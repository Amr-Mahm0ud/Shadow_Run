import 'package:flutter/material.dart';
import 'package:multi_media_game/logic/controller.dart';
import 'package:multi_media_game/logic/models/enemy.dart';
import 'package:multi_media_game/logic/models/hero.dart';

import 'home.dart';

class StartGame extends StatefulWidget {
  const StartGame({Key? key}) : super(key: key);

  @override
  State<StartGame> createState() => _GameState();
}

class _GameState extends State<StartGame> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> animation;
  int timer = 6000;
  bool gameOver = false;
  int runIndex = 0;
  HeroCharacter hero = HeroCharacter();
  Enemy enemy = Enemy();
  int score = 0;
  Color color = Colors.amber;
  Color secColor = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: timer));
    animation = Tween<Offset>(
      begin: const Offset(3.2, 3.15),
      //end game when x = 0.5 to -0.2
      end: const Offset(-3.5, 3.15),
    ).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!gameOver) controller.forward();
    final size = MediaQuery.of(context).size;
    if (animation.value.dx < 0.5 && animation.value.dx > -0.2) {
      if (enemy.status == 'run' && hero.status == 'run') {
        hero.die();
        if (hero.lives == 0) {
          gameOver = true;
          controller.stop();
        }
        Future.delayed(Duration(milliseconds: (timer / 8).floor()))
            .then((_) => hero.run());
      } else if (hero.status == 'attack' && enemy.status == 'run') {
        enemy.die(hero.status);
        score += 5;
      }
    }
    if (animation.value.dx < -1.5) {
      setState(() {
        enemy.run();
      });
      if (timer > 1500) {
        timer -= 200;
      }
      controller.stop();
      controller.duration = Duration(milliseconds: timer);
      controller.reset();
    }
    if (!gameOver) {
      Future.delayed(Duration(milliseconds: (timer / 20).floor())).then(
        (val) {
          if (runIndex < 3) {
            setState(() {
              runIndex++;
            });
          } else {
            setState(() {
              runIndex = 0;
            });
          }
        },
      );
    }

    if (!gameOver) {
      if (score > 0 && score % 50 == 0) {
        if (color == Colors.amber) {
          color = Colors.white.withOpacity(0.9);
          secColor = Colors.yellow;
        } else {
          color = Colors.amber;
          secColor = Colors.deepOrange;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          //sky
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: size.width,
              color: color,
              height: size.height * 0.8,
            ),
          ),
          //stars
          stars(10, 0.0, 0.0, context),
          stars(5, 0.5, 0.3, context),
          stars(20, -0.6, 0.2, context),
          stars(15, 0.35, -0.5, context),
          stars(30, -0.3, -0.5, context),
          stars(7, -1.0, -0.3, context),
          stars(12, 0.7, -0.2, context),
          stars(17, 1.0, -0.7, context),
          //road line
          Align(
            alignment: const Alignment(0, 0.65),
            child: SlideTransition(
              position: animation,
              child: Container(
                color: Colors.white54,
                width: size.width * 0.55,
                height: 10,
              ),
            ),
          ),
          //score
          Align(
            alignment: const Alignment(0.15, -0.8),
            child: Container(
              width: size.width * 0.2,
              color: Colors.transparent,
              child: Text(
                'Score: $score',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          //Lives
          Align(
            alignment: const Alignment(0.9, -0.9),
            child: SizedBox(
                width: size.width * 0.1,
                child: Row(
                  children: [
                    Icon(Icons.favorite,
                        color: hero.lives > 0 ? Colors.red : Colors.white),
                    Icon(Icons.favorite,
                        color: hero.lives > 1 ? Colors.red : Colors.white),
                    Icon(Icons.favorite,
                        color: hero.lives > 2 ? Colors.red : Colors.white),
                  ],
                )),
          ),
          //sun
          Align(
            alignment: const Alignment(-0.9, -0.9),
            child: Container(
              width: size.height * 0.25,
              height: size.height * 0.25,
              decoration: BoxDecoration(
                color: secColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          //hero
          Align(
            alignment: const Alignment(-0.9, 0.5),
            child: SizedBox(
              height: size.height * 0.25,
              child: Container(
                alignment: Alignment.bottomCenter,
                width: size.width * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(hero.status == 'run'
                          ? hero.runImages[runIndex]
                          : hero.status == 'attack'
                              ? hero.attackImage
                              : hero.dieImages[2])),
                ),
              ),
            ),
          ),
          //enemy
          SlideTransition(
            position: animation,
            child: SizedBox(
              height: size.height * 0.2,
              child: AnimatedOpacity(
                opacity: enemy.status == 'die' ? 0 : 1,
                duration: Duration(milliseconds: (timer / 20).floor()),
                child: Container(
                  alignment: Alignment.bottomCenter,
                  width: size.width * 0.3,
                  decoration: BoxDecoration(
                    image: DecorationImage(image: AssetImage(enemy.image)),
                  ),
                ),
              ),
            ),
          ),
          //attack
          Align(
            alignment: const Alignment(0.9, 0.35),
            child: ElevatedButton(
              child: Text(
                'attack',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size.height),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 45),
                primary: Colors.black54,
                elevation: 0,
              ),
              onPressed: () {
                if (hero.status != 'die') {
                  hero.attack();
                  Future.delayed(Duration(milliseconds: (timer / 8).floor()))
                      .then((val) {
                    hero.run();
                  });
                }
              },
            ),
          ),
          //Game Over
          if (gameOver)
            Container(
              width: size.width,
              height: size.height,
              color: Colors.black54,
              child: retryGame(size),
            )
        ],
      ),
    );
  }

  Align stars(size, x, y, ctx) {
    return Align(
      alignment: Alignment(x, y),
      child: SizedBox(
        width: MediaQuery.of(ctx).size.width * 0.3,
        child: Icon(
          Icons.star_sharp,
          size: size + 0.0,
        ),
      ),
    );
  }

  Widget retryGame(size) {
    return Center(
      child: Container(
        height: size.height * 0.6,
        width: size.width * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Game Over!',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .copyWith(color: Colors.black),
            ),
            const Divider(),
            Text(
              'Score: $score',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: const Text('Main Menu'),
                  onPressed: () {
                    HighScore().updateScore(score);
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const Home()));
                  },
                ),
                ElevatedButton(
                  child: const Text('Play again'),
                  onPressed: () {
                    HighScore().updateScore(score);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const StartGame()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
