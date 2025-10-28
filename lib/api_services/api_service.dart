import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan alamat server Laravel kamu
  static const String baseUrl = 'http://192.168.1.6:8000/api'; 

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
  // Upload foto profil
    static Future<Map<String, String>> uploadProfile(File file) async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile'), 
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = json.decode(resBody);
        return {
          'url': data['url'],
          'path': data['path'],
        };
      } else {
        throw Exception('Gagal upload foto profil');
      }
    }

    // Update data costomer
    static Future<void> updateCostomer(String id, Map<String, dynamic> data) async {
      var uri = Uri.parse('$baseUrl/costomers/$id');

      var response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          '_method': 'PUT', // spoof method PUT
          ...data,
        }),
      );

      if (response.statusCode != 200) {
        print('Gagal update: ${response.body}');  
        throw Exception('Gagal memperbarui profil');
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
    static Future<Map<String, dynamic>> login(String username, String password) async {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
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
    String name, String username, String password, String nohp, String tglLahir) async {
    // Convert phone number: replace leading '0' with '62'
    String formattedNohp = nohp.startsWith('0') ? '62${nohp.substring(1)}' : nohp;

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cos_nama': name,
        'username': username,
        'password': password,
        'cos_hp': formattedNohp,
        'cos_tgl_lahir': tglLahir,
      }),
    );

    return json.decode(response.body);
  }



}
