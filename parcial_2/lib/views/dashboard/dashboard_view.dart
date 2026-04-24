import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/accidentes_service.dart';
import '../../services/establecimiento_service.dart';
import '../../themes/app_theme.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _cargando = true;
  int _totalAccidentes = 0;
  int _totalEstablecimientos = 0;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    setState(() => _cargando = true);
    try {
      final accidentes = await AccidentesService().getAll();
      final establecimientos = await EstablecimientoService().getAll();
      if (!mounted) return;
      setState(() {
        _totalAccidentes = accidentes.length;
        _totalEstablecimientos = establecimientos.length;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🚦 Parcial Flutter')),
      body: RefreshIndicator(
        onRefresh: _cargarResumen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Panel Principal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Selecciona un módulo para comenzar',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // Tarjetas de resumen
              Skeletonizer(
                enabled: _cargando,
                child: Row(
                  children: [
                    Expanded(
                      child: _ResumenCard(
                        titulo: 'Accidentes',
                        valor: '$_totalAccidentes',
                        icono: Icons.car_crash,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResumenCard(
                        titulo: 'Establecimientos',
                        valor: '$_totalEstablecimientos',
                        icono: Icons.store,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text('Módulos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Card Accidentes
              _ModuloCard(
                titulo: 'Estadísticas de Accidentes',
                subtitulo: 'Visualiza 4 gráficas procesadas con Isolate\ndesde Datos Abiertos Colombia',
                icono: Icons.bar_chart,
                color: AppTheme.error,
                onTap: () => context.push('/accidentes'),
              ),
              const SizedBox(height: 12),

              // Card Establecimientos
              _ModuloCard(
                titulo: 'Gestión de Establecimientos',
                subtitulo: 'CRUD completo: crear, editar, eliminar\ny cargar logo desde galería',
                icono: Icons.store,
                color: AppTheme.primary,
                onTap: () => context.push('/establecimientos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(valor,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(titulo, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _ModuloCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icono, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitulo,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}