import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/screens/add_product_screen.dart';
import 'package:warehouse_app/presentation/screens/auth_screen.dart';
import 'package:warehouse_app/presentation/screens/product_detail_screen.dart';
import 'package:warehouse_app/presentation/screens/product_operation_screen.dart';
import 'package:warehouse_app/presentation/screens/products_screen.dart';
import 'package:warehouse_app/presentation/screens/qr_product_screen.dart';
import 'package:warehouse_app/presentation/screens/register_screen.dart';
import 'package:warehouse_app/presentation/screens/scan_screen.dart';

/// Мост «состояние Riverpod → перепроверка маршрутов».
///
/// Роутер создаётся ОДИН раз. Если бы он пересоздавался при каждом изменении
/// авторизации, `MaterialApp.router` получил бы новый конфиг и навигационный
/// стек сбрасывался бы. Вместо этого [GoRouter.refreshListenable] заставляет
/// роутер просто заново выполнить `redirect` для текущего адреса.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshNotifier();

  ref.listen<AuthState>(authStateProvider, (previous, next) {
    refreshListenable.refresh();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final user = authState is AuthSuccess ? authState.user : null;

      const publicPaths = <String>{'/', '/register'};
      final path = state.uri.path;
      final isQrPath = path == '/qr' || path.startsWith('/qr/');
      final isAdmin = user?.role == AppConstants.adminRole;

      // Не авторизован: пускаем только на логин/регистрацию и на страницу QR
      // (отсканировал ярлык другим телефоном — товар посмотреть можно).
      if (user == null && !publicPaths.contains(path) && !isQrPath) return '/';
      // Авторизован: с логина уводим в каталог.
      if (user != null && publicPaths.contains(path)) return '/products';
      // Добавление товаров доступно только администратору.
      if (path == '/add-product' && !isAdmin) return '/products';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product/:id/operation',
        builder: (context, state) =>
            ProductOperationScreen(productId: state.pathParameters['id']!),
      ),
      // Deep link вида /qr?code=<ссылка из QR-кода>.
      // Именно query-параметр, а не path-сегмент: `code` — целый URL
      // со слэшами и «?», в путь он не помещается.
      GoRoute(
        path: '/qr',
        builder: (context, state) =>
            QRProductScreen(encodedQr: state.uri.queryParameters['code'] ?? ''),
      ),
      GoRoute(
        path: '/add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanScreen(),
      ),
    ],
  );
});
