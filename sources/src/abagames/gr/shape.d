/*
 * $Id: shape.d,v 1.1.1.1 2005/06/18 00:46:00 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.gr.shape;

private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
private import abagames.util.vector;
private import abagames.util.rand;
private import abagames.util.sdl.shape;
private import abagames.gr.screen;
private import abagames.gr.particle;

/**
 * Shape of a ship/platform/turret/bridge.
 */
public class BaseShape: DrawableShape {
 public:
  static enum ShapeType {
    SHIP, SHIP_ROUNDTAIL, SHIP_SHADOW, PLATFORM, TURRET, BRIDGE,
    SHIP_DAMAGED, SHIP_DESTROYED,
    PLATFORM_DAMAGED, PLATFORM_DESTROYED,
    TURRET_DAMAGED, TURRET_DESTROYED,
  };
 private:
  static const int POINT_NUM = 16;
  static Rand rand;
  static Vector wakePos;
  float size, distRatio, spinyRatio;
  int type;
  float r, g, b;
  static const int PILLAR_POINT_NUM = 8;
  Vector[] pillarPos;
  Vector[] _pointPos;
  float[] _pointDeg;
  GLenum[] shapeModes;
  GLfloat[][] shapeVertices;
  GLfloat[4][] shapeColors;

  invariant() {
    assert(wakePos.x < 15 && wakePos.x > -15);
    assert(wakePos.y < 60 && wakePos.y > -40);
    assert(size > 0 && size < 20);
    assert(distRatio >= 0 && distRatio <= 1);
    assert(spinyRatio >= 0 && spinyRatio <= 1);
    assert(type >= 0);
    assert(r >= 0 && r <= 1);
    assert(g >= 0 && g <= 1);
    assert(b >= 0 && b <= 1);
    foreach (const(Vector) p; pillarPos) {
      assert(p.x < 20 && p.x > -20);
      assert(p.y < 20 && p.x > -20);
    }
    foreach (const(Vector) p; _pointPos) {
      assert(p.x < 20 && p.x > -20);
      assert(p.y < 20 && p.x > -20);
    }
    foreach (float d; _pointDeg)
      assert(d <>= 0);
  }

  public static void init0() {
    rand = new Rand;
    wakePos = new Vector;
  }

  public static void setRandSeed(long seed) {
    rand.setSeed(seed);
  }

  public this(float size, float distRatio, float spinyRatio,
              int type, float r, float g, float b) {
    this.size = size;
    this.distRatio = distRatio;
    this.spinyRatio = spinyRatio;
    this.type = type;
    this.r = r;
    this.g = g;
    this.b = b;
    super();
  }

