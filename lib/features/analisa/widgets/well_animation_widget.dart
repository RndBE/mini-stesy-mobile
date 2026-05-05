import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WellAnimationWidget extends StatefulWidget {
  final double? kedalamanSumur;
  final double? kedalamanSensor;
  final double? kedalamanPompa;
  final double? mukaAirTanah;
  final bool hasPump;
  final bool isOnline;
  final void Function(String)? onLabelTap;

  const WellAnimationWidget({
    super.key,
    this.kedalamanSumur,
    this.kedalamanSensor,
    this.kedalamanPompa,
    this.mukaAirTanah,
    this.hasPump = false,
    this.isOnline = false,
    this.onLabelTap,
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
    const double widgetHeight = 350.0;
    const double wellWidth = 137.0;
    const double wellHeight = 227.0;
    
    final innerHeight = 219.0;
    
    double kSumur = widget.kedalamanSumur ?? 100.0;
    if (kSumur <= 0) kSumur = 100.0;
    
    final sensorRatio = ((widget.kedalamanSensor ?? 50.0) / kSumur).clamp(0.0, 1.0);
    final pompaRatio = ((widget.kedalamanPompa ?? 60.0) / kSumur).clamp(0.0, 1.0);
    final airRatio = ((widget.mukaAirTanah ?? 30.0) / kSumur).clamp(0.0, 1.0);
    
    final sensorY = sensorRatio * innerHeight;
    final pompaY = pompaRatio * innerHeight;
    final airY = airRatio * innerHeight;

    final dataAirTanah = kSumur - (widget.mukaAirTanah ?? 0.0);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          height: widgetHeight,
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // The Well Stack
              SizedBox(
                width: wellWidth,
                height: wellHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Well
                    Positioned(
                      top: 0,
                      left: 0,
                      width: wellWidth,
                      height: wellHeight,
                      child: SvgPicture.asset('assets/images/sumur/badan_sumur.svg'),
                    ),
                    
                    // Water Layer
                    Positioned(
                      top: airY,
                      left: 54.0,
                      width: 29.0,
                      height: innerHeight - airY,
                      child: _buildWater(_ctrl.value, widget.isOnline),
                    ),
                    
                    // Inner Well
                    Positioned(
                      top: -9.3,
                      left: 54.0,
                      width: 29.0,
                      height: 232.0, // dalam_sumur height
                      child: SvgPicture.asset('assets/images/sumur/dalam_sumur.svg'),
                    ),

                    // Top Cap
                    Positioned(
                      top: -13.0,
                      left: 20.0,
                      child: SvgPicture.asset('assets/images/sumur/top_sumur.svg', width: 97),
                    ),

                    // Sensor Cap, Line, and Head
                    Positioned(
                      top: -11.0,
                      left: 48.0,
                      child: SvgPicture.asset('assets/images/sumur/cap_sensor.svg', width: 14),
                    ),
                    Positioned(
                      top: 0.5,
                      left: 60.0,
                      width: 2.0,
                      height: max(0.0, sensorY - 0.5),
                      child: SvgPicture.asset('assets/images/sumur/line_sensor.svg', fit: BoxFit.fill),
                    ),
                    Positioned(
                      top: sensorY,
                      left: 57.0, 
                      child: SvgPicture.asset('assets/images/sumur/kepala_sensor.svg', width: 9),
                    ),

                    // Pump Line, Cap, and Head (if hasPump)
                    if (widget.hasPump) ...[
                      Positioned(
                        top: -7.0,
                        left: 68.0,
                        width: 3.0,
                        height: max(0.0, pompaY + 9.0),
                        child: SvgPicture.asset('assets/images/sumur/line_pompa.svg', fit: BoxFit.fill),
                      ),
                      Positioned(
                        top: -30.0,
                        left: 65.0,
                        child: SvgPicture.asset('assets/images/sumur/cap_pompa.svg', width: 9),
                      ),
                      Positioned(
                        top: pompaY,
                        left: 63.0,
                        child: SvgPicture.asset('assets/images/sumur/kepala_pompa.svg', width: 13),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Pointer lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _WellPointersPainter(
                    wellWidth: wellWidth,
                    wellHeight: wellHeight,
                    sensorY: sensorY,
                    pompaY: pompaY,
                    airY: airY,
                    hasPump: widget.hasPump,
                    isOnline: widget.isOnline,
                  ),
                ),
              ),
              
              // Labels
              _buildLabel('DATA AIR TANAH', '${dataAirTanah.toStringAsFixed(2)} m', const Color(0xFFA67C52), true, -60, const Color(0xFFE8DCD1)),
              _buildLabel('MUKA AIR TANAH', '${(widget.mukaAirTanah ?? 0).toStringAsFixed(2)} m', const Color(0xFF00B2FF), false, -60, const Color(0xFFE0F4FF), paramName: 'muka_air_tanah'),
              _buildLabel('ELEVASI SENSOR', '${(widget.kedalamanSensor ?? 0).toStringAsFixed(2)} m', const Color(0xFFFF4D4D), true, 20, const Color(0xFFFFE0E0)),
              if (widget.hasPump)
                _buildLabel('ELEVASI POMPA', '${(widget.kedalamanPompa ?? 0).toStringAsFixed(2)} m', const Color(0xFFFFD12A), false, 20, const Color(0xFFFFF7D6)),
                
              // Bottom depth text
              Positioned(
                bottom: 0,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                    children: [
                      const TextSpan(text: 'KEDALAMAN SUMUR: '),
                      TextSpan(
                        text: '${kSumur.toStringAsFixed(2)} m',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWater(double animValue, bool isOnline) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _WaterPainter(animValue: isOnline ? animValue : 0.0),
        );
      },
    );
  }

  Widget _buildLabel(String title, String value, Color borderColor, bool isLeft, double yOffset, Color bgColor, {String? paramName}) {
    return Positioned(
      top: 175.0 + yOffset, 
      left: isLeft ? 10 : null,
      right: isLeft ? null : 10,
      width: 120,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: paramName != null 
              ? () {
                  if (widget.onLabelTap != null) {
                    widget.onLabelTap!(paramName);
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A), letterSpacing: 0.5)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: value.split(' ')[0], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                      const TextSpan(text: ' m', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double animValue;
  _WaterPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect waterRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final LinearGradient waterGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF6ED8FF), Color(0xFF1E88E5), Color(0xFF1565C0)],
    );
    final Paint waterPaint = Paint()
      ..shader = waterGrad.createShader(waterRect)
      ..style = PaintingStyle.fill;
      
    final wavePath = Path();
    wavePath.moveTo(0, 0);
    for (double x = 0; x <= size.width; x += 1) {
      final relX = x / size.width;
      final waveY = sin((relX * 2 * pi) + (animValue * 2 * pi)) * 1.5;
      wavePath.lineTo(x, waveY);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    
    canvas.drawPath(wavePath, waterPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) => oldDelegate.animValue != animValue;
}

class _WellPointersPainter extends CustomPainter {
  final double wellWidth;
  final double wellHeight;
  final double sensorY;
  final double pompaY;
  final double airY;
  final bool hasPump;
  final bool isOnline;

  _WellPointersPainter({
    required this.wellWidth,
    required this.wellHeight,
    required this.sensorY,
    required this.pompaY,
    required this.airY,
    required this.hasPump,
    required this.isOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double wellX = cx - wellWidth / 2;
    final double wellY = cy - wellHeight / 2;
    
    final Offset airPointLeft = Offset(wellX + 55.5, wellY + airY);
    final Offset airPointRight = Offset(wellX + 81.5, wellY + airY);
    final Offset sensorPoint = Offset(wellX + 55.0, wellY + sensorY + 6.0);
    final Offset pompaPoint = Offset(wellX + 81.0, wellY + pompaY + 11.0);
    
    final Paint brownPaint = Paint()..color = const Color(0xFFA67C52)..strokeWidth = 1.5;
    final Paint cyanPaint = Paint()..color = const Color(0xFF00B2FF)..strokeWidth = 1.5;
    final Paint redPaint = Paint()..color = const Color(0xFFFF4D4D)..strokeWidth = 1.5;
    final Paint yellowPaint = Paint()..color = const Color(0xFFFFD12A)..strokeWidth = 1.5;
    
    final Paint circlePaint = Paint()..style = PaintingStyle.fill;
    
    void drawPointer(Offset start, Offset target, Paint paint) {
      canvas.drawLine(start, target, paint);
      circlePaint.color = paint.color;
      canvas.drawCircle(target, 3.0, circlePaint);
    }
    
    drawPointer(Offset(130, 175.0 - 60 + 20), airPointLeft, brownPaint); 
    drawPointer(Offset(size.width - 130, 175.0 - 60 + 20), airPointRight, cyanPaint);
    drawPointer(Offset(130, 175.0 + 20 + 20), sensorPoint, redPaint);
    
    if (hasPump) {
      drawPointer(Offset(size.width - 130, 175.0 + 20 + 20), pompaPoint, yellowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WellPointersPainter oldDelegate) {
    return oldDelegate.sensorY != sensorY || 
           oldDelegate.pompaY != pompaY ||
           oldDelegate.airY != airY;
  }
}
