; SSOK Win+F2 ¹®¼­Á¤¸® ¸ðµâ
; ssok.ahk¿¡¼­ #Include·Î ºÒ·¯¿É´Ï´Ù.

SSOK_DoF2:
    TargetHwnd := WinExist("A")
    SavedClip := ClipboardAll

    if (!DOC_IsActualDocumentInputTarget(TargetHwnd))
    {
        ; Chrome/Edge ÁÖ¼ÒÃ¢¡¤°Ë»öÃ¢Ã³·³ ÀÏ¹Ý ¹®¼­Ã¢ÀÌ ¾Æ´Ï¾îµµ,
        ; »ç¿ëÀÚ°¡ ºí·Ï ÁöÁ¤ÇÑ ÅØ½ºÆ®°¡ ÀÖÀ¸¸é ¼±ÅÃ ¿µ¿ª °è»ê/º¯È¯¸¸ Çã¿ëÇÕ´Ï´Ù.
        WinGet, SSOK_F2Proc, ProcessName, ahk_id %TargetHwnd%
        StringLower, SSOK_F2Proc, SSOK_F2Proc
        if (DOC_IsBrowserProcess(SSOK_F2Proc))
        {
            DOC_CopySelectedText(selectedText, 0.3, 2)
            if (Trim(selectedText) != "")
            {
                if (DOC_ClipboardHtmlHasTable())
                {
                    Clipboard := SavedClip
                    MsgBox, 48, SSOK ¾È³», Ç¥°¡ Æ÷ÇÔµÈ HTML ¼±ÅÃ ¿µ¿ªÀº Win+F2 ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇÕ´Ï´Ù.`nÇ¥¸¦ Á¦¿ÜÇÑ ¹®Àå ºÎºÐ¸¸ ºí·Ï ÁöÁ¤ÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
                    return
                }
                if (DOC_FindTableStartLine(selectedText) > 0)
                {
                    Clipboard := SavedClip
                    MsgBox, 48, SSOK ¾È³», Ç¥°¡ Æ÷ÇÔµÈ ¿µ¿ªÀº Win+F2 ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇÕ´Ï´Ù.`nÇ¥¸¦ Á¦¿ÜÇÑ ¹®Àå ºÎºÐ¸¸ ºí·Ï ÁöÁ¤ÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
                    return
                }

                newText := DOC_ProcessSelection(selectedText)
                newText := DOC_RemoveSelectionEndMarker(newText)
                if (!DOC_OutputText(newText, false))
                {
                    Clipboard := SavedClip
                    MsgBox, 48, SSOK ¾È³», Å¬¸³º¸µå°¡ ÁØºñµÇÁö ¾Ê¾Æ Win+F2 ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
                    return
                }
                Sleep, 150
                Clipboard := SavedClip
                return
            }
        }

        Clipboard := SavedClip
        MsgBox, 48, SSOK Help, ÅØ½ºÆ®ÀÇ ¹üÀ§¸¦ ÁöÁ¤ÇÏ°í ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.`n
        return
    }

    ; ¦¡¦¡ À¥±â¾È±â/HWP ÆíÁý±â °¨Áö ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    isHwpOrWeb := DOC_IsHwpOrWebEditor()

    DOC_CopySelectedText(selectedText, 0.3, 2)

    ; ¦¡¦¡ ºí·Ï ¼±ÅÃÀÌ ÀÖÀ» ¶§: ¼±ÅÃ ¿µ¿ª¸¸ Ã³¸® (°øÅë) ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    if (Trim(selectedText) != "")
    {
        ; ¼±ÅÃ ¿µ¿ª ¾È¿¡ Ç¥·Î º¸ÀÌ´Â ³»¿ëÀÌ ÀÖÀ¸¸é Ç¥°¡ ±úÁú ¼ö ÀÖÀ¸¹Ç·Î Áß´ÜÇÕ´Ï´Ù.
        if (DOC_ClipboardHtmlHasTable())
        {
            Clipboard := SavedClip
            MsgBox, 48, SSOK ¾È³», Ç¥°¡ Æ÷ÇÔµÈ HTML ¼±ÅÃ ¿µ¿ªÀº Win+F2 ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇÕ´Ï´Ù.`nÇ¥¸¦ Á¦¿ÜÇÑ ¹®Àå ºÎºÐ¸¸ ºí·Ï ÁöÁ¤ÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
            return
        }
        if (DOC_FindTableStartLine(selectedText) > 0)
        {
            Clipboard := SavedClip
            MsgBox, 48, SSOK ¾È³», Ç¥°¡ Æ÷ÇÔµÈ ¿µ¿ªÀº Win+F2 ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇÕ´Ï´Ù.`nÇ¥¸¦ Á¦¿ÜÇÑ ¹®Àå ºÎºÐ¸¸ ºí·Ï ÁöÁ¤ÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
            return
        }

        newText := DOC_ProcessSelection(selectedText)
        newText := DOC_RemoveSelectionEndMarker(newText)
        if (!DOC_OutputText(newText, false))
        {
            Clipboard := SavedClip
            MsgBox, 48, SSOK ¾È³», Å¬¸³º¸µå°¡ ÁØºñµÇÁö ¾Ê¾Æ Win+F2 ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
            return
        }
        Sleep, 150
        Clipboard := SavedClip
        return
    }

    ; ¦¡¦¡ ¼±ÅÃ ¾øÀ» ¶§: ÀüÃ¼ Á¤¸® ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    Send, ^a
    Sleep, 100
    if (!DOC_CopyWholeDocumentText(fullText, 1.0, 4))
    {
        Clipboard := SavedClip
        MsgBox, 48, SSOK ¾È³», ¹®¼­ ³»¿ëÀ» Å¬¸³º¸µå·Î °¡Á®¿ÀÁö ¸øÇØ Win+F2 ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
        return
    }
    fullHtmlHasTable := DOC_ClipboardHtmlHasTable()

    checkText := RegExReplace(fullText, "\s", "")

    if (checkText = "")
    {
        Clipboard := SavedClip
        WinActivate, ahk_id %TargetHwnd%
        Sleep, 80
        Send, .
        DOC_TempDotInserted := true
        Sleep, 80
        DOC_ShowTemplateGui()
        return
    }

    ; ¦¡¦¡ Ç¥ °¨Áö ½Ã: Ç¥ ½ÃÀÛ Àü±îÁö¸¸ Á¤¸®ÇÏ°í Áß´Ü ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    ; HWP Ç¥°¡ Æ÷ÇÔµÈ ¹®¼­¸¦ ÀüÃ¼ ºÙ¿©³Ö±âÇÏ¸é Ç¥ ±¸Á¶°¡ ÅØ½ºÆ®·Î ±úÁú ¼ö ÀÖ½À´Ï´Ù.
    ; µû¶ó¼­ Ç¥ ½ÃÀÛ Àü ÁÙ±îÁö¸¸ ¼±ÅÃ¡¤±³Ã¼ÇÏ°í, Ç¥ ÀÌÈÄ ³»¿ëÀº ±×´ë·Î º¸Á¸ÇÕ´Ï´Ù.
    tableStartLine := DOC_FindTableStartLine(fullText)
    if (fullHtmlHasTable && tableStartLine <= 0)
    {
        Clipboard := SavedClip
        MsgBox, 48, SSOK ¾È³», Ç¥°¡ Æ÷ÇÔµÈ HTML ¹®¼­·Î °¨ÁöµÇ¾î Win+F2 ÀÚµ¿ Á¤¸®¸¦ °Ç³Ê¶Ý´Ï´Ù.`nÇ¥¸¦ Á¦¿ÜÇÑ ¹®Àå ºÎºÐ¸¸ ºí·Ï ÁöÁ¤ÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
        return
    }
    if (tableStartLine > 0)
    {
        beforeText := DOC_GetLinesBefore(fullText, tableStartLine)
        if (Trim(beforeText) = "")
        {
            Clipboard := SavedClip
            MsgBox, 48, SSOK ¾È³», ¹®¼­ ¾ÕºÎºÐ¿¡ ¹Ù·Î Ç¥°¡ ÀÖ¾î Win+F2 ÀÚµ¿ Á¤¸®¸¦ °Ç³Ê¶Ý´Ï´Ù.`nÇ¥ µÚ ³»¿ëÀº ±×´ë·Î µÎ¾ú½À´Ï´Ù.
            return
        }

        newText := DOC_ProcessTextBeforeTable(beforeText)
        lineCount := tableStartLine - 1
        if (!DOC_ReplaceLinesFromDocStart(newText, lineCount, TargetHwnd))
        {
            Clipboard := SavedClip
            MsgBox, 48, SSOK ¾È³», Å¬¸³º¸µå°¡ ÁØºñµÇÁö ¾Ê¾Æ Ç¥ ¾ÕºÎºÐ Á¤¸®¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
            return
        }

        Sleep, 150
        Clipboard := SavedClip
        MsgBox, 64, SSOK ¾È³», Ç¥ ½ÃÀÛ Àü±îÁö¸¸ Win+F2 ÀÚµ¿ Á¤¸®¸¦ ¿Ï·áÇß½À´Ï´Ù.`nÇ¥¿Í Ç¥ ¾Æ·¡ ³»¿ëÀº ±×´ë·Î µÎ¾ú½À´Ï´Ù.
        return
    }

    newText := DOC_ProcessText(fullText)

    ; ¦¡¦¡ À¥±â¾È±â: °ø¹é 1°³ ¼±ÀÔ·Â ÈÄ ºÙ¿©³Ö±â ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    ; À¥±â¾È±â/HWP ÆíÁý±â´Â ÆíÁý ¿µ¿ªÀÌ ¿ÏÀüÈ÷ °ø¶õÀÏ ¶§ ±âº» Æ÷¸Ë(¹ÙÅÁÃ¼ µî)À¸·Î
    ; ¸®¼ÂµÇ´Â Çö»óÀÌ ÀÖ½À´Ï´Ù.
    ; °ø¹é 1°³¸¦ ¸ÕÀú ÀÔ·ÂÇØ ÆíÁý±â¸¦ "ºñ¾îÀÖÁö ¾ÊÀº" »óÅÂ·Î ¸¸µç µÚ
    ; ÀüÃ¼ ¼±ÅÃ(^a) ¡æ ºÙ¿©³Ö±â(^v) ÇÏ¸é ±âÁ¸ ¼­½Ä ±âÁØÁ¡ÀÌ À¯ÁöµË´Ï´Ù.
    ; °ø¹éÀº ºÙ¿©³Ö´Â newText·Î ¿ÏÀüÈ÷ µ¤¾î¾º¿öÁö¹Ç·Î °á°ú¹°¿¡ ³²Áö ¾Ê½À´Ï´Ù.
    if (isHwpOrWeb)
    {
        if (TargetHwnd != "")
        {
            WinActivate, ahk_id %TargetHwnd%
            Sleep, 120
        }

        ; ¹®¼­ ³¡À¸·Î ÀÌµ¿ ÈÄ °ø¹é 1°³ ÀÔ·Â
        Send, ^{End}
        Sleep, 80
        Send, {Space}
        Sleep, 120

        ; ÀüÃ¼ ¼±ÅÃ ÈÄ Á¤¸®µÈ ÅØ½ºÆ®·Î ´ëÃ¼
        Send, ^a
        Sleep, 100

        text := DOC_FixAttachGapForHwp(newText)
        text := DOC_NormalizeClipboardLineBreaks(text)
        if (!DOC_SetClipboardTextForEditor(text))
        {
            Clipboard := SavedClip
            MsgBox, 48, SSOK ¾È³», Á¤¸®µÈ ¹®¼­¸¦ Å¬¸³º¸µå¿¡ ´ãÁö ¸øÇØ ºÙ¿©³Ö±â¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
            return
        }
        Send, ^v
        Sleep, 180

        Sleep, 150
        Clipboard := SavedClip
        return
    }

    ; ¦¡¦¡ ÀÏ¹Ý ÆíÁý±â(¸Þ¸ðÀå¡¤txt µî): ±âÁ¸ ·ÎÁ÷ ±×´ë·Î ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    if (!DOC_OutputText(newText, true))
    {
        Clipboard := SavedClip
        MsgBox, 48, SSOK ¾È³», Á¤¸®µÈ ¹®¼­¸¦ Å¬¸³º¸µå¿¡ ´ãÁö ¸øÇØ ºÙ¿©³Ö±â¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
        return
    }

    Sleep, 150
    Clipboard := SavedClip
return


; =========================================================
; Ãâ·Â
; =========================================================
DOC_OutputText(text, applyFontAfter := false)
{
    global TargetHwnd

    if (TargetHwnd != "")
    {
        WinActivate, ahk_id %TargetHwnd%
        Sleep, 120
    }

    ; HWP/ODT/À¥ ±â¾È±â °øÅë ÁÙ¹Ù²Þ º¸Á¤
    text := DOC_FixAttachGapForHwp(text)
    text := DOC_NormalizeClipboardLineBreaks(text)

    ; ¼±ÅÃ ¿µ¿ªÀ» Áö¿î µÚ ºÙ¿©³Ö±âÇÏ¸é ±âÁ¸ ¼­½Ä ±âÁØÁ¡ÀÌ Èçµé¸®´Â °æ¿ì°¡ ÀÖ¾î
    ; Ctrl+V·Î ¼±ÅÃ ¿µ¿ªÀ» ±×´ë·Î ´ëÃ¼ÇÕ´Ï´Ù.
    if (!DOC_SetClipboardTextForEditor(text))
        return false

    ; À¥±â¾È±â´Â ±¼¸² 12 HTML º¸Á¶, ÀÏ¹Ý HWP´Â ±âÁ¸ ÅØ½ºÆ® ¹æ½ÄÀ¸·Î ºÙ¿©³Ö½À´Ï´Ù.

    Send, ^v
    Sleep, 180

    ; ÀÏ¹Ý HWP¿¡¼­¸¸ COMÀ¸·Î ±¼¸² 12¸¦ º¸Á¤ÇÕ´Ï´Ù.
    ; HWP ÆíÁý±â(À¥±â¾È±â)¿¡¼­´Â ÀüÃ¼ ¼­½Ä ÀçÀû¿ëÀÌ ¾ç½ÄÀ» ÆÄ±«ÇÏ¹Ç·Î ¹Ýµå½Ã °Ç³Ê¶Ý´Ï´Ù.
    if (applyFontAfter && !DOC_IsHwpOrWebEditor())
        DOC_TrySetGulim12AfterPaste_Final(text)
    return true
}

DOC_TrySetGulim12AfterPaste_Final(text := "")
{
    ; Win+F2 ÃÖÁ¾ º¸Á¤ Àü¿ë
    ; ¸ñÀû: HWP/ODT °è¿­¿¡¼­ ºÙ¿©³Ö±â ÈÄ ±Û²Ã Èçµé¸²À» ÁÙÀÌ°í,
    ;       ±¼¸² 12pt + ¿ÞÂÊ Á¤·Ä + ³»¾î¾²±â 17pt¸¦ ¾ÈÁ¤ÀûÀ¸·Î Àç½ÃµµÇÕ´Ï´Ù.
    ; ÁÖÀÇ: ´Ù¸¥ ±â´É¿¡¼­´Â È£ÃâÇÏÁö ¾ÊÀ¸¸ç, ½ÇÆÐÇØµµ ¿ø¹® ºÙ¿©³Ö±â °á°ú´Â À¯ÁöÇÕ´Ï´Ù.

    ; 1Â÷: HWP COM ¹æ½Ä. ÀÏ¹Ý HWP¿Í ÀÏºÎ ODT/HWP °´Ã¼°¡ ÀâÈ÷´Â È¯°æ¿¡¼­ °¡Àå ¾ÈÁ¤ÀûÀÔ´Ï´Ù.
    if (DOC_TryHwpComFinalFormat(text))
        return

    ; 2Â÷: COMÀÌ ÀâÈ÷Áö ¾Ê´Â À¥ ±â¾È±â/ODT¿¡¼­´Â ´ÜÃàÅ° °­Á¦ Á¶ÀÛÀÌ ¿ÀÈ÷·Á À§ÇèÇÒ ¼ö ÀÖ¾î
    ;      ¹®¼­ ³»¿ëÀ» ¸Á°¡¶ß¸®Áö ¾Êµµ·Ï Ãß°¡ Á¶ÀÛÇÏÁö ¾Ê½À´Ï´Ù.
    ;      À¥ ÆíÁý±â´Â DOC_OutputText() ´Ü°èÀÇ HTML Å¬¸³º¸µå(±¼¸² 12pt)°¡ 1Â÷ º¸Á¤ÀÔ´Ï´Ù.
    return
}

DOC_HasResponsiveHwpHost(timeoutMs := 250)
{
    exes := ["hwp.exe", "hwpx.exe"]
    for _, exe in exes
    {
        WinGet, hwpList, List, ahk_exe %exe%
        Loop, %hwpList%
        {
            hwnd := hwpList%A_Index%
            if (DOC_IsWindowResponsive(hwnd, timeoutMs))
                return true
        }
    }
    return false
}

DOC_IsWindowResponsive(hwnd, timeoutMs := 250)
{
    if (!hwnd)
        return false
    result := 0
    flags := 0x2 ; SMTO_ABORTIFHUNG
    return DllCall("user32\SendMessageTimeout", "Ptr", hwnd, "UInt", 0, "Ptr", 0, "Ptr", 0, "UInt", flags, "UInt", timeoutMs, "Ptr*", result) ? true : false
}

DOC_TryHwpComFinalFormat(text := "")
{
    if (!DOC_HasResponsiveHwpHost())
        return false

    try
    {
        hwp := ComObjActive("HWPFrame.HwpObject")
    }
    catch
    {
        return false
    }

    ; HWP º¸¾È ¸ðµâÀÌ ¾ø¾îµµ ¼­½Ä ¸í·ÉÀº µÇ´Â °æ¿ì°¡ ¸¹Áö¸¸,
    ; µî·Ï °¡´ÉÇÑ È¯°æ¿¡¼­´Â ¹Ì¸® ½ÃµµÇÕ´Ï´Ù. ½ÇÆÐÇØµµ ¹«½ÃÇÕ´Ï´Ù.
    try
        hwp.RegisterModule("FilePathCheckDLL", "FilePathCheckerModule")

    ; È°¼º ¹®¼­°¡ ¾ø°Å³ª °´Ã¼°¡ ºÒ¾ÈÁ¤ÇÑ °æ¿ì ´ëºñ
    try
        hwp.XHwpWindows.Item(0).Visible := true

    ; ºÙ¿©³Ö±â Á÷ÈÄ ·»´õ¸µ Áö¿¬À» °í·ÁÇØ Âª°Ô ±â´Ù¸³´Ï´Ù.
    Sleep, 120

    ; ÇöÀç ¹®¼­ ÀüÃ¼ ¼±ÅÃ. Win+F2 ÀüÃ¼ ÀÚµ¿Á¤¸® ÈÄ ÃÖÁ¾ ¾ç½Ä º¸Á¤ ¸ñÀûÀÔ´Ï´Ù.
    if (!DOC_HwpSelectAll(hwp))
        return false

    Sleep, 100

    ; ¼Óµµº¸´Ù ¾ÈÁ¤¼º: ±ÛÀÚ¸ð¾ç ¡æ ¹®´Ü¸ð¾ç ¡æ ±ÛÀÚ¸ð¾çÀ» 2È¸±îÁö Àç½ÃµµÇÕ´Ï´Ù.
    Loop, 2
    {
        DOC_HwpApplyCharShapeGulim12(hwp)
        Sleep, 80
        DOC_HwpApplyParaShapeLeftHang17(hwp)
        Sleep, 80
        DOC_HwpApplyCharShapeGulim12(hwp)
        Sleep, 80
    }


    ; ¼±ÅÃ ÇØÁ¦. ½ÇÆÐÇØµµ ¹®Á¦ ¾øµµ·Ï Ã³¸®ÇÕ´Ï´Ù.
    try
        hwp.HAction.Run("MoveDocEnd")
    catch
    {
        try
            hwp.HAction.Run("Cancel")
        catch
            Send, {Right}
    }

    return true
}


DOC_HwpSelectAll(hwp)
{
    ok := false
    try
    {
        hwp.HAction.Run("SelectAll")
        ok := true
    }
    catch
    {
    }

    if (!ok)
    {
        try
        {
            hwp.Run("SelectAll")
            ok := true
        }
        catch
        {
        }
    }

    if (!ok)
    {
        Send, ^a
        Sleep, 120
        ok := true
    }
    return ok
}

DOC_HwpApplyCharShapeGulim12(hwp)
{
    ; ±¼¸² 12pt °­Á¦ Àû¿ë. ÇÑ±Û/¿µ¹®/ÇÑÀÚ/±âÈ£ ¿µ¿ªÀ» ¸ðµÎ ±¼¸²À¸·Î ¸ÂÃä´Ï´Ù.
    try
    {
        hwp.HAction.GetDefault("CharShape", hwp.HParameterSet.HCharShape.HSet)

        ; ±Û²Ã¸í Á÷Á¢ ´ëÀÔ
        try
        {
            hwp.HParameterSet.HCharShape.FaceNameHangul := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameLatin := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameHanja := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameJapanese := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameOther := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameSymbol := "±¼¸²"
            hwp.HParameterSet.HCharShape.FaceNameUser := "±¼¸²"
            hwp.HParameterSet.HCharShape.Height := 1200
        }
        catch
        {
        }

        ; HWP ¹öÀüº° SetItem º¸Á¶
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
        catch
        {
        }

        ; ±Û²Ã Å¸ÀÔµµ °¡´ÉÇÑ °æ¿ì ÀÏ¹Ý ±Û²Ã·Î ¸ÂÃä´Ï´Ù.
        try
        {
            hwp.HParameterSet.HCharShape.FontTypeHangul := 1
            hwp.HParameterSet.HCharShape.FontTypeLatin := 1
            hwp.HParameterSet.HCharShape.FontTypeHanja := 1
            hwp.HParameterSet.HCharShape.FontTypeJapanese := 1
            hwp.HParameterSet.HCharShape.FontTypeOther := 1
            hwp.HParameterSet.HCharShape.FontTypeSymbol := 1
            hwp.HParameterSet.HCharShape.FontTypeUser := 1
        }
        catch
        {
        }

        hwp.HAction.Execute("CharShape", hwp.HParameterSet.HCharShape.HSet)
        return true
    }
    catch
    {
        return false
    }
}

DOC_HwpApplyParaShapeLeftHang17(hwp)
{
    ; ¿ÞÂÊ Á¤·Ä + ³»¾î¾²±â 17pt.
    ; 17pt´Â ¾à 6mmÀÌ¹Ç·Î, HWPUnit º¯È¯ÀÌ °¡´ÉÇÏ¸é 6mm ±âÁØÀ» »ç¿ëÇÏ°í,
    ; ½ÇÆÐÇÏ¸é ±âÁ¸ °ü·Ê°ª 1700À» »ç¿ëÇÕ´Ï´Ù.
    hang := 1700
    try
        hang := hwp.MiliToHwpUnit(6.0)

    try
    {
        hwp.HAction.GetDefault("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)

        ; ¿ÞÂÊ Á¤·Ä
        try
            hwp.HParameterSet.HParaShape.AlignType := 0
        catch
        {
        }
        try
            hwp.HParameterSet.HParaShape.SetItem("AlignType", 0)
        catch
        {
        }

        ; ³»¾î¾²±â: ¿ÞÂÊ ¿©¹é + À½¼ö µé¿©¾²±â Á¶ÇÕ
        try
        {
            hwp.HParameterSet.HParaShape.LeftMargin := hang
            hwp.HParameterSet.HParaShape.Indent := -hang
        }
        catch
        {
        }
        try
        {
            hwp.HParameterSet.HParaShape.SetItem("LeftMargin", hang)
            hwp.HParameterSet.HParaShape.SetItem("Indent", -hang)
        }
        catch
        {
        }

        hwp.HAction.Execute("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)
    }
    catch
    {
        ; ÀÏºÎ ¹öÀüÀº ¾×¼Ç¸í Á÷Á¢ ½ÇÇàÀÌ ´õ Àß ¸Ô´Â °æ¿ì°¡ ÀÖ¾î º¸Á¶ ½ÃµµÇÕ´Ï´Ù.
        try
            hwp.HAction.Run("ParagraphShapeAlignLeft")
        catch
        {
        }
        return false
    }

    ; Á¤·Ä ¾×¼ÇÀ» ¸¶Áö¸·¿¡ ÇÑ ¹ø ´õ ½ÇÇàÇØ °¡¿îµ¥/¾çÂÊ Á¤·Ä ÀÜ·ù¸¦ ÁÙÀÔ´Ï´Ù.
    try
        hwp.HAction.Run("ParagraphShapeAlignLeft")
    catch
    {
    }

    return true
}






; =========================================================
; À¥/ODT ÆíÁý±â °¨Áö ¹× ±¼¸² 12 HTML Å¬¸³º¸µå º¸Á¶
; =========================================================
DOC_IsBrowserProcess(proc)
{
    StringLower, proc, proc
    if RegExMatch(proc, "i)^(chrome|msedge|iexplore|firefox|whale|brave|vivaldi|opera|opera_gx)\.exe$")
        return true
    return false
}

DOC_IsWebLikeEditor()
{
    ; Chrome/Edge/Internet Explorer µî À¥ ±â¹Ý ¿¡µàÆÄÀÎ/ODT ÆíÁý±â °¨Áö
    WinGet, proc, ProcessName, A
    StringLower, proc, proc
    if (DOC_IsBrowserProcess(proc))
        return true
    return false
}

DOC_IsHwpOrWebEditor()
{
    ; ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    ; HWP ÆíÁý±â(À¥±â¾È±â Æ÷ÇÔ) °¨Áö ÇÔ¼ö
    ; ¸ñÀû: Win+F2¿¡¼­ ÀüÃ¼¼±ÅÃ(^a)+ºÙ¿©³Ö±â(^v) ¶Ç´Â COM ¼­½Ä ÀüÃ¼ ÀçÀû¿ëÀÌ
    ;       Ç¥¡¤¾ç½Ä ±¸Á¶¸¦ ÆÄ±«ÇÏ´Â °ÍÀ» ¹æÁöÇÏ±â À§ÇØ È¯°æÀ» ÆÇº°ÇÕ´Ï´Ù.
    ;
    ; °¨Áö ´ë»ó:
    ;  1) ÇÑ±Û°úÄÄÇ»ÅÍ HWP ÆíÁý±â ÇÁ·Î¼¼½º (hwp.exe, hwpx.exe µî)
    ;  2) À¥ ±â¹Ý ±â¾È±â (¿¡µàÆÄÀÎ/K-¿¡µàÆÄÀÎ µî)°¡ ¿­¸° ºê¶ó¿ìÀú Ã¢
    ;     - Ã¢ Á¦¸ñ¿¡ "±â¾È", "¿¡µàÆÄÀÎ", "edufine", "¿Â³ª¶ó" µîÀÌ Æ÷ÇÔµÈ °æ¿ì
    ;  3) HWP COM °´Ã¼°¡ È°¼ºÈ­µÈ È¯°æ (À¥ ³»Àå HWP ÆíÁý ÄÁÆ®·Ñ Æ÷ÇÔ)
    ; ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡

    WinGet, proc, ProcessName, A
    StringLower, proc, proc

    ; 1) µ¶¸³ ½ÇÇàÇü HWP ÇÁ·Î¼¼½º
    if (proc = "hwp.exe" || proc = "hwpx.exe" || proc = "gulim.exe")
        return true

    ; 2) ºê¶ó¿ìÀú¿¡¼­ ¿­¸° À¥±â¾È±â Ã¢ Á¦¸ñ °¨Áö
    if (DOC_IsBrowserProcess(proc))
    {
        WinGetTitle, winTitle, A
        StringLower, winTitleL, winTitle
        ; ¿¡µàÆÄÀÎ/¿Â³ª¶ó/À¥±â¾È °ü·Ã Å°¿öµå
        keywords := ["±â¾È", "¿¡µàÆÄÀÎ", "edufine", "¿Â³ª¶ó", "k-edufine"
                    , "¾÷¹«°ü¸®", "¾÷¹«°ü¸®½Ã½ºÅÛ", "°áÀç", "°ø¹®", "hwpÆíÁý", "hwp ÆíÁý", "¹®¼­ÆíÁý", "¹®¼­ ÆíÁý"]
        for _, kw in keywords
        {
            if InStr(winTitleL, kw)
                return true
        }
    }

    ; 3) HWP COM °´Ã¼ È°¼º ¿©ºÎ (À¥ ³»Àå HWP ÄÁÆ®·Ñ Æ÷ÇÔ)
    ; COM ¼­¹ö°¡ Á»ºñ »óÅÂÀÌ¸é ComObjActive ÀÚÃ¼°¡ ¿À·¡ ¸ØÃâ ¼ö ÀÖÀ¸¹Ç·Î,
    ; ÀÀ´ä ÁßÀÎ HWP Ã¢ÀÌ ÀÖÀ» ¶§¸¸ COM¿¡ Á¢±ÙÇÕ´Ï´Ù.
    if (!DOC_HasResponsiveHwpHost())
        return false

    try
    {
        hwpTest := ComObjActive("HWPFrame.HwpObject")
        if (IsObject(hwpTest))
            return true
    }

    return false
}

