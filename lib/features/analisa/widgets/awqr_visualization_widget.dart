import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/detail_analisa_screen.dart';

class AwqrVisualizationWidget extends StatelessWidget {
  final String idLogger;
  final Map<String, dynamic> sensorData;
  final bool isOnline;
  final String? namaPos;
  final String? namaLogger;

  const AwqrVisualizationWidget({
    super.key,
    required this.idLogger,
    required this.sensorData,
    required this.isOnline,
    this.namaPos,
    this.namaLogger,
  });

  @override
  Widget build(BuildContext context) {
    final tma = (sensorData['tma'] as num?)?.toDouble() ?? (sensorData['elevasi_muka_air'] as num?)?.toDouble();
    final phAir = (sensorData['ph_air'] as num?)?.toDouble();
    final suhuAir = (sensorData['suhu_air'] as num?)?.toDouble();
    final orp = (sensorData['orp'] as num?)?.toDouble();
    final conductivity = (sensorData['conductivity'] as num?)?.toDouble();
    final salinity = (sensorData['salinity'] as num?)?.toDouble();
    final tds = (sensorData['tds'] as num?)?.toDouble();
    final turbidity = (sensorData['turbidity'] as num?)?.toDouble();
    final tinggiSensor = (sensorData['elevasi_sensor'] as num?)?.toDouble();

    // Kumpulkan parameter yang tersedia
    List<Widget> gridItems = [];
    
    if (phAir != null) {
      gridItems.add(_buildGridItem(context, 'pH AIR', phAir, '', isOnline, 'assets/images/awqr/ph_air.svg', 'ph_air'));
    }
    if (suhuAir != null) {
      gridItems.add(_buildGridItem(context, 'SUHU AIR', suhuAir, '°C', isOnline, 'assets/images/awqr/suhu_air.svg', 'suhu_air'));
    }
    if (orp != null) {
      gridItems.add(_buildGridItem(context, 'ORP', orp, 'mV', isOnline, 'assets/images/awqr/orp.svg', 'orp'));
    }
    if (conductivity != null) {
      gridItems.add(_buildGridItem(context, 'CONDUCTIVITY', conductivity, 'µS/cm', isOnline, 'assets/images/awqr/conductivity.svg', 'conductivity'));
    }
    if (salinity != null) {
      gridItems.add(_buildGridItem(context, 'SALINITY', salinity, 'PSU', isOnline, 'assets/images/awqr/salinity.svg', 'salinity'));
    }
    if (tds != null) {
      gridItems.add(_buildGridItem(context, 'TOTAL DISSOLVED\nSOLIDS', tds, 'mg/L', isOnline, 'assets/images/awqr/total_dissolved_solids.svg', 'tds'));
    }
    if (turbidity != null) {
      gridItems.add(_buildGridItem(context, 'TURBIDITY', turbidity, 'NTU', isOnline, 'assets/images/awqr/turbidity.svg', 'turbidity'));
    }
    if (tinggiSensor != null) {
      gridItems.add(_buildGridItem(context, 'TINGGI SENSOR', tinggiSensor, 'm', isOnline, 'assets/images/awqr/tinggi_sensor.svg', 'elevasi_sensor'));
    }

    // Bangun baris untuk grid secara dinamis (2 kolom per baris)
    List<Widget> gridRows = [];
    for (int i = 0; i < gridItems.length; i += 2) {
      gridRows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(child: gridItems[i]),
              const SizedBox(width: 8),
              if (i + 1 < gridItems.length)
                Expanded(child: gridItems[i + 1])
              else
                Expanded(child: const SizedBox()), // Spacer agar lebar kolom pertama tetap konsisten
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tma != null) ...[
            _buildTopCard(context, tma, isOnline, 'tma'),
            if (gridRows.isNotEmpty) const SizedBox(height: 12),
          ],
          ...gridRows,
        ],
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, double value, bool isOnline, String parameterName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              namaPos: namaPos,
              namaLogger: namaLogger,
              parameterName: parameterName,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/awqr/elevasi_muka_air.svg',
            width: 36,
            height: 36,
            colorFilter: !isOnline
                ? const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ])
                : null,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TINGGI MUKA AIR',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isOnline ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'mdpl',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String label, double value, String unit, bool isOnline, String assetPath, String parameterName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              namaPos: namaPos,
              namaLogger: namaLogger,
              parameterName: parameterName,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            assetPath,
            width: 28,
            height: 28,
            colorFilter: !isOnline
                ? const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ])
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? Colors.black : Colors.grey,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 10,
                          color: isOnline ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
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
}
