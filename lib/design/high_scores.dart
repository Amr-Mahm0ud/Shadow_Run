import 'package:flutter/material.dart';

import '../logic/controller.dart';

class HighScores extends StatelessWidget {
  const HighScores({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final res = HighScore().readScores();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('High Scores'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'First: ' + res[0].toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Second: ' + res[1].toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Third: ' + res[2].toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
