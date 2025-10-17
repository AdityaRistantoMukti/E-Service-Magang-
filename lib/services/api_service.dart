import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan alamat server Laravel kamu
  static const String baseUrl = 'http://192.168.1.15:8000/api'; 

  //  GET semua costomer
  static Future<List<dynamic>> getCostomers() async {
    final response = await http.get(Uri.parse('$baseUrl/costomers'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data costomer');
    }
  }

  //  POST - Tambah costomer
  static Future<void> addCostomer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/costomers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal menambahkan costomer');
    }
  }

  // PUT - Update costomer
  static Future<void> updateCostomer(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/costomers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate costomer');
    }
  }

  //  DELETE - Hapus costomer
    static Future<void> deleteCostomer(int id) async {
      final response = await http.delete(
        Uri.parse('$baseUrl/costomers/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus costomer');
      }
    }

    // LOGIN USER
    static Future<Map<String, dynamic>> login(String nama, String password) async {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cos_nama': nama, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        return json.decode(response.body);
      } else {
      throw Exception('Gagal login');
    }
  } 

  // REGISTER USER 
   Future<Map<String, dynamic>> registerUser(String name, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'cos_nama': name,
        'password': password,
      },
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      try {
        // Jika API kirim JSON error
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Registrasi gagal');
      } catch (_) {
        // Jika API kirim text biasa (bukan JSON)
        throw Exception(response.body);
      }
    }
  }


}
