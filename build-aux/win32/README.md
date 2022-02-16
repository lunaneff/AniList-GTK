# AniList-GTK Windows port

To build an installer for Windows, follow these instructions:

1. Install [MSYS2](https://msys2.org/)
2. Install the `base-devel` meta-package:
   ```
   pacman -S base-devel
   ```
3. Run `build.ps1` with options as described below

## Build options

The build script supports a few options:

| Name         | Default                                  | Description                                                                                                                                       |
| ------------ | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Msys2Path    | C:\msys64                                | The path to the MSYS2 installation that will be used                                                                                              |
| Msys2Env     | clang64                                  | The MSYS2 environment that will be used. See [here][environments] for details. Only clang64 is supported. Others may work, but you're on your own |
| MakeNsisPath | C:\Program Files (x86)\NSIS\makensis.exe | The path to makensis.exe                                                                                                                          |

[environments]: https://www.msys2.org/docs/environments/

