import 'package:e_service/models/technician_order_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrackingTab extends StatelessWidget {
  final List<TechnicianOrder> assignedOrders;
  final Future<void> Function(String) onOpenMaps;

  const TrackingTab({
    super.key,
    required this.assignedOrders,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.navigation, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Pelacakan & Navigasi',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tampilan peta dan rute ke lokasi pelanggan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Open maps with first active order if available
              if (assignedOrders.isNotEmpty) {
                onOpenMaps(assignedOrders.first.customerAddress);
              }
            },
            icon: const Icon(Icons.map),
            label: const Text('Buka Peta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
