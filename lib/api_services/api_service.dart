import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:e_service/models/technician_order_model.dart';

class ApiService {
  // Ganti dengan alamat server Laravel kamu
  // static const String baseUrl = 'http://192.168.1.6:8000/api';
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
        final data = json.decode(response.body);
        // Pastikan response memiliki 'role'
        if (data['success'] == true && data.containsKey('role')) {
          return data;
        } else {
          // Jika tidak ada role, anggap sebagai customer
          return {
            'success': data['success'] ?? false,
            'message': data['message'] ?? 'Login berhasil',
            'user': data['user'],
            'role': 'customer',
          };
        }
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

//Transaksi
  // POST - Tambah transaksi baru
  static Future<Map<String, dynamic>> createTransaksi(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = json.decode(response.body);
        // Handle if response is wrapped in 'data'
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      } catch (e) {
        if (e is FormatException) {
          print('Response is not valid JSON: ${response.body}');
          throw Exception('Response is not valid JSON: ${response.body}');
        } else {
          rethrow;
        }
      }
    } else {
      throw Exception('Gagal membuat transaksi: ${response.body}');
    }
  }

  // GET technician orders by kry_kode
  
  // ✅ GET technician orders by kry_kode - UPDATED WITH DEBUG LOGS
  static Future<List<TechnicianOrder>> getkry_kode(String kryKode) async {
    print('🔍 [API] Fetching orders for kry_kode: $kryKode');

    final response = await http.get(Uri.parse('$baseUrl/transaksi'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('📊 [API] Total transaksi from server: ${data.length}');

      // Debug: Print semua kry_kode yang ada
      final allKryCodes = data.map((item) => item['kry_kode']).toSet();
      print('📋 [API] All kry_kode in database: $allKryCodes');

      final filteredData =
          data.where((item) {
            final itemKryKode = item['kry_kode']?.toString();
            final match = itemKryKode == kryKode;

            if (match) {
              print(
                '✅ [API] Match found - trans_kode: ${item['trans_kode']}, kry_kode: $itemKryKode, status: ${item['trans_status']}',
              );
            }

            return match;
          }).toList();

      print('📦 [API] Filtered orders for $kryKode: ${filteredData.length}');

      if (filteredData.isEmpty) {
        print('⚠️ [API] No orders found for kry_kode: $kryKode');
        print('   Make sure:');
        print('   1. Database has transaksi with kry_kode = "$kryKode"');
        print('   2. kry_kode is exact match (case-sensitive)');
        return [];
      }

      // Fetch customer data for each transaction
      final List<TechnicianOrder> orders = [];
      for (var item in filteredData) {
        print('🔄 [API] Processing transaction: ${item['trans_kode']}');

        final cosKode = item['cos_kode'];
        if (cosKode != null && cosKode.toString().isNotEmpty) {
          try {
            print('   Fetching customer data for cos_kode: $cosKode');
            final customerResponse = await http.get(
              Uri.parse('$baseUrl/costomers/$cosKode'),
            );

            if (customerResponse.statusCode == 200) {
              final customerData = json.decode(customerResponse.body);
              // Merge customer data into transaction data
              item['cos_nama'] = customerData['cos_nama'];
              item['cos_alamat'] = customerData['cos_alamat'];
              item['cos_hp'] = customerData['cos_hp'];

              print('   ✅ Customer data merged: ${customerData['cos_nama']}');
            } else {
              print(
                '   ⚠️ Customer API returned ${customerResponse.statusCode} for $cosKode',
              );
            }
          } catch (e) {
            print('   ❌ Failed to fetch customer $cosKode: $e');
          }
        } else {
          print('   ⚠️ No cos_kode in transaction ${item['trans_kode']}');
        }

        try {
          final order = TechnicianOrder.fromMap(item);
          orders.add(order);
          print(
            '   ✅ Order object created: ${order.orderId}, status: ${order.status.name}',
          );
        } catch (e) {
          print('   ❌ Failed to create TechnicianOrder: $e');
          print('   Item data: $item');
        }
      }

      print('🎯 [API] Successfully created ${orders.length} order objects');
      return orders;
    } else {
      print('❌ [API] HTTP Error: ${response.statusCode}');
      print('   Response: ${response.body}');
      throw Exception('Gagal memuat data pesanan teknisi');
    }
  }


  // GET semua transaksi
  static Future<List<dynamic>> getTransaksi() async {
    final response = await http.get(Uri.parse('$baseUrl/transaksi'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data transaksi');
    }
  }

  // GET transaksi by trans_kode
  static Future<Map<String, dynamic>> getTransaksiByKode(String transKode) async {
    final response = await http.get(Uri.parse('$baseUrl/transaksi/$transKode'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'];
      }
      return data;
    } else {
      throw Exception('Gagal memuat data transaksi');
    }
  }

  // GET pending transaksi by trans_kode
  static Future<Map<String, dynamic>> getPendingTransaksiByKode(String transKode) async {
    final response = await http.get(Uri.parse('$baseUrl/transaksi/pending/$transKode'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Transaksi tidak ditemukan');
      }
    } else {
      throw Exception('Gagal memuat data transaksi pending');
    }
  }

  // UPDATE status transaksi
  static Future<Map<String, dynamic>> updateTransaksiStatus(
    String transKode,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaksi/$transKode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'_method': 'PUT', 'trans_status': status}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal update status transaksi: ${response.body}');
    }
  }
  
  // UPDATE ket_keluhan + trans_total (Tindakan)
  static Future<Map<String, dynamic>> updateTransaksiTemuan(
    String transKode,
    String ketKeluhan,
    num transTotal, {
    String? alsoSetStatus,
  }) async {
    final uri = Uri.parse('$baseUrl/transaksi/$transKode');
    final payload = {
      '_method': 'PUT',
      'ket_keluhan': ketKeluhan,
      'trans_total': transTotal,
      if (alsoSetStatus != null) 'trans_status': alsoSetStatus,
    };

    print('[ApiService.updateTransaksiTemuan] PUT $uri');
    print('  payload: $payload');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    print('[ApiService.updateTransaksiTemuan] status: ${res.statusCode}');
    print('[ApiService.updateTransaksiTemuan] body  : ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      return data is Map<String, dynamic> ? data : {'data': data};
    } else {
      throw Exception('Gagal simpan temuan transaksi: ${res.body}');
    }
  }

  // DRIVER LOCATION TRACKING
   static Future<void> updateDriverLocation({
    required String transKode,
    required String kryKode,
    required double latitude,
    required double longitude,
  }) async {
    // URL disesuaikan dengan standar route Laravel (tanpa .php)
    final url = '$baseUrl/update-driver-location';

    // Data yang akan dikirim dalam format JSON
    final body = json.encode({
      'trans_kode': transKode,
      'kry_kode': kryKode,
      'latitude': latitude,
      'longitude': longitude,
    });

    print('📍 [API] Sending location to: $url');
    print('   Payload: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📡 [API] Response status: ${response.statusCode}');
      print('📄 [API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ [API] Lokasi berhasil dikirim dan disimpan di server.');
        } else {
          print('⚠️ [API] Server merespons, tapi ada error: ${data['message']}');
        }
      } else {
        // Jika 404, artinya route di Laravel belum ada atau salah ketik.
        // Jika 500, artinya ada error di kode Controller Laravel.
        print('❌ [API] Gagal mengirim lokasi, HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      // Error ini terjadi jika tidak ada koneksi internet atau server tidak bisa dijangkau.
      print('🚫 [API] Network error: $e');
    }
  }

  // Fungsi untuk getDriverLocation juga perlu disesuaikan jika ingin dipakai
  static Future<Map<String, dynamic>?> getDriverLocation(String transKode) async {
    // Sesuaikan dengan route di Laravel untuk mengambil lokasi
    final url = '$baseUrl/get-driver-location/$transKode';

    print('📍 [API] Fetching location from: $url');
    try {
      final response = await http.get(Uri.parse(url));

      print('📡 [API] Response status: ${response.statusCode}');
      print('📄 [API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> && responseData['success'] == true) {
          final locationData = responseData['data'] as Map<String, dynamic>;
          // Merge icon from response if present, default to 'motorcycle'
          locationData['icon'] = responseData['icon'] ?? 'motorcycle';
          return locationData;
        } else {
          print('❌ [API] Invalid response format: $responseData');
          return null;
        }
      } else {
        print('❌ [API] Gagal mengambil lokasi driver: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('🚫 [API] Network error saat mengambil lokasi: $e');
      return null;
    }
  }


// ORDER
  // POST - Tambah order_list
  static Future<Map<String, dynamic>> createOrderList(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order-list'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal membuat order_list: ${response.body}');
    }
  }

  // GET all order_list
  static Future<List<dynamic>> getOrderList() async {
    final response = await http.get(Uri.parse('$baseUrl/order-list'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Order list tidak ditemukan');
      }
    } else {
      throw Exception('Gagal memuat order list');
    }
  }

  // GET order_list by trans_kode
  static Future<List<dynamic>> getOrderListByTransKode(String transKode) async {
    final response = await http.get(Uri.parse('$baseUrl/order-list/trans/$transKode'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Order list tidak ditemukan');
      }
    } else {
      throw Exception('Gagal memuat order list');
    }
  }

  // GET order_list by kry_kode (for technicians)
  static Future<List<dynamic>> getOrderListByKryKode(String kryKode) async {
    final response = await http.get(Uri.parse('$baseUrl/order-list/kry/$kryKode'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Order list tidak ditemukan untuk kry_kode tersebut');
      }
    } else {
      throw Exception('Gagal memuat order list by kry_kode');
    }
  }

  // POST - Update order_list status
  static Future<Map<String, dynamic>> updateOrderListStatus(String orderId, String newStatus) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order-list/update-status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'trans_kode': orderId,
        'trans_status': newStatus,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal update status order_list');
      }
    } else {
      throw Exception('Gagal update status order_list: ${response.body}');
    }
  }



  // Ambil DETAIL order_list:
  // 1) Coba GET /order-list/{orderId}
  // 2) Jika belum ada endpointnya, fallback: ambil semua /order-list dan filter by order_id
  static Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    // Coba endpoint langsung
    try {
      final url = Uri.parse('$baseUrl/order-list/$orderId');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is Map<String, dynamic>) {
          if (data['data'] is Map<String, dynamic>) return data['data'];
          return data;
        }
      } else {
        print('getOrderDetail: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('getOrderDetail error: $e');
    }

    // Fallback: ambil dari list
    try {
      final list = await getOrderList();
      for (final it in list) {
        if (it is Map<String, dynamic>) {
          final code = it['order_id']?.toString();
          if (code == orderId) return it;
        }
      }
    } catch (e) {
      print('getOrderDetail fallback list error: $e');
    }
    return null;
  }

  // POST - Tambah tindakan baru
  static Future<Map<String, dynamic>> createTindakan(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tindakan'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal membuat tindakan: ${response.body}');
    }
  }

}
