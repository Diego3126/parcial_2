import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/accidente_model.dart';

class AccidentesService {
  final Dio _dio = Dio();

  Future<List<Accidente>> getAll() async {
    final url = '${AppConfig.baseUrlAccidentes}?\$limit=100000';
    final response = await _dio.get(url);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((e) => Accidente.fromJson(e)).toList();
    }
    throw Exception('Error al cargar accidentes');
  }
}