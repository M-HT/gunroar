/*
 * $Id: texture.d,v 1.2 2005/07/03 07:05:23 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.texture;

private import std.string;
private import opengl;
private import openglu;
private import bindbc.sdl;
private import abagames.util.sdl.sdlexception;

/**
 * Manage OpenGL textures.
 */
public class Texture {
 public:
  static string imagesDir = "images/";
  static SDL_Surface*[char[]] surface;
 private:
  GLuint[] num, maskNum;
  int textureNum, maskTextureNum;
  uint[128 * 128] pixels;
  uint[128 * 128] maskPixels;

  public static SDL_Surface* loadBmp(const char[] name) {
    if (name in surface) {
      return surface[name];
    } else {
      const char[] fileName = imagesDir ~ name;
      SDL_Surface *s = SDL_LoadBMP(std.string.toStringz(fileName));
      if (!s)
        throw new SDLInitFailedException("Unable to load: " ~ fileName);
      SDL_PixelFormat *format = SDL_AllocFormat(SDL_PIXELFORMAT_ABGR8888);
      SDL_Surface *cs = SDL_ConvertSurface(s, format, 0);
      SDL_FreeFormat(format);
      surface[name] = cs;
      return cs;
    }
  }

  public this(const char[] name) {
    SDL_Surface *s = loadBmp(name);
    num.length = 1;
    glGenTextures(1, num.ptr);
    glBindTexture(GL_TEXTURE_2D, num[0]);
    gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, s.w, s.h,
                      GL_RGBA, GL_UNSIGNED_BYTE, s.pixels);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  }

  public this(const char[] name, int sx, int sy, int xn, int yn, int panelWidth, int panelHeight,
              uint maskColor = 0xffffffffu) {
    SDL_Surface *s = loadBmp(name);
    uint* surfacePixels = cast(uint*) s.pixels;
    this(surfacePixels, s.w, sx, sy, xn, yn, panelWidth, panelHeight, maskColor);
  }

  public this(uint* surfacePixels, int surfaceWidth,
              int sx, int sy, int xn, int yn, int panelWidth, int panelHeight,
              uint maskColor = 0xffffffffu) {
    textureNum = xn * yn;
    num.length = textureNum;
    glGenTextures(textureNum, num.ptr);
    if (maskColor != 0xffffffffu) {
      maskTextureNum = textureNum;
      maskNum.length = maskTextureNum;
      glGenTextures(maskTextureNum, maskNum.ptr);
    }
    int ti = 0;
    for (int oy = 0; oy < yn; oy++) {
      for (int ox = 0; ox < xn; ox++) {
        int pi = 0;
        for (int y = 0; y < panelHeight; y++) {
          for (int x = 0; x < panelWidth; x++) {
            uint p = surfacePixels[ox * panelWidth + x + sx + (oy * panelHeight + y + sy) * surfaceWidth];
            uint m;
            if (p == maskColor) {
              p = 0xff000000u;
              m = 0x00ffffffu;
            } else {
              m = 0x00000000u;
            }
            pixels[pi] = p;
            if (maskColor != 0xffffffffu)
              maskPixels[pi] = m;
            pi++;
          }
        }
        glBindTexture(GL_TEXTURE_2D, num[ti]);
        gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, panelWidth, panelHeight,
                          GL_RGBA, GL_UNSIGNED_BYTE, pixels.ptr);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        if (maskColor != 0xffffffffu) {
          glBindTexture(GL_TEXTURE_2D, maskNum[ti]);
          gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, panelWidth, panelHeight,
                            GL_RGBA, GL_UNSIGNED_BYTE, maskPixels.ptr);
          glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
          glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        }
        ti++;
      }
    }
  }

  public void close() {
    glDeleteTextures(textureNum, num.ptr);
    num.length = 0;
    if (maskTextureNum > 0) {
      glDeleteTextures(maskTextureNum, maskNum.ptr);
      maskNum.length = 0;
    }
  }

  public void bind(int idx = 0) {
    glBindTexture(GL_TEXTURE_2D, num[idx]);
  }

  public void bindMask(int idx = 0) {
    glBindTexture(GL_TEXTURE_2D, maskNum[idx]);
  }
}