  public override void prepareShape() {
    float height = size * 0.5f;
    float z = 0;
    float sz = 1;
    if (type == ShapeType.BRIDGE)
      z += height;

    shapeModes.length = 1;
    shapeVertices.length = 1;
    shapeColors.length = 1;

    int currentIndex = 0;

    shapeModes[currentIndex] = GL_LINE_LOOP;
    if (type != ShapeType.SHIP_DESTROYED) {
      shapeColors[currentIndex][0] = r * Screen.brightness;
      shapeColors[currentIndex][1] = g * Screen.brightness;
      shapeColors[currentIndex][2] = b * Screen.brightness;
      shapeColors[currentIndex][3] = 1;
    } else {
      shapeColors[currentIndex][0] = -1;
    }
    if (type != ShapeType.BRIDGE)
      createLoop(shapeVertices[currentIndex], sz, z, false, true);
    else
      createSquareLoop(shapeVertices[currentIndex], sz, z, false, true);

    if (type != ShapeType.SHIP_SHADOW && type != ShapeType.SHIP_DESTROYED &&
        type != ShapeType.PLATFORM_DESTROYED && type != ShapeType.TURRET_DESTROYED) {
      currentIndex++;
      shapeModes.length = currentIndex + 1;
      shapeVertices.length = currentIndex + 1;
      shapeColors.length = currentIndex + 1;

      shapeModes[currentIndex] = GL_TRIANGLE_FAN;

      shapeColors[currentIndex][0] = r * 0.4f * Screen.brightness;
      shapeColors[currentIndex][1] = g * 0.4f * Screen.brightness;
      shapeColors[currentIndex][2] = b * 0.4f * Screen.brightness;
      shapeColors[currentIndex][3] = 1;

      createLoop(shapeVertices[currentIndex], sz, z, true);
    }
    switch (type) {
    case ShapeType.SHIP:
    case ShapeType.SHIP_ROUNDTAIL:
    case ShapeType.SHIP_SHADOW:
    case ShapeType.SHIP_DAMAGED:
    case ShapeType.SHIP_DESTROYED:
      for (int i = 0; i < 3; i++) {
        z -= height / 4;
        sz -= 0.2f;

        currentIndex++;
        shapeModes.length = currentIndex + 1;
        shapeVertices.length = currentIndex + 1;
        shapeColors.length = currentIndex + 1;

        shapeModes[currentIndex] = GL_LINE_LOOP;

        if ((i == 0) && (type != ShapeType.SHIP_DESTROYED)) {
          shapeColors[currentIndex][0] = r * 0.4f * Screen.brightness;
          shapeColors[currentIndex][1] = g * 0.4f * Screen.brightness;
          shapeColors[currentIndex][2] = b * 0.4f * Screen.brightness;
          shapeColors[currentIndex][3] = 1;
        } else {
          shapeColors[currentIndex][0] = -1;
        }

        createLoop(shapeVertices[currentIndex], sz, z);
      }
      break;
    case ShapeType.PLATFORM:
    case ShapeType.PLATFORM_DAMAGED:
    case ShapeType.PLATFORM_DESTROYED:
      for (int i = 0; i < 3; i++) {
        z -= height / 3;
        bool firstIndex = (i == 0);
        foreach (Vector pp; pillarPos) {
          currentIndex++;
          shapeModes.length = currentIndex + 1;
          shapeVertices.length = currentIndex + 1;
          shapeColors.length = currentIndex + 1;

          shapeModes[currentIndex] = GL_LINE_LOOP;

          if (firstIndex) {
            firstIndex = false;
            shapeColors[currentIndex][0] = r * 0.4f * Screen.brightness;
            shapeColors[currentIndex][1] = g * 0.4f * Screen.brightness;
            shapeColors[currentIndex][2] = b * 0.4f * Screen.brightness;
            shapeColors[currentIndex][3] = 1;
          } else {
            shapeColors[currentIndex][0] = -1;
          }

          createPillar(shapeVertices[currentIndex], pp, size * 0.2f, z);
        }
      }
      break;
    case ShapeType.BRIDGE:
    case ShapeType.TURRET:
    case ShapeType.TURRET_DAMAGED:
      z += height;
      sz -= 0.33f;

      currentIndex++;
      shapeModes.length = currentIndex + 1;
      shapeVertices.length = currentIndex + 1;
      shapeColors.length = currentIndex + 1;

      shapeModes[currentIndex] = GL_LINE_LOOP;

      shapeColors[currentIndex][0] = r * 0.6f * Screen.brightness;
      shapeColors[currentIndex][1] = g * 0.6f * Screen.brightness;
      shapeColors[currentIndex][2] = b * 0.6f * Screen.brightness;
      shapeColors[currentIndex][3] = 1;

      if (type == ShapeType.BRIDGE)
        createSquareLoop(shapeVertices[currentIndex], sz, z);
      else
        createSquareLoop(shapeVertices[currentIndex], sz, z / 2, false, 3);


      currentIndex++;
      shapeModes.length = currentIndex + 1;
      shapeVertices.length = currentIndex + 1;
      shapeColors.length = currentIndex + 1;

      shapeModes[currentIndex] = GL_TRIANGLE_FAN;

      shapeColors[currentIndex][0] = r * 0.25f * Screen.brightness;
      shapeColors[currentIndex][1] = g * 0.25f * Screen.brightness;
      shapeColors[currentIndex][2] = b * 0.25f * Screen.brightness;
      shapeColors[currentIndex][3] = 1;

      if (type == ShapeType.BRIDGE)
        createSquareLoop(shapeVertices[currentIndex], sz, z, true);
      else
        createSquareLoop(shapeVertices[currentIndex], sz, z / 2, true, 3);

      break;
    case ShapeType.TURRET_DESTROYED:
      break;
    default:
      break;
    }
  }

  protected override void drawShape() {
    glEnableClientState(GL_VERTEX_ARRAY);

    foreach(i; 0..shapeModes.length) {
      if (shapeColors[i][0] != -1) {
        glColor4f(shapeColors[i][0], shapeColors[i][1], shapeColors[i][2], shapeColors[i][3]);
      }

      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices[i].ptr));

