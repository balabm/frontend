import 'dart:io';
import 'package:flutter/material.dart';

class BoundingBoxOverlay extends StatelessWidget {
  final String imagePath;
  final List<dynamic> boundingBoxes;
  final Map<String, dynamic>? selectedBox;
  final Set<Map<String, dynamic>> previouslySelectedBoxes;
  final Function(Map<String, dynamic>) onBoundingBoxTap;

  const BoundingBoxOverlay({
    Key? key,
    required this.imagePath,
    required this.boundingBoxes,
    required this.selectedBox,
    required this.previouslySelectedBoxes,
    required this.onBoundingBoxTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageFile = File(imagePath);
          final image = Image.file(
            imageFile,
            height: MediaQuery.of(context).size.height,
          );
          final ImageStream stream =
              image.image.resolve(const ImageConfiguration());
          late double scaleX;
          late double scaleY;

          stream.addListener(ImageStreamListener((info, _) {
            final double imageWidth = info.image.width.toDouble();
            final double imageHeight = info.image.height.toDouble();

            scaleX = constraints.maxWidth / imageWidth;
            scaleY = constraints.maxHeight / imageHeight;
          }));

          return Stack(
            children: boundingBoxes.map((box) {
              final scaledX =
                  box['x_center'] * scaleX - (box['width'] * scaleX / 2);
              final scaledY =
                  box['y_center'] * scaleY - (box['height'] * scaleY / 2);
              final scaledWidth = box['width'] * scaleX;
              final scaledHeight = box['height'] * scaleY;
              final fieldType = box['class'];

              final isCurrentlySelected = selectedBox == box;
              final wasEverSelected = previouslySelectedBoxes.contains(box);

              final borderColor = isCurrentlySelected
                  ? Colors.blue
                  : wasEverSelected
                      ? const Color.fromARGB(255, 192, 191, 155)
                      : Colors.green;
              final fillColor = borderColor.withOpacity(0.1);

              return Positioned(
                left: scaledX,
                top: scaledY,
                width: scaledWidth,
                height: scaledHeight,
                child: GestureDetector(
                  onTap: () => onBoundingBoxTap(box),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: 0.5,
                      ),
                      color: fillColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        fieldType,
                        style: TextStyle(
                          color: borderColor.withOpacity(0.15),
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
