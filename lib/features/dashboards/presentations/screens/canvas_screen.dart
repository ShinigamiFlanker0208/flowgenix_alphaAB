// lib/features/dashboards/presentations/screens/canvas_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flowgenix/presentation/theme/color_palette.dart';
import 'package:flowgenix/features/dashboards/data/models/canvas_object_model.dart';
import 'package:flowgenix/features/dashboards/data/services/artifact_service.dart';
import 'package:flowgenix/features/dashboards/data/services/flowchart_service.dart';
import 'package:flowgenix/features/dashboards/data/models/api_response_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

// Modern color scheme with gradients
const Color kDarkBackground = Color(0xFF0A0E27);
const Color kDarkAccent = Color(0xFF1A1F3A);
const Color kCardBackground = Color(0xFF252B48);
const Color kAccentGlow = Color(0xFF6C5CE7);
const Color kSecondaryGlow = Color(0xFF00D4FF);

class EdgePainter extends CustomPainter {
  final List<Map<String, int>> edges;
  final Map<int, GlobalKey> objectKeys;
  final GlobalKey stackKey;

  EdgePainter({required this.edges, required this.objectKeys, required this.stackKey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kSecondaryGlow.withOpacity(0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = kSecondaryGlow.withOpacity(0.15)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final stackRenderBox = stackKey.currentContext?.findRenderObject();
    if (stackRenderBox == null) return;

    for (var edge in edges) {
      final fromNodeKey = objectKeys[edge['from']];
      final toNodeKey = objectKeys[edge['to']];
      if (fromNodeKey?.currentContext != null && toNodeKey?.currentContext != null) {
        final fromRenderBox = fromNodeKey!.currentContext!.findRenderObject() as RenderBox;
        final toRenderBox = toNodeKey!.currentContext!.findRenderObject() as RenderBox;
        final fromCenter = fromRenderBox.localToGlobal(fromRenderBox.size.center(Offset.zero), ancestor: stackRenderBox);
        final toCenter = toRenderBox.localToGlobal(toRenderBox.size.center(Offset.zero), ancestor: stackRenderBox);

        // Draw glow effect
        canvas.drawLine(fromCenter, toCenter, glowPaint);
        // Draw main line
        canvas.drawLine(fromCenter, toCenter, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CanvasScreen extends StatefulWidget {
  final String? artifactJson;
  const CanvasScreen({super.key, this.artifactJson});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> with SingleTickerProviderStateMixin {
  final double _canvasWidth = 10000;
  final double _canvasHeight = 10000;
  late final Offset _canvasCenter;

  bool _isLoading = false;
  String _loadingMessage = 'Processing...';
  final ImagePicker _picker = ImagePicker();
  final FlowchartService _flowchartService = FlowchartService();

  List<CanvasObject> _canvasObjects = [];
  List<Map<String, int>> _edges = [];
  final Map<int, GlobalKey> _objectKeys = {};
  final GlobalKey _stackKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _isConnecting = false;
  int? _firstObjectToConnect;
  final List<String> _emojis = ['😀', '❤️', '👍', '🎉', '⭐', '🔥', '💡', '✅'];

  String _summaryNotes = '';
  Map<String, String> _deepExplanations = {};
  int _currentPageIndex = 0;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _canvasCenter = Offset(_canvasWidth / 2, _canvasHeight / 2);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.artifactJson != null) {
        _loadGraphFromJson(widget.artifactJson!);
      }
      _centerView();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _saveCanvas() async {
    final artifactName = await _showSaveDialog();
    if (artifactName == null || artifactName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Capturing screenshot...';
    });

    try {
      final Uint8List? imageData = await _screenshotController.capture(
        pixelRatio: 1.5,
        delay: const Duration(milliseconds: 20),
      );

      if (imageData == null) {
        throw Exception('Failed to capture canvas preview.');
      }

      setState(() => _loadingMessage = 'Preparing data...');

      final savableObjects = _canvasObjects.map((obj) => {
        'id': obj.id,
        'type': obj.type.index,
        'data': obj.data,
        'position': {'dx': obj.position.dx, 'dy': obj.position.dy},
        'size': {'width': obj.size.width, 'height': obj.size.height},
      }).toList();

      final Map<String, dynamic> canvasState = {
        'objects': savableObjects,
        'edges': _edges,
        'notes': _summaryNotes,
        'deepExplanations': _deepExplanations,
      };

      final jsonString = jsonEncode(canvasState);

      setState(() => _loadingMessage = 'Saving to cloud...');

      await ArtifactService.instance.saveArtifact(artifactName, imageData, jsonString);

      _showSuccessSnackBar('Artifact "$artifactName" saved successfully!');

    } catch (e) {
      _showErrorSnackBar('Failed to save artifact: $e');
      print('Save artifact error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadNotes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/notes_${DateTime.now().millisecondsSinceEpoch}.txt';

      final buffer = StringBuffer();
      buffer.writeln('SUMMARY NOTES');
      buffer.writeln('=' * 50);
      buffer.writeln(_summaryNotes);
      buffer.writeln('\n');

      if (_deepExplanations.isNotEmpty) {
        buffer.writeln('DETAILED EXPLANATIONS');
        buffer.writeln('=' * 50);
        _deepExplanations.forEach((topic, explanation) {
          buffer.writeln('\n### $topic ###\n');
          buffer.writeln(explanation);
          buffer.writeln('\n${'-' * 50}\n');
        });
      }

      await File(filePath).writeAsString(buffer.toString());
      _showSuccessSnackBar('Notes downloaded to: $filePath');
    } catch (e) {
      _showErrorSnackBar('Failed to download notes: $e');
    }
  }

  Future<String?> _showSaveDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kCardBackground, kDarkAccent],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kAccentGlow.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAccentGlow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.save_outlined, color: kAccentGlow, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Save Artifact',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Enter artifact name",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: kDarkBackground.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentGlow,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(controller.text),
                    child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 15))),
        ],
      ),
      backgroundColor: kAccentGlow,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 15))),
        ],
      ),
      backgroundColor: const Color(0xFFFF6B6B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _generateFlowchartFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _loadingMessage = 'Uploading image...';
      });

      final imageFile = File(image.path);

      setState(() => _loadingMessage = 'Processing with Passion...');
      final Map<String, dynamic> response = await _flowchartService.getFlowchartFromImage(imageFile);

      setState(() => _loadingMessage = 'Building flowchart...');
      _loadFlowchartData(response);

      _showSuccessSnackBar('Flowchart generated! 🎉');

    } catch (e) {
      print('Error generating flowchart: $e');
      _showErrorSnackBar('Failed to generate flowchart: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
      if (mounted) setState(() {});
    });
  }

  Future<void> _generateFlowchartFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _loadingMessage = 'Uploading image...';
      });

      final imageFile = File(image.path);

      setState(() => _loadingMessage = 'Processing with AI...');
      final Map<String, dynamic> response = await _flowchartService.getFlowchartFromImage(imageFile);

      setState(() => _loadingMessage = 'Building flowchart...');
      _loadFlowchartData(response);

      _showSuccessSnackBar('Flowchart generated! 🎉');

    } catch (e) {
      print('Error generating flowchart: $e');
      _showErrorSnackBar('Failed to generate flowchart: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerView();
      if (mounted) setState(() {});
    });
  }

  void _loadFlowchartData(dynamic data) {
    print('📊 Loading flowchart data from API');
    _canvasObjects.clear();
    _edges.clear();
    _objectKeys.clear();

    FlowchartData flowchartData;
    String tempSummaryNotes = '';
    Map<String, String> tempDeepExplanations = {};

    if (data is Map<String, dynamic>) {
      final jsonData = data;
      if (!jsonData.containsKey('flowchart')) {
        _showErrorSnackBar('API response is missing "flowchart" data.');
        return;
      }
      flowchartData = FlowchartData.fromJson(jsonData['flowchart']);

      if (jsonData.containsKey('structured_output')) {
        final structured = jsonData['structured_output'];
        if (structured != null && structured is Map) {
          tempSummaryNotes = structured['notes'] ?? '';
          final deepExp = structured['deep_explanations'];
          if (deepExp is Map) {
            tempDeepExplanations = deepExp.map((key, value) => MapEntry(key.toString(), value.toString()));
          }
        }
      }
    } else {
      _showErrorSnackBar('Unknown API data type: ${data.runtimeType}');
      return;
    }

    final newObjects = flowchartData.nodes.map<CanvasObject>((apiNode) {
      _objectKeys[apiNode.id] = GlobalKey();
      final Size nodeSize = _calculateNodeSize(apiNode.label);

      return CanvasObject(
        id: apiNode.id,
        type: CanvasObjectType.node,
        data: apiNode.label,
        position: Offset(
          _canvasCenter.dx + (apiNode.x * 2.5),
          _canvasCenter.dy + (apiNode.y * 2.5),
        ),
        size: nodeSize,
      );
    }).toList();

    final newEdges = flowchartData.edges.map<Map<String, int>>((apiEdge) {
      return {'from': apiEdge.from, 'to': apiEdge.to};
    }).toList();

    setState(() {
      _canvasObjects = newObjects;
      _edges = newEdges;
      _summaryNotes = tempSummaryNotes;
      _deepExplanations = tempDeepExplanations;
    });
  }

  Size _calculateNodeSize(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 300);

    final width = (textPainter.width + 40).clamp(120.0, 350.0);
    final height = (textPainter.height + 32).clamp(60.0, 200.0);

    return Size(width, height);
  }

  void _loadGraphFromJson(String jsonString) {
    _canvasObjects.clear();
    _edges.clear();
    _objectKeys.clear();

    print("Loading artifact from JSON...");

    try {
      final Map<String, dynamic> canvasState = jsonDecode(jsonString);

      final objectsData = canvasState['objects'] as List?;
      if (objectsData == null) {
        throw Exception("Artifact data is corrupt. Missing 'objects' list.");
      }

      final newObjects = objectsData.map<CanvasObject>((objJson) {
        final id = objJson['id'];
        _objectKeys[id] = GlobalKey();

        return CanvasObject(
          id: id,
          type: CanvasObjectType.values[objJson['type']],
          data: objJson['data'],
          position: Offset(objJson['position']['dx'], objJson['position']['dy']),
          size: Size(objJson['size']['width'], objJson['size']['height']),
        );
      }).toList();

      final newEdges = (canvasState['edges'] as List).map<Map<String, int>>((edgeJson) {
        return {
          'from': (edgeJson['from'] as num).toInt(),
          'to': (edgeJson['to'] as num).toInt()
        };
      }).toList();

      setState(() {
        _canvasObjects = newObjects;
        _edges = newEdges;
        _summaryNotes = canvasState['notes'] ?? '';
        _deepExplanations = Map<String, String>.from(canvasState['deepExplanations'] ?? {});
      });

      print("Successfully loaded ${_canvasObjects.length} objects and ${_edges.length} edges.");

    } catch (e) {
      print("Error loading graph from JSON: $e");
      try {
        print("Attempting to load as API response...");
        final Map<String, dynamic> data = jsonDecode(jsonString);
        if (data.containsKey('flowchart')) {
          _loadFlowchartData(data);
        } else {
          _showErrorSnackBar("Failed to load artifact: Invalid format.");
        }
      } catch (e2) {
        _showErrorSnackBar("Failed to load artifact: $e");
      }
    }
  }

  void _centerView() {
    if (!mounted) return;
    final screenWidth = context.size?.width ?? 400;
    final screenHeight = context.size?.height ?? 800;
    final matrix = Matrix4.translationValues(
        -_canvasCenter.dx + screenWidth / 2,
        -_canvasCenter.dy + screenHeight / 2,
        0.0);
    _transformationController.value = matrix;
  }

  int _getNewId() {
    return (_canvasObjects.isNotEmpty ? _canvasObjects.map((o) => o.id).reduce(max) : 0) + 1;
  }

  Offset _getCanvasCenter() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final viewCenter = renderBox.size.center(Offset.zero);
    return _transformationController.toScene(viewCenter);
  }

  void _addNode() {
    setState(() {
      final newId = _getNewId();
      _objectKeys[newId] = GlobalKey();
      _canvasObjects.add(CanvasObject(
        id: newId,
        type: CanvasObjectType.node,
        data: 'Editable Node',
        position: _getCanvasCenter(),
      ));
    });
  }

  void _addTextBox() {
    setState(() {
      final newId = _getNewId();
      _objectKeys[newId] = GlobalKey();
      _canvasObjects.add(CanvasObject(
        id: newId,
        type: CanvasObjectType.text,
        data: 'Editable Text',
        position: _getCanvasCenter(),
      ));
    });
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kCardBackground, kDarkAccent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kAccentGlow.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kAccentGlow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('😀', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Select Emoji',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 300,
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _emojis.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            final newId = _getNewId();
                            _objectKeys[newId] = GlobalKey();
                            _canvasObjects.add(CanvasObject(
                                id: newId,
                                type: CanvasObjectType.emoji,
                                data: _emojis[index],
                                position: _getCanvasCenter(),
                                size: const Size(80, 80)));
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: kDarkBackground.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Center(
                            child: Text(_emojis[index], style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kCardBackground, kDarkAccent],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Generate Flowchart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take Photo',
                    subtitle: 'Capture with camera',
                    onTap: () {
                      Navigator.pop(context);
                      _generateFlowchartFromCamera();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    title: 'Choose from Gallery',
                    subtitle: 'Select existing image',
                    onTap: () {
                      Navigator.pop(context);
                      _generateFlowchartFromGallery();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kDarkBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAccentGlow, kSecondaryGlow],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleConnectionMode() {
    setState(() {
      _isConnecting = !_isConnecting;
      _firstObjectToConnect = null;
    });
  }

  void _handleObjectTap(CanvasObject object) {
    if (!_isConnecting) return;
    if (object.type == CanvasObjectType.node || object.type == CanvasObjectType.text) {
      setState(() {
        if (_firstObjectToConnect == null) {
          _firstObjectToConnect = object.id;
        } else {
          if (_firstObjectToConnect != object.id) {
            _edges.add({'from': _firstObjectToConnect!, 'to': object.id});
          }
          _firstObjectToConnect = null;
          _isConnecting = false;
        }
      });
    }
  }

  void _showObjectContextMenu(BuildContext context, CanvasObject object, LongPressStartDetails details) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: kCardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'delete') {
        setState(() {
          _canvasObjects.removeWhere((o) => o.id == object.id);
          _edges.removeWhere((edge) => edge['from'] == object.id || edge['to'] == object.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kAccentGlow, kSecondaryGlow],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_tree_rounded, size: 20),
            ),
            const SizedBox(width: 4),
            const Text('FlowGenix Canvas', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: kDarkAccent.withOpacity(0.95),
        elevation: 0,
        actions: [
          if (_currentPageIndex == 1)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAccentGlow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded, size: 20),
              ),
              onPressed: _downloadNotes,
              tooltip: 'Download Notes',
            ),
          if (_currentPageIndex == 0)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAccentGlow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.save_rounded, size: 20),
              ),
              onPressed: _saveCanvas,
              tooltip: 'Save Artifact',
            ),
          if (_currentPageIndex == 0 && _isConnecting)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFFFF6B6B)),
              ),
              onPressed: _toggleConnectionMode,
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _currentPageIndex == 0
          ? ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            _fabAnimationController.forward().then((_) {
              _fabAnimationController.reverse();
            });
            _showImageSourcePicker();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kAccentGlow, kSecondaryGlow],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: kAccentGlow.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, size: 22),
                SizedBox(width: 8),
                Text('Generate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      )
          : null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentPageIndex == 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kCardBackground, kDarkAccent],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kAccentGlow.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernToolbarButton(Icons.add_box_rounded, 'Node', _addNode),
                  _buildModernToolbarButton(Icons.link_rounded, 'Connect', _toggleConnectionMode, isActive: _isConnecting),
                  _buildModernToolbarButton(Icons.text_fields_rounded, 'Text', _addTextBox),
                  _buildModernToolbarButton(Icons.emoji_emotions_rounded, 'Emoji', _showEmojiPicker),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kDarkAccent.withOpacity(0.95), kDarkAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.account_tree_rounded,
                      label: 'Flowchart',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.description_rounded,
                      label: 'Notes',
                      index: 1,
                      hasBadge: _summaryNotes.isNotEmpty || _deepExplanations.isNotEmpty,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentPageIndex,
        children: [
          _buildFlowchartPage(),
          _buildNotesPage(),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool hasBadge = false,
  }) {
    final isSelected = _currentPageIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentPageIndex = index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [kAccentGlow, kSecondaryGlow])
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        size: 24,
                      ),
                    ),
                    if (hasBadge && !isSelected)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [kAccentGlow, kSecondaryGlow]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kAccentGlow.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowchartPage() {
    return Stack(
      children: [
        Screenshot(
          controller: _screenshotController,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  kDarkBackground,
                  kDarkBackground.withOpacity(0.95),
                  const Color(0xFF05070F),
                ],
              ),
            ),
            child: InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.01,
              maxScale: 4.0,
              child: SizedBox(
                width: _canvasWidth,
                height: _canvasHeight,
                child: Stack(
                  key: _stackKey,
                  children: [
                    CustomPaint(
                      painter: EdgePainter(
                        edges: _edges,
                        objectKeys: _objectKeys,
                        stackKey: _stackKey,
                      ),
                      child: const SizedBox.shrink(),
                    ),
                    if (_canvasObjects.isEmpty && !_isLoading)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kAccentGlow.withOpacity(0.1), kSecondaryGlow.withOpacity(0.1)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 64,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height:0.25),
                            Text(
                              'Create Your First Flowchart',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the Generate button to create from an image\nor use the toolbar to add elements manually',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ..._canvasObjects.map((object) {
                      return Positioned(
                        key: _objectKeys[object.id],
                        left: object.position.dx,
                        top: object.position.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              object.position += details.delta;
                            });
                          },
                          child: _buildCanvasObject(object),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kDarkBackground.withOpacity(0.98),
                  kDarkBackground.withOpacity(0.95),
                ],
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kCardBackground, kDarkAccent],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kAccentGlow.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: kAccentGlow,
                        strokeWidth: 5,
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotesPage() {
    if (_summaryNotes.isEmpty && _deepExplanations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kAccentGlow.withOpacity(0.1), kSecondaryGlow.withOpacity(0.1)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_add_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notes Available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate a flowchart to see Detailed Notes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 2.0,
          colors: [
            kDarkBackground,
            const Color(0xFF05070F),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Summary Notes Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kCardBackground, kDarkAccent],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: kAccentGlow.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kAccentGlow.withOpacity(0.3), kSecondaryGlow.withOpacity(0.3)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.summarize_rounded, color: kAccentGlow, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Summary Notes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 7
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 0),
                  TextField(
                    controller: TextEditingController(text: _summaryNotes)
                      ..selection = TextSelection.collapsed(offset: _summaryNotes.length),
                    maxLines: null,
                    readOnly: false,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'No summary available',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    ),
                    onChanged: (value) {
                      setState(() => _summaryNotes = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Deep Explanations Section
            if (_deepExplanations.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kAccentGlow.withOpacity(0.3), kSecondaryGlow.withOpacity(0.3)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: kSecondaryGlow, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detailed Explanations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._deepExplanations.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kCardBackground, kDarkAccent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: kSecondaryGlow.withOpacity(0.08),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kAccentGlow.withOpacity(0.2), kSecondaryGlow.withOpacity(0.2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kSecondaryGlow.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: entry.value)
                          ..selection = TextSelection.collapsed(offset: entry.value.length),
                        maxLines: null,
                        readOnly: false,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _deepExplanations[entry.key] = value;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasObject(CanvasObject object) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _handleObjectTap(object),
          onLongPressStart: (details) => _showObjectContextMenu(context, object, details),
          child: _buildObjectContent(object),
        ),
        if (object.type != CanvasObjectType.emoji)
          Positioned(
            bottom: -12,
            right: -12,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final newWidth = object.size.width + details.delta.dx;
                  final newHeight = object.size.height + details.delta.dy;
                  object.size = Size(max(50, newWidth), max(50, newHeight));
                });
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAccentGlow, kSecondaryGlow],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kAccentGlow.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.open_in_full_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildObjectContent(CanvasObject object) {
    if (object.type == CanvasObjectType.emoji) {
      return _buildEmoji(object);
    }
    Widget content;
    BoxDecoration decoration;
    switch (object.type) {
      case CanvasObjectType.node:
        content = _buildNode(object);
        decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _firstObjectToConnect == object.id
                ? [const Color(0xFFFFD93D), const Color(0xFFFFB800)]
                : [kAccentGlow, kSecondaryGlow],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_firstObjectToConnect == object.id ? const Color(0xFFFFD93D) : kAccentGlow).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        );
        break;
      case CanvasObjectType.text:
        content = _buildTextBox(object);
        decoration = BoxDecoration(
          color: _firstObjectToConnect == object.id ? const Color(0xFFFFD93D).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _firstObjectToConnect == object.id
                ? const Color(0xFFFFD93D)
                : Colors.white.withOpacity(0.1),
            width: _firstObjectToConnect == object.id ? 3 : 1.5,
          ),
        );
        break;
      default:
        content = Container();
        decoration = BoxDecoration();
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        width: object.size.width,
        height: object.size.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: decoration,
        child: Center(child: content),
      ),
    );
  }

  Widget _buildNode(CanvasObject object) {
    return TextField(
      controller: object.textController,
      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
      maxLines: null,
      onChanged: (newText) => object.data = newText,
    );
  }

  Widget _buildTextBox(CanvasObject object) {
    return TextField(
      controller: object.textController,
      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: kAccentGlow,
      maxLines: null,
      onChanged: (newText) => object.data = newText,
    );
  }

  Widget _buildEmoji(CanvasObject object) {
    return Container(
      width: object.size.width,
      height: object.size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentGlow.withOpacity(0.1), kSecondaryGlow.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(object.data),
      ),
    );
  }

  Widget _buildModernToolbarButton(IconData icon, String label, VoidCallback onPressed, {bool isActive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: [const Color(0xFFFFD93D), const Color(0xFFFFB800)])
                : null,
            color: isActive ? null : kDarkBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFFFFD93D) : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}