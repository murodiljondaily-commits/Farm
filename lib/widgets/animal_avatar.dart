import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Drop-in content for any circular avatar slot (CircleAvatar's `child`, or
/// a Center inside a decorated Container): shows the animal's real photo if
/// one was taken when adding it, else falls back to the species emoji.
/// Callers keep their own background/gradient/border/shadow — this widget
/// only decides what goes *inside* the circle.
class AnimalAvatarContent extends StatelessWidget {
  final String? photoFileId;
  final String species;
  final double emojiFontSize;

  /// null = fully round (circle avatars); pass a value to match a
  /// rounded-square avatar's own BorderRadius so the clipped photo lines
  /// up with the container behind it.
  final BorderRadius? borderRadius;

  const AnimalAvatarContent({
    super.key,
    required this.photoFileId,
    required this.species,
    this.emojiFontSize = 24,
    this.borderRadius,
  });

  bool get _hasPhoto {
    final p = photoFileId;
    return p != null && p.isNotEmpty && File(p).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPhoto) {
      final image = Image.file(
        File(photoFileId!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: image)
          : ClipOval(child: image);
    }
    return Center(
      child: Text(speciesEmoji(species), style: TextStyle(fontSize: emojiFontSize)),
    );
  }
}

/// Telegram-style tap-to-expand: wrap a small avatar in this and tapping it
/// opens the photo full-screen (pinch-zoom, tap/swipe-down to dismiss) with
/// a shared-element transition. No-ops (doesn't wrap in a tappable) when
/// there's no real photo to show, since the emoji fallback has nothing to
/// zoom into.
class ExpandablePhoto extends StatelessWidget {
  final String? photoFileId;
  final String heroTag;
  final Widget child;

  const ExpandablePhoto({
    super.key,
    required this.photoFileId,
    required this.heroTag,
    required this.child,
  });

  bool get _hasPhoto {
    final p = photoFileId;
    return p != null && p.isNotEmpty && File(p).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPhoto) return child;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (_, __, ___) => _FullscreenPhotoViewer(
            photoFile: File(photoFileId!),
            heroTag: heroTag,
          ),
          transitionsBuilder: (_, animation, __, page) =>
              FadeTransition(opacity: animation, child: page),
        ),
      ),
      child: Hero(tag: heroTag, child: child),
    );
  }
}

class _FullscreenPhotoViewer extends StatelessWidget {
  final File photoFile;
  final String heroTag;

  const _FullscreenPhotoViewer({required this.photoFile, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.file(photoFile, fit: BoxFit.contain),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
