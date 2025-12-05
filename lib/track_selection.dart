import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slider_app/car_selection.dart';
import 'services/audio_manager.dart';

class TrackData {
  final String name;
  final String location;
  final String description;
  final String dioramaPath;
  final String scenarioFolder;
  final double length;
  final String recordHolder;
  final String recordTime;

  TrackData({
    required this.name,
    required this.location,
    required this.description,
    required this.dioramaPath,
    required this.scenarioFolder,
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
  CarData? _selectedCar;
  int? _hoveredTrackIndex;
  bool _isStartHovered = false;
  bool _isBackHovered = false;

  final List<TrackData> _tracks = [
    TrackData(
      name: 'MOUNT AKINA',
      location: 'TAKASAKI, JAPAN',
      description: 'The legendary SpeedStars mountain',
      dioramaPath: 'assets/dioramas/mountain.png',
      scenarioFolder: 'montana',
      length: 8.5,
      recordHolder: 'TAKUMI F.',
      recordTime: '2:35.12',
    ),
    TrackData(
      name: 'SLENDER FOREST',
      location: 'OHIO, UNITED STATES',
      description: 'Dangerous zigzag curves',
      dioramaPath: 'assets/dioramas/forest.png',
      scenarioFolder: 'bosque',
      length: 7.2,
      recordHolder: 'KEISUKE T.',
      recordTime: '2:48.33',
    ),
    TrackData(
      name: 'UENO PARK',
      location: 'UENO, JAPAN',
      description: 'Beautiful scenic nightrace',
      dioramaPath: 'assets/dioramas/cherry_blossom.png',
      scenarioFolder: 'parque',
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
    if (_selectedCar == null) return;

    final prefs = await SharedPreferences.getInstance();
    final currentTrack = _tracks[_currentTrackIndex];

    final trackMap = currentTrack.toMap();
    trackMap.forEach((key, value) async {
      await prefs.setString('selected_track_$key', value.toString());
    });

    AudioManager.instance.stopCurrent();

    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'carSprite': _selectedCar!.carGameSprite,
        'trackFolder': currentTrack.scenarioFolder,
        'trackName': currentTrack.name,
        'isVertical': true,
      },
    );
  }

  // Determinar el tipo de dispositivo basado en el ancho
  bool _isDesktop(double width) => width >= 1024;
  bool _isTablet(double width) => width >= 600 && width < 1024;
  bool _isMobile(double width) => width < 600;

  @override
  Widget build(BuildContext context) {
    if (_selectedCar == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isDesktop = _isDesktop(width);
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
                  child: isDesktop
                      ? _buildDesktopLayout(currentTrack, width, height)
                      : (isPortrait
                            ? _buildPortraitLayout(currentTrack)
                            : _buildLandscapeLayout(currentTrack)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // NUEVO: Layout para Desktop
  Widget _buildDesktopLayout(
    TrackData currentTrack,
    double width,
    double height,
  ) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 1400),
        child: Column(
          children: [
            _buildHeader(isDesktop: true),
            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel izquierdo: Lista de pistas + Diorama
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildTrackTitle(currentTrack, isDesktop: true),
                          const SizedBox(height: 20),
                          _buildTrackList(isDesktop: true),
                          const SizedBox(height: 20),
                          _buildTrackDetails(currentTrack),
                          const Spacer(),
                          // Diorama grande en desktop
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              border: Border.all(
                                color: Colors.grey[700]!,
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              currentTrack.dioramaPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.landscape,
                                  size: 100,
                                  color: Colors.white.withOpacity(0.3),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 40),

                    // Panel central: Carro grande
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 500),
                          child: Image.asset(
                            _selectedCar!.carImagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 40),

                    // Panel derecho: Info del piloto + Botones
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildDriverInfoDesktop(),
                          const SizedBox(height: 30),
                          _buildCarStats(),
                          const Spacer(),
                          _buildButtons(isDesktop: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget con detalles adicionales de la pista (Desktop)
  Widget _buildTrackDetails(TrackData currentTrack) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRACK INFORMATION',
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 12,
              color: Colors.orange,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('DESCRIPTION', currentTrack.description),
          const SizedBox(height: 8),
          _buildDetailRow('LENGTH', '${currentTrack.length} KM'),
          const SizedBox(height: 8),
          _buildDetailRow('RECORD HOLDER', currentTrack.recordHolder),
          const SizedBox(height: 8),
          _buildDetailRow('BEST TIME', currentTrack.recordTime),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 9,
              color: Colors.grey[400],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 9,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Info del piloto para Desktop
  Widget _buildDriverInfoDesktop() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.grey[900],
            ),
            child: _selectedCar!.driverImagePath.isNotEmpty
                ? Image.asset(_selectedCar!.driverImagePath, fit: BoxFit.cover)
                : Icon(Icons.person, color: Colors.grey[600], size: 60),
          ),
          const SizedBox(height: 15),
          Text(
            'DRIVER',
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCar!.driverName,
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Container(width: double.infinity, height: 2, color: Colors.orange),
          const SizedBox(height: 15),
          Text(
            _selectedCar!.name,
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 12,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Stats del carro (Desktop)
  Widget _buildCarStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VEHICLE STATS',
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 11,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 15),
          _buildStatBar('SPEED', 0.85),
          const SizedBox(height: 10),
          _buildStatBar('ACCELERATION', 0.75),
          const SizedBox(height: 10),
          _buildStatBar('HANDLING', 0.90),
          const SizedBox(height: 10),
          _buildStatBar('DRIFT', 0.95),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'PressStart',
            fontSize: 8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(color: Colors.orange),
          ),
        ),
      ],
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

            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  child: Image.asset(
                    _selectedCar!.carImagePath,
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
                          _selectedCar!.carImagePath,
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
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildTrackList(),
                          ),
                        ),
                        const SizedBox(height: 10),
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

