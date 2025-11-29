import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:azza_service/models/technician_order_model.dart';
import 'package:azza_service/config/api_config.dart';

class ApiService {
  // Base URL is now configurable in ApiConfig
  static String get baseUrl => ApiConfig.apiBaseUrl;

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

      var response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      debugPrint('Update customer response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal memperbarui profil: ${response.statusCode} - ${response.body}');
      }
    }

    // Upload bukti pembayaran
       static Future<Map<String, String>> uploadPaymentProof(File file) async {
         var request = http.MultipartRequest(
           'POST',
           Uri.parse('$baseUrl/checkout/upload-payment-proof'),
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
           throw Exception('Gagal upload bukti pembayaran');
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
    // GET semua produk dengan error handling
   static Future<List<dynamic>> getProduk() async {
     try {
       final response = await http.get(
         Uri.parse('$baseUrl/produk'),
         headers: {
           'Accept': 'application/json',
         },
       ).timeout(const Duration(seconds: 30));

       if (response.statusCode == 200) {
         final data = json.decode(response.body);
         return data;
       } else {
         throw Exception('Gagal memuat data produk: ${response.statusCode}');
       }
     } catch (e) {
       throw Exception('Gagal memuat data produk: $e');
     }
   }

   // GET produk dengan pagination (lazy loading)
   static Future<Map<String, dynamic>> getProdukPaginated({
     int limit = 20,
     int offset = 0,
   }) async {
     try {
       final uri = Uri.parse('$baseUrl/produk').replace(queryParameters: {
         'limit': limit.toString(),
         'offset': offset.toString(),
       });

       final response = await http.get(
         uri,
         headers: {
           'Accept': 'application/json',
         },
       ).timeout(const Duration(seconds: 30));

       if (response.statusCode == 200) {
         final data = json.decode(response.body);

         // Handle if response is wrapped in success/data format
         if (data is Map<String, dynamic> && data.containsKey('data')) {
           return {
             'data': data['data'] ?? [],
             'total': data['total'] ?? 0,
             'hasMore': data['has_more'] ?? false,
           };
         }

         // Assume direct array response - check if we got exactly the limit amount
         final products = data is List ? data : [];
         return {
           'data': products,
           'total': products.length,
           'hasMore': products.length == limit, // If we got exactly the limit, there might be more
         };
       } else {
         throw Exception('Gagal memuat data produk: ${response.statusCode}');
       }
     } catch (e) {
       throw Exception('Gagal memuat data produk: $e');
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
        headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        },
      body: jsonEncode({'username': username, 'password': password}),
      );

      Map<String, dynamic> data = {};
      try { data = response.body.isNotEmpty ? json.decode(response.body) : {}; } catch (_) {
      data = {'success': false, 'message': 'Non-JSON response', 'raw': response.body};
      }

      if (response.statusCode == 200) {
      if (data['success'] == true && data.containsKey('role')) return data;
      return {
      'success': data['success'] ?? true,
      'message': data['message'] ?? 'Login berhasil',
      'user': data['user'],
      'role': 'customer',
      };
      } else if (response.statusCode == 401) {
      return data; // {success:false, message:'Username atau password salah'}
      } else {
      return {
      'success': false,
      'message': 'HTTP ${response.statusCode}: ${data['message'] ?? response.body}',
      'raw': response.body,
      };
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
  
  static Future<List<TechnicianOrder>> getkry_kode(String kryKode) async {
    final response = await http.get(Uri.parse('$baseUrl/transaksi'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      final filteredData =
          data.where((item) {
            final itemKryKode = item['kry_kode']?.toString();
            return itemKryKode == kryKode;
          }).toList();

      if (filteredData.isEmpty) {
        return [];
      }

      // Fetch customer data for each transaction
      final List<TechnicianOrder> orders = [];
      for (var item in filteredData) {
        final cosKode = item['cos_kode'];
        if (cosKode != null && cosKode.toString().isNotEmpty) {
          try {
            final customerResponse = await http.get(
              Uri.parse('$baseUrl/costomers/$cosKode'),
            );

            if (customerResponse.statusCode == 200) {
              final customerData = json.decode(customerResponse.body);
              // Merge customer data into transaction data
              item['cos_nama'] = customerData['cos_nama'];
              item['cos_alamat'] = customerData['cos_alamat'];
              item['cos_hp'] = customerData['cos_hp'];
            }
          } catch (e) {
            // Customer data fetch failed, continue without it
          }
        }

        try {
          final order = TechnicianOrder.fromMap(item);
          orders.add(order);
        } catch (e) {
          // Failed to create order, skip this item
        }
      }

      return orders;
    } else {
      throw Exception('Gagal memuat data pesanan teknisi: HTTP ${response.statusCode}');
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

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

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

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          // Server responded but with error
        }
      }
      // Location update completed (success or failure handled silently)
    } catch (e) {
      // Network error - silently fail for location updates
    }
  }

  // Fungsi untuk getDriverLocation juga perlu disesuaikan jika ingin dipakai
  static Future<Map<String, dynamic>?> getDriverLocation(String transKode) async {
    // Sesuaikan dengan route di Laravel untuk mengambil lokasi
    final url = '$baseUrl/get-driver-location/$transKode';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> && responseData['success'] == true) {
          final locationData = responseData['data'] as Map<String, dynamic>;
          // Merge icon from response if present, default to 'motorcycle'
          locationData['icon'] = responseData['icon'] ?? 'motorcycle';
          return locationData;
        }
      }
      return null;
    } catch (e) {
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
      if (data is List) {
        return data;
      } else if (data is Map && data['success'] == true) {
        final dataList = data['data'];
        if (dataList is List) {
          return dataList;
        } else {
          return [];
        }
      } else {
        throw Exception('Unexpected response format for order list');
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
      }
    } catch (e) {
      // Silently handle error for fallback
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
      // Fallback failed
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

  
  // ✅ GET tindakan by trans_kode - UNTUK MENAMPILKAN SUBTOTAL DP
  static Future<List<dynamic>?> getTindakanByTransKode(String transKode) async {
    try {
      final url = Uri.parse('$baseUrl/tindakan/trans/$transKode');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle berbagai format response
        if (data is Map<String, dynamic>) {
          if (data['success'] == true && data['data'] is List) {
            return data['data'] as List<dynamic>;
          } else if (data.containsKey('data') && data['data'] is List) {
            return data['data'] as List<dynamic>;
          }
        } else if (data is List) {
          return data;
        }

        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Gagal mengambil data tindakan: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty list instead of throwing, agar UI tidak crash
      return [];
    }
  }


   // ========================
  // CHECKOUT ENDPOINTS
  // ========================

  /// Estimasi ongkir berdasarkan lokasi customer
  static Future<Map<String, dynamic>> estimateShipping({
    required double customerLat,
    required double customerLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkout/estimate-shipping'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_lat': customerLat,
          'customer_lng': customerLng,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Gagal menghitung ongkir');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Buat order baru
  static Future<Map<String, dynamic>> createCheckoutOrder({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String paymentMethod,
    required String deliveryAddress,
    required double customerLat,
    required double customerLng,
    String? voucherCode,
    double? voucherDiscount,
    bool isPointExchange = false,      // ✅ NEW optional parameter
    int pointsUsed = 0,                 // ✅ NEW optional parameter
    double shippingCost = 0.0,
  }) async {
    try {
      // ✅ FIXED: Use correct field names
      final body = {
        'id_costomer': customerId,       // ✅ Changed from 'customerId'
        'items': items.map((item) {
          // ✅ Ensure items use 'price' instead of 'harga'
          return {
            'kode_barang': item['kode_barang'],
            'nama_produk': item['nama_produk'],
            'price': item['price'] ?? item['harga'] ?? 0,  // ✅ Support both
            'quantity': item['quantity'],
          };
        }).toList(),
        'total_price': totalPrice,
        'payment_method': paymentMethod,
        'delivery_address': deliveryAddress,
        'customer_lat': customerLat,
        'customer_lng': customerLng,
        'voucher_discount': voucherDiscount ?? 0.0,
        'shipping_cost': shippingCost,
        'expedition_type': 'pribadi',
      };

      // ✅ Add point exchange fields if applicable
      if (isPointExchange) {
        body['is_point_exchange'] = true;
        body['points_used'] = pointsUsed;
      }

      debugPrint('📤 [createCheckoutOrder] Payload: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/checkout/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('📥 [createCheckoutOrder] Status: ${response.statusCode}');
      debugPrint('📥 [createCheckoutOrder] Response: ${response.body}');

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('❌ [createCheckoutOrder] Error: $e');
      return {
        'success': false,
        'message': 'Gagal menghubungi server: $e',
      };
    }
  }

  /// Update status pembayaran
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required String orderCode,
    required String paymentStatus,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/checkout/update-payment/$orderCode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'payment_status': paymentStatus}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal update status pembayaran: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update status pengiriman
  static Future<Map<String, dynamic>> updateDeliveryStatus({
    required String orderCode,
    required String deliveryStatus,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/checkout/update-delivery/$orderCode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'delivery_status': deliveryStatus}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal update status pengiriman: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update order payment status after Midtrans payment
  /// Endpoint: PUT /api/checkout/update-payment-status/{orderCode}
  static Future<Map<String, dynamic>> updateOrderPaymentStatus({
    required String orderCode,
    required String status,  // 'paid', 'pending', 'failed', 'cancelled'
  }) async {
    try {
      // ✅ Endpoint yang benar
      final url = '${baseUrl}/checkout/update-payment-status/$orderCode';

      final body = {
        'status': status,
      };

      debugPrint('📤 [updateOrderPaymentStatus] URL: $url');
      debugPrint('📤 [updateOrderPaymentStatus] Body: ${jsonEncode(body)}');

      final response = await http.put(  // ✅ Method PUT
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('📥 [updateOrderPaymentStatus] Status: ${response.statusCode}');
      debugPrint('📥 [updateOrderPaymentStatus] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to update payment status',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ [updateOrderPaymentStatus] Error: $e');
      return {
        'success': false,
        'message': 'Gagal update status pembayaran: $e',
      };
    }
  }

  /// Sync payment status with Midtrans
  /// Endpoint: POST /api/payment/sync-update
  static Future<Map<String, dynamic>> syncPaymentStatus({
    required String orderId,
  }) async {
    try {
      final url = '${baseUrl}/payment/sync-update';

      final body = {
        'order_id': orderId,
      };

      debugPrint('📤 [syncPaymentStatus] URL: $url');
      debugPrint('📤 [syncPaymentStatus] Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('📥 [syncPaymentStatus] Status: ${response.statusCode}');
      debugPrint('📥 [syncPaymentStatus] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Sync failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ [syncPaymentStatus] Error: $e');
      return {
        'success': false,
        'message': 'Gagal sync status: $e',
      };
    }
  }

  /// Update checkout order
  static Future<Map<String, dynamic>> updateCheckoutOrder(String orderCode, Map<String, dynamic> updates) async {
    try {
      debugPrint('Update checkout order payload: $updates');
      final response = await http.put(
        Uri.parse('$baseUrl/checkout/update-order/$orderCode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Gagal update order');
        }
      } else {
        throw Exception('Gagal update checkout order: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get order by order code
  static Future<Map<String, dynamic>> getOrderByCode(String orderCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkout/order/$orderCode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Order tidak ditemukan');
        }
      } else {
        throw Exception('Gagal mengambil data order: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get orders by customer
  static Future<List<dynamic>> getCustomerOrders(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkout/customer-orders/$customerId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil data orders');
        }
      } else {
        throw Exception('Gagal mengambil data orders customer');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all orders (admin)
  static Future<List<dynamic>> getAllOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkout/all-orders'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil data orders');
        }
      } else {
        throw Exception('Gagal mengambil semua orders');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create checkout order for point exchange
  /// - total_price = 0 (paid with points)
  /// - points_used = actual points deducted
  /// - shipping_cost = needs to be paid via Midtrans (if any)
  static Future<Map<String, dynamic>> createCheckoutOrderWithPoints({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double customerLat,
    required double customerLng,
    required int pointsUsed,
    double shippingCost = 0.0,
  }) async {
    try {
      final url = '${baseUrl}/checkout/create-order';

      final body = {
        'id_costomer': customerId,
        'items': items,
        'total_price': 0,  // ✅ Harga produk = 0 karena dibayar dengan poin
        'payment_method': 'points',
        'delivery_address': deliveryAddress,
        'customer_lat': customerLat,
        'customer_lng': customerLng,
        'is_point_exchange': true,
        'points_used': pointsUsed,  // ✅ Poin yang digunakan
        'shipping_cost': shippingCost,  // ✅ Ongkir yang perlu dibayar (jika ada)
        'expedition_type': 'pribadi',
      };

      debugPrint('📤 [createCheckoutOrderWithPoints] URL: $url');
      debugPrint('📤 [createCheckoutOrderWithPoints] Payload: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('📥 [createCheckoutOrderWithPoints] Status: ${response.statusCode}');
      debugPrint('📥 [createCheckoutOrderWithPoints] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == null) {
          data['success'] = true;
        }
        return data;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Server error: ${response.statusCode}',
            'errors': errorData['errors'],
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ [createCheckoutOrderWithPoints] Error: $e');
      return {
        'success': false,
        'message': 'Gagal menghubungi server: $e',
      };
    }
  }

  /// Get expedition zones
  static Future<List<dynamic>> getExpeditionZones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkout/expedition-zones'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil data zona');
        }
      } else {
        throw Exception('Gagal mengambil data zona ekspedisi');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Validasi voucher
  static Future<Map<String, dynamic>> validateVoucher({
    required String voucherCode,
    required String customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkout/validate-voucher'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'voucherCode': voucherCode,
          'id_costomer': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal validasi voucher: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // VOUCHER ENDPOINTS
  static Future<List<dynamic>> getVouchers() async {
    final response = await http.get(Uri.parse('$baseUrl/vouchers?status=all'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Handle various response formats
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is List) {
          return data['data'] as List<dynamic>;
        } else if (data.containsKey('data') && data['data'] is List) {
          return data['data'] as List<dynamic>;
        } else {
          return [];
        }
      } else if (data is List) {
        return data;
      } else {
        return [];
      }
    } else {
      throw Exception('Gagal memuat data voucher');
    }
  }

  /// Mark voucher as used after successful payment
  static Future<Map<String, dynamic>> markVoucherUsed(String voucherCode, String customerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkout/mark-voucher-used'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'voucherCode': voucherCode,
          'id_costomer': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal menandai voucher sebagai digunakan: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> claimVoucher(String customerId, int voucherId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-voucher'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_costomer': customerId,
          'voucher_id': voucherId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        // Try to parse error message from response body
        String errorMessage = 'Gagal claim voucher';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        } catch (_) {
          // If can't parse, use default
        }
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getUserVouchers(String customerId) async {
    final response = await http.get(Uri.parse('$baseUrl/user-vouchers/$customerId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat voucher user');
    }
  }

  /// Update user voucher status (mark as used)
  static Future<Map<String, dynamic>> updateUserVoucher(int userVoucherId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user-voucher/$userVoucherId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Gagal update user voucher');
        }
      } else {
        throw Exception('Gagal update user voucher: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