DOC_IsActualDocumentInputTarget(hwnd)
{
    if (hwnd = "")
        return false

    WinGet, proc, ProcessName, ahk_id %hwnd%
    StringLower, proc, proc

    if (proc = "explorer.exe" || proc = "searchhost.exe" || proc = "searchui.exe")
        return false
    if (proc = "autohotkey.exe" || proc = "autohotkey64.exe" || proc = "autohotkeyu64.exe" || proc = "autohotkeyu32.exe")
        return false

    if (DOC_IsBrowserProcess(proc))
    {
        WinGetTitle, winTitle, ahk_id %hwnd%
        StringLower, winTitleL, winTitle
        keywords := ["±â¾È", "¿¡µàÆÄÀÎ", "edufine", "¿Â³ª¶ó", "k-edufine"
                    , "¾÷¹«°ü¸®", "¾÷¹«°ü¸®½Ã½ºÅÛ", "°áÀç", "°ø¹®", "hwpÆíÁý", "hwp ÆíÁý", "¹®¼­ÆíÁý", "¹®¼­ ÆíÁý"]
        for _, kw in keywords
        {
            if InStr(winTitleL, kw)
                return true
        }
        return false
    }

    return true
}
DOC_CopySelectedText(ByRef outText, timeoutSeconds := 0.3, retries := 2)
{
    outText := ""
    Loop, %retries%
    {
        Clipboard := ""
        Sleep, 40
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

DOC_CopyWholeDocumentText(ByRef outText, timeoutSeconds := 1.0, retries := 4)
{
    outText := ""
    Loop, %retries%
    {
        Clipboard := ""
        Sleep, 60
        Send, ^c
        ClipWait, %timeoutSeconds%
        if (!ErrorLevel)
        {
            outText := Clipboard
            return true
        }
        Sleep, 100
    }

    ; ºó ¹®¼­´Â Ctrl+A ÈÄ Ctrl+C¸¦ ÇØµµ Å¬¸³º¸µå°¡ ºñ¾î ÀÖ¾î ClipWait°¡ ½ÇÆÐÇÕ´Ï´Ù.
    ; ÀüÃ¼ ¹®¼­ È®ÀÎ ´Ü°è¿¡¼­´Â ÀÌ »óÅÂ¸¦ ½ÇÆÐ°¡ ¾Æ´Ï¶ó °ø¶õ ¹®¼­·Î Ã³¸®ÇÕ´Ï´Ù.
    outText := ""
    return true
}
DOC_WaitClipboardReady(timeoutSeconds := 0.7)
{
    ClipWait, %timeoutSeconds%
    if (ErrorLevel)
        return false
    return true
}

DOC_SetClipboardTextForEditor(text, timeoutSeconds := 0.7, retries := 3)
{
    Loop, %retries%
    {
        Clipboard := ""
        Sleep, 60

        ; Chrome/Edge ±â¹Ý À¥±â¾È±â¡¤ODT´Â ¼ø¼ö ÅØ½ºÆ® ºÙ¿©³Ö±â ¶§ ±âº» ±Û²ÃÀÌ Èçµé¸± ¼ö ÀÖ¾î
        ; ±¼¸² 12pt HTML Çü½ÄÀ» ÇÔ²² Á¦°øÇÕ´Ï´Ù. ÀÏ¹Ý HWP´Â ±âÁ¸ ÅØ½ºÆ® ¹æ½ÄÀ» À¯ÁöÇÕ´Ï´Ù.
        if (DOC_IsWebLikeEditor())
        {
            if (DOC_SetClipboardHtmlGulim12(text) && DOC_WaitClipboardReady(timeoutSeconds))
                return true
        }

        Clipboard := text
        if (DOC_WaitClipboardReady(timeoutSeconds))
            return true
        Sleep, 80
    }
    return false
}
DOC_SetClipboardHtmlGulim12(text)
{
    ; AHK v1 ¾ÈÁ¤¼º ¿ì¼±: ÀÏ¹Ý ÅØ½ºÆ®´Â Ç×»ó À¯ÁöÇÏ°í,
    ; °¡´ÉÇÏ¸é CF_HTML Çü½Äµµ °°ÀÌ µî·ÏÇÏ¿© À¥ ODT°¡ ±¼¸² 12pt·Î ¹ÞÀ» ¼ö ÀÖ°Ô ÇÕ´Ï´Ù.
    Clipboard := text

    html := DOC_BuildGulim12Html(text)
    if (html = "")
        return false

    return DOC_PutHtmlOnClipboard(html, text)
}

DOC_BuildGulim12Html(text)
{
    ; ÁÙ ´ÜÀ§·Î ºÐ¸®ÇÏ¿© * ½ÃÀÛ ÁÙÀº Áß°íµñ 10pt + µé¿©¾²±â Àû¿ë
    rawText := StrReplace(text, "`r`n", "`n")
    rawText := StrReplace(rawText, "`r", "`n")

    lines := StrSplit(rawText, "`n")
    htmlBody := ""

    Loop, % lines.MaxIndex()
    {
        lineRaw := lines[A_Index]
        lineEsc := DOC_EscapeHtml(lineRaw)

        ; * ·Î ½ÃÀÛÇÏ´Â ÁÙ (°ø¹é ÀÖµç ¾øµç): HYÁß°íµñ 10pt + µé¿©¾²±â
        if RegExMatch(lineRaw, "^\*")
        {
            htmlBody .= "<div style=" . Chr(34)
                . "font-family:'HYÁß°íµñ','HYGraphicM','HYÁß°íµñÃ¼',sans-serif;"
                . "font-size:10pt;line-height:1.6;"
                . "padding-left:1em;text-indent:0;"
                . Chr(34) . ">" . lineEsc . "</div>"
        }
        else
        {
            htmlBody .= "<div style=" . Chr(34)
                . "font-family:Gulim,±¼¸²,sans-serif;"
                . "font-size:12pt;line-height:1.6;"
                . Chr(34) . ">" . lineEsc . "</div>"
        }
    }

    return "<html><body><!--StartFragment-->" . htmlBody . "<!--EndFragment--></body></html>"
}

DOC_EscapeHtml(text)
{
    text := StrReplace(text, "&", "&amp;")
    text := StrReplace(text, "<", "&lt;")
    text := StrReplace(text, ">", "&gt;")
    text := StrReplace(text, Chr(34), "&quot;")
    return text
}

DOC_Utf8ByteLen(text)
{
    return StrPut(text, "UTF-8") - 1
}
DOC_PutHtmlOnClipboard(html, plainText := "")
{
    ; Windows CF_HTML Çü½Ä µî·Ï. ½ÇÆÐÇØµµ ÀÏ¹Ý ÅØ½ºÆ® Clipboard´Â À¯ÁöµË´Ï´Ù.
    try
    {
        fmt := DllCall("RegisterClipboardFormat", "Str", "HTML Format", "UInt")
        if (!fmt)
            return false

        prefix := "Version:0.9`r`nStartHTML:0000000000`r`nEndHTML:0000000000`r`nStartFragment:0000000000`r`nEndFragment:0000000000`r`n"
        full := prefix . html
        startHTML := DOC_Utf8ByteLen(prefix)
        endHTML := DOC_Utf8ByteLen(full)
        startFragMark := "<!--StartFragment-->"
        endFragMark := "<!--EndFragment-->"
        startFragment := DOC_Utf8ByteLen(SubStr(full, 1, InStr(full, startFragMark) + StrLen(startFragMark) - 1))
        endFragment := DOC_Utf8ByteLen(SubStr(full, 1, InStr(full, endFragMark) - 1))

        header := "Version:0.9`r`n"
        header .= "StartHTML:" . SubStr("0000000000" . startHTML, -9) . "`r`n"
        header .= "EndHTML:" . SubStr("0000000000" . endHTML, -9) . "`r`n"
        header .= "StartFragment:" . SubStr("0000000000" . startFragment, -9) . "`r`n"
        header .= "EndFragment:" . SubStr("0000000000" . endFragment, -9) . "`r`n"
        cfhtml := header . html

        size := StrPut(cfhtml, "UTF-8")
        hMem := DllCall("GlobalAlloc", "UInt", 0x42, "UPtr", size, "UPtr")
        if (!hMem)
            return false
        pMem := DllCall("GlobalLock", "UPtr", hMem, "UPtr")
        StrPut(cfhtml, pMem, size, "UTF-8")
        DllCall("GlobalUnlock", "UPtr", hMem)

        if (!DllCall("OpenClipboard", "Ptr", 0))
            return false
        DllCall("EmptyClipboard")

        if (plainText != "")
        {
            uSize := (StrLen(plainText) + 1) * 2
            hText := DllCall("GlobalAlloc", "UInt", 0x42, "UPtr", uSize, "UPtr")
            pText := DllCall("GlobalLock", "UPtr", hText, "UPtr")
            StrPut(plainText, pText, "UTF-16")
            DllCall("GlobalUnlock", "UPtr", hText)
            DllCall("SetClipboardData", "UInt", 13, "UPtr", hText)
        }

        DllCall("SetClipboardData", "UInt", fmt, "UPtr", hMem)
        DllCall("CloseClipboard")
        return true
    }
    catch
    {
        try
            DllCall("CloseClipboard")
        return false
    }
}

DOC_ClipboardHtmlHasTable()
{
    try
    {
        fmt := DllCall("RegisterClipboardFormat", "Str", "HTML Format", "UInt")
        if (!fmt || !DllCall("OpenClipboard", "Ptr", 0))
            return false
        hData := DllCall("GetClipboardData", "UInt", fmt, "UPtr")
        if (!hData)
        {
            DllCall("CloseClipboard")
            return false
        }
        pData := DllCall("GlobalLock", "UPtr", hData, "UPtr")
        if (!pData)
        {
            DllCall("CloseClipboard")
            return false
        }
        size := DllCall("GlobalSize", "UPtr", hData, "UPtr")
        html := StrGet(pData, size, "UTF-8")
        DllCall("GlobalUnlock", "UPtr", hData)
        DllCall("CloseClipboard")
        return RegExMatch(html, "i)<\s*(table|tr|td|th)\b")
    }
    catch
    {
        try DllCall("CloseClipboard")
        return false
    }
}
; =========================================================
; Å¬¸³º¸µå/ODT/HWP ÁÙ¹Ù²Þ ¾ÈÁ¤È­
; =========================================================
DOC_NormalizeClipboardLineBreaks(text)
{
    ; AHK v1 / HWP / À¥ ODT¿¡¼­ ÁÙ¹Ù²ÞÀÌ ±úÁö°Å³ª ÇÑ ÁÙ·Î ºÙ´Â ¹®Á¦¸¦ ÁÙÀÌ±â À§ÇØ
    ; ¸ðµç ÁÙ¹Ù²ÞÀ» Windows Ç¥ÁØ CRLF·Î ÅëÀÏÇÕ´Ï´Ù.
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")

    ; ºÒÇÊ¿äÇÑ Á¦¾î¹®ÀÚ´Â Á¦°ÅÇÏµÇ ÅÇ/ÁÙ¹Ù²ÞÀº À¯ÁöÇÕ´Ï´Ù.
    text := RegExReplace(text, "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")

    ; °úµµÇÑ ¿¬¼Ó °ø¹é ÁÙÀº ÃÖ´ë 2ÁÙ ºó ÁÙ Á¤µµ·Î ¾ÈÁ¤È­ÇÕ´Ï´Ù.
    text := RegExReplace(text, "`n{4,}", "`n`n`n")

    ; HWP/Windows ºÙ¿©³Ö±â¿ë CRLF º¹¿ø
    text := StrReplace(text, "`n", "`r`n")
    return text
}

; =========================================================
; HWP ºÙ¿©³Ö±â¿ë ºÙÀÓ ¾Õ ÁÙ¹Ù²Þ º¸Á¤
; =========================================================
DOC_FixAttachGapForHwp(text)
{
    ; ºÙÀÓ ¾Õ¿¡¸¸ ºó ÁÙ 1ÁÙÀ» µÎ°í, 1. ´ÙÀ½ °¡.³ª.´Ù. »çÀÌ µî ³ª¸ÓÁö ºó ÁÙÀº Á¦°ÅÇÕ´Ï´Ù.
    text := DOC_KeepOnlyAttachBlankLine(text)

    ; Windows/HWP¿ë ÁÙ¹Ù²ÞÀ¸·Î º¹¿ø
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    text := StrReplace(text, "`n", "`r`n")

    return text
}


; =========================================================
; ÅÛÇÃ¸´ ¼±ÅÃ GUI
; Á¦¸ñÀº GUI ¾ÈÂÊÀÌ ¾Æ´Ï¶ó À©µµ¿ì ±âº» Å¸ÀÌÆ²¹Ù¿¡ Ç¥½Ã
; =========================================================
DOC_ShowTemplateGui()
{
    global APP_FULL_TITLE, TargetHwnd

    activeHwnd := WinExist("A")
    if (!DOC_IsActualDocumentInputTarget(activeHwnd))
    {
        MsgBox, 48, SSOK Help, ÅØ½ºÆ® ÀÔ·ÂÀÌ °¡´ÉÇÑ °÷À» Å¬¸¯ÇÑ µÚ [°£´Ü ÀÛ¼º]À» ´Ù½Ã ´­·¯ÁÖ¼¼¿ä.`n
        return
    }
    TargetHwnd := activeHwnd

    Gui, DOC:Destroy

    ; +ToolWindow¸¦ »©¾ß ±âº» Å¸ÀÌÆ²¹Ù°¡ ³Ð°Ô Ç¥½ÃµË´Ï´Ù.
    ; +CaptionÀº ±âº» Á¦¸ñÁÙÀ» È®½ÇÈ÷ º¸ÀÌ°Ô ÇÕ´Ï´Ù.
    Gui, DOC:+AlwaysOnTop +Caption +HwndDOC_Hwnd
    Gui, DOC:Color, F4FAFB
    Gui, DOC:Margin, 0, 0

    ; -----------------------------------------------------
    ; »ó´Ü ¾È³» ¿µ¿ª
    ; Á¦¸ñÀº Å¸ÀÌÆ²¹Ù¿¡¸¸ Ç¥½ÃÇÏ°í, GUI ³»ºÎ¿¡´Â ÂªÀº ¾È³»¸¸ Ç¥½Ã
    ; -----------------------------------------------------
    Gui, DOC:Font, s17 Bold c005BAC, Malgun Gothic
    Gui, DOC:Add, Text, x15 y16 w650 h34 Center, ½î¿Á for K-¿¡µàÆÄÀÎ

    ; ±¸ºÐ¼±
    Gui, DOC:Add, Text, x15 y58 w650 h1 0x10

    ; -----------------------------------------------------
    ; ¸Þ´º ±¸ºÐ
    ; -----------------------------------------------------
    Gui, DOC:Font, s10 Bold c000000, Malgun Gothic
    Gui, DOC:Add, Text, x15 y72 w120 h28 Center, ¹°Ç°
    Gui, DOC:Add, Text, x145 y72 w120 h28 Center, ¿ë¿ª
    Gui, DOC:Add, Text, x275 y72 w120 h28 Center, ±âÅ¸
    Gui, DOC:Add, Text, x405 y72 w120 h28 Center, ¼¼ÀÔ
    Gui, DOC:Add, Text, x535 y72 w120 h28 Center, ÀÏ¹Ý

    Gui, DOC:Font, s9 Bold c003D73, Malgun Gothic
    Gui, DOC:Add, Button, x15 y126 w120 h34 gGUI_GoodsGeneral, ÀÏ¹Ý¹°Ç°
    Gui, DOC:Add, Button, x15 y166 w120 h34 gGUI_Supplies, ÇÐ½ÀÁØºñ¹°
    Gui, DOC:Add, Button, x15 y206 w120 h34 gGUI_Book, µµ¼­
    Gui, DOC:Add, Button, x15 y246 w120 h34 gGUI_Album, Á¹¾÷¾Ù¹ü
    Gui, DOC:Add, Button, x15 y286 w120 h34 gGUI_CareSnack, µ¹º½±³½Ç °£½Ä
    Gui, DOC:Add, Button, x15 y326 w120 h34 gGUI_Furniture, ºñÇ°
    Gui, DOC:Add, Button, x15 y366 w120 h34 gGUI_OldGoodsImprove, ³ëÈÄÈ­ È¯°æ°³¼±
    Gui, DOC:Add, Button, x15 y406 w120 h34 gGUI_SchoolMeal, ÇÐ±³ ±Þ½Ä

    Gui, DOC:Font, s9 Bold c004D3B, Malgun Gothic
    Gui, DOC:Add, Button, x145 y126 w120 h34 gGUI_ServiceGeneral, ÀÏ¹Ý¿ë¿ª
    Gui, DOC:Add, Button, x145 y166 w120 h34 gGUI_FieldTripBus, ÇöÀåÃ¼Çè Â÷·®ÀÓÂ÷
    Gui, DOC:Add, Button, x145 y206 w120 h34 gGUI_SchoolTrip, ¼öÇÐ¿©Çà ¿ë¿ª
    Gui, DOC:Add, Button, x145 y246 w120 h34 gGUI_AfterSchool, ¹æ°úÈÄÇÐ±³ À§Å¹
    Gui, DOC:Add, Button, x145 y286 w120 h34 gGUI_SchoolBus, ÅëÇÐ¹ö½º ÀÓÂ÷
    Gui, DOC:Add, Button, x145 y326 w120 h34 gGUI_CleaningService, Ã»¼Ò¿ë¿ª

    Gui, DOC:Font, s9 Bold c423070, Malgun Gothic
    Gui, DOC:Add, Button, x275 y126 w120 h34 gGUI_MeetingFee, ÇùÀÇÈ¸ºñ
    Gui, DOC:Add, Button, x275 y166 w120 h34 gGUI_LecturerFee, °­»çºñ
    Gui, DOC:Add, Button, x275 y206 w120 h34 gGUI_TravelFee, ÃâÀåºñ

    ; ±âÅ¸¿Í °ø»ç »çÀÌ¸¦ ÇÑ ÁÙ ¶ç¿ö ±¸ºÐ
    Gui, DOC:Font, s9 Bold c5A3300, Malgun Gothic
    Gui, DOC:Add, Button, x275 y286 w120 h30 gGUI_OtherGift, »óÇ°±Ç
    Gui, DOC:Add, Button, x275 y326 w120 h30 gGUI_OtherCard, ¹ýÀÎÄ«µå»ç¿ëºÎ
    Gui, DOC:Add, Text, x275 y366 w120 h24 Center, °ø»ç
    Gui, DOC:Add, Button, x275 y406 w120 h30 gGUI_Construction, ÀÏ¹Ý°ø»ç
    Gui, DOC:Add, Text, x405 y370 w120 h24 Center, ¿¹»ê
    Gui, DOC:Add, Button, x405 y410 w120 h30 gGUI_Budget1, ¿¹»ê¿ä±¸¼­
    Gui, DOC:Add, Button, x405 y440 w120 h30 gGUI_Budget2, Ãß°¡°æÁ¤¿¹»ê
    Gui, DOC:Add, Button, x405 y470 w120 h30 gGUI_Budget3, ¼º¸³Àü(¸ñÀû»ç¾÷ºñ)
    Gui, DOC:Add, Button, x405 y500 w120 h30 gGUI_Budget4, ¼º¸³Àü(¼öÀÍÀÚºÎ´ã)
    Gui, DOC:Add, Button, x405 y530 w120 h30 gGUI_Budget5, °ú¸ñ°æÁ¤

    Gui, DOC:Font, s9 Bold c703000, Malgun Gothic
    Gui, DOC:Add, Button, x405 y126 w120 h34 gGUI_RevenueCollect, % SSOK_RevenueLabel(1)
    Gui, DOC:Add, Button, x405 y186 w120 h34 gGUI_RevenueInterest, % SSOK_RevenueLabel(3)
    Gui, DOC:Add, Button, x405 y216 w120 h34 gGUI_RevenueTransfer, % SSOK_RevenueLabel(4)
    Gui, DOC:Add, Button, x405 y276 w120 h34 gGUI_RevenueRefundPurpose, % SSOK_RevenueLabel(6)

    Gui, DOC:Add, Button, x405 y156 w120 h28 gGUI_RevenueFieldTrip, % SSOK_RevenueLabel(2)
    Gui, DOC:Add, Button, x405 y246 w120 h28 gGUI_RevenueSettlement, % SSOK_RevenueLabel(5)
    Gui, DOC:Add, Button, x405 y306 w120 h28 gGUI_RevenueRefundBeneficiary, % SSOK_RevenueLabel(7)
    Gui, DOC:Font, s9 Bold c003D73, Malgun Gothic
    Gui, DOC:Add, Button, x535 y126 w120 h34 gGUI_GeneralPlan, °èÈ¹¼ö¸³
    Gui, DOC:Add, Button, x535 y166 w120 h34 gGUI_GeneralEventNotice, Çà»ç¾È³»

    Gui, DOC:Font, s9 Bold c423070, Malgun Gothic
    Gui, DOC:Add, Text, x535 y286 w120 h24 Center, ±âÅ¸
    Gui, DOC:Add, Button, x535 y326 w120 h34 gGUI_NationalPetition, ±¹¹Î½Å¹®°í
    Gui, DOC:Add, Button, x535 y366 w120 h34 gGUI_SchoolMarket, ÇÐ±³ÀåÅÍ
    Gui, DOC:Add, Button, x535 y406 w120 h34 gGUI_LegalBasis, ¹ý·É±Ù°Å

    ; ¿ÞÂÊ ÇÏ´Ü ¾È³»¹®
    Gui, DOC:Font, s7 c777777, Malgun Gothic
    Gui, DOC:Add, Text, x15 y570 w300 h18 Left, ½î¿Á for K-¿¡µàÆÄÀÎ (SSOK-Sejong Smart One Key)

    ; ¿À¸¥ÂÊ ÇÏ´Ü ÀúÀÛ±Ç
    Gui, DOC:Font, s7 c777777, Malgun Gothic
    Gui, DOC:Add, Text, x365 y570 w290 h18 Right, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£

    DOC_GetSidebarAttachedGuiPos(680, 510, DOCWinX, DOCWinY)
    Gui, DOC:Show, x%DOCWinX% y%DOCWinY% w680 h600, %APP_FULL_TITLE%

    Sleep, 100
    WinSetTitle, ahk_id %DOC_Hwnd%,, %APP_FULL_TITLE%
}

DOC_GetSidebarAttachedGuiPos(guiW, guiH, ByRef outX, ByRef outY)
{
    global SSOK_SidebarHwnd, SSOK_SidebarMiniHwnd, SSOK_SidebarSavedY

    SysGet, DOC_AttachWork, MonitorWorkArea
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
        sideX := DOC_AttachWorkRight - sideW
        if (SSOK_SidebarSavedY != "")
            sideY := SSOK_SidebarSavedY
        else
            sideY := DOC_AttachWorkTop + 76
    }

    outX := sideX - guiW - gap
    if (outX < DOC_AttachWorkLeft)
        outX := sideX + sideW + gap
    if (outX + guiW > DOC_AttachWorkRight)
        outX := DOC_AttachWorkRight - guiW
    if (outX < DOC_AttachWorkLeft)
        outX := DOC_AttachWorkLeft

    outY := sideY
    if (outY + guiH > DOC_AttachWorkBottom)
        outY := DOC_AttachWorkBottom - guiH
    if (outY < DOC_AttachWorkTop)
        outY := DOC_AttachWorkTop
}

; =========================================================
; Á¦¸ñ ¹öÆ° ´­·¶À» ¶§ ¾Æ¹« µ¿ÀÛ ¾È ÇÔ
; =========================================================
DOC_TitleNoop:
return


; =========================================================
; GUI ´Ý±â
; ±âº» X ¹öÆ°, ESC ¸ðµÎ ´ÝÈû
; =========================================================
DOCGuiClose:
DOCGuiEscape:
    Gui, DOC:Destroy
return


; =========================================================
; GUI ¹öÆ°
; =========================================================
GUI_GoodsGeneral:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_GoodsGeneral())
return

GUI_Supplies:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_Supplies())
return

GUI_Book:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_Book())
return

GUI_Album:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_Album())
return

GUI_CareSnack:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_CareSnack())
return

GUI_Furniture:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_Furniture())
return

GUI_OldGoodsImprove:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_OldGoodsImprove())
return

GUI_SchoolMeal:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_SchoolMeal())
return

GUI_ServiceGeneral:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_ServiceGeneral())
return

GUI_FieldTripBus:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_FieldTripBus())
return

GUI_SchoolTrip:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_SchoolTrip())
return

GUI_AfterSchool:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_AfterSchool())
return

GUI_SchoolBus:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_SchoolBus())
return

GUI_CleaningService:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_CleaningService())
return

GUI_Construction:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_Construction())
return

GUI_Budget1:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_BudgetItem(1))
return

GUI_Budget2:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_BudgetItem(2))
return

GUI_Budget3:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_BudgetItem(3))
return

GUI_Budget4:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_BudgetItem(4))
return

GUI_Budget5:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_BudgetItem(5))
return

GUI_OtherGift:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_OtherGift())
return

GUI_OtherCard:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_OtherCard())
return

GUI_MeetingFee:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_MeetingFee())
return
GUI_LecturerFee:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_LecturerFee())
return

GUI_TravelFee:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_TravelFee())
return

GUI_RevenueCollect:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_RevenueCollect())
return

GUI_RevenueFieldTrip:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_RevenuePlaceholder(2))
return

GUI_RevenueSettlement:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_RevenuePlaceholder(5))
return

GUI_RevenueRefundBeneficiary:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_RevenueRefundBeneficiary())
return

GUI_RevenueInterest:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_RevenueInterest())
return

GUI_RevenueTransfer:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_RevenueTransfer())
return

GUI_RevenueRefundPurpose:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_RevenueRefund())
return

GUI_GeneralPlan:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_GeneralPlan())
return

GUI_GeneralEventNotice:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_GeneralEventNotice())
return

GUI_NationalPetition:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_NationalPetition())
return

GUI_SchoolMarket:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_SchoolMarket())
return

GUI_LegalBasis:
    Gui, DOC:Destroy
    DOC_PasteTemplate(TPL_LegalBasis())
return


; =========================================================
; ºó ¹®¼­ Win+F2 ¸Þ´º Ç¥½Ã¿ë ÀÓ½Ã ¸¶Ä§Ç¥ »èÁ¦
; =========================================================
DOC_ClearTempDotBeforeTemplatePaste()
{
    global DOC_TempDotInserted, TargetHwnd

    if (!DOC_TempDotInserted)
        return

    if (TargetHwnd != "")
    {
        WinActivate, ahk_id %TargetHwnd%
        Sleep, 120
    }

    ; ºó ¹®¼­¿¡¼­ ¸Þ´º¸¦ ¶ç¿ì±â À§ÇØ ÀÓ½Ã·Î ÀÔ·ÂÇÑ . ¸¸ Á¦°ÅÇÕ´Ï´Ù.
    ; ÀÌ »óÅÂÀÇ ¹®¼­´Â ¿ø·¡ °ø¶õÀÌ¹Ç·Î ÀüÃ¼¼±ÅÃ ÈÄ »èÁ¦ÇØµµ ±âÁ¸ ³»¿ë ¼Õ»óÀÌ ¾ø½À´Ï´Ù.
    Send, ^a
    Sleep, 100
    Send, {Backspace}
    Sleep, 120

    DOC_TempDotInserted := false
}


; =========================================================
; ÅÛÇÃ¸´ ºÙ¿©³Ö±â
; =========================================================
DOC_PasteTemplate(template)
{
    global SavedClip, TargetHwnd

    template := DOC_ApplyOrgNameToTemplate(template)

    DOC_ClearTempDotBeforeTemplatePaste()
    ; ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    ; [2026-05-11 º¸Á¤] HWP À¥±â¾È±â ºó ¹®¼­ ÅÛÇÃ¸´ ºÙ¿©³Ö±â ¼­½Ä Èçµé¸² ¹æÁö
    ; Áõ»ó: À¥±â¾È±â¿¡¼­ ºó »óÅÂ·Î Win+F2 ¡æ ÅÛÇÃ¸´ ¼±ÅÃ ¡æ ºÙ¿©³Ö±â ½Ã
    ;       HY½Å¸íÁ¶ 10À¸·Î µé¾î°¡°í, »ç¿ëÀÚ°¡ ¸ÕÀú °ø¹é 1Ä­À» ÀÔ·ÂÇÑ µÚ
    ;       ½ÇÇàÇÏ¸é ±¼¸² 12·Î µé¾î°¡´Â Çö»ó.
    ; ¿øÀÎ: ºó ÆíÁý ¿µ¿ª¿¡¼­´Â À¥±â¾È±â ±âº» ¼­½ÄÀ» »ó¼ÓÇÔ.
    ; ÇØ°á: »ç¿ëÀÚ°¡ Á÷Á¢ °ø¹éÀ» ³Ö´ø µ¿ÀÛÀ» ÀÚµ¿È­ÇÔ.
    ;       °ø¹é 1Ä­ ÀÔ·Â ¡æ ÀüÃ¼¼±ÅÃ ¡æ ÅÛÇÃ¸´ ºÙ¿©³Ö±â ¼ø¼­·Î Ã³¸®ÇÏ¿©
    ;       ÅÛÇÃ¸´ ³»¿ëÀº ³²±â°í °ø¹éÀº µ¤¾î¾¹´Ï´Ù.
    ; ÁÖÀÇ: ´Ù¸¥ ±â´ÉÀº °Çµå¸®Áö ¾Ê°í, ÅÛÇÃ¸´ ºÙ¿©³Ö±â °æ·Î¸¸ º¸Á¤ÇÕ´Ï´Ù.
    ; ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    if (DOC_IsHwpOrWebEditor())
    {
        if (TargetHwnd != "")
        {
            WinActivate, ahk_id %TargetHwnd%
            Sleep, 150
        }

        Send, ^{End}
        Sleep, 80
        Send, {Space}
        Sleep, 120
        Send, ^a
        Sleep, 120

        text := DOC_FixAttachGapForHwp(template)
        text := DOC_NormalizeClipboardLineBreaks(text)

        if (!DOC_SetClipboardTextForEditor(text))
        {
            Clipboard := SavedClip
            MsgBox, 48, SSOK ¾È³», ÅÛÇÃ¸´À» Å¬¸³º¸µå¿¡ ´ãÁö ¸øÇØ ºÙ¿©³Ö±â¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
            return
        }
        Send, ^v
        Sleep, 180

        Clipboard := SavedClip
        return
    }

    ; ÀÏ¹Ý ÆíÁý±â/¸Þ¸ðÀå/ºê¶ó¿ìÀú ÀÏ¹Ý ÀÔ·ÂÃ¢Àº ±âÁ¸ ¹æ½Ä ±×´ë·Î À¯Áö
    if (!DOC_OutputText(template, true))
    {
        Clipboard := SavedClip
        MsgBox, 48, SSOK ¾È³», ÅÛÇÃ¸´À» Å¬¸³º¸µå¿¡ ´ãÁö ¸øÇØ ºÙ¿©³Ö±â¸¦ Áß´ÜÇß½À´Ï´Ù.`nÀá½Ã ÈÄ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
        return
    }
    Sleep, 150
    Clipboard := SavedClip
}


DOC_ApplyOrgNameToTemplate(template)
{
    org := DOC_GetOrgName()
    if (org = "")
        org := "µµ´ãÁß"

    template := StrReplace(template, "OOÇÐ±³-OOOO", org . "-0000")
    template := StrReplace(template, "OOÇÐ±³-0000", org . "-0000")
    template := StrReplace(template, "OOÇÐ±³-¡Û¡Û¡Û¡Û", org . "-0000")
    template := StrReplace(template, "OOÇÐ±³-¡Û¡Û", org . "-0000")
    template := StrReplace(template, "¡Û¡ÛÇÐ±³-OOOO", org . "-0000")
    template := StrReplace(template, "¡Û¡ÛÇÐ±³-0000", org . "-0000")
    template := StrReplace(template, "¡Û¡ÛÇÐ±³-¡Û¡Û¡Û¡Û", org . "-0000")
    template := StrReplace(template, "¡Û¡ÛÇÐ±³-¡Û¡Û", org . "-0000")
    template := StrReplace(template, "00ÇÐ±³-OOOO", org . "-0000")
    template := StrReplace(template, "00ÇÐ±³-0000", org . "-0000")
    template := StrReplace(template, "OOÇÐ±³", org)
    template := StrReplace(template, "¡Û¡ÛÇÐ±³", org)
    template := StrReplace(template, "00ÇÐ±³", org)
    return template
}
DOC_GetOrgName()
{
    IniRead, DOC_OrgNameValue, %A_ScriptDir%\ssok.ini, MajorTodos, OrgName, µµ´ãÁß
    DOC_OrgNameValue := Trim(DOC_OrgNameValue)
    if (DOC_OrgNameValue = "")
        DOC_OrgNameValue := "µµ´ãÁß"
    return DOC_OrgNameValue
}
; =========================================================
; ³¯Â¥ °ü·Ã ÇÔ¼ö
; =========================================================
GetYear()
{
    FormatTime, y, %A_Now%, yyyy
    return y
}

GetMonth()
{
    FormatTime, m, %A_Now%, M
    return m
}

GetSchoolYear()
{
    ; 3¿ù ±âÁØ ÇÐ³âµµ: 1~2¿ùÀº Àü³âµµ ÇÐ³âµµ
    FormatTime, y, %A_Now%, yyyy
    FormatTime, m, %A_Now%, M
    if (m + 0 < 3)
        y := y - 1
    return y
}

GetDueDate()
{
    FormatTime, y, %A_Now%, yyyy
    FormatTime, m, %A_Now%, M
    FormatTime, d, %A_Now%, d

    m := m + 1
    if (m > 12)
    {
        m := 1
        y := y + 1
    }

    lastDay := DOC_LastDayOfMonth(y, m)
    if (d > lastDay)
        d := lastDay

    return FormatYmdWithWeekday(BuildDateValue(y, m, d)) . "±îÁö"
}

DOC_LastDayOfMonth(y, m)
{
    if (m = 2)
        return DOC_IsLeapYear(y) ? 29 : 28
    if (m = 4 || m = 6 || m = 9 || m = 11)
        return 30
    return 31
}

DOC_IsLeapYear(y)
{
    return (Mod(y, 400) = 0 || (Mod(y, 4) = 0 && Mod(y, 100) != 0))
}

GetAfterDays(daysToAdd)
{
    d := A_Now
    EnvAdd, d, %daysToAdd%, Days
    return FormatYmdWithWeekday(d)
}

FormatYmdWithWeekday(dateValue)
{
    FormatTime, y, %dateValue%, yyyy
    FormatTime, m, %dateValue%, M
    FormatTime, d, %dateValue%, d
    FormatTime, wd, %dateValue%, WDay

    days := ["ÀÏ","¿ù","È­","¼ö","¸ñ","±Ý","Åä"]
    return y . ". " . m . ". " . d . ".(" . days[wd] . ")"
}

FormatDateRangeWithWeekdays(startValue, endValue, totalDays := "")
{
    FormatTime, sy, %startValue%, yyyy
    FormatTime, ey, %endValue%, yyyy
    FormatTime, em, %endValue%, M
    FormatTime, ed, %endValue%, d
    FormatTime, ewd, %endValue%, WDay

    days := ["ÀÏ","¿ù","È­","¼ö","¸ñ","±Ý","Åä"]
    startText := FormatYmdWithWeekday(startValue)

    if (sy = ey)
        endText := em . ". " . ed . ".(" . days[ewd] . ")"
    else
        endText := FormatYmdWithWeekday(endValue)

    result := startText . "~" . endText
    if (totalDays != "")
        result .= ", " . AddComma(totalDays) . "ÀÏ°£"

    return result
}

BuildDateValue(y, m, d)
{
    m := m + 0
    d := d + 0

    if (m < 1 || m > 12 || d < 1 || d > 31)
        return ""

    if (m < 10)
        m := "0" . m
    if (d < 10)
        d := "0" . d

    return y . m . d . "000000"
}


; =========================================================
; ÅÛÇÃ¸´
; =========================================================
TPL_GoodsGeneral()
{
    y := GetYear()
    sy := GetSchoolYear()
    due := GetDueDate()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¡Û¡Û ¿î¿µ¹°Ç° ±¸ÀÔ
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ ¡Û¡Û ¿î¿µ °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ ¡Û¡Û ¿î¿µ¿¡ ÇÊ¿äÇÑ ¹°Ç°À» ´ÙÀ½°ú °°ÀÌ ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ±¸ÀÔ³»¿ª: ¡Û¡Û¡Û ¿Ü ¡ÛÁ¾
  ³ª. ¼Ò¿ä¿¹»ê: ±Ý¡Û¿ø

ºÙÀÓ  ÁöÃâÇ°ÀÇ¼­ 1ºÎ.  ³¡.

)
    return template
}

TPL_Supplies()
{
    y := GetYear()
    sy := GetSchoolYear()
    due := GetDueDate()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ÇÐ½ÀÁØºñ¹° ±¸ÀÔ
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ ÇÐ½ÀÁØºñ¹° ±¸ÀÔ °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ ÇÐ½ÀÁØºñ¹°À» ´ÙÀ½°ú °°ÀÌ ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ±¸ÀÔ³»¿ª: µµÈ­Áö ¿Ü O¿©Á¾
  ³ª. ¼Ò¿ä¿¹»ê: ±Ý¡Û¿ø
  ´Ù. ³³Ç°±âÇÑ: %due%
  * ÇÊ¿ä½Ã ¾Æ·¡ ¹®±¸ Ãß°¡ÇÏ¿© È°¿ë
  ¶ó. ±¸ÀÔ¹æ¹ý: Ä«µå°áÁ¦ / °èÁÂÀÌÃ¼ / ³ª¶óÀåÅÍ / S2B
    ¡Ø ÇÐ±³ ÀÎ±Ù¹®±¸Á¡ ±¸ÀÔ ¿äÃ»

ºÙÀÓ  1. ÇÐ½ÀÁØºñ¹° ¸ñ·Ï 1ºÎ.
      2. °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
      3. °ßÀû¼­ 1ºÎ.
      4. 1ÀÎ¼öÀÇ°è¾à ¿äÃ» »çÀ¯¼­ 1ºÎ.
      5. »ç¾÷ÀÚµî·ÏÁõ 1ºÎ.  ³¡.

* °ßÀû¼­ Ã·ºÎ ½Ã 1ÀÎ¼öÀÇ°è¾à ¿äÃ» »çÀ¯¼­ 1ºÎ ÇÊ¼ö

)
    return template
}

