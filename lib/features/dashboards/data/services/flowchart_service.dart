// lib/features/dashboards/data/services/flowchart_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Import your response models
import 'package:flowgenix/features/dashboards/data/models/api_response_model.dart';

class FlowchartService {

  // === THIS IS THE CORRECTED LIVE API ENDPOINT ===
  final String _apiUrl = "https://flowgenix-api-384589582331.us-central1.run.app/process-whiteboard";

  // --- FIX 1: Change the return type from FlowchartData to Map<String, dynamic> ---
  Future<Map<String, dynamic>> getFlowchartFromImage(File imageFile) async {
    try {
      // 1. Create a Multipart request
      var request = http.MultipartRequest("POST", Uri.parse(_apiUrl));

      // 2. Attach the file to the request
      // This is now confirmed to be correct from your cURL command
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // The key is 'file'
          imageFile.path,
        ),
      );

      // Add the 'accept' header, just like in the cURL command
      request.headers['accept'] = 'application/json';

      // 3. Send the request
      print("Sending image to API at $_apiUrl");
      var streamedResponse = await request.send();

      // 4. Get the response
      var response = await http.Response.fromStream(streamedResponse);

      // 5. Check for a successful response (HTTP 200)
      if (response.statusCode == 200) {
        print("API Response success!");
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          // --- FIX 2: Return the ENTIRE JSON map, not just the flowchart ---
          return jsonData;
        } else {
          throw Exception("API returned an error: ${jsonData['message'] ?? 'Unknown error'}");
        }

      } else {
        // Handle server errors
        print("API Error: ${response.statusCode}");
        print("Response body: ${response.body}");
        throw Exception("Failed to load flowchart. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // Handle network or other errors
      print("Error in FlowchartService: $e");
      throw Exception("Failed to connect to the server: $e");
    }
  }
}