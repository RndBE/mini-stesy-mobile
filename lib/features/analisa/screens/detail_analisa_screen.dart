import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../data/analisa_repository.dart';
import '../widgets/custom_date_pickers.dart';
import '../widgets/offline_bottom_sheet.dart';

class ChartData {
  ChartData(this.time, this.min, this.maks, this.rerata);
  final DateTime time;
  final double min;
  final double maks;
  final double rerata;
}

class DetailAnalisaScreen extends StatefulWidget {
  final String idLogger;
  final String parameterName;
  final String? initialDisplayName;
  final bool isOnline;
  final String? namaPos;
  final String? namaLogger;

  const DetailAnalisaScreen({
    super.key,
    required this.idLogger,
    required this.parameterName,
    this.initialDisplayName,
    required this.isOnline,
    this.namaPos,
    this.namaLogger,
  });

  @override
  State<DetailAnalisaScreen> createState() => _DetailAnalisaScreenState();
}

class _DetailAnalisaScreenState extends State<DetailAnalisaScreen> {
  final AnalisaRepository _repository = AnalisaRepository();
  
  String _selectedRange = 'Hari'; // Hari, Bulan, Tahun, Rentang
  bool _isLoading = true;
  String? _errorMessage;

  List<ChartData> _chartData = [];
  List<Map<String, dynamic>> _tableData = [];
  String _satuan = '';
  double _minY = 0;
  double _maxY = 10;
  double _intervalY = 1;

  String _currentParameterName = '';
  String? _displayName;
  String _tipeGraf = 'line';
  List<Map<String, dynamic>> _availableParams = [];
  bool _showMaksLine = true;
  bool _showMinLine = true;
  bool _showRerataLine = true;

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();
  late DateTimeRange _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _currentParameterName = widget.parameterName;
    _displayName = widget.initialDisplayName;
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _fetchData();
  }

  Future<void> _downloadCsv() async {
    if (_tableData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diunduh')),
        );
      }
      return;
    }

    try {
      final StringBuffer csv = StringBuffer();
      
      // Header Informasi Pos & Logger
      csv.writeln('INFORMASI DATA LOGGER');
      if (widget.namaPos != null && widget.namaPos!.isNotEmpty) {
        csv.writeln('Nama Pos,"${widget.namaPos}"');
      }
      if (widget.namaLogger != null && widget.namaLogger!.isNotEmpty) {
        csv.writeln('Nama Logger,"${widget.namaLogger}"');
      }
      csv.writeln('ID Logger,"${widget.idLogger}"');
      csv.writeln('Parameter,"${_formatParamName(_currentParameterName)}"');
      csv.writeln(''); // baris kosong sebagai pemisah

      csv.writeln('Waktu,Minimum,Maksimum,Rerata');
      
      for (var row in _tableData) {
        final waktu = row['waktu'] ?? '';
        final min = row['min']?.toStringAsFixed(2) ?? '';
        final maks = row['maks']?.toStringAsFixed(2) ?? '';
        final rerata = row['rerata']?.toStringAsFixed(2) ?? '';
        csv.writeln('"$waktu","$min","$maks","$rerata"');
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/analisa_data_${DateTime.now().millisecondsSinceEpoch}.csv';
      final File file = File(filePath);
      await file.writeAsString(csv.toString());

      await Share.shareXFiles([XFile(filePath)], text: 'Data Analisa ${_formatParamName(_currentParameterName)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat file CSV: $e')),
        );
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      DateTime fromDt;
      DateTime toDt;

      if (_selectedRange == 'Hari') {
        fromDt = _selectedDate;
        toDt = _selectedDate;
      } else if (_selectedRange == 'Bulan') {
        fromDt = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        toDt = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      } else if (_selectedRange == 'Tahun') {
        fromDt = DateTime(_selectedYear.year, 1, 1);
        toDt = DateTime(_selectedYear.year, 12, 31);
      } else {
        fromDt = _selectedDateRange.start;
        toDt = _selectedDateRange.end;
      }

      final fromStr = DateFormat('yyyy-MM-dd').format(fromDt);
      final toStr = DateFormat('yyyy-MM-dd').format(toDt);

      final response = await _repository.getAnalisaData(
        widget.idLogger,
        from: fromStr,
        to: toStr,
        parameter: _currentParameterName,
      );

      if (response['success'] == true) {
        final paramsInfo = response['params'] as List?;
        String column = '';
        if (paramsInfo != null && paramsInfo.isNotEmpty) {
          _availableParams = List<Map<String, dynamic>>.from(paramsInfo);
          final currentLabelLower = _currentParameterName.toLowerCase();
          final currentSlug = currentLabelLower.replaceAll(' ', '_');

          final matchedParam = _availableParams.firstWhere(
            (p) {
               final nama = (p['nama_parameter']?.toString().toLowerCase() ?? '');
               final kolom = (p['kolom_sensor']?.toString().toLowerCase() ?? '');
               return nama == currentLabelLower || 
                      kolom == currentLabelLower ||
                      nama == currentSlug ||
                      kolom == currentSlug ||
                      nama.replaceAll('_', ' ') == currentLabelLower;
            },
            orElse: () => _availableParams.first,
          );
          column = matchedParam['kolom_sensor'] ?? '';
          _satuan = matchedParam['satuan'] ?? '';
          _tipeGraf = matchedParam['tipe_graf']?.toString() ?? 'line';
          _currentParameterName = matchedParam['nama_parameter'] ?? _currentParameterName;
          _displayName = _currentParameterName;
        }

        final rawData = response['data'] as List?;
        _processData(rawData, column);
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      if (mounted) {
        bool isNetworkError = false;
        String displayError = e.toString();

        if (e is DioException) {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            return; // Biarkan interceptor global yang menangani (force logout / suspend)
          }

          isNetworkError = e.type == DioExceptionType.connectionTimeout ||
                           e.type == DioExceptionType.sendTimeout ||
                           e.type == DioExceptionType.receiveTimeout ||
                           e.type == DioExceptionType.connectionError ||
                           e.type == DioExceptionType.unknown;

          if (e.response != null && e.response?.data is Map && e.response?.data['message'] != null) {
            displayError = e.response?.data['message'];
          } else {
            displayError = e.message ?? e.toString();
          }
        } else if (e.toString().toLowerCase().contains('socketexception') || e.toString().toLowerCase().contains('host lookup')) {
          isNetworkError = true;
        }

        if (isNetworkError) {
          showOfflineBottomSheet(context, () {
            _fetchData();
          });
        } else {
          setState(() { _isLoading = false; }); // Hentikan loading hanya untuk error server/biasa
          showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
                      const SizedBox(height: 16),
                      const Text('Gagal Memuat Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(displayError, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() { _isLoading = true; });
                            _fetchData();
                          },
                          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 8), // Extra space
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
    }
  }

  void _processData(List? rawData, String column) {
    if (rawData == null || rawData.isEmpty || column.isEmpty) {
      setState(() {
        _chartData = [];
        _tableData = [];
        _isLoading = false;
      });
      return;
    }

    Map<String, List<double>> grouped = {};

    for (var row in rawData) {
      if (row['waktu'] == null || row[column] == null) continue;

      final dt = DateTime.parse(row['waktu']).toLocal();
      String key;
      if (_selectedRange == 'Hari' || _selectedRange == 'Rentang') {
        key = DateFormat('yyyy-MM-dd HH:00').format(dt);
      } else if (_selectedRange == 'Bulan') {
        key = DateFormat('yyyy-MM-dd').format(dt);
      } else {
        key = DateFormat('yyyy-MM').format(dt);
      }

      final val = double.tryParse(row[column].toString());
      if (val != null) {
        grouped.putIfAbsent(key, () => []).add(val);
      }
    }

    List<ChartData> chartData = [];
    List<Map<String, dynamic>> tableData = [];
    
    final sortedKeys = grouped.keys.toList()..sort();
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;

    for (var key in sortedKeys) {
      final values = grouped[key]!;
      final min = values.reduce((a, b) => a < b ? a : b);
      final maks = values.reduce((a, b) => a > b ? a : b);
      final rerata = values.reduce((a, b) => a + b) / values.length;

      if (min < globalMin) globalMin = min;
      if (maks > globalMax) globalMax = maks;

      tableData.add({
        'waktu': key,
        'min': min,
        'maks': maks,
        'rerata': rerata,
      });

      DateTime parsedTime;
      if (_selectedRange == 'Hari' || _selectedRange == 'Rentang') {
        parsedTime = DateTime.parse('$key:00');
      } else if (_selectedRange == 'Tahun') {
        parsedTime = DateTime.parse('$key-01');
      } else {
        parsedTime = DateTime.parse(key);
      }

      chartData.add(ChartData(parsedTime, min, maks, rerata));
    }

    // Set chart boundaries
    if (globalMin == double.infinity) {
      globalMin = 0;
      globalMax = 10;
    }
    
    // Add some padding to Y axis
    double padding = (globalMax - globalMin) * 0.1;
    if (padding == 0) padding = 1;
    
    setState(() {
      _chartData = chartData;
      // Urutkan tabel dari yang terbaru
      _tableData = tableData.reversed.toList();
      _minY = globalMin - padding;
      _maxY = globalMax + padding;
      
      // Hitung interval
      final diff = _maxY - _minY;
      if (diff <= 5) {
        _intervalY = 1;
      } else if (diff <= 20) _intervalY = 5;
      else if (diff <= 50) _intervalY = 10;
      else if (diff <= 100) _intervalY = 20;
      else _intervalY = diff / 5;
      
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Biru gelap
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Analisa',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              _downloadCsv();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Info Card diletakkan di luar loading agar Hero animation selalu punya tujuan saat frame pertama
          _buildHeaderInfoCard(),
          const SizedBox(height: 16),
          
          if (_isLoading)
            _buildSkeletonContentOnly()
          else ...[
            // Segmented Buttons (Hari, Bulan, Tahun, Rentang)
            _buildSegmentedButtons(),
            const SizedBox(height: 16),

            // Selector Parameter
            if (_availableParams.isNotEmpty) ...[
              _buildParameterSelector(),
              const SizedBox(height: 16),
            ],

            // Chart Card
            _buildChartCard(),
            const SizedBox(height: 16),

            // Data Table Card
            _buildDataTableCard(),
          ]
        ],
      ),
    );
  }

  Widget _buildSkeletonContentOnly() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          // Segmented Buttons Skeleton
          Row(
            children: List.generate(4, (index) => Expanded(
              child: Container(
                height: 36,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )),
          ),
          const SizedBox(height: 16),

          // Selector Parameter Skeleton
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Chart Card Skeleton
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Data Table Card Skeleton
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoCard() {
    // Tentukan judul: prioritas namaPos > namaLogger > parameter name
    final String title;
    final String? subtitle;
    
    final paramText = _formatParamName(_displayName ?? _currentParameterName);
    final bool hasParam = paramText.isNotEmpty;
    
    if (widget.namaPos != null && widget.namaPos!.isNotEmpty) {
      title = widget.namaPos!;
      subtitle = hasParam ? paramText : widget.namaLogger;
    } else if (widget.namaLogger != null && widget.namaLogger!.isNotEmpty) {
      title = widget.namaLogger!;
      subtitle = hasParam ? paramText : null;
    } else {
      title = hasParam ? paramText : widget.idLogger;
      subtitle = null;
    }

    // Saat loading dan belum ada parameter (misal: buka dari peta), tunjukkan shimmer
    final bool showParamShimmer = _isLoading && !hasParam;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon: shimmer saat belum ada data parameter
          if (showParamShimmer)
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            Hero(
              tag: 'hero-${widget.idLogger}-${widget.parameterName}',
              child: _buildParameterIcon(),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Subtitle: shimmer saat parameter belum diketahui
                if (showParamShimmer) ...[
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ] else if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      widget.isOnline ? Icons.fiber_manual_record : Icons.radio_button_checked,
                      size: 12,
                      color: widget.isOnline ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isOnline ? 'Koneksi Terhubung' : 'Koneksi Terputus',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedButtons() {
    final options = ['Hari', 'Bulan', 'Tahun', 'Rentang'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((option) {
        final isSelected = _selectedRange == option;
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              bool shouldFetch = false;
              
              if (option == 'Hari') {
                final picked = await showCustomDayPicker(
                  context: context,
                  initialDate: _selectedDate,
                );
                if (picked != null) {
                  _selectedDate = picked;
                  shouldFetch = true;
                }
              } else if (option == 'Bulan') {
                final picked = await showCustomMonthPicker(
                  context: context,
                  initialDate: _selectedMonth,
                );
                if (picked != null) {
                  _selectedMonth = picked;
                  shouldFetch = true;
                }
              } else if (option == 'Tahun') {
                final picked = await showCustomYearPicker(
                  context: context,
                  initialDate: _selectedYear,
                );
                if (picked != null) {
                  _selectedYear = picked;
                  shouldFetch = true;
                }
              } else if (option == 'Rentang') {
                final picked = await showCustomDateRangePicker(
                  context: context,
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  _selectedDateRange = picked;
                  shouldFetch = true;
                }
              }

              if (shouldFetch) {
                setState(() {
                  _selectedRange = option;
                });
                _fetchData();
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: option == 'Rentang' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E3B84) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E3B84), // header background color
          onPrimary: Colors.white, // header text color
          onSurface: Color(0xFF1E293B), // body text color
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2E3B84), // button text color
          ),
        ),
      ),
      child: child!,
    );
  }

  // Warna intensitas hujan per jam — matching website implementation
  Color _getRainfallColor(double val) {
    if (val <= 0) return const Color(0xFF84C450);   // Tidak Hujan
    if (val < 1)  return const Color(0xFF70CDDD);   // Sangat Ringan
    if (val < 5)  return const Color(0xFF35549D);   // Ringan
    if (val < 10) return const Color(0xFFFEF216);   // Sedang
    if (val < 20) return const Color(0xFFF47E2C);   // Lebat
    return const Color(0xFFED1C24);                  // Sangat Lebat
  }

  String _getRainfallLabel(double val) {
    if (val <= 0) return 'Tidak Hujan';
    if (val < 1)  return 'Hujan Sangat Ringan';
    if (val < 5)  return 'Hujan Ringan';
    if (val < 10) return 'Hujan Sedang';
    if (val < 20) return 'Hujan Lebat';
    return 'Hujan Sangat Lebat';
  }

  bool get _isBarChart => _tipeGraf == 'bar';

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isBarChart
                ? '${_formatParamName(_currentParameterName)} ${_satuan.isNotEmpty ? '($_satuan)' : ''}'
                : 'Rerata ${_formatParamName(_currentParameterName)} ${_satuan.isNotEmpty ? '($_satuan)' : ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (_chartData.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isBarChart ? Icons.bar_chart : Icons.show_chart, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Tidak ada data tersedia pada rentang waktu ini.',
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: _isBarChart ? _buildBarChart() : _buildLineChart(),
            ),
          const SizedBox(height: 16),
          _isBarChart ? _buildRainfallLegend() : _buildLineLegend(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return SfCartesianChart(
      margin: const EdgeInsets.all(0),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
          final chartData = data as ChartData;
          final val = chartData.rerata;
          final valStr = val.toStringAsFixed(2);
          final color = _getRainfallColor(val);
          final label = _getRainfallLabel(val);

          String timeLabel = '';
          if (_selectedRange == 'Hari') {
            timeLabel = DateFormat('HH:mm').format(chartData.time);
          } else if (_selectedRange == 'Rentang') {
            timeLabel = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(chartData.time);
          } else if (_selectedRange == 'Tahun') {
            timeLabel = DateFormat('MMMM yyyy', 'id_ID').format(chartData.time);
          } else {
            timeLabel = DateFormat('dd MMM yyyy', 'id_ID').format(chartData.time);
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                const SizedBox(height: 6),
                Container(height: 1, width: 120, color: Colors.black12),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text('$valStr $_satuan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
      ),
      primaryXAxis: DateTimeAxis(
        dateFormat: _selectedRange == 'Hari' ? DateFormat('HH:mm') :
                    _selectedRange == 'Tahun' ? DateFormat('MMM yy') : DateFormat('dd MMM'),
        majorGridLines: const MajorGridLines(width: 0),
        intervalType: _selectedRange == 'Hari' ? DateTimeIntervalType.hours :
                      _selectedRange == 'Tahun' ? DateTimeIntervalType.months : DateTimeIntervalType.days,
        labelStyle: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: _maxY,
        interval: _intervalY,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(color: Colors.grey.shade200),
        labelStyle: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        labelFormat: '{value} mm',
      ),
      series: <CartesianSeries>[
        ColumnSeries<ChartData, DateTime>(
          name: 'Curah Hujan',
          dataSource: _chartData,
          xValueMapper: (ChartData data, _) => data.time,
          yValueMapper: (ChartData data, _) => data.rerata,
          pointColorMapper: (ChartData data, _) => _getRainfallColor(data.rerata),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          width: 0.6,
          spacing: 0.3,
          animationDuration: 1000,
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    return SfCartesianChart(
      margin: const EdgeInsets.all(0),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        builder: (BuildContext context, TrackballDetails trackballDetails) {
          final modeInfo = trackballDetails.groupingModeInfo;
          if (modeInfo == null || modeInfo.points.isEmpty) return const SizedBox.shrink();

          final firstPoint = modeInfo.points.first;
          String timeLabel = '';
          if (firstPoint.x is DateTime) {
            final DateTime time = firstPoint.x;
            if (_selectedRange == 'Hari') {
              timeLabel = DateFormat('HH:mm').format(time);
            } else if (_selectedRange == 'Rentang') {
              timeLabel = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(time);
            } else if (_selectedRange == 'Tahun') {
              timeLabel = DateFormat('MMMM yyyy', 'id_ID').format(time);
            } else {
              timeLabel = DateFormat('dd MMM yyyy', 'id_ID').format(time);
            }
          }

          Widget? rerataRow;
          Widget? minRow;
          Widget? maksRow;

          for (int i = 0; i < modeInfo.points.length && i < modeInfo.visibleSeriesList.length; i++) {
            final point = modeInfo.points[i];
            final series = modeInfo.visibleSeriesList[i];
            final seriesName = series.name;

            if (seriesName == 'Maks' || seriesName == 'Min' || seriesName == 'Rerata') {
              Color dotColor = Colors.black;
              String labelName = seriesName;
              if (seriesName == 'Maks') {
                dotColor = const Color(0xFF4F46E5);
                labelName = 'Maksimum';
              } else if (seriesName == 'Rerata') {
                dotColor = const Color(0xFF1E3A8A);
              } else if (seriesName == 'Min') {
                dotColor = const Color(0xFF38BDF8);
                labelName = 'Minimum';
              }

              final yValue = point.y;
              final yString = yValue is double ? yValue.toStringAsFixed(2) : yValue.toString();

              final row = Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('● ', style: TextStyle(color: dotColor, fontSize: 14)),
                    Text('$labelName: ', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                    Text('$yString $_satuan', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              );

              if (seriesName == 'Rerata') {
                rerataRow = row;
              } else if (seriesName == 'Min') { minRow = row; }
              else if (seriesName == 'Maks') { maksRow = row; }
            }
          }

          List<Widget> rows = [];
          if (rerataRow != null) rows.add(rerataRow);
          if (minRow != null) rows.add(minRow);
          if (maksRow != null) rows.add(maksRow);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (timeLabel.isNotEmpty) ...[
                  Text(timeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                  const SizedBox(height: 6),
                  Container(height: 1, width: 120, color: Colors.black12),
                  const SizedBox(height: 6),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
              ],
            ),
          );
        },
        markerSettings: const TrackballMarkerSettings(
          markerVisibility: TrackballVisibilityMode.visible,
          height: 10,
          width: 10,
          borderWidth: 2,
        ),
        lineType: TrackballLineType.vertical,
        lineColor: Colors.grey.withValues(alpha: 0.5),
        lineWidth: 1,
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
      ),
      primaryXAxis: DateTimeAxis(
        dateFormat: _selectedRange == 'Hari' ? DateFormat('HH:mm') :
                    _selectedRange == 'Tahun' ? DateFormat('MMM yy') : DateFormat('dd MMM'),
        majorGridLines: const MajorGridLines(width: 0),
        intervalType: _selectedRange == 'Hari' ? DateTimeIntervalType.hours :
                      _selectedRange == 'Tahun' ? DateTimeIntervalType.months : DateTimeIntervalType.days,
        labelStyle: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
      ),
      primaryYAxis: NumericAxis(
        minimum: _minY,
        maximum: _maxY,
        interval: _intervalY,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(color: Colors.grey.shade200),
        labelStyle: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
      ),
      series: <CartesianSeries>[
        RangeAreaSeries<ChartData, DateTime>(
          key: const ValueKey('area-maks-rerata'),
          dataSource: _showMaksLine && _showRerataLine ? _chartData : const <ChartData>[],
          xValueMapper: (ChartData data, _) => data.time,
          highValueMapper: (ChartData data, _) => data.maks,
          lowValueMapper: (ChartData data, _) => data.rerata,
          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          animationDuration: 1000,
          enableTooltip: false,
          enableTrackball: false,
          isVisibleInLegend: false,
        ),
        RangeAreaSeries<ChartData, DateTime>(
          key: const ValueKey('area-rerata-min'),
          dataSource: _showMinLine && _showRerataLine ? _chartData : const <ChartData>[],
          xValueMapper: (ChartData data, _) => data.time,
          highValueMapper: (ChartData data, _) => data.rerata,
          lowValueMapper: (ChartData data, _) => data.min,
          color: const Color(0xFF60A5FA).withValues(alpha: 0.1),
          animationDuration: 1000,
          enableTooltip: false,
          enableTrackball: false,
          isVisibleInLegend: false,
        ),
        FastLineSeries<ChartData, DateTime>(
          key: const ValueKey('line-maks'),
          name: 'Maks',
          dataSource: _showMaksLine ? _chartData : const <ChartData>[],
          xValueMapper: (ChartData data, _) => data.time,
          yValueMapper: (ChartData data, _) => data.maks,
          color: const Color(0xFF4F46E5),
          dashArray: <double>[5, 5],
          width: 2,
          animationDuration: 1000,
        ),
        FastLineSeries<ChartData, DateTime>(
          key: const ValueKey('line-min'),
          name: 'Min',
          dataSource: _showMinLine ? _chartData : const <ChartData>[],
          xValueMapper: (ChartData data, _) => data.time,
          yValueMapper: (ChartData data, _) => data.min,
          color: const Color(0xFF38BDF8),
          dashArray: <double>[5, 5],
          width: 2,
          animationDuration: 1000,
        ),
        FastLineSeries<ChartData, DateTime>(
          key: const ValueKey('line-rerata'),
          name: 'Rerata',
          dataSource: _showRerataLine ? _chartData : const <ChartData>[],
          xValueMapper: (ChartData data, _) => data.time,
          yValueMapper: (ChartData data, _) => data.rerata,
          color: const Color(0xFF1E3A8A),
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            color: Colors.white,
            borderColor: Color(0xFF1E3A8A),
            borderWidth: 2,
          ),
          animationDuration: 1000,
        ),
      ],
    );
  }

  Widget _buildRainfallLegend() {
    final legends = [
      (const Color(0xFF84C450), 'Tidak Hujan', '0 mm'),
      (const Color(0xFF70CDDD), 'Sangat Ringan', '0.1 – 1 mm'),
      (const Color(0xFF35549D), 'Ringan', '1 – 5 mm'),
      (const Color(0xFFFEF216), 'Sedang', '5 – 10 mm'),
      (const Color(0xFFF47E2C), 'Lebat', '10 – 20 mm'),
      (const Color(0xFFED1C24), 'Sangat Lebat', '≥ 20 mm'),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: legends.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: e.$1,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            e.$2,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ],
      )).toList(),
    );
  }

  Widget _buildLineLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _buildLegendItem(
          const Color(0xFF4F46E5),
          'Maks',
          isActive: _showMaksLine,
          onTap: () => setState(() => _showMaksLine = !_showMaksLine),
        ),
        _buildLegendItem(
          const Color(0xFF38BDF8),
          'Min',
          isActive: _showMinLine,
          onTap: () => setState(() => _showMinLine = !_showMinLine),
        ),
        _buildLegendItem(
          const Color(0xFF1E3A8A),
          'Rerata',
          isCircle: true,
          isActive: _showRerataLine,
          onTap: () => setState(() => _showRerataLine = !_showRerataLine),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label, {
    bool isCircle = false,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = isActive ? color : Colors.grey.shade400;
    final textColor = isActive ? Colors.grey.shade700 : Colors.grey.shade500;

    return Semantics(
      button: true,
      selected: isActive,
      label: '${isActive ? 'Sembunyikan' : 'Tampilkan'} garis $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.08) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive ? color.withValues(alpha: 0.35) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 10,
                  child: Center(
                    child: isCircle
                        ? Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: activeColor, width: 2),
                            ),
                          )
                        : Container(
                            width: 14,
                            height: 2,
                            color: activeColor,
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                    decorationColor: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildTableHeaderText('WAKTU')),
                Expanded(flex: 2, child: _buildTableHeaderText('RERATA', align: TextAlign.center)),
                Expanded(flex: 1, child: _buildTableHeaderText('MIN', align: TextAlign.center)),
                Expanded(flex: 1, child: _buildTableHeaderText('MAKS', align: TextAlign.right)),
              ],
            ),
          ),
          // Table Rows
          if (_tableData.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Tidak ada riwayat data pada rentang ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            )
          else
            ..._tableData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: index < _tableData.length - 1
                      ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        data['waktu'],
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        data['rerata'].toStringAsFixed(2),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        data['min'].toStringAsFixed(2),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                      ),
                    ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      data['maks'].toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeaderText(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        letterSpacing: 0.5,
      ),
    );
  }

  String _formatParamName(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildParameterSelector() {
    return GestureDetector(
      onTap: _showParameterBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _formatParamName(_currentParameterName),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showParameterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: (() {
                        // Urutkan berdasarkan nomor sensor (sensor1, sensor2, dst)
                        final sorted = [..._availableParams];
                        sorted.sort((a, b) {
                          final kolA = a['kolom_sensor']?.toString() ?? '';
                          final kolB = b['kolom_sensor']?.toString() ?? '';
                          final numA = int.tryParse(kolA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9999;
                          final numB = int.tryParse(kolB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9999;
                          return numA.compareTo(numB);
                        });
                        return sorted.map((param) {
                          final paramName = param['nama_parameter']?.toString() ?? 'Unknown';
                          final isSelected = paramName == _currentParameterName;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                            title: Text(
                              _formatParamName(paramName),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            trailing: isSelected 
                                ? const Icon(Icons.radio_button_checked, color: Colors.black, size: 20)
                                : const Icon(Icons.radio_button_off, color: Colors.black54, size: 20),
                            onTap: () {
                              Navigator.pop(context);
                              if (!isSelected) {
                                setState(() {
                                  _currentParameterName = paramName;
                                  _displayName = paramName;
                                });
                                _fetchData();
                              }
                            },
                          );
                        }).toList();
                      })(),

                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParameterIcon() {
    String? assetPath;
    IconData? iconData;

    String resolveName = (_displayName ?? _currentParameterName)
        .toLowerCase()
        .replaceAll(' ', '_');

    switch (resolveName) {
      case 'tma':
      case 'elevasi_muka_air':
      case 'tinggi_muka_air':
        assetPath = 'assets/images/awlr/elevasi_muka_air.svg';
        break;
      case 'debit':
        assetPath = 'assets/images/awlr/debit.svg';
        break;
      case 'luas_penampang':
      case 'luas_penampang_basah':
        assetPath = 'assets/images/afmr/luas_penampang_air.svg';
        break;
      case 'flow_velocity':
      case 'kecepatan_aliran':
        assetPath = 'assets/images/afmr/flow_velocity.svg';
        break;
      case 'elevasi_sensor':
      case 'tinggi_sensor':
        assetPath = 'assets/images/afmr/elevasi_sensor.svg';
        break;
      case 'jarak_sensor':
        assetPath = 'assets/images/afmr/jarak_sensor.svg';
        break;
      case 'kecepatan_angin':
        assetPath = 'assets/images/awr/kecepatan_angin.svg';
        break;
      case 'arah_angin':
        assetPath = 'assets/images/awr/arah_angin.svg';
        break;
      case 'kecerahan':
        assetPath = 'assets/images/awr/kecerahan.svg';
        break;
      case 'arah_cahaya':
        assetPath = 'assets/images/awr/arah.svg';
        break;
      case 'temperature':
      case 'temp_logger':
      case 'temperature_logger':
      case 'suhu':
        assetPath = 'assets/images/beranda/temper_online.svg';
        break;
      case 'tekanan_udara':
        assetPath = 'assets/images/awr/tekanan_udara.svg';
        break;
      case 'humidity':
      case 'kelembaban':
      case 'humidity_logger':
        assetPath = 'assets/images/beranda/humidity_online.svg';
        break;
      case 'ph_air':
        assetPath = 'assets/images/awqr/ph_air.svg';
        break;
      case 'suhu_air':
        assetPath = 'assets/images/awqr/suhu_air.svg';
        break;
      case 'orp':
        assetPath = 'assets/images/awqr/orp.svg';
        break;
      case 'conductivity':
        assetPath = 'assets/images/awqr/conductivity.svg';
        break;
      case 'salinity':
        assetPath = 'assets/images/awqr/salinity.svg';
        break;
      case 'tds':
        assetPath = 'assets/images/awqr/total_dissolved_solids.svg';
        break;
      case 'turbidity':
        assetPath = 'assets/images/awqr/turbidity.svg';
        break;
      case 'battery':
      case 'battery_logger':
        assetPath = 'assets/images/beranda/battery_online.svg';
        break;
      case 'curah_hujan':
        iconData = Icons.cloudy_snowing;
        break;
      case 'muka_air_tanah':
        assetPath = 'assets/images/muka_air_tanah.png';
        break;
      default:
        iconData = Icons.analytics_outlined;
    }

    final colorFilter = widget.isOnline ? null : const ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]);

    if (assetPath != null) {
      if (assetPath.endsWith('.png')) {
        Widget img = Image.asset(
          assetPath,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        );
        if (!widget.isOnline && colorFilter != null) {
          return ColorFiltered(
            colorFilter: colorFilter,
            child: img,
          );
        }
        return img;
      }
      return SvgPicture.asset(
        assetPath,
        width: 32,
        height: 32,
        colorFilter: colorFilter,
      );
    } else {
      return Icon(
        iconData ?? Icons.analytics_outlined,
        color: widget.isOnline ? Colors.blue.shade700 : Colors.grey,
        size: 32,
      );
    }
  }
}
