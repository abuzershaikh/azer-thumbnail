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

class _RightToolbarState extends State<RightToolbar> with TickerProviderStateMixin {
  final TextEditingController _textEditingController = TextEditingController();
  Key _textFormFieldKey = UniqueKey();
  
  // Expansion states for color sections
  bool _showFontColors = false;
  bool _showBackgroundColors = false;
  bool _showOutlineColors = false;
  bool _showShapeFillColors = false;
  bool _showShapeOutlineColors = false;
  
  // Expansion states for main sections
  bool _canvasToolsExpanded = true;
  bool _selectedElementExpanded = true;

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
    Size? newSize
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
        radius: newSize != null ? newSize.width / 2 : element.radius
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
          width: 260,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              left: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Properties Panel',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable Content
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(3),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Canvas Tools Section
                        _buildExpandableSection(
                          'Canvas Tools',
                          Icons.dashboard_rounded,
                          _canvasToolsExpanded,
                          (expanded) => setState(() => _canvasToolsExpanded = expanded),
                          _buildCanvasTools(context, canvasProviderNoListen, colorScheme, textTheme),
                          colorScheme,
                          textTheme,
                        ),

                        const SizedBox(height: 16),

                        // Selected Element Section
                        _buildExpandableSection(
                          'Selected Element',
                          selectedElement == null ? Icons.select_all_rounded : _getElementIcon(selectedElement),
                          _selectedElementExpanded,
                          (expanded) => setState(() => _selectedElementExpanded = expanded),
                          selectedElement == null
                              ? _buildNoSelectionWidget(colorScheme, textTheme)
                              : _buildSelectedElementContent(
                                  context, 
                                  canvasProviderNoListen, 
                                  selectedElement, 
                                  canBringForward, 
                                  canSendBackward, 
                                  isElementLocked, 
                                  colorScheme, 
                                  textTheme
                                ),
                          colorScheme,
                          textTheme,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getElementIcon(CanvasElement element) {
    if (element is TextElement) return Icons.text_fields_rounded;
    if (element is ImageElement) return Icons.image_rounded;
    if (element is RectangleElement) return Icons.rectangle_rounded;
    if (element is CircleElement) return Icons.circle_rounded;
    return Icons.layers_rounded;
  }

  Widget _buildExpandableSection(
    String title,
    IconData icon,
    bool isExpanded,
    Function(bool) onChanged,
    Widget content,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              onTap: () => onChanged(!isExpanded),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.all(12),
                    child: content,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelectionWidget(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No element selected',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an element on the canvas to see its properties',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedElementContent(
    BuildContext context,
    CanvasProvider provider,
    CanvasElement selectedElement,
    bool canBringForward,
    bool canSendBackward,
    bool isElementLocked,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Element Info Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(_getElementIcon(selectedElement), size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID: ${selectedElement.id.substring(0, 8)}...',
                      style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selectedElement.isLocked ? colorScheme.errorContainer : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedElement.isLocked ? Icons.lock : Icons.lock_open_rounded,
                          size: 12,
                          color: selectedElement.isLocked ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedElement.isLocked ? 'Locked' : 'Unlocked',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: selectedElement.isLocked ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(selectedElement.isLocked ? Icons.lock : Icons.lock_open_rounded),
                    tooltip: selectedElement.isLocked ? 'Unlock Element' : 'Lock Element',
                    onPressed: () => provider.toggleElementLock(),
                    color: selectedElement.isLocked ? colorScheme.error : colorScheme.primary,
                    iconSize: 18,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Layer Controls
        _buildLayerControls(context, provider, canBringForward, canSendBackward, isElementLocked, colorScheme, textTheme),

        const SizedBox(height: 16),

        // Properties
        _buildPropertiesGrid(selectedElement, textTheme, colorScheme),

        const SizedBox(height: 16),

        // Element-specific properties
        if (selectedElement is ImageElement) 
          ..._buildImageSpecificProperties(selectedElement, isElementLocked, textTheme, colorScheme),
        if (selectedElement is TextElement) 
          ..._buildTextSpecificProperties(context, provider, selectedElement, isElementLocked, colorScheme, textTheme),
        if (selectedElement is RectangleElement) 
          ..._buildShapeProperties(context, provider, selectedElement, isElementLocked, colorScheme, textTheme, isRect: true),
        if (selectedElement is CircleElement) 
          ..._buildShapeProperties(context, provider, selectedElement, isElementLocked, colorScheme, textTheme, isRect: false),

        const SizedBox(height: 20),

        // Deselect Button
        FilledButton.tonalIcon(
          onPressed: () => provider.selectElement(null),
          icon: const Icon(Icons.deselect_rounded, size: 18),
          label: const Text('Deselect Element'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesGrid(CanvasElement element, TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Properties',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPropertyRow('Type', element.type.toString().split('.').last, textTheme, colorScheme),
          _buildPropertyRow('Scale', _formatDouble(element.scale), textTheme, colorScheme),
          _buildPropertyRow('Rotation', '${_formatDouble(element.rotation * 180 / math.pi, places: 1)}°', textTheme, colorScheme),
          _buildPropertyRow('X Position', _formatDouble(element.position.dx, places: 1), textTheme, colorScheme),
          _buildPropertyRow('Y Position', _formatDouble(element.position.dy, places: 1), textTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildLayerControls(BuildContext context, CanvasProvider provider, bool canBringForward, bool canSendBackward, bool isLocked, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_rounded, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Layer Controls',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLayerButton(
                context,
                icon: Icons.vertical_align_bottom_rounded,
                tooltip: 'Send to Back',
                onPressed: canSendBackward ? provider.sendToBack : null,
                colorScheme: colorScheme,
              ),
              _buildLayerButton(
                context,
                icon: Icons.keyboard_arrow_down_rounded,
                tooltip: 'Send Backward',
                onPressed: canSendBackward ? provider.sendBackward : null,
                colorScheme: colorScheme,
              ),
              _buildLayerButton(
                context,
                icon: Icons.keyboard_arrow_up_rounded,
                tooltip: 'Bring Forward',
                onPressed: canBringForward ? provider.bringForward : null,
                colorScheme: colorScheme,
              ),
              _buildLayerButton(
                context,
                icon: Icons.vertical_align_top_rounded,
                tooltip: 'Bring to Front',
                onPressed: canBringForward ? provider.bringToFront : null,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayerButton(BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? colorScheme.primaryContainer.withOpacity(0.5) : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed != null ? colorScheme.primary.withOpacity(0.3) : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildImageSpecificProperties(ImageElement element, bool isLocked, TextTheme textTheme, ColorScheme colorScheme) {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_rounded, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Image Properties',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPropertyRow('File', _getFileName(element.imagePath), textTheme, colorScheme, overflow: TextOverflow.ellipsis),
            _buildPropertyRow('Original Width', '${_formatDouble(element.size.width, places: 0)}px', textTheme, colorScheme),
            _buildPropertyRow('Original Height', '${_formatDouble(element.size.height, places: 0)}px', textTheme, colorScheme),
            _buildPropertyRow('Display Width', '${_formatDouble(element.size.width * element.scale, places: 1)}px', textTheme, colorScheme),
            _buildPropertyRow('Display Height', '${_formatDouble(element.size.height * element.scale, places: 1)}px', textTheme, colorScheme),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildTextSpecificProperties(BuildContext context, CanvasProvider provider, TextElement element, bool isLocked, ColorScheme colorScheme, TextTheme textTheme) {
    return [
      // Text Content
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields_rounded, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Text Properties',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: _textFormFieldKey,
              initialValue: element.text,
              enabled: !isLocked,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Text Content',
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: (newText) {
                if (!isLocked) _updateTextElement(provider, element, text: newText);
              },
            ),
            const SizedBox(height: 12),
            
            // Font Size Controls
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Font Size: ${_formatDouble(element.style.fontSize ?? 0, places: 0)}pt',
                    style: textTheme.bodyMedium,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        tooltip: "Decrease font size",
                        onPressed: isLocked ? null : () => _updateTextElement(provider, element, fontSizeDelta: -2),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        tooltip: "Increase font size",
                        onPressed: isLocked ? null : () => _updateTextElement(provider, element, fontSizeDelta: 2),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Font Color Section
            _buildColorSection(
              'Font Color',
              Icons.format_color_text_rounded,
              _showFontColors,
              (show) => setState(() => _showFontColors = show),
              [Colors.black, Colors.white, Colors.red, Colors.blue, Colors.green, Colors.orange],
              (color) => _updateTextElement(provider, element, color: color),
              element.style.color ?? Colors.black,
              isLocked,
              colorScheme,
              textTheme,
            ),
            
            const SizedBox(height: 12),
            
            // Background Color Section
            _buildColorSection(
              'Background Color',
              Icons.format_color_fill_rounded,
              _showBackgroundColors,
              (show) => setState(() => _showBackgroundColors = show),
              [Colors.transparent, Colors.yellowAccent, Colors.lightBlueAccent, colorScheme.surfaceContainerHighest],
              (color) => _updateTextElement(
                provider, 
                element, 
                textBackgroundColor: color == Colors.transparent ? null : color,
                clearTextBackgroundColor: color == Colors.transparent,
              ) as TextElement,
              element.textBackgroundColor ?? Colors.transparent,
              isLocked,
              colorScheme,
              textTheme,
              allowTransparent: true,
            ),
            
            const SizedBox(height: 12),
            
            // Outline Color Section
            _buildColorSection(
              'Outline Color',
              Icons.border_color_rounded,
              _showOutlineColors,
              (show) => setState(() => _showOutlineColors = show),
              [Colors.transparent, Colors.black, Colors.white, Colors.red, Colors.blue],
              (color) => _updateTextElement(
                provider, 
                element, 
                outlineColor: color == Colors.transparent ? null : color,
                clearOutlineColor: color == Colors.transparent,
              ) as TextElement,
              element.outlineColor ?? Colors.transparent,
              isLocked,
              colorScheme,
              textTheme,
              allowTransparent: true,
            ),
            
            const SizedBox(height: 12),
            
            // Outline Width Controls
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Outline Width: ${_formatDouble(element.outlineWidth, places: 1)}pt',
                    style: textTheme.bodyMedium,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        tooltip: "Decrease outline width",
                        onPressed: isLocked ? null : () => _updateTextElement(provider, element, outlineWidthDelta: -0.5),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        tooltip: "Increase outline width",
                        onPressed: isLocked ? null : () => _updateTextElement(provider, element, outlineWidthDelta: 0.5),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            _buildPropertyRow('Box Width', '${_formatDouble(element.size.width * element.scale, places: 1)}px', textTheme, colorScheme),
            _buildPropertyRow('Box Height', '${_formatDouble(element.size.height * element.scale, places: 1)}px', textTheme, colorScheme),
          ],
        ),
      ),
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
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRect ? Icons.rectangle_rounded : Icons.circle_rounded, 
                  size: 14, 
                  color: colorScheme.primary
                ),
                const SizedBox(width: 6),
                Text(
                  '${isRect ? 'Rectangle' : 'Circle'} Properties',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Fill Color Section
            _buildColorSection(
              'Fill Color',
              Icons.format_color_fill_rounded,
              _showShapeFillColors,
              (show) => setState(() => _showShapeFillColors = show),
              [Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.purple],
              (color) => _updateShapeElement(provider, element, fillColor: color),
              currentFillColor,
              isLocked,
              colorScheme,
              textTheme,
            ),
            
            const SizedBox(height: 12),
            
            // Outline Color Section
            _buildColorSection(
              'Outline Color',
              Icons.border_color_rounded,
              _showShapeOutlineColors,
              (show) => setState(() => _showShapeOutlineColors = show),
              [Colors.transparent, Colors.black, Colors.white, Colors.red, Colors.blue],
              (color) => _updateShapeElement(
                provider, 
                element, 
                outlineColor: color == Colors.transparent ? null : color,
                clearOutlineColor: color == Colors.transparent,
              ) as CanvasElement,
              currentOutlineColor ?? Colors.transparent,
              isLocked, // Pass isLocked here
              colorScheme,
              textTheme,
              allowTransparent: true,
            ),
            
            const SizedBox(height: 12),
            
            // Outline Width Controls
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Outline Width: ${_formatDouble(currentOutlineWidth, places: 1)}pt',
                    style: textTheme.bodyMedium,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        tooltip: "Decrease outline width",
                        onPressed: isLocked ? null : () => _updateShapeElement(provider, element, outlineWidthDelta: -0.5),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        tooltip: "Increase outline width",
                        onPressed: isLocked ? null : () => _updateShapeElement(provider, element, outlineWidthDelta: 0.5),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (isRect && element is RectangleElement) ...[
              _buildPropertyRow('Base Width', '${_formatDouble(element.size.width, places: 1)}px', textTheme, colorScheme),
              _buildPropertyRow('Base Height', '${_formatDouble(element.size.height, places: 1)}px', textTheme, colorScheme),
            ] else if (!isRect && element is CircleElement) ...[
              _buildPropertyRow('Radius', '${_formatDouble(element.radius, places: 1)}px', textTheme, colorScheme),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildColorSection(
    String title,
    IconData icon,
    bool isExpanded,
    Function(bool) onToggle,
    List<Color> colors,
    Function(Color) onColorSelected,
    Color currentColor,
    bool isLocked,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool allowTransparent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onToggle(!isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    // Current color preview
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: currentColor == Colors.transparent ? colorScheme.surface : currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                      ),
                      child: currentColor == Colors.transparent 
                          ? Icon(Icons.clear, size: 12, color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: colors.map((color) {
                        bool isSelected = (allowTransparent && color == Colors.transparent && currentColor == Colors.transparent) ||
                                         (!allowTransparent && color == currentColor) ||
                                         (color == currentColor);
                        
                        return GestureDetector(
                          onTap: isLocked ? null : () => onColorSelected(color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color == Colors.transparent ? colorScheme.surface : color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                )
                              ] : [],
                            ),
                            child: color == Colors.transparent 
                                ? Icon(Icons.clear, size: 16, color: colorScheme.onSurfaceVariant)
                                : isSelected 
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                      )
                                    : null,
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value, TextTheme textTheme, ColorScheme colorScheme, {TextOverflow overflow = TextOverflow.clip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              overflow: overflow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasTools(BuildContext context, CanvasProvider canvasProviderNoListen, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Background Color Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_rounded, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Background',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBackgroundButton('White', Colors.white, () => canvasProviderNoListen.changeBackgroundColor(Colors.white), colorScheme, textTheme),
                  _buildBackgroundButton('Grey', colorScheme.surfaceContainerLow, () => canvasProviderNoListen.changeBackgroundColor(colorScheme.surfaceContainerLow), colorScheme, textTheme),
                  _buildBackgroundButton('Black', Colors.black, () => canvasProviderNoListen.changeBackgroundColor(Colors.black), colorScheme, textTheme),
                  _buildBackgroundButton('Red', Colors.red.shade100, () => canvasProviderNoListen.changeBackgroundColor(Colors.red.shade100), colorScheme, textTheme),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Background Image Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.image_rounded, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Background Image',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    String imagePath = result.files.single.path!;
                    BoxFit currentFit = canvasProviderNoListen.backgroundFitValue ?? BoxFit.contain;
                    canvasProviderNoListen.setBackgroundImage(imagePath, currentFit);
                  }
                },
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: const Text('Set Image'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
              const SizedBox(height: 8),
              Consumer<CanvasProvider>(
                builder: (context, provider, child) {
                  return FilledButton.tonalIcon(
                    onPressed: provider.backgroundImagePathValue != null
                        ? () => canvasProviderNoListen.setBackgroundImage(null, null)
                        : null,
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Clear Image'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 36),
                      backgroundColor: provider.backgroundImagePathValue != null 
                          ? colorScheme.errorContainer 
                          : null,
                      foregroundColor: provider.backgroundImagePathValue != null 
                          ? colorScheme.onErrorContainer 
                          : null,
                    ),
                  );
                },
              ),
              Consumer<CanvasProvider>(
                builder: (context, provider, child) {
                  if (provider.backgroundImagePathValue != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: DropdownButtonFormField<BoxFit>(
                        value: provider.backgroundFitValue ?? BoxFit.contain,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Image Fit",
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        ),
                        items: BoxFit.values.map((BoxFit fit) {
                          return DropdownMenuItem<BoxFit>(
                            value: fit,
                            child: Text(fit.name, style: textTheme.bodySmall),
                          );
                        }).toList(),
                        onChanged: (BoxFit? newValue) {
                          if (newValue != null) {
                            canvasProviderNoListen.setBackgroundImage(
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
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Zoom Level Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.zoom_in_rounded, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Zoom Level',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer<CanvasProvider>(
                builder: (context, provider, child) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${provider.zoomLevel.toStringAsFixed(1)}x',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundButton(String label, Color color, VoidCallback onPressed, ColorScheme colorScheme, TextTheme textTheme) {
    return Expanded(
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
        ),
        child: Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}