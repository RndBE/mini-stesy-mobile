import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_svg/flutter_svg.dart';
import '../data/peta_repository.dart';
import '../../analisa/screens/detail_analisa_screen.dart';

class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> with TickerProviderStateMixin {
  final PetaRepository _petaRepo = PetaRepository();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _isFirstLoad = true; // Tambahan untuk membedakan load pertama
  List<dynamic> _points = [];
  bool _isSatellite = false;
  Map<String, dynamic>? _selectedPointPopup;
  bool _isSearching = false;
  bool _isFilterOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  Set<String> _selectedCategories = {};
  List<String> _availableCategories = [];
  
  // Posisi awal peta (default Banten, tapi akan langsung diubah sebelum peta di-render)
  LatLng _defaultCenter = const LatLng(-6.12, 106.15);
  double _currentZoom = 10.0;

  List<dynamic> get _filteredPoints {
    var filtered = _points.where((p) {
      final kat = p['kategori']?.toString() ?? 'Unknown';
      return _selectedCategories.contains(kat);
    }).toList();

    if (_isSearching && _searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        final namaLokasi = (p['nama_lokasi']?.toString() ?? p['nama_logger']?.toString() ?? '').toLowerCase();
        return namaLokasi.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchPoints();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Buat animasi smooth menggunakan Tween
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    // Hitung jarak zoom untuk menyesuaikan durasi (agar tidak terlalu cepat jika jaraknya jauh)
    final zoomDiff = (destZoom - _mapController.camera.zoom).abs();
    final int durationMs = (400 + (zoomDiff * 150)).clamp(400, 1000).toInt();

    final controller = AnimationController(duration: Duration(milliseconds: durationMs), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _fetchPoints() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final points = await _petaRepo.getPetaPoints();
      if (mounted) {
        LatLng? targetLatLng;
        if (points.isNotEmpty) {
          final firstPoint = points.first;
          if (firstPoint['lat'] != null && firstPoint['lng'] != null) {
            targetLatLng = LatLng(firstPoint['lat'] as double, firstPoint['lng'] as double);
          }
        }

        setState(() {
          _points = points;
          _isLoading = false;
          
          _availableCategories = _points
              .map((p) => p['kategori']?.toString() ?? 'Unknown')
              .toSet()
              .toList()
            ..sort();
          
          if (_isFirstLoad) {
            _selectedCategories = Set.from(_availableCategories);
            
            // Pada load pertama, update koordinat awal sebelum peta di-build
            if (targetLatLng != null) {
              _defaultCenter = targetLatLng;
            }
            _isFirstLoad = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat peta: $e')),
        );
      }
    }
  }

  void _zoomIn() {
    final newZoom = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
    _animatedMapMove(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final newZoom = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
    _animatedMapMove(_mapController.camera.center, newZoom);
  }

  Color _getMarkerColor(Map<String, dynamic> point) {
    final status = point['status']?.toString() ?? 'offline';
    final state = point['arr_state']?.toString() ?? '';
    
    if (status == 'offline' || state == 'koneksi_terputus') {
      return Colors.black87;
    }
    
    if (state.contains('aman') || state.contains('tidak_hujan')) {
      return Colors.green.shade600;
    } else if (state.contains('waspada') || state.contains('ringan')) {
      return Colors.orange;
    } else if (state.contains('siaga') || state.contains('awas') || state.contains('lebat')) {
      return Colors.red.shade600;
    }
    
    return Colors.blue.shade700; // Default color
  }

  IconData _getMarkerIcon(String kategori) {
    final kat = kategori.toUpperCase();
    if (kat.contains('AWLR')) {
      return Icons.waves_rounded;
    } else if (kat.contains('ARR')) {
      return Icons.cloudy_snowing;
    } else if (kat.contains('KLIMAT')) {
      return Icons.thermostat;
    }
    return Icons.location_on;
  }

  String _getKategoriIconAsset(String kategori) {
    final kat = kategori.toLowerCase();
    if (kat.contains('awlr')) return 'assets/images/awlr/ikon_awlr.svg';
    if (kat.contains('arr')) return 'assets/images/arr/ikon_arr.svg';
    if (kat.contains('awr')) return 'assets/images/awr/ikon_awr.svg';
    if (kat.contains('afmr')) return 'assets/images/afmr/ikon_afmr.svg';
    if (kat.contains('awqr')) return 'assets/images/awqr/ikon_awqr.svg';
    // Fallback default
    return 'assets/images/awlr/ikon_awlr.svg';
  }

  String _getMarkerAssetPath(Map<String, dynamic> point) {
    final status = point['status']?.toString().toLowerCase() ?? 'offline';
    final kondisi = point['kondisi']?.toString().toLowerCase() ?? '';
    final kategori = (point['kategori']?.toString() ?? '').toLowerCase();
    
    // Tentukan folder berdasarkan kategori
    String folder = 'awlr';
    if (kategori.contains('arr')) {
      folder = 'arr';
    } else if (kategori.contains('awr')) {
      folder = 'awr';
    } else if (kategori.contains('afmr')) {
      folder = 'afmr';
    } else if (kategori.contains('awqr')) {
      folder = 'awqr';
    }

    // Perbaikan / Maintenance check
    if (status == 'perbaikan' || kondisi == 'perbaikan') {
       return 'assets/images/$folder/perbaikan.svg';
    }

    // Offline check
    if (status == 'offline') {
       if (folder == 'arr') {
         return 'assets/images/arr/koneksi_terputus.svg';
       }
       return 'assets/images/$folder/offline.svg';
    }

    // Online check
    if (folder == 'arr') {
      final state = point['arr_state']?.toString().toLowerCase() ?? '';
      if (state.contains('sangat lebat') || state.contains('sangat_lebat')) return 'assets/images/arr/hujan_sangat_lebat.svg';
      if (state.contains('lebat')) return 'assets/images/arr/hujan_lebat.svg';
      if (state.contains('sedang')) return 'assets/images/arr/hujan_sedang.svg';
      if (state.contains('sangat ringan') || state.contains('sangat_ringan')) return 'assets/images/arr/hujan_sangat_ringan.svg';
      if (state.contains('ringan')) return 'assets/images/arr/hujan_ringan.svg';
      return 'assets/images/arr/tidak_hujan.svg';
    }
    
    return 'assets/images/$folder/online.svg';
  }

  @override
  Widget build(BuildContext context) {
    // URL Tile Provider (menggunakan {s} untuk parallel loading)
    final String mapTileUrl = _isSatellite
        ? 'https://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}' // Google Satellite
        : 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'; // Google Maps Standard (Roadmap)

    return Scaffold(
      body: Stack(
        children: [
          // 1. Layer Peta
          if (_isFirstLoad)
            const SizedBox.expand(
              child: ColoredBox(color: Color(0xFFF0F4F8)), // Warna latar sebelum peta muncul
            )
          else
            FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _currentZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, point) {
                if (_selectedPointPopup != null) {
                  setState(() => _selectedPointPopup = null);
                }
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _currentZoom = position.zoom;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: mapTileUrl,
                userAgentPackageName: 'com.ministesy.app',
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'], // Parallel loading
                panBuffer: 1, // Preload 1 tile luar layar
                keepBuffer: 3, // Kurangi keepBuffer agar memori tidak penuh
                maxZoom: 20, // Batas zoom Google Maps
                tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 250)),
              ),
              MarkerLayer(
                markers: _filteredPoints.map((p) {
                  final lat = p['lat'] as double?;
                  final lng = p['lng'] as double?;
                  if (lat == null || lng == null) return null;

                  final color = _getMarkerColor(p);
                  final kategori = p['kategori']?.toString() ?? '';
                  final icon = _getMarkerIcon(kategori);

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 46, // Diperkecil dari sebelumnya 50x56
                    alignment: Alignment.topCenter,
                    child: RepaintBoundary(
                      child: GestureDetector(
                        onTap: () {
                          _showPointInfo(p);
                        },
                        child: OverflowBox(
                          maxWidth: 250,
                          maxHeight: 150,
                          alignment: Alignment.bottomCenter,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Pin / Marker Asli dari Asset SVG
                              SvgPicture.asset(
                                _getMarkerAssetPath(p),
                                width: 36,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                              // Label Popup (hanya jika terpilih) melayang di atas marker
                              if (_selectedPointPopup == p)
                                Positioned(
                                  bottom: 56, // Melayang di atas lingkaran icon
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    child: Text(
                                      p['nama_lokasi']?.toString() ?? p['nama_logger']?.toString() ?? 'Pos Unknown',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),
            ],
          ),

          // 2. Custom Top AppBar (Melayang) & Dropdown Pencarian
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3192), // Warna header biru kustom
                    boxShadow: [
                      if (!_isSearching || _searchController.text.isEmpty)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: _isSearching
                      ? Row(
                          children: [
                            const Icon(Icons.search, color: Colors.white, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
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
                                  filled: false, // Memaksa background transparan, menimpa tema global
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() {}); // Filter berjalan realtime
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                });
                              },
                              child: const Icon(Icons.close, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _fetchPoints,
                              child: const Icon(Icons.refresh, color: Colors.white, size: 22),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            ),
                            const Expanded(
                              child: Text(
                                'Peta Lokasi Pos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearching = true;
                                });
                                // Request focus to ensure keyboard pops up immediately
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  _searchFocusNode.requestFocus();
                                });
                              },
                              child: const Icon(Icons.search, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _fetchPoints,
                              child: const Icon(Icons.refresh, color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                ),
                
                // Dropdown List Hasil Pencarian
                if (_isSearching && _searchController.text.isNotEmpty && _filteredPoints.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredPoints.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, index) {
                        final p = _filteredPoints[index];
                        final namaLokasi = p['nama_lokasi']?.toString() ?? p['nama_logger']?.toString() ?? 'Pos Unknown';
                        return ListTile(
                          title: Text(namaLokasi, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                            });
                            _showPointInfo(p);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Floating Filter Popup (Kiri Atas)
          if (_isFilterOpen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64, // Didekatkan ke header (sebelumnya +90)
              left: 16,
              right: 16, // Biarkan melebar ke kanan
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.only(bottom: 16), // Agar shadow tidak terpotong
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _availableCategories.map((kategori) {
                    final isSelected = _selectedCategories.contains(kategori);
                    return Container(
                      width: 160, // Lebar fixed untuk tiap card kategori
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Card: Icon, Title, Checkbox
                          Row(
                            children: [
                              // Icon Kategori
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: SvgPicture.asset(
                                  _getKategoriIconAsset(kategori),
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(Color(0xFF2E3192), BlendMode.srcIn),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  kategori.isNotEmpty ? kategori : 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              // Checkbox kustom bentuk rounded square biru
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedCategories.remove(kategori);
                                    } else {
                                      _selectedCategories.add(kategori);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2E3192) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2E3192) : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Legend Terhubung
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 6),
                              const Text('Terhubung', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Legend Terputus
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 6),
                              const Text('Terputus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 3. Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Popup Card di tengah bawah
          if (_selectedPointPopup != null) _buildPopupCard(),



          // 4. Zoom Controls (Kanan Bawah)
          Positioned(
            bottom: 32,
            right: 16,
            child: Container(
              width: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _zoomIn,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: const SizedBox(
                      width: 38,
                      height: 40,
                      child: Icon(Icons.add, color: Colors.black87, size: 22),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  InkWell(
                    onTap: _zoomOut,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    child: const SizedBox(
                      width: 38,
                      height: 40,
                      child: Icon(Icons.remove, color: Colors.black87, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Tombol Filter & Toggle Layer Satelit (Kiri Bawah)
          Positioned(
            bottom: 32,
            left: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Tombol Filter
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFilterOpen = !_isFilterOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isFilterOpen ? const Color(0xFF2E3192) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.tune, color: _isFilterOpen ? Colors.white : const Color(0xFF2E3192), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle Layer Satelit
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Peta Biasa
                  GestureDetector(
                    onTap: () => setState(() => _isSatellite = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isSatellite ? const Color(0xFF2E3192) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Peta',
                        style: TextStyle(
                          color: !_isSatellite ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Tombol Satelit
                  GestureDetector(
                    onTap: () => setState(() => _isSatellite = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isSatellite ? const Color(0xFF2E3192) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Satelit',
                        style: TextStyle(
                          color: _isSatellite ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupCard() {
    if (_selectedPointPopup == null) return const SizedBox.shrink();

    final p = _selectedPointPopup!;
    final namaLokasi = p['nama_lokasi']?.toString() ?? p['nama_logger']?.toString() ?? 'Pos Unknown';
    final lastUpdate = p['last_time']?.toString() ?? '-';
    final status = p['status']?.toString() ?? 'offline';
    final isOnline = status == 'online';
    final statusText = isOnline ? 'Koneksi Terhubung' : 'Koneksi Terputus';
    final statusColor = isOnline ? Colors.green.shade600 : Colors.red.shade600;

    return Positioned(
      bottom: 130, // Dinaikkan agar tidak tertutup tombol zoom
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              namaLokasi,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Waktu', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                Text(lastUpdate, style: const TextStyle(color: Colors.black87, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3192),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  _openPointDetail(p);
                },
                child: const Text('Lihat Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPointInfo(Map<String, dynamic> p) {
    setState(() {
      _selectedPointPopup = p;
    });
    
    final lat = p['lat'] as double?;
    final lng = p['lng'] as double?;
    
    if (lat != null && lng != null) {
      final markerLatLng = LatLng(lat, lng);
      
      // Tentukan target zoom: agak zoom in ke level 14 jika masih terlalu jauh dari peta
      final targetZoom = math.max(_currentZoom, 14.0);
      
      // Hitung offset latitude berdasarkan level zoom target
      // Semakin besar zoom (makin dekat), semakin kecil offset derajatnya
      final zoomDiff = 14.0 - targetZoom;
      final latOffset = 0.005 * math.pow(2, zoomDiff);
      
      // Kurangi latitude agar kamera berpusat sedikit ke selatan dari marker, 
      // sehingga secara visual letak marker di layar akan naik menjauhi popup card.
      final destLatLng = LatLng(markerLatLng.latitude - latOffset, markerLatLng.longitude);
      
      // Pindahkan peta ke target offset tersebut dengan animasi panning dan zooming!
      _animatedMapMove(destLatLng, targetZoom);
    }
  }

  void _openPointDetail(Map<String, dynamic> p) {
    final idLogger = p['id_logger']?.toString() ?? '';
    final status = p['status']?.toString() ?? 'offline';
    final isOnline = status == 'online';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailAnalisaScreen(
          idLogger: idLogger,
          namaPos: p['nama_lokasi']?.toString() ?? p['nama']?.toString(),
          namaLogger: p['nama_logger']?.toString(),
          parameterName: '', // Kosong agar otomatis memilih parameter pertama di layar detail
          isOnline: isOnline,
        ),
      ),
    );
  }
}
