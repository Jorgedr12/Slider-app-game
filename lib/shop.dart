import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

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
  List<String> ownedCharacters = [];

  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  late AudioPlayer _audioPlayer;

  final List<ShopItem> _shopItems = [
    ShopItem(
      id: 'health_upgrade',
      name: 'HEALTH UPGRADE',
      description: 'Increase your health capacity',
      basePrice: 25,
      imagePath: 'assets/shop/health_upgrade.png',
      type: ShopItemType.healthUpgrade,
    ),
    ShopItem(
      id: 'fuel_upgrade',
      name: 'FUEL UPGRADE',
      description: 'Increase max fuel by 25',
      basePrice: 25,
      imagePath: 'assets/shop/fuel_upgrade.png',
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
      name: 'DA BABY',
      description: 'East Coast Menace',
      basePrice: 300,
      imagePath: 'assets/characters/da_baby.png',
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
      await _audioPlayer.setVolume(0.4);
      await _audioPlayer.play(AssetSource('music/shop_theme.m4a'));
    } catch (e) {
      debugPrint('Error al reproducir música de la tienda: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coinBank = prefs.getInt('coin_bank') ?? 0;
      healthUpgradeCount = prefs.getInt('healthUpgradeCount') ?? 0;
      fuelUpgradeCount = prefs.getInt('fuelUpgradeCount') ?? 0;
      maxFuel = prefs.getDouble('maxFuel') ?? 100.0;
      ownedCharacters = prefs.getStringList('ownedCharacters') ?? [];
    });
  }

  Future<void> _savePlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin_bank', coinBank);
    await prefs.setInt('healthUpgradeCount', healthUpgradeCount);
    await prefs.setInt('fuelUpgradeCount', fuelUpgradeCount);
    await prefs.setDouble('maxFuel', maxFuel);
    await prefs.setStringList('ownedCharacters', ownedCharacters);
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

  void _showPurchaseDialog(ShopItem item) {
    final price = _calculatePrice(item);
    final canAfford = coinBank >= price;
    final alreadyOwned = _isItemOwned(item);

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
            if (!alreadyOwned)
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
            if (!alreadyOwned && canAfford)
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
            if (alreadyOwned || !canAfford)
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
      } else if (item.type == ShopItemType.fuelUpgrade) {
        fuelUpgradeCount++;
        maxFuel += 25;
      } else if (item.type == ShopItemType.character) {
        if (!ownedCharacters.contains(item.id)) {
          ownedCharacters.add(item.id);
        }
      }
    });

    _savePlayerData();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

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
          child: isPortrait ? _buildPortraitLayout() : _buildLandscapeLayout(),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Stack(
      children: [
        Column(
          children: [
            // Header con botón y monedas
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
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

                  // Coin display
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

            // Title SHOP
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

            // Item carousel - con altura limitada
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

            // Page indicators
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
        // Back button (top left)
        Positioned(
          top: 15,
          left: 15,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),

        // Title SHOP (top center)
        Positioned(
          top: 15,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
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

        // Coin display (top right)
        Positioned(
          top: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              border: Border.all(color: Colors.yellow, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.yellow, size: 18),
                const SizedBox(width: 6),
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

        // Shop items carousel (centered right)
        Positioned(
          right: 30,
          top: 80,
          bottom: 20,
          width: MediaQuery.of(context).size.width * 0.45,
          child: Column(
            children: [
              // Item carousel
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

              // Page indicators
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

  Widget _buildShopItemCard(
    ShopItem item,
    int index, {
    required bool isPortrait,
  }) {
    final price = _calculatePrice(item);
    final canAfford = coinBank >= price;
    final isOwned = _isItemOwned(item);
    final scale = _currentPage == index ? 1.0 : 0.88;

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
                  // Item image (real asset)
                  Container(
                    width: isPortrait ? 140 : 80,
                    height: isPortrait ? 140 : 80,
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
                          fontSize: isPortrait ? 14 : 9,
                          color: Colors.green,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPortrait ? 15 : 10,
                        vertical: isPortrait ? 8 : 5,
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
                            size: isPortrait ? 18 : 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$price',
                            style: TextStyle(
                              fontFamily: 'PressStart',
                              fontSize: isPortrait ? 15 : 10,
                              color: canAfford ? Colors.yellow : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: isPortrait ? 10 : 5),

                  // Additional info for upgrades
                  if (item.type == ShopItemType.healthUpgrade &&
                      healthUpgradeCount > 0)
                    Text(
                      'Owned: $healthUpgradeCount',
                      style: TextStyle(
                        fontFamily: 'PressStart',
                        fontSize: isPortrait ? 9 : 6,
                        color: Colors.grey[500],
                      ),
                    ),
                  if (item.type == ShopItemType.fuelUpgrade &&
                      fuelUpgradeCount > 0)
                    Text(
                      'Owned: $fuelUpgradeCount',
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
