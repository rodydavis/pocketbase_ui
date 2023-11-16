import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pocketbase_ui/pocketbase_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  const authKey = 'pb_auth';
  final store = AsyncAuthStore(
    save: (data) async => prefs.setString(authKey, data),
    initial: prefs.getString(authKey),
  );
  final pb = PocketBase(
    'https://pocketbase.io',
    authStore: store,
  );
  runApp(App(prefs: prefs, pb: pb));
}

class App extends StatefulWidget {
  const App({
    super.key,
    required this.pb,
    required this.prefs,
  });

  final PocketBase pb;
  final SharedPreferences prefs;

  static AppState of(BuildContext context) {
    return context.findAncestorStateOfType<AppState>()!;
  }

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  final themeMode = ValueNotifier(ThemeMode.light);
  late final PocketBase pb = widget.pb;
  late final SharedPreferences prefs = widget.prefs;
  late final _controller = AuthController(
    client: pb,
    providers: [
      EmailAuthProvider(),
      AppleAuthProvider(),
      GoogleAuthProvider(),
    ],
    errorCallback: (error) {},
  )..addListener(() => setState(() {}));

  late final _router = GoRouter(
    initialLocation: '/',
    refreshListenable: _controller,
    redirect: (context, state) {
      if (!_controller.isSignedIn) return '/sign-in';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (context, state) {
          if (!_controller.isSignedIn) {
            return '/sign-in?redirect_url=${state.matchedLocation}';
          }
          return null;
        },
        builder: (context, state) {
          return const MyHomePage(title: 'Flutter Demo Home Page');
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'profile',
            builder: (context, state) {
              return ProfileScreen(controller: _controller);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/sign-in',
        redirect: (context, state) {
          if (_controller.isSignedIn) {
            final prev = state.uri.queryParameters['redirect_url'];
            if (prev != null) return prev;
            return '/';
          }
          return null;
        },
        builder: (context, state) {
          return SignInScreen(
            controller: _controller,
            background: const Placeholder(),
            onLoginSuccess: () {},
          );
        },
      ),
    ],
  );

  ThemeData buildTheme(Brightness brightness, Color color) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: brightness,
      ),
      brightness: brightness,
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    const color = Colors.deepPurple;
    return ValueListenableBuilder(
        valueListenable: themeMode,
        builder: (context, mode, child) {
          return MaterialApp.router(
            title: 'Flutter Demo',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light, color),
            darkTheme: buildTheme(Brightness.dark, color),
            themeMode: mode,
            routerConfig: _router,
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          ValueListenableBuilder(
            valueListenable: App.of(context).themeMode,
            builder: (context, mode, child) => IconButton(
              tooltip: switch (mode) {
                ThemeMode.dark => 'Dark Mode',
                ThemeMode.light => 'Light Mode',
                ThemeMode.system => 'System Brightness Mode',
              },
              icon: switch (mode) {
                ThemeMode.dark => const Icon(Icons.dark_mode),
                ThemeMode.light => const Icon(Icons.light_mode),
                ThemeMode.system => const Icon(Icons.brightness_auto),
              },
              onPressed: switch (mode) {
                ThemeMode.dark => () =>
                    App.of(context).themeMode.value = ThemeMode.light,
                ThemeMode.light => () =>
                    App.of(context).themeMode.value = ThemeMode.dark,
                ThemeMode.system => () =>
                    App.of(context).themeMode.value = ThemeMode.light,
              },
            ),
          ),
          IconButton(
            tooltip: 'Go to profile',
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
