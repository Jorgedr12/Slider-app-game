import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarData {
  final String name;
  final String carImagePath; // Para la pantalla de selección
  final String carGameSprite; // ⭐ NUEVO: Para el juego
  final String driverImagePath;
  final String driverName;

  CarData({
    required this.name,
    required this.carImagePath,
    required this.carGameSprite, // ⭐ NUEVO
    required this.driverImagePath,
    required this.driverName,
  });

  // Convertir a Map para SharedPreferences
  Map<String, String> toMap() {
    return {
      'name': name,
      'carImagePath': carImagePath,
      'carGameSprite': carGameSprite,
      'driverImagePath': driverImagePath,
      'driverName': driverName,
    };
  }

  // Crear desde Map
  factory CarData.fromMap(Map<String, dynamic> map) {
    return CarData(
      name: map['name'] ?? '',
      carImagePath: map['carImagePath'] ?? '',
      carGameSprite: map['carGameSprite'] ?? '',
      driverImagePath: map['driverImagePath'] ?? '',
      driverName: map['driverName'] ?? '',
    );
  }
}

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  int _currentCarIndex = 0;

  final List<CarData> _cars = [
    CarData(
      name: 'TOYOTA TRUENO GT-APEX (AE86)',
      carImagePath: 'assets/cars/toyota_select.png',
      // Usar ruta relativa para Flame (sin 'assets/') y sprite del juego
      carGameSprite: 'cars/toyota_ae86.png', // ⭐ Sprite para el juego
      driverImagePath: 'assets/characters/takumi_fujiwara.png',
      driverName: 'TAKUMI FUJIWARA',
    ),
    CarData(
      name: 'JEEP CHEROKEE',
      carImagePath: 'assets/cars/jeep_select.png',
      carGameSprite: 'cars/jeep_cherokee.png', // ⭐ Sprite para el juego
      driverImagePath: 'assets/characters/pirata_culiacan.png',
      driverName: 'PIRATA DE CULIACÁN',
    ),
    CarData(
      name: 'MICROBUS RUTA 12',
      carImagePath: 'assets/cars/bus_select.png',
      carGameSprite: 'cars/microbus.png', // ⭐ Sprite para el juego
      driverImagePath: 'assets/characters/el_vitor.png',
      driverName: 'EL VITOR',
    ),
  ];

  void _previousCar() {
    setState(() {
      _currentCarIndex = (_currentCarIndex - 1) % _cars.length;
    });
  }

  void _nextCar() {
    setState(() {
      _currentCarIndex = (_currentCarIndex + 1) % _cars.length;
    });
  }

  Future<void> _selectCar() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCar = _cars[_currentCarIndex];

    // Guardar TODO el CarData como JSON
    final carMap = currentCar.toMap();
    carMap.forEach((key, value) async {
      await prefs.setString('selected_car_$key', value);
    });

    // Navegar a la selección de pista
    Navigator.pushNamed(context, '/track_selection');
  }

  @override
  Widget build(BuildContext context) {
    final currentCar = _cars[_currentCarIndex];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/background/car_select.png',
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Botón de regreso
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Título "SELECT A MODEL"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 3),
                        bottom: BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                    child: Text(
                      'SELECT A MODEL',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            offset: Offset(3, 3),
                            color: Colors.black,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Panel con nombre del carro y conductor
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      border: Border.all(color: Colors.grey[600]!, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentCar.name,
                          style: TextStyle(
                            fontFamily: 'PressStart',
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                color: Colors.grey[900],
                              ),
                              child: Image.asset(
                                currentCar.driverImagePath,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(width: 20),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DRIVER',
                                  style: TextStyle(
                                    fontFamily: 'PressStart',
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentCar.driverName,
                                  style: TextStyle(
                                    fontFamily: 'PressStart',
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Carro con flechas de navegación
                  Container(
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Container(
                            width: 400,
                            height: 250,
                            child: Image.asset(
                              currentCar.carImagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        Positioned.fill(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.yellow,
                                  size: 60,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      color: Colors.black,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                onPressed: _previousCar,
                                padding: const EdgeInsets.all(20),
                              ),

                              IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.yellow,
                                  size: 60,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      color: Colors.black,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                onPressed: _nextCar,
                                padding: const EdgeInsets.all(20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Botón SELECT
                  GestureDetector(
                    onTap: _selectCar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'SELECT',
                        style: TextStyle(
                          fontFamily: 'PressStart',
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              color: Colors.black,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Indicadores de página
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _cars.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentCarIndex == index
                              ? Colors.yellow
                              : Colors.grey[600],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
