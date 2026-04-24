import '../models/accidente_model.dart';
import '../models/estadisticas_model.dart';

EstadisticasAccidentes calcularEstadisticas(List<Accidente> accidentes) {
  final inicio = DateTime.now();
  print('[Isolate] Iniciado — ${accidentes.length} registros recibidos');

  // 1. Por clase de accidente
  final porClase = <String, int>{};
  // 2. Por gravedad
  final porGravedad = <String, int>{};
  // 3. Por barrio
  final porBarrio = <String, int>{};
  // 4. Por día
  final porDia = <String, int>{};

  for (final a in accidentes) {
    // Clase
    final clase = _normalizarClase(a.claseDeAccidente);
    porClase[clase] = (porClase[clase] ?? 0) + 1;

    // Gravedad
    final gravedad = _normalizarGravedad(a.gravedadDelAccidente);
    porGravedad[gravedad] = (porGravedad[gravedad] ?? 0) + 1;

    // Barrio
    final barrio = a.barrioHecho.trim().toUpperCase();
    if (barrio.isNotEmpty && barrio != 'NO INFORMA' && barrio != 'NO INFORMAR') {
      porBarrio[barrio] = (porBarrio[barrio] ?? 0) + 1;
    }

    // Día
    final dia = _normalizarDia(a.dia);
    porDia[dia] = (porDia[dia] ?? 0) + 1;
  }

  // Top 5 barrios
  final sorted = porBarrio.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top5 = Map<String, int>.fromEntries(sorted.take(5));

  final ms = DateTime.now().difference(inicio).inMilliseconds;
  print('[Isolate] Completado en $ms ms');

  return EstadisticasAccidentes(
    porClase:   porClase,
    porGravedad: porGravedad,
    topBarrios:  top5,
    porDia:      porDia,
    total:       accidentes.length,
  );
}

String _normalizarClase(String clase) {
  final c = clase.trim().toUpperCase();
  if (c.contains('CHOQUE'))       return 'Choque';
  if (c.contains('ATROPELLO'))    return 'Atropello';
  if (c.contains('VOLCAMIENTO'))  return 'Volcamiento';
  if (c.contains('INCENDIO'))     return 'Incendio';
  if (c.contains('CAIDA'))        return 'Caída';
  return 'Otros';
}

String _normalizarGravedad(String gravedad) {
  final g = gravedad.trim().toUpperCase();
  if (g.contains('MUERTO'))  return 'Con muertos';
  if (g.contains('HERIDO'))  return 'Con heridos';
  if (g.contains('DAÑO') || g.contains('DANO')) return 'Solo daños';
  return 'Sin información';
}

String _normalizarDia(String dia) {
  final d = dia.trim().toLowerCase();
  const dias = {
    'lunes': 'Lunes', 'martes': 'Martes', 'miercoles': 'Miércoles',
    'miércoles': 'Miércoles', 'jueves': 'Jueves', 'viernes': 'Viernes',
    'sabado': 'Sábado', 'sábado': 'Sábado', 'domingo': 'Domingo',
  };
  return dias[d] ?? dia;
}