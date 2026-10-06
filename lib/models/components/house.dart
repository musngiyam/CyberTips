import 'package:flutter/material.dart';

class House {
  double x;
  double y;
  String type;

  House({required this.x, required this.y, this.type = 'house'});

  Widget render() {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: 75,
        height: 65,
        decoration: BoxDecoration(
          color: type == 'hospital' ? Colors.blue.shade300 : Colors.brown.shade400,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: type == 'hospital' ? Colors.red : Colors.orange.shade800,
                border: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
              child: Center(
                child: Text(
                  type == 'hospital' ? '+' : 'ROOF',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 16,
                  height: 22,
                  color: Colors.brown.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}