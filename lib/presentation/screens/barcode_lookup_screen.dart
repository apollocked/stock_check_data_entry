import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/entities/item.dart';
import '../providers/repository_providers.dart';
import 'new_item_form_screen.dart';
import 'stock_action_sheet.dart';

class BarcodeLookupScreen extends ConsumerStatefulWidget {
  const BarcodeLookupScreen({super.key});

  @override
  ConsumerState<BarcodeLookupScreen> createState() =>
      _BarcodeLookupScreenState();
}

enum _LookupState { idle, loading, results }

class _BarcodeLookupScreenState extends ConsumerState<BarcodeLookupScreen> {
  final _barcodeController = TextEditingController();
  bool _scanAvailable = true;
  _LookupState _state = _LookupState.idle;
  Item? _item;

  @override
  void initState() {
    super.initState();
    try {
      _scanAvailable = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    } catch (_) {
      _scanAvailable = false;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _lookup(String barcode) async {
    if (barcode.trim().isEmpty) return;
    setState(() {
      _state = _LookupState.loading;
      _item = null;
    });

    final repo = ref.read(inventoryRepositoryProvider);

    try {
      final found = await repo.searchByBarcode(barcode.trim());
      if (!mounted) return;
      setState(() {
        _item = found;
        _state = _LookupState.results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lookup failed: $e')));
        setState(() => _state = _LookupState.idle);
      }
    }
  }

  Future<void> _scan() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _CameraScanner()));
    if (code != null && code.isNotEmpty) {
      _barcodeController.text = code;
      _lookup(code);
    }
  }

  Future<void> _createNew() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(barcode: _barcodeController.text.trim()),
      ),
    );
    if (created == true) _lookup(_barcodeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _barcodeController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            onSubmitted: (v) => _lookup(v),
            decoration: InputDecoration(
              hintText: 'Enter or scan a barcode',
              prefixIcon: const Icon(Icons.qr_code_2),
              suffixIcon: _scanAvailable
                  ? IconButton(
                      tooltip: 'Scan barcode',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _state == _LookupState.loading ? null : _scan,
                    )
                  : null,
              suffix: IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.arrow_forward),
                onPressed: _state == _LookupState.loading
                    ? null
                    : () => _lookup(_barcodeController.text),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LookupState.idle:
        return _HintCard(scanAvailable: _scanAvailable, onScan: _scan);

      case _LookupState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        );

      case _LookupState.results:
        final item = _item;
        if (item == null) {
          return _NotFoundCard(
            barcode: _barcodeController.text.trim(),
            onCreate: _createNew,
          );
        }
        return _FoundItemCard(
          item: item,
          onDone: () => Navigator.of(context).pop(),
          onStockAction: () {
            showStockActionSheet(context, item: item);
          },
        );
    }
  }
}

class _HintCard extends StatelessWidget {
  final bool scanAvailable;
  final VoidCallback onScan;

  const _HintCard({required this.scanAvailable, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Type a barcode and press Enter\nor tap the scanner icon.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (scanAvailable) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onScan,
                child: const Text('Open camera scanner'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FoundItemCard extends StatefulWidget {
  final Item item;
  final VoidCallback onDone;
  final VoidCallback onStockAction;

  const _FoundItemCard({
    required this.item,
    required this.onDone,
    required this.onStockAction,
  });

  @override
  State<_FoundItemCard> createState() => _FoundItemCardState();
}

class _FoundItemCardState extends State<_FoundItemCard> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;
    final low = item.quantity <= 5;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Item already in inventory',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: cs.primary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 72,
                            height: 72,
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.broken_image, color: cs.outline),
                          ),
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported,
                            color: cs.outline,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Barcode: ${item.barcode ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'In stock: ${item.quantity}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: low ? cs.error : cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: widget.onStockAction,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Manage stock'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: widget.onDone,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundCard extends StatelessWidget {
  final String barcode;
  final VoidCallback onCreate;

  const _NotFoundCard({required this.barcode, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: cs.onErrorContainer),
            const SizedBox(height: 12),
            Text(
              'No item with barcode\n"$barcode"\nfound in inventory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onErrorContainer),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Add new item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraScanner extends StatefulWidget {
  const _CameraScanner();

  @override
  State<_CameraScanner> createState() => _CameraScannerState();
}

class _CameraScannerState extends State<_CameraScanner> {
  bool _popped = false;

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (code.isEmpty || _popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
