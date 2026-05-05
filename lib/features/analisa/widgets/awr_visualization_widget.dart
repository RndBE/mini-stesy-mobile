import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/detail_analisa_screen.dart';

class AwrVisualizationWidget extends StatefulWidget {
  final String idLogger;
  final Map<String, dynamic> sensorData;
  final bool isOnline;

  const AwrVisualizationWidget({
    super.key,
    required this.idLogger,
    required this.sensorData,
    required this.isOnline,
  });

  @override
  State<AwrVisualizationWidget> createState() => _AwrVisualizationWidgetState();
}

class _AwrVisualizationWidgetState extends State<AwrVisualizationWidget> {
  // Start at a large even number to allow scrolling left and right infinitely
  final PageController _rainPageController = PageController(initialPage: 1000);
  int _currentRainPage = 0;

  @override
  void dispose() {
    _rainPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final windCard = _buildWindCard();
    final lightCard = _buildLightCard();
    final rainCard = _buildRainCard();
    final airCard = _buildAirCard();

    List<Widget> children = [];
    
    if (windCard != null) {
      children.add(windCard);
      children.add(const SizedBox(height: 12));
    }

    List<Widget> rowItems = [];
    if (lightCard != null) rowItems.add(Expanded(child: lightCard));
    if (rainCard != null) rowItems.add(Expanded(child: rainCard));

    if (rowItems.isNotEmpty) {
      if (rowItems.length == 1) {
        children.add(Row(children: [rowItems[0], const SizedBox(width: 12), const Expanded(child: SizedBox())]));
      } else {
        children.add(Row(children: [rowItems[0], const SizedBox(width: 12), rowItems[1]]));
      }
      children.add(const SizedBox(height: 12));
    }

    if (airCard != null) {
      children.add(airCard);
    }

    // Remove trailing SizedBox if it exists
    if (children.isNotEmpty && children.last is SizedBox) {
      children.removeLast();
    }

    return Column(children: children);
  }

