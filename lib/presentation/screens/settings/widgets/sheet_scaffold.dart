import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Common frame for bottom-sheet forms: title, padding that follows the
/// keyboard, and scrolling when space is tight.
class SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const SheetScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        0,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Gap.xl),
            child,
          ],
        ),
      ),
    );
  }
}
