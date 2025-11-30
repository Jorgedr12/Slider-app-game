import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); 
      await _audioPlayer.setVolume(0.4); 
      await _audioPlayer.play(AssetSource('music/menu_theme.m4a'));
    } catch (e) {
      debugPrint('Error al reproducir música: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/background/menu_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
              ),
            ),

            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/logo/game_logo.png',
                    height: 450,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(),

                  Column(
                    children: [
                      _menuText('PLAY', selected: true, onTap: () {
                        _audioPlayer.stop(); // Detener música al salir
                        Navigator.pushNamed(context, '/game');
                      }),

                      const SizedBox(height: 1),
                      _menuText('SHOP', onTap: () {
                        _audioPlayer.stop();
                        Navigator.pushNamed(context, '/shop');
                      }),
                      
                      const SizedBox(height: 1),
                      _menuText('RANKING', onTap: () {}),

                      const SizedBox(height: 1),
                      _menuText('SETTINGS', onTap: () {
                        _audioPlayer.stop();
                        Navigator.pushNamed(context, '/settings');
                      }),

                      const SizedBox(height: 1),
                      _menuText('CREDITS', onTap: () {
                        _audioPlayer.stop();
                        Navigator.pushNamed(context, '/credits');
                      }),
                    ],
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      '©1999 しげの秀一　©1999 講談社／JAM',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuText(String text,
      {bool selected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'PixelifySans',
          fontSize: 35,
          letterSpacing: 1,
          color: selected ? Colors.orangeAccent : Colors.blue[300],
          shadows: [
            const Shadow(offset: Offset(-1, -1), color: Colors.black),
            const Shadow(offset: Offset(1, -1), color: Colors.black),
            const Shadow(offset: Offset(-1, 1), color: Colors.black),
            const Shadow(offset: Offset(1, 1), color: Colors.black),
          ],
        ),
      ),
    );
  }
}