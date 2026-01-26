import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/feedback_detail_screen.dart';

/// 自動匿名ログイン状態
final autoSignInProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);

  // 既にログイン済みならtrue
  if (auth.currentUser != null) {
    return true;
  }

  // 匿名ログイン実行
  try {
    await auth.signInAnonymously();
    return true;
  } catch (e) {
    return false;
  }
});

/// アプリケーションルーター
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _AutoSignInWrapper(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return FeedbackScreen(ideaData: extra);
        },
      ),
      GoRoute(
        path: '/feedback/detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return FeedbackDetailScreen(
            originalFeedback: extra['content'] ?? '',
            ideaData: extra['ideaData'],
            personaId: extra['personaId'],
          );
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Error Occurred',
                  style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
  );
});

/// 自動サインインラッパー
class _AutoSignInWrapper extends ConsumerWidget {
  const _AutoSignInWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSignIn = ref.watch(autoSignInProvider);

    return autoSignIn.when(
      loading:
          () => const Scaffold(
            backgroundColor: Color(0xFFF5F5F7),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4A4A4A)),
                  SizedBox(height: 24),
                  Text(
                    'SCLUP',
                    style: TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
      error:
          (e, _) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F7),
            body: Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Color(0xFF4A4A4A)),
              ),
            ),
          ),
      data: (success) {
        if (success) {
          return const HomeScreen();
        }
        return const Scaffold(
          backgroundColor: Color(0xFFF5F5F7),
          body: Center(
            child: Text(
              'Login Failed',
              style: TextStyle(color: Color(0xFF4A4A4A)),
            ),
          ),
        );
      },
    );
  }
}
