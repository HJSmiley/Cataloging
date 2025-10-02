import 'package:flutter/material.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: const MainScreen(),
    );
  }
}

// 메인 스크린 - 페이지 전환 관리
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CatalogListPage(),
    const CatalogExplorePage(),
    const AddPage(),
    const MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF46BADA),
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '탐색'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: '추가'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}

// 1. 전체 카탈로그 페이지
class CatalogListPage extends StatelessWidget {
  const CatalogListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      height: 956,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          Positioned(
            left: 25,
            top: 148,
            child: Container(
              width: 390,
              height: 720,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 30,
                children: [
                  _buildCatalogItem(const Color(0xFFF5F5F5), const Color(0xFF46BADA)),
                  _buildCatalogItem(const Color(0xFFD9D9D9), const Color(0xFF3B4B18)),
                  _buildCatalogItem(const Color(0xFFD9D9D9), const Color(0xFF3B4B18)),
                  _buildCatalogItem(const Color(0xFFD9D9D9), const Color(0xFF3B4B18)),
                  _buildCatalogItem(const Color(0xFFD9D9D9), const Color(0xFF3B4B18)),
                  _buildCatalogItem(const Color(0xFFD9D9D9), const Color(0xFF3B4B18)),
                ],
              ),
            ),
          ),
          _buildTopBar(title: '전체 카탈로그'),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildCatalogItem(Color bgColor, Color accentColor) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: ShapeDecoration(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: ShapeDecoration(
                color: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  const Text(
                    '25FW 트렌드 스니커즈',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    '18/20 아이템',
                    style: TextStyle(
                      color: Color(0xFF323232),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  // Progress bar placeholder
                  Container(
                    height: 12,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. 카탈로그 탐색 페이지
class CatalogExplorePage extends StatelessWidget {
  const CatalogExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      height: 956,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          // Background
          Positioned(
            left: 0,
            top: 118,
            child: Container(
              width: 440,
              height: 753,
              decoration: const BoxDecoration(color: Color(0x2646BADA)),
            ),
          ),
          // Search Bar
          Positioned(
            left: 24,
            top: 138,
            child: _buildSearchBar(),
          ),
          // Filter Tabs
          Positioned(
            left: 24,
            top: 214,
            child: Row(
              spacing: 13,
              children: [
                _buildFilterChip('인기 카탈로그', isSelected: true),
                _buildFilterChip('신규 카탈로그', isSelected: false),
              ],
            ),
          ),
          // Popular Catalog Item
          Positioned(
            left: 25,
            top: 274,
            child: _buildPopularCatalogItem(),
          ),
          _buildTopBar(title: '카탈로그 탐색'),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 392,
      height: 56,
      decoration: ShapeDecoration(
        color: const Color(0x2646BADA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.search, color: Color(0xFF49454F)),
          ),
          const Expanded(
            child: Text(
              '검색어를 입력하세요 (ex. TCG, 신발, … )',
              style: TextStyle(
                color: Color(0xFF49454F),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      width: 130,
      height: 40,
      decoration: ShapeDecoration(
        color: isSelected ? const Color(0xFF46BADA) : const Color(0xFFFDFEFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPopularCatalogItem() {
    return Container(
      width: 390,
      height: 120,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: ShapeDecoration(
              color: const Color(0xFF46BADA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '인기 카탈로그',
                  style: TextStyle(
                    color: Color(0xFF46BADA),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '25FW 트렌드 스니커즈',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '이번 시즌 HOT 데일리 스타일 확인!',
                  style: TextStyle(
                    color: Color(0xFF49454F),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '20',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '아이템',
                style: TextStyle(
                  color: Color(0xFF49454F),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 3. 추가 페이지 (플레이스홀더)
class AddPage extends StatelessWidget {
  const AddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text('추가 페이지', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

// 4. 마이페이지
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      height: 956,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          _buildTopBar(title: '마이페이지'),
          _buildStatusBar(),
        ],
      ),
    );
  }
}

// 공통 위젯들
Widget _buildTopBar({required String title}) {
  return Positioned(
    left: 0,
    top: 62,
    child: Container(
      width: 440,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 56, height: 56),
          SizedBox(
            width: 288,
            height: 56,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            child: const Icon(Icons.notifications_none),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatusBar() {
  return Positioned(
    left: 0,
    top: 0,
    child: Container(
      width: 440,
      padding: const EdgeInsets.only(top: 21, left: 16, right: 16, bottom: 19),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '9:41',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            spacing: 7,
            children: [
              Container(
                width: 25,
                height: 13,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(4.30),
                  ),
                ),
              ),
              Container(
                width: 21,
                height: 9,
                decoration: ShapeDecoration(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.50),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}