      glDrawArrays(shapeModes[i], 0, cast(int)(shapeVertices[i].length / 3));
    }

    glDisableClientState(GL_VERTEX_ARRAY);
  }

  private void createLoop(ref GLfloat[] partVertices, float s, float z, bool backToFirst = false, bool record = false) {
    float d = 0;
    int pn;
    bool firstPoint = true;
    float fpx, fpy;
    for (int i = 0; i < POINT_NUM; i++) {
      if (type != ShapeType.SHIP && type != ShapeType.SHIP_DESTROYED && type != ShapeType.SHIP_DAMAGED &&
          i > POINT_NUM * 2 / 5 && i <= POINT_NUM * 3 / 5)
        continue;
      if ((type == ShapeType.TURRET || type == ShapeType.TURRET_DAMAGED || type == ShapeType.TURRET_DESTROYED) &&
          (i <= POINT_NUM / 5 || i > POINT_NUM * 4 / 5))
        continue;
      d = PI * 2 * i / POINT_NUM;
      const float dSin = sin(d);
      const float dCos = cos(d);
      float cx = dSin * size * s * (1 - distRatio);
      float cy = dCos * size * s;
      float sx, sy;
      if (i == POINT_NUM / 4 || i == POINT_NUM / 4 * 3)
        sy = 0;
      else
        sy = 1 / (1 + fabs(tan(d)));
      assert(sy <>= 0);
      sx = 1 - sy;
      if (i >= POINT_NUM / 2)
        sx *= -1;
      if (i >= POINT_NUM / 4 && i <= POINT_NUM / 4 * 3)
        sy *= -1;
      sx *= size * s * (1 - distRatio);
      sy *= size * s;
      float px = cx * (1 - spinyRatio) + sx * spinyRatio;
      float py = cy * (1 - spinyRatio) + sy * spinyRatio;
      partVertices ~= [px, py, z];
      if (backToFirst && firstPoint) {
        fpx = px;
        fpy = py;
        firstPoint = false;
      }
      if (record) {
        if (i == POINT_NUM / 8 || i == POINT_NUM / 8 * 3 ||
            i == POINT_NUM / 8 * 5 || i == POINT_NUM / 8 * 7)
          pillarPos ~= new Vector(px * 0.8f, py * 0.8f);
        _pointPos ~= new Vector(px, py);
        _pointDeg ~= d;
      }
    }
    if (backToFirst)
      partVertices ~= [fpx, fpy, z];
  }

  private void createSquareLoop(ref GLfloat[] partVertices, float s, float z, bool backToFirst = false, float yRatio = 1) {
    float d;
    int pn;
    if (backToFirst)
      pn = 4;
    else
      pn = 3;
    for (int i = 0; i <= pn; i++) {
      d = PI * 2 * i / 4 + PI / 4;
      const float dSin = sin(d);
      const float dCos = cos(d);
      float px = dSin * size * s;
      float py = dCos * size * s;
      if (py > 0)
        py *= yRatio;

      partVertices ~= [px, py, z];
    }
  }

  private void createPillar(ref GLfloat[] partVertices, Vector p, float s, float z) {
    float d;
    for (int i = 0; i < PILLAR_POINT_NUM; i++) {
      d = PI * 2 * i / PILLAR_POINT_NUM;
      const float dSin = sin(d);
      const float dCos = cos(d);
      partVertices ~= [dSin * s + p.x, dCos * s + p.y, z];
    }
  }

  public void addWake(WakePool wakes, Vector pos, float deg, float spd, float sr = 1) {
    float sp = spd;
    if (sp > 0.1f)
      sp = 0.1f;
    float sz = size;
    if (sz > 10)
      sz = 10;
    const float degSin1 = sin(deg + cast(float)(PI / 2 + 0.7f));
    const float degCos1 = cos(deg + cast(float)(PI / 2 + 0.7f));
    wakePos.x = pos.x + degSin1 * size * 0.5f * sr;
    wakePos.y = pos.y + degCos1 * size * 0.5f * sr;
    Wake w = wakes.getInstanceForced();
    w.set(wakePos, deg + PI - 0.2f + rand.nextSignedFloat(0.1f), sp, 40, sz * 32 * sr);
    const float degSin2 = sin(deg - cast(float)(PI / 2 + 0.7f));
    const float degCos2 = cos(deg - cast(float)(PI / 2 + 0.7f));
    wakePos.x = pos.x + degSin2 * size * 0.5f * sr;
    wakePos.y = pos.y + degCos2 * size * 0.5f * sr;
    w = wakes.getInstanceForced();
    w.set(wakePos, deg + PI + 0.2f + rand.nextSignedFloat(0.1f), sp, 40, sz * 32 * sr);
  }

  public Vector[] pointPos() {
    return _pointPos;
  }

  public float[] pointDeg() {
    return _pointDeg;
  }

  public bool checkShipCollision(float x, float y, float deg, float sr = 1) {
    float cs = size * (1 - distRatio) * 1.1f * sr;
    if (dist(x, y, 0, 0) < cs)
      return true;
    float ofs = 0;
    for (;;) {
      ofs += cs;
      cs *= distRatio;
      if (cs < 0.2f)
        return false;
      const float degSin = sin(deg);
      const float degCos = cos(deg);
      if (dist(x, y, degSin * ofs, degCos * ofs) < cs ||
          dist(x, y, -degSin * ofs, -degCos * ofs) < cs)
        return true;
    }
  }

  private float dist(float x, float y, float px, float py) {
    float ax = fabs(x - px);
    float ay = fabs(y - py);
    if (ax > ay)
      return ax + ay / 2;
    else
      return ay + ax / 2;
  }
}

