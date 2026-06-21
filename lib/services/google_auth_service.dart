import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // serverClientId is the web client from google-services.json (client_type: 3).
  // Without it, idToken is null on Android and signInWithCredential hangs.
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '3764155961-i65drlrkajoljn96d78464sbtbrqkp79.apps.googleusercontent.com',
  );
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static bool get isSignedIn => _auth.currentUser != null;

  static String? get displayName => currentUser?.displayName;
  static String? get email => currentUser?.email;
  static String? get uid => currentUser?.uid;
  static String? get photoUrl => currentUser?.photoURL;

  static Future<User?> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Google idToken is null — serverClientId may be wrong');
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
