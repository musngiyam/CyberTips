import 'package:flutter/material.dart';

class TallGrass {
  double x;
  double y;

  TallGrass({required this.x, required this.y});

  Widget render() {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.green.shade800,
          border: Border.all(color: Colors.green.shade900, width: 0.5),
        ),
        child: const Center(
          child: Text('w', style: TextStyle(color: Colors.lightGreenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}