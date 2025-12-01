import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Overlay de pausa con estética de Initial D
/// Se muestra sobre el juego cuando se pausa
class PauseMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final AudioPlayer? gameAudioPlayer;

  const PauseMenu({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
    this.gameAudioPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título "PAUSA"
              Text(
                'PAUSA',
                style: TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 60,
                  letterSpacing: 4,
                  color: Colors.orangeAccent,
                  shadows: [
                    const Shadow(offset: Offset(-2, -2), color: Colors.black),
                    const Shadow(offset: Offset(2, -2), color: Colors.black),
                    const Shadow(offset: Offset(-2, 2), color: Colors.black),
                    const Shadow(offset: Offset(2, 2), color: Colors.black),
                    Shadow(
                      offset: const Offset(0, 0),
                      blurRadius: 10,
                      color: Colors.orange.withOpacity(0.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Línea decorativa superior
              Container(
                width: 300,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.orangeAccent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Botón Reanudar
              _buildMenuButton(
                context,
                icon: Icons.play_arrow,
                text: 'REANUDAR',
                color: Colors.green,
                onTap: onResume,
              ),

              const SizedBox(height: 20),

              // Botón Reiniciar
              _buildMenuButton(
                context,
                icon: Icons.restart_alt,
                text: 'REINICIAR',
                color: Colors.blue[300]!,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: '¿REINICIAR PARTIDA?',
                    message: 'Perderás todo el progreso actual',
                    confirmText: 'REINICIAR',
                    onConfirm: onRestart,
                  );
                },
              ),

              const SizedBox(height: 20),

              // Botón Salir
              _buildMenuButton(
                context,
                icon: Icons.exit_to_app,
                text: 'SALIR AL MENÚ',
                color: Colors.red[300]!,
                onTap: () {
                  _showConfirmDialog(
                    context,
                    title: '¿SALIR AL MENÚ?',
                    message: 'Perderás todo el progreso actual',
                    confirmText: 'SALIR',
                    onConfirm: onExit,
                  );
                },
              ),

              const SizedBox(height: 40),

              // Línea decorativa inferior
              Container(
                width: 300,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.orangeAccent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Texto de ayuda
              Text(
                'Presiona ESC para reanudar',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
              shadows: [
                const Shadow(offset: Offset(-1, -1), color: Colors.black),
                const Shadow(offset: Offset(1, -1), color: Colors.black),
                const Shadow(offset: Offset(-1, 1), color: Colors.black),
                const Shadow(offset: Offset(1, 1), color: Colors.black),
              ],
            ),
            const SizedBox(width: 15),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: 24,
                letterSpacing: 1,
                color: color,
                shadows: [
                  const Shadow(offset: Offset(-1, -1), color: Colors.black),
                  const Shadow(offset: Offset(1, -1), color: Colors.black),
                  const Shadow(offset: Offset(-1, 1), color: Colors.black),
                  const Shadow(offset: Offset(1, 1), color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              border: Border.all(color: Colors.orangeAccent, width: 3),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 28,
                    letterSpacing: 1,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón Cancelar
                    _buildDialogButton(
                      text: 'CANCELAR',
                      color: Colors.grey,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    // Botón Confirmar
                    _buildDialogButton(
                      text: confirmText,
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        onConfirm();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'PixelifySans',
            fontSize: 18,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
