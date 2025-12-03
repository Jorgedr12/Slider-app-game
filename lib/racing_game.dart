import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slider_app/game_size_config.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Clase principal del juego de carreras
/// Maneja la lógica del juego, física, colisiones y estado
class RacingGame extends FlameGame
    with KeyboardEvents, HasCollisionDetection, PanDetector {
  // Estado del juego
  double distance = 0;
  double fuel = 100;
  double maxFuel = 100;
  int obstaclesAvoided = 0;
  int coinsCollected = 0;
  int coinBank = 0; // Monedas acumuladas persistentes para la tienda
  double maxSpeed = 0;
  double currentSpeed = 0;
  bool isGameOver = false;
  int lives = 3;
  int maxLives = 3;

  // Configuración
  bool isVertical = true;
  bool debugMode = false; // ⭐ MODO DEBUG DESACTIVADO
  String selectedCarSprite = 'cars/orange_car.png';
  String selectedTrack = 'montana';
  String currentTrackName = 'MONTE AKINA';

  // Velocidad del juego
  double gameSpeed = 400.0;
  double baseSpeed = 400.0;
  double speedIncrement = 10.0;

  // ⭐ NUEVO: Configuración de tamaños
  late GameSizeConfig sizeConfig;

  // Componentes principales
  late PlayerCar playerCar;
  late TrackBackground trackBackground;

  // Callbacks
  Function()? onPauseRequest;
  Function()? onGameOver;

  int _obstacleSpawnCount = 0;
  double _timeSinceLastSpawn = 0;
  double _currentSpawnInterval = 1.5;

  RacingGame({
    this.isVertical = true,
    this.selectedCarSprite = 'cars/orange_car.png',
    this.selectedTrack = 'akina',
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Asegurar que Flame busque imágenes bajo la carpeta 'assets/'
    // Debe terminar en '/': evita error "Prefix must be empty or end with a /"
    Flame.images.prefix = 'assets/';

    // ⭐ PRE-CARGA DE ASSETS
    // Cargamos todo en memoria ahora para evitar lag durante el juego
    try {
      await Flame.images.loadAll([
        selectedCarSprite,
        'escenarios/$selectedTrack/road.png',
        'escenarios/$selectedTrack/left.png',
        'escenarios/$selectedTrack/right.png',
        'obstacles/cone.png',
        'obstacles/llantas.png',
        'obstacles/valla.png',
        // 'obstacles/coin.png', // No existen aún
        // 'obstacles/fuel.png', // No existen aún
      ]);
      debugPrint('✅ Assets precargados correctamente');
    } catch (e) {
      debugPrint('⚠️ Error precargando assets: $e');
    }

    // ⭐ NUEVO: Inicializar configuración de tamaños
    sizeConfig = GameSizeConfig(
      screenSize: Size(size.x, size.y),
      isVertical: isVertical,
    );

    debugPrint('═══════════════════════════════════');
    debugPrint('📐 CONFIGURACIÓN DE TAMAÑOS:');
    debugPrint('   Pantalla: ${size.x.toInt()}x${size.y.toInt()}');
    debugPrint('   Orientación: ${isVertical ? "Vertical" : "Horizontal"}');
    debugPrint('   Carriles: ${sizeConfig.numberOfLanes}');
    debugPrint('   Ancho carril: ${sizeConfig.laneWidth.toInt()}px');
    debugPrint(
      '   Tamaño carro: ${sizeConfig.carWidth.toInt()}x${sizeConfig.carHeight.toInt()}',
    );
    debugPrint('   Ancho carretera: ${sizeConfig.roadWidth.toInt()}px');
    debugPrint('   Ancho lados: ${sizeConfig.sideWidth.toInt()}px');
    debugPrint('═══════════════════════════════════');

    camera.viewfinder.anchor = Anchor.topLeft;

    // Crear el fondo de la pista
    trackBackground = TrackBackground(
      isVertical: isVertical,
      trackName: selectedTrack,
    );
    world.add(trackBackground);

    // Crear el carro del jugador
    playerCar = PlayerCar(
      isVertical: isVertical,
      carSpritePath: selectedCarSprite,
    );
    world.add(playerCar);

    // Cargar banco de monedas persistente
    await _loadPlayerData();

    _resetSpawnTimer();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!paused && !isGameOver) {
      distance += gameSpeed * dt / 10;
      fuel -= 2.5 * dt; // Consumo reducido (antes 8)
      gameSpeed += speedIncrement * dt;
      currentSpeed = gameSpeed / 2.78;

      if (currentSpeed > maxSpeed) {
        maxSpeed = currentSpeed;
      }

      trackBackground.gameSpeed = gameSpeed;

      if (fuel <= 0) {
        fuel = 0;
        _triggerGameOver();
      }

      // ⭐ Lógica de spawn progresivo
      _timeSinceLastSpawn += dt;

      // Calcular intervalo basado en velocidad: A mayor velocidad, menor intervalo
      // Base: 400 speed -> 1.5s (vertical) / 1.0s (horizontal)
      // Max: 1000 speed -> 0.5s (vertical) / 0.3s (horizontal)
      double speedFactor = (gameSpeed - baseSpeed) / 600.0; // 0.0 a 1.0 aprox
      speedFactor = speedFactor.clamp(0.0, 1.0);

      double baseInterval = isVertical ? 1.5 : 1.0;
      double minInterval = isVertical ? 0.5 : 0.3;

      _currentSpawnInterval =
          baseInterval - (speedFactor * (baseInterval - minInterval));

      if (_timeSinceLastSpawn >= _currentSpawnInterval) {
        _timeSinceLastSpawn = 0;
        _spawnObstacle();
        _obstacleSpawnCount++;

        // Monedas cada 4 obstáculos
        if (_obstacleSpawnCount % 4 == 0) {
          _spawnCoin();
        }

        // Gasolina cada 10 obstáculos
        if (_obstacleSpawnCount % 10 == 0) {
          _spawnFuel();
        }
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (paused) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        onPauseRequest?.call();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        onPauseRequest?.call();
        return KeyEventResult.handled;
      }

      playerCar.handleKeyDown(event.logicalKey);
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      playerCar.handleKeyUp(event.logicalKey);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void onPanStart(DragStartInfo info) {
    // No longer needed
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (paused || isGameOver) return;

    final delta = info.delta.global;

    if (isVertical) {
      playerCar.position.x += delta.x;
    } else {
      playerCar.position.y += delta.y;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    // No longer needed
  }

  void _resetSpawnTimer() {
    // Reiniciar contadores de spawn
    _timeSinceLastSpawn = 0;
    _currentSpawnInterval = isVertical ? 1.5 : 1.0;
  }

  bool _isInRoadBounds(PositionComponent component) {
    final config = sizeConfig;
    final double roadStart = config.sideWidth;
    final double roadEnd = config.sideWidth + config.roadWidth;

    // Margen de tolerancia
    const double tolerance = 20.0;

    if (isVertical) {
      return component.position.x >= roadStart - tolerance &&
          component.position.x <= roadEnd + tolerance;
    } else {
      return component.position.y >= roadStart - tolerance &&
          component.position.y <= roadEnd + tolerance;
    }
  }

  void _spawnObstacle() {
    final obstacle = ObstacleComponent(
      isVertical: isVertical,
      gameSpeed: gameSpeed,
    );
    world.add(obstacle);
  }

  void _spawnCoin() {
    final coin = CoinComponent(isVertical: isVertical, gameSpeed: gameSpeed);
    world.add(coin);
  }

  void _spawnFuel() {
    final fuelItem = FuelComponent(
      isVertical: isVertical,
      gameSpeed: gameSpeed,
    );
    world.add(fuelItem);
  }

  void _triggerGameOver() {
    isGameOver = true;
    pauseEngine();
    onGameOver?.call();
  }

  void resetGame() {
    distance = 0;
    fuel = maxFuel;
    obstaclesAvoided = 0;
    coinsCollected = 0;
    lives = maxLives;
    maxSpeed = 0;
    currentSpeed = 0;
    gameSpeed = baseSpeed;
    isGameOver = false;
    _obstacleSpawnCount = 0;

    world.children.whereType<ObstacleComponent>().forEach((obs) {
      obs.removeFromParent();
    });
    world.children.whereType<CoinComponent>().forEach((c) {
      c.removeFromParent();
    });
    world.children.whereType<FuelComponent>().forEach((f) {
      f.removeFromParent();
    });

    playerCar.resetPosition();
    trackBackground.reset();
  }

  void toggleOrientation() {
    isVertical = !isVertical;

    // ⭐ NUEVO: Recalcular tamaños al cambiar orientación
    sizeConfig = GameSizeConfig(
      screenSize: Size(size.x, size.y),
      isVertical: isVertical,
    );

    debugPrint(
      '🔄 Orientación cambiada a: ${isVertical ? "Vertical" : "Horizontal"}',
    );
    debugPrint('   Nuevos carriles: ${sizeConfig.numberOfLanes}');

    trackBackground.updateOrientation(isVertical);
    playerCar.updateOrientation(isVertical);

    // Reiniciar timer con nueva velocidad
    _resetSpawnTimer();

    world.children.whereType<ObstacleComponent>().forEach((obs) {
      obs.updateOrientation(isVertical);
      if (!_isInRoadBounds(obs)) obs.removeFromParent();
    });
    world.children.whereType<CoinComponent>().forEach((c) {
      c.updateOrientation(isVertical);
      if (!_isInRoadBounds(c)) c.removeFromParent();
    });
    world.children.whereType<FuelComponent>().forEach((f) {
      f.updateOrientation(isVertical);
      if (!_isInRoadBounds(f)) f.removeFromParent();
    });
  }

  void addFuel(double amount) {
    fuel = (fuel + amount).clamp(0, maxFuel);
  }

  void incrementObstaclesAvoided() {
    obstaclesAvoided++;
  }

  void incrementCoins(int amount) {
    coinsCollected += amount;
    // Actualizar banco persistente y guardar
    coinBank += amount;
    _saveCoinBank();
  }

  void loseLife(int amount) {
    lives = (lives - amount).clamp(0, maxLives);
    if (lives <= 0) {
      _triggerGameOver();
    }
  }

  void addLife(int amount) {
    lives = (lives + amount).clamp(0, maxLives);
  }

  Future<void> _loadPlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      coinBank = prefs.getInt('coin_bank') ?? 0;

      // Cargar niveles de mejora
      final fuelUpgradeCount = prefs.getInt('fuelUpgradeCount') ?? 0;
      final healthUpgradeCount = prefs.getInt('healthUpgradeCount') ?? 0;

      // Recalcular máximos basados en los niveles para asegurar consistencia (20 por mejora)
      maxFuel = 100.0 + (fuelUpgradeCount * 20.0);
      maxLives = 3 + healthUpgradeCount;

      // Inicializar valores actuales con los máximos cargados
      fuel = maxFuel;
      lives = maxLives;
    } catch (e) {
      debugPrint('❌ Error cargando datos del jugador: $e');
      coinBank = 0;
      maxFuel = 100.0;
      maxLives = 3;
    }
  }

  Future<void> _saveCoinBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coin_bank', coinBank);
    } catch (e) {
      debugPrint('❌ Error guardando coin_bank: $e');
    }
  }
}