  double? _parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // Helper function to build small parameter cards
  Widget _buildParamItem(String label, String value, String unit, String iconPath, String parameterName, {IconData? fallbackIcon}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: widget.idLogger,
              parameterName: parameterName,
              isOnline: widget.isOnline,
            ),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade100),
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          fallbackIcon != null
              ? Icon(fallbackIcon, size: 28, color: widget.isOnline ? Colors.blueGrey : Colors.grey)
              : SvgPicture.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  colorFilter: !widget.isOnline
                      ? const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : null,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isOnline ? Colors.black : Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(fontSize: 10, color: widget.isOnline ? Colors.black87 : Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget? _buildWindCard() {
    final speed = _parseDoubleOrNull(widget.sensorData['kecepatan_angin']);
    final direction = _parseDoubleOrNull(widget.sensorData['arah_angin']);

    if (speed == null && direction == null) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Compass Left
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/kompas.svg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                // Blue Arc
                if (direction != null)
                  Positioned(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _CompassArcPainter(direction, const Color(0xFF0000FF)),
                    ),
                  ),
                // Needle
                if (direction != null)
                  Positioned(
                    width: 120,
                    height: 120,
                    child: Transform.rotate(
                      angle: direction * (math.pi / 180),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: const Icon(Icons.navigation, color: Color(0xFF0000FF), size: 28),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Parameters Right
          Expanded(
            flex: 3,
            child: Column(
              children: [
                if (speed != null) _buildParamItem('KECEPATAN ANGIN', speed.toStringAsFixed(3), 'm/s', 'assets/images/awr/kecepatan_angin.svg', 'kecepatan_angin'),
                if (speed != null && direction != null) const SizedBox(height: 8),
                if (direction != null) _buildParamItem('ARAH ANGIN', direction.toStringAsFixed(2), '°', 'assets/images/awr/arah_angin.svg', 'arah_angin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildLightCard() {
    final light = _parseDoubleOrNull(widget.sensorData['kecerahan']);
    final lightDir = _parseDoubleOrNull(widget.sensorData['arah_cahaya']);
    
    if (light == null && lightDir == null) return null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cahaya',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          if (light != null) _buildParamItem('KECERAHAN', light.toStringAsFixed(3), 'K Lux', 'assets/images/awr/kecerahan.svg', 'kecerahan'),
          if (light != null && lightDir != null) const SizedBox(height: 8),
          if (lightDir != null) _buildParamItem('ARAH', lightDir.toStringAsFixed(1), '°', 'assets/images/awr/arah.svg', 'arah_cahaya'),
        ],
      ),
    );
  }

  Widget? _buildRainCard() {
    final rainHour = _parseDoubleOrNull(widget.sensorData['curah_hujan_per_jam']);
    final rainDay = _parseDoubleOrNull(widget.sensorData['curah_hujan_harian']);
    
    if (rainHour == null && rainDay == null) return null;

    List<Widget> slides = [];
    if (rainHour != null) slides.add(_buildRainSlide('Akumulasi 1 Jam', rainHour, true));
    if (rainDay != null) slides.add(_buildRainSlide('Akumulasi Harian', rainDay, false));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150, // Fixed height for carousel
            child: slides.length > 1
              ? PageView.builder(
                  controller: _rainPageController,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentRainPage = idx % slides.length;
                    });
                  },
                  itemBuilder: (context, idx) {
                    return slides[idx % slides.length];
                  },
                )
              : slides.first,
          ),
          if (slides.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (index) => Padding(
                padding: EdgeInsets.only(right: index == slides.length - 1 ? 0 : 4),
                child: _buildDot(index),
              )),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentRainPage == index ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildRainSlide(String title, double hujan, bool isHourly) {
    String imagePath = 'assets/images/klasifikasi_hujan/';
    String labelKlasifikasi = '';

    if (hujan == 0) {
      imagePath += 'tidak_hujan.png';
      labelKlasifikasi = 'Berawan/Tidak Hujan';
    } else if (isHourly) {
      if (hujan < 1) {
        imagePath += 'hujan_sangat_ringan.png';
        labelKlasifikasi = 'Hujan Sangat Ringan';
      } else if (hujan < 5) {
        imagePath += 'hujan_ringan.png';
        labelKlasifikasi = 'Hujan Ringan';
      } else if (hujan < 10) {
        imagePath += 'hujan_sedang.png';
        labelKlasifikasi = 'Hujan Sedang';
      } else if (hujan < 20) {
        imagePath += 'hujan_lebat.png';
        labelKlasifikasi = 'Hujan Lebat';
      } else {
        imagePath += 'hujan_sangat_lebat.png';
        labelKlasifikasi = 'Hujan Sangat Lebat';
      }
    } else {
      if (hujan < 5) {
        imagePath += 'hujan_sangat_ringan.png';
        labelKlasifikasi = 'Hujan Sangat Ringan';
      } else if (hujan < 20) {
        imagePath += 'hujan_ringan.png';
        labelKlasifikasi = 'Hujan Ringan';
      } else if (hujan < 50) {
        imagePath += 'hujan_sedang.png';
        labelKlasifikasi = 'Hujan Sedang';
      } else if (hujan < 100) {
        imagePath += 'hujan_lebat.png';
        labelKlasifikasi = 'Hujan Lebat';
      } else {
        imagePath += 'hujan_sangat_lebat.png';
        labelKlasifikasi = 'Hujan Sangat Lebat';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              hujan.toStringAsFixed(3),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isOnline ? Colors.black : Colors.grey),
            ),
            const SizedBox(width: 4),
            Text(
              'mm',
              style: TextStyle(fontSize: 10, color: widget.isOnline ? Colors.black : Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          labelKlasifikasi,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget? _buildAirCard() {
    final temp = _parseDoubleOrNull(widget.sensorData['temperature'] ?? widget.sensorData['suhu']);
    final press = _parseDoubleOrNull(widget.sensorData['tekanan_udara']);
    final humid = _parseDoubleOrNull(widget.sensorData['humidity'] ?? widget.sensorData['kelembaban']);

    if (temp == null && press == null && humid == null) return null;

    List<Widget> items = [];
    if (temp != null) items.add(_buildAirItem('TEMPERATURE', temp.toStringAsFixed(2), '°C', 'temperature', assetPath: 'assets/images/beranda/temper_online.svg'));
    if (press != null) items.add(_buildAirItem('TEKANAN UDARA', press.toStringAsFixed(1), 'hPa', 'tekanan_udara', assetPath: 'assets/images/awr/tekanan_udara.svg'));
    if (humid != null) items.add(_buildAirItem('KELEMBABAN', humid.toStringAsFixed(2), '%', 'humidity', assetPath: 'assets/images/beranda/humidity_online.svg'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Udara',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((e) => Expanded(child: e)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirItem(String label, String value, String unit, String parameterName, {IconData? icon, Color? color, String? assetPath}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: widget.idLogger,
              parameterName: parameterName,
              isOnline: widget.isOnline,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
        if (assetPath != null)
          SvgPicture.asset(
            assetPath,
            width: 28,
            height: 28,
            colorFilter: !widget.isOnline
                ? const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ])
                : null,
          )
        else if (icon != null && color != null)
          Icon(icon, size: 28, color: widget.isOnline ? color : Colors.grey),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: widget.isOnline ? Colors.black : Colors.grey),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(fontSize: 10, color: widget.isOnline ? Colors.black : Colors.grey),
            ),
          ],
        ),
      ],
    ),
      ),
    );
  }
}

class _CompassArcPainter extends CustomPainter {
  final double direction;
  final Color color;

  _CompassArcPainter(this.direction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (direction <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final center = Offset(size.width / 2, size.height / 2);
    // Setting radius to align perfectly just inside the outer ring of the SVG compass
    final radius = size.width / 2 - 12;

    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // SVG compass 0 degrees is at the top (-pi/2)
    final startAngle = -math.pi / 2;
    // Sweep angle is the wind direction in radians
    final sweepAngle = direction * (math.pi / 180);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CompassArcPainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.color != color;
  }
}

