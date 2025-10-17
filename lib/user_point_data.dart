import 'package:flutter/foundation.dart';

class UserPointData {
  // Simpan poin user
  static ValueNotifier<int> userPoints = ValueNotifier<int>(25);

  // Tambah poin (misalnya dari hasil scan QR)
  static void addPoints(int points) {
    userPoints.value += points;
  }

  // Set poin (kalau nanti dari database)
  static void setPoints(int points) {
    userPoints.value = points;
  }
}
