import 'package:flutter/material.dart';
import 'package:sample/pages/todo_page.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  TextStyle ts1 = const TextStyle(color: Colors.blue,fontSize: 30);
  String helloText = "안녕";
  double imgSize = 80;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(helloText, style: const TextStyle(fontSize: 30),),

            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TodoPage()),
                );
              },
              child: const Text('페이지 이동'),
            ),

            SaveUserButton(
              buttonText: "글자 변경",
              textColor: Colors.black54,
              onClick: (){
                // print(helloText);
                // helloText = "Hello";
                // setState(() {});
                setState(() {
                  helloText = "Hello";
                  imgSize = 200;
                });
              },
            ),

            SaveUserButton(
              buttonText: "Google 로그인",
              onClick: (){
                print("클릭2");
              },
            ),

            Image.network(
              width: imgSize,
              "https://yt3.googleusercontent.com/ytc/AIdro_nqx_sCd8ZIeIcodS0sfeMKJ8rVTslmQHUe_udwGNH2Pg=s900-c-k-c0x00ffffff-no-rj"
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: Text('안녕하세요',style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
            ),

            const Text('안녕하세요'),
            const SizedBox(height: 50,),
            const Text('안녕하세요'),
            const Text('안녕하세요'),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('로우1',style: ts1,),
                const SizedBox(width: 30,),
                Text('로우2',style: ts1,),
                Text('로우3',style: ts1,),
                Text('로우4',style: ts1,),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SaveUserButton extends StatelessWidget {
  String buttonText;
  Color textColor;
  Function onClick;

  // const SaveUserButton({super.key});
  SaveUserButton({super.key, 
    required this.buttonText,
    this.textColor=Colors.blue,
    required this.onClick
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: (){
          onClick();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white60,
        ),
        child: Text(buttonText, style: TextStyle(fontSize: 26, color: textColor),)
    );
  }
}