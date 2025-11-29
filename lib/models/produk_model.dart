class Produk {
  final String kodeBarang;
  final String namaProduk;
  final int harga;
  final String? deskripsi;
  final String? gambar;
  final String? gambarUrl;

  Produk({
    required this.kodeBarang,
    required this.namaProduk,
    required this.harga,
    this.deskripsi,
    this.gambar,
    this.gambarUrl,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      kodeBarang: json['kodeBarang'],
      namaProduk: json['namaProduk'],
      harga: json['harga'] is int ? json['harga'] : int.parse(json['harga'].toString()),
      deskripsi: json['deskripsi'],
      gambar: json['gambar'],
      gambarUrl: json['gambarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kodeBarang': kodeBarang,
      'namaProduk': namaProduk,
      'harga': harga,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'gambarUrl': gambarUrl,
    };
  }
}
