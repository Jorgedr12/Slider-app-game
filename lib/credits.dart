import 'package:flutter/material.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  int _currentIndex = 0;

  final List<Map<String, String>> developers = [
    {
      'name': 'JORGE DUARTE',
      'role': 'ART & UI DESIGN',
      'image': 'assets/credits/yorch.png',
    },
    {
      'name': 'DANIEL ESTRADA',
      'role': 'GAME DESIGNER',
      'image': 'assets/credits/daniel.png',
    },
    {
      'name': 'KEVIN MARTINEZ',
      'role': 'GAME DESIGNER',
      'image': 'assets/credits/kevin.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background/car_select.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                const SizedBox(height: 20),

                Expanded(
                  child: PageView.builder(
                    itemCount: developers.length,
                    onPageChanged: (i) {
                      setState(() => _currentIndex = i);
                    },
                    itemBuilder: (context, index) {
                      return isPortrait
                          ? _buildPortraitCard(developers[index])
                          : _buildLandscapeCard(developers[index]);
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    developers.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == i ? 14 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? Colors.orange
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildFooterCredits(),

                const SizedBox(height: 15),

                _buildBackButton(),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: const Border(
          bottom: BorderSide(color: Colors.orange, width: 3),
        ),
      ),
      child: Center(
        child: Text(
          'CREDITS',
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

  // CARD - PORTRAIT
  Widget _buildPortraitCard(Map<String, String> dev) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Image.asset(dev['image']!, fit: BoxFit.cover),
        ),
        const SizedBox(height: 20),
        Text(
          dev['name']!,
          style: TextStyle(
            fontFamily: 'PixelifySans',
            fontSize: 28,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          dev['role']!,
          style: TextStyle(
            fontFamily: 'PressStart',
            fontSize: 12,
            color: Colors.orangeAccent,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // CARD - LANDSCAPE
  Widget _buildLandscapeCard(Map<String, String> dev) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Image.asset(dev['image']!, fit: BoxFit.cover),
        ),
        const SizedBox(width: 40),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dev['name']!,
              style: TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              dev['role']!,
              style: TextStyle(
                fontFamily: 'PressStart',
                fontSize: 11,
                color: Colors.orangeAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  // FOOTER CREDITS
  Widget _buildFooterCredits() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          'Images generated with Gemini\n'
          'Music obtained from: Suno.com and YouTube, free of copyright claims\n'
          'Sound effects obtained from: pixabay.com',
          style: TextStyle(
            fontFamily: 'PressStart',
            fontSize: 9,
            color: Colors.white70,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // BACK BUTTON
  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const Icon(Icons.arrow_back, color: Colors.white, size: 16),
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
    );
  }
}
