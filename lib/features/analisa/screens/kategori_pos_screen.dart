import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shimmer/shimmer.dart';
import '../../peta/data/peta_repository.dart';
import '../widgets/pos_visualization_widget.dart';
import 'dokumentasi_pos_screen.dart';

class KategoriPosScreen extends StatefulWidget {
  final String kategori;

  const KategoriPosScreen({super.key, required this.kategori});

  @override
  State<KategoriPosScreen> createState() => _KategoriPosScreenState();
}

class _KategoriPosScreenState extends State<KategoriPosScreen> {
  final PetaRepository _repository = PetaRepository();
  bool _isLoading = true;
  String? _errorMessage;
  
  List<Map<String, dynamic>> _points = [];
  Map<String, dynamic>? _selectedPoint;
  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredPoints {
    if (!_isSearching || _searchController.text.isEmpty) {
      return _points;
    }
    final query = _searchController.text.toLowerCase();
    return _points.where((p) {
      final name = (p['nama_logger'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final points = await _repository.getPetaPoints();
      
      // Filter berdasarkan kategori dan casting tipe datanya
      final filteredPoints = points.where((p) {
        final k = (p['kategori'] ?? '').toString().toUpperCase();
        return k.contains(widget.kategori.toUpperCase()) || 
               widget.kategori.toUpperCase().contains(k);
      }).cast<Map<String, dynamic>>().toList();

      if (mounted) {
        setState(() {
          _points = filteredPoints;
          if (_points.isNotEmpty) {
            _selectedPoint = _points.first; // Default pilihan pertama
          }
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Biru gelap sesuai header
        elevation: 0,
        centerTitle: !_isSearching,
        titleSpacing: _isSearching ? 16 : null,
        title: _isSearching
            ? Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        hintText: 'Cari...',
                        hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false, // Memaksa background transparan
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (_filteredPoints.isNotEmpty && !_filteredPoints.contains(_selectedPoint)) {
                            _selectedPoint = _filteredPoints.first;
                          }
                          // Jika _filteredPoints kosong, kita biarkan _selectedPoint apa adanya
                          // agar tampilan visualisasi pos tetap terlihat.
                        });
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        if (_points.isNotEmpty && _selectedPoint == null) {
                          _selectedPoint = _points.first;
                        }
                      });
                    },
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ],
              )
            : Text(
                widget.kategori.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        leading: _isSearching
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        leadingWidth: _isSearching ? 0 : null,
        actions: _isSearching
            ? []
            : [
                PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'Cari') {
                setState(() {
                  _isSearching = true;
                });
              } else if (value == 'Informasi') {
                if (_selectedPoint != null) {
                  _showInformasiDialog(_selectedPoint!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pilih pos terlebih dahulu')),
                  );
                }
              } else if (value == 'Dokumentasi Pos') {
                if (_selectedPoint != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DokumentasiPosScreen(point: _selectedPoint!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pilih pos terlebih dahulu')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Cari',
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    const Text('Cari'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Dokumentasi Pos',
                child: Row(
                  children: [
                    Icon(Icons.image_outlined, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    const Text('Dokumentasi Pos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Informasi',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    const Text('Informasi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeletonLoading();
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
              onPressed: () {
                setState(() { _isLoading = true; _errorMessage = null; });
                _fetchData();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Tidak ada pos untuk kategori ${widget.kategori}',
                 style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Scrollable Chips Pemilihan Pos
        Container(
          height: 50,
          color: const Color(0xFF1E3A8A), // Background biru gelap dari header dilanjutkan
          child: _filteredPoints.isEmpty 
            ? Center(
                child: Text(
                  'Pos tidak ditemukan',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                itemCount: _filteredPoints.length,
                itemBuilder: (context, index) {
                  final point = _filteredPoints[index];
                  final isOnline = (point['status'] ?? 'offline') == 'online';
                  final isSelected = _selectedPoint == point;
                  final namaLogger = point['nama_logger'] ?? 'Pos Unknown';

              // Warna chip
              final chipBgColor = isOnline
                  ? const Color(0xFFD1FAE5) // Hijau muda cerah
                  : const Color(0xFFFEE2E2); // Merah muda
              final textColor = isOnline
                  ? const Color(0xFF065F46) // Teks hijau gelap
                  : const Color(0xFF991B1B); // Teks merah gelap
              final iconColor = isOnline
                  ? const Color(0xFF10B981) // Hijau solid
                  : const Color(0xFFEF4444); // Merah solid

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPoint = point;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: chipBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: iconColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        namaLogger,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Tanggal & Hari
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
          ),
          child: Builder(
            builder: (context) {
              final lastTimeStr = _selectedPoint?['last_time'];
              DateTime? lastTime;
              if (lastTimeStr != null && lastTimeStr.toString().isNotEmpty) {
                try {
                  lastTime = DateTime.parse(lastTimeStr.toString());
                } catch (_) {}
              }
              
              final dateStr = lastTime != null 
                  ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(lastTime)
                  : '-';
              final timeStr = lastTime != null 
                  ? DateFormat('HH:mm:ss').format(lastTime)
                  : '-';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            }
          ),
        ),
        
        // ── Body Visualisasi Pos yang dipilih
        Expanded(
          child: Container(
            color: const Color(0xFFF4F6F8), // Latar belakang abu-abu terang
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: _selectedPoint == null 
                    ? const SizedBox.shrink()
                    : PosVisualizationWidget(point: _selectedPoint!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showInformasiDialog(Map<String, dynamic> point) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2E3B84), // Matching the screenshot blue
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24), // Placeholder untuk menyeimbangkan tombol close
                    const Expanded(
                      child: Text(
                        'Informasi Logger',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow('ID Logger', point['id_logger']?.toString() ?? '-'),
                    _buildInfoRow('Seri Logger', point['informasi']?['seri_logger'] ?? '-'),
                    _buildInfoRow('Serial Number', point['informasi']?['serial_number'] ?? '-'),
                    _buildInfoRow('Sensor', point['sensor_count']?.toString() ?? '-'),
                    _buildInfoRow('Awal Kontrak', point['informasi']?['awal_kontrak'] ?? '-'),
                    _buildInfoRow('Akhir garansi', point['informasi']?['garansi'] ?? '-'),
                    _buildInfoRow('IMEI', point['informasi']?['imei'] ?? '-'),
                    _buildInfoRow('Nama PIC', point['informasi']?['nama_pic'] ?? '-'),
                    _buildInfoRow('No. PIC', point['informasi']?['no_pic'] ?? '-'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton Chips dengan background biru
        Container(
          height: 50,
          color: const Color(0xFF1E3A8A), // Background biru gelap dari header dilanjutkan
          child: Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              physics: const NeverScrollableScrollPhysics(), // Biar nggak bisa di-scroll saat loading
              child: Row(
                children: List.generate(4, (index) => Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                )),
              ),
            ),
          ),
        ),
        // Sisa layar dengan background default putih/abu
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton Date & Time
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 150, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      Container(width: 60, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
                // Skeleton Body Card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: _buildSkeletonVisualization(widget.kategori.toUpperCase()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonVisualization(String kategori) {
    if (kategori.contains('ARR')) {
      return Column(
        children: [
          Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ],
      );
    } else if (kategori.contains('AWR') || kategori.contains('AWQR')) {
      return Column(
        children: [
          Container(height: 160, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ],
      );
    } else if (kategori.contains('AWLR')) {
      // AWLR default to JIAT skeleton (Data Sumur Card + Well Animation + Health Logger)
      // karena POS pertama yang muncul biasanya adalah AWLR JIAT.
      return Column(
        children: [
          Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Container(height: 250, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ],
      );
    } else if (kategori.contains('AFMR')) {
      // AFMR: River Animation + 3 Rows of Parameters + Health Logger
      return Column(
        children: [
          Container(height: 250, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ],
      );
    } else {
      // Default: River Animation + 1 Row of Parameters + Health Logger
      return Column(
        children: [
          Container(height: 250, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ],
      );
    }
  }
}
