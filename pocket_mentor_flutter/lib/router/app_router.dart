import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/learn_feed_screen.dart';
import '../screens/revision/revision_screen.dart';
import '../screens/interview/interview_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../utils/constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _fade(const LoginScreen());
      case AppRoutes.register:
        return _fade(const RegisterScreen());
      case AppRoutes.home:
        return _fade(const HomeScreen());
      case AppRoutes.learn:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slide(LearnFeedScreen(topicId: args?['topicId'] as String?));
      case AppRoutes.revision:
        return _slide(const RevisionScreen());
      case AppRoutes.interview:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slide(InterviewScreen(
          topicId: args?['topicId'] as String?,
          difficulty: args?['difficulty'] as int?,
        ));
      case AppRoutes.notes:
        return _slide(const NotesScreen());
      case AppRoutes.profile:
        return _slide(const ProfileScreen());
      default:
        return _fade(const LoginScreen());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: anim.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }
        return child;
      },
    );
  }
}
