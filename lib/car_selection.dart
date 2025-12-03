import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/audio_manager.dart';

class CarData {
  final String name;
  final String carImagePath;
  final String carGameSprite;
  final String driverImagePath;
  final String driverName;
  final String? characterId; // ID para verificar si está desbloqueado
  final String sfxPath; // SFX único para cada personaje

  CarData({
    required this.name,
    required this.carImagePath,
    required this.carGameSprite,
    required this.driverImagePath,
    required this.driverName,
    required this.sfxPath,
    this.characterId, // null = desbloqueado por defecto
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'carImagePath': carImagePath,
      'carGameSprite': carGameSprite,
      'driverImagePath': driverImagePath,
      'driverName': driverName,
      'sfxPath': sfxPath,
    };
  }

  factory CarData.fromMap(Map<String, dynamic> map) {
    return CarData(
      name: map['name'] ?? '',
      carImagePath: map['carImagePath'] ?? '',
      carGameSprite: map['carGameSprite'] ?? '',
      driverImagePath: map['driverImagePath'] ?? '',
      driverName: map['driverName'] ?? '',
      sfxPath: map['sfxPath'] ?? '',
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
  AudioPlayer? _currentSfxPlayer;

  final List<CarData> _cars = [
    CarData(
      name: 'TOYOTA TRUENO GT-APEX (AE86)',
      carImagePath: 'assets/cars/toyota_select.png',
      carGameSprite: 'cars/toyota_ae86.png',
      driverImagePath: 'assets/characters/takumi_fujiwara.png',
      driverName: 'TAKUMI FUJIWARA',
      characterId: null,
      sfxPath: 'sound effects/car_engine.m4a',
    ),
    CarData(
      name: 'JEEP CHEROKEE',
      carImagePath: 'assets/cars/jeep_select.png',
      carGameSprite: 'cars/jeep_cherokee.png',
      driverImagePath: 'assets/characters/pirata_culiacan.png',
      driverName: 'PIRATA DE CULIACÁN',
      characterId: null,
      sfxPath: 'sound effects/que_rollo.m4a',
    ),
    CarData(
      name: 'MICROBUS RUTA 12',
      carImagePath: 'assets/cars/bus_select.png',
      carGameSprite: 'cars/microbus.png',
      driverImagePath: 'assets/characters/el_vitor.png',
      driverName: 'EL VITOR',
      characterId: null,
      sfxPath: 'sound effects/el_vitor.m4a',
    ),
    CarData(
      name: 'HOT DOGS MANOS PUERCAS',
      carImagePath: 'assets/cars/hotdog_select.png',
      carGameSprite: 'cars/hotdog.png',
      driverImagePath: 'assets/characters/manos_puercas.png',
      driverName: 'EL MANOS PUERCAS',
      characterId: 'character_manos_puercas',
      sfxPath: 'sound effects/disgusting_sound_effect.m4a',
    ),
    CarData(
      name: 'TSURU 1992',
      carImagePath: 'assets/cars/weeb_select.png',
      carGameSprite: 'cars/weeb.png',
      driverImagePath: 'assets/characters/miguel.png',
      driverName: 'MIGUEL THE CREATOR',
      characterId: 'character_da_baby',
      sfxPath: 'sound effects/tyler.m4a',
    ),
    CarData(
      name: 'DELOREAN',
      carImagePath: 'assets/cars/delorean_select.png',
      carGameSprite: 'cars/microbus.png',
      driverImagePath: 'assets/characters/cirett.png',
      driverName: 'CIRETT',
      characterId: 'character_cirett',
      sfxPath: 'sound effects/delorean.m4a',
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
    // Reproduce el SFX del personaje actual al cargar la pantalla
    await _playCurrentSfx();
  }

  bool _isCarUnlocked(CarData car) {
    // Si no tiene characterId, está desbloqueado por defecto
    if (car.characterId == null) return true;

    // Verificar si el personaje está en la lista de comprados
    return _ownedCharacters.contains(car.characterId);
  }

  Future<void> _playCurrentSfx() async {
    // Cancela el SFX anterior si existe
    if (_currentSfxPlayer != null) {
      try {
        await _currentSfxPlayer!.stop();
        await _currentSfxPlayer!.dispose();
      } catch (_) {}
      _currentSfxPlayer = null;
    }
    // Reproduce el SFX del personaje actual
    final player = AudioPlayer();
    await player.setVolume(AudioManager.instance.effectiveSfxVolume);
    await player.play(AssetSource(_cars[_currentCarIndex].sfxPath));
    player.onPlayerComplete.listen((_) {
      player.dispose();
      if (_currentSfxPlayer == player) _currentSfxPlayer = null;
    });
    _currentSfxPlayer = player;
  }

  void _previousCar() {
    setState(() {
      _currentCarIndex = (_currentCarIndex - 1) % _cars.length;
    });
    _playCurrentSfx();
  }

  void _nextCar() {
    setState(() {
      _currentCarIndex = (_currentCarIndex + 1) % _cars.length;
    });
    _playCurrentSfx();
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
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

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
              child: isPortrait
                  ? _buildPortraitLayout(currentCar, isUnlocked)
                  : _buildLandscapeLayout(currentCar, isUnlocked),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(CarData currentCar, bool isUnlocked) {
    return Column(
      children: [
        // Botón de regreso
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 32),
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
                          border: Border.all(color: Colors.white, width: 3),
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
                          color: isUnlocked ? Colors.white : Colors.red,
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
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
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
                    : (isCurrentUnlocked ? Colors.grey[600] : Colors.grey[800]),
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
    );
  }

  Widget _buildLandscapeLayout(CarData currentCar, bool isUnlocked) {
    return Stack(
      children: [
        // Botón de regreso (top left)
        Positioned(
          top: 10,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        // Título "SELECT A MODEL" (top center)
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red[700],
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'SELECT A MODEL',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      color: Colors.black,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Contenido principal dividido en dos columnas
        Positioned(
          left: 20,
          right: 20,
          top: 70,
          bottom: 20,
          child: Row(
            children: [
              // Columna izquierda: Info del carro y conductor
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Panel con nombre del carro y conductor
                    Container(
                      padding: const EdgeInsets.all(12),
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
                                Icon(Icons.lock, color: Colors.red, size: 16),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  currentCar.name,
                                  style: TextStyle(
                                    fontFamily: 'PressStart',
                                    fontSize: 12,
                                    color: isUnlocked
                                        ? Colors.white
                                        : Colors.red,
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
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
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(width: 15),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DRIVER',
                                    style: TextStyle(
                                      fontFamily: 'PressStart',
                                      fontSize: 9,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      currentCar.driverName,
                                      style: TextStyle(
                                        fontFamily: 'PressStart',
                                        fontSize: 10,
                                        color: isUnlocked
                                            ? Colors.white
                                            : Colors.red,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botón SELECT o LOCKED
                    GestureDetector(
                      onTap: _selectCar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? Colors.green[700]
                              : Colors.red[700],
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isUnlocked) ...[
                              Icon(Icons.lock, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              isUnlocked ? 'SELECT' : 'LOCKED',
                              style: TextStyle(
                                fontFamily: 'PressStart',
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 2,
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

                    const SizedBox(height: 15),

                    // Indicadores de página
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_cars.length, (index) {
                        final isCurrentUnlocked = _isCarUnlocked(_cars[index]);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarIndex == index
                                ? (isCurrentUnlocked
                                      ? Colors.yellow
                                      : Colors.red)
                                : (isCurrentUnlocked
                                      ? Colors.grey[600]
                                      : Colors.grey[800]),
                            border: Border.all(
                              color: isCurrentUnlocked
                                  ? Colors.white
                                  : Colors.red.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Columna derecha: Carro con flechas
              Expanded(
                flex: 6,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 350,
                            height: 200,
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
                              size: 60,
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
                              size: 45,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  color: Colors.black,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            onPressed: _previousCar,
                            padding: const EdgeInsets.all(15),
                          ),

                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.yellow,
                              size: 45,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  color: Colors.black,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            onPressed: _nextCar,
                            padding: const EdgeInsets.all(15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
