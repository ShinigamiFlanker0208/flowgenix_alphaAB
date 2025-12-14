// lib/features/dashboards/data/models/canvas_object_model.dart

import 'package:flutter/material.dart';

enum CanvasObjectType {
  node,
  text,
  emoji,
}

class CanvasObject {
  int id;
  CanvasObjectType type;
  String data;
  Offset position;
  Size size;
  TextEditingController textController;

  CanvasObject({
    required this.id,
    required this.type,
    required this.data,
    required this.position,
    this.size = const Size(150, 80),
  }) : textController = TextEditingController(text: data);

  void dispose() {
    textController.dispose();
  }
}