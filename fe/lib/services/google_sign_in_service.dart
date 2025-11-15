import 'package:google_sign_in/google_sign_in.dart';

/**
 * Google Sign-In 서비스
 * - 네이티브 Google Sign-In SDK 사용
 * - WebView 차단 문제 해결
 * - 백엔드 토큰 로그인 API와 연동
 */
class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // iOS/Android: Info.plist/google-services.json에서 자동 설정
    // clientId를 지정하지 않으면 플랫폼별 설정 파일에서 자동으로 읽음
    scopes: [
      'email',
      'profile',
    ],
  );

  /**
   * Google 로그인
   * @return GoogleSignInAccount 또는 null (로그인 실패/취소)
   */
  Future<GoogleSignInAccount?> signIn() async {
    try {
      print('Google Sign-In 시작...');

      // Google 로그인 화면 표시
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        print('Google 로그인 성공: ${account.email}');

        // 인증 정보 가져오기
        final GoogleSignInAuthentication auth = await account.authentication;
        print('Access Token: ${auth.accessToken?.substring(0, 20)}...');
        print('ID Token: ${auth.idToken?.substring(0, 20)}...');
      } else {
        print('Google 로그인 취소됨');
      }

      return account;
    } catch (error) {
      print('Google Sign-In 오류: $error');
      return null;
    }
  }

  /**
   * Google 로그아웃
   */
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('Google 로그아웃 완료');
    } catch (error) {
      print('Google 로그아웃 오류: $error');
    }
  }

  /**
   * 현재 로그인한 사용자
   */
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /**
   * 로그인 여부 확인
   */
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /**
   * 자동 로그인 시도 (이전에 로그인한 적이 있는 경우)
   */
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      print('Google 자동 로그인 시도...');
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        print('Google 자동 로그인 성공: ${account.email}');
      }
      return account;
    } catch (error) {
      print('Google 자동 로그인 실패: $error');
      return null;
    }
  }
}
