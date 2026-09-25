import 'package:flutter/material.dart';

import '../../core/security/trusted_url.dart';

/// An item photo, or a placeholder when there is none.
///
/// Only images hosted by this project's Supabase are loaded; anything else in
/// `image_url` shows the placeholder (see [isTrustedImageUrl]).
class ItemImage extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const ItemImage({super.key, this.url, this.size = 56, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(size: size);
    final trusted = isTrustedImageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: trusted
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              )
            : placeholder,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;

  const _Placeholder({required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.tertiaryContainer],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: size * 0.42,
          color: cs.onPrimaryContainer.withAlpha(190),
        ),
      ),
    );
  }
}
