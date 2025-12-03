import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/audio_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioManager _audioManager = AudioManager.instance;

  double _masterVolume = 1.0;
  double _musicVolume = 1.0;
  double _sfxVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadAudioSettings();
  }

  void _loadAudioSettings() {
    _masterVolume = _audioManager.masterVolume;
    _musicVolume = _audioManager.musicVolume;
    _sfxVolume = _audioManager.sfxVolume;
  }



  @override
  void dispose() {
    super.dispose();
  }


  TextStyle _getRetroStyle({double fontSize = 16, Color color = Colors.white}) {
    return TextStyle(
      fontFamily: 'PixelifySans', 
      fontSize: fontSize,
      color: color,
      letterSpacing: 2,
      shadows: const [
        Shadow(offset: Offset(2, 2), color: Colors.black),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgImage = 'assets/background/menu_bg.png';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0058b0),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "CONFIGURACIÓN",
          style: _getRetroStyle(fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: Colors.white, height: 4),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.black),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85), // Fondo oscuro semitransparente
                    border: Border.all(color: Colors.white, width: 4), // Borde blanco grueso
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(8, 8), // Sombra de caja dura
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "AUDIO SYSTEM",
                        style: _getRetroStyle(color: Colors.yellowAccent, fontSize: 28),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Colors.white30,
                        margin: const EdgeInsets.only(bottom: 30),
                      ),

                      _buildRetroSlider(
                        label: "MASTER",
                        value: _masterVolume,
                        color: Colors.cyanAccent,
                        onChanged: (val) {
                          setState(() => _masterVolume = val);
                          _audioManager.setMasterVolume(val);
                        },
                      ),

                      const SizedBox(height: 30),

                      _buildRetroSlider(
                        label: "MUSIC",
                        value: _musicVolume,
                        color: Colors.greenAccent,
                        onChanged: (val) {
                          setState(() => _musicVolume = val);
                          _audioManager.setMusicVolume(val);
                        },
                      ),

                      const SizedBox(height: 30),

                      _buildRetroSlider(
                        label: "SFX",
                        value: _sfxVolume,
                        color: Colors.orangeAccent,
                        onChanged: (val) {
                          setState(() => _sfxVolume = val);
                          _audioManager.setSfxVolume(val);
                        },
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label, 
              style: _getRetroStyle(fontSize: 20),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: _getRetroStyle(color: color, fontSize: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 30,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 14,
              activeTrackColor: color,
              inactiveTrackColor: Colors.grey[800],
              disabledActiveTrackColor: Colors.grey,
              disabledInactiveTrackColor: Colors.grey,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), 
              overlayShape: SliderComponentShape.noOverlay,
              trackShape: const RectangularSliderTrackShape(),
              thumbColor: Colors.transparent,
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.transparent,
                  ),
                ),
                Slider(
                  value: value, 
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}