import 'package:flutter/material.dart';

class EditNmtlpnPage extends StatefulWidget {
  const EditNmtlpnPage({super.key});

  @override
  State<EditNmtlpnPage> createState() => _EditNmtlpnPageState();
}

class _EditNmtlpnPageState extends State<EditNmtlpnPage> {
  final TextEditingController phoneController = TextEditingController(text: '081292303471');
  int maxLength = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // === APP BAR ===
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4DB7),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Azzahra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Icon(Icons.chat_bubble_outline, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),

      // === BODY ===
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tombol kembali
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Kembali",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // === INPUT FIELD ===
            TextField(
              controller: phoneController,
              maxLength: maxLength,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                labelStyle: const TextStyle(color: Colors.black54),
                suffixIcon: const Icon(Icons.phone, color: Color(0xFF1E4DB7)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E4DB7), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E4DB7), width: 1),
                ),
                counterText:
                    '${phoneController.text.length}/${maxLength.toString()}',
                counterStyle: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),

            const Spacer(),

            // Tombol Simpan
            Center(
              child: SizedBox(
                width: 180,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4DB7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Nomor telepon disimpan: ${phoneController.text}")),
                    );
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
