class ApiConfig {
  // Change this IP address when your server IP changes
  // Current: 192.168.1.13 - Update this to match your Laravel server IP
  // static const String serverIp = '192.168.1.13';
  static const String serverIp = '192.168.1.21';
  static const String serverPort = '8000';

  // API Base URLs
  static String get apiBaseUrl => 'http://$serverIp:$serverPort/api';
  static String get storageBaseUrl => 'http://$serverIp:$serverPort/storage/';
  static String get imageBaseUrl => 'http://$serverIp:$serverPort/storage/';

  // Webhook and other service URLs
  static String get webhookBaseUrl => 'http://$serverIp:$serverPort/api/payment/webhook';

  // Instructions for changing IP:
  // 1. Change the serverIp above to your new server IP
  // 2. Restart the Flutter app (hot reload may not pick up const changes)
  // 3. Make sure your Laravel server is running on the new IP:port
}
