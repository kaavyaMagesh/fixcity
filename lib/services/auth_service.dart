import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] ?? 'Citizen';
        }
      } catch (e) {
        print("Error fetching role: $e");
      }
    }
    return 'Citizen';
  }

  // 👇 UPDATED: Now accepts 'role' argument
  Future<UserCredential> signUpWithEmail(String email, String password, String role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save the selected role to Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role, // 👈 Uses the role you picked
        'totalXP': 0,
      });

      return cred;
    } catch (e) {
      throw e;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    // ... (Google Sign In code remains the same, defaults to Citizen) ...
    // For brevity, I'm omitting the full Google logic here as it doesn't change
    // If you need it, copy it from the previous response.
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential cred = await _auth.signInWithCredential(credential);
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'email': cred.user!.email,
          'role': 'Citizen', // Google always defaults to Citizen
          'totalXP': 0,
        });
      }
      return cred;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}