TPL_Book()
{
    y := GetYear()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ µµ¼­°ü µµ¼­ ±¸ÀÔ
1. °ü·Ã
  °¡. ¡¸ÃâÆÇ¹®È­»ê¾÷ ÁøÈï¹ý¡¹ Á¦22Á¶Á¦5Ç×(°£Çà¹° Á¤°¡ Ç¥½Ã ¹× ÆÇ¸Å)
  ³ª. OOÇÐ±³-OOOO(%y%. 0. 0.) µµ¼­¼±Á¤À§¿øÈ¸ È¸ÀÇ °á°ú
2. ÇÐ»ý µ¶¼­±³À°È°µ¿À» À§ÇÑ µµ¼­¸¦ ´ÙÀ½°ú °°ÀÌ ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. µµ¼­¸ñ·Ï: ¡Û ¿Ü ¡ÛÁ¾
  ³ª. ¼Ò¿ä¿¹»ê: ±Ý ¿ø
    ¡Ø µµ¼­ Á¤°¡·Î Ç°ÀÇ

ºÙÀÓ  µµ¼­ ¸ñ·Ï 1ºÎ.  ³¡.
)
    return template
}

TPL_Album()
{
    y := GetYear()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ Á¹¾÷¾Ù¹ü ±¸ÀÔ
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ Á¹¾÷¾Ù¹ü ±¸ÀÔ °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ Á¹¾÷¾Ù¹üÀ» ´ÙÀ½°ú °°ÀÌ ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. Ç°¸í: Á¹¾÷¾Ù¹ü
  ³ª. ±¸¸Å³»¿ª
    1) ÇÐ»ý: ¡Û¡Û¿ø*¡ÛºÎ(¼öÀÍÀÚ ¡Û¸í, Áö¿ø±Ý ¡Û¸í)
    2) º¸°ü¿ë: ¡Û¡Û¿ø*3ºÎ
  ¶ó. ¼Ò¿ä¿¹»ê: ±Ý¡Û¿ø

ºÙÀÓ  1. Á¹¾÷¾Ù¹ü ±¸ÀÔ °èÈ¹ 1ºÎ.
      2. °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_CareSnack()
{
    y := GetYear()
    sy := GetSchoolYear()
    nextY := y + 1

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ µ¹º½±³½Ç °£½Ä ±¸ÀÔ °è¾à ¿ä±¸
1. °ü·Ã: ¡Û¡ÛÇÐ±³-0000(%y%. 0. 0.) %sy%ÇÐ³âµµ µ¹º½±³½Ç ¿î¿µ°èÈ¹
2. %sy%ÇÐ³âµµ µ¹º½±³½Ç °£½Ä ±¸ÀÔÀ» ¾Æ·¡¿Í °°ÀÌ °è¾à ¿ä±¸ÇÕ´Ï´Ù.
  °¡. ¿î¿µ±â°£: %y%. 3. 1.~%nextY%. 2. 28.
  ³ª. ¿î¿µÀÏ¼ö: ÇÐ±âÁß ¡Û¡ÛÀÏ, ¹æÇÐ ¡Û¡ÛÀÏ
  ´Ù. ¿¹»óÀÎ¿ø: µ¹º½±³½Ç ¡Û½Ç ¡Û¡Û¸í
  ¶ó. ¿¹»ó´Ü°¡: ±Ý ¿ø
  ¸¶. ¼Ò¿ä¿¹»ê: ±Ý ¿ø
  ¹Ù. »êÃâ±âÃÊ: 1,500¿ø*¡Û¡Û¸í*¡Û¡ÛÀÏ

ºÙÀÓ  1. %sy%ÇÐ³âµµ µ¹º½±³½Ç ¿î¿µ °èÈ¹ 1ºÎ.
      2. °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_Furniture()
{
    y := GetYear()
    sy := GetSchoolYear()
    due := GetDueDate()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¡Û¡Û½Ç ºñÇ° ±¸ÀÔ
1. °ü·Ã: ¡Û¡ÛÇÐ±³-¡Û¡Û¡Û¡Û(%y%. 0. 0.) ¡Û¡ÛÇÐ±³ ¹°Ç°¼±Á¤À§¿øÈ¸ È¸ÀÇ °á°ú
  °¡. (¿¹½Ã) ¡¸ÇÐ±³½Ã¼³ µîÀÇ ¾ÈÀü ¹× À¯Áö°ü¸® µî¿¡ °üÇÑ ¹ý·ü¡¹ 
2. ¡Û¡Û½Ç ¿î¿µ¿¡ ÇÊ¿äÇÑ ºñÇ°À» ¹°Ç°¼±Á¤À§¿øÈ¸ ¼±Á¤ °á°ú¿¡ µû¶ó ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ±¸ÀÔ¸ñ·Ï: ¡Û¡Û¡Û¡Û¡Û ¿Ü ¡ÛÁ¾
  ³ª. ¿¹»ó±Ý¾×: ±Ý ¿ø
  ´Ù. ±¸ÀÔ¹æ¹ý: ³ª¶óÀåÅÍ / S2B
  ¶ó. ³³Ç°±âÇÑ: %due%
  * ³ª¶óÀåÅÍ ¸ñ·ÏÁ¤º¸½Ã½ºÅÛ(https://goods.g2b.go.kr/) ¿¡¼­ Á¦Ç° µî·Ï¿©ºÎ ¹× ³»¿ë¿¬¼ö È®ÀÎ ÈÄ ±¸¸Å(ÇàÁ¤½Ç ¹®ÀÇ)

ºÙÀÓ  ±¸¸Å³»¿ª¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_OldGoodsImprove()
{
    y := GetYear()
    sy := GetSchoolYear()
    due := GetDueDate()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¡Û¡Û½Ç ³ëÈÄÈ­ È¯°æ°³¼± ¹°Ç° ±¸ÀÔ
1. °ü·Ã
  °¡. ¡¸ÇÐ±³½Ã¼³ µîÀÇ ¾ÈÀü ¹× À¯Áö°ü¸® µî¿¡ °üÇÑ ¹ý·ü¡¹ 
  ³ª. ¡¸ÇÐ±³º¸°Ç¹ý¡¹ Á¦4Á¶(ÇÐ±³ÀÇ È¯°æÀ§»ý ¹× ½ÄÇ°À§»ý)
  ³ª. OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ ³ëÈÄÈ­ È¯°æ°³¼± °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ ¡Û¡Û½Ç ³ëÈÄÈ­ È¯°æ°³¼±¿¡ ÇÊ¿äÇÑ ¹°Ç°À» ºÙÀÓ°ú °°ÀÌ ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ¸ñÀû:
  ³ª. »ç¾÷¸í: %sy%ÇÐ³âµµ ¡Û¡Û½Ç ³ëÈÄÈ­ È¯°æ°³¼±
  ´Ù. ±¸ÀÔ³»¿ª: ¡Û¡Û¡Û¡Û¡Û ¿Ü ¡ÛÁ¾
  ¶ó. ¼Ò¿ä¿¹»ê: ±Ý ¿ø
  ¸¶. ³³Ç°±âÇÑ: %due%

ºÙÀÓ  %sy%ÇÐ³âµµ ¡Û¡Û½Ç ³ëÈÄÈ­ È¯°æ°³¼± °èÈ¹ 1ºÎ.  ³¡.
)
    return template
}

TPL_SchoolMeal()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %y%³â %m%¿ù ÇÐ±³±Þ½Ä ½ÄÀç·á Ç°ÀÇ
1. °ü·Ã:
  °¡. ¡¸¼¼Á¾Æ¯º°ÀÚÄ¡½Ã Áö¿ª³ó»ê¹° °ø°ø±Þ½Ä Áö¿ø¿¡ °üÇÑ Á¶·Ê¡¹ Á¦26Á¶
  ³ª. ¡¸Áö¹æ°è¾à¹ý ½ÃÇà·É¡¹ Á¦25Á¶1Ç×3È£ ¹× Á¦50Á¶1Ç×4È£.
  ´Ù. ±³À°º¹Áö°ú-1702(%y%.1.27.) ¡¸%sy%ÇÐ³âµµ ÇÐ±³±Þ½Ä ±âº» ¿î¿µ °èÈ¹ ¾Ë¸²¡¹
2. %y%³â %m%¿ù ÇÐ±³±Þ½Ä ½ÄÀç·á¸¦ ´ÙÀ½°ú °°ÀÌ ±¸¸ÅÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ±â°£: %y%. %m%. 1.~%m%. 30.(OÀÏ°£)
  ³ª. Ç°¸ñ: O ¿Ü OÁ¾
  ´Ù. ±Ý¾×: ±Ý ¿ø
  ¶ó. ¹æ¹ý: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã °ø°ø±Þ½ÄÁö¿ø¼¾ÅÍ¿Í ¼öÀÇ°è¾à

ºÙÀÓ  1. ±¸¸Å°èÈ¹¼­ 1ºÎ.
      2. ±¸¸Å°èÈ¹¼­ 1ºÎ.   ³¡.
)
    return template
}
TPL_ServiceGeneral()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ±³³» ¡Û¡Û Çà»ç ¿ë¿ª ½Ç½Ã
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ ¡Û¡Û Çà»ç °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ ±³³» ¡Û¡Û Çà»ç ¿ë¿ªÀ» ´ÙÀ½°ú °°ÀÌ ½Ç½ÃÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ¸ñÀû:
  ³ª. ¿ë¿ª¸í: ±³³» ¡Û¡Û Çà»ç ¿ë¿ª
  ´Ù. ±â°£: %y%. %m%. ¡Û.~%m%. ¡Û.(¡ÛÀÏ°£)
  ¶ó. Àå¼Ò:
  ¸¶. ³»¿ë:
  ¹Ù. ¼Ò¿ä¿¹»ê: ±Ý ¿ø
    - »êÃâ³»¿ª: ¡Û¿ø*¡Û¸í=
  »ç. °è¾à¹æ¹ý: Ä«µå°áÁ¦ / °èÁÂÀÌÃ¼ / ³ª¶óÀåÅÍ / S2B

ºÙÀÓ  °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_FieldTripBus()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¡ÛÇÐ±â ÇöÀåÃ¼ÇèÇÐ½À Â÷·® ÀÓÂ÷ °è¾à ÀÇ·Ú
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ ÇöÀåÃ¼ÇèÇÐ½À °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ ¡ÛÇÐ±â ÇöÀåÃ¼ÇèÇÐ½À È°µ¿À» À§ÇÑ Â÷·®À» ´ÙÀ½°ú °°ÀÌ ÀÓÂ÷ÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ÀÏ½Ã: %y%. %m%. 00.~%m%. 00.(¡ÛÀÏ°£)
  ³ª. Àå¼Ò: ¡Û¡ÛÀÏ¿ø
  ´Ù. ´ë»ó: ÃÑ ¡Û¡Û¸í(ÇÐ»ý ¡Û¡Û¸í, ±³¿ø ¡Û¡Û¸í)
  ¶ó. ¼Ò¿ä¿¹»ê: ±Ý¡Û¿ø
    - »êÃâ³»¿ª:  ¡Û¡Û¿ø* ¡Û¡Û´ë(45ÀÎ½Â)
  ¸¶. °è¾à¹æ¹ý: ³ª¶óÀåÅÍ / S2B / ¼öÀÇ°è¾à

ºÙÀÓ  1. »ç¾÷ °èÈ¹ 1ºÎ.
      2. °ú¾÷Áö½Ã¼­(È¤Àº Æ¯¼öÁ¶°Ç) 1ºÎ.  ³¡.
)
    return template
}

TPL_SchoolTrip()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¼öÇÐ¿©Çà À§Å¹¿ë¿ª °è¾à ¿äÃ»
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ ¼öÇÐ¿©Çà °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ ¼öÇÐ¿©Çà À§Å¹¿ë¿ªÀ» ´ÙÀ½°ú °°ÀÌ °è¾à ¿äÃ»ÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. °Ç¸í: %sy%ÇÐ³âµµ ¼öÇÐ¿©Çà À§Å¹¿ë¿ª
  ³ª. ¿ë¿ª±â°£: %y%. %m%. ¡Û.~%m%. ¡Û.(¡ÛÀÏ°£)
  ´Ù. Àå¼Ò: ¡Û¡ÛÀÏ¿ø
  ¶ó. Âü°¡ÀÎ¿ø: ÃÑ ¡Û¡Û¸í(ÇÐ»ý ¡Û¡Û¸í, ±³¿ø ¡Û¡Û¸í)
  ¸¶. ÃßÁ¤±Ý¾×: ±Ý ¿ø
  ¹Ù. ¿ë¿ª³»¿ë: ºÙÀÓ °èÈ¹¼­¿Í °°À½

ºÙÀÓ  1. »ç¾÷ °èÈ¹ 1ºÎ.
      2. °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_AfterSchool()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¹æ°úÈÄÇÐ±³ ÇÁ·Î±×·¥ À§Å¹¿î¿µ ¿ë¿ª °è¾à ¿äÃ»
1. °ü·Ã: ¡Û¡ÛÇÐ±³-0000(%y%. . .), ¡¸%sy%ÇÐ³âµµ ¹æ°úÈÄÇÐ±³ ¿î¿µ°èÈ¹ ¼ö¸³¡¹
2. %sy%ÇÐ³âµµ ¹æ°úÈÄÇÐ±³ ÇÁ·Î±×·¥ À§Å¹¿î¿µ ¿ë¿ª °è¾àÀ» ºÙÀÓ°ú °°ÀÌ ¿äÃ»ÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. °Ç¸í: %sy%ÇÐ³âµµ ¹æ°úÈÄÇÐ±³ ÇÁ·Î±×·¥ À§Å¹¿î¿µ ¿ë¿ª
  ³ª. ¿ë¿ª³»¿ª: ¡Û ¿Ü ¡Û Á¾ ·Î±×·¥ ¿î¿µ
  ´Ù. ¿ë¿ª±â°£: %y%. %m%. ¡Û.~%m%. ¡Û.(¡ÛÀÏ°£)
  ¶ó. ÃßÁ¤±Ý¾×: ±Ý ¿ø

ºÙÀÓ  1. »ç¾÷ °èÈ¹ 1ºÎ.
      2. °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_SchoolBus()
{
    y := GetYear()
    sy := GetSchoolYear()
    nextY := y + 1

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ÅëÇÐ¹ö½º Â÷·® ÀÓÂ÷ ¿äÃ»
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ ÅëÇÐ¹ö½º ¿î¿µ °èÈ¹ ¼ö¸³
2. º»±³ ÇÐ»ýµéÀÇ ¾ÈÀüÇÑ µîÇÏ±³ Áö¿øÀ» À§ÇÏ¿© %sy%ÇÐ³âµµ ÅëÇÐ¹ö½º Â÷·®À» ÀÓÂ÷ÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ¸ñÀû:
  ³ª. ¿îÇà±â°£: %y%. 3. 1.~%nextY%. 2. 28. (¿îÇàÀÏ¼ö: 190ÀÏ)
  ´Ù. ½ÂÂ÷¿¹Á¤ÀÎ¿ø: ¡Û¡Û¸í
  ¶ó. ¿îÇà´ë¼ö: ¡Û´ë(45ÀÎ½Â)
  ¸¶. ¿¹»ó±Ý¾×: ±Ý ¿ø
    - »êÃâ³»¿ª: ¡Û¿ø*190ÀÏ*¡Û´ë
  ¹Ù. °è¾à¹æ¹ý: ³ª¶óÀåÅÍ / S2B / ¼öÀÇ°è¾à

ºÙÀÓ  1. »ç¾÷ °èÈ¹ 1ºÎ.
      2. °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_CleaningService()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ½ÅÇÐ±â ´ëºñ Ã»¼Ò¿ë¿ª ½Ç½Ã
1. °ü·Ã: OOÇÐ±³-OOOO(%y%. 0. 0.) %sy%ÇÐ³âµµ Ã»¼Ò¿ë¿ª °èÈ¹ ¼ö¸³
2. %sy%ÇÐ³âµµ ½ÅÇÐ±â ´ëºñ ±³³» Ã»¼Ò¿ë¿ªÀ» ´ÙÀ½°ú °°ÀÌ ½Ç½ÃÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ¸ñÀû:
  ³ª. ÀÏ½Ã: %y%. %m%. ¡Û.~%m%. ¡Û.(¡ÛÀÏ°£)
  ´Ù. Ã»¼Ò±¸¿ª: ¡Û µî ÃÑ ¡Û½Ç
  ¶ó. Ã»¼Ò³»¿ë: ¹Ù´Ú ¹°, ¿Î½º, ÃµÀå, À¯¸® µî
  ¸¶. ¿¹»ó±Ý¾×: ±Ý ¿ø
  ¹Ù. °è¾à¹æ¹ý: Ä«µå°áÁ¦ / °èÁÂÀÌÃ¼ / ³ª¶óÀåÅÍ / S2B

ºÙÀÓ  1. »ç¾÷ °èÈ¹ 1ºÎ.
      2. °ú¾÷Áö½Ã¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_Construction()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: ÇÐ»ý ¡Û¡Û °ø°£ È¯°æ ±¸¼º °ø»ç ½ÃÇà
1. °ü·Ã: ¡Û¡ÛÇÐ±³-¡Û¡Û(%y%. . .)
2. %sy%ÇÐ³âµµ ¡Û¡Û°ø°£ »ç¾÷°èÈ¹À» ºÙÀÓ°ú °°ÀÌ ¼ö¸³ÇÏ¿© ÁýÇàÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ¸ñÀû:
  ³ª. °ø»ç¸í: ÇÐ»ý ¡Û¡Û °ø°£ È¯°æ ±¸¼º
  ´Ù. °ø»çÀå¼Ò:
  ¶ó. »ç¾÷±â°£: %y%. %m%. ¡Û.~%m%. ¡Û.
  ¸¶. »ç¾÷¿¹»ê: ±Ý ¿ø

ºÙÀÓ  1. ¡Û¡Û »ç¾÷°èÈ¹¼­ 1ºÎ.
      2. °ø»ç½Ã¹æ¼­(µµ¸é Æ÷ÇÔ) 1ºÎ.
      3. »êÃâ³»¿ª¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_BudgetItem(itemNo)
{
    if (itemNo = 1)
        return TPL_BudgetRequest()
    if (itemNo = 2)
        return TPL_BudgetSupplementary()
    if (itemNo = 3)
        return TPL_BudgetPurposeFund()
    if (itemNo = 4)
        return TPL_BudgetBeneficiaryFund()
    return TPL_BudgetSubjectChange()
}

TPL_BudgetRequest()
{
    y := GetYear()
    sy := GetSchoolYear()
    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ º»¿¹»ê ¿ä±¸¼­ Á¦Ãâ

1. °ü·Ã: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã °ø¸³ÇÐ±³È¸°è ±ÔÄ¢ Á¦12Á¶(¿¹»ê¾ÈÀÇ Æí¼º)
2. %sy%ÇÐ³âµµ º»¿¹»ê ¿ä±¸¼­¸¦ ºÙÀÓ°ú °°ÀÌ Á¦ÃâÇÏ°íÀÚ ÇÕ´Ï´Ù.
   ºÙÀÓ  º»¿¹»ê ¿ä±¸¼­(¡ÛºÎ-°úÇÐ½Ç¿î¿µ) 1ºÎ.  ³¡.

¡Ø °áÀç¼± ÁöÁ¤½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¿¹»ê´ã´çÀÚ) ÇùÁ¶ ¶Ç´Â ÇÊ¼ö °ø¶÷ ÁöÁ¤
)
    return template
}

TPL_BudgetSupplementary()
{
    y := GetYear()
    sy := GetSchoolYear()
    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ Á¦¡ÛÈ¸ ÇÐ±³È¸°è Ãß°¡°æÁ¤¿¹»ê ¿ä±¸¼­ Á¦Ãâ

1. °ü·Ã
   °¡. ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã °ø¸³ÇÐ±³È¸°è ±ÔÄ¢ Á¦15Á¶
   ³ª. ÇÐ±³ ÀÚÃ¼ Ãß°¡°æÁ¤¿¹»ê Æí¼º °èÈ¹
2. ¿¹»êÀÇ ¸ñÀû(»ç¾÷)º¯°æ µîÀÇ »çÀ¯°¡ ¹ß»ýÇÏ¿© ºÙÀÓ°ú °°ÀÌ ¡ÛºÎÀÇ Ãß°¡°æÁ¤¿¹»ê ¿ä±¸¼­¸¦ Á¦ÃâÇÕ´Ï´Ù.

ºÙÀÓ  Ãß°¡°æÁ¤¿¹»ê ¿ä±¸¼­ 1ºÎ.  ³¡.

¡Ø °áÀç¼± ÁöÁ¤½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¿¹»ê´ã´çÀÚ) ÇùÁ¶ ¶Ç´Â ÇÊ¼ö °ø¶÷ ÁöÁ¤
)
    return template
}

TPL_BudgetPurposeFund()
{
    y := GetYear()
    sy := GetSchoolYear()
    template =
(
Á¦¸ñ: ¡Û¡Û ¿î¿µºñ ¼º¸³Àü¿¹»ê »ç¿ë ¿ä±¸

1. °ü·Ã
   °¡. ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã °ø¸³ÇÐ±³È¸°è ±ÔÄ¢ Á¦12Á¶(¿¹»ê¾ÈÀÇ Æí¼º)
   ³ª. %sy%ÇÐ³âµµ ¡Û¡Û ¿î¿µ ¿¹»ê ±³ºÎ (00°ú-0000, %y%.00.00.)
2. µðÁöÅÐÆ©ÅÍ ¿î¿µ»ç¾÷ ¿¹»êÀÌ ±³ºÎµÊ¿¡ µû¶ó Ãß°¡°æÁ¤¿¹»êÀ» Æí¼ºÇÏ¿© ÁýÇàÇÏ¿©¾ß ÇÏ³ª ½ÃÀÏÀÌ ÃË¹ÚÇÏ°í ¿øÈ°ÇÑ ±³À°°úÁ¤ ¿î¿µÀ» À§ÇØ ºÙÀÓ°ú °°ÀÌ ¼º¸³Àü¿¹»êÀ¸·Î »ç¿ëÇÏ°íÀÚ ÇÕ´Ï´Ù.

ºÙÀÓ  ¼º¸³Àü¿¹»ê »ç¿ë ¿ä±¸¼­ 1ºÎ.  ³¡.

¡Ø °áÀç¼± ÁöÁ¤½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¿¹»ê´ã´çÀÚ) ÇùÁ¶ ¶Ç´Â ÇÊ¼ö °ø¶÷ ÁöÁ¤
)
    return template
}

TPL_BudgetBeneficiaryFund()
{
    y := GetYear()
    sy := GetSchoolYear()
    template =
(
Á¦¸ñ: ÇöÀåÃ¼ÇèÇÐ½À ¿î¿µ ¼º¸³Àü¿¹»ê »ç¿ë ¿ä±¸

1. °ü·Ã
   °¡. ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã °ø¸³ÇÐ±³È¸°è ±ÔÄ¢ Á¦12Á¶(¿¹»ê¾ÈÀÇ Æí¼º)
   ³ª. %sy%ÇÐ³âµµ ÇöÀåÃ¼ÇèÇÐ½À ¿î¿µ°èÈ¹
   ´Ù. Á¦¡ÛÈ¸ ÇÐ±³¿î¿µÀ§¿øÈ¸ ÀÓ½ÃÈ¸ ½ÉÀÇ°á°ú ÀÌ¼Û
2. ÇöÀåÃ¼ÇèÇÐ½À ¿î¿µ°èÈ¹ÀÌ ÇÐ±³¿î¿µÀ§¿øÈ¸ ½ÉÀÇ¿¡ Åë°úµÇ¾î º»¿¹»êÀ» Æí¼ºÇÏ¿© ÁýÇàÇÏ¿©¾ß ÇÏ³ª ½ÃÀÏÀÌ ÃË¹ÚÇÏ°í ¿øÈ°ÇÑ ±³À°°úÁ¤ ¿î¿µÀ» À§ÇØ ºÙÀÓ°ú °°ÀÌ ¼º¸³Àü¿¹»êÀ¸·Î »ç¿ëÇÏ°íÀÚ ÇÕ´Ï´Ù.

ºÙÀÓ  ¼º¸³Àü¿¹»ê »ç¿ë ¿ä±¸¼­ 1ºÎ.  ³¡.

¡Ø °áÀç¼± ÁöÁ¤½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¿¹»ê´ã´çÀÚ) ÇùÁ¶ ¶Ç´Â ÇÊ¼ö °ø¶÷ ÁöÁ¤
)
    return template
}

TPL_BudgetSubjectChange()
{
    y := GetYear()
    sy := GetSchoolYear()
    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¹æ°úÈÄÇÐ±³ ¿î¿µºñ °ú¸ñ°æÁ¤ ÀÇ·Ú

1. °ü·Ã: ¡Û¡ÛÇÐ±³-000(%y%.00.00.)¡¸%sy%ÇÐ³âµµ ¹æ°úÈÄÇÐ±³ ¿î¿µºñ ÁöÃâ¡¹
2. %sy%ÇÐ³âµµ ¹æ°úÈÄÇÐ±³ ¿î¿µºñ ÁöÃâ °Ç¿¡ ´ëÇØ ´ÙÀ½°ú °°ÀÌ °ú¸ñ°æÁ¤À» ÀÇ·ÚÇÕ´Ï´Ù.
   °¡. °ú¸ñ°æÁ¤ ÀÇ·Ú »çÀ¯: ´çÃÊ ¿¹»ê°ú¸ñÀ¸·Î ÁöÃâÇÏ¿´À¸³ª, »ç¾÷ ¸ñÀû ¹× ÁýÇà³»¿ë °ËÅä °á°ú º¯°æ ÈÄ ¿¹»ê°ú¸ñÀ¸·Î ÁýÇàÇÏ´Â °ÍÀÌ ÀûÁ¤ÇÏ¿© °ú¸ñ°æÁ¤À» ÀÇ·ÚÇÔ
   ³ª. °ú¸ñ°æÁ¤ ¼¼ºÎ³»¿ª

1) »ç¾÷¸í: ¹æ°úÈÄÇÐ±³¿î¿µ
2) º¯°æ Àü ¿¹»ê: ±³¹«ÇÐ»ç¿î¿µ-ÀÔÇÐ½Ä¹°Ç°±¸ÀÔ
3) º¯°æ ÈÄ ¿¹»ê: ¹æ°úÈÄÇÐ±³ ÇÑ½ÃÀû Áö¿øºñ-Àç·áºñ
4) ÁöÃâ°áÀÇÀÏÀÚ: %y%.00.00.
5) ±Ý¾×: ±Ý¡Û¿ø.  ³¡.
)
    return template
}
TPL_MeetingFee()
{
    y := GetYear()
    sy := GetSchoolYear()
    meetingDate := GetAfterDays(7)

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ÇÐ±³ ¡Û±³À°°úÁ¤¿î¿µ ÇùÀÇÈ¸ ½Ç½Ã
1. °ü·Ã: ¡Û¡ÛÇÐ±³-¡Û¡Û(%y%. 0. 0.)
2. %sy%ÇÐ³âµµ ¡Û¡ÛÇÐ±³ ¡Û ±³À°°úÁ¤¿î¿µ ÇùÀÇÈ¸¸¦ ¾Æ·¡¿Í °°ÀÌ ½Ç½ÃÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ÀÏ½Ã: %meetingDate% 10:00~
  ³ª. Àå¼Ò: È¸ÀÇ½Ç ¹× ÀÎ±Ù½Ä´ç
  ´Ù. ´ë»ó: ±³Àå, ±³°¨, ÇàÁ¤½ÇÀå, ºÎÀå±³»ç ¡Û¸í ÃÑ ¡Û¸í
  ¶ó. ÇùÀÇ¾È°Ç: ºÎ¼­º° ÁÖ¿ä¾÷¹«ÃßÁø°èÈ¹ µî
  ¸¶. ¼Ò¿ä°æºñ: ±Ý ¿ø
    ¡Ø 50¸¸¿ø ÀÌ»ó½Ã ¸í´Ü ºÙÀÓ ÇÊ¼ö
  ¹Ù. ÁýÇà¹æ¹ý: ÇÐ±³Ä«µå °áÁ¦.  ³¡.
)
    return template
}

TPL_LecturerFee()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ ¡Û ¿î¿µ »ç¾÷ °­»çºñ Áö±Þ
1. °ü·Ã: ¡Û¡ÛÇÐ±³-¡Û(%y%. . .) ¡Û »ç¾÷ ¿î¿µ °èÈ¹
2. %sy%ÇÐ³âµµ ¡Û¡Û °­»çºñ¸¦ ´ÙÀ½°ú °°ÀÌ Áö±ÞÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. °Ç¸í:
  ³ª. Áö±Þ´ë»ó: ¿ÜºÎ°­»ç ¡Û [ÀÏ¹Ý/Æ¯º°°­»ç ¡ÛÈ£]
  ´Ù. ÀÏ½Ã: %y%. %m%. ¡Û.~%m%. ¡Û. (ÃÑ2½Ã°£: ±âº»1, ÃÊ°ú1)
  ¶ó. Áö±Þ±Ý¾×: ±Ý ¿ø
    - °­»ç·á: ±âº»1½Ã°£ 60,000¿ø+ÃÊ°ú 1½Ã°£ 50,000¿ø
    - ¿ø°í·á: 10,000¿ø*5¸Å*2½Ã°£  
  ¸¶. Áö±Þ¹æ¹ý: °èÁÂÀÌÃ¼ (¡ÛÀºÇà, X-X-X, O)

  * %sy%ÇÐ³âµµ ÇÐ±³È¸°è ¼¼Ãâ¿¹»ê ÁýÇàÁöÄ§ °­»çºñ ÃÖ½Å ±ÔÁ¤ È®ÀÎ

