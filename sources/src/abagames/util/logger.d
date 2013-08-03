/*
 * $Id: logger.d,v 1.2 2005/07/03 07:05:23 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.logger;

private import std.string;
private import std.stdio;
private import std.conv;

/**
 * Logger(error/info).
 */
version(Win32_release) {

private import std.string;
private import std.c.windows.windows;

public class Logger {

  public static void info(const char[] msg, bool nline = true) {
    // Win32 exe crashes if it writes something to stderr.
    /*if (nline)
      stderr.writeln(msg);
    else
      stderr.write(msg);*/
  }

  public static void info(double n, bool nline = true) {
    /*if (nline)
      stderr.writeln(std.string.toString(n));
    else
      stderr.write(std.string.toString(n) ~ " ");*/
  }

  private static void putMessage(const char[] msg) {
    MessageBoxA(null, std.string.toStringz(msg), "Error", MB_OK | MB_ICONEXCLAMATION);
  }

  public static void error(const char[] msg) {
    putMessage("Error: " ~ msg);
  }

  public static void error(Exception e) {
    putMessage("Error: " ~ e.toString());
  }

  public static void error(Error e) {
    putMessage("Error: " ~ e.toString());
  }
}

} else {

public class Logger {

  public static void info(const char[] msg, bool nline = true) {
    if (nline)
      stderr.writeln(msg);
    else
      stderr.write(msg);
  }

  public static void info(double n, bool nline = true) {
    if (nline)
      stderr.writeln(to!string(n));
    else
      stderr.write(to!string(n) ~ " ");
  }

  public static void error(const char[] msg) {
    stderr.writeln("Error: " ~ msg);
  }

  public static void error(Exception e) {
    stderr.writeln("Error: " ~ e.toString());
  }

  public static void error(Error e) {
    stderr.writeln("Error: " ~ e.toString());
    if (e.next)
      error(cast(Error)e.next);
  }
}

}
