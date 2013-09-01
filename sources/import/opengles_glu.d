/*
 * SGI FREE SOFTWARE LICENSE B (Version 2.0, Sept. 18, 2008)
 * Copyright (C) 1991-2000 Silicon Graphics, Inc. All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice including the dates of first publication and
 * either this permission notice or a reference to
 * http://oss.sgi.com/projects/FreeB/
 * shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * SILICON GRAPHICS, INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of Silicon Graphics, Inc.
 * shall not be used in advertising or otherwise to promote the sale, use or
 * other dealings in this Software without prior written authorization from
 * Silicon Graphics, Inc.
 */

import std.math;
import opengles;

const uint GL_GENERATE_MIPMAP = 0x8191;
const uint GL_GENERATE_MIPMAP_HINT = 0x8192;


private void __gluMakeIdentityf(ref GLfloat[16] m)
{
    m[0+4*0] = 1; m[0+4*1] = 0; m[0+4*2] = 0; m[0+4*3] = 0;
    m[1+4*0] = 0; m[1+4*1] = 1; m[1+4*2] = 0; m[1+4*3] = 0;
    m[2+4*0] = 0; m[2+4*1] = 0; m[2+4*2] = 1; m[2+4*3] = 0;
    m[3+4*0] = 0; m[3+4*1] = 0; m[3+4*2] = 0; m[3+4*3] = 1;
}

private void normalize(ref float[3] v)
{
    float r;

    r = sqrt( v[0]*v[0] + v[1]*v[1] + v[2]*v[2] );
    if (r == 0.0) return;

    v[0] /= r;
    v[1] /= r;
    v[2] /= r;
}

private void cross(float[3] v1, float[3] v2, ref float[3] result)
{
    result[0] = v1[1]*v2[2] - v1[2]*v2[1];
    result[1] = v1[2]*v2[0] - v1[0]*v2[2];
    result[2] = v1[0]*v2[1] - v1[1]*v2[0];
}

void gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez,
               GLfloat centerx, GLfloat centery, GLfloat centerz,
               GLfloat upx, GLfloat upy, GLfloat upz)
{
    float[3] forward, side, up;
    GLfloat[16] m;

    forward[0] = centerx - eyex;
    forward[1] = centery - eyey;
    forward[2] = centerz - eyez;

    up[0] = upx;
    up[1] = upy;
    up[2] = upz;

    normalize(forward);

    // Side = forward x up
    cross(forward, up, side);
    normalize(side);

    // Recompute up as: up = side x forward
    cross(side, forward, up);

    __gluMakeIdentityf(m);
    m[0+4*0] = side[0];
    m[0+4*1] = side[1];
    m[0+4*2] = side[2];

    m[1+4*0] = up[0];
    m[1+4*1] = up[1];
    m[1+4*2] = up[2];

    m[2+4*0] = -forward[0];
    m[2+4*1] = -forward[1];
    m[2+4*2] = -forward[2];

    glMultMatrixf(m.ptr);
    glTranslatef(-eyex, -eyey, -eyez);
}

void gluOrtho2D(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top)
{
    glOrthof(left, right, bottom, top, -1, 1);
}

void gluPerspective(GLfloat fovy, GLfloat aspect, GLfloat zNear, GLfloat zFar)
{
    GLfloat[16] m;
    float sine, cosine, cotangent, deltaZ;
    float radians = fovy * std.math.PI / 360;

    deltaZ = zFar - zNear;
    sine = sin(radians);
    cosine = cos(radians);
    if ((deltaZ == 0.0) || (sine == 0.0) || (aspect == 0.0)) {
        return;
    }
    cotangent = cosine / sine;

    __gluMakeIdentityf(m);
    m[0+4*0] = cotangent / aspect;
    m[1+4*1] = cotangent;
    m[2+4*2] = -(zFar + zNear) / deltaZ;
    m[3+4*2] = -1;
    m[2+4*3] = -2 * zNear * zFar / deltaZ;
    m[3+4*3] = 0;
    glMultMatrixf(m.ptr);
}

private uint resample_rgba(uint src1, uint src2, uint src_pos) {
    ubyte[4] bsrc1, bsrc2, dst;
    (cast(uint*)(bsrc1.ptr))[0] = src1;
    (cast(uint*)(bsrc2.ptr))[0] = src2;

    foreach (i; 0..4) {
        dst[i] = cast(ubyte)( (cast(uint)(bsrc1[i]) * (0x10000 - src_pos) + cast(uint)(bsrc2[i]) * src_pos) >> 16 );
    }

    return (cast(uint*)(dst.ptr))[0];
}

GLint gluBuild2DMipmaps(GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *data) {
    if (target != GL_TEXTURE_2D || (internalFormat != 4 && internalFormat != GL_RGBA) || format != GL_RGBA || type != GL_UNSIGNED_BYTE) {
        throw new Exception("gluBuild2DMipmaps: unimplemented parameters");
    }

    int potWidth = cast(int) exp2(trunc(log2(width)));
    int potHeight = cast(int) exp2(trunc(log2(height)));

    if (width - potWidth >= 2*potWidth - width) potWidth *= 2;
    if (height - potHeight >= 2*potHeight - height) potHeight *= 2;

    if (width == potWidth && height == potHeight) {
        glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
        glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, data);
        return 0;
    }

    const uint* orig_data = cast(uint*)data;
    uint[] new_data;

    new_data.length = potWidth * potHeight;

    if (height == potHeight) {
        // resize horizontally

        uint dst_lastsize = (((potWidth << 16) / width) + 0xffff) >> 16;
        uint dst_size = potWidth - dst_lastsize;
        uint src_delta = (width << 16) / potWidth;
        uint src_pos_base = (width > potWidth)?( ((width - potWidth) << 16) / width ):0;

        foreach (y; 0..potHeight) {
            uint src_pos = src_pos_base;
            const (uint)* srcbuf = &(orig_data[y * width]);
            const (uint)* srclastbuf = &(srcbuf[width - 2]);
            uint* dstbuf = &(new_data[y * potWidth]);

            foreach (x; 0..dst_size) {
                dstbuf[0] = resample_rgba(srcbuf[0], srcbuf[1], src_pos);

                src_pos += src_delta;
                srcbuf = &(srcbuf[src_pos >> 16]);
                src_pos &= 0xffff;
                dstbuf = &(dstbuf[1]);
            }

            src_pos = 0x10000;
            srcbuf = srclastbuf;
            foreach (x; 0..dst_lastsize) {
                dstbuf[0] = resample_rgba(srcbuf[0], srcbuf[1], src_pos);

                dstbuf = &(dstbuf[1]);
            }
        }
    } else if (width == potWidth) {
        // resize vertically
        throw new Exception("gluBuild2DMipmaps: unimplemented resize");
    } else {
        // resize horizontally and vertically
        throw new Exception("gluBuild2DMipmaps: unimplemented resize");
    }

    glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
    glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, potWidth, potHeight, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, new_data.ptr);

    new_data.length = 0;

    return 0;
}

