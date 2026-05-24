import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/slip_model.dart';

class SwipeCard extends StatefulWidget {
  final SlipModel slip;
  final bool isTop;
  final double dragPercent;

  const SwipeCard({
    super.key,
    required this.slip,
    required this.isTop,
    this.dragPercent = 0,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.slip.localAssetId == null) return;
    try {
      final asset = await AssetEntity.fromId(widget.slip.localAssetId!);
      final file = await asset?.file;
      if (mounted && file != null) {
        setState(() => _imageFile = file);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isRight = widget.dragPercent > 0;
    final isLeft = widget.dragPercent < 0;

    return Container(
      width: screenWidth * 0.88,
      height: screenHeight * 0.58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isTop ? 0.12 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── Image ───────────────────────────────────────────────
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('ไม่พบรูปภาพ',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),

            // ─── Gradient overlay ─────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // ─── Info overlay ─────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '฿${_formatAmount(widget.slip.amount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM yyyy', 'th')
                          .format(widget.slip.date),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    if (widget.slip.note != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.notes,
                              size: 14, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.slip.note!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ─── Swipe indicators ─────────────────────────────────────
            if (widget.isTop && isRight)
              Positioned(
                top: 24,
                left: 20,
                child: Opacity(
                  opacity: widget.dragPercent.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: const Text(
                      'จัดหมวด ✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),

            if (widget.isTop && isLeft)
              Positioned(
                top: 24,
                right: 20,
                child: Opacity(
                  opacity: widget.dragPercent.abs().clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Text(
                      '✕ ข้าม',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }
}
