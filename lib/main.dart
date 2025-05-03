import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setPortrait();
  final shapeGame = GameTemplate();
  runApp(GameWidget(game: shapeGame));
}

class GameTemplate extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Ship shipPlayer;
  late Square squareEnemy;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(HeaderTitle());
    add(shipPlayer = Ship(await loadSprite('triangle.png')));
    add(squareEnemy = Square(await loadSprite('square.png')));

    // Load and cache the audio
    await FlameAudio.audioCache.load('ball.wav');
    await FlameAudio.audioCache.load('explosion.wav');
  }
}

// Add a ship to the game, using triangle.png
class Ship extends SpriteComponent
    with HasGameReference<GameTemplate>, CollisionCallbacks {

  final spriteVelocity  = 500;
  double screenPosition = 0.0;
  bool leftPressed      = false;
  bool rightPressed     = false;
  bool isCollision      = false;

  Ship(Sprite sprite) {
    debugMode = true;
    this.sprite = sprite;
    size = Vector2(50.0, 50.0);
    anchor = Anchor.center;
    position = Vector2(200.0, 200.0);
    add(RectangleHitbox());
    add(KeyboardListenerComponent(
      // keyUp: {
      // },
      keyDown: {
        LogicalKeyboardKey.keyA: (keysPressed) { return leftPressed  = true; },
        LogicalKeyboardKey.keyD: (keysPressed) { return rightPressed = true; },
      },
    ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (leftPressed == true){
      screenPosition = position.x - spriteVelocity * dt ;
      if (screenPosition > 0 + width/2){
        position.x = screenPosition;
        FlameAudio.play('ball.wav');
      }
      leftPressed = false;
    }
    if (rightPressed == true){
      screenPosition = position.x + spriteVelocity * dt;
      if (screenPosition < game.size.x - width/2) {
        position.x = screenPosition;
        FlameAudio.play('ball.wav');
      }
      rightPressed = false;
    }
  }
}


class Square extends SpriteComponent
    with HasGameReference<GameTemplate>, CollisionCallbacks {

  final spriteVelocity  = 100;
  double screenPosition = 0.0;
  bool isCollision      = false;

  Square(Sprite sprite) {
    debugMode = true;
    this.sprite = sprite;
    size = Vector2(50.0, 50.0);
    position = Vector2(100.0, 100.0);
    add(RectangleHitbox());
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    isCollision = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Fall down the screen
    screenPosition = position.y + spriteVelocity * dt ;
    if (screenPosition < game.size.y - height/2){
      position.y = screenPosition;
    } else {
      position.y = 0.0;
    }

    if (isCollision){
      //print('Collision!');
      FlameAudio.play('explosion.wav');
      isCollision = false;
    }
  }
}

class HeaderTitle extends TextBoxComponent {

  final double xHeaderPosition = 100.0;
  final double yHeaderPosition = 20.0;

  final textPaint = TextPaint(
      style: const TextStyle(
          color: Colors.white,
          fontSize: 22.0,
          fontFamily: 'Awesome Font'));

  HeaderTitle(){
    position = Vector2(xHeaderPosition, yHeaderPosition);
  }


  @override
  void render(Canvas canvas) {
    textPaint.render(canvas, "Super Square Attack", position);
  }
}

