/*
 * $Id: prefmanager.d,v 1.4 2005/09/11 00:47:40 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.gr.prefmanager;

private import std.stdio;
private import abagames.util.prefmanager;
private import abagames.gr.gamemanager;

/**
 * Save/Load the high score.
 */
public class PrefManager: abagames.util.prefmanager.PrefManager {
 private:
  static const int VERSION_NUM = 14;
  static const int VERSION_NUM_13 = 13;
  static string PREF_FILE = "gr.prf";
  PrefData _prefData;

  public this() {
    _prefData = new PrefData;
  }

  public void load() {
    scope File fd;
    try {
      int[1] read_data;
      fd.open(PREF_FILE);
      fd.rawRead(read_data);
      if (read_data[0] == VERSION_NUM_13)
        _prefData.loadVer13(fd);
      else if (read_data[0] != VERSION_NUM)
        throw new Exception("Wrong version num");
      else
        _prefData.load(fd);
    } catch (Exception e) {
      _prefData.init();
    } finally {
      if (fd.isOpen())
        fd.close();
    }
  }

  public void save() {
    scope File fd;
    try {
      fd.open(PREF_FILE, "wb");
      int[1] write_data = [VERSION_NUM];
      fd.rawWrite(write_data);
      _prefData.save(fd);
    } finally {
      fd.close();
    }
  }

  public PrefData prefData() {
    return _prefData;
  }
}

public class PrefData {
 private:
  //int[InGameState.GAME_MODE_NUM] _highScore;
  int[4] _highScore;
  int _gameMode;

  public void init() {
    foreach (ref int hs; _highScore)
      hs = 0;
    _gameMode = 0;
  }

  public void load(File fd) {
    fd.rawRead(_highScore);
    int[1] read_data;
    fd.rawRead(read_data);
    _gameMode = read_data[0];
  }

  public void loadVer13(File fd) {
    init();
    int[3] read_data13;
    fd.rawRead(read_data13);
    _highScore[0..3] = read_data13[];
    int[1] read_data;
    fd.rawRead(read_data);
    _gameMode = read_data[0];
  }

  public void save(File fd) {
    fd.rawWrite(_highScore);
    int[1] write_data = [_gameMode];
    fd.rawWrite(write_data);
  }

  public void recordGameMode(int gm) {
    _gameMode = gm;
  }

  public void recordResult(int score, int gm) {
    if (score > _highScore[gm])
      _highScore[gm] = score;
    _gameMode = gm;
  }

  public int highScore(int gm) {
    return _highScore[gm];
  }

  public int gameMode() {
    return _gameMode;
  }
}
