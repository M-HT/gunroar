/*
 * $Id: screen.d,v 1.1.1.1 2005/06/18 00:46:00 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.screen;

/**
 * SDL screen handler interface.
 */
//public interface Screen {
public abstract class Screen {
  public void initSDL();
  public void resized(int width, int height);
  public void closeSDL();
  public void flip();
  public void clear();
}

public interface SizableScreen {
  public bool windowMode();
  public int screenWidth();
  public int screenHeight();
  public int screenStartX();
  public int screenStartY();
}
