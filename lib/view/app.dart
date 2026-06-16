import 'package:flutter/material.dart';

import 'home/home_page.dart';

class ReadIt extends StatelessWidget {
  const ReadIt({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
