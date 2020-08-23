part of nes.ppu;

/// return the palette for the background and sprites
List<Color> _read_palette(PPUMemory memory) {
  List<Color> res = new List<Color>(32);
  for (int i = 0; i < 32; i++) {
    res[i] = nes_palette[
        memory._data[0x3F00 + i] & 0x3F]; // image palette starts at 0x3F10
  }

  return res;
}

/// nes color palette from http://nesdev.com/nespal.txt
const List<Color> nes_palette = [
  Color(0xFF808080),
  Color(0xFF0000BB),
  Color(0xFF3700BF),
  Color(0xFF8400A6),
  Color(0xFFBB006A),
  Color(0xFFB7001E),
  Color(0xFFB30000),
  Color(0xFF912600),
  Color(0xFF7B2B00),
  Color(0xFF003E00),
  Color(0xFF00480D),
  Color(0xFF003C22),
  Color(0xFF002F66),
  Color(0xFF000000),
  Color(0xFF050505),
  Color(0xFF050505),
  Color(0xFFC8C8C8),
  Color(0xFF0059FF),
  Color(0xFF443CFF),
  Color(0xFFB733CC),
  Color(0xFFFF33AA),
  Color(0xFFFF375E),
  Color(0xFFFF371A),
  Color(0xFFD54B00),
  Color(0xFFC46200),
  Color(0xFF3C7B00),
  Color(0xFF1E8415),
  Color(0xFF009566),
  Color(0xFF0084C4),
  Color(0xFF111111),
  Color(0xFF090909),
  Color(0xFF090909),
  Color(0xFFFFFFFF),
  Color(0xFF0095FF),
  Color(0xFF6F84FF),
  Color(0xFFD56FFF),
  Color(0xFFFF77CC),
  Color(0xFFFF6F99),
  Color(0xFFFF7B59),
  Color(0xFFFF915F),
  Color(0xFFFFA233),
  Color(0xFFA6BF00),
  Color(0xFF51D96A),
  Color(0xFF4DD5AE),
  Color(0xFF00D9FF),
  Color(0xFF666666),
  Color(0xFF0D0D0D),
  Color(0xFF0D0D0D),
  Color(0xFFFFFFFF),
  Color(0xFF84BFFF),
  Color(0xFFBBBBFF),
  Color(0xFFD0BBFF),
  Color(0xFFFFBFEA),
  Color(0xFFFFBFCC),
  Color(0xFFFFC4B7),
  Color(0xFFFFCCAE),
  Color(0xFFFFD9A2),
  Color(0xFFCCE199),
  Color(0xFFAEEEB7),
  Color(0xFFAAF7EE),
  Color(0xFFB3EEFF),
  Color(0xFFDDDDDD),
  Color(0xFF111111),
  Color(0xFF111111),
];
