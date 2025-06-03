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
  final double opacity;
  final Color? shadowColor;
  final Offset? shadowOffset;
  final double shadowBlurRadius;

  CanvasElement({
    required this.id,
    required this.type,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    required this.size,
    this.isLocked = false,
    this.opacity = 1.0,
    this.shadowColor,
    this.shadowOffset,
    this.shadowBlurRadius = 0.0,
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
      'opacity': opacity,
      'shadowColor': colorToJson(shadowColor),
      'shadowOffset': shadowOffset != null ? offsetToJson(shadowOffset!) : null,
      'shadowBlurRadius': shadowBlurRadius,
    };
  }

  dynamic copyWith({
    String? id,
    Offset? position,
    double? scale,
    double? rotation,
    Size? size,
    bool? isLocked,
    double? opacity,
    Color? shadowColor, ValueGetter<Color?>? shadowColorGetter,
    Offset? shadowOffset, ValueGetter<Offset?>? shadowOffsetGetter,
    double? shadowBlurRadius,
  });
}

class ImageElement extends CanvasElement {
  final String imagePath;
  final double cornerRadius;
  final Color? borderColor;
  final double borderWidth;

  ImageElement({
    required super.id, required this.imagePath, required super.position, super.scale, super.rotation, required super.size, super.isLocked, super.opacity,
    super.shadowColor, super.shadowOffset, super.shadowBlurRadius,
    this.cornerRadius = 0.0, this.borderColor, this.borderWidth = 0.0,
  }) : super(type: ElementType.image);

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({
      'imagePath': imagePath,
      'cornerRadius': cornerRadius,
      'borderColor': colorToJson(borderColor),
      'borderWidth': borderWidth,
    });
  }

  factory ImageElement.fromJson(Map<String, dynamic> json) {
    return ImageElement(
      id: json['id'] as String, imagePath: json['imagePath'] as String, position: jsonToOffset(json['position'] as Map<String, dynamic>),
      scale: json['scale'] as double, rotation: json['rotation'] as double, size: jsonToSize(json['size'] as Map<String, dynamic>),
      isLocked: json['isLocked'] as bool? ?? false,
      cornerRadius: json['cornerRadius'] as double? ?? 0.0,
      opacity: json['opacity'] as double? ?? 1.0,
      borderColor: jsonToColor(json['borderColor']),
      borderWidth: json['borderWidth'] as double? ?? 0.0,
      shadowColor: jsonToColor(json['shadowColor']),
      shadowOffset: json['shadowOffset'] != null ? jsonToOffset(json['shadowOffset'] as Map<String, dynamic>) : null,
      shadowBlurRadius: json['shadowBlurRadius'] as double? ?? 0.0,
    );
  }

  @override
  ImageElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked, double? opacity,
    Color? shadowColor, ValueGetter<Color?>? shadowColorGetter, Offset? shadowOffset, ValueGetter<Offset?>? shadowOffsetGetter, double? shadowBlurRadius,
    String? imagePath,
    double? cornerRadius,
    ValueGetter<Color?>? borderColorGetter, Color? borderColor,
    double? borderWidth,
  }) {
    return ImageElement(
      id: id ?? this.id, imagePath: imagePath ?? this.imagePath, position: position ?? this.position,
      scale: scale ?? this.scale, rotation: rotation ?? this.rotation, size: size ?? this.size, isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      shadowColor: shadowColorGetter != null ? shadowColorGetter() : (shadowColor ?? this.shadowColor),
      shadowOffset: shadowOffsetGetter != null ? shadowOffsetGetter() : (shadowOffset ?? this.shadowOffset),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderColor: borderColorGetter != null ? borderColorGetter() : (borderColor ?? this.borderColor),
      borderWidth: borderWidth ?? this.borderWidth,
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
    required super.id, required this.text, required super.position, super.scale, super.rotation, super.opacity,
    super.shadowColor, super.shadowOffset, super.shadowBlurRadius,
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
      opacity: json['opacity'] as double? ?? 1.0,
      shadowColor: jsonToColor(json['shadowColor']),
      shadowOffset: json['shadowOffset'] != null ? jsonToOffset(json['shadowOffset'] as Map<String, dynamic>) : null,
      shadowBlurRadius: json['shadowBlurRadius'] as double? ?? 0.0,
    );
  }

  @override
  TextElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked, double? opacity,
    Color? shadowColor, ValueGetter<Color?>? shadowColorGetter, Offset? shadowOffset, ValueGetter<Offset?>? shadowOffsetGetter, double? shadowBlurRadius,
    String? text, TextStyle? style, TextAlign? textAlign,
    ValueGetter<Color?>? textBackgroundColorGetter, Color? textBackgroundColor,
    ValueGetter<Color?>? outlineColorGetter, Color? outlineColor,
    double? outlineWidth,
  }) {
    return TextElement(
      id: id ?? this.id, text: text ?? this.text, position: position ?? this.position, scale: scale ?? this.scale, rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      shadowColor: shadowColorGetter != null ? shadowColorGetter() : (shadowColor ?? this.shadowColor),
      shadowOffset: shadowOffsetGetter != null ? shadowOffsetGetter() : (shadowOffset ?? this.shadowOffset),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
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
  final double cornerRadius;

  RectangleElement({
    required super.id, required super.position, required super.size, this.color = Colors.blue,
    super.scale, super.rotation, super.isLocked, super.opacity,
    super.shadowColor, super.shadowOffset, super.shadowBlurRadius,
    this.outlineColor, this.outlineWidth = 0.0,
    this.cornerRadius = 0.0,
  }) : super(type: ElementType.rectangle);

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()..addAll({
      'color': colorToJson(color),
      'outlineColor': colorToJson(outlineColor),
      'outlineWidth': outlineWidth,
      'cornerRadius': cornerRadius,
    });
  }

  factory RectangleElement.fromJson(Map<String, dynamic> json) {
    return RectangleElement(
      id: json['id'] as String, position: jsonToOffset(json['position'] as Map<String, dynamic>),
      scale: json['scale'] as double, rotation: json['rotation'] as double, size: jsonToSize(json['size'] as Map<String, dynamic>),
      color: jsonToColor(json['color'] as int)!, isLocked: json['isLocked'] as bool? ?? false,
      outlineColor: jsonToColor(json['outlineColor']), outlineWidth: json['outlineWidth'] as double? ?? 0.0,
      cornerRadius: json['cornerRadius'] as double? ?? 0.0,
      opacity: json['opacity'] as double? ?? 1.0,
      shadowColor: jsonToColor(json['shadowColor']),
      shadowOffset: json['shadowOffset'] != null ? jsonToOffset(json['shadowOffset'] as Map<String, dynamic>) : null,
      shadowBlurRadius: json['shadowBlurRadius'] as double? ?? 0.0,
    );
  }

  @override
  RectangleElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked, double? opacity,
    Color? shadowColor, ValueGetter<Color?>? shadowColorGetter, Offset? shadowOffset, ValueGetter<Offset?>? shadowOffsetGetter, double? shadowBlurRadius,
    Color? color, Color? outlineColor, ValueGetter<Color?>? outlineColorGetter, double? outlineWidth,
    double? cornerRadius,
  }) {
    return RectangleElement(
      id: id ?? this.id, position: position ?? this.position, scale: scale ?? this.scale, rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      shadowColor: shadowColorGetter != null ? shadowColorGetter() : (shadowColor ?? this.shadowColor),
      shadowOffset: shadowOffsetGetter != null ? shadowOffsetGetter() : (shadowOffset ?? this.shadowOffset),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      size: size ?? this.size, color: color ?? this.color, isLocked: isLocked ?? this.isLocked,
      outlineColor: outlineColorGetter != null ? outlineColorGetter() : (outlineColor ?? this.outlineColor),
      outlineWidth: outlineWidth ?? this.outlineWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }
}

