import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';
import 'package:warehouse_app/data/models/user_model.dart';
import 'package:warehouse_app/presentation/providers/auth_provider.dart';
import 'package:warehouse_app/presentation/screens/add_product_screen.dart';
import 'package:warehouse_app/presentation/screens/auth_screen.dart';
import 'package:warehouse_app/presentation/screens/product_detail_screen.dart';
import 'package:warehouse_app/presentation/screens/product_operation_screen.dart';
import 'package:warehouse_app/presentation/screens/products_screen.dart';
import 'package:warehouse_app/presentation/screens/qr_product_screen.dart';
import 'package:warehouse_app/presentation/screens/register_screen.dart';
import 'package:warehouse_app/presentation/screens/scan_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final loggedInUser =
      authState is AuthSuccess ? authState.user : null;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublic = path == '/' || path == '/register';
      final isQRPath = path.startsWith('/qr/');
      final loggedIn = isLoggedInUser(loggedInUser);
      final userRole = loggedIn ? loggedInUser!.role : '';

      if (!loggedIn && !isPublic && !isQRPath) return '/';
      if (loggedIn && isPublic) return '/products';

      if (loggedIn &&
          path == '/add-product' &&
          userRole != AppConstants.adminRole) {
        return '/products';
      }

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
      GoRoute(
        path: '/qr/:code',
        builder: (context, state) =>
            QRProductScreen(encodedQr: state.pathParameters['code']!),
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

bool isLoggedInUser(UserModel? user) {
  return user != null;
}

