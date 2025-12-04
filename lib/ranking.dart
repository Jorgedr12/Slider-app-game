import 'package:flutter/material.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> ranking = List.generate(10, (i) {
      return {
        "name": "Player ${i + 1}",
        "score": (10000 - i * 527),
        "maxSpeed": "${(180 - i * 5)} km/h",
      };
    });

    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/menu_bg.png'),
            fit: BoxFit.cover,
            alignment: isPortrait ? Alignment.centerLeft : Alignment.center,
          ),
        ),
        child: SafeArea(
          child: isPortrait
              ? _buildPortraitLayout(ranking, context)
              : _buildLandscapeLayout(ranking),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(List<Map<String, dynamic>> ranking, context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Title RANKINGS
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: Border.all(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'TOP 10',
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),

        const SizedBox(height: 30),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.orange, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ranking.length,
              itemBuilder: (context, index) {
                final item = ranking[index];
                return _buildRankingCard(
                  position: index + 1,
                  name: item["name"],
                  score: item["score"],
                  maxSpeed: item["maxSpeed"],
                  isPortrait: true,
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Back button
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'BACK',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLandscapeLayout(List<Map<String, dynamic>> ranking) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth > 1200;

        return Stack(
          children: [
            // Back button (top left)
            Positioned(
              top: isLargeScreen ? 25 : 15,
              left: isLargeScreen ? 25 : 15,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(isLargeScreen ? 14 : 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: isLargeScreen ? 28 : 20,
                  ),
                ),
              ),
            ),

            // Title RANKINGS (top center)
            Positioned(
              top: isLargeScreen ? 25 : 15,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 35 : 25,
                    vertical: isLargeScreen ? 14 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TOP 10 RANKINGS',
                    style: TextStyle(
                      fontFamily: 'PressStart',
                      fontSize: isLargeScreen ? 24 : 16,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            // Rankings list (centered)
            Positioned(
              left: isLargeScreen ? 100 : 60,
              right: isLargeScreen ? 100 : 60,
              top: isLargeScreen ? 100 : 70,
              bottom: isLargeScreen ? 40 : 30,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border.all(color: Colors.orange, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    final item = ranking[index];
                    return _buildRankingCard(
                      position: index + 1,
                      name: item["name"],
                      score: item["score"],
                      maxSpeed: item["maxSpeed"],
                      isPortrait: false,
                      isLargeScreen: isLargeScreen,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRankingCard({
    required int position,
    required String name,
    required int score,
    required String maxSpeed,
    required bool isPortrait,
    bool isLargeScreen = false,
  }) {
    Color borderColor;
    Color bgColor;
    Color textColor;

    if (position == 1) {
      // gold
      borderColor = Color(0xFFFFD700);
      bgColor = Color(0xFFFFD700).withOpacity(0.2);
      textColor = Color(0xFFFFD700);
    } else if (position == 2) {
      // silver
      borderColor = Color(0xFFC0C0C0);
      bgColor = Color(0xFFC0C0C0).withOpacity(0.2);
      textColor = Color(0xFFC0C0C0);
    } else if (position == 3) {
      // bronze
      borderColor = Color(0xFFCD7F32);
      bgColor = Color(0xFFCD7F32).withOpacity(0.2);
      textColor = Color(0xFFCD7F32);
    } else {
      // normal
      borderColor = Colors.grey[600]!;
      bgColor = Colors.grey[800]!.withOpacity(0.5);
      textColor = Colors.grey[400]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isPortrait ? 10 : 8),
      padding: EdgeInsets.all(isLargeScreen ? 14 : (isPortrait ? 12 : 10)),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isLargeScreen ? 50 : (isPortrait ? 45 : 38),
            height: isLargeScreen ? 50 : (isPortrait ? 45 : 38),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              "$position",
              style: TextStyle(
                fontFamily: 'PressStart',
                fontSize: isLargeScreen ? 20 : (isPortrait ? 18 : 14),
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(width: isPortrait ? 15 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: isLargeScreen ? 16 : (isPortrait ? 14 : 11),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isPortrait ? 8 : 6),
                Row(
                  children: [
                    // Score
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: isLargeScreen ? 18 : (isPortrait ? 16 : 12),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "$score",
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: isLargeScreen ? 13 : (isPortrait ? 11 : 9),
                        color: Colors.yellow,
                      ),
                    ),
                    SizedBox(width: isPortrait ? 20 : 15),
                    // Max Speed
                    Icon(
                      Icons.speed,
                      color: Colors.orange,
                      size: isLargeScreen ? 18 : (isPortrait ? 16 : 12),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      maxSpeed,
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: isLargeScreen ? 13 : (isPortrait ? 11 : 9),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
