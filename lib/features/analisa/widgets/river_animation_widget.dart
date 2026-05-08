import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RiverAnimationWidget extends StatefulWidget {
  final double? tma;
  final double? elevasiMin;
  final double? elevasiMax;
  final bool isOnline;
  final String tiangAsset;

  const RiverAnimationWidget({
    super.key,
    this.tma,
    this.elevasiMin,
    this.elevasiMax,
    this.isOnline = false,
    this.tiangAsset = 'assets/images/sungai/tiang-nonjiat.svg',
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
    if (widget.tma == null) return const SizedBox.shrink();

    return Container(
      height: 250,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // 1. River Background
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => CustomPaint(
              size: const Size(double.infinity, 250),
              painter: _RiverPainter(
                animValue: _ctrl.value,
                tma: widget.tma ?? 0,
                elevasiMin: widget.elevasiMin ?? 0,
                elevasiMax: widget.elevasiMax ?? 40,
                isOnline: widget.isOnline,
              ),
            ),
          ),
          
          // 2. Tiang & Tanah SVG (Left)
          Positioned(
            left: -20,
            bottom: -15,
            child: SvgPicture.asset(
              widget.tiangAsset,
              height: 250,
            ),
          ),



          // 4. Foreground: TMA Line & Text
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => CustomPaint(
              size: const Size(double.infinity, 250),
              painter: _ForegroundPainter(
                tma: widget.tma ?? 0,
                elevasiMin: widget.elevasiMin ?? 0,
                elevasiMax: widget.elevasiMax ?? 40,
                isOnline: widget.isOnline,
              ),
            ),
          ),
        ],
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

    // Fixed peil height relative to container, independent of elevasi range
    final peilH = h * 0.55;

    // Water level corresponds to the peil scale
    final waterTopY = h - (ratio * peilH);

    final waterColor = [const Color(0xFF7DD3FC), const Color(0xFF38BDF8), const Color(0xFF0369A1)];

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: waterColor,
      ).createShader(Rect.fromLTWH(0, waterTopY, w, h - waterTopY))
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, waterTopY, w, h - waterTopY), waterPaint);

    final wavePath = Path();
    wavePath.moveTo(0, waterTopY);
    for (double x = 0; x <= w; x++) {
      final wave = sin((x / 30) + (animValue * 2 * pi)) * 3.0;
      wavePath.lineTo(x, waterTopY + wave);
    }
    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();
    
    canvas.drawPath(
        wavePath,
        Paint()
          ..color = const Color(0xFFBAE6FD).withOpacity(0.45)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_RiverPainter old) =>
      old.animValue != animValue || old.tma != tma || old.isOnline != isOnline;
}

class _ForegroundPainter extends CustomPainter {
  final double tma;
  final double elevasiMin;
  final double elevasiMax;
  final bool isOnline;

  _ForegroundPainter({
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

    // Fixed peil height relative to container, independent of elevasi range
    final peilH = h * 0.55;
    final waterTopY = h - (ratio * peilH);

    // Peil is positioned at right
    final peilW = 30.0;
    final peilX = w - peilW - 1; // 5px padding from right
    final peilBottom = h;
    final peilTop = peilBottom - peilH;

    // Draw yellow peil stick background
    final stickPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(peilX, peilTop, peilW, peilH), const Radius.circular(4));
    canvas.drawRRect(rrect, stickPaint);

    final stickBorder = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, stickBorder);

    // Draw ticks and dynamic scale text
    final tickPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5;
    final textStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );

    int minV = elevasiMin.floor();
    int maxV = elevasiMax.ceil();

    for (int v = minV; v <= maxV; v++) {
      // Draw minor ticks every 2 units, major ticks with text every 10 units
      if (v % 2 != 0 && v % 10 != 0) continue;

      double tickRatio = (v - elevasiMin) / range;
      if (tickRatio < 0 || tickRatio > 1) continue;

      double tickY = peilBottom - (tickRatio * peilH);
      bool isMajor = (v % 10 == 0);
      double tickLength = isMajor ? 8.0 : 4.0;

      // Draw tick line on the right side of the stick
      canvas.drawLine(Offset(peilX + peilW - tickLength, tickY), Offset(peilX + peilW, tickY), tickPaint);

      // Draw text on the left side of the stick only for major ticks
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(text: v.toString(), style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(peilX + 4, tickY - tp.height / 2));
      }
    }

    final levelPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2;
      
    double dashWidth = 4, dashSpace = 4;
    double startX = peilX - 15;
    double endX = peilX + peilW + 10;
    while (startX < endX) {
      double currentDashWidth = (startX + dashWidth > endX) ? (endX - startX) : dashWidth;
      canvas.drawLine(Offset(startX, waterTopY), Offset(startX + currentDashWidth, waterTopY), levelPaint);
      startX += dashWidth + dashSpace;
    }
    
    canvas.drawCircle(
        Offset(peilX - 15, waterTopY), 3.5, Paint()..color = const Color(0xFF0284C7));

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
    
    tmaPainter.paint(canvas, Offset(peilX - 55, waterTopY - 18));
  }

  @override
  bool shouldRepaint(_ForegroundPainter old) =>
      old.tma != tma || old.isOnline != isOnline;
}
