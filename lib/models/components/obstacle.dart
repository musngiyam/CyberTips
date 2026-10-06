import 'package:flutter/material.dart';

/// Defines a solid obstacle using fractional coordinates (0.0 - 1.0)
class Obstacle {
  final double xStart;
  final double yStart;
  final double xEnd;
  final double yEnd;
  final String label;

  const Obstacle({
    required this.xStart,
    required this.yStart,
    required this.xEnd,
    required this.yEnd,
    this.label = '',
  });

  Rect toRect(double screenWidth, double screenHeight) {
    return Rect.fromLTRB(
      xStart * screenWidth,
      yStart * screenHeight,
      xEnd * screenWidth,
      yEnd * screenHeight,
    );
  }
}

const List<Obstacle> mapObstacles = [
  // Top-left Farmhouse walls
  Obstacle(xStart: 0.17, yStart: 0.05, xEnd: 0.29, yEnd: 0.20, label: 'farmhouse'),

  // Greenhouse
  Obstacle(xStart: 0.38, yStart: 0.32, xEnd: 0.48, yEnd: 0.55, label: 'greenhouse'),

  // Manor
  Obstacle(xStart: 0.58, yStart: 0.06, xEnd: 0.86, yEnd: 0.34, label: 'manor'),

  // Barn & Silo
  Obstacle(xStart: 0.02, yStart: 0.43, xEnd: 0.15, yEnd: 0.63, label: 'barn'),
  Obstacle(xStart: 0.15, yStart: 0.49, xEnd: 0.20, yEnd: 0.63, label: 'silo'),

  // Market Area & Crates
  Obstacle(xStart: 0.18, yStart: 0.73, xEnd: 0.22, yEnd: 0.79, label: 'crates_stack'),
  Obstacle(xStart: 0.23, yStart: 0.74, xEnd: 0.29, yEnd: 0.79, label: 'market_stall_blue'),
  Obstacle(xStart: 0.30, yStart: 0.74, xEnd: 0.33, yEnd: 0.79, label: 'market_barrels'),
  Obstacle(xStart: 0.34, yStart: 0.74, xEnd: 0.40, yEnd: 0.79, label: 'market_stall_pink'),

  // Water / Pond body
  Obstacle(xStart: 0.60, yStart: 0.62, xEnd: 0.74, yEnd: 0.82, label: 'pond'),

  // Church walls
  Obstacle(xStart: 0.84, yStart: 0.51, xEnd: 0.98, yEnd: 0.78, label: 'church'),

  // Bottom Row Buildings
  Obstacle(xStart: 0.00, yStart: 0.82, xEnd: 0.18, yEnd: 1.00, label: 'bottom_roof_left'),
  Obstacle(xStart: 0.24, yStart: 0.85, xEnd: 0.52, yEnd: 1.00, label: 'bottom_roof_mid'),
  Obstacle(xStart: 0.88, yStart: 0.82, xEnd: 1.00, yEnd: 1.00, label: 'bottom_roof_right'),
];