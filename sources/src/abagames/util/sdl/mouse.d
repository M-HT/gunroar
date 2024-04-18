/*
 * $Id: mouse.d,v 1.1 2005/09/11 00:47:41 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.mouse;

private import std.string;
private import std.stdio;
private import SDL;
private import abagames.util.sdl.input;
private import abagames.util.sdl.recordableinput;
private import abagames.util.sdl.screen;

/**
 * Mouse input.
 */
public class Mouse: Input {
 public:
  //float accel = 1;
 private:
  SizableScreen screen;
  MouseState state;

  public this() {
    state = new MouseState;
  }

  public void init(SizableScreen screen) {
    this.screen = screen;
    /*if (screen.windowMode) {
      SDL_GetMouseState(&state.x, &state.y);
    } else {
      state.x = screen.width / 2;
      state.y = screen.height / 2;
    }*/
  }

  public void handleEvent(SDL_Event *event) {
  }

  public MouseState getState() {
    int mx, my;
    int btn = SDL_GetMouseState(&mx, &my);
    version (PANDORA) {
      mx -= screen.startx;
      my -= screen.starty;

      if (mx < 0) mx = 0;
      if (my < 0) my = 0;
      if (mx >= screen.width) mx = screen.width - 1;
      if (my >= screen.height) my = screen.height - 1;
    }
    state.x = mx;
    state.y = my;
    /*int mvx, mvy;
    int btn = SDL_GetRelativeMouseState(&mvx, &mvy);
    state.x += mvx * accel;
    state.y += mvy * accel;
    if (state.x < 0)
      state.x = 0;
    else if (state.x >= screen.width)
      state.x = screen.width - 1;
    if (state.y < 0)
      state.y = 0;
    else if (state.y >= screen.height)
      state.x = screen.height - 1;*/
    state.button = 0;
    if (btn & SDL_BUTTON(1)) {
      version (PANDORA) {
        Uint8 *keys = SDL_GetKeyState(null);
        if (keys[SDLK_RSHIFT] == SDL_PRESSED) {
          state.button |= MouseState.Button.RIGHT;
        } else {
          state.button |= MouseState.Button.LEFT;
        }
      } else {
        state.button |= MouseState.Button.LEFT;
      }
    }
    if (btn & SDL_BUTTON(3))
      state.button |= MouseState.Button.RIGHT;
    adjustPos(state);
    return state;
  }

  protected void adjustPos(MouseState ms) {}

  public MouseState getNullState() {
    state.clear();
    return state;
  }
}

public class MouseState {
 public:
  static enum Button {
    LEFT = 1, RIGHT = 2,
  };
  float x, y;
  int button;
 private:

  public static MouseState newInstance() {
    return new MouseState;
  }

  public static MouseState newInstance(MouseState s) {
    return new MouseState(s);
  }

  public this() {
  }

  public this(MouseState s) {
    this();
    set(s);
  }

  public void set(MouseState s) {
    x = s.x;
    y = s.y;
    button = s.button;
  }

  public void clear() {
    button = 0;
  }

  public void read(File fd) {
    float[2] read_data;
    fd.rawRead(read_data);
    x = read_data[0];
    y = read_data[1];
    int[1] read_data2;
    fd.rawRead(read_data2);
    button = read_data2[0];
  }

  public void write(File fd) {
    float[2] write_data = [x, y];
    fd.rawWrite(write_data);
    int[1] write_data2 = [button];
    fd.rawWrite(write_data2);
  }

  public bool equals(MouseState s) {
    if (x == s.x && y == s.y && button == s.button)
      return true;
    else
      return false;
  }
}

public class RecordableMouse: Mouse {
  mixin RecordableInput!(MouseState);
 private:

  public override MouseState getState() {
    return getState(true);
  }

  public MouseState getState(bool doRecord) {
    MouseState s = super.getState();
    if (doRecord)
      record(s);
    return s;
  }
}
