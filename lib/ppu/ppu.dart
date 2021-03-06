library nes.ppu;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:nesemu/main.dart';
import 'package:image/image.dart' as img;

import '../cpu/cpu.dart';

part 'ppu_memory.dart';
part 'color_palette.dart';
part 'background.dart';
part 'sprites.dart';

enum MirroringType { Horizontal, Vertical, FourScreens, SingleScreen }

/// simulate a NES PPU
class PPU {
  /// Store the screen being rendered
  /// the screen is an NTSC screen : 256x240
  img.Image _screen;

  /// temporary canvas used for scaling

  /// Load the background
  final Background _background = new Background();

  /// load the sprites
  final Sprites _sprites = new Sprites();

  /// Store the PPU memory
  final PPUMemory memory = new PPUMemory();

  /// return the pattern table the background is stored in
  /// 0 : $0000; 1 : $1000
  /// located in control register 1 bit 4
  int get pattern_background_location => (memory.control_register >> 4) & 1;

  /// return the pattern table the sprites are stored in
  /// 0 : $0000; 1 : $1000
  /// located in control register 1 bit 3
  int get pattern_sprites_location => (memory.control_register >> 3) & 1;

  /// return if sprites should be displayed
  /// located in control register 2 bit 4
  bool get display_sprite => ((memory.mask_register >> 4) & 1) == 1;

  /// return if the background should be displayed
  /// located in control register 2 bit 3
  bool get display_background => ((memory.mask_register >> 3) & 1) == 1;

  /// See [PPUMemory.x_scroll]
  /// Add also scrolling based on control register bit 0
  int get x_delta => memory.x_scroll + (memory.nametable & 1) * 256;

  /// See [PPUMemory.y_scroll]
  /// Add also scrolling based on control register bit 1
  int get y_delta => memory.y_scroll + (memory.nametable & 2) * 120;

  /// if the sprites are 8x8 or 8x16
  /// located in control register 1 bit 5
  bool get has8x16Sprites => ((memory.control_register >> 5) & 1) == 1;

  /// set the sprite 0 hit flag
  /// located in bit 6 status register
  set sprite0_hit_flag(bool flag) => flag
      ? memory.status_register |= (1 << 6)
      : memory.status_register &= ~(1 << 6);

  /// set the overflow flag
  /// located in bit 5 status register
  set overflow_flag(bool flag) => flag
      ? memory.status_register |= (1 << 5)
      : memory.status_register &= ~(1 << 5);

  /// set the V-blank flag
  /// located in bit 7 status register
  set v_blank_flag(bool flag) => flag
      ? memory.status_register |= (1 << 7)
      : memory.status_register &= ~(1 << 7);

  /// return the CPU related to this PPU
  CPU get cpu => _cpu;
  CPU _cpu;

  void init(CPU cpu) {
    _background._ppu = this;
    _sprites._ppu = this;
    _screen = img.Image.rgb(256, 240);
    this._cpu = cpu;
    _screen.fill(Colors.white.value);
  }

  // starts the first tick at scanline 0
  int _curr_scanline = 0;
  // already 30 PPU cycles occured
  int _cycles_left = 311;

  /// make one CPU tick
  void tick() async {
    if (_cycles_left <= 0) {
      // notify the (potential) mapper
      cpu.mapper.count_scanline();

      // start a new scanline
      _curr_scanline++;
      if (_curr_scanline == 262) _curr_scanline = 0;

      _cycles_left += 341;

      if (_curr_scanline == 0) {
        // start a new frame

        // first update scrolling
        if (display_background) memory.transfer_temp_addr();

        _background._result.fillRange(
            0, _background._result.length, display_background ? 255 : 0);
        if (display_sprite) {
          _sprites._render();
        } else {
          _sprites._result.fillRange(0, _sprites._result.length, 0);
          _sprites._nb_sprites.fillRange(0, _sprites._nb_sprites.length, 0);
          _sprites._sprite0_opaque_pixels
              .fillRange(0, _sprites._sprite0_opaque_pixels.length, false);
        }
      }

      if (_curr_scanline >= 240) {
        // non-rendered line

        if (_curr_scanline == 240) {
          // the frame is totally rendered, now show it
          Uint8List png = img.encodePng(_screen);
          ui.Codec codec = await ui.instantiateImageCodec(png);
          ui.Image image = (await codec.getNextFrame()).image;

          NESPainterController().screen = image;
          //NESPainterController().update();
        }

        // flag update is done during the first tick and not the second
        // hopefully this doesn't have an effect
        if (_curr_scanline == 241) {
          v_blank_flag = true;
          // causes an NMI
          _cpu.interrupt(InterruptType.NMI);
        } else if (_curr_scanline == 261) {
          v_blank_flag = false;
          overflow_flag = false;
          sprite0_hit_flag = false;
        }
      } else {
        _render_line();
      }
    }

    // there are 3 ppu cycles per cpu cycle
    _cycles_left -= 3;
  }

  /// render the current line
  void _render_line() {
    // first update the scrolling if rendering is enabled
    if (display_background) {
      memory._update_horizontal_scrolling();
    }

    List<Color> palette = _read_palette(memory);
    if (_sprites._nb_sprites[_curr_scanline] > 8) {
      overflow_flag = true;
    }
    int curr_y = y_delta % 480;

    int first_x = x_delta % 512;

    for (int x = 0; x < 256; x++) {
      int curr_x = (x + first_x) % 512;

      if (_background._result[curr_y * 256 * 2 + curr_x] == 255) {
        // we need to render the background here
        _background._render_tile_line(first_x, curr_y);
      }

      int color_rendered = _background._result[curr_y * 256 * 2 + curr_x];
      if ((color_rendered & 3) == 0) color_rendered = 0;

      // check sprite 0 collision
      // 0 is the transparent color
      if (color_rendered != 0 &&
          _sprites._sprite0_opaque_pixels[_curr_scanline * 256 + x]) {
        sprite0_hit_flag = true;
      }

      if ((_sprites._result[_curr_scanline * 256 + x] & 3) != 0 &&
          (color_rendered == 0 ||
              _sprites._has_priority[_curr_scanline * 256 + x])) {
        // the color rendered is the one of the sprite
        color_rendered = _sprites._result[_curr_scanline * 256 + x];
      }
      _screen.setPixelRgba(
        x,
        _curr_scanline,
        palette[color_rendered].red,
        palette[color_rendered].green,
        palette[color_rendered].blue,
      );
      /*Color color = Color.fromRGBO(
        palette[color_rendered].red,
        palette[color_rendered].green,
        palette[color_rendered].blue,
        1,
      );
      if (NESPainterController().points[color] == null) {
        NESPainterController().points[color] = [];
      }
      NESPainterController()
          .points[color]
          .add(Offset(x.toDouble(), _curr_scanline.toDouble()));*/
    }
    memory.y_scroll++;
    memory.y_scroll %= 480;
  }
}
