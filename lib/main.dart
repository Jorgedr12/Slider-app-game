import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'widgets/draggable_car.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carga las variables de entorno desde .env
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slider App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Slider App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late final SupabaseService _supabaseService;
  bool _isSignedIn = false;
  bool _isVertical = true; // true = vertical (Column), false = horizontal (Row)

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _initializeData();
  }

  /// Alterna entre diseño vertical y horizontal
  void _toggleOrientation() {
    setState(() {
      _isVertical = !_isVertical;
    });
  }

  /// Inicializa la sesión y carga los puntos del jugador.
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
        actions: [
          // Botón para cambiar orientación
          IconButton(
            icon: Icon(_isVertical ? Icons.swap_horiz : Icons.swap_vert),
            tooltip: _isVertical ? 'Cambiar a horizontal' : 'Cambiar a vertical',
            onPressed: _toggleOrientation,
            // Añadir un padding superior
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

  /// Layout vertical (Column)
  Widget _buildVerticalLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Espacio superior flexible
        const Spacer(flex: 2),
        
        // Contenido central
        Column(
          children: [
            const Text('You have pushed the button this many times:'),
            const SizedBox(height: 20),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
        
        // Espacio flexible antes del coche
        const Spacer(flex: 2),
        
        // Coche arrastrable en la parte inferior
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

  /// Layout horizontal (Row)
  Widget _buildHorizontalLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Coche vertical en el lado izquierdo
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: DraggableCarHorizontal(
            imagePath: 'assets/cars/orange_car_h.png',
            width: 60,
            height: 100,
          ),
        ),
        const Spacer(flex: 2),
        const Text('You have pushed the button this many times:'),
        const SizedBox(width: 20),
        Text(
          '$_counter',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
