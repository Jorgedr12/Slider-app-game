import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slider_app/car_selection.dart';

class TrackData {
  final String name;
  final String location;
  final String description;
  final String dioramaPath;
  final String
  scenarioFolder; // ⭐ NUEVO: Nombre de la carpeta en assets/escenarios/
  final double length;
  final String recordHolder;
  final String recordTime;

  TrackData({
    required this.name,
    required this.location,
    required this.description,
    required this.dioramaPath,
    required this.scenarioFolder, // ⭐ NUEVO
    required this.length,
    required this.recordHolder,
    required this.recordTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'dioramaPath': dioramaPath,
      'scenarioFolder': scenarioFolder,
      'length': length,
      'recordHolder': recordHolder,
      'recordTime': recordTime,
    };
  }

  factory TrackData.fromMap(Map<String, dynamic> map) {
    return TrackData(
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      dioramaPath: map['dioramaPath'] ?? '',
      scenarioFolder: map['scenarioFolder'] ?? 'retro',
      length: map['length']?.toDouble() ?? 0.0,
      recordHolder: map['recordHolder'] ?? '',
      recordTime: map['recordTime'] ?? '',
    );
  }
}

class TrackSelectionScreen extends StatefulWidget {
  const TrackSelectionScreen({super.key});

  @override
  State<TrackSelectionScreen> createState() => _TrackSelectionScreenState();
}

class _TrackSelectionScreenState extends State<TrackSelectionScreen> {
  int _currentTrackIndex = 0;
  late CarData _selectedCar;

  final List<TrackData> _tracks = [
    TrackData(
      name: 'MOUNT AKINA',
      location: 'TAKASAKI, JAPAN',
      description: 'The legendary SpeedStars mountain',
      dioramaPath: 'assets/dioramas/mountain.png',
      scenarioFolder: 'montana', // ⭐ assets/escenarios/montana/
      length: 8.5,
      recordHolder: 'TAKUMI F.',
      recordTime: '2:35.12',
    ),
    TrackData(
      name: 'SLENDER FOREST',
      location: 'OHIO, UNITED STATES',
      description: 'Dangerous zigzag curves',
      dioramaPath: 'assets/dioramas/forest.png',
      scenarioFolder: 'bosque', // ⭐ assets/escenarios/bosque/
      length: 7.2,
      recordHolder: 'KEISUKE T.',
      recordTime: '2:48.33',
    ),
    TrackData(
      name: 'UENO PARK',
      location: 'UENO, JAPAN',
      description: 'Beautiful scenic nightrace',
      dioramaPath: 'assets/dioramas/cherry_blossom.png',
      scenarioFolder: 'parque', // ⭐ assets/escenarios/parque/
      length: 6.8,
      recordHolder: 'TAKESHI N.',
      recordTime: '2:52.47',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedCar();
  }

  Future<void> _loadSelectedCar() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar el CarData completo
    final carMap = {
      'name': prefs.getString('selected_car_name') ?? 'TOYOTA AE86',
      'carImagePath':
          prefs.getString('selected_car_carImagePath') ??
          'assets/cars/toyota_select.png',
      'carGameSprite':
          prefs.getString('selected_car_carGameSprite') ??
          'cars/toyota_ae86.png',
      'driverImagePath':
          prefs.getString('selected_car_driverImagePath') ??
          'assets/characters/takumi_fujiwara.png',
      'driverName':
          prefs.getString('selected_car_driverName') ?? 'TAKUMI FUJIWARA',
    };

    setState(() {
      _selectedCar = CarData.fromMap(carMap);
    });
  }

  Future<void> _startRace() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTrack = _tracks[_currentTrackIndex];

    // Guardar datos de la pista
    final trackMap = currentTrack.toMap();
    trackMap.forEach((key, value) async {
      await prefs.setString('selected_track_$key', value.toString());
    });

    // Navegar al juego pasando los datos
    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'carSprite': _selectedCar.carGameSprite,
        'trackFolder': currentTrack.scenarioFolder,
        'trackName': "retro",
        'isVertical': true, // Por defecto vertical
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    final currentTrack = _tracks[_currentTrackIndex];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                'assets/background/car_select.png',
                fit: BoxFit.cover,
              ),
            ),

            // Overlay
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),

            SafeArea(
              child: isPortrait
                  ? _buildPortraitLayout(currentTrack)
                  : _buildLandscapeLayout(currentTrack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(TrackData currentTrack) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildTrackTitle(currentTrack),

            const SizedBox(height: 15),

            // Carro
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  child: Image.asset(
                    _selectedCar.carImagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            _buildDriverInfoCompact(),

            const SizedBox(height: 15),
            _buildTrackList(),
            const SizedBox(height: 15),
            _buildButtons(),

            const SizedBox(height: 15),
          ],
        ),

        // Diorama
        Positioned(
          bottom: 280,
          right: 20,
          child: Container(
            width: 120,
            height: 100,
            child: Image.asset(
              currentTrack.dioramaPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.landscape,
                  size: 60,
                  color: Colors.white.withOpacity(0.3),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(TrackData currentTrack) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTrackTitle(currentTrack),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        width: 250,
                        child: Image.asset(
                          _selectedCar.carImagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildDriverInfoCompact(),
                        const SizedBox(height: 10),
                        _buildTrackList(),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: _buildButtons(),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Diorama
        Positioned(
          top: 120,
          left: 30,
          child: Container(
            width: 140,
            height: 110,
            child: Image.asset(
              currentTrack.dioramaPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.landscape,
                  size: 70,
                  color: Colors.white.withOpacity(0.3),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.orange, width: 3)),
      ),
      child: Center(
        child: Text(
          'TRACK SELECTION',
          style: TextStyle(
            fontFamily: 'PressStart',
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackTitle(TrackData currentTrack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentTrack.name,
              style: TextStyle(
                fontFamily: 'PressStart',
                fontSize: 16,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              currentTrack.location,
              style: TextStyle(
                fontFamily: 'PressStart',
                fontSize: 9,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCompact() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.grey[900],
              ),
              child: _selectedCar.driverImagePath.isNotEmpty
                  ? Image.asset(_selectedCar.driverImagePath, fit: BoxFit.cover)
                  : Icon(Icons.person, color: Colors.grey[600], size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCar.driverName,
                    style: TextStyle(
                      fontFamily: 'PressStart',
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCar.name,
                    style: TextStyle(
                      fontFamily: 'PressStart',
                      fontSize: 8,
                      color: Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RECORD: ${_tracks[_currentTrackIndex].recordTime}',
                    style: TextStyle(
                      fontFamily: 'PressStart',
                      fontSize: 7,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.grey[700]!, width: 2),
        ),
        child: Column(
          children: List.generate(
            _tracks.length,
            (index) => GestureDetector(
              onTap: () {
                setState(() {
                  _currentTrackIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _currentTrackIndex == index
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 12,
                        color: _currentTrackIndex == index
                            ? Colors.orange
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _tracks[index].name,
                        style: TextStyle(
                          fontFamily: 'PressStart',
                          fontSize: 12,
                          color: _currentTrackIndex == index
                              ? Colors.orange
                              : Colors.white,
                          fontStyle: _currentTrackIndex == index
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    if (_currentTrackIndex == index)
                      Icon(Icons.arrow_forward, color: Colors.orange, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'BACK',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: GestureDetector(
              onTap: _startRace,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'START RACE',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
