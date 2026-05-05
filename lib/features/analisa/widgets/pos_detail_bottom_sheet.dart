import 'package:flutter/material.dart';
import 'pos_visualization_widget.dart';

class PosDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> point;

  const PosDetailBottomSheet({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    final namaLogger = point['nama_logger'] ?? 'Pos Tidak Diketahui';
    final namaLokasi = point['nama_lokasi'] ?? '-';
    final status = point['status']?.toString() ?? 'offline';
    final isOnline = status == 'online';
    final kategori = (point['kategori'] ?? '').toString().toUpperCase();
    final subKategori = point['sub_kategori']?.toString();
    final sensorData = (point['sensor_data'] as Map<String, dynamic>?) ?? {};
    final jiatData = point['jiat_data'] as Map<String, dynamic>?;
    final nonjiatData = point['nonjiat_data'] as Map<String, dynamic>?;
    final loggerHealth = (point['logger_health'] as Map<String, dynamic>?) ?? {};

    final statusColor = isOnline ? Colors.green.shade600 : Colors.grey.shade500;
    final statusBg = isOnline ? Colors.green.shade50 : Colors.grey.shade100;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaLogger,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              namaLokasi,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, indent: 20, endIndent: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20, 
                0, 
                20, 
                MediaQuery.of(context).padding.bottom > 0 
                    ? MediaQuery.of(context).padding.bottom + 24 
                    : 48
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gunakan widget yang sudah direfactor
                  PosVisualizationWidget(point: point),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
