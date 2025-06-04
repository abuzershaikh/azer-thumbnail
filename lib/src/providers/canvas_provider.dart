import 'dart:io';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:flutter/material.dart';
import 'package:thumbnail_maker/src/models/element_model.dart';
import 'package:uuid/uuid.dart';


class _CanvasStateSnapshot {
  final List<CanvasElement> elements;
  final Color backgroundColor;
  final String? backgroundImagePath;
  final BoxFit? backgroundFit;

  _CanvasStateSnapshot(this.elements, this.backgroundColor, this.backgroundImagePath, this.backgroundFit);

  factory _CanvasStateSnapshot.deepCopy(List<CanvasElement> elements, Color backgroundColor, String? backgroundImagePath, BoxFit? backgroundFit) {
    List<CanvasElement> copiedElements = elements.map((e) {
      return CanvasProvider.elementFromJson(e.toJson());
    }).toList();
    return _CanvasStateSnapshot(copiedElements, backgroundColor, backgroundImagePath, backgroundFit);
  }
}


class CanvasProvider with ChangeNotifier {
  List<CanvasElement> _elements = [];
  Color _backgroundColor = Colors.white;
  String? backgroundImagePath;
  BoxFit? backgroundFit;
  double _zoomLevel = 1.0;
  final Uuid _uuid = const Uuid();

  CanvasElement? _selectedElement;

  Offset? _lastFocalPoint; // Not strictly used in current simplified gesture model
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

  final List<_CanvasStateSnapshot> _undoStack = [];
  final List<_CanvasStateSnapshot> _redoStack = [];
  static const int _maxHistoryStack = 30;

  Color get backgroundColor => _backgroundColor;
  String? get backgroundImagePathValue => backgroundImagePath; // Getter for UI
  BoxFit? get backgroundFitValue => backgroundFit; // Getter for UI
  double get zoomLevel => _zoomLevel;
  List<CanvasElement> get elements => List.unmodifiable(_elements);
  CanvasElement? get selectedElement => _selectedElement;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  static CanvasElement elementFromJson(Map<String, dynamic> json) {
    ElementType type = ElementType.values.firstWhere((e) => e.name == json['type'], orElse: () => throw Exception('Unknown element type: ${json['type']}'));
    switch (type) {
      case ElementType.image:
        return ImageElement.fromJson(json);
      case ElementType.text:
        return TextElement.fromJson(json);
      case ElementType.rectangle:
        return RectangleElement.fromJson(json);
      case ElementType.circle:
        return CircleElement.fromJson(json);
      default:
        throw Exception('Unsupported element type for deserialization: $type');
    }
  }