ºÙÀÓ  1. °­»çÄ«µå ¶Ç´Â °­ÀÇÈ®ÀÎ¼­ 1ºÎ. (º°Ã· or ºñ°ø°³ ¿µ±¸)
        2. °³ÀÎÁ¤º¸µ¿ÀÇ¼­ 1ºÎ.(º°Ã· or ºñ°ø°³ ¿µ±¸)
      2. ÅëÀå»çº» 1ºÎ.  ³¡.
)
    return template
}

TPL_TravelFee()
{
    y := GetYear()
    m := GetMonth()
    sy := GetSchoolYear()

    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ %m%¿ù ±³Á÷¿ø °ü³»(°ü¿Ü) ¿©ºñ Áö±Þ
1. °ü·Ã: %sy%ÇÐ³âµµ ÇÐ±³È¸°è ¼¼Ãâ¿¹»ê ÁýÇàÁöÄ§
2. %sy%ÇÐ³âµµ %m%¿ùºÐ ±³Á÷¿ø °ü³» °ü¿Ü ÃâÀå ¿©ºñ¸¦ ¾Æ·¡¿Í °°ÀÌ Áö±ÞÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. ±â°£: %y%. %m%. ¡Û.~%m%. ¡Û.
  ³ª. Áö±Þ´ë»ó: ¡Û [±³Á÷¿ø/ÇÐºÎ¸ð/±âÅ¸]
  ´Ù. Áö±Þ±Ý¾×: ±Ý¡Û¿ø
    - »êÃâ³»¿ª: 20,000¿ø*¡ÛÀÏ
  ¹Ù. Áö±Þ¹æ¹ý: °èÁÂÀÌÃ¼ (¡ÛÀºÇà, X-X-X, O)


ºÙÀÓ  1. ¿©ºñ ³»¿ª 1ºÎ. 
      2. ¿©ºñÁ¤»ê¼­ °¢ 1ºÎ.  ³¡.

  °¡. ¸ñÀû:
  ³ª. Àå¼Ò:

ºÙÀÓ  1. Âü¼®ÀÚ µî·ÏºÎ µî ±Ù°ÅÀÚ·á 1ºÎ. 
      2. ÅëÀå»çº» 1ºÎ.  ³¡.
)
    return template
}


SSOK_RevenueLabel(n)
{
    labels := []
    labels.Push(Chr(0xC9D5) . Chr(0xC218) . Chr(0x0028) . Chr(0xC77C) . Chr(0xBC18) . Chr(0x0029))
    labels.Push(Chr(0xC9D5) . Chr(0xC218) . Chr(0x0028) . Chr(0xD604) . Chr(0xC7A5) . Chr(0xCCB4) . Chr(0xD5D8) . Chr(0xD559) . Chr(0xC2B5) . Chr(0x0029))
    labels.Push(Chr(0xC740) . Chr(0xD589) . Chr(0xC774) . Chr(0xC790))
    labels.Push(Chr(0xC804) . Chr(0xC785) . Chr(0xAE08))
    labels.Push(Chr(0xC218) . Chr(0xC775) . Chr(0xC790) . Chr(32) . Chr(0xC815) . Chr(0xC0B0))
    labels.Push(Chr(0xBC18) . Chr(0xD658) . Chr(0x0028) . Chr(0xBAA9) . Chr(0xC801) . Chr(0xC0AC) . Chr(0xC5C5) . Chr(0xBE44) . Chr(0x0029))
    labels.Push(Chr(0xBC18) . Chr(0xD658) . Chr(0x0028) . Chr(0xC218) . Chr(0xC775) . Chr(0xC790) . Chr(0xBD80) . Chr(0xB2F4) . Chr(0x0029))
    return labels[n]
}

TPL_OtherGift()
{
    y := GetYear()
    template =
(
Á¦¸ñ: %y%ÇÐ³âµµ »óÇ°±Ç ±¸ÀÔ °èÈ¹ ¼ö¸³

1. °ü·Ã: ¡Û¡ÛÇÐ±³-000(%y%.00.00.)¡¸%y%ÇÐ³âµµ ±³À°°úÁ¤ ¿î¿µ °èÈ¹¡¹
2. %y%ÇÐ³âµµ ±³À°°úÁ¤ ¿î¿µÀ» À§ÇØ ´ÙÀ½°ú °°ÀÌ »óÇ°±Ç ±¸ÀÔ °èÈ¹À» ¼ö¸³ÇÕ´Ï´Ù.
   °¡. ±¸¸Å ¿¹Á¤ ³»¿ª: µ¶¼­Çà»ç ½Ã»óÇ° 5,000¿ø¡¿20Àå(2ÇÐ±â »ç¿ë ¿¹Á¤)
   ³ª. ±¸¸Å ¹æ¹ý: ±¸¸ÅÃ³º° °ßÀû ¶Ç´Â ÇÒÀÎÀ²À» ºñ±³ÇÑ ÈÄ, Ç°ÀÇÇÏ¿© ±¸ÀÔ ¿¹Á¤
   ´Ù. °ü¸® ¹æ¹ý
      1. ±¸ÀÔ´ëÀå ¹× ¹èºÎ´ëÀå ÀÛ¼º
      2. »óÇ°±Ç ½Ç¼ö·É ¿©ºÎ¸¦ ¸íÈ®È÷ ÇÏ±â À§ÇØ ¼ö·ÉÀÎ ÀÚÇÊ ¼­¸í ÀÇ¹«È­
      3. »óÇ°±Ç ±¸¸Å ¹× »ç¿ë³»¿ªÀ» ºÐ±âº°·Î ÀÍ¿ù 10ÀÏ±îÁö ±³À°Ã» ¹× º»±³ ´©¸®Áý¿¡ °ø°³ÇÔ.  ³¡.
)
    return template
}

TPL_OtherCard()
{
    y := GetYear()
    m := GetMonth()
    template =
(
Á¦¸ñ: %y%³â %m%¿ù 1È¸Â÷ ¹ýÀÎÄ«µå »ç¿ëºÎ º¸°í

1. °ü·Ã: %y%ÇÐ³âµµ ÇÐ±³È¸°è ¿¹»êÆí¼º ¹× ÁýÇàÁöÄ§
2. %y%³â %m%¿ù 1ÀÏ~15ÀÏ±îÁöÀÇ ¹ýÀÎÄ«µå »ç¿ëºÎ¸¦ ¾Æ·¡¿Í °°ÀÌ º¸°íÇÕ´Ï´Ù.

ºÙÀÓ  ¹ýÀÎÄ«µå »ç¿ëºÎ 1ºÎ.  ³¡.
)
    return template
}
TPL_RevenuePlaceholder(n)
{
    if (n = 2)
        return TPL_RevenueFieldTrip()
    if (n = 5)
        return TPL_RevenueSettlement()
    if (n = 7)
        return TPL_RevenueRefundBeneficiary()
    return TPL_RevenuePlaceholderBasic()
}

TPL_RevenuePlaceholderBasic()
{
    template =
(
ÃßÈÄ ÀÛ¼º(Á¦¸ñ000)
)
    return template
}

TPL_RevenueFieldTrip()
{
    y := GetYear()
    sy := GetSchoolYear()
    m := GetMonth()
    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ Â¡¼ö ÀÇ·Ú ¹× °¡Á¤Åë½Å¹® ¹ß¼Û

1. °ü·Ã: %sy%ÇÐ³âµµ ÇöÀåÃ¼ÇèÇÐ½À ¿î¿µ ¼¼ºÎÃßÁø°èÈ¹(¡Û¡ÛÇÐ±³-0000, %y%. 0. 0.)
2. ÇöÀåÃ¼ÇèÇÐ½ÀÀÇ ¿øÈ°ÇÑ ¿î¿µÀ» À§ÇÏ¿© %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ Â¡¼ö¸¦ ´ÙÀ½°ú °°ÀÌ ÀÇ·ÚÇÏ°íÀÚ ÇÕ´Ï´Ù.
   °¡. ¿ä±¸³»¿ª: %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ Â¡¼ö ÀÇ·Ú
   ³ª. Ã¼ÇèÀÏ½Ã: %y%. 0. 0.
   ´Ù. Â¡¼ö´ë»ó: ÃÑ 200¸í(5ÇÐ³â 6ÇÐ±Þ/ ºÙÀÓÆÄÀÏ Âü°í)
   ¶ó. Â¡¼ö¿ä±¸±â°£: %y%. 0. 0. ~ %y%. 0. 0.(00ÀÏ)
   ¸¶. »êÃâ±âÃÊ: ºÙÀÓÆÄÀÏ Âü°í
   ¹Ù. Â¡¼ö±Ý¾×: ±Ý¡Û¿ø
   »ç. Áö¿ø±Ý¾×: ±Ý¡Û¿ø(±Ý¡Û¿ø)

ºÙÀÓ  1. %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ Â¡¼ö ÀÇ·Ú »ó¼¼ ³»¿ª¼­ 1ºÎ.
      2. %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ Ãâ±Ý ¾È³» °¡Á¤Åë½Å¹® 1ºÎ.  ³¡.

¡Ø 1) Â¡¼ö¿ä±¸±â°£Àº »ç¾÷ °³½Ã Àü¿¡ ¿Ï·áµÇ¾î¾ß ÇÏ¸ç, ±â°£ ¼³Á¤Àº ¼¼ÀÔ´ã´çÀÚ¿Í »çÀü ÇùÀÇ
   2) °áÀç¼± ÁöÁ¤ ½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¼¼ÀÔ´ã´çÀÚ) ÇùÁ¶, ´ã´çÀÚ ¹ÌÇùÁ¶ ½Ã ÇÊ¼ö °ø¶÷ ÁöÁ¤
)
    return template
}

TPL_RevenueSettlement()
{
    y := GetYear()
    sy := GetSchoolYear()
    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ ¼öÀÍÀÚºÎ´ã±Ý Á¤»ê ¹× °ø°³

1. °ü·Ã: %sy%ÇÐ³âµµ ÇöÀåÃ¼ÇèÇÐ½À ¿î¿µ ¼¼ºÎÃßÁø°èÈ¹(¡Û¡Û¡ÛÇÐ±³-0000, %y%. 0. 0.)
2. %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ ¼öÀÍÀÚºÎ´ã±ÝÀ» ´ÙÀ½°ú °°ÀÌ Á¤»êÇÏ°í ±× °á°ú¸¦ ÇÐ±³ ´©¸®Áý(È¨ÆäÀÌÁö)¿¡ °ø°³ÇÏ°íÀÚ ÇÕ´Ï´Ù.
   °¡. »ç ¾÷ ¸í: %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½À ¿î¿µ
   ³ª. ÃßÁø±â°£: %y%. 0. 0.(¡Û) ~ %y%. 0. 0.(¡Û) (ÃÑ¡ÛÀÏ)
   ´Ù. ÁýÇà³»¿ª: ºÙÀÓÆÄÀÏ Âü°í
   ¶ó. ÁýÇàÀÜ¾×: ±Ý¡Û¿ø(±Ý¡Û¿ø)
   ¸¶. °ø°³¹æ¹ý: ÇÐ±³ ´©¸®Áý(È¨ÆäÀÌÁö) °Ô½Ã

ºÙÀÓ  1. %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ ¼öÀÍÀÚºÎ´ã±Ý Á¤»ê ³»¿ª 1ºÎ.
      2. %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ ¼öÀÍÀÚºÎ´ã±Ý Á¤»ê °¡Á¤Åë½Å¹® 1ºÎ.  ³¡.

¡Ø °áÀç¼± ÁöÁ¤ ½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¼¼ÀÔ´ã´çÀÚ) ÇùÁ¶
)
    return template
}

