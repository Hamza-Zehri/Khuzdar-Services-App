import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'shared/theme/app_theme.dart';
import 'core/models/user_model.dart';
import 'providers/auth_provider.dart';
import 'features/auth/screens/phone_entry_screen.dart';
import 'features/auth/screens/email_login_screen.dart';
import 'features/auth/screens/register_credentials_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/providers/screens/provider_dashboard_screen.dart';
import 'features/providers/screens/provider_list_screen.dart';
import 'features/providers/screens/provider_register_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/screens/inbox_screen.dart';
import 'features/rating/screens/rate_screen.dart';
import 'features/auth/screens/blocked_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

class KhuzdarMarketplaceApp extends StatelessWidget {
  const KhuzdarMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Khuzdar Services',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _router(context),
    );
  }

  GoRouter _router(BuildContext context) {
    return GoRouter(
      initialLocation: '/home',
      redirect: (context, state) {
        final auth = context.read<AuthAppProvider>();
        final isLoggedIn = auth.isLoggedIn;
        final hasProfile = auth.hasProfile;
        final loc = state.matchedLocation;

        // Public routes (Home and Provider List)
        if (loc == '/home' || loc.startsWith('/providers/')) {
          return null;
        }

        // Auth flow routes
        if (!isLoggedIn && (loc == '/login' || loc.startsWith('/auth/') || loc == '/provider/register')) {
          return null;
        }

        if (!isLoggedIn) return '/login';
        
        // Blocking enforcement
        if (isLoggedIn && auth.user?.isBlocked == true && loc != '/blocked') {
          return '/blocked';
        }

        // If logged in but no profile, redirect to role selection
        if (isLoggedIn && !hasProfile && loc != '/auth/role' && loc != '/provider/register' && loc != '/blocked') {
          return '/auth/role';
        }

        // Admin route protection
        if (loc == '/admin' && auth.user?.role != UserRole.admin) {
          return '/home';
        }
        
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const EmailLoginScreen()),
        GoRoute(path: '/auth/phone', builder: (_, state) {
          final data = state.extra as Map<String, String>? ?? {};
          return PhoneEntryScreen(registrationData: data);
        }),
        GoRoute(path: '/auth/otp', builder: (_, state) {
          final data = state.extra as Map<String, String>? ?? {};
          return OtpScreen(registrationData: data);
        }),
        GoRoute(path: '/auth/register', builder: (_, __) => const RegisterCredentialsScreen()),
        GoRoute(path: '/auth/role', builder: (_, __) => const RoleSelectionScreen()),
        GoRoute(
          path: '/home',
          builder: (context, __) {
            final auth = context.watch<AuthAppProvider>();
            if (auth.isProviderMode && auth.user?.role == UserRole.provider) {
              return const ProviderDashboardScreen();
            }
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/providers/:category',
          builder: (_, state) =>
              ProviderListScreen(category: state.pathParameters['category']!),
        ),
        GoRoute(path: '/provider/register', builder: (_, __) => const ProviderRegisterScreen()),
        GoRoute(
          path: '/chat/:chatId',
          builder: (_, state) => ChatScreen(chatId: state.pathParameters['chatId']!),
        ),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const InboxScreen()),
        GoRoute(path: '/blocked', builder: (_, __) => const BlockedScreen()),
        GoRoute(
          path: '/rate/:jobId',
          builder: (_, state) => RateScreen(jobId: state.pathParameters['jobId']!),
        ),
      ],
    );
  }
}
