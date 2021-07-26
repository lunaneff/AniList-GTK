# AniList-GTK

A native desktop client for AniList

## Building & Installing

### Linux

#### Native

##### Dependencies
- Vala
- GTK4
- Libadwaita
- Meson (only needed for building)
- Ninja (only needed for building)

```shell
$ meson build
$ ninja -C build
$ sudo ninja -C build install

# To uninstall:
$ sudo ninja -C build uninstall
```

#### Flatpak
You can open this project in GNOME Builder and export a Flatpak bundle from
there. I don't know how to build one from the CLI (yet), but I'll add
instructions once I do

### Windows & macOS
It's probably possible to run this on Windows & macOS, but you're on your own
(for now at least)

