/*
 * $Id: replay.d,v 1.4 2005/09/11 00:47:40 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.gr.replay;

private import std.stdio;
private import abagames.util.sdl.recordableinput;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.twinstick;
private import abagames.util.sdl.mouse;
private import abagames.gr.gamemanager;
private import abagames.gr.mouseandpad;

/**
 * Save/Load a replay data.
 */
public class ReplayData {
 public:
  static string dir = "replay";
  static const int VERSION_NUM = 11;
  InputRecord!(PadState) padInputRecord;
  InputRecord!(TwinStickState) twinStickInputRecord;
  InputRecord!(MouseAndPadState) mouseAndPadInputRecord;
  long seed;
  int score = 0;
  float shipTurnSpeed;
  bool shipReverseFire;
  int gameMode;
 private:

  public void save(string fileName) {
    scope File fd;
    int[1] write_data_int;
    long[1] write_data_long;
    float[1] write_data_float;
    fd.open(dir ~ "/" ~ fileName, "wb");
    write_data_int[0] = VERSION_NUM;
    fd.rawWrite(write_data_int);
    write_data_long[0] = seed;
    fd.rawWrite(write_data_long);
    write_data_int[0] = score;
    fd.rawWrite(write_data_int);
    write_data_float[0] = shipTurnSpeed;
    fd.rawWrite(write_data_float);
    write_data_int[0] = (shipReverseFire)?1:0;
    fd.rawWrite(write_data_int);
    write_data_int[0] = gameMode;
    fd.rawWrite(write_data_int);
    switch (gameMode) {
    case InGameState.GameMode.NORMAL:
      padInputRecord.save(fd);
      break;
    case InGameState.GameMode.TWIN_STICK:
    case InGameState.GameMode.DOUBLE_PLAY:
      twinStickInputRecord.save(fd);
      break;
    case InGameState.GameMode.MOUSE:
      mouseAndPadInputRecord.save(fd);
      break;
    default:
      break;
    }
    fd.close();
  }

  public void load(string fileName) {
    scope File fd;
    int[1] read_data_int;
    long[1] read_data_long;
    float[1] read_data_float;
    fd.open(dir ~ "/" ~ fileName);
    fd.rawRead(read_data_int);
    if (read_data_int[0] != VERSION_NUM)
      throw new Exception("Wrong version num");
    fd.rawRead(read_data_long);
    seed = read_data_long[0];
    fd.rawRead(read_data_int);
    score = read_data_int[0];
    fd.rawRead(read_data_float);
    shipTurnSpeed = read_data_float[0];
    fd.rawRead(read_data_int);
    if (read_data_int[0] == 1)
      shipReverseFire = true;
    else
      shipReverseFire = false;
    fd.rawRead(read_data_int);
    gameMode = read_data_int[0];
    switch (gameMode) {
    case InGameState.GameMode.NORMAL:
      padInputRecord = new InputRecord!(PadState);
      padInputRecord.load(fd);
      break;
    case InGameState.GameMode.TWIN_STICK:
    case InGameState.GameMode.DOUBLE_PLAY:
      twinStickInputRecord = new InputRecord!(TwinStickState);
      twinStickInputRecord.load(fd);
      break;
    case InGameState.GameMode.MOUSE:
      mouseAndPadInputRecord = new InputRecord!(MouseAndPadState);
      mouseAndPadInputRecord.load(fd);
      break;
    default:
      break;
    }
    fd.close();
  }
}
