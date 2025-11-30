import 'package:flutter/material.dart';

/// Pantalla principal del menú estilo Initial D Arcade.
class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Fondo
            Positioned.fill(
              child: Image.asset(
                'assets/background/menu_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // Overlay oscuro
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
              ),
            ),

            // Contenido centrado
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Logo grande arriba
                  Image.asset(
                    'assets/logo/game_logo.png',
                    height: 450,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(),

                  // Menú estilo pixel arcade
                  Column(
                    children: [
                      _menuText('PLAY', selected: true, onTap: () {
                        Navigator.pushNamed(context, '/game');
                      }),

                      const SizedBox(height: 1),
                      _menuText('SHOP', onTap: () {
                        Navigator.pushNamed(context, '/shop');
                      }),
                      
                      const SizedBox(height: 1),
                      _menuText('RANKING', onTap: () {}),

                      const SizedBox(height: 1),
                      _menuText('SETTINGS', onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      }),

                      const SizedBox(height: 1),
                      _menuText('CREDITS', onTap: () {
                        Navigator.pushNamed(context, '/credits');
                      }),
                    ],
                  ),

                  const Spacer(),

                  // Copyright
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
            // Outline estilo pixel
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