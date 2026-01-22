import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';

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
    ],
    errorBuilder:
        (context, state) => Scaffold(
          backgroundColor: const Color(0xFF1a1a2e),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'エラーが発生しました',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('再試行'),
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
            backgroundColor: Color(0xFF1a1a2e),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 24),
                  Text(
                    'Thinker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      error:
          (e, _) => Scaffold(
            backgroundColor: const Color(0xFF1a1a2e),
            body: Center(
              child: Text(
                'エラー: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      data: (success) {
        if (success) {
          return const HomeScreen();
        }
        return const Scaffold(
          backgroundColor: Color(0xFF1a1a2e),
          body: Center(
            child: Text('ログインに失敗しました', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}
