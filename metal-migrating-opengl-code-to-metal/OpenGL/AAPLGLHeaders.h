/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the collection of OpenGL headers and definitions.
*/
#ifndef AAPLGLHeaders_h
#define AAPLGLHeaders_h


#if TARGET_MACOS

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/gl3.h>

#else // if (TARGET_IOS || TARGET_TVOS)

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES3/gl.h>

#endif // !(TARGET_IOS || TARGET_TVOS)

// The name of the vertex array objects are slightly different in OpenGL ES, OpenGL Core
// Profile, and OpenGL Legacy. Howeverm the arguments are exactly the same across these APIs.

#if (TARGET_IOS || TARGET_TVOS)
#define glBindVertexArray glBindVertexArrayOES
#define glGenVertexArrays glGenVertexArraysOES
#define glDeleteVertexArrays glDeleteVertexArraysOES
#endif // !(TARGET_IOS || TARGET_TVOS)


#define BUFFER_OFFSET(i) ((char *)NULL + (i))


static inline const char * GetGLErrorString(GLenum error)
{
    const char *str;
    switch( error )
    {
        case GL_NO_ERROR:
            str = "GL_NO_ERROR";
            break;
        case GL_INVALID_ENUM:
            str = "GL_INVALID_ENUM";
            break;
        case GL_INVALID_VALUE:
            str = "GL_INVALID_VALUE";
            break;
        case GL_INVALID_OPERATION:
            str = "GL_INVALID_OPERATION";
            break;
        case GL_OUT_OF_MEMORY:
            str = "GL_OUT_OF_MEMORY";
            break;
        case GL_INVALID_FRAMEBUFFER_OPERATION:
            str = "GL_INVALID_FRAMEBUFFER_OPERATION";
            break;
#if defined __gl_h_
        case GL_STACK_OVERFLOW:
            str = "GL_STACK_OVERFLOW";
            break;
        case GL_STACK_UNDERFLOW:
            str = "GL_STACK_UNDERFLOW";
            break;
        case GL_TABLE_TOO_LARGE:
            str = "GL_TABLE_TOO_LARGE";
            break;
#endif
        default:
            str = "(ERROR: Unknown Error Enum)";
            break;
    }
    return str;
}

#define GetGLError()                                  \
{                                                     \
    GLenum err = glGetError();                        \
    while (err != GL_NO_ERROR)                        \
    {                                                 \
        NSLog(@"GLError %s set in File:%s Line:%d\n", \
        GetGLErrorString(err), __FILE__, __LINE__);   \
        err = glGetError();                           \
    }                                                 \
}

#endif
