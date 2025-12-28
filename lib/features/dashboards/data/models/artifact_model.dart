import 'package:cloud_firestore/cloud_firestore.dart';

class Artifact {
  final String id;
  final String name;
  final DateTime createdAt;
  final String previewImageUrl; // This is the URL from Firebase Storage
  final String canvasState;     // This is the JSON string
  final String userId;

  Artifact({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.previewImageUrl,
    required this.canvasState,
    required this.userId,
  });

  // Factory constructor to create an Artifact from a Firestore document
  factory Artifact.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle potential nulls or data type issues gracefully
    final createdAtData = data['createdAt'];
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else {
      // Fallback if data is missing or wrong type
      createdAt = DateTime.now();
    }

    return Artifact(
      id: doc.id,
      name: data['name'] ?? 'Untitled Artifact',
      createdAt: createdAt,
      previewImageUrl: data['previewImageUrl'] ?? '',
      canvasState: data['canvasState'] ?? '{}', // Default to empty JSON object
      userId: data['userId'] ?? '',
    );
  }
}