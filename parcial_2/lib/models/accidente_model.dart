class Accidente {
  final String anio;
  final String dia;
  final String hora;
  final String area;
  final String barrioHecho;
  final String claseDeAccidente;
  final String gravedadDelAccidente;
  final String claseDeVehiculo;

  Accidente({
    required this.anio,
    required this.dia,
    required this.hora,
    required this.area,
    required this.barrioHecho,
    required this.claseDeAccidente,
    required this.gravedadDelAccidente,
    required this.claseDeVehiculo,
  });

  factory Accidente.fromJson(Map<String, dynamic> json) {
    return Accidente(
      anio:                 json['a_o']                   ?? '',
      dia:                  json['dia']                   ?? '',
      hora:                 json['hora']                  ?? '',
      area:                 json['area']                  ?? '',
      barrioHecho:          json['barrio_hecho']          ?? 'No informa',
      claseDeAccidente:     json['clase_de_accidente']    ?? 'Otros',
      gravedadDelAccidente: json['gravedad_del_accidente'] ?? '',
      claseDeVehiculo:      json['clase_de_vehiculo']     ?? '',
    );
  }
}