public class CollidableBaseShape: BaseShape, Collidable {
  mixin CollidableImpl;
 private:
  Vector _collision;

  public this(float size, float distRatio, float spinyRatio,
              int type,
              float r, float g, float b) {
    super(size, distRatio, spinyRatio, type, r, g, b);
    _collision = new Vector(size / 2, size / 2);
  }

  public Vector collision() {
    return _collision;
  }
}

public class TurretShape: ResizableDrawable {
 public:
  static enum TurretShapeType {
    NORMAL, DAMAGED, DESTROYED,
  };
 private:
  static BaseShape[] shapes;

  public static void init() {
    shapes ~= new CollidableBaseShape(1, 0, 0, BaseShape.ShapeType.TURRET, 1, 0.8f, 0.8f);
    shapes ~= new BaseShape(1, 0, 0, BaseShape.ShapeType.TURRET_DAMAGED, 0.9f, 0.9f, 1);
    shapes ~= new BaseShape(1, 0, 0, BaseShape.ShapeType.TURRET_DESTROYED, 0.8f, 0.33f, 0.66f);
  }

  public static void close() {
    foreach (BaseShape s; shapes)
      s.close();
  }

  public this(int t) {
    shape = shapes[t];
  }
}

public class EnemyShape: ResizableDrawable {
 public:
  static enum EnemyShapeType {
    SMALL, SMALL_DAMAGED, SMALL_BRIDGE,
    MIDDLE, MIDDLE_DAMAGED, MIDDLE_DESTROYED, MIDDLE_BRIDGE,
    PLATFORM, PLATFORM_DAMAGED, PLATFORM_DESTROYED, PLATFORM_BRIDGE,
  };
  static const float MIDDLE_COLOR_R = 1, MIDDLE_COLOR_G = 0.6f, MIDDLE_COLOR_B = 0.5f;
 private:
  static BaseShape[] shapes;

  public static void init() {
    shapes ~= new BaseShape
      (1, 0.5f, 0.1f, BaseShape.ShapeType.SHIP, 0.9f, 0.7f, 0.5f);
    shapes ~= new BaseShape
      (1, 0.5f, 0.1f, BaseShape.ShapeType.SHIP_DAMAGED, 0.5f, 0.5f, 0.9f);
    shapes ~= new CollidableBaseShape
      (0.66f, 0, 0, BaseShape.ShapeType.BRIDGE, 1, 0.2f, 0.3f);
    shapes ~= new BaseShape
      (1, 0.7f, 0.33f, BaseShape.ShapeType.SHIP, MIDDLE_COLOR_R, MIDDLE_COLOR_G, MIDDLE_COLOR_B);
    shapes ~= new BaseShape
      (1, 0.7f, 0.33f, BaseShape.ShapeType.SHIP_DAMAGED, 0.5f, 0.5f, 0.9f);
    shapes ~= new BaseShape
      (1, 0.7f, 0.33f, BaseShape.ShapeType.SHIP_DESTROYED, 0, 0, 0);
    shapes ~= new CollidableBaseShape
      (0.66f, 0, 0, BaseShape.ShapeType.BRIDGE, 1, 0.2f, 0.3f);
    shapes ~= new BaseShape
      (1, 0, 0, BaseShape.ShapeType.PLATFORM, 1, 0.6f, 0.7f);
    shapes ~= new BaseShape
      (1, 0, 0, BaseShape.ShapeType.PLATFORM_DAMAGED, 0.5f, 0.5f, 0.9f);
    shapes ~= new BaseShape
      (1, 0, 0, BaseShape.ShapeType.PLATFORM_DESTROYED, 1, 0.6f, 0.7f);
    shapes ~= new CollidableBaseShape
      (0.5f, 0, 0, BaseShape.ShapeType.BRIDGE, 1, 0.2f, 0.3f);
  }

