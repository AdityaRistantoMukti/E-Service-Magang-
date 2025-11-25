import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CekGaransiPage extends StatefulWidget {
  const CekGaransiPage({super.key});

  @override
  State<CekGaransiPage> createState() => _CekGaransiPageState();
}

class _CekGaransiPageState extends State<CekGaransiPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0041c3),
        title: Text(
          'Cara Mengecek Status Garansi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/image/banner/garansi.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cara Mengecek Status Garansi Barang Kamu',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '''
Sebelum melakukan servis, penting untuk memastikan apakah barang kamu masih dalam masa garansi atau tidak.
Berikut beberapa cara mudah untuk mengecek status garansi berbagai jenis perangkat:

🔹 1. Cek Kartu Garansi atau Nota Pembelian

Setiap produk biasanya disertai kartu garansi atau nota pembelian dari toko.

Di sana tertera:

Tanggal pembelian

Nomor seri (serial number) perangkat

Lama garansi (misalnya: 1 tahun)

Hitung masa garansi dari tanggal pembelian tersebut.

🔹 2. Cek di Website Resmi Merek Produk

Hampir semua merek besar menyediakan fitur cek garansi online.
Kamu hanya perlu memasukkan nomor seri atau IMEI perangkat.

Contohnya:

Merek	Link Pengecekan Garansi
Samsung	https://www.samsung.com/id/support/warranty/

Xiaomi	https://www.mi.co.id/id/service/warranty/

OPPO	https://support.oppo.com/id/warranty-check/

ASUS	https://www.asus.com/id/support/warranty-status-inquiry/

HP (Hewlett-Packard)	https://support.hp.com/id-en/checkwarranty

Lenovo	https://support.lenovo.com/id/en/warrantylookup

📌 Tips: Nomor seri atau IMEI biasanya bisa ditemukan di:

Kotak kemasan produk

Stiker di bagian belakang atau bawah perangkat

Menu "Tentang Perangkat" (untuk smartphone/laptop)

🔹 3. Cek Melalui Aplikasi Resmi Brand

Beberapa merek punya aplikasi resmi yang otomatis menampilkan status garansi begitu kamu login, contohnya:

Samsung Members

MyOPPO

Mi Account

MyASUS

🔹 4. Hubungi Layanan Pelanggan (Customer Service)

Jika kamu tidak bisa menemukan informasi secara online, kamu bisa langsung menghubungi layanan pelanggan resmi dengan menyebutkan nomor seri dan tanggal pembelian.

⚠️ Catatan Penting

Garansi biasanya tidak berlaku untuk:

Kerusakan akibat jatuh, air, atau kesalahan pengguna.

Modifikasi perangkat di luar service center resmi.

Selalu simpan nota pembelian dan kartu garansi agar mudah diklaim.
''',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
