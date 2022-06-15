import 'package:flutter/material.dart';
import 'package:multi_media_game/design/start_game.dart';

import 'high_scores.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: size.height,
              color: Colors.amber,
            ),
          ),
          Center(
            child: Container(
              height: size.height * 0.6,
              width: size.width * 0.5,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Avengers Game',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(color: Colors.white),
                  ),
                  const Divider(),
                  ElevatedButton(
                    child: const Text('Start Game'),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const StartGame()));
                    },
                  ),
                  ElevatedButton(
                    child: const Text('High Scores'),
                    onPressed: () async {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const HighScores()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
