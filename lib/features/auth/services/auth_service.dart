import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../../services/database_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();
  // This is required for Web: GoogleSignIn needs the Web Client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '766301000676-bbhb70etko6qt8gp75vt1bu2vq7aijl3.apps.googleusercontent.com' : null,
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // تسجيل بالإيميل وكلمة المرور
  Future<String?> signUp({required String name, required String email, required String password}) async {
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await _dbService.createUserDocument(
          uid: credential.user!.uid,
          email: email,
          name: name,
        );
      }
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message ?? 'حدث خطأ أثناء التسجيل';
    } catch (e) {
      _setLoading(false);
      return 'حدث خطأ غير معروف';
    }
  }

  // تسجيل دخول بالإيميل وكلمة المرور
  Future<String?> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (credential.user != null) {
        await _dbService.createUserDocument(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
          name: credential.user!.displayName ?? email.split('@')[0],
          photoUrl: credential.user!.photoURL,
        );
      }
      
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message ?? 'حدث خطأ أثناء تسجيل الدخول';
    } catch (e) {
      _setLoading(false);
      return 'حدث خطأ غير معروف';
    }
  }

  // تسجيل دخول بجوجل
  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    try {
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // للويب: استخدم popup مباشرة
        await _googleSignIn.signInSilently();
        googleUser = await _googleSignIn.signIn();
      } else {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        _setLoading(false);
        return 'تم إلغاء تسجيل الدخول';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      
      // Update Database
      if (result.user != null) {
        await _dbService.createUserDocument(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? 'مستخدم جديد',
          photoUrl: result.user!.photoURL ?? '',
        );
      }

      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message ?? 'حدث خطأ أثناء تسجيل الدخول بجوجل';
    } catch (e) {
      _setLoading(false);
      return 'حدث خطأ: ${e.toString()}';
    }
  }

  // إعادة تعيين كلمة المرور
  Future<String?> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'user-not-found') {
        return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
      }
      return e.message ?? 'حدث خطأ أثناء إرسال رابط إعادة التعيين';
    } catch (e) {
      _setLoading(false);
      return 'حدث خطأ غير معروف';
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
