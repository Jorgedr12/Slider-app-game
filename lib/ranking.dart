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

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B29), // Metal oscuro
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3A332C), // Bronce
                  Color(0xFF1F1B18), // Cobre
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Borde estilo metal
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF8A6A3F), // cobre
                width: 5,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "TOP 10 RANKING",
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5C287), // dorado
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    final item = ranking[index];
                    return _buildSteampunkCard(
                      position: index + 1,
                      name: item["name"],
                      score: item["score"],
                      maxSpeed: item["maxSpeed"],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 30,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF704E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC8A26E),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      "BACK",
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        color: Color(0xFFF5E3B2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tarjeta
  Widget _buildSteampunkCard({
    required int position,
    required String name,
    required int score,
    required String maxSpeed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3F352C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8A6A3F), width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Número del ranking
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF704E2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8A26E), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                "$position",
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  color: Color(0xFFF5E3B2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Info de jugador
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      color: Color(0xFFE7D7AA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Score: $score",
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 12,
                          color: Color(0xFFD8C18C),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Text(
                        "Max Speed: $maxSpeed",
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 12,
                          color: Color(0xFFD8C18C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
