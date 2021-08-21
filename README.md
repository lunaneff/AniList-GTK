# AniList-GTK

A native desktop client for AniList

## Building & Installing

### Linux

#### Native

##### Dependencies
- Vala
- GTK4
- Libadwaita
- Libsecret (+ a Secret Service implementation like GNOME Keyring or KWallet)
- Libsoup
- JSON-GLib
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
If you build a Flatpak, all dependencies will be built automatically:

```shell
$ flatpak-builder build-dir ch.laurinneff.AniList-GTK.json --force-clean --user --install
```

### Windows & macOS
It's probably possible to run this on Windows & macOS, but you're on your own
(for now at least)