TPL_RevenueRefundBeneficiary()
{
    y := GetYear()
    sy := GetSchoolYear()
    template =
(
Á¦¸ñ: %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ °ú¿À³³¹ÝÈ¯ ÀÇ·Ú

1. °ü·Ã: %sy%ÇÐ³âµµ ÇöÀåÃ¼ÇèÇÐ½À ¼öÀÍÀÚºÎ´ã±Ý Á¤»ê ¹× °ø°³(¡Û¡Û¡ÛÇÐ±³-0000, %y%. 0. 0.)
2. %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ ÀÜ¾×À» ´ÙÀ½°ú °°ÀÌ °ú¿À³³¹ÝÈ¯ ÀÇ·ÚÇÏ°íÀÚ ÇÕ´Ï´Ù.
   °¡. ¿ä±¸³»¿ª: %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ °ú¿À³³¹ÝÈ¯ ÀÇ·Ú
   ³ª. Ã¼ÇèÀÏ½Ã: %y%. 0. 0.(¡Û)
   ´Ù. ¹ÝÈ¯´ë»ó: ÃÑ¡Û¸í(ºÙÀÓÆÄÀÏ Âü°í)
   ¶ó. ¹ÝÈ¯»çÀ¯: ÇöÀåÃ¼ÇèÇÐ½À ºÒÂü¿¡ µû¸¥ ÀÔÀå·á ¹ÝÈ¯
   ¸¶. ¹ÝÈ¯±Ý¾×: ±Ý¡Û¿ø(±Ý¡Û¿ø)

ºÙÀÓ %sy%ÇÐ³âµµ 0¿ù ÇöÀåÃ¼ÇèÇÐ½Àºñ ¹ÝÈ¯ ´ë»ó ¸í´Ü 1ºÎ.  ³¡.

¡Ø °áÀç¼± ÁöÁ¤ ½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¼¼ÀÔ´ã´çÀÚ) ÇùÁ¶, ¼¼ÀÔ´ã´çÀÚ ¹ÌÇùÁ¶ ½Ã ÇÊ¼ö °ø¶÷ ÁöÁ¤
)
    return template
}
TPL_RevenueCollect()
{
    y := GetYear()
    m := GetMonth()

    template =
(
Á¦¸ñ: %y%³â %m%¿ù OOOO Â¡¼ö°áÀÇ
1. °ü·Ã: ¡Û¡ÛÇÐ±³-¡Û¡Û(%y%. . .)
2. %y%³â %m%¿ù ±³Á÷¿ø ±Þ½Äºñ¸¦ ´ÙÀ½°ú °°ÀÌ Â¡¼ö°áÁ¤ °áÀÇÇÕ´Ï´Ù.
  °¡. Â¡¼ö´ë»ó: ±³Á÷¿ø ¸í
  ³ª. ±Ý¾×: ±Ý  ¿ø

ºÙÀÓ Â¡¼ö°áÀÇ¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_RevenueInterest()
{
    y := GetYear()
    m := GetMonth()

    template =
(
Á¦¸ñ: %y%³â %m%¿ù ÇÐ±³È¸°è ÀºÇàÀÌÀÚ Â¡¼ö°áÀÇ
1. °ü·Ã: ¡Û¡ÛÇÐ±³-¡Û¡Û(%y%. . .)
2. %y%³â %m%¿ù ÇÐ±³È¸°è ÀºÇàÀÌÀÚ¸¦ ´ÙÀ½°ú °°ÀÌ Â¡¼ö°áÁ¤ °áÀÇÇÕ´Ï´Ù.
  °¡. ´ë»ó: %y%³â %m%¿ù ÇÐ±³È¸°è ÀºÇàÀÌÀÚ
  ³ª. ±Ý¾×: ±Ý  ¿ø

ºÙÀÓ Â¡¼ö°áÀÇ¼­ 1ºÎ.  ³¡.
)
    return template
}

TPL_RevenueTransfer()
{
    y := GetYear()
    m := GetMonth()
    template =
(
%y%³â %m%¿ù ¿î¿µºñ ÀüÀÔ±Ý Â¡¼ö ÀÇ·Ú

ÃßÈÄ ÀÛ¼º(Á¦¸ñ000)
)
    return template
}

TPL_RevenueRefund()
{
    y := GetYear()
    sy := GetSchoolYear()
    m := GetMonth()

    template =
(
Á¦¸ñ:  %y%³â %m%¿ù ¡Û¡Û ÇÐ±³ Áö¿ø±Ý ÁýÇà ÀÜ¾× °ú¿À³³¹ÝÈ¯ ÀÇ·Ú
1. °ü·Ã: %sy%ÇÐ³âµµ ¡Û¡Û ÇÐ±³ Áö¿ø±Ý ¹Ý³³ ¾È³»(¡Û¡Û¡Û°ú-0000, %y%. 0. 0.)
2. %y%³â %m%¿ù ¡Û¡Û ÇÐ±³ Áö¿ø±ÝÀÇ ÁýÇà ÀÜ¾×ÀÌ ¹ß»ýÇÔ¿¡ µû¶ó ´ÙÀ½°ú °°ÀÌ ¸ñÀû »ç¾÷ºñÀÇ °ú¿À³³¹ÝÈ¯À» ÀÇ·ÚÇÕ´Ï´Ù.
  °¡. ¿ä±¸³»¿ª: %y%³âµµ ¡Û¡Û ÇÐ±³ Áö¿ø±Ý ÁýÇà ÀÜ¾× °ú¿À³³¹ÝÈ¯ ÀÇ·Ú   
  ³ª. ¹Ý³³»çÀ¯: ÇÐ»ý ¼ö °¨¼Ò·Î ÀÎÇÑ ¼ö·® Á¶Á¤À¸·Î 10¸¸¿ø ÀÌ»óÀÇ ÀÜ¾× ¹ß»ý   
  ´Ù. ¹Ý³³ÀÏÀÚ: %y%. %m%. 0.(°ü·Ã°ø¹® ÁöÁ¤ÀÏÀÚ)
  ¶ó. ¹Ý³³°èÁÂ: ³óÇù 000-0000-0000-00 ¼¼Á¾½Ã±³À°Ã»(°ü·Ã°ø¹® ÂüÁ¶)   
  ¸¶. ¹Ý³³±Ý¾×: ±Ý¡Û¿ø(±Ý¡Û¿ø).  ³¡.

¡Ø °áÀç¼± ÁöÁ¤½Ã ÇàÁ¤½Ç(ÇàÁ¤½ÇÀå, ¼¼ÀÔ´ã´çÀÚ) ÇùÁ¶, ¼¼ÀÔ´ã´çÀÚ ¹ÌÇùÁ¶ ½Ã ÇÊ¼ö °ø¶÷ ÁöÁ¤
)
    return template
}

TPL_NationalPetition()
{
    template =
(
1. ¾È³çÇÏ½Ê´Ï±î? ±ÍÇÏ²²¼­ ±¹¹Î½Å¹®°í¸¦ ÅëÇØ ½ÅÃ»ÇÏ½Å ¹Î¿ø(½ÅÃ»¹øÈ£ 1AA-0000-000000)¿¡ ´ëÇÑ °ËÅä °á°ú¸¦ ´ÙÀ½°ú °°ÀÌ ¾Ë·Áµå¸³´Ï´Ù.

2. ±ÍÇÏÀÇ ¹Î¿ø³»¿ëÀº '¡Û¡Û¡Û¡Û¡Û¡Û¡Û¡Û'¿¡ °üÇÑ °ÍÀ¸·Î ÀÌÇØ(¶Ç´Â ÆÇ´Ü) µË´Ï´Ù.
   ¡Ø ¹Î¿øÀÎ ¶Ç´Â Á¦3ÀÚ °³ÀÎÁ¤º¸(°ø¹«¿ø Æ÷ÇÔ) µî °³ÀÎÀ» ½Äº°ÇÒ ¼ö ÀÖ´Â Á¤º¸´Â Á¦¿Ü
    ¡Øºñ°ø°³¿ëÀº ¹Î¿ø ½ÅÃ»¹øÈ£ ±âÀçÇÏ¸ç, °ø°³¿ëÀº ¹Î¿ø ½ÅÃ»¹øÈ£ ±âÀçÇÏÁö ¾ÊÀ½
2. ±ÍÇÏ²²¼­ ¹Î¿øÀ» Á¦±âÇÏ½Ç ¶§, Áßµî±³À°°ú¸¦ ±âÇÇ½ÅÃ» ÇÏ¼ÌÀ¸³ª, ¢¼¢¼¢¼ µîÀÇ »çÁ¤À» °¨¾ÈÇÒ °æ¿ì(¡â¡âµîÀÇ ÀÌÀ¯·Î) ºÎµæÀÌ [±â°ü¸í]¿¡¼­ ´äº¯À» µå¸± ¼ö¹Û¿¡ ¾øÀ½À» ¾çÇØÇØ ÁÖ½Ã±â ¹Ù¶ø´Ï´Ù.
*±âÇÇ½ÅÃ» ºÒ¼ö¿ë »çÀ¯ ¹Ýµå½Ã ±âÀç!!*(¹ÌÀÛ¼º ½Ã Æò°¡¿¡¼­ °¨Á¡ ¿äÀÎ)
3. ±ÍÇÏÀÇ ÁúÀÇ»çÇ×¿¡ ´ëÇØ °ËÅäÇÑ ÀÇ°ßÀº ´ÙÀ½°ú °°½À´Ï´Ù.
 °¡.
 ³ª.
4. ±ÍÇÏÀÇ Áú¹®¿¡ ¸¸Á·½º·¯¿î ´äº¯ÀÌ µÇ¾ú±â¸¦ ¹Ù¶ó¸ç, ´äº¯ ³»¿ë¿¡ ´ëÇÑ Ãß°¡ ¼³¸íÀÌ ÇÊ¿äÇÑ °æ¿ì [±â°ü¸í] OOO(¢Î044-OOO-OOOO, OOOOO@korea.kr)¿¡°Ô ¿¬¶ôÇÏ½Ã¸é Ä£ÀýÈ÷ ¾È³»ÇØµå¸®µµ·Ï ÇÏ°Ú½À´Ï´Ù.
  ³¡À¸·Î ¿ì¸® ±³À°Ã»¿¡¼­´Â ¹Î¿øÃ³¸® °á°ú¿¡ ´ëÇÑ ¹Î¿øÀÎÀÇ ¸¸Á·µµ¸¦ ÆÄ¾ÇÇÏ¿© ¹Î¿øÃ³¸® ¾÷¹« °³¼±¿¡ Âü°íÀÚ·á·Î È°¿ëÇÏ°í ÀÖ½À´Ï´Ù. Àá½Ã ½Ã°£À» ³»½Ã¾î ¹Î¿øÃ³¸® ¸¸Á·µµ¸¦ µî·ÏÇØÁÖ½Ã¸é °¨»çÇÏ°Ú½À´Ï´Ù.
)
    return template
}
TPL_SchoolMarket()
{
    y := GetYear()
    m := GetMonth()
    due := GetDueDate()
    template =
(
<ÀÏ¹Ý¹°Ç°>
1. ¹°Ç°³»¿ª¼­ÀÇ ±Ô°Ý,¸ðµ¨¸í°ú ¹Ýµå½Ã µ¿ÀÏÇÑ Á¦Ç°ÀÌ¾î¾ß ÇÕ´Ï´Ù.
 - ±Ô°ÝÁ¦Ç°(KS) ¹× ¾ÈÀüÀÎÁõ Á¦Ç°(KC)À» ±¸¸ÅÇÏ¿© Ç°Áú °ü¸®¿¡ Ã¶Àú
2. ¹°Ç° ³»¿ª¼­ÀÇ »ó¼¼ÇÑ ³»¿ë È®ÀÎ ¾øÀÌ Á¦ÃâÇÑ °ßÀû¿¡ ´ëÇÑ Ã¥ÀÓÀº °ø±Þ¾÷Ã¼¿¡ ÀÖ½À´Ï´Ù.
3. Á¦Ç° ¼³Ä¡ ¹× ¹è¼Û, ºÎ°¡¼¼¸¦ Æ÷ÇÔÇÑ °ßÀûÁ¦Ãâ ÇÊ¼ö
4. °Ë¼ö ÈÄ ÇÐ±³ Ãø ¿äÃ» ¹°°Ç°ú ´Ù¸£°Å³ª ÇÏÀÚ°¡ ÀÖÀ» °æ¿ì Áï½Ã ±³È¯ ¹× ±³È¯¿¡ µû¸¥ ºñ¿ëÀº ¾÷Ã¼°¡ ºÎ´ãÇÔ
5. ¹®ÀÇ: (ÇàÁ¤½Ç) 044-OOO-OOO, (±³¹«½Ç) 044-OOO-OOO
6. ³³Ç°±âÇÑ: %due% 15½Ã±îÁö[±âÇÑ ¾ö¼ö]

<¿ë¿ª>
1. °ßÀû Á¦Ãâ Àü ÇöÀå ¹æ¹® ¹× È®ÀÎÇÏ¿© °ßÀû Á¦Ãâ ¹Ù¶ø´Ï´Ù.
2. ÇöÀå È®ÀÎÇÏÁö ¾Ê¾Æ ¹ß»ýÇÏ´Â ºÒÀÌÀÍÀº ÇÐ±³¿¡¼­ Ã¥ÀÓÁöÁö ¾ÊÀ½
3. °ú¾÷³»¿ª: [¼¼ºÎ ºÙÀÓ °ú¾÷Áö½Ã¼­ ÂüÁ¶]
  - Àå¼Ò:
  - ÀÏÁ¤:
4. °ßÀû¼­, ³»¿ª¼­, ÀÛ¾÷¿Ï·áÈ®ÀÎ¼­(»çÁø´ëÁö Æ÷ÇÔ) Á¦Ãâ
5. ¹®ÀÇ: (ÇàÁ¤½Ç) 044-OOO-OOO, (±³¹«½Ç) 044-OOO-OOO

<°ø»ç>
1. °ßÀû Á¦Ãâ Àü ÇöÀå ¹æ¹® ¹× È®ÀÎÇÏ¿© °ßÀû Á¦Ãâ ¹Ù¶ø´Ï´Ù.
2. ÇöÀå È®ÀÎÇÏÁö ¾Ê¾Æ ¹ß»ýÇÏ´Â ºÒÀÌÀÍÀº ÇÐ±³¿¡¼­ Ã¥ÀÓÁöÁö ¾ÊÀ½
3. °ú¾÷³»¿ª:
 - Àå¼Ò:
 - ÀÏÁ¤:
4. ±âÅ¸»çÇ×: ¼¼ºÎ ºÙÀÓ °ú¾÷Áö½Ã¼­, ½Ã¹æ¼­, µµ¸é ÂüÁ¶
5. ÇöÀå¼³Ä¡ ¹× ºÎ°¡°¡Ä¡¼¼ Æ÷ÇÔ, ³»¿ª¼­, »çÁø ´ëÁö, ½ÃÇè¼ºÀû¼­(ÀÎÁõ¼­) Á¦Ãâ
5. Àü±â°ø»ç¾÷ ¸éÇã ÇÊ¼ö º¸À¯
5. ¹®ÀÇ: (ÇàÁ¤½Ç) 044-OOO-OOO, (±³¹«½Ç) 044-OOO-OOO

<µµ¼­±¸¸Å>
1. µµ¼­Á¤°¡(±âÃÊ±Ý¾×)ÀÇ 90`%¹Ì¸¸À¸·Î °ßÀûÁ¦Ãâ ÇÏ´Â °æ¿ì °ßÀû ¹«È¿
 - ¹è¼Ûºñ, ºÎ°¡¼¼ Æ÷ÇÔ °ßÀû Á¦Ãâ ÇÊ¼ö
2. µ¿ÀÏ°¡°Ý °ßÀû Á¦ÃâÀÏ °æ¿ì 'S2B µ¿ÀÏ°¡°ÝÃßÃ·¡¯À¸·Î  °è¾à»ó´ëÀÚ°áÁ¤
3. °Ë¼ö ½Ã ÆÄº», ÈÑ¼ÕµÈ ÀÚ·á¿¡ ´ëÇØ¼­´Â Áï½Ã ±³È¯ ¿øÄ¢,
    1³â ÀÌ³» ¹ßÇàµÈ Á¤Ç°µµ¼­·Î ±³È¯ µÇ¾î¾ß ÇÑ´Ù
4. Ç°Àý, ÀýÆÇ µÈ µµ¼­´Â ¹Ýµå½Ã 2°÷ ÀÌ»óÀÇ Ç°Àý È®ÀÎ¼­ Á¦Ãâ
 - Ç°Àýµµ¼­ ¹ß»ý ½Ã Ç°Àýµµ¼­ Æ÷ÇÔÇÑ ±Ý¾×À» Á¦ÃâÇÒ °Í
5. ³³Ç°ÀÏ ÁØ¼ö¸¦ ¹Ù¶ó¸ç ºÐÇÒ ³³Ç°Àº ¿øÄ¢ÀûÀ¸·Î ºÒ°¡ÇÕ´Ï´Ù.
6. DLS ¶óº§ ÀÛ¾÷ÀÌ °¡´ÉÇØ¾ß ÇÏ¸ç,´ë±ÝÁö±ÞÀº µµ¼­±Ý¾×°ú º°µµ·Î Ã»±¸ÇÑ´Ù.
  ¡Ø ¹®ÀÇÃ³: (°è¾à´ã´ç) 044-OOO-OOO, (µµ¼­´ã´ç) 044-OOO-OOO
 * ³³Ç°±âÇÑ: %due% 13½Ã±îÁö (±âÇÑ¾ö¼ö)

<Â÷·®ÀÓÂ÷>
1. °ßÀû Á¦Ãâ Àü ÇöÀå ¹æ¹® ¹× È®ÀÎÇÏ¿© °ßÀû Á¦Ãâ ¹Ù¶ø´Ï´Ù.
2. ÇöÀå È®ÀÎÇÏÁö ¾Ê¾Æ ¹ß»ýÇÏ´Â ºÒÀÌÀÍÀº ÇÐ±³¿¡¼­ Ã¥ÀÓÁöÁö ¾ÊÀ½
3. °ú¾÷³»¿ª: [¼¼ºÎ ºÙÀÓ °ú¾÷Áö½Ã¼­ ÂüÁ¶]
  - ÀÏ½Ã: 20%y%. %m%. OO. 10:00~20%y%. %m%. OO. 10:00[O¹ÚOÀÏ]
  - Àå¼Ò: OO ÀÏ¿ø
  - ´ë»ó: ÇÐ»ý OO¸í, ±³»ç O¸í
  - Â÷·®: (45)ÀÎ½Â O´ë
 * À¯·ùºñ, µµ·Îºñ, ÁÖÂ÷ºñ, ±â»ç ½Ä»çºñ µî ¸ðµç Á¦°æºñ Æ÷ÇÔ
4. ¾ÈÀü¿ä¿ø ¹èÄ¡°èÈ¹ ¹× ÀÚ°Ý Áõºù¼­·ù(ÇØ´ç ÀÚ°ÝÁõ + ¾ÈÀü¿¬¼ö ÀÌ¼öÁõ) Á¦Ãâ ÇÊ¼ö
5. ¹®ÀÇ: (ÇàÁ¤½Ç) 044-OOO-OOO, (±³¹«½Ç) 044-OOO-OOO
)
    return template
}

TPL_LegalBasis()
{
    template =
(
1. °ü·Ã: ¡¸Áö¹æ°è¾à¹ý½ÃÇà·É¡¹ Á¦25Á¶1Ç×5È£³ª¸ñ (2Ãµ¸¸¿ø ÀÌÇÏ ¹°Ç°,¿ë¿ª ¼öÀÇ°è¾à)
1. °ü·Ã: ¡¸Áö¹æ°è¾à¹ý½ÃÇà·É¡¹ Á¦80Á¶ ¹× Á¶´Þ»ç¾÷¹ý½ÃÇà·É Á¦7Á¶(Á¦3ÀÚ¸¦ À§ÇÑ ´Ü°¡°è¾à)
1. °ü·Ã: ¡¸Áö¹æ°è¾à¹ý½ÃÇà·É¡¹ Á¦25Á¶1Ç×5È£´Ù¸ñ (¿¹: Áß¼Ò±â¾÷, ¼Ò»ó°øÀÎ)
1. °ü·Ã:  ¡¸Áö¹æ°è¾à¹ý½ÃÇà·É¡¹ Á¦25Á¶1Ç×5È£ ¸¶¸ñ (¿¹: ÇÐ¼ú¿¬±¸,¿ø°¡°è»ê)
1. °ü·Ã
  °¡. ¡¸¼¼Á¾Æ¯º°ÀÚÄ¡½Ã Áö¿ª³ó»ê¹° °ø°ø±Þ½Ä Áö¿ø¿¡ °üÇÑ Á¶·Ê¡¹ Á¦26Á¶
  ³ª. ¡¸Áö¹æ°è¾à¹ý ½ÃÇà·É¡¹ Á¦25Á¶1Ç×3È£ ¹× Á¦50Á¶1Ç×4È£.
1. °ü·Ã
  °¡. ¡¸Áö¹æ°è¾à¹ý½ÃÇà·É¡¹ Á¦25Á¶1Ç×5È£¹Ù¸ñ (¿¹: »çÈ¸Àû,¿©¼º,Àå¾Ö,ÀÚÈ°,¸¶À»±â¾÷)
  ³ª. ¡¸¼¼Á¾±³À°Ã» »çÈ¸Àû°æÁ¦±â¾÷ Á¦Ç° ±¸¸ÅÃËÁø¿¡ °üÇÑ Á¶·Ê¡¹ Á¦5Á¶(±¸¸ÅÃËÁø°èÈ¹ ¼ö¸³)
  ´Ù. ¡¸¼¼Á¾½Ã »çÈ¸Àû°æÁ¦ À°¼ºÁö¿ø¿¡ °üÇÑ Á¶·Ê¡¹ Á¦2Á¶Á¦2È£³ª¸ñ
1. °ü·Ã: ¡¸ÃâÆÇ¹®È­»ê¾÷ ÁøÈï¹ý¡¹ Á¦22Á¶Á¦5Ç×(°£Çà¹° Á¤°¡ Ç¥½Ã ¹× ÆÇ¸Å)
1. °ü·Ã: ¡¸ÇÐ±³º¸°Ç¹ý¡¹ Á¦4Á¶(ÇÐ±³ÀÇ È¯°æÀ§»ý ¹× ½ÄÇ°À§»ý)
1. °ü·Ã: ¡¸ÇÐ±³½Ã¼³ µîÀÇ ¾ÈÀü ¹× À¯Áö°ü¸® µî¿¡ °üÇÑ ¹ý·ü¡¹ Á¦17Á¶(¾ÈÀüÁ¡°ËµîÀÇ °á°ú¿¡ µû¸¥ Á¶Ä¡)
1. °ü·Ã: ¡¸Áö¹æÀÚÄ¡´ÜÃ¼ ÀÔÂû ¹× °è¾à ÁýÇà±âÁØ¡¹ Á¦5Àå ¼öÀÇ°è¾à ¿î¿µ¿ä·É

4. °è¾à¹æ¹ý: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã °ø°ø±Þ½ÄÁö¿ø¼¾ÅÍ¿Í ¼öÀÇ°è¾à, S2B ÀüÀÚ°è¾à, ³ª¶óÀåÅÍ ¼îÇÎ¸ô ¼öÀÇ°è¾à
)
    return template
}
TPL_GeneralPlan()
{
    y := GetYear()
    m := GetMonth()

    template =
(
Á¦¸ñ: %y%³â ¡Û¡Û ¾÷¹« ÃßÁø °èÈ¹ ¼ö¸³
1. °ü·Ã: ±³À°ºÎ ¡Û¡Û ±âº»ÁöÄ§ Á¦*Á¶(¡Û¡Û)
2. %y%³â ¡Û¡Û¾÷¹« ÃßÁø °èÈ¹À» ºÙÀÓ°ú °°ÀÌ ¼ö¸³ÇÏ¿© ÃßÁøÇÏ°íÀÚ ÇÕ´Ï´Ù.
  °¡. °Ç¸í: %y%³â ¡Û¡Û ¾÷¹« ÃßÁø °èÈ¹ ¼ö¸³
  ³ª. ¸ñÀû: ¡Û¡Û ¾÷¹«ÀÇ Ã¼°èÀûÀÌ°í È¿À²ÀûÀÎ ¿î¿µ
  ´Ù. ÃßÁø±â°£: %y%. %m%. ¡Û.~%m%. ¡Û.
  ¶ó. ÁÖ¿ä³»¿ë
    1) ¡Û¡Û ¿î¿µ °èÈ¹
    2) ¼¼ºÎ ÃßÁø ÀÏÁ¤
    3) ¿¹»ê ÁýÇà °èÈ¹
  ¸¶. ±â´ëÈ¿°ú: ¡Û¡Û ¾÷¹«ÀÇ È¿À²¼º ¹× ¿î¿µ ³»½ÇÈ­ Á¦°í

ºÙÀÓ  ÃßÁø °èÈ¹(¾È) 1ºÎ.  ³¡.
)
    return template
}

TPL_GeneralEventNotice()
{
    y := GetYear()
    m := GetMonth()

    template =
(
Á¦¸ñ: [Âü¼®-¾È³»] %y%³â Á¦*È¸  ¼¼Á¾ ¡Û¡Û °³ÃÖ
1. °ü·Ã: ¡Û¡ÛÇÐ±³-***(%y%. *. *.)
2. %y%³â ¡Û¡Û¸¦ À§ÇÑ ¡¸Á¦*È¸ ¼¼Á¾ ¡Û¡Û¡¹¸¦ ¾Æ·¡¿Í °°ÀÌ °³ÃÖÇÏ¿À´Ï Èñ¸ÁÀÚ°¡ Âü¼®ÇÒ ¼ö ÀÖµµ·Ï ¾È³»ÇÏ¿© ÁÖ½Ã±â ¹Ù¶ø´Ï´Ù.
  °¡. ÀÏ½Ã: %y%. %m%. ¡Û. 10:00~12:00
  ³ª. Àå¼Ò: 
  ´Ù. ¸ñÀû: 
  ¶ó. ´ë»ó: 
  ¸¶. ³»¿ë: ?  , ?  , ?
  ¹Ù. ÇàÁ¤»çÇ× 
    - ÁÖÂ÷ÀåÀÌ Çù¼ÒÇÏ¹Ç·Î °¡±ÞÀû ´ëÁß±³Åë ÀÌ¿ë ¹Ù¶ø´Ï´Ù. 

* º» °ø¹® ³»¿ëÀ» °ü½É ÀÖ´Â ±³Á÷¿øÀÌ Âü¼®ÇÒ ¼ö ÀÖµµ·Ï °ø¶÷ ¹× ¾È³»ÇÏ¿© ÁÖ½Ã±â ¹Ù¶ø´Ï´Ù.

ºÙÀÓ  1. ¿î¿µ°èÈ¹ 1ºÎ.
      2. ½ÅÃ»¾ç½Ä 1ºÎ.
)
    return template
}



; =========================================================
; ¼±ÅÃ ¿µ¿ª Á¤¸®
; =========================================================
DOC_ProcessSelection(text)
{
    text := RTrim(text, "`r`n ")

    ; ¦¡¦¡ ½Ã°£ ¹üÀ§¸¸ ºí·Ï ¼±ÅÃ ¡æ ÃÑ ¼Ò¿ä½Ã°£ °è»ê ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
   ; ¿¹: 14:20~18:40 ¡æ 14:20~18:40(4½Ã°£ 20ºÐ)
    ; ÀüÃ¼ Win+F2¿¡¼­´Â È£ÃâÇÏÁö ¾Ê°í, ºí·Ï ÁöÁ¤ ½Ã¿¡¸¸ Àû¿ëÇÕ´Ï´Ù.
    timeResult := DOC_FormatSelectedTimeRange(text)
    if (timeResult != "")
        return timeResult

    ; ¦¡¦¡ ¼ýÀÚ¸¸ ¼±ÅÃ ¡æ ±Ý¾× º¯È¯ ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    if (DOC_IsPlainNumber(text))
        return DOC_FormatPlainMoney(text)

    fixedMoney := DOC_FixMoneyParen(text)
    if (fixedMoney != text)
        return fixedMoney

    ; ¦¡¦¡ ³¯Â¥ ¹üÀ§ Ã³¸®: "2021. 3. 1.(¿ù)~2029. 2. 1.(¸ñ)" ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    rangeStrip := RegExReplace(text, "\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)?\)", "")
    rangeStrip := RegExReplace(rangeStrip, "\(\s*ÃÑ\s*[\d,]+\s*ÀÏ\s*\)", "")
    rangeStrip := RegExReplace(rangeStrip, ",\s*[\d,]+\s*ÀÏ°£", "")
    rangeStrip := RegExReplace(rangeStrip, "\(\s*[\d,]+\s*ÀÏ°£\s*\)", "")
    rangeStrip := RegExReplace(rangeStrip, "\s+", "")

    if RegExMatch(rangeStrip, "^(\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?[-~](\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?$", rM)
    {
        ry1 := rM1, rmo1 := rM2, rd1 := rM3
        ry2 := rM4, rmo2 := rM5, rd2 := rM6
        ry1 := DOC_NormalizeYear(ry1)
        ry2 := DOC_NormalizeYear(ry2)

        rStart := ry1 . Format("{:02}", rmo1) . Format("{:02}", rd1)
        rEnd   := ry2 . Format("{:02}", rmo2) . Format("{:02}", rd2)

        rTemp := rEnd
        EnvSub, rTemp, %rStart%, Days
        rTotal := rTemp + 1

        return FormatDateRangeWithWeekdays(rStart, rEnd, rTotal)
    }

    if RegExMatch(rangeStrip, "^(\d{2}|\d{4})\.(\d{1,2})\.(\d{1,2})\.?[-~](\d{1,2})\.(\d{1,2})\.?$", rM)
    {
        ry1 := DOC_NormalizeYear(rM1)
        rmo1 := rM2, rd1 := rM3
        ry2 := ry1, rmo2 := rM4, rd2 := rM5

        rStart := ry1 . Format("{:02}", rmo1) . Format("{:02}", rd1)
        rEnd   := ry2 . Format("{:02}", rmo2) . Format("{:02}", rd2)
        if (rEnd < rStart)
        {
            ry2 := ry1 + 1
            rEnd := ry2 . Format("{:02}", rmo2) . Format("{:02}", rd2)
        }

        rTemp := rEnd
        EnvSub, rTemp, %rStart%, Days
        rTotal := rTemp + 1

        return FormatDateRangeWithWeekdays(rStart, rEnd, rTotal)
    }

    ; ¦¡¦¡ ³¯Â¥¸¸ ¼±ÅÃ ¡æ ¿äÀÏ °ËÁõ¡¤¼öÁ¤ ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    if (DOC_IsPlainDate(text))
        return DOC_FormatPlainDate(text)

    ; ¦¡¦¡ ³¯Â¥ + ¸¸³ªÀÌ ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    t_age := RegExReplace(text, "\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)", "")
    t_age := RegExReplace(t_age, "\s+", "")
    if RegExMatch(t_age, "^(\d{2,4})\.(\d{1,2})\.(\d{1,2})\.?¸¸³ªÀÌ$", mA)
    {
        birthY := DOC_NormalizeYear(mA1)
        birthM := mA2 + 0
        birthD := mA3 + 0

        FormatTime, nowY,, yyyy
        FormatTime, nowM,, M
        FormatTime, nowD,, d

        age := nowY - birthY
        if (nowM < birthM || (nowM = birthM && nowD < birthD))
            age--

        return birthY . ". " . birthM . ". " . birthD . ". (¸¸ " . age . "¼¼)"
    }

    ; ¦¡¦¡ ³¯Â¥+½Ã°£: "2026. 5. 2.(Åä) 10:00~12:00" ¡æ ±×´ë·Î ¹ÝÈ¯ ¦¡¦¡¦¡¦¡¦¡
    ; ´Ü, ÇÑ±Û+¿¬»êÀÚ°¡ ¼¯ÀÎ °è»ê½Ä(¸¶. 3¸í*26°³)Àº Á¦¿Ü
    t_dt := Trim(RegExReplace(RegExReplace(text, "`r", ""), "`n", ""))
    if (RegExMatch(t_dt, "^(19|20)\d{2}\s*\.\s*\d{1,2}\s*\.\s*\d{1,2}")
        && !RegExMatch(t_dt, "[°¡-ÆR]\s*[\+\*¡¿¡À/]|[\+\*¡¿¡À/]\s*[°¡-ÆR]"))
        return t_dt

    ; ¦¡¦¡ »êÃâ½Ä °è»ê ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    ; ¿©·¯ ÁÙÀ» ¼±ÅÃÇÑ °æ¿ì¿¡´Â ÀüÃ¼¸¦ ÇÑ ¹ø¿¡ °è»êÇÏÁö ¾Ê°í, ¾Æ·¡ÀÇ ÁÙ ´ÜÀ§ Á¤¸®¿¡¼­ °¢ ÁÙº°·Î Ã³¸®ÇÕ´Ï´Ù.
    if (!InStr(text, "`n") && DOC_HasCalcExpression(text, true))
    {
        result := DOC_FixCalc(text, true)
        result := DOC_FinalCleanup(result)
        return result
    }

    ; ¦¡¦¡ ±× ¿Ü: °ø¹®¼­ Á¤¸® ¹æ½Ä ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    result := ""
    Loop, Parse, text, `n, `r
    {
        line := A_LoopField
        line := DOC_CleanLine(line)
        result .= line . "`r`n"
    }

    result := RTrim(result, "`r`n ")
    result := DOC_PromoteGaItemsWhenNoRelated(result)
    result := DOC_AutoNumberLeadingSentence(result)
    result := DOC_NormalizeListNumbers(result)
    result := DOC_KeepOnlyAttachBlankLine(result)
    result := DOC_FinalCleanup(result)

    return result
}


; =========================================================
; ÀüÃ¼ ¹®¼­ Á¤¸®
; =========================================================
DOC_ProcessText(text)
{
    result := ""
    section2 := ""
    purposeAlreadyExists := DOC_HasPurposeExamples(text)

    Loop, Parse, text, `n, `r
    {
        line := A_LoopField

        if RegExMatch(line, "^\s*2\.\s*(.+)$", m2)
            section2 := m21

        line := DOC_CleanLine(line)

        if (!purposeAlreadyExists && RegExMatch(line, "^\s*[°¡-ÇÏ]\.\s*¸ñÀû\s*:\s*$"))
        {
            contextForPurpose := section2 . " " . text
            examples := DOC_BuildPurposeExamples(contextForPurpose)
            line := line . "`r`n" . examples
            purposeAlreadyExists := true
        }

        result .= line . "`r`n"
    }

    result := RTrim(result, "`r`n ")
    result := DOC_PromoteGaItemsWhenNoRelated(result)
    result := DOC_AutoNumberLeadingSentence(result)
    result := DOC_NormalizeListNumbers(result)
    result := DOC_KeepOnlyAttachBlankLine(result)
    result := DOC_FinalCleanup(result)

    if (result != "")
    {
        result := RegExReplace(result, "(?:^|\s*\.\s*|\s+)³¡\.?\s*$")
        result := RTrim(result, ". ")
        result .= ".  ³¡."
        result := DOC_FixFinalAttachEnd(result)
        result := DOC_KeepOnlyAttachBlankLine(result)
    }

    return result
}


; =========================================================
; Win+F2 Ç¥ º¸È£ Á¤¸®
; - Ç¥°¡ ÀÖ´Â ¹®¼­´Â Ç¥ ½ÃÀÛ Àü±îÁö¸¸ Á¤¸®ÇÏ¿© HWP Ç¥ ±¸Á¶¸¦ º¸Á¸ÇÕ´Ï´Ù.
; - ÀüÃ¼ ¹®¼­¿ë DOC_ProcessText()¿Í ´Þ¸®, Ç¥ ¾ÕºÎºÐ¿¡´Â ÃÖÁ¾ "³¡."À» ºÙÀÌÁö ¾Ê½À´Ï´Ù.
; =========================================================
DOC_FindTableStartLine(text)
{
    lines := []
    Loop, Parse, text, `n, `r
        lines.Push(A_LoopField)

    sawTableTitle := false
    headerStreak := 0
    firstHeaderLine := 0

    Loop, % lines.MaxIndex()
    {
        idx := A_Index
        line := lines[idx]
        t := Trim(DOC_NormalizeHardSpaces(line))

        if (t = "")
            continue

        if RegExMatch(t, "(Á¦Ãâ³»¿ª|¼¼ºÎ³»¿ª|»êÃâ³»¿ª|°á»ê\s*³»¿ª|ÀÌ¿ù\s*³»¿ª|³»¿ª\s*$|¸í¼¼|¸ñ·Ï|ÇöÈ²|\[.*³»¿ª.*\]|\(´ÜÀ§\s*[:£º])")
        {
            sawTableTitle := true
            continue
        }

        ; HWP Ç¥¸¦ ÀüÃ¼ º¹»çÇÏ¸é ¼¿ »çÀÌ°¡ ÅÇÀ¸·Î µé¾î¿À´Â °æ¿ì°¡ ¸¹½À´Ï´Ù.
        if InStr(line, A_Tab)
        {
            if (sawTableTitle || DOC_LooksLikeTableHeader(t))
                return idx
        }

        ; Ç¥ Á¦¸ñ ¹Ù·Î ´ÙÀ½¿¡ ´ëÇ¥ Ç¥ ¸Ó¸®±ÛÀÌ ³ª¿À´Â °æ¿ì¸¦ °¨ÁöÇÕ´Ï´Ù.
        if (DOC_LooksLikeTableHeader(t))
        {
            if (firstHeaderLine = 0)
                firstHeaderLine := idx
            headerStreak++

            if (sawTableTitle || headerStreak >= 3)
                return firstHeaderLine

            continue
        }

        ; ±Ý¾× ÁÙÀÌ³ª ÀÏ¹Ý ¹®ÀåÀÌ ³ª¿À¸é ¿¬¼Ó ¸Ó¸®±Û ÆÇ´ÜÀ» ÃÊ±âÈ­ÇÕ´Ï´Ù.
        if !RegExMatch(t, "^[0-9,]+$")
        {
            headerStreak := 0
            firstHeaderLine := 0
        }
    }

    return 0
}

DOC_LooksLikeTableHeader(t)
{
    compact := RegExReplace(t, "\s", "")

    ; HWP Ç¥°¡ ÀÏ¹Ý ÅØ½ºÆ®·Î Ç®·Á º¹»çµÇ´Â °æ¿ì¿¡´Â ¼¿ Á¦¸ñÀÌ ÇÑ ÁÙ¾¿ ³»·Á¿É´Ï´Ù.
    ; ±×·¡¼­ ´ëÇ¥ Ç¥ ¸Ó¸®±Û 1°³¸¸ ÀÖ¾îµµ, À§¿¡¼­ "³»¿ª/ÇöÈ²/¸ñ·Ï"·ù Á¦¸ñÀ» º» »óÅÂ¶ó¸é
    ; Ç¥ ½ÃÀÛÀ¸·Î ÆÇ´ÜÇÒ ¼ö ÀÖµµ·Ï ¸Ó¸®±Û ¹üÀ§¸¦ ³ÐÈü´Ï´Ù.
    if RegExMatch(compact, "^(±¸ºÐ|¿¬¹ø|¼ø¹ø|¹øÈ£|¼ÒµæÀÚ°Ç¼ö|¿¬°£Áö±ÞÃÑ¾×|¼Òµæ¼¼ÇÕ°è|Áö¹æ¼Òµæ¼¼ÇÕ°è|Ç°¸í|±Ô°Ý|¼ö·®|´Ü°¡|±Ý¾×|»êÃâ³»¿ª|ºñ°í|¼¼ºÎ»ç¾÷|¼¼ºÎÇ×¸ñ|¼¼ºÎÇ×º¹|¿¹»ê¾×|ÁýÇà¾×|ÀÌ¿ù¾×|ÇÕ°è|¼¼°èÀ×¿©±Ý|´ÙÀ½¿¬µµÀÌ¿ù»ç¾÷|¼ø¼¼°èÀ×¿©±Ý|¼¼ÀÔ°á»ê|¼¼Ãâ°á»ê|Â÷¾×|¸í½ÃÀÌ¿ù|»ç°íÀÌ¿ù|°è¼Óºñ|°á»êÀüÀÌÀÔ|°á»êÈÄÀÌ¿ù|¼Ò°è)$")
        return true

    score := 0
    headers := "±¸ºÐ|¿¬¹ø|¼ø¹ø|¹øÈ£|¼º¸í|´ë»ó|¼ÒµæÀÚ|°Ç¼ö|¿¬°£Áö±ÞÃÑ¾×|¼Òµæ¼¼|Áö¹æ¼Òµæ¼¼|Ç°¸í|±Ô°Ý|¼ö·®|´Ü°¡|±Ý¾×|ºñ°í|³»¿ª|¼¼ºÎ»ç¾÷|¼¼ºÎÇ×¸ñ|¼¼ºÎÇ×º¹|¿¹»ê¾×|ÁýÇà¾×|ÀÌ¿ù¾×|ÇÕ°è|¼¼°èÀ×¿©±Ý|´ÙÀ½¿¬µµÀÌ¿ù»ç¾÷|¼ø¼¼°èÀ×¿©±Ý|¼¼ÀÔ°á»ê|¼¼Ãâ°á»ê|Â÷¾×|¸í½ÃÀÌ¿ù|»ç°íÀÌ¿ù|°è¼Óºñ|°á»êÀüÀÌÀÔ|°á»êÈÄÀÌ¿ù|¼Ò°è"
    Loop, Parse, headers, |
    {
        if InStr(compact, A_LoopField)
            score++
    }

    return (score >= 2)
}

DOC_GetLinesBefore(text, tableStartLine)
{
    result := ""
    maxLine := tableStartLine - 1

    if (maxLine <= 0)
        return ""

    Loop, Parse, text, `n, `r
    {
        if (A_Index > maxLine)
            break
        result .= A_LoopField . "`r`n"
    }

    return RTrim(result, "`r`n ")
}

DOC_ProcessTextBeforeTable(text)
{
    result := ""
    section2 := ""
    purposeAlreadyExists := DOC_HasPurposeExamples(text)

    Loop, Parse, text, `n, `r
    {
        line := A_LoopField

        if RegExMatch(line, "^\s*2\.\s*(.+)$", m2)
            section2 := m21

        line := DOC_CleanLine(line)

        if (!purposeAlreadyExists && RegExMatch(line, "^\s*[°¡-ÇÏ]\.\s*¸ñÀû\s*:\s*$"))
        {
            contextForPurpose := section2 . " " . text
            examples := DOC_BuildPurposeExamples(contextForPurpose)
            line := line . "`r`n" . examples
            purposeAlreadyExists := true
        }

        result .= line . "`r`n"
    }

    result := RTrim(result, "`r`n ")
    result := DOC_PromoteGaItemsWhenNoRelated(result)
    result := DOC_AutoNumberLeadingSentence(result)
    result := DOC_NormalizeListNumbers(result)
    result := DOC_KeepOnlyAttachBlankLine(result)
    result := DOC_FinalCleanup(result)
    result := RegExReplace(result, "\s*\.?\s*³¡\.\s*$")
    result := RTrim(result, "`r`n ")

    return result . "`r`n"
}

DOC_ReplaceLinesFromDocStart(text, lineCount, targetHwnd := "")
{
    if (lineCount <= 0)
        return false

    if (targetHwnd != "")
    {
        WinActivate, ahk_id %targetHwnd%
        Sleep, 120
    }

    Send, ^{Home}
    Sleep, 100

    Loop, %lineCount%
    {
        Send, +{Down}
        Sleep, 20
    }

    text := DOC_FixAttachGapForHwp(text)
    text := DOC_NormalizeClipboardLineBreaks(text)
    if (!DOC_SetClipboardTextForEditor(text))
        return false
    Send, ^v
    Sleep, 180

    return true
}


; =========================================================
; ÇÑ ÁÙ Á¤¸®
; =========================================================
DOC_CleanLine(line)
{
    line := DOC_NormalizeHardSpaces(line)
    line := DOC_FixQuickSymbols(line)
    line := DOC_FixBasicTerms(line)
    line := DOC_FixLawBrackets(line)
    line := DOC_FixRelatedItemLawBrackets(line)
    line := DOC_FixDateRangeStrict(line)
    line := DOC_FixMonthDayRange(line)
    line := DOC_FixMonthDayWeekday(line)
    line := DOC_FixDate(line)
    line := DOC_FixDateRangeSeparator(line)
    line := DOC_FixOfficialDocRefDate(line)
    line := DOC_FixOfficialDocTitleBrackets(line)
    line := DOC_FixDateRangeDays(line)
    line := DOC_FixOfficialDocRefDate(line)
    line := DOC_FixTime(line)
    line := DOC_FixDueBlank(line)
    line := DOC_FixMoneyParen(line)
    line := DOC_FixMoney(line)
    line := DOC_FixCalc(line)
    line := DOC_FixSpace(line)
    line := DOC_FinalCleanup(line)
    line := DOC_RemoveLineEndMarker(line)

    return line
}


DOC_NormalizeHardSpaces(text)
{
    text := StrReplace(text, Chr(160), " ")
    text := StrReplace(text, Chr(0x2007), " ")
    text := StrReplace(text, Chr(0x202F), " ")
    text := StrReplace(text, Chr(0x3000), " ")
    return text
}

DOC_FinalCleanup(text)
{
    text := DOC_RemoveEmptyDateParens(text)
    text := DOC_RemoveTempDayText(text)
    text := DOC_FixOfficialDocRefDate(text)
    text := DOC_FixOfficialDocTitleBrackets(text)
    text := DOC_FixLawTailSpacing(text)
    text := DOC_EnsureDayRangeSpace(text)

    return text
}

DOC_RemoveLineEndMarker(line)
{
    ; ¹®¼­ Áß°£ ÁÙ ³¡ÀÇ ³¡Ç¥½Ã´Â °ø¹é ¼ö¿Í ¸¶Ä§Ç¥ À¯¹«¿¡ °ü°è¾øÀÌ Á¦°ÅÇÕ´Ï´Ù.
    ; ÃÖÁ¾ '³¡.'Àº DOC_ProcessText() ¸¶Áö¸· ´Ü°è¿¡¼­ ¹®¼­ ¸Ç ³¡¿¡ ÇÑ ¹ø¸¸ ´Ù½Ã ºÙÀÔ´Ï´Ù.
    t := Trim(line)
    if RegExMatch(t, "^\.?\s*³¡\.?$")
        return ""

    line := RegExReplace(line, "(?:\s*\.\s*|\s+)³¡\.?\s*$", "")
    return RTrim(line)
}

DOC_RemoveSelectionEndMarker(text)
{
    ; ºí·Ï ÁöÁ¤ Win+F2´Â ¼±ÅÃÇÑ ºÎºÐ¸¸ º¯È¯ÇÏ¹Ç·Î ÃÖÁ¾ ¹®¼­¿ë "³¡."À» ºÙÀÌÁö ¾Ê½À´Ï´Ù.
    text := RegExReplace(text, "(?:^|\s*\.\s*|\s+)³¡\.?\s*$", "")
    return RTrim(text)
}

DOC_FixQuickSymbols(line)
{
    ; ÁÙ ¾Õ ¾à½Ä ±âÈ£ º¯È¯
    line := RegExReplace(line, "^(\s*)¤·1(\s+|$)", "$1¨ç$2")
    line := RegExReplace(line, "^(\s*)¤·2(\s+|$)", "$1¨è$2")
    line := RegExReplace(line, "^(\s*)¤·3(\s+|$)", "$1¨é$2")
    line := RegExReplace(line, "^(\s*)¤·¤¡(\s+|$)", "$1¨±$2")
    line := RegExReplace(line, "^(\s*)¤·¤¤(\s+|$)", "$1¨²$2")
    line := RegExReplace(line, "^(\s*)¤·¤§(\s+|$)", "$1¨³$2")
    line := RegExReplace(line, "^(\s*)Ã¼Å©(\s+|$)", "$1?$2")
    line := RegExReplace(line, "^(\s*)º°(\s+|$)", "$1¡Ù$2")
    line := RegExReplace(line, "^(\s*)¼Õ(\s+|$)", "$1¢Ñ$2")
    line := RegExReplace(line, "^(\s*)¤±(\s+|$)", "$1¡à$2")
    line := RegExReplace(line, "^(\s*)¤²(\s+|$)", "$1¡á$2")
    line := RegExReplace(line, "^(\s*)¤·(\s+|$)", "$1¡Û$2")
    line := RegExReplace(line, "^(\s*)¤¡(\s+|$)", "$1¡¤$2")
    line := RegExReplace(line, "^(\s*)¤µ(\s+|$)", "$1¡â$2")
    line := RegExReplace(line, "^(\s*)¤¸(\s+|$)", "$1¡Ø$2")
    line := RegExReplace(line, "(¡Ø\s*¿ìÃµ)\s+½Ã", "$1½Ã")

    ; ¼ýÀÚ µÚ ´ÜÀ§ º¯È¯
    line := RegExReplace(line, "i)([0-9][0-9,]*(?:\.[0-9]+)?)\s*cm2\b", "$1§²")
    line := RegExReplace(line, "i)([0-9][0-9,]*(?:\.[0-9]+)?)\s*km2\b", "$1§´")
    line := RegExReplace(line, "i)([0-9][0-9,]*(?:\.[0-9]+)?)\s*m2\b", "$1§³")
    line := RegExReplace(line, "i)([0-9][0-9,]*(?:\.[0-9]+)?)\s*m3\b", "$1§©")
    line := RegExReplace(line, "i)([0-9][0-9,]*(?:\.[0-9]+)?)\s*ml\b", "$1§¢")
    line := RegExReplace(line, "([0-9][0-9,]*(?:\.[0-9]+)?)\s*µµ\b", "$1¡É")

    ; È­»ìÇ¥ º¯È¯Àº ±ä ÆÐÅÏºÎÅÍ Ã³¸®ÇÕ´Ï´Ù.
    line := StrReplace(line, "<->", "¡ê")
    line := StrReplace(line, "->>", "¢¡")
    line := StrReplace(line, "<<-", "?")
    line := StrReplace(line, "->", "¡æ")
    line := StrReplace(line, "<-", "¡ç")

    return line
}

DOC_EnsureDayRangeSpace(text)
{
    ; ', NÀÏ°£' µÚ¿¡ ¹Ù·Î ½Ã°£ÀÌ ºÙ´Â °æ¿ì ¹Ýµå½Ã ÇÑ Ä­ ¶ç¿ó´Ï´Ù.
   ; ¿¹: ', 1ÀÏ°£14:20' ¡æ ', 1ÀÏ°£ 14:20'
    text := RegExReplace(text, "(,\s*[0-9,]+ÀÏ°£)(?=\S)", "$1 ")
    return text
}

DOC_FormatSelectedTimeRange(text)
{
    t := Trim(text)
    t := StrReplace(t, "`r", "")
    t := StrReplace(t, "`n", "")
    t := RegExReplace(t, "\s+", "")
    t := RegExReplace(t, "\([^)]*½Ã°£[^)]*\)\s*$", "")

    if !RegExMatch(t, "^(\d{1,2}):(\d{2})~(\d{1,2}):(\d{2})$", m)
        return ""

    sh := m1 + 0
    sm := m2 + 0
    eh := m3 + 0
    em := m4 + 0

    if (sh < 0 || sh > 23 || eh < 0 || eh > 23 || sm < 0 || sm > 59 || em < 0 || em > 59)
        return ""

    startMin := sh * 60 + sm
    endMin := eh * 60 + em
    if (endMin < startMin)
        endMin += 24 * 60

    diff := endMin - startMin
    h := Floor(diff / 60)
    mi := Mod(diff, 60)

    duration := ""
    if (h > 0)
        duration .= h . "½Ã°£"
    if (mi > 0)
    {
        if (duration != "")
            duration .= " "
        duration .= mi . "ºÐ"
    }
    if (duration = "")
        duration := "0ºÐ"

    return Format("{:02}", sh) . ":" . Format("{:02}", sm) . "~" . Format("{:02}", eh) . ":" . Format("{:02}", em) . "(" . duration . ")"
}


; =========================================================
; Win+F5 ¼±ÅÃ¿µ¿ª ÀÚµ¿ ÆÇº°: ¼ýÀÚ / ³¯Â¥
; =========================================================
DOC_IsPlainNumber(text)
{
    t := Trim(text)
    t := StrReplace(t, "`r", "")
    t := StrReplace(t, "`n", "")
    t := Trim(t)

    ; ³¯Â¥, ¹®¼­¹øÈ£, °è»ê½ÄÀº ¼ýÀÚ¸¸À¸·Î º¸Áö ¾ÊÀ½
    if InStr(t, ".")
        return false
    if InStr(t, "-")
        return false
    if InStr(t, "/")
        return false
    if InStr(t, "*")
        return false
    if InStr(t, "¡¿")
        return false
    if InStr(t, "+")
        return false
    if InStr(t, "¡À")
        return false

    if RegExMatch(t, "^\s*±Ý?\s*[0-9][0-9,\s]*\s*¿ø?\s*$")
        return true

    return false
}


DOC_FormatPlainMoney(text)
{
    num := RegExReplace(text, "[^\d]", "")

    if (num = "")
        return text

    num := RegExReplace(num, "^0+")
    if (num = "")
        num := "0"

    comma := AddComma(num)
    kor := NumToKor(num)

    return "±Ý" . comma . "¿ø(±Ý" . kor . "¿ø)"
}


DOC_IsPlainDate(text)
{
    y := ""
    m := ""
    d := ""

    if (DOC_TryParsePlainDate(text, y, m, d))
        return true

    return false
}


DOC_FormatPlainDate(text)
{
    y := ""
    m := ""
    d := ""

    if (!DOC_TryParsePlainDate(text, y, m, d))
        return text

    dateValue := BuildDateValue(y, m, d)

    if (dateValue = "")
        return text

    return FormatYmdWithWeekday(dateValue)
}


DOC_TryParsePlainDate(text, ByRef y, ByRef m, ByRef d)
{
    t := Trim(text)
    t := StrReplace(t, "`r", "")
    t := StrReplace(t, "`n", "")
    t := Trim(t)

    ; ¾Õ¿¡ ºÙÀº ÀÛÀºµû¿ÈÇ¥ µî Á¦°Å: '26. 4. 7. / ¡®26. 4. 7.
    t := RegExReplace(t, "^[^0-9]+", "")

    ; 2026³â 4¿ù 7ÀÏ
    if RegExMatch(t, "^(\d{2,4})\s*³â\s*(\d{1,2})\s*¿ù\s*(\d{1,2})\s*ÀÏ?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*\.?\s*$", mm)
    {
        y := mm1
        m := mm2
        d := mm3
        y := DOC_NormalizeYear(y)
        return DOC_IsValidSimpleDate(y, m, d)
    }

    ; 2026. 4. 7. / 26. 4. 7. / 2026-4-7 / 2026/4/7
    if RegExMatch(t, "^(\d{2,4})\s*[\./-]\s*(\d{1,2})\s*[\./-]\s*(\d{1,2})\s*\.?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*$", mm)
    {
        y := mm1
        m := mm2
        d := mm3
        y := DOC_NormalizeYear(y)
        return DOC_IsValidSimpleDate(y, m, d)
    }

    ; 4. 7. Ã³·³ ¿ù/ÀÏ¸¸ ¼±ÅÃÇÑ °æ¿ì: ¿ÃÇØ ±âÁØ
    if RegExMatch(t, "^(\d{1,2})\s*\.\s*(\d{1,2})\s*\.?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*$", mm)
    {
        y := GetYear()
        m := mm1
        d := mm2
        return DOC_IsValidSimpleDate(y, m, d)
    }

    return false
}


DOC_NormalizeYear(y)
{
    y := y + 0

    if (y < 100)
    {
        ; 30 ÃÊ°ú¸é 1900³â´ë, ÀÌÇÏ¸é 2000³â´ë·Î Ã³¸®
        y := (y > 30) ? 1900 + y : 2000 + y
    }

    return y
}


DOC_IsValidSimpleDate(y, m, d)
{
    y := y + 0
    m := m + 0
    d := d + 0

    if (y < 1900 || y > 2099)
        return false
    if (m < 1 || m > 12)
        return false
    if (d < 1 || d > 31)
        return false

    return true
}


DOC_FixBasicTerms(line)
{
    line := StrReplace(line, "°áÁ¦¹Ù¶ø´Ï´Ù", "°áÀç ¹Ù¶ø´Ï´Ù")
    line := StrReplace(line, "°áÁ¦ ¹Ù¶ø´Ï´Ù", "°áÀç ¹Ù¶ø´Ï´Ù")
    line := StrReplace(line, "°áÀç¹Ù¶ø´Ï´Ù", "°áÀç ¹Ù¶ø´Ï´Ù")
    line := StrReplace(line, "½ÅÃ»¹Ù¶ø´Ï´Ù", "½ÅÃ» ¹Ù¶ø´Ï´Ù")
    line := StrReplace(line, "Á¦Ãâ¹Ù¶ø´Ï´Ù", "Á¦Ãâ ¹Ù¶ø´Ï´Ù")
    line := StrReplace(line, "Âü¼®¹Ù¶ø´Ï´Ù", "Âü¼® ¹Ù¶ø´Ï´Ù")
    line := StrReplace(line, "³â¿ùÀÏ", "¿¬¿ùÀÏ")
    line := StrReplace(line, "ÀÏÂ¥", "ÀÏÀÚ")
    line := StrReplace(line, "±¸¸ÅÇÏ°íÀÚ ÇÕ´Ï´Ù", "±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù")
    line := StrReplace(line, "±¸¸ÅÇÏ°íÀÚ", "±¸ÀÔÇÏ°íÀÚ")
    line := StrReplace(line, "°ú¾÷ÁöÁö¼­", "°ú¾÷Áö½Ã¼­")
    line := StrReplace(line, "¹æ°úÈÄÇÏ±³", "¹æ°úÈÄÇÐ±³")
    line := StrReplace(line, "¿©ºñÁö±ÞÇÏ°íÀÚ ÇÕ´Ï´Ù", "¿©ºñ¸¦ Áö±ÞÇÏ°íÀÚ ÇÕ´Ï´Ù")
    line := StrReplace(line, "ÃâÀåºñÁö±ÞÇÏ°íÀÚ ÇÕ´Ï´Ù", "ÃâÀåºñ¸¦ Áö±ÞÇÏ°íÀÚ ÇÕ´Ï´Ù")
    line := DOC_RemoveDateUnitCommas(line)

    return line
}

DOC_RemoveDateUnitCommas(line)
{
    line := RegExReplace(line, "(\d),(?=\d{3}\s*(ÇÐ³âµµ|³âµµ|³â))", "$1")
    line := RegExReplace(line, "(\d),(?=\d{1,2}\s*(¿ù|ÀÏ))", "$1")
    return line
}
; =========================================================
; °ü·Ã ¹ý·É¸í ÀÚµ¿ °ýÈ£ º¸Á¤
; ¿¹1: °ü·Ã: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ±³À°ºñÆ¯º°È¸°è Àç¹«È¸°è±ÔÄ¢ Á¦4Á¶
;      ¡æ °ü·Ã: ¡¸¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ±³À°ºñÆ¯º°È¸°è Àç¹«È¸°è±ÔÄ¢¡¹Á¦4Á¶
; ¿¹2: °ü·Ã: µµ´ãÁßÇÐ±³-2935(2026. 3. 18.), ÀÚÄ¡¹ý ±ÔÄ¢ Á¦2Á¶
;      ¡æ °ü·Ã: µµ´ãÁßÇÐ±³-2935(2026. 3. 18.), ¡¸ÀÚÄ¡¹ý ±ÔÄ¢¡¹Á¦2Á¶
; =========================================================
DOC_FixLawBrackets(line)
{
    ; °ü·Ã: ÁÙÀÌ ¾Æ´Ï¸é Ã³¸®ÇÏÁö ¾ÊÀ½
    if !RegExMatch(line, "°ü·Ã\s*:")
        return line

    ; °ü·Ã ÁÙ ¾È¿¡ ¹®¼­¹øÈ£¿Í ¹ý·ÉÀÌ ÇÔ²² ÀÖ¾îµµ ¹ý·É ºÎºÐ¸¸ Ã£¾Æ¼­ º¸Á¤
    lawPattern := "([,£¬]\s*|°ü·Ã\s*:\s*|\s+(?!°ü·Ã\s*:))([^,£¬¡¸¡¹\r\n]*?(?:½ÃÇà·É|½ÃÇà±ÔÄ¢|¹ý·ü|¹ý|Á¶·Ê|±ÔÄ¢|±ÔÁ¤|ÁöÄ§|±âÁØ|ÈÆ·É|¿¹±Ô|°í½Ã))\s*(Á¦\s*[0-9¡Û?]+\s*(?:Á¶|È£|Ç×|¸ñ))"

    result := ""
    pos := 1
    changed := false

    while (RegExMatch(line, "O)" . lawPattern, mLaw, pos))
    {
        mPos := mLaw.Pos(0)
        mLen := mLaw.Len(0)

        prefix := mLaw.Value(1)
        lawName := Trim(mLaw.Value(2))
        tail := mLaw.Value(3)

        ; ÀÌ¹Ì ¡¸¡¹°¡ ÀÖ°Å³ª ¹®¼­¹øÈ£Ã³·³ º¸ÀÌ¸é °Çµå¸®Áö ¾ÊÀ½
        shouldSkip := false
        if (lawName = "")
            shouldSkip := true
        if InStr(lawName, "-")
            shouldSkip := true
        if RegExMatch(lawName, "\d{2,4}\s*\.")
            shouldSkip := true
        if InStr(lawName, "(")
            shouldSkip := true
        if InStr(lawName, ")")
            shouldSkip := true
        if InStr(lawName, "°ü·Ã:")
            shouldSkip := true

        result .= SubStr(line, pos, mPos - pos)

        if (shouldSkip)
        {
            result .= SubStr(line, mPos, mLen)
        }
        else
        {
            tail := RegExReplace(tail, "Á¦\s+", "Á¦")
            tail := RegExReplace(tail, "\s+(Á¶|È£|Ç×|¸ñ)", "$1")
            result .= prefix . "¡¸" . lawName . "¡¹" . tail
            changed := true
        }

        pos := mPos + mLen
    }

    if (changed)
    {
        result .= SubStr(line, pos)
        return result
    }

    ; ÇÑ ÁÙ ÀüÃ¼°¡ °ü·Ã ¹ý·É ÇÏ³ª¸¸ ÀÖ´Â ±âÁ¸ ¹æ½Äµµ À¯Áö
    if RegExMatch(line, "^(.*°ü·Ã\s*:\s*)([^¡¸¡¹]*?(?:½ÃÇà·É|½ÃÇà±ÔÄ¢|¹ý·ü|¹ý|Á¶·Ê|±ÔÄ¢|±ÔÁ¤|ÁöÄ§|±âÁØ|ÈÆ·É|¿¹±Ô|°í½Ã))\s*(Á¦\s*[0-9¡Û?]+\s*(?:Á¶|È£|Ç×|¸ñ).*)$", mLaw2)
    {
        prefix2 := mLaw21
        lawName2 := Trim(mLaw22)
        tail2 := mLaw23
        tail2 := RegExReplace(tail2, "Á¦\s+", "Á¦")
        tail2 := RegExReplace(tail2, "\s+(Á¶|È£|Ç×|¸ñ)", "$1")

        if (lawName2 != "" && !InStr(lawName2, "-") && !InStr(lawName2, "(") && !InStr(lawName2, ")") && !InStr(lawName2, "°ü·Ã:"))
            return prefix2 . "¡¸" . lawName2 . "¡¹" . tail2
    }

    return line
}


; =========================================================
; °ü·Ã Ç×¸ñ ¹ý·É¸í ÀÚµ¿ ²ª¼è º¸Á¤
; ¿¹:   °¡. °í¿ëº¸Çè¹ý ½ÃÇà·É Á¦7Á¶
;    -> °¡. ¡¸°í¿ëº¸Çè¹ý ½ÃÇà·É¡¹ Á¦7Á¶
; - 1. °ü·Ã: ¾Æ·¡¿¡ ¾²´Â °¡./³ª./´Ù. ¹ý·É ±Ù°Å ÁÙ º¸°­¿ë
; - ÀÌ¹Ì ¡¸¡¹°¡ ÀÖÀ¸¸é °Çµå¸®Áö ¾ÊÀ½
; =========================================================
DOC_FixRelatedItemLawBrackets(line)
{
    if InStr(line, "¡¸")
        return line

    ; °¡. / ³ª. / 1) / - µî ¸ñ·Ï Ç¥Áö ´ÙÀ½¿¡ ¹ý·É¸íÀÌ ¹Ù·Î ¿À´Â °æ¿ì¸¸ Ã³¸®ÇÕ´Ï´Ù.
    itemPat := "^(\s*(?:[°¡-ÆR]\.\s*|[0-9]+\)\s*|-\s*))([^,£¬:£º¡¸¡¹\r\n]*?(?:½ÃÇà·É|½ÃÇà±ÔÄ¢|¹ý·ü|¹ý|Á¶·Ê|±ÔÄ¢|±ÔÁ¤|ÁöÄ§|±âÁØ|ÈÆ·É|¿¹±Ô|°í½Ã))\s*(Á¦\s*[0-9¡Û?]+\s*(?:Á¶|È£|Ç×|¸ñ).*)$"

    if RegExMatch(line, itemPat, mLawItem)
    {
        prefix := mLawItem1
        lawName := Trim(mLawItem2)
        tail := mLawItem3

        ; ¹®¼­¹øÈ£¡¤³¯Â¥¡¤°ýÈ£°¡ ¼¯ÀÎ ÁÙÀº ¾ÈÀüÇÏ°Ô Á¦¿ÜÇÕ´Ï´Ù.
        if (lawName = "")
            return line
        if InStr(lawName, "-")
            return line
        if InStr(lawName, "(") || InStr(lawName, ")")
            return line
        if RegExMatch(lawName, "\d{2,4}\s*\.")
            return line

        tail := RegExReplace(tail, "Á¦\s+", "Á¦")
        tail := RegExReplace(tail, "\s+(Á¶|È£|Ç×|¸ñ)", "$1")
        return prefix . "¡¸" . lawName . "¡¹ " . tail
    }

    return line
}



; =========================================================
; ¹ý·É ²ª¼è µÚ Á¶¹® ¶ç¾î¾²±â º¸Á¤
; ¿¹: ¡¸¹ý¡¹Á¦1È£ -> ¡¸¹ý¡¹ Á¦1È£
; =========================================================
DOC_FixLawTailSpacing(text)
{
    text := RegExReplace(text, "¡¹\s*(Á¦\s*[0-9¡Û?])", "¡¹ $1")
    text := RegExReplace(text, "¡¹\s*(Á¦\s*[°¡-ÆRA-Za-z])", "¡¹ $1")
    return text
}

; =========================================================
; °ø¹®¹øÈ£ ¿À¸¥ÂÊ Á¦¸ñ ²ª¼è º¸Á¤
; ¿¹: µµ´ãÁßÇÐ±³-4813(2026. 4. 23.) ³»¿ë
;     -> µµ´ãÁßÇÐ±³-4813(2026. 4. 23.) ¡¸³»¿ë¡¹
; - ÁÙ ¾ÕÀÇ 1. / °¡. / 1) µî Ç×¸ñ¹øÈ£´Â Àý´ë ²ª¼è Ã³¸®ÇÏÁö ¾ÊÀ½
; - ÀÌ¹Ì ¡¸¡¹°¡ ÀÖÀ¸¸é °Çµå¸®Áö ¾ÊÀ½
; =========================================================
DOC_FixOfficialDocTitleBrackets(line)
{
    ; ---------------------------------------------------------
    ; °ø¹®¹øÈ£ ¿À¸¥ÂÊ Á¦¸ñ ²ª¼è ÃÖÁ¾ º¸Á¤
    ; ¿¹) °¡. °¨»ç°ü-2768(2021. 5. 14.) 1ºÎ¼­ °úÁ¦
    ;     ¡æ °¡. °¨»ç°ü-2768(2021. 5. 14.) ¡¸1ºÎ¼­ °úÁ¦¡¹
    ; ¿¹) 1. °ü·Ã: µµ´ãÁßÇÐ±³-4813(2026. 4. 23.) ³»¿ë
    ;     ¡æ 1. °ü·Ã: µµ´ãÁßÇÐ±³-4813(2026. 4. 23.) ¡¸³»¿ë¡¹
    ; ---------------------------------------------------------

    line := DOC_FixLawTailSpacing(line)

    ; °ú°Å ¿ÀÀÛµ¿À¸·Î »ý±ä Ç×¸ñ¹øÈ£ ²ª¼è º¹±¸: ¡¸°¡.¡¹ ¡æ °¡. / ¡¸1)¡¹ ¡æ 1)
    line := RegExReplace(line, "¡¸\s*([°¡-ÆR])\.\s*¡¹", "$1.")
    line := RegExReplace(line, "¡¸\s*([0-9]+)\.\s*¡¹", "$1.")
    line := RegExReplace(line, "¡¸\s*([0-9]+)\)\s*¡¹", "$1)")
    line := RegExReplace(line, "¡¸\s*([°¡-ÆR])\)\s*¡¹", "$1)")

    ; ¡¸¹ý¡¹Á¦1È£ ¡æ ¡¸¹ý¡¹ Á¦1È£ °°Àº ¹ý·É Á¶¹® ¶ç¾î¾²±â Àçº¸Á¤
    line := DOC_FixLawTailSpacing(line)

    ; °ø¹®¹øÈ£ + ³¯Â¥ ÆÐÅÏ
    ; ±â°ü¸í-¹®¼­¹øÈ£(yyyy. m. d.) µÚ¿¡ Á¦¸ñÀÌ ºÙ°Å³ª ¶ç¾îÁ® ÀÖÀ¸¸é Á¦¸ñ¸¸ ²ª¼è Ã³¸®
    docPat := "[°¡-ÆRA-Za-z0-9_¡Û?]+-[°¡-ÆRA-Za-z0-9_¡Û?\-]+\(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.\)"

    ; ÀÌ¹Ì ²ª¼è°¡ ÀÖ´Â °æ¿ì: °ø¹®¹øÈ£¿Í ¡¸ »çÀÌ¸¦ ÇÑ Ä­À¸·Î Á¤¸®
    line := RegExReplace(line, "(" . docPat . ")\s*¡¸", "$1 ¡¸")

    ; °ø¹®¹øÈ£ µÚ Á¦¸ñÀÌ ¾ÆÁ÷ ²ª¼è Ã³¸®µÇÁö ¾ÊÀº °æ¿ì
    if RegExMatch(line, "^(.*" . docPat . ")\s*([^¡¸¡¹\r\n]+)$", m)
    {
        before := m1
        title := Trim(m2)

        ; Á¦¸ñÀÌ ºñ¾î ÀÖ°Å³ª Ç×¸ñ¹øÈ£/±¸µÎÁ¡»ÓÀÌ¸é Á¦¿Ü
        if (title != "" 
            && !RegExMatch(title, "^[,£¬.¡£\s]+$")
            && !RegExMatch(title, docPat)
            && !RegExMatch(title, "^[,£¬]\s*[°¡-ÆRA-Za-z0-9_¡Û?]+-[°¡-ÆRA-Za-z0-9_¡Û?\-]+\(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.\)\s*$")
            && !RegExMatch(title, "^([°¡-ÆR]\.|[0-9]+\.|[0-9]+\)|[°¡-ÆR]\))\s*$"))
        {
            ; Á¦¸ñ ³¡¿¡ Àß¸ø ºÙÀº ³¡.Àº ¿©±â¼­ Á¦¸ñÀ¸·Î °¨½ÎÁö ¾ÊÀ½
            title := RegExReplace(title, "\s*\.\s*³¡\.\s*$", "")
            title := RegExReplace(title, "\s*³¡\.\s*$", "")
            title := Trim(title)

            if (title != "")
                return before . " ¡¸" . title . "¡¹"
        }
    }

    return line
}

