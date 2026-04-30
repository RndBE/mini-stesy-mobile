import 'dart:math';
import 'package:flutter/material.dart';

class WellAnimationWidget extends StatefulWidget {
  final double? kedalamanSumur;
  final double? kedalamanSensor;
  final double? kedalamanPompa;
  final double? mukaAirTanah;
  final bool hasPump;
  final bool isOnline;

  const WellAnimationWidget({
    super.key,
    this.kedalamanSumur,
    this.kedalamanSensor,
    this.kedalamanPompa,
    this.mukaAirTanah,
    this.hasPump = false,
    this.isOnline = false,
  });

  @override
  State<WellAnimationWidget> createState() => _WellAnimationWidgetState();
}

class _WellAnimationWidgetState extends State<WellAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
      builder: (_, __) {
        return CustomPaint(
          size: const Size(double.infinity, 220),
          painter: _WellPainter(
            animValue: _ctrl.value,
            kedalamanSumur: widget.kedalamanSumur ?? 10.0,
            kedalamanSensor: widget.kedalamanSensor ?? 5.0,
            kedalamanPompa: widget.kedalamanPompa ?? 7.0,
            mukaAirTanah: widget.mukaAirTanah ?? 3.0,
            hasPump: widget.hasPump,
            isOnline: widget.isOnline,
          ),
        );
      },
    );
  }
}

class _WellPainter extends CustomPainter {
  final double animValue;
  final double kedalamanSumur;
  final double kedalamanSensor;
  final double kedalamanPompa;
  final double mukaAirTanah;
  final bool hasPump;
  final bool isOnline;

  _WellPainter({
    required this.animValue,
    required this.kedalamanSumur,
    required this.kedalamanSensor,
    required this.kedalamanPompa,
    required this.mukaAirTanah,
    required this.hasPump,
    required this.isOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final wellW = 50.0;
    final wellLeft = cx - wellW / 2;
    final wellRight = cx + wellW / 2;
    final wellTop = 30.0;
    final wellBottom = size.height - 20;
    final wellH = wellBottom - wellTop;

    // Rasio air dalam sumur
    final waterRatio = kedalamanSumur > 0
        ? (mukaAirTanah / kedalamanSumur).clamp(0.05, 0.95)
        : 0.3;
    final waterY = wellTop + (waterRatio * wellH);
    final waterHeight = wellBottom - waterY;

    // ── Dinding sumur
    final wallPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(wellLeft, wellTop), Offset(wellLeft, wellBottom), wallPaint);
    canvas.drawLine(Offset(wellRight, wellTop), Offset(wellRight, wellBottom), wallPaint);

    // Tutup atas sumur
    final capPaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(wellLeft - 10, wellTop), Offset(wellRight + 10, wellTop), capPaint);
    canvas.drawLine(Offset(wellLeft - 4, wellTop - 6),
        Offset(wellLeft - 4, wellTop + 6), capPaint);
    canvas.drawLine(Offset(wellRight + 4, wellTop - 6),
        Offset(wellRight + 4, wellTop + 6), capPaint);

    // ── Air dalam sumur (gradien biru)
    final waterRect = Rect.fromLTWH(wellLeft + 2, waterY, wellW - 4, waterHeight);
    final waterGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isOnline
          ? [const Color(0xFFB3F0FF), const Color(0xFF2EA7E8), const Color(0xFF0050A0)]
          : [Colors.grey.shade300, Colors.grey.shade400, Colors.grey.shade600],
    );
    final waterPaint = Paint()
      ..shader = waterGrad.createShader(waterRect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(waterRect, waterPaint);

    // Animasi gelombang di permukaan air
    if (isOnline && waterHeight > 5) {
      final wavePath = Path();
      wavePath.moveTo(wellLeft + 2, waterY);
      for (double x = wellLeft + 2; x <= wellRight - 2; x += 1) {
        final relX = (x - wellLeft) / wellW;
        final waveY = waterY + sin((relX * 2 * pi) + (animValue * 2 * pi)) * 2.5;
        wavePath.lineTo(x, waveY);
      }
      wavePath.lineTo(wellRight - 2, waterY + waterHeight);
      wavePath.lineTo(wellLeft + 2, waterY + waterHeight);
      wavePath.close();
      canvas.drawPath(
          wavePath,
          Paint()
            ..color = const Color(0xFFB3F0FF).withOpacity(0.4)
            ..style = PaintingStyle.fill);
    }

    // ── Sensor (garis + kepala)
    final sensorRatio = (kedalamanSensor / kedalamanSumur).clamp(0.1, 0.95);
    final sensorY = wellTop + sensorRatio * wellH;
    final sensorPaint = Paint()
      ..color = isOnline ? Colors.red.shade700 : Colors.grey
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(cx - 8, wellTop), Offset(cx - 8, sensorY), sensorPaint);
    canvas.drawCircle(Offset(cx - 8, sensorY), 5,
        Paint()..color = isOnline ? Colors.red.shade600 : Colors.grey);

    // ── Pompa (jika ada)
    if (hasPump) {
      final pompaRatio = (kedalamanPompa / kedalamanSumur).clamp(0.1, 0.95);
      final pompaY = wellTop + pompaRatio * wellH;
      final pompaPaint = Paint()
        ..color = isOnline ? const Color(0xFFF59E0B) : Colors.grey
        ..strokeWidth = 3;
      canvas.drawLine(Offset(cx + 8, wellTop), Offset(cx + 8, pompaY), pompaPaint);
      // Kepala pompa (persegi kecil)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 8, pompaY), width: 14, height: 10),
            const Radius.circular(2)),
        Paint()..color = isOnline ? const Color(0xFFF59E0B) : Colors.grey,
      );

      // Animasi gelembung pompa saat online
      if (isOnline) {
        final bubbleOffset = (animValue * wellH * 0.3) % (pompaY - wellTop);
        final bubbleY = pompaY - bubbleOffset;
        if (bubbleY > wellTop + 10 && bubbleY < pompaY) {
          canvas.drawCircle(
              Offset(cx + 8, bubbleY),
              2.5,
              Paint()
                ..color = Colors.white.withOpacity(0.6)
                ..style = PaintingStyle.fill);
        }
      }
    }

    // ── Label kedalaman di kiri
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${kedalamanSumur.toStringAsFixed(1)} m',
        style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(wellLeft - 40, (wellTop + wellBottom) / 2 - 6));
  }

  @override
  bool shouldRepaint(_WellPainter old) =>
      old.animValue != animValue || old.isOnline != isOnline;
}
