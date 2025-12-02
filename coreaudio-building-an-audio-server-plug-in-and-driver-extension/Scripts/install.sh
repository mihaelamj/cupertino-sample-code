#!/bin/bash

# Clean up existing install, if present
sudo darwinup uninstall SimpleAudio.tgz

# Build the individual targets
sudo xcodebuild -project SimpleAudio.xcodeproj -scheme SimpleAudioDriver DSTROOT=/tmp/SimpleAudio/dstroot SYMROOT=/tmp/SimpleAudio/symroot OBJROOT=/tmp/SimpleAudio/objroot install 
sudo xcodebuild -project SimpleAudio.xcodeproj -scheme SimpleAudioPlugIn DSTROOT=/tmp/SimpleAudio/dstroot SYMROOT=/tmp/SimpleAudio/symroot OBJROOT=/tmp/SimpleAudio/objroot install 

# tar the build products
tar czf /tmp/SimpleAudio.tgz -C /tmp/SimpleAudio/dstroot . && chown $USER /tmp/SimpleAudio.tgz

# install
sudo darwinup install /tmp/SimpleAudio.tgz
