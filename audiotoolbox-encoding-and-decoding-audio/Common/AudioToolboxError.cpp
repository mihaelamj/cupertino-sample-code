/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to manage the error handling for the app.
*/

#include "AudioToolboxError.hpp"

AudioToolboxError::AudioToolboxError(const std::string& what_arg, OSStatus status)
	: std::runtime_error(what_arg), status(status)
{
}
