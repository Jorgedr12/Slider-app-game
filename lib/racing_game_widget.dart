import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:slider_app/pause_menu.dart';
import 'package:slider_app/racing_game.dart';
import 'services/audio_manager.dart';
// import 'racing_game.dart';
// import 'pause_menu_advanced.dart';

/// Widget principal que contiene el juego de carreras
/// Maneja el estado de pausa, orientación, audio y overlays
class RacingGameWidget extends StatefulWidget {
  final bool startVertical;
  final String selectedCarSprite;
  final String trackFolder;
  final String trackName;

  const RacingGameWidget({
    super.key,
    this.startVertical = true,
    this.selectedCarSprite = 'cars/toyota_ae86.png',
    this.trackFolder = 'montana',
    this.trackName = 'retro',
  });

  @override
  State<RacingGameWidget> createState() => _RacingGameWidgetState();
}

class _RacingGameWidgetState extends State<RacingGameWidget>
    with SingleTickerProviderStateMixin {
  late RacingGame _game;
  late AudioPlayer _gameAudioPlayer;
  bool _isPaused = false;
  bool _isGameOver = false;
  bool _isVertical = true;
  late final AnimationController _hudTicker;

  @override
  void initState() {
    super.initState();
    _isVertical = widget.startVertical;
    _gameAudioPlayer = AudioPlayer();
    // Refrescar el HUD periódicamente para reflejar cambios del juego
    _hudTicker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            if (!_isPaused) {
              setState(() {});
            }
          })
          ..repeat(period: const Duration(milliseconds: 100));

    // Inicializar el juego con los datos recibidos
    _game = RacingGame(
      isVertical: _isVertical,
      selectedCarSprite: widget.selectedCarSprite, // ⭐ Sprite del carro
      selectedTrack: widget.trackFolder, // ⭐ Carpeta del escenario
    );

    // Configurar callbacks
    _game.onPauseRequest = _togglePause;
    _game.onGameOver = _showGameOver;
    _game.currentTrackName = widget.trackName; // ⭐ Nombre para mostrar

    debugPrint('═══════════════════════════════════════');
    debugPrint('🎮 VALORES RECIBIDOS EN EL JUEGO:');
    debugPrint('   Sprite del carro: ${widget.selectedCarSprite}');
    debugPrint('   Carpeta de pista: ${widget.trackFolder}');
    debugPrint('   Nombre de pista: ${widget.trackName}');
    debugPrint(
      '   Orientación: ${widget.startVertical ? "Vertical" : "Horizontal"}',
    );
    debugPrint('═══════════════════════════════════════');

    _playGameMusic();
  }

  Future<void> _playGameMusic() async {
    try {
      await _gameAudioPlayer.setReleaseMode(ReleaseMode.loop);

      AudioManager.instance.setBytesPlayer(_gameAudioPlayer);

      await _gameAudioPlayer.setVolume(
        AudioManager.instance.effectiveMusicVolume,
      );

      await _gameAudioPlayer.play(AssetSource('music/race_theme_v1.m4a'));
    } catch (e) {
      debugPrint('Error al reproducir música del juego: $e');
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
        _gameAudioPlayer.pause();
      } else {
        _game.resumeEngine();
        _gameAudioPlayer.resume();
      }
    });
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
      _game.resumeEngine();
      _gameAudioPlayer.resume();
    });
  }

  void _restartGame() {
    setState(() {
      _isPaused = false;
      _isGameOver = false;
      _game.resetGame();
      _game.resumeEngine();
      _gameAudioPlayer.stop();
      _playGameMusic();
    });
  }

  void _exitToMenu() {
    AudioManager.instance.clearCurrentPlayer(_gameAudioPlayer);
    _gameAudioPlayer.stop();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _toggleOrientation() {
    setState(() {
      _isVertical = !_isVertical;
      _game.toggleOrientation();
    });
  }

  void _showGameOver() {
    setState(() {
      _isGameOver = true;
      _gameAudioPlayer.stop();
    });
  }

  @override
  void dispose() {
    AudioManager.instance.clearCurrentPlayer(_gameAudioPlayer);
    _hudTicker.dispose();
    _gameAudioPlayer.dispose();
    super.dispose();
  }

  bool get _shouldShowOrientationButton {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        autofocus: true,
        child: Stack(
          children: [
            // El juego de Flame
            GameWidget(game: _game),

            // HUD del juego (siempre visible cuando no está pausado)
            if (!_isPaused && !_isGameOver) _buildGameHUD(),

            // Botón de pausa flotante
            if (!_isPaused && !_isGameOver) _buildPauseButton(),

            // Botón de cambiar orientación
            if (!_isPaused && !_isGameOver && _shouldShowOrientationButton)
              _buildOrientationButton(),

            // Menú de pausa
            if (_isPaused && !_isGameOver)
              PauseMenu(
                onResume: _resumeGame,
                onRestart: _restartGame,
                onExit: _exitToMenu,
              ),

            // Pantalla de Game Over
            if (_isGameOver) _buildGameOverScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHUD() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Panel izquierdo - Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.cyan.withOpacity(0.6), width: 2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vidas
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_game.lives}/${_game.maxLives}',
                      style: const TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Distancia
                Row(
                  children: [
                    const Icon(Icons.straighten, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_game.distance.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Velocidad
                Row(
                  children: [
                    const Icon(
                      Icons.speed,
                      color: Colors.orangeAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_game.currentSpeed.toStringAsFixed(0)} km/h',
                      style: const TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 14,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Panel derecho - Gasolina
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(
                color: _game.fuel > 20
                    ? Colors.green.withOpacity(0.6)
                    : Colors.red.withOpacity(0.8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (_game.fuel > 20 ? Colors.green : Colors.red)
                      .withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Monedas
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_game.coinsCollected}',
                      style: const TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 16,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      color: _game.fuel > 20 ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_game.fuel.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 16,
                        color: _game.fuel > 20 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Barra de gasolina
                Container(
                  width: 120,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_game.fuel / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _game.fuel > 20
                              ? [Colors.green, Colors.lightGreen]
                              : [Colors.red, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: GestureDetector(
        onTap: _togglePause,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border.all(color: Colors.orangeAccent, width: 3),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.pause, color: Colors.orangeAccent, size: 35),
        ),
      ),
    );
  }

  Widget _buildOrientationButton() {
    return Positioned(
      bottom: 30,
      left: 20,
      child: GestureDetector(
        onTap: _toggleOrientation,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border.all(color: Colors.blue[300]!, width: 3),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            _isVertical ? Icons.swap_horiz : Icons.swap_vert,
            color: Colors.blue[300],
            size: 35,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(20), // Margen para móviles
            decoration: BoxDecoration(
              color: const Color(0xFF0a0a0a),
              border: Border.all(color: Colors.red, width: 4),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: isLandscape
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Izquierda: Título y Stats
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'GAME OVER',
                              style: TextStyle(
                                fontFamily: 'PixelifySans',
                                fontSize: 50,
                                color: Colors.red,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(
                                    color: Colors.red.withOpacity(0.8),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFinalStat(
                            'DISTANCIA',
                            '${_game.distance.toStringAsFixed(0)} m',
                          ),
                          const SizedBox(height: 10),
                          _buildFinalStat(
                            'OBSTÁCULOS',
                            '${_game.obstaclesAvoided}',
                          ),
                          const SizedBox(height: 10),
                          _buildFinalStat('MONEDAS', '${_game.coinsCollected}'),
                          const SizedBox(height: 10),
                          _buildFinalStat(
                            'VEL. MÁXIMA',
                            '${_game.maxSpeed.toStringAsFixed(0)} km/h',
                          ),
                        ],
                      ),
                      const SizedBox(width: 50),
                      // Derecha: Botones
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGameOverButton(
                            text: 'REINTENTAR',
                            icon: Icons.restart_alt,
                            color: Colors.green,
                            onTap: _restartGame,
                          ),
                          const SizedBox(height: 20),
                          _buildGameOverButton(
                            text: 'MENÚ',
                            icon: Icons.home,
                            color: Colors.blue,
                            onTap: _exitToMenu,
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título Game Over
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'GAME OVER',
                          style: TextStyle(
                            fontFamily: 'PixelifySans',
                            fontSize: 50,
                            color: Colors.red,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.red.withOpacity(0.8),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Estadísticas finales
                      _buildFinalStat(
                        'DISTANCIA',
                        '${_game.distance.toStringAsFixed(0)} m',
                      ),
                      const SizedBox(height: 15),
                      _buildFinalStat(
                        'OBSTÁCULOS',
                        '${_game.obstaclesAvoided}',
                      ),
                      const SizedBox(height: 15),
                      _buildFinalStat('MONEDAS', '${_game.coinsCollected}'),
                      const SizedBox(height: 15),
                      _buildFinalStat(
                        'VEL. MÁXIMA',
                        '${_game.maxSpeed.toStringAsFixed(0)} km/h',
                      ),

                      const SizedBox(height: 40),

                      // Botones
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildGameOverButton(
                            text: 'REINTENTAR',
                            icon: Icons.restart_alt,
                            color: Colors.green,
                            onTap: _restartGame,
                          ),
                          _buildGameOverButton(
                            text: 'MENÚ',
                            icon: Icons.home,
                            color: Colors.blue,
                            onTap: _exitToMenu,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PressStart',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 30),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PixelifySans',
            fontSize: 20,
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200, // Ancho fijo para uniformidad
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centrar contenido
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