  Widget _buildHeader({bool isDesktop = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.orange, width: 3)),
      ),
      child: Center(
        child: Text(
          'TRACK SELECTION',
          style: TextStyle(
            fontFamily: 'PressStart',
            fontSize: isDesktop ? 28 : 20,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackTitle(TrackData currentTrack, {bool isDesktop = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 20),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isDesktop ? 16 : 10,
          horizontal: isDesktop ? 20 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                currentTrack.name,
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: isDesktop ? 20 : 16,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Text(
              currentTrack.location,
              style: TextStyle(
                fontFamily: 'PressStart',
                fontSize: isDesktop ? 11 : 9,
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
              child: _selectedCar!.driverImagePath.isNotEmpty
                  ? Image.asset(
                      _selectedCar!.driverImagePath,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.person, color: Colors.grey[600], size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCar!.driverName,
                    style: TextStyle(
                      fontFamily: 'PressStart',
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCar!.name,
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

  Widget _buildTrackList({bool isDesktop = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 20),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 12 : 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.grey[700]!, width: 2),
        ),
        child: Column(
          children: List.generate(
            _tracks.length,
            (index) => MouseRegion(
              onEnter: (_) => setState(() => _hoveredTrackIndex = index),
              onExit: (_) => setState(() => _hoveredTrackIndex = null),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTrackIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 12 : 6,
                    horizontal: isDesktop ? 16 : 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: _currentTrackIndex == index
                        ? Colors.orange.withOpacity(0.3)
                        : (_hoveredTrackIndex == index
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.transparent),
                    border: _currentTrackIndex == index
                        ? Border.all(color: Colors.orange, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontFamily: 'PressStart',
                          fontSize: isDesktop ? 14 : 12,
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
                            fontSize: isDesktop ? 14 : 12,
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
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.orange,
                          size: isDesktop ? 20 : 16,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons({bool isDesktop = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 20),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isBackHovered = true),
              onExit: (_) => setState(() => _isBackHovered = false),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: _isBackHovered ? Colors.grey[700] : Colors.grey[800],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: isDesktop ? 20 : 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BACK',
                        style: TextStyle(
                          fontFamily: 'PressStart',
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isStartHovered = true),
              onExit: (_) => setState(() => _isStartHovered = false),
              child: GestureDetector(
                onTap: _startRace,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: _isStartHovered
                        ? Colors.green[600]
                        : Colors.green[700],
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(
                          _isStartHovered ? 0.6 : 0.4,
                        ),
                        blurRadius: _isStartHovered ? 12 : 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'START RACE',
                    style: TextStyle(
                      fontFamily: 'PressStart',
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
