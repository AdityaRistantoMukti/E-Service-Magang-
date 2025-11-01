import 'package:e_service/models/technician_order_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TasksTab extends StatelessWidget {
  final List<TechnicianOrder> assignedOrders;
  final List<dynamic> transaksiList;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TechnicianOrder, OrderStatus) onUpdateStatus;
  final void Function(TechnicianOrder) onShowDamageForm;
  final Future<void> Function(String) onOpenMaps;
  final Future<void> Function(dynamic, String) onUpdateTransaksiStatus;

  const TasksTab({
    super.key,
    required this.assignedOrders,
    required this.transaksiList,
    required this.isLoading,
    required this.onRefresh,
    required this.onUpdateStatus,
    required this.onShowDamageForm,
    required this.onOpenMaps,
    required this.onUpdateTransaksiStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Filter transaksi that are not completed
    final filteredTransaksi = transaksiList.where((transaksi) {
      final status = transaksi['trans_status']?.toString().toLowerCase() ?? '';
      return status != 'completed' && status != 'selesai' && status != 'finished';
    }).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : assignedOrders.isEmpty && filteredTransaksi.isEmpty
          ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada pesanan aktif',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
          : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignedOrders.length + filteredTransaksi.length,
            itemBuilder: (context, index) {
              if (index < assignedOrders.length) {
                final order = assignedOrders[index];
                return _buildOrderCard(context, order);
              } else {
                final transaksiIndex = index - assignedOrders.length;
                final transaksi = filteredTransaksi[transaksiIndex];
                return _buildTransaksiCard(context, transaksi);
              }
            },
          ),
    );
  }

  Widget _buildOrderCard(BuildContext context, TechnicianOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderId,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        order.status.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _infoRow('Nama Pelanggan', order.customerName),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOpenMaps(order.customerAddress),
                    child: Text(
                      order.customerAddress,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow('Perangkat', '${order.deviceBrand} ${order.deviceType}'),
            const SizedBox(height: 8),
            _infoRow('Serial', order.deviceSerial),

            if (order.visitCost != null) ...[
              const SizedBox(height: 8),
              _infoRow('Biaya Kunjungan', 'Rp ${order.visitCost!.toStringAsFixed(0)}'),
            ],

            // Temuan kerusakan (jika ada)
            if (order.damageDescription != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temuan Kerusakan:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.damageDescription!,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    if (order.estimatedPrice != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Estimasi: Rp ${order.estimatedPrice!.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Tombol aksi
            const SizedBox(height: 16),

            if (order.status == OrderStatus.arrived) ...[
              if (order.damageDescription == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onUpdateStatus(order, OrderStatus.completed),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Service Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onShowDamageForm(order),
                        icon: const Icon(Icons.report_problem, size: 16),
                        label: const Text('Temuan Kerusakan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onUpdateStatus(order, OrderStatus.pickingParts),
                        icon: const Icon(Icons.build, size: 16),
                        label: const Text('Ambil Part'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (order.status == OrderStatus.pickingParts) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onUpdateStatus(order, OrderStatus.completed),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Service Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.waitingApproval) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onUpdateStatus(order, OrderStatus.pickingParts),
                      icon: const Icon(Icons.build, size: 16),
                      label: const Text('Ambil Part'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.repairing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onUpdateStatus(order, OrderStatus.completed),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Service Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(order),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(TechnicianOrder order) {
    final nextStatus = _getNextStatus(order.status);
    if (nextStatus == null) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: () => onUpdateStatus(order, nextStatus),
      icon: Icon(nextStatus.icon, size: 16),
      label: Text(nextStatus.displayName),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        textStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }

  OrderStatus? _getNextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.assigned:
        return OrderStatus.accepted;
      case OrderStatus.accepted:
        return OrderStatus.enRoute;
      case OrderStatus.enRoute:
        return OrderStatus.arrived;
      case OrderStatus.arrived:
        return null;
      case OrderStatus.waitingApproval:
        return OrderStatus.pickingParts;
      case OrderStatus.pickingParts:
        return OrderStatus.repairing;
      case OrderStatus.repairing:
        return OrderStatus.completed;
      case OrderStatus.completed:
        return OrderStatus.delivering;
      case OrderStatus.delivering:
        return null;
    }
  }

  Widget _buildTransaksiCard(BuildContext context, dynamic transaksi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaksi['trans_kode'] ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaksi['trans_status'] ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaksi['trans_status'] ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _getStatusColor(transaksi['trans_status'] ?? ''),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transaction Details
            _infoRow('Tanggal', transaksi['trans_tanggal'] ?? 'N/A'),
            const SizedBox(height: 8),
            _infoRow('Total', 'Rp ${transaksi['trans_total']?.toString() ?? '0'}'),
            const SizedBox(height: 8),
            _infoRow('Metode Pembayaran', transaksi['trans_metode'] ?? 'N/A'),

            // Customer Info if available
            if (transaksi['cos_nama'] != null) ...[
              const SizedBox(height: 8),
              _infoRow('Pelanggan', transaksi['cos_nama']),
            ],

            // Service Type if available
            if (transaksi['service_type'] != null) ...[
              const SizedBox(height: 8),
              _infoRow('Jenis Layanan', transaksi['service_type']),
            ],

            // Tombol aksi untuk Transaksi
            const SizedBox(height: 12),
            if (!['completed', 'selesai', 'finished']
                .contains((transaksi['trans_status']?.toString() ?? '').toLowerCase())) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onUpdateTransaksiStatus(transaksi, 'completed'),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Tandai Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 14))),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
