/*
 * $Id: screen3d.d,v 1.1.1.1 2005/06/18 00:46:00 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.screen3d;

version(PANDORA) version = PANDORA_OR_PYRA;
version(PYRA) version = PANDORA_OR_PYRA;

private import std.string;
private import std.conv;
private import bindbc.sdl;
private import opengl;
private import abagames.util.vector;
private import abagames.util.sdl.screen;
private import abagames.util.sdl.sdlexception;

/**
 * SDL screen handler(3D, OpenGL).
 */
public class Screen3D: Screen, SizableScreen {
 private:
  static float _brightness = 1;
  float _farPlane = 1000;
  float _nearPlane = 0.1;
  int _width = 640;
  int _height = 480;
  int _screenWidth = 640;
  int _screenHeight = 480;
  int _screenStartX = 0;
  int _screenStartY = 0;
  string _name = "";
  SDL_Window* _window;
  SDL_GLContext _context;
version (PANDORA_OR_PYRA) {
  bool _windowMode = false;
} else {
  bool _windowMode = true;
}

  protected abstract void init();
  protected abstract void close();

  public override void initSDL() {
    // Initialize SDL.
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
      throw new SDLInitFailedException(
        "Unable to initialize SDL: " ~ to!string(SDL_GetError()));
    }
    // Create an OpenGL screen.
    uint videoFlags;
    if (_windowMode) {
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;
    } else {
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN_DESKTOP;
    }
    _window = SDL_CreateWindow(std.string.toStringz(_name), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _screenWidth, _screenHeight, videoFlags);
    if (_window == null) {
      throw new SDLInitFailedException(
        "Unable to create SDL window: " ~ to!string(SDL_GetError()));
    }
    _context = SDL_GL_CreateContext(_window);
    if (_context == null) {
      SDL_DestroyWindow(_window);
      _window = null;
      throw new SDLInitFailedException(
        "Unable to initialize OpenGL context: " ~ to!string(SDL_GetError()));
    }
    SDL_GetWindowSize(_window, &_screenWidth, &_screenHeight);
    glViewport(_screenStartX, _screenStartY, _screenWidth, _screenHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    resized(_screenWidth, _screenHeight);
    SDL_ShowCursor(SDL_DISABLE);
    init();
  }

  // Reset a viewport when the screen is resized.
  public void screenResized() {
    static if (SDL_VERSION_ATLEAST(2, 0, 1)) {
      SDL_version linked;
      SDL_GetVersion(&linked);
      if (SDL_version(linked.major, linked.minor, linked.patch) >= SDL_version(2, 0, 1)) {
        int glwidth, glheight;
        SDL_GL_GetDrawableSize(_window, &glwidth, &glheight);
        if ((cast(float)(glwidth)) / _width <= (cast(float)(glheight)) / _height) {
          _screenStartX = 0;
          _screenWidth = glwidth;
          _screenHeight = (glwidth * _height) / _width;
          _screenStartY = (glheight - _screenHeight) / 2;
        } else {
          _screenStartY = 0;
          _screenHeight = glheight;
          _screenWidth = (glheight * _width) / _height;
          _screenStartX = (glwidth - _screenWidth) / 2;
        }
      }
    }
    glViewport(_screenStartX, _screenStartY, _screenWidth, _screenHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    //gluPerspective(45.0f, cast(GLfloat) width / cast(GLfloat) height, nearPlane, farPlane);
    glFrustum(-_nearPlane,
              _nearPlane,
              -_nearPlane * cast(GLfloat) _height / cast(GLfloat) _width,
              _nearPlane * cast(GLfloat) _height / cast(GLfloat) _width,
              0.1f, _farPlane);
    glMatrixMode(GL_MODELVIEW);
  }

  public override void resized(int w, int h) {
    _screenWidth = w;
    _screenHeight = h;
    screenResized();
  }

  public override void closeSDL() {
    close();
    SDL_ShowCursor(SDL_ENABLE);
    SDL_GL_DeleteContext(_context);
    SDL_DestroyWindow(_window);
  }

  public override void flip() {
    handleError();
    SDL_GL_SwapWindow(_window);
  }

  public override void clear() {
    glClear(GL_COLOR_BUFFER_BIT);
  }

  public void handleError() {
    GLenum error = glGetError();
    if (error == GL_NO_ERROR)
      return;
    closeSDL();
    throw new Exception("OpenGL error(" ~ to!string(error) ~ ")");
  }

  protected void setCaption(const char[] name) {
    _name = name.idup;
    if (_window != null) {
      SDL_SetWindowTitle(_window, std.string.toStringz(name));
    }
  }

  public bool windowMode(bool v) {
    return _windowMode = v;
  }

  public bool windowMode() {
    return _windowMode;
  }

  public int width() {
    return _width;
  }

  public int height() {
    return _height;
  }

  public int screenWidth(int v) {
    return _screenWidth = v;
  }

  public int screenWidth() {
    return _screenWidth;
  }

  public int screenHeight(int v) {
    return _screenHeight = v;
  }

  public int screenHeight() {
    return _screenHeight;
  }

  public int screenStartX() {
    return _screenStartX;
  }

  public int screenStartY() {
    return _screenStartY;
  }

  public static void glVertex(Vector v) {
    glVertex3f(v.x, v.y, 0);
  }

  public static void glVertex(Vector3 v) {
    glVertex3f(v.x, v.y, v.z);
  }

  public static void glTranslate(Vector v) {
    glTranslatef(v.x, v.y, 0);
  }

  public static void glTranslate(Vector3 v) {
    glTranslatef(v.x, v.y, v.z);
  }

  public static void setColor(float r, float g, float b, float a = 1) {
    glColor4f(r * _brightness, g * _brightness, b * _brightness, a);
  }

  public static void setClearColor(float r, float g, float b, float a = 1) {
    glClearColor(r * _brightness, g * _brightness, b * _brightness, a);
  }

  public static float brightness(float v) {
    return _brightness = v;
  }
}
