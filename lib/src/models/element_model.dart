import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- Serialization Helpers ---
Map<String, dynamic> offsetToJson(Offset o) => {'dx': o.dx, 'dy': o.dy};
Offset jsonToOffset(Map<String, dynamic> json) => Offset(json['dx'] as double, json['dy'] as double);

Map<String, dynamic> sizeToJson(Size s) => {'width': s.width, 'height': s.height};
Size jsonToSize(Map<String, dynamic> json) => Size(json['width'] as double, json['height'] as double);

int? colorToJson(Color? color) => color?.value;
Color? jsonToColor(dynamic value) => value == null ? null : Color(value as int);

Map<String, dynamic> textStyleToJson(TextStyle ts) {
  return {
    'fontSize': ts.fontSize,
    'color': colorToJson(ts.color),
    'fontWeight': ts.fontWeight?.index,
    'fontStyle': ts.fontStyle?.index,
    'fontFamily': ts.fontFamily,
  };
}

TextStyle jsonToTextStyle(Map<String, dynamic> json) {
  return TextStyle(
    fontSize: json['fontSize'] as double?,
    color: jsonToColor(json['color']),
    fontWeight: json['fontWeight'] != null ? FontWeight.values[json['fontWeight'] as int] : null,
    fontStyle: json['fontStyle'] != null ? FontStyle.values[json['fontStyle'] as int] : null,
    fontFamily: json['fontFamily'] as String?,
  );
}


enum ElementType { image, text, rectangle, circle }

abstract class CanvasElement {
  final String id;
  final ElementType type;
  Offset position;
  double scale;
  double rotation;
  Size size;
  final bool isLocked;

  CanvasElement({
    required this.id,
    required this.type,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    required this.size,
    this.isLocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'position': offsetToJson(position),
      'scale': scale,
      'rotation': rotation,
      'size': sizeToJson(size),
      'isLocked': isLocked,
    };
  }

  dynamic copyWith({
    String? id,
    Offset? position,
    double? scale,
    double? rotation,
    Size? size,
    bool? isLocked,
  });
}

class ImageElement extends CanvasElement {
  final String imagePath;

  ImageElement({
    required super.id, required this.imagePath, required super.position, super.scale, super.rotation, required super.size, super.isLocked,
  }) : super(type: ElementType.image);

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({'imagePath': imagePath});
  }

  factory ImageElement.fromJson(Map<String, dynamic> json) {
    return ImageElement(
      id: json['id'] as String, imagePath: json['imagePath'] as String, position: jsonToOffset(json['position'] as Map<String, dynamic>),
      scale: json['scale'] as double, rotation: json['rotation'] as double, size: jsonToSize(json['size'] as Map<String, dynamic>),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  @override
  ImageElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked,
    String? imagePath,
  }) {
    return ImageElement(
      id: id ?? this.id, imagePath: imagePath ?? this.imagePath, position: position ?? this.position,
      scale: scale ?? this.scale, rotation: rotation ?? this.rotation, size: this.size, isLocked: isLocked ?? this.isLocked,
    );
  }
}

class TextElement extends CanvasElement {
  String text;
  TextStyle style;
  TextAlign textAlign;
  Color? textBackgroundColor;
  Color? outlineColor;
  double outlineWidth;

  TextElement({
    required super.id, required this.text, required super.position, super.scale, super.rotation,
    TextStyle? style, this.textAlign = TextAlign.center, required super.size, super.isLocked,
    this.textBackgroundColor, this.outlineColor, this.outlineWidth = 0.0,
  }) : style = style ?? const TextStyle(fontSize: 48, color: Colors.black),
       super(type: ElementType.text);

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({
      'text': text, 'style': textStyleToJson(style), 'textAlign': textAlign.index,
      'textBackgroundColor': colorToJson(textBackgroundColor), 'outlineColor': colorToJson(outlineColor), 'outlineWidth': outlineWidth,
    });
  }

  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      id: json['id'] as String, text: json['text'] as String, position: jsonToOffset(json['position'] as Map<String, dynamic>),
      scale: json['scale'] as double, rotation: json['rotation'] as double, style: jsonToTextStyle(json['style'] as Map<String, dynamic>),
      textAlign: TextAlign.values[json['textAlign'] as int? ?? TextAlign.center.index], size: jsonToSize(json['size'] as Map<String, dynamic>),
      isLocked: json['isLocked'] as bool? ?? false, textBackgroundColor: jsonToColor(json['textBackgroundColor']),
      outlineColor: jsonToColor(json['outlineColor']), outlineWidth: json['outlineWidth'] as double? ?? 0.0,
    );
  }

  @override
  TextElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked,
    String? text, TextStyle? style, TextAlign? textAlign,
    ValueGetter<Color?>? textBackgroundColorGetter, Color? textBackgroundColor, // Allow explicit null via getter
    ValueGetter<Color?>? outlineColorGetter, Color? outlineColor, // Allow explicit null via getter
    double? outlineWidth,
  }) {
    return TextElement(
      id: id ?? this.id, text: text ?? this.text, position: position ?? this.position, scale: scale ?? this.scale, rotation: rotation ?? this.rotation,
      style: style ?? this.style, textAlign: textAlign ?? this.textAlign, size: size ?? this.size, isLocked: isLocked ?? this.isLocked,
      textBackgroundColor: textBackgroundColorGetter != null ? textBackgroundColorGetter() : (textBackgroundColor ?? this.textBackgroundColor),
      outlineColor: outlineColorGetter != null ? outlineColorGetter() : (outlineColor ?? this.outlineColor),
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }
}

