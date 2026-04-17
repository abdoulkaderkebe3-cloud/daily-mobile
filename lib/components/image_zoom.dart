import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ImageZoom extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onFermer;

  const ImageZoom({
    super.key,
    required this.imageUrl,
    required this.onFermer,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFermer,
      child: Container(
        color: Colors.black.withOpacity(0.9),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {}, // Prevent closing when clicking the image content
              child: Hero(
                tag: imageUrl,
                child: InteractiveViewer(
                  child: (imageUrl.isNotEmpty && imageUrl.startsWith('http')) 
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(PhosphorIcons.warning(), color: Colors.white, size: 48),
                        ),
                      )
                    : Center(
                        child: Icon(PhosphorIcons.user(), color: Colors.white, size: 100),
                      ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: onFermer,
                icon: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
