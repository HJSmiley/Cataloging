import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../controllers/auth_controller.dart';
import '../services/platform_config.dart';
import 'home_screen.dart';

// 플랫폼별 import (웹이 아닐 때만)
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// 조건부 import: 웹이 아닐 때만 dart:io 사용
import 'dart:io' if (dart.library.html) 'dart:html' as platform;

class OAuthWebViewScreen extends StatefulWidget {
  final String provider;

  const OAuthWebViewScreen({super.key, required this.provider});

  @override
  State<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends State<OAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final authUrl =
        '${PlatformConfig.userApiUrl}/oauth2/authorization/${widget.provider}';

    debugPrint('OAuth2 로그인 URL: $authUrl');

    // 플랫폼별 WebView 파라미터 설정
    late final PlatformWebViewControllerCreationParams params;

    if (kIsWeb) {
      // 웹 환경
      params = const PlatformWebViewControllerCreationParams();
    } else {
      // 모바일 환경
      if (platform.Platform.isAndroid) {
        params = AndroidWebViewControllerCreationParams();
      } else if (platform.Platform.isIOS) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    // iOS WebView 추가 설정
    if (!kIsWeb && platform.Platform.isIOS) {
      final webKitController = controller.platform as WebKitWebViewController;
      webKitController.setAllowsBackForwardNavigationGestures(true);
    }

    _controller = controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 데스크톱 User-Agent 설정 (네이버 인앱 브라우저 제한 우회)
      ..setUserAgent(
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('페이지 로딩 시작: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });

            // 네이버 인앱 브라우저 차단 감지
            if (url.contains('nid.naver.com/login/ext/error.inapp')) {
              debugPrint('네이버 인앱 브라우저 차단 감지');
              if (mounted) {
                Get.back();
                Get.snackbar(
                  '로그인 제한',
                  'iOS에서는 네이버 로그인이 제한됩니다. Google 로그인을 이용해주세요.',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 4),
                );
              }
              return;
            }

            // OAuth2 성공 후 JSON 응답 확인
            if (url.contains('/api/auth/oauth2/') &&
                url.contains('/callback')) {
              try {
                // 약간의 지연 후 페이지 내용 추출 (렌더링 대기)
                await Future.delayed(const Duration(milliseconds: 800));

                // WebView에서 loginData 추출 시도
                final content = await _controller.runJavaScriptReturningResult(
                    'document.getElementById("loginData") ? document.getElementById("loginData").innerText : null');

                debugPrint('OAuth2 응답 원본: $content');

                // 따옴표 제거
                String jsonString = content.toString();
                if (jsonString == 'null' || jsonString.isEmpty) {
                  debugPrint('로그인 데이터를 찾을 수 없습니다.');
                  return;
                }

                if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
                  jsonString = jsonString.substring(1, jsonString.length - 1);
                }

                // 이스케이프 문자 처리
                jsonString = jsonString
                    .replaceAll(r'\"', '"')
                    .replaceAll(r'\n', '')
                    .replaceAll(r'\r', '');

                debugPrint('파싱할 JSON: $jsonString');

                final responseData = json.decode(jsonString);
                debugPrint('파싱된 데이터: $responseData');

                // 로그인 성공 처리
                if (responseData['accessToken'] != null &&
                    responseData['user'] != null) {
                  final authController = Get.find<AuthController>();
                  final success = await authController.handleOAuth2Callback(
                    responseData['accessToken'],
                    responseData['user'],
                  );

                  if (success && mounted) {
                    Get.offAll(() => const HomeScreen());
                    Get.snackbar(
                      '로그인 성공',
                      '환영합니다!',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  }
                } else {
                  if (mounted) {
                    Get.back();
                    Get.snackbar(
                      '로그인 실패',
                      '로그인 데이터가 올바르지 않습니다.',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              } catch (e) {
                debugPrint('OAuth2 응답 파싱 오류: $e');
                if (mounted) {
                  Get.back();
                  Get.snackbar(
                    '로그인 오류',
                    '로그인 처리 중 오류가 발생했습니다: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 5),
                  );
                }
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView 오류: ${error.description}');
            debugPrint('오류 타입: ${error.errorType}');
            debugPrint('오류 코드: ${error.errorCode}');

            if (mounted) {
              Get.snackbar(
                '연결 오류',
                'User API 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하세요.',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getProviderName()} 로그인'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
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
