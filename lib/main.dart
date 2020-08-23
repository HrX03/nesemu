import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nesemu/emulator.dart';
import 'package:nesemu/gamepad/gamepad.dart';
import 'package:nesemu/ppu/ppu.dart';

final NESEmulator emulator = NESEmulator();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool running = false;
  final focusNode = FocusNode();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      NESPainterController().addListener(() {
        setState(() {});
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(
        "needRepaint: ${NESPainterController().needRepaint}, screen: ${NESPainterController().screen}");
    FocusScope.of(context).requestFocus(focusNode);
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (value) {
        emulator.cpu.gamepad.keyChanged(
          value.isKeyPressed(value.logicalKey),
          normalizeKeyDebugName(value.logicalKey.debugName),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Text(
              emulator.frame_rendered.toString(),
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
              ),
            ),
            CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.width / 1.0666,
              ),
              painter: NESPainter(),
            ),
            Visibility(
              visible: Platform.isAndroid || Platform.isIOS,
              child: Container(
                color: Colors.black,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).size.width / 1.0666,
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).size.width / 1.0666,
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Spacer(),
                                GameButton(
                                  buttonKey: GamePad.up_key,
                                  size: Size(40, 80),
                                ),
                                Spacer(),
                              ],
                            ),
                            Row(
                              children: [
                                GameButton(
                                  buttonKey: GamePad.left_key,
                                  size: Size(80, 40),
                                ),
                                Spacer(),
                                GameButton(
                                  buttonKey: GamePad.right_key,
                                  size: Size(80, 40),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Spacer(),
                                GameButton(
                                  buttonKey: GamePad.down_key,
                                  size: Size(40, 80),
                                ),
                                Spacer(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Column(
                          children: [
                            Spacer(),
                            Row(
                              children: [
                                GameButton(
                                  buttonKey: GamePad.a_key,
                                  size: Size(60, 60),
                                ),
                                Spacer(),
                                GameButton(
                                  buttonKey: GamePad.b_key,
                                  size: Size(60, 60),
                                ),
                              ],
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            Spacer(flex: 2),
                            GameButton(
                              buttonKey: GamePad.start_key,
                              size: Size(60, 20),
                            ),
                            Spacer(),
                            GameButton(
                              buttonKey: GamePad.select_key,
                              size: Size(60, 20),
                            ),
                            Spacer(flex: 2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: !running
            ? FloatingActionButton.extended(
                onPressed: () async {
                  File file = await FilePicker.getFile();
                  emulator.loadRom(await file.readAsBytes());
                  emulator.run();
                  setState(() => running = true);
                },
                icon: Icon(Icons.file_download),
                label: Text("LOAD ROM"),
                isExtended: true,
              )
            : null,
      ),
    );
  }

  int normalizeKeyDebugName(String debugName) {
    switch (debugName.toLowerCase()) {
      case "arrow right":
        return GamePad.right_key;
      case "arrow left":
        return GamePad.left_key;
      case "arrow up":
        return GamePad.up_key;
      case "arrow down":
        return GamePad.down_key;
      case "key a":
        return GamePad.a_key;
      case "key s":
        return GamePad.b_key;
      case "key q":
        return GamePad.start_key;
      case "key w":
        return GamePad.select_key;
    }
  }
}

class NESPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 256);
    print("paint");
    /*for (int i = 0; i < NESPainterController().points.length; i++) {
      Color color = NESPainterController().points.keys.toList()[i];
      List<Offset> points = NESPainterController().points[color];

      canvas.drawPoints(
        ui.PointMode.points,
        points,
        Paint()
          ..color = color
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.square,
      );

      NESPainterController().points[color].clear();
    }*/

    canvas.drawImageRect(
      NESPainterController().screen,
      Rect.fromLTWH(0, 0, 256, 240),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class NESPainterController extends ChangeNotifier {
  static NESPainterController _instance = new NESPainterController._();
  bool _needRepaint = false;
  Map<Color, List<Offset>> _points = {};
  ui.Image _screen;

  bool get needRepaint => _needRepaint;
  Map<Color, List<Offset>> get points => _points;
  ui.Image get screen => _screen;

  set needRepaint(bool value) {
    _needRepaint = value;
    notifyListeners();
  }

  set screen(ui.Image value) {
    _screen = value;
    notifyListeners();
  }

  factory NESPainterController() {
    return _instance;
  }

  static Map<Color, List<Offset>> _loadInitialMap() {
    Map<Color, List<Offset>> map = {};

    for (int i = 0; i < nes_palette.length; i++) {
      map.addAll({nes_palette[i]: []});
    }

    return map;
  }

  void update() => notifyListeners();

  NESPainterController._();
}

class GameButton extends StatelessWidget {
  final int buttonKey;
  final Size size;

  GameButton({
    @required this.buttonKey,
    @required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        emulator.gamepad.keyChanged(true, buttonKey);
      },
      onTapUp: (details) {
        emulator.gamepad.keyChanged(false, buttonKey);
      },
      child: Container(
        color: Colors.red.withOpacity(
          emulator.gamepad.isPressed(buttonKey) ? 1 : 0.4,
        ),
        width: size.width,
        height: size.height,
      ),
    );
  }
}
