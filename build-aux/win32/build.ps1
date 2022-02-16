param (
  [string] $Msys2Path = 'C:\msys64',
  [string] $Msys2Env = 'clang64',
  [string] $MakeNsisPath = 'C:\Program Files (x86)\NSIS\makensis.exe'
)

function bash {
  param (
    [Parameter(Mandatory)]
    [string] $Command
  )
  & "$Msys2Path\msys2_shell.cmd" -defterm -here -no-start "-$Msys2Env" -c "$Command"
}

Set-Location $PSScriptRoot

Write-Host 'Installing toolchain'
bash 'pacman -S "${MINGW_PACKAGE_PREFIX}-toolchain" --needed --noconfirm'

Write-Host 'Building package'
bash 'makepkg-mingw --cleanbuild --syncdeps --force --noconfirm'

Write-Host 'Installing everything into new rootfs'
New-Item -ItemType Directory -ErrorAction Ignore ./rootfs/var/lib/pacman | Out-Null
bash 'pacman -Sy --root ./rootfs'
bash 'pacman -U "./${MINGW_PACKAGE_PREFIX}-anilist-gtk-*.pkg.tar.zst" --root ./rootfs --needed --noconfirm'

Write-Host 'Removing unnecessary files'
Push-Location "rootfs\$Msys2Env"
Get-ChildItem -Recurse | ForEach-Object { Set-ItemProperty $_.FullName -Name IsReadOnly -Value $false -ErrorAction Ignore }

Remove-Item -Recurse -ErrorAction Ignore x86_64-w64-mingw32
Remove-Item -Recurse -ErrorAction Ignore var
Remove-Item -Recurse -ErrorAction Ignore ssl
Remove-Item -Recurse -ErrorAction Ignore libexec
Remove-Item -Recurse -ErrorAction Ignore include
Remove-Item -Recurse -ErrorAction Ignore etc

Get-ChildItem lib | ForEach-Object {
  if (!($_.Name -eq "gdk-pixbuf-2.0" -or $_.Name -eq "gio")) {
    Remove-Item -Recurse $_.FullName
  }
}

Get-ChildItem share | ForEach-Object {
  if (!($_.Name -eq "glib-2.0" -or $_.Name -eq "icons")) {
    Remove-Item -Recurse $_.FullName
  }
}
Remove-Item -Recurse -ErrorAction Ignore share\glib-2.0\codegen
Remove-Item -Recurse -ErrorAction Ignore share\glib-2.0\gdb
Remove-Item -Recurse -ErrorAction Ignore share\glib-2.0\gettext
Remove-Item -Recurse -ErrorAction Ignore share\glib-2.0\schemas\*.xml
Remove-Item -Recurse -ErrorAction Ignore share\glib-2.0\schemas\gschema.dtd

Remove-Item -ErrorAction Ignore bin/* -Exclude @("ch.laurinneff.AniList-GTK.exe", "gdbus.exe", "gspawn-win64-helper.exe", "*.dll")
Pop-Location

Write-Host 'Building installer'
& "$MakeNsisPath" -Wx "-Dmsys2env=$Msys2Env" installer.nsi

Write-Host 'Cleaning up'
Remove-Item -Recurse -Force @("./rootfs", "./anilist-gtk", "./pkg", "./src", "./*.pkg.tar.zst")