  void _saveStateForUndo() {
    if (_undoStack.length >= _maxHistoryStack && _undoStack.isNotEmpty) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(_CanvasStateSnapshot.deepCopy(_elements, _backgroundColor, backgroundImagePath, backgroundFit));
    _redoStack.clear();
    // notifyListeners(); // Called by the public method that invoked _saveStateForUndo or at the end of an action
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_CanvasStateSnapshot.deepCopy(List.from(_elements), _backgroundColor, backgroundImagePath, backgroundFit));
    final lastState = _undoStack.removeLast();
    _elements = List.from(lastState.elements);
    _backgroundColor = lastState.backgroundColor;
    backgroundImagePath = lastState.backgroundImagePath;
    backgroundFit = lastState.backgroundFit;
    _selectedElement = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_CanvasStateSnapshot.deepCopy(List.from(_elements), _backgroundColor, backgroundImagePath, backgroundFit));
    final nextState = _redoStack.removeLast();
    _elements = List.from(nextState.elements);
    _backgroundColor = nextState.backgroundColor;
    backgroundImagePath = nextState.backgroundImagePath;
    backgroundFit = nextState.backgroundFit;
    _selectedElement = null;
    notifyListeners();
  }

  Future<void> saveProject(String filePath) async {
    try {
      final projectData = {
        'backgroundColor': _backgroundColor.value,
        'elements': _elements.map((e) => e.toJson()).toList(),
        'backgroundImagePath': backgroundImagePath,
        'backgroundFit': backgroundFit?.name,
      };
      final String jsonString = jsonEncode(projectData);
      await File(filePath).writeAsString(jsonString);
    } catch (e) {
      print('Error saving project: $e');
      rethrow;
    }
  }

  Future<void> loadProject(String filePath) async {
    try {
      final String jsonString = await File(filePath).readAsString();
      final Map<String, dynamic> projectData = jsonDecode(jsonString);

      // Save current state *before* loading, so loading itself is undoable
      _saveStateForUndo();

      _backgroundColor = Color(projectData['backgroundColor'] as int);
      final List<dynamic> elementListJson = projectData['elements'] as List<dynamic>;
      _elements = elementListJson.map((json) => elementFromJson(json as Map<String, dynamic>)).toList();
      
      backgroundImagePath = projectData['backgroundImagePath'] as String?;
      String? fitName = projectData['backgroundFit'] as String?;
      if (fitName != null) {
        backgroundFit = BoxFit.values.firstWhere((fit) => fit.name == fitName, orElse: () => BoxFit.contain);
      } else {
        backgroundFit = null;
      }

      _selectedElement = null;
      // _undoStack is managed by _saveStateForUndo
      // _redoStack is cleared by _saveStateForUndo
      notifyListeners();
    } catch (e) {
      print('Error loading project: $e');
      rethrow;
    }
  }

  void setBackgroundImage(String? path, BoxFit? fit) {
    if (backgroundImagePath == path && backgroundFit == fit) return;
    _saveStateForUndo();
    backgroundImagePath = path;
    backgroundFit = (path == null) ? null : fit;
    notifyListeners();
  }

  void changeBackgroundColor(Color newColor) {
    if (_backgroundColor == newColor) return;
    _saveStateForUndo();
    _backgroundColor = newColor;
    notifyListeners();
  }

  void setZoomLevel(double newZoom) {
    double clampedZoom = newZoom.clamp(0.05, 10.0);
    if ((_zoomLevel - clampedZoom).abs() > 0.01) {
      _zoomLevel = clampedZoom;
      notifyListeners();
    }
  }

  Size _calculateTextSize(String text, TextStyle style, {double maxWidth = 1280 * 0.8}) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(minWidth: 0, maxWidth: maxWidth);
    return textPainter.size;
  }

  void addImageElement(String imagePath, Size imageSize) {
    _saveStateForUndo();
    const Offset defaultPosition = Offset(100, 100);
    final newElement = ImageElement(id: _uuid.v4(), imagePath: imagePath, position: defaultPosition, size: imageSize);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void addTextElement(String text, TextStyle initialStyle, Offset position) {
    _saveStateForUndo();
    final Size calculatedSize = _calculateTextSize(text, initialStyle);
    final newElement = TextElement(id: _uuid.v4(), text: text, position: position, style: initialStyle, size: calculatedSize);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void addRectangleElement() {
    _saveStateForUndo();
    const defaultSize = Size(200, 100);
    const defaultPosition = Offset(150, 150);
    final newElement = RectangleElement(id: _uuid.v4(), position: defaultPosition, size: defaultSize, color: Colors.blueAccent);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void addCircleElement() {
    _saveStateForUndo();
    const defaultRadius = 50.0;
    const defaultPosition = Offset(200, 200);
    final newElement = CircleElement(id: _uuid.v4(), position: defaultPosition, radius: defaultRadius, color: Colors.greenAccent);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void updateElement(CanvasElement updatedElementFromToolbar) {
    final index = _elements.indexWhere((e) => e.id == updatedElementFromToolbar.id);
    if (index == -1) return;

    final currentElementInList = _elements[index];
    if (currentElementInList.isLocked) {
      // Optional: Provide feedback that element is locked (e.g., via a status message provider)
      // For now, silently ignore or print debug message.
      print("Element ${currentElementInList.id} is locked. Update from toolbar ignored.");
      return;
    }

    _saveStateForUndo();

    CanvasElement elementToUpdate = updatedElementFromToolbar; // It's already a new instance from copyWith in RightToolbar
    if (updatedElementFromToolbar is TextElement) {
      // Size recalculation if text or style that affects size has changed
      final oldElement = currentElementInList as TextElement;
      if (updatedElementFromToolbar.text != oldElement.text ||
          updatedElementFromToolbar.style.fontSize != oldElement.style.fontSize ||
          updatedElementFromToolbar.style.fontWeight != oldElement.style.fontWeight ||
          updatedElementFromToolbar.style.fontFamily != oldElement.style.fontFamily) {
         elementToUpdate = updatedElementFromToolbar.copyWith(size: _calculateTextSize(updatedElementFromToolbar.text, updatedElementFromToolbar.style));
      }
    }

    _elements[index] = elementToUpdate;
    _selectedElement = elementToUpdate;
    notifyListeners();
  }

  void selectElement(CanvasElement? element) {
    if (_selectedElement != element) {
      _selectedElement = element;
      notifyListeners();
    }
  }

  void toggleElementLock() {
    if (_selectedElement == null) return;
    _saveStateForUndo();

    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      final currentElement = _elements[index];
      // Use dynamic dispatch for copyWith to call the correct subclass implementation
      CanvasElement updatedElement = (currentElement as dynamic).copyWith(isLocked: !currentElement.isLocked);

      _elements[index] = updatedElement;
      _selectedElement = updatedElement; // Update selected element to the new instance
      notifyListeners();
    }
  }

  void bringToFront() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return; // Cannot reorder locked element
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1 && index < _elements.length - 1) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.add(element);
      notifyListeners();
    }
  }

  void sendToBack() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return;
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index > 0) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.insert(0, element);
      notifyListeners();
    }
  }

  void bringForward() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return;
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1 && index < _elements.length - 1) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.insert(index + 1, element);
      notifyListeners();
    }
  }

  void sendBackward() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return;
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index > 0) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.insert(index - 1, element);
      notifyListeners();
    }
  }

  _CanvasStateSnapshot? _preGestureState;

  void onElementGestureStart(CanvasElement element) {
    if (element.isLocked) return; // Do not initiate gesture if element is locked

    if (_selectedElement != element) {
      selectElement(element);
    }
     _preGestureState = _CanvasStateSnapshot.deepCopy(List.from(_elements), _backgroundColor, backgroundImagePath, backgroundFit);
    _initialScale = element.scale;
    _initialRotation = element.rotation;
  }

  void panElement(CanvasElement element, Offset delta) {
    if (element.isLocked || element.id != _selectedElement?.id) return;

    final currentElement = _selectedElement!;
    currentElement.position += delta;
    notifyListeners();
  }

  void scaleAndRotateElement(ScaleUpdateDetails details) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;
    final currentElement = _selectedElement!;
    double newScale = _initialScale * details.scale;
    currentElement.scale = newScale;
    currentElement.rotation = _initialRotation + details.rotation;
    notifyListeners();
  }

  void onElementGestureEnd() {
    if (_preGestureState == null) return; // Gesture was not started on a non-locked element or was on a locked one

    // Check if state actually changed to avoid empty undo states.
    // This simple check compares references of selected element and its properties.
    // A more robust check would compare all elements or use a hash.
    bool stateChanged = false;
    if (_selectedElement != null && _preGestureState!.elements.any((e) => e.id == _selectedElement!.id)) {
        final originalStateOfSelectedElement = _preGestureState!.elements.firstWhere((e) => e.id == _selectedElement!.id);
        if (originalStateOfSelectedElement.position != _selectedElement!.position ||
            originalStateOfSelectedElement.scale != _selectedElement!.scale ||
            originalStateOfSelectedElement.rotation != _selectedElement!.rotation ||
            _preGestureState!.backgroundColor != _backgroundColor ||
            _preGestureState!.backgroundImagePath != backgroundImagePath ||
            _preGestureState!.backgroundFit != backgroundFit 
            ) {
            stateChanged = true;
        }
    } else if (_preGestureState!.elements.length != _elements.length || // Element added/removed
               _preGestureState!.backgroundColor != _backgroundColor ||
               _preGestureState!.backgroundImagePath != backgroundImagePath ||
               _preGestureState!.backgroundFit != backgroundFit
              ) {
      stateChanged = true;
    }


    if (stateChanged) {
       if (_undoStack.length >= _maxHistoryStack && _undoStack.isNotEmpty) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(_preGestureState!); // _preGestureState already contains the new fields
      _redoStack.clear();
    }
    _preGestureState = null;
    notifyListeners();
  }

  void updateSelectedElementSizeAndPosition(Offset newPosition, Size newSize) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;

    // Ensure this is treated as part of an ongoing gesture if _preGestureState is set
    // (meaning onElementGestureStart was called and onElementGestureEnd hasn't been yet)
    // If _preGestureState is null, it implies this update is happening outside a main gesture,
    // which shouldn't be the case for resizing handles. It relies on onElementGestureStart
    // having been called from the HomeScreen to set up _preGestureState.

    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      // Use dynamic to call the correct copyWith
      CanvasElement updatedElement = (_elements[index] as dynamic).copyWith(
        position: newPosition,
        size: newSize,
        // Reset scale if direct size manipulation is intended to override scaling.
        // scale: 1.0, // This might be desired depending on interaction model.
                      // For now, let's assume scale is independent and not reset here.
      );

      // If the element is a CircleElement, width and height must be equal.
      // The newSize comes from the drag, which might make it non-square.
      // We should probably average width/height or use min/max to define the new radius.
      // And then adjust position to keep the center fixed if aspect ratio changed.
      if (updatedElement is CircleElement) {
        // Preserve the circle's center during resize.
        Offset oldCenter = _elements[index].position + Offset(_elements[index].size.width / 2, _elements[index].size.height / 2);
        
        double newRadius = (newSize.width + newSize.height) / 4; // Average of new width and height / 2
        if (newRadius < 5.0) newRadius = 5.0; // Min radius

        Size finalSize = Size(newRadius * 2, newRadius * 2);
        Offset finalPosition = oldCenter - Offset(newRadius, newRadius); // New top-left for the centered circle

        updatedElement = (updatedElement).copyWith(
          position: finalPosition,
          size: finalSize,
        );
      }
      // Text element size is handled by direct manipulation, so no special recalc here,
      // unlike in updateElement where it's based on text content changes.

      _elements[index] = updatedElement;
      _selectedElement = updatedElement;
      notifyListeners();
    }
  }

  void toggleLockSelectedElement() {
    if (_selectedElement == null) return;
    _saveStateForUndo(); // Save state before the change

    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      // Create a new instance with the toggled lock state
      // Explicitly cast to dynamic to ensure the correct copyWith is called
      final CanvasElement oldElement = _elements[index];
      final CanvasElement updatedElement = (oldElement as dynamic).copyWith(isLocked: !oldElement.isLocked);
      
      _elements[index] = updatedElement;
      _selectedElement = updatedElement; // Update selected element to the new instance
      notifyListeners();
    }
  }

  void deleteElement(CanvasElement element) {
    _saveStateForUndo(); // Save state before deleting

    _elements.removeWhere((e) => e.id == element.id);
    if (_selectedElement?.id == element.id) {
      _selectedElement = null;
    }
    notifyListeners();
  }

  void updateSelectedElementOpacity(double opacity) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;
    if (_selectedElement!.opacity == opacity.clamp(0.0, 1.0)) return; // No change

    _saveStateForUndo(); // Save current state before changing opacity
    
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      // Use dynamic dispatch for copyWith to ensure correct subclass implementation is called
      _selectedElement = (_elements[index] as dynamic).copyWith(opacity: opacity.clamp(0.0, 1.0));
      _elements[index] = _selectedElement!;
      notifyListeners();
    }
  }

  void updateSelectedElementRotation(double newRotationInDegrees) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;

    double newRotationInRadians = newRotationInDegrees * (3.141592653589793 / 180);
    // Normalize radians to be within -PI to PI for consistency, though not strictly necessary for math.cos/sin
    // newRotationInRadians = (newRotationInRadians + 3.141592653589793) % (2 * 3.141592653589793) - 3.141592653589793;
    
    // Check if rotation actually changed significantly to avoid unnecessary updates/undo states
    if ((_selectedElement!.rotation - newRotationInRadians).abs() < 0.001) return;


    _saveStateForUndo(); // Save current state before changing rotation

    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      // Use dynamic dispatch for copyWith
      _selectedElement = (_elements[index] as dynamic).copyWith(rotation: newRotationInRadians);
      _elements[index] = _selectedElement!;
      notifyListeners();
    }
  }

  void updateSelectedElementSize(Size newSize) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;
    
    // Basic validation for minimum size
    if (newSize.width < 5 || newSize.height < 5) {
      // Optionally provide feedback to user about minimum size
      return;
    }
    // Check if size actually changed
    if ((_selectedElement!.size.width - newSize.width).abs() < 0.1 &&
        (_selectedElement!.size.height - newSize.height).abs() < 0.1) {
      return;
    }

    _saveStateForUndo();
    final oldElement = _selectedElement!; // Store for CircleElement's centered scaling

    // For CircleElement, maintain aspect ratio and centered scaling
    if (_selectedElement is CircleElement) {
      CircleElement circle = _selectedElement as CircleElement;
      double newRadius = (newSize.width + newSize.height) / 4; // Average of new width and height / 2
      newRadius = newRadius.clamp(5.0, 1000.0); // Min radius 5, Max radius 1000 (arbitrary large)

      Offset oldCenter = oldElement.position + Offset(oldElement.size.width / 2, oldElement.size.height / 2);
      Size finalSize = Size(newRadius * 2, newRadius * 2);
      Offset finalPosition = oldCenter - Offset(newRadius, newRadius);
      
      _selectedElement = circle.copyWith(position: finalPosition, size: finalSize);
    } else {
      // For other elements, just update the size
      _selectedElement = _selectedElement!.copyWith(size: newSize);
    }

    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      _elements[index] = _selectedElement!;
    }
    notifyListeners();
  }

  void updateSelectedElementCornerRadius(double newRadius) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;

    double clampedRadius = newRadius.clamp(0.0, 2000.0); // Min 0, Max 2000 (arbitrary large, will be clamped further by element size)

    CanvasElement? updatedElement;

    if (_selectedElement is ImageElement) {
      ImageElement current = _selectedElement as ImageElement;
      if (current.cornerRadius == clampedRadius) return; // No change
      _saveStateForUndo();
      clampedRadius = clampedRadius.clamp(0.0, current.size.shortestSide / 2);
      updatedElement = current.copyWith(cornerRadius: clampedRadius);
    } else if (_selectedElement is RectangleElement) {
      RectangleElement current = _selectedElement as RectangleElement;
      if (current.cornerRadius == clampedRadius) return; // No change
      _saveStateForUndo();
      clampedRadius = clampedRadius.clamp(0.0, current.size.shortestSide / 2);
      updatedElement = current.copyWith(cornerRadius: clampedRadius);
    } else {
      // Not an element type that supports corner radius
      return;
    }
    
    _selectedElement = updatedElement;
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      _elements[index] = _selectedElement!;
    }
    notifyListeners();
    }

  void updateSelectedElementBorder({
    ValueGetter<Color?>? borderColorGetter, Color? borderColor, 
    double? borderWidth,
    ValueGetter<Color?>? outlineColorGetter, Color? outlineColor,
    double? outlineWidth,
  }) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;

    bool changed = false;
    CanvasElement? newElementState;

    if (_selectedElement is ImageElement) {
      ImageElement current = _selectedElement as ImageElement;
      // Check if there's an actual change to avoid unnecessary undo states
      if ((borderColor != null && current.borderColor != borderColor) || 
          (borderColorGetter != null) || // Explicit null set
          (borderWidth != null && current.borderWidth != borderWidth)) {
        _saveStateForUndo();
        newElementState = current.copyWith(
          borderColorGetter: borderColorGetter,
          borderColor: borderColor,
          borderWidth: borderWidth,
        );
        changed = true;
      }
    } else if (_selectedElement is TextElement) {
      TextElement current = _selectedElement as TextElement;
      if ((outlineColor != null && current.outlineColor != outlineColor) ||
          (outlineColorGetter != null) || // Explicit null set
          (outlineWidth != null && current.outlineWidth != outlineWidth)) {
        _saveStateForUndo();
        newElementState = current.copyWith(
          outlineColorGetter: outlineColorGetter,
          outlineColor: outlineColor,
          outlineWidth: outlineWidth,
        );
        changed = true;
      }
    } else if (_selectedElement is RectangleElement) {
      RectangleElement current = _selectedElement as RectangleElement;
       if ((outlineColor != null && current.outlineColor != outlineColor) ||
          (outlineColorGetter != null) || // Explicit null set
          (outlineWidth != null && current.outlineWidth != outlineWidth)) {
        _saveStateForUndo();
        newElementState = current.copyWith(
          outlineColorGetter: outlineColorGetter,
          outlineColor: outlineColor,
          outlineWidth: outlineWidth,
        );
        changed = true;
      }
    } else if (_selectedElement is CircleElement) {
      CircleElement current = _selectedElement as CircleElement;
      if ((outlineColor != null && current.outlineColor != outlineColor) ||
          (outlineColorGetter != null) || // Explicit null set
          (outlineWidth != null && current.outlineWidth != outlineWidth)) {
        _saveStateForUndo();
        newElementState = current.copyWith(
          outlineColorGetter: outlineColorGetter,
          outlineColor: outlineColor,
          outlineWidth: outlineWidth,
        );
        changed = true;
      }
    }

    if (changed && newElementState != null) {
      _selectedElement = newElementState;
      final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
      if (index != -1) {
        _elements[index] = _selectedElement!;
      }
      notifyListeners();
    }
  }

  void updateSelectedElementShadow({
    Color? shadowColor, Offset? shadowOffset, double? shadowBlurRadius,
    ValueGetter<Color?>? shadowColorGetter, ValueGetter<Offset?>? shadowOffsetGetter,
  }) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;

    final currentElement = _selectedElement!;
    // Determine actual new values, respecting getters for nullability
    // shadowColorGetter and shadowOffsetGetter allow to explicitly set the value to null
    final newShadowColor = shadowColorGetter != null ? shadowColorGetter() : (shadowColor ?? currentElement.shadowColor);
    final newShadowOffset = shadowOffsetGetter != null ? shadowOffsetGetter() : (shadowOffset ?? currentElement.shadowOffset);
    final newShadowBlurRadius = shadowBlurRadius ?? currentElement.shadowBlurRadius;

    // Check if anything actually changed
    if (currentElement.shadowColor == newShadowColor &&
        currentElement.shadowOffset == newShadowOffset &&
        currentElement.shadowBlurRadius == newShadowBlurRadius) {
      return;
    }
    _saveStateForUndo();

    // Use dynamic dispatch for copyWith
    _selectedElement = (currentElement as dynamic).copyWith(
      shadowColor: newShadowColor, // Pass the resolved value
      shadowOffset: newShadowOffset, // Pass the resolved value
      shadowBlurRadius: newShadowBlurRadius.clamp(0.0, 100.0), // Min blur 0, Max 100 (arbitrary)
      // No need to pass ValueGetters to copyWith if they are resolved before this call
      // However, if copyWith itself is designed to handle ValueGetters, then pass them.
      // The current model's copyWith takes direct values after resolution.
    );

    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      _elements[index] = _selectedElement!;
    }
    notifyListeners();
  }
}
