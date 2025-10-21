import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan alamat server Laravel kamu
  static const String baseUrl = 'http://192.168.1.15:8000/api'; 

//Customer
  //  GET semua costomer
  static Future<List<dynamic>> getCostomers() async {
    final response = await http.get(Uri.parse('$baseUrl/costomers'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data costomer');
    }
  }

  // GET data costomer berdasarkan ID
  static Future<Map<String, dynamic>> getCostomerById(String id) async {
  final response = await http.get(Uri.parse('$baseUrl/costomers/$id'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // kalau response API langsung user
    return data;
    // kalau response API pakai format { "success": true, "data": { ... } }
    // return data['data'];
  } else {
    throw Exception('Gagal mengambil data costomer');
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

//Produk
  // GET semua produk
  static Future<List<dynamic>> getProduk() async {
    final response = await http.get(Uri.parse('$baseUrl/produk'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data produk');
    }
  }
      // PROMO
      static Future<List<dynamic>> getPromo() async {
        final response = await http.get(Uri.parse('$baseUrl/promo'));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Gagal memuat data promo');
        }
      }







//AUTH    
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
  //REGISTER
  static Future<Map<String, dynamic>> registerUser(
    String name, String password, String nohp, String tglLahir) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'cos_nama': name,
        'password': password,
        'cos_hp': nohp,
        'cos_tgl_lahir': tglLahir,
      },
    );

    final data = json.decode(response.body);
    return {
      'status': response.statusCode,
      'success': data['success'] ?? false,
      'code': data['code'] ?? 0,
      'message': data['message'] ?? 'Terjadi kesalahan',
      'costomer': data['costomer'],
    };
  }



}
