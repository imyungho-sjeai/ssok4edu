#NoEnv
#SingleInstance Off
#Persistent
SetBatchLines, -1
ListLines, Off
SendMode, Input
SetWinDelay, 50
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
global SSOK_DpiAwarenessMode := 0
SSOK_Capture_EnableDpiAwareness()

; ============================================================
; SSOK GDI/GDI+ ¾ÈÀü ÇØÁ¦ º¸°­
; ±âÁ¸ ±â´ÉÀº º¯°æÇÏÁö ¾Ê°í ÀÚ¿ø ÇØÁ¦ °æ·Î¸¸ º¸°­
; ============================================================
SSOK_SafeDisposeImage(pImage) {
    if (pImage)
        Gdip_DisposeImage(pImage)
}

SSOK_SafeDeleteGraphics(pGraphics) {
    if (pGraphics)
        Gdip_DeleteGraphics(pGraphics)
}

SSOK_SafeDeleteObject(hObj) {
    if (hObj)
        DllCall("gdi32\\DeleteObject", "Ptr", hObj)
}



SSOK_Capture_EnableDpiAwareness()
{
    global SSOK_DpiAwarenessMode
    ; ´Üµ¶ AHK ½ÇÇà/ÄÄÆÄÀÏ EXE ¸ðµÎ¿¡¼­ ´ÙÁß ¸ð´ÏÅÍ ¹°¸® ÁÂÇ¥¸¦ ¿ì¼± »ç¿ëÇÕ´Ï´Ù.
    ; ÀÌ¹Ì ¸ÞÀÎ ½ºÅ©¸³Æ®¿¡¼­ DPI awareness°¡ ¼³Á¤µÈ °æ¿ìµµ ÀÖÀ¸¹Ç·Î ÇöÀç »óÅÂ¸¦ ¸ÕÀú ÀÐ½À´Ï´Ù.
    SSOK_DpiAwarenessMode := SSOK_Capture_GetCurrentDpiAwarenessMode()
    if (SSOK_DpiAwarenessMode >= 2)
        return true

    if (DllCall("user32\SetProcessDpiAwarenessContext", "Ptr", -4, "Int"))
    {
        SSOK_DpiAwarenessMode := 2
        return true
    }
    if (DllCall("Shcore\SetProcessDpiAwareness", "Int", 2, "UInt") = 0)
    {
        SSOK_DpiAwarenessMode := 2
        return true
    }

    SSOK_DpiAwarenessMode := SSOK_Capture_GetCurrentDpiAwarenessMode()
    if (SSOK_DpiAwarenessMode >= 2)
        return true

    if (DllCall("user32\SetProcessDPIAware", "Int"))
    {
        SSOK_DpiAwarenessMode := 1
        return true
    }

    SSOK_DpiAwarenessMode := SSOK_Capture_GetCurrentDpiAwarenessMode()
    return (SSOK_DpiAwarenessMode > 0)
}

SSOK_Capture_GetCurrentDpiAwarenessMode()
{
    ctx := DllCall("user32\GetThreadDpiAwarenessContext", "Ptr")
    if (ctx)
    {
        if (DllCall("user32\AreDpiAwarenessContextsEqual", "Ptr", ctx, "Ptr", -4, "Int")
            || DllCall("user32\AreDpiAwarenessContextsEqual", "Ptr", ctx, "Ptr", -3, "Int"))
            return 2
        if (DllCall("user32\AreDpiAwarenessContextsEqual", "Ptr", ctx, "Ptr", -2, "Int"))
            return 1
    }

    awareness := -1
    if (DllCall("Shcore\GetProcessDpiAwareness", "Ptr", 0, "Int*", awareness) = 0)
    {
        if (awareness = 2)
            return 2
        if (awareness = 1)
            return 1
    }

    if (DllCall("user32\IsProcessDPIAware", "Int"))
        return 1
    return 0
}

SSOK_GetMonitorDpiScaleForPoint(px, py, ByRef scaleX, ByRef scaleY)
{
    scaleX := 1.0
    scaleY := 1.0

    VarSetCapacity(rc, 16, 0)
    NumPut(Round(px), rc, 0, "Int")
    NumPut(Round(py), rc, 4, "Int")
    NumPut(Round(px) + 1, rc, 8, "Int")
    NumPut(Round(py) + 1, rc, 12, "Int")
    hMon := DllCall("user32\MonitorFromRect", "Ptr", &rc, "UInt", 2, "Ptr")
    if (!hMon)
        return false

    dpiX := 96
    dpiY := 96
    if (DllCall("Shcore\GetDpiForMonitor", "Ptr", hMon, "Int", 0, "UInt*", dpiX, "UInt*", dpiY) = 0 && dpiX > 0 && dpiY > 0)
    {
        scaleX := dpiX / 96.0
        scaleY := dpiY / 96.0
        return true
    }

    hdc := DllCall("user32\GetDC", "Ptr", 0, "Ptr")
    if (hdc)
    {
        dpiX := DllCall("gdi32\GetDeviceCaps", "Ptr", hdc, "Int", 88, "Int")
        dpiY := DllCall("gdi32\GetDeviceCaps", "Ptr", hdc, "Int", 90, "Int")
        DllCall("user32\ReleaseDC", "Ptr", 0, "Ptr", hdc)
        if (dpiX > 0 && dpiY > 0)
        {
            scaleX := dpiX / 96.0
            scaleY := dpiY / 96.0
            return true
        }
    }
    return false
}

SSOK_AdjustScreenCaptureRectForDpi(ByRef x, ByRef y, ByRef w, ByRef h)
{
    global SSOK_DpiAwarenessMode
    ; Per-monitor DPI aware »óÅÂ¿¡¼­´Â ¸¶¿ì½º/À©µµ¿ì ÁÂÇ¥°¡ ÀÌ¹Ì ¹°¸® ÇÈ¼¿ ±âÁØÀÔ´Ï´Ù.
    if (SSOK_DpiAwarenessMode >= 2 || w < 1 || h < 1)
        return false

    cx := x + (w / 2.0)
    cy := y + (h / 2.0)
    if (!SSOK_GetMonitorDpiScaleForPoint(cx, cy, scaleX, scaleY))
        return false
    if (Abs(scaleX - 1.0) < 0.01 && Abs(scaleY - 1.0) < 0.01)
        return false

    if (!SSOK_GetMonitorBoundsFromPoint(cx, cy, monLeft, monTop, monRight, monBottom))
    {
        monLeft := 0
        monTop := 0
    }
    x := monLeft + Round((x - monLeft) * scaleX)
    y := monTop + Round((y - monTop) * scaleY)
    w := Round(w * scaleX)
    h := Round(h * scaleY)
    if (w < 1)
        w := 1
    if (h < 1)
        h := 1
    return true
}

; ============================================================
; SSOK Ä¸Ã³ Å×½ºÆ® - Á÷Á¢ ¹üÀ§ Ä¸Ã³ + GDI ÆíÁý
; - Ä¸Ã³: Windows Ä¸Ã³µµ±¸ ¾øÀÌ È­¸é ¹üÀ§¸¦ Á÷Á¢ ¼±ÅÃ
; - Ä¸Ã³ ¿Ï·á ÈÄ: ¹Ù·Î SSOK Ä¸Ã³ ÆíÁýÃ¢ Ç¥½Ã
; - ÆíÁý: SSOK GDI ÆíÁýÃ¢¿¡¼­ ¹øÈ£/¹Ú½º/È­»ìÇ¥/±Û»óÀÚ/Çü±¤Ææ/¸ðÀÚÀÌÅ© Ã³¸®
; - ¹øÈ£: Å¬¸¯ À§Ä¡¿¡ »¡°£ ¿øÇü ¹øÈ£ µµÀå Áï½Ã ¹Ý¿µ
; - ±Û¾²±â: »ó´Ü ¹®±¸ ÀÔ·ÂÄ­¿¡ ¸ÕÀú ÀÔ·ÂÇÑ µÚ ÀÌ¹ÌÁö À§Ä¡¸¦ Å¬¸¯ÇÏ¿© ¹èÄ¡
; - ³»ºÎ ÀÛ¾÷/Å¬¸³º¸µå/OCR ÆÄÀÏÀº PNG ¿ì¼±, »ç¿ëÀÚ ÀúÀåÀº PNG/JPG ¼±ÅÃ
; ============================================================

global SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
global SSOK_ConfigDir := SSOK_GetSafeConfigDir()
global SSOK_StateIni := SSOK_ConfigDir "\ssok.ini"
global SSOK_OldStateIni := SSOK_ConfigDir "\ssok_capture_test.ini"
global SSOK_LastCaptureFile := ""
global SSOK_StampNo := 1
global SSOK_GdipToken := 0
global SSOK_MainHwnd := ""
global SSOK_ToolHwnd := ""
global SSOK_EditorHwnd := ""
global SSOK_ImageHwnd := ""
global SSOK_ImageW := 0, SSOK_ImageH := 0
global SSOK_DisplayW := 0, SSOK_DisplayH := 0
global SSOK_EditorTool := ""
global SSOK_CaptureCompleted := false
global SSOK_PaintPID := ""
global SSOK_MenuTarget := "snip"
global SSOK_PaintHasCapture := false
global SSOK_CaptureStartClipboardSeq := 0
global SSOK_NumberMode := false
global SSOK_NumberClickBusy := false
global SSOK_NumberPoints := []
global SSOK_NumberOverlayIds := []
global SSOK_NumberOverlaySize := 42
global SSOK_NumberPrevLButton := false
global SSOK_NumberOverlayHwnd := ""
global SSOK_NumberStartedAt := 0
global SSOK_NumberLastClickTick := 0
global SSOK_StampGuiHwnd := ""
global SSOK_StampPicHwnd := ""
global SSOK_StampInfoHwnd := ""
global SSOK_StampBitmap := 0
global SSOK_StampImageW := 0
global SSOK_StampImageH := 0
global SSOK_StampDisplayW := 0
global SSOK_StampDisplayH := 0
global SSOK_StampInfoW := 1040
global SSOK_StampPreviewFile := ""
global SSOK_StampSourceFile := ""
global SSOK_StampSessionTempFiles := []
global SSOK_StampTempManifestFile := ""
global SSOK_StampTempManifestInitialized := false
global SSOK_StampDirty := false
global SSOK_StampLastClickTick := 0
global SSOK_StampInfoText := ""
global SSOK_StampPic := ""
global SSOK_StampTool := "rect"
global SSOK_StampDragging := false
global SSOK_StampDragStartX := 0
global SSOK_StampDragStartY := 0
global SSOK_StampPreviewLastTick := 0
global SSOK_StampPreviewTempFile := ""
global SSOK_StampSuppressPicClickUntil := 0
global SSOK_StampUndoStack := []
global SSOK_ActiveEditorInfoCache := ""
global SSOK_ActiveEditorLastWriteTick := 0
global SSOK_WorkCleanupLastDate := ""
global SSOK_StampMainColor := "»¡°­"
global SSOK_StampSizeLevel := "ÀÛ°Ô"
; È£È¯¿ë ±âÁ¸ º¯¼ö: ½ÇÁ¦ »ç¿ë°ªÀº SSOK_StampMainColor / SSOK_StampSizeLevel ±âÁØÀ¸·Î µ¿±âÈ­ÇÕ´Ï´Ù.
global SSOK_StampNumberColor := "»¡°­"
global SSOK_StampRectColor := "»¡°­"
global SSOK_StampArrowColor := "»¡°­"
global SSOK_StampHighlightColor := "»¡°­"
global SSOK_StampHighlightSize := 24
global SSOK_StampMosaicBlock := 12
global SSOK_StampTextEditHwnd := ""
global SSOK_StampInlineText := ""
global SSOK_StampTextEditing := false
global SSOK_StampTextImgX1 := 0
global SSOK_StampTextImgY1 := 0
global SSOK_StampTextImgX2 := 0
global SSOK_StampTextImgY2 := 0
global SSOK_StampTextInput := "[±â°ü¸í]"
global SSOK_StampTextInputHwnd := ""
global SSOK_StampColorHwnd := ""
global SSOK_StampSizeHwnd := ""
global SSOK_StampEmojiHwnd := ""
global SSOK_StampPendingDropdownHwnd := ""
global SSOK_StampEmojiName := "Ã¼Å©"
global SSOK_StampLastTextMeta := ""

global SSOK_DirectCaptureActive := false
global SSOK_DirectCaptureDragging := false
global SSOK_CapDragVisualStarted := false
global SSOK_CapClickDownTick := 0
global SSOK_CapHwnd := ""
global SSOK_CapStartX := 0
global SSOK_CapStartY := 0
global SSOK_CapVX := 0
global SSOK_CapVY := 0
global SSOK_CapVW := 0
global SSOK_CapVH := 0
global SSOK_CapLineT := ""
global SSOK_CapLineB := ""
global SSOK_CapLineL := ""
global SSOK_CapLineR := ""
; Ä¸Ã³ ¹üÀ§ Å×µÎ¸®¸¦ ´õ ±½°í ÁøÇÏ°Ô º¸ÀÌµµ·Ï º°µµ ÃÖ»óÀ§ »¡°£ ¼± GUI¸¦ ÇÔ²² »ç¿ëÇÕ´Ï´Ù.
global SSOK_CapLineHwndT := ""
global SSOK_CapLineHwndB := ""
global SSOK_CapLineHwndL := ""
global SSOK_CapLineHwndR := ""
global SSOK_CapDefaultHas := false
global SSOK_CapDefaultX := 0
global SSOK_CapDefaultY := 0
global SSOK_CapDefaultW := 0
global SSOK_CapDefaultH := 0
global SSOK_CapLoopMode := false
global SSOK_LastExternalHwnd := ""
global SSOK_LaunchMode := ""
global SSOK_CaptureEmbeddedMode := false
global SSOK_CaptureEmbeddedInited := false
global SSOK_CaptureEmbeddedInitOK := 0
global SSOK_CaptureEmbeddedStartOK := 0
global SSOK_MultiCaptureLaunchBlocked := false
global SSOK_CaptureMainMutex := 0
if (IsObject(A_Args) && A_Args.Length() >= 1)
    SSOK_LaunchMode := A_Args[1]
; ´ÙÁß ÆíÁý±â ÀÚ½Ä ÇÁ·Î¼¼½º´Â ÀÓ½Ã Æú´õÀÇ º¹»çº»À¸·Î ½ÇÇàµÇ¹Ç·Î
; ¼³Á¤(ssok.ini)Àº ¿øº» SSOK Æú´õ ±âÁØÀ¸·Î °è¼Ó ÀÐ°í ¾¹´Ï´Ù.
if (IsObject(A_Args) && A_Args.Length() >= 2 && A_Args[2] != "")
{
    SSOK_ConfigDir := SSOK_GetSafeConfigDir(A_Args[2])
    SSOK_StateIni := SSOK_ConfigDir "\ssok.ini"
    SSOK_OldStateIni := SSOK_ConfigDir "\ssok_capture_test.ini"
}
if (SSOK_LaunchMode != "direct" && SSOK_LaunchMode != "direct-child")
{
    SSOK_CaptureMainMutex := DllCall("CreateMutex", "Ptr", 0, "Int", true, "Str", "SSOK_Capture_Main_SingleInstance_Mutex", "Ptr")
    if (A_LastError = 183)
    {
        SSOK_ReleaseCaptureMutex()
        ExitApp
    }
}


SSOK_GetSafeConfigDir(preferred := "")
{
    dir := Trim(preferred)
    if (dir = "")
    {
        if (A_IsCompiled)
            dir := "C:\SSOK"
        else
            dir := A_ScriptDir
    }
    if (!SSOK_IsUsableConfigDir(dir))
        dir := A_IsCompiled ? "C:\SSOK" : A_ScriptDir
    return RTrim(dir, "\/")
}

SSOK_IsUsableConfigDir(dir)
{
    dir := Trim(dir)
    if (dir = "" || dir = "\" || RegExMatch(dir, "i)^[A-Z]:\\?$"))
        return false
    return FileExist(dir)
}
SSOK_GetPrivateWorkDir(subDir := "capture")
{
    root := A_LocalAppData "\SSOK\work"
    if (subDir != "")
        root := root "\" subDir
    FileCreateDir, %root%
    return root
}
FileCreateDir, %SSOK_WorkFolder%
SSOK_StampInitTempManifest()
SSOK_CleanupDeadTempManifests()
SSOK_CleanupOldWorkFiles(1)
Gosub, SSOK_LoadState

SSOK_GdipToken := Gdip_Startup()
if (!SSOK_GdipToken)
{
    MsgBox, 16, SSOK Ä¸Ã³ Å×½ºÆ®, GDI+ ÃÊ±âÈ­¿¡ ½ÇÆÐÇß½À´Ï´Ù.
    ExitApp
}

OnMessage(0x201, "SSOK_WM_LBUTTONDOWN")
OnMessage(0x202, "SSOK_WM_LBUTTONUP")
OnMessage(0x200, "SSOK_WM_MOUSEMOVE")
if (!IsLabel("SSOK_MainExitCleanup"))
    OnExit, SSOK_AppExit
SetTimer, SSOK_WatchActiveWindow, 200
SetTimer, SSOK_WorkFolderCleanupTick, 1200000
if (SSOK_LaunchMode = "direct" || SSOK_LaunchMode = "direct-child")
    Gosub, SSOK_Capture
return

SSOK_CloseOnlyWindowsSearchIfOpen()
{
    ; Win+S hotkey after key release must not send Esc to ordinary dialogs.
    ; Esc is only used when Windows Search/Start accidentally remains active.
    WinGet, activeExe, ProcessName, A
    WinGetClass, activeClass, A
    WinGetTitle, activeTitle, A

    if (activeExe = "SearchHost.exe" || activeExe = "SearchApp.exe" || activeExe = "StartMenuExperienceHost.exe")
    {
        SendInput, {Esc}
        Sleep, 40
        return true
    }

    if (activeClass = "Windows.UI.Core.CoreWindow")
    {
        if (InStr(activeTitle, "Search") || InStr(activeTitle, "°Ë»ö"))
        {
            SendInput, {Esc}
            Sleep, 40
            return true
        }
    }
    return false
}
; Àü¿ª Ä¸Ã³ ´ÜÃàÅ°: Win+S
; ´ÙÁß ÆíÁý±â ÀÚ½Ä ÇÁ·Î¼¼½º¿¡¼­´Â Win+S Àü¿ª ÇÖÅ°¸¦ µî·ÏÇÏÁö ¾Ê½À´Ï´Ù.
#s::
if (SSOK_CloseOnlyWindowsSearchIfOpen())
    return
if (!SSOK_StartCapturePreferred())
    MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, ½ºÅ©¸° Ä¸Ã³ ½ÇÇà¿¡ ½ÇÆÐÇß½À´Ï´Ù.
return

SSOK_Capture_DirectChildStart:
SSOK_CaptureEmbeddedStartOK := 0
Gosub, SSOK_Capture_EmbeddedInit
if (!SSOK_CaptureEmbeddedInitOK)
    ExitApp
SSOK_CaptureEmbeddedMode := false
SSOK_LaunchMode := "direct-child"
Gosub, SSOK_Capture
SSOK_CaptureEmbeddedStartOK := 1
return

SSOK_Capture_EmbeddedDirect:
SSOK_CaptureEmbeddedStartOK := 0
SSOK_CaptureEmbeddedMode := true
SSOK_LaunchMode := "embedded-direct"
Gosub, SSOK_Capture_EmbeddedInit
if (!SSOK_CaptureEmbeddedInitOK)
    return
Gosub, SSOK_Capture
SSOK_CaptureEmbeddedStartOK := 1
return

SSOK_Capture_EmbeddedInit:
SSOK_CaptureEmbeddedInitOK := 0
if (SSOK_CaptureEmbeddedInited)
{
    SSOK_CaptureEmbeddedInitOK := 1
    return
}
if (SSOK_DirectCaptureActive || SSOK_StampGuiHwnd != "")
{
    SSOK_CaptureEmbeddedInitOK := 1
    return
}

SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
SSOK_ConfigDir := SSOK_GetSafeConfigDir()
SSOK_StateIni := SSOK_ConfigDir "\ssok.ini"
SSOK_OldStateIni := SSOK_ConfigDir "\ssok_capture_test.ini"
if (IsObject(A_Args) && A_Args.Length() >= 2 && A_Args[2] != "")
{
    ; exe ÀÚ½Ä ÇÁ·Î¼¼½ºµµ ¿øº» SSOK Æú´õÀÇ ssok.ini¸¦ »ç¿ëÇÕ´Ï´Ù.
    SSOK_ConfigDir := SSOK_GetSafeConfigDir(A_Args[2])
    SSOK_StateIni := SSOK_ConfigDir "\ssok.ini"
    SSOK_OldStateIni := SSOK_ConfigDir "\ssok_capture_test.ini"
}
SSOK_LastCaptureFile := ""
SSOK_StampNo := 1
SSOK_MainHwnd := ""
SSOK_ToolHwnd := ""
SSOK_EditorHwnd := ""
SSOK_ImageHwnd := ""
SSOK_ImageW := 0, SSOK_ImageH := 0
SSOK_DisplayW := 0, SSOK_DisplayH := 0
SSOK_EditorTool := ""
SSOK_CaptureCompleted := false
SSOK_PaintPID := ""
SSOK_MenuTarget := "snip"
SSOK_PaintHasCapture := false
SSOK_CaptureStartClipboardSeq := 0
SSOK_NumberMode := false
SSOK_NumberClickBusy := false
SSOK_NumberPoints := []
SSOK_NumberOverlayIds := []
SSOK_NumberOverlaySize := 42
SSOK_NumberPrevLButton := false
SSOK_NumberOverlayHwnd := ""
SSOK_NumberStartedAt := 0
SSOK_NumberLastClickTick := 0
SSOK_StampGuiHwnd := ""
SSOK_StampPicHwnd := ""
SSOK_StampInfoHwnd := ""
SSOK_StampBitmap := 0
SSOK_StampImageW := 0
SSOK_StampImageH := 0
SSOK_StampDisplayW := 0
SSOK_StampDisplayH := 0
SSOK_StampInfoW := 1040
SSOK_StampPreviewFile := ""
SSOK_StampSourceFile := ""
SSOK_StampSessionTempFiles := []
SSOK_StampTempManifestFile := ""
SSOK_StampTempManifestInitialized := false
SSOK_StampDirty := false
SSOK_StampLastClickTick := 0
SSOK_StampInfoText := ""
SSOK_StampPic := ""
SSOK_StampTool := "rect"
SSOK_StampDragging := false
SSOK_StampDragStartX := 0
SSOK_StampDragStartY := 0
SSOK_StampPreviewLastTick := 0
SSOK_StampPreviewTempFile := ""
SSOK_StampSuppressPicClickUntil := 0
SSOK_StampUndoStack := []
SSOK_ActiveEditorInfoCache := ""
SSOK_ActiveEditorLastWriteTick := 0
SSOK_WorkCleanupLastDate := ""
SSOK_StampMainColor := "»¡°­"
SSOK_StampSizeLevel := "ÀÛ°Ô"
SSOK_StampNumberColor := "»¡°­"
SSOK_StampRectColor := "»¡°­"
SSOK_StampArrowColor := "»¡°­"
SSOK_StampHighlightColor := "»¡°­"
SSOK_StampHighlightSize := 24
SSOK_StampMosaicBlock := 12
SSOK_StampTextEditHwnd := ""
SSOK_StampInlineText := ""
SSOK_StampTextEditing := false
SSOK_StampTextImgX1 := 0
SSOK_StampTextImgY1 := 0
SSOK_StampTextImgX2 := 0
SSOK_StampTextImgY2 := 0
SSOK_StampTextInput := "[±â°ü¸í]"
SSOK_StampTextInputHwnd := ""
SSOK_StampColorHwnd := ""
SSOK_StampSizeHwnd := ""
SSOK_StampEmojiHwnd := ""
SSOK_StampPendingDropdownHwnd := ""
SSOK_StampEmojiName := "Ã¼Å©"
SSOK_StampLastTextMeta := ""
SSOK_DirectCaptureActive := false
SSOK_DirectCaptureDragging := false
SSOK_CapDragVisualStarted := false
SSOK_CapClickDownTick := 0
SSOK_CapHwnd := ""
SSOK_CapStartX := 0
SSOK_CapStartY := 0
SSOK_CapVX := 0
SSOK_CapVY := 0
SSOK_CapVW := 0
SSOK_CapVH := 0
SSOK_CapLineT := ""
SSOK_CapLineB := ""
SSOK_CapLineL := ""
SSOK_CapLineR := ""
SSOK_CapLineHwndT := ""
SSOK_CapLineHwndB := ""
SSOK_CapLineHwndL := ""
SSOK_CapLineHwndR := ""
SSOK_CapDefaultHas := false
SSOK_CapDefaultX := 0
SSOK_CapDefaultY := 0
SSOK_CapDefaultW := 0
SSOK_CapDefaultH := 0
SSOK_CapLoopMode := false
SSOK_LastExternalHwnd := ""
SSOK_CaptureEmbeddedMode := true
SSOK_LaunchMode := "embedded-direct"

FileCreateDir, %SSOK_WorkFolder%
SSOK_StampInitTempManifest()
SSOK_CleanupDeadTempManifests()
SSOK_CleanupOldWorkFiles(1)
Gosub, SSOK_LoadState

if (!SSOK_GdipToken)
    SSOK_GdipToken := Gdip_Startup()
if (!SSOK_GdipToken)
    return

OnMessage(0x201, "SSOK_WM_LBUTTONDOWN")
OnMessage(0x202, "SSOK_WM_LBUTTONUP")
OnMessage(0x200, "SSOK_WM_MOUSEMOVE")
if (!IsLabel("SSOK_MainExitCleanup"))
    OnExit, SSOK_AppExit
SetTimer, SSOK_WatchActiveWindow, 200
SetTimer, SSOK_WorkFolderCleanupTick, 1200000
SSOK_CaptureEmbeddedInited := true
SSOK_CaptureEmbeddedInitOK := 1
return

SSOK_Capture_EmbeddedClose()
{
    global SSOK_CaptureEmbeddedMode, SSOK_CaptureEmbeddedInited, SSOK_CaptureEmbeddedInitOK, SSOK_CaptureEmbeddedStartOK, SSOK_GdipToken
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd, SSOK_StampInfoHwnd, SSOK_StampTextInputHwnd
    global SSOK_StampColorHwnd, SSOK_StampSizeHwnd, SSOK_StampEmojiHwnd, SSOK_StampPendingDropdownHwnd
    SetTimer, SSOK_UpdateActiveEditorInfo, Off
    SetTimer, SSOK_StampDragPreviewTimer, Off
    Gui, Main:Destroy
    Gui, CaptureTools:Destroy
    Gui, Editor:Destroy
    Gui, Stamp:Destroy
    SSOK_StampGuiHwnd := ""
    SSOK_StampPicHwnd := ""
    SSOK_StampInfoHwnd := ""
    SSOK_StampTextInputHwnd := ""
    SSOK_StampColorHwnd := ""
    SSOK_StampSizeHwnd := ""
    SSOK_StampEmojiHwnd := ""
    SSOK_StampPendingDropdownHwnd := ""
    SSOK_CancelDirectAreaCapture(false)
    SSOK_ClearStampUndoStack()
    SSOK_DisposeStampBitmap()
    SSOK_StampCleanupSessionTempFiles()
    SSOK_ShutdownGdip()
    SSOK_ReleaseCaptureMutex()
    SSOK_CaptureEmbeddedInited := false
    SSOK_CaptureEmbeddedInitOK := 0
    SSOK_CaptureEmbeddedStartOK := 0
    return true
}

; ------------------------------------------------------------
; ´ÙÁß Ä¸Ã³ ÆíÁý±â
; - ¸ÞÀÎ ÇÁ·Î¼¼½º´Â Win+S °¨½Ã¸¸ À¯Áö
; - ½ÇÁ¦ Ä¸Ã³/ÆíÁýÀº ÀÓ½Ã º¹»çº» ÀÚ½Ä ÇÁ·Î¼¼½º¿¡¼­ °¢°¢ µ¶¸³ ½ÇÇà
; - ÀÚ½Ä ÇÁ·Î¼¼½º¿¡¼­´Â Win+S Àü¿ª ÇÖÅ°¸¦ Á¦°ÅÇÏ¿© ÇÖÅ° Ãæµ¹ ¹æÁö
; ------------------------------------------------------------
SSOK_StartCapturePreferred()
{
    global SSOK_CaptureEmbeddedStartOK, SSOK_MultiCaptureLaunchBlocked
    liveEditors := SSOK_CountOpenCaptureEditors()
    if (liveEditors <= 0)
    {
        SSOK_CaptureEmbeddedStartOK := 0
        Gosub, SSOK_Capture_EmbeddedDirect
        return SSOK_CaptureEmbeddedStartOK
    }

    if (!SSOK_LaunchMultiCaptureEditor())
    {
        if (SSOK_MultiCaptureLaunchBlocked)
            return false
        return false
    }
    return true
}

SSOK_LaunchMultiCaptureEditor()
{
    global SSOK_WorkFolder, SSOK_MultiCaptureLaunchBlocked
    SSOK_MultiCaptureLaunchBlocked := false
    if (SSOK_WorkFolder = "")
        SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
    FileCreateDir, %SSOK_WorkFolder%
    maxEditors := 5
    liveEditors := SSOK_CountOpenCaptureEditors()
    if (liveEditors >= maxEditors)
    {
        SSOK_MultiCaptureLaunchBlocked := true
        MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, Ä¸Ã³ ÆíÁý±â´Â ÃÖ´ë %maxEditors%°³±îÁö µ¿½Ã¿¡ ¿­ ¼ö ÀÖ½À´Ï´Ù.`n»ç¿ë ÁßÀÎ ÆíÁý±â ÀÏºÎ¸¦ ´ÝÀº µÚ ´Ù½Ã Ä¸Ã³ÇØÁÖ¼¼¿ä.
        return false
    }

    if (A_IsCompiled)
    {
        exePath := A_ScriptFullPath
        if (exePath = "" || !FileExist(exePath))
            return false
        Run, "%exePath%" "direct-child" "%A_ScriptDir%",, UseErrorLevel, childPid
        if (ErrorLevel)
        {
            MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, »õ Ä¸Ã³ ÆíÁý±â ½ÇÇà¿¡ ½ÇÆÐÇß½À´Ï´Ù.
            return false
        }
        return true
    }

    sourceScript := A_LineFile
    if (sourceScript = "" || !FileExist(sourceScript))
        sourceScript := A_ScriptFullPath
    if (sourceScript = "" || !FileExist(sourceScript))
    {
        MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, ¿øº» Ä¸Ã³ ½ºÅ©¸³Æ® ÆÄÀÏÀ» Ã£Áö ¸øÇß½À´Ï´Ù.
        return false
    }

    ahkPath := A_AhkPath
    if (ahkPath = "" || !FileExist(ahkPath))
    {
        MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, AutoHotkey ½ÇÇà ÆÄÀÏÀ» Ã£Áö ¸øÇß½À´Ï´Ù.
        return false
    }

    Run, "%ahkPath%" "%sourceScript%" "direct-child" "%A_ScriptDir%",, UseErrorLevel, childPid
    if (ErrorLevel)
    {
        MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, »õ Ä¸Ã³ ÆíÁý±â ½ÇÇà¿¡ ½ÇÆÐÇß½À´Ï´Ù.
        return false
    }

    ; Ä¸Ã³ ¹üÀ§ ¼±ÅÃ ½Ã°£ÀÌ »ç¿ëÀÚ¸¶´Ù ´Ù¸£¹Ç·Î ¿©±â¼­ "Ã¢ÀÌ ¶ß´ÂÁö 5ÃÊ È®ÀÎ"Àº ÇÏÁö ¾Ê½À´Ï´Ù.
    ; ÀÚ½Ä ÇÁ·Î¼¼½º°¡ Á÷Á¢ Ä¸Ã³¸¦ ÁøÇàÇÏ°í, Ä¸Ã³ ¿Ï·á ÈÄ µ¶¸³ ÆíÁý±â Ã¢À» Ç¥½ÃÇÕ´Ï´Ù.
    return true
}

SSOK_CountOpenCaptureEditors()
{
    WinGet, editorList, List, SSOK ½ºÅ©¸° Ä¸Ã³ ÆíÁý±â ahk_class AutoHotkeyGUI
    if (editorList = "")
        return 0
    return editorList + 0
}

SSOK_PrepareCaptureEditorChildScript()
{
    global SSOK_WorkFolder
    editorDir := SSOK_WorkFolder "\editors"
    FileCreateDir, %editorDir%

    ; ½ÇÇà ÁßÀÎ ÀÚ½Ä ½ºÅ©¸³Æ®¸¦ µ¤¾î¾²Áö ¾Êµµ·Ï ¸Å¹ø °íÀ¯ ÆÄÀÏ¸íÀ» »ç¿ëÇÕ´Ï´Ù.
    FormatTime, now,, yyyyMMdd_HHmmss
    childScript := editorDir "\SSOK_capture_editor_" now "_" A_TickCount "_" A_ScriptHwnd ".ahk"

    ; Æ÷ÇÔ ÆÄÀÏ(ssok_capture.ahk)¿¡¼­ ½ÇÇàµÇ´Â °æ¿ì A_ScriptFullPath´Â ¸ÞÀÎ ssok.ahk¸¦ °¡¸®Åµ´Ï´Ù.
    ; ¸ÞÀÎ ÆÄÀÏÀ» º¹»çÇÏ¸é #Include ssok_doc.ahk °æ·Î°¡ ÀÓ½Ã Æú´õ ±âÁØÀ¸·Î ¹Ù²î¾î ¿À·ù°¡ ³ª¹Ç·Î,
    ; ½ÇÁ¦ ÀÌ ÇÔ¼ö°¡ µé¾î ÀÖ´Â Ä¸Ã³ ÆÄÀÏ(A_LineFile)À» º¹»çÇÕ´Ï´Ù.
    sourceScript := A_LineFile
    if (sourceScript = "" || !FileExist(sourceScript))
        sourceScript := A_ScriptFullPath

    FileRead, src, %sourceScript%
    if (ErrorLevel || src = "")
    {
        MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, ÀÚ½Ä ÆíÁý±â ½ºÅ©¸³Æ® »ý¼º¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n¿øº» ÆÄÀÏÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.
        return ""
    }

    ; ÀÓ½Ã º¹»çº»Àº ¼­·Î ´Ù¸¥ ÆÄÀÏ¸íÀ¸·Î ½ÇÇàµÇÁö¸¸, ¾ÈÀüÇÏ°Ô ´ÜÀÏ ½ÇÇà Á¦ÇÑµµ ÇØÁ¦ÇÕ´Ï´Ù.
    StringReplace, src, src, #SingleInstance Off, #SingleInstance Off, All

    ; ÀÚ½Ä ÇÁ·Î¼¼½º°¡ Win+S¸¦ ´Ù½Ã °¡·ÎÃ¤¸é ¸ÞÀÎ ÇÖÅ°¿Í Ãæµ¹ÇÏ¹Ç·Î,
    ; ÀÓ½Ã º¹»çº»¿¡¼­ Win+S ÇÖÅ° ºí·Ï¸¸ Á¦°ÅÇÕ´Ï´Ù.
    hotkeyStart := InStr(src, "#s::")
    labelStart := InStr(src, "SSOK_Capture_EmbeddedDirect:")
    if (hotkeyStart > 0 && labelStart > hotkeyStart)
    {
        beforeHotkey := SubStr(src, 1, hotkeyStart - 1)
        afterHotkey := SubStr(src, labelStart)
        disabledBlock := "; ´ÙÁß ÆíÁý±â ÀÚ½Ä ÇÁ·Î¼¼½º¿¡¼­´Â Win+S Àü¿ª ÇÖÅ°¸¦ µî·ÏÇÏÁö ¾Ê½À´Ï´Ù.`r`n"
        src := beforeHotkey disabledBlock afterHotkey
    }

    FileDelete, %childScript%
    FileAppend, %src%, %childScript%
    if (ErrorLevel || !FileExist(childScript))
    {
        MsgBox, 48, SSOK ½ºÅ©¸° Ä¸Ã³, ÀÚ½Ä ÆíÁý±â ½ºÅ©¸³Æ® ÆÄÀÏÀ» ¸¸µéÁö ¸øÇß½À´Ï´Ù.
        return ""
    }
    return childScript
}

SSOK_WorkFolderCleanupTick:
SSOK_CleanupWorkFolderAtNoon()
return

SSOK_CleanupWorkFolderAtNoon()
{
    global SSOK_WorkFolder, SSOK_WorkCleanupLastDate
    today := A_YYYY A_MM A_DD
    if (SSOK_WorkCleanupLastDate = today)
        return true
    ; ¾÷¹« Áß ¹æÇØ¸¦ ÁÙÀÌ±â À§ÇØ ¸ÅÀÏ 12:30 ÀÌÈÄ ÇÑ ¹ø¸¸ Á¤¸®ÇÕ´Ï´Ù.
    if (A_Hour != 12 || A_Min < 30)
        return true
    SSOK_WorkCleanupLastDate := today
    return SSOK_CleanupOldWorkFiles(24)
}

SSOK_CleanupOldWorkFiles(maxAgeHours := 24)
{
    global SSOK_WorkFolder
    if (SSOK_WorkFolder = "")
        SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
    work := RTrim(SSOK_WorkFolder, "\/")
    if (work != "" && InStr(work, "\SSOK\work\capture") && FileExist(work))
    {
        SSOK_DeleteOldFilesInDir(work, maxAgeHours)
        SSOK_RemoveEmptyDirs(work)
    }

    return true
}

SSOK_DeleteOldFilesByPattern(dir, pattern, maxAgeHours := 24)
{
    if (dir = "" || pattern = "" || !FileExist(dir))
        return false
    now := A_Now
    Loop, Files, %dir%\%pattern%, F
    {
        FileGetTime, modified, %A_LoopFileFullPath%, M
        if (modified = "")
            continue
        age := now
        EnvSub, age, %modified%, Hours
        if (age >= maxAgeHours)
            FileDelete, %A_LoopFileFullPath%
    }
    return true
}

SSOK_DeleteOldFilesInDir(dir, maxAgeHours := 24, maxDeletes := 0)
{
    if (dir = "" || !FileExist(dir))
        return false
    now := A_Now
    deleted := 0
    Loop, Files, %dir%\*.*, FR
    {
        FileGetTime, modified, %A_LoopFileFullPath%, M
        if (modified = "")
            continue
        age := now
        EnvSub, age, %modified%, Hours
        if (age >= maxAgeHours)
        {
            FileDelete, %A_LoopFileFullPath%
            deleted++
        }
    }
    return true
}

SSOK_RemoveEmptyDirs(rootDir)
{
    if (rootDir = "" || !FileExist(rootDir))
        return false
    Loop, Files, %rootDir%\*.*, DR
        FileRemoveDir, %A_LoopFileFullPath%
    return true
}

; ------------------------------------------------------------
; ±×¸²ÆÇ¿¡¼­ ¹Ù·Î ¾²´Â ´ÜÃàÅ°
; ------------------------------------------------------------
; °ú°Å ±×¸²ÆÇ ¿¬°è ´ÜÃàÅ°´Â ÀÚÃ¼ ÆíÁý±â ÀüÈ¯ ÈÄ »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.

; °ú°Å ±×¸²ÆÇ ¹øÈ£ ÀÔ·Â ¸ðµå ´ÜÃàÅ°´Â ÀÚÃ¼ ÆíÁý±â ÀüÈ¯ ÈÄ »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.

#If (SSOK_StampTextEditing)
$Enter::
SSOK_ApplyInlineTextBox()
return

$NumpadEnter::
SSOK_ApplyInlineTextBox()
return

$Esc::
SSOK_CancelInlineTextBox()
return
#If

#If (SSOK_StampEditorCtrlCHotkeyActive())
$^c::
SSOK_StampCopyCurrentToClipboard()
return
#If

#If (SSOK_StampEditorUndoHotkeyActive())
^z::
SSOK_StampUndo()
return
#If

#If (SSOK_StampEditorHotkeysActive())
$^s::
SSOK_StampSaveCurrentAsJpg()
return

$^p::
SSOK_StampPrintCurrent()
return
#If

#If (SSOK_StampTextInputFocused())
$Enter::
SSOK_StampLeaveOptionInput()
return

$NumpadEnter::
SSOK_StampLeaveOptionInput()
return

$Esc::
SSOK_StampLeaveOptionInput()
return
#If

SSOK_NumberLayerClick:
return

SSOK_StampPreparePreviewFile()
{
    global SSOK_StampPreviewFile, SSOK_LastCaptureFile
    if (!SSOK_StampRefreshPreview())
        return false
    if (SSOK_StampPreviewFile = "" || !FileExist(SSOK_StampPreviewFile))
        return false
    SSOK_LastCaptureFile := SSOK_StampPreviewFile
    return true
}
SSOK_StampPrintCurrent()
{
    global SSOK_LastCaptureFile, SSOK_StampTextEditing

    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()

    if (IsFunc("SSOK_StampPreparePreviewFile"))
        SSOK_StampPreparePreviewFile()

    if (SSOK_LastCaptureFile = "" || !FileExist(SSOK_LastCaptureFile))
    {
        ToolTip, ÀÎ¼âÇÒ ÀÌ¹ÌÁö ÆÄÀÏÀ» Ã£À» ¼ö ¾ø½À´Ï´Ù.
        SetTimer, SSOK_ClearTip, -1200
        return
    }

    Run, print "%SSOK_LastCaptureFile%"
return
}
SSOK_StampSaveClose:
SSOK_StampSaveAndClose()
return

SSOK_StampCopyClipboard:
SSOK_StampCopyCurrentToClipboard()
return

SSOK_StampExtractText:
SSOK_StampExtractTextCurrent("text")
return

SSOK_StampExtractTable:
SSOK_StampExtractTextCurrent("table")
return

SSOK_StampAutoMask:
SSOK_StampAutoMaskCurrent()
return

SSOK_StampWindowsOcr:
SSOK_StampOpenWindowsOcrTool()
return

SSOK_StampSaveJpg:
SSOK_StampSaveCurrentAsJpg()
return

SSOK_StampReduce10:
SSOK_StampReduceImage10()
return

SSOK_StampUndoLabel:
SSOK_StampUndo()
return

SSOK_StampResetNumber:
SSOK_StampNo := 1
Gosub, SSOK_SaveState
SSOK_StampUpdateInfo()
ToolTip, ¹øÈ£°¡ 1¹øÀ¸·Î ÃÊ±âÈ­µÇ¾ú½À´Ï´Ù.
SetTimer, SSOK_ClearTip, -1200
return

SSOK_StampToolNone:
SSOK_StampSetTool("none")
return

SSOK_StampToolNumber:
SSOK_StampSetTool("number")
return

SSOK_StampToolRect:
SSOK_StampSetTool("rect")
return

SSOK_StampToolArrow:
SSOK_StampSetTool("arrow")
return

SSOK_StampToolText:
SSOK_StampSetTool("text")
return

SSOK_StampToolHighlight:
SSOK_StampSetTool("highlight")
return

SSOK_StampToolMosaic:
SSOK_StampSetTool("mosaic")
return

SSOK_StampToolMaskRrn:
SSOK_StampSetTool("mask_rrn")
return

SSOK_StampToolMaskPhone:
SSOK_StampSetTool("mask_phone")
return

SSOK_StampToolMaskName:
SSOK_StampSetTool("mask_name")
return

SSOK_StampOuterBorder:
if (SSOK_StampTextEditing)
    SSOK_ApplyInlineTextBox()
if (SSOK_DrawOuterBorderOnCurrentBitmap())
{
    ToolTip, ÀÌ¹ÌÁö ¹Ù±ù Å×µÎ¸®¸¦ Ãß°¡Çß½À´Ï´Ù.
    SetTimer, SSOK_ClearTip, -1200
}
return

SSOK_StampToolEmoji:
SSOK_StampSetTool("emoji")
return

SSOK_StampOptionsChanged:
Gui, Stamp:Submit, NoHide
SSOK_NormalizeStampOptions()
SSOK_StampUpdateInlineTextBoxStyle()
SSOK_StampRefreshLastTextForOptions()
Gosub, SSOK_SaveState
SSOK_StampUpdateInfo()
return

SSOK_StampOpenPendingDropdown:
SSOK_StampOpenPendingOptionDropdown()
return

SSOK_StampIsOptionDropdownHwnd(hwnd)
{
    global SSOK_StampColorHwnd, SSOK_StampSizeHwnd, SSOK_StampEmojiHwnd
    return (hwnd != "" && (hwnd = SSOK_StampColorHwnd || hwnd = SSOK_StampSizeHwnd || hwnd = SSOK_StampEmojiHwnd))
}

SSOK_StampPrepareOptionDropdownClick(hwnd)
{
    global SSOK_StampPendingDropdownHwnd, SSOK_StampDragging, SSOK_StampTextEditing
    if (!SSOK_StampIsOptionDropdownHwnd(hwnd))
        return false
    if (!SSOK_StampTextInputFocused() && !SSOK_StampTextEditing)
        return false
    Gui, Stamp:Submit, NoHide
    SSOK_NormalizeStampOptions()
    SSOK_StampDragging := false
    SetTimer, SSOK_StampDragPreviewTimer, Off
    DllCall("ReleaseCapture")
    SSOK_StampPendingDropdownHwnd := hwnd
    SetTimer, SSOK_StampOpenPendingDropdown, -30
    return true
}

SSOK_StampOpenPendingOptionDropdown()
{
    global SSOK_StampPendingDropdownHwnd, SSOK_StampGuiHwnd
    hwnd := SSOK_StampPendingDropdownHwnd
    SSOK_StampPendingDropdownHwnd := ""
    if (hwnd = "" || SSOK_StampGuiHwnd = "")
        return false
    WinActivate, ahk_id %SSOK_StampGuiHwnd%
    DllCall("SetFocus", "Ptr", hwnd)
    PostMessage, 0x014F, 1, 0,, ahk_id %hwnd%
    return true
}

SSOK_StampTextInputFocused()
{
    global SSOK_StampGuiHwnd, SSOK_StampTextInputHwnd
    if (SSOK_StampGuiHwnd = "" || SSOK_StampTextInputHwnd = "")
        return false
    if (!WinActive("ahk_id " SSOK_StampGuiHwnd))
        return false
    return (DllCall("GetFocus", "Ptr") = SSOK_StampTextInputHwnd)
}

SSOK_StampEditorCtrlCHotkeyActive()
{
    global SSOK_StampGuiHwnd
    if (SSOK_StampGuiHwnd = "")
        return false
    return WinActive("ahk_id " SSOK_StampGuiHwnd)
}

SSOK_StampEditorUndoHotkeyActive()
{
    global SSOK_StampGuiHwnd, SSOK_StampTextEditing
    if (SSOK_StampGuiHwnd = "")
        return false
    if (!WinActive("ahk_id " SSOK_StampGuiHwnd))
        return false
    if (SSOK_StampTextEditing)
        return false
    return true
}
SSOK_StampEditorHotkeysActive()
{
    global SSOK_StampGuiHwnd, SSOK_StampTextEditing
    if (SSOK_StampGuiHwnd = "")
        return false
    if (!WinActive("ahk_id " SSOK_StampGuiHwnd))
        return false
    if (SSOK_StampTextEditing)
        return false
    if (SSOK_StampTextInputFocused())
        return false
    return true
}

SSOK_StampFocusCanvas()
{
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd
    if (SSOK_StampGuiHwnd = "")
        return false
    WinActivate, ahk_id %SSOK_StampGuiHwnd%
    if (SSOK_StampPicHwnd != "")
        DllCall("SetFocus", "Ptr", SSOK_StampPicHwnd)
    return true
}

SSOK_StampLeaveOptionInput()
{
    global SSOK_StampGuiHwnd, SSOK_StampDragging, SSOK_StampTextInputHwnd
    if (SSOK_StampGuiHwnd = "")
        return false
    Gui, Stamp:Submit, NoHide
    SSOK_NormalizeStampOptions()
    SSOK_StampUpdateInlineTextBoxStyle()
    SSOK_StampRefreshLastTextForOptions()
    Gosub, SSOK_SaveState
    SSOK_StampUpdateInfo()
    SSOK_StampDragging := false
    SetTimer, SSOK_StampDragPreviewTimer, Off
    DllCall("ReleaseCapture")
    DllCall("SetFocus", "Ptr", 0)
    WinActivate, ahk_id %SSOK_StampGuiHwnd%
    return true
}

SSOK_StampCancel:
SSOK_CloseStampEditor(false)
return

SSOK_StampPicClicked:
MouseGetPos, _stampMx, _stampMy
SSOK_StampScreenClick(_stampMx, _stampMy)
return

StampGuiClose:
SSOK_CloseStampEditor(false)
return

StampGuiEscape:
SSOK_CloseStampEditor(false)
return

; ------------------------------------------------------------
; Ä¸Ã³ ±âº» ´ë»ó Ã¢ ÃßÀû
; - Ä¸Ã³ ¹öÆ°À» Å¬¸¯ÇÏ¸é SSOK Ã¢ÀÌ È°¼ºÈ­µÇ¹Ç·Î,
;   Á÷ÀüÀÇ ½ÇÁ¦ ÀÛ¾÷ Ã¢À» ±â¾ïÇØ ±âº» Ä¸Ã³ ¹üÀ§ º¸Á¶°ªÀ¸·Î »ç¿ëÇÕ´Ï´Ù.
; ------------------------------------------------------------
SSOK_WatchActiveWindow:
_hwnd := DllCall("user32\GetForegroundWindow", "Ptr")
if (SSOK_IsUsableCaptureTarget(_hwnd))
    SSOK_LastExternalHwnd := _hwnd
return

; ------------------------------------------------------------
; »óÅÂ ÀúÀå/º¹¿ø
; ------------------------------------------------------------
SSOK_LoadState:
Gosub, SSOK_MigrateOldCaptureIni
IniRead, _n, %SSOK_StateIni%, Stamp, NextNumber, 1
SSOK_StampNo := _n + 0
if (SSOK_StampNo < 1)
    SSOK_StampNo := 1
IniRead, SSOK_StampMainColor, %SSOK_StateIni%, Stamp, Color, __NONE__
if (SSOK_StampMainColor = "__NONE__")
    IniRead, SSOK_StampMainColor, %SSOK_StateIni%, Stamp, NumberColor, »¡°­
IniRead, SSOK_StampSizeLevel, %SSOK_StateIni%, Stamp, SizeLevel, ÀÛ°Ô
IniRead, _defaultOrgName, %SSOK_StateIni%, MajorTodos, OrgName, [±â°ü¸í]
_defaultOrgName := Trim(_defaultOrgName, " `t`r`n")
if (_defaultOrgName = "")
    _defaultOrgName := "[±â°ü¸í]"
IniRead, _savedStampText, %SSOK_StateIni%, Stamp, TextInput, __SSOK_EMPTY__
_savedStampText := Trim(_savedStampText, " `t`r`n")
if (_savedStampText = "__SSOK_EMPTY__" || _savedStampText = "" || _savedStampText = "[±â°ü¸í]")
    SSOK_StampTextInput := _defaultOrgName
else
    SSOK_StampTextInput := _savedStampText
IniRead, SSOK_StampEmojiName, %SSOK_StateIni%, Stamp, EmojiName, Ã¼Å©
SSOK_NormalizeStampOptions()
return

SSOK_MigrateOldCaptureIni:
if (FileExist(SSOK_OldStateIni))
{
    IniRead, _captureIniUnified, %SSOK_StateIni%, Stamp, CaptureIniUnified, 0
    if (_captureIniUnified != 1)
    {
        IniRead, _curStampText, %SSOK_StateIni%, Stamp, TextInput, __SSOK_EMPTY__
        IniRead, _oldNextNumber, %SSOK_OldStateIni%, Stamp, NextNumber, __SSOK_EMPTY__
        IniRead, _oldColor, %SSOK_OldStateIni%, Stamp, Color, __SSOK_EMPTY__
        IniRead, _oldNumberColor, %SSOK_OldStateIni%, Stamp, NumberColor, __SSOK_EMPTY__
        IniRead, _oldSizeLevel, %SSOK_OldStateIni%, Stamp, SizeLevel, __SSOK_EMPTY__
        IniRead, _oldTextInput, %SSOK_OldStateIni%, Stamp, TextInput, __SSOK_EMPTY__
        IniRead, _oldEmojiName, %SSOK_OldStateIni%, Stamp, EmojiName, __SSOK_EMPTY__
        if (_oldNextNumber != "__SSOK_EMPTY__")
            IniWrite, %_oldNextNumber%, %SSOK_StateIni%, Stamp, NextNumber
        if (_oldColor != "__SSOK_EMPTY__")
            IniWrite, %_oldColor%, %SSOK_StateIni%, Stamp, Color
        else if (_oldNumberColor != "__SSOK_EMPTY__")
            IniWrite, %_oldNumberColor%, %SSOK_StateIni%, Stamp, Color
        if (_oldSizeLevel != "__SSOK_EMPTY__")
            IniWrite, %_oldSizeLevel%, %SSOK_StateIni%, Stamp, SizeLevel
        if (_oldTextInput != "__SSOK_EMPTY__" && _curStampText = "__SSOK_EMPTY__")
            IniWrite, %_oldTextInput%, %SSOK_StateIni%, Stamp, TextInput
        if (_oldEmojiName != "__SSOK_EMPTY__")
            IniWrite, %_oldEmojiName%, %SSOK_StateIni%, Stamp, EmojiName
        IniWrite, 1, %SSOK_StateIni%, Stamp, CaptureIniUnified
    }
}
return

SSOK_SaveState:
if (SSOK_StampGuiHwnd != "")
    Gui, Stamp:Submit, NoHide
IniWrite, %SSOK_StampNo%, %SSOK_StateIni%, Stamp, NextNumber
IniWrite, %SSOK_StampMainColor%, %SSOK_StateIni%, Stamp, Color
IniWrite, %SSOK_StampSizeLevel%, %SSOK_StateIni%, Stamp, SizeLevel
IniWrite, %SSOK_StampTextInput%, %SSOK_StateIni%, Stamp, TextInput
IniWrite, %SSOK_StampEmojiName%, %SSOK_StateIni%, Stamp, EmojiName
; ÀÌÀü ¹öÀü ini È£È¯À» À§ÇØ ±âÁ¸ Å°µµ °°Àº °ªÀ¸·Î ÀúÀåÇÕ´Ï´Ù.
IniWrite, %SSOK_StampMainColor%, %SSOK_StateIni%, Stamp, NumberColor
IniWrite, %SSOK_StampMainColor%, %SSOK_StateIni%, Stamp, RectColor
IniWrite, %SSOK_StampMainColor%, %SSOK_StateIni%, Stamp, ArrowColor
IniWrite, %SSOK_StampMainColor%, %SSOK_StateIni%, Stamp, HighlightColor
IniWrite, %SSOK_StampHighlightSize%, %SSOK_StateIni%, Stamp, HighlightSize
IniWrite, %SSOK_StampMosaicBlock%, %SSOK_StateIni%, Stamp, MosaicBlock
return

; ------------------------------------------------------------
; ¸ÞÀÎ ¸Þ´º
; ------------------------------------------------------------
SSOK_ShowMain:
; ¸ÞÀÎ ¸Þ´º´Â »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù. ½ºÅ©¸³Æ®´Â ¹é±×¶ó¿îµå¿¡¼­ Win+S Ä¸Ã³¸¸ ´ë±âÇÕ´Ï´Ù.
Gui, Main:Destroy
return

SSOK_ReturnToMainOrExit:
if (SSOK_LaunchMode = "embedded-direct" || SSOK_CaptureEmbeddedMode)
{
    SSOK_Capture_EmbeddedClose()
    return
}
if (SSOK_LaunchMode = "direct" || SSOK_LaunchMode = "direct-child")
    ExitApp
Gui, Main:Destroy
Gui, CaptureTools:Destroy
return

SSOK_ExitApp:
if (SSOK_LaunchMode = "embedded-direct" || SSOK_CaptureEmbeddedMode)
{
    SSOK_Capture_EmbeddedClose()
    return
}
ExitApp
return

; ------------------------------------------------------------
; Windows ±âº» Ä¸Ã³ µµ±¸ ½ÇÇà
; ------------------------------------------------------------
SSOK_Capture:
Gui, Main:Hide
; Ä¸Ã³ ¹æ½Ä:
; - Ä¸Ã³¸¦ ´©¸£¸é ¸¶¿ì½º ¾Æ·¡ Ã¢ Å©±â¸¦ ±âº» ¹üÀ§·Î ¸ÕÀú Àâ½À´Ï´Ù.
; - ±×´ë·Î Ä¸Ã³ÇÏ·Á¸é ¸¶¿ì½º¸¦ Âª°Ô Å¬¸¯ÇÕ´Ï´Ù.
; - ¿øÇÏ´Â ¹üÀ§¸¦ Ä¸Ã³ÇÏ·Á¸é Å¬¸¯ÇÑ Ã¤ ±æ°Ô µå·¡±×ÇÏ°í ³õ½À´Ï´Ù.
Sleep, 180
Gui, CaptureTools:Destroy
Gui, Editor:Destroy
ToolTip
SSOK_CaptureCompleted := false
; Ä¸Ã³ÇÒ ¶§¸¶´Ù ¹øÈ£ ½ºÅÆÇÁ´Â Ç×»ó 1¹øºÎÅÍ ½ÃÀÛÇÕ´Ï´Ù.
SSOK_StampNo := 1
SSOK_StampLastClickTick := 0
Gosub, SSOK_SaveState
SSOK_LastCaptureFile := ""
SSOK_EditorTool := ""
SSOK_PaintHasCapture := false
SSOK_PaintPID := ""
SSOK_CaptureStartClipboardSeq := SSOK_GetClipboardSequenceNumber()

if (!SSOK_StartDirectAreaCapture())
    Gosub, SSOK_ReturnToMainOrExit
return

SSOK_StartWindowsCapture:
Gosub, SSOK_Capture
return

SSOK_CaptureWindowUnderMouseOrLast()
{
    global SSOK_LastExternalHwnd, SSOK_CapVX, SSOK_CapVY, SSOK_CapVW, SSOK_CapVH

    ; °¡»ó È­¸é ¹üÀ§ °ªÀ» ¸ÕÀú È®º¸ÇÕ´Ï´Ù.
    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79
    SSOK_CapVX := vx, SSOK_CapVY := vy, SSOK_CapVW := vw, SSOK_CapVH := vh

    MouseGetPos, mx, my
    hwnd := SSOK_GetWindowUnderPoint(mx, my)
    if (!SSOK_IsUsableCaptureTarget(hwnd) && SSOK_IsUsableCaptureTarget(SSOK_LastExternalHwnd))
        hwnd := SSOK_LastExternalHwnd

    if (!SSOK_IsUsableCaptureTarget(hwnd))
        return false

    if (!SSOK_GetWindowRectForCapture(hwnd, wx, wy, ww, wh))
        return false

    ; È­¸é ¹ÛÀ¸·Î °ÉÄ£ Ã¢Àº ½ÇÁ¦ °¡»ó È­¸é ¾ÈÂÊ¸¸ Ä¸Ã³ÇÕ´Ï´Ù.
    if (!SSOK_ClipRectToVirtualScreen(wx, wy, ww, wh))
        return false

    if (ww < 30 || wh < 30)
        return false

    return SSOK_CaptureRectToEditor(wx, wy, ww, wh)
}

SSOK_ClipRectToVirtualScreen(ByRef x, ByRef y, ByRef w, ByRef h)
{
    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79

    right := x + w
    bottom := y + h
    vRight := vx + vw
    vBottom := vy + vh

    if (x < vx)
        x := vx
    if (y < vy)
        y := vy
    if (right > vRight)
        right := vRight
    if (bottom > vBottom)
        bottom := vBottom

    w := right - x
    h := bottom - y
    return (w > 0 && h > 0)
}

SSOK_CaptureRectToEditor(rx, ry, rw, rh)
{
    global SSOK_WorkFolder, SSOK_LastCaptureFile, SSOK_PaintHasCapture, SSOK_StampNo, SSOK_StampLastClickTick, SSOK_CaptureCompleted

    SSOK_RefreshScreen()
    Sleep, 120
    FormatTime, now,, yyyyMMdd_HHmmss
    outFile := SSOK_WorkFolder "\SSOK_direct_capture_" now "_" A_TickCount ".png"
    if (!SSOK_CaptureStampEditorRegionToFile(rx, ry, rw, rh, outFile)
        && !SSOK_CaptureExternalStampEditorRegionToFile(rx, ry, rw, rh, outFile)
        && !SSOK_CaptureScreenAreaToFile(rx, ry, rw, rh, outFile))
    {
        Gosub, SSOK_ReturnToMainOrExit
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ´ë»ó Ã¢À» ÀÌ¹ÌÁö·Î ÀúÀåÇÏÁö ¸øÇß½À´Ï´Ù.
        return 0
    }
    SSOK_LastCaptureFile := outFile
    SSOK_StampRememberTempFile(outFile)
    SSOK_CaptureCompleted := true
    SSOK_PaintHasCapture := false
    SSOK_StampNo := 1
    SSOK_StampLastClickTick := 0
    Gosub, SSOK_SaveState
    SSOK_OpenNumberStampEditor()
    return 1
}

SSOK_StartQuickRectangleCapture()
{
    ; Windows ±âº» Snipping ToolÀÇ »çÁø/Á÷»ç°¢Çü Ä¸Ã³¸¦ ¹Ù·Î ½ÃÀÛÇÕ´Ï´Ù.
    return SSOK_StartSnippingToolNewCapture()
}

SSOK_OpenSnippingTool()
{
    if (SSOK_ActivateSnippingTool())
        return true

    Run, SnippingTool.exe,, UseErrorLevel
    if (SSOK_WaitForSnippingToolWindow(18))
        return true

    Run, %A_WinDir%\System32\SnippingTool.exe,, UseErrorLevel
    if (SSOK_WaitForSnippingToolWindow(18))
        return true

    Run, explorer.exe shell:AppsFolder\Microsoft.ScreenSketch_8wekyb3d8bbwe!App,, UseErrorLevel
    if (SSOK_WaitForSnippingToolWindow(25))
        return true

    Run, ms-screensketch:,, UseErrorLevel
    if (SSOK_WaitForSnippingToolWindow(25))
        return true

    return false
}

SSOK_WaitForSnippingToolWindow(loopCount := 20)
{
    Loop, %loopCount%
    {
        Sleep, 80
        if (SSOK_ActivateSnippingTool())
            return true
    }
    return false
}

SSOK_StartSnippingToolNewCapture()
{
    ; ¹Ýµå½Ã Windows ±âº» Snipping Tool ¾Û ¾È¿¡¼­ »çÁø/Á÷»ç°¢Çü/Áö¿¬ ¾øÀ½À¸·Î ÃÊ±âÈ­ÇÑ µÚ »õ Ä¸Ã³¸¦ ½ÃÀÛÇÕ´Ï´Ù.
    ; ms-screenclip: ¿À¹ö·¹ÀÌ³ª SSOK ÀÚÃ¼ Ä¸Ã³´Â »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    SendInput, {LWin up}{RWin up}{Shift up}{Ctrl up}{Alt up}
    Sleep, 40

    if (!SSOK_OpenSnippingTool())
        return false

    Sleep, 260
    if (!SSOK_ForceSnippingToolPhotoRectangleNoDelay())
        SSOK_ForceSnippingToolRectangleNoDelay()

    Sleep, 80
    ; Áö¿¬ ¸Þ´º°¡ ¿­¸° »óÅÂ·Î ³²¾Æ ÀÖÀ¸¸é »õ Ä¸Ã³ ¹öÆ°ÀÌ ´­¸®Áö ¾ÊÀ¸¹Ç·Î ¹Ýµå½Ã ´Ý°í ÁøÇàÇÕ´Ï´Ù.
    if (SSOK_ActivateSnippingTool())
    {
        SendInput, {Esc}
        Sleep, 60
    }

    if (!SSOK_ClickSnippingToolNewCaptureButton())
    {
        if (!SSOK_ActivateSnippingTool())
            return false
        SendInput, {Esc}
        Sleep, 60
        SendInput, !n
        Sleep, 120
        SendInput, ^n
    }
    Sleep, 120
    return true
}

SSOK_ForceNativeScreenClipRectangle()
{
    ; È£È¯¿ë: ÀÌÁ¦´Â Windows ±âº» Snipping Tool ¾ÛÀÇ Á÷»ç°¢Çü ÃÊ±âÈ­ ÇÔ¼ö¸¦ »ç¿ëÇÕ´Ï´Ù.
    return SSOK_ForceSnippingToolPhotoRectangleNoDelay()
}

SSOK_ClickNativeScreenClipRectangleButton()
{
    ; È£È¯¿ë: ÀÌÁ¦´Â Windows ±âº» Snipping Tool ¾ÛÀÇ Á÷»ç°¢Çü ÃÊ±âÈ­ ÇÔ¼ö¸¦ »ç¿ëÇÕ´Ï´Ù.
    return SSOK_ForceSnippingToolPhotoRectangleNoDelay()
}

SSOK_GetMonitorBoundsFromPoint(px, py, ByRef left, ByRef top, ByRef right, ByRef bottom)
{
    SysGet, monCount, MonitorCount
    Loop, %monCount%
    {
        SysGet, mon, Monitor, %A_Index%
        if (px >= monLeft && px < monRight && py >= monTop && py < monBottom)
        {
            left := monLeft
            top := monTop
            right := monRight
            bottom := monBottom
            return true
        }
    }
    return false
}

SSOK_ForceSnippingToolPhotoMode()
{
    hwnd := SSOK_GetSnippingToolHwnd()
    if (hwnd = "")
        return false

    ; 1¼øÀ§: UI AutomationÀ¸·Î Ä¸Ã³/½ºÅ©¸°¼¦ Åä±ÛÀ» Á÷Á¢ ¼±ÅÃÇÕ´Ï´Ù.
    if (SSOK_UIA_InvokeSnippingPhotoButton(hwnd))
        return true

    ; 2¼øÀ§: ÁÂÇ¥·Î Ä«¸Þ¶ó(»çÁø Ä¸Ã³) ¹öÆ°À» ´©¸¨´Ï´Ù.
    return SSOK_ClickSnippingToolPhotoButton(hwnd)
}

SSOK_ForceSnippingToolRectangleNoDelay()
{
    return SSOK_ForceSnippingToolPhotoRectangleNoDelay()
}

SSOK_ForceSnippingToolPhotoRectangleNoDelay()
{
    if (!SSOK_ActivateSnippingTool())
        return false

    hwnd := SSOK_GetSnippingToolHwnd()
    if (hwnd = "")
        return false

    ; 1. »çÁø Ä¸Ã³ ÅÇÀ¸·Î °­Á¦ ÀüÈ¯ÇÕ´Ï´Ù. »ç¿ëÀÚ°¡ µ¿¿µ»ó/³ìÈ­ ÅÇÀ» ¸¶Áö¸·À¸·Î ½è¾îµµ ¿©±â¼­ ¹Ù²ß´Ï´Ù.
    SSOK_ForceSnippingToolPhotoMode()
    Sleep, 120

    ; 2. Á÷»ç°¢Çü ¸ðµå¸¦ ¹Ýµå½Ã ¼±ÅÃÇÕ´Ï´Ù.
    ;    UIA ¡æ ´ÜÃàÅ° ¡æ ÁÂÇ¥ Å¬¸¯À» ¼ø¼­´ë·Î ¸ðµÎ ½ÃµµÇÕ´Ï´Ù.
    rectOk := false
    if (SSOK_OpenSnippingToolModeMenu(hwnd))
    {
        Sleep, 180
        rectOk := SSOK_SelectSnippingToolRectangleFromOpenMenu(hwnd)
    }
    if (!rectOk)
    {
        if (SSOK_ActivateSnippingTool())
        {
            SendInput, !m
            Sleep, 200
            rectOk := SSOK_SelectSnippingToolRectangleFromOpenMenu(hwnd)
        }
    }
    if (!rectOk)
        rectOk := SSOK_ClickSnippingToolRectangleByCoordinate(hwnd)

    Sleep, 100

    ; 3. Áö¿¬ ¾øÀ½Àº UIA·Î ¿À·¡ Å½»öÇÏÁö ¾Ê½À´Ï´Ù.
    ;    ÀÌÀü ¹öÀüÀº ÀÌ ´Ü°è¿¡¼­ ¸Þ´º°¡ ¿­¸° Ã¤ ¸ØÃß´Â °æ¿ì°¡ ÀÖ¾î,
    ;    Alt+D ¡æ Home ¡æ Enter¸¸ ºü¸£°Ô ½ÃµµÇÏ°í Áï½Ã Esc·Î ´ÝÀº µÚ °è¼Ó ÁøÇàÇÕ´Ï´Ù.
    SSOK_TrySetSnippingToolNoDelayFast(hwnd)

    return rectOk
}

SSOK_TrySetSnippingToolNoDelayFast(hwnd)
{
    if (hwnd = "")
        return false
    if (!SSOK_ActivateSnippingTool())
        return false

    SendInput, {Esc}
    Sleep, 40
    SendInput, !d
    Sleep, 120
    SendInput, {Home}{Enter}
    Sleep, 80
    SendInput, {Esc}
    Sleep, 50
    return true
}

SSOK_ClickSnippingToolPhotoButton(hwnd)
{
    if (hwnd = "")
        return false
    CoordMode, Mouse, Screen
    MouseGetPos, oldX, oldY
    WinGetPos, sx, sy, sw, sh, ahk_id %hwnd%
    if (sx = "")
        return false

    ; Snipping Tool »ó´ÜÀÇ Ä«¸Þ¶ó ¹öÆ° À§Ä¡ÀÔ´Ï´Ù. È­¸é ¹èÀ²/À§Ä¡°¡ ´Þ¶óµµ Ã¢ ±âÁØ ÁÂÇ¥·Î ´©¸¨´Ï´Ù.
    DllCall("SetCursorPos", "Int", sx + 128, "Int", sy + 43)
    Sleep, 35
    Click
    Sleep, 80
    DllCall("SetCursorPos", "Int", oldX, "Int", oldY)
    return true
}

SSOK_OpenSnippingToolModeMenu(hwnd)
{
    if (hwnd = "")
        return false

    ; UIA·Î ÇöÀç ¸ðµå µå·Ó´Ù¿îÀ» ¸ÕÀú ¿±´Ï´Ù. ÇöÀç °ªÀÌ 'Ã¢'ÀÌ¾îµµ ÇØ´ç ¹öÆ°À» Ã£¾Æ ¿±´Ï´Ù.
    if (SSOK_UIA_InvokeInWindowByNameList(hwnd, ["Ä¸Ã³ ¸ðµå", "Ä¸Ã³ À¯Çü", "¸ðµå", "Snipping mode", "Snip mode", "Capture mode", "Á÷»ç°¢Çü", "Rectangle", "Ã¢", "Window", "ÀüÃ¼ È­¸é", "Full screen", "ÀÚÀ¯Çü", "Free-form"], ["»õ", "New", "³ìÈ­", "µ¿¿µ»ó", "ºñµð¿À", "Record", "Video", "Áö¿¬", "Delay", "ÀúÀå", "Save", "º¹»ç", "Copy"]))
        return true

    ; UIA°¡ ½ÇÆÐÇÏ¸é Alt+MÀ» ½ÃµµÇÕ´Ï´Ù.
    if (SSOK_ActivateSnippingTool())
    {
        SendInput, !m
        Sleep, 120
        return true
    }
    return false
}

SSOK_SelectSnippingToolRectangleFromOpenMenu(hwnd)
{
    ; ¿­¸° ÆË¾÷ ¸Þ´º´Â SnippingTool Ã¢ ¹ÛÀÇ Desktop ÀÚ½ÄÀ¸·Î ÀâÈ÷´Â °æ¿ì°¡ ÀÖ¾î Desktop ÀüÃ¼¿¡¼­ ¸ÕÀú Ã£½À´Ï´Ù.
    if (SSOK_UIA_InvokeDesktopByNameList(["Á÷»ç°¢Çü", "Rectangle", "Rectangular"], ["Ã¢", "Window", "ÀüÃ¼", "Full", "ÀÚÀ¯", "Free", "Áö¿¬", "Delay"]))
        return true

    ; UIA°¡ ¸Þ´º Ç×¸ñÀ» ¸ø ÀâÀ¸¸é ½ÇÁ¦ ¿­¸° ¸Þ´º Ã¹ ¹øÂ° Ç×¸ñÀ» Ã¢ ±âÁØ ÁÂÇ¥·Î Å¬¸¯ÇÕ´Ï´Ù.
    return SSOK_ClickSnippingToolRectangleMenuItemByCoordinate(hwnd)
}

SSOK_ClickSnippingToolRectangleByCoordinate(hwnd)
{
    if (hwnd = "")
        return false
    if (!SSOK_ActivateSnippingTool())
        return false

    CoordMode, Mouse, Screen
    MouseGetPos, oldX, oldY
    WinGetPos, sx, sy, sw, sh, ahk_id %hwnd%
    if (sx = "")
        return false

    ; 1) ÇöÀç ¸ðµå µå·Ó´Ù¿îÀ» ¿±´Ï´Ù.
    DllCall("SetCursorPos", "Int", sx + 232, "Int", sy + 43)
    Sleep, 35
    Click
    Sleep, 220

    ; 2) ¿­¸° ¸Þ´ºÀÇ Ã¹ ¹øÂ° Ç×¸ñÀÎ 'Á÷»ç°¢Çü'À» °­Á¦ Å¬¸¯ÇÕ´Ï´Ù.
    DllCall("SetCursorPos", "Int", sx + 258, "Int", sy + 78)
    Sleep, 35
    Click
    Sleep, 120

    DllCall("SetCursorPos", "Int", oldX, "Int", oldY)
    return true
}

SSOK_ClickSnippingToolRectangleMenuItemByCoordinate(hwnd)
{
    if (hwnd = "")
        return false
    CoordMode, Mouse, Screen
    MouseGetPos, oldX, oldY
    WinGetPos, sx, sy, sw, sh, ahk_id %hwnd%
    if (sx = "")
        return false

    ; ¿­¸° ¸ðµå ¸Þ´ºÀÇ Ã¹ ÁÙÀº Ç×»ó Á÷»ç°¢ÇüÀÔ´Ï´Ù.
    DllCall("SetCursorPos", "Int", sx + 258, "Int", sy + 78)
    Sleep, 35
    Click
    Sleep, 120
    DllCall("SetCursorPos", "Int", oldX, "Int", oldY)
    return true
}

SSOK_OpenSnippingToolDelayMenu(hwnd)
{
    if (hwnd = "")
        return false

    if (SSOK_UIA_InvokeInWindowByNameList(hwnd, ["Áö¿¬", "Delay", "Áö¿¬ ¾øÀ½", "No delay"], ["»õ", "New", "Ä¸Ã³ ¸ðµå", "Snipping mode", "Á÷»ç°¢Çü", "Rectangle", "Ã¢", "Window", "ÀüÃ¼", "Full", "ÀÚÀ¯", "Free", "ÀúÀå", "Save", "º¹»ç", "Copy"]))
        return true

    if (SSOK_ActivateSnippingTool())
    {
        SendInput, !d
        Sleep, 120
        return true
    }
    return false
}

SSOK_SelectSnippingToolNoDelayFromOpenMenu(hwnd)
{
    if (SSOK_UIA_InvokeDesktopByNameList(["Áö¿¬ ¾øÀ½", "No delay", "No Delay"], ["3", "5", "10", "ÃÊ", "second", "seconds"]))
        return true
    return false
}

SSOK_ClickSnippingToolNewCaptureButton()
{
    hwnd := SSOK_GetSnippingToolHwnd()
    if (hwnd = "")
        return false

    ; UIA·Î '»õ Ä¸Ã³'¸¦ ¸ÕÀú ´©¸£°í, ½ÇÆÐÇÏ¸é ÁÂÇ¥·Î ´©¸¨´Ï´Ù.
    if (SSOK_UIA_InvokeInWindowByNameList(hwnd, ["»õ Ä¸Ã³", "New snip", "New capture", "New"], ["ÀúÀå", "Save", "º¹»ç", "Copy", "¼³Á¤", "Settings"]))
        return true

    if (!SSOK_ActivateSnippingTool())
        return false

    CoordMode, Mouse, Screen
    MouseGetPos, oldX, oldY
    WinGetPos, sx, sy, sw, sh, ahk_id %hwnd%
    if (sx = "")
        return false

    DllCall("SetCursorPos", "Int", sx + 54, "Int", sy + 43)
    Sleep, 35
    Click
    Sleep, 120
    DllCall("SetCursorPos", "Int", oldX, "Int", oldY)
    return true
}

SSOK_UIA_InvokeInWindowByNameList(hwnd, includeList, excludeList)
{
    ; UIAutomation disabled for the current SSOK distribution.
    return false
    try
    {
        uia := ComObjCreate("UIAutomationClient.CUIAutomation")
        root := uia.ElementFromHandle(hwnd)
        if (!IsObject(root))
            return false
        condition := uia.CreateTrueCondition()
        elements := root.FindAll(4, condition)
        if (!IsObject(elements))
            return false
        return SSOK_UIA_InvokeByNameList(elements, includeList, excludeList)
    }
    catch e
    {
        return false
    }
    return false
}

SSOK_UIA_InvokeDesktopByNameList(includeList, excludeList)
{
    ; UIAutomation disabled for the current SSOK distribution.
    return false
    try
    {
        uia := ComObjCreate("UIAutomationClient.CUIAutomation")
        root := uia.GetRootElement()
        if (!IsObject(root))
            return false
        condition := uia.CreateTrueCondition()
        elements := root.FindAll(4, condition)
        if (!IsObject(elements))
            return false
        return SSOK_UIA_InvokeByNameList(elements, includeList, excludeList)
    }
    catch e
    {
        return false
    }
    return false
}

SSOK_UIA_InvokeSnippingPhotoButton(hwnd)
{
    ; UIAutomation disabled for the current SSOK distribution.
    return false
    try
    {
        uia := ComObjCreate("UIAutomationClient.CUIAutomation")
        root := uia.ElementFromHandle(hwnd)
        if (!IsObject(root))
            return false

        condition := uia.CreateTrueCondition()
        elements := root.FindAll(4, condition) ; TreeScope_Descendants = 4
        if (!IsObject(elements))
            return false

        ; ¸ÕÀú ºñ±³Àû ¸íÈ®ÇÑ ÀÌ¸§À» Ã£°í, ½ÇÆÐÇÏ¸é 'Ä¸Ã³' °è¿­ ÀÌ¸§À» Ã£½À´Ï´Ù.
        if (SSOK_UIA_InvokeByNameList(elements, ["½ºÅ©¸°¼¦", "»çÁø", "Screenshot", "Screen snip", "Screen capture"], ["³ìÈ­", "µ¿¿µ»ó", "ºñµð¿À", "Record", "Video", "»õ", "New", "ÀúÀå", "Save", "º¹»ç", "Copy"]))
            return true
        if (SSOK_UIA_InvokeByNameList(elements, ["Ä¸Ã³", "Snip"], ["»õ", "New", "³ìÈ­", "µ¿¿µ»ó", "ºñµð¿À", "Record", "Video", "ÀúÀå", "Save", "º¹»ç", "Copy", "ÀüÃ¼", "Full", "Ã¢", "Window", "ÀÚÀ¯", "Free", "Áö¿¬", "Delay"]))
            return true
    }
    catch e
    {
        return false
    }
    return false
}

SSOK_UIA_InvokeByNameList(elements, includeList, excludeList)
{
    ; UIAutomation disabled for the current SSOK distribution.
    return false
    try
    {
        count := elements.Length
        Loop, %count%
        {
            el := elements.GetElement(A_Index - 1)
            if (!IsObject(el))
                continue

            name := ""
            try
            {
                name := el.CurrentName
            }
            catch e
            {
                name := ""
            }
            if (name = "")
                continue

            if (!SSOK_TextContainsAny(name, includeList))
                continue
            if (SSOK_TextContainsAny(name, excludeList))
                continue

            if (SSOK_UIA_InvokeElement(el))
                return true
        }
    }
    catch e
    {
        return false
    }
    return false
}

SSOK_UIA_InvokeElement(el)
{
    ; UIAutomation disabled for the current SSOK distribution.
    return false
    ; InvokePattern
    try
    {
        p := el.GetCurrentPattern(10000)
        if (IsObject(p))
        {
            p.Invoke()
            Sleep, 80
            return true
        }
    }
    catch e
    {
    }

    ; TogglePattern
    try
    {
        p := el.GetCurrentPattern(10015)
        if (IsObject(p))
        {
            p.Toggle()
            Sleep, 80
            return true
        }
    }
    catch e
    {
    }

    ; SelectionItemPattern
    try
    {
        p := el.GetCurrentPattern(10010)
        if (IsObject(p))
        {
            p.Select()
            Sleep, 80
            return true
        }
    }
    catch e
    {
    }

    return false
}

SSOK_TextContainsAny(text, list)
{
    for _, word in list
    {
        if (word != "" && InStr(text, word))
            return true
    }
    return false
}

SSOK_WaitForSnippingToolCapture:
Loop, 240
{
    Sleep, 250
    if (SSOK_ClipboardHasImage())
    {
        currentSeq := SSOK_GetClipboardSequenceNumber()
        if (SSOK_CaptureStartClipboardSeq = 0 || currentSeq != SSOK_CaptureStartClipboardSeq)
        {
            ToolTip
            SSOK_CaptureCompleted := true
            SSOK_StampNo := 1
            SSOK_PaintHasCapture := false
            Sleep, 120
            FormatTime, now,, yyyyMMdd_HHmmss
            outFile := SSOK_WorkFolder "\SSOK_screenclip_" now "_" A_TickCount ".png"
            if (SSOK_SaveClipboardImageToFile(outFile) && FileExist(outFile))
            {
                SSOK_LastCaptureFile := outFile
                SSOK_StampRememberTempFile(outFile)
            }
            if (SSOK_OpenNumberStampEditor())
                return
            Gosub, SSOK_ReturnToMainOrExit
            return
        }
    }
}
ToolTip
Gosub, SSOK_ReturnToMainOrExit
return

SSOK_ForceRectangleSnipMode:
SSOK_ForceNativeScreenClipRectangle()
return

SSOK_GetSnippingToolHwnd()
{
    WinGet, hwnd, ID, ahk_exe SnippingTool.exe
    if (hwnd != "")
        return hwnd
    WinGet, hwnd, ID, ahk_exe ScreenSketch.exe
    if (hwnd != "")
        return hwnd
    return ""
}

SSOK_GetPaintHwnd()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_ActivateSnippingTool()
{
    hwnd := SSOK_GetSnippingToolHwnd()
    if (hwnd = "")
        return false
    WinActivate, ahk_id %hwnd%
    WinWaitActive, ahk_id %hwnd%,, 2
    return true
}

SSOK_CopySnippingToolImage()
{
    if (SSOK_ActivateSnippingTool())
    {
        Sleep, 180
        Clipboard := ""
        startSeq := SSOK_GetClipboardSequenceNumber()
        SendInput, ^c
        if (SSOK_WaitForClipboardImage(2.0, startSeq))
            return true
    }
    return SSOK_ClipboardHasImage()
}

SSOK_ClipboardHasImage()
{
    static pngFmt := 0
    if (!pngFmt)
        pngFmt := DllCall("user32\RegisterClipboardFormat", "Str", "PNG", "UInt")
    return DllCall("user32\IsClipboardFormatAvailable", "UInt", 2) || DllCall("user32\IsClipboardFormatAvailable", "UInt", 8) || DllCall("user32\IsClipboardFormatAvailable", "UInt", 17) || (pngFmt && DllCall("user32\IsClipboardFormatAvailable", "UInt", pngFmt))
}

SSOK_GetClipboardSequenceNumber()
{
    return DllCall("user32\GetClipboardSequenceNumber", "UInt")
}

SSOK_WaitForClipboardImage(timeoutSeconds := 2, startSeq := 0)
{
    ClipWait, %timeoutSeconds%, 1
    if (ErrorLevel)
        return false
    if (!SSOK_ClipboardHasImage())
        return false
    if (startSeq = 0)
        return true
    currentSeq := SSOK_GetClipboardSequenceNumber()
    return (currentSeq != startSeq)
}

; ------------------------------------------------------------
; SSOK Á÷Á¢ ¿µ¿ª Ä¸Ã³ + ¸Þ½ÃÁö µð½ºÆÐÃ³
; ------------------------------------------------------------
SSOK_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
    global SSOK_DirectCaptureActive, SSOK_CapHwnd
    if (SSOK_DirectCaptureActive && hwnd = SSOK_CapHwnd)
        return SSOK_Cap_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
    return SSOK_Stamp_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
}

SSOK_WM_LBUTTONUP(wParam, lParam, msg, hwnd)
{
    global SSOK_DirectCaptureActive, SSOK_CapHwnd
    if (SSOK_DirectCaptureActive && hwnd = SSOK_CapHwnd)
        return SSOK_Cap_WM_LBUTTONUP(wParam, lParam, msg, hwnd)
    return SSOK_Stamp_WM_LBUTTONUP(wParam, lParam, msg, hwnd)
}

SSOK_WM_MOUSEMOVE(wParam, lParam, msg, hwnd)
{
    global SSOK_DirectCaptureActive, SSOK_CapHwnd
    if (SSOK_DirectCaptureActive && hwnd = SSOK_CapHwnd)
        return SSOK_Cap_WM_MOUSEMOVE(wParam, lParam, msg, hwnd)
    return SSOK_Stamp_WM_MOUSEMOVE(wParam, lParam, msg, hwnd)
}

SSOK_StartDirectAreaCapture()
{
    global SSOK_DirectCaptureActive, SSOK_DirectCaptureDragging, SSOK_CapDragVisualStarted, SSOK_CapHwnd
    global SSOK_CapVX, SSOK_CapVY, SSOK_CapVW, SSOK_CapVH
    global SSOK_CapLineT, SSOK_CapLineB, SSOK_CapLineL, SSOK_CapLineR
    global SSOK_CapLineHwndT, SSOK_CapLineHwndB, SSOK_CapLineHwndL, SSOK_CapLineHwndR
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    global SSOK_CapLoopMode
    global SSOK_LastExternalHwnd

    ; Ä¸Ã³ ½ÃÀÛ ½Ã¿¡´Â ¸¶¿ì½º ¾Æ·¡ÀÇ ½ÇÁ¦ Ã¢ ÀüÃ¼¸¦ ±âº» ¹üÀ§·Î ¸ÕÀú Ç¥½ÃÇÕ´Ï´Ù.
    ; ÀÌÈÄ »ç¿ëÀÚ°¡ µå·¡±×ÇÏ¸é µå·¡±×ÇÑ ¹üÀ§·Î ÀüÈ¯ÇÏ°í, Âª°Ô Å¬¸¯ÇÏ¸é ±âº» Ã¢ ¹üÀ§¸¦ Ä¸Ã³ÇÕ´Ï´Ù.

    SSOK_DirectCaptureActive := true
    SSOK_DirectCaptureDragging := false
    SSOK_CapDragVisualStarted := false
    SSOK_CapDefaultHas := false
    SSOK_CapLoopMode := false

    SysGet, vx, 76
    SysGet, vy, 77
    SysGet, vw, 78
    SysGet, vh, 79
    SSOK_CapVX := vx, SSOK_CapVY := vy, SSOK_CapVW := vw, SSOK_CapVH := vh

    Gui, Cap:Destroy
    ; Å« ¹üÀ§ Ä¸Ã³ ¾ÈÁ¤È­:
    ; - ¾È³» ¹®±¸¸¦ ³ÖÁö ¾Ê¾Æ Ä¸Ã³ ÀÌ¹ÌÁö¿¡ ¹®±¸°¡ ÂïÈ÷Áö ¾Ê°Ô ÇÕ´Ï´Ù.
    ; - »¡°£ ¼±Àº ±âº» Ã¢ ¹üÀ§¿Í »ç¿ëÀÚ°¡ µå·¡±×ÇÑ ¹üÀ§¸¦ Ç¥½ÃÇÕ´Ï´Ù.
    Gui, Cap:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +HwndSSOK_CapHwnd
    Gui, Cap:Color, 000000
    Gui, Cap:Add, Progress, x0 y0 w1 h1 vSSOK_CapLineT cFF0000 BackgroundFF0000 Hidden, 100
    Gui, Cap:Add, Progress, x0 y0 w1 h1 vSSOK_CapLineB cFF0000 BackgroundFF0000 Hidden, 100
    Gui, Cap:Add, Progress, x0 y0 w1 h1 vSSOK_CapLineL cFF0000 BackgroundFF0000 Hidden, 100
    Gui, Cap:Add, Progress, x0 y0 w1 h1 vSSOK_CapLineR cFF0000 BackgroundFF0000 Hidden, 100

    ; Cap GUI ÀÚÃ¼´Â ¹ÝÅõ¸íÀÌ¶ó ³»ºÎ Progress ¼±µµ ÇÔ²² ¿¶¾îÁý´Ï´Ù.
    ; ±×·¡¼­ ½ÇÁ¦ »ç¿ëÀÚ°¡ º¸´Â Å×µÎ¸®´Â º°µµÀÇ Å¬¸¯ Åë°ú(+E0x20) ÃÖ»óÀ§ »¡°£ ¼± GUI·Î ÇÑ ¹ø ´õ ±×¸³´Ï´Ù.
    SSOK_CapCreateStrongBorderLines()

    Gui, Cap:Show, NA x%vx% y%vy% w%vw% h%vh%, SSOK Á÷Á¢ Ä¸Ã³
    WinSet, Transparent, 42, ahk_id %SSOK_CapHwnd%

    ; ±âº» ¹üÀ§ º¹±¸:
    ; Ä¸Ã³°¡ ½ÃÀÛµÇ¸é ÇöÀç ¸¶¿ì½º ¾Æ·¡ÀÇ ½ÇÁ¦ Ã¢ ÀüÃ¼¸¦ ¸ÕÀú »¡°£ Å×µÎ¸®·Î Àâ½À´Ï´Ù.
    MouseGetPos, initMx, initMy
    if (!SSOK_CapUpdateDefaultToMouseWindow(initMx, initMy))
        SSOK_CapSetFallbackDefaultRect(initMx, initMy)

    ; ¹üÀ§ ÁöÁ¤ ¾ÈÁ¤È­:
    ; Ä¸Ã³ ¿À¹ö·¹ÀÌ¸¦ ¶ç¿î µÚ ¹°¸® ¸¶¿ì½º »óÅÂ¸¦ Á÷Á¢ °¨½ÃÇÕ´Ï´Ù.
    ; ÂªÀº Å¬¸¯Àº ±âº» Ã¢ ¹üÀ§ Ä¸Ã³, µå·¡±× ÈÄ ³õ±â´Â µå·¡±× ¹üÀ§ Ä¸Ã³·Î Ã³¸®ÇÕ´Ï´Ù.
    return SSOK_CapRunMouseSelectionLoop()
}

SSOK_CapRunMouseSelectionLoop()
{
    global SSOK_DirectCaptureActive, SSOK_DirectCaptureDragging, SSOK_CapDragVisualStarted, SSOK_CapClickDownTick
    global SSOK_CapStartX, SSOK_CapStartY, SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    global SSOK_CapLoopMode

    SSOK_CapLoopMode := true
    SSOK_DirectCaptureDragging := false
    SSOK_CapDragVisualStarted := false

    ; Ä¸Ã³ ¹öÆ°À» ´©¸¥ ¼ÕÀÌ ¾ÆÁ÷ ¶¼¾îÁöÁö ¾ÊÀº »óÅÂ¸¦ ¸ÕÀú Á¤¸®ÇÕ´Ï´Ù.
    KeyWait, LButton
    Sleep, 60

    lastDefaultCheck := 0
    lastMx := ""
    lastMy := ""
    sx := ""
    sy := ""

    Loop
    {
        if (!SSOK_DirectCaptureActive)
        {
            SSOK_CapLoopMode := false
            return false
        }
        if (GetKeyState("Esc", "P"))
        {
            SSOK_CapLoopMode := false
            SSOK_CancelDirectAreaCapture(true)
            return false
        }
        if (GetKeyState("Enter", "P") || GetKeyState("Space", "P"))
        {
            SSOK_CapLoopMode := false
            if (SSOK_CapDefaultHas && SSOK_CapDefaultW >= 20 && SSOK_CapDefaultH >= 20)
                return SSOK_CapFinishAndCapture(SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH)
            SSOK_CancelDirectAreaCapture(false)
            return false
        }

        MouseGetPos, curMx, curMy
        ; ¸¶¿ì½º¸¦ ´©¸£±â Àü¿¡´Â ÇöÀç ¸¶¿ì½º ¾Æ·¡ Ã¢ ÀüÃ¼¸¦ ±âº» ¹üÀ§·Î °è¼Ó Ç¥½ÃÇÕ´Ï´Ù.
        ; ¸¶¿ì½º¸¦ ÀÌµ¿ÇØ ´Ù¸¥ Ã¢ À§·Î ¿Ã¸®¸é ±âº» »¡°£ Å×µÎ¸®µµ ±× Ã¢À¸·Î °»½ÅµË´Ï´Ù.
        nowTick := A_TickCount
        if ((curMx != lastMx || curMy != lastMy) && (nowTick - lastDefaultCheck >= 80))
        {
            SSOK_CapUpdateDefaultToMouseWindow(curMx, curMy)
            lastDefaultCheck := nowTick
            lastMx := curMx
            lastMy := curMy
        }

        ; ¸¶¿ì½º¸¦ ´©¸¥ ¼ø°£ÀÇ ÁÂÇ¥¸¦ ¸ÕÀú °íÁ¤ÇÕ´Ï´Ù.
        ; ÀÌ µÚ¿¡ ±âº» Ã¢ ¹üÀ§¸¦ ´Ù½Ã °»½ÅÇÏ¸é Ã¢/È­¸é ¿ÞÂÊ °æ°è¿¡¼­ ½ÃÀÛÇÑ °ÍÃ³·³ º¸ÀÏ ¼ö ÀÖ½À´Ï´Ù.
        if (GetKeyState("LButton", "P"))
        {
            sx := curMx
            sy := curMy
            break
        }


        Sleep, 10
    }

    if (sx = "" || sy = "")
        MouseGetPos, sx, sy
    SSOK_CapStartX := sx
    SSOK_CapStartY := sy
    SSOK_CapClickDownTick := A_TickCount
    SSOK_DirectCaptureDragging := true
    SSOK_CapDragVisualStarted := false

    Loop
    {
        if (!GetKeyState("LButton", "P"))
            break
        if (GetKeyState("Esc", "P"))
        {
            SSOK_CapLoopMode := false
            SSOK_CancelDirectAreaCapture(true)
            return false
        }
        MouseGetPos, cx, cy
        dx := Abs(cx - sx)
        dy := Abs(cy - sy)
        ; 6px ÀÌ»ó ¿òÁ÷ÀÌ¸é Áï½Ã »ç¿ëÀÚ ¹üÀ§·Î ÀüÈ¯ÇÕ´Ï´Ù.
        if (dx >= 6 || dy >= 6)
        {
            SSOK_CapDragVisualStarted := true
            SSOK_CapUpdateLines(sx, sy, cx, cy)
        }
        Sleep, 8
    }

    MouseGetPos, ex, ey
    SSOK_DirectCaptureDragging := false
    elapsed := A_TickCount - SSOK_CapClickDownTick
    dx := Abs(ex - sx)
    dy := Abs(ey - sy)
    SSOK_NormalizeRect(sx, sy, ex, ey, rx, ry, rw, rh)

    SSOK_CapLoopMode := false

    ; ÂªÀº Å¬¸¯/¼Õ¶³¸² ¼öÁØÀÇ ÀÌµ¿Àº ¸¶¿ì½º ¾Æ·¡ ±âº» Ã¢ ÀüÃ¼¸¦ Ä¸Ã³ÇÕ´Ï´Ù.
    ; ½ÇÁ¦·Î µå·¡±×ÇØ¼­ ³õÀº °æ¿ì¿¡¸¸ µå·¡±× ¹üÀ§¸¦ Ä¸Ã³ÇÕ´Ï´Ù.
    if (!SSOK_CapDragVisualStarted || dx < 6 || dy < 6 || rw < 20 || rh < 20)
    {
        if (SSOK_CapDefaultHas && SSOK_CapDefaultW >= 20 && SSOK_CapDefaultH >= 20)
            return SSOK_CapFinishAndCapture(SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH)
        SSOK_CancelDirectAreaCapture(false)
        SSOK_ShowToolTip("¸¶¿ì½º ¾Æ·¡ Ã¢À» Ã£Áö ¸øÇß½À´Ï´Ù. Ä¸Ã³ÇÒ ¹üÀ§¸¦ µå·¡±×ÇÏ¼¼¿ä.")
        return false
    }
    return SSOK_CapFinishAndCapture(rx, ry, rw, rh)
}

SSOK_CancelDirectAreaCapture(showMain := true)
{
    global SSOK_DirectCaptureActive, SSOK_DirectCaptureDragging, SSOK_CapDragVisualStarted, SSOK_CapHwnd, SSOK_CapLoopMode
    SSOK_CapLoopMode := false
    SSOK_DirectCaptureActive := false
    SSOK_DirectCaptureDragging := false
    SSOK_CapDragVisualStarted := false
    SSOK_CapHideLines()
    Gui, Cap:Hide
    Gui, Cap:Destroy
    SSOK_CapHwnd := ""
    SSOK_RefreshScreen()
    if (showMain)
        Gosub, SSOK_ReturnToMainOrExit
    return true
}

SSOK_Cap_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
    global SSOK_CapLoopMode
    if (SSOK_CapLoopMode)
        return 0
    global SSOK_DirectCaptureDragging, SSOK_CapDragVisualStarted, SSOK_CapClickDownTick
    global SSOK_CapStartX, SSOK_CapStartY, SSOK_CapVX, SSOK_CapVY
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    SSOK_CapStartX := SSOK_CapVX + x
    SSOK_CapStartY := SSOK_CapVY + y
    SSOK_CapClickDownTick := A_TickCount
    SSOK_DirectCaptureDragging := true
    SSOK_CapDragVisualStarted := false
    ; ÂªÀº Å¬¸¯ÀÌ¸é ±âº» Ã¢ ¹üÀ§¸¦ ±×´ë·Î Ä¸Ã³ÇØ¾ß ÇÏ¹Ç·Î,
    ; ¸¶¿ì½º¸¦ ½ÇÁ¦·Î ²ø±â Àü±îÁö´Â ±âº» Ã¢ Å×µÎ¸®¸¦ À¯ÁöÇÕ´Ï´Ù.
    return 0
}

SSOK_Cap_WM_MOUSEMOVE(wParam, lParam, msg, hwnd)
{
    global SSOK_CapLoopMode
    if (SSOK_CapLoopMode)
        return 0
    global SSOK_DirectCaptureDragging, SSOK_CapDragVisualStarted
    global SSOK_CapStartX, SSOK_CapStartY, SSOK_CapVX, SSOK_CapVY
    if (!SSOK_DirectCaptureDragging)
        return 0
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    ex := SSOK_CapVX + x
    ey := SSOK_CapVY + y
    dx := Abs(ex - SSOK_CapStartX)
    dy := Abs(ey - SSOK_CapStartY)
    ; ¼Õ¶³¸² ¼öÁØÀÇ ÀÌµ¿Àº ¹üÀ§ ÁöÁ¤À¸·Î º¸Áö ¾Ê½À´Ï´Ù.
    ; ÀÌ¶§´Â ¸¶¿ì½º ¾Æ·¡ Ã¢ ±âº» Å×µÎ¸®¸¦ °è¼Ó º¸¿©ÁÝ´Ï´Ù.
    if (!SSOK_CapDragVisualStarted && dx < 12 && dy < 12)
        return 0
    SSOK_CapDragVisualStarted := true
    SSOK_CapUpdateLines(SSOK_CapStartX, SSOK_CapStartY, ex, ey)
    return 0
}

SSOK_Cap_WM_LBUTTONUP(wParam, lParam, msg, hwnd)
{
    global SSOK_CapLoopMode
    if (SSOK_CapLoopMode)
        return 0
    global SSOK_DirectCaptureDragging, SSOK_CapDragVisualStarted, SSOK_CapClickDownTick
    global SSOK_CapStartX, SSOK_CapStartY, SSOK_CapVX, SSOK_CapVY
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    if (!SSOK_DirectCaptureDragging)
        return 0
    SSOK_DirectCaptureDragging := false
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    ex := SSOK_CapVX + x
    ey := SSOK_CapVY + y
    dx := Abs(ex - SSOK_CapStartX)
    dy := Abs(ey - SSOK_CapStartY)
    elapsed := A_TickCount - SSOK_CapClickDownTick
    SSOK_NormalizeRect(SSOK_CapStartX, SSOK_CapStartY, ex, ey, rx, ry, rw, rh)

    ; ÂªÀº Å¬¸¯/¼Õ¶³¸² ¼öÁØÀÇ ÀÌµ¿Àº ±âº» Ã¢ ¹üÀ§¸¦ Ä¸Ã³ÇÕ´Ï´Ù.
    ; »ç¿ëÀÚ°¡ ½ÇÁ¦·Î µå·¡±×ÇÑ °æ¿ì¿¡¸¸ µå·¡±× ¹üÀ§¸¦ Ä¸Ã³ÇÕ´Ï´Ù.
    if (!SSOK_CapDragVisualStarted || dx < 12 || dy < 12 || rw < 20 || rh < 20)
    {
        if (SSOK_CapDefaultHas && SSOK_CapDefaultW >= 20 && SSOK_CapDefaultH >= 20)
            return SSOK_CapFinishAndCapture(SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH)
        SSOK_CancelDirectAreaCapture(false)
        SSOK_ShowToolTip("¸¶¿ì½º ¾Æ·¡ Ã¢À» Ã£Áö ¸øÇß½À´Ï´Ù. Ä¸Ã³ÇÒ ¹üÀ§¸¦ µå·¡±×ÇÏ¼¼¿ä.")
        return 0
    }
    return SSOK_CapFinishAndCapture(rx, ry, rw, rh)
}

SSOK_CapCaptureDefault()
{
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    if (SSOK_CapDefaultHas && SSOK_CapDefaultW >= 20 && SSOK_CapDefaultH >= 20)
        return SSOK_CapFinishAndCapture(SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH)
    SSOK_CancelDirectAreaCapture(false)
    return 0
}

SSOK_CapFinishAndCapture(rx, ry, rw, rh)
{
    global SSOK_DirectCaptureActive, SSOK_DirectCaptureDragging, SSOK_CapDragVisualStarted, SSOK_CapHwnd, SSOK_CapDefaultHas, SSOK_CapLoopMode
    SSOK_CapLoopMode := false
    SSOK_DirectCaptureDragging := false
    SSOK_CapDragVisualStarted := false
    SSOK_DirectCaptureActive := false
    SSOK_CapDefaultHas := false
    ; Ä¸Ã³¿ë ¾îµÎ¿î µ¤°³¿Í »¡°£ ¼±À» ¸ÕÀú ¿ÏÀüÈ÷ Á¦°ÅÇÑ µÚ ½ÇÁ¦ È­¸éÀ» ÀúÀåÇÕ´Ï´Ù.
    SSOK_CapHideLines()
    Gui, Cap:Hide
    Gui, Cap:Destroy
    SSOK_CapHwnd := ""
    SSOK_RefreshScreen()
    Sleep, 220

    ; Áß¿ä: ±âÁ¸¿¡´Â Ä¸Ã³/ÆíÁý±â ¿­±â°¡ ¼º°øÇØµµ Ç×»ó 0À» ¹ÝÈ¯Çß½À´Ï´Ù.
    ; ±×·¡¼­ ÀüÃ¼ Ã¢ Ä¸Ã³Ã³·³ Á¤»ó ¿Ï·áµÈ °æ¿ì¿¡µµ »óÀ§ SSOK_Capture¿¡¼­
    ; "Ä¸Ã³¸¦ ½ÃÀÛÇÏÁö ¸øÇß½À´Ï´Ù" ¸Þ½ÃÁö°¡ ¶ã ¼ö ÀÖ¾ú½À´Ï´Ù.
    ; ½ÇÁ¦ Ä¸Ã³ °á°ú¸¦ ±×´ë·Î ¹ÝÈ¯ÇÏµµ·Ï ¼öÁ¤ÇÕ´Ï´Ù.
    captureOk := SSOK_CaptureRectToEditor(rx, ry, rw, rh)
    return captureOk ? 1 : 0
}

SSOK_GetWindowUnderPoint(x, y)
{
    ssokHwnd := SSOK_GetSsokGuiWindowAtPoint(x, y)
    if (SSOK_IsUsableCaptureTarget(ssokHwnd))
        return ssokHwnd

    ; POINT ±¸Á¶¸¦ Int64·Î Àü´ÞÇØ ¸¶¿ì½º ¾Æ·¡ ½ÇÁ¦ Ã¢ ÇÚµéÀ» ¾ò½À´Ï´Ù.
    ; Ä¸Ã³ ¿À¹ö·¹ÀÌ°¡ ¶° ÀÖ´Â »óÅÂ¿¡¼­´Â WindowFromPoint°¡ SSOK ¿À¹ö·¹ÀÌ¸¦ ¸ÕÀú ÀâÀ» ¼ö ÀÖÀ¸¹Ç·Î,
    ; ±× °æ¿ì¿¡´Â Z-order Ã¢ ¸ñ·Ï¿¡¼­ ÇØ´ç ÁÂÇ¥¸¦ Æ÷ÇÔÇÏ´Â ½ÇÁ¦ ÀÛ¾÷ Ã¢À» ´Ù½Ã Ã£½À´Ï´Ù.
    point := ((y & 0xFFFFFFFF) << 32) | (x & 0xFFFFFFFF)
    hwnd := DllCall("user32\WindowFromPoint", "Int64", point, "Ptr")
    if (hwnd)
    {
        root := DllCall("user32\GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr") ; GA_ROOT
        if (root)
            hwnd := root
        if (SSOK_IsUsableCaptureTarget(hwnd))
            return hwnd
    }
    return SSOK_FindTopUsableWindowAtPoint(x, y)
}

SSOK_GetSsokGuiWindowAtPoint(x, y)
{
    global SSOK_SidebarHwnd, SSOK_SidebarMiniHwnd
    if (SSOK_IsPointInsideCaptureWindow(SSOK_SidebarHwnd, x, y))
        return SSOK_SidebarHwnd
    if (SSOK_IsPointInsideCaptureWindow(SSOK_SidebarMiniHwnd, x, y))
        return SSOK_SidebarMiniHwnd
    return ""
}

SSOK_IsPointInsideCaptureWindow(hwnd, x, y)
{
    if (!hwnd)
        return false
    if (!SSOK_GetWindowRectForCapture(hwnd, wx, wy, ww, wh))
        return false
    return (x >= wx && x <= wx + ww && y >= wy && y <= wy + wh)
}

SSOK_FindTopUsableWindowAtPoint(x, y)
{
    ; Ä¸Ã³ ¿À¹ö·¹ÀÌ°¡ ¸¶¿ì½º ¾Æ·¡ Ã¢À» °¡¸®´Â »óÈ² º¸¿Ï¿ëÀÔ´Ï´Ù.
    ; WinGet List´Â ´ëÃ¼·Î Z-order ¼ø¼­·Î ¹ÝÈ¯µÇ¹Ç·Î, °¡Àå À§¿¡ ÀÖ´Â ½ÇÁ¦ Ã¢ºÎÅÍ °Ë»çÇÕ´Ï´Ù.
    WinGet, ids, List
    Loop, %ids%
    {
        hwnd := ids%A_Index%
        if (!SSOK_IsUsableCaptureTarget(hwnd))
            continue
        if (!SSOK_GetWindowRectForCapture(hwnd, wx, wy, ww, wh))
            continue
        if (x >= wx && x <= wx + ww && y >= wy && y <= wy + wh)
            return hwnd
    }
    return ""
}

SSOK_CapUpdateDefaultToMouseWindow(mx := "", my := "")
{
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    if (mx = "" || my = "")
        MouseGetPos, mx, my

    if (SSOK_CapSetDefaultStampImageRect(mx, my))
        return true

    if (SSOK_CapSetDefaultExternalStampImageRect(mx, my))
        return true

    hwnd := SSOK_GetWindowUnderPoint(mx, my)
    if (hwnd && SSOK_GetWindowRectForCapture(hwnd, wx, wy, ww, wh))
    {
        if (SSOK_CapDefaultHas && wx = SSOK_CapDefaultX && wy = SSOK_CapDefaultY && ww = SSOK_CapDefaultW && wh = SSOK_CapDefaultH)
            return true
        return SSOK_CapSetDefaultWindowRect(hwnd, mx, my)
    }

    ; ¹ÙÅÁÈ­¸é/ºó È­¸éÃ³·³ Ä¸Ã³ ´ë»ó Ã¢ÀÌ ¾ø´Â °÷¿¡¼­´Â ¸¶¿ì½º°¡ ÀÖ´Â ¸ð´ÏÅÍ ÀüÃ¼¸¦ ±âº» ¹üÀ§·Î Ç¥½ÃÇÕ´Ï´Ù.
    return SSOK_CapSetMonitorDefaultRect(mx, my)
}

SSOK_CapSetDefaultStampImageRect(mx := "", my := "")
{
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    if (!SSOK_GetStampEditorImageScreenRect(px, py, pw, ph))
        return false
    if (mx = "" || my = "")
        MouseGetPos, mx, my
    if (mx < px || mx > px + pw || my < py || my > py + ph)
        return false
    if (pw < 20 || ph < 20)
        return false
    if (SSOK_CapDefaultHas && px = SSOK_CapDefaultX && py = SSOK_CapDefaultY && pw = SSOK_CapDefaultW && ph = SSOK_CapDefaultH)
        return true
    SSOK_CapDefaultHas := true
    SSOK_CapDefaultX := px
    SSOK_CapDefaultY := py
    SSOK_CapDefaultW := pw
    SSOK_CapDefaultH := ph
    SSOK_CapUpdateLines(px, py, px + pw, py + ph)
    return true
}

SSOK_CapSetDefaultExternalStampImageRect(mx := "", my := "")
{
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    if (mx = "" || my = "")
        MouseGetPos, mx, my
    if (!SSOK_ReadBestEditorInfo(mx, my, 1, 1, px, py, pw, ph, previewFile))
        return false
    if (mx < px || mx > px + pw || my < py || my > py + ph)
        return false
    if (pw < 20 || ph < 20)
        return false
    if (SSOK_CapDefaultHas && px = SSOK_CapDefaultX && py = SSOK_CapDefaultY && pw = SSOK_CapDefaultW && ph = SSOK_CapDefaultH)
        return true
    SSOK_CapDefaultHas := true
    SSOK_CapDefaultX := px
    SSOK_CapDefaultY := py
    SSOK_CapDefaultW := pw
    SSOK_CapDefaultH := ph
    SSOK_CapUpdateLines(px, py, px + pw, py + ph)
    return true
}

SSOK_CapSetMonitorDefaultRect(mx := "", my := "")
{
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    global SSOK_CapVX, SSOK_CapVY, SSOK_CapVW, SSOK_CapVH
    if (mx = "" || my = "")
        MouseGetPos, mx, my

    if (SSOK_GetMonitorBoundsFromPoint(mx, my, monLeft, monTop, monRight, monBottom))
    {
        wx := monLeft
        wy := monTop
        ww := monRight - monLeft
        wh := monBottom - monTop
    }
    else
    {
        wx := SSOK_CapVX
        wy := SSOK_CapVY
        ww := SSOK_CapVW
        wh := SSOK_CapVH
    }

    if (ww < 20 || wh < 20)
        return false
    if (SSOK_CapDefaultHas && wx = SSOK_CapDefaultX && wy = SSOK_CapDefaultY && ww = SSOK_CapDefaultW && wh = SSOK_CapDefaultH)
        return true

    SSOK_CapDefaultHas := true
    SSOK_CapDefaultX := wx
    SSOK_CapDefaultY := wy
    SSOK_CapDefaultW := ww
    SSOK_CapDefaultH := wh
    SSOK_CapUpdateLines(wx, wy, wx + ww, wy + wh)
    return true
}

SSOK_IsUsableCaptureTarget(hwnd)
{
    global SSOK_MainHwnd, SSOK_CapHwnd, SSOK_StampGuiHwnd, SSOK_ToolHwnd, SSOK_EditorHwnd
    if (!hwnd)
        return false
    if (hwnd = SSOK_MainHwnd || hwnd = SSOK_CapHwnd || hwnd = SSOK_StampGuiHwnd || hwnd = SSOK_ToolHwnd || hwnd = SSOK_EditorHwnd)
        return false
    WinGetClass, cls, ahk_id %hwnd%
    if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd" || cls = "Button")
        return false
    if (cls = "AutoHotkeyGUI" && !SSOK_IsAllowedSsokGuiCaptureTarget(hwnd))
        return false
    WinGet, mm, MinMax, ahk_id %hwnd%
    if (mm = -1)
        return false
    WinGet, style, Style, ahk_id %hwnd%
    if (!(style & 0x10000000)) ; WS_VISIBLE
        return false
    if (!SSOK_GetWindowRectForCapture(hwnd, wx, wy, ww, wh))
        return false
    return (ww >= 30 && wh >= 30)
}

SSOK_IsAllowedSsokGuiCaptureTarget(hwnd)
{
    global SSOK_SidebarHwnd, SSOK_SidebarMiniHwnd
    if (hwnd = SSOK_SidebarHwnd || hwnd = SSOK_SidebarMiniHwnd)
        return true
    WinGetTitle, title, ahk_id %hwnd%
    return (title = "½ï(SSOK)" || title = "SSOK ¹Ù·Îº¸±â")
}

SSOK_GetWindowRectForCapture(hwnd, ByRef wx, ByRef wy, ByRef ww, ByRef wh)
{
    wx := 0, wy := 0, ww := 0, wh := 0
    if (!hwnd)
        return false

    ; DWM È®Àå ÇÁ·¹ÀÓ ±âÁØÀÌ ½ÇÁ¦ º¸ÀÌ´Â Ã¢ ¿µ¿ª¿¡ ´õ °¡±õ½À´Ï´Ù.
    VarSetCapacity(rc, 16, 0)
    dwmOk := false
    if (DllCall("GetModuleHandle", "Str", "dwmapi.dll", "Ptr"))
    {
        hr := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", &rc, "UInt", 16, "Int") ; DWMWA_EXTENDED_FRAME_BOUNDS
        if (hr = 0)
            dwmOk := true
    }
    if (!dwmOk)
    {
        if (!DllCall("user32\GetWindowRect", "Ptr", hwnd, "Ptr", &rc))
            return false
    }
    left := NumGet(rc, 0, "Int")
    top := NumGet(rc, 4, "Int")
    right := NumGet(rc, 8, "Int")
    bottom := NumGet(rc, 12, "Int")
    wx := left
    wy := top
    ww := right - left
    wh := bottom - top
    return (ww > 0 && wh > 0)
}

SSOK_CapSetDefaultWindowRect(hwnd, mx := "", my := "")
{
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    global SSOK_CapVX, SSOK_CapVY, SSOK_CapVW, SSOK_CapVH, SSOK_MainHwnd
    if (!hwnd)
        return false
    if (hwnd = SSOK_MainHwnd)
        return false
    if (!SSOK_GetWindowRectForCapture(hwnd, wx, wy, ww, wh))
        return false
    if (ww < 20 || wh < 20)
        return false
    ; È­¸é ¹ÛÀ¸·Î Æ¢¾î³ª°£ Ã¢µµ °¡»ó È­¸é ¾ÈÀ¸·Î º¸Á¤ÇÕ´Ï´Ù.
    if (wx < SSOK_CapVX)
    {
        ww := ww - (SSOK_CapVX - wx)
        wx := SSOK_CapVX
    }
    if (wy < SSOK_CapVY)
    {
        wh := wh - (SSOK_CapVY - wy)
        wy := SSOK_CapVY
    }
    if (wx + ww > SSOK_CapVX + SSOK_CapVW)
        ww := SSOK_CapVX + SSOK_CapVW - wx
    if (wy + wh > SSOK_CapVY + SSOK_CapVH)
        wh := SSOK_CapVY + SSOK_CapVH - wy
    if (ww < 20 || wh < 20)
        return false
    SSOK_CapDefaultHas := true
    SSOK_CapDefaultX := wx
    SSOK_CapDefaultY := wy
    SSOK_CapDefaultW := ww
    SSOK_CapDefaultH := wh
    SSOK_CapUpdateLines(wx, wy, wx + ww, wy + wh)
    return true
}

SSOK_CapSetFallbackDefaultRect(mx, my)
{
    global SSOK_CapDefaultHas, SSOK_CapDefaultX, SSOK_CapDefaultY, SSOK_CapDefaultW, SSOK_CapDefaultH
    global SSOK_CapVX, SSOK_CapVY, SSOK_CapVW, SSOK_CapVH
    if (mx = "" || my = "")
    {
        mx := SSOK_CapVX + Round(SSOK_CapVW / 2)
        my := SSOK_CapVY + Round(SSOK_CapVH / 2)
    }
    w := 800, h := 500
    if (w > SSOK_CapVW)
        w := SSOK_CapVW
    if (h > SSOK_CapVH)
        h := SSOK_CapVH
    x := mx - Round(w / 2)
    y := my - Round(h / 2)
    if (x < SSOK_CapVX)
        x := SSOK_CapVX
    if (y < SSOK_CapVY)
        y := SSOK_CapVY
    if (x + w > SSOK_CapVX + SSOK_CapVW)
        x := SSOK_CapVX + SSOK_CapVW - w
    if (y + h > SSOK_CapVY + SSOK_CapVH)
        y := SSOK_CapVY + SSOK_CapVH - h
    if (x < SSOK_CapVX)
        x := SSOK_CapVX
    if (y < SSOK_CapVY)
        y := SSOK_CapVY
    SSOK_CapDefaultHas := true
    SSOK_CapDefaultX := x
    SSOK_CapDefaultY := y
    SSOK_CapDefaultW := w
    SSOK_CapDefaultH := h
    SSOK_CapUpdateLines(x, y, x + w, y + h)
    return true
}

#If (SSOK_DirectCaptureActive)
Enter::
SSOK_CapCaptureDefault()
return

Space::
SSOK_CapCaptureDefault()
return

Esc::
SSOK_CancelDirectAreaCapture(true)
return
#If

SSOK_CapUpdateLines(x1, y1, x2, y2)
{
    global SSOK_CapVX, SSOK_CapVY, SSOK_CapVW, SSOK_CapVH
    SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
    if (rw < 1)
        rw := 1
    if (rh < 1)
        rh := 1
    ; »ç¿ëÀÚ°¡ ¸¶¿ì½º ¾Æ·¡ Ã¢ ±âº» ¹üÀ§¿Í Á÷Á¢ ÁöÁ¤ ¹üÀ§¸¦ È®½ÇÈ÷ º¼ ¼ö ÀÖµµ·Ï Ç¥½ÃÇÏµÇ, ³Ê¹« µÎ²®Áö ¾Ê°Ô Áß°£ ±½±â·Î Á¶Á¤ÇÕ´Ï´Ù.
    t := 4
    ; È­¸é ÁÂÇ¥¸¦ Cap GUI ³»ºÎ ÁÂÇ¥·Î º¯È¯ÇÕ´Ï´Ù.
    relX := rx - SSOK_CapVX
    relY := ry - SSOK_CapVY
    if (relX < 0)
        relX := 0
    if (relY < 0)
        relY := 0
    if (relX + rw > SSOK_CapVW)
        rw := SSOK_CapVW - relX
    if (relY + rh > SSOK_CapVH)
        rh := SSOK_CapVH - relY
    if (rw < 1 || rh < 1)
        return false
    SSOK_CapMoveLine("T", relX, relY, rw, t)
    SSOK_CapMoveLine("B", relX, relY + rh - t, rw, t)
    SSOK_CapMoveLine("L", relX, relY, t, rh)
    SSOK_CapMoveLine("R", relX + rw - t, relY, t, rh)
    return true
}

SSOK_CapMoveLine(name, x, y, w, h)
{
    global SSOK_CapVX, SSOK_CapVY
    ctrl := "SSOK_CapLine" name
    if (w < 1)
        w := 1
    if (h < 1)
        h := 1

    ; ¹ÝÅõ¸í Cap GUI ³»ºÎ ¼±µµ À¯ÁöÇÏµÇ, ½ÇÁ¦ ½ÃÀÎ¼ºÀº ¾Æ·¡ º°µµ »¡°£ ¼± GUI°¡ ´ã´çÇÕ´Ï´Ù.
    GuiControl, Cap:MoveDraw, %ctrl%, x%x% y%y% w%w% h%h%
    GuiControl, Cap:Show, %ctrl%

    ax := SSOK_CapVX + x
    ay := SSOK_CapVY + y
    SSOK_CapShowStrongBorderLine(name, ax, ay, w, h)
    return true
}

SSOK_CapCreateStrongBorderLines()
{
    global SSOK_CapLineHwndT, SSOK_CapLineHwndB, SSOK_CapLineHwndL, SSOK_CapLineHwndR

    Gui, CapLineT:Destroy
    Gui, CapLineB:Destroy
    Gui, CapLineL:Destroy
    Gui, CapLineR:Destroy

    Gui, CapLineT:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +HwndSSOK_CapLineHwndT
    Gui, CapLineT:Color, FF0000
    Gui, CapLineB:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +HwndSSOK_CapLineHwndB
    Gui, CapLineB:Color, FF0000
    Gui, CapLineL:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +HwndSSOK_CapLineHwndL
    Gui, CapLineL:Color, FF0000
    Gui, CapLineR:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +HwndSSOK_CapLineHwndR
    Gui, CapLineR:Color, FF0000
    return true
}

SSOK_CapShowStrongBorderLine(name, x, y, w, h)
{
    if (w < 1)
        w := 1
    if (h < 1)
        h := 1

    if (name = "T")
        Gui, CapLineT:Show, NA x%x% y%y% w%w% h%h%
    else if (name = "B")
        Gui, CapLineB:Show, NA x%x% y%y% w%w% h%h%
    else if (name = "L")
        Gui, CapLineL:Show, NA x%x% y%y% w%w% h%h%
    else if (name = "R")
        Gui, CapLineR:Show, NA x%x% y%y% w%w% h%h%
    return true
}

; È£È¯¿ë: ±âÁ¸ º°µµ ¼± GUI »ý¼º ÇÔ¼ö´Â ´õ ÀÌ»ó »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
SSOK_CapShowLine(name, x, y, w, h)
{
    return true
}

SSOK_CapHideLines()
{
    global SSOK_CapHwnd
    if (SSOK_CapHwnd = "")
    {
        Gui, CapLineT:Destroy
        Gui, CapLineB:Destroy
        Gui, CapLineL:Destroy
        Gui, CapLineR:Destroy
        return true
    }
    GuiControl, Cap:Hide, SSOK_CapLineT
    GuiControl, Cap:Hide, SSOK_CapLineB
    GuiControl, Cap:Hide, SSOK_CapLineL
    GuiControl, Cap:Hide, SSOK_CapLineR
    ; º°µµ ÃÖ»óÀ§ »¡°£ ¼± GUIµµ °°ÀÌ Á¤¸®ÇÕ´Ï´Ù.
    Gui, CapLineT:Destroy
    Gui, CapLineB:Destroy
    Gui, CapLineL:Destroy
    Gui, CapLineR:Destroy
    return true
}

SSOK_RefreshScreen()
{
    ; Ä¸Ã³ µ¤°³/»¡°£ ¼±À» ¾ø¾Ø µÚ Windows¿¡ È­¸éÀ» ´Ù½Ã ±×¸®°Ô ÇØ¼­ ÀÜ»óÀ» ÁÙÀÔ´Ï´Ù.
    DllCall("user32\RedrawWindow", "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
    return true
}

SSOK_CaptureScreenAreaToFile(x, y, w, h, outFile)
{
    if (w < 1 || h < 1 || outFile = "")
        return false

    capX := x
    capY := y
    capW := w
    capH := h
    SSOK_AdjustScreenCaptureRectForDpi(capX, capY, capW, capH)

    hdcScreen := 0
    hdcMem := 0
    hbm := 0
    obm := 0
    pBitmap := 0
    result := false

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    if (!hdcScreen)
        goto SSOK_CaptureScreenAreaToFile_Cleanup

    hdcMem := DllCall("gdi32\CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    if (!hdcMem)
        goto SSOK_CaptureScreenAreaToFile_Cleanup

    VarSetCapacity(bi, 40, 0)
    NumPut(40, bi, 0, "UInt")
    NumPut(capW, bi, 4, "Int")
    NumPut(-capH, bi, 8, "Int")
    NumPut(1, bi, 12, "UShort")
    NumPut(32, bi, 14, "UShort")
    NumPut(0, bi, 16, "UInt")
    hbm := DllCall("gdi32\CreateDIBSection", "Ptr", hdcScreen, "Ptr", &bi, "UInt", 0, "Ptr*", bits, "Ptr", 0, "UInt", 0, "Ptr")
    if (!hbm)
        goto SSOK_CaptureScreenAreaToFile_Cleanup

    obm := DllCall("gdi32\SelectObject", "Ptr", hdcMem, "Ptr", hbm, "Ptr")
    if (!obm)
        goto SSOK_CaptureScreenAreaToFile_Cleanup

    if (!DllCall("gdi32\BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", capW, "Int", capH, "Ptr", hdcScreen, "Int", capX, "Int", capY, "UInt", 0x40CC0020))
        goto SSOK_CaptureScreenAreaToFile_Cleanup

    DllCall("gdi32\SelectObject", "Ptr", hdcMem, "Ptr", obm)
    obm := 0
    pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
    if (pBitmap)
    {
        err := Gdip_SaveBitmapToFile(pBitmap, outFile)
        result := (err = 0 && FileExist(outFile))
    }

SSOK_CaptureScreenAreaToFile_Cleanup:
    if (pBitmap)
        Gdip_DisposeImage(pBitmap)
    if (obm && hdcMem)
        DllCall("gdi32\SelectObject", "Ptr", hdcMem, "Ptr", obm)
    if (hbm)
        DllCall("gdi32\DeleteObject", "Ptr", hbm)
    if (hdcMem)
        DllCall("gdi32\DeleteDC", "Ptr", hdcMem)
    if (hdcScreen)
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    return result
}
SSOK_GetStampEditorImageScreenRect(ByRef x, ByRef y, ByRef w, ByRef h)
{
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd, SSOK_StampDisplayW, SSOK_StampDisplayH, SSOK_StampBitmap
    x := "", y := "", w := "", h := ""
    if (SSOK_StampGuiHwnd = "" || SSOK_StampPicHwnd = "" || !SSOK_StampBitmap)
        return false
    WinGetPos, x, y, w, h, ahk_id %SSOK_StampPicHwnd%
    if (x = "" || y = "")
        return false
    if (w = "" || w < 1)
        w := SSOK_StampDisplayW
    if (h = "" || h < 1)
        h := SSOK_StampDisplayH
    return (w >= 1 && h >= 1)
}

SSOK_CaptureStampEditorRegionToFile(x, y, w, h, outFile)
{
    global SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH
    if (!SSOK_GetStampEditorImageScreenRect(px, py, pw, ph))
        return false

    ix1 := (x > px) ? x : px
    iy1 := (y > py) ? y : py
    ix2 := ((x + w) < (px + pw)) ? (x + w) : (px + pw)
    iy2 := ((y + h) < (py + ph)) ? (y + h) : (py + ph)
    iw := ix2 - ix1
    ih := iy2 - iy1
    if (iw < 2 || ih < 2)
        return false

    ; »ç¿ëÀÚ°¡ SSOK ÆíÁýÃ¢¿¡ Ç¥½ÃµÈ Ä¸Ã³ ÀÌ¹ÌÁö¸¦ ´Ù½Ã Àâ´Â °æ¿ì,
    ; È­¸é DC ´ë½Å ³»ºÎ ¿øº» ºñÆ®¸Ê¿¡¼­ ÇØ´ç ¿µ¿ªÀ» Àß¶ó ºó È­¸é Ä¸Ã³¸¦ ÇÇÇÕ´Ï´Ù.
    sx := Round((ix1 - px) * SSOK_StampImageW / pw)
    sy := Round((iy1 - py) * SSOK_StampImageH / ph)
    sw := Round(iw * SSOK_StampImageW / pw)
    sh := Round(ih * SSOK_StampImageH / ph)
    if (sx < 0)
        sx := 0
    if (sy < 0)
        sy := 0
    if (sx + sw > SSOK_StampImageW)
        sw := SSOK_StampImageW - sx
    if (sy + sh > SSOK_StampImageH)
        sh := SSOK_StampImageH - sy
    if (sw < 1 || sh < 1)
        return false

    pCrop := Gdip_CreateBitmap(sw, sh)
    if (!pCrop)
        return false
    g := Gdip_GraphicsFromImage(pCrop)
    if (!g)
    {
        Gdip_DisposeImage(pCrop)
        return false
    }
    Gdip_SetSmoothingMode(g, 4)
    Gdip_SetInterpolationMode(g, 7)
    ok := Gdip_DrawImageRectRectI(g, SSOK_StampBitmap, 0, 0, sw, sh, sx, sy, sw, sh)
    Gdip_DeleteGraphics(g)
    if (!ok)
    {
        Gdip_DisposeImage(pCrop)
        return false
    }
    err := Gdip_SaveBitmapToFile(pCrop, outFile)
    Gdip_DisposeImage(pCrop)
    return (err = 0 && FileExist(outFile))
}

SSOK_GetEditorInfoDir()
{
    global SSOK_WorkFolder
    if (SSOK_WorkFolder = "")
        SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
    FileCreateDir, %SSOK_WorkFolder%
    infoDir := SSOK_WorkFolder "\editors_info"
    FileCreateDir, %infoDir%
    return infoDir
}

SSOK_GetActiveEditorInfoPath(editorHwnd := "")
{
    global SSOK_StampGuiHwnd
    if (editorHwnd = "")
        editorHwnd := SSOK_StampGuiHwnd
    if (editorHwnd = "")
        return SSOK_GetEditorInfoDir() "\SSOK_editor_unknown.ini"
    return SSOK_GetEditorInfoDir() "\SSOK_editor_" editorHwnd ".ini"
}

SSOK_WriteActiveEditorInfo(force := false)
{
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd, SSOK_StampPreviewFile, SSOK_ActiveEditorInfoCache, SSOK_ActiveEditorLastWriteTick
    if (SSOK_StampGuiHwnd = "" || SSOK_StampPicHwnd = "" || SSOK_StampPreviewFile = "" || !FileExist(SSOK_StampPreviewFile))
        return false
    WinGetPos, px, py, pw, ph, ahk_id %SSOK_StampPicHwnd%
    if (px = "" || py = "" || pw < 2 || ph < 2)
        return false
    sig := SSOK_StampGuiHwnd "|" SSOK_StampPicHwnd "|" px "|" py "|" pw "|" ph "|" SSOK_StampPreviewFile
    if (!force && sig = SSOK_ActiveEditorInfoCache && A_TickCount - SSOK_ActiveEditorLastWriteTick < 5000)
        return true
    infoPath := SSOK_GetActiveEditorInfoPath(SSOK_StampGuiHwnd)
    IniWrite, %SSOK_StampGuiHwnd%, %infoPath%, ActiveEditor, EditorHwnd
    IniWrite, %SSOK_StampPicHwnd%, %infoPath%, ActiveEditor, PicHwnd
    IniWrite, %px%, %infoPath%, ActiveEditor, PicX
    IniWrite, %py%, %infoPath%, ActiveEditor, PicY
    IniWrite, %pw%, %infoPath%, ActiveEditor, PicW
    IniWrite, %ph%, %infoPath%, ActiveEditor, PicH
    IniWrite, %SSOK_StampPreviewFile%, %infoPath%, ActiveEditor, PreviewFile
    IniWrite, %A_TickCount%, %infoPath%, ActiveEditor, Tick
    SSOK_ActiveEditorInfoCache := sig
    SSOK_ActiveEditorLastWriteTick := A_TickCount
    return true
}

SSOK_ReadEditorInfoFile(infoPath, ByRef px, ByRef py, ByRef pw, ByRef ph, ByRef previewFile)
{
    px := "", py := "", pw := "", ph := "", previewFile := ""
    if (!FileExist(infoPath))
        return false
    IniRead, editorHwnd, %infoPath%, ActiveEditor, EditorHwnd, 0
    IniRead, picHwnd, %infoPath%, ActiveEditor, PicHwnd, 0
    IniRead, px, %infoPath%, ActiveEditor, PicX, __NONE__
    IniRead, py, %infoPath%, ActiveEditor, PicY, __NONE__
    IniRead, pw, %infoPath%, ActiveEditor, PicW, __NONE__
    IniRead, ph, %infoPath%, ActiveEditor, PicH, __NONE__
    IniRead, previewFile, %infoPath%, ActiveEditor, PreviewFile, __NONE__
    if (px = "__NONE__" || py = "__NONE__" || pw = "__NONE__" || ph = "__NONE__" || previewFile = "__NONE__")
        return false
    if (!FileExist(previewFile))
        return false
    if (!WinExist("ahk_id " editorHwnd) || !WinExist("ahk_id " picHwnd))
        return false
    px += 0, py += 0, pw += 0, ph += 0
    return (pw >= 2 && ph >= 2)
}

SSOK_ReadActiveEditorInfo(ByRef px, ByRef py, ByRef pw, ByRef ph, ByRef previewFile)
{
    return SSOK_ReadBestEditorInfo("", "", "", "", px, py, pw, ph, previewFile)
}

SSOK_ReadBestEditorInfo(x, y, w, h, ByRef px, ByRef py, ByRef pw, ByRef ph, ByRef previewFile)
{
    px := "", py := "", pw := "", ph := "", previewFile := ""
    infoDir := SSOK_GetEditorInfoDir()
    bestArea := -1
    bestTick := -1
    Loop, Files, %infoDir%\SSOK_editor_*.ini
    {
        if (!SSOK_ReadEditorInfoFile(A_LoopFileFullPath, tx, ty, tw, th, tPreview))
        {
            FileDelete, %A_LoopFileFullPath%
            continue
        }
        IniRead, tick, %A_LoopFileFullPath%, ActiveEditor, Tick, 0
        tick += 0
        if (x != "" && y != "" && w != "" && h != "")
        {
            ix1 := (x > tx) ? x : tx
            iy1 := (y > ty) ? y : ty
            ix2 := ((x + w) < (tx + tw)) ? (x + w) : (tx + tw)
            iy2 := ((y + h) < (ty + th)) ? (y + h) : (ty + th)
            area := (ix2 > ix1 && iy2 > iy1) ? ((ix2 - ix1) * (iy2 - iy1)) : 0
        }
        else
            area := 1
        if (area > bestArea || (area = bestArea && tick > bestTick))
        {
            bestArea := area
            bestTick := tick
            px := tx, py := ty, pw := tw, ph := th, previewFile := tPreview
        }
    }
    return (bestArea > 0 && previewFile != "" && FileExist(previewFile))
}

SSOK_CaptureExternalStampEditorRegionToFile(x, y, w, h, outFile)
{
    if (!SSOK_ReadBestEditorInfo(x, y, w, h, px, py, pw, ph, previewFile))
        return false
    ix1 := (x > px) ? x : px
    iy1 := (y > py) ? y : py
    ix2 := ((x + w) < (px + pw)) ? (x + w) : (px + pw)
    iy2 := ((y + h) < (py + ph)) ? (y + h) : (py + ph)
    iw := ix2 - ix1
    ih := iy2 - iy1
    if (iw < 2 || ih < 2)
        return false
    sx := Round(ix1 - px)
    sy := Round(iy1 - py)
    sw := Round(iw)
    sh := Round(ih)
    return SSOK_CropImageFileToFile(previewFile, sx, sy, sw, sh, outFile)
}

SSOK_CropImageFileToFile(sourceFile, sx, sy, sw, sh, outFile)
{
    if (sourceFile = "" || outFile = "" || !FileExist(sourceFile) || sw < 1 || sh < 1)
        return false
    pSource := Gdip_CreateBitmapFromFile(sourceFile)
    if (!pSource)
        return false
    Gdip_GetImageDimensions(pSource, imgW, imgH)
    if (sx < 0)
        sx := 0
    if (sy < 0)
        sy := 0
    if (sx + sw > imgW)
        sw := imgW - sx
    if (sy + sh > imgH)
        sh := imgH - sy
    if (sw < 1 || sh < 1)
    {
        Gdip_DisposeImage(pSource)
        return false
    }
    pCrop := Gdip_CreateBitmap(sw, sh)
    if (!pCrop)
    {
        Gdip_DisposeImage(pSource)
        return false
    }
    g := Gdip_GraphicsFromImage(pCrop)
    if (!g)
    {
        Gdip_DisposeImage(pCrop)
        Gdip_DisposeImage(pSource)
        return false
    }
    Gdip_SetInterpolationMode(g, 7)
    ok := Gdip_DrawImageRectRectI(g, pSource, 0, 0, sw, sh, sx, sy, sw, sh)
    Gdip_DeleteGraphics(g)
    Gdip_DisposeImage(pSource)
    if (!ok)
    {
        Gdip_DisposeImage(pCrop)
        return false
    }
    err := Gdip_SaveBitmapToFile(pCrop, outFile)
    Gdip_DisposeImage(pCrop)
    return (err = 0 && FileExist(outFile))
}

; ------------------------------------------------------------
; Ä¸Ã³ ¿Ï·á ÈÄ ¸Þ´º
; ------------------------------------------------------------
SSOK_ToolText:
if (SSOK_OpenNumberStampEditor())
    SSOK_StampSetTool("text")
return

SSOK_ToolHighlight:
if (SSOK_OpenNumberStampEditor())
    SSOK_StampSetTool("highlight")
return
SSOK_ToolMosaic:
return

SSOK_ToolNumberStart:
SSOK_OpenNumberStampEditor()
return

SSOK_ToolNumberStop:
if (SSOK_StampGuiHwnd != "")
    SSOK_StampSaveAndClose()
else
    SSOK_ShowToolTip("¹øÈ£ ÀÔ·Â Ã¢ÀÌ ¿­·Á ÀÖÁö ¾Ê½À´Ï´Ù.")
return

SSOK_ToolStamp:
; F9 È£È¯¿ë: ¹øÈ£ ÀÔ·Â Ã¢À» ¿±´Ï´Ù.
SSOK_OpenNumberStampEditor()
return

SSOK_ToolSave:
if (!SSOK_FinalizeStampEditorIfOpen())
    return
Gui, CaptureTools:Hide
if (SSOK_SaveCurrentImageAs())
    SSOK_ShowToolTip("ÀÌ¹ÌÁö¸¦ ÀúÀåÇß½À´Ï´Ù.")
SSOK_ShowCaptureTools("snip")
return

SSOK_ToolRecapture:
if (!SSOK_FinalizeStampEditorIfOpen())
    return
Gui, CaptureTools:Hide
SSOK_PaintHasCapture := false
SSOK_PaintPID := ""
Gosub, SSOK_Capture
return

SSOK_ToolExit:
if (SSOK_LaunchMode = "embedded-direct" || SSOK_CaptureEmbeddedMode)
{
    SSOK_Capture_EmbeddedClose()
    return
}
ExitApp
return

SSOK_ToolExtract:
if (!SSOK_FinalizeStampEditorIfOpen())
    return
if (SSOK_LastCaptureFile != "" && FileExist(SSOK_LastCaptureFile))
{
    SSOK_ExtractTextFromCapture()
    SSOK_ShowCaptureTools("snip")
    return
}

if (SSOK_PrepareCurrentImageForOcr())
    SSOK_ExtractTextFromCapture()
SSOK_ShowCaptureTools("snip")
return

SSOK_ShowToolTip(msg)
{
    ToolTip, %msg%
    SetTimer, SSOK_ClearTip, -1900
}

SSOK_ShowCaptureTools(target := "")
{
    ; »õ ±¸Á¶¿¡¼­´Â º°µµ "Ä¸Ã³ ¿É¼Ç" floating ¸Þ´º¸¦ »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    ; Ä¸Ã³ ÈÄ ÇÊ¿äÇÑ ±â´ÉÀº SSOK Ä¸Ã³ ÆíÁýÃ¢ ¾È¿¡¼­ ¹Ù·Î Ã³¸®ÇÕ´Ï´Ù.
    global SSOK_ToolHwnd, SSOK_MenuTarget
    if (target != "")
        SSOK_MenuTarget := target
    Gui, CaptureTools:Destroy
    SSOK_ToolHwnd := ""
    return true
}
SSOK_ShowEditor()
{
    ; ÇöÀç ±¸Á¶¿¡¼­´Â Ä¸Ã³ Á÷ÈÄ SSOK GDI ÆíÁýÃ¢À» Á÷Á¢ ¿±´Ï´Ù.
    return false
}

SSOK_LoadImageDimensions(file)
{
    global SSOK_ImageW, SSOK_ImageH
    pBitmap := Gdip_CreateBitmapFromFile(file)
    if (!pBitmap)
        return false
    Gdip_GetImageDimensions(pBitmap, w, h)
    Gdip_DisposeImage(pBitmap)
    if (w < 1 || h < 1)
        return false
    SSOK_ImageW := w
    SSOK_ImageH := h
    return true
}

SSOK_Editor_LButtonDown(wParam, lParam, msg, hwnd)
{
    global SSOK_EditorHwnd, SSOK_ImageHwnd, SSOK_EditorTool
    global SSOK_ImageW, SSOK_ImageH, SSOK_DisplayW, SSOK_DisplayH

    if (hwnd != SSOK_ImageHwnd && hwnd != SSOK_EditorHwnd)
        return
    if (SSOK_EditorTool = "")
        return

    cx := lParam & 0xFFFF
    cy := (lParam >> 16) & 0xFFFF
    if (cx < 0 || cy < 0 || cx > SSOK_DisplayW || cy > SSOK_DisplayH)
        return

    ix := Round(cx * SSOK_ImageW / SSOK_DisplayW)
    iy := Round(cy * SSOK_ImageH / SSOK_DisplayH)

    if (SSOK_EditorTool = "text")
    {
        InputBox, userText, ±Û»óÀÚ, ³ÖÀ» ±ÛÀ» ÀÔ·ÂÇÏ¼¼¿ä.,, 360, 140
        if (ErrorLevel || Trim(userText) = "")
            return 0
        SSOK_ApplyTextBox(ix, iy, userText)
    }
    else if (SSOK_EditorTool = "highlight" || SSOK_EditorTool = "mosaic")
    {
        startCX := cx
        startCY := cy
        KeyWait, LButton
        MouseGetPos, endSX, endSY
        SSOK_ScreenToClient(hwnd, endSX, endSY, endCX, endCY)
        if (endCX < 0)
            endCX := 0
        if (endCY < 0)
            endCY := 0
        if (endCX > SSOK_DisplayW)
            endCX := SSOK_DisplayW
        if (endCY > SSOK_DisplayH)
            endCY := SSOK_DisplayH

        rx := (startCX < endCX) ? startCX : endCX
        ry := (startCY < endCY) ? startCY : endCY
        rw := Abs(endCX - startCX)
        rh := Abs(endCY - startCY)
        if (rw < 4 || rh < 4)
            return 0

        ix := Round(rx * SSOK_ImageW / SSOK_DisplayW)
        iy := Round(ry * SSOK_ImageH / SSOK_DisplayH)
        iw := Round(rw * SSOK_ImageW / SSOK_DisplayW)
        ih := Round(rh * SSOK_ImageH / SSOK_DisplayH)
        if (SSOK_EditorTool = "highlight")
            SSOK_ApplyHighlight(ix, iy, iw, ih)
        else
            SSOK_ApplyMosaic(ix, iy, iw, ih)
    }
    return 0
}

SSOK_ScreenToClient(hwnd, sx, sy, ByRef cx, ByRef cy)
{
    VarSetCapacity(pt, 8, 0)
    NumPut(sx, pt, 0, "Int")
    NumPut(sy, pt, 4, "Int")
    DllCall("user32\ScreenToClient", "Ptr", hwnd, "Ptr", &pt)
    cx := NumGet(pt, 0, "Int")
    cy := NumGet(pt, 4, "Int")
}

SSOK_ApplyTextBox(x, y, text)
{
    textFile := SSOK_GetPrivateWorkDir("capture") "\ssok_textbox_" A_TickCount ".txt"
    FileDelete, %textFile%
    FileAppend, %text%, %textFile%, UTF-8
    SSOK_RunImageOperation("text", x, y, 0, 0, textFile, 0)
    FileDelete, %textFile%
}

SSOK_ApplyHighlight(x, y, w, h)
{
    SSOK_RunImageOperation("highlight", x, y, w, h, "", 0)
}

SSOK_ApplyMosaic(x, y, w, h)
{
    SSOK_RunImageOperation("mosaic", x, y, w, h, "", 0)
}

SSOK_HideSnippingTool()
{
    hwnd := SSOK_GetSnippingToolHwnd()
    if (hwnd != "")
        WinMinimize, ahk_id %hwnd%
}

SSOK_HidePaint()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è Á¤¸®¸¸ ¼öÇàÇÕ´Ï´Ù.
    return true
}

SSOK_GetDefaultDownloadDir()
{
    dl := ""
    RegRead, dl, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders, {374DE290-123F-4565-9164-39C4925E467B}
    EnvGet, userProfile, USERPROFILE
    EnvGet, oneDrive, OneDrive
    if (dl != "")
    {
        dl := StrReplace(dl, "%USERPROFILE%", userProfile)
        if (oneDrive != "")
            dl := StrReplace(dl, "%OneDrive%", oneDrive)
        if (FileExist(dl))
            return dl
    }
    if (userProfile != "")
    {
        dir := userProfile "\Downloads"
        if (FileExist(dir))
            return dir
    }
    return A_Desktop
}

SSOK_GetDefaultDownloadPath(fileName)
{
    return SSOK_GetDefaultDownloadDir() "\" fileName
}

SSOK_SaveCurrentImageAs()
{
    global SSOK_LastCaptureFile, SSOK_WorkFolder, SSOK_PaintHasCapture

    FormatTime, now,, yyyyMMdd_HHmmss
    defaultPath := SSOK_GetDefaultDownloadPath("SSOK_capture_" now ".png")
    oldWD := A_WorkingDir
    defaultDir := SSOK_GetDefaultDownloadDir()
    if (defaultDir != "")
        SetWorkingDir, %defaultDir%
    Gui, Main:+OwnDialogs
    FileSelectFile, savePath, S16, %defaultPath%, ÀÌ¹ÌÁö ÀúÀå, PNG/JPG ÀÌ¹ÌÁö (*.png; *.jpg; *.jpeg)
    if (oldWD != "")
        SetWorkingDir, %oldWD%
    if (ErrorLevel)
        return false

    SplitPath, savePath, fileName, dir, ext, nameNoExt
    StringLower, extLower, ext
    if (extLower != "png" && extLower != "jpg" && extLower != "jpeg")
    {
        if (dir != "")
            savePath := dir "\" nameNoExt ".png"
        else
            savePath := nameNoExt ".png"
    }

    sourceFile := ""
    if (!SSOK_PaintHasCapture)
    {
        tempFile := SSOK_WorkFolder "\SSOK_save_snip_" now "_" A_TickCount ".png"
        if (SSOK_CopySnippingToolImage() && SSOK_SaveClipboardImageToFile(tempFile))
        {
            SSOK_LastCaptureFile := tempFile
            sourceFile := tempFile
        }
        else if (SSOK_LastCaptureFile != "" && FileExist(SSOK_LastCaptureFile))
            sourceFile := SSOK_LastCaptureFile
    }
    else if (SSOK_LastCaptureFile != "" && FileExist(SSOK_LastCaptureFile))
        sourceFile := SSOK_LastCaptureFile

    if (sourceFile = "" || !FileExist(sourceFile))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÀúÀåÇÒ ÀÌ¹ÌÁö¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.
        return false
    }

    if (!SSOK_CopyOrConvertImageFile(sourceFile, savePath))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÀÌ¹ÌÁö¸¦ ÀúÀåÇÏÁö ¸øÇß½À´Ï´Ù.`n%savePath%
        return false
    }
    return true
}

SSOK_CopyOrConvertImageFile(sourceFile, outFile)
{
    if (sourceFile = "" || outFile = "" || !FileExist(sourceFile))
        return false
    SplitPath, sourceFile,,, srcExt
    SplitPath, outFile,,, outExt
    StringLower, srcExt, srcExt
    StringLower, outExt, outExt
    if (srcExt = outExt)
    {
        FileCopy, %sourceFile%, %outFile%, 1
        return (!ErrorLevel && FileExist(outFile))
    }
    pBitmap := Gdip_CreateBitmapFromFile(sourceFile)
    if (!pBitmap)
        return false
    err := Gdip_SaveBitmapToFile(pBitmap, outFile)
    Gdip_DisposeImage(pBitmap)
    return (err = 0 && FileExist(outFile))
}

SSOK_CopyImageFileToClipboard(imageFile)
{
    if (imageFile = "" || !FileExist(imageFile))
        return false
    pBitmap := Gdip_CreateBitmapFromFile(imageFile)
    if (!pBitmap)
        return false
    ok := Gdip_SetBitmapToClipboard(pBitmap)
    Gdip_DisposeImage(pBitmap)
    return ok
}
SSOK_CommitPaintCurrentEdit()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_SavePaintCanvasToFile(outFile)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}
SSOK_SavePaintSilently()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_ClosePaint()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è Á¤¸®¸¸ ¼öÇàÇÕ´Ï´Ù.
    return true
}

SSOK_OpenImageFileInPaint(imageFile)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_SelectPaintTextTool()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_ClickPaintTextToolCenter()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î ±×¸²ÆÇ UIAutomationÀº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    return false
}

SSOK_PreparePaintTextTool()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_GetPaintWorkArea(ByRef x, ByRef y, ByRef w, ByRef h)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_CreatePaintTextBox(ByRef outX, ByRef outY)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_SetPaintTextDefaults()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î ±×¸²ÆÇ ±Û²Ã/»ö»ó ÀÚµ¿È­´Â »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    return false
}

SSOK_SelectSnippingToolHighlighter()
{
    if (SSOK_InvokeUiButton("SnippingTool|ScreenSketch|ApplicationFrameHost", "Çü±¤Ææ|Highlighter|Highlight|°­Á¶ Ç¥½Ã|°­Á¶Ç¥½Ã|Marker"))
        return true
    SendInput, !h
    Sleep, 180
    return SSOK_InvokeUiButton("SnippingTool|ScreenSketch|ApplicationFrameHost", "Çü±¤Ææ|Highlighter|Highlight|°­Á¶ Ç¥½Ã|°­Á¶Ç¥½Ã|Marker")
}

SSOK_SelectSnippingToolTextAction()
{
    if (SSOK_InvokeUiButton("SnippingTool|ScreenSketch|ApplicationFrameHost", "ÅØ½ºÆ® ÀÛ¾÷|ÅØ½ºÆ® ÃßÃâ|ÅØ½ºÆ® ½ºÄµ|Text actions|Text action|Text extractor|Text scan|Scan text|OCR"))
        return true
    SendInput, ^t
    Sleep, 180
    return SSOK_InvokeUiButton("SnippingTool|ScreenSketch|ApplicationFrameHost", "ÅØ½ºÆ® ÀÛ¾÷|ÅØ½ºÆ® ÃßÃâ|ÅØ½ºÆ® ½ºÄµ|Text actions|Text action|Text extractor|Text scan|Scan text|OCR")
}

SSOK_ClickSnippingToolApproxTool(tool)
{
    return false
}
SSOK_InvokeUiButton(processNames, patterns)
{
    ; ¿ÜºÎ ÀÚµ¿È­ È£ÃâÀ» ÁÙÀÌ±â À§ÇØ ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_OpenImageFileInSnippingTool(imageFile)
{
    if (imageFile = "" || !FileExist(imageFile))
        return false
    Run, SnippingTool.exe "%imageFile%",, UseErrorLevel
    if (SSOK_WaitForSnippingToolWindow(12))
        return true
    Run, %A_WinDir%\System32\SnippingTool.exe "%imageFile%",, UseErrorLevel
    if (SSOK_WaitForSnippingToolWindow(12))
        return true
    return false
}
SSOK_SendCurrentWorkToSnippingTool(closePaint := false)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}
SSOK_EnsurePaintHasCapture(paintTool := "")
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_PasteNextStampToPaint()
{
    ; ÀÚÃ¼ ÆíÁý±â¸¦ ¿±´Ï´Ù.
    return SSOK_OpenNumberStampEditor()
}

SSOK_NumberWatchClick:
if (!SSOK_NumberMode)
{
    SetTimer, SSOK_NumberWatchClick, Off
    SSOK_NumberPrevLButton := false
    return
}
_nowDown := GetKeyState("LButton", "P")
if (_nowDown && !SSOK_NumberPrevLButton)
{
    SSOK_NumberPrevLButton := true
    SSOK_HandlePaintNumberClick()
}
else if (!_nowDown)
{
    SSOK_NumberPrevLButton := false
}
return

SSOK_StartPaintNumberMode()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}
SSOK_StopPaintNumberMode(msg := "")
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è Á¤¸®¸¸ ¼öÇàÇÕ´Ï´Ù.
    return true
}

SSOK_FinalizePaintNumberMode(msg := "")
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è Á¤¸®¸¸ ¼öÇàÇÕ´Ï´Ù.
    return true
}

SSOK_HandlePaintNumberClick()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_ShowNumberClickLayer()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_GetNumberClickArea(ByRef x, ByRef y, ByRef w, ByRef h)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_DestroyNumberClickLayer()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è Á¤¸®¸¸ ¼öÇàÇÕ´Ï´Ù.
    return true
}

SSOK_IsPointInsideCaptureTools(screenX, screenY)
{
    global SSOK_ToolHwnd
    if (SSOK_ToolHwnd = "")
        return false
    WinGetPos, tx, ty, tw, th, ahk_id %SSOK_ToolHwnd%
    if (tx = "")
        return false
    return (screenX >= tx && screenX <= tx + tw && screenY >= ty && screenY <= ty + th)
}

SSOK_IsPointInsidePaintWindow(screenX, screenY)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_ShowNumberOverlay(screenX, screenY, num)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_DestroyNumberOverlays()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è Á¤¸®¸¸ ¼öÇàÇÕ´Ï´Ù.
    return true
}

SSOK_IsPointInPaintCanvas(screenX, screenY)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_GetImageFileSize(imageFile, ByRef w, ByRef h)
{
    w := 0
    h := 0
    if (imageFile = "" || !FileExist(imageFile))
        return false
    pBitmap := Gdip_CreateBitmapFromFile(imageFile)
    if (!pBitmap)
        return false
    Gdip_GetImageDimensions(pBitmap, w, h)
    Gdip_DisposeImage(pBitmap)
    return (w > 0 && h > 0)
}

SSOK_ScreenToPaintImagePoint(screenX, screenY, imgW, imgH, ByRef imgX, ByRef imgY)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_DrawNumberStampsOnImage(sourceFile, outFile, pointsFile)
{
    ; ÀÚÃ¼ ÆíÁý±â ¹øÈ£ µµ±¸¸¦ »ç¿ëÇÏ¹Ç·Î ±×¸²ÆÇ¿ë ÇÕ¼º ·çÆ¾Àº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    return false
}

SSOK_DrawNumberStampOnImage(sourceFile, outFile, num, centerX, centerY)
{
    ; ÀÚÃ¼ ÆíÁý±â ¹øÈ£ µµ±¸¸¦ »ç¿ëÇÏ¹Ç·Î ±×¸²ÆÇ¿ë ´ÜÀÏ ½ºÅÆÇÁ ÇÕ¼ºÀº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    return false
}

SSOK_ReplacePaintCanvasFromFile(imageFile)
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_PrepareCurrentImageForOcr()
{
    global SSOK_LastCaptureFile, SSOK_WorkFolder, SSOK_PaintHasCapture

    SSOK_PaintHasCapture := false

    if (SSOK_LastCaptureFile != "" && FileExist(SSOK_LastCaptureFile))
    {
        sourceFile := SSOK_LastCaptureFile
        return Gdip_CreateBitmapFromFile(sourceFile)
    }

    if (SSOK_CopySnippingToolImage())
    {
        FormatTime, now,, yyyyMMdd_HHmmss
        outFile := SSOK_WorkFolder "\SSOK_ocr_snip_" now "_" A_TickCount ".png"
        if (SSOK_SaveClipboardImageToFile(outFile))
        {
            SSOK_LastCaptureFile := outFile
            return true
        }
    }

    MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÅØ½ºÆ® ÃßÃâÇÒ ÀÌ¹ÌÁö¸¦ ÁØºñÇÏÁö ¸øÇß½À´Ï´Ù.
    return false
}

SSOK_CopyPaintCanvasToClipboard()
{
    ; ÀÚÃ¼ ÆíÁý±â »ç¿ëÀ¸·Î °ú°Å ±×¸²ÆÇ ¿¬°è´Â ºñÈ°¼ºÈ­ÇÕ´Ï´Ù.
    return false
}

SSOK_OpenCurrentCaptureInPaint(pasteStamp := false, modeName := "", paintTool := "")
{
    ; ÀÚÃ¼ ÆíÁý±â¸¦ ¿±´Ï´Ù.
    return SSOK_OpenNumberStampEditor()
}
SSOK_RunImageOperation(op, x, y, w, h, textFile, num)
{
    ; »ç¿ëÀÚ ¿äÃ» ¹Ý¿µ: SSOK ÀÚÃ¼ ÆíÁý È­¸é/³»ºÎ ÇÕ¼º ÆíÁýÀº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    ; ±Û»óÀÚ¿Í ¹øÈ£ ½ºÅÆÇÁ´Â ±×¸²ÆÇÀ¸·Î¸¸ Ã³¸®ÇÕ´Ï´Ù.
    return false
}
SSOK_SaveClipboardImageToFile(outFile)
{
    ; ¿ÜºÎ ÀÚ½Ä ÇÁ·Î¼¼½º ¾øÀÌ Å¬¸³º¸µå ºñÆ®¸ÊÀ» GDI+·Î ¹Ù·Î ÀúÀåÇÕ´Ï´Ù.
    pBitmap := Gdip_CreateBitmapFromClipboard()
    if (!pBitmap)
        return false
    err := Gdip_SaveBitmapToFile(pBitmap, outFile)
    Gdip_DisposeImage(pBitmap)
    return (err = 0 && FileExist(outFile))
}
SSOK_PrepareSmallTextOcrImage(sourceFile)
{
    global SSOK_WorkFolder
    if (sourceFile = "" || !FileExist(sourceFile))
        return sourceFile

    pBitmap := Gdip_CreateBitmapFromFile(sourceFile)
    if (!pBitmap)
        return sourceFile

    Gdip_GetImageDimensions(pBitmap, w, h)
    if (w < 1 || h < 1)
    {
        Gdip_DisposeImage(pBitmap)
        return sourceFile
    }

    scale := 2.0
    if (w < 1000 || h < 700)
        scale := 3.0

    maxDim := 2600
    maxScaleW := maxDim / w
    maxScaleH := maxDim / h
    maxScale := (maxScaleW < maxScaleH) ? maxScaleW : maxScaleH
    if (scale > maxScale)
        scale := maxScale
    if (scale < 1.15)
    {
        Gdip_DisposeImage(pBitmap)
        return sourceFile
    }

    dstW := Round(w * scale)
    dstH := Round(h * scale)
    pScaled := SSOK_CreateScaledBitmap(pBitmap, dstW, dstH)
    Gdip_DisposeImage(pBitmap)
    if (!pScaled)
        return sourceFile

    if (SSOK_WorkFolder = "")
        SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
    FileCreateDir, %SSOK_WorkFolder%
    FormatTime, now,, yyyyMMdd_HHmmss
    ocrFile := SSOK_WorkFolder "\SSOK_ocr_input_" now "_" A_TickCount ".png"
    err := Gdip_SaveBitmapToFile(pScaled, ocrFile)
    Gdip_DisposeImage(pScaled)
    if (err = 0 && FileExist(ocrFile))
        return ocrFile
    return sourceFile
}

SSOK_FinishExtractedOcrText(ocrText, mode)
{
    ocrText := Trim(ocrText, " `t`r`n")
    if (mode = "table")
        ocrText := SSOK_FormatOcrTable(ocrText)
    else
        ocrText := SSOK_FormatOcrText(ocrText)
    if (SubStr(ocrText, 1, 18) = "__SSOK_OCR_ERROR__")
    {
        ocrText := Trim(SubStr(ocrText, 19), " `t`r`n")
        titleText := (mode = "table") ? "Ç¥ ÃßÃâ" : "ÅØ½ºÆ® ÃßÃâ"
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, %titleText%¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n`n¿À·ù ³»¿ë: %ocrText%
        return false
    }
    if (ocrText = "")
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÃßÃâµÈ ³»¿ëÀÌ ¾ø½À´Ï´Ù.
        return false
    }
    Clipboard := ocrText
    doneText := (mode = "table") ? "Ç¥¸¦ ÃßÃâÇØ Å¬¸³º¸µå¿¡ º¹»çÇß½À´Ï´Ù.`n¿¢¼¿¿¡ ºÙ¿©³ÖÀ¸¸é ¼¿·Î ³ª´¹´Ï´Ù." : "ÅØ½ºÆ®¸¦ ÃßÃâÇØ Å¬¸³º¸µå¿¡ º¹»çÇß½À´Ï´Ù."
    MsgBox, 64, SSOK Ä¸Ã³ Å×½ºÆ®, %doneText%`n`n%ocrText%
    return true
}

SSOK_WinRtOcrImageToText(imageFile, mode, ByRef resultText, ByRef errMsg)
{
    resultText := ""
    ocr := SSOK_WinRtOcrRecognizeFile(imageFile, errMsg)
    if (!IsObject(ocr))
        return false
    if (mode = "table")
        resultText := SSOK_WinRtOcrBuildTableText(ocr)
    else
        resultText := SSOK_WinRtOcrBuildPositionText(ocr)
    if (resultText = "")
        resultText := ocr.Text
    return true
}

SSOK_WinRtOcrImageToPrivacyRects(imageFile, ByRef rectText, ByRef errMsg)
{
    rectText := ""
    ocr := SSOK_WinRtOcrRecognizeFile(imageFile, errMsg)
    if (!IsObject(ocr))
        return false
    rectText := SSOK_AutoMaskRectsFromOcrResult(ocr)
    return true
}

SSOK_WinRtOcrRecognizeFile(imageFile, ByRef errMsg, lang := "FirstFromAvailableLanguages")
{
    global SSOK_WinRtOcr_BitmapDecoderStatics, SSOK_WinRtOcr_OcrEngine, SSOK_WinRtOcr_MaxDimension
    errMsg := ""
    if (imageFile = "" || !FileExist(imageFile))
    {
        errMsg := "OCR ´ë»ó ÀÌ¹ÌÁö ÆÄÀÏÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
        return false
    }
    if (!SSOK_WinRtOcrEnsureInit(errMsg))
        return false

    stream := 0, decoder := 0, bitmapFrame := 0, frameWithSoftwareBitmap := 0, softwareBitmap := 0, ocrResult := 0, linesList := 0
    VarSetCapacity(iidStream, 16, 0)
    if (!SSOK_WinRtGuidFromString("{905A0FE1-BC53-11DF-8C49-001E4FC686DA}", iidStream, errMsg))
        return false

    hr := DllCall("ShCore\CreateRandomAccessStreamOnFile", "WStr", imageFile, "UInt", 0, "Ptr", &iidStream, "Ptr*", stream, "UInt")
    if (hr != 0 || !stream)
    {
        errMsg := "OCR ÀÌ¹ÌÁö ½ºÆ®¸²À» ¿­Áö ¸øÇß½À´Ï´Ù. HRESULT: " SSOK_HResultHex(hr)
        return false
    }

    result := false
    Loop, 1
    {
        if (!SSOK_WinRtCallAsync(SSOK_WinRtVTable(SSOK_WinRtOcr_BitmapDecoderStatics, 14), SSOK_WinRtOcr_BitmapDecoderStatics, stream, decoder, errMsg, "OCR ÀÌ¹ÌÁö µðÄÚ´õ »ý¼º"))
            break

        bitmapFrame := ComObjQuery(decoder, "{72A49A1C-8081-438D-91BC-94ECFC8185C6}")
        if (!bitmapFrame)
        {
            errMsg := "OCR ÀÌ¹ÌÁö ÇÁ·¹ÀÓÀ» ÀÐÁö ¸øÇß½À´Ï´Ù."
            break
        }
        DllCall(SSOK_WinRtVTable(bitmapFrame, 12), "Ptr", bitmapFrame, "UInt*", width)
        DllCall(SSOK_WinRtVTable(bitmapFrame, 13), "Ptr", bitmapFrame, "UInt*", height)
        if (width < 1 || height < 1)
        {
            errMsg := "OCR ÀÌ¹ÌÁö Å©±â¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù."
            break
        }
        if (SSOK_WinRtOcr_MaxDimension > 0 && (width > SSOK_WinRtOcr_MaxDimension || height > SSOK_WinRtOcr_MaxDimension))
        {
            errMsg := "OCR ÀÌ¹ÌÁö°¡ ³Ê¹« Å®´Ï´Ù. " width "x" height " / ÃÖ´ë " SSOK_WinRtOcr_MaxDimension "px"
            break
        }

        frameWithSoftwareBitmap := ComObjQuery(decoder, "{FE287C9A-420C-4963-87AD-691436E08383}")
        if (!frameWithSoftwareBitmap)
        {
            errMsg := "OCR SoftwareBitmap º¯È¯ ÀÎÅÍÆäÀÌ½º¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù."
            break
        }
        if (!SSOK_WinRtCallAsync(SSOK_WinRtVTable(frameWithSoftwareBitmap, 6), frameWithSoftwareBitmap, "", softwareBitmap, errMsg, "OCR SoftwareBitmap »ý¼º"))
            break
        SSOK_WinRtOcrEnsureBitmapFormat(softwareBitmap)

        if (!SSOK_WinRtOcrGetEngine(lang, errMsg))
            break
        if (!SSOK_WinRtCallAsync(SSOK_WinRtVTable(SSOK_WinRtOcr_OcrEngine, 6), SSOK_WinRtOcr_OcrEngine, softwareBitmap, ocrResult, errMsg, "Windows OCR ½ÇÇà"))
            break

        result := SSOK_WinRtOcrReadResult(ocrResult, width, height, errMsg)
        break
    }

    SSOK_WinRtCloseIClosable(stream)
    SSOK_WinRtCloseIClosable(softwareBitmap)
    SSOK_WinRtSafeRelease(linesList)
    SSOK_WinRtSafeRelease(ocrResult)
    SSOK_WinRtSafeRelease(softwareBitmap)
    SSOK_WinRtSafeRelease(frameWithSoftwareBitmap)
    SSOK_WinRtSafeRelease(bitmapFrame)
    SSOK_WinRtSafeRelease(decoder)
    SSOK_WinRtSafeRelease(stream)
    return IsObject(result) ? result : false
}

SSOK_WinRtOcrEnsureInit(ByRef errMsg)
{
    global SSOK_WinRtOcr_LanguageFactory, SSOK_WinRtOcr_BitmapDecoderStatics, SSOK_WinRtOcr_SoftwareBitmapStatics, SSOK_WinRtOcr_OcrEngineStatics, SSOK_WinRtOcr_MaxDimension
    if (SSOK_WinRtOcr_OcrEngineStatics != "")
        return true
    if (!SSOK_WinRtCreateClass("Windows.Globalization.Language", "{9B0252AC-0C27-44F8-B792-9793FB66C63E}", SSOK_WinRtOcr_LanguageFactory, errMsg))
        return false
    if (!SSOK_WinRtCreateClass("Windows.Graphics.Imaging.BitmapDecoder", "{438CCB26-BCEF-4E95-BAD6-23A822E58D01}", SSOK_WinRtOcr_BitmapDecoderStatics, errMsg))
        return false
    if (!SSOK_WinRtCreateClass("Windows.Graphics.Imaging.SoftwareBitmap", "{df0385db-672f-4a9d-806e-c2442f343e86}", SSOK_WinRtOcr_SoftwareBitmapStatics, errMsg))
        return false
    if (!SSOK_WinRtCreateClass("Windows.Media.Ocr.OcrEngine", "{5BFFA85A-3384-3540-9940-699120D428A8}", SSOK_WinRtOcr_OcrEngineStatics, errMsg))
        return false
    DllCall(SSOK_WinRtVTable(SSOK_WinRtOcr_OcrEngineStatics, 6), "Ptr", SSOK_WinRtOcr_OcrEngineStatics, "UInt*", SSOK_WinRtOcr_MaxDimension)
    return true
}

SSOK_WinRtOcrGetEngine(lang, ByRef errMsg)
{
    global SSOK_WinRtOcr_LanguageFactory, SSOK_WinRtOcr_OcrEngineStatics, SSOK_WinRtOcr_OcrEngine, SSOK_WinRtOcr_CurrentLanguage
    if (lang = "")
        lang := "FirstFromAvailableLanguages"
    if (SSOK_WinRtOcr_OcrEngine && SSOK_WinRtOcr_CurrentLanguage = lang)
        return true
    if (SSOK_WinRtOcr_OcrEngine)
    {
        ObjRelease(SSOK_WinRtOcr_OcrEngine)
        SSOK_WinRtOcr_OcrEngine := 0
    }

    if (lang = "FirstFromAvailableLanguages")
    {
        hr := DllCall(SSOK_WinRtVTable(SSOK_WinRtOcr_OcrEngineStatics, 10), "Ptr", SSOK_WinRtOcr_OcrEngineStatics, "Ptr*", SSOK_WinRtOcr_OcrEngine, "UInt")
        if (hr = 0 && SSOK_WinRtOcr_OcrEngine)
        {
            SSOK_WinRtOcr_CurrentLanguage := lang
            return true
        }
        if (SSOK_WinRtOcrCreatePreferredEngine(errMsg))
        {
            SSOK_WinRtOcr_CurrentLanguage := lang
            return true
        }
        if (errMsg = "")
            errMsg := "¼³Ä¡µÈ Windows OCR ÀÎ½Ä ¾ð¾î¸¦ Ã£Áö ¸øÇß½À´Ï´Ù."
        return false
    }

    hString := 0, language := 0
    if (!SSOK_WinRtCreateHString(lang, hString, errMsg))
        return false
    hr := DllCall(SSOK_WinRtVTable(SSOK_WinRtOcr_LanguageFactory, 6), "Ptr", SSOK_WinRtOcr_LanguageFactory, "Ptr", hString, "Ptr*", language, "UInt")
    SSOK_WinRtDeleteHString(hString)
    if (hr != 0 || !language)
    {
        errMsg := "OCR ¾ð¾î °´Ã¼¸¦ ¸¸µéÁö ¸øÇß½À´Ï´Ù. HRESULT: " SSOK_HResultHex(hr)
        return false
    }
    hr := DllCall(SSOK_WinRtVTable(SSOK_WinRtOcr_OcrEngineStatics, 9), "Ptr", SSOK_WinRtOcr_OcrEngineStatics, "Ptr", language, "Ptr*", SSOK_WinRtOcr_OcrEngine, "UInt")
    ObjRelease(language)
    if (hr != 0 || !SSOK_WinRtOcr_OcrEngine)
    {
        errMsg := "Windows OCR ÀÎ½Ä ¾ð¾î¸¦ ¸¸µéÁö ¸øÇß½À´Ï´Ù. HRESULT: " SSOK_HResultHex(hr)
        return false
    }
    SSOK_WinRtOcr_CurrentLanguage := lang
    return true
}

SSOK_WinRtOcrCreatePreferredEngine(ByRef errMsg)
{
    global SSOK_WinRtOcr_OcrEngineStatics, SSOK_WinRtOcr_OcrEngine
    langList := 0, firstLang := 0, koLang := 0, enLang := 0, pick := 0
    hr := DllCall(SSOK_WinRtVTable(SSOK_WinRtOcr_OcrEngineStatics, 7), "Ptr", SSOK_WinRtOcr_OcrEngineStatics, "Ptr*", langList, "UInt")
    if (hr != 0 || !langList)
        return false
    DllCall(SSOK_WinRtVTable(langList, 7), "Ptr", langList, "Int*", count)
    Loop, %count%
    {
        langObj := 0
        DllCall(SSOK_WinRtVTable(langList, 6), "Ptr", langList, "Int", A_Index - 1, "Ptr*", langObj, "UInt")
        if (!langObj)
            continue
        tag := SSOK_WinRtLanguageTag(langObj)
        keep := false
        if (!firstLang)
        {
            firstLang := langObj
            keep := true
        }
        if (!koLang && RegExMatch(tag, "i)^ko"))
        {
            koLang := langObj
            keep := true
        }
        if (!enLang && RegExMatch(tag, "i)^en"))
        {
            enLang := langObj
            keep := true
        }
        if (!keep)
            ObjRelease(langObj)
    }
    pick := koLang ? koLang : (enLang ? enLang : firstLang)
    if (pick)
        hr := DllCall(SSOK_WinRtVTable(SSOK_WinRtOcr_OcrEngineStatics, 9), "Ptr", SSOK_WinRtOcr_OcrEngineStatics, "Ptr", pick, "Ptr*", SSOK_WinRtOcr_OcrEngine, "UInt")
    if (firstLang && firstLang != koLang && firstLang != enLang)
        ObjRelease(firstLang)
    if (koLang && koLang != firstLang && koLang != enLang)
        ObjRelease(koLang)
    if (enLang && enLang != firstLang && enLang != koLang)
        ObjRelease(enLang)
    SSOK_WinRtSafeRelease(langList)
    if (hr = 0 && SSOK_WinRtOcr_OcrEngine)
        return true
    errMsg := "Windows OCR ÀÎ½Ä ¾ð¾î¸¦ ¸¸µéÁö ¸øÇß½À´Ï´Ù."
    return false
}

SSOK_WinRtOcrEnsureBitmapFormat(ByRef softwareBitmap)
{
    global SSOK_WinRtOcr_SoftwareBitmapStatics
    if (!softwareBitmap || !SSOK_WinRtOcr_SoftwareBitmapStatics)
        return false
    DllCall(SSOK_WinRtVTable(softwareBitmap, 6), "Ptr", softwareBitmap, "Int*", pixelFormat)
    DllCall(SSOK_WinRtVTable(softwareBitmap, 7), "Ptr", softwareBitmap, "Int*", alphaMode)
    ; Windows OCR¿¡ ¾ÈÁ¤ÀûÀÎ Bgra8 / Premultiplied Çü½ÄÀ¸·Î ¸ÂÃä´Ï´Ù.
    if (pixelFormat = 87 && alphaMode = 0)
        return true
    converted := 0
    hr := DllCall(SSOK_WinRtVTable(SSOK_WinRtOcr_SoftwareBitmapStatics, 8), "Ptr", SSOK_WinRtOcr_SoftwareBitmapStatics, "Ptr", softwareBitmap, "Int", 87, "Int", 0, "Ptr*", converted, "UInt")
    if (hr = 0 && converted)
    {
        SSOK_WinRtCloseIClosable(softwareBitmap)
        ObjRelease(softwareBitmap)
        softwareBitmap := converted
        return true
    }
    return false
}

SSOK_WinRtOcrReadResult(ocrResult, imageW, imageH, ByRef errMsg)
{
    if (!ocrResult)
    {
        errMsg := "Windows OCR °á°ú°¡ ºñ¾î ÀÖ½À´Ï´Ù."
        return false
    }
    result := {Text: "", Lines: [], Words: [], ImageWidth: imageW, ImageHeight: imageH}
    linesList := 0
    hr := DllCall(SSOK_WinRtVTable(ocrResult, 6), "Ptr", ocrResult, "Ptr*", linesList, "UInt")
    if (hr != 0 || !linesList)
    {
        errMsg := "Windows OCR ÁÙ ¸ñ·ÏÀ» ÀÐÁö ¸øÇß½À´Ï´Ù. HRESULT: " SSOK_HResultHex(hr)
        return false
    }
    DllCall(SSOK_WinRtVTable(linesList, 7), "Ptr", linesList, "Int*", lineCount)
    Loop, %lineCount%
    {
        ocrLine := 0
        DllCall(SSOK_WinRtVTable(linesList, 6), "Ptr", linesList, "Int", A_Index - 1, "Ptr*", ocrLine, "UInt")
        if (!ocrLine)
            continue
        lineText := SSOK_WinRtGetHStringProperty(ocrLine, 7)
        lineObj := {Text: Trim(lineText, " `t`r`n"), Words: []}
        wordsList := 0
        DllCall(SSOK_WinRtVTable(ocrLine, 6), "Ptr", ocrLine, "Ptr*", wordsList, "UInt")
        if (wordsList)
        {
            DllCall(SSOK_WinRtVTable(wordsList, 7), "Ptr", wordsList, "Int*", wordCount)
            Loop, %wordCount%
            {
                ocrWord := 0
                DllCall(SSOK_WinRtVTable(wordsList, 6), "Ptr", wordsList, "Int", A_Index - 1, "Ptr*", ocrWord, "UInt")
                if (!ocrWord)
                    continue
                wordText := Trim(SSOK_WinRtGetHStringProperty(ocrWord, 7), " `t`r`n")
                if (wordText != "")
                {
                    VarSetCapacity(rc, 16, 0)
                    DllCall(SSOK_WinRtVTable(ocrWord, 6), "Ptr", ocrWord, "Ptr", &rc, "UInt")
                    x := NumGet(rc, 0, "Float")
                    y := NumGet(rc, 4, "Float")
                    w := NumGet(rc, 8, "Float")
                    h := NumGet(rc, 12, "Float")
                    if (h <= 0)
                        h := 12.0
                    item := {Text: wordText, X: x, Y: y, W: w, H: h, R: x + w, B: y + h, C: y + (h / 2.0)}
                    lineObj.Words.Push(item)
                    result.Words.Push(item)
                }
                ObjRelease(ocrWord)
            }
            ObjRelease(wordsList)
        }
        if (lineObj.Text = "")
            lineObj.Text := SSOK_JoinWordTexts(lineObj.Words, " ")
        if (lineObj.Text != "")
        {
            result.Lines.Push(lineObj)
            if (result.Text != "")
                result.Text .= "`r`n"
            result.Text .= lineObj.Text
        }
        ObjRelease(ocrLine)
    }
    ObjRelease(linesList)
    return result
}

SSOK_WinRtOcrBuildPositionText(ocr)
{
    rows := SSOK_WinRtOcrBuildRows(ocr.Words, 0.68)
    out := ""
    for _, row in rows
    {
        line := SSOK_JoinWordTexts(row.Words, " ")
        if (line != "")
            out .= (out = "" ? "" : "`r`n") line
    }
    return out
}

SSOK_WinRtOcrBuildTableText(ocr)
{
    rows := SSOK_WinRtOcrBuildRows(ocr.Words, 0.72)
    header := ""
    for _, row in rows
    {
        if (row.Words.Length() >= 2)
        {
            header := row
            break
        }
    }
    if (!IsObject(header))
        return SSOK_WinRtOcrBuildPositionText(ocr)

    headerWords := SSOK_SortOcrWords(header.Words, "x")
    avgH := SSOK_AvgWordHeight(ocr.Words)
    if (avgH <= 0)
        avgH := 12.0
    minGap := Max(8.0, avgH * 0.55)
    bounds := []
    Loop, % headerWords.Length() - 1
    {
        left := headerWords[A_Index]
        right := headerWords[A_Index + 1]
        gap := right.X - left.R
        if (gap >= minGap)
            bounds.Push(left.R + (gap / 2.0))
    }
    if (bounds.Length() < 1)
    {
        Loop, % headerWords.Length() - 1
        {
            left := headerWords[A_Index]
            right := headerWords[A_Index + 1]
            bounds.Push(left.R + ((right.X - left.R) / 2.0))
        }
    }
    bounds := SSOK_MergeNumberBounds(bounds, Max(10.0, avgH * 0.7))
    colCount := bounds.Length() + 1
    if (colCount < 2)
        return SSOK_WinRtOcrBuildPositionText(ocr)

    out := ""
    for _, row in rows
    {
        cells := []
        Loop, %colCount%
            cells.Push("")
        rowWords := SSOK_SortOcrWords(row.Words, "x")
        for _, word in rowWords
        {
            centerX := (word.X + word.R) / 2.0
            idx := 1
            for _, b in bounds
            {
                if (centerX > b)
                    idx++
            }
            if (idx < 1)
                idx := 1
            if (idx > colCount)
                idx := colCount
            if (cells[idx] != "")
                cells[idx] .= " "
            cells[idx] .= word.Text
        }
        line := SSOK_JoinArray(cells, "`t")
        line := Trim(line, " `t`r`n")
        if (line != "")
            out .= (out = "" ? "" : "`r`n") line
    }
    return out
}

SSOK_WinRtOcrBuildRows(words, factor := 0.68)
{
    rows := []
    if (!IsObject(words) || words.Length() < 1)
        return rows
    avgH := SSOK_AvgWordHeight(words)
    if (avgH <= 0)
        avgH := 12.0
    threshold := Max(5.0, avgH * factor)
    sorted := SSOK_SortOcrWords(words, "cyx")
    for _, word in sorted
    {
        bestIdx := 0
        bestDiff := 999999.0
        for idx, row in rows
        {
            rowY := row.Y / row.Count
            diff := Abs(word.C - rowY)
            if (diff <= threshold && diff < bestDiff)
            {
                bestIdx := idx
                bestDiff := diff
            }
        }
        if (!bestIdx)
            rows.Push({Y: word.C, Count: 1, Words: [word]})
        else
        {
            rows[bestIdx].Words.Push(word)
            rows[bestIdx].Y += word.C
            rows[bestIdx].Count += 1
        }
    }
    rows := SSOK_SortOcrRows(rows)
    for idx, row in rows
        rows[idx].Words := SSOK_SortOcrWords(row.Words, "x")
    return rows
}

SSOK_SortOcrWords(words, mode := "x")
{
    arr := []
    for _, word in words
        arr.Push(word)
    n := arr.Length()
    if (n < 2)
        return arr
    Loop, % n - 1
    {
        i := A_Index
        Loop, % n - i
        {
            j := A_Index
            if (!SSOK_OcrWordBefore(arr[j], arr[j + 1], mode))
            {
                tmp := arr[j]
                arr[j] := arr[j + 1]
                arr[j + 1] := tmp
            }
        }
    }
    return arr
}

SSOK_OcrWordBefore(a, b, mode)
{
    if (mode = "cyx")
    {
        if (a.C = b.C)
            return (a.X <= b.X)
        return (a.C < b.C)
    }
    if (a.X = b.X)
        return (a.Y <= b.Y)
    return (a.X < b.X)
}

SSOK_SortOcrRows(rows)
{
    arr := []
    for _, row in rows
        arr.Push(row)
    n := arr.Length()
    if (n < 2)
        return arr
    Loop, % n - 1
    {
        i := A_Index
        Loop, % n - i
        {
            j := A_Index
            y1 := arr[j].Y / arr[j].Count
            y2 := arr[j + 1].Y / arr[j + 1].Count
            if (y1 > y2)
            {
                tmp := arr[j]
                arr[j] := arr[j + 1]
                arr[j + 1] := tmp
            }
        }
    }
    return arr
}

SSOK_AvgWordHeight(words)
{
    if (!IsObject(words) || words.Length() < 1)
        return 0
    sum := 0.0
    count := 0
    for _, word in words
    {
        if (word.H > 0)
        {
            sum += word.H
            count++
        }
    }
    return count ? (sum / count) : 0
}

SSOK_MergeNumberBounds(bounds, minDistance)
{
    sorted := []
    for _, b in bounds
        sorted.Push(b)
    n := sorted.Length()
    if (n < 2)
        return sorted
    Loop, % n - 1
    {
        i := A_Index
        Loop, % n - i
        {
            j := A_Index
            if (sorted[j] > sorted[j + 1])
            {
                tmp := sorted[j]
                sorted[j] := sorted[j + 1]
                sorted[j + 1] := tmp
            }
        }
    }
    merged := []
    for _, b in sorted
    {
        if (merged.Length() < 1)
            merged.Push(b)
        else
        {
            last := merged.Length()
            if (Abs(b - merged[last]) < minDistance)
                merged[last] := (merged[last] + b) / 2.0
            else
                merged.Push(b)
        }
    }
    return merged
}

SSOK_JoinWordTexts(words, sep := " ")
{
    out := ""
    for _, word in words
    {
        t := Trim(word.Text, " `t`r`n")
        if (t != "")
            out .= (out = "" ? "" : sep) t
    }
    return out
}

SSOK_JoinArray(items, sep := " ")
{
    out := ""
    for _, item in items
        out .= (A_Index = 1 ? "" : sep) item
    return out
}

SSOK_WinRtCallAsync(methodPtr, thisPtr, argPtr, ByRef resultPtr, ByRef errMsg, label)
{
    resultPtr := 0
    if (argPtr = "")
        hr := DllCall(methodPtr, "Ptr", thisPtr, "Ptr*", asyncObj, "UInt")
    else
        hr := DllCall(methodPtr, "Ptr", thisPtr, "Ptr", argPtr, "Ptr*", asyncObj, "UInt")
    if (hr != 0 || !asyncObj)
    {
        errMsg := label " ºñµ¿±â ÀÛ¾÷À» ½ÃÀÛÇÏÁö ¸øÇß½À´Ï´Ù. HRESULT: " SSOK_HResultHex(hr)
        return false
    }
    if (!SSOK_WinRtWaitForAsync(asyncObj, errMsg))
    {
        if (errMsg = "")
            errMsg := label " ºñµ¿±â ÀÛ¾÷ÀÌ ½ÇÆÐÇß½À´Ï´Ù."
        return false
    }
    resultPtr := asyncObj
    return true
}

SSOK_WinRtWaitForAsync(ByRef asyncObj, ByRef errMsg, timeoutMs := 30000)
{
    asyncInfo := ComObjQuery(asyncObj, "{00000036-0000-0000-C000-000000000046}")
    if (!asyncInfo)
    {
        errMsg := "Windows Runtime ºñµ¿±â »óÅÂ¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù."
        return false
    }
    start := A_TickCount
    Loop
    {
        status := 0
        DllCall(SSOK_WinRtVTable(asyncInfo, 7), "Ptr", asyncInfo, "UInt*", status)
        if (status != 0)
            break
        if ((A_TickCount - start) > timeoutMs)
        {
            ObjRelease(asyncInfo)
            errMsg := "Windows OCR ºñµ¿±â ÀÛ¾÷ÀÌ 30ÃÊ ¾È¿¡ ¿Ï·áµÇÁö ¾Ê¾Ò½À´Ï´Ù."
            return false
        }
        Sleep, 10
    }
    if (status != 1)
    {
        errorCode := 0
        DllCall(SSOK_WinRtVTable(asyncInfo, 8), "Ptr", asyncInfo, "UInt*", errorCode)
        ObjRelease(asyncInfo)
        errMsg := "Windows OCR ºñµ¿±â ¿À·ù: " SSOK_HResultHex(errorCode)
        return false
    }
    ObjRelease(asyncInfo)
    result := 0
    hr := DllCall(SSOK_WinRtVTable(asyncObj, 8), "Ptr", asyncObj, "Ptr*", result, "UInt")
    ObjRelease(asyncObj)
    asyncObj := result
    if (hr != 0 || !asyncObj)
    {
        errMsg := "Windows OCR ºñµ¿±â °á°ú¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù. HRESULT: " SSOK_HResultHex(hr)
        return false
    }
    return true
}

SSOK_WinRtCreateClass(className, iid, ByRef classPtr, ByRef errMsg)
{
    classPtr := 0
    hString := 0
    if (!SSOK_WinRtCreateHString(className, hString, errMsg))
        return false
    VarSetCapacity(guid, 16, 0)
    if (!SSOK_WinRtGuidFromString(iid, guid, errMsg))
    {
        SSOK_WinRtDeleteHString(hString)
        return false
    }
    hr := DllCall("Combase.dll\RoGetActivationFactory", "Ptr", hString, "Ptr", &guid, "Ptr*", classPtr, "UInt")
    SSOK_WinRtDeleteHString(hString)
    if (hr != 0 || !classPtr)
    {
        errMsg := className " È°¼ºÈ­ ÆÑÅÍ¸®¸¦ ¸¸µéÁö ¸øÇß½À´Ï´Ù. HRESULT: " SSOK_HResultHex(hr)
        return false
    }
    return true
}

SSOK_WinRtCreateHString(text, ByRef hString, ByRef errMsg)
{
    hString := 0
    hr := DllCall("Combase.dll\WindowsCreateString", "WStr", text, "UInt", StrLen(text), "Ptr*", hString, "UInt")
    if (hr != 0 || !hString)
    {
        errMsg := "Windows Runtime ¹®ÀÚ¿­ »ý¼º ½ÇÆÐ: " SSOK_HResultHex(hr)
        return false
    }
    return true
}

SSOK_WinRtDeleteHString(hString)
{
    if (hString)
        DllCall("Combase.dll\WindowsDeleteString", "Ptr", hString)
}

SSOK_WinRtGetHStringProperty(ptr, vtableIndex)
{
    hText := 0
    text := ""
    if (ptr)
    {
        hr := DllCall(SSOK_WinRtVTable(ptr, vtableIndex), "Ptr", ptr, "Ptr*", hText, "UInt")
        if (hr = 0 && hText)
        {
            buffer := DllCall("Combase.dll\WindowsGetStringRawBuffer", "Ptr", hText, "UInt*", length, "Ptr")
            if (buffer)
                text := StrGet(buffer, length, "UTF-16")
            SSOK_WinRtDeleteHString(hText)
        }
    }
    return text
}

SSOK_WinRtLanguageTag(languagePtr)
{
    return SSOK_WinRtGetHStringProperty(languagePtr, 6)
}

SSOK_WinRtGuidFromString(iid, ByRef guid, ByRef errMsg)
{
    VarSetCapacity(guid, 16, 0)
    hr := DllCall("ole32\CLSIDFromString", "WStr", iid, "Ptr", &guid, "UInt")
    if (hr != 0)
    {
        errMsg := "GUID º¯È¯ ½ÇÆÐ: " iid " / " SSOK_HResultHex(hr)
        return false
    }
    return true
}

SSOK_WinRtVTable(ptr, index)
{
    return NumGet(NumGet(ptr + 0) + index * A_PtrSize)
}

SSOK_WinRtCloseIClosable(ptr)
{
    if (!ptr)
        return false
    closable := ComObjQuery(ptr, "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
    if (!closable)
        return false
    DllCall(SSOK_WinRtVTable(closable, 6), "Ptr", closable)
    ObjRelease(closable)
    return true
}

SSOK_WinRtSafeRelease(ByRef ptr)
{
    if (ptr)
    {
        ObjRelease(ptr)
        ptr := 0
    }
}

SSOK_HResultHex(hr)
{
    return Format("0x{:08X}", hr & 0xFFFFFFFF)
}

SSOK_AutoMaskRectsFromOcrResult(ocr)
{
    rects := []
    seen := {}
    for _, line in ocr.Lines
    {
        if (IsObject(line.Words) && line.Words.Length() > 0)
            SSOK_AutoMaskFindPrivacyRectsInWords(line.Words, rects, seen)
    }
    rows := SSOK_WinRtOcrBuildRows(ocr.Words, 0.72)
    for _, row in rows
    {
        if (IsObject(row.Words) && row.Words.Length() > 0)
            SSOK_AutoMaskFindPrivacyRectsInWords(row.Words, rects, seen)
    }
    out := ""
    for _, r in rects
        out .= (out = "" ? "" : "`r`n") Round(r.X) "|" Round(r.Y) "|" Round(r.W) "|" Round(r.H) "|" r.Kind
    return out
}

SSOK_AutoMaskFindPrivacyRectsInWords(words, ByRef rects, ByRef seen)
{
    count := words.Length()
    if (count < 1)
        return
    Loop, %count%
    {
        i := A_Index
        maxN := Min(7, count - i + 1)
        Loop, %maxN%
        {
            n := A_Index
            items := SSOK_ArraySlice(words, i, n)
            packedRaw := SSOK_JoinWordTexts(items, "")
            digits := SSOK_CompactNumberText(packedRaw)
            headDigits := SSOK_CompactNumberText(words[i].Text)
            if (StrLen(headDigits) >= 2)
            {
                if (RegExMatch(digits, "^\d{13}$"))
                {
                    SSOK_AutoMaskAddNumberTailRect(items, rects, seen, "rrn", 6)
                    continue
                }
                if (RegExMatch(digits, "^01[016789]\d{7,8}$"))
                {
                    SSOK_AutoMaskAddNumberTailRect(items, rects, seen, "phone", SSOK_AutoMaskGetPhoneKeepDigits(digits))
                    continue
                }
                if (RegExMatch(digits, "^02\d{7,8}$"))
                {
                    SSOK_AutoMaskAddNumberTailRect(items, rects, seen, "phone", SSOK_AutoMaskGetPhoneKeepDigits(digits))
                    continue
                }
                if (RegExMatch(digits, "^0[3-6][1-5]\d{7,8}$"))
                {
                    SSOK_AutoMaskAddNumberTailRect(items, rects, seen, "phone", SSOK_AutoMaskGetPhoneKeepDigits(digits))
                    continue
                }
                if (RegExMatch(digits, "^\d{14,16}$"))
                {
                    SSOK_AutoMaskAddNumberTailRect(items, rects, seen, "card", 4)
                    continue
                }
            }
            labelNameText := SSOK_CompactLabelText(packedRaw)
            if (RegExMatch(labelNameText, "^(¼º¸í|¼ºÇÔ|ÀÌ¸§|´ã´çÀÚ|½ÅÃ»ÀÎ|¹Î¿øÀÎ|ÇÐ»ý¸í|ÇÐ»ýÀÌ¸§|±³»ç¸í|º¸È£ÀÚ|º¸È£ÀÚ¸í|ÀÛ¼ºÀÚ|¼ö·ÉÀÎ|ÇÐºÎ¸ð|´ãÀÓ)([°¡-ÆR]{2,4})$"))
            {
                lastItem := items[items.Length()]
                if (SSOK_IsKoreanNameCandidate(lastItem.Text))
                    SSOK_AutoMaskAddTextTailRect(lastItem, rects, seen, "name", 1)
                else
                    SSOK_AutoMaskAddRect(items, rects, seen, "name")
                continue
            }
            email := SSOK_NormalizeEmailText(packedRaw)
            if (RegExMatch(email, "i)^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"))
            {
                SSOK_AutoMaskAddEmailMaskRect(items, rects, seen)
                continue
            }
        }
        if (SSOK_IsNameLabel(words[i].Text))
        {
            last := Min(count, i + 3)
            j := i + 1
            while (j <= last)
            {
                if (SSOK_IsKoreanNameCandidate(words[j].Text))
                {
                    SSOK_AutoMaskAddTextTailRect(words[j], rects, seen, "name", 1)
                    break
                }
                j++
            }
        }
        if (SSOK_IsPhoneLabel(words[i].Text))
            SSOK_AutoMaskAddLabeledNumericRect(words, i, rects, seen, "phone", 7, 12, 5)
        if (SSOK_IsRrnLabel(words[i].Text))
            SSOK_AutoMaskAddLabeledNumericRect(words, i, rects, seen, "rrn", 6, 13, 5)
        if (SSOK_IsEmailLabel(words[i].Text))
        {
            last := Min(count, i + 6)
            j := i + 1
            while (j <= last)
            {
                maxN2 := Min(6, last - j + 1)
                Loop, %maxN2%
                {
                    items := SSOK_ArraySlice(words, j, A_Index)
                    email := SSOK_NormalizeEmailText(SSOK_JoinWordTexts(items, ""))
                    if (RegExMatch(email, "i)^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"))
                    {
                        SSOK_AutoMaskAddEmailMaskRect(items, rects, seen)
                        break
                    }
                }
                j++
            }
        }
        if (SSOK_IsAddressLabel(words[i].Text))
        {
            last := Min(count, i + 7)
            if (last >= i + 1)
                SSOK_AutoMaskAddRect(SSOK_ArraySlice(words, i + 1, last - i), rects, seen, "address")
        }
    }
}

SSOK_AutoMaskAddLabeledNumericRect(words, start, ByRef rects, ByRef seen, kind, minDigits, maxDigits, maxWords)
{
    last := Min(words.Length(), start + maxWords)
    j := start + 1
    while (j <= last)
    {
        maxN := Min(maxWords, last - j + 1)
        Loop, %maxN%
        {
            items := SSOK_ArraySlice(words, j, A_Index)
            digits := SSOK_CompactNumberText(SSOK_JoinWordTexts(items, ""))
            if (StrLen(digits) >= minDigits && StrLen(digits) <= maxDigits)
            {
                keep := SSOK_AutoMaskGetKeepDigitsForKind(kind, digits)
                if (StrLen(digits) > keep)
                    SSOK_AutoMaskAddNumberTailRect(items, rects, seen, kind, keep)
                return
            }
        }
        j++
    }
}

SSOK_AutoMaskAddRect(items, ByRef rects, ByRef seen, kind)
{
    if (!IsObject(items) || items.Length() < 1)
        return
    x1 := items[1].X, y1 := items[1].Y, x2 := items[1].R, y2 := items[1].B
    for _, item in items
    {
        x1 := Min(x1, item.X)
        y1 := Min(y1, item.Y)
        x2 := Max(x2, item.R)
        y2 := Max(y2, item.B)
    }
    SSOK_AutoMaskAddBoundsRect(rects, seen, x1, y1, x2, y2, kind)
}

SSOK_AutoMaskAddBoundsRect(ByRef rects, ByRef seen, x1, y1, x2, y2, kind)
{
    if (x2 <= x1 || y2 <= y1)
        return
    margin := Max(3.0, (y2 - y1) * 0.18)
    x := Max(0, Floor(x1 - margin))
    y := Max(0, Floor(y1 - margin))
    w := Ceil((x2 - x1) + (margin * 2))
    h := Ceil((y2 - y1) + (margin * 2))
    if (w < 4 || h < 4)
        return
    key := Round(x) "|" Round(y) "|" Round(w) "|" Round(h)
    if (seen.HasKey(key))
        return
    seen[key] := true
    rects.Push({X: x, Y: y, W: w, H: h, Kind: kind})
}

SSOK_AutoMaskAddItemSliceRect(item, ByRef rects, ByRef seen, startRatio, endRatio, kind)
{
    if (!IsObject(item))
        return
    if (startRatio < 0.0)
        startRatio := 0.0
    if (endRatio > 1.0)
        endRatio := 1.0
    if (endRatio <= startRatio)
        return
    width := item.R - item.X
    if (width <= 1.0)
        return
    x1 := item.X + (width * startRatio)
    x2 := item.X + (width * endRatio)
    SSOK_AutoMaskAddBoundsRect(rects, seen, x1, item.Y, x2, item.B, kind)
}

SSOK_AutoMaskAddNumberTailRect(items, ByRef rects, ByRef seen, kind, keepDigits)
{
    leftToKeep := keepDigits
    maskStarted := false
    for _, item in items
    {
        digitCount := StrLen(SSOK_CompactNumberText(item.Text))
        if (digitCount < 1)
            continue
        if (!maskStarted)
        {
            if (leftToKeep >= digitCount)
            {
                leftToKeep -= digitCount
                continue
            }
            if (leftToKeep > 0)
            {
                ratio := SSOK_AutoMaskGetDigitBoundaryRatio(item.Text, leftToKeep)
                SSOK_AutoMaskAddItemSliceRect(item, rects, seen, ratio, 1.0, kind)
                maskStarted := true
                leftToKeep := 0
                continue
            }
            maskStarted := true
        }
        SSOK_AutoMaskAddRect([item], rects, seen, kind)
    }
}

SSOK_AutoMaskGetDigitBoundaryRatio(text, keepDigits)
{
    if (text = "" || keepDigits <= 0)
        return 0.0
    count := 0
    boundary := 0
    Loop, Parse, text
    {
        ch := A_LoopField
        if (StrLen(SSOK_CompactNumberText(ch)) > 0)
        {
            count++
            if (count >= keepDigits)
            {
                boundary := A_Index
                break
            }
        }
    }
    if (boundary < 1)
        return 0.0
    len := StrLen(text)
    while (boundary < len)
    {
        next := SubStr(text, boundary + 1, 1)
        if (StrLen(SSOK_CompactNumberText(next)) > 0)
            break
        boundary++
    }
    return Min(1.0, Max(0.0, boundary / len))
}

SSOK_AutoMaskAddTextTailRect(item, ByRef rects, ByRef seen, kind, keepChars)
{
    t := item.Text
    len := StrLen(t)
    if (len <= keepChars)
        return
    SSOK_AutoMaskAddItemSliceRect(item, rects, seen, keepChars / len, 1.0, kind)
}

SSOK_AutoMaskAddEmailMaskRect(items, ByRef rects, ByRef seen)
{
    for _, item in items
    {
        text := StrReplace(item.Text, "£À", "@")
        at := InStr(text, "@")
        if (at > 1)
        {
            keep := (at <= 3) ? 1 : 2
            if (at > keep)
            {
                len := StrLen(text)
                SSOK_AutoMaskAddItemSliceRect(item, rects, seen, keep / len, (at - 1) / len, "email")
                return
            }
        }
    }
    SSOK_AutoMaskAddRect(items, rects, seen, "email")
}

SSOK_AutoMaskGetPhoneKeepDigits(digits)
{
    if (SubStr(digits, 1, 2) = "02")
        return 2
    if (SubStr(digits, 1, 1) = "0")
        return 3
    return 3
}

SSOK_AutoMaskGetKeepDigitsForKind(kind, digits)
{
    if (kind = "rrn")
        return 6
    if (kind = "phone")
        return SSOK_AutoMaskGetPhoneKeepDigits(digits)
    if (kind = "card")
        return 4
    return 0
}

SSOK_ArraySlice(arr, start, count)
{
    out := []
    maxIdx := Min(arr.Length(), start + count - 1)
    i := start
    while (i <= maxIdx)
    {
        out.Push(arr[i])
        i++
    }
    return out
}

SSOK_CompactLabelText(text)
{
    return RegExReplace(text, "[\s:£º,£¬\.\(\)\[\]{}<>]", "")
}

SSOK_NormalizeOcrDigitText(text)
{
    text := RegExReplace(text, "[Oo]", "0")
    text := RegExReplace(text, "[Il\|!]", "1")
    text := RegExReplace(text, "[Ss]", "5")
    text := RegExReplace(text, "[Bb]", "8")
    text := RegExReplace(text, "[Zz]", "2")
    return text
}

SSOK_CompactNumberText(text)
{
    return RegExReplace(SSOK_NormalizeOcrDigitText(text), "[^0-9]", "")
}

SSOK_NormalizeEmailText(text)
{
    text := RegExReplace(text, "\s", "")
    text := StrReplace(text, "£À", "@")
    text := RegExReplace(text, "i)(£¨at£©|\(at\)|\[at\])", "@")
    return text
}

SSOK_IsNameLabel(text)
{
    text := SSOK_CompactLabelText(text)
    return RegExMatch(text, "^(¼º¸í|¼ºÇÔ|ÀÌ¸§|´ã´çÀÚ|½ÅÃ»ÀÎ|¹Î¿øÀÎ|ÇÐ»ý¸í|ÇÐ»ýÀÌ¸§|±³»ç¸í|º¸È£ÀÚ|º¸È£ÀÚ¸í|ÀÛ¼ºÀÚ|¼ö·ÉÀÎ|ÇÐºÎ¸ð|´ãÀÓ)$")
}

SSOK_IsKoreanNameCandidate(text)
{
    text := SSOK_CompactLabelText(text)
    return RegExMatch(text, "^[°¡-ÆR]{2,4}$")
}

SSOK_IsPhoneLabel(text)
{
    text := SSOK_CompactLabelText(text)
    return RegExMatch(text, "i)^(ÀüÈ­|ÀüÈ­¹øÈ£|¿¬¶ôÃ³|ÈÞ´ëÀüÈ­|ÈÞ´ëÆù|ÇÚµåÆù|ÈÞ´ëÆù¹øÈ£|ÇÚµåÆù¹øÈ£|ÆÑ½º|Fax|FAX|Tel|TEL|HP|Mobile)$")
}

SSOK_IsEmailLabel(text)
{
    text := SSOK_CompactLabelText(text)
    return RegExMatch(text, "i)^(ÀÌ¸ÞÀÏ|¸ÞÀÏ|ÀüÀÚ¸ÞÀÏ|ÀüÀÚ¿ìÆí|Email|EMAIL|E-mail|e-mail)$")
}

SSOK_IsRrnLabel(text)
{
    text := SSOK_CompactLabelText(text)
    return RegExMatch(text, "^(ÁÖ¹Îµî·Ï¹øÈ£|ÁÖ¹Î¹øÈ£|»ý³â¿ùÀÏ|»ý³â¿ùÀÏ¹øÈ£|µî·Ï¹øÈ£|°³ÀÎ¹øÈ£)$")
}

SSOK_IsAddressLabel(text)
{
    text := SSOK_CompactLabelText(text)
    return RegExMatch(text, "^(ÁÖ¼Ò|ÀÚÅÃÁÖ¼Ò|°ÅÁÖÁö|¼ÒÀçÁö|µµ·Î¸íÁÖ¼Ò)$")
}
SSOK_ExtractTextFromCapture(mode := "text")
{
    global SSOK_LastCaptureFile
    if (SSOK_LastCaptureFile = "" || !FileExist(SSOK_LastCaptureFile))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ¸ÕÀú Ä¸Ã³¸¦ ½ÇÇàÇØ ÁÖ¼¼¿ä.
        return
    }

    ocrImageFile := SSOK_PrepareSmallTextOcrImage(SSOK_LastCaptureFile)
    if (ocrImageFile = "")
        ocrImageFile := SSOK_LastCaptureFile
    if (!FileExist(ocrImageFile))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, OCR ´ë»ó ÀÌ¹ÌÁö ÆÄÀÏÀ» Ã£Áö ¸øÇß½À´Ï´Ù.`n´Ù½Ã Ä¸Ã³ÇÑ µÚ ½ÃµµÇØ ÁÖ¼¼¿ä.
        return
    }

    cleanupOcrImage := (ocrImageFile != SSOK_LastCaptureFile)
    directOcrErr := ""
    if (!SSOK_WinRtOcrImageToText(ocrImageFile, mode, directOcrText, directOcrErr))
    {
        if (cleanupOcrImage)
            FileDelete, %ocrImageFile%
        titleText := (mode = "table") ? "Ç¥ ÃßÃâ" : "ÅØ½ºÆ® ÃßÃâ"
        msg := titleText "¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n¿ÜºÎ ÇÁ·Î¼¼½º fallback ¾øÀÌ AHK DllCall WinRT OCR¸¸ »ç¿ëÇß½À´Ï´Ù."
        if (directOcrErr != "")
            msg .= "`n`n¿À·ù ³»¿ë: " directOcrErr
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, %msg%
        return
    }

    if (cleanupOcrImage)
        FileDelete, %ocrImageFile%
    SSOK_FinishExtractedOcrText(directOcrText, mode)
}
SSOK_FormatOcrText(text)
{
    ; OCR °á°ú¸¦ »ç¶÷ÀÌ ºÙ¿©³Ö±â ÆíÇÏ°Ô ÁÙ/´Ü¶ô Áß½ÉÀ¸·Î °¡º±°Ô Á¤¸®ÇÕ´Ï´Ù.
    ; ÀÎ½Ä ±ÛÀÚ¸¦ »õ·Î ÃßÁ¤ÇÏÁö ¾Ê°í, ÁÙ¹Ù²Þ¡¤°ø¹é¡¤¹øÈ£ ¾Õ ÁÙ³ª´®¸¸ º¸Á¤ÇÕ´Ï´Ù.
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    text := StrReplace(text, Chr(160), " ")
    text := RegExReplace(text, "[ \t]+", " ")
    text := RegExReplace(text, "\s+([,.!?;:])", "$1")
    text := RegExReplace(text, "([¡¸¡º\(\[])\s+", "$1")
    text := RegExReplace(text, "\s+([¡¹¡»\)\]])", "$1")

    ; ÇÑ ÁÙ·Î ºÙ¾î ³ª¿Â ÇàÁ¤¹®¼­Çü OCR °á°ú¸¦ ¹øÈ£/Ç×¸ñ ¾Õ¿¡¼­ ÁÙ¹Ù²ÞÇÕ´Ï´Ù.
    text := RegExReplace(text, "([^\n])\s+([0-9]{1,2}\.\s*)", "$1`n$2")
    text := RegExReplace(text, "([^\n])\s+([°¡³ª´Ù¶ó¸¶¹Ù»ç¾ÆÀÚÂ÷Ä«Å¸ÆÄÇÏ]\.\s*)", "$1`n$2")
    text := RegExReplace(text, "([^\n])\s+([0-9]{1,2}\)\s*)", "$1`n$2")
    text := RegExReplace(text, "([^\n])\s+([°¡³ª´Ù¶ó¸¶¹Ù»ç¾ÆÀÚÂ÷Ä«Å¸ÆÄÇÏ]\)\s*)", "$1`n$2")
    text := RegExReplace(text, "([^\n])\s+(-\s+)", "$1`n$2")
    text := RegExReplace(text, "([^\n])\s+(ºÙÀÓ\s*)", "$1`n`n$2")
    text := RegExReplace(text, "([^\n])\s+(³¡\.)", "$1`n$2")
    text := RegExReplace(text, "([^\n])\s+(°ü·Ã:|¸ñÀû:|ÀÏ½Ã:|Àå¼Ò:|´ë»ó:|³»¿ë:|¹æ¹ý:|±Ý¾×:|¿¹»ê:|»êÃâ³»¿ª:)", "$1`n$2")

    out := ""
    prevBlank := false
    Loop, Parse, text, `n, `r
    {
        line := Trim(A_LoopField, " `t")
        line := RegExReplace(line, "[ \t]+", " ")
        line := RegExReplace(line, "^([0-9]{1,2})\s+\.", "$1.")
        line := RegExReplace(line, "^([°¡³ª´Ù¶ó¸¶¹Ù»ç¾ÆÀÚÂ÷Ä«Å¸ÆÄÇÏ])\s+\.", "$1.")
        line := RegExReplace(line, "^([0-9]{1,2})\s+\)", "$1)")
        line := RegExReplace(line, "^([°¡³ª´Ù¶ó¸¶¹Ù»ç¾ÆÀÚÂ÷Ä«Å¸ÆÄÇÏ])\s+\)", "$1)")
        line := RegExReplace(line, "^([0-9]{1,2}\.|[°¡³ª´Ù¶ó¸¶¹Ù»ç¾ÆÀÚÂ÷Ä«Å¸ÆÄÇÏ]\.|[0-9]{1,2}\)|[°¡³ª´Ù¶ó¸¶¹Ù»ç¾ÆÀÚÂ÷Ä«Å¸ÆÄÇÏ]\))\s*", "$1 ")
        line := RegExReplace(line, "^-\s*", "- ")

        if (line = "")
        {
            if (!prevBlank && out != "")
            {
                out .= "`r`n"
                prevBlank := true
            }
            continue
        }

        ; ¾ÆÁÖ ±æ°Ô ÇÑ ÁÙ·Î ºÙÀº °æ¿ì¿¡´Â ÁÖ¿ä Ç×¸ñ ¾Õ¿¡¼­ ÇÑ ¹ø ´õ ÁÙÀ» ³ª´¯´Ï´Ù.
        if (StrLen(line) > 90)
        {
            line := RegExReplace(line, "\s+(?=(°ü·Ã:|¸ñÀû:|ÀÏ½Ã:|Àå¼Ò:|´ë»ó:|³»¿ë:|¹æ¹ý:|±Ý¾×:|¿¹»ê:|»êÃâ³»¿ª:|ºÙÀÓ|[0-9]{1,2}\.|[°¡³ª´Ù¶ó¸¶¹Ù»ç¾ÆÀÚÂ÷Ä«Å¸ÆÄÇÏ]\.))", "`r`n")
        }

        if (out != "" && SubStr(out, 0) != "`n")
            out .= "`r`n"
        out .= line
        prevBlank := false
    }
    return Trim(out, " `t`r`n")
}

SSOK_FormatOcrTable(text)
{
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    text := StrReplace(text, Chr(160), " ")
    out := ""
    Loop, Parse, text, `n
    {
        line := Trim(A_LoopField, " `t")
        if (line = "")
            continue
        line := RegExReplace(line, "[ ]*\t[ ]*", "`t")
        line := RegExReplace(line, "[ \t]+$", "")
        line := RegExReplace(line, "^[ \t]+", "")
        if (out != "")
            out .= "`r`n"
        out .= line
    }
    return Trim(out, " `t`r`n")
}


; ------------------------------------------------------------
; AHK ÀÚÃ¼ GUI + GDI+ ÅëÇÕ Ä¸Ã³ ÆíÁý±â
; - ¹øÈ£, ³×¸ð ¹Ú½º, È­»ìÇ¥, ±Û»óÀÚ, °­Á¶, ¸ðÀÚÀÌÅ©¸¦ ±×¸²ÆÇ ¾øÀÌ Ã³¸®ÇÕ´Ï´Ù.
; - Å¬¸¯ ÁÂÇ¥´Â AHK Picture ÄÁÆ®·Ñ ³»ºÎ ÁÂÇ¥¸¦ »ç¿ëÇÏ¹Ç·Î ±×¸²ÆÇ ¸®º»/¹èÀ²/½ºÅ©·Ñ ¿µÇâÀ» ¹ÞÁö ¾Ê½À´Ï´Ù.
; ------------------------------------------------------------
SSOK_GetStampEditorMaxSize(ByRef maxW, ByRef maxH)
{
    global SSOK_StampGuiHwnd
    if (SSOK_StampGuiHwnd != "")
    {
        WinGetPos, wx, wy, ww, wh, ahk_id %SSOK_StampGuiHwnd%
        if (wx != "" && wy != "" && ww != "" && wh != "")
        {
            mx := wx + (ww // 2)
            my := wy + (wh // 2)
        }
    }
    if (mx = "" || my = "")
    {
        CoordMode, Mouse, Screen
        MouseGetPos, mx, my
    }
    if (SSOK_GetMonitorBoundsFromPoint(mx, my, monLeft, monTop, monRight, monBottom))
    {
        maxW := (monRight - monLeft) - 120
        maxH := (monBottom - monTop) - 180
    }
    else
    {
    maxW := A_ScreenWidth - 120
        maxH := A_ScreenHeight - 180
    }
    if (maxW < 500)
        maxW := 500
    if (maxH < 360)
        maxH := 360
    return true
}

SSOK_OpenNumberStampEditor()
{
    global SSOK_StampGuiHwnd, SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDisplayW, SSOK_StampDisplayH, SSOK_StampInfoW
    global SSOK_StampPicHwnd, SSOK_StampPreviewFile, SSOK_StampSourceFile, SSOK_StampDirty, SSOK_StampNo
    global SSOK_StampInfoText, SSOK_StampPic, SSOK_StampTool, SSOK_StampDragging, SSOK_StampDragStartX, SSOK_StampDragStartY
    global SSOK_StampMainColor, SSOK_StampSizeLevel, SSOK_StampNumberColor, SSOK_StampRectColor, SSOK_StampArrowColor, SSOK_StampHighlightColor, SSOK_StampHighlightSize, SSOK_StampMosaicBlock
    global SSOK_StampTextEditHwnd, SSOK_StampInlineText, SSOK_StampTextEditing, SSOK_StampTextInput, SSOK_StampTextInputHwnd, SSOK_StampEmojiName
    global SSOK_StampColorHwnd, SSOK_StampSizeHwnd, SSOK_StampEmojiHwnd, SSOK_StampPendingDropdownHwnd
    global SSOK_StampToolRectBtn, SSOK_StampToolHighlightBtn, SSOK_StampToolArrowBtn, SSOK_StampToolTextBtn, SSOK_StampToolNumberBtn, SSOK_StampToolEmojiBtn, SSOK_StampToolMosaicBtn, SSOK_StampToolBorderBtn, SSOK_StampToolAutoMaskBtn
    global SSOK_StampUndoStack
    global SSOK_StampPreviewLineT, SSOK_StampPreviewLineB, SSOK_StampPreviewLineL, SSOK_StampPreviewLineR, SSOK_StampPreviewDot
    global SSOK_StampPreviewSeg1, SSOK_StampPreviewSeg2, SSOK_StampPreviewSeg3, SSOK_StampPreviewSeg4, SSOK_StampPreviewSeg5, SSOK_StampPreviewSeg6, SSOK_StampPreviewSeg7, SSOK_StampPreviewSeg8
    global SSOK_StampPreviewSeg9, SSOK_StampPreviewSeg10, SSOK_StampPreviewSeg11, SSOK_StampPreviewSeg12, SSOK_StampPreviewSeg13, SSOK_StampPreviewSeg14, SSOK_StampPreviewSeg15, SSOK_StampPreviewSeg16
    global SSOK_StampPreviewSeg17, SSOK_StampPreviewSeg18, SSOK_StampPreviewSeg19, SSOK_StampPreviewSeg20, SSOK_StampPreviewSeg21, SSOK_StampPreviewSeg22, SSOK_StampPreviewSeg23, SSOK_StampPreviewSeg24
    global SSOK_StampPreviewSeg25, SSOK_StampPreviewSeg26, SSOK_StampPreviewSeg27, SSOK_StampPreviewSeg28, SSOK_StampPreviewSeg29, SSOK_StampPreviewSeg30, SSOK_StampPreviewSeg31, SSOK_StampPreviewSeg32

    if (SSOK_StampGuiHwnd != "")
    {
        SSOK_BringStampEditorToFront()
        return true
    }

    sourceFile := ""
    pBitmap := SSOK_LoadBitmapForStampEditor(sourceFile)
    if (!pBitmap)
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÆíÁýÇÒ Ä¸Ã³ ÀÌ¹ÌÁö¸¦ °¡Á®¿ÀÁö ¸øÇß½À´Ï´Ù.`nÄ¸Ã³ ÈÄ ´Ù½Ã ½ÇÇàÇØÁÖ¼¼¿ä.
        return false
    }

    SSOK_DisposeStampBitmap()
    SSOK_StampBitmap := pBitmap
    SSOK_StampSourceFile := sourceFile
    SSOK_StampRememberTempFile(sourceFile)
    SSOK_StampDirty := false
    SSOK_ClearStampUndoStack()
    SSOK_StampDragging := false
    SSOK_StampDragStartX := 0
    SSOK_StampDragStartY := 0
    ; ÆíÁý±â¿¡ Ã³À½ µé¾î°¡¸é ¹øÈ£ ½ºÅÆÇÁ°¡ ¾Æ´Ï¶ó ³×¸ð ¹Ú½º°¡ ¸ÕÀú ¼±ÅÃµÇµµ·Ï °íÁ¤ÇÕ´Ï´Ù.
    SSOK_StampTool := "rect"

    Gdip_GetImageDimensions(SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH)
    if (SSOK_StampImageW < 1 || SSOK_StampImageH < 1)
    {
        SSOK_DisposeStampBitmap()
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÀÌ¹ÌÁö Å©±â¸¦ È®ÀÎÇÏÁö ¸øÇß½À´Ï´Ù.
        return false
    }

    ; Å« È­¸é Ä¸Ã³µµ Âî±×·¯Á® º¸ÀÌÁö ¾Êµµ·Ï ½ÇÁ¦ ÀÌ¹ÌÁö´Â ¿øº» ÇØ»óµµ·Î º¸Á¸ÇÏ°í,
    ; ÆíÁý±â¿¡´Â È­¸é¿¡ ¸ÂÃá °íÇ°Áú Ãà¼Ò ¹Ì¸®º¸±â¸¸ Ç¥½ÃÇÕ´Ï´Ù.
    SSOK_GetStampEditorMaxSize(maxW, maxH)

    scaleW := maxW / SSOK_StampImageW
    scaleH := maxH / SSOK_StampImageH
    scale := (scaleW < scaleH) ? scaleW : scaleH
    if (scale > 1)
        scale := 1
    if (scale <= 0)
        scale := 1
    SSOK_StampDisplayW := Round(SSOK_StampImageW * scale)
    SSOK_StampDisplayH := Round(SSOK_StampImageH * scale)
    if (SSOK_StampDisplayW < 1)
        SSOK_StampDisplayW := 1
    if (SSOK_StampDisplayH < 1)
        SSOK_StampDisplayH := 1

    if (!SSOK_StampRefreshPreview())
    {
        SSOK_DisposeStampBitmap()
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÆíÁý ¹Ì¸®º¸±â¸¦ ¸¸µéÁö ¸øÇß½À´Ï´Ù.
        return false
    }

    SSOK_StampColorHwnd := ""
    SSOK_StampSizeHwnd := ""
    SSOK_StampEmojiHwnd := ""
    SSOK_StampPendingDropdownHwnd := ""
    Gui, Stamp:Destroy
    Gui, Stamp:New, +HwndSSOK_StampGuiHwnd +Resize, SSOK ½ºÅ©¸° Ä¸Ã³ ÆíÁý±â
    Gui, Stamp:+OwnDialogs
    Gui, Stamp:Color, F2F5F1
    Gui, Stamp:Margin, 10, 10
    Gui, Stamp:Font, s9, ¸¼Àº °íµñ
    infoW := SSOK_StampDisplayW
    if (infoW < 1040)
        infoW := 1040
    SSOK_StampInfoW := infoW

    ; »ó´Ü ¼³¸í ¹®±¸´Â ¼û±â°í, ¼±ÅÃµÈ µµ±¸´Â ¹öÆ° ÀÚÃ¼¸¦ °­Á¶ Ç¥½ÃÇÕ´Ï´Ù.
    Gui, Stamp:Font, s8, ¸¼Àº °íµñ
    Gui, Stamp:Add, Text, x0 y0 w1 h1 Hidden vSSOK_StampInfoText,

    ; 1ÁÙ: µµ±¸ ¸Þ´º + ¹®±¸ ÀÔ·Â + ÀÌ¸ðÆ¼ÄÜ ¼±ÅÃ
    Gui, Stamp:Font, s9 Bold, ¸¼Àº °íµñ
    Gui, Stamp:Add, Text, xm ym w64 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolRectBtn gSSOK_StampToolRect, ¹Ú½º
    Gui, Stamp:Add, Text, x+5 yp w74 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolHighlightBtn gSSOK_StampToolHighlight, Çü±¤Ææ
    Gui, Stamp:Add, Text, x+5 yp w64 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolArrowBtn gSSOK_StampToolArrow, È­»ìÇ¥
    Gui, Stamp:Add, Text, x+5 yp w70 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolTextBtn gSSOK_StampToolText, ±Û¾²±â
    Gui, Stamp:Font, s9, ¸¼Àº °íµñ
    Gui, Stamp:Add, Edit, x+4 yp+3 w160 h24 vSSOK_StampTextInput HwndSSOK_StampTextInputHwnd, %SSOK_StampTextInput%
    Gui, Stamp:Font, s9 Bold, ¸¼Àº °íµñ
    Gui, Stamp:Add, Text, x+5 yp-3 w86 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolNumberBtn gSSOK_StampToolNumber, ¹øÈ£½ºÅÆÇÁ
    Gui, Stamp:Add, Text, x+5 yp w72 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolEmojiBtn gSSOK_StampToolEmoji, ÀÌ¸ðÆ¼ÄÜ
    Gui, Stamp:Font, s9, ¸¼Àº °íµñ
    Gui, Stamp:Add, DropDownList, x+4 yp+3 w110 vSSOK_StampEmojiName HwndSSOK_StampEmojiHwnd gSSOK_StampOptionsChanged, Ã¼Å©|¿¢½º|°æ°í|º°|ÇÉ|Àü±¸|¸»Ç³¼±|ÇÏÆ®|´À³¦Ç¥|¹°À½Ç¥|½º¸¶ÀÏ|¿ôÀ½|¿ì¿ï|´«¹°|È­³²|¾öÁö
    GuiControl, Stamp:ChooseString, SSOK_StampEmojiName, %SSOK_StampEmojiName%
    Gui, Stamp:Font, s9 Bold, ¸¼Àº °íµñ
    Gui, Stamp:Add, Text, x+5 yp-3 w72 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolMosaicBtn gSSOK_StampToolMosaic, ¸ðÀÚÀÌÅ©
    Gui, Stamp:Add, Text, x+5 yp w64 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolBorderBtn gSSOK_StampOuterBorder, Å×µÎ¸®
    Gui, Stamp:Add, Text, x+5 yp w126 h30 Center +0x200 Border BackgroundE2F1C7 c126600 vSSOK_StampToolAutoMaskBtn gSSOK_StampAutoMask, °³ÀÎÁ¤º¸ ÀÚµ¿°¡¸²

    ; 2ÁÙ ¿ÞÂÊ: »ö»ó / Å©±â
    Gui, Stamp:Font, s9, ¸¼Àº °íµñ
    Gui, Stamp:Add, Text, xm y+8 w42 h24 Center +0x200 BackgroundD6EAF8 c083B58, »ö»ó
    Gui, Stamp:Add, DropDownList, x+4 yp-1 w82 vSSOK_StampMainColor HwndSSOK_StampColorHwnd gSSOK_StampOptionsChanged, »¡°­|ÆÄ¶û|ÃÊ·Ï|ÁÖÈ²|º¸¶ó|°ËÁ¤|³ë¶û
    GuiControl, Stamp:ChooseString, SSOK_StampMainColor, %SSOK_StampMainColor%
    Gui, Stamp:Add, Text, x+12 yp+1 w42 h24 Center +0x200 BackgroundD6EAF8 c083B58, Å©±â
    Gui, Stamp:Add, DropDownList, x+4 yp-1 w72 vSSOK_StampSizeLevel HwndSSOK_StampSizeHwnd gSSOK_StampOptionsChanged, ÀÛ°Ô|Áß°£|Å©°Ô
    GuiControl, Stamp:ChooseString, SSOK_StampSizeLevel, %SSOK_StampSizeLevel%

    ; 2ÁÙ ¿À¸¥ÂÊ: ½ÇÇà ¹öÆ°
    actionW := 74 + 5 + 86 + 5 + 78 + 5 + 70 + 5 + 66 + 5 + 86 + 5 + 68
    actionX := 10 + infoW - actionW
    Gui, Stamp:Font, s7 Bold, ¸¼Àº °íµñ
    Gui, Stamp:Add, Text, x%actionX% yp-1 w74 h30 Center +0x200 Border BackgroundE5E5E5 c000000 gSSOK_StampExtractText, ÅØ½ºÆ® ÃßÃâ
    Gui, Stamp:Add, Text, x+5 yp w86 h30 Center +0x200 Border BackgroundE5E5E5 c000000 gSSOK_StampExtractTable, Ç¥ ÃßÃâ(¿¢¼¿)
    Gui, Stamp:Add, Text, x+5 yp w78 h30 Center +0x200 Border BackgroundE5E5E5 c000000 gSSOK_StampWindowsOcr, À©µµ¿ìOCR
    Gui, Stamp:Add, Text, x+5 yp w70 h30 Center +0x200 Border BackgroundE5E5E5 c000000 gSSOK_StampReduce10, 10`% ÁÙÀÌ±â
    Gui, Stamp:Add, Text, x+5 yp w66 h30 Center +0x200 Border BackgroundE5E5E5 c000000 gSSOK_StampUndoLabel, µÇµ¹¸®±â
    Gui, Stamp:Add, Text, x+5 yp w86 h30 Center +0x200 Border BackgroundE5E5E5 c000000 gSSOK_StampCopyClipboard, Å¬¸³º¸µå º¹»ç
    Gui, Stamp:Add, Text, x+5 yp w68 h30 Center +0x200 Border BackgroundE5E5E5 c000000 gSSOK_StampSaveJpg, ÆÄÀÏ ÀúÀå
    ; ÆíÁý ÀÌ¹ÌÁö°¡ »ó´Ü ¸Þ´º Æøº¸´Ù ÀÛÀ» ¶§ ¿ÞÂÊ¿¡ ºÙÁö ¾Êµµ·Ï °¡¿îµ¥ ¹èÄ¡
    picX := 10
    if (infoW > SSOK_StampDisplayW)
        picX := 10 + Floor((infoW - SSOK_StampDisplayW) / 2)
    Gui, Stamp:Add, Picture, x%picX% y+8 w%SSOK_StampDisplayW% h%SSOK_StampDisplayH% +0x100 vSSOK_StampPic HwndSSOK_StampPicHwnd, %SSOK_StampPreviewFile%
    Gui, Stamp:Add, Progress, x0 y0 w1 h1 vSSOK_StampPreviewLineT cFF0000 BackgroundFF0000 Hidden +E0x20, 100
    Gui, Stamp:Add, Progress, x0 y0 w1 h1 vSSOK_StampPreviewLineB cFF0000 BackgroundFF0000 Hidden +E0x20, 100
    Gui, Stamp:Add, Progress, x0 y0 w1 h1 vSSOK_StampPreviewLineL cFF0000 BackgroundFF0000 Hidden +E0x20, 100
    Gui, Stamp:Add, Progress, x0 y0 w1 h1 vSSOK_StampPreviewLineR cFF0000 BackgroundFF0000 Hidden +E0x20, 100
    Loop, 32
    {
        _seg := A_Index
        Gui, Stamp:Add, Progress, x0 y0 w1 h1 vSSOK_StampPreviewSeg%_seg% cFF0000 BackgroundFF0000 Hidden +E0x20, 100
    }
    Gui, Stamp:Add, Progress, x0 y0 w8 h8 vSSOK_StampPreviewDot cFF0000 BackgroundFF0000 Hidden +E0x20, 100
    Gui, Stamp:Add, Edit, x%picX% y10 w200 h32 vSSOK_StampInlineText HwndSSOK_StampTextEditHwnd Hidden -Wrap
    Gui, Stamp:Show, AutoSize Center, SSOK ½ºÅ©¸° Ä¸Ã³ ÆíÁý±â
    SSOK_BringStampEditorToFront()
    SetTimer, SSOK_BringStampEditorToFrontTimer, -250
    SetTimer, SSOK_BringStampEditorToFrontTimer, -900
    SSOK_StampFocusCanvas()
    SSOK_WriteActiveEditorInfo(true)
    SetTimer, SSOK_UpdateActiveEditorInfo, 500
    SSOK_StampUpdateInfo()
    return true
}

SSOK_UpdateActiveEditorInfo:
SSOK_WriteActiveEditorInfo()
return

SSOK_BringStampEditorToFrontTimer:
SSOK_BringStampEditorToFront()
return

SSOK_BringStampEditorToFront()
{
    global SSOK_StampGuiHwnd
    if (SSOK_StampGuiHwnd = "")
        return false
    if !WinExist("ahk_id " . SSOK_StampGuiHwnd)
        return false

    WinShow, ahk_id %SSOK_StampGuiHwnd%
    WinRestore, ahk_id %SSOK_StampGuiHwnd%
    DllCall("SetWindowPos", "Ptr", SSOK_StampGuiHwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0043)
    DllCall("SetWindowPos", "Ptr", SSOK_StampGuiHwnd, "Ptr", -2, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0043)
    WinActivate, ahk_id %SSOK_StampGuiHwnd%
    return true
}
SSOK_LoadBitmapForStampEditor(ByRef sourceFile)
{
    global SSOK_PaintHasCapture, SSOK_WorkFolder, SSOK_LastCaptureFile
    sourceFile := ""
    SSOK_PaintHasCapture := false

    if (SSOK_LastCaptureFile != "" && FileExist(SSOK_LastCaptureFile))
    {
        sourceFile := SSOK_LastCaptureFile
        return Gdip_CreateBitmapFromFile(sourceFile)
    }

    if (SSOK_CopySnippingToolImage())
    {
        pBitmap := Gdip_CreateBitmapFromClipboard()
        if (pBitmap)
        {
            FormatTime, now,, yyyyMMdd_HHmmss
            sourceFile := SSOK_WorkFolder "\SSOK_editor_from_clip_" now "_" A_TickCount ".png"
            Gdip_SaveBitmapToFile(pBitmap, sourceFile)
            if (FileExist(sourceFile))
                SSOK_LastCaptureFile := sourceFile
            return pBitmap
        }
        FormatTime, now,, yyyyMMdd_HHmmss
        sourceFile := SSOK_WorkFolder "\SSOK_editor_from_clip_" now "_" A_TickCount ".png"
        if (SSOK_SaveClipboardImageToFile(sourceFile) && FileExist(sourceFile))
        {
            SSOK_LastCaptureFile := sourceFile
            return Gdip_CreateBitmapFromFile(sourceFile)
        }
    }

    if (SSOK_LastCaptureFile != "" && FileExist(SSOK_LastCaptureFile))
    {
        sourceFile := SSOK_LastCaptureFile
        return Gdip_CreateBitmapFromFile(sourceFile)
    }

    if (SSOK_ClipboardHasImage())
    {
        pBitmap := Gdip_CreateBitmapFromClipboard()
        if (pBitmap)
        {
            FormatTime, now,, yyyyMMdd_HHmmss
            sourceFile := SSOK_WorkFolder "\SSOK_editor_from_clip_" now "_" A_TickCount ".png"
            Gdip_SaveBitmapToFile(pBitmap, sourceFile)
            if (FileExist(sourceFile))
                SSOK_LastCaptureFile := sourceFile
            return pBitmap
        }
    }
    return 0
}


SSOK_NormalizeStampOptions()
{
    global SSOK_StampMainColor, SSOK_StampSizeLevel, SSOK_StampEmojiName, SSOK_StampTextInput
    global SSOK_StampNumberColor, SSOK_StampRectColor, SSOK_StampArrowColor, SSOK_StampHighlightColor, SSOK_StampHighlightSize, SSOK_StampMosaicBlock
    if (!SSOK_IsStampColorName(SSOK_StampMainColor))
        SSOK_StampMainColor := "»¡°­"
    if (SSOK_StampSizeLevel != "ÀÛ°Ô" && SSOK_StampSizeLevel != "Áß°£" && SSOK_StampSizeLevel != "Å©°Ô")
        SSOK_StampSizeLevel := "ÀÛ°Ô"
    if (Trim(SSOK_StampTextInput, " `t`r`n") = "")
        SSOK_StampTextInput := "[±â°ü¸í]"
    if (!SSOK_IsStampEmojiName(SSOK_StampEmojiName))
        SSOK_StampEmojiName := "Ã¼Å©"

    ; È£È¯¿ë ±âÁ¸ º¯¼öµµ µ¿ÀÏ »ö»ó/±½±â °ªÀ¸·Î µ¿±âÈ­ÇÕ´Ï´Ù.
    SSOK_StampNumberColor := SSOK_StampMainColor
    SSOK_StampRectColor := SSOK_StampMainColor
    SSOK_StampArrowColor := SSOK_StampMainColor
    SSOK_StampHighlightColor := SSOK_StampMainColor
    SSOK_StampHighlightSize := SSOK_GetHighlightThickness()
    SSOK_StampMosaicBlock := SSOK_GetMosaicBlockSize()
    return true
}

SSOK_IsStampColorName(name)
{
    return (name = "»¡°­" || name = "ÆÄ¶û" || name = "ÃÊ·Ï" || name = "ÁÖÈ²" || name = "º¸¶ó" || name = "°ËÁ¤" || name = "³ë¶û")
}

SSOK_IsStampEmojiName(name)
{
    return (name = "Ã¼Å©" || name = "¿¢½º" || name = "°æ°í" || name = "º°" || name = "ÇÉ" || name = "Àü±¸" || name = "¸»Ç³¼±" || name = "ÇÏÆ®" || name = "´À³¦Ç¥" || name = "¹°À½Ç¥" || name = "½º¸¶ÀÏ" || name = "¿ôÀ½" || name = "¿ì¿ï" || name = "´«¹°" || name = "È­³²" || name = "¾öÁö")
}

SSOK_GetStampColorARGB(name := "", alpha := 255)
{
    global SSOK_StampMainColor
    if (name = "")
        name := SSOK_StampMainColor
    if (alpha < 0)
        alpha := 0
    if (alpha > 255)
        alpha := 255
    if (name = "ÆÄ¶û")
        rgb := 0x1E63FF
    else if (name = "ÃÊ·Ï")
        rgb := 0x00A050
    else if (name = "ÁÖÈ²")
        rgb := 0xFF8C00
    else if (name = "º¸¶ó")
        rgb := 0x8E44AD
    else if (name = "°ËÁ¤")
        rgb := 0x111111
    else if (name = "³ë¶û")
        rgb := 0xFFD400
    else
        rgb := 0xEB0000
    return ((alpha & 0xFF) << 24) | rgb
}

SSOK_GetStampColorHex(name := "")
{
    rgb := SSOK_GetStampColorARGB(name) & 0xFFFFFF
    return Format("{:06X}", rgb)
}

SSOK_GetStampTextColorARGB(name := "")
{
    global SSOK_StampMainColor
    if (name = "")
        name := SSOK_StampMainColor
    if (name = "³ë¶û")
        return 0xFF000000
    return 0xFFFFFFFF
}

SSOK_GetHighlightColorARGB()
{
    global SSOK_StampMainColor
    ; Çü±¤ÆæÀº Å×µÎ¸®/µµ±¸ »ö»ó°ú °°Àº »öÀ» ¾²¸é Àß ¾È º¸ÀÌ¹Ç·Î
    ; ¼±ÅÃ »ö»óÀÇ ´ëºñ °è¿­ ¿¬ÇÑ »öÀ¸·Î Ç¥½ÃÇÕ´Ï´Ù.
    ; Çü±¤Ææ ÁøÇÏ±â´Â ÀÌÀü ±âÁØ Åõ¸íµµ(0x66)¸¦ À¯ÁöÇÕ´Ï´Ù.
    alpha := 0x66

    if (SSOK_StampMainColor = "ÆÄ¶û")
        rgb := 0xFFF2A8   ; ÆÄ¶û ´ëºñ: ¿¬ÇÑ ³ë¶û
    else if (SSOK_StampMainColor = "ÃÊ·Ï")
        rgb := 0xFFD6E8   ; ÃÊ·Ï ´ëºñ: ¿¬ÇÑ ºÐÈ«
    else if (SSOK_StampMainColor = "ÁÖÈ²")
        rgb := 0xD6ECFF   ; ÁÖÈ² ´ëºñ: ¿¬ÇÑ ÇÏ´Ã
    else if (SSOK_StampMainColor = "º¸¶ó")
        rgb := 0xE7FFD6   ; º¸¶ó ´ëºñ: ¿¬ÇÑ ¿¬µÎ
    else if (SSOK_StampMainColor = "°ËÁ¤")
        rgb := 0xFFF2A8   ; °ËÁ¤ ´ëºñ: ¿¬ÇÑ ³ë¶û
    else if (SSOK_StampMainColor = "³ë¶û")
        rgb := 0xD6ECFF   ; ³ë¶û ´ëºñ: ¿¬ÇÑ ÇÏ´Ã
    else
        rgb := 0xFFF2A8   ; »¡°­ ´ëºñ: ¿¬ÇÑ ³ë¶û

    return ((alpha & 0xFF) << 24) | rgb
}

SSOK_GetStampLineWidth()
{
    global SSOK_StampSizeLevel
    if (SSOK_StampSizeLevel = "ÀÛ°Ô")
        return 3
    if (SSOK_StampSizeLevel = "Å©°Ô")
        return 8
    return 5
}

SSOK_GetHighlightThickness()
{
    global SSOK_StampSizeLevel
    if (SSOK_StampSizeLevel = "ÀÛ°Ô")
        return 16
    if (SSOK_StampSizeLevel = "Å©°Ô")
        return 40
    return 26
}

SSOK_GetMosaicBlockSize()
{
    ; Á÷Àü ¹öÀüÀÇ ½ÇÁ¦ Àû¿ë ºí·Ï 4px ±âÁØÀ¸·Î ¾à 25% Å°¿ó´Ï´Ù.
    ; ³Ê¹« ¹¶°³ÁöÁö ¾ÊÀ¸¸é¼­ ÀÌÀüº¸´Ù ¾à°£ ´õ Àß °¡·ÁÁöµµ·Ï 5px·Î °íÁ¤ÇÕ´Ï´Ù.
    return 5
}

SSOK_GetTextBoxFontSize()
{
    global SSOK_StampSizeLevel
    if (SSOK_StampSizeLevel = "ÀÛ°Ô")
        return 13
    if (SSOK_StampSizeLevel = "Å©°Ô")
        return 22
    return 17
}

SSOK_GetTextBoxDefaultHeight()
{
    global SSOK_StampSizeLevel
    if (SSOK_StampSizeLevel = "ÀÛ°Ô")
        return 34
    if (SSOK_StampSizeLevel = "Å©°Ô")
        return 58
    return 44
}

SSOK_AdjustHighlightRect(ByRef rx, ByRef ry, ByRef rw, ByRef rh)
{
    global SSOK_StampImageH
    thick := SSOK_GetHighlightThickness()
    if (thick < 1)
        thick := 26
    if (rh < thick)
    {
        centerY := ry + Round(rh / 2)
        ry := centerY - Round(thick / 2)
        rh := thick
        if (ry < 0)
            ry := 0
        if (ry + rh > SSOK_StampImageH)
            ry := SSOK_StampImageH - rh
        if (ry < 0)
            ry := 0
    }
    return true
}

SSOK_StampSetTool(tool)
{
    global SSOK_StampTool, SSOK_StampDragging, SSOK_StampTextEditing
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    SSOK_StampTool := tool
    SSOK_StampDragging := false
    SSOK_StampUpdateInfo()
    if (tool = "text")
        GuiControl, Stamp:Focus, SSOK_StampTextInput
    return true
}

SSOK_StampGetToolName()
{
    global SSOK_StampTool
    if (SSOK_StampTool = "number")
        return "¹øÈ£"
    if (SSOK_StampTool = "rect")
        return "¹Ú½º"
    if (SSOK_StampTool = "arrow")
        return "È­»ìÇ¥"
    if (SSOK_StampTool = "text")
        return "±Û¾²±â"
    if (SSOK_StampTool = "highlight")
        return "Çü±¤Ææ"
    if (SSOK_StampTool = "mosaic")
        return "¸ðÀÚÀÌÅ©"
    if (SSOK_StampTool = "mask_rrn")
        return "ÁÖ¹ÎµÚ °¡¸²"
    if (SSOK_StampTool = "mask_phone")
        return "ÀüÈ­¹øÈ£ °¡¸²"
    if (SSOK_StampTool = "mask_name")
        return "ÀÌ¸§ °¡¸²"
    if (SSOK_StampTool = "emoji")
        return "ÀÌ¸ðÆ¼ÄÜ"
    if (SSOK_StampTool = "none")
        return "´ë±â"
    return "´ë±â"
}

SSOK_StampUpdateToolButtons()
{
    global SSOK_StampGuiHwnd, SSOK_StampTool
    if (SSOK_StampGuiHwnd = "")
        return

    SSOK_StampSetToolButtonStyle("SSOK_StampToolRectBtn", "¹Ú½º", SSOK_StampTool = "rect")
    SSOK_StampSetToolButtonStyle("SSOK_StampToolHighlightBtn", "Çü±¤Ææ", SSOK_StampTool = "highlight")
    SSOK_StampSetToolButtonStyle("SSOK_StampToolArrowBtn", "È­»ìÇ¥", SSOK_StampTool = "arrow")
    SSOK_StampSetToolButtonStyle("SSOK_StampToolTextBtn", "±Û¾²±â", SSOK_StampTool = "text")
    SSOK_StampSetToolButtonStyle("SSOK_StampToolNumberBtn", "¹øÈ£½ºÅÆÇÁ", SSOK_StampTool = "number")
    SSOK_StampSetToolButtonStyle("SSOK_StampToolEmojiBtn", "ÀÌ¸ðÆ¼ÄÜ", SSOK_StampTool = "emoji")
    SSOK_StampSetToolButtonStyle("SSOK_StampToolMosaicBtn", "¸ðÀÚÀÌÅ©", SSOK_StampTool = "mosaic")
}

SSOK_StampSetToolButtonStyle(ctrlName, caption, isSelected)
{
    if (isSelected)
    {
        GuiControl, Stamp:, %ctrlName%, % "¡Ü " caption
        GuiControl, Stamp:+BackgroundFFD966 +c000000, %ctrlName%
    }
    else
    {
        GuiControl, Stamp:, %ctrlName%, %caption%
        GuiControl, Stamp:+BackgroundE2F1C7 +c126600, %ctrlName%
    }
    GuiControl, Stamp:+Redraw, %ctrlName%
}

SSOK_StampGetInfoText()
{
    global SSOK_StampTool, SSOK_StampNo, SSOK_StampMainColor, SSOK_StampSizeLevel, SSOK_StampEmojiName
    toolName := SSOK_StampGetToolName()
    opt := " | »ö»ó: " SSOK_StampMainColor " / Å©±â: " SSOK_StampSizeLevel
    if (SSOK_StampTool = "number")
        return "ÇöÀç µµ±¸: " toolName opt " | ÀÌ¹ÌÁö¿¡¼­ ¸¶¿ì½º¸¦ ´©¸¥ Ã¤ À§Ä¡¸¦ È®ÀÎÇÏ°í, ¶¼¸é " SSOK_StampNo "¹øÀÌ ÂïÈü´Ï´Ù."
    if (SSOK_StampTool = "text")
        return "ÇöÀç µµ±¸: " toolName opt " | »ó´Ü ¹®±¸ ÀÔ·ÂÄ­¿¡ ¸ÕÀú ÀÔ·ÂÇÑ µÚ, ´©¸¥ Ã¤ À§Ä¡¸¦ È®ÀÎÇÏ°í ¶¼¸é ±ÛÀÚ°¡ ÂïÈü´Ï´Ù."
    if (SSOK_StampTool = "rect")
        return "ÇöÀç µµ±¸: " toolName opt " | ½ÃÀÛÁ¡¿¡¼­ ³¡Á¡±îÁö µå·¡±×ÇÏ¸é ¹Ú½º°¡ ±×·ÁÁý´Ï´Ù."
    if (SSOK_StampTool = "arrow")
        return "ÇöÀç µµ±¸: " toolName opt " | ½ÃÀÛÁ¡¿¡¼­ ³¡Á¡±îÁö µå·¡±×ÇÏ¸é È­»ìÇ¥°¡ ±×·ÁÁý´Ï´Ù."
    if (SSOK_StampTool = "highlight")
        return "ÇöÀç µµ±¸: " toolName opt " | °­Á¶ÇÒ ¿µ¿ªÀ» µå·¡±×ÇÏ¸é °°Àº »ö»ó¿¡ Åõ¸íµµ¸¦ ÁØ Çü±¤ÆæÀÌ ¹Ý¿µµË´Ï´Ù."
    if (SSOK_StampTool = "mosaic")
        return "ÇöÀç µµ±¸: " toolName opt " | °¡¸± ¿µ¿ªÀ» µå·¡±×ÇÏ¸é ¸ðÀÚÀÌÅ©°¡ ¹Ý¿µµË´Ï´Ù."
    if (SSOK_StampIsMaskPresetTool(SSOK_StampTool))
        return "ÇöÀç µµ±¸: " toolName " | ÀÌ¹ÌÁö À§¸¦ Å¬¸¯ÇÏ¸é °³ÀÎÁ¤º¸¿ë °ËÀº ¹Ú½º°¡ °íÁ¤ Å©±â·Î ÂïÈü´Ï´Ù."
    if (SSOK_StampTool = "emoji")
        return "ÇöÀç µµ±¸: " toolName opt " | ÀÌ¸ðÆ¼ÄÜ: " SSOK_StampEmojiName " | ¸¶¿ì½º·Î µå·¡±×ÇÑ Å©±â´ë·Î ÀÌ¸ðÆ¼ÄÜÀÌ ÂïÈü´Ï´Ù."
    if (SSOK_StampTool = "none")
        return "ÇöÀç µµ±¸: ´ë±â" opt " | ¹øÈ£ Á¾·á »óÅÂÀÔ´Ï´Ù. ÇÊ¿äÇÑ µµ±¸¸¦ ¼±ÅÃÇÏ¼¼¿ä."
    return "ÇöÀç µµ±¸: ´ë±â | ÇÊ¿äÇÑ µµ±¸¸¦ ¼±ÅÃÇÏ¼¼¿ä."
}

SSOK_StampScreenClick(screenX, screenY)
{
    global SSOK_StampPicHwnd, SSOK_StampDisplayW, SSOK_StampDisplayH, SSOK_StampTool, SSOK_StampSuppressPicClickUntil
    if (SSOK_StampPicHwnd = "")
        return false
    if (SSOK_StampSuppressPicClickUntil && A_TickCount < SSOK_StampSuppressPicClickUntil)
        return false
    VarSetCapacity(pt, 8, 0)
    NumPut(screenX, pt, 0, "Int")
    NumPut(screenY, pt, 4, "Int")
    DllCall("ScreenToClient", "Ptr", SSOK_StampPicHwnd, "Ptr", &pt)
    x := NumGet(pt, 0, "Int")
    y := NumGet(pt, 4, "Int")
    if (x < 0 || y < 0 || x > SSOK_StampDisplayW || y > SSOK_StampDisplayH)
        return false
    if (SSOK_StampTool = "number")
        return SSOK_StampHandleClick(x, y)
    if (SSOK_StampIsMaskPresetTool(SSOK_StampTool))
        return SSOK_StampHandleMaskPresetClick(x, y)
    if (SSOK_StampTool = "text")
        return SSOK_StampHandleTextClick(x, y)
    if (SSOK_StampTool = "emoji")
        return SSOK_StampHandleEmojiClick(x, y)
    return false
}


SSOK_StampDragPreviewTimer:
    SSOK_StampUpdateDragPreviewFromMouse()
return

SSOK_Stamp_WM_MOUSEMOVE(wParam, lParam, msg, hwnd)
{
    global SSOK_StampDragging, SSOK_StampTool
    ; ÆíÁý ÀÌ¹ÌÁö¿¡¼­ ½ÇÁ¦ µå·¡±× ÁßÀÏ ¶§¸¸ ¸¶¿ì½º ÀÌµ¿ ¸Þ½ÃÁö¸¦ °¡·ÎÃ©´Ï´Ù.
    ; Æò»ó½Ã±îÁö return 0À¸·Î ¸·À¸¸é ÇÏ´Ü »ö»ó/Å©±â/ÀÌ¸ðÆ¼ÄÜ DropDownList°¡
    ; ¸¶¿ì½º hover/click ±âº» µ¿ÀÛÀ» Á¦´ë·Î ¹ÞÁö ¸øÇÒ ¼ö ÀÖ½À´Ï´Ù.
    if (!SSOK_StampDragging)
        return
    SSOK_StampUpdateDragPreviewFromMouse()
    return 0
}

SSOK_StampUpdateDragPreviewFromMouse()
{
    global SSOK_StampDragging, SSOK_StampTool, SSOK_StampDragStartX, SSOK_StampDragStartY
    global SSOK_StampPreviewLastX, SSOK_StampPreviewLastY
    if (!SSOK_StampDragging)
    {
        SetTimer, SSOK_StampDragPreviewTimer, Off
        return false
    }
    CoordMode, Mouse, Screen
    MouseGetPos, sx, sy
    if (!SSOK_StampScreenToPicClient(sx, sy, x, y))
        return false
    SSOK_StampClampPicPoint(x, y)
    if (SSOK_StampPreviewLastX != "" && Abs(x - SSOK_StampPreviewLastX) < 2 && Abs(y - SSOK_StampPreviewLastY) < 2)
        return true
    SSOK_StampPreviewLastX := x
    SSOK_StampPreviewLastY := y
    if (SSOK_StampTool = "number")
        return SSOK_StampShowPlacementPreview(x, y)
    if (SSOK_StampIsMaskPresetTool(SSOK_StampTool))
        return SSOK_StampShowMaskPresetPreview(x, y)
    if (SSOK_StampTool = "text")
        return SSOK_StampShowLivePreview(SSOK_StampDragStartX, SSOK_StampDragStartY, x, y)
    if (SSOK_StampTool = "emoji")
        return SSOK_StampShowLivePreview(SSOK_StampDragStartX, SSOK_StampDragStartY, x, y)
    return SSOK_StampShowLivePreview(SSOK_StampDragStartX, SSOK_StampDragStartY, x, y)
}

SSOK_StampScreenToPicClient(screenX, screenY, ByRef x, ByRef y)
{
    global SSOK_StampPicHwnd
    if (SSOK_StampPicHwnd = "")
        return false
    WinGetPos, picSX, picSY,,, ahk_id %SSOK_StampPicHwnd%
    if (picSX = "" || picSY = "")
        return false
    x := screenX - picSX
    y := screenY - picSY
    return true
}
SSOK_StampClampPicPoint(ByRef x, ByRef y)
{
    global SSOK_StampDisplayW, SSOK_StampDisplayH
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0
    if (x > SSOK_StampDisplayW)
        x := SSOK_StampDisplayW
    if (y > SSOK_StampDisplayH)
        y := SSOK_StampDisplayH
    return true
}

SSOK_StampGetPicClientPos(ByRef picX, ByRef picY)
{
    GuiControlGet, picPos, Stamp:Pos, SSOK_StampPic
    if (picPosW = "")
        return false
    picX := picPosX
    picY := picPosY
    return true
}
SSOK_StampMovePreviewControl(ctrl, x, y, w, h)
{
    if (w < 1)
        w := 1
    if (h < 1)
        h := 1
    GuiControl, Stamp:MoveDraw, %ctrl%, x%x% y%y% w%w% h%h%
    GuiControl, Stamp:Show, %ctrl%
    return true
}

SSOK_StampHidePreviewLines(redraw := true)
{
    global SSOK_StampGuiHwnd
    GuiControl, Stamp:Hide, SSOK_StampPreviewLineT
    GuiControl, Stamp:Hide, SSOK_StampPreviewLineB
    GuiControl, Stamp:Hide, SSOK_StampPreviewLineL
    GuiControl, Stamp:Hide, SSOK_StampPreviewLineR
    GuiControl, Stamp:Hide, SSOK_StampPreviewDot
    SSOK_StampHidePreviewSegments()
    if (redraw && SSOK_StampGuiHwnd != "")
        DllCall("RedrawWindow", "Ptr", SSOK_StampGuiHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0101)
    return true
}

SSOK_StampHidePreviewSegments()
{
    Loop, 32
    {
        ctrl := "SSOK_StampPreviewSeg" . A_Index
        GuiControl, Stamp:Hide, %ctrl%
    }
    return true
}

SSOK_StampMovePreviewSegmentLine(x1, y1, x2, y2, ByRef idx, count := 12, size := 4)
{
    if (count < 1)
        count := 1
    Loop, %count%
    {
        if (idx > 32)
            return false
        ratio := (count = 1) ? 0 : ((A_Index - 1) / (count - 1))
        x := Round(x1 + (x2 - x1) * ratio - size / 2)
        y := Round(y1 + (y2 - y1) * ratio - size / 2)
        ctrl := "SSOK_StampPreviewSeg" . idx
        SSOK_StampMovePreviewControl(ctrl, x, y, size, size)
        idx++
    }
    return true
}

SSOK_StampShowPlacementPreview(ctrlX, ctrlY)
{
    if (!SSOK_StampGetPicClientPos(picX, picY))
        return false
    if (!SSOK_StampGetPlacementPreviewRect(ctrlX, ctrlY, rx, ry, rw, rh))
        return false
    return SSOK_StampMovePreviewBox(picX + rx, picY + ry, rw, rh)
}

SSOK_StampMovePreviewBox(x, y, w, h)
{
    SSOK_StampHidePreviewLines(true)
    t := 3
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineT", x, y, w, t)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineB", x, y + h - t, w, t)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineL", x, y, t, h)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineR", x + w - t, y, t, h)
    return true
}

SSOK_StampGetPlacementPreviewRect(ctrlX, ctrlY, ByRef rx, ByRef ry, ByRef rw, ByRef rh)
{
    global SSOK_StampTool, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDisplayW, SSOK_StampDisplayH
    global SSOK_StampTextInput
    if (SSOK_StampImageW < 1 || SSOK_StampImageH < 1 || SSOK_StampDisplayW < 1 || SSOK_StampDisplayH < 1)
        return false
    SSOK_StampClampPicPoint(ctrlX, ctrlY)
    if (SSOK_StampTool = "number")
    {
        sizeImg := SSOK_CalcStampSize(SSOK_StampImageW, SSOK_StampImageH)
        rw := Round(sizeImg * SSOK_StampDisplayW / SSOK_StampImageW)
        rh := Round(sizeImg * SSOK_StampDisplayH / SSOK_StampImageH)
        rx := Round(ctrlX - rw / 2)
        ry := Round(ctrlY - rh / 2)
    }
    else if (SSOK_StampTool = "emoji")
    {
        boxImg := Round(SSOK_CalcEmojiSize() * 1.25)
        rw := Round(boxImg * SSOK_StampDisplayW / SSOK_StampImageW)
        rh := Round(boxImg * SSOK_StampDisplayH / SSOK_StampImageH)
        rx := Round(ctrlX - rw / 2)
        ry := Round(ctrlY - rh / 2)
    }
    else if (SSOK_StampTool = "text")
    {
        Gui, Stamp:Submit, NoHide
        txt := Trim(SSOK_StampTextInput, " `t`r`n")
        if (txt = "")
            return false
        if (!SSOK_StampCtrlToImage(ctrlX, ctrlY, imgX, imgY))
            return false
        fontSize := SSOK_GetTextBoxFontSize()
        tw := SSOK_EstimateTextWidth(txt, fontSize) + 12
        th := Round(fontSize * 1.65)
        if (tw < 30)
            tw := 30
        if (th < 22)
            th := 22
        ix := Round(imgX)
        iy := Round(imgY - th / 2 + th * 0.15)
        if (ix + tw > SSOK_StampImageW)
            ix := SSOK_StampImageW - tw
        if (iy + th > SSOK_StampImageH)
            iy := SSOK_StampImageH - th
        if (ix < 0)
            ix := 0
        if (iy < 0)
            iy := 0
        rw := Round(tw * SSOK_StampDisplayW / SSOK_StampImageW)
        rh := Round(th * SSOK_StampDisplayH / SSOK_StampImageH)
        rx := Round(ix * SSOK_StampDisplayW / SSOK_StampImageW)
        ry := Round(iy * SSOK_StampDisplayH / SSOK_StampImageH)
    }
    else
        return false
    if (rw < 8)
        rw := 8
    if (rh < 8)
        rh := 8
    if (rx < 0)
        rx := 0
    if (ry < 0)
        ry := 0
    if (rx + rw > SSOK_StampDisplayW)
        rx := SSOK_StampDisplayW - rw
    if (ry + rh > SSOK_StampDisplayH)
        ry := SSOK_StampDisplayH - rh
    if (rx < 0)
        rx := 0
    if (ry < 0)
        ry := 0
    return true
}
SSOK_StampShowLivePreview(startCtrlX, startCtrlY, endCtrlX, endCtrlY)
{
    global SSOK_StampTool
    if (!SSOK_StampGetPicClientPos(picX, picY))
        return false

    if (SSOK_StampTool = "arrow")
    {
        SSOK_StampHidePreviewLines(true)
        sx := picX + startCtrlX
        sy := picY + startCtrlY
        ex := picX + endCtrlX
        ey := picY + endCtrlY
        dx := ex - sx
        dy := ey - sy
        len := Sqrt(dx * dx + dy * dy)
        idx := 1
        if (len < 4)
        {
            SSOK_StampMovePreviewControl("SSOK_StampPreviewSeg1", ex - 3, ey - 3, 6, 6)
            return true
        }
        ux := dx / len
        uy := dy / len
        head := 18
        if (head > len * 0.55)
            head := Round(len * 0.55)
        if (head < 8)
            head := 8
        baseX := ex - ux * head
        baseY := ey - uy * head
        halfHead := head * 0.45
        px := -uy
        py := ux
        leftX := baseX + px * halfHead
        leftY := baseY + py * halfHead
        rightX := baseX - px * halfHead
        rightY := baseY - py * halfHead
        SSOK_StampMovePreviewSegmentLine(sx, sy, baseX, baseY, idx, 18, 4)
        SSOK_StampMovePreviewSegmentLine(ex, ey, leftX, leftY, idx, 7, 4)
        SSOK_StampMovePreviewSegmentLine(ex, ey, rightX, rightY, idx, 7, 4)
        return true
    }

    SSOK_StampHidePreviewLines(true)
    SSOK_NormalizeRect(startCtrlX, startCtrlY, endCtrlX, endCtrlY, cx, cy, cw, ch)
    if (cw < 1)
        cw := 1
    if (ch < 1)
        ch := 1
    t := 3
    x := picX + cx
    y := picY + cy
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineT", x, y, cw, t)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineB", x, y + ch - t, cw, t)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineL", x, y, t, ch)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineR", x + cw - t, y, t, ch)
    return true
}
SSOK_StampDrawPreviewShape(pBitmap, tool, x1, y1, x2, y2)
{
    global SSOK_StampMainColor
    if (!pBitmap)
        return false
    g := Gdip_GraphicsFromImage(pBitmap)
    if (!g)
        return false
    Gdip_SetSmoothingMode(g, 4)
    if (tool = "rect")
    {
        SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
        pen := Gdip_PenCreate(SSOK_GetStampColorARGB(SSOK_StampMainColor), SSOK_GetStampLineWidth())
        Gdip_DrawRectangle(g, pen, rx, ry, rw, rh)
        Gdip_DeletePen(pen)
    }
    else if (tool = "arrow")
    {
        SSOK_DrawArrowOnGraphics(g, x1, y1, x2, y2, SSOK_GetStampColorARGB(SSOK_StampMainColor), SSOK_GetStampLineWidth())
    }
    else if (tool = "highlight")
    {
        SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
        SSOK_AdjustHighlightRect(rx, ry, rw, rh)
        brush := Gdip_BrushCreateSolid(SSOK_GetHighlightColorARGB())
        Gdip_FillRectangle(g, brush, rx, ry, rw, rh)
        Gdip_DeleteBrush(brush)
    }
    else if (tool = "mosaic")
    {
        ; ¸ðÀÚÀÌÅ©´Â µå·¡±× Áß ½ÇÁ¦ Ã³¸® ´ë½Å ¹üÀ§¸¸ ¹Ì¸® Ç¥½ÃÇÕ´Ï´Ù.
        SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
        brush := Gdip_BrushCreateSolid(0x33000000)
        Gdip_FillRectangle(g, brush, rx, ry, rw, rh)
        Gdip_DeleteBrush(brush)
        pen := Gdip_PenCreate(SSOK_GetStampColorARGB(SSOK_StampMainColor), 2)
        Gdip_DrawRectangle(g, pen, rx, ry, rw, rh)
        Gdip_DeletePen(pen)
    }
    Gdip_DeleteGraphics(g)
    return true
}

SSOK_DrawArrowOnGraphics(g, x1, y1, x2, y2, argb := "", width := 5)
{
    global SSOK_StampMainColor
    if (argb = "")
        argb := SSOK_GetStampColorARGB(SSOK_StampMainColor)
    if (width < 1)
        width := 5

    ; È­»ìÇ¥ ³¡Á¡ º¸Á¤:
    ; ±âÁ¸ ¹æ½ÄÀº ¼±À» ³¡Á¡±îÁö ±×¸° µÚ ¸Ó¸®¼± 2°³¸¦ µ¡±×·Á¼­
    ; µÎ²¨¿î ¼±¿¡¼­´Â ³¡ÀÌ µÐÇÏ°Ô º¸ÀÌ°Å³ª ¸¶¿ì½º ³¡Á¡°ú »ìÂ¦ ¾î±ß³ª º¸¿´½À´Ï´Ù.
    ; ÀÌÁ¦´Â ¸öÅë¼±À» È­»ìÇ¥ ¸Ó¸®ÀÇ ±âÁØÁ¡±îÁö¸¸ ±×¸®°í,
    ; ½ÇÁ¦ ³¡Á¡(x2, y2)À» ²ÀÁþÁ¡À¸·Î ÇÏ´Â »ï°¢Çü ¸Ó¸®¸¦ Ã¤¿ö¼­ ³¡ÀÌ Á¤È®È÷ ¸Â°Ô ÇÕ´Ï´Ù.
    dx := x2 - x1
    dy := y2 - y1
    len := Sqrt(dx*dx + dy*dy)
    if (len < 8)
        return false

    ux := dx / len
    uy := dy / len
    head := Round(width * 5.2)
    if (head < 14)
        head := 14
    if (head > 34)
        head := 34
    if (head > len * 0.55)
        head := Round(len * 0.55)
    if (head < 8)
        head := 8

    baseX := x2 - ux * head
    baseY := y2 - uy * head
    halfHead := head * 0.45
    px := -uy
    py := ux

    leftX := baseX + px * halfHead
    leftY := baseY + py * halfHead
    rightX := baseX - px * halfHead
    rightY := baseY - py * halfHead

    pen := Gdip_PenCreate(argb, width)
    ; ¸öÅëÀº ¸Ó¸®ÀÇ ±âÁØÁ¡±îÁö¸¸ ±×·Á¼­ È­»ìÇ¥ ³¡ÀÌ ¸¶¿ì½º ³¡Á¡ ¹ÛÀ¸·Î Æ¢Áö ¾Ê°Ô ÇÕ´Ï´Ù.
    Gdip_DrawLine(g, pen, x1, y1, baseX, baseY)
    Gdip_DeletePen(pen)

    brush := Gdip_BrushCreateSolid(argb)
    Gdip_FillPolygon(g, brush, x2, y2, leftX, leftY, rightX, rightY)
    Gdip_DeleteBrush(brush)
    return true
}

SSOK_Stamp_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd, SSOK_StampDisplayW, SSOK_StampDisplayH
    global SSOK_StampDragging, SSOK_StampDragStartX, SSOK_StampDragStartY, SSOK_StampTool, SSOK_StampTextEditing, SSOK_StampTextInput
    global SSOK_StampPreviewLastTick, SSOK_StampPreviewLastX, SSOK_StampPreviewLastY
    if (SSOK_StampGuiHwnd = "")
        return
    ; SetCapture »óÅÂ¿¡¼­´Â Àü´Þ hwnd°¡ ±×¸² ¿µ¿ªÀ¸·Î ³²À» ¼ö ÀÖÀ¸¹Ç·Î,
    ; ½ÇÁ¦ ¸¶¿ì½º ¾Æ·¡ ÄÁÆ®·Ñ hwndµµ ÇÔ²² È®ÀÎÇØ¼­ ÇÏ´Ü µå·Ó´Ù¿î Å¬¸¯À» »ì¸³´Ï´Ù.
    MouseGetPos, , , , _stampHitHwnd, 2
    if (SSOK_StampPrepareOptionDropdownClick(hwnd) || SSOK_StampPrepareOptionDropdownClick(_stampHitHwnd))
        return
    if (hwnd != SSOK_StampPicHwnd)
        return
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    ; Å¬¸¯ ½ÃÀÛÁ¡Àº Picture ÄÁÆ®·ÑÀÌ ³Ñ°ÜÁØ ³»ºÎ ÁÂÇ¥¸¦ ±×´ë·Î »ç¿ëÇÕ´Ï´Ù.
    ; È­¸é ÁÂÇ¥ º¸Á¤°ªÀÌ Èçµé¸®¸é ½ÃÀÛÁ¡ÀÌ ÀÌ¹ÌÁö ¿ÞÂÊ ³¡À¸·Î ¹Ð¸± ¼ö ÀÖ½À´Ï´Ù.
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    if (x < 0 || y < 0 || x > SSOK_StampDisplayW || y > SSOK_StampDisplayH)
        return 0

    if (SSOK_StampTool = "none")
        return 0
    if (SSOK_StampTool = "text")
    {
        Gui, Stamp:Submit, NoHide
        if (Trim(SSOK_StampTextInput, " `t`r`n") = "")
        {
            GuiControl, Stamp:Focus, SSOK_StampTextInput
            SSOK_ShowToolTip("»ó´Ü ±Û»óÀÚ ÀÔ·ÂÄ­¿¡ ³»¿ëÀ» ¸ÕÀú ÀÔ·ÂÇÏ¼¼¿ä.")
            return 0
        }
    }

    SSOK_StampClearLivePreview()
    SSOK_StampDragging := true
    SSOK_StampDragStartX := x
    SSOK_StampDragStartY := y
    SSOK_StampPreviewLastTick := 0
    SSOK_StampPreviewLastX := ""
    SSOK_StampPreviewLastY := ""
    DllCall("SetCapture", "Ptr", SSOK_StampPicHwnd)
    if (SSOK_StampTool = "number")
        SSOK_StampShowPlacementPreview(x, y)
    else if (SSOK_StampIsMaskPresetTool(SSOK_StampTool))
        SSOK_StampShowMaskPresetPreview(x, y)
    else if (SSOK_StampTool = "text" || SSOK_StampTool = "emoji")
        SSOK_StampShowLivePreview(x, y, x, y)
    SetTimer, SSOK_StampDragPreviewTimer, 16
    return 0
}

SSOK_Stamp_WM_LBUTTONUP(wParam, lParam, msg, hwnd)
{
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd
    global SSOK_StampDragging, SSOK_StampDragStartX, SSOK_StampDragStartY, SSOK_StampTool, SSOK_StampSuppressPicClickUntil
    if (SSOK_StampGuiHwnd = "" || SSOK_StampPicHwnd = "")
        return

    ; ±×¸² ÆíÁý µå·¡±× ÁßÀÌ ¾Æ´Ò ¶§´Â Å¬¸¯À» Àý´ë °¡·ÎÃ¤Áö ¾Ê½À´Ï´Ù.
    ; ÀÌ return 0 ÇÏ³ª ¶§¹®¿¡ ÇÏ´Ü »ö»ó/Å©±â/ÀÌ¸ðÆ¼ÄÜ µå·Ó´Ù¿îÀÇ ¸¶¿ì½º ¼±ÅÃÀÌ ¸·Èú ¼ö ÀÖ½À´Ï´Ù.
    if (!SSOK_StampDragging)
        return

    CoordMode, Mouse, Screen
    MouseGetPos, sx, sy
    if (!SSOK_StampScreenToPicClient(sx, sy, x, y))
    {
        SSOK_StampDragging := false
        SetTimer, SSOK_StampDragPreviewTimer, Off
        DllCall("ReleaseCapture")
        SSOK_StampClearLivePreview()
        return 0
    }
    SSOK_StampClampPicPoint(x, y)

    SSOK_StampDragging := false
    SetTimer, SSOK_StampDragPreviewTimer, Off
    DllCall("ReleaseCapture")
    SSOK_StampClearLivePreview()
    SSOK_StampSuppressPicClickUntil := A_TickCount + 200
    if (SSOK_StampTool = "number")
        SSOK_StampHandleClick(x, y)
    else if (SSOK_StampIsMaskPresetTool(SSOK_StampTool))
        SSOK_StampHandleMaskPresetClick(x, y)
    else if (SSOK_StampTool = "text")
    {
        SSOK_StampHandleTextDrag(SSOK_StampDragStartX, SSOK_StampDragStartY, x, y)
    }
    else if (SSOK_StampTool = "emoji")
        SSOK_StampHandleEmojiDrag(SSOK_StampDragStartX, SSOK_StampDragStartY, x, y)
    else
        SSOK_StampHandleDrag(SSOK_StampDragStartX, SSOK_StampDragStartY, x, y)
    return 0
}

SSOK_StampClearLivePreview()
{
    global SSOK_StampPreviewTempFile, SSOK_StampPreviewLastX, SSOK_StampPreviewLastY
    SetTimer, SSOK_StampDragPreviewTimer, Off
    SSOK_StampHidePreviewLines(true)
    SSOK_StampPreviewLastX := ""
    SSOK_StampPreviewLastY := ""
    if (SSOK_StampPreviewTempFile != "")
    {
        FileDelete, %SSOK_StampPreviewTempFile%
        SSOK_StampPreviewTempFile := ""
    }
    return true
}
SSOK_StampHandleClick(ctrlX, ctrlY)
{
    global SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDisplayW, SSOK_StampDisplayH, SSOK_StampLastClickTick
    nowTick := A_TickCount
    if (SSOK_StampLastClickTick > 0 && nowTick - SSOK_StampLastClickTick < 70)
        return false
    SSOK_StampLastClickTick := nowTick
    if (!SSOK_StampCtrlToImage(ctrlX, ctrlY, imgX, imgY))
        return false
    return SSOK_DrawStampOnCurrentBitmap(imgX, imgY)
}

SSOK_StampHandleDrag(startCtrlX, startCtrlY, endCtrlX, endCtrlY)
{
    global SSOK_StampTool
    if (SSOK_StampTool = "text")
        return false

    if (!SSOK_StampCtrlToImage(startCtrlX, startCtrlY, x1, y1))
        return false
    if (!SSOK_StampCtrlToImage(endCtrlX, endCtrlY, x2, y2))
        return false

    dx := Abs(x2 - x1)
    dy := Abs(y2 - y1)
    if (dx < 4 && dy < 4)
        return false
    if (SSOK_StampTool = "rect")
        return SSOK_DrawRectangleOnCurrentBitmap(x1, y1, x2, y2)
    if (SSOK_StampTool = "arrow")
        return SSOK_DrawArrowOnCurrentBitmap(x1, y1, x2, y2)
    if (SSOK_StampTool = "highlight")
        return SSOK_DrawHighlightOnCurrentBitmap(x1, y1, x2, y2)
    if (SSOK_StampTool = "mosaic")
        return SSOK_DrawMosaicOnCurrentBitmap(x1, y1, x2, y2)
    return false
}

SSOK_StampCtrlToImage(ctrlX, ctrlY, ByRef imgX, ByRef imgY)
{
    global SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDisplayW, SSOK_StampDisplayH
    if (SSOK_StampDisplayW < 1 || SSOK_StampDisplayH < 1)
        return false
    if (ctrlX < 0)
        ctrlX := 0
    if (ctrlY < 0)
        ctrlY := 0
    if (ctrlX > SSOK_StampDisplayW)
        ctrlX := SSOK_StampDisplayW
    if (ctrlY > SSOK_StampDisplayH)
        ctrlY := SSOK_StampDisplayH
    imgX := Round(ctrlX * SSOK_StampImageW / SSOK_StampDisplayW)
    imgY := Round(ctrlY * SSOK_StampImageH / SSOK_StampDisplayH)
    if (imgX < 0)
        imgX := 0
    if (imgY < 0)
        imgY := 0
    if (imgX > SSOK_StampImageW)
        imgX := SSOK_StampImageW
    if (imgY > SSOK_StampImageH)
        imgY := SSOK_StampImageH
    return true
}

SSOK_DrawStampOnCurrentBitmap(imgX, imgY)
{
    global SSOK_StampBitmap, SSOK_StampNo, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDirty, SSOK_StampMainColor
    if (!SSOK_StampBitmap)
        return false
    size := SSOK_CalcStampSize(SSOK_StampImageW, SSOK_StampImageH)
    x := imgX - Round(size / 2)
    y := imgY - Round(size / 2)
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0
    if (x + size > SSOK_StampImageW)
        x := SSOK_StampImageW - size
    if (y + size > SSOK_StampImageH)
        y := SSOK_StampImageH - size
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0

    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    Gdip_SetSmoothingMode(g, 4)
    Gdip_SetTextRenderingHint(g, 4)
    fillColor := SSOK_GetStampColorARGB(SSOK_StampMainColor)
    brush := Gdip_BrushCreateSolid(fillColor)
    pen := Gdip_PenCreate(0xFFFFFFFF, (size * 0.08 < 3) ? 3 : Round(size * 0.08))
    Gdip_FillEllipse(g, brush, x, y, size, size)
    Gdip_DrawEllipse(g, pen, x, y, size, size)
    num := SSOK_StampNo
    if (num >= 100)
        fontSize := Round(size * 0.35)
    else if (num >= 10)
        fontSize := Round(size * 0.42)
    else
        fontSize := Round(size * 0.52)
    textColor := SSOK_GetStampTextColorARGB(SSOK_StampMainColor)
    ; Arial ¼ýÀÚ´Â GDI+ ¼¼·Î Áß¾Ó Á¤·ÄÀ» ½áµµ ½Ã°¢ÀûÀ¸·Î ¾à°£ À§·Î ¶° º¸ÀÔ´Ï´Ù.
    ; ¿ø ¾ÈÀÇ ½ÇÁ¦ ½Ã°¢ Áß½É¿¡ ¸Âµµ·Ï ¼ýÀÚ À§Ä¡¸¦ Á¶±Ý ¾Æ·¡·Î º¸Á¤ÇÕ´Ï´Ù.
    textYOffset := Round(size * 0.045)
    SSOK_GdipDrawCenteredText(g, num, x, y + textYOffset, size, size, "Arial", fontSize, textColor)
    Gdip_DeletePen(pen)
    Gdip_DeleteBrush(brush)
    Gdip_DeleteGraphics(g)

    SSOK_StampNo := num + 1
    Gosub, SSOK_SaveState
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    return true
}

SSOK_StampIsMaskPresetTool(tool)
{
    return (tool = "mask_rrn" || tool = "mask_phone" || tool = "mask_name")
}

SSOK_StampGetMaskPresetDisplaySize(tool, ByRef w, ByRef h)
{
    ; °íÁ¤ Å©±â ÇÁ¸®¼ÂÀº ÆíÁý È­¸é¿¡¼­ º¸ÀÌ´Â Å©±â¸¦ ±âÁØÀ¸·Î Àâ°í,
    ; ½ÇÁ¦ ÀúÀå ÀÌ¹ÌÁö´Â ÇöÀç ¹Ì¸®º¸±â ¹èÀ²¿¡ ¸ÂÃç ÀÚµ¿ È¯»êÇÕ´Ï´Ù.
    if (tool = "mask_phone")
    {
        w := 130
        h := 24
    }
    else if (tool = "mask_name")
    {
        w := 56
        h := 24
    }
    else
    {
        ; ÁÖ¹Îµî·Ï¹øÈ£ µÞÀÚ¸® 7ÀÚ¸®¿Í ÇÏÀÌÇÂ µÚ ¿µ¿ªÀ» °¡¸± ¶§ ¾²´Â ±âº»°ªÀÔ´Ï´Ù.
        w := 110
        h := 24
    }
    return true
}

SSOK_StampShowMaskPresetPreview(ctrlX, ctrlY)
{
    global SSOK_StampTool, SSOK_StampDisplayW, SSOK_StampDisplayH
    if (!SSOK_StampGetPicClientPos(picX, picY))
        return false
    SSOK_StampGetMaskPresetDisplaySize(SSOK_StampTool, boxW, boxH)
    if (boxW > SSOK_StampDisplayW)
        boxW := SSOK_StampDisplayW
    if (boxH > SSOK_StampDisplayH)
        boxH := SSOK_StampDisplayH
    x := ctrlX - Round(boxW / 2)
    y := ctrlY - Round(boxH / 2)
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0
    if (x + boxW > SSOK_StampDisplayW)
        x := SSOK_StampDisplayW - boxW
    if (y + boxH > SSOK_StampDisplayH)
        y := SSOK_StampDisplayH - boxH
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0

    SSOK_StampHidePreviewLines(false)
    t := 3
    drawX := picX + x
    drawY := picY + y
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineT", drawX, drawY, boxW, t)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineB", drawX, drawY + boxH - t, boxW, t)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineL", drawX, drawY, t, boxH)
    SSOK_StampMovePreviewControl("SSOK_StampPreviewLineR", drawX + boxW - t, drawY, t, boxH)
    return true
}

SSOK_StampHandleMaskPresetClick(ctrlX, ctrlY)
{
    global SSOK_StampLastClickTick, SSOK_StampTool
    nowTick := A_TickCount
    if (SSOK_StampLastClickTick > 0 && nowTick - SSOK_StampLastClickTick < 70)
        return false
    SSOK_StampLastClickTick := nowTick
    if (!SSOK_StampCtrlToImage(ctrlX, ctrlY, imgX, imgY))
        return false
    return SSOK_DrawMaskPresetOnCurrentBitmap(imgX, imgY, SSOK_StampTool)
}

SSOK_DrawMaskPresetOnCurrentBitmap(imgX, imgY, tool)
{
    global SSOK_StampBitmap, SSOK_StampDirty, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDisplayW, SSOK_StampDisplayH
    if (!SSOK_StampBitmap)
        return false
    if (SSOK_StampDisplayW < 1 || SSOK_StampDisplayH < 1 || SSOK_StampImageW < 1 || SSOK_StampImageH < 1)
        return false
    SSOK_StampGetMaskPresetDisplaySize(tool, displayW, displayH)
    w := Round(displayW * SSOK_StampImageW / SSOK_StampDisplayW)
    h := Round(displayH * SSOK_StampImageH / SSOK_StampDisplayH)
    if (w < 4)
        w := 4
    if (h < 4)
        h := 4
    if (w > SSOK_StampImageW)
        w := SSOK_StampImageW
    if (h > SSOK_StampImageH)
        h := SSOK_StampImageH
    x := imgX - Round(w / 2)
    y := imgY - Round(h / 2)
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0
    if (x + w > SSOK_StampImageW)
        x := SSOK_StampImageW - w
    if (y + h > SSOK_StampImageH)
        y := SSOK_StampImageH - h
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0

    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    if (!g)
        return false
    brush := Gdip_BrushCreateSolid(0xFF000000)
    Gdip_FillRectangle(g, brush, x, y, w, h)
    Gdip_DeleteBrush(brush)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    return true
}
SSOK_DrawRectangleOnCurrentBitmap(x1, y1, x2, y2)
{
    global SSOK_StampBitmap, SSOK_StampDirty, SSOK_StampMainColor
    SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
    if (rw < 4 || rh < 4)
        return false
    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    Gdip_SetSmoothingMode(g, 4)
    pen := Gdip_PenCreate(SSOK_GetStampColorARGB(SSOK_StampMainColor), SSOK_GetStampLineWidth())
    Gdip_DrawRectangle(g, pen, rx, ry, rw, rh)
    Gdip_DeletePen(pen)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    return true
}

SSOK_DrawOuterBorderOnCurrentBitmap()
{
    global SSOK_StampBitmap, SSOK_StampDirty, SSOK_StampMainColor, SSOK_StampImageW, SSOK_StampImageH
    if (!SSOK_StampBitmap)
        return false
    if (SSOK_StampImageW < 2 || SSOK_StampImageH < 2)
        return false
    if (!SSOK_StampBeginEdit())
        return false

    lineW := SSOK_GetStampLineWidth()
    if (lineW < 1)
        lineW := 1
    inset := Floor(lineW / 2)
    rectW := SSOK_StampImageW - lineW
    rectH := SSOK_StampImageH - lineW
    if (rectW < 1)
        rectW := SSOK_StampImageW - 1
    if (rectH < 1)
        rectH := SSOK_StampImageH - 1

    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    if (!g)
        return false
    Gdip_SetSmoothingMode(g, 4)
    pen := Gdip_PenCreate(SSOK_GetStampColorARGB(SSOK_StampMainColor), lineW)
    Gdip_DrawRectangle(g, pen, inset, inset, rectW, rectH)
    Gdip_DeletePen(pen)
    Gdip_DeleteGraphics(g)

    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    return true
}

SSOK_DrawHighlightOnCurrentBitmap(x1, y1, x2, y2)
{
    global SSOK_StampBitmap, SSOK_StampDirty, SSOK_StampMainColor
    SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
    if (rw < 4 || rh < 4)
        return false
    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    SSOK_AdjustHighlightRect(rx, ry, rw, rh)
    brush := Gdip_BrushCreateSolid(SSOK_GetHighlightColorARGB())
    Gdip_FillRectangle(g, brush, rx, ry, rw, rh)
    Gdip_DeleteBrush(brush)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    return true
}

SSOK_DrawArrowOnCurrentBitmap(x1, y1, x2, y2)
{
    global SSOK_StampBitmap, SSOK_StampDirty, SSOK_StampMainColor
    dx := x2 - x1
    dy := y2 - y1
    len := Sqrt(dx*dx + dy*dy)
    if (len < 8)
        return false
    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    Gdip_SetSmoothingMode(g, 4)
    SSOK_DrawArrowOnGraphics(g, x1, y1, x2, y2, SSOK_GetStampColorARGB(SSOK_StampMainColor), SSOK_GetStampLineWidth())
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    return true
}

SSOK_StampHandleTextClick(ctrlX, ctrlY)
{
    global SSOK_StampTextInput, SSOK_StampTextInputHwnd
    Gui, Stamp:Submit, NoHide
    txt := Trim(SSOK_StampTextInput, " `t`r`n")
    if (txt = "")
    {
        GuiControl, Stamp:Focus, SSOK_StampTextInput
        SSOK_ShowToolTip("»ó´Ü ±Û»óÀÚ ÀÔ·ÂÄ­¿¡ ³»¿ëÀ» ¸ÕÀú ÀÔ·ÂÇÏ¼¼¿ä.")
        return false
    }
    if (!SSOK_StampCtrlToImage(ctrlX, ctrlY, imgX, imgY))
        return false
    return SSOK_DrawPlainTextOnCurrentBitmap(imgX, imgY, txt)
}

SSOK_StampHandleTextDrag(startCtrlX, startCtrlY, endCtrlX, endCtrlY)
{
    global SSOK_StampTextInput
    Gui, Stamp:Submit, NoHide
    txt := Trim(SSOK_StampTextInput, " `t`r`n")
    if (txt = "")
    {
        GuiControl, Stamp:Focus, SSOK_StampTextInput
        SSOK_ShowToolTip("»ó´Ü ±Û»óÀÚ ÀÔ·ÂÄ­¿¡ ³»¿ëÀ» ¸ÕÀú ÀÔ·ÂÇÏ¼¼¿ä.")
        return false
    }
    if (!SSOK_StampCtrlToImage(startCtrlX, startCtrlY, x1, y1))
        return false
    if (!SSOK_StampCtrlToImage(endCtrlX, endCtrlY, x2, y2))
        return false
    if (Abs(x2 - x1) < 8 && Abs(y2 - y1) < 8)
        return SSOK_DrawPlainTextOnCurrentBitmap(x2, y2, txt)
    return SSOK_DrawTextBoxOnCurrentBitmap(x1, y1, x2, y2, txt)
}

SSOK_DrawPlainTextOnCurrentBitmap(x, y, txt, trackLast := true)
{
    global SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDirty, SSOK_StampMainColor, SSOK_StampSizeLevel
    global SSOK_StampLastTextMeta, SSOK_StampUndoStack
    txt := Trim(txt, " `t`r`n")
    if (txt = "" || !SSOK_StampBitmap)
        return false
    anchorX := x
    anchorY := y
    fontSize := SSOK_GetTextBoxFontSize()
    tw := SSOK_EstimateTextWidth(txt, fontSize) + 12
    th := Round(fontSize * 1.65)
    if (tw < 30)
        tw := 30
    if (th < 22)
        th := 22
    ; °¡·Î À§Ä¡´Â Å¬¸¯ÇÑ ÁöÁ¡¿¡¼­ ¹Ù·Î ±ÛÀÚ°¡ ½ÃÀÛµÇ°Ô ÇÏ°í,
    ; ¼¼·Î À§Ä¡´Â ±âÁ¸Ã³·³ ±ÛÀÚ ³ôÀÌÀÇ ¾à 15%¸¸ ¾Æ·¡·Î ³»·Á ÀÚ¿¬½º·´°Ô ¸ÂÃä´Ï´Ù.
    x := Round(x)
    y := Round(y - th / 2 + th * 0.15)
    if (x + tw > SSOK_StampImageW)
        x := SSOK_StampImageW - tw
    if (y + th > SSOK_StampImageH)
        y := SSOK_StampImageH - th
    if (x < 0)
        x := 0
    if (y < 0)
        y := 0
    textColor := SSOK_GetStampColorARGB(SSOK_StampMainColor)
    if (SSOK_StampMainColor = "³ë¶û")
        textColor := 0xFF000000
    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    Gdip_SetSmoothingMode(g, 4)
    Gdip_SetTextRenderingHint(g, 4)
    SSOK_GdipDrawText(g, txt, x, y, tw, th, "Malgun Gothic", fontSize, textColor, 1, 0, 0)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    if (trackLast)
    {
        if (!IsObject(SSOK_StampUndoStack))
            SSOK_StampUndoStack := []
        SSOK_StampLastTextMeta := {x:anchorX, y:anchorY, text:txt, size:SSOK_StampSizeLevel, color:SSOK_StampMainColor, undoLen:SSOK_StampUndoStack.Length()}
    }
    return true
}

SSOK_StampRefreshLastTextForOptions()
{
    global SSOK_StampLastTextMeta, SSOK_StampTool, SSOK_StampSizeLevel, SSOK_StampMainColor, SSOK_StampUndoStack
    global SSOK_StampBitmap, SSOK_StampNo, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampTextEditing
    if (SSOK_StampTextEditing || SSOK_StampTool != "text" || !IsObject(SSOK_StampLastTextMeta))
        return false
    if (SSOK_StampLastTextMeta.size = SSOK_StampSizeLevel && SSOK_StampLastTextMeta.color = SSOK_StampMainColor)
        return false
    if (!IsObject(SSOK_StampUndoStack) || SSOK_StampUndoStack.Length() != SSOK_StampLastTextMeta.undoLen)
        return false

    anchorX := SSOK_StampLastTextMeta.x
    anchorY := SSOK_StampLastTextMeta.y
    txt := SSOK_StampLastTextMeta.text
    prev := SSOK_StampUndoStack.Pop()
    if (SSOK_StampBitmap)
        Gdip_DisposeImage(SSOK_StampBitmap)
    if (IsObject(prev))
    {
        SSOK_StampBitmap := prev.bitmap
        SSOK_StampNo := prev.stampNo
    }
    else
        SSOK_StampBitmap := prev
    Gdip_GetImageDimensions(SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH)
    return SSOK_DrawPlainTextOnCurrentBitmap(anchorX, anchorY, txt, true)
}

SSOK_EstimateTextWidth(txt, fontSize)
{
    width := 0
    Loop, Parse, txt
    {
        ch := A_LoopField
        code := Asc(ch)
        if (ch = " ")
            width += fontSize * 0.45
        else if (code > 127)
            width += fontSize * 1.05
        else
            width += fontSize * 0.62
    }
    return Round(width)
}

SSOK_StartInlineTextBoxOnStamp(startCtrlX, startCtrlY, endCtrlX, endCtrlY)
{
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd, SSOK_StampTextEditHwnd, SSOK_StampInlineText, SSOK_StampTextEditing
    global SSOK_StampTextImgX1, SSOK_StampTextImgY1, SSOK_StampTextImgX2, SSOK_StampTextImgY2
    global SSOK_StampDisplayW, SSOK_StampDisplayH

    SSOK_CancelInlineTextBox(false)

    SSOK_NormalizeRect(startCtrlX, startCtrlY, endCtrlX, endCtrlY, cx, cy, cw, ch)
    minH := SSOK_GetTextBoxDefaultHeight()
    if (cw < 80)
        cw := 260
    if (ch < minH)
        ch := minH
    if (cx + cw > SSOK_StampDisplayW)
        cw := SSOK_StampDisplayW - cx
    if (cy + ch > SSOK_StampDisplayH)
        ch := SSOK_StampDisplayH - cy
    if (cw < 80)
        cw := 80
    if (ch < 24)
        ch := 24

    if (!SSOK_StampCtrlToImage(cx, cy, ix1, iy1))
        return false
    if (!SSOK_StampCtrlToImage(cx + cw, cy + ch, ix2, iy2))
        return false
    SSOK_StampTextImgX1 := ix1
    SSOK_StampTextImgY1 := iy1
    SSOK_StampTextImgX2 := ix2
    SSOK_StampTextImgY2 := iy2

    WinGetPos, picSX, picSY,,, ahk_id %SSOK_StampPicHwnd%
    VarSetCapacity(_pt, 8, 0)
    NumPut(picSX, _pt, 0, "Int")
    NumPut(picSY, _pt, 4, "Int")
    DllCall("ScreenToClient", "Ptr", SSOK_StampGuiHwnd, "Ptr", &_pt)
    picX := NumGet(_pt, 0, "Int")
    picY := NumGet(_pt, 4, "Int")
    ex := picX + cx
    ey := picY + cy
    GuiControl, Stamp:, SSOK_StampInlineText,
    GuiControl, Stamp:Move, SSOK_StampInlineText, x%ex% y%ey% w%cw% h%ch%
    SSOK_StampInlineText := ""
    SSOK_StampTextEditing := true
    SSOK_StampUpdateInlineTextBoxStyle()
    GuiControl, Stamp:Show, SSOK_StampInlineText
    GuiControl, Stamp:Focus, SSOK_StampInlineText
    SSOK_StampUpdateInfo()
    return true
}

SSOK_StampUpdateInlineTextBoxStyle()
{
    global SSOK_StampGuiHwnd, SSOK_StampTextEditing, SSOK_StampMainColor
    if (SSOK_StampGuiHwnd = "" || !SSOK_StampTextEditing)
        return false
    fontSize := SSOK_GetTextBoxFontSize()
    if (fontSize < 8)
        fontSize := 8
    fontColor := SSOK_GetStampColorHex(SSOK_StampMainColor)
    if (SSOK_StampMainColor = "³ë¶û")
        fontColor := "000000"
    Gui, Stamp:Font, s%fontSize% c%fontColor%, ¸¼Àº °íµñ
    GuiControl, Stamp:Font, SSOK_StampInlineText
    GuiControl, Stamp:MoveDraw, SSOK_StampInlineText
    return true
}

SSOK_ApplyInlineTextBox()
{
    global SSOK_StampInlineText, SSOK_StampTextEditing, SSOK_StampTextImgX1, SSOK_StampTextImgY1, SSOK_StampTextImgX2, SSOK_StampTextImgY2
    Gui, Stamp:Submit, NoHide
    txt := Trim(SSOK_StampInlineText, " `t`r`n")
    GuiControl, Stamp:Hide, SSOK_StampInlineText
    SSOK_StampTextEditing := false
    if (txt = "")
    {
        SSOK_StampUpdateInfo()
        return false
    }
    return SSOK_DrawTextBoxOnCurrentBitmap(SSOK_StampTextImgX1, SSOK_StampTextImgY1, SSOK_StampTextImgX2, SSOK_StampTextImgY2, txt)
}

SSOK_CancelInlineTextBox(updateInfo := true)
{
    global SSOK_StampTextEditing, SSOK_StampInlineText, SSOK_StampGuiHwnd
    if (SSOK_StampGuiHwnd != "")
    {
        GuiControl, Stamp:Hide, SSOK_StampInlineText
        GuiControl, Stamp:, SSOK_StampInlineText,
    }
    SSOK_StampInlineText := ""
    SSOK_StampTextEditing := false
    if (updateInfo)
        SSOK_StampUpdateInfo()
    return true
}

SSOK_DrawTextBoxOnCurrentBitmap(x1, y1, x2, y2, txt := "")
{
    global SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDirty, SSOK_StampMainColor
    txt := Trim(txt, " `t`r`n")
    if (txt = "")
        return false
    SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
    if (rw < 30)
        rw := 260
    minH := SSOK_GetTextBoxDefaultHeight()
    if (rh < minH)
        rh := minH
    if (rx + rw > SSOK_StampImageW)
        rw := SSOK_StampImageW - rx
    if (ry + rh > SSOK_StampImageH)
        rh := SSOK_StampImageH - ry
    if (rw < 30 || rh < 20)
        return false

    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    Gdip_SetSmoothingMode(g, 4)
    Gdip_SetTextRenderingHint(g, 4)
    fontSize := SSOK_GetTextBoxFontSize()
    textColor := SSOK_GetStampColorARGB(SSOK_StampMainColor)
    if (SSOK_StampMainColor = "³ë¶û")
        textColor := 0xFF000000
    tw := SSOK_EstimateTextWidth(txt, fontSize) + 12
    if (tw < rw)
        rw := tw
    SSOK_GdipDrawText(g, txt, rx, ry, rw, rh, "Malgun Gothic", fontSize, textColor, 1, 0, 0)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    return true
}


SSOK_StampHandleEmojiClick(ctrlX, ctrlY)
{
    global SSOK_StampEmojiName
    Gui, Stamp:Submit, NoHide
    SSOK_NormalizeStampOptions()
    if (!SSOK_StampCtrlToImage(ctrlX, ctrlY, imgX, imgY))
        return false
    return SSOK_DrawEmojiOnCurrentBitmap(imgX, imgY, SSOK_StampEmojiName)
}

SSOK_StampHandleEmojiDrag(startCtrlX, startCtrlY, endCtrlX, endCtrlY)
{
    global SSOK_StampEmojiName
    Gui, Stamp:Submit, NoHide
    SSOK_NormalizeStampOptions()
    if (!SSOK_StampCtrlToImage(startCtrlX, startCtrlY, x1, y1))
        return false
    if (!SSOK_StampCtrlToImage(endCtrlX, endCtrlY, x2, y2))
        return false
    if (Abs(x2 - x1) < 8 && Abs(y2 - y1) < 8)
        return SSOK_DrawEmojiOnCurrentBitmap(x2, y2, SSOK_StampEmojiName)
    return SSOK_DrawEmojiBoxOnCurrentBitmap(x1, y1, x2, y2, SSOK_StampEmojiName)
}

SSOK_DrawEmojiBoxOnCurrentBitmap(x1, y1, x2, y2, emojiName := "")
{
    global SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDirty, SSOK_StampMainColor
    if (!SSOK_StampBitmap)
        return false
    if (emojiName = "")
        emojiName := "Ã¼Å©"
    emoji := SSOK_GetEmojiChar(emojiName)
    if (emoji = "")
        return false
    bx := Round(x1 < x2 ? x1 : x2)
    by := Round(y1 < y2 ? y1 : y2)
    bw := Round(Abs(x2 - x1))
    bh := Round(Abs(y2 - y1))
    if (bw < 8 || bh < 8)
        return false
    if (bx < 0)
        bx := 0
    if (by < 0)
        by := 0
    if (bx + bw > SSOK_StampImageW)
        bw := SSOK_StampImageW - bx
    if (by + bh > SSOK_StampImageH)
        bh := SSOK_StampImageH - by
    if (bw < 8 || bh < 8)
        return false
    size := Round((bw < bh ? bw : bh) * 0.82)
    if (size < 8)
        size := 8

    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    Gdip_SetSmoothingMode(g, 4)
    Gdip_SetTextRenderingHint(g, 4)
    textColor := SSOK_GetStampColorARGB(SSOK_StampMainColor)
    SSOK_GdipDrawCenteredText(g, emoji, bx, by, bw, bh, "Segoe UI Emoji", size, textColor)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    return true
}

SSOK_DrawEmojiOnCurrentBitmap(x, y, emojiName := "")
{
    global SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDirty, SSOK_StampMainColor
    if (!SSOK_StampBitmap)
        return false
    if (emojiName = "")
        emojiName := "Ã¼Å©"
    emoji := SSOK_GetEmojiChar(emojiName)
    if (emoji = "")
        return false
    size := SSOK_CalcEmojiSize()
    box := Round(size * 1.25)
    bx := Round(x - box / 2)
    by := Round(y - box / 2)
    if (bx < 0)
        bx := 0
    if (by < 0)
        by := 0
    if (bx + box > SSOK_StampImageW)
        bx := SSOK_StampImageW - box
    if (by + box > SSOK_StampImageH)
        by := SSOK_StampImageH - box
    if (bx < 0)
        bx := 0
    if (by < 0)
        by := 0

    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    Gdip_SetSmoothingMode(g, 4)
    Gdip_SetTextRenderingHint(g, 4)
    ; Segoe UI Emoji¸¦ ¿ì¼± »ç¿ëÇÕ´Ï´Ù. È¯°æ¿¡ µû¶ó ÄÃ·¯°¡ ¾Æ´Ñ ´Ü»öÀ¸·Î º¸ÀÏ ¼ö ÀÖ¾î °øÅë »ö»óÀ» brush·Î ÇÔ²² Àû¿ëÇÕ´Ï´Ù.
    textColor := SSOK_GetStampColorARGB(SSOK_StampMainColor)
    SSOK_GdipDrawCenteredText(g, emoji, bx, by, box, box, "Segoe UI Emoji", size, textColor)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    return true
}

SSOK_CalcEmojiSize()
{
    global SSOK_StampSizeLevel
    ; ÀÌ¸ðÆ¼ÄÜÀº ±âÁ¸ ÀÛ°Ô/Áß°£/Å©±â ´ëºñ ¾à 30% ÀÛ°Ô Á¶Á¤ÇÕ´Ï´Ù.
    if (SSOK_StampSizeLevel = "ÀÛ°Ô")
        return 20
    if (SSOK_StampSizeLevel = "Å©°Ô")
        return 36
    return 28
}

SSOK_GetEmojiChar(name)
{
    ; BMP ÀÌ¸ðÁö´Â ±×´ë·Î Chr() »ç¿ë, 0x10000 ÀÌ»ó ÀÌ¸ðÁö´Â surrogate pair·Î ±¸¼ºÇÕ´Ï´Ù.
    if (name = "Ã¼Å©")
        return Chr(0x2705)
    if (name = "¿¢½º")
        return Chr(0x274C)
    if (name = "°æ°í")
        return Chr(0x26A0)
    if (name = "º°")
        return Chr(0x2B50)
    if (name = "ÇÉ")
        return Chr(0xD83D) . Chr(0xDCCC)
    if (name = "Àü±¸")
        return Chr(0xD83D) . Chr(0xDCA1)
    if (name = "¸»Ç³¼±")
        return Chr(0xD83D) . Chr(0xDCAC)
    if (name = "ÇÏÆ®")
        return Chr(0x2764)
    if (name = "´À³¦Ç¥")
        return Chr(0x2757)
    if (name = "¹°À½Ç¥")
        return Chr(0x2753)
    if (name = "½º¸¶ÀÏ")
        return Chr(0xD83D) . Chr(0xDE00)
    if (name = "¿ôÀ½")
        return Chr(0xD83D) . Chr(0xDE04)
    if (name = "¿ì¿ï")
        return Chr(0xD83D) . Chr(0xDE1E)
    if (name = "´«¹°")
        return Chr(0xD83D) . Chr(0xDE22)
    if (name = "È­³²")
        return Chr(0xD83D) . Chr(0xDE20)
    if (name = "¾öÁö")
        return Chr(0xD83D) . Chr(0xDC4D)
    return Chr(0x2705)
}


SSOK_StampBeginEdit()
{
    global SSOK_StampBitmap, SSOK_StampUndoStack, SSOK_StampNo
    if (!SSOK_StampBitmap)
        return false
    pClone := Gdip_CloneImage(SSOK_StampBitmap)
    if (!pClone)
        return false
    if (!IsObject(SSOK_StampUndoStack))
        SSOK_StampUndoStack := []
    SSOK_StampUndoStack.Push({bitmap:pClone, stampNo:SSOK_StampNo})
    ; ¸Þ¸ð¸® °ú´Ù »ç¿ëÀ» ¸·±â À§ÇØ ÃÖ±Ù 20´Ü°è¸¸ À¯ÁöÇÕ´Ï´Ù.
    while (SSOK_StampUndoStack.Length() > 20)
    {
        old := SSOK_StampUndoStack.RemoveAt(1)
        if (IsObject(old) && old.bitmap)
            Gdip_DisposeImage(old.bitmap)
        else if (old)
            Gdip_DisposeImage(old)
    }
    return true
}

SSOK_StampUndo()
{
    global SSOK_StampBitmap, SSOK_StampUndoStack, SSOK_StampDirty, SSOK_StampNo, SSOK_StampLastTextMeta
    global SSOK_StampGuiHwnd, SSOK_StampTextEditing, SSOK_StampImageW, SSOK_StampImageH
    if (SSOK_StampGuiHwnd = "")
        return false
    if (SSOK_StampTextEditing)
        SSOK_CancelInlineTextBox(false)
    if (!IsObject(SSOK_StampUndoStack) || SSOK_StampUndoStack.Length() < 1)
    {
        SSOK_ShowToolTip("µÇµ¹¸± ÀÛ¾÷ÀÌ ¾ø½À´Ï´Ù.")
        return false
    }
    prev := SSOK_StampUndoStack.Pop()
    if (SSOK_StampBitmap)
        Gdip_DisposeImage(SSOK_StampBitmap)
    if (IsObject(prev))
    {
        SSOK_StampBitmap := prev.bitmap
        SSOK_StampNo := prev.stampNo
    }
    else
    {
        SSOK_StampBitmap := prev
        if (SSOK_StampNo > 1)
            SSOK_StampNo--
    }
    Gdip_GetImageDimensions(SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH)
    SSOK_StampDirty := true

    ; ÀÌ¹ÌÁö Å©±â 10% ÁÙÀÌ±âÃ³·³ ½ÇÁ¦ ¿øº» Å©±â°¡ ¹Ù²ï ÀÛ¾÷À» µÇµ¹¸± ¶§µµ
    ; ¹Ì¸®º¸±â Å©±â¿Í Picture ÄÁÆ®·Ñ Å©±â¸¦ ÇÔ²² ´Ù½Ã °è»êÇØ¾ß ÇÕ´Ï´Ù.
    ; ±âÁ¸¿¡´Â bitmapÀº º¹±¸µÆÁö¸¸ Ç¥½Ã ÄÁÆ®·Ñ Å©±â°¡ ÁÙ¾îµç »óÅÂ·Î ³²¾Æ
    ; Ctrl+Z°¡ ¾È µÈ °ÍÃ³·³ º¸ÀÏ ¼ö ÀÖ¾ú½À´Ï´Ù.
    SSOK_StampRecalculateDisplaySize()
    SSOK_StampRefreshPreview()
    SSOK_StampRelayoutImageControl(true)
    SSOK_StampLastTextMeta := ""
    SSOK_StampUpdateInfo()
    Gosub, SSOK_SaveState
    return true
}

SSOK_ClearStampUndoStack()
{
    global SSOK_StampUndoStack
    if (!IsObject(SSOK_StampUndoStack))
    {
        SSOK_StampUndoStack := []
        return true
    }
    while (SSOK_StampUndoStack.Length() > 0)
    {
        p := SSOK_StampUndoStack.Pop()
        if (IsObject(p) && p.bitmap)
            Gdip_DisposeImage(p.bitmap)
        else if (p)
            Gdip_DisposeImage(p)
    }
    return true
}

SSOK_DrawMosaicOnCurrentBitmap(x1, y1, x2, y2)
{
    global SSOK_StampBitmap, SSOK_StampDirty
    SSOK_NormalizeRect(x1, y1, x2, y2, rx, ry, rw, rh)
    if (rw < 4 || rh < 4)
        return false
    block := SSOK_GetMosaicBlockSize()
    if (block < 2)
        block := 4
    if (!SSOK_StampBeginEdit())
        return false
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    y := ry
    while (y < ry + rh)
    {
        bh := block
        if (y + bh > ry + rh)
            bh := ry + rh - y
        x := rx
        while (x < rx + rw)
        {
            bw := block
            if (x + bw > rx + rw)
                bw := rx + rw - x
            sx := x + Floor(bw / 2)
            sy := y + Floor(bh / 2)
            argb := Gdip_GetPixel(SSOK_StampBitmap, sx, sy)
            brush := Gdip_BrushCreateSolid(0xFF000000 | (argb & 0x00FFFFFF))
            Gdip_FillRectangle(g, brush, x, y, bw, bh)
            Gdip_DeleteBrush(brush)
            x += block
        }
        y += block
    }
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    return true
}


SSOK_Atan2(y, x)
{
    pi := 3.141592653589793
    if (x > 0)
        return ATan(y / x)
    if (x < 0 && y >= 0)
        return ATan(y / x) + pi
    if (x < 0 && y < 0)
        return ATan(y / x) - pi
    if (x = 0 && y > 0)
        return pi / 2
    if (x = 0 && y < 0)
        return -pi / 2
    return 0
}

SSOK_NormalizeRect(x1, y1, x2, y2, ByRef rx, ByRef ry, ByRef rw, ByRef rh)
{
    if (x2 < x1)
    {
        tmp := x1, x1 := x2, x2 := tmp
    }
    if (y2 < y1)
    {
        tmp := y1, y1 := y2, y2 := tmp
    }
    rx := Round(x1)
    ry := Round(y1)
    rw := Round(x2 - x1)
    rh := Round(y2 - y1)
    if (rw < 1)
        rw := 1
    if (rh < 1)
        rh := 1
}

SSOK_CalcStampSize(w, h)
{
    global SSOK_StampSizeLevel
    ; ¹øÈ£ ½ºÅÆÇÁ´Â ±âÁ¸ ÀÛ°Ô/Áß°£/Å©±â ´ëºñ ¾à 30% ÀÛ°Ô Á¶Á¤ÇÕ´Ï´Ù.
    if (SSOK_StampSizeLevel = "ÀÛ°Ô")
        return 24
    if (SSOK_StampSizeLevel = "Å©°Ô")
        return 41
    return 31
}

SSOK_StampRefreshPreview()
{
    global SSOK_StampBitmap, SSOK_StampPreviewFile, SSOK_WorkFolder, SSOK_StampDisplayW, SSOK_StampDisplayH, SSOK_StampGuiHwnd
    if (!SSOK_StampBitmap)
        return false
    previewFile := SSOK_WorkFolder "\SSOK_editor_preview_" A_TickCount ".png"
    pPreview := SSOK_CreateScaledBitmap(SSOK_StampBitmap, SSOK_StampDisplayW, SSOK_StampDisplayH)
    if (!pPreview)
        pPreview := Gdip_CloneImage(SSOK_StampBitmap)
    if (!pPreview)
        return false
    err := Gdip_SaveBitmapToFile(pPreview, previewFile)
    Gdip_DisposeImage(pPreview)
    if (err != 0 || !FileExist(previewFile))
        return false
    if (SSOK_StampPreviewFile != "" && SSOK_StampPreviewFile != previewFile)
        FileDelete, %SSOK_StampPreviewFile%
    SSOK_StampPreviewFile := previewFile
    SSOK_StampRememberTempFile(previewFile)
    if (SSOK_StampGuiHwnd != "")
    {
        GuiControl, Stamp:, SSOK_StampPic, *w%SSOK_StampDisplayW% *h%SSOK_StampDisplayH% %SSOK_StampPreviewFile%
        SSOK_WriteActiveEditorInfo(true)
    }
    return true
}

SSOK_StampRecalculateDisplaySize()
{
    global SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDisplayW, SSOK_StampDisplayH
    SSOK_GetStampEditorMaxSize(maxW, maxH)

    scaleW := maxW / SSOK_StampImageW
    scaleH := maxH / SSOK_StampImageH
    scale := (scaleW < scaleH) ? scaleW : scaleH
    if (scale > 1)
        scale := 1
    if (scale <= 0)
        scale := 1
    SSOK_StampDisplayW := Round(SSOK_StampImageW * scale)
    SSOK_StampDisplayH := Round(SSOK_StampImageH * scale)
    if (SSOK_StampDisplayW < 1)
        SSOK_StampDisplayW := 1
    if (SSOK_StampDisplayH < 1)
        SSOK_StampDisplayH := 1
    return true
}

SSOK_StampRelayoutImageControl(keepWindowSize := false)
{
    global SSOK_StampGuiHwnd, SSOK_StampInfoW, SSOK_StampDisplayW, SSOK_StampDisplayH, SSOK_StampPreviewFile
    if (SSOK_StampGuiHwnd = "")
        return false

    ; keepWindowSize=trueÀÏ ¶§´Â ÆíÁýÃ¢ Å©±â¸¦ °Çµå¸®Áö ¾Ê°í »çÁø Ç¥½Ã ¿µ¿ª¸¸ ÁÙÀÔ´Ï´Ù.
    if (keepWindowSize)
    {
        WinGetPos, keepX, keepY, keepW, keepH, ahk_id %SSOK_StampGuiHwnd%
        baseW := keepW - 40
        if (baseW < SSOK_StampInfoW)
            baseW := SSOK_StampInfoW
    }
    else
    {
        baseW := SSOK_StampInfoW
        if (baseW < SSOK_StampDisplayW)
            baseW := SSOK_StampDisplayW
        SSOK_StampInfoW := baseW
    }

    picX := 10
    if (baseW > SSOK_StampDisplayW)
        picX := 10 + Floor((baseW - SSOK_StampDisplayW) / 2)
    GuiControl, Stamp:Move, SSOK_StampPic, x%picX% w%SSOK_StampDisplayW% h%SSOK_StampDisplayH%
    GuiControl, Stamp:Move, SSOK_StampInlineText, x%picX%
    if (SSOK_StampPreviewFile != "" && FileExist(SSOK_StampPreviewFile))
    {
        GuiControl, Stamp:, SSOK_StampPic, *w%SSOK_StampDisplayW% *h%SSOK_StampDisplayH% %SSOK_StampPreviewFile%
        SSOK_WriteActiveEditorInfo(true)
    }

    if (keepWindowSize)
        WinMove, ahk_id %SSOK_StampGuiHwnd%,, keepX, keepY, keepW, keepH
    else
        Gui, Stamp:Show, AutoSize Center
    SSOK_WriteActiveEditorInfo(true)
    return true
}

SSOK_StampReduceImage10()
{
    global SSOK_StampBitmap, SSOK_StampImageW, SSOK_StampImageH, SSOK_StampDirty, SSOK_StampGuiHwnd, SSOK_StampTextEditing
    if (SSOK_StampGuiHwnd = "" || !SSOK_StampBitmap)
        return false
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    newW := Round(SSOK_StampImageW * 0.9)
    newH := Round(SSOK_StampImageH * 0.9)
    if (newW < 50 || newH < 50)
    {
        SSOK_ShowToolTip("ÀÌ¹ÌÁö°¡ ³Ê¹« ÀÛ¾Æ ´õ ÁÙÀÏ ¼ö ¾ø½À´Ï´Ù.")
        return false
    }
    if (!SSOK_StampBeginEdit())
        return false
    pNew := SSOK_CreateScaledBitmap(SSOK_StampBitmap, newW, newH)
    if (!pNew)
    {
        SSOK_ShowToolTip("ÀÌ¹ÌÁö Å©±â ÁÙÀÌ±â¿¡ ½ÇÆÐÇß½À´Ï´Ù.")
        return false
    }
    Gdip_DisposeImage(SSOK_StampBitmap)
    SSOK_StampBitmap := pNew
    SSOK_StampImageW := newW
    SSOK_StampImageH := newH
    SSOK_StampDirty := true
    SSOK_StampRecalculateDisplaySize()
    SSOK_StampRefreshPreview()
    SSOK_StampRelayoutImageControl(true)
    SSOK_StampUpdateInfo()
    SSOK_ShowToolTip("ÀÌ¹ÌÁö¸¸ 10% ÁÙ¿´½À´Ï´Ù.")
    return true
}

SSOK_StampUpdateInfo()
{
    global SSOK_StampGuiHwnd
    if (SSOK_StampGuiHwnd = "")
        return
    GuiControl, Stamp:, SSOK_StampInfoText, % SSOK_StampGetInfoText()
    SSOK_StampUpdateToolButtons()
}

SSOK_StampSaveAndClose()
{
    global SSOK_StampGuiHwnd, SSOK_StampBitmap, SSOK_WorkFolder, SSOK_LastCaptureFile, SSOK_PaintHasCapture, SSOK_StampTextEditing
    if (SSOK_StampGuiHwnd = "")
        return true
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    if (!SSOK_StampBitmap)
    {
        SSOK_CloseStampEditor(false)
        return false
    }
    FormatTime, now,, yyyyMMdd_HHmmss
    outFile := SSOK_WorkFolder "\SSOK_capture_edited_" now "_" A_TickCount ".png"
    if (Gdip_SaveBitmapToFile(SSOK_StampBitmap, outFile) != 0 || !FileExist(outFile))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÆíÁýÇÑ ÀÌ¹ÌÁö¸¦ ÀúÀåÇÏÁö ¸øÇß½À´Ï´Ù.
        return false
    }
    SSOK_LastCaptureFile := outFile
    SSOK_PaintHasCapture := false
    if (!Gdip_SetBitmapToClipboard(SSOK_StampBitmap))
        SSOK_CopyImageFileToClipboard(outFile)
    SSOK_CloseStampEditor(true)
    SSOK_ShowToolTip("ÆíÁýÇÑ ÀÌ¹ÌÁö°¡ ÀúÀåµÇ°í Å¬¸³º¸µå¿¡µµ º¹»çµÇ¾ú½À´Ï´Ù.")
    Gosub, SSOK_ReturnToMainOrExit
    return true
}

SSOK_StampCopyCurrentToClipboard()
{
    global SSOK_StampBitmap, SSOK_StampTextEditing
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    if (!SSOK_StampBitmap)
        return false

    ; Å¬¸³º¸µå º¹»ç´Â ÆÄÀÏÀ» ¸¸µéÁö ¾Ê°í, ÇöÀç ÆíÁý ÀÌ¹ÌÁö¸¦ ÀÌ¹ÌÁö µ¥ÀÌÅÍ·Î¸¸ º¹»çÇÕ´Ï´Ù.
    ; ÆÄÀÏ ÀúÀåÀº »ç¿ëÀÚ°¡ [ÆÄÀÏ ÀúÀå] ¶Ç´Â ÀúÀå ´Ý±â¸¦ ¼±ÅÃÇÒ ¶§¸¸ ¼öÇàÇÕ´Ï´Ù.
    if (Gdip_SetBitmapToClipboard(SSOK_StampBitmap))
    {
        Sleep, 80
        SSOK_ShowToolTip("ÇöÀç ÆíÁý ÀÌ¹ÌÁö¸¦ Å¬¸³º¸µå¿¡ º¹»çÇß½À´Ï´Ù.")
        return true
    }

    MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÀÌ¹ÌÁö º¹»ç¿¡ ½ÇÆÐÇß½À´Ï´Ù.
    return false
}

SSOK_StampAutoMaskCurrent()
{
    global SSOK_StampBitmap, SSOK_WorkFolder, SSOK_StampTextEditing, SSOK_StampGuiHwnd, SSOK_StampImageW, SSOK_StampImageH
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    if (!SSOK_StampBitmap)
        return false

    FormatTime, now,, yyyyMMdd_HHmmss
    imageFile := SSOK_WorkFolder "\SSOK_editor_automask_" now "_" A_TickCount ".png"
    SSOK_StampRememberTempFile(imageFile)

    if (Gdip_SaveBitmapToFile(SSOK_StampBitmap, imageFile) != 0 || !FileExist(imageFile))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÀÚµ¿°¡¸²¿ë ÀÌ¹ÌÁö¸¦ ÁØºñÇÏÁö ¸øÇß½À´Ï´Ù.
        return false
    }

    ocrImageFile := SSOK_PrepareSmallTextOcrImage(imageFile)
    if (ocrImageFile = "" || !FileExist(ocrImageFile))
        ocrImageFile := imageFile
    cleanupOcrImage := (ocrImageFile != imageFile)
    scaleX := 1.0
    scaleY := 1.0
    if (cleanupOcrImage)
    {
        pOcrBitmap := Gdip_CreateBitmapFromFile(ocrImageFile)
        if (pOcrBitmap)
        {
            Gdip_GetImageDimensions(pOcrBitmap, ocrW, ocrH)
            Gdip_DisposeImage(pOcrBitmap)
            if (ocrW > 0 && ocrH > 0)
            {
                scaleX := SSOK_StampImageW / ocrW
                scaleY := SSOK_StampImageH / ocrH
            }
        }
    }

    directOcrErr := ""
    if (!SSOK_WinRtOcrImageToPrivacyRects(ocrImageFile, rectText, directOcrErr))
    {
        if (cleanupOcrImage)
            FileDelete, %ocrImageFile%
        FileDelete, %imageFile%
        msg := "°³ÀÎÁ¤º¸ ÀÚµ¿°¡¸²¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n¿ÜºÎ ÇÁ·Î¼¼½º fallback ¾øÀÌ AHK DllCall WinRT OCR¸¸ »ç¿ëÇß½À´Ï´Ù."
        if (directOcrErr != "")
            msg .= "`n`n¿À·ù ³»¿ë: " directOcrErr
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, %msg%
        return false
    }

    if (cleanupOcrImage)
        FileDelete, %ocrImageFile%
    FileDelete, %imageFile%
    rectText := Trim(rectText, " `t`r`n")
    count := SSOK_DrawAutoMaskRectsOnCurrentBitmap(rectText, scaleX, scaleY)
    if (count > 0)
    {
        SSOK_ShowToolTip("°³ÀÎÁ¤º¸ ÈÄº¸ " count "°÷À» ÀÚµ¿À¸·Î °¡·È½À´Ï´Ù.")
        return true
    }
    SSOK_ShowToolTip("ÀÚµ¿À¸·Î °¡¸± °³ÀÎÁ¤º¸ ÈÄº¸¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.")
    return false
}
SSOK_DrawAutoMaskRectsOnCurrentBitmap(rectText, scaleX := 1.0, scaleY := 1.0)
{
    global SSOK_StampBitmap, SSOK_StampDirty, SSOK_StampImageW, SSOK_StampImageH
    if (scaleX <= 0)
        scaleX := 1.0
    if (scaleY <= 0)
        scaleY := 1.0
    rects := []
    Loop, Parse, rectText, `n, `r
    {
        line := Trim(A_LoopField, " `t`r`n")
        if (line = "")
            continue
        StringSplit, part, line, |
        if (part0 < 4)
            continue
        x := Round((part1 + 0) * scaleX)
        y := Round((part2 + 0) * scaleY)
        w := Round((part3 + 0) * scaleX)
        h := Round((part4 + 0) * scaleY)
        if (w < 4 || h < 4)
            continue
        if (x < 0)
            x := 0
        if (y < 0)
            y := 0
        if (x + w > SSOK_StampImageW)
            w := SSOK_StampImageW - x
        if (y + h > SSOK_StampImageH)
            h := SSOK_StampImageH - y
        if (w < 4 || h < 4)
            continue
        rects.Push({x:x, y:y, w:w, h:h})
    }
    if (rects.Length() < 1)
        return 0
    if (!SSOK_StampBeginEdit())
        return 0
    g := Gdip_GraphicsFromImage(SSOK_StampBitmap)
    if (!g)
        return 0
    brush := Gdip_BrushCreateSolid(0xFF000000)
    for _, r in rects
        Gdip_FillRectangle(g, brush, r.x, r.y, r.w, r.h)
    Gdip_DeleteBrush(brush)
    Gdip_DeleteGraphics(g)
    SSOK_StampDirty := true
    SSOK_StampRefreshPreview()
    SSOK_StampUpdateInfo()
    return rects.Length()
}
SSOK_StampExtractTextCurrent(mode := "text")
{
    global SSOK_StampBitmap, SSOK_WorkFolder, SSOK_LastCaptureFile, SSOK_StampTextEditing, SSOK_StampGuiHwnd
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    if (!SSOK_StampBitmap)
        return false

    FormatTime, now,, yyyyMMdd_HHmmss
    tempFile := SSOK_WorkFolder "\SSOK_editor_ocr_" now "_" A_TickCount ".png"
    SSOK_StampRememberTempFile(tempFile)
    if (Gdip_SaveBitmapToFile(SSOK_StampBitmap, tempFile) != 0 || !FileExist(tempFile))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÅØ½ºÆ® ÃßÃâ¿ë ÀÌ¹ÌÁö¸¦ ÁØºñÇÏÁö ¸øÇß½À´Ï´Ù.
        return false
    }

    SSOK_LastCaptureFile := tempFile
    Gui, Stamp:+OwnDialogs
    if (SSOK_StampGuiHwnd != "")
    {
        WinActivate, ahk_id %SSOK_StampGuiHwnd%
        Sleep, 80
    }
    SSOK_ExtractTextFromCapture(mode)
    return true
}

SSOK_StampOpenWindowsOcrTool()
{
    global SSOK_StampTextEditing, SSOK_StampGuiHwnd
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()

    ; ´Ü¼ø ½ÇÇà Àü¿ëÀÔ´Ï´Ù.
    ; ÇöÀç ÆíÁý ÀÌ¹ÌÁö¸¦ ÀúÀåÇÏ°Å³ª Snipping Tool·Î ³Ñ±â°Å³ª ÅØ½ºÆ® ÀÛ¾÷À» ÀÚµ¿ Å¬¸¯ÇÏÁö ¾Ê½À´Ï´Ù.
    if (SSOK_OpenSnippingTool())
    {
        SSOK_ShowToolTip("Windows Ä¸Ã³ µµ±¸¸¦ ¿­¾ú½À´Ï´Ù.")
        return true
    }

    MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, Windows Ä¸Ã³ µµ±¸¸¦ ¿­Áö ¸øÇß½À´Ï´Ù.
    return false
}

SSOK_StampSaveCurrentAsJpg()
{
    global SSOK_StampBitmap, SSOK_LastCaptureFile, SSOK_StampTextEditing, SSOK_StampGuiHwnd
    if (SSOK_StampTextEditing)
        SSOK_ApplyInlineTextBox()
    if (!SSOK_StampBitmap)
        return false
    FormatTime, now,, yyyyMMdd_HHmmss
    defaultFile := SSOK_GetDefaultDownloadPath(now ".png")
    defaultDir := SSOK_GetDefaultDownloadDir()
    oldWD := A_WorkingDir
    if (defaultDir != "")
        SetWorkingDir, %defaultDir%
    Gui, Stamp:+OwnDialogs
    if (SSOK_StampGuiHwnd != "")
    {
        WinActivate, ahk_id %SSOK_StampGuiHwnd%
        Sleep, 80
    }
    FileSelectFile, outFile, S16, %defaultFile%, ÆÄÀÏ ÀúÀå, PNG/JPG ÀÌ¹ÌÁö (*.png; *.jpg; *.jpeg)
    if (oldWD != "")
        SetWorkingDir, %oldWD%
    if (SSOK_StampGuiHwnd != "")
        WinActivate, ahk_id %SSOK_StampGuiHwnd%
    if (outFile = "")
        return false
    SplitPath, outFile,,, ext
    if (ext = "")
        outFile .= ".png"
    else
    {
        StringLower, extLower, ext
        if (extLower != "png" && extLower != "jpg" && extLower != "jpeg")
            outFile .= ".png"
    }
    if (Gdip_SaveBitmapToFile(SSOK_StampBitmap, outFile) != 0 || !FileExist(outFile))
    {
        MsgBox, 48, SSOK Ä¸Ã³ Å×½ºÆ®, ÀÌ¹ÌÁö ÆÄÀÏ ÀúÀå¿¡ ½ÇÆÐÇß½À´Ï´Ù.
        return false
    }
    SSOK_LastCaptureFile := outFile
    SSOK_ShowToolTip("ÀÌ¹ÌÁö ÆÄÀÏ·Î ÀúÀåÇß½À´Ï´Ù.")
    Gosub, SSOK_SaveState
    return true
}

SSOK_FinalizeStampEditorIfOpen()
{
    global SSOK_StampGuiHwnd
    if (SSOK_StampGuiHwnd != "")
        return SSOK_StampSaveAndClose()
    return true
}

SSOK_StampInitTempManifest()
{
    global SSOK_StampTempManifestFile, SSOK_StampTempManifestInitialized
    SSOK_StampTempManifestFile := ""
    SSOK_StampTempManifestInitialized := false
    return true
}

SSOK_StampAppendTempManifest(filePath)
{
    ; Manifest ÆÄÀÏ ÃßÀûÀº Áß´ÜÇÕ´Ï´Ù. ÇöÀç ¼¼¼Ç ¸ñ·ÏÀº ¸Þ¸ð¸® ¹è¿­°ú wildcard cleanupÀ¸·Î Ã³¸®ÇÕ´Ï´Ù.
    return false
}
SSOK_CleanupDeadTempManifests()
{
    global SSOK_WorkFolder
    if (SSOK_WorkFolder = "")
        SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
    FileCreateDir, %SSOK_WorkFolder%

    work := RTrim(SSOK_WorkFolder, "\/")
    if (work = "" || !InStr(work, "\SSOK\work\capture"))
        return false

    ; ÇÁ·Î±×·¥ ÃÊ±â ±âµ¿ ½Ã, ±âÁ¸¿¡ ³²¾Æ ÀÖ´ø ÀÓ½Ã Ä¸Ã³ Âî²¨±â¸¦ ÀÏ°ý Á¤¸®ÇÕ´Ï´Ù.
    Loop, Files, %work%\SSOK_*.png, F
        FileDelete, %A_LoopFileFullPath%
    Loop, Files, %work%\*.lst, F
        FileDelete, %A_LoopFileFullPath%
    Loop, Files, %work%\*.txt, F
        FileDelete, %A_LoopFileFullPath%

    manifestDir := work "\sessions"
    if InStr(FileExist(manifestDir), "D")
    {
        Loop, Files, %manifestDir%\*.lst, F
            FileDelete, %A_LoopFileFullPath%
        SSOK_RemoveEmptyDirs(manifestDir)
        FileRemoveDir, %manifestDir%
    }

    return true
}
SSOK_IsProcessRunning(pid)
{
    pid := pid + 0
    if (pid <= 0)
        return false
    hProc := DllCall("OpenProcess", "UInt", 0x1000, "Int", false, "UInt", pid, "Ptr")
    if (!hProc)
        return false
    DllCall("CloseHandle", "Ptr", hProc)
    return true
}
SSOK_StampRememberTempFile(filePath)
{
    global SSOK_StampSessionTempFiles
    filePath := Trim(filePath)
    if (filePath = "")
        return false
    if (!IsObject(SSOK_StampSessionTempFiles))
        SSOK_StampSessionTempFiles := []
    Loop % SSOK_StampSessionTempFiles.Length()
    {
        if (SSOK_StampSessionTempFiles[A_Index] = filePath)
            return true
    }
    SSOK_StampSessionTempFiles.Push(filePath)
    SSOK_StampAppendTempManifest(filePath)
    return true
}

SSOK_StampIsSafeTempFile(filePath)
{
    global SSOK_WorkFolder
    filePath := Trim(filePath)
    if (filePath = "")
        return false
    SplitPath, filePath, fileName, fileDir
    if (fileName = "")
        return false
    workPrefix := RTrim(SSOK_WorkFolder, "\/") . "\"
    if (SubStr(filePath, 1, StrLen(workPrefix)) = workPrefix)
    {
        return RegExMatch(fileName, "i)^SSOK_(direct_capture|screenclip|editor_preview|editor_clip|editor_ocr|editor_automask|editor_from_clip|capture_edited|ocr_snip|ocr_input|save_snip)_.*\.(png|jpg|jpeg)$")
            || RegExMatch(fileName, "i)^SSOK_active_editor.*\.ini$")
            || RegExMatch(fileName, "i)^SSOK_editor_.*\.ini$")
            || RegExMatch(fileName, "i)^(ssok_ocr_.*\.txt|ssok_textbox_.*\.txt)$")
    }
    return false
}

SSOK_StampDeleteTempFile(filePath)
{
    if (!SSOK_StampIsSafeTempFile(filePath))
        return false

    Loop, 8
    {
        if (!FileExist(filePath))
            return true
        FileDelete, %filePath%
        if (!FileExist(filePath))
            return true
        Sleep, 100
    }
    return !FileExist(filePath)
}

SSOK_StampCleanupSessionTempFiles()
{
    global SSOK_WorkFolder
    global SSOK_StampPreviewFile, SSOK_StampPreviewTempFile, SSOK_StampSourceFile, SSOK_LastCaptureFile
    global SSOK_StampSessionTempFiles, SSOK_StampTempManifestFile, SSOK_StampTempManifestInitialized

    if (SSOK_WorkFolder = "")
        SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
    FileCreateDir, %SSOK_WorkFolder%

    work := RTrim(SSOK_WorkFolder, "\/")
    if (work != "" && InStr(work, "\SSOK\work\capture"))
    {
        ; º¹ÀâÇÑ manifest ÃßÀû ´ë½Å, Ä¸Ã³ Æú´õ¿¡ ³²Àº ÀÓ½Ã png/lst/txt¸¦ Áï½Ã ÀÏ°ý »èÁ¦ÇÕ´Ï´Ù.
        Loop, Files, %work%\*.*, F
        {
            if RegExMatch(A_LoopFileName, "i)\.(png|lst|txt)$")
                FileDelete, %A_LoopFileFullPath%
        }

        manifestDir := work "\sessions"
        if InStr(FileExist(manifestDir), "D")
        {
            Loop, Files, %manifestDir%\*.lst, F
                FileDelete, %A_LoopFileFullPath%
            SSOK_RemoveEmptyDirs(manifestDir)
            FileRemoveDir, %manifestDir%
        }
    }

    SSOK_StampPreviewFile := ""
    SSOK_StampPreviewTempFile := ""
    SSOK_StampSourceFile := ""
    SSOK_LastCaptureFile := ""
    SSOK_StampSessionTempFiles := []
    SSOK_StampTempManifestFile := ""
    SSOK_StampTempManifestInitialized := false
    return true
}
SSOK_CloseStampEditor(saved := false)
{
    global SSOK_StampGuiHwnd, SSOK_StampPicHwnd, SSOK_StampInfoHwnd, SSOK_StampPreviewFile, SSOK_StampDirty, SSOK_StampLastTextMeta
    global SSOK_StampDragging, SSOK_StampDragStartX, SSOK_StampDragStartY, SSOK_StampTextEditing, SSOK_StampTextEditHwnd, SSOK_StampInlineText
    global SSOK_StampTextInputHwnd, SSOK_StampColorHwnd, SSOK_StampSizeHwnd, SSOK_StampEmojiHwnd, SSOK_StampPendingDropdownHwnd
    global SSOK_ActiveEditorInfoCache, SSOK_ActiveEditorLastWriteTick
    infoPath := ""
    if (SSOK_StampGuiHwnd != "")
    {
        SetTimer, SSOK_UpdateActiveEditorInfo, Off
        infoPath := SSOK_GetActiveEditorInfoPath(SSOK_StampGuiHwnd)
        SSOK_CancelInlineTextBox(false)
        Gui, Stamp:Destroy
    }
    if (infoPath != "")
        FileDelete, %infoPath%
    SSOK_ClearStampUndoStack()
    SSOK_DisposeStampBitmap()
    SSOK_StampCleanupSessionTempFiles()
    SSOK_StampGuiHwnd := ""
    SSOK_StampPicHwnd := ""
    SSOK_StampInfoHwnd := ""
    SSOK_StampTextInputHwnd := ""
    SSOK_StampColorHwnd := ""
    SSOK_StampSizeHwnd := ""
    SSOK_StampEmojiHwnd := ""
    SSOK_StampPendingDropdownHwnd := ""
    SSOK_StampDragging := false
    SSOK_StampDragStartX := 0
    SSOK_StampDragStartY := 0
    SSOK_StampTextEditing := false
    SSOK_StampTextEditHwnd := ""
    SSOK_StampInlineText := ""
    SSOK_StampLastTextMeta := ""
    SSOK_StampDirty := false
    SSOK_ActiveEditorInfoCache := ""
    SSOK_ActiveEditorLastWriteTick := 0
    if (!saved)
        Gosub, SSOK_ReturnToMainOrExit
    return true
}

SSOK_DisposeStampBitmap()
{
    global SSOK_StampBitmap
    if (SSOK_StampBitmap)
    {
        Gdip_DisposeImage(SSOK_StampBitmap)
        SSOK_StampBitmap := 0
    }
}

SSOK_ShutdownGdip()
{
    global SSOK_GdipToken
    if (SSOK_GdipToken)
    {
        Gdip_Shutdown(SSOK_GdipToken)
        SSOK_GdipToken := 0
    }
}

SSOK_ReleaseCaptureMutex()
{
    global SSOK_CaptureMainMutex
    if (SSOK_CaptureMainMutex)
    {
        DllCall("ReleaseMutex", "Ptr", SSOK_CaptureMainMutex)
        DllCall("CloseHandle", "Ptr", SSOK_CaptureMainMutex)
        SSOK_CaptureMainMutex := 0
    }
    return true
}

; ------------------------------------------------------------
; ±×¸²ÆÇ ¹øÈ£ ½ºÅÆÇÁ
; ------------------------------------------------------------
SSOK_PasteStamp:
SSOK_PasteNextStampToPaint()
return

SSOK_ResetNumber:
SSOK_StampNo := 1
Gosub, SSOK_SaveState
ToolTip, ¹øÈ£°¡ 1¹øÀ¸·Î ÃÊ±âÈ­µÇ¾ú½À´Ï´Ù.
SetTimer, SSOK_ClearTip, -1200
return

SSOK_ClearTip:
ToolTip
return

SSOK_CreateStampToClipboard(num)
{
    ; ÀÚÃ¼ ÆíÁý±â ¹øÈ£ µµ±¸¸¦ »ç¿ëÇÏ¹Ç·Î ±×¸²ÆÇ¿ë ½ºÅÆÇÁ »ý¼ºÀº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    return false
}

; ------------------------------------------------------------
; Á¾·á / GDI+
; ------------------------------------------------------------
SSOK_AppExit:
SSOK_DestroyNumberOverlays()
SSOK_DestroyNumberClickLayer()
SSOK_CancelDirectAreaCapture(false)
SSOK_ClearStampUndoStack()
SSOK_DisposeStampBitmap()
SSOK_StampCleanupSessionTempFiles()
SSOK_ShutdownGdip()
SSOK_ReleaseCaptureMutex()

if (SSOK_LaunchMode = "embedded-direct" || SSOK_CaptureEmbeddedMode)
    return
ExitApp
return

Gdip_Startup()
{
    if !DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
        DllCall("LoadLibrary", "Str", "gdiplus")
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "UInt")
    DllCall("gdiplus\GdiplusStartup", "UPtr*", pToken, "UPtr", &si, "UPtr", 0)
    return pToken
}

Gdip_Shutdown(pToken)
{
    return DllCall("gdiplus\GdiplusShutdown", "UPtr", pToken)
}

Gdip_CreateBitmapFromFile(sFile)
{
    pBitmap := 0
    pClone := 0
    DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", sFile, "UPtr*", pBitmap)
    if (!pBitmap)
        return 0
    DllCall("gdiplus\GdipCloneImage", "Ptr", pBitmap, "Ptr*", pClone)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    return pClone
}

Gdip_GetImageDimensions(pBitmap, ByRef w, ByRef h)
{
    DllCall("gdiplus\GdipGetImageWidth", "Ptr", pBitmap, "UInt*", w)
    DllCall("gdiplus\GdipGetImageHeight", "Ptr", pBitmap, "UInt*", h)
}

Gdip_DisposeImage(pBitmap)
{
    return DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
}


Gdip_CreateBitmapFromHBITMAP(hBitmap, hPalette := 0)
{
    if (!hBitmap)
        return 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBitmap, "Ptr", hPalette, "Ptr*", pBitmap)
    return pBitmap
}

Gdip_CloneImage(pBitmap)
{
    if (!pBitmap)
        return 0
    DllCall("gdiplus\GdipCloneImage", "Ptr", pBitmap, "Ptr*", pClone)
    return pClone
}

Gdip_SetBitmapToClipboard(pBitmap)
{
    if (!pBitmap)
        return false

    if (Gdip_SetBitmapToClipboard_DIB(pBitmap))
        return true

    ; DIB Á÷Á¢ µî·ÏÀÌ º¸¾È ¸ðµâ/È¯°æ ¹®Á¦·Î ½ÇÆÐÇÏ¸é Windows Forms ¹æ½ÄÀ¸·Î ÇÑ ¹ø ´õ ½ÃµµÇÕ´Ï´Ù.
    return Gdip_SetBitmapToClipboard_PowerShell(pBitmap)
}

Gdip_SetBitmapToClipboard_DIB(pBitmap)
{
    if (!pBitmap)
        return false

    DllCall("gdiplus\GdipGetImageWidth", "Ptr", pBitmap, "UInt*", w)
    DllCall("gdiplus\GdipGetImageHeight", "Ptr", pBitmap, "UInt*", h)
    if (w < 1 || h < 1)
        return false

    hBitmap := 0
    if (DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "UInt", 0xFFFFFFFF) != 0 || !hBitmap)
        return false

    hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
    if (!hdc)
    {
        DllCall("DeleteObject", "Ptr", hBitmap)
        return false
    }

    biSizeImage := w * h * 4
    dwLen := 40 + biSizeImage
    hDIB := DllCall("GlobalAlloc", "UInt", 0x42, "UPtr", dwLen, "Ptr")
    if (!hDIB)
    {
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
        DllCall("DeleteObject", "Ptr", hBitmap)
        return false
    }

    pDIB := DllCall("GlobalLock", "Ptr", hDIB, "Ptr")
    if (!pDIB)
    {
        DllCall("GlobalFree", "Ptr", hDIB)
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
        DllCall("DeleteObject", "Ptr", hBitmap)
        return false
    }

    NumPut(40, pDIB, 0, "UInt")              ; biSize
    NumPut(w, pDIB, 4, "Int")                ; biWidth
    NumPut(h, pDIB, 8, "Int")                ; biHeight, bottom-up DIB
    NumPut(1, pDIB, 12, "UShort")            ; biPlanes
    NumPut(32, pDIB, 14, "UShort")           ; biBitCount
    NumPut(0, pDIB, 16, "UInt")              ; biCompression = BI_RGB
    NumPut(biSizeImage, pDIB, 20, "UInt")    ; biSizeImage

    ; GetDIBits ´ë»ó hBitmapÀº DC¿¡ ¼±ÅÃÇÏÁö ¾Ê¾Æ¾ß ½ÇÆÐÇÏÁö ¾Ê½À´Ï´Ù.
    gotBits := DllCall("GetDIBits", "Ptr", hdc, "Ptr", hBitmap, "UInt", 0, "UInt", h, "Ptr", pDIB + 40, "Ptr", pDIB, "UInt", 0)

    DllCall("GlobalUnlock", "Ptr", hDIB)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
    DllCall("DeleteObject", "Ptr", hBitmap)

    if (!gotBits)
    {
        DllCall("GlobalFree", "Ptr", hDIB)
        return false
    }

    opened := false
    Loop, 5
    {
        if (DllCall("OpenClipboard", "Ptr", 0))
        {
            opened := true
            break
        }
        Sleep, 80
    }
    if (!opened)
    {
        DllCall("GlobalFree", "Ptr", hDIB)
        return false
    }

    DllCall("EmptyClipboard")
    ok := DllCall("SetClipboardData", "UInt", 8, "Ptr", hDIB, "Ptr") ; CF_DIB
    DllCall("CloseClipboard")
    if (!ok)
    {
        DllCall("GlobalFree", "Ptr", hDIB)
        return false
    }
    return true
}

Gdip_SetBitmapToClipboard_PowerShell(pBitmap)
{
    global SSOK_WorkFolder
    if (!pBitmap)
        return false
    if (SSOK_WorkFolder = "")
        SSOK_WorkFolder := SSOK_GetPrivateWorkDir("capture")
    FileCreateDir, %SSOK_WorkFolder%

    FormatTime, now,, yyyyMMdd_HHmmss
    tempFile := SSOK_WorkFolder "\SSOK_clipboard_fallback_" now "_" A_TickCount ".png"
    if (Gdip_SaveBitmapToFile(pBitmap, tempFile) != 0 || !FileExist(tempFile))
        return false

    q := Chr(34)
    psCmd := "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; "
        . "$img=[System.Drawing.Image]::FromFile('" tempFile "'); "
        . "[System.Windows.Forms.Clipboard]::SetImage($img); $img.Dispose()"
    cmd := "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -Command " q psCmd q
    RunWait, %cmd%,, Hide UseErrorLevel
    ok := (ErrorLevel = 0 && SSOK_ClipboardHasImage())
    FileDelete, %tempFile%
    return ok
}
Gdip_CreateBitmapFromClipboard()
{
    pBitmap := 0
    if (!DllCall("OpenClipboard", "Ptr", 0))
        return 0

    hBitmap := DllCall("GetClipboardData", "UInt", 2, "Ptr") ; CF_BITMAP
    if (hBitmap)
    {
        hCopy := DllCall("CopyImage", "Ptr", hBitmap, "UInt", 0, "Int", 0, "Int", 0, "UInt", 0x2000, "Ptr") ; LR_CREATEDIBSECTION
        if (!hCopy)
            hCopy := hBitmap
        DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hCopy, "Ptr", 0, "Ptr*", pBitmap)
        if (hCopy && hCopy != hBitmap)
            DllCall("DeleteObject", "Ptr", hCopy)
    }

    if (!pBitmap)
    {
        hDIB := DllCall("GetClipboardData", "UInt", 8, "Ptr") ; CF_DIB
        if (hDIB)
        {
            pDIB := DllCall("GlobalLock", "Ptr", hDIB, "Ptr")
            if (pDIB)
            {
                biSize := NumGet(pDIB, 0, "UInt")
                biBitCount := NumGet(pDIB, 14, "UShort")
                biCompression := NumGet(pDIB, 16, "UInt")
                biClrUsed := NumGet(pDIB, 32, "UInt")

                colorCount := 0
                if (biBitCount <= 8)
                    colorCount := biClrUsed ? biClrUsed : (1 << biBitCount)
                bitFieldsSize := (biCompression = 3 && biSize <= 40) ? 12 : 0
                bitsOffset := biSize + (colorCount * 4) + bitFieldsSize

                DllCall("gdiplus\GdipCreateBitmapFromGdiDib", "Ptr", pDIB, "Ptr", pDIB + bitsOffset, "Ptr*", pBitmap)
                DllCall("GlobalUnlock", "Ptr", hDIB)
            }
        }
    }

    DllCall("CloseClipboard")
    return pBitmap
}

SSOK_CreateScaledBitmap(pBitmap, dstW, dstH)
{
    if (!pBitmap || dstW < 1 || dstH < 1)
        return 0
    pNew := Gdip_CreateBitmap(Round(dstW), Round(dstH))
    if (!pNew)
        return 0
    g := Gdip_GraphicsFromImage(pNew)
    if (!g)
    {
        Gdip_DisposeImage(pNew)
        return 0
    }
    Gdip_SetSmoothingMode(g, 4)
    Gdip_SetInterpolationMode(g, 7)
    Gdip_SetPixelOffsetMode(g, 2)
    DllCall("gdiplus\GdipDrawImageRectI", "Ptr", g, "Ptr", pBitmap, "Int", 0, "Int", 0, "Int", Round(dstW), "Int", Round(dstH))
    Gdip_DeleteGraphics(g)
    return pNew
}

Gdip_CreateBitmap(w, h)
{
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", pBitmap)
    return pBitmap
}

Gdip_SetInterpolationMode(pGraphics, mode := 7)
{
    return DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", pGraphics, "Int", mode)
}

Gdip_SetPixelOffsetMode(pGraphics, mode := 2)
{
    return DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", mode)
}

Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality := 95)
{
    if (!pBitmap || sOutput = "")
        return -1
    SplitPath, sOutput,,, ext
    StringLower, ext, ext
    mime := (ext = "png") ? "image/png" : "image/jpeg"
    if (!Gdip_GetEncoderClsid(mime, clsid))
        return -2

    ; JPG´Â ±âº» ¾ÐÃà·üÀÌ ³·¾Æ ±ÛÀÚ°¡ Èå¸´ÇØ º¸ÀÏ ¼ö ÀÖ¾î 95 Ç°Áú·Î ÀúÀåÇÕ´Ï´Ù.
    if (mime = "image/jpeg")
    {
        if (Quality < 1)
            Quality := 95
        if (Quality > 100)
            Quality := 100
        VarSetCapacity(encQuality, 16, 0)
        DllCall("ole32\CLSIDFromString", "WStr", "{1D5BE4B5-FA4A-452D-9CDD-5DB35105E7EB}", "Ptr", &encQuality)
        VarSetCapacity(qVal, 4, 0)
        NumPut(Quality, qVal, 0, "UInt")
        epSize := (A_PtrSize = 8) ? 40 : 32
        VarSetCapacity(encParams, epSize, 0)
        NumPut(1, encParams, 0, "UInt")
        pParam := &encParams + ((A_PtrSize = 8) ? 8 : 4)
        DllCall("RtlMoveMemory", "Ptr", pParam, "Ptr", &encQuality, "UPtr", 16)
        NumPut(1, pParam+16, "UInt")       ; NumberOfValues
        NumPut(4, pParam+20, "UInt")       ; EncoderParameterValueTypeLong
        NumPut(&qVal, pParam+24, "Ptr")    ; Value
        return DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", sOutput, "Ptr", &clsid, "Ptr", &encParams)
    }
    return DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", sOutput, "Ptr", &clsid, "Ptr", 0)
}

Gdip_GetEncoderClsid(mime, ByRef clsid)
{
    VarSetCapacity(clsid, 16, 0)
    DllCall("gdiplus\GdipGetImageEncodersSize", "UInt*", count, "UInt*", size)
    if (size < 1)
        return false
    VarSetCapacity(ci, size, 0)
    if (DllCall("gdiplus\GdipGetImageEncoders", "UInt", count, "UInt", size, "Ptr", &ci) != 0)
        return false
    itemSize := 48 + (7 * A_PtrSize)
    Loop, %count%
    {
        item := &ci + (A_Index - 1) * itemSize
        pMime := NumGet(item+0, 32 + 4 * A_PtrSize, "Ptr")
        sMime := StrGet(pMime, "UTF-16")
        if (sMime = mime)
        {
            DllCall("RtlMoveMemory", "Ptr", &clsid, "Ptr", item, "UPtr", 16)
            return true
        }
    }
    return false
}

Gdip_GraphicsFromImage(pBitmap)
{
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    return pGraphics
}

Gdip_DeleteGraphics(pGraphics)
{
    return DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
}

Gdip_SetSmoothingMode(pGraphics, mode := 4)
{
    return DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", mode)
}

Gdip_SetTextRenderingHint(pGraphics, hint := 4)
{
    return DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGraphics, "Int", hint)
}

Gdip_BrushCreateSolid(argb)
{
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", pBrush)
    return pBrush
}

Gdip_DeleteBrush(pBrush)
{
    return DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
}

Gdip_PenCreate(argb, width)
{
    DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", width, "Int", 2, "Ptr*", pPen)
    return pPen
}

Gdip_DeletePen(pPen)
{
    return DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
}

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h)
{
    return DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h)
{
    return DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
{
    return DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
{
    return DllCall("gdiplus\GdipDrawRectangle", "Ptr", pGraphics, "Ptr", pPen, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_FillPolygon(pGraphics, pBrush, x1, y1, x2, y2, x3, y3)
{
    VarSetCapacity(points, 24, 0)
    NumPut(x1, points, 0, "Float")
    NumPut(y1, points, 4, "Float")
    NumPut(x2, points, 8, "Float")
    NumPut(y2, points, 12, "Float")
    NumPut(x3, points, 16, "Float")
    NumPut(y3, points, 20, "Float")
    ; FillModeAlternate = 0
    return DllCall("gdiplus\GdipFillPolygon", "Ptr", pGraphics, "Ptr", pBrush, "Ptr", &points, "Int", 3, "Int", 0)
}

Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2)
{
    return DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", x1, "Float", y1, "Float", x2, "Float", y2)
}

Gdip_DrawImageRectRectI(pGraphics, pBitmap, dx, dy, dw, dh, sx, sy, sw, sh)
{
    return (DllCall("gdiplus\GdipDrawImageRectRectI"
        , "Ptr", pGraphics
        , "Ptr", pBitmap
        , "Int", dx
        , "Int", dy
        , "Int", dw
        , "Int", dh
        , "Int", sx
        , "Int", sy
        , "Int", sw
        , "Int", sh
        , "Int", 2
        , "Ptr", 0
        , "Ptr", 0
        , "Ptr", 0) = 0)
}

Gdip_GetPixel(pBitmap, x, y)
{
    DllCall("gdiplus\GdipBitmapGetPixel", "Ptr", pBitmap, "Int", x, "Int", y, "UInt*", argb)
    return argb
}

SSOK_GdipDrawCenteredText(pGraphics, text, x, y, w, h, fontName, fontSize, argb)
{
    hFamily := 0, hFont := 0, hFormat := 0, pBrush := 0
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "UShort", 0, "Ptr*", hFormat)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", hFormat, "Int", 1)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", hFormat, "Int", 1)
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", fontName, "Ptr", 0, "Ptr*", hFamily)
    if (!hFamily)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI Symbol", "Ptr", 0, "Ptr*", hFamily)
    if (!hFamily)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Arial", "Ptr", 0, "Ptr*", hFamily)
    if (!hFamily)
        return false
    DllCall("gdiplus\GdipCreateFont", "Ptr", hFamily, "Float", fontSize, "Int", 1, "Int", 2, "Ptr*", hFont)
    if (!hFont)
    {
        DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", hFamily)
        return false
    }
    pBrush := Gdip_BrushCreateSolid(argb)
    VarSetCapacity(rect, 16, 0)
    NumPut(x, rect, 0, "Float")
    NumPut(y, rect, 4, "Float")
    NumPut(w, rect, 8, "Float")
    NumPut(h, rect, 12, "Float")
    DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics, "WStr", text, "Int", -1, "Ptr", hFont, "Ptr", &rect, "Ptr", hFormat, "Ptr", pBrush)
    Gdip_DeleteBrush(pBrush)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", hFont)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", hFamily)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", hFormat)
    return true
}

SSOK_GdipDrawText(pGraphics, text, x, y, w, h, fontName, fontSize, argb, style := 1, align := 0, lineAlign := 0)
{
    hFamily := 0, hFont := 0, hFormat := 0, pBrush := 0
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "UShort", 0, "Ptr*", hFormat)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", hFormat, "Int", align)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", hFormat, "Int", lineAlign)
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", fontName, "Ptr", 0, "Ptr*", hFamily)
    if (!hFamily)
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Arial", "Ptr", 0, "Ptr*", hFamily)
    if (!hFamily)
        return false
    DllCall("gdiplus\GdipCreateFont", "Ptr", hFamily, "Float", fontSize, "Int", style, "Int", 2, "Ptr*", hFont)
    if (!hFont)
    {
        DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", hFamily)
        return false
    }
    pBrush := Gdip_BrushCreateSolid(argb)
    VarSetCapacity(rect, 16, 0)
    NumPut(x, rect, 0, "Float")
    NumPut(y, rect, 4, "Float")
    NumPut(w, rect, 8, "Float")
    NumPut(h, rect, 12, "Float")
    DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics, "WStr", text, "Int", -1, "Ptr", hFont, "Ptr", &rect, "Ptr", hFormat, "Ptr", pBrush)
    Gdip_DeleteBrush(pBrush)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", hFont)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", hFamily)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", hFormat)
    return true
}

; [SSOK GDI leak review: targeted safe-cleanup pass]

; ==============================================================================
; SSOK AI/OCR ¹Î°¨Á¤º¸ ÀÚµ¿ ¸¶½ºÅ·
; Windows OCR -> ´Ü¾îº° BoundingBox -> ¹Î°¨Á¤º¸ ÆÐÅÏ °Ë»ç -> ÀÚµ¿ ¸¶½ºÅ·
; ==============================================================================

SSOK_AutoMaskSensitiveInfo(pBitmap) {
    if (!pBitmap)
        return false

    tempImgPath := A_Temp . "\ssok_ocr_temp_" . A_TickCount . ".png"
    ocrOutput := ""
    G := 0
    pBrush := 0
    result := false

    ; 1. OCR¿ë ÀÓ½Ã ÀÌ¹ÌÁö ÀúÀå
    if (!Gdip_SaveBitmapToFile(pBitmap, tempImgPath))
        return false

    ; 2. Windows OCR
    psPath := StrReplace(tempImgPath, "'", "''")

    psScript =
    (
[Windows.Media.Ocr.OcrEngine, Windows.Foundation.Ocr, ContentType=WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime] | Out-Null
try {
    $file = [Windows.Storage.StorageFile]::GetFileFromPathAsync('__SSOK_PATH__').GetResults()
    $stream = $file.OpenAsync([Windows.Storage.FileAccessMode]::Read).GetResults()
    $decoder = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream).GetResults()
    $softwareBitmap = $decoder.GetSoftwareBitmapAsync().GetResults()
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguage()
    if ($null -eq $engine) { exit 2 }
    $ocrResult = $engine.RecognizeAsync($softwareBitmap).GetResults()
    foreach ($line in $ocrResult.Lines) {
        foreach ($word in $line.Words) {
            $rect = $word.BoundingRect
            $safeText = $word.Text -replace '\|', ''
            Write-Output ("{0}|{1}|{2}|{3}|{4}" -f $safeText, [int]$rect.X, [int]$rect.Y, [int]$rect.Width, [int]$rect.Height)
        }
    }
}
catch {
    exit 3
}
    )

    psScript := StrReplace(psScript, "__SSOK_PATH__", psPath)
    ocrOutput := SSOK_RunPowerShell(psScript)

    ; ÀÓ½ÃÆÄÀÏÀº OCR ¼º°ø/½ÇÆÐ¿Í °ü°è¾øÀÌ »èÁ¦
    FileDelete, %tempImgPath%

    if (!ocrOutput)
        return false

    ; 3. ¸¶½ºÅ· ±×·¡ÇÈ »ý¼º
    G := Gdip_GraphicsFromImage(pBitmap)
    if (!G)
        return false

    pBrush := Gdip_BrushCreateSolid(0xFF000000)
    if (!pBrush) {
        Gdip_DeleteGraphics(G)
        return false
    }

    ; 4. OCR °á°ú ºÐ¼®
    Loop, Parse, ocrOutput, `n, `r
    {
        line := Trim(A_LoopField)
        if (line == "")
            continue

        parts := StrSplit(line, "|")
        if (parts.MaxIndex() < 5)
            continue

        text := parts[1]
        x := parts[2] + 0
        y := parts[3] + 0
        w := parts[4] + 0
        h := parts[5] + 0

        if (w <= 0 || h <= 0)
            continue

        isSensitive := false

        ; ÁÖ¹Îµî·Ï¹øÈ£
        if RegExMatch(text, "^\d{6}-[1-4]\d{6}$")
            isSensitive := true

        ; ÈÞ´ëÀüÈ­¹øÈ£
        else if RegExMatch(text, "^01[016789]-?\d{3,4}-?\d{4}$")
            isSensitive := true

        ; ÀÏ¹Ý ÀüÈ­¹øÈ£
        else if RegExMatch(text, "^0(?:2|3[1-3]|4[1-4]|5[1-5]|6[1-4])-?\d{3,4}-?\d{4}$")
            isSensitive := true

        if (isSensitive) {
            pad := 2
            left := x - pad
            top := y - pad
            width := w + pad * 2
            height := h + pad * 2

            if (left < 0)
                left := 0
            if (top < 0)
                top := 0

            Gdip_FillRectangle(G, pBrush, left, top, width, height)
            result := true
        }
    }

    ; 5. GDI+ ÀÚ¿ø ÇØÁ¦
    if (pBrush)
        Gdip_DeleteBrush(pBrush)
    if (G)
        Gdip_DeleteGraphics(G)

    return result
}

; ------------------------------------------------------------------------------
; PowerShell ½ÇÇà
; EncodedCommand¸¦ »ç¿ëÇÏ¿© AHK/PowerShell µû¿ÈÇ¥ Ãæµ¹ ¹æÁö
; ------------------------------------------------------------------------------
SSOK_RunPowerShell(script) {
    if (script == "")
        return ""

    encoded := SSOK_PSEncode(script)
    if (encoded == "")
        return ""

    shell := ComObjCreate("WScript.Shell")
    if (!IsObject(shell))
        return ""

    exec := shell.Exec("powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand " . encoded)
    if (!IsObject(exec))
        return ""

    return exec.StdOut.ReadAll()
}

SSOK_PSEncode(text) {
    stream := ComObjCreate("ADODB.Stream")
    if (!IsObject(stream))
        return ""

    stream.Type := 2
    stream.Charset := "unicode"
    stream.Open()
    stream.WriteText(text)
    stream.Position := 0
    stream.Type := 1
    bytes := stream.Read()
    stream.Close()

    xml := ComObjCreate("MSXML2.DOMDocument.6.0")
    if (!IsObject(xml))
        return ""

    node := xml.createElement("b64")
    node.dataType := "bin.base64"
    node.nodeTypedValue := bytes
    return node.text
}
