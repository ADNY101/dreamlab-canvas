; DreamLab Canvas setup.exe (NSIS 3). Built by packaging/windows/build-setup.sh:
;   makensis -DVERSION=0.7.0 -DSTAGE=<dir with the files> -DOUTFILE=<setup.exe> dreamlab-canvas.nsi
;
; Mirrors dreamlab-canvas.wxs (the MSI): per-machine install into Program Files, Start Menu shortcut,
; App Paths entry, .pcraft documents opened by DreamLab Canvas, and DreamLab Canvas offered under
; "Open with" (and Settings > Default apps) for PSD/PSB and common image formats without taking over
; their defaults. Adds: optional desktop shortcut, optional CLI on PATH.
;
; -DWITH_CLI also installs dreamlab-canvas-cli.exe (and offers it on PATH). Without it the CLI ships
; as its own zip, which keeps setup.exe small.
;
; Silent install:  setup.exe /S [/NODESKTOP] [/CLIPATH] [/D=C:\Path\To\Install]
; Silent removal:  "C:\Program Files\DreamLab Canvas\uninstall.exe" /S

Target amd64-unicode   ; native 64-bit installer (the app is x64-only)
ManifestDPIAware true
SetCompressor /SOLID lzma

!include "MUI2.nsh"
!include "x64.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"

!ifndef VERSION
  !error "pass -DVERSION=x.y.z"
!endif
!ifndef STAGE
  !error "pass -DSTAGE=<staging dir>"
!endif
!ifndef OUTFILE
  !define OUTFILE "dreamlab-canvas-${VERSION}-windows-x64-setup.exe"
!endif

!define APPNAME     "DreamLab Canvas"
!define PUBLISHER   "DreamLab"
!define EXE         "dreamlab-canvas.exe"
!define PROGID_DOC  "DreamLabCanvas.Document"
!define PROGID_PSD  "DreamLabCanvas.PhotoshopDocument"
!define PROGID_IMG  "DreamLabCanvas.Image"
!define UNINSTKEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\DreamLab Canvas"
!define APPKEY      "Software\DreamLab Canvas"
!define URL         "https://github.com/mad10188/dreamlab-canvas"

Name "${APPNAME}"
OutFile "${OUTFILE}"
InstallDir "$PROGRAMFILES64\${APPNAME}"
InstallDirRegKey HKLM "${APPKEY}" "InstallDir"
RequestExecutionLevel admin
BrandingText "${APPNAME} ${VERSION}"

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "CompanyName" "${PUBLISHER}"
VIAddVersionKey "FileDescription" "${APPNAME} Setup"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "Copyright (c) 2026 Marc Joseph and the DreamLab Canvas contributors. MIT OR Apache-2.0."

; ---- Look ------------------------------------------------------------------------------------
!define MUI_ICON   "${STAGE}\dreamlab-canvas.ico"
!define MUI_UNICON "${STAGE}\dreamlab-canvas.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP   "wizard.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "wizard.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP   "header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "header.bmp"
!define MUI_ABORTWARNING
!define MUI_COMPONENTSPAGE_SMALLDESC

!define MUI_WELCOMEPAGE_TEXT "This will install ${APPNAME} ${VERSION}, a native, open-source image editor.$\r$\n$\r$\nLayers, masks, adjustment layers, layer styles, type, vectors, brushes and real PSD files. Your images never leave your computer.$\r$\n$\r$\nClick Next to continue."
!define MUI_LICENSEPAGE_TEXT_TOP "${APPNAME} is free, open-source software."
!define MUI_LICENSEPAGE_TEXT_BOTTOM "You may use it under the MIT License or the Apache License 2.0, at your option. No agreement is required to install it."
!define MUI_LICENSEPAGE_BUTTON "&Next >"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APPNAME}"
!define MUI_FINISHPAGE_RUN_FUNCTION LaunchUnelevated
!define MUI_FINISHPAGE_LINK "${APPNAME} on GitHub"
!define MUI_FINISHPAGE_LINK_LOCATION "${URL}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${STAGE}\LICENSE-MIT.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Image formats offered under "Open with" (defaults untouched).
!macro ForEachImageExt MACRO
  !insertmacro ${MACRO} ".pdn"
  !insertmacro ${MACRO} ".ora"
  !insertmacro ${MACRO} ".png"
  !insertmacro ${MACRO} ".jpg"
  !insertmacro ${MACRO} ".jpeg"
  !insertmacro ${MACRO} ".tif"
  !insertmacro ${MACRO} ".tiff"
  !insertmacro ${MACRO} ".webp"
  !insertmacro ${MACRO} ".gif"
  !insertmacro ${MACRO} ".bmp"
  !insertmacro ${MACRO} ".tga"
  !insertmacro ${MACRO} ".exr"
  !insertmacro ${MACRO} ".hdr"
  !insertmacro ${MACRO} ".avif"
  !insertmacro ${MACRO} ".qoi"
  !insertmacro ${MACRO} ".ico"