DOC_FixDateRangeStrict(line)
{
    dateOne := "([`'¡®¡¯]?)(\d{2,4})\s*\.\s*(\d{1,2})\s*\.\s*(\d{1,2})\s*\.?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*(\(\))?"
    patternShortEnd := dateOne . "\s*[-~]\s*(\d{1,2})\s*\.\s*(\d{1,2})\s*\.?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*(\(\))?"

    pos := 1
    while pos := RegExMatch(line, patternShortEnd, m, pos)
    {
        sy := m2
        sm := m3
        sd := m4
        ey := sy
        em := m7
        ed := m8

        if (StrLen(sy) = 2)
            sy := DOC_NormalizeYear(sy)
        ey := sy

        d1 := BuildDateValue(sy, sm, sd)
        d2 := BuildDateValue(ey, em, ed)
        if (d1 = "" || d2 = "")
        {
            pos += StrLen(m)
            continue
        }

        if (d2 < d1)
        {
            ey := sy + 1
            d2 := BuildDateValue(ey, em, ed)
        }

        diff := d2
        EnvSub, diff, %d1%, Days
        totalDays := diff + 1
        if (totalDays <= 0)
        {
            pos += StrLen(m)
            continue
        }

        replacement := FormatDateRangeWithWeekdays(d1, d2, totalDays)
        line := SubStr(line, 1, pos - 1) . replacement . SubStr(line, pos + StrLen(m))
        pos += StrLen(replacement)
    }

    pattern := dateOne . "\s*[-~]\s*" . dateOne

    pos := 1
    while pos := RegExMatch(line, pattern, m, pos)
    {
        sy := m2
        sm := m3
        sd := m4
        ey := m8
        em := m9
        ed := m10

        if (StrLen(sy) = 2)
            sy := DOC_NormalizeYear(sy)
        if (StrLen(ey) = 2)
            ey := DOC_NormalizeYear(ey)

        d1 := BuildDateValue(sy, sm, sd)
        d2 := BuildDateValue(ey, em, ed)
        if (d1 = "" || d2 = "")
        {
            pos += StrLen(m)
            continue
        }

        if (d2 < d1)
        {
            ey := sy + 1
            d2 := BuildDateValue(ey, em, ed)
        }

        diff := d2
        EnvSub, diff, %d1%, Days
        totalDays := diff + 1
        if (totalDays <= 0)
        {
            pos += StrLen(m)
            continue
        }

        replacement := FormatDateRangeWithWeekdays(d1, d2, totalDays)
        line := SubStr(line, 1, pos - 1) . replacement . SubStr(line, pos + StrLen(m))
        pos += StrLen(replacement)
    }

    return line
}


DOC_FixMonthDayRange(line)
{
    FormatTime, y,, yyyy
    pos := 1
    pattern := "(^|[^0-9\.])(\d{1,2})\s*\.\s*(\d{1,2})\s*\.?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*[-~]\s*(\d{1,2})\s*\.\s*(\d{1,2})\s*\.?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*(?:,\s*[\d,]+\s*ÀÏ°£|\(\s*ÃÑ\s*[\d,]+\s*ÀÏ\s*\)|\(\s*[\d,]+\s*ÀÏ°£\s*\))?"

    while pos := RegExMatch(line, pattern, m, pos)
    {
        prefix := m1
        sm := m2 + 0
        sd := m3 + 0
        em := m5 + 0
        ed := m6 + 0
        monthPos := pos + StrLen(prefix)
        beforeMonth := SubStr(line, 1, monthPos - 1)

        if RegExMatch(beforeMonth, "\d{2,4}\s*\.\s*$")
        {
            pos += StrLen(m)
            continue
        }

        sy := y
        ey := y
        d1 := BuildDateValue(sy, sm, sd)
        d2 := BuildDateValue(ey, em, ed)
        if (d1 = "" || d2 = "")
        {
            pos += StrLen(m)
            continue
        }

        if (d2 < d1)
        {
            ey := sy + 1
            d2 := BuildDateValue(ey, em, ed)
        }

        diff := d2
        EnvSub, diff, %d1%, Days
        totalDays := diff + 1
        if (totalDays <= 0)
        {
            pos += StrLen(m)
            continue
        }

        FormatTime, swd, %d1%, WDay
        FormatTime, ewd, %d2%, WDay
        days := ["ÀÏ","¿ù","È­","¼ö","¸ñ","±Ý","Åä"]
        replacement := prefix . sm . ". " . sd . ".(" . days[swd] . ")~" . em . ". " . ed . ".(" . days[ewd] . "), " . AddComma(totalDays) . "ÀÏ°£"

        line := SubStr(line, 1, pos - 1) . replacement . SubStr(line, pos + StrLen(m))
        pos += StrLen(replacement)
    }

    return line
}

DOC_FixMonthDayWeekday(line)
{
    FormatTime, y,, yyyy
    pos := 1
    pattern := "(^|[^0-9\.])(\d{1,2})\s*\.\s*(\d{1,2})\s*\.?\s*\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\)"

    while pos := RegExMatch(line, pattern, m, pos)
    {
        prefix := m1
        mon := m2 + 0
        day := m3 + 0
        monthPos := pos + StrLen(prefix)
        beforeMonth := SubStr(line, 1, monthPos - 1)

        if RegExMatch(beforeMonth, "\d{2,4}\s*\.\s*$")
        {
            pos += StrLen(m)
            continue
        }

        dateValue := BuildDateValue(y, mon, day)
        if (dateValue = "")
        {
            pos += StrLen(m)
            continue
        }

        FormatTime, wd, %dateValue%, WDay
        days := ["ÀÏ","¿ù","È­","¼ö","¸ñ","±Ý","Åä"]
        replacement := prefix . mon . ". " . day . ".(" . days[wd] . ")"

        line := SubStr(line, 1, pos - 1) . replacement . SubStr(line, pos + StrLen(m))
        pos += StrLen(replacement)
    }

    return line
}

DOC_FixDate(line)
{
    pos := 1

    while pos := RegExMatch(line, "([`'¡®¡¯]?)(\d{2,4})\s*\.\s*(\d{1,2})\s*\.\s*(\d{1,2})\s*\.?\s*(\((?:[¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]|¿äÀÏ)\))?\s*(\(\))?", m, pos)
    {
        quote := m1
        y := m2
        mon := m3 + 0
        day := m4 + 0
        emptyParen := m6

        if (mon < 1 || mon > 12 || day < 1 || day > 31)
        {
            pos += StrLen(m)
            continue
        }

        if (StrLen(y) = 2)
            y := DOC_NormalizeYear(y)

        mon2 := mon < 10 ? "0" . mon : mon
        day2 := day < 10 ? "0" . day : day

        dateValue := y . mon2 . day2
        FormatTime, wd, %dateValue%, WDay
        days := ["ÀÏ","¿ù","È­","¼ö","¸ñ","±Ý","Åä"]

        if (quote != "" || emptyParen != "")
            replacement := y . ". " . mon . ". " . day . "."
        else
            replacement := y . ". " . mon . ". " . day . ".(" . days[wd] . ")"

        line := SubStr(line, 1, pos - 1) . replacement . SubStr(line, pos + StrLen(m))
        pos += StrLen(replacement)
    }

    line := DOC_RemoveEmptyDateParens(line)
    return line
}


DOC_FixDateRangeSeparator(line)
{
    datePat := "(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.(?:\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\))?)"
    line := RegExReplace(line, datePat . "\s*[-~]\s*" . datePat, "$1~$2")
    return line
}


DOC_FixOfficialDocRefDate(line)
{
    ; ÀÏ¹Ý °ø¹®¹øÈ£: µµ´ãÁßÇÐ±³-15140(2025. 12. 24.(¼ö)) ¡æ µµ´ãÁßÇÐ±³-15140(2025. 12. 24.)
    line := RegExReplace(line, "([°¡-ÆRA-Za-z¡Û0-9]+-[°¡-ÆRA-Za-z¡Û0-9\-]+)\((\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)\)", "$1($2)")
    line := RegExReplace(line, "(-[°¡-ÆRA-Za-z¡Û0-9\-]+)\((\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)\)", "$1($2)")

    ; °ýÈ£ ¾È ½°Ç¥Çü °ø¹®¹øÈ£: (±³À°½Ã¼³°ú-1000, 2000. 1. 1.(Åä)) ¡æ (±³À°½Ã¼³°ú-1000, 2000. 1. 1.)
    line := RegExReplace(line, "\(([°¡-ÆRA-Za-z¡Û0-9]+-[°¡-ÆRA-Za-z¡Û0-9\-]+)\s*,\s*(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)\)", "($1, $2)")

    ; ½°Ç¥Çü °ø¹®¹øÈ£ ÀÏºÎ¸¸ ¼±ÅÃµÈ °æ¿ìµµ º¸È£
    line := RegExReplace(line, "([°¡-ÆRA-Za-z¡Û0-9]+-[°¡-ÆRA-Za-z¡Û0-9\-]+)\s*,\s*(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)", "$1, $2")

    ; Ãß°¡ º¸È£: (µµ´ãÁß-1212, 2026.1.1.(¸ñ))Ã³·³ ³¯Â¥ »çÀÌ °ø¹éÀÌ ÀüÇô ¾ø´Â °ø¹®¹øÈ£µµ ¿äÀÏ Á¦°Å
    ; À§ Á¤±Ô½Äµµ ´ëºÎºÐ Ã³¸®ÇÏÁö¸¸, °ø¹®¼­ ÇöÀå ÀÔ·ÂÇüÀ» ¸í½ÃÀûÀ¸·Î ÇÑ ¹ø ´õ º¸È£ÇÕ´Ï´Ù.
    line := RegExReplace(line, "\(([°¡-ÆRA-Za-z¡Û0-9]+-[°¡-ÆRA-Za-z¡Û0-9\-]+)\s*,\s*(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)\)", "($1, $2)")
    line := RegExReplace(line, "([°¡-ÆRA-Za-z¡Û0-9]+-[°¡-ÆRA-Za-z¡Û0-9\-]+)\s*,\s*(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)", "$1, $2")
    return line
}


DOC_RemoveEmptyDateParens(line)
{
    line := RegExReplace(line, "(\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\))\s*\(\s*\)", "$1")
    line := RegExReplace(line, "(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\s*\(\s*\)", "$1")
    line := RegExReplace(line, "(\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\))\s*\(\s*\)", "$1")
    line := RegExReplace(line, "(\d{4}\.\s*\d{1,2}\.\s*\d{1,2}\.)\s*\(\s*\)", "$1")
    return line
}


DOC_FixDateRangeDays(line)
{
    line := DOC_RemoveEmptyDateParens(line)

    ; ±âÁ¸ NÀÏ°£ Ç¥±â°¡ ÀÖ¾îµµ ¹«½ÃÇÏÁö ¾Ê°í, ³¯Â¥ ¹üÀ§ ±âÁØÀ¸·Î ´Ù½Ã °è»êÇÕ´Ï´Ù.
    ; ´Ü, ³¯Â¥ ¹üÀ§°¡ ¾ø´Â ÁÙÀÇ ÀÏ¹Ý ¹®±¸´Â ÃÖ´ëÇÑ °Çµå¸®Áö ¾Ê½À´Ï´Ù.
    originalLine := line
    calcLine := DOC_RemoveTempDayText(line)
    calcLine := RegExReplace(calcLine, "\s*,\s*[\d,]+\s*ÀÏ°£", "")
    calcLine := RegExReplace(calcLine, "\s*\(\s*ÃÑ\s*[\d,]+\s*ÀÏ\s*\)", "")
    calcLine := RegExReplace(calcLine, "\s*\(\s*[\d,]+\s*ÀÏ°£\s*\)", "")

    pattern := "(\d{4})\.\s*(\d{1,2})\.\s*(\d{1,2})\.\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)\s*~\s*(?:(\d{4})\.\s*)?(\d{1,2})\.\s*(\d{1,2})\.\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\)"

    if RegExMatch(calcLine, pattern, m)
    {
        sy := m1
        sm := m2
        sd := m3
        ey := m4
        em := m5
        ed := m6
        if (ey = "")
            ey := sy

        d1 := BuildDateValue(sy, sm, sd)
        d2 := BuildDateValue(ey, em, ed)

        if (d1 != "" && d2 != "")
        {
            if (d2 < d1)
            {
                ey := sy + 1
                d2 := BuildDateValue(ey, em, ed)
            }

            diff := d2
            EnvSub, diff, %d1%, Days
            totalDays := diff + 1

            if (totalDays > 0)
            {
                old := m
                new := FormatDateRangeWithWeekdays(BuildDateValue(sy, sm, sd), BuildDateValue(ey, em, ed), totalDays)
                calcLine := StrReplace(calcLine, old, new)
                calcLine := DOC_RemoveEmptyDateParens(calcLine)
                calcLine := DOC_RemoveTempDayText(calcLine)
                return calcLine
            }
        }
    }

    originalLine := DOC_RemoveEmptyDateParens(originalLine)
    originalLine := DOC_RemoveTempDayText(originalLine)

    return originalLine
}



DOC_RemoveTempDayText(line)
{
    line := DOC_RemoveEmptyDateParens(line)

    ; ±âÁ¸ ±â°£ Ç¥±â¸¦ »õ Ç¥±â Çü½ÄÀ¸·Î ÅëÀÏÇÕ´Ï´Ù.
    line := RegExReplace(line, "\s*\(\s*ÃÑ\s*([\d,]+)\s*ÀÏ\s*\)", ", $1ÀÏ°£")
    line := RegExReplace(line, "\s*\(\s*([\d,]+)\s*ÀÏ°£\s*\)", ", $1ÀÏ°£")
    line := RegExReplace(line, "\s*,\s*([\d,]+)\s*ÀÏ°£\s*[, ]+\s*\1\s*ÀÏ°£", ", $1ÀÏ°£")

    line := RegExReplace(line, "\(\s*¡Û+\s*ÀÏ°£\s*\)", "")
    line := RegExReplace(line, "\(\s*0+\s*ÀÏ°£\s*\)", "")
    line := RegExReplace(line, "\(\s*O+\s*ÀÏ°£\s*\)", "")
    line := RegExReplace(line, "\(\s*o+\s*ÀÏ°£\s*\)", "")

    return line
}


