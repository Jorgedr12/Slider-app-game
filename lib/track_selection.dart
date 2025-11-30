import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackData {
  final String name;
  final String location;
  final String description;
  final String dioramaPath;
  final double length;
  final String recordHolder;
  final String recordTime;

  TrackData({
    required this.name,
    required this.location,
    required this.description,
    required this.dioramaPath,
    required this.length,
    required this.recordHolder,
    required this.recordTime,
  });
}

class TrackSelectionScreen extends StatefulWidget {
  const TrackSelectionScreen({super.key});

  @override
  State<TrackSelectionScreen> createState() => _TrackSelectionScreenState();
}

class _TrackSelectionScreenState extends State<TrackSelectionScreen> {
  int _currentTrackIndex = 0;
  String _selectedCarName = '';
  String _selectedCarImage = '';
  String _selectedDriverName = '';
  String _selectedDriverImage = '';

  final List<TrackData> _tracks = [
    TrackData(
      name: 'MONTE AKINA',
      location: 'AKINA - DOWNHILL / UPHILL',
      description: 'La legendaria montaña del equipo SpeedStars',
      dioramaPath: 'assets/tracks/akina_diorama.png',
      length: 8.5,
      recordHolder: 'TAKUMI F.',
      recordTime: '2:35.12',
    ),
    TrackData(
      name: 'USUI',
      location: 'USUI - DOWNHILL',
      description: 'Peligrosas curvas en zigzag',
      dioramaPath: 'assets/tracks/usui_diorama.png',
      length: 7.2,
      recordHolder: 'KEISUKE T.',
      recordTime: '2:48.33',
    ),
    TrackData(
      name: 'MYOGI',
      location: 'MYOGI - DOWNHILL',
      description: 'Territorio del equipo NightKids',
      dioramaPath: 'assets/tracks/myogi_diorama.png',
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
    setState(() {
      _selectedCarName = prefs.getString('selected_car_name') ?? 'TOYOTA AE86';
      _selectedCarImage =
          prefs.getString('selected_car_image') ??
          'assets/cars/toyota_select.png';
      _selectedDriverName =
          prefs.getString('selected_driver_name') ?? 'TAKUMI FUJIWARA';
      _selectedDriverImage =
          prefs.getString('selected_driver_image') ??
          'assets/characters/takumi_fujiwara.png';
    });
  }

  void _startRace() {
    Navigator.pushNamed(context, '/game');
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
            // Header compacto
            _buildHeader(),

            const SizedBox(height: 10),

            // Info de la pista
            _buildTrackTitle(currentTrack),

            const SizedBox(height: 15),

            // Carro
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  child: Image.asset(_selectedCarImage, fit: BoxFit.contain),
                ),
              ),
            ),

            // Info del conductor (compacta)
            _buildDriverInfoCompact(),

            const SizedBox(height: 15),

            // Lista de pistas
            _buildTrackList(),

            const SizedBox(height: 15),

            // Botones
            _buildButtons(),

            const SizedBox(height: 15),
          ],
        ),

        // Diorama flotante (PNG transparente)
        Positioned(
          top: 120,
          right: 20,
          child: Container(
            width: 120,
            height: 100,
            child: Icon(
              Icons.landscape,
              size: 60,
              color: Colors.white.withOpacity(0.3),
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
            // Header
            _buildHeader(),

            const SizedBox(height: 8),

            // Info de la pista
            _buildTrackTitle(currentTrack),

            const SizedBox(height: 10),

            Expanded(
              child: Row(
                children: [
                  // Lado izquierdo: Carro
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        width: 250,
                        child: Image.asset(
                          _selectedCarImage,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Lado derecho: Info conductor, lista y botones
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

        // Diorama flotante arriba a la derecha
        Positioned(
          top: 80,
          right: 30,
          child: Container(
            width: 140,
            height: 110,
            child: Icon(
              Icons.landscape,
              size: 70,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.orange, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo/game_logo.png',
            height: 35,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Text(
            'SELECCIÓN DE RUTA',
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTitle(TrackData currentTrack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: Column(
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
            const SizedBox(height: 5),
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
            // Foto del conductor
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.grey[900],
              ),
              child: _selectedDriverImage.isNotEmpty
                  ? Image.asset(_selectedDriverImage, fit: BoxFit.cover)
                  : Icon(Icons.person, color: Colors.grey[600], size: 30),
            ),
            const SizedBox(width: 12),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDriverName,
                    style: TextStyle(
                      fontFamily: 'PressStart',
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCarName,
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
                    'RÉCORD: ${_tracks[_currentTrackIndex].recordTime}',
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
          // Botón ATRÁS
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
                      'ATRÁS',
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

          // Botón INICIAR RUTA
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
                  'INICIAR RUTA',
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
