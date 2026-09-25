import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../widgets/states/empty_state.dart';
import 'scan_overlay.dart';

/// Live camera with a scan window and a torch button.
class ScannerView extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(String code) onCode;

  const ScannerView({
    super.key,
    required this.controller,
    required this.onCode,
  });

  static Rect windowFor(Size size) {
    final width = (size.width * 0.78).clamp(220.0, 420.0);
    final height = width * 0.62;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = windowFor(constraints.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              scanWindow: window,
              onDetect: (capture) {
                final code = capture.barcodes
                    .map((b) => b.rawValue?.trim())
                    .firstWhere(
                      (v) => v != null && v.isNotEmpty,
                      orElse: () => null,
                    );
                if (code != null) onCode(code);
              },
              errorBuilder: (context, error) => ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: EmptyState(
                  icon: Icons.no_photography_rounded,
                  title: 'Camera unavailable',
                  message:
                      'Allow camera access in Settings, or type the '
                      'barcode below.',
                ),
              ),
            ),
            ScanOverlay(window: window, color: primary),
            Positioned(
              top: window.bottom + Gap.lg,
              left: 0,
              right: 0,
              child: Center(child: _TorchButton(controller: controller)),
            ),
          ],
        );
      },
    );
  }
}

class _TorchButton extends StatelessWidget {
  final MobileScannerController controller;

  const _TorchButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (!state.isRunning || state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }
        final on = state.torchState == TorchState.on;
        return IconButton.filled(
          tooltip: on ? 'Turn off light' : 'Turn on light',
          style: IconButton.styleFrom(
            backgroundColor: on ? Colors.white : Colors.white24,
            foregroundColor: on ? Colors.black : Colors.white,
            minimumSize: const Size.square(56),
          ),
          onPressed: controller.toggleTorch,
          icon: Icon(
            on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
          ),
        );
      },
    );
  }
}
