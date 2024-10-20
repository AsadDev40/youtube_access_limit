import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    // Begin Interactive Sign In Process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    // Obtain OAuth details from request
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // Finally lets Sign In
    return _auth.signInWithCredential(credential);
  }

  // Sign Up with Google
  Future<UserCredential> signUpWithGoogle() async {
    // Sign in with Google to get user credentials
    final UserCredential userCredential = await signInWithGoogle();

    // Create user if not exists
    if (userCredential.user != null) {}
    return userCredential;
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    final AuthorizationCredentialAppleID credential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: credential.identityToken!,
      accessToken: credential.authorizationCode,
    );

    return _auth.signInWithCredential(oauthCredential);
  }

  // Sign Up with Apple
  Future<UserCredential> signUpWithApple() async {
    final UserCredential userCredential = await signInWithApple();
    // Create user if not exists
    if (userCredential.user != null) {
      // Additional user creation logic, if needed
      // For instance, create user profile in Firestore if not already done
    }
    return userCredential;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    final UserCredential userCredential = await _auth
        .signInWithEmailAndPassword(email: email, password: password);
    return userCredential;
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    final UserCredential userCredential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);
    return userCredential;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
