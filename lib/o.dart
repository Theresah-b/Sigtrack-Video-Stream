import 'package:flutter/material.dart';

void main() {
  runApp(LAYOUTS());
}

class LAYOUTS extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('THERESAH LAYOUTS EXAMPLES')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row of boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBox('APPLE', Colors.greenAccent),
                  _buildBox('BANANA', Colors.purpleAccent),
                  _buildBox('CABBAGE', Colors.black87),
                  _buildBox('DONKEY', Colors.red),
                ],
              ),
              const SizedBox(height: 60),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBox('APPLE', Colors.greenAccent),
                  _buildBox('BANANA', Colors.purpleAccent),
                  _buildBox('CABBAGE', Colors.black87),
                  _buildBox('DONKEY', Colors.red),
                ],
              ),
              const SizedBox(height: 60 ),
              const SizedBox(width: 50000),

              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.greenAccent,
                    width: 100,
                    height: 100,
                    child: const Center(child: Text('APPLE')),
                  ),
                  Container(
                    color: Colors.purpleAccent,
                    width: 80,
                    height: 80,
                    child: const Center(child: Text('BANANA')),
                  ),
                  Container(
                    color: Colors.black87,
                    width: 60,
                    height: 60,
                    child: const Center(child: Text('CABBAGE')),
                  ),
                  Container(
                    color: Colors.red,
                    width: 40,
                    height: 40,
                    child: const Center(child: Text('DONKEY')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox(String text, Color color) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(5.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
