import 'dart:math';
import 'package:flutter/material.dart';

class RiverAnimationWidget extends StatefulWidget {
  final double? tma;
  final double? elevasiMin;
  final double? elevasiMax;
  final bool isOnline;

  const RiverAnimationWidget({
    super.key,
    this.tma,
    this.elevasiMin,
    this.elevasiMax,
    this.isOnline = false,
  });

  @override
  State<RiverAnimationWidget> createState() => _RiverAnimationWidgetState();
}

class _RiverAnimationWidgetState extends State<RiverAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, 180),
        painter: _RiverPainter(
          animValue: _ctrl.value,
          tma: widget.tma ?? 0,
          elevasiMin: widget.elevasiMin ?? 0,
          elevasiMax: widget.elevasiMax ?? 40,
          isOnline: widget.isOnline,
        ),
      ),
    );
  }
}

class _RiverPainter extends CustomPainter {
  final double animValue;
  final double tma;
  final double elevasiMin;
  final double elevasiMax;
  final bool isOnline;

  _RiverPainter({
    required this.animValue,
    required this.tma,
    required this.elevasiMin,
    required this.elevasiMax,
    required this.isOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final range = (elevasiMax - elevasiMin).abs();
    final ratio = range > 0
        ? ((tma - elevasiMin) / range).clamp(0.05, 0.95)
        : 0.5;

    // Area air — semakin tinggi TMA, semakin tinggi airnya
    final waterTopY = h * 0.85 - (ratio * h * 0.65);
    final groundY = h * 0.85;

    // ── Tanah / ground
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFD6B896), const Color(0xFF92400E)],
      ).createShader(Rect.fromLTWH(0, groundY, w, h - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), groundPaint);

    // ── Air sungai (gradien biru)
    final waterColor = isOnline
        ? [const Color(0xFF7DD3FC), const Color(0xFF38BDF8), const Color(0xFF0369A1)]
        : [Colors.grey.shade300, Colors.grey.shade400, Colors.grey.shade500];

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: waterColor,
      ).createShader(Rect.fromLTWH(0, waterTopY, w * 0.85, groundY - waterTopY))
      ..style = PaintingStyle.fill;

    final waterPath = Path();
    waterPath.moveTo(0, waterTopY);
    waterPath.lineTo(w * 0.85, waterTopY);
    waterPath.lineTo(w * 0.85, groundY);
    waterPath.lineTo(0, groundY);
    waterPath.close();
    canvas.drawPath(waterPath, waterPaint);

    // ── Animasi gelombang permukaan
    if (isOnline) {
      final wavePath = Path();
      wavePath.moveTo(0, waterTopY);
      for (double x = 0; x <= w * 0.85; x++) {
        final wave = sin((x / 30) + (animValue * 2 * pi)) * 3.0;
        wavePath.lineTo(x, waterTopY + wave);
      }
      wavePath.lineTo(w * 0.85, groundY);
      wavePath.lineTo(0, groundY);
      wavePath.close();
      canvas.drawPath(
          wavePath,
          Paint()
            ..color = const Color(0xFFBAE6FD).withOpacity(0.45)
            ..style = PaintingStyle.fill);
    }

    // ── Tiang / peil (kanan)
    final peilX = w * 0.88;
    final peilTop = h * 0.05;
    final peilH = groundY - peilTop;

    // Batang tiang
    canvas.drawRect(
        Rect.fromLTWH(peilX, peilTop, 6, peilH),
        Paint()..color = const Color(0xFF475569));

    // Garis skala pada peil
    final tickPaint = Paint()..color = const Color(0xFF92400E)..strokeWidth = 1.2;
    for (int i = 0; i <= 5; i++) {
      final ty = peilTop + (i / 5) * peilH;
      canvas.drawLine(Offset(peilX, ty), Offset(peilX + 12, ty), tickPaint);
    }

    // Garis level TMA (horizontal)
    if (isOnline) {
      final levelPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(peilX - 10, waterTopY), Offset(peilX + 14, waterTopY), levelPaint);
      canvas.drawCircle(
          Offset(peilX - 10, waterTopY), 3.5, Paint()..color = const Color(0xFF0284C7));
    }

    // Label TMA
    final tmaPainter = TextPainter(
      text: TextSpan(
        text: tma > 0 ? '${tma.toStringAsFixed(2)} m' : '- m',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isOnline ? const Color(0xFF0369A1) : Colors.grey,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tmaPainter.paint(canvas, Offset(peilX + 16, waterTopY - 8));
  }

  @override
  bool shouldRepaint(_RiverPainter old) =>
      old.animValue != animValue || old.tma != tma || old.isOnline != isOnline;
}