/// Componente del carro del jugador - Ahora usa GameSizeConfig
class PlayerCar extends PositionComponent with HasGameReference<RacingGame> {
  bool isVertical;
  String carSpritePath;

  // Sprite que puede ser null
  Sprite? carSprite;

  // Paint para fallback
  final Paint fallbackPaint = Paint()..color = Colors.orange;

  // Movimiento libre
  double speed = 600.0;

  bool movingLeft = false;
  bool movingRight = false;

  PlayerCar({required this.isVertical, required this.carSpritePath});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      carSprite = await Sprite.load(carSpritePath);
      debugPrint('✅ Sprite del carro cargado: $carSpritePath');
    } catch (e) {
      debugPrint('❌ Error cargando sprite del carro: $e');
      debugPrint('🎨 Usando color fallback: NARANJA');
      carSprite = null; // Explícitamente null
    }

    // ⭐ NUEVO: Tamaño del carro desde GameSizeConfig
    if (isVertical) {
      size = Vector2(game.sizeConfig.carWidth, game.sizeConfig.carHeight);
    } else {
      size = Vector2(game.sizeConfig.carHeight, game.sizeConfig.carWidth);
    }

    anchor = Anchor.center;

    _updatePosition();

    debugPrint('🚗 Carro creado - Tamaño: ${size.x.toInt()}x${size.y.toInt()}');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (carSprite != null) {
      if (isVertical) {
        // Renderizar normal (vertical)
        carSprite!.render(canvas, position: Vector2.zero(), size: size);
      } else {
        // Renderizar rotado 90 grados para horizontal
        canvas.save();
        canvas.translate(size.x / 2, size.y / 2);
        canvas.rotate(pi / 2);
        carSprite!.render(
          canvas,
          position: Vector2(-size.y / 2, -size.x / 2),
          size: Vector2(size.y, size.x),
        );
        canvas.restore();
      }
    } else {
      // Renderizar fallback (rectángulo naranja)
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawRect(rect, fallbackPaint);

      // Opcional: Dibujar borde negro para que se vea mejor
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // ⭐ DEBUG: Dibujar hitbox
    if (game.debugMode) {
      final hitbox = getHitboxRectLocal();
      canvas.drawRect(
        hitbox,
        Paint()
          ..color = Colors.red.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Obtener el Rect de colisión (Hitbox) en coordenadas globales
  Rect getHitboxRect() {
    final localRect = getHitboxRectLocal();
    // Ajustar por la posición del componente (que es el centro) y el offset del centro
    return localRect.shift(position.toOffset() - (size / 2).toOffset());
  }

  /// Obtener el Rect de colisión en coordenadas locales (centrado en size/2)
  Rect getHitboxRectLocal() {
    // Hitbox centrada en el componente
    return Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x * 0.8,
      height: size.y * 0.9,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Movimiento continuo con teclado
    if (movingLeft) {
      if (isVertical) {
        position.x -= speed * dt;
      } else {
        position.y -= speed * dt;
      }
    }
    if (movingRight) {
      if (isVertical) {
        position.x += speed * dt;
      } else {
        position.y += speed * dt;
      }
    }

    _clampPosition();
  }

  void _clampPosition() {
    final config = game.sizeConfig;
    if (isVertical) {
      final minX = config.sideWidth + size.x / 2;
      final maxX = config.sideWidth + config.roadWidth - size.x / 2;
      position.x = position.x.clamp(minX, maxX);
    } else {
      final minY = config.sideWidth + size.y / 2;
      final maxY = config.sideWidth + config.roadWidth - size.y / 2;
      position.y = position.y.clamp(minY, maxY);
    }
  }

  void handleKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      movingLeft = true;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      movingRight = true;
    }
  }

  void handleKeyUp(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      movingLeft = false;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      movingRight = false;
    }
  }

  void _updatePosition() {
    final config = game.sizeConfig;

    if (isVertical) {
      // Posicionar el carro centrado en la carretera
      position = Vector2(
        config.sideWidth + config.roadWidth / 2,
        game.size.y - (size.y / 2) - 20,
      );
    } else {
      position = Vector2(150, config.sideWidth + config.roadWidth / 2);
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;

    // Actualizar tamaño según nueva configuración
    if (isVertical) {
      size = Vector2(game.sizeConfig.carWidth, game.sizeConfig.carHeight);
    } else {
      size = Vector2(game.sizeConfig.carHeight, game.sizeConfig.carWidth);
    }

    _updatePosition();
  }

  void resetPosition() {
    _updatePosition();
    movingLeft = false;
    movingRight = false;
  }
}

