import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../peta/data/peta_repository.dart';
import '../widgets/pos_visualization_widget.dart';

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
        centerTitle: true,
        title: Text(
          widget.kategori.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'Informasi') {
                if (_selectedPoint != null) {
                  _showInformasiDialog(_selectedPoint!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pilih pos terlebih dahulu')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Menu $value dipilih (Belum Diimplementasikan)')),
                );
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
          height: 60,
          color: const Color(0xFF1E3A8A), // Background biru gelap dari header dilanjutkan
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _points.length,
            itemBuilder: (context, index) {
              final point = _points[index];
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569), // Warna slate text
            ),
          ),
        ),
        
        // ── Body Visualisasi Pos yang dipilih
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _selectedPoint == null 
                ? const SizedBox.shrink()
                : PosVisualizationWidget(point: _selectedPoint!),
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
}
