import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. SIGN UP & SEND VERIFICATION
  // We now return a String? error message. If it's null, it succeeded.
  Future<String?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      // Create the user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), // CRITICAL: Trim spaces
        password: password.trim(), // CRITICAL: Trim spaces
      );

      // Send the verification email immediately
      await credential.user?.sendEmailVerification();

      return null; // Success!
    } on FirebaseAuthException catch (e) {
      // Return the specific error message from Firebase
      return e.message;
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  // 2. SIGN IN
  // We now return the User object if successful, OR throw an exception if it fails.
  // This allows the UI to handle success and failure more clearly.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(), // CRITICAL: Trim spaces
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // We throw the error so the UI can catch it and show the specific message
      throw e.message ?? "Login failed";
    } catch (e) {
      throw "An unknown error occurred during login.";
    }
  }

  // 3. PASSWORD RESET (Bonus: You'll need this soon)
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper to get current user
  User? get currentUser => _auth.currentUser;
}