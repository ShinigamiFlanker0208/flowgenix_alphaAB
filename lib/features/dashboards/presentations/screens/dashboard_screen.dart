import 'package:flutter/material.dart';
import 'package:flowgenix/features/dashboards/data/services/artifact_service.dart';
import 'package:flowgenix/features/dashboards/presentations/screens/canvas_screen.dart';
import 'package:intl/intl.dart';
import 'package:animated_background/animated_background.dart';

import 'package:flowgenix/features/dashboards/data/models/artifact_model.dart';

const Color _kDarkBackground = Color(0xFF1a1a2e);
const Color _kDarkAccent = Color(0xFF16213e);
const Color _kPrimaryColor = Color(0xFF6C63FF);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {

  late Future<List<Artifact>> _artifactsFuture;

  @override
  void initState() {
    super.initState();
    _artifactsFuture = ArtifactService.instance.getArtifacts();
  }

  void _refreshArtifacts() {
    setState(() {
      _artifactsFuture = ArtifactService.instance.getArtifacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Saved Artifacts',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kDarkAccent, _kDarkBackground, _kDarkBackground],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBackground(
                behaviour: RandomParticleBehaviour(
                  options: ParticleOptions(
                    baseColor: _kPrimaryColor.withOpacity(0.15),
                    spawnOpacity: 0.15,
                    opacityChangeRate: -0.01,
                    minOpacity: 0.0,
                    maxOpacity: 0.2,
                    particleCount: 60,
                    spawnMaxRadius: 3.0,
                    spawnMinRadius: 1.0,
                    spawnMaxSpeed: 12.0,
                    spawnMinSpeed: 3.0,
                  ),
                ),
                vsync: this,
                child: Container(),
              ),
            ),
            SafeArea(
              child: FutureBuilder<List<Artifact>>(
                future: _artifactsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kPrimaryColor),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading artifacts: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final artifacts = snapshot.data!;
                  return _buildArtifactList(artifacts);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_outlined,
              color: Colors.white30, size: 80),
          SizedBox(height: 20),
          Text(
            'No Saved Artifacts',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Create a flowchart and tap the save icon.',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildArtifactList(List<Artifact> artifacts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: artifacts.length,
      itemBuilder: (context, index) {
        final artifact = artifacts[index];
        return _buildArtifactCard(artifact);
      },
    );
  }

  Widget _buildArtifactCard(Artifact artifact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _kDarkAccent.withOpacity(0.6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kPrimaryColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () async {
          // This is where the magic happens:
          // We pass the raw 'canvasState' JSON string to the CanvasScreen
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CanvasScreen(artifactJson: artifact.canvasState),
            ),
          );
          // Refresh the list when returning just in case
          _refreshArtifacts();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              artifact.previewImageUrl, // Use the URL from Firebase Storage
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: _kPrimaryColor.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _kPrimaryColor,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print("Error loading image: $error");
                return Container(
                  height: 150,
                  color: _kPrimaryColor.withOpacity(0.1),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 40),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artifact.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saved on ${DateFormat.yMMMd().format(artifact.createdAt)}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}