DOC_FixTime(line)
{
    line := RegExReplace(line, "(\d{1,2})\s*:\s*(\d{2})", "$1:$2")
    line := RegExReplace(line, "(\([¿ùÈ­¼ö¸ñ±ÝÅäÀÏ]\))\s*(?=\d{1,2}:\d{2})", "$1 ")
    line := RegExReplace(line, "(\d{1,2}:\d{2})\s*~\s*(\d{1,2}:\d{2})", "$1~$2")
    line := RegExReplace(line, "(\d{1,2}:\d{2})\s*~\s*$", "$1~")
    return line
}


DOC_FixDueBlank(line)
{
    if RegExMatch(line, "(³³Ç°±âÇÑ|¿Ï·á±âÇÑ)\s*:\s*$")
    {
        due := GetDueDate()
        line := RegExReplace(line, ":\s*$", ": " . due)
    }

    return line
}


DOC_FixMoney(line)
{
    if !RegExMatch(line, "(±Ý\s*¾×|ºñ\s*¿ë|ÃÑ¾×|ÃÑ±Ý¾×|°è¾à±Ý¾×|ÀÓÂ÷ºñ|¿ë¿ªºñ|¼Ò¿ä±Ý¾×|¼Ò¿ä¿¹»ê|¿¹\s*»ê|¿¹»ê¾×|»ç¾÷¿¹»ê|¿¹»ó±Ý¾×|ÃßÁ¤±Ý¾×|Áö±Þ±Ý¾×|ÃâÀåºñ|°­»çºñ|ÇùÀÇÈ¸ºñ|¼Ò¿ä°æºñ|¿¹»ó´Ü°¡)")
        return line

    if RegExMatch(line, "»êÃâ³»¿ª|»êÃâ±âÃÊ")
        return line

    if RegExMatch(line, "±Ý\s*¿ø\s*\(±Ý\s*¿ø\)")
        return line

    if RegExMatch(line, "±Ý\s*([0-9][0-9,]*)", m)
        num := RegExReplace(m1, "[^\d]", "")
    else if RegExMatch(line, "([0-9][0-9,]*)\s*¿ø", m)
        num := RegExReplace(m1, "[^\d]", "")
    else if RegExMatch(line, ":\s*([0-9][0-9,]*)(?![0-9,])(?!(\s*)(ÇÐ³âµµ|¿¬µµ|³âµµ|³â|¿ù|ÀÏ|½Ã|ºÐ|ÃÊ|ÇÐ±â))", m)
        num := RegExReplace(m1, "[^\d]", "")
    else
        return line

    if (num = "")
        return line

    num := RegExReplace(num, "^0+")
    if (num = "")
        num := "0"

    comma := AddComma(num)
    kor := NumToKor(num)
    moneyText := "±Ý" . comma . "¿ø(±Ý" . kor . "¿ø)"

    if RegExMatch(line, "±Ý\s*[0-9][0-9,]*\s*¿ø?\s*(\([^)]*\))?")
        line := RegExReplace(line, "±Ý\s*[0-9][0-9,]*\s*¿ø?\s*(\([^)]*\))?", moneyText, , 1)
    else if RegExMatch(line, "[0-9][0-9,]*\s*¿ø\s*(\([^)]*\))?")
        line := RegExReplace(line, "[0-9][0-9,]*\s*¿ø\s*(\([^)]*\))?", moneyText, , 1)
    else
        line := RegExReplace(line, ":\s*[0-9][0-9,]*", ": " . moneyText, , 1)

    return line
}


DOC_FixMoneyParen(line)
{
    ; ¿¹: ±Ý100,000¿ø(±Ý¿µ¿ø) ¡æ ±Ý100,000¿ø(±ÝÀÏ½Ê¸¸¿ø)
    pos := 1
    while pos := RegExMatch(line, "±Ý\s*([0-9][0-9,]*)\s*¿ø?\s*\(\s*±Ý[^)]*¿ø\s*\)", m, pos)
    {
        num := RegExReplace(m1, "[^\d]", "")
        num := RegExReplace(num, "^0+")
        if (num = "")
            num := "0"

        moneyText := "±Ý" . AddComma(num) . "¿ø(±Ý" . NumToKor(num) . "¿ø)"
        line := SubStr(line, 1, pos - 1) . moneyText . SubStr(line, pos + StrLen(m))
        pos += StrLen(moneyText)
    }

    return line
}


DOC_IsOfficialRefLine(text)
{
    t := Trim(text)

    ; 1. °ü·Ã: ÁÙÀº °è»ê½ÄÀ¸·Î º¸Áö ¾ÊÀ½
    if RegExMatch(t, "^\s*\d+\.\s*°ü·Ã\s*:")
        return true

    ; °ü·Ã: À¸·Î ½ÃÀÛÇÏ´Â ÁÙµµ °è»ê½Ä Á¦¿Ü
    if RegExMatch(t, "^\s*°ü·Ã\s*:")
        return true

    ; µµ´ãÁß-4746(2026. 4. 21.) °°Àº °ø½Ä ¹®¼­¹øÈ£ ÆÐÅÏ Á¦¿Ü
    if RegExMatch(t, "[°¡-ÆRA-Za-z¡Û]+-[0-9A-Za-z¡Û\-]+\s*\(")
        return true

    ; ¡Û¡ÛÇÐ±³-0000 °°Àº ¹®¼­¹øÈ£ ÆÐÅÏ Á¦¿Ü
    if RegExMatch(t, "[°¡-ÆRA-Za-z¡Û]+-[0-9A-Za-z¡Û\-]+")
        return true

    return false
}


DOC_HasCalcExpression(text, allowTightMinus := false)
{
    ; ºí·Ï ÁöÁ¤ ´ÜÀÏ ¼±ÅÃÀÏ ¶§´Â »ç¿ëÀÚ°¡ °è»ê ÀÇµµ·Î °í¸¥ °ÍÀ¸·Î º¸°í
    ; ÀÚ¸®¼ö¿Í »ó°ü¾øÀÌ ºÙÀº ¸¶ÀÌ³Ê½º±îÁö °­Á¦ °è»êÇÕ´Ï´Ù.
   ; ¿¹: 116930-115340, 123-45, 010-1234-5678, 900101-1234567
    ; ´Ü, ºí·Ï ¹ÌÁöÁ¤/ÀüÃ¼ Á¤¸®¿¡¼­´Â ¾Æ·¡ º¸È£ ·ÎÁ÷À» ±×´ë·Î À¯ÁöÇÕ´Ï´Ù.
    if (allowTightMinus)
    {
        tForce := Trim(text)
        tForce := StrReplace(tForce, "`r", "")
        tForce := StrReplace(tForce, "`n", "")
        if RegExMatch(tForce, "^[0-9][0-9,]*(\.[0-9]+)?%?\s*[\+\-\*xX¡¿¡À/]\s*[0-9][0-9,]*(\.[0-9]+)?%?(\s*[\+\-\*xX¡¿¡À/]\s*[0-9][0-9,]*(\.[0-9]+)?%?)*\s*=?\s*$")
            return true
    }

    if (DOC_IsOfficialRefLine(text))
        return false

    ; ¹®¼­¹øÈ£ ¿ÀÀÎ ¹æÁö¸¦ À§ÇØ '-'´Â ±âº» °è»ê ¿¬»êÀÚ¿¡¼­ Á¦¿Ü
    ; ´õÇÏ±â/°öÇÏ±â/³ª´©±â À§ÁÖ °è»ê½Ä¸¸ ÀÚµ¿ Ã³¸®
    if RegExMatch(text, "[0-9][0-9,]*%?\s*(¾ï¿ø|Ãµ¸¸¿ø|¹é¸¸¿ø|¸¸¿ø|Ãµ¿ø|¹é¿ø|¿ø|¸í|°³|½Ã°£|ÀÏ|¿ù|È¸|´ë|ºÎ|½Ä|§²|§´|§³|§©|§¢|¡É)*\s*[\+\*xX¡¿¡À/]\s*[0-9]")
        return true

    ; »©±â´Â ¾çÂÊ¿¡ °ø¹éÀÌ ÀÖ´Â °æ¿ì¸¸ °è»ê½ÄÀ¸·Î ÀÎÁ¤
    if RegExMatch(text, "[0-9][0-9,]*%?\s*(¿ø)?\s+\-\s+[0-9]")
        return true

    return false
}


DOC_IsProtectedNumberPattern(text)
{
    t := Trim(text)
    t := StrReplace(t, "`r", "")
    t := StrReplace(t, "`n", "")
    t := RegExReplace(t, "\s+", "")

    ; ÁÖ¹Îµî·Ï¹øÈ£: 6ÀÚ¸®-7ÀÚ¸® ¶Ç´Â 13ÀÚ¸®
    if RegExMatch(t, "^\d{6}-?[1-4]\d{6}$")
        return true

    ; ÈÞ´ëÀüÈ­/ÀÏ¹ÝÀüÈ­/ÆÑ½º/ÀÎÅÍ³ÝÀüÈ­: 010-0000-0000, 044-320-0000 µî
    if RegExMatch(t, "^(01[016789]|02|0[3-6][1-5]|070|050\d)-?\d{3,4}-?\d{4}$")
        return true

    return false
}


DOC_FixCalc(line, allowTightMinus := false)
{
    ; ºí·Ï ÁöÁ¤ °è»êÀº °ø½Ä ¹®¼­¹øÈ£/ÀüÈ­¹øÈ£/ÁÖ¹Î¹øÈ£Ã³·³ º¸¿©µµ
    ; »ç¿ëÀÚ°¡ Á÷Á¢ ¼±ÅÃÇÑ °è»ê½ÄÀ¸·Î º¸°í °­Á¦ °è»êÇÕ´Ï´Ù.
    if (!allowTightMinus && DOC_IsOfficialRefLine(line))
        return line

    if !DOC_HasCalcExpression(line, allowTightMinus)
        return line

    if RegExMatch(line, "^\s*\d{4}\.\s*\d{1,2}\.\s*\d{1,2}")
        return line

    ; ±âÁ¸ ÇÕ°è(=142, =142¿ø µî)°¡ ÀÖ¾îµµ ´Ù½Ã °è»êÇÏ¿© ¿Ã¹Ù¸¥ °ªÀ¸·Î ±³Ã¼ÇÕ´Ï´Ù.
    line := RegExReplace(line, "\s*\.\s*³¡\.\s*$", "")
    line := RegExReplace(line, "\s+³¡\.\s*$", "")
    exprLine := line
    prefix := ""
    expr := exprLine

    if RegExMatch(exprLine, "^(.*?:\s*)(.+)$", mm)
    {
        prefix := mm1
        expr := mm2
    }

    ; È­¸é¿¡ ³²±æ »êÃâ½Ä¿¡¼­´Â ±âÁ¸ =°ªÀ» Á¦°ÅÇÏ°í »õ °è»ê°ª¸¸ ºÙÀÔ´Ï´Ù.
    ; ±âÁ¸ °á°ú°¡ À½¼ö(¿¹: =-5,036)¿´´ø °æ¿ìµµ ±ú²ýÇÏ°Ô Á¦°ÅÇÕ´Ï´Ù.
    exprDisplay := RegExReplace(expr, "\s*=\s*[\+\-]?[0-9,]+(\.[0-9]+)?\s*(¿ø|¸í|°³|½Ã°£|ÀÏ|¿ù|È¸|´ë|ºÎ|½Ä)?\s*$", "")
    exprDisplay := RegExReplace(exprDisplay, "\s*=\s*$", "")
    exprDisplay := DOC_FormatMoneyUnitNumbersInCalcDisplay(exprDisplay)
    cleanExpr := DOC_CleanCalcExpression(exprDisplay)

    if (cleanExpr = "")
        return line

    result := DOC_EvalExpression(cleanExpr)

    if (result = "")
        return line

    resultText := AddCommaDecimal(Round(result, 2))

    if RegExMatch(exprDisplay, "¿ø")
        resultText := resultText . "¿ø"

    return prefix . exprDisplay . "=" . resultText
}


DOC_CleanCalcExpression(expr)
{
    clean := expr
    clean := RegExReplace(clean, "^\s*[¡à¡Û¡¤]\s*", "")
    if RegExMatch(clean, "¡Û")
        return ""
    clean := DOC_ExpandMoneyUnitsInCalcExpr(clean)
    clean := StrReplace(clean, "¡¿", "*")
    clean := StrReplace(clean, "x", "*")
    clean := StrReplace(clean, "X", "*")
    clean := StrReplace(clean, "¡À", "/")
    clean := StrReplace(clean, ",", "")
    clean := RegExReplace(clean, "=.*$")
    clean := RegExReplace(clean, "[°¡-ÆR]+", "")
    clean := RegExReplace(clean, "[^0-9\+\-\*\/\.\(\)%]", "")

    if !RegExMatch(clean, "[\+\-\*\/]")
        return ""

    return clean
}


DOC_FormatMoneyUnitNumbersInCalcDisplay(expr)
{
    pos := 1
    while pos := RegExMatch(expr, "([0-9][0-9,]*)(\s*)(¾ï¿ø|Ãµ¸¸¿ø|¹é¸¸¿ø|¸¸¿ø|Ãµ¿ø|¹é¿ø|¿ø)", m, pos)
    {
        num := RegExReplace(m1, ",", "")
        repl := AddComma(num) . m2 . m3
        expr := SubStr(expr, 1, pos - 1) . repl . SubStr(expr, pos + StrLen(m))
        pos += StrLen(repl)
    }

    return expr
}
DOC_ExpandMoneyUnitsInCalcExpr(expr)
{
    pos := 1
    while pos := RegExMatch(expr, "([0-9][0-9,]*(\.[0-9]+)?)\s*(Ãµ¸¸¿ø|¹é¸¸¿ø|¸¸¿ø|Ãµ¿ø|¹é¿ø|¾ï¿ø|¿ø)", m, pos)
    {
        num := RegExReplace(m1, ",", "") + 0
        unit := m3

        if (unit = "¹é¿ø")
            num := num * 100
        else if (unit = "Ãµ¿ø")
            num := num * 1000
        else if (unit = "¸¸¿ø")
            num := num * 10000
        else if (unit = "¹é¸¸¿ø")
            num := num * 1000000
        else if (unit = "Ãµ¸¸¿ø")
            num := num * 10000000
        else if (unit = "¾ï¿ø")
            num := num * 100000000

        repl := Round(num, 0)
        expr := SubStr(expr, 1, pos - 1) . repl . SubStr(expr, pos + StrLen(m))
        pos += StrLen(repl)
    }

    return expr
}
DOC_PreparePercentExpression(expr)
{
    ; 120-10%´Â ÀÏ¹Ý °è»ê±âÃ³·³ 120-(120*10/100)À¸·Î ÇØ¼®ÇÕ´Ï´Ù.
    if RegExMatch(expr, "^([0-9]+(\.[0-9]+)?)([\+\-])([0-9]+(\.[0-9]+)?)%$", m)
        return m1 . m3 . "(" . m1 . "*" . m4 . "/100)"
    return expr
}


DOC_EvalExpression(expr)
{
    global DOC_EXPR, DOC_POS

    DOC_EXPR := RegExReplace(expr, "\s", "")
    DOC_EXPR := DOC_PreparePercentExpression(DOC_EXPR)
    DOC_POS := 1

    if (DOC_EXPR = "")
        return ""

    val := DOC_ParseExpression()
    return val
}


DOC_ParseExpression()
{
    global DOC_EXPR, DOC_POS

    value := DOC_ParseTerm()

    Loop
    {
        op := SubStr(DOC_EXPR, DOC_POS, 1)

        if (op != "+" && op != "-")
            break

        DOC_POS++
        right := DOC_ParseTerm()

        if (op = "+")
            value := value + right
        else
            value := value - right
    }

    return value
}


DOC_ParseTerm()
{
    global DOC_EXPR, DOC_POS

    value := DOC_ParseFactor()

    Loop
    {
        op := SubStr(DOC_EXPR, DOC_POS, 1)

        if (op != "*" && op != "/")
            break

        DOC_POS++
        right := DOC_ParseFactor()

        if (op = "*")
            value := value * right
        else
        {
            if (right = 0)
                return ""
            value := value / right
        }
    }

    return value
}


DOC_ParseFactor()
{
    global DOC_EXPR, DOC_POS

    ch := SubStr(DOC_EXPR, DOC_POS, 1)

    if (ch = "+")
    {
        DOC_POS++
        return DOC_ParseFactor()
    }

    if (ch = "-")
    {
        DOC_POS++
        return -1 * DOC_ParseFactor()
    }

    if (ch = "(")
    {
        DOC_POS++
        value := DOC_ParseExpression()

        if (SubStr(DOC_EXPR, DOC_POS, 1) = ")")
            DOC_POS++
        if (SubStr(DOC_EXPR, DOC_POS, 1) = "%")
        {
            value := value / 100
            DOC_POS++
        }

        return value
    }

    rest := SubStr(DOC_EXPR, DOC_POS)

    if RegExMatch(rest, "^\d+(\.\d+)?", m)
    {
        DOC_POS += StrLen(m)
        value := m + 0
        if (SubStr(DOC_EXPR, DOC_POS, 1) = "%")
        {
            value := value / 100
            DOC_POS++
        }
        return value
    }

    ; ÆÄ½Ì ½ÇÆÐ ½Ã DOC_POS¸¦ ¹®ÀÚ¿­ ³¡À¸·Î ÀÌµ¿ÇØ ¹«ÇÑ·çÇÁ ¹æÁö
    DOC_POS := StrLen(DOC_EXPR) + 1
    return 0
}


DOC_FixSpace(line)
{
    ; 2.ÇÐ±Þ ¡æ 2. ÇÐ±Þ / 10.°èÈ¹ ¡æ 10. °èÈ¹
    ; ´Ü, 2026.5.1. °°Àº ³¯Â¥´Â °Çµå¸®Áö ¾Êµµ·Ï 1~2ÀÚ¸® ¹øÈ£¸¸ º¸Á¤ÇÕ´Ï´Ù.
    line := RegExReplace(line, "^(\s*\d{1,2}\.)\s*((?:19|20)\d{2}³â)", "$1 $2")
    line := RegExReplace(line, "^(\s*\d{1,2}\.)\s*([^\s\d])", "$1 $2")

    line := RegExReplace(line, "[ `t]{2,}", " ")
    line := RegExReplace(line, "(^|\s)±Ý\s+¾×\s*:", "$1±Ý¾×:")
    line := RegExReplace(line, "\s+:", ":")
    line := RegExReplace(line, ":\s*", ": ")
    line := RegExReplace(line, ":\s*$", ":")
    line := RegExReplace(line, "\s*~\s*", "~")
    line := DOC_FixLawTailSpacing(line)
    line := DOC_FinalCleanup(line)
    line := DOC_FixTime(line)

    return line
}


DOC_HasPurposeExamples(text)
{
    if RegExMatch(text, "-\s*¸ñÀû\s*¿¹½Ã")
        return true

    if (RegExMatch(text, "¨ç") && RegExMatch(text, "¨è") && RegExMatch(text, "¨é") && RegExMatch(text, "¨ê") && RegExMatch(text, "¨ë"))
        return true

    return false
}


DOC_PurposeBlock(a, b, c, d, e)
{
    return "    - ¸ñÀû ¿¹½Ã`r`n"
         . "      ¨ç " . a . "`r`n"
         . "      ¨è " . b . "`r`n"
         . "      ¨é " . c . "`r`n"
         . "      ¨ê " . d . "`r`n"
         . "      ¨ë " . e
}


DOC_BuildPurposeExamples(context)
{
    if (context = "")
        context := "ÇÐ±³ ±³À°È°µ¿ ¿î¿µ"

    if RegExMatch(context, "°ø»ç|½Ã¼³|¼ö¼±|º¸¼ö|°ø°£|¸®¸ðµ¨¸µ|µµ»ö|¹æ¼ö|Àü±â|¹è°ü|¹®Â¦|Ã¢È£|È¯°æ\s*±¸¼º")
        return DOC_PurposeBlock("ÇÐ»ý È°µ¿ Æ¯¼º¿¡ ¸Â´Â ¾ÈÀüÇÏ°í È°¿ëµµ ³ôÀº ±³À°°ø°£ Á¶¼º", "³ëÈÄ¡¤ºÒÆí ½Ã¼³ °³¼±À» ÅëÇÑ ÇÐ±³ °ø°£ÀÇ ±â´É¼º Çâ»ó", "´Ù¾çÇÑ ±³À°È°µ¿À» Áö¿øÇÒ ¼ö ÀÖ´Â °ø°£ È¯°æ ¸¶·Ã", "½Ã¼³ ÀÌ¿ëÀÚÀÇ ¾ÈÀü¼º°ú ÆíÀÇ¼ºÀ» °í·ÁÇÑ È¯°æ°³¼± ÃßÁø", "ÇÐ±³ °ø°£ÀÇ È¿À²Àû È°¿ë°ú ±³À°È¯°æ °³¼±À» À§ÇÑ °ø»ç ½ÃÇà")

    else if RegExMatch(context, "½Ç³»È­|½½¸®ÆÛ|½Å¹ßÀå|ÇÐ»ý\s*½Å¹ß|±³³»È­")
        return DOC_PurposeBlock("³ëÈÄ¡¤ÆÄ¼Õ ½Ç³»È­ ±³Ã¼¸¦ ÅëÇÑ ÇÐ»ý À§»ý ¹× ¾ÈÀüÇÑ ½Ç³» º¸ÇàÈ¯°æ Á¶¼º", "ÇÐ»ý »ýÈ°Áöµµ¿Í ÇÐ±³ ½Ç³» È¯°æ °ü¸®¸¦ À§ÇÑ °ø¿ë ½Ç³»È­ È®º¸", "¿À¿°¡¤ÈÑ¼ÕµÈ ½Ç³»È­ Á¤ºñ·Î ÄèÀûÇÑ ÇÐ±³»ýÈ° ¿©°Ç ¸¶·Ã", "±³À°È°µ¿ Áß ¹Ì²ô·¯Áü µî ¾ÈÀü»ç°í ¿¹¹æÀ» À§ÇÑ ½Ç³» ÀÌµ¿È¯°æ °³¼±", "ÇÐ»ý Áß½ÉÀÇ »ýÈ°È¯°æ Á¤ºñ¸¦ ÅëÇÑ ÇÐ±³»ýÈ° ¸¸Á·µµ Á¦°í")

    else if RegExMatch(context, "CCTV|cctv|¾¾¾¾Æ¼ºñ|¿µ»óÁ¤º¸|¿µ»ó\s*ÀåÄ¡|°¨½ÃÄ«¸Þ¶ó|º¸¾ÈÄ«¸Þ¶ó")
        return DOC_PurposeBlock("ÇÐ±³ ³» ¾ÈÀü Ãë¾à±¸¿ª °ü¸®¸¦ À§ÇÑ CCTV ¼³Ä¡¡¤Á¤ºñ", "ÇÐ»ý ¾ÈÀü»ç°í ¹× ÇÐ±³Æø·Â ¿¹¹æÀ» À§ÇÑ ¿µ»óÁ¤º¸ °ü¸®Ã¼°è °­È­", "±³³» ½Ã¼³¹° º¸È£¿Í ¿ÜºÎÀÎ ÃâÀÔ °ü¸® µî ÇÐ±³ º¸¾ÈÈ¯°æ °³¼±", "»ç°¢Áö´ë ÃÖ¼ÒÈ­¸¦ ÅëÇÑ ¾ÈÀüÇÑ ±³À°È°µ¿ °ø°£ Á¶¼º", "ÇÐ±³ ¾ÈÀü°ü¸® °èÈ¹¿¡ µû¸¥ ¿¹¹æ Áß½ÉÀÇ ÇÐ»ý º¸È£Ã¼°è ¸¶·Ã")

    else if RegExMatch(context, "¹æ¼Û|¸¶ÀÌÅ©|½ºÇÇÄ¿|¾ÚÇÁ|À½Çâ|¹«¼±¸¶ÀÌÅ©|À¯¼±¸¶ÀÌÅ©|¹æ¼ÛÀåºñ|½ÃÃ»°¢")
        return DOC_PurposeBlock("ÇÐ±³ Çà»ç ¹× ±³À°È°µ¿ ¾È³»¸¦ À§ÇÑ ¹æ¼Û¡¤À½Çâ Àåºñ È®º¸", "±³³» Àü´ÞÃ¼°è °³¼±À» ÅëÇÑ °¢Á¾ Çà»ç¿Í ¼ö¾÷ ¿î¿µÀÇ È¿À²¼º Á¦°í", "³ëÈÄ ¹æ¼ÛÀåºñ ±³Ã¼·Î ¾ÈÁ¤ÀûÀÎ ¾È³»¹æ¼Û ¹× ½ÃÃ»°¢ ±³À°È¯°æ Á¶¼º", "°­´ç¡¤±³½Ç¡¤Æ¯º°½Ç µî ±³À°°ø°£º° À½Çâ Ç°Áú °³¼±", "ÇÐ»ý ¹ßÇ¥È°µ¿°ú ÇÐ±³ Çà»ç ¿î¿µÀ» Áö¿øÇÏ±â À§ÇÑ ¹æ¼ÛÈ¯°æ Á¤ºñ")

    else if RegExMatch(context, "ÄÄÇ»ÅÍ|³ëÆ®ºÏ|ÅÂºí¸´|PC|pc|¸ð´ÏÅÍ|Å°º¸µå|¸¶¿ì½º|Á¤º¸È­|½º¸¶Æ®±â±â|ÀüÀÚÄ¥ÆÇ|µðÁöÅÐ")
        return DOC_PurposeBlock("µðÁöÅÐ ±â¹Ý ¼ö¾÷ ¹× ÇÐ±³ ¾÷¹« Áö¿øÀ» À§ÇÑ Á¤º¸È­±â±â È®º¸", "³ëÈÄ Á¤º¸È­±â±â ±³Ã¼¸¦ ÅëÇÑ ¼ö¾÷È¯°æ°ú ¾÷¹«Ã³¸® È¿À²¼º °³¼±", "ÇÐ»ý Âü¿©Çü ¼ö¾÷°ú ¿Â¶óÀÎ ÇÐ½ÀÈ°µ¿ ¿î¿µÀ» À§ÇÑ µðÁöÅÐ ±³À°È¯°æ Á¶¼º", "±³Á÷¿ø ÇàÁ¤¾÷¹« ¹× ±³¼öÇÐ½ÀÀÚ·á Á¦ÀÛ Áö¿øÀ» À§ÇÑ Àü»êÀåºñ ±¸ÀÔ", "¹Ì·¡±³À° ±â¹Ý Á¶¼ºÀ» À§ÇÑ ÇÐ±³ Á¤º¸È­ ÀÎÇÁ¶ó Á¤ºñ")

    else if RegExMatch(context, "Ã¼À°|¿îµ¿|½ºÆ÷Ã÷|Ãà±¸|³ó±¸|¹è±¸|¹èµå¹ÎÅÏ|Å¹±¸|Ã¼À°´ëÈ¸|ÇÐ±³½ºÆ÷Ã÷Å¬·´")
        return DOC_PurposeBlock("Ã¼À°¼ö¾÷ ¹× ÇÐ±³½ºÆ÷Ã÷Å¬·´ ¿î¿µ¿¡ ÇÊ¿äÇÑ Ã¼À°¿ëÇ° È®º¸", "ÇÐ»ý ½ÅÃ¼È°µ¿ Âü¿© È®´ë¿Í °Ç°­ÇÑ ÇÐ±³»ýÈ° Áö¿ø", "³ëÈÄ¡¤ÆÄ¼Õ Ã¼À°¿ëÇ° ±³Ã¼¸¦ ÅëÇÑ ¾ÈÀüÇÑ Ã¼À°È°µ¿ È¯°æ Á¶¼º", "±³À°°úÁ¤°ú ¿¬°èÇÑ ´Ù¾çÇÑ Ã¼À°È°µ¿ ¿î¿µ ±â¹Ý ¸¶·Ã", "ÇÐ»ýÀÇ Çùµ¿½É°ú ±âÃÊÃ¼·Â Çâ»óÀ» À§ÇÑ Ã¼À°±³À° Áö¿ø")

    else if RegExMatch(context, "ÇùÀÇÈ¸|È¸ÀÇ|°£´ãÈ¸|±³À°°úÁ¤¿î¿µ|ÇùÀÇ")
        return DOC_PurposeBlock("±³À°°úÁ¤ ¿î¿µ ¹æÇâ°ú ºÎ¼­º° ÃßÁø°èÈ¹ °øÀ¯¸¦ À§ÇÑ ÇùÀÇ", "ÇÐ»ý Áö¿ø ¹æ¾È ¹× ÇÐ±³ Çö¾È¿¡ ´ëÇÑ °øµ¿ ³íÀÇ Ã¼°è ¸¶·Ã", "ÇÐ³â¡¤ºÎ¼­ °£ ¾÷¹« Á¶Á¤À» ÅëÇÑ ±³À°È°µ¿ ¿î¿µ È¿À²È­", "ÇÐ±³ ±¸¼º¿ø °£ ¼ÒÅë °­È­ ¹× ÇöÀå ÀÇ°ß ¼ö·Å", "ÁÖ¿ä ±³À°È°µ¿ÀÇ ½ÇÇà·Â Á¦°í¸¦ À§ÇÑ ÇùÀÇÈ¸ ¿î¿µ")

    else if RegExMatch(context, "ÃâÀå|¿©ºñ|¿¬¼ö|Âü¼®")
        return DOC_PurposeBlock("ÇÐ±³ ¾÷¹« ÃßÁø¿¡ ÇÊ¿äÇÑ ¿¬¼ö¡¤È¸ÀÇ¡¤ÇùÀÇÈ¸ Âü¼® ¿©ºñ Áö±Þ", "°ü°è±â°ü ÇùÀÇ ¹× ÀÚ·á¼öÁýÀ» ÅëÇÑ »ç¾÷ ÃßÁø ±â¹Ý ¸¶·Ã", "±³À°ÇàÁ¤ ¾÷¹«ÀÇ Àü¹®¼º °­È­¸¦ À§ÇÑ °ø½Ä ÀÏÁ¤ Âü¼® Áö¿ø", "ÃâÀå ¸í·É¿¡ µû¸¥ ÀÌµ¿°æºñ¸¦ °ü·Ã ±ÔÁ¤¿¡ µû¶ó Áö±Þ", "ÇÐ±³ ¿î¿µ ¹× ±³À°È°µ¿ Áö¿øÀ» À§ÇÑ ´ë¿Ü ¾÷¹« ¼öÇà")

    else if RegExMatch(context, "°­»ç|°­ÀÇ|Æ¯°­|°­»çºñ|°­»ç·á")
        return DOC_PurposeBlock("±³À°°úÁ¤°ú ¿¬°èÇÑ Àü¹® °­ÀÇ ¿î¿µÀ» À§ÇÑ ¿ÜºÎ°­»ç È°¿ë", "ÇÐ»ýÀÇ Áø·Î¡¤ÀÎ¼º¡¤Ã¢ÀÇ¿ª·® ÇÔ¾çÀ» À§ÇÑ Æ¯°­ ÇÁ·Î±×·¥ Áö¿ø", "ÇÐ±³ ³»ºÎ ÀÎ·ÂÀ¸·Î º¸¿ÏÇÏ±â ¾î·Á¿î Àü¹® ºÐ¾ß ±³À°±âÈ¸ Á¦°ø", "ÇÁ·Î±×·¥ ¿î¿µ °á°ú¿¡ µû¸¥ °­»ç·á Áö±Þ ÀýÂ÷ ÀÌÇà", "ÇÐ»ý Âü¿©Çü ±³À°È°µ¿ÀÇ ÁúÀû Çâ»óÀ» À§ÇÑ °­»çºñ ÁýÇà")

    else
        return DOC_PurposeBlock("°èÈ¹µÈ ±³À°È°µ¿ÀÇ ¿øÈ°ÇÑ ÃßÁøÀ» À§ÇÑ ¿î¿µ ¿©°Ç ¸¶·Ã", "ÇÐ»ý Áö¿ø ¹× ÇÐ±³ ¾÷¹« ¼öÇà¿¡ ÇÊ¿äÇÑ ÇàÁ¤ÀýÂ÷ ÀÌÇà", "»ç¾÷ ¸ñÀû¿¡ ¸Â´Â ¿¹»ê ÁýÇàÀ¸·Î ±³À°È°µ¿ ¿î¿µ ¾ÈÁ¤¼º È®º¸", "ÇÐ±³ ÇöÀå ¼ö¿ä¸¦ ¹Ý¿µÇÑ ¿î¿µ Áö¿ø Ã¼°è ¸¶·Ã", "±³À°È°µ¿ÀÇ Áö¼Ó¼º°ú È¿°ú¼ºÀ» ³ôÀÌ±â À§ÇÑ ±â¹Ý Á¶¼º")
}



