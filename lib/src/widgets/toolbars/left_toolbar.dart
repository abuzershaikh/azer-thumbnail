import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:thumbnail_maker/src/providers/canvas_provider.dart';

class LeftToolbar extends StatelessWidget {
  const LeftToolbar({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final imageFile = File(filePath);

        var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
        Size imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

        canvasProvider.addImageElement(filePath, imageSize);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _showAddTextDialog(BuildContext context) async {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final TextEditingController textController = TextEditingController();

    // Position in roughly the center of a 1280x720 canvas
    const Offset defaultTextPosition = Offset(580, 330);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Text Element'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter your text"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  const TextStyle defaultTextStyle = TextStyle(
                    fontSize: 50,
                    color: Colors.black,
                  );
                  canvasProvider.addTextElement(
                    textController.text,
                    defaultTextStyle,
                    defaultTextPosition,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasProviderNoListen = Provider.of<CanvasProvider>(context, listen: false);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 220, // Increased width for better spacing
      color: colorScheme.surface, // Use a slightly different background
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), // Adjust padding
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elements',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), // Bolder title
            ),
            const SizedBox(height: 16), // Increased spacing
            Tooltip(
              message: 'Add image from file',
              child: FilledButton.tonalIcon( // Changed to FilledButton for a modern look
                icon: const Icon(Icons.image_outlined), // Use outlined icon
                label: const Text('Add Image'),
                onPressed: () => _pickImage(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12), // Add padding to button
                ),
              ),
            ),
            const SizedBox(height: 10),
            Tooltip(
              message: 'Add text element',
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.text_fields_outlined),
                label: const Text('Add Text'),
                onPressed: () => _showAddTextDialog(context),
                 style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Tooltip(
              message: 'Add rectangle shape',
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.crop_square_outlined), 
                label: const Text('Add Rectangle'),
                onPressed: () {
                  canvasProviderNoListen.addRectangleElement();
                },
                 style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Tooltip(
              message: 'Add circle shape',
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.circle_outlined), 
                label: const Text('Add Circle'),
                onPressed: () {
                  canvasProviderNoListen.addCircleElement();
                },
                 style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
