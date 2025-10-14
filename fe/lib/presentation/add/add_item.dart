import 'package:flutter/material.dart';

class AddItemPage extends StatelessWidget {
  const AddItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 전체 화면 배경(Scaffold 배경색은 투명하게)
      color: const Color(0x2646BADA),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // 앱 바(기본 배경색 흰색, 스크롤 시 색/음영 고정)
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            // 뒤로가기
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.maybePop(context),
            tooltip: '뒤로',
          ),
          title: const Text(
            // 화면 제목
            '아이템 추가',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontFamily: 'Niramit',
              fontWeight: FontWeight.w600,
              height: 1.38,
            ),
          ),
          actions: [
            // 닫기(X 버튼)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.maybePop(context),
              tooltip: '닫기',
            ),
          ],
          bottom: const PreferredSize(
            // 하단 구분선
            preferredSize: Size.fromHeight(1),
            child: SizedBox(
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black12),
              ),
            ),
          ),
        ),
        body: const SafeArea(
          // AppBar가 상단 인셋 처리
          top: false,
          child: AddItemBody(),
        ),
      ),
    );
  }
}

class AddItemBody extends StatefulWidget {
  const AddItemBody({super.key});

  @override
  State<AddItemBody> createState() => _AddItemBodyState();
}

class _AddItemBodyState extends State<AddItemBody> {
  // 폼 상태 및 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 반응형 폭(좌측 기준선은 ListView padding으로 통일)
    final w = MediaQuery.of(context).size.width;
    final contentW = (w * 0.94).clamp(300.0, 560.0);
    final sidePad = (w - contentW) / 2;

    // 공통 입력 데코레이터(컨테이너 스타일 재현)
    InputDecoration deco(String hint, {EdgeInsets? pad}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF717680),
        fontSize: 16,
        height: 1.5,
        fontFamily: 'Inter',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          pad ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD5D6D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD5D6D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFF46BADA)),
      ),
    );

    return ListView(
      // 좌우 패딩 한 곳에서 관리(정렬 기준선)
      padding: EdgeInsets.symmetric(horizontal: sidePad),
      children: [
        const SizedBox(height: 12),

        // 프로그레스 바(진행률 표시)
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: const LinearProgressIndicator(
              value: 0.6,
              minHeight: 12,
              backgroundColor: Color(0xFFEEEEEE),
              color: Color(0xFF46BADA),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 타이틀/부제
        SizedBox(
          width: contentW,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '아이템 설명 추가',
                style: TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 32,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w700,
                  height: 1.60,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '어떤 아이템인지 설명해 주세요.',
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 18,
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                  letterSpacing: 0.20,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 사진 미리보기
        Container(
          width: contentW,
          height: (contentW / 382) * 200,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: ShapeDecoration(
            image: const DecorationImage(
              image: NetworkImage('https://placehold.co/600x315.png'),
              fit: BoxFit.cover,
            ),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 3, color: Color(0xFFC2F9FF)),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 사진 추가 버튼(아이콘+텍스트)
        SizedBox(
          width: contentW,
          height: 58,
          child: TextButton.icon(
            onPressed: () {
              // TODO: 사진 선택/촬영
            },
            icon: const Icon(Icons.camera_alt, size: 20),
            label: const Text('사진 추가', overflow: TextOverflow.ellipsis),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF46BADA),
              backgroundColor: const Color(0x2646BADA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              minimumSize: const Size.fromHeight(58),
              textStyle: const TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 입력 폼(이름/설명)
        Form(
          key: _formKey,
          child: SizedBox(
            width: contentW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이름*',
                  style: TextStyle(
                    color: Color(0xFF414651),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _name,
                  decoration: deco('아이템 이름'),
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'Inter',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '이름을 입력해 주세요' : null,
                ),

                const SizedBox(height: 16),

                const Text(
                  '설명*',
                  style: TextStyle(
                    color: Color(0xFF414651),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _desc,
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: 6,
                  textAlignVertical: const TextAlignVertical(y: -1),
                  decoration: deco(
                    '아이템 설명',
                    pad: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'Inter',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '설명을 입력해 주세요' : null,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 계속(제출 버튼)
        SizedBox(
          width: contentW,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                // TODO: 제출 처리
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF46BADA),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(width: 1, color: Color(0xFF46BADA)),
              ),
              minimumSize: Size(contentW, 48),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            child: const Text('계속'),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
