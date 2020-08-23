library nes.gamepad;

/// Allow to access to the player gamepad
class GamePad {
  static int a_key = 65;
  static int b_key = 90;
  static int start_key = 83;
  static int select_key = 81;
  static int up_key = 38;
  static int down_key = 40;
  static int left_key = 37;
  static int right_key = 39;

  bool a_pressed = false;
  bool b_pressed = false;
  bool start_pressed = false;
  bool select_pressed = false;
  bool up_pressed = false;
  bool down_pressed = false;
  bool left_pressed = false;
  bool right_pressed = false;

  void keyChanged(bool flag, int keyCode) {
    int key = keyCode;
    if (key == a_key)
      a_pressed = flag;
    else if (key == b_key)
      b_pressed = flag;
    else if (key == select_key)
      select_pressed = flag;
    else if (key == start_key)
      start_pressed = flag;
    else if (key == select_key)
      select_pressed = flag;
    else if (key == up_key)
      up_pressed = flag;
    else if (key == down_key)
      down_pressed = flag;
    else if (key == left_key)
      left_pressed = flag;
    else if (key == right_key) right_pressed = flag;
    return;
  }

  /// id correspond to the order the key states are given to the nes
  bool isPressed(int id) {
    switch (id) {
      case 0:
        return a_pressed;
      case 1:
        return b_pressed;
      case 2:
        return select_pressed;
      case 3:
        return start_pressed;
      case 4:
        return up_pressed;
      case 5:
        return down_pressed;
      case 6:
        return left_pressed;
      case 7:
        return right_pressed;
      default:
        return false;
    }
  }
}
