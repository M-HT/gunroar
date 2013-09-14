/*
 * $Id: shot.d,v 1.2 2005/07/03 07:05:22 kenta Exp $
 *
 * Copyright 2005 Kenta Cho. Some rights reserved.
 */
module abagames.gr.shot;

private import std.math;
private import std.string;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
private import abagames.util.actor;
private import abagames.util.vector;
private import abagames.util.rand;
private import abagames.util.sdl.shape;
private import abagames.gr.field;
private import abagames.gr.screen;
private import abagames.gr.enemy;
private import abagames.gr.particle;
private import abagames.gr.bullet;
private import abagames.gr.soundmanager;

/**
 * Player's shot.
 */
public class Shot: Actor {
 public:
  static const float SPEED = 0.6f;
  static const float LANCE_SPEED = 0.5f;//0.4f;
 private:
  static ShotShape shape;
  static LanceShape lanceShape;
  static Rand rand;
  Field field;
  EnemyPool enemies;
  SparkPool sparks;
  SmokePool smokes;
  BulletPool bullets;
  Vector pos;
  int cnt;
  int hitCnt;
  float _deg;
  int _damage;
  bool lance;

  invariant() {
    assert(pos.x < 15 && pos.x > -15);
    assert(pos.y < 20 && pos.y > -20);
    assert(cnt >= 0);
    assert(hitCnt >= 0);
    assert(_deg <>= 0);
    assert(_damage >= 1);
  }

  public static void init() {
    shape = new ShotShape;
    lanceShape = new LanceShape;
    rand = new Rand;
  }

  public static void setRandSeed(long seed) {
    rand.setSeed(seed);
  }

  public static void close() {
    shape.close();
  }

  public this() {
    pos = new Vector;
    cnt = hitCnt = 0;
    _deg = 0;
    _damage = 1;
    lance = false;
  }

  public override void init(Object[] args) {
    field = cast(Field) args[0];
    enemies = cast(EnemyPool) args[1];
    sparks = cast(SparkPool) args[2];
    smokes = cast(SmokePool) args[3];
    bullets = cast(BulletPool) args[4];
  }

  public void set(Vector p, float d, bool lance = false, int dmg = -1) {
    pos.x = p.x;
    pos.y = p.y;
    cnt = hitCnt = 0;
    _deg = d;
    this.lance = lance;
    if (lance)
      _damage = 10;
    else
      _damage = 1;
    if (dmg >= 0)
      _damage = dmg;
    exists = true;
  }

  public override void move() {
    cnt++;
    if (hitCnt > 0) {
      hitCnt++;
      if (hitCnt > 30)
        remove();
      return;
    }
    float sp;
    if (!lance) {
      sp = SPEED;
    } else {
      if (cnt < 10)
        sp = LANCE_SPEED * cnt / 10;
      else
        sp = LANCE_SPEED;
    }
    const float degSin = sin(_deg);
    const float degCos = cos(_deg);
    pos.x += degSin * sp;
    pos.y += degCos * sp;
    pos.y -= field.lastScrollY;
    if (field.getBlock(pos) >= Field.ON_BLOCK_THRESHOLD ||
        !field.checkInOuterField(pos) || pos.y > field.size.y)
      remove();
    if (lance) {
      enemies.checkShotHit(pos, lanceShape, this);
    } else {
      bullets.checkShotHit(pos, shape, this);
      enemies.checkShotHit(pos, shape, this);
    }
  }

  public void remove() {
    if (lance && hitCnt <= 0) {
      hitCnt = 1;
      return;
    }
    exists = false;
  }

  public void removeHitToBullet() {
    removeHit();
  }

  public void removeHitToEnemy(bool isSmallEnemy = false) {
    if (isSmallEnemy && lance)
      return;
    SoundManager.playSe("hit.wav");
    removeHit();
  }

