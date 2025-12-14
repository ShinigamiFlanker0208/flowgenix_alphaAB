import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- ADD THIS IMPORT ---
import 'package:flowgenix/features/dashboards/data/models/artifact_model.dart';

class ArtifactService {
  // Static instance for singleton pattern
  static final ArtifactService _instance = ArtifactService._internal();
  factory ArtifactService() => _instance;
  ArtifactService._internal();

  static ArtifactService get instance => _instance;

  // Get Firebase service instances
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Saves the complete artifact (preview image and data) to Firebase.
  Future<void> saveArtifact(String artifactName, Uint8List imageData, String jsonString) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User is not logged in. Cannot save artifact.");
    }
    String userId = user.uid;

    try {
      DocumentReference docRef = _db
          .collection('users')
          .doc(userId)
          .collection('artifacts')
          .doc();

      String artifactId = docRef.id;
      final String imagePath = 'artifact_previews/$userId/$artifactId.png';
      final Reference storageRef = _storage.ref().child(imagePath);

      final metadata = SettableMetadata(contentType: 'image/png');
      UploadTask uploadTask = storageRef.putData(imageData, metadata);

      TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await docRef.set({
        'name': artifactName,
        'createdAt': FieldValue.serverTimestamp(),
        'previewImageUrl': downloadUrl,
        'canvasState': jsonString,
        'userId': userId,
      });
    } catch (e) {
      print("Error saving artifact: $e");
      throw Exception("Failed to save artifact to Firebase: $e");
    }
  }

  // --- ADD THIS NEW METHOD ---
  /// Fetches a list of all artifacts for the current user.
  Future<List<Artifact>> getArtifacts() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("No user logged in, returning empty artifact list.");
      return []; // Return an empty list if no user is logged in
    }
    String userId = user.uid;

    try {
      // Get the collection, order by creation date (newest first)
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('artifacts')
          .orderBy('createdAt', descending: true)
          .get();

      // Map each document to an Artifact object
      return snapshot.docs
          .map((doc) => Artifact.fromFirestore(doc))
          .toList();

    } catch (e) {
      print("Error fetching artifacts: $e");
      return []; // Return empty list on error
    }
  }
}