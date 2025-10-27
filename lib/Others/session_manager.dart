import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserId = 'id_costomer';
  static const String _keyUserName = 'cos_nama';
  static const String _keyPoin = 'cos_poin';

  // Simpan data login
  static Future<void> saveUserSession(String id, String name, int poin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyUserName, name);
    await prefs.setInt(_keyPoin, poin);
  }

  // Ambil data login
  static Future<Map<String, dynamic>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_keyUserId),
      'name': prefs.getString(_keyUserName),
      'poin': prefs.getInt(_keyPoin) ?? 0,
    };
  }

  // Hapus data login (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyPoin); // 🟢 Tambahkan ini
    await prefs.setBool('isLoggedIn', false);
  }

  // Cek apakah sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Update poin saja (misal setelah transaksi)
  static Future<void> updateUserPoin(int poin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPoin, poin);
  }

  // Get customer ID
  static Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }
}