  private void removeHit() {
    remove();
    int sn;
    if (lance) {
      for (int i = 0; i < 10; i++) {
        Smoke s = smokes.getInstanceForced();
        float d = _deg + rand.nextSignedFloat(0.1f);
        float sp = rand.nextFloat(LANCE_SPEED);
        const float dSin1 = sin(d);
        const float dCos1 = cos(d);
        s.set(pos, dSin1 * sp, dCos1 * sp, 0,
              Smoke.SmokeType.LANCE_SPARK, 30 + rand.nextInt(30), 1);
        s = smokes.getInstanceForced();
        d = _deg + rand.nextSignedFloat(0.1f);
        sp = rand.nextFloat(LANCE_SPEED);
        const float dSin2 = sin(d);
        const float dCos2 = cos(d);
        s.set(pos, -dSin2 * sp, -dCos2 * sp, 0,
              Smoke.SmokeType.LANCE_SPARK, 30 + rand.nextInt(30), 1);
      }
    } else {
      Spark s = sparks.getInstanceForced();
      float d = _deg + rand.nextSignedFloat(0.5f);
      const float dSin3 = sin(d);
      const float dCos3 = cos(d);
      s.set(pos, dSin3 * SPEED, dCos3 * SPEED,
            0.6f + rand.nextSignedFloat(0.4f), 0.6f + rand.nextSignedFloat(0.4f), 0.1f, 20);
      s = sparks.getInstanceForced();
      d = _deg + rand.nextSignedFloat(0.5f);
      const float dSin4 = sin(d);
      const float dCos4 = cos(d);
      s.set(pos, -dSin4 * SPEED, -dCos4 * SPEED,
            0.6f + rand.nextSignedFloat(0.4f), 0.6f + rand.nextSignedFloat(0.4f), 0.1f, 20);
    }
  }

  public override void draw() {
    if (lance) {
      float x = pos.x, y = pos.y;
      float size = 0.25f, a = 0.6f;
      int hc = hitCnt;
      const float degSin = sin(_deg);
      const float degCos = cos(_deg);
      const float degSinSpeed = degSin * LANCE_SPEED * 2;
      const float degCosSpeed = degCos * LANCE_SPEED * 2;
      for (int i = 0; i < cnt / 4 + 1; i++) {
        size *= 0.9f;
        a *= 0.8f;
        if (hc > 0) {
          hc--;
          continue;
        }
        float d = i * 13 + cnt * 3;
        for (int j = 0; j < 6; j++) {
          glPushMatrix();
          glTranslatef(x, y, 0);
          glRotatef(-_deg * 180 / PI, 0, 0, 1);
          glRotatef(d, 0, 1, 0);
          {
            const GLfloat[3*4] shotVertices = [
              -size,  LANCE_SPEED, size / 2,
               size,  LANCE_SPEED, size / 2,
               size, -LANCE_SPEED, size / 2,
              -size, -LANCE_SPEED, size / 2
            ];

            glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shotVertices.ptr));

            Screen.setColor(0.4f, 0.8f, 0.8f, a);
            glDrawArrays(GL_LINE_LOOP, 0, 4);

            Screen.setColor(0.2f, 0.5f, 0.5f, a / 2);
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

            glDisableClientState(GL_VERTEX_ARRAY);

          }
          glPopMatrix();
          d += 60;
        }
        x -= degSinSpeed;
        y -= degCosSpeed;
      }
    } else {
      glPushMatrix();
      Screen.glTranslate(pos);
      glRotatef(-_deg * 180 / PI, 0, 0, 1);
      glRotatef(cnt * 31, 0, 1, 0);
      shape.draw();
      glPopMatrix();
    }
  }

  public float deg() {
    return _deg;
  }

  public int damage() {
    return _damage;
  }

  public bool removed() {
    if (hitCnt > 0)
      return true;
    else
      return false;
  }
}

public class ShotPool: ActorPool!(Shot) {
  public this(int n, Object[] args) {
    super(n, args);
  }

  public bool existsLance() {
    foreach (Shot s; actor)
      if (s.exists)
        if (s.lance && !s.removed)
          return true;
    return false;
  }
}

public class ShotShape: CollidableDrawable {
  static const GLfloat[3*(3*4)] shapeVertices = [
     0     ,  0.3f,  0.1f  ,
     0.066f,  0.3f, -0.033f,
     0.1f  , -0.3f, -0.05f ,
     0     , -0.3f,  0.15f ,
     0.066f,  0.3f, -0.033f,
    -0.066f,  0.3f, -0.033f,
    -0.1f  , -0.3f, -0.05f ,
     0.1f  , -0.3f, -0.05f ,
    -0.066f,  0.3f, -0.033f,
     0     ,  0.3f,  0.1f  ,
     0     , -0.3f,  0.15f ,
    -0.1f  , -0.3f, -0.05f
  ];

  protected override void prepareShape() {
  }

  protected override void drawShape() {
    Screen.setColor(0.1f, 0.33f, 0.1f);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices.ptr));

    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 4, 4);
    glDrawArrays(GL_TRIANGLE_FAN, 8, 4);

    glDisableClientState(GL_VERTEX_ARRAY);
  }

  protected override void setCollision() {
    _collision = new Vector(0.33f, 0.33f);
  }
}

public class LanceShape: Collidable {
  mixin CollidableImpl;
 private:
  Vector _collision;

  public this() {
    _collision = new Vector(0.66f, 0.66f);
  }

  public Vector collision() {
    return _collision;
  }
}
