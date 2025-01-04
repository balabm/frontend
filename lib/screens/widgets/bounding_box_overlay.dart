import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class BoundingBoxOverlay extends StatefulWidget {
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
  State<BoundingBoxOverlay> createState() => _BoundingBoxOverlayState();
}

class _BoundingBoxOverlayState extends State<BoundingBoxOverlay> {
  double? scaleX;
  double? scaleY;
  bool isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final imageFile = File(widget.imagePath);
    final image = Image.file(imageFile);
    final completer = Completer<void>();

    image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, _) {
            if (mounted) {
              setState(() {
                isImageLoaded = true;
              });
            }
            completer.complete();
          }, onError: (error, stackTrace) {
            print('Error loading image: $error');
            completer.completeError(error);
          }),
        );

    await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageFile = File(widget.imagePath);
          final image = Image.file(
            imageFile,
            height: MediaQuery.of(context).size.height,
          );

          // Initialize scales when image is loaded
          if (isImageLoaded) {
            image.image.resolve(const ImageConfiguration()).addListener(
              ImageStreamListener((info, _) {
                final double imageWidth = info.image.width.toDouble();
                final double imageHeight = info.image.height.toDouble();

                scaleX = constraints.maxWidth / imageWidth;
                scaleY = constraints.maxHeight / imageHeight;
              }),
            );
          }

          if (!isImageLoaded || scaleX == null || scaleY == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            children: widget.boundingBoxes.map((box) {
              final scaledX =
                  box['x_center'] * scaleX! - (box['width'] * scaleX! / 2);
              final scaledY =
                  box['y_center'] * scaleY! - (box['height'] * scaleY! / 2);
              final scaledWidth = box['width'] * scaleX!;
              final scaledHeight = box['height'] * scaleY!;
              final fieldType = box['class'];

              final isCurrentlySelected = widget.selectedBox == box;
              final wasEverSelected =
                  widget.previouslySelectedBoxes.contains(box);

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
                  onTap: () => widget.onBoundingBoxTap(box),
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
