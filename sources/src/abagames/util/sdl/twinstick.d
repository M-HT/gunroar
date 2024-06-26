/*
 * $Id: twinstick.d,v 1.5 2006/03/18 02:42:09 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.twinstick;

version(PANDORA) version = PANDORA_OR_PYRA;
version(PYRA) version = PANDORA_OR_PYRA;

version (PANDORA) {
  private import std.conv;
}
private import std.string;
private import std.stdio;
private import std.math;
private import bindbc.sdl;
private import abagames.util.vector;
private import abagames.util.sdl.input;
private import abagames.util.sdl.recordableinput;

/**
 * Twinstick input.
 */
public class TwinStick: Input {
 public:
  float rotate = 0;
  float reverse = 1;
  ubyte *keys;
  bool enableAxis5 = false;
 private:
  SDL_Joystick *stick = null;
version (PANDORA) {
  SDL_Joystick *stick2 = null;
}
  const int JOYSTICK_AXIS_MAX = 32768;
  TwinStickState state;

  public this() {
    state = new TwinStickState;
  }

  public SDL_Joystick* openJoystick(SDL_Joystick *st = null) {
    if (st == null) {
      if (SDL_InitSubSystem(SDL_INIT_JOYSTICK) < 0)
        return null;
      version (PANDORA) {
        foreach (i; 0..SDL_NumJoysticks()) {
          if (to!string(SDL_JoystickNameForIndex(i)) == "nub0") {
            stick = SDL_JoystickOpen(i);
          }
        }
      } else {
        stick = SDL_JoystickOpen(0);
      }
    } else {
      stick = st;
    }
    version (PANDORA) {
      foreach (i; 0..SDL_NumJoysticks()) {
        if (to!string(SDL_JoystickNameForIndex(i)) == "nub1") {
          stick2 = SDL_JoystickOpen(i);
        }
      }
    }
    return stick;
  }

  public void handleEvent(SDL_Event *event) {
  }

  public void handleEvents() {
    keys = SDL_GetKeyboardState(null);
  }

  public TwinStickState getState() {
    if (stick) {
      state.left.x = adjustAxis(SDL_JoystickGetAxis(stick, 0));
      state.left.y = -adjustAxis(SDL_JoystickGetAxis(stick, 1));
      version (PANDORA) {
        int rx = SDL_JoystickGetAxis(stick2, 0);
        int ry = SDL_JoystickGetAxis(stick2, 1);
      } else {
        int rx = 0;
        if (enableAxis5)
          rx = SDL_JoystickGetAxis(stick, 4);
        else
          rx = SDL_JoystickGetAxis(stick, 2);
        int ry = SDL_JoystickGetAxis(stick, 3);
      }
      if (rx == 0 && ry == 0) {
        state.right.x = state.right.y = 0;
      } else {
        ry = -ry;
        float rd = atan2(cast(float) rx, cast(float) ry) * reverse + rotate;
        assert(!std.math.isNaN(rd));
        float rl = sqrt(cast(float) rx * rx + cast(float) ry * ry);
        assert(!std.math.isNaN(rl));
        const float rdSin = sin(rd);
        const float rdCos = cos(rd);
        state.right.x = adjustAxis(cast(int) (rdSin * rl));
        state.right.y = adjustAxis(cast(int) (rdCos * rl));
      }
    } else {
      state.left.x = state.left.y = state.right.x = state.right.y = 0;
    }
    version (PANDORA_OR_PYRA) {
      if (keys[SDL_SCANCODE_RIGHT] == SDL_PRESSED)
        state.left.x = 1;
      if (keys[SDL_SCANCODE_LEFT] == SDL_PRESSED)
        state.left.x = -1;
      if (keys[SDL_SCANCODE_DOWN] == SDL_PRESSED)
        state.left.y = -1;
      if (keys[SDL_SCANCODE_UP] == SDL_PRESSED)
        state.left.y = 1;

      if (keys[SDL_SCANCODE_END] == SDL_PRESSED)
        state.right.x = 1;
      if (keys[SDL_SCANCODE_HOME] == SDL_PRESSED)
        state.right.x = -1;
      if (keys[SDL_SCANCODE_PAGEDOWN] == SDL_PRESSED)
        state.right.y = -1;
      if (keys[SDL_SCANCODE_PAGEUP] == SDL_PRESSED)
        state.right.y = 1;
    } else {
      if (keys[SDL_SCANCODE_D] == SDL_PRESSED)
        state.left.x = 1;
      if (keys[SDL_SCANCODE_L] == SDL_PRESSED)
        state.right.x = 1;
      if (keys[SDL_SCANCODE_A] == SDL_PRESSED)
        state.left.x = -1;
      if (keys[SDL_SCANCODE_J] == SDL_PRESSED)
        state.right.x = -1;
      if (keys[SDL_SCANCODE_S] == SDL_PRESSED)
        state.left.y = -1;
      if (keys[SDL_SCANCODE_K] == SDL_PRESSED)
        state.right.y = -1;
      if (keys[SDL_SCANCODE_W] == SDL_PRESSED)
        state.left.y = 1;
      if (keys[SDL_SCANCODE_I] == SDL_PRESSED)
        state.right.y = 1;
    }
    return state;
  }

  public float adjustAxis(int v) {
    float a = 0;
    if (v > JOYSTICK_AXIS_MAX / 3) {
      a = cast(float) (v - JOYSTICK_AXIS_MAX / 3) /
        (JOYSTICK_AXIS_MAX - JOYSTICK_AXIS_MAX / 3);
      if (a > 1)
        a = 1;
    } else if (v < -(JOYSTICK_AXIS_MAX / 3)) {
      a = cast(float) (v + JOYSTICK_AXIS_MAX / 3) /
        (JOYSTICK_AXIS_MAX - JOYSTICK_AXIS_MAX / 3);
      if (a < -1)
        a = -1;
    }
    return a;
  }

  public TwinStickState getNullState() {
    state.clear();
    return state;
  }
}

public class TwinStickState {
 public:
  Vector left, right;
 private:

  invariant() {
    assert(left.x >= -1 && left.x <= 1);
    assert(left.y >= -1 && left.y <= 1);
    assert(right.x >= -1 && right.x <= 1);
    assert(right.y >= -1 && right.y <= 1);
  }

  public static TwinStickState newInstance() {
    return new TwinStickState;
  }

  public static TwinStickState newInstance(TwinStickState s) {
    return new TwinStickState(s);
  }

  public this() {
    left = new Vector;
    right = new Vector;
  }

  public this(TwinStickState s) {
    this();
    set(s);
  }

  public void set(TwinStickState s) {
    left.x = s.left.x;
    left.y = s.left.y;
    right.x = s.right.x;
    right.y = s.right.y;
  }

  public void clear() {
    left.x = left.y = right.x = right.y = 0;
  }

  public void read(File fd) {
    float[4] read_data;
    fd.rawRead(read_data);
    left.x = read_data[0];
    left.y = read_data[1];
    right.x = read_data[2];
    right.y = read_data[3];
  }

  public void write(File fd) {
    float[4] write_data = [left.x, left.y, right.x, right.y];
    fd.rawWrite(write_data);
  }

  public bool equals(TwinStickState s) {
    return (left.x == s.left.x && left.y == s.left.y &&
            right.x == s.right.x && right.y == s.right.y);
  }
}

public class RecordableTwinStick: TwinStick {
  mixin RecordableInput!(TwinStickState);
 private:

  public override TwinStickState getState() {
    return getState(true);
  }

  public TwinStickState getState(bool doRecord) {
    TwinStickState s = super.getState();
    if (doRecord)
      record(s);
    return s;
  }
}