; =========================================================
; ¼ýÀÚ ¾øÀÌ ½ÃÀÛµÈ º»¹® ÀÚµ¿ º¸Á¤
; ¿¹: Ã¹ ¹®Àå + 1. °ü·Ã / 2. ÀÏ½Ã / 3. Àå¼Ò
;     ¡æ 1. Ã¹ ¹®Àå /   °¡. °ü·Ã /   ³ª. ÀÏ½Ã /   ´Ù. Àå¼Ò
; =========================================================
DOC_PromoteGaItemsWhenNoRelated(text)
{
    ; 1. °ü·Ã / °ü·Ã Ã³·³ ÄÝ·Ð ¾øÀÌ ¾²ÀÎ °ü·Ã ºí·Ïµµ ÇÏÀ§ °¡/³ª Ç×¸ñÀ» º¸Á¸ÇÕ´Ï´Ù.
    if RegExMatch(text, "m)^\s*(?:\d+\.\s*)?°ü·Ã\s*[:£º]?\s*$")
        return text
    if RegExMatch(text, "°ü·Ã\s*[:£º]")
        return text

    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    lines := StrSplit(text, "`n")
    firstIdx := 0
    nextIdx := 0

    for idx, line in lines
    {
        t := Trim(DOC_NormalizeHardSpaces(line))
        if (t = "")
            continue
        if RegExMatch(t, "^Á¦¸ñ\s*:")
            continue
        firstIdx := idx
        break
    }

    if (firstIdx <= 0)
        return text

    firstText := Trim(lines[firstIdx])
    firstContent := firstText
    if RegExMatch(firstText, "^\d+\.\s*(.+)$", mFirstTop)
        firstContent := mFirstTop1

    if RegExMatch(firstContent, "^([°¡-ÇÏ]\s*[\.,£¬¡¢¤ý:£º]|ºÙÀÓ)")
        return text

    i := firstIdx
    Loop
    {
        i++
        if (i > lines.MaxIndex())
            break
        t := Trim(lines[i])
        if (t = "")
            continue
        nextIdx := i
        break
    }

    if (nextIdx <= 0 || !RegExMatch(Trim(lines[nextIdx]), "^[°¡-ÇÏ]\s*[\.,£¬¡¢¤ý:£º]\s*"))
        return text

    result := ""
    topNo := 0
    promoting := true
    skippingDuplicateBlock := false

    for idx, line in lines
    {
        t := Trim(DOC_NormalizeHardSpaces(line))

        if (idx = firstIdx)
        {
            result .= firstContent . "`r`n"
            continue
        }

        if (promoting && t != "" && RegExMatch(t, "^ºÙÀÓ"))
        {
            promoting := false
            skippingDuplicateBlock := false
        }

        if (promoting && RegExMatch(t, "^\d+\.\s*(.+)$", mDupTop))
        {
            dupContent := Trim(mDupTop1)
            if (dupContent = firstContent)
            {
                skippingDuplicateBlock := true
                continue
            }
        }

        if (skippingDuplicateBlock)
        {
            if RegExMatch(t, "^[°¡-ÇÏ]\s*[\.,£¬¡¢¤ý:£º]\s*")
                continue
            if RegExMatch(t, "^-+\s*")
                continue
            if (t = "")
                continue
            skippingDuplicateBlock := false
        }

        if (promoting && RegExMatch(t, "^[°¡-ÇÏ]\s*[\.,£¬¡¢¤ý:£º]\s*(.*)$", mGaTop))
        {
            topNo++
            result .= "  " . topNo . ". " . mGaTop1 . "`r`n"
            continue
        }

        result .= line . "`r`n"
    }

    return RTrim(result, "`r`n ")
}
DOC_AutoNumberLeadingSentence(text)
{
    ; °ø¹®¼­ º»¹® Ã¹ ¹®ÀåÀÌ ¹øÈ£ ¾øÀÌ ½ÃÀÛÇÏ¸é ±×´ë·Î µÓ´Ï´Ù.
    ; ¿¹: "Áø·ÎÃ¼Çè È°µ¿ ... ÁöÃâÇÏ°íÀÚ ÇÕ´Ï´Ù." ¾Æ·¡ÀÇ 1. °ü·Ã / 2. ÀÏ½Ã´Â ÃÖ»óÀ§ ¹øÈ£·Î À¯ÁöÇÕ´Ï´Ù.
    return text
}


; =========================================================
; ºÙÀÓ ¾Õ¿¡¸¸ ºó ÁÙ 1ÁÙ À¯Áö
; - 1. ´ÙÀ½ °¡.³ª.´Ù. »çÀÌ¿¡´Â ºó ÁÙÀ» µÎÁö ¾ÊÀ½
; - ¹®¼­ Áß°£ÀÇ °úµµÇÑ ºó ÁÙµµ Á¦°Å
; =========================================================
DOC_FixFinalAttachEnd(text)
{
    text := RTrim(text, " `t`r`n")

    if !RegExMatch(text, "s)ºÙÀÓ[\s\S]*\d+\s*(ºÎ|¸Å|½Ä|±Ç|°Ç|°³)\.")
        return text

    ; '³¡'ÀÌ ºÙÀÓ Ç×¸ñÀ¸·Î ¿ÀÀÎµÇ¾î »ý±ä ÈçÀû°ú Áßº¹ ³¡Ç¥½Ã¸¦ ¸ÕÀú Á¤¸®ÇÕ´Ï´Ù.
    text := RegExReplace(text, "\s+³¡\s+1ºÎ\.", "")
    text := RegExReplace(text, "(\s+³¡\.?)+\s*$", "")
    text := RTrim(text, " `t`r`n.") . "."

    ; ºÙÀÓ ¹®¼­¿¡¼­´Â ¸¶Áö¸· ºÙÀÓ Ç×¸ñ ³¡¿¡ '³¡.'ÀÌ È®½ÇÈ÷ ºÙµµ·Ï º¸Á¤ÇÕ´Ï´Ù.
    if RegExMatch(text, "s)(ºÙÀÓ[\s\S]*\d+\s*(ºÎ|¸Å|½Ä|±Ç|°Ç|°³)\.)$")
        text .= "  ³¡."

    return text
}

DOC_KeepOnlyAttachBlankLine(text)
{
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")

    ; ¸ðµç ºó ÁÙÀ» ¸ÕÀú Á¦°ÅÇÕ´Ï´Ù.
    text := RegExReplace(text, "`n[ `t]*`n+", "`n")

    ; ºÙÀÓ ¾Õ¿¡¸¸ ºó ÁÙ 1ÁÙÀ» ³Ö½À´Ï´Ù.
    text := RegExReplace(text, "`n[ `t]*(ºÙÀÓ)", "`n`n$1")

    return RTrim(text, "`r`n ")
}

DOC_NormalizeListNumbers(text)
{
    result := ""
    currentTop := 0
    currentGa := 0
    currentParenNo := 0
    currentParenGa := 0
    expectedTop := 1
    inAttach := false
    attachNo := 0
    lastItemIndent := -1
    lastListIndent := -1
    lastSymbol := ""
    lastSymbolIndent := -1
    sourceRank2Active := false
    sourceRank3Active := false

    text := DOC_SplitInlineHangulListItems(text)
    lines := StrSplit(text, "`n", "`r")
    baseListRank := DOC_DetectListBaseRank(lines)

    for idx, line in lines
    {
        t := Trim(DOC_NormalizeHardSpaces(line))

        if (t = "")
        {
            result .= "`r`n"
            continue
        }

        if RegExMatch(t, "^Á¦¸ñ\s*:")
        {
            result .= t . "`r`n"
            lastItemIndent := -1
            lastSymbol := ""
            lastSymbolIndent := -1
            continue
        }

        ; =====================================================
        ; ºÙÀÓ ÀÚµ¿ º¸Á¤
        ; - ºÙÀÓÀÌ 1°³»ÓÀÌ¸é: ºÙÀÓ  ¹®¼­ 1ºÎ.
        ; - µÚ¿¡ 2. Ç×¸ñÀÌ ÀÖÀ¸¸é: ºÙÀÓ  1. ¹®¼­ 1ºÎ. /       2. ¹®¼­ 1ºÎ.
        ; =====================================================
        if RegExMatch(t, "^ºÙÀÓ\s+(\d+)\.\s*(.+)$", mAttachFirst)
        {
            inAttach := true
            attachText := DOC_RemoveEndText(mAttachFirst2)
            attachText := DOC_NormalizeAttachTextForOutput(attachText)

            ; ºÙÀÓÀÌ 1°³»ÓÀÌ¸é ¹øÈ£¸¦ Á¦°ÅÇÕ´Ï´Ù.
           ; ¿¹: ºÙÀÓ  1. ³»¿ª¼­.  ³¡. ¡æ ºÙÀÓ  ³»¿ª¼­ 1ºÎ.
            ; µÚ¿¡ 2. Ç×¸ñ µîÀÌ ÀÖÀ¸¸é ±âÁ¸ ´ÙÁß ºÙÀÓ Çü½ÄÀº ±×´ë·Î À¯ÁöÇÕ´Ï´Ù.
            if (DOC_AttachHasFollowingItems(lines, idx))
            {
                attachNo := 1
                result .= "ºÙÀÓ  " . attachNo . ". " . attachText . "`r`n"
            }
            else
            {
                attachNo := 0
                result .= "ºÙÀÓ  " . attachText . "`r`n"
            }
            continue
        }

        if RegExMatch(t, "^ºÙÀÓ\s+(.+)$", mAttachNoNum)
        {
            attachText := mAttachNoNum1
            attachText := RegExReplace(attachText, "^\s+", "")
            attachText := DOC_RemoveEndText(attachText)

            attachText := DOC_NormalizeAttachTextForOutput(attachText)

            if (DOC_AttachHasFollowingItems(lines, idx))
            {
                inAttach := true
                attachNo := 1
                result .= "ºÙÀÓ  " . attachNo . ". " . attachText . "`r`n"
            }
            else
            {
                inAttach := true
                attachNo := 0
                result .= "ºÙÀÓ  " . attachText . "`r`n"
            }
            continue
        }

        if RegExMatch(t, "^ºÙÀÓ\s*$")
        {
            inAttach := true
            attachNo := 0
            result .= "ºÙÀÓ" . "`r`n"
            continue
        }

        ; ºÙÀÓ ¾Æ·¡¿¡ 2. / 3.Ã³·³ ¹øÈ£°¡ ³ª¿À¸é, ½ÇÁ¦ ¹øÈ£°¡ Æ²·Áµµ ºÙÀÓ ´ÙÀ½ Ç×¸ñÀ¸·Î º½
       ; ¿¹: ºÙÀÓ  Á÷¹«´ë¸®¸í·É¼­ 1ºÎ. / 3. ³ë·¡Àå¶û. ³¡. ¡æ ºÙÀÓ  1. ... /       2. ³ë·¡Àå¶û. ³¡.
        if (inAttach && RegExMatch(t, "^(\d+)\.\s*(.+)$", mAttachNext))
        {
            foundAttachNo := mAttachNext1 + 0

            if (attachNo <= 0)
                attachNo := 1
            else if (foundAttachNo = attachNo + 1)
                attachNo := foundAttachNo
            else
                attachNo++

            attachText := DOC_RemoveEndText(mAttachNext2)
            attachText := DOC_NormalizeAttachTextForOutput(attachText)
            result .= "      " . attachNo . ". " . attachText . "`r`n"
            continue
        }

        if (inAttach && RegExMatch(t, "^[-?]\s*(.+)$", mAttachBullet))
        {
            if (attachNo <= 0)
                attachNo := 1
            else
                attachNo++
            attachText := DOC_RemoveEndText(mAttachBullet1)
            attachText := DOC_NormalizeAttachTextForOutput(attachText)
            result .= "      " . attachNo . ". " . attachText . "`r`n"
            continue
        }

        ; ºÙÀÓ ¾Æ·¡¿¡ ¹øÈ£ ¾øÀÌ ÀÌ¾îÁö´Â ÁÙµµ ´ÙÀ½ ºÙÀÓ Ç×¸ñÀ¸·Î º¾´Ï´Ù.
       ; ¿¹: ºÙÀÓ  °ßÀû¼­ 1ºÎ. / ³ë·¡. ³¡. ¡æ ºÙÀÓ  1. °ßÀû¼­ 1ºÎ. /       2. ³ë·¡. ³¡.
        if (inAttach)
        {
            attachText := DOC_RemoveEndText(t)

            ; ³¡.¸¸ ´Üµ¶À¸·Î ³²Àº ÁÙÀº Ç×¸ñÀ¸·Î ¸¸µéÁö ¾Ê°í, ¸¶Áö¸· ³¡ Ã³¸®´Â ÀüÃ¼ Á¤¸® ´Ü°è¿¡ ¸Ã±é´Ï´Ù.
            if (attachText = "")
                continue

            if (attachNo <= 0)
                attachNo := 1
            else
                attachNo++

            attachText := DOC_NormalizeAttachTextForOutput(attachText)
            result .= "      " . attachNo . ". " . attachText . "`r`n"
            continue
        }

        ; ¹®¼­¿¡ ½ÇÁ¦·Î Á¸ÀçÇÏ´Â Ã¹ ¸ñ·Ï ´Ü°è¸¦ ÃÖ»óÀ§·Î ½Â°ÝÇÕ´Ï´Ù.
        ; ¿¹: 1. ´Ü°è°¡ ¾øÀ¸¸é °¡.¡æ1., 1)¡æ°¡., °¡)¡æ1) ¼øÀ¸·Î ÇÔ²² ´ç±é´Ï´Ù.
        markerRank := DOC_GetListMarkerRank(t, listContent)
        if (markerRank > 0)
        {
            ; ¹®¼­ ÀüÃ¼»Ó ¾Æ´Ï¶ó ÇöÀç »óÀ§ Ç×¸ñ ¾È¿¡¼­ ºüÁø Áß°£ ´Ü°èµµ ¾ÐÃàÇÕ´Ï´Ù.
            ; ¿¹: 4. ÁÖ¿ä³»¿ë / - ¼³¸í / 1) ÀÏÁ¤ / 2) ¿¹»ê
            ;     ¡æ 4. ÁÖ¿ä³»¿ë /   - ¼³¸í /   °¡. ÀÏÁ¤ /   ³ª. ¿¹»ê
            if (markerRank = baseListRank)
            {
                outputRank := 1
            }
            else
            {
                outputRank := 2
                checkRank := baseListRank + 1
                while (checkRank < markerRank)
                {
                    if (checkRank = 2 && sourceRank2Active)
                        outputRank++
                    else if (checkRank = 3 && sourceRank3Active)
                        outputRank++
                    checkRank++
                }
            }
            content := DOC_RemoveEmptyHeadingColon(listContent)

            if (outputRank = 1)
            {
                currentTop++
                currentGa := 0
                currentParenNo := 0
                currentParenGa := 0
                outputText := currentTop . ". " . content
                indent := 0
            }
            else if (outputRank = 2)
            {
                currentGa++
                currentParenNo := 0
                currentParenGa := 0
                outputText := DOC_KorLetter(currentGa) . ". " . content
                indent := 2
            }
            else if (outputRank = 3)
            {
                currentParenNo++
                currentParenGa := 0
                outputText := currentParenNo . ") " . content
                indent := 4
            }
            else
            {
                currentParenGa++
                outputText := DOC_KorLetter(currentParenGa) . ") " . content
                indent := 6
            }

            result .= DOC_Spaces(indent) . outputText . "`r`n"

            ; ¿ø¹®¿¡¼­ ½ÇÁ¦·Î µîÀåÇÑ ºÎ¸ð ´Ü°è¸¦ ÇöÀç »óÀ§ Ç×¸ñº°·Î ±â¾ïÇÕ´Ï´Ù.
            if (markerRank <= 1)
            {
                sourceRank2Active := false
                sourceRank3Active := false
            }
            else if (markerRank = 2)
            {
                sourceRank2Active := true
                sourceRank3Active := false
            }
            else if (markerRank = 3)
            {
                sourceRank3Active := true
            }

            expectedTop := currentTop + 1
            inAttach := false
            lastItemIndent := indent
            lastListIndent := indent
            lastSymbol := ""
            lastSymbolIndent := -1
            continue
        }

        if RegExMatch(t, "^-+\s*¸ñÀû\s*¿¹½Ã")
        {
            result .= "    " . t . "`r`n"
            continue
        }

        if RegExMatch(t, "^[¨ç¨è¨é¨ê¨ë¨ì¨í¨î¨ï¨ð]")
        {
            result .= "      " . t . "`r`n"
            lastItemIndent := 6
            lastSymbol := ""
            lastSymbolIndent := -1
            continue
        }

        if RegExMatch(t, "^(-|¡¤|¤ý|¡à|¡â|¡Û|¡Ø|,|%|\*)\s*(.*)$", mSymbol)
        {
            symbol := mSymbol1
            content := mSymbol2
            if (lastListIndent >= 0)
                indent := lastListIndent + 2
            else
                indent := 2
            result .= DOC_Spaces(indent) . symbol . " " . content . "`r`n"
            lastItemIndent := indent
            lastSymbol := symbol
            lastSymbolIndent := indent
            continue
        }

        if RegExMatch(t, "^-+\s*")
        {
            result .= "    " . t . "`r`n"
            lastItemIndent := 4
            lastSymbol := ""
            lastSymbolIndent := -1
            continue
        }

        if RegExMatch(t, "^¡Ø")
        {
            result .= "    " . t . "`r`n"
            lastItemIndent := 4
            lastSymbol := ""
            lastSymbolIndent := -1
            continue
        }

        result .= line . "`r`n"
    }

    return RTrim(result, "`r`n ")
}

DOC_Spaces(count)
{
    spaces := ""
    Loop, %count%
        spaces .= " "
    return spaces
}

DOC_DetectListBaseRank(lines)
{
    baseRank := 0
    inAttach := false

    for _, line in lines
    {
        t := Trim(DOC_NormalizeHardSpaces(line))
        if RegExMatch(t, "^ºÙÀÓ(?:\s|$)")
        {
            inAttach := true
            continue
        }
        if (inAttach)
            continue

        rank := DOC_GetListMarkerRank(t, content)
        if (rank > 0 && (baseRank = 0 || rank < baseRank))
            baseRank := rank
    }

    return baseRank > 0 ? baseRank : 1
}

DOC_GetListMarkerRank(text, ByRef content)
{
    content := ""
    t := Trim(DOC_NormalizeHardSpaces(text))

    if RegExMatch(t, "^(\d+)\.\s+(.+)$", mTop)
    {
        foundNo := mTop1 + 0
        if (foundNo >= 1900 && foundNo <= 2099)
            return 0
        content := mTop2
        return 1
    }

    if RegExMatch(t, "^([°¡-ÇÏ])\s*[\.,£¬¡¢¤ý:£º]\s*(.*)$", mGa)
    {
        content := mGa2
        return 2
    }

    if RegExMatch(t, "^(\d+)\)\s*(.*)$", mParenNo)
    {
        content := mParenNo2
        return 3
    }

    if RegExMatch(t, "^([°¡-ÇÏ])\)\s*(.*)$", mParenGa)
    {
        content := mParenGa2
        return 4
    }

    return 0
}


DOC_SplitInlineHangulListItems(text)
{
    result := ""

    Loop, Parse, text, `n, `r
    {
        line := A_LoopField
        t := Trim(DOC_NormalizeHardSpaces(line))

        if RegExMatch(t, "^[°¡-ÇÏ]\.\s+")
        {
            Loop
            {
                if !RegExMatch(t, "^(.*?\S)\s+([°¡-ÇÏ])\.\s+(.+)$", m)
                    break

                result .= m1 . "`r`n"
                t := m2 . ". " . m3
            }
            result .= t . "`r`n"
            continue
        }

        result .= line . "`r`n"
    }

    return RTrim(result, "`r`n ")
}
DOC_StartsWithYearText(text)
{
    t := Trim(text)
    return RegExMatch(t, "^(19|20)\d{2}\s*(\.|ÇÐ³âµµ|³âµµ|³â)")
}
DOC_RemoveEmptyHeadingColon(content)
{
    t := Trim(content)
    if RegExMatch(t, "^(ÀÏ½Ã|±â°£|Àå¼Ò|´ë»ó|¸ñÀû|³»¿ë|Ç°¸ñ|¼ö·®|±Ô°Ý|³»¿ª|ÁöÃâ³»¿ª|»êÃâ³»¿ª|ÇùÀÇ¾È°Ç|¾È°Ç|¼Ò¿ä¿¹»ê|¼Ò¿ä±Ý¾×|¼Ò¿ä°æºñ|±Ý¾×|¿¹»ê|³³Ç°Àå¼Ò|³³Ç°±âÇÑ|°è¾à±â°£|¿ë¿ª±â°£|°Ë»ç°Ë¼ö|Âü¼®ÀÚ|°­»ç|ÁÖÁ¦|¿î¿µ³»¿ë)\s*[:£º]\s*$", m)
        return m1
    return content
}
DOC_ShouldNumberedLineBecomeSub(foundTop, expectedTop, currentTop, currentGa, content)
{
    t := Trim(content)

    ; ÇÏÀ§¸ñ·ÏÀÌ ¾ÆÁ÷ ½ÃÀÛµÇÁö ¾Ê¾ÒÀ¸¸é ¼ýÀÚ Ç×¸ñÀº ÃÖ»óÀ§ ¹øÈ£·Î µÓ´Ï´Ù.
    if (currentTop < 2 || currentGa <= 0)
        return false

    ; ÁýÇà/±¸ÀÔ/°è¾à/Áö±Þ ¹æ¹ýÀº º¸Åë ´ÙÀ½ ÃÖ»óÀ§ Ç×¸ñÀ¸·Î ¾²¹Ç·Î ÇÏÀ§ ÀüÈ¯ Á¦¿Ü
    if RegExMatch(t, "^(ÁýÇà¹æ¹ý|±¸ÀÔ¹æ¹ý|°è¾à¹æ¹ý|Áö±Þ¹æ¹ý|ÃßÁø¹æ¹ý|°áÁ¦¹æ¹ý|°áÀç¹æ¹ý)\s*:")
        return false

    if (!DOC_IsSubListContent(t))
        return false

    ; ÇùÀÇ¾È°Ç/¾È°ÇÀº ¸ñÀû ¿¹½Ã µÚ¿¡ 1.·Î Àß¸ø µé¾î¿À´Â °æ¿ì°¡ ¸¹¾Æ °­Á¦ ÇÏÀ§ ÀüÈ¯
    if RegExMatch(t, "^(ÇùÀÇ¾È°Ç|¾È°Ç)\s*:?")
        return true

   ; ¿¹: 4. Àå¼Ò, 1. ´ë»óÃ³·³ ÇöÀç ¿¹»ó ÃÖ»óÀ§ ¹øÈ£¿Í ¸ÂÁö ¾Ê´Â °æ¿ì ÇÏÀ§ ÀüÈ¯
    if (foundTop != expectedTop)
        return true

   ; ¿¹: 1. ´ë»óÃ³·³ ¹øÈ£°¡ ¾Õ¹øÈ£·Î µÇµ¹¾Æ°£ °æ¿ì ÇÏÀ§ ÀüÈ¯
    if (foundTop <= currentTop)
        return true

    return false
}


DOC_IsSubListContent(content)
{
    t := Trim(content)

    ; ÁýÇà¹æ¹ý/±¸ÀÔ¹æ¹ý/Áö±Þ¹æ¹ý µîÀº º¸Åë ´ÙÀ½ ÃÖ»óÀ§ ¹øÈ£·Î µÎ´Â °æ¿ì°¡ ¸¹¾Æ Á¦¿Ü
    if RegExMatch(t, "^(ÁýÇà¹æ¹ý|±¸ÀÔ¹æ¹ý|°è¾à¹æ¹ý|Áö±Þ¹æ¹ý|ÃßÁø¹æ¹ý|°áÁ¦¹æ¹ý|°áÀç¹æ¹ý)\s*:")
        return false

    if RegExMatch(t, "^(ÀÏ½Ã|±â°£|Àå¼Ò|´ë»ó|¸ñÀû|³»¿ë|Ç°¸ñ|¼ö·®|±Ô°Ý|³»¿ª|ÁöÃâ³»¿ª|»êÃâ³»¿ª|ÇùÀÇ¾È°Ç|¾È°Ç|¼Ò¿ä¿¹»ê|¼Ò¿ä±Ý¾×|¼Ò¿ä°æºñ|±Ý¾×|¿¹»ê|³³Ç°Àå¼Ò|³³Ç°±âÇÑ|°è¾à±â°£|¿ë¿ª±â°£|°Ë»ç°Ë¼ö|Âü¼®ÀÚ|°­»ç|ÁÖÁ¦|¿î¿µ³»¿ë)\s*:?\s*")
        return true

    return false
}


DOC_AttachHasFollowingItems(lines, startIdx)
{
    max := lines.MaxIndex()

    Loop
    {
        i := startIdx + A_Index
        if (i > max)
            break

        t := Trim(lines[i])

        if (t = "")
            continue

        ; ºÙÀÓ ¹Ù·Î ¾Æ·¡¿¡ ¼ýÀÚ/±Û¸Ó¸®Ç¥ Ç×¸ñÀÌ ÀÖÀ¸¸é ¿©·¯ ºÙÀÓÀ¸·Î ÆÇ´Ü
        ; Ç×¸ñ ¹øÈ£°¡ 2.°¡ ¾Æ´Ï¶ó 3.À¸·Î Àß¸ø µé¾î¿Íµµ µÚ¿¡¼­ 2.·Î ´Ù½Ã ¸Å±é´Ï´Ù.
        if RegExMatch(t, "^\d+\.\s*(.+)$", m)
            return true

        if RegExMatch(t, "^[-?]\s*(.+)$", b)
            return true

        ; ºÙÀÓ ¾Æ·¡¿¡ ¹øÈ£°¡ ¾ø¾îµµ ½ÇÁ¦ ±ÛÀÚ°¡ ÀÌ¾îÁö¸é ¿©·¯ ºÙÀÓÀ¸·Î ÆÇ´ÜÇÕ´Ï´Ù.
       ; ¿¹: ºÙÀÓ  °ßÀû¼­ 1ºÎ. / ³ë·¡. ³¡.
        clean := DOC_RemoveEndText(t)
        if (clean != "")
            return true

        ; ³¡.¸¸ ´Üµ¶À¸·Î ÀÖÀ¸¸é Ãß°¡ ºÙÀÓ Ç×¸ñÀ¸·Î º¸Áö ¾Ê½À´Ï´Ù.
        return false
    }

    return false
}


DOC_NormalizeAttachTextForOutput(text)
{
    t := Trim(text)

    if (t = "")
        return t

    ; ³¡. Á¦°Å ÈÄ ³²Àº ¸¶Ä§Ç¥ Á¤¸®
    t := DOC_RemoveEndText(t)
    t := Trim(t)

    ; ÀÌ¹Ì 1ºÎ/°¢ 1ºÎ/1¸Å/1½Ä/1±Ç µî ¼ö·® ´ÜÀ§°¡ ÀÖÀ¸¸é ¸¶Ä§Ç¥¸¸ º¸Á¤
    if (DOC_IsAttachItemText(t))
    {
        t := RegExReplace(t, "\s*\.\s*$", "")
        return t . "."
    }

    ; ¼ö·® ´ÜÀ§°¡ ¾øÀ¸¸é ºÙÀÓ ¹®¼­ 1ºÎ·Î º¸Á¤
   ; ¿¹: ³ë·¡. ³¡. ¡æ ³ë·¡ 1ºÎ.
    t := RegExReplace(t, "\s*\.\s*$", "")
    return t . " 1ºÎ."
}

DOC_IsAttachItemText(text)
{
    t := Trim(text)
    t := DOC_RemoveEndText(t)

    ; ºÙÀÓ Ç×¸ñÀº º¸Åë '1ºÎ, °¢ 1ºÎ, 1¸Å, 1½Ä, 1±Ç' µîÀ¸·Î ³¡³²
    if RegExMatch(t, "(°¢\s*)?\d+\s*(ºÎ|¸Å|½Ä|±Ç|°Ç|°³)\s*\.?$")
        return true

    ; °ýÈ£ ¼³¸í µÚ¿¡µµ 1ºÎ. ÇüÅÂ°¡ ÀÖ´Â °æ¿ì
    if RegExMatch(t, "\d+\s*(ºÎ|¸Å|½Ä|±Ç|°Ç|°³)\s*\([^)]*\)\s*\.?$")
        return true

    return false
}


DOC_RemoveEndText(text)
{
    t := Trim(text)
    t := RegExReplace(t, "(\s*\.?\s*³¡\.?)\s*$", "")
    return Trim(t)
}

DOC_KorLetter(idx)
{
    letters := ["°¡","³ª","´Ù","¶ó","¸¶","¹Ù","»ç","¾Æ","ÀÚ","Â÷","Ä«","Å¸","ÆÄ","ÇÏ"]

    if (idx >= 1 && idx <= letters.MaxIndex())
        return letters[idx]

    return "ÇÏ"
}


AddComma(num)
{
    ; À½¼ö °è»ê °á°ú º¸Á¸ º¸°­
   ; ¿¹: 2571-7607= ¡æ -5036 ¡æ -5,036
    s := Trim(num . "")
    isNegative := false

    if RegExMatch(s, "^\s*-")
        isNegative := true

    ; Á¤¼ö Ç¥½Ã¿ë ½°Ç¥ ÇÔ¼öÀÌ¹Ç·Î ¼Ò¼öÁ¡ ¾Æ·¡´Â ¹ö¸®°í, ºÎÈ£´Â º°µµ·Î º¸Á¸ÇÕ´Ï´Ù.
    s := RegExReplace(s, "^\s*[\+\-]", "")
    s := RegExReplace(s, "\..*$", "")
    s := RegExReplace(s, "[^\d]", "")
    s := RegExReplace(s, "^0+(?=\d)", "")

    if (s = "")
        return ""

    out := ""
    len := StrLen(s)
    cnt := 0

    Loop, %len%
    {
        ch := SubStr(s, len - A_Index + 1, 1)
        cnt++

        if (cnt > 1 && Mod(cnt - 1, 3) = 0)
            out := "," . out

        out := ch . out
    }

    if (isNegative && out != "0")
        out := "-" . out

    return out
}

AddCommaDecimal(num)
{
    s := Format("{:.2f}", num + 0)
    isNegative := false

    if RegExMatch(s, "^\s*-")
        isNegative := true

    s := RegExReplace(s, "^\s*[\+\-]", "")
    parts := StrSplit(s, ".")
    intPart := parts[1]
    decPart := parts.MaxIndex() >= 2 ? parts[2] : ""
    decPart := RegExReplace(decPart, "0+$", "")

    intText := AddComma((isNegative ? "-" : "") . intPart)
    if (decPart != "")
        return intText . "." . decPart

    return intText
}

NumToKor(num)
{
    num := RegExReplace(num, "[^\d]", "")
    num := RegExReplace(num, "^0+")

    if (num = "")
        return "¿µ"

    digits := ["","ÀÏ","ÀÌ","»ï","»ç","¿À","À°","Ä¥","ÆÈ","±¸"]
    smallUnits := ["","½Ê","¹é","Ãµ"]
    bigUnits := ["","¸¸","¾ï","Á¶","°æ"]

    result := ""
    groupIndex := 0

    while (StrLen(num) > 0)
    {
        len := StrLen(num)

        if (len > 4)
        {
            group := SubStr(num, len - 3, 4)
            num := SubStr(num, 1, len - 4)
        }
        else
        {
            group := num
            num := ""
        }

        groupNum := group + 0
        groupText := ""

        if (groupNum > 0)
        {
            groupLen := StrLen(group)

            Loop, %groupLen%
            {
                digit := SubStr(group, groupLen - A_Index + 1, 1) + 0

                if (digit = 0)
                    continue

                unit := smallUnits[A_Index]
                groupText := digits[digit + 1] . unit . groupText
            }

            result := groupText . bigUnits[groupIndex + 1] . result
        }

        groupIndex++
    }

    return result
}






















































; =========================================================
