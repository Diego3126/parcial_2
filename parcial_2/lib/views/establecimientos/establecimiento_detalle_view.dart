import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../models/establecimiento_model.dart';
import '../../services/establecimiento_service.dart';
import '../../widgets/estado_widget.dart';

class EstablecimientoDetalleView extends StatefulWidget {
  final int id;
  const EstablecimientoDetalleView({super.key, required this.id});

  @override
  State<EstablecimientoDetalleView> createState() =>
      _EstablecimientoDetalleViewState();
}

class _EstablecimientoDetalleViewState
    extends State<EstablecimientoDetalleView> {
  bool _cargando = true;
  String? _error;
  Establecimiento? _item;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await EstablecimientoService().getById(widget.id);
      if (!mounted) return;
      setState(() { _item = data; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar establecimiento'),
        content: Text(
            '¿Estás seguro de eliminar "${_item?.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await EstablecimientoService().eliminar(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Establecimiento eliminado'),
            backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item?.nombre ?? 'Detalle'),
        actions: _item == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () async {
                    await context.push(
                        '/establecimientos/${widget.id}/editar');
                    _cargar();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar',
                  onPressed: _eliminar,
                ),
              ],
      ),
      body: EstadoWidget(
        cargando: _cargando,
        error: _error,
        onReintentar: _cargar,
        hijo: _item == null
            ? const SizedBox()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${AppConfig.logoBaseUrl}${_item!.logo}',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.store, size: 64,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _campo('Nombre',    _item!.nombre),
                    _campo('NIT',       _item!.nit),
                    _campo('Dirección', _item!.direccion),
                    _campo('Teléfono',  _item!.telefono),
                    _campo('Estado',
                        _item!.estado == 'A' ? 'Activo' : 'Inactivo'),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _campo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }
}