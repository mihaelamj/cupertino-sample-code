/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to manage the error handling for the app.
*/

#pragma once

#include <MacTypes.h>

#include <exception>
#include <string>

struct AudioToolboxError : public std::runtime_error {
	AudioToolboxError(const std::string& what_arg, OSStatus status);

	OSStatus status;
};
