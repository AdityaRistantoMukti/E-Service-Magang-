import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import your existing files
import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Home/Home.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/Service.dart';
import 'package:azza_service/Service/tracking_driver.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/api_services/payment_service.dart';
import 'package:azza_service/Others/midtrans_webview.dart';

class RiwayatPage extends StatefulWidget {
  final bool shouldRefresh;

  const RiwayatPage({
    super.key,
    this.shouldRefresh = false,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with SingleTickerProviderStateMixin {
  // Navigation
  int currentIndex = 4;
  
  // Tab Controller for Service/Purchase toggle
  late TabController _mainTabController;
  int _selectedMainTab = 0; // 0 = Service, 1 = Purchase
  
  // Selected status filter
  String? _selectedServiceStatus;
  String? _selectedPurchaseStatus;
  
  // Transaction data
  List<Map<String, dynamic>> serviceTransactions = [];
  List<Map<String, dynamic>> purchaseTransactions = [];
  
  bool isLoading = true;

  // Status definitions
  final List<String> serviceStatuses = ['pending', 'approved', 'in_progress', 'on_the_way', 'completed'];
  final List<String> purchaseStatuses = ['pending', 'paid', 'diproses', 'dikirim', 'selesai'];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) {
        setState(() {
          _selectedMainTab = _mainTabController.index;
        });
      }
    });
    
    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  // ============ DATA LOADING ============
  
  Future<void> _loadTransactionHistory() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final session = await SessionManager.getUserSession();
      if (session == null) {
        _setEmptyState();
        return;
      }

      final userCosKode = session['id']?.toString();
      if (userCosKode == null || userCosKode.isEmpty) {
        _setEmptyState();
        return;
      }

      // Fetch service transactions
      final serviceData = await ApiService.getOrderList();
      
      // Fetch purchase transactions
      final purchaseData = await ApiService.getCustomerOrders(userCosKode);

      if (!mounted) return;

      // Process service transactions
      final tempService = <Map<String, dynamic>>[];
      for (final transaksi in serviceData) {
        final transCosKode = transaksi['cos_kode']?.toString();
        if (transCosKode == userCosKode) {
          tempService.add(Map<String, dynamic>.from(transaksi));
        }
      }

      // Process purchase transactions
      final tempPurchase = <Map<String, dynamic>>[];
      for (final orderData in purchaseData) {
        final order = orderData['order'];
        if (order == null) continue;

        final orderCode = order['order_code']?.toString();
        if (orderCode == null || orderCode.isEmpty) continue;

        tempPurchase.add({
          'order_code': orderCode,
          'total_price': order['total_price'] ?? 0,
          'total_payment': order['total_payment'] ?? order['total_price'] ?? 0,
          'shipping_cost': order['shipping_cost'] ?? 0,
          'created_at': order['created_at'],
          'payment_status': order['payment_status']?.toString().toLowerCase() ?? 'pending',
          'delivery_status': order['delivery_status']?.toString().toLowerCase() ?? 'menunggu',
          'payment_method': order['payment_method'] ?? 'N/A',
          'expedition_type': order['expedition_type'] ?? 'N/A',
          'delivery_address': order['delivery_address'] ?? '',
          'is_point_exchange': order['is_point_exchange'] == true || order['is_point_exchange'] == 1,
          'points_used': order['points_used'] ?? 0,
          'midtrans_redirect_url': order['midtrans_redirect_url'],
          'payment_url_expires_at': order['payment_url_expires_at'],
          'items': orderData['items'] ?? [],
        });
      }

      // Sort by date (newest first)
      tempService.sort((a, b) => _compareDate(b['trans_tanggal'], a['trans_tanggal']));
      tempPurchase.sort((a, b) => _compareDate(b['created_at'], a['created_at']));

