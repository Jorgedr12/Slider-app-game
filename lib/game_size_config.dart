import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configuración dinámica de tamaños según el dispositivo
class GameSizeConfig {
  // Tamaño base del carro (relación 2:1)
  static const double carBaseWidth = 120.0;
  static const double carBaseHeight = 60.0;

  // Multiplicador para ancho de carril
  static const double laneWidthMultiplier = 1.1;

  // Límites de carriles
  static const int minLanes = 2;
  static const int maxLanesVertical = 4;
  static const int maxLanesHorizontal = 5;

  final Size screenSize;
  final bool isVertical;

  // Valores calculados
  late final double carWidth;
  late final double carHeight;
  late final double laneWidth;
  late final int numberOfLanes;
  late final double roadWidth;
  late final double sideWidth;

  GameSizeConfig({required this.screenSize, required this.isVertical}) {
    _calculateSizes();
  }

  void _calculateSizes() {
    // Dimensión relevante según orientación
    final screenDimension = isVertical ? screenSize.width : screenSize.height;

    // El carro ocupa ~10-12% del ancho/alto de la pantalla
    carWidth = (screenDimension * 0.11).clamp(80.0, 160.0);
    carHeight = carWidth / 2.0; // Relación 2:1

    // Calcular ancho de carril (1.1 veces el ancho del carro)
    laneWidth = carWidth * laneWidthMultiplier;

    // Calcular número de carriles que caben
    final maxLanes = isVertical ? maxLanesVertical : maxLanesHorizontal;
    final fittingLanes = (screenDimension / laneWidth).floor();
    numberOfLanes = fittingLanes.clamp(minLanes, maxLanes);

    // Calcular ancho total de la carretera
    roadWidth = laneWidth * numberOfLanes;

    // Calcular ancho de los lados
    sideWidth = (screenDimension - roadWidth) / 2;
  }

  /// Obtener la posición X del centro de un carril (para vertical)
  double getLaneCenterX(int laneIndex) {
    assert(laneIndex >= 0 && laneIndex < numberOfLanes);
    return sideWidth + (laneIndex * laneWidth) + (laneWidth / 2);
  }

  /// Obtener la posición Y del centro de un carril (para horizontal)
  double getLaneCenterY(int laneIndex) {
    assert(laneIndex >= 0 && laneIndex < numberOfLanes);
    return sideWidth + (laneIndex * laneWidth) + (laneWidth / 2);
  }

  /// Tamaño de obstáculo escalado
  Vector2 getObstacleSize(double baseWidth, double baseHeight) {
    final scale = carWidth / carBaseWidth;
    return Vector2(baseWidth * scale, baseHeight * scale);
  }
}
