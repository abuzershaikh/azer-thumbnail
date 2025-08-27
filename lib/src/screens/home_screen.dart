import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thumbnail_maker/src/providers/canvas_provider.dart';
import 'package:thumbnail_maker/src/models/element_model.dart';
import 'package:thumbnail_maker/src/widgets/toolbars/left_toolbar.dart';
import 'package:thumbnail_maker/src/widgets/toolbars/right_toolbar.dart';
import 'package:thumbnail_maker/src/widgets/toolbars/bottom_properties_toolbar.dart'; // Added import
import 'dart:math' as math;

enum ResizeHandleType { topLeft, topRight, bottomLeft, bottomRight, top, bottom, left, right }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  CanvasElement? _initialDragElement;
  ResizeHandleType? _currentHandleType;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(() {
      final newZoom = _transformationController.value.getMaxScaleOnAxis();
      Provider.of<CanvasProvider>(context, listen: false).setZoomLevel(newZoom);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _exportCanvasAsPng() async {
    // ... (existing export code)
    try {
      if (!mounted || _canvasKey.currentContext == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Canvas not ready.')));
        return;
      }
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Could not get image data.');
      Uint8List pngBytes = byteData.buffer.asUint8List();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Thumbnail as PNG',
        fileName: 'thumbnail-${DateTime.now().millisecondsSinceEpoch}.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.png')) {
          outputFile += '.png';
        }
        File savedFile = File(outputFile);
        await savedFile.writeAsBytes(pngBytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: ${savedFile.path}')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save cancelled.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _saveProject() async {
    // ... (existing save project code)
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Project',
        fileName: 'project.thumbnailproj',
        type: FileType.custom,
        allowedExtensions: ['thumbnailproj'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.thumbnailproj')) {
          outputFile += '.thumbnailproj';
        }
        await Provider.of<CanvasProvider>(context, listen: false).saveProject(outputFile);
        if (!mounted) return; 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project saved to: $outputFile')));
      } else {
         if (!mounted) return; 
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save project cancelled.')));
      }
    } catch (e) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving project: ${e.toString()}')));
    }
  }

  Future<void> _loadProject() async {
    // ... (existing load project code)
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Load Project',
        type: FileType.custom,
        allowedExtensions: ['thumbnailproj', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await Provider.of<CanvasProvider>(context, listen: false).loadProject(path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project loaded from: $path')));
      } else {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Load project cancelled.')));
      }
    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading project: ${e.toString()}')));
    }
  }


  Widget _buildElementWidget(CanvasElement element, CanvasProvider provider, double currentCanvasZoom) {
    print("[HomeScreen - _buildElementWidget] Rendering Element ID: ${element.id}, Size: ${element.size}, Pos: ${element.position}, Scale: ${element.scale}, Rotation: ${element.rotation}");
    Widget content;
    BoxDecoration? shapeDecoration;
    const double handleSize = 10.0; // Defined handle size

    if (element is ImageElement) {
      Widget imageWidget = Image.file(
        File(element.imagePath),
        width: element.size.width,
        height: element.size.height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: element.size.width, // Ensure error container also respects size for clipping
            height: element.size.height,
            color: Colors.red[100], alignment: Alignment.center, padding: const EdgeInsets.all(4),
            child: Text('Error: ${element.imagePath.split('/').last}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.red)),
          );
        },
      );

      if (element.cornerRadius > 0) {
        content = ClipRRect(
          borderRadius: BorderRadius.circular(element.cornerRadius),
          child: imageWidget,
        );
      } else {
        content = imageWidget;
      }

      // Apply border if specified
      if (element.borderWidth > 0 && element.borderColor != null) {
        content = Container(
          decoration: BoxDecoration(
            border: Border.all(color: element.borderColor!, width: element.borderWidth),
            borderRadius: element.cornerRadius > 0 ? BorderRadius.circular(element.cornerRadius) : null,
          ),
          child: content, // content is already the (potentially clipped) imageWidget
        );
      }

      // Apply border blur if specified
      if (element.borderBlurRadius > 0.0) {
        content = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: element.borderBlurRadius, sigmaY: element.borderBlurRadius),
          child: content, // content is the image, potentially clipped and with a regular border
        );
      }
    } else if (element is TextElement) {
      Widget fillText = Text(element.text, style: element.style, textAlign: element.textAlign);
      Widget? textContentWidget;

      if (element.outlineColor != null && element.outlineWidth > 0) {
        textContentWidget = Stack(
          alignment: Alignment.center,
          children: [
            Text(
              element.text,
              textAlign: element.textAlign,
              style: element.style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = element.outlineWidth
                  ..color = element.outlineColor!,
              ),
            ),
            fillText,
          ],
        );
      } else {
        textContentWidget = fillText;
      }

      if (element.textBackgroundColor != null) {
        content = Container(
          // Size of this container should match the TextElement's calculated size for background to fit tightly.
          // The TextPainter's calculated size is stored in element.size.
          width: element.size.width,
          height: element.size.height,
          padding: const EdgeInsets.all(4.0), // Consider if padding should scale: 4.0 * element.scale
          decoration: BoxDecoration(color: element.textBackgroundColor),
          child: textContentWidget,
        );
      } else {
        content = textContentWidget;
      }

    } else if (element is RectangleElement) {
      shapeDecoration = BoxDecoration(
        color: element.color,
        border: (element.outlineColor != null && element.outlineWidth > 0)
            ? Border.all(color: element.outlineColor!, width: element.outlineWidth)
            : null,
        borderRadius: element.cornerRadius > 0
            ? BorderRadius.circular(element.cornerRadius)
            : null,
      );
      content = SizedBox(width: element.size.width, height: element.size.height);
    } else if (element is CircleElement) {
      shapeDecoration = BoxDecoration(
        color: element.color,
        shape: BoxShape.circle,
        border: (element.outlineColor != null && element.outlineWidth > 0)
            ? Border.all(color: element.outlineColor!, width: element.outlineWidth)
            : null,
      );
      content = SizedBox(width: element.size.width, height: element.size.height);
    } else {
      content = const SizedBox.shrink();
    }

    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.size.width,
      height: element.size.height,
      child: GestureDetector(
        onTap: () => provider.selectElement(element),
        onScaleStart: (details) {
          if (element.isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Element is locked."), duration: Duration(milliseconds: 1200)));
            return;
          }
          provider.onElementGestureStart(element);
        },
        onScaleUpdate: (details) {
          if (element.isLocked) return;
          if (details.pointerCount > 1 || (details.scale - 1.0).abs() > 0.01 || details.rotation.abs() > 0.01) {
            provider.scaleAndRotateElement(details);
          } else if (details.pointerCount == 1) {
            Offset panDelta = details.focalPointDelta / currentCanvasZoom;
            setState(() => element.position += panDelta);
          }
        },
        onScaleEnd: (details) {
          if (element.isLocked) return;
          provider.onElementGestureEnd();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(element.size.width / 2, element.size.height / 2)
                ..rotateZ(element.rotation)
                ..scale(element.scale)
                ..translate(-element.size.width / 2, -element.size.height / 2),
              child: Opacity( // Apply opacity here, around the actual content
                opacity: element.opacity,
                child: Container(
                  width: element.size.width,
                  height: element.size.height,
                  decoration: _buildElementDecoration(element, shapeDecoration), // Updated to use a helper for decoration
                  child: (element is ImageElement || element is TextElement) ? content : null,
                ),
              ),
            ),
            if (element.isLocked)
              Positioned(
                top: 0, right: 0,
                child: Transform.scale(
                  scale: 1.0 / (element.scale * currentCanvasZoom),
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.all(2.0 / (element.scale * currentCanvasZoom)),
                    color: Colors.black.withAlpha((255 * 0.1).round()),
                    child: Icon(Icons.lock, color: Colors.white.withAlpha((255 * 0.7).round()), size: 16.0),
                  ),
                ),
              ),
            // Selection border: Common for all, drawn on top if selected and not locked
            if (provider.selectedElement?.id == element.id && !element.isLocked)
              Positioned.fill(
                child: Transform( // Apply same transform as the element for the border
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(element.size.width / 2, element.size.height / 2)
                    ..rotateZ(element.rotation)
                    ..scale(element.scale)
                    ..translate(-element.size.width / 2, -element.size.height / 2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: element is CircleElement ? BoxShape.circle : BoxShape.rectangle,
                      border: Border.all(
                        color: Colors.blueAccent,
                        width: 2.0 / (element.scale * currentCanvasZoom), // Make border width visually consistent
                      ),
                    ),
                  ),
                ),
              ),
            // Resize handles
            if (provider.selectedElement?.id == element.id && !element.isLocked)
              ..._buildResizeHandles(element, currentCanvasZoom, handleSize, provider),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildElementDecoration(CanvasElement element, BoxDecoration? existingShapeDecoration) {
    List<BoxShadow>? currentBoxShadows;
    if (element.shadowColor != null && element.shadowBlurRadius >= 0.0 && element.shadowColor!.alpha > 0) {
      // Apply element's base opacity to shadow's color opacity
      // Shadow color's own alpha is already part of element.shadowColor.alpha
      // Element's overall opacity is handled by the Opacity widget wrapper.
      // So, use element.shadowColor directly.
      currentBoxShadows = [
        BoxShadow(
          color: element.shadowColor!,
          blurRadius: element.shadowBlurRadius,
          offset: element.shadowOffset ?? const Offset(2, 2), // Default offset if null
        ),
      ];
    }

    BorderRadius? decorationBorderRadius;
    BoxShape shape = BoxShape.rectangle;

    if (element is ImageElement && element.cornerRadius > 0) {
      decorationBorderRadius = BorderRadius.circular(element.cornerRadius);
    } else if (element is RectangleElement && element.cornerRadius > 0) {
      decorationBorderRadius = BorderRadius.circular(element.cornerRadius);
    } else if (element is CircleElement) {
      shape = BoxShape.circle; // Circle shape for shadow and main decoration
    }

    if (existingShapeDecoration != null) {
      // For shape elements, merge with their existing decoration
      return existingShapeDecoration.copyWith(
        boxShadow: currentBoxShadows,
        // Ensure shape and borderRadius are consistent if they were already set
        shape: (element is CircleElement) ? BoxShape.circle : existingShapeDecoration.shape,
        borderRadius: (element is! CircleElement) ? (decorationBorderRadius ?? existingShapeDecoration.borderRadius) : null,
      );
    } else {
      // For ImageElement and TextElement (which don't have existingShapeDecoration from this function's input)
      return BoxDecoration(
        shape: shape, // Will be rectangle unless it's a CircleElement (which is not the case here)
        borderRadius: decorationBorderRadius,
        boxShadow: currentBoxShadows,
        // color: element is TextElement && element.textBackgroundColor != null ? element.textBackgroundColor : null, // Background color for text elements is handled by their 'content'
      );
    }
  }

  List<Widget> _buildResizeHandles(CanvasElement element, double currentCanvasZoom, double baseHandleSize, CanvasProvider provider) {
    final double visualHandleSize = baseHandleSize / (element.scale * currentCanvasZoom);
    final double handleOffset = -visualHandleSize / 2;

    // Helper to create a handle widget
    Widget createHandle({required ResizeHandleType handleType}) { // Removed alignment parameter
      // Determine alignment and positioning based on handleType
      double? left, top, right, bottom;
      switch (handleType) {
        case ResizeHandleType.topLeft:
          left = handleOffset;
          top = handleOffset;
          break;
        case ResizeHandleType.topRight:
          right = handleOffset;
          top = handleOffset;
          break;
        case ResizeHandleType.bottomLeft:
          left = handleOffset;
          bottom = handleOffset;
          break;
        case ResizeHandleType.bottomRight:
          right = handleOffset;
          bottom = handleOffset;
          break;
        case ResizeHandleType.top:
          top = handleOffset;
          left = element.size.width / 2 - visualHandleSize / 2; // Centered
          break;
        case ResizeHandleType.bottom:
          bottom = handleOffset;
          left = element.size.width / 2 - visualHandleSize / 2; // Centered
          break;
        case ResizeHandleType.left:
          left = handleOffset;
          top = element.size.height / 2 - visualHandleSize / 2; // Centered
          break;
        case ResizeHandleType.right:
          right = handleOffset;
          top = element.size.height / 2 - visualHandleSize / 2; // Centered
          break;
      }

      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        child: GestureDetector(
          onPanStart: (details) {
            if (element.isLocked) return;
            setState(() {
              _initialDragElement = element.copyWith();
              _currentHandleType = handleType;
            });
            provider.onElementGestureStart(element); // For undo state
          },
          onPanUpdate: (details) {
            if (_initialDragElement == null || _currentHandleType == null || element.isLocked) return;

            // final initialElement = _initialDragElement!; // REMOVED - Use 'element' from closure
            Offset canvasDelta = details.delta / currentCanvasZoom;

            // Rotate canvasDelta by -element.rotation to get localDelta
            Offset localDelta = Offset(
              canvasDelta.dx * math.cos(-element.rotation) - canvasDelta.dy * math.sin(-element.rotation),
              canvasDelta.dx * math.sin(-element.rotation) + canvasDelta.dy * math.cos(-element.rotation),
            );

            Size newSize = element.size; // Base newSize on current element's size
            Offset newPosition = element.position; // Base newPosition on current element's position

            double minSize = 10.0;

            switch (_currentHandleType!) {
              case ResizeHandleType.topLeft:
                double potentialNewWidth = element.size.width - localDelta.dx;
                double potentialNewHeight = element.size.height - localDelta.dy;

                double actualNewWidth = math.max(minSize, potentialNewWidth);
                double actualNewHeight = math.max(minSize, potentialNewHeight);
                
                newSize = Size(actualNewWidth, actualNewHeight);

                double actualDeltaXForPosition = element.size.width - actualNewWidth;
                double actualDeltaYForPosition = element.size.height - actualNewHeight;
                
                Offset actualLocalDeltaForPosition = Offset(actualDeltaXForPosition, actualDeltaYForPosition);

                Offset positionDelta = Offset(
                  actualLocalDeltaForPosition.dx * math.cos(element.rotation) - actualLocalDeltaForPosition.dy * math.sin(element.rotation),
                  actualLocalDeltaForPosition.dx * math.sin(element.rotation) + actualLocalDeltaForPosition.dy * math.cos(element.rotation),
                );
                newPosition = element.position + positionDelta;
                break;
              case ResizeHandleType.topRight:
                double potentialNewWidth = element.size.width + localDelta.dx;
                double potentialNewHeight = element.size.height - localDelta.dy;

                double actualNewWidth = math.max(minSize, potentialNewWidth);
                double actualNewHeight = math.max(minSize, potentialNewHeight);

                newSize = Size(actualNewWidth, actualNewHeight);

                double actualDeltaYForPosition = element.size.height - actualNewHeight;
                
                Offset actualLocalDeltaForPosition = Offset(0, actualDeltaYForPosition); 

                Offset positionDelta = Offset(
                  -actualLocalDeltaForPosition.dy * math.sin(element.rotation), 
                  actualLocalDeltaForPosition.dy * math.cos(element.rotation),   
                );
                newPosition = element.position + positionDelta;
                break;
              case ResizeHandleType.bottomLeft:
                double potentialNewWidth = element.size.width - localDelta.dx;
                double potentialNewHeight = element.size.height + localDelta.dy;

                double actualNewWidth = math.max(minSize, potentialNewWidth);
                double actualNewHeight = math.max(minSize, potentialNewHeight);

                newSize = Size(actualNewWidth, actualNewHeight);

                double actualDeltaXForPosition = element.size.width - actualNewWidth;
                
                Offset actualLocalDeltaForPosition = Offset(actualDeltaXForPosition, 0); 

                Offset positionDelta = Offset(
                  actualLocalDeltaForPosition.dx * math.cos(element.rotation), 
                  actualLocalDeltaForPosition.dx * math.sin(element.rotation),  
                );
                newPosition = element.position + positionDelta;
                break;
              case ResizeHandleType.bottomRight:
                double newWidth = element.size.width + localDelta.dx;
                double newHeight = element.size.height + localDelta.dy;
                if (newWidth < minSize) newWidth = minSize;
                if (newHeight < minSize) newHeight = minSize;
                newSize = Size(newWidth, newHeight);
                // Position does not change from element.position
                break;
              case ResizeHandleType.top:
                double potentialNewHeight = element.size.height - localDelta.dy;
                double actualNewHeight = math.max(minSize, potentialNewHeight);
                newSize = Size(element.size.width, actualNewHeight);

                double actualDeltaYForPosition = element.size.height - actualNewHeight;
                Offset actualLocalDeltaForPosition = Offset(0, actualDeltaYForPosition);

                Offset positionDelta = Offset(
                  -actualLocalDeltaForPosition.dy * math.sin(element.rotation), 
                  actualLocalDeltaForPosition.dy * math.cos(element.rotation)    
                );
                newPosition = element.position + positionDelta;
                break;
              case ResizeHandleType.bottom:
                double newHeight = element.size.height + localDelta.dy;
                if (newHeight < minSize) newHeight = minSize;
                newSize = Size(element.size.width, newHeight);
                // Position does not change from element.position
                break;
              case ResizeHandleType.left:
                double potentialNewWidth = element.size.width - localDelta.dx;
                double actualNewWidth = math.max(minSize, potentialNewWidth);
                newSize = Size(actualNewWidth, element.size.height);

                double actualDeltaXForPosition = element.size.width - actualNewWidth;
                Offset actualLocalDeltaForPosition = Offset(actualDeltaXForPosition, 0);
                
                Offset positionDelta = Offset(
                  actualLocalDeltaForPosition.dx * math.cos(element.rotation), 
                  actualLocalDeltaForPosition.dx * math.sin(element.rotation)   
                );
                newPosition = element.position + positionDelta;
                break;
              case ResizeHandleType.right:
                double newWidth = element.size.width + localDelta.dx;
                if (newWidth < minSize) newWidth = minSize;
                newSize = Size(newWidth, element.size.height);
                // Position does not change from element.position
                break;
            }
            // Update debug print to use 'element' for consistency, or _initialDragElement if that's what's intended for "Initial"
            print("[HomeScreen - onPanUpdate] Handle: $_currentHandleType, Current Element Size: ${element.size}, Current Element Pos: ${element.position}");
            print("[HomeScreen - onPanUpdate] LocalDelta: $localDelta, CanvasDelta: $canvasDelta");
            print("[HomeScreen - onPanUpdate] Calculated New Size: $newSize, New Position: $newPosition");
            provider.updateSelectedElementSizeAndPosition(newPosition, newSize);
          },
          onPanEnd: (details) {
            if (element.isLocked) return;
            provider.onElementGestureEnd();
            setState(() {
              _initialDragElement = null;
              _currentHandleType = null;
            });
          },
          child: Container(
            width: visualHandleSize,
            height: visualHandleSize,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 0.5 / (element.scale * currentCanvasZoom),
              ),
            ),
          ),
        ),
      );
    }

    return [
      createHandle(handleType: ResizeHandleType.topLeft),
      createHandle(handleType: ResizeHandleType.topRight),
      createHandle(handleType: ResizeHandleType.bottomLeft),
      createHandle(handleType: ResizeHandleType.bottomRight),
      createHandle(handleType: ResizeHandleType.top),
      createHandle(handleType: ResizeHandleType.bottom),
      createHandle(handleType: ResizeHandleType.left),
      createHandle(handleType: ResizeHandleType.right),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of build method is unchanged)
    final canvasProvider = Provider.of<CanvasProvider>(context);
    double currentCanvasZoom = canvasProvider.zoomLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Thumbnail Maker'),
        backgroundColor: Colors.redAccent,
        actions: [
          Consumer<CanvasProvider>(builder: (context, provider, child) => IconButton(icon: const Icon(Icons.undo), tooltip: 'Undo', onPressed: provider.canUndo ? provider.undo : null)),
          Consumer<CanvasProvider>(builder: (context, provider, child) => IconButton(icon: const Icon(Icons.redo), tooltip: 'Redo', onPressed: provider.canRedo ? provider.redo : null)),
          IconButton(icon: const Icon(Icons.folder_open), tooltip: 'Load Project', onPressed: _loadProject),
          IconButton(icon: const Icon(Icons.save), tooltip: 'Save Project', onPressed: _saveProject),
          IconButton(icon: const Icon(Icons.save_alt), tooltip: 'Export as PNG', onPressed: _exportCanvasAsPng),
          IconButton(icon: const Icon(Icons.zoom_out), tooltip: 'Zoom Out', onPressed: () {
              const double scaleFactor = 1.2;
              final currentZoomVal = _transformationController.value.getMaxScaleOnAxis();
              double newScale = (currentZoomVal / scaleFactor).clamp(0.05, 10.0);
              _transformationController.value = Matrix4.identity()..scale(newScale);
            },
          ),
          IconButton(icon: const Icon(Icons.zoom_in), tooltip: 'Zoom In', onPressed: () {
              const double scaleFactor = 1.2;
              final currentZoomVal = _transformationController.value.getMaxScaleOnAxis();
              double newScale = (currentZoomVal * scaleFactor).clamp(0.05, 10.0);
              _transformationController.value = Matrix4.identity()..scale(newScale);
            },
          ),
        ],
      ),
      body: Column( // New Column
        children: [
          Expanded( // Existing Row content is now the first child of Column, wrapped in Expanded
            child: Row(
              children: [
                const LeftToolbar(),
                Expanded(
                  child: Container(
                    color: Colors.grey[800],
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: 0.05,
                      maxScale: 10.0,
                      onInteractionEnd: (details) {
                         Provider.of<CanvasProvider>(context, listen: false).setZoomLevel(_transformationController.value.getMaxScaleOnAxis());
                      },
                      child: Center(
                        child: RepaintBoundary(
                          key: _canvasKey,
                          child: Container(
                            width: 1280,
                            height: 720,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              // Background color is now handled by the first layer of the Stack below
                              border: Border.all(color: Colors.black54, width: 1.0 / currentCanvasZoom),
                            ),
                            child: Stack( // New Stack for background and elements
                              fit: StackFit.expand,
                              children: [
                                // Background Image Layer
                                Consumer<CanvasProvider>(
                                  builder: (context, provider, child) {
                                    String? bgImagePath = provider.backgroundImagePathValue;
                                    BoxFit? bgFit = provider.backgroundFitValue;
                                    if (bgImagePath != null) {
                                      File imageFile = File(bgImagePath);
                                      return Image.file(
                                        imageFile,
                                        width: 1280,
                                        height: 720,
                                        fit: bgFit ?? BoxFit.contain, // Default fit
                                        errorBuilder: (context, error, stackTrace) {
                                          // On error, fallback to background color
                                          // print("Error loading background image: $error"); // REMOVED
                                          return Container(color: provider.backgroundColor);
                                        },
                                      );
                                    } else {
                                      // No background image, just use background color
                                      return Container(color: provider.backgroundColor);
                                    }
                                  },
                                ),
                                // Elements Layer
                                Consumer<CanvasProvider>(
                                  builder: (context, provider, child) {
                                    return Stack(
                                      children: provider.elements.map((element) {
                                        return _buildElementWidget(element, provider, currentCanvasZoom);
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const RightToolbar(),
              ],
            ),
          ),
          const SizedBox(height: 70, child: ClipRect(child: BottomPropertiesToolbar())), // Add the new toolbar here
        ],
      ),
    );
  }
}