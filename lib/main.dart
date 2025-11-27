import 'package:K_Skill/auth/signup_page.dart';
import 'package:K_Skill/screens/academics.dart';
import 'package:K_Skill/screens/discourse.dart';
import 'package:K_Skill/screens/games.dart';
import 'package:K_Skill/screens/welcome.dart';
import 'package:K_Skill/screens/splash_screen.dart';
import 'package:K_Skill/screens/widgets/help.dart';
import 'package:K_Skill/services/app_usage_tracker.dart';
import 'package:flutter/material.dart';
import 'package:K_Skill/assessment/assessment_screen.dart';
import 'package:K_Skill/assessment/listening_screen.dart';
import 'package:K_Skill/assessment/quiz_screen.dart';
import 'package:K_Skill/assessment/reading_screen.dart';
import 'package:K_Skill/auth/login_page.dart';
import 'package:K_Skill/screens/dashboard.dart';
import 'package:K_Skill/screens/levels.dart';
import 'package:K_Skill/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

final AppUsageTracker _usageTracker = AppUsageTracker(); 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start app usage tracking when app launches
  _usageTracker.startTracking();

  // Always start with splash screen
  runApp(const MyKSkillApp());
}

class MyKSkillApp extends StatefulWidget {
  const MyKSkillApp({super.key});

  @override
  State<MyKSkillApp> createState() => _MyKSkillAppState();
}

class _MyKSkillAppState extends State<MyKSkillApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop and sync usage time when app fully closes
    _usageTracker.stopTracking();
    AppUsageTracker.syncUsageToServer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Forward lifecycle changes to usage tracker
    _usageTracker.didChangeAppLifecycleState(state);

    final prefs = await SharedPreferences.getInstance();

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Clear last route when app closes or goes background
      await prefs.remove('lastRoute');

      // Sync usage time to backend every time app is paused
      await AppUsageTracker.syncUsageToServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Skill',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => LoginPage(),
        '/dashboard': (context) => const RouteAwareWrapper(
              routeName: '/dashboard',
              child: DashboardScreen(),
            ),
        '/profile': (context) =>
            RouteAwareWrapper(routeName: '/profile', child: ProfileScreen()),
        '/levels': (context) =>
            RouteAwareWrapper(routeName: '/levels', child: LevelsScreen()),
        '/reading': (context) => const RouteAwareWrapper(
              routeName: '/reading',
              child: ReadingScreen(),
            ),
        '/assessment': (context) => const RouteAwareWrapper(
              routeName: '/assessment',
              child: AssessmentScreen(),
            ),
        '/listening': (context) => const RouteAwareWrapper(
              routeName: '/listening',
              child: ListeningScreen(),
            ),
        '/quiz': (context) =>
            RouteAwareWrapper(routeName: '/quiz', child: QuizScreen()),
        '/discourse': (context) =>
            RouteAwareWrapper(routeName: '/discourse', child: Discourse()),
        '/games': (context) =>
            RouteAwareWrapper(routeName: '/games', child: GameScreen()),
        '/help': (context) =>
            RouteAwareWrapper(routeName: '/help', child: HelpScreen()),
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '/';

    switch (routeName) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case '/welcome':
        return MaterialPageRoute(
          builder: (_) => const WelcomePage(),
          settings: settings,
        );
      case '/signup':
        return MaterialPageRoute(
          builder: (_) => SignupPage(),
          settings: settings,
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => LoginPage(),
          settings: settings,
        );
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const RouteAwareWrapper(
            routeName: '/dashboard',
            child: DashboardScreen(),
          ),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) =>
              RouteAwareWrapper(routeName: '/profile', child: ProfileScreen()),
          settings: settings,
        );
      case '/levels':
        return MaterialPageRoute(
          builder: (_) => const RouteAwareWrapper(
            routeName: '/levels',
            child: LevelsScreen(),
          ),
          settings: settings,
        );
      case '/reading':
        return MaterialPageRoute(
          builder: (_) => const RouteAwareWrapper(
            routeName: '/reading',
            child: ReadingScreen(),
          ),
          settings: settings,
        );
      case '/assessment':
        return MaterialPageRoute(
          builder: (_) => const RouteAwareWrapper(
            routeName: '/assessment',
            child: AssessmentScreen(),
          ),
          settings: settings,
        );
      case '/quiz':
        return MaterialPageRoute(
          builder: (_) =>
              RouteAwareWrapper(routeName: '/quiz', child: QuizScreen()),
          settings: settings,
        );
      case '/discourse':
        return MaterialPageRoute(
          builder: (_) => const RouteAwareWrapper(
            routeName: '/discourse',
            child: Discourse(),
          ),
          settings: settings,
        );
      case '/games':
        return MaterialPageRoute(
          builder: (_) =>
              RouteAwareWrapper(routeName: '/games', child: GameScreen()),
          settings: settings,
        );
      case '/academic':
        return MaterialPageRoute(
          builder: (_) => RouteAwareWrapper(
            routeName: '/academic',
            child: AcademicsScreen(),
          ),
          settings: settings,
        );
        case '/help':
        return MaterialPageRoute(
          builder: (_) => RouteAwareWrapper(
            routeName: '/help',
            child: HelpScreen(),
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const RouteAwareWrapper(
            routeName: '/dashboard',
            child: DashboardScreen(),
          ),
          settings: settings,
        );
    }
  }
}

class RouteAwareWrapper extends StatefulWidget {
  final Widget child;
  final String routeName;

  const RouteAwareWrapper({
    super.key,
    required this.child,
    required this.routeName,
  });

  @override
  State<RouteAwareWrapper> createState() => _RouteAwareWrapperState();
}

class _RouteAwareWrapperState extends State<RouteAwareWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _storeCurrentRoute();
    });
  }

  void _storeCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && widget.routeName != '/login') {
      await prefs.setString('lastRoute', widget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
