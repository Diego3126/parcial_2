import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/establecimiento_model.dart';
import '../../services/establecimiento_service.dart';
import '../../config/app_config.dart';
import '../../widgets/estado_widget.dart';

class EstablecimientosView extends StatefulWidget {
  const EstablecimientosView({super.key});

  @override
  State<EstablecimientosView> createState() => _EstablecimientosViewState();
}

class _EstablecimientosViewState extends State<EstablecimientosView> {
  bool _cargando = true;
  String? _error;
  List<Establecimiento> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await EstablecimientoService().getAll();
      if (!mounted) return;
      setState(() { _items = data; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Establecimientos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/establecimientos/crear');
          _cargar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: EstadoWidget(
        cargando: false,
        error: _error,
        onReintentar: _cargar,
        hijo: Skeletonizer(
          enabled: _cargando,
          child: _cargando
              ? _buildSkeleton()
              : _buildLista(),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(8),
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: ListTile(
          leading: Container(
              width: 50, height: 50, color: Colors.grey.shade300),
          title: Container(
              height: 14, color: Colors.grey.shade300),
          subtitle: Container(
              height: 12, color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay establecimientos registrados',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        itemCount: _items.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final e = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${AppConfig.logoBaseUrl}${e.logo}',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50, height: 50,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
              ),
              title: Text(e.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('NIT: ${e.nit}\n${e.direccion}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await context.push('/establecimientos/${e.id}');
                _cargar();
              },
            ),
          );
        },
      ),
    );
  }
}