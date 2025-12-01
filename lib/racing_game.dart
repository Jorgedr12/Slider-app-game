import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clase principal del juego de carreras
/// Maneja la lógica del juego, física, colisiones y estado
class RacingGame extends FlameGame
    with KeyboardEvents, HasCollisionDetection, PanDetector {
  // Estado del juego
  double distance = 0;
  double fuel = 100;
  double maxFuel = 100;
  int obstaclesAvoided = 0;
  double maxSpeed = 0;
  double currentSpeed = 0;
  bool isGameOver = false;

  // Configuración
  bool isVertical = true;
  String selectedCarSprite = 'cars/orange_car.png';
  String selectedTrack = 'akina';
  String currentTrackName = 'MONTE AKINA';

  // Velocidad del juego (aumenta con el tiempo)
  double gameSpeed = 200.0; // píxeles por segundo
  double baseSpeed = 200.0;
  double speedIncrement = 5.0; // incremento por segundo

  // Componentes principales
  late PlayerCar playerCar;
  late TrackBackground trackBackground;

  // Callbacks para el widget
  Function()? onPauseRequest;
  Function()? onGameOver;

  // Para detección de swipe
  Vector2? _panStartPosition;

  RacingGame({
    this.isVertical = true,
    this.selectedCarSprite = 'cars/orange_car.png',
    this.selectedTrack = 'akina',
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Configurar cámara
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

    // Iniciar generación de obstáculos
    _startObstacleGeneration();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!paused && !isGameOver) {
      // Actualizar distancia
      distance += gameSpeed * dt / 10; // Convertir a metros

      // Consumir gasolina (ajusta el rate según prefieras)
      fuel -= 8 * dt; // 8% por segundo aprox

      // Aumentar velocidad gradualmente
      gameSpeed += speedIncrement * dt;
      currentSpeed = gameSpeed / 2.78; // Convertir a km/h aprox

      if (currentSpeed > maxSpeed) {
        maxSpeed = currentSpeed;
      }

      // Actualizar velocidad del fondo
      trackBackground.gameSpeed = gameSpeed;

      // Verificar Game Over
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
    // Solo procesar si no está pausado
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

  // Detección de gestos táctiles (swipe)
  @override
  void onPanStart(DragStartInfo info) {
    _panStartPosition = info.eventPosition.global;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_panStartPosition == null || paused || isGameOver) return;

    final currentPosition = info.eventPosition.global;
    final delta = currentPosition - _panStartPosition!;

    // Detectar swipe según orientación
    if (isVertical) {
      // En vertical, swipe horizontal
      if (delta.x < -50) {
        // Swipe a la izquierda
        playerCar.moveLeft();
        _panStartPosition = currentPosition;
      } else if (delta.x > 50) {
        // Swipe a la derecha
        playerCar.moveRight();
        _panStartPosition = currentPosition;
      }
    } else {
      // En horizontal, swipe vertical
      if (delta.y < -50) {
        // Swipe hacia arriba
        playerCar.moveLeft();
        _panStartPosition = currentPosition;
      } else if (delta.y > 50) {
        // Swipe hacia abajo
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

  void _triggerGameOver() {
    isGameOver = true;
    pauseEngine();
    onGameOver?.call();
  }

  void resetGame() {
    distance = 0;
    fuel = 100;
    obstaclesAvoided = 0;
    maxSpeed = 0;
    currentSpeed = 0;
    gameSpeed = baseSpeed;
    isGameOver = false;

    world.children.whereType<ObstacleComponent>().forEach((obs) {
      obs.removeFromParent();
    });

    playerCar.resetPosition();
    trackBackground.reset();
  }

  void toggleOrientation() {
    isVertical = !isVertical;
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
}

/// Componente del carro del jugador con sprites
class PlayerCar extends SpriteComponent with HasGameReference<RacingGame> {
  bool isVertical;
  String carSpritePath;

  int currentLane = 1;
  final int totalLanes = 3;

  double laneChangeSpeed = 500.0;
  Vector2 targetPosition = Vector2.zero();
  bool isChangingLane = false;

  bool movingLeft = false;
  bool movingRight = false;

  PlayerCar({required this.isVertical, required this.carSpritePath});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Cargar sprite del carro
    try {
      sprite = await Sprite.load(carSpritePath);
    } catch (e) {
      debugPrint('Error cargando sprite del carro: $e');
      // Fallback: usar color sólido
      paint = Paint()..color = Colors.orange;
    }

    // Tamaño del carro
    if (isVertical) {
      size = Vector2(80, 120);
    } else {
      size = Vector2(120, 80);
    }

    anchor = Anchor.center;

    _updatePosition();
    targetPosition = position.clone();
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
    final gameSize = game.size;

    if (isVertical) {
      final laneWidth = gameSize.x / totalLanes;
      position = Vector2(
        laneWidth * currentLane + laneWidth / 2,
        gameSize.y - 150,
      );
    } else {
      final laneHeight = gameSize.y / totalLanes;
      position = Vector2(150, laneHeight * currentLane + laneHeight / 2);
    }
  }

  void _updateTargetPosition() {
    final gameSize = game.size;

    if (isVertical) {
      final laneWidth = gameSize.x / totalLanes;
      targetPosition = Vector2(
        laneWidth * currentLane + laneWidth / 2,
        position.y,
      );
    } else {
      final laneHeight = gameSize.y / totalLanes;
      targetPosition = Vector2(
        position.x,
        laneHeight * currentLane + laneHeight / 2,
      );
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;

    if (isVertical) {
      size = Vector2(80, 120);
    } else {
      size = Vector2(120, 80);
    }

    currentLane = 1;
    _updatePosition();
    targetPosition = position.clone();
    isChangingLane = false;
  }

  void resetPosition() {
    currentLane = 1;
    _updatePosition();
    targetPosition = position.clone();
    isChangingLane = false;
    movingLeft = false;
    movingRight = false;
  }
}

/// Fondo de la pista con sprites y parallax
class TrackBackground extends Component with HasGameReference<RacingGame> {
  bool isVertical;
  String trackName;
  double gameSpeed = 200.0;
  double scrollOffset = 0;

  // Sprites
  Sprite? roadSprite;
  Sprite? leftSideSprite;
  Sprite? rightSideSprite;

  TrackBackground({required this.isVertical, required this.trackName});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Cargar sprites de la pista
    try {
      roadSprite = await Sprite.load('escenarios/${trackName}_road.png');
      leftSideSprite = await Sprite.load('escenarios/retro_left.png');
      rightSideSprite = await Sprite.load('escenarios/retro_right.png');
    } catch (e) {
      debugPrint('Error cargando sprites de la pista: $e');
      // Los sprites quedan null y se dibuja con colores sólidos
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
    final laneWidth = gameSize.x / 3;
    final sideWidth = (gameSize.x - laneWidth * 3) / 2;

    // Lado izquierdo
    _drawSide(
      canvas,
      Rect.fromLTWH(0, 0, laneWidth * 0.3, gameSize.y),
      leftSideSprite,
      const Color(0xFF2d5016), // Verde oscuro (pasto)
    );

    // Carretera
    _drawRoad(
      canvas,
      Rect.fromLTWH(laneWidth * 0.3, 0, laneWidth * 3, gameSize.y),
      roadSprite,
      const Color(0xFF3a3a3a), // Gris oscuro (asfalto)
    );

    // Lado derecho
    _drawSide(
      canvas,
      Rect.fromLTWH(
        laneWidth * 3.3,
        0,
        gameSize.x - laneWidth * 3.3,
        gameSize.y,
      ),
      rightSideSprite,
      const Color(0xFF2d5016),
    );
  }

  void _renderHorizontalTrack(Canvas canvas, Vector2 gameSize) {
    final laneHeight = gameSize.y / 3;

    // Lado superior
    _drawSide(
      canvas,
      Rect.fromLTWH(0, 0, gameSize.x, laneHeight * 0.3),
      leftSideSprite,
      const Color(0xFF2d5016),
    );

    // Carretera
    _drawRoad(
      canvas,
      Rect.fromLTWH(0, laneHeight * 0.3, gameSize.x, laneHeight * 3),
      roadSprite,
      const Color(0xFF3a3a3a),
    );

    // Lado inferior
    _drawSide(
      canvas,
      Rect.fromLTWH(
        0,
        laneHeight * 3.3,
        gameSize.x,
        gameSize.y - laneHeight * 3.3,
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
      // Dibujar sprite repetido con scroll
      final spriteSize = isVertical
          ? Vector2(rect.width, rect.width)
          : Vector2(rect.height, rect.height);

      if (isVertical) {
        double y = -scrollOffset;
        while (y < rect.bottom) {
          sprite.render(
            canvas,
            position: Vector2(rect.left, y),
            size: spriteSize,
          );
          y += spriteSize.y;
        }
      } else {
        double x = rect.width - scrollOffset;
        while (x > rect.left - spriteSize.x) {
          sprite.render(
            canvas,
            position: Vector2(x, rect.top),
            size: spriteSize,
          );
          x -= spriteSize.x;
        }
      }
    } else {
      // Fallback: color sólido
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
      sprite.render(
        canvas,
        position: Vector2(rect.left, rect.top),
        size: Vector2(rect.width, rect.height),
      );
    } else {
      canvas.drawRect(rect, Paint()..color = fallbackColor);
    }
  }

  void _drawLaneMarkings(Canvas canvas, Vector2 gameSize) {
    final dashedPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final edgePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    if (isVertical) {
      final laneWidth = gameSize.x / 3;
      final roadLeft = laneWidth * 0.3;
      final roadRight = laneWidth * 3.3;

      // Líneas de borde
      _drawDashedVerticalLine(canvas, roadLeft, gameSize.y, edgePaint);
      _drawDashedVerticalLine(canvas, roadRight, gameSize.y, edgePaint);

      // Líneas de carriles
      _drawDashedVerticalLine(
        canvas,
        roadLeft + laneWidth,
        gameSize.y,
        dashedPaint,
      );
      _drawDashedVerticalLine(
        canvas,
        roadLeft + laneWidth * 2,
        gameSize.y,
        dashedPaint,
      );
    } else {
      final laneHeight = gameSize.y / 3;
      final roadTop = laneHeight * 0.3;
      final roadBottom = laneHeight * 3.3;

      // Líneas de borde
      _drawDashedHorizontalLine(canvas, roadTop, gameSize.x, edgePaint);
      _drawDashedHorizontalLine(canvas, roadBottom, gameSize.x, edgePaint);

      // Líneas de carriles
      _drawDashedHorizontalLine(
        canvas,
        roadTop + laneHeight,
        gameSize.x,
        dashedPaint,
      );
      _drawDashedHorizontalLine(
        canvas,
        roadTop + laneHeight * 2,
        gameSize.x,
        dashedPaint,
      );
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

/// Componente de obstáculo
class ObstacleComponent extends SpriteComponent
    with HasGameReference<RacingGame> {
  bool isVertical;
  double gameSpeed;
  int lane;
  bool hasPassed = false;

  ObstacleComponent({required this.isVertical, required this.gameSpeed})
    : lane = _randomLane();

  static int _randomLane() {
    return (DateTime.now().millisecondsSinceEpoch % 3);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final gameSize = game.size;

    // Cargar sprite del obstáculo
    try {
      sprite = await Sprite.load('obstacles/cone.png');
    } catch (e) {
      debugPrint('Error cargando sprite de obstáculo: $e');
      paint = Paint()..color = Colors.red.withOpacity(0.8);
    }

    if (isVertical) {
      size = Vector2(60, 80);
    } else {
      size = Vector2(80, 60);
    }

    anchor = Anchor.center;
    _setInitialPosition(gameSize);
  }

  void _setInitialPosition(Vector2 gameSize) {
    if (isVertical) {
      final laneWidth = gameSize.x / 3;
      final roadLeft = laneWidth * 0.3;
      position = Vector2(roadLeft + laneWidth * lane + laneWidth / 2, -size.y);
    } else {
      final laneHeight = gameSize.y / 3;
      final roadTop = laneHeight * 0.3;
      position = Vector2(
        gameSize.x + size.x,
        roadTop + laneHeight * lane + laneHeight / 2,
      );
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
    final distance = position.distanceTo(playerCar.position);

    // Colisión simple por distancia
    if (distance < 60) {
      game.fuel -= 10;
      removeFromParent();
    }
  }

  void updateOrientation(bool vertical) {
    isVertical = vertical;

    if (isVertical) {
      size = Vector2(60, 80);
    } else {
      size = Vector2(80, 60);
    }
  }
}
