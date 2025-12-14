import 'package:flutter/material.dart';

// This is the model for the "flowchart" part of your JSON
class FlowchartData {
  final List<ApiFlowNode> nodes;
  final List<ApiFlowEdge> edges;

  FlowchartData({required this.nodes, required this.edges});

  factory FlowchartData.fromJson(Map<String, dynamic> json) {
    var nodesList = json['nodes'] as List;
    var edgesList = json['edges'] as List;

    List<ApiFlowNode> nodes =
    nodesList.map((i) => ApiFlowNode.fromJson(i)).toList();
    List<ApiFlowEdge> edges =
    edgesList.map((i) => ApiFlowEdge.fromJson(i)).toList();

    return FlowchartData(nodes: nodes, edges: edges);
  }
}

// This model represents a node from your API
// It's similar to your 'node_model.dart' but matches the JSON 'x' and 'y'
class ApiFlowNode {
  final int id;
  final String label;
  final double x;
  final double y;

  // A helper to easily get the position as an Offset
  Offset get position => Offset(x, y);

  ApiFlowNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
  });

  factory ApiFlowNode.fromJson(Map<String, dynamic> json) {
    return ApiFlowNode(
      id: json['id'],
      label: json['label'],
      // Ensure x and y are treated as doubles
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

// This model represents an edge from your API
class ApiFlowEdge {
  final int from; // The ID of the starting node
  final int to; // The ID of the ending node

  ApiFlowEdge({required this.from, required this.to});

  factory ApiFlowEdge.fromJson(Map<String, dynamic> json) {
    return ApiFlowEdge(
      from: json['from'],
      to: json['to'],
    );
  }
}

// You can also model the full response if you need the notes at the same time
class FullApiResponse {
  final String status;
  final FlowchartData flowchart;
  // You would add models for 'structured_output' here too
  // final StructuredOutput structuredOutput;

  FullApiResponse({required this.status, required this.flowchart});

  factory FullApiResponse.fromJson(Map<String, dynamic> json) {
    return FullApiResponse(
      status: json['status'],
      flowchart: FlowchartData.fromJson(json['flowchart']),
      // structuredOutput: StructuredOutput.fromJson(json['structured_output']),
    );
  }
}