!macroend

!macro RegImage ext
  WriteRegStr HKLM "Software\Classes\${ext}\OpenWithProgids" "${PROGID_IMG}" ""
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\SupportedTypes" "${ext}" ""
  WriteRegStr HKLM "${APPKEY}\Capabilities\FileAssociations" "${ext}" "${PROGID_IMG}"
!macroend
!macro UnRegImage ext
  DeleteRegValue HKLM "Software\Classes\${ext}\OpenWithProgids" "${PROGID_IMG}"
!macroend

; ---- Sections --------------------------------------------------------------------------------
Section "${APPNAME} (required)" SecMain
  SectionIn RO
  SetShellVarContext all
  SetOutPath "$INSTDIR"
  File "${STAGE}\${EXE}"
  !ifdef WITH_CLI
    File "${STAGE}\dreamlab-canvas-cli.exe"
  !endif
  File "${STAGE}\LICENSE-MIT.txt"
  File "${STAGE}\LICENSE-APACHE.txt"
  File "${STAGE}\NOTICE.txt"

  CreateShortcut "$SMPROGRAMS\${APPNAME}.lnk" "$INSTDIR\${EXE}" "" "$INSTDIR\${EXE}" 0 SW_SHOWNORMAL "" "${APPNAME} image editor"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\App Paths\${EXE}" "" "$INSTDIR\${EXE}"

  ; DreamLab Canvas documents (.pcraft) are the app's own format: it opens them by default.
  WriteRegStr HKLM "Software\Classes\${PROGID_DOC}" "" "DreamLab Canvas Document"
  WriteRegStr HKLM "Software\Classes\${PROGID_DOC}\DefaultIcon" "" '"$INSTDIR\${EXE}",0'
  WriteRegStr HKLM "Software\Classes\${PROGID_DOC}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
  WriteRegStr HKLM "Software\Classes\.pcraft" "" "${PROGID_DOC}"
  WriteRegStr HKLM "Software\Classes\.pcraft" "Content Type" "application/x-dreamlab-canvas"

  ; PSD/PSB and images: offered under "Open with"; the user chooses any default.
  WriteRegStr HKLM "Software\Classes\${PROGID_PSD}" "" "PSD Document"
  WriteRegStr HKLM "Software\Classes\${PROGID_PSD}\DefaultIcon" "" '"$INSTDIR\${EXE}",0'
  WriteRegStr HKLM "Software\Classes\${PROGID_PSD}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
  WriteRegStr HKLM "Software\Classes\${PROGID_IMG}" "" "Image"
  WriteRegStr HKLM "Software\Classes\${PROGID_IMG}\DefaultIcon" "" '"$INSTDIR\${EXE}",0'
  WriteRegStr HKLM "Software\Classes\${PROGID_IMG}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
  WriteRegStr HKLM "Software\Classes\.psd\OpenWithProgids" "${PROGID_PSD}" ""
  WriteRegStr HKLM "Software\Classes\.psb\OpenWithProgids" "${PROGID_PSD}" ""

  WriteRegStr HKLM "Software\Classes\Applications\${EXE}" "FriendlyAppName" "${APPNAME}"
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\shell\open\command" "" '"$INSTDIR\${EXE}" "%1"'
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\SupportedTypes" ".pcraft" ""
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\SupportedTypes" ".psd" ""
  WriteRegStr HKLM "Software\Classes\Applications\${EXE}\SupportedTypes" ".psb" ""

  ; Default Programs registration, so DreamLab Canvas appears in Settings > Default apps.
  WriteRegStr HKLM "${APPKEY}\Capabilities" "ApplicationName" "${APPNAME}"
  WriteRegStr HKLM "${APPKEY}\Capabilities" "ApplicationDescription" "Open-source image editor"
  WriteRegStr HKLM "${APPKEY}\Capabilities" "ApplicationIcon" "$INSTDIR\${EXE},0"
  WriteRegStr HKLM "${APPKEY}\Capabilities\FileAssociations" ".pcraft" "${PROGID_DOC}"
  WriteRegStr HKLM "${APPKEY}\Capabilities\FileAssociations" ".psd" "${PROGID_PSD}"
  WriteRegStr HKLM "${APPKEY}\Capabilities\FileAssociations" ".psb" "${PROGID_PSD}"
  !insertmacro ForEachImageExt RegImage
  WriteRegStr HKLM "Software\RegisteredApplications" "${APPNAME}" "${APPKEY}\Capabilities"

  ; Uninstaller and the Add/Remove Programs entry.
  WriteRegStr HKLM "${APPKEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "${APPKEY}" "Version" "${VERSION}"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "${UNINSTKEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayIcon" "$INSTDIR\${EXE},0"
  WriteRegStr HKLM "${UNINSTKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${UNINSTKEY}" "URLInfoAbout" "${URL}"
  WriteRegStr HKLM "${UNINSTKEY}" "HelpLink" "${URL}/issues"
  WriteRegStr HKLM "${UNINSTKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "${UNINSTKEY}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${UNINSTKEY}" "EstimatedSize" "$0"

  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd

Section "Desktop shortcut" SecDesktop
  SetShellVarContext all
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${EXE}" "" "$INSTDIR\${EXE}" 0 SW_SHOWNORMAL "" "${APPNAME} image editor"
SectionEnd

!ifdef WITH_CLI
Section /o "Add dreamlab-canvas-cli to PATH" SecPath
  nsExec::ExecToLog `powershell.exe -NoProfile -NonInteractive -Command "$$k='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; $$p=(Get-Item $$k).GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); $$d='$INSTDIR'; if (($$p -split ';') -notcontains $$d) { Set-ItemProperty $$k -Name Path -Type ExpandString -Value (($$p.TrimEnd(';')) + ';' + $$d) }"`
  Pop $0
  WriteRegDWORD HKLM "${APPKEY}" "OnPath" 1
  SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd
!endif

LangString DESC_Main    ${LANG_ENGLISH} "The DreamLab Canvas app, Start Menu shortcut, .pcraft documents, and 'Open with' entries for PSD and image files (your defaults are kept)."
LangString DESC_Desktop ${LANG_ENGLISH} "A DreamLab Canvas shortcut on the desktop for all users."
!ifdef WITH_CLI
LangString DESC_Path    ${LANG_ENGLISH} "Lets you run dreamlab-canvas-cli from any terminal (adds the install folder to the system PATH)."
!endif
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain}    $(DESC_Main)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_Desktop)
  !ifdef WITH_CLI
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPath}    $(DESC_Path)
  !endif
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ---- Functions -------------------------------------------------------------------------------
Function .onInit
  SetRegView 64
  ReadRegStr $0 HKLM "${APPKEY}" "InstallDir"
  ${If} $0 != ""
    StrCpy $INSTDIR $0
  ${EndIf}
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 "/NODESKTOP" $R1
  ${IfNot} ${Errors}
    !insertmacro UnselectSection ${SecDesktop}
  ${EndIf}
  !ifdef WITH_CLI
    ClearErrors
    ${GetOptions} $R0 "/CLIPATH" $R1
    ${IfNot} ${Errors}
      !insertmacro SelectSection ${SecPath}
    ${EndIf}
  !endif
