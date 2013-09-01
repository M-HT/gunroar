module abagames.gr.drawdata;

version (USE_GLES) {
  import opengles;
} else {
  import opengl;
}

/**
 * Data for drawing graphic primitives.
 */
public class DrawData {
 public:
  GLfloat[] vertices;
  GLfloat[] colors;

  public void clearData()
  {
    vertices = [];
    colors = [];
  }

  public void draw(GLenum mode)
  {
    const int numColors = cast(int)(colors.length / 4);
    const int numVertices = (numColors == 0)?(cast(int)(vertices.length / 3)):(numColors);

    if (numVertices > 0) {
      glEnableClientState(GL_VERTEX_ARRAY);
      if (numColors != 0) glEnableClientState(GL_COLOR_ARRAY);

      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(vertices.ptr));
      if (numColors != 0) glColorPointer(4, GL_FLOAT, 0, cast(void *)(colors.ptr));
      glDrawArrays(mode, 0, numVertices);

      if (numColors != 0) glDisableClientState(GL_COLOR_ARRAY);
      glDisableClientState(GL_VERTEX_ARRAY);
    }
  }

  public void drawQuads()
  {
    const int numColors = cast(int)(colors.length / 4);
    const int numVertices = (numColors == 0)?(cast(int)(vertices.length / 3)):(numColors);

    if (numVertices > 0) {
      glEnableClientState(GL_VERTEX_ARRAY);
      if (numColors != 0) glEnableClientState(GL_COLOR_ARRAY);

      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(vertices.ptr));
      if (numColors != 0) glColorPointer(4, GL_FLOAT, 0, cast(void *)(colors.ptr));
      foreach(i; 0..(numVertices / 4)) {
        glDrawArrays(GL_TRIANGLE_FAN, 4*i, 4);
      }

      if (numColors != 0) glDisableClientState(GL_COLOR_ARRAY);
      glDisableClientState(GL_VERTEX_ARRAY);
    }
  }
}

