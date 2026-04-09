import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'shared/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'features/auth/screens/phone_entry_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/providers/screens/provider_list_screen.dart';
import 'features/providers/screens/provider_register_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/screens/inbox_screen.dart';
import 'features/rating/screens/rate_screen.dart';

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
      initialLocation: '/auth/phone',
      redirect: (context, state) {
        final auth = context.read<AuthAppProvider>();
        final isLoggedIn = auth.isLoggedIn;
        final hasProfile = auth.hasProfile;

        // Public routes
        if (!isLoggedIn && (state.matchedLocation == '/auth/phone' || state.matchedLocation == '/auth/otp')) {
          return null;
        }

        if (!isLoggedIn) return '/auth/phone';
        
        // If logged in but no profile, redirect to role selection
        if (isLoggedIn && !hasProfile && state.matchedLocation != '/auth/role' && state.matchedLocation != '/provider/register') {
          return '/auth/role';
        }
        
        return null;
      },
      routes: [
        GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneEntryScreen()),
        GoRoute(path: '/auth/otp', builder: (_, __) => const OtpScreen()),
        GoRoute(path: '/auth/role', builder: (_, __) => const RoleSelectionScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
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
        GoRoute(path: '/notifications', builder: (_, __) => const InboxScreen()),
        GoRoute(
          path: '/rate/:jobId',
          builder: (_, state) => RateScreen(jobId: state.pathParameters['jobId']!),
        ),
      ],
    );
  }
}
