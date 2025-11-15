import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'dart:convert';

/**
 * WebView 기반 OAuth2 로그인 화면 (개선 버전)
 * - 시스템 브라우저 User-Agent 사용
 * - 딥링크 대신 직접 콜백 처리
 */
class OAuth2BrowserScreen extends StatefulWidget {
  final String provider;
  final String authUrl;
  final String state;

  const OAuth2BrowserScreen({
    super.key,
    required this.provider,
    required this.authUrl,
    required this.state,
  });

  @override
  State<OAuth2BrowserScreen> createState() => _OAuth2BrowserScreenState();
}

class _OAuth2BrowserScreenState extends State<OAuth2BrowserScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        // 데스크톱 브라우저 User-Agent (Google 차단 우회 시도)
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('OAuth2 페이지 로딩 시작: $url');
            _checkCallbackUrl(url);
          },
          onPageFinished: (String url) async {
            print('OAuth2 페이지 로딩 완료: $url');
            setState(() {
              _isLoading = false;
            });

            // 콜백 URL인 경우 데이터 추출
            if (url.contains('/api/auth/oauth2/') &&
                url.contains('/callback')) {
              await _extractCallbackData(url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('OAuth2 WebView 에러: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  void _checkCallbackUrl(String url) {
    // 콜백 URL 패턴 확인
    if (url.contains('/api/auth/oauth2/') && url.contains('/callback')) {
      print('OAuth2 콜백 감지: $url');
    }
  }

  Future<void> _extractCallbackData(String url) async {
    try {
      // URL에서 code와 state 추출
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      if (code != null && state != null) {
        print('Code 추출 성공: $code');

        // State 검증
        if (state != widget.state) {
          throw Exception('State 검증 실패');
        }

        // 백엔드에 code 전달하여 JWT 토큰 받기
        final success = await _exchangeCodeForToken(code, state);

        if (success && mounted) {
          Get.offAll(() => const HomeScreen());
          Get.snackbar(
            '로그인 성공',
            '환영합니다!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('콜백 데이터 추출 실패: $e');
      if (mounted) {
        Get.back();
        Get.snackbar(
          '로그인 실패',
          e.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<bool> _exchangeCodeForToken(String code, String state) async {
    try {
      final authController = Get.find<AuthController>();

      // 백엔드 API 호출하여 code를 JWT로 교환
      final response = await authController.apiService.handleOAuthCallback(
        widget.provider,
        code,
        state,
      );

      // JWT 토큰 저장
      await authController.saveLoginData(
        response['accessToken'],
        response['user'],
      );

      return true;
    } catch (e) {
      print('토큰 교환 실패: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getProviderName()} 로그인'),
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('로그인 중...'),
                  SizedBox(height: 8),
                  Text(
                    '브라우저에서 로그인을 완료해주세요',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
            : const Text('로그인 처리 중...'),
      ),
    );
  }

  String _getProviderName() {
    switch (widget.provider.toLowerCase()) {
      case 'google':
        return 'Google';
      case 'naver':
        return 'Naver';
      default:
        return widget.provider;
    }
  }
}