  public static void close() {
    foreach (BaseShape s; shapes)
      s.close();
  }

  public this(int t) {
    shape = shapes[t];
  }

  public void addWake(WakePool wakes, Vector pos, float deg, float sp) {
    (cast(BaseShape) shape).addWake(wakes, pos, deg, sp, size);
  }

  public bool checkShipCollision(float x, float y, float deg) {
    return (cast(BaseShape) shape).checkShipCollision(x, y, deg, size);
  }
}

public class BulletShape: ResizableDrawable {
 public:
  static enum BulletShapeType {
    NORMAL, SMALL, MOVING_TURRET, DESTRUCTIVE,
  };
 private:
  static DrawableShape[] shapes;

  public static void init() {
    shapes ~= new NormalBulletShape;
    shapes ~= new SmallBulletShape;
    shapes ~= new MovingTurretBulletShape;
    shapes ~= new DestructiveBulletShape;
  }

  public static void close() {
    foreach (DrawableShape s; shapes)
      s.close();
  }

  public void set(int t) {
    shape = shapes[t];
  }
}

public class NormalBulletShape: DrawableShape {
 private:
  static const GLfloat[3*(3+3+6)] shapeVertices = [
     0.2f, -0.25f,  0.2f,
     0   ,  0.33f,  0   ,
    -0.2f, -0.25f, -0.2f,

    -0.2f, -0.25f,  0.2f,
     0   ,  0.33f,  0   ,
     0.2f, -0.25f, -0.2f,

     0   ,  0.33f,  0   ,
     0.2f, -0.25f,  0.2f,
    -0.2f, -0.25f,  0.2f,
    -0.2f, -0.25f, -0.2f,
     0.2f, -0.25f, -0.2f,
     0.2f, -0.25f,  0.2f
  ];

  public override void prepareShape() {
  }

  protected override void drawShape() {
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices.ptr));

    glDisable(GL_BLEND);
    Screen.setColor(1, 1, 0.3f);
    glDrawArrays(GL_LINE_STRIP, 0, 3);
    glDrawArrays(GL_LINE_STRIP, 3, 3);
    glEnable(GL_BLEND);

    Screen.setColor(0.5f, 0.2f, 0.1f);
    glDrawArrays(GL_TRIANGLE_FAN, 6, 6);

    glDisableClientState(GL_VERTEX_ARRAY);
  }
}

public class SmallBulletShape: DrawableShape {
 private:
  static const GLfloat[3*(3+3+6)] shapeVertices = [
     0.25f, -0.25f,  0.25f,
     0    ,  0.33f,  0    ,
    -0.25f, -0.25f, -0.25f,

    -0.25f, -0.25f,  0.25f,
     0    ,  0.33f,  0    ,
     0.25f, -0.25f, -0.25f,

     0    ,  0.33f,  0    ,
     0.25f, -0.25f,  0.25f,
    -0.25f, -0.25f,  0.25f,
    -0.25f, -0.25f, -0.25f,
     0.25f, -0.25f, -0.25f,
     0.25f, -0.25f,  0.25f
  ];

  public override void prepareShape() {
  }

  protected override void drawShape() {
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices.ptr));

    glDisable(GL_BLEND);
    Screen.setColor(0.6f, 0.9f, 0.3f);
    glDrawArrays(GL_LINE_STRIP, 0, 3);
    glDrawArrays(GL_LINE_STRIP, 3, 3);
    glEnable(GL_BLEND);

    Screen.setColor(0.2f, 0.4f, 0.1f);
    glDrawArrays(GL_TRIANGLE_FAN, 6, 6);

    glDisableClientState(GL_VERTEX_ARRAY);
  }
}

