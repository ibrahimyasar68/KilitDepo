import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/about_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/setup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/generator/presentation/generator_screen.dart';
import '../../features/guide/presentation/guide_screen.dart';
import '../../features/settings/presentation/backup_screen.dart';
import '../../features/settings/presentation/csv_import_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/vault/presentation/entry_detail_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/vault/presentation/entry_edit_screen.dart';
import '../../features/vault/presentation/password_history_screen.dart';
import '../../features/vault/presentation/security_report_screen.dart';
import '../../features/vault/presentation/vault_list_screen.dart';
import '../theme/page_transitions.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String setup = '/setup';
  static const String login = '/login';
  static const String about = '/about';
  static const String guide = '/guide';

  // Alt gezinme çubuğundaki sekmeler.
  static const String vault = '/vault';
  static const String generator = '/generator';
  static const String securityReport = '/report';
  static const String settings = '/settings';

  // Sekmelerin üzerine tam ekran açılan sayfalar.
  static const String backup = '/settings/backup';
  static const String csvImport = '/settings/import-csv';
  static const String changePassword = '/settings/change-password';
  static const String entryNew = '/entry/new';
  static String entryDetail(int id) => '/entry/$id';
  static String entryEdit(int id) => '/entry/$id/edit';
  static String entryHistory(int id) => '/entry/$id/history';

  /// Kasa kilitliyken de açılabilen sayfalar. Bu sayfalar hiçbir
  /// kasa verisine erişmez.
  static const Set<String> public = {about, guide};

  static const Set<String> _authFlow = {splash, setup, login};
}

/// Kimlik doğrulama durumuna göre yönlendirme kararı (test edilebilir).
@visibleForTesting
String? authRedirect(AuthStatus status, String location) {
  if (AppRoutes.public.contains(location)) return null;

  final target = switch (status) {
    AuthStatus.initializing || AuthStatus.error => AppRoutes.splash,
    AuthStatus.needsSetup => AppRoutes.setup,
    AuthStatus.locked => AppRoutes.login,
    AuthStatus.unlocked =>
      AppRoutes._authFlow.contains(location) ? AppRoutes.vault : null,
  };
  return target == location ? null : target;
}

final routerProvider = Provider<GoRouter>((ref) {
  final status = ValueNotifier<AuthStatus>(
    ref.read(authControllerProvider).status,
  );
  ref.listen(
    authControllerProvider.select((s) => s.status),
    (_, next) => status.value = next,
  );

  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: status,
    redirect: (context, state) =>
        authRedirect(status.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // Kasa açıkken: alt gezinme çubuklu ana iskelet. Her sekmenin kendi
      // gezinme yığını vardır (sekme değiştirince konum korunur).
      StatefulShellRoute(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        // Sekme değiştirirken solup belirme geçişi (yığınlar korunur).
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughBranches(
              currentIndex: shell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.vault,
                builder: (context, state) => const VaultListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.generator,
                builder: (context, state) => const GeneratorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.securityReport,
                builder: (context, state) => const SecurityReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'backup',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const BackupScreen(),
                  ),
                  GoRoute(
                    path: 'import-csv',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const CsvImportScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Kayıt sayfaları her sekmeden tam ekran açılır; geri dönünce aynı
      // sekmeye dönülür.
      GoRoute(
        path: AppRoutes.entryNew,
        builder: (context, state) => const EntryEditScreen(),
      ),
      GoRoute(
        path: '/entry/:id',
        builder: (context, state) => EntryDetailScreen(entryId: _idOf(state)),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => EntryEditScreen(entryId: _idOf(state)),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) =>
                PasswordHistoryScreen(entryId: _idOf(state)),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.guide,
        builder: (context, state) => const GuideScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    status.dispose();
  });
  return router;
});

/// Geçersiz id → -1 (ekran "kayıt bulunamadı" gösterir).
int _idOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
