import 'dart:io';
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/models/technician_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'input_estimasi.dart';
import 'teknisi_profil.dart';

class TeknisiHomePage extends StatefulWidget {
  const TeknisiHomePage({super.key});

  @override
  State<TeknisiHomePage> createState() => _TeknisiHomePageState();
}

class _TeknisiHomePageState extends State<TeknisiHomePage> {
  int currentIndex = 0;
  List<TechnicianOrder> activeOrders = [];
  List<TechnicianOrder> completedOrders = [];
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
    _loadOrders();
  }

  @override
  void dispose() {
    damageDescriptionController.dispose();
    estimatedPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);

    // Load from SharedPreferences (in real app, this would be from API)
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Sample data for demonstration
    activeOrders = [
      TechnicianOrder(
        orderId: 'TTS001-REP',
        customerName: 'John Doe',
        customerAddress: 'Jl. Sudirman No. 123, Jakarta',
        deviceType: 'Laptop',
        deviceBrand: 'Asus',
        deviceSerial: 'ASUS123456',
        serviceType: 'Repair',
        status: OrderStatus.enRoute,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        visitCost: 50000,
        customerPhone: '+6281234567890',
      ),
      TechnicianOrder(
        orderId: 'TTS002-CLEAN',
        customerName: 'Jane Smith',
        customerAddress: 'Jl. Thamrin No. 456, Jakarta',
        deviceType: 'Desktop',
        deviceBrand: 'Dell',
        deviceSerial: 'DELL789012',
        serviceType: 'Cleaning',
        status: OrderStatus.arrived,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        visitCost: 30000,
      ),
    ];

    completedOrders = [
      TechnicianOrder(
        orderId: 'TTS003-REP',
        customerName: 'Bob Wilson',
        customerAddress: 'Jl. Gatot Subroto No. 789, Jakarta',
        deviceType: 'Laptop',
        deviceBrand: 'HP',
        deviceSerial: 'HP345678',
        serviceType: 'Repair',
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        visitCost: 75000,
        damageDescription: 'Replaced faulty RAM module',
        estimatedPrice: 150000,
      ),
    ];

    setState(() => isLoading = false);
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

    setState(() {
      final index = activeOrders.indexWhere((o) => o.orderId == order.orderId);
      if (index != -1) {
        activeOrders[index] = order.copyWith(status: newStatus);

        // Move to completed if status is completed
        if (newStatus == OrderStatus.completed) {
          completedOrders.add(activeOrders[index]);
          activeOrders.removeAt(index);
        }
      }
    });

    // Save to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('${order.orderId}_status', newStatus.name);

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status diperbarui ke ${newStatus.displayName}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  bool _isValidStatusTransition(OrderStatus current, OrderStatus next) {
    switch (current) {
      case OrderStatus.enRoute:
        return next == OrderStatus.arrived;
      case OrderStatus.arrived:
        return next == OrderStatus.waitingApproval ||
            next == OrderStatus.pickingParts ||
            next == OrderStatus.repairing;
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
                                // Save damage findings
                                final updatedOrder = order.copyWith(
                                  damageDescription:
                                      damageDescriptionController.text,
                                  estimatedPrice: double.tryParse(
                                    estimatedPriceController.text,
                                  ),
                                  damagePhotos:
                                      selectedMedia.map((f) => f.path).toList(),
                                );

                                setState(() {
                                  final index = activeOrders.indexWhere(
                                    (o) => o.orderId == order.orderId,
                                  );
                                  if (index != -1) {
                                    activeOrders[index] = updatedOrder;
                                  }
                                });

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
          _buildTasksTab(),
          _buildTrackingTab(),
          _buildChatTab(),
          _buildHistoryTab(),
          _buildProfileTab(),
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
              label: Text(activeOrders.length.toString()),
              child: const Icon(Icons.assignment),
            ),
            label: 'Tasks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: const Text('2'), // Assume unread count
              child: const Icon(Icons.chat),
            ),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(TechnicianOrder order, {bool isHistory = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.status.icon,
                        size: 16,
                        color: order.status.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.status.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: order.status.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Info
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

            if (order.visitCost != null) ...[
              const SizedBox(height: 8),
              _infoRow(
                'Biaya Kunjungan',
                'Rp ${order.visitCost!.toStringAsFixed(0)}',
              ),
            ],

            // Damage findings (if any)
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

            // Action buttons (only for active orders)
            if (!isHistory) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Quick status actions
                  Expanded(
                    child: _buildActionButton(
                      order,
                      _getNextStatus(order.status),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Damage form button (for certain statuses)
                  if (order.status == OrderStatus.arrived ||
                      order.status == OrderStatus.repairing)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDamageForm(order),
                        icon: const Icon(Icons.report_problem, size: 16),
                        label: const Text('Temuan'),
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
            ],
          ],
        ),
      ),
    );
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
      case OrderStatus.enRoute:
        return OrderStatus.arrived;
      case OrderStatus.arrived:
        return OrderStatus.waitingApproval;
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

  Widget _buildTasksTab() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeOrders.isEmpty
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
                itemCount: activeOrders.length,
                itemBuilder: (context, index) {
                  final order = activeOrders[index];
                  return Dismissible(
                    key: Key(order.orderId),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      color: Colors.green,
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.cancel, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        // Cancel action
                        return false;
                      } else {
                        // Update status
                        final nextStatus = _getNextStatus(order.status);
                        if (nextStatus != null) {
                          await _updateOrderStatus(order, nextStatus);
                          HapticFeedback.lightImpact();
                        }
                        return false; // Don't dismiss, just update
                      }
                    },
                    child: _buildOrderCard(order),
                  );
                },
              ),
    );
  }

  Widget _buildTrackingTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.navigation, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tracking & Navigation',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Map view and route to customer location',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Open maps with first active order if available
              if (activeOrders.isNotEmpty) {
                _openMaps(activeOrders.first.customerAddress);
              }
            },
            icon: const Icon(Icons.map),
            label: const Text('Open Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Communication / Chat',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact customer or admin',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to chat page (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming soon')),
              );
            },
            icon: const Icon(Icons.message),
            label: const Text('Start Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return completedOrders.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No completed jobs',
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
          itemCount: completedOrders.length,
          itemBuilder: (context, index) {
            final order = completedOrders[index];
            return _buildOrderCard(order, isHistory: true);
          },
        );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Technician Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Profile settings and availability',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Toggle availability (placeholder)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Availability toggled')),
                  );
                },
                icon: const Icon(Icons.online_prediction),
                label: const Text('Online'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeknisiProfilPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
