; =========================================================
; SSOK ´ÜÃàÅ° Àç¹èÄ¡ ÄÄÆÑÆ® Á¤¸® ¹öÀü
; =========================================================

;@Ahk2Exe-SetDescription SSOK ¾÷¹« ´ÜÃàÅ° µµ¿ì¹Ì
;@Ahk2Exe-SetCompanyName ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»
;@Ahk2Exe-SetCopyright ÀÌ¸íÈ£
;@Ahk2Exe-SetProductName SSOK
;@Ahk2Exe-SetOrigFilename ssok.exe

global SSOK_VERSION := "260926"
global SSOK_VERSION_DATE := "2026.9.9"
global SSOK_COPYRIGHT_TEXT := "¨Ï ¼¼Á¾½Ã±³À°Ã» ÀÌ¸íÈ£(v." . SSOK_VERSION . ")"
global SSOK_PrintPauseActive := false
global SSOK_PrintPauseMenuText := "OZ Ãâ·Â ÀÏ½ÃÁ¤Áö/ÇØÁ¦"

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







; =========================================================
; Win + F10 : °³ÀÎÁ¤º¸ Á¤¸®
; - ºí·Ï ¼±ÅÃÀÌ ÀÖÀ¸¸é ¼±ÅÃ ¿µ¿ª¸¸ °¡¸² Ã³¸®
; - ºí·Ï ¼±ÅÃÀÌ ¾øÀ¸¸é Ctrl+A·Î ÀüÃ¼ ¹®¼­¸¦ ¼±ÅÃÇÏ¿© ¹®¼­ ÀüÃ¼¿¡¼­ Ã£¾Æ °¡¸² Ã³¸®
; - ÈÞ´ëÀüÈ­, ÀÏ¹ÝÀüÈ­/ÆÑ½º, ÁÖ¹Îµî·Ï¹øÈ£, ÀÌ¸ÞÀÏ, Ä«µå¹øÈ£, ±ä °èÁÂ/½Äº°¹øÈ£, ÀÏºÎ ÀÌ¸§ ÇüÅÂ¸¦ ±âº» ¸¶½ºÅ·
; =========================================================
#F10::
    ; Win Å°°¡ ´­¸° »óÅÂ¿¡¼­ Ctrl+C/Ctrl+A°¡ ¼¯ÀÌ¸é º¹»ç°¡ ½ÇÆÐÇÏ´Â °æ¿ì°¡ ÀÖ¾î ¸ÕÀú Win ÇØÁ¦ ´ë±â
    KeyWait, LWin
    KeyWait, RWin
    Gosub, SSOK_DoPrivacyMask
return

SSOK_DoPrivacyMask:
    SavedClipboard := ClipboardAll
    Clipboard := ""
    SSOK_PrivacySelectionMode := false

    ; 1. ¸ÕÀú ºí·Ï ÁöÁ¤µÈ ¼±ÅÃ ¿µ¿ªÀÌ ÀÖ´ÂÁö È®ÀÎ
    if (SSOK_CopyClipboardText(originalText, 0.35, 2, true) && originalText != "")
        SSOK_PrivacySelectionMode := true

    ; 2. ¼±ÅÃ ¿µ¿ªÀÌ ¾øÀ¸¸é ÇöÀç ÁÙÀÌ ¾Æ´Ï¶ó ¹®¼­ ÀüÃ¼¸¦ ´ë»óÀ¸·Î Ã³¸®
    if (originalText = "")
    {
        SSOK_PrivacySelectionMode := false
        SendInput, ^a
        Sleep, 100
        if (!SSOK_CopyClipboardText(originalText, 0.8, 3, true))
        {
            Clipboard := SavedClipboard
            ToolTip, Å¬¸³º¸µå¿¡¼­ ¹®¼­ ³»¿ëÀ» °¡Á®¿ÀÁö ¸øÇß½À´Ï´Ù.
            SetTimer, RemoveToolTip, -1800
            return
        }
    }

    if (originalText = "")
    {
        Clipboard := SavedClipboard
        ToolTip, ¼±ÅÃ ¿µ¿ª ¶Ç´Â ÀüÃ¼ ¹®¼­¿¡¼­ Ã³¸®ÇÒ ÅØ½ºÆ®¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.
        SetTimer, RemoveToolTip, -1800
        return
    }

    maskedText := SSOK_MaskPrivateInfo(originalText, SSOK_PrivacySelectionMode)

    ; ¼±ÅÃ ¿µ¿ª ¶Ç´Â Ctrl+A·Î ÀâÈù ÀüÃ¼ ¹®¼­¸¦ °¡¸² Ã³¸® °á°ú·Î ±³Ã¼
    if (!SSOK_SetClipboardTextWithWait(maskedText, 0.7, 3))
    {
        Clipboard := SavedClipboard
        ToolTip, Å¬¸³º¸µå¿¡ °¡¸² Ã³¸® °á°ú¸¦ ´ãÁö ¸øÇß½À´Ï´Ù.
        SetTimer, RemoveToolTip, -1800
        return
    }
    Sleep, 50
    SendInput, ^v
    Sleep, 150
    Clipboard := SavedClipboard
return
SSOK_MaskPrivateInfo(text, forceNameMask := false)
{
    masked := text

    ; ÁÖ¹Îµî·Ï¹øÈ£: 900101-1234567 / 9001011234567 -> 900101-1******
    masked := RegExReplace(masked, "(^|[^\d])(\d{6})[- ]?([1-4])\d{6}(?!\d)", "$1$2-$3******")

    ; ÈÞ´ëÀüÈ­: 010-2571-7607 / 01025717607 / 010 2571 7607 -> 010-****-7607
    masked := RegExReplace(masked, "(^|[^\d])(01[016789])[-\.\s]*(\d{3,4})[-\.\s]*(\d{4})(?!\d)", "$1$2-****-$4")

    ; ÀÏ¹ÝÀüÈ­/ÆÑ½º: 044-320-0000 / 02-123-4567 -> 044-****-0000
    masked := RegExReplace(masked, "(^|[^\d])(0(?:2|[3-6][1-5]|70|50|80))[-\.\s]*(\d{3,4})[-\.\s]*(\d{4})(?!\d)", "$1$2-****-$4")

    ; ÀÌ¸ÞÀÏ: testuser@korea.kr -> t***@korea.kr
    masked := RegExReplace(masked, "\b([A-Za-z0-9._%+\-])([A-Za-z0-9._%+\-]*)(@[A-Za-z0-9.\-]+\.[A-Za-z]{2,})\b", "$1***$3")

    ; Ä«µå¹øÈ£: 1234-5678-9012-3456 / 1234567890123456 -> 1234-****-****-3456
    masked := RegExReplace(masked, "(^|[^\d])(\d{4})[- ]?(\d{4})[- ]?(\d{4})[- ]?(\d{4})(?!\d)", "$1$2-****-****-$5")

    ; »ç¾÷ÀÚµî·Ï¹øÈ£ ÇüÅÂ: 123-45-67890 -> 123-**-*****
    masked := RegExReplace(masked, "(^|[^\d])(\d{3})[- ]?(\d{2})[- ]?(\d{5})(?!\d)", "$1$2-**-*****")

    ; °èÁÂ¹øÈ£/±ä ½Äº°¹øÈ£ ÃßÁ¤: 10~14ÀÚ¸® ¼ýÀÚ ¶Ç´Â ÇÏÀÌÇÂ Æ÷ÇÔ ¼ýÀÚ -> ¾Õ 3ÀÚ¸®¿Í µÚ 3ÀÚ¸®¸¸ º¸Á¸
   ; ¿¹: 1234567890 -> 123****890, 123-456789-012 -> 123****012
    masked := RegExReplace(masked, "(^|[^\d])(\d{3})[- ]?\d{4,8}[- ]?(\d{3})(?!\d)", "$1$2****$3")

    ; ºí·Ï ÁöÁ¤ ½Ã¿¡´Â ÀÌ¸§/´ë»ó °°Àº Ç¥Áö°¡ ¾ø¾îµµ 3±ÛÀÚ ÇÑ±Û ÀÌ¸§ ÈÄº¸¸¦ ¹Ù·Î Ã³¸®ÇÕ´Ï´Ù.
    if (forceNameMask)
        masked := SSOK_MaskThreeCharKoreanNamesInText(masked)
    else
        masked := SSOK_MaskNamesInSensitiveLines(masked)

    return masked
}

SSOK_MaskNamesInSensitiveLines(text)
{
    result := ""
    lineBreak := SSOK_DetectLineBreak(text)
    normalizedText := SSOK_NormalizeLineBreaksForParse(text)
    Loop, Parse, normalizedText, `n
    {
        line := A_LoopField
        if RegExMatch(line, "(´ë»ó|Âü¼®ÀÚ|Âü¿©ÀÚ|ÇÐ»ý¸í|¼º¸í|¼º\s*¸í|¸í´Ü|ÀÌ¸§)")

            line := SSOK_MaskKoreanNamesInLine(line)

        if (A_Index = 1)
            result := line
        else
            result .= lineBreak . line
    }
    return result
}

SSOK_MaskThreeCharKoreanNamesInText(text)
{
    result := ""
    lineBreak := SSOK_DetectLineBreak(text)
    normalizedText := SSOK_NormalizeLineBreaksForParse(text)
    Loop, Parse, normalizedText, `n
    {
        line := SSOK_MaskThreeCharKoreanNamesInLine(A_LoopField)

        if (A_Index = 1)
            result := line
        else
            result .= lineBreak . line
    }
    return result
}

SSOK_DetectLineBreak(text)
{
    if InStr(text, "`r`n")
        return "`r`n"
    if InStr(text, "`n")
        return "`n"
    if InStr(text, "`r")
        return "`r"
    return "`r`n"
}

SSOK_NormalizeLineBreaksForParse(text)
{
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    return text
}


SSOK_MaskThreeCharKoreanNamesInLine(line)
{
    pos := 1
    out := ""
    while RegExMatch(line, "O)([°¡-ÆR]{3})", m, pos)
    {
        word := m.Value(1)
        start := m.Pos(1)
        len := m.Len(1)
        out .= SubStr(line, pos, start - pos)

        __prevChar := (start > 1) ? SubStr(line, start - 1, 1) : ""
        __nextChar := SubStr(line, start + len, 1)
        if (RegExMatch(__prevChar, "[°¡-ÆR]") || RegExMatch(__nextChar, "[°¡-ÆR]"))
        {
            out .= word
            pos := start + len
            continue
        }

        __protected := SSOK_GetProtectedTitleAt(line, start)
        if (__protected != "")
        {
            out .= __protected
            pos := start + StrLen(__protected)
            continue
        }

        if (SSOK_IsMaskableKoreanName(word))
            out .= SubStr(word, 1, 1) . "**"
        else
            out .= word

        pos := start + len
    }
    out .= SubStr(line, pos)
    return out
}

SSOK_MaskKoreanNamesInLine(line)
{
    pos := 1
    out := ""
    while RegExMatch(line, "O)([°¡-ÆR]{2,4})", m, pos)
    {
        word := m.Value(1)
        start := m.Pos(1)
        len := m.Len(1)
        out .= SubStr(line, pos, start - pos)

        ; ±ä ÇÑ±Û ´Ü¾îÀÇ ÀÏºÎ(¿¹: Àü¹®»ó´ã»ç Áß Àü¹®»ó´ã)¸¸ Àß·Á ÀÌ¸§Ã³·³ ¸¶½ºÅ·µÇ´Â °ÍÀ» ¹æÁö
        __prevChar := (start > 1) ? SubStr(line, start - 1, 1) : ""
        __nextChar := SubStr(line, start + len, 1)
        if (RegExMatch(__prevChar, "[°¡-ÆR]") || RegExMatch(__nextChar, "[°¡-ÆR]"))
        {
            out .= word
            pos := start + len
            continue
        }

        ; Á÷Ã¥/¿ªÇÒ ´Ü¾î°¡ 5±ÛÀÚ ÀÌ»óÀÌ¸é ±âÁ¸ [°¡-ÆR]{2,4} °Ë»ö¿¡¼­
        ; ¾Õ 4±ÛÀÚ¸¸ Àß·Á ÀÌ¸§Ã³·³ ¸¶½ºÅ·µÇ´Â ¹®Á¦°¡ ÀÖ½À´Ï´Ù.
       ; ¿¹: Àü¹®»ó´ã»ç -> Àü¹®»ó´ã + »ç ·Î ÀÎ½ÄµÇ¾î Àü***»ç Ã³¸®µÊ
        ; µû¶ó¼­ ÇöÀç À§Ä¡¿¡¼­ º¸È£ ´Ü¾î°¡ ½ÃÀÛÇÏ¸é ÀüÃ¼ ´Ü¾î¸¦ ±×´ë·Î º¸Á¸ÇÕ´Ï´Ù.
        __protected := SSOK_GetProtectedTitleAt(line, start)
        if (__protected != "")
        {
            out .= __protected
            pos := start + StrLen(__protected)
            continue
        }

        if (SSOK_IsMaskableKoreanName(word))
            out .= SubStr(word, 1, 1) . SSOK_RepeatStar(StrLen(word) - 1)
        else
            out .= word

        pos := start + len
    }
    out .= SubStr(line, pos)
    return out
}

SSOK_GetProtectedTitleAt(line, start)
{
    ; ±ä ´Ü¾î¸¦ ¸ÕÀú °Ë»çÇØ¾ß Àü¹®»ó´ã»ç/Àü¹®»ó´ã±³»çÃ³·³ ±ä Á÷Ã¥ÀÌ Àß¸®Áö ¾Ê½À´Ï´Ù.
    titles := "Àü¹®»ó´ã±³»ç|Àü¹®»ó´ã»ç|»ó´ã±³»ç|ºÎÀå±³»ç|ÀÎ¼Ö±³»ç|ÇàÁ¤½ÇÀå|º¸°Ç±³»ç|¿µ¾ç±³»ç|»ç¼­±³»ç|Æ¯¼ö±³»ç|±â°£Á¦±³»ç|´ãÀÓ±³»ç|ÇàÁ¤½Ç|ÇàÁ¤Á÷|Àü¹®°­»ç|¿ÜºÎ°­»ç|±³Á÷¿ø|±³À°°ø¹«Á÷|ÀÎ¼ÖÀÚ|»ó´ã»ç|´ãÀÓ|±³»ç|±³°¨|±³Àå|ÁÖ¹«°ü|°ø¹«¿ø|°­»ç|Á÷¿ø|ÇÐºÎ¸ð|º¸È£ÀÚ|ÇÐ»ý|´ë»ó|Âü¼®ÀÚ|Âü¿©ÀÚ|¼º¸í|¸í´Ü|ÀÌ¸§|¹øÈ£|ÇÐ¹ø|³»¿ª|°Ç¸í|ÀÏ½Ã|Àå¼Ò|³»¿ë|¼Ò¿ä¿¹»ê|Ç°ÀÇ³»¿ª¼­|Âü¿©µ¿ÀÇ¼­|½Ä¹®È­Ã¼Çè|Á¦°úÁ¦»§Ã¼Çè"
    rest := SubStr(line, start)
    Loop, Parse, titles, |
    {
        t := A_LoopField
        if (SubStr(rest, 1, StrLen(t)) = t)
            return t
    }
    return ""
}

SSOK_IsMaskableKoreanName(word)
{
    exclude := "Àü¹®»ó´ã»ç|»ó´ã±³»ç|»ó´ã»ç|ÀÎ¼Ö±³»ç|ÀÎ¼ÖÀÚ|´ãÀÓ±³»ç|´ãÀÓ|±³»ç|±³°¨|±³Àå|ºÎÀå±³»ç|ÇàÁ¤½ÇÀå|ÇàÁ¤½Ç|ÇàÁ¤Á÷|ÁÖ¹«°ü|°ø¹«¿ø|°­»ç|Àü¹®°­»ç|¿ÜºÎ°­»ç|Á÷¿ø|±³Á÷¿ø|ÇÐºÎ¸ð|º¸È£ÀÚ|ÇÐ»ý|´ë»ó|Âü¼®ÀÚ|Âü¿©ÀÚ|¼º¸í|¸í´Ü|ÀÌ¸§|¹øÈ£|ÇÐ¹ø|³»¿ª|°Ç¸í|ÀÏ½Ã|Àå¼Ò|³»¿ë|¼Ò¿ä¿¹»ê|Ç°ÀÇ³»¿ª¼­|Âü¿©µ¿ÀÇ¼­|½Ä¹®È­Ã¼Çè|Á¦°úÁ¦»§Ã¼Çè"
    if RegExMatch(word, "^(" . exclude . ")$")
        return false
    if RegExMatch(word, "^[°¡-ÆR][\*¤·¡ÛO]{1,3}$")
        return false
    return true
}

SSOK_RepeatStar(n)
{
    s := ""
    Loop, %n%
        s .= "*"
    return s
}

; --- ½î¿Á Win+F1 1~12¹ø ºü¸¥ ÀÔ·Â µµ¿ì¹Ì  ---
; =========================================================
; ½î¿Á Win+F1 1~12¹ø ºü¸¥ ÀÔ·Â µµ¿ì¹Ì
; AutoHotkey v1.1 Àü¿ë
;
; ÀúÀå À§Ä¡:
; - AHK ½ÇÇà ½Ã: AHK ÆÄÀÏÀÌ ÀÖ´Â Æú´õ\ssok.ini
; - EXE ½ÇÇà ½Ã: C:\SSOK\ssok.ini
;
; ±â´É:
; - Win+F1 ´©¸£¸é 1~12¹ø ºü¸¥ ÀÔ·Â µµ¿ì¹Ì Ç¥½Ã
; - 1~7¹øÀº »ç¿ëÀÚ°¡ Á÷Á¢ ¼öÁ¤ °¡´É
; - ±âÁ¸ 6¹ø/7¹ø ¹®±¸´Â »õ 5¹ø/6¹øÀ¸·Î ÀÚµ¿ ÀÌµ¿
; - 7¹øÀº »ç¿ëÀÚ ¹®±¸ ÀúÀå/ÀÔ·Â
; - 8¹øÀº ³¯Â¥ / ¿äÀÏ / ±â°£ °è»ê ½ÇÇà
;   * ºí·Ï ÁöÁ¤ ÀÖÀ½: ¼±ÅÃÇÑ ³¯Â¥¸¦ ¿äÀÏ º¸Á¤, ³¯Â¥~³¯Â¥´Â ±â°£ °è»ê
;   * ºí·Ï ÁöÁ¤ ¾øÀ½: ¿À´Ã ³¯Â¥(¿äÀÏ) ÇöÀç ½Ã°£ ÀÔ·Â
; - 9¹øÀº Æ¯¼ö¹®ÀÚ ÀÚµ¿ ÀÔ·Â
; - 1~9¹øÀº ¼ýÀÚÅ° ½ÇÇà, 10~12¹øÀº ¿À¸¥ÂÊ ÀúÀå&&ÀÔ·Â ¹öÆ° ½ÇÇà
; - ¿©·¯ ÁÙ ÀÔ·Â/ÀúÀå/ºÙ¿©³Ö±â Áö¿ø
; - IniWrite »ç¿ë ¾È ÇÔ
; - ssok.ini ÀÚµ¿ »ý¼º
; =========================================================


; =========================================================
; Win + F3 : Gemini AI µµ¿ì¹Ì
; =========================================================
#F3::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF3
return

SSOK_DoF1:
    Gosub, QI_Init
    QILastTargetHwnd := WinExist("A")
    Gosub, QI_LoadTexts
    Gosub, QI_MakeTodayDate
    Gosub, QI_MakeSpecialText
    Gosub, QI_ShowGui
return


; =========================================================
; QI ±âº» ¼³Á¤
; =========================================================
QI_Init:
    QIIni := SSOK_IniFile

    ; Win+F1 ÇÏ´Ü ÀÌ¹ÌÁö ±âº» ¸µÅ© - AHK ¼Ò½º ±âº»°ª
    ; ssok.ini¿¡ ÀúÀåµÈ °ªÀÌ ÀÖÀ¸¸é INI °ªÀ» ¿ì¼±ÇÕ´Ï´Ù.
    QI_DefaultImage12 := "https://www.sje.go.kr/images/T1/sub/img_ci_logo04.png"
    QI_DefaultImage13 := "https://www.sje.go.kr/images/T1/sub/img_ci_logo05.png"
    QI_DefaultImage14 := "https://www.sje.go.kr/images/T1/sub/img_ci_character6.png"
    QI_DefaultImage15 := "https://www.sje.go.kr/images/T1/sub/img_ci_character5.png"
    FileEncoding, UTF-8

    ; ÀÌ¹ÌÁö ¼³Á¤Àº Win+F1À» ´Ù½Ã ¿­°Å³ª ºÙ¿©³ÖÀº µÚ¿¡µµ À¯ÁöµÇ¾î¾ß ÇÕ´Ï´Ù.
    ; ±âÁ¸ °ªÀ» ¸ÕÀú ÀÐ°í, ±× ´ÙÀ½ ÅØ½ºÆ® º¯¼ö¸¸ ÃÊ±âÈ­ÇÕ´Ï´Ù.
    QI_LoadImageSettings()

    QIText1 := ""
    QIText2 := ""
    QIText3 := ""
    QIText4 := ""
    QIText5 := ""
    QIText6 := ""
    QIText7 := ""
    QIText10 := ""
    QIText11 := ""
    QIText12 := ""
    QIImageIni := QIIni
    QITodayText := ""
    QISpecialText := ""
    QINumber := ""
return


; =========================================================
; ±âº»°ª ¼³Á¤
; - 1~7¹ø ¹®±¸ ±âº»°ª ¼³Á¤
; =========================================================
QI_SetDefaults:
    QIDefault1 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    QIDefault2 := "¼ýÀÚÅ° 1~9¹øÀ¸·Î ¹Ù·Î ÀÔ·ÂÇÒ ¼ö ÀÖ½À´Ï´Ù"
    QIDefault3 := "°³ÀÎÁ¤º¸´Â À¯ÃâµÇÁö ¾Êµµ·Ï ÁÖÀÇÇØÁÖ¼¼¿ä"
    QIDefault4 := "¾÷¹«·Î ¹Ù»Ú½Å ¿ÍÁß¿¡µµ Àû±ØÀûÀ¸·Î ÇùÁ¶ÇØ ÁÖ¼Å¼­ °¨»çÇÕ´Ï´Ù. °ü·ÃÇÏ¿© ¹®ÀÇ »çÇ×ÀÌ ÀÖÀ¸½Ã¸é ¾ðÁ¦µç ¿¬¶ô ÁÖ½Ê½Ã¿À. 000 µå¸²"
    QIDefault5 := "¼¼Á¾ ±³À° ¹ßÀüÀ» À§ÇØ ÇùÁ¶ÇØ ÁÖ¼Å¼­ ´Ã °¨»çÇÕ´Ï´Ù. ¿À´Ãµµ º¸¶÷Âù ÇÏ·ç º¸³»½Ã±æ ¹Ù¶ø´Ï´Ù. OOO µå¸²"
    QIDefault6 := "¿¹½Ã) ÁÖ¼Ò ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã º¸¶÷µ¿ ÇÑ´©¸®´ë·Î 2154 (¿ìÆí¹øÈ£ 30151) ÀüÈ­ 044-320-0000 ÆÑ½º 044-320-0000"
    QIDefault7 := "¿¹½Ã) ¸ÞÀÏ dodammid@korea.kr"
    QIDefault10 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    QIDefault11 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    QIDefault12 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
return


; =========================================================
; ¿À´Ã ³¯Â¥ ¸¸µé±â
; ¿¹: 2026. 5. 5.(È­) 14:30
; =========================================================
QI_MakeTodayDate:
    FormatTime, QIYear,, yyyy
    FormatTime, QIMonth,, M
    FormatTime, QIDay,, d

    if (A_WDay = 1)
        QIYoil := "ÀÏ"
    else if (A_WDay = 2)
        QIYoil := "¿ù"
    else if (A_WDay = 3)
        QIYoil := "È­"
    else if (A_WDay = 4)
        QIYoil := "¼ö"
    else if (A_WDay = 5)
        QIYoil := "¸ñ"
    else if (A_WDay = 6)
        QIYoil := "±Ý"
    else if (A_WDay = 7)
        QIYoil := "Åä"

    FormatTime, QITime,, HH:mm
    QITodayText := QIYear . ". " . QIMonth . ". " . QIDay . ".(" . QIYoil . ") " . QITime
return


; =========================================================
; 9¹ø Æ¯¼ö¹®ÀÚ ¸¸µé±â
; =========================================================
QI_MakeSpecialText:
    QISpecialText := "¡¸¹ý¡¹¡¼±Ù°Å¡½¡² ¡³¡¶ ¡·¡º¡»?¡î¡Ý¨¬?¡¤???¡Û¡Û¡à¡à¡Þ¡â¡ä¢¹¡á¡á¡Ü¡ß¢º¡ã¡å- ? ¢Ñ¡°Âü°í¡±¡Ø¡É§®§¯§°§³§¨§±§¸ ¢ß¡À¡¿¡ç¡è¡é ¡ê"
return


; =========================================================
; ssok.ini ÆÄÀÏÀÌ ¾øÀ¸¸é ÀÚµ¿ »ý¼º
; =========================================================
QI_EnsureIni:
    if (QIIni = "")
        Gosub, QI_Init

    Gosub, QI_SetDefaults

    if !FileExist(QIIni)
    {
        QIText1 := QIDefault1
        QIText2 := QIDefault2
        QIText3 := QIDefault3
        QIText4 := QIDefault4
        QIText5 := QIDefault5
        QIText6 := QIDefault6
        QIText7 := QIDefault7
        QIText10 := QIDefault10
        QIText11 := QIDefault11
        QIText12 := QIDefault12

        Gosub, QI_WriteIniFile

        if !FileExist(QIIni)
        {
            MsgBox, 48, ½î¿Á ÀúÀå ¿À·ù, ssok.ini ÆÄÀÏÀ» ¸¸µé ¼ö ¾ø½À´Ï´Ù.`n`nÀúÀå À§Ä¡:`n%QIIni%`n`nÀÌ Æú´õ°¡ ¾²±â ±ÝÁöµÇ¾î ÀÖ°Å³ª ±ÇÇÑÀÌ ¾øÀ» ¼ö ÀÖ½À´Ï´Ù.
        }
    }
return


; =========================================================
; ÀúÀåµÈ ¹®±¸ ºÒ·¯¿À±â
; - ¿©·¯ ÁÙ ÀúÀå°ªµµ º¹¿øÇÔ
; - ±âÁ¸ Text6/Text7 ¹®±¸¸¦ »õ Text5/Text6À¸·Î ÀÚµ¿ ÀÌµ¿
; - ±âÁ¸ Text8¿¡ ÀÖ´ø ¹®±¸µµ ÇÊ¿äÇÑ °æ¿ì »õ Text6À¸·Î ÀÌµ¿
; =========================================================
QI_LoadTexts:
    if (QIIni = "")
        Gosub, QI_Init

    Gosub, QI_SetDefaults
    Gosub, QI_EnsureIni

    ; ÀÌ¹ÌÁö Á¤º¸µµ º°µµ INI¸¦ ¸¸µéÁö ¾Ê°í ±âÁ¸ ssok.ini¿¡¼­ À¯ÁöÇÕ´Ï´Ù.
    QI_LoadImageSettings()

    QIText1 := QIDefault1
    QIText2 := QIDefault2
    QIText3 := QIDefault3
    QIText4 := QIDefault4
    QIText5 := QIDefault5
    QIText6 := QIDefault6
    QIText7 := QIDefault7
    QIText10 := QIDefault10
    QIText11 := QIDefault11
    QIText12 := QIDefault12

    QIOldText1 := ""
    QIOldText2 := ""
    QIOldText3 := ""
    QIOldText4 := ""
    QIOldText5 := ""
    QIOldText6 := ""
    QIOldText7 := ""
    QIOldText8 := ""
    QIOldText10 := ""
    QIOldText11 := ""
    QIOldText12 := ""

    QIHas1 := 0
    QIHas2 := 0
    QIHas3 := 0
    QIHas4 := 0
    QIHas5 := 0
    QIHas6 := 0
    QIHas7 := 0
    QIHas8 := 0
    QIHas10 := 0
    QIHas11 := 0
    QIHas12 := 0

    QIRawText := ""
    FileRead, QIRawText, %QIIni%

    if ErrorLevel
    {
        MsgBox, 48, ½î¿Á ÀÐ±â ¿À·ù, ssok.ini ÆÄÀÏÀ» ÀÐÀ» ¼ö ¾ø½À´Ï´Ù.`n`nÀ§Ä¡:`n%QIIni%
        return
    }

    Loop, Parse, QIRawText, `n, `r
    {
        QILine := A_LoopField
        QILine := StrReplace(QILine, Chr(0xFEFF), "")

        if (SubStr(QILine, 1, 6) = "Text1=")
        {
            QIOldText1 := QI_DecodeText(SubStr(QILine, 7))
            QIHas1 := 1
        }
        else if (SubStr(QILine, 1, 6) = "Text2=")
        {
            QIOldText2 := QI_DecodeText(SubStr(QILine, 7))
            QIHas2 := 1
        }
        else if (SubStr(QILine, 1, 6) = "Text3=")
        {
            QIOldText3 := QI_DecodeText(SubStr(QILine, 7))
            QIHas3 := 1
        }
        else if (SubStr(QILine, 1, 6) = "Text4=")
        {
            QIOldText4 := QI_DecodeText(SubStr(QILine, 7))
            QIHas4 := 1
        }
        else if (SubStr(QILine, 1, 6) = "Text5=")
        {
            QIOldText5 := QI_DecodeText(SubStr(QILine, 7))
            QIHas5 := 1
        }
        else if (SubStr(QILine, 1, 6) = "Text6=")
        {
            QIOldText6 := QI_DecodeText(SubStr(QILine, 7))
            QIHas6 := 1
        }
        else if (SubStr(QILine, 1, 6) = "Text7=")
        {
            QIOldText7 := QI_DecodeText(SubStr(QILine, 7))
            QIHas7 := 1
        }
        else if (SubStr(QILine, 1, 6) = "Text8=")
        {
            QIOldText8 := QI_DecodeText(SubStr(QILine, 7))
            QIHas8 := 1
        }
        else if (SubStr(QILine, 1, 7) = "Text10=")
        {
            QIOldText10 := QI_DecodeText(SubStr(QILine, 8))
            QIHas10 := 1
        }
        else if (SubStr(QILine, 1, 7) = "Text11=")
        {
            QIOldText11 := QI_DecodeText(SubStr(QILine, 8))
            QIHas11 := 1
        }
        else if (SubStr(QILine, 1, 7) = "Text12=")
        {
            QIOldText12 := QI_DecodeText(SubStr(QILine, 8))
            QIHas12 := 1
        }
    }

    if (QIHas1)
        QIText1 := QIOldText1
    if (QIHas2)
        QIText2 := QIOldText2
    if (QIHas3)
        QIText3 := QIOldText3
    if (QIHas4)
        QIText4 := QIOldText4

    ; -----------------------------------------------------
    ; ±¸Á¶ ÀÚµ¿ º¸Á¤
    ; ÀÌÀü ±¸Á¶: 5¹ø ºóÄ­ / 6¹ø °¨»ç¹®±¸1 / 7¹ø °¨»ç¹®±¸2 / 8¹ø ¿À´Ã ³¯Â¥
    ; »õ ±¸Á¶  : 5¹ø °¨»ç¹®±¸1 / 6¹ø °¨»ç¹®±¸2 / 7¹ø Á÷Á¢ÀÔ·Â / 8¹ø ³¯Â¥Ã³¸® / 9¹ø Æ¯¼ö¹®ÀÚ
    ; -----------------------------------------------------
    if (QIHas5 && QIOldText5 != "")
    {
        ; »ç¿ëÀÚ°¡ ÀÌ¹Ì 5¹ø¿¡ Á÷Á¢ ³ÖÀº °ªÀÌ ÀÖÀ¸¸é º¸Á¸
        QIText5 := QIOldText5

        if (QIHas6 && QIOldText6 != "")
            QIText6 := QIOldText6
        else if (QIHas7 && QIOldText7 != "")
            QIText6 := QIOldText7
        else if (QIHas8 && QIOldText8 != "")
            QIText6 := QIOldText8
        else
            QIText6 := QIDefault6
    }
    else
    {
        ; 5¹øÀÌ ºñ¾î ÀÖÀ¸¸é ±âÁ¸ 6¹ø/7¹øÀ» 5¹ø/6¹øÀ¸·Î ´ç±è
        if (QIHas6 && QIOldText6 != "")
            QIText5 := QIOldText6
        else if (QIHas7 && QIOldText7 != "")
            QIText5 := QIOldText7
        else
            QIText5 := QIDefault5

        if (QIHas7 && QIOldText7 != "")
            QIText6 := QIOldText7
        else if (QIHas8 && QIOldText8 != "")
            QIText6 := QIOldText8
        else if (QIHas6 && QIOldText6 != "" && QIOldText6 != QIText5)
            QIText6 := QIOldText6
        else
            QIText6 := QIDefault6
    }

    if (QIHas7 && QIOldText7 != "")
        QIText7 := QIOldText7
    if (QIHas10)
        QIText10 := QIOldText10
    if (QIHas11)
        QIText11 := QIOldText11
    if (QIHas12)
        QIText12 := QIOldText12

    ; º¸Á¤µÈ ±¸Á¶¸¦ ssok.ini¿¡ ´Ù½Ã ÀúÀå
    Gosub, QI_WriteIniFile
return


; =========================================================
; ssok.ini Á÷Á¢ ÀúÀå
; - ¿©·¯ ÁÙÀº %0D%0A ÇüÅÂ·Î ÀúÀå
; - ´Ù½Ã ºÒ·¯¿Ã ¶§ ¿ø·¡ ÁÙ¹Ù²ÞÀ¸·Î º¹¿ø
; - 1~7¹ø°ú 10~12¹ø ¹®±¸´Â ÀúÀå, 8¹ø ³¯Â¥Ã³¸®, 9¹ø Æ¯¼ö¹®ÀÚ´Â ÀÚµ¿ ±â´É
; =========================================================
QI_WriteIniFile:
    if (QIIni = "")
        Gosub, QI_Init

    ; QI ÀúÀå ½Ã¿¡µµ F5QuickFiles ¼½¼ÇÀ» Áö¿ìÁö ¾Êµµ·Ï ÅëÇÕ ÀúÀåÇÕ´Ï´Ù.
    ; ±âÁ¸ ssok.iniÀÇ F5 ÇÑ±Û Å°¿öµå°¡ ±úÁ® ÀÖÀ¸¸é ±âº» Å°¿öµå·Î ÀÚµ¿ º¹±¸µË´Ï´Ù.
    if FileExist(QIIni)
        Gosub, SSOK_QF_LoadKeywords
    else
        Gosub, SSOK_QF_SetDefaults

    SSOK_SaveUnifiedIni()
return


; =========================================================
; 1~12¹ø ºü¸¥ ÀÔ·Â µµ¿ì¹Ì GUI
; =========================================================
QI_ShowGui:
    Gui, QIQuick:Destroy
    Gui, QIQuick:+AlwaysOnTop +ToolWindow
    Gui, QIQuick:Color, F7FBFF
    Gui, QIQuick:Font, s9, Malgun Gothic

    ; ¼ýÀÚÅ° ¼±ÅÃÀ» ¹Þ±â À§ÇÑ ÃÊÁ¡¿ë ¼ûÀº ¹öÆ°
    Gui, QIQuick:Add, Button, x930 y690 w1 h1 vQIFocusDummy gQI_DoNothing, .

    ; »ó´Ü Å¸ÀÌÆ²
    Gui, QIQuick:Font, s17 bold, Malgun Gothic
    Gui, QIQuick:Add, Text, x15 y12 w930 h34 c005BAC Center, ½î¿Á Å¬¸³º¸µå for K-¿¡µàÆÄÀÎ
    Gui, QIQuick:Font, s10 norm, Malgun Gothic

    ; 1¹ø
    Gui, QIQuick:Add, Text, x20 y55 w25 h24, 1.
    Gui, QIQuick:Add, Edit, x50 y50 w780 h45 vQIEdit1 +Multi +WantReturn, %QIText1%
    Gui, QIQuick:Add, Button, x840 y58 w95 h28 gQI_Input1, ÀúÀå && ÀÔ·Â

    ; 2¹ø
    Gui, QIQuick:Add, Text, x20 y110 w25 h24, 2.
    Gui, QIQuick:Add, Edit, x50 y105 w780 h45 vQIEdit2 +Multi +WantReturn, %QIText2%
    Gui, QIQuick:Add, Button, x840 y113 w95 h28 gQI_Input2, ÀúÀå && ÀÔ·Â

    ; 3¹ø
    Gui, QIQuick:Add, Text, x20 y165 w25 h24, 3.
    Gui, QIQuick:Add, Edit, x50 y160 w780 h45 vQIEdit3 +Multi +WantReturn, %QIText3%
    Gui, QIQuick:Add, Button, x840 y168 w95 h28 gQI_Input3, ÀúÀå && ÀÔ·Â

    ; 4¹ø
    Gui, QIQuick:Add, Text, x20 y220 w25 h24, 4.
    Gui, QIQuick:Add, Edit, x50 y215 w780 h45 vQIEdit4 +Multi +WantReturn, %QIText4%
    Gui, QIQuick:Add, Button, x840 y223 w95 h28 gQI_Input4, ÀúÀå && ÀÔ·Â

    ; 5¹ø
    Gui, QIQuick:Add, Text, x20 y275 w25 h24, 5.
    Gui, QIQuick:Add, Edit, x50 y270 w780 h45 vQIEdit5 +Multi +WantReturn, %QIText5%
    Gui, QIQuick:Add, Button, x840 y278 w95 h28 gQI_Input5, ÀúÀå && ÀÔ·Â

    ; 6¹ø
    Gui, QIQuick:Add, Text, x20 y330 w25 h24, 6.
    Gui, QIQuick:Add, Edit, x50 y325 w780 h45 vQIEdit6 +Multi +WantReturn, %QIText6%
    Gui, QIQuick:Add, Button, x840 y333 w95 h28 gQI_Input6, ÀúÀå && ÀÔ·Â

    ; 7¹ø
    Gui, QIQuick:Add, Text, x20 y385 w25 h24, 7.
    Gui, QIQuick:Add, Edit, x50 y380 w780 h45 vQIEdit7 +Multi +WantReturn, %QIText7%
    Gui, QIQuick:Add, Button, x840 y388 w95 h28 gQI_Input7, ÀúÀå && ÀÔ·Â

    ; 8¹ø ³¯Â¥ Ã³¸®
    Gui, QIQuick:Add, Text, x20 y440 w25 h24 c003366, 8.
    Gui, QIQuick:Add, Text, x50 y445 w780 h22 c003366, [¿À´Ã ³¯Â¥(¿äÀÏ) ÇöÀç ½Ã°£] ÀÔ·Â ¶Ç´Â [¼±ÅÃ ¹üÀ§ ³¯Â¥(¿äÀÏ)] ±³Á¤
    Gui, QIQuick:Add, Button, x840 y438 w95 h28 gQI_Input8, ÀúÀå && ½ÇÇà

    ; 9¹ø Æ¯¼ö¹®ÀÚ
    Gui, QIQuick:Add, Text, x20 y490 w25 h24 c003366, 9.
    Gui, QIQuick:Add, Text, x50 y495 w780 h22 c003366, Æ¯¼ö¹®ÀÚ ÀÚµ¿ÀÔ·Â: ¡¸¹ý¡¹¡¼±Ù°Å¡½¡² ¡³¡¶ ¡·¡º¡»?¡î¡Ý¨¬?¡¤???¡Û¡Û¡à¡à¡Þ¡â¡ä¢¹¡á¡á¡Ü¡ß¢º¡ã¡å
    Gui, QIQuick:Add, Button, x840 y488 w95 h28 gQI_Input9, ÀúÀå && ÀÔ·Â

    ; 10¹ø
    Gui, QIQuick:Add, Text, x20 y540 w25 h24, 10.
    Gui, QIQuick:Add, Edit, x50 y535 w780 h45 vQIEdit10 +Multi +WantReturn, %QIText10%
    Gui, QIQuick:Add, Button, x840 y543 w95 h28 gQI_Input10, ÀúÀå && ½ÇÇà

    ; 11¹ø
    Gui, QIQuick:Add, Text, x20 y595 w25 h24, 11.
    Gui, QIQuick:Add, Edit, x50 y590 w780 h45 vQIEdit11 +Multi +WantReturn, %QIText11%
    Gui, QIQuick:Add, Button, x840 y598 w95 h28 gQI_Input11, ÀúÀå && ½ÇÇà

    ; 12~15¹ø ÀÌ¹ÌÁö Àü¿ë
    ; ¼±ÅÃ: ·ÎÄÃ ÀÌ¹ÌÁö ÆÄÀÏ ¼³Á¤
    ; URL: ÀÌ¹ÌÁö URL ¼³Á¤
    ; ¼³Á¤µÈ ÀÌ¹ÌÁö¸¦ Å¬¸¯ÇÏ¸é ¹Ù·Î ºÙ¿©³Ö½À´Ï´Ù.
    Gui, QIQuick:Font, s9 bold, Malgun Gothic

    QIImage12Preview := QI_GetImagePreviewPath(QIImage12, 12)
    QIImage13Preview := QI_GetImagePreviewPath(QIImage13, 13)
    QIImage14Preview := QI_GetImagePreviewPath(QIImage14, 14)
    QIImage15Preview := QI_GetImagePreviewPath(QIImage15, 15)

    ; 12¹ø
    Gui, QIQuick:Add, Text, x20 y650 w25 h24, 12.
    Gui, QIQuick:Add, Button, x50 y648 w55 h24 gQI_SelectImage12, ¼±ÅÃ
    Gui, QIQuick:Add, Button, x110 y648 w55 h24 gQI_SetImageURL12, URL
    if (QIImage12Preview != "")
        Gui, QIQuick:Add, Picture, x20 y678 w210 h75 vQIImage12Ctrl gQI_PasteImage12 +Border, %QIImage12Preview%
    else
        Gui, QIQuick:Add, Text, x20 y678 w210 h75 vQIImage12Ctrl +Border Center 0x200 gQI_SelectImage12, ÀÌ¹ÌÁö ¾øÀ½

    ; 13¹ø
    Gui, QIQuick:Add, Text, x255 y650 w25 h24, 13.
    Gui, QIQuick:Add, Button, x285 y648 w55 h24 gQI_SelectImage13, ¼±ÅÃ
    Gui, QIQuick:Add, Button, x345 y648 w55 h24 gQI_SetImageURL13, URL
    if (QIImage13Preview != "")
        Gui, QIQuick:Add, Picture, x255 y678 w210 h75 vQIImage13Ctrl gQI_PasteImage13 +Border, %QIImage13Preview%
    else
        Gui, QIQuick:Add, Text, x255 y678 w210 h75 vQIImage13Ctrl +Border Center 0x200 gQI_SelectImage13, ÀÌ¹ÌÁö ¾øÀ½

    ; 14¹ø
    Gui, QIQuick:Add, Text, x490 y650 w25 h24, 14.
    Gui, QIQuick:Add, Button, x520 y648 w55 h24 gQI_SelectImage14, ¼±ÅÃ
    Gui, QIQuick:Add, Button, x580 y648 w55 h24 gQI_SetImageURL14, URL
    if (QIImage14Preview != "")
        Gui, QIQuick:Add, Picture, x490 y678 w210 h75 vQIImage14Ctrl gQI_PasteImage14 +Border, %QIImage14Preview%
    else
        Gui, QIQuick:Add, Text, x490 y678 w210 h75 vQIImage14Ctrl +Border Center 0x200 gQI_SelectImage14, ÀÌ¹ÌÁö ¾øÀ½

    ; 15¹ø
    Gui, QIQuick:Add, Text, x725 y650 w25 h24, 15.
    Gui, QIQuick:Add, Button, x755 y648 w55 h24 gQI_SelectImage15, ¼±ÅÃ
    Gui, QIQuick:Add, Button, x815 y648 w55 h24 gQI_SetImageURL15, URL
    if (QIImage15Preview != "")
        Gui, QIQuick:Add, Picture, x725 y678 w210 h75 vQIImage15Ctrl gQI_PasteImage15 +Border, %QIImage15Preview%
    else
        Gui, QIQuick:Add, Text, x725 y678 w210 h75 vQIImage15Ctrl +Border Center 0x200 gQI_SelectImage15, ÀÌ¹ÌÁö ¾øÀ½

    Gui, QIQuick:Add, Text, x15 y770 w430 h20 c999999, ÀúÀåÆÄÀÏ: %QIIni%
    Gui, QIQuick:Add, Text, x490 y770 w450 h20 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£

    SSOK_GetSidebarAttachedGuiPos(960, 805, QIQuickX, QIQuickY)
    Gui, QIQuick:Show, x%QIQuickX% y%QIQuickY% w960 h805, ½î¿Á ºü¸¥ ÀÔ·Â µµ¿ì¹Ì

    ; Ã³À½ Ã¢ÀÌ ¿­¸®¸é ÀÔ·ÂÄ­ÀÌ ¾Æ´Ï¶ó ÃÊÁ¡¿ë ¹öÆ°¿¡ Æ÷Ä¿½º
    GuiControl, QIQuick:Focus, QIFocusDummy

    ; URL ¹Ì¸®º¸±â´Â Ã¢À» ¸ÕÀú ¶ç¿î ÈÄ ºñµ¿±â·Î ·ÎµåÇÕ´Ï´Ù.
    Gosub, QI_StartPreviewLoad
return


; =========================================================
; ¾Æ¹« µ¿ÀÛ ¾È ÇÏ´Â ÃÊÁ¡¿ë ¹öÆ°
; =========================================================
QI_StartPreviewLoad:
    ; GUI¸¦ ¸ÕÀú ¶ç¿î µÚ URL ÀÌ¹ÌÁö´Â º°µµ Å¸ÀÌ¸Ó¿¡¼­ Ã³¸®ÇÕ´Ï´Ù.
    SetTimer, QI_LoadUrlPreviews, -20
return


QI_LoadUrlPreviews:
    ; URL ¹Ì¸®º¸±â´Â ÇÑ ¹ø¿¡ ÇÏ³ª¾¿ Ã³¸®ÇÏ¿© GUI ÀÀ´ä¼ºÀ» À¯ÁöÇÕ´Ï´Ù.
    QI_LoadOneUrlPreview(12)
    QI_LoadOneUrlPreview(13)
    QI_LoadOneUrlPreview(14)
    QI_LoadOneUrlPreview(15)
return


QI_LoadOneUrlPreview(slot)
{
    global QIImage12, QIImage13, QIImage14, QIImage15

    imageValue := QI_GetImageValue(slot)
    if (!RegExMatch(imageValue, "i)^https?://"))
        return

    cachePath := QI_GetPreviewCachePath(imageValue, slot)
    if (!FileExist(cachePath))
    {
        ext := QI_GetImageUrlExtension(imageValue)
        if (ext = "")
            ext := "img"

        rawPath := A_Temp . "\SSOK_QI_URLPREV_" . slot . "_" . A_TickCount . "." . ext
        FileDelete, %rawPath%
        UrlDownloadToFile, %imageValue%, %rawPath%

        if ErrorLevel || !FileExist(rawPath)
            return

        if (ext = "png")
        {
            if (!QI_ConvertPngToWhiteBackground(rawPath, cachePath))
            {
                FileDelete, %rawPath%
                return
            }
        }
        else if (ext = "webp" || ext = "svg")
        {
            if (!QI_ConvertWebImageToPng(rawPath, cachePath))
            {
                FileDelete, %rawPath%
                return
            }
        }
        else
        {
            ; JPG/GIF/BMPµµ Èò ¹è°æ Ã³¸® ¹× Ç¥ÁØ PNG º¯È¯
            if (!QI_ConvertPngLikeToWhiteBackground(rawPath, cachePath))
            {
                FileDelete, %rawPath%
                return
            }
        }

        FileDelete, %rawPath%
    }

    if !FileExist(cachePath)
        return

    x := 20
    if (slot = 13)
        x := 255
    else if (slot = 14)
        x := 490
    else if (slot = 15)
        x := 725

    Gui, QIQuick:Add, Picture, x%x% y678 w210 h75 gQI_PasteImage%slot% +Border, %cachePath%
}


QI_DoNothing:
return


; =========================================================
; GUI ÀÔ·ÂÄ­ ³»¿ëÀ» º¯¼ö¿¡ ´ã°í ssok.ini¿¡ ÀúÀå
; 1~7¹ø°ú 10~12¹ø¸¸ ÀúÀå, 8¹ø/9¹øÀº ÀÚµ¿ ±â´É
; =========================================================
QI_SaveFromGui:
    if (QIIni = "")
        Gosub, QI_Init

    Gui, QIQuick:Submit, NoHide

    QIText1 := QIEdit1
    QIText2 := QIEdit2
    QIText3 := QIEdit3
    QIText4 := QIEdit4
    QIText5 := QIEdit5
    QIText6 := QIEdit6
    QIText7 := QIEdit7
    QIText10 := QIEdit10
    QIText11 := QIEdit11
    QIText12 := QIEdit12

    Gosub, QI_WriteIniFile
return


; =========================================================
; ¼±ÅÃÃ¢ÀÌ ¶° ÀÖÀ» ¶§ ¼ýÀÚÅ° 1~9·Î ÀÔ·Â
; ´Ü, ¹®±¸ ¼öÁ¤Ä­ ¾È¿¡¼­´Â ¼ýÀÚ¸¦ ±×´ë·Î ÀÔ·Â
; =========================================================
#IfWinActive, ½î¿Á ºü¸¥ ÀÔ·Â µµ¿ì¹Ì

$1::
    QINumber := "1"
    Gosub, QI_NumberPressed
return

$2::
    QINumber := "2"
    Gosub, QI_NumberPressed
return

$3::
    QINumber := "3"
    Gosub, QI_NumberPressed
return

$4::
    QINumber := "4"
    Gosub, QI_NumberPressed
return

$5::
    QINumber := "5"
    Gosub, QI_NumberPressed
return

$6::
    QINumber := "6"
    Gosub, QI_NumberPressed
return

$7::
    QINumber := "7"
    Gosub, QI_NumberPressed
return

$8::
    QINumber := "8"
    Gosub, QI_NumberPressed
return

$9::
    QINumber := "9"
    Gosub, QI_NumberPressed
return

$Numpad1::
    QINumber := "1"
    Gosub, QI_NumberPressed
return

$Numpad2::
    QINumber := "2"
    Gosub, QI_NumberPressed
return

$Numpad3::
    QINumber := "3"
    Gosub, QI_NumberPressed
return

$Numpad4::
    QINumber := "4"
    Gosub, QI_NumberPressed
return

$Numpad5::
    QINumber := "5"
    Gosub, QI_NumberPressed
return

$Numpad6::
    QINumber := "6"
    Gosub, QI_NumberPressed
return

$Numpad7::
    QINumber := "7"
    Gosub, QI_NumberPressed
return

$Numpad8::
    QINumber := "8"
    Gosub, QI_NumberPressed
return

$Numpad9::
    QINumber := "9"
    Gosub, QI_NumberPressed
return

#IfWinActive


; =========================================================
; ¼ýÀÚÅ°¸¦ ´­·¶À» ¶§ Ã³¸®
; =========================================================
QI_NumberPressed:
    ControlGetFocus, QIFocusedControl, A

    ; ÀÔ·ÂÄ­À» Á÷Á¢ ¼öÁ¤ ÁßÀÌ¸é ¼ýÀÚ´Â ±×´ë·Î ÀÔ·Â
    if RegExMatch(QIFocusedControl, "^Edit")
    {
        SendInput, %QINumber%
        return
    }

    if (QINumber = "1")
        Gosub, QI_Input1
    else if (QINumber = "2")
        Gosub, QI_Input2
    else if (QINumber = "3")
        Gosub, QI_Input3
    else if (QINumber = "4")
        Gosub, QI_Input4
    else if (QINumber = "5")
        Gosub, QI_Input5
    else if (QINumber = "6")
        Gosub, QI_Input6
    else if (QINumber = "7")
        Gosub, QI_Input7
    else if (QINumber = "8")
        Gosub, QI_Input8
    else if (QINumber = "9")
        Gosub, QI_Input9
return


; =========================================================
; 1~7¹ø, 10~12¹ø ÀúÀå && ÀÔ·Â
; =========================================================
QI_Input1:
    Gosub, QI_SaveFromGui
    QIInputText := QIText1
    Gosub, QI_PasteText
return

QI_Input2:
    Gosub, QI_SaveFromGui
    QIInputText := QIText2
    Gosub, QI_PasteText
return

QI_Input3:
    Gosub, QI_SaveFromGui
    QIInputText := QIText3
    Gosub, QI_PasteText
return

QI_Input4:
    Gosub, QI_SaveFromGui
    QIInputText := QIText4
    Gosub, QI_PasteText
return

QI_Input5:
    Gosub, QI_SaveFromGui
    QIInputText := QIText5
    Gosub, QI_PasteText
return

QI_Input6:
    Gosub, QI_SaveFromGui
    QIInputText := QIText6
    Gosub, QI_PasteText
return


; =========================================================
; 7¹ø ÀúÀå && ÀÔ·Â
; =========================================================
QI_Input7:
    Gosub, QI_SaveFromGui
    QIInputText := QIText7
    Gosub, QI_PasteText
return

QI_Input10:
    Gosub, QI_SaveFromGui
    QIInputText := QIText10
    Gosub, QI_PasteText
return

QI_Input11:
    Gosub, QI_SaveFromGui
    QIInputText := QIText11
    Gosub, QI_PasteText
return

QI_Input12:
    ; ±âÁ¸ 12¹ø ¹®±¸ ÀÔ·Â ·çÆ¾Àº »õ 12¹ø ÀÌ¹ÌÁö ±â´ÉÀ¸·Î ´ëÃ¼µÇ¾ú½À´Ï´Ù.
    Gosub, QI_SelectImage12
return


; =========================================================
; 12~14¹ø ÀÌ¹ÌÁö ÀúÀå/ºÙ¿©³Ö±â
; - ¼³Á¤: ÀÌ¹ÌÁö ÆÄÀÏ ¶Ç´Â ÀÌ¹ÌÁö URLÀ» ¼±ÅÃ/ÀÔ·Â
; - ¿øº» ÆÄÀÏÀº º¹»çÇÏÁö ¾Ê°í ÆÄÀÏ °æ·Î ¶Ç´Â URL¸¸ ±âÁ¸ ssok.ini¿¡ ÀúÀå
; - URL ¹Ì¸®º¸±â/ºÙ¿©³Ö±â´Â ÀÓ½ÃÆÄÀÏ¸¸ »ç¿ëÇÏ°í ÀÛ¾÷ ÈÄ »èÁ¦
; =========================================================
QI_SelectImage12:
    QI_SelectImageSlot(12)
return

QI_SelectImage13:
    QI_SelectImageSlot(13)
return

QI_SelectImage14:
    QI_SelectImageSlot(14)
return

QI_SelectImage15:
    QI_SelectImageSlot(15)
return

QI_SelectImageSlot(slot)
{
    global QIImage12, QIImage13, QIImage14, QIImage15, QIImageIni, QIIni

    ; Win+F1 Ã¢Àº Ç×»ó À§¿¡ ÀÖÀ¸¹Ç·Î ÆÄÀÏ ¼±ÅÃÃ¢À» °¡¸± ¼ö ÀÖ½À´Ï´Ù.
    ; ¼±ÅÃÇÏ´Â µ¿¾È¸¸ QIQuickÀ» ¼û°Ü ½Ã½ºÅÛ ÆÄÀÏ ¼±ÅÃÃ¢ÀÌ È®½ÇÈ÷ ¾Õ¿¡ ³ª¿À°Ô ÇÕ´Ï´Ù.
    Gui, QIQuick:Hide
    FileSelectFile, QISelectedImage, 3,, ÀÌ¹ÌÁö ¼±ÅÃ, ÀÌ¹ÌÁö ÆÄÀÏ (*.png;*.jpg;*.jpeg;*.bmp;*.gif;*.tif;*.tiff)

    if ErrorLevel
    {
        Gosub, QI_ShowGui
        return
    }

    if (slot = 12)
        QIImage12 := QISelectedImage
    else if (slot = 13)
        QIImage13 := QISelectedImage
    else if (slot = 14)
        QIImage14 := QISelectedImage
    else
        QIImage15 := QISelectedImage

    QIImageIni := QIIni
    QI_SaveImageSettings()
    Gosub, QI_ShowGui
}

QI_SetImageURL12:
    QI_SetImageURLSlot(12)
return

QI_SetImageURL13:
    QI_SetImageURLSlot(13)
return

QI_SetImageURL14:
    QI_SetImageURLSlot(14)
return

QI_SetImageURL15:
    QI_SetImageURLSlot(15)
return

QI_SetImageURLSlot(slot)
{
    global QIImage12, QIImage13, QIImage14, QIImage15, QIImageIni, QIIni

    currentValue := QI_GetImageValue(slot)

    ; Win+F1 Ã¢Àº Ç×»ó À§¿¡ ÀÖÀ¸¹Ç·Î URL ÀÔ·ÂÃ¢À» °¡¸± ¼ö ÀÖ½À´Ï´Ù.
    ; ÀÔ·ÂÇÏ´Â µ¿¾È¸¸ QIQuickÀ» ¼û°Ü URL ÀÔ·ÂÃ¢ÀÌ È®½ÇÈ÷ ¾Õ¿¡ ³ª¿À°Ô ÇÕ´Ï´Ù.
    Gui, QIQuick:Hide
    InputBox, QIImageURL, ÀÌ¹ÌÁö URL ¼³Á¤, Á÷Á¢ ÀÌ¹ÌÁö URLÀ» ÀÔ·ÂÇÏ¼¼¿ä.`n¿¹: https://example.com/image.png,,,,,,,,%currentValue%

    if ErrorLevel
    {
        Gosub, QI_ShowGui
        return
    }

    imageValue := Trim(QIImageURL)
    if (imageValue = "")
    {
        Gosub, QI_ShowGui
        return
    }

    if !RegExMatch(imageValue, "i)^https?://")
    {
        MsgBox, 48, ÀÌ¹ÌÁö URL, http:// ¶Ç´Â https:// ·Î ½ÃÀÛÇÏ´Â ÀÌ¹ÌÁö URLÀ» ÀÔ·ÂÇÏ¼¼¿ä.
        Gosub, QI_ShowGui
        return
    }

    if (slot = 12)
        QIImage12 := imageValue
    else if (slot = 13)
        QIImage13 := imageValue
    else if (slot = 14)
        QIImage14 := imageValue
    else
        QIImage15 := imageValue

    QIImageIni := QIIni
    QI_SaveImageSettings()
    Gosub, QI_ShowGui
}


QI_LoadImageSettings()
{
    global QIIni, QIImage12, QIImage13, QIImage14, QIImage15, QIImageIni, QI_DefaultImage12, QI_DefaultImage13, QI_DefaultImage14, QI_DefaultImage15

    if (QIIni = "")
        return

    QIImageIni := QIIni
    IniRead, loaded12, %QIIni%, QuickImages, Image12,
    IniRead, loaded13, %QIIni%, QuickImages, Image13,
    IniRead, loaded14, %QIIni%, QuickImages, Image14
    IniRead, loaded15, %QIIni%, QuickImages, Image15

    if (loaded12 = "ERROR")
        loaded12 := ""
    if (loaded13 = "ERROR")
        loaded13 := ""
    if (loaded14 = "ERROR")
        loaded14 := ""
    if (loaded15 = "ERROR")
        loaded15 := ""

    ; INI °ªÀÌ ¾øÀ» ¶§¸¸ AHK¿¡ ³»ÀåµÈ ±âº» ¸µÅ©¸¦ »ç¿ëÇÕ´Ï´Ù.
    if (loaded12 = "")
        loaded12 := QI_DefaultImage12
    if (loaded13 = "")
        loaded13 := QI_DefaultImage13
    if (loaded14 = "")
        loaded14 := QI_DefaultImage14
    if (loaded15 = "")
        loaded15 := QI_DefaultImage15

    QIImage12 := loaded12
    QIImage13 := loaded13
    QIImage14 := loaded14
    QIImage15 := loaded15
}


QI_SaveImageSettings()
{
    global QIIni, QIImage12, QIImage13, QIImage14, QIImage15

    if (QIIni = "")
        return

    ; ÀÌ¹ÌÁö ÆÄÀÏ ÀÚÃ¼´Â ÀúÀåÇÏÁö ¾Ê°í °æ·Î/URL ¹®ÀÚ¿­¸¸ ÀúÀåÇÕ´Ï´Ù.
    IniWrite, % QIImage12, %QIIni%, QuickImages, Image12
    IniWrite, % QIImage13, %QIIni%, QuickImages, Image13
    IniWrite, % QIImage14, %QIIni%, QuickImages, Image14
    IniWrite, % QIImage15, %QIIni%, QuickImages, Image15
}


QI_GetImageValue(slot)
{
    global QIImage12, QIImage13, QIImage14, QIImage15

    if (slot = 12)
        return QIImage12
    else if (slot = 13)
        return QIImage13
    else if (slot = 14)
        return QIImage14
    return QIImage15
}


QI_PasteImage12:
    QI_PasteImageSlot(12)
return

QI_PasteImage13:
    QI_PasteImageSlot(13)
return

QI_PasteImage14:
    QI_PasteImageSlot(14)
return

QI_PasteImage15:
    QI_PasteImageSlot(15)
return

QI_PasteImageSlot(slot)
{
    global QIImage12, QIImage13, QIImage14, QIImage15, QILastTargetHwnd

    imageValue := QI_GetImageValue(slot)
    if (imageValue = "")
    {
        QI_SelectImageSlot(slot)
        return
    }

    tempImage := ""
    if (RegExMatch(imageValue, "i)^https?://"))
    {
        ; URL ¿øº» È®ÀåÀÚ¸¦ º¸Á¸ÇÑ µÚ WebP/SVG´Â PNG·Î º¯È¯ÇÕ´Ï´Ù.
        ext := QI_GetImageUrlExtension(imageValue)
        if (ext = "")
            ext := "img"

        tempRaw := A_Temp . "\SSOK_QI_URL_" . slot . "_" . A_TickCount . "." . ext
        FileDelete, %tempRaw%
        UrlDownloadToFile, %imageValue%, %tempRaw%
        if ErrorLevel || !FileExist(tempRaw)
        {
            ToolTip, ÀÌ¹ÌÁö URLÀ» ºÒ·¯¿ÀÁö ¸øÇß½À´Ï´Ù.
            SetTimer, QI_RemoveToolTip, -1800
            return
        }

        tempImage := tempRaw
        if (ext = "png")
        {
            tempImage := A_Temp . "\SSOK_QI_URL_" . slot . "_" . A_TickCount . "_converted.png"
            FileDelete, %tempImage%
            if (!QI_ConvertPngToWhiteBackground(tempRaw, tempImage))
            {
                FileDelete, %tempRaw%
                ToolTip, PNG ÀÌ¹ÌÁö¸¦ º¯È¯ÇÏÁö ¸øÇß½À´Ï´Ù.
                SetTimer, QI_RemoveToolTip, -1800
                return
            }
        }
        else if (ext = "webp" || ext = "svg" || ext = "jpg" || ext = "gif" || ext = "bmp")
        {
            tempImage := A_Temp . "\SSOK_QI_URL_" . slot . "_" . A_TickCount . "_converted.png"
            FileDelete, %tempImage%
            if (!QI_ConvertWebImageToPng(tempRaw, tempImage))
            {
                FileDelete, %tempRaw%
                ToolTip, ÀÌ¹ÌÁö º¯È¯¿¡ ½ÇÆÐÇß½À´Ï´Ù.
                SetTimer, QI_RemoveToolTip, -1800
                return
            }
        }
        pastePath := tempImage
    }
    else
    {
        if !FileExist(imageValue)
        {
            QI_SelectImageSlot(slot)
            return
        }
        pastePath := imageValue
    }

    ; ´ë»ó Ã¢À» ±â¾ïÇÑ µÚ ºü¸¥ ÀÔ·Â Ã¢À» ´Ý½À´Ï´Ù.
    targetHwnd := QILastTargetHwnd
    Gui, QIQuick:Destroy

    if (targetHwnd != "")
    {
        WinActivate, ahk_id %targetHwnd%
        WinWaitActive, ahk_id %targetHwnd%,, 1.5
        Sleep, 200
    }

    if (!QI_SetClipboardImage(pastePath))
    {
        if (tempImage != "")
            FileDelete, %tempImage%
        if (tempRaw != "" && tempRaw != tempImage)
            FileDelete, %tempRaw%
        ToolTip, ÀÌ¹ÌÁö Å¬¸³º¸µå »ý¼º¿¡ ½ÇÆÐÇß½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1500
        return
    }

    Sleep, 120
    SendInput, ^v
    Sleep, 350

    if (tempImage != "")
        FileDelete, %tempImage%
}


QI_GetImagePreviewPath(imageValue, slot)
{
    if (imageValue = "")
        return ""

    ; ·ÎÄÃ ÆÄÀÏÀº Áï½Ã »ç¿ëÇÕ´Ï´Ù.
    if FileExist(imageValue)
    {
        if (QI_IsWebImageConvertRequired(imageValue))
            return ""
        return imageValue
    }

    ; URLÀº Ä³½Ã°¡ ÀÖÀ» ¶§¸¸ Áï½Ã Ç¥½ÃÇÕ´Ï´Ù.
    ; ÃÖÃÊ ´Ù¿î·Îµå´Â QI_StartPreviewLoad¿¡¼­ Ã¢À» ¶ç¿î ÈÄ Ã³¸®ÇÕ´Ï´Ù.
    if (RegExMatch(imageValue, "i)^https?://"))
    {
        cachePath := QI_GetPreviewCachePath(imageValue, slot)
        if FileExist(cachePath)
            return cachePath
    }

    return ""
}

QI_GetPreviewCachePath(imageValue, slot)
{
    ; URLº° ¹Ì¸®º¸±â Ä³½Ã ÆÄÀÏ °æ·Î¸¦ °è»êÇÕ´Ï´Ù.
    ; Win+F1À» ¶ç¿ï ¶§ ½ÇÁ¦ ´Ù¿î·Îµå´Â ÇÏÁö ¾Ê½À´Ï´Ù.
    hash := 0
    Loop, Parse, imageValue
    {
        hash := Mod((hash * 31) + Asc(A_LoopField), 2147483647)
    }
    return A_Temp . "\SSOK_QI_URLCACHE_" . slot . "_" . hash . ".png"
}


QI_GetImageUrlExtension(url)
{
    url := RegExReplace(url, "[?#].*$")
    SplitPath, url, , , ext
    ext := LTrim(ext, ".")
    StringLower, ext, ext

    if (ext = "jpeg")
        ext := "jpg"

    if (ext = "png" || ext = "jpg" || ext = "gif" || ext = "bmp" || ext = "webp" || ext = "svg")
        return ext

    return ""
}


QI_IsWebImageConvertRequired(path)
{
    SplitPath, path, , , ext
    StringLower, ext, ext
    return (ext = "webp" || ext = "svg")
}


QI_ConvertPngToWhiteBackground(sourcePath, outputPath)
{
    if (!FileExist(sourcePath))
        return false

    psPath := A_Temp . "\SSOK_QI_PngWhite_" . A_TickCount . ".ps1"
    src := StrReplace(sourcePath, "'", "''")
    dst := StrReplace(outputPath, "'", "''")

    ps =
    (
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
$src = '%src%'
$dst = '%dst%'
try {
    $fs = [System.IO.File]::OpenRead($src)
    $decoder = New-Object System.Windows.Media.Imaging.PngBitmapDecoder($fs, [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat, [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    $fs.Close()
    $bmp = $decoder.Frames[0]

    $w = $bmp.PixelWidth
    $h = $bmp.PixelHeight

    $canvas = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($w, $h, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $dv = New-Object System.Windows.Media.DrawingVisual
    $dc = $dv.RenderOpen()
    $dc.DrawRectangle([System.Windows.Media.Brushes]::White, $null, (New-Object System.Windows.Rect(0,0,$w,$h)))
    $dc.DrawImage($bmp, (New-Object System.Windows.Rect(0,0,$w,$h)))
    $dc.Close()
    $canvas.Render($dv)

    $out = New-Object System.IO.FileStream($dst, [System.IO.FileMode]::Create)
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($canvas))
    $enc.Save($out)
    $out.Close()
    exit 0
}
catch {
    exit 1
}
    )

    FileDelete, %psPath%
    FileAppend, %ps%, %psPath%, UTF-8
    RunWait, %ComSpec% /c powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%psPath%",, Hide UseErrorLevel
    exitCode := ErrorLevel
    FileDelete, %psPath%

    return (exitCode = 0 && FileExist(outputPath))
}


QI_ConvertPngLikeToWhiteBackground(sourcePath, outputPath)
{
    ; JPG/GIF/BMP´Â Edge·Î Ç¥ÁØ PNGÈ­ÇÏµÇ Èò»ö ¹è°æÀ» »ç¿ëÇÕ´Ï´Ù.
    return QI_ConvertWebImageToPng(sourcePath, outputPath)
}


QI_ConvertWebImageToPng(sourcePath, outputPath)
{
    if (!FileExist(sourcePath))
        return false

    edge := QI_FindEdge()
    if (edge = "")
        return false

    htmlPath := A_Temp . "\SSOK_QI_Render_" . A_TickCount . ".html"

    uri := "file:///" . StrReplace(sourcePath, "\", "/")
    uri := StrReplace(uri, " ", "%20")
    uri := StrReplace(uri, "#", "%23")
    uri := StrReplace(uri, "&", "%26")
    uri := StrReplace(uri, "'", "%27")

    ; Èò»ö ¹è°æÀ» ¸í½ÃÇÏ¿© PNGÀÇ Åõ¸í ¿µ¿ªÀÌ °Ë°Ô º¯ÇÏÁö ¾Êµµ·Ï ÇÕ´Ï´Ù.
    html =
    (
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
html,body{margin:0;padding:0;background:#fff;overflow:hidden;}
img{display:block;max-width:1200px;max-height:900px;width:auto;height:auto;}
</style>
</head>
<body><img src="%uri%"></body>
</html>
    )

    FileDelete, %htmlPath%
    FileAppend, %html%, %htmlPath%, UTF-8

    htmlUri := "file:///" . StrReplace(htmlPath, "\", "/")
    htmlUri := StrReplace(htmlUri, " ", "%20")

    FileDelete, %outputPath%

    cmd := """" . edge . """ --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --window-size=1200,900 --virtual-time-budget=300 --default-background-color=FFFFFFFF --screenshot=""" . outputPath . """ """ . htmlUri . """"
    RunWait, %cmd%,, Hide UseErrorLevel

    FileDelete, %htmlPath%

    if (ErrorLevel != 0 || !FileExist(outputPath))
        return false

    croppedPath := A_Temp . "\SSOK_QI_CROP_" . A_TickCount . ".png"
    FileDelete, %croppedPath%

    if (QI_CropPngToContent(outputPath, croppedPath))
    {
        FileMove, %croppedPath%, %outputPath%, 1
        return true
    }

    FileDelete, %croppedPath%
    return true
}


QI_CropPngToContent(sourcePath, outputPath)
{
    ; AHK continuation-section ¹®¹ý°ú Ãæµ¹ÇÏÁö ¾Êµµ·Ï PowerShellÀ» ÇÑ ÁÙ¾¿
    ; ¸íÈ®ÇÏ°Ô ±¸¼ºÇÕ´Ï´Ù. ½ÇÁ¦ ÀÌ¹ÌÁö ¿µ¿ª¸¸ Àß¶ó³À´Ï´Ù.
    psPath := A_Temp . "\SSOK_QI_Crop_" . A_TickCount . ".ps1"
    src := StrReplace(sourcePath, "'", "''")
    dst := StrReplace(outputPath, "'", "''")

    ps =
    (
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
$src = '%src%'
$dst = '%dst%'
try {
    $fs = [System.IO.File]::OpenRead($src)
    $decoder = New-Object System.Windows.Media.Imaging.PngBitmapDecoder($fs, [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat, [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    $fs.Close()
    $bmp = $decoder.Frames[0]
    $w = $bmp.PixelWidth
    $h = $bmp.PixelHeight
    $stride = $w * 4
    $bytes = New-Object byte[] ($stride * $h)
    $fmt = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
    $fmt.BeginInit()
    $fmt.Source = $bmp
    $fmt.DestinationFormat = [System.Windows.Media.PixelFormats]::Bgra32
    $fmt.EndInit()
    $fmt.Freeze()
    $fmt.CopyPixels($bytes, $stride, 0)
    $minX = $w
    $minY = $h
    $maxX = -1
    $maxY = -1
    for ($y = 0; $y -lt $h; $y++) {
        $row = $y * $stride
        for ($x = 0; $x -lt $w; $x++) {
            $p = $row + ($x * 4)
            $b = $bytes[$p]
            $g = $bytes[$p + 1]
            $r = $bytes[$p + 2]
            $a = $bytes[$p + 3]
            if ($a -gt 0 -and ($r -lt 248 -or $g -lt 248 -or $b -lt 248)) {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    if ($maxX -lt 0 -or $maxY -lt 0) { exit 2 }
    $minX = [Math]::Max(0, $minX - 1)
    $minY = [Math]::Max(0, $minY - 1)
    $maxX = [Math]::Min($w - 1, $maxX + 1)
    $maxY = [Math]::Min($h - 1, $maxY + 1)
    $cw = $maxX - $minX + 1
    $ch = $maxY - $minY + 1
    $rect = New-Object System.Windows.Int32Rect
    $rect.X = $minX
    $rect.Y = $minY
    $rect.Width = $cw
    $rect.Height = $ch
    $crop = New-Object System.Windows.Media.Imaging.CroppedBitmap -ArgumentList $bmp, $rect
    $crop.Freeze()
    $out = New-Object System.IO.FileStream($dst, [System.IO.FileMode]::Create)
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($crop))
    $enc.Save($out)
    $out.Close()
    exit 0
}
catch {
    exit 1
}
    )

    FileDelete, %psPath%
    FileAppend, %ps%, %psPath%, UTF-8

    RunWait, %ComSpec% /c powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%psPath%",, Hide UseErrorLevel
    exitCode := ErrorLevel

    FileDelete, %psPath%
    return (exitCode = 0 && FileExist(outputPath))
}




QI_FindEdge()
{
    paths := []
    paths.Push(A_ProgramFiles . "\Microsoft\Edge\Application\msedge.exe")
    paths.Push(A_ProgramFiles . " (x86)\Microsoft\Edge\Application\msedge.exe")
    paths.Push(A_LocalAppData . "\Microsoft\Edge\Application\msedge.exe")

    for _, p in paths
    {
        if FileExist(p)
            return p
    }

    return ""
}


QI_IniDirectory()
{
    global QIIni
    SplitPath, QIIni, , QIBaseDir
    if (QIBaseDir = "")
        QIBaseDir := A_ScriptDir
    return QIBaseDir
}

; GDI+¸¦ ÀÌ¿ëÇØ ÀÌ¹ÌÁö ÆÄÀÏÀ» Windows Å¬¸³º¸µå¿¡ ³Ö½À´Ï´Ù.
; CF_DIB¿Í CF_BITMAPÀ» ÇÔ²² Á¦°øÇÏ¿© ÇÑ±Û/HWP/¿¢¼¿/À¥ µî¿¡¼­
; Ctrl+V·Î ÀÌ¹ÌÁö°¡ ÀÎ½ÄµÉ °¡´É¼ºÀ» ³ôÀÔ´Ï´Ù.
; ¿ÜºÎ ÇÁ·Î±×·¥ÀÌ³ª PowerShellÀº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
QI_SetClipboardImage(imagePath)
{
    ; ÀÌ¹ÌÁö Å¬¸³º¸µå Ã³¸® ½ÇÆÐ°¡ SSOK ÇÁ·Î¼¼½º Á¾·á·Î ÀÌ¾îÁöÁö ¾Êµµ·Ï
    ; Windows PowerShell STA + WPF ¹æ½ÄÀ¸·Î Å¬¸³º¸µå¿¡ ÀÌ¹ÌÁö¸¦ ³Ö½À´Ï´Ù.
    imagePath := Trim(imagePath)

    if (imagePath = "" || !FileExist(imagePath))
    {
        MsgBox, 48, SSOK ÀÌ¹ÌÁö ºÙ¿©³Ö±â, ÀÌ¹ÌÁö ÆÄÀÏÀ» Ã£À» ¼ö ¾ø½À´Ï´Ù.`n%imagePath%
        return false
    }

    psPath := StrReplace(imagePath, "'", "''")

    ps =
    (
Add-Type -AssemblyName PresentationCore
$path = '%psPath%'
try {
    $img = New-Object System.Windows.Media.Imaging.BitmapImage
    $img.BeginInit()
    $img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $img.UriSource = New-Object System.Uri($path)
    $img.EndInit()
    $img.Freeze()
    [System.Windows.Clipboard]::SetImage($img)
    exit 0
}
catch {
    exit 1
}
    )

    tmpPs := A_Temp . "\SSOK_ImageClipboard_" . A_TickCount . ".ps1"
    FileDelete, %tmpPs%
    FileAppend, %ps%, %tmpPs%, UTF-8

    RunWait, %ComSpec% /c powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%tmpPs%",, Hide UseErrorLevel
    exitCode := ErrorLevel
    FileDelete, %tmpPs%

    if (exitCode != 0)
    {
        MsgBox, 48, SSOK ÀÌ¹ÌÁö ºÙ¿©³Ö±â, ÀÌ¹ÌÁö¸¦ Å¬¸³º¸µå¿¡ ³ÖÁö ¸øÇß½À´Ï´Ù.`n`nSSOK´Â Á¾·áµÇÁö ¾Ê½À´Ï´Ù.
        return false
    }

    return true
}

QI_CreateDIBFromHBITMAP(hBitmap)
{
    ; GetObject·Î BITMAP ±¸Á¶Ã¼¸¦ ÀÐ½À´Ï´Ù.
    VarSetCapacity(bm, 32, 0)
    if (DllCall("GetObject", "Ptr", hBitmap, "Int", 32, "Ptr", &bm) = 0)
        return 0

    width := NumGet(bm, 4, "Int")
    height := NumGet(bm, 8, "Int")
    bpp := 32

    if (width <= 0 || height <= 0)
        return 0

    ; BITMAPINFOHEADER + ÇÈ¼¿ µ¥ÀÌÅÍ.
    rowBytes := ((width * bpp + 31) // 32) * 4
    imageSize := rowBytes * height
    totalSize := 40 + imageSize

    hMem := DllCall("GlobalAlloc", "UInt", 0x0042, "UPtr", totalSize, "Ptr")
    if (!hMem)
        return 0

    pMem := DllCall("GlobalLock", "Ptr", hMem, "Ptr")
    if (!pMem)
    {
        DllCall("GlobalFree", "Ptr", hMem)
        return 0
    }

    ; BITMAPINFOHEADER
    NumPut(40, pMem + 0, 0, "UInt")
    NumPut(width, pMem + 4, 0, "Int")
    NumPut(height, pMem + 8, 0, "Int")
    NumPut(1, pMem + 12, 0, "UShort")
    NumPut(32, pMem + 14, 0, "UShort")
    NumPut(0, pMem + 16, 0, "UInt") ; BI_RGB
    NumPut(imageSize, pMem + 20, 0, "UInt")
    NumPut(0, pMem + 24, 0, "Int")
    NumPut(0, pMem + 28, 0, "Int")
    NumPut(0, pMem + 32, 0, "UInt")
    NumPut(0, pMem + 36, 0, "UInt")

    ; HBITMAP -> DIB ÇÈ¼¿
    hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
    pixelsPtr := pMem + 40
    if !DllCall("GetDIBits", "Ptr", hdc, "Ptr", hBitmap, "UInt", 0, "UInt", height, "Ptr", 0, "Ptr", pMem, "UInt", 0)
    {
        ; Çì´õ¸¦ ÀÌ¿ëÇÑ ½ÇÁ¦ ÇÈ¼¿ ÀÐ±â
        DllCall("GetDIBits", "Ptr", hdc, "Ptr", hBitmap, "UInt", 0, "UInt", height, "Ptr", pixelsPtr, "Ptr", pMem, "UInt", 0)
    }
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)

    ; À§ È£Ãâ ¹æ½Ä¸¸À¸·Î´Â ÀÏºÎ È¯°æ¿¡¼­ ÇÈ¼¿ÀÌ Ã¤¿öÁöÁö ¾ÊÀ» ¼ö ÀÖÀ¸¹Ç·Î
    ; º°µµ È­¸é DC ¹æ½ÄÀ¸·Î ´Ù½Ã ½ÃµµÇÕ´Ï´Ù.
    hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    oldObj := DllCall("SelectObject", "Ptr", hdc, "Ptr", hBitmap, "Ptr")
    DllCall("GetDIBits", "Ptr", hdc, "Ptr", hBitmap, "UInt", 0, "UInt", height, "Ptr", pixelsPtr, "Ptr", pMem, "UInt", 0)
    DllCall("SelectObject", "Ptr", hdc, "Ptr", oldObj)
    DllCall("DeleteDC", "Ptr", hdc)

    DllCall("GlobalUnlock", "Ptr", hMem)
    return hMem
}


QI_GdipStartup(ByRef token)
{
    VarSetCapacity(si, 16, 0)
    NumPut(1, si, 0, "UInt")
    token := 0
    return DllCall("gdiplus\GdiplusStartup", "Ptr*", token, "Ptr", &si, "Ptr", 0) = 0
}

QI_GdipShutdown(token)
{
    if (token)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", token)
}


; =========================================================
; 8¹ø ÀúÀå && ½ÇÇà
; - 1~7¹ø ÇöÀç ¼öÁ¤ ³»¿ëÀº ÀúÀå
; - ¿ø·¡ ÀÛ¾÷ Ã¢À¸·Î µ¹¾Æ°¡ Shift+F2 ³¯Â¥/¿äÀÏ/±â°£ ±â´É ½ÇÇà
; =========================================================
QI_Input8:
    Gosub, QI_SaveFromGui
    Gui, QIQuick:Destroy

    if (QILastTargetHwnd != "")
    {
        WinActivate, ahk_id %QILastTargetHwnd%
        Sleep, 150
    }

    Gosub, QI_RunDateTool
return


; =========================================================
; 9¹ø ÀúÀå && ÀÔ·Â
; - 1~7¹ø ÇöÀç ¼öÁ¤ ³»¿ëÀº ÀúÀå
; - 9¹øÀº Æ¯¼ö¹®ÀÚ ÀÚµ¿ ÀÔ·Â
; =========================================================
QI_Input9:
    Gosub, QI_SaveFromGui
    Gosub, QI_MakeSpecialText
    QIInputText := QISpecialText
    Gosub, QI_PasteText
return


; =========================================================
; QI 8¹ø ³¯Â¥/¿äÀÏ/±â°£ Ã³¸® Àü¿ë
; - ºí·Ï ÁöÁ¤ ¾øÀ½: ¿À´Ã ³¯Â¥(¿äÀÏ) ÇöÀç ½Ã°£ ÀÔ·Â
; - ´ÜÀÏ ³¯Â¥ ¼±ÅÃ: 2026. 5. 5.(È­) ÇüÅÂ·Î º¸Á¤
; - ³¯Â¥~³¯Â¥ ¼±ÅÃ: ¾çÂÊ ³¯Â¥ ¿äÀÏ º¸Á¤ + , NÀÏ°£ °è»ê
; =========================================================
QI_RunDateTool:
    QIOldClip := ClipboardAll
    ; ºí·Ï ÁöÁ¤ ¿©ºÎ È®ÀÎ
    SSOK_CopyClipboardText(QISelectedDateRaw, 0.25, 2)
    QISelectedDate := Trim(QISelectedDateRaw)

    if (QISelectedDate != "")
    {
        QIDateText := QISelectedDate

        ; µû¿ÈÇ¥ ¹× ºÒÇÊ¿ä ¹®ÀÚ Á¦°Å
        QIDateText := StrReplace(QIDateText, "'", "")
        QIDateText := StrReplace(QIDateText, "¡¯", "")
        QIDateText := StrReplace(QIDateText, "¡®", "")
        QIDateText := StrReplace(QIDateText, "¡°", "")
        QIDateText := StrReplace(QIDateText, "¡±", "")
        QIDateText := StrReplace(QIDateText, "``", "")

        ; ±âÁ¸ ¿äÀÏ, ºó °ýÈ£, ±â°£ Ç¥½Ã Á¦°Å
        QIDateText := RegExReplace(QIDateText, "\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]?\)", "")
        QIDateText := RegExReplace(QIDateText, "\(\s*ÃÑ\s*[\d,]+\s*ÀÏ\s*\)", "")
        QIDateText := RegExReplace(QIDateText, ",\s*[\d,]+\s*ÀÏ°£", "")
        QIDateText := RegExReplace(QIDateText, "\(\s*[\d,]+\s*ÀÏ°£\s*\)", "")
        QIDateText := RegExReplace(QIDateText, "\[\s*\d+\s*ÀÏ°£.*?\]", "")
        QIDateText := RegExReplace(QIDateText, "\s+", "")

        ; ³¯Â¥ ¹üÀ§: 26.5.1.~26.5.3. / 2026. 5. 1.~2026. 5. 3.
        if (RegExMatch(QIDateText, "^(\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?[-~](\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?$", m))
        {
            QIY1 := m1
            QIM1 := m2
            QID1 := m3
            QIY2 := m4
            QIM2 := m5
            QID2 := m6

            if (StrLen(QIY1) = 2)
                QIY1 := (QIY1 + 0 > 30) ? "19" . QIY1 : "20" . QIY1
            if (StrLen(QIY2) = 2)
                QIY2 := (QIY2 + 0 > 30) ? "19" . QIY2 : "20" . QIY2

            QIStartDate := QIY1 . Format("{:02}", QIM1) . Format("{:02}", QID1)
            QIEndDate := QIY2 . Format("{:02}", QIM2) . Format("{:02}", QID2)

            QITempDate := QIEndDate
            EnvSub, QITempDate, %QIStartDate%, Days
            QITotalDays := QITempDate + 1

            if (QITotalDays < 1)
            {
                Clipboard := QIOldClip
                ToolTip, Á¾·áÀÏÀÌ ½ÃÀÛÀÏº¸´Ù ºü¸¨´Ï´Ù.
                SetTimer, QI_RemoveToolTip, -1300
                return
            }

            FormatTime, QIWDay1, %QIStartDate%, WDay
            FormatTime, QIWDay2, %QIEndDate%, WDay
            QIDays := ["ÀÏ", "¿ù", "È­", "¼ö", "¸ñ", "±Ý", "Åä"]
            QIYoil1 := QIDays[QIWDay1]
            QIYoil2 := QIDays[QIWDay2]

            QIResultDate := QIY1 . ". " . QIM1 . ". " . QID1 . ".(" . QIYoil1 . ")~" . QIY2 . ". " . QIM2 . ". " . QID2 . ".(" . QIYoil2 . "), " . QITotalDays . "ÀÏ°£"

            Clipboard := QIResultDate
            Send, ^v
            Sleep, 100
            Clipboard := QIOldClip
            return
        }

        ; ´ÜÀÏ ³¯Â¥: 26.5.1. / 2026. 5. 1.
        if (RegExMatch(QIDateText, "^(\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?$", m))
        {
            QIY := m1
            QIM := m2
            QID := m3

            if (StrLen(QIY) = 2)
                QIY := (QIY + 0 > 30) ? "19" . QIY : "20" . QIY

            QICalcDate := QIY . Format("{:02}", QIM) . Format("{:02}", QID)

            FormatTime, QIWDay, %QICalcDate%, WDay
            QIDays := ["ÀÏ", "¿ù", "È­", "¼ö", "¸ñ", "±Ý", "Åä"]
            QIYoil := QIDays[QIWDay]

            QIResultDate := QIY . ". " . QIM . ". " . QID . ".(" . QIYoil . ")"

            Clipboard := QIResultDate
            Send, ^v
            Sleep, 100
            Clipboard := QIOldClip
            return
        }

        Clipboard := QIOldClip
        ToolTip, ³¯Â¥ Çü½ÄÀ» Ã£Áö ¸øÇß½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1300
        return
    }

    ; ºí·Ï ÁöÁ¤ÀÌ ¾øÀ¸¸é ¿À´Ã ³¯Â¥(¿äÀÏ) ÇöÀç ½Ã°£ ÀÔ·Â
    Gosub, QI_MakeTodayDate
    Clipboard := QITodayText
    Send, ^v
    Sleep, 100
    Clipboard := QIOldClip
return


; =========================================================
; ¼±ÅÃÇÑ ¹®±¸ ÀÚµ¿ ÀÔ·Â
; =========================================================
QI_PasteText:
    if (QIInputText = "")
    {
        ToolTip, ÀÔ·ÂÇÒ ¹®±¸°¡ ºñ¾î ÀÖ½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1200
        return
    }

    Gui, QIQuick:Destroy

    if (QILastTargetHwnd != "")
    {
        WinActivate, ahk_id %QILastTargetHwnd%
        WinWaitActive, ahk_id %QILastTargetHwnd%,, 0.6
        Sleep, 60
    }

    if (QI_CanTypeDirect(QIInputText))
    {
        QI_TypeDirect(QIInputText)
        Sleep, 120
        return
    }

    QIOldClip := ClipboardAll
    if (!SSOK_SetClipboardTextWithWait(QIInputText, 0.7, 3))
    {
        Clipboard := QIOldClip
        ToolTip, Å¬¸³º¸µå¿¡ ÀÔ·Â ¹®±¸¸¦ ´ãÁö ¸øÇß½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1200
        return
    }

    Send, ^v
    Sleep, 120

    Clipboard := QIOldClip
return

QI_CanTypeDirect(QIValue)
{
    if (StrLen(QIValue) > 200)
        return false
    return !RegExMatch(QIValue, "[^\x09\x0A\x0D\x20-\x7E]")
}

QI_TypeDirect(QIValue)
{
    QIValue := StrReplace(QIValue, "`r`n", "`n")
    QIValue := StrReplace(QIValue, "`r", "`n")

    Loop, Parse, QIValue
    {
        QIChar := A_LoopField
        if (QIChar = "`n")
            SendEvent, {Enter}
        else if (QIChar = "`t")
            SendEvent, {Tab}
        else
            SendRaw, %QIChar%
        Sleep, 15
    }
    return true
}


; =========================================================
; X ¶Ç´Â Esc·Î Ã¢ ´Ý±â
; ´ÝÀ» ¶§µµ ÇöÀç ¼öÁ¤ ³»¿ë ÀúÀå
; =========================================================
QIQuickGuiClose:
QIQuickGuiEscape:
    Gosub, QI_SaveFromGui
    Gui, QIQuick:Destroy
return


; =========================================================
; ÅøÆÁ Á¦°Å
; =========================================================
QI_RemoveToolTip:
    ToolTip
return


; =========================================================
; ¿©·¯ ÁÙ ÀúÀå¿ë ÀÎÄÚµù ÇÔ¼ö
; ÁÙ¹Ù²ÞÀ» ssok.ini ÇÑ ÁÙ¿¡ ÀúÀå °¡´ÉÇÏ°Ô º¯È¯
; =========================================================
QI_EncodeText(QIValue)
{
    QIValue := StrReplace(QIValue, "%", "%25")
    QIValue := StrReplace(QIValue, "`r`n", "%0D%0A")
    QIValue := StrReplace(QIValue, "`n", "%0A")
    QIValue := StrReplace(QIValue, "`r", "%0D")
    return QIValue
}


; =========================================================
; ¿©·¯ ÁÙ ÀúÀå°ª º¹¿ø ÇÔ¼ö
; =========================================================
QI_DecodeText(QIValue)
{
    QIValue := StrReplace(QIValue, "%0D%0A", "`r`n")
    QIValue := StrReplace(QIValue, "%0A", "`r`n")
    QIValue := StrReplace(QIValue, "%0D", "`r`n")
    QIValue := StrReplace(QIValue, "%25", "%")
    return QIValue
}


; --- ºñ¹Ð¹øÈ£ ÇÖÅ°´Â º¸¾È»ó Á¦°ÅµÊ ---
; °³ÀÎ ºñ¹Ð¹øÈ£/ÁÖ¼Ò´Â ssok.ini [PersonalHotstrings]¿¡ º°µµ °ü¸®ÇÏ¼¼¿ä.



















































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
    IniRead, SSOK_OrgName, %SSOK_IniFile%, MajorTodos, OrgName, ¼¼Á¾±³
    SSOK_OrgName := Trim(SSOK_OrgName)
    if (SSOK_OrgName = "")
        SSOK_OrgName := "¼¼Á¾±³"
    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Text, x8 y27 w34 h12 c6B7280 Right gSSOK_SchoolSearch_Show, ±â°ü¸í
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
    Gui, SSOKSide:Add, Button, x8 y144 w%SSOK_SidebarButtonW% h25 vSSOK_SidebarBtnDraft gSSOK_Sidebar_Draft, °£´Ü ÀÛ¼º

    Gui, SSOKSide:Font, s8 bold c006400, Malgun Gothic
    Gui, SSOKSide:Add, Text, x8 y170 w%SSOK_SidebarButtonW% h29 vSSOK_SidebarOneShot +Border +0x200 BackgroundE8F5E9 c006400 Center gSSOK_Sidebar_F2, % Chr(9889) . " " . Chr(54620) . Chr(48169) . " " . Chr(51221) . Chr(47532) . " " . Chr(9889)

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
    Gui, SSOKSide:Font, s6 norm c808080, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x%SSOK_QASearchX1% y284 w%SSOK_QASearchW% h18 vSSOK_ACC_SideQuery HwndSSOK_ACC_SideQueryEditHwnd, %SSOK_ACC_SidePlaceholder%
    Gui, SSOKSide:Add, Edit, x%SSOK_QASearchX2% y284 w%SSOK_QASearchW% h18 vSSOK_WRK_SideQuery HwndSSOK_WRK_SideQueryEditHwnd, %SSOK_WRK_SidePlaceholder%
    Gui, SSOKSide:Add, Button, x-100 y-100 w1 h1 Hidden Default gSSOK_Sidebar_DefaultSearch

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Progress, x12 y306 w%SSOK_SidebarSepW% h1 vSSOK_SidebarSepF4 BackgroundE6EAEE cE6EAEE
    Gui, SSOKSide:Add, Text, x8 y313 w%SSOK_SidebarCaptionW% h12 vSSOK_SidebarHintF4 c6B7280 Center gSSOK_Sidebar_F4, Win + F4
    Gui, SSOKSide:Font, s9 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y324 w%SSOK_QFMainButtonW% h25 vSSOK_SidebarBtnFile gSSOK_Sidebar_F4, ÆÄÀÏ¿­±â
    SSOK_QF_SidePlaceholder := "°Ë»ö "
    SSOK_QF_SideIsPlaceholder := true
    Gui, SSOKSide:Font, s6 norm c808080, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x%SSOK_QFSearchX% y326 w%SSOK_QFSearchW% h21 vSSOK_QF_SideKeyword HwndSSOK_QF_SideKeywordEditHwnd, %SSOK_QF_SidePlaceholder%
    Gui, SSOKSide:Font, s8 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX1% y350 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF1 gSSOK_Sidebar_QF1, %SSOK_SideQF1%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX2% y350 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF2 gSSOK_Sidebar_QF2, %SSOK_SideQF2%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX3% y350 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF3 gSSOK_Sidebar_QF3, %SSOK_SideQF3%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX4% y350 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF4 gSSOK_Sidebar_QF4, %SSOK_SideQF4%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX5% y350 w%SSOK_SidebarSmallButtonW% h22 vSSOK_SidebarQF5 gSSOK_Sidebar_QF5, %SSOK_SideQF5%

    Gui, SSOKSide:Font, s6 norm, Malgun Gothic
    Gui, SSOKSide:Add, Progress, x12 y373 w%SSOK_SidebarSepW% h1 vSSOK_SidebarSepF5 BackgroundE6EAEE cE6EAEE
    Gui, SSOKSide:Add, Text, x8 y383 w%SSOK_SidebarCaptionW% h12 vSSOK_SidebarHintF5 c6B7280 Center gSSOK_Sidebar_F5, Win + F5
    Gui, SSOKSide:Font, s9 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y396 w%SSOK_QUMainButtonW% h25 vSSOK_SidebarBtnUrl gSSOK_Sidebar_F5, URL¿­±â
    SSOK_QU_SidePlaceholder := "°Ë»ö "
    SSOK_QU_SideIsPlaceholder := true
    Gui, SSOKSide:Font, s6 norm c808080, Malgun Gothic
    Gui, SSOKSide:Add, Edit, x%SSOK_QUSearchX% y398 w%SSOK_QUSearchW% h21 vSSOK_QU_SideKeyword HwndSSOK_QU_SideKeywordEditHwnd, %SSOK_QU_SidePlaceholder%
    Gui, SSOKSide:Font, s8 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX1% y423 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU1 gSSOK_Sidebar_QU1, %SSOK_SideQU1%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX2% y423 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU2 gSSOK_Sidebar_QU2, %SSOK_SideQU2%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX3% y423 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU3 gSSOK_Sidebar_QU3, %SSOK_SideQU3%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX4% y423 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU4 gSSOK_Sidebar_QU4, %SSOK_SideQU4%
    Gui, SSOKSide:Add, Button, x%SSOK_SidebarSmallButtonX5% y423 w%SSOK_SidebarSmallButtonW% h23 vSSOK_SidebarQU5 gSSOK_Sidebar_QU5, %SSOK_SideQU5%

    ; ===== ÁÖ¿äÇÒÀÏ ¸Þ¸ð =====
    IniRead, SSOK_MajorTodoRaw, %SSOK_IniFile%, MajorTodos, Memo, __SSOK_EMPTY__
    if (SSOK_MajorTodoRaw = "__SSOK_EMPTY__" || SSOK_MajorTodoRaw = "")
        SSOK_MajorTodo := SSOK_GetMajorTodoSampleText()
    else
        SSOK_MajorTodo := StrReplace(SSOK_MajorTodoRaw, "\n", "`r`n")

    Gui, SSOKSide:Font, s8 norm, Malgun Gothic
    OnMessage(0x0133, "SSOK_WM_CTLCOLOREDIT")
    OnMessage(0x0138, "SSOK_WM_CTLCOLORSTATIC")
    Gui, SSOKSide:Add, Edit, x8 y456 w%SSOK_SidebarButtonW% h112 vSSOK_MajorTodoEdit HwndSSOK_MajorTodoHwnd gSSOK_SaveMajorTodo +Wrap -VScroll -HScroll -E0x200 BackgroundFFFAE6, %SSOK_MajorTodo%

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
    Gui, SSOKSide:Add, Text, x8 y624 w%SSOK_SidebarButtonW% h11 vSSOK_SidebarHintF12 c4D6B7A Center gSSOK_Sidebar_PCOff, Win + F12
    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y636 w%SSOK_PCOffW% h25 vSSOK_SidebarBtnPCOff gSSOK_Sidebar_PCOff, Åð±Ù PC OFF
    Gui, SSOKSide:Font, s5 norm, Malgun Gothic
    Gui, SSOKSide:Add, Button, x%SSOK_SettingsX% y636 w18 h25 vSSOK_SidebarBtnSettings gSSOK_ShowPowerScheduleGui, ¼³Á¤

    ; ¾÷¹«¿ë µµ±¸ ¸Þ´º
    Gui, SSOKSide:Font, s7 bold, Malgun Gothic
    Gui, SSOKSide:Add, Button, x8 y663 w%SSOK_SidebarButtonW% h25 vSSOK_SidebarBtnWorkTools gSSOK_Sidebar_WorkTools, % Chr(9881) . " ¾÷¹«¿ë µµ±¸"

    SSOK_HideY := SSOK_SidebarH - 70
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
    IniRead, SSOK_OrgNameValue, %SSOK_IniFile%, MajorTodos, OrgName, ¼¼Á¾±³
    SSOK_OrgNameValue := Trim(SSOK_OrgNameValue)
    if (SSOK_OrgNameValue = "")
        SSOK_OrgNameValue := "¼¼Á¾±³"
    return SSOK_OrgNameValue
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
                if (SSOK_IsQuitAlarmTime(timeText))
                    SSOK_ShowQuitAlarmConfirm(display, target)
                else if (SSOK_IsLunchAlarmTime(timeText))
                    SSOK_ShowAlarmCenter(display, "Á¡½É ½Ã°£ 5ºÐ ÀüÀÔ´Ï´Ù.")
                else
                    SSOK_ShowAlarmCenter(display)
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

SSOK_ShowAlarmCenter(displayText, messageText := "5ºÐÀüÀÔ´Ï´Ù.")
{
    Gui, SSOKAlarmCenter:Destroy
    Gui, SSOKAlarmCenter:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKAlarmCenter:Color, FFF7D6
    Gui, SSOKAlarmCenter:Font, s56 bold, Malgun Gothic
    Gui, SSOKAlarmCenter:Add, Text, x0 y48 w720 h116 c111111 Center, %displayText%
    Gui, SSOKAlarmCenter:Font, s18 norm, Malgun Gothic
    Gui, SSOKAlarmCenter:Add, Text, x0 y164 w720 h48 c555555 Center, %messageText%
    Gui, SSOKAlarmCenter:Font, s18 bold, Malgun Gothic
    Gui, SSOKAlarmCenter:Add, Button, x284 y220 w152 h48 gSSOK_CloseAlarmCenter, ´Ý±â
    x := (A_ScreenWidth - 720) // 2
    y := (A_ScreenHeight - 280) // 2
    Gui, SSOKAlarmCenter:Show, x%x% y%y% w720 h280, SSOK ¾Ë¶÷
}

SSOK_ShowQuitAlarmConfirm(displayText, targetStamp := "")
{
    global SSOK_QuitAlarmTargetStamp
    SSOK_QuitAlarmTargetStamp := targetStamp
    Gui, SSOKQuitAlarm:Destroy
    Gui, SSOKQuitAlarm:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKQuitAlarm:Color, FFF7D6
    Gui, SSOKQuitAlarm:Font, s44 bold, Malgun Gothic
    Gui, SSOKQuitAlarm:Add, Text, x0 y36 w780 h84 c111111 Center, %displayText%
    Gui, SSOKQuitAlarm:Font, s24 norm, Malgun Gothic
    Gui, SSOKQuitAlarm:Add, Text, x0 y132 w780 h52 c333333 Center, Åð±Ù½Ã°£ 5ºÐÀüÀÔ´Ï´Ù.
    Gui, SSOKQuitAlarm:Add, Text, x0 y186 w780 h52 c333333 Center, PC¸¦ ÀÚµ¿À¸·Î ²ø±î¿ä?
    Gui, SSOKQuitAlarm:Font, s20 bold, Malgun Gothic
    Gui, SSOKQuitAlarm:Add, Button, x210 y256 w160 h56 gSSOK_QuitAlarmOK, Y
    Gui, SSOKQuitAlarm:Add, Button, x410 y256 w160 h56 gSSOK_QuitAlarmNo, NO
    x := (A_ScreenWidth - 780) // 2
    y := (A_ScreenHeight - 340) // 2
    Gui, SSOKQuitAlarm:Show, x%x% y%y% w780 h340, SSOK Åð±Ù ¾Ë¶÷
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
    GuiControl, SSOKSide:MoveDraw, SSOK_SidebarBtnDraft, w%buttonW%
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

SSOK_GetSidebarAttachedGuiPos(guiW, guiH, ByRef outX, ByRef outY)
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

    outX := sideX - guiW - gap
    if (outX < SSOK_AttachWorkLeft)
        outX := sideX + sideW + gap
    if (outX + guiW > SSOK_AttachWorkRight)
        outX := SSOK_AttachWorkRight - guiW
    if (outX < SSOK_AttachWorkLeft)
        outX := SSOK_AttachWorkLeft

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


SSOK_Sidebar_Calc:
    Gosub, SSOK_ShowCalculator
return

SSOK_ShowCalculator:
    Gosub, SSOK_WinHelp_BlockWindowsMenu
    Gui, SSOKCalc:Destroy
    Gui, SSOKCalc:New, +AlwaysOnTop +ToolWindow +HwndSSOK_CalcHwnd, SSOK ÇàÁ¤¾÷¹« °£Æí °è»ê±â
    Gui, SSOKCalc:Margin, 12, 10
    Gui, SSOKCalc:Color, F7FBFF
    SSOK_CalcFormatting := false

    ; 1. 8°³ ¸ðµå ¼±ÅÃ ÅÇ (1Çà 4°³: °è»ê±â, ³¯Â¥¡¤¿äÀÏ, ³ªÀÌ.ÅðÁ÷, ±Ù¹«½Ã°£ / 2Çà 4°³: ¿¹»ê »êÃâ³»¿ª, VAT °è»ê, Á¶´Þ¼ö¼ö·á, ÀÔÂû°ø°í)
    Gui, SSOKCalc:Font, s8 bold, Malgun Gothic
    Gui, SSOKCalc:Add, Radio, x12 y10 w103 h26 vSSOK_CalcTab1 +0x1000 +Center Checked gSSOK_CalcModeExpression, ¡Ü °è»ê±â
    Gui, SSOKCalc:Add, Radio, x121 y10 w103 h26 vSSOK_CalcTab2 +0x1000 +Center gSSOK_CalcModeDate, ³¯Â¥¡¤¿äÀÏ
    Gui, SSOKCalc:Add, Radio, x230 y10 w103 h26 vSSOK_CalcTab3 +0x1000 +Center gSSOK_CalcModeAge, ³ªÀÌ.ÅðÁ÷
    Gui, SSOKCalc:Add, Radio, x339 y10 w103 h26 vSSOK_CalcTab4 +0x1000 +Center gSSOK_CalcModeWorkday, ±Ù¹«½Ã°£

    ; 2¹øÂ° ÅÇ Çà: ¿¹»ê »êÃâ³»¿ª, VAT °è»ê, Á¶´Þ¼ö¼ö·á, ÀÔÂû°ø°í
    Gui, SSOKCalc:Add, Radio, x12 y39 w103 h26 vSSOK_CalcTab6 +0x1000 +Center gSSOK_CalcModeBudget, ¿¹»ê »êÃâ³»¿ª
    Gui, SSOKCalc:Add, Radio, x121 y39 w103 h26 vSSOK_CalcTab7 +0x1000 +Center gSSOK_CalcModeVat, VAT °è»ê
    Gui, SSOKCalc:Add, Radio, x230 y39 w103 h26 vSSOK_CalcTab8 +0x1000 +Center gSSOK_CalcModeProcure, Á¶´Þ¼ö¼ö·á
    Gui, SSOKCalc:Add, Radio, x339 y39 w103 h26 vSSOK_CalcTab5 +0x1000 +Center gSSOK_CalcModeBid, ÀÔÂû°ø°í

    ; 2. µµ¿ò¸» ¾È³»
    Gui, SSOKCalc:Font, s8 norm c2A5C70, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y70 w430 h16 vSSOK_CalcHelp, ¿¹: 5,000 * 2°³ * 4ÁÖ=  ¶Ç´Â  (1,000 + 2,000) * 10

    ; 3. ºÐ¸®µÈ ÀÔ·ÂÄ­ 1 & 2 (3¹è ´ëÇüÈ­ h54)
    Gui, SSOKCalc:Font, s8 bold c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y90 w430 h18 vSSOK_CalcPrompt1, °è»ê ¼ö½Ä ¶Ç´Â ±Ý¾× ÀÔ·Â:
    Gui, SSOKCalc:Add, Text, x234 y90 w208 h18 vSSOK_CalcPrompt2, Ãß°¡ ¿É¼Ç:
    Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x12 y110 w430 h54 -WantReturn vSSOK_CalcInput1 gSSOK_CalcInput1Changed HwndSSOK_CalcInput1Hwnd
    Gui, SSOKCalc:Font, s15 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x234 y110 w208 h54 -WantReturn vSSOK_CalcInput2

    ; ³¯Â¥ ¼±ÅÃ DateTime ÄÁÆ®·Ñ (³¯Â¥¡¤¿äÀÏ, ³ªÀÌ¡¤ÅðÁ÷, ÀÔÂû°ø°í, ±Ù¹«½Ã°£ Àü¿ë)
    Gui, SSOKCalc:Font, s13 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, DateTime, x12 y110 w208 h42 vSSOK_CalcDate_Start Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd
    Gui, SSOKCalc:Add, DateTime, x12 y110 w208 h42 vSSOK_CalcAge_Birth Choose19900515 Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd
    Gui, SSOKCalc:Add, DateTime, x234 y110 w208 h42 vSSOK_CalcAge_Ref Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd
    Gui, SSOKCalc:Add, DateTime, x12 y110 w208 h42 vSSOK_CalcBid_Date Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd

    ; ±Ù¹«½Ã°£ Àü¿ë DateTime ÄÁÆ®·Ñ (ÀÏ½Ã 1ºÐ´ÜÀ§ Á¤È® ¼±ÅÃ)
    FormatTime, todayWorkStart,, yyyyMMdd083000
    FormatTime, todayWorkEnd,, yyyyMMdd163000
    Gui, SSOKCalc:Font, s11 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, DateTime, x12 y110 w208 h42 vSSOK_CalcWork_Start Choose%todayWorkStart% Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd HH:mm
    Gui, SSOKCalc:Add, DateTime, x234 y110 w208 h42 vSSOK_CalcWork_End Choose%todayWorkEnd% Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd HH:mm

    ; ÀÎÁ¤·ü ÄÁÆ®·Ñ (³¯Â¥¡¤¿äÀÏ Àü¿ë)
    Gui, SSOKCalc:Font, s8 bold c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x305 y165 w45 h18 Right vSSOK_CalcRateLabel, ÀÎÁ¤·ü:
    Gui, SSOKCalc:Font, s9 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x353 y162 w46 h22 Center -WantReturn vSSOK_CalcRate, 100
    Gui, SSOKCalc:Font, s8 bold c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x401 y165 w18 h18 Left vSSOK_CalcRateUnit, `%

    ; Á¶´Þ¼ö¼ö·á °è¾à ¹æ½Ä ¼±ÅÃ ¶óµð¿À (Á¶´Þ¼ö¼ö·á Àü¿ë)
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Radio, x12 y168 w150 h22 vSSOK_CalcProcureRad1 Group Checked gSSOK_CalcProcureTypeChanged, ¡Ü ³»ÀÚ±¸¸Å ÃÑ¾×°è¾à
    Gui, SSOKCalc:Add, Radio, x168 y168 w180 h22 vSSOK_CalcProcureRad2 gSSOK_CalcProcureTypeChanged, Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç°

    ; 4-1. ¿¹»êºñ¸ñ ¼±ÅÃ ¹öÆ° (¿¹»ê »êÃâ³»¿ª Àü¿ë)
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y174 w42 h22 vSSOK_CalcBudgetLabel, ºñ¸ñ:
    Gui, SSOKCalc:Font, s8 norm c222222, Malgun Gothic
    Gui, SSOKCalc:Add, Button, x56 y170 w74 h28 vSSOK_CalcBudgetBtn1 gSSOK_CalcBudgetBtnClick, ±³À°¿î¿µºñ
    Gui, SSOKCalc:Add, Button, x133 y170 w70 h28 vSSOK_CalcBudgetBtn2 gSSOK_CalcBudgetBtnClick, ¿î¿µ¼ö´ç
    Gui, SSOKCalc:Add, Button, x206 y170 w74 h28 vSSOK_CalcBudgetBtn3 gSSOK_CalcBudgetBtnClick, ÀÏ¹Ý¼ö¿ëºñ
    Gui, SSOKCalc:Add, Button, x283 y170 w74 h28 vSSOK_CalcBudgetBtn4 gSSOK_CalcBudgetBtnClick, ¾÷¹«ÃßÁøºñ
    Gui, SSOKCalc:Add, Button, x360 y170 w82 h28 vSSOK_CalcBudgetBtn5 gSSOK_CalcBudgetBtnClick, ºñÇ°ºñ

    ; 4. ½ÇÇà ¹öÆ° ¿µ¿ª (°è»ê 1.5¹è ±æ°Ô: 295px / °á°ú º¹»ç 60% ÀÛ°Ô: 125px)
    Gui, SSOKCalc:Font, s9 bold, Malgun Gothic
    Gui, SSOKCalc:Add, Button, x12 y172 w295 h28 Default vSSOK_CalcCalculateBtn gSSOK_CalcCalculate, °è»ê (Enter)
    Gui, SSOKCalc:Font, s9 norm, Malgun Gothic
    Gui, SSOKCalc:Add, Button, x317 y172 w125 h28 vSSOK_CalcCopyBtn gSSOK_CalcCopyResult, °á°ú º¹»ç

    ; 5. ÀÚ¸´¼ö ¿É¼Ç (Ä­À» ³ÐÇô¼­ 2ÁÙ ÁÙ¹Ù²Þ ¹æÁö)
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y205 w48 h20 vSSOK_CalcPrecisionLabel, ÀÚ¸´¼ö:
    Gui, SSOKCalc:Font, s8 norm c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Radio, x65 y204 w55 h20 vSSOK_CalcRadPrec0 gSSOK_CalcPrecisionChanged Checked, Á¤¼ö
    Gui, SSOKCalc:Add, Radio, x124 y204 w92 h20 vSSOK_CalcRadPrec1 gSSOK_CalcPrecisionChanged, ¼Ò¼ö 1ÀÚ¸®
    Gui, SSOKCalc:Add, Radio, x220 y204 w92 h20 vSSOK_CalcRadPrec2 gSSOK_CalcPrecisionChanged, ¼Ò¼ö 2ÀÚ¸®
    Gui, SSOKCalc:Add, Radio, x316 y204 w55 h20 vSSOK_CalcRadPrec4 gSSOK_CalcPrecisionChanged, ÀÚµ¿

    ; 6. °è»ê °á°ú ¿µ¿ª
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y230 w100 h16 vSSOK_CalcResultLabel, °è»ê °á°ú:
    Gui, SSOKCalc:Font, s10 bold c006C73, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x12 y250 w430 h134 ReadOnly +Multi +Wrap -WantReturn HwndSSOK_CalcResultHwnd vSSOK_CalcResult,

    Gui, SSOKCalc:Show, w455 h395, SSOK ÇàÁ¤¾÷¹« °£Æí °è»ê±â

    SSOK_CalcMode := "expr"
    SSOK_CalcPrecision := 1
    SSOK_CalcBudgetCat := "±³À°¿î¿µºñ"
    Gosub, SSOK_CalcApplyModeUI
    GuiControl, SSOKCalc:Focus, SSOK_CalcInput1
return

SSOK_CalcApplyModeUI:
    Gosub, SSOK_CalcUpdateModeTabs

    ; 1. °á°úÃ¢ ¿ÏÀü ÃÊ±âÈ­
    GuiControl, SSOKCalc:, SSOK_CalcResult,
    GuiControl, SSOKCalc:Text, SSOK_CalcResult,
    if (SSOK_CalcResultHwnd)
        DllCall("user32\SetWindowText", "Ptr", SSOK_CalcResultHwnd, "Str", "")
    GuiControl, SSOKCalc:+Redraw, SSOK_CalcResult

    ; Æ¯¼ö ¸ðµå Àü¿ë ÄÁÆ®·Ñ ±âº» ¼û±è
    GuiControl, SSOKCalc:Hide, SSOK_CalcRateLabel
    GuiControl, SSOKCalc:Hide, SSOK_CalcRate
    GuiControl, SSOKCalc:Hide, SSOK_CalcRateUnit
    GuiControl, SSOKCalc:Hide, SSOK_CalcProcureRad1
    GuiControl, SSOKCalc:Hide, SSOK_CalcProcureRad2
    GuiControl, SSOKCalc:Hide, SSOK_CalcDate_Start
    GuiControl, SSOKCalc:Hide, SSOK_CalcAge_Birth
    GuiControl, SSOKCalc:Hide, SSOK_CalcAge_Ref
    GuiControl, SSOKCalc:Hide, SSOK_CalcBid_Date
    GuiControl, SSOKCalc:Hide, SSOK_CalcWork_Start
    GuiControl, SSOKCalc:Hide, SSOK_CalcWork_End

    ; ³¯Â¥/ÀÏ½Ã ¼±ÅÃ ¸ðµå(date, age, bid, workday)´Â Input1 ¼û±è, ±× ¿Ü ¸ðµå(expr, budget, vat, procure)´Â ¹«Á¶°Ç Ç¥½Ã ¹× °»½Å
    if (SSOK_CalcMode = "date" || SSOK_CalcMode = "age" || SSOK_CalcMode = "bid" || SSOK_CalcMode = "workday")
        GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
    else
    {
        GuiControl, SSOKCalc:Show, SSOK_CalcInput1
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcInput1
    }

    FormatTime, todayDateStr,, yyyy-MM-dd
    FormatTime, todayTimeStr,, yyyy-MM-dd 08:30

    if (SSOK_CalcMode = "budget")
    {
        SSOK_CalcSetPrecisionVisible(false)
        ; °è»ê(Enter) ¹öÆ°Àº ¿¹»ê ¸ðµå¿¡¼­ ¿ÏÀü °Ý¸®/¼û±è (Áßº¹ ¿À¹ö·¦ ¹æÁö)
        GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x-999 y-999 w10 h10
        GuiControl, SSOKCalc:Hide, SSOK_CalcCalculateBtn

        ; ¿¹»ê ÃÑ¾× ÀÔ·ÂÄ­: ³ôÀÌ 3¹è(h54), ±ÛÀÚ Å©±â 2¹è(s18 bold)
        Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
        GuiControl, SSOKCalc:Font, SSOK_CalcInput1
        GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y110 w430 h54
        GuiControl, SSOKCalc:Show, SSOK_CalcInput1

        ; ¿¹»êºñ¸ñ ¹öÆ° Ç¥½Ã ¹× À§Ä¡ ÇÏÇâ Á¶Á¤
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetLabel, x12 y174 w42 h22
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn1, x56 y170 w74 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn2, x133 y170 w70 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn3, x206 y170 w74 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn4, x283 y170 w74 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn5, x360 y170 w82 h28

        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetLabel
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn1
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn2
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn3
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn4
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn5

        ; °á°ú º¹»ç ¹öÆ° ÀüÃ¼ ³Êºñ ¹èÄ¡
        GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x12 y206 w430 h28
        GuiControl, SSOKCalc:Show, SSOK_CalcCopyBtn
        GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y240
        GuiControl, SSOKCalc:Move, SSOK_CalcResult, y260 h124

        GuiControl, SSOKCalc:, SSOK_CalcHelp, ¿¹»ê »êÃâ³»¿ª: ¿¹»ê ÃÑ¾×À» ÀÔ·ÂÇÏ°í ºñ¸ñ ¹öÆ°À» ´©¸£¸é »êÃâ½ÄÀÌ ÀÚµ¿ ÀÛ¼ºµË´Ï´Ù.
        GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ¿¹»ê ÃÑ¾× ÀÔ·Â (¿¹: 1,000,000):
        GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 w430
        GuiControl, SSOKCalc:Hide, SSOK_CalcPrompt2
        GuiControl, SSOKCalc:Hide, SSOK_CalcInput2

        GuiControlGet, vIn1, SSOKCalc:, SSOK_CalcInput1
        numStr := RegExReplace(vIn1, "[^0-9]", "")
        amt := Round(numStr + 0)
        if (amt <= 0)
            amt := 1000000
        else if (amt < 1000)
            amt := amt * 1000
        else
            amt := Round(amt / 1000) * 1000
        vIn1 := SSOK_CalcAddCommas(amt)
        GuiControl, SSOKCalc:, SSOK_CalcInput1, %vIn1%
        cat := (SSOK_CalcBudgetCat != "") ? SSOK_CalcBudgetCat : "±³À°¿î¿µºñ"
        res := SSOK_CalcGetBudgetBreakdown(cat, vIn1, autoFormula)
        SSOK_CalcSetResult(res)
    }
    else
    {
        ; ¿¹»êºñ¸ñ ¹öÆ° ¼û±è
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetLabel
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn1
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn2
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn3
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn4
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn5

        ; °è»ê(1.5¹è ±æ°Ô: w295) / º¹»ç(60% ÀÛ°Ô: w125) ¹öÆ° ¹èÄ¡ (y172)
        GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x12 y172 w295 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x317 y172 w125 h28
        GuiControl, SSOKCalc:Show, SSOK_CalcCalculateBtn
        GuiControl, SSOKCalc:Show, SSOK_CalcCopyBtn
        GuiControl, SSOKCalc:Text, SSOK_CalcCalculateBtn, °è»ê (Enter)

        if (SSOK_CalcMode = "expr")
        {
            ; ÀÏ¹Ý°è»ê: ´ëÇü ÀÔ·ÂÄ­ (h54, s18 bold)
            Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
            GuiControl, SSOKCalc:Font, SSOK_CalcInput1
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y110 w430 h54
            GuiControl, SSOKCalc:Show, SSOK_CalcInput1

            SSOK_CalcSetPrecisionVisible(true)
            GuiControl, SSOKCalc:Move, SSOK_CalcPrecisionLabel, y205
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec0, y204
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec1, y204
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec2, y204
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec4, y204

            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y230
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y250 h134
            GuiControl, SSOKCalc:, SSOK_CalcHelp, ¿¹: 5,000 * 2°³ * 4ÁÖ=  ¶Ç´Â  (1,000 + 2,000) * 10
            GuiControl, SSOKCalc:, SSOK_CalcPrompt1, °è»ê ¼ö½Ä ¶Ç´Â ±Ý¾× ÀÔ·Â:
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 w430
            GuiControl, SSOKCalc:Hide, SSOK_CalcPrompt2
            GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
            GuiControlGet, vIn1, SSOKCalc:, SSOK_CalcInput1
            if (RegExMatch(vIn1, "^\s*\d{4}[./-]\d{1,2}"))
                GuiControl, SSOKCalc:, SSOK_CalcInput1,
        }
        else if (SSOK_CalcMode = "vat")
        {
            ; VAT °è»ê: ´ëÇü ÀÔ·ÂÄ­ (h54, s18 bold)
            Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
            GuiControl, SSOKCalc:Font, SSOK_CalcInput1
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y110 w430 h54
            GuiControl, SSOKCalc:Show, SSOK_CalcInput1

            SSOK_CalcSetPrecisionVisible(false)
            GuiControl, SSOKCalc:Text, SSOK_CalcCalculateBtn, VAT °è»ê (Enter)
            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y208
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y228 h156
            GuiControl, SSOKCalc:, SSOK_CalcHelp, % "VAT °è»ê: ±Ý¾×À» ÀÔ·ÂÇÏ¸é °ø±Þ°¡¾×(¿ø°¡)°ú ºÎ°¡¼¼(10%)¸¦ Áï½Ã ÀÚµ¿ °è»êÇÕ´Ï´Ù."
            GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ±Ý¾× ÀÔ·Â (¿¹: 10,000):
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 w430
            GuiControl, SSOKCalc:Hide, SSOK_CalcPrompt2
            GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
            GuiControlGet, vIn1, SSOKCalc:, SSOK_CalcInput1
            if (Trim(vIn1) = "" || !RegExMatch(vIn1, "\d+"))
                GuiControl, SSOKCalc:, SSOK_CalcInput1, 10,000
        }
        else if (SSOK_CalcMode = "procure")
        {
            Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
            GuiControl, SSOKCalc:Font, SSOK_CalcInput1
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y110 w430 h54
            GuiControl, SSOKCalc:Show, SSOK_CalcInput1

            SSOK_CalcSetPrecisionVisible(false)
            GuiControl, SSOKCalc:Text, SSOK_CalcCalculateBtn, Á¶´Þ¼ö¼ö·á °è»ê (Enter)
            GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x12 y196 w295 h28
            GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x317 y196 w125 h28
            GuiControl, SSOKCalc:Show, SSOK_CalcProcureRad1
            GuiControl, SSOKCalc:Show, SSOK_CalcProcureRad2
            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y230
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y250 h134
            GuiControl, SSOKCalc:, SSOK_CalcHelp, % "Á¶´Þ¼ö¼ö·á: °è¾à(±¸¸Å) ±Ý¾×À» ³Ö°í °è¾à ¹æ½ÄÀ» ¼±ÅÃÇÏ¸é Á¶´ÞÃ» ¼ö¼ö·á¸¦ Áï½Ã °è»êÇÕ´Ï´Ù."
            GuiControl, SSOKCalc:, SSOK_CalcPrompt1, °è¾à(±¸¸Å) ±Ý¾× ÀÔ·Â (¿¹: 30,000,000 ¶Ç´Â 3000¸¸):
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 w430
            GuiControl, SSOKCalc:Hide, SSOK_CalcPrompt2
            GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
            GuiControlGet, vIn1, SSOKCalc:, SSOK_CalcInput1
            if (Trim(vIn1) = "" || !RegExMatch(vIn1, "\d+"))
                GuiControl, SSOKCalc:, SSOK_CalcInput1, 30,000,000
        }
        else
        {
            ; ³¯Â¥¡¤¿äÀÏ, ¸¸³ªÀÌ, ±Ù¹«½Ã°£, ÀÔÂû°ø°í: 2°³ ´ëÇü ÀÔ·ÂÄ­ (h54, s15 bold)
            Gui, SSOKCalc:Font, s15 bold c173F52, Malgun Gothic
            GuiControl, SSOKCalc:Font, SSOK_CalcInput1
            GuiControl, SSOKCalc:Font, SSOK_CalcInput2
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y110 w208 h54
            GuiControl, SSOKCalc:Move, SSOK_CalcInput2, x234 y110 w208 h54

            SSOK_CalcSetPrecisionVisible(false)
            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y208
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y228 h156
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 w208
            GuiControl, SSOKCalc:Show, SSOK_CalcPrompt2
            GuiControl, SSOKCalc:Show, SSOK_CalcInput2

            if (SSOK_CalcMode = "date")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Show, SSOK_CalcDate_Start
                GuiControl, SSOKCalc:Move, SSOK_CalcDate_Start, x12 y110 w208 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcInput2
                Gui, SSOKCalc:Font, s13 bold c173F52, Malgun Gothic
                GuiControl, SSOKCalc:Font, SSOK_CalcInput2
                GuiControl, SSOKCalc:Move, SSOK_CalcInput2, x234 y110 w208 h42

                GuiControl, SSOKCalc:, SSOK_CalcHelp, ³¯Â¥¡¤¿äÀÏ °è»ê: ³¯Â¥¿Í ¿äÀÏÀ» È®ÀÎÇÏ°Å³ª ±â°£(+100ÀÏ µî)À» °è»êÇÕ´Ï´Ù.
                GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ½ÃÀÛÀÏÀÚ:
                GuiControl, SSOKCalc:, SSOK_CalcPrompt2, Á¾·áÀÏÀÚ ¶Ç´Â ÀÏ¼ö (¿¹: +100):

                ; ÀÎÁ¤·ü ÄÁÆ®·Ñ Ç¥½Ã ¹× ¹öÆ°/°á°úÃ¢ ÀÌµ¿
                GuiControl, SSOKCalc:Show, SSOK_CalcRateLabel
                GuiControl, SSOKCalc:Show, SSOK_CalcRate
                GuiControl, SSOKCalc:Show, SSOK_CalcRateUnit
                GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x12 y190 w295 h28
                GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x317 y190 w125 h28
                GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y222
                GuiControl, SSOKCalc:Move, SSOK_CalcResult, y242 h142
            }
            else if (SSOK_CalcMode = "age")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
                GuiControl, SSOKCalc:Show, SSOK_CalcAge_Birth
                GuiControl, SSOKCalc:Move, SSOK_CalcAge_Birth, x12 y110 w208 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcAge_Ref
                GuiControl, SSOKCalc:Move, SSOK_CalcAge_Ref, x234 y110 w208 h42

                GuiControl, SSOKCalc:, SSOK_CalcHelp, ³ªÀÌ.ÅðÁ÷: »ý³â¿ùÀÏÀ» ³ÖÀ¸¸é ¸¸ ³ªÀÌ ¹× °ø¹«¿ø/°ø¹«Á÷ Á¤³âÅðÁ÷ÀÏÀÌ °è»êµË´Ï´Ù.
                GuiControl, SSOKCalc:, SSOK_CalcPrompt1, »ý³â¿ùÀÏ:
                GuiControl, SSOKCalc:, SSOK_CalcPrompt2, ±âÁØÀÏ:
            }
            else if (SSOK_CalcMode = "workday")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
                GuiControl, SSOKCalc:Show, SSOK_CalcWork_Start
                GuiControl, SSOKCalc:Move, SSOK_CalcWork_Start, x12 y110 w208 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcWork_End
                GuiControl, SSOKCalc:Move, SSOK_CalcWork_End, x234 y110 w208 h42

                GuiControl, SSOKCalc:, SSOK_CalcHelp, ±Ù¹«½Ã°£ °è»ê: ½ÃÀÛÀÏ½Ã¿Í Á¾·áÀÏ½Ã¸¦ ¼±ÅÃ/ÀÔ·ÂÇÏ¸é ÃÑ ±Ù¹«½Ã°£À» 1ºÐ ´ÜÀ§·Î Á¤È®È÷ °è»êÇÕ´Ï´Ù.
                GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ½ÃÀÛ½Ã°£ (ÀÏ½Ã ¼±ÅÃ):
                GuiControl, SSOKCalc:, SSOK_CalcPrompt2, Á¾·á½Ã°£ (ÀÏ½Ã ¼±ÅÃ):
            }
            else if (SSOK_CalcMode = "bid")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Show, SSOK_CalcBid_Date
                GuiControl, SSOKCalc:Move, SSOK_CalcBid_Date, x12 y110 w208 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcInput2
                Gui, SSOKCalc:Font, s13 bold c173F52, Malgun Gothic
                GuiControl, SSOKCalc:Font, SSOK_CalcInput2
                GuiControl, SSOKCalc:Move, SSOK_CalcInput2, x234 y110 w208 h42

                GuiControl, SSOKCalc:, SSOK_CalcHelp, ÀÔÂû°ø°í: °ø°íÀÏ¡¤¸¶°¨ÀÏ ºÒ»êÀÔ / 3ÀÏ(¼ø¼ö ÆòÀÏ), 5ÀÏ¡¤7ÀÏ µî(°øÈÞÀÏ Æ÷ÇÔ, ¸»ÀÏ ¼ø¿¬)
                GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ÀÔÂû°ø°íÀÏ:
                GuiControl, SSOKCalc:, SSOK_CalcPrompt2, °ø°í ±â°£ (¿¹: 5ÀÏ ¶Ç´Â 3ÀÏ):
                GuiControlGet, vIn2, SSOKCalc:, SSOK_CalcInput2
                if (Trim(vIn2) = "")
                    GuiControl, SSOKCalc:, SSOK_CalcInput2, 5ÀÏ
            }
        }
    }

    if (SSOK_CalcMode != "budget")
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcCalculateBtn
    else
    {
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcBudgetLabel
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcBudgetBtn1
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcBudgetBtn2
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcBudgetBtn3
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcBudgetBtn4
        GuiControl, SSOKCalc:+Redraw, SSOK_CalcBudgetBtn5
    }
    GuiControl, SSOKCalc:+Redraw, SSOK_CalcCopyBtn
    GuiControl, SSOKCalc:+Redraw, SSOK_CalcResultLabel
    GuiControl, SSOKCalc:+Redraw, SSOK_CalcResult

    ; 3. ÀÔ·Â°ªÀÌ ÀÖ°í ÇØ´ç ¸ðµå¿¡ ºÎÇÕÇÏ¸é Áï½Ã ´Ù½Ã °è»ê
    if (SSOK_CalcMode = "date" || SSOK_CalcMode = "age" || SSOK_CalcMode = "bid" || SSOK_CalcMode = "workday")
    {
        Gosub, SSOK_CalcCalculate
    }
    else
    {
        GuiControlGet, curIn1, SSOKCalc:, SSOK_CalcInput1
        curIn1 := Trim(curIn1)
        if (curIn1 != "")
        {
            if (SSOK_CalcMode = "expr" || SSOK_CalcMode = "budget" || SSOK_CalcMode = "vat")
                Gosub, SSOK_CalcCalculate
        }
    }

    ; ±Ù¹«½Ã°£ ¸ðµå¿¡¼­´Â Ç×»ó °á°úÃ¢ ÆùÆ®¸¦ Ç¥ÁØ ÆùÆ®·Î À¯Áö
    if (SSOK_CalcMode = "workday")
        Gui, SSOKCalc:Font, s10 norm c006C73, Malgun Gothic

    if (SSOK_CalcMode != "date" && SSOK_CalcMode != "age" && SSOK_CalcMode != "bid" && SSOK_CalcMode != "workday")
        GuiControl, SSOKCalc:Focus, SSOK_CalcInput1
    else if (SSOK_CalcMode = "workday")
        GuiControl, SSOKCalc:Focus, SSOK_CalcWork_Start
return

SSOK_CalcUpdateModeTabs:
    activeIdx := (SSOK_CalcMode = "expr") ? 1 : (SSOK_CalcMode = "date") ? 2 : (SSOK_CalcMode = "age") ? 3 : (SSOK_CalcMode = "workday") ? 4 : (SSOK_CalcMode = "bid") ? 5 : (SSOK_CalcMode = "budget") ? 6 : (SSOK_CalcMode = "vat") ? 7 : 8
    tabNamesList := ["°è»ê±â", "³¯Â¥¡¤¿äÀÏ", "³ªÀÌ.ÅðÁ÷", "±Ù¹«½Ã°£", "ÀÔÂû°ø°í", "¿¹»ê »êÃâ³»¿ª", "VAT °è»ê", "Á¶´Þ¼ö¼ö·á"]
    Loop, 8
    {
        tIdx := A_Index
        tName := tabNamesList[tIdx]
        if (tIdx = activeIdx)
        {
            GuiControl, SSOKCalc:, SSOK_CalcTab%tIdx%, 1
            GuiControl, SSOKCalc:Text, SSOK_CalcTab%tIdx%, % "¡Ü " . tName
        }
        else
        {
            GuiControl, SSOKCalc:, SSOK_CalcTab%tIdx%, 0
            GuiControl, SSOKCalc:Text, SSOK_CalcTab%tIdx%, %tName%
        }
    }
return

SSOK_CalcModeExpression:
    SSOK_CalcMode := "expr"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcModeDate:
    SSOK_CalcMode := "date"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcModeAge:
    SSOK_CalcMode := "age"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcModeWorkday:
    SSOK_CalcMode := "workday"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcModeBid:
    SSOK_CalcMode := "bid"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcModeBudget:
    SSOK_CalcMode := "budget"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcModeVat:
    SSOK_CalcMode := "vat"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcModeProcure:
    SSOK_CalcMode := "procure"
    Gosub, SSOK_CalcApplyModeUI
    GuiControl, SSOKCalc:Focus, SSOK_CalcInput1
return

SSOK_CalcProcureTypeChanged:
    Gui, SSOKCalc:Submit, NoHide
    GuiControl, SSOKCalc:Text, SSOK_CalcProcureRad1, % SSOK_CalcProcureRad1 ? "¡Ü ³»ÀÚ±¸¸Å ÃÑ¾×°è¾à" : "³»ÀÚ±¸¸Å ÃÑ¾×°è¾à"
    GuiControl, SSOKCalc:Text, SSOK_CalcProcureRad2, % SSOK_CalcProcureRad2 ? "¡Ü Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç°" : "Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç°"
    if (SSOK_CalcMode = "procure")
        Gosub, SSOK_CalcCalculate
return
SSOK_CalcCopyResult:
    Gui, SSOKCalc:Submit, NoHide
    if (SSOK_CalcResult != "")
    {
        Clipboard := SSOK_CalcResult
        ToolTip, °á°ú¸¦ Å¬¸³º¸µå¿¡ º¹»çÇß½À´Ï´Ù.
        SetTimer, SSOK_CalcRemoveToolTip, -900
    }
return

SSOK_CalcRemoveToolTip:
    ToolTip
return

SSOK_CalcPrecisionChanged:
    Gui, SSOKCalc:Submit, NoHide
    SSOK_CalcPrecision := SSOK_CalcRadPrec4 ? 4 : SSOK_CalcRadPrec2 ? 3 : SSOK_CalcRadPrec1 ? 2 : 1
    if (SSOK_CalcMode = "expr")
        Gosub, SSOK_CalcCalculate
return

SSOK_CalcShowPrecision:
    SSOK_CalcSetPrecisionVisible(true)
return

SSOK_CalcHidePrecision:
    SSOK_CalcSetPrecisionVisible(false)
return

SSOK_CalcSetPrecisionVisible(show)
{
    cmd := show ? "Show" : "Hide"
    GuiControl, SSOKCalc:%cmd%, SSOK_CalcPrecisionLabel
    GuiControl, SSOKCalc:%cmd%, SSOK_CalcRadPrec0
    GuiControl, SSOKCalc:%cmd%, SSOK_CalcRadPrec1
    GuiControl, SSOKCalc:%cmd%, SSOK_CalcRadPrec2
    GuiControl, SSOKCalc:%cmd%, SSOK_CalcRadPrec4
}

SSOK_CalcInput1Changed:
    if (SSOK_CalcFormatting)
        return
    if (SSOK_CalcMode = "date" || SSOK_CalcMode = "age" || SSOK_CalcMode = "workday" || SSOK_CalcMode = "bid")
        return

    GuiControlGet, curVal, SSOKCalc:, SSOK_CalcInput1
    if (curVal = "" || !RegExMatch(curVal, "\d"))
        return

    ; Ä¿¼­ À§Ä¡ ¹× Ä¿¼­ ¾Õ ¼ýÀÚ °³¼ö º¸Á¸
    selStart := 0, selEnd := 0
    if (SSOK_CalcInput1Hwnd)
        DllCall("SendMessage", "Ptr", SSOK_CalcInput1Hwnd, "UInt", 0x00B0, "UIntP", selStart, "UIntP", selEnd)

    subBefore := SubStr(curVal, 1, selStart)
    digitsBefore := StrLen(RegExReplace(subBefore, "[^0-9]", ""))

    newVal := SSOK_CalcFormatInputAmount(curVal)
    if (newVal != curVal)
    {
        SSOK_CalcFormatting := true
        GuiControl, SSOKCalc:, SSOK_CalcInput1, %newVal%

        ; »õ Ä¿¼­ À§Ä¡ º¹¿ø
        newLen := StrLen(newVal)
        newCaret := 0
        dCount := 0
        Loop, %newLen%
        {
            c := SubStr(newVal, A_Index, 1)
            if (c ~= "[0-9]")
                dCount++
            if (dCount = digitsBefore)
            {
                newCaret := A_Index
                break
            }
        }
        if (digitsBefore = 0)
            newCaret := 0
        else if (dCount < digitsBefore)
            newCaret := newLen

        if (SSOK_CalcInput1Hwnd)
            DllCall("SendMessage", "Ptr", SSOK_CalcInput1Hwnd, "UInt", 0x00B1, "UInt", newCaret, "UInt", newCaret)
        SSOK_CalcFormatting := false
    }
return

SSOK_CalcDatePickChanged:
    Gosub, SSOK_CalcCalculate
return

SSOK_CalcCalculate:
    Gui, SSOKCalc:Submit, NoHide
    SSOK_CalcPrecision := SSOK_CalcRadPrec4 ? 4 : SSOK_CalcRadPrec2 ? 3 : SSOK_CalcRadPrec1 ? 2 : 1
    GuiControlGet, in1, SSOKCalc:, SSOK_CalcInput1
    GuiControlGet, in2, SSOKCalc:, SSOK_CalcInput2
    in1 := Trim(in1, " `t`r`n")
    in2 := Trim(in2, " `t`r`n")

    if (SSOK_CalcMode = "date")
    {
        FormatTime, in1, %SSOK_CalcDate_Start%, yyyy-MM-dd
    }
    else if (SSOK_CalcMode = "age")
    {
        FormatTime, in1, %SSOK_CalcAge_Birth%, yyyy-MM-dd
        FormatTime, in2, %SSOK_CalcAge_Ref%, yyyy-MM-dd
    }
    else if (SSOK_CalcMode = "bid")
    {
        FormatTime, in1, %SSOK_CalcBid_Date%, yyyy-MM-dd
    }
    else if (SSOK_CalcMode = "workday")
    {
        FormatTime, in1, %SSOK_CalcWork_Start%, yyyy-MM-dd HH:mm
        FormatTime, in2, %SSOK_CalcWork_End%, yyyy-MM-dd HH:mm
    }

    if (in1 = "" && in2 = "")
    {
        GuiControl, SSOKCalc:, SSOK_CalcResult, °ªÀ» ÀÔ·ÂÇÏ¼¼¿ä.
        return
    }

    result := ""

    ; 1. ÀÔÂû°ø°í ¸ðµå
    if (SSOK_CalcMode = "bid")
    {
        term := (in2 != "") ? in2 : "5ÀÏ"
        query := in1 . ", " . term
        result := SSOK_CalcBid(query)
    }
    ; 2. ¸¸³ªÀÌ ¸ðµå
    else if (SSOK_CalcMode = "age")
    {
        query := (in2 != "") ? (in1 . ", " . in2) : in1
        result := SSOK_CalcAge(query)
    }
    ; 3. ±Ù¹«ÀÏ ¸ðµå
    else if (SSOK_CalcMode = "workday")
    {
        result := SSOK_CalcWorkHours(in1, in2)
    }
    ; 4. ´Þ·Â¡¤±â°£ ¸ðµå
    else if (SSOK_CalcMode = "date")
    {
        GuiControlGet, vRate, SSOKCalc:, SSOK_CalcRate
        result := SSOK_CalcDate(in1, in2, vRate)
    }
    ; 5. ¿¹»ê »êÃâ³»¿ª ¸ðµå
    else if (SSOK_CalcMode = "budget")
    {
        cat := (SSOK_CalcBudgetCat != "") ? SSOK_CalcBudgetCat : "±³À°¿î¿µºñ"
        result := SSOK_CalcGetBudgetBreakdown(cat, in1, autoFormula)
        numStr := RegExReplace(in1, "[^0-9]", "")
        amt := Round(numStr + 0)
        if (amt < 1000 && amt > 0)
            amt := amt * 1000
        else if (amt >= 1000)
            amt := Round(amt / 1000) * 1000
        if (amt > 0)
            GuiControl, SSOKCalc:, SSOK_CalcInput1, % SSOK_CalcAddCommas(amt)
    }
    ; 6. VAT °è»ê ¸ðµå
    else if (SSOK_CalcMode = "vat")
    {
        result := SSOK_CalcVat(in1)
    }
    ; 7. Á¶´Þ¼ö¼ö·á ¸ðµå
    else if (SSOK_CalcMode = "procure")
    {
        procureType := SSOK_CalcProcureRad2 ? 2 : 1
        result := SSOK_CalcProcure(in1, procureType)
    }
    ; 7. ¼ö½Ä °è»ê ¸ðµå
    else
    {
        input := in1
        cleanFormula := ""
        val := SSOK_CalcExpression(input, cleanFormula)
        if (val != "" && val ~= "^-?[0-9]+(\.[0-9]+)?$")
        {
            formattedVal := SSOK_CalcFormatNumber(val + 0)
            if RegExMatch(cleanFormula, "[\+\*/]|(?<!^)\-")
            {
                formattedFormula := SSOK_CalcFormatFormula(cleanFormula)
                result := formattedFormula . " = " . formattedVal
            }
            else
                result := formattedVal
        }
        else
            result := val
    }

    SSOK_CalcSetResult(result)
return

SSOK_CalcSetResult(result)
{
    global SSOK_CalcResult, SSOK_CalcResultHwnd
    if (result = "")
        result := "°è»ê °á°ú°¡ ¾ø½À´Ï´Ù. ÀÔ·Â°ªÀ» È®ÀÎÇÏ¼¼¿ä."

    result := StrReplace(result, "`r`n", "`n")
    result := StrReplace(result, "`n", "`r`n")

    SSOK_CalcResult := result
    GuiControl, SSOKCalc:, SSOK_CalcResult, %result%
    GuiControl, SSOKCalc:Text, SSOK_CalcResult, %result%
    if (SSOK_CalcResultHwnd)
        DllCall("user32\SetWindowText", "Ptr", SSOK_CalcResultHwnd, "Str", result)
    GuiControl, SSOKCalc:+Redraw, SSOK_CalcResult
}

SSOK_CalcBudgetBtnClick:
    GuiControlGet, in1, SSOKCalc:, SSOK_CalcInput1
    btn := A_GuiControl
    cat := (btn = "SSOK_CalcBudgetBtn1") ? "±³À°¿î¿µºñ"
        : (btn = "SSOK_CalcBudgetBtn2") ? "¿î¿µ¼ö´ç"
        : (btn = "SSOK_CalcBudgetBtn3") ? "ÀÏ¹Ý¼ö¿ëºñ"
        : (btn = "SSOK_CalcBudgetBtn4") ? "¾÷¹«ÃßÁøºñ"
        : "ºñÇ°ºñ"
    SSOK_CalcBudgetCat := cat
    res := SSOK_CalcGetBudgetBreakdown(cat, in1, autoFormula)
    numStr := RegExReplace(in1, "[^0-9]", "")
    amt := Round(numStr + 0)
    if (amt < 1000 && amt > 0)
        amt := amt * 1000
    else if (amt >= 1000)
        amt := Round(amt / 1000) * 1000
    if (amt > 0)
        GuiControl, SSOKCalc:, SSOK_CalcInput1, % SSOK_CalcAddCommas(amt)
    SSOK_CalcSetResult(res)
return
SSOK_CalcExpression(input, ByRef cleanFormula := "")
{
    s := Trim(input)

    ; °öÇÏ±â/³ª´©±â ±âÈ£ ¹× °ýÈ£/½°Ç¥ Á¤µ·
    s := StrReplace(s, "¡¿", "*")
    s := StrReplace(s, "¡À", "/")
    s := StrReplace(s, "[", "(")
    s := StrReplace(s, "]", ")")
    s := StrReplace(s, "{", "(")
    s := StrReplace(s, "}", ")")
    s := StrReplace(s, ",", "")

    ; ¼ýÀÚ¿Í ¼ýÀÚ »çÀÌÀÇ x/X ¸¦ °öÇÏ±â * ·Î º¯È¯
    s := RegExReplace(s, "(?i)(\d|\))\s*x\s*(\d|\()", "$1*$2")

    ; ´ÜÀ§ ¹× ºÒÇÊ¿ä ¹®ÀÚ Á¦°Å
    s := RegExReplace(s, "[^0-9\.\+\-\*/\(\)=]", "")

    ; µîÈ£(=) Á¦°Å
    s := StrReplace(s, "=")

    ; ¿¬¼Ó ºÎÈ£ Á¤±ÔÈ­
    s := StrReplace(s, "--", "+")
    s := StrReplace(s, "+-", "-")
    s := StrReplace(s, "-+", "-")
    s := StrReplace(s, "++", "+")

    if (s = "")
        return "¼ö½ÄÀ» ÀÔ·ÂÇÏ¼¼¿ä."

    openCnt := 0
    closeCnt := 0
    Loop, Parse, s
    {
        if (A_LoopField = "(")
            openCnt++
        else if (A_LoopField = ")")
            closeCnt++
    }

    if (openCnt != closeCnt)
    {
        s := StrReplace(s, "(", "")
        s := StrReplace(s, ")", "")
    }

    cleanFormula := s

    v := SSOK_CalcParseExpression(s)
    if (v = "__ERROR__")
        return "¼ö½ÄÀ» È®ÀÎÇÏ¼¼¿ä."

    return v
}

SSOK_CalcFormatFormula(expr)
{
    out := ""
    pos := 1
    while RegExMatch(expr, "O)(\d+(?:\.\d+)?)|([^\d\.]+)", m, pos)
    {
        num := m.Value(1)
        nonNum := m.Value(2)
        if (num != "")
        {
            dotPos := InStr(num, ".")
            if (dotPos)
            {
                intPart := SubStr(num, 1, dotPos - 1)
                fracPart := SubStr(num, dotPos)
                out .= SSOK_CalcAddCommas(intPart) . fracPart
            }
            else
                out .= SSOK_CalcAddCommas(num)
        }
        else
            out .= nonNum
        if (!m || m.Len(0) <= 0)
            break
        pos := m.Pos(0) + m.Len(0)
    }
    return (out != "") ? out : expr
}

SSOK_CalcFormatInputAmount(text)
{
    ; ³¯Â¥/½Ã°£ Æ÷¸ËÀº º¯È¯ Á¦¿Ü (¿¹: 2026-09-08 08:30)
    if (RegExMatch(text, "^\s*\d{4}[-./]\d{1,2}"))
        return text
    text := RegExReplace(text, "¿ø\s*$", "")
    cleanText := RegExReplace(text, "(?<=\d),(?=\d)", "")
    return SSOK_CalcFormatFormula(cleanText)
}

SSOK_CalcParseExpression(s)
{
    global SSOK_CalcExpr, SSOK_CalcPos
    SSOK_CalcExpr := s
    SSOK_CalcPos := 1
    v := SSOK_CalcParseAddSub()
    if (v = "__ERROR__")
        return "__ERROR__"
    if (SSOK_CalcPos <= StrLen(SSOK_CalcExpr))
        return "__ERROR__"
    return v
}

SSOK_CalcParseAddSub()
{
    global SSOK_CalcExpr, SSOK_CalcPos
    v := SSOK_CalcParseMulDiv()
    if (v = "__ERROR__")
        return "__ERROR__"
    Loop
    {
        op := SubStr(SSOK_CalcExpr, SSOK_CalcPos, 1)
        if (op != "+" && op != "-")
            break
        SSOK_CalcPos++
        r := SSOK_CalcParseMulDiv()
        if (r = "__ERROR__")
            return "__ERROR__"
        if (op = "+")
            v := v + r
        else
            v := v - r
    }
    return v
}

SSOK_CalcParseMulDiv()
{
    global SSOK_CalcExpr, SSOK_CalcPos
    v := SSOK_CalcParseUnary()
    if (v = "__ERROR__")
        return "__ERROR__"
    Loop
    {
        op := SubStr(SSOK_CalcExpr, SSOK_CalcPos, 1)
        if (op != "*" && op != "/")
            break
        SSOK_CalcPos++
        r := SSOK_CalcParseUnary()
        if (r = "__ERROR__")
            return "__ERROR__"
        if (op = "/" && r = 0)
            return "__ERROR__"
        if (op = "*")
            v := v * r
        else
            v := v / r
    }
    return v
}

SSOK_CalcParseUnary()
{
    global SSOK_CalcExpr, SSOK_CalcPos
    ch := SubStr(SSOK_CalcExpr, SSOK_CalcPos, 1)
    if (ch = "+" || ch = "-")
    {
        SSOK_CalcPos++
        v := SSOK_CalcParseUnary()
        if (v = "__ERROR__")
            return "__ERROR__"
        if (ch = "-")
            return -v
        return v
    }
    if (ch = "(")
    {
        SSOK_CalcPos++
        v := SSOK_CalcParseAddSub()
        if (SubStr(SSOK_CalcExpr, SSOK_CalcPos, 1) != ")")
            return "__ERROR__"
        SSOK_CalcPos++
        return v
    }
    startPos := SSOK_CalcPos
    dotCount := 0
    while (SSOK_CalcPos <= StrLen(SSOK_CalcExpr))
    {
        ch := SubStr(SSOK_CalcExpr, SSOK_CalcPos, 1)
        if (ch >= "0" && ch <= "9")
        {
            SSOK_CalcPos++
            continue
        }
        if (ch = ".")
        {
            dotCount++
            if (dotCount > 1)
                return "__ERROR__"
            SSOK_CalcPos++
            continue
        }
        break
    }
    if (SSOK_CalcPos = startPos)
        return "__ERROR__"
    numText := SubStr(SSOK_CalcExpr, startPos, SSOK_CalcPos - startPos)
    return numText + 0
}

SSOK_CalcFormatNumber(v)
{
    global SSOK_CalcPrecision
    ; 1=Á¤¼ö ¹Ý¿Ã¸², 2=¼Ò¼ö 1ÀÚ¸®(*.1), 3=¼Ò¼ö 2ÀÚ¸®(*.12), 4=ÀÚµ¿(ÀüÃ¼ ³¡±îÁö)
    if (SSOK_CalcPrecision = 1)
        return SSOK_CalcFormatFixed(v, 0)
    if (SSOK_CalcPrecision = 2)
        return SSOK_CalcFormatFixed(v, 1)
    if (SSOK_CalcPrecision = 3)
        return SSOK_CalcFormatFixed(v, 2)
    if (SSOK_CalcPrecision = 4)
        return SSOK_CalcFormatAll(v)
    return SSOK_CalcFormatFixed(v, 0)
}

SSOK_CalcFormatFixed(v, decimals)
{
    n := Round(v, decimals)
    if (decimals = 0)
        s := Round(n) . ""
    else
        s := Format("{:." . decimals . "f}", n)
    return SSOK_CalcAddCommas(s)
}

SSOK_CalcFormatAll(v)
{
    s := Round(v, 10) . ""
    if InStr(s, ".")
    {
        s := RTrim(s, "0")
        s := RTrim(s, ".")
    }
    return SSOK_CalcAddCommas(s)
}

SSOK_CalcApplyRate(ymdStr, rate)
{
    rate := RegExReplace(rate, "[^0-9.]", "") + 0
    if (rate = 0 || rate >= 100)
        return ""

    if (!RegExMatch(ymdStr, "(\d+)³â\s*(\d+)¿ù\s*(\d+)ÀÏ", m))
        return ""
    y := m1 + 0, mo := m2 + 0, d := m3 + 0

    ; ±³À°°ø¹«¿ø ¹× °ø¹«¿øº¸¼ö±ÔÁ¤ °æ·ÂÈ¯»êÀ² ±âÁØ (1³â=12¿ù, 1¿ù=30ÀÏ, ÀÏ ´ÜÀ§ ¼Ò¼öÁ¡ Àý»ç)
    totalDays := (y * 360) + (mo * 30) + d
    recDays := Floor(totalDays * (rate / 100))

    rY := Floor(recDays / 360)
    remDays := Mod(recDays, 360)
    rM := Floor(remDays / 30)
    rD := Mod(remDays, 30)

    rateDisplay := (Mod(rate, 1) = 0) ? Round(rate) : rate
    return "[" . rateDisplay . "% Àû¿ë½Ã ÀÎÁ¤·ü:  " . rY . "³â " . rM . "¿ù " . rD . "ÀÏ ]"
}

SSOK_CalcParseAmount(s)
{
    s := Trim(s)
    if RegExMatch(s, "^[0-9, \t]+¿ø?$")
    {
        numStr := RegExReplace(s, "[^0-9]", "")
        return (numStr = "") ? 0 : (numStr + 0)
    }

    total := 0
    clean := RegExReplace(s, "[,\s¿ø]", "")
    if RegExMatch(clean, "(\d+(?:\.\d+)?)¾ï", m)
    {
        total += m1 * 100000000
        clean := RegExReplace(clean, "\d+(?:\.\d+)?¾ï", "")
    }
    if RegExMatch(clean, "(\d+(?:\.\d+)?)Ãµ¸¸", m)
    {
        total += m1 * 10000000
        clean := RegExReplace(clean, "\d+(?:\.\d+)?Ãµ¸¸", "")
    }
    if RegExMatch(clean, "(\d+(?:\.\d+)?)¹é¸¸", m)
    {
        total += m1 * 1000000
        clean := RegExReplace(clean, "\d+(?:\.\d+)?¹é¸¸", "")
    }
    if RegExMatch(clean, "(\d+(?:\.\d+)?)¸¸", m)
    {
        total += m1 * 10000
        clean := RegExReplace(clean, "\d+(?:\.\d+)?¸¸", "")
    }
    if RegExMatch(clean, "(\d+(?:\.\d+)?)Ãµ", m)
    {
        total += m1 * 1000
        clean := RegExReplace(clean, "\d+(?:\.\d+)?Ãµ", "")
    }
    if RegExMatch(clean, "^\d+$")
    {
        total += clean + 0
    }
    return Round(total)
}

SSOK_CalcProcure(input, type := 1)
{
    amt := SSOK_CalcParseAmount(input)
    if (amt <= 0)
        return "°è¾à(±¸¸Å) ±Ý¾×À» ¿Ã¹Ù¸£°Ô ÀÔ·ÂÇÏ¼¼¿ä. (¿¹: 30,000,000¿ø ¶Ç´Â 3000¸¸)"

    typeName := (type = 2) ? "Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç° (´Ü°¡°è¾à)" : "³»ÀÚ±¸¸Å ÃÑ¾×°è¾à"
    detailBody := ""
    feeTotal := 0

    if (type = 1) ; ³»ÀÚ±¸¸Å ÃÑ¾×°è¾à (ÀÏ¹Ý¿ë¿ª Æ÷ÇÔ)
    {
        if (amt <= 20000000)
        {
            feeTotal := 210000
            detailBody .= "- Àû¿ë ¿äÀ²±¸°£: 2Ãµ¸¸ ¿ø ÀÌÇÏ (Á¤¾×)`n"
            detailBody .= "- »êÃâ½Ä: Á¤¾× 210,000¿ø`n"
        }
        else if (amt <= 50000000)
        {
            feeTotal := 530000
            detailBody .= "- Àû¿ë ¿äÀ²±¸°£: 2Ãµ¸¸ ¿ø ÃÊ°ú ~ 5Ãµ¸¸ ¿ø ÀÌÇÏ (Á¤¾×)`n"
            detailBody .= "- »êÃâ½Ä: Á¤¾× 530,000¿ø`n"
        }
        else if (amt <= 100000000)
        {
            feeTotal := Round(amt * 0.0107)
            detailBody .= "- Àû¿ë ¿äÀ²±¸°£: 5Ãµ¸¸ ¿ø ÃÊ°ú ~ 1¾ï ¿ø ÀÌÇÏ (1.07% Á¤·ü)`n"
            detailBody .= "- »êÃâ½Ä: " . SSOK_CalcAddCommas(amt) . "¿ø ¡¿ 1.07% = " . SSOK_CalcAddCommas(feeTotal) . "¿ø`n"
        }
        else ; 1¾ï ¿ø ÃÊ°ú (Ã¼°¨ Àû¿ë)
        {
            detailBody .= "- °è»ê ¹æ½Ä: 1¾ï ¿ø ÃÊ°úºÐ Ã¼°¨ Àû¿ë`n`n"
            detailBody .= "[±¸°£º° »êÃâ ³»¿ª]`n"

            ; 1¾ï ¿ø±îÁö: 1.07% (1,070,000¿ø)
            t1Fee := 1070000
            detailBody .= "- 1¾ï ¿ø±îÁö (1.07%): 100,000,000¿ø ¡¿ 1.07% = 1,070,000¿ø`n"
            formulaSum := "1,070,000¿ø"
            feeTotal += t1Fee

            ; 1¾ï ¿ø ÃÊ°ú ~ 10¾ï ¿ø ÀÌÇÏ (0.76% Ã¼°¨)
            t2Amt := (amt > 1000000000) ? 900000000 : (amt - 100000000)
            t2Fee := Round(t2Amt * 0.0076)
            detailBody .= "- 1¾ï ¿ø ÃÊ°ú ~ 10¾ï ¿ø ÀÌÇÏ (0.76%): " . SSOK_CalcAddCommas(t2Amt) . "¿ø ¡¿ 0.76% = " . SSOK_CalcAddCommas(t2Fee) . "¿ø`n"
            formulaSum .= " + " . SSOK_CalcAddCommas(t2Fee) . "¿ø"
            feeTotal += t2Fee

            ; 10¾ï ¿ø ÃÊ°ú ~ 100¾ï ¿ø ÀÌÇÏ (0.48% Ã¼°¨)
            if (amt > 1000000000)
            {
                t3Amt := (amt > 10000000000) ? 9000000000 : (amt - 1000000000)
                t3Fee := Round(t3Amt * 0.0048)
                detailBody .= "- 10¾ï ¿ø ÃÊ°ú ~ 100¾ï ¿ø ÀÌÇÏ (0.48%): " . SSOK_CalcAddCommas(t3Amt) . "¿ø ¡¿ 0.48% = " . SSOK_CalcAddCommas(t3Fee) . "¿ø`n"
                formulaSum .= " + " . SSOK_CalcAddCommas(t3Fee) . "¿ø"
                feeTotal += t3Fee
            }

            ; 100¾ï ¿ø ÃÊ°ú (0.38% Ã¼°¨)
            if (amt > 10000000000)
            {
                t4Amt := amt - 10000000000
                t4Fee := Round(t4Amt * 0.0038)
                detailBody .= "- 100¾ï ¿ø ÃÊ°ú (0.38%): " . SSOK_CalcAddCommas(t4Amt) . "¿ø ¡¿ 0.38% = " . SSOK_CalcAddCommas(t4Fee) . "¿ø`n"
                formulaSum .= " + " . SSOK_CalcAddCommas(t4Fee) . "¿ø"
                feeTotal += t4Fee
            }

            detailBody .= "- »êÃâ ÇÕ°è: " . formulaSum . " = " . SSOK_CalcAddCommas(feeTotal) . "¿ø`n"
        }
    }
    else ; Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç° (´Ü°¡°è¾à: ÀÏ¹Ý, 3ÀÚ, MAS)
    {
        if (amt <= 1000000000)
        {
            feeTotal := Round(amt * 0.0054)
            detailBody .= "- Àû¿ë ¿äÀ²±¸°£: 10¾ï ¿ø ÀÌÇÏ (0.54% Á¤·ü)`n"
            detailBody .= "- »êÃâ½Ä: " . SSOK_CalcAddCommas(amt) . "¿ø ¡¿ 0.54% = " . SSOK_CalcAddCommas(feeTotal) . "¿ø`n"
        }
        else ; 10¾ï ¿ø ÃÊ°ú (Ã¼°¨ Àû¿ë)
        {
            detailBody .= "- °è»ê ¹æ½Ä: 10¾ï ¿ø ÃÊ°úºÐ Ã¼°¨ Àû¿ë`n`n"
            detailBody .= "[±¸°£º° »êÃâ ³»¿ª]`n"

            ; 10¾ï ¿ø±îÁö: 0.54% (5,400,000¿ø)
            t1Fee := 5400000
            detailBody .= "- 10¾ï ¿ø±îÁö (0.54%): 1,000,000,000¿ø ¡¿ 0.54% = 5,400,000¿ø`n"
            formulaSum := "5,400,000¿ø"
            feeTotal += t1Fee

            ; 10¾ï ¿ø ÃÊ°ú ~ 100¾ï ¿ø ÀÌÇÏ (0.47% Ã¼°¨)
            t2Amt := (amt > 10000000000) ? 9000000000 : (amt - 1000000000)
            t2Fee := Round(t2Amt * 0.0047)
            detailBody .= "- 10¾ï ¿ø ÃÊ°ú ~ 100¾ï ¿ø ÀÌÇÏ (0.47%): " . SSOK_CalcAddCommas(t2Amt) . "¿ø ¡¿ 0.47% = " . SSOK_CalcAddCommas(t2Fee) . "¿ø`n"
            formulaSum .= " + " . SSOK_CalcAddCommas(t2Fee) . "¿ø"
            feeTotal += t2Fee

            ; 100¾ï ¿ø ÃÊ°ú (0.37% Ã¼°¨)
            if (amt > 10000000000)
            {
                t3Amt := amt - 10000000000
                t3Fee := Round(t3Amt * 0.0037)
                detailBody .= "- 100¾ï ¿ø ÃÊ°ú (0.37%): " . SSOK_CalcAddCommas(t3Amt) . "¿ø ¡¿ 0.37% = " . SSOK_CalcAddCommas(t3Fee) . "¿ø`n"
                formulaSum .= " + " . SSOK_CalcAddCommas(t3Fee) . "¿ø"
                feeTotal += t3Fee
            }

            detailBody .= "- »êÃâ ÇÕ°è: " . formulaSum . " = " . SSOK_CalcAddCommas(feeTotal) . "¿ø`n"
        }
    }

    ; ±¹°í±Ý °ü¸®¹ý Á¦47Á¶¿¡ µû¸¥ 10¿ø ¹Ì¸¸ Àý»ç
    finalFee := Floor(feeTotal / 10) * 10
    totalPay := amt + finalFee

    res := "¡á Á¶´Þ¼ö¼ö·á »êÃâ ³»¿ª (" . typeName . ")`n`n"
    res .= "- °è¾à(±¸¸Å)±Ý¾×: " . SSOK_CalcAddCommas(amt) . "¿ø`n"
    res .= detailBody . "`n"
    res .= "¢º Á¶´Þ¼ö¼ö·á: " . SSOK_CalcAddCommas(finalFee) . "¿ø (10¿ø ¹Ì¸¸ Àý»ç)`n"
    res .= "¢º ³³ºÎ ÃÑ¾×(±¸¸Å¾×+¼ö¼ö·á): " . SSOK_CalcAddCommas(totalPay) . "¿ø`n`n"
    res .= "¡Ø Á¶´Þ¼ö¼ö·á´Â ºÎ°¡°¡Ä¡¼¼ ¸éÁ¦ °Å·¡(¿µ¼¼À²/¸éÁ¦) ´ë»óÀÔ´Ï´Ù."
    return res
}
SSOK_CalcAddCommas(s)
{
    sign := ""
    if (SubStr(s, 1, 1) = "-")
    {
        sign := "-"
        s := SubStr(s, 2)
    }
    dot := InStr(s, ".")
    if (dot)
    {
        whole := SubStr(s, 1, dot - 1)
        frac := SubStr(s, dot)
    }
    else
    {
        whole := s
        frac := ""
    }
    if (whole = "")
        whole := "0"
    while RegExMatch(whole, "^(\d+)(\d{3})", m)
        whole := RegExReplace(whole, "^(\d+)(\d{3})", "$1,$2")
    return sign . whole . frac
}

SSOK_CalcIsValidDate(y, m, d)
{
    if (y < 1601 || y > 9999 || m < 1 || m > 12 || d < 1 || d > 31)
        return false
    test := SSOK_CalcMakeDate(y, m, d)
    FormatTime, yy, %test%, yyyy
    FormatTime, mm, %test%, M
    FormatTime, dd, %test%, d
    return (yy = y && mm = m && dd = d)
}

SSOK_CalcGetDate(s, ByRef y, ByRef m, ByRef d)
{
    dStr := SSOK_CalcParseSingleDate(s)
    if (!dStr)
        return false
    y := SubStr(dStr, 1, 4) + 0
    m := SubStr(dStr, 5, 2) + 0
    d := SubStr(dStr, 7, 2) + 0
    return true
}

SSOK_CalcMakeDate(y, m, d)
{
    mm := SubStr("0" . m, -1)
    dd := SubStr("0" . d, -1)
    return y . mm . dd
}

SSOK_CalcParseSingleDate(str)
{
    s := Trim(str, " `t`r`n")
    if (s = "")
        return ""

    ; 0. ¿©·¯ ÁÙÀÌ µé¾î¿Â °æ¿ì(ÁÙ¹Ù²Þ µî) °¡Àå ¸¶Áö¸· À¯È¿ ÁÙ ¼±ÅÃ
    if InStr(s, "`n")
    {
        lines := StrSplit(s, "`n", "`r `t")
        Loop, % lines.Length()
        {
            idx := lines.Length() - A_Index + 1
            cand := Trim(lines[idx], " `t`r`n")
            if (cand != "")
            {
                s := cand
                break
            }
        }
    }

    ; 1. °ýÈ£ ¾ÈÀÇ ¿äÀÏÀÌ³ª ºÎ°¡ Á¤º¸ Á¦°Å (¿¹: (È­), (¸ñ), (¼ö), (¿ù¿äÀÏ) µî)
    s := RegExReplace(s, "\([^)]*\)", "")

    ; 2. ÇÑ±Û ¿äÀÏ ´Üµ¶ Ç¥±â Á¦°Å (¿¹: "2026.1.1. ¼ö¿äÀÏ", "2026-09-09 È­")
    s := RegExReplace(s, "(¿ù|È­|¼ö|¸ñ|±Ý|Åä|ÀÏ)(¿äÀÏ)?", "")

    ; 3. ÇÑ±Û ³â, ¿ù, ÀÏ ±¸ºÐÀÚ¸¦ Á¡(.)À¸·Î Ä¡È¯
    s := RegExReplace(s, "[³â¿ùÀÏ]", ".")

    ; 4. ½½·¡½Ã(/), ´ë½Ã(-), ¾ð´õ¹Ù(_), °ø¹é( )À» Á¡(.)À¸·Î Ä¡È¯
    s := RegExReplace(s, "[/\-_ \t]+", ".")

    ; 5. ¿¬¼ÓµÈ Á¡(..)À» ÇÏ³ª·Î Ãà¼Ò
    s := RegExReplace(s, "\.+", ".")

    ; 6. ¾ÕµÚÀÇ Á¡(.), µîÈ£(=), Æ¯¼ö¹®ÀÚ Á¦°Å
    s := RegExReplace(s, "^[.=]+|[.=]+$", "")

    ; ÇüÅÂ 1: 8ÀÚ¸® ¿¬¼Ó ¼ýÀÚ (¿¹: 20140101)
    if RegExMatch(s, "^([0-9]{4})([0-9]{2})([0-9]{2})$", m)
    {
        y := m1 + 0, mo := m2 + 0, d := m3 + 0
        if SSOK_CalcIsValidDate(y, mo, d)
            return SSOK_CalcMakeDate(y, mo, d)
    }

    ; ÇüÅÂ 2: Á¡À¸·Î ±¸ºÐµÈ ³â.¿ù.ÀÏ (¿¹: 2026.1.1, 2026.09.09, 2026-9.1.)
    if RegExMatch(s, "^([0-9]{4})\.([0-9]{1,2})\.([0-9]{1,2})$", m)
    {
        y := m1 + 0, mo := m2 + 0, d := m3 + 0
        if SSOK_CalcIsValidDate(y, mo, d)
            return SSOK_CalcMakeDate(y, mo, d)
    }

    ; ÇüÅÂ 3: Á¡À¸·Î ±¸ºÐµÈ ³â.¿ù (ÀÏÀÌ »ý·«µÈ °æ¿ì 1ÀÏ·Î °£ÁÖ. ¿¹: 2029.09., 2026.1)
    if RegExMatch(s, "^([0-9]{4})\.([0-9]{1,2})$", m)
    {
        y := m1 + 0, mo := m2 + 0, d := 1
        if SSOK_CalcIsValidDate(y, mo, d)
            return SSOK_CalcMakeDate(y, mo, d)
    }

    return ""
}

SSOK_CalcDateDiffYMD(a, b)
{
    nextB := b
    EnvAdd, nextB, 1, Days
    
    y1 := SubStr(a, 1, 4) + 0
    m1 := SubStr(a, 5, 2) + 0
    d1 := SubStr(a, 7, 2) + 0
    
    ny := SubStr(nextB, 1, 4) + 0
    nm := SubStr(nextB, 5, 2) + 0
    nd := SubStr(nextB, 7, 2) + 0
    
    curY := ny
    curM := nm
    curD := nd
    
    if (curD < d1)
    {
        prevM := curM - 1
        prevY := curY
        if (prevM = 0)
        {
            prevM := 12
            prevY -= 1
        }
        if (prevM = 1 || prevM = 3 || prevM = 5 || prevM = 7 || prevM = 8 || prevM = 10 || prevM = 12)
            dim := 31
        else if (prevM = 4 || prevM = 6 || prevM = 9 || prevM = 11)
            dim := 30
        else
        {
            isLeap := (Mod(prevY, 4) = 0 && (Mod(prevY, 100) != 0 || Mod(prevY, 400) = 0))
            dim := isLeap ? 29 : 28
        }
        curD += dim
        curM -= 1
    }
    
    diffD := curD - d1
    
    if (curM < m1)
    {
        curM += 12
        curY -= 1
    }
    
    diffM := curM - m1
    diffY := curY - y1
    
    return diffY . "³â " . diffM . "¿ù " . diffD . "ÀÏ"
}

SSOK_CalcDateRange(a, b, rate := 100)
{
    if (a > b)
        return "Á¾·áÀÏÀÌ ½ÃÀÛÀÏº¸´Ù ¾Õ¼·´Ï´Ù."
    diff := b
    EnvSub, diff, %a%, Days
    total := diff + 1
    weekdays := 0
    holidays := 0
    cur := a
    Loop, %total%
    {
        FormatTime, wd, %cur%, WDay
        if (wd >= 2 && wd <= 6)
            weekdays++
        else
            holidays++
        EnvAdd, cur, 1, Days
    }
    FormatTime, oa, %a%, yyyy. M. d.(ddd)
    FormatTime, ob, %b%, yyyy. M. d.(ddd)

    ymdStr := SSOK_CalcDateDiffYMD(a, b)

    ; »ç¿ëÀÚ ÁöÁ¤ ¿äÃ» Çü½Ä:
    ; 2025. 1. 1.(¼ö)~2026. 1. 1.(¸ñ), 366ÀÏ
    ;
    ; - 1³â 0¿ù 1ÀÏ
    ;
    ; - ÆòÀÏ: 262ÀÏ  /  ÁÖ¸»(Åä¡¤ÀÏ): 104ÀÏ
    res := oa . "~" . ob . ", " . SSOK_CalcAddCommas(total) . "ÀÏ`n`n"
    res .= "- " . ymdStr . "`n`n"
    res .= "- ÆòÀÏ: " . SSOK_CalcAddCommas(weekdays) . "ÀÏ  /  ÁÖ¸»(Åä¡¤ÀÏ): " . SSOK_CalcAddCommas(holidays) . "ÀÏ"

    rateStr := SSOK_CalcApplyRate(ymdStr, rate)
    if (rateStr != "")
        res .= "`n`n" . rateStr

    return res
}

SSOK_CalcDate(in1, in2 := "", rate := 100)
{
    s1 := Trim(in1, " `t`r`n")
    s2 := Trim(in2, " `t`r`n")

    if (s2 != "")
    {
        ; in2°¡ ¼ýÀÚ(ÀÏ¼ö ¿ÀÇÁ¼Â)ÀÎ °æ¿ì: +100, -50, 100, 100ÀÏ µî
        if RegExMatch(s2, "^([+-]?)\s*([0-9]+)\s*ÀÏ?$", om)
        {
            d1 := SSOK_CalcParseSingleDate(s1)
            if (!d1)
                return "½ÃÀÛ ³¯Â¥¸¦ È®ÀÎÇÏ¼¼¿ä: " . s1
            n := om2 + 0
            if (om1 = "-")
                n := -n
            base := d1
            EnvAdd, base, %n%, Days
            FormatTime, oa, %d1%, yyyy. M. d.(ddd)
            FormatTime, ob, %base%, yyyy. M. d.(ddd)
            signStr := (n >= 0) ? ("+" . n) : ("" . n)
            return oa . " " . signStr . "ÀÏ = " . ob
        }

        ; in2µµ ³¯Â¥ÀÎ °æ¿ì: ±â°£ °è»ê
        d1 := SSOK_CalcParseSingleDate(s1)
        d2 := SSOK_CalcParseSingleDate(s2)
        if (!d1)
            return "½ÃÀÛ ³¯Â¥¸¦ È®ÀÎÇÏ¼¼¿ä: " . s1
        if (!d2)
            return "Á¾·á ³¯Â¥¸¦ È®ÀÎÇÏ¼¼¿ä: " . s2
        return SSOK_CalcDateRange(d1, d2, rate)
    }

    ; in1 ¾È¿¡ ¹üÀ§ ±¸ºÐÀÚ(~, -, to)°¡ ÀÖ´Â °æ¿ì
    if InStr(s1, "~")
    {
        pos := InStr(s1, "~")
        p1 := SubStr(s1, 1, pos - 1)
        p2 := SubStr(s1, pos + 1)
        d1 := SSOK_CalcParseSingleDate(p1)
        d2 := SSOK_CalcParseSingleDate(p2)
        if (d1 && d2)
            return SSOK_CalcDateRange(d1, d2, rate)
    }
    else if InStr(s1, " - ")
    {
        pos := InStr(s1, " - ")
        p1 := SubStr(s1, 1, pos - 1)
        p2 := SubStr(s1, pos + 3)
        d1 := SSOK_CalcParseSingleDate(p1)
        d2 := SSOK_CalcParseSingleDate(p2)
        if (d1 && d2)
            return SSOK_CalcDateRange(d1, d2, rate)
    }

    ; in1 ¾È¿¡ ¿ÀÇÁ¼ÂÀÌ ÀÖ´Â °æ¿ì (¿¹: 2014.1.1 + 100ÀÏ)
    if RegExMatch(s1, "^(.+?)\s*([+-])\s*([0-9]+)\s*ÀÏ?$", om)
    {
        d1 := SSOK_CalcParseSingleDate(om1)
        if (d1)
        {
            n := om3 + 0
            if (om2 = "-")
                n := -n
            base := d1
            EnvAdd, base, %n%, Days
            FormatTime, oa, %d1%, yyyy. M. d.(ddd)
            FormatTime, ob, %base%, yyyy. M. d.(ddd)
            signStr := (n >= 0) ? ("+" . n) : ("" . n)
            return oa . " " . signStr . "ÀÏ = " . ob
        }
    }

    ; ´ÜÀÏ ³¯Â¥
    d1 := SSOK_CalcParseSingleDate(s1)
    if (d1)
    {
        FormatTime, oa, %d1%, yyyy. M. d.(ddd)
        return oa
    }

    return "³¯Â¥ ¿¹: 2014.1.1 / 2014-1-1 / 2014. 1. 1.~2025. 1. 1."
}

SSOK_CalcAge(input)
{
    input := Trim(input, " `t`r`n")
    dates := []

    ; ½°Ç¥(,), ¹°°áÇ¥(~), ÁÙ¹Ù²Þ, " - " µîÀ» ±¸ºÐÀÚ·Î ºÐ¸® ½Ãµµ
    splitStr := RegExReplace(input, "\s+-\s+", ",")
    splitStr := RegExReplace(splitStr, "[\r\n~]+", ",")
    if InStr(splitStr, ",")
    {
        Loop, Parse, splitStr, `,
        {
            field := Trim(A_LoopField, " `t`r`n")
            if (field != "")
            {
                d := SSOK_CalcParseSingleDate(field)
                if (d)
                    dates.Push(d)
            }
        }
    }
    else
    {
        d := SSOK_CalcParseSingleDate(input)
        if (d)
            dates.Push(d)
    }

    ; ¸¸¾à ±¸ºÐÀÚ ºÐ¸®·Î 2°³ ³¯Â¥°¡ ¾È ÀâÈù °æ¿ì(¿¹: °ø¹éÀ¸·Î µÎ ³¯Â¥°¡ ÀÔ·ÂµÈ °æ¿ì µî)
    if (dates.Length() < 2)
    {
        tempDates := []
        pos := 1
        while RegExMatch(input, "O)(\d{4})[³â./\- \t]+(\d{1,2})[¿ù./\- \t]+(\d{1,2})ÀÏ?\.?", m, pos)
        {
            y := m[1] + 0, mo := m[2] + 0, d := m[3] + 0
            if SSOK_CalcIsValidDate(y, mo, d)
                tempDates.Push(SSOK_CalcMakeDate(y, mo, d))
            if (!m || m.Len(0) <= 0)
                break
            pos := m.Pos(0) + m.Len(0)
        }
        if (tempDates.Length() >= dates.Length())
            dates := tempDates
    }

    if (dates.Length() = 0)
    {
        pos := 1
        while RegExMatch(input, "O)(\d{4})(\d{2})(\d{2})", m, pos)
        {
            y := m[1] + 0, mo := m[2] + 0, d := m[3] + 0
            if SSOK_CalcIsValidDate(y, mo, d)
                dates.Push(SSOK_CalcMakeDate(y, mo, d))
            if (!m || m.Len(0) <= 0)
                break
            pos := m.Pos(0) + m.Len(0)
        }
    }
    if (dates.Length() < 1)
        return "»ý³â¿ùÀÏÀ» ÀÔ·ÂÇÏ¼¼¿ä. (¿¹: 1990-05-15 ¶Ç´Â 1990-05-15, 2024-03-01)"
    birthDate := dates[1]
    isCustomBase := (dates.Length() >= 2)
    if (isCustomBase)
        baseDate := dates[2]
    else
    {
        FormatTime, today,, yyyyMMdd
        baseDate := today
    }
    by := SubStr(birthDate, 1, 4) + 0
    bm := SubStr(birthDate, 5, 2) + 0
    bd := SubStr(birthDate, 7, 2) + 0
    ty := SubStr(baseDate, 1, 4) + 0
    tm := SubStr(baseDate, 5, 2) + 0
    td := SubStr(baseDate, 7, 2) + 0
    if (birthDate > baseDate)
        return "»ý³â¿ùÀÏÀÌ ±âÁØÀÏÀÚº¸´Ù ¹Ì·¡ÀÏ ¼ö ¾ø½À´Ï´Ù."
    manAge := ty - by
    isBirthdayPassed := false
    if (tm > bm || (tm = bm && td >= bd))
        isBirthdayPassed := true
    else
        manAge--
    yeonAge := ty - by
    diffDays := baseDate
    EnvSub, diffDays, %birthDate%, Days
    FormatTime, bFmt, %birthDate%, yyyy. M. d.(ddd)
    FormatTime, tFmt, %baseDate%, yyyy. M. d.(ddd)
    res := "[¸¸ ³ªÀÌ] " . manAge . "¼¼ /  [¿¬ ³ªÀÌ] " . yeonAge . "¼¼`n`n"
    res .= "- " . bFmt . "~" . tFmt . "`n"
    res .= "- Ãâ»ý ÈÄ " . SSOK_CalcAddCommas(diffDays + 1) . "ÀÏÂ°"

    ; Á¤³âÅðÁ÷ÀÏ °è»ê (¸¸ 60¼¼, ¸¸ 65¼¼)
    ; 1) °ø¹«¿ø: 1~6¿ù »ýÀÏ -> 6¿ù 30ÀÏ, 7~12¿ù »ýÀÏ -> 12¿ù 31ÀÏ
    g60y := by + 60
    g60d := (bm >= 1 && bm <= 6) ? (g60y . ". 6. 30.") : (g60y . ". 12. 31.")
    g65y := by + 65
    g65d := (bm >= 1 && bm <= 6) ? (g65y . ". 6. 30.") : (g65y . ". 12. 31.")

    ; 2) °ø¹«Á÷: 3~8¿ù »ýÀÏ -> 8¿ù 31ÀÏ, 9~12¿ù »ýÀÏ -> ÀÍ³â 2¿ù ¸»ÀÏ, 1~2¿ù »ýÀÏ -> ´çÇØ 2¿ù ¸»ÀÏ
    w60y := by + 60
    if (bm >= 3 && bm <= 8)
        w60d := w60y . ". 8. 31."
    else if (bm >= 9 && bm <= 12)
    {
        ny := w60y + 1
        febEnd := ((Mod(ny, 4) = 0 && Mod(ny, 100) != 0) || Mod(ny, 400) = 0) ? 29 : 28
        w60d := ny . ". 2. " . febEnd . "."
    }
    else
    {
        febEnd := ((Mod(w60y, 4) = 0 && Mod(w60y, 100) != 0) || Mod(w60y, 400) = 0) ? 29 : 28
        w60d := w60y . ". 2. " . febEnd . "."
    }

    w65y := by + 65
    if (bm >= 3 && bm <= 8)
        w65d := w65y . ". 8. 31."
    else if (bm >= 9 && bm <= 12)
    {
        ny := w65y + 1
        febEnd := ((Mod(ny, 4) = 0 && Mod(ny, 100) != 0) || Mod(ny, 400) = 0) ? 29 : 28
        w65d := ny . ". 2. " . febEnd . "."
    }
    else
    {
        febEnd := ((Mod(w65y, 4) = 0 && Mod(w65y, 100) != 0) || Mod(w65y, 400) = 0) ? 29 : 28
        w65d := w65y . ". 2. " . febEnd . "."
    }

    res .= "`n`n[Á¤³âÅðÁ÷ÀÏ]`n"
    res .= "¡Ü °ø¹«¿ø: ¸¸60¼¼ " . g60d . "  |  ¸¸65¼¼ " . g65d . "`n"
    res .= "¡Ü °ø¹«Á÷: ¸¸60¼¼ " . w60d . "  |  ¸¸65¼¼ " . w65d
    return res
}

SSOK_CalcBid(input)
{
    input := Trim(input)
    period := 5
    bidPart := input
    if InStr(input, ",")
    {
        StringSplit, bp, input, `,
        bidPart := bp1
        if RegExMatch(bp2, "(\d+)", pm)
            period := pm1 + 0
    }
    else if RegExMatch(input, "(\d+)\s*ÀÏ", pm)
    {
        period := pm1 + 0
    }

    bidDate := SSOK_CalcParseSingleDate(bidPart)
    if (!bidDate)
    {
        if RegExMatch(input, "O)(\d{4})[./-](\d{1,2})[./-](\d{1,2})", bm)
            bidDate := SSOK_CalcMakeDate(bm[1]+0, bm[2]+0, bm[3]+0)
    }
    if (!bidDate)
        return "°ø°í ³¯Â¥ Çü½ÄÀ» È®ÀÎÇÏ¼¼¿ä. (¿¹: 2026-09-08, 5ÀÏ)"

    if (period <= 0)
        return "°ø°í ±â°£Àº 1ÀÏ ÀÌ»óÀÌ¾î¾ß ÇÕ´Ï´Ù."

    if (period <= 3)
    {
        ; °ø°í±â°£ 3ÀÏ (3ÀÏ ÀÌÇÏ): °øÈÞÀÏ Á¦¿ÜÇØ¼­ ¼ø¼ö ÆòÀÏ¸¸ Ä«¿îÆ®
        ruleText := "3ÀÏ: °ø°íÀÏ¡¤¸¶°¨ÀÏ Á¦¿Ü, ¼ø¼ö ÆòÀÏ"
        cur := bidDate
        EnvAdd, cur, 1, Days
        counted := 0
        Loop
        {
            d8 := SubStr(cur, 1, 8)
            if (!SSOK_IsKoreaNonWorkday(d8))
                counted++
            if (counted = period)
                break
            EnvAdd, cur, 1, Days
        }
        expireDate := cur
    }
    else
    {
        ; 5ÀÏ, 7ÀÏ µî ÀÌ»ó: °øÈÞÀÏ Æ÷ÇÔ Ä«¿îÆ®
        ruleText := period . "ÀÏ: °ø°íÀÏ¡¤¸¶°¨ÀÏ Á¦¿Ü, °øÈÞÀÏ Æ÷ÇÔ"
        expireDate := bidDate
        EnvAdd, expireDate, %period%, Days
    }

    ; °ø°í±â°£¿¡´Â °ø°íÀÏ°ú ÀÔÂû¼­ Á¦Ãâ¸¶°¨ÀÏ(°³ÂûÀÏ)ÀÌ Æ÷ÇÔµÇÁö ¾ÊÀ¸¹Ç·Î, ¸¸·á ÀÍÀÏºÎÅÍ ¸¶°¨ °¡´É
    closeDate := expireDate
    EnvAdd, closeDate, 1, Days
    isDelayed := false
    Loop
    {
        d8 := SubStr(closeDate, 1, 8)
        if (!SSOK_IsKoreaNonWorkday(d8))
            break
        isDelayed := true
        EnvAdd, closeDate, 1, Days
    }
    FormatTime, bidFmt, %bidDate%, yyyy. M. d.(ddd)
    FormatTime, clsFmt, %closeDate%, yyyy. M. d.(ddd)

    res := "- ÀÔÂû°ø°íÀÏ: " . bidFmt . "`n"
    res .= "- ¹ýÁ¤°ø°í±â°£: " . period . "ÀÏ (" . ruleText . ")`n"
    res .= "- ÀÔÂû¼­ Á¦Ãâ ¸¶°¨ÀÏ:  " . clsFmt
    if (isDelayed)
        res .= "`n`n* ¸¶°¨ÀÏÀÌ Åä¡¤ÀÏ¡¤°øÈÞÀÏ¿¡ ÇØ´çÇÏ¿© ÀÍÀÏ ÆòÀÏ·Î ¼ø¿¬µÊ"
    return res
}

SSOK_CalcWorkdays(input)
{
    input := Trim(input)
    if InStr(input, "~")
        StringSplit, p, input, ~
    else if InStr(input, " - ")
        StringSplit, p, input, -
    else if InStr(input, ",")
        StringSplit, p, input, `,
    else
        StringSplit, p, input, ~
    d1 := SSOK_CalcParseSingleDate(p1)
    d2 := SSOK_CalcParseSingleDate(p2)
    if (!d1 || !d2)
        return "³¯Â¥ Çü½ÄÀ» È®ÀÎÇÏ¼¼¿ä. (¿¹: 2026-09-08 ~ 2026-09-30)"
    a := d1
    b := d2
    if (a > b)
        return "½ÃÀÛÀÏÀÌ Á¾·áÀÏº¸´Ù ´Ê½À´Ï´Ù."
    diff := b
    EnvSub, diff, %a%, Days
    totalDays := diff + 1
    workdays := 0
    holidays := 0
    cur := a
    Loop, %totalDays%
    {
        d8 := SubStr(cur, 1, 8)
        if (SSOK_IsKoreaNonWorkday(d8))
            holidays++
        else
            workdays++
        EnvAdd, cur, 1, Days
    }
    FormatTime, oa, %a%, yyyy. M. d.(ddd)
    FormatTime, ob, %b%, yyyy. M. d.(ddd)
    return "[±Ù¹«ÀÏ °è»ê] ÃÑ " . SSOK_CalcAddCommas(totalDays) . "ÀÏ`n- ½ÇÁ¦ ±Ù¹«ÀÏ: " . SSOK_CalcAddCommas(workdays) . "ÀÏ  /  ÈÞÀÏ(ÁÖ¸»¡¤°øÈÞÀÏ): " . SSOK_CalcAddCommas(holidays) . "ÀÏ`n- ±â°£: " . oa . " ~ " . ob
}
SSOK_CalcWorkHours(in1, in2 := "")
{
    s1 := Trim(in1)
    s2 := Trim(in2)
    p1 := s1
    p2 := s2
    if (p2 = "")
    {
        if InStr(p1, "~")
            StringSplit, sp, p1, ~
        else if InStr(p1, " - ")
            StringSplit, sp, p1, -
        else if InStr(p1, ",")
            StringSplit, sp, p1, `,
        p1 := sp1
        p2 := sp2
    }
    p1 := Trim(p1)
    p2 := Trim(p2)
    if (p1 = "" || p2 = "")
        return "½ÃÀÛ½Ã°£°ú Á¾·á½Ã°£À» ÀÔ·ÂÇÏ¼¼¿ä. (¿¹: 2026-09-08 08:30 ~ 17:30)"

    pr1 := SSOK_CalcParseDateTimeParts(p1)
    pr2 := SSOK_CalcParseDateTimeParts(p2)
    if (!pr1 || !pr2)
        return "½Ã°£ Çü½ÄÀ» È®ÀÎÇÏ¼¼¿ä. (¿¹: 08:30 ¶Ç´Â 2026-09-08 08:30)"

    FormatTime, today8,, yyyyMMdd
    d1 := (pr1.d != "") ? pr1.d : today8
    d2 := (pr2.d != "") ? pr2.d : ""

    if (d2 = "")
    {
        d2 := d1
        mins1 := pr1.h * 60 + pr1.m
        mins2 := pr2.h * 60 + pr2.m
        if (mins2 < mins1)
            EnvAdd, d2, 1, Days
    }

    ts1 := d1 . SubStr("0" . pr1.h, -1) . SubStr("0" . pr1.m, -1) . "00"
    ts2 := d2 . SubStr("0" . pr2.h, -1) . SubStr("0" . pr2.m, -1) . "00"

    diffMins := ts2
    EnvSub, diffMins, %ts1%, Minutes
    if (diffMins < 0)
        diffMins := 0

    days := diffMins // 1440
    rem := Mod(diffMins, 1440)
    hours := rem // 60
    mins := Mod(rem, 60)

    FormatTime, dt1Fmt, %ts1%, yyyy. M. d.(ddd) HH:mm
    FormatTime, dt2Fmt, %ts2%, yyyy. M. d.(ddd) HH:mm
    res := dt1Fmt . " ~ " . dt2Fmt . "`n`n"
    res .= "ÃÑ ±Ù¹«½Ã°£ " . SSOK_CalcAddCommas(diffMins) . "ºÐ`n"
    if (days > 0)
        res .= days . "ÀÏ " . hours . "½Ã°£ " . mins . "ºÐ`n`n"
    else
        res .= hours . "½Ã°£ " . mins . "ºÐ`n`n"
    res .= "10Áø¼ö º¯È¯: " . Format("{:0.4f}", diffMins / 60)
    return res

}

SSOK_CalcDiffMinutes(s1, s2)
{
    p1 := SSOK_CalcParseDateTimeParts(s1)
    p2 := SSOK_CalcParseDateTimeParts(s2)
    if (!p1 || !p2)
        return "__ERROR__"

    d1 := p1.d, h1 := p1.h, m1 := p1.m
    d2 := p2.d, h2 := p2.h, m2 := p2.m

    if (d1 != "" && d2 != "")
    {
        ts1 := d1 . SubStr("0" . h1, -1) . SubStr("0" . m1, -1) . "00"
        ts2 := d2 . SubStr("0" . h2, -1) . SubStr("0" . m2, -1) . "00"
        diff := ts2
        EnvSub, diff, %ts1%, Minutes
        return (diff < 0) ? 0 : diff
    }
    else
    {
        mins1 := h1 * 60 + m1
        mins2 := h2 * 60 + m2
        if (mins2 < mins1)
            totalMins := (mins2 + 1440) - mins1
        else
            totalMins := mins2 - mins1
        return totalMins
    }
}

SSOK_CalcParseDateTimeParts(s)
{
    s := Trim(s)
    datePart := ""
    if RegExMatch(s, "(\d{4}[./-]\d{1,2}[./-]\d{1,2})", dm)
    {
        datePart := SSOK_CalcParseSingleDate(dm1)
        s := StrReplace(s, dm1, "")
    }

    hh := -1
    mi := -1

    if RegExMatch(s, "(\d{1,2})\s*:\s*(\d{2})", tm)
    {
        hh := tm1 + 0
        mi := tm2 + 0
    }
    else if RegExMatch(s, "(\d{1,2})\s*½Ã\s*(\d{1,2})?\s*ºÐ?", tm)
    {
        hh := tm1 + 0
        mi := (tm2 != "") ? (tm2 + 0) : 0
    }
    else if RegExMatch(Trim(s), "^(\d{2})(\d{2})$", tm)
    {
        hh := tm1 + 0
        mi := tm2 + 0
    }
    else if RegExMatch(Trim(s), "^(\d{1,2})$", tm)
    {
        hh := tm1 + 0
        mi := 0
    }

    if (hh < 0 || hh > 23 || mi < 0 || mi > 59)
        return false

    return {d: datePart, h: hh, m: mi}
}




SSOK_CalcVat(input)
{
    s := input
    isAdd := InStr(s, "+")
    numStr := RegExReplace(s, "[^0-9]", "")
    if (numStr = "")
        return "±Ý¾×À» ÀÔ·ÂÇÏ¼¼¿ä. (¿¹: 10,000)"
    amt := Round(numStr + 0)

    supply1 := amt
    vat1 := Round(supply1 * 0.1)
    total1 := supply1 + vat1

    total2 := amt
    supply2 := Round(total2 / 1.1)
    vat2 := total2 - supply2

    if (isAdd)
    {
        return "¡á °ø±Þ°¡¾× + ºÎ°¡¼¼(10%) °¡»ê ½Ã`n - °ø±Þ°¡¾×: " . SSOK_CalcAddCommas(supply1) . "¿ø`n - ºÎ°¡¼¼(10%): " . SSOK_CalcAddCommas(vat1) . "¿ø`n - ÇÕ°è±Ý¾×: " . SSOK_CalcAddCommas(total1) . "¿ø"
    }
    else
    {
        res := "¡á °ø±Þ°¡¾× + ºÎ°¡¼¼ 10% °¡»ê ½Ã`n"
        res .= " - °ø±Þ°¡¾×: " . SSOK_CalcAddCommas(supply1) . "¿ø`n"
        res .= " - ºÎ°¡¼¼(10%): " . SSOK_CalcAddCommas(vat1) . "¿ø`n"
        res .= " - ÇÕ°è±Ý¾×(VATÆ÷ÇÔ): " . SSOK_CalcAddCommas(total1) . "¿ø`n`n"
        res .= "¡á ÇÕ°è±Ý¾×(VATÆ÷ÇÔ)¿¡¼­ °ø±Þ°¡¾×¡¤ºÎ°¡¼¼ ºÐ¸® ½Ã`n"
        res .= " - °ø±Þ°¡¾×: " . SSOK_CalcAddCommas(supply2) . "¿ø`n"
        res .= " - ºÎ°¡¼¼(10%): " . SSOK_CalcAddCommas(vat2) . "¿ø`n"
        res .= " - ÇÕ°è±Ý¾×: " . SSOK_CalcAddCommas(total2) . "¿ø"
        return res
    }
}

SSOK_CalcGetBudgetBreakdown(cat, inputStr, ByRef formulaOut)
{
    numStr := RegExReplace(inputStr, "[^0-9]", "")
    totalAmt := Round(numStr + 0)
    if (totalAmt <= 0)
        totalAmt := 1000000
    else if (totalAmt < 1000)
        totalAmt := totalAmt * 1000
    else
        totalAmt := Round(totalAmt / 1000) * 1000

    formulaOut := ""

    ; 1. ±³À°¿î¿µºñ (¿î¿µ¹°Ç° ±¸¸Å) - ´Ü°¡ 20,000¿ø/10,000¿ø µî
    if (InStr(cat, "±³À°¿î¿µºñ") || InStr(cat, "¿î¿µ¹°Ç°") || InStr(cat, "¹°Ç°"))
    {
        if (Mod(totalAmt, 2) = 0)
        {
            half := totalAmt // 2
            unitPrice := 0
            cnt := 0

            units := [50000, 30000, 25000, 20000, 15000, 10000, 5000, 2000, 1000]
            for idx, u in units
            {
                if (half >= u * 2 && Mod(half, u) = 0)
                {
                    unitPrice := u
                    cnt := half // u
                    break
                }
            }

            if (unitPrice > 0)
            {
                formulaOut := SSOK_CalcAddCommas(unitPrice) . " * " . cnt . " * 2"
                return "- ±³À°È°µ¿ ¿î¿µ¹°Ç° ¹× Àç·á ±¸ÀÔ: " . SSOK_CalcAddCommas(unitPrice) . "¿ø ¡¿ " . cnt . "¸í ¡¿ 2È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
            else
            {
                formulaOut := SSOK_CalcAddCommas(half) . " * 2"
                return "- ±³À°È°µ¿ ¿î¿µ¹°Ç° ±¸ÀÔ: " . SSOK_CalcAddCommas(half) . "¿ø ¡¿ 2Á¾ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
        }
        else
        {
            formulaOut := SSOK_CalcAddCommas(totalAmt) . " * 1"
            return "- ±³À°È°µ¿ ¿î¿µ¹°Ç° ±¸ÀÔ: " . SSOK_CalcAddCommas(totalAmt) . "¿ø ¡¿ 1Á¾ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
    }
    ; 2. ¿î¿µ¼ö´ç (°­»ç¼ö´ç)
    else if (InStr(cat, "¿î¿µ¼ö´ç") || InStr(cat, "°­»ç"))
    {
        if (Mod(totalAmt, 200000) = 0 && (totalAmt // 200000) >= 2)
        {
            cnt := totalAmt // 200000
            formulaOut := "100,000 * 2 * " . cnt
            return "- ¿ÜºÎ Àü¹®°­»ç ¼ö´ç: 100,000¿ø ¡¿ 2½Ã°£ ¡¿ " . cnt . "È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
        else if (Mod(totalAmt, 100000) = 0)
        {
            cnt := totalAmt // 100000
            if (cnt >= 2)
            {
                formulaOut := "50,000 * 2 * " . cnt
                return "- ¿ÜºÎ °­»ç Áöµµ¼ö´ç: 50,000¿ø ¡¿ 2½Ã°£ ¡¿ " . cnt . "È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
            else
            {
                formulaOut := "50,000 * 1 * 2"
                return "- ÀÏ¹Ý°­»ç ¼ö´ç: 50,000¿ø ¡¿ 1½Ã°£ ¡¿ 2È¸ = 100,000¿ø"
            }
        }
        else if (Mod(totalAmt, 50000) = 0)
        {
            cnt := totalAmt // 50000
            if (cnt >= 2)
            {
                formulaOut := "50,000 * 1 * " . cnt
                return "- ÀÏ¹Ý°­»ç ¼ö´ç: 50,000¿ø ¡¿ 1½Ã°£ ¡¿ " . cnt . "È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
            else
            {
                formulaOut := "25,000 * 1 * 2"
                return "- º¸Á¶°­»ç Áöµµ¼ö´ç: 25,000¿ø ¡¿ 1½Ã°£ ¡¿ 2È¸ = 50,000¿ø"
            }
        }
        else if (Mod(totalAmt, 2) = 0)
        {
            half := totalAmt // 2
            formulaOut := SSOK_CalcAddCommas(half) . " * 2"
            return "- °­»ç Áöµµ¼ö´ç: " . SSOK_CalcAddCommas(half) . "¿ø ¡¿ 2È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
        else
        {
            formulaOut := SSOK_CalcAddCommas(totalAmt) . " * 1"
            return "- °­»ç Áöµµ¼ö´ç: " . SSOK_CalcAddCommas(totalAmt) . "¿ø ¡¿ 1È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
    }
    ; 3. ÀÏ¹Ý¼ö¿ëºñ (´Ü°¡ ¾à 1¸¸¿ø ±âÁØ, ³¡ÀÚ¸® 1,000¿ø ÀÌ»ó)
    else if (InStr(cat, "ÀÏ¹Ý¼ö¿ëºñ") || InStr(cat, "¼ö¿ëºñ"))
    {
        if (Mod(totalAmt, 10000) = 0 && (totalAmt // 10000) >= 2)
        {
            cnt := totalAmt // 10000
            formulaOut := "10,000 * " . cnt
            return "- »ç¹«¡¤¿î¿µ ¼Ò¸ðÇ° ±¸ÀÔ: 10,000¿ø ¡¿ " . cnt . "°³ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
        else if (Mod(totalAmt, 10000) = 0)
        {
            formulaOut := "5,000 * 2"
            return "- »ç¹«¡¤¿î¿µ ¼Ò¸ðÇ° ±¸ÀÔ: 5,000¿ø ¡¿ 2°³ = 10,000¿ø"
        }

        ; 1¸¸¿ø ±ÙÃ³ÀÇ 1,000¿ø ´ÜÀ§ ´Ü°¡ Å½»ö
        divs := [15000, 12000, 8000, 6000, 5000, 4000, 3000, 2000, 1000]
        for idx, d in divs
        {
            if (Mod(totalAmt, d) = 0 && (totalAmt // d) >= 2)
            {
                cnt := totalAmt // d
                formulaOut := SSOK_CalcAddCommas(d) . " * " . cnt
                return "- »ç¹«¡¤¿î¿µ ¼Ò¸ðÇ° ±¸ÀÔ: " . SSOK_CalcAddCommas(d) . "¿ø ¡¿ " . cnt . "°³ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
        }

        if (Mod(totalAmt, 2) = 0)
        {
            half := totalAmt // 2
            formulaOut := SSOK_CalcAddCommas(half) . " * 2"
            return "- »ç¹«¡¤¿î¿µ ¼Ò¸ðÇ° ±¸ÀÔ: " . SSOK_CalcAddCommas(half) . "¿ø ¡¿ 2Á¾ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
        else
        {
            formulaOut := SSOK_CalcAddCommas(totalAmt) . " * 1"
            return "- »ç¹«¡¤¿î¿µ ¼Ò¸ðÇ° ±¸ÀÔ: " . SSOK_CalcAddCommas(totalAmt) . "¿ø ¡¿ 1°³ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
    }
    ; 4. ¾÷¹«ÃßÁøºñ (´Ü°¡ ¾à 3¸¸¿ø ±âÁØ, ¼Ò¼öÁ¡ ¾ø´Â Á¤¼ö, 1ÁÙ »êÃâ)
    else if (InStr(cat, "¾÷¹«ÃßÁøºñ"))
    {
        if (Mod(totalAmt, 60000) = 0 && (totalAmt // 60000) >= 1)
        {
            persons := totalAmt // 60000
            if (persons >= 2)
            {
                formulaOut := "30,000 * " . persons . " * 2"
                return "- ÇùÀÇÈ¸ ½Äºñ: 30,000¿ø ¡¿ " . persons . "¸í ¡¿ 2È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
            else
            {
                formulaOut := "30,000 * 2"
                return "- ÇùÀÇÈ¸ ½Äºñ: 30,000¿ø ¡¿ 2¸í = 60,000¿ø"
            }
        }
        else if (Mod(totalAmt, 30000) = 0)
        {
            persons := totalAmt // 30000
            formulaOut := "30,000 * " . persons
            return "- ÇùÀÇÈ¸ ½Äºñ: 30,000¿ø ¡¿ " . persons . "¸í = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
        else if (Mod(totalAmt, 25000) = 0 && (totalAmt // 25000) >= 2)
        {
            persons := totalAmt // 25000
            if (Mod(persons, 2) = 0)
            {
                p := persons // 2
                formulaOut := "25,000 * " . p . " * 2"
                return "- ÇùÀÇÈ¸ ½Äºñ: 25,000¿ø ¡¿ " . p . "¸í ¡¿ 2È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
            else
            {
                formulaOut := "25,000 * " . persons
                return "- ÇùÀÇÈ¸ ½Äºñ: 25,000¿ø ¡¿ " . persons . "¸í = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
        }
        else if (Mod(totalAmt, 20000) = 0 && (totalAmt // 20000) >= 2)
        {
            persons := totalAmt // 20000
            if (Mod(persons, 2) = 0)
            {
                p := persons // 2
                formulaOut := "20,000 * " . p . " * 2"
                return "- ÇùÀÇÈ¸ ½Äºñ: 20,000¿ø ¡¿ " . p . "¸í ¡¿ 2È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
            else
            {
                formulaOut := "20,000 * " . persons
                return "- ÇùÀÇÈ¸ ½Äºñ: 20,000¿ø ¡¿ " . persons . "¸í = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
        }

        ; 3¸¸¿ø ¹Ì¸¸ ¶Ç´Â 3¸¸¿ø ¹è¼ö°¡ ¾Æ´Ñ °æ¿ì: È¸ÀÇ ´Ù°ú¡¤À½·áºñ
        snackDivs := [5000, 4000, 3000, 2000, 1000]
        for idx, d in snackDivs
        {
            if (Mod(totalAmt, d) = 0 && (totalAmt // d) >= 2)
            {
                cnt := totalAmt // d
                formulaOut := SSOK_CalcAddCommas(d) . " * " . cnt
                return "- È¸ÀÇ ´Ù°ú¡¤À½·áºñ: " . SSOK_CalcAddCommas(d) . "¿ø ¡¿ " . cnt . "¸í = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
        }

        if (Mod(totalAmt, 2) = 0)
        {
            half := totalAmt // 2
            formulaOut := SSOK_CalcAddCommas(half) . " * 2"
            return "- È¸ÀÇ ´Ù°ú¡¤À½·áºñ: " . SSOK_CalcAddCommas(half) . "¿ø ¡¿ 2È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
        else
        {
            formulaOut := SSOK_CalcAddCommas(totalAmt) . " * 1"
            return "- È¸ÀÇ ´Ù°ú¡¤À½·áºñ: " . SSOK_CalcAddCommas(totalAmt) . "¿ø ¡¿ 1È¸ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
    }
    ; 5. ºñÇ°ºñ (´Ü°¡ ¾à 50¸¸¿ø ±âÁØ, ´ë/Á¾/°³, 1,000¿ø ´ÜÀ§, 1ÁÙ »êÃâ)
    else if (InStr(cat, "ºñÇ°ºñ"))
    {
        if (totalAmt >= 1000000 && Mod(totalAmt, 500000) = 0)
        {
            cnt := totalAmt // 500000
            formulaOut := "500,000 * " . cnt
            return "- ±³À°¿ë ºñÇ° ±¸ÀÔ: 500,000¿ø ¡¿ " . cnt . "´ë = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }

        divs := [500000, 300000, 250000, 200000, 150000, 100000, 80000, 75000, 60000, 50000, 40000, 30000, 25000, 20000, 15000, 10000, 8000, 6000, 5000, 4000, 3000, 2000, 1000]
        for idx, d in divs
        {
            if (Mod(totalAmt, d) = 0 && (totalAmt // d) >= 2)
            {
                cnt := totalAmt // d
                unitName := (d >= 200000) ? "´ë" : (d >= 50000) ? "Á¾" : "°³"
                formulaOut := SSOK_CalcAddCommas(d) . " * " . cnt
                return "- ±³À°¿ë ºñÇ° ±¸ÀÔ: " . SSOK_CalcAddCommas(d) . "¿ø ¡¿ " . cnt . unitName . " = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
            }
        }

        if (Mod(totalAmt, 2) = 0)
        {
            half := totalAmt // 2
            unitName := (half >= 200000) ? "´ë" : (half >= 50000) ? "Á¾" : "°³"
            formulaOut := SSOK_CalcAddCommas(half) . " * 2"
            return "- ±³À°¿ë ºñÇ° ±¸ÀÔ: " . SSOK_CalcAddCommas(half) . "¿ø ¡¿ 2" . unitName . " = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
        else
        {
            formulaOut := SSOK_CalcAddCommas(totalAmt) . " * 1"
            return "- ±³À°¿ë ºñÇ° ±¸ÀÔ: " . SSOK_CalcAddCommas(totalAmt) . "¿ø ¡¿ 1°³ = " . SSOK_CalcAddCommas(totalAmt) . "¿ø"
        }
    }

    return ""
}
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

SSOK_Sidebar_WorkTools:
    Gosub, SSOK_ShowWorkToolsGui
return

SSOK_ShowWorkToolsGui:
    Gui, SSOKWorkTools:Destroy
    Gui, SSOKWorkTools:+AlwaysOnTop +ToolWindow +HwndSSOK_WorkToolsHwnd
    Gui, SSOKWorkTools:Color, F7FBFF
    Gui, SSOKWorkTools:Font, s8 bold, Malgun Gothic
    Gui, SSOKWorkTools:Add, Button, x8 y8 w166 h25 gSSOK_WorkTools_Travel, ¿©ºñÁ¤»ê¼­
    Gui, SSOKWorkTools:Add, Button, x8 y39 w166 h25 gSSOK_WorkTools_Calc, °è»ê±â
    Gui, SSOKWorkTools:Add, Button, x8 y70 w166 h25 gSSOK_WorkTools_AutoClick, ¸¶¿ì½º ¸ÅÅ©·Î
    Gui, SSOKWorkTools:Add, Button, x8 y101 w166 h25 gSSOK_WorkTools_Privacy, °³ÀÎÁ¤º¸ ¼û±â±â
    Gui, SSOKWorkTools:Add, Button, x8 y132 w166 h25 gSSOK_WorkTools_CommaToggle, ¼ýÀÚ Ãµ ´ÜÀ§ Åä±Û
    Gui, SSOKWorkTools:Add, Button, x8 y163 w166 h25 gSSOK_WorkTools_SchoolSearch, ÇÐ±³°Ë»ö (Àü±¹)
    Gui, SSOKWorkTools:Add, Button, x8 y194 w166 h25 gSSOK_WorkTools_SchoolSearchNational, ÇÐ±³°Ë»ö (¼¼Á¾)
    Gui, SSOKWorkTools:Add, Button, x8 y225 w166 h25 gSSOK_WorkTools_LocalFinanceInfo, Áö¹æ±³À°ÀçÁ¤Á¤º¸
    Gui, SSOKWorkTools:Add, Button, x8 y256 w166 h25 gSSOK_WorkTools_ContractG2B, °è¾àÇöÈ² (³ª¶óÀåÅÍ)
    Gui, SSOKWorkTools:Add, Button, x8 y287 w166 h25 gSSOK_WorkTools_ContractG2BSejong, °è¾àÇöÈ² (³ª¶óÀåÅÍ_¼¼Á¾)
    Gui, SSOKWorkTools:Add, Button, x8 y318 w166 h25 gSSOK_WorkTools_ContractLofin365, °è¾àÇöÈ² (Áö¹æÀçÁ¤365)
    Gui, SSOKWorkTools:Add, Button, x8 y349 w166 h25 gSSOK_WorkTools_ContractSejong, °è¾àÇöÈ² (¼¼Á¾)
    Gui, SSOKWorkTools:Add, Button, x8 y380 w166 h25 vSSOK_WorkTools_Exit gSSOK_Sidebar_Delete, Á¾·á
    Gui, SSOKWorkTools:Add, Button, x8 y411 w166 h25 vSSOK_WorkTools_BetaToggle gSSOK_WorkTools_BetaToggle, Å×½ºÆ®¹öÀü Beta
    Gui, SSOKWorkTools:Add, Button, x8 y442 w166 h25 vSSOK_WorkTools_Win1 gSSOK_Advanced_Win1 Hidden, °£Æí ¿øÀÎÇàÀ§(win+1)
    Gui, SSOKWorkTools:Add, Button, x8 y473 w166 h25 vSSOK_WorkTools_Win2 gSSOK_Advanced_Win2 Hidden, °£Æí ¿øÀÎÇàÀ§(win+2)

    ; Å×½ºÆ®¹öÀüÀ» ´­·¯µµ Ã¢ Å©±â¿Í À§Ä¡´Â º¯°æÇÏÁö ¾Ê½À´Ï´Ù.
    ; µû¶ó¼­ Å×½ºÆ®¹öÀü ¹öÆ°ÀÌ »ç¶óÁöÁö ¾Ê°í °è¼Ó °°Àº À§Ä¡¿¡¼­ ´Ù½Ã ´©¸¦ ¼ö ÀÖ½À´Ï´Ù.
    SSOK_WorkToolsW := 182
    SSOK_WorkToolsH := 505
    SSOK_WorkToolsBetaExpanded := 0

    SSOK_WorkToolsX := SSOK_SidebarX - SSOK_WorkToolsW
    SSOK_WorkToolsY := SSOK_SidebarY + SSOK_SidebarH - SSOK_WorkToolsH
    if (SSOK_WorkToolsX < SSOK_WorkAreaLeft)
        SSOK_WorkToolsX := SSOK_WorkAreaLeft
    if (SSOK_WorkToolsY < SSOK_WorkAreaTop)
        SSOK_WorkToolsY := SSOK_WorkAreaTop
    if (SSOK_WorkToolsY > SSOK_WorkAreaBottom - SSOK_WorkToolsH)
        SSOK_WorkToolsY := SSOK_WorkAreaBottom - SSOK_WorkToolsH

    Gui, SSOKWorkTools:Show, x%SSOK_WorkToolsX% y%SSOK_WorkToolsY% w%SSOK_WorkToolsW% h%SSOK_WorkToolsH%, ¾÷¹«¿ë µµ±¸
    WinSet, AlwaysOnTop, On, ahk_id %SSOK_WorkToolsHwnd%
    WinActivate, ahk_id %SSOK_WorkToolsHwnd%
return

SSOK_WorkTools_BetaToggle:
    ; Å×½ºÆ®¹öÀü ¹öÆ° ÀÚÃ¼´Â Àý´ë·Î ¼û±â°Å³ª ÀÌµ¿ÇÏÁö ¾Ê½À´Ï´Ù.
    if (SSOK_WorkToolsBetaExpanded)
    {
        GuiControl, SSOKWorkTools:Hide, SSOK_WorkTools_Win1
        GuiControl, SSOKWorkTools:Hide, SSOK_WorkTools_Win2
        SSOK_WorkToolsBetaExpanded := 0
    }
    else
    {
        GuiControl, SSOKWorkTools:Show, SSOK_WorkTools_Win1
        GuiControl, SSOKWorkTools:Show, SSOK_WorkTools_Win2
        SSOK_WorkToolsBetaExpanded := 1
    }
return

SSOK_WorkTools_Travel:
    Gosub, SSOK_TrayOpenTravel
return

SSOK_WorkTools_Calc:
    Gosub, SSOK_Sidebar_Calc
return

SSOK_WorkTools_AutoClick:
    Gosub, SSOK_Advanced_AutoClick
return

SSOK_WorkTools_Privacy:
    Gosub, SSOK_Advanced_Privacy
return

SSOK_WorkTools_CommaToggle:
    Gosub, SSOK_Advanced_CommaToggle
return

SSOK_WorkTools_SchoolSearch:
    Gosub, SSOK_Advanced_SchoolSearch
return

SSOK_WorkTools_SchoolSearchNational:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_SchoolSearch_ShowNational
return

SSOK_WorkTools_LocalFinanceInfo:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_OpenLocalFinanceInfoForSejongElementary()
return

SSOK_WorkTools_ContractG2B:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_OpenUrlPreferred("https://www.g2b.go.kr/link/FIUA006_01/")
return

SSOK_WorkTools_ContractG2BSejong:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_OpenUrlPreferred("https://www.g2b.go.kr/link/FIUA006_01/single/?untySrchSeCd=BKOB&rowCnt=&instCd=9300000&demaInstNm=&hghrkInstCd=9300000&prcmBsneAreaCd=%EC%A0%84%EC%B2%B4&prcmMthoSeCd=&frcpYn=N&laseYn=N&rsrvYn=N&chkInstCd=&urlSrchSeCd=hghrkInstCd")
return

SSOK_WorkTools_ContractLofin365:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_OpenUrlPreferred("https://www.lofin365.go.kr/portal/LF3120302.do")
return

SSOK_WorkTools_ContractSejong:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_OpenUrlPreferred("https://www.sje.go.kr/sje/ir/selectCntrInfoList.do?mi=52495")
return

SSOKWorkToolsGuiEscape:
SSOKWorkToolsGuiClose:
    Gui, SSOKWorkTools:Destroy
    SSOK_WorkToolsHwnd := ""
return

SSOK_Sidebar_Advanced:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gui, SSOKAdvanced:Destroy
    Gui, SSOKAdvanced:+AlwaysOnTop +ToolWindow +HwndSSOK_AdvancedHwnd
    Gui, SSOKAdvanced:Color, F7FBFF
    Gui, SSOKAdvanced:Font, s8 bold, Malgun Gothic
    Gui, SSOKAdvanced:Add, Button, x8 y8 w166 h25 gSSOK_Advanced_Win1, °£Æí ¿øÀÎÇàÀ§(win+1)
    Gui, SSOKAdvanced:Add, Button, x8 y39 w166 h25 gSSOK_Advanced_Win2, °£Æí ¿øÀÎÇàÀ§(win+2)
    SSOK_AdvancedW := 182
    SSOK_AdvancedH := 76
    if (SSOK_AdvancedCustomPos = 1 && SSOK_AdvancedSavedX != "" && SSOK_AdvancedSavedY != "")
    {
        SSOK_AdvancedX := SSOK_AdvancedSavedX
        SSOK_AdvancedY := SSOK_AdvancedSavedY
    }
    else
    {
        if (SSOK_SidebarHwnd != "")
            WinGetPos, SSOK_AdvancedX, SSOK_AdvancedSideY,,, ahk_id %SSOK_SidebarHwnd%
        else
        {
            SSOK_AdvancedX := SSOK_SidebarX
            SSOK_AdvancedSideY := SSOK_SidebarY
        }
        SSOK_AdvancedY := SSOK_AdvancedSideY + SSOK_SidebarH - SSOK_AdvancedH - 22
    }
    SysGet, SSOK_AdvancedWork, MonitorWorkArea
    if (SSOK_AdvancedX < SSOK_AdvancedWorkLeft)
        SSOK_AdvancedX := SSOK_AdvancedWorkLeft
    if (SSOK_AdvancedX > SSOK_AdvancedWorkRight - SSOK_AdvancedW)
        SSOK_AdvancedX := SSOK_AdvancedWorkRight - SSOK_AdvancedW
    if (SSOK_AdvancedY < SSOK_AdvancedWorkTop)
        SSOK_AdvancedY := SSOK_AdvancedWorkTop
    if (SSOK_AdvancedY > SSOK_AdvancedWorkBottom - SSOK_AdvancedH)
        SSOK_AdvancedY := SSOK_AdvancedWorkBottom - SSOK_AdvancedH
    Gui, SSOKAdvanced:Show, x%SSOK_AdvancedX% y%SSOK_AdvancedY% w%SSOK_AdvancedW% h%SSOK_AdvancedH%, Hidden Menu
    WinSet, AlwaysOnTop, On, ahk_id %SSOK_AdvancedHwnd%
    WinActivate, ahk_id %SSOK_AdvancedHwnd%
    SetTimer, SSOK_Advanced_TrackMovedPos, 700
return

SSOK_Advanced_Privacy:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoPrivacyMask
return

SSOK_Advanced_Win1:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoWin1_KEdufine_TabSeq_10_1_4
return

SSOK_Advanced_Win2:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoWin2_KEdufine_TabSeq
return

SSOK_Advanced_CommaToggle:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoCommaToggle
return

SSOK_Advanced_AutoClick:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_AutoClick_Show
return

SSOK_Advanced_SchoolSearch:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    SSOK_OpenSchoolInfo2ForSejongElementary()
return

SSOK_SchoolSearch_ShowNational:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_SchoolSearch_Show
return

SSOK_Advanced_EduOfficeSearch:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_EduOfficeSearch_Show
return

SSOK_AutoClick_Show:
    SSOK_AutoClickIni := SSOK_IniFile
    IniRead, SSOK_AutoClickSec, %SSOK_AutoClickIni%, AutoClick, Sec, 0
    IniRead, SSOK_AutoClickModeSaved, %SSOK_AutoClickIni%, AutoClick, Mode, 1
    IniRead, SSOK_AutoClickTimeModeSaved, %SSOK_AutoClickIni%, AutoClick, TimeMode, 1
    IniRead, SSOK_AutoClickIX, %SSOK_AutoClickIni%, AutoClick, IX, __SSOK_EMPTY__
    IniRead, SSOK_AutoClickIY, %SSOK_AutoClickIni%, AutoClick, IY, __SSOK_EMPTY__
    IniRead, SSOK_AutoClickCoordOneVer, %SSOK_AutoClickIni%, AutoClick, CoordOneVer, 0
    if (SSOK_AutoClickIX = "__SSOK_EMPTY__")
        SSOK_AutoClickIX := ""
    if (SSOK_AutoClickIY = "__SSOK_EMPTY__")
        SSOK_AutoClickIY := ""
    Loop, 3
    {
        idx := A_Index
        IniRead, SSOK_AutoClickUse%idx%, %SSOK_AutoClickIni%, AutoClick, Use%idx%, 0
        IniRead, SSOK_AutoClickX%idx%, %SSOK_AutoClickIni%, AutoClick, X%idx%, __SSOK_EMPTY__
        IniRead, SSOK_AutoClickY%idx%, %SSOK_AutoClickIni%, AutoClick, Y%idx%, __SSOK_EMPTY__
        IniRead, SSOK_AutoClickH%idx%, %SSOK_AutoClickIni%, AutoClick, H%idx%, 00
        IniRead, SSOK_AutoClickM%idx%, %SSOK_AutoClickIni%, AutoClick, M%idx%, 00
        IniRead, SSOK_AutoClickS%idx%, %SSOK_AutoClickIni%, AutoClick, S%idx%, 00
        if (SSOK_AutoClickUse%idx% != 1)
            SSOK_AutoClickUse%idx% := 0
        if (SSOK_AutoClickX%idx% = "__SSOK_EMPTY__")
            SSOK_AutoClickX%idx% := ""
        if (SSOK_AutoClickY%idx% = "__SSOK_EMPTY__")
            SSOK_AutoClickY%idx% := ""
        SSOK_AutoClickH%idx% := SSOK_AutoClickPad2(SSOK_AutoClickH%idx%)
        SSOK_AutoClickM%idx% := SSOK_AutoClickPad2(SSOK_AutoClickM%idx%)
        SSOK_AutoClickS%idx% := SSOK_AutoClickPad2(SSOK_AutoClickS%idx%)
    }

    if (SSOK_AutoClickSec = "" || SSOK_AutoClickSec = "ERROR")
        SSOK_AutoClickSec := 0
    IniWrite, 2, %SSOK_AutoClickIni%, AutoClick, CoordOneVer
    if (SSOK_AutoClickModeSaved != 2)
        SSOK_AutoClickModeSaved := 1
    if (SSOK_AutoClickTimeModeSaved != 2)
        SSOK_AutoClickTimeModeSaved := 1
    SSOK_AutoClickCursorChecked := (SSOK_AutoClickModeSaved = 1 ? 1 : 0)
    SSOK_AutoClickCoordChecked := (SSOK_AutoClickModeSaved = 2 ? 1 : 0)
    SSOK_AutoClickTimeCursorChecked := (SSOK_AutoClickTimeModeSaved = 1 ? 1 : 0)
    SSOK_AutoClickTimeCoordChecked := (SSOK_AutoClickTimeModeSaved = 2 ? 1 : 0)

    Gui, SSOKAutoClick:Destroy
    Gui, SSOKAutoClick:+AlwaysOnTop +ToolWindow +HwndSSOK_AutoClickHwnd
    Gui, SSOKAutoClick:Color, F7FBFF
    Gui, SSOKAutoClick:Font, s11 bold, Malgun Gothic
    Gui, SSOKAutoClick:Add, Text, x0 y12 w590 h26 Center c005BAC, ÀÚµ¿ ¸¶¿ì½º Å¬¸¯
    Gui, SSOKAutoClick:Font, s9 norm, Malgun Gothic
    Gui, SSOKAutoClick:Add, Text, x20 y50 w72 h24 +0x200, Å¬¸¯ °£°Ý
    Gui, SSOKAutoClick:Add, Edit, x96 y50 w54 h24 Center vSSOK_AutoClickSec, %SSOK_AutoClickSec%
    Gui, SSOKAutoClick:Add, Text, x156 y50 w24 h24 +0x200, ÃÊ
    Gui, SSOKAutoClick:Add, Text, x188 y50 w380 h24 +0x200 c777777, (¿¹: 0 = ¹Ì½Ç½Ã, 5 = 5ÃÊ¸¶´Ù, 60 = 1ºÐ¸¶´Ù Å¬¸¯)
    Gui, SSOKAutoClick:Add, Radio, x46 y84 w260 h22 Group vSSOK_AutoClickMode hwndSSOK_AutoClickModeCursorHwnd Checked%SSOK_AutoClickCursorChecked%, ÁÂÇ¥ ¹ÌÁöÁ¤ (ÇöÀç ¸¶¿ì½º À§Ä¡)
    Gui, SSOKAutoClick:Add, Radio, x46 y112 w80 h22 hwndSSOK_AutoClickModeCoordHwnd Checked%SSOK_AutoClickCoordChecked%, ÁÂÇ¥ ÁöÁ¤
    Gui, SSOKAutoClick:Add, Text, x130 y112 w16 h22 +0x200, X
    Gui, SSOKAutoClick:Add, Edit, x150 y112 w70 h24 Center vSSOK_AutoClickIX, %SSOK_AutoClickIX%
    Gui, SSOKAutoClick:Add, Text, x232 y112 w16 h22 +0x200, Y
    Gui, SSOKAutoClick:Add, Edit, x252 y112 w70 h24 Center vSSOK_AutoClickIY, %SSOK_AutoClickIY%
    Gui, SSOKAutoClick:Add, Button, x340 y111 w82 h26 gSSOK_AutoClick_FindInterval, ÁÂÇ¥Ã£±â

    Gui, SSOKAutoClick:Add, Progress, x20 y152 w550 h1 BackgroundD4E6EF cD4E6EF, 100
    Gui, SSOKAutoClick:Font, s9 bold, Malgun Gothic
    Gui, SSOKAutoClick:Add, Text, x20 y168 w78 h24 +0x200 c005BAC, Å¬¸¯ ½Ã°£
    Gui, SSOKAutoClick:Font, s9 norm, Malgun Gothic
    Loop, 3
    {
        idx := A_Index
        rowY := 166 + (idx * 34)
        useChecked := SSOK_AutoClickUse%idx%
        Gui, SSOKAutoClick:Add, CheckBox, x34 y%rowY% w50 h24 vSSOK_AutoClickUse%idx% Checked%useChecked%, »ç¿ë
        Gui, SSOKAutoClick:Add, Text, x88 y%rowY% w55 h24 +0x200 Right, %idx%È¸Â÷:
        Gui, SSOKAutoClick:Add, Edit, x152 y%rowY% w34 h24 Center vSSOK_AutoClickH%idx%, % SSOK_AutoClickH%idx%
        Gui, SSOKAutoClick:Add, Text, x190 y%rowY% w20 h24 +0x200, ½Ã
        Gui, SSOKAutoClick:Add, Edit, x214 y%rowY% w34 h24 Center vSSOK_AutoClickM%idx%, % SSOK_AutoClickM%idx%
        Gui, SSOKAutoClick:Add, Text, x252 y%rowY% w20 h24 +0x200, ºÐ
        Gui, SSOKAutoClick:Add, Edit, x276 y%rowY% w34 h24 Center vSSOK_AutoClickS%idx%, % SSOK_AutoClickS%idx%
        Gui, SSOKAutoClick:Add, Text, x314 y%rowY% w20 h24 +0x200, ÃÊ
    }

    Gui, SSOKAutoClick:Add, Progress, x20 y306 w550 h1 BackgroundD4E6EF cD4E6EF, 100
    Gui, SSOKAutoClick:Add, Radio, x46 y324 w260 h22 Group vSSOK_AutoClickTimeMode hwndSSOK_AutoClickTimeModeCursorHwnd Checked%SSOK_AutoClickTimeCursorChecked%, ÁÂÇ¥ ¹ÌÁöÁ¤ (ÇöÀç ¸¶¿ì½º À§Ä¡)
    Gui, SSOKAutoClick:Add, Radio, x46 y352 w250 h22 hwndSSOK_AutoClickTimeModeCoordHwnd Checked%SSOK_AutoClickTimeCoordChecked%, ÁÂÇ¥ ÁöÁ¤
    Loop, 3
    {
        idx := A_Index
        rowY := 388 + ((idx - 1) * 42)
        Gui, SSOKAutoClick:Add, Text, x46 y%rowY% w55 h24 +0x200 Right, %idx%È¸Â÷:
        Gui, SSOKAutoClick:Add, Text, x106 y%rowY% w16 h24 +0x200, X
        Gui, SSOKAutoClick:Add, Edit, x126 y%rowY% w70 h24 Center vSSOK_AutoClickX%idx%, % SSOK_AutoClickX%idx%
        Gui, SSOKAutoClick:Add, Text, x210 y%rowY% w16 h24 +0x200, Y
        Gui, SSOKAutoClick:Add, Edit, x230 y%rowY% w70 h24 Center vSSOK_AutoClickY%idx%, % SSOK_AutoClickY%idx%
        Gui, SSOKAutoClick:Add, Button, x318 y%rowY% w82 h26 gSSOK_AutoClick_FindRange%idx%, ÁÂÇ¥Ã£±â
    }
    Gui, SSOKAutoClick:Add, Text, x42 y512 w500 h42 vSSOK_AutoClickRangeText c555555,
    Gui, SSOKAutoClick:Add, Text, x20 y560 w550 h34 c777777, Å¬¸¯ ½Ã°£Àº '»ç¿ë'À» Ã¼Å©ÇÑ È¸Â÷¸¸ ½ÇÇàÇÕ´Ï´Ù. 00½Ã 00ºÐ 00ÃÊµµ »ç¿ë Ã¼Å©°¡ ÄÑÁ® ÀÖÀ» ¶§¸¸ ½ÇÇàµË´Ï´Ù.
    Gui, SSOKAutoClick:Font, s9 bold, Malgun Gothic
    Gui, SSOKAutoClick:Add, Button, x185 y608 w90 h32 gSSOK_AutoClick_Start, ½ÃÀÛ
    Gui, SSOKAutoClick:Add, Button, x315 y608 w90 h32 gSSOK_AutoClick_Stop, ÁßÁö
    Gui, SSOKAutoClick:Font, s8 norm, Malgun Gothic
    Gui, SSOKAutoClick:Add, Text, x0 y654 w590 h22 Center vSSOK_AutoClickStatus c777777, ´ë±â Áß
    Gosub, SSOK_AutoClick_UpdateRangeText
    SSOK_GetSidebarAttachedGuiPos(590, 690, SSOK_AutoClickWinX, SSOK_AutoClickWinY)
    Gui, SSOKAutoClick:Show, x%SSOK_AutoClickWinX% y%SSOK_AutoClickWinY% w590 h690, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯
return

SSOK_AutoClick_FindInterval:
    SSOK_AutoClickFindIndex := 0
    Gosub, SSOK_AutoClick_FindRange
return

SSOK_AutoClick_FindRange1:
    SSOK_AutoClickFindIndex := 1
    Gosub, SSOK_AutoClick_FindRange
return

SSOK_AutoClick_FindRange2:
    SSOK_AutoClickFindIndex := 2
    Gosub, SSOK_AutoClick_FindRange
return

SSOK_AutoClick_FindRange3:
    SSOK_AutoClickFindIndex := 3
    Gosub, SSOK_AutoClick_FindRange
return

SSOK_AutoClick_FindRange:
    Gui, SSOKAutoClick:Submit, NoHide
    if (SSOK_AutoClickFindIndex < 0 || SSOK_AutoClickFindIndex > 3)
        SSOK_AutoClickFindIndex := 1
    CoordMode, Mouse, Screen
    SSOK_AutoClickFindActive := 1
    SSOK_AutoClickFindWaitRelease := 1
    SSOK_AutoClickFindClickDown := 0
    if (SSOK_AutoClickFindIndex = 0)
    {
        SSOK_AutoClickSetRadioPair(SSOK_AutoClickModeCursorHwnd, SSOK_AutoClickModeCoordHwnd, 2)
        SSOK_AutoClickMode := 2
        SSOK_AutoClickFindLabel := "Å¬¸¯ °£°Ý"
    }
    else
    {
        SSOK_AutoClickSetRadioPair(SSOK_AutoClickTimeModeCursorHwnd, SSOK_AutoClickTimeModeCoordHwnd, 2)
        SSOK_AutoClickTimeMode := 2
        SSOK_AutoClickFindLabel := SSOK_AutoClickFindIndex . "È¸Â÷"
    }
    GuiControl, SSOKAutoClick:, SSOK_AutoClickStatus, %SSOK_AutoClickFindLabel% ÁÂÇ¥ Ã£±â Áß
    SetTimer, SSOK_AutoClick_FindCoordTrack, 40
    SSOK_AutoClickTip := SSOK_AutoClickFindLabel . " ÁÂÇ¥ Ã£±â ½ÃÀÛ`n¸¶¿ì½º¸¦ ¿òÁ÷ÀÌ¸é ÇöÀç ÁÂÇ¥°¡ Ç¥½ÃµË´Ï´Ù.`n¿øÇÏ´Â À§Ä¡¿¡¼­ ¿ÞÂÊ Å¬¸¯: X, Y ÀÔ·Â`nÃë¼Ò: Esc ¶Ç´Â ¿À¸¥ÂÊ Å¬¸¯"
    ToolTip, %SSOK_AutoClickTip%
return

SSOK_AutoClick_FindCoordTrack:
    if (!SSOK_AutoClickFindActive)
    {
        SetTimer, SSOK_AutoClick_FindCoordTrack, Off
        return
    }
    CoordMode, Mouse, Screen
    MouseGetPos, SSOK_AutoClickNowX, SSOK_AutoClickNowY

    if (GetKeyState("Esc", "P") || GetKeyState("RButton", "P"))
    {
        SSOK_AutoClickFindActive := 0
        SetTimer, SSOK_AutoClick_FindCoordTrack, Off
        GuiControl, SSOKAutoClick:, SSOK_AutoClickStatus, ÁÂÇ¥ Ã£±â Ãë¼ÒµÊ
        SSOK_AutoClickTip := "ÁÂÇ¥ Ã£±â¸¦ Ãë¼ÒÇß½À´Ï´Ù."
        ToolTip, %SSOK_AutoClickTip%
        SetTimer, SSOK_AutoClick_ClearToolTip, -1200
        return
    }

    if (GetKeyState("LButton", "P"))
    {
        if (!SSOK_AutoClickFindWaitRelease && !SSOK_AutoClickFindClickDown)
        {
            SSOK_AutoClickFindClickDown := 1
            idx := SSOK_AutoClickFindIndex
            if (idx = 0)
            {
                SSOK_AutoClickIX := SSOK_AutoClickNowX
                SSOK_AutoClickIY := SSOK_AutoClickNowY
                SSOK_AutoClickDoneText := "Å¬¸¯ °£°Ý ÁÂÇ¥°¡ ÀÔ·ÂµÇ¾ú½À´Ï´Ù.`nÁÂÇ¥: " . SSOK_AutoClickIX . ", " . SSOK_AutoClickIY
                GuiControl, SSOKAutoClick:, SSOK_AutoClickStatus, Å¬¸¯ °£°Ý ÁÂÇ¥ ÀÔ·Â ¿Ï·á
            }
            else
            {
                SSOK_AutoClickX%idx% := SSOK_AutoClickNowX
                SSOK_AutoClickY%idx% := SSOK_AutoClickNowY
                SSOK_AutoClickDoneText := idx . "È¸Â÷ ÁÂÇ¥°¡ ÀÔ·ÂµÇ¾ú½À´Ï´Ù.`nÁÂÇ¥: " . SSOK_AutoClickX%idx% . ", " . SSOK_AutoClickY%idx%
                GuiControl, SSOKAutoClick:, SSOK_AutoClickStatus, %idx%È¸Â÷ ÁÂÇ¥ ÀÔ·Â ¿Ï·á
            }
            SSOK_AutoClickFindActive := 0
            SetTimer, SSOK_AutoClick_FindCoordTrack, Off
            Gosub, SSOK_AutoClick_UpdateRangeText
            Gosub, SSOK_AutoClick_SaveSettings
            ToolTip, %SSOK_AutoClickDoneText%
            SetTimer, SSOK_AutoClick_ClearToolTip, -1500
        }
        return
    }
    else
    {
        SSOK_AutoClickFindWaitRelease := 0
        SSOK_AutoClickFindClickDown := 0
    }

    SSOK_AutoClickTip := SSOK_AutoClickFindLabel . " ÁÂÇ¥ Ã£±â Áß`nÇöÀç ÁÂÇ¥: " . SSOK_AutoClickNowX . ", " . SSOK_AutoClickNowY . "`n¿øÇÏ´Â À§Ä¡¿¡¼­ ¿ÞÂÊ Å¬¸¯: X, Y ÀÔ·Â`nÃë¼Ò: Esc ¶Ç´Â ¿À¸¥ÂÊ Å¬¸¯"
    ToolTip, %SSOK_AutoClickTip%
return

SSOK_AutoClick_ClearToolTip:
    ToolTip
return

SSOK_AutoClickSetRadioPair(cursorHwnd, coordHwnd, selected)
{
    if (cursorHwnd != "")
        DllCall("SendMessage", "ptr", cursorHwnd, "uint", 0xF1, "ptr", selected = 1 ? 1 : 0, "ptr", 0)
    if (coordHwnd != "")
        DllCall("SendMessage", "ptr", coordHwnd, "uint", 0xF1, "ptr", selected = 2 ? 1 : 0, "ptr", 0)
}

SSOK_AutoClick_UpdateRangeText:
    GuiControl, SSOKAutoClick:, SSOK_AutoClickIX, %SSOK_AutoClickIX%
    GuiControl, SSOKAutoClick:, SSOK_AutoClickIY, %SSOK_AutoClickIY%
    Loop, 3
    {
        idx := A_Index
        GuiControl, SSOKAutoClick:, SSOK_AutoClickX%idx%, % SSOK_AutoClickX%idx%
        GuiControl, SSOKAutoClick:, SSOK_AutoClickY%idx%, % SSOK_AutoClickY%idx%
    }
    if (SSOK_AutoClickIX != "" && SSOK_AutoClickIY != "")
        SSOK_AutoClickRangeLabel := "Å¬¸¯ °£°Ý ÁÂÇ¥: " . SSOK_AutoClickIX . ", " . SSOK_AutoClickIY
    else
        SSOK_AutoClickRangeLabel := "Å¬¸¯ °£°Ý ÁÂÇ¥ ¹ÌÁöÁ¤Àº Å¬¸¯ ½ÃÁ¡ÀÇ ÇöÀç ¸¶¿ì½º À§Ä¡¸¦ »ç¿ëÇÕ´Ï´Ù."
    SSOK_AutoClickRangeLabel .= "`nÅ¬¸¯ ½Ã°£Àº »ç¿ë Ã¼Å©°¡ ÄÑÁø È¸Â÷¸¸ ½ÇÇàµÇ¸ç, ÁÂÇ¥ ÁöÁ¤ ¼±ÅÃ ½Ã ÇØ´ç È¸Â÷ ÁÂÇ¥°¡ ÇÊ¿äÇÕ´Ï´Ù."
    GuiControl, SSOKAutoClick:, SSOK_AutoClickRangeText, %SSOK_AutoClickRangeLabel%
return

SSOK_AutoClick_Start:
    Gui, SSOKAutoClick:Submit, NoHide
    SSOK_AutoClickSec := Trim(SSOK_AutoClickSec)
    if !(RegExMatch(SSOK_AutoClickSec, "^[0-9]+(\.[0-9]+)?$"))
    {
        SSOK_AutoClickMsg := "Å¬¸¯ °£°ÝÀº 0, 5, 60Ã³·³ 0 ÀÌ»óÀÇ ¼ýÀÚ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä."
        MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %SSOK_AutoClickMsg%
        return
    }
    SSOK_AutoClickSec := SSOK_AutoClickSec + 0
    if (SSOK_AutoClickSec < 0)
    {
        SSOK_AutoClickMsg := "Å¬¸¯ °£°ÝÀº 0, 5, 60Ã³·³ 0 ÀÌ»óÀÇ ¼ýÀÚ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä."
        MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %SSOK_AutoClickMsg%
        return
    }
    SSOK_AutoClickTimerMs := Round(SSOK_AutoClickSec * 1000)
    if (SSOK_AutoClickSec > 0 && SSOK_AutoClickTimerMs < 100)
        SSOK_AutoClickTimerMs := 100

    SSOK_AutoClickHasSchedule := 0
    FormatTime, SSOK_AutoClickStartTimeKey,, HHmmss
    FormatTime, SSOK_AutoClickStartDateKey,, yyyyMMdd
    Loop, 3
    {
        idx := A_Index
        if (!SSOK_AutoClickNormalizeTime(SSOK_AutoClickH%idx%, SSOK_AutoClickM%idx%, SSOK_AutoClickS%idx%, timeKey))
        {
            MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %idx%È¸Â÷ Å¬¸¯ ½Ã°£Àº 00~23½Ã, 00~59ºÐ, 00~59ÃÊ ¹üÀ§·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
            return
        }
        SSOK_AutoClickTimeKey%idx% := timeKey
        SSOK_AutoClickLastDate%idx% := ""
        if (SSOK_AutoClickUse%idx% = 1)
        {
            SSOK_AutoClickHasSchedule := 1
            if (timeKey < SSOK_AutoClickStartTimeKey)
                SSOK_AutoClickLastDate%idx% := SSOK_AutoClickStartDateKey
        }
    }

    if (SSOK_AutoClickSec > 0 && SSOK_AutoClickMode = 2)
    {
        SSOK_AutoClickIX := Trim(SSOK_AutoClickIX)
        SSOK_AutoClickIY := Trim(SSOK_AutoClickIY)
        if !(RegExMatch(SSOK_AutoClickIX, "^-?\d+$") && RegExMatch(SSOK_AutoClickIY, "^-?\d+$"))
        {
            SSOK_AutoClickMsg := "Å¬¸¯ °£°ÝÀÇ ÁÂÇ¥ ÁöÁ¤À» »ç¿ëÇÏ·Á¸é X, Y ÁÂÇ¥¸¦ ¼ýÀÚ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä."
            MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %SSOK_AutoClickMsg%
            return
        }
    }
    if (SSOK_AutoClickHasSchedule && SSOK_AutoClickTimeMode = 2)
    {
        Loop, 3
        {
            idx := A_Index
            if (SSOK_AutoClickUse%idx% != 1)
                continue
            if !(RegExMatch(SSOK_AutoClickX%idx%, "^-?\d+$") && RegExMatch(SSOK_AutoClickY%idx%, "^-?\d+$"))
            {
                SSOK_AutoClickMsg := idx . "È¸Â÷ Å¬¸¯ ½Ã°£ÀÇ ÁÂÇ¥ ÁöÁ¤À» »ç¿ëÇÏ·Á¸é ÇØ´ç È¸Â÷ X, Y ÁÂÇ¥¸¦ ¼ýÀÚ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä."
                MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %SSOK_AutoClickMsg%
                return
            }
        }
    }

    SSOK_AutoClickRunning := 1
    SetTimer, SSOK_AutoClick_DoClick, Off
    SetTimer, SSOK_AutoClick_CheckSchedule, Off
    if (SSOK_AutoClickSec > 0)
        SetTimer, SSOK_AutoClick_DoClick, %SSOK_AutoClickTimerMs%
    if (SSOK_AutoClickHasSchedule)
        SetTimer, SSOK_AutoClick_CheckSchedule, 1000
    Gosub, SSOK_AutoClick_SaveSettings
    GuiControl, SSOKAutoClick:, SSOK_AutoClickStatus, ½ÇÇà Áß - °£°Ý 0Àº ¹Ýº¹ ¹Ì½Ç½Ã / »ç¿ë Ã¼Å©µÈ ½Ã°£¸¸ ½ÇÇà
return

SSOK_AutoClick_Stop:
    SSOK_AutoClickRunning := 0
    SetTimer, SSOK_AutoClick_DoClick, Off
    SetTimer, SSOK_AutoClick_CheckSchedule, Off
    GuiControl, SSOKAutoClick:, SSOK_AutoClickStatus, ÁßÁöµÊ
return

SSOK_AutoClick_DoClick:
    if (!SSOK_AutoClickRunning)
        return
    SSOK_AutoClickClickIndex(0, SSOK_AutoClickMode)
return

SSOK_AutoClick_CheckSchedule:
    if (!SSOK_AutoClickRunning)
        return
    FormatTime, nowKey,, HHmmss
    FormatTime, todayKey,, yyyyMMdd
    Loop, 3
    {
        idx := A_Index
        if (SSOK_AutoClickUse%idx% != 1)
            continue
        timeKey := SSOK_AutoClickTimeKey%idx%
        if (timeKey = "")
            continue
        if (nowKey >= timeKey && SSOK_AutoClickLastDate%idx% != todayKey)
        {
            SSOK_AutoClickLastDate%idx% := todayKey
            SSOK_AutoClickClickIndex(idx, SSOK_AutoClickTimeMode)
        }
    }
return

SSOK_AutoClick_SaveSettings:
    Gui, SSOKAutoClick:Submit, NoHide
    SSOK_AutoClickIni := SSOK_IniFile
    IniWrite, %SSOK_AutoClickSec%, %SSOK_AutoClickIni%, AutoClick, Sec
    IniWrite, %SSOK_AutoClickMode%, %SSOK_AutoClickIni%, AutoClick, Mode
    IniWrite, %SSOK_AutoClickTimeMode%, %SSOK_AutoClickIni%, AutoClick, TimeMode
    IniWrite, %SSOK_AutoClickIX%, %SSOK_AutoClickIni%, AutoClick, IX
    IniWrite, %SSOK_AutoClickIY%, %SSOK_AutoClickIni%, AutoClick, IY
    IniWrite, 2, %SSOK_AutoClickIni%, AutoClick, CoordOneVer
    Loop, 3
    {
        idx := A_Index
        IniWrite, % SSOK_AutoClickUse%idx%, %SSOK_AutoClickIni%, AutoClick, Use%idx%
        IniWrite, % SSOK_AutoClickX%idx%, %SSOK_AutoClickIni%, AutoClick, X%idx%
        IniWrite, % SSOK_AutoClickY%idx%, %SSOK_AutoClickIni%, AutoClick, Y%idx%
        IniWrite, % SSOK_AutoClickH%idx%, %SSOK_AutoClickIni%, AutoClick, H%idx%
        IniWrite, % SSOK_AutoClickM%idx%, %SSOK_AutoClickIni%, AutoClick, M%idx%
        IniWrite, % SSOK_AutoClickS%idx%, %SSOK_AutoClickIni%, AutoClick, S%idx%
    }
return

SSOK_AutoClickClickIndex(idx, mode := "")
{
    global
    CoordMode, Mouse, Screen
    if (mode = "")
        mode := SSOK_AutoClickMode
    if (mode = 2)
    {
        if (idx = 0)
        {
            x := SSOK_AutoClickIX
            y := SSOK_AutoClickIY
        }
        else
        {
            x := SSOK_AutoClickX%idx%
            y := SSOK_AutoClickY%idx%
        }
        if (RegExMatch(x, "^-?\d+$") && RegExMatch(y, "^-?\d+$"))
        {
            x += 0
            y += 0
            Click, %x%, %y%
            return true
        }
    }
    Click
    return true
}

SSOK_AutoClickNormalizeTime(ByRef hh, ByRef mm, ByRef ss, ByRef key)
{
    hh := Trim(hh)
    mm := Trim(mm)
    ss := Trim(ss)
    if (hh = "")
        hh := "00"
    if (mm = "")
        mm := "00"
    if (ss = "")
        ss := "00"
    if !(RegExMatch(hh, "^\d{1,2}$") && RegExMatch(mm, "^\d{1,2}$") && RegExMatch(ss, "^\d{1,2}$"))
        return false
    h := hh + 0
    m := mm + 0
    s := ss + 0
    if (h < 0 || h > 23 || m < 0 || m > 59 || s < 0 || s > 59)
        return false
    hh := Format("{:02}", h)
    mm := Format("{:02}", m)
    ss := Format("{:02}", s)
    key := hh . mm . ss
    return true
}

SSOK_AutoClickPad2(value)
{
    value := Trim(value)
    if (value = "" || value = "ERROR")
        value := "00"
    if RegExMatch(value, "^\d{1,2}$")
        return Format("{:02}", value + 0)
    return "00"
}
SSOKAutoClickGuiEscape:
SSOKAutoClickGuiClose:
    SSOK_AutoClickRunning := 0
    SSOK_AutoClickFindActive := 0
    SetTimer, SSOK_AutoClick_DoClick, Off
    SetTimer, SSOK_AutoClick_FindCoordTrack, Off
    ToolTip
    Gui, SSOKAutoClick:Destroy
    SSOK_AutoClickHwnd := ""
return

; =========================================================
; Hidden Menu - ÇÐ±³ °Ë»ö / ±³À°Ã» ¾÷¹«´ã´ç Á¶È¸
; =========================================================
SSOK_SchoolSearch_Show:
    Gui, SSOKSchool:Destroy
    Gui, SSOKSchool:+AlwaysOnTop +ToolWindow +MinSize920x540
    Gui, SSOKSchool:Color, F7FBFF
    SSOK_SchoolDataTitle := "¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»_¼¼Á¾½Ã °ü³» ÇÐ±³±Þº° ÇöÈ² ¾È³»"
    SSOK_SchoolDataMeta := "°ü¸®ºÎ¼­¸í: ±³À°º¹Áö°ú    ÀüÈ­¹øÈ£: 044-320-3332`n°Ô½ÃÀÏ: 2025.09.17.    ¼öÁ¤ÀÏ: 2026.02.20.`n(ÃâÃ³: °ø°øµ¥ÀÌÅÍÆ÷ÅÐ)"
    Gui, SSOKSchool:Font, s12 bold, Malgun Gothic
    Gui, SSOKSchool:Add, Text, x18 y12 w710 h30 c005BAC +0x200, %SSOK_SchoolDataTitle%
    Gui, SSOKSchool:Font, s8 norm, Malgun Gothic
    Gui, SSOKSchool:Add, Text, x748 y8 w425 h56 c555555 Right, %SSOK_SchoolDataMeta%
    Gui, SSOKSchool:Font, s9 norm, Malgun Gothic
    Gui, SSOKSchool:Add, Text, x20 y64 w60 h24 +0x200, °Ë»ö¾î
    Gui, SSOKSchool:Add, Edit, x82 y62 w420 h26 vSSOK_SchoolSearchQuery
    Gui, SSOKSchool:Add, Button, x510 y61 w80 h28 Default gSSOK_SchoolSearch_DoSearch, °Ë»ö
    Gui, SSOKSchool:Add, Text, x20 y98 w1145 h38 vSSOK_SchoolSearchStatus c777777, ÇÐ±³ Á¤º¸ 200°ÇÀ» ºÒ·¯¿À´Â ÁßÀÔ´Ï´Ù...
    Gui, SSOKSchool:Add, ListView, x18 y146 w1145 h410 vSSOK_SchoolSearchLV gSSOK_SchoolSearch_LVClick Grid AltSubmit, ±¸ºÐ|ÇÐ±³¸í|Áö¿ª¸í|ÀüÈ­|ÆÑ½º|ÇÐ±Þ¼ö|ÇÐ»ý¼ö|±³¿ø¼ö|ÁÖ¼Ò|È¨ÆäÀÌÁö
    SSOK_GetSidebarAttachedGuiPos(1180, 610, SSOK_SchoolSearchWinX, SSOK_SchoolSearchWinY)
    Gui, SSOKSchool:Show, x%SSOK_SchoolSearchWinX% y%SSOK_SchoolSearchWinY% w1180 h610, %SSOK_SchoolDataTitle%
    ; Ã¢ÀÌ ¿ÏÀüÈ÷ Ç¥½ÃµÇ±â Àü¿¡ API¸¦ ¹Ù·Î È£ÃâÇÏ¸é Ã¹ È£Ãâ¿¡¼­¸¸ 400/999·ù ¿À·ù°¡ ¶ß´Â °æ¿ì°¡ ÀÖ¾î
    ; ÀÚµ¿ ºÒ·¯¿À±â´Â Á¶±Ý ´ÊÃß°í, ÃÖÃÊ ÀÚµ¿ È£Ãâ ½ÇÆÐ ½Ã ÆË¾÷ ¾øÀÌ ÇÑ ¹ø ´õ Àç½ÃµµÇÕ´Ï´Ù.
    SSOK_SchoolSearch_IsAutoLoading := 0
    SSOK_SchoolSearch_AutoRetryDone := 0
    SetTimer, SSOK_SchoolSearch_AutoLoad, -700
return

SSOK_SchoolSearch_AutoLoad:
    SSOK_SchoolSearch_IsAutoLoading := 1
    Gosub, SSOK_SchoolSearch_DoSearch
    SSOK_SchoolSearch_IsAutoLoading := 0
return

SSOK_SchoolSearch_DoSearch:
    Gui, SSOKSchool:Submit, NoHide
    if (!IsObject(SSOK_SchoolSearch_AllRecords) || SSOK_SchoolSearch_AllRecords.Length() = 0)
    {
        GuiControl, SSOKSchool:, SSOK_SchoolSearchStatus, °ø°øµ¥ÀÌÅÍ API¿¡¼­ ÇÐ±³ Á¤º¸¸¦ ºÒ·¯¿À´Â Áß...
        SSOK_SchoolSearch_AllRecords := SSOK_SchoolSearch_FetchRecords(errMsg)
        if (!IsObject(SSOK_SchoolSearch_AllRecords) || SSOK_SchoolSearch_AllRecords.Length() = 0)
        {
            if (errMsg = "")
                errMsg := "ÇÐ±³ µ¥ÀÌÅÍ¸¦ ºÒ·¯¿ÀÁö ¸øÇß½À´Ï´Ù. APIÅ° ¶Ç´Â ³×Æ®¿öÅ© »óÅÂ¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä."

            ; Hidden ¸Þ´º¿¡¼­ ÇÐ±³ °Ë»öÀ» Ã³À½ ´­·¶À» ¶§ ÀÚµ¿ È£Ãâ¸¸ ½ÇÆÐÇÏ´Â °æ¿ì°¡ ÀÖ¾î
            ; ÀÚµ¿ È£Ãâ Áß¿¡´Â ¿À·ùÃ¢À» ¶ç¿ìÁö ¾Ê°í Àá½Ã µÚ ÇÑ ¹ø ´õ ½ÃµµÇÕ´Ï´Ù.
            if (SSOK_SchoolSearch_IsAutoLoading)
            {
                if (!SSOK_SchoolSearch_AutoRetryDone)
                {
                    SSOK_SchoolSearch_AutoRetryDone := 1
                    retryMsg := "Ã¹ API È£ÃâÀÌ Áö¿¬µÇ¾î Àá½Ã ÈÄ ÀÚµ¿À¸·Î ´Ù½Ã ½ÃµµÇÕ´Ï´Ù..."
                    GuiControl, SSOKSchool:, SSOK_SchoolSearchStatus, %retryMsg%
                    SetTimer, SSOK_SchoolSearch_AutoLoad, -900
                }
                else
                {
                    retryMsg := errMsg . "`n°Ë»ö ¹öÆ°À» ´©¸£¸é ´Ù½Ã ½ÃµµÇÕ´Ï´Ù."
                    GuiControl, SSOKSchool:, SSOK_SchoolSearchStatus, %retryMsg%
                }
                return
            }

            GuiControl, SSOKSchool:, SSOK_SchoolSearchStatus, %errMsg%
            MsgBox, 48, SSOK ÇÐ±³ °Ë»ö, %errMsg%
            return
        }
    }
    SSOK_SchoolSearch_Render(SSOK_SchoolSearchQuery)
return

SSOKSchoolGuiEscape:
SSOKSchoolGuiClose:
    Gui, SSOKSchool:Destroy
return

SSOK_SchoolSearch_LVClick:
    ; ¿­ Á¦¸ñ Å¬¸¯ ½Ã Á¤·ÄÀ» Á÷Á¢ Ã³¸®ÇÕ´Ï´Ù.
    ; ¼ýÀÚ ¿­(ÇÐ±Þ¼ö/ÇÐ»ý¼ö/±³¿ø¼ö)Àº ¹®ÀÚ Á¤·ÄÀÌ ¾Æ´Ï¶ó ¼ýÀÚ Á¤·Ä·Î °­Á¦ÇÕ´Ï´Ù.
    if (A_GuiEvent = "ColClick")
    {
        SSOK_SchoolSearch_SortByColumn(A_EventInfo)
        return
    }

    ; È¨ÆäÀÌÁö ¿­±â´Â ÇÐ±³¸í(2¹ø Ä­) ¶Ç´Â È¨ÆäÀÌÁö(10¹ø Ä­)¸¦ Å¬¸¯ÇßÀ» ¶§¸¸ ½ÇÇàÇÕ´Ï´Ù.
    ; ´Ù¸¥ Ä­À» ´­·¯ Á¤·Ä/¼±ÅÃÇÒ ¶§ °è¼Ó È¨ÆäÀÌÁö°¡ ¿­¸®´Â Çö»óÀ» ¸·½À´Ï´Ù.
    if (A_GuiEvent != "Normal" && A_GuiEvent != "DoubleClick")
        return
    if (A_EventInfo <= 0)
        return

    clickedCol := SSOK_SchoolSearch_GetClickedColumn()
    if (clickedCol != 2 && clickedCol != 10)
        return

    Gui, SSOKSchool:Default
    Gui, SSOKSchool:ListView, SSOK_SchoolSearchLV
    LV_GetText(schoolName, A_EventInfo, 2)
    LV_GetText(homeUrl, A_EventInfo, 10)
    schoolName := Trim(schoolName)
    homeUrl := Trim(homeUrl)

    url := SSOK_SchoolSearch_NormalizeHomepageUrl(homeUrl)
    if (url = "")
    {
        if (schoolName = "")
            return
        query := SSOK_SchoolSearch_BuildHomepageQuery(schoolName)
        if (query = "")
            return
        url := "https://duckduckgo.com/?q=" . SSOK_QU_UrlEncode("!ducky " . query)
    }

    if (schoolName != "")
        GuiControl, SSOKSchool:, SSOK_SchoolSearchStatus, %schoolName% È¨ÆäÀÌÁö¸¦ ¿©´Â Áß...
    SSOK_OpenUrlPreferred(url)
return

SSOK_EduOfficeSearch_Show:
    ; ±³À°Ã» ¾÷¹«´ã´ç Á¶È¸: ¾÷¹«¸í °Ë»öÀÌ ±âº» ¼±ÅÃµÈ ºÎ¼­ ¾÷¹« ÆäÀÌÁö¸¦ ¿±´Ï´Ù.
    SSOK_OpenUrlPreferred(SSOK_EduOfficeSearch_GetUrl())
return

SSOK_EduOfficeSearch_OpenStaffPage:
    SSOK_OpenUrlPreferred(SSOK_EduOfficeSearch_GetUrl())
return

SSOK_EduOfficeSearch_OpenOfficePhone:
    SSOK_OpenUrlPreferred(SSOK_EduOfficeSearch_GetUrl())
return

SSOK_QU_OpenSchoolSearchFromMenu:
    Gui, SSOKQuickUrl:Destroy
    Gosub, SSOK_SchoolSearch_Show
return

SSOK_QU_OpenSchoolInfoFromMenu:
    Gui, SSOKQuickUrl:Destroy
    SSOK_OpenUrlPreferred("https://www.schoolinfo.go.kr/ei/ss/pneiss_a08_s0.do?SIDO_CODE=3611000000")
return

SSOK_QU_OpenSchoolInfo2FromMenu:
    Gui, SSOKQuickUrl:Destroy
    SSOK_OpenSchoolInfo2ForSejongElementary()
return

SSOK_QU_OpenLocalFinanceInfoFromMenu:
    Gui, SSOKQuickUrl:Destroy
    SSOK_OpenLocalFinanceInfoForSejongElementary()
return

SSOK_QU_OpenEduOfficeSearchFromMenu:
    Gui, SSOKQuickUrl:Destroy
    Gosub, SSOK_EduOfficeSearch_Show
return

SSOK_QU_OpenSchoolSupportInfoFromMenu:
    Gui, SSOKQuickUrl:Destroy
    SSOK_OpenUrlPreferred("https://sssc.sje.go.kr/sssc/cm/conts/contsView.do?mi=201304&contsId=201058")
return

SSOK_QU_OpenContractInfoFromMenu:
    Gui, SSOKQuickUrl:Destroy
    Gosub, SSOK_QU_OpenContractInfo
return

SSOK_QU_OpenContractInfo:
    SSOK_OpenUrlPreferred("https://www.sje.go.kr/sje/ir/selectCntrInfoList.do?mi=52495")
return

SSOK_OpenSchoolInfo2ForSejongElementary()
{
    url := "https://www.schoolinfo.go.kr/ng/go/pnnggo_a01_l2.do"
    browserExe := SSOK_OpenUrlPreferred(url)
    if (browserExe = "")
        return false

    Sleep, 4800
    SSOK_ACC_ActivateBrowser(browserExe)
    Sleep, 300

    ; ÇÐ±³±âº»Á¤º¸¸¦ ºÒ·¯¿Â µÚ ÃÊµîÇÐ±³¿Í ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»À» ¼±ÅÃÇÕ´Ï´Ù.
    ; ½Ãµµ±³À°Ã» ¼±ÅÃ º¯°æ ½Ã ÇØ´ç Á¶°ÇÀ¸·Î µ¥ÀÌÅÍ °Ë»öÀÌ ¹Ù·Î ½ÇÇàµË´Ï´Ù.
    script := "(function(){var a=document.getElementById('openDataTitle0');if(!a)return;a.click();var n=0,t=setInterval(function(){n++;var k=document.getElementById('schulKndCode_0');if(k&&k.options.length>1){clearInterval(t);k.value='02';if(window.jQuery)jQuery(k).trigger('change');else k.dispatchEvent(new Event('change',{bubbles:true}));var m=0,u=setInterval(function(){m++;var o=document.getElementById('lctnScCode_0'),has=false;if(o){for(var i=0;i<o.options.length;i++)if(o.options[i].value=='08'){has=true;break;}}if(has){clearInterval(u);o.value='08';if(window.jQuery)jQuery(o).trigger('change');else o.dispatchEvent(new Event('change',{bubbles:true}));o.scrollIntoView({block:'center'});}else if(m>50)clearInterval(u);},150);}else if(n>50)clearInterval(t);},150);})()"
    SSOK_RunJavascriptInActiveBrowser(script)
    return true
}
SSOK_OpenLocalFinanceInfoForSejongElementary()
{
    url := "https://www.eduinfo.go.kr/portal/theme/schCmprPage.do"
    browserExe := SSOK_OpenUrlPreferred(url)
    if (browserExe = "")
        return false

    ; ÆäÀÌÁöÀÇ ¼­¿ï ±âº» °Ë»öÀÌ ³¡³­ µÚ ¼¼Á¾ °Ë»öÀ¸·Î ¹Ù²ß´Ï´Ù.
    Sleep, 5200
    SSOK_ACC_ActivateBrowser(browserExe)
    Sleep, 300

    ; ¼¼Á¾ > ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã > ÃÊ¸¦ ¼±ÅÃÇÏ°í °Ë»ö ¹öÆ°À» ´©¸¨´Ï´Ù.
    script := "(function(){var e=document.getElementById('eduOffcDivCd'),s=document.getElementById('sggCd'),k=document.getElementById('schlKndCd'),b=document.getElementById('search_btn');if(!e||!s||!k||!b)return;e.value='I10';if(window.jQuery)jQuery(e).trigger('change');else e.dispatchEvent(new Event('change',{bubbles:true}));var n=0,t=setInterval(function(){n++;var v='';for(var i=1;i<s.options.length;i++){if(s.options[i].value=='3611000000'){v='3611000000';break;}}if(v||n>40){clearInterval(t);if(!v||!s.options.length)return;s.value=v||s.options[1].value;k.value='E';b.click();}},150);})()"
    SSOK_RunJavascriptInActiveBrowser(script)
    return true
}
SSOK_RunJavascriptInActiveBrowser(script)
{
    savedClipboard := ClipboardAll
    Clipboard := script
    ClipWait, 1
    SendInput, ^l
    Sleep, 100
    SendInput, {Text}javascript:
    SendInput, ^v
    Sleep, 100
    SendInput, {Enter}
    Sleep, 300
    Clipboard := savedClipboard
    return true
}
SSOK_EduOfficeSearch_GetUrl()
{
    return "https://www.sje.go.kr/sje/ad/ofcrk/ofcrkDeptInfo.do?deptSn=476&mi=52203&srchOpt=W"
}

SSOK_EduOfficeSearch_GetSearchUrl(query := "")
{
    return SSOK_EduOfficeSearch_GetUrl()
}


SSOK_SchoolSearch_GetApiEndpoint()
{
    global SSOK_IniFile
    defaultEndpoint := "https://api.odcloud.kr/api/15050938/v1/uddi:d9e0a016-4299-4471-a54b-ade5e74d5aa6"
    IniRead, endpoint, %SSOK_IniFile%, SchoolSearch, ApiEndpoint, %defaultEndpoint%
    endpoint := Trim(endpoint)
    if (endpoint = "" || endpoint = "ERROR" || !InStr(endpoint, "/15050938/v1/uddi:d9e0a016-4299-4471-a54b-ade5e74d5aa6"))
        endpoint := defaultEndpoint
    return endpoint
}

SSOK_SchoolSearch_GetServiceKey()
{
    ; ÇÐ±³°Ë»ö API ÀÎÁõÅ°´Â »ç¿ëÀÚ°¡ »õ·Î Á¦°øÇÑ ½ÇÁ¦ ¼­ºñ½ºÅ°·Î °íÁ¤ÇÕ´Ï´Ù.
    ; ±âÁ¸ ini¿¡ ³²¾Æ ÀÖ´Â ¿¹Àü Å° ¶§¹®¿¡ 400/401ÀÌ ¹Ýº¹µÇÁö ¾Êµµ·Ï ini °ªÀ» »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    return "230ae6fe40480dce9f264334da7b436e300be9d6ce2ba45772563b6eb5a42854"
}

SSOK_SchoolSearch_GetServiceKeys()
{
    ; »õ ÀÎÁõÅ°¸¸ »ç¿ëÇÕ´Ï´Ù.
    keys := []
    keys.Push("230ae6fe40480dce9f264334da7b436e300be9d6ce2ba45772563b6eb5a42854")
    return keys
}

SSOK_SchoolSearch_KeyExists(keys, key)
{
    for _, item in keys
    {
        if (item = key)
            return true
    }
    return false
}

SSOK_SchoolSearch_FetchRecords(ByRef errMsg)
{
    errMsg := ""
    endpoint := SSOK_SchoolSearch_GetApiEndpoint()
    serviceKeys := SSOK_SchoolSearch_GetServiceKeys()
    maxRecords := 200
    ; ½ÇÁ¦ PC¿¡¼­ ¸Þ´º ¾ÈÀÇ °Ë»ö ¹öÆ°Àº serviceKey Äõ¸® ¹æ½ÄÀ¸·Î Á¤»ó Ç¥ÃâµÇ¹Ç·Î
    ; ÃÖÃÊ ÀÚµ¿ È£Ãâµµ °°Àº ¹æ½ÄºÎÅÍ ¸ÕÀú ½ÃµµÇÏ°í, ÇÊ¿äÇÒ ¶§¸¸ Authorization Çì´õ ¹æ½ÄÀ» º¸Á¶·Î ½ÃµµÇÕ´Ï´Ù.
    perPage := 100
    authModes := ["query", "header"]

    for _, serviceKey in serviceKeys
    {
        encodedKey := SSOK_QU_UrlEncode(serviceKey)

        for _, authMode in authModes
        {
            records := []
            seenSchools := {}
            totalCount := 0
            page := 1
            keyErr := ""

            Loop, 50
            {
                url := endpoint . "?page=" . page . "&perPage=" . perPage . "&returnType=JSON"
                if (authMode = "query")
                    url .= "&serviceKey=" . encodedKey

                body := SSOK_SchoolSearch_HttpGet(url, pageErr, serviceKey, authMode)
                if (body = "")
                {
                    if (records.Length() = 0)
                        keyErr := pageErr
                    break
                }

                if (!InStr(body, Chr(34) . "data" . Chr(34)))
                {
                    if (records.Length() = 0)
                        keyErr := "°ø°øµ¥ÀÌÅÍ API ÀÀ´ä¿¡ data Ç×¸ñÀÌ ¾ø½À´Ï´Ù. APIÅ° ¶Ç´Â ¿£µåÆ÷ÀÎÆ®¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä."
                    break
                }

                pageRecords := SSOK_SchoolSearch_ParseRecords(body)
                if (!IsObject(pageRecords) || pageRecords.Length() = 0)
                    break

                for _, rec in pageRecords
                {
                    if (records.Length() >= maxRecords)
                        break
                    dedupeKey := SSOK_SchoolSearch_DedupeKey(rec)
                    if (seenSchools.HasKey(dedupeKey))
                        continue
                    seenSchools[dedupeKey] := 1
                    records.Push(rec)
                }

                if (totalCount = 0)
                    totalCount := SSOK_SchoolSearch_JsonNumber(body, "totalCount")

                if (records.Length() >= maxRecords)
                    break
                if (totalCount > 0)
                {
                    if (records.Length() >= totalCount)
                        break
                }
                else if (pageRecords.Length() < perPage)
                    break

                page++
            }

            if (records.Length() > 0)
                return records
            if (keyErr != "")
                errMsg := keyErr
        }
    }

    if (errMsg = "" || InStr(errMsg, "HTTP 401") || InStr(errMsg, "µî·ÏµÇÁö ¾ÊÀº ÀÎÁõÅ°"))
    {
        errMsg := "°ø°øµ¥ÀÌÅÍ API ÀÎÁõ ¿À·ù"
        errMsg .= "`nserviceKey Äõ¸® ¹æ½Ä°ú Authorization Çì´õ ¹æ½ÄÀ» ¸ðµÎ ½ÃµµÇß½À´Ï´Ù."
        errMsg .= "`n±×·¡µµ °ÅºÎµÇ¸é °ø°øµ¥ÀÌÅÍÆ÷ÅÐ È°¿ë½ÅÃ»/½ÂÀÎ »óÅÂ ¶Ç´Â ½ÇÁ¦ ¼­ºñ½ºÅ°¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä."
    }
    return []
}

SSOK_SchoolSearch_DedupeKey(rec)
{
    key := Trim(rec.name . "|" . rec.kind . "|" . rec.addr)
    if (key = "||")
        key := Trim(rec.kind . " " . rec.addr)
    key := RegExReplace(key, "\s+", "")
    StringLower, key, key
    if (key = "")
        key := "__empty__" . A_TickCount . A_Index
    return key
}
SSOK_SchoolSearch_HttpGet(url, ByRef errMsg, serviceKey := "", authMode := "query")
{
    errMsg := ""
    try
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    catch
    {
        errMsg := "WinHttp °´Ã¼¸¦ ¸¸µé ¼ö ¾ø¾î °ø°øµ¥ÀÌÅÍ API¸¦ È£ÃâÇÏÁö ¸øÇß½À´Ï´Ù."
        return ""
    }
    try
    {
        req.Open("GET", url, false)
        req.SetTimeouts(5000, 5000, 10000, 10000)
        req.SetRequestHeader("Accept", "application/json")
        ; serviceKey Äõ¸® ¹æ½ÄÀÏ ¶§´Â Authorization Çì´õ¸¦ ³ÖÁö ¾Ê½À´Ï´Ù. µÑÀ» µ¿½Ã¿¡ ³ÖÀ¸¸é ÀÏºÎ odcloud API¿¡¼­ HTTP 400ÀÌ ³¯ ¼ö ÀÖ½À´Ï´Ù.
        if (serviceKey != "" && authMode = "header")
            req.SetRequestHeader("Authorization", serviceKey)
        req.Send()
        status := req.Status
        body := req.ResponseText
    }
    catch
    {
        errMsg := "°ø°øµ¥ÀÌÅÍ API È£Ãâ¿¡ ½ÇÆÐÇß½À´Ï´Ù. ³×Æ®¿öÅ© ¶Ç´Â ÀÎÁõÅ°¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä."
        return ""
    }
    if (status < 200 || status >= 300)
    {
        modeText := (authMode = "header") ? "Authorization Çì´õ ¹æ½Ä" : "serviceKey Äõ¸® ¹æ½Ä"
        errMsg := "°ø°øµ¥ÀÌÅÍ API ÀÀ´ä ¿À·ù: HTTP " . status . " / " . modeText
        bodyPreview := Trim(RegExReplace(body, "\s+", " "))
        if (bodyPreview != "")
        {
            if (StrLen(bodyPreview) > 180)
                bodyPreview := SubStr(bodyPreview, 1, 180) . "..."
            errMsg .= "`n" . bodyPreview
        }
        return ""
    }
    return body
}

SSOK_SchoolSearch_SortByColumn(col)
{
    global SSOK_SchoolSearch_LastSortCol, SSOK_SchoolSearch_LastSortDesc

    if (col <= 0)
        return

    Gui, SSOKSchool:Default
    Gui, SSOKSchool:ListView, SSOK_SchoolSearchLV

    if (SSOK_SchoolSearch_LastSortCol = col)
        SSOK_SchoolSearch_LastSortDesc := !SSOK_SchoolSearch_LastSortDesc
    else
    {
        SSOK_SchoolSearch_LastSortCol := col
        SSOK_SchoolSearch_LastSortDesc := 0
    }

    sortOpt := SSOK_SchoolSearch_LastSortDesc ? "SortDesc" : "Sort"
    if (col = 6 || col = 7 || col = 8)
        LV_ModifyCol(col, "Integer " . sortOpt)
    else
        LV_ModifyCol(col, sortOpt)
}

SSOK_SchoolSearch_GetClickedColumn()
{
    GuiControlGet, hLV, SSOKSchool:Hwnd, SSOK_SchoolSearchLV
    if (hLV = "")
        return 0
    CoordMode, Mouse, Screen
    MouseGetPos, mx, my
    VarSetCapacity(pt, 8, 0)
    NumPut(mx, pt, 0, "Int")
    NumPut(my, pt, 4, "Int")
    DllCall("ScreenToClient", "Ptr", hLV, "Ptr", &pt)
    VarSetCapacity(hit, 32, 0)
    NumPut(NumGet(pt, 0, "Int"), hit, 0, "Int")
    NumPut(NumGet(pt, 4, "Int"), hit, 4, "Int")
    SendMessage, 0x1039, 0, &hit,, ahk_id %hLV%
    return NumGet(hit, 16, "Int") + 1
}

SSOK_SchoolSearch_NormalizeHomepageUrl(homeUrl)
{
    cleanUrl := Trim(homeUrl)
    if (cleanUrl = "" || cleanUrl = "-" || cleanUrl = ".")
        return ""
    cleanUrl := StrReplace(cleanUrl, " ", "")
    cleanUrl := StrReplace(cleanUrl, "`t", "")
    if RegExMatch(cleanUrl, "i)^https?://")
        return cleanUrl
    if RegExMatch(cleanUrl, "i)^www\.")
        return "https://" . cleanUrl
    if RegExMatch(cleanUrl, "i)^([a-z0-9-]+\.)+[a-z]{2,}(:\d+)?(/.*)?$")
        return "https://" . cleanUrl
    return ""
}

SSOK_SchoolSearch_BuildHomepageQuery(schoolName)
{
    cleanName := Trim(schoolName)
    if (cleanName = "")
        return ""
    if (SSOK_SchoolSearch_HasSameSchoolName(cleanName))
        return "¼¼Á¾ " . cleanName . " È¨ÆäÀÌÁö"
    return cleanName . " È¨ÆäÀÌÁö"
}

SSOK_SchoolSearch_HasSameSchoolName(schoolName)
{
    global SSOK_SchoolSearch_AllRecords
    count := 0
    if (!IsObject(SSOK_SchoolSearch_AllRecords))
        return false
    for _, rec in SSOK_SchoolSearch_AllRecords
    {
        if (Trim(rec.name) = schoolName)
        {
            count++
            if (count >= 2)
                return true
        }
    }
    return false
}
SSOK_SchoolSearch_JsonNumber(jsonText, key)
{
    q := Chr(34)
    pattern := q . key . q . "\s*:\s*([0-9]+)"
    if RegExMatch(jsonText, pattern, m)
        return m1 + 0
    return 0
}
SSOK_SchoolSearch_ParseRecords(jsonText)
{
    records := []
    dataPos := InStr(jsonText, Chr(34) . "data" . Chr(34))
    if (!dataPos)
        return records
    arrStart := InStr(jsonText, "[", false, dataPos)
    if (!arrStart)
        return records

    depth := 0
    inString := false
    escaped := false
    objStart := 0
    jsonLen := StrLen(jsonText)
    Loop, % jsonLen - arrStart
    {
        idx := arrStart + A_Index
        ch := SubStr(jsonText, idx, 1)
        if (inString)
        {
            if (escaped)
                escaped := false
            else if (ch = "\")
                escaped := true
            else if (ch = Chr(34))
                inString := false
            continue
        }
        if (ch = Chr(34))
        {
            inString := true
            continue
        }
        if (ch = "{")
        {
            if (depth = 0)
                objStart := idx
            depth++
        }
        else if (ch = "}")
        {
            depth--
            if (depth = 0 && objStart > 0)
            {
                objText := SubStr(jsonText, objStart, idx - objStart + 1)
                rec := SSOK_SchoolSearch_RecordFromJson(objText)
                if (rec.name != "" || rec.addr != "")
                    records.Push(rec)
                objStart := 0
            }
        }
        else if (ch = "]" && depth = 0)
            break
    }
    return records
}

SSOK_SchoolSearch_RecordFromJson(objText)
{
    rec := {}
    rec.name := SSOK_SchoolSearch_JsonValue(objText, "ÇÐ±³¸í")
    rec.tel := SSOK_SchoolSearch_JsonValue(objText, "ÇÐ±³ÀüÈ­¹øÈ£")
    rec.fax := SSOK_SchoolSearch_JsonValue(objText, "ÇÐ±³ÆÑ½º¹øÈ£")
    rec.classes := SSOK_SchoolSearch_OnlyDigits(SSOK_SchoolSearch_JsonValue(objText, "ÇÐ±Þ¼ö"))
    rec.students := SSOK_SchoolSearch_OnlyDigits(SSOK_SchoolSearch_JsonValue(objText, "ÇÐ»ý¼ö"))
    rec.teachers := SSOK_SchoolSearch_OnlyDigits(SSOK_SchoolSearch_JsonValue(objText, "±³¿ø¼ö"))
    rec.addr := SSOK_SchoolSearch_JsonValue(objText, "ÁÖ¼Ò")
    rec.region := SSOK_SchoolSearch_GetRegion(objText, rec.addr)
    rec.home := SSOK_SchoolSearch_JsonValue(objText, "È¨ÆäÀÌÁöÁÖ¼Ò")
    rec.kind := SSOK_SchoolSearch_JsonValue(objText, "ÇÐ±³±¸ºÐ")
    return rec
}

SSOK_SchoolSearch_GetRegion(objText, addr)
{
    region := SSOK_SchoolSearch_JsonValue(objText, "Áö¿ª¸í")
    if (region = "")
        region := SSOK_SchoolSearch_JsonValue(objText, "Áö¿ª")
    if (region = "")
        region := SSOK_SchoolSearch_JsonValue(objText, "À¾¸éµ¿")
    if (region = "")
        region := SSOK_SchoolSearch_JsonValue(objText, "ÇàÁ¤µ¿")
    if (region != "")
        return region
    if RegExMatch(addr, "([°¡-ÆR0-9]+(À¾|¸é|µ¿|¸®))", m)
        return m1
    return ""
}
SSOK_SchoolSearch_JsonValue(objText, key)
{
    q := Chr(34)
    pattern := q . key . q . "\s*:\s*" . q . "((?:\\.|[^" . q . "])*)" . q
    if RegExMatch(objText, pattern, m)
        return SSOK_SchoolSearch_JsonUnescape(m1)
    pattern := q . key . q . "\s*:\s*([^,}]+)"
    if RegExMatch(objText, pattern, m)
        return Trim(m1, " `t`r`n" . q)
    return ""
}

SSOK_SchoolSearch_JsonUnescape(text)
{
    while RegExMatch(text, "\\u([0-9A-Fa-f]{4})", m)
        text := StrReplace(text, m, Chr("0x" . m1))
    text := StrReplace(text, "\/", "/")
    text := StrReplace(text, "\" . Chr(34), Chr(34))
    text := StrReplace(text, "\r", "`r")
    text := StrReplace(text, "\n", "`n")
    text := StrReplace(text, "\t", "`t")
    text := StrReplace(text, "\\", "\")
    return text
}

SSOK_SchoolSearch_OnlyDigits(value)
{
    value := Trim(value)
    value := StrReplace(value, ",")
    value := RegExReplace(value, "[^0-9]", "")
    return value
}

SSOK_SchoolSearch_RecordMatches(rec, query)
{
    query := Trim(query)
    if (query = "")
        return true
    hay := rec.kind . " " . rec.name . " " . rec.region . " " . rec.tel . " " . rec.fax . " " . rec.addr . " " . rec.home
    StringLower, hay, hay
    StringLower, query, query
    return InStr(hay, query)
}

SSOK_SchoolSearch_Render(query)
{
    global SSOK_SchoolSearch_AllRecords
    Gui, SSOKSchool:Default
    LV_Delete()
    shown := 0
    total := 0
    if (IsObject(SSOK_SchoolSearch_AllRecords))
    {
        total := SSOK_SchoolSearch_AllRecords.Length()
        for _, rec in SSOK_SchoolSearch_AllRecords
        {
            if (!SSOK_SchoolSearch_RecordMatches(rec, query))
                continue
            LV_Add("", rec.kind, rec.name, rec.region, rec.tel, rec.fax, rec.classes, rec.students, rec.teachers, rec.addr, rec.home)
            shown++
        }
    }
    LV_ModifyCol(1, 65)
    LV_ModifyCol(2, 160)
    LV_ModifyCol(3, 85)
    LV_ModifyCol(4, 100)
    LV_ModifyCol(5, 100)
    LV_ModifyCol(6, 60)
    LV_ModifyCol(6, "Integer")
    LV_ModifyCol(7, 60)
    LV_ModifyCol(7, "Integer")
    LV_ModifyCol(8, 60)
    LV_ModifyCol(8, "Integer")
    LV_ModifyCol(9, 350)
    LV_ModifyCol(10, 230)
    statusText := "°Ë»ö °á°ú " . shown . "°Ç / ºÒ·¯¿Â ¸ñ·Ï " . total . "°Ç (±âº» 200°Ç)"
    GuiControl, SSOKSchool:, SSOK_SchoolSearchStatus, %statusText%
}
SSOKAdvancedGuiEscape:
SSOKAdvancedGuiClose:
    Gosub, SSOK_Advanced_SaveMovedPos
    SetTimer, SSOK_Advanced_TrackMovedPos, Off
    Gui, SSOKAdvanced:Destroy
    SSOK_AdvancedHwnd := ""
return

SSOK_Advanced_TrackMovedPos:
    if (SSOK_AdvancedHwnd = "")
    {
        SetTimer, SSOK_Advanced_TrackMovedPos, Off
        return
    }
    WinGetPos, SSOK_AdvancedNowX, SSOK_AdvancedNowY,,, ahk_id %SSOK_AdvancedHwnd%
    if (SSOK_AdvancedNowX = "" || SSOK_AdvancedNowY = "")
    {
        SetTimer, SSOK_Advanced_TrackMovedPos, Off
        return
    }
    if (SSOK_AdvancedNowX != SSOK_AdvancedSavedX || SSOK_AdvancedNowY != SSOK_AdvancedSavedY)
    {
        SSOK_AdvancedSavedX := SSOK_AdvancedNowX
        SSOK_AdvancedSavedY := SSOK_AdvancedNowY
        SSOK_AdvancedCustomPos := 1
        SSOK_SaveHiddenMenuPositionIni()
    }
return

SSOK_Advanced_SaveMovedPos:
    if (SSOK_AdvancedHwnd != "")
    {
        WinGetPos, SSOK_AdvancedSavedX, SSOK_AdvancedSavedY,,, ahk_id %SSOK_AdvancedHwnd%
        if (SSOK_AdvancedSavedX != "" && SSOK_AdvancedSavedY != "")
        {
            SSOK_AdvancedCustomPos := 1
            SSOK_SaveHiddenMenuPositionIni()
        }
    }
return

SSOK_SaveHiddenMenuPositionIni()
{
    global SSOK_AdvancedCustomPos, SSOK_AdvancedSavedX, SSOK_AdvancedSavedY
    posIni := SSOK_IniFile
    IniWrite, %SSOK_AdvancedCustomPos%, %posIni%, HiddenMenuPosition, CustomPos
    IniWrite, %SSOK_AdvancedSavedX%, %posIni%, HiddenMenuPosition, X
    IniWrite, %SSOK_AdvancedSavedY%, %posIni%, HiddenMenuPosition, Y
}

SSOK_Sidebar_Win1:
    Gosub, SSOK_Sidebar_PrepareAction
    Gosub, SSOK_DoWin1_KEdufine_TabSeq_10_1_4
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
    Gui, SSOKQuickFile:Add, Text, x25 y16 w930 h34 c005BAC Center, ÀÚÁÖ »ç¿ëÇÏ´Â ÆÄÀÏ ¹Ù·Î ¿­±â
    Gui, SSOKQuickFile:Font, s8 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Button, x780 y20 w145 h24 gSSOK_QF_ShowAppRecentMenu, ÃÖ±Ù¹®¼­
    Gui, SSOKQuickFile:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Text, x25 y52 w930 h20 c555555 Center, ¼ýÀÚ´Â ¹Ù·Î ¿­±â, [ÀúÀå&&¿­±â]´Â ÀúÀå ÈÄ ¿­±â, [Æú´õ]´Â Æú´õ¸¸ ¿±´Ï´Ù.
    Gui, SSOKQuickFile:Font, s10 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Text, x35 y82 w24 h24 c005BAC Center, 1
    Gui, SSOKQuickFile:Add, Edit, x65 y78 w610 h28 vSSOK_QF_Edit1, %SSOK_QF_Text1%
    Gui, SSOKQuickFile:Add, Button, x690 y77 w170 h30 gSSOK_QF_Open1, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y77 w54 h30 gSSOK_QF_Folder1, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y116 w24 h24 c005BAC Center, 2
    Gui, SSOKQuickFile:Add, Edit, x65 y112 w610 h28 vSSOK_QF_Edit2, %SSOK_QF_Text2%
    Gui, SSOKQuickFile:Add, Button, x690 y111 w170 h30 gSSOK_QF_Open2, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y111 w54 h30 gSSOK_QF_Folder2, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y150 w24 h24 c005BAC Center, 3
    Gui, SSOKQuickFile:Add, Edit, x65 y146 w610 h28 vSSOK_QF_Edit3, %SSOK_QF_Text3%
    Gui, SSOKQuickFile:Add, Button, x690 y145 w170 h30 gSSOK_QF_Open3, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y145 w54 h30 gSSOK_QF_Folder3, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y184 w24 h24 c005BAC Center, 4
    Gui, SSOKQuickFile:Add, Edit, x65 y180 w610 h28 vSSOK_QF_Edit4, %SSOK_QF_Text4%
    Gui, SSOKQuickFile:Add, Button, x690 y179 w170 h30 gSSOK_QF_Open4, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y179 w54 h30 gSSOK_QF_Folder4, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y218 w24 h24 c005BAC Center, 5
    Gui, SSOKQuickFile:Add, Edit, x65 y214 w610 h28 vSSOK_QF_Edit5, %SSOK_QF_Text5%
    Gui, SSOKQuickFile:Add, Button, x690 y213 w170 h30 gSSOK_QF_Open5, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y213 w54 h30 gSSOK_QF_Folder5, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y252 w24 h24 c005BAC Center, 6
    Gui, SSOKQuickFile:Add, Edit, x65 y248 w610 h28 vSSOK_QF_Edit6, %SSOK_QF_Text6%
    Gui, SSOKQuickFile:Add, Button, x690 y247 w170 h30 gSSOK_QF_Open6, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y247 w54 h30 gSSOK_QF_Folder6, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y286 w24 h24 c005BAC Center, 7
    Gui, SSOKQuickFile:Add, Edit, x65 y282 w610 h28 vSSOK_QF_Edit7, %SSOK_QF_Text7%
    Gui, SSOKQuickFile:Add, Button, x690 y281 w170 h30 gSSOK_QF_Open7, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y281 w54 h30 gSSOK_QF_Folder7, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y320 w24 h24 c005BAC Center, 8
    Gui, SSOKQuickFile:Add, Edit, x65 y316 w610 h28 vSSOK_QF_Edit8, %SSOK_QF_Text8%
    Gui, SSOKQuickFile:Add, Button, x690 y315 w170 h30 gSSOK_QF_Open8, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y315 w54 h30 gSSOK_QF_Folder8, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y354 w24 h24 c005BAC Center, 9
    Gui, SSOKQuickFile:Add, Edit, x65 y350 w610 h28 vSSOK_QF_Edit9, %SSOK_QF_Text9%
    Gui, SSOKQuickFile:Add, Button, x690 y349 w170 h30 gSSOK_QF_Open9, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y349 w54 h30 gSSOK_QF_Folder9, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y388 w24 h24 c005BAC Center, 10
    Gui, SSOKQuickFile:Add, Edit, x65 y384 w610 h28 vSSOK_QF_Edit10, %SSOK_QF_Text10%
    Gui, SSOKQuickFile:Add, Button, x690 y383 w170 h30 gSSOK_QF_Open10, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y383 w54 h30 gSSOK_QF_Folder10, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y422 w24 h24 c005BAC Center, 11
    Gui, SSOKQuickFile:Add, Edit, x65 y418 w610 h28 vSSOK_QF_Edit11, %SSOK_QF_Text11%
    Gui, SSOKQuickFile:Add, Button, x690 y417 w170 h30 gSSOK_QF_Open11, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y417 w54 h30 gSSOK_QF_Folder11, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x35 y456 w24 h24 c005BAC Center, 12
    Gui, SSOKQuickFile:Add, Edit, x65 y452 w610 h28 vSSOK_QF_Edit12, %SSOK_QF_Text12%
    Gui, SSOKQuickFile:Add, Button, x690 y451 w170 h30 gSSOK_QF_Open12, ÀúÀå&&¿­±â
    Gui, SSOKQuickFile:Add, Button, x872 y451 w54 h30 gSSOK_QF_Folder12, Æú´õ

    Gui, SSOKQuickFile:Add, Text, x45 y499 w105 h22 c333333, ´Ù¸¥ÆÄÀÏ °Ë»ö
    Gui, SSOKQuickFile:Add, Edit, x150 y495 w525 h28 vSSOK_QF_CustomKeyword
    Gui, SSOKQuickFile:Add, Button, x690 y494 w170 h30 gSSOK_QF_CustomOpen Default, °Ë»ö

    Gui, SSOKQuickFile:Font, s10 bold c005BAC, Malgun Gothic
    Gui, SSOKQuickFile:Add, Text, x35 y533 w120 h24, Setting
    Gui, SSOKQuickFile:Font, s8 norm, Malgun Gothic
    Gui, SSOKQuickFile:Add, Progress, x35 y560 w890 h1 BackgroundD5DDE8 cD5DDE8
    Gui, SSOKQuickFile:Add, Text, x35 y573 w88 h22 c333333, °Ë»ö Æú´õ ¼³Á¤
    Gui, SSOKQuickFile:Add, Checkbox, x130 y571 w76 h22 vSSOK_QF_SearchDesktop Checked%SSOK_QF_SearchDesktop% gSSOK_QF_SaveFolderOptions, ¹ÙÅÁÈ­¸é
    Gui, SSOKQuickFile:Add, Checkbox, x212 y571 w76 h22 vSSOK_QF_SearchDownloads Checked%SSOK_QF_SearchDownloads% gSSOK_QF_SaveFolderOptions, ´Ù¿î·Îµå
    Gui, SSOKQuickFile:Add, Checkbox, x294 y571 w54 h22 vSSOK_QF_SearchDocuments Checked%SSOK_QF_SearchDocuments% gSSOK_QF_SaveFolderOptions, ¹®¼­
    Gui, SSOKQuickFile:Add, Checkbox, x358 y571 w80 h22 vSSOK_QF_SearchDriveD Checked%SSOK_QF_SearchDriveD% gSSOK_QF_SaveDriveDOption, D: µå¶óÀÌºê
    Gui, SSOKQuickFile:Add, Checkbox, x446 y571 w80 h22 vSSOK_QF_SearchDriveE Checked%SSOK_QF_SearchDriveE% gSSOK_QF_SaveDriveEOption, E: µå¶óÀÌºê
    Gui, SSOKQuickFile:Add, Checkbox, x534 y571 w80 h22 vSSOK_QF_SearchDriveF Checked%SSOK_QF_SearchDriveF% gSSOK_QF_SaveDriveFOption, F: µå¶óÀÌºê
    if (!InStr(FileExist("D:"), "D"))
        GuiControl, SSOKQuickFile:Disable, SSOK_QF_SearchDriveD
    if (!InStr(FileExist("E:"), "D"))
        GuiControl, SSOKQuickFile:Disable, SSOK_QF_SearchDriveE
    if (!InStr(FileExist("F:"), "D"))
        GuiControl, SSOKQuickFile:Disable, SSOK_QF_SearchDriveF

    Gui, SSOKQuickFile:Add, Progress, x35 y606 w890 h1 BackgroundD5DDE8 cD5DDE8
    Gui, SSOKQuickFile:Add, Text, x35 y619 w88 h22 c333333, °Ë»ö ÆÄÀÏ ¼³Á¤
    Gui, SSOKQuickFile:Add, Checkbox, x130 y617 w84 h22 vSSOK_QF_ExtHwp Checked%SSOK_QF_ExtHwp% gSSOK_QF_SaveFolderOptions, hwp(ÇÑ±Û)
    Gui, SSOKQuickFile:Add, Checkbox, x220 y617 w84 h22 vSSOK_QF_ExtXls Checked%SSOK_QF_ExtXls% gSSOK_QF_SaveFolderOptions, xls(¿¢¼¿)
    Gui, SSOKQuickFile:Add, Checkbox, x310 y617 w84 h22 vSSOK_QF_ExtDoc Checked%SSOK_QF_ExtDoc% gSSOK_QF_SaveFolderOptions, doc(¿öµå)
    Gui, SSOKQuickFile:Add, Checkbox, x400 y617 w96 h22 vSSOK_QF_ExtPpt Checked%SSOK_QF_ExtPpt% gSSOK_QF_SaveFolderOptions, PPT(½½¶óÀÌµå)
    Gui, SSOKQuickFile:Add, Checkbox, x504 y617 w50 h22 vSSOK_QF_ExtTxt Checked%SSOK_QF_ExtTxt% gSSOK_QF_SaveFolderOptions, txt
    Gui, SSOKQuickFile:Add, Checkbox, x560 y617 w50 h22 vSSOK_QF_ExtPdf Checked%SSOK_QF_ExtPdf% gSSOK_QF_SaveFolderOptions, pdf

    Gui, SSOKQuickFile:Add, Text, x35 y655 w650 h18 c999999, SSOK ÀÚÃ¼°Ë»öÀº D/E/F Áß ¼±ÅÃÇÑ 1°³ µå¶óÀÌºê¸¸ Ãß°¡ °Ë»öÇÕ´Ï´Ù.
    Gui, SSOKQuickFile:Add, Text, x660 y655 w265 h18 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£
    SSOK_GetSidebarAttachedGuiPos(960, 685, SSOK_QF_WinX, SSOK_QF_WinY)
    Gui, SSOKQuickFile:Show, x%SSOK_QF_WinX% y%SSOK_QF_WinY% w960 h685, SSOK ÀÚÁÖ ¿©´Â ÆÄÀÏ
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
    global QIImage12, QIImage13, QIImage14
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
    _orgNameSave := "¼¼Á¾±³"
    _majorAlarmSave := ""
    _majorAlarmEnabledSave := 1
    _majorAlarm2Save := ""
    _majorAlarm2EnabledSave := 1
    if FileExist(QIIni)
    {
        IniRead, _majorTodoRead, %QIIni%, MajorTodos, Memo, __SSOK_EMPTY__
        if (_majorTodoRead != "__SSOK_EMPTY__")
            _majorTodoSave := _majorTodoRead
        IniRead, _orgNameRead, %QIIni%, MajorTodos, OrgName, ¼¼Á¾±³
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
            _orgNameSave := "¼¼Á¾±³"
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

    Gui, SSOKQuickUrl:Destroy
    Gui, SSOKQuickUrl:+AlwaysOnTop +ToolWindow -MinimizeBox
    Gui, SSOKQuickUrl:Color, F7FBFF
    Gui, SSOKQuickUrl:Font, s17 bold, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x25 y16 w930 h34 c005BAC Center, ÀÚÁÖ°¡´Â »çÀÌÆ® URL ¹Ù·Î ¿­±â
    Gui, SSOKQuickUrl:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x25 y52 w930 h20 c555555 Center, ¼ýÀÚ 1~9¹øÅ°¿Í [ÀúÀå&&¿­±â]·Î ¹Ù·Î°¡±â, 10~12¹øÀº ¹öÆ°À¸·Î ½ÇÇà

    Gui, SSOKQuickUrl:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x65 y78 w175 h20 c005BAC Center, ÀÌ¸§
    Gui, SSOKQuickUrl:Add, Text, x250 y78 w500 h20 c005BAC Center, ÁÖ¼Ò

    Gui, SSOKQuickUrl:Font, s10 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x35 y104 w24 h24 c005BAC Center, 1
    Gui, SSOKQuickUrl:Add, Edit, x65 y100 w175 h28 vSSOK_QU_NameEdit1, %SSOK_QU_Name1%
    Gui, SSOKQuickUrl:Add, Edit, x250 y100 w500 h28 vSSOK_QU_Edit1, %SSOK_QU_Url1%
    Gui, SSOKQuickUrl:Add, Button, x760 y99 w160 h30 gSSOK_QU_Open1, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y138 w24 h24 c005BAC Center, 2
    Gui, SSOKQuickUrl:Add, Edit, x65 y134 w175 h28 vSSOK_QU_NameEdit2, %SSOK_QU_Name2%
    Gui, SSOKQuickUrl:Add, Edit, x250 y134 w500 h28 vSSOK_QU_Edit2, %SSOK_QU_Url2%
    Gui, SSOKQuickUrl:Add, Button, x760 y133 w160 h30 gSSOK_QU_Open2, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y172 w24 h24 c005BAC Center, 3
    Gui, SSOKQuickUrl:Add, Edit, x65 y168 w175 h28 vSSOK_QU_NameEdit3, %SSOK_QU_Name3%
    Gui, SSOKQuickUrl:Add, Edit, x250 y168 w500 h28 vSSOK_QU_Edit3, %SSOK_QU_Url3%
    Gui, SSOKQuickUrl:Add, Button, x760 y167 w160 h30 gSSOK_QU_Open3, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y206 w24 h24 c005BAC Center, 4
    Gui, SSOKQuickUrl:Add, Edit, x65 y202 w175 h28 vSSOK_QU_NameEdit4, %SSOK_QU_Name4%
    Gui, SSOKQuickUrl:Add, Edit, x250 y202 w500 h28 vSSOK_QU_Edit4, %SSOK_QU_Url4%
    Gui, SSOKQuickUrl:Add, Button, x760 y201 w160 h30 gSSOK_QU_Open4, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y240 w24 h24 c005BAC Center, 5
    Gui, SSOKQuickUrl:Add, Edit, x65 y236 w175 h28 vSSOK_QU_NameEdit5, %SSOK_QU_Name5%
    Gui, SSOKQuickUrl:Add, Edit, x250 y236 w500 h28 vSSOK_QU_Edit5, %SSOK_QU_Url5%
    Gui, SSOKQuickUrl:Add, Button, x760 y235 w160 h30 gSSOK_QU_Open5, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y274 w24 h24 c005BAC Center, 6
    Gui, SSOKQuickUrl:Add, Edit, x65 y270 w175 h28 vSSOK_QU_NameEdit6, %SSOK_QU_Name6%
    Gui, SSOKQuickUrl:Add, Edit, x250 y270 w500 h28 vSSOK_QU_Edit6, %SSOK_QU_Url6%
    Gui, SSOKQuickUrl:Add, Button, x760 y269 w160 h30 gSSOK_QU_Open6, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y308 w24 h24 c005BAC Center, 7
    Gui, SSOKQuickUrl:Add, Edit, x65 y304 w175 h28 vSSOK_QU_NameEdit7, %SSOK_QU_Name7%
    Gui, SSOKQuickUrl:Add, Edit, x250 y304 w500 h28 vSSOK_QU_Edit7, %SSOK_QU_Url7%
    Gui, SSOKQuickUrl:Add, Button, x760 y303 w160 h30 gSSOK_QU_Open7, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y342 w24 h24 c005BAC Center, 8
    Gui, SSOKQuickUrl:Add, Edit, x65 y338 w175 h28 vSSOK_QU_NameEdit8, %SSOK_QU_Name8%
    Gui, SSOKQuickUrl:Add, Edit, x250 y338 w500 h28 vSSOK_QU_Edit8, %SSOK_QU_Url8%
    Gui, SSOKQuickUrl:Add, Button, x760 y337 w160 h30 gSSOK_QU_Open8, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y376 w24 h24 c005BAC Center, 9
    Gui, SSOKQuickUrl:Add, Edit, x65 y372 w175 h28 vSSOK_QU_NameEdit9, %SSOK_QU_Name9%
    Gui, SSOKQuickUrl:Add, Edit, x250 y372 w500 h28 vSSOK_QU_Edit9, %SSOK_QU_Url9%
    Gui, SSOKQuickUrl:Add, Button, x760 y371 w160 h30 gSSOK_QU_Open9, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y410 w24 h24 c005BAC Center, 10
    Gui, SSOKQuickUrl:Add, Edit, x65 y406 w175 h28 vSSOK_QU_NameEdit10, %SSOK_QU_Name10%
    Gui, SSOKQuickUrl:Add, Edit, x250 y406 w500 h28 vSSOK_QU_Edit10, %SSOK_QU_Url10%
    Gui, SSOKQuickUrl:Add, Button, x760 y405 w160 h30 gSSOK_QU_Open10, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y444 w24 h24 c005BAC Center, 11
    Gui, SSOKQuickUrl:Add, Edit, x65 y440 w175 h28 vSSOK_QU_NameEdit11, %SSOK_QU_Name11%
    Gui, SSOKQuickUrl:Add, Edit, x250 y440 w500 h28 vSSOK_QU_Edit11, %SSOK_QU_Url11%
    Gui, SSOKQuickUrl:Add, Button, x760 y439 w160 h30 gSSOK_QU_Open11, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Add, Text, x35 y478 w24 h24 c005BAC Center, 12
    Gui, SSOKQuickUrl:Add, Edit, x65 y474 w175 h28 vSSOK_QU_NameEdit12, %SSOK_QU_Name12%
    Gui, SSOKQuickUrl:Add, Edit, x250 y474 w500 h28 vSSOK_QU_Edit12, %SSOK_QU_Url12%
    Gui, SSOKQuickUrl:Add, Button, x760 y473 w160 h30 gSSOK_QU_Open12, ÀúÀå&&¿­±â

    Gui, SSOKQuickUrl:Font, s9 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Button, x585 y520 w160 h30 gSSOK_QU_SaveAll, ÀüÃ¼ ÀúÀå

    Gui, SSOKQuickUrl:Font, s8 bold underline c005BAC, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x5 y560 w145 h24 Center +0x200 gSSOK_QU_OpenSchoolSearchFromMenu, [¼¼Á¾ °ü³» ÇÐ±³]
    Gui, SSOKQuickUrl:Add, Text, x150 y560 w120 h24 Center +0x200 gSSOK_QU_OpenSchoolInfoFromMenu, [ÇÐ±³¾Ë¸®¹Ì1]
    Gui, SSOKQuickUrl:Add, Text, x270 y560 w30 h24 Center +0x200 gSSOK_QU_OpenSchoolInfo2FromMenu, 2
    Gui, SSOKQuickUrl:Add, Text, x300 y560 w175 h24 Center +0x200 gSSOK_QU_OpenLocalFinanceInfoFromMenu, [Áö¹æ±³À°ÀçÁ¤ ¾Ë¸®¹Ì]
    Gui, SSOKQuickUrl:Add, Text, x475 y560 w135 h24 Center +0x200 gSSOK_QU_OpenEduOfficeSearchFromMenu, [±³À°Ã» ¾÷¹«´ã´ç]
    Gui, SSOKQuickUrl:Add, Text, x610 y560 w190 h24 Center +0x200 gSSOK_QU_OpenSchoolSupportInfoFromMenu, [ÇÐ±³Áö¿øº»ºÎ ¾÷¹«¾È³»]
    Gui, SSOKQuickUrl:Add, Text, x800 y560 w155 h24 Center +0x200 gSSOK_QU_OpenContractInfoFromMenu, [°Å·¡Ã³ °è¾àÁ¤º¸]

    Gui, SSOKQuickUrl:Font, s8 norm, Malgun Gothic
    Gui, SSOKQuickUrl:Add, Text, x35 y600 w650 h18 c999999, ¼ýÀÚ 1~9¹øÅ° ¶Ç´Â [ÀúÀå&¿­±â]·Î ¹Ù·Î°¡±â
    Gui, SSOKQuickUrl:Add, Text, x585 y620 w335 h18 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£
    SSOK_GetSidebarAttachedGuiPos(960, 645, SSOK_QU_WinX, SSOK_QU_WinY)
    Gui, SSOKQuickUrl:Show, x%SSOK_QU_WinX% y%SSOK_QU_WinY% w960 h645, SSOK ÀÚÁÖ°¡´Â »çÀÌÆ®
return

SSOKQuickUrlGuiEscape:
SSOKQuickUrlGuiClose:
    Gui, SSOKQuickUrl:Destroy
return

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
        defaultName := "°è¾àÁ¤º¸°ø°³"
        defaultUrl := "https://www.sje.go.kr/sje/ir/selectPrvCntrList.do?mi=52618"
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
; Win + F9 : Gemini ¹Ù·Î ¿­±â
; - ºí·Ï ÁöÁ¤ ½Ã: ¼±ÅÃ ¹®±¸¸¦ Gemini ÀÔ·ÂÃ¢¿¡ °Ë»ö¾î/Áú¹®À¸·Î ºÙ¿©³Ö±â
; - ºí·Ï ¹ÌÁöÁ¤ ½Ã: Gemini »õ ÅÇ¸¸ ¿­±â
; - Chrome ¡æ Edge ¡æ ±âº» ºê¶ó¿ìÀú ¼øÀ¸·Î ½ÇÇà
; =========================================================
#F9::
    Gosub, SSOK_WinHelp_CancelDirect
    Gosub, SSOK_DoF9
return

SSOK_DoF9:
    ClipSavedF9 := ClipboardAll
    ; ºí·Ï ÁöÁ¤ ¿©ºÎ È®ÀÎ
    f9Text := ""
    if (SSOK_CopyClipboardText(f9RawText, 0.35, 2) && f9RawText != "")
        f9Text := Trim(f9RawText)

    Clipboard := ClipSavedF9

    if (f9Text = "")
    {
        SSOK_OpenGeminiBlankPreferred()
        return
    }

    SSOK_OpenGeminiAndPaste(f9Text)
return

SSOK_OpenGeminiBlankPreferred()
{
    SSOK_OpenUrlPreferred("https://gemini.google.com/app")
}

SSOK_OpenGeminiAndPaste(queryText)
{
    ClipSavedGemini := ClipboardAll

    browserExe := SSOK_OpenUrlPreferred("https://gemini.google.com/app")
    if (browserExe = "")
        Sleep, 1800

    if (browserExe != "" && browserExe != "default")
        WinWaitActive, ahk_exe %browserExe%, , 8

    ; ÆäÀÌÁö ·Îµå ¿©À¯ ´ë±â ÈÄ ¼±ÅÃ ¹®±¸ ÀÔ·Â
    Sleep, 1800
    if (!SSOK_SetClipboardTextWithWait(queryText, 0.7, 3))
    {
        Clipboard := ClipSavedGemini
        return
    }
    Send, ^v
    Sleep, 250
    Clipboard := ClipSavedGemini
}


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


; Gemini AI µµ¿ì¹Ì º»¹®
; - ½ÇÇà ´ÜÃàÅ°: Win+F3
; =========================================================
SSOK_DoF3:
    ; Win+F3À» ¸ÕÀú ´©¸¥ µÚ ºí·Ï ÁöÁ¤ÇÏ´Â Èå¸§µµ Áö¿øÇÏ±â À§ÇØ
    ; AI ¸Þ´º¸¦ ¶ç¿ì±â Àü ÇöÀç ÀÛ¾÷Ã¢À» ±â¾ïÇØ µÒ
    SSOK_AI_TargetHwnd := WinExist("A")
    if (SSOK_SidebarTargetHwnd != "")
        SSOK_AI_TargetHwnd := SSOK_SidebarTargetHwnd

    ClipSaved := ClipboardAll
    Clipboard := ""

    ; ±âÁ¸ ¹æ½Ä Áö¿ø: ºí·Ï ÁöÁ¤/º¹»ç ÈÄ Win+F3 ½ÇÇà
    ; Æ÷Ä¿½º°¡ ´Ê°Ô µ¹¾Æ¿À´Â °æ¿ì°¡ ÀÖ¾î 2È¸ È®ÀÎ
    Sleep, 120
    SendInput, ^c
    ClipWait, 0.8

    SSOK_AI_SelectedText := ""
    if (!ErrorLevel && Clipboard != "")
    {
        SSOK_AI_SelectedText := Trim(Clipboard)
    }
    else
    {
        Clipboard := ""
        Sleep, 120
        SendInput, ^c
        ClipWait, 0.8
        if (!ErrorLevel && Clipboard != "")
            SSOK_AI_SelectedText := Trim(Clipboard)
    }

    Clipboard := ClipSaved
    Gosub, SSOK_ShowGeminiAIMenu
return

SSOK_ShowGeminiAIMenu:
    Gosub, SSOK_AI_LoadSites
    Gui, SSOKGeminiAI:Destroy
    Gui, SSOKGeminiAI:+AlwaysOnTop +ToolWindow -MinimizeBox +HwndSSOK_AI_GuiHwnd
    Gui, SSOKGeminiAI:Color, F7FBFF
    Gui, SSOKGeminiAI:Font, s17 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x35 y28 w890 h34 c005BAC Center, SSOK Gemini AI µµ¿ì¹Ì
    Gui, SSOKGeminiAI:Font, s9 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x35 y76 w890 h24 c555555 Center, ÀÛ¼ºÀ» ¿øÇÏ´Â ¹®±¸¸¦ ºí·° ÁöÁ¤ÇÏ°í ¾Æ·¡ ¹öÆ°À» ¼±ÅÃÇÏ¸é, Gemini¿¡ ÇÁ·ÒÇÁÆ®°¡ ÀÚµ¿ ÀÔ·ÂµË´Ï´Ù.
    Gui, SSOKGeminiAI:Font, s11 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, GroupBox, x50 y116 w425 h180 c005BAC, ±â¾È¹®
    Gui, SSOKGeminiAI:Add, GroupBox, x485 y116 w425 h180 c005BAC, °èÈ¹¼­
    Gui, SSOKGeminiAI:Font, s10 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Button, x65 y160 w395 h54 gSSOK_AI_DraftMemo, 1. AI ÀÛ¼º
    Gui, SSOKGeminiAI:Add, Button, x500 y160 w395 h54 gSSOK_AI_PlanDoc, 1. AI ÀÛ¼º
    Gui, SSOKGeminiAI:Add, Button, x65 y226 w395 h54 gSSOK_AI_ReportConvert1, 2. HWP ¾ç½Ä º¯È¯
    Gui, SSOKGeminiAI:Add, Button, x500 y226 w395 h54 gSSOK_AI_ReportConvert2, 2. HWP ¾ç½Ä º¯È¯

    Gui, SSOKGeminiAI:Font, s9 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x65 y315 w450 h22 c777777, ºí·Ï ÁöÁ¤ÇÏÁö ¾Ê¾Æµµ Gemini¿¡¼­ ¿øÇÏ´Â ¹®±¸¸¦ ÀÛ¼ºÇÒ ¼ö ÀÖ½À´Ï´Ù.

    Gui, SSOKGeminiAI:Font, s9 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Button, x65 y337 w155 h30 gSSOK_AI_OpenSite1, %SSOK_AI_SiteName1%
    Gui, SSOKGeminiAI:Add, Button, x225 y337 w155 h30 gSSOK_AI_OpenSite2, %SSOK_AI_SiteName2%
    Gui, SSOKGeminiAI:Add, Button, x385 y337 w155 h30 gSSOK_AI_OpenSite3, %SSOK_AI_SiteName3%
    Gui, SSOKGeminiAI:Add, Button, x545 y337 w155 h30 gSSOK_AI_OpenSite4, %SSOK_AI_SiteName4%
    Gui, SSOKGeminiAI:Add, Button, x705 y337 w155 h30 gSSOK_AI_OpenSite5, %SSOK_AI_SiteName5%

    Gui, SSOKGeminiAI:Font, s10 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, GroupBox, x50 y382 w860 h205 c005BAC, AI »çÀÌÆ® ¹Ù·Î°¡±â / ÀÌ¸§¡¤ÁÖ¼Ò ¼öÁ¤
    Gui, SSOKGeminiAI:Font, s8 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x95 y408 w145 h18 c005BAC Center, ÀÌ¸§
    Gui, SSOKGeminiAI:Add, Text, x250 y408 w480 h18 c005BAC Center, ÁÖ¼Ò

    Gui, SSOKGeminiAI:Font, s9 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x65 y433 w24 h24 c005BAC Center, 1
    Gui, SSOKGeminiAI:Add, Edit, x95 y429 w145 h28 vSSOK_AI_SiteNameEdit1, %SSOK_AI_SiteName1%
    Gui, SSOKGeminiAI:Add, Edit, x250 y429 w480 h28 vSSOK_AI_SiteUrlEdit1, %SSOK_AI_SiteUrl1%
    Gui, SSOKGeminiAI:Add, Button, x745 y428 w150 h30 gSSOK_AI_OpenSite1, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x65 y464 w24 h24 c005BAC Center, 2
    Gui, SSOKGeminiAI:Add, Edit, x95 y460 w145 h28 vSSOK_AI_SiteNameEdit2, %SSOK_AI_SiteName2%
    Gui, SSOKGeminiAI:Add, Edit, x250 y460 w480 h28 vSSOK_AI_SiteUrlEdit2, %SSOK_AI_SiteUrl2%
    Gui, SSOKGeminiAI:Add, Button, x745 y459 w150 h30 gSSOK_AI_OpenSite2, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x65 y495 w24 h24 c005BAC Center, 3
    Gui, SSOKGeminiAI:Add, Edit, x95 y491 w145 h28 vSSOK_AI_SiteNameEdit3, %SSOK_AI_SiteName3%
    Gui, SSOKGeminiAI:Add, Edit, x250 y491 w480 h28 vSSOK_AI_SiteUrlEdit3, %SSOK_AI_SiteUrl3%
    Gui, SSOKGeminiAI:Add, Button, x745 y490 w150 h30 gSSOK_AI_OpenSite3, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x65 y526 w24 h24 c005BAC Center, 4
    Gui, SSOKGeminiAI:Add, Edit, x95 y522 w145 h28 vSSOK_AI_SiteNameEdit4, %SSOK_AI_SiteName4%
    Gui, SSOKGeminiAI:Add, Edit, x250 y522 w480 h28 vSSOK_AI_SiteUrlEdit4, %SSOK_AI_SiteUrl4%
    Gui, SSOKGeminiAI:Add, Button, x745 y521 w150 h30 gSSOK_AI_OpenSite4, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x65 y557 w24 h24 c005BAC Center, 5
    Gui, SSOKGeminiAI:Add, Edit, x95 y553 w145 h28 vSSOK_AI_SiteNameEdit5, %SSOK_AI_SiteName5%
    Gui, SSOKGeminiAI:Add, Edit, x250 y553 w480 h28 vSSOK_AI_SiteUrlEdit5, %SSOK_AI_SiteUrl5%
    Gui, SSOKGeminiAI:Add, Button, x745 y552 w150 h30 gSSOK_AI_OpenSite5, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Font, s8 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x65 y602 w520 h18 c999999, 5°³ AI »çÀÌÆ® ÀÌ¸§°ú ÁÖ¼Ò´Â ssok.ini¿¡ ÀúÀåµË´Ï´Ù.
    Gui, SSOKGeminiAI:Add, Button, x620 y595 w120 h30 gSSOK_AI_SaveSites, ÀüÃ¼ ÀúÀå
    Gui, SSOKGeminiAI:Add, Text, x500 y632 w425 h24 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£
    SSOK_GetSidebarAttachedGuiPos(960, 667, SSOK_AI_WinX, SSOK_AI_WinY)
    Gui, SSOKGeminiAI:Show, x%SSOK_AI_WinX% y%SSOK_AI_WinY% w960 h667, SSOK Gemini AI µµ¿ì¹Ì
    SetTimer, SSOK_AI_TrackTargetWindow, 200
return

SSOK_AI_EditDoc:
    Gosub, SSOK_AI_CaptureSelectionBeforeRun
    Gui, SSOKGeminiAI:Destroy
    prompt := SSOK_BuildGeminiPrompt("EDIT", SSOK_AI_SelectedText)
    Gosub, SSOK_RunGeminiWithPrompt
return

SSOK_AI_DraftMemo:
    Gosub, SSOK_AI_CaptureSelectionBeforeRun
    Gui, SSOKGeminiAI:Destroy
    prompt := SSOK_BuildGeminiPrompt("MEMO", SSOK_AI_SelectedText)
    Gosub, SSOK_RunGeminiWithPrompt
return

SSOK_AI_PlanDoc:
    Gosub, SSOK_AI_CaptureSelectionBeforeRun
    Gui, SSOKGeminiAI:Destroy
    prompt := SSOK_BuildGeminiPrompt("PLAN", SSOK_AI_SelectedText)
    Gosub, SSOK_RunGeminiWithPrompt
return

SSOK_AI_ReportConvert:
SSOK_AI_ReportConvert2:
    Gosub, SSOK_AI_CaptureSelectionBeforeRun
    Gui, SSOKGeminiAI:Destroy
    reportSource := Trim(SSOK_AI_SelectedText)
    if (reportSource = "")
        reportSource := Trim(Clipboard)
    if (reportSource = "")
    {
        MsgBox, 48, SSOK HWP ¾ç½Ä º¯È¯, Gemini¿¡¼­ ÀÛ¼ºµÈ ÅØ½ºÆ®¸¦ ºí·Ï ÁöÁ¤ÇÏ°Å³ª º¹»çÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_CreateHwpxReportFromText(reportSource, "ssok_ai_report2_template.hwtx")
return

SSOK_AI_ReportConvert1:
    Gosub, SSOK_AI_CaptureSelectionBeforeRun
    Gui, SSOKGeminiAI:Destroy
    reportSource := Trim(SSOK_AI_SelectedText)
    if (reportSource = "")
        reportSource := Trim(Clipboard)
    if (reportSource = "")
    {
        MsgBox, 48, SSOK HWP ¾ç½Ä º¯È¯, Gemini¿¡¼­ ÀÛ¼ºµÈ ÅØ½ºÆ®¸¦ ºí·Ï ÁöÁ¤ÇÏ°Å³ª º¹»çÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
        return
    }
    SSOK_CreateHwpxReportFromText(reportSource, "ssok_ai_report1_template.hwtx")
return

SSOK_AI_SearchOnly:
    Gosub, SSOK_AI_CaptureSelectionBeforeRun
    Gui, SSOKGeminiAI:Destroy
    prompt := SSOK_BuildGeminiPrompt("SEARCH", SSOK_AI_SelectedText)
    Gosub, SSOK_RunGeminiWithPrompt
return

SSOK_AI_CaptureSelectionBeforeRun:
    ; ±âÁ¸ ¹æ½Ä°ú »õ ¹æ½Ä ¸ðµÎ Áö¿ø
    ; 1) ºí·Ï ÁöÁ¤ ¡æ Win+F3 ¡æ ¸Þ´º ¼±ÅÃ
    ; 2) Win+F3 ¡æ ºí·Ï ÁöÁ¤ ¡æ ¸Þ´º ¼±ÅÃ
    ; ¸Þ´º ¼±ÅÃ Á÷Àü¿¡ ¿ø·¡ ÀÛ¾÷Ã¢À¸·Î µ¹¾Æ°¡ ÇöÀç ¼±ÅÃ¿µ¿ªÀ» ´Ù½Ã º¹»çÇÔ
    ClipSaved3 := ClipboardAll
    Clipboard := ""
    SetTimer, SSOK_AI_TrackTargetWindow, Off

    Gui, SSOKGeminiAI:Hide
    Sleep, 120

    if (SSOK_AI_TargetHwnd != "")
    {
        WinActivate, ahk_id %SSOK_AI_TargetHwnd%
        WinWaitActive, ahk_id %SSOK_AI_TargetHwnd%,, 1.2
        Sleep, 180
    }

    SendInput, ^c
    ClipWait, 1.0
    if (!ErrorLevel && Clipboard != "")
    {
        SSOK_AI_SelectedText := Trim(Clipboard)
    }
    else
    {
        Clipboard := ""
        Sleep, 180
        SendInput, ^c
        ClipWait, 1.0
        if (!ErrorLevel && Clipboard != "")
            SSOK_AI_SelectedText := Trim(Clipboard)
    }

    Clipboard := ClipSaved3
return

SSOK_AI_TrackTargetWindow:
    activeHwnd := WinExist("A")
    if (activeHwnd != "" && activeHwnd != SSOK_AI_GuiHwnd)
        SSOK_AI_TargetHwnd := activeHwnd
return

; =========================================================
; Win+F3 AI ¸Þ´º ÇÏ´Ü 5°³ »çÀÌÆ® ¼öÁ¤/¿­±â
; - ±âº»°ª: ChatGPT, Gemini, Copilot, Perplexity, Claude
; - ÀúÀå À§Ä¡: ssok.ini [F3AISites]
; =========================================================
SSOK_AI_SetSiteDefaults:
    Loop, 5
    {
        idx := A_Index
        SSOK_AI_GetSiteDefault(idx, defaultName, defaultUrl)
        SSOK_AI_SiteName%idx% := defaultName
        SSOK_AI_SiteUrl%idx% := defaultUrl
    }
return

SSOK_AI_GetSiteDefault(index, ByRef defaultName, ByRef defaultUrl)
{
    defaultName := "AI" . index
    defaultUrl := ""

    if (index = 1)
    {
        defaultName := "Á¦¹Ì³ªÀÌ"
        defaultUrl := "https://gemini.google.com/"
    }
    else if (index = 2)
    {
        defaultName := "ÃªÁöÇÇÆ¼"
        defaultUrl := "https://chatgpt.com/"
    }
    else if (index = 3)
    {
        defaultName := "ÄÚÆÄÀÏ·µ"
        defaultUrl := "https://copilot.microsoft.com/"
    }
    else if (index = 4)
    {
        defaultName := "Perplexity"
        defaultUrl := "https://www.perplexity.ai/"
    }
    else if (index = 5)
    {
        defaultName := "Å¬·Îµå"
        defaultUrl := "https://claude.ai/"
    }
}

SSOK_AI_LoadSites:
    Gosub, SSOK_AI_SetSiteDefaults
    SSOK_AI_Ini := SSOK_IniFile
    if FileExist(SSOK_AI_Ini)
    {
        Loop, 5
        {
            idx := A_Index
            defaultName := SSOK_AI_SiteName%idx%
            defaultUrl := SSOK_AI_SiteUrl%idx%
            IniRead, readName, %SSOK_AI_Ini%, F3AISites, Name%idx%, %defaultName%
            IniRead, readUrl, %SSOK_AI_Ini%, F3AISites, Url%idx%, %defaultUrl%
            if (readName != "ERROR" && Trim(readName) != "")
                SSOK_AI_SiteName%idx% := readName
            if (readUrl != "ERROR")
                SSOK_AI_SiteUrl%idx% := readUrl
        }
    }
return

SSOK_AI_SaveSitesFromGui(showNotice := 0)
{
    global
    Gui, SSOKGeminiAI:Submit, NoHide
    Loop, 5
    {
        idx := A_Index
        nameVar := SSOK_AI_SiteNameEdit%idx%
        urlVar := SSOK_AI_SiteUrlEdit%idx%
        if (Trim(nameVar) = "")
        {
            SSOK_AI_GetSiteDefault(idx, defaultName, defaultUrl)
            nameVar := defaultName
        }
        SSOK_AI_SiteName%idx% := nameVar
        SSOK_AI_SiteUrl%idx% := urlVar
    }
    SSOK_AI_SaveActive := 1
    SSOK_SaveUnifiedIni()
    SSOK_AI_SaveActive := 0
    if (showNotice)
        MsgBox, 64, SSOK ¾È³», Win+F3 AI »çÀÌÆ® 5°³¸¦ ÀúÀåÇß½À´Ï´Ù.`n`nÀúÀå À§Ä¡: ssok.ini
}

SSOK_AI_OpenSiteIndex(index)
{
    global
    SSOK_AI_SaveSitesFromGui(0)
    urlVar := SSOK_AI_SiteUrl%index%
    urlVar := SSOK_QU_NormalizeUrl(urlVar)
    if (urlVar = "")
    {
        MsgBox, 48, SSOK ¾È³», AI »çÀÌÆ® ÁÖ¼Ò°¡ ºñ¾î ÀÖ½À´Ï´Ù.`n`nÁÖ¼Ò¸¦ ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    SetTimer, SSOK_AI_TrackTargetWindow, Off
    Gui, SSOKGeminiAI:Destroy
    SSOK_OpenUrlPreferred(urlVar)
}

SSOK_AI_SaveSites:
    SSOK_AI_SaveSitesFromGui(1)
return

SSOK_AI_OpenSite1:
    SSOK_AI_OpenSiteIndex(1)
return
SSOK_AI_OpenSite2:
    SSOK_AI_OpenSiteIndex(2)
return
SSOK_AI_OpenSite3:
    SSOK_AI_OpenSiteIndex(3)
return
SSOK_AI_OpenSite4:
    SSOK_AI_OpenSiteIndex(4)
return
SSOK_AI_OpenSite5:
    SSOK_AI_OpenSiteIndex(5)
return

; AI º¸°í¼­ º¯È¯ ±â´ÉÀº º°µµ ¸ðµâ·Î ºÐ¸®Çß½À´Ï´Ù.
#Include %A_ScriptDir%\ssok_ai_report.ahk

SSOK_RunGeminiWithPrompt:
    ClipSaved2 := ClipboardAll

    if (prompt = "")
    {
        Clipboard := ClipSaved2
        return
    }

    browserExe := SSOK_OpenUrlPreferred("https://gemini.google.com/app")
    if (browserExe = "")
    {
        Sleep, 1800
        Clipboard := prompt
        MsgBox, 48, SSOK AI, ºê¶ó¿ìÀú·Î Gemini¸¦ ¿­¾ú½À´Ï´Ù.`nÇÁ·ÒÇÁÆ®¸¦ Á÷Á¢ ºÙ¿©³Ö±â ÇØÁÖ¼¼¿ä.`n`nÅ¬¸³º¸µå¿¡ ÇÁ·ÒÇÁÆ®°¡ º¹»çµÇ¾î ÀÖ½À´Ï´Ù.
        return
    }

    if (browserExe != "" && browserExe != "default")
        WinWaitActive, ahk_exe %browserExe%, , 10

    ; Gemini ÆäÀÌÁö¿Í ÀÔ·ÂÃ¢ ÁØºñ ½Ã°£À» ³Ë³ËÈ÷ µÒ
    Sleep, 2200
    if (!SSOK_SetClipboardTextWithWait(prompt, 0.7, 3))
    {
        Clipboard := ClipSaved2
        MsgBox, 48, SSOK AI, Gemini·Î º¸³¾ ¹®±¸¸¦ Å¬¸³º¸µå¿¡ º¹»çÇÏÁö ¸øÇß½À´Ï´Ù.
        return
    }
    Sleep, 150
    SendInput, ^v
    Sleep, 700
    Clipboard := ClipSaved2
return

SSOKGeminiAIGuiEscape:
SSOKGeminiAIGuiClose:
    SetTimer, SSOK_AI_TrackTargetWindow, Off
    Gui, SSOKGeminiAI:Destroy
return

SSOK_BuildGeminiPrompt(mode, selectedText)
{
    selectedText := Trim(selectedText)
    fence := Chr(96) . Chr(96) . Chr(96)

    if (selectedText = "")
        selectedBlock := "[ÀÌ ¹®ÀåÀ» Áö¿ì°í, ¿äÃ»ÇÏ°íÀÚ ÇÏ´Â ³»¿ëÀ» ÀÛ¼ºÇØÁÖ¼¼¿ä. ¿¹½Ã) 5¿ù 12ÀÏ ÇÐ±³ ÃàÁ¦¿ë ¿î¿µ ¹°Ç° 0 ¿Ü 0Á¾ ±¸ÀÔ ¶Ç´Â  OOO Çà»ç °èÈ¹ ÃßÁø µî]"
    else
        selectedBlock := selectedText

    if (mode = "SEARCH")
    {
        if (selectedText = "")
            return ""
        return selectedText
    }

    commonRule =
(
´ç½ÅÀº ´ëÇÑ¹Î±¹ ÇÐ±³ ÇàÁ¤½Ç¡¤±³¹«½Ç¡¤±³À°Áö¿øÃ»¡¤½Ãµµ±³À°Ã» °ø¹®¼­ ÀÛ¼º °æÇèÀÌ ¸Å¿ì Ç³ºÎÇÑ ±³À°ÇàÁ¤ Àü¹®°¡ÀÔ´Ï´Ù.
¾Æ·¡ ¿ø¹®À» ¹ÙÅÁÀ¸·Î K-¿¡µàÆÄÀÎ ³»ºÎ°áÀç¡¤°ø¹®¼­¡¤°èÈ¹¼­¿¡ ±×´ë·Î ºÙ¿©³ÖÀ» ¼ö ÀÖ´Â ÃÖÁ¾º»¸¸ ÀÛ¼ºÇØ ÁÖ¼¼¿ä.


[°ø¹®¼­ ÀÛ¼º ±âÁØ ¿ì¼±¼øÀ§: ¸Å¿ì Áß¿ä]
- °ø¹®¼­ ÀÛ¼º ±ÔÁ¤, ¹®¼­ Çü½Ä, ¹øÈ£ Ã¼°è, ºÙÀÓ Ç¥±â, ³¡. Ç¥±â, ¶ç¾î¾²±â, ¾î¹® Ç¥ÇöÀ» ÆÇ´ÜÇÒ ¶§´Â ¹Ýµå½Ã °Ë»ö °¡´ÉÇÑ ÃÖ½Å³âµµ ¡¸ÇàÁ¤¾÷¹«¿î¿µ Æí¶÷¡¹À» ÃÖ¿ì¼± ±âÁØÀ¸·Î »ï½À´Ï´Ù.
- Ç¥±â¹ý, ¶ç¾î¾²±â, ¸ÂÃã¹ý, ¹®ÀåºÎÈ£, ¿Ü·¡¾î¡¤·Î¸¶ÀÚ¡¤ÇÑ±Û ¸ÂÃã¹ý µî ¾î¹® ±Ô¹üÀº ¡¸±¹¾î±âº»¹ý¡¹ ¹× ±¹¸³±¹¾î¿ø ¾î¹® ±Ô¹üÀ» Àý´ë ±âÁØÀ¸·Î »ï½À´Ï´Ù.
- ±âÁ¸ °üÇà, Áö¿ªº° ÀÓÀÇ ¼­½Ä, ¿À·¡µÈ ¿¹½Ãº¸´Ù ÃÖ½Å³âµµ ¡¸ÇàÁ¤¾÷¹«¿î¿µ Æí¶÷¡¹°ú ¡¸±¹¾î±âº»¹ý¡¹¡¤±¹¸³±¹¾î¿ø ¾î¹® ±Ô¹üÀ» ¿ì¼±ÇÕ´Ï´Ù.
- ±âÁØÀÌ Ãæµ¹ÇÏ°Å³ª ÃÖ½Å ±Ù°Å¸¦ È®Á¤ÇÒ ¼ö ¾øÀ¸¸é ÀÓÀÇ·Î ´ÜÁ¤ÇÏÁö ¸»°í [ÃÖ½Å ±âÁØ È®ÀÎ ÇÊ¿ä]·Î Ç¥½ÃÇÕ´Ï´Ù.
- ´äº¯ ÀÛ¼º ½Ã ÃÖ½Å³âµµ ¡¸ÇàÁ¤¾÷¹«¿î¿µ Æí¶÷¡¹, ¡¸±¹¾î±âº»¹ý¡¹, ±¹¸³±¹¾î¿ø ¾î¹® ±Ô¹ü¿¡ ¾î±ß³ª´Â Ç¥Çö¡¤¼­½ÄÀº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.

[ÃÖ¿ì¼± ¸ñÇ¥]
- »ç¿ëÀÚ°¡ ´äº¯ ÀüÃ¼¸¦ º¹»çÇÏ¿© ÇÑ±Û(HWP), K-¿¡µàÆÄÀÎ, ¸Þ¸ðÀå¿¡ ºÙ¿©³Ö¾úÀ» ¶§ 1. 2. 3. °¡. ³ª. ´Ù. 1) 2) 3) °¡) ³ª) ´Ù) - ±âÈ£°¡ ¸ðµÎ ºüÁöÁö ¾Ê°í ±×´ë·Î º¹»çµÇ¾î¾ß ÇÕ´Ï´Ù.
- ´äº¯Ã¢¿¡¼­ 1. 2. 3. ¼ýÀÚ ¹øÈ£°¡ ÀÚµ¿¸ñ·ÏÀ¸·Î Ã³¸®µÇ¾î º¹»ç ½Ã ºüÁö´Â ¹®Á¦¸¦ ¹æÁöÇÏ±â À§ÇØ ÃÖÁ¾ ´äº¯Àº ¹Ýµå½Ã text ÄÚµåºí·Ï ¾È¿¡¸¸ ÀÛ¼ºÇÕ´Ï´Ù.
- ÄÚµåºí·ÏÀº ÄÚµå ÀÛ¼º ¸ñÀûÀÌ ¾Æ´Ï¶ó HWP, K-¿¡µàÆÄÀÎ, ¸Þ¸ðÀå¿¡ ¹øÈ£±îÁö ±×´ë·Î º¹»çµÇµµ·Ï ÇÏ±â À§ÇÑ ÀÏ¹Ý ÅØ½ºÆ® º¸°ü¿ëÀÔ´Ï´Ù.
- ¸ðµç ¹øÈ£¿Í ±âÈ£´Â Å°º¸µå·Î Á÷Á¢ Ä£ ÀÏ¹Ý ÅØ½ºÆ® ¹®ÀÚÃ³·³ Ãâ·ÂÇÕ´Ï´Ù.

[Àý´ë Ãâ·Â ±ÔÄ¢]
- ÃÖÁ¾ ´äº¯Àº ¹Ýµå½Ã %fence%text ·Î ½ÃÀÛÇÏ°í %fence% ·Î ³¡³³´Ï´Ù.
- ÄÚµåºí·Ï ¹Û¿¡´Â ¼³¸í, ¾È³»¹®, ÀÎ»ç¸», °ËÅä ÀÇ°ßÀ» Àý´ë ¾²Áö ¾Ê½À´Ï´Ù.
- ÀÏ¹Ý Markdown ¼­½ÄÀº ±ÝÁöÇÏµÇ, º¹»ç ¾ÈÁ¤¼ºÀ» À§ÇÑ text ÄÚµåºí·Ï¸¸ ¹Ýµå½Ã »ç¿ëÇÕ´Ï´Ù.
- ÀÚµ¿ ¸ñ·Ï ±â´É Àý´ë ±ÝÁö
- ¹øÈ£ ÀÚµ¿ »ý¼º Àý´ë ±ÝÁö
- Ç¥ Àý´ë ±ÝÁö
- ±½°Ô Ç¥½Ã, Á¦¸ñ ¼­½Ä, ÀÎ¿ë¹® Àý´ë ±ÝÁö
- ºÒ¸´ Æ¯¼ö¹®ÀÚ(?, ¡ß, ¡Ø, ¡Û, ¡à µî) Àý´ë ±ÝÁö
- HTML ÅÂ±× Àý´ë ±ÝÁö
- ÃÖÁ¾ ¹®¼­ º»¹®¸¸ ÄÚµåºí·Ï ¾È¿¡ Ãâ·ÂÇÕ´Ï´Ù.

[ÄÚµåºí·Ï º¹»ç ¾ÈÁ¤È­ ÇÊ¼ö ±ÔÄ¢]
- ÄÚµåºí·Ï ¾ÈÀÇ 1. 2. 3. °¡. ³ª. ´Ù. 1) 2) 3) °¡) ³ª) ´Ù) - ±âÈ£´Â ¸ðµÎ ½ÇÁ¦ Å°º¸µå ¹®ÀÚ·Î Á÷Á¢ Ãâ·ÂÇÕ´Ï´Ù.
- ÄÚµåºí·Ï ¾È¿¡¼­´Â ÀÚµ¿¸ñ·Ï, HTML ¸ñ·Ï, ¼­½Ä ¸ñ·ÏÀ» Àý´ë »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
- ÄÚµåºí·Ï ¾ÈÀÇ ¹®¼­ º»¹®¿¡´Â ºÒÇÊ¿äÇÑ ºó ÁÙÀ» ³ÖÁö ¾Ê½À´Ï´Ù.
- ºó ÁÙ 1ÁÙÀº º»¹®°ú ºÙÀÓ »çÀÌ, Áï ºÙÀÓ ¹Ù·Î ¾Õ¿¡¸¸ ³Ö½À´Ï´Ù.
- ºÙÀÓÀÌ ¾ø´Â °æ¿ì¿¡´Â ºó ÁÙ ¾øÀÌ ¸¶Áö¸· ÁÙ¿¡ ³¡.¸¸ ÀÛ¼ºÇÕ´Ï´Ù.

[¹øÈ£ µÚ ÇÑ Ä­ À¯Áö ±ÔÄ¢]
- Å« Ç×¸ñ ¹øÈ£´Â '1. °ü·Ã:', '2. º»¹® ¹®Àå', '3. ÇÊ¿äÇÑ °æ¿ì Ãß°¡ Å« Ç×¸ñ'Ã³·³ ¹øÈ£ µÚ¿¡ ¹Ýµå½Ã ÇÑ Ä­À» ¶ç¿ì°í ¾¹´Ï´Ù.
- Áß°£ Ç×¸ñÀº '  °¡. Ç×¸ñ¸í: ³»¿ë'Ã³·³ °¡. µÚ¿¡ ¹Ýµå½Ã ÇÑ Ä­À» ¶ç¿ì°í ¾¹´Ï´Ù.
- ¼¼ºÎ Ç×¸ñÀº '    1) ¼¼ºÎ³»¿ë: ³»¿ë'Ã³·³ 1) µÚ¿¡ ¹Ýµå½Ã ÇÑ Ä­À» ¶ç¿ì°í ¾¹´Ï´Ù.
- ´õ ³·Àº Ç×¸ñÀº '      °¡) ¼¼ºÎ³»¿ë'Ã³·³ °¡) µÚ¿¡ ¹Ýµå½Ã ÇÑ Ä­À» ¶ç¿ì°í ¾¹´Ï´Ù.
- º¸Á¶ ¼³¸í ÇÏÀÌÇÂÀº '    - º¸Á¶ ¼³¸í'Ã³·³ ÇÏÀÌÇÂ µÚ¿¡ ¹Ýµå½Ã ÇÑ Ä­À» µÓ´Ï´Ù.
- º»¹® Áß 1. 2. 3. / °¡. ³ª. ´Ù. / 1) 2) 3) Ç×¸ñ »çÀÌ¿¡´Â ºó ÁÙÀ» Àý´ë ³ÖÁö ¾Ê°í, ºÙÀÓ ¹Ù·Î ¾Õ¿¡¸¸ ºó ÁÙ 1ÁÙÀ» µÓ´Ï´Ù.

[°ø¹® °èÃþ Á¤·Ä ±ÔÄ¢]
- Å« Ç×¸ñÀº ¹Ýµå½Ã ¸Ç ¿ÞÂÊ¿¡¼­ ½ÃÀÛÇÕ´Ï´Ù. ¾Õ¿¡ °ø¹éÀ» ³ÖÁö ¾Ê½À´Ï´Ù.
1. °ü·Ã:
2. º»¹® ¹®Àå
3. ÇÊ¿äÇÑ °æ¿ì Ãß°¡ Å« Ç×¸ñ
- Áß°£ Ç×¸ñÀº ¹Ýµå½Ã ¾Õ¿¡ °ø¹é 2Ä­À» µÓ´Ï´Ù.
  °¡. Ç×¸ñ¸í: ³»¿ë
  ³ª. Ç×¸ñ¸í: ³»¿ë
  ´Ù. Ç×¸ñ¸í: ³»¿ë
  ¶ó. Ç×¸ñ¸í: ³»¿ë
- ¼¼ºÎ Ç×¸ñÀº ¹Ýµå½Ã ¾Õ¿¡ °ø¹é 4Ä­À» µÓ´Ï´Ù.
    1) ¼¼ºÎ³»¿ë: ³»¿ë
    2) ¼¼ºÎ³»¿ë: ³»¿ë
    3) ¼¼ºÎ³»¿ë: ³»¿ë
- ´õ ³·Àº Ç×¸ñÀº ¹Ýµå½Ã ¾Õ¿¡ °ø¹é 6Ä­À» µÓ´Ï´Ù.
      °¡) ¼¼ºÎ³»¿ë
      ³ª) ¼¼ºÎ³»¿ë
      ´Ù) ¼¼ºÎ³»¿ë
- º¸Á¶ ¼³¸í ÇÏÀÌÇÂÀº ¹Ýµå½Ã ¾Õ¿¡ °ø¹é 4Ä­À» µÓ´Ï´Ù.
    - º¸Á¶ ¼³¸í
- 1. 2. 3. / °¡. ³ª. ´Ù. / 1) 2) 3) / °¡) ³ª) ´Ù) / - ÀÇ °èÃþÀ» ¼­·Î ¼¯Áö ¾Ê½À´Ï´Ù.
- '°³¿ä', '»ó¼¼ ³»¿ª', 'Á¶Ä¡ °á°ú', 'ÇâÈÄ °èÈ¹', '±âÅ¸»çÇ×'Àº ¹øÈ£ ¾ø´Â Á¦¸ñÀ¸·Î ¾²Áö ¸»°í ¹Ýµå½Ã °¡., ³ª., ´Ù., ¶ó. Ç×¸ñ ¾È¿¡ ³Ö½À´Ï´Ù.
- ¹øÈ£ ¾ø´Â Á¦¸ñÇü ¹®´ÜÀ» ¸¸µéÁö ¾Ê½À´Ï´Ù.

[1.°ü·Ã ÀÛ¼º ±ÔÄ¢: ¸Å¿ì Áß¿ä]
- '1. °ü·Ã:'Àº ¹Ýµå½Ã ÀÛ¼ºÇÕ´Ï´Ù.
- ¹®¼­ ³»¿ëÀ» ºÐ¼®ÇÏ¿© °ø½Ä ÃâÃ³¿¡¼­ ½ÇÁ¦ Á¸Àç°¡ È®ÀÎµÇ´Â ±Ù°Å¸¸ ÀÛ¼ºÇÕ´Ï´Ù.
- ¹ý·ü, ½ÃÇà·É, ½ÃÇà±ÔÄ¢Àº ¹Ýµå½Ã ±¹°¡¹ý·ÉÁ¤º¸¼¾ÅÍ(law.go.kr)ÀÇ ÇöÇà ±¹°¡¹ý·É¿¡¼­ È®ÀÎµÈ °Í¸¸ »ç¿ëÇÕ´Ï´Ù.
- Á¶·Ê, ±³À°±ÔÄ¢, ±³À°Ã» ÁöÄ§, ÀÚÄ¡¹ý±Ô´Â ¹Ýµå½Ã ÀÚÄ¡¹ý±ÔÁ¤º¸½Ã½ºÅÛ, ±¹°¡¹ý·ÉÁ¤º¸¼¾ÅÍ ÀÚÄ¡¹ý±Ô, ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» °ø½Ä ´©¸®Áý µî °ø½Ä ÃâÃ³¿¡¼­ È®ÀÎµÈ ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã ¶Ç´Â ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ±Ù°Å¸¸ »ç¿ëÇÕ´Ï´Ù.
- ¼­¿ïÆ¯º°½Ã, °æ±âµµ, ºÎ»ê±¤¿ª½Ã µî Å¸ ½Ãµµ ¹× Å¸ ½Ãµµ±³À°Ã»ÀÇ Á¶·Ê¡¤±ÔÄ¢¡¤ÁöÄ§Àº Àý´ë °ü·Ã ±Ù°Å·Î ÀÛ¼ºÇÏÁö ¾Ê½À´Ï´Ù.
- ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ±Ù°Å¸¦ °ø½Ä ÃâÃ³¿¡¼­ È®Á¤ÇÒ ¼ö ¾øÀ¸¸é Å¸ ½Ãµµ ±Ù°Å·Î ´ëÃ¼ÇÏÁö ¸»°í ÇØ´ç ±Ù°Å ÁÙÀ» ¾²Áö ¾Ê½À´Ï´Ù.
- °¡´ÉÇÑ °æ¿ì ¹ý·É¸í, ½ÃÇà·É¸í, ½ÃÇà±ÔÄ¢¸í, Á¶¹®¹øÈ£, Á¶¹® Á¦¸ñ±îÁö Ç¥½ÃÇÕ´Ï´Ù.
- ¹ý·É¸í ÀÚÃ¼ÀÇ Á¸Àç°¡ È®ÀÎµÇÁö ¾ÊÀ¸¸é Àý´ë ¾²Áö ¾Ê½À´Ï´Ù.
- Á¶¹®¹øÈ£³ª Á¶¹® Á¦¸ñÀÌ È®ÀÎµÇÁö ¾ÊÀ¸¸é Á¶¹®¹øÈ£¸¦ Áö¾î³»Áö ¸»°í, È®ÀÎµÈ ¹ý·É¸í¸¸ ¾²°Å³ª ÇØ´ç ±Ù°Å ÁÙÀ» »ý·«ÇÕ´Ï´Ù.
- ¹ý·ÉÀº ¾Æ·¡ Çü½ÄÃ³·³ ÀÛ¼ºÇÕ´Ï´Ù.
  °¡.¡¸¹ý·É¸í¡¹ Á¦00Á¶(Á¶¹® Á¦¸ñ)
  ³ª.¡¸¹ý·É¸í ½ÃÇà·É¡¹ Á¦00Á¶(Á¶¹® Á¦¸ñ)
  ´Ù.¡¸¹ý·É¸í ½ÃÇà±ÔÄ¢¡¹ Á¦00Á¶(Á¶¹® Á¦¸ñ)
- ¹®¼­¹øÈ£ ±Ù°Å°¡ ÀÖÀ¸¸é ¹ý·Éº¸´Ù ¾Õ¿¡ ¾µ ¼ö ÀÖ½À´Ï´Ù.
- »ç¿ëÀÚ°¡ ¿ø¹®¿¡ Á¦°øÇÏÁö ¾ÊÀº ÇÐ±³ ³»ºÎ °èÈ¹¸í, ¿¹»ê¿î¿µ°èÈ¹¸í, °ø¹®¹øÈ£, ÀÚÃ¼ °èÈ¹¸íÀº ÀÓÀÇ·Î ¸¸µéÁö ¾Ê½À´Ï´Ù.
- ÇÐ±³È¸°è, ¹°Ç°±¸ÀÔ, ¿ë¿ª°è¾à, °ø»ç, °­»çºñ, ÃâÀåºñ, ÇùÀÇÈ¸ºñ, ±Þ½Ä, ¾ÈÀü, °³ÀÎÁ¤º¸, ¼Ò¹æ, ¹Î¹æÀ§, ±³À°È°µ¿, ¼ÒÇÁÆ®¿þ¾î, Á¤º¸º¸¾È µî ¹®¼­ ³»¿ë¿¡ ¸Â´Â ±Ù°Å¸¦ ¿ì¼± ¼±ÅÃÇÕ´Ï´Ù.
- °ü·Ã ¹ý·ÉÀ» È®Á¤ÇÒ ¼ö ¾øÀ¸¸é °¡Àå °¡´É¼ºÀÌ ³ôÀº ¹ý·É ÈÄº¸¸¦ ¸¸µéÁö ¾Ê½À´Ï´Ù.
- '[È®ÀÎ ÇÊ¿ä]', '[Á¶¹® È®ÀÎ ÇÊ¿ä]' ¹®±¸´Â ÃÖÈÄÀÇ ¼ö´ÜÀ¸·Î¸¸ »ç¿ëÇÏ°í, ÇÑ ¹®¼­ ¾È¿¡¼­ ³²¹ßÇÏÁö ¾Ê½À´Ï´Ù.
- °ø½Ä ÃâÃ³¿¡¼­ È®ÀÎµÇÁö ¾ÊÀº ±Ù°Åº¸´Ù ±Ù°Å ¼ö°¡ Àû´õ¶óµµ Á¤È®ÇÑ ±Ù°Å¸¸ ¾²´Â °ÍÀ» ¿ì¼±ÇÕ´Ï´Ù.
- ´ÙÀ½°ú °°Àº Á¸Àç ºÒ¸í ¶Ç´Â ÀÓÀÇ ¸íÄªÀº Àý´ë ¾²Áö ¾Ê½À´Ï´Ù: ¡¸¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÇöÀåÁß½É ¹°Ç°°ü¸®¹ý ½ÃÇà±ÔÄ¢¡¹, '2026ÇÐ³âµµ ÇÐ±³È¸°è ¿¹»ê¿î¿µ°èÈ¹(¾È)'Ã³·³ »ç¿ëÀÚ°¡ Á¦°øÇÏÁö ¾ÊÀº ÇÐ±³ ÀÚÃ¼ ¹®¼­.

[°ü·Ã ±Ù°Å °ËÁõ ÀýÂ÷: ¹Ýµå½Ã ¼öÇà]
- ´äº¯À» ÀÛ¼ºÇÏ±â Àü¿¡ °ü·Ã ±Ù°Å¸¦ ÃÖ¼Ò 2È¸ ÀÌ»ó °Ë»ö¡¤´ëÁ¶ÇÕ´Ï´Ù.
- 1Â÷: ±¹°¡¹ý·ÉÁ¤º¸¼¾ÅÍ(law.go.kr)¿¡¼­ ±¹°¡¹ý·É¸í°ú Á¶¹®À» È®ÀÎÇÕ´Ï´Ù.
- 2Â÷: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ¶Ç´Â ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã ÀÚÄ¡¹ý±Ô °ø½Ä ÃâÃ³¿¡¼­ Á¶·Ê¡¤±ÔÄ¢¡¤ÁöÄ§ Á¸Àç ¿©ºÎ¸¦ È®ÀÎÇÕ´Ï´Ù.
- °Ë»ö °á°ú¿¡¼­ ¹ý·É¸í, Á¶¹®¹øÈ£, Á¶¹® Á¦¸ñÀÌ ¼­·Î ¸ÂÁö ¾ÊÀ¸¸é ±× ±Ù°Å´Â »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
- °Ë»ö¿¡ ½Ã°£ÀÌ °É¸®´õ¶óµµ Á¤È®¼ºÀ» ¿ì¼±ÇÕ´Ï´Ù.
- ±Ù°Å È®ÀÎ °úÁ¤Àº ÃÖÁ¾ ´äº¯¿¡ ¼³¸íÇÏÁö ¸»°í, ÃÖÁ¾ ¹®¼­¿¡´Â È®ÀÎµÈ ±Ù°Å¸¸ ¹Ý¿µÇÕ´Ï´Ù.
- ¹°Ç° ±¸ÀÔ ¹®¼­¶ó¸é ¸ÕÀú 'Áö¹æÀÚÄ¡´ÜÃ¼¸¦ ´ç»çÀÚ·Î ÇÏ´Â °è¾à¿¡ °üÇÑ ¹ý·ü', 'Áö¹æÀÚÄ¡´ÜÃ¼¸¦ ´ç»çÀÚ·Î ÇÏ´Â °è¾à¿¡ °üÇÑ ¹ý·ü ½ÃÇà·É', '°øÀ¯Àç»ê ¹× ¹°Ç° °ü¸®¹ý' µî ±¹°¡¹ý·ÉÀ» °ø½Ä ÃâÃ³¿¡¼­ °ËÅäÇÏµÇ, Á¶¹®±îÁö È®ÀÎµÈ °æ¿ì¿¡¸¸ ¹Ý¿µÇÕ´Ï´Ù.
- ÇÐ±³È¸°è, ¿¹»ê¿î¿µ°èÈ¹, ÀÚÃ¼ °èÈ¹, ³»ºÎ ¹æÄ§Àº »ç¿ëÀÚ°¡ ¿ø¹®¿¡ Á¦°øÇÑ °æ¿ì¿¡¸¸ °ü·Ã ±Ù°Å·Î ÀÛ¼ºÇÕ´Ï´Ù.

[2. º»¹® ¹®Àå ±ÔÄ¢]
- 2¹ø Ç×¸ñÀº ¹Ýµå½Ã ¸Ç ¿ÞÂÊ Á¤·Ä·Î ÀÛ¼ºÇÕ´Ï´Ù.
- 2¹ø Ç×¸ñÀº ¹®¼­ ¼º°Ý¿¡ ¸Â°Ô ¾Æ·¡ Áß ÇÏ³ª·Î ÀÛ¼ºÇÕ´Ï´Ù.
2. ¡Û¡Û¡ÛÀ»(¸¦) ´ÙÀ½°ú °°ÀÌ ½Ç½ÃÇÏ°íÀÚ ÇÕ´Ï´Ù.
2. ¡Û¡Û¡ÛÀ»(¸¦) ´ÙÀ½°ú °°ÀÌ ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.
2. ¡Û¡Û¡Û °è¾àÀ» ´ÙÀ½°ú °°ÀÌ ¿äÃ»ÇÏ°íÀÚ ÇÕ´Ï´Ù.
2. ¡Û¡Û¡Û¿¡ ´ëÇÏ¿© ´ÙÀ½°ú °°ÀÌ º¸°íÇÕ´Ï´Ù.
2. ¡Û¡Û¡ÛÀ»(¸¦) ´ÙÀ½°ú °°ÀÌ Áö±ÞÇÏ°íÀÚ ÇÕ´Ï´Ù.
- 2¹ø ´ÙÀ½ ¼¼ºÎ ³»¿ëÀº ¹Ýµå½Ã °¡., ³ª., ´Ù. Ã¼°è·Î ÀÛ¼ºÇÕ´Ï´Ù.

[°ø¹® ¹®Ã¼ ±ÔÄ¢]
- ÇÐ±³¡¤±³À°Ã»¿¡¼­ ½ÇÁ¦ »ç¿ëÇÏ´Â °£°áÇÏ°í °ø½ÄÀûÀÎ ¹®Ã¼¸¦ »ç¿ëÇÕ´Ï´Ù.
- ±¸¾îÃ¼, °¨Åº¹®, ÀåÈ²ÇÑ ¼³¸í, È«º¸¼º ¹®±¸´Â »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
- ¿ø¹®ÀÇ »ç½Ç°ü°è, ÆÄÀÏ¸í, ³¯Â¥, ±Ý¾×, ±â°ü¸íÀº ÀÓÀÇ·Î ¹Ù²ÙÁö ¾Ê½À´Ï´Ù.
- È®½ÇÇÏÁö ¾ÊÀº ³¯Â¥¡¤±Ý¾×¡¤±â°ü¸í¡¤¹®¼­¹øÈ£´Â [È®ÀÎ ÇÊ¿ä]·Î Ç¥½ÃÇÕ´Ï´Ù.
- ±Ý¾×Àº °¡´ÉÇÑ °æ¿ì '±Ý¾×: ±Ý0,000¿ø(±Ý¡Û¡Û¿ø)' Çü½ÄÀ¸·Î Á¤¸®ÇÕ´Ï´Ù.
- ³¯Â¥´Â °¡´ÉÇÑ °æ¿ì '2026. 5. 6.(¼ö)' Çü½ÄÀ¸·Î Á¤¸®ÇÕ´Ï´Ù.
- '³¡.'Àº ¹®¼­ ¸¶Áö¸·¿¡ ÇÑ ¹ø¸¸ ÀÛ¼ºÇÕ´Ï´Ù.

[ºÙÀÓ ±ÔÄ¢: ¸Å¿ì Áß¿ä]
- ºÙÀÓÀº °ø¹®¼­ ±Ô°Ý¿¡ ¸Â°Ô ¹®¼­ ¸¶Áö¸·¿¡ ÀÛ¼ºÇÕ´Ï´Ù.
- º»¹®°ú ºÙÀÓ »çÀÌ¿¡´Â ºó ÁÙ 1ÁÙ¸¸ µÓ´Ï´Ù.
- º»¹® ´Ù¸¥ À§Ä¡¿¡´Â ºÒÇÊ¿äÇÑ ºó ÁÙÀ» ³ÖÁö ¾Ê½À´Ï´Ù.
- ºÙÀÓÀÌ ¾øÀ¸¸é ºÙÀÓ ÁÙÀ» ¸¸µéÁö ¾Ê°í ¹®¼­ ¸¶Áö¸· ÁÙ¿¡ '³¡.'¸¸ ÀÛ¼ºÇÕ´Ï´Ù.
- ºÙÀÓÀÌ 1°³ÀÌ¸é ¼ýÀÚ 1.À» Àý´ë ºÙÀÌÁö ¾Ê½À´Ï´Ù.
ºÙÀÓ  ¡Û¡Û¡Û 1ºÎ.  ³¡.
- ºÙÀÓÀÌ 2°³ ÀÌ»óÀÌ¸é ±×¶§¸¸ 1., 2., 3. ¹øÈ£¸¦ ºÙÀÔ´Ï´Ù.
ºÙÀÓ  1. ¡Û¡Û¡Û 1ºÎ.
      2. ¡Û¡Û¡Û 1ºÎ.  ³¡.
- ºÙÀÓ µÎ ¹øÂ° ÁÙºÎÅÍ´Â ¾Õ¿¡ °ø¹é 6Ä­À» µÎ°í 2., 3.ÀÌ ½ÃÀÛµÇ°Ô ÀÛ¼ºÇÕ´Ï´Ù.
- '.  ³¡.' »çÀÌ °ø¹éÀº ¹Ýµå½Ã 2Ä­ÀÔ´Ï´Ù.
- '³¡.'Àº ºÙÀÓ ¸¶Áö¸· ÁÙ ³¡¿¡¸¸ ºÙÀÔ´Ï´Ù.
)

    if (mode = "EDIT")
    {
        prompt =
(
%commonRule%

[ÀÛ¾÷: ¹®¼­¼öÁ¤]
¾Æ·¡ ¿ø¹®À» ±³À°ÇàÁ¤ °ø¹®¼­ Àü¹®°¡ °üÁ¡¿¡¼­ ¹øÈ£ Ã¼°è, µé¿©¾²±â, ¹®Ã¼, °ü·Ã ±Ù°Å, ºÙÀÓ Çü½ÄÀÌ ¿ÏÀüÇÏ°Ô ¸Âµµ·Ï ¼öÁ¤ÇØ ÁÖ¼¼¿ä.

[¹®¼­¼öÁ¤ °­Á¦ Áö½Ã]
- ¿ø¹®ÀÌ ¹øÈ£ ¾ø´Â º¸°í¼­Ã³·³ µÇ¾î ÀÖ¾îµµ ¹Ýµå½Ã °ø¹®¼­ ¹øÈ£ Ã¼°è·Î Àç±¸¼ºÇÕ´Ï´Ù.
- '°ü·Ã:'Àº ¹Ýµå½Ã '1. °ü·Ã:'·Î °íÄ¨´Ï´Ù.
- '1. °ü·Ã:'¿¡´Â °ø½Ä ÃâÃ³¿¡¼­ ½ÇÁ¦ Á¸Àç¿Í Á¶¹®ÀÌ È®ÀÎµÈ °ü·Ã ±Ù°Å¸¸ ÀÛ¼ºÇÕ´Ï´Ù.
- °ü·Ã ¹ý·ÉÀÌ È®½ÇÇÏÁö ¾ÊÀ¸¸é ¹ý·É ÈÄº¸¸¦ ¸¸µéÁö ¸»°í ÇØ´ç ÁÙÀ» »ý·«ÇÕ´Ï´Ù.
- ¾ø´Â Á¶·Ê¡¤±³À°±ÔÄ¢¡¤ÇÐ±³ ÀÚÃ¼ °èÈ¹¸í¡¤°ø¹®¹øÈ£¸¦ ÀÓÀÇ·Î ¸¸µéÁö ¾Ê½À´Ï´Ù.
- [È®ÀÎ ÇÊ¿ä], [Á¶¹® È®ÀÎ ÇÊ¿ä] ¹®±¸´Â ¿ø¹® Á¤º¸°¡ ¹Ýµå½Ã ÇÊ¿äÇÑ °æ¿ì¿¡¸¸ ÃÖ¼ÒÇÑÀ¸·Î »ç¿ëÇÕ´Ï´Ù.
- ÇÙ½É ¹®ÀåÀº ¹Ýµå½Ã '2. ¡Û¡Û¡Û¿¡ ´ëÇÏ¿© ´ÙÀ½°ú °°ÀÌ º¸°íÇÕ´Ï´Ù.' ¶Ç´Â ¹®¼­ ¼º°Ý¿¡ ¸Â´Â '2. ¡Û¡Û¡ÛÀ»(¸¦) ´ÙÀ½°ú °°ÀÌ ¡Û¡ÛÇÏ°íÀÚ ÇÕ´Ï´Ù.'·Î °íÄ¨´Ï´Ù.
- '°³¿ä', '»ó¼¼ ³»¿ª', 'Á¶Ä¡ °á°ú', 'ÇâÈÄ °èÈ¹'Àº °¢°¢ 2¹ø ¾Æ·¡ °¡., ³ª., ´Ù., ¶ó. Ç×¸ñ ¾È¿¡ ³Ö½À´Ï´Ù.
- '¿À·ù ¹ß»ý ÁöÁ¡', '¹ß»ý ¿øÀÎ', '¼öÁ¤ ³»¿ë'Ã³·³ »ó¼¼ Ç×¸ñÀº 1), 2), 3)À¸·Î ³Ö½À´Ï´Ù.
- 1. 2. 3.Àº ¹Ýµå½Ã ¸Ç ¿ÞÂÊ¿¡¼­ ½ÃÀÛÇÕ´Ï´Ù.
- °¡. ³ª. ´Ù.´Â ¹Ýµå½Ã ¾Õ¿¡ °ø¹é 2Ä­À» µÓ´Ï´Ù.
- 1) 2) 3)Àº ¹Ýµå½Ã ¾Õ¿¡ °ø¹é 4Ä­À» µÓ´Ï´Ù.
- - Ç¥½Ã´Â ¹Ýµå½Ã ¾Õ¿¡ °ø¹é 4Ä­À» µÓ´Ï´Ù.
- ¸ðµç ¹øÈ£´Â ÀÚµ¿¸ñ·ÏÀÌ ¾Æ´Ï¶ó Á÷Á¢ ÀÔ·ÂÇÑ ÀÏ¹Ý ¹®ÀÚ·Î ÀÛ¼ºÇÕ´Ï´Ù.
- 1. 2. 3. ¹× 1) 2) 3) ¼ýÀÚµµ ¹Ýµå½Ã º¹»ç °¡´ÉÇÑ ÀÏ¹Ý ÅØ½ºÆ® ¹®ÀÚ·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ¹øÈ£ µÚ ÇÑ Ä­ À¯Áö ±ÔÄ¢¿¡ µû¶ó '1. °ü·Ã:', '2. º»¹®', '  °¡. °³¿ä', '    1) ¿À·ù ¹ß»ý ÁöÁ¡'Ã³·³ ¹øÈ£¿Í ¹®Àå »çÀÌ¿¡ ÇÑ Ä­À» µÓ´Ï´Ù.
- ºó ÁÙ 1ÁÙÀº ºÙÀÓ ¹Ù·Î ¾Õ¿¡¸¸ Àû¿ëÇÏ°í º»¹® Áß°£¿¡´Â ºó ÁÙÀ» ³ÖÁö ¾Ê½À´Ï´Ù.
- ÃÖÁ¾ ¼öÁ¤º»¸¸ text ÄÚµåºí·Ï ¾È¿¡ Á¦½ÃÇÏ°í, ¼öÁ¤ ÀÌÀ¯ ¼³¸íÀº ¾²Áö ¾Ê½À´Ï´Ù.

[Ãâ·Â ¿¹½Ã Çü½Ä]
%fence%text
1. °ü·Ã: ¡¸¡Û¡Û¹ý¡¹ Á¦00Á¶(¡Û¡Û), ¡¸¡Û¡Û¹ý ½ÃÇà·É¡¹ Á¦00Á¶(¡Û¡Û)
2. ¡Û¡Û¡Û¿¡ ´ëÇÏ¿© ´ÙÀ½°ú °°ÀÌ º¸°íÇÕ´Ï´Ù.
  °¡.°³¿ä: ¡Û¡Û¡Û
  ³ª.»ó¼¼ ³»¿ª
    1)¿À·ù ¹ß»ý ÁöÁ¡: ¡Û¡Û¡Û
    2)¹ß»ý ¿øÀÎ: ¡Û¡Û¡Û
    3)¼öÁ¤ ³»¿ë: ¡Û¡Û¡Û
  ´Ù.Á¶Ä¡ °á°ú: ¡Û¡Û¡Û
  ¶ó.ÇâÈÄ °èÈ¹: ¡Û¡Û¡Û

ºÙÀÓ  ¡Û¡Û¡Û 1ºÎ.  ³¡.
%fence%

[¿ø¹®]
%selectedBlock%
)
        return prompt
    }

    if (mode = "MEMO")
    {
        prompt =
(
%commonRule%

[ÀÛ¾÷: ±â¾È¹® ÀÛ¼º(°³Á¶½Ä)]
¾Æ·¡ ¿ø¹® ¶Ç´Â Å°¿öµå¸¦ ¹ÙÅÁÀ¸·Î ÇÐ±³ ÇàÁ¤½Ç¿¡¼­ »ç¿ëÇÏ´Â K-¿¡µàÆÄÀÎ ±â¾È¹® Çü½ÄÀÇ °³Á¶½Ä ¹®¼­¸¦ ÀÛ¼ºÇØ ÁÖ¼¼¿ä.

[±â¾È¹® °­Á¦ Çü½Ä]
%fence%text
Á¦¸ñ: ¡Û¡Û¡Û¡Û
1. °ü·Ã: ¡¸¡Û¡Û¹ý¡¹ Á¦00Á¶(¡Û¡Û), ¡¸¡Û¡Û¹ý ½ÃÇà·É¡¹ Á¦00Á¶(¡Û¡Û)
2. ¡Û¡Û¡ÛÀ»(¸¦) ´ÙÀ½°ú °°ÀÌ ½Ç½Ã/±¸ÀÔ/°è¾à/Áö±Þ/¿î¿µ/º¸°íÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. °Ç¸í: ¡Û¡Û¡Û
  ³ª. ¸ñÀû: ¡Û¡Û¡Û
  ´Ù. ÀÏ½Ã ¶Ç´Â ±â°£: ¡Û¡Û¡Û
  ¶ó. Àå¼Ò: ¡Û¡Û¡Û
  ¸¶. ´ë»ó: ¡Û¡Û¡Û
  ¹Ù. ³»¿ë: ¡Û¡Û¡Û
  »ç. ±Ý¾×: ±Ý¡Û¡Û¡Û¿ø(±Ý¡Û¡Û¡Û¿ø)
  ¾Æ. ÁýÇà¹æ¹ý ¶Ç´Â °è¾à¹æ¹ý: ¡Û¡Û¡Û
  ÀÚ. ±âÅ¸»çÇ×: ¡Û¡Û¡Û

ºÙÀÓ  ¡Û¡Û¡Û 1ºÎ.  ³¡.
%fence%

[±â¾È¹® ¼¼ºÎ Áö½Ã]
- À§ Çü½ÄÀÇ ¹øÈ£¿Í µé¿©¾²±â¸¦ ¹Ýµå½Ã ÁöÅµ´Ï´Ù.
- ¹°Ç° ±¸ÀÔÀº '±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù', ¿ë¿ªÀº '°è¾àÀ» ¿äÃ»ÇÏ°íÀÚ ÇÕ´Ï´Ù', Çà»ç¡¤ÈÆ·ÃÀº '½Ç½ÃÇÏ°íÀÚ ÇÕ´Ï´Ù', °á°ú ³»¿ëÀº 'º¸°íÇÕ´Ï´Ù'·Î ÀÚ¿¬½º·´°Ô ¼±ÅÃÇÕ´Ï´Ù.
- 1. °ü·Ã¿¡´Â °ø½Ä ÃâÃ³¿¡¼­ ½ÇÁ¦ Á¸Àç°¡ È®ÀÎµÈ ¹ý·É¡¤ÀÚÄ¡¹ý±Ô¡¤»ç¿ëÀÚ°¡ Á¦°øÇÑ ¹®¼­¹øÈ£¸¸ ÀÛ¼ºÇÕ´Ï´Ù.
- ½Å¹ßÀå, Ã¥»ó, ÀÇÀÚ, »ç¹«¿ëÇ° µî ÀÏ¹Ý ¹°Ç° ±¸ÀÔ ±â¾È¿¡¼­ ¾ø´Â ¼¼Á¾±³À°Ã» ±ÔÄ¢ÀÌ³ª ÇÐ±³ ÀÚÃ¼ °èÈ¹¸íÀ» ¸¸µéÁö ¾Ê½À´Ï´Ù.
- ¹ý·É ÈÄº¸, Á¶·Ê ÈÄº¸, ÀÚÃ¼ °èÈ¹ ÈÄº¸¸¦ »ó»óÇØ¼­ ¾²Áö ¾Ê½À´Ï´Ù.
- [È®ÀÎ ÇÊ¿ä], [Á¶¹® È®ÀÎ ÇÊ¿ä]´Â °¡´ÉÇÑ ÇÑ ¾²Áö ¸»°í, È®ÀÎµÇÁö ¾ÊÀº ±Ù°Å´Â »èÁ¦ÇÕ´Ï´Ù.
- ¸ñÀûÀº »óÅõÀûÀÎ ¹®±¸°¡ ¾Æ´Ï¶ó ÇØ´ç ¾÷¹«ÀÇ ½ÇÁ¦ ÇÊ¿ä¼ºÀÌ µå·¯³ª°Ô ÀÛ¼ºÇÕ´Ï´Ù.
- ¸ñÀûÀº ¸Å¹ø °°Àº ¹®ÀåÀ¸·Î ¾²Áö ¸»°í ¿ø¹® Å°¿öµå¿¡ µû¶ó ¾÷¹« À¯Çü, ´ë»ó, ÇÊ¿ä¼º, ±â´ë º¯È­¸¦ ¹Ý¿µÇØ ´Ù¸£°Ô ÀÛ¼ºÇÕ´Ï´Ù.
- '¿øÈ°ÇÑ ¾÷¹« ÃßÁø', '±³À°È°µ¿ Áö¿ø', 'È¿À²ÀûÀÎ ¿î¿µ'Ã³·³ ¾îµð¿¡³ª ºÙ´Â Ç¥Çö¸¸ ´Üµ¶À¸·Î ¾²Áö ¾Ê½À´Ï´Ù.
- ¸ñÀû ¹®ÀåÀº °¡±ÞÀû '¹«¾ùÀ»/´©±¸¿¡°Ô/¿Ö ÇÊ¿äÇÑÁö/¾î¶² »óÅÂ·Î °³¼±ÇÏ·Á´ÂÁö'°¡ µå·¯³ª´Â ÇÑ ¹®ÀåÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ¸ñÀû ÀÛ¼º Àü ¿ø¹®¿¡¼­ ÇàÀ§¾î¸¦ ¸ÕÀú ÆÇº°ÇÕ´Ï´Ù. '±¸ÀÔ/±¸¸Å', '¼ö¼±/¼ö¸®/º¸¼ö', 'ÁöÃâ/Áö±Þ', 'Á¤»ê/º¸°í', '°è¾à/¿ë¿ª', '½Ç½Ã/¿î¿µ' Áß ¹«¾ùÀÎÁö ±¸ºÐÇÑ µÚ ¸ñÀûÀ» ÀÛ¼ºÇÕ´Ï´Ù.
- °°Àº ¹°Ç°¸íÀÌ¶óµµ ÇàÀ§¾î°¡ ´Ù¸£¸é ¸ñÀûÀ» ´Ù¸£°Ô ¾¹´Ï´Ù. ¿¹¸¦ µé¾î '½Ç³»È­ ±¸¸Å'¿Í '½Ç³»È­ ¼ö¼± ÁöÃâ'Àº °°Àº ¸ñÀû ¹®ÀåÀ¸·Î ¾²Áö ¾Ê½À´Ï´Ù.
- ¹°Ç° ±¸ÀÔ ¸ñÀûÀº ³ëÈÄ¡¤ºÎÁ·¡¤ÆÄ¼Õ¡¤À§»ý¡¤¾ÈÀü¡¤¼ö¾÷ ÁØºñ¡¤ÇàÁ¤ Ã³¸® µî ½ÇÁ¦ ±¸ÀÔ »çÀ¯¸¦ Áß½ÉÀ¸·Î ¾¹´Ï´Ù.
- ¹°Ç°¸íÀÌ ¿ø¹®¿¡ ÀÖÀ¸¸é ¹°Ç°¸íÀ» ±×´ë·Î ¹Ýº¹ÇÏ´Â µ¥¼­ ¸ØÃßÁö ¸»°í, ±× ¹°Ç°ÀÌ ÇÐ±³¿¡¼­ ¾²ÀÌ´Â ±¸Ã¼Àû Àå¸é°ú ´ë»ó±îÁö ¸ñÀû¿¡ ¹Ý¿µÇÕ´Ï´Ù.
- ¿¹: '½Ç³»È­ ±¸¸Å'´Â ÀÏ¹ÝÀûÀÎ '±³À°È°µ¿ Áö¿ø'ÀÌ ¾Æ´Ï¶ó ÇÐ»ýÀÇ ±³½Ç¡¤º¹µµ µî ½Ç³» ÀÌµ¿, À§»ýÀûÀÎ ÇÐ±³»ýÈ°, ºÐ½Ç¡¤ÈÑ¼Õ ¹°Ç° º¸Ãæ, ¾ÈÀüÇÑ ½Ç³» »ýÈ° ¿©°Ç Á¶¼ºÃ³·³ ½Ç³»È­ÀÇ ½ÇÁ¦ ¿ëµµ¿¡ ¸Â°Ô ¾¹´Ï´Ù.
- ¿¹: '½Ç³»È­ ¼ö¼± ÁöÃâ'Àº »õ ¹°Ç° ±¸ÀÔ ¸ñÀûÀÌ ¾Æ´Ï¶ó ÆÄ¼Õ¡¤³ëÈÄµÈ ½Ç³»È­¸¦ ¼ö¼±ÇÏ¿© °è¼Ó »ç¿ë °¡´ÉÇÏ°Ô ÇÏ°í, ÇÐ»ýÀÇ À§»ýÀûÀÌ°í ¾ÈÀüÇÑ ½Ç³» »ýÈ°À» À¯ÁöÇÏ¸ç, ÀÌ¿¡ µû¸¥ ¼ö¼±ºñ¸¦ ÀûÁ¤ÇÏ°Ô ÁýÇàÇÏ´Â ¸ñÀû¿¡ ¸Â°Ô ¾¹´Ï´Ù.
- ¿¹: '½Ç³»È­ ¼ö¸®ºñ Áö±Þ'Àº ¼ö¸® ¿Ï·á »ç½Ç°ú ºñ¿ë Áö±ÞÀÇ ÇÊ¿ä¼ºÀ» ¹Ý¿µÇÏ¿©, ¼ö¸®µÈ ½Ç³»È­ÀÇ »ç¿ë Áö¼Ó¼º È®º¸¿Í ÁöÃâ ÀýÂ÷ ÀÌÇà Áß½ÉÀ¸·Î ¾¹´Ï´Ù.
- ¿¹: '½Å¹ßÀå ±¸¸Å'´Â ¹°Ç° º¸°ü °ø°£ È®º¸, º¹µµ Á¤¸®, ÇÐ»ý ÀÌµ¿ ¾ÈÀü, ±³½Ç¡¤º¹µµ È¯°æ °³¼±Ã³·³ ½Å¹ßÀåÀÇ ½ÇÁ¦ ¿ªÇÒ¿¡ ¸Â°Ô ¾¹´Ï´Ù.
- ¿¹: 'Ã¥»ó¡¤ÀÇÀÚ ±¸¸Å'´Â ¼ö¾÷ Âü¿© È¯°æ, ³ëÈÄ ºñÇ° ±³Ã¼, ÇÐ»ý Ã¼Çü°ú ÇÐ½À È°µ¿ Áö¿øÃ³·³ Ã¥»ó¡¤ÀÇÀÚÀÇ ½ÇÁ¦ »ç¿ë ¸ñÀû¿¡ ¸Â°Ô ¾¹´Ï´Ù.
- ¿¹: 'Ã»¼Ò¿ëÇ° ±¸¸Å'´Â ±³½Ç¡¤Æ¯º°½Ç À§»ý°ü¸®, °¨¿°º´ ¿¹¹æ, ÄèÀûÇÑ ±³À°È¯°æ À¯ÁöÃ³·³ Ã»¼Ò¿ëÇ°ÀÇ ½ÇÁ¦ ÇÊ¿ä¼º¿¡ ¸Â°Ô ¾¹´Ï´Ù.
- ¿ø¹®¿¡ '½Ç³»È­', '½Å¹ßÀå', 'Ã¥»ó', 'ÀÇÀÚ', 'Ã»¼Ò¿ëÇ°', 'ÇÁ¸°ÅÍ', '¼Ò¸ðÇ°' µî ±¸Ã¼ ¹°Ç°¸íÀÌ ÀÖÀ¸¸é ¹Ýµå½Ã ±× ¹°Ç°¸í¿¡ ¸ÂÃá ¸ñÀûÀ» ÀÛ¼ºÇÏ°í, ÀÏ¹Ý ¹°Ç° ±¸¸Å ¸ñÀû ¹®ÀåÀ¸·Î ´ëÃ¼ÇÏÁö ¾Ê½À´Ï´Ù.
- ¿ø¹®¿¡ '¼ö¼±', '¼ö¸®', 'º¸¼ö'¿Í 'ÁöÃâ', 'Áö±Þ'ÀÌ ÇÔ²² ÀÖÀ¸¸é ¸ñÀûÀº '»õ·Î ¸¶·ÃÇÏ±â À§ÇÔ'ÀÌ ¾Æ´Ï¶ó '±âÁ¸ ¹°Ç°¡¤½Ã¼³ÀÇ ±â´É È¸º¹, ¾ÈÀüÇÑ »ç¿ë À¯Áö, ¿Ï·áµÈ ¼ö¼± ºñ¿ëÀÇ ÀûÁ¤ ÁöÃâ' Áß½ÉÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ¿ë¿ª¡¤°ø»ç ¸ñÀûÀº Á¡°Ë¡¤º¸¼ö¡¤¼³Ä¡¡¤È¯°æ°³¼±¡¤¾ÈÀüÈ®º¸¡¤Àü¹®¼º È®º¸ µî ÃßÁø ÇÊ¿ä¼ºÀ» Áß½ÉÀ¸·Î ¾¹´Ï´Ù.
- Çà»ç¡¤¿¬¼ö¡¤±³À° ¸ñÀûÀº Âü¿© ´ë»óÀÇ ¿ª·® °­È­, °øµ¿Ã¼ Çü¼º, ¾ÈÀüÀÇ½Ä Á¦°í, ±³À°°úÁ¤ ¿î¿µ Áö¿ø µî ¿ø¹®¿¡ ¸Â´Â º¯È­¸¦ Áß½ÉÀ¸·Î ¾¹´Ï´Ù.
- ÁöÃâ¡¤Á¤»ê¡¤º¸°í ¸ñÀûÀº ÀÌ¹Ì ÃßÁøÇÑ ¾÷¹«ÀÇ °á°ú È®ÀÎ, Áõºù Á¤¸®, ¿¹»ê ÁýÇàÀÇ ÀûÁ¤¼º È®º¸¸¦ Áß½ÉÀ¸·Î ¾¹´Ï´Ù.
- ¸ñÀû ¿¹½Ã¸¦ ±×´ë·Î ¹Ýº¹ÇÏÁö ¸»°í, ¿ø¹®¿¡ ÀÖ´Â ¸í»ç¿Í µ¿»ç¸¦ È°¿ëÇØ ÀÚ¿¬½º·´°Ô ¹Ù²Ù¾î ÀÛ¼ºÇÕ´Ï´Ù.
- ºÒÇÊ¿äÇÑ Ç×¸ñÀº »èÁ¦ °¡´ÉÇÏÁö¸¸, »èÁ¦ÇÏ´õ¶óµµ ¹øÈ£ Ã¼°è´Â À¯ÁöÇÕ´Ï´Ù.
- 'ÇâÈÄ °èÈ¹'ÀÌ ÇÊ¿äÇÏ¸é ¹Ýµå½Ã °¡., ³ª., ´Ù. Ç×¸ñ Áß ÇÏ³ª·Î ³Ö½À´Ï´Ù.
- ºÙÀÓÀÌ 1°³ÀÌ¸é 'ºÙÀÓ  ¡Û¡Û¡Û 1ºÎ.  ³¡.'Ã³·³ ¼ýÀÚ¸¦ ºÙÀÌÁö ¾Ê½À´Ï´Ù.
- ºÙÀÓÀÌ 2°³ ÀÌ»óÀÌ¸é ±×¶§¸¸ 'ºÙÀÓ  1.'°ú '      2.' Çü½ÄÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- 1. 2. 3. ¹× 1) 2) 3) ¼ýÀÚµµ ¹Ýµå½Ã º¹»ç °¡´ÉÇÑ ÀÏ¹Ý ÅØ½ºÆ® ¹®ÀÚ·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ¹øÈ£ µÚ ÇÑ Ä­ À¯Áö ±ÔÄ¢¿¡ µû¶ó '1. °ü·Ã:', '2. º»¹®', '  °¡. °Ç¸í'Ã³·³ ¹øÈ£¿Í ¹®Àå »çÀÌ¿¡ ÇÑ Ä­À» µÓ´Ï´Ù.
- ºó ÁÙ 1ÁÙÀº ºÙÀÓ ¹Ù·Î ¾Õ¿¡¸¸ Àû¿ëÇÏ°í º»¹® Áß°£¿¡´Â ºó ÁÙÀ» ³ÖÁö ¾Ê½À´Ï´Ù.
- ÃÖÁ¾ ±â¾È¹®¸¸ text ÄÚµåºí·Ï ¾È¿¡ Á¦½ÃÇÏ°í ¼³¸íÀº ¾²Áö ¾Ê½À´Ï´Ù.

[ÀÛ¼º Àç·á]
%selectedBlock%
)
        return prompt
    }

    if (mode = "PLAN")
    {
        prompt =
(
%commonRule%

[ÀÛ¾÷: °èÈ¹¼­ ÀÛ¼º(°³Á¶½Ä)]
¾Æ·¡ ¿ø¹® ¶Ç´Â Å°¿öµå¸¦ ¹ÙÅÁÀ¸·Î ÇÐ±³¡¤±³À°Ã»¿¡¼­ »ç¿ëÇÏ´Â °èÈ¹¼­ Çü½ÄÀÇ °³Á¶½Ä ¹®¼­¸¦ ÀÛ¼ºÇØ ÁÖ¼¼¿ä.

[°èÈ¹¼­ °­Á¦ Çü½Ä]
%fence%text
¡Û¡Û¡Û¡Û °èÈ¹
1. ÃßÁø ±Ù°Å
  °¡. ¡¸¡Û¡Û¹ý¡¹ Á¦00Á¶(¡Û¡Û)
  ³ª. ¡¸¡Û¡Û¹ý ½ÃÇà·É¡¹ Á¦00Á¶(¡Û¡Û)
2. ÃßÁø ¸ñÀû
  °¡. ¡Û¡Û¡Û
  ³ª. ¡Û¡Û¡Û
3. ÃßÁø °³¿ä
  °¡. °Ç¸í: ¡Û¡Û¡Û
  ³ª. ÃßÁø±â°£: 2026. 00. 00.(¿äÀÏ)~2026. 00. 00.(¿äÀÏ)
  ´Ù. ÃßÁøÀå¼Ò: ¡Û¡Û¡Û
  ¶ó. ÃßÁø´ë»ó: ¡Û¡Û¡Û
  ¸¶. ÃßÁø³»¿ë: ¡Û¡Û¡Û
4. ¼¼ºÎ ÃßÁø ÀÏÁ¤
  °¡. »çÀü ÁØºñ: 2026. 00. 00.(¿äÀÏ)~2026. 00. 00.(¿äÀÏ)
    1) ¼¼ºÎ °èÈ¹ ¼ö¸³
    2) ¿¹»ê È®ÀÎ ¹× °è¾à ÀýÂ÷ ÁØºñ
  ³ª. »ç¾÷ ÃßÁø: 2026. 00. 00.(¿äÀÏ)~2026. 00. 00.(¿äÀÏ)
    1) ¹°Ç° ±¸ÀÔ ¶Ç´Â ¿ë¿ª¡¤°ø»ç ÃßÁø
    2) ÇöÀå È®ÀÎ ¹× Áß°£ Á¡°Ë
  ´Ù. °á°ú Á¤¸®: 2026. 00. 00.(¿äÀÏ)~2026. 00. 00.(¿äÀÏ)
    1) ³³Ç°¡¤°Ë¼ö ¶Ç´Â ¿Ï·á È®ÀÎ
    2) °á°ú º¸°í ¹× ÁõºùÀÚ·á Á¤¸®
5. ¼¼ºÎ ÃßÁø ³»¿ë
  °¡. ¡Û¡Û¡Û
    1) ¡Û¡Û¡Û
    2) ¡Û¡Û¡Û
  ³ª. ¡Û¡Û¡Û
    1) ¡Û¡Û¡Û
    2) ¡Û¡Û¡Û
6. ¼Ò¿ä ¿¹»ê
  °¡. ÃÑ¾×: ±Ý¡Û¡Û¡Û¿ø(±Ý¡Û¡Û¡Û¿ø)
  ³ª. »êÃâ³»¿ª
    1) ¹°Ç°ºñ: ¡Û¡Û¡Û¿ø¡¿¡Û°³=±Ý¡Û¡Û¡Û¿ø
    2) ¿ë¿ªºñ: ¡Û¡Û¡Û¿ø¡¿¡ÛÈ¸=±Ý¡Û¡Û¡Û¿ø
    3) ¼³Ä¡ºñ: ¡Û¡Û¡Û¿ø¡¿¡Û½Ä=±Ý¡Û¡Û¡Û¿ø
    4) ±âÅ¸°æºñ: ¡Û¡Û¡Û¿ø¡¿¡ÛÈ¸=±Ý¡Û¡Û¡Û¿ø
  ´Ù. ÁýÇà¹æ¹ý: ÇÐ±³È¸°è ¿¹»ê ¹üÀ§ ³» Ä«µå°áÁ¦, °èÁÂÀÌÃ¼, S2B, ³ª¶óÀåÅÍ µî °ü·Ã ÀýÂ÷¿¡ µû¶ó ÁýÇà
7. ÇàÁ¤»çÇ×
  °¡. °è¾à ¹× ¿¹»ê ÁýÇà: °ü·Ã ¹ý·É°ú ÇÐ±³È¸°è ÀýÂ÷¿¡ µû¶ó ÃßÁø
  ³ª. »çÀü ¾È³»: ´ë»óÀÚ, ÀÏÁ¤, Àå¼Ò, À¯ÀÇ»çÇ×À» »çÀü¿¡ ¾È³»
  ´Ù. ¾ÈÀü°ü¸®: ÃßÁø °úÁ¤¿¡¼­ ÇÐ»ý ¾ÈÀü ¹× ½Ã¼³ ¾ÈÀüÀ» È®ÀÎ
  ¶ó. °Ë¼ö ¹× Á¤»ê: ³³Ç°, ¼³Ä¡, ¿ë¿ª ¿Ï·á ÈÄ °Ë¼öÀÚ·á¿Í ÁöÃâ ÁõºùÀÚ·á¸¦ Á¤¸®
  ¸¶. °á°ú º¸°í: ÃßÁø ¿Ï·á ÈÄ °á°úº¸°í¼­¿Í °ü·Ã ÁõºùÀÚ·á¸¦ º¸°ü
8. ±â´ë È¿°ú
  °¡. ¡Û¡Û¡Û
  ³ª. ¡Û¡Û¡Û
%fence%

[°èÈ¹¼­ ¼¼ºÎ Áö½Ã]
- À§ Çü½ÄÀÇ ¹øÈ£¿Í µé¿©¾²±â¸¦ ¹Ýµå½Ã ÁöÅµ´Ï´Ù.
- ÃßÁø ±Ù°Å¿¡´Â °ø½Ä ÃâÃ³¿¡¼­ ½ÇÁ¦ Á¸Àç¿Í Á¶¹®ÀÌ È®ÀÎµÈ ±Ù°Å¸¸ ÀÛ¼ºÇÕ´Ï´Ù.
- ¹ý·É Á¶¹®À» È®Á¤ÇÒ ¼ö ¾øÀ¸¸é Á¶¹®À» Áö¾î³»Áö ¸»°í, È®ÀÎµÈ ¹ý·É¸í¸¸ ¾²°Å³ª ÇØ´ç ±Ù°Å ÁÙÀ» »ý·«ÇÕ´Ï´Ù.
- ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» Á¶·Ê¡¤±ÔÄ¢¡¤ÁöÄ§Àº °ø½Ä ÃâÃ³¿¡¼­ Á¸Àç°¡ È®ÀÎµÉ ¶§¸¸ ÀÛ¼ºÇÕ´Ï´Ù.(°ø¸³ O, »ç¸³ X)
- ÇÐ±³ ÀÚÃ¼ °èÈ¹¸íÀÌ³ª ¿¹»ê¿î¿µ°èÈ¹¸íÀº »ç¿ëÀÚ°¡ Á¦°øÇÑ °æ¿ì¿¡¸¸ ÀÛ¼ºÇÕ´Ï´Ù.
- [È®ÀÎ ÇÊ¿ä], [Á¶¹® È®ÀÎ ÇÊ¿ä]´Â °¡´ÉÇÑ ÇÑ ¾²Áö ¸»°í, ¿ø¹® Á¤º¸°¡ ¹Ýµå½Ã ÇÊ¿äÇÑ ºóÄ­¿¡¸¸ ÃÖ¼ÒÇÑÀ¸·Î »ç¿ëÇÕ´Ï´Ù.
- ÇÐ±³ ÇöÀå¿¡¼­ ¹Ù·Î ¾µ ¼ö ÀÖ´Â ½Ç¹«Çü °èÈ¹¼­·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ½ÇÁ¦ ÃßÁø±â°£, »çÀü ÁØºñ±â°£, »ç¾÷ ÃßÁø±â°£, °á°ú Á¤¸®±â°£Àº ¸ðµÎ ±¸Ã¼ÀûÀÎ ³¯Â¥ Çü½ÄÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ¿ø¹®¿¡ ³¯Â¥°¡ ¾øÀ¸¸é ºñ¿ö µÎÁö ¸»°í '2026. 00. 00.(¿äÀÏ)' Çü½ÄÀ¸·Î Ç¥½ÃÇÕ´Ï´Ù.
- »êÃâ³»¿ªÀº '¹°Ç°ºñ, ¿ë¿ªºñ, ¼³Ä¡ºñ, ±âÅ¸°æºñ' µî ÇÐ±³¿¡¼­ ÀÚÁÖ ¾²´Â Ç×¸ñÀ¸·Î ³ª´©¾î ¼ö·®¡¿´Ü°¡¡¿È½¼ö=±Ý¾× Çü½ÄÀ¸·Î ±¸Ã¼ÀûÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- »êÃâ³»¿ªÀÌ ºÒ¸íÈ®ÇØµµ '¡Û¡Û¿ø¡¿¡Û°³=¡Û¡Û¿ø' ÇüÅÂÀÇ ±âº» Æ²À» ¹Ýµå½Ã ÀÛ¼ºÇÕ´Ï´Ù.
- ³¯Â¥, ±Ý¾×, ±â°ü¸í, ¼ö·®Ã³·³ ¿ø¹® Á¤º¸°¡ ¹Ýµå½Ã ÇÊ¿äÇÑ »ç½Ç°ü°è°¡ ºÎÁ·ÇÑ °æ¿ì¿¡¸¸ [È®ÀÎ ÇÊ¿ä]·Î ÃÖ¼Ò Ç¥½ÃÇÕ´Ï´Ù.
- ÃßÁø ¸ñÀûÀº ¸Å¹ø °°Àº ÀÏ¹Ý ¹®±¸·Î ¾²Áö ¸»°í ¿ø¹® Å°¿öµå¿¡ µû¶ó ´ë»ó, ¹®Á¦»óÈ², ÃßÁø ÇÊ¿ä¼º, ±â´ë º¯È­¸¦ ±¸Ã¼ÀûÀ¸·Î ³ª´©¾î ÀÛ¼ºÇÕ´Ï´Ù.
- '¿øÈ°ÇÑ ÃßÁø', 'È¿À²ÀûÀÎ ¿î¿µ', '±³À°È°µ¿ Áö¿ø'Ã³·³ ¹ü¿ë Ç¥Çö¸¸ ¹Ýº¹ÇÏÁö ¾Ê½À´Ï´Ù.
- ¹°Ç°¡¤½Ã¼³ °èÈ¹Àº ³ëÈÄ, ºÎÁ·, ¾ÈÀü, À§»ý, Á¢±Ù¼º, ¼ö¾÷¡¤¾÷¹« È¯°æ °³¼± µî ½ÇÁ¦ ÇÊ¿ä¼ºÀ» ¹Ý¿µÇÕ´Ï´Ù.
- ¹°Ç°¡¤½Ã¼³¸íÀÌ ¿ø¹®¿¡ ÀÖÀ¸¸é ±× ÀÌ¸§ÀÇ ÇÐ±³ ³» ½ÇÁ¦ »ç¿ë Àå¸éÀ» ¹Ý¿µÇÕ´Ï´Ù. ¿¹¸¦ µé¾î ½Ç³»È­´Â ÇÐ»ýÀÇ ½Ç³» ÀÌµ¿°ú À§»ý¡¤¾ÈÀü, ½Å¹ßÀåÀº º¸°ü °ø°£°ú º¹µµ Á¤¸®¡¤ÀÌµ¿ ¾ÈÀü, Ã¥»ó¡¤ÀÇÀÚ´Â ¼ö¾÷ Âü¿© È¯°æ°ú ³ëÈÄ ºñÇ° ±³Ã¼, Ã»¼Ò¿ëÇ°Àº À§»ý°ü¸®¿Í °¨¿°º´ ¿¹¹æ Áß½ÉÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ¿ø¹®¿¡¼­ '±¸¸Å/±¸ÀÔ'ÀÎÁö, '¼ö¼±/¼ö¸®/º¸¼ö'ÀÎÁö, 'ÁöÃâ/Áö±Þ/Á¤»ê'ÀÎÁö ¸ÕÀú ±¸ºÐÇÕ´Ï´Ù. °°Àº ½Ç³»È­¶óµµ ±¸¸Å °èÈ¹Àº È®º¸¡¤º¸Ãæ ¸ñÀû, ¼ö¼± ÁöÃâÀº ±â´É È¸º¹¡¤¾ÈÀüÇÑ »ç¿ë À¯Áö¡¤¼ö¼±ºñ ÁýÇà ¸ñÀûÀ» Áß½ÉÀ¸·Î ¾¹´Ï´Ù.
- ¿¹¸¦ µé¾î '½Ç³»È­ ¼ö¼± ÁöÃâ'Àº ½Ç³»È­¸¦ »õ·Î ¸¶·ÃÇÏ´Â °èÈ¹ÀÌ ¾Æ´Ï¶ó, ÆÄ¼Õ ¶Ç´Â ³ëÈÄµÈ ½Ç³»È­¸¦ ¼ö¼±ÇÏ¿© ÇÐ»ýÀÇ À§»ýÀûÀÌ°í ¾ÈÀüÇÑ ½Ç³» »ýÈ°À» À¯ÁöÇÏ°í ¿Ï·áµÈ ¼ö¼± ºñ¿ëÀ» ÀûÁ¤ÇÏ°Ô ÁýÇàÇÏ´Â ³»¿ëÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ±¸Ã¼ ¹°Ç°¸íÀÌ ÀÖ´Âµ¥µµ '±³À°È°µ¿ Áö¿ø', 'È¯°æ °³¼±', '¿øÈ°ÇÑ ¿î¿µ'¸¸À¸·Î ¸ñÀûÀ» ³¡³»Áö ¾Ê½À´Ï´Ù.
- Çà»ç¡¤±³À°¡¤¿¬¼ö °èÈ¹Àº ´ë»óÀÚÀÇ °æÇè, ¿ª·®, ¾ÈÀüÀÇ½Ä, °øµ¿Ã¼¼º, ±³À°°úÁ¤ ¿¬°è È¿°ú¸¦ ¹Ý¿µÇÕ´Ï´Ù.
- ¿ë¿ª¡¤Á¡°Ë¡¤°ü¸® °èÈ¹Àº Àü¹®¼º È®º¸, ¿¹¹æ Á¡°Ë, À§Çè¿äÀÎ ÇØ¼Ò, ¿î¿µ ¾ÈÁ¤¼º È®º¸¸¦ ¹Ý¿µÇÕ´Ï´Ù.
- ¾ÈÀü°ü¸®, ¿¹»êÁýÇà, »çÀü¾È³», °á°úº¸°í, °³ÀÎÁ¤º¸º¸È£ µî ÇÊ¿äÇÑ ÇàÁ¤»çÇ×À» ¹Ý¿µÇÕ´Ï´Ù.
- ÇàÁ¤»çÇ×Àº ¼­¼ú½Ä ¹®ÀåÀ¸·Î ¾²Áö ¸»°í ¹Ýµå½Ã '°¡. °è¾à ¹× ¿¹»ê ÁýÇà: ¡Û¡Û', '³ª. »çÀü ¾È³»: ¡Û¡Û'Ã³·³ Ç×¸ñ¸í°ú ³»¿ëÀ» Âª°Ô ºÙÀÎ °³Á¶½ÄÀ¸·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ÇàÁ¤»çÇ×ÀÇ ¸ðµç ÇÏÀ§ ³»¿ëµµ ÇÊ¿äÇÏ¸é '1) ¡Û¡Û', '2) ¡Û¡Û' Çü½ÄÀÇ °³Á¶½ÄÀ¸·Î¸¸ ÀÛ¼ºÇÏ°í ¹®´ÜÇü ¼­¼ú½ÄÀº ±ÝÁöÇÕ´Ï´Ù.
- 'ÇàÁ¤»çÇ×Àº ´ÙÀ½°ú °°´Ù'Ã³·³ ¼­¼úÇü ¹®ÀåÀ» ¾²Áö ¾Ê½À´Ï´Ù.
- ¹øÈ£ ¾ø´Â 'ÇâÈÄ °èÈ¹' Á¦¸ñÀ» ¸¸µéÁö ¸»°í ÇÊ¿äÇÑ ³»¿ëÀº 7. ÇàÁ¤»çÇ× ¶Ç´Â ÇØ´ç ¹øÈ£ ¾È¿¡ ³Ö½À´Ï´Ù.
- 1. 2. 3. ¹× 1) 2) 3) ¼ýÀÚµµ ¹Ýµå½Ã º¹»ç °¡´ÉÇÑ ÀÏ¹Ý ÅØ½ºÆ® ¹®ÀÚ·Î ÀÛ¼ºÇÕ´Ï´Ù.
- ¹øÈ£ µÚ ÇÑ Ä­ À¯Áö ±ÔÄ¢¿¡ µû¶ó '1. ÃßÁø ±Ù°Å', '  °¡. ±Ù°Å', '    1) ³»¿ë'Ã³·³ ¹øÈ£¿Í ¹®Àå »çÀÌ¿¡ ÇÑ Ä­À» µÓ´Ï´Ù.
- ºó ÁÙ 1ÁÙÀº ºÙÀÓ ¹Ù·Î ¾Õ¿¡¸¸ Àû¿ëÇÏ°í º»¹® Áß°£¿¡´Â ºó ÁÙÀ» ³ÖÁö ¾Ê½À´Ï´Ù.
- 1. ÃßÁø ±Ù°ÅºÎÅÍ 8. ±â´ë È¿°ú±îÁö ¸ðµç Ç×¸ñ »çÀÌ¿¡´Â ºó ÁÙÀ» ³ÖÁö ¾Ê½À´Ï´Ù.
- Æ¯È÷ 7. ÇàÁ¤»çÇ×Àº ´Ù¸¥ Ç×¸ñ°ú µ¿ÀÏÇÏ°Ô °³Á¶½ÄÀ¸·Î ÀÛ¼ºÇÏ°í, ¼­¼ú½Ä ¹®´ÜÀ» Àý´ë ¸¸µéÁö ¾Ê½À´Ï´Ù.
- ÃÖÁ¾ °èÈ¹¼­¸¸ text ÄÚµåºí·Ï ¾È¿¡ Á¦½ÃÇÏ°í ¼³¸íÀº ¾²Áö ¾Ê½À´Ï´Ù.

[ÀÛ¼º Àç·á]
%selectedBlock%
)
        return prompt
    }

    return selectedBlock
}


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
; =====================================

; =========================================================
; Win + 1 : K-¿¡µàÆÄÀÎ ¿øÀÎÇàÀ§ ±âº»°ª ÀÚµ¿¼³Á¤ - »ç¿ëÀÚ ÁöÁ¤ Tab ¼ø¼­ ¹æ½Ä
; ---------------------------------------------------------
; [2026-05-14 ¼öÁ¤]
; - Ctrl+F/ÁÖ¼ÒÃ¢/javascript/ÁÂÇ¥/ImageSearch »ç¿ë ¾È ÇÔ
; - »ç¿ëÀÚ°¡ ÁöÁ¤ÇÑ Å° ¼ø¼­¸¸ ½ÇÇà
; - ¼ø¼­: Space ¡æ ´ë±â ¡æ Tab 10 ¡æ Down 1 ¡æ Tab 1 ¡æ Down 4 ¡æ Tab 2 ¡æ Enter ¡æ 11 ¡æ Enter
; =========================================================
#1::
    ; K-¿¡µàÆÄÀÎ ¿øÀÎÇàÀ§ º¸Á¶ - Tab ¼ø¼­ ¹æ½Ä
    ; ¼ø¼­: Space ¡æ ´ë±â ¡æ Tab 10 ¡æ ¡é 1 ¡æ Tab 1 ¡æ ¡é 4 ¡æ Tab 2 ¡æ Enter ¡æ ´ë±â ¡æ 11 ¡æ Enter
    SendInput, {Space}
    Sleep, 1000
    SendInput, {Tab 10}
    Sleep, 120
    SendInput, {Down 1}
    Sleep, 120
    SendInput, {Tab 1}
    Sleep, 120
    SendInput, {Down 4}
    Sleep, 120
    SendInput, {Tab 2}
    Sleep, 120
    SendInput, {Enter}
    Sleep, 900
    SendInput, 11
    Sleep, 300
    SendInput, {Enter}
    Sleep, 300
    SendInput, {Tab 7}
    Sleep, 180
    SendInput, {Down}
    Sleep, 120
    SendInput, {WheelDown 1}
return

; =========================================================
; Win + 2 : K-¿¡µàÆÄÀÎ »ç¿ëÀÚ ÁöÁ¤ Tab ¼ø¼­ ½ÇÇà
; ---------------------------------------------------------
; ¼ø¼­: Tab 12 ¡æ Left 1 ¡æ Tab 7 ¡æ Space ¡æ Tab 1 ¡æ Space ¡æ Tab 16 ¡æ Down 1
; =========================================================
#2::
    Gosub, SSOK_DoWin2_KEdufine_TabSeq
return


; =========================================================
; =========================================================
; ¿øÀÎÇàÀ§À¯Çü¼±ÅÃ È®ÀÎ ÈÄ Win+1 µÞºÎºÐ ÀÚµ¿ ½ÇÇà
; ---------------------------------------------------------
; ÇöÀç ºñÈ°¼ºÈ­: SSOK_EnableCauseTypeAutoAfter := 1 ·Î ÄÑ±â Àü±îÁö ½ÇÇàµÇÁö ¾Ê½À´Ï´Ù.
; UIA/¸¶¿ì½º À§Ä¡ ÆÇµ¶Àº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
; º°µµ ¼±ÅÃÃ¢ Á¦¸ñÀÌ ÀâÈ÷´Â °æ¿ì¿¡¸¸, ¼±ÅÃ ÈÄ Ã¢ÀÌ ´ÝÈ÷¸é Space ¾øÀÌ Tab 10ºÎÅÍ ½ÇÇà
; =========================================================
#If (SSOK_EnableCauseTypeAutoAfter && SSOK_IsCauseTypeWindowActive())
~Enter::
~NumpadEnter::
~LButton Up::
    Gosub, SSOK_Win1_AutoAfterTypeConfirm_Start
return
#If
SSOK_Win1_AutoAfterTypeConfirm_Start:
    if (SSOK_Win1_AutoAfterTypeConfirmPending)
        return
    WinGet, SSOK_Win1_AutoCauseHwnd, ID, A
    if (SSOK_Win1_AutoCauseHwnd = "")
        return
    SSOK_Win1_AutoAfterTypeConfirmPending := 1
    SetTimer, SSOK_Win1_AutoAfterTypeConfirm_Run, -80
return

SSOK_Win1_AutoAfterTypeConfirm_Run:
    WinWaitClose, ahk_id %SSOK_Win1_AutoCauseHwnd%,, 5
    if (ErrorLevel)
    {
        SSOK_Win1_AutoAfterTypeConfirmPending := 0
        return
    }
    Sleep, 900
    Gosub, SSOK_DoWin1_KEdufine_TabSeq_AfterTypeConfirm
    SSOK_Win1_AutoAfterTypeConfirmPending := 0
return

SSOK_DoWin2_KEdufine_TabSeq:
    KeyWait, LWin
    KeyWait, RWin
    SendInput, {LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}
    SetKeyDelay, 80, 40
    Sleep, 150

    SendInput, {Tab 12}
    Sleep, 180
    SendInput, {Left}
    Sleep, 180
    SendInput, {Tab 7}
    Sleep, 180
    SendInput, {Space}
    Sleep, 180
    SendInput, {Tab}
    Sleep, 180
    SendInput, {Space}
    Sleep, 180
    SendInput, {Tab 16}
    Sleep, 180
    SendInput, {Down}
return

SSOK_DoWin1_KEdufine_TabSeq_10_1_4:
    KeyWait, LWin
    KeyWait, RWin
    SendInput, {LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}
    SetKeyDelay, 80, 40
    Sleep, 150

    ToolTip, Win+1 K-¿¡µàÆÄÀÎ »ç¿ëÀÚ ÁöÁ¤ Tab ¼ø¼­ ½ÇÇà Áß...
    SetTimer, SSOK_Win1_TabSeq_ClearTip, -2500

    ; ¿äÃ» ¼ø¼­ ±×´ë·Î ½ÇÇà
    ; Tab 10¹ø ¡æ ¡é 1¹ø ¡æ Tab 1¹ø ¡æ ¡é 4¹ø ¡æ Tab 2¹ø ¡æ Enter ¡æ 11 ¡æ Enter
    SendInput, {Space}
    Sleep, 1000
    SendInput, {Tab 10}
    Sleep, 180
    SendInput, {Down}
    Sleep, 180
    SendInput, {Tab}
    Sleep, 180
    SendInput, {Down 4}
    Sleep, 180
    SendInput, {Tab 2}
    Sleep, 180
    SendInput, {Enter}
    Sleep, 180
    SendInput, 11
    Sleep, 120
    SendInput, {Enter}
    Sleep, 300
    SendInput, {Tab 7}
    Sleep, 180
    SendInput, {Down}
    Sleep, 120
    SendInput, {WheelDown 1}
return

SSOK_DoWin1_KEdufine_TabSeq_AfterTypeConfirm:
    SetKeyDelay, 80, 40
    Sleep, 150
    SendInput, {Tab 10}
    Sleep, 120
    SendInput, {Down 1}
    Sleep, 120
    SendInput, {Tab 1}
    Sleep, 120
    SendInput, {Down 4}
    Sleep, 120
    SendInput, {Tab 2}
    Sleep, 120
    SendInput, {Enter}
    Sleep, 900
    SendInput, 11
    Sleep, 300
    SendInput, {Enter}
    Sleep, 300
    SendInput, {Tab 7}
    Sleep, 180
    SendInput, {Down}
    Sleep, 120
    SendInput, {WheelDown 1}
return

SSOK_IsCauseTypeWindowActive()
{
    WinGetTitle, SSOK_CauseTypeTitle, A
    return InStr(SSOK_CauseTypeTitle, "¿øÀÎÇàÀ§À¯Çü¼±ÅÃ")
}

SSOK_Win1_TabSeq_ClearTip:
    ToolTip
return
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