      setState(() {
        serviceTransactions = tempService;
        purchaseTransactions = tempPurchase;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) _setEmptyState();
    }
  }

  void _setEmptyState() {
    setState(() {
      serviceTransactions = [];
      purchaseTransactions = [];
      isLoading = false;
    });
  }

  int _compareDate(String? a, String? b) {
    final dateA = DateTime.tryParse(a ?? '') ?? DateTime(1900);
    final dateB = DateTime.tryParse(b ?? '') ?? DateTime(1900);
    return dateA.compareTo(dateB);
  }

  // ============ HELPER METHODS ============

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic amount) {
    try {
      final number = double.tryParse(amount?.toString() ?? '0') ?? 0;
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(number);
    } catch (e) {
      return 'Rp 0';
    }
  }

  String _getStatusLabel(String status) {
    final labels = {
      'pending': 'Menunggu',
      'approved': 'Disetujui',
      'in_progress': 'Diproses',
      'on_the_way': 'Dalam Perjalanan',
      'completed': 'Selesai',
      'paid': 'Dibayar',
      'diproses': 'Diproses',
      'dikirim': 'Dikirim',
      'selesai': 'Selesai',
      'menunggu': 'Menunggu',
      'cancelled': 'Dibatalkan',
      'expired': 'Kadaluarsa',
    };
    return labels[status.toLowerCase()] ?? status;
  }

  Color _getStatusColor(String status) {
    final colors = {
      'pending': Colors.orange,
      'approved': Colors.blue,
      'in_progress': Colors.indigo,
      'on_the_way': Colors.purple,
      'completed': Colors.green,
      'paid': Colors.green,
      'diproses': Colors.blue,
      'dikirim': Colors.purple,
      'selesai': Colors.green,
      'menunggu': Colors.orange,
      'cancelled': Colors.red,
      'expired': Colors.grey,
    };
    return colors[status.toLowerCase()] ?? Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    final icons = {
      'pending': Icons.hourglass_empty,
      'approved': Icons.thumb_up_outlined,
      'in_progress': Icons.engineering,
      'on_the_way': Icons.local_shipping,
      'completed': Icons.check_circle,
      'paid': Icons.payment,
      'diproses': Icons.inventory,
      'dikirim': Icons.local_shipping,
      'selesai': Icons.check_circle,
      'menunggu': Icons.hourglass_empty,
      'cancelled': Icons.cancel,
      'expired': Icons.timer_off,
    };
    return icons[status.toLowerCase()] ?? Icons.help_outline;
  }

  // ✅ Check if payment URL is still valid
  bool _isPaymentUrlValid(String? expiresAt) {
    if (expiresAt == null || expiresAt.isEmpty) return false;
    try {
      final expiry = DateTime.parse(expiresAt);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  // ✅ Get expiry text
  String _getExpiryText(String? expiresAt) {
    if (expiresAt == null) return '';
    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      
      if (now.isAfter(expiry)) {
        return '⚠️ Link pembayaran expired';
      }
      
      final diff = expiry.difference(now);
      if (diff.inHours > 0) {
        return '⏰ Bayar dalam ${diff.inHours}j ${diff.inMinutes % 60}m';
      } else if (diff.inMinutes > 0) {
        return '⏰ Bayar dalam ${diff.inMinutes} menit';
      } else {
        return '⚠️ Segera expired!';
      }
    } catch (e) {
      return '';
    }
  }

  // ============ COUNT METHODS ============

  int _getServiceCountByStatus(String status) {
    return serviceTransactions.where((t) {
      final transStatus = t['trans_status']?.toString().toLowerCase() ?? '';
      return transStatus == status.toLowerCase();
    }).length;
  }

  int _getPurchaseCountByStatus(String status) {
    return purchaseTransactions.where((t) {
      final paymentStatus = t['payment_status']?.toString().toLowerCase() ?? '';
      final deliveryStatus = t['delivery_status']?.toString().toLowerCase() ?? '';
      
      if (status == 'pending') {
        return paymentStatus == 'pending';
      } else if (status == 'paid') {
        return paymentStatus == 'paid' && deliveryStatus != 'selesai' && deliveryStatus != 'dikirim';
      } else if (status == 'diproses') {
        return deliveryStatus == 'diproses';
      } else if (status == 'dikirim') {
        return deliveryStatus == 'dikirim';
      } else if (status == 'selesai') {
        return deliveryStatus == 'selesai';
      }
      return false;
    }).length;
  }

  List<Map<String, dynamic>> _getFilteredServiceTransactions() {
    if (_selectedServiceStatus == null) return [];
    return serviceTransactions.where((t) {
      final status = t['trans_status']?.toString().toLowerCase() ?? '';
      return status == _selectedServiceStatus!.toLowerCase();
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredPurchaseTransactions() {
    if (_selectedPurchaseStatus == null) return [];
    return purchaseTransactions.where((t) {
      final paymentStatus = t['payment_status']?.toString().toLowerCase() ?? '';
      final deliveryStatus = t['delivery_status']?.toString().toLowerCase() ?? '';
      
      if (_selectedPurchaseStatus == 'pending') {
        return paymentStatus == 'pending';
      } else if (_selectedPurchaseStatus == 'paid') {
        return paymentStatus == 'paid' && deliveryStatus != 'selesai' && deliveryStatus != 'dikirim';
      } else if (_selectedPurchaseStatus == 'diproses') {
        return deliveryStatus == 'diproses';
      } else if (_selectedPurchaseStatus == 'dikirim') {
        return deliveryStatus == 'dikirim';
      } else if (_selectedPurchaseStatus == 'selesai') {
        return deliveryStatus == 'selesai';
      }
      return false;
    }).toList();
  }

  // ============ PAYMENT HANDLING ============

  Future<void> _handleContinuePayment(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    final orderCode = transaction['order_code']?.toString() ?? '';
    final midtransUrl = transaction['midtrans_redirect_url']?.toString();
    final expiresAt = transaction['payment_url_expires_at']?.toString();
    final shippingCost = double.tryParse(transaction['shipping_cost']?.toString() ?? '0') ?? 0;
    final isPointExchange = transaction['is_point_exchange'] == true;
    final pointsUsed = int.tryParse(transaction['points_used']?.toString() ?? '0') ?? 0;
    
    final bool hasValidUrl = midtransUrl != null && 
        midtransUrl.isNotEmpty && 
        _isPaymentUrlValid(expiresAt);

    debugPrint('💳 Continue payment for order: $orderCode');
    debugPrint('🔗 Existing URL: $midtransUrl');
    debugPrint('✅ URL Valid: $hasValidUrl');
    debugPrint('🎯 Is Point Exchange: $isPointExchange');

    if (hasValidUrl) {
      // ✅ Use existing Midtrans URL
      debugPrint('🔓 Opening existing Midtrans URL...');
      
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => MidtransWebView(
          redirectUrl: midtransUrl!,
          orderId: orderCode,
          onTransactionFinished: (status) {
            debugPrint('💳 Payment status: $status');
          },
        ),
      );

      await _handlePaymentResult(context, orderCode, result, isPointExchange, pointsUsed);
    } else {
      // ✅ Generate new Midtrans URL
      debugPrint('🔄 Generating new payment URL...');
      await _regeneratePaymentUrl(context, transaction);
    }
  }

  Future<void> _regeneratePaymentUrl(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    final orderCode = transaction['order_code']?.toString() ?? '';
    final shippingCost = double.tryParse(transaction['shipping_cost']?.toString() ?? '0') ?? 0;
    final deliveryAddress = transaction['delivery_address']?.toString() ?? '';
    final isPointExchange = transaction['is_point_exchange'] == true;
    final pointsUsed = int.tryParse(transaction['points_used']?.toString() ?? '0') ?? 0;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0041c3)),
            const SizedBox(height: 16),
            Text(
              'Mempersiapkan pembayaran...',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );

    try {
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString() ?? '';

      final paymentData = await PaymentService.createPaymentCharge(
        orderId: '${orderCode}_RETRY_${DateTime.now().millisecondsSinceEpoch}',
        customerId: customerId,
        totalPrice: 0,
        totalPayment: shippingCost,
        items: [
          {
            'kode_barang': 'SHIPPING',
            'nama_produk': 'Ongkos Kirim',
            'quantity': 1,
            'price': shippingCost,
            'subtotal': shippingCost,
          }
        ],
        deliveryAddress: deliveryAddress,
        isPointExchange: isPointExchange,
        pointsRequired: pointsUsed,
      );

      // Close loading
      if (mounted) Navigator.of(context).pop();

      if (paymentData['redirect_url'] != null) {
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => MidtransWebView(
            redirectUrl: paymentData['redirect_url'],
            orderId: orderCode,
            onTransactionFinished: (status) {
              debugPrint('💳 Payment status: $status');
            },
          ),
        );

        await _handlePaymentResult(context, orderCode, result, isPointExchange, pointsUsed);
      } else {
        throw Exception('Tidak mendapat URL pembayaran');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mempersiapkan pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePaymentResult(
    BuildContext context,
    String orderCode,
    String? result,
    bool isPointExchange,
    int pointsUsed,
  ) async {
    if (PaymentService.isTransactionSuccess(result)) {
      debugPrint('✅ Payment successful!');
      
      // Update payment status
      try {
        await ApiService.updateOrderPaymentStatus(
          orderCode: orderCode,
          status: 'paid',
        );
      } catch (e) {
        debugPrint('Error updating status: $e');
      }

      // ✅ Potong poin jika point exchange dan belum dipotong
      if (isPointExchange && pointsUsed > 0) {
        try {
          final session = await SessionManager.getUserSession();
          final customerId = session['id']?.toString() ?? '';
          final userData = await ApiService.getCostomerById(customerId);
          final currentPoints = int.tryParse(userData['cos_poin']?.toString() ?? '0') ?? 0;
          
          if (currentPoints >= pointsUsed) {
            final newPoints = currentPoints - pointsUsed;
            await ApiService.updateCostomer(customerId, {'cos_poin': newPoints.toString()});
            debugPrint('💰 Points deducted: $pointsUsed, New balance: $newPoints');
          }
        } catch (e) {
          debugPrint('Error deducting points: $e');
        }
      }

      // Refresh and show success
      await _loadTransactionHistory();
      
      if (mounted) {
        _showPaymentSuccessSnackbar(context);
      }
    } else if (result == 'pending') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Menunggu pembayaran...'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(child: Text('Pembayaran dibatalkan. Anda dapat mencoba lagi nanti.')),
              ],
            ),
            backgroundColor: Colors.grey[700],
          ),
        );
      }
    }
  }

  void _showPaymentSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Pembayaran berhasil!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, String orderCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Batalkan Pesanan?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Pesanan akan dibatalkan dan tidak dapat dikembalikan.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Tidak', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Ya, Batalkan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Membatalkan pesanan...'),
            ],
          ),
        ),
      );
      
      await ApiService.updateOrderPaymentStatus(
        orderCode: orderCode,
        status: 'cancelled',
      );
      
      if (mounted) Navigator.of(context).pop();
      
      await _loadTransactionHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ BUILD METHODS ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoading() : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0041c3),
      elevation: 0,
      title: Text(
        'Riwayat Transaksi',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadTransactionHistory,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0041c3),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildCustomTabBar(),
        Expanded(
          child: TabBarView(
            controller: _mainTabController,
            children: [
              _buildServiceTab(),
              _buildPurchaseTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ============ CUSTOM TAB BAR ============

  Widget _buildCustomTabBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabItem(
                      index: 0,
                      icon: Icons.build_circle,
                      label: 'Service',
                      count: serviceTransactions.length,
                      isSelected: _selectedMainTab == 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabItem(
                      index: 1,
                      icon: Icons.shopping_bag,
                      label: 'Pembelian',
                      count: purchaseTransactions.length,
                      isSelected: _selectedMainTab == 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        _mainTabController.animateTo(index);
        setState(() {
          _selectedMainTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0041c3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0041c3).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.25) 
                    : const Color(0xFF0041c3).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF0041c3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ SERVICE TAB ============

  Widget _buildServiceTab() {
    if (serviceTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.build_circle_outlined,
        title: 'Belum Ada Riwayat Service',
        subtitle: 'Transaksi service Anda akan muncul di sini',
      );
    }

    return Column(
      children: [
        _buildStatusGrid(isService: true),
        Expanded(
          child: _selectedServiceStatus == null
              ? _buildSelectStatusHint()
              : _buildServiceList(),
        ),
      ],
    );
  }

  Widget _buildServiceList() {
    final filtered = _getFilteredServiceTransactions();
    
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: _getStatusIcon(_selectedServiceStatus!),
        title: 'Tidak Ada Pesanan',
        subtitle: 'Tidak ada pesanan dengan status "${_getStatusLabel(_selectedServiceStatus!)}"',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactionHistory,
      color: const Color(0xFF0041c3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildServiceCard(filtered[index]),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> transaction) {
    final kode = transaction['trans_kode'] ?? '-';
    final status = transaction['trans_status']?.toString().toLowerCase() ?? 'pending';
    final tanggal = _formatDate(transaction['trans_tanggal']);
    final total = _formatCurrency(transaction['trans_total']);
    final keluhan = transaction['ket_keluhan'] ?? '-';
    
    final isTrackable = ['pending', 'approved', 'in_progress', 'on_the_way'].contains(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isTrackable
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackingPage(queueCode: kode),
                    ),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0041c3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.build,
                              size: 18,
                              color: Color(0xFF0041c3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '#$kode',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0041c3),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                
                const SizedBox(height: 14),
                Container(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 14),
                
                Row(
                  children: [
                    Expanded(child: _buildInfoItem(Icons.calendar_today, tanggal)),
                    Container(width: 1, height: 20, color: Colors.grey[200]),
                    Expanded(child: _buildInfoItem(Icons.payments, total)),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          keluhan,
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isTrackable) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0041c3), Color(0xFF0052E0)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Lacak Pesanan',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ PURCHASE TAB ============

  Widget _buildPurchaseTab() {
    if (purchaseTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Belum Ada Riwayat Pembelian',
        subtitle: 'Transaksi pembelian Anda akan muncul di sini',
      );
    }

    return Column(
      children: [
        _buildStatusGrid(isService: false),
        Expanded(
          child: _selectedPurchaseStatus == null
              ? _buildSelectStatusHint()
              : _buildPurchaseList(),
        ),
      ],
    );
  }

  Widget _buildPurchaseList() {
    final filtered = _getFilteredPurchaseTransactions();
    
    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: _getStatusIcon(_selectedPurchaseStatus!),
        title: 'Tidak Ada Pesanan',
        subtitle: 'Tidak ada pesanan dengan status "${_getStatusLabel(_selectedPurchaseStatus!)}"',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactionHistory,
      color: const Color(0xFF0041c3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildPurchaseCard(filtered[index]),
      ),
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> transaction) {
    final orderCode = transaction['order_code'] ?? '-';
    final paymentStatus = transaction['payment_status']?.toString().toLowerCase() ?? 'pending';
    final deliveryStatus = transaction['delivery_status']?.toString().toLowerCase() ?? 'menunggu';
    final tanggal = _formatDate(transaction['created_at']);
    final total = _formatCurrency(transaction['total_payment']);
    final shippingCost = double.tryParse(transaction['shipping_cost']?.toString() ?? '0') ?? 0;
    final items = transaction['items'] as List? ?? [];
    final isPointExchange = transaction['is_point_exchange'] == true;
    final pointsUsed = transaction['points_used'] ?? 0;
    final midtransUrl = transaction['midtrans_redirect_url']?.toString();
    final expiresAt = transaction['payment_url_expires_at']?.toString();
    
    // Check if needs payment
    final bool needsPayment = paymentStatus == 'pending' && shippingCost > 0;
    final bool hasValidUrl = midtransUrl != null && 
        midtransUrl.isNotEmpty && 
        _isPaymentUrlValid(expiresAt);
    
    // Get product summary
    String productSummary = 'Tidak ada produk';
    if (items.isNotEmpty) {
      final firstItem = items[0];
      final name = firstItem['nama_produk'] ?? firstItem['name'] ?? 'Produk';
      final qty = firstItem['quantity'] ?? 1;
      if (items.length == 1) {
        productSummary = '$name (${qty}x)';
      } else {
        productSummary = '$name (${qty}x) +${items.length - 1} lainnya';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPointExchange 
                              ? const Color.fromARGB(255, 0, 193, 164).withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPointExchange ? Icons.monetization_on : Icons.shopping_bag,
                          size: 18,
                          color: isPointExchange 
                              ? const Color.fromARGB(255, 0, 193, 164)
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$orderCode',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0041c3),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isPointExchange)
                              Text(
                                'Tukar $pointsUsed Poin',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color.fromARGB(255, 0, 193, 164),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(deliveryStatus),
              ],
            ),
            
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 14),
            
            // Product Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[100]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      productSummary,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 14),
            
            // Info Row
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.calendar_today, tanggal)),
                Container(width: 1, height: 20, color: Colors.grey[200]),
                Expanded(child: _buildInfoItem(Icons.payments, total)),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Status Row
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatus(
                    icon: Icons.payment,
                    label: 'Pembayaran',
                    status: paymentStatus,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStatus(
                    icon: Icons.local_shipping,
                    label: 'Pengiriman',
                    status: deliveryStatus,
                  ),
                ),
              ],
            ),
            
            // ✅ Payment Action Button for pending orders
            if (needsPayment) ...[
              const SizedBox(height: 14),
              
              // Warning banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menunggu Pembayaran Ongkir',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                          Text(
                            _formatCurrency(shippingCost),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Pay Now Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelOrder(context, orderCode),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Batalkan',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleContinuePayment(context, transaction),
                      icon: const Icon(Icons.payment, size: 18),
                      label: Text(
                        'Bayar Sekarang',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0041c3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Expiry info
              if (expiresAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      _getExpiryText(expiresAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: hasValidUrl ? Colors.grey[500] : Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ REUSABLE WIDGETS ============

  Widget _buildStatusGrid({required bool isService}) {
    final statuses = isService ? serviceStatuses : purchaseStatuses;
    final selectedStatus = isService ? _selectedServiceStatus : _selectedPurchaseStatus;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0041c3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.filter_list, size: 16, color: Color(0xFF0041c3)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter Status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (selectedStatus != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isService) {
                          _selectedServiceStatus = null;
                        } else {
                          _selectedPurchaseStatus = null;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: statuses.asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                final count = isService
                    ? _getServiceCountByStatus(status)
                    : _getPurchaseCountByStatus(status);
                final isSelected = selectedStatus == status;

                return Padding(
                  padding: EdgeInsets.only(right: index < statuses.length - 1 ? 10 : 0),
                  child: _buildStatusFilterChip(
                    status: status,
                    count: count,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isService) {
                          _selectedServiceStatus = isSelected ? null : status;
                        } else {
                          _selectedPurchaseStatus = isSelected ? null : status;
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String status,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = _getStatusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getStatusIcon(status), size: 20, color: isSelected ? Colors.white : color),
              ),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              Text(
                _getStatusLabel(status),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusLabel(status),
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatus({
    required IconData icon,
    required String label,
    required String status,
  }) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Text(_getStatusLabel(status), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectStatusHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0041c3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.touch_app, size: 48, color: const Color(0xFF0041c3).withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text('Pilih Status', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
              'Tap salah satu status di atas\nuntuk melihat daftar pesanan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(icon, size: 52, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500], height: 1.4), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ============ BOTTOM NAVIGATION ============

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) {
            _loadTransactionHistory();
            return;
          }
          
          Widget? page;
          switch (index) {
            case 0: page = const ServicePage(); break;
            case 1: page = const MarketplacePage(); break;
            case 2: page = const HomePage(); break;
            case 3: page = const TukarPoinPage(); break;
            case 4: return;
          }
          
          if (page != null) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page!));
          }
        },
        backgroundColor: const Color(0xFF0041c3),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: 'Service'),
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Beli'),
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: currentIndex == 3
                ? Image.asset('assets/image/promo.png', width: 24, height: 24)
                : Opacity(opacity: 0.6, child: Image.asset('assets/image/promo.png', width: 24, height: 24)),
            label: 'Promo',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}
