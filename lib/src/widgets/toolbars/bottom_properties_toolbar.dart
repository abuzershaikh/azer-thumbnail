import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thumbnail_maker/src/providers/canvas_provider.dart';
import 'package:thumbnail_maker/src/models/element_model.dart';

class BottomPropertiesToolbar extends StatefulWidget {
  const BottomPropertiesToolbar({super.key});

  @override
  State<BottomPropertiesToolbar> createState() => _BottomPropertiesToolbarState();
}

class _BottomPropertiesToolbarState extends State<BottomPropertiesToolbar> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _cornerRadiusController;
  late TextEditingController _borderWidthController;
  late TextEditingController _shadowBlurController;
  late TextEditingController _shadowOffsetXController;
  late TextEditingController _shadowOffsetYController;
  final FocusNode _widthFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _cornerRadiusFocusNode = FocusNode();
  final FocusNode _borderWidthFocusNode = FocusNode();
  final FocusNode _shadowBlurFocusNode = FocusNode();
  final FocusNode _shadowOffsetXFocusNode = FocusNode();
  final FocusNode _shadowOffsetYFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _cornerRadiusController = TextEditingController();
    _borderWidthController = TextEditingController();
    _shadowBlurController = TextEditingController();
    _shadowOffsetXController = TextEditingController();
    _shadowOffsetYController = TextEditingController();

    // Add listeners to focus nodes to commit changes on unfocus
    _widthFocusNode.addListener(_onFocusChange);
    _heightFocusNode.addListener(_onFocusChange);
    _cornerRadiusFocusNode.addListener(_onFocusChange);
    _borderWidthFocusNode.addListener(_onFocusChange);
    _shadowBlurFocusNode.addListener(_onFocusChange);
    _shadowOffsetXFocusNode.addListener(_onFocusChange);
    _shadowOffsetYFocusNode.addListener(_onFocusChange);

    // Initial update of text controllers
    _updateTextControllers(Provider.of<CanvasProvider>(context, listen: false).selectedElement);
  }

  void _onFocusChange() {
    // Check if any of the text fields have lost focus and submit their current value
    if (!_widthFocusNode.hasFocus) _submitWidth();
    if (!_heightFocusNode.hasFocus) _submitHeight();
    if (!_cornerRadiusFocusNode.hasFocus) _submitCornerRadius();
    if (!_borderWidthFocusNode.hasFocus) _submitBorderWidth();
    if (!_shadowBlurFocusNode.hasFocus) _submitShadowBlur();
    if (!_shadowOffsetXFocusNode.hasFocus) _submitShadowOffsetX();
    if (!_shadowOffsetYFocusNode.hasFocus) _submitShadowOffsetY();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update controllers if the selected element changes externally
    // This relies on the widget rebuilding when selectedElement changes in provider
    final selectedElement = Provider.of<CanvasProvider>(context).selectedElement;
     _updateTextControllers(selectedElement);
  }


  void _updateTextControllers(CanvasElement? element) {
    if (element != null) {
      if (!_widthFocusNode.hasFocus) {
        _widthController.text = element.size.width.toStringAsFixed(1);
      }
      if (!_heightFocusNode.hasFocus) {
        _heightController.text = element.size.height.toStringAsFixed(1);
      }
      if (element is ImageElement || element is RectangleElement) {
        if (!_cornerRadiusFocusNode.hasFocus) {
          _cornerRadiusController.text = (element as dynamic).cornerRadius.toStringAsFixed(1);
        }
      } else {
       _cornerRadiusController.text = '';
    }

    // Update border width controller
    if (element is ImageElement) {
      if(!_borderWidthFocusNode.hasFocus) _borderWidthController.text = element.borderWidth.toStringAsFixed(1);
    } else if (element is TextElement || element is RectangleElement || element is CircleElement) {
      if(!_borderWidthFocusNode.hasFocus) _borderWidthController.text = (element as dynamic).outlineWidth.toStringAsFixed(1);
    } else {
      _borderWidthController.text = '';
    }

    // Update shadow controllers
    if (!_shadowBlurFocusNode.hasFocus) {
      _shadowBlurController.text = element.shadowBlurRadius.toStringAsFixed(1);
    }
    if (!_shadowOffsetXFocusNode.hasFocus) {
      _shadowOffsetXController.text = element.shadowOffset?.dx.toStringAsFixed(0) ?? "0";
    }
    if (!_shadowOffsetYFocusNode.hasFocus) {
      _shadowOffsetYController.text = element.shadowOffset?.dy.toStringAsFixed(0) ?? "0";
    }

    } else {
      _widthController.clear();
      _heightController.clear();
      _cornerRadiusController.clear();
      _borderWidthController.clear();
      _shadowBlurController.clear();
      _shadowOffsetXController.clear();
      _shadowOffsetYController.clear();
    }
  }

  void _submitWidth() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null) return;

    final double? newWidth = double.tryParse(_widthController.text);
    if (newWidth != null && newWidth != selectedElement.size.width) {
      canvasProvider.updateSelectedElementSize(Size(newWidth, selectedElement.size.height));
    } else if (newWidth == null) { // Revert to current value if parse fails
        _widthController.text = selectedElement.size.width.toStringAsFixed(1);
    }
  }

  void _submitHeight() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null) return;

    final double? newHeight = double.tryParse(_heightController.text);
    if (newHeight != null && newHeight != selectedElement.size.height) {
      canvasProvider.updateSelectedElementSize(Size(selectedElement.size.width, newHeight));
    } else if (newHeight == null) {
       _heightController.text = selectedElement.size.height.toStringAsFixed(1);
    }
  }

  void _submitCornerRadius() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null || !(selectedElement is ImageElement || selectedElement is RectangleElement)) return;

    final double? newRadius = double.tryParse(_cornerRadiusController.text);
    if (newRadius != null && newRadius != (selectedElement as dynamic).cornerRadius) {
      canvasProvider.updateSelectedElementCornerRadius(newRadius);
    } else if (newRadius == null) {
       _cornerRadiusController.text = (selectedElement as dynamic).cornerRadius.toStringAsFixed(1);
    }
  }

  void _submitBorderWidth() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null) return;

    final double? newBorderWidth = double.tryParse(_borderWidthController.text);
    if (newBorderWidth != null) {
      if (selectedElement is ImageElement && newBorderWidth != selectedElement.borderWidth) {
        canvasProvider.updateSelectedElementBorder(borderWidth: newBorderWidth);
      } else if ((selectedElement is TextElement || selectedElement is RectangleElement || selectedElement is CircleElement) &&
                 newBorderWidth != (selectedElement as dynamic).outlineWidth) {
        canvasProvider.updateSelectedElementBorder(outlineWidth: newBorderWidth);
      }
    } else { // Revert if parse fails
        if (selectedElement is ImageElement) {
             _borderWidthController.text = selectedElement.borderWidth.toStringAsFixed(1);
        } else if (selectedElement is TextElement || selectedElement is RectangleElement || selectedElement is CircleElement) {
            _borderWidthController.text = (selectedElement as dynamic).outlineWidth.toStringAsFixed(1);
        }
    }
  }


  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _cornerRadiusController.dispose();
    _borderWidthController.dispose(); // Dispose new controller
    _widthFocusNode.removeListener(_onFocusChange);
    _widthFocusNode.dispose();
    _heightFocusNode.removeListener(_onFocusChange);
    _heightFocusNode.dispose();
    _cornerRadiusFocusNode.removeListener(_onFocusChange);
    _cornerRadiusFocusNode.dispose();
    _borderWidthFocusNode.removeListener(_onFocusChange);
    _borderWidthFocusNode.dispose();
    _shadowBlurFocusNode.removeListener(_onFocusChange);
    _shadowBlurFocusNode.dispose();
    _shadowOffsetXFocusNode.removeListener(_onFocusChange);
    _shadowOffsetXFocusNode.dispose();
    _shadowOffsetYFocusNode.removeListener(_onFocusChange);
    _shadowOffsetYFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final selectedElement = canvasProvider.selectedElement;

    if (selectedElement == null) {
      return const SizedBox.shrink();
    }

    // Update controllers if selected element is available but widget hasn't rebuilt for it yet
    // This is a fallback, didChangeDependencies should ideally handle it.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _updateTextControllers(selectedElement);
    // });


    final canvasProviderNoListen = Provider.of<CanvasProvider>(context, listen: false);
    bool isLocked = selectedElement.isLocked;

    return Container(
      height: 70, // Increased height for TextFields
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, -2), // changes position of shadow
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Size Inputs
            _buildTextFieldProperty(context, "W", _widthController, _widthFocusNode, isLocked, _submitWidth),
            const SizedBox(width: 8),
            _buildTextFieldProperty(context, "H", _heightController, _heightFocusNode, isLocked, _submitHeight),

            if (selectedElement is ImageElement || selectedElement is RectangleElement) ...[
              const SizedBox(width: 8),
              _buildTextFieldProperty(context, "Radius", _cornerRadiusController, _cornerRadiusFocusNode, isLocked, _submitCornerRadius, width: 70),
            ],

            const SizedBox(width: 10),
            const VerticalDivider(width: 20, thickness: 1, indent: 8, endIndent: 8),
            const SizedBox(width: 10),

            // Opacity Slider
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text('Opacity: ${(selectedElement.opacity * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
                ),
                SizedBox(
                  width: 130,
                  height: 30,
                  child: Slider(
                    value: selectedElement.opacity, min: 0.0, max: 1.0, divisions: 20,
                    onChanged: isLocked ? null : (double value) { canvasProviderNoListen.updateSelectedElementOpacity(value); },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const VerticalDivider(width: 20, thickness: 1, indent: 8, endIndent: 8),
            const SizedBox(width: 10),

            // Rotation Slider
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text('Rotation: ${(selectedElement.rotation * (180 / 3.1415926535)).toStringAsFixed(0)}°', style: Theme.of(context).textTheme.bodySmall),
                ),
                SizedBox(
                  width: 130,
                  height: 30,
                  child: Slider(
                    value: (selectedElement.rotation * (180 / 3.1415926535)).clamp(-180.0, 180.0), min: -180.0, max: 180.0, divisions: 360,
                    onChanged: isLocked ? null : (double degrees) { canvasProviderNoListen.updateSelectedElementRotation(degrees); },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const VerticalDivider(width: 20, thickness: 1, indent: 8, endIndent: 8),
            const SizedBox(width: 10),

            // Lock/Unlock Button
            IconButton(
              icon: Icon(selectedElement.isLocked ? Icons.lock : Icons.lock_open),
              tooltip: selectedElement.isLocked ? 'Unlock Element' : 'Lock Element',
              color: selectedElement.isLocked ? Theme.of(context).colorScheme.primary : Colors.grey[700],
              onPressed: () { canvasProviderNoListen.toggleLockSelectedElement(); },
            ),
            const SizedBox(width: 8),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Element',
              color: Colors.red[700],
              onPressed: () { canvasProviderNoListen.deleteElement(selectedElement); },
            ),

            // Placeholder for specific properties (Text, Image specific etc.)
            // const SizedBox(width: 16),
            // const VerticalDivider(width: 20, thickness: 1, indent: 8, endIndent: 8),
            // const SizedBox(width: 16),
            // const Text("Specific Props"),

            const SizedBox(width: 10),
            const VerticalDivider(width: 20, thickness: 1, indent: 8, endIndent: 8),
            const SizedBox(width: 10),

            // Border/Outline Width TextField
            if (selectedElement is ImageElement || selectedElement is TextElement || selectedElement is RectangleElement || selectedElement is CircleElement)
              _buildTextFieldProperty(context, "B.Width", _borderWidthController, _borderWidthFocusNode, isLocked, _submitBorderWidth, width: 70),

            const SizedBox(width: 8),

            // Border/Outline Color Buttons
            if (selectedElement is ImageElement || selectedElement is TextElement || selectedElement is RectangleElement || selectedElement is CircleElement) ...[
              _buildBorderColorButtons(context, canvasProviderNoListen, selectedElement, isLocked),
              const SizedBox(width: 10),
              const VerticalDivider(width: 20, thickness: 1, indent: 8, endIndent: 8),
              const SizedBox(width: 10),
            ],

            // Shadow Properties
            _buildTextFieldProperty(context, "S.Blur", _shadowBlurController, _shadowBlurFocusNode, isLocked, _submitShadowBlur, width: 70),
            const SizedBox(width: 8),
            _buildTextFieldProperty(context, "S.OffX", _shadowOffsetXController, _shadowOffsetXFocusNode, isLocked, _submitShadowOffsetX),
            const SizedBox(width: 8),
            _buildTextFieldProperty(context, "S.OffY", _shadowOffsetYController, _shadowOffsetYFocusNode, isLocked, _submitShadowOffsetY),
            const SizedBox(width: 8),
            _buildShadowColorButtons(context, canvasProviderNoListen, selectedElement, isLocked),

          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldProperty(BuildContext context, String label, TextEditingController controller, FocusNode focusNode, bool isLocked, VoidCallback onSubmit, {double width = 60}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
        enabled: !isLocked,
        onSubmitted: (_) => onSubmit(), // Submit on enter
        // No onFocusChange here, handled by the listener on the FocusNode
      ),
    );
  }

  Widget _buildBorderColorButtons(BuildContext context, CanvasProvider canvasProvider, CanvasElement element, bool isLocked) {
    List<Color?> presetColors = [null, Colors.black, Colors.white, Colors.red, Colors.blue, Colors.green];
    Color? currentColor;

    if (element is ImageElement) {
      currentColor = element.borderColor;
    } else if (element is TextElement) {
      currentColor = element.outlineColor;
    } else if (element is RectangleElement) {
      currentColor = element.outlineColor;
    } else if (element is CircleElement) {
      currentColor = element.outlineColor;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: presetColors.map((Color? color) {
        bool isSelected = (color == null && currentColor == null) || (color != null && currentColor == color);
        String displayHex = "N/A";
        if (color != null) {
          String colorString = color.toString();
          if (colorString.contains('(0xff')) {
            var parts = colorString.split('(0xff');
            if (parts.length > 1) {
              displayHex = parts[1].replaceAll(')', '');
            } else {
              parts = colorString.split('(0x');
              if (parts.length > 1) {
                displayHex = parts[1].replaceAll(')', '');
              }
            }
          } else if (colorString.contains('(0x')) {
            var parts = colorString.split('(0x');
            if (parts.length > 1) {
              displayHex = parts[1].replaceAll(')', '');
            }
          }
        }
        return Tooltip(
          message: color == null ? "Clear Border/Outline" : "Set Border/Outline to $displayHex",
          child: InkWell(
            onTap: isLocked ? null : () {
              if (element is ImageElement) {
                canvasProvider.updateSelectedElementBorder(borderColor: color, borderColorGetter: () => color);
              } else if (element is TextElement || element is RectangleElement || element is CircleElement) {
                canvasProvider.updateSelectedElementBorder(outlineColor: color, outlineColorGetter: () => color);
              }
            },
            child: Container(
              width: 28, height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color ?? Colors.grey[400], // Show grey for "clear" button
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600]!,
                  width: isSelected ? 2.5 : 1.5
                ),
                boxShadow: isSelected ? [const BoxShadow(color: Colors.black38, blurRadius: 3, spreadRadius: 0.5)] : [],
              ),
              child: color == null ? Icon(Icons.format_clear, size: 16, color: Colors.grey[800]) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShadowColorButtons(BuildContext context, CanvasProvider canvasProvider, CanvasElement element, bool isLocked) {
    List<Color?> presetColors = [null, Colors.black54, Colors.black26, Colors.blueGrey, Colors.deepPurple];
    Color? currentColor = element.shadowColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: presetColors.map((Color? color) {
        // For shadow, allow a slightly different comparison if alpha is involved.
        // Here, direct comparison is fine as we store the color with its alpha.
        bool isSelected = currentColor == color;
         if (color == null && currentColor == null) isSelected = true;

        String displayHex = "N/A";
        if (color != null) {
          String colorString = color.toString();
          var parts = colorString.split('(0x');
          if (parts.length > 1) {
            displayHex = parts[1].replaceAll(')', '');
          } else {
            displayHex = colorString; 
          }
        }

        return Tooltip(
          message: color == null ? "Clear Shadow" : "Set Shadow to $displayHex",
          child: InkWell(
            onTap: isLocked ? null : () {
               canvasProvider.updateSelectedElementShadow(shadowColor: color, shadowColorGetter: () => color);
            },
            child: Container(
              width: 28, height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color ?? Colors.grey[400], // Show grey for "clear" button
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600]!,
                  width: isSelected ? 2.5 : 1.5
                ),
                boxShadow: isSelected ? [const BoxShadow(color: Colors.black38, blurRadius: 3, spreadRadius: 0.5)] : [],
              ),
              child: color == null ? Icon(Icons.format_clear, size: 16, color: Colors.grey[800]) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Submission methods for shadow properties
  void _submitShadowBlur() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null) return;

    final double? newBlur = double.tryParse(_shadowBlurController.text);
    if (newBlur != null && newBlur != selectedElement.shadowBlurRadius) {
      canvasProvider.updateSelectedElementShadow(shadowBlurRadius: newBlur);
    } else if (newBlur == null) {
      _shadowBlurController.text = selectedElement.shadowBlurRadius.toStringAsFixed(1);
    }
  }

  void _submitShadowOffsetX() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null) return;

    final double? newOffsetX = double.tryParse(_shadowOffsetXController.text);
    final currentOffsetY = selectedElement.shadowOffset?.dy ?? 0.0;
    if (newOffsetX != null && newOffsetX != (selectedElement.shadowOffset?.dx ?? 0.0)) {
      canvasProvider.updateSelectedElementShadow(shadowOffset: Offset(newOffsetX, currentOffsetY));
    } else if (newOffsetX == null) {
      _shadowOffsetXController.text = selectedElement.shadowOffset?.dx.toStringAsFixed(0) ?? "0";
    }
  }

  void _submitShadowOffsetY() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null) return;

    final double? newOffsetY = double.tryParse(_shadowOffsetYController.text);
    final currentOffsetX = selectedElement.shadowOffset?.dx ?? 0.0;
    if (newOffsetY != null && newOffsetY != (selectedElement.shadowOffset?.dy ?? 0.0)) {
      canvasProvider.updateSelectedElementShadow(shadowOffset: Offset(currentOffsetX, newOffsetY));
    } else if (newOffsetY == null) {
       _shadowOffsetYController.text = selectedElement.shadowOffset?.dy.toStringAsFixed(0) ?? "0";
    }
  }

}
