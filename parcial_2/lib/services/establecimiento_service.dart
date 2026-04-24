import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/establecimiento_model.dart';

class EstablecimientoService {
  final Dio _dio = Dio();
  String get _base => AppConfig.baseUrlParqueadero;

  Future<List<Establecimiento>> getAll() async {
    final response = await _dio.get('$_base/establecimientos');
    if (response.statusCode == 200) {
      final List data = response.data['data'];
      return data.map((e) => Establecimiento.fromJson(e)).toList();
    }
    throw Exception('Error al cargar establecimientos');
  }

  Future<Establecimiento> getById(int id) async {
    final response = await _dio.get('$_base/establecimientos/$id');
    if (response.statusCode == 200) {
      return Establecimiento.fromJson(response.data['data']);
    }
    throw Exception('Error al cargar establecimiento');
  }

  Future<void> crear({
    required String nombre,
    required String nit,
    required String direccion,
    required String telefono,
    File? logo,
  }) async {
    final formData = FormData.fromMap({
      'nombre':    nombre,
      'nit':       nit,
      'direccion': direccion,
      'telefono':  telefono,
      if (logo != null)
        'logo': await MultipartFile.fromFile(
          logo.path,
          filename: logo.path.split('/').last,
        ),
    });
    await _dio.post('$_base/establecimientos', data: formData);
  }

  Future<void> editar({
    required int id,
    required String nombre,
    required String nit,
    required String direccion,
    required String telefono,
    File? logo,
  }) async {
    final formData = FormData.fromMap({
      '_method':   'PUT',
      'nombre':    nombre,
      'nit':       nit,
      'direccion': direccion,
      'telefono':  telefono,
      if (logo != null)
        'logo': await MultipartFile.fromFile(
          logo.path,
          filename: logo.path.split('/').last,
        ),
    });
    await _dio.post('$_base/establecimiento-update/$id', data: formData);
  }

  Future<void> eliminar(int id) async {
    await _dio.delete('$_base/establecimientos/$id');
  }
}