import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/item.dart';
import '../../providers/repository_providers.dart';
import '../../router/app_routes.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/motion/entrance.dart';
import '../stock/stock_action_sheet.dart';
import 'widgets/manual_entry_bar.dart';
import 'widgets/scan_result_card.dart';
import 'widgets/scanner_view.dart';

/// Scan (or type) a barcode: open the item, update its stock, or add it.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  static final _hasCamera =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final MobileScannerController? _camera = _hasCamera
      ? MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates)
      : null;

  bool _busy = false;
  String? _barcode;
  Item? _item;

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _lookup(String code) async {
    if (_busy || _barcode != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    await _camera?.stop();
    try {
      final item = await ref
          .read(inventoryRepositoryProvider)
          .searchByBarcode(code);
      if (!mounted) return;
      setState(() {
        _barcode = code;
        _item = item;
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
      await _camera?.start();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _barcode = null;
      _item = null;
    });
    await _camera?.start();
  }

  Future<void> _create() async {
    final code = _barcode!;
    await context.newItem(barcode: code);
    if (!mounted) return;
    setState(() => _barcode = null);
    await _lookup(code);
  }

  @override
  Widget build(BuildContext context) {
    final barcode = _barcode;
    final item = _item;
    final bottom = barcode == null
        ? ManualEntryBar(
            key: const ValueKey('entry'),
            busy: _busy,
            onSubmit: _lookup,
          )
        : ScanResultCard(
            key: ValueKey(barcode),
            barcode: barcode,
            item: item,
            onScanAgain: _reset,
            onCreate: _create,
            onOpen: () => context.openItem(item!),
            onUpdateStock: () => showStockActionSheet(context, item: item!),
          ).entrance(offset: 0.3);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan barcode'),
        backgroundColor: Colors.transparent,
        foregroundColor: _hasCamera ? Colors.white : null,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_camera != null)
            ScannerView(controller: _camera, onCode: _lookup)
          else
            const Center(child: Icon(Icons.qr_code_2_rounded, size: 160)),
          Positioned(
            left: Gap.lg,
            right: Gap.lg,
            bottom:
                Gap.lg +
                MediaQuery.viewPaddingOf(context).bottom +
                MediaQuery.viewInsetsOf(context).bottom,
            child: AnimatedSwitcher(duration: Motion.medium, child: bottom),
          ),
        ],
      ),
    );
  }
}
