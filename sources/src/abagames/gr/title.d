/*
 * $Id: title.d,v 1.4 2005/09/11 00:47:40 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.gr.title;

private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
//private import openglu;
private import abagames.util.vector;
private import abagames.util.sdl.texture;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.mouse;
private import abagames.gr.screen;
private import abagames.gr.prefmanager;
private import abagames.gr.field;
private import abagames.gr.letter;
private import abagames.gr.gamemanager;
private import abagames.gr.replay;
private import abagames.gr.soundmanager;

/**
 * Title screen.
 */
public class TitleManager {
 private:
  static const float SCROLL_SPEED_BASE = 0.025f;
  PrefManager prefManager;
  RecordablePad pad;
  RecordableMouse mouse;
  Field field;
  GameManager gameManager;
  Texture logo;
  int cnt;
  ReplayData _replayData;
  int btnPressedCnt;
  int gameMode;
  const GLfloat[2*4] titleTexCoords1 = [
    0, 0,
    1, 0,
    1, 1,
    0, 1
  ];
  const GLfloat[2*4] titleVertices1 = [
    0, -63,
    255, -63,
    255, 0,
    0, 0
  ];
  const GLfloat[2*(3+3)] titleVertices2 = [
    -80, -7,
    -20, -7,
    10, -70,

    45, -2,
    -15, -2,
    -45, 61
  ];
  const GLfloat[2*(3+3)] titleVertices3 = [
    -19, -6,
    -79, -6,
    11, -69,

    -16, -3,
    44, -3,
    -46, 60
  ];
  GLfloat[4*(3+3)] titleColors3 = [
    1, 1, 1, 1,
    0, 0, 0, 1,
    0, 0, 0, 1,

    1, 1, 1, 1,
    0, 0, 0, 1,
    0, 0, 0, 1
  ];

  public this(PrefManager prefManager, Pad pad, Mouse mouse,
              Field field, GameManager gameManager) {
    this.prefManager = prefManager;
    this.pad = cast(RecordablePad) pad;
    this.mouse = cast(RecordableMouse) mouse;
    this.field = field;
    this.gameManager = gameManager;
    init();
  }

  private void init() {
    logo = new Texture("title.bmp");
    gameMode = prefManager.prefData.gameMode;

    foreach(i; 0..(3+3)) {
      titleColors3[4*i + 0] *= Screen.brightness;
      titleColors3[4*i + 1] *= Screen.brightness;
      titleColors3[4*i + 2] *= Screen.brightness;
    }
  }

  public void close() {
    logo.close();
  }

  public void start() {
    cnt = 0;
    field.start();
    btnPressedCnt = 1;
  }

  public void move() {
    if (!_replayData) {
      field.move();
      field.scroll(SCROLL_SPEED_BASE, true);
    }
    PadState input = pad.getState(false);
    MouseState mouseInput = mouse.getState(false);
    if (btnPressedCnt <= 0) {
      if (((input.button & PadState.Button.A) ||
           (gameMode == InGameState.GameMode.MOUSE &&
            (mouseInput.button & MouseState.Button.LEFT))) &&
          gameMode >= 0)
        gameManager.startInGame(gameMode);
      int gmc = 0;
      if ((input.button & PadState.Button.B) || (input.dir & PadState.Dir.DOWN))
        gmc = 1;
      else if (input.dir & PadState.Dir.UP)
        gmc = -1;
      if (gmc != 0) {
        gameMode += gmc;
        if (gameMode >= InGameState.GAME_MODE_NUM)
          gameMode = -1;
        else if (gameMode < -1)
          gameMode = InGameState.GAME_MODE_NUM - 1;
        if (gameMode == -1 && _replayData) {
          SoundManager.enableBgm();
          SoundManager.enableSe();
          SoundManager.playCurrentBgm();
        } else {
          SoundManager.fadeBgm();
          SoundManager.disableBgm();
          SoundManager.disableSe();
        }
      }
    }
    if ((input.button & (PadState.Button.A | PadState.Button.B)) ||
        (input.dir & (PadState.Dir.UP | PadState.Dir.DOWN)) ||
        (mouseInput.button & MouseState.Button.LEFT))
      btnPressedCnt = 6;
    else
      btnPressedCnt--;
    cnt++;
  }

  private void drawTitle() {
    glEnable(GL_TEXTURE_2D);
    logo.bind();
    Screen.setColor(1, 1, 1);

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glVertexPointer(2, GL_FLOAT, 0, cast(void *)(titleVertices1.ptr));
    glTexCoordPointer(2, GL_FLOAT, 0, cast(void *)(titleTexCoords1.ptr));
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

    glDisable(GL_TEXTURE_2D);
    Screen.lineWidth(3);

    glVertexPointer(2, GL_FLOAT, 0, cast(void *)(titleVertices2.ptr));

    glDrawArrays(GL_LINE_STRIP, 0, 3);
    glDrawArrays(GL_LINE_STRIP, 3, 3);

    glEnableClientState(GL_COLOR_ARRAY);

    glVertexPointer(2, GL_FLOAT, 0, cast(void *)(titleVertices3.ptr));
    glColorPointer(4, GL_FLOAT, 0, cast(void *)(titleColors3.ptr));

    glDrawArrays(GL_TRIANGLE_FAN, 0, 3);
    glDrawArrays(GL_TRIANGLE_FAN, 3, 3);

    Screen.lineWidth(1);

    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
  }

  public void draw() {
    if (gameMode < 0) {
      Letter.drawString("REPLAY", 3, 400, 5);
      return;
    }
    float ts = 1;
    if (cnt > 120) {
      ts -= (cnt - 120) * 0.015f;
      if (ts < 0.5f)
        ts = 0.5f;
    }
    glPushMatrix();
    glTranslatef(80 * ts, 240, 0);
    glScalef(ts, ts, 0);
    drawTitle();
    glPopMatrix();
    if (cnt > 150) {
      Letter.drawString("HIGH", 3, 305, 4, Letter.Direction.TO_RIGHT, 1);
      Letter.drawNum(prefManager.prefData.highScore(gameMode), 80, 320, 4, 0, 9);
    }
    if (cnt > 200) {
      Letter.drawString("LAST", 3, 345, 4, Letter.Direction.TO_RIGHT, 1);
      int ls = 0;
      if (_replayData)
        ls = _replayData.score;
      Letter.drawNum(ls, 80, 360, 4, 0, 9);
    }
    Letter.drawString(InGameState.gameModeText[gameMode], 3, 400, 5);
  }

  public ReplayData replayData(ReplayData v) {
    return _replayData = v;
  }
}
