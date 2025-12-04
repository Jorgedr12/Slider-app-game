import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/audio_manager.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      AudioManager.instance.setBytesPlayer(_audioPlayer);

      await _audioPlayer.setVolume(AudioManager.instance.effectiveMusicVolume);

      await _audioPlayer.play(AssetSource('music/menu_theme.m4a'));
    } catch (e) {
      debugPrint('Error al reproducir música: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioManager.instance.clearCurrentPlayer(_audioPlayer);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_audioPlayer.state == PlayerState.playing) {
        _audioPlayer.pause();
        _wasPlaying = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlaying) {
        _audioPlayer.resume();
        _wasPlaying = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/background/menu_bg.png',
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.25)),
              ),

              orientation == Orientation.portrait
                  ? _buildPortraitLayout()
                  : _buildLandscapeLayout(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),

          Image.asset(
            'assets/logo/game_logo.png',
            height: 450,
            fit: BoxFit.contain,
          ),

          const Spacer(),

          _buildMenuList(),

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
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Center(
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/logo/game_logo.png',
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuList(),

                const SizedBox(height: 20),

                Text(
                  '©1999 しげの秀一　©1999 講談社／JAM',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return Column(
      children: [
        _menuText(
          'PLAY',
          selected: true,
          onTap: () {
            Navigator.pushNamed(context, '/car_selection');
          },
        ),
        const SizedBox(height: 1),
        _menuText(
          'SHOP',
          onTap: () {
            _audioPlayer.stop();
            Navigator.pushNamed(context, '/shop').then((_) {
              _playBackgroundMusic();
            });
          },
        ),
        const SizedBox(height: 1),
        _menuText(
          'RANKING',
          onTap: () {
            _audioPlayer.stop();
            Navigator.pushNamed(context, '/ranking').then((_) {
              _playBackgroundMusic();
            });
          },
        ),
        const SizedBox(height: 1),
        _menuText(
          'SETTINGS',
          onTap: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
        const SizedBox(height: 1),
        _menuText(
          'CREDITS',
          onTap: () {
            _audioPlayer.stop();
            Navigator.pushNamed(context, '/credits').then((_) {
              _playBackgroundMusic();
            });
          },
        ),
      ],
    );
  }

  Widget _menuText(
    String text, {
    bool selected = false,
    required VoidCallback onTap,
  }) {
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
