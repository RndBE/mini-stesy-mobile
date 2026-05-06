import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'well_animation_widget.dart';
import 'river_animation_widget.dart';
import 'awr_visualization_widget.dart';
import 'awqr_visualization_widget.dart';
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

    final isARR = kategori.contains('ARR');
    final isAWLR = kategori.contains('AWLR');
    final isAWR = kategori.contains('AWR');
    final isAFMR = kategori.contains('AFMR');
    final isAWQR = kategori.contains('AWQR');
    final hideDataPengukuran = isARR || isAWR || isAWLR || isAFMR || isAWQR;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAWLR && subKategori == 'jiat')
          _buildDataSumurCard(context, point['id_logger'].toString(), sensorData, isOnline),

        // ── Visualisasi Animasi
        _buildVisualization(
            context, point['id_logger'].toString(),
            kategori, subKategori, sensorData,
            jiatData, nonjiatData, isOnline),

        if (!hideDataPengukuran) ...[
          const SizedBox(height: 12),

          // ── Data Sensor Utama
          // ── Data Sensor Utama
          _buildSensorCardsAsLogger(context, point['id_logger'].toString(), sensorData, isOnline),
        ],

        const SizedBox(height: 12),

        // ── Health Logger
        _buildDataLoggerCard(context, point['id_logger'].toString(), loggerHealth, isOnline),
      ],
    );
  }

  Widget _buildVisualization(
    BuildContext context,
    String idLogger,
    String kategori,
    String? subKategori,
    Map<String, dynamic> sensorData,
    Map<String, dynamic>? jiatData,
    Map<String, dynamic>? nonjiatData,
    bool isOnline,
  ) {
    if (kategori.contains('AWLR')) {
      // JIAT (Sumur)
      if (subKategori == 'jiat' && jiatData != null) {
        final kdlSumur = (jiatData['kedalaman_sumur'] as num?)?.toDouble();
        final kdlSensor = (jiatData['kedalaman_sensor'] as num?)?.toDouble();
        final kdlPompa = (jiatData['kedalaman_pompa'] as num?)?.toDouble();
        
        final hasPump = (jiatData['has_pump'] == true) || 
                        (kdlPompa != null && kdlPompa > 0);
                        
        final mukaAir = (sensorData['muka_air_tanah'] as num?)?.toDouble() ??
            (sensorData['tma'] as num?)?.toDouble();

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
              WellAnimationWidget(
                kedalamanSumur: kdlSumur,
                kedalamanSensor: kdlSensor,
                kedalamanPompa: kdlPompa,
                mukaAirTanah: mukaAir,
                hasPump: hasPump,
                isOnline: isOnline,
                onLabelTap: (paramName) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailAnalisaScreen(
                        idLogger: idLogger,
                        parameterName: paramName,
                        isOnline: isOnline,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }

      // Non-JIAT (Sungai)
      return _buildRiverCard(context, idLogger, sensorData, nonjiatData, isOnline, 'assets/images/sungai/tiang_tanah.svg');
    }

    // AFMR
    if (kategori.contains('AFMR')) {
      return _buildRiverCard(context, idLogger, sensorData, nonjiatData, isOnline, 'assets/images/sungai/tiang_afmr.svg', isAFMR: true);
    }

    // ARR - curah hujan
    if (kategori.contains('ARR')) {
      final hujanPerJam = (sensorData['curah_hujan_per_jam'] as num?)?.toDouble() ?? 
                          (sensorData['curah_hujan'] as num?)?.toDouble() ?? 0.0;
      final hujanHarian = (sensorData['curah_hujan_harian'] as num?)?.toDouble() ?? 0.0;
      
      return Column(
        children: [
          _buildRainfallCard('AKUMULASI HARIAN', hujanHarian, isOnline),
          const SizedBox(height: 12),
          _buildRainfallCard('AKUMULASI 1 JAM', hujanPerJam, isOnline),
        ],
      );
    }

    // AWR - Automatic Weather Station
    if (kategori.contains('AWR')) {
      return AwrVisualizationWidget(
        idLogger: point['id_logger'].toString(),
        sensorData: sensorData,
        isOnline: isOnline,
      );
    }

    // AWQR - Automatic Water Quality
    if (kategori.contains('AWQR')) {
      return AwqrVisualizationWidget(
        idLogger: idLogger,
        sensorData: sensorData,
        isOnline: isOnline,
      );
    }

    // Default
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(Icons.sensors, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Visualisasi tidak tersedia',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildRiverCard(BuildContext context, String idLogger, Map<String, dynamic> sensorData, Map<String, dynamic>? nonjiatData, bool isOnline, String tiangAsset, {bool isAFMR = false}) {
    final tma = (sensorData['tma'] as num?)?.toDouble();
    final elevMin = (nonjiatData?['elevasi_min'] as num?)?.toDouble();
    final elevMax = (nonjiatData?['elevasi_max'] as num?)?.toDouble();
    
    final debit = (sensorData['debit'] as num?)?.toDouble();
    final luasPenampang = (sensorData['luas_penampang'] as num?)?.toDouble() ?? (sensorData['luas_penampang_basah'] as num?)?.toDouble();
    final kecepatanAliran = (sensorData['kecepatan_aliran'] as num?)?.toDouble() ?? (sensorData['flow_velocity'] as num?)?.toDouble();
    final elevSensor = (sensorData['elevasi_sensor'] as num?)?.toDouble();
    final jarakSensor = (sensorData['jarak_sensor'] as num?)?.toDouble();
    
    List<Widget> gridItems = [];
    
    if (isAFMR) {
      if (luasPenampang != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'luas_penampang', 'LUAS PENAMPANG BASAH', luasPenampang, 'm²', isOnline, assetPath: 'assets/images/afmr/luas_penampang_air.svg'));
      if (debit != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'debit', 'DEBIT', debit, 'm³/s', isOnline, assetPath: 'assets/images/awlr/debit.svg'));
      if (kecepatanAliran != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'flow_velocity', 'FLOW VELOCITY', kecepatanAliran, 'm/s', isOnline, assetPath: 'assets/images/afmr/flow_velocity.svg'));
      if (tma != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'tma', 'ELEVASI MUKA AIR', tma, 'm', isOnline, assetPath: 'assets/images/awlr/elevasi_muka_air.svg'));
      if (elevSensor != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'elevasi_sensor', 'ELEVASI SENSOR', elevSensor, 'm', isOnline, assetPath: 'assets/images/afmr/elevasi_sensor.svg'));
      if (jarakSensor != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'jarak_sensor', 'JARAK SENSOR', jarakSensor, 'm', isOnline, assetPath: 'assets/images/afmr/jarak_sensor.svg'));
    } else {
      if (tma != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'tma', 'TINGGI MUKA AIR', tma, 'm', isOnline, assetPath: 'assets/images/awlr/elevasi_muka_air.svg'));
      if (debit != null) gridItems.add(_buildSungaiCardItem(context, idLogger, 'debit', 'DEBIT', debit, 'm³/s', isOnline, assetPath: 'assets/images/awlr/debit.svg'));
    }

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
                Expanded(child: const SizedBox()),
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
          RiverAnimationWidget(
            tma: tma,
            elevasiMin: elevMin,
            elevasiMax: isAFMR ? elevSensor : elevMax,
            isOnline: isOnline,
            tiangAsset: tiangAsset,
          ),
          if (tma != null && gridRows.isNotEmpty) const SizedBox(height: 12),
          ...gridRows,
        ],
      ),
    );
  }

  Widget _buildRainfallCard(String title, double hujan, bool isOnline) {
    if (!isOnline) {
      hujan = 0.0;
    }

    String imagePath = 'assets/images/klasifikasi_hujan/';
    String labelKlasifikasi = '';
    
    if (hujan == 0) {
      imagePath += 'tidak_hujan.png';
      labelKlasifikasi = 'Berawan/Tidak Hujan';
    } else if (hujan < 5) {
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

    return Container(
      width: double.infinity,
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
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: isOnline ? 1.0 : 0.4,
              child: Image.asset(imagePath, height: 120, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade800, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isOnline ? hujan.toStringAsFixed(3) : '0.00', 
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isOnline ? Colors.black : Colors.grey)
                    ),
                    const SizedBox(width: 4),
                    Text('mm', style: TextStyle(fontSize: 14, color: isOnline ? Colors.black : Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                if (labelKlasifikasi.isNotEmpty) ...[
                  Text(
                    labelKlasifikasi,
                    style: TextStyle(fontSize: 13, color: isOnline ? const Color(0xFF0369A1) : Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataLoggerCard(BuildContext context, String idLogger, Map<String, dynamic> health, bool isOnline) {
    final humidity = health['humidity']?.toString() ?? '--';
    final battery = health['battery']?.toString() ?? '--';
    final temp = health['temp']?.toString() ?? '--';

    return Container(
      width: double.infinity,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Data Logger',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDataLoggerSvgItem(context, idLogger, 'humidity_online.svg', 'humidity_offline.svg', Colors.blue, 'HUMIDITY', 'humidity_logger', '$humidity %', isOnline),
                const SizedBox(width: 36),
                _buildDataLoggerSvgItem(context, idLogger, 'battery_online.svg', 'battery_offline.svg', Colors.green, 'BATTERY', 'battery_logger', '$battery Volt', isOnline),
                const SizedBox(width: 36),
                _buildDataLoggerSvgItem(context, idLogger, 'temper_online.svg', 'temper_offline.svg', Colors.orange, 'TEMPERATURE', 'temperature_logger', '$temp °C', isOnline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataLoggerItem(BuildContext context, String idLogger, IconData icon, Color color, String label, String parameterName, String value, bool isOnline) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              parameterName: parameterName,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent, // Ensures the whole column area is clickable
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: isOnline ? color : Colors.grey),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.black , letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOnline ? Colors.black : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataLoggerSvgItem(BuildContext context, String idLogger, String svgOnline, String svgOffline, Color color, String label, String parameterName, String value, bool isOnline) {
    final svgPath = 'assets/images/beranda/${isOnline ? svgOnline : svgOffline}';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              parameterName: parameterName,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent, // Ensures the whole column area is clickable
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(svgPath, width: 36, height: 36),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.black, letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOnline ? Colors.black : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCardsAsLogger(
      BuildContext context, String idLogger, Map<String, dynamic> sensorData, bool isOnline) {
    final items = <Widget>[];

    final tma = sensorData['tma'];
    final debit = sensorData['debit'];
    final hujan = sensorData['curah_hujan'];
    final elevasi = sensorData['elevasi_muka_air'];
    final airTanah = sensorData['muka_air_tanah'];

    if (tma != null) items.add(_buildDataLoggerItem(context, idLogger, Icons.waves, Colors.blue, 'TMA', 'tma', '${(tma as num).toStringAsFixed(3)} m', isOnline));
    if (debit != null) items.add(_buildDataLoggerItem(context, idLogger, Icons.speed, Colors.cyan, 'DEBIT', 'debit', '${(debit as num).toStringAsFixed(3)} m³/s', isOnline));
    if (hujan != null) items.add(_buildDataLoggerItem(context, idLogger, Icons.cloudy_snowing, Colors.indigo, 'CURAH HUJAN', 'curah_hujan', '${(hujan as num).toStringAsFixed(1)} mm', isOnline));
    if (elevasi != null) items.add(_buildDataLoggerItem(context, idLogger, Icons.height, Colors.teal, 'ELEVASI', 'elevasi_muka_air', '${(elevasi as num).toStringAsFixed(3)} m', isOnline));
    if (airTanah != null) items.add(_buildDataLoggerItem(context, idLogger, Icons.landscape, Colors.brown, 'AIR TANAH', 'muka_air_tanah', '${(airTanah as num).toStringAsFixed(3)} m', isOnline));

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Data Pengukuran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Expanded(child: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDataSumurCard(BuildContext context, String idLogger, Map<String, dynamic> sensorData, bool isOnline) {
    final tma = sensorData['tma'] ?? sensorData['muka_air_tanah'];
    final valueText = tma != null ? '${(tma as num).toStringAsFixed(3)} m' : '-';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              parameterName: 'muka_air_tanah',
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Data Sumur',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/muka_air_tanah.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MUKA AIR TANAH',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valueText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSungaiCardItem(BuildContext context, String idLogger, String parameterName, String label, double value, String unit, bool isOnline, {IconData? icon, Color? color, String? assetPath}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnalisaScreen(
              idLogger: idLogger,
              parameterName: parameterName,
              isOnline: isOnline,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // Ensures it is fully clickable
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (assetPath != null)
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
            )
          else if (icon != null && color != null)
            Icon(icon, size: 28, color: isOnline ? color : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.toStringAsFixed(3),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isOnline ? Colors.black : Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 10, color: isOnline ? Colors.black87 : Colors.grey),
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
