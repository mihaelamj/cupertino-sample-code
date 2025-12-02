# Creating a 3D application with Hydra rendering

Build a 3D application that integrates with Hydra and USD.

## Overview

- Note: This sample code project is associated with WWDC22 session 10141: [Explore USD tools and rendering](https://developer.apple.com/wwdc22/10141/).

## Configure the sample code project

This sample requires Xcode 14 or later and macOS 13 or later. To build the project, you first need to [get and build the USD source code](https://github.com/PixarAnimationStudios/USD/blob/release/README.md#getting-and-building-the-code) from Pixar's GitHub repository, and then use CMake to generate an Xcode project with references to both the compiled USD libraries and the header files in the USD source code. If you don't already have CMake installed, [download the latest version of CMake](https://cmake.org/download/) to your Applications folder.

CMake is both a GUI and command-line app. To use the command-line tool, open a Terminal window and add the `/Contents/bin` folder from the `CMake.app` application bundle to your `PATH` environment variable, like this:

```
path+=('/Applications/CMake.app/Contents/bin/')
export PATH
```

- Note: The previous command assumes you use the default `zsh` shell and adds `cmake` to your path for only the current terminal session. To add `cmake` to your path permanently, or if you're using another shell like `bash`, add `/Applications/CMake.app/Contents/bin/` to the `$PATH` declaration in your `.zshrc` file or in the configuration file your shell uses.

Clone the USD repo, using the following command:

```
git clone https://github.com/PixarAnimationStudios/USD
```



Next, build USD using the following command: `python3 <path to usd source>/build_scripts/build_usd.py --generator Xcode --no-python <path to install the built USD>`. For example, if you've cloned the USD source code into `~/dev/USD`, the build command might look like this: 

``` 
python3 ~/dev/USD/build_scripts/build_usd.py --generator Xcode --no-python ./USDInstall
```

Configure the `USD_Path` environment variable: `export USD_PATH=<path to usd install>`. For example, if you've installed USD at `~/dev/USDInstall`, use this command:

```
 export USD_PATH=~/dev/USDInstall
```

Run the following CMake command to generate an Xcode project: `cmake -S <path to project source folder> -B <path to directory where it creates the Xcode project>`. If the sample code is at `~/dev/`, the command might look like this:
 ```
 cmake -S ~/dev/CreatingA3DApplicationWithHydraRendering/ -B ~/dev/CreatingA3DApplicationWithHydraRendering/
 ```

Finally, open the generated Xcode project, and change the scheme to `hydraplayer`.

- Important: You're responsible for abiding by the terms of the license(s) associated with the code from the USD repo.
