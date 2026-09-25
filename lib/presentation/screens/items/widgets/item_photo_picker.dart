import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/security/trusted_url.dart';
import '../../../../core/theme/app_tokens.dart';

/// Photo area of the item form: shows the picked or saved photo, and lets
/// the user take one, choose one, or remove it.
class ItemPhotoPicker extends StatelessWidget {
  final XFile? picked;
  final String? existingUrl;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onRemove;

  const ItemPhotoPicker({
    super.key,
    required this.picked,
    required this.existingUrl,
    required this.onPick,
    required this.onRemove,
  });

  static final _hasCamera =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _choose(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheet, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) onPick(source);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final file = picked;
    final url = isTrustedImageUrl(existingUrl) ? existingUrl : null;
    final Widget image = file != null
        ? (kIsWeb
              ? Image.network(file.path, fit: BoxFit.cover)
              : Image.file(File(file.path), fit: BoxFit.cover))
        : url != null
        ? Image.network(url, fit: BoxFit.cover)
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_rounded, size: 44, color: cs.primary),
              const SizedBox(height: Gap.sm),
              Text('Add a photo', style: TextStyle(color: cs.primary)),
            ],
          );
    final hasImage = file != null || url != null;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Material(
        color: cs.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: InkWell(
          onTap: () => _choose(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: Motion.medium,
                child: KeyedSubtree(
                  key: ValueKey(file?.path ?? url),
                  child: image,
                ),
              ),
              if (hasImage)
                Positioned(
                  right: Gap.sm,
                  bottom: Gap.sm,
                  child: Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _choose(context),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Change'),
                      ),
                      const SizedBox(width: Gap.sm),
                      IconButton.filledTonal(
                        tooltip: 'Remove photo',
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
