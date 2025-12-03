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

  /// ⭐ CARGA DE DATOS - Lee desde SharedPreferences
  Future<void> _loadPlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Cargar monedas
        coinBank = prefs.getInt('coin_bank') ?? 0;

        // Cargar contadores de mejoras
        healthUpgradeCount = prefs.getInt('healthUpgradeCount') ?? 0;
        fuelUpgradeCount = prefs.getInt('fuelUpgradeCount') ?? 0;

        // Recalcular valores máximos basados en mejoras
        // IMPORTANTE: Usar la misma fórmula que en racing_game.dart
        maxFuel = 100.0 + (fuelUpgradeCount * 20.0);
        maxLives = 3 + healthUpgradeCount;

        // Cargar personajes comprados
        ownedCharacters = prefs.getStringList('ownedCharacters') ?? [];
      });

      debugPrint('📊 Datos cargados en Shop:');
      debugPrint('   Monedas: $coinBank');
      debugPrint(
        '   Health Upgrades: $healthUpgradeCount (Max Lives: $maxLives)',
      );
      debugPrint('   Fuel Upgrades: $fuelUpgradeCount (Max Fuel: $maxFuel)');
      debugPrint('   Personajes: ${ownedCharacters.length}');
    } catch (e) {
      debugPrint('❌ Error cargando datos del jugador: $e');
    }
  }

  /// ⭐ GUARDADO DE DATOS - Escribe en SharedPreferences
  Future<void> _savePlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar monedas
      await prefs.setInt('coin_bank', coinBank);

      // ⭐ CRÍTICO: Guardar contadores de mejoras (incrementados)
      await prefs.setInt('healthUpgradeCount', healthUpgradeCount);
      await prefs.setInt('fuelUpgradeCount', fuelUpgradeCount);

      // Guardar valores máximos recalculados
      await prefs.setDouble('maxFuel', maxFuel);
      await prefs.setInt('maxLives', maxLives);

      // Guardar personajes
      await prefs.setStringList('ownedCharacters', ownedCharacters);

      debugPrint('💾 Datos guardados en Shop:');
      debugPrint('   Health Upgrades: $healthUpgradeCount');
      debugPrint('   Fuel Upgrades: $fuelUpgradeCount');
      debugPrint('   Max Fuel: $maxFuel');
      debugPrint('   Max Lives: $maxLives');
    } catch (e) {
      debugPrint('❌ Error guardando datos del jugador: $e');
    }
  }

  /// ⭐ CÁLCULO DE PRECIO - Se duplica con cada compra (1 << n es 2^n)
  int _calculatePrice(ShopItem item) {
    if (item.type == ShopItemType.healthUpgrade) {
      // Precio = basePrice * 2^healthUpgradeCount
      // 25, 50, 100, 200, 400, 800, 1600, 3200...
      return item.basePrice * (1 << healthUpgradeCount);
    } else if (item.type == ShopItemType.fuelUpgrade) {
      // Precio = basePrice * 2^fuelUpgradeCount
      // 25, 50, 100, 200, 400, 800, 1600, 3200...
      return item.basePrice * (1 << fuelUpgradeCount);
    }
    // Personajes tienen precio fijo
    return item.basePrice;
  }

  bool _isItemOwned(ShopItem item) {
    if (item.type == ShopItemType.character) {
      return ownedCharacters.contains(item.id);
    }
    return false;
  }

  /// ⭐ LÍMITES MÁXIMOS para evitar valores infinitos
  bool _isMaxedOut(ShopItem item) {
    if (item.type == ShopItemType.fuelUpgrade) {
      // Límite: 5 mejoras = 100 + (5*20) = 200 de combustible
      return fuelUpgradeCount >= 5; // o maxFuel >= 200
    }
    if (item.type == ShopItemType.healthUpgrade) {
      // Límite: 5 mejoras = 3 + 5 = 8 vidas
      return healthUpgradeCount >= 5; // o maxLives >= 8
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

  /// ⭐ COMPRA DE ITEMS - Incrementa contadores y recalcula valores
  void _purchaseItem(ShopItem item) {
    final price = _calculatePrice(item);

    setState(() {
      // Descontar monedas
      coinBank -= price;

      if (item.type == ShopItemType.healthUpgrade) {
        // ⭐ INCREMENTAR CONTADOR en SharedPreferences
        healthUpgradeCount++;
        // Recalcular valor máximo
        maxLives = 3 + healthUpgradeCount;

        debugPrint('✅ Health Upgrade comprado!');
        debugPrint('   Nivel: $healthUpgradeCount');
        debugPrint('   Max Lives: $maxLives');
        debugPrint('   Próximo precio: ${_calculatePrice(item)}');
      } else if (item.type == ShopItemType.fuelUpgrade) {
        // ⭐ INCREMENTAR CONTADOR en SharedPreferences
        fuelUpgradeCount++;
        // Recalcular valor máximo
        maxFuel = 100.0 + (fuelUpgradeCount * 20.0);

        debugPrint('✅ Fuel Upgrade comprado!');
        debugPrint('   Nivel: $fuelUpgradeCount');
        debugPrint('   Max Fuel: $maxFuel');
        debugPrint('   Próximo precio: ${_calculatePrice(item)}');
      } else if (item.type == ShopItemType.character) {
        if (!ownedCharacters.contains(item.id)) {
          ownedCharacters.add(item.id);
          debugPrint('✅ Personaje comprado: ${item.name}');
        }
      }
    });

    // ⭐ GUARDAR TODO en SharedPreferences
    _savePlayerData();

    // Opcional: Reproducir sonido de compra
    AudioManager.instance.playSfx('sound effects/coin_recieved.m4a');
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

        // Title SHOP (top center)
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
                'SHOP',
                style: TextStyle(
                  fontFamily: 'PressStart',
                  fontSize: isLargeScreen ? 26 : 18,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),

        // Coin display (top right)
        Positioned(
          top: isLargeScreen ? 25 : 15,
          right: isLargeScreen ? 25 : 15,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 16 : 12,
              vertical: isLargeScreen ? 10 : 8,
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
                  size: isLargeScreen ? 24 : 18,
                ),
                SizedBox(width: isLargeScreen ? 8 : 6),
                Text(
                  '$coinBank',
                  style: TextStyle(
                    fontFamily: 'PressStart',
                    fontSize: isLargeScreen ? 17 : 13,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Shop items carousel (centered right)
        Positioned(
          right: isLargeScreen ? 50 : 30,
          top: isLargeScreen ? 120 : 80,
          bottom: isLargeScreen ? 30 : 20,
          width: isLargeScreen
              ? MediaQuery.of(context).size.width * 0.55
              : MediaQuery.of(context).size.width * 0.45,
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
                  // Item image (real asset)
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

                  // ⭐ Mostrar nivel actual de mejoras
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
