import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setPortrait();
  final shapeGame = GameTemplate();
  runApp(GameWidget(game: shapeGame));
}

class GameTemplate extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Ship shipPlayer;
  late List<Square> squareEnemies;
  int playerPoints = 100;
  int hitsReceived = 0;
  int remainingAttempts = 30;
  bool gameOver = false;
  Random random = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(HeaderTitle());
    add(shipPlayer = Ship(await loadSprite('triangle.png')));
    
    squareEnemies = List.generate(3, (index) => Square(
      await loadSprite('square.png'),
      speed: 100 + random.nextInt(150), // Velocidad aleatoria entre 100 y 250
    ));
    
    for (var square in squareEnemies) {
      add(square);
    }

    // Load and cache the audio
    await FlameAudio.audioCache.load('ball.wav');
    await FlameAudio.audioCache.load('explosion.wav');
  }

  void onPlayerHit() {
    if (gameOver) return;
    
    playerPoints -= 20;
    hitsReceived++;
    remainingAttempts--;
    
    if (hitsReceived > 5 || playerPoints <= 0 || remainingAttempts <= 0) {
      gameOver = true;
    }
  }

  void resetSquare(Square square) {
    if (gameOver) return;
    
    remainingAttempts--;
    square.resetPosition();
    square.speed = 100 + random.nextInt(150); // Nueva velocidad aleatoria
    
    if (remainingAttempts <= 0) {
      gameOver = true;
    }
  }
}

class Ship extends SpriteComponent
    with HasGameReference<GameTemplate>, CollisionCallbacks {
  final spriteVelocity = 500;
  double screenPosition = 0.0;
  bool leftPressed = false;
  bool rightPressed = false;
  bool upPressed = false;
  bool downPressed = false;
  bool isCollision = false;

  Ship(Sprite sprite) {
    debugMode = true;
    this.sprite = sprite;
    size = Vector2(50.0, 50.0);
    anchor = Anchor.center;
    position = Vector2(200.0, 300.0); // Posición inicial más abajo
    add(RectangleHitbox());
    add(KeyboardListenerComponent(
      keyDown: {
        LogicalKeyboardKey.keyA: (keysPressed) { return leftPressed = true; },
        LogicalKeyboardKey.keyD: (keysPressed) { return rightPressed = true; },
        LogicalKeyboardKey.keyW: (keysPressed) { return upPressed = true; },
        LogicalKeyboardKey.keyS: (keysPressed) { return downPressed = true; },
      },
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (leftPressed) {
      screenPosition = position.x - spriteVelocity * dt;
      if (screenPosition > 0 + width/2) {
        position.x = screenPosition;
        FlameAudio.play('ball.wav');
      }
      leftPressed = false;
    }
    if (rightPressed) {
      screenPosition = position.x + spriteVelocity * dt;
      if (screenPosition < game.size.x - width/2) {
        position.x = screenPosition;
        FlameAudio.play('ball.wav');
      }
      rightPressed = false;
    }
    if (upPressed) {
      screenPosition = position.y - spriteVelocity * dt;
      if (screenPosition > 0 + height/2) {
        position.y = screenPosition;
        FlameAudio.play('ball.wav');
      }
      upPressed = false;
    }
    if (downPressed) {
      screenPosition = position.y + spriteVelocity * dt;
      if (screenPosition < game.size.y - height/2) {
        position.y = screenPosition;
        FlameAudio.play('ball.wav');
      }
      downPressed = false;
    }
  }
}

class Square extends SpriteComponent
    with HasGameReference<GameTemplate>, CollisionCallbacks {
  double speed;
  double screenPosition = 0.0;
  bool isCollision = false;
  Random random = Random();

  Square(Sprite sprite, {required this.speed}) {
    debugMode = true;
    this.sprite = sprite;
    size = Vector2(50.0, 50.0);
    resetPosition();
    add(RectangleHitbox());
  }

  void resetPosition() {
    position = Vector2(
      random.nextDouble() * (game.size.x - 50), 
      0.0
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ship && !isCollision) {
      isCollision = true;
      (game as GameTemplate).onPlayerHit();
      resetPosition();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Fall down the screen
    screenPosition = position.y + speed * dt;
    if (screenPosition < game.size.y - height/2) {
      position.y = screenPosition;
    } else {
      (game as GameTemplate).resetSquare(this);
    }

    if (isCollision) {
      FlameAudio.play('explosion.wav');
      isCollision = false;
    }
  }
}

class HeaderTitle extends TextBoxComponent with HasGameReference<GameTemplate> {
  final double xHeaderPosition = 20.0;
  final double yHeaderPosition = 20.0;

  final textPaint = TextPaint(
      style: const TextStyle(
          color: Colors.white,
          fontSize: 22.0,
          fontFamily: 'Awesome Font'));

  HeaderTitle() {
    position = Vector2(xHeaderPosition, yHeaderPosition);
  }

  @override
  void render(Canvas canvas) {
    final gameTemplate = game as GameTemplate;
    
    if (gameTemplate.gameOver) {
      // Mostrar estadísticas finales
      textPaint.render(canvas, "¡JUEGO TERMINADO!", Vector2(xHeaderPosition, yHeaderPosition));
      textPaint.render(canvas, "Golpes recibidos: ${gameTemplate.hitsReceived}", 
          Vector2(xHeaderPosition, yHeaderPosition + 30));
      textPaint.render(canvas, "Puntos restantes: ${gameTemplate.playerPoints}", 
          Vector2(xHeaderPosition, yHeaderPosition + 60));
      
      String status;
      if (gameTemplate.playerPoints <= 0) {
        status = "Estado: ¡Destruido!";
      } else if (gameTemplate.hitsReceived > 5) {
        status = "Estado: ¡Demasiados golpes!";
      } else if (gameTemplate.remainingAttempts <= 0) {
        status = "Estado: ¡Enemigos sin intentos!";
      } else {
        status = "Estado: Desconocido";
      }
      
      textPaint.render(canvas, status, Vector2(xHeaderPosition, yHeaderPosition + 90));
    } else {
      // Mostrar información del juego en curso
      textPaint.render(canvas, "Puntos: ${gameTemplate.playerPoints}", 
          Vector2(xHeaderPosition, yHeaderPosition));
      textPaint.render(canvas, "Golpes: ${gameTemplate.hitsReceived}/5", 
          Vector2(xHeaderPosition, yHeaderPosition + 30));
      textPaint.render(canvas, "Intentos: ${gameTemplate.remainingAttempts}", 
          Vector2(xHeaderPosition, yHeaderPosition + 60));
    }
  }
}
