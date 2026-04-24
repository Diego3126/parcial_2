class Establecimiento {
  final int    id;
  final String nombre;
  final String nit;
  final String direccion;
  final String telefono;
  final String logo;
  final String estado;

  Establecimiento({
    required this.id,
    required this.nombre,
    required this.nit,
    required this.direccion,
    required this.telefono,
    required this.logo,
    required this.estado,
  });

  factory Establecimiento.fromJson(Map<String, dynamic> json) {
    return Establecimiento(
      id:        json['id']        ?? 0,
      nombre:    json['nombre']    ?? '',
      nit:       json['nit']       ?? '',
      direccion: json['direccion'] ?? '',
      telefono:  json['telefono']  ?? '',
      logo:      json['logo']      ?? 'sin-imagen.png',
      estado:    json['estado']    ?? 'A',
    );
  }
}