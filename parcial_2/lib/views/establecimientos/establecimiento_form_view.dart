import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/establecimiento_model.dart';
import '../../services/establecimiento_service.dart';

class EstablecimientoFormView extends StatefulWidget {
  final int? id;
  const EstablecimientoFormView({super.key, this.id});

  @override
  State<EstablecimientoFormView> createState() =>
      _EstablecimientoFormViewState();
}

class _EstablecimientoFormViewState extends State<EstablecimientoFormView> {
  final _formKey    = GlobalKey<FormState>();
  final _nombre     = TextEditingController();
  final _nit        = TextEditingController();
  final _direccion  = TextEditingController();
  final _telefono   = TextEditingController();

  File?            _logoFile;
  Establecimiento? _original;
  bool             _cargando  = false;
  bool             _guardando = false;

  bool get _esEdicion => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final data = await EstablecimientoService().getById(widget.id!);
      if (!mounted) return;
      setState(() {
        _original   = data;
        _nombre.text    = data.nombre;
        _nit.text       = data.nit;
        _direccion.text = data.direccion;
        _telefono.text  = data.telefono;
        _cargando   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      if (_esEdicion) {
        await EstablecimientoService().editar(
          id:        widget.id!,
          nombre:    _nombre.text.trim(),
          nit:       _nit.text.trim(),
          direccion: _direccion.text.trim(),
          telefono:  _telefono.text.trim(),
          logo:      _logoFile,
        );
      } else {
        await EstablecimientoService().crear(
          nombre:    _nombre.text.trim(),
          nit:       _nit.text.trim(),
          direccion: _direccion.text.trim(),
          telefono:  _telefono.text.trim(),
          logo:      _logoFile,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion
              ? 'Establecimiento actualizado'
              : 'Establecimiento creado'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _nit.dispose();
    _direccion.dispose();
    _telefono.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion
            ? 'Editar Establecimiento'
            : 'Nuevo Establecimiento'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de logo
                    GestureDetector(
                      onTap: _seleccionarImagen,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _logoFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_logoFile!,
                                    fit: BoxFit.cover))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Toca para seleccionar logo',
                                      style:
                                          TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nombre,
                      decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store)),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nit,
                      decoration: const InputDecoration(
                          labelText: 'NIT *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge)),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _direccion,
                      decoration: const InputDecoration(
                          labelText: 'Dirección *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on)),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _telefono,
                      decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_guardando
                          ? 'Guardando...'
                          : (_esEdicion ? 'Actualizar' : 'Crear')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}