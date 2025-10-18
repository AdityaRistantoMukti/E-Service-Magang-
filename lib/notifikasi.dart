import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_notifikasi.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [
    {
      'icon': Icons.card_giftcard,
      'title': 'Selamat ulang tahun Users',
      'subtitle':
          'Anda mendapatkan hadiah ulang tahun, klik untuk mengambilnya',
      'color': Colors.blue,
      'textColor': Colors.white,
    },
    {
      'icon': Icons.person,
      'title': 'Selamat datang Users',
      'subtitle':
          'Selamat datang perbarui profilmu yuk, klik untuk melihat profile anda',
      'color': const Color(0xFFE0E0E0),
      'textColor': Colors.black87,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/logo.png', // ganti sesuai logo kamu
              height: 40,
            ),
            const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.black),
                      SizedBox(width: 5),
                      Text('Kembali', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      notifications.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item['title']} dihapus'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: item['color'],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'],
                        color: item['textColor'],
                      ),
                      title: Text(
                        item['title'],
                        style: GoogleFonts.poppins(
                          color: item['textColor'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        item['subtitle'],
                        style: GoogleFonts.poppins(
                          color: item['textColor'].withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailPage(
                              title: item['title'],
                              subtitle: item['subtitle'],
                              icon: item['icon'],
                              color: item['color'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
