/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for a user-generated dynamic library.
*/

#ifndef AAPLUserDylib_h
#define AAPLUserDylib_h

// By default, a dynamic library exports all symbols, which can cause
// namespace clashes.
// The sample selectively exports only the symbols that the app code looks for.
#define EXPORT __attribute__((visibility("default")))
namespace AAPLUserDylib
{
    EXPORT float4 calculateColorInside(int iteration, float distance);
    EXPORT float4 calculateColorEscaped(int iteration, float distance);
}
#undef EXPORT

#endif /* UserDylib_h */
