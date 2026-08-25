import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/entities/item.dart';
import '../providers/repository_providers.dart';
import 'new_item_form_screen.dart';

class BarcodeLookupScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String branchName;

  const BarcodeLookupScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  ConsumerState<BarcodeLookupScreen> createState() =>
      _BarcodeLookupScreenState();
}

enum _LookupState { idle, loading, foundLocal, foundGlobal, notFound }

class _BarcodeLookupScreenState extends ConsumerState<BarcodeLookupScreen> {
  final _barcodeController = TextEditingController();
  bool _scanAvailable = true;
  _LookupState _state = _LookupState.idle;
  Item? _localItem;
  Item? _globalItem;
  bool _copying = false;

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
      _localItem = null;
      _globalItem = null;
    });

    final repo = ref.read(inventoryRepositoryProvider);

    try {
      // Step 1: check current branch
      final local = await repo.searchByBarcode(
        branchId: widget.branchId,
        barcode: barcode.trim(),
      );
      if (!mounted) return;

      if (local != null) {
        setState(() {
          _localItem = local;
          _state = _LookupState.foundLocal;
        });
        return;
      }

      // Step 2: check all other branches
      final global = await repo.searchByBarcodeGlobal(barcode.trim());
      if (!mounted) return;

      if (global != null) {
        setState(() {
          _globalItem = global;
          _state = _LookupState.foundGlobal;
        });
        return;
      }

      // Step 3: not found anywhere
      setState(() => _state = _LookupState.notFound);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lookup failed: $e')));
        setState(() => _state = _LookupState.idle);
      }
    }
  }

  Future<void> _copyToBranch() async {
    if (_globalItem == null) return;
    setState(() => _copying = true);
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .copyItemToBranch(
            sourceItem: _globalItem!,
            targetBranchId: widget.branchId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${_globalItem!.name}" copied to ${widget.branchName}',
          ),
        ),
      );
      // Re-lookup to show the item as "found local" now
      _lookup(_barcodeController.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Copy failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _copying = false);
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
        builder: (_) => ItemFormScreen(
          branchId: widget.branchId,
          barcode: _barcodeController.text.trim(),
        ),
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

      case _LookupState.foundLocal:
        return _FoundItemCard(
          item: _localItem!,
          label: 'Item in this branch',
          onDone: () => Navigator.of(context).pop(),
        );

      case _LookupState.foundGlobal:
        return _FoundInOtherBranchCard(
          item: _globalItem!,
          targetBranch: widget.branchName,
          copying: _copying,
          onCopy: _copyToBranch,
          onCreateNew: _createNew,
        );

      case _LookupState.notFound:
        return _NotFoundCard(
          barcode: _barcodeController.text.trim(),
          onCreate: _createNew,
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

class _FoundItemCard extends StatelessWidget {
  final Item item;
  final String label;
  final VoidCallback onDone;

  const _FoundItemCard({
    required this.item,
    required this.label,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: cs.primary),
            ),
            const SizedBox(height: 12),
            _ItemInfo(item: item),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoundInOtherBranchCard extends StatelessWidget {
  final Item item;
  final String targetBranch;
  final bool copying;
  final VoidCallback onCopy;
  final VoidCallback onCreateNew;

  const _FoundInOtherBranchCard({
    required this.item,
    required this.targetBranch,
    required this.copying,
    required this.onCopy,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Found in another branch',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: cs.tertiary),
            ),
            const SizedBox(height: 4),
            Text(
              '"${item.branchName}" — copy to $targetBranch?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _ItemInfo(item: item),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: copying ? null : onCopy,
              icon: copying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.copy),
              label: Text(copying ? 'Copying...' : 'Copy to $targetBranch'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onCreateNew,
              child: const Text('Create as new item instead'),
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
              'No item with barcode\n"$barcode"\nfound in any branch.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onErrorContainer),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create new item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemInfo extends StatelessWidget {
  final Item item;

  const _ItemInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
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
                  child: Icon(Icons.image_not_supported, color: cs.outline),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              if (item.description != null && item.description!.isNotEmpty)
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              Text(
                'Barcode: ${item.barcode ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.price == null ? '-' : item.price!.toStringAsFixed(2),
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
        ),
      ],
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
