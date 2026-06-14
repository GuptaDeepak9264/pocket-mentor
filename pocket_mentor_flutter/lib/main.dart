import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/topic_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/upload_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Bootstrap services
  final storage = await StorageService.getInstance();
  final api = await ApiService.getInstance();

  runApp(PocketMentorApp(api: api, storage: storage));
}

class PocketMentorApp extends StatelessWidget {
  final ApiService api;
  final StorageService storage;

  const PocketMentorApp({
    super.key,
    required this.api,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(api: api, storage: storage),
        ),
        ChangeNotifierProvider(
          create: (_) => TopicProvider(api: api),
        ),
        ChangeNotifierProvider(
          create: (_) => LearnFeedProvider(api: api),
        ),
        ChangeNotifierProvider(
          create: (_) => RevisionFeedProvider(api: api),
        ),
        ChangeNotifierProvider(
          create: (_) => InterviewFeedProvider(api: api),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(api: api),
        ),
        ChangeNotifierProvider(
          create: (_) => UploadProvider(api: api),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    // Check auth on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Mentor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.generateRoute,
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _SplashScreen();
          case AuthStatus.authenticated:
            return const _HomeRedirect();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const _LoginRedirect();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pocket Mentor',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Learn smarter, not harder',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeRedirect extends StatefulWidget {
  const _HomeRedirect();

  @override
  State<_HomeRedirect> createState() => _HomeRedirectState();
}

class _HomeRedirectState extends State<_HomeRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) => const _SplashScreen();
}

class _LoginRedirect extends StatefulWidget {
  const _LoginRedirect();

  @override
  State<_LoginRedirect> createState() => _LoginRedirectState();
}

class _LoginRedirectState extends State<_LoginRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) => const _SplashScreen();
}
