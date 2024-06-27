# Gauntlet

A remake of the arcade game [Gauntlet](https://en.wikipedia.org/wiki/Gauntlet_(1985_video_game)) with 3D graphics inspired on [Gauntlet Slayer Edition](https://store.steampowered.com/app/258970/Gauntlet_Slayer_Edition/).

The point of this remake is to develop an engine with similar capabilities and support for the Raspberry Pi 4.



## How to build

This project supports building and cross-compiling with the latest Visual Studio versions (2019+) with the [CMake plugin](https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170) installed.

Launch Visual Studio and open a new CMake project by navigating to *"File->Open->CMake"* and opening the main CMakeLists.txt.

Alternatively, you can right click on the root folder which has this file and in the drop box menu select *"Open with Visual Studio"*

After opening Visual Studio will start generating the cache, once it completes without errors there should be five configurations to pick from:

- Win64-Editor-(Config)-MSVC
- Win64-Game-(Config)-MSVC

Where (Config) is either Debug, Release, or Shipping. Editor configurations will include the editor and should not be used for shipping builds.

There should also be two targets called *"Gauntlet.exe"* and *"Gauntlet.exe (Install) (bin\)Guantlet.exe"*, which are the game runtimes, the latter used to package the project.



### For RPi/Linux (WIP)

When switching to the ARM based platform rsync will need to copy all the assets and source files over, this might take a while so if the connection times-out try deleting the cache and re-generating it.

If you want audio on the raspberry pi you will need to [get the ALSA dev packages](http://www.portaudio.com/docs/v19-doxydocs/compile_linux.html) with:

`sudo apt-get install libasound-dev`
