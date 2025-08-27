import 'dart:io'; // For Platform.isWindows
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thumbnail_maker/src/providers/canvas_provider.dart';
import 'package:thumbnail_maker/src/models/element_model.dart';
import 'dart:math' as math; // For pi

class RightToolbar extends StatefulWidget {
  const RightToolbar({super.key});

  @override
  State<RightToolbar> createState() => _RightToolbarState();
}

class _RightToolbarState extends State<RightToolbar> {
  final TextEditingController _textEditingController = TextEditingController();
  Key _textFormFieldKey = UniqueKey();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  String _formatDouble(double value, {int places = 2}) {
    return value.toStringAsFixed(places);
  }

  String _getFileName(String path) {
    try {
      return path.split(Platform.isWindows ? '\\' : '/').last;
    } catch (e) {
      return path.length > 20 ? '...${path.substring(path.length - 20)}' : path;
    }
  }

  void _updateTextElement(CanvasProvider provider, TextElement element, {
    String? text,
    double? fontSizeDelta,
    Color? color,
    Color? textBackgroundColor,
    bool clearTextBackgroundColor = false,
    Color? outlineColor,
    bool clearOutlineColor = false,
    double? outlineWidthDelta,
  }) {
    if (element.isLocked) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Element is locked."), duration: Duration(milliseconds: 1200)));
      return;
    }
    TextStyle newStyle = element.style;
    if (fontSizeDelta != null) {
      double newFontSize = (element.style.fontSize ?? 16) + fontSizeDelta;
      newStyle = element.style.copyWith(fontSize: newFontSize.clamp(8, 200));
    }
    if (color != null) {
      newStyle = element.style.copyWith(color: color);
    }

    double newOutlineWidth = element.outlineWidth;
    if (outlineWidthDelta != null) {
      newOutlineWidth = (element.outlineWidth + outlineWidthDelta).clamp(0.0, 20.0);
    }