FunctionEnd

; Launch through Explorer so the app runs as the signed-in user, not elevated.
Function LaunchUnelevated
  Exec '"$WINDIR\explorer.exe" "$INSTDIR\${EXE}"'
FunctionEnd

Function un.onInit
  SetRegView 64
FunctionEnd

; ---- Uninstall -------------------------------------------------------------------------------
Section "Uninstall"
  SetShellVarContext all

  ReadRegDWORD $0 HKLM "${APPKEY}" "OnPath"
  ${If} $0 == 1
    nsExec::ExecToLog `powershell.exe -NoProfile -NonInteractive -Command "$$k='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; $$p=(Get-Item $$k).GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); $$d='$INSTDIR'; Set-ItemProperty $$k -Name Path -Type ExpandString -Value ((($$p -split ';') | Where-Object { $$_ -and $$_ -ne $$d }) -join ';')"`
    Pop $0
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000
  ${EndIf}

  Delete "$SMPROGRAMS\${APPNAME}.lnk"
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$INSTDIR\${EXE}"
  Delete "$INSTDIR\dreamlab-canvas-cli.exe"
  Delete "$INSTDIR\LICENSE-MIT.txt"
  Delete "$INSTDIR\LICENSE-APACHE.txt"
  Delete "$INSTDIR\NOTICE.txt"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\App Paths\${EXE}"
  DeleteRegKey HKLM "Software\Classes\${PROGID_DOC}"
  DeleteRegKey HKLM "Software\Classes\${PROGID_PSD}"
  DeleteRegKey HKLM "Software\Classes\${PROGID_IMG}"
  ; .pcraft only if it still points at us.
  ReadRegStr $1 HKLM "Software\Classes\.pcraft" ""
  ${If} $1 == "${PROGID_DOC}"
    DeleteRegKey HKLM "Software\Classes\.pcraft"
  ${EndIf}
  DeleteRegValue HKLM "Software\Classes\.psd\OpenWithProgids" "${PROGID_PSD}"
  DeleteRegValue HKLM "Software\Classes\.psb\OpenWithProgids" "${PROGID_PSD}"
  !insertmacro ForEachImageExt UnRegImage
  DeleteRegKey HKLM "Software\Classes\Applications\${EXE}"
  DeleteRegValue HKLM "Software\RegisteredApplications" "${APPNAME}"
  DeleteRegKey HKLM "${APPKEY}"
  DeleteRegKey HKLM "${UNINSTKEY}"

  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
  ; Per-user settings, recent files and logs (%APPDATA%) are kept, like most apps.
SectionEnd
