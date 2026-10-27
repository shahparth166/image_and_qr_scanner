import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../app/constants/app_colors.dart';
import '../app/constants/app_text.dart';
import '../models/capture_item.dart';
import '../viewmodels/results_view_model.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.items});

  final List<CaptureItem> items;

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(ResultsViewModel(items));
    return GetBuilder<ResultsViewModel>(
      builder: (_) => viewModel.buildView(context),
    );
  }
}

extension ResultsViewBuilder on ResultsViewModel {
  Widget buildView(BuildContext context) {
    final visible = items
        .where((item) => matches(item, selectedFilter))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppText.resultsTitle),
        backgroundColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatTile(
                        label: 'Photos',
                        value: count(ResultsFilter.all),
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icons.photo_library_outlined,
                      ),
                      const SizedBox(width: 8),
                      _StatTile(
                        label: 'QR',
                        value: count(ResultsFilter.qr),
                        color: AppColors.qr,
                        icon: Icons.qr_code_2,
                      ),
                      const SizedBox(width: 8),
                      _StatTile(
                        label: 'Barcode',
                        value: count(ResultsFilter.barcode),
                        color: AppColors.barcode,
                        icon: Icons.view_week,
                      ),
                      const SizedBox(width: 8),
                      _StatTile(
                        label: 'No code',
                        value: count(ResultsFilter.none),
                        color: AppColors.noCode,
                        icon: Icons.image_not_supported_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in ResultsFilter.values)
                        ChoiceChip(
                          label: Text('${label(f)} (${count(f)})'),
                          selected: selectedFilter == f,
                          onSelected: (_) => selectFilter(f),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Nothing in this category.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ResultCard(item: visible[index]),
                  ),
                  childCount: visible.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});

  final CaptureItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => Get.to<void>(() => _FullImagePage(item: item)),
                child: Hero(
                  tag: 'img_${item.id}',
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.file(
                      File(item.path),
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: _Badge(
                  text: '#${item.id}',
                  color: Colors.black87,
                  textColor: Colors.white,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Row(
                  children: [
                    if (item.hasQr)
                      const _Badge(
                        text: 'QR',
                        color: AppColors.qr,
                        textColor: Colors.black,
                      ),
                    if (item.hasQr && item.hasBarcode) const SizedBox(width: 6),
                    if (item.hasBarcode)
                      const _Badge(
                        text: 'BARCODE',
                        color: AppColors.barcode,
                        textColor: Colors.black,
                      ),
                    if (!item.hasCode)
                      const _Badge(
                        text: 'NO CODE',
                        color: Colors.black54,
                        textColor: Colors.white70,
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: item.hasCode
                ? Column(
                    children: [
                      for (final code in item.codes) _CodeTile(code: code),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        item.errorMessage != null
                            ? Icons.error_outline
                            : Icons.image_outlined,
                        color: item.errorMessage != null
                            ? Colors.orangeAccent
                            : AppColors.noCode,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.errorMessage != null
                              ? 'Scan error: ${item.errorMessage}'
                              : 'No QR code or barcode found',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.code});

  final ScannedCode code;

  @override
  Widget build(BuildContext context) {
    final isQr = code.kind == CodeKind.qr;
    final color = isQr ? AppColors.qr : AppColors.barcode;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isQr ? Icons.qr_code_2 : Icons.view_week, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code.format.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  code.value,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code.value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FullImagePage extends StatelessWidget {
  const _FullImagePage({required this.item});

  final CaptureItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Photo #${item.id}'),
      ),
      body: Center(
        child: Hero(
          tag: 'img_${item.id}',
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.file(File(item.path)),
          ),
        ),
      ),
    );
  }
}
