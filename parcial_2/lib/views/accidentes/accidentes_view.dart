import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../isolates/accidentes_isolate.dart';
import '../../models/estadisticas_model.dart';
import '../../services/accidentes_service.dart';
import '../../widgets/estado_widget.dart';

class AccidentesView extends StatefulWidget {
  const AccidentesView({super.key});

  @override
  State<AccidentesView> createState() => _AccidentesViewState();
}

class _AccidentesViewState extends State<AccidentesView> {
  bool _cargando = true;
  String? _error;
  EstadisticasAccidentes? _stats;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final accidentes = await AccidentesService().getAll();
      final stats = await compute(calcularEstadisticas, accidentes);
      if (!mounted) return;
      setState(() { _stats = stats; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas de Accidentes')),
      body: EstadoWidget(
        cargando: false,
        error: _error,
        onReintentar: _cargar,
        hijo: Skeletonizer(
          enabled: _cargando,
          child: _stats == null
              ? _buildSkeleton()
              : _buildGraficas(),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(4, (_) => Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      )),
    );
  }

  Widget _buildGraficas() {
    final s = _stats!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tituloTotal(s.total),
        const SizedBox(height: 16),
        _GraficaCard(
          titulo: '1. Distribución por Clase de Accidente',
          child: _PieChartWidget(data: s.porClase),
        ),
        const SizedBox(height: 16),
        _GraficaCard(
          titulo: '2. Distribución por Gravedad',
          child: _PieChartWidget(data: s.porGravedad),
        ),
        const SizedBox(height: 16),
        _GraficaCard(
          titulo: '3. Top 5 Barrios con más Accidentes',
          child: _BarChartWidget(data: s.topBarrios),
        ),
        const SizedBox(height: 16),
        _GraficaCard(
          titulo: '4. Distribución por Día de la Semana',
          child: _BarChartWidget(data: s.porDia),
        ),
      ],
    );
  }

  Widget _tituloTotal(int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.car_crash, color: Colors.red, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$total',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              const Text('Total de accidentes procesados',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GraficaCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _GraficaCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  final Map<String, int> data;
  const _PieChartWidget({required this.data});

  static const List<Color> _colors = [
    Color(0xFF1565C0), Color(0xFFE53935), Color(0xFF43A047),
    Color(0xFFFB8C00), Color(0xFF8E24AA), Color(0xFF00ACC1),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total   = data.values.fold(0, (a, b) => a + b);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: List.generate(entries.length, (i) {
                final pct = total > 0
                    ? (entries[i].value / total * 100).toStringAsFixed(1)
                    : '0';
                return PieChartSectionData(
                  value:     entries[i].value.toDouble(),
                  color:     _colors[i % _colors.length],
                  title:     '$pct%',
                  titleStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: Colors.white),
                  radius: 70,
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: List.generate(entries.length, (i) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 12, height: 12,
                  color: _colors[i % _colors.length]),
              const SizedBox(width: 4),
              Text('${entries[i].key} (${entries[i].value})',
                  style: const TextStyle(fontSize: 11)),
            ],
          )),
        ),
      ],
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final Map<String, int> data;
  const _BarChartWidget({required this.data});

  static const List<Color> _colors = [
    Color(0xFF1565C0), Color(0xFFE53935), Color(0xFF43A047),
    Color(0xFFFB8C00), Color(0xFF8E24AA), Color(0xFF00ACC1),
    Color(0xFF6D4C41),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxVal  = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxVal.toDouble() * 1.2,
              barGroups: List.generate(entries.length, (i) =>
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: entries[i].value.toDouble(),
                    color: _colors[i % _colors.length],
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ]),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (val, _) => Text(
                      val.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox();
                      }
                      final label = entries[idx].key;
                      final short = label.length > 8
                          ? '${label.substring(0, 7)}.'
                          : label;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(short,
                            style: const TextStyle(fontSize: 9)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: List.generate(entries.length, (i) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 12, height: 12,
                  color: _colors[i % _colors.length]),
              const SizedBox(width: 4),
              Text('${entries[i].key}: ${entries[i].value}',
                  style: const TextStyle(fontSize: 11)),
            ],
          )),
        ),
      ],
    );
  }
}