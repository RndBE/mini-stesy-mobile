import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data/analisa_repository.dart';
import '../widgets/custom_date_pickers.dart';

class DetailAnalisaScreen extends StatefulWidget {
  final String idLogger;
  final String parameterName;
  final bool isOnline;

  const DetailAnalisaScreen({
    super.key,
    required this.idLogger,
    required this.parameterName,
    required this.isOnline,
  });

  @override
  State<DetailAnalisaScreen> createState() => _DetailAnalisaScreenState();
}

class _DetailAnalisaScreenState extends State<DetailAnalisaScreen> {
  final AnalisaRepository _repository = AnalisaRepository();
  
  String _selectedRange = 'Hari'; // Hari, Bulan, Tahun, Rentang
  bool _isLoading = true;
  String? _errorMessage;

  List<FlSpot> _spots = [];
  List<FlSpot> _minSpots = [];
  List<FlSpot> _maxSpots = [];
  List<Map<String, dynamic>> _tableData = [];
  String _satuan = '';
  double _minY = 0;
  double _maxY = 10;
  double _intervalY = 1;

  String _currentParameterName = '';
  List<Map<String, dynamic>> _availableParams = [];

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();
  late DateTimeRange _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _currentParameterName = widget.parameterName;
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _fetchData();
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
          _currentParameterName = matchedParam['nama_parameter'] ?? _currentParameterName;
        }

        final rawData = response['data'] as List?;
        _processData(rawData, column);
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _processData(List? rawData, String column) {
    if (rawData == null || rawData.isEmpty || column.isEmpty) {
      setState(() {
        _spots = [];
        _minSpots = [];
        _maxSpots = [];
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
      if (_selectedRange == 'Hari') {
        key = DateFormat('yyyy-MM-dd HH:00').format(dt);
      } else if (_selectedRange == 'Bulan' || _selectedRange == 'Rentang') {
        key = DateFormat('yyyy-MM-dd').format(dt);
      } else {
        key = DateFormat('yyyy-MM').format(dt);
      }

      final val = double.tryParse(row[column].toString());
      if (val != null) {
        grouped.putIfAbsent(key, () => []).add(val);
      }
    }

    List<FlSpot> spots = [];
    List<FlSpot> minSpots = [];
    List<FlSpot> maxSpots = [];
    List<Map<String, dynamic>> tableData = [];
    
    final sortedKeys = grouped.keys.toList()..sort();
    int i = 0;
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

      spots.add(FlSpot(i.toDouble(), rerata));
      minSpots.add(FlSpot(i.toDouble(), min));
      maxSpots.add(FlSpot(i.toDouble(), maks));
      i++;
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
      _spots = spots;
      _minSpots = minSpots;
      _maxSpots = maxSpots;
      // Urutkan tabel dari yang terbaru
      _tableData = tableData.reversed.toList();
      _minY = globalMin - padding;
      _maxY = globalMax + padding;
      
      // Hitung interval
      final diff = _maxY - _minY;
      if (diff <= 5) _intervalY = 1;
      else if (diff <= 20) _intervalY = 5;
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchData();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Gagal memuat data:\n$_errorMessage', 
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Info Card
          _buildHeaderInfoCard(),
          const SizedBox(height: 16),
          
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
        ],
      ),
    );
  }

  Widget _buildHeaderInfoCard() {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildParameterIcon(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatParamName(_currentParameterName),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
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

              if (shouldFetch || _selectedRange != option) {
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

  Widget _buildChartCard() {
    final chartColor = widget.isOnline ? Colors.blue : Colors.grey;

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
      child: Column(
        children: [
          Text(
            'Rerata ${_formatParamName(_currentParameterName)} ${_satuan.isNotEmpty ? '($_satuan)' : ''}',
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
          if (_spots.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Tidak ada data tersedia pada rentang waktu ini.',
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 1.5,
              child: LineChart(
                LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.white,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    maxContentWidth: 250,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    tooltipBorder: const BorderSide(color: Colors.black12, width: 1),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      if (touchedSpots.isEmpty) return [];

                      final x = touchedSpots.first.x.toInt();
                      final int idx = _tableData.length - 1 - x;
                      String timeLabel = '';
                      if (idx >= 0 && idx < _tableData.length) {
                        final timeStr = _tableData[idx]['waktu'] as String;
                        if (_selectedRange == 'Hari') {
                          timeLabel = timeStr.substring(11, 16); // HH:mm
                        } else if (_selectedRange == 'Tahun') {
                          timeLabel = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.parse('$timeStr-01'));
                        } else {
                          timeLabel = DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(timeStr));
                        }
                      }

                      return touchedSpots.map((spot) {
                        String label = '';
                        Color dotColor = Colors.black;
                        if (spot.barIndex == 0) {
                          label = 'Maks';
                          dotColor = const Color(0xFF4F46E5);
                        } else if (spot.barIndex == 1) {
                          label = 'Rerata';
                          dotColor = const Color(0xFF1E3A8A);
                        } else {
                          label = 'Min';
                          dotColor = const Color(0xFF38BDF8);
                        }

                        final isFirst = spot.barIndex == touchedSpots.first.barIndex;
                        
                        return LineTooltipItem(
                          isFirst ? '$timeLabel\n' : '',
                          const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.left,
                          children: [
                            TextSpan(
                              text: '● ',
                              style: TextStyle(color: dotColor, fontSize: 16),
                            ),
                            TextSpan(
                              text: '$label:  ',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: '${spot.y.toStringAsFixed(2)} $_satuan',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                minY: _minY,
                maxY: _maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _intervalY,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0 || value < 0 || value >= _tableData.length) {
                           return const SizedBox.shrink();
                        }
                        // we reverse the tableData for display, but spots are in chronological order
                        // the index for spot is chronological.
                        // _tableData is descending. So spot index `value` corresponds to `_tableData[_tableData.length - 1 - value]`
                        final int idx = _tableData.length - 1 - value.toInt();
                        if (idx < 0 || idx >= _tableData.length) return const SizedBox.shrink();

                        final timeStr = _tableData[idx]['waktu'] as String;
                        // simplify the label
                        String label = '';
                        if (_selectedRange == 'Hari') {
                          label = timeStr.substring(11, 16); // HH:mm
                        } else if (_selectedRange == 'Tahun') {
                           label = timeStr.substring(5, 7); // MM
                        } else {
                           label = timeStr.substring(8, 10); // dd
                        }
                        
                        // only show a few labels if there are many spots
                        if (_spots.length > 7 && value % (_spots.length / 5).ceil() != 0 && value != _spots.length - 1) {
                           return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _intervalY,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),
                betweenBarsData: [
                  BetweenBarsData(
                    fromIndex: 0,
                    toIndex: 2,
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                  ),
                ],
                lineBarsData: [
                  // Index 0: Maks (dashed)
                  LineChartBarData(
                    spots: _maxSpots,
                    isCurved: true,
                    color: const Color(0xFF4F46E5), // Indigo
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                  // Index 1: Rerata (solid)
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    color: const Color(0xFF1E3A8A), // Dark blue
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: _spots.length < 20, // hide dots if too many
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF1E3A8A),
                        );
                      },
                    ),
                  ),
                  // Index 2: Min (dashed)
                  LineChartBarData(
                    spots: _minSpots,
                    isCurved: true,
                    color: const Color(0xFF38BDF8), // Light blue
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF4F46E5), 'Maks'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFF38BDF8), 'Min'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFF1E3A8A), 'Rerata', isCircle: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isCircle = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 2,
          color: isCircle ? Colors.transparent : color,
          child: isCircle
              ? Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
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
                    children: _availableParams.map((param) {
                      final paramName = param['nama_parameter']?.toString() ?? 'Unknown';
                      final isSelected = paramName == _currentParameterName;
                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
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
                            });
                            _fetchData();
                          }
                        },
                      );
                    }).toList(),
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

    switch (_currentParameterName.toLowerCase()) {
      case 'tma':
      case 'elevasi_muka_air':
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
          width: 28,
          height: 28,
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
        width: 28,
        height: 28,
        colorFilter: colorFilter,
      );
    } else {
      return Icon(
        iconData ?? Icons.analytics_outlined,
        color: widget.isOnline ? Colors.blue.shade700 : Colors.grey,
        size: 28,
      );
    }
  }
}
