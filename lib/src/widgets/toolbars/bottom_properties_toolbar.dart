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
  late TextEditingController _borderBlurRadiusController;
  final FocusNode _borderBlurRadiusFocusNode = FocusNode();

  // --- NEW: Toolbar ki height ko manage karne ke liye state variables ---
  double _toolbarHeight = 160.0; // Initial height
  final double _minToolbarHeight = 80.0;
  final double _maxToolbarHeight = 300.0;


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
    _borderBlurRadiusController = TextEditingController();

    _widthFocusNode.addListener(_onFocusChange);
    _heightFocusNode.addListener(_onFocusChange);
    _cornerRadiusFocusNode.addListener(_onFocusChange);
    _borderWidthFocusNode.addListener(_onFocusChange);
    _shadowBlurFocusNode.addListener(_onFocusChange);
    _shadowOffsetXFocusNode.addListener(_onFocusChange);
    _shadowOffsetYFocusNode.addListener(_onFocusChange);
    _borderBlurRadiusFocusNode.addListener(_onFocusChange);

    _updateTextControllers(Provider.of<CanvasProvider>(context, listen: false).selectedElement);
  }

  void _onFocusChange() {
    if (!_widthFocusNode.hasFocus) _submitWidth();
    if (!_heightFocusNode.hasFocus) _submitHeight();
    if (!_cornerRadiusFocusNode.hasFocus) _submitCornerRadius();
    if (!_borderWidthFocusNode.hasFocus) _submitBorderWidth();
    if (!_shadowBlurFocusNode.hasFocus) _submitShadowBlur();
    if (!_shadowOffsetXFocusNode.hasFocus) _submitShadowOffsetX();
    if (!_shadowOffsetYFocusNode.hasFocus) _submitShadowOffsetY();
    if (!_borderBlurRadiusFocusNode.hasFocus) _submitBorderBlurRadius();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

      if (element is ImageElement) {
        if (!_borderWidthFocusNode.hasFocus) _borderWidthController.text = element.borderWidth.toStringAsFixed(1);
      } else if (element is TextElement || element is RectangleElement || element is CircleElement) {
        if (!_borderWidthFocusNode.hasFocus) _borderWidthController.text = (element as dynamic).outlineWidth.toStringAsFixed(1);
      } else {
        _borderWidthController.text = '';
      }

      if (!_shadowBlurFocusNode.hasFocus) {
        _shadowBlurController.text = element.shadowBlurRadius.toStringAsFixed(1);
      }
      if (!_shadowOffsetXFocusNode.hasFocus) {
        _shadowOffsetXController.text = element.shadowOffset?.dx.toStringAsFixed(0) ?? "0";
      }
      if (!_shadowOffsetYFocusNode.hasFocus) {
        _shadowOffsetYController.text = element.shadowOffset?.dy.toStringAsFixed(0) ?? "0";
      }

      if (element is ImageElement) {
        if (!_borderBlurRadiusFocusNode.hasFocus) {
          _borderBlurRadiusController.text = element.borderBlurRadius.toStringAsFixed(1);
        }
      } else {
        _borderBlurRadiusController.text = '';
      }
    } else {
      _widthController.clear();
      _heightController.clear();
      _cornerRadiusController.clear();
      _borderWidthController.clear();
      _shadowBlurController.clear();
      _shadowOffsetXController.clear();
      _shadowOffsetYController.clear();
      _borderBlurRadiusController.clear();
    }
  }

  void _submitWidth() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null) return;

    final double? newWidth = double.tryParse(_widthController.text);
    if (newWidth != null && newWidth != selectedElement.size.width) {
      canvasProvider.updateSelectedElementSize(Size(newWidth, selectedElement.size.height));
    } else if (newWidth == null) {
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
    } else {
      if (selectedElement is ImageElement) {
        _borderWidthController.text = selectedElement.borderWidth.toStringAsFixed(1);
      } else if (selectedElement is TextElement || selectedElement is RectangleElement || selectedElement is CircleElement) {
        _borderWidthController.text = (selectedElement as dynamic).outlineWidth.toStringAsFixed(1);
      }
    }
  }

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

  void _submitBorderBlurRadius() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final selectedElement = canvasProvider.selectedElement;
    if (selectedElement == null || selectedElement is! ImageElement) return;

    final ImageElement imageElement = selectedElement;
    final double? newBlurRadius = double.tryParse(_borderBlurRadiusController.text);

    if (newBlurRadius != null && newBlurRadius != imageElement.borderBlurRadius) {
      canvasProvider.updateSelectedImageElementBorderBlur(newBlurRadius);
    } else if (newBlurRadius == null) {
      _borderBlurRadiusController.text = imageElement.borderBlurRadius.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _cornerRadiusController.dispose();
    _borderWidthController.dispose();
    _shadowBlurController.dispose();
    _shadowOffsetXController.dispose();
    _shadowOffsetYController.dispose();
    _borderBlurRadiusController.dispose();
    
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
    _borderBlurRadiusFocusNode.removeListener(_onFocusChange);
    _borderBlurRadiusFocusNode.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasProvider = Provider.of<CanvasProvider>(context);
    final selectedElement = canvasProvider.selectedElement;

    if (selectedElement == null) {
      return const SizedBox.shrink();
    }

    final canvasProviderNoListen = Provider.of<CanvasProvider>(context, listen: false);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    bool isLocked = selectedElement.isLocked;

    return Container(
      height: _toolbarHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _toolbarHeight = (_toolbarHeight - details.delta.dy).clamp(_minToolbarHeight, _maxToolbarHeight);
              });
            },
            child: Container(
              width: double.infinity,
              height: 20,
              color: colorScheme.surface.withOpacity(0.01),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 4,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _buildSection(
                        'Size',
                        Icons.aspect_ratio_rounded,
                        [
                          _buildTextFieldProperty(
                            context, "W", _widthController, _widthFocusNode, 
                            isLocked, _submitWidth, colorScheme, textTheme, width: 55
                          ),
                          const SizedBox(width: 8),
                          _buildTextFieldProperty(
                            context, "H", _heightController, _heightFocusNode, 
                            isLocked, _submitHeight, colorScheme, textTheme, width: 55
                          ),
                        ],
                      ),

                      if (selectedElement is ImageElement || selectedElement is RectangleElement) ...[
                        _buildDivider(colorScheme),
                        _buildSection(
                          'Corner',
                          Icons.rounded_corner,
                          [
                            _buildTextFieldProperty(
                              context, "R", _cornerRadiusController, _cornerRadiusFocusNode, 
                              isLocked, _submitCornerRadius, colorScheme, textTheme, width: 55
                            ),
                          ],
                        ),
                      ],

                      _buildDivider(colorScheme),

                      _buildSection(
                        'Transform',
                        Icons.transform,
                        [
                          _buildSliderProperty(
                            context, 'Opacity', selectedElement.opacity, 
                            '${(selectedElement.opacity * 100).toStringAsFixed(0)}%',
                            min: 0.0, max: 1.0, divisions: 20, isLocked: isLocked,
                            onChanged: (value) => canvasProviderNoListen.updateSelectedElementOpacity(value),
                            colorScheme: colorScheme, textTheme: textTheme
                          ),
                          const SizedBox(width: 12),
                          _buildSliderProperty(
                            context, 'Rotation', 
                            (selectedElement.rotation * (180 / 3.1415926535)).clamp(-180.0, 180.0), 
                            '${(selectedElement.rotation * (180 / 3.1415926535)).toStringAsFixed(0)}°',
                            min: -180.0, max: 180.0, divisions: 360, isLocked: isLocked,
                            onChanged: (degrees) => canvasProviderNoListen.updateSelectedElementRotation(degrees),
                            colorScheme: colorScheme, textTheme: textTheme
                          ),
                        ],
                      ),

                      _buildDivider(colorScheme),

                      _buildSection(
                        'Actions',
                        Icons.build_rounded,
                        [
                          _buildActionButton(
                            context,
                            icon: selectedElement.isLocked ? Icons.lock : Icons.lock_open_rounded,
                            tooltip: selectedElement.isLocked ? 'Unlock' : 'Lock',
                            color: selectedElement.isLocked ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            onPressed: () => canvasProviderNoListen.toggleLockSelectedElement(),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            context,
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Delete',
                            color: colorScheme.error,
                            onPressed: () => canvasProviderNoListen.deleteElement(selectedElement),
                          ),
                        ],
                      ),

                      if (selectedElement is ImageElement || selectedElement is TextElement || 
                          selectedElement is RectangleElement || selectedElement is CircleElement) ...[
                        _buildDivider(colorScheme),
                        _buildSection(
                          'Border',
                          Icons.border_all_rounded,
                          [
                            _buildTextFieldProperty(
                              context, "Width", _borderWidthController, _borderWidthFocusNode, 
                              isLocked, _submitBorderWidth, colorScheme, textTheme, width: 55
                            ),
                            if (selectedElement is ImageElement) ...[
                              const SizedBox(width: 8),
                              _buildTextFieldProperty(
                                context, "Blur", _borderBlurRadiusController, _borderBlurRadiusFocusNode, 
                                isLocked, _submitBorderBlurRadius, colorScheme, textTheme, width: 55
                              ),
                            ],
                            const SizedBox(width: 12),
                            _buildBorderColorButtons(context, canvasProviderNoListen, selectedElement, isLocked, colorScheme),
                          ],
                        ),
                      ],

                      _buildDivider(colorScheme),

                      _buildSection(
                        'Shadow',
                        Icons.blur_on_rounded,
                        [
                          _buildTextFieldProperty(
                            context, "Blur", _shadowBlurController, _shadowBlurFocusNode, 
                            isLocked, _submitShadowBlur, colorScheme, textTheme, width: 55
                          ),
                          const SizedBox(width: 8),
                          _buildTextFieldProperty(
                            context, "X", _shadowOffsetXController, _shadowOffsetXFocusNode, 
                            isLocked, _submitShadowOffsetX, colorScheme, textTheme, width: 50
                          ),
                          const SizedBox(width: 8),
                          _buildTextFieldProperty(
                            context, "Y", _shadowOffsetYController, _shadowOffsetYFocusNode, 
                            isLocked, _submitShadowOffsetY, colorScheme, textTheme, width: 50
                          ),
                          const SizedBox(width: 12),
                          _buildShadowColorButtons(context, canvasProviderNoListen, selectedElement, isLocked, colorScheme),
                        ],
                      ),

                      const SizedBox(width: 16),
                    ],
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                title,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return VerticalDivider(
      width: 20,
      thickness: 1,
      indent: 15,
      endIndent: 15,
      color: colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderProperty(BuildContext context, String label, double value, String displayValue, {
    required double min, required double max, required int divisions, required bool isLocked, 
    required ValueChanged<double> onChanged, required ColorScheme colorScheme, required TextTheme textTheme
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$label: $displayValue', 
          style: textTheme.bodySmall?.copyWith(fontSize: 9, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 100,
          height: 24,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.onSurface.withOpacity(0.2),
              onChanged: isLocked ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldProperty(BuildContext context, String label, TextEditingController controller, 
      FocusNode focusNode, bool isLocked, VoidCallback onSubmit, ColorScheme colorScheme, 
      TextTheme textTheme, {double width = 60}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontSize: 9, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Container(
          width: width,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            color: isLocked ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surface,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              isDense: true,
            ),
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
            enabled: !isLocked,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
      ],
    );
  }

  Widget _buildBorderColorButtons(BuildContext context, CanvasProvider canvasProvider, CanvasElement element, bool isLocked, ColorScheme colorScheme) {
    List<Color?> presetColors = [null, Colors.black, Colors.white, Colors.red, Colors.blue, Colors.green, Colors.orange];
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

    return Wrap(
      spacing: 4,
      children: presetColors.map((Color? color) {
        bool isSelected = (color == null && currentColor == null) || (color != null && currentColor == color);
        
        return Tooltip(
          message: color == null ? "Clear Border" : "Set Border Color",
          child: GestureDetector(
            onTap: isLocked ? null : () {
              if (element is ImageElement) {
                canvasProvider.updateSelectedElementBorder(borderColor: color, borderColorGetter: () => color);
              } else if (element is TextElement || element is RectangleElement || element is CircleElement) {
                canvasProvider.updateSelectedElementBorder(outlineColor: color, outlineColorGetter: () => color);
              }
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color ?? colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
                  width: isSelected ? 2 : 1
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3), 
                    blurRadius: 3, 
                    spreadRadius: 0.5
                  )
                ] : [],
              ),
              child: color == null ? Icon(Icons.clear, size: 10, color: colorScheme.onSurfaceVariant) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShadowColorButtons(BuildContext context, CanvasProvider canvasProvider, CanvasElement element, bool isLocked, ColorScheme colorScheme) {
    List<Color?> presetColors = [null, Colors.black54, Colors.black26, Colors.blueGrey, Colors.deepPurple.withOpacity(0.6)];
    Color? currentColor = element.shadowColor;

    return Wrap(
      spacing: 4,
      children: presetColors.map((Color? color) {
        bool isSelected = currentColor == color || (color == null && currentColor == null);

        return Tooltip(
          message: color == null ? "Clear Shadow" : "Set Shadow Color",
          child: GestureDetector(
            onTap: isLocked ? null : () {
              canvasProvider.updateSelectedElementShadow(shadowColor: color, shadowColorGetter: () => color);
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color ?? colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
                  width: isSelected ? 2 : 1
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3), 
                    blurRadius: 3, 
                    spreadRadius: 0.5
                  )
                ] : [],
              ),
              child: color == null ? Icon(Icons.clear, size: 10, color: colorScheme.onSurfaceVariant) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
