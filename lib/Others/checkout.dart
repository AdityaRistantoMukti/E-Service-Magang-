import 'package:e_service/Service/detail_alamat.dart';
import 'package:flutter/material.dart';
import 'struck_pesanan.dart';

class CheckoutPage extends StatefulWidget {
  final bool? usePointsFromPromo; 
  const CheckoutPage({super.key, this.usePointsFromPromo});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedPaymentMethod;
  String? selectedShipping;
  Map<String, dynamic>? selectedAddress;
  bool usePoints = false; // Variable untuk toggle pembayaran


  @override
  void initState() {
    super.initState();
    // Set usePoints berdasarkan parameter yang dikirim dari promo
    if (widget.usePointsFromPromo != null) {
      usePoints = widget.usePointsFromPromo!;
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Ringkasan Pesanan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Pengiriman ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1 Produk",
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 6),
                      const Text("Pengiriman 1–3 Hari",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Produk Online",
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.delivery_dining,
                            color: Colors.blue, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Estimasi sampai: Maks. Senin, 20 Okt",
                                  style: TextStyle(fontSize: 13)),
                              Text("Jam 07:00 – 21:00",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Produk ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/image/produk.jpg',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Laptop Si Unyil",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text("Ram 8GB SSD 512GB Intel I9",
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        // Tampilkan harga atau poin berdasarkan usePoints
                        usePoints
                            ? Row(
                                children: const [
                                  Text("1x   ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Icon(Icons.monetization_on,
                                      color: Color.fromARGB(255, 0, 193, 164), size: 18),
                                  SizedBox(width: 4),
                                  Text("1200",
                                      style: TextStyle(
                                          color: Color.fromARGB(255, 0, 193, 164),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),                                  
                                ],
                              )
                            : const Text("1x   Rp 1.000.000",
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Ringkasan Pesanan ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ringkasan Pesanan",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  // Tampilkan nilai 0 jika menggunakan poin
                  _summaryRow("Subtotal", usePoints ? "Rp 0" : "Rp 100.000"),
                  _summaryRow("Diskon", usePoints ? "Rp 0" : "Rp 40.000"),
                  _summaryRow("Voucher", "Rp 0"),
                  _summaryRow("Total ongkos kirim", "Rp 0"),
                  const Divider(),
                  // Ubah label dan nilai untuk Total jika menggunakan poin
                  usePoints
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Poin",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87)),
                              Row(
                                children: const [
                                  Icon(Icons.monetization_on,
                                      color: Color.fromARGB(255, 0, 193, 164), size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    "1200",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 193, 164),
                                    ),
                                  ),                                 
                                ],
                              ),
                            ],
                          ),
                        )
                      : _summaryRow("Total Belanja", "Rp 60.000",
                          isTotal: true, color: Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Toggle Metode Pembayaran (Poin atau Bank) ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Gunakan Poin",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 4),
                    ],
                  ),
                  Switch(
                    value: usePoints,
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setState(() {
                        usePoints = value;
                        // Reset payment method ketika toggle diubah
                        if (usePoints) {
                          selectedPaymentMethod = null;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Ekspedisi ---
            InkWell(
              onTap: () => _showShippingOptions(context),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Pilih Ekspedisi",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("Pilih",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (selectedShipping != null) ...[
                      Row(
                        children: [
                          Icon(_getShippingIcon(selectedShipping!),
                              color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedShipping!,
                                    style: const TextStyle(fontSize: 14)),
                                const Text("Estimasi 1-3 hari",
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.blueAccent, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Text("Pilih ekspedisi pengiriman",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // --- Alamat ---
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DetailAlamatPage()),
                );
                if (result != null) {
                  setState(() {
                    selectedAddress = result;
                  });
                }
              },
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Kirim ke Alamat",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("Tambahkan Alamat",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: selectedAddress != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${selectedAddress!['nama']} - ${selectedAddress!['hp']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(selectedAddress!['detailAlamat'],
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black87)),
                                if (selectedAddress!['catatan'] != null &&
                                    selectedAddress!['catatan'].isNotEmpty)
                                  Text(
                                      "Catatan: ${selectedAddress!['catatan']}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54)),
                              ],
                            )
                          : const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Atur alamat anda di sini",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text(
                                    "Masukan detail alamat agar memudahkan pengiriman barang",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.black87)),
                                SizedBox(height: 6),
                                Text(
                                    "Tambahkan catatan untuk memudahkan kurir menemukan lokasimu.",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                                SizedBox(height: 8),
                                Text(
                                  "GPS belum aktif. Aktifkan dulu supaya alamatmu terbaca dengan tepat.",
                                  style:
                                      TextStyle(color: Colors.blue, fontSize: 12),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Metode Pembayaran (if selected and not using points) ---
            if (selectedPaymentMethod != null && !usePoints) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Metode Pembayaran",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(_getPaymentIcon(selectedPaymentMethod!),
                            color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedPaymentMethod!,
                                  style: const TextStyle(fontSize: 14)),
                              const Text("Nomor Rekening: 1234567890",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),

      // --- Tombol Pembayaran ---
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                usePoints ? const Color.fromARGB(255, 0, 193, 164) : Colors.blue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: usePoints
              ? () => _completeOrderWithPoints(context)
              : (selectedPaymentMethod != null
                  ? () => _completeOrder(context)
                  : () => _showPaymentOptions(context)),
          child: Text(
            usePoints
                ? "Tukar Poin"
                : (selectedPaymentMethod != null
                    ? "Selesaikan Pesanan"
                    : "Pilih Metode Pembayaran"),
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Metode Pembayaran",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _paymentItem(Icons.account_balance, "Transfer Bank BCA"),
              _paymentItem(Icons.account_balance_wallet, "Transfer Bank BRI"),
              _paymentItem(
                  Icons.account_balance_rounded, "Transfer Bank Mandiri"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        setState(() {
          selectedPaymentMethod = label;
        });
        Navigator.pop(context);
      },
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case "Transfer Bank BCA":
        return Icons.account_balance;
      case "Transfer Bank BRI":
        return Icons.account_balance_wallet;
      case "Transfer Bank Mandiri":
        return Icons.account_balance_rounded;
      default:
        return Icons.account_balance;
    }
  }

  void _showShippingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Ekspedisi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _shippingItem(Icons.local_shipping, "J&T"),
              _shippingItem(Icons.delivery_dining, "SiCepat"),
              _shippingItem(Icons.local_shipping_outlined, "JNE"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _shippingItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        setState(() {
          selectedShipping = label;
        });
        Navigator.pop(context);
      },
    );
  }

  IconData _getShippingIcon(String shipping) {
    switch (shipping) {
      case "J&T":
        return Icons.local_shipping;
      case "SiCepat":
        return Icons.delivery_dining;
      case "JNE":
        return Icons.local_shipping_outlined;
      default:
        return Icons.local_shipping;
    }
  }

  void _completeOrder(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StruckPesananPage(
          serviceType: 'shop',
          nama: selectedAddress?['nama'] ?? 'User',
          jumlahBarang: 1,
          items: [
            {
              'merek': 'ASUS',
              'device': 'Laptop Si Unyil',
              'seri': 'Ram 8GB SSD 512GB Intel I9',
            }
          ],
          alamat:
              selectedAddress?['detailAlamat'] ?? 'Atur alamat anda di sini',
          totalHarga: 'Rp 60.000',
        ),
      ),
    );
  }

  void _completeOrderWithPoints(BuildContext context) {
    // Fungsi untuk menyelesaikan pesanan dengan poin
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StruckPesananPage(
          serviceType: 'shop',
          nama: selectedAddress?['nama'] ?? 'User',
          jumlahBarang: 1,
          items: [
            {
              'merek': 'ASUS',
              'device': 'Laptop Si Unyil',
              'seri': 'Ram 8GB SSD 512GB Intel I9',
            }
          ],
          alamat:
              selectedAddress?['detailAlamat'] ?? 'Atur alamat anda di sini',
          totalHarga: '1200 Poin',
        ),
      ),
    );
  }
}