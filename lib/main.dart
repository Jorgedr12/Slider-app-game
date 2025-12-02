import 'package:flutter/material.dart';
import 'package:slider_app/menu.dart';
import 'package:slider_app/racing_game_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'widgets/draggable_car.dart';
import 'car_selection.dart';
import 'shop.dart';
import 'credits.dart';
import 'track_selection.dart';
import 'settings.dart';
import 'ranking.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Initial D Racing Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Menu(),
        '/car_selection': (context) => const CarSelectionScreen(),
        '/track_selection': (context) => const TrackSelectionScreen(),
        '/settings': (context) => const SettingsPage(),
        '/shop': (context) => Shop(),
        '/ranking': (context) => const RankingPage(),
        '/credits': (context) => const CreditsScreen(),
      },
      onGenerateRoute: (settings) {
        // Manejar la ruta del juego con argumentos
        if (settings.name == '/game') {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (context) => RacingGameWidget(
              startVertical: args?['isVertical'] ?? true,
              selectedCarSprite: args?['carSprite'] ?? 'cars/toyota_ae86.png',
              trackFolder: args?['trackFolder'] ?? 'retro',
              trackName: args?['trackName'] ?? 'RETRO TRACK',
            ),
          );
        }
        return null;
      },
    );
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
  late final SupabaseService _supabaseService;
  bool _isSignedIn = false;
  bool _isVertical = true;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _initializeData();
  }

  void _toggleOrientation() {
    setState(() {
      _isVertical = !_isVertical;
    });
  }

  Future<void> _initializeData() async {
    if (!_isSignedIn) {
      await _supabaseService.signIn(
        email: dotenv.env['AUTH_EMAIL']!,
        password: dotenv.env['AUTH_PASSWORD']!,
      );

      final points = await _supabaseService.retrievePoints(
        playerName: 'Spongebob',
      );

      if (points != null) {
        setState(() {
          _counter = points;
          _isSignedIn = true;
        });
      }
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    _supabaseService.checkAndUpsertPlayer(
      playerName: 'Spongebob',
      score: _counter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isVertical ? Icons.swap_horiz : Icons.swap_vert),
            tooltip: _isVertical
                ? 'Change to horizontal'
                : 'Change to vertical',
            onPressed: _toggleOrientation,
            padding: const EdgeInsets.only(top: 8.0, right: 16.0),
          ),
        ],
      ),
      body: Center(
        child: _isVertical ? _buildVerticalLayout() : _buildHorizontalLayout(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Spacer(flex: 2),
        Column(
          children: [
            const Text('You have pushed the button this many times:'),
            const SizedBox(height: 20),
            Text('$_counter', style: Theme.of(context).textTheme.headlineLarge),
          ],
        ),
        const Spacer(flex: 2),
        const Padding(
          padding: EdgeInsets.only(bottom: 20.0),
          child: DraggableCar(
            imagePath: 'assets/cars/orange_car.png',
            width: 120,
            height: 70,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: DraggableCarHorizontal(
            imagePath: 'assets/cars/orange_car_h.png',
            width: 60,
            height: 100,
          ),
        ),
        const Spacer(flex: 2),
        const Text('You have pushed the button this many times:'),
        const SizedBox(width: 20),
        Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(flex: 2),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Settings Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }
}

// Ejemplo de cómo navegar al juego con parámetros desde el menú
class GameLauncher {
  static void launchGame(
    BuildContext context, {
    bool isVertical = true,
    String carColor = 'Naranja',
    String trackName = 'MONTE AKINA',
  }) {
    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'isVertical': isVertical,
        'carColor': carColor,
        'trackName': trackName,
      },
    );
  }
}
