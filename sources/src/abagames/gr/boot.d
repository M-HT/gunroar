/*
 * $Id: boot.d,v 1.6 2006/03/18 02:42:09 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.gr.boot;

private import std.string;
//private import std.stream;
private import std.conv;
private import std.math;
private import core.stdc.stdlib;
private import abagames.util.logger;
private import abagames.util.tokenizer;
private import abagames.util.sdl.mainloop;
private import abagames.util.sdl.input;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.twinstick;
private import abagames.util.sdl.recordableinput;
private import abagames.util.sdl.sound;
private import abagames.gr.screen;
private import abagames.gr.gamemanager;
private import abagames.gr.prefmanager;
private import abagames.gr.ship;
private import abagames.gr.mouse;

/**
 * Boot the game.
 */
private:
Screen screen;
MultipleInputDevice input;
RecordablePad pad;
RecordableTwinStick twinStick;
RecordableMouse mouse;
GameManager gameManager;
PrefManager prefManager;
MainLoop mainLoop;

version (Win32_release) {
  // Boot as the Windows executable.
  private import std.c.windows.windows;
  private import std.string;

  extern (C) void gc_init();
  extern (C) void gc_term();
  extern (C) void _minit();
  extern (C) void _moduleCtor();

  extern (Windows)
  public int WinMain(HINSTANCE hInstance,
		     HINSTANCE hPrevInstance,
		     LPSTR lpCmdLine,
		     int nCmdShow) {
    int result;
    gc_init();
    _minit();
    try {
      _moduleCtor();
      char[4096] exe;
      GetModuleFileNameA(null, exe, 4096);
      string[1] prog;
      prog[0] = to!string(exe);
      result = boot(prog ~ std.string.split(to!string(lpCmdLine)));
    } catch (Exception o) {
      Logger.error("Exception: " ~ o.toString());
      result = EXIT_FAILURE;
    }
    gc_term();
    return result;
  }
} else {
  // Boot as the general executable.
  public int main(string[] args) {
    return boot(args);
  }
}

public int boot(string[] args) {
  screen = new Screen;
  input = new MultipleInputDevice;
  pad = new RecordablePad;
  twinStick = new RecordableTwinStick;
  mouse = new RecordableMouse(screen);
  input.inputs ~= pad;
  input.inputs ~= twinStick;
  input.inputs ~= mouse;
  gameManager = new GameManager;
  prefManager = new PrefManager;
  mainLoop = new MainLoop(screen, input, gameManager, prefManager);
  try {
    parseArgs(args);
  } catch (Exception e) {
    return EXIT_FAILURE;
  }
  try {
    mainLoop.loop();
  } catch (Exception o) {
    Logger.info(o.toString());
    try {
      gameManager.saveErrorReplay();
    } catch (Exception o1) {}
    throw o;
  }
  return EXIT_SUCCESS;
}

private void parseArgs(string[] commandArgs) {
  string[] args = readOptionsIniFile();
  for (int i = 1; i < commandArgs.length; i++)
    args ~= commandArgs[i];
  string progName = commandArgs[0];
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
    case "-brightness":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float b = cast(float) to!int(args[i]) / 100;
      if (b < 0 || b > 1) {
        usage(args[0]);
        throw new Exception("Invalid options");
      }
      Screen.brightness = b;
      break;
    case "-luminosity":
    case "-luminous":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float l = cast(float) to!int(args[i]) / 100;
      if (l < 0 || l > 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      screen.luminosity = l;
      break;
    case "-window":
      screen.windowMode = true;
      break;
    case "-res":
      if (i >= args.length - 2) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      int w = to!int(args[i]);
      i++;
      int h = to!int(args[i]);
      screen.screenWidth = w;
      screen.screenHeight = h;
      break;
    case "-nosound":
      SoundManager.noSound = true;
      break;
    case "-exchange":
      pad.buttonReversed = true;
      break;
    case "-nowait":
      mainLoop.nowait = true;
      break;
    case "-accframe":
      mainLoop.accframe = 1;
      break;
    case "-turnspeed":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float s = cast(float) to!int(args[i]) / 100;
      if (s < 0 || s > 5) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      GameManager.shipTurnSpeed = s;
      break;
    case "-firerear":
      GameManager.shipReverseFire = true;
      break;
    case "-rotatestick2":
    case "-rotaterightstick":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      twinStick.rotate = cast(float) to!int(args[i]) * PI / 180.0f;
      break;
    case "-reversestick2":
    case "-reverserightstick":
      twinStick.reverse = -1;
      break;
    case "-enableaxis5":
      twinStick.enableAxis5 = true;
      break;
    /*case "-mouseaccel":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float s = cast(float) to!int(args[i]) / 100;
      if (s < 0 || s > 5) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      mouse.accel = s;
      break;*/
    default:
      usage(progName);
      throw new Exception("Invalid options");
    }
  }
}

private string OPTIONS_INI_FILE = "options.ini";

private string[] readOptionsIniFile() {
  try {
    return Tokenizer.readFile(OPTIONS_INI_FILE, " ");
  } catch (Exception e) {
    return null;
  }
}

private void usage(string progName) {
  Logger.error
    ("Usage: " ~ progName ~ " [-window] [-res x y] [-brightness [0-100]] [-luminosity [0-100]] [-nosound] [-exchange] [-turnspeed [0-500]] [-firerear] [-rotatestick2 deg] [-reversestick2] [-enableaxis5] [-nowait]");
}