    provider.updateElement(element.copyWith(
      text: text ?? element.text,
      style: newStyle,
      textBackgroundColorGetter: clearTextBackgroundColor ? () => null : null,
      textBackgroundColor: clearTextBackgroundColor ? null : (textBackgroundColor ?? element.textBackgroundColor),
      outlineColorGetter: clearOutlineColor ? () => null : null,
      outlineColor: clearOutlineColor ? null : (outlineColor ?? element.outlineColor),
      outlineWidth: newOutlineWidth,
    ));
  }

  void _updateShapeElement(CanvasProvider provider, CanvasElement element, {
    Color? fillColor,
    Color? outlineColor,
    bool clearOutlineColor = false,
    double? outlineWidthDelta,
    Size? newSize // Not used for MVP outline/fill, but kept for signature consistency
  }) {
    if (element.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Element is locked."), duration: Duration(milliseconds: 1200)));
      return;
    }

    double newOutlineWidth = 0.0;
    if (element is RectangleElement) newOutlineWidth = element.outlineWidth;
    if (element is CircleElement) newOutlineWidth = element.outlineWidth;

    if (outlineWidthDelta != null) {
      newOutlineWidth = (newOutlineWidth + outlineWidthDelta).clamp(0.0, 20.0);
    }

     if (element is RectangleElement) {
        provider.updateElement(element.copyWith(
          color: fillColor ?? element.color,
          outlineColorGetter: clearOutlineColor ? () => null : null,
          outlineColor: clearOutlineColor ? null : (outlineColor ?? element.outlineColor),
          outlineWidth: newOutlineWidth,
          size: newSize ?? element.size
        ));
     } else if (element is CircleElement) {
        provider.updateElement(element.copyWith(
          color: fillColor ?? element.color,
          outlineColorGetter: clearOutlineColor ? () => null : null,
          outlineColor: clearOutlineColor ? null : (outlineColor ?? element.outlineColor),
          outlineWidth: newOutlineWidth,
          radius: newSize != null ? newSize.width / 2 : element.radius // Keep radius update logic if newSize is passed
        ));
     }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasProvider>(
      builder: (context, canvasProvider, child) {
        final selectedElement = canvasProvider.selectedElement;
        final elements = canvasProvider.elements;
        final canvasProviderNoListen = Provider.of<CanvasProvider>(context, listen: false);
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final TextTheme textTheme = Theme.of(context).textTheme;

        int selectedElementIndex = -1;
        if (selectedElement != null) {
          selectedElementIndex = elements.indexWhere((e) => e.id == selectedElement.id);
        }

        bool isElementLocked = selectedElement?.isLocked ?? false;
        bool canSendBackward = selectedElement != null && selectedElementIndex > 0 && !isElementLocked;
        bool canBringForward = selectedElement != null && selectedElementIndex < elements.length - 1 && selectedElementIndex != -1 && !isElementLocked;

        if (selectedElement is TextElement && _textEditingController.text != selectedElement.text) {
          _textEditingController.text = selectedElement.text;
          _textFormFieldKey = UniqueKey();
        } else if (selectedElement == null || selectedElement is! TextElement) {
           _textEditingController.clear();
        }

        return Container(
          width: 230,
          color: colorScheme.surfaceContainerLow, // Updated background color
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Canvas Tools', textAlign: TextAlign.center, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildCanvasTools(context, canvasProviderNoListen, colorScheme),

                const Divider(height: 30, thickness: 1.5),

                Text('Selected Element', textAlign: TextAlign.center, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (selectedElement == null)
                  const Center(child: Text('No element selected.', textAlign: TextAlign.center,))
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('ID: ${selectedElement.id.substring(0,6)}...', style: textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: Icon(selectedElement.isLocked ? Icons.lock : Icons.lock_open),
                        tooltip: selectedElement.isLocked ? 'Unlock Element' : 'Lock Element',
                        onPressed: () {
                          canvasProviderNoListen.toggleElementLock();
                        },
                        color: selectedElement.isLocked ? Colors.orangeAccent[700] : colorScheme.onSurfaceVariant, // Updated color
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildLayerControls(context, canvasProviderNoListen, canBringForward, canSendBackward, isElementLocked, textTheme), // Pass textTheme
                  const SizedBox(height: 10),
                  _buildPropertyRow('Type:', selectedElement.type.toString().split('.').last, textTheme),
                  _buildPropertyRow('Scale:', _formatDouble(selectedElement.scale), textTheme),
                  _buildPropertyRow('Rotation:', '${_formatDouble(selectedElement.rotation * 180 / math.pi, places: 1)}°', textTheme),
                  _buildPropertyRow('X:', _formatDouble(selectedElement.position.dx, places: 1), textTheme),
                  _buildPropertyRow('Y:', _formatDouble(selectedElement.position.dy, places: 1), textTheme),

                  if (selectedElement is ImageElement) ..._buildImageSpecificProperties(selectedElement, isElementLocked, textTheme),
                  if (selectedElement is TextElement) ..._buildTextSpecificProperties(context, canvasProviderNoListen, selectedElement, isElementLocked, colorScheme, textTheme),
                  if (selectedElement is RectangleElement) ..._buildShapeProperties(context, canvasProviderNoListen, selectedElement, isElementLocked, colorScheme, textTheme, isRect: true),
                  if (selectedElement is CircleElement) ..._buildShapeProperties(context, canvasProviderNoListen, selectedElement, isElementLocked, colorScheme, textTheme, isRect: false),

                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.tonal( // Changed to FilledButton.tonal
                      onPressed: () => canvasProviderNoListen.selectElement(null),
                      child: const Text('Deselect'),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayerControls(BuildContext context, CanvasProvider provider, bool canBringForward, bool canSendBackward, bool isLocked, TextTheme textTheme) { // Add textTheme
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layering:', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.vertical_align_bottom), tooltip: 'Send to Back', onPressed: canSendBackward ? provider.sendToBack : null),
            IconButton(icon: const Icon(Icons.keyboard_arrow_down), tooltip: 'Send Backward', onPressed: canSendBackward ? provider.sendBackward : null),
            IconButton(icon: const Icon(Icons.keyboard_arrow_up), tooltip: 'Bring Forward', onPressed: canBringForward ? provider.bringForward : null),
            IconButton(icon: const Icon(Icons.vertical_align_top), tooltip: 'Bring to Front', onPressed: canBringForward ? provider.bringToFront : null),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildImageSpecificProperties(ImageElement element, bool isLocked, TextTheme textTheme) {
     return [
      _buildPropertyRow('File:', _getFileName(element.imagePath), textTheme, overflow: TextOverflow.ellipsis),
      _buildPropertyRow('Orig. W:', '${_formatDouble(element.size.width, places: 0)}px', textTheme),
      _buildPropertyRow('Orig. H:', '${_formatDouble(element.size.height, places: 0)}px', textTheme),
      _buildPropertyRow('Disp. W:', '${_formatDouble(element.size.width * element.scale, places: 1)}px', textTheme),
      _buildPropertyRow('Disp. H:', '${_formatDouble(element.size.height * element.scale, places: 1)}px', textTheme),
    ];
  }

  List<Widget> _buildTextSpecificProperties(BuildContext context, CanvasProvider provider, TextElement element, bool isLocked, ColorScheme colorScheme, TextTheme textTheme) {
    return [
      const SizedBox(height: 8),
      TextFormField(
        key: _textFormFieldKey,
        initialValue: element.text,
        enabled: !isLocked,
        decoration: const InputDecoration(labelText: 'Text Content', border: OutlineInputBorder(), isDense: true),
        onChanged: (newText) {
           if(!isLocked) _updateTextElement(provider, element, text: newText);
        },
      ),
      const SizedBox(height: 10),
      _buildPropertyRow('Font Size:', _formatDouble(element.style.fontSize ?? 0, places: 0), textTheme),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: const Icon(Icons.remove), tooltip: "Decrease font size", onPressed: isLocked ? null : () => _updateTextElement(provider, element, fontSizeDelta: -2)),
        IconButton(icon: const Icon(Icons.add), tooltip: "Increase font size", onPressed: isLocked ? null : () => _updateTextElement(provider, element, fontSizeDelta: 2)),
      ]),
      const SizedBox(height: 8),
      Text('Font Color:', style: textTheme.bodyMedium),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.black, colorScheme, isTextFontColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.red, colorScheme, isTextFontColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.white, colorScheme, isTextFontColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.blue, colorScheme, isTextFontColor: true, isLocked: isLocked),
      ]),
      const SizedBox(height: 10),
      Text('Background Color:', style: textTheme.bodyMedium),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.transparent, colorScheme, isTextBg: true, clearColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.yellowAccent, colorScheme, isTextBg: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.lightBlueAccent, colorScheme, isTextBg: true, isLocked: isLocked),
        _colorButton(context, provider, element, colorScheme.surfaceContainerHighest, colorScheme, isTextBg: true, isLocked: isLocked), // Use colorScheme
      ]),
       const SizedBox(height: 10),
      Text('Outline Color:', style: textTheme.bodyMedium),
       Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.transparent, colorScheme, isOutline: true, clearColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.black, colorScheme, isOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.white, colorScheme, isOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.red, colorScheme, isOutline: true, isLocked: isLocked),
      ]),
      const SizedBox(height: 8),
      _buildPropertyRow('Outline Width:', _formatDouble(element.outlineWidth, places: 1), textTheme),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: const Icon(Icons.remove), tooltip: "Decrease outline width", onPressed: isLocked ? null : () => _updateTextElement(provider, element, outlineWidthDelta: -0.5)),
        IconButton(icon: const Icon(Icons.add), tooltip: "Increase outline width", onPressed: isLocked ? null : () => _updateTextElement(provider, element, outlineWidthDelta: 0.5)),
      ]),
      _buildPropertyRow('Box W:', '${_formatDouble(element.size.width * element.scale, places: 1)}px', textTheme),
      _buildPropertyRow('Box H:', '${_formatDouble(element.size.height* element.scale, places: 1)}px', textTheme),
    ];
  }

  List<Widget> _buildShapeProperties(BuildContext context, CanvasProvider provider, CanvasElement element, bool isLocked, ColorScheme colorScheme, TextTheme textTheme, {required bool isRect}) {
    Color currentFillColor = Colors.transparent;
    Color? currentOutlineColor;
    double currentOutlineWidth = 0.0;

    if (element is RectangleElement) {
      currentFillColor = element.color;
      currentOutlineColor = element.outlineColor;
      currentOutlineWidth = element.outlineWidth;
    } else if (element is CircleElement) {
      currentFillColor = element.color;
      currentOutlineColor = element.outlineColor;
      currentOutlineWidth = element.outlineWidth;
    }

    return [
      const SizedBox(height: 8),
      Text('Fill Color:', style: textTheme.bodyMedium),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.blue, colorScheme, isLocked: isLocked, isShapeFill: true),
        _colorButton(context, provider, element, Colors.green, colorScheme, isLocked: isLocked, isShapeFill: true),
        _colorButton(context, provider, element, Colors.yellow, colorScheme, isLocked: isLocked, isShapeFill: true),
        _colorButton(context, provider, element, Colors.orange, colorScheme, isLocked: isLocked, isShapeFill: true),
      ]),
      const SizedBox(height: 10),
      Text('Outline Color:', style: textTheme.bodyMedium),
       Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.transparent, colorScheme, isShapeOutline: true, clearColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.black, colorScheme, isShapeOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.white, colorScheme, isShapeOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.red, colorScheme, isShapeOutline: true, isLocked: isLocked),
      ]),
      const SizedBox(height: 8),
      _buildPropertyRow('Outline Width:', _formatDouble(currentOutlineWidth, places: 1), textTheme),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: const Icon(Icons.remove), tooltip: "Decrease outline width", onPressed: isLocked ? null : () => _updateShapeElement(provider, element, outlineWidthDelta: -0.5)),
        IconButton(icon: const Icon(Icons.add), tooltip: "Increase outline width", onPressed: isLocked ? null : () => _updateShapeElement(provider, element, outlineWidthDelta: 0.5)),
      ]),
      if (isRect && element is RectangleElement) ...[
         _buildPropertyRow('Base W:', '${_formatDouble(element.size.width, places: 1)}px', textTheme),
         _buildPropertyRow('Base H:', '${_formatDouble(element.size.height, places: 1)}px', textTheme),
      ] else if (!isRect && element is CircleElement) ...[
        _buildPropertyRow('Radius:', '${_formatDouble(element.radius, places: 1)}px', textTheme),
      ]
    ];
  }

  Widget _buildPropertyRow(String label, String value, TextTheme textTheme, {TextOverflow overflow = TextOverflow.clip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), // Updated style
        const SizedBox(width: 8),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), overflow: overflow)), // Updated style
      ]),
    );
  }

  Widget _colorButton(BuildContext context, CanvasProvider provider, CanvasElement element, Color color, ColorScheme colorScheme, {
    bool isTextFontColor = false, bool isLocked = false,
    bool isTextBg = false, bool isOutline = false,
    bool isShapeFill = false, bool isShapeOutline = false,
    bool clearColor = false
  }) {
    bool isSelectedColor = false;
    Color? actualColorToCompare;

    if (isTextFontColor && element is TextElement) {
      actualColorToCompare = element.style.color;
    } else if (isTextBg && element is TextElement) actualColorToCompare = element.textBackgroundColor;
    else if (isOutline && element is TextElement) actualColorToCompare = element.outlineColor;
    else if (isShapeFill && element is RectangleElement) actualColorToCompare = element.color;
    else if (isShapeFill && element is CircleElement) actualColorToCompare = element.color;
    else if (isShapeOutline && element is RectangleElement) actualColorToCompare = element.outlineColor;
    else if (isShapeOutline && element is CircleElement) actualColorToCompare = element.outlineColor;

    isSelectedColor = clearColor ? actualColorToCompare == null : actualColorToCompare == color;

    return InkWell(
      onTap: isLocked ? null : () {
        if (element is TextElement) {
           _updateTextElement(provider, element,
            color: isTextFontColor ? color : null,
            textBackgroundColor: isTextBg && !clearColor ? color : null,
            clearTextBackgroundColor: isTextBg && clearColor,
            outlineColor: isOutline && !clearColor ? color : null,
            clearOutlineColor: isOutline && clearColor,
           );
        } else if (element is RectangleElement || element is CircleElement) {
          _updateShapeElement(provider, element,
            fillColor: isShapeFill ? color : null,
            outlineColor: isShapeOutline && !clearColor ? color : null,
            clearOutlineColor: isShapeOutline && clearColor
          );
        }
      },
      child: Opacity(
        opacity: isLocked && !isSelectedColor ? 0.5 : 1.0,
        child: Container(
          width: 28, height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: clearColor ? colorScheme.surfaceContainerHighest : color, // Updated clear color
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outlineVariant, width: (color == Colors.white || isSelectedColor) ? 2 : 0.5), // Updated border color
            boxShadow: isSelectedColor ? [const BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)] : [],
          ),
           child: clearColor && actualColorToCompare == null ? Icon(Icons.check, color: colorScheme.onSurfaceVariant, size: 16) // Updated icon color
                 : (isSelectedColor && !clearColor ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null),
        ),
      ),
    );
  }

   Widget _buildCanvasTools(BuildContext context, CanvasProvider canvasProviderNoListen, ColorScheme colorScheme) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Background:', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        FilledButton.tonal(onPressed: () => canvasProviderNoListen.changeBackgroundColor(Colors.white), child: const Text('White')),
        FilledButton.tonal(onPressed: () => canvasProviderNoListen.changeBackgroundColor(colorScheme.surfaceContainerLow), child: const Text('Theme Aware Grey')),
        FilledButton.tonal(onPressed: () => canvasProviderNoListen.changeBackgroundColor(Colors.black), child: const Text('Black')),
        FilledButton.tonal(onPressed: () => canvasProviderNoListen.changeBackgroundColor(Colors.red.shade100), child: const Text('Light Red')),

        const SizedBox(height: 12),
        Text('Background Image:', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        FilledButton.tonal( // Changed to FilledButton.tonal
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null && result.files.single.path != null) {
              String imagePath = result.files.single.path!;
              BoxFit currentFit = Provider.of<CanvasProvider>(context, listen: false).backgroundFitValue ?? BoxFit.contain;
              Provider.of<CanvasProvider>(context, listen: false).setBackgroundImage(imagePath, currentFit);
            }
          },
          child: const Text('Set Image'),
        ),
        Consumer<CanvasProvider>( 
          builder: (context, provider, child) {
            return FilledButton.tonal( // Changed to FilledButton.tonal
              onPressed: provider.backgroundImagePathValue != null
                  ? () {
                      Provider.of<CanvasProvider>(context, listen: false).setBackgroundImage(null, null);
                    }
                  : null,
              style: provider.backgroundImagePathValue != null 
                   ? FilledButton.styleFrom(backgroundColor: colorScheme.errorContainer, foregroundColor: colorScheme.onErrorContainer) 
                   : null,
              child: const Text('Clear Image'),
            );
          }
        ),
        Consumer<CanvasProvider>( // Consumer for Dropdown visibility and value
          builder: (context, provider, child) {
            if (provider.backgroundImagePathValue != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: DropdownButtonFormField<BoxFit>(
                  value: provider.backgroundFitValue ?? BoxFit.contain,
                  hint: const Text("Fit"),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Image Fit",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                  items: BoxFit.values.map((BoxFit fit) {
                    return DropdownMenuItem<BoxFit>(
                      value: fit,
                      child: Text(fit.name),
                    );
                  }).toList(),
                  onChanged: (BoxFit? newValue) {
                    if (newValue != null) {
                      Provider.of<CanvasProvider>(context, listen: false).setBackgroundImage(
                        provider.backgroundImagePathValue!,
                        newValue,
                      );
                    }
                  },
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }
        ),

        const SizedBox(height: 16),
        Text('Zoom Level:', style: textTheme.titleSmall),
        Consumer<CanvasProvider>(
            builder: (context, provider, child) {
            final String formattedZoom = provider.zoomLevel.toStringAsFixed(1);
            return Text('${formattedZoom}x', textAlign: TextAlign.center, style: textTheme.bodyLarge);
            }
        ),
      ],
    );
  }
}
