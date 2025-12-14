// lib/features/dashboard/data/models/node_model.dart

import 'package:flutter/material.dart';

class FlowNode {
  final int id;
  final String label;
  Offset position; // We use Offset to store (x, y) coordinates

  FlowNode({
    required this.id,
    required this.label,
    required this.position,
  });
}