/// Fondo de la pista - Ahora usa GameSizeConfig
class TrackBackground extends Component with HasGameReference<RacingGame> {
  bool isVertical;
  String trackName;
  double gameSpeed = 200.0;
  double scrollOffset = 0;

  Sprite? roadSprite;
  Sprite? leftSideSprite;
  Sprite? rightSideSprite;

  TrackBackground({required this.isVertical, required this.trackName});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      roadSprite = await Sprite.load('escenarios/$trackName/road.png');
      leftSideSprite = await Sprite.load('escenarios/$trackName/left.png');
      rightSideSprite = await Sprite.load('escenarios/$trackName/right.png');
      debugPrint('✅ Sprites de pista cargados: $trackName');
    } catch (e) {
      debugPrint('❌ Error cargando sprites de pista: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.paused && !game.isGameOver) {
      if (isVertical) {
        scrollOffset += gameSpeed * dt;
        if (scrollOffset > game.size.y) {
          scrollOffset = 0;
        }
      } else {
        scrollOffset += gameSpeed * dt;
        if (scrollOffset > game.size.x) {
          scrollOffset = 0;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final gameSize = game.size;

    if (isVertical) {
      _renderVerticalTrack(canvas, gameSize);
    } else {
      _renderHorizontalTrack(canvas, gameSize);
    }

    // Solo dibujar líneas procedimentales si no hay sprite de carretera cargado
    if (roadSprite == null) {
      _drawLaneMarkings(canvas, gameSize);
    }
  }

  void _renderVerticalTrack(Canvas canvas, Vector2 gameSize) {
    final config = game.sizeConfig;

    // ⭐ NUEVO: Usar valores de GameSizeConfig
    // Lado izquierdo
    _drawSide(
      canvas,
      Rect.fromLTWH(0, 0, config.sideWidth, gameSize.y),
      leftSideSprite,
      const Color(0xFF2d5016),
    );

    // Carretera
    _drawRoad(
      canvas,
      Rect.fromLTWH(config.sideWidth, 0, config.roadWidth, gameSize.y),
      roadSprite,
      const Color(0xFF3a3a3a),
    );

    // Lado derecho
    _drawSide(
      canvas,
      Rect.fromLTWH(
        config.sideWidth + config.roadWidth,
        0,
        config.sideWidth,
        gameSize.y,
      ),
      rightSideSprite,
      const Color(0xFF2d5016),
    );
  }

  void _renderHorizontalTrack(Canvas canvas, Vector2 gameSize) {
    final config = game.sizeConfig;

    // Lado superior
    _drawSide(
      canvas,
      Rect.fromLTWH(0, 0, gameSize.x, config.sideWidth),
      leftSideSprite,
      const Color(0xFF2d5016),
    );

    // Carretera
    _drawRoad(
      canvas,
      Rect.fromLTWH(0, config.sideWidth, gameSize.x, config.roadWidth),
      roadSprite,
      const Color(0xFF3a3a3a),
    );

    // Lado inferior
    _drawSide(
      canvas,
      Rect.fromLTWH(
        0,
        config.sideWidth + config.roadWidth,
        gameSize.x,
        config.sideWidth,
      ),
      rightSideSprite,
      const Color(0xFF2d5016),
    );
  }

  void _drawRoad(
    Canvas canvas,
    Rect rect,
    Sprite? sprite,
    Color fallbackColor,
  ) {
    if (sprite != null) {
      const double tile = 512.0;
      if (isVertical) {
        // Desplazamiento vertical
        double startY = rect.top - (scrollOffset % tile);
        for (double y = startY; y < rect.bottom; y += tile) {
          for (double x = rect.left; x < rect.right; x += tile) {
            final w = (x + tile > rect.right) ? rect.right - x : tile;
            final h = (y + tile > rect.bottom) ? rect.bottom - y : tile;
            if (w <= 0 || h <= 0) continue;
            sprite.render(canvas, position: Vector2(x, y), size: Vector2(w, h));
          }
        }
      } else {
        // Desplazamiento horizontal
        double startX = rect.left - (scrollOffset % tile);
        for (double x = startX; x < rect.right; x += tile) {
          for (double y = rect.top; y < rect.bottom; y += tile) {
            final w = (x + tile > rect.right) ? rect.right - x : tile;
            final h = (y + tile > rect.bottom) ? rect.bottom - y : tile;
            if (w <= 0 || h <= 0) continue;

            // Rotar el sprite 90 grados para que la carretera se vea horizontal
            canvas.save();
            canvas.translate(x + w / 2, y + h / 2);
            canvas.rotate(-pi / 2);
            sprite.render(
              canvas,
              position: Vector2(-h / 2, -w / 2),
              size: Vector2(h, w),
            );
            canvas.restore();
          }
        }
      }
    } else {
      canvas.drawRect(rect, Paint()..color = fallbackColor);
    }
  }

  void _drawSide(
    Canvas canvas,
    Rect rect,
    Sprite? sprite,
    Color fallbackColor,
  ) {
    if (sprite != null) {
      const double tile = 512.0;
      if (isVertical) {
        for (double x = rect.left; x < rect.right; x += tile) {
          for (double y = rect.top; y < rect.bottom; y += tile) {
            final w = (x + tile > rect.right) ? rect.right - x : tile;
            final h = (y + tile > rect.bottom) ? rect.bottom - y : tile;
            if (w <= 0 || h <= 0) continue;
            sprite.render(canvas, position: Vector2(x, y), size: Vector2(w, h));
          }
        }
      } else {
        // En horizontal, rotamos los sprites de los lados
        for (double x = rect.left; x < rect.right; x += tile) {
          for (double y = rect.top; y < rect.bottom; y += tile) {
            final w = (x + tile > rect.right) ? rect.right - x : tile;
            final h = (y + tile > rect.bottom) ? rect.bottom - y : tile;
            if (w <= 0 || h <= 0) continue;

            canvas.save();
            canvas.translate(x + w / 2, y + h / 2);
            canvas.rotate(-pi / 2);
            sprite.render(
              canvas,
              position: Vector2(-h / 2, -w / 2),
              size: Vector2(h, w),
            );
            canvas.restore();
          }
        }
      }
    } else {
      canvas.drawRect(rect, Paint()..color = fallbackColor);
    }
  }

  void _drawLaneMarkings(Canvas canvas, Vector2 gameSize) {
    final config = game.sizeConfig;

    final dashedPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final edgePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    if (isVertical) {
      // Líneas de borde
      _drawDashedVerticalLine(canvas, config.sideWidth, gameSize.y, edgePaint);
      _drawDashedVerticalLine(
        canvas,
        config.sideWidth + config.roadWidth,
        gameSize.y,
        edgePaint,
      );

      // ⭐ NUEVO: Líneas de carriles dinámicas según número de carriles
      for (int i = 1; i < config.numberOfLanes; i++) {
        final x = config.sideWidth + (i * config.laneWidth);
        _drawDashedVerticalLine(canvas, x, gameSize.y, dashedPaint);
      }
    } else {
      // Líneas de borde
      _drawDashedHorizontalLine(
        canvas,
        config.sideWidth,
        gameSize.x,
        edgePaint,
      );
      _drawDashedHorizontalLine(
        canvas,
        config.sideWidth + config.roadWidth,
        gameSize.x,
        edgePaint,
      );

      // Líneas de carriles dinámicas
      for (int i = 1; i < config.numberOfLanes; i++) {
        final y = config.sideWidth + (i * config.laneWidth);
        _drawDashedHorizontalLine(canvas, y, gameSize.x, dashedPaint);
      }
    }
  }

  void _drawDashedVerticalLine(
    Canvas canvas,
    double x,
    double height,
    Paint paint,
  ) {
    const dashHeight = 30.0;
    const gapHeight = 20.0;

    double y = -scrollOffset % (dashHeight + gapHeight);
    while (y < height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + gapHeight;
    }
  }

  void _drawDashedHorizontalLine(
    Canvas canvas,
    double y,
    double width,
    Paint paint,
  ) {
    const dashWidth = 30.0;
    const gapWidth = 20.0;

    double x = width - (scrollOffset % (dashWidth + gapWidth));
    while (x > -dashWidth) {
      canvas.drawLine(Offset(x, y), Offset(x - dashWidth, y), paint);
      x -= dashWidth + gapWidth;
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;
    scrollOffset = 0;
  }

  void reset() {
    scrollOffset = 0;
  }
}

class ObstacleData {
  final String path;
  final double hitboxWidthFactor;
  final double hitboxHeightFactor;

  const ObstacleData(
    this.path,
    this.hitboxWidthFactor,
    this.hitboxHeightFactor,
  );
}

/// Componente de obstáculo - Ahora usa GameSizeConfig
class ObstacleComponent extends PositionComponent
    with HasGameReference<RacingGame> {
  bool isVertical;
  double gameSpeed;
  // int lane; // Eliminado: ya no usamos carriles fijos
  bool hasPassed = false;

  // Tipos de obstáculos
  static const List<String> types = ['cone', 'llantas', 'valla'];
  late String type;

  static const Map<String, ObstacleData> obstacleConfig = {
    'cone': ObstacleData('obstacles/cone.png', 0.6, 0.6),
    'llantas': ObstacleData('obstacles/llantas.png', 0.85, 0.85),
    'valla': ObstacleData('obstacles/valla.png', 0.95, 0.4),
  };

  // Sprite que puede ser null
  Sprite? obstacleSprite;

  // Paint para fallback
  final Paint fallbackPaint = Paint()..color = Colors.red.withOpacity(0.8);

  ObstacleComponent({required this.isVertical, required this.gameSpeed});

  @override
  Future<void> onLoad() async {
    // Seleccionar tipo aleatorio
    type = types[Random().nextInt(types.length)];

    await super.onLoad();

    final data = obstacleConfig[type]!;

    try {
      obstacleSprite = await Sprite.load(data.path);
      debugPrint('✅ Sprite obstáculo cargado: ${data.path}');
    } catch (e) {
      debugPrint('❌ Error cargando sprite de obstáculo ($type): $e');
      debugPrint('🎨 Usando color fallback: ROJO');
      obstacleSprite = null;
    }

    // ⭐ Ajustar al carril (obstáculo 2:1 que cabe en un carril)
    final obstacleSize = game.sizeConfig.getObstacleSizeFitLane2to1(fill: 0.9);
    if (isVertical) {
      size = obstacleSize;
    } else {
      size = Vector2(obstacleSize.y, obstacleSize.x);
    }

    anchor = Anchor.center;
    _setInitialPosition(game.size);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (obstacleSprite != null) {
      // Renderizar sprite
      obstacleSprite!.render(canvas, position: Vector2.zero(), size: size);
    } else {
      // Renderizar fallback (rectángulo rojo)
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawRect(rect, fallbackPaint);

      // Borde negro
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // ⭐ DEBUG: Dibujar hitbox
    if (game.debugMode) {
      final hitbox = getHitboxRectLocal();
      canvas.drawRect(
        hitbox,
        Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Obtener el Rect de colisión (Hitbox) en coordenadas globales
  Rect getHitboxRect() {
    final localRect = getHitboxRectLocal();
    return localRect.shift(position.toOffset() - (size / 2).toOffset());
  }

  /// Obtener el Rect de colisión en coordenadas locales
  Rect getHitboxRectLocal() {
    final data = obstacleConfig[type]!;
    // Hitbox ajustada según el tipo de obstáculo
    return Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x * data.hitboxWidthFactor,
      height: size.y * data.hitboxHeightFactor,
    );
  }

  void _setInitialPosition(Vector2 gameSize) {
    final config = game.sizeConfig;
    final random = Random();

    // Posición aleatoria continua dentro de la carretera
    final double roadStart = config.sideWidth;
    final double roadWidth = config.roadWidth;

    // Margen para que no aparezca cortado en los bordes
    final double margin = isVertical ? size.x / 2 : size.y / 2;

    final double minPos = roadStart + margin;
    final double maxPos = roadStart + roadWidth - margin;

    final double randomPos = minPos + random.nextDouble() * (maxPos - minPos);

    if (isVertical) {
      position = Vector2(randomPos, -size.y);
    } else {
      position = Vector2(gameSize.x + size.x, randomPos);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final gameSize = game.size;

    if (isVertical) {
      position.y += gameSpeed * dt;

      if (!hasPassed && position.y > gameSize.y - 200) {
        hasPassed = true;
        game.incrementObstaclesAvoided();
      }

      if (position.y > gameSize.y + 100) {
        removeFromParent();
      }
    } else {
      position.x -= gameSpeed * dt;

      if (!hasPassed && position.x < 200) {
        hasPassed = true;
        game.incrementObstaclesAvoided();
      }

      if (position.x < -100) {
        removeFromParent();
      }
    }

    _checkCollision();
  }

  void _checkCollision() {
    final playerCar = game.playerCar;

    // Usar las hitboxes ajustadas
    final Rect playerRect = playerCar.getHitboxRect();
    final Rect obstacleRect = getHitboxRect();

    if (playerRect.overlaps(obstacleRect)) {
      game.fuel -= 10;
      game.loseLife(1);
      removeFromParent();
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;
    // Mantener el ajuste de obstáculo al carril también al rotar
    final obstacleSize = game.sizeConfig.getObstacleSizeFitLane2to1(fill: 0.9);
    if (isVertical) {
      size = obstacleSize;
    } else {
      size = Vector2(obstacleSize.y, obstacleSize.x);
    }
  }
}

/// Componente de moneda
class CoinComponent extends PositionComponent
    with HasGameReference<RacingGame> {
  bool isVertical;
  double gameSpeed;
  int lane;

  Sprite? coinSprite;
  final Paint fallbackPaint = Paint()..color = Colors.amber;

  CoinComponent({required this.isVertical, required this.gameSpeed}) : lane = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    lane =
        DateTime.now().millisecondsSinceEpoch % game.sizeConfig.numberOfLanes;

    // Evitar colisión inicial con obstáculos recién generados
    final obstacles = game.world.children.whereType<ObstacleComponent>();
    bool tooClose = false;

    // Posición temporal para verificar
    final config = game.sizeConfig;
    final double roadStart = config.sideWidth;
    final double roadWidth = config.roadWidth;
    final double margin = isVertical ? size.x / 2 : size.y / 2;
    final double minPos = roadStart + margin;
    final double maxPos = roadStart + roadWidth - margin;

    // Intentar encontrar una posición libre (máximo 5 intentos)
    for (int i = 0; i < 5; i++) {
      final randomPos = minPos + Random().nextDouble() * (maxPos - minPos);
      Vector2 candidatePos;

      if (isVertical) {
        candidatePos = Vector2(randomPos, -size.y - 220);
      } else {
        candidatePos = Vector2(game.size.x + size.x + 220, randomPos);
      }

      // Verificar distancia con obstáculos cercanos
      tooClose = false;
      for (final o in obstacles) {
        if (o.position.distanceTo(candidatePos) < 150) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        position = candidatePos;
        break;
      }
    }

    if (tooClose) {
      // Si no encontramos sitio, no spawneamos
      removeFromParent();
      return;
    }

    try {
      coinSprite = await Sprite.load('obstacles/coin.png');
    } catch (e) {
      debugPrint('❌ Error cargando sprite de moneda: $e');
      coinSprite = null;
    }

    final coinSize = game.sizeConfig.getObstacleSize(40, 40);
    size = Vector2(coinSize.x, coinSize.y);
    anchor = Anchor.center;
    // La posición ya se estableció arriba
  }

  // Eliminado _setInitialPosition ya que se hace en onLoad con lógica de colisión

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (coinSprite != null) {
      coinSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        // anchor: Anchor.topLeft,
      );
    } else {
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawOval(rect, fallbackPaint);
      canvas.drawOval(
        rect,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // ⭐ DEBUG: Dibujar hitbox
    if (game.debugMode) {
      final hitbox = getHitboxRectLocal();
      canvas.drawRect(
        hitbox,
        Paint()
          ..color = Colors.purple.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Obtener el Rect de colisión (Hitbox) en coordenadas globales
  Rect getHitboxRect() {
    final localRect = getHitboxRectLocal();
    return localRect.shift(position.toOffset() - (size / 2).toOffset());
  }

  /// Obtener el Rect de colisión en coordenadas locales
  Rect getHitboxRectLocal() {
    return Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final gameSize = game.size;
    if (isVertical) {
      position.y += gameSpeed * dt;
      if (position.y > gameSize.y + 80) {
        removeFromParent();
        return;
      }
    } else {
      position.x -= gameSpeed * dt;
      if (position.x < -80) {
        removeFromParent();
        return;
      }
    }

    _checkCollection();
  }

  void _checkCollection() {
    final playerCar = game.playerCar;

    // Usar la hitbox del jugador
    final Rect playerRect = playerCar.getHitboxRect();
    final Rect coinRect = getHitboxRect();

    if (playerRect.overlaps(coinRect)) {
      game.incrementCoins(100);
      removeFromParent();
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;
    final coinSize = game.sizeConfig.getObstacleSize(40, 40);
    size = Vector2(coinSize.x, coinSize.y);
  }
}

/// Componente de gasolina
class FuelComponent extends PositionComponent
    with HasGameReference<RacingGame> {
  bool isVertical;
  double gameSpeed;

  Sprite? fuelSprite;
  final Paint fallbackPaint = Paint()..color = Colors.green;

  FuelComponent({required this.isVertical, required this.gameSpeed});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Lógica de posición similar a CoinComponent
    final config = game.sizeConfig;
    final double roadStart = config.sideWidth;
    final double roadWidth = config.roadWidth;
    final double margin = isVertical ? size.x / 2 : size.y / 2;
    final double minPos = roadStart + margin;
    final double maxPos = roadStart + roadWidth - margin;

    final randomPos = minPos + Random().nextDouble() * (maxPos - minPos);

    if (isVertical) {
      position = Vector2(randomPos, -size.y - 300); // Más separado
    } else {
      position = Vector2(game.size.x + size.x + 300, randomPos);
    }

    try {
      // Intentar cargar sprite, si no existe usará fallback
      fuelSprite = await Sprite.load('obstacles/fuel.png');
    } catch (e) {
      debugPrint('⚠️ No se encontró sprite de gasolina, usando fallback');
      fuelSprite = null;
    }

    final itemSize = game.sizeConfig.getObstacleSize(40, 40);
    size = Vector2(itemSize.x, itemSize.y);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (fuelSprite != null) {
      fuelSprite!.render(canvas, position: Vector2.zero(), size: size);
    } else {
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      // Dibujar un bidón simple
      canvas.drawRect(rect, fallbackPaint);
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      // Letra F
      const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );
      final textSpan = TextSpan(text: 'F', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          (size.y - textPainter.height) / 2,
        ),
      );
    }

    if (game.debugMode) {
      final hitbox = getHitboxRectLocal();
      canvas.drawRect(
        hitbox,
        Paint()
          ..color = Colors.green.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  Rect getHitboxRect() {
    final localRect = getHitboxRectLocal();
    return localRect.shift(position.toOffset() - (size / 2).toOffset());
  }

  Rect getHitboxRectLocal() {
    return Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final gameSize = game.size;
    if (isVertical) {
      position.y += gameSpeed * dt;
      if (position.y > gameSize.y + 80) {
        removeFromParent();
        return;
      }
    } else {
      position.x -= gameSpeed * dt;
      if (position.x < -80) {
        removeFromParent();
        return;
      }
    }

    _checkCollection();
  }

  void _checkCollection() {
    final playerCar = game.playerCar;
    final Rect playerRect = playerCar.getHitboxRect();
    final Rect fuelRect = getHitboxRect();

    if (playerRect.overlaps(fuelRect)) {
      game.addFuel(20); // Recargar 20 de gasolina
      removeFromParent();
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;
    final itemSize = game.sizeConfig.getObstacleSize(40, 40);
    size = Vector2(itemSize.x, itemSize.y);
  }
}
