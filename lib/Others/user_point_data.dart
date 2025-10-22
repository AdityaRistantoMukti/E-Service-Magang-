import 'package:flutter/foundation.dart';

class UserPointData {
  static ValueNotifier<int> userPoints = ValueNotifier<int>(0);

  static void addPoints(int points) {
    userPoints.value += points;
  }

  static void setPoints(int points) {
    userPoints.value = points;
  }

  static int get currentPoints => userPoints.value;
}
