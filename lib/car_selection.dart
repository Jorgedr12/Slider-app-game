import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarData {
  final String name;
  final String carImagePath;
  final String carGameSprite;
  final String driverImagePath;
  final String driverName;
  final String? characterId; // ID para verificar si está desbloqueado

  CarData({
    required this.name,
    required this.carImagePath,
    required this.carGameSprite,
    required this.driverImagePath,
    required this.driverName,
    this.characterId, // null = desbloqueado por defecto
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'carImagePath': carImagePath,
      'carGameSprite': carGameSprite,
      'driverImagePath': driverImagePath,
      'driverName': driverName,
    };
  }

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
  List<String> _ownedCharacters = [];
  bool _isLoading = true;

  final List<CarData> _cars = [
    CarData(
      name: 'TOYOTA TRUENO GT-APEX (AE86)',
      carImagePath: 'assets/cars/toyota_select.png',
      carGameSprite: 'cars/toyota_ae86.png',
      driverImagePath: 'assets/characters/takumi_fujiwara.png',
      driverName: 'TAKUMI FUJIWARA',
      characterId: null, // Desbloqueado por defecto
    ),
    CarData(
      name: 'JEEP CHEROKEE',
      carImagePath: 'assets/cars/jeep_select.png',
      carGameSprite: 'cars/jeep_cherokee.png',
      driverImagePath: 'assets/characters/pirata_culiacan.png',
      driverName: 'PIRATA DE CULIACÁN',
      characterId: null, // Desbloqueado por defecto
    ),
    CarData(
      name: 'MICROBUS RUTA 12',
      carImagePath: 'assets/cars/bus_select.png',
      carGameSprite: 'cars/microbus.png',
      driverImagePath: 'assets/characters/el_vitor.png',
      driverName: 'EL VITOR',
      characterId: null, // Desbloqueado por defecto
    ),
    CarData(
      name: 'HOT DOGS MANOS PUERCAS',
      carImagePath: 'assets/cars/hotdog_select.png',
      carGameSprite: 'cars/hotdog.png',
      driverImagePath: 'assets/characters/manos_puercas.png',
      driverName: 'EL MANOS PUERCAS',
      characterId: 'character_manos_puercas', // Requiere compra
    ),
    CarData(
      name: 'TSURU 1992',
      carImagePath: 'assets/cars/weeb_select.png',
      carGameSprite: 'cars/weeb.png',
      driverImagePath: 'assets/characters/miguel.png',
      driverName: 'MIGUEL THE CREATOR',
      characterId: 'character_da_baby', // Requiere compra
    ),
    CarData(
      name: 'DELOREAN',
      carImagePath: 'assets/cars/delorean_select.png',
      carGameSprite: 'cars/microbus.png',
      driverImagePath: 'assets/characters/cirett.png',
      driverName: 'CIRETT',
      characterId: 'character_cirett', // Requiere compra
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOwnedCharacters();
  }

  Future<void> _loadOwnedCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownedCharacters = prefs.getStringList('ownedCharacters') ?? [];
      _isLoading = false;
    });
  }

  bool _isCarUnlocked(CarData car) {
    // Si no tiene characterId, está desbloqueado por defecto
    if (car.characterId == null) return true;

    // Verificar si el personaje está en la lista de comprados
    return _ownedCharacters.contains(car.characterId);
  }

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

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.red, width: 3),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'LOCKED',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 18,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This character is locked!',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 12,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Visit the SHOP to unlock',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectCar() async {
    final currentCar = _cars[_currentCarIndex];

    // Verificar si el carro está desbloqueado
    if (!_isCarUnlocked(currentCar)) {
      _showLockedDialog();
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Guardar el CarData
    final carMap = currentCar.toMap();
    carMap.forEach((key, value) async {
      await prefs.setString('selected_car_$key', value);
    });

    // Navegar a la selección de pista
    Navigator.pushNamed(context, '/track_selection');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.yellow)),
      );
    }

    final currentCar = _cars[_currentCarIndex];
    final isUnlocked = _isCarUnlocked(currentCar);

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
                      border: Border.all(
                        color: isUnlocked ? Colors.grey[600]! : Colors.red,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isUnlocked) ...[
                              Icon(Icons.lock, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                currentCar.name,
                                style: TextStyle(
                                  fontFamily: 'PressStart',
                                  fontSize: 18,
                                  color: isUnlocked ? Colors.white : Colors.red,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
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
                                  child: ColorFiltered(
                                    colorFilter: isUnlocked
                                        ? ColorFilter.mode(
                                            Colors.transparent,
                                            BlendMode.multiply,
                                          )
                                        : ColorFilter.mode(
                                            Colors.black.withOpacity(0.7),
                                            BlendMode.darken,
                                          ),
                                    child: Image.asset(
                                      currentCar.driverImagePath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                                    color: isUnlocked
                                        ? Colors.white
                                        : Colors.red,
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
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 400,
                                height: 250,
                                child: ColorFiltered(
                                  colorFilter: isUnlocked
                                      ? ColorFilter.mode(
                                          Colors.transparent,
                                          BlendMode.multiply,
                                        )
                                      : ColorFilter.mode(
                                          Colors.black.withOpacity(0.5),
                                          BlendMode.darken,
                                        ),
                                  child: Image.asset(
                                    currentCar.carImagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              if (!isUnlocked)
                                Icon(
                                  Icons.lock,
                                  color: Colors.red,
                                  size: 80,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(3, 3),
                                      color: Colors.black,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                            ],
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

                  // Botón SELECT o LOCKED
                  GestureDetector(
                    onTap: _selectCar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: isUnlocked ? Colors.green[700] : Colors.red[700],
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isUnlocked) ...[
                            Icon(Icons.lock, color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            isUnlocked ? 'SELECT' : 'LOCKED',
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Indicadores de página
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_cars.length, (index) {
                      final isCurrentUnlocked = _isCarUnlocked(_cars[index]);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentCarIndex == index
                              ? (isCurrentUnlocked ? Colors.yellow : Colors.red)
                              : (isCurrentUnlocked
                                    ? Colors.grey[600]
                                    : Colors.grey[800]),
                          border: Border.all(
                            color: isCurrentUnlocked
                                ? Colors.white
                                : Colors.red.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      );
                    }),
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
