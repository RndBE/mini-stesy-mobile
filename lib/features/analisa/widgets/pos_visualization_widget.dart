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
                        namaPos: point['nama']?.toString(),
                        namaLogger: point['nama_logger']?.toString(),
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

    // AWLR (Non-JIAT)
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
      final paramsList = _getParamsList();
      // Exclude rain params since already shown in rainfall cards
      final otherParams = paramsList.where((p) {
        final utama = (p['parameter_utama'] ?? '').toString().toLowerCase();
        final nama = (p['nama'] ?? '').toString().toLowerCase();
        return !utama.contains('hujan') && !utama.contains('rain') && !utama.contains('curah') &&
               !nama.contains('hujan') && !nama.contains('rain') && !nama.contains('curah');
      }).toList();
      
      return Column(
        children: [
          _buildRainfallCard('AKUMULASI HARIAN', hujanHarian, isOnline),
          const SizedBox(height: 12),
          _buildRainfallCard('AKUMULASI 1 JAM', hujanPerJam, isOnline),
          if (otherParams.isNotEmpty) ...[  
            const SizedBox(height: 12),
            _buildDynamicParamGrid(context, point['id_logger'].toString(), otherParams, isOnline),
          ],
        ],
      );
    }

    // AWR - Automatic Weather Station
    if (kategori.contains('AWR')) {
      return AwrVisualizationWidget(
        idLogger: point['id_logger'].toString(),
        sensorData: sensorData,
        isOnline: isOnline,
        namaPos: point['nama']?.toString(),
        namaLogger: point['nama_logger']?.toString(),
      );
    }

    // AWQR - Automatic Water Quality
    if (kategori.contains('AWQR')) {
      return AwqrVisualizationWidget(
        idLogger: idLogger,
        sensorData: sensorData,
        isOnline: isOnline,
        namaPos: point['nama']?.toString(),
        namaLogger: point['nama_logger']?.toString(),
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
    final elevSensor = (sensorData['elevasi_sensor'] as num?)?.toDouble();

    // Use dynamic params from API
    final paramsList = _getParamsList();
    final dynamicGrid = _buildDynamicParamGrid(context, idLogger, paramsList, isOnline);

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
          if (paramsList.isNotEmpty) ...[
            const SizedBox(height: 12),
            dynamicGrid,
          ],
        ],
      ),
    );
  }




  List<Map<String, dynamic>> _getParamsList() {
    final raw = point['parameters_list'];
    if (raw == null || raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget _buildDynamicParamGrid(BuildContext context, String idLogger, List<Map<String, dynamic>> params, bool isOnline) {
    final items = params.where((p) => p['nilai'] != null).map((p) {
      final nama = p['nama']?.toString() ?? '';
      final satuan = p['satuan']?.toString() ?? _inferUnit(p['parameter_utama']?.toString() ?? '', p['key']?.toString() ?? '');
      final nilai = (p['nilai'] as num?)?.toDouble() ?? 0.0;
      final key = p['key']?.toString() ?? '';
      final paramUtama = p['parameter_utama']?.toString() ?? '';
      final iconPath = _getParamIconPath(paramUtama, nama.toLowerCase());
      final icon = _getParamIcon(paramUtama, nama.toLowerCase());
      final color = _getParamColor(paramUtama, nama.toLowerCase());
      if (iconPath != null) {
        return _buildSungaiCardItem(context, idLogger, key, nama.toUpperCase(), nilai, satuan, isOnline, assetPath: iconPath);
      }
      return _buildSungaiCardItem(context, idLogger, key, nama.toUpperCase(), nilai, satuan, isOnline, icon: icon, color: color);
    }).toList();

    if (items.isEmpty) return const SizedBox.shrink();
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(children: [
          Expanded(child: items[i]),
          const SizedBox(width: 8),
          i + 1 < items.length ? Expanded(child: items[i + 1]) : const Expanded(child: SizedBox()),
        ]),
      ));
    }
    return Column(children: rows);
  }

  String? _getParamIconPath(String u, String n) {
    final k = '$u $n';
    if (k.contains('tma') || k.contains('muka_air') || k.contains('tinggi_muka')) return 'assets/images/awlr/elevasi_muka_air.svg';
    if (k.contains('debit')) return 'assets/images/awlr/debit.svg';
    if (k.contains('luas_penampang') || k.contains('penampang')) return 'assets/images/afmr/luas_penampang_air.svg';
    if (k.contains('flow_velocity') || k.contains('velocity')) return 'assets/images/afmr/flow_velocity.svg';
    if (k.contains('elevasi_sensor')) return 'assets/images/afmr/elevasi_sensor.svg';
    if (k.contains('jarak_sensor')) return 'assets/images/afmr/jarak_sensor.svg';
    if (k.contains('elevasi')) return 'assets/images/awlr/elevasi_muka_air.svg';
    return null;
  }

  IconData _getParamIcon(String u, String n) {
    final k = '$u $n';
    if (k.contains('hujan') || k.contains('rain') || k.contains('curah')) return Icons.water_drop;
    if (k.contains('suhu') || k.contains('temperature') || k.contains('temp')) return Icons.thermostat;
    if (k.contains('kelembaban') || k.contains('humidity')) return Icons.opacity;
    if (k.contains('angin') || k.contains('wind')) return Icons.air;
    if (k.contains('tekanan') || k.contains('pressure')) return Icons.compress;
    if (k.contains('cahaya') || k.contains('light')) return Icons.wb_sunny;
    if (k.contains('ph')) return Icons.science;
    if (k.contains('turb') || k.contains('kekeruhan')) return Icons.blur_on;
    if (k.contains('conduct') || k.contains('konduktivitas')) return Icons.electric_bolt;
    if (k.contains('salin')) return Icons.waves;
    if (k.contains('tds')) return Icons.water;
    return Icons.sensors;
  }

  Color _getParamColor(String u, String n) {
    final k = '$u $n';
    if (k.contains('hujan') || k.contains('rain')) return Colors.blue;
    if (k.contains('suhu') || k.contains('temp')) return Colors.orange;
    if (k.contains('kelembaban') || k.contains('humidity')) return Colors.lightBlue;
    if (k.contains('angin') || k.contains('wind')) return Colors.teal;
    if (k.contains('tekanan') || k.contains('pressure')) return Colors.purple;
    if (k.contains('cahaya') || k.contains('light')) return Colors.amber;
    if (k.contains('ph')) return Colors.green;
    return Colors.blueGrey;
  }

  String _inferUnit(String u, String k) {
    final s = '$u $k';
    if (s.contains('tma') || s.contains('muka_air') || s.contains('elevasi') || s.contains('jarak')) return 'm';
    if (s.contains('debit')) return 'm³/s';
    if (s.contains('hujan') || s.contains('rain') || s.contains('curah')) return 'mm';
    if (s.contains('suhu') || s.contains('temperature')) return '°C';
    if (s.contains('kelembaban') || s.contains('humidity')) return '%';
    if (s.contains('angin') || s.contains('wind') || s.contains('velocity') || s.contains('flow')) return 'm/s';
    if (s.contains('tekanan') || s.contains('pressure')) return 'hPa';
    if (s.contains('luas') || s.contains('penampang')) return 'm²';
    return '';
  }

  Widget _buildRainfallCard(String title, double hujan, bool isOnline) {
    // if (!isOnline) {
    //   hujan = 0.0;
    // }

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
                      hujan.toStringAsFixed(2), 
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
              namaPos: point['nama']?.toString(),
              namaLogger: point['nama_logger']?.toString(),
              parameterName: parameterName,
              initialDisplayName: label,
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
            Hero(
              tag: 'hero-$idLogger-$parameterName',
              child: Icon(icon, size: 36, color: isOnline ? color : Colors.grey),
            ),
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
              namaPos: point['nama']?.toString(),
              namaLogger: point['nama_logger']?.toString(),
              parameterName: parameterName,
              initialDisplayName: label,
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
            Hero(
              tag: 'hero-$idLogger-$parameterName',
              child: SvgPicture.asset(svgPath, width: 36, height: 36),
            ),
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
              namaPos: point['nama']?.toString(),
              namaLogger: point['nama_logger']?.toString(),
              parameterName: 'muka_air_tanah',
              initialDisplayName: 'MUKA AIR TANAH',
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
                Hero(
                  tag: 'hero-$idLogger-muka_air_tanah',
                  child: Image.asset(
                    'assets/images/muka_air_tanah.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
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
              namaPos: point['nama']?.toString(),
              namaLogger: point['nama_logger']?.toString(),
              parameterName: parameterName,
              initialDisplayName: label,
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
            Hero(
              tag: 'hero-$idLogger-$parameterName',
              child: SvgPicture.asset(
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
            )
          else if (icon != null && color != null)
            Hero(
              tag: 'hero-$idLogger-$parameterName',
              child: Icon(icon, size: 28, color: isOnline ? color : Colors.grey),
            ),
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
