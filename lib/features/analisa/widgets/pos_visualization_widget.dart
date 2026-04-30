import 'package:flutter/material.dart';
import 'well_animation_widget.dart';
import 'river_animation_widget.dart';
import '../screens/detail_analisa_screen.dart';

class PosVisualizationWidget extends StatelessWidget {
  final Map<String, dynamic> point;

  const PosVisualizationWidget({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    final status = point['status']?.toString() ?? 'offline';
    final isOnline = status == 'online';
    final kategori = (point['kategori'] ?? '').toString().toUpperCase();
    final subKategori = point['sub_kategori']?.toString();
    final sensorData = (point['sensor_data'] as Map<String, dynamic>?) ?? {};
    final jiatData = point['jiat_data'] as Map<String, dynamic>?;
    final nonjiatData = point['nonjiat_data'] as Map<String, dynamic>?;
    final loggerHealth = (point['logger_health'] as Map<String, dynamic>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Visualisasi Animasi
        _buildSectionTitle('Visualisasi'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(12),
            child: _buildVisualization(
                kategori, subKategori, sensorData,
                jiatData, nonjiatData, isOnline),
          ),
        ),

        const SizedBox(height: 16),

        // ── Data Sensor Utama
        _buildSectionTitle('Data Pengukuran'),
        const SizedBox(height: 10),
        _buildSensorCards(context, point['id_logger'].toString(), kategori, sensorData, isOnline),

        const SizedBox(height: 16),

        // ── Health Logger
        _buildSectionTitle('Kondisi Logger'),
        const SizedBox(height: 10),
        _buildHealthCards(context, point['id_logger'].toString(), loggerHealth, isOnline),
      ],
    );
  }

  Widget _buildVisualization(
    String kategori,
    String? subKategori,
    Map<String, dynamic> sensorData,
    Map<String, dynamic>? jiatData,
    Map<String, dynamic>? nonjiatData,
    bool isOnline,
  ) {
    if (kategori.contains('AWLR') || kategori.contains('AWQR') || kategori.contains('AWR')) {
      // JIAT (Sumur)
      if (subKategori == 'jiat' && jiatData != null) {
        final kdlSumur = (jiatData['kedalaman_sumur'] as num?)?.toDouble();
        final kdlSensor = (jiatData['kedalaman_sensor'] as num?)?.toDouble();
        final kdlPompa = (jiatData['kedalaman_pompa'] as num?)?.toDouble();
        final hasPump = jiatData['has_pump'] as bool? ?? false;
        final mukaAir = (sensorData['muka_air_tanah'] as num?)?.toDouble() ??
            (sensorData['tma'] as num?)?.toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sumur (JIAT)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            WellAnimationWidget(
              kedalamanSumur: kdlSumur,
              kedalamanSensor: kdlSensor,
              kedalamanPompa: kdlPompa,
              mukaAirTanah: mukaAir,
              hasPump: hasPump,
              isOnline: isOnline,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.red.shade600, 'Sensor ${kdlSensor?.toStringAsFixed(1) ?? "-"} m'),
                if (hasPump)
                  _buildLegendItem(const Color(0xFFF59E0B), 'Pompa ${kdlPompa?.toStringAsFixed(1) ?? "-"} m'),
                _buildLegendItem(Colors.blue.shade700, 'Air ${mukaAir?.toStringAsFixed(2) ?? "-"} m'),
              ],
            ),
          ],
        );
      }

      // Non-JIAT (Sungai)
      final tma = (sensorData['tma'] as num?)?.toDouble();
      final elevMin = (nonjiatData?['elevasi_min'] as num?)?.toDouble();
      final elevMax = (nonjiatData?['elevasi_max'] as num?)?.toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Sungai',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          RiverAnimationWidget(
            tma: tma,
            elevasiMin: elevMin,
            elevasiMax: elevMax,
            isOnline: isOnline,
          ),
        ],
      );
    }

    // ARR - curah hujan (gauge sederhana)
    if (kategori.contains('ARR')) {
      final hujan = (sensorData['curah_hujan'] as num?)?.toDouble() ?? 0;
      return _buildRainfallGauge(hujan, isOnline);
    }

    // Default
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.sensors, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Visualisasi tidak tersedia',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRainfallGauge(double hujan, bool isOnline) {
    final maxHujan = 100.0;
    final ratio = (hujan / maxHujan).clamp(0.0, 1.0);
    final barColor = hujan >= 50
        ? Colors.red.shade500
        : hujan >= 20
            ? Colors.orange
            : Colors.blue.shade400;

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.cloudy_snowing, size: 32,
                color: isOnline ? Colors.blue.shade400 : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Curah Hujan', style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                          isOnline ? barColor : Colors.grey.shade400),
                      minHeight: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${hujan.toStringAsFixed(1)}\nmm',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isOnline ? barColor : Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCards(
      BuildContext context, String idLogger, String kategori, Map<String, dynamic> sensorData, bool isOnline) {
    final cards = <Map<String, String>>[];

    final tma = sensorData['tma'];
    final debit = sensorData['debit'];
    final hujan = sensorData['curah_hujan'];
    final elevasi = sensorData['elevasi_muka_air'];
    final airTanah = sensorData['muka_air_tanah'];

    if (tma != null) cards.add({'label': 'TMA', 'value': '${(tma as num).toStringAsFixed(3)} m', 'icon': 'tma'});
    if (debit != null) cards.add({'label': 'Debit', 'value': '${(debit as num).toStringAsFixed(3)} m³/s', 'icon': 'debit'});
    if (hujan != null) cards.add({'label': 'Curah Hujan', 'value': '${(hujan as num).toStringAsFixed(1)} mm', 'icon': 'hujan'});
    if (elevasi != null) cards.add({'label': 'Elevasi Muka Air', 'value': '${(elevasi as num).toStringAsFixed(3)} m', 'icon': 'elevasi'});
    if (airTanah != null) cards.add({'label': 'Muka Air Tanah', 'value': '${(airTanah as num).toStringAsFixed(3)} m', 'icon': 'air_tanah'});

    if (cards.isEmpty) {
      return Text('Tidak ada data sensor',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards
          .map((c) => _buildSingleSensorCard(context, idLogger, c['label']!, c['value']!, isOnline))
          .toList(),
    );
  }

  Widget _buildSingleSensorCard(BuildContext context, String idLogger, String label, String value, bool isOnline) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              parameterName: label,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOnline ? const Color(0xFFF0F9FF) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOnline
                ? const Color(0xFF7DD3FC)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? const Color(0xFF0369A1) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCards(BuildContext context, String idLogger, Map<String, dynamic> health, bool isOnline) {
    final humidity = health['humidity'];
    final battery = health['battery'];
    final temp = health['temp'];

    return Row(
      children: [
        if (humidity != null)
          Expanded(child: _buildHealthCard(context, idLogger, 'Kelembapan', '$humidity %',
              Icons.water_drop_outlined, Colors.blue, isOnline)),
        if (battery != null) ...[
          const SizedBox(width: 8),
          Expanded(child: _buildHealthCard(context, idLogger, 'Baterai', '$battery V',
              Icons.battery_charging_full, Colors.green, isOnline)),
        ],
        if (temp != null) ...[
          const SizedBox(width: 8),
          Expanded(child: _buildHealthCard(context, idLogger, 'Suhu Logger', '$temp °C',
              Icons.thermostat, Colors.orange, isOnline)),
        ],
      ],
    );
  }

  Widget _buildHealthCard(BuildContext context, String idLogger, String label, String value, IconData icon,
      Color color, bool isOnline) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              parameterName: label,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isOnline ? color.withOpacity(0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isOnline ? color.withOpacity(0.3) : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isOnline ? color : Colors.grey),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isOnline ? color : Colors.grey)),
            Text(label,
                style:
                    TextStyle(fontSize: 9, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
      ],
    );
  }
}
