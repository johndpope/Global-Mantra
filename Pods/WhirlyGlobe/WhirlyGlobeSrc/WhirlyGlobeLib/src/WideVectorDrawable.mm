/*
 *  WideVectorDrawable.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 5/29/14.
 *  Copyright 2011-2014 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "WideVectorDrawable.h"
#import "OpenGLES2Program.h"
#import "SceneRendererES.h"
#import "FlatMath.h"

namespace WhirlyKit
{
    
WideVectorDrawable::WideVectorDrawable() : BasicDrawable("WideVector"), width(10.0/1024.0), texRepeat(1.0)
{
    offsetIndex = addAttribute(BDFloat3Type, "a_dir");
}
    
void WideVectorDrawable::addDir(const Point3f &dir)
{
    addAttributeValue(offsetIndex, dir);
}
    
void WideVectorDrawable::addDir(const Point3d &dir)
{
    addAttributeValue(offsetIndex, Point3f(dir.x(),dir.y(),dir.z()));
}
    
void WideVectorDrawable::draw(WhirlyKitRendererFrameInfo *frameInfo, Scene *scene)
{
    if (frameInfo.program)
    {
        float scale = frameInfo.sceneRenderer.framebufferWidth;
        float screenSize = frameInfo.screenSizeInDisplayCoords.x();
        frameInfo.program->setUniform("u_length", width/scale);
        float texScale = scale/(screenSize*texRepeat);
        frameInfo.program->setUniform("u_texScale", texScale);
    }
    
    BasicDrawable::draw(frameInfo,scene);
}

static const char *vertexShaderTri =
"uniform mat4  u_mvpMatrix;"
"uniform mat4  u_mvMatrix;"
"uniform mat4  u_pMatrix;"
"uniform float u_fade;"
"uniform float u_length;"
"uniform float u_texScale;"
""
"attribute vec3 a_position;"
"attribute vec2 a_texCoord0;"
"attribute vec4 a_color;"
"attribute vec3 a_dir;"
""
"varying vec2 v_texCoord;"
"varying vec4 v_color;"
""
"void main()"
"{"
"   v_texCoord = vec2(a_texCoord0.x, a_texCoord0.y * u_texScale);"
    "   v_color = a_color;"
    " vec4 vertPos = u_mvpMatrix * vec4(a_position,1.0);"
    " vertPos /= vertPos.w;"
    " vec2 screenDir = (u_mvpMatrix * vec4(a_dir,0.0)).xy;"
    " gl_Position = vertPos + vec4(screenDir * u_length,0,0);"
"}"
;

static const char *fragmentShaderTri =
"precision mediump float;                            \n"
"\n"
"uniform sampler2D s_baseMap0;                        \n"
"uniform bool  u_hasTexture;                         \n"
"\n"
"varying vec2      v_texCoord;                       \n"
"varying vec4      v_color;                          \n"
"\n"
"void main()                                         \n"
"{                                                   \n"
"  vec4 baseColor = u_hasTexture ? texture2D(s_baseMap0, v_texCoord) : vec4(1.0,1.0,1.0,1.0); \n"
"  gl_FragColor = v_color * baseColor;  \n"
"}                                                   \n"
;

WhirlyKit::OpenGLES2Program *BuildWideVectorProgram()
{
    OpenGLES2Program *shader = new OpenGLES2Program(kWideVectorShaderName,vertexShaderTri,fragmentShaderTri);
    if (!shader->isValid())
    {
        delete shader;
        shader = NULL;
    }
    
    // Set some reasonable defaults
    if (shader)
    {
        glUseProgram(shader->getProgram());
        
        shader->setUniform("u_length", 10.f/1024);
        shader->setUniform("u_texScale", 1.f);
    }
    
    
    return shader;
}
    
    
    
}
