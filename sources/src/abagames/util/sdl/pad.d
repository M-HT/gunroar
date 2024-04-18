/*
 * $Id: pad.d,v 1.2 2005/07/03 07:05:23 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.pad;

version (PANDORA) {
  private import std.conv;
}
private import std.string;
private import std.stdio;
private import SDL;
private import abagames.util.sdl.input;
private import abagames.util.sdl.recordableinput;

/**
 * Joystick and keyboard input.
 */
public class Pad: Input {
 public:
  Uint8 *keys;
  bool buttonReversed = false;
 private:
  SDL_Joystick *stick = null;
  const int JOYSTICK_AXIS = 16384;
  PadState state;

  public this() {
    state = new PadState;
  }

  public SDL_Joystick* openJoystick(SDL_Joystick *st = null) {
    if (st == null) {
      if (SDL_InitSubSystem(SDL_INIT_JOYSTICK) < 0)
        return null;
      version (PANDORA) {
        foreach (i; 0..SDL_NumJoysticks()) {
          if (to!string(SDL_JoystickName(i)) == "nub0") {
            stick = SDL_JoystickOpen(i);
          }
        }
      } else {
        stick = SDL_JoystickOpen(0);
      }
    } else {
      stick = st;
    }
    return stick;
  }

  public void handleEvent(SDL_Event *event) {
    keys = SDL_GetKeyState(null);
  }

  public PadState getState() {
    int x = 0, y = 0;
    state.dir = 0;
    if (stick) {
      x = SDL_JoystickGetAxis(stick, 0);
      y = SDL_JoystickGetAxis(stick, 1);
    }
    if (keys[SDLK_RIGHT] == SDL_PRESSED || keys[SDLK_KP6] == SDL_PRESSED ||
        keys[SDLK_d] == SDL_PRESSED || keys[SDLK_l] == SDL_PRESSED ||
        x > JOYSTICK_AXIS)
      state.dir |= PadState.Dir.RIGHT;
    if (keys[SDLK_LEFT] == SDL_PRESSED || keys[SDLK_KP4] == SDL_PRESSED ||
        keys[SDLK_a] == SDL_PRESSED || keys[SDLK_j] == SDL_PRESSED ||
        x < -JOYSTICK_AXIS)
      state.dir |= PadState.Dir.LEFT;
    if (keys[SDLK_DOWN] == SDL_PRESSED || keys[SDLK_KP2] == SDL_PRESSED ||
        keys[SDLK_s] == SDL_PRESSED || keys[SDLK_k] == SDL_PRESSED ||
        y > JOYSTICK_AXIS)
      state.dir |= PadState.Dir.DOWN;
    if (keys[SDLK_UP] == SDL_PRESSED ||  keys[SDLK_KP8] == SDL_PRESSED ||
        keys[SDLK_w] == SDL_PRESSED || keys[SDLK_i] == SDL_PRESSED ||
        y < -JOYSTICK_AXIS)
      state.dir |= PadState.Dir.UP;
    state.button = 0;
    bool btnx = false, btnz = false;
    int btn1 = 0, btn2 = 0;
    float leftTrigger = 0, rightTrigger = 0;
    if (stick) {
      btn1 = SDL_JoystickGetButton(stick, 0) + SDL_JoystickGetButton(stick, 3) +
             SDL_JoystickGetButton(stick, 4) + SDL_JoystickGetButton(stick, 7) +
             SDL_JoystickGetButton(stick, 8) + SDL_JoystickGetButton(stick, 11);
      btn2 = SDL_JoystickGetButton(stick, 1) + SDL_JoystickGetButton(stick, 2) +
             SDL_JoystickGetButton(stick, 5) + SDL_JoystickGetButton(stick, 6) +
             SDL_JoystickGetButton(stick, 9) + SDL_JoystickGetButton(stick, 10);
    }
    version (PANDORA) {
      if (keys[SDLK_HOME] == SDL_PRESSED || keys[SDLK_PAGEUP] == SDL_PRESSED) btnz = true;
      if (keys[SDLK_PAGEDOWN] == SDL_PRESSED || keys[SDLK_END] == SDL_PRESSED) btnx = true;
    } else {
      if (keys[SDLK_z] == SDL_PRESSED || keys[SDLK_PERIOD] == SDL_PRESSED ||
          keys[SDLK_LCTRL] == SDL_PRESSED || keys[SDLK_RCTRL] == SDL_PRESSED ||
          btn1) btnz = true;
      if (keys[SDLK_x] == SDL_PRESSED || keys[SDLK_SLASH] == SDL_PRESSED ||
          keys[SDLK_LALT] == SDL_PRESSED || keys[SDLK_RALT] == SDL_PRESSED ||
          keys[SDLK_LSHIFT] == SDL_PRESSED || keys[SDLK_RSHIFT] == SDL_PRESSED ||
          keys[SDLK_RETURN] == SDL_PRESSED ||
          btn2) btnx = true;
    }
    if (btnz) {
      if (!buttonReversed)
        state.button |= PadState.Button.A;
      else
        state.button |= PadState.Button.B;
    }
    if (btnx) {
      if (!buttonReversed)
        state.button |= PadState.Button.B;
      else
        state.button |= PadState.Button.A;
    }
    return state;
  }

  public PadState getNullState() {
    state.clear();
    return state;
  }

}

public class PadState {
 public:
  static enum Dir {
    UP = 1, DOWN = 2, LEFT = 4, RIGHT = 8,
  };
  static enum Button {
    A = 16, B = 32, ANY = 48,
  };
  int dir, button;
 private:

  public static PadState newInstance() {
    return new PadState;
  }

  public static PadState newInstance(PadState s) {
    return new PadState(s);
  }

  public this() {
  }

  public this(PadState s) {
    this();
    set(s);
  }

  public void set(PadState s) {
    dir = s.dir;
    button = s.button;
  }

  public void clear() {
    dir = button = 0;
  }

  public void read(File fd) {
    int[1] read_data;
    fd.rawRead(read_data);
    dir = read_data[0] & (Dir.UP | Dir.DOWN | Dir.LEFT | Dir.RIGHT);
    button = read_data[0] & Button.ANY;
  }

  public void write(File fd) {
    int[1] write_data = [dir | button];
    fd.rawWrite(write_data);
  }

  public bool equals(PadState s) {
    if (dir == s.dir && button == s.button)
      return true;
    else
      return false;
  }
}

public class RecordablePad: Pad {
  mixin RecordableInput!(PadState);
 private:

  public override PadState getState() {
    return getState(true);
  }

  public PadState getState(bool doRecord) {
    PadState s = super.getState();
    if (doRecord)
      record(s);
    return s;
  }
}
