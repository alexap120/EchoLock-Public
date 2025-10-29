import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      await _firestore.collection('users').doc(user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': '',
        'phoneVerified': false,
        'two_fa_enabled': false,
        'totp_secret': '',
      });

      await user.sendEmailVerification();

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  Future<dynamic> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user == null) {
        return 'User not found after login.';
      }

      if (!user.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email before logging in.';
      }

      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return 'User profile data not found.';
      }

      Map<String, dynamic>? userData = userDoc.data();

      return userData;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException [${e.code}]: ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email format.';
        case 'invalid-credential':
          return 'Invalid login credentials. Please check your password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return 'Login error [${e.code}]: ${e.message}';
      }
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return 'Error: ${e.message}';
      }
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }
}

String _handleFirebaseAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'This email is already in use.';
    case 'invalid-email':
      return 'The email address is not valid.';
    case 'weak-password':
      return 'The password is too weak.';
    case 'operation-not-allowed':
      return 'Email/password accounts are not enabled.';
    default:
      return 'Authentication error: ${e.message}';
  }
}
