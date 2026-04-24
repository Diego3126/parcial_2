import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrlAccidentes =>
      dotenv.env['BASE_URL_ACCIDENTES'] ?? '';
  static String get baseUrlParqueadero =>
      dotenv.env['BASE_URL_PARQUEADERO'] ?? '';
  static String get logoBaseUrl =>
      'https://parking.visiontic.com.co/storage/';
}