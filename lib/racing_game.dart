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
  int maxLives = 8;

  // Configuración
  bool isVertical = true;
  bool debugMode = true; // ⭐ MODO DEBUG ACTIVADO
  String selectedCarSprite = 'cars/orange_car.png';
  String selectedTrack = 'akina';
  String currentTrackName = 'MONTE AKINA';

  // Velocidad del juego
  double gameSpeed = 200.0;
  double baseSpeed = 200.0;
  double speedIncrement = 5.0;

  // ⭐ NUEVO: Configuración de tamaños
  late GameSizeConfig sizeConfig;

  // Componentes principales
  late PlayerCar playerCar;
  late TrackBackground trackBackground;

  // Callbacks
  Function()? onPauseRequest;
  Function()? onGameOver;

  // Para detección de swipe
  Vector2? _panStartPosition;
  int _obstacleSpawnCount = 0;

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
    await _loadCoinBank();

    _startObstacleGeneration();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!paused && !isGameOver) {
      distance += gameSpeed * dt / 10;
      fuel -= 8 * dt;
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
    _panStartPosition = info.eventPosition.global;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_panStartPosition == null || paused || isGameOver) return;

    final currentPosition = info.eventPosition.global;
    final delta = currentPosition - _panStartPosition!;

    if (isVertical) {
      if (delta.x < -50) {
        playerCar.moveLeft();
        _panStartPosition = currentPosition;
      } else if (delta.x > 50) {
        playerCar.moveRight();
        _panStartPosition = currentPosition;
      }
    } else {
      if (delta.y < -50) {
        playerCar.moveLeft();
        _panStartPosition = currentPosition;
      } else if (delta.y > 50) {
        playerCar.moveRight();
        _panStartPosition = currentPosition;
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _panStartPosition = null;
  }

  void _startObstacleGeneration() {
    world.add(
      TimerComponent(
        period: 2.0,
        repeat: true,
        onTick: () {
          if (!paused && !isGameOver) {
            _spawnObstacle();
            _obstacleSpawnCount++;
            if (_obstacleSpawnCount % 4 == 0) {
              _spawnCoin();
            }
          }
        },
      ),
    );
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

  void _triggerGameOver() {
    isGameOver = true;
    pauseEngine();
    onGameOver?.call();
  }

  void resetGame() {
    distance = 0;
    fuel = 100;
    obstaclesAvoided = 0;
    coinsCollected = 0;
    lives = 3;
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

    world.children.whereType<ObstacleComponent>().forEach((obs) {
      obs.updateOrientation(isVertical);
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

  Future<void> _loadCoinBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      coinBank = prefs.getInt('coin_bank') ?? 0;
    } catch (e) {
      debugPrint('❌ Error cargando coin_bank: $e');
      coinBank = 0;
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

  int currentLane = 1;
  int get totalLanes => game.sizeConfig.numberOfLanes; // ⭐ Dinámico

  double laneChangeSpeed = 500.0;
  Vector2 targetPosition = Vector2.zero();
  bool isChangingLane = false;

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
    targetPosition = position.clone();

    debugPrint('🚗 Carro creado - Tamaño: ${size.x.toInt()}x${size.y.toInt()}');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (carSprite != null) {
      // Renderizar sprite
      carSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        // anchor: Anchor.topLeft, // Por defecto es topLeft, que llena el componente desde 0,0
      );
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

    if (isChangingLane) {
      final direction = targetPosition - position;
      final distance = direction.length;

      if (distance < 5) {
        position = targetPosition.clone();
        isChangingLane = false;
      } else {
        direction.normalize();
        position += direction * laneChangeSpeed * dt;
      }
    }

    if (movingLeft && !isChangingLane) {
      moveLeft();
    }
    if (movingRight && !isChangingLane) {
      moveRight();
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

  void moveLeft() {
    if (currentLane > 0 && !isChangingLane) {
      currentLane--;
      _updateTargetPosition();
      isChangingLane = true;
    }
  }

  void moveRight() {
    if (currentLane < totalLanes - 1 && !isChangingLane) {
      currentLane++;
      _updateTargetPosition();
      isChangingLane = true;
    }
  }

  void _updatePosition() {
    final config = game.sizeConfig;

    if (isVertical) {
      // Posicionar el carro pegado a la parte inferior de la pantalla
      position = Vector2(
        config.getLaneCenterX(currentLane),
        game.size.y - (size.y / 2) - 20,
      );
    } else {
      // ⭐ NUEVO: Usar getLaneCenterY de GameSizeConfig
      position = Vector2(150, config.getLaneCenterY(currentLane));
    }
  }

  void _updateTargetPosition() {
    final config = game.sizeConfig;

    if (isVertical) {
      targetPosition = Vector2(config.getLaneCenterX(currentLane), position.y);
    } else {
      targetPosition = Vector2(position.x, config.getLaneCenterY(currentLane));
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;

    // ⭐ NUEVO: Actualizar tamaño según nueva configuración
    if (isVertical) {
      size = Vector2(game.sizeConfig.carWidth, game.sizeConfig.carHeight);
    } else {
      size = Vector2(game.sizeConfig.carHeight, game.sizeConfig.carWidth);
    }

    currentLane = totalLanes ~/ 2; // Carril central
    _updatePosition();
    targetPosition = position.clone();
    isChangingLane = false;
  }

  void resetPosition() {
    currentLane = totalLanes ~/ 2; // Carril central
    _updatePosition();
    targetPosition = position.clone();
    isChangingLane = false;
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

    _drawLaneMarkings(canvas, gameSize);
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
            sprite.render(canvas, position: Vector2(x, y), size: Vector2(w, h));
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
      for (double x = rect.left; x < rect.right; x += tile) {
        for (double y = rect.top; y < rect.bottom; y += tile) {
          final w = (x + tile > rect.right) ? rect.right - x : tile;
          final h = (y + tile > rect.bottom) ? rect.bottom - y : tile;
          if (w <= 0 || h <= 0) continue;
          sprite.render(canvas, position: Vector2(x, y), size: Vector2(w, h));
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

/// Componente de obstáculo - Ahora usa GameSizeConfig
class ObstacleComponent extends PositionComponent
    with HasGameReference<RacingGame> {
  bool isVertical;
  double gameSpeed;
  int lane;
  bool hasPassed = false;

  // Sprite que puede ser null
  Sprite? obstacleSprite;

  // Paint para fallback
  final Paint fallbackPaint = Paint()..color = Colors.red.withOpacity(0.8);

  ObstacleComponent({required this.isVertical, required this.gameSpeed})
    : lane = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ⭐ NUEVO: Carril aleatorio según número de carriles disponibles
    lane =
        DateTime.now().millisecondsSinceEpoch % game.sizeConfig.numberOfLanes;

    try {
      obstacleSprite = await Sprite.load('obstacles/cone.png');
      debugPrint('✅ Sprite obstáculo cargado');
    } catch (e) {
      debugPrint('❌ Error cargando sprite de obstáculo: $e');
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
      obstacleSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        // anchor: Anchor.topLeft, // Por defecto
      );
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
    // Hitbox ajustada (80% del tamaño visual), centrada en el componente
    return Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x * 0.8,
      height: size.y * 0.8,
    );
  }

  void _setInitialPosition(Vector2 gameSize) {
    final config = game.sizeConfig;

    if (isVertical) {
      position = Vector2(config.getLaneCenterX(lane), -size.y);
    } else {
      position = Vector2(gameSize.x + size.x, config.getLaneCenterY(lane));
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

    // Evitar colisión inicial con obstáculos recién generados (mismo carril y zona de spawn)
    final obstacles = game.world.children.whereType<ObstacleComponent>();
    final occupiedLanes = <int>{};
    final gameSize = game.size;
    for (final o in obstacles) {
      if (o.isVertical == isVertical) {
        if (isVertical) {
          // Obstáculos en zona alta (spawn) si su y todavía < 120
          if (o.position.y < 120) occupiedLanes.add(o.lane);
        } else {
          // Obstáculos en zona derecha (spawn) si su x > ancho - 120
          if (o.position.x > gameSize.x - 120) occupiedLanes.add(o.lane);
        }
      }
    }
    if (occupiedLanes.contains(lane)) {
      final allLanes = List<int>.generate(
        game.sizeConfig.numberOfLanes,
        (i) => i,
      );
      final free = allLanes.where((l) => !occupiedLanes.contains(l)).toList();
      if (free.isNotEmpty) {
        lane = free[Random().nextInt(free.length)];
      } else {
        // No hay carril libre en la zona de spawn, cancelar moneda
        removeFromParent();
        return;
      }
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
    _setInitialPosition(game.size);
  }

  void _setInitialPosition(Vector2 gameSize) {
    final config = game.sizeConfig;
    if (isVertical) {
      // Separar la moneda de la zona de aparición de obstáculos (más arriba)
      const double separation = 220; // píxeles extra de separación
      position = Vector2(config.getLaneCenterX(lane), -size.y - separation);
    } else {
      // Separar la moneda hacia la derecha para evitar proximidad inmediata
      const double separation = 220; // píxeles extra de separación
      position = Vector2(
        gameSize.x + size.x + separation,
        config.getLaneCenterY(lane),
      );
    }
  }

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
      game.incrementCoins(1);
      removeFromParent();
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;
    final coinSize = game.sizeConfig.getObstacleSize(40, 40);
    size = Vector2(coinSize.x, coinSize.y);
  }
}