class RectangleElement extends CanvasElement {
  Color color;
  Color? outlineColor;
  double outlineWidth;

  RectangleElement({
    required super.id, required super.position, required super.size, this.color = Colors.blue,
    super.scale, super.rotation, super.isLocked,
    this.outlineColor, this.outlineWidth = 0.0, // New properties
  }) : super(type: ElementType.rectangle);

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({
      'color': colorToJson(color),
      'outlineColor': colorToJson(outlineColor),
      'outlineWidth': outlineWidth,
    });
  }

  factory RectangleElement.fromJson(Map<String, dynamic> json) {
    return RectangleElement(
      id: json['id'] as String, position: jsonToOffset(json['position'] as Map<String, dynamic>),
      scale: json['scale'] as double, rotation: json['rotation'] as double, size: jsonToSize(json['size'] as Map<String, dynamic>),
      color: jsonToColor(json['color'] as int)!, isLocked: json['isLocked'] as bool? ?? false,
      outlineColor: jsonToColor(json['outlineColor']), outlineWidth: json['outlineWidth'] as double? ?? 0.0,
    );
  }

  @override
  RectangleElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked,
    Color? color, Color? outlineColor, ValueGetter<Color?>? outlineColorGetter, double? outlineWidth,
  }) {
    return RectangleElement(
      id: id ?? this.id, position: position ?? this.position, scale: scale ?? this.scale, rotation: rotation ?? this.rotation,
      size: size ?? this.size, color: color ?? this.color, isLocked: isLocked ?? this.isLocked,
      outlineColor: outlineColorGetter != null ? outlineColorGetter() : (outlineColor ?? this.outlineColor),
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }
}

class CircleElement extends CanvasElement {
  Color color;
  Color? outlineColor;
  double outlineWidth;

  CircleElement({
    required super.id, required super.position, required double radius, this.color = Colors.red,
    super.scale, super.rotation, super.isLocked,
    this.outlineColor, this.outlineWidth = 0.0, // New properties
  }) : super(type: ElementType.circle, size: Size(radius * 2, radius * 2));

  double get radius => size.width / 2;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({'color': colorToJson(color), 'radius': radius, 'outlineColor': colorToJson(outlineColor), 'outlineWidth': outlineWidth});
  }

  factory CircleElement.fromJson(Map<String, dynamic> json) {
    double radius = json['radius'] != null ? json['radius'] as double : (jsonToSize(json['size'] as Map<String, dynamic>)).width / 2;
    return CircleElement(
      id: json['id'] as String, position: jsonToOffset(json['position'] as Map<String, dynamic>),
      scale: json['scale'] as double, rotation: json['rotation'] as double, radius: radius,
      color: jsonToColor(json['color'] as int)!, isLocked: json['isLocked'] as bool? ?? false,
      outlineColor: jsonToColor(json['outlineColor']), outlineWidth: json['outlineWidth'] as double? ?? 0.0,
    );
  }

  @override
  CircleElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked,
    double? radius, Color? color, Color? outlineColor, ValueGetter<Color?>? outlineColorGetter, double? outlineWidth,
  }) {
    double newRadius;
    if (radius != null) {
      newRadius = radius;
    } else if (size != null) {
      newRadius = math.min(size.width, size.height) / 2;
    } else {
      newRadius = this.radius;
    }
    return CircleElement(
      id: id ?? this.id, position: position ?? this.position, scale: scale ?? this.scale, rotation: rotation ?? this.rotation,
      radius: newRadius, color: color ?? this.color, isLocked: isLocked ?? this.isLocked,
      outlineColor: outlineColorGetter != null ? outlineColorGetter() : (outlineColor ?? this.outlineColor),
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }
}