class CircleElement extends CanvasElement {
  Color color;
  Color? outlineColor;
  double outlineWidth;

  CircleElement({
    required super.id, required super.position, required double radius, this.color = Colors.red,
    super.scale, super.rotation, super.isLocked, super.opacity,
    super.shadowColor, super.shadowOffset, super.shadowBlurRadius,
    this.outlineColor, this.outlineWidth = 0.0,
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
      opacity: json['opacity'] as double? ?? 1.0,
      shadowColor: jsonToColor(json['shadowColor']),
      shadowOffset: json['shadowOffset'] != null ? jsonToOffset(json['shadowOffset'] as Map<String, dynamic>) : null,
      shadowBlurRadius: json['shadowBlurRadius'] as double? ?? 0.0,
    );
  }

  @override
  CircleElement copyWith({
    String? id, Offset? position, double? scale, double? rotation, Size? size, bool? isLocked, double? opacity,
    Color? shadowColor, ValueGetter<Color?>? shadowColorGetter, Offset? shadowOffset, ValueGetter<Offset?>? shadowOffsetGetter, double? shadowBlurRadius,
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
      opacity: opacity ?? this.opacity,
      shadowColor: shadowColorGetter != null ? shadowColorGetter() : (shadowColor ?? this.shadowColor),
      shadowOffset: shadowOffsetGetter != null ? shadowOffsetGetter() : (shadowOffset ?? this.shadowOffset),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      radius: newRadius, color: color ?? this.color, isLocked: isLocked ?? this.isLocked,
      outlineColor: outlineColorGetter != null ? outlineColorGetter() : (outlineColor ?? this.outlineColor),
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }
}
