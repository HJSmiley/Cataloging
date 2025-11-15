import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';

/**
 * REST API 기반 OAuth2 로그인 화면
 * - WebView로 OAuth2 인증 화면 표시
 * - Callback URL 감지하여 Authorization Code 추출
 * - Backend에 Code 전달하여 JWT 받기
 */
class OAuth2Screen extends StatefulWidget {
  final String provider; // 'google' 또는 'naver'
  final String authUrl; // OAuth2 인증 URL
  final String state; // CSRF 방지용 state

  const OAuth2Screen({
    super.key,
    required this.provider,
    required this.authUrl,
    required this.state,
  });

  @override
  State<OAuth2Screen> createState() => _OAuth2ScreenState();
}

class _OAuth2ScreenState extends State<OAuth2Screen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        // Google OAuth2를 위한 User-Agent 설정
        // WebView임을 숨기고 일반 브라우저처럼 보이게 함
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('OAuth2 페이지 로딩 시작: $url');
            _checkCallbackUrl(url);
          },
          onPageFinished: (String url) {
            print('OAuth2 페이지 로딩 완료: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('OAuth2 WebView 에러: ${error.description}');
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  /**
   * Callback URL 감지 및 데이터 추출
   */
  void _checkCallbackUrl(String url) {
    // Backend 콜백 URL 패턴 확인
    final callbackPattern = '/api/auth/oauth2/${widget.provider}/callback';

    if (url.contains(callbackPattern)) {
      print('OAuth2 콜백 감지: $url');

      // 로딩 상태 유지 (빈 페이지 보이지 않도록)
      setState(() {
        _isLoading = true;
      });

      // HTML 페이지가 로드되면 JavaScript에서 데이터 추출
      _extractLoginDataFromPage();
    }
  }

  /**
   * HTML 페이지에서 로그인 데이터 추출
   */
  Future<void> _extractLoginDataFromPage() async {
    try {
      // 페이지 로딩 대기 (최소화)
      await Future.delayed(const Duration(milliseconds: 200));

      // JavaScript를 실행하여 window.loginData 가져오기
      // null 체크를 JavaScript 내에서 수행
      final result = await _controller.runJavaScriptReturningResult(
          'window.loginData ? JSON.stringify(window.loginData) : "null"');

      print('JavaScript 실행 결과: $result');

      if (result != null &&
          result.toString() != 'null' &&
          result.toString() != '"null"') {
        print('로그인 데이터 추출 성공');

        // JSON 파싱
        String jsonString = result.toString();

        // 1단계: 앞뒤 따옴표 제거
        if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
          jsonString = jsonString.substring(1, jsonString.length - 1);
        }

        // 2단계: 이스케이프된 따옴표 복원 (\" → ")
        jsonString = jsonString.replaceAll(r'\"', '"');

        // 3단계: 이스케이프된 백슬래시 복원 (\\n → \n 등)
        jsonString = jsonString.replaceAll(r'\\', r'\');

        final loginData = jsonDecode(jsonString);

        // JWT 토큰 저장
        final authController = Get.find<AuthController>();
        await authController.saveLoginData(
          loginData['accessToken'],
          loginData['user'],
        );

        // 홈 화면으로 이동
        Get.offAll(() => const HomeScreen());
      } else {
        // 재시도 로직
        _retryCount++;
        if (_retryCount < _maxRetries) {
          print('로그인 데이터가 없습니다. ${_retryCount}/$_maxRetries 재시도...');
          await Future.delayed(const Duration(milliseconds: 500));
          _extractLoginDataFromPage();
        } else {
          print('최대 재시도 횟수 초과');
          Get.snackbar(
            '로그인 실패',
            '로그인 처리 중 오류가 발생했습니다.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          Get.back();
        }
      }
    } catch (e) {
      print('로그인 데이터 추출 실패: $e');

      // 재시도
      _retryCount++;
      if (_retryCount < _maxRetries) {
        print('오류 발생, ${_retryCount}/$_maxRetries 재시도...');
        await Future.delayed(const Duration(milliseconds: 500));
        _extractLoginDataFromPage();
      } else {
        print('최대 재시도 횟수 초과');
        Get.snackbar(
          '로그인 실패',
          '로그인 처리 중 오류가 발생했습니다: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.provider.toUpperCase()} 로그인'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '로그인 중 오류가 발생했습니다',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('돌아가기'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('로그인 중...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
