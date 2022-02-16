# mostly based on the Modern UI\Basic.nsi example

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"

Name "AniList-GTK"
OutFile "AniList-GTK Installer.exe"
Unicode true
InstallDir "$LOCALAPPDATA\Programs\AniList-GTK"
InstallDirRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "InstallLocation"
RequestExecutionLevel user

Var DeleteDataCheckbox
Var DeleteDataCheckboxState

Function un.deleteDataPageCreate
  !insertmacro MUI_HEADER_TEXT "Delete data?" "Would you like to delete app data?"

  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckBox} 0 0 100% 12u "Delete data"
  Pop $DeleteDataCheckbox

  ${NSD_SetState} $DeleteDataCheckbox $DeleteDataCheckboxState

  nsDialogs::Show
FunctionEnd

Function un.deleteDataPageLeave
  ${NSD_GetState} $DeleteDataCheckbox $DeleteDataCheckboxState
FunctionEnd

!define MUI_FINISHPAGE_RUN "$INSTDIR\bin\ch.laurinneff.AniList-GTK.exe"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "gpl-3.0.rtf"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
UninstPage custom un.deleteDataPageCreate un.deleteDataPageLeave
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

# From https://nsis.sourceforge.io/Auto-uninstall_old_before_installing_new
!macro UninstallExisting exitcode uninstcommand
  Push `${uninstcommand}`
  Call UninstallExisting
  Pop ${exitcode}
!macroend
Function UninstallExisting
  Exch $1 ; uninstcommand
  Push $2 ; Uninstaller
  Push $3 ; Len
  StrCpy $3 ""
  StrCpy $2 $1 1
  StrCmp $2 '"' qloop sloop
  sloop:
    StrCpy $2 $1 1 $3
    IntOp $3 $3 + 1
    StrCmp $2 "" +2
    StrCmp $2 ' ' 0 sloop
    IntOp $3 $3 - 1
    Goto run
  qloop:
    StrCmp $3 "" 0 +2
    StrCpy $1 $1 "" 1 ; Remove initial quote
    IntOp $3 $3 + 1
    StrCpy $2 $1 1 $3
    StrCmp $2 "" +2
    StrCmp $2 '"' 0 qloop
  run:
    StrCpy $2 $1 $3 ; Path to uninstaller
    StrCpy $1 161 ; ERROR_BAD_PATHNAME
    GetFullPathName $3 "$2\.." ; $InstDir
    IfFileExists "$2" 0 +4
    ExecWait '"$2" /S _?=$3' $1 ; This assumes the existing uninstaller is a NSIS uninstaller, other uninstallers don't support /S nor _?=
    IntCmp $1 0 "" +2 +2 ; Don't delete the installer if it was aborted
    Delete "$2" ; Delete the uninstaller
    RMDir "$3" ; Try to delete $InstDir
    RMDir "$3\.." ; (Optional) Try to delete the parent of $InstDir
  Pop $3
  Pop $2
  Exch $1 ; exitcode
FunctionEnd

Function .onInit
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "UninstallString"
  ${If} $0 != ""
    ${If} ${Cmd} 'MessageBox MB_YESNO|MB_ICONQUESTION "Uninstall previous version?" /SD IDYES IDYES'
      !insertmacro "UninstallExisting" $0 $0
      ${If} $0 != 0
        MessageBox MB_OK|MB_ICONSTOP "Failed to uninstall" /SD IDOK
          Abort
      ${EndIf}
    ${Else}
      MessageBox MB_OK|MB_ICONSTOP "You need to uninstall the previous version first" /SD IDOK
      Abort
    ${EndIf}
  ${EndIf}
FunctionEnd

Section "" "section_anilist_gtk"
  SetOutPath "$INSTDIR"

  File /r "rootfs\${msys2env}\*"

  CreateShortCut "$SMPROGRAMS\AniList-GTK.lnk" "$INSTDIR\bin\ch.laurinneff.AniList-GTK.exe"

  WriteRegStr HKCU "Software\Classes\anilist-gtk" "" "AniList-GTK"
  WriteRegStr HKCU "Software\Classes\anilist-gtk" "URL Protocol" ""
  WriteRegStr HKCU "Software\Classes\anilist-gtk\shell\open\command" "" "$\"$INSTDIR\bin\ch.laurinneff.AniList-GTK.exe$\" %1"

  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "DisplayName" "AniList-GTK"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "Publisher" "Laurin Neff"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "Readme" "https://github.com/laurinneff/AniList-GTK"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "NoModify" "1"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "NoRepair" "1"

  SectionGetSize ${section_anilist_gtk} $0
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK" "EstimatedSize" "$0"

  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  RMDir /r "$INSTDIR"

  Delete "$SMPROGRAMS\AniList-GTK.lnk"

  DeleteRegKey HKCU "Software\Classes\anilist-gtk"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AniList-GTK"

  ${If} $DeleteDataCheckboxState == ${BST_CHECKED}
    RMDir /r "$LOCALAPPDATA\Microsoft\Windows\INetCache\AniList-GTK"
    # There are also other keys under GSettings, but they may be created by other software that uses GSettings, so we don't delete it
    DeleteRegKey HKCU "Software\GSettings\ch\laurinneff\AniList-GTK"
    DeleteRegKey /ifnovalues HKCU "Software\GSettings\ch"
  ${EndIf}
SectionEnd