public class MovingTurretBulletShape: DrawableShape {
 private:
  static const GLfloat[3*(3+3+6)] shapeVertices = [
     0.25f, -0.25f,  0.25f,
     0    ,  0.33f,  0    ,
    -0.25f, -0.25f, -0.25f,

    -0.25f, -0.25f,  0.25f,
     0    ,  0.33f,  0    ,
     0.25f, -0.25f, -0.25f,

     0    ,  0.33f,  0    ,
     0.25f, -0.25f,  0.25f,
    -0.25f, -0.25f,  0.25f,
    -0.25f, -0.25f, -0.25f,
     0.25f, -0.25f, -0.25f,
     0.25f, -0.25f,  0.25f
  ];

  public override void prepareShape() {
  }

  protected override void drawShape() {
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices.ptr));

    glDisable(GL_BLEND);
    Screen.setColor(0.7f, 0.5f, 0.9f);
    glDrawArrays(GL_LINE_STRIP, 0, 3);
    glDrawArrays(GL_LINE_STRIP, 3, 3);
    glEnable(GL_BLEND);

    Screen.setColor(0.2f, 0.2f, 0.3f);
    glDrawArrays(GL_TRIANGLE_FAN, 6, 6);

    glDisableClientState(GL_VERTEX_ARRAY);
  }
}

public class DestructiveBulletShape: DrawableShape, Collidable {
  mixin CollidableImpl;
 private:
  static const GLfloat[3*4] shapeVertices = [
     0.2f,  0   , 0,
     0   ,  0.4f, 0,
    -0.2f,  0   , 0,
     0   , -0.4f, 0
  ];
  Vector _collision;

  public override void prepareShape() {
    _collision = new Vector(0.4f, 0.4f);
  }

  protected override void drawShape() {
    Screen.setColor(0.1f, 0.33f, 0.1f);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices.ptr));

    glDisable(GL_BLEND);
    Screen.setColor(0.9f, 0.9f, 0.6f);
    glDrawArrays(GL_LINE_LOOP, 0, 4);
    glEnable(GL_BLEND);

    Screen.setColor(0.7f, 0.5f, 0.4f);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

    glDisableClientState(GL_VERTEX_ARRAY);
  }

  public Vector collision() {
    return _collision;
  }
}

public class CrystalShape: DrawableShape {
 private:
  static const GLfloat[3*4] shapeVertices = [
    -0.2f,  0.2f, 0,
     0.2f,  0.2f, 0,
     0.2f, -0.2f, 0,
    -0.2f, -0.2f, 0
  ];

  public override void prepareShape() {
  }

  protected override void drawShape() {
    Screen.setColor(0.6f, 1, 0.7f);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices.ptr));

    glDrawArrays(GL_LINE_LOOP, 0, 4);

    glDisableClientState(GL_VERTEX_ARRAY);
  }
}

public class ShieldShape: DrawableShape {
 private:
  static GLfloat[3*10] shapeVertices;
  static GLfloat[4*10] shapeColors;

  public static this() {
    shapeVertices[0] = 0;
    shapeVertices[1] = 0;
    shapeVertices[2] = 0;

    shapeColors[0] = 0;
    shapeColors[1] = 0;
    shapeColors[2] = 0;
    shapeColors[3] = 1;

    float d = 0;
    for (int i = 0; i < 9; i++) {
      const float dSin = sin(d);
      const float dCos = cos(d);
      shapeVertices[3*(i+1) + 0] = dSin;
      shapeVertices[3*(i+1) + 1] = dCos;
      shapeVertices[3*(i+1) + 2] = 0;

      shapeColors[4*(i+1) + 0] = 0.3f * Screen.brightness;
      shapeColors[4*(i+1) + 1] = 0.3f * Screen.brightness;
      shapeColors[4*(i+1) + 2] = 0.5f * Screen.brightness;
      shapeColors[4*(i+1) + 3] = 1;

      d += PI / 4;
    }
  }

  public override void prepareShape() {
  }

  protected override void drawShape() {
    Screen.setColor(0.5f, 0.5f, 0.7f);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices.ptr));

    glDrawArrays(GL_LINE_LOOP, 1, 8);

    glEnableClientState(GL_COLOR_ARRAY);
    glColorPointer(4, GL_FLOAT, 0, cast(void *)(shapeColors.ptr));

    glDrawArrays(GL_TRIANGLE_FAN, 0, 10);

    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
  }
}
