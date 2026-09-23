; =========================================================
; SSOK ´ÜÃàÅ° Àç¹èÄ¡ ÄÄÆÑÆ® Á¤¸® ¹öÀü
; =========================================================

;@Ahk2Exe-SetDescription SSOK ¾÷¹« ´ÜÃàÅ° µµ¿ì¹Ì
;@Ahk2Exe-SetCompanyName ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»
;@Ahk2Exe-SetCopyright ÀÌ¸íÈ£
;@Ahk2Exe-SetProductName SSOK
;@Ahk2Exe-SetOrigFilename ssok.exe

global SSOK_VERSION := "260923"
global SSOK_VERSION_DATE := "2026.9.23"
global SSOK_COPYRIGHT_TEXT := "¨Ï ¼¼Á¾½Ã±³À°Ã» ÀÌ¸íÈ£(v." . SSOK_VERSION . ")"
global SSOK_PrintPauseActive := false
global SSOK_PrintPauseMenuText := "OZ Ãâ·Â ÀÏ½ÃÁ¤Áö/ÇØÁ¦"
global SSOK_CareerResultText := ""
global SSOK_CareerSelected := []

#MenuMaskKey vkE8


#NoEnv
#SingleInstance Force
SendMode Input
; ---------------------------------------------------------
; SSOK ÀÏ¹Ý ¾ÈÁ¤È­ ¼³Á¤
; - ÀÔ·Â/Ã¢ ÀüÈ¯/Å¬¸³º¸µå ÀÛ¾÷ÀÇ ¾ÈÁ¤¼ºÀ» ³ôÀÌ±â À§ÇÑ ±âº» Áö¿¬°ª
; - °ü¸®ÀÚ ±ÇÇÑ ÀÚµ¿»ó½ÂÀÌ³ª º¸¾È ¿ìÈ¸ ¸ñÀû ¼³Á¤Àº »ç¿ëÇÏÁö ¾ÊÀ½
; ---------------------------------------------------------
SetKeyDelay, 30, 50
SetMouseDelay, 30
SetControlDelay, 30
SetWinDelay, 100
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
SSOK_EnableDpiAwareness()
global SSOK_ConfigDir := SSOK_GetRuntimeConfigDir()
global SSOK_IniFile := SSOK_ConfigDir . "\ssok.ini"
if (A_IsCompiled)
    FileCreateDir, %SSOK_ConfigDir%
SSOK_MainLaunchMode := ""
if (IsObject(A_Args) && A_Args.Length() >= 1)
    SSOK_MainLaunchMode := A_Args[1]
OnExit, SSOK_MainExitCleanup
if (A_IsCompiled && SSOK_MainLaunchMode != "/installed" && SSOK_MainLaunchMode != "direct" && SSOK_MainLaunchMode != "direct-child")
    Gosub, SSOK_RelaunchFromCDriveInstall
if (SSOK_MainLaunchMode = "direct" || SSOK_MainLaunchMode = "direct-child")
{
    Gosub, SSOK_Capture_DirectChildStart
    return
}
Gosub, SSOK_PrepareFreshMainLaunch
SSOK_MainMutex := DllCall("CreateMutex", "Ptr", 0, "Int", true, "Str", "SSOK_Main_SingleInstance_Mutex", "Ptr")
if (A_LastError = 183)
{
    if (SSOK_MainMutex)
        DllCall("CloseHandle", "Ptr", SSOK_MainMutex)
    MsgBox, 64, SSOK ¾È³», SSOK(¿¡µàÆÄÀÎ µµ¿ì¹Ì)°¡ ÀÌ¹Ì ½ÇÇà ÁßÀÔ´Ï´Ù.`n`nÈ­¸é ¿À¸¥ÂÊ ¾Æ·¡(½Ã°è ¿·) Æ®·¹ÀÌ ¾ÆÀÌÄÜÀÌ³ª`n´ÜÃàÅ° [Win + F2]¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä., 5
    ExitApp
}
Gosub, SSOK_InstallBundledFiles
SSOK_FirstRunIniMissing := !FileExist(SSOK_IniFile)

Gosub, SSOK_InitRuntime

SSOK_EnableDpiAwareness()
{
    ; exe ½ÇÇà ½Ã µà¾ó ¸ð´ÏÅÍ/¹èÀ² È¯°æ¿¡¼­ Ä¸Ã³ ÁÂÇ¥°¡ ¾î±ß³ªÁö ¾Êµµ·Ï DPI ÀÎ½ÄÀ» ¸ÕÀú ÄÕ´Ï´Ù.
    if (DllCall("user32\SetProcessDpiAwarenessContext", "Ptr", -4, "Int"))
        return true
    if (DllCall("Shcore\SetProcessDpiAwareness", "Int", 2, "UInt") = 0)
        return true
    return DllCall("user32\SetProcessDPIAware", "Int")
}

; =========================================================
; AHK ¹èÆ÷/ÀÚµ¿½ÇÇà ¼³Á¤
; - »ç¿ëÀÚ°¡ ³»·Á¹ÞÀº ssok.ahk¸¦ ±×´ë·Î »ç¿ë
; - Windows ºÎÆÃ ½Ã AutoHotkey.exe·Î ÇöÀç ssok.ahk¸¦ ÀÚµ¿ ½ÇÇà
; - »õ ¹öÀüÀÇ ssok.ahk¸¦ ½ÇÇàÇÏ¸é ÀÚµ¿½ÇÇà ´ë»óµµ ÇöÀç ssok.ahk·Î °»½Å
; - ¿¹Àü SSOK ÀÚµ¿½ÇÇà ¹Ù·Î°¡±â/µî·Ï ÈçÀûÀº Á¤¸®
; =========================================================
Gosub, SSOK_StartupInstallAndAutoRun
SetTimer, SSOK_ShowSidebar, -300
SetTimer, SSOK_AI_TempCleanupNoonTick, 1200000
Gosub, SSOK_AI_TempCleanupNoonTick
SetTimer, SSOK_GlobalTempCleanupNoonTick, 1200000
Gosub, SSOK_GlobalTempCleanupNoonTick


; --- Win + F1 : ½î¿Á ºü¸¥ ÀÔ·Â µµ¿ì¹Ì ---
#F1::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF1
return

global SSOK_GlobalTempCleanupLastDate := ""

SSOK_GlobalGetPrivateWorkDir(subDir := "")
{
    root := A_LocalAppData "\SSOK\work"
    if (subDir != "")
        root := root "\" subDir
    FileCreateDir, %root%
    return root
}

SSOK_GlobalTempCleanupNoonTick:
SSOK_GlobalTempCleanupAtNoon()
return

SSOK_GlobalTempCleanupAtNoon()
{
    global SSOK_GlobalTempCleanupLastDate
    today := A_YYYY A_MM A_DD
    if (SSOK_GlobalTempCleanupLastDate = today)
        return true
    if (A_Hour != 12 || A_Min < 30)
        return true
    SSOK_GlobalTempCleanupLastDate := today
    return SSOK_GlobalTempCleanup(24, 2)
}

SSOK_MainExitCleanup:
SSOK_RunExitCleanup()
return

SSOK_RunExitCleanup()
{
    static done := false
    if (done)
        return true
    done := true

    if (IsFunc("SSOK_DestroyNumberOverlays"))
        SSOK_DestroyNumberOverlays()
    if (IsFunc("SSOK_DestroyNumberClickLayer"))
        SSOK_DestroyNumberClickLayer()
    if (IsFunc("SSOK_CancelDirectAreaCapture"))
        SSOK_CancelDirectAreaCapture(false)
    if (IsFunc("SSOK_ClearStampUndoStack"))
        SSOK_ClearStampUndoStack()
    if (IsFunc("SSOK_DisposeStampBitmap"))
        SSOK_DisposeStampBitmap()
    if (IsFunc("SSOK_StampCleanupSessionTempFiles"))
        SSOK_StampCleanupSessionTempFiles()
    if (IsFunc("SSOK_ShutdownGdip"))
        SSOK_ShutdownGdip()
    if (IsFunc("SSOK_ReleaseCaptureMutex"))
        SSOK_ReleaseCaptureMutex()

    SSOK_GlobalTempCleanup(24, 2)
    SSOK_ReleaseMainMutex()
    return true
}

SSOK_ReleaseMainMutex()
{
    global SSOK_MainMutex
    if (SSOK_MainMutex)
    {
        DllCall("ReleaseMutex", "Ptr", SSOK_MainMutex)
        DllCall("CloseHandle", "Ptr", SSOK_MainMutex)
        SSOK_MainMutex := 0
    }
    return true
}

SSOK_CleanupPrivateWorkRoot(workRoot, captureAgeHours := 24, xmlAgeHours := 1, draftAgeDays := 2)
{
    workRoot := RTrim(workRoot, "\/")
    if (workRoot = "" || !FileExist(workRoot))
        return false

    captureDir := workRoot . "\capture"
    if InStr(FileExist(captureDir), "D")
    {
        SSOK_GlobalDeleteOldFilesInDir(captureDir, captureAgeHours)
        SSOK_GlobalRemoveEmptyDirs(captureDir)
    }

    Loop, Files, %workRoot%\SSOK_AI_*Xml_*, D
        SSOK_GlobalRemoveOldDir(A_LoopFileFullPath, xmlAgeHours, "Hours")

    draftDir := workRoot . "\report_draft"
    if InStr(FileExist(draftDir), "D")
    {
        now := A_Now
        deleted := 0
        Loop, Files, %draftDir%\*.*, FR
        {
            FileGetTime, modified, %A_LoopFileFullPath%, M
            if (modified = "")
                continue
            age := now
            EnvSub, age, %modified%, Days
            if (age >= draftAgeDays)
            {
                FileDelete, %A_LoopFileFullPath%
                deleted++
                if (deleted >= 80)
                    break
            }
        }
        SSOK_GlobalRemoveEmptyDirs(draftDir)
        FileRemoveDir, %draftDir%
    }
    return true
}

SSOK_GlobalTempCleanup(captureAgeHours := 24, draftAgeDays := 2)
{
    return SSOK_CleanupPrivateWorkRoot(SSOK_GlobalGetPrivateWorkDir(), captureAgeHours, 1, draftAgeDays)
}

SSOK_GlobalDeleteOldFilesByPattern(dir, pattern, maxAgeHours := 24)
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

SSOK_GlobalDeleteOldFilesInDir(dir, maxAgeHours := 24, maxDeletes := 120)
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
            if (deleted >= maxDeletes)
                break
        }
    }
    return true
}

SSOK_GlobalRemoveOldDir(dir, maxAge := 1, unit := "Hours")
{
    if (dir = "" || !InStr(FileExist(dir), "D"))
        return false
    FileGetTime, modified, %dir%, M
    if (modified = "")
        return false
    age := A_Now
    EnvSub, age, %modified%, %unit%
    if (age >= maxAge)
        FileRemoveDir, %dir%, 1
    return true
}

SSOK_GlobalRemoveEmptyDirs(rootDir)
{
    if (rootDir = "" || !FileExist(rootDir))
        return false
    Loop, Files, %rootDir%\*.*, DR
        FileRemoveDir, %A_LoopFileFullPath%
    return true
}

SSOK_CopyClipboardText(ByRef outText, timeoutSeconds := 0.3, retries := 2, useInput := false)
{
    outText := ""
    Loop, %retries%
    {
        Clipboard := ""
        Sleep, 40
        if (useInput)
            SendInput, ^c
        else
            Send, ^c
        ClipWait, %timeoutSeconds%
        if (!ErrorLevel)
        {
            outText := Clipboard
            return true
        }
        Sleep, 80
    }
    return false
}

SSOK_SetClipboardTextWithWait(text, timeoutSeconds := 0.7, retries := 3)
{
    Loop, %retries%
    {
        Clipboard := ""
        Sleep, 30
        Clipboard := text
        ClipWait, %timeoutSeconds%
        if (!ErrorLevel)
            return true
        Sleep, 80
    }
    return false
}

SSOK_DoMoneyTool:
    SavedClipboard := ClipboardAll
    Clipboard := ""

    ; ====================================================
    ; 1. ºí·Ï ¼±ÅÃ ¿©ºÎ È®ÀÎ
    ; ====================================================
    SSOK_CopyClipboardText(selectedText, 0.2, 2)

    ; ----------------------------------------------------
    ; ºí·Ï ÁöÁ¤µÈ °æ¿ì: ¼±ÅÃÇÑ ºÎºÐ¸¸ ±Ý¾× º¯È¯
    ; ----------------------------------------------------
    if (selectedText != "")
    {
        num := RegExReplace(selectedText, "[^\d]", "")

        if (num = "")
        {
            Clipboard := SavedClipboard
            return
        }

        num := RegExReplace(num, "^0+")
        if (num = "")
            num := "0"

        formattedNum := Money_AddCommas(num)
        resultHan := Money_NumToKorean(num)

        finalResult := "±Ý" . formattedNum . "¿ø(±Ý" . resultHan . "¿ø)"

        if (!SSOK_SetClipboardTextWithWait(finalResult, 0.7, 3))
        {
            Clipboard := SavedClipboard
            return
        }
        Send, ^v
        Sleep, 150
        Clipboard := SavedClipboard
        return
    }

    ; ====================================================
    ; 2. ºí·Ï ¾øÀ¸¸é ÇöÀç ÁÙ ÀüÃ¼ ¼±ÅÃ
    ; ====================================================
    Send, {Home}
    Sleep, 30
    Send, +{End}
    Sleep, 50
    if (!SSOK_CopyClipboardText(originalText, 0.3, 3))
    {
        Clipboard := SavedClipboard
        return
    }

    if (originalText = "")
    {
        Clipboard := SavedClipboard
        return
    }

    ; ====================================================
    ; 3. ÇöÀç ÁÙ µÚÂÊ¿¡ ±ÛÀÚ°¡ ÀÖ´ÂÁö È®ÀÎ
    ;    - ´ÙÀ½ ÁÙ¿¡ ºÙÀÓ µî ±ÛÀÚ°¡ ÀÖÀ¸¸é .  ³¡. ¾È ºÙÀÓ
    ; ====================================================
    ; ÇöÀç ÁÙ ¼±ÅÃ ÇØÁ¦ ÈÄ ÁÙ ³¡À¸·Î ÀÌµ¿
    Send, {End}
    Sleep, 30

    ; ÇöÀç À§Ä¡ºÎÅÍ ¹®¼­ ³¡±îÁö ¼±ÅÃÇØ¼­ È®ÀÎ
    Send, +^{End}
    Sleep, 80
    if (!SSOK_CopyClipboardText(afterText, 0.3, 2))
    {
        Clipboard := SavedClipboard
        return
    }
    hasTextAfter := false

    ; µÚÂÊ¿¡ °ø¹é, ÁÙ¹Ù²Þ ¸»°í ½ÇÁ¦ ±ÛÀÚ°¡ ÀÖÀ¸¸é true
    if RegExMatch(afterText, "\S")
        hasTextAfter := true

    ; ´Ù½Ã ÇöÀç ÁÙ ¼±ÅÃ
    Send, {Left}
    Sleep, 30
    Send, {Home}
    Sleep, 30
    Send, +{End}
    Sleep, 50

    ; ====================================================
    ; 4. ¾Õ ¹øÈ£ º¸Á¸
   ; ¿¹:
    ; "  ³ª. ±Ý¾×: ±Ý1,210,000¿ø"
    ; prefix = "  ³ª. "
    ; body   = "±Ý¾×: ±Ý1,210,000¿ø"
    ; ====================================================
    prefix := ""
    body := originalText

    if RegExMatch(originalText, "^(\s*(\d+\.|[°¡-ÆR]\.)\s*)(.*)$", m)
    {
        prefix := m1
        body := m3
    }

    ; ====================================================
    ; 5. ±Ý¾× ¼ýÀÚ ÃßÃâ
    ; ====================================================
    num := RegExReplace(body, "[^\d]", "")

    if (num = "")
    {
        Clipboard := SavedClipboard
        Send, {Right}
        return
    }

    num := RegExReplace(num, "^0+")
    if (num = "")
        num := "0"

    formattedNum := Money_AddCommas(num)
    resultHan := Money_NumToKorean(num)

    ; ====================================================
    ; 6. ¼ýÀÚ¸¸ ÀÖ´Â ÁÙÀÎÁö È®ÀÎ
    ;    ¿¹: 320000 / 320,000¿ø / ±Ý320,000¿ø
    ;    ÀÌ·± °æ¿ì´Â "±Ý¾×:"°ú ".  ³¡."À» ºÙÀÌÁö ¾ÊÀ½
    ; ====================================================
    bareBody := Trim(body)
    bareBody := RegExReplace(bareBody, "\s+", "")
    bareBody := RegExReplace(bareBody, "\([^)]*\)", "")
    bareBody := RegExReplace(bareBody, ",", "")

    isBareAmountLine := false
    if RegExMatch(bareBody, "^(±Ý)?\d+¿ø?\.?$")
        isBareAmountLine := true

    ; ====================================================
    ; 7. °°Àº ÁÙ¿¡¼­ ±Ý¾× µÚ¿¡ ´Ù¸¥ ±ÛÀÚ°¡ ÀÖ´ÂÁö È®ÀÎ
    ;    ¿¹: ±Ý1,000¿ø    ºñ°í³»¿ë
    ;    ÀÌ·± °æ¿ìµµ .  ³¡. ¾È ºÙÀÓ
    ; ====================================================
    hasTextAfterInSameLine := false

    if RegExMatch(body, "([0-9][0-9,]*)\s*¿ø?\s*(.*)$", tailMatch)
    {
        tailText := tailMatch2

        ; ±âÁ¸ÀÇ ". ³¡."¸¸ ÀÖ´Â °æ¿ì´Â ½ÇÁ¦ ´ÙÀ½ ±ÛÀÚ·Î º¸Áö ¾ÊÀ½
        cleanedTail := RegExReplace(tailText, "^\s*\.?\s*³¡\.?\s*$", "")

        if RegExMatch(cleanedTail, "\S")
            hasTextAfterInSameLine := true
    }

    ; ====================================================
    ; 8. ÃÖÁ¾ ¹®±¸ ÀÛ¼º
    ;    - ¼ýÀÚ¸¸ ÀÖÀ¸¸é: ±Ý#,###¿ø(±ÝÇÑ±Û¿ø)
    ;    - ±Ý¾× ¹®¸ÆÀÌ¸é: ±Ý¾×: ±Ý#,###¿ø(±ÝÇÑ±Û¿ø)
    ;    - µÚ¿¡ ±ÛÀÚ°¡ ¾øÀ» ¶§¸¸ ".  ³¡." ºÙÀÓ
    ; ====================================================
    if (isBareAmountLine)
    {
        finalResult := prefix . "±Ý" . formattedNum . "¿ø(±Ý" . resultHan . "¿ø)"
    }
    else
    {
        ending := ""

        if (!hasTextAfter && !hasTextAfterInSameLine)
            ending := ".  ³¡."

        finalResult := prefix . "±Ý¾×: ±Ý" . formattedNum . "¿ø(±Ý" . resultHan . "¿ø)" . ending
    }

    if (!SSOK_SetClipboardTextWithWait(finalResult, 0.7, 3))
    {
        Clipboard := SavedClipboard
        return
    }
    Send, ^v
    Sleep, 150
    Clipboard := SavedClipboard
return


Money_AddCommas(num)
{
    return RegExReplace(num, "\G\d+?(?=(\d{3})+(?!\d))", "$0,")
}

SSOK_DoCommaToggle:
    SavedClipboard := ClipboardAll
    if (!SSOK_CopyClipboardText(selectedText, 0.3, 2) || selectedText = "")
    {
        Clipboard := SavedClipboard
        return
    }

    if !RegExMatch(selectedText, "s)^([ `t`r`n]*)([+-]?[0-9,]+)([ `t`r`n]*)$", m)
    {
        Clipboard := SavedClipboard
        return
    }

    numberText := m2
    rawNumber := RegExReplace(numberText, ",", "")
    if !RegExMatch(rawNumber, "^[+-]?\d+$")
    {
        Clipboard := SavedClipboard
        return
    }

    if InStr(numberText, ",")
        resultText := rawNumber
    else
    {
        signText := ""
        absNumber := rawNumber
        if (SubStr(absNumber, 1, 1) = "+" || SubStr(absNumber, 1, 1) = "-")
        {
            signText := SubStr(absNumber, 1, 1)
            absNumber := SubStr(absNumber, 2)
        }
        resultText := signText . Money_AddCommas(absNumber)
    }

    if (!SSOK_SetClipboardTextWithWait(m1 . resultText . m3, 0.7, 3))
    {
        Clipboard := SavedClipboard
        return
    }
    Send, ^v
    Sleep, 120
    Clipboard := SavedClipboard
return

Money_NumToKorean(num)
{
    hanDigit0 := ""
    hanDigit1 := "ÀÏ"
    hanDigit2 := "ÀÌ"
    hanDigit3 := "»ï"
    hanDigit4 := "»ç"
    hanDigit5 := "¿À"
    hanDigit6 := "À°"
    hanDigit7 := "Ä¥"
    hanDigit8 := "ÆÈ"
    hanDigit9 := "±¸"

    hanUnit0 := ""
    hanUnit1 := "½Ê"
    hanUnit2 := "¹é"
    hanUnit3 := "Ãµ"

    hanLarge0 := ""
    hanLarge1 := "¸¸"
    hanLarge2 := "¾ï"
    hanLarge3 := "Á¶"
    hanLarge4 := "°æ"

    resultHan := ""
    len := StrLen(num)

    Loop, %len%
    {
        pos := A_Index
        idx := len - pos
        digit := SubStr(num, pos, 1)

        if (digit != "0")
        {
            currDigit := hanDigit%digit%
            unitIndex := Mod(idx, 4)
            currUnit := hanUnit%unitIndex%
            resultHan .= currDigit . currUnit
        }

        if (Mod(idx, 4) = 0)
        {
            groupStart := pos - Mod(pos - 1, 4)
            groupText := SubStr(num, groupStart, pos - groupStart + 1)

            if (RegExReplace(groupText, "0", "") != "")
            {
                largeIndex := idx // 4
                currLarge := hanLarge%largeIndex%
                resultHan .= currLarge
            }
        }
    }

    return resultHan
}



RemoveToolTip:
    ToolTip
return



; --- Win + F2 : ¹°Ç°¡¤¿ë¿ª¡¤±âÅ¸¡¤¼¼ÀÔ¡¤ÀÏ¹Ý µî ÀÚµ¿ ¹®¼­ Á¤¸® ---
#F2::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF2
return

SSOK_DoDateTool:
    SavedClipboard := ClipboardAll
    SSOK_CopyClipboardText(selectedRaw, 0.2, 2)
    selected := Trim(selectedRaw)

    if (selected != "")
    {
        text := selected

        ; µû¿ÈÇ¥ Á¦°Å
        text := StrReplace(text, "'", "")
        text := StrReplace(text, "¡¯", "")
        text := StrReplace(text, "¡®", "")
        text := StrReplace(text, "¡°", "")
        text := StrReplace(text, "¡±", "")
        text := StrReplace(text, "``", "")

        ; ==============================
        ; 1. ³¯Â¥ ¹üÀ§ Ã³¸® (ÃÖ¿ì¼±)
        ; ==============================
        rangeText := RegExReplace(text, "\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]?\)", "")
        rangeText := RegExReplace(rangeText, "\(\s*ÃÑ\s*[\d,]+\s*ÀÏ\s*\)", "")
        rangeText := RegExReplace(rangeText, ",\s*[\d,]+\s*ÀÏ°£", "")
        rangeText := RegExReplace(rangeText, "\s+", "")

        if (RegExMatch(rangeText, "^(\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?[-~](\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?$", m))
        {
            y1 := m1, mo1 := m2, d1 := m3
            y2 := m4, mo2 := m5, d2 := m6

            if (StrLen(y1) = 2)
                y1 := (y1 + 0 > 30) ? "19" . y1 : "20" . y1
            if (StrLen(y2) = 2)
                y2 := (y2 + 0 > 30) ? "19" . y2 : "20" . y2

            startDate := y1 . Format("{:02}", mo1) . Format("{:02}", d1)
            endDate   := y2 . Format("{:02}", mo2) . Format("{:02}", d2)

            temp := endDate
            EnvSub, temp, %startDate%, Days
            totalDays := temp + 1

            ; ¿äÀÏ °è»ê
            FormatTime, wd1, %startDate%, WDay
            FormatTime, wd2, %endDate%, WDay
            wdays := ["ÀÏ", "¿ù", "È­", "¼ö", "¸ñ", "±Ý", "Åä"]
            korWd1 := wdays[wd1]
            korWd2 := wdays[wd2]

            ; ³¯Â¥ Ç¥ÁØ Æ÷¸ËÀ¸·Î ÀçÁ¶ÇÕ (¿äÀÏ °ËÅä¡¤¼öÁ¤ Æ÷ÇÔ)
            startFmt := y1 . ". " . (mo1 + 0) . ". " . (d1 + 0) . ".(" . korWd1 . ")"
            endFmt   := y2 . ". " . (mo2 + 0) . ". " . (d2 + 0) . ".(" . korWd2 . ")"

            ; totalDays ÄÞ¸¶ Æ÷¸Ë (3ÀÚ¸® ²÷±â)
            totalDaysComma := AddComma(totalDays)

            result := startFmt . "~" . endFmt . ", " . totalDaysComma . "ÀÏ°£"

            Clipboard := result
            Send, ^v
            Sleep, 100
            Clipboard := SavedClipboard
            return
        }

        ; ==============================
        ; 2. ´ÜÀÏ ³¯Â¥ ¿äÀÏ °è»ê (±âÁ¸ ±â´É)
        ; ==============================
        text := RegExReplace(text, "\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]?\)", "")
        text := RegExReplace(text, "\s+", "")

        if (RegExMatch(text, "^(\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?$", m))
        {
            yy := m1
            mm := m2
            dd := m3

            if (StrLen(yy) = 2)
                yyyy := (yy + 0 > 30) ? "19" . yy : "20" . yy
            else
                yyyy := yy

            dateForCalc := yyyy . Format("{:02}", mm) . Format("{:02}", dd)

            FormatTime, WDay, %dateForCalc%, WDay
            days := ["ÀÏ", "¿ù", "È­", "¼ö", "¸ñ", "±Ý", "Åä"]
            korWDay := days[WDay]

            result := yyyy . ". " . mm . ". " . dd . ".(" . korWDay . ")"

            Clipboard := result
            Send, ^v
            Sleep, 100
            Clipboard := SavedClipboard
            return
        }

        Clipboard := SavedClipboard
        return
    }

    ; ==============================
    ; 3. ¼±ÅÃ ¾øÀ¸¸é ¿À´Ã ³¯Â¥
    ; ==============================
    FormatTime, yyyy,, yyyy
    FormatTime, mm,, M
    FormatTime, dd,, d
    FormatTime, WDay,, WDay

    days := ["ÀÏ", "¿ù", "È­", "¼ö", "¸ñ", "±Ý", "Åä"]
    korWDay := days[WDay]

    result := yyyy . ". " . mm . ". " . dd . ".(" . korWDay . ")"

    Clipboard := result
    Send, ^v
    Sleep, 100
    Clipboard := SavedClipboard
return



























































; --- #F5:: SSOK ¿øÅ¬¸¯ ¹®¼­ Á¤¸® ---
; =========================================================
; ½î¿Á for K-¿¡µàÆÄÀÎ (SSOK-Sejong Smart One Key)
; ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ±³Á÷¿øÀ» À§ÇÑ K-¿¡µàÆÄÀÎ ¿øÅ° Á¤¸®±â
; AutoHotkey v1.1 Àü¿ë
; =========================================================

SSOK_ShowFirstRunNotice:
    SSOK_FirstRunNoticeText := "º» ÇÁ·Î±×·¥Àº K-¿¡µàÆÄÀÎ ¾÷¹« º¸Á¶ µµ±¸·Î, ÃÖÃÊ ½ÇÇà ½Ã V3¿¡¼­ º¸¾È ¾Ë¸²ÀÌ ¶ã ¼ö ÀÖ½À´Ï´Ù.`n`nÀÌ´Â µðÁöÅÐ ¼­¸í ÀÎÁõ ÀýÂ÷ ¶§¹®ÀÌ¸ç, 'Çã¿ë ¶Ç´Â ½ÇÇà ÈÄ ´ÙÀ½ºÎÅÍ ¹¯Áö ¾ÊÀ½'À» ´©¸£½Ã¸é Á¤»óÀûÀ¸·Î »ç¿ë °¡´ÉÇÕ´Ï´Ù.`n`n¶ÇÇÑ ¾÷¹« ÆíÀÇ¸¦ À§ÇØ ¸ÅÀÏ PC ½ÃÀÛ ½Ã ÀÚµ¿ ½ÇÇàµÇµµ·Ï µî·ÏµË´Ï´Ù.`n`n¿øÇÏÁö ¾ÊÀ¸½Ã¸é  ÁýÁß¸ðµå ¸Þ´ºÀÇ ÇÏ´Ü¿¡¼­ [Á¾·á]¸¦ ´©¸£½Ã¸é ÀÚµ¿ ÇØÁ¦µË´Ï´Ù."
    MsgBox, 64, SSOK ¾È³», %SSOK_FirstRunNoticeText%
return


SSOK_InitRuntime:
    APP_TITLE := "½î¿Á for K-¿¡µàÆÄÀÎ"
    APP_TITLE_SUB := "(SSOK-Sejong Smart One Key)"
    APP_FULL_TITLE := "½î¿Á for K-¿¡µàÆÄÀÎ (SSOK-Sejong Smart One Key)"

    SavedClip := ""
    TargetHwnd := ""
    DOC_TempDotInserted := false   ; ºó ¹®¼­ Win+F2 ¸Þ´º Ç¥½Ã¿ë ÀÓ½Ã ¸¶Ä§Ç¥ »èÁ¦ ÇÃ·¡±×
    DOC_EXPR := ""
    DOC_POS := 1

    SSOK_SidebarVisible := 0
    SSOK_SidebarMiniVisible := 0
    SSOK_SidebarHwnd := ""
    SSOK_SidebarMiniHwnd := ""
    SSOK_SidebarTargetHwnd := ""
    SSOK_SidebarCustomPos := 0
    SSOK_SidebarSavedX := ""
    SSOK_SidebarSavedY := ""
    SSOK_SidebarSavedW := ""
    SSOK_SidebarMinW := 112
    SSOK_SidebarResizeReady := 0
    SSOK_SidebarMiniX := ""
    SSOK_SidebarMiniY := ""
    SSOK_AdvancedCustomPos := 0
    SSOK_AdvancedSavedX := ""
    SSOK_AdvancedSavedY := ""
    SSOK_ReminderLastKey := ""
    SSOK_AlarmLastKey := ""
    SSOK_Alarm2Enabled := 1
    SSOK_LastPowerOffKey := ""
    SSOK_QuitAlarmTargetStamp := ""
    SSOK_PosIni := SSOK_IniFile
    if FileExist(SSOK_PosIni)
    {
        IniRead, SSOK_ReadSidebarCustomPos, %SSOK_PosIni%, SidebarPosition, CustomPos, 0
        IniRead, SSOK_ReadSidebarX, %SSOK_PosIni%, SidebarPosition, X, __SSOK_EMPTY__
        IniRead, SSOK_ReadSidebarY, %SSOK_PosIni%, SidebarPosition, Y, __SSOK_EMPTY__
        IniRead, SSOK_ReadSidebarW, %SSOK_PosIni%, SidebarPosition, Width, __SSOK_EMPTY__
        if (SSOK_ReadSidebarCustomPos = 1 && SSOK_ReadSidebarX != "__SSOK_EMPTY__" && SSOK_ReadSidebarY != "__SSOK_EMPTY__")
        {
            SSOK_SidebarCustomPos := 1
            SSOK_SidebarSavedX := SSOK_ReadSidebarX + 0
            SSOK_SidebarSavedY := SSOK_ReadSidebarY + 0
        }
        if (SSOK_ReadSidebarW != "__SSOK_EMPTY__" && SSOK_ReadSidebarW + 0 >= SSOK_SidebarMinW)
            SSOK_SidebarSavedW := SSOK_ReadSidebarW + 0
        IniRead, SSOK_ReadAdvancedCustomPos, %SSOK_PosIni%, HiddenMenuPosition, CustomPos, 0
        IniRead, SSOK_ReadAdvancedX, %SSOK_PosIni%, HiddenMenuPosition, X, __SSOK_EMPTY__
        IniRead, SSOK_ReadAdvancedY, %SSOK_PosIni%, HiddenMenuPosition, Y, __SSOK_EMPTY__
        if (SSOK_ReadAdvancedCustomPos = 1 && SSOK_ReadAdvancedX != "__SSOK_EMPTY__" && SSOK_ReadAdvancedY != "__SSOK_EMPTY__")
        {
            SSOK_AdvancedCustomPos := 1
            SSOK_AdvancedSavedX := SSOK_ReadAdvancedX + 0
            SSOK_AdvancedSavedY := SSOK_ReadAdvancedY + 0
        }
    }

    Menu, Tray, Tip, %APP_FULL_TITLE%
    Menu, Tray, NoStandard
    Menu, Tray, Add, »çÀÌµå¹Ù ¹Ù·Îº¸±â, SSOK_Sidebar_ShowButton
    Menu, Tray, Add, %SSOK_PrintPauseMenuText%, SSOK_TrayTogglePrintPause
    Menu, Tray, Add, SSOK Æú´õ ¿­±â, SSOK_TrayOpenFolder
    Menu, Tray, Add, ÀÚµ¿½ÇÇà ÇØÁ¦, SSOK_TrayDisableAutoRun
    Menu, Tray, Add, ¸ÅÀÏ½ÇÇà »èÁ¦, SSOK_TrayPrepareMoveOrDelete
    Menu, Tray, Add
    Menu, Tray, Add, ¿©ºñÁ¤»ê½ÅÃ»¼­, SSOK_TrayOpenTravel
    Menu, Tray, Add, Á¾·á, SSOK_TrayExit
    Menu, Tray, Default, »çÀÌµå¹Ù ¹Ù·Îº¸±â
    SetTimer, SSOK_CheckMajorTodoReminder, 30000
    SetTimer, SSOK_CheckPowerOffSchedule, 30000
    SSOK_RefreshWakeTaskFromIni()
return



; =========================================================
; Win + F4 : ÆÄÀÏ ¿­±â
; - ±â¾È¹®/°èÈ¹¼­ ÇÁ·ÒÇÁÆ® ¹®±¸´Â ¼öÁ¤ÇÏÁö ¾ÊÀ½
; - ±âÁ¸ °¡·ÎÇü ÀüÃ¼ ¸Þ´º´Â »ç¿ëÇÏÁö ¾ÊÀ½
; - »çÀÌµå¹Ù ¹öÆ°Àº ±âÁ¸ ÇÙ½É ±â´É ¶óº§¸¸ ±×´ë·Î È£Ãâ
; =========================================================
#F4::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF5
return

SSOK_DoF4:
    SSOK_AllMenuTargetHwnd := WinExist("A")
    SSOK_SidebarTargetHwnd := SSOK_AllMenuTargetHwnd
    Gosub, SSOK_ShowSidebar
return

SSOK_ShowAllFunctionMenu:
    Gosub, SSOK_ShowSidebar
return

SSOK_ShowSidebar:
    if (SSOK_SidebarTargetHwnd = "")
        SSOK_SidebarTargetHwnd := WinExist("A")

    SysGet, SSOK_WorkArea, MonitorWorkArea
    SSOK_WorkAreaH := SSOK_WorkAreaBottom - SSOK_WorkAreaTop
    SSOK_SidebarMinW := 112
    SSOK_SidebarMaxW := SSOK_WorkAreaRight - SSOK_WorkAreaLeft - 16
    if (SSOK_SidebarMaxW < SSOK_SidebarMinW)
        SSOK_SidebarMaxW := SSOK_SidebarMinW
    SSOK_SidebarW := SSOK_SidebarMinW
    if (SSOK_SidebarSavedW != "")
        SSOK_SidebarW := SSOK_SidebarSavedW + 0
    if (SSOK_SidebarW < SSOK_SidebarMinW)
        SSOK_SidebarW := SSOK_SidebarMinW
    if (SSOK_SidebarW > SSOK_SidebarMaxW)
        SSOK_SidebarW := SSOK_SidebarMaxW
    SSOK_SidebarSavedW := SSOK_SidebarW
    SSOK_DefaultSidebarX := SSOK_WorkAreaRight - SSOK_SidebarW - 68
    SSOK_SidebarTopGap := 116
    SSOK_SidebarH := 760
    if (SSOK_SidebarH > SSOK_WorkAreaH - SSOK_SidebarTopGap - 12)
        SSOK_SidebarH := SSOK_WorkAreaH - SSOK_SidebarTopGap - 12
    SSOK_DefaultSidebarY := SSOK_WorkAreaTop + SSOK_SidebarTopGap
    if (SSOK_SidebarCustomPos = 1)
    {
        SSOK_SidebarX := SSOK_SidebarSavedX
        SSOK_SidebarY := SSOK_SidebarSavedY
    }
    else
    {
        SSOK_SidebarX := SSOK_DefaultSidebarX
        SSOK_SidebarY := SSOK_DefaultSidebarY
    }
    if (SSOK_SidebarX < SSOK_WorkAreaLeft)
        SSOK_SidebarX := SSOK_WorkAreaLeft
    if (SSOK_SidebarX > SSOK_WorkAreaRight - SSOK_SidebarW)
        SSOK_SidebarX := SSOK_WorkAreaRight - SSOK_SidebarW
    if (SSOK_SidebarY < SSOK_WorkAreaTop)
        SSOK_SidebarY := SSOK_WorkAreaTop
    if (SSOK_SidebarY > SSOK_WorkAreaBottom - SSOK_SidebarH)
        SSOK_SidebarY := SSOK_WorkAreaBottom - SSOK_SidebarH
    SSOK_BottomY := SSOK_SidebarH - 92
    SSOK_HideY := SSOK_BottomY + 4
    SSOK_CopyY1 := SSOK_SidebarH - 35
    SSOK_CopyY2 := SSOK_SidebarH - 26
    SSOK_CopyY3 := SSOK_SidebarH - 17
    SSOK_SidebarCaptionW := SSOK_SidebarW - 15
    SSOK_SidebarButtonW := SSOK_SidebarW - 16
    SSOK_SidebarBtnF1W := SSOK_SidebarButtonW - 32
    if (SSOK_SidebarBtnF1W < 50)
        SSOK_SidebarBtnF1W := 50
    SSOK_SidebarCalcX := 8 + SSOK_SidebarBtnF1W + 2
    SSOK_SidebarCalcW := SSOK_SidebarButtonW - SSOK_SidebarBtnF1W - 2
    if (SSOK_SidebarCalcW < 26)
        SSOK_SidebarCalcW := 26
    SSOK_SidebarSepW := SSOK_SidebarW - 24
    SSOK_SidebarFooterW := SSOK_SidebarW - 4
    SSOK_SidebarOrgEditW := SSOK_SidebarW - 52
    if (SSOK_SidebarOrgEditW < 60)
        SSOK_SidebarOrgEditW := 60
    SSOK_SidebarSmallButtonW := Floor((SSOK_SidebarW - 17) / 5)
    if (SSOK_SidebarSmallButtonW < 19)
        SSOK_SidebarSmallButtonW := 19
    SSOK_SidebarSmallButtonX1 := 8
    SSOK_SidebarSmallButtonX2 := SSOK_SidebarSmallButtonX1 + SSOK_SidebarSmallButtonW + 1
    SSOK_SidebarSmallButtonX3 := SSOK_SidebarSmallButtonX2 + SSOK_SidebarSmallButtonW + 1
    SSOK_SidebarSmallButtonX4 := SSOK_SidebarSmallButtonX3 + SSOK_SidebarSmallButtonW + 1
    SSOK_SidebarSmallButtonX5 := SSOK_SidebarSmallButtonX4 + SSOK_SidebarSmallButtonW + 1
    SSOK_SidebarAIButtonW := Floor((SSOK_SidebarW - 22) / 2)
    if (SSOK_SidebarAIButtonW < 45)
        SSOK_SidebarAIButtonW := 45
    SSOK_SidebarAIButtonX1 := 9
    SSOK_SidebarAIButtonX2 := SSOK_SidebarAIButtonX1 + SSOK_SidebarAIButtonW + 5
    SSOK_SidebarAIConvert1X := Floor(SSOK_SidebarW / 2) - 32
    SSOK_SidebarAIConvert2X := Floor(SSOK_SidebarW / 2) + 18
    SSOK_QASearchGap := 2
    SSOK_QASearchW := Floor((SSOK_SidebarButtonW - SSOK_QASearchGap) / 2)
    if (SSOK_QASearchW < 44)
        SSOK_QASearchW := 44
    SSOK_QASearchX1 := 8
    SSOK_QASearchX2 := SSOK_QASearchX1 + SSOK_QASearchW + SSOK_QASearchGap
    SSOK_QFMainButtonW := 64
    SSOK_QFSearchX := 70
    SSOK_QFSearchW := SSOK_SidebarW - 77
    if (SSOK_QFSearchW < 30)
        SSOK_QFSearchW := 30
    SSOK_QUMainButtonW := 60
    SSOK_QUSearchX := 69
    SSOK_QUSearchW := SSOK_SidebarW - 76
    if (SSOK_QUSearchW < 30)
        SSOK_QUSearchW := 30
    SSOK_AlarmTimeW := SSOK_SidebarW - 58
    if (SSOK_AlarmTimeW < 54)
        SSOK_AlarmTimeW := 54
    SSOK_PCOffW := SSOK_SidebarW - 36
    if (SSOK_PCOffW < 76)
        SSOK_PCOffW := 76
    SSOK_SettingsX := SSOK_SidebarW - 25
    SSOK_SidebarShortcutChars := 1
    if (SSOK_SidebarW >= 170)
        SSOK_SidebarShortcutChars := 2
    if (SSOK_SidebarW >= 250)
        SSOK_SidebarShortcutChars := 3

    Gui, SSOKSideMini:Destroy
    SSOK_SidebarMiniVisible := 0

    Gui, SSOKSide:Destroy
    Gui, SSOKSide:+AlwaysOnTop +ToolWindow -Caption +Border +Resize +HwndSSOK_SidebarHwnd
    Gui, SSOKSide:Color, F7FBFF
    Gui, SSOKSide:Margin, 0, 0
    Gui, SSOKSide:+MinSize%SSOK_SidebarMinW%x%SSOK_SidebarH%
    Gui, SSOKSide:+MaxSize%SSOK_SidebarMaxW%x%SSOK_SidebarH%

    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Text, x11 y8 w16 h14 cE53935 Center gSSOK_Sidebar_StartMove, ½ï
    Gui, SSOKSide:Add, Text, x26 y8 w5 h14 cF4511E Center gSSOK_Sidebar_StartMove, (
    Gui, SSOKSide:Add, Text, x31 y8 w7 h14 cFB8C00 Center gSSOK_Sidebar_StartMove, S
    Gui, SSOKSide:Add, Text, x38 y8 w7 h14 cFDD835 Center gSSOK_Sidebar_StartMove, S
    Gui, SSOKSide:Add, Text, x45 y8 w7 h14 c43A047 Center gSSOK_Sidebar_StartMove, O
    Gui, SSOKSide:Add, Text, x52 y8 w7 h14 c00ACC1 Center gSSOK_Sidebar_StartMove, K
    Gui, SSOKSide:Add, Text, x59 y8 w5 h14 c1E88E5 Center gSSOK_Sidebar_StartMove, )
    Gui, SSOKSide:Font, s5 bold, Malgun Gothic
    Gui, SSOKSide:Add, Text, x65 y10 w12 h10 c3949AB Center gSSOK_Sidebar_StartMove, for
    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Text, x77 y8 w7 h14 c5E35B1 Center gSSOK_Sidebar_StartMove, ¿¡
    Gui, SSOKSide:Add, Text, x84 y8 w7 h14 c7B1FA2 Center gSSOK_Sidebar_StartMove, µà
    Gui, SSOKSide:Add, Text, x91 y8 w7 h14 c8E24AA Center gSSOK_Sidebar_StartMove, ÆÄ
    Gui, SSOKSide:Add, Text, x98 y8 w7 h14 c6A1B9A Center gSSOK_Sidebar_StartMove, ÀÎ
    IniRead, SSOK_OrgName, %SSOK_IniFile%, MajorTodos, OrgName, µµ´ãÁßÇÐ±³
    SSOK_OrgName := Trim(SSOK_OrgName)
    if (SSOK_OrgName = "")
        SSOK_OrgName := "µµ´ãÁßÇÐ±³"
    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x8 y27 w34 h12 c6B7280 Right gSSOK_EDU_OpenOrgPicker, ±â°ü¸í
    Gui, SSOKSide:Font, s6 norm c6B7280, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x45 y24 w%SSOK_SidebarOrgEditW% h18 vSSOK_OrgNameEdit gSSOK_SaveOrgName, %SSOK_OrgName%

    Gosub, QI_Init
    Gosub, QI_LoadTexts
    Gosub, SSOK_QF_LoadKeywords
    Gosub, SSOK_QU_LoadUrls
    Gosub, SSOK_AI_LoadSites
    SSOK_SideQI1 := SSOK_Sidebar_FirstCharLabel(QIText1, "1", SSOK_SidebarShortcutChars)
    SSOK_SideQI2 := SSOK_Sidebar_FirstCharLabel(QIText2, "2", SSOK_SidebarShortcutChars)
    SSOK_SideQI3 := SSOK_Sidebar_FirstCharLabel(QIText3, "3", SSOK_SidebarShortcutChars)
    SSOK_SideQI4 := SSOK_Sidebar_FirstCharLabel(QIText4, "4", SSOK_SidebarShortcutChars)
    SSOK_SideQI5 := SSOK_Sidebar_FirstCharLabel(QIText5, "5", SSOK_SidebarShortcutChars)
    SSOK_SideQF1 := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text1, "1", SSOK_SidebarShortcutChars)
    SSOK_SideQF2 := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text2, "2", SSOK_SidebarShortcutChars)
    SSOK_SideQF3 := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text3, "3", SSOK_SidebarShortcutChars)
    SSOK_SideQF4 := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text4, "4", SSOK_SidebarShortcutChars)
    SSOK_SideQF5 := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text5, "5", SSOK_SidebarShortcutChars)
    SSOK_SideQU1 := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name1, "1", SSOK_SidebarShortcutChars)
    SSOK_SideQU2 := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name2, "2", SSOK_SidebarShortcutChars)
    SSOK_SideQU3 := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name3, "3", SSOK_SidebarShortcutChars)
    SSOK_SideQU4 := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name4, "4", SSOK_SidebarShortcutChars)
    SSOK_SideQU5 := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name5, "5", SSOK_SidebarShortcutChars)
    SSOK_SideAI1 := SSOK_Sidebar_FirstCharLabel(SSOK_AI_SiteName1, "C", SSOK_SidebarShortcutChars)
    SSOK_SideAI2 := SSOK_Sidebar_FirstCharLabel(SSOK_AI_SiteName2, "G", SSOK_SidebarShortcutChars)
    SSOK_SideAI3 := SSOK_Sidebar_FirstCharLabel(SSOK_AI_SiteName3, "C", SSOK_SidebarShortcutChars)
    SSOK_SideAI4 := SSOK_Sidebar_FirstCharLabel(SSOK_AI_SiteName4, "P", SSOK_SidebarShortcutChars)
    SSOK_SideAI5 := SSOK_Sidebar_FirstCharLabel(SSOK_AI_SiteName5, "C", SSOK_SidebarShortcutChars)

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x8 y53 w%SSOK_SidebarCaptionW% h12 vSSOK_SidebarHintF1 c6B7280 Center gSSOK_Sidebar_F1, Win + F1
    Gui, SSOKSide:Font, s9 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y66 w%SSOK_SidebarBtnF1W% h25 vSSOK_SidebarBtnF1 gSSOK_Sidebar_F1, ºü¸¥ ÀÔ·Â
    Gui, SSOKSide:Font, s8 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarCalcX% y66 w%SSOK_SidebarCalcW% h25 vSSOK_SidebarBtnCalc gSSOK_Sidebar_Calc, °è»ê
    Gui, SSOKSide:Font, s9 bold, Malgun Gothic
    Gui, SSOKSide:Font, s8 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX1% y93 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQI1 gSSOK_Sidebar_QI1, %SSOK_SideQI1%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX2% y93 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQI2 gSSOK_Sidebar_QI2, %SSOK_SideQI2%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX3% y93 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQI3 gSSOK_Sidebar_QI3, %SSOK_SideQI3%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX4% y93 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQI4 gSSOK_Sidebar_QI4, %SSOK_SideQI4%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX5% y93 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQI5 gSSOK_Sidebar_QI5, %SSOK_SideQI5%

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Progress, x12 y123 w%SSOK_SidebarSepW% h1 vSSOK_SidebarSepF2 BackgroundE6EAEE cE6EAEE
    Gui, SSOKSide:Add, Text, x8 y131 w%SSOK_SidebarCaptionW% h12 vSSOK_SidebarHintF2 c6B7280 Center gSSOK_Sidebar_F2, Win + F2
    Gui, SSOKSide:Font, s9 bold c005BAC, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y144 w%SSOK_SidebarBtnF1W% h25 vSSOK_SidebarBtnDraft gSSOK_Sidebar_Draft, °£´Ü ÀÛ¼º
    Gui, SSOKSide:Font, s8 bold c005BAC, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarCalcX% y144 w%SSOK_SidebarCalcW% h25 vSSOK_SidebarBtnExpense gSSOK_Sidebar_Expense, Ç°ÀÇ

    ; ÇÑ¹æ Á¤¸®: °£´Ü ÀÛ¼º(s9 bold)º¸´Ù ¾à 10% Å©°Ô/±½°Ô + ÁøÃÊ·Ï
    ; Ç¥ÁØ ¹öÆ°ÀÇ hover ¹ÝÀÀÀº À¯Áö
    Gui, SSOKSide:Font, s10 w770 c006400, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y170 w%SSOK_SidebarButtonW% h29 vSSOK_SidebarOneShot HwndSSOK_SidebarOneShotHwnd gSSOK_Sidebar_F2, % Chr(9889) . " " . Chr(54620) . Chr(48169) . " " . Chr(51221) . Chr(47532) . " " . Chr(9889)
    DllCall("uxtheme\SetWindowTheme", "Ptr", SSOK_SidebarOneShotHwnd, "WStr", "", "WStr", "")
    OnMessage(0x0135, "SSOK_WM_CTLCOLORBTN")

    Gui, SSOKSide:Font, s8 bold c005BAC, Malgun Gothic
    Gui, SSOKSide:Add, Progress, x12 y208 w%SSOK_SidebarSepW% h1 vSSOK_SidebarSepAI BackgroundD4E6EF cD4E6EF
    Gui, SSOKSide:Add, Text, x14 y213 w41 h15 c005BAC Right gSSOK_Sidebar_F3, AI ÀÛ¼º
    Gui, SSOKSide:Font, s5 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x56 y216 w50 h10 c4E7F90 Left gSSOK_Sidebar_F3, (Win + F3)
    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarAIButtonX1% y228 w%SSOK_SidebarAIButtonW% h21 vSSOK_SidebarBtnAIDraft gSSOK_Sidebar_AI_Draft, ±â¾È¹®
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarAIButtonX2% y228 w%SSOK_SidebarAIButtonW% h21 vSSOK_SidebarBtnAIPlan gSSOK_Sidebar_AI_Plan, °èÈ¹¼­
    Gui, SSOKSide:Font, s6 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarAIConvert1X% y250 w30 h14 vSSOK_SidebarAIConvert1 gSSOK_Sidebar_AI_Convert1, HWP
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarAIConvert2X% y250 w30 h14 vSSOK_SidebarAIConvert2 gSSOK_Sidebar_AI_Convert2, HWP

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Progress, x12 y267 w%SSOK_SidebarSepW% h1 vSSOK_SidebarSepQA BackgroundD4E6EF cD4E6EF
    Gui, SSOKSide:Font, s6 bold c005BAC, Malgun Gothic
    Gui, SSOKSide:Add, Text, x8 y271 w%SSOK_SidebarCaptionW% h12 vSSOK_SidebarHintQA Center, °£´Ü Q&&A

    SSOK_ACC_SidePlaceholder := "ÇÐ±³È¸°è"
    SSOK_ACC_SideIsPlaceholder := true
    SSOK_WRK_SidePlaceholder := "°ø¹«Á÷"
    SSOK_WRK_SideIsPlaceholder := true
    SSOK_LAW_SidePlaceholder := "¹ý·ÉÁ¤º¸"
    SSOK_LAW_SideIsPlaceholder := true
    SSOK_EDU_SidePlaceholder := "±³À°Á¤º¸"
    SSOK_EDU_SideIsPlaceholder := true
    Gui, SSOKSide:Font, s6 norm c808080, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x%SSOK_QASearchX1% y284 w%SSOK_QASearchW% h18 vSSOK_ACC_SideQuery HwndSSOK_ACC_SideQueryEditHwnd, %SSOK_ACC_SidePlaceholder%
    Gui, SSOKSide:Add, Edit, x%SSOK_QASearchX2% y284 w%SSOK_QASearchW% h18 vSSOK_WRK_SideQuery HwndSSOK_WRK_SideQueryEditHwnd, %SSOK_WRK_SidePlaceholder%
    Gui, SSOKSide:Add, Edit, x%SSOK_QASearchX1% y306 w%SSOK_QASearchW% h18 vSSOK_LAW_SideQuery HwndSSOK_LAW_SideQueryEditHwnd, %SSOK_LAW_SidePlaceholder%
    Gui, SSOKSide:Add, Edit, x%SSOK_QASearchX2% y306 w%SSOK_QASearchW% h18 vSSOK_EDU_SideQuery HwndSSOK_EDU_SideQueryEditHwnd, %SSOK_EDU_SidePlaceholder%
    Gui, SSOKSide:Add, Button, x-100 y-100 w1 h1 Hidden Default gSSOK_Sidebar_DefaultSearch

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Progress, x12 y328 w%SSOK_SidebarSepW% h1 vSSOK_SidebarSepF4 BackgroundE6EAEE cE6EAEE
    Gui, SSOKSide:Add, Text, x8 y335 w%SSOK_SidebarCaptionW% h12 vSSOK_SidebarHintF4 c6B7280 Center gSSOK_Sidebar_F4, Win + F4
    Gui, SSOKSide:Font, s9 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y346 w%SSOK_QFMainButtonW% h25 vSSOK_SidebarBtnFile gSSOK_Sidebar_F4, ÆÄÀÏ¿­±â
    SSOK_QF_SidePlaceholder := "°Ë»ö "
    SSOK_QF_SideIsPlaceholder := true
    Gui, SSOKSide:Font, s6 norm c808080, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x%SSOK_QFSearchX% y348 w%SSOK_QFSearchW% h21 vSSOK_QF_SideKeyword HwndSSOK_QF_SideKeywordEditHwnd, %SSOK_QF_SidePlaceholder%
    Gui, SSOKSide:Font, s8 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX1% y372 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF1 gSSOK_Sidebar_QF1, %SSOK_SideQF1%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX2% y372 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF2 gSSOK_Sidebar_QF2, %SSOK_SideQF2%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX3% y372 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF3 gSSOK_Sidebar_QF3, %SSOK_SideQF3%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX4% y372 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF4 gSSOK_Sidebar_QF4, %SSOK_SideQF4%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX5% y372 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF5 gSSOK_Sidebar_QF5, %SSOK_SideQF5%

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Progress, x12 y395 w%SSOK_SidebarSepW% h1 vSSOK_SidebarSepF5 BackgroundE6EAEE cE6EAEE
    Gui, SSOKSide:Add, Text, x8 y405 w%SSOK_SidebarCaptionW% h12 vSSOK_SidebarHintF5 c6B7280 Center gSSOK_Sidebar_F5, Win + F5
    Gui, SSOKSide:Font, s9 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y418 w%SSOK_QUMainButtonW% h25 vSSOK_SidebarBtnUrl gSSOK_Sidebar_F5, URL¿­±â
    SSOK_QU_SidePlaceholder := "°Ë»ö "
    SSOK_QU_SideIsPlaceholder := true
    Gui, SSOKSide:Font, s6 norm c808080, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x%SSOK_QUSearchX% y420 w%SSOK_QUSearchW% h21 vSSOK_QU_SideKeyword HwndSSOK_QU_SideKeywordEditHwnd, %SSOK_QU_SidePlaceholder%
    Gui, SSOKSide:Font, s8 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX1% y445 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU1 gSSOK_Sidebar_QU1, %SSOK_SideQU1%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX2% y445 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU2 gSSOK_Sidebar_QU2, %SSOK_SideQU2%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX3% y445 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU3 gSSOK_Sidebar_QU3, %SSOK_SideQU3%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX4% y445 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU4 gSSOK_Sidebar_QU4, %SSOK_SideQU4%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX5% y445 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU5 gSSOK_Sidebar_QU5, %SSOK_SideQU5%

    ; ===== ÁÖ¿äÇÒÀÏ ¸Þ¸ð =====
    IniRead, SSOK_MajorTodoRaw, %SSOK_IniFile%, MajorTodos, Memo, __SSOK_EMPTY__
    if (SSOK_MajorTodoRaw = "__SSOK_EMPTY__" || SSOK_MajorTodoRaw = "")
        SSOK_MajorTodo := SSOK_GetMajorTodoSampleText()
    else
        SSOK_MajorTodo := StrReplace(SSOK_MajorTodoRaw, "\n", "`r`n")

    Gui, SSOKSide:Font, s8 norm, Malgun Gothic
    OnMessage(0x0133, "SSOK_WM_CTLCOLOREDIT")
    OnMessage(0x0138, "SSOK_WM_CTLCOLORSTATIC")
    Gui, SSOKSide:Add, Edit, x8 y478 w%SSOK_SidebarButtonW% h90 vSSOK_MajorTodoEdit HwndSSOK_MajorTodoHwnd gSSOK_SaveMajorTodo +Wrap -VScroll -HScroll -E0x200 BackgroundFFFAE6, %SSOK_MajorTodo%

    IniRead, SSOK_AlarmRaw, %SSOK_IniFile%, MajorTodos, Alarm, __SSOK_EMPTY__
    SSOK_AlarmTime := SSOK_NormalizeAlarmTime(SSOK_AlarmRaw, "1150")
    SSOK_AlarmTimeText := SubStr(SSOK_AlarmTime, 1, 2) . ":" . SubStr(SSOK_AlarmTime, 3, 2)
    IniRead, SSOK_AlarmEnabled, %SSOK_IniFile%, MajorTodos, AlarmEnabled, 1
    SSOK_AlarmToggleText := (SSOK_AlarmEnabled = 1) ? "O" : "X"
    IniRead, SSOK_Alarm2Raw, %SSOK_IniFile%, MajorTodos, Alarm2, __SSOK_EMPTY__
    SSOK_Alarm2Time := SSOK_NormalizeAlarmTime(SSOK_Alarm2Raw, "1630")
    SSOK_Alarm2TimeText := SubStr(SSOK_Alarm2Time, 1, 2) . ":" . SubStr(SSOK_Alarm2Time, 3, 2)
    IniRead, SSOK_Alarm2Enabled, %SSOK_IniFile%, MajorTodos, Alarm2Enabled, 1
    SSOK_Alarm2ToggleText := (SSOK_Alarm2Enabled = 1) ? "O" : "X"

    Gui, SSOKSide:Font, s8 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x7 y580 w27 h18 +0x200 c333333, ¾Ë¶÷
    if (SSOK_AlarmEnabled = 1)
        Gui, SSOKSide:Font, s8 bold cE53935, Malgun Gothic
    else
        Gui, SSOKSide:Font, s8 bold c555555, Malgun Gothic
    Gui, SSOKSide:Add, Text, x32 y579 w15 h18 +Border +0x200 Center vSSOK_AlarmToggleButton gSSOK_AlarmToggle, %SSOK_AlarmToggleText%
    Gui, SSOKSide:Font, s8 norm, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x51 y579 w%SSOK_AlarmTimeW% h18 Center vSSOK_AlarmTimeEdit gSSOK_SaveAlarm, %SSOK_AlarmTimeText%

    Gui, SSOKSide:Font, s8 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x7 y601 w27 h18 +0x200 c333333, ¾Ë¶÷
    if (SSOK_Alarm2Enabled = 1)
        Gui, SSOKSide:Font, s8 bold cE53935, Malgun Gothic
    else
        Gui, SSOKSide:Font, s8 bold c555555, Malgun Gothic
    Gui, SSOKSide:Add, Text, x32 y600 w15 h18 +Border +0x200 Center vSSOK_Alarm2ToggleButton gSSOK_Alarm2Toggle, %SSOK_Alarm2ToggleText%
    Gui, SSOKSide:Font, s8 norm, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x51 y600 w%SSOK_AlarmTimeW% h18 Center vSSOK_Alarm2TimeEdit gSSOK_SaveAlarm, %SSOK_Alarm2TimeText%

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x8 y620 w%SSOK_SidebarButtonW% h11 vSSOK_SidebarHintF12 c4D6B7A Center gSSOK_Sidebar_PCOff, Win + F12
    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y632 w%SSOK_PCOffW% h25 vSSOK_SidebarBtnPCOff gSSOK_Sidebar_PCOff, Åð±Ù PC OFF
    Gui, SSOKSide:Font, s5 norm, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SettingsX% y632 w18 h25 vSSOK_SidebarBtnSettings gSSOK_ShowPowerScheduleGui, ¼³Á¤

    ; ¾÷¹«¿ë µµ±¸ ¸Þ´º
    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y663 w%SSOK_SidebarButtonW% h25 vSSOK_SidebarBtnWorkTools gSSOK_Sidebar_WorkTools, % Chr(9881) . " ¾÷¹«¿ë µµ±¸"

    SSOK_HideY := SSOK_SidebarH - 66
    SSOK_HideTitleY := SSOK_HideY + 4
    SSOK_HideSubY := SSOK_HideY + 21
    SSOK_BottomSplitGap := 2
    SSOK_BottomSplitW := Floor((SSOK_SidebarButtonW - SSOK_BottomSplitGap) / 2)
    if (SSOK_BottomSplitW < 45)
        SSOK_BottomSplitW := 45
    SSOK_CaptureX := 8
    SSOK_HideX := SSOK_CaptureX + SSOK_BottomSplitW + SSOK_BottomSplitGap
    SSOK_CaptureTextX := SSOK_CaptureX + 1
    SSOK_HideTextX := SSOK_HideX + 1
    SSOK_CaptureLabelW := SSOK_BottomSplitW - 2
    SSOK_HideLabelW := SSOK_BottomSplitW - 2

    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Text, x%SSOK_CaptureX% y%SSOK_HideY% w%SSOK_BottomSplitW% h35 vSSOK_SidebarBtnCapture +Border BackgroundF2F6FA c005BAC Center gSSOK_Sidebar_Capture,
    Gui, SSOKSide:Add, Text, x%SSOK_CaptureTextX% y%SSOK_HideTitleY% w%SSOK_CaptureLabelW% h16 vSSOK_SidebarBtnCaptureTitle +0x200 BackgroundF2F6FA c005BAC Center gSSOK_Sidebar_Capture, ½ºÅ©¸°Ä¸Ã³
    Gui, SSOKSide:Font, s5 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x%SSOK_CaptureTextX% y%SSOK_HideSubY% w%SSOK_CaptureLabelW% h10 vSSOK_SidebarBtnCaptureSub +0x200 BackgroundF2F6FA c005BAC Center gSSOK_Sidebar_Capture, win + S

    Gui, SSOKSide:Font, s6 bold, Malgun Gothic
    Gui, SSOKSide:Add, Text, x%SSOK_HideX% y%SSOK_HideY% w%SSOK_BottomSplitW% h35 vSSOK_SidebarBtnHide +Border BackgroundF2F6FA cA33A3A Center gSSOK_Sidebar_Hide,
    Gui, SSOKSide:Add, Text, x%SSOK_HideTextX% y%SSOK_HideTitleY% w%SSOK_HideLabelW% h16 vSSOK_SidebarBtnHideTitle +0x200 BackgroundF2F6FA cA33A3A Center gSSOK_Sidebar_Hide, ¸Þ´º
    Gui, SSOKSide:Font, s6 bold, Malgun Gothic
    Gui, SSOKSide:Add, Text, x%SSOK_HideTextX% y%SSOK_HideSubY% w%SSOK_HideLabelW% h10 vSSOK_SidebarBtnHideSub +0x200 BackgroundF2F6FA cA33A3A Center gSSOK_Sidebar_Hide, ¼û±â±â

    Gui, SSOKSide:Font, s5 norm, Malgun Gothic
    SSOK_CopyOneY := SSOK_SidebarH - 22
    Gui, SSOKSide:Add, Text, x2 y%SSOK_CopyOneY% w%SSOK_SidebarFooterW% h16 vSSOK_SidebarFooter +0x200 c888888 Center gSSOK_Sidebar_OpenHomepage, % "¨Ï ¼¼Á¾½Ã±³À°Ã» ÀÌ¸íÈ£(v." . SSOK_VERSION . ")"

    SSOK_SidebarResizeReady := 0
    Gui, SSOKSide:Show, NoActivate x%SSOK_SidebarX% y%SSOK_SidebarY% w%SSOK_SidebarW% h%SSOK_SidebarH%, ½ï(SSOK)
    SSOK_Sidebar_ApplyWidth(SSOK_SidebarW)
    WinSet, AlwaysOnTop, On, ahk_id %SSOK_SidebarHwnd%
    SSOK_SidebarVisible := 1

    SetTimer, SSOK_Sidebar_TrackTarget, 300
    SetTimer, SSOK_Sidebar_KeepOnTop, 2000
    SetTimer, SSOK_ACC_CheckSideQueryFocus, 50
    SetTimer, SSOK_Sidebar_EnableResizeSave, -300
return


SSOK_SaveOrgName:
    SetTimer, SSOK_SaveOrgNameNow, -600
return

SSOK_SaveOrgNameNow:
    SSOK_SaveUnifiedIni()
    SSOK_MySchool_AutoMatchCurrentOrg()
return

; ±â°ü¸í ±ÛÀÚ¸¦ Å¬¸¯ÇÏ¸é ÇöÀç ±â°ü¸íÀ» ³ªÀÌ½º ÇÐ±³Á¤º¸¿Í ´Ù½Ã ¿¬°áÇÕ´Ï´Ù.
SSOK_MySchool_Setting_Show:
    SetTimer, SSOK_SaveOrgNameNow, Off
    SSOK_SaveUnifiedIni()
    SSOK_MySchool_AutoMatchCurrentOrg(true)
return

SSOK_MySchool_ListEvent:
    if (A_GuiEvent = "DoubleClick" && A_EventInfo > 0)
        SSOK_MySchool_SelectPickerRow(A_EventInfo)
return

SSOK_MySchool_Select:
    Gui, SSOKMySchool:Default
    Gui, ListView, SSOK_MySchool_List
    row := LV_GetNext(0, "F")
    if (row < 1)
        row := LV_GetNext()
    if (row < 1)
    {
        MsgBox, 48, SSOK ±â°ü ÇÐ±³ ¼³Á¤, ÇÐ±³¸¦ ÇÏ³ª ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_MySchool_SelectPickerRow(row)
return

SSOK_MySchool_GuiClose:
SSOK_MySchool_GuiEscape:
    Gui, SSOKMySchool:Destroy
return

SSOK_GetOrgName()
{
    GuiControlGet, SSOK_OrgNameGuiValue, SSOKSide:, SSOK_OrgNameEdit
    if (!ErrorLevel)
    {
        SSOK_OrgNameGuiValue := Trim(SSOK_OrgNameGuiValue)
        if (SSOK_OrgNameGuiValue != "")
            return SSOK_OrgNameGuiValue
    }
    IniRead, SSOK_OrgNameValue, %SSOK_IniFile%, MajorTodos, OrgName, µµ´ãÁßÇÐ±³
    SSOK_OrgNameValue := Trim(SSOK_OrgNameValue)
    if (SSOK_OrgNameValue = "")
        SSOK_OrgNameValue := "µµ´ãÁßÇÐ±³"
    return SSOK_OrgNameValue
}


; =========================================================
; ¸ÞÀÎ ±â°ü¸í -> ³ªÀÌ½º ÇÐ±³ °íÀ¯ÄÚµå ¿¬°á
; - ±â°ü¸í°ú Á¤È®È÷ °°Àº ÇÐ±³°¡ 1°³¸é ÀÚµ¿ ÀúÀå
; - µ¿¸íÀÌ±³°¡ ¿©·¯ °³¸é »ç¿ëÀÚ°¡ ÇÑ ¹ø ¼±ÅÃ
; - ¼±ÅÃ ÈÄ¿¡´Â [MySchool]ÀÇ ±³À°Ã»ÄÚµå+ÇÐ±³ÄÚµå·Î Á¤È®È÷ ½Äº°
; =========================================================
SSOK_MySchool_AutoMatchCurrentOrg(force := false)
{
    global SSOK_IniFile, SSOK_MySchool_LastAttempt

    orgName := Trim(SSOK_GetOrgName())
    if (orgName = "" || StrLen(orgName) < 2)
        return false

    IniRead, savedName, %SSOK_IniFile%, MySchool, Name, __SSOK_EMPTY__
    IniRead, savedOffice, %SSOK_IniFile%, MySchool, OfficeCode, __SSOK_EMPTY__
    IniRead, savedSchool, %SSOK_IniFile%, MySchool, SchoolCode, __SSOK_EMPTY__
    savedName := Trim(savedName)
    savedOffice := Trim(savedOffice)
    savedSchool := Trim(savedSchool)

    if (!force && savedName = orgName && savedOffice != "" && savedOffice != "__SSOK_EMPTY__"
        && savedSchool != "" && savedSchool != "__SSOK_EMPTY__")
        return true

    if (!force && SSOK_MySchool_LastAttempt = orgName)
        return false
    SSOK_MySchool_LastAttempt := orgName

    exact := SSOK_MySchool_FindExact(orgName)
    cnt := IsObject(exact) ? exact.Length() : 0

    if (cnt = 1)
    {
        SSOK_MySchool_SaveSchool(exact[1])
        return true
    }

    if (cnt > 1)
    {
        exact := SSOK_MySchool_Prioritize(exact)
        SSOK_MySchool_ShowPicker(exact, orgName)
        return false
    }

    ; ±â°ü¸íÀÌ ´Ù¸¥ ±â°ü/ºÎ¼­¸íÀ¸·Î ¹Ù²î¾úÀ¸¸é ¿¹Àü ÇÐ±³ÄÚµå¸¦ ³²±âÁö ¾Ê½À´Ï´Ù.
    if (savedName != "__SSOK_EMPTY__" && savedName != "" && savedName != orgName)
        IniDelete, %SSOK_IniFile%, MySchool

    if (force)
        MsgBox, 48, SSOK ±â°ü ÇÐ±³ ¼³Á¤, % "³ªÀÌ½º ÇÐ±³Á¤º¸¿¡¼­ ±â°ü¸í°ú Á¤È®È÷ ÀÏÄ¡ÇÏ´Â ÇÐ±³¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`n`n±â°ü¸í: " . orgName
    return false
}

SSOK_MySchool_FindExact(orgName)
{
    key := SSOK_EDU_GetApiKey()
    url := SSOK_EDU_BuildUrl("schoolInfo", Object("SCHUL_NM", orgName), 100, key)
    resp := SSOK_EDU_HttpGet(url)
    exact := []
    if (!resp.ok)
        return exact

    rows := SSOK_EDU_ParseSchools(resp.text)
    if !IsObject(rows)
        return exact

    for idx, item in rows
    {
        if (Trim(item.schoolName) = orgName)
            exact.Push(item)
    }
    return exact
}

SSOK_MySchool_PreferredRegion()
{
    global SSOK_IniFile
    IniRead, region, %SSOK_IniFile%, EduQuickLinks, Neis, ¼¼Á¾
    region := Trim(region)
    if (region = "" || region = "ERROR")
        region := "¼¼Á¾"
    return region
}

SSOK_MySchool_Prioritize(items)
{
    preferred := []
    others := []
    region := SSOK_MySchool_PreferredRegion()

    for idx, item in items
    {
        if (region != "" && (InStr(item.officeName, region) || InStr(item.address, region) || InStr(item.location, region)))
            preferred.Push(item)
        else
            others.Push(item)
    }

    result := []
    for idx, item in preferred
        result.Push(item)
    for idx, item in others
        result.Push(item)
    return result
}

SSOK_MySchool_ShowPicker(items, orgName)
{
    global SSOK_MySchool_Candidates, SSOK_MySchool_List
    SSOK_MySchool_Candidates := items

    Gui, SSOKMySchool:Destroy
    Gui, SSOKMySchool:New, +AlwaysOnTop +ToolWindow +Resize +MinSize760x350 +LabelSSOK_MySchool_Gui
    Gui, SSOKMySchool:Color, F7FBFF
    Gui, SSOKMySchool:Margin, 12, 12
    Gui, SSOKMySchool:Font, s10 bold c005BAC, Malgun Gothic
    Gui, SSOKMySchool:Add, Text, x12 y12 w800 h24, % "µ¿ÀÏÇÑ ÇÐ±³¸íÀÌ ¿©·¯ °÷¿¡ ÀÖ½À´Ï´Ù : " . orgName
    Gui, SSOKMySchool:Font, s8 norm c666666, Malgun Gothic
    Gui, SSOKMySchool:Add, Text, x12 y36 w800 h18, ÇöÀç SSOK Áö¿ª¼³Á¤°ú °¡±î¿î ±³À°Ã»À» À§¿¡ Ç¥½ÃÇß½À´Ï´Ù. ½ÇÁ¦ ±â°üÀ» ÇÑ ¹ø ¼±ÅÃÇØ ÁÖ¼¼¿ä.
    Gui, SSOKMySchool:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKMySchool:Add, ListView, x12 y60 w836 h250 vSSOK_MySchool_List gSSOK_MySchool_ListEvent AltSubmit, ÇÐ±³¸í|ÇÐ±³±Þ|±³À°Ã»|Áö¿øÃ»|ÁÖ¼Ò

    Gui, SSOKMySchool:Default
    Gui, ListView, SSOK_MySchool_List
    for idx, item in items
        LV_Add("", item.schoolName, item.kind, item.officeName, item.parentOrg, item.address)
    LV_ModifyCol(1, 150)
    LV_ModifyCol(2, 70)
    LV_ModifyCol(3, 145)
    LV_ModifyCol(4, 160)
    LV_ModifyCol(5, 285)
    if (items.Length() > 0)
        LV_Modify(1, "Select Focus Vis")

    Gui, SSOKMySchool:Add, Button, x748 y320 w100 h30 gSSOK_MySchool_Select Default, ÀÌ ÇÐ±³
    Gui, SSOKMySchool:Show, w860 h362, SSOK ±â°ü ÇÐ±³ ¼³Á¤
}

SSOK_MySchool_SelectPickerRow(row)
{
    global SSOK_MySchool_Candidates
    if (!IsObject(SSOK_MySchool_Candidates) || row < 1 || row > SSOK_MySchool_Candidates.Length())
        return
    school := SSOK_MySchool_Candidates[row]
    SSOK_MySchool_SaveSchool(school)
    Gui, SSOKMySchool:Destroy
}

SSOK_MySchool_SaveSchool(school)
{
    global SSOK_IniFile, SSOK_MySchool_LastAttempt
    if !IsObject(school)
        return false

    IniWrite, % school.schoolName, %SSOK_IniFile%, MySchool, Name
    IniWrite, % school.officeCode, %SSOK_IniFile%, MySchool, OfficeCode
    IniWrite, % school.schoolCode, %SSOK_IniFile%, MySchool, SchoolCode
    IniWrite, % school.officeName, %SSOK_IniFile%, MySchool, OfficeName
    IniWrite, % school.kind, %SSOK_IniFile%, MySchool, SchoolKind
    IniWrite, % school.parentOrg, %SSOK_IniFile%, MySchool, SupportOffice
    IniWrite, % school.address, %SSOK_IniFile%, MySchool, Address
    SSOK_MySchool_LastAttempt := school.schoolName
    return true
}

SSOK_SaveMajorTodo:
    GuiControlGet, SSOK_MajorTodoEdit,, SSOK_MajorTodoEdit
    SSOK_MajorTodoSave := Trim(SSOK_MajorTodoEdit, " `t`r`n")
    if (SSOK_IsMajorTodoSampleOrGuideText(SSOK_MajorTodoSave))
        SSOK_MajorTodoSave := ""
    SSOK_MajorTodoSave := StrReplace(SSOK_MajorTodoSave, "`r`n", "\n")
    SSOK_MajorTodoSave := StrReplace(SSOK_MajorTodoSave, "`n", "\n")
    IniWrite, %SSOK_MajorTodoSave%, %SSOK_IniFile%, MajorTodos, Memo
return

SSOK_GetMajorTodoSampleText()
{
    return "<ToDoList>`r`n5.1 12:00 ±³À°Âü¼®(¿¹½Ã)`r`n5.3. 13:00 Çà»ç½Ç½Ã(¿¹½Ã)"
}

SSOK_IsMajorTodoSampleOrGuideText(_text)
{
    _text := Trim(_text, " `t`r`n")
    return (_text = "" || _text = SSOK_GetMajorTodoSampleText() || _text = "¿©±â¿¡ ÁÖ¿äÇÒÀÏÀ» ÀÔ·Â~" || _text = "¿©±â¿¡ ÁÖ¿äÇÒÀÏ ¶Ç´Â ¸Þ¸ð¸¦ ÀÔ·ÂÇÏ¿© °ü¸®ÇÏ¼¼¿ä`r`n5.*. 12:00 00 ±³À°`r`n5.*. 13:00 Çà»ç")
}

SSOK_CheckMajorTodoReminder:
    if (SSOK_SidebarVisible)
    {
        GuiControlGet, SSOK_ReminderTime1, SSOKSide:, SSOK_AlarmTimeEdit
        SSOK_ReminderTime1 := SSOK_NormalizeAlarmTime(SSOK_ReminderTime1, "1150")
        SSOK_ReminderEnabled1 := SSOK_AlarmEnabled
        GuiControlGet, SSOK_ReminderTime2, SSOKSide:, SSOK_Alarm2TimeEdit
        SSOK_ReminderTime2 := SSOK_NormalizeAlarmTime(SSOK_ReminderTime2, "1630")
        SSOK_ReminderEnabled2 := SSOK_Alarm2Enabled
    }
    else
    {
        IniRead, SSOK_ReminderRaw, %SSOK_IniFile%, MajorTodos, Alarm, __SSOK_EMPTY__
        SSOK_ReminderTime1 := SSOK_NormalizeAlarmTime(SSOK_ReminderRaw, "1150")
        IniRead, SSOK_ReminderEnabled1, %SSOK_IniFile%, MajorTodos, AlarmEnabled, 1
        IniRead, SSOK_ReminderRaw2, %SSOK_IniFile%, MajorTodos, Alarm2, __SSOK_EMPTY__
        SSOK_ReminderTime2 := SSOK_NormalizeAlarmTime(SSOK_ReminderRaw2, "1630")
        IniRead, SSOK_ReminderEnabled2, %SSOK_IniFile%, MajorTodos, Alarm2Enabled, 1
    }

    FormatTime, SSOK_ReminderNow,, yyyyMMddHHmm
    SSOK_CheckOneAlarm(1, SSOK_ReminderTime1, SSOK_ReminderEnabled1, SSOK_ReminderNow)
    SSOK_CheckOneAlarm(2, SSOK_ReminderTime2, SSOK_ReminderEnabled2, SSOK_ReminderNow)
return

SSOK_CheckOneAlarm(index, timeText, enabled, nowMinute)
{
    global SSOK_AlarmLastKey
    if (enabled != 1 || timeText = "")
        return

    FormatTime, todayStamp,, yyyyMMdd
    Loop, 2
    {
        target := todayStamp . timeText . "00"
        if (A_Index = 2)
            EnvAdd, target, 1, Days
        trigger := target
        EnvAdd, trigger, -5, Minutes
        triggerMinute := SubStr(trigger, 1, 12)
        if (triggerMinute = nowMinute)
        {
            FormatTime, display, %target%, M¿ù dÀÏ HH:mm
            key := "T" . index . "|" . triggerMinute . "|" . target
            if (SSOK_AlarmLastKey != key)
            {
                SSOK_AlarmLastKey := key
                SoundBeep, 880, 180
                mealLine := SSOK_GetAlarmMealLine(timeText)
                if (SSOK_IsQuitAlarmTime(timeText))
                    SSOK_ShowQuitAlarmConfirm(display, target, mealLine)
                else if (SSOK_IsLunchAlarmTime(timeText))
                    SSOK_ShowAlarmCenter(display, "Á¡½É ½Ã°£ 5ºÐ ÀüÀÔ´Ï´Ù.", mealLine)
                else
                    SSOK_ShowAlarmCenter(display, "5ºÐÀüÀÔ´Ï´Ù.", mealLine)
            }
            return
        }
    }
}

SSOK_SaveAlarm:
    GuiControlGet, SSOK_AlarmTimeEdit,, SSOK_AlarmTimeEdit
    SSOK_AlarmSave := SSOK_NormalizeAlarmTime(SSOK_AlarmTimeEdit, "1150")
    GuiControlGet, SSOK_Alarm2TimeEdit,, SSOK_Alarm2TimeEdit
    SSOK_Alarm2Save := SSOK_NormalizeAlarmTime(SSOK_Alarm2TimeEdit, "1630")
    IniWrite, %SSOK_AlarmSave%, %SSOK_IniFile%, MajorTodos, Alarm
    IniWrite, %SSOK_AlarmEnabled%, %SSOK_IniFile%, MajorTodos, AlarmEnabled
    IniWrite, %SSOK_Alarm2Save%, %SSOK_IniFile%, MajorTodos, Alarm2
    IniWrite, %SSOK_Alarm2Enabled%, %SSOK_IniFile%, MajorTodos, Alarm2Enabled
    if RegExMatch(Trim(SSOK_AlarmTimeEdit), "^\d{4}$")
    {
        SSOK_AlarmHour := SubStr(SSOK_AlarmTimeEdit, 1, 2) + 0
        SSOK_AlarmMinute := SubStr(SSOK_AlarmTimeEdit, 3, 2) + 0
        if (SSOK_AlarmHour >= 0 && SSOK_AlarmHour <= 23 && SSOK_AlarmMinute >= 0 && SSOK_AlarmMinute <= 59)
        {
            SSOK_AlarmShow := SubStr(SSOK_AlarmSave, 1, 2) . ":" . SubStr(SSOK_AlarmSave, 3, 2)
            GuiControl, SSOKSide:, SSOK_AlarmTimeEdit, %SSOK_AlarmShow%
        }
    }
    if RegExMatch(Trim(SSOK_Alarm2TimeEdit), "^\d{4}$")
    {
        SSOK_Alarm2Hour := SubStr(SSOK_Alarm2TimeEdit, 1, 2) + 0
        SSOK_Alarm2Minute := SubStr(SSOK_Alarm2TimeEdit, 3, 2) + 0
        if (SSOK_Alarm2Hour >= 0 && SSOK_Alarm2Hour <= 23 && SSOK_Alarm2Minute >= 0 && SSOK_Alarm2Minute <= 59)
        {
            SSOK_Alarm2Show := SubStr(SSOK_Alarm2Save, 1, 2) . ":" . SubStr(SSOK_Alarm2Save, 3, 2)
            GuiControl, SSOKSide:, SSOK_Alarm2TimeEdit, %SSOK_Alarm2Show%
        }
    }
return

SSOK_AlarmToggle:
    SSOK_AlarmEnabled := (SSOK_AlarmEnabled = 1) ? 0 : 1
    SSOK_AlarmToggleText := (SSOK_AlarmEnabled = 1) ? "O" : "X"
    if (SSOK_AlarmEnabled = 1)
        Gui, SSOKSide:Font, s8 bold cE53935, Malgun Gothic
    else
        Gui, SSOKSide:Font, s8 bold c555555, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_AlarmToggleButton
    GuiControl, SSOKSide:, SSOK_AlarmToggleButton, %SSOK_AlarmToggleText%
    Gosub, SSOK_SaveAlarm
return

SSOK_Alarm2Toggle:
    SSOK_Alarm2Enabled := (SSOK_Alarm2Enabled = 1) ? 0 : 1
    SSOK_Alarm2ToggleText := (SSOK_Alarm2Enabled = 1) ? "O" : "X"
    if (SSOK_Alarm2Enabled = 1)
        Gui, SSOKSide:Font, s8 bold cE53935, Malgun Gothic
    else
        Gui, SSOKSide:Font, s8 bold c555555, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_Alarm2ToggleButton
    GuiControl, SSOKSide:, SSOK_Alarm2ToggleButton, %SSOK_Alarm2ToggleText%
    Gosub, SSOK_SaveAlarm
return

SSOK_NormalizeAlarmTime(raw, defaultTime := "")
{
    raw := Trim(raw)
    if RegExMatch(raw, "^\d{12}(\d{2})?$")
        raw := SubStr(raw, 9, 4)
    if RegExMatch(raw, "^\s*(\d{1,2})\s*[:½Ã]\s*(\d{1,2})\s*(?:ºÐ)?\s*$", m)
    {
        hour := m1 + 0
        minute := m2 + 0
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59)
            return Format("{:02}{:02}", hour, minute)
    }
    if RegExMatch(raw, "^\s*(\d{3,4})\s*$", m)
    {
        digits := m1
        if (StrLen(digits) = 3)
            digits := "0" . digits
        hour := SubStr(digits, 1, 2) + 0
        minute := SubStr(digits, 3, 2) + 0
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59)
            return Format("{:02}{:02}", hour, minute)
    }
    if (defaultTime != "")
        return defaultTime
    return "1150"
}

SSOK_IsLunchAlarmTime(timeText)
{
    t := timeText + 0
    return (t >= 1130 && t <= 1230)
}

SSOK_IsQuitAlarmTime(timeText)
{
    t := timeText + 0
    return ((t >= 1620 && t <= 1640) || (t >= 1730 && t <= 1830))
}

SSOK_GetAlarmMealLine(timeText)
{
    t := timeText + 0
    wanted := ""
    if (t >= 700 && t <= 900)
        wanted := "Á¶½Ä"
    else if (t >= 1100 && t <= 1300)
        wanted := "Áß½Ä"
    else if (t >= 1630 && t <= 1900)
        wanted := "¼®½Ä"
    else
        return ""

    mealInfo := SSOK_AdminCalendar_GetMySchoolTodayMeals()
    if (!IsObject(mealInfo) || !mealInfo.ok || Trim(mealInfo.text) = "")
        return ""

    mealTextAll := mealInfo.text
    Loop, Parse, mealTextAll, `n, `r
    {
        line := Trim(A_LoopField)
        if (SubStr(line, 1, StrLen(wanted) + 1) = wanted . ":")
            return line
    }
    return ""
}

SSOK_ShowAlarmCenter(displayText, messageText := "5ºÐÀüÀÔ´Ï´Ù.", mealText := "")
{
    global SSOK_AlarmMealBody
    mealDisplay := Trim(mealText)

    Gui, SSOKAlarmCenter:Destroy
    Gui, SSOKAlarmCenter:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKAlarmCenter:Color, FFF7D6
    Gui, SSOKAlarmCenter:Font, s56 bold, Malgun Gothic
    Gui, SSOKAlarmCenter:Add, Text, x0 y48 w720 h116 c111111 Center, %displayText%
    Gui, SSOKAlarmCenter:Font, s18 norm, Malgun Gothic
    Gui, SSOKAlarmCenter:Add, Text, x0 y164 w720 h48 c555555 Center, %messageText%

    if (mealDisplay = "")
    {
        Gui, SSOKAlarmCenter:Font, s18 bold, Malgun Gothic
        Gui, SSOKAlarmCenter:Add, Button, x284 y220 w152 h48 gSSOK_CloseAlarmCenter, ´Ý±â
        winH := 280
    }
    else
    {
        ; ÇàÁ¤¾÷¹«´Þ·Â ÇÏ´Ü ±Þ½Ä°ú µ¿ÀÏÇÑ °£´Ü Ç¥½Ã
        Gui, SSOKAlarmCenter:Font, s9 norm c30445A, Malgun Gothic
        Gui, SSOKAlarmCenter:Add, Text, x24 y220 w672 vSSOK_AlarmMealBody Left, %mealDisplay%
        GuiControlGet, mealPos, SSOKAlarmCenter:Pos, SSOK_AlarmMealBody
        mealH := mealPosH
        if (mealH < 20)
            mealH := 20
        buttonY := 220 + mealH + 18
        Gui, SSOKAlarmCenter:Font, s18 bold, Malgun Gothic
        Gui, SSOKAlarmCenter:Add, Button, x284 y%buttonY% w152 h48 gSSOK_CloseAlarmCenter, ´Ý±â
        winH := buttonY + 60
    }

    x := (A_ScreenWidth - 720) // 2
    y := (A_ScreenHeight - winH) // 2
    Gui, SSOKAlarmCenter:Show, x%x% y%y% w720 h%winH%, SSOK ¾Ë¶÷
}

SSOK_ShowQuitAlarmConfirm(displayText, targetStamp := "", mealText := "")
{
    global SSOK_QuitAlarmTargetStamp, SSOK_QuitAlarmMealBody
    SSOK_QuitAlarmTargetStamp := targetStamp
    mealDisplay := Trim(mealText)

    Gui, SSOKQuitAlarm:Destroy
    Gui, SSOKQuitAlarm:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKQuitAlarm:Color, FFF7D6
    Gui, SSOKQuitAlarm:Font, s44 bold, Malgun Gothic
    Gui, SSOKQuitAlarm:Add, Text, x0 y36 w780 h84 c111111 Center, %displayText%
    Gui, SSOKQuitAlarm:Font, s24 norm, Malgun Gothic
    Gui, SSOKQuitAlarm:Add, Text, x0 y132 w780 h52 c333333 Center, Åð±Ù½Ã°£ 5ºÐÀüÀÔ´Ï´Ù.
    Gui, SSOKQuitAlarm:Add, Text, x0 y186 w780 h52 c333333 Center, PC¸¦ ÀÚµ¿À¸·Î ²ø±î¿ä?

    if (mealDisplay = "")
    {
        buttonY := 256
        winH := 340
    }
    else
    {
        ; 16:30~19:00 ¾Ë¶÷ÀÌ¸é ¼®½Ä Á¤º¸¸¦ Áú¹® ÇÏ´Ü¿¡ Ç¥½Ã
        Gui, SSOKQuitAlarm:Font, s9 norm c30445A, Malgun Gothic
        Gui, SSOKQuitAlarm:Add, Text, x24 y240 w732 vSSOK_QuitAlarmMealBody Left, %mealDisplay%
        GuiControlGet, mealPos, SSOKQuitAlarm:Pos, SSOK_QuitAlarmMealBody
        mealH := mealPosH
        if (mealH < 20)
            mealH := 20
        buttonY := 240 + mealH + 18
        winH := buttonY + 84
    }

    Gui, SSOKQuitAlarm:Font, s20 bold, Malgun Gothic
    Gui, SSOKQuitAlarm:Add, Button, x210 y%buttonY% w160 h56 gSSOK_QuitAlarmOK, Y
    Gui, SSOKQuitAlarm:Add, Button, x410 y%buttonY% w160 h56 gSSOK_QuitAlarmNo, NO
    x := (A_ScreenWidth - 780) // 2
    y := (A_ScreenHeight - winH) // 2
    Gui, SSOKQuitAlarm:Show, x%x% y%y% w780 h%winH%, SSOK Åð±Ù ¾Ë¶÷
}

SSOK_QuitAlarmOK:
    SetTimer, SSOK_QuitAlarmNo, Off
    Gui, SSOKQuitAlarm:Destroy
    if (SSOK_QuitAlarmTargetStamp != "")
    {
        SSOK_QuitAlarmDelayStamp := SSOK_QuitAlarmTargetStamp
        FormatTime, SSOK_QuitAlarmNow,, yyyyMMddHHmmss
        EnvSub, SSOK_QuitAlarmDelayStamp, %SSOK_QuitAlarmNow%, Seconds
        if (SSOK_QuitAlarmDelayStamp > 0)
        {
            SSOK_QuitAlarmDelayMs := SSOK_QuitAlarmDelayStamp * 1000
            SetTimer, SSOK_QuitAlarmPowerOff, -%SSOK_QuitAlarmDelayMs%
            return
        }
    }
    Gosub, SSOK_DoMouseWakeSleep
return

SSOK_QuitAlarmPowerOff:
    SSOK_QuitAlarmTargetStamp := ""
    Gosub, SSOK_DoMouseWakeSleep
return

SSOK_QuitAlarmNo:
    SetTimer, SSOK_QuitAlarmNo, Off
    SetTimer, SSOK_QuitAlarmPowerOff, Off
    SSOK_QuitAlarmTargetStamp := ""
    Gui, SSOKQuitAlarm:Destroy
return

SSOKQuitAlarmGuiEscape:
SSOKQuitAlarmGuiClose:
    Gosub, SSOK_QuitAlarmNo
return

SSOK_CloseAlarmCenter:
    Gui, SSOKAlarmCenter:Destroy
return

SSOKAlarmCenterGuiEscape:
SSOKAlarmCenterGuiClose:
    Gui, SSOKAlarmCenter:Destroy
return



SSOK_WM_CTLCOLORBTN(wParam, lParam, msg, hwnd)
{
    global SSOK_SidebarOneShotHwnd

    if (lParam = SSOK_SidebarOneShotHwnd)
    {
        ; ÁøÃÊ·Ï #006400
        DllCall("SetTextColor", "Ptr", wParam, "UInt", 0x006400)
        DllCall("SetBkMode", "Ptr", wParam, "Int", 1)
    }

    return 0
}

SSOK_WM_CTLCOLOREDIT(wParam, lParam, msg, hwnd)
{
    global SSOK_MajorTodoHwnd, SSOK_MajorTodoBrush
    if (lParam = SSOK_MajorTodoHwnd)
    {
        if (!SSOK_MajorTodoBrush)
            SSOK_MajorTodoBrush := DllCall("CreateSolidBrush", "UInt", 0xE6FAFF, "Ptr")  ; RGB FFFAE6 ¿¬ÇÑ Æ÷½ºÆ®ÀÕ ³ë¶û
        DllCall("SetBkColor", "Ptr", wParam, "UInt", 0xE6FAFF)
        DllCall("SetTextColor", "Ptr", wParam, "UInt", 0x000000)
        return SSOK_MajorTodoBrush
    }
}

SSOK_WM_CTLCOLORSTATIC(wParam, lParam, msg, hwnd)
{
    global SSOK_MajorTodoHwnd, SSOK_MajorTodoBrush
    if (lParam = SSOK_MajorTodoHwnd)
    {
        if (!SSOK_MajorTodoBrush)
            SSOK_MajorTodoBrush := DllCall("CreateSolidBrush", "UInt", 0xE6FAFF, "Ptr")  ; RGB FFFAE6 ¿¬ÇÑ Æ÷½ºÆ®ÀÕ ³ë¶û
        DllCall("SetBkColor", "Ptr", wParam, "UInt", 0xE6FAFF)
        DllCall("SetTextColor", "Ptr", wParam, "UInt", 0x000000)
        return SSOK_MajorTodoBrush
    }
}

SSOK_Sidebar_TrackTarget:
    WinGet, SSOK_ActiveHwnd, ID, A
    if (SSOK_ActiveHwnd = "")
        return
    WinGetClass, SSOK_ActiveClass, ahk_id %SSOK_ActiveHwnd%
    if (SSOK_ActiveClass = "AutoHotkeyGUI")
        return
    SSOK_SidebarTargetHwnd := SSOK_ActiveHwnd
return

SSOK_Sidebar_KeepOnTop:
    if (SSOK_SidebarVisible = 1 && SSOK_SidebarHwnd != "")
        WinSet, AlwaysOnTop, On, ahk_id %SSOK_SidebarHwnd%
    if (SSOK_SidebarMiniVisible = 1 && SSOK_SidebarMiniHwnd != "")
        WinSet, AlwaysOnTop, On, ahk_id %SSOK_SidebarMiniHwnd%
return

SSOK_Sidebar_StartMove:
    if (SSOK_SidebarHwnd = "")
        return
    MouseGetPos, SSOK_SidebarMoveStartX, SSOK_SidebarMoveStartY
    PostMessage, 0xA1, 2,,, ahk_id %SSOK_SidebarHwnd%
    SetTimer, SSOK_Sidebar_SaveMovedPos, -150
return

SSOK_Sidebar_SaveMovedPos:
    if (GetKeyState("LButton", "P"))
    {
        SetTimer, SSOK_Sidebar_SaveMovedPos, -150
        return
    }
    if (SSOK_SidebarHwnd != "")
    {
        WinGetPos, SSOK_SidebarSavedX, SSOK_SidebarSavedY,,, ahk_id %SSOK_SidebarHwnd%
        MouseGetPos, SSOK_SidebarMoveEndX, SSOK_SidebarMoveEndY
        SSOK_SidebarMoveDeltaX := Abs(SSOK_SidebarMoveEndX - SSOK_SidebarMoveStartX)
        SSOK_SidebarMoveDeltaY := Abs(SSOK_SidebarMoveEndY - SSOK_SidebarMoveStartY)
        if (SSOK_SidebarMoveDeltaX <= 6 && SSOK_SidebarMoveDeltaY <= 6)
        {
            return
        }
        if (SSOK_SidebarSavedW < SSOK_SidebarMinW)
            SSOK_SidebarSavedW := SSOK_SidebarMinW
        SSOK_SidebarCustomPos := 1
        SSOK_SaveUnifiedIni()
    }
return

SSOK_Sidebar_ApplyWidth(w)
{
    global SSOK_SidebarMinW
    global QIText1, QIText2, QIText3, QIText4, QIText5
    global SSOK_QF_Text1, SSOK_QF_Text2, SSOK_QF_Text3, SSOK_QF_Text4, SSOK_QF_Text5
    global SSOK_QU_Name1, SSOK_QU_Name2, SSOK_QU_Name3, SSOK_QU_Name4, SSOK_QU_Name5
    global SSOK_AI_SiteName1, SSOK_AI_SiteName2, SSOK_AI_SiteName3, SSOK_AI_SiteName4, SSOK_AI_SiteName5

    if (w < SSOK_SidebarMinW)
        w := SSOK_SidebarMinW
    captionW := w - 15
    buttonW := w - 16
    sepW := w - 24
    footerW := w - 4
    orgEditW := w - 52
    if (orgEditW < 60)
        orgEditW := 60
    smallButtonW := Floor((w - 17) / 5)
    if (smallButtonW < 19)
        smallButtonW := 19
    x1 := 8
    x2 := x1 + smallButtonW + 1
    x3 := x2 + smallButtonW + 1
    x4 := x3 + smallButtonW + 1
    x5 := x4 + smallButtonW + 1
    aiButtonW := Floor((w - 22) / 2)
    if (aiButtonW < 45)
        aiButtonW := 45
    aiX1 := 9
    aiX2 := aiX1 + aiButtonW + 5
    aiConvert1X := Floor(w / 2) - 32
    aiConvert2X := Floor(w / 2) + 18
    qaSearchGap := 2
    qaSearchW := Floor((buttonW - qaSearchGap) / 2)
    if (qaSearchW < 44)
        qaSearchW := 44
    qaSearchX1 := 8
    qaSearchX2 := qaSearchX1 + qaSearchW + qaSearchGap
    qfMainButtonW := 64
    qfSearchX := 70
    qfSearchW := w - 77
    if (qfSearchW < 30)
        qfSearchW := 30
    quMainButtonW := 60
    quSearchX := 69
    quSearchW := w - 76
    if (quSearchW < 30)
        quSearchW := 30
    alarmTimeW := w - 58
    if (alarmTimeW < 54)
        alarmTimeW := 54
    pcOffW := w - 36
    if (pcOffW < 76)
        pcOffW := 76
    settingsX := w - 25
    chars := 1
    if (w >= 170)
        chars := 2
    if (w >= 250)
        chars := 3

    GuiControl, SSOKSide:MoveDraw, SSOK_OrgNameEdit, w%orgEditW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarHintF1, w%captionW%
    f1W := buttonW - 32
    if (f1W < 50)
        f1W := 50
    calcX := 8 + f1W + 2
    calcW := buttonW - f1W - 2
    if (calcW < 26)
        calcW := 26
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnF1, w%f1W%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnCalc, x%calcX% w%calcW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQI1, x%x1% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQI2, x%x2% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQI3, x%x3% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQI4, x%x4% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQI5, x%x5% w%smallButtonW%
    label := SSOK_Sidebar_FirstCharLabel(QIText1, "1", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQI1, %label%
    label := SSOK_Sidebar_FirstCharLabel(QIText2, "2", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQI2, %label%
    label := SSOK_Sidebar_FirstCharLabel(QIText3, "3", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQI3, %label%
    label := SSOK_Sidebar_FirstCharLabel(QIText4, "4", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQI4, %label%
    label := SSOK_Sidebar_FirstCharLabel(QIText5, "5", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQI5, %label%

    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarSepF2, w%sepW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarHintF2, w%captionW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnDraft, w%f1W%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnExpense, x%calcX% w%calcW%
    if (buttonW >= 135)
    {
        Gui, SSOKSide:Font, s9 bold c006400, Malgun Gothic
        GuiControl, SSOKSide:Font, SSOK_SidebarOneShot
        GuiControl, SSOKSide:, SSOK_SidebarOneShot, % Chr(9889) . "   " . Chr(54620) . Chr(48169) . " " . Chr(51221) . Chr(47532) . "   " . Chr(9889)
    }
    else if (buttonW >= 115)
    {
        Gui, SSOKSide:Font, s9 bold c006400, Malgun Gothic
        GuiControl, SSOKSide:Font, SSOK_SidebarOneShot
        GuiControl, SSOKSide:, SSOK_SidebarOneShot, % Chr(9889) . "  " . Chr(54620) . Chr(48169) . " " . Chr(51221) . Chr(47532) . "  " . Chr(9889)
    }
    else
    {
        Gui, SSOKSide:Font, s8 bold c006400, Malgun Gothic
        GuiControl, SSOKSide:Font, SSOK_SidebarOneShot
        GuiControl, SSOKSide:, SSOK_SidebarOneShot, % Chr(9889) . " " . Chr(54620) . Chr(48169) . " " . Chr(51221) . Chr(47532) . " " . Chr(9889)
    }
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarOneShot, w%buttonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarSepAI, w%sepW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnAIDraft, x%aiX1% w%aiButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnAIPlan, x%aiX2% w%aiButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarAIConvert1, x%aiConvert1X%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarAIConvert2, x%aiConvert2X%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarSepQA, w%sepW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarHintQA, w%captionW%
    GuiControl, SSOKSide:MoveDraw, SSOK_ACC_SideQuery, x%qaSearchX1% w%qaSearchW%
    GuiControl, SSOKSide:MoveDraw, SSOK_WRK_SideQuery, x%qaSearchX2% w%qaSearchW%
    GuiControl, SSOKSide:MoveDraw, SSOK_LAW_SideQuery, x%qaSearchX1% w%qaSearchW%
    GuiControl, SSOKSide:MoveDraw, SSOK_EDU_SideQuery, x%qaSearchX2% w%qaSearchW%

    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarSepF4, w%sepW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarHintF4, w%captionW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnFile, w%qfMainButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_QF_SideKeyword, x%qfSearchX% w%qfSearchW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQF1, x%x1% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQF2, x%x2% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQF3, x%x3% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQF4, x%x4% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQF5, x%x5% w%smallButtonW%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text1, "1", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQF1, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text2, "2", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQF2, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text3, "3", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQF3, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text4, "4", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQF4, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QF_Text5, "5", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQF5, %label%

    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarSepF5, w%sepW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarHintF5, w%captionW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnUrl, w%quMainButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_QU_SideKeyword, x%quSearchX% w%quSearchW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQU1, x%x1% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQU2, x%x2% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQU3, x%x3% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQU4, x%x4% w%smallButtonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarQU5, x%x5% w%smallButtonW%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name1, "1", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQU1, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name2, "2", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQU2, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name3, "3", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQU3, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name4, "4", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQU4, %label%
    label := SSOK_Sidebar_FirstCharLabel(SSOK_QU_Name5, "5", chars)
    GuiControl, SSOKSide:, SSOK_SidebarQU5, %label%

    GuiControl, SSOKSide:MoveDraw, SSOK_MajorTodoEdit, w%buttonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_AlarmTimeEdit, w%alarmTimeW%
    GuiControl, SSOKSide:MoveDraw, SSOK_Alarm2TimeEdit, w%alarmTimeW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarHintF12, w%buttonW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnPCOff, w%pcOffW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnSettings, x%settingsX%
    bottomSplitGap := 2
    bottomSplitW := Floor((buttonW - bottomSplitGap) / 2)
    if (bottomSplitW < 45)
        bottomSplitW := 45
    captureX := 8
    hideX := captureX + bottomSplitW + bottomSplitGap
    captureTextX := captureX + 1
    hideTextX := hideX + 1
    splitLabelW := bottomSplitW - 2
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnCapture, x%captureX% w%bottomSplitW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnCaptureTitle, x%captureTextX% w%splitLabelW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnCaptureSub, x%captureTextX% w%splitLabelW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnHide, x%hideX% w%bottomSplitW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnHideTitle, x%hideTextX% w%splitLabelW%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnHideSub, x%hideTextX% w%splitLabelW%
    footer1W := Floor(footerW * 0.46)
    if (footer1W < 50)
        footer1W := 50
    footer2X := 2 + footer1W
    footer2W := footerW - footer1W
    if (footer2W < 58)
        footer2W := 58
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarFooter1, x2 w%footer1W%
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarFooter2, x%footer2X% w%footer2W%
}

SSOK_Sidebar_FirstCharLabel(text, fallback, maxChars := 1)
{
    t := Trim(text, " `t`r`n")
    if (t = "")
        return fallback
    if (InStr(t, "¿©±â¿¡") = 1)
        return fallback
    if (maxChars < 1)
        maxChars := 1
    return SubStr(t, 1, maxChars)
}

SSOK_GetSidebarAttachedGuiPos(guiW, guiH, ByRef outX, ByRef outY, forceLeft := false)
{
    global SSOK_SidebarHwnd, SSOK_SidebarMiniHwnd, SSOK_SidebarSavedY

    SysGet, SSOK_AttachWork, MonitorWorkArea
    gap := 8
    sideX := ""
    sideY := ""
    sideW := 112
    sideH := 650

    if (SSOK_SidebarHwnd != "")
        WinGetPos, sideX, sideY, sideW, sideH, ahk_id %SSOK_SidebarHwnd%
    if (sideX = "" && SSOK_SidebarMiniHwnd != "")
        WinGetPos, sideX, sideY, sideW, sideH, ahk_id %SSOK_SidebarMiniHwnd%
    if (sideX = "")
    {
        sideW := 112
        sideX := SSOK_AttachWorkRight - sideW
        if (SSOK_SidebarSavedY != "")
            sideY := SSOK_SidebarSavedY
        else
            sideY := SSOK_AttachWorkTop + 76
    }

    outX := sideX - guiW - (forceLeft ? 0 : gap)
    if (!forceLeft)
    {
        if (outX < SSOK_AttachWorkLeft)
            outX := sideX + sideW + gap
        if (outX + guiW > SSOK_AttachWorkRight)
            outX := SSOK_AttachWorkRight - guiW
        if (outX < SSOK_AttachWorkLeft)
            outX := SSOK_AttachWorkLeft
    }

    outY := sideY
    if (outY + guiH > SSOK_AttachWorkBottom)
        outY := SSOK_AttachWorkBottom - guiH
    if (outY < SSOK_AttachWorkTop)
        outY := SSOK_AttachWorkTop
}

SSOK_Sidebar_PrepareAction:
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    if (SSOK_SidebarTargetHwnd != "")
    {
        WinActivate, ahk_id %SSOK_SidebarTargetHwnd%
        Sleep, 120
    }
return


SSOK_Sidebar_QI1:
    SSOK_Sidebar_QINumber := 1
    Gosub, SSOK_Sidebar_QuickInput
return

SSOK_Sidebar_QI2:
    SSOK_Sidebar_QINumber := 2
    Gosub, SSOK_Sidebar_QuickInput
return

SSOK_Sidebar_QI3:
    SSOK_Sidebar_QINumber := 3
    Gosub, SSOK_Sidebar_QuickInput
return

SSOK_Sidebar_QI4:
    SSOK_Sidebar_QINumber := 4
    Gosub, SSOK_Sidebar_QuickInput
return

SSOK_Sidebar_QI5:
    SSOK_Sidebar_QINumber := 5
    Gosub, SSOK_Sidebar_QuickInput
return

SSOK_Sidebar_QuickInput:
    QILastTargetHwnd := SSOK_SidebarTargetHwnd
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, QI_Init
    Gosub, QI_LoadTexts
    if (SSOK_Sidebar_QINumber = 1)
        QIInputText := QIText1
    else if (SSOK_Sidebar_QINumber = 2)
        QIInputText := QIText2
    else if (SSOK_Sidebar_QINumber = 3)
        QIInputText := QIText3
    else if (SSOK_Sidebar_QINumber = 4)
        QIInputText := QIText4
    else if (SSOK_Sidebar_QINumber = 5)
        QIInputText := QIText5
    Gosub, QI_PasteText
return

SSOK_Sidebar_DefaultSearch:
    ControlGetFocus, SSOK_SidebarFocusedCtrl, ahk_id %SSOK_SidebarHwnd%
    if (SSOK_SidebarFocusedCtrl != "")
    {
        ControlGet, SSOK_SidebarFocusedHwnd, Hwnd,, %SSOK_SidebarFocusedCtrl%, ahk_id %SSOK_SidebarHwnd%
        if (SSOK_SidebarFocusedHwnd = SSOK_QF_SideKeywordEditHwnd)
        {
            Gosub, SSOK_QF_SidebarSearch
            return
        }
        if (SSOK_SidebarFocusedHwnd = SSOK_QU_SideKeywordEditHwnd)
        {
            Gosub, SSOK_QU_SidebarSearch
            return
        }
        if (SSOK_SidebarFocusedHwnd = SSOK_WRK_SideQueryEditHwnd)
        {
            Gosub, SSOK_WRK_SidebarSearch
            return
        }
        if (SSOK_SidebarFocusedHwnd = SSOK_LAW_SideQueryEditHwnd)
        {
            Gosub, SSOK_LAW_SidebarSearch
            return
        }
        if (SSOK_SidebarFocusedHwnd = SSOK_EDU_SideQueryEditHwnd)
        {
            Gosub, SSOK_EDU_SidebarSearch
            return
        }
        if (SSOK_SidebarFocusedHwnd = SSOK_ACC_SideQueryEditHwnd)
        {
            Gosub, SSOK_ACC_SidebarSearch
            return
        }
    }
    Gosub, SSOK_ACC_SidebarSearch
return

SSOK_ACC_SidebarSearch:
    Gui, SSOKSide:Submit, NoHide
    if (SSOK_ACC_SideIsPlaceholder || Trim(SSOK_ACC_SideQuery) = "")
        return
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    SSOK_ACC_RunSearch(SSOK_ACC_SideQuery)
return

SSOK_WRK_SidebarSearch:
    Gui, SSOKSide:Submit, NoHide
    if (SSOK_WRK_SideIsPlaceholder || Trim(SSOK_WRK_SideQuery) = "")
        return
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    SSOK_WRK_RunSearch(SSOK_WRK_SideQuery)
return

SSOK_LAW_SidebarSearch:
    Gui, SSOKSide:Submit, NoHide
    if (SSOK_LAW_SideIsPlaceholder || Trim(SSOK_LAW_SideQuery) = "")
        return
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    SSOK_LAW_RunSearch(SSOK_LAW_SideQuery)
return

SSOK_EDU_SidebarSearch:
    Gui, SSOKSide:Submit, NoHide
    if (SSOK_EDU_SideIsPlaceholder || Trim(SSOK_EDU_SideQuery) = "")
        return
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    SSOK_EDU_RunSearch(SSOK_EDU_SideQuery)
return

SSOK_QF_SidebarSearch:
    Gui, SSOKSide:Submit, NoHide
    if (SSOK_QF_SideIsPlaceholder || Trim(SSOK_QF_SideKeyword) = "")
        return
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    SSOK_ShowMatchingFileChoices(SSOK_QF_SideKeyword, 12, true)
return

SSOK_QU_SidebarSearch:
    Gui, SSOKSide:Submit, NoHide
    if (SSOK_QU_SideIsPlaceholder || Trim(SSOK_QU_SideKeyword) = "")
        return
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    SSOK_QU_OpenSmartSearch(SSOK_QU_SideKeyword)
return

SSOK_ACC_CheckSideQueryFocus:
    if (!GetKeyState("LButton", "P"))
        return
    MouseGetPos, , , , SSOK_SideMouseCtrlHwnd, 2
    if (SSOK_ACC_SideIsPlaceholder && SSOK_SideMouseCtrlHwnd = SSOK_ACC_SideQueryEditHwnd)
        SSOK_ACC_ClearSideQueryPlaceholder()
    if (SSOK_WRK_SideIsPlaceholder && SSOK_SideMouseCtrlHwnd = SSOK_WRK_SideQueryEditHwnd)
        SSOK_WRK_ClearSideQueryPlaceholder()
    if (SSOK_LAW_SideIsPlaceholder && SSOK_SideMouseCtrlHwnd = SSOK_LAW_SideQueryEditHwnd)
        SSOK_LAW_ClearSideQueryPlaceholder()
    if (SSOK_EDU_SideIsPlaceholder && SSOK_SideMouseCtrlHwnd = SSOK_EDU_SideQueryEditHwnd)
        SSOK_EDU_ClearSideQueryPlaceholder()
    if (SSOK_QF_SideIsPlaceholder && SSOK_SideMouseCtrlHwnd = SSOK_QF_SideKeywordEditHwnd)
        SSOK_QF_ClearSideKeywordPlaceholder()
    if (SSOK_QU_SideIsPlaceholder && SSOK_SideMouseCtrlHwnd = SSOK_QU_SideKeywordEditHwnd)
        SSOK_QU_ClearSideKeywordPlaceholder()
return

SSOK_ACC_ClearSideQueryPlaceholder()
{
    global SSOK_ACC_SideIsPlaceholder
    if (!SSOK_ACC_SideIsPlaceholder)
        return
    GuiControl, SSOKSide:, SSOK_ACC_SideQuery,
    Gui, SSOKSide:Font, s6 norm c000000, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_ACC_SideQuery
    SSOK_ACC_SideIsPlaceholder := false
}

SSOK_WRK_ClearSideQueryPlaceholder()
{
    global SSOK_WRK_SideIsPlaceholder
    if (!SSOK_WRK_SideIsPlaceholder)
        return
    GuiControl, SSOKSide:, SSOK_WRK_SideQuery,
    Gui, SSOKSide:Font, s6 norm c000000, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_WRK_SideQuery
    SSOK_WRK_SideIsPlaceholder := false
}

SSOK_LAW_ClearSideQueryPlaceholder()
{
    global SSOK_LAW_SideIsPlaceholder
    if (!SSOK_LAW_SideIsPlaceholder)
        return
    GuiControl, SSOKSide:, SSOK_LAW_SideQuery,
    Gui, SSOKSide:Font, s6 norm c000000, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_LAW_SideQuery
    SSOK_LAW_SideIsPlaceholder := false
}

SSOK_EDU_ClearSideQueryPlaceholder()
{
    global SSOK_EDU_SideIsPlaceholder
    if (!SSOK_EDU_SideIsPlaceholder)
        return
    GuiControl, SSOKSide:, SSOK_EDU_SideQuery,
    Gui, SSOKSide:Font, s6 norm c000000, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_EDU_SideQuery
    SSOK_EDU_SideIsPlaceholder := false
}

SSOK_QF_ClearSideKeywordPlaceholder()
{
    global SSOK_QF_SideIsPlaceholder
    if (!SSOK_QF_SideIsPlaceholder)
        return
    GuiControl, SSOKSide:, SSOK_QF_SideKeyword,
    Gui, SSOKSide:Font, s6 norm c000000, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_QF_SideKeyword
    SSOK_QF_SideIsPlaceholder := false
}

SSOK_QU_ClearSideKeywordPlaceholder()
{
    global SSOK_QU_SideIsPlaceholder
    if (!SSOK_QU_SideIsPlaceholder)
        return
    GuiControl, SSOKSide:, SSOK_QU_SideKeyword,
    Gui, SSOKSide:Font, s6 norm c000000, Malgun Gothic
    GuiControl, SSOKSide:Font, SSOK_QU_SideKeyword
    SSOK_QU_SideIsPlaceholder := false
}

SSOK_Sidebar_QF1:
    SSOK_Sidebar_QFNumber := 1
    Gosub, SSOK_Sidebar_QuickFile
return

SSOK_Sidebar_QF2:
    SSOK_Sidebar_QFNumber := 2
    Gosub, SSOK_Sidebar_QuickFile
return

SSOK_Sidebar_QF3:
    SSOK_Sidebar_QFNumber := 3
    Gosub, SSOK_Sidebar_QuickFile
return

SSOK_Sidebar_QF4:
    SSOK_Sidebar_QFNumber := 4
    Gosub, SSOK_Sidebar_QuickFile
return

SSOK_Sidebar_QF5:
    SSOK_Sidebar_QFNumber := 5
    Gosub, SSOK_Sidebar_QuickFile
return

SSOK_Sidebar_QuickFile:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_QF_LoadKeywords
    SSOK_Sidebar_QFKeyword := SSOK_QF_Text%SSOK_Sidebar_QFNumber%
    SSOK_OpenFirstMatchingFile(SSOK_Sidebar_QFKeyword)
return

SSOK_Sidebar_QU1:
    SSOK_Sidebar_QUNumber := 1
    Gosub, SSOK_Sidebar_QuickUrl
return

SSOK_Sidebar_QU2:
    SSOK_Sidebar_QUNumber := 2
    Gosub, SSOK_Sidebar_QuickUrl
return

SSOK_Sidebar_QU3:
    SSOK_Sidebar_QUNumber := 3
    Gosub, SSOK_Sidebar_QuickUrl
return

SSOK_Sidebar_QU4:
    SSOK_Sidebar_QUNumber := 4
    Gosub, SSOK_Sidebar_QuickUrl
return

SSOK_Sidebar_QU5:
    SSOK_Sidebar_QUNumber := 5
    Gosub, SSOK_Sidebar_QuickUrl
return

SSOK_Sidebar_AI_Link1:
    Gosub, SSOK_AI_LoadSites
    SSOK_Sidebar_AIUrl := SSOK_AI_SiteUrl1
    Gosub, SSOK_Sidebar_OpenAILink
return

SSOK_Sidebar_AI_Link2:
    Gosub, SSOK_AI_LoadSites
    SSOK_Sidebar_AIUrl := SSOK_AI_SiteUrl2
    Gosub, SSOK_Sidebar_OpenAILink
return

SSOK_Sidebar_AI_Link3:
    Gosub, SSOK_AI_LoadSites
    SSOK_Sidebar_AIUrl := SSOK_AI_SiteUrl3
    Gosub, SSOK_Sidebar_OpenAILink
return

SSOK_Sidebar_AI_Link4:
    Gosub, SSOK_AI_LoadSites
    SSOK_Sidebar_AIUrl := SSOK_AI_SiteUrl4
    Gosub, SSOK_Sidebar_OpenAILink
return

SSOK_Sidebar_AI_Link5:
    Gosub, SSOK_AI_LoadSites
    SSOK_Sidebar_AIUrl := SSOK_AI_SiteUrl5
    Gosub, SSOK_Sidebar_OpenAILink
return

SSOK_Sidebar_OpenAILink:
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_Sidebar_AIUrl := SSOK_QU_NormalizeUrl(SSOK_Sidebar_AIUrl)
    if (SSOK_Sidebar_AIUrl = "")
    {
        MsgBox, 48, SSOK ¾È³», AI »çÀÌÆ® ÁÖ¼Ò°¡ ºñ¾î ÀÖ½À´Ï´Ù.`n`nWin+F3 AI ¸Þ´º¿¡¼­ ÁÖ¼Ò¸¦ ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_OpenUrlPreferred(SSOK_Sidebar_AIUrl)
return

SSOK_Sidebar_QuickUrl:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_QU_LoadUrls
    SSOK_Sidebar_QUUrl := SSOK_QU_Url%SSOK_Sidebar_QUNumber%
    SSOK_Sidebar_QUUrl := SSOK_QU_NormalizeUrl(SSOK_Sidebar_QUUrl)
    if (SSOK_Sidebar_QUUrl = "")
    {
        MsgBox, 48, SSOK ¾È³», ÁÖ¼Ò°¡ ºñ¾î ÀÖ½À´Ï´Ù.`n`nWin+F5 URL ¿­±â¿¡¼­ ÁÖ¼Ò¸¦ ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_OpenUrlPreferred(SSOK_Sidebar_QUUrl)
return

SSOK_AllMenu_F1:
SSOK_Sidebar_F1:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF1
return

SSOK_Sidebar_Expense:
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_Expense_Run()
return

SSOK_Sidebar_Draft:
    Gosub, SSOK_Sidebar_PrepareAction
    DOC_TempDotInserted := false
    DOC_ShowTemplateGui()
return

SSOK_AllMenu_F2:
SSOK_Sidebar_F2:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF2
return

SSOK_AllMenu_QI:
SSOK_Sidebar_F3:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF3
return

SSOK_Sidebar_AI_Draft:
    SSOK_AI_TargetHwnd := SSOK_SidebarTargetHwnd
    Gosub, SSOK_AI_DraftMemo
return

SSOK_Sidebar_AI_Plan:
    SSOK_AI_TargetHwnd := SSOK_SidebarTargetHwnd
    Gosub, SSOK_AI_PlanDoc
return

SSOK_Sidebar_AI_Convert1:
    SSOK_AI_TargetHwnd := SSOK_SidebarTargetHwnd
    Gosub, SSOK_AI_ReportConvert1
return

SSOK_Sidebar_AI_Convert2:
    SSOK_AI_TargetHwnd := SSOK_SidebarTargetHwnd
    Gosub, SSOK_AI_ReportConvert2
return

SSOK_AllMenu_F5:
SSOK_Sidebar_F4:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF5
return

SSOK_AllMenu_F6:
SSOK_Sidebar_F5:
SSOK_Sidebar_F6:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF6
return

SSOK_AllMenu_F7:
SSOK_Sidebar_F7:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF7
return

SSOK_AllMenu_F8:
SSOK_Sidebar_F8:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF8
return

SSOK_Sidebar_F9:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoF9
return

SSOK_AllMenu_WinF10:
SSOK_Sidebar_F10:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoPrivacyMask
return

SSOK_Sidebar_OpenHomepage:
    Run, https://blog.naver.com/ssok4edu
return

SSOK_Sidebar_OpenEdufine:
    Run, https://sje.eduptl.kr/
return



SSOK_AllMenu_F12:
SSOK_Sidebar_F12:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoMouseWakeSleep
return

SSOK_Sidebar_PCOff:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoMouseWakeSleep
return

SSOK_Sidebar_Capture:
    Gosub, SSOK_Sidebar_PrepareAction
    if (!SSOK_StartCapturePreferred())
        MsgBox, 48, SSOK ¾È³», ½ºÅ©¸° Ä¸Ã³ ÅëÇÕ ¸ðµâ ½ÇÇà¿¡ ½ÇÆÐÇß½À´Ï´Ù.
return

SSOK_Sidebar_Hide:
    Gosub, SSOK_Advanced_SaveMovedPos
    if (SSOK_SidebarHwnd != "")
    {
        WinGetPos, SSOK_CurrentSidebarX, SSOK_CurrentSidebarY,,, ahk_id %SSOK_SidebarHwnd%
        SSOK_SidebarSavedX := SSOK_CurrentSidebarX
        SSOK_SidebarSavedY := SSOK_CurrentSidebarY
        SSOK_SidebarCustomPos := 1
        SysGet, SSOK_HideWorkArea, MonitorWorkArea
        SSOK_SidebarMiniX := SSOK_CurrentSidebarX + 15
        SSOK_SidebarMiniY := SSOK_HideWorkAreaBottom - 80 - 8
    }
    SetTimer, SSOK_ACC_CheckSideQueryFocus, Off
    Gui, SSOKSide:Destroy
    SSOK_SidebarVisible := 0
    Gosub, SSOK_ShowSidebarMini
return

SSOK_ShowSidebarMini:
    SysGet, SSOK_WorkArea, MonitorWorkArea
    SSOK_MiniW := 112
    SSOK_MiniH := 80
    if (SSOK_SidebarMiniX != "" && SSOK_SidebarMiniY != "")
    {
        SSOK_MiniX := SSOK_SidebarMiniX
        SSOK_MiniY := SSOK_SidebarMiniY
    }
    else
    {
        SSOK_MiniX := SSOK_WorkAreaRight - SSOK_MiniW - 83
        SSOK_MiniY := SSOK_WorkAreaBottom - SSOK_MiniH - 28
    }
    if (SSOK_MiniX < SSOK_WorkAreaLeft)
        SSOK_MiniX := SSOK_WorkAreaLeft
    if (SSOK_MiniX > SSOK_WorkAreaRight - SSOK_MiniW)
        SSOK_MiniX := SSOK_WorkAreaRight - SSOK_MiniW
    if (SSOK_MiniY < SSOK_WorkAreaTop)
        SSOK_MiniY := SSOK_WorkAreaTop
    if (SSOK_MiniY > SSOK_WorkAreaBottom - SSOK_MiniH)
        SSOK_MiniY := SSOK_WorkAreaBottom - SSOK_MiniH

    Gui, SSOKSideMini:Destroy
    Gui, SSOKSideMini:+AlwaysOnTop +ToolWindow -Caption +Border +HwndSSOK_SidebarMiniHwnd
    Gui, SSOKSideMini:Color, F7FBFF
    Gui, SSOKSideMini:Font, s7 bold, Malgun Gothic
    Gui, SSOKSideMini:Add, Text, x6 y6 w49 h44 +Border BackgroundF2F6FA gSSOK_SidebarMini_Capture,
    Gui, SSOKSideMini:Font, s6 bold, Malgun Gothic
    Gui, SSOKSideMini:Add, Text, x7 y15 w47 h12 BackgroundF2F6FA c005BAC Center gSSOK_SidebarMini_Capture, ½ºÅ©¸°Ä¸Ã³
    Gui, SSOKSideMini:Font, s6 norm, Malgun Gothic
    Gui, SSOKSideMini:Add, Text, x7 y30 w47 h10 BackgroundF2F6FA c005BAC Center gSSOK_SidebarMini_Capture, win + S
    Gui, SSOKSideMini:Font, s7 bold, Malgun Gothic
    Gui, SSOKSideMini:Add, Text, x57 y6 w49 h44 +Border +0x200 BackgroundFFF8F1 cA33A3A Center gSSOK_SidebarMini_ShowOrMove, ÀüÃ¼`nº¸±â
    Gui, SSOKSideMini:Font, s8 norm, Malgun Gothic
    ; ÁýÁß¸ðµå ¹Ì´ÏÃ¢Àº NoActivate/¹«Á¦¸ñ Ã¢ÀÌ¶ó Button Å¬¸¯ÀÌ È¯°æ¿¡ µû¶ó Ã¢ ¼û±èÃ³·³ º¸ÀÏ ¼ö ÀÖ¾î
    ; Text(+Border) ÄÁÆ®·Ñ¿¡ Á÷Á¢ Á¾·á¿Í ÀÚµ¿½ÇÇà ÇØÁ¦ µ¿ÀÛÀ» ¿¬°áÇÕ´Ï´Ù.
    Gui, SSOKSideMini:Add, Text, x18 y58 w76 h16 vSSOK_SidebarMiniExitDeleteBtn +Border +0x200 BackgroundF2F6FA c555555 Center gSSOK_Sidebar_Delete, Á¾·á
    Gui, SSOKSideMini:Show, NoActivate x%SSOK_MiniX% y%SSOK_MiniY% w%SSOK_MiniW% h%SSOK_MiniH%, SSOK ¹Ù·Îº¸±â
    WinSet, AlwaysOnTop, On, ahk_id %SSOK_SidebarMiniHwnd%
    SSOK_SidebarMiniVisible := 1
    SetTimer, SSOK_Sidebar_KeepOnTop, 2000
return

SSOK_SidebarMini_Capture:
    Gosub, SSOK_Sidebar_Capture
return

SSOK_SidebarMini_ShowOrMove:
    if (SSOK_SidebarMiniHwnd = "")
        return
    MouseGetPos, SSOK_MiniMoveStartX, SSOK_MiniMoveStartY
    PostMessage, 0xA1, 2,,, ahk_id %SSOK_SidebarMiniHwnd%
    SetTimer, SSOK_SidebarMini_FinishShowOrMove, -250
return

SSOK_SidebarMini_FinishShowOrMove:
    if (GetKeyState("LButton", "P"))
    {
        SetTimer, SSOK_SidebarMini_FinishShowOrMove, -250
        return
    }
    if (SSOK_SidebarMiniHwnd != "")
    {
        WinGetPos, SSOK_SidebarMiniX, SSOK_SidebarMiniY,,, ahk_id %SSOK_SidebarMiniHwnd%
        MouseGetPos, SSOK_MiniMoveEndX, SSOK_MiniMoveEndY
        SSOK_MiniMoveDeltaX := Abs(SSOK_MiniMoveEndX - SSOK_MiniMoveStartX)
        SSOK_MiniMoveDeltaY := Abs(SSOK_MiniMoveEndY - SSOK_MiniMoveStartY)
        if (SSOK_MiniMoveDeltaX <= 3 && SSOK_MiniMoveDeltaY <= 3)
            Gosub, SSOK_ShowSidebar
    }
return

SSOK_Sidebar_ShowButton:
    Gosub, SSOK_ShowSidebar
return

SSOK_TrayTogglePrintPause:
    SSOK_SetPrintPause(!SSOK_PrintPauseActive)
return
SSOK_SetPrintPause(enable, notify := true)
{
    global SSOK_PrintPauseActive, SSOK_PrintPauseMenuText, APP_FULL_TITLE
    global SSOK_SidebarVisible, SSOK_SidebarMiniVisible

    SSOK_PrintPauseActive := enable ? true : false
    if (SSOK_PrintPauseActive)
    {
        Suspend, On
        Menu, Tray, Check, %SSOK_PrintPauseMenuText%
        Menu, Tray, Tip, SSOK Ãâ·Â ÀÏ½ÃÁ¤Áö Áß
        SetTimer, SSOK_Sidebar_TrackTarget, Off
        SetTimer, SSOK_Sidebar_KeepOnTop, Off
        SetTimer, SSOK_ACC_CheckSideQueryFocus, Off
        SetTimer, SSOK_WatchActiveWindow, Off
        SetTimer, SSOK_NumberWatchClick, Off
        SetTimer, SSOK_WinHelp_ShowNow, Off
        SetTimer, SSOK_WinHelp_Watch, Off
        SetTimer, SSOK_WinHelp_CloseNativeMenuIfOpened, Off
        SetTimer, SSOK_AI_TrackTargetWindow, Off
        if (notify)
        {
            ToolTip, SSOK Ãâ·Â ÀÏ½ÃÁ¤Áö ÁßÀÔ´Ï´Ù.
            SetTimer, RemoveToolTip, -1200
        }
        return
    }

    Suspend, Off
    Menu, Tray, Uncheck, %SSOK_PrintPauseMenuText%
    Menu, Tray, Tip, %APP_FULL_TITLE%
    if (SSOK_SidebarVisible)
    {
        SetTimer, SSOK_Sidebar_TrackTarget, 300
        SetTimer, SSOK_Sidebar_KeepOnTop, 2000
        SetTimer, SSOK_ACC_CheckSideQueryFocus, 50
    }
    else if (SSOK_SidebarMiniVisible)
    {
        SetTimer, SSOK_Sidebar_KeepOnTop, 2000
    }
    if (notify)
    {
        ToolTip, SSOK ´Ù½Ã ½ÃÀÛµÊ.
        SetTimer, RemoveToolTip, -1200
    }
}

SSOK_Sidebar_MiniExit:
    ; ÁýÁß¸ðµå ÇÏ´Ü [Á¾·á]: ÇÁ·Î±×·¥À» Á¾·áÇÏ°í ÀÚµ¿½ÇÇà µî·Ïµµ ÇØÁ¦ÇÕ´Ï´Ù.
    Gosub, SSOK_DeleteDailyAutoRun
    Gosub, SSOK_ExitApplicationNow
return

SSOK_Sidebar_Delete:
    ; ÁýÁß¸ðµå ÇÏ´Ü [Á¾·á]: ÇÁ·Î±×·¥À» Á¾·áÇÏ°í ÀÚµ¿½ÇÇà µî·Ï¸¸ ÇØÁ¦ÇÕ´Ï´Ù.
    Gosub, SSOK_DeleteDailyAutoRun
    Gosub, SSOK_ExitApplicationNow
return

SSOK_ExitApplicationNow:
    ; ÇöÀç ½ÇÇà ÁßÀÎ SSOK º»Ã¼¿Í SSOK ³»ºÎ Ä¸Ã³ ÆíÁýÃ¢/Å¸ÀÌ¸Ó¸¦ Á¤¸®ÇÑ µÚ ¿ÏÀüÈ÷ Á¾·áÇÕ´Ï´Ù.
    Critical
    SetTimer, SSOK_Sidebar_KeepOnTop, Off
    SetTimer, SSOK_Sidebar_TrackTarget, Off
    SetTimer, SSOK_ACC_CheckSideQueryFocus, Off
    SetTimer, SSOK_CheckMajorTodoReminder, Off
    SetTimer, SSOK_CheckPowerOffSchedule, Off
    SetTimer, SSOK_SidebarMini_FinishShowOrMove, Off
    SetTimer, SSOK_WatchActiveWindow, Off
    SetTimer, SSOK_NumberWatchClick, Off
    SetTimer, SSOK_ClearTip, Off
    try
        SSOK_Capture_EmbeddedClose()
    Gui, SSOKSideMini:Destroy
    Gui, SSOKSide:Destroy
    Gui, SSOKWorkTools:Destroy
    Gui, SSOKAdvanced:Destroy
    Gui, SSOKPowerSchedule:Destroy
    Gui, CaptureTools:Destroy
    Gui, Editor:Destroy
    Gui, Stamp:Destroy
    Gui, QIQuick:Destroy
    Gui, SSOKAlarmCenter:Destroy
    Gui, SSOKQuitAlarm:Destroy
    Gui, SSOKCalc:Destroy
    Gui, SSOKAutoClick:Destroy
    Gui, SSOKSchool:Destroy
    Gui, SSOKQuickUrl:Destroy
    Gui, SSOKQuickFile:Destroy
    Gui, SSOKAppRecent:Destroy
    Gui, SSOKFileChoices:Destroy
    Gui, SSOKFileNotice:Destroy
    Gui, SSOKGeminiAI:Destroy
    Gui, SSOKWinHelp:Destroy
    Gui, SSOKACC:Destroy
    SSOK_RunExitCleanup()
    ; SSOK ÀÚ½ÅÀÇ AutoHotkeyU64.exe ÇÁ·Î¼¼½º PID¸¸ °­Á¦ Á¾·áÇÏµµ·Ï
    ; º°µµ cmd ÇÁ·Î¼¼½º¸¦ Àá½Ã ¶ç¿î µÚ ÇöÀç ÇÁ·Î¼¼½º¸¦ Á¤»ó Á¾·áÇÕ´Ï´Ù.
    ; ´Ù¸¥ AutoHotkey ÇÁ·Î±×·¥ÀÇ ÇÁ·Î¼¼½º´Â °Çµå¸®Áö ¾Ê½À´Ï´Ù.
    SSOK_ForceTerminateOwnProcess()
    ExitApp
return

SSOK_ForceTerminateOwnProcess()
{
    pid := DllCall("GetCurrentProcessId", "UInt")
    if (!pid)
        return false

    cleanupCmd := A_Temp "\SSOK_KillSelf_" pid "_" A_TickCount ".cmd"

    FileDelete, %cleanupCmd%
    FileAppend, @echo off`r`n, %cleanupCmd%, UTF-8
    FileAppend, timeout /t 2 /nobreak >nul`r`n, %cleanupCmd%, UTF-8
    FileAppend, taskkill /PID %pid% /F /T >nul 2>&1`r`n, %cleanupCmd%, UTF-8
    FileAppend, % "del /f /q """ . Chr(37) . "~f0"" >nul 2>&1`r`n", %cleanupCmd%, UTF-8

    Run, %ComSpec% /c ""%cleanupCmd%"",, Hide
    return true
}

SSOK_ForceKillSelf:
    SSOK_ForceTerminateOwnProcess()
    ExitApp
return

SSOKAllMenuGuiEscape:
SSOKAllMenuGuiClose:
SSOKSideGuiEscape:
SSOKSideGuiClose:
    Gosub, SSOK_Sidebar_Hide
return

SSOK_Sidebar_EnableResizeSave:
    SSOK_SidebarResizeReady := 1
return

SSOKSideGuiSize:
    if (A_EventInfo = 1 || SSOK_SidebarHwnd = "")
        return
    if (SSOK_SidebarResizeReady != 1)
        return
    SSOK_SidebarSavedW := A_GuiWidth + 0
    if (SSOK_SidebarSavedW < SSOK_SidebarMinW)
        SSOK_SidebarSavedW := SSOK_SidebarMinW
    SSOK_Sidebar_ApplyWidth(SSOK_SidebarSavedW)
    if (SSOK_SidebarH != "" && A_GuiHeight != SSOK_SidebarH)
        WinMove, ahk_id %SSOK_SidebarHwnd%,,,, %SSOK_SidebarSavedW%, %SSOK_SidebarH%
    SetTimer, SSOK_Sidebar_SaveResizedWidth, -400
return

SSOK_Sidebar_SaveResizedWidth:
    if (GetKeyState("LButton", "P"))
    {
        SetTimer, SSOK_Sidebar_SaveResizedWidth, -400
        return
    }
    if (SSOK_SidebarHwnd != "")
    {
        WinGetPos, SSOK_SidebarSavedX, SSOK_SidebarSavedY,,, ahk_id %SSOK_SidebarHwnd%
        if (SSOK_SidebarSavedW < SSOK_SidebarMinW)
            SSOK_SidebarSavedW := SSOK_SidebarMinW
        SSOK_SidebarCustomPos := 1
        SSOK_SaveUnifiedIni()
    }
return

SSOKSideMiniGuiEscape:
SSOKSideMiniGuiClose:
    Gui, SSOKSideMini:Destroy
    SSOK_SidebarMiniVisible := 0
return

; =========================================================
; Win + F5 : ÀÚÁÖ°¡´Â »çÀÌÆ® 9°³ ¹Ù·Î ¿­±â
; =========================================================
#F5::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF6
return

SSOK_DoF5:
    Gosub, SSOK_ShowQuickFileMenu
return

; =========================================================
; Win + F6 : »ç¿ë ¾È ÇÔ
; =========================================================
#F6::
return

SSOK_DoF6:
    Gosub, SSOK_ShowQuickUrlMenu
return

; Win+F2 ¹®¼­Á¤¸® ±â´ÉÀº º°µµ ¸ðµâ·Î ºÐ¸®Çß½À´Ï´Ù.
; UIA module disabled: K-¿¡µàÆÄÀÎ È¯°æ¿¡¼­ ¾ÈÁ¤¼ºÀÌ ³·¾Æ ÇöÀç ¹èÆ÷º»¿¡¼­´Â ¿¬°áÇÏÁö ¾Ê½À´Ï´Ù.
; #Include %A_ScriptDir%\ssok_uia.ahk
#Include %A_ScriptDir%\ssok_doc.ahk

; Win + F5 : ÀÚÁÖ ¿©´Â ÆÄÀÏ Å°¿öµå °Ë»ö
; - Å°¿öµå 1~12´Â ssok.ini [F5QuickFiles]¿¡ ÀúÀå
; - °Ë»ö À§Ä¡: ssok.ini [F5QuickFileFolders]¿¡¼­ »ç¿ëÀÚ°¡ ¼±ÅÃ
; - ÆÄÀÏ¸í ±âÁØÀ¸·Î¸¸ °Ë»ö
; - °°Àº ÆÄÀÏ¸íÀÌ ¿©·¯ °÷¿¡ ÀÖÀ¸¸é ¼öÁ¤ÀÏ ±âÁØ ÃÖ½Å ÆÄÀÏ ¿­±â
; =========================================================

SSOK_ShowQuickFileMenu:
    Gosub, SSOK_QF_LoadKeywords
    SSOK_QF_LoadFolderSettings()

    Gui, SSOKQuickFile:Destroy
    Gui, SSOKQuickFile:+ToolWindow -MinimizeBox
    Gui, SSOKQuickFile:Color, F7FBFF
    Gui, SSOKQuickFile:Font, s17 bold, Malgun Gothic
    Gui, SSOKQuickFile:Add, Text, x20 y16 w640 h34 c005BAC Center, ÀÚÁÖ »ç¿ëÇÏ´Â ÆÄÀÏ ¹Ù·Î ¿­±â
    Gui, SSOKQuickFile:Font, s8 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Button, x535 y20 w120 h24 gSSOK_QF_ShowAppRecentMenu, ÃÖ±Ù¹®¼­
    Gui, SSOKQuickFile:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Text, x20 y52 w640 h20 c555555 Center, ¼ýÀÚ´Â ¹Ù·Î ¿­±â, [ÀúÀå&&¿­±â]´Â ÀúÀå ÈÄ ¿­±â, [Æú´õ]´Â Æú´õ¸¸ ¿±´Ï´Ù.
    Gui, SSOKQuickFile:Font, s10 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Text, x20 y82 w24 h24 c005BAC Center, 1
    Gui, SSOKQuickFile:Add, Edit, x50 y78 w445 h28 vSSOK_QF_Edit1, %SSOK_QF_Text1%
    Gui, SSOKQuickFile:Add, Button, x500 y77 w105 h30 gSSOK_QF_Open1, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y77 w45 h30 gSSOK_QF_Folder1, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y116 w24 h24 c005BAC Center, 2
    Gui, SSOKQuickFile:Add, Edit, x50 y112 w445 h28 vSSOK_QF_Edit2, %SSOK_QF_Text2%
    Gui, SSOKQuickFile:Add, Button, x500 y111 w105 h30 gSSOK_QF_Open2, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y111 w45 h30 gSSOK_QF_Folder2, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y150 w24 h24 c005BAC Center, 3
    Gui, SSOKQuickFile:Add, Edit, x50 y146 w445 h28 vSSOK_QF_Edit3, %SSOK_QF_Text3%
    Gui, SSOKQuickFile:Add, Button, x500 y145 w105 h30 gSSOK_QF_Open3, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y145 w45 h30 gSSOK_QF_Folder3, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y184 w24 h24 c005BAC Center, 4
    Gui, SSOKQuickFile:Add, Edit, x50 y180 w445 h28 vSSOK_QF_Edit4, %SSOK_QF_Text4%
    Gui, SSOKQuickFile:Add, Button, x500 y179 w105 h30 gSSOK_QF_Open4, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y179 w45 h30 gSSOK_QF_Folder4, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y218 w24 h24 c005BAC Center, 5
    Gui, SSOKQuickFile:Add, Edit, x50 y214 w445 h28 vSSOK_QF_Edit5, %SSOK_QF_Text5%
    Gui, SSOKQuickFile:Add, Button, x500 y213 w105 h30 gSSOK_QF_Open5, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y213 w45 h30 gSSOK_QF_Folder5, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y252 w24 h24 c005BAC Center, 6
    Gui, SSOKQuickFile:Add, Edit, x50 y248 w445 h28 vSSOK_QF_Edit6, %SSOK_QF_Text6%
    Gui, SSOKQuickFile:Add, Button, x500 y247 w105 h30 gSSOK_QF_Open6, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y247 w45 h30 gSSOK_QF_Folder6, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y286 w24 h24 c005BAC Center, 7
    Gui, SSOKQuickFile:Add, Edit, x50 y282 w445 h28 vSSOK_QF_Edit7, %SSOK_QF_Text7%
    Gui, SSOKQuickFile:Add, Button, x500 y281 w105 h30 gSSOK_QF_Open7, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y281 w45 h30 gSSOK_QF_Folder7, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y320 w24 h24 c005BAC Center, 8
    Gui, SSOKQuickFile:Add, Edit, x50 y316 w445 h28 vSSOK_QF_Edit8, %SSOK_QF_Text8%
    Gui, SSOKQuickFile:Add, Button, x500 y315 w105 h30 gSSOK_QF_Open8, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y315 w45 h30 gSSOK_QF_Folder8, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y354 w24 h24 c005BAC Center, 9
    Gui, SSOKQuickFile:Add, Edit, x50 y350 w445 h28 vSSOK_QF_Edit9, %SSOK_QF_Text9%
    Gui, SSOKQuickFile:Add, Button, x500 y349 w105 h30 gSSOK_QF_Open9, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y349 w45 h30 gSSOK_QF_Folder9, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y388 w24 h24 c005BAC Center, 10
    Gui, SSOKQuickFile:Add, Edit, x50 y384 w445 h28 vSSOK_QF_Edit10, %SSOK_QF_Text10%
    Gui, SSOKQuickFile:Add, Button, x500 y383 w105 h30 gSSOK_QF_Open10, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y383 w45 h30 gSSOK_QF_Folder10, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y422 w24 h24 c005BAC Center, 11
    Gui, SSOKQuickFile:Add, Edit, x50 y418 w445 h28 vSSOK_QF_Edit11, %SSOK_QF_Text11%
    Gui, SSOKQuickFile:Add, Button, x500 y417 w105 h30 gSSOK_QF_Open11, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y417 w45 h30 gSSOK_QF_Folder11, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x20 y456 w24 h24 c005BAC Center, 12
    Gui, SSOKQuickFile:Add, Edit, x50 y452 w445 h28 vSSOK_QF_Edit12, %SSOK_QF_Text12%
    Gui, SSOKQuickFile:Add, Button, x500 y451 w105 h30 gSSOK_QF_Open12, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x610 y451 w45 h30 gSSOK_QF_Folder12, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x30 y499 w95 h22 c333333, ´Ù¸¥ÆÄÀÏ °Ë»ö
    Gui, SSOKQuickFile:Add, Edit, x125 y495 w335 h28 vSSOK_QF_CustomKeyword
    Gui, SSOKQuickFile:Add, Button, x500 y494 w130 h30 gSSOK_QF_CustomOpen Default, °Ë»ö

    Gui, SSOKQuickFile:Font, s10 bold c005BAC, Malgun Gothic
    Gui, SSOKQuickFile:Add, Text, x20 y533 w120 h24, Setting
    Gui, SSOKQuickFile:Font, s8 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Progress, x20 y560 w635 h1 BackgroundD5DDE8 cD5DDE8
    Gui, SSOKQuickFile:Add, Text, x20 y573 w80 h22 c333333, °Ë»ö Æú´õ ¼³Á¤
    Gui, SSOKQuickFile:Add, Checkbox, x105 y571 w68 h22 vSSOK_QF_SearchDesktop Checked%SSOK_QF_SearchDesktop% gSSOK_QF_SaveFolderOptions, ¹ÙÅÁÈ­¸é
    Gui, SSOKQuickFile:Add, Checkbox, x177 y571 w68 h22 vSSOK_QF_SearchDownloads Checked%SSOK_QF_SearchDownloads% gSSOK_QF_SaveFolderOptions, ´Ù¿î·Îµå
    Gui, SSOKQuickFile:Add, Checkbox, x249 y571 w48 h22 vSSOK_QF_SearchDocuments Checked%SSOK_QF_SearchDocuments% gSSOK_QF_SaveFolderOptions, ¹®¼­
    Gui, SSOKQuickFile:Add, Checkbox, x301 y571 w72 h22 vSSOK_QF_SearchDriveD Checked%SSOK_QF_SearchDriveD% gSSOK_QF_SaveDriveDOption, D: µå¶óÀÌºê
    Gui, SSOKQuickFile:Add, Checkbox, x377 y571 w72 h22 vSSOK_QF_SearchDriveE Checked%SSOK_QF_SearchDriveE% gSSOK_QF_SaveDriveEOption, E: µå¶óÀÌºê
    Gui, SSOKQuickFile:Add, Checkbox, x453 y571 w72 h22 vSSOK_QF_SearchDriveF Checked%SSOK_QF_SearchDriveF% gSSOK_QF_SaveDriveFOption, F: µå¶óÀÌºê
    if (!InStr(FileExist("D:"), "D"))
        GuiControl, SSOKQuickFile:Disable, SSOK_QF_SearchDriveD
    if (!InStr(FileExist("E:"), "D"))
        GuiControl, SSOKQuickFile:Disable, SSOK_QF_SearchDriveE
    if (!InStr(FileExist("F:"), "D"))
        GuiControl, SSOKQuickFile:Disable, SSOK_QF_SearchDriveF

    Gui, SSOKQuickFile:Add, Progress, x20 y606 w635 h1 BackgroundD5DDE8 cD5DDE8
    Gui, SSOKQuickFile:Add, Text, x20 y619 w80 h22 c333333, °Ë»ö ÆÄÀÏ ¼³Á¤
    Gui, SSOKQuickFile:Add, Checkbox, x130 y617 w84 h22 vSSOK_QF_ExtHwp Checked%SSOK_QF_ExtHwp% gSSOK_QF_SaveFolderOptions, hwp(ÇÑ±Û)
    Gui, SSOKQuickFile:Add, Checkbox, x220 y617 w84 h22 vSSOK_QF_ExtXls Checked%SSOK_QF_ExtXls% gSSOK_QF_SaveFolderOptions, xls(¿¢¼¿)
    Gui, SSOKQuickFile:Add, Checkbox, x310 y617 w84 h22 vSSOK_QF_ExtDoc Checked%SSOK_QF_ExtDoc% gSSOK_QF_SaveFolderOptions, doc(¿öµå)
    Gui, SSOKQuickFile:Add, Checkbox, x400 y617 w96 h22 vSSOK_QF_ExtPpt Checked%SSOK_QF_ExtPpt% gSSOK_QF_SaveFolderOptions, PPT(½½¶óÀÌµå)
    Gui, SSOKQuickFile:Add, Checkbox, x504 y617 w50 h22 vSSOK_QF_ExtTxt Checked%SSOK_QF_ExtTxt% gSSOK_QF_SaveFolderOptions, txt
    Gui, SSOKQuickFile:Add, Checkbox, x560 y617 w50 h22 vSSOK_QF_ExtPdf Checked%SSOK_QF_ExtPdf% gSSOK_QF_SaveFolderOptions, pdf

    Gui, SSOKQuickFile:Add, Text, x20 y655 w420 h18 c999999, SSOK ÀÚÃ¼°Ë»öÀº D/E/F Áß ¼±ÅÃÇÑ 1°³ µå¶óÀÌºê¸¸ Ãß°¡ °Ë»öÇÕ´Ï´Ù.
    Gui, SSOKQuickFile:Add, Text, x450 y655 w205 h18 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£
    SSOK_GetSidebarAttachedGuiPos(680, 685, SSOK_QF_WinX, SSOK_QF_WinY)
    Gui, SSOKQuickFile:Show, x%SSOK_QF_WinX% y%SSOK_QF_WinY% w680 h685, SSOK ÀÚÁÖ ¿©´Â ÆÄÀÏ
return
SSOKQuickFileGuiEscape:
SSOKQuickFileGuiClose:
    Gui, SSOKQuickFile:Destroy
return

; ÀÚÁÖ ¿©´Â ÆÄÀÏ Ã¢ÀÌ ¶° ÀÖÀ» ¶§ ¼ýÀÚ 1~9¸¦ ´©¸£¸é ÀúÀåÇÏÁö ¾Ê°í ¹Ù·Î ¿±´Ï´Ù.
; ÀÔ·ÂÄ­¿¡ Ä¿¼­°¡ ÀÖÀ¸¸é ¼ýÀÚ¸¦ ±×´ë·Î ÀÔ·ÂÇÕ´Ï´Ù.
#IfWinActive, SSOK ÀÚÁÖ ¿©´Â ÆÄÀÏ
1::
    SSOK_QF_HandleNumberHotkey(1, "1")
return
2::
    SSOK_QF_HandleNumberHotkey(2, "2")
return
3::
    SSOK_QF_HandleNumberHotkey(3, "3")
return
4::
    SSOK_QF_HandleNumberHotkey(4, "4")
return
5::
    SSOK_QF_HandleNumberHotkey(5, "5")
return
6::
    SSOK_QF_HandleNumberHotkey(6, "6")
return
7::
    SSOK_QF_HandleNumberHotkey(7, "7")
return
8::
    SSOK_QF_HandleNumberHotkey(8, "8")
return
9::
    SSOK_QF_HandleNumberHotkey(9, "9")
return
Numpad1::
    SSOK_QF_HandleNumberHotkey(1, "1")
return
Numpad2::
    SSOK_QF_HandleNumberHotkey(2, "2")
return
Numpad3::
    SSOK_QF_HandleNumberHotkey(3, "3")
return
Numpad4::
    SSOK_QF_HandleNumberHotkey(4, "4")
return
Numpad5::
    SSOK_QF_HandleNumberHotkey(5, "5")
return
Numpad6::
    SSOK_QF_HandleNumberHotkey(6, "6")
return
Numpad7::
    SSOK_QF_HandleNumberHotkey(7, "7")
return
Numpad8::
    SSOK_QF_HandleNumberHotkey(8, "8")
return
Numpad9::
    SSOK_QF_HandleNumberHotkey(9, "9")
return
#IfWinActive

SSOK_QF_HandleNumberHotkey(index, key)
{
    ControlGetFocus, focusedCtrl, SSOK ÀÚÁÖ ¿©´Â ÆÄÀÏ
    if (SubStr(focusedCtrl, 1, 4) = "Edit")
    {
        SendInput, %key%
        return
    }
    SSOK_QF_OpenOnlyIndex(index)
}
SSOK_QF_SetDefaults:
    SSOK_QF_Text1 := "¿©±â¿¡ ÀÚÁÖ»ç¿ëÇÏ´Â ÆÄÀÏ¸íÀ» °£·«È÷ ÀÔ·ÂÇÏ¼¼¿ä. ¹Ù·Î Ã£¾Æ ½ÇÇàÇÒ ¼ö ÀÖ½À´Ï´Ù"
    SSOK_QF_Text2 := "ºñ»ó¿¬¶ô"
    SSOK_QF_Text3 := "ºÐÀå"
    SSOK_QF_Text4 := "ÇÐ±ÞÆí¼º"
    SSOK_QF_Text5 := "½Ã°£Ç¥"
    SSOK_QF_Text6 := "¹èÄ¡µµ"
    SSOK_QF_Text7 := "ÀÏ¶÷"
    SSOK_QF_Text8 := "°¢¸ñ³»¿ª¼­"
    SSOK_QF_Text9 := "ÁýÇàÁöÄ§"
    SSOK_QF_Text10 := "°è¾à"
    SSOK_QF_Text11 := "Ç°ÀÇ"
    SSOK_QF_Text12 := "°èÈ¹"
return

SSOK_QF_LoadKeywords:
    Gosub, SSOK_QF_SetDefaults
    SSOK_QF_Ini := SSOK_IniFile
    if !FileExist(SSOK_QF_Ini)
    {
        Gosub, SSOK_QF_SaveIni
        return
    }
    IniRead, v1, %SSOK_QF_Ini%, F5QuickFiles, Keyword1, %SSOK_QF_Text1%
    IniRead, v2, %SSOK_QF_Ini%, F5QuickFiles, Keyword2, %SSOK_QF_Text2%
    IniRead, v3, %SSOK_QF_Ini%, F5QuickFiles, Keyword3, %SSOK_QF_Text3%
    IniRead, v4, %SSOK_QF_Ini%, F5QuickFiles, Keyword4, %SSOK_QF_Text4%
    IniRead, v5, %SSOK_QF_Ini%, F5QuickFiles, Keyword5, %SSOK_QF_Text5%
    IniRead, v6, %SSOK_QF_Ini%, F5QuickFiles, Keyword6, %SSOK_QF_Text6%
    IniRead, v7, %SSOK_QF_Ini%, F5QuickFiles, Keyword7, %SSOK_QF_Text7%
    IniRead, v8, %SSOK_QF_Ini%, F5QuickFiles, Keyword8, %SSOK_QF_Text8%
    IniRead, v9, %SSOK_QF_Ini%, F5QuickFiles, Keyword9, %SSOK_QF_Text9%
    IniRead, v10, %SSOK_QF_Ini%, F5QuickFiles, Keyword10, %SSOK_QF_Text10%
    IniRead, v11, %SSOK_QF_Ini%, F5QuickFiles, Keyword11, %SSOK_QF_Text11%
    IniRead, v12, %SSOK_QF_Ini%, F5QuickFiles, Keyword12, %SSOK_QF_Text12%
    if (v1 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v1))
        SSOK_QF_Text1 := v1
    if (v2 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v2))
        SSOK_QF_Text2 := v2
    if (v3 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v3))
        SSOK_QF_Text3 := v3
    if (v4 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v4))
        SSOK_QF_Text4 := v4
    if (v5 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v5))
        SSOK_QF_Text5 := v5
    if (v6 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v6))
        SSOK_QF_Text6 := v6
    if (v7 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v7))
        SSOK_QF_Text7 := v7
    if (v8 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v8))
        SSOK_QF_Text8 := v8
    if (v9 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v9))
        SSOK_QF_Text9 := v9
    if (v10 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v10))
        SSOK_QF_Text10 := v10
    if (v11 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v11))
        SSOK_QF_Text11 := v11
    if (v12 != "ERROR" && !SSOK_QF_IsBrokenKeyword(v12))
        SSOK_QF_Text12 := v12
return

SSOK_QF_SaveFromGui:
    Gui, SSOKQuickFile:Submit, NoHide
    SSOK_QF_Text1 := SSOK_QF_Edit1
    SSOK_QF_Text2 := SSOK_QF_Edit2
    SSOK_QF_Text3 := SSOK_QF_Edit3
    SSOK_QF_Text4 := SSOK_QF_Edit4
    SSOK_QF_Text5 := SSOK_QF_Edit5
    SSOK_QF_Text6 := SSOK_QF_Edit6
    SSOK_QF_Text7 := SSOK_QF_Edit7
    SSOK_QF_Text8 := SSOK_QF_Edit8
    SSOK_QF_Text9 := SSOK_QF_Edit9
    SSOK_QF_Text10 := SSOK_QF_Edit10
    SSOK_QF_Text11 := SSOK_QF_Edit11
    SSOK_QF_Text12 := SSOK_QF_Edit12
    Gosub, SSOK_QF_SaveIni
return

SSOK_QF_SaveIni:
    ; ÇÑ±Û Å°¿öµå ±úÁü ¹æÁö: IniWrite ´ë½Å ssok.ini ÀüÃ¼¸¦ UTF-16À¸·Î Á÷Á¢ ÀúÀåÇÕ´Ï´Ù.
    SSOK_SaveUnifiedIni()
return

SSOK_QF_SaveFolderOptions:
    SSOK_QF_SaveFolderSettingsFromGui()
return

SSOK_QF_SaveDriveDOption:
    SSOK_QF_SaveDriveOptionFromGui("D")
return

SSOK_QF_SaveDriveEOption:
    SSOK_QF_SaveDriveOptionFromGui("E")
return

SSOK_QF_SaveDriveFOption:
    SSOK_QF_SaveDriveOptionFromGui("F")
return

SSOK_QF_SelectOtherFolder:
    SSOK_QF_SelectOtherFolderFromGui()
return

SSOK_QF_ClearOtherFolder:
    SSOK_QF_ClearOtherFolderFromGui()
return



SSOK_QF_FolderDialogTopTimer:
    SSOK_QF_BringFolderDialogToFront()
return

SSOK_QF_SaveOneFromGui(index)
{
    global SSOK_QF_Ini
    global SSOK_QF_Edit1, SSOK_QF_Edit2, SSOK_QF_Edit3, SSOK_QF_Edit4, SSOK_QF_Edit5, SSOK_QF_Edit6, SSOK_QF_Edit7, SSOK_QF_Edit8, SSOK_QF_Edit9, SSOK_QF_Edit10, SSOK_QF_Edit11, SSOK_QF_Edit12
    global SSOK_QF_Text1, SSOK_QF_Text2, SSOK_QF_Text3, SSOK_QF_Text4, SSOK_QF_Text5, SSOK_QF_Text6, SSOK_QF_Text7, SSOK_QF_Text8, SSOK_QF_Text9, SSOK_QF_Text10, SSOK_QF_Text11, SSOK_QF_Text12

    Gui, SSOKQuickFile:Submit, NoHide
    SSOK_QF_Ini := SSOK_IniFile

    if (index = 1)
        SSOK_QF_Text1 := SSOK_QF_Edit1
    else if (index = 2)
        SSOK_QF_Text2 := SSOK_QF_Edit2
    else if (index = 3)
        SSOK_QF_Text3 := SSOK_QF_Edit3
    else if (index = 4)
        SSOK_QF_Text4 := SSOK_QF_Edit4
    else if (index = 5)
        SSOK_QF_Text5 := SSOK_QF_Edit5
    else if (index = 6)
        SSOK_QF_Text6 := SSOK_QF_Edit6
    else if (index = 7)
        SSOK_QF_Text7 := SSOK_QF_Edit7
    else if (index = 8)
        SSOK_QF_Text8 := SSOK_QF_Edit8
    else if (index = 9)
        SSOK_QF_Text9 := SSOK_QF_Edit9
    else if (index = 10)
        SSOK_QF_Text10 := SSOK_QF_Edit10
    else if (index = 11)
        SSOK_QF_Text11 := SSOK_QF_Edit11
    else if (index = 12)
        SSOK_QF_Text12 := SSOK_QF_Edit12

    ; ÇÑ±Û Å°¿öµå ±úÁü ¹æÁö: ÇØ´ç ÁÙ¸¸ IniWrite ÇÏÁö ¾Ê°í ÀüÃ¼ INI¸¦ UTF-16À¸·Î ´Ù½Ã ÀúÀåÇÕ´Ï´Ù.
    SSOK_SaveUnifiedIni()
}


; =========================================================
; ssok.ini ÅëÇÕ ÀúÀå ÇÔ¼ö
; - QIQuickInput, F5QuickFiles¸¦ ÇÑ ÆÄÀÏ¿¡ ÇÔ²² ÀúÀå
; - ÇÑ±Û ±úÁü ¹æÁö¸¦ À§ÇØ UTF-16À¸·Î ÀúÀå
; - ±âÁ¸ IniWrite ¹æ½Ä »ç¿ë ±ÝÁö
; =========================================================
SSOK_SaveUnifiedIni()
{
    global QIIni, QIText1, QIText2, QIText3, QIText4, QIText5, QIText6, QIText7, QIText10, QIText11, QIText12
    global QIImage12, QIImage13, QIImage14, QIImage15
    global QIDefault1, QIDefault2, QIDefault3, QIDefault4, QIDefault5, QIDefault6, QIDefault7, QIDefault10, QIDefault11, QIDefault12
    global SSOK_QF_Ini
    global SSOK_QF_Text1, SSOK_QF_Text2, SSOK_QF_Text3, SSOK_QF_Text4, SSOK_QF_Text5, SSOK_QF_Text6, SSOK_QF_Text7, SSOK_QF_Text8, SSOK_QF_Text9, SSOK_QF_Text10, SSOK_QF_Text11, SSOK_QF_Text12
    global SSOK_QF_FolderSettingsLoaded, SSOK_QF_SearchDesktop, SSOK_QF_SearchDownloads, SSOK_QF_SearchDocuments, SSOK_QF_SearchExtraFolders
    global SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    global SSOK_QF_ExtHwp, SSOK_QF_ExtXls, SSOK_QF_ExtDoc, SSOK_QF_ExtPpt, SSOK_QF_ExtTxt, SSOK_QF_ExtPdf
    global SSOK_QU_Ini
    global SSOK_QU_Name1, SSOK_QU_Name2, SSOK_QU_Name3, SSOK_QU_Name4, SSOK_QU_Name5, SSOK_QU_Name6, SSOK_QU_Name7, SSOK_QU_Name8, SSOK_QU_Name9, SSOK_QU_Name10, SSOK_QU_Name11, SSOK_QU_Name12
    global SSOK_QU_Url1, SSOK_QU_Url2, SSOK_QU_Url3, SSOK_QU_Url4, SSOK_QU_Url5, SSOK_QU_Url6, SSOK_QU_Url7, SSOK_QU_Url8, SSOK_QU_Url9, SSOK_QU_Url10, SSOK_QU_Url11, SSOK_QU_Url12
    global SSOK_QU_SaveActive
    global SSOK_QU_EduRegionPortal, SSOK_QU_EduRegionKEdufine, SSOK_QU_EduRegionNeis, SSOK_QU_EduRegionSupport, SSOK_QU_EduRegionEVPN
    global SSOK_AI_Ini
    global SSOK_AI_SiteName1, SSOK_AI_SiteName2, SSOK_AI_SiteName3, SSOK_AI_SiteName4, SSOK_AI_SiteName5
    global SSOK_AI_SiteUrl1, SSOK_AI_SiteUrl2, SSOK_AI_SiteUrl3, SSOK_AI_SiteUrl4, SSOK_AI_SiteUrl5
    global SSOK_AI_SaveActive
    global SSOK_MajorTodoEdit, SSOK_OrgNameEdit
    global SSOK_AlarmTimeEdit, SSOK_AlarmEnabled, SSOK_Alarm2TimeEdit, SSOK_Alarm2Enabled
    global SSOK_SidebarCustomPos, SSOK_SidebarSavedX, SSOK_SidebarSavedY, SSOK_SidebarSavedW, SSOK_SidebarMinW, SSOK_SidebarHwnd
    global SSOK_AdvancedCustomPos, SSOK_AdvancedSavedX, SSOK_AdvancedSavedY, SSOK_AdvancedHwnd

    if (QIIni = "")
        QIIni := SSOK_IniFile
    SSOK_QF_Ini := SSOK_IniFile
    if (SSOK_QU_Ini = "")
        SSOK_QU_Ini := SSOK_IniFile
    if (SSOK_AI_Ini = "")
        SSOK_AI_Ini := SSOK_IniFile

    ; F5 ÀúÀå¸¸ ÇÑ °æ¿ì¿¡µµ ±âÁ¸ QIQuickInput °ªÀ» ÀÒÁö ¾Êµµ·Ï ¸ÕÀú ±âÁ¸ ÆÄÀÏ¿¡¼­ ÀÐ¾î¿É´Ï´Ù.
    if FileExist(QIIni)
    {
        FileRead, ExistingIniText, %QIIni%
        if !ErrorLevel
        {
            Loop, Parse, ExistingIniText, `n, `r
            {
                ExistingLine := StrReplace(A_LoopField, Chr(0xFEFF), "")
                if (SubStr(ExistingLine, 1, 6) = "Text1=" && QIText1 = "")
                    QIText1 := QI_DecodeText(SubStr(ExistingLine, 7))
                else if (SubStr(ExistingLine, 1, 6) = "Text2=" && QIText2 = "")
                    QIText2 := QI_DecodeText(SubStr(ExistingLine, 7))
                else if (SubStr(ExistingLine, 1, 6) = "Text3=" && QIText3 = "")
                    QIText3 := QI_DecodeText(SubStr(ExistingLine, 7))
                else if (SubStr(ExistingLine, 1, 6) = "Text4=" && QIText4 = "")
                    QIText4 := QI_DecodeText(SubStr(ExistingLine, 7))
                else if (SubStr(ExistingLine, 1, 6) = "Text5=" && QIText5 = "")
                    QIText5 := QI_DecodeText(SubStr(ExistingLine, 7))
                else if (SubStr(ExistingLine, 1, 6) = "Text6=" && QIText6 = "")
                    QIText6 := QI_DecodeText(SubStr(ExistingLine, 7))
                else if (SubStr(ExistingLine, 1, 6) = "Text7=" && QIText7 = "")
                    QIText7 := QI_DecodeText(SubStr(ExistingLine, 7))
                else if (SubStr(ExistingLine, 1, 7) = "Text10=" && QIText10 = "")
                    QIText10 := QI_DecodeText(SubStr(ExistingLine, 8))
                else if (SubStr(ExistingLine, 1, 7) = "Text11=" && QIText11 = "")
                    QIText11 := QI_DecodeText(SubStr(ExistingLine, 8))
                else if (SubStr(ExistingLine, 1, 7) = "Text12=" && QIText12 = "")
                    QIText12 := QI_DecodeText(SubStr(ExistingLine, 8))
                else if (SubStr(ExistingLine, 1, 7) = "Keyword")
                {
                    _eqPos := InStr(ExistingLine, "=")
                    if (_eqPos > 8)
                    {
                        _qfIdx := SubStr(ExistingLine, 8, _eqPos - 8) + 0
                        if (_qfIdx >= 1 && _qfIdx <= 12 && SSOK_QF_Text%_qfIdx% = "")
                            SSOK_QF_Text%_qfIdx% := SubStr(ExistingLine, _eqPos + 1)
                    }
                }
            }
        }
    }

    ; QI °ªÀÌ ±×·¡µµ ºñ¾î ÀÖÀ¸¸é ±âº»°ªÀ» Ã¤¿ó´Ï´Ù.
    if (QIDefault1 = "")
    {
        QIDefault1 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault2 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault3 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault4 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault5 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault6 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault7 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault10 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault11 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
        QIDefault12 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    }
    if (QIDefault7 = "")
        QIDefault7 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    if (QIDefault10 = "")
        QIDefault10 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    if (QIDefault11 = "")
        QIDefault11 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    if (QIDefault12 = "")
        QIDefault12 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    if (QIText1 = "")
        QIText1 := QIDefault1
    if (QIText2 = "")
        QIText2 := QIDefault2
    if (QIText3 = "")
        QIText3 := QIDefault3
    if (QIText4 = "")
        QIText4 := QIDefault4
    if (QIText5 = "")
        QIText5 := QIDefault5
    if (QIText6 = "")
        QIText6 := QIDefault6
    if (QIText7 = "")
        QIText7 := QIDefault7
    if (QIText10 = "")
        QIText10 := QIDefault10
    if (QIText11 = "")
        QIText11 := QIDefault11
    if (QIText12 = "")
        QIText12 := QIDefault12

    ; F5 °ªÀÌ ºñ¾î ÀÖ°Å³ª ±úÁø Á¦¾î¹®ÀÚ¸¸ ÀÖÀ¸¸é ±âº»°ªÀ» Ã¤¿ó´Ï´Ù.
    if (SSOK_QF_Text1 = "")
        SSOK_QF_Text1 := "ºñ»ó¿¬¶ô"
    if (SSOK_QF_Text2 = "")
        SSOK_QF_Text2 := "ÀÏ¶÷"
    if (SSOK_QF_Text3 = "")
        SSOK_QF_Text3 := "¾÷¹«ºÐÀå"
    if (SSOK_QF_Text4 = "")
        SSOK_QF_Text4 := "ÇÐ±ÞÆí¼º"
    if (SSOK_QF_Text5 = "")
        SSOK_QF_Text5 := "½Ã°£Ç¥"
    if (SSOK_QF_Text6 = "")
        SSOK_QF_Text6 := "±Þ½Ä"
    if (SSOK_QF_Text7 = "")
        SSOK_QF_Text7 := "¿¹»ê"
    if (SSOK_QF_Text8 = "")
        SSOK_QF_Text8 := "°¢¸ñ³»¿ª¼­"
    if (SSOK_QF_Text9 = "")
        SSOK_QF_Text9 := "È¸°èÁöÄ§"
    if (SSOK_QF_Text10 = "")
        SSOK_QF_Text10 := "°è¾à"
    if (SSOK_QF_Text11 = "")
        SSOK_QF_Text11 := "Ç°ÀÇ"
    if (SSOK_QF_Text12 = "")
        SSOK_QF_Text12 := "°èÈ¹"

    ; URL ¸Þ´º ±âº»°ªÀº SSOK_QU_GetDefault() ÇÑ °÷¿¡¼­¸¸ °ü¸®ÇÕ´Ï´Ù.
    Loop, 12
    {
        _urlIdx := A_Index
        SSOK_QU_GetDefault(_urlIdx, _defaultUrlName, _defaultUrlValue)
        if (SSOK_QU_Name%_urlIdx% = "")
            SSOK_QU_Name%_urlIdx% := _defaultUrlName
        if (!SSOK_QU_SaveActive && SSOK_QU_Url%_urlIdx% = "")
            SSOK_QU_Url%_urlIdx% := _defaultUrlValue
    }

    if (!SSOK_QU_SaveActive && FileExist(SSOK_QU_Ini))
    {
        Loop, 12
        {
            _urlIdx := A_Index
            IniRead, _savedUrlName, %SSOK_QU_Ini%, F6QuickUrls, Name%_urlIdx%, __SSOK_MISSING__
            IniRead, _savedUrlValue, %SSOK_QU_Ini%, F6QuickUrls, Url%_urlIdx%, __SSOK_MISSING__
            if (_savedUrlName != "__SSOK_MISSING__" && Trim(_savedUrlName) != "" && !SSOK_QU_IsOldPlaceholderName(_urlIdx, _savedUrlName))
                SSOK_QU_Name%_urlIdx% := _savedUrlName
            if (_savedUrlValue != "__SSOK_MISSING__" && !(SSOK_QU_IsOldPlaceholderName(_urlIdx, _savedUrlName) && Trim(_savedUrlValue) = ""))
                SSOK_QU_Url%_urlIdx% := _savedUrlValue
        }
    }

    ; Win+F3 AI ¸Þ´º ÇÏ´Ü 5°³ »çÀÌÆ® ±âº»°ª/ÀúÀå°ª º¸Á¸
    Loop, 5
    {
        _aiSiteIdx := A_Index
        SSOK_AI_GetSiteDefault(_aiSiteIdx, _aiDefaultName, _aiDefaultUrl)
        if (SSOK_AI_SiteName%_aiSiteIdx% = "")
            SSOK_AI_SiteName%_aiSiteIdx% := _aiDefaultName
        if (!SSOK_AI_SaveActive && SSOK_AI_SiteUrl%_aiSiteIdx% = "")
            SSOK_AI_SiteUrl%_aiSiteIdx% := _aiDefaultUrl
    }

    if (!SSOK_AI_SaveActive && FileExist(SSOK_AI_Ini))
    {
        Loop, 5
        {
            _aiSiteIdx := A_Index
            IniRead, _savedAISiteName, %SSOK_AI_Ini%, F3AISites, Name%_aiSiteIdx%, __SSOK_MISSING__
            IniRead, _savedAISiteUrl, %SSOK_AI_Ini%, F3AISites, Url%_aiSiteIdx%, __SSOK_MISSING__
            if (_savedAISiteName != "__SSOK_MISSING__" && Trim(_savedAISiteName) != "")
                SSOK_AI_SiteName%_aiSiteIdx% := _savedAISiteName
            if (_savedAISiteUrl != "__SSOK_MISSING__")
                SSOK_AI_SiteUrl%_aiSiteIdx% := _savedAISiteUrl
        }
    }

    ; ±³À°Ã» ¹Ù·Î°¡±â Áö¿ª ¼±ÅÃ°ª º¸Á¸
    ; ´Ù¸¥ ±â´ÉÀÌ ÅëÇÕ ÀúÀåÀ» È£ÃâÇØµµ ±âÁ¸ ¼±ÅÃ°ªÀÌ »ç¶óÁöÁö ¾Êµµ·Ï ¸ÕÀú ÀÐ½À´Ï´Ù.
    if FileExist(QIIni)
    {
        if (Trim(SSOK_QU_EduRegionPortal) = "")
        {
            IniRead, _eduPortalRead, %QIIni%, EduQuickLinks, WorkPortal, __SSOK_MISSING__
            if (_eduPortalRead != "__SSOK_MISSING__")
                SSOK_QU_EduRegionPortal := _eduPortalRead
        }
        if (Trim(SSOK_QU_EduRegionKEdufine) = "")
        {
            IniRead, _eduKEdufineRead, %QIIni%, EduQuickLinks, KEdufine, __SSOK_MISSING__
            if (_eduKEdufineRead != "__SSOK_MISSING__")
                SSOK_QU_EduRegionKEdufine := _eduKEdufineRead
        }
        if (Trim(SSOK_QU_EduRegionNeis) = "")
        {
            IniRead, _eduNeisRead, %QIIni%, EduQuickLinks, Neis, __SSOK_MISSING__
            if (_eduNeisRead != "__SSOK_MISSING__")
                SSOK_QU_EduRegionNeis := _eduNeisRead
        }
        if (Trim(SSOK_QU_EduRegionSupport) = "")
        {
            IniRead, _eduSupportRead, %QIIni%, EduQuickLinks, Support, __SSOK_MISSING__
            if (_eduSupportRead != "__SSOK_MISSING__")
                SSOK_QU_EduRegionSupport := _eduSupportRead
        }
        if (Trim(SSOK_QU_EduRegionEVPN) = "")
        {
            IniRead, _eduEVPNRead, %QIIni%, EduQuickLinks, EVPN, __SSOK_MISSING__
            if (_eduEVPNRead != "__SSOK_MISSING__")
                SSOK_QU_EduRegionEVPN := _eduEVPNRead
        }
    }
    if (Trim(SSOK_QU_EduRegionPortal) = "")
        SSOK_QU_EduRegionPortal := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionKEdufine) = "")
        SSOK_QU_EduRegionKEdufine := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionNeis) = "")
        SSOK_QU_EduRegionNeis := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionSupport) = "")
        SSOK_QU_EduRegionSupport := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionEVPN) = "")
        SSOK_QU_EduRegionEVPN := "¼¼Á¾"

    SSOK_QF_LoadFolderSettings()

    SaveText := ""
    SaveText .= "; SSOK ¼³Á¤ ÆÄÀÏÀÔ´Ï´Ù. Á÷Á¢ ÆíÁýÇÒ ¶§´Â UTF-16 LE ¶Ç´Â UTF-8(BOM Æ÷ÇÔ)À¸·Î ÀúÀåÇÏ¼¼¿ä.`r`n"
    SaveText .= "; ¸Þ¸ðÀå¿¡¼­ ÀúÀåÇÒ ¶§´Â '´Ù¸¥ ÀÌ¸§À¸·Î ÀúÀå' ÈÄ ÀÎÄÚµùÀ» UTF-8(BOM Æ÷ÇÔ) ¶Ç´Â UTF-16 LE·Î ¼±ÅÃÇÏ¼¼¿ä.`r`n`r`n"
    SaveText .= "[QIQuickInput]`r`n"
    SaveText .= "Text1=" . QI_EncodeText(QIText1) . "`r`n"
    SaveText .= "Text2=" . QI_EncodeText(QIText2) . "`r`n"
    SaveText .= "Text3=" . QI_EncodeText(QIText3) . "`r`n"
    SaveText .= "Text4=" . QI_EncodeText(QIText4) . "`r`n"
    SaveText .= "Text5=" . QI_EncodeText(QIText5) . "`r`n"
    SaveText .= "Text6=" . QI_EncodeText(QIText6) . "`r`n"
    SaveText .= "Text7=" . QI_EncodeText(QIText7) . "`r`n"
    SaveText .= "Text10=" . QI_EncodeText(QIText10) . "`r`n"
    SaveText .= "Text11=" . QI_EncodeText(QIText11) . "`r`n"
    SaveText .= "Text12=" . QI_EncodeText(QIText12) . "`r`n"

    ; Win+F1 ÀÌ¹ÌÁö ¼³Á¤µµ ÅëÇÕ ÀúÀå ½Ã ¹Ýµå½Ã º¸Á¸ÇÕ´Ï´Ù.
    ; ´Ù¸¥ ±â´ÉÀÌ SSOK_SaveUnifiedIni()¸¦ È£ÃâÇØµµ ÀÌ¹ÌÁö °æ·Î/URLÀÌ »ç¶óÁöÁö ¾Êµµ·Ï
    ; ±âÁ¸ INI °ªÀ» ¸ÕÀú ÀÐ°í, ÇöÀç ¸Þ¸ð¸® °ªÀÌ ÀÖÀ¸¸é ±×°ÍÀ» ¿ì¼± ÀúÀåÇÕ´Ï´Ù.
    _qiImage12Save := ""
    _qiImage13Save := ""
    _qiImage14Save := ""
    _qiImage15Save := ""
    if FileExist(QIIni)
    {
        IniRead, _qiImage12Read, %QIIni%, QuickImages, Image12, __SSOK_MISSING__
        IniRead, _qiImage13Read, %QIIni%, QuickImages, Image13, __SSOK_MISSING__
        IniRead, _qiImage14Read, %QIIni%, QuickImages, Image14, __SSOK_MISSING__
        IniRead, _qiImage15Read, %QIIni%, QuickImages, Image15, __SSOK_MISSING__
        if (_qiImage12Read != "__SSOK_MISSING__")
            _qiImage12Save := _qiImage12Read
        if (_qiImage13Read != "__SSOK_MISSING__")
            _qiImage13Save := _qiImage13Read
        if (_qiImage14Read != "__SSOK_MISSING__")
            _qiImage14Save := _qiImage14Read
        if (_qiImage15Read != "__SSOK_MISSING__")
            _qiImage15Save := _qiImage15Read
    }
    if (QIImage12 != "")
        _qiImage12Save := QIImage12
    if (QIImage13 != "")
        _qiImage13Save := QIImage13
    if (QIImage14 != "")
        _qiImage14Save := QIImage14
    if (QIImage15 != "")
        _qiImage15Save := QIImage15

    SaveText .= "[QuickImages]`r`n"
    SaveText .= "Image12=" . _qiImage12Save . "`r`n"
    SaveText .= "Image13=" . _qiImage13Save . "`r`n"
    SaveText .= "Image14=" . _qiImage14Save . "`r`n"
    SaveText .= "Image15=" . _qiImage15Save . "`r`n"
    SaveText .= "`r`n"
    SaveText .= "[F5QuickFiles]`r`n"
    Loop, 12
    {
        _i := A_Index
        SaveText .= "Keyword" . _i . "=" . SSOK_QF_Text%_i% . "`r`n"
    }

    SaveText .= "`r`n"
    SaveText .= "[F5QuickFileFolders]`r`n"
    SaveText .= "Desktop=" . SSOK_QF_SearchDesktop . "`r`n"
    SaveText .= "Downloads=" . SSOK_QF_SearchDownloads . "`r`n"
    SaveText .= "Documents=" . SSOK_QF_SearchDocuments . "`r`n"
    SaveText .= "ExtraFolders=" . SSOK_QF_SearchExtraFolders . "`r`n"

    SaveText .= "`r`n"
    SaveText .= "[F5QuickFileExtensions]`r`n"
    SaveText .= "Hwp=" . SSOK_QF_ExtHwp . "`r`n"
    SaveText .= "Xls=" . SSOK_QF_ExtXls . "`r`n"
    SaveText .= "Doc=" . SSOK_QF_ExtDoc . "`r`n"
    SaveText .= "Ppt=" . SSOK_QF_ExtPpt . "`r`n"
    SaveText .= "Txt=" . SSOK_QF_ExtTxt . "`r`n"
    SaveText .= "Pdf=" . SSOK_QF_ExtPdf . "`r`n"

    ; F6 »çÀÌÆ®µµ ÇÔ²² ÀúÀå (ÇÑ±Û ±úÁü ¹æÁö ÅëÇÕ)
    SaveText .= "`r`n"
    SaveText .= "[F6QuickUrls]`r`n"
    Loop, 12
    {
        _i := A_Index
        _n := SSOK_QU_Name%_i%
        _u := SSOK_QU_Url%_i%
        if (_n = "")
            _n := "»çÀÌÆ®" . _i
        SaveText .= "Name" . _i . "=" . _n . "`r`n"
        SaveText .= "Url" . _i . "=" . _u . "`r`n"
    }

    ; ±³À°Ã» ¾÷¹« ½Ã½ºÅÛ ¹Ù·Î°¡±â¿¡¼­ ¼±ÅÃÇÑ Áö¿ª ÀúÀå
    SaveText .= "`r`n"
    SaveText .= "[EduQuickLinks]`r`n"
    SaveText .= "WorkPortal=" . SSOK_QU_EduRegionPortal . "`r`n"
    SaveText .= "KEdufine=" . SSOK_QU_EduRegionKEdufine . "`r`n"
    SaveText .= "Neis=" . SSOK_QU_EduRegionNeis . "`r`n"
    SaveText .= "Support=" . SSOK_QU_EduRegionSupport . "`r`n"
    SaveText .= "EVPN=" . SSOK_QU_EduRegionEVPN . "`r`n"

    ; Win+F3 AI ¸Þ´º ÇÏ´Ü 5°³ »çÀÌÆ®µµ ÇÔ²² ÀúÀå
    SaveText .= "`r`n"
    SaveText .= "[F3AISites]`r`n"
    Loop, 5
    {
        _i := A_Index
        _n := SSOK_AI_SiteName%_i%
        _u := SSOK_AI_SiteUrl%_i%
        if (_n = "")
        {
            SSOK_AI_GetSiteDefault(_i, _defaultAISiteName, _defaultAISiteUrl)
            _n := _defaultAISiteName
        }
        SaveText .= "Name" . _i . "=" . _n . "`r`n"
        SaveText .= "Url" . _i . "=" . _u . "`r`n"
    }

    ; ÁÖ¿äÇÒÀÏ ¸Þ¸ð º¸Á¸
    ; - Win+F1 ºü¸¥ÀÔ·Â / Win+F5 ÆÄÀÏ / Win+F6 URL ÀúÀå ½Ã ssok.ini ÀüÃ¼¸¦ ´Ù½Ã ¾²±â ¶§¹®¿¡
    ;   ±âÁ¸ [MajorTodos] ¼½¼ÇÀ» ÇÔ²² ´Ù½Ã ½á ÁÖ¾î¾ß ¸Þ¸ð/¾Ë¶÷ÀÌ »ç¶óÁöÁö ¾Ê½À´Ï´Ù.
    _majorTodoSave := ""
    _orgNameSave := "µµ´ãÁßÇÐ±³"
    _majorAlarmSave := ""
    _majorAlarmEnabledSave := 1
    _majorAlarm2Save := ""
    _majorAlarm2EnabledSave := 1
    if FileExist(QIIni)
    {
        IniRead, _majorTodoRead, %QIIni%, MajorTodos, Memo, __SSOK_EMPTY__
        if (_majorTodoRead != "__SSOK_EMPTY__")
            _majorTodoSave := _majorTodoRead
        IniRead, _orgNameRead, %QIIni%, MajorTodos, OrgName, µµ´ãÁßÇÐ±³
        _orgNameRead := Trim(_orgNameRead)
        if (_orgNameRead != "")
            _orgNameSave := _orgNameRead
        IniRead, _majorAlarmRead, %QIIni%, MajorTodos, Alarm, __SSOK_EMPTY__
        if (_majorAlarmRead != "__SSOK_EMPTY__")
            _majorAlarmSave := _majorAlarmRead
        IniRead, _majorAlarmEnabledRead, %QIIni%, MajorTodos, AlarmEnabled, 1
        _majorAlarmEnabledSave := _majorAlarmEnabledRead
        IniRead, _majorAlarm2Read, %QIIni%, MajorTodos, Alarm2, __SSOK_EMPTY__
        if (_majorAlarm2Read != "__SSOK_EMPTY__")
            _majorAlarm2Save := _majorAlarm2Read
        IniRead, _majorAlarm2EnabledRead, %QIIni%, MajorTodos, Alarm2Enabled, 1
        _majorAlarm2EnabledSave := _majorAlarm2EnabledRead
    }
    ; »çÀÌµå¹Ù ¸Þ¸ð/¾Ë¶÷Ä­ÀÌ ÇöÀç ¿­·Á ÀÖÀ¸¸é È­¸éÀÇ ÃÖ½Å °ªµµ ¹Ý¿µÇÕ´Ï´Ù.
    GuiControlGet, _orgNameGui, SSOKSide:, SSOK_OrgNameEdit
    if (!ErrorLevel)
    {
        _orgNameSave := Trim(_orgNameGui)
        if (_orgNameSave = "")
            _orgNameSave := "µµ´ãÁßÇÐ±³"
    }
    GuiControlGet, _majorTodoGui, SSOKSide:, SSOK_MajorTodoEdit
    if (!ErrorLevel)
    {
        _majorTodoSave := Trim(_majorTodoGui, " `t`r`n")
        if (SSOK_IsMajorTodoSampleOrGuideText(_majorTodoSave))
            _majorTodoSave := ""
        _majorTodoSave := StrReplace(_majorTodoSave, "`r`n", "\n")
        _majorTodoSave := StrReplace(_majorTodoSave, "`n", "\n")
    }
    GuiControlGet, _majorAlarmGui, SSOKSide:, SSOK_AlarmTimeEdit
    if (!ErrorLevel)
    {
        _majorAlarmSave := SSOK_NormalizeAlarmTime(_majorAlarmGui, "1150")
        _majorAlarmEnabledSave := SSOK_AlarmEnabled
        GuiControlGet, _majorAlarm2Gui, SSOKSide:, SSOK_Alarm2TimeEdit
        if (!ErrorLevel)
        {
            _majorAlarm2Save := SSOK_NormalizeAlarmTime(_majorAlarm2Gui, "1630")
            _majorAlarm2EnabledSave := SSOK_Alarm2Enabled
        }
    }
    SaveText .= "`r`n"
    SaveText .= "[MajorTodos]`r`n"
    SaveText .= "Memo=" . _majorTodoSave . "`r`n"
    SaveText .= "OrgName=" . _orgNameSave . "`r`n"
    SaveText .= "Alarm=" . _majorAlarmSave . "`r`n"
    SaveText .= "AlarmEnabled=" . _majorAlarmEnabledSave . "`r`n"
    SaveText .= "Alarm2=" . _majorAlarm2Save . "`r`n"
    SaveText .= "Alarm2Enabled=" . _majorAlarm2EnabledSave . "`r`n"

    ; ¸ÞÀÎ ±â°ü¸í°ú ¿¬°áµÈ ³ªÀÌ½º ÇÐ±³ °íÀ¯ÄÚµå´Â ÅëÇÕ INI ÀçÀúÀå ¶§µµ º¸Á¸ÇÕ´Ï´Ù.
    _mySchoolSection := SSOK_ExtractIniSection(ExistingIniText, "MySchool")
    if (_mySchoolSection != "")
        SaveText .= "`r`n" . _mySchoolSection . "`r`n"

    _powerOnSave := "0830"
    _powerOffSave := "1630"
    _powerEnabledSave := 0
    if FileExist(QIIni)
    {
        IniRead, _powerOnRead, %QIIni%, PowerSchedule, OnTime, 0830
        IniRead, _powerOffRead, %QIIni%, PowerSchedule, OffTime, 1630
        IniRead, _powerEnabledRead, %QIIni%, PowerSchedule, Enabled, 0
        _powerOnSave := SSOK_NormalizeAlarmTime(_powerOnRead, "0830")
        _powerOffSave := SSOK_NormalizeAlarmTime(_powerOffRead, "1630")
        _powerEnabledSave := _powerEnabledRead
    }
    SaveText .= "`r`n"
    SaveText .= "[PowerSchedule]`r`n"
    SaveText .= "OnTime=" . _powerOnSave . "`r`n"
    SaveText .= "OffTime=" . _powerOffSave . "`r`n"
    SaveText .= "Enabled=" . _powerEnabledSave . "`r`n"
    if (SSOK_SidebarHwnd != "")
    {
        WinGetPos, _sidebarNowX, _sidebarNowY,,, ahk_id %SSOK_SidebarHwnd%
        if (_sidebarNowX != "" && _sidebarNowY != "")
        {
            SSOK_SidebarSavedX := _sidebarNowX
            SSOK_SidebarSavedY := _sidebarNowY
            SSOK_SidebarCustomPos := 1
        }
    }
    SaveText .= "`r`n"
    SaveText .= "[SidebarPosition]`r`n"
    SaveText .= "CustomPos=" . SSOK_SidebarCustomPos . "`r`n"
    SaveText .= "X=" . SSOK_SidebarSavedX . "`r`n"
    SaveText .= "Y=" . SSOK_SidebarSavedY . "`r`n"
    if (SSOK_SidebarSavedW = "" || SSOK_SidebarSavedW < SSOK_SidebarMinW)
        SSOK_SidebarSavedW := SSOK_SidebarMinW
    SaveText .= "Width=" . SSOK_SidebarSavedW . "`r`n"
    if (SSOK_AdvancedHwnd != "")
    {
        WinGetPos, _advancedNowX, _advancedNowY,,, ahk_id %SSOK_AdvancedHwnd%
        if (_advancedNowX != "" && _advancedNowY != "")
        {
            SSOK_AdvancedSavedX := _advancedNowX
            SSOK_AdvancedSavedY := _advancedNowY
            SSOK_AdvancedCustomPos := 1
        }
    }
    SaveText .= "`r`n"
    SaveText .= "[HiddenMenuPosition]`r`n"
    SaveText .= "CustomPos=" . SSOK_AdvancedCustomPos . "`r`n"
    SaveText .= "X=" . SSOK_AdvancedSavedX . "`r`n"
    SaveText .= "Y=" . SSOK_AdvancedSavedY . "`r`n"

    _autoClickSecSave := "0"
    _autoClickModeSave := "1"
    _autoClickTimeModeSave := "1"
    _autoClickIXSave := ""
    _autoClickIYSave := ""
    Loop, 3
    {
        _i := A_Index
        _autoClickUse%_i%Save := "0"
        _autoClickX%_i%Save := ""
        _autoClickY%_i%Save := ""
        _autoClickH%_i%Save := "00"
        _autoClickM%_i%Save := "00"
        _autoClickS%_i%Save := "00"
    }
    if FileExist(QIIni)
    {
        IniRead, _autoClickSecRead, %QIIni%, AutoClick, Sec, 0
        IniRead, _autoClickModeRead, %QIIni%, AutoClick, Mode, 1
        IniRead, _autoClickTimeModeRead, %QIIni%, AutoClick, TimeMode, 1
        IniRead, _autoClickIXRead, %QIIni%, AutoClick, IX, __SSOK_EMPTY__
        IniRead, _autoClickIYRead, %QIIni%, AutoClick, IY, __SSOK_EMPTY__
        _autoClickSecSave := _autoClickSecRead
        _autoClickModeSave := _autoClickModeRead
        _autoClickTimeModeSave := _autoClickTimeModeRead
        _autoClickIXSave := (_autoClickIXRead = "__SSOK_EMPTY__" ? "" : _autoClickIXRead)
        _autoClickIYSave := (_autoClickIYRead = "__SSOK_EMPTY__" ? "" : _autoClickIYRead)
        Loop, 3
        {
            _i := A_Index
            IniRead, _autoClickUseRead, %QIIni%, AutoClick, Use%_i%, 0
            IniRead, _autoClickXRead, %QIIni%, AutoClick, X%_i%, __SSOK_EMPTY__
            IniRead, _autoClickYRead, %QIIni%, AutoClick, Y%_i%, __SSOK_EMPTY__
            IniRead, _autoClickHRead, %QIIni%, AutoClick, H%_i%, 00
            IniRead, _autoClickMRead, %QIIni%, AutoClick, M%_i%, 00
            IniRead, _autoClickSRead, %QIIni%, AutoClick, S%_i%, 00
            _autoClickUse%_i%Save := (_autoClickUseRead = 1 ? "1" : "0")
            _autoClickX%_i%Save := (_autoClickXRead = "__SSOK_EMPTY__" ? "" : _autoClickXRead)
            _autoClickY%_i%Save := (_autoClickYRead = "__SSOK_EMPTY__" ? "" : _autoClickYRead)
            _autoClickH%_i%Save := SSOK_AutoClickPad2(_autoClickHRead)
            _autoClickM%_i%Save := SSOK_AutoClickPad2(_autoClickMRead)
            _autoClickS%_i%Save := SSOK_AutoClickPad2(_autoClickSRead)
        }
    }
    if (SSOK_AutoClickSec != "")
        _autoClickSecSave := SSOK_AutoClickSec
    if (SSOK_AutoClickMode != "")
        _autoClickModeSave := SSOK_AutoClickMode
    if (SSOK_AutoClickTimeMode != "")
        _autoClickTimeModeSave := SSOK_AutoClickTimeMode
    if (SSOK_AutoClickIX != "")
        _autoClickIXSave := SSOK_AutoClickIX
    if (SSOK_AutoClickIY != "")
        _autoClickIYSave := SSOK_AutoClickIY
    Loop, 3
    {
        _i := A_Index
        if (SSOK_AutoClickUse%_i% != "")
            _autoClickUse%_i%Save := SSOK_AutoClickUse%_i%
        if (SSOK_AutoClickX%_i% != "")
            _autoClickX%_i%Save := SSOK_AutoClickX%_i%
        if (SSOK_AutoClickY%_i% != "")
            _autoClickY%_i%Save := SSOK_AutoClickY%_i%
        if (SSOK_AutoClickH%_i% != "")
            _autoClickH%_i%Save := SSOK_AutoClickPad2(SSOK_AutoClickH%_i%)
        if (SSOK_AutoClickM%_i% != "")
            _autoClickM%_i%Save := SSOK_AutoClickPad2(SSOK_AutoClickM%_i%)
        if (SSOK_AutoClickS%_i% != "")
            _autoClickS%_i%Save := SSOK_AutoClickPad2(SSOK_AutoClickS%_i%)
    }
    SaveText .= "`r`n"
    SaveText .= "[AutoClick]`r`n"
    SaveText .= "Sec=" . _autoClickSecSave . "`r`n"
    SaveText .= "Mode=" . _autoClickModeSave . "`r`n"
    SaveText .= "TimeMode=" . _autoClickTimeModeSave . "`r`n"
    SaveText .= "IX=" . _autoClickIXSave . "`r`n"
    SaveText .= "IY=" . _autoClickIYSave . "`r`n"
    SaveText .= "CoordOneVer=2`r`n"
    Loop, 3
    {
        _i := A_Index
        SaveText .= "Use" . _i . "=" . _autoClickUse%_i%Save . "`r`n"
        SaveText .= "X" . _i . "=" . _autoClickX%_i%Save . "`r`n"
        SaveText .= "Y" . _i . "=" . _autoClickY%_i%Save . "`r`n"
        SaveText .= "H" . _i . "=" . _autoClickH%_i%Save . "`r`n"
        SaveText .= "M" . _i . "=" . _autoClickM%_i%Save . "`r`n"
        SaveText .= "S" . _i . "=" . _autoClickS%_i%Save . "`r`n"
    }
    _accKeywordLines := SSOK_ACC_GetKeywordSectionForSave()
    SaveText .= "`r`n"
    SaveText .= "[AccountingKeywords]`r`n"
    SaveText .= _accKeywordLines

    _personalHotstringsSection := SSOK_ExtractIniSection(ExistingIniText, "PersonalHotstrings")
    if (_personalHotstringsSection != "")
        SaveText .= "`r`n" . _personalHotstringsSection
    else
    {
        SaveText .= "`r`n[PersonalHotstrings]`r`n"
        SaveText .= "; ¿¹: ::addr::ÇÐ±³ ÁÖ¼Ò`r`n"
        SaveText .= "; ÇÑ±ÛÀÌ ±úÁöÁö ¾Êµµ·Ï ÀÌ ÆÄÀÏÀº UTF-16 LE ¶Ç´Â UTF-8(BOM Æ÷ÇÔ)À¸·Î ÀúÀåÇÏ¼¼¿ä.`r`n"
    }

    TempFile := SSOK_QF_Ini . ".tmp"
    FileDelete, %TempFile%
    FileAppend, %SaveText%, %TempFile%, UTF-16
    if ErrorLevel
    {
        MsgBox, 48, ½î¿Á ÀúÀå ¿À·ù, ÀÓ½Ã ÀúÀåÆÄÀÏÀ» ¸¸µé ¼ö ¾ø½À´Ï´Ù.`n`nÀ§Ä¡:`n%TempFile%
        return
    }

    FileDelete, %SSOK_QF_Ini%
    FileMove, %TempFile%, %SSOK_QF_Ini%, 1
    if ErrorLevel
    {
        MsgBox, 48, ½î¿Á ÀúÀå ¿À·ù, ssok.ini ÆÄÀÏ·Î ÀúÀåÇÒ ¼ö ¾ø½À´Ï´Ù.`n`nÀ§Ä¡:`n%SSOK_QF_Ini%
        return
    }
}

SSOK_ExtractIniSection(iniText, sectionName)
{
    if (iniText = "" || sectionName = "")
        return ""
    result := ""
    inSection := false
    Loop, Parse, iniText, `n, `r
    {
        line := A_LoopField
        cleanLine := StrReplace(line, Chr(0xFEFF), "")
        if RegExMatch(cleanLine, "^\s*\[([^\]]+)\]\s*$", m)
        {
            if (inSection)
                break
            inSection := (m1 = sectionName)
        }
        if (inSection)
            result .= line . "`r`n"
    }
    return RTrim(result, "`r`n")
}

SSOK_QF_ShowSavedNotice(index)
{
    MsgBox, 64, SSOK ¾È³», %index%¹ø Å°¿öµå¸¦ ÀúÀåÇß½À´Ï´Ù.`n`nÀúÀå À§Ä¡: ssok.ini
}

SSOK_QF_Save1:
    SSOK_QF_SaveOneFromGui(1)
    SSOK_QF_ShowSavedNotice(1)
return
SSOK_QF_Save2:
    SSOK_QF_SaveOneFromGui(2)
    SSOK_QF_ShowSavedNotice(2)
return
SSOK_QF_Save3:
    SSOK_QF_SaveOneFromGui(3)
    SSOK_QF_ShowSavedNotice(3)
return
SSOK_QF_Save4:
    SSOK_QF_SaveOneFromGui(4)
    SSOK_QF_ShowSavedNotice(4)
return
SSOK_QF_Save5:
    SSOK_QF_SaveOneFromGui(5)
    SSOK_QF_ShowSavedNotice(5)
return
SSOK_QF_Save6:
    SSOK_QF_SaveOneFromGui(6)
    SSOK_QF_ShowSavedNotice(6)
return
SSOK_QF_Save7:
    SSOK_QF_SaveOneFromGui(7)
    SSOK_QF_ShowSavedNotice(7)
return
SSOK_QF_Save8:
    SSOK_QF_SaveOneFromGui(8)
    SSOK_QF_ShowSavedNotice(8)
return
SSOK_QF_Save9:
    SSOK_QF_SaveOneFromGui(9)
    SSOK_QF_ShowSavedNotice(9)
return
SSOK_QF_Save10:
    SSOK_QF_SaveOneFromGui(10)
    SSOK_QF_ShowSavedNotice(10)
return
SSOK_QF_Save11:
    SSOK_QF_SaveOneFromGui(11)
    SSOK_QF_ShowSavedNotice(11)
return
SSOK_QF_Save12:
    SSOK_QF_SaveOneFromGui(12)
    SSOK_QF_ShowSavedNotice(12)
return

SSOK_QF_GetEditKeyword(index)
{
    global
    Gui, SSOKQuickFile:Submit, NoHide
    return SSOK_QF_Edit%index%
}

SSOK_QF_OpenOnlyIndex(index)
{
    keyword := SSOK_QF_GetEditKeyword(index)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(keyword)
}

SSOK_QF_OpenFolderForKeyword(keyword)
{
    keyword := Trim(keyword)
    if (keyword = "")
    {
        SSOK_ShowCopyFileNotice("")
        return false
    }

    _everythingExe := SSOK_QF_FindEverythingExe()
    if (_everythingExe != "")
    {
        ; Æú´õ ¹öÆ°Àº °Ë»öÃ¢ Ç¥ÃâÀÌ ¾Æ´Ï¶ó ÃÖ½Å¼ø Ã¹ °á°ú¿¡ EverythingÀÇ Open Path ¸í·ÉÀ» ¹Ù·Î º¸³À´Ï´Ù.
        if (SSOK_QF_OpenNewestMatchingFolderWithEverything(keyword, _everythingExe))
        {
            Gui, SSOKQuickFile:Destroy
            WinClose, SSOK ÀÚÁÖ ¿©´Â ÆÄÀÏ ahk_class AutoHotkeyGUI
            return true
        }

        ; EverythingÀÌ ÀÖ´Â °æ¿ì¿¡´Â SSOK Æú´õ Á¦ÇÑ °Ë»öÀ¸·Î ³»·Á°¡Áö ¾Ê½À´Ï´Ù.
        ; ÀÚµ¿ °æ·Î¿­±â°¡ ½ÇÆÐÇÏ¸é ÀüÃ¼ µå¶óÀÌºê Everything °Ë»ö °á°ú¸¸ ¶ç¿ó´Ï´Ù.
        if (SSOK_QF_OpenEverythingSearchWindow(keyword))
        {
            Gui, SSOKQuickFile:Destroy
            WinClose, SSOK ÀÚÁÖ ¿©´Â ÆÄÀÏ ahk_class AutoHotkeyGUI
            return true
        }
        SSOK_ShowCopyFileNotice(keyword)
        return false
    }

    ; Everything.exe°¡ ¾øÀ» ¶§´Â ±âÁ¸ SSOK ÀÚÃ¼ °Ë»ö º¸Á¤¿ë º°ÄªÀ¸·Î Æú´õ¸¦ Ã£½À´Ï´Ù.
    path := SSOK_QF_FindNewestFileInternal(SSOK_BuildKeywordAliases(keyword))
    if (path = "" || !FileExist(path))
    {
        SSOK_ShowCopyFileNotice(keyword)
        return false
    }

    SplitPath, path,, dir
    if (dir = "")
        return false
    Run, explorer.exe /select`,"%path%"
    Gui, SSOKQuickFile:Destroy
    WinClose, SSOK ÀÚÁÖ ¿©´Â ÆÄÀÏ ahk_class AutoHotkeyGUI
    return true
}

SSOK_QF_OpenOnly1:
    SSOK_QF_OpenOnlyIndex(1)
return
SSOK_QF_OpenOnly2:
    SSOK_QF_OpenOnlyIndex(2)
return
SSOK_QF_OpenOnly3:
    SSOK_QF_OpenOnlyIndex(3)
return
SSOK_QF_OpenOnly4:
    SSOK_QF_OpenOnlyIndex(4)
return
SSOK_QF_OpenOnly5:
    SSOK_QF_OpenOnlyIndex(5)
return
SSOK_QF_OpenOnly6:
    SSOK_QF_OpenOnlyIndex(6)
return
SSOK_QF_OpenOnly7:
    SSOK_QF_OpenOnlyIndex(7)
return
SSOK_QF_OpenOnly8:
    SSOK_QF_OpenOnlyIndex(8)
return
SSOK_QF_OpenOnly9:
    SSOK_QF_OpenOnlyIndex(9)
return

SSOK_QF_Folder1:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(1))
return
SSOK_QF_Folder2:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(2))
return
SSOK_QF_Folder3:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(3))
return
SSOK_QF_Folder4:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(4))
return
SSOK_QF_Folder5:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(5))
return
SSOK_QF_Folder6:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(6))
return
SSOK_QF_Folder7:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(7))
return
SSOK_QF_Folder8:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(8))
return
SSOK_QF_Folder9:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(9))
return
SSOK_QF_Folder10:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(10))
return
SSOK_QF_Folder11:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(11))
return
SSOK_QF_Folder12:
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_GetEditKeyword(12))
return
SSOK_QF_Open1:
    SSOK_QF_SaveOneFromGui(1)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text1)
return
SSOK_QF_Open2:
    SSOK_QF_SaveOneFromGui(2)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text2)
return
SSOK_QF_Open3:
    SSOK_QF_SaveOneFromGui(3)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text3)
return
SSOK_QF_Open4:
    SSOK_QF_SaveOneFromGui(4)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text4)
return
SSOK_QF_Open5:
    SSOK_QF_SaveOneFromGui(5)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text5)
return
SSOK_QF_Open6:
    SSOK_QF_SaveOneFromGui(6)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text6)
return
SSOK_QF_Open7:
    SSOK_QF_SaveOneFromGui(7)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text7)
return
SSOK_QF_Open8:
    SSOK_QF_SaveOneFromGui(8)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text8)
return
SSOK_QF_Open9:
    SSOK_QF_SaveOneFromGui(9)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text9)
return
SSOK_QF_Open10:
    SSOK_QF_SaveOneFromGui(10)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text10)
return
SSOK_QF_Open11:
    SSOK_QF_SaveOneFromGui(11)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text11)
return
SSOK_QF_Open12:
    SSOK_QF_SaveOneFromGui(12)
    Gui, SSOKQuickFile:Destroy
    SSOK_OpenFirstMatchingFile(SSOK_QF_Text12)
return

SSOK_QF_CustomOpen:
    Gui, SSOKQuickFile:Submit, NoHide
    if (Trim(SSOK_QF_CustomKeyword) = "")
    {
        SSOK_ShowCopyFileNotice("")
        return
    }
    if (SSOK_ShowMatchingFileChoices(SSOK_QF_CustomKeyword, 12))
        Gui, SSOKQuickFile:Destroy
return

SSOK_QF_CustomFolder:
    Gui, SSOKQuickFile:Submit, NoHide
    SSOK_QF_OpenFolderForKeyword(SSOK_QF_CustomKeyword)
return

SSOK_QF_ShowAppRecentMenu:
    if (SSOK_QF_OpenEverythingRecentDocsWindow())
        return
    SSOK_QF_LoadAppRecentFiles()
    Gui, SSOKAppRecent:Destroy
    Gui, SSOKAppRecent:+AlwaysOnTop +ToolWindow -MinimizeBox
    Gui, SSOKAppRecent:Color, F7FBFF
    Gui, SSOKAppRecent:Margin, 12, 12
    Gui, SSOKAppRecent:Font, s11 bold c005BAC, Malgun Gothic
    Gui, SSOKAppRecent:Add, Text, x12 y10 w710 h24 Center, ÇÑ±Û/¿¢¼¿ ÃÖ±Ù¹®¼­

    _recentAny := 0
    _y := 44
    Loop, 12
    {
        _i := A_Index
        _path := SSOK_QF_AppRecentPath%_i%
        if (_path = "")
            continue
        _label := SSOK_QF_AppRecentLabel%_i%
        _label := StrReplace(_label, "&", "&&")
        Gui, SSOKAppRecent:Font, s8 norm c222222, Malgun Gothic
        Gui, SSOKAppRecent:Add, Button, x18 y%_y% w610 h30 Left gSSOK_QF_AppRecentOpen%_i%, %_label%
        Gui, SSOKAppRecent:Add, Button, x640 y%_y% w72 h30 gSSOK_QF_AppRecentFolder%_i%, Æú´õ
        _recentAny := 1
        _y += 36
    }
    if (!_recentAny)
    {
        Gui, SSOKAppRecent:Font, s9 norm c555555, Malgun Gothic
        Gui, SSOKAppRecent:Add, Text, x18 y52 w690 h24 Center, ÇÑ±Û/¿¢¼¿ ÃÖ±Ù¹®¼­°¡ ¾ø½À´Ï´Ù.
        _y := 88
    }
    _h := _y + 12
    SSOK_GetSidebarAttachedGuiPos(740, _h, SSOK_QF_AppRecentX, SSOK_QF_AppRecentY)
    Gui, SSOKAppRecent:Show, x%SSOK_QF_AppRecentX% y%SSOK_QF_AppRecentY% w740 h%_h%, SSOK ÇÑ±Û/¿¢¼¿ ÃÖ±Ù¹®¼­
return

SSOKAppRecentGuiEscape:
SSOKAppRecentGuiClose:
    Gui, SSOKAppRecent:Destroy
return
SSOK_QF_LoadAppRecentFiles()
    Menu, SSOK_QF_AppRecentMenu, Add, __ÃÊ±âÈ­__, SSOK_QF_AppRecentEmpty
    Menu, SSOK_QF_AppRecentMenu, DeleteAll
    _recentAny := 0
    Loop, 12
    {
        _i := A_Index
        _path := SSOK_QF_AppRecentPath%_i%
        if (_path = "")
            continue
        _label := SSOK_QF_AppRecentLabel%_i%
        _label := StrReplace(_label, "&", "&&")
        _handler := "SSOK_QF_AppRecentOpen" . _i
        Menu, SSOK_QF_AppRecentMenu, Add, %_label%, %_handler%
        _recentAny := 1
    }
    if (!_recentAny)
        Menu, SSOK_QF_AppRecentMenu, Add, ÇÑ±Û/¿¢¼¿ ÃÖ±Ù¹®¼­ ¾øÀ½, SSOK_QF_AppRecentEmpty
    Menu, SSOK_QF_AppRecentMenu, Show
return

SSOK_QF_AppRecentEmpty:
return

SSOK_QF_LoadAppRecentFiles()
{
    global
    Loop, 12
    {
        _i := A_Index
        SSOK_QF_AppRecentPath%_i% := ""
        SSOK_QF_AppRecentLabel%_i% := ""
    }

    _slot := 1
    _seen := "|"
    _hwpCount := 0
    _excelCount := 0
    _hncRecent := A_AppData . "\HNC\User\Common\130\recentInfo.xml"
    if FileExist(_hncRecent)
    {
        FileRead, _hncText, %_hncRecent%
        Loop, Parse, _hncText, `n, `r
        {
            _line := A_LoopField
            if (!InStr(_line, "RecentFileListInfo") || !InStr(_line, "AppName=""Hwp"""))
                continue
            if !RegExMatch(_line, "PathName=""([^""]+)""", _m)
                continue
            _path := SSOK_QF_XmlUnescape(_m1)
            if (!SSOK_QF_IsHwpRecentFile(_path))
                continue
            if (_hwpCount >= 6)
                break
            if (!SSOK_QF_AddAppRecentItem(_slot, _seen, "ÇÑ±Û", _path))
                continue
            _hwpCount++
            if (_slot > 12)
                return
        }
    }

    _officeRecent := A_AppData . "\Microsoft\Office\Recent"
    if InStr(FileExist(_officeRecent), "D")
    {
        _excelEntries := ""
        Loop, Files, %_officeRecent%\*.lnk, F
        {
            _target := ""
            FileGetShortcut, %A_LoopFileFullPath%, _target
            if (SSOK_QF_IsExcelRecentFile(_target))
                _excelEntries .= A_LoopFileTimeModified . "`t" . _target . "`n"
        }
        Loop, Files, %_officeRecent%\*.url, F
        {
            _url := SSOK_QF_ReadInternetShortcutUrl(A_LoopFileFullPath)
            if (SSOK_QF_IsExcelRecentFile(_url))
                _excelEntries .= A_LoopFileTimeModified . "`t" . _url . "`n"
        }
        Sort, _excelEntries, R
        Loop, Parse, _excelEntries, `n, `r
        {
            _line := A_LoopField
            if (_line = "")
                continue
            _tabPos := InStr(_line, "`t")
            if (_tabPos <= 0)
                continue
            _path := SubStr(_line, _tabPos + 1)
            if (_excelCount >= 6)
                break
            if (!SSOK_QF_AddAppRecentItem(_slot, _seen, "¿¢¼¿", _path))
                continue
            _excelCount++
            if (_slot > 12)
                return
        }
    }
}

SSOK_QF_AddAppRecentItem(ByRef slot, ByRef seen, appName, path)
{
    global
    path := Trim(path)
    if (path = "")
        return false
    _cmp := path
    StringLower, _cmp, _cmp
    if InStr(seen, "|" . _cmp . "|")
        return false
    seen .= _cmp . "|"
    SSOK_QF_AppRecentPath%slot% := path
    SSOK_QF_AppRecentLabel%slot% := slot . ". [" . appName . "] " . SSOK_QF_GetDisplayNameFromPathOrUrl(path)
    slot++
    return true
}

SSOK_QF_GetDisplayNameFromPathOrUrl(path)
{
    _path := Trim(path)
    if (SubStr(_path, 1, 4) = "http")
    {
        _clean := RegExReplace(_path, "[?#].*$")
        _slash := InStr(_clean, "/", false, 0)
        if (_slash > 0)
            _name := SubStr(_clean, _slash + 1)
        else
            _name := _clean
        return SSOK_QF_UrlDecode(_name)
    }
    SplitPath, _path, _name
    return _name
}

SSOK_QF_ReadInternetShortcutUrl(filePath)
{
    FileRead, _content, %filePath%
    if ErrorLevel
        return ""
    Loop, Parse, _content, `n, `r
    {
        _line := Trim(A_LoopField)
        if (SubStr(_line, 1, 4) = "URL=")
            return SubStr(_line, 5)
    }
    return ""
}

SSOK_QF_IsHwpRecentFile(path)
{
    SplitPath, path,,, _ext
    StringLower, _ext, _ext
    return (_ext = "hwp" || _ext = "hwpx" || _ext = "hwtx")
}

SSOK_QF_IsExcelRecentFile(path)
{
    _path := Trim(path)
    StringLower, _lower, _path
    _lower := RegExReplace(_lower, "[?#].*$")
    return (SubStr(_lower, -3) = ".xls" || SubStr(_lower, -4) = ".xlsx")
}

SSOK_QF_XmlUnescape(text)
{
    text := StrReplace(text, "&quot;", Chr(34))
    text := StrReplace(text, "&apos;", "'")
    text := StrReplace(text, "&lt;", "<")
    text := StrReplace(text, "&gt;", ">")
    text := StrReplace(text, "&amp;", "&")
    return text
}

SSOK_QF_UrlDecode(text)
{
    text := StrReplace(text, "+", " ")
    while RegExMatch(text, "i)%([0-9A-F]{2})", _m)
        text := StrReplace(text, _m, Chr("0x" . _m1))
    return text
}

SSOK_QF_OpenAppRecentIndex(index)
{
    global
    _path := SSOK_QF_AppRecentPath%index%
    if (_path = "")
        return
    Gui, SSOKAppRecent:Destroy
    Gui, SSOKQuickFile:Destroy
    Run, %_path%
}

SSOK_QF_AppRecentOpen1:
    SSOK_QF_OpenAppRecentIndex(1)
return
SSOK_QF_AppRecentOpen2:
    SSOK_QF_OpenAppRecentIndex(2)
return
SSOK_QF_AppRecentOpen3:
    SSOK_QF_OpenAppRecentIndex(3)
return
SSOK_QF_AppRecentOpen4:
    SSOK_QF_OpenAppRecentIndex(4)
return
SSOK_QF_AppRecentOpen5:
    SSOK_QF_OpenAppRecentIndex(5)
return
SSOK_QF_AppRecentOpen6:
    SSOK_QF_OpenAppRecentIndex(6)
return
SSOK_QF_AppRecentOpen7:
    SSOK_QF_OpenAppRecentIndex(7)
return
SSOK_QF_AppRecentOpen8:
    SSOK_QF_OpenAppRecentIndex(8)
return
SSOK_QF_AppRecentOpen9:
    SSOK_QF_OpenAppRecentIndex(9)
return
SSOK_QF_AppRecentOpen10:
    SSOK_QF_OpenAppRecentIndex(10)
return
SSOK_QF_AppRecentOpen11:
    SSOK_QF_OpenAppRecentIndex(11)
return
SSOK_QF_AppRecentOpen12:
    SSOK_QF_OpenAppRecentIndex(12)
return

SSOK_QF_OpenAppRecentFolderIndex(index)
{
    global
    _path := SSOK_QF_AppRecentPath%index%
    if (_path = "")
        return
    if (SubStr(_path, 1, 4) = "http")
    {
        _folderUrl := RegExReplace(_path, "[?#].*$")
        _slash := InStr(_folderUrl, "/", false, 0)
        if (_slash > 0)
            _folderUrl := SubStr(_folderUrl, 1, _slash - 1)
        Run, %_folderUrl%
        Gui, SSOKAppRecent:Destroy
        Gui, SSOKQuickFile:Destroy
        return
    }
    SplitPath, _path,, _dir
    if (_dir = "")
        return
    Run, %_dir%
    Gui, SSOKAppRecent:Destroy
    Gui, SSOKQuickFile:Destroy
}

SSOK_QF_AppRecentFolder1:
    SSOK_QF_OpenAppRecentFolderIndex(1)
return
SSOK_QF_AppRecentFolder2:
    SSOK_QF_OpenAppRecentFolderIndex(2)
return
SSOK_QF_AppRecentFolder3:
    SSOK_QF_OpenAppRecentFolderIndex(3)
return
SSOK_QF_AppRecentFolder4:
    SSOK_QF_OpenAppRecentFolderIndex(4)
return
SSOK_QF_AppRecentFolder5:
    SSOK_QF_OpenAppRecentFolderIndex(5)
return
SSOK_QF_AppRecentFolder6:
    SSOK_QF_OpenAppRecentFolderIndex(6)
return
SSOK_QF_AppRecentFolder7:
    SSOK_QF_OpenAppRecentFolderIndex(7)
return
SSOK_QF_AppRecentFolder8:
    SSOK_QF_OpenAppRecentFolderIndex(8)
return
SSOK_QF_AppRecentFolder9:
    SSOK_QF_OpenAppRecentFolderIndex(9)
return
SSOK_QF_AppRecentFolder10:
    SSOK_QF_OpenAppRecentFolderIndex(10)
return
SSOK_QF_AppRecentFolder11:
    SSOK_QF_OpenAppRecentFolderIndex(11)
return
SSOK_QF_AppRecentFolder12:
    SSOK_QF_OpenAppRecentFolderIndex(12)
return

SSOK_QF_IsBrokenKeyword(value)
{
    v := Trim(value)
    if (v = "")
        return 1
    ; À¯´ÏÄÚµå »ç¼³¿µ¿ª/Á¦¾î¹®ÀÚÃ³·³ º¸ÀÌ´Â ±úÁø ±ÛÀÚ°¡ ÀÖÀ¸¸é ±âº»°ªÀ¸·Î º¹±¸
    Loop, Parse, v
    {
        ch := Asc(A_LoopField)
        if (ch < 32)
            return 1
        if (ch >= 0xE000 && ch <= 0xF8FF)
            return 1
    }
    return 0
}

SSOK_BuildKeywordAliases(keyword)
{
    k := Trim(keyword)
    if (k = "")
        return ""

    ; ³Ê¹« ³ÐÀº ´Ü¾î´Â µÚ·Î º¸³»°Å³ª Á¦¿ÜÇÕ´Ï´Ù.
    ; Æ¯È÷ 'ÀÏ¶÷'Àº '±³Á÷¿ø' ´Ü¾î¸¸À¸·Î Ã£Áö ¾Ê°Ô ÇÏ¿©
    ; ±³Á÷¿ø ¿¬¼öÀÚ·á °°Àº ¾û¶×ÇÑ ÃÖ½Å ÆÄÀÏÀÌ ¿­¸®´Â ¹®Á¦¸¦ ¸·½À´Ï´Ù.
    if (InStr(k, "¿¬¶ô"))
        return "ºñ»ó¿¬¶ô¸Á|¿¬¶ô¸Á|ºñ»ó|¿¬¶ô|" . k

    if (InStr(k, "ÀÏ¶÷"))
        return "±³Á÷¿øÀÏ¶÷Ç¥|±³Á÷¿ø ÀÏ¶÷Ç¥|ÀÏ¶÷Ç¥|ÀÏ¶÷|" . k

    return k
}

SSOK_ShowMatchingFileChoices(keywords, maxCount := 12, includeDriveD := false)
{
    global SSOK_QF_ResultPath1, SSOK_QF_ResultPath2, SSOK_QF_ResultPath3, SSOK_QF_ResultPath4, SSOK_QF_ResultPath5, SSOK_QF_ResultPath6, SSOK_QF_ResultPath7, SSOK_QF_ResultPath8, SSOK_QF_ResultPath9, SSOK_QF_ResultPath10, SSOK_QF_ResultPath11, SSOK_QF_ResultPath12

    ; EverythingÀº »ç¿ëÀÚ°¡ ÀÔ·ÂÇÑ ¹®±¸ ±×´ë·Î °Ë»öÇÕ´Ï´Ù.
    if (SSOK_QF_OpenEverythingSearchWindow(keywords))
        return true

    ; EverythingÀÌ ¾øÀ» ¶§¸¸ SSOK ÀÚÃ¼ °Ë»ö º¸Á¤¿ë º°ÄªÀ» Àû¿ëÇÕ´Ï´Ù.
    results := SSOK_FindMatchingFiles(SSOK_BuildKeywordAliases(keywords), maxCount, includeDriveD)
    if (!IsObject(results) || results.MaxIndex() < 1)
    {
        SSOK_ShowCopyFileNotice(keywords)
        return false
    }

    Gui, SSOKFileChoices:Destroy
    Gui, SSOKFileChoices:+AlwaysOnTop +ToolWindow -MinimizeBox
    Gui, SSOKFileChoices:Color, F7FBFF
    Gui, SSOKFileChoices:Margin, 12, 12
    Gui, SSOKFileChoices:Font, s11 bold c005BAC, Malgun Gothic
    Gui, SSOKFileChoices:Add, Text, x12 y10 w800 h24 Center, ÆÄÀÏ °Ë»ö °á°ú
    Gui, SSOKFileChoices:Font, s8 norm c555555, Malgun Gothic
    Gui, SSOKFileChoices:Add, Text, x12 y38 w800 h18 Center, ¿øÇÏ´Â ÆÄÀÏÀ» Å¬¸¯ÇØ¼­ ¿©¼¼¿ä.

    y := 66
    Loop, 12
        SSOK_QF_ResultPath%A_Index% := ""

    for idx, item in results
    {
        path := item.Path
        SSOK_QF_ResultPath%idx% := path
        SplitPath, path, fileName, dir
        FormatTime, modText, % item.Time, yyyy-MM-dd HH:mm
        label := idx . ". " . fileName . "    [" . modText . "]`nÀ§Ä¡: " . dir
        label := StrReplace(label, "&", "&&")
        Gui, SSOKFileChoices:Font, s8 norm c222222, Malgun Gothic
        Gui, SSOKFileChoices:Add, Button, x20 y%y% w690 h42 Left gSSOK_QF_ResultOpen%idx%, %label%
        Gui, SSOKFileChoices:Add, Button, x720 y%y% w90 h42 gSSOK_QF_ResultFolder%idx%, Æú´õ ¿­±â
        y += 48
    }

    h := y + 12
    SSOK_GetSidebarAttachedGuiPos(830, h, SSOK_QF_ChoiceX, SSOK_QF_ChoiceY)
    Gui, SSOKFileChoices:Show, x%SSOK_QF_ChoiceX% y%SSOK_QF_ChoiceY% w830 h%h%, SSOK ÆÄÀÏ °Ë»ö °á°ú
    return true
}

SSOK_FindMatchingFiles(keywords, maxCount := 12, includeDriveD := false)
{
    results := []
    entries := ""
    seen := "|"
    keywords := Trim(keywords)
    if (keywords = "")
        return results

    exts := SSOK_GetQuickFileExtensions()
    keywordList := StrSplit(keywords, "|")
    searchDirs := SSOK_GetQuickFileSearchDirs()
    recursiveDirs := SSOK_GetQuickFileRecursiveSearchDirs()
    maxDepth := SSOK_QF_GetMaxRecursiveDepth()
    ; includeDriveD ÀÎ¼ö´Â ¿¹Àü È£Ãâ È£È¯¿ëÀ¸·Î¸¸ ³²°ÜµÓ´Ï´Ù.
    ; ½ÇÁ¦ °Ë»ö ¹üÀ§´Â ssok.ini [F5QuickFileFolders] ¼±ÅÃ°ª¸¸ »ç¿ëÇÕ´Ï´Ù.

    for kIndex, rawKeyword in keywordList
    {
        keyword := Trim(rawKeyword)
        if (keyword = "")
            continue

        for dIndex, dir in searchDirs
        {
            if (dir = "" || !InStr(FileExist(dir), "D"))
                continue
            for eIndex, ext in exts
            {
                pattern := dir . "\*" . keyword . "*." . ext
                Loop, Files, %pattern%, F
                {
                    if InStr(seen, "|" . A_LoopFileFullPath . "|")
                        continue
                    seen .= A_LoopFileFullPath . "|"
                    entries .= A_LoopFileTimeModified . "`t" . A_LoopFileFullPath . "`n"
                }
            }
        }

        for rdIndex, rdir in recursiveDirs
        {
            SSOK_QF_CollectMatchingFilesRecursive(entries, seen, rdir, keyword, exts, maxDepth)
        }
    }

    Sort, entries, R
    count := 0
    Loop, Parse, entries, `n, `r
    {
        line := A_LoopField
        if (line = "")
            continue
        tabPos := InStr(line, "`t")
        if (tabPos <= 0)
            continue
        item := {}
        item.Time := SubStr(line, 1, tabPos - 1)
        item.Path := SubStr(line, tabPos + 1)
        results.Push(item)
        count++
        if (count >= maxCount)
            break
    }
    return results
}
SSOK_QF_OpenResultIndex(index)
{
    global SSOK_QF_ResultPath1, SSOK_QF_ResultPath2, SSOK_QF_ResultPath3, SSOK_QF_ResultPath4, SSOK_QF_ResultPath5, SSOK_QF_ResultPath6, SSOK_QF_ResultPath7, SSOK_QF_ResultPath8, SSOK_QF_ResultPath9, SSOK_QF_ResultPath10, SSOK_QF_ResultPath11, SSOK_QF_ResultPath12
    path := SSOK_QF_ResultPath%index%
    if (path = "")
        return
    Gui, SSOKFileChoices:Destroy
    Run, %path%
}

SSOK_QF_OpenResultFolderIndex(index)
{
    global SSOK_QF_ResultPath1, SSOK_QF_ResultPath2, SSOK_QF_ResultPath3, SSOK_QF_ResultPath4, SSOK_QF_ResultPath5, SSOK_QF_ResultPath6, SSOK_QF_ResultPath7, SSOK_QF_ResultPath8, SSOK_QF_ResultPath9, SSOK_QF_ResultPath10, SSOK_QF_ResultPath11, SSOK_QF_ResultPath12
    path := SSOK_QF_ResultPath%index%
    if (path = "")
        return
    SplitPath, path,, dir
    if (dir = "")
        return
    Run, %dir%
    Gui, SSOKFileChoices:Destroy
    WinClose, SSOK ÆÄÀÏ °Ë»ö °á°ú ahk_class AutoHotkeyGUI
}

SSOK_QF_ResultOpen1:
    SSOK_QF_OpenResultIndex(1)
return
SSOK_QF_ResultOpen2:
    SSOK_QF_OpenResultIndex(2)
return
SSOK_QF_ResultOpen3:
    SSOK_QF_OpenResultIndex(3)
return
SSOK_QF_ResultOpen4:
    SSOK_QF_OpenResultIndex(4)
return
SSOK_QF_ResultOpen5:
    SSOK_QF_OpenResultIndex(5)
return
SSOK_QF_ResultOpen6:
    SSOK_QF_OpenResultIndex(6)
return
SSOK_QF_ResultOpen7:
    SSOK_QF_OpenResultIndex(7)
return
SSOK_QF_ResultOpen8:
    SSOK_QF_OpenResultIndex(8)
return
SSOK_QF_ResultOpen9:
    SSOK_QF_OpenResultIndex(9)
return
SSOK_QF_ResultOpen10:
    SSOK_QF_OpenResultIndex(10)
return
SSOK_QF_ResultOpen11:
    SSOK_QF_OpenResultIndex(11)
return
SSOK_QF_ResultOpen12:
    SSOK_QF_OpenResultIndex(12)
return

SSOK_QF_ResultFolder1:
    SSOK_QF_OpenResultFolderIndex(1)
return
SSOK_QF_ResultFolder2:
    SSOK_QF_OpenResultFolderIndex(2)
return
SSOK_QF_ResultFolder3:
    SSOK_QF_OpenResultFolderIndex(3)
return
SSOK_QF_ResultFolder4:
    SSOK_QF_OpenResultFolderIndex(4)
return
SSOK_QF_ResultFolder5:
    SSOK_QF_OpenResultFolderIndex(5)
return
SSOK_QF_ResultFolder6:
    SSOK_QF_OpenResultFolderIndex(6)
return
SSOK_QF_ResultFolder7:
    SSOK_QF_OpenResultFolderIndex(7)
return
SSOK_QF_ResultFolder8:
    SSOK_QF_OpenResultFolderIndex(8)
return
SSOK_QF_ResultFolder9:
    SSOK_QF_OpenResultFolderIndex(9)
return
SSOK_QF_ResultFolder10:
    SSOK_QF_OpenResultFolderIndex(10)
return
SSOK_QF_ResultFolder11:
    SSOK_QF_OpenResultFolderIndex(11)
return
SSOK_QF_ResultFolder12:
    SSOK_QF_OpenResultFolderIndex(12)
return
SSOKFileChoicesGuiEscape:
SSOKFileChoicesGuiClose:
    Gui, SSOKFileChoices:Destroy
return
SSOK_OpenFirstMatchingFile(keywords)
{
    keywords := Trim(keywords)
    if (keywords = "")
    {
        SSOK_ShowCopyFileNotice("")
        return false
    }

    _everythingExe := SSOK_QF_FindEverythingExe()
    if (_everythingExe != "")
    {
        ; ÀúÀå Å°¿öµå/¼ýÀÚÅ°/»çÀÌµå¹Ù ºü¸¥ ¹öÆ°Àº Everything °Ë»öÃ¢À» »ç¿ëÀÚ¿¡°Ô ¶ç¿ìÁö ¾Ê°í,
        ; ÃÖ½Å¼ø »ó´Ü °á°ú¿¡ EverythingÀÇ 'Open'(41000) ¸í·ÉÀ» ¹Ù·Î º¸³À´Ï´Ù.
        if (SSOK_QF_OpenNewestMatchingFileWithEverything(keywords, _everythingExe))
            return true

        ; EverythingÀÌ ÀÖ´Â °æ¿ì¿¡´Â SSOK Æú´õ Á¦ÇÑ °Ë»öÀ¸·Î ³»·Á°¡Áö ¾Ê½À´Ï´Ù.
        ; ÀÚµ¿ ¿­±â°¡ ½ÇÆÐÇÏ¸é ÀüÃ¼ µå¶óÀÌºê Everything °Ë»ö °á°ú¸¸ ¶ç¿ó´Ï´Ù.
        if (SSOK_QF_OpenEverythingSearchWindow(keywords))
            return true
        SSOK_ShowCopyFileNotice(keywords)
        return false
    }

    ; Everything.exe°¡ ¾øÀ» ¶§´Â ±âÁ¸ SSOK ÀÚÃ¼ °Ë»ö º¸Á¤¿ë º°ÄªÀ¸·Î ÃÖ½Å ÆÄÀÏÀ» Ã£½À´Ï´Ù.
    bestPath := SSOK_QF_FindNewestFileInternal(SSOK_BuildKeywordAliases(keywords))
    if (bestPath != "")
    {
        Run, %bestPath%
        return true
    }

    SSOK_ShowCopyFileNotice(keywords)
    return false
}

SSOK_QF_OpenEverythingSearchWindow(keywords)
{
    _exePath := SSOK_QF_FindEverythingExe()
    if (_exePath = "")
        return false

    _searchText := SSOK_QF_BuildEverythingWindowSearch(keywords)
    if (_searchText = "")
        return false

    _cmd := SSOK_QF_CmdQuote(_exePath) . " -newwindow -noontop -details -nomatchpath -sort " . SSOK_QF_CmdQuote("Date Modified") . " -sort-descending -s " . SSOK_QF_CmdQuote(_searchText)
    Run, %_cmd%,, UseErrorLevel
    return !ErrorLevel
}

SSOK_QF_OpenEverythingRecentDocsWindow()
{
    _exePath := SSOK_QF_FindEverythingExe()
    if (_exePath = "")
        return false

    _extSearch := SSOK_QF_BuildEverythingExtSearch(SSOK_GetQuickFileExtensions())
    if (_extSearch = "")
        return false
    _searchText := "file: " . _extSearch
    _cmd := SSOK_QF_CmdQuote(_exePath) . " -newwindow -noontop -details -nomatchpath -sort " . SSOK_QF_CmdQuote("Date Modified") . " -sort-descending -s " . SSOK_QF_CmdQuote(_searchText)
    Run, %_cmd%,, UseErrorLevel
    return !ErrorLevel
}

SSOK_QF_FindEverythingExe()
{
    static _cached := ""

    ; ÀúÀåµÈ Ä³½Ã°¡ ½ÇÁ¦·Î »ì¾Æ ÀÖÀ» ¶§¸¸ ¹Ù·Î »ç¿ëÇÕ´Ï´Ù.
    if (_cached != "" && FileExist(_cached))
        return _cached
    _cached := ""

    _ini := SSOK_IniFile

    ; 1¼øÀ§: ssok.ini¿¡ ÀúÀåµÈ °æ·Î
    IniRead, _savedEverythingExe, %_ini%, Everything, ExePath, __SSOK_MISSING__
    _result := SSOK_QF_TryRememberEverythingExe(_savedEverythingExe, _ini)
    if (_result != "")
    {
        _cached := _result
        return _cached
    }

    ; ini¿¡ ³²Àº °æ·Î°¡ »èÁ¦/ÀÌµ¿µÈ °æ¿ì, Àß¸øµÈ °ª ¶§¹®¿¡ °è¼Ó ¸·È÷Áö ¾Êµµ·Ï Á¤¸®ÇÕ´Ï´Ù.
    _savedEverythingExe := Trim(_savedEverythingExe, " `t`r`n")
    if (_savedEverythingExe != "" && _savedEverythingExe != "__SSOK_MISSING__")
    {
        IniDelete, %_ini%, Everything, ExePath
        IniDelete, %_ini%, Everything, LastFound
    }

    EnvGet, _programFiles, ProgramFiles
    EnvGet, _programFilesX86, ProgramFiles(x86)
    EnvGet, _programW6432, ProgramW6432
    EnvGet, _userProfile, USERPROFILE
    EnvGet, _localAppData, LOCALAPPDATA

    _downloads := SSOK_GetShellFolderPath("shell:Downloads")
    if (_downloads = "" && _userProfile != "")
        _downloads := _userProfile . "\Downloads"
    _downloads := RTrim(Trim(_downloads), "")

    _candidates := []
    _candidates.Push(A_ScriptDir . "\Everything.exe")
    _candidates.Push(A_ScriptDir . "\Everything\Everything.exe")
    _candidates.Push(A_ScriptDir . "\Everything 1.5a\Everything.exe")
    _candidates.Push(A_ScriptDir . "\Everything 1.4\Everything.exe")

    ; 2¼øÀ§: ·¹Áö½ºÆ®¸® App Paths¿¡ µî·ÏµÈ Everything.exe
    _regKeys := []
    _regKeys.Push("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Everything.exe")
    _regKeys.Push("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Everything.exe")
    for _idx, _regKey in _regKeys
    {
        RegRead, _regEverythingExe, %_regKey%
        if (!ErrorLevel)
            _candidates.Push(_regEverythingExe)
    }

    ; 3¼øÀ§: ´ëÇ¥ ¼³Ä¡ °æ·Î Á÷Á¢ È®ÀÎ
    _roots := []
    if (_programW6432 != "")
        _roots.Push(_programW6432)
    if (_programFiles != "")
        _roots.Push(_programFiles)
    if (_programFilesX86 != "")
        _roots.Push(_programFilesX86)
    _roots.Push("C:\Program Files")
    _roots.Push("C:\Program Files (x86)")
    if (_localAppData != "")
        _roots.Push(_localAppData . "\Programs")

    _seenRoots := "|"
    for _idx, _root in _roots
    {
        _root := RTrim(Trim(_root), "")
        if (_root = "")
            continue
        _rootKey := "|" . _root . "|"
        if InStr(_seenRoots, _rootKey)
            continue
        _seenRoots .= _root . "|"

        _candidates.Push(_root . "\Everything\Everything.exe")
        _candidates.Push(_root . "\Everything 1.5a\Everything.exe")
        _candidates.Push(_root . "\Everything 1.5\Everything.exe")
        _candidates.Push(_root . "\Everything 1.4\Everything.exe")
        _candidates.Push(_root . "\Everything 1.4.1\Everything.exe")

        ; Everything 1.4.1.1026, Everything 1.5a, Everything 1.5.x µî Æú´õ¸íÀÌ ´Þ¶óµµ Ã£½À´Ï´Ù.
        _pattern := _root . "\Everything*"
        Loop, Files, %_pattern%, D
            _candidates.Push(A_LoopFileFullPath . "\Everything.exe")

        ; ÀÏºÎ È¯°æ¿¡¼­ µð·ºÅÍ¸® ¿ÍÀÏµåÄ«µå°¡ ´Ù¸£°Ô µ¿ÀÛÇÒ ¼ö ÀÖ¾î exe ÆÐÅÏµµ ÇÑ ¹ø ´õ È®ÀÎÇÕ´Ï´Ù.
        _patternExe := _root . "\Everything*\Everything.exe"
        Loop, Files, %_patternExe%, F
            _candidates.Push(A_LoopFileFullPath)
    }

    if (_downloads != "")
    {
        _candidates.Push(_downloads . "\Everything.exe")
        _candidates.Push(_downloads . "\Everything\Everything.exe")
    }

    for _idx, _candidate in _candidates
    {
        _result := SSOK_QF_TryRememberEverythingExe(_candidate, _ini)
        if (_result != "")
        {
            _cached := _result
            return _cached
        }
    }

    ; 4¼øÀ§: PATH µî·Ï È®ÀÎ
    _whereFile := SSOK_GlobalGetPrivateWorkDir("misc") . "\ssok_everything_where_" . A_TickCount . ".txt"
    FileDelete, %_whereFile%
    _whereCmd := ComSpec . " /C where Everything.exe > " . SSOK_QF_CmdQuote(_whereFile) . " 2>nul"
    RunWait, %_whereCmd%,, Hide
    if FileExist(_whereFile)
    {
        FileRead, _whereText, %_whereFile%
        FileDelete, %_whereFile%
        Loop, Parse, _whereText, `n, `r
        {
            _result := SSOK_QF_TryRememberEverythingExe(A_LoopField, _ini)
            if (_result != "")
            {
                _cached := _result
                return _cached
            }
        }
    }

    ; ½ÇÆÐ°ªÀº Ä³½ÃÇÏÁö ¾Ê½À´Ï´Ù. ºÎÆÃ Á÷ÈÄ/¼³Ä¡ Á÷ÈÄ ´Ù½Ã ½ÃµµÇÒ ¼ö ÀÖ°Ô ÇÏ±â À§ÇÔÀÔ´Ï´Ù.
    return ""
}

SSOK_QF_TryRememberEverythingExe(candidate, iniPath)
{
    _candidate := SSOK_QF_NormalizeEverythingExeCandidate(candidate)
    if (_candidate = "" || !FileExist(_candidate))
        return ""

    FormatTime, _now,, yyyyMMddHHmmss
    IniWrite, %_candidate%, %iniPath%, Everything, ExePath
    IniWrite, %_now%, %iniPath%, Everything, LastFound
    return _candidate
}

SSOK_QF_NormalizeEverythingExeCandidate(candidate)
{
    _candidate := Trim(candidate, " `t`r`n")
    if (_candidate = "" || _candidate = "__SSOK_MISSING__")
        return ""

    ; µû¿ÈÇ¥·Î °¨½Ñ °æ·Î ¶Ç´Â µÚ¿¡ ÀÎ¼ö°¡ ºÙÀº °æ·Î¸¦ ¾ÈÀüÇÏ°Ô Á¤¸®ÇÕ´Ï´Ù.
    if RegExMatch(_candidate, "i)""([^""`r`n]*\\Everything\.exe)""", _m)
        return _m1
    if RegExMatch(_candidate, "i)([A-Z]:\\[^<>|?*`r`n]*\\Everything\.exe)", _m)
        return _m1

    return Trim(_candidate, """")
}

SSOK_QF_GetEverythingSearchDirs()
{
    _dirs := []
    _searchDirs := SSOK_GetQuickFileSearchDirs()
    _recursiveDirs := SSOK_GetQuickFileRecursiveSearchDirs()
    for _idx, _dir in _searchDirs
        SSOK_AddQuickFileDir(_dirs, _dir)
    for _idx, _dir in _recursiveDirs
        SSOK_AddQuickFileDir(_dirs, _dir)
    return _dirs
}

SSOK_QF_BuildEverythingWindowSearch(keywords)
{
    _keywordSearch := SSOK_QF_BuildEverythingKeywordGroup(keywords)
    if (_keywordSearch = "")
        return ""
    ; EverythingÀº ÀÎµ¦½º °Ë»öÀÌ ºü¸£¹Ç·Î Æú´õ Á¦ÇÑ ¹®±¸(<Æú´õ1|Æú´õ2...>)¸¦ ºÙÀÌÁö ¾Ê½À´Ï´Ù.
    ; Æú´õ Á¦ÇÑ °Ë»öÀº Everything.exe°¡ ¾øÀ» ¶§ ±âÁ¸ SSOK ÀÚÃ¼ °Ë»ö¿¡¼­¸¸ Àû¿ëµË´Ï´Ù.
    _extSearch := SSOK_QF_BuildEverythingExtSearch(SSOK_GetQuickFileExtensions())

    _searchText := "file: " . _keywordSearch
    if (_extSearch != "")
        _searchText .= " " . _extSearch
    return _searchText
}

SSOK_QF_BuildEverythingKeywordGroup(keywords)
{
    _text := ""
    Loop, Parse, keywords, |
    {
        _keyword := Trim(A_LoopField)
        if (_keyword = "")
            continue
        _term := SSOK_QF_EverythingSearchQuote(_keyword)
        if (_text = "")
            _text := _term
        else
            _text .= "|" . _term
    }
    if InStr(_text, "|")
        return "<" . _text . ">"
    return _text
}

SSOK_QF_BuildEverythingDirGroup()
{
    _dirs := SSOK_QF_GetEverythingSearchDirs()
    _text := ""
    for _idx, _dir in _dirs
    {
        _dir := SSOK_QF_PathForEverything(_dir)
        if (_dir = "")
            continue
        _term := SSOK_QF_EverythingSearchQuote(_dir)
        if (_text = "")
            _text := _term
        else
            _text .= "|" . _term
    }
    if InStr(_text, "|")
        return "<" . _text . ">"
    return _text
}

SSOK_QF_BuildEverythingExtSearch(exts)
{
    _text := ""
    for _idx, _ext in exts
    {
        _ext := Trim(_ext, " `t`r`n.")
        if (_ext = "")
            continue
        if (_text = "")
            _text := "ext:" . _ext
        else
            _text .= ";" . _ext
    }
    return _text
}

SSOK_QF_PathForEverything(path)
{
    path := Trim(path, " `t`r`n")
    if RegExMatch(path, "i)^[A-Z]:$", _m)
        return path . ""
    return path
}

SSOK_QF_EverythingSearchQuote(text)
{
    text := Trim(text, " `t`r`n")
    text := StrReplace(text, Chr(34), Chr(34) . Chr(34) . Chr(34))
    return Chr(34) . text . Chr(34)
}

SSOK_QF_CmdQuote(text)
{
    text := StrReplace(text, Chr(34), Chr(34) . Chr(34))
    return Chr(34) . text . Chr(34)
}

SSOK_QF_FindNewestMatchingFileFast(keywords)
{
    static _cacheKeyword := "", _cachePath := "", _cacheTick := 0
    keywords := Trim(keywords)
    if (keywords = "")
        return ""

    ; °°Àº Å°¿öµå·Î "ÀúÀå&¿­±â"¿Í "Æú´õ ¿­±â"¸¦ ¿¬¼Ó ½ÇÇàÇÒ ¶§´Â ¹æ±Ý Ã£Àº ÃÖ½Å ÆÄÀÏÀ» Àç»ç¿ëÇÕ´Ï´Ù.
    if (_cacheKeyword = keywords && _cachePath != "" && FileExist(_cachePath) && (A_TickCount - _cacheTick < 15000))
        return _cachePath

    _everythingExe := SSOK_QF_FindEverythingExe()
    if (_everythingExe != "")
    {
        _path := SSOK_QF_FindNewestFileWithEverythingExe(keywords, _everythingExe)
        if (_path != "" && FileExist(_path))
        {
            _cacheKeyword := keywords
            _cachePath := _path
            _cacheTick := A_TickCount
            return _path
        }
        ; Everything.exe°¡ ÀÖ´Â PC¿¡¼­´Â ´À¸° SSOK ÀÚÃ¼ ÀüÃ¼ ½ºÄµÀ¸·Î µÇµ¹¾Æ°¡Áö ¾Ê½À´Ï´Ù.
        ; ½ÇÆÐ ½Ã Áï½Ã "¸ø Ã£À½" Ã³¸®ÇÏ¿© Win+F4°¡ ¸ØÃá °ÍÃ³·³ ´À²¸Áö´Â ¹®Á¦¸¦ ÁÙÀÔ´Ï´Ù.
        return ""
    }

    _path := SSOK_QF_FindNewestFileInternal(SSOK_BuildKeywordAliases(keywords))
    if (_path != "" && FileExist(_path))
    {
        _cacheKeyword := keywords
        _cachePath := _path
        _cacheTick := A_TickCount
    }
    return _path
}

SSOK_QF_FindNewestFileWithEverythingExe(keywords, exePath := "")
{
    if (exePath = "")
        exePath := SSOK_QF_FindEverythingExe()
    if (exePath = "")
        return ""

    ; ¸ÕÀú Everything IPC·Î Ã¢ ¾øÀÌ °æ·Î¸¦ ¹Þ½À´Ï´Ù.
    _path := SSOK_QF_FindNewestFileWithEverythingIPCOnly(keywords, exePath)
    if (_path != "" && FileExist(_path))
        return _path

    ; IPC Ã¢À» Ã£Áö ¸øÇÏ´Â È¯°æ¿¡¼­´Â Everything.exe ÀÓ½Ã °Ë»öÃ¢À» ÃÖ¼ÒÈ­·Î ¶ç¿ö
    ; Ã¹ °á°úÀÇ ÀüÃ¼ °æ·Î¸¸ º¹»çÇÑ µÚ ´Ý½À´Ï´Ù. SSOK Æú´õ Á¦ÇÑ °Ë»öÀ¸·Î´Â ³»·Á°¡Áö ¾Ê½À´Ï´Ù.
    return SSOK_QF_FindNewestFileViaEverythingWindowFallback(keywords, exePath)
}

SSOK_QF_FindNewestFileWithEverythingIPCOnly(keywords, exePath)
{
    if (exePath = "" || !FileExist(exePath))
        return ""

    if (!SSOK_QF_EnsureEverythingIpcReady(exePath))
        return ""

    _searchText := SSOK_QF_BuildEverythingWindowSearch(keywords)
    if (_searchText = "")
        return ""

    ; IPC °á°ú°¡ ±âº» ÀÌ¸§¼øÀÏ ¼ö ÀÖÀ¸¹Ç·Î ÈÄº¸¸¦ ³Ë³ËÈ÷ ¹Þ¾Æ AHK¿¡¼­ ¼öÁ¤ÀÏÀ» ´Ù½Ã È®ÀÎÇÕ´Ï´Ù.
    _paths := SSOK_QF_EverythingIpcQuery(_searchText, 5000)
    if (!IsObject(_paths) || _paths.MaxIndex() < 1)
        return ""

    return SSOK_QF_PickNewestExistingFile(_paths)
}

SSOK_QF_PickNewestExistingFile(paths)
{
    _bestPath := ""
    _bestTime := 0
    if (!IsObject(paths))
        return ""

    for _idx, _path in paths
    {
        _path := Trim(_path, " `t`r`n" . Chr(34))
        if (_path = "" || !FileExist(_path))
            continue
        FileGetAttrib, _attr, %_path%
        if InStr(_attr, "D")
            continue
        FileGetTime, _mtime, %_path%, M
        if (_mtime > _bestTime)
        {
            _bestTime := _mtime
            _bestPath := _path
        }
    }
    return _bestPath
}

SSOK_QF_FindNewestFileViaEverythingWindowFallback(keywords, exePath)
{
    _path := ""
    SSOK_QF_RunEverythingNewestResultCommand(keywords, 0, _path, exePath)
    return _path
}

SSOK_QF_OpenNewestMatchingFileWithEverything(keywords, exePath := "")
{
    _path := SSOK_QF_FindNewestFileWithEverythingExe(keywords, exePath)
    if (_path = "" || !FileExist(_path))
        return false
    _target := Chr(34) . _path . Chr(34)
    Run, %_target%,, UseErrorLevel
    return !ErrorLevel
}

SSOK_QF_OpenNewestMatchingFolderWithEverything(keywords, exePath := "")
{
    _path := SSOK_QF_FindNewestFileWithEverythingExe(keywords, exePath)
    if (_path = "" || !FileExist(_path))
        return false
    SplitPath, _path,, _dir
    if (_dir = "" || !InStr(FileExist(_dir), "D"))
        return false
    _cmd := "explorer.exe /select," . Chr(34) . _path . Chr(34)
    Run, %_cmd%,, UseErrorLevel
    return !ErrorLevel
}

SSOK_QF_RunEverythingNewestResultCommand(keywords, commandId, ByRef outPath, exePath := "")
{
    outPath := ""
    if (exePath = "")
        exePath := SSOK_QF_FindEverythingExe()
    if (exePath = "" || !FileExist(exePath))
        return false

    _searchText := SSOK_QF_BuildEverythingWindowSearch(keywords)
    if (_searchText = "")
        return false

    _beforeWindows := SSOK_QF_GetEverythingSearchWindowIdList()

    _cmd := SSOK_QF_CmdQuote(exePath) . " -newwindow -minimized -noontop -details -nomatchpath -sort " . SSOK_QF_CmdQuote("Date Modified") . " -sort-descending -focus-results -focus-top-result -s " . SSOK_QF_CmdQuote(_searchText)
    Run, %_cmd%,, UseErrorLevel, _pid
    if (ErrorLevel)
        return false

    _hwnd := SSOK_QF_WaitForEverythingSearchWindow(_beforeWindows, _pid, 1800)
    if (!_hwnd)
        return false

    ; ÀÓ½Ã °Ë»öÃ¢Àº ÃÖ¼ÒÈ­ »óÅÂ·Î ¿­¾î Áß¾Ó¿¡ ¹ÝÂ¦ÀÌÁö ¾Ê°Ô µÓ´Ï´Ù.
    _isNewWindow := !InStr(_beforeWindows, "|" . _hwnd . "|")

    ; ÃÖ½Å¼ø Á¤·Ä ¹× »ó´Ü °á°ú Æ÷Ä¿½º°¡ ¹Ý¿µµÉ ½Ã°£À» Âª°Ô¸¸ ÁÝ´Ï´Ù.
    Sleep, 220
    SendMessage, 0x111, 41010, 0,, ahk_id %_hwnd%  ; UI_ID_RESULT_LIST_FOCUS
    SendMessage, 0x111, 41022, 0,, ahk_id %_hwnd%  ; UI_ID_RESULT_LIST_START
    Sleep, 80

    if (commandId)
    {
        ; Everything ±âº» ´ÜÃàÅ°¸¦ »ç¿ëÇÕ´Ï´Ù: Enter=¿­±â, Ctrl+Enter=°æ·Î ¿­±â.
        WinActivate, ahk_id %_hwnd%
        WinWaitActive, ahk_id %_hwnd%,, 0.8
        SendMessage, 0x111, 41010, 0,, ahk_id %_hwnd%  ; UI_ID_RESULT_LIST_FOCUS
        SendMessage, 0x111, 41022, 0,, ahk_id %_hwnd%  ; UI_ID_RESULT_LIST_START
        Sleep, 120
        if (commandId = 41003)
            Send, ^{Enter}
        else
            Send, {Enter}
        Sleep, 260
        if (_isNewWindow)
            WinClose, ahk_id %_hwnd%
        return true
    }

    _path := SSOK_QF_CopyEverythingFocusedResultPath(_hwnd)
    if (_path = "" || !FileExist(_path))
    {
        if (_isNewWindow)
            WinClose, ahk_id %_hwnd%
        return false
    }

    FileGetAttrib, _attr, %_path%
    if InStr(_attr, "D")
    {
        if (_isNewWindow)
            WinClose, ahk_id %_hwnd%
        return false
    }

    outPath := _path
    if (_isNewWindow)
        WinClose, ahk_id %_hwnd%
    return true
}
SSOK_QF_GetEverythingSearchWindowIdList()
{
    _out := "|"
    WinGet, _list, List, ahk_exe Everything.exe
    Loop, %_list%
    {
        _id := _list%A_Index%
        if (SSOK_QF_IsEverythingSearchWindow(_id))
            _out .= _id . "|"
    }
    return _out
}

SSOK_QF_WaitForEverythingSearchWindow(beforeWindows, pid := "", timeoutMs := 2500)
{
    _start := A_TickCount
    Loop
    {
        _newHwnd := SSOK_QF_FindNewEverythingSearchWindow(beforeWindows, pid)
        if (_newHwnd)
            return _newHwnd
        if (A_TickCount - _start > timeoutMs)
            break
        Sleep, 80
    }
    return SSOK_QF_FindAnyEverythingSearchWindow(pid)
}

SSOK_QF_FindNewEverythingSearchWindow(beforeWindows, pid := "")
{
    WinGet, _list, List, ahk_exe Everything.exe
    Loop, %_list%
    {
        _id := _list%A_Index%
        if InStr(beforeWindows, "|" . _id . "|")
            continue
        if (!SSOK_QF_IsEverythingSearchWindow(_id))
            continue
        return _id
    }
    return 0
}

SSOK_QF_FindAnyEverythingSearchWindow(pid := "")
{
    WinGet, _list, List, ahk_exe Everything.exe
    Loop, %_list%
    {
        _id := _list%A_Index%
        if (!SSOK_QF_IsEverythingSearchWindow(_id))
            continue
        return _id
    }
    return 0
}

SSOK_QF_IsEverythingSearchWindow(hwnd)
{
    if (!hwnd)
        return false
    WinGetClass, _className, ahk_id %hwnd%
    if (_className = "" || InStr(_className, "TASKBAR_NOTIFICATION"))
        return false
    if !RegExMatch(_className, "i)^EVERYTHING")
        return false
    if (!DllCall("IsWindowVisible", "Ptr", hwnd, "Int"))
        return false
    return true
}

SSOK_QF_CopyEverythingFocusedResultPath(hwnd)
{
    if (!hwnd)
        return ""

    _clipSaved := ClipboardAll
    Clipboard := ""

    ; WM_COMMAND 41007 = Everything °á°ú ¸ñ·ÏÀÇ ÇöÀç ¼±ÅÃ Ç×¸ñ ÀüÃ¼ °æ·Î º¹»ç
    Loop, 2
    {
        Clipboard := ""
        SendMessage, 0x111, 41007, 0,, ahk_id %hwnd%
        ClipWait, 0.8
        if (!ErrorLevel)
            break
        Sleep, 80
    }
    if (ErrorLevel)
    {
        Clipboard := _clipSaved
        VarSetCapacity(_clipSaved, 0)
        return ""
    }
    _text := Clipboard

    Clipboard := _clipSaved
    VarSetCapacity(_clipSaved, 0)

    _text := Trim(_text, " `t`r`n" . Chr(34))
    if (_text = "")
        return ""
    Loop, Parse, _text, `n, `r
    {
        _line := Trim(A_LoopField, " `t`r`n" . Chr(34))
        if (_line != "")
            return _line
    }
    return ""
}

SSOK_QF_EnsureEverythingIpcReady(exePath)
{
    if (SSOK_QF_FindEverythingIpcHwnd())
        return true

    exePath := Trim(exePath)
    if (exePath = "" || !FileExist(exePath))
        return false

    ; Everything.exe¸¸ »ç¿ëÇÕ´Ï´Ù. -startupÀº °Ë»öÃ¢À» ¶ç¿ìÁö ¾Ê°í ¹é±×¶ó¿îµå IPC¸¦ ÁØºñÇÕ´Ï´Ù.
    _cmd := SSOK_QF_CmdQuote(exePath) . " -startup"
    Run, %_cmd%,, UseErrorLevel

    Loop, 25
    {
        Sleep, 120
        if (SSOK_QF_FindEverythingIpcHwnd())
            return true
    }
    return false
}

SSOK_QF_FindEverythingIpcHwnd()
{
    _classes := []
    _classes.Push("EVERYTHING_TASKBAR_NOTIFICATION")
    _classes.Push("EVERYTHING_TASKBAR_NOTIFICATION_(1.5a)")
    _classes.Push("EVERYTHING_TASKBAR_NOTIFICATION (1.5a)")

    for _idx, _className in _classes
    {
        _hwnd := DllCall("FindWindow", "Str", _className, "Ptr", 0, "Ptr")
        if (_hwnd)
            return _hwnd
    }
    return 0
}

SSOK_QF_GetEverythingIpcReplyHwnd()
{
    global SSOK_EverythingIPC_Hwnd
    if (SSOK_EverythingIPC_Hwnd)
        return SSOK_EverythingIPC_Hwnd

    Gui, SSOKEverythingIPC:New, +HwndSSOK_EverythingIPC_Hwnd +ToolWindow -Caption
    Gui, SSOKEverythingIPC:Show, Hide, SSOKEverythingIPC
    return SSOK_EverythingIPC_Hwnd
}

SSOK_QF_EverythingIpcQuery(searchText, maxResults := 300)
{
    global SSOK_EverythingIPC_Done, SSOK_EverythingIPC_Results, SSOK_EverythingIPC_ReplyMessage

    _everythingHwnd := SSOK_QF_FindEverythingIpcHwnd()
    if (!_everythingHwnd)
        return ""

    _replyHwnd := SSOK_QF_GetEverythingIpcReplyHwnd()
    if (!_replyHwnd)
        return ""

    SSOK_EverythingIPC_Done := false
    SSOK_EverythingIPC_Results := []
    SSOK_EverythingIPC_ReplyMessage := 0x534F4B51
    OnMessage(0x4A, "SSOK_QF_EverythingIPC_OnCopyData")

    if (!SSOK_QF_SendEverythingIpcQuery(_everythingHwnd, _replyHwnd, maxResults, searchText, SSOK_EverythingIPC_ReplyMessage))
        return ""

    _startTick := A_TickCount
    Loop
    {
        if (SSOK_EverythingIPC_Done)
            return SSOK_EverythingIPC_Results
        if (A_TickCount - _startTick > 1600)
            break
        Sleep, 30
    }
    return ""
}

SSOK_QF_SendEverythingIpcQuery(everythingHwnd, replyHwnd, maxResults, searchText, replyMessage)
{
    if (!everythingHwnd || !replyHwnd || searchText = "")
        return false

    _isUnicode := A_IsUnicode
    _charSize := _isUnicode ? 2 : 1
    _copyDataQuery := _isUnicode ? 2 : 1
    _searchFlags := 0
    _headerSize := 16 + A_PtrSize
    _chars := StrLen(searchText) + 1
    _querySize := _headerSize + (_chars * _charSize)
    VarSetCapacity(_query, _querySize, 0)

    NumPut(maxResults, _query, 0, "UInt")
    NumPut(0, _query, 4, "UInt")
    NumPut(replyMessage, _query, 8, "UInt")
    NumPut(_searchFlags, _query, 12, "UInt")
    NumPut(replyHwnd, _query, 16, "Ptr")

    if (_isUnicode)
        StrPut(searchText, &_query + _headerSize, _chars, "UTF-16")
    else
        StrPut(searchText, &_query + _headerSize, _chars, "CP0")

    _lpOffset := (A_PtrSize = 8) ? 16 : 8
    VarSetCapacity(_cds, _lpOffset + A_PtrSize, 0)
    NumPut(_copyDataQuery, _cds, 0, "Ptr")
    NumPut(_querySize, _cds, A_PtrSize, "UInt")
    NumPut(&_query, _cds, _lpOffset, "Ptr")

    _ret := DllCall("SendMessage", "Ptr", everythingHwnd, "UInt", 0x4A, "Ptr", replyHwnd, "Ptr", &_cds, "Ptr")
    return (_ret != 0)
}

SSOK_QF_EverythingIPC_OnCopyData(wParam, lParam, msg, hwnd)
{
    global SSOK_EverythingIPC_Done, SSOK_EverythingIPC_Results, SSOK_EverythingIPC_ReplyMessage

    if (!lParam)
        return

    _dwData := NumGet(lParam + 0, 0, "Ptr")
    if (_dwData != SSOK_EverythingIPC_ReplyMessage)
        return

    _lpOffset := (A_PtrSize = 8) ? 16 : 8
    _listPtr := NumGet(lParam + 0, _lpOffset, "Ptr")
    if (!_listPtr)
    {
        SSOK_EverythingIPC_Done := true
        return 1
    }

    _numItems := NumGet(_listPtr + 0, 4, "UInt")
    _itemBase := _listPtr + 12
    _itemSize := 12
    _results := []

    Loop, %_numItems%
    {
        _itemPtr := _itemBase + ((A_Index - 1) * _itemSize)
        _fileOffset := NumGet(_itemPtr + 0, 4, "UInt")
        _pathOffset := NumGet(_itemPtr + 0, 8, "UInt")
        if (!_fileOffset || !_pathOffset)
            continue

        if (A_IsUnicode)
        {
            _path := StrGet(_listPtr + _pathOffset, "UTF-16")
            _file := StrGet(_listPtr + _fileOffset, "UTF-16")
        }
        else
        {
            _path := StrGet(_listPtr + _pathOffset, "CP0")
            _file := StrGet(_listPtr + _fileOffset, "CP0")
        }

        if (_path = "")
            _full := _file
        else
            _full := RTrim(_path, "") . "" . _file
        _results.Push(_full)
    }

    SSOK_EverythingIPC_Results := _results
    SSOK_EverythingIPC_Done := true
    return 1
}

SSOK_QF_FindNewestFileInternal(keywords)
{
    _bestPath := ""
    _bestTime := 0
    keywords := Trim(keywords)
    if (keywords = "")
        return ""

    _exts := SSOK_GetQuickFileExtensions()
    _keywordList := StrSplit(keywords, "|")
    _searchDirs := SSOK_GetQuickFileSearchDirs()
    _recursiveDirs := SSOK_GetQuickFileRecursiveSearchDirs()
    _maxDepth := SSOK_QF_GetMaxRecursiveDepth()

    for _kIndex, _rawKeyword in _keywordList
    {
        _keyword := Trim(_rawKeyword)
        if (_keyword = "")
            continue

        for _dIndex, _dir in _searchDirs
        {
            if (_dir = "" || !InStr(FileExist(_dir), "D"))
                continue
            for _eIndex, _ext in _exts
            {
                _pattern := _dir . "\*" . _keyword . "*." . _ext
                Loop, Files, %_pattern%, F
                {
                    if (A_LoopFileTimeModified > _bestTime)
                    {
                        _bestTime := A_LoopFileTimeModified
                        _bestPath := A_LoopFileFullPath
                    }
                }
            }
        }

        for _rdIndex, _rdir in _recursiveDirs
            SSOK_QF_FindBestMatchingFileRecursive(_bestPath, _bestTime, _rdir, _keyword, _exts, _maxDepth)
    }

    return _bestPath
}

SSOK_QF_GetMaxRecursiveDepth()
{
    return 4
}

SSOK_QF_CollectMatchingFilesRecursive(ByRef entries, ByRef seen, dir, keyword, exts, maxDepth, depth := 0)
{
    if (dir = "" || !InStr(FileExist(dir), "D"))
        return

    for eIndex, ext in exts
    {
        pattern := dir . "\*" . keyword . "*." . ext
        Loop, Files, %pattern%, F
        {
            if InStr(seen, "|" . A_LoopFileFullPath . "|")
                continue
            seen .= A_LoopFileFullPath . "|"
            entries .= A_LoopFileTimeModified . "`t" . A_LoopFileFullPath . "`n"
        }
    }

    if (depth >= maxDepth)
        return

    folderPattern := dir . "\*.*"
    Loop, Files, %folderPattern%, D
    {
        SSOK_QF_CollectMatchingFilesRecursive(entries, seen, A_LoopFileFullPath, keyword, exts, maxDepth, depth + 1)
    }
}

SSOK_QF_FindBestMatchingFileRecursive(ByRef bestPath, ByRef bestTime, dir, keyword, exts, maxDepth, depth := 0)
{
    if (dir = "" || !InStr(FileExist(dir), "D"))
        return

    for eIndex, ext in exts
    {
        pattern := dir . "\*" . keyword . "*." . ext
        Loop, Files, %pattern%, F
        {
            if (A_LoopFileTimeModified > bestTime)
            {
                bestTime := A_LoopFileTimeModified
                bestPath := A_LoopFileFullPath
            }
        }
    }

    if (depth >= maxDepth)
        return

    folderPattern := dir . "\*.*"
    Loop, Files, %folderPattern%, D
    {
        SSOK_QF_FindBestMatchingFileRecursive(bestPath, bestTime, A_LoopFileFullPath, keyword, exts, maxDepth, depth + 1)
    }
}
SSOK_GetQuickFileSearchDirs()
{
    global SSOK_QF_SearchDownloads, SSOK_QF_SearchDocuments
    dirs := []
    SSOK_QF_LoadFolderSettings()

    SSOK_AddQuickFileDir(dirs, A_ScriptDir)

    EnvGet, oneDrive, OneDrive
    EnvGet, oneDriveConsumer, OneDriveConsumer
    EnvGet, oneDriveCommercial, OneDriveCommercial

    if (SSOK_QF_SearchDownloads)
    {
        SSOK_AddQuickFileDir(dirs, oneDrive . "\Downloads")
        SSOK_AddQuickFileDir(dirs, oneDriveConsumer . "\Downloads")
        SSOK_AddQuickFileDir(dirs, oneDriveCommercial . "\Downloads")
    }
    if (SSOK_QF_SearchDocuments)
    {
        SSOK_AddQuickFileDir(dirs, oneDrive . "\Documents")
        SSOK_AddQuickFileDir(dirs, oneDriveConsumer . "\Documents")
        SSOK_AddQuickFileDir(dirs, oneDriveCommercial . "\Documents")
    }
    return dirs
}

SSOK_GetQuickFileRecursiveSearchDirs()
{
    global SSOK_QF_SearchDesktop, SSOK_QF_SearchDownloads, SSOK_QF_SearchDocuments, SSOK_QF_SearchExtraFolders
    dirs := []
    SSOK_QF_LoadFolderSettings()

    EnvGet, userProfile, USERPROFILE
    EnvGet, oneDrive, OneDrive
    EnvGet, oneDriveConsumer, OneDriveConsumer
    EnvGet, oneDriveCommercial, OneDriveCommercial

    if (SSOK_QF_SearchDesktop)
    {
        SSOK_AddQuickFileDir(dirs, A_Desktop)
        SSOK_AddQuickFileDir(dirs, A_DesktopCommon)
    }
    if (SSOK_QF_SearchDownloads)
    {
        SSOK_AddQuickFileDir(dirs, SSOK_GetShellFolderPath("shell:Downloads"))
        SSOK_AddQuickFileDir(dirs, userProfile . "\Downloads")
        SSOK_AddQuickFileDir(dirs, oneDrive . "\Downloads")
        SSOK_AddQuickFileDir(dirs, oneDriveConsumer . "\Downloads")
        SSOK_AddQuickFileDir(dirs, oneDriveCommercial . "\Downloads")
    }
    if (SSOK_QF_SearchDocuments)
    {
        SSOK_AddQuickFileDir(dirs, SSOK_GetShellFolderPath("shell:Personal"))
        SSOK_AddQuickFileDir(dirs, A_MyDocuments)
        SSOK_AddQuickFileDir(dirs, userProfile . "\Documents")
        SSOK_AddQuickFileDir(dirs, oneDrive . "\Documents")
        SSOK_AddQuickFileDir(dirs, oneDriveConsumer . "\Documents")
        SSOK_AddQuickFileDir(dirs, oneDriveCommercial . "\Documents")
    }
    SSOK_AddQuickFileDir(dirs, A_ScriptDir)
    SSOK_QF_AddFolderListToDirs(dirs, SSOK_QF_SearchExtraFolders)

    return dirs
}

SSOK_QF_LoadFolderSettings(force := false)
{
    global SSOK_QF_FolderSettingsLoaded, SSOK_QF_SearchDesktop, SSOK_QF_SearchDownloads, SSOK_QF_SearchDocuments, SSOK_QF_SearchExtraFolders
    global SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    global SSOK_QF_ExtHwp, SSOK_QF_ExtXls, SSOK_QF_ExtDoc, SSOK_QF_ExtPpt, SSOK_QF_ExtTxt, SSOK_QF_ExtPdf
    if (SSOK_QF_FolderSettingsLoaded && !force)
        return

    SSOK_QF_SearchDesktop := 1
    SSOK_QF_SearchDownloads := 1
    SSOK_QF_SearchDocuments := 1
    SSOK_QF_SearchExtraFolders := ""
    SSOK_QF_SearchDriveD := 0
    SSOK_QF_SearchDriveE := 0
    SSOK_QF_SearchDriveF := 0
    SSOK_QF_ExtHwp := 1
    SSOK_QF_ExtXls := 1
    SSOK_QF_ExtDoc := 0
    SSOK_QF_ExtPpt := 0
    SSOK_QF_ExtTxt := 0
    SSOK_QF_ExtPdf := 1

    _ini := SSOK_IniFile
    if FileExist(_ini)
    {
        IniRead, _desktop, %_ini%, F5QuickFileFolders, Desktop, %SSOK_QF_SearchDesktop%
        IniRead, _downloads, %_ini%, F5QuickFileFolders, Downloads, %SSOK_QF_SearchDownloads%
        IniRead, _documents, %_ini%, F5QuickFileFolders, Documents, %SSOK_QF_SearchDocuments%
        IniRead, _extraFolders, %_ini%, F5QuickFileFolders, ExtraFolders, __SSOK_MISSING__
        SSOK_QF_SearchDesktop := SSOK_QF_NormalizeFolderOption(_desktop, 1)
        SSOK_QF_SearchDownloads := SSOK_QF_NormalizeFolderOption(_downloads, 1)
        SSOK_QF_SearchDocuments := SSOK_QF_NormalizeFolderOption(_documents, 1)
        if (_extraFolders != "__SSOK_MISSING__")
            SSOK_QF_SearchExtraFolders := SSOK_QF_NormalizeDriveRootFolderList(_extraFolders)
        SSOK_QF_UpdateDriveOptionsFromExtraFolders()

        IniRead, _extHwp, %_ini%, F5QuickFileExtensions, Hwp, %SSOK_QF_ExtHwp%
        IniRead, _extXls, %_ini%, F5QuickFileExtensions, Xls, %SSOK_QF_ExtXls%
        IniRead, _extDoc, %_ini%, F5QuickFileExtensions, Doc, %SSOK_QF_ExtDoc%
        IniRead, _extPpt, %_ini%, F5QuickFileExtensions, Ppt, %SSOK_QF_ExtPpt%
        IniRead, _extTxt, %_ini%, F5QuickFileExtensions, Txt, %SSOK_QF_ExtTxt%
        IniRead, _extPdf, %_ini%, F5QuickFileExtensions, Pdf, %SSOK_QF_ExtPdf%
        SSOK_QF_ExtHwp := SSOK_QF_NormalizeFolderOption(_extHwp, 1)
        SSOK_QF_ExtXls := SSOK_QF_NormalizeFolderOption(_extXls, 1)
        SSOK_QF_ExtDoc := SSOK_QF_NormalizeFolderOption(_extDoc, 0)
        SSOK_QF_ExtPpt := SSOK_QF_NormalizeFolderOption(_extPpt, 0)
        SSOK_QF_ExtTxt := SSOK_QF_NormalizeFolderOption(_extTxt, 0)
        SSOK_QF_ExtPdf := SSOK_QF_NormalizeFolderOption(_extPdf, 1)
    }

    SSOK_QF_UpdateDriveOptionsFromExtraFolders()
    SSOK_QF_FolderSettingsLoaded := 1
}

SSOK_QF_NormalizeFolderOption(value, defaultValue := 0)
{
    value := Trim(value)
    if (value = "" || value = "ERROR")
        return defaultValue
    valueLower := value
    StringLower, valueLower, valueLower
    if (value = "1" || valueLower = "true" || valueLower = "yes" || valueLower = "on")
        return 1
    return 0
}

SSOK_QF_SaveFolderSettingsFromGui()
{
    global SSOK_QF_FolderSettingsLoaded, SSOK_QF_SearchDesktop, SSOK_QF_SearchDownloads, SSOK_QF_SearchDocuments, SSOK_QF_SearchExtraFolders
    global SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    global SSOK_QF_ExtHwp, SSOK_QF_ExtXls, SSOK_QF_ExtDoc, SSOK_QF_ExtPpt, SSOK_QF_ExtTxt, SSOK_QF_ExtPdf
    Gui, SSOKQuickFile:Submit, NoHide
    SSOK_QF_SearchDesktop := SSOK_QF_NormalizeFolderOption(SSOK_QF_SearchDesktop, 0)
    SSOK_QF_SearchDownloads := SSOK_QF_NormalizeFolderOption(SSOK_QF_SearchDownloads, 0)
    SSOK_QF_SearchDocuments := SSOK_QF_NormalizeFolderOption(SSOK_QF_SearchDocuments, 0)
    SSOK_QF_SearchDriveD := SSOK_QF_NormalizeFolderOption(SSOK_QF_SearchDriveD, 0)
    SSOK_QF_SearchDriveE := SSOK_QF_NormalizeFolderOption(SSOK_QF_SearchDriveE, 0)
    SSOK_QF_SearchDriveF := SSOK_QF_NormalizeFolderOption(SSOK_QF_SearchDriveF, 0)
    SSOK_QF_EnsureSingleDriveOption()
    SSOK_QF_SearchExtraFolders := SSOK_QF_BuildDriveRootFolderListFromOptions()
    SSOK_QF_ExtHwp := SSOK_QF_NormalizeFolderOption(SSOK_QF_ExtHwp, 0)
    SSOK_QF_ExtXls := SSOK_QF_NormalizeFolderOption(SSOK_QF_ExtXls, 0)
    SSOK_QF_ExtDoc := SSOK_QF_NormalizeFolderOption(SSOK_QF_ExtDoc, 0)
    SSOK_QF_ExtPpt := SSOK_QF_NormalizeFolderOption(SSOK_QF_ExtPpt, 0)
    SSOK_QF_ExtTxt := SSOK_QF_NormalizeFolderOption(SSOK_QF_ExtTxt, 0)
    SSOK_QF_ExtPdf := SSOK_QF_NormalizeFolderOption(SSOK_QF_ExtPdf, 0)
    SSOK_QF_FolderSettingsLoaded := 1
    SSOK_SaveUnifiedIni()
}

SSOK_QF_SaveDriveOptionFromGui(selectedDrive)
{
    global SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    Gui, SSOKQuickFile:Submit, NoHide
    if (selectedDrive = "D" && SSOK_QF_SearchDriveD)
    {
        SSOK_QF_SearchDriveE := 0
        SSOK_QF_SearchDriveF := 0
    }
    else if (selectedDrive = "E" && SSOK_QF_SearchDriveE)
    {
        SSOK_QF_SearchDriveD := 0
        SSOK_QF_SearchDriveF := 0
    }
    else if (selectedDrive = "F" && SSOK_QF_SearchDriveF)
    {
        SSOK_QF_SearchDriveD := 0
        SSOK_QF_SearchDriveE := 0
    }
    GuiControl, SSOKQuickFile:, SSOK_QF_SearchDriveD, %SSOK_QF_SearchDriveD%
    GuiControl, SSOKQuickFile:, SSOK_QF_SearchDriveE, %SSOK_QF_SearchDriveE%
    GuiControl, SSOKQuickFile:, SSOK_QF_SearchDriveF, %SSOK_QF_SearchDriveF%
    SSOK_QF_SaveFolderSettingsFromGui()
}

SSOK_QF_UpdateDriveOptionsFromExtraFolders()
{
    global SSOK_QF_SearchExtraFolders, SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    _driveFolders := SSOK_QF_NormalizeDriveRootFolderList(SSOK_QF_SearchExtraFolders)
    SSOK_QF_SearchDriveD := SSOK_QF_PipeListHasValue(_driveFolders, "D:") ? 1 : 0
    SSOK_QF_SearchDriveE := (!SSOK_QF_SearchDriveD && SSOK_QF_PipeListHasValue(_driveFolders, "E:")) ? 1 : 0
    SSOK_QF_SearchDriveF := (!SSOK_QF_SearchDriveD && !SSOK_QF_SearchDriveE && SSOK_QF_PipeListHasValue(_driveFolders, "F:")) ? 1 : 0
    SSOK_QF_SearchExtraFolders := SSOK_QF_BuildDriveRootFolderListFromOptions()
}

SSOK_QF_EnsureSingleDriveOption()
{
    global SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    if (SSOK_QF_SearchDriveD)
    {
        SSOK_QF_SearchDriveE := 0
        SSOK_QF_SearchDriveF := 0
    }
    else if (SSOK_QF_SearchDriveE)
        SSOK_QF_SearchDriveF := 0
}

SSOK_QF_BuildDriveRootFolderListFromOptions()
{
    global SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    _folders := ""
    if (SSOK_QF_SearchDriveD)
        SSOK_QF_AddPipeListValue(_folders, "D:")
    else if (SSOK_QF_SearchDriveE)
        SSOK_QF_AddPipeListValue(_folders, "E:")
    else if (SSOK_QF_SearchDriveF)
        SSOK_QF_AddPipeListValue(_folders, "F:")
    return SSOK_QF_NormalizeDriveRootFolderList(_folders)
}

SSOK_QF_SelectOtherFolderFromGui()
{
    SSOK_QF_SaveFolderSettingsFromGui()
}

SSOK_QF_ClearOtherFolderFromGui()
{
    global SSOK_QF_SearchExtraFolders, SSOK_QF_FolderSettingsLoaded, SSOK_QF_SearchDriveD, SSOK_QF_SearchDriveE, SSOK_QF_SearchDriveF
    SSOK_QF_SearchExtraFolders := ""
    SSOK_QF_SearchDriveD := 0
    SSOK_QF_SearchDriveE := 0
    SSOK_QF_SearchDriveF := 0
    SSOK_QF_FolderSettingsLoaded := 1
    SSOK_SaveUnifiedIni()
}

SSOK_QF_GetExtraFolderLimit()
{
    return 3
}

SSOK_QF_GetFolderDialogStart()
{
    if (InStr(FileExist("D:"), "D"))
        return "D:"
    if (InStr(FileExist(A_Desktop), "D"))
        return A_Desktop
    if (InStr(FileExist(A_MyDocuments), "D"))
        return A_MyDocuments
    EnvGet, _userProfile, USERPROFILE
    if (InStr(FileExist(_userProfile), "D"))
        return _userProfile
    return "C:"
}

SSOK_QF_BringFolderDialogToFront()
{
    _id := SSOK_QF_FindFolderDialogWindow()
    if (!_id)
        return
    WinSet, AlwaysOnTop, On, ahk_id %_id%
    WinActivate, ahk_id %_id%
}

SSOK_QF_FindFolderDialogWindow()
{
    WinGet, _id, ID, °Ë»öÇÒ Æú´õ¸¦ ¼±ÅÃÇÏ¼¼¿ä ahk_class #32770
    if (_id)
        return _id
    WinGet, _id, ID, Æú´õ Ã£¾Æº¸±â ahk_class #32770
    if (_id)
        return _id
    WinGet, _id, ID, Browse For Folder ahk_class #32770
    return _id
}

SSOK_QF_NormalizeFolderList(folderList)
{
    if (SSOK_QF_FindEverythingExe() = "")
        return SSOK_QF_NormalizeDriveRootFolderList(folderList)

    _out := ""
    _count := 0
    _limit := SSOK_QF_GetExtraFolderLimit()
    Loop, Parse, folderList, |
    {
        _folder := SSOK_QF_NormalizeFolderPath(A_LoopField)
        if (_folder != "" && !SSOK_QF_IsBlockedSearchRoot(_folder))
        {
            _before := _out
            SSOK_QF_AddPipeListValue(_out, _folder)
            if (_out != _before)
                _count++
            if (_count >= _limit)
                break
        }
    }
    return _out
}

SSOK_QF_NormalizeDriveRootFolderList(folderList)
{
    _out := ""
    Loop, Parse, folderList, |
    {
        _folder := SSOK_QF_GetAllowedExtraDriveRoot(A_LoopField)
        if (_folder != "")
            SSOK_QF_AddPipeListValue(_out, _folder)
    }
    return _out
}

SSOK_QF_GetAllowedExtraDriveRoot(path)
{
    path := Trim(path, " `t`r`n|")
    if !RegExMatch(path, "i)^([D-F]):", _m)
        return ""
    _letter := _m1
    StringUpper, _letter, _letter
    _root := _letter . ":"
    if InStr(FileExist(_root), "D")
        return _root
    return ""
}

SSOK_QF_NormalizeFolderPath(path)
{
    path := Trim(path, " `t`r`n|")
    if (path = "" || !InStr(FileExist(path), "D"))
        return ""
    if RegExMatch(path, "i)^([A-Z]):\\?$", _m)
    {
        _letter := _m1
        StringUpper, _letter, _letter
        return _letter . ":"
    }
    path := RegExReplace(path, "\\+$")
    return path
}
SSOK_QF_IsDriveRoot(path)
{
    path := Trim(path, " `t`r`n|")
    path := RegExReplace(path, "\\+$")
    return RegExMatch(path, "i)^[A-Z]:$")
}

SSOK_QF_IsBlockedSearchRoot(path)
{
    path := Trim(path, " `t`r`n|")
    path := RegExReplace(path, "\\+$")
    return RegExMatch(path, "i)^C:$")
}
SSOK_QF_CountPipeItems(list)
{
    _count := 0
    Loop, Parse, list, |
    {
        if (Trim(A_LoopField) != "")
            _count++
    }
    return _count
}

SSOK_QF_PipeListHasValue(list, value)
{
    value := Trim(value, " `t`r`n|")
    valueCmp := value
    StringLower, valueCmp, valueCmp
    Loop, Parse, list, |
    {
        existing := Trim(A_LoopField, " `t`r`n|")
        existingCmp := existing
        StringLower, existingCmp, existingCmp
        if (existingCmp = valueCmp)
            return true
    }
    return false
}

SSOK_QF_FormatFolderListForDisplay(folderList)
{
    folderList := SSOK_QF_NormalizeFolderList(folderList)
    return StrReplace(folderList, "|", " | ")
}

SSOK_QF_AddPipeListValue(ByRef list, value)
{
    value := Trim(value, " `t`r`n|")
    if (value = "")
        return
    valueCmp := value
    StringLower, valueCmp, valueCmp
    Loop, Parse, list, |
    {
        existing := Trim(A_LoopField)
        existingCmp := existing
        StringLower, existingCmp, existingCmp
        if (existingCmp = valueCmp)
            return
    }
    if (list = "")
        list := value
    else
        list .= "|" . value
}

SSOK_QF_AddFolderListToDirs(ByRef dirs, folderList)
{
    Loop, Parse, folderList, |
    {
        _folder := SSOK_QF_NormalizeFolderPath(A_LoopField)
        if (_folder != "" && !SSOK_QF_IsBlockedSearchRoot(_folder))
            SSOK_AddQuickFileDir(dirs, _folder)
    }
}
SSOK_GetQuickFileExtensions()
{
    global SSOK_QF_ExtHwp, SSOK_QF_ExtXls, SSOK_QF_ExtDoc, SSOK_QF_ExtPpt, SSOK_QF_ExtTxt, SSOK_QF_ExtPdf
    SSOK_QF_LoadFolderSettings()
    exts := []
    if (SSOK_QF_ExtHwp)
    {
        exts.Push("hwp")
        exts.Push("hwpx")
    }
    if (SSOK_QF_ExtXls)
    {
        exts.Push("xls")
        exts.Push("xlsx")
    }
    if (SSOK_QF_ExtDoc)
    {
        exts.Push("doc")
        exts.Push("docx")
    }
    if (SSOK_QF_ExtPpt)
    {
        exts.Push("ppt")
        exts.Push("pptx")
    }
    if (SSOK_QF_ExtTxt)
        exts.Push("txt")
    if (SSOK_QF_ExtPdf)
        exts.Push("pdf")
    return exts
}
SSOK_AddQuickFileDir(ByRef dirs, path)
{
    path := Trim(path, " `t`r`n")
    if (path = "" || !InStr(FileExist(path), "D"))
        return

    ; ³¡ÀÇ ¿ª½½·¡½Ã´Â ºñ±³¿ëÀ¸·Î¸¸ Á¦°ÅÇØ Áßº¹ °Ë»öÀ» ¸·½À´Ï´Ù.
    path := RegExReplace(path, "\\+$")
    pathCmp := path
    StringLower, pathCmp, pathCmp

    for idx, existing in dirs
    {
        existingCmp := existing
        StringLower, existingCmp, existingCmp
        if (existingCmp = pathCmp)
            return
    }

    dirs.Push(path)
}

SSOK_GetShellFolderPath(folderSpec)
{
    try
    {
        shell := ComObjCreate("Shell.Application")
        folder := shell.Namespace(folderSpec)
        if IsObject(folder)
        {
            self := folder.Self
            if IsObject(self)
                return self.Path
        }
    }
    catch e
    {
    }

    return ""
}

SSOK_ShowCopyFileNotice(keyword := "")
{
    keyword := Trim(keyword)
    if (keyword != "")
    {
        MsgBox, 262192, SSOK ¾È³», %keyword% ÆÄÀÏÀÌ ¾ø½À´Ï´Ù.`n¼³Á¤ÇÑ °Ë»ö Æú´õ ¾È¿¡ ³Ö¾îÁÖ¼¼¿ä.`n`n°Ë»ö Æú´õ´Â ÀÚÁÖ ¿©´Â ÆÄÀÏ Ã¢¿¡¼­ Ã¼Å©ÇÒ ¼ö ÀÖ½À´Ï´Ù.
    }
    else
    {
        MsgBox, 262192, SSOK ¾È³», °Ë»ö¾î°¡ ¾ø½À´Ï´Ù.`nÅ°¿öµå¸¦ ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
    }
}
SSOK_ClearCopyFileNotice:
    ToolTip
    Gui, SSOKFileNotice:Destroy
return

SSOK_BrowserCandidates()
{
    return ["chrome.exe", "msedge.exe", "whale.exe", "firefox.exe"]
}

SSOK_IsKnownBrowserProcess(proc)
{
    StringLower, proc, proc
    for _, exe in SSOK_BrowserCandidates()
    {
        if (proc = exe)
            return true
    }
    return RegExMatch(proc, "i)^(chrome|msedge|firefox|whale|iexplore|brave|vivaldi|opera|opera_gx)\.exe$")
}

SSOK_OpenUrlPreferred(url)
{
    Run, %url%,, UseErrorLevel
    if (ErrorLevel)
        return ""

    Sleep, 300
    WinGet, proc, ProcessName, A
    StringLower, proc, proc
    if (SSOK_IsKnownBrowserProcess(proc))
        return proc

    return "default"
}

; =========================================================
; Win + F6 : ÀÚÁÖ°¡´Â »çÀÌÆ®
; - ¸íÄª°ú ÁÖ¼Ò¸¦ 1~12 °¢ ÁÙ¿¡¼­ Á÷Á¢ ¼öÁ¤ °¡´É
; - Å° 1~9, 0¹ø ¶Ç´Â ÀúÀå&¿­±â·Î Windows ±âº» ºê¶ó¿ìÀú ½ÇÇà
; - Chrome/Edge °íÁ¤ ¾øÀÌ »ç¿ëÀÚ°¡ Á¤ÇÑ ±âº» ºê¶ó¿ìÀú¸¦ µû¸§
; =========================================================

SSOK_ShowQuickUrlMenu:
    Gosub, SSOK_QU_LoadUrls
    SSOK_QU_LoadEduRegionPrefs()

    Gui, SSOKQuickUrl:Destroy
    Gui, SSOKQuickUrl:+AlwaysOnTop +ToolWindow -MinimizeBox
    Gui, SSOKQuickUrl:Color, F7FBFF
    Gui, SSOKQuickUrl:Font, s17 bold, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x20 y16 w640 h34 c005BAC Center, ÀÚÁÖ°¡´Â »çÀÌÆ® URL ¹Ù·Î ¿­±â
    Gui, SSOKQuickUrl:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x20 y52 w640 h20 c555555 Center, ¼ýÀÚ 1~9¹øÅ°¿Í [ÀúÀå&&¿­±â]·Î ¹Ù·Î°¡±â, 10~12¹øÀº ¹öÆ°À¸·Î ½ÇÇà

    Gui, SSOKQuickUrl:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x50 y78 w150 h20 c005BAC Center, ÀÌ¸§
    Gui, SSOKQuickUrl:Add, Text, x205 y78 w335 h20 c005BAC Center, ÁÖ¼Ò

    Gui, SSOKQuickUrl:Font, s10 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x20 y104 w24 h24 c005BAC Center, 1
    Gui, SSOKQuickUrl:Add, Edit, x50 y100 w150 h28 vSSOK_QU_NameEdit1, %SSOK_QU_Name1%
    Gui, SSOKQuickUrl:Add, Edit, x205 y100 w335 h28 vSSOK_QU_Edit1, %SSOK_QU_Url1%
    Gui, SSOKQuickUrl:Add, Button, x545 y99 w95 h30 gSSOK_QU_Open1, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y138 w24 h24 c005BAC Center, 2
    Gui, SSOKQuickUrl:Add, Edit, x50 y134 w150 h28 vSSOK_QU_NameEdit2, %SSOK_QU_Name2%
    Gui, SSOKQuickUrl:Add, Edit, x205 y134 w335 h28 vSSOK_QU_Edit2, %SSOK_QU_Url2%
    Gui, SSOKQuickUrl:Add, Button, x545 y133 w95 h30 gSSOK_QU_Open2, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y172 w24 h24 c005BAC Center, 3
    Gui, SSOKQuickUrl:Add, Edit, x50 y168 w150 h28 vSSOK_QU_NameEdit3, %SSOK_QU_Name3%
    Gui, SSOKQuickUrl:Add, Edit, x205 y168 w335 h28 vSSOK_QU_Edit3, %SSOK_QU_Url3%
    Gui, SSOKQuickUrl:Add, Button, x545 y167 w95 h30 gSSOK_QU_Open3, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y206 w24 h24 c005BAC Center, 4
    Gui, SSOKQuickUrl:Add, Edit, x50 y202 w150 h28 vSSOK_QU_NameEdit4, %SSOK_QU_Name4%
    Gui, SSOKQuickUrl:Add, Edit, x205 y202 w335 h28 vSSOK_QU_Edit4, %SSOK_QU_Url4%
    Gui, SSOKQuickUrl:Add, Button, x545 y201 w95 h30 gSSOK_QU_Open4, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y240 w24 h24 c005BAC Center, 5
    Gui, SSOKQuickUrl:Add, Edit, x50 y236 w150 h28 vSSOK_QU_NameEdit5, %SSOK_QU_Name5%
    Gui, SSOKQuickUrl:Add, Edit, x205 y236 w335 h28 vSSOK_QU_Edit5, %SSOK_QU_Url5%
    Gui, SSOKQuickUrl:Add, Button, x545 y235 w95 h30 gSSOK_QU_Open5, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y274 w24 h24 c005BAC Center, 6
    Gui, SSOKQuickUrl:Add, Edit, x50 y270 w150 h28 vSSOK_QU_NameEdit6, %SSOK_QU_Name6%
    Gui, SSOKQuickUrl:Add, Edit, x205 y270 w335 h28 vSSOK_QU_Edit6, %SSOK_QU_Url6%
    Gui, SSOKQuickUrl:Add, Button, x545 y269 w95 h30 gSSOK_QU_Open6, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y308 w24 h24 c005BAC Center, 7
    Gui, SSOKQuickUrl:Add, Edit, x50 y304 w150 h28 vSSOK_QU_NameEdit7, %SSOK_QU_Name7%
    Gui, SSOKQuickUrl:Add, Edit, x205 y304 w335 h28 vSSOK_QU_Edit7, %SSOK_QU_Url7%
    Gui, SSOKQuickUrl:Add, Button, x545 y303 w95 h30 gSSOK_QU_Open7, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y342 w24 h24 c005BAC Center, 8
    Gui, SSOKQuickUrl:Add, Edit, x50 y338 w150 h28 vSSOK_QU_NameEdit8, %SSOK_QU_Name8%
    Gui, SSOKQuickUrl:Add, Edit, x205 y338 w335 h28 vSSOK_QU_Edit8, %SSOK_QU_Url8%
    Gui, SSOKQuickUrl:Add, Button, x545 y337 w95 h30 gSSOK_QU_Open8, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y376 w24 h24 c005BAC Center, 9
    Gui, SSOKQuickUrl:Add, Edit, x50 y372 w150 h28 vSSOK_QU_NameEdit9, %SSOK_QU_Name9%
    Gui, SSOKQuickUrl:Add, Edit, x205 y372 w335 h28 vSSOK_QU_Edit9, %SSOK_QU_Url9%
    Gui, SSOKQuickUrl:Add, Button, x545 y371 w95 h30 gSSOK_QU_Open9, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y410 w24 h24 c005BAC Center, 10
    Gui, SSOKQuickUrl:Add, Edit, x50 y406 w150 h28 vSSOK_QU_NameEdit10, %SSOK_QU_Name10%
    Gui, SSOKQuickUrl:Add, Edit, x205 y406 w335 h28 vSSOK_QU_Edit10, %SSOK_QU_Url10%
    Gui, SSOKQuickUrl:Add, Button, x545 y405 w95 h30 gSSOK_QU_Open10, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y444 w24 h24 c005BAC Center, 11
    Gui, SSOKQuickUrl:Add, Edit, x50 y440 w150 h28 vSSOK_QU_NameEdit11, %SSOK_QU_Name11%
    Gui, SSOKQuickUrl:Add, Edit, x205 y440 w335 h28 vSSOK_QU_Edit11, %SSOK_QU_Url11%
    Gui, SSOKQuickUrl:Add, Button, x545 y439 w95 h30 gSSOK_QU_Open11, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x20 y478 w24 h24 c005BAC Center, 12
    Gui, SSOKQuickUrl:Add, Edit, x50 y474 w150 h28 vSSOK_QU_NameEdit12, %SSOK_QU_Name12%
    Gui, SSOKQuickUrl:Add, Edit, x205 y474 w335 h28 vSSOK_QU_Edit12, %SSOK_QU_Url12%
    Gui, SSOKQuickUrl:Add, Button, x545 y473 w95 h30 gSSOK_QU_Open12, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Button, x500 y520 w140 h30 gSSOK_QU_SaveAll, ÀüÃ¼ ÀúÀå

    ; ±³À°Ã»º° ¾÷¹«½Ã½ºÅÛ ¹Ù·Î°¡±â
    ; À§ Á¦¸ñÀ» ´©¸£¸é ¾Æ·¡¿¡ ÀúÀåµÈ Áö¿ªÀÇ »çÀÌÆ®°¡ ¹Ù·Î ¿­¸³´Ï´Ù.
    SSOK_QU_EduRegionListAll := "¼­¿ï|´ëÀü|´ë±¸|ºÎ»ê|±¤ÁÖ|¿ï»ê|ÀÎÃµ|°æ±â|°æºÏ|°æ³²|ÀüºÏ|Àü³²|Ãæ³²|ÃæºÏ|°­¿ø|Á¦ÁÖ|¼¼Á¾"
    SSOK_QU_EduRegionListSupport := "¼­¿ï|´ëÀü|´ë±¸|ºÎ»ê|±¤ÁÖ|¿ï»ê|ÀÎÃµ|°æ±â|°æºÏ|°æ³²|ÀüºÏ|Àü³²|Ãæ³²|ÃæºÏ|°­¿ø|Á¦ÁÖ|¼¼Á¾"

    Gui, SSOKQuickUrl:Font, s9 bold underline c4F6F8F, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x20  y558 w110 h20 Center +0x200 gSSOK_QU_EduOpenPortal, ¾÷¹«Æ÷ÅÐ
    Gui, SSOKQuickUrl:Add, Text, x140 y558 w110 h20 Center +0x200 gSSOK_QU_EduOpenKEdufine, K¿¡µàÆÄÀÎ
    Gui, SSOKQuickUrl:Add, Text, x260 y558 w110 h20 Center +0x200 gSSOK_QU_EduOpenNeis, ³ªÀÌ½º
    Gui, SSOKQuickUrl:Add, Text, x380 y558 w110 h20 Center +0x200 gSSOK_QU_EduOpenSupport, ¾÷¹«Áö¿ø
    Gui, SSOKQuickUrl:Add, Text, x500 y558 w110 h20 Center +0x200 gSSOK_QU_EduOpenEVPN, EVPN

    Gui, SSOKQuickUrl:Font, s8 norm c000000, Malgun Gothic
    Gui, SSOKQuickUrl:Add, DropDownList, x20  y579 w110 r12 vSSOK_QU_EduRegionPortal, %SSOK_QU_EduRegionListAll%
    Gui, SSOKQuickUrl:Add, DropDownList, x140 y579 w110 r12 vSSOK_QU_EduRegionKEdufine, %SSOK_QU_EduRegionListAll%
    Gui, SSOKQuickUrl:Add, DropDownList, x260 y579 w110 r12 vSSOK_QU_EduRegionNeis, %SSOK_QU_EduRegionListAll%
    Gui, SSOKQuickUrl:Add, DropDownList, x380 y579 w110 r12 vSSOK_QU_EduRegionSupport, %SSOK_QU_EduRegionListSupport%
    Gui, SSOKQuickUrl:Add, DropDownList, x500 y579 w110 r12 vSSOK_QU_EduRegionEVPN, %SSOK_QU_EduRegionListAll%
    GuiControl, SSOKQuickUrl:ChooseString, SSOK_QU_EduRegionPortal, %SSOK_QU_EduRegionPortal%
    GuiControl, SSOKQuickUrl:ChooseString, SSOK_QU_EduRegionKEdufine, %SSOK_QU_EduRegionKEdufine%
    GuiControl, SSOKQuickUrl:ChooseString, SSOK_QU_EduRegionNeis, %SSOK_QU_EduRegionNeis%
    GuiControl, SSOKQuickUrl:ChooseString, SSOK_QU_EduRegionSupport, %SSOK_QU_EduRegionSupport%
    GuiControl, SSOKQuickUrl:ChooseString, SSOK_QU_EduRegionEVPN, %SSOK_QU_EduRegionEVPN%
    Gui, SSOKQuickUrl:Add, Button, x615 y578 w45 h25 gSSOK_QU_EduSave, ÀúÀå

    ; ÇÏ´Ü ±âÁ¸ ¸µÅ©´Â ÇÑ ÁÙ·Î À¯Áö
    ; ¼¼Á¾ °ü³» ÇÐ±³¸¸ ±âÁ¸ s5 ´ëºñ ¾à 30% Å©°Ô Ç¥½Ã
    Gui, SSOKQuickUrl:Font, s6.5 bold underline c6F7F8F, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x5   y621 w95  h18 Center +0x200 gSSOK_QU_OpenSchoolSearchFromMenu, [¼¼Á¾ °ü³» ÇÐ±³]
    Gui, SSOKQuickUrl:Add, Text, x100 y621 w75  h18 Center +0x200 gSSOK_QU_OpenSchoolInfoFromMenu, [ÇÐ±³¾Ë¸®¹Ì1]
    Gui, SSOKQuickUrl:Add, Text, x175 y621 w75  h18 Center +0x200 gSSOK_QU_OpenSchoolInfo2FromMenu, [ÇÐ±³¾Ë¸®¹Ì2]
    Gui, SSOKQuickUrl:Add, Text, x250 y621 w110 h18 Center +0x200 gSSOK_QU_OpenLocalFinanceInfoFromMenu, [Áö¹æ±³À°ÀçÁ¤ ¾Ë¸®¹Ì]
    Gui, SSOKQuickUrl:Add, Text, x360 y621 w100 h18 Center +0x200 gSSOK_QU_OpenEduOfficeSearchFromMenu, [±³À°Ã» ¾÷¹«´ã´ç]
    Gui, SSOKQuickUrl:Add, Text, x460 y621 w120 h18 Center +0x200 gSSOK_QU_OpenSchoolSupportInfoFromMenu, [ÇÐ±³Áö¿øº»ºÎ ¾÷¹«¾È³»]
    Gui, SSOKQuickUrl:Add, Text, x580 y621 w95  h18 Center +0x200 gSSOK_QU_OpenContractInfoFromMenu, [°Å·¡Ã³ °è¾àÁ¤º¸]

    Gui, SSOKQuickUrl:Font, s7 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x20 y666 w400 h18 c999999, ¼ýÀÚ 1~9¹øÅ° ¶Ç´Â [ÀúÀå&¿­±â]·Î ¹Ù·Î°¡±â
    Gui, SSOKQuickUrl:Add, Text, x430 y682 w225 h18 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£
    SSOK_GetSidebarAttachedGuiPos(680, 695, SSOK_QU_WinX, SSOK_QU_WinY)
    Gui, SSOKQuickUrl:Show, x%SSOK_QU_WinX% y%SSOK_QU_WinY% w680 h695, SSOK ÀÚÁÖ°¡´Â »çÀÌÆ®
return
SSOKQuickUrlGuiEscape:
SSOKQuickUrlGuiClose:
    Gui, SSOKQuickUrl:Destroy
return

SSOK_QU_EduOpenPortal:
    SSOK_QU_OpenEduShortcut("portal")
return

SSOK_QU_EduOpenKEdufine:
    SSOK_QU_OpenEduShortcut("kedufine")
return

SSOK_QU_EduOpenNeis:
    SSOK_QU_OpenEduShortcut("neis")
return

SSOK_QU_EduOpenSupport:
    SSOK_QU_OpenEduShortcut("support")
return

SSOK_QU_EduOpenEVPN:
    SSOK_QU_OpenEduShortcut("evpn")
return

SSOK_QU_EduSave:
    SSOK_QU_SaveEduRegionPrefs()
    ToolTip, ±³À°Ã» ¹Ù·Î°¡±â Áö¿ªÀ» ÀúÀåÇß½À´Ï´Ù.
    SetTimer, SSOK_QU_EduClearToolTip, -1200
return

SSOK_QU_EduClearToolTip:
    ToolTip
return

SSOK_QU_LoadEduRegionPrefs()
{
    global SSOK_IniFile
    global SSOK_QU_EduRegionPortal, SSOK_QU_EduRegionKEdufine, SSOK_QU_EduRegionNeis, SSOK_QU_EduRegionSupport, SSOK_QU_EduRegionEVPN

    SSOK_QU_EduRegionPortal := "¼¼Á¾"
    SSOK_QU_EduRegionKEdufine := "¼¼Á¾"
    SSOK_QU_EduRegionNeis := "¼¼Á¾"
    SSOK_QU_EduRegionSupport := "¼¼Á¾"
    SSOK_QU_EduRegionEVPN := "¼¼Á¾"

    if !FileExist(SSOK_IniFile)
        return

    IniRead, _r1, %SSOK_IniFile%, EduQuickLinks, WorkPortal, ¼¼Á¾
    IniRead, _r2, %SSOK_IniFile%, EduQuickLinks, KEdufine, ¼¼Á¾
    IniRead, _r3, %SSOK_IniFile%, EduQuickLinks, Neis, ¼¼Á¾
    IniRead, _r4, %SSOK_IniFile%, EduQuickLinks, Support, ¼¼Á¾
    IniRead, _r5, %SSOK_IniFile%, EduQuickLinks, EVPN, ¼¼Á¾
    if (Trim(_r1) != "")
        SSOK_QU_EduRegionPortal := _r1
    if (Trim(_r2) != "")
        SSOK_QU_EduRegionKEdufine := _r2
    if (Trim(_r3) != "")
        SSOK_QU_EduRegionNeis := _r3
    if (Trim(_r4) != "")
        SSOK_QU_EduRegionSupport := _r4
    if (Trim(_r5) != "")
        SSOK_QU_EduRegionEVPN := _r5
}

SSOK_QU_SaveEduRegionPrefs()
{
    global SSOK_QU_EduRegionPortal, SSOK_QU_EduRegionKEdufine, SSOK_QU_EduRegionNeis, SSOK_QU_EduRegionSupport, SSOK_QU_EduRegionEVPN

    Gui, SSOKQuickUrl:Submit, NoHide
    if (Trim(SSOK_QU_EduRegionPortal) = "")
        SSOK_QU_EduRegionPortal := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionKEdufine) = "")
        SSOK_QU_EduRegionKEdufine := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionNeis) = "")
        SSOK_QU_EduRegionNeis := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionSupport) = "")
        SSOK_QU_EduRegionSupport := "¼¼Á¾"
    if (Trim(SSOK_QU_EduRegionEVPN) = "")
        SSOK_QU_EduRegionEVPN := "¼¼Á¾"
    SSOK_SaveUnifiedIni()
}

SSOK_QU_OpenEduShortcut(kind)
{
    global SSOK_QU_EduRegionPortal, SSOK_QU_EduRegionKEdufine, SSOK_QU_EduRegionNeis, SSOK_QU_EduRegionSupport, SSOK_QU_EduRegionEVPN

    Gui, SSOKQuickUrl:Submit, NoHide
    if (kind = "portal")
        region := SSOK_QU_EduRegionPortal
    else if (kind = "kedufine")
        region := SSOK_QU_EduRegionKEdufine
    else if (kind = "neis")
        region := SSOK_QU_EduRegionNeis
    else if (kind = "support")
        region := SSOK_QU_EduRegionSupport
    else if (kind = "evpn")
        region := SSOK_QU_EduRegionEVPN
    else
        return

    url := SSOK_QU_GetEduShortcutUrl(kind, region)
    if (url = "")
    {
        MsgBox, 48, SSOK ¾È³», %region% ±³À°Ã»ÀÇ ÇØ´ç ¹Ù·Î°¡±â ÁÖ¼Ò°¡ µî·ÏµÇ¾î ÀÖÁö ¾Ê½À´Ï´Ù.
        return
    }

    ; ¼±ÅÃÇÑ Áö¿ªÀ¸·Î ½ÇÁ¦ ÀÌµ¿ÇÏ¸é ÇöÀç 5°³ ¼±ÅÃ°ªÀ» Áï½Ã ÀúÀåÇÕ´Ï´Ù.
    ; µû¶ó¼­ º°µµ [ÀúÀå]À» ´©¸£Áö ¾Ê¾Æµµ ´ÙÀ½ ½ÇÇà ¶§ ¸¶Áö¸· ¼±ÅÃ Áö¿ªÀÌ À¯ÁöµË´Ï´Ù.
    SSOK_SaveUnifiedIni()

    Gui, SSOKQuickUrl:Destroy
    SSOK_OpenUrlPreferred(url)
}

SSOK_QU_GetEduShortcutUrl(kind, region)
{
    code := SSOK_QU_GetEduRegionCode(region)
    if (kind = "portal")
        return (code = "" ? "" : "https://" . code . ".eduptl.kr")
    if (kind = "neis")
        return (code = "" ? "" : "https://" . code . ".neis.go.kr")
    if (kind = "kedufine")
        return (code = "" ? "" : "https://klef." . code . ".go.kr")
    if (kind = "evpn")
    {
        if (region = "°æºÏ")
            return "https://evpn.gbe.kr"
        return (code = "" ? "" : "https://evpn." . code . ".go.kr")
    }
    if (kind = "support")
        return SSOK_QU_GetEduSupportUrl(region)
    return ""
}

SSOK_QU_GetEduRegionCode(region)
{
    if (region = "°­¿ø")
        return "kwe"
    if (region = "°æ±â")
        return "goe"
    if (region = "°æ³²")
        return "gne"
    if (region = "°æºÏ")
        return "gbe"
    if (region = "±¤ÁÖ")
        return "gen"
    if (region = "´ë±¸")
        return "dge"
    if (region = "´ëÀü")
        return "dje"
    if (region = "ºÎ»ê")
        return "pen"
    if (region = "¼­¿ï")
        return "sen"
    if (region = "¼¼Á¾")
        return "sje"
    if (region = "¿ï»ê")
        return "use"
    if (region = "ÀÎÃµ")
        return "ice"
    if (region = "Àü³²")
        return "jne"
    if (region = "ÀüºÏ")
        return "jbe"
    if (region = "Á¦ÁÖ")
        return "jje"
    if (region = "Ãæ³²")
        return "cne"
    if (region = "ÃæºÏ")
        return "cbe"
    return ""
}

SSOK_QU_GetEduSupportUrl(region)
{
    if (region = "¼­¿ï")
        return "https://baro.sen.go.kr/"
    if (region = "´ëÀü")
        return "https://www.dje.go.kr/boardCnts/list.do?boardID=10375&m=030609&s=dje"
    if (region = "´ë±¸")
        return "https://www.dge.go.kr/defsc/main.do"
    if (region = "ºÎ»ê")
        return "https://bsss.pen.go.kr/"
    if (region = "±¤ÁÖ")
        return "https://www.gen.go.kr/xmanual/main/main.php#section-0"
    if (region = "¿ï»ê")
        return "https://use.go.kr/user/bbs/BD_selectBbsList.do?q_bbsSn=1925"
    if (region = "ÀÎÃµ")
        return "https://edus.ice.go.kr/"
    if (region = "°æ±â")
        return "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?mi=10554&cntntsId=1465"
    if (region = "°æºÏ")
        return "https://www.gbe.kr/edupia/main.do#freLinkPopup"
    if (region = "°æ³²")
        return "https://www.gne.go.kr/helpschool/index.do"
    if (region = "ÀüºÏ")
        return "https://www.jbe.go.kr/support/index.jbe"
    if (region = "Àü³²")
        return "https://www.jge.go.kr/jgemain/na/ntt/selectNttList.do?mi=2346&bbsId=1096"
    if (region = "Ãæ³²")
        return "http://www.cne.go.kr/manual/main.do"
    if (region = "ÃæºÏ")
        return "https://www.cbe.go.kr/baro/main.do"
    if (region = "°­¿ø")
        return "https://www.gwe.go.kr/main/bbs/list.do?key=bTIzMDcyMTExOTg1NTA="
    if (region = "Á¦ÁÖ")
        return "https://www.jje.go.kr/support/board/list.jje?boardId=BBS_0000261&menuCd=DOM_000001404001000000&contentsSid=732&cpath=%2Fsupport"
    if (region = "¼¼Á¾")
        return "https://www.sje.go.kr/sje/na/ntt/selectNttList.do?mi=52164&bbsId=982"
    return ""
}

#IfWinActive, SSOK ÀÚÁÖ°¡´Â »çÀÌÆ®
1::SSOK_QU_HotkeyOpen(1)
2::SSOK_QU_HotkeyOpen(2)
3::SSOK_QU_HotkeyOpen(3)
4::SSOK_QU_HotkeyOpen(4)
5::SSOK_QU_HotkeyOpen(5)
6::SSOK_QU_HotkeyOpen(6)
7::SSOK_QU_HotkeyOpen(7)
8::SSOK_QU_HotkeyOpen(8)
9::SSOK_QU_HotkeyOpen(9)
0::SSOK_QU_HotkeyOpen(10, "0")
Numpad1::SSOK_QU_HotkeyOpen(1)
Numpad2::SSOK_QU_HotkeyOpen(2)
Numpad3::SSOK_QU_HotkeyOpen(3)
Numpad4::SSOK_QU_HotkeyOpen(4)
Numpad5::SSOK_QU_HotkeyOpen(5)
Numpad6::SSOK_QU_HotkeyOpen(6)
Numpad7::SSOK_QU_HotkeyOpen(7)
Numpad8::SSOK_QU_HotkeyOpen(8)
Numpad9::SSOK_QU_HotkeyOpen(9)
Numpad0::SSOK_QU_HotkeyOpen(10, "0")
#IfWinActive

SSOK_QU_HotkeyOpen(index, typedKey := "")
{
    ControlGetFocus, focusedCtrl, SSOK ÀÚÁÖ°¡´Â »çÀÌÆ®
    if InStr(focusedCtrl, "Edit")
    {
        if (typedKey = "")
            typedKey := index
        SendInput, %typedKey%
        return
    }
    SSOK_QU_OpenIndex(index)
}

SSOK_QU_SetDefaults:
    Loop, 12
    {
        idx := A_Index
        SSOK_QU_GetDefault(idx, defaultName, defaultUrl)
        SSOK_QU_Name%idx% := defaultName
        SSOK_QU_Url%idx% := defaultUrl
    }
return

SSOK_QU_GetDefault(index, ByRef defaultName, ByRef defaultUrl)
{
    defaultName := "»çÀÌÆ®" . index
    defaultUrl := ""

    if (index = 1)
    {
        defaultName := "K-¿¡µàÆÄÀÎ"
        defaultUrl := "https://sje.eduptl.kr/bpm_lgn_lg00_001.do?noEpSession"
    }
    else if (index = 2)
    {
        defaultName := "°øÁ÷ÀÚ¸ÞÀÏ"
        defaultUrl := "https://mail.korea.kr/"
    }
    else if (index = 3)
    {
        defaultName := "³óÇùÀºÇà"
        defaultUrl := "https://ibz.nonghyup.com/"
    }
    else if (index = 4)
    {
        defaultName := "Á¶´Þ¼îÇÎ¸ô"
        defaultUrl := "https://shop.g2b.go.kr/"
    }
    else if (index = 5)
    {
        defaultName := "S2B ÇÐ±³ÀåÅÍ"
        defaultUrl := "https://www.s2b.kr/"
    }
    else if (index = 6)
    {
        defaultName := "¹ý·ÉÁ¤º¸"
        defaultUrl := "https://www.law.go.kr/"
    }
    else if (index = 7)
    {
        defaultName := "¼¼Á¾±³À°Ã»"
        defaultUrl := "https://www.sje.go.kr/"
    }
    else if (index = 8)
    {
        defaultName := "³ªÀÌ½º´ë±¹¹Î¼­ºñ½º"
        defaultUrl := "https://www.neis.go.kr/"
    }
    else if (index = 9)
    {
        defaultName := "±³À°Åë°è¼­ºñ½º"
        defaultUrl := "https://kess.kedi.re.kr/"
    }
    else if (index = 10)
    {
        defaultName := "GAI ±³Çà AI Çãºê"
        defaultUrl := "https://gaihub.net/programs"
    }
    else if (index = 11)
    {
        defaultName := "¼¼Á¾½Ã±³À°Ã»¿¬¼ö¿ø"
        defaultUrl := "https://www.sjti.kr/"
    }
    else if (index = 12)
    {
        defaultName := "±³À°½Ã¼³ÅëÇÕÁ¤º¸¸Á"
        defaultUrl := "https://work.keiis.kr/keiis/index.do"
    }
}

SSOK_QU_IsOldPlaceholderName(index, name)
{
    return (Trim(name) = "»çÀÌÆ®" . index)
}
return

SSOK_QU_LoadUrls:
    Gosub, SSOK_QU_SetDefaults
    SSOK_QU_Ini := SSOK_IniFile
    if !FileExist(SSOK_QU_Ini)
    {
        Gosub, SSOK_QU_SaveIni
        return
    }
    Loop, 12
    {
        idx := A_Index
        defaultName := SSOK_QU_Name%idx%
        defaultUrl := SSOK_QU_Url%idx%
        IniRead, readName, %SSOK_QU_Ini%, F6QuickUrls, Name%idx%, %defaultName%
        IniRead, readUrl, %SSOK_QU_Ini%, F6QuickUrls, Url%idx%, %defaultUrl%
        if (readName != "ERROR" && Trim(readName) != "" && !SSOK_QU_IsOldPlaceholderName(idx, readName))
            SSOK_QU_Name%idx% := readName
        if (readUrl != "ERROR" && Trim(readUrl) != "")
            SSOK_QU_Url%idx% := readUrl
    }

return

SSOK_QU_SaveIni:
    ; ÇÑ±Û ±úÁü ¹æÁö: IniWrite ´ë½Å ÅëÇÕ ÀúÀå ÇÔ¼ö »ç¿ë
    SSOK_SaveUnifiedIni()
return

SSOK_QU_SaveOneFromGui(index)
{
    global
    Gui, SSOKQuickUrl:Submit, NoHide
    SSOK_QU_Ini := SSOK_IniFile

    nameEditVar := SSOK_QU_NameEdit%index%
    urlEditVar := SSOK_QU_Edit%index%

    if (Trim(nameEditVar) = "")
        nameEditVar := "»çÀÌÆ®" . index

    SSOK_QU_Name%index% := nameEditVar
    SSOK_QU_Url%index% := urlEditVar

    ; ÇÑ±Û ±úÁü ¹æÁö: IniWrite ´ë½Å ÅëÇÕ ÀúÀå ÇÔ¼ö »ç¿ë
    SSOK_QU_SaveActive := 1
    SSOK_SaveUnifiedIni()
    SSOK_QU_SaveActive := 0
}

SSOK_QU_SaveAllFromGui()
{
    global
    Gui, SSOKQuickUrl:Submit, NoHide
    Loop, 12
    {
        idx := A_Index
        nameEditVar := SSOK_QU_NameEdit%idx%
        urlEditVar := SSOK_QU_Edit%idx%
        if (Trim(nameEditVar) = "")
            nameEditVar := "»çÀÌÆ®" . idx
        SSOK_QU_Name%idx% := nameEditVar
        SSOK_QU_Url%idx% := urlEditVar
    }
    SSOK_QU_SaveActive := 1
    SSOK_SaveUnifiedIni()
    SSOK_QU_SaveActive := 0
}

SSOK_QU_SaveAll:
    SSOK_QU_SaveAllFromGui()
    MsgBox, 64, SSOK ¾È³», Win+F5 URL ¸ñ·ÏÀ» ÀúÀåÇß½À´Ï´Ù.`n`nÀúÀå À§Ä¡:`nssok.ini
return

SSOK_QU_OpenTextFile:
    SSOK_QU_SaveAllFromGui()
    path := SSOK_IniFile
    Run, notepad.exe "%path%"
return

SSOK_QU_NormalizeUrl(url)
{
    u := Trim(url)
    if (u = "")
        return ""
    if RegExMatch(u, "i)^(https?://|file:|mailto:)")
        return u
    return "https://" . u
}

SSOK_QU_OpenSmartSearch(query)
{
    url := SSOK_QU_BuildSmartSearchUrl(query)
    if (url != "")
        SSOK_OpenUrlPreferred(url)
}

SSOK_QU_BuildSmartSearchUrl(query)
{
    q := Trim(query)
    if (q = "")
        return ""
    if RegExMatch(q, "i)^(https?://|file:|mailto:)")
        return q
    if (SSOK_QU_IsDirectUrl(q))
        return "https://" . q
    knownUrl := SSOK_QU_GetKnownSiteUrl(q)
    if (knownUrl != "")
        return knownUrl
    return "https://duckduckgo.com/?q=" . SSOK_QU_UrlEncode(Chr(92) . q)
}

SSOK_QU_GetKnownSiteUrl(query)
{
    q := Trim(query)
    StringLower, q, q
    q := RegExReplace(q, "\s+")
    if (q = "³×ÀÌ¹ö" || q = "naver")
        return "https://www.naver.com/"
    if (q = "±¸±Û" || q = "google")
        return "https://www.google.com/"
    if (q = "´ÙÀ½" || q = "daum")
        return "https://www.daum.net/"
    if (q = "À¯Æ©ºê" || q = "youtube")
        return "https://www.youtube.com/"
    return ""
}

SSOK_QU_IsDirectUrl(text)
{
    t := Trim(text)
    if RegExMatch(t, "i)^localhost(:\d+)?([/?#].*)?$")
        return true
    if RegExMatch(t, "i)^\d{1,3}(\.\d{1,3}){3}(:\d+)?([/?#].*)?$")
        return true
    return RegExMatch(t, "i)^([a-z0-9-]+\.)+[a-z]{2,}(:\d+)?([/?#].*)?$")
}

SSOK_QU_UrlEncode(text)
{
    _size := StrPut(text, "UTF-8")
    VarSetCapacity(_buf, _size, 0)
    _len := StrPut(text, &_buf, _size, "UTF-8") - 1
    _out := ""
    Loop, %_len%
    {
        _ch := NumGet(_buf, A_Index - 1, "UChar")
        if ((_ch >= 0x30 && _ch <= 0x39) || (_ch >= 0x41 && _ch <= 0x5A) || (_ch >= 0x61 && _ch <= 0x7A) || _ch = 0x2D || _ch = 0x2E || _ch = 0x5F || _ch = 0x7E)
            _out .= Chr(_ch)
        else if (_ch = 0x20)
            _out .= "+"
        else
            _out .= "%" . Format("{:02X}", _ch)
    }
    return _out
}

SSOK_QU_OpenIndex(index)
{
    global
    SSOK_QU_SaveOneFromGui(index)
    urlVar := SSOK_QU_Url%index%
    urlVar := SSOK_QU_NormalizeUrl(urlVar)
    if (urlVar = "")
    {
        MsgBox, 48, SSOK ¾È³», ÁÖ¼Ò°¡ ºñ¾î ÀÖ½À´Ï´Ù.`n`nÁÖ¼Ò¸¦ ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    Gui, SSOKQuickUrl:Destroy
    SSOK_OpenUrlPreferred(urlVar)
}

SSOK_QU_Open1:
    SSOK_QU_OpenIndex(1)
return
SSOK_QU_Open2:
    SSOK_QU_OpenIndex(2)
return
SSOK_QU_Open3:
    SSOK_QU_OpenIndex(3)
return
SSOK_QU_Open4:
    SSOK_QU_OpenIndex(4)
return
SSOK_QU_Open5:
    SSOK_QU_OpenIndex(5)
return
SSOK_QU_Open6:
    SSOK_QU_OpenIndex(6)
return
SSOK_QU_Open7:
    SSOK_QU_OpenIndex(7)
return
SSOK_QU_Open8:
    SSOK_QU_OpenIndex(8)
return
SSOK_QU_Open9:
    SSOK_QU_OpenIndex(9)
return
SSOK_QU_Open10:
    SSOK_QU_OpenIndex(10)
return
SSOK_QU_Open11:
    SSOK_QU_OpenIndex(11)
return
SSOK_QU_Open12:
    SSOK_QU_OpenIndex(12)
return

#F7::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF7
return

SSOK_DoF7:
    SSOK_OpenUrlPreferred("https://sje.eduptl.kr/bpm_lgn_lg00_001.do?noEpSession")
return

#F8::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF8
return

SSOK_DoF8:
    SSOK_OpenUrlPreferred("https://mail.korea.kr/")
return

; =========================================================
; ÀÎ¼â ÈÄ Æ÷Ä¿½º ¸®¼Â º¸Á¶ ·çÆ¾
; - K-¿¡µàÆÄÀÎ/ºê¶ó¿ìÀú ÀÎ¼â ÈÄ Å° ÀÔ·ÂÀÌ³ª Å¬¸¯ÀÌ ¸ÔÁö ¾ÊÀ» ¶§ »ç¿ë
; =========================================================
SSOK_DoF10_PrintFocusReset:
    ; È¤½Ã ´­¸° »óÅÂ·Î ³²Àº º¸Á¶Å°¸¦ ¸ÕÀú ÇØÁ¦
    Send, {Ctrl up}{LControl up}{RControl up}{Alt up}{LAlt up}{RAlt up}{Shift up}{LShift up}{RShift up}{LWin up}{RWin up}
    Sleep, 80

    ; ÇöÀç È°¼º Ã¢À» ÀúÀå ÈÄ ÃÖ¼ÒÈ­/º¹¿øÇÏ¿© Æ÷Ä¿½º ÀçÈ¹µæ
    WinGet, SSOK_F10_Hwnd, ID, A
    if (SSOK_F10_Hwnd = "")
        return

    WinMinimize, ahk_id %SSOK_F10_Hwnd%
    Sleep, 250
    WinRestore, ahk_id %SSOK_F10_Hwnd%
    Sleep, 250
    WinActivate, ahk_id %SSOK_F10_Hwnd%
    WinWaitActive, ahk_id %SSOK_F10_Hwnd%, , 2
    Sleep, 120

    ; ¸¶Áö¸·À¸·Î ÇÑ ¹ø ´õ Å° »óÅÂ ÇØÁ¦
    Send, {Ctrl up}{LControl up}{RControl up}{Alt up}{LAlt up}{RAlt up}{Shift up}{LShift up}{RShift up}{LWin up}{RWin up}
return



; AI º¸°í¼­ º¯È¯ ±â´ÉÀº º°µµ ¸ðµâ·Î ºÐ¸®Çß½À´Ï´Ù.
#Include %A_ScriptDir%\ssok_ai_report.ahk

; Win+F12´Â ¸ÞÀÎ ¸Þ´ºÀÇ [Åð±Ù PC OFF]¿Í µ¿ÀÏÇÏ°Ô ÀýÀüÀ¸·Î ÁøÀÔÇÕ´Ï´Ù.
#F12::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoMouseWakeSleep
return

SSOK_DoF12:
    SSOK_RefreshWakeTaskFromIni()
    Sleep, 500  ; ¿¹¾à ÀÚµ¿ OFF Àü ´ë±â
    ; Ãâ±Ù/Åð±Ù ÀÚµ¿ ¿¹¾à OFF¿¡¼­¸¸ ÃÖ´ëÀýÀüÀ¸·Î ÁøÀÔÇÕ´Ï´Ù.
    DllCall("PowrProf\SetSuspendState", "Int", 1, "Int", 0, "Int", 0)
return

SSOK_DoMouseWakeSleep:
    SSOK_RefreshWakeTaskFromIni()
    SSOK_EnableInputWakeDevices()
    Sleep, 500  ; ¹öÆ° Å¬¸¯À» ³õÀ» ½Ã°£À» ÁÖ±â À§ÇÑ ´ë±â
    ; Á÷Á¢ ´©¸£´Â Åð±Ù PC OFF´Â ¸¶¿ì½º/Å°º¸µå·Î ±ú¿ï ¼ö ÀÖµµ·Ï ÃÖ´ëÀýÀüÀÌ ¾Æ´Ñ ÀýÀüÀ¸·Î ÁøÀÔÇÕ´Ï´Ù.
    DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
return

SSOK_EnableInputWakeDevices()
{
    _tempFile := SSOK_GlobalGetPrivateWorkDir("misc") . "\ssok_input_wake_" . A_TickCount . ".txt"
    FileDelete, %_tempFile%
    _queryCmd := ComSpec . " /c powercfg /devicequery wake_from_any > " . SSOK_QF_CmdQuote(_tempFile) . " 2>nul"
    RunWait, %_queryCmd%,, Hide
    if !FileExist(_tempFile)
        return

    FileRead, _deviceText, %_tempFile%
    FileDelete, %_tempFile%
    Loop, Parse, _deviceText, `n, `r
    {
        _device := Trim(A_LoopField)
        if (_device = "")
            continue
        _deviceLower := _device
        StringLower, _deviceLower, _deviceLower
        if (!InStr(_deviceLower, "mouse") && !InStr(_deviceLower, "¸¶¿ì½º") && !InStr(_deviceLower, "keyboard") && !InStr(_deviceLower, "Å°º¸µå"))
            continue
        _enableCmd := ComSpec . " /c powercfg /deviceenablewake " . SSOK_QF_CmdQuote(_device) . " >nul 2>nul"
        RunWait, %_enableCmd%,, Hide
    }
}

SSOK_ShowPowerScheduleGui:
    IniRead, SSOK_PowerOnRaw, %SSOK_IniFile%, PowerSchedule, OnTime, 0830
    IniRead, SSOK_PowerOffRaw, %SSOK_IniFile%, PowerSchedule, OffTime, 1630
    IniRead, SSOK_PowerScheduleEnabled, %SSOK_IniFile%, PowerSchedule, Enabled, 0
    SSOK_PowerOnTime := SSOK_NormalizeAlarmTime(SSOK_PowerOnRaw, "0830")
    SSOK_PowerOffTime := SSOK_NormalizeAlarmTime(SSOK_PowerOffRaw, "1630")
    SSOK_PowerOnText := SubStr(SSOK_PowerOnTime, 1, 2) . ":" . SubStr(SSOK_PowerOnTime, 3, 2)
    SSOK_PowerOffText := SubStr(SSOK_PowerOffTime, 1, 2) . ":" . SubStr(SSOK_PowerOffTime, 3, 2)

    Gui, SSOKPowerSchedule:Destroy
    Gui, SSOKPowerSchedule:+AlwaysOnTop +ToolWindow
    Gui, SSOKPowerSchedule:Color, F7FBFF
    Gui, SSOKPowerSchedule:Font, s12 bold, Malgun Gothic
    Gui, SSOKPowerSchedule:Add, Button, x40 y14 w260 h38 gSSOK_PowerSchedule_PCOff, Åð±ÙÇÏ±â (PC OFF)
    Gui, SSOKPowerSchedule:Font, s14 bold, Malgun Gothic
    Gui, SSOKPowerSchedule:Add, Text, x20 y86 w300 h28 c005BAC Center, Ãâ±Ù/Åð±Ù PC ÀÚµ¿ ON/OFF ¼³Á¤
    Gui, SSOKPowerSchedule:Font, s10 norm, Malgun Gothic
    Gui, SSOKPowerSchedule:Add, Text, x30 y130 w80 h24 +0x200, Ãâ±Ù ON
    Gui, SSOKPowerSchedule:Add, Edit, x115 y130 w80 h24 Center vSSOK_PowerOnEdit, %SSOK_PowerOnText%
    Gui, SSOKPowerSchedule:Add, Text, x205 y130 w90 h24 +0x200 c777777, ¿¹: 08:30
    Gui, SSOKPowerSchedule:Add, Text, x30 y164 w80 h24 +0x200, Åð±Ù OFF
    Gui, SSOKPowerSchedule:Add, Edit, x115 y164 w80 h24 Center vSSOK_PowerOffEdit, %SSOK_PowerOffText%
    Gui, SSOKPowerSchedule:Add, Text, x205 y164 w90 h24 +0x200 c777777, ¿¹: 16:30
    Gui, SSOKPowerSchedule:Add, Checkbox, x115 y200 w150 h24 vSSOK_PowerEnableCheck Checked%SSOK_PowerScheduleEnabled%, ÀÚµ¿ ¿¹¾à »ç¿ë
    Gui, SSOKPowerSchedule:Font, s9 norm, Malgun Gothic
    Gui, SSOKPowerSchedule:Add, Text, x25 y232 w290 h38 c777777 Center, ONÀº ÀýÀü/ÃÖ´ëÀýÀü »óÅÂ¿¡¼­¸¸ ±ú¿ï ¼ö ÀÖ½À´Ï´Ù.`n¿ÏÀü Á¾·áµÈ PC´Â BIOS/Àü¿ø ¼³Á¤ÀÌ ÇÊ¿äÇÕ´Ï´Ù.
    Gui, SSOKPowerSchedule:Font, s10 bold, Malgun Gothic
    Gui, SSOKPowerSchedule:Add, Button, x60 y282 w95 h30 gSSOK_SavePowerSchedule, ÀúÀå
    Gui, SSOKPowerSchedule:Add, Button, x180 y282 w95 h30 gSSOKPowerScheduleGuiClose, ´Ý±â
    SSOK_GetSidebarAttachedGuiPos(340, 328, SSOK_PowerWinX, SSOK_PowerWinY)
    Gui, SSOKPowerSchedule:Show, x%SSOK_PowerWinX% y%SSOK_PowerWinY% w340 h328, SSOK Ãâ±Ù/Åð±Ù ¼³Á¤
return

SSOK_PowerSchedule_PCOff:
    Gui, SSOKPowerSchedule:Destroy
    Gosub, SSOK_DoMouseWakeSleep
return

SSOK_SavePowerSchedule:
    Gui, SSOKPowerSchedule:Submit, NoHide
    SSOK_PowerOnSave := SSOK_NormalizeAlarmTime(SSOK_PowerOnEdit, "0830")
    SSOK_PowerOffSave := SSOK_NormalizeAlarmTime(SSOK_PowerOffEdit, "1630")
    IniWrite, %SSOK_PowerOnSave%, %SSOK_IniFile%, PowerSchedule, OnTime
    IniWrite, %SSOK_PowerOffSave%, %SSOK_IniFile%, PowerSchedule, OffTime
    IniWrite, %SSOK_PowerEnableCheck%, %SSOK_IniFile%, PowerSchedule, Enabled
    if (SSOK_PowerEnableCheck = 1)
    {
        SSOK_CreateWakeTask(SSOK_PowerOnSave)
        SetTimer, SSOK_CheckPowerOffSchedule, 30000
    }
    else
    {
        SSOK_DeleteWakeTask()
        SetTimer, SSOK_CheckPowerOffSchedule, Off
    }
    ToolTip, Ãâ±Ù/Åð±Ù ½Ã°£À» ÀúÀåÇß½À´Ï´Ù.
    SetTimer, SSOK_RemoveAlarmToolTip, -1300
return

SSOKPowerScheduleGuiEscape:
SSOKPowerScheduleGuiClose:
    Gui, SSOKPowerSchedule:Destroy
return

SSOK_CheckPowerOffSchedule:
    IniRead, SSOK_PowerEnabled, %SSOK_IniFile%, PowerSchedule, Enabled, 0
    if (SSOK_PowerEnabled != 1)
        return
    IniRead, SSOK_PowerOffRaw, %SSOK_IniFile%, PowerSchedule, OffTime, 1630
    SSOK_PowerOffTime := SSOK_NormalizeAlarmTime(SSOK_PowerOffRaw, "1630")
    FormatTime, SSOK_PowerNow,, HHmm
    FormatTime, SSOK_PowerToday,, yyyyMMdd
    if (SSOK_PowerNow = SSOK_PowerOffTime && SSOK_LastPowerOffKey != SSOK_PowerToday . SSOK_PowerOffTime)
    {
        SSOK_LastPowerOffKey := SSOK_PowerToday . SSOK_PowerOffTime
        Gosub, SSOK_DoF12
    }
return

SSOK_RefreshWakeTaskFromIni()
{
    IniRead, SSOK_PowerEnabled, %SSOK_IniFile%, PowerSchedule, Enabled, 0
    if (SSOK_PowerEnabled = 1)
    {
        IniRead, SSOK_PowerOnRaw, %SSOK_IniFile%, PowerSchedule, OnTime, 0830
        SSOK_PowerOnTime := SSOK_NormalizeAlarmTime(SSOK_PowerOnRaw, "0830")
        SSOK_CreateWakeTask(SSOK_PowerOnTime)
    }
    else
        SSOK_DeleteWakeTask()
}

SSOK_CreateWakeTask(timeText)
{
    if (timeText = "")
        return
    runAt := SSOK_GetNextKoreaWorkdayWakeBoundary(timeText)
    if (runAt = "")
        return
    try
    {
        service := ComObjCreate("Schedule.Service")
        service.Connect()
        root := service.GetFolder("")
        task := service.NewTask(0)
        task.RegistrationInfo.Description := "SSOK Ãâ±Ù ½Ã°£ PC ±ú¿ì±â(Åä¡¤ÀÏ¡¤ÇÑ±¹ °øÈÞÀÏ Á¦¿Ü)"
        task.Settings.Enabled := true
        task.Settings.WakeToRun := true
        task.Settings.StartWhenAvailable := false
        task.Settings.DisallowStartIfOnBatteries := false
        task.Settings.StopIfGoingOnBatteries := false
        trigger := task.Triggers.Create(1)
        trigger.StartBoundary := runAt
        action := task.Actions.Create(0)
        action.Path := "cmd.exe"
        action.Arguments := "/c exit"
        root.RegisterTaskDefinition("SSOK_WakeOnTime", task, 6, "", "", 3)
    }
    catch e
    {
        ToolTip, ON ¿¹¾àÀ» ¸¸µé ¼ö ¾ø½À´Ï´Ù. Windows ÀÛ¾÷ ½ºÄÉÁÙ·¯ ±ÇÇÑ/±ú¿ì±â ¼³Á¤À» È®ÀÎÇØ ÁÖ¼¼¿ä.
        SetTimer, SSOK_RemoveAlarmToolTip, -2200
    }
}

SSOK_GetNextKoreaWorkdayWakeBoundary(timeText)
{
    timeText := SSOK_NormalizeAlarmTime(timeText, "0830")
    FormatTime, today,, yyyyMMdd
    FormatTime, nowStamp,, yyyyMMddHHmm
    wakeStamp := today . timeText . "00"
    if (SubStr(wakeStamp, 1, 12) <= nowStamp)
        EnvAdd, wakeStamp, 1, Days

    Loop, 370
    {
        FormatTime, wakeDate, %wakeStamp%, yyyyMMdd
        if (!SSOK_IsKoreaNonWorkday(wakeDate))
        {
            FormatTime, runAt, %wakeStamp%, yyyy-MM-ddTHH:mm:ss
            return runAt
        }
        EnvAdd, wakeStamp, 1, Days
    }

    FormatTime, runAt, %wakeStamp%, yyyy-MM-ddTHH:mm:ss
    return runAt
}

SSOK_IsKoreaNonWorkday(date8)
{
    if (SSOK_IsKoreaWeekend(date8))
        return true
    if (SSOK_IsKoreaHoliday(date8))
        return true
    return false
}

SSOK_IsKoreaWeekend(date8)
{
    stamp := date8 . "000000"
    FormatTime, wday, %stamp%, WDay
    return (wday = 1 || wday = 7)
}

SSOK_IsKoreaSunday(date8)
{
    stamp := date8 . "000000"
    FormatTime, wday, %stamp%, WDay
    return (wday = 1)
}

SSOK_IsKoreaHoliday(date8)
{
    year := SubStr(date8, 1, 4) + 0
    csv := SSOK_GetKoreaHolidayCsv(year)
    return InStr("," . csv . ",", "," . date8 . ",") > 0
}

SSOK_GetKoreaHolidayCsv(year)
{
    static cache
    if !IsObject(cache)
        cache := {}
    year := year + 0
    if (cache.HasKey(year))
        return cache[year]

    ; ssok.ini [HolidayApi] ServiceKey°¡ ÀÖÀ¸¸é ÇÑ±¹Ãµ¹®¿¬±¸¿ø Æ¯ÀÏÁ¤º¸ API¸¦ ¿ì¼± »ç¿ëÇÕ´Ï´Ù.
    ; Å°°¡ ¾ø°Å³ª Á¶È¸°¡ ½ÇÆÐÇÏ¸é ¾Æ·¡ ³»Àå °è»ê °æ·Î·Î Áï½Ã µ¹¾Æ°©´Ï´Ù.
    apiCsv := SSOK_GetKoreaHolidayCsvFromPublicApi(year)
    if (apiCsv != "")
    {
        cache[year] := apiCsv
        return apiCsv
    }

    yyyy := Format("{:04}", year)
    entries := []
    holidays := {}
    counts := {}

    ; mode 0: ´ëÃ¼°øÈÞÀÏ ¾øÀ½ / mode 1: Åä¡¤ÀÏ °ãÄ§ ½Ã ´ëÃ¼ / mode 2: ÀÏ¿äÀÏ °ãÄ§ ½Ã ´ëÃ¼
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "0101", 0)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "0301", 1)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "0501", 1)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "0505", 1)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "0606", 0)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "0815", 1)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "1003", 1)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "1009", 1)
    SSOK_AddKoreaHolidayEntry(entries, yyyy . "1225", 1)
    if (year = 2026)
        SSOK_AddKoreaHolidayEntry(entries, "20260603", 0)  ; Á¦9È¸ Àü±¹µ¿½ÃÁö¹æ¼±°ÅÀÏ

    lunarCsv := SSOK_GetKoreaLunarHolidayCsv(year)
    Loop, Parse, lunarCsv, `,
    {
        d := A_LoopField
        if !RegExMatch(d, "^\d{8}$")
            continue
        idx := A_Index
        if (idx <= 3)
            SSOK_AddKoreaHolidayEntry(entries, d, 2)
        else if (idx = 4)
            SSOK_AddKoreaHolidayEntry(entries, d, 1)
        else
            SSOK_AddKoreaHolidayEntry(entries, d, 2)
    }

    for i, entry in entries
    {
        d := entry.Date
        if !RegExMatch(d, "^\d{8}$")
            continue
        holidays[d] := 1
        if (counts.HasKey(d))
            counts[d] := counts[d] + 1
        else
            counts[d] := 1
    }

    for i, entry in entries
    {
        d := entry.Date
        mode := entry.Mode
        if !RegExMatch(d, "^\d{8}$")
            continue
        if (mode = 1 && SSOK_IsKoreaWeekend(d))
            SSOK_AddKoreaSubstituteHoliday(holidays, d)
        else if (mode = 2 && SSOK_IsKoreaSunday(d))
            SSOK_AddKoreaSubstituteHoliday(holidays, d)
        if (mode > 0 && counts.HasKey(d) && counts[d] > 1 && !SSOK_IsKoreaWeekend(d))
            SSOK_AddKoreaSubstituteHoliday(holidays, d)
    }

    csv := ""
    for d, v in holidays
        csv .= (csv = "" ? "" : ",") . d
    cache[year] := csv
    return csv
}

SSOK_GetKoreaHolidayCsvFromPublicApi(year)
{
    global SSOK_IniFile
    year := year + 0
    if (year < 1900 || year > 2100)
        return ""

    IniRead, serviceKey, %SSOK_IniFile%, HolidayApi, ServiceKey, __SSOK_EMPTY__
    serviceKey := Trim(serviceKey)
    if (serviceKey = "" || serviceKey = "ERROR" || serviceKey = "__SSOK_EMPTY__")
        return ""

    keyParam := SSOK_HolidayApiServiceKeyParam(serviceKey)
    url := "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo?ServiceKey=" . keyParam . "&solYear=" . year . "&numOfRows=100"

    try
    {
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(500, 1000, 1000, 1500)
        http.Open("GET", url, false)
        http.Send()
        if (http.Status != 200)
            return ""
        return SSOK_ParseKoreaHolidayApiXml(http.ResponseText)
    }
    catch
    {
        return ""
    }
}

SSOK_HolidayApiServiceKeyParam(serviceKey)
{
    ; °ø°øµ¥ÀÌÅÍÆ÷ÅÐÀº ÀÎÄÚµù Å°/µðÄÚµù Å°¸¦ ¸ðµÎ º¸¿©ÁÖ¹Ç·Î,
    ; ÀÌ¹Ì %XX ÇüÅÂ°¡ µé¾î¿Â Å°´Â ±×´ë·Î ¾²°í ³ª¸ÓÁö¸¸ URL ÀÎÄÚµùÇÕ´Ï´Ù.
    if InStr(serviceKey, "%")
        return serviceKey
    return SSOK_QU_UrlEncode(serviceKey)
}

SSOK_ParseKoreaHolidayApiXml(xml)
{
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return ""
        nodes := dom.selectNodes("//item")
        csv := ""
        Loop, % nodes.length
        {
            item := nodes.item(A_Index - 1)
            locNode := item.selectSingleNode("locdate")
            holidayNode := item.selectSingleNode("isHoliday")
            if (!locNode)
                continue
            if (holidayNode && holidayNode.text != "Y")
                continue
            d := Trim(locNode.text)
            if RegExMatch(d, "^\d{8}$")
                csv .= (csv = "" ? "" : ",") . d
        }
        return csv
    }
    catch
    {
        return ""
    }
}

SSOK_AddKoreaHolidayEntry(ByRef entries, date8, mode)
{
    if RegExMatch(date8, "^\d{8}$")
        entries.Push(Object("Date", date8, "Mode", mode))
}

SSOK_AddKoreaSubstituteHoliday(ByRef holidays, baseDate8)
{
    cand := baseDate8 . "000000"
    Loop, 20
    {
        EnvAdd, cand, 1, Days
        FormatTime, candDate, %cand%, yyyyMMdd
        if (!holidays.HasKey(candDate) && !SSOK_IsKoreaWeekend(candDate))
        {
            holidays[candDate] := 1
            return candDate
        }
    }
    return ""
}

SSOK_GetKoreaLunarHolidayCsv(year)
{
    ; ÇÑ±¹ À½·Â º¯È¯À¸·Î ÁÖ¿ä À½·Â °øÈÞÀÏÀ» °è»êÇÕ´Ï´Ù.
    ; Ç×¸ñ ¼ø¼­: ¼³ Àü³¯/´çÀÏ/´ÙÀ½³¯, ºÎÃ³´Ô¿À½Å³¯, Ãß¼® Àü³¯/´çÀÏ/´ÙÀ½³¯
    seollal := SSOK_KoreanLunarToSolarDate(year, 1, 1)
    buddha := SSOK_KoreanLunarToSolarDate(year, 4, 8)
    chuseok := SSOK_KoreanLunarToSolarDate(year, 8, 15)
    if (seollal = "" || buddha = "" || chuseok = "")
        return ""

    return SSOK_DateAddDays(seollal, -1) . "," . seollal . "," . SSOK_DateAddDays(seollal, 1)
        . "," . buddha
        . "," . SSOK_DateAddDays(chuseok, -1) . "," . chuseok . "," . SSOK_DateAddDays(chuseok, 1)
}

SSOK_KoreanLunarToSolarDate(year, month, day, isLeap := false)
{
    info := SSOK_GetKoreanLunarYearInfo(year)
    if (!IsObject(info))
        return ""

    month := month + 0
    day := day + 0
    leapIdx := info.LeapIndex + 0
    monthIdx := month

    ; .NET KoreanLunisolarCalendar ±âÁØ LeapIndex´Â À±´ÞÀÌ ³¢¾îµå´Â À§Ä¡ÀÔ´Ï´Ù.
    ; ¿¹: leapIdx=5ÀÌ¸é 4¿ù µÚ¿¡ À±4¿ùÀÌ ÀÖ°í, ½ÇÁ¦ ¹è¿­ÀÇ 5¹øÂ° ´ÞÀÌ À±4¿ùÀÔ´Ï´Ù.
    if (isLeap)
    {
        if (leapIdx <= 0 || month != leapIdx - 1)
            return ""
        monthIdx := leapIdx
    }
    else if (leapIdx > 0 && month >= leapIdx)
        monthIdx := month + 1

    if (monthIdx < 1 || monthIdx > info.MonthDays.Length())
        return ""

    maxDay := info.MonthDays[monthIdx] + 0
    if (day < 1 || day > maxDay)
        return ""

    offset := day - 1
    Loop, % monthIdx - 1
        offset += info.MonthDays[A_Index] + 0

    return SSOK_DateAddDays(info.SolarStart, offset)
}

SSOK_DateAddDays(date8, days)
{
    if !RegExMatch(date8, "^\d{8}$")
        return ""
    stamp := date8 . "000000"
    EnvAdd, stamp, %days%, Days
    FormatTime, out, %stamp%, yyyyMMdd
    return out
}

SSOK_GetKoreanLunarYearInfo(year)
{
    static cache
    if !IsObject(cache)
    {
        cache := {}
        data =
(
1900:19000131:9:29.30.29.29.30.29.30.30.29.30.30.29.30
1901:19010219:0:29.30.29.29.30.29.30.29.30.30.30.29
1902:19020208:0:30.29.30.29.29.30.29.30.29.30.30.30
1903:19030129:6:29.30.29.30.29.29.30.29.29.30.30.29.30
1904:19040216:0:30.30.29.30.29.29.30.29.29.30.30.29
1905:19050204:0:30.30.29.30.30.29.29.30.29.30.29.30
1906:19060125:5:29.30.30.29.30.29.30.29.30.29.30.29.30
1907:19070213:0:29.30.29.30.29.30.30.29.30.29.30.29
1908:19080202:0:30.29.29.30.30.29.30.29.30.30.29.30
1909:19090122:3:29.30.29.29.30.29.30.29.30.30.30.29.30
1910:19100210:0:29.30.29.29.30.29.30.29.30.30.30.29
1911:19110130:7:30.29.30.29.29.30.29.29.30.30.29.30.30
1912:19120218:0:30.29.30.29.29.30.29.29.30.30.29.30
1913:19130206:0:30.30.29.30.29.29.30.29.29.30.29.30
1914:19140126:6:30.30.29.30.30.29.29.30.29.30.29.29.30
1915:19150214:0:30.29.30.30.29.30.29.30.29.30.29.30
1916:19160204:0:29.30.29.30.29.30.30.29.30.29.30.29
1917:19170123:3:30.29.29.30.29.30.30.29.30.30.29.30.29
1918:19180211:0:30.29.29.30.29.30.29.30.30.30.29.30
1919:19190201:8:29.30.29.29.30.29.30.29.30.30.29.30.30
1920:19200220:0:29.30.29.29.30.29.29.30.30.29.30.30
1921:19210208:0:30.29.30.29.29.30.29.29.30.29.30.30
1922:19220128:6:30.29.30.30.29.29.30.29.29.30.29.30.30
1923:19230216:0:29.30.30.29.30.29.30.29.30.29.29.30
1924:19240205:0:30.29.30.29.30.30.29.30.29.30.29.29
1925:19250124:5:30.29.30.30.29.30.29.30.30.29.30.29.30
1926:19260213:0:29.29.30.29.30.29.30.30.29.30.30.29
1927:19270202:0:30.29.29.30.29.30.29.30.30.29.30.30
1928:19280123:3:29.30.29.29.30.29.29.30.30.29.30.30.30
1929:19290210:0:29.30.29.29.30.29.29.30.29.30.30.30
1930:19300130:7:29.30.30.29.29.30.29.29.30.29.30.30.29
1931:19310217:0:30.30.30.29.29.30.29.29.30.29.30.29
1932:19320206:0:30.30.30.29.30.29.30.29.29.30.29.30
1933:19330126:6:29.30.30.29.30.30.29.30.29.30.29.29.30
1934:19340214:0:29.30.29.30.30.29.30.30.29.30.29.30
1935:19350204:0:29.29.30.29.30.29.30.30.29.30.30.29
1936:19360124:4:30.29.29.30.29.30.29.30.29.30.30.30.29
1937:19370211:0:30.29.29.30.29.29.30.29.30.30.30.29
1938:19380131:8:30.30.29.29.30.29.29.30.29.30.30.29.30
1939:19390219:0:30.30.29.29.30.29.29.30.29.30.29.30
1940:19400208:0:30.30.29.30.29.30.29.29.30.29.30.29
1941:19410127:7:30.30.29.30.30.29.30.29.29.30.29.30.29
1942:19420215:0:30.29.30.30.29.30.30.29.30.29.29.30
1943:19430205:0:29.30.29.30.29.30.30.29.30.30.29.30
1944:19440126:5:29.29.30.29.30.29.30.29.30.30.29.30.30
1945:19450213:0:29.29.30.29.29.30.29.30.30.30.29.30
1946:19460202:0:30.29.29.30.29.29.30.29.30.30.29.30
1947:19470122:3:30.30.29.29.30.29.29.30.29.30.29.30.30
1948:19480210:0:30.29.30.29.30.29.29.30.29.30.29.30
1949:19490129:8:30.30.29.30.29.30.29.29.30.29.30.29.30
1950:19500217:0:30.29.30.30.29.30.29.29.30.29.30.29
1951:19510206:0:30.29.30.30.29.30.29.30.29.30.29.30
1952:19520127:6:29.30.29.30.29.30.30.29.30.29.30.29.30
1953:19530214:0:29.30.29.29.30.30.29.30.30.29.30.30
1954:19540204:0:29.29.30.29.29.30.29.30.30.29.30.30
1955:19550124:4:30.29.29.30.29.29.30.29.30.29.30.30.30
1956:19560212:0:29.30.29.30.29.29.30.29.30.29.30.30
1957:19570131:9:30.29.30.29.30.29.29.30.29.30.29.30.30
1958:19580219:0:29.30.30.29.30.29.29.30.29.30.29.30
1959:19590208:0:29.30.30.29.30.29.30.29.30.29.30.29
1960:19600128:7:30.29.30.29.30.30.29.30.29.30.29.30.29
1961:19610215:0:30.29.30.29.30.29.30.30.29.30.29.30
1962:19620205:0:29.30.29.29.30.29.30.30.29.30.30.29
1963:19630125:5:30.29.30.29.29.30.29.30.29.30.30.30.29
1964:19640213:0:30.29.30.29.29.30.29.30.29.30.30.30
1965:19650202:0:29.30.29.30.29.29.30.29.29.30.30.30
1966:19660122:4:29.30.30.29.30.29.29.30.29.29.30.30.29
1967:19670209:0:30.30.29.30.30.29.29.30.29.30.29.30
1968:19680130:8:29.30.30.29.30.29.30.29.30.29.30.29.30
1969:19690217:0:29.30.29.30.29.30.30.29.30.29.30.29
1970:19700206:0:30.29.29.30.30.29.30.29.30.30.29.30
1971:19710127:6:29.30.29.29.30.29.30.29.30.30.30.29.30
1972:19720215:0:29.30.29.29.30.29.30.29.30.30.30.29
1973:19730203:0:30.29.30.29.29.30.29.29.30.30.30.29
1974:19740123:5:30.30.29.30.29.29.30.29.29.30.30.29.30
1975:19750211:0:30.30.29.30.29.29.30.29.29.30.29.30
1976:19760131:9:30.30.29.30.29.30.29.30.29.30.29.29.30
1977:19770218:0:30.29.30.30.29.30.29.30.29.30.29.29
1978:19780207:0:30.30.29.30.29.30.30.29.30.29.30.29
1979:19790128:7:30.29.29.30.29.30.30.29.30.30.29.30.29
1980:19800216:0:30.29.29.30.29.30.29.30.30.29.30.30
1981:19810205:0:29.30.29.29.30.29.29.30.30.29.30.30
1982:19820125:5:30.29.30.29.29.30.29.29.30.30.29.30.30
1983:19830213:0:30.29.30.29.29.30.29.29.30.29.30.30
1984:19840202:11:30.29.30.30.29.29.30.29.29.30.29.30.30
1985:19850220:0:29.30.30.29.30.29.30.29.29.30.29.30
1986:19860209:0:29.30.30.29.30.30.29.30.29.30.29.29
1987:19870129:7:30.29.30.30.29.30.29.30.30.29.30.29.30
1988:19880218:0:29.29.30.29.30.29.30.30.29.30.30.29
1989:19890206:0:30.29.29.30.29.30.29.30.30.29.30.30
1990:19900127:6:29.30.29.29.30.29.29.30.30.29.30.30.30
1991:19910215:0:29.30.29.29.30.29.29.30.29.30.30.30
1992:19920204:0:29.30.30.29.29.30.29.29.30.29.30.30
1993:19930123:4:29.30.30.29.30.29.30.29.29.30.29.30.29
1994:19940210:0:30.30.30.29.30.29.30.29.29.30.29.30
1995:19950131:9:29.30.30.29.30.30.29.30.29.30.29.29.30
1996:19960219:0:29.30.29.30.30.29.30.29.30.30.29.30
1997:19970208:0:29.29.30.29.30.29.30.30.29.30.30.29
1998:19980128:6:30.29.29.30.29.29.30.30.29.30.30.30.29
1999:19990216:0:30.29.29.30.29.29.30.29.30.30.30.29
2000:20000205:0:30.30.29.29.30.29.29.30.29.30.30.29
2001:20010124:5:30.30.30.29.29.30.29.29.30.29.30.29.30
2002:20020212:0:30.30.29.30.29.30.29.29.30.29.30.29
2003:20030201:0:30.30.29.30.30.29.30.29.29.30.29.30
2004:20040122:3:29.30.29.30.30.29.30.29.30.29.30.29.30
2005:20050209:0:29.30.29.30.29.30.30.29.30.30.29.29
2006:20060129:8:30.29.30.29.30.29.30.29.30.30.29.30.30
2007:20070218:0:29.29.30.29.29.30.29.30.30.30.29.30
2008:20080207:0:30.29.29.30.29.29.30.29.30.30.29.30
2009:20090126:6:30.30.29.29.30.29.29.30.29.30.29.30.30
2010:20100214:0:30.29.30.29.30.29.29.30.29.30.29.30
2011:20110203:0:30.29.30.30.29.30.29.29.30.29.30.29
2012:20120123:4:30.29.30.30.30.29.30.29.29.30.29.30.29
2013:20130210:0:30.29.30.30.29.30.29.30.29.30.29.30
2014:20140131:10:29.30.29.30.29.30.29.30.30.29.30.29.30
2015:20150219:0:29.30.29.29.30.29.30.30.30.29.30.29
2016:20160208:0:30.29.30.29.29.30.29.30.30.29.30.30
2017:20170128:6:29.30.29.30.29.29.30.29.30.29.30.30.30
2018:20180216:0:29.30.29.30.29.29.30.29.30.29.30.30
2019:20190205:0:30.29.30.29.30.29.29.30.29.30.29.30
2020:20200125:5:30.29.30.30.29.30.29.29.30.29.30.29.30
2021:20210212:0:29.30.30.29.30.29.30.29.30.29.30.29
2022:20220201:0:30.29.30.29.30.30.29.30.29.30.29.30
2023:20230122:3:29.30.29.30.29.30.29.30.30.29.30.29.30
2024:20240210:0:29.30.29.29.30.29.30.30.29.30.30.29
2025:20250129:7:30.29.30.29.29.30.29.30.29.30.30.30.29
2026:20260217:0:30.29.30.29.29.30.29.30.29.30.30.30
2027:20270207:0:29.30.29.30.29.29.30.29.29.30.30.30
2028:20280127:6:29.30.30.29.30.29.29.30.29.29.30.30.29
2029:20290213:0:30.30.29.30.30.29.29.30.29.29.30.30
2030:20300203:0:29.30.29.30.30.29.30.29.30.29.30.29
2031:20310123:4:30.29.30.29.30.29.30.30.29.30.29.30.29
2032:20320211:0:30.29.29.30.29.30.30.29.30.30.29.30
2033:20330131:12:29.30.29.29.30.29.30.29.30.30.30.29.30
2034:20340219:0:29.30.29.29.30.29.30.29.30.30.30.29
2035:20350208:0:30.29.30.29.29.30.29.29.30.30.29.30
2036:20360128:7:30.30.29.30.29.29.30.29.29.30.30.29.30
2037:20370215:0:30.30.29.30.29.29.30.29.29.30.29.30
2038:20380204:0:30.30.29.30.29.30.29.30.29.29.30.29
2039:20390124:6:30.30.29.30.30.29.30.29.30.29.30.29.29
2040:20400212:0:30.29.30.30.29.30.30.29.30.29.30.29
2041:20410201:0:30.29.29.30.29.30.30.29.30.30.29.30
2042:20420122:3:29.30.29.29.30.29.30.29.30.30.29.30.30
2043:20430210:0:29.30.29.29.30.29.29.30.30.29.30.30
2044:20440130:8:30.29.30.29.29.30.29.29.30.29.30.30.30
2045:20450217:0:30.29.30.29.29.30.29.29.30.29.30.30
2046:20460206:0:30.29.30.30.29.29.30.29.29.30.29.30
2047:20470126:6:30.29.30.30.29.30.29.30.29.29.30.29.30
2048:20480214:0:29.30.30.29.30.30.29.30.29.30.29.29
2049:20490202:0:30.29.30.29.30.30.29.30.30.29.30.29
2050:20500123:4:30.29.29.30.29.30.29.30.30.29.30.30.29
)
        Loop, Parse, data, `n, `r
        {
            line := Trim(A_LoopField)
            if (line = "")
                continue
            parts := StrSplit(line, ":")
            if (parts.Length() < 4)
                continue
            y := parts[1] + 0
            days := []
            for _, item in StrSplit(parts[4], ".")
                days.Push(item + 0)
            cache[y] := Object("SolarStart", parts[2], "LeapIndex", parts[3] + 0, "MonthDays", days)
        }
    }

    year := year + 0
    return cache.HasKey(year) ? cache[year] : ""
}
SSOK_DeleteWakeTask()
{
    try
    {
        service := ComObjCreate("Schedule.Service")
        service.Connect()
        root := service.GetFolder("")
        root.DeleteTask("SSOK_WakeOnTime", 0)
    }
}

SSOK_RemoveAlarmToolTip:
    ToolTip
return

; Å×½ºÆ®
; Launch_App1::
; Run, msedge.exe https://www.sje.go.kr
; Run, ?msedge.exe https://sje.eduptl.kr/bpm_lgn_lg00_001.do?noEpSession
; return

; ´ÜÃàÅ° (°³ÀÎÁ¤º¸ ÇÖ½ºÆ®¸µ º¸¾È»ó Á¦°ÅµÊ)
; ÁÖ¼Ò¡¤ÀüÈ­¹øÈ£¡¤ºñ¹Ð¹øÈ£ µî °³ÀÎÁ¤º¸´Â ÄÚµå¿¡ ÇÏµåÄÚµùÇÏÁö ¸¶¼¼¿ä.
; ssok.ini [PersonalHotstrings] ¼½¼Ç¿¡ º°µµ °ü¸®¸¦ ±ÇÀåÇÕ´Ï´Ù.





; =========================================================
; SSOK Win+F ´ÜÃàÅ° º¸Á¶ Ã³¸®
; - Win+F ´ÜÃàÅ° ½ÇÇà ½Ã Windows ½ÃÀÛ ¸Þ´º°¡ ÇÔ²² ¶ß´Â Çö»óÀ» ¹æÁö
; - ÀüÃ¼ ±â´É ¹Ù·Î°¡±â´Â Win+F4¿¡¼­ ½ÇÇà
; =========================================================

global SSOK_WinHelpVisible := 0
global SSOK_WinHelpKeyDown := 0
global SSOK_WinHelpTargetHwnd := ""
global SSOK_WinHelpDirectHwnd := ""
global SSOK_WinHelpDisabled := 0  ; 1=Win ´Üµ¶ ±æ°Ô ´©¸§ ¾È³»Ã¢ ºñÈ°¼ºÈ­, 0=»ç¿ë

SSOK_WinHelp_BlockWindowsMenu:
    ; Win Å°¸¦ ´Üµ¶À¸·Î ´­·¶´Ù°í Windows°¡ ÆÇ´ÜÇÏÁö ¾Ê°Ô ÇÏ´Â ¸¶½ºÅ© Ã³¸®
    ; vkE8¸¸À¸·Î ºÎÁ·ÇÑ PC°¡ ÀÖ¾î Ctrl Down/UpÀ» ÇÔ²² »ç¿ë
    SendInput, {Blind}{LControl Down}{LControl Up}
    Sleep, 10
    SendInput, {Blind}{vkE8}
    Sleep, 10
return

SSOK_WinHelp_CloseNativeMenuIfOpened:
    ; ±×·¡µµ ½ÃÀÛ/°Ë»ö ¸Þ´º°¡ ¿­¸° °æ¿ì¿¡¸¸ Esc·Î ´ÝÀ½
    ; ÀÏ¹Ý ¹®¼­Ã¢¿¡´Â Esc¸¦ º¸³»Áö ¾Êµµ·Ï ½ÃÀÛ/°Ë»ö °ü·Ã Ã¢¸¸ È®ÀÎ
    if WinActive("ahk_exe StartMenuExperienceHost.exe")
    {
        SendInput, {Esc}
        return
    }
    if WinActive("ahk_exe SearchHost.exe")
    {
        SendInput, {Esc}
        return
    }
    if WinActive("ahk_exe SearchUI.exe")
    {
        SendInput, {Esc}
        return
    }
    if WinActive("ahk_exe ShellExperienceHost.exe")
    {
        SendInput, {Esc}
        return
    }
    if WinActive("ahk_class Windows.UI.Core.CoreWindow")
    {
        SendInput, {Esc}
        return
    }
    if WinActive("ahk_class XamlExplorerHostIslandWindow")
    {
        SendInput, {Esc}
        return
    }
return

SSOK_WinHelp_ShowNow:
    ; WinÅ°¸¦ 2ÃÊ ÀÌ»ó '´Üµ¶À¸·Î' ´©¸¥ °æ¿ì¿¡¸¸ ¾È³»Ã¢À» Ç¥½ÃÇÕ´Ï´Ù.
    if (SSOK_WinHelpDisabled = 1)
    {
        SSOK_WinHelpKeyDown := 0
        SetTimer, SSOK_WinHelp_Watch, Off
        return
    }

    if !(GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
    {
        SSOK_WinHelpKeyDown := 0
        return
    }

    if (SSOK_WinHelpKeyDown != 1)
        return

    if (A_PriorKey != "LWin" && A_PriorKey != "RWin")
    {
        SSOK_WinHelpKeyDown := 0
        return
    }

    if (SSOK_WinHelpVisible = 1)
        return

    SSOK_WinHelpVisible := 1
    SSOK_WinHelpTargetHwnd := WinExist("A")

    SetTimer, SSOK_WinHelp_Watch, 80

    SSOK_MenuW := 700
    SSOK_MenuH := 500
    SSOK_MenuX := (A_ScreenWidth - SSOK_MenuW) // 2
    SSOK_MenuY := (A_ScreenHeight - SSOK_MenuH) // 2

    Gui, SSOKWinHelp:Destroy
    Gui, SSOKWinHelp:+AlwaysOnTop -Caption +ToolWindow -SysMenu +Border
    Gui, SSOKWinHelp:Color, F7FBFF
    Gui, SSOKWinHelp:Font, s10, Malgun Gothic

    Gui, SSOKWinHelp:Font, s11 bold, Malgun Gothic
    Gui, SSOKWinHelp:Add, Text, x25 y18 w650 h26 c003366 Center, ½î¿Á for K-¿¡µàÆÄÀÎ (SSOK-Sejong Smart One Key)

    Gui, SSOKWinHelp:Font, s10 norm, Malgun Gothic
    Gui, SSOKWinHelp:Add, Text, x35 y58 w115 h26 c005BAC gSSOK_ClickF1, Win + F1
    Gui, SSOKWinHelp:Add, Text, x165 y58 w390 h26 c222222 gSSOK_ClickF1, ½î¿Á ºü¸¥ ÀÔ·Â µµ¿ì¹Ì
    Gui, SSOKWinHelp:Add, Text, x590 y58 w70 h26 c005BAC Center gSSOK_ClickF1, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y93 w115 h26 c005BAC gSSOK_ClickF2, Win + F2
    Gui, SSOKWinHelp:Add, Text, x165 y93 w390 h26 c222222 gSSOK_ClickF2, ¹°Ç°¡¤¿ë¿ª¡¤±âÅ¸¡¤¼¼ÀÔ¡¤ÀÏ¹Ý µî ÀÚµ¿ ¹®¼­ Á¤¸®
    Gui, SSOKWinHelp:Add, Text, x590 y93 w70 h26 c005BAC Center gSSOK_ClickF2, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y128 w115 h26 c005BAC gSSOK_ClickF3, Win + F3
    Gui, SSOKWinHelp:Add, Text, x165 y128 w390 h26 c222222 gSSOK_ClickF3, Gemini AI µµ¿ì¹Ì
    Gui, SSOKWinHelp:Add, Text, x590 y128 w70 h26 c005BAC Center gSSOK_ClickF3, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y163 w115 h26 c005BAC gSSOK_ClickF4, Win + F4
    Gui, SSOKWinHelp:Add, Text, x165 y163 w390 h26 c222222 gSSOK_ClickF4, ÀüÃ¼ ±â´É ¹Ù·Î°¡±â
    Gui, SSOKWinHelp:Add, Text, x590 y163 w70 h26 c005BAC Center gSSOK_ClickF4, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y198 w115 h26 c005BAC gSSOK_ClickF5, Win + F5
    Gui, SSOKWinHelp:Add, Text, x165 y198 w390 h26 c222222 gSSOK_ClickF5, ÀÚÁÖ ¿©´Â ÆÄÀÏ
    Gui, SSOKWinHelp:Add, Text, x590 y198 w70 h26 c005BAC Center gSSOK_ClickF5, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y233 w115 h26 c005BAC gSSOK_ClickF6, Win + F6
    Gui, SSOKWinHelp:Add, Text, x165 y233 w390 h26 c222222 gSSOK_ClickF6, ÀÚÁÖ°¡´Â »çÀÌÆ®
    Gui, SSOKWinHelp:Add, Text, x590 y233 w70 h26 c005BAC Center gSSOK_ClickF6, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y268 w115 h26 c005BAC gSSOK_ClickF7, Win + F7
    Gui, SSOKWinHelp:Add, Text, x165 y268 w390 h26 c222222 gSSOK_ClickF7, ¿¡µàÆÄÀÎ ¸µÅ©
    Gui, SSOKWinHelp:Add, Text, x590 y268 w70 h26 c005BAC Center gSSOK_ClickF7, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y303 w115 h26 c005BAC gSSOK_ClickF8, Win + F8
    Gui, SSOKWinHelp:Add, Text, x165 y303 w390 h26 c222222 gSSOK_ClickF8, K¸ÞÀÏ ¸µÅ©
    Gui, SSOKWinHelp:Add, Text, x590 y303 w70 h26 c005BAC Center gSSOK_ClickF8, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y338 w115 h26 c005BAC gSSOK_ClickWinF10, Win + F10
    Gui, SSOKWinHelp:Add, Text, x165 y338 w390 h26 c222222 gSSOK_ClickWinF10, °³ÀÎÁ¤º¸ Á¤¸®
    Gui, SSOKWinHelp:Add, Text, x590 y338 w70 h26 c005BAC Center gSSOK_ClickWinF10, [Å¬¸¯]

    Gui, SSOKWinHelp:Add, Text, x35 y373 w115 h26 c005BAC gSSOK_ClickF12, Win + F12
    Gui, SSOKWinHelp:Add, Text, x165 y373 w390 h26 c222222 gSSOK_ClickF12, Åð±Ù PC OFF
    Gui, SSOKWinHelp:Add, Text, x590 y373 w70 h26 c005BAC Center gSSOK_ClickF12, [Å¬¸¯]

    Gui, SSOKWinHelp:Font, s7 norm, Malgun Gothic
    Gui, SSOKWinHelp:Add, Text, x260 y463 w410 h16 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£

    Gui, SSOKWinHelp:Show, NoActivate x%SSOK_MenuX% y%SSOK_MenuY% w%SSOK_MenuW% h%SSOK_MenuH%, SSOK Win ´ÜÃàÅ° ¾È³»
return

SSOK_WinHelp_Watch:
    ; ½ÇÁ¦ ¹°¸® Win »óÅÂ¸¦ °è¼Ó È®ÀÎ
    ; Win Å°¸¦ ¶Ã´Âµ¥ Up ÀÌº¥Æ®°¡ ´©¶ôµÇ¸é ¿©±â¼­ °­Á¦·Î ´ÝÀ½
    if !(GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
    {
        SSOK_WinHelpKeyDown := 0
        SetTimer, SSOK_WinHelp_ShowNow, Off
        SetTimer, SSOK_WinHelp_Watch, Off
        Gosub, SSOK_WinHelp_HideOnly
        Gosub, SSOK_WinHelp_BlockWindowsMenu
        SetTimer, SSOK_WinHelp_CloseNativeMenuIfOpened, -80
    }
return

SSOK_WinHelp_CancelDirect:
    ; Win+FÅ° Á÷Á¢ ½ÇÇà ¶§ ¸Þ´º Å¸ÀÌ¸Ó¸¦ ²ô°í, Windows ½ÃÀÛ/°Ë»ö ¸Þ´º°¡ ¶ßÁö ¾Ê°Ô ¸¶½ºÅ© Ã³¸®
    SSOK_WinHelpDirectHwnd := WinExist("A")
    SetTimer, SSOK_WinHelp_ShowNow, Off
    SetTimer, SSOK_WinHelp_Watch, Off
    SSOK_WinHelpKeyDown := 0
    Gosub, SSOK_WinHelp_HideOnly

    ; AHK°¡ FÅ° ÀÔ·ÂÀ» °¡·ÎÃ¤¸é Windows ÀÔÀå¿¡¼­´Â Win ´Üµ¶ ÀÔ·ÂÃ³·³ º¸ÀÏ ¼ö ÀÖ¾î ¸ÕÀú Â÷´Ü
    Gosub, SSOK_WinHelp_BlockWindowsMenu

    if (GetKeyState("LWin", "P"))
        KeyWait, LWin
    if (GetKeyState("RWin", "P"))
        KeyWait, RWin

    SetTimer, SSOK_WinHelp_CloseNativeMenuIfOpened, -80

    if (SSOK_WinHelpDirectHwnd != "")
    {
        WinActivate, ahk_id %SSOK_WinHelpDirectHwnd%
        Sleep, 80
    }
return

SSOK_WinHelp_PrepareClick:
    ; ¸Þ´º Å¬¸¯ ½ÇÇà ¶§ ¸Þ´º¸¦ ´Ý°í, Win Å°/Windows ¸Þ´º¸¦ Á¤¸®ÇÑ µÚ ¿ø·¡ ÀÛ¾÷ Ã¢À¸·Î µ¹¾Æ°¡ ½ÇÇà
    SetTimer, SSOK_WinHelp_ShowNow, Off
    SetTimer, SSOK_WinHelp_Watch, Off
    SSOK_WinHelpKeyDown := 0
    Gosub, SSOK_WinHelp_HideOnly
    Gosub, SSOK_WinHelp_BlockWindowsMenu

    if (GetKeyState("LWin", "P"))
        KeyWait, LWin
    if (GetKeyState("RWin", "P"))
        KeyWait, RWin

    SetTimer, SSOK_WinHelp_CloseNativeMenuIfOpened, -80

    Gosub, SSOK_ActivateWinHelpTarget
    Sleep, 80
return

SSOK_WinHelp_HideOnly:
    SetTimer, SSOK_WinHelp_Watch, Off
    if (SSOK_WinHelpVisible = 1)
    {
        SSOK_WinHelpVisible := 0
        Gui, SSOKWinHelp:Destroy
    }
return

SSOK_ActivateWinHelpTarget:
    if (SSOK_WinHelpTargetHwnd != "")
    {
        WinActivate, ahk_id %SSOK_WinHelpTargetHwnd%
        Sleep, 120
    }
return

SSOK_ClickF1:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF1
return

SSOK_ClickF2:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF2
return

SSOK_ClickF3:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF3
return

SSOK_ClickF4:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF4
return

SSOK_ClickF5:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF5
return

SSOK_ClickF6:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF6
return

SSOK_ClickF7:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF7
return

SSOK_ClickF8:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoF8
return

SSOK_ClickWinF10:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoPrivacyMask
return

SSOK_ClickF12:
    Gosub, SSOK_WinHelp_PrepareClick
    Gosub, SSOK_DoMouseWakeSleep
return

SSOKWinHelpGuiEscape:
SSOKWinHelpGuiClose:
    Gosub, SSOK_WinHelp_HideOnly
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    SetTimer, SSOK_WinHelp_CloseNativeMenuIfOpened, -80
return

DOC_TrySetGulim12AfterPaste()
{
    ; HWP¿¡¼­´Â ºÙ¿©³ÖÀº µÚ ¹®¼­ ÀüÃ¼¸¦ ±¼¸² 12pt·Î ¸ÂÃä´Ï´Ù.
    ; ±âÁ¸Ã³·³ HTML ¼­½ÄÀ¸·Î ºÙÀÌÁö ¾ÊÀ¸¹Ç·Î ÁÙ¹Ù²ÞÀÌ ÇÑ ÁÙ·Î ºÙ´Â ¹®Á¦¸¦ ÇÇÇÕ´Ï´Ù.
    ; ¾÷¹«°ü¸®½Ã½ºÅÛ À¥ ÆíÁý±â´Â ºê¶ó¿ìÀú/ÆíÁý±â Á¤Ã¥»ó ±Û²Ã °­Á¦°¡ ¾î·Á¿ö,
    ; ÀÏ¹Ý ÅØ½ºÆ®°¡ ÆíÁý±â ±âº» ±Û²ÃÀ» µû¶ó°¡µµ·Ï µÓ´Ï´Ù.

    if (!DOC_HasResponsiveHwpHost())
        return

    try
    {
        hwp := ComObjActive("HWPFrame.HwpObject")

        ; HWP ³»ºÎ ¸í·ÉÀ¸·Î ÀüÃ¼ ¼±ÅÃÇØ¾ß Send ^aº¸´Ù ¾ÈÁ¤ÀûÀÔ´Ï´Ù.
        try
            hwp.HAction.Run("SelectAll")
        catch
        {
            Send, ^a
            Sleep, 80
        }

        Sleep, 80

        hwp.HAction.GetDefault("CharShape", hwp.HParameterSet.HCharShape.HSet)

        ; ±Û²Ã: ±¼¸² / Å©±â: 12pt
        ; Á÷Á¢ ´ëÀÔ°ú SetItemÀ» ÇÔ²² ½ÃµµÇØ HWP ¹öÀüº° Àû¿ë ½ÇÆÐ¸¦ ÁÙÀÔ´Ï´Ù.
        try
        {
            hwp.HParameterSet.HCharShape.FaceNameHangul := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameLatin := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameHanja := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameJapanese := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameOther := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameSymbol := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameUser := "±¼¸²"

            ; 1Àº ÀÏ¹Ý TTF ±Û²Ã À¯ÇüÀ¸·Î ¾²ÀÌ´Â °æ¿ì°¡ ¸¹½À´Ï´Ù.
            hwp.HParameterSet.HCharShape.FontTypeHangul := 1
            hwp.HParameterSet.HCharShape.FontTypeLatin := 1
            hwp.HParameterSet.HCharShape.FontTypeHanja := 1
            hwp.HParameterSet.HCharShape.FontTypeJapanese := 1
            hwp.HParameterSet.HCharShape.FontTypeOther := 1
            hwp.HParameterSet.HCharShape.FontTypeSymbol := 1
            hwp.HParameterSet.HCharShape.FontTypeUser := 1

            hwp.HParameterSet.HCharShape.Height := 1200
        }

        try
        {
            hwp.HParameterSet.HCharShape.SetItem("FaceNameHangul", "±¼¸²")
            hwp.HParameterSet.HCharShape.SetItem("FaceNameLatin", "±¼¸²")
            hwp.HParameterSet.HCharShape.SetItem("FaceNameHanja", "±¼¸²")
            hwp.HParameterSet.HCharShape.SetItem("FaceNameJapanese", "±¼¸²")
            hwp.HParameterSet.HCharShape.SetItem("FaceNameOther", "±¼¸²")
            hwp.HParameterSet.HCharShape.SetItem("FaceNameSymbol", "±¼¸²")
            hwp.HParameterSet.HCharShape.SetItem("FaceNameUser", "±¼¸²")
            hwp.HParameterSet.HCharShape.SetItem("Height", 1200)
        }

        hwp.HAction.Execute("CharShape", hwp.HParameterSet.HCharShape.HSet)

        ; ÇÑ±Û/HWP¿¡¼­ ¹®´ÜÀ» ¿ÞÂÊ Á¤·Ä + ³»¾î¾²±â 17pt·Î º¸Á¤ÇÕ´Ï´Ù.
        ; ¼±ÅÃµÈ ÀüÃ¼ ¿µ¿ª¿¡ Àû¿ëµÇ¸ç, ½ÇÆÐÇØµµ ±Û²Ã Àû¿ë ±â´ÉÀº À¯ÁöµË´Ï´Ù.
        try
        {
            hwp.HAction.GetDefault("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)

            ; ¿ÞÂÊ Á¤·Ä: HWP ¹öÀü¿¡ µû¶ó Á÷Á¢ ´ëÀÔ/SetItemÀ» ¸ðµÎ ½ÃµµÇÕ´Ï´Ù.
            try
                hwp.HParameterSet.HParaShape.AlignType := 0
            try
                hwp.HParameterSet.HParaShape.SetItem("AlignType", 0)

            ; ³»¾î¾²±â 17pt: 1pt ¡Ö 100 HWPUnit ÀÌ¹Ç·Î 17pt ¡Ö 1700
            ; LeftMargin 17pt + Indent -17pt Á¶ÇÕÀ¸·Î µÑÂ° ÁÙÀÌ ±ÛÀÚ ½ÃÀÛÁ¡¿¡ ¿Àµµ·Ï º¸Á¤ÇÕ´Ï´Ù.
            hang := 1700
            try
            {
                hwp.HParameterSet.HParaShape.LeftMargin := hang
                hwp.HParameterSet.HParaShape.Indent := -hang
            }
            try
            {
                hwp.HParameterSet.HParaShape.SetItem("LeftMargin", hang)
                hwp.HParameterSet.HParaShape.SetItem("Indent", -hang)
            }

            hwp.HAction.Execute("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)

            ; ¹®´Ü¸ð¾ç Àû¿ë ÈÄ ÀÏºÎ HWP/ODT È¯°æ¿¡¼­ ±Û²ÃÀÌ ´Ù½Ã Èçµé¸®´Â °æ¿ì°¡ ÀÖ¾î
            ; ¸¶Áö¸· ´Ü°è¿¡¼­ ±¼¸² 12pt ±ÛÀÚ¸ð¾çÀ» ÇÑ ¹ø ´õ Àû¿ëÇÕ´Ï´Ù.
            try
                hwp.HAction.Execute("CharShape", hwp.HParameterSet.HCharShape.HSet)
        }

        ; ¼±ÅÃ »óÅÂ ÇØÁ¦: ¹®¼­ ³¡À¸·Î ÀÌµ¿
        try
            hwp.HAction.Run("MoveDocEnd")
        catch
            Send, {Right}
    }
    catch
    {
        return
    }
}



; =========================================================
; Æ®·¹ÀÌ ¸Þ´º: SSOK ÀÚµ¿½ÇÇà ÇØÁ¦ / Á¾·á º¸Á¶
; - »èÁ¦´Â ÆÄÀÏ »èÁ¦°¡ ¾Æ´Ï¶ó Windows ½ÃÀÛ ½Ã ¸ÅÀÏ ÀÚµ¿½ÇÇà µî·ÏÀ» ÇØÁ¦ÇÏ´Â ÀÇ¹Ì
; =========================================================
SSOK_TrayOpenFolder:
    Run, %A_ScriptDir%
return

SSOK_TrayDisableAutoRun:
    SSOK_UnregisterAutoRun()
    SSOK_CleanOldStartupLinks()
    MsgBox, 64, SSOK, ÀÚµ¿½ÇÇà µî·ÏÀ» ÇØÁ¦Çß½À´Ï´Ù.
return

SSOK_TrayPrepareMoveOrDelete:
SSOK_DeleteDailyAutoRun:
    ; Windows ½ÃÀÛ ½Ã ¸ÅÀÏ ÀÚµ¿½ÇÇàµÇ´Â µî·Ï¸¸ ÇØÁ¦ÇÕ´Ï´Ù.
    SSOK_UnregisterAutoRun()
    SSOK_CleanOldStartupLinks()
    ToolTip, % "ÇÁ·Î±×·¥À» Á¾·áÇÏ°í, ÀÚµ¿ ½ÇÇà µî·Ïµµ ÇØÁ¦ÇÕ´Ï´Ù."
    Sleep, 900
    ToolTip
return

SSOK_TrayExit:
    Gosub, SSOK_ExitApplicationNow
return

SSOK_UnregisterAutoRun()
{
    runKey := "Software\Microsoft\Windows\CurrentVersion\Run"
    ; ÇöÀç/±¸¹öÀü SSOK ¹× °ú°Å SJOffice ÀÚµ¿½ÇÇà°ªÀ» ¸ðµÎ Á¤¸®ÇÕ´Ï´Ù.
    RegDelete, HKCU, %runKey%, SSOK_SejongSmartOneKey
    RegDelete, HKCU, %runKey%, SSOK
    RegDelete, HKCU, %runKey%, SSOK_Sejong
    RegDelete, HKCU, %runKey%, SejongOneKey
    RegDelete, HKCU, %runKey%, Sejong One Key K-Edufine
    RegDelete, HKCU, %runKey%, K-Edufine SSOK
    RegDelete, HKCU, %runKey%, ½î¿Á
    RegDelete, HKCU, %runKey%, SJOffice
    RegDelete, HKCU, %runKey%, sjoffice
    RegDelete, HKCU, %runKey%, SJOffice_Sejong
    RegDelete, HKCU, %runKey%, SejongOffice
    RegDelete, HKCU, %runKey%, ¼¼Á¾¿ÀÇÇ½º
}

SSOK_UninstallAutoRunAndExit()
{
    ; UninstallÀº ÆÄÀÏ »èÁ¦°¡ ¾Æ´Ï¶ó PC ºÎÆÃ ½Ã ÀÚµ¿½ÇÇàµÇÁö ¾Ê°Ô Á¤¸®ÇÏ´Â ÀÇ¹ÌÀÔ´Ï´Ù.
    ; ½ÇÇà ÆÄÀÏ/½ºÅ©¸³Æ®¿Í »ç¿ëÀÚ ¼³Á¤ ÆÄÀÏÀº ±×´ë·Î µÓ´Ï´Ù.
    SSOK_UnregisterAutoRun()
    SSOK_CleanOldStartupLinks()
    SSOK_ClearPowerSchedule()
    ExitApp
}

SSOK_ClearPowerSchedule()
{
    SetTimer, SSOK_CheckPowerOffSchedule, Off
    SSOK_DeleteWakeTask()
    IniDelete, %SSOK_IniFile%, PowerSchedule
}

; =========================================================
; SSOK EXE ¼³Ä¡/ÀÚµ¿½ÇÇà/¾÷µ¥ÀÌÆ® °ü¸®
; =========================================================
SSOK_RelaunchFromCDriveInstall:
    ; AHK ¹èÆ÷¿¡¼­´Â C:\SSOK\ssok.exe·Î º¹»ç/Àç½ÇÇàÇÏÁö ¾Ê½À´Ï´Ù.
    ; ÇöÀç ½ÇÇà ÁßÀÎ ssok.ahk ÀÚÃ¼¸¦ »ç¿ëÇÕ´Ï´Ù.
return

SSOK_GetCDriveInstallDir()
{
    return "C:\SSOK"
}

SSOK_GetRuntimeConfigDir()
{
    if (A_IsCompiled)
        return SSOK_GetCDriveInstallDir()
    return A_ScriptDir
}


SSOK_PrepareFreshMainLaunch:
    if (A_IsCompiled)
    {
        SSOK_CloseOldSsokProcesses(A_ScriptFullPath)
        SSOK_CloseOldAhkProcesses(A_ScriptFullPath)
    }
    else
        SSOK_CloseOldAhkProcesses(A_ScriptFullPath)
return



SSOK_StartupInstallAndAutoRun:
    ; =========================================================
    ; AHK(.ahk) ÀÚµ¿½ÇÇà
    ; - EXE ¼³Ä¡/º¹»ç/Àç½ÇÇàÀº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    ; - Windows ½ÃÀÛÇÁ·Î±×·¥¿¡ "AutoHotkey.exe + ÇöÀç ssok.ahk"¸¦ µî·ÏÇÕ´Ï´Ù.
    ; - »ç¿ëÀÚ°¡ [Á¾·á]¸¦ ´©¸¥ °æ¿ì¿¡¸¸ SSOK_DeleteDailyAutoRun¿¡¼­ µî·ÏÀ» ÇØÁ¦ÇÕ´Ï´Ù.
    ; - Windows Á¾·á/ÀçºÎÆÃÀ¸·Î ÇÁ·Î±×·¥ÀÌ Á¾·áµÇ´Â °æ¿ì¿¡´Â µî·ÏÀ» À¯ÁöÇÏ¹Ç·Î
    ;   ´ÙÀ½ Windows ½ÃÀÛ ¶§ ssok.ahk°¡ ÀÚµ¿À¸·Î ´Ù½Ã ½ÇÇàµË´Ï´Ù.
    ; =========================================================
    SSOK_CleanOldStartupLinks()
    startupOk := SSOK_RegisterStartupShortcut(A_ScriptFullPath, false)

    ; ½ÃÀÛÇÁ·Î±×·¥ ¹Ù·Î°¡±â »ý¼º¿¡ ½ÇÆÐÇÑ °æ¿ì¿¡¸¸ HKCU\RunÀ» º¸Á¶ ÀÚµ¿½ÇÇàÀ¸·Î »ç¿ëÇÕ´Ï´Ù.
    ; ´ë»óÀº µ¿ÀÏÇÏ°Ô ÇöÀç ssok.ahkÀÌ¸ç EXE¸¦ »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    if (!startupOk)
        SSOK_RegisterAhkRunKey(A_ScriptFullPath)

    ; Áßº¹ ½ÇÇàµÇ¾î ÀÖ´Â ÀÌÀü ssok.ahk¸¸ Á¤¸®ÇÕ´Ï´Ù.
    SSOK_CloseOldAhkProcesses(A_ScriptFullPath)
    ; Ensure desktop shortcut with ssok.ico exists
    SSOK_EnsureDesktopShortcut(A_ScriptFullPath)
return

SSOK_RegisterStartupShortcut(targetPath, isExe := false)
{
    if (!FileExist(targetPath))
        return false

    startupDir := A_Startup
    if (!FileExist(startupDir))
        FileCreateDir, %startupDir%

    linkPath := startupDir . "\SSOK_SejongSmartOneKey.lnk"

    ; ÇöÀç SSOK´Â EXE ¹èÆ÷°¡ ¾Æ´Ï¶ó .ahk ¹èÆ÷¸¦ »ç¿ëÇÕ´Ï´Ù.
    ; AutoHotkey ½ÇÇà ÆÄÀÏÀ» TargetÀ¸·Î ÇÏ°í ssok.ahk¸¦ Arguments·Î Àü´ÞÇÕ´Ï´Ù.
    if (!isExe)
    {
        ahkPath := A_AhkPath
        if (!FileExist(ahkPath))
            return false

        args := Chr(34) . targetPath . Chr(34)
        FileCreateShortcut, %ahkPath%, %linkPath%, %A_ScriptDir%, %args%, SSOK ÀÚµ¿½ÇÇà
    }
    else
    {
        ; ±¸Çü È£Ãâ È£È¯¿ë. ÇöÀç ¹èÆ÷¿¡¼­´Â »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
        args := "/installed"
        FileCreateShortcut, %targetPath%, %linkPath%, %A_ScriptDir%, %args%, SSOK ÀÚµ¿½ÇÇà
    }

    if (ErrorLevel)
        return false

    return FileExist(linkPath) ? true : false
}

SSOK_EnsureDesktopShortcut(targetPath := "")
{
    if (targetPath = "")
        targetPath := A_ScriptFullPath

    desktopDir := A_Desktop
    if (!FileExist(desktopDir))
    {
        RegRead, regDesk, HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders, Desktop
        if (regDesk != "")
        {
            Transform, regDesk, Deref, %regDesk%
            if (FileExist(regDesk))
                desktopDir := regDesk
        }
    }

    if (!FileExist(desktopDir))
        return false

    linkPath := desktopDir . "\SSOK.lnk"

    ahkPath := A_AhkPath
    if (!FileExist(ahkPath))
        return false

    icoPath := A_ScriptDir . "\ssok.ico"
    if (!FileExist(icoPath))
        icoPath := ahkPath

    args := Chr(34) . targetPath . Chr(34)

    FileCreateShortcut, %ahkPath%, %linkPath%, %A_ScriptDir%, %args%, SSOK, %icoPath%
    if (ErrorLevel)
        return false

    return FileExist(linkPath) ? true : false
}

SSOK_RegisterAhkRunKey(targetPath)
{
    if (!FileExist(targetPath))
        return false

    runKey := "Software\Microsoft\Windows\CurrentVersion\Run"
    command := Chr(34) . A_AhkPath . Chr(34) . " " . Chr(34) . targetPath . Chr(34)

    RegWrite, REG_SZ, HKCU, %runKey%, SSOK_SejongSmartOneKey, %command%
    if (ErrorLevel)
        return false

    return true
}

SSOK_CleanOldStartupLinks()
{
    startupDir := A_Startup
    patterns := []
    patterns.Push("SSOK*.lnk")
    patterns.Push("ssok*.lnk")
    patterns.Push("½î¿Á*.lnk")
    patterns.Push("Sejong*.lnk")
    patterns.Push("K-Edufine*.lnk")
    patterns.Push("SJOffice*.lnk")
    patterns.Push("sjoffice*.lnk")
    patterns.Push("¼¼Á¾¿ÀÇÇ½º*.lnk")

    for idx, pat in patterns
    {
        Loop, Files, %startupDir%\%pat%, F
            FileDelete, %A_LoopFileFullPath%
    }
}

SSOK_DeleteOldLocalAppDataInstall(currentExe)
{
    oldDir := A_LocalAppData . "\SSOK"

    ; ÇöÀç ½ÇÇà ÆÄÀÏÀÌ ¿¹Àü ¼³Ä¡ Æú´õ ¾È¿¡ ÀÖ´Â °æ¿ì¿¡´Â ÀÚ±â ÀÚ½ÅÀ» Áö¿ìÁö ¾Ê½À´Ï´Ù.
    if (SSOK_NormalizePath(currentExe) = SSOK_NormalizePath(oldDir . "\ssok.exe"))
        return

    if (!FileExist(oldDir))
        return

    Loop, Files, %oldDir%\*.exe, F
        FileDelete, %A_LoopFileFullPath%

    Loop, Files, %oldDir%\*.ahk, F
        FileDelete, %A_LoopFileFullPath%

    FileRemoveDir, %oldDir%, 0
}


SSOK_DeleteFileWithRetry(filePath, attempts := 8, delayMs := 150)
{
    if (!FileExist(filePath))
        return true

    Loop, %attempts%
    {
        FileDelete, %filePath%
        if (!FileExist(filePath))
            return true
        Sleep, %delayMs%
    }

    return !FileExist(filePath)
}


SSOK_CloseProcessGracefully(pid, waitSeconds := 1)
{
    if (pid = "")
        return false

    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On
    WinClose, ahk_pid %pid%
    WinWaitClose, ahk_pid %pid%,, %waitSeconds%
    DetectHiddenWindows, %dhw%

    Process, Exist, %pid%
    if (ErrorLevel = 0)
        return true

    Process, Close, %pid%
    Sleep, 150
    Process, Exist, %pid%
    return (ErrorLevel = 0)
}

SSOK_CloseOldSsokProcesses(currentExe)
{
    currentPid := DllCall("GetCurrentProcessId")

    try
    {
        wmi := ComObjGet("winmgmts:")
        for proc in wmi.ExecQuery("Select ProcessId, ExecutablePath From Win32_Process Where Name='ssok.exe'")
        {
            thisPid := proc.ProcessId + 0
            if (thisPid = currentPid || thisPid = DllCall("GetCurrentProcessId", "UInt"))
                continue

            SSOK_CloseProcessGracefully(proc.ProcessId)
        }
    }
}

SSOK_CloseOldAhkProcesses(currentPath)
{
    normalizedCurrent := SSOK_NormalizePath(currentPath)
    currentPid := DllCall("GetCurrentProcessId", "UInt")

    try
    {
        wmi := ComObjGet("winmgmts:")
        for proc in wmi.ExecQuery("Select ProcessId, Name, ExecutablePath, CommandLine From Win32_Process Where Name='AutoHotkey.exe' Or Name='AutoHotkeyU32.exe' Or Name='AutoHotkeyU64.exe'")
        {
            thisPid := proc.ProcessId + 0
            if (thisPid = currentPid || thisPid = DllCall("GetCurrentProcessId", "UInt"))
                continue

            cmd := SSOK_NormalizePath(proc.CommandLine)
            if (cmd = "")
                continue

            ; ¿¹Àü ssok.ahk°¡ AutoHotkey·Î ½ÇÇà ÁßÀÌ¸é Á¾·áÇÕ´Ï´Ù.
            ; ´Ü, ÇöÀç Å×½ºÆ® ½ÇÇà ÁßÀÎ ÀÚ±â ÀÚ½ÅÀº Á¾·áÇÏÁö ¾Ê½À´Ï´Ù.
            if (InStr(cmd, normalizedCurrent) || InStr(cmd, "ssok.ahk"))
                SSOK_CloseProcessGracefully(proc.ProcessId)
        }
    }
}

SSOK_CloseProcessByPath(exePath)
{
    normalizedTarget := SSOK_NormalizePath(exePath)
    currentPid := DllCall("GetCurrentProcessId")

    try
    {
        wmi := ComObjGet("winmgmts:")
        for proc in wmi.ExecQuery("Select ProcessId, ExecutablePath From Win32_Process Where Name='ssok.exe'")
        {
            if (proc.ProcessId != currentPid && SSOK_NormalizePath(proc.ExecutablePath) = normalizedTarget)
                SSOK_CloseProcessGracefully(proc.ProcessId)
        }
    }
}

SSOK_NormalizePath(path)
{
    StringLower, out, path
    return out
}



; ===== * ½ÃÀÛ ¹®Àå Áß°íµñ 10 Àû¿ë =====
; ÅØ½ºÆ®¿¡ * ·Î ½ÃÀÛÇÏ´Â ÁÙÀÌ ÀÖ´ÂÁö È®ÀÎÇÕ´Ï´Ù.
DOC_HasStarLine(text)
{
    Loop, Parse, text, `n, `r
    {
        if RegExMatch(A_LoopField, "^\*")
            return true
    }
    return false
}

; HWP COM ¹æ½ÄÀ¸·Î * ½ÃÀÛ ÁÙ¿¡ HYÁß°íµñ 10pt + µé¿©¾²±â¸¦ Àû¿ëÇÕ´Ï´Ù.
; ÀüÃ¼ ¼­½Ä Àû¿ë ÈÄ * ÁÙ¸¸ Ä¿¼­·Î Ã£¾Æ ´Ù½Ã ¼­½ÄÀ» µ¤¾î¾º¿ó´Ï´Ù.
DOC_HwpApplyStarLineCharShape(hwp, text)
{
    try
    {
        ; ¹®¼­ Ã³À½À¸·Î ÀÌµ¿
        hwp.HAction.Run("MoveDocBegin")
        Sleep, 50

        Loop, Parse, text, `n, `r
        {
            lineText := A_LoopField
            if !RegExMatch(lineText, "^\*\s")
                continue

            ; * ·Î ½ÃÀÛÇÏ´Â ÁÙ Ã£±â: FindReplace·Î ÁÙ Å½»ö
            hwp.HAction.GetDefault("Find", hwp.HParameterSet.HFindReplace.HSet)
            try
                hwp.HParameterSet.HFindReplace.FindString := SubStr(lineText, 1, 10)
            try
                hwp.HParameterSet.HFindReplace.SetItem("FindString", SubStr(lineText, 1, 10))
            try
                hwp.HParameterSet.HFindReplace.Direction := 1
            try
                hwp.HParameterSet.HFindReplace.SetItem("Direction", 1)
            hwp.HAction.Execute("Find", hwp.HParameterSet.HFindReplace.HSet)
            Sleep, 30

            ; Ã£Àº À§Ä¡¿¡¼­ ÇöÀç ÁÙ ÀüÃ¼ ¼±ÅÃ
            hwp.HAction.Run("SelectLine")
            Sleep, 30

            ; HYÁß°íµñ 10pt Àû¿ë
            hwp.HAction.GetDefault("CharShape", hwp.HParameterSet.HCharShape.HSet)
            try
            {
                hwp.HParameterSet.HCharShape.FaceNameHangul := "HYÁß°íµñ"
                hwp.HParameterSet.HCharShape.FaceNameLatin  := "HYÁß°íµñ"
                hwp.HParameterSet.HCharShape.Height         := 1000
            }
            try
            {
                hwp.HParameterSet.HCharShape.SetItem("FaceNameHangul", "HYÁß°íµñ")
                hwp.HParameterSet.HCharShape.SetItem("FaceNameLatin",  "HYÁß°íµñ")
                hwp.HParameterSet.HCharShape.SetItem("Height",         1000)
            }
            hwp.HAction.Execute("CharShape", hwp.HParameterSet.HCharShape.HSet)
            Sleep, 30

            ; ¹®´Ü µé¿©¾²±â Àû¿ë (¿ÞÂÊ ¿©¹é 10pt ¡Ö 1000 HWPUnit)
            hwp.HAction.GetDefault("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)
            try
                hwp.HParameterSet.HParaShape.LeftMargin := 1000
            try
                hwp.HParameterSet.HParaShape.SetItem("LeftMargin", 1000)
            hwp.HAction.Execute("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)
            Sleep, 30
        }

        ; ¹®¼­ ³¡À¸·Î ÀÌµ¿ÇÏ¿© ¼±ÅÃ ÇØÁ¦
        hwp.HAction.Run("MoveDocEnd")
    }
    catch
    {
        ; ½ÇÆÐÇØµµ ÀüÃ¼ ¼­½ÄÀº À¯ÁöµÇ¹Ç·Î ¹«½ÃÇÕ´Ï´Ù.
    }
}
SSOK_ACC_OpenFromMenu:
    SSOK_ACC_ShowMain()
return

SSOK_ACC_Search:
    Gui, SSOKACC:Submit, NoHide
    SSOK_ACC_RunSearch(SSOK_ACC_Query)
return

SSOK_WRK_Search:
    Gui, SSOKACC:Submit, NoHide
    SSOK_WRK_RunSearch(SSOK_WRK_Query)
return

; =========================================================
; SSOK ±³À°Á¤º¸ - ³ªÀÌ½º ±³À°Á¤º¸ °³¹æ Æ÷ÅÐ OPEN API
; ¸ÞÀÎ °Ë»öÄ­: ÇÐ±³¸í °Ë»ö -> ÇÐ±³ ¼±ÅÃ -> ÇÐ±³Á¤º¸/½Ä´Ü/½Ã°£Ç¥/ÇÐ»çÀÏÁ¤/ÇÐ±ÞÁ¤º¸
; °üÇÒ ±³À°Ã»: ±³À°Ã»/±³À°Áö¿øÃ»/ÇÐ±³±Þ ¼±ÅÃ -> °üÇÒ ÇÐ±³ ¸ñ·Ï
; =========================================================
SSOK_EDU_OpenOrgPicker:
    SSOK_EDU_ShowOrgPicker()
return

SSOK_EDU_OrgViewSchool:
    SSOK_EDU_SetOrgViewMode("school")
return

SSOK_EDU_OrgViewOffice:
    SSOK_EDU_SetOrgViewMode("office")
return

SSOK_EDU_OrgOfficeChanged:
    if (SSOK_EDU_OrgViewMode = "office")
        return
    SSOK_EDU_OrgSearch := ""
    SSOK_EDU_OrgSearchMode := "office"
    SSOK_EDU_OrgGlobalResults := []
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgSearch,
    SSOK_EDU_LoadOrgSchools()
return

SSOK_EDU_OrgSupportChanged:
    if (SSOK_EDU_OrgViewMode != "office")
        SSOK_EDU_RefreshOrgSchoolList()
return

SSOK_EDU_OrgKindChanged:
    if (SSOK_EDU_OrgViewMode != "office")
        SSOK_EDU_RefreshOrgSchoolList()
return

SSOK_EDU_OrgSearchChanged:
    SetTimer, SSOK_EDU_OrgGlobalSearchTimer, Off
    SetTimer, SSOK_EDU_OrgGlobalSearchTimer, -350
return

SSOK_EDU_OrgGlobalSearchTimer:
    SSOK_EDU_ApplyOrgGlobalSearch()
return

SSOK_EDU_ClassCountPoll:
    SSOK_EDU_PollClassCountRequests()
return

SSOK_EDU_OrgExportExcel:
    SSOK_EDU_ExportOrgSchoolsExcel()
return

SSOK_EDU_OrgSchoolListEvent:
    if (A_GuiEvent = "DoubleClick" && A_EventInfo > 0)
        SSOK_EDU_SelectOrgSchoolRow(A_EventInfo)
return

SSOK_EDU_OrgOfficeListEvent:
return

SSOK_EDU_OrgSelectSchool:
    Gui, SSOKEDUOrg:Default
    Gui, ListView, SSOK_EDU_OrgSchoolList
    row := LV_GetNext(0, "F")
    if (row < 1)
        row := LV_GetNext()
    if (row < 1)
    {
        MsgBox, 48, SSOK ±³À°Á¤º¸, ÇÐ±³¸¦ ÇÏ³ª ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_EDU_SelectOrgSchoolRow(row)
return

SSOK_EDU_OrgGuiClose:
SSOK_EDU_OrgGuiEscape:
    SetTimer, SSOK_EDU_OrgGlobalSearchTimer, Off
    SSOK_EDU_CancelClassCountLoad()
    Gui, SSOKEDUOrg:Destroy
return

SSOK_EDU_SchoolListEvent:
    if (A_GuiEvent = "DoubleClick" && A_EventInfo > 0)
        SSOK_EDU_SelectSchoolRow(A_EventInfo)
return

SSOK_EDU_SelectSchoolButton:
    Gui, SSOKEDUSchool:Default
    Gui, ListView, SSOK_EDU_SchoolList
    row := LV_GetNext(0, "F")
    if (row < 1)
        row := LV_GetNext()
    if (row < 1)
    {
        MsgBox, 48, SSOK ±³À°Á¤º¸, ÇÐ±³¸¦ ÇÏ³ª ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_EDU_SelectSchoolRow(row)
return

SSOK_EDU_SchoolGuiClose:
SSOK_EDU_SchoolGuiEscape:
    Gui, SSOKEDUSchool:Destroy
return

SSOK_EDU_GuiClose:
SSOK_EDU_GuiEscape:
    Gui, SSOKEDU:Destroy
return

SSOK_EDU_MealPrev:
    SSOK_EDU_MealDate := SSOK_EDU_ShiftDate(SSOK_EDU_MealDate, -1)
    SSOK_EDU_LoadMeal()
return

SSOK_EDU_MealToday:
    SSOK_EDU_MealDate := A_YYYY . A_MM . A_DD
    SSOK_EDU_LoadMeal()
return

SSOK_EDU_MealNext:
    SSOK_EDU_MealDate := SSOK_EDU_ShiftDate(SSOK_EDU_MealDate, 1)
    SSOK_EDU_LoadMeal()
return

SSOK_EDU_TTPrev:
    Gui, SSOKEDU:Submit, NoHide
    SSOK_EDU_TTDate := SSOK_EDU_ShiftDate(SSOK_EDU_NormalizeDate(SSOK_EDU_TTDate), -1)
    GuiControl, SSOKEDU:, SSOK_EDU_TTDate, %SSOK_EDU_TTDate%
    SSOK_EDU_LoadTimetable()
return

SSOK_EDU_TTToday:
    SSOK_EDU_TTDate := A_YYYY . A_MM . A_DD
    GuiControl, SSOKEDU:, SSOK_EDU_TTDate, %SSOK_EDU_TTDate%
    SSOK_EDU_LoadTimetable()
return

SSOK_EDU_TTNext:
    Gui, SSOKEDU:Submit, NoHide
    SSOK_EDU_TTDate := SSOK_EDU_ShiftDate(SSOK_EDU_NormalizeDate(SSOK_EDU_TTDate), 1)
    GuiControl, SSOKEDU:, SSOK_EDU_TTDate, %SSOK_EDU_TTDate%
    SSOK_EDU_LoadTimetable()
return

SSOK_EDU_TTLoad:
    Gui, SSOKEDU:Submit, NoHide
    SSOK_EDU_LoadTimetable()
return

SSOK_EDU_ClassLoad:
    Gui, SSOKEDU:Submit, NoHide
    SSOK_EDU_LoadClassInfo()
return

SSOK_EDU_SchedulePrev:
    SSOK_EDU_ScheduleMonth := SSOK_EDU_ShiftMonth(SSOK_EDU_ScheduleMonth, -1)
    SSOK_EDU_LoadSchedule()
return

SSOK_EDU_ScheduleThis:
    SSOK_EDU_ScheduleMonth := A_YYYY . A_MM
    SSOK_EDU_LoadSchedule()
return

SSOK_EDU_ScheduleNext:
    SSOK_EDU_ScheduleMonth := SSOK_EDU_ShiftMonth(SSOK_EDU_ScheduleMonth, 1)
    SSOK_EDU_LoadSchedule()
return

SSOK_EDU_OpenHomepage:
    if (IsObject(SSOK_EDU_SelectedSchool) && Trim(SSOK_EDU_SelectedSchool.homepage) != "")
    {
        url := Trim(SSOK_EDU_SelectedSchool.homepage)
        if (!RegExMatch(url, "i)^https?://"))
            url := "https://" . url
        SSOK_OpenUrlPreferred(url)
    }
return

SSOK_EDU_OpenPortal:
    SSOK_OpenUrlPreferred("https://open.neis.go.kr/portal/data/dataset/searchDatasetPage.do")
return

SSOK_EDU_RunSearch(query)
{
    global SSOK_EDU_SchoolResults
    q := Trim(query)
    if (q = "")
        return

    if (q = "±³À°Ã»" || q = "Áö¿øÃ»" || q = "±³À°Áö¿øÃ»" || q = "°üÇÒ" || q = "°üÇÒÇÐ±³" || q = "°üÇÒ±³À°Ã»" || q = "°üÇÒ ±³À°Ã»")
    {
        SSOK_EDU_ShowOrgPicker()
        return
    }

    key := SSOK_EDU_GetApiKey()
    url := SSOK_EDU_BuildUrl("schoolInfo", Object("SCHUL_NM", q), 100, key)
    resp := SSOK_EDU_HttpGet(url)
    if (!resp.ok)
    {
        MsgBox, 48, SSOK ±³À°Á¤º¸, ³ªÀÌ½º ±³À°Á¤º¸ OPEN API¿¡ ¿¬°áÇÏÁö ¸øÇß½À´Ï´Ù.`n`nÀÎÅÍ³Ý ¿¬°á ¶Ç´Â ÀÎÁõÅ°¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä.
        return
    }

    results := SSOK_EDU_ParseSchools(resp.text)
    SSOK_EDU_SchoolResults := results
    if (!IsObject(results) || results.Length() < 1)
    {
        msg := SSOK_EDU_ParseResultMessage(resp.text)
        if (msg = "")
            msg := "°Ë»öµÈ ÇÐ±³°¡ ¾ø½À´Ï´Ù."
        MsgBox, 48, SSOK ±³À°Á¤º¸, %msg%
        return
    }

    if (results.Length() = 1)
    {
        SSOK_EDU_OpenSchool(results[1])
        return
    }
    SSOK_EDU_ShowSchoolPicker(results, q)
}

SSOK_EDU_ShowSchoolPicker(results, query)
{
    global SSOK_EDU_SchoolList, SSOK_EDU_SchoolResults
    SSOK_EDU_SchoolResults := results

    Gui, SSOKEDUSchool:Destroy
    Gui, SSOKEDUSchool:New, +Resize +MinSize700x360 +LabelSSOK_EDU_SchoolGui
    Gui, SSOKEDUSchool:Color, F7FBFF
    Gui, SSOKEDUSchool:Margin, 12, 12
    Gui, SSOKEDUSchool:Font, s10 bold c005BAC, Malgun Gothic
    Gui, SSOKEDUSchool:Add, Text, x12 y12 w760 h24, ÇÐ±³ °Ë»ö : %query%
    Gui, SSOKEDUSchool:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKEDUSchool:Add, ListView, x12 y42 w776 h280 vSSOK_EDU_SchoolList gSSOK_EDU_SchoolListEvent AltSubmit, ÇÐ±³¸í|ÇÐ±³±Þ|±³À°Ã»|Áö¿øÃ»|ÁÖ¼Ò
    Gui, SSOKEDUSchool:Default
    Gui, ListView, SSOK_EDU_SchoolList
    for idx, item in results
        LV_Add("", item.schoolName, item.kind, item.officeName, item.parentOrg, item.address)
    LV_ModifyCol(1, 155)
    LV_ModifyCol(2, 75)
    LV_ModifyCol(3, 130)
    LV_ModifyCol(4, 155)
    LV_ModifyCol(5, 260)
    if (results.Length() > 0)
        LV_Modify(1, "Select Focus Vis")
    Gui, SSOKEDUSchool:Add, Button, x688 y330 w100 h30 gSSOK_EDU_SelectSchoolButton Default, ¼±ÅÃ
    Gui, SSOKEDUSchool:Show, w800 h372, SSOK4edu ÇÐ±³ ¼±ÅÃ
}

SSOK_EDU_ShowOrgPicker(defaultOfficeCode := "", defaultSupport := "")
{
    global SSOK_EDU_SelectedSchool, SSOK_EDU_OrgOffice, SSOK_EDU_OrgSupport, SSOK_EDU_OrgKind
    global SSOK_EDU_OrgDefaultSupport, SSOK_EDU_OrgSchoolList, SSOK_EDU_OrgOfficeList, SSOK_EDU_OrgStatus, SSOK_EDU_OrgSearch
    global SSOK_EDU_OrgSearchMode, SSOK_EDU_OrgGlobalResults, SSOK_EDU_OrgViewMode
    global SSOK_EDU_OrgSelectSchoolBtn

    SSOK_EDU_OrgSearch := ""
    SSOK_EDU_OrgSearchMode := "office"
    SSOK_EDU_OrgGlobalResults := []
    SSOK_EDU_OrgViewMode := "school"

    if (defaultOfficeCode = "" && IsObject(SSOK_EDU_SelectedSchool))
    {
        defaultOfficeCode := SSOK_EDU_SelectedSchool.officeCode
        if (defaultSupport = "")
            defaultSupport := SSOK_EDU_SelectedSchool.parentOrg
    }
    if (defaultOfficeCode = "")
        defaultOfficeCode := "I10"

    idx := SSOK_EDU_GetOfficeIndexByCode(defaultOfficeCode)
    if (idx < 1)
        idx := 1
    SSOK_EDU_OrgDefaultSupport := defaultSupport
    officePipe := SSOK_EDU_GetOfficeNamesPipe()

    Gui, SSOKEDUOrg:Destroy
    Gui, SSOKEDUOrg:New, +Resize +MinSize1100x465 +LabelSSOK_EDU_OrgGui
    Gui, SSOKEDUOrg:Color, F7FBFF
    Gui, SSOKEDUOrg:Margin, 12, 12

    Gui, SSOKEDUOrg:Font, s9 bold c005BAC, Malgun Gothic
    Gui, SSOKEDUOrg:Add, Text, x12 y14 w38 h24 +0x200, ±¸ºÐ
    Gui, SSOKEDUOrg:Add, Button, x54 y10 w82 h26 gSSOK_EDU_OrgViewSchool, ÇÐ±³
    Gui, SSOKEDUOrg:Add, Button, x142 y10 w82 h26 gSSOK_EDU_OrgViewOffice, ±³À°Ã»

    Gui, SSOKEDUOrg:Font, s10 bold c005BAC, Malgun Gothic
    Gui, SSOKEDUOrg:Add, Text, x12 y48 w48 h20 +0x200, ±³À°Ã»
    Gui, SSOKEDUOrg:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKEDUOrg:Add, DropDownList, x62 y46 w230 h240 vSSOK_EDU_OrgOffice gSSOK_EDU_OrgOfficeChanged AltSubmit Choose%idx%, %officePipe%
    Gui, SSOKEDUOrg:Add, Text, x307 y48 w48 h20 +0x200, Áö¿øÃ»
    Gui, SSOKEDUOrg:Add, DropDownList, x357 y46 w270 h240 vSSOK_EDU_OrgSupport gSSOK_EDU_OrgSupportChanged, ±³À°Ã» ÀüÃ¼
    Gui, SSOKEDUOrg:Add, Text, x642 y48 w48 h20 +0x200, ÇÐ±³±Þ
    Gui, SSOKEDUOrg:Add, DropDownList, x692 y46 w120 h240 vSSOK_EDU_OrgKind gSSOK_EDU_OrgKindChanged, ÀüÃ¼
    Gui, SSOKEDUOrg:Font, s8 norm c4B5563, Malgun Gothic
    Gui, SSOKEDUOrg:Add, Text, x825 y48 w105 h20 vSSOK_EDU_OrgStatus +0x200, ÇÐ±³ ¸ñ·Ï ºÒ·¯¿À´Â Áß...
    Gui, SSOKEDUOrg:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKEDUOrg:Add, Text, x928 y48 w58 h20 +0x200, Àü±¹°Ë»ö
    Gui, SSOKEDUOrg:Add, Edit, x988 y44 w102 h26 vSSOK_EDU_OrgSearch gSSOK_EDU_OrgSearchChanged
    Gui, SSOKEDUOrg:Add, Button, x1098 y44 w92 h26 gSSOK_EDU_OrgExportExcel, ¿¢¼¿ ÀúÀå
    Gui, SSOKEDUOrg:Add, Button, x1196 y44 w100 h26 vSSOK_EDU_OrgSelectSchoolBtn gSSOK_EDU_OrgSelectSchool Default, ÇÐ±³ ¿­±â

    Gui, SSOKEDUOrg:Add, ListView, x12 y79 w1284 h395 vSSOK_EDU_OrgSchoolList gSSOK_EDU_OrgSchoolListEvent AltSubmit, ÇÐ±³¸í|ÇÐ±³±Þ|ÇÐ±Þ¼ö|¼³¸³¿¬µµ|Áö¿øÃ»|ÁÖ¼Ò|ÀüÈ­|ÆÑ½º|È¨ÆäÀÌÁö|ÇÐ±³ÄÚµå
    Gui, SSOKEDUOrg:Add, ListView, x12 y79 w1284 h395 vSSOK_EDU_OrgOfficeList gSSOK_EDU_OrgOfficeListEvent Hidden AltSubmit, ½Ã¡¤µµ±³À°Ã»|±¸ºÐ|±â°ü¸í|°üÇÒ ±¸¿ª|ÁÖ¼Ò|ÀüÈ­¹øÈ£|ÆÑ½º¹øÈ£|ÃâÃ³ URL
    OnMessage(0x202, "SSOK_EDU_OrgOfficeUrlClick")
    Gui, SSOKEDUOrg:Show, w1308 h486, SSOK4edu °üÇÒ ±³À°Ã»
    SSOK_EDU_LoadOrgSchools()
}

SSOK_EDU_SetOrgViewMode(mode)
{
    global SSOK_EDU_OrgViewMode, SSOK_EDU_OrgSearch, SSOK_EDU_OrgSearchMode, SSOK_EDU_OrgGlobalResults
    global SSOK_EDU_OrgOfficeRows

    if (mode != "office")
        mode := "school"

    SSOK_EDU_OrgViewMode := mode
    SetTimer, SSOK_EDU_OrgGlobalSearchTimer, Off
    SSOK_EDU_OrgSearch := ""
    SSOK_EDU_OrgSearchMode := "office"
    SSOK_EDU_OrgGlobalResults := []
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgSearch,

    if (mode = "office")
    {
        GuiControl, SSOKEDUOrg:Disable, SSOK_EDU_OrgOffice
        GuiControl, SSOKEDUOrg:Disable, SSOK_EDU_OrgSupport
        GuiControl, SSOKEDUOrg:Disable, SSOK_EDU_OrgKind
        GuiControl, SSOKEDUOrg:Disable, SSOK_EDU_OrgSelectSchoolBtn
        GuiControl, SSOKEDUOrg:Hide, SSOK_EDU_OrgSchoolList
        GuiControl, SSOKEDUOrg:Show, SSOK_EDU_OrgOfficeList

        if (!IsObject(SSOK_EDU_OrgOfficeRows))
            SSOK_EDU_OrgOfficeRows := SSOK_EDU_GetOrgOfficeDirectoryData()
        SSOK_EDU_RefreshOrgOfficeList()
    }
    else
    {
        GuiControl, SSOKEDUOrg:Enable, SSOK_EDU_OrgOffice
        GuiControl, SSOKEDUOrg:Enable, SSOK_EDU_OrgSupport
        GuiControl, SSOKEDUOrg:Enable, SSOK_EDU_OrgKind
        GuiControl, SSOKEDUOrg:Enable, SSOK_EDU_OrgSelectSchoolBtn
        GuiControl, SSOKEDUOrg:Hide, SSOK_EDU_OrgOfficeList
        GuiControl, SSOKEDUOrg:Show, SSOK_EDU_OrgSchoolList
        SSOK_EDU_RefreshOrgSchoolList()
    }
}

SSOK_EDU_ListViewHitColumn(lvHwnd)
{
    if (!lvHwnd)
        return 0

    MouseGetPos, mx, my
    VarSetCapacity(pt, 8, 0)
    NumPut(mx, pt, 0, "Int")
    NumPut(my, pt, 4, "Int")
    DllCall("ScreenToClient", "Ptr", lvHwnd, "Ptr", &pt)

    VarSetCapacity(hit, 24, 0)
    NumPut(NumGet(pt, 0, "Int"), hit, 0, "Int")
    NumPut(NumGet(pt, 4, "Int"), hit, 4, "Int")
    DllCall("SendMessage", "Ptr", lvHwnd, "UInt", 0x1039, "Ptr", 0, "Ptr", &hit, "Ptr")
    subItem := NumGet(hit, 16, "Int")
    return subItem + 1
}

SSOK_EDU_OrgOfficeUrlClick(wParam, lParam, msg, hwnd)
{
    global SSOK_EDU_OrgViewMode

    if (SSOK_EDU_OrgViewMode != "office")
        return

    Gui, SSOKEDUOrg:Default
    GuiControlGet, lvHwnd, Hwnd, SSOK_EDU_OrgOfficeList
    if (!lvHwnd || hwnd != lvHwnd)
        return

    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    VarSetCapacity(hit, 24, 0)
    NumPut(x, hit, 0, "Int")
    NumPut(y, hit, 4, "Int")
    DllCall("SendMessage", "Ptr", lvHwnd, "UInt", 0x1039, "Ptr", 0, "Ptr", &hit, "Ptr")

    row := NumGet(hit, 12, "Int") + 1
    col := NumGet(hit, 16, "Int") + 1
    if (row < 1 || col != 8)
        return

    Gui, ListView, SSOK_EDU_OrgOfficeList
    LV_GetText(url, row, 8)
    url := Trim(url)
    if (url = "")
        return

    if (!RegExMatch(url, "i)^https?://"))
        url := "https://" . url
    SSOK_OpenUrlPreferred(url)
}

SSOK_EDU_RefreshOrgOfficeList()
{
    global SSOK_EDU_OrgOfficeRows, SSOK_EDU_OrgOfficeList, SSOK_EDU_OrgSearch, SSOK_EDU_OrgStatus

    if (!IsObject(SSOK_EDU_OrgOfficeRows))
        SSOK_EDU_OrgOfficeRows := SSOK_EDU_GetOrgOfficeDirectoryData()

    Gui, SSOKEDUOrg:Submit, NoHide
    q := Trim(SSOK_EDU_OrgSearch)

    Gui, SSOKEDUOrg:Default
    Gui, ListView, SSOK_EDU_OrgOfficeList
    LV_Delete()

    count := 0
    for idx, item in SSOK_EDU_OrgOfficeRows
    {
        if (q != "")
        {
            hay := item[1] . "`n" . item[2] . "`n" . item[3] . "`n" . item[4] . "`n" . item[5] . "`n" . item[6] . "`n" . item[7] . "`n" . item[8]
            if (!InStr(hay, q))
                continue
        }

        LV_Add("", item[1], item[2], item[3], item[4], item[5], item[6], item[7], item[8])
        count++
    }

    LV_ModifyCol(1, 145)
    LV_ModifyCol(2, 80)
    LV_ModifyCol(3, 185)
    LV_ModifyCol(4, 155)
    LV_ModifyCol(5, 280)
    LV_ModifyCol(6, 110)
    LV_ModifyCol(7, 110)
    LV_ModifyCol(8, 310)

    if (count > 0)
        LV_Modify(1, "Select Focus Vis")

    status := (q = "") ? ("±³À°Ã» ÀÚ·á " . count . "°³") : ("±³À°Ã» °Ë»ö " . count . "°³")
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgStatus, %status%
}

SSOK_EDU_GetOrgOfficeDirectoryData()
{
    data := []
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "¼­¿ïÆ¯º°½Ã±³À°Ã»", "¼­¿ïÆ¯º°½Ã", "¼­¿ïÆ¯º°½Ã ¿ë»ê±¸ µÎÅÓ¹ÙÀ§·Î 27", "02-1396", "02-6907-2859", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ãµ¿ºÎ±³À°Áö¿øÃ»", "µ¿´ë¹®±¸, Áß¶û±¸", "¼­¿ïÆ¯º°½Ã µ¿´ë¹®±¸ Àü³ó·Î 168", "02-2217-7323", "02-2217-7330", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ã¼­ºÎ±³À°Áö¿øÃ»", "¸¶Æ÷±¸, ¼­´ë¹®±¸, ÀºÆò±¸", "¼­¿ïÆ¯º°½Ã ¼­´ë¹®±¸ ÀÌÈ­¿©´ë2±æ 15", "02-390-5500", "02-364-6057", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ã³²ºÎ±³À°Áö¿øÃ»", "¿µµîÆ÷±¸, ±¸·Î±¸, ±ÝÃµ±¸", "¼­¿ïÆ¯º°½Ã ¿µµîÆ÷±¸ ¹®·¡·Î 121", "02-2165-0200", "02-2632-4389", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½ÃºÏºÎ±³À°Áö¿øÃ»", "³ë¿ø±¸, µµºÀ±¸", "¼­¿ïÆ¯º°½Ã µµºÀ±¸ ³ëÇØ·Î 313", "02-3499-6990", "02-990-2360", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½ÃÁßºÎ±³À°Áö¿øÃ»", "Á¾·Î±¸, Áß±¸, ¿ë»ê±¸", "¼­¿ïÆ¯º°½Ã Á¾·Î±¸ ´ëÇÐ·Î 10", "02-708-6500", "02-708-6641", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ã°­µ¿¼ÛÆÄ±³À°Áö¿øÃ»", "°­µ¿±¸, ¼ÛÆÄ±¸", "¼­¿ïÆ¯º°½Ã ¼ÛÆÄ±¸ Àá½Ç·Î 26", "02-3434-4300", "02-424-3388", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ã°­¼­¾çÃµ±³À°Áö¿øÃ»", "°­¼­±¸, ¾çÃµ±¸", "¼­¿ïÆ¯º°½Ã ¾çÃµ±¸ ¿ùÁ¤·Î 269", "02-2600-0800", "02-2620-8312", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ã°­³²¼­ÃÊ±³À°Áö¿øÃ»", "°­³²±¸, ¼­ÃÊ±¸", "¼­¿ïÆ¯º°½Ã °­³²±¸ ¼±¸ª·Î116±æ 45", "02-545-1577", "02-3015-3420", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ãµ¿ÀÛ°ü¾Ç±³À°Áö¿øÃ»", "µ¿ÀÛ±¸, °ü¾Ç±¸", "¼­¿ïÆ¯º°½Ã µ¿ÀÛ±¸ Àå½Â¹è±â·Î10°¡±æ 35", "02-810-8300", "02-822-7004", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ã¼ºµ¿±¤Áø±³À°Áö¿øÃ»", "¼ºµ¿±¸, ±¤Áø±¸", "¼­¿ïÆ¯º°½Ã ¼ºµ¿±¸ °í»êÀÚ·Î 280", "02-2286-3694", "02-2281-3816", "https://www.sen.go.kr/"])
    data.Push(["¼­¿ïÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼­¿ïÆ¯º°½Ã¼ººÏ°­ºÏ±³À°Áö¿øÃ»", "¼ººÏ±¸, °­ºÏ±¸", "¼­¿ïÆ¯º°½Ã ¼ººÏ±¸ Á¾¾Ï·Î 208", "02-944-9383", "02-985-8361", "https://www.sen.go.kr/"])
    data.Push(["ºÎ»ê±¤¿ª½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "ºÎ»ê±¤¿ª½Ã±³À°Ã»", "ºÎ»ê±¤¿ª½Ã", "ºÎ»ê±¤¿ª½Ã ºÎ»êÁø±¸ È­Áö·Î 12", "051-860-0114", "051-860-0628", "https://www.pen.go.kr/main/main.do"])
    data.Push(["ºÎ»ê±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ºÎ»ê±¤¿ª½Ã¼­ºÎ±³À°Áö¿øÃ»", "¼­±¸, »çÇÏ±¸, ¿µµµ±¸, Áß±¸", "ºÎ»ê±¤¿ª½Ã ¼­±¸ ²É¸¶À»·Î 33", "051-250-0500", "051-246-1832", "https://home.pen.go.kr/seobu/main.do"])
    data.Push(["ºÎ»ê±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ºÎ»ê±¤¿ª½Ã³²ºÎ±³À°Áö¿øÃ»", "³²±¸, µ¿±¸, ºÎ»êÁø±¸", "ºÎ»ê±¤¿ª½Ã ³²±¸ ¸ø°ñ·Î 29", "051-640-0200", "051-637-8958", "https://home.pen.go.kr/nambu/main.do"])
    data.Push(["ºÎ»ê±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ºÎ»ê±¤¿ª½ÃºÏºÎ±³À°Áö¿øÃ»", "ºÏ±¸, »ç»ó±¸, °­¼­±¸", "ºÎ»ê±¤¿ª½Ã ºÏ±¸ ¹é¾ç´ë·Î1016¹ø´Ù±æ 44", "051-330-1200", "051-330-1338", "https://home.pen.go.kr/bukbu/"])
    data.Push(["ºÎ»ê±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ºÎ»ê±¤¿ª½Ãµ¿·¡±³À°Áö¿øÃ»", "µ¿·¡±¸, ±ÝÁ¤±¸, ¿¬Á¦±¸", "ºÎ»ê±¤¿ª½Ã µ¿·¡±¸ µ¿·¡·Î179¹ø±æ 31", "051-550-0114", "051-558-3869", "https://home.pen.go.kr/dongnae/main.do"])
    data.Push(["ºÎ»ê±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ºÎ»ê±¤¿ª½ÃÇØ¿î´ë±³À°Áö¿øÃ»", "ÇØ¿î´ë±¸, ¼ö¿µ±¸, ±âÀå±º", "ºÎ»ê±¤¿ª½Ã ÇØ¿î´ë±¸ ¼¼½Ç·Î 137", "051-709-0300", "051-709-0309", "https://home.pen.go.kr/haeundae/main.do"])
    data.Push(["´ë±¸±¤¿ª½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "´ë±¸±¤¿ª½Ã±³À°Ã»", "´ë±¸±¤¿ª½Ã", "´ë±¸±¤¿ª½Ã ¼ö¼º±¸ ¼ö¼º·Î76±æ 11", "053-231-0000", "053-757-8100", "https://www.dge.go.kr/main/main.do"])
    data.Push(["´ë±¸±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ë±¸±¤¿ª½Ãµ¿ºÎ±³À°Áö¿øÃ»", "µ¿±¸, ¼ö¼º±¸", "´ë±¸±¤¿ª½Ã Áß±¸ °ü´öÁ¤±æ 35", "053-232-0000", "053-255-5938", "https://www.dge.go.kr/dgdbe/main.do"])
    data.Push(["´ë±¸±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ë±¸±¤¿ª½Ã¼­ºÎ±³À°Áö¿øÃ»", "¼­±¸, ºÏ±¸", "´ë±¸±¤¿ª½Ã ¼­±¸ ¼­´ë±¸·Î3±æ 5", "053-233-0000", "053-522-5269", "https://www.dge.go.kr/dgsbe/main.do"])
    data.Push(["´ë±¸±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ë±¸±¤¿ª½Ã³²ºÎ±³À°Áö¿øÃ»", "Áß±¸, ³²±¸, ´Þ¼­±¸", "´ë±¸±¤¿ª½Ã ´Þ¼­±¸ ÇÐ»ê·Î 185", "053-234-0000", "053-234-0019", "https://www.dge.go.kr/dgnbe/main.do"])
    data.Push(["´ë±¸±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ë±¸±¤¿ª½Ã´Þ¼º±³À°Áö¿øÃ»", "´Þ¼º±º", "´ë±¸±¤¿ª½Ã ´Þ¼º±º ¿ÁÆ÷À¾ ºñ½½·Î 1934", "053-235-0000", "053-235-0019", "https://www.dge.go.kr/dgdse/main.do"])
    data.Push(["´ë±¸±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ë±¸±¤¿ª½Ã±ºÀ§±³À°Áö¿øÃ»", "±ºÀ§±º", "´ë±¸±¤¿ª½Ã ±ºÀ§±º ±ºÀ§À¾ ±ºÃ»·Î 204", "054-380-2200", "054-380-2219", "https://www.dge.go.kr/dggwe/main.do"])
    data.Push(["ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "ÀÎÃµ±¤¿ª½Ã", "ÀÎÃµ±¤¿ª½Ã ³²µ¿±¸ Á¤°¢·Î 9", "032-420-6526~7", "032-420-6537", "https://www.ice.go.kr/ice/main.do"])
    data.Push(["ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÀÎÃµ±¤¿ª½Ã³²ºÎ±³À°Áö¿øÃ»", "Á¦¹°Æ÷±¸, ¿µÁ¾±¸, ¹ÌÃßÈ¦±¸, ¿ËÁø±º", "ÀÎÃµ±¤¿ª½Ã Áß±¸ Â÷ÀÌ³ªÅ¸¿î·Î51¹ø±æ 45", "032-762-7361", "032-770-0119", "https://www.ice.go.kr/ice/main.do"])
    data.Push(["ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÀÎÃµ±¤¿ª½ÃºÏºÎ±³À°Áö¿øÃ»", "ºÎÆò±¸, °è¾ç±¸", "ÀÎÃµ±¤¿ª½Ã ºÎÆò±¸ ºÎÆò¹®È­·Î53¹ø±æ 35", "032-524-9631~2", "032-510-1539", "https://www.ice.go.kr/ice/main.do"])
    data.Push(["ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÀÎÃµ±¤¿ª½Ãµ¿ºÎ±³À°Áö¿øÃ»", "³²µ¿±¸, ¿¬¼ö±¸", "ÀÎÃµ±¤¿ª½Ã ³²µ¿±¸ ÀÎÁÖ´ë·Î 923", "032-460-6000", "032-460-6019", "https://www.ice.go.kr/ice/main.do"])
    data.Push(["ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÀÎÃµ±¤¿ª½Ã¼­ºÎ±³À°Áö¿øÃ»", "¼­ÇØ±¸, °Ë´Ü±¸", "ÀÎÃµ±¤¿ª½Ã ¼­±¸ °æ¸í´ë·Î 713", "032-560-6600", "032-560-6519", "https://www.ice.go.kr/ice/main.do"])
    data.Push(["ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÀÎÃµ±¤¿ª½Ã°­È­±³À°Áö¿øÃ»", "°­È­±º", "ÀÎÃµ±¤¿ª½Ã °­È­±º ºÒÀº¸é Áß¾Ó·Î 607", "032-930-7777", "032-937-0795", "https://www.ice.go.kr/ice/main.do"])
    data.Push(["´ëÀü±¤¿ª½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "´ëÀü±¤¿ª½Ã±³À°Ã»", "´ëÀü±¤¿ª½Ã", "´ëÀü±¤¿ª½Ã ¼­±¸ µÐ»ê·Î 89", "042-616-8900", "042-616-8579", "https://www.dje.go.kr/main.do?s=djeNew"])
    data.Push(["´ëÀü±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ëÀü±¤¿ª½Ãµ¿ºÎ±³À°Áö¿øÃ»", "µ¿±¸, Áß±¸, ´ë´ö±¸", "´ëÀü±¤¿ª½Ã Áß±¸ ¹®È­·Î234¹ø±æ 34", "042-229-1000", "042-229-1019", "https://www.dje.go.kr/"])
    data.Push(["´ëÀü±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ëÀü±¤¿ª½Ã¼­ºÎ±³À°Áö¿øÃ»", "¼­±¸, À¯¼º±¸", "´ëÀü±¤¿ª½Ã ¼­±¸ °è¹é·Î 1419", "042-530-1114", "042-530-1019", "https://www.dje.go.kr/"])
    data.Push(["¿ï»ê±¤¿ª½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "¿ï»ê±¤¿ª½Ã±³À°Ã»", "¿ï»ê±¤¿ª½Ã", "¿ï»ê±¤¿ª½Ã Áß±¸ ºÏºÎ¼øÈ¯µµ·Î 375", "052-210-5400", "052-210-5759", "https://use.go.kr/"])
    data.Push(["¿ï»ê±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¿ï»ê±¤¿ª½Ã°­ºÏ±³À°Áö¿øÃ»", "Áß±¸, ºÏ±¸, µ¿±¸", "¿ï»ê±¤¿ª½Ã ºÏ±¸ »ê¾÷·Î 1015", "052-219-5615", "052-219-5616", "https://use.go.kr/"])
    data.Push(["¿ï»ê±¤¿ª½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¿ï»ê±¤¿ª½Ã°­³²±³À°Áö¿øÃ»", "³²±¸, ¿ïÁÖ±º", "¿ï»ê±¤¿ª½Ã ³²±¸ ¿ùÆò·Î 87", "052-228-6666", "052-228-6667", "https://use.go.kr/"])
    data.Push(["¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»", "¼¼Á¾Æ¯º°ÀÚÄ¡½Ã", "¼¼Á¾Æ¯º°ÀÚÄ¡½Ã ÇÑ´©¸®´ë·Î 2154", "044-1396", "044-320-3198", "https://www.sje.go.kr/sje/main.do"])
    data.Push(["°æ±âµµ±³À°Ã»", "½Ãµµ±³À°Ã»", "°æ±âµµ±³À°Ã»(³²ºÎÃ»»ç)", "°æ±âµµ", "°æ±âµµ ¼ö¿ø½Ã ¿µÅë±¸ µµÃ»·Î 28 ", "031-249-0114", "031-259-5990", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "½Ãµµ±³À°Ã»", "°æ±âµµ±³À°Ã»(ºÏºÎÃ»»ç)", "°æ±âµµ", "°æ±âµµ ÀÇÁ¤ºÎ½Ã µ¿ÀÏ·Î 700", "031-249-0114", "031-821-2058", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¼ö¿ø±³À°Áö¿øÃ»", "¼ö¿ø½Ã", "°æ±âµµ ¼ö¿ø½Ã Àå¾È±¸ °æ¼ö´ë·Î 792", "031-250-1335", "031-246-3442", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¼º³²±³À°Áö¿øÃ»", "¼º³²½Ã", "°æ±âµµ ¼º³²½Ã ºÐ´ç±¸ ¾çÇö·Î 20", "031-780-2500", "031-781-2196", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¾È¾ç°úÃµ±³À°Áö¿øÃ»", "¾È¾ç½Ã, °úÃµ½Ã", "°æ±âµµ ¾È¾ç½Ã µ¿¾È±¸ °üÆò·Î 210", "031-380-7056", "031-386-9913", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµºÎÃµ±³À°Áö¿øÃ»", "ºÎÃµ½Ã", "°æ±âµµ ºÎÃµ½Ã °è³²·Î 219", "032-620-0112", "032-326-3107", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ±¤¸í±³À°Áö¿øÃ»", "±¤¸í½Ã", "°æ±âµµ ±¤¸í½Ã ±¤¸í·Î 777", "02-2610-0592", "02-2684-7353", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¾È»ê±³À°Áö¿øÃ»", "¾È»ê½Ã", "°æ±âµµ ¾È»ê½Ã »ó·Ï±¸ ¼®È£°ø¿ø·Î5±æ 8", "031-412-4621", "031-487-0040", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµÆòÅÃ±³À°Áö¿øÃ»", "ÆòÅÃ½Ã", "°æ±âµµ ÆòÅÃ½Ã ÆòÅÃ1·Î 80", "031-650-1218", "031-657-9118", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµµ¿µÎÃµ¾çÁÖ±³À°Áö¿øÃ»", "µ¿µÎÃµ½Ã, ¾çÁÖ½Ã", "°æ±âµµ µ¿µÎÃµ½Ã Áß¾Ó·Î 110-32", "031-860-4356", "031-864-4606", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ°í¾ç±³À°Áö¿øÃ»", "°í¾ç½Ã", "°æ±âµµ °í¾ç½Ã ÀÏ»êµ¿±¸ Áß¾Ó·Î 1296", "031-900-2800", "031-900-8095", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ±¸¸®³²¾çÁÖ±³À°Áö¿øÃ»", "±¸¸®½Ã, ³²¾çÁÖ½Ã", "°æ±âµµ ³²¾çÁÖ½Ã °æÃá·Î 520", "031-563-5191", "031-562-6947", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµÆÄÁÖ±³À°Áö¿øÃ»", "ÆÄÁÖ½Ã", "°æ±âµµ ÆÄÁÖ½Ã ±ÝÁ¤2±æ 55", "031-940-7114", "031-944-2340", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ±ºÆ÷ÀÇ¿Õ±³À°Áö¿øÃ»", "±ºÆ÷½Ã, ÀÇ¿Õ½Ã", "°æ±âµµ ±ºÆ÷½Ã Ã»¹é¸®±æ 17", "031-390-1101", "031-397-1324", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ±¤ÁÖÇÏ³²±³À°Áö¿øÃ»", "±¤ÁÖ½Ã, ÇÏ³²½Ã", "°æ±âµµ ±¤ÁÖ½Ã ±¤ÁÖ´ë·Î 178", "031-760-4000", "031-280-7288", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ±èÆ÷±³À°Áö¿øÃ»", "±èÆ÷½Ã", "°æ±âµµ ±èÆ÷½Ã ±èÆ÷ÇÑ°­11·Î 342", "031-980-1125", "031-984-6767", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµÈ­¼º¿À»ê±³À°Áö¿øÃ»", "È­¼º½Ã, ¿À»ê½Ã", "°æ±âµµ ¿À»ê½Ã ºÏ»ï¹Ì·Î 119", "031-371-0600", "031-371-0795", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ½ÃÈï±³À°Áö¿øÃ»", "½ÃÈï½Ã", "°æ±âµµ ½ÃÈï½Ã ¸¶À¯·Î446¹ø±æ 11-2", "031-488-2464", "031-488-2469", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¿ëÀÎ±³À°Áö¿øÃ»", "¿ëÀÎ½Ã", "°æ±âµµ ¿ëÀÎ½Ã Ã³ÀÎ±¸ ÁßºÎ´ë·Î1161¹ø±æ 69", "031-8020-9114", "031-8020-9117", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµÀÇÁ¤ºÎ±³À°Áö¿øÃ»", "ÀÇÁ¤ºÎ½Ã", "°æ±âµµ ÀÇÁ¤ºÎ½Ã °¡´É·Î136¹ø±æ 29", "031-8200-114", "031-842-2574", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµÀÌÃµ±³À°Áö¿øÃ»", "ÀÌÃµ½Ã", "°æ±âµµ ÀÌÃµ½Ã ÀÌ¼·´ëÃµ·Î1311¹ø±æ 18", "031-639-5694", "031-639-5695", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¾È¼º±³À°Áö¿øÃ»", "¾È¼º½Ã", "°æ±âµµ ¾È¼º½Ã ¸í·û±æ 82", "031-678-5258", "031-675-0177", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¾çÆò±³À°Áö¿øÃ»", "¾çÆò±º", "°æ±âµµ ¾çÆò±º ¾çÆòÀ¾ ¾ç±Ù°­º¯±æ 126", "031-770-5200", "031-770-5206", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¿©ÁÖ±³À°Áö¿øÃ»", "¿©ÁÖ½Ã", "°æ±âµµ ¿©ÁÖ½Ã Ã»½É·Î 181", "031-880-2308", "031-884-2396", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ¿¬Ãµ±³À°Áö¿øÃ»", "¿¬Ãµ±º", "°æ±âµµ ¿¬Ãµ±º ¿¬ÃµÀ¾ ¿¬Ãµ·Î 356-1", "031-834-1422", "031-834-1565", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµÆ÷Ãµ±³À°Áö¿øÃ»", "Æ÷Ãµ½Ã", "°æ±âµµ Æ÷Ãµ½Ã ±º³»¸é È£±¹·Î 1520", "031-539-0000", "031-8089-8190", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°æ±âµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ±âµµ°¡Æò±³À°Áö¿øÃ»", "°¡Æò±º", "°æ±âµµ °¡Æò±º °¡ÆòÀ¾ Çâ±³·Î 17", "031-580-5114", "031-581-0557", "https://www.goe.go.kr/goe/cm/cntnts/cntntsView.do?cntntsId=963&mi=10034"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "½Ãµµ±³À°Ã»", "°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "°­¿øÆ¯º°ÀÚÄ¡µµ", "°­¿øÆ¯º°ÀÚÄ¡µµ ÃáÃµ½Ã ¿µ¼­·Î 2854", "033-1396", "033-258-5138", "https://www.gwe.go.kr/"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÃáÃµ±³À°Áö¿øÃ»", "ÃáÃµ½Ã", "°­¿øÆ¯º°ÀÚÄ¡µµ ÃáÃµ½Ã µÕÁö±æ 56", "033-259-1500", "033-259-1670", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµ¿øÁÖ±³À°Áö¿øÃ»", "¿øÁÖ½Ã", "°­¿øÆ¯º°ÀÚÄ¡µµ ¿øÁÖ½Ã ´Ü±¸·Î 151", "033-760-5720", "033-764-4908", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµ°­¸ª±³À°Áö¿øÃ»", "°­¸ª½Ã", "°­¿øÆ¯º°ÀÚÄ¡µµ °­¸ª½Ã ³ë¾Ïµî±æ 39", "033-640-3315", "033-640-1291~2", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµµ¿ÇØ±³À°Áö¿øÃ»", "µ¿ÇØ½Ã", "°­¿øÆ¯º°ÀÚÄ¡µµ µ¿ÇØ½Ã Ãµ°î·Î 117", "033-530-3065", "033-530-3008", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÅÂ¹é±³À°Áö¿øÃ»", "ÅÂ¹é½Ã", "°­¿øÆ¯º°ÀÚÄ¡µµ ÅÂ¹é½Ã ÇÏÀå¼º1±æ 14", "033-580-5513", "033-581-5547", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµ¼ÓÃÊ¾ç¾ç±³À°Áö¿øÃ»", "¼ÓÃÊ½Ã, ¾ç¾ç±º", "°­¿øÆ¯º°ÀÚÄ¡µµ ¼ÓÃÊ½Ã ¹Ì½Ã·É·Î 3336", "033-639-6000", "033-639-6007~8", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµ»ïÃ´±³À°Áö¿øÃ»", "»ïÃ´½Ã", "°­¿øÆ¯º°ÀÚÄ¡µµ »ïÃ´½Ã Ã»¼®·Î3±æ 32", "033-570-5199", "033-572-7802", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÈ«Ãµ±³À°Áö¿øÃ»", "È«Ãµ±º", "°­¿øÆ¯º°ÀÚÄ¡µµ È«Ãµ±º È«ÃµÀ¾ ²É¸þ·Î 95", "033-430-1115", "033-430-1108", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÈ¾¼º±³À°Áö¿øÃ»", "È¾¼º±º", "°­¿øÆ¯º°ÀÚÄ¡µµ È¾¼º±º È¾¼ºÀ¾ ÇÑ¿ì·Î242¹ø±æ 9", "033-340-0715", "033-343-3651", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµ¿µ¿ù±³À°Áö¿øÃ»", "¿µ¿ù±º", "°­¿øÆ¯º°ÀÚÄ¡µµ ¿µ¿ù±º ¿µ¿ùÀ¾ ¿µ¿ù·Î 1892", "033-370-1114", "033-370-1188", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÆòÃ¢±³À°Áö¿øÃ»", "ÆòÃ¢±º", "°­¿øÆ¯º°ÀÚÄ¡µµ ÆòÃ¢±º ÆòÃ¢À¾ ³ë¼º·Î 193-9", "033-330-1712", "033-334-2618", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÁ¤¼±±³À°Áö¿øÃ»", "Á¤¼±±º", "°­¿øÆ¯º°ÀÚÄ¡µµ Á¤¼±±º Á¤¼±À¾ ºñºÀ·Î 41", "033-560-8114", "033-562-5856", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÃ¶¿ø±³À°Áö¿øÃ»", "Ã¶¿ø±º", "°­¿øÆ¯º°ÀÚÄ¡µµ Ã¶¿ø±º °¥¸»À¾ ¸í¼º·Î139¹ø±æ 47", "033-450-1000", "033-452-3700", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÈ­Ãµ±³À°Áö¿øÃ»", "È­Ãµ±º", "°­¿øÆ¯º°ÀÚÄ¡µµ È­Ãµ±º È­ÃµÀ¾ »ó½Â·Î 19", "033-440-1510", "033-441-2596", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµ¾ç±¸±³À°Áö¿øÃ»", "¾ç±¸±º", "°­¿øÆ¯º°ÀÚÄ¡µµ ¾ç±¸±º ¾ç±¸À¾ °ü°ø¼­·Î 32", "033-480-1410", "033-480-1456", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµÀÎÁ¦±³À°Áö¿øÃ»", "ÀÎÁ¦±º", "°­¿øÆ¯º°ÀÚÄ¡µµ ÀÎÁ¦±º ÀÎÁ¦À¾ ÀÎÁ¦·Î193¹ø±æ 15", "033-460-1000", "033-460-1058", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°­¿øÆ¯º°ÀÚÄ¡µµ°í¼º±³À°Áö¿øÃ»", "°í¼º±º", "°­¿øÆ¯º°ÀÚÄ¡µµ °í¼º±º °£¼ºÀ¾ °£¼º·Î 80", "033-680-6073", "033-680-6098", "https://www.gwe.go.kr/main/content.do?key=m2307211206458"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "½Ãµµ±³À°Ã»", "ÃæÃ»ºÏµµ±³À°Ã»", "ÃæÃ»ºÏµµ", "ÃæÃ»ºÏµµ Ã»ÁÖ½Ã ¼­¿ø±¸ Ã»³²·Î 1929", "043-290-2000", "043-290-2741", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµÃ»ÁÖ±³À°Áö¿øÃ»", "Ã»ÁÖ½Ã", "ÃæÃ»ºÏµµ Ã»ÁÖ½Ã ¼­¿ø±¸ »ê³²·Î24¹ø±æ 25", "043-299-3000", "043-299-3229", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµÃæÁÖ±³À°Áö¿øÃ»", "ÃæÁÖ½Ã", "ÃæÃ»ºÏµµ ÃæÁÖ½Ã ºÀÇö·Î 170", "043-850-0610", "043-848-0664", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµÁ¦Ãµ±³À°Áö¿øÃ»", "Á¦Ãµ½Ã", "ÃæÃ»ºÏµµ Á¦Ãµ½Ã Ã»Àü´ë·Î1±æ 7", "043-640-6600", "043-642-0999", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµº¸Àº±³À°Áö¿øÃ»", "º¸Àº±º", "ÃæÃ»ºÏµµ º¸Àº±º º¸ÀºÀ¾ Àå½Å·Î 26", "043-540-5500", "043-542-5475", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµ¿ÁÃµ±³À°Áö¿øÃ»", "¿ÁÃµ±º", "ÃæÃ»ºÏµµ ¿ÁÃµ±º ¿ÁÃµÀ¾ »ï¾ç·Î 75", "043-730-1313", "043-732-1314", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµ¿µµ¿±³À°Áö¿øÃ»", "¿µµ¿±º", "ÃæÃ»ºÏµµ ¿µµ¿±º ¿µµ¿À¾ ÇÐ»ê¿µµ¿·Î 1220", "043-740-7777", "043-740-7708", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµÁøÃµ±³À°Áö¿øÃ»", "ÁøÃµ±º", "ÃæÃ»ºÏµµ ÁøÃµ±º ÁøÃµÀ¾ »ó»ê·Î 48", "043-530-5305", "043-534-0324", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµ±«»êÁõÆò±³À°Áö¿øÃ»", "±«»ê±º, ÁõÆò±º", "ÃæÃ»ºÏµµ ±«»ê±º ±«»êÀ¾ À¾³»·Î3±æ 23", "043-830-5065", "043-830-5056", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµÀ½¼º±³À°Áö¿øÃ»", "À½¼º±º", "ÃæÃ»ºÏµµ À½¼º±º À½¼ºÀ¾ Áß¾Ó·Î 77", "043-871-5099", "043-872-4498", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»ºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»ºÏµµ´Ü¾ç±³À°Áö¿øÃ»", "´Ü¾ç±º", "ÃæÃ»ºÏµµ ´Ü¾ç±º ´Ü¾çÀ¾ Áß¾Ó1·Î 15", "043-420-6104", "043-422-3561", "https://www.cbe.go.kr/cbe/cm/cntnts/cntntsView.do?cntntsId=35649&mi=11749"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "½Ãµµ±³À°Ã»", "ÃæÃ»³²µµ±³À°Ã»", "ÃæÃ»³²µµ", "ÃæÃ»³²µµ È«¼º±º È«ºÏÀ¾ ¼±È­·Î 22", "041-635-3114", "041-635-3919", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµÃµ¾È±³À°Áö¿øÃ»", "Ãµ¾È½Ã", "ÃæÃ»³²µµ Ãµ¾È½Ã ¼­ºÏ±¸ ±¤Àå·Î 239", "041-529-0500", "041-554-0033", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ°øÁÖ±³À°Áö¿øÃ»", "°øÁÖ½Ã", "ÃæÃ»³²µµ °øÁÖ½Ã ¿Õ¸ª·Î 115", "041-850-5500", "041-850-2359", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµº¸·É±³À°Áö¿øÃ»", "º¸·É½Ã", "ÃæÃ»³²µµ º¸·É½Ã º¸·ÉºÏ·Î 169", "041-930-6352", "041-935-2379", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ¾Æ»ê±³À°Áö¿øÃ»", "¾Æ»ê½Ã", "ÃæÃ»³²µµ ¾Æ»ê½Ã ¹®È­·Î 53", "041-539-2200", "041-549-6451", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ¼­»ê±³À°Áö¿øÃ»", "¼­»ê½Ã", "ÃæÃ»³²µµ ¼­»ê½Ã ¹®È­·Î 112", "041-660-0305", "041-660-0308", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ³í»ê°è·æ±³À°Áö¿øÃ»", "³í»ê½Ã, °è·æ½Ã", "ÃæÃ»³²µµ ³í»ê½Ã °üÃË·Î 253", "041-730-7100", "041-730-7119", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ´çÁø±³À°Áö¿øÃ»", "´çÁø½Ã", "ÃæÃ»³²µµ ´çÁø½Ã ³²ºÎ·Î 186", "041-351-2500", "041-351-2599", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ±Ý»ê±³À°Áö¿øÃ»", "±Ý»ê±º", "ÃæÃ»³²µµ ±Ý»ê±º ±Ý»êÀ¾ ÀÎ»ï·Î 14", "041-750-8100", "041-750-8119", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµºÎ¿©±³À°Áö¿øÃ»", "ºÎ¿©±º", "ÃæÃ»³²µµ ºÎ¿©±º ºÎ¿©À¾ ±Ý¼º·Î 150", "041-830-1500", "041-830-1519", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ¼­Ãµ±³À°Áö¿øÃ»", "¼­Ãµ±º", "ÃæÃ»³²µµ ¼­Ãµ±º ¼­ÃµÀ¾ ¼­Ãµ·Î 105", "041-950-6091", "041-953-1244", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµÃ»¾ç±³À°Áö¿øÃ»", "Ã»¾ç±º", "ÃæÃ»³²µµ Ã»¾ç±º Ã»¾çÀ¾ Áß¾Ó·Î12±æ 19", "041-940-2400", "041-940-2419", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµÈ«¼º±³À°Áö¿øÃ»", "È«¼º±º", "ÃæÃ»³²µµ È«¼º±º È«¼ºÀ¾ ÃæÀý·Î 998", "041-630-5544", "041-630-5539", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµ¿¹»ê±³À°Áö¿øÃ»", "¿¹»ê±º", "ÃæÃ»³²µµ ¿¹»ê±º ¿¹»êÀ¾ ¿ªÀü·Î126¹ø±æ 14", "041-330-1100", "041-330-1119", "https://www.cne.go.kr/"])
    data.Push(["ÃæÃ»³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÃæÃ»³²µµÅÂ¾È±³À°Áö¿øÃ»", "ÅÂ¾È±º", "ÃæÃ»³²µµ ÅÂ¾È±º ÅÂ¾ÈÀ¾ ¿øÀÌ·Î 28", "041-670-8282", "041-674-8179", "https://www.cne.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "½Ãµµ±³À°Ã»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ÀüÁÖ½Ã ¿Ï»ê±¸ È«»ê·Î 111", "063-1396", "063-220-9431, 9432", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµÀüÁÖ±³À°Áö¿øÃ»", "ÀüÁÖ½Ã", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ÀüÁÖ½Ã ´öÁø±¸ ÅÂÁø·Î 100", "063-270-6000", "063-255-9221", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ±º»ê±³À°Áö¿øÃ»", "±º»ê½Ã", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ±º»ê½Ã Á¶ÃÌ·Î 22", "063-450-7000", "063-450-7019", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµÀÍ»ê±³À°Áö¿øÃ»", "ÀÍ»ê½Ã", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ÀÍ»ê½Ã Áß¾Ó·Î 127", "063-850-8800", "063-850-8819", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµÁ¤À¾±³À°Áö¿øÃ»", "Á¤À¾½Ã", "ÀüºÏÆ¯º°ÀÚÄ¡µµ Á¤À¾½Ã ÃæÁ¤·Î 276", "063-530-3000", "063-530-3019", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ³²¿ø±³À°Áö¿øÃ»", "³²¿ø½Ã", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ³²¿ø½Ã ³²¹®·Î 373", "063-620-1100", "063-620-7520", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ±èÁ¦±³À°Áö¿øÃ»", "±èÁ¦½Ã", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ±èÁ¦½Ã ¿äÃÌºÏ·Î 70", "063-540-1100", "063-540-1119", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ¿ÏÁÖ±³À°Áö¿øÃ»", "¿ÏÁÖ±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ¿ÏÁÖ±º ¿ëÁøÀ¾ Áö¾Ï·Î 65", "063-290-2100", "063-290-2119", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµÁø¾È±³À°Áö¿øÃ»", "Áø¾È±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ Áø¾È±º Áø¾ÈÀ¾ ÇÐÃµº¯±æ 47", "063-430-2100", "063-430-2119", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ¹«ÁÖ±³À°Áö¿øÃ»", "¹«ÁÖ±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ¹«ÁÖ±º ¹«ÁÖÀ¾ ´ÜÃµ·Î5±æ 22", "063-320-5100", "063-324-7173", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµÀå¼ö±³À°Áö¿øÃ»", "Àå¼ö±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ Àå¼ö±º Àå¼öÀ¾ È£ºñ·Î 50", "063-350-2100", "063-350-2119", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµÀÓ½Ç±³À°Áö¿øÃ»", "ÀÓ½Ç±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ÀÓ½Ç±º ÀÓ½ÇÀ¾ ºÀÈ²·Î 247", "063-640-2100", "063-640-2119", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ¼øÃ¢±³À°Áö¿øÃ»", "¼øÃ¢±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ¼øÃ¢±º ¼øÃ¢À¾ Àå·ù·Î 383", "063-650-2100", "063-650-2119", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ°íÃ¢±³À°Áö¿øÃ»", "°íÃ¢±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ °íÃ¢±º °íÃ¢À¾ Áß¾Ó·Î 258", "063-560-2100", "063-560-2119", "https://www.jbe.go.kr/"])
    data.Push(["ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "ÀüºÏÆ¯º°ÀÚÄ¡µµºÎ¾È±³À°Áö¿øÃ»", "ºÎ¾È±º", "ÀüºÏÆ¯º°ÀÚÄ¡µµ ºÎ¾È±º ºÎ¾ÈÀ¾ ¸ÅÃ¢·Î 113", "063-580-2100", "063-580-2119", "https://www.jbe.go.kr/"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»(Àü³²Ã»»ç)", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¹«¾È±º »ïÇâÀ¾ ¾îÁø´©¸®±æ 10", "061-260-0013", "061-260-0679", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "½Ãµµ±³À°Ã»", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»(±¤ÁÖÃ»»ç)", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¼­±¸ È­¿î·Î 93", "062-380-4633", "062-375-9383", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "±¤ÁÖµ¿ºÎ±³À°Áö¿øÃ»", "µ¿±¸, Áß±¸, ºÏ±¸", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ºÏ±¸ ¼­¾ç·Î 111", "062-605-5500", "062-605-5519", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "±¤ÁÖ¼­ºÎ±³À°Áö¿øÃ»", "¼­±¸, ³²±¸, ±¤»ê±¸", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¼­±¸ »ó¹«¹ø¿µ·Î 98", "062-600-9700", "062-600-9720", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¸ñÆ÷±³À°Áö¿øÃ»", "¸ñÆ÷½Ã", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¸ñÆ÷½Ã ±³À°·Î 5", "061-282-7321", "061-282-7329", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¿©¼ö±³À°Áö¿øÃ»", "¿©¼ö½Ã", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¿©¼ö½Ã °ü¹®µ¿1±æ 39", "061-690-5566", "061-686-5123", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¼øÃµ±³À°Áö¿øÃ»", "¼øÃµ½Ã", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¼øÃµ½Ã ¿¬Çâ2·Î 15", "061-721-8700", "061-723-1769", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "³ªÁÖ±³À°Áö¿øÃ»", "³ªÁÖ½Ã", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ³ªÁÖ½Ã ¿Ï»çÃµ±æ 15", "061-330-0154", "061-333-8379", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "±¤¾ç±³À°Áö¿øÃ»", "±¤¾ç½Ã", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ±¤¾ç½Ã ±¤¾çÀ¾ ¿ì»ê±æ 3", "061-760-3346", "061-762-2530", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "´ã¾ç±³À°Áö¿øÃ»", "´ã¾ç±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ´ã¾ç±º ´ã¾çÀ¾ ½Å¼º±æ 2-8", "061-380-8154", "061-383-3278", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "°î¼º±³À°Áö¿øÃ»", "°î¼º±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã °î¼º±º °î¼ºÀ¾ ±ºÃ»·Î 13", "061-360-6667", "061-363-0227", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "±¸·Ê±³À°Áö¿øÃ»", "±¸·Ê±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ±¸·Ê±º ±¸·ÊÀ¾ ±¸·Ê2±æ 21", "061-780-6600", "061-782-8035", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "°íÈï±³À°Áö¿øÃ»", "°íÈï±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã °íÈï±º °íÈïÀ¾ ¹é·ÃÀåÀü±æ 36", "061-830-2000", "061-835-1019", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "º¸¼º±³À°Áö¿øÃ»", "º¸¼º±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã º¸¼º±º º¸¼ºÀ¾ »õ½Ï±æ 26", "061-850-7114", "061-852-4648", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "È­¼ø±³À°Áö¿øÃ»", "È­¼ø±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã È­¼ø±º È­¼øÀ¾ Áø°¢·Î 159", "061-370-7114", "061-370-7103", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÀåÈï±³À°Áö¿øÃ»", "ÀåÈï±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ÀåÈï±º ÀåÈïÀ¾ µ¿±³·Î 64-17", "061-860-1245", "061-863-1337", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "°­Áø±³À°Áö¿øÃ»", "°­Áø±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã °­Áø±º °­ÁøÀ¾ ±Ý¸ª6±æ 8", "061-430-1505", "061-432-9337", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÇØ³²±³À°Áö¿øÃ»", "ÇØ³²±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ÇØ³²±º ÇØ³²À¾ ±³À°Ã»±æ 50", "061-530-1100", "061-530-1104", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¿µ¾Ï±³À°Áö¿øÃ»", "¿µ¾Ï±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¿µ¾Ï±º ¿µ¾ÏÀ¾ ¿ùÃâ·Î 84", "061-470-4156", "061-473-0335", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¹«¾È±³À°Áö¿øÃ»", "¹«¾È±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¹«¾È±º ¹«¾ÈÀ¾ ½Â´Þ·Î 63", "061-450-7000", "061-454-7811", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "ÇÔÆò±³À°Áö¿øÃ»", "ÇÔÆò±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ÇÔÆò±º ÇÔÆòÀ¾ ¿µ¼ö±æ 273-17", "061-320-6654", "061-324-1655", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¿µ±¤±³À°Áö¿øÃ»", "¿µ±¤±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¿µ±¤±º ¿µ±¤À¾ Áß¾Ó·Î 204", "061-350-6600", "061-352-1605", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "Àå¼º±³À°Áö¿øÃ»", "Àå¼º±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã Àå¼º±º Àå¼ºÀ¾ ¹æ¿ï»ù±æ 22", "061-390-6000", "061-393-1800", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "¿Ïµµ±³À°Áö¿øÃ»", "¿Ïµµ±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¿Ïµµ±º ¿ÏµµÀ¾ °³Æ÷·Î114¹ø±æ 30-12", "061-550-0500", "061-554-0424", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "Áøµµ±³À°Áö¿øÃ»", "Áøµµ±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã Áøµµ±º ÁøµµÀ¾ ´Þµ¿³×±æ 12", "061-540-5164", "061-543-0009", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã±³À°Ã»", "±³À°Áö¿øÃ»", "½Å¾È±³À°Áö¿øÃ»", "½Å¾È±º", "Àü³²±¤ÁÖÅëÇÕÆ¯º°½Ã ¸ñÆ÷½Ã ÇØ¾È·Î165¹ø±æ 25", "061-240-3656", "061-245-3190", "https://gen.go.kr/sub/page.php?page_code=introduce_06_02"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "½Ãµµ±³À°Ã»", "°æ»óºÏµµ±³À°Ã»", "°æ»óºÏµµ", "°æ»óºÏµµ ¾Èµ¿½Ã Ç³Ãµ¸é µµÃ»´ë·Î 511", "054-805-3000", "054-805-3129", "https://www.gbe.kr/main/main.do"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµÆ÷Ç×±³À°Áö¿øÃ»", "Æ÷Ç×½Ã", "°æ»óºÏµµ Æ÷Ç×½Ã ºÏ±¸ »ïÈï·Î 416", "054-288-6800", "054-288-6820", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ°æÁÖ±³À°Áö¿øÃ»", "°æÁÖ½Ã", "°æ»óºÏµµ °æÁÖ½Ã ÃÊ´ç±æ 9", "054-740-9118", "054-741-4827", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ±èÃµ±³À°Áö¿øÃ»", "±èÃµ½Ã", "°æ»óºÏµµ ±èÃµ½Ã ÃæÈ¿±æ 19", "054-420-5210", "054-432-2827", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¾Èµ¿±³À°Áö¿øÃ»", "¾Èµ¿½Ã", "°æ»óºÏµµ ¾Èµ¿½Ã °æµ¿·Î 554", "054-851-9100", "054-851-9199", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ±¸¹Ì±³À°Áö¿øÃ»", "±¸¹Ì½Ã", "°æ»óºÏµµ ±¸¹Ì½Ã ¼ÛÁ¤´ë·Î 63", "054-440-2215", "054-440-2219", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¿µÁÖ±³À°Áö¿øÃ»", "¿µÁÖ½Ã", "°æ»óºÏµµ ¿µÁÖ½Ã °¡Èï·Î 165", "054-632-5167", "054-632-0919", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¿µÃµ±³À°Áö¿øÃ»", "¿µÃµ½Ã", "°æ»óºÏµµ ¿µÃµ½Ã Àå¼ö·Î 18-2", "054-330-2365", "054-330-2375", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ»óÁÖ±³À°Áö¿øÃ»", "»óÁÖ½Ã", "°æ»óºÏµµ »óÁÖ½Ã ¸¸»ê8±æ 26", "054-530-2300", "054-530-2399", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¹®°æ±³À°Áö¿øÃ»", "¹®°æ½Ã", "°æ»óºÏµµ ¹®°æ½Ã È£°è¸é ÅÂºÀ1±æ 25", "054-550-5544", "054-553-1396", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ°æ»ê±³À°Áö¿øÃ»", "°æ»ê½Ã", "°æ»óºÏµµ °æ»ê½Ã ¿øÈ¿·Î 309-6", "053-810-7565", "053-810-7589", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµÀÇ¼º±³À°Áö¿øÃ»", "ÀÇ¼º±º", "°æ»óºÏµµ ÀÇ¼º±º ÀÇ¼ºÀ¾ ±¸ºÀ±æ 168-7", "054-830-1163", "054-833-9552", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµÃ»¼Û±³À°Áö¿øÃ»", "Ã»¼Û±º", "°æ»óºÏµµ Ã»¼Û±º Ã»¼ÛÀ¾ ±ºÃ»·Î 25", "054-870-1100", "054-870-1106", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¿µ¾ç±³À°Áö¿øÃ»", "¿µ¾ç±º", "°æ»óºÏµµ ¿µ¾ç±º ¿µ¾çÀ¾ ¿µ¾çÃ¢¼ö·Î 83", "054-680-2200", "054-680-2205", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¿µ´ö±³À°Áö¿øÃ»", "¿µ´ö±º", "°æ»óºÏµµ ¿µ´ö±º ¿µ´öÀ¾ À¾»ç¹«¼Ò1±æ 32-15", "054-730-8007", "054-730-8006", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµÃ»µµ±³À°Áö¿øÃ»", "Ã»µµ±º", "°æ»óºÏµµ Ã»µµ±º Ã»µµÀ¾ ³²¼ºÇö·Î 31", "054-370-1145", "054-372-1904", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ°í·É±³À°Áö¿øÃ»", "°í·É±º", "°æ»óºÏµµ °í·É±º ´ë°¡¾ßÀ¾ °¡¾ß±Ý±æ 34", "054-950-2500", "054-954-3771", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¼ºÁÖ±³À°Áö¿øÃ»", "¼ºÁÖ±º", "°æ»óºÏµµ ¼ºÁÖ±º ¼ºÁÖÀ¾ ÁÖ»ê·Î 71-4", "054-930-2000", "054-931-0038", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµÄ¥°î±³À°Áö¿øÃ»", "Ä¥°î±º", "°æ»óºÏµµ Ä¥°î±º ¿Ö°üÀ¾ Áß¾Ó·Î10±æ 33", "054-979-2100", "054-971-1506", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¿¹Ãµ±³À°Áö¿øÃ»", "¿¹Ãµ±º", "°æ»óºÏµµ ¿¹Ãµ±º È£¸íÀ¾ ¾çÁö9±æ 6, 3~4Ãþ", "054-650-2515", "054-652-5968", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµºÀÈ­±³À°Áö¿øÃ»", "ºÀÈ­±º", "°æ»óºÏµµ ºÀÈ­±º ºÀÈ­À¾ ¼Ö¾È4±æ 12", "054-679-1750", "054-673-9530", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¿ïÁø±³À°Áö¿øÃ»", "¿ïÁø±º", "°æ»óºÏµµ ¿ïÁø±º ¿ïÁøÀ¾ ¿ùº¯7±æ 17", "054-780-3351", "054-783-3880", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»óºÏµµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»óºÏµµ¿ï¸ª±³À°Áö¿øÃ»", "¿ï¸ª±º", "°æ»óºÏµµ ¿ï¸ª±º ¿ï¸ªÀ¾ ¾à¼öÅÍ±æ 40", "054-791-2293", "054-791-2295", "https://www.gbe.kr/main/cm/cntnts/cntntsView.do?cntntsId=3118&mi=4155"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "½Ãµµ±³À°Ã»", "°æ»ó³²µµ±³À°Ã»", "°æ»ó³²µµ", "°æ»ó³²µµ Ã¢¿ø½Ã ¼º»ê±¸ Áß¾Ó´ë·Î 241", "055-268-1004", "055-268-1369", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÃ¢¿ø±³À°Áö¿øÃ»", "Ã¢¿ø½Ã", "°æ»ó³²µµ Ã¢¿ø½Ã ¼º»ê±¸ Áß¾Ó´ë·Î228¹ø±æ 3", "055-210-0522~0524", "055-210-0530", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÁøÁÖ±³À°Áö¿øÃ»", "ÁøÁÖ½Ã", "°æ»ó³²µµ ÁøÁÖ½Ã ºñºÀ·Î23¹ø±æ 8", "055-740-2000", "055-752-5786", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÅë¿µ±³À°Áö¿øÃ»", "Åë¿µ½Ã", "°æ»ó³²µµ Åë¿µ½Ã ±¤µµ¸é Á×¸²2·Î 25-32", "055-650-8065", "055-645-2253", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ»çÃµ±³À°Áö¿øÃ»", "»çÃµ½Ã", "°æ»ó³²µµ »çÃµ½Ã »ï»ó·Î 85", "055-830-1565", "055-832-3865", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ±èÇØ±³À°Áö¿øÃ»", "±èÇØ½Ã", "°æ»ó³²µµ ±èÇØ½Ã ±èÇØ´ë·Î1902¹ø±æ 50", "055-330-7620~7621", "055-322-1910", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ¹Ð¾ç±³À°Áö¿øÃ»", "¹Ð¾ç½Ã", "°æ»ó³²µµ ¹Ð¾ç½Ã »ó³²¸é ¹Ð¾ç´ë·Î 1522", "055-350-1564", "055-350-1588", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ°ÅÁ¦±³À°Áö¿øÃ»", "°ÅÁ¦½Ã", "°æ»ó³²µµ °ÅÁ¦½Ã °ÅÁ¦Áß¾Ó·Î 1809", "055-630-9264", "055-630-9209", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ¾ç»ê±³À°Áö¿øÃ»", "¾ç»ê½Ã", "°æ»ó³²µµ ¾ç»ê½Ã ¹°±ÝÀ¾ Ã»·æ·Î 53", "055-379-3124", "055-379-3111", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÀÇ·É±³À°Áö¿øÃ»", "ÀÇ·É±º", "°æ»ó³²µµ ÀÇ·É±º ÀÇ·ÉÀ¾ ÀÇº´·Î 148", "055-570-7166", "055-573-3796", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÇÔ¾È±³À°Áö¿øÃ»", "ÇÔ¾È±º", "°æ»ó³²µµ ÇÔ¾È±º °¡¾ßÀ¾ ÇÔ¾È´ë·Î 497", "055-580-8064", "055-582-4945", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÃ¢³ç±³À°Áö¿øÃ»", "Ã¢³ç±º", "°æ»ó³²µµ Ã¢³ç±º Ã¢³çÀ¾ Ã¢³ç´ë·Î 135", "055-530-3565", "055-533-2511", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ°í¼º±³À°Áö¿øÃ»", "°í¼º±º", "°æ»ó³²µµ °í¼º±º °í¼ºÀ¾ µ¿¿Ü·Î 108", "055-670-8163", "055-674-1006", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ³²ÇØ±³À°Áö¿øÃ»", "³²ÇØ±º", "°æ»ó³²µµ ³²ÇØ±º ³²ÇØÀ¾ È­Àü·Î95¹ø±æ 14", "055-860-4165", "055-864-3572", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÇÏµ¿±³À°Áö¿øÃ»", "ÇÏµ¿±º", "°æ»ó³²µµ ÇÏµ¿±º ÇÏµ¿À¾ ±ºÃ»·Î 191", "055-880-1958", "055-883-0138", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ»êÃ»±³À°Áö¿øÃ»", "»êÃ»±º", "°æ»ó³²µµ »êÃ»±º »êÃ»À¾ Ä£È¯°æ·Î2720¹ø±æ 10", "055-970-3064", "055-973-0556", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÇÔ¾ç±³À°Áö¿øÃ»", "ÇÔ¾ç±º", "°æ»ó³²µµ ÇÔ¾ç±º ÇÔ¾çÀ¾ ÇÔ¾ç·Î 1157", "055-960-2763", "055-960-2709", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµ°ÅÃ¢±³À°Áö¿øÃ»", "°ÅÃ¢±º", "°æ»ó³²µµ °ÅÃ¢±º °ÅÃ¢À¾ °ÅÇÔ´ë·Î 3235", "055-940-6100", "055-943-7066", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["°æ»ó³²µµ±³À°Ã»", "±³À°Áö¿øÃ»", "°æ»ó³²µµÇÕÃµ±³À°Áö¿øÃ»", "ÇÕÃµ±º", "°æ»ó³²µµ ÇÕÃµ±º ÇÕÃµÀ¾ µ¿¼­·Î 150", "055-930-7071", "055-932-0572", "https://www.gne.go.kr/www/minwon/complaints/guide/guide_01.jsp"])
    data.Push(["Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "½Ãµµ±³À°Ã»", "Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "Á¦ÁÖÆ¯º°ÀÚÄ¡µµ", "Á¦ÁÖÆ¯º°ÀÚÄ¡µµ Á¦ÁÖ½Ã ¹®¿¬·Î 5", "064-710-0114", "064-710-0709", "https://www.jje.go.kr/"])
    data.Push(["Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "Á¦ÁÖ½Ã±³À°Áö¿øÃ»", "Á¦ÁÖ½Ã", "Á¦ÁÖÆ¯º°ÀÚÄ¡µµ Á¦ÁÖ½Ã ³²±¤·Î 27", "064-754-1221", "064-754-1229", "https://www.jje.go.kr/"])
    data.Push(["Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "±³À°Áö¿øÃ»", "¼­±ÍÆ÷½Ã±³À°Áö¿øÃ»", "¼­±ÍÆ÷½Ã", "Á¦ÁÖÆ¯º°ÀÚÄ¡µµ ¼­±ÍÆ÷½Ã ÅäÆò·Î 43", "064-730-8100", "064-730-8107", "https://www.jje.go.kr/jse/index.jje?contentsSid=374"])
    return data
}

SSOK_EDU_GetOfficeNamesPipe()
{
    return "¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»|¼­¿ïÆ¯º°½Ã±³À°Ã»|ºÎ»ê±¤¿ª½Ã±³À°Ã»|´ë±¸±¤¿ª½Ã±³À°Ã»|ÀÎÃµ±¤¿ª½Ã±³À°Ã»|±¤ÁÖ±¤¿ª½Ã±³À°Ã»|´ëÀü±¤¿ª½Ã±³À°Ã»|¿ï»ê±¤¿ª½Ã±³À°Ã»|°æ±âµµ±³À°Ã»|°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»|ÃæÃ»ºÏµµ±³À°Ã»|ÃæÃ»³²µµ±³À°Ã»|ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»|Àü¶ó³²µµ±³À°Ã»|°æ»óºÏµµ±³À°Ã»|°æ»ó³²µµ±³À°Ã»|Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»"
}

SSOK_EDU_GetOfficeCodeByIndex(idx)
{
    codes := ["I10", "B10", "C10", "D10", "E10", "F10", "G10", "H10", "J10", "K10", "M10", "N10", "P10", "Q10", "R10", "S10", "T10"]
    if (idx < 1 || idx > codes.Length())
        return ""
    return codes[idx]
}

SSOK_EDU_GetOfficeIndexByCode(code)
{
    codes := ["I10", "B10", "C10", "D10", "E10", "F10", "G10", "H10", "J10", "K10", "M10", "N10", "P10", "Q10", "R10", "S10", "T10"]
    for idx, item in codes
        if (item = code)
            return idx
    return 0
}

SSOK_EDU_LoadOrgSchools()
{
    global SSOK_EDU_OrgOffice, SSOK_EDU_OrgSupport, SSOK_EDU_OrgKind, SSOK_EDU_OrgSchools, SSOK_EDU_OrgDefaultSupport
    global SSOK_EDU_OrgStatus

    Gui, SSOKEDUOrg:Submit, NoHide
    officeCode := SSOK_EDU_GetOfficeCodeByIndex(SSOK_EDU_OrgOffice)
    if (officeCode = "")
        return

    ; ±³À°Ã»À» ¹Ù²Ù¸é ÀÌÀü ±³À°Ã»ÀÇ ÁøÇà Áß ÇÐ±Þ¼ö ¿äÃ»ºÎÅÍ Áï½Ã ÁßÁöÇÕ´Ï´Ù.
    SSOK_EDU_CancelClassCountLoad()
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgStatus, ÇÐ±³ ¸ñ·Ï ºÒ·¯¿À´Â Áß...
    schools := SSOK_EDU_FetchSchoolsByOffice(officeCode)

    ; ÇÐ±³ ¸ñ·ÏÀº ¸ÕÀú Áï½Ã Ç¥½ÃÇÏ°í, ÇÐ±Þ¼ö´Â ºñµ¿±â ¿äÃ»À¸·Î µÚ¿¡¼­ Ã¤¿ó´Ï´Ù.
    ; µð½ºÅ©/¸Þ¸ð¸® Ä³½Ã´Â »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    if (IsObject(schools))
    {
        for idx, item in schools
            item.classCount := "..."
    }
    SSOK_EDU_OrgSchools := schools

    supportSeen := {}
    supportLines := ""
    kindSeen := {}
    kindLines := ""
    if (IsObject(schools))
    {
        for idx, item in schools
        {
            s := Trim(item.parentOrg)
            if (s != "" && !supportSeen.HasKey(s))
            {
                supportSeen[s] := 1
                supportLines .= s . "`n"
            }

            k := Trim(item.kind)
            if (k != "" && !kindSeen.HasKey(k))
            {
                kindSeen[k] := 1
                kindLines .= k . "`n"
            }
        }
    }

    Sort, supportLines, U
    supportPipe := "±³À°Ã» ÀüÃ¼"
    Loop, Parse, supportLines, `n, `r
    {
        s := Trim(A_LoopField)
        if (s != "")
            supportPipe .= "|" . s
    }

    Sort, kindLines, U
    kindPipe := "ÀüÃ¼"
    Loop, Parse, kindLines, `n, `r
    {
        k := Trim(A_LoopField)
        if (k != "")
            kindPipe .= "|" . k
    }

    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgSupport, |%supportPipe%
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgKind, |%kindPipe%

    if (SSOK_EDU_OrgDefaultSupport != "")
    {
        GuiControl, SSOKEDUOrg:ChooseString, SSOK_EDU_OrgSupport, %SSOK_EDU_OrgDefaultSupport%
        SSOK_EDU_OrgDefaultSupport := ""
    }
    else
        GuiControl, SSOKEDUOrg:Choose, SSOK_EDU_OrgSupport, 1

    GuiControl, SSOKEDUOrg:Choose, SSOK_EDU_OrgKind, 1
    SSOK_EDU_RefreshOrgSchoolList()
    SSOK_EDU_StartClassCountLoad(officeCode, A_YYYY, schools)
}

SSOK_EDU_RefreshOrgSchoolList()
{
    global SSOK_EDU_OrgSupport, SSOK_EDU_OrgKind, SSOK_EDU_OrgSchools, SSOK_EDU_OrgVisibleSchools
    global SSOK_EDU_OrgSchoolList, SSOK_EDU_OrgStatus, SSOK_EDU_OrgSearch
    global SSOK_EDU_OrgSearchMode, SSOK_EDU_OrgGlobalResults
    global SSOK_EDU_ClassReqLoading, SSOK_EDU_ClassReqDone, SSOK_EDU_ClassReqTotal

    Gui, SSOKEDUOrg:Submit, NoHide
    support := Trim(SSOK_EDU_OrgSupport)
    kind := Trim(SSOK_EDU_OrgKind)
    isGlobal := (SSOK_EDU_OrgSearchMode = "global")
    source := isGlobal ? SSOK_EDU_OrgGlobalResults : SSOK_EDU_OrgSchools
    visible := []

    Gui, SSOKEDUOrg:Default
    Gui, ListView, SSOK_EDU_OrgSchoolList
    LV_Delete()
    if (IsObject(source))
    {
        for idx, item in source
        {
            ; Àü±¹°Ë»ö¿¡¼­´Â ÇöÀç ±³À°Ã»/Áö¿øÃ» ¼±ÅÃ°ª¿¡ Á¦ÇÑÇÏÁö ¾Ê½À´Ï´Ù.
            if (!isGlobal && support != "" && support != "±³À°Ã» ÀüÃ¼" && item.parentOrg != support)
                continue
            if (kind != "" && kind != "ÀüÃ¼" && item.kind != kind)
                continue

            visible.Push(item)
            classText := (item.classCount != "" ? item.classCount : "-")
            foundYear := "-"
            if (RegExMatch(Trim(item.foundDate), "^([0-9]{4})", foundYearMatch))
                foundYear := foundYearMatch1
            LV_Add("", item.schoolName, item.kind, classText, foundYear, item.parentOrg, item.address, item.tel, item.fax, item.homepage, item.schoolCode)
        }
    }

    SSOK_EDU_OrgVisibleSchools := visible
    LV_ModifyCol(1, 155)
    LV_ModifyCol(2, 75)
    LV_ModifyCol(3, "60 Integer")
    LV_ModifyCol(4, "68 Integer")
    LV_ModifyCol(5, 165)
    LV_ModifyCol(6, 260)
    LV_ModifyCol(7, 105)
    LV_ModifyCol(8, 105)
    LV_ModifyCol(9, 190)
    LV_ModifyCol(10, 0)

    if (visible.Length() > 0)
        LV_Modify(1, "Select Focus Vis")

    status := isGlobal ? ("Àü±¹°Ë»ö " . visible.Length() . "°³") : ("ÇÐ±³ " . visible.Length() . "°³")
    if (!isGlobal && SSOK_EDU_ClassReqLoading && SSOK_EDU_ClassReqTotal > 0)
        status .= " ¡¤ ÇÐ±Þ¼ö " . SSOK_EDU_ClassReqDone . "/" . SSOK_EDU_ClassReqTotal
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgStatus, %status%
}

SSOK_EDU_ApplyOrgGlobalSearch()
{
    global SSOK_EDU_OrgSearch, SSOK_EDU_OrgSearchMode, SSOK_EDU_OrgGlobalResults
    global SSOK_EDU_OrgStatus, SSOK_EDU_OrgViewMode

    if (SSOK_EDU_OrgViewMode = "office")
    {
        SSOK_EDU_RefreshOrgOfficeList()
        return
    }

    Gui, SSOKEDUOrg:Submit, NoHide
    q := Trim(SSOK_EDU_OrgSearch)

    ; °Ë»ö¾î¸¦ Áö¿ì¸é ´Ù½Ã ÇöÀç ¼±ÅÃÇÑ ±³À°Ã»ÀÇ °üÇÒÇÐ±³ ¸ñ·ÏÀ¸·Î µ¹¾Æ°©´Ï´Ù.
    if (q = "")
    {
        if (SSOK_EDU_OrgSearchMode = "global")
        {
            SSOK_EDU_OrgSearchMode := "office"
            SSOK_EDU_OrgGlobalResults := []
            SSOK_EDU_LoadOrgSchools()
        }
        else
            SSOK_EDU_RefreshOrgSchoolList()
        return
    }

    if (StrLen(q) < 2)
    {
        GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgStatus, Àü±¹°Ë»öÀº 2±ÛÀÚ ÀÌ»ó
        return
    }

    SSOK_EDU_CancelClassCountLoad()
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgStatus, Àü±¹ ÇÐ±³ °Ë»ö Áß...
    results := SSOK_EDU_FetchSchoolsByName(q)

    ; Á¶È¸ Áß °Ë»ö¾î°¡ ¹Ù²ï °æ¿ì¿¡´Â »õ Å¸ÀÌ¸Ó °Ë»ö °á°ú¸¦ ±â´Ù¸³´Ï´Ù.
    Gui, SSOKEDUOrg:Submit, NoHide
    if (Trim(SSOK_EDU_OrgSearch) != q)
        return

    if (IsObject(results))
    {
        for idx, item in results
            item.classCount := "-"
    }
    SSOK_EDU_OrgSearchMode := "global"
    SSOK_EDU_OrgGlobalResults := results
    SSOK_EDU_RefreshOrgSchoolList()
}

SSOK_EDU_FetchSchoolsByName(query)
{
    results := []
    seen := {}
    q := Trim(query)
    if (q = "")
        return results

    pageSize := 1000
    key := SSOK_EDU_GetApiKey()
    params := Object("SCHUL_NM", q)
    url := SSOK_EDU_BuildUrl("schoolInfo", params, pageSize, key, 1)
    resp := SSOK_EDU_HttpGet(url)
    if (!resp.ok)
        return results

    firstRows := SSOK_EDU_ParseSchools(resp.text)
    if (!IsObject(firstRows) || firstRows.Length() < 1)
        return results

    for idx, item in firstRows
    {
        k := item.officeCode . "|" . item.schoolCode
        if (!seen.HasKey(k))
        {
            seen[k] := 1
            results.Push(item)
        }
    }

    total := SSOK_EDU_ParseTotalCount(resp.text)
    if (total <= firstRows.Length())
        return results

    perPage := firstRows.Length()
    if (perPage < 1)
        return results
    pageCount := Ceil(total / perPage)
    if (pageCount > 10)
        pageCount := 10
    Loop, % pageCount - 1
    {
        pageIndex := A_Index + 1
        url := SSOK_EDU_BuildUrl("schoolInfo", params, pageSize, key, pageIndex)
        resp2 := SSOK_EDU_HttpGet(url)
        if (!resp2.ok)
            break
        pageRows := SSOK_EDU_ParseSchools(resp2.text)
        if (!IsObject(pageRows) || pageRows.Length() < 1)
            break
        for idx, item in pageRows
        {
            k := item.officeCode . "|" . item.schoolCode
            if (!seen.HasKey(k))
            {
                seen[k] := 1
                results.Push(item)
            }
        }
    }
    return results
}

SSOK_EDU_ExportOrgSchoolsExcel()
{
    global SSOK_EDU_OrgVisibleSchools, SSOK_EDU_OrgOffice, SSOK_EDU_OrgSearchMode, SSOK_EDU_OrgSearch

    if (!IsObject(SSOK_EDU_OrgVisibleSchools) || SSOK_EDU_OrgVisibleSchools.Length() < 1)
    {
        MsgBox, 48, SSOK ±³À°Á¤º¸, ¿¢¼¿·Î ÀúÀåÇÒ ÇÐ±³ ¸ñ·ÏÀÌ ¾ø½À´Ï´Ù.
        return
    }

    Gui, SSOKEDUOrg:Submit, NoHide
    if (SSOK_EDU_OrgSearchMode = "global")
        officeName := "Àü±¹_ÇÐ±³°Ë»ö_" . Trim(SSOK_EDU_OrgSearch)
    else
        officeName := SSOK_EDU_GetOfficeNameByIndex(SSOK_EDU_OrgOffice)
    safeOffice := RegExReplace(officeName, "[\/:*?""<>|]", "")
    defaultName := safeOffice . "_ÇÐ±³¸ñ·Ï_" . A_YYYY . A_MM . A_DD . ".xlsx"
    defaultPath := A_Desktop . "\" . defaultName

    FileSelectFile, savePath, S16, %defaultPath%, °üÇÒ ±³À°Ã» ÇÐ±³¸ñ·Ï ÀúÀå, Excel ÅëÇÕ¹®¼­ (*.xlsx)
    if (ErrorLevel || Trim(savePath) = "")
        return
    if (!RegExMatch(savePath, "i)\.xlsx$"))
        savePath .= ".xlsx"

    try
    {
        xl := ComObjCreate("Excel.Application")
        xl.Visible := false
        xl.DisplayAlerts := false
        wb := xl.Workbooks.Add()
        ws := wb.Worksheets(1)
        ws.Name := "ÇÐ±³¸ñ·Ï"

        headers := ["ÇÐ±³¸í", "ÇÐ±³±Þ", "±³À°Ã»", "Áö¿øÃ»", "ÁÖ¼Ò", "ÀüÈ­", "ÆÑ½º", "È¨ÆäÀÌÁö"]
        for col, header in headers
            ws.Cells(1, col).Value := header

        rowNo := 2
        for idx, item in SSOK_EDU_OrgVisibleSchools
        {
            ws.Cells(rowNo, 1).Value := item.schoolName
            ws.Cells(rowNo, 2).Value := item.kind
            ws.Cells(rowNo, 3).Value := item.officeName
            ws.Cells(rowNo, 4).Value := item.parentOrg
            ws.Cells(rowNo, 5).Value := item.address
            ws.Cells(rowNo, 6).NumberFormat := "@"
            ws.Cells(rowNo, 6).Value := item.tel
            ws.Cells(rowNo, 7).NumberFormat := "@"
            ws.Cells(rowNo, 7).Value := item.fax
            ws.Cells(rowNo, 8).Value := item.homepage
            rowNo++
        }

        ws.Range("A1:H1").Font.Bold := true
        ws.Range("A1:H1").AutoFilter()
        ws.Columns("A:H").EntireColumn.AutoFit()
        if (ws.Columns("E").ColumnWidth > 45)
            ws.Columns("E").ColumnWidth := 45
        if (ws.Columns("H").ColumnWidth > 50)
            ws.Columns("H").ColumnWidth := 50

        wb.SaveAs(savePath, 51)
        wb.Close(false)
        xl.Quit()
        wb := ""
        ws := ""
        xl := ""

        MsgBox, 64, SSOK ±³À°Á¤º¸, % "¿¢¼¿ ÆÄÀÏÀ» ÀúÀåÇß½À´Ï´Ù.`n`n" . savePath
    }
    catch e
    {
        try
        {
            if IsObject(wb)
                wb.Close(false)
            if IsObject(xl)
                xl.Quit()
        }
        catch e2
        {
        }
        MsgBox, 48, SSOK ±³À°Á¤º¸, ¿¢¼¿ ÀúÀå Áß ¿À·ù°¡ ¹ß»ýÇß½À´Ï´Ù.`n`nMicrosoft ExcelÀÌ ¼³Ä¡µÇ¾î ÀÖ´ÂÁö È®ÀÎÇØ ÁÖ¼¼¿ä.
    }
}

SSOK_EDU_GetOfficeNameByIndex(idx)
{
    names := ["¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»", "¼­¿ïÆ¯º°½Ã±³À°Ã»", "ºÎ»ê±¤¿ª½Ã±³À°Ã»", "´ë±¸±¤¿ª½Ã±³À°Ã»", "ÀÎÃµ±¤¿ª½Ã±³À°Ã»", "±¤ÁÖ±¤¿ª½Ã±³À°Ã»", "´ëÀü±¤¿ª½Ã±³À°Ã»", "¿ï»ê±¤¿ª½Ã±³À°Ã»", "°æ±âµµ±³À°Ã»", "°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "ÃæÃ»ºÏµµ±³À°Ã»", "ÃæÃ»³²µµ±³À°Ã»", "ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»", "Àü¶ó³²µµ±³À°Ã»", "°æ»óºÏµµ±³À°Ã»", "°æ»ó³²µµ±³À°Ã»", "Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»"]
    if (idx < 1 || idx > names.Length())
        return "°üÇÒ±³À°Ã»"
    return names[idx]
}

SSOK_EDU_SelectOrgSchoolRow(row)
{
    global SSOK_EDU_OrgVisibleSchools
    if (!IsObject(SSOK_EDU_OrgVisibleSchools) || row < 1)
        return

    ; ¿­ Á¦¸ñ Á¤·Ä ÈÄ¿¡µµ ¼±ÅÃÇÑ È­¸é Çà°ú ½ÇÁ¦ ÇÐ±³°¡ Á¤È®È÷ ¿¬°áµÇµµ·Ï
    ; ¼û±è ÇÐ±³ÄÚµå¸¦ ±âÁØÀ¸·Î ¿øº» ÇÐ±³ °´Ã¼¸¦ Ã£½À´Ï´Ù.
    Gui, SSOKEDUOrg:Default
    Gui, ListView, SSOK_EDU_OrgSchoolList
    LV_GetText(schoolCode, row, 10)
    school := ""
    if (schoolCode != "")
    {
        for idx, item in SSOK_EDU_OrgVisibleSchools
        {
            if (item.schoolCode = schoolCode)
            {
                school := item
                break
            }
        }
    }

    ; ¿¹¿ÜÀûÀ¸·Î ÇÐ±³ÄÚµå¸¦ ÀÐÁö ¸øÇÑ °æ¿ì ±âÁ¸ Çà ¼ø¼­ ¹æ½ÄÀ¸·Î º¸¿ÏÇÕ´Ï´Ù.
    if (!IsObject(school) && row <= SSOK_EDU_OrgVisibleSchools.Length())
        school := SSOK_EDU_OrgVisibleSchools[row]
    if (!IsObject(school))
        return

    Gui, SSOKEDUOrg:Destroy
    SSOK_EDU_OpenSchool(school)
}

SSOK_EDU_FetchSchoolsByOffice(officeCode)
{
    results := []
    seen := {}
    pageSize := 1000
    key := SSOK_EDU_GetApiKey()
    params := Object("ATPT_OFCDC_SC_CODE", officeCode)
    url := SSOK_EDU_BuildUrl("schoolInfo", params, pageSize, key, 1)
    resp := SSOK_EDU_HttpGet(url)
    if (!resp.ok)
        return results

    firstRows := SSOK_EDU_ParseSchools(resp.text)
    if (!IsObject(firstRows) || firstRows.Length() < 1)
        return results
    for idx, item in firstRows
    {
        k := item.officeCode . "|" . item.schoolCode
        if (!seen.HasKey(k))
        {
            seen[k] := 1
            results.Push(item)
        }
    }

    total := SSOK_EDU_ParseTotalCount(resp.text)
    perPage := firstRows.Length()
    if (total <= perPage || perPage < 1)
        return results
    pageCount := Ceil(total / perPage)
    if (pageCount > 50)
        pageCount := 50

    Loop, % pageCount - 1
    {
        pageIndex := A_Index + 1
        url := SSOK_EDU_BuildUrl("schoolInfo", params, pageSize, key, pageIndex)
        resp2 := SSOK_EDU_HttpGet(url)
        if (!resp2.ok)
            break
        pageRows := SSOK_EDU_ParseSchools(resp2.text)
        if (!IsObject(pageRows) || pageRows.Length() < 1)
            break
        for idx, item in pageRows
        {
            k := item.officeCode . "|" . item.schoolCode
            if (!seen.HasKey(k))
            {
                seen[k] := 1
                results.Push(item)
            }
        }
    }
    return results
}

SSOK_EDU_StartClassCountLoad(officeCode, year, schools)
{
    global SSOK_EDU_ClassReqQueue, SSOK_EDU_ClassReqPending
    global SSOK_EDU_ClassReqNext, SSOK_EDU_ClassReqTotal, SSOK_EDU_ClassReqDone
    global SSOK_EDU_ClassReqOffice, SSOK_EDU_ClassReqYear, SSOK_EDU_ClassReqLoading

    SSOK_EDU_CancelClassCountLoad()
    if (officeCode = "" || year = "" || !IsObject(schools) || schools.Length() < 1)
        return

    SSOK_EDU_ClassReqQueue := []
    for idx, item in schools
    {
        schoolCode := Trim(item.schoolCode)
        if (schoolCode != "")
            SSOK_EDU_ClassReqQueue.Push(schoolCode)
    }

    SSOK_EDU_ClassReqPending := []
    SSOK_EDU_ClassReqNext := 1
    SSOK_EDU_ClassReqTotal := SSOK_EDU_ClassReqQueue.Length()
    SSOK_EDU_ClassReqDone := 0
    SSOK_EDU_ClassReqOffice := officeCode
    SSOK_EDU_ClassReqYear := year
    SSOK_EDU_ClassReqLoading := (SSOK_EDU_ClassReqTotal > 0)

    if (!SSOK_EDU_ClassReqLoading)
        return

    ; ¸ÕÀú ÇÔ¼ö¿¡¼­ ºüÁ®³ª°¡ ¸ñ·Ï GUI¸¦ Áï½Ã ±×¸° µÚ, Å¸ÀÌ¸Ó¿¡¼­ ÃÖ´ë 32°³¾¿ ºñµ¿±â Á¶È¸ÇÕ´Ï´Ù.
    SetTimer, SSOK_EDU_ClassCountPoll, 30
    SSOK_EDU_UpdateClassCountStatus()
}

SSOK_EDU_LaunchClassCountRequests()
{
    global SSOK_EDU_ClassReqQueue, SSOK_EDU_ClassReqPending
    global SSOK_EDU_ClassReqNext, SSOK_EDU_ClassReqTotal
    global SSOK_EDU_ClassReqOffice, SSOK_EDU_ClassReqYear

    maxActive := 32
    key := SSOK_EDU_GetApiKey()

    while (IsObject(SSOK_EDU_ClassReqPending)
        && SSOK_EDU_ClassReqPending.Length() < maxActive
        && SSOK_EDU_ClassReqNext <= SSOK_EDU_ClassReqTotal)
    {
        schoolCode := SSOK_EDU_ClassReqQueue[SSOK_EDU_ClassReqNext]
        SSOK_EDU_ClassReqNext++

        params := Object("ATPT_OFCDC_SC_CODE", SSOK_EDU_ClassReqOffice
                       , "SD_SCHUL_CODE", schoolCode
                       , "AY", SSOK_EDU_ClassReqYear)
        url := SSOK_EDU_BuildUrl("classInfo", params, 1, key, 1)

        try
        {
            http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            http.SetTimeouts(900, 1400, 2200, 3500)
            http.Open("GET", url, true)
            http.SetRequestHeader("User-Agent", "SSOK4edu")
            http.Send()
            SSOK_EDU_ClassReqPending.Push(Object("http", http
                                               , "schoolCode", schoolCode
                                               , "started", A_TickCount))
        }
        catch e
        {
            SSOK_EDU_ClassReqDone++
            SSOK_EDU_SetClassCountValue(schoolCode, "-")
        }
    }
}

SSOK_EDU_PollClassCountRequests()
{
    global SSOK_EDU_ClassReqPending, SSOK_EDU_ClassReqNext
    global SSOK_EDU_ClassReqTotal, SSOK_EDU_ClassReqDone, SSOK_EDU_ClassReqLoading

    if (!SSOK_EDU_ClassReqLoading || !IsObject(SSOK_EDU_ClassReqPending))
    {
        SetTimer, SSOK_EDU_ClassCountPoll, Off
        return
    }

    countPending := SSOK_EDU_ClassReqPending.Length()
    Loop, %countPending%
    {
        idx := countPending - A_Index + 1
        req := SSOK_EDU_ClassReqPending[idx]
        finished := false
        value := ""
        status := ""

        try status := req.http.Status
        catch e
            status := ""

        if (status >= 100)
        {
            finished := true
            if (status = 200)
            {
                try
                {
                    total := SSOK_EDU_ParseTotalCount(req.http.ResponseText)
                    value := (total > 0 ? total : "-")
                }
                catch e
                    value := "-"
            }
            else
                value := "-"
        }
        else if ((A_TickCount - req.started) > 5000)
        {
            finished := true
            value := "-"
            try req.http.Abort()
        }

        if (finished)
        {
            SSOK_EDU_ClassReqPending.RemoveAt(idx)
            SSOK_EDU_ClassReqDone++
            SSOK_EDU_SetClassCountValue(req.schoolCode, value)
        }
    }

    SSOK_EDU_LaunchClassCountRequests()
    SSOK_EDU_UpdateClassCountStatus()

    if (SSOK_EDU_ClassReqDone >= SSOK_EDU_ClassReqTotal
        && SSOK_EDU_ClassReqPending.Length() = 0
        && SSOK_EDU_ClassReqNext > SSOK_EDU_ClassReqTotal)
    {
        SSOK_EDU_ClassReqLoading := false
        SetTimer, SSOK_EDU_ClassCountPoll, Off
        SSOK_EDU_UpdateClassCountStatus()
    }
}

SSOK_EDU_SetClassCountValue(schoolCode, value)
{
    global SSOK_EDU_OrgSchools, SSOK_EDU_OrgSchoolList

    if (IsObject(SSOK_EDU_OrgSchools))
    {
        for idx, item in SSOK_EDU_OrgSchools
        {
            if (item.schoolCode = schoolCode)
            {
                item.classCount := value
                break
            }
        }
    }

    ; ÇöÀç ÇÊÅÍ/Á¤·Ä »óÅÂ¸¦ À¯ÁöÇÑ Ã¤ º¸ÀÌ´Â ÇàÀÇ ÇÐ±Þ¼ö ¼¿¸¸ °»½ÅÇÕ´Ï´Ù.
    Gui, SSOKEDUOrg:Default
    Gui, ListView, SSOK_EDU_OrgSchoolList
    rowCount := LV_GetCount()
    Loop, %rowCount%
    {
        LV_GetText(code, A_Index, 10)
        if (code = schoolCode)
        {
            LV_Modify(A_Index, "Col3", value)
            break
        }
    }
}

SSOK_EDU_UpdateClassCountStatus()
{
    global SSOK_EDU_OrgVisibleSchools, SSOK_EDU_OrgStatus, SSOK_EDU_OrgSearchMode, SSOK_EDU_OrgViewMode
    global SSOK_EDU_ClassReqLoading, SSOK_EDU_ClassReqDone, SSOK_EDU_ClassReqTotal

    if (SSOK_EDU_OrgViewMode = "office")
        return

    visibleCount := IsObject(SSOK_EDU_OrgVisibleSchools) ? SSOK_EDU_OrgVisibleSchools.Length() : 0
    isGlobal := (SSOK_EDU_OrgSearchMode = "global")
    status := isGlobal ? ("Àü±¹°Ë»ö " . visibleCount . "°³") : ("ÇÐ±³ " . visibleCount . "°³")
    if (!isGlobal && SSOK_EDU_ClassReqLoading && SSOK_EDU_ClassReqTotal > 0)
        status .= " ¡¤ ÇÐ±Þ¼ö " . SSOK_EDU_ClassReqDone . "/" . SSOK_EDU_ClassReqTotal
    GuiControl, SSOKEDUOrg:, SSOK_EDU_OrgStatus, %status%
}

SSOK_EDU_CancelClassCountLoad()
{
    global SSOK_EDU_ClassReqPending, SSOK_EDU_ClassReqQueue
    global SSOK_EDU_ClassReqNext, SSOK_EDU_ClassReqTotal, SSOK_EDU_ClassReqDone
    global SSOK_EDU_ClassReqOffice, SSOK_EDU_ClassReqYear, SSOK_EDU_ClassReqLoading

    SetTimer, SSOK_EDU_ClassCountPoll, Off
    if (IsObject(SSOK_EDU_ClassReqPending))
    {
        for idx, req in SSOK_EDU_ClassReqPending
        {
            try req.http.Abort()
        }
    }

    SSOK_EDU_ClassReqPending := []
    SSOK_EDU_ClassReqQueue := []
    SSOK_EDU_ClassReqNext := 1
    SSOK_EDU_ClassReqTotal := 0
    SSOK_EDU_ClassReqDone := 0
    SSOK_EDU_ClassReqOffice := ""
    SSOK_EDU_ClassReqYear := ""
    SSOK_EDU_ClassReqLoading := false
}

SSOK_EDU_AccumulateClassCounts(xml, ByRef counts, ByRef seen)
{
    added := 0
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return 0

        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            schoolCode := SSOK_EDU_XmlText(row, "SD_SCHUL_CODE")
            if (schoolCode = "")
                continue

            classKey := schoolCode . "|"
                      . SSOK_EDU_XmlText(row, "AY") . "|"
                      . SSOK_EDU_XmlText(row, "GRADE") . "|"
                      . SSOK_EDU_XmlText(row, "CLASS_NM") . "|"
                      . SSOK_EDU_XmlText(row, "SCHUL_CRSE_SC_NM") . "|"
                      . SSOK_EDU_XmlText(row, "ORD_SC_NM") . "|"
                      . SSOK_EDU_XmlText(row, "DDDEP_NM") . "|"
                      . SSOK_EDU_XmlText(row, "DGHT_CRSE_SC_NM")

            if (seen.HasKey(classKey))
                continue
            seen[classKey] := 1

            if (!counts.HasKey(schoolCode))
                counts[schoolCode] := 0
            counts[schoolCode] += 1
            added++
        }
    }
    catch
    {
        return added
    }
    return added
}

SSOK_EDU_SelectSchoolRow(row)
{
    global SSOK_EDU_SchoolResults
    if (!IsObject(SSOK_EDU_SchoolResults) || row < 1 || row > SSOK_EDU_SchoolResults.Length())
        return
    school := SSOK_EDU_SchoolResults[row]
    Gui, SSOKEDUSchool:Destroy
    SSOK_EDU_OpenSchool(school)
}

SSOK_EDU_OpenSchool(school)
{
    global SSOK_EDU_SelectedSchool, SSOK_EDU_MealDate, SSOK_EDU_TTDate
    global SSOK_EDU_TTGrade, SSOK_EDU_TTClass, SSOK_EDU_ScheduleMonth
    global SSOK_EDU_ClassYear, SSOK_EDU_ClassGrade, SSOK_EDU_ClassLV
    global SSOK_EDU_Tab, SSOK_EDU_SchoolInfoText, SSOK_EDU_MealDateText
    global SSOK_EDU_MealLV, SSOK_EDU_TTLV, SSOK_EDU_ScheduleMonthText, SSOK_EDU_ScheduleLV

    SSOK_EDU_SelectedSchool := school
    SSOK_EDU_MealDate := A_YYYY . A_MM . A_DD
    SSOK_EDU_TTDate := SSOK_EDU_MealDate
    SSOK_EDU_TTGrade := 1
    SSOK_EDU_TTClass := 1
    SSOK_EDU_ScheduleMonth := A_YYYY . A_MM
    SSOK_EDU_ClassYear := A_YYYY
    SSOK_EDU_ClassGrade := "ÀüÃ¼"

    Gui, SSOKEDU:Destroy
    Gui, SSOKEDU:New, +Resize +MinSize820x560 +LabelSSOK_EDU_Gui
    Gui, SSOKEDU:Color, F7FBFF
    Gui, SSOKEDU:Margin, 10, 10
    Gui, SSOKEDU:Font, s11 bold c005BAC, Malgun Gothic
    header := school.schoolName . "  ¡¤  " . school.kind . "  ¡¤  " . school.officeName
    Gui, SSOKEDU:Add, Text, x14 y10 w595 h24, %header%
    Gui, SSOKEDU:Font, s8 norm c4B5563, Malgun Gothic
    Gui, SSOKEDU:Add, Text, x14 y34 w760 h18, % school.address
    Gui, SSOKEDU:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKEDU:Add, Button, x600 y12 w96 h24 gSSOK_EDU_OpenOrgPicker, °üÇÒ ±³À°Ã»
    Gui, SSOKEDU:Add, Button, x700 y12 w70 h24 gSSOK_EDU_OpenHomepage, È¨ÆäÀÌÁö
    Gui, SSOKEDU:Add, Button, x774 y12 w70 h24 gSSOK_EDU_OpenPortal, NEIS

    Gui, SSOKEDU:Add, Tab3, x12 y58 w836 h470 vSSOK_EDU_Tab, ÇÐ±³Á¤º¸|½Ä´ÜÁ¤º¸|½Ã°£Ç¥|ÇÐ»çÀÏÁ¤|ÇÐ±ÞÁ¤º¸

    Gui, SSOKEDU:Tab, ÇÐ±³Á¤º¸
    schoolText := SSOK_EDU_FormatSchoolInfo(school)
    Gui, SSOKEDU:Add, Edit, x28 y96 w802 h405 vSSOK_EDU_SchoolInfoText ReadOnly +Multi -WantReturn, %schoolText%

    Gui, SSOKEDU:Tab, ½Ä´ÜÁ¤º¸
    Gui, SSOKEDU:Add, Button, x28 y94 w70 h26 gSSOK_EDU_MealPrev, ¢¸ ÀÌÀü³¯
    Gui, SSOKEDU:Add, Button, x102 y94 w60 h26 gSSOK_EDU_MealToday, ¿À´Ã
    Gui, SSOKEDU:Add, Button, x166 y94 w70 h26 gSSOK_EDU_MealNext, ´ÙÀ½³¯ ¢º
    Gui, SSOKEDU:Font, s10 bold c005BAC, Malgun Gothic
    Gui, SSOKEDU:Add, Text, x250 y98 w190 h22 vSSOK_EDU_MealDateText, % SSOK_EDU_FormatDate8(SSOK_EDU_MealDate)
    Gui, SSOKEDU:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKEDU:Add, ListView, x28 y130 w802 h365 vSSOK_EDU_MealLV, ³¯Â¥|±¸ºÐ|½Ä´Ü|Ä®·Î¸®

    Gui, SSOKEDU:Tab, ½Ã°£Ç¥
    Gui, SSOKEDU:Add, Button, x28 y94 w60 h26 gSSOK_EDU_TTPrev, ¢¸ ÀÌÀü
    Gui, SSOKEDU:Add, Button, x92 y94 w52 h26 gSSOK_EDU_TTToday, ¿À´Ã
    Gui, SSOKEDU:Add, Button, x148 y94 w60 h26 gSSOK_EDU_TTNext, ´ÙÀ½ ¢º
    Gui, SSOKEDU:Add, Text, x220 y100 w30 h18, ³¯Â¥
    Gui, SSOKEDU:Add, Edit, x252 y96 w82 h24 vSSOK_EDU_TTDate, %SSOK_EDU_TTDate%
    Gui, SSOKEDU:Add, Text, x348 y100 w30 h18, ÇÐ³â
    Gui, SSOKEDU:Add, DropDownList, x380 y96 w58 h220 vSSOK_EDU_TTGrade Choose1, 1|2|3|4|5|6
    Gui, SSOKEDU:Add, Text, x450 y100 w20 h18, ¹Ý
    Gui, SSOKEDU:Add, Edit, x472 y96 w42 h24 vSSOK_EDU_TTClass, 1
    Gui, SSOKEDU:Add, Button, x524 y95 w60 h26 gSSOK_EDU_TTLoad Default, Á¶È¸
    Gui, SSOKEDU:Add, ListView, x28 y130 w802 h365 vSSOK_EDU_TTLV, ³¯Â¥|ÇÐ³â|¹Ý|±³½Ã|¼ö¾÷³»¿ë

    Gui, SSOKEDU:Tab, ÇÐ»çÀÏÁ¤
    Gui, SSOKEDU:Add, Button, x28 y94 w70 h26 gSSOK_EDU_SchedulePrev, ¢¸ ÀÌÀü´Þ
    Gui, SSOKEDU:Add, Button, x102 y94 w60 h26 gSSOK_EDU_ScheduleThis, ÀÌ¹ø´Þ
    Gui, SSOKEDU:Add, Button, x166 y94 w70 h26 gSSOK_EDU_ScheduleNext, ´ÙÀ½´Þ ¢º
    Gui, SSOKEDU:Font, s10 bold c005BAC, Malgun Gothic
    Gui, SSOKEDU:Add, Text, x250 y98 w190 h22 vSSOK_EDU_ScheduleMonthText, % SSOK_EDU_FormatMonth(SSOK_EDU_ScheduleMonth)
    Gui, SSOKEDU:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKEDU:Add, ListView, x28 y130 w802 h365 vSSOK_EDU_ScheduleLV, ³¯Â¥|Çà»ç¸í|³»¿ë

    Gui, SSOKEDU:Tab, ÇÐ±ÞÁ¤º¸
    Gui, SSOKEDU:Add, Text, x28 y100 w42 h18, ÇÐ³âµµ
    Gui, SSOKEDU:Add, Edit, x72 y96 w62 h24 vSSOK_EDU_ClassYear, %SSOK_EDU_ClassYear%
    Gui, SSOKEDU:Add, Text, x150 y100 w30 h18, ÇÐ³â
    Gui, SSOKEDU:Add, DropDownList, x182 y96 w70 h220 vSSOK_EDU_ClassGrade Choose1, ÀüÃ¼|1|2|3|4|5|6
    Gui, SSOKEDU:Add, Button, x266 y95 w60 h26 gSSOK_EDU_ClassLoad, Á¶È¸
    Gui, SSOKEDU:Add, ListView, x28 y130 w802 h365 vSSOK_EDU_ClassLV, ÇÐ³âµµ|ÇÐ³â|¹Ý|ÇÐ±³°úÁ¤|°è¿­|ÇÐ°ú|ÁÖ¾ß

    Gui, SSOKEDU:Tab
    Gui, SSOKEDU:Show, w860 h545, SSOK4edu ±³À°Á¤º¸

    SSOK_EDU_LoadMeal()
    SSOK_EDU_LoadTimetable()
    SSOK_EDU_LoadSchedule()
    SSOK_EDU_LoadClassInfo()
}

SSOK_EDU_LoadMeal()
{
    global SSOK_EDU_SelectedSchool, SSOK_EDU_MealDate, SSOK_EDU_MealDateText, SSOK_EDU_MealLV
    if (!IsObject(SSOK_EDU_SelectedSchool))
        return

    GuiControl, SSOKEDU:, SSOK_EDU_MealDateText, % SSOK_EDU_FormatDate8(SSOK_EDU_MealDate)
    p := Object("ATPT_OFCDC_SC_CODE", SSOK_EDU_SelectedSchool.officeCode
              , "SD_SCHUL_CODE", SSOK_EDU_SelectedSchool.schoolCode
              , "MLSV_YMD", SSOK_EDU_MealDate)
    url := SSOK_EDU_BuildUrl("mealServiceDietInfo", p, 50, SSOK_EDU_GetApiKey())
    resp := SSOK_EDU_HttpGet(url)
    rows := resp.ok ? SSOK_EDU_ParseMeal(resp.text) : []

    Gui, SSOKEDU:Default
    Gui, ListView, SSOK_EDU_MealLV
    LV_Delete()
    if (!IsObject(rows) || rows.Length() < 1)
        LV_Add("", SSOK_EDU_FormatDate8(SSOK_EDU_MealDate), "-", "±Þ½Ä Á¤º¸°¡ ¾ø½À´Ï´Ù.", "")
    else
    {
        for idx, item in rows
            LV_Add("", SSOK_EDU_FormatDate8(item.date), item.mealName, item.dish, item.calorie)
    }
    LV_ModifyCol(1, 95)
    LV_ModifyCol(2, 80)
    LV_ModifyCol(3, 500)
    LV_ModifyCol(4, 90)
}

SSOK_EDU_LoadTimetable()
{
    global SSOK_EDU_SelectedSchool, SSOK_EDU_TTDate, SSOK_EDU_TTGrade, SSOK_EDU_TTClass, SSOK_EDU_TTLV
    if (!IsObject(SSOK_EDU_SelectedSchool))
        return

    Gui, SSOKEDU:Submit, NoHide
    date := SSOK_EDU_NormalizeDate(SSOK_EDU_TTDate)
    if (StrLen(date) != 8)
    {
        MsgBox, 48, SSOK ±³À°Á¤º¸, ³¯Â¥¸¦ 20260921 ¶Ç´Â 2026.9.21 Çü½ÄÀ¸·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_EDU_TTDate := date
    GuiControl, SSOKEDU:, SSOK_EDU_TTDate, %date%
    endpoint := SSOK_EDU_TimetableEndpoint(SSOK_EDU_SelectedSchool.kind)

    Gui, SSOKEDU:Default
    Gui, ListView, SSOK_EDU_TTLV
    LV_Delete()
    if (endpoint = "")
    {
        LV_Add("", SSOK_EDU_FormatDate8(date), "-", "-", "ÇØ´ç ÇÐ±³±ÞÀÇ ½Ã°£Ç¥ API¸¦ Áö¿øÇÏÁö ¾Ê½À´Ï´Ù.")
        return
    }

    p := Object("ATPT_OFCDC_SC_CODE", SSOK_EDU_SelectedSchool.officeCode
              , "SD_SCHUL_CODE", SSOK_EDU_SelectedSchool.schoolCode
              , "ALL_TI_YMD", date
              , "GRADE", SSOK_EDU_TTGrade
              , "CLASS_NM", SSOK_EDU_TTClass)
    url := SSOK_EDU_BuildUrl(endpoint, p, 100, SSOK_EDU_GetApiKey())
    resp := SSOK_EDU_HttpGet(url)
    rows := resp.ok ? SSOK_EDU_ParseTimetable(resp.text) : []
    if (!IsObject(rows) || rows.Length() < 1)
        LV_Add("", SSOK_EDU_FormatDate8(date), SSOK_EDU_TTGrade, SSOK_EDU_TTClass, "½Ã°£Ç¥ Á¤º¸°¡ ¾ø½À´Ï´Ù.")
    else
    {
        for idx, item in rows
            LV_Add("", SSOK_EDU_FormatDate8(item.date), item.grade, item.className, item.period . "±³½Ã  " . item.content)
    }
    LV_ModifyCol(1, 100)
    LV_ModifyCol(2, 60)
    LV_ModifyCol(3, 60)
    LV_ModifyCol(4, 80)
    LV_ModifyCol(5, 470)
}

SSOK_EDU_LoadSchedule()
{
    global SSOK_EDU_SelectedSchool, SSOK_EDU_ScheduleMonth, SSOK_EDU_ScheduleMonthText, SSOK_EDU_ScheduleLV
    if (!IsObject(SSOK_EDU_SelectedSchool))
        return

    GuiControl, SSOKEDU:, SSOK_EDU_ScheduleMonthText, % SSOK_EDU_FormatMonth(SSOK_EDU_ScheduleMonth)
    fromDate := SSOK_EDU_ScheduleMonth . "01"
    nextMonth := SSOK_EDU_ShiftMonth(SSOK_EDU_ScheduleMonth, 1)
    toDate := SSOK_EDU_ShiftDate(nextMonth . "01", -1)
    p := Object("ATPT_OFCDC_SC_CODE", SSOK_EDU_SelectedSchool.officeCode
              , "SD_SCHUL_CODE", SSOK_EDU_SelectedSchool.schoolCode
              , "AA_FROM_YMD", fromDate
              , "AA_TO_YMD", toDate)
    url := SSOK_EDU_BuildUrl("SchoolSchedule", p, 100, SSOK_EDU_GetApiKey())
    resp := SSOK_EDU_HttpGet(url)
    rows := resp.ok ? SSOK_EDU_ParseSchedule(resp.text) : []

    Gui, SSOKEDU:Default
    Gui, ListView, SSOK_EDU_ScheduleLV
    LV_Delete()
    if (!IsObject(rows) || rows.Length() < 1)
        LV_Add("", SSOK_EDU_FormatMonth(SSOK_EDU_ScheduleMonth), "-", "ÇÐ»çÀÏÁ¤ Á¤º¸°¡ ¾ø½À´Ï´Ù.")
    else
    {
        for idx, item in rows
            LV_Add("", SSOK_EDU_FormatDate8(item.date), item.eventName, item.content)
    }
    LV_ModifyCol(1, 100)
    LV_ModifyCol(2, 210)
    LV_ModifyCol(3, 470)
}

SSOK_EDU_LoadClassInfo()
{
    global SSOK_EDU_SelectedSchool, SSOK_EDU_ClassYear, SSOK_EDU_ClassGrade, SSOK_EDU_ClassLV
    if (!IsObject(SSOK_EDU_SelectedSchool))
        return

    Gui, SSOKEDU:Submit, NoHide
    year := RegExReplace(Trim(SSOK_EDU_ClassYear), "[^0-9]", "")
    if (StrLen(year) != 4)
    {
        MsgBox, 48, SSOK ±³À°Á¤º¸, ÇÐ³âµµ¸¦ 2026Ã³·³ 4ÀÚ¸®·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_EDU_ClassYear := year
    GuiControl, SSOKEDU:, SSOK_EDU_ClassYear, %year%

    p := Object("ATPT_OFCDC_SC_CODE", SSOK_EDU_SelectedSchool.officeCode
              , "SD_SCHUL_CODE", SSOK_EDU_SelectedSchool.schoolCode
              , "AY", year)
    grade := Trim(SSOK_EDU_ClassGrade)
    if (grade != "" && grade != "ÀüÃ¼")
        p["GRADE"] := grade

    url := SSOK_EDU_BuildUrl("classInfo", p, 500, SSOK_EDU_GetApiKey())
    resp := SSOK_EDU_HttpGet(url)
    rows := resp.ok ? SSOK_EDU_ParseClassInfo(resp.text) : []

    Gui, SSOKEDU:Default
    Gui, ListView, SSOK_EDU_ClassLV
    LV_Delete()
    if (!IsObject(rows) || rows.Length() < 1)
        LV_Add("", year, grade, "-", "-", "-", "ÇÐ±ÞÁ¤º¸°¡ ¾ø½À´Ï´Ù.", "-")
    else
    {
        for idx, item in rows
            LV_Add("", item.year, item.grade, item.className, item.course, item.series, item.department, item.dayNight)
    }
    LV_ModifyCol(1, 70)
    LV_ModifyCol(2, 55)
    LV_ModifyCol(3, 55)
    LV_ModifyCol(4, 120)
    LV_ModifyCol(5, 100)
    LV_ModifyCol(6, 300)
    LV_ModifyCol(7, 70)
}

SSOK_EDU_GetApiKey()
{
    ; SSOK4edu °ø¿ë ³ªÀÌ½º ±³À°Á¤º¸ °³¹æ Æ÷ÅÐ ÀÎÁõÅ°¸¦ ÇÁ·Î±×·¥¿¡¼­ Á÷Á¢ »ç¿ëÇÕ´Ï´Ù.
    return "bdf805328d4546d1a4574fd266f5ae63"
}

SSOK_EDU_BuildUrl(endpoint, params, pageSize := 100, key := "", pageIndex := 1)
{
    if (key = "")
        key := SSOK_EDU_GetApiKey()
    url := "https://open.neis.go.kr/hub/" . endpoint
         . "?KEY=" . SSOK_QU_UrlEncode(key)
         . "&Type=xml&pIndex=" . pageIndex . "&pSize=" . pageSize
    if (IsObject(params))
    {
        for k, v in params
        {
            v := Trim(v)
            if (v != "")
                url .= "&" . k . "=" . SSOK_QU_UrlEncode(v)
        }
    }
    return url
}

SSOK_EDU_HttpGet(url)
{
    out := Object("ok", false, "text", "", "status", 0)
    try
    {
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(1500, 3000, 5000, 7000)
        http.Open("GET", url, false)
        http.SetRequestHeader("User-Agent", "SSOK4edu")
        http.Send()
        out.status := http.Status
        if (http.Status = 200)
        {
            out.text := http.ResponseText
            out.ok := true
        }
    }
    catch e
    {
        out.ok := false
    }
    return out
}

SSOK_EDU_ParseTotalCount(xml)
{
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return 0
        node := dom.selectSingleNode("//*[local-name()='list_total_count']")
        if (IsObject(node))
            return Trim(node.text) + 0
    }
    catch
    {
    }
    return 0
}

SSOK_EDU_ParseSchools(xml)
{
    results := []
    seen := {}
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results
        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            schoolName := SSOK_EDU_XmlText(row, "SCHUL_NM")
            officeCode := SSOK_EDU_XmlText(row, "ATPT_OFCDC_SC_CODE")
            schoolCode := SSOK_EDU_XmlText(row, "SD_SCHUL_CODE")
            if (schoolName = "" || officeCode = "" || schoolCode = "")
                continue
            key := officeCode . "|" . schoolCode
            if (seen.HasKey(key))
                continue
            seen[key] := 1
            results.Push(Object("schoolName", SSOK_EDU_CleanText(schoolName)
                              , "officeCode", officeCode
                              , "officeName", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "ATPT_OFCDC_SC_NM"))
                              , "schoolCode", schoolCode
                              , "kind", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "SCHUL_KND_SC_NM"))
                              , "location", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "LCTN_SC_NM"))
                              , "parentOrg", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "JU_ORG_NM"))
                              , "foundation", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "FOND_SC_NM"))
                              , "address", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "ORG_RDNMA"))
                              , "addressDetail", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "ORG_RDNDA"))
                              , "tel", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "ORG_TELNO"))
                              , "fax", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "ORG_FAXNO"))
                              , "homepage", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "HMPG_ADRES"))
                              , "coedu", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "COEDU_SC_NM"))
                              , "dayNight", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "DGHT_SC_NM"))
                              , "foundDate", SSOK_EDU_XmlText(row, "FOND_YMD")
                              , "anniversary", SSOK_EDU_XmlText(row, "FOAS_MEMRD")))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_EDU_ParseMeal(xml)
{
    results := []
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results
        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            date := SSOK_EDU_XmlText(row, "MLSV_YMD")
            dish := SSOK_EDU_CleanMealText(SSOK_EDU_XmlText(row, "DDISH_NM"))
            if (date = "" && dish = "")
                continue
            results.Push(Object("date", date
                              , "mealName", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "MMEAL_SC_NM"))
                              , "dish", dish
                              , "calorie", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "CAL_INFO"))))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_EDU_ParseTimetable(xml)
{
    results := []
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results
        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            date := SSOK_EDU_XmlText(row, "ALL_TI_YMD")
            content := SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "ITRT_CNTNT"))
            if (date = "" && content = "")
                continue
            results.Push(Object("date", date
                              , "grade", SSOK_EDU_XmlText(row, "GRADE")
                              , "className", SSOK_EDU_XmlText(row, "CLASS_NM")
                              , "period", SSOK_EDU_XmlText(row, "PERIO")
                              , "content", content))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_EDU_ParseClassInfo(xml)
{
    results := []
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results
        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            year := SSOK_EDU_XmlText(row, "AY")
            grade := SSOK_EDU_XmlText(row, "GRADE")
            className := SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "CLASS_NM"))
            if (year = "" && grade = "" && className = "")
                continue
            results.Push(Object("year", year
                              , "grade", grade
                              , "className", className
                              , "course", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "SCHUL_CRSE_SC_NM"))
                              , "series", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "ORD_SC_NM"))
                              , "department", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "DDDEP_NM"))
                              , "dayNight", SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "DGHT_CRSE_SC_NM"))))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_EDU_ParseSchedule(xml)
{
    results := []
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results
        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            date := SSOK_EDU_XmlText(row, "AA_YMD")
            eventName := SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "EVENT_NM"))
            content := SSOK_EDU_CleanText(SSOK_EDU_XmlText(row, "EVENT_CNTNT"))
            if (date = "" && eventName = "")
                continue
            results.Push(Object("date", date, "eventName", eventName, "content", content))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_EDU_XmlText(parent, tagName)
{
    if (!IsObject(parent) || tagName = "")
        return ""
    try
    {
        node := parent.selectSingleNode(".//*[local-name()='" . tagName . "']")
        if (IsObject(node))
            return Trim(node.text)
    }
    catch
    {
    }
    return ""
}

SSOK_EDU_ParseResultMessage(xml)
{
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return ""
        node := dom.selectSingleNode("//*[local-name()='MESSAGE']")
        if (IsObject(node))
            return Trim(node.text)
    }
    catch
    {
    }
    return ""
}

SSOK_EDU_CleanText(text)
{
    text := StrReplace(text, "`r", " ")
    text := StrReplace(text, "`n", " ")
    text := RegExReplace(text, "\s+", " ")
    return Trim(text)
}

SSOK_EDU_CleanMealText(text)
{
    text := StrReplace(text, "<br/>", " / ")
    text := StrReplace(text, "<br />", " / ")
    text := StrReplace(text, "<br>", " / ")
    text := RegExReplace(text, "<[^>]+>", "")
    text := RegExReplace(text, "\s+", " ")
    return Trim(text)
}

SSOK_EDU_FormatSchoolInfo(school)
{
    if (!IsObject(school))
        return ""
    txt := "ÇÐ±³¸í : " . school.schoolName . "`r`n"
    txt .= "ÇÐ±³±Þ : " . school.kind . "`r`n"
    txt .= "±³À°Ã» : " . school.officeName . "`r`n"
    if (school.parentOrg != "")
        txt .= "°üÇÒ±â°ü : " . school.parentOrg . "`r`n"
    if (school.foundation != "")
        txt .= "¼³¸³±¸ºÐ : " . school.foundation . "`r`n"
    if (school.coedu != "")
        txt .= "³²³à°øÇÐ : " . school.coedu . "`r`n"
    if (school.dayNight != "")
        txt .= "ÁÖ¾ß±¸ºÐ : " . school.dayNight . "`r`n"
    txt .= "ÁÖ¼Ò : " . school.address
    if (school.addressDetail != "")
        txt .= " " . school.addressDetail
    txt .= "`r`n"
    if (school.tel != "")
        txt .= "ÀüÈ­ : " . school.tel . "`r`n"
    if (school.fax != "")
        txt .= "ÆÑ½º : " . school.fax . "`r`n"
    if (school.homepage != "")
        txt .= "È¨ÆäÀÌÁö : " . school.homepage . "`r`n"
    if (school.foundDate != "")
        txt .= "¼³¸³ÀÏ : " . SSOK_EDU_FormatDate8(school.foundDate) . "`r`n"
    if (school.anniversary != "")
        txt .= "°³±³±â³äÀÏ : " . school.anniversary . "`r`n"
    txt .= "±³À°Ã»ÄÚµå : " . school.officeCode . "`r`nÇÐ±³ÄÚµå : " . school.schoolCode
    return txt
}

SSOK_EDU_TimetableEndpoint(kind)
{
    if InStr(kind, "ÃÊµî")
        return "elsTimetable"
    if InStr(kind, "Áß")
        return "misTimetable"
    if InStr(kind, "°íµî")
        return "hisTimetable"
    if InStr(kind, "°í")
        return "hisTimetable"
    return ""
}

SSOK_EDU_NormalizeDate(s)
{
    d := RegExReplace(Trim(s), "[^0-9]", "")
    if (StrLen(d) = 8)
        return d
    return ""
}

SSOK_EDU_FormatDate8(ymd)
{
    d := SSOK_EDU_NormalizeDate(ymd)
    if (StrLen(d) != 8)
        return ymd
    return SubStr(d, 1, 4) . ". " . (SubStr(d, 5, 2) + 0) . ". " . (SubStr(d, 7, 2) + 0) . "."
}

SSOK_EDU_FormatMonth(yyyymm)
{
    d := RegExReplace(Trim(yyyymm), "[^0-9]", "")
    if (StrLen(d) != 6)
        return yyyymm
    return SubStr(d, 1, 4) . ". " . (SubStr(d, 5, 2) + 0) . "."
}

SSOK_EDU_ShiftDate(ymd, days)
{
    d := SSOK_EDU_NormalizeDate(ymd)
    if (StrLen(d) != 8)
        d := A_YYYY . A_MM . A_DD
    ts := d . "000000"
    EnvAdd, ts, %days%, Days
    return SubStr(ts, 1, 8)
}

SSOK_EDU_ShiftMonth(yyyymm, delta)
{
    d := RegExReplace(Trim(yyyymm), "[^0-9]", "")
    if (StrLen(d) != 6)
        d := A_YYYY . A_MM
    y := SubStr(d, 1, 4) + 0
    m := SubStr(d, 5, 2) + 0
    total := y * 12 + (m - 1) + delta
    newY := Floor(total / 12)
    newM := Mod(total, 12) + 1
    return Format("{:04}{:02}", newY, newM)
}

SSOK_LAW_ResultEvent:
    if (A_GuiEvent = "Normal" || A_GuiEvent = "DoubleClick")
    {
        ctrl := A_GuiControl
        row := A_EventInfo
        if (row < 1)
        {
            Gui, SSOKLaw:ListView, %ctrl%
            row := LV_GetNext(0, "F")
        }
        if (row > 0)
        {
            SSOK_LAW_UpdateDetailForControl(ctrl, row)
            if (A_GuiEvent = "DoubleClick")
                SSOK_LAW_OpenSelected(ctrl)
        }
    }
return

SSOK_LAW_TabChanged:
    SSOK_LAW_UpdateDetailForCurrentTab()
return

SSOK_LAW_OpenSelectedButton:
    SSOK_LAW_OpenSelected()
return

SSOK_LAW_OpenWebSearch:
    if (Trim(SSOK_LAW_LastQuery) != "")
    {
        url := "https://www.law.go.kr/LSW/ais/searchList.do?aiBoardQuery=" . SSOK_QU_UrlEncode(SSOK_LAW_LastQuery) . "&pageIndex=1"
        SSOK_OpenUrlPreferred(url)
    }
return

SSOK_LAW_GuiClose:
SSOK_LAW_GuiEscape:
    Gui, SSOKLaw:Destroy
return

SSOK_LAW_RunSearch(query)
{
    global SSOK_IniFile, SSOK_LAW_LastQuery
    global SSOK_LAW_LawResults, SSOK_LAW_AdminResults, SSOK_LAW_OrdinResults
    global SSOK_LAW_PrecResults, SSOK_LAW_DetcResults, SSOK_LAW_ExpcResults, SSOK_LAW_DeccResults
    global SSOK_LAW_MoeResults, SSOK_LAW_BylResults, SSOK_LAW_SelectedRows

    q := Trim(query)
    if (q = "")
        return

    ; ¹ýÁ¦Ã³ ±¹°¡¹ý·ÉÁ¤º¸ °øµ¿È°¿ë OPEN API ÀÎÁõ°ª
    oc := "ssok4edu"
    if (FileExist(SSOK_IniFile))
    {
        IniRead, savedOc, %SSOK_IniFile%, LawApi, OC, __SSOK_EMPTY__
        savedOc := Trim(savedOc)
        if (savedOc != "" && savedOc != "ERROR" && savedOc != "__SSOK_EMPTY__")
            oc := savedOc
    }

    ; 1) ¹ý·É: Áö´ÉÇü ¹ý·É°Ë»ö(Á¶¹®)
    lawUrl := "https://www.law.go.kr/DRF/lawSearch.do?OC=" . SSOK_QU_UrlEncode(oc)
           . "&target=aiSearch&type=XML&search=0&query=" . SSOK_QU_UrlEncode(q)
           . "&display=30&page=1"

    ; 2) ÇàÁ¤±ÔÄ¢ / 3) ÀÚÄ¡¹ý±Ô / 4) ÆÇ·Ê / 5) ÇåÀç°áÁ¤·Ê
    ; 6) ¹ý·ÉÇØ¼®·Ê / 7) ÇàÁ¤½ÉÆÇ·Ê / 8) ±³À°ºÎÇØ¼®
    adminUrl := SSOK_LAW_BuildSearchUrl(oc, "admrul", q, 2, 25)
    ordinUrl := SSOK_LAW_BuildSearchUrl(oc, "ordin", q, 2, 25)
    precUrl  := SSOK_LAW_BuildSearchUrl(oc, "prec", q, 2, 25)
    detcUrl  := SSOK_LAW_BuildSearchUrl(oc, "detc", q, 2, 25)
    expcUrl  := SSOK_LAW_BuildSearchUrl(oc, "expc", q, 2, 25)
    deccUrl  := SSOK_LAW_BuildSearchUrl(oc, "decc", q, 2, 25)
    moeUrl   := SSOK_LAW_BuildSearchUrl(oc, "moeCgmExpc", q, 2, 25)

    ; 9) º°Ç¥¼­½Ä: º°Ç¥¼­½Ä¸í + ÇØ´ç ¹ý·É¸í °Ë»öÀ» ÇÕÃÄ¼­ Ç¥½Ã
    bylNameUrl := SSOK_LAW_BuildSearchUrl(oc, "licbyl", q, 1, 25)
    bylLawUrl  := SSOK_LAW_BuildSearchUrl(oc, "licbyl", q, 2, 25)

    lawResp     := SSOK_LAW_HttpGet(lawUrl)
    adminResp   := SSOK_LAW_HttpGet(adminUrl)
    ordinResp   := SSOK_LAW_HttpGet(ordinUrl)
    precResp    := SSOK_LAW_HttpGet(precUrl)
    detcResp    := SSOK_LAW_HttpGet(detcUrl)
    expcResp    := SSOK_LAW_HttpGet(expcUrl)
    deccResp    := SSOK_LAW_HttpGet(deccUrl)
    moeResp     := SSOK_LAW_HttpGet(moeUrl)
    bylNameResp := SSOK_LAW_HttpGet(bylNameUrl)
    bylLawResp  := SSOK_LAW_HttpGet(bylLawUrl)

    SSOK_LAW_LawResults   := lawResp.ok   ? SSOK_LAW_ParseAiSearchXml(lawResp.text)              : []
    SSOK_LAW_AdminResults := adminResp.ok ? SSOK_LAW_ParseCategoryXml(adminResp.text, "admrul") : []
    SSOK_LAW_OrdinResults := ordinResp.ok ? SSOK_LAW_ParseCategoryXml(ordinResp.text, "ordin")  : []
    SSOK_LAW_PrecResults  := precResp.ok  ? SSOK_LAW_ParseReferenceXml(precResp.text, "prec")   : []
    SSOK_LAW_DetcResults  := detcResp.ok  ? SSOK_LAW_ParseReferenceXml(detcResp.text, "detc")   : []
    SSOK_LAW_ExpcResults  := expcResp.ok  ? SSOK_LAW_ParseReferenceXml(expcResp.text, "expc")   : []
    SSOK_LAW_DeccResults  := deccResp.ok  ? SSOK_LAW_ParseReferenceXml(deccResp.text, "decc")   : []
    SSOK_LAW_MoeResults   := moeResp.ok   ? SSOK_LAW_ParseCategoryXml(moeResp.text, "moe")      : []
    SSOK_LAW_BylResults   := bylNameResp.ok ? SSOK_LAW_ParseBylXml(bylNameResp.text) : []
    if (bylLawResp.ok)
        SSOK_LAW_BylResults := SSOK_LAW_MergeUnique(SSOK_LAW_BylResults, SSOK_LAW_ParseBylXml(bylLawResp.text))

    total := SSOK_LAW_Count(SSOK_LAW_LawResults)
           + SSOK_LAW_Count(SSOK_LAW_AdminResults)
           + SSOK_LAW_Count(SSOK_LAW_OrdinResults)
           + SSOK_LAW_Count(SSOK_LAW_PrecResults)
           + SSOK_LAW_Count(SSOK_LAW_DetcResults)
           + SSOK_LAW_Count(SSOK_LAW_ExpcResults)
           + SSOK_LAW_Count(SSOK_LAW_DeccResults)
           + SSOK_LAW_Count(SSOK_LAW_MoeResults)
           + SSOK_LAW_Count(SSOK_LAW_BylResults)

    SSOK_LAW_LastQuery := q
    SSOK_LAW_SelectedRows := Object("law", 1, "admrul", 1, "ordin", 1, "prec", 1, "detc", 1, "expc", 1, "decc", 1, "moe", 1, "byl", 1)

    if (total < 1)
    {
        allFailed := !lawResp.ok && !adminResp.ok && !ordinResp.ok && !precResp.ok && !detcResp.ok
                  && !expcResp.ok && !deccResp.ok && !moeResp.ok && !bylNameResp.ok && !bylLawResp.ok
        if (allFailed)
        {
            MsgBox, 48, SSOK ¹ý·ÉÁ¤º¸ °Ë»ö, ¹ý·ÉÁ¤º¸ OPEN API¿¡ ¿¬°áÇÏÁö ¸øÇß½À´Ï´Ù.`n`n±¹°¡¹ý·ÉÁ¤º¸¼¾ÅÍ °Ë»ö ÆäÀÌÁö¸¦ ¿±´Ï´Ù.
            url2 := "https://www.law.go.kr/LSW/ais/searchList.do?aiBoardQuery=" . SSOK_QU_UrlEncode(q) . "&pageIndex=1"
            SSOK_OpenUrlPreferred(url2)
            return
        }
        MsgBox, 48, SSOK ¹ý·ÉÁ¤º¸ °Ë»ö, ¹ý·É¡¤ÇàÁ¤±ÔÄ¢¡¤ÀÚÄ¡¹ý±Ô¡¤ÆÇ·Ê¡¤ÇåÀç°áÁ¤·Ê¡¤¹ý·ÉÇØ¼®·Ê¡¤ÇàÁ¤½ÉÆÇ·Ê¡¤±³À°ºÎÇØ¼®¡¤º°Ç¥¼­½Ä¿¡¼­ °Ë»ö °á°ú¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.
        return
    }

    SSOK_LAW_ShowResults(q)
}

SSOK_LAW_BuildSearchUrl(oc, target, query, searchMode := 2, display := 25)
{
    return "https://www.law.go.kr/DRF/lawSearch.do?OC=" . SSOK_QU_UrlEncode(oc)
         . "&target=" . SSOK_QU_UrlEncode(target)
         . "&type=XML&search=" . searchMode
         . "&query=" . SSOK_QU_UrlEncode(query)
         . "&display=" . display . "&page=1"
}

SSOK_LAW_HttpGet(url)
{
    out := Object("ok", false, "text", "", "status", 0)
    try
    {
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(1500, 3000, 5000, 7000)
        http.Open("GET", url, false)
        http.Send()
        out.status := http.Status
        if (http.Status = 200)
        {
            out.text := http.ResponseText
            out.ok := true
        }
    }
    catch e
    {
        out.ok := false
    }
    return out
}

SSOK_LAW_ParseAiSearchXml(xml)
{
    results := []
    seen := {}
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results

        nodes := dom.selectNodes("//*[local-name()='¹ý·É¸í']")
        Loop, % nodes.length
        {
            nameNode := nodes.item(A_Index - 1)
            parent := nameNode.parentNode
            lawName := SSOK_LAW_XmlText(parent, "¹ý·É¸í")
            if (lawName = "")
                lawName := Trim(nameNode.text)
            if (lawName = "")
                continue

            seq := SSOK_LAW_XmlText(parent, "¹ý·ÉÀÏ·Ã¹øÈ£")
            lawId := SSOK_LAW_XmlText(parent, "¹ý·ÉID")
            jo := SSOK_LAW_XmlText(parent, "Á¶¹®¹øÈ£")
            joBranch := SSOK_LAW_XmlText(parent, "Á¶¹®°¡Áö¹øÈ£")
            joTitle := SSOK_LAW_XmlText(parent, "Á¶¹®Á¦¸ñ")
            joText := SSOK_LAW_XmlText(parent, "Á¶¹®³»¿ë")
            dept := SSOK_LAW_XmlText(parent, "¼Ò°üºÎÃ³¸í")
            eff := SSOK_LAW_XmlText(parent, "½ÃÇàÀÏÀÚ")
            lawType := SSOK_LAW_XmlText(parent, "¹ý·ÉÁ¾·ù¸í")

            key := seq . "|" . lawId . "|" . jo . "|" . joBranch . "|" . joTitle
            if (seen.HasKey(key))
                continue
            seen[key] := 1

            results.Push(Object("category", "law"
                              , "lawName", SSOK_LAW_CleanText(lawName)
                              , "seq", seq
                              , "lawId", lawId
                              , "jo", jo
                              , "joBranch", joBranch
                              , "joTitle", SSOK_LAW_CleanText(joTitle)
                              , "joText", SSOK_LAW_CleanText(joText)
                              , "dept", SSOK_LAW_CleanText(dept)
                              , "eff", eff
                              , "lawType", SSOK_LAW_CleanText(lawType)
                              , "detailLink", ""
                              , "itemNo", ""
                              , "relatedName", ""))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_LAW_ParseCategoryXml(xml, category)
{
    results := []
    seen := {}

    if (category = "admrul")
    {
        keyTag := "ÇàÁ¤±ÔÄ¢ÀÏ·Ã¹øÈ£"
        nameTag := "ÇàÁ¤±ÔÄ¢¸í"
        typeTag := "ÇàÁ¤±ÔÄ¢Á¾·ù"
        deptTag := "¼Ò°üºÎÃ³¸í"
        dateTag := "½ÃÇàÀÏÀÚ"
        idTag := "ÇàÁ¤±ÔÄ¢ID"
        linkTag := "ÇàÁ¤±ÔÄ¢»ó¼¼¸µÅ©"
    }
    else if (category = "ordin")
    {
        keyTag := "ÀÚÄ¡¹ý±ÔÀÏ·Ã¹øÈ£"
        nameTag := "ÀÚÄ¡¹ý±Ô¸í"
        typeTag := "ÀÚÄ¡¹ý±ÔÁ¾·ù"
        deptTag := "ÁöÀÚÃ¼±â°ü¸í"
        dateTag := "½ÃÇàÀÏÀÚ"
        idTag := "ÀÚÄ¡¹ý±ÔID"
        linkTag := "ÀÚÄ¡¹ý±Ô»ó¼¼¸µÅ©"
    }
    else if (category = "moe")
    {
        keyTag := "¹ý·ÉÇØ¼®ÀÏ·Ã¹øÈ£"
        nameTag := "¾È°Ç¸í"
        typeTag := ""
        deptTag := "ÇØ¼®±â°ü¸í"
        dateTag := "ÇØ¼®ÀÏÀÚ"
        idTag := ""
        linkTag := "¹ý·ÉÇØ¼®»ó¼¼¸µÅ©"
    }
    else
        return results

    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results

        nodes := dom.selectNodes("//*[local-name()='" . keyTag . "']")
        Loop, % nodes.length
        {
            seqNode := nodes.item(A_Index - 1)
            parent := seqNode.parentNode
            seq := Trim(seqNode.text)
            name := SSOK_LAW_XmlText(parent, nameTag)
            if (name = "")
                continue

            lawId := (idTag != "") ? SSOK_LAW_XmlText(parent, idTag) : ""
            lawType := (typeTag != "") ? SSOK_LAW_XmlText(parent, typeTag) : "±³À°ºÎÇØ¼®"
            dept := SSOK_LAW_XmlText(parent, deptTag)
            eff := SSOK_LAW_XmlText(parent, dateTag)
            detailLink := SSOK_LAW_XmlText(parent, linkTag)
            itemNo := (category = "moe") ? SSOK_LAW_XmlText(parent, "¾È°Ç¹øÈ£") : ""

            key := category . "|" . seq . "|" . name
            if (seen.HasKey(key))
                continue
            seen[key] := 1

            results.Push(Object("category", category
                              , "lawName", SSOK_LAW_CleanText(name)
                              , "seq", seq
                              , "lawId", lawId
                              , "jo", ""
                              , "joBranch", ""
                              , "joTitle", ""
                              , "joText", ""
                              , "dept", SSOK_LAW_CleanText(dept)
                              , "eff", eff
                              , "lawType", SSOK_LAW_CleanText(lawType)
                              , "detailLink", Trim(detailLink)
                              , "itemNo", SSOK_LAW_CleanText(itemNo)
                              , "relatedName", ""))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_LAW_ParseReferenceXml(xml, category)
{
    results := []
    seen := {}

    if (category = "prec")
    {
        nameTag := "»ç°Ç¸í"
        seqTags := "ÆÇ·ÊÀÏ·Ã¹øÈ£|ÆÇ·ÊÁ¤º¸ÀÏ·Ã¹øÈ£"
        itemTag := "»ç°Ç¹øÈ£"
        dateTag := "¼±°íÀÏÀÚ"
        deptTag := "¹ý¿ø¸í"
        typeTag := "ÆÇ°áÀ¯Çü"
        linkTag := "ÆÇ·Ê»ó¼¼¸µÅ©"
        defaultType := "ÆÇ·Ê"
    }
    else if (category = "detc")
    {
        nameTag := "»ç°Ç¸í"
        seqTags := "ÇåÀç°áÁ¤·ÊÀÏ·Ã¹øÈ£"
        itemTag := "»ç°Ç¹øÈ£"
        dateTag := "Á¾±¹ÀÏÀÚ"
        deptTag := ""
        typeTag := "»ç°ÇÁ¾·ù¸í"
        linkTag := "ÇåÀç°áÁ¤·Ê»ó¼¼¸µÅ©"
        defaultType := "ÇåÀç°áÁ¤·Ê"
    }
    else if (category = "expc")
    {
        nameTag := "¾È°Ç¸í"
        seqTags := "¹ý·ÉÇØ¼®·ÊÀÏ·Ã¹øÈ£"
        itemTag := "¾È°Ç¹øÈ£"
        dateTag := "È¸½ÅÀÏÀÚ"
        deptTag := "È¸½Å±â°ü¸í"
        typeTag := ""
        linkTag := "¹ý·ÉÇØ¼®·Ê»ó¼¼¸µÅ©"
        defaultType := "¹ý·ÉÇØ¼®·Ê"
    }
    else if (category = "decc")
    {
        nameTag := "»ç°Ç¸í"
        seqTags := "ÇàÁ¤½ÉÆÇÀç°á·ÊÀÏ·Ã¹øÈ£|ÇàÁ¤½ÉÆÇ·ÊÀÏ·Ã¹øÈ£"
        itemTag := "»ç°Ç¹øÈ£"
        dateTag := "ÀÇ°áÀÏÀÚ"
        deptTag := "Àç°áÃ»"
        typeTag := "Àç°á±¸ºÐ¸í"
        linkTag := "ÇàÁ¤½ÉÆÇ·Ê»ó¼¼¸µÅ©"
        defaultType := "ÇàÁ¤½ÉÆÇ·Ê"
    }
    else
        return results

    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results

        nodes := dom.selectNodes("//*[local-name()='" . nameTag . "']")
        Loop, % nodes.length
        {
            nameNode := nodes.item(A_Index - 1)
            parent := nameNode.parentNode
            name := Trim(nameNode.text)
            if (name = "")
                continue

            seq := SSOK_LAW_XmlTextAny(parent, seqTags)
            itemNo := SSOK_LAW_XmlText(parent, itemTag)
            eff := SSOK_LAW_XmlText(parent, dateTag)
            dept := (deptTag != "") ? SSOK_LAW_XmlText(parent, deptTag) : ""
            lawType := (typeTag != "") ? SSOK_LAW_XmlText(parent, typeTag) : ""
            if (lawType = "")
                lawType := defaultType
            if (category = "detc" && dept = "")
                dept := "Çå¹ýÀçÆÇ¼Ò"
            detailLink := SSOK_LAW_XmlText(parent, linkTag)

            key := category . "|" . seq . "|" . name . "|" . itemNo
            if (seen.HasKey(key))
                continue
            seen[key] := 1

            results.Push(Object("category", category
                              , "lawName", SSOK_LAW_CleanText(name)
                              , "seq", seq
                              , "lawId", ""
                              , "jo", ""
                              , "joBranch", ""
                              , "joTitle", ""
                              , "joText", ""
                              , "dept", SSOK_LAW_CleanText(dept)
                              , "eff", eff
                              , "lawType", SSOK_LAW_CleanText(lawType)
                              , "detailLink", Trim(detailLink)
                              , "itemNo", SSOK_LAW_CleanText(itemNo)
                              , "relatedName", ""))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_LAW_ParseBylXml(xml)
{
    results := []
    seen := {}
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return results

        nodes := dom.selectNodes("//*[local-name()='º°Ç¥ÀÏ·Ã¹øÈ£']")
        Loop, % nodes.length
        {
            seqNode := nodes.item(A_Index - 1)
            parent := seqNode.parentNode
            seq := Trim(seqNode.text)
            name := SSOK_LAW_XmlText(parent, "º°Ç¥¸í")
            if (name = "")
                continue

            relatedName := SSOK_LAW_XmlText(parent, "°ü·Ã¹ý·É¸í")
            lawType := SSOK_LAW_XmlText(parent, "º°Ç¥Á¾·ù")
            dept := SSOK_LAW_XmlText(parent, "¼Ò°üºÎÃ³¸í")
            eff := SSOK_LAW_XmlText(parent, "°øÆ÷ÀÏÀÚ")
            pdfLink := SSOK_LAW_XmlText(parent, "º°Ç¥¼­½ÄPDFÆÄÀÏ¸µÅ©")
            fileLink := SSOK_LAW_XmlText(parent, "º°Ç¥¼­½ÄÆÄÀÏ¸µÅ©")
            detailLink := SSOK_LAW_XmlText(parent, "º°Ç¥¹ý·É»ó¼¼¸µÅ©")
            if (pdfLink != "")
                openLink := pdfLink
            else if (fileLink != "")
                openLink := fileLink
            else
                openLink := detailLink

            key := seq . "|" . name . "|" . relatedName
            if (seen.HasKey(key))
                continue
            seen[key] := 1

            results.Push(Object("category", "byl"
                              , "lawName", SSOK_LAW_CleanText(name)
                              , "seq", seq
                              , "lawId", ""
                              , "jo", ""
                              , "joBranch", ""
                              , "joTitle", ""
                              , "joText", ""
                              , "dept", SSOK_LAW_CleanText(dept)
                              , "eff", eff
                              , "lawType", SSOK_LAW_CleanText(lawType)
                              , "detailLink", Trim(openLink)
                              , "itemNo", ""
                              , "relatedName", SSOK_LAW_CleanText(relatedName)))
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_LAW_MergeUnique(base, extra)
{
    if (!IsObject(base))
        base := []
    seen := {}
    for idx, item in base
        seen[item.category . "|" . item.seq . "|" . item.lawName . "|" . item.relatedName] := 1

    if (IsObject(extra))
    {
        for idx, item in extra
        {
            key := item.category . "|" . item.seq . "|" . item.lawName . "|" . item.relatedName
            if (!seen.HasKey(key))
            {
                seen[key] := 1
                base.Push(item)
            }
        }
    }
    return base
}

SSOK_LAW_XmlTextAny(parent, tagNames)
{
    Loop, Parse, tagNames, |
    {
        t := SSOK_LAW_XmlText(parent, A_LoopField)
        if (t != "")
            return t
    }
    return ""
}

SSOK_LAW_XmlText(parent, tagName)
{
    if (!IsObject(parent) || tagName = "")
        return ""
    try
    {
        node := parent.selectSingleNode(".//*[local-name()='" . tagName . "']")
        if (!node)
            node := parent.selectSingleNode("*[local-name()='" . tagName . "']")
        if (node)
            return Trim(node.text)
    }
    catch
    {
    }
    return ""
}

SSOK_LAW_CleanText(text)
{
    t := StrReplace(text, "`r", " ")
    t := StrReplace(t, "`n", " ")
    t := StrReplace(t, "`t", " ")
    t := RegExReplace(t, "\s+", " ")
    return Trim(t)
}

SSOK_LAW_FormatArticle(item)
{
    jo := Trim(item.jo)
    branch := Trim(item.joBranch)
    if (jo = "")
        return ""
    jo := RegExReplace(jo, "^0+")
    if (jo = "")
        jo := "0"
    out := "Á¦" . jo . "Á¶"
    if (branch != "")
    {
        branch := RegExReplace(branch, "^0+")
        if (branch != "" && branch != "0")
            out .= "ÀÇ" . branch
    }
    return out
}

SSOK_LAW_FormatDate8(value)
{
    d := RegExReplace(value, "[^0-9]")
    if (StrLen(d) = 8)
        return SubStr(d, 1, 4) . "." . (SubStr(d, 5, 2) + 0) . "." . (SubStr(d, 7, 2) + 0) . "."
    return value
}

SSOK_LAW_BuildDetail(item)
{
    category := item.category
    if (category = "law")
    {
        article := SSOK_LAW_FormatArticle(item)
        title := item.lawName
        if (article != "")
            title .= " " . article
        if (item.joTitle != "")
            title .= "(" . item.joTitle . ")"

        meta := "¹ý·É"
        if (item.lawType != "")
            meta .= " / " . item.lawType
        if (item.dept != "")
            meta .= " / " . item.dept
        if (item.eff != "")
            meta .= " / ½ÃÇà " . SSOK_LAW_FormatDate8(item.eff)

        detail := title . "`r`n" . meta
        if (item.joText != "")
            detail .= "`r`n`r`n" . item.joText
        return detail
    }

    if (category = "admrul")
    {
        label := "ÇàÁ¤±ÔÄ¢"
        dateLabel := "½ÃÇà"
    }
    else if (category = "ordin")
    {
        label := "ÀÚÄ¡¹ý±Ô"
        dateLabel := "½ÃÇà"
    }
    else if (category = "prec")
    {
        label := "ÆÇ·Ê"
        dateLabel := "¼±°í"
    }
    else if (category = "detc")
    {
        label := "ÇåÀç°áÁ¤·Ê"
        dateLabel := "Á¾±¹"
    }
    else if (category = "expc")
    {
        label := "¹ý·ÉÇØ¼®·Ê"
        dateLabel := "È¸½Å"
    }
    else if (category = "decc")
    {
        label := "ÇàÁ¤½ÉÆÇ·Ê"
        dateLabel := "ÀÇ°á"
    }
    else if (category = "moe")
    {
        label := "±³À°ºÎÇØ¼®"
        dateLabel := "ÇØ¼®"
    }
    else if (category = "byl")
    {
        label := "º°Ç¥¼­½Ä"
        dateLabel := "°øÆ÷"
    }
    else
    {
        label := "¹ý·ÉÁ¤º¸"
        dateLabel := "ÀÏÀÚ"
    }

    detail := item.lawName . "`r`n" . label
    if (item.relatedName != "")
        detail .= " / °ü·Ã¹ý·É " . item.relatedName
    if (item.itemNo != "")
    {
        if (category = "prec" || category = "detc" || category = "decc")
            detail .= " / »ç°Ç¹øÈ£ " . item.itemNo
        else
            detail .= " / ¾È°Ç¹øÈ£ " . item.itemNo
    }
    if (item.lawType != "" && item.lawType != label)
        detail .= " / " . item.lawType
    if (item.dept != "")
        detail .= " / " . item.dept
    if (item.eff != "")
        detail .= " / " . dateLabel . " " . SSOK_LAW_FormatDate8(item.eff)
    detail .= "`r`n`r`n´õºíÅ¬¸¯ÇÏ°Å³ª [¼±ÅÃ Ç×¸ñ ¿­±â]¸¦ ´©¸£¸é ±¹°¡¹ý·ÉÁ¤º¸¼¾ÅÍ ¿ø¹®À» ¿±´Ï´Ù."
    return detail
}

SSOK_LAW_Count(arr)
{
    if (!IsObject(arr))
        return 0
    n := arr.MaxIndex()
    return (n = "" ? 0 : n)
}

SSOK_LAW_ShowResults(query)
{
    global SSOK_LAW_LawResults, SSOK_LAW_AdminResults, SSOK_LAW_OrdinResults
    global SSOK_LAW_PrecResults, SSOK_LAW_DetcResults, SSOK_LAW_ExpcResults, SSOK_LAW_DeccResults
    global SSOK_LAW_MoeResults, SSOK_LAW_BylResults
    global SSOK_LAW_LawList, SSOK_LAW_AdminList, SSOK_LAW_OrdinList
    global SSOK_LAW_PrecList, SSOK_LAW_DetcList, SSOK_LAW_ExpcList, SSOK_LAW_DeccList
    global SSOK_LAW_MoeList, SSOK_LAW_BylList, SSOK_LAW_Tab, SSOK_LAW_Detail

    lawCnt := SSOK_LAW_Count(SSOK_LAW_LawResults)
    adminCnt := SSOK_LAW_Count(SSOK_LAW_AdminResults)
    ordinCnt := SSOK_LAW_Count(SSOK_LAW_OrdinResults)
    precCnt := SSOK_LAW_Count(SSOK_LAW_PrecResults)
    detcCnt := SSOK_LAW_Count(SSOK_LAW_DetcResults)
    expcCnt := SSOK_LAW_Count(SSOK_LAW_ExpcResults)
    deccCnt := SSOK_LAW_Count(SSOK_LAW_DeccResults)
    moeCnt := SSOK_LAW_Count(SSOK_LAW_MoeResults)
    bylCnt := SSOK_LAW_Count(SSOK_LAW_BylResults)

    tabNames := "¹ý·É (" . lawCnt . ")|ÇàÁ¤±ÔÄ¢ (" . adminCnt . ")|ÀÚÄ¡¹ý±Ô (" . ordinCnt . ")|ÆÇ·Ê (" . precCnt . ")|ÇåÀç°áÁ¤·Ê (" . detcCnt . ")|¹ý·ÉÇØ¼®·Ê (" . expcCnt . ")|ÇàÁ¤½ÉÆÇ·Ê (" . deccCnt . ")|±³À°ºÎÇØ¼® (" . moeCnt . ")|º°Ç¥¼­½Ä (" . bylCnt . ")"

    Gui, SSOKLaw:Destroy
    Gui, SSOKLaw:New, +Resize +MinSize960x500 +LabelSSOK_LAW_Gui
    Gui, SSOKLaw:Color, F7FBFF
    Gui, SSOKLaw:Margin, 12, 12
    Gui, SSOKLaw:Font, s11 bold c005BAC, Malgun Gothic
    Gui, SSOKLaw:Add, Text, x12 y12 w1040 h24, % "¹ý·ÉÁ¤º¸ ÅëÇÕ°Ë»ö : " . query
    Gui, SSOKLaw:Font, s9 norm c333333, Malgun Gothic
    Gui, SSOKLaw:Add, Tab2, x12 y42 w1056 h282 vSSOK_LAW_Tab gSSOK_LAW_TabChanged, %tabNames%

    Gui, SSOKLaw:Tab, 1
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_LawList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, ¹ý·É¸í|Á¶¹®|Á¶¹®Á¦¸ñ|¼Ò°üºÎÃ³|½ÃÇàÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_LawList
    for idx, item in SSOK_LAW_LawResults
        LV_Add("", item.lawName, SSOK_LAW_FormatArticle(item), item.joTitle, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 290)
    LV_ModifyCol(2, 70)
    LV_ModifyCol(3, 280)
    LV_ModifyCol(4, 220)
    LV_ModifyCol(5, 110)

    Gui, SSOKLaw:Tab, 2
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_AdminList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, ÇàÁ¤±ÔÄ¢¸í|Á¾·ù|¼Ò°üºÎÃ³|½ÃÇàÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_AdminList
    for idx, item in SSOK_LAW_AdminResults
        LV_Add("", item.lawName, item.lawType, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 450)
    LV_ModifyCol(2, 120)
    LV_ModifyCol(3, 300)
    LV_ModifyCol(4, 110)

    Gui, SSOKLaw:Tab, 3
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_OrdinList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, ÀÚÄ¡¹ý±Ô¸í|Á¾·ù|±â°ü|½ÃÇàÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_OrdinList
    for idx, item in SSOK_LAW_OrdinResults
        LV_Add("", item.lawName, item.lawType, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 450)
    LV_ModifyCol(2, 120)
    LV_ModifyCol(3, 300)
    LV_ModifyCol(4, 110)

    Gui, SSOKLaw:Tab, 4
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_PrecList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, »ç°Ç¸í|»ç°Ç¹øÈ£|¹ý¿ø|¼±°íÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_PrecList
    for idx, item in SSOK_LAW_PrecResults
        LV_Add("", item.lawName, item.itemNo, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 520)
    LV_ModifyCol(2, 180)
    LV_ModifyCol(3, 210)
    LV_ModifyCol(4, 110)

    Gui, SSOKLaw:Tab, 5
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_DetcList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, »ç°Ç¸í|»ç°Ç¹øÈ£|±â°ü|Á¾±¹ÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_DetcList
    for idx, item in SSOK_LAW_DetcResults
        LV_Add("", item.lawName, item.itemNo, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 520)
    LV_ModifyCol(2, 180)
    LV_ModifyCol(3, 210)
    LV_ModifyCol(4, 110)

    Gui, SSOKLaw:Tab, 6
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_ExpcList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, ¾È°Ç¸í|¾È°Ç¹øÈ£|È¸½Å±â°ü|È¸½ÅÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_ExpcList
    for idx, item in SSOK_LAW_ExpcResults
        LV_Add("", item.lawName, item.itemNo, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 500)
    LV_ModifyCol(2, 150)
    LV_ModifyCol(3, 250)
    LV_ModifyCol(4, 110)

    Gui, SSOKLaw:Tab, 7
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_DeccList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, »ç°Ç¸í|»ç°Ç¹øÈ£|Àç°áÃ»|ÀÇ°áÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_DeccList
    for idx, item in SSOK_LAW_DeccResults
        LV_Add("", item.lawName, item.itemNo, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 480)
    LV_ModifyCol(2, 180)
    LV_ModifyCol(3, 240)
    LV_ModifyCol(4, 110)

    Gui, SSOKLaw:Tab, 8
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_MoeList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, ¾È°Ç¸í|¾È°Ç¹øÈ£|ÇØ¼®±â°ü|ÇØ¼®ÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_MoeList
    for idx, item in SSOK_LAW_MoeResults
        LV_Add("", item.lawName, item.itemNo, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 500)
    LV_ModifyCol(2, 150)
    LV_ModifyCol(3, 250)
    LV_ModifyCol(4, 110)

    Gui, SSOKLaw:Tab, 9
    Gui, SSOKLaw:Add, ListView, x24 y86 w1032 h218 vSSOK_LAW_BylList gSSOK_LAW_ResultEvent AltSubmit Grid -Multi, º°Ç¥¼­½Ä¸í|°ü·Ã¹ý·É|Á¾·ù|¼Ò°üºÎÃ³|°øÆ÷ÀÏ
    Gui, SSOKLaw:Default
    Gui, ListView, SSOK_LAW_BylList
    for idx, item in SSOK_LAW_BylResults
        LV_Add("", item.lawName, item.relatedName, item.lawType, item.dept, SSOK_LAW_FormatDate8(item.eff))
    LV_ModifyCol(1, 300)
    LV_ModifyCol(2, 300)
    LV_ModifyCol(3, 90)
    LV_ModifyCol(4, 210)
    LV_ModifyCol(5, 110)

    Gui, SSOKLaw:Tab
    Gui, SSOKLaw:Font, s9 norm c222222, Malgun Gothic
    Gui, SSOKLaw:Add, Edit, x12 y334 w1056 h130 vSSOK_LAW_Detail ReadOnly +Wrap +VScroll
    Gui, SSOKLaw:Font, s9 bold, Malgun Gothic
    Gui, SSOKLaw:Add, Button, x12 y474 w115 h28 gSSOK_LAW_OpenSelectedButton, ¼±ÅÃ Ç×¸ñ ¿­±â
    Gui, SSOKLaw:Add, Button, x136 y474 w170 h28 gSSOK_LAW_OpenWebSearch, ±¹°¡¹ý·ÉÁ¤º¸¼¾ÅÍ °Ë»ö
    Gui, SSOKLaw:Add, Button, x978 y474 w90 h28 gSSOK_LAW_GuiClose, ´Ý±â

    ; Ã¹ ¹øÂ° °á°ú°¡ ÀÖ´Â ÅÇÀ» ÀÚµ¿ ¼±ÅÃ
    firstTab := 1
    if (lawCnt > 0)
        firstTab := 1
    else if (adminCnt > 0)
        firstTab := 2
    else if (ordinCnt > 0)
        firstTab := 3
    else if (precCnt > 0)
        firstTab := 4
    else if (detcCnt > 0)
        firstTab := 5
    else if (expcCnt > 0)
        firstTab := 6
    else if (deccCnt > 0)
        firstTab := 7
    else if (moeCnt > 0)
        firstTab := 8
    else if (bylCnt > 0)
        firstTab := 9

    GuiControl, SSOKLaw:Choose, SSOK_LAW_Tab, %firstTab%
    Gui, SSOKLaw:Show, w1080 h514, SSOK ¹ý·ÉÁ¤º¸ ÅëÇÕ°Ë»ö
    SSOK_LAW_UpdateDetailForCurrentTab()
}

SSOK_LAW_GetResultsByControl(ctrl)
{
    global SSOK_LAW_LawResults, SSOK_LAW_AdminResults, SSOK_LAW_OrdinResults
    global SSOK_LAW_PrecResults, SSOK_LAW_DetcResults, SSOK_LAW_ExpcResults, SSOK_LAW_DeccResults
    global SSOK_LAW_MoeResults, SSOK_LAW_BylResults

    if (ctrl = "SSOK_LAW_LawList")
        return SSOK_LAW_LawResults
    if (ctrl = "SSOK_LAW_AdminList")
        return SSOK_LAW_AdminResults
    if (ctrl = "SSOK_LAW_OrdinList")
        return SSOK_LAW_OrdinResults
    if (ctrl = "SSOK_LAW_PrecList")
        return SSOK_LAW_PrecResults
    if (ctrl = "SSOK_LAW_DetcList")
        return SSOK_LAW_DetcResults
    if (ctrl = "SSOK_LAW_ExpcList")
        return SSOK_LAW_ExpcResults
    if (ctrl = "SSOK_LAW_DeccList")
        return SSOK_LAW_DeccResults
    if (ctrl = "SSOK_LAW_MoeList")
        return SSOK_LAW_MoeResults
    if (ctrl = "SSOK_LAW_BylList")
        return SSOK_LAW_BylResults
    return []
}

SSOK_LAW_CategoryByControl(ctrl)
{
    if (ctrl = "SSOK_LAW_LawList")
        return "law"
    if (ctrl = "SSOK_LAW_AdminList")
        return "admrul"
    if (ctrl = "SSOK_LAW_OrdinList")
        return "ordin"
    if (ctrl = "SSOK_LAW_PrecList")
        return "prec"
    if (ctrl = "SSOK_LAW_DetcList")
        return "detc"
    if (ctrl = "SSOK_LAW_ExpcList")
        return "expc"
    if (ctrl = "SSOK_LAW_DeccList")
        return "decc"
    if (ctrl = "SSOK_LAW_MoeList")
        return "moe"
    if (ctrl = "SSOK_LAW_BylList")
        return "byl"
    return ""
}

SSOK_LAW_ControlForCurrentTab()
{
    GuiControlGet, tabText, SSOKLaw:, SSOK_LAW_Tab
    if (InStr(tabText, "ÇåÀç°áÁ¤·Ê"))
        return "SSOK_LAW_DetcList"
    if (InStr(tabText, "¹ý·ÉÇØ¼®·Ê"))
        return "SSOK_LAW_ExpcList"
    if (InStr(tabText, "ÇàÁ¤½ÉÆÇ·Ê"))
        return "SSOK_LAW_DeccList"
    if (InStr(tabText, "±³À°ºÎÇØ¼®"))
        return "SSOK_LAW_MoeList"
    if (InStr(tabText, "º°Ç¥¼­½Ä"))
        return "SSOK_LAW_BylList"
    if (InStr(tabText, "ÇàÁ¤±ÔÄ¢"))
        return "SSOK_LAW_AdminList"
    if (InStr(tabText, "ÀÚÄ¡¹ý±Ô"))
        return "SSOK_LAW_OrdinList"
    if (InStr(tabText, "ÆÇ·Ê"))
        return "SSOK_LAW_PrecList"
    return "SSOK_LAW_LawList"
}

SSOK_LAW_UpdateDetailForCurrentTab()
{
    ctrl := SSOK_LAW_ControlForCurrentTab()
    SSOK_LAW_UpdateDetailForControl(ctrl, 0)
}

SSOK_LAW_UpdateDetailForControl(ctrl, preferredRow := 0)
{
    global SSOK_LAW_SelectedRows
    results := SSOK_LAW_GetResultsByControl(ctrl)
    category := SSOK_LAW_CategoryByControl(ctrl)
    count := SSOK_LAW_Count(results)
    if (count < 1)
    {
        GuiControl, SSOKLaw:, SSOK_LAW_Detail, °Ë»ö °á°ú°¡ ¾ø½À´Ï´Ù.
        return
    }

    Gui, SSOKLaw:Default
    Gui, SSOKLaw:ListView, %ctrl%
    row := preferredRow
    if (row < 1)
        row := LV_GetNext(0, "F")
    if (row < 1 && IsObject(SSOK_LAW_SelectedRows) && SSOK_LAW_SelectedRows.HasKey(category))
        row := SSOK_LAW_SelectedRows[category]
    if (row < 1 || row > count)
        row := 1

    LV_Modify(row, "Select Focus Vis")
    if (!IsObject(SSOK_LAW_SelectedRows))
        SSOK_LAW_SelectedRows := {}
    SSOK_LAW_SelectedRows[category] := row

    detail := SSOK_LAW_BuildDetail(results[row])
    GuiControl, SSOKLaw:, SSOK_LAW_Detail, %detail%
}

SSOK_LAW_NormalizeLink(link)
{
    u := Trim(link)
    if (u = "")
        return ""
    if (RegExMatch(u, "i)^https?://"))
        return u
    if (SubStr(u, 1, 2) = "//")
        return "https:" . u
    if (SubStr(u, 1, 1) = "/")
        return "https://www.law.go.kr" . u
    return "https://www.law.go.kr/" . u
}

SSOK_LAW_OpenSelected(ctrl := "")
{
    global SSOK_LAW_SelectedRows, SSOK_LAW_LastQuery
    if (ctrl = "")
        ctrl := SSOK_LAW_ControlForCurrentTab()

    results := SSOK_LAW_GetResultsByControl(ctrl)
    if (SSOK_LAW_Count(results) < 1)
        return

    category := SSOK_LAW_CategoryByControl(ctrl)
    Gui, SSOKLaw:Default
    Gui, SSOKLaw:ListView, %ctrl%
    row := LV_GetNext(0, "F")
    if (row < 1 && IsObject(SSOK_LAW_SelectedRows) && SSOK_LAW_SelectedRows.HasKey(category))
        row := SSOK_LAW_SelectedRows[category]
    if (row < 1)
        row := 1
    if (!IsObject(results[row]))
        return

    item := results[row]
    url := SSOK_LAW_NormalizeLink(item.detailLink)

    if (url = "" && category = "law" && Trim(item.seq) != "")
        url := "https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=" . SSOK_QU_UrlEncode(item.seq)

    if (url = "")
    {
        term := Trim(item.lawName)
        if (term = "")
            term := SSOK_LAW_LastQuery
        url := "https://www.law.go.kr/LSW/ais/searchList.do?aiBoardQuery=" . SSOK_QU_UrlEncode(term) . "&pageIndex=1"
    }
    SSOK_OpenUrlPreferred(url)
}

SSOK_QA_PopupDefaultSearch:
    ControlGetFocus, SSOK_QA_FocusedCtrl, ahk_id %SSOK_ACC_GuiHwnd%
    if (SSOK_QA_FocusedCtrl != "")
    {
        ControlGet, SSOK_QA_FocusedHwnd, Hwnd,, %SSOK_QA_FocusedCtrl%, ahk_id %SSOK_ACC_GuiHwnd%
        if (SSOK_QA_FocusedHwnd = SSOK_WRK_QueryEditHwnd)
        {
            Gosub, SSOK_WRK_Search
            return
        }
        if (SSOK_QA_FocusedHwnd = SSOK_ACC_QueryEditHwnd)
        {
            Gosub, SSOK_ACC_Search
            return
        }
    }
    Gosub, SSOK_ACC_Search
return

SSOK_ACC_CheckQueryFocus:
    ; °Ë»öÃ¢ ¾È³»¹®Àº ½ÇÁ¦·Î ¸¶¿ì½º·Î °Ë»öÃ¢À» ´­·¶À» ¶§¸¸ Áö¿ò
    if (!SSOK_ACC_IsPlaceholder && !SSOK_WRK_IsPlaceholder)
        return
    if (!GetKeyState("LButton", "P"))
        return
    MouseGetPos, , , , SSOK_ACC_MouseCtrlHwnd, 2
    if (SSOK_ACC_IsPlaceholder && SSOK_ACC_MouseCtrlHwnd = SSOK_ACC_QueryEditHwnd)
        SSOK_ACC_ClearQueryPlaceholder()
    if (SSOK_WRK_IsPlaceholder && SSOK_ACC_MouseCtrlHwnd = SSOK_WRK_QueryEditHwnd)
        SSOK_WRK_ClearQueryPlaceholder()
return

SSOK_ACC_GuiClose:
SSOK_ACC_GuiEscape:
    SetTimer, SSOK_ACC_CheckQueryFocus, Off
    Gui, SSOKACC:Destroy
return

SSOK_ACC_ShowMain() {
    global SSOK_ACC_Query, SSOK_ACC_QueryEditHwnd
    global SSOK_WRK_Query, SSOK_WRK_QueryEditHwnd
    global SSOK_ACC_Placeholder, SSOK_ACC_IsPlaceholder
    global SSOK_WRK_Placeholder, SSOK_WRK_IsPlaceholder
    SSOK_ACC_EnsureInit()
    SSOK_WRK_EnsureInit()
    SSOK_ACC_LoadIndex()

    SSOK_ACC_Placeholder := "ÇÐ±³È¸°è Q&A °Ë»ö"
    SSOK_ACC_IsPlaceholder := true
    SSOK_WRK_Placeholder := "°ø¹«Á÷ Q&A °Ë»ö"
    SSOK_WRK_IsPlaceholder := true

    Gui, SSOKACC:Destroy
    Gui, SSOKACC:New, +HwndSSOK_ACC_GuiHwnd +LabelSSOK_ACC_Gui
    Gui, SSOKACC:Margin, 12, 12

    Gui, SSOKACC:Font, s9 bold c005BAC, ¸¼Àº °íµñ
    Gui, SSOKACC:Add, Text, x12 y18 w64 h22 Right, ÇÐ±³È¸°è
    Gui, SSOKACC:Font, s10 c808080, ¸¼Àº °íµñ
    Gui, SSOKACC:Add, Edit, x82 y12 w250 h30 vSSOK_ACC_Query hwndSSOK_ACC_QueryEditHwnd, %SSOK_ACC_Placeholder%
    Gui, SSOKACC:Font, s6 c000000, ¸¼Àº °íµñ
    Gui, SSOKACC:Add, Button, x340 y20 w14 h14 gSSOK_ACC_Search, ?

    Gui, SSOKACC:Font, s9 bold c7A4B00, ¸¼Àº °íµñ
    Gui, SSOKACC:Add, Text, x370 y18 w54 h22 Right, °ø¹«Á÷
    Gui, SSOKACC:Font, s10 c808080, ¸¼Àº °íµñ
    Gui, SSOKACC:Add, Edit, x432 y12 w250 h30 vSSOK_WRK_Query hwndSSOK_WRK_QueryEditHwnd, %SSOK_WRK_Placeholder%
    Gui, SSOKACC:Font, s6 c000000, ¸¼Àº °íµñ
    Gui, SSOKACC:Add, Button, x690 y20 w14 h14 gSSOK_WRK_Search, ?
    Gui, SSOKACC:Add, Button, x-100 y-100 w1 h1 Hidden Default gSSOK_QA_PopupDefaultSearch

    Gui, SSOKACC:Show, w720 h54, SSOK Q&A °Ë»ö
    GuiControl, SSOKACC:Focus, Button1
    SetTimer, SSOK_ACC_CheckQueryFocus, 50
}

SSOK_ACC_ClearQueryPlaceholder() {
    global SSOK_ACC_IsPlaceholder
    if (!SSOK_ACC_IsPlaceholder)
        return
    GuiControl, SSOKACC:, SSOK_ACC_Query,
    Gui, SSOKACC:Font, s10 c000000, ¸¼Àº °íµñ
    GuiControl, SSOKACC:Font, SSOK_ACC_Query
    SSOK_ACC_IsPlaceholder := false
}

SSOK_WRK_ClearQueryPlaceholder() {
    global SSOK_WRK_IsPlaceholder
    if (!SSOK_WRK_IsPlaceholder)
        return
    GuiControl, SSOKACC:, SSOK_WRK_Query,
    Gui, SSOKACC:Font, s10 c000000, ¸¼Àº °íµñ
    GuiControl, SSOKACC:Font, SSOK_WRK_Query
    SSOK_WRK_IsPlaceholder := false
}

SSOK_ACC_EnsureInit() {
    global SSOK_ACC_Records, SSOK_ACC_Loaded, SSOK_ACC_LastResults, SSOK_ACC_MinScore
    global SSOK_ACC_Placeholder, SSOK_ACC_IsPlaceholder
    if (!IsObject(SSOK_ACC_Records))
        SSOK_ACC_Records := []
    if (SSOK_ACC_Loaded = "")
        SSOK_ACC_Loaded := false
    if (!IsObject(SSOK_ACC_LastResults))
        SSOK_ACC_LastResults := []
    if (SSOK_ACC_MinScore = "")
        SSOK_ACC_MinScore := 20
    if (SSOK_ACC_Placeholder = "")
        SSOK_ACC_Placeholder := "ÇÐ±³È¸°è Q&A °Ë»ö"
    if (SSOK_ACC_IsPlaceholder = "")
        SSOK_ACC_IsPlaceholder := false
}

SSOK_ACC_RunSearch(query) {
    global SSOK_ACC_LastResults, SSOK_ACC_Placeholder, SSOK_ACC_IsPlaceholder
    SSOK_ACC_EnsureInit()
    q := Trim(query)
    if (q = "" || q = SSOK_ACC_Placeholder || SSOK_ACC_IsPlaceholder) {
        MsgBox, 48, SSOK ÇÐ±³È¸°è Q&A, ÇÐ±³È¸°è ¿¹»êÆí¼º ¹× ÁýÇàÁöÄ§¿¡¼­ °ü·Ã Å°¿öµå¸¦ Ã£Áö ¸øÇÏ¿´½À´Ï´Ù.
        return
    }

    SSOK_ACC_DoSearch(q)

    if (!IsObject(SSOK_ACC_LastResults) || SSOK_ACC_LastResults.MaxIndex() < 1) {
        MsgBox, 48, SSOK ÇÐ±³È¸°è Q&A, ÇÐ±³È¸°è ¿¹»êÆí¼º ¹× ÁýÇàÁöÄ§¿¡¼­ °ü·Ã Å°¿öµå¸¦ Ã£Áö ¸øÇÏ¿´½À´Ï´Ù.
        return
    }

    prompt := SSOK_ACC_BuildGeminiPrompt(q, SSOK_ACC_LastResults)
    accClipSaved := ClipboardAll
    if (!SSOK_SetClipboardTextWithWait(prompt, 3, 3)) {
        Clipboard := accClipSaved
        MsgBox, 16, SSOK ÇÐ±³È¸°è Q&A, Gemini·Î º¸³¾ ¹®±¸¸¦ Å¬¸³º¸µå¿¡ º¹»çÇÏÁö ¸øÇß½À´Ï´Ù.
        return
    }

    SSOK_ACC_OpenGeminiAndPaste()
}

SSOK_ACC_OpenGeminiAndPaste() {
    ; È¸°è Q&Aµµ Windows ±âº» ºê¶ó¿ìÀú¸¦ »ç¿ëÇÔ.
    chromeWasOpen := SSOK_ACC_IsProcessRunning("chrome.exe")
    edgeWasOpen := SSOK_ACC_IsProcessRunning("msedge.exe")
    browserExe := ""
    browserWasOpen := false

    browserExe := SSOK_OpenUrlPreferred("https://gemini.google.com/app")
    if (browserExe = "chrome.exe")
        browserWasOpen := chromeWasOpen
    else if (browserExe = "msedge.exe")
        browserWasOpen := edgeWasOpen
    else
        browserWasOpen := (chromeWasOpen || edgeWasOpen)

    if (!browserWasOpen) {
        ; ºê¶ó¿ìÀú°¡ ¿ÏÀüÈ÷ »õ·Î ¶ß´Â ÃÖÃÊ ½ÇÇàÀº Gemini ÀÔ·ÂÃ¢ ÁØºñ ½Ã°£ÀÌ ±æ ¼ö ÀÖÀ½
        Sleep, 9500
    } else {
        ; ÀÌ¹Ì ºê¶ó¿ìÀú°¡ ¶° ÀÖ´Â ÀÏ¹Ý °Ë»öÀº ±âÁ¸Ã³·³ ºü¸£°Ô Ã³¸®
        Sleep, 4800
    }

    SSOK_ACC_ActivateBrowser(browserExe)
    Sleep, 300
    SendInput, ^v
    Sleep, 900
    SendInput, {Enter}
}
SSOK_ACC_IsProcessRunning(exeName) {
    Process, Exist, %exeName%
    return (ErrorLevel != 0)
}

SSOK_ACC_ActivateBrowser(browserExe := "") {
    if (browserExe != "" && browserExe != "default") {
        if WinExist("ahk_exe " . browserExe) {
            WinActivate
            WinWaitActive, ahk_exe %browserExe%,, 3
            return
        }
    }
    for _, exe in SSOK_BrowserCandidates()
    {
        if (browserExe = exe)
            continue
        if WinExist("ahk_exe " . exe)
        {
            WinActivate
            WinWaitActive, ahk_exe %exe%,, 3
            return
        }
    }
}
SSOK_ACC_GetAccDir() {
    return A_ScriptDir
}

SSOK_ACC_LoadIndex() {
    global SSOK_ACC_Loaded, SSOK_ACC_Records
    SSOK_ACC_EnsureInit()
    if (SSOK_ACC_Loaded)
        return

    SSOK_ACC_Records := []
    baseDir := SSOK_ACC_GetAccDir()
    idxPath := baseDir . "\ssok_index1.tsv"

    if (!FileExist(idxPath)) {
        MsgBox, 16, SSOK ÇÐ±³È¸°è Q&A, °Ë»ö ÀÚ·á ÆÄÀÏÀ» Ã£À» ¼ö ¾ø½À´Ï´Ù.`n%idxPath%
        return
    }

    loadedCount := SSOK_ACC_LoadIndexFile(idxPath)
    if (loadedCount < 1) {
        MsgBox, 16, SSOK ÇÐ±³È¸°è Q&A, °Ë»ö ÀÚ·á ÆÄÀÏÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`n%idxPath%
        return
    }

    SSOK_ACC_Loaded := true
}

SSOK_ACC_LoadIndexFile(idxPath) {
    global SSOK_ACC_Records

    FileRead, raw, *P65001 %idxPath%
    if (ErrorLevel) {
        MsgBox, 16, SSOK ÇÐ±³È¸°è Q&A, °Ë»ö ÀÚ·á ÆÄÀÏÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`n%idxPath%
        return 0
    }

    loaded := 0
    Loop, Parse, raw, `n, `r
    {
        if (A_Index = 1)
            continue
        line := A_LoopField
        if (line = "")
            continue

        parts := StrSplit(line, A_Tab)
        if (parts.MaxIndex() < 4)
            continue

        item := Object()
        item.doc := parts[1]
        item.page := parts[2]
        item.section := parts[3]
        item.text := SSOK_ACC_Unescape(parts[4])
        item.compact := SSOK_ACC_Compact(item.text . " " . item.section . " " . item.page . "ÂÊ")
        item.score := 0
        SSOK_ACC_Records.Push(item)
        loaded++
    }

    return loaded
}
SSOK_ACC_DoSearch(query) {
    global SSOK_ACC_Records, SSOK_ACC_LastResults, SSOK_ACC_MinScore
    SSOK_ACC_LoadIndex()

    top := []
    q := Trim(query)
    terms := SSOK_ACC_MakeTerms(q)
    qCompact := SSOK_ACC_Compact(q)

    ; ÂÊ¼ö Á÷Á¢ °Ë»ö: ¿¹) 95ÂÊ
    if (RegExMatch(q, "(\d+)\s*ÂÊ", m)) {
        pageAsked := m1 + 0
        for i, rec in SSOK_ACC_Records {
            if (rec.page = pageAsked) {
                item := SSOK_ACC_Clone(rec)
                item.score := 999
                SSOK_ACC_InsertTop(top, item, 10)
            }
        }
    }

    for i, rec in SSOK_ACC_Records {
        score := 0
        t := rec.compact

        if (qCompact != "" && InStr(t, qCompact))
            score += 120

        for k, term in terms {
            cterm := SSOK_ACC_Compact(term)
            if (cterm = "")
                continue
            if (InStr(t, cterm)) {
                add := 4
                if (StrLen(cterm) >= 4)
                    add := 10
                if (StrLen(cterm) >= 6)
                    add := 18
                if (StrLen(cterm) >= 9)
                    add := 28
                score += add
                score += SSOK_ACC_CountHits(t, cterm) * 2
            }
        }

        ; ´Ü°¡¡¤±Ý¾×¼º Áú¹® °¡»ê
        if (InStr(qCompact, "¾ó¸¶") || InStr(qCompact, "´Ü°¡") || InStr(qCompact, "±Ý¾×") || InStr(qCompact, "¿ø")) {
            if (InStr(t, "´Ü°¡") || InStr(t, "1½Ä") || InStr(t, "1ÀÏ") || InStr(t, "¿ø"))
                score += 12
        }

        ; ÀÚÁÖ ¾²´Â È¸°è ÁúÀÇ º¸Á¤
        if (InStr(qCompact, "°£½Ä") && InStr(t, "°£½Äºñ1ÀÏ3000"))
            score += 230
        if (InStr(qCompact, "½Äºñ") && InStr(t, "½Äºñ1½Ä10000"))
            score += 160
        if (InStr(qCompact, "¼öÀÍÀÚ") && InStr(t, "Á¤»ê") && InStr(t, "°ø°³"))
            score += 90
        if (InStr(qCompact, "¾÷¹«ÃßÁø") && InStr(t, "¾÷¹«ÃßÁøºñ"))
            score += 90
        if (InStr(qCompact, "»óÇ°±Ç") && InStr(t, "»óÇ°±Ç"))
            score += 80
        if (InStr(qCompact, "°­»ç") && (InStr(t, "°­»ç") || InStr(t, "¼ö´ç")))
            score += 70

        if (score >= SSOK_ACC_MinScore) {
            item := SSOK_ACC_Clone(rec)
            item.score := score
            SSOK_ACC_InsertTop(top, item, 10)
        }
    }

    SSOK_ACC_LastResults := top
}

SSOK_ACC_MakeTerms(q) {
    arr := []
    clean := RegExReplace(q, "[?£¿!£¡,£¬.¡£:£º;£»/\\\[\]\(\){}<>]", " ")
    compactWhole := SSOK_ACC_Compact(clean)
    if (compactWhole != "")
        arr.Push(compactWhole)

    Loop, Parse, clean, %A_Space%
    {
        token := Trim(A_LoopField)
        if (StrLen(token) < 2)
            continue
        if (SSOK_ACC_IsStopWord(token))
            continue
        arr.Push(token)
    }

    qc := SSOK_ACC_Compact(q)
    if (InStr(qc, "°£½Ä")) {
        arr.Push("ÇÐ»ý°£½Äºñ"), arr.Push("°£½Äºñ"), arr.Push("ÇÐ»ý °£½Ä"), arr.Push("1ÀÏ 3,000¿ø"), arr.Push("ÇöÀåÃ¼ÇèÇÐ½À ½Äºñ °£½Äºñ")
    }
    if (InStr(qc, "½Äºñ") || InStr(qc, "½Ä´ë") || InStr(qc, "¸Å½Ä")) {
        arr.Push("ÇÐ»ý ½Äºñ"), arr.Push("½Äºñ"), arr.Push("1½Ä 10,000¿ø"), arr.Push("ÇöÀåÃ¼ÇèÇÐ½À ½Äºñ")
    }
    if (InStr(qc, "ÃâÀå") || InStr(qc, "¿©ºñ")) {
        arr.Push("¿©ºñ"), arr.Push("ÃâÀå"), arr.Push("ÀÏºñ"), arr.Push("¿îÀÓ"), arr.Push("¼÷¹Úºñ")
    }
    if (InStr(qc, "¼öÀÍÀÚ") || InStr(qc, "ÇÐºÎ¸ðºÎ´ã")) {
        arr.Push("¼öÀÍÀÚºÎ´ã°æºñ"), arr.Push("¼öÀÍÀÚ ºÎ´ã"), arr.Push("Á¤»ê"), arr.Push("°ø°³")
    }
    if (InStr(qc, "¾÷¹«ÃßÁø") || InStr(qc, "ÇùÀÇÈ¸") || InStr(qc, "°£´ãÈ¸")) {
        arr.Push("¾÷¹«ÃßÁøºñ"), arr.Push("ÇùÀÇÈ¸"), arr.Push("°£´ãÈ¸"), arr.Push("ÁýÇà±âÁØ")
    }
    if (InStr(qc, "»óÇ°±Ç")) {
        arr.Push("»óÇ°±Ç ±¸¸Å"), arr.Push("»óÇ°±Ç »ç¿ë"), arr.Push("°ø°³")
    }
    if (InStr(qc, "°­»ç") || InStr(qc, "¼ö´ç")) {
        arr.Push("°­»ç¼ö´ç"), arr.Push("°­»ç·á"), arr.Push("¿ÜºÎ°­»ç"), arr.Push("¿ø°í·á"), arr.Push("¼ö´ç")
    }
    if (InStr(qc, "°è¾à") || InStr(qc, "¼öÀÇ")) {
        arr.Push("°è¾à"), arr.Push("¼öÀÇ°è¾à"), arr.Push("°ø°³°ßÀû"), arr.Push("ÁöÁ¤Á¤º¸Ã³¸®ÀåÄ¡")
    }

    SSOK_ACC_AddKeywordAliases(arr, qc)

    return SSOK_ACC_Unique(arr)
}

SSOK_ACC_AddKeywordAliases(ByRef arr, qc) {
    keywordLines := SSOK_ACC_GetKeywordSectionForSearch()
    Loop, Parse, keywordLines, `n, `r
    {
        line := Trim(A_LoopField)
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue
        eq := InStr(line, "=")
        if (!eq)
            continue
        key := Trim(SubStr(line, 1, eq-1))
        vals := Trim(SubStr(line, eq+1))
        if (key != "" && InStr(qc, SSOK_ACC_Compact(key))) {
            Loop, Parse, vals, CSV
            {
                v := Trim(A_LoopField)
                if (v != "")
                    arr.Push(v)
            }
        }
    }
}

SSOK_ACC_GetKeywordSectionForSearch() {
    text := SSOK_ACC_GetKeywordSectionFromSsokIni()
    if (Trim(text) != "")
        return text

    return SSOK_ACC_DefaultKeywordLines()
}

SSOK_ACC_GetKeywordSectionForSave() {
    text := SSOK_ACC_GetKeywordSectionFromSsokIni()
    if (Trim(text) != "")
        return SSOK_ACC_EnsureTrailingNewline(text)

    return SSOK_ACC_DefaultKeywordLines()
}

SSOK_ACC_GetKeywordSectionFromSsokIni() {
    iniPath := SSOK_IniFile
    if (!FileExist(iniPath))
        return ""

    FileRead, raw, %iniPath%
    if (ErrorLevel)
        return ""

    return SSOK_ACC_ExtractIniSection(raw, "AccountingKeywords")
}


SSOK_ACC_ExtractIniSection(raw, sectionName) {
    out := ""
    inSec := false
    target := "[" . sectionName . "]"

    Loop, Parse, raw, `n, `r
    {
        line := StrReplace(A_LoopField, Chr(0xFEFF), "")
        trimmed := Trim(line)
        if (trimmed = target) {
            inSec := true
            continue
        }
        if (inSec && SubStr(trimmed, 1, 1) = "[")
            break
        if (inSec && trimmed != "")
            out .= line . "`r`n"
    }

    return out
}

SSOK_ACC_EnsureTrailingNewline(text) {
    if (SubStr(text, 0) != "`n")
        text .= "`r`n"
    return text
}

SSOK_ACC_DefaultKeywordLines() {
    text =
(
°£½Ä=ÇÐ»ý°£½Äºñ,°£½Äºñ,ÇÐ»ý °£½Ä,ÇÐ»ý ¿©ºñ,½Äºñ,±âÁØ´Ü°¡,´Ü°¡,´ëÈ¸ °£½Ä,ÇöÀåÃ¼ÇèÇÐ½À °£½Ä
ÇÐ»ý°£½Äºñ=ÇÐ»ý°£½Äºñ,°£½Äºñ,ÇÐ»ý °£½Ä,1ÀÏ,3,000¿ø,3000¿ø
½Äºñ=ÇÐ»ý ½Äºñ,½Äºñ,1½Ä,10,000¿ø,10000¿ø,±Þ½Äºñ,½Ä´ë
¿©ºñ=ÇÐ»ý¿©ºñ,¿©ºñ,¿îÀÓ,¼÷¹Úºñ,½Äºñ,ÃâÀå
¼öÀÍÀÚºÎ´ã=¼öÀÍÀÚºÎ´ã°æºñ,¼öÀÍÀÚ ºÎ´ã,Á¤»ê,°ø°³,ÇÐºÎ¸ðºÎ´ã
°ø°³=ÇÐ±³ÀçÁ¤¿î¿µÀÇ °ø°³,¼öÀÍÀÚºÎ´ã°æºñ °ø°³,¾÷¹«ÃßÁøºñ °ø°³,»óÇ°±Ç °ø°³
¾÷¹«ÃßÁøºñ=¾÷¹«ÃßÁøºñ,ÇùÀÇÈ¸,°£´ãÈ¸,Á¢´ë,°æÁ¶»ç
»óÇ°±Ç=»óÇ°±Ç,»óÇ°±Ç ±¸¸Å,»óÇ°±Ç »ç¿ë,°ø°³
°­»ç=°­»ç¼ö´ç,°­»ç·á,¿ÜºÎ°­»ç,¿ø°í·á,¼ö´ç
°è¾à=°è¾à,¼öÀÇ°è¾à,°ø°³°ßÀû,G2B,S2B,³ª¶óÀåÅÍ,ÁöÁ¤Á¤º¸Ã³¸®ÀåÄ¡
)
    return text . "`r`n"
}

SSOK_ACC_IsStopWord(token) {
    t := SSOK_ACC_Compact(token)
    if (t = "¾ó¸¶" || t = "¹«¾ù" || t = "¹¹¾ß" || t = "ÀÖ³ª" || t = "ÀÖ³ª¿ä")
        return true
    if (t = "µÇ´ÂÁö" || t = "°¡´É" || t = "°¡´ÉÇÑ°¡" || t = "¾Ë·ÁÁà" || t = "Ã£¾ÆÁà")
        return true
    if (t = "±âÁØ" || t = "±ÔÁ¤" || t = "ÁöÄ§" || t = "³»¿ë")
        return true
    return false
}


SSOK_WRK_EnsureInit() {
    global SSOK_WRK_Records, SSOK_WRK_Loaded, SSOK_WRK_LastResults, SSOK_WRK_MinScore
    global SSOK_WRK_Placeholder, SSOK_WRK_IsPlaceholder
    if (!IsObject(SSOK_WRK_Records))
        SSOK_WRK_Records := []
    if (SSOK_WRK_Loaded = "")
        SSOK_WRK_Loaded := false
    if (!IsObject(SSOK_WRK_LastResults))
        SSOK_WRK_LastResults := []
    if (SSOK_WRK_MinScore = "")
        SSOK_WRK_MinScore := 18
    if (SSOK_WRK_Placeholder = "")
        SSOK_WRK_Placeholder := "°ø¹«Á÷ Q&A °Ë»ö"
    if (SSOK_WRK_IsPlaceholder = "")
        SSOK_WRK_IsPlaceholder := false
}

SSOK_WRK_RunSearch(query) {
    global SSOK_WRK_LastResults, SSOK_WRK_Placeholder, SSOK_WRK_IsPlaceholder
    SSOK_WRK_EnsureInit()
    q := Trim(query)
    if (q = "" || q = SSOK_WRK_Placeholder || SSOK_WRK_IsPlaceholder) {
        MsgBox, 48, SSOK °ø¹«Á÷ Q&A, 2026³âµµ ±³À°°ø¹«Á÷¿ø µî Á¾ÇÕ°ü¸®°èÈ¹¿¡¼­ °ü·Ã Å°¿öµå¸¦ Ã£Áö ¸øÇÏ¿´½À´Ï´Ù.
        return
    }

    SSOK_WRK_DoSearch(q)

    if (!IsObject(SSOK_WRK_LastResults) || SSOK_WRK_LastResults.MaxIndex() < 1) {
        MsgBox, 48, SSOK °ø¹«Á÷ Q&A, 2026³âµµ ±³À°°ø¹«Á÷¿ø µî Á¾ÇÕ°ü¸®°èÈ¹¿¡¼­ °ü·Ã Å°¿öµå¸¦ Ã£Áö ¸øÇÏ¿´½À´Ï´Ù.
        return
    }

    prompt := SSOK_WRK_BuildGeminiPrompt(q, SSOK_WRK_LastResults)
    wrkClipSaved := ClipboardAll
    if (!SSOK_SetClipboardTextWithWait(prompt, 3, 3)) {
        Clipboard := wrkClipSaved
        MsgBox, 16, SSOK °ø¹«Á÷ Q&A, Gemini·Î º¸³¾ ¹®±¸¸¦ Å¬¸³º¸µå¿¡ º¹»çÇÏÁö ¸øÇß½À´Ï´Ù.
        return
    }

    SSOK_ACC_OpenGeminiAndPaste()
}

SSOK_WRK_LoadIndex() {
    global SSOK_WRK_Loaded, SSOK_WRK_Records
    SSOK_WRK_EnsureInit()
    if (SSOK_WRK_Loaded)
        return

    SSOK_WRK_Records := []
    baseDir := SSOK_ACC_GetAccDir()
    idxPath := baseDir . "\ssok_index2.tsv"

    if (!FileExist(idxPath)) {
        MsgBox, 16, SSOK °ø¹«Á÷ Q&A, °Ë»ö ÀÚ·á ÆÄÀÏÀ» Ã£À» ¼ö ¾ø½À´Ï´Ù.`n%idxPath%
        return
    }

    loadedCount := SSOK_WRK_LoadIndexFile(idxPath)
    if (loadedCount < 1) {
        MsgBox, 16, SSOK °ø¹«Á÷ Q&A, °Ë»ö ÀÚ·á ÆÄÀÏÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`n%idxPath%
        return
    }

    SSOK_WRK_Loaded := true
}

SSOK_WRK_LoadIndexFile(idxPath) {
    global SSOK_WRK_Records

    FileRead, raw, *P65001 %idxPath%
    if (ErrorLevel) {
        MsgBox, 16, SSOK °ø¹«Á÷ Q&A, °Ë»ö ÀÚ·á ÆÄÀÏÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`n%idxPath%
        return 0
    }

    loaded := 0
    Loop, Parse, raw, `n, `r
    {
        if (A_Index = 1)
            continue
        line := A_LoopField
        if (line = "")
            continue

        parts := StrSplit(line, A_Tab)
        if (parts.MaxIndex() < 4)
            continue

        item := Object()
        item.doc := parts[1]
        item.page := parts[2]
        item.section := parts[3]
        item.text := SSOK_ACC_Unescape(parts[4])
        item.compact := SSOK_ACC_Compact(item.text . " " . item.section . " " . item.page . "ÂÊ")
        item.score := 0
        SSOK_WRK_Records.Push(item)
        loaded++
    }

    return loaded
}

SSOK_WRK_DoSearch(query) {
    global SSOK_WRK_Records, SSOK_WRK_LastResults, SSOK_WRK_MinScore
    SSOK_WRK_LoadIndex()

    top := []
    q := Trim(query)
    terms := SSOK_WRK_MakeTerms(q)
    qCompact := SSOK_ACC_Compact(q)

    ; ÂÊ¼ö Á÷Á¢ °Ë»ö: ¿¹) 95ÂÊ
    if (RegExMatch(q, "(\d+)\s*ÂÊ", m)) {
        pageAsked := m1 + 0
        for i, rec in SSOK_WRK_Records {
            if (rec.page = pageAsked) {
                item := SSOK_ACC_Clone(rec)
                item.score := 999
                SSOK_ACC_InsertTop(top, item, 10)
            }
        }
    }

    for i, rec in SSOK_WRK_Records {
        score := 0
        t := rec.compact

        if (qCompact != "" && InStr(t, qCompact))
            score += 120

        for k, term in terms {
            cterm := SSOK_ACC_Compact(term)
            if (cterm = "")
                continue
            if (InStr(t, cterm)) {
                add := 4
                if (StrLen(cterm) >= 4)
                    add := 10
                if (StrLen(cterm) >= 6)
                    add := 18
                if (StrLen(cterm) >= 9)
                    add := 28
                score += add
                score += SSOK_ACC_CountHits(t, cterm) * 2
            }
        }

        ; ±³À°°ø¹«Á÷ ÁúÀÇ º¸Á¤
        if (InStr(qCompact, "ÈÞÁ÷") && InStr(t, "ÈÞÁ÷"))
            score += 120
        if (InStr(qCompact, "À°¾Æ") && InStr(t, "À°¾ÆÈÞÁ÷"))
            score += 160
        if (InStr(qCompact, "Áúº´") && InStr(t, "Áúº´ÈÞÁ÷"))
            score += 130
        if (InStr(qCompact, "°¡Á·µ¹º½") && (InStr(t, "°¡Á·µ¹º½ÈÞÁ÷") || InStr(t, "°¡Á·µ¹º½ÈÞ°¡")))
            score += 140
        if (InStr(qCompact, "Àüº¸") && InStr(t, "Àüº¸"))
            score += 120
        if ((InStr(qCompact, "Ã¤¿ë") || InStr(qCompact, "´ëÃ¼ÀÎ·Â") || InStr(qCompact, "±â°£Á¦")) && (InStr(t, "Ã¤¿ë") || InStr(t, "±â°£Á¦±Ù·ÎÀÚ") || InStr(t, "´ëÃ¼ÀÎ·Â")))
            score += 100
        if ((InStr(qCompact, "±Ù·Î°è¾à") || InStr(qCompact, "°è¾à¼­")) && (InStr(t, "±Ù·Î°è¾à") || InStr(t, "Ç¥ÁØ±Ù·Î°è¾à¼­")))
            score += 100
        if (InStr(qCompact, "±Ù·Î½Ã°£") && InStr(t, "±Ù·Î½Ã°£"))
            score += 110
        if ((InStr(qCompact, "ÈÞ°¡") || InStr(qCompact, "¿¬Â÷") || InStr(qCompact, "º´°¡") || InStr(qCompact, "°ø°¡")) && (InStr(t, "ÈÞ°¡") || InStr(t, "¿¬Â÷") || InStr(t, "º´°¡") || InStr(t, "°ø°¡")))
            score += 110
        if ((InStr(qCompact, "ÀÓ±Ý") || InStr(qCompact, "±Þ¿©") || InStr(qCompact, "º¸¼ö")) && (InStr(t, "ÀÓ±Ý") || InStr(t, "±Þ¿©") || InStr(t, "º¸¼öÃ¼°è")))
            score += 110
        if ((InStr(qCompact, "ÅðÁ÷") || InStr(qCompact, "»çÁ÷") || InStr(qCompact, "±Ù·Î°ü°èÁ¾·á")) && (InStr(t, "ÅðÁ÷") || InStr(t, "»çÁ÷") || InStr(t, "±Ù·Î°ü°èÁ¾·á")))
            score += 110
        if ((InStr(qCompact, "4´ëº¸Çè") || InStr(qCompact, "»çÈ¸º¸Çè")) && (InStr(t, "4´ë»çÈ¸º¸Çè") || InStr(t, "»çÈ¸º¸Çè")))
            score += 110
        if ((InStr(qCompact, "Â¡°è") || InStr(qCompact, "Æò°¡")) && (InStr(t, "Â¡°è") || InStr(t, "Æò°¡")))
            score += 80

        if (score >= SSOK_WRK_MinScore) {
            item := SSOK_ACC_Clone(rec)
            item.score := score
            SSOK_ACC_InsertTop(top, item, 10)
        }
    }

    SSOK_WRK_LastResults := top
}

SSOK_WRK_MakeTerms(q) {
    arr := []
    clean := RegExReplace(q, "[?£¿!£¡,£¬.¡£:£º;£»/\\\[\]\(\){}<>]", " ")
    compactWhole := SSOK_ACC_Compact(clean)
    if (compactWhole != "")
        arr.Push(compactWhole)

    Loop, Parse, clean, %A_Space%
    {
        token := Trim(A_LoopField)
        if (StrLen(token) < 2)
            continue
        if (SSOK_WRK_IsStopWord(token))
            continue
        arr.Push(token)
    }

    qc := SSOK_ACC_Compact(q)
    if (InStr(qc, "ÈÞÁ÷")) {
        arr.Push("ÈÞÁ÷"), arr.Push("ÈÞÁ÷ Á¾·ùº° »çÀ¯ ¹× ±â°£"), arr.Push("ÈÞÁ÷¿ø"), arr.Push("º¹Á÷¿ø")
    }
    if (InStr(qc, "À°¾Æ")) {
        arr.Push("À°¾ÆÈÞÁ÷"), arr.Push("À°¾Æ±â ±Ù·Î½Ã°£ ´ÜÃà"), arr.Push("ÀÚ³à´ç 3³â")
    }
    if (InStr(qc, "Áúº´")) {
        arr.Push("Áúº´ÈÞÁ÷"), arr.Push("Áø´Ü¼­"), arr.Push("Àå±â¿ä¾ç")
    }
    if (InStr(qc, "Àüº¸")) {
        arr.Push("Àüº¸´ë»ó"), arr.Push("Àüº¸½Ã±â"), arr.Push("Àüº¸À¯¿¹"), arr.Push("Àüº¸Á¡¼öÁ¦")
    }
    if (InStr(qc, "Ã¤¿ë") || InStr(qc, "´ëÃ¼") || InStr(qc, "±â°£Á¦")) {
        arr.Push("¹«±â°è¾à±Ù·ÎÀÚ Ã¤¿ë"), arr.Push("±â°£Á¦±Ù·ÎÀÚ"), arr.Push("´ëÃ¼ÀÎ·Â"), arr.Push("ºñÁ¤±ÔÁ÷ »çÀü½É»çÁ¦")
    }
    if (InStr(qc, "±Ù·Î°è¾à") || InStr(qc, "°è¾à¼­")) {
        arr.Push("±Ù·Î°è¾à"), arr.Push("Ç¥ÁØ±Ù·Î°è¾à¼­"), arr.Push("»ó½Ã±Ù·ÎÀÚ"), arr.Push("¹æÁßºñ±Ù¹«ÀÚ")
    }
    if (InStr(qc, "±Ù·Î½Ã°£") || InStr(qc, "ÈÞ°Ô")) {
        arr.Push("±Ù·Î½Ã°£"), arr.Push("ÈÞ°Ô½Ã°£"), arr.Push("¼ÒÁ¤±Ù·Î½Ã°£")
    }
    if (InStr(qc, "ÈÞ°¡") || InStr(qc, "¿¬Â÷") || InStr(qc, "º´°¡") || InStr(qc, "°ø°¡")) {
        arr.Push("ÈÞ°¡"), arr.Push("¿¬Â÷À¯±ÞÈÞ°¡"), arr.Push("º´°¡"), arr.Push("°ø°¡"), arr.Push("Æ¯º°ÈÞ°¡")
    }
    if (InStr(qc, "ÀÓ±Ý") || InStr(qc, "±Þ¿©") || InStr(qc, "º¸¼ö")) {
        arr.Push("º¸¼öÃ¼°è"), arr.Push("Áö±Þ±âÁØ"), arr.Push("¿ùº° ±Þ¿©"), arr.Push("ÀÓ±ÝÇù¾à")
    }
    if (InStr(qc, "ÅðÁ÷") || InStr(qc, "»çÁ÷")) {
        arr.Push("ÅðÁ÷±Þ¿©Á¦µµ"), arr.Push("±Ù·Î°ü°è Á¾·á"), arr.Push("»çÁ÷¿ø")
    }
    if (InStr(qc, "4´ë") || InStr(qc, "»çÈ¸º¸Çè")) {
        arr.Push("4´ë »çÈ¸º¸Çè"), arr.Push("±¹¹Î¿¬±Ý"), arr.Push("°Ç°­º¸Çè"), arr.Push("°í¿ëº¸Çè"), arr.Push("»êÀçº¸Çè")
    }

    SSOK_WRK_AddKeywordAliases(arr, qc)

    return SSOK_ACC_Unique(arr)
}

SSOK_WRK_IsStopWord(token) {
    t := SSOK_ACC_Compact(token)
    if (SSOK_ACC_IsStopWord(token))
        return true
    if (t = "±³À°°ø¹«Á÷" || t = "±³À°°ø¹«Á÷¿ø" || t = "°ø¹«Á÷")
        return true
    if (t = "°ü¸®°èÈ¹" || t = "Á¾ÇÕ°ü¸®°èÈ¹")
        return true
    return false
}

SSOK_WRK_AddKeywordAliases(ByRef arr, qc) {
    keywordLines := SSOK_WRK_GetKeywordSectionForSearch()
    Loop, Parse, keywordLines, `n, `r
    {
        line := Trim(A_LoopField)
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue
        eq := InStr(line, "=")
        if (!eq)
            continue
        key := Trim(SubStr(line, 1, eq-1))
        vals := Trim(SubStr(line, eq+1))
        if (key != "" && InStr(qc, SSOK_ACC_Compact(key))) {
            Loop, Parse, vals, CSV
            {
                v := Trim(A_LoopField)
                if (v != "")
                    arr.Push(v)
            }
        }
    }
}

SSOK_WRK_GetKeywordSectionForSearch() {
    text := SSOK_WRK_GetKeywordSectionFromSsokIni()
    if (Trim(text) != "")
        return text

    return SSOK_WRK_DefaultKeywordLines()
}

SSOK_WRK_GetKeywordSectionFromSsokIni() {
    iniPath := SSOK_IniFile
    if (!FileExist(iniPath))
        return ""

    FileRead, raw, %iniPath%
    if (ErrorLevel)
        return ""

    return SSOK_ACC_ExtractIniSection(raw, "WorkerKeywords")
}

SSOK_WRK_DefaultKeywordLines() {
    text =
(
ÈÞÁ÷=ÈÞÁ÷,ÈÞÁ÷¿ø,º¹Á÷¿ø,À°¾ÆÈÞÁ÷,Áúº´ÈÞÁ÷,°¡Á·µ¹º½ÈÞÁ÷,»êÀçÈÞÁ÷,º´¿ªÈÞÁ÷
À°¾Æ=À°¾ÆÈÞÁ÷,À°¾Æ±â ±Ù·Î½Ã°£ ´ÜÃà,ÀÚ³à,ÀÓ½Å,Ãâ»ê,¸ÂÃãÇüº¹Áöºñ
Àüº¸=Àüº¸,Àüº¸´ë»ó,Àüº¸½Ã±â,Àüº¸À¯¿¹,Àüº¸Á¡¼öÁ¦,ÀÎ»ç°íÃæ½É»çÇùÀÇÈ¸
Ã¤¿ë=Ã¤¿ë,¹«±â°è¾à±Ù·ÎÀÚ Ã¤¿ë,±â°£Á¦±Ù·ÎÀÚ,´ëÃ¼ÀÎ·Â,ºñÁ¤±ÔÁ÷ »çÀü½É»çÁ¦
±Ù·Î°è¾à=±Ù·Î°è¾à,Ç¥ÁØ±Ù·Î°è¾à¼­,»ó½Ã±Ù·ÎÀÚ,¹æÁßºñ±Ù¹«ÀÚ,´Ü½Ã°£±Ù·ÎÀÚ,ÀÏ¿ë±Ù·ÎÀÚ
±Ù·Î½Ã°£=±Ù·Î½Ã°£,ÈÞ°Ô½Ã°£,¼ÒÁ¤±Ù·Î½Ã°£,ÃâÀå,¿¬¼ö,±³À°
ÈÞ°¡=ÈÞ°¡,¿¬Â÷À¯±ÞÈÞ°¡,º´°¡,°ø°¡,Æ¯º°ÈÞ°¡,¸ð¼ºº¸È£
ÀÓ±Ý=ÀÓ±Ý,º¸¼öÃ¼°è,Áö±Þ±âÁØ,±Þ¿©,¿ùº° ±Þ¿©,ÀÓ±ÝÇù¾à
ÅðÁ÷=ÅðÁ÷±Þ¿©Á¦µµ,ÅðÁ÷±Þ¿©,±Ù·Î°ü°è Á¾·á,»çÁ÷¿ø
»çÈ¸º¸Çè=4´ë »çÈ¸º¸Çè,±¹¹Î¿¬±Ý,°Ç°­º¸Çè,°í¿ëº¸Çè,»êÀçº¸Çè
)
    return text . "`r`n"
}

SSOK_WRK_BuildGeminiPrompt(q, top) {
    prompt := "´ç½ÅÀº ¼¼Á¾ ±³À°°ø¹«Á÷¿ø µî Á¾ÇÕ°ü¸®°èÈ¹ Q&A °ËÅä µµ¿ì¹ÌÀÔ´Ï´Ù.`r`n"
    prompt .= "¾Æ·¡ [Á¦°ø ±Ù°Å] ¾È¿¡¼­¸¸ °Ë»öÇÏ°í ´äº¯ÇÏ¼¼¿ä.`r`n"
    prompt .= "PDF Ã·ºÎÆÄÀÏÀº ¾øÀ¸¹Ç·Î, ¾Æ·¡ Á¦°øµÈ ±Ù°Å ÅØ½ºÆ®¸¸ »ç¿ëÇÏ¼¼¿ä.`r`n"
    prompt .= "´Ù¸¥ ¹ý·É, ´Ù¸¥ ½Ãµµ ÁöÄ§, ÀÎÅÍ³Ý °Ë»ö, ÀÏ¹Ý »ó½ÄÀº Àý´ë »ç¿ëÇÏÁö ¸¶¼¼¿ä.`r`n"
    prompt .= "±Ù°Å ¾È¿¡ ´äÀÌ ¾øÀ¸¸é ¹Ýµå½Ã 'ÁöÄ§°ú ±ÔÁ¤¿¡ ¾øÀ½'ÀÌ¶ó°í¸¸ ´äÇÏ¼¼¿ä.`r`n"
    prompt .= "´äÀÌ ÀÖÀ¸¸é 6~9¹®ÀåÀ¸·Î Ä£ÀýÇÏ°Ô ´äÇÏ°í, ¸¶Áö¸·¿¡ ±Ù°Å ¹®¼­¸í°ú ÂÊ¼ö¸¦ Ç¥½ÃÇÏ¼¼¿ä.`r`n"
    prompt .= "ÈÞÁ÷¡¤Àüº¸¡¤Ã¤¿ë¡¤±Ù·Î°è¾à¡¤±Ù·Î½Ã°£¡¤ÈÞ°¡¡¤ÀÓ±Ý¡¤4´ëº¸Çè¡¤ÅðÁ÷±Þ¿© °ü·Ã ³»¿ëÀº Á¦°ø ±Ù°Å ¾È¿¡¼­ ÃÖ´ëÇÑ Á¤È®È÷ È®ÀÎÇÏ¼¼¿ä.`r`n`r`n"
    prompt .= "[Áú¹®]`r`n" . q . "`r`n`r`n"
    prompt .= "[Á¦°ø ±Ù°Å]`r`n"

    max := top.MaxIndex()
    if (max > 8)
        max := 8
    Loop, %max%
    {
        item := top[A_Index]
        prompt .= "--- ±Ù°Å " . A_Index . " ---`r`n"
        prompt .= item.doc . " " . item.page . "ÂÊ`r`n"
        if (item.section != "")
            prompt .= item.section . "`r`n"
        prompt .= SSOK_ACC_Limit(item.text, 1900) . "`r`n`r`n"
    }
    return prompt
}

SSOK_ACC_BuildGeminiPrompt(q, top) {
    prompt := "´ç½ÅÀº ¼¼Á¾ ÇÐ±³È¸°è ¼¼Ãâ¿¹»ê ÁýÇàÁöÄ§ Q&A °ËÅä µµ¿ì¹ÌÀÔ´Ï´Ù.`r`n"
    prompt .= "¾Æ·¡ [Á¦°ø ±Ù°Å] ¾È¿¡¼­¸¸ °Ë»öÇÏ°í ´äº¯ÇÏ¼¼¿ä.`r`n"
    prompt .= "PDF Ã·ºÎÆÄÀÏÀº ¾øÀ¸¹Ç·Î, ¾Æ·¡ Á¦°øµÈ ±Ù°Å ÅØ½ºÆ®¸¸ »ç¿ëÇÏ¼¼¿ä.`r`n"
    prompt .= "´Ù¸¥ ¹ý·É, ´Ù¸¥ ½Ãµµ ÁöÄ§, ÀÎÅÍ³Ý °Ë»ö, ÀÏ¹Ý »ó½ÄÀº Àý´ë »ç¿ëÇÏÁö ¸¶¼¼¿ä.`r`n"
    prompt .= "±Ù°Å ¾È¿¡ ´äÀÌ ¾øÀ¸¸é ¹Ýµå½Ã 'ÁöÄ§°ú ±ÔÁ¤¿¡ ¾øÀ½'ÀÌ¶ó°í¸¸ ´äÇÏ¼¼¿ä.`r`n"
    prompt .= "´äÀÌ ÀÖÀ¸¸é 6~9¹®ÀåÀ¸·Î Ä£ÀýÇÏ°Ô ´äÇÏ°í, ¸¶Áö¸·¿¡ ±Ù°Å ¹®¼­¸í°ú ÂÊ¼ö¸¦ Ç¥½ÃÇÏ¼¼¿ä.`r`n"
    prompt .= "ÂÊ¼ö¡¤Ç¥¡¤ºÎ·Ï¡¤±âÁØ´Ü°¡ °ü·Ã ³»¿ëÀº Á¦°ø ±Ù°Å ¾È¿¡¼­ ÃÖ´ëÇÑ Á¤È®È÷ È®ÀÎÇÏ¼¼¿ä.`r`n`r`n"
    prompt .= "[Áú¹®]`r`n" . q . "`r`n`r`n"
    prompt .= "[Á¦°ø ±Ù°Å]`r`n"

    max := top.MaxIndex()
    if (max > 8)
        max := 8
    Loop, %max%
    {
        item := top[A_Index]
        prompt .= "--- ±Ù°Å " . A_Index . " ---`r`n"
        prompt .= item.doc . " " . item.page . "ÂÊ`r`n"
        if (item.section != "")
            prompt .= item.section . "`r`n"
        prompt .= SSOK_ACC_Limit(item.text, 1900) . "`r`n`r`n"
    }
    return prompt
}

SSOK_ACC_Clone(rec) {
    item := Object()
    item.doc := rec.doc
    item.page := rec.page
    item.section := rec.section
    item.text := rec.text
    item.compact := rec.compact
    item.score := rec.score
    return item
}

SSOK_ACC_InsertTop(ByRef top, item, limit) {
    inserted := false
    max := top.MaxIndex()
    if (!max) {
        top.Push(item)
    } else {
        Loop, %max%
        {
            if (item.score > top[A_Index].score) {
                top.InsertAt(A_Index, item)
                inserted := true
                break
            }
        }
        if (!inserted)
            top.Push(item)
    }
    while (top.MaxIndex() > limit)
        top.RemoveAt(top.MaxIndex())
}

SSOK_ACC_CountHits(text, term) {
    count := 0
    if (term = "")
        return count
    pos := 1
    len := StrLen(term)
    Loop
    {
        p := InStr(text, term, false, pos)
        if (!p)
            break
        count++
        if (count >= 6)
            break
        pos := p + len
    }
    return count
}

SSOK_ACC_Unique(arr) {
    out := []
    seen := Object()
    for k, v in arr {
        v := Trim(v)
        if (v = "")
            continue
        key := SSOK_ACC_Compact(v)
        if (key = "")
            continue
        if (!seen.HasKey(key)) {
            seen[key] := true
            out.Push(v)
        }
    }
    return out
}

SSOK_ACC_Compact(s) {
    StringLower, s, s
    s := RegExReplace(s, "\s+", "")
    removeChars := " ,£¬.¡£:£º;£»/\|-+*?£¿!£¡()[]{}<>¡¸¡¹¡º¡»'¡¤¤ý?????¡á¡à¢º?¡Ø"
    s := StrReplace(s, Chr(34), "")
    Loop, Parse, removeChars
    {
        ch := A_LoopField
        if (ch != "")
            s := StrReplace(s, ch, "")
    }
    return s
}

SSOK_ACC_Limit(text, n) {
    if (StrLen(text) <= n)
        return text
    return SubStr(text, 1, n) . "`r`n...(ÀÌÇÏ »ý·«)"
}

SSOK_ACC_Unescape(s) {
    return StrReplace(s, "\n", "`r`n")
}

; =========================================================
; ÄÄÆÄÀÏ EXE Æ÷ÇÔ ÆÄÀÏ Ç®±â
; - ssok.ini´Â »ç¿ëÀÚ ÀúÀå ÆÄÀÏÀÌ¹Ç·Î Æ÷ÇÔÇÏÁö ¾ÊÀ½
; - ±âÁ¸ ¿ÜºÎ TSV°¡ ÀÖÀ¸¸é µ¤¾î¾²Áö ¾ÊÀ½
; =========================================================
SSOK_InstallBundledFiles:
    if (!A_IsCompiled)
        return

    installErrors := ""
    index1Path := A_ScriptDir . "\ssok_index1.tsv"
    index2Path := A_ScriptDir . "\ssok_index2.tsv"

    FileInstall, ssok_index1.tsv, %index1Path%, 0
    if (!FileExist(index1Path))
        installErrors .= "ssok_index1.tsv`n"

    FileInstall, ssok_index2.tsv, %index2Path%, 0
    travelPath := A_ScriptDir . "\ssok_travel.ahk"
    FileInstall, ssok_travel.ahk, %travelPath%, 0
    if (!FileExist(travelPath))
        installErrors .= "ssok_travel.ahk`n"
    if (!FileExist(index2Path))
        installErrors .= "ssok_index2.tsv`n"

    if (installErrors != "")
        MsgBox, 48, SSOK °Ë»ö ÀÚ·á ¼³Ä¡, ´ÙÀ½ °Ë»ö ÀÚ·á ÆÄÀÏÀ» ÁØºñÇÏÁö ¸øÇß½À´Ï´Ù.`n`n%installErrors%`nSSOK Q&A °Ë»ö ±â´ÉÀÌ Á¦ÇÑµÉ ¼ö ÀÖ½À´Ï´Ù.
return
; =========================================================
; SSOK ½ºÅ©¸° Ä¸Ã³ ÅëÇÕ ¸ðµâ
; - ÄÄÆÄÀÏ ½Ã ssok_capture.ahkµµ ssok.exe ¾È¿¡ Æ÷ÇÔµË´Ï´Ù.
; =========================================================
#Include %A_ScriptDir%\ssok_capture.ahk

SSOK_TrayOpenTravel:
    travelPath := A_ScriptDir . "\ssok_travel.ahk"
    if (!FileExist(travelPath))
    {
        MsgBox, 48, SSOK, ssok_travel.ahk ÆÄÀÏÀ» Ã£À» ¼ö ¾ø½À´Ï´Ù.
        return
    }
    ahkPath := A_ScriptDir . "\AutoHotkeyU64.exe"
    if (FileExist(ahkPath))
        Run, %ahkPath% "%travelPath%"
    else
        Run, %travelPath%
return

; SSOK ±â´É µµ±¸ ÅëÇÕ ¸ðµâ
#Include %A_ScriptDir%\ssok_tool.ahk

; SSOK °£Æí ÁöÃâÇ°ÀÇ ¸ðµâ
#Include %A_ScriptDir%\ssok_tool_expense.ahk
