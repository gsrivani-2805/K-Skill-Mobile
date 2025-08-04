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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Always start from login when launching
  runApp(MyKSkillApp(
    isLoggedIn: isLoggedIn,
    initialRoute: '/login',
  ));
}

class MyKSkillApp extends StatefulWidget {
  final bool isLoggedIn;
  final String initialRoute;

  const MyKSkillApp({
    required this.isLoggedIn,
    required this.initialRoute,
    super.key,
  });

  @override
  State<MyKSkillApp> createState() => _MyKSkillAppState();
}

class _MyKSkillAppState extends State<MyKSkillApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Clear last route when app closes or goes background
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastRoute');
      print('Last route cleared on app close.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Skill App',
      debugShowCheckedModeBanner: false,
      initialRoute: widget.initialRoute,
      onGenerateRoute: _generateRoute,
      routes: {
        '/login': (context) => LoginPage(),
        '/dashboard': (context) => const RouteAwareWrapper(
              routeName: '/dashboard',
              child: DashboardScreen(),
            ),
        '/profile': (context) => RouteAwareWrapper(
              routeName: '/profile',
              child: ProfileScreen(),
            ),
        '/levels': (context) => RouteAwareWrapper(
              routeName: '/levels',
              child: LevelsScreen(),
            ),
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
        '/quiz': (context) => RouteAwareWrapper(
              routeName: '/quiz',
              child: QuizScreen(),
            ),
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '/';

    switch (routeName) {
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
          builder: (_) => RouteAwareWrapper(
            routeName: '/profile',
            child: ProfileScreen(),
          ),
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
          builder: (_) => const RouteAwareWrapper(
            routeName: '/quiz',
            child: QuizScreen(),
          ),
          settings: settings,
        );
      case '/listening':
        return MaterialPageRoute(
          builder: (_) => const RouteAwareWrapper(
            routeName: '/listening',
            child: ListeningScreen(),
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
      print('Stored route: ${widget.routeName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
