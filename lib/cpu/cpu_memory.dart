part of nes.cpu;

class CPUMemory {
  /// The NES processor has a 16-bit address bus
  Uint8List _data = new Uint8List(0x10000);

  /// Access to the cpu
  CPU get cpu => _cpu;
  CPU _cpu;

  /// Quick access to the ppu memory
  PPUMemory get ppu_memory => _cpu._ppu.memory;

  /// 8-bit address of the sprite index
  int _sprite_memory_addr = 0;

  /// current joypad button id to be read
  int _curr_button_id = 0;

  /// state of joypad reset
  bool _joypad_reset = false;

  /// get the increase of [_ppu_memory_addr] after each read/write
  int get _ppu_addr_increase =>
      ((ppu_memory.control_register >> 2) & 1) == 1 ? 32 : 1;

  /// ppu memory buffer
  int _ppu_memory_buffer = 0;

  /// load a 16-bit upper part of the PGR
  /// located at $C000-$FFFF
  void load_PGR_upper(Uint8List from, int start) {
    copy_memory(from, start, 1 << 14, 0xC000);
  }

  /// load the 16-bit lower part of the PGR
  /// located at $8000-$8FFF
  void load_PGR_lower(Uint8List from, int start) {
    copy_memory(from, start, 1 << 14, 0x8000);
  }

  /// load the 32-bit whole PGR
  /// located at $8000-$FFFF
  void load_PGR(Uint8List from, int start) {
    copy_memory(from, start, 1 << 15, 0x8000);
  }

  /// load a 512-byte trainer
  /// located at $7000-$71FF
  void load_trainer(Uint8List from, int start) {
    copy_memory(from, start, 512, 0x7000);
  }

  /// Used by mappers
  void copy_memory(Uint8List from, int start, int length, int to) {
    // Add some code to check validity ?
    for (int i = 0; i < length; i++) {
      _data[to + i] = from[start + i];
    }
  }

  /// get address through memory mirroring
  int _get_addr(int index) {
    if (index >= 0x2008 && index < 0x4000) {
      index = 0x2000 | (index & 0x7);
    } else if (index >= 0x0800 && index < 0x2000) {
      index &= 0x07FF;
    }
    return index;
  }

  int operator [](int index) {
    index = _get_addr(index);

    // If access is done in the PGR zone
    if (index >= 0x8000) {
      return _data[index];
    } else if (index >= 0x6000) {
      // SRAM access, may disable it if no sram inserted
      return _data[index];
    }

    // RAM access
    if (index < 0x2000) {
      return _data[index];
    }

    if ((index >= 0x4000 && index <= 0x4013) || index == 0x4015) {
      // sound, not implemented yet
      return _data[index];
    }

    switch (index) {
      case 0x2000:
        return ppu_memory.control_register;

      case 0x2001:
        return ppu_memory.mask_register;

      case 0x2002:
        int res = ppu_memory.status_register;
        // reading PPUSTATUS reset bit 7, PPUSCROLL and PPUADDRESS
        ppu_memory
          ..status_register &= ~(1 << 7)
          ..toggle_second_w = false;
        return res;

      case 0x2004:
        int res = ppu_memory.spr_ram[_sprite_memory_addr];
        return res;

      case 0x2007:
        int res = ppu_memory[ppu_memory.memory_addr];
        if ((ppu_memory.memory_addr & 0x3FFF) < 0x3F00) {
          // emulate buffered read when to reading palette
          int temp = _ppu_memory_buffer;
          _ppu_memory_buffer = res;
          res = temp;
        }
        // for more accuracy, scrolling related registers should also be set
        ppu_memory.memory_addr += _ppu_addr_increase;
        ppu_memory.memory_addr &= 0xFFFF;
        return res;

      case 0x4016:
        // joypad 1 state
        bool res = _cpu.gamepad.isPressed(_curr_button_id);
        _curr_button_id++;
        _curr_button_id %= 25;
        _joypad_reset = false;
        return res ? 1 : 0;

      case 0x4017:
        // joypad 2 register
        // print("Attempt to access player 2 gamepad");
        return 0;

      default:
        debugger();
        throw "Attempt to access memory location 0x${index.toRadixString(16)}";
    }
  }

  void operator []=(int index, int value) {
    index = _get_addr(index);
    if (index < 0x2000) {
      _data[index] = value;
      return;
    }

    if (index >= 0x6000 && index < 0x8000) {
      // sram, may disable it if no sram inserted
      _data[index] = value;
      return;
    } else if ((index >= 0x4000 && index <= 0x4013) || index == 0x4015) {
      // sound, not implemented yet
      _data[index] = value;
      return;
    } else if (index >= 0x8000) {
      _cpu.mapper.memory_write(index, value);
      return;
    }

    switch (index) {
      case 0x2000:
        ppu_memory
          ..control_register = value
          ..temp_addr &= ~(3 << 10)
          ..temp_addr |= (value & 3) << 10;
        break;
      case 0x2001:
        ppu_memory.mask_register = value;
        break;
      case 0x2003:
        _sprite_memory_addr = value;
        break;
      case 0x2004:
        if (_sprite_memory_addr & 3 == 2) {
          // bits 234 of byte 2 are unimplemented
          value &= 0xE3;
        }
        ppu_memory.spr_ram[_sprite_memory_addr] = value;
        _sprite_memory_addr++;
        _sprite_memory_addr &= 0xFF;
        break;
      case 0x2005:
        if (ppu_memory.toggle_second_w) {
          ppu_memory
            ..temp_addr &= 0xC1F
            ..temp_addr |= ((value & 7) << 12)
            ..temp_addr |= ((value & 0xF8) << 2)
            ..toggle_second_w = false;
        } else {
          ppu_memory
            ..x_scroll &= ~7
            ..x_scroll |= value & 7
            ..temp_addr &= ~0x1F
            ..temp_addr |= (value >> 3)
            ..toggle_second_w = true;
        }
        break;
      case 0x2006:
        if (ppu_memory.toggle_second_w) {
          ppu_memory
            ..temp_addr &= 0xFF00
            ..temp_addr |= value
            ..transfer_temp_addr()
            ..toggle_second_w = false;
        } else {
          ppu_memory
            ..temp_addr &= 0x00FF
            ..temp_addr |= ((value & 0x3F) << 8)
            ..toggle_second_w = true;
        }
        break;
      case 0x2007:
        //if (ppu_memory.memory_addr == 0x3F01) debugger();
        ppu_memory[ppu_memory.memory_addr] = value;
        ppu_memory.memory_addr += _ppu_addr_increase;
        ppu_memory.memory_addr &= 0xFFFF;
        break;
      case 0x4014:
        // DMA
        for (int i = 0; i <= 0xFF; i++) {
          ppu_memory.spr_ram[(_sprite_memory_addr + i) & 0xFF] =
              this[(value << 8) + i];
        }
        cpu._interpreter._cpu_cycles += 513;
        break;
      case 0x4016:
        if ((value & 1) == 1) {
          _joypad_reset = true;
        } else {
          if (_joypad_reset) _curr_button_id = 0;

          _joypad_reset = false;
        }
        break;
      case 0x4017:
        break;
      default:
        debugger();
        throw "Memory write at 0x${index.toRadixString(16)} not implemented";
    }
  }

  /// return the 16-bit address when an IRQ happens
  int get irq_address => _data[0xFFFE] | ((_data[0xFFFF]) << 8);
}
