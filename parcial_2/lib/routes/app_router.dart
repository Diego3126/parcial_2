import 'package:go_router/go_router.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/accidentes/accidentes_view.dart';
import '../views/establecimientos/establecimientos_view.dart';
import '../views/establecimientos/establecimiento_form_view.dart';
import '../views/establecimientos/establecimiento_detalle_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/accidentes',
      builder: (context, state) => const AccidentesView(),
    ),
    GoRoute(
      path: '/establecimientos',
      builder: (context, state) => const EstablecimientosView(),
    ),
    GoRoute(
      path: '/establecimientos/crear',
      builder: (context, state) => const EstablecimientoFormView(),
    ),
    GoRoute(
      path: '/establecimientos/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EstablecimientoDetalleView(id: id);
      },
    ),
    GoRoute(
      path: '/establecimientos/:id/editar',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EstablecimientoFormView(id: id);
      },
    ),
  ],
);