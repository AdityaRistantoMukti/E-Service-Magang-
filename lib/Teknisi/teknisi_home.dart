import 'dart:io';
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:e_service/models/technician_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'input_estimasi.dart';
import 'teknisi_profil.dart';
import 'tasks_tab.dart';
import 'tracking_tab.dart';
import 'chat_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart';

class TeknisiHomePage extends StatefulWidget {
  const TeknisiHomePage({super.key});

  @override
  State<TeknisiHomePage> createState() => _TeknisiHomePageState();
}

class _TeknisiHomePageState extends State<TeknisiHomePage> {
  int currentIndex = 0;
  List<TechnicianOrder> assignedOrders = [];
  List<dynamic> transaksiList = [];
  bool isLoading = true;

  // Damage form controllers
  final TextEditingController damageDescriptionController =
      TextEditingController();
  final TextEditingController estimatedPriceController =
      TextEditingController();
  List<XFile> selectedMedia = [];

  @override
  void initState() {
    super.initState();
    fetchAssignedOrders();
  }

  @override
  void dispose() {
    damageDescriptionController.dispose();
    estimatedPriceController.dispose();
    super.dispose();
  }

  Future<void> fetchAssignedOrders() async {
    setState(() => isLoading = true);

    final technicianId = await SessionManager.getkry_kode();
    if (technicianId != null) {
      try {
        final fetchedOrders = await ApiService.getkry_kode(technicianId);
        setState(() {
          assignedOrders = fetchedOrders;
        });
      } catch (e) {
        setState(() {
          assignedOrders = [];
        });
        print("Error fetching orders: $e");
      }
    } else {
      setState(() {
        assignedOrders = [];
      });
    }

    // Fetch transaksi data with status not completed for tasks
    try {
      final fetchedTransaksi = await ApiService.getTransaksi();
      setState(() {
        transaksiList = fetchedTransaksi;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        transaksiList = [];
        isLoading = false;
      });
      print("Error fetching transaksi: $e");
    }
  }

  Future<void> fetchHistoryTransaksi() async {
    setState(() => isLoading = true);

    // Fetch transaksi data with status completed for history
    try {
      final fetchedTransaksi = await ApiService.getTransaksi();
      setState(() {
        transaksiList = fetchedTransaksi;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        transaksiList = [];
        isLoading = false;
      });
      print("Error fetching transaksi: $e");
    }
  }





  Future<void> _updateOrderStatus(
    TechnicianOrder order,
    OrderStatus newStatus,
  ) async {
    // Validate status transitions
    if (!_isValidStatusTransition(order.status, newStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transisi status tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update status in database
      await ApiService.updateTransaksiStatus(order.orderId, newStatus.name);

      setState(() {
        final index = assignedOrders.indexWhere((o) => o.orderId == order.orderId);
        if (index != -1) {
          assignedOrders[index] = order.copyWith(status: newStatus);

          // Move to completed if status is completed
          if (newStatus == OrderStatus.completed) {
            // For now, just remove from assigned orders
            assignedOrders.removeAt(index);
          }
        }
      });

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diperbarui ke ${newStatus.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidStatusTransition(OrderStatus current, OrderStatus next) {
    switch (current) {
      case OrderStatus.assigned:
        return next == OrderStatus.accepted;
      case OrderStatus.accepted:
        return next == OrderStatus.enRoute;
      case OrderStatus.enRoute:
        return next == OrderStatus.arrived;
      case OrderStatus.arrived:
        return next == OrderStatus.completed ||
            next == OrderStatus.pickingParts;
      case OrderStatus.waitingApproval:
        return next == OrderStatus.pickingParts ||
            next == OrderStatus.repairing;
      case OrderStatus.pickingParts:
        return next == OrderStatus.repairing;
      case OrderStatus.repairing:
        return next == OrderStatus.completed;
      case OrderStatus.completed:
        return next == OrderStatus.delivering;
      case OrderStatus.delivering:
        return false; // Final status
    }
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka maps')));
    }
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedMedia.addAll(pickedFiles);
      });
    }
  }

  void _showDamageForm(TechnicianOrder order) {
    damageDescriptionController.clear();
    estimatedPriceController.clear();
    selectedMedia.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Temuan Kerusakan - ${order.orderId}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextField(
                        controller: damageDescriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Kerusakan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Estimated price field
                      TextField(
                        controller: estimatedPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Estimasi Harga (Rp)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Media upload
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _pickMedia();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Upload Foto/Video'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${selectedMedia.length} file(s) dipilih'),
                        ],
                      ),

                      // Media preview
                      if (selectedMedia.isNotEmpty)
                        Container(
                          height: 100,
                          margin: const EdgeInsets.only(top: 8),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedMedia.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(
                                      File(selectedMedia[index].path),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Save damage findings and update status
                                final updatedOrder = order.copyWith(
                                  damageDescription:
                                      damageDescriptionController.text,
                                  estimatedPrice: double.tryParse(
                                    estimatedPriceController.text,
                                  ),
                                  damagePhotos:
                                      selectedMedia.map((f) => f.path).toList(),
                                );

                                // Update order in state
                                setState(() {
                                  final index = assignedOrders.indexWhere(
                                    (o) => o.orderId == order.orderId,
                                  );
                                  if (index != -1) {
                                    assignedOrders[index] = updatedOrder;
                                  }
                                });

                                // Update status to waiting for approval
                                _updateOrderStatus(
                                  updatedOrder,
                                  OrderStatus.waitingApproval,
                                );

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Temuan kerusakan disimpan'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          'Dashboard Teknisi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeknisiProfilPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          TasksTab(
            assignedOrders: assignedOrders,
            transaksiList: transaksiList,
            isLoading: isLoading,
            onRefresh: fetchAssignedOrders,
            onUpdateStatus: _updateOrderStatus,
            onShowDamageForm: _showDamageForm,
            onOpenMaps: _openMaps,
            onUpdateTransaksiStatus: _updateTransaksiStatus,
          ),
          TrackingTab(
            assignedOrders: assignedOrders,
            onOpenMaps: _openMaps,
          ),
          const ChatTab(),
          HistoryTab(
            transaksiList: transaksiList,
            isLoading: isLoading,
            onRefresh: fetchHistoryTransaksi,
            onUpdateTransaksiStatus: _updateTransaksiStatus,
          ),
          const ProfileTab(),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1976D2),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(assignedOrders.length.toString()),
              child: const Icon(Icons.assignment),
            ),
            label: 'Tugas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            label: 'Pelacakan',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: const Text('2'), // Assume unread count
              child: const Icon(Icons.chat),
            ),
            label: 'Obrolan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, {bool isHistory = false}) {
    final bool isTechOrder = order is TechnicianOrder;

    final String title = isTechOrder
        ? order.orderId
        : 'Transaksi ${order['trans_kode'] ?? '-'}';

    final String statusText = isTechOrder
        ? order.status.displayName
        : (order['trans_status']?.toString() ?? '-');

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
                  title,
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
                        statusText,
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

            // Detail untuk TechnicianOrder
            if (isTechOrder) ...[
              _infoRow('Nama Pelanggan', order.customerName),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openMaps(order.customerAddress),
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
            ]
            // Detail untuk Transaksi (map/dynamic)
            else ...[
              _infoRow('Keluhan', order['ket_keluhan']?.toString() ?? 'Tidak ada keluhan'),
              const SizedBox(height: 8),
              _infoRow('Tanggal', order['trans_tanggal']?.toString() ?? 'Tidak ada tanggal'),
            ],

            if (isTechOrder && order.visitCost != null) ...[
              const SizedBox(height: 8),
              _infoRow('Biaya Kunjungan', 'Rp ${order.visitCost!.toStringAsFixed(0)}'),
            ],

            // Temuan kerusakan (jika ada)
            if (isTechOrder && order.damageDescription != null) ...[
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

            // Tombol aksi untuk TechnicianOrder (aktif)
            if (!isHistory && isTechOrder) ...[
              const SizedBox(height: 16),

              if (order.status == OrderStatus.arrived) ...[
                if (order.damageDescription == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
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
                          onPressed: () => _showDamageForm(order),
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
                          onPressed: () => _updateOrderStatus(order, OrderStatus.pickingParts),
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
                        onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
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
                        onPressed: () => _updateOrderStatus(order, OrderStatus.pickingParts),
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
                        onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
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
                      child: _buildActionButton(
                        order,
                        _getNextStatus(order.status),
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ],

            // Tombol aksi untuk Transaksi (map) – tandai selesai
            if (!isHistory && !isTechOrder) ...[
              const SizedBox(height: 12),
              if (!['completed', 'selesai', 'finished']
                  .contains((order['trans_status']?.toString() ?? '').toLowerCase())) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateTransaksiStatus(order, 'completed'),
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
          ],
        ),
      ),
    );
  }



  Future<void> _updateTransaksiStatus(dynamic transaksi, String newStatus) async {
    try {
      // Update status in database
      await ApiService.updateTransaksiStatus(transaksi['trans_kode'], newStatus);

      setState(() {
        // Update the status in the local list
        final index = transaksiList.indexWhere((t) => t['trans_kode'] == transaksi['trans_kode']);
        if (index != -1) {
          transaksiList[index]['trans_status'] = newStatus;
        }
      });

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status transaksi diperbarui ke $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update status transaksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButton(
    TechnicianOrder order,
    OrderStatus? nextStatus, {
    bool isPrimary = false,
  }) {
    if (nextStatus == null) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: () => _updateOrderStatus(order, nextStatus),
      icon: Icon(nextStatus.icon, size: 16),
      label: Text(nextStatus.displayName),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? const Color(0xFF1976D2) : Colors.grey.shade600,
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
        return null; // No next status, use buttons instead
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
}
