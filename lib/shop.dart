import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/audio_manager.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int basePrice;
  final String imagePath;
  final ShopItemType type;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imagePath,
    required this.type,
  });
}

enum ShopItemType { healthUpgrade, fuelUpgrade, character }

class Shop extends StatefulWidget {
  const Shop({super.key});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  int coinBank = 0;
  int healthUpgradeCount = 0;
  int fuelUpgradeCount = 0;
  double maxFuel = 100;
  int maxLives = 3;
  List<String> ownedCharacters = [];

  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  late AudioPlayer _audioPlayer;

  final List<ShopItem> _shopItems = [
    ShopItem(
      id: 'health_upgrade',
      name: 'HEALTH UPGRADE',
      description: 'Increase max lives by 1',
      basePrice: 25,
      imagePath: 'assets/misc/wrench.png',
      type: ShopItemType.healthUpgrade,
    ),
    ShopItem(
      id: 'fuel_upgrade',
      name: 'FUEL UPGRADE',
      description: 'Increase max fuel by 20',
      basePrice: 25,
      imagePath: 'assets/misc/gasoline.png',
      type: ShopItemType.fuelUpgrade,
    ),
    ShopItem(
      id: 'character_manos_puercas',
      name: 'EL MANOS PUERCAS',
      description: 'Fastest Truck in Sonora',
      basePrice: 100,
      imagePath: 'assets/characters/manos_puercas.png',
      type: ShopItemType.character,
    ),
    ShopItem(
      id: 'character_da_baby',
      name: 'MIGUEL THE CREATOR',
      description: 'West Coast Menace',
      basePrice: 300,
      imagePath: 'assets/characters/miguel.png',
      type: ShopItemType.character,
    ),
    ShopItem(
      id: 'character_cirett',
      name: 'CIRETT',
      description: 'The Big One',
      basePrice: 999,
      imagePath: 'assets/characters/cirett.png',
      type: ShopItemType.character,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playShopMusic();
    _loadPlayerData();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  Future<void> _playShopMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      AudioManager.instance.setBytesPlayer(_audioPlayer);
      await _audioPlayer.setVolume(AudioManager.instance.effectiveMusicVolume);
      await _audioPlayer.play(AssetSource('music/shop_theme.m4a'));
    } catch (e) {}
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        coinBank = prefs.getInt('coin_bank') ?? 0;
        healthUpgradeCount = prefs.getInt('healthUpgradeCount') ?? 0;
        fuelUpgradeCount = prefs.getInt('fuelUpgradeCount') ?? 0;
        maxFuel = 100.0 + (fuelUpgradeCount * 20.0);
        maxLives = 3 + healthUpgradeCount;
        ownedCharacters = prefs.getStringList('ownedCharacters') ?? [];
      });
    } catch (e) {
      debugPrint('Error cargando datos del jugador: $e');
    }
  }

  Future<void> _savePlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coin_bank', coinBank);
      await prefs.setInt('healthUpgradeCount', healthUpgradeCount);
      await prefs.setInt('fuelUpgradeCount', fuelUpgradeCount);
      await prefs.setDouble('maxFuel', maxFuel);
      await prefs.setInt('maxLives', maxLives);
      await prefs.setStringList('ownedCharacters', ownedCharacters);
    } catch (e) {
      debugPrint('Error guardando datos del jugador: $e');
    }
  }

  int _calculatePrice(ShopItem item) {
    if (item.type == ShopItemType.healthUpgrade) {
      return item.basePrice * (1 << healthUpgradeCount);
    } else if (item.type == ShopItemType.fuelUpgrade) {
      return item.basePrice * (1 << fuelUpgradeCount);
    }
    return item.basePrice;
  }

  bool _isItemOwned(ShopItem item) {
    if (item.type == ShopItemType.character) {
      return ownedCharacters.contains(item.id);
    }
    return false;
  }

  bool _isMaxedOut(ShopItem item) {
    if (item.type == ShopItemType.fuelUpgrade) {
      return fuelUpgradeCount >= 5;
    }
    if (item.type == ShopItemType.healthUpgrade) {
      return healthUpgradeCount >= 5;
    }
    return false;
  }

  void _showPurchaseDialog(ShopItem item) {
    final price = _calculatePrice(item);
    final canAfford = coinBank >= price;
    final alreadyOwned = _isItemOwned(item);
    final isMaxed = _isMaxedOut(item);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.orange, width: 2),
          ),
          title: Text(
            'CONFIRM PURCHASE',
            style: TextStyle(
              fontFamily: 'PressStart',
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 14,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                item.description,
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 11,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (alreadyOwned)
                Text(
                  'ALREADY OWNED',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 12,
                    color: Colors.green,
                  ),
                )
              else if (isMaxed)
                Text(
                  'MAX LEVEL REACHED',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                )
              else if (!canAfford)
                Text(
                  'NOT ENOUGH COINS',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 12,
                    color: Colors.red,
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PRICE: ',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.monetization_on, color: Colors.yellow, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      '$price',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 12,
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            if (!alreadyOwned && !isMaxed)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (!alreadyOwned && !isMaxed && canAfford)
              TextButton(
                onPressed: () {
                  _purchaseItem(item);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'BUY',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ),
            if (alreadyOwned || !canAfford || isMaxed)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _purchaseItem(ShopItem item) {
    final price = _calculatePrice(item);

    setState(() {
      coinBank -= price;

      if (item.type == ShopItemType.healthUpgrade) {
        healthUpgradeCount++;
        maxLives = 3 + healthUpgradeCount;
      } else if (item.type == ShopItemType.fuelUpgrade) {
        fuelUpgradeCount++;
        maxFuel = 100.0 + (fuelUpgradeCount * 20.0);
      } else if (item.type == ShopItemType.character) {
        if (!ownedCharacters.contains(item.id)) {
          ownedCharacters.add(item.id);
        }
      }
    });

    _savePlayerData();
    AudioManager.instance.playSfx('sound effects/coin_recieved.m4a');
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/shop.png'),
            fit: BoxFit.cover,
            alignment: isPortrait ? Alignment.centerLeft : Alignment.center,
          ),
        ),
        child: SafeArea(
          child: isPortrait
              ? _buildPortraitLayout()
              : (isLargeScreen
                    ? _buildDesktopLayout()
                    : _buildLandscapeLayout()),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      border: Border.all(color: Colors.yellow, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$coinBank',
                          style: TextStyle(
                            fontFamily: 'PressStart',
                            fontSize: 14,
                            color: Colors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'SHOP',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 24,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 450,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _shopItems.length,
                itemBuilder: (context, index) {
                  return _buildShopItemCard(
                    _shopItems[index],
                    index,
                    isPortrait: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _shopItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.orange
                        : Colors.grey[600],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Stack(
      children: [
        Positioned(
          top: 15,
          left: 15,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),
        Positioned(
          top: 15,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'SHOP',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 15,
          right: 15,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              border: Border.all(color: Colors.yellow, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.yellow, size: 18),
                SizedBox(width: 6),
                Text(
                  '$coinBank',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 13,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 30,
          top: 80,
          bottom: 20,
          width: MediaQuery.of(context).size.width * 0.45,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _shopItems.length,
                  itemBuilder: (context, index) {
                    return _buildShopItemCard(
                      _shopItems[index],
                      index,
                      isPortrait: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _shopItems.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.orange
                          : Colors.grey[600],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        border: Border.all(color: Colors.orange, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          border: Border.all(color: Colors.orange, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'SHOP',
                          style: TextStyle(
                            fontFamily: 'PressStart',
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Coin display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      border: Border.all(color: Colors.yellow, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.yellow,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$coinBank',
                          style: TextStyle(
                            fontFamily: 'PressStart',
                            fontSize: 24,
                            color: Colors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Grid
        Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 1400),
            padding: const EdgeInsets.only(top: 140, bottom: 40),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 30,
                    ),
                    itemCount: _shopItems.length,
                    itemBuilder: (context, index) {
                      return _buildDesktopShopCard(_shopItems[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Desktop Card
  Widget _buildDesktopShopCard(ShopItem item) {
    final price = _calculatePrice(item);
    final canAfford = coinBank >= price;
    final isOwned = _isItemOwned(item);
    final isMaxed = _isMaxedOut(item);

    return GestureDetector(
      onTap: () => _showPurchaseDialog(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(
            color: isOwned ? Colors.green : Colors.orange,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isOwned ? Colors.green : Colors.orange).withOpacity(0.4),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Item image
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.grey[700]!, width: 2),
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(item.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Item name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.name,
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),

            const SizedBox(height: 12),

            // Item description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.description,
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),

            const SizedBox(height: 20),

            // Price or status
            if (isOwned)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'OWNED',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              )
            else if (isMaxed)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MAXED',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: canAfford
                      ? Colors.yellow.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  border: Border.all(
                    color: canAfford ? Colors.yellow : Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: canAfford ? Colors.yellow : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$price',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: 18,
                        color: canAfford ? Colors.yellow : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Level indicator
            if (item.type == ShopItemType.healthUpgrade)
              Text(
                healthUpgradeCount > 0
                    ? 'Level: $healthUpgradeCount/5'
                    : 'Not upgraded',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            if (item.type == ShopItemType.fuelUpgrade)
              Text(
                fuelUpgradeCount > 0
                    ? 'Level: $fuelUpgradeCount/5'
                    : 'Not upgraded',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItemCard(
    ShopItem item,
    int index, {
    required bool isPortrait,
  }) {
    final price = _calculatePrice(item);
    final canAfford = coinBank >= price;
    final isOwned = _isItemOwned(item);
    final isMaxed = _isMaxedOut(item);
    final scale = _currentPage == index ? 1.0 : 0.88;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: scale, end: scale),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () => _showPurchaseDialog(item),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isPortrait ? 15 : 8,
                vertical: isPortrait ? 20 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                border: Border.all(
                  color: isOwned ? Colors.green : Colors.orange,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isOwned ? Colors.green : Colors.orange).withOpacity(
                      0.3,
                    ),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Item image
                  Container(
                    width: isLargeScreen ? 220 : (isPortrait ? 140 : 80),
                    height: isLargeScreen ? 220 : (isPortrait ? 140 : 80),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.grey[600]!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: AssetImage(item.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: isPortrait ? 20 : 10),

                  // Item name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: isPortrait ? 16 : 11,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),

                  SizedBox(height: isPortrait ? 12 : 6),

                  // Item description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.description,
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: isPortrait ? 11 : 7,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),

                  SizedBox(height: isPortrait ? 15 : 8),

                  // Price or owned status
                  if (isOwned)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPortrait ? 15 : 10,
                        vertical: isPortrait ? 8 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OWNED',
                        style: TextStyle(
                          fontFamily: 'PressStart',
                          fontSize: isLargeScreen ? 18 : (isPortrait ? 14 : 9),
                          color: Colors.green,
                        ),
                      ),
                    )
                  else if (isMaxed)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 22 : (isPortrait ? 15 : 10),
                        vertical: isLargeScreen ? 12 : (isPortrait ? 8 : 5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'MAXED',
                        style: TextStyle(
                          fontFamily: 'PressStart',
                          fontSize: isLargeScreen ? 18 : (isPortrait ? 14 : 9),
                          color: Colors.blue,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 22 : (isPortrait ? 15 : 10),
                        vertical: isLargeScreen ? 12 : (isPortrait ? 8 : 5),
                      ),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? Colors.yellow.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        border: Border.all(
                          color: canAfford ? Colors.yellow : Colors.red,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: canAfford ? Colors.yellow : Colors.red,
                            size: isLargeScreen ? 24 : (isPortrait ? 18 : 12),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$price',
                            style: TextStyle(
                              fontFamily: 'PressStart',
                              fontSize: isLargeScreen
                                  ? 18
                                  : (isPortrait ? 15 : 10),
                              color: canAfford ? Colors.yellow : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: isPortrait ? 10 : 5),

                  // Level indicator for upgrades
                  if (item.type == ShopItemType.healthUpgrade)
                    Text(
                      healthUpgradeCount > 0
                          ? 'Level: $healthUpgradeCount/5'
                          : 'Not upgraded',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: isPortrait ? 9 : 6,
                        color: Colors.grey[500],
                      ),
                    ),
                  if (item.type == ShopItemType.fuelUpgrade)
                    Text(
                      fuelUpgradeCount > 0
                          ? 'Level: $fuelUpgradeCount/5'
                          : 'Not upgraded',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: isPortrait ? 9 : 6,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
