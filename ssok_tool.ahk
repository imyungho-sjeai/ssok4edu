; =========================================================
; ssok_tool.ahk ´Üµ¶ ½ÇÇà Áö¿ø
; - ssok.ahk¿¡¼­ #IncludeµÉ ¶§: ±âÁ¸ µ¿ÀÛ ±×´ë·Î
; - ssok_tool.ahk¸¦ Á÷Á¢ ½ÇÇàÇÒ ¶§¸¸: ±âÁ¸ SSOK °è»ê±â ÀÚµ¿ Ç¥½Ã
; =========================================================
global SSOK_ToolStandalone := (A_LineFile = A_ScriptFullPath)

if (SSOK_ToolStandalone)
{
    ; °è»ê±âÀÇ °æ·Â±â°£ ÅÇ¿¡¼­ »ç¿ëÇÏ´Â ¹è¿­¸¸ ´Üµ¶ ½ÇÇà ½Ã ÃÊ±âÈ­
    if !IsObject(SSOK_CareerSelected)
        SSOK_CareerSelected := []

    ; ½ºÅ©¸³Æ® ·Îµå°¡ ³¡³­ µÚ ±âÁ¸ °è»ê±â GUI¸¦ È£Ãâ
    SetTimer, SSOK_Tool_StandaloneOpenCalculator, -50
    SetTimer, SSOK_AdminCalendar_StandaloneInit, -150
}
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
    if (SSOK_Tool_CopyClipboardText(originalText, 0.35, 2, true) && originalText != "")
        SSOK_PrivacySelectionMode := true

    ; 2. ¼±ÅÃ ¿µ¿ªÀÌ ¾øÀ¸¸é ÇöÀç ÁÙÀÌ ¾Æ´Ï¶ó ¹®¼­ ÀüÃ¼¸¦ ´ë»óÀ¸·Î Ã³¸®
    if (originalText = "")
    {
        SSOK_PrivacySelectionMode := false
        SendInput, ^a
        Sleep, 100
        if (!SSOK_Tool_CopyClipboardText(originalText, 0.8, 3, true))
        {
            Clipboard := SavedClipboard
            ToolTip, Å¬¸³º¸µå¿¡¼­ ¹®¼­ ³»¿ëÀ» °¡Á®¿ÀÁö ¸øÇß½À´Ï´Ù.
            SetTimer, SSOK_Tool_RemoveToolTip, -1800
            return
        }
    }

    if (originalText = "")
    {
        Clipboard := SavedClipboard
        ToolTip, ¼±ÅÃ ¿µ¿ª ¶Ç´Â ÀüÃ¼ ¹®¼­¿¡¼­ Ã³¸®ÇÒ ÅØ½ºÆ®¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.
        SetTimer, SSOK_Tool_RemoveToolTip, -1800
        return
    }

    maskedText := SSOK_MaskPrivateInfo(originalText, SSOK_PrivacySelectionMode)

    ; ¼±ÅÃ ¿µ¿ª ¶Ç´Â Ctrl+A·Î ÀâÈù ÀüÃ¼ ¹®¼­¸¦ °¡¸² Ã³¸® °á°ú·Î ±³Ã¼
    if (!SSOK_Tool_SetClipboardTextWithWait(maskedText, 0.7, 3))
    {
        Clipboard := SavedClipboard
        ToolTip, Å¬¸³º¸µå¿¡ °¡¸² Ã³¸® °á°ú¸¦ ´ãÁö ¸øÇß½À´Ï´Ù.
        SetTimer, SSOK_Tool_RemoveToolTip, -1800
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

    ; »ç¾÷ÀÚµî·Ï¹øÈ£: ÇÏÀÌÇÂ Çü½ÄÀÌ ºÐ¸íÇÏ°Å³ª °°Àº ÁÙ¿¡ Ç×¸ñ¸íÀÌ ÀÖÀ» ¶§¸¸ Ã³¸®ÇÕ´Ï´Ù.
    masked := RegExReplace(masked, "(^|[^\d])(\d{3})-(\d{2})-(\d{5})(?!\d)", "$1$2-**-*****")
    masked := SSOK_MaskContextualBusinessNumbers(masked)

    ; ±ä ¼ýÀÚ´Â °èÁÂ¡¤½Äº°¹øÈ£ Ç×¸ñ¸íÀÌ °°Àº ÁÙ¿¡ ÀÖ°í ¹øÈ£ Çü½ÄÀÌ ¸ÂÀ» ¶§¸¸ Ã³¸®ÇÕ´Ï´Ù.
    ; ±Ý¾×¡¤¿¹»ê¡¤ÀÏ¹Ý °ü¸® ¼ýÀÚ°¡ °èÁÂ¹øÈ£·Î Àß¸ø °¡·ÁÁö´Â °ÍÀ» ¹æÁöÇÕ´Ï´Ù.
    masked := SSOK_MaskContextualLongNumbers(masked)

    ; ºí·Ï ÁöÁ¤ ½Ã¿¡µµ ¼º¸í Ç¥Áö ¶Ç´Â ÇÑ ÁÙÂ¥¸® ÀÌ¸§ ÇüÅÂ°¡ È®ÀÎµÉ ¶§¸¸ ÀÌ¸§À» Ã³¸®ÇÕ´Ï´Ù.
    if (forceNameMask)
        masked := SSOK_MaskThreeCharKoreanNamesInText(masked)
    else
        masked := SSOK_MaskNamesInSensitiveLines(masked)

    return masked
}

SSOK_MaskNamesInSensitiveLines(text)
{
    result := ""
    expectNameOnNextLine := false
    lineBreak := SSOK_DetectLineBreak(text)
    normalizedText := SSOK_NormalizeLineBreaksForParse(text)
    Loop, Parse, normalizedText, `n
    {
        line := A_LoopField
        trimmedLine := Trim(line)
        if SSOK_HasNameLabel(line)
        {
            line := SSOK_MaskLabeledNamesInLine(line)
            expectNameOnNextLine := RegExMatch(trimmedLine, "^(´ë»ó|Âü¼®ÀÚ|Âü¿©ÀÚ|ÇÐ»ý¸í|¼º¸í|¼º\s*¸í|¸í´Ü|ÀÌ¸§)\s*[:£º]?$")
        }
        else if (expectNameOnNextLine && SSOK_IsSimpleNameLine(line))
        {
            line := SSOK_MaskSimpleNameLine(line)
            expectNameOnNextLine := false
        }
        else
            expectNameOnNextLine := false

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
        line := A_LoopField
        if SSOK_HasNameLabel(line)
            line := SSOK_MaskLabeledNamesInLine(line)
        else if SSOK_IsSimpleNameLine(line)
            line := SSOK_MaskSimpleNameLine(line)

        if (A_Index = 1)
            result := line
        else
            result .= lineBreak . line
    }
    return result
}

SSOK_HasNameLabel(line)
{
    return RegExMatch(line, "(´ë»ó|Âü¼®ÀÚ|Âü¿©ÀÚ|ÇÐ»ý¸í|¼º¸í|¼º\s*¸í|¸í´Ü|ÀÌ¸§)")
}

SSOK_MaskLabeledNamesInLine(line)
{
    pos := 1
    out := ""
    pattern := "O)((?:Âü¼®ÀÚ\s*¸í´Ü|Âü¿©ÀÚ\s*¸í´Ü|ÇÐ»ý\s*¸í´Ü|´ë»ó|Âü¼®ÀÚ|Âü¿©ÀÚ|ÇÐ»ý¸í|¼º¸í|¼º\s*¸í|¸í´Ü|ÀÌ¸§)\s*(?:[:£º]\s*)?(?:(?:ÇÐ»ý|±³Á÷¿ø|ÇÐºÎ¸ð|º¸È£ÀÚ)\s*)?)([°¡-ÆR]{2,4})"
    while RegExMatch(line, pattern, m, pos)
    {
        name := m.Value(2)
        start := m.Pos(2)
        out .= SubStr(line, pos, start - pos)
        if SSOK_IsMaskableKoreanName(name)
            out .= SubStr(name, 1, 1) . SSOK_RepeatStar(StrLen(name) - 1)
        else
            out .= name
        pos := start + m.Len(2)
    }
    out .= SubStr(line, pos)
    return out
}

SSOK_IsSimpleNameLine(line)
{
    if !RegExMatch(line, "O)^\s*(?:(?:\d+)[.)]\s*|[-¡¤?¡Û¡à]\s*)?([°¡-ÆR]{2,4})\s*$", m)
        return false
    return SSOK_IsLikelyKoreanName(m.Value(1))
}

SSOK_MaskSimpleNameLine(line)
{
    if !RegExMatch(line, "O)^(\s*(?:(?:\d+)[.)]\s*|[-¡¤?¡Û¡à]\s*)?)([°¡-ÆR]{2,4})(\s*)$", m)
        return line
    name := m.Value(2)
    if !SSOK_IsLikelyKoreanName(name)
        return line
    return m.Value(1) . SubStr(name, 1, 1) . SSOK_RepeatStar(StrLen(name) - 1) . m.Value(3)
}

SSOK_IsLikelyKoreanName(word)
{
    if !SSOK_IsMaskableKoreanName(word)
        return false

    commonWords := "½ÅÃ»¼­|º¸°í¼­|°èÈ¹¼­|È®ÀÎ¼­|¾È³»¹®|ÁØºñ¹°|Á¦Ãâ¹°|°á°ú¹°|´ã´çÀÚ|½ÅÃ»ÀÚ|Âü¿©ÀÚ|´ë»óÀÚ|º¸È£ÀÚ|±³À°ºñ|¿î¿µºñ|Àç·áºñ|±³Åëºñ|±Þ½Äºñ|¿¹»ê¾×|ÃÑ¾×|±Ý¾×|ÀÜ¾×|ÀÏÁ¤Ç¥|½Ã°£Ç¥|Ãâ¼®ºÎ|¸í´ÜÇ¥|¿¬¶ôÃ³|ÈÞ´ëÆù|ÀüÈ­±â|ÀÌ¸ÞÀÏ|ÇÐ±³¸í|±â°ü¸í|ÁÖ¼ÒÁö|¹®¼­¸í|¾÷¹«¸í|ÇÐ»ý¼ö|ÇÐ±Þ¼ö|ÀüÈ­¹øÈ£|°èÁÂ¹øÈ£|»ý³â¿ùÀÏ|ÁÖ¹Î¹øÈ£"
    if RegExMatch(word, "^(" . commonWords . ")$")
        return false

    if RegExMatch(word, "^(³²±Ã|È²º¸|Á¦°¥|¼±¿ì|¼­¹®|µ¶°í|µ¿¹æ)[°¡-ÆR]{1,2}$")
        return true
    return RegExMatch(word, "^[±èÀÌ¹ÚÃÖÁ¤°­Á¶À±ÀåÀÓÇÑ¿À¼­½Å±ÇÈ²¾È¼ÛÀüÈ«À¯°í¹®¾ç¼Õ¹è¹éÇã³²½É³ëÇÏ°û¼ºÂ÷ÁÖ¿ì±¸¹ÎÁøÁö¾öÃ¤¿øÃµ¹æ°øÇöÇÔº¯¿°¿©Ãßµµ¼Ò¼®¼±¼³¸¶±æ¿¬À§Ç¥¸í±â¹Ý¶ó¿Õ±Ý¿ÁÀ°ÀÎ¸ÍÁ¦¸ðÅ¹±¹¾îÀºÆí¿ë¿¹°æºÀ»çºÎ°¡º¹ÅÂ¸ñÇüÇÇµÎ°¨À½ºóµ¿È£]{1}[°¡-ÆR]{1,2}$")
}

SSOK_MaskContextualLongNumbers(text)
{
    result := ""
    lineBreak := SSOK_DetectLineBreak(text)
    normalizedText := SSOK_NormalizeLineBreaksForParse(text)
    Loop, Parse, normalizedText, `n
    {
        line := A_LoopField
        if RegExMatch(line, "(°èÁÂ\s*¹øÈ£|°èÁÂ¹øÈ£|ÀÔ±Ý\s*°èÁÂ|È¯ºÒ\s*°èÁÂ|°èÁÂ|ÅëÀå|ÇÐ¹ø|»ç¹ø|±³Á÷¿ø\s*¹øÈ£|Á÷¿ø\s*¹øÈ£|Á¢¼ö\s*¹øÈ£|Áõ¼­\s*¹øÈ£)")
            line := SSOK_MaskLongNumbersInContextLine(line)

        if (A_Index = 1)
            result := line
        else
            result .= lineBreak . line
    }
    return result
}

SSOK_MaskContextualBusinessNumbers(text)
{
    result := ""
    lineBreak := SSOK_DetectLineBreak(text)
    normalizedText := SSOK_NormalizeLineBreaksForParse(text)
    Loop, Parse, normalizedText, `n
    {
        line := A_LoopField
        if RegExMatch(line, "(»ç¾÷ÀÚ\s*µî·Ï\s*¹øÈ£|»ç¾÷ÀÚ\s*¹øÈ£)")
            line := RegExReplace(line, "(^|[^\d])(\d{3})[- ]?(\d{2})[- ]?(\d{5})(?!\d)", "$1$2-**-*****")

        if (A_Index = 1)
            result := line
        else
            result .= lineBreak . line
    }
    return result
}

SSOK_MaskLongNumbersInContextLine(line)
{
    pos := 1
    out := ""
    while RegExMatch(line, "O)(?<!\d)(\d(?:[- ]?\d){8,18})(?!\d)", m, pos)
    {
        raw := m.Value(1)
        start := m.Pos(1)
        len := m.Len(1)
        digits := RegExReplace(raw, "[^0-9]", "")
        following := SubStr(line, start + len, 2)
        out .= SubStr(line, pos, start - pos)

        if (StrLen(digits) >= 10 && StrLen(digits) <= 16 && !RegExMatch(following, "^\s*(¿ø|¸¸¿ø|Ãµ¿ø)"))
            out .= SubStr(digits, 1, 3) . SSOK_RepeatStar(StrLen(digits) - 6) . SubStr(digits, StrLen(digits) - 2)
        else
            out .= raw
        pos := start + len
    }
    out .= SubStr(line, pos)
    return out
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
    SSOK_ToolDynamicLabel := "SSOK_WinHelp_CancelDirect"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
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

    ; Win+F1 ÀÔ·Â ÈÄ Ã¢ À¯Áö ¼³Á¤: ±âº»°ªÀº "ÇØÁ¦"
    QIPinMode := 0
return


; =========================================================
; ±âº»°ª ¼³Á¤
; - 1~7¹ø ¹®±¸ ±âº»°ª ¼³Á¤
; =========================================================
QI_SetDefaults:
    QIDefault1 := "¿©±â¿¡ [ÀÚÁÖ »ç¿ëÇÏ´Â¹®±¸]¸¦ ÀÔ·ÂÇÏ½Ã°í ¿À¸¥ÂÊ [ÀúÀå&ÀÔ·Â]À» ´©¸£¼¼¿ä"
    QIDefault2 := "¼ýÀÚÅ° 1~9¹øÀ¸·Î ¹Ù·Î ÀÔ·ÂÇÒ ¼ö ÀÖ½À´Ï´Ù"
    QIDefault3 := "°³ÀÎÁ¤º¸´Â À¯ÃâµÇÁö ¾Êµµ·Ï ÁÖÀÇÇØÁÖ¼¼¿ä"
    QIDefault4 := "¾÷¹«·Î ¹Ù»Ú½Å ¿ÍÁß¿¡µµ Àû±ØÀûÀ¸·Î ÇùÁ¶ÇØ ÁÖ¼Å¼­ °¨»çÇÕ´Ï´Ù.`r`n°ü·ÃÇÏ¿© ¹®ÀÇ »çÇ×ÀÌ ÀÖÀ¸½Ã¸é ¾ðÁ¦µç ¿¬¶ô ÁÖ½Ê½Ã¿À.`r`n000 µå¸²"
    QIDefault5 := "¼¼Á¾ ±³À° ¹ßÀüÀ» À§ÇØ ÇùÁ¶ÇØ ÁÖ¼Å¼­ ´Ã °¨»çÇÕ´Ï´Ù.`r`n¿À´Ãµµ º¸¶÷Âù ÇÏ·ç º¸³»½Ã±æ ¹Ù¶ø´Ï´Ù.`r`nOOO µå¸²"
    QIDefault6 := "ÁÖ¼Ò ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã º¸¶÷µ¿ ÇÑ´©¸®´ë·Î 2154 (¿ìÆí¹øÈ£ 30151)`r`nÀüÈ­ 044-320-0000`r`nÆÑ½º 044-320-0000"
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

    ; -----------------------------------------------------
    ; 4~6¹ø ¿¹Àü ÇÑ ÁÙ ±âº»¹®±¸ ¡æ »õ ¿©·¯ ÁÙ ±âº»¹®±¸ ÀÚµ¿ ÀüÈ¯
    ; »ç¿ëÀÚ°¡ Á÷Á¢ ¼öÁ¤ÇÑ °ªÀº ±×´ë·Î º¸Á¸ÇÕ´Ï´Ù.
    ; -----------------------------------------------------
    QIOldDefault4 := "¾÷¹«·Î ¹Ù»Ú½Å ¿ÍÁß¿¡µµ Àû±ØÀûÀ¸·Î ÇùÁ¶ÇØ ÁÖ¼Å¼­ °¨»çÇÕ´Ï´Ù. °ü·ÃÇÏ¿© ¹®ÀÇ »çÇ×ÀÌ ÀÖÀ¸½Ã¸é ¾ðÁ¦µç ¿¬¶ô ÁÖ½Ê½Ã¿À. 000 µå¸²"
    QIOldDefault5 := "¼¼Á¾ ±³À° ¹ßÀüÀ» À§ÇØ ÇùÁ¶ÇØ ÁÖ¼Å¼­ ´Ã °¨»çÇÕ´Ï´Ù. ¿À´Ãµµ º¸¶÷Âù ÇÏ·ç º¸³»½Ã±æ ¹Ù¶ø´Ï´Ù. OOO µå¸²"
    QIOldDefault6 := "¿¹½Ã) ÁÖ¼Ò ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã º¸¶÷µ¿ ÇÑ´©¸®´ë·Î 2154 (¿ìÆí¹øÈ£ 30151) ÀüÈ­ 044-320-0000 ÆÑ½º 044-320-0000"

    if (QIText4 = QIOldDefault4)
        QIText4 := QIDefault4
    if (QIText5 = QIOldDefault5)
        QIText5 := QIDefault5
    if (QIText6 = QIOldDefault6)
        QIText6 := QIDefault6

    if (QIHas7 && QIOldText7 != "")
        QIText7 := QIOldText7
    if (QIHas10)
        QIText10 := QIOldText10
    if (QIHas11)
        QIText11 := QIOldText11
    if (QIHas12)
        QIText12 := QIOldText12

    ; -----------------------------------------------------
    ; 2026-09-23 ÀÓ½Ã º¯°æ ¹öÀüÀ» ½ÇÇàÇÑ °æ¿ì¿¡¸¸ ¿ø·¡ ±âº»°ªÀ¸·Î º¹¿ø
    ; - 5¹ø ±â°ü¸í ¾È³»¹® -> ±âÁ¸ °¨»ç¹®±¸
    ; - 9¹øÀ¸·Î ¿Å°ÜÁ³´ø ±âº» °¨»ç¹®±¸ -> ±âº» ÀÔ·Â ¾È³»¹®
    ; »ç¿ëÀÚ°¡ Á÷Á¢ ¸¸µç ´Ù¸¥ ¹®±¸´Â °Çµå¸®Áö ¾Ê½À´Ï´Ù.
    ; -----------------------------------------------------
    QITempSchoolPrompt := "±â°ü¸íÀ» ÀÔ·ÂÇÏ¼¼¿ä (¿¹: µµ´ãÁßÇÐ±³)"
    QIOldThankText := "¼¼Á¾ ±³À° ¹ßÀüÀ» À§ÇØ ÇùÁ¶ÇØ ÁÖ¼Å¼­ ´Ã °¨»çÇÕ´Ï´Ù.`r`n¿À´Ãµµ º¸¶÷Âù ÇÏ·ç º¸³»½Ã±æ ¹Ù¶ø´Ï´Ù.`r`nOOO µå¸²"
    QIPreviousOneLineThankText := "¼¼Á¾ ±³À° ¹ßÀüÀ» À§ÇØ ÇùÁ¶ÇØ ÁÖ¼Å¼­ ´Ã °¨»çÇÕ´Ï´Ù. ¿À´Ãµµ º¸¶÷Âù ÇÏ·ç º¸³»½Ã±æ ¹Ù¶ø´Ï´Ù. OOO µå¸²"

    ; ÀÌÀü ±âº»°ª¸¸ ÇöÀç 3ÁÙ ±âº» ¹®±¸·Î º¯°æÇÕ´Ï´Ù.
    ; »ç¿ëÀÚ°¡ Á÷Á¢ ¸¸µç 5¹ø ¹®±¸´Â ±×´ë·Î µÓ´Ï´Ù.
    if (QIHas5 && (QIOldText5 = QITempSchoolPrompt || QIOldText5 = QIOldThankText || QIOldText5 = QIPreviousOneLineThankText))
        QIText5 := QIDefault5

    ; ÀÓ½Ã ¹öÀü¿¡¼­ 9¹øÀ¸·Î ÀÌµ¿Çß´ø °¨»ç¹®±¸¸¸ ¿ø·¡ ±âº» ¾È³»¹®À¸·Î º¹¿ø
    if (QIHas11 && QIOldText11 = QIOldThankText)
        QIText11 := QIDefault11

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
        SSOK_ToolDynamicLabel := "SSOK_QF_LoadKeywords"
        if IsLabel(SSOK_ToolDynamicLabel)
            Gosub, %SSOK_ToolDynamicLabel%
    else
        SSOK_ToolDynamicLabel := "SSOK_QF_SetDefaults"
        if IsLabel(SSOK_ToolDynamicLabel)
            Gosub, %SSOK_ToolDynamicLabel%

    SSOK_Tool_SaveUnifiedIni()
return


; =========================================================
; 1~12¹ø ºü¸¥ ÀÔ·Â µµ¿ì¹Ì GUI
; =========================================================
QI_ShowGui:
    Gui, QIQuick:Destroy
    Gui, QIQuick:+AlwaysOnTop +ToolWindow +HwndQIQuickHwnd
    Gui, QIQuick:Color, F7FBFF
    Gui, QIQuick:Font, s9, Malgun Gothic

    ; ¼ýÀÚÅ° ¼±ÅÃÀ» ¹Þ±â À§ÇÑ ÃÊÁ¡¿ë ¼ûÀº ¹öÆ°
    Gui, QIQuick:Add, Button, x660 y835 w1 h1 vQIFocusDummy gQI_DoNothing, .

    ; ---------------------------------------------------------
    ; »ó´Ü Å¸ÀÌÆ² + °íÁ¤/ÇØÁ¦
    ; - ±âº»°ª: ÇØÁ¦
    ; - ¼±ÅÃµÈ »óÅÂ´Â ÁøÇÑ ÆÄ¶õ»öÀ¸·Î Ç¥½Ã
    ; ---------------------------------------------------------
    Gui, QIQuick:Font, s15 bold c005BAC, Malgun Gothic
    Gui, QIQuick:Add, Text, x15 y12 w465 h34 Center, ½î¿Á Å¬¸³º¸µå for K-¿¡µàÆÄÀÎ

    ; °íÁ¤ / ÇØÁ¦
    ; ½ÇÁ¦ ¹öÆ°Ã³·³ ´­¸®´Â PushLike Radio¸¦ »ç¿ëÇÏ¿© Å¬¸¯ÀÌ È®½ÇÇÏ°Ô µ¿ÀÛÇÏµµ·Ï ÇÔ
    ; ¼±ÅÃµÈ ÂÊÀº ´­¸° »óÅÂ + ¡Ü Ç¥½Ã·Î ÁøÇÏ°Ô ±¸ºÐ
    Gui, QIQuick:Font, s9 bold c222222, Malgun Gothic
    Gui, QIQuick:Add, Radio, x495 y15 w72 h27 vQIPinOnChoice gQI_PinOn +0x1000 Group, °íÁ¤
    Gui, QIQuick:Add, Radio, x575 y15 w72 h27 vQIPinOffChoice gQI_PinOff +0x1000, ÇØÁ¦

    Gui, QIQuick:Font, s9 norm c000000, Malgun Gothic

    ; 1¹ø
    Gui, QIQuick:Add, Text, x15 y55 w18 h24, 1.
    Gui, QIQuick:Add, Edit, x35 y50 w550 h45 vQIEdit1 +Multi +WantReturn, %QIText1%
    Gui, QIQuick:Add, Button, x595 y58 w70 h28 gQI_Input1, ÀúÀå&&ÀÔ·Â

    ; 2¹ø
    Gui, QIQuick:Add, Text, x15 y110 w18 h24, 2.
    Gui, QIQuick:Add, Edit, x35 y105 w550 h45 vQIEdit2 +Multi +WantReturn, %QIText2%
    Gui, QIQuick:Add, Button, x595 y113 w70 h28 gQI_Input2, ÀúÀå&&ÀÔ·Â

    ; 3¹ø
    Gui, QIQuick:Add, Text, x15 y165 w18 h24, 3.
    Gui, QIQuick:Add, Edit, x35 y160 w550 h45 vQIEdit3 +Multi +WantReturn, %QIText3%
    Gui, QIQuick:Add, Button, x595 y168 w70 h28 gQI_Input3, ÀúÀå&&ÀÔ·Â

    ; 4¹ø
    Gui, QIQuick:Add, Text, x15 y220 w18 h24, 4.
    Gui, QIQuick:Add, Edit, x35 y215 w550 h45 vQIEdit4 +Multi +WantReturn, %QIText4%
    Gui, QIQuick:Add, Button, x595 y223 w70 h28 gQI_Input4, ÀúÀå&&ÀÔ·Â

    ; 5¹ø
    Gui, QIQuick:Add, Text, x15 y275 w18 h24, 5.
    Gui, QIQuick:Add, Edit, x35 y270 w550 h45 vQIEdit5 +Multi +WantReturn, %QIText5%
    Gui, QIQuick:Add, Button, x595 y278 w70 h28 gQI_Input5, ÀúÀå&&ÀÔ·Â

    ; 6¹ø
    Gui, QIQuick:Add, Text, x15 y330 w18 h24, 6.
    Gui, QIQuick:Add, Edit, x35 y325 w550 h45 vQIEdit6 +Multi +WantReturn, %QIText6%
    Gui, QIQuick:Add, Button, x595 y333 w70 h28 gQI_Input6, ÀúÀå&&ÀÔ·Â

    ; 7¹ø
    Gui, QIQuick:Add, Text, x15 y385 w18 h24, 7.
    Gui, QIQuick:Add, Edit, x35 y380 w550 h45 vQIEdit7 +Multi +WantReturn, %QIText7%
    Gui, QIQuick:Add, Button, x595 y388 w70 h28 gQI_Input7, ÀúÀå&&ÀÔ·Â

    ; 8¹ø
    Gui, QIQuick:Add, Text, x15 y440 w18 h24, 8.
    Gui, QIQuick:Add, Edit, x35 y435 w550 h45 vQIEdit10 +Multi +WantReturn, %QIText10%
    Gui, QIQuick:Add, Button, x595 y443 w70 h28 gQI_Input10, ÀúÀå&&½ÇÇà

    ; 9¹ø
    Gui, QIQuick:Add, Text, x15 y490 w18 h24, 9.
    Gui, QIQuick:Add, Edit, x35 y485 w550 h45 vQIEdit11 +Multi +WantReturn, %QIText11%
    Gui, QIQuick:Add, Button, x595 y493 w70 h28 gQI_Input11, ÀúÀå&&ÀÔ·Â

    ; 10¹ø ³¯Â¥ ±â´É - 5°³ ¹öÆ° ¹Ù·Î ½ÇÇà
    Gui, QIQuick:Add, Text, x15 y540 w18 h24 c003366, 10.
    Gui, QIQuick:Font, s9 norm c000000, Malgun Gothic
    Gui, QIQuick:Add, Button, x35  y535 w70  h28 gQI_DateToday, ¿À´Ã
    Gui, QIQuick:Add, Button, x110 y535 w95  h28 gQI_DateThisWeek, ÀÌ¹ø ¿ù±Ý
    Gui, QIQuick:Add, Button, x210 y535 w80  h28 gQI_DateAge, ¸¸³ªÀÌ
    Gui, QIQuick:Add, Button, x295 y535 w70  h28 gQI_DateWeekday, ¿äÀÏ
    Gui, QIQuick:Add, Button, x370 y535 w95  h28 gQI_DateFormatToggle, ³¯Â¥ Çü½Ä
    Gui, QIQuick:Add, Button, x470 y535 w90  h28 gSSOK_WorkTools_CommaToggle, ¼ýÀÚ-Ãµ¿ø
    Gui, QIQuick:Add, Button, x565 y535 w90  h28 gSSOK_WorkTools_MoneyToggle, ¼ýÀÚ-±Ý¾×

    ; ÇÐ±³ÁÖ¼Ò - ¸ÞÀÎ È­¸é¿¡ ÀÔ·ÂµÈ ±â°ü¸íÀ» ¹Ù·Î »ç¿ë
    ; ³ªÀÌ½º ÇÐ±³Á¤º¸ API¿¡¼­ ÁÖ¼Ò / ÀüÈ­ / ÆÑ½º / È¨ÆäÀÌÁö¸¦ Ã£¾Æ ÇöÀç ÀÛ¾÷Ã¢¿¡ ÀÔ·Â
    Gui, QIQuick:Add, Button, x35 y569 w105 h28 gQI_SchoolAddressInput, ÇÐ±³ÁÖ¼Ò

    ; 11¹ø Æ¯¼ö¹®ÀÚ - º°µµ ¼±ÅÃÃ¢ ¾øÀÌ ¹Ù·Î Å¬¸¯ ÀÔ·Â
    Gui, QIQuick:Add, Text, x15 y635 w18 h24 c003366, 11.
    QISymbolMap := StrSplit("¡¤|¡î|¢Ñ|¢¡|¡Ø|¢¹|¢º|¡Û|¡Ü|¡Ý|¡à|¡á|¢Ã|¡¸|¡¹|¡¼|¡½|¡²|¡³|¡¶|¡·|¡º|¡»|¡Þ|¡ß|¡Ú|¡â|¡ã|¡ä|¡å|¡ç|¡è|¡é|¡ê|¢Ï|¥°|¥±|¥²|¥³|¥´|¨ç|¨è|¨é|¨ê|¨ë|¡É|§®|§¯|§°|§³|§¨|§±|§¸|¢ß|¡À|¡¿", "|")
    Gui, QIQuick:Font, s8 norm c000000, Malgun Gothic
    Loop, % QISymbolMap.Length()
    {
        QISymbolIndex := A_Index
        QISymbol := QISymbolMap[QISymbolIndex]
        QISymbolCol := Mod(QISymbolIndex - 1, 19)
        QISymbolRow := Floor((QISymbolIndex - 1) / 19)
        QISymbolX := 35 + (QISymbolCol * 32)
        QISymbolY := 630 + (QISymbolRow * 20)
        QISymbolCtrl := "QIQuickSymbolBtn" . QISymbolIndex
        Gui, QIQuick:Add, Button, x%QISymbolX% y%QISymbolY% w30 h18 v%QISymbolCtrl% gQI_QuickSpecialPick, %QISymbol%
    }
    Gui, QIQuick:Font, s9 norm c000000, Malgun Gothic

    ; 12~15¹ø ÀÌ¹ÌÁö Àü¿ë
    Gui, QIQuick:Font, s9 bold, Malgun Gothic

    QIImage12Preview := QI_GetImagePreviewPath(QIImage12, 12)
    QIImage13Preview := QI_GetImagePreviewPath(QIImage13, 13)
    QIImage14Preview := QI_GetImagePreviewPath(QIImage14, 14)
    QIImage15Preview := QI_GetImagePreviewPath(QIImage15, 15)

    ; 12¹ø
    Gui, QIQuick:Add, Text, x15 y690 w20 h24, 12.
    Gui, QIQuick:Add, Button, x38 y688 w42 h24 gQI_SelectImage12, º¯°æ
    Gui, QIQuick:Add, Button, x83 y688 w40 h24 gQI_SetImageURL12, URL
    if (QIImage12Preview != "")
        Gui, QIQuick:Add, Picture, x15 y718 w150 h75 vQIImage12Ctrl gQI_PasteImage12 +Border, %QIImage12Preview%
    else
        Gui, QIQuick:Add, Text, x15 y718 w150 h75 vQIImage12Ctrl +Border Center 0x200 gQI_SelectImage12, ÀÌ¹ÌÁö ¾øÀ½

    ; 13¹ø
    Gui, QIQuick:Add, Text, x180 y690 w20 h24, 13.
    Gui, QIQuick:Add, Button, x203 y688 w42 h24 gQI_SelectImage13, º¯°æ
    Gui, QIQuick:Add, Button, x248 y688 w40 h24 gQI_SetImageURL13, URL
    if (QIImage13Preview != "")
        Gui, QIQuick:Add, Picture, x180 y718 w150 h75 vQIImage13Ctrl gQI_PasteImage13 +Border, %QIImage13Preview%
    else
        Gui, QIQuick:Add, Text, x180 y718 w150 h75 vQIImage13Ctrl +Border Center 0x200 gQI_SelectImage13, ÀÌ¹ÌÁö ¾øÀ½

    ; 14¹ø
    Gui, QIQuick:Add, Text, x345 y690 w20 h24, 14.
    Gui, QIQuick:Add, Button, x368 y688 w42 h24 gQI_SelectImage14, º¯°æ
    Gui, QIQuick:Add, Button, x413 y688 w40 h24 gQI_SetImageURL14, URL
    if (QIImage14Preview != "")
        Gui, QIQuick:Add, Picture, x345 y718 w150 h75 vQIImage14Ctrl gQI_PasteImage14 +Border, %QIImage14Preview%
    else
        Gui, QIQuick:Add, Text, x345 y718 w150 h75 vQIImage14Ctrl +Border Center 0x200 gQI_SelectImage14, ÀÌ¹ÌÁö ¾øÀ½

    ; 15¹ø
    Gui, QIQuick:Add, Text, x510 y690 w20 h24, 15.
    Gui, QIQuick:Add, Button, x533 y688 w42 h24 gQI_SelectImage15, º¯°æ
    Gui, QIQuick:Add, Button, x578 y688 w40 h24 gQI_SetImageURL15, URL
    if (QIImage15Preview != "")
        Gui, QIQuick:Add, Picture, x510 y718 w150 h75 vQIImage15Ctrl gQI_PasteImage15 +Border, %QIImage15Preview%
    else
        Gui, QIQuick:Add, Text, x510 y718 w150 h75 vQIImage15Ctrl +Border Center 0x200 gQI_SelectImage15, ÀÌ¹ÌÁö ¾øÀ½

    Gui, QIQuick:Font, s8 norm c999999, Malgun Gothic
    Gui, QIQuick:Add, Text, x15 y810 w315 h20, ÀúÀåÆÄÀÏ: %QIIni%
    Gui, QIQuick:Add, Text, x345 y810 w315 h20 Right, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£

    ; ±âÁ¸ 960px¿¡¼­ ¾à 30% Ãà¼Ò
    SSOK_Tool_GetSidebarAttachedGuiPos(680, 845, QIQuickX, QIQuickY)
    Gui, QIQuick:Show, x%QIQuickX% y%QIQuickY% w680 h845, ½î¿Á ºü¸¥ ÀÔ·Â µµ¿ì¹Ì

    Gosub, QI_UpdatePinButtons

    ; Ã³À½ Ã¢ÀÌ ¿­¸®¸é ÀÔ·ÂÄ­ÀÌ ¾Æ´Ï¶ó ÃÊÁ¡¿ë ¹öÆ°¿¡ Æ÷Ä¿½º
    GuiControl, QIQuick:Focus, QIFocusDummy

    ; URL ¹Ì¸®º¸±â´Â Ã¢À» ¸ÕÀú ¶ç¿î ÈÄ ºñµ¿±â·Î ·ÎµåÇÕ´Ï´Ù.
    Gosub, QI_StartPreviewLoad
return


QI_PinOn:
    QIPinMode := 1
    Gosub, QI_UpdatePinButtons
return


QI_PinOff:
    QIPinMode := 0
    Gosub, QI_UpdatePinButtons
return


QI_UpdatePinButtons:
    if (QIPinMode)
    {
        GuiControl, QIQuick:, QIPinOnChoice, 1
        GuiControl, QIQuick:, QIPinOffChoice, 0
        GuiControl, QIQuick:, QIPinOnChoice, ¡Ü °íÁ¤
        GuiControl, QIQuick:, QIPinOffChoice, ÇØÁ¦
    }
    else
    {
        GuiControl, QIQuick:, QIPinOnChoice, 0
        GuiControl, QIQuick:, QIPinOffChoice, 1
        GuiControl, QIQuick:, QIPinOnChoice, °íÁ¤
        GuiControl, QIQuick:, QIPinOffChoice, ¡Ü ÇØÁ¦
    }
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

    x := 15
    if (slot = 13)
        x := 180
    else if (slot = 14)
        x := 345
    else if (slot = 15)
        x := 510

    Gui, QIQuick:Add, Picture, x%x% y718 w150 h75 gQI_PasteImage%slot% +Border, %cachePath%
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
        Gosub, QI_Input10
    else if (QINumber = "9")
        Gosub, QI_Input11
return


; =========================================================
; 1~7¹ø, 10~12¹ø ÀúÀå && ÀÔ·Â
; =========================================================
QI_Input1:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit1
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText1
    }
    Gosub, QI_PasteText
return

QI_Input2:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit2
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText2
    }
    Gosub, QI_PasteText
return

QI_Input3:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit3
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText3
    }
    Gosub, QI_PasteText
return

QI_Input4:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit4
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText4
    }
    Gosub, QI_PasteText
return

QI_Input5:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit5
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText5
    }
    Gosub, QI_PasteText
return


QI_SchoolAddressInput:
    ; ¸ÞÀÎ È­¸éÀÇ ±â°ü¸íÀ» ±×´ë·Î »ç¿ëÇÕ´Ï´Ù.
    if IsFunc("SSOK_GetOrgName")
        QISchoolQuery := Trim(Func("SSOK_GetOrgName").Call())
    else
    {
        IniRead, QISchoolQuery, %QIIni%, MajorTodos, OrgName,
        QISchoolQuery := Trim(QISchoolQuery)
    }

    if (QISchoolQuery = "")
    {
        ToolTip, ¸ÞÀÎ È­¸é¿¡ ±â°ü¸íÀÌ ÀÔ·ÂµÇ¾î ÀÖÁö ¾Ê½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1500
        return
    }

    QIInputText := QI_GetSchoolContactText(QISchoolQuery)
    if (QIInputText = "")
        return

    Gosub, QI_PasteText
return


QI_GetSchoolContactText(query)
{
    q := Trim(query)
    if (q = "")
        return ""

    ; ¸ÞÀÎ SSOKÀÇ [±³À°Á¤º¸ - ÇÐ±³Á¤º¸]¿Í µ¿ÀÏÇÑ ³ªÀÌ½º schoolInfo API/ÆÄ¼­¸¦ »ç¿ë
    if (!IsFunc("SSOK_EDU_GetApiKey") || !IsFunc("SSOK_EDU_BuildUrl")
        || !IsFunc("SSOK_EDU_HttpGet") || !IsFunc("SSOK_EDU_ParseSchools"))
    {
        MsgBox, 48, SSOK ÇÐ±³Á¤º¸, SSOK º»Ã¼ÀÇ [±³À°Á¤º¸ - ÇÐ±³Á¤º¸] ±â´ÉÀ» Ã£À» ¼ö ¾ø½À´Ï´Ù.
        return ""
    }

    fnKey := Func("SSOK_EDU_GetApiKey")
    fnBuild := Func("SSOK_EDU_BuildUrl")
    fnHttp := Func("SSOK_EDU_HttpGet")
    fnParse := Func("SSOK_EDU_ParseSchools")

    apiKey := fnKey.Call()
    params := Object("SCHUL_NM", q)
    url := fnBuild.Call("schoolInfo", params, 100, apiKey)
    resp := fnHttp.Call(url)

    if (!IsObject(resp) || !resp.ok)
    {
        MsgBox, 48, SSOK ÇÐ±³Á¤º¸, ³ªÀÌ½º ±³À°Á¤º¸ OPEN API¿¡ ¿¬°áÇÏÁö ¸øÇß½À´Ï´Ù.`n`nÀÎÅÍ³Ý ¿¬°áÀ» È®ÀÎÇØ ÁÖ¼¼¿ä.
        return ""
    }

    results := fnParse.Call(resp.text)
    if (!IsObject(results) || results.Length() < 1)
    {
        MsgBox, 48, SSOK ÇÐ±³Á¤º¸, ÀÔ·ÂÇÑ ±â°ü¸íÀ¸·Î ÇÐ±³Á¤º¸¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`n`n±â°ü¸í: %q%
        return ""
    }

    exact := []
    for _, schoolItem in results
    {
        if (Trim(schoolItem.schoolName) = q)
            exact.Push(schoolItem)
    }

    if (exact.Length() = 1)
        school := exact[1]
    else if (exact.Length() > 1)
    {
        MsgBox, 48, SSOK ÇÐ±³Á¤º¸, °°Àº ÀÌ¸§ÀÇ ÇÐ±³°¡ ¿©·¯ °÷ÀÔ´Ï´Ù.`nÁ¤È®ÇÑ ±â°ü¸íÀ» ÀÔ·ÂÇØ ÁÖ¼¼¿ä.`n`n±â°ü¸í: %q%
        return ""
    }
    else if (results.Length() = 1)
        school := results[1]
    else
    {
        MsgBox, 48, SSOK ÇÐ±³Á¤º¸, ºñ½ÁÇÑ ÇÐ±³°¡ ¿©·¯ °÷ °Ë»öµÇ¾ú½À´Ï´Ù.`nÁ¤È®ÇÑ ±â°ü¸íÀ» ÀÔ·ÂÇØ ÁÖ¼¼¿ä.`n`n±â°ü¸í: %q%
        return ""
    }

    address := Trim(school.address)
    detail := Trim(school.addressDetail)
    if (detail != "")
        address .= (address = "" ? "" : " ") . detail

    return "ÁÖ¼Ò : " . address
        . "`r`nÀüÈ­ : " . Trim(school.tel)
        . "`r`nÆÑ½º : " . Trim(school.fax)
        . "`r`nÈ¨ÆäÀÌÁö : " . Trim(school.homepage)
}

QI_Input6:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit6
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText6
    }
    Gosub, QI_PasteText
return


; =========================================================
; 7¹ø ÀúÀå && ÀÔ·Â
; =========================================================
QI_Input7:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit7
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText7
    }
    Gosub, QI_PasteText
return

QI_Input10:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit10
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText10
    }
    Gosub, QI_PasteText
return

QI_Input11:
    if (QIPinMode)
        GuiControlGet, QIInputText, QIQuick:, QIEdit11
    else
    {
        Gosub, QI_SaveFromGui
        QIInputText := QIText11
    }
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
    global QIImage12, QIImage13, QIImage14, QIImage15, QILastTargetHwnd, QIPinMode, QIQuickHwnd

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

    ; ´ë»ó Ã¢À» ±â¾ïÇÕ´Ï´Ù.
    ; ÇØÁ¦ »óÅÂ¿¡¼­´Â ±âÁ¸Ã³·³ Ã¢À» ´Ý°í, °íÁ¤ »óÅÂ¿¡¼­´Â À¯ÁöÇÕ´Ï´Ù.
    targetHwnd := QILastTargetHwnd
    if (!QIPinMode)
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
        QI_RestorePinnedGuiFocus()
        return
    }

    Sleep, 120
    SendInput, ^v
    Sleep, 350

    if (tempImage != "")
        FileDelete, %tempImage%

    QI_RestorePinnedGuiFocus()
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
; 10¹ø ³¯Â¥ ±â´É
; - ¿À´Ã: ¿À´Ã ³¯Â¥(¿äÀÏ) + ÇöÀç ½Ã°£
; - ÀÌ¹ø ¿ù±Ý: ÀÌ¹ø ÁÖ ¿ù¿äÀÏ~±Ý¿äÀÏ
; - ¸¸³ªÀÌ: ¼±ÅÃÇÑ »ý³â¿ùÀÏ ¿·¿¡ ¿À´Ã ±âÁØ ¸¸³ªÀÌ Ç¥½Ã
; - ¿äÀÏ: ¼±ÅÃÇÑ ³¯Â¥ ¿·¿¡ ¿äÀÏ Ç¥½Ã
; - ³¯Â¥ Çü½Ä: 2026.9.21. -> 2026. 9. 21. -> 2026-09-21 ¼øÈ¯
; =========================================================
QI_DateToday:
    Gosub, QI_MakeTodayDate
    QIInputText := QITodayText
    Gosub, QI_PasteText
return

QI_DateThisWeek:
    QIWeekMonday := A_Now
    QIWeekOffset := Mod(A_WDay + 5, 7)
    QIWeekOffset := -QIWeekOffset
    EnvAdd, QIWeekMonday, %QIWeekOffset%, Days

    QIWeekFriday := QIWeekMonday
    EnvAdd, QIWeekFriday, 4, Days

    FormatTime, QIWY1, %QIWeekMonday%, yyyy
    FormatTime, QIWM1, %QIWeekMonday%, M
    FormatTime, QIWD1, %QIWeekMonday%, d
    FormatTime, QIWW1, %QIWeekMonday%, WDay
    FormatTime, QIWM2, %QIWeekFriday%, M
    FormatTime, QIWD2, %QIWeekFriday%, d
    FormatTime, QIWW2, %QIWeekFriday%, WDay

    QIWeekDays := ["ÀÏ", "¿ù", "È­", "¼ö", "¸ñ", "±Ý", "Åä"]
    QIInputText := QIWY1 . ". " . QIWM1 . ". " . QIWD1 . ".(" . QIWeekDays[QIWW1] . ")~" . QIWM2 . ". " . QIWD2 . ".(" . QIWeekDays[QIWW2] . ")"
    Gosub, QI_PasteText
return

QI_DateAge:
    if (!QI_DateGetSelection(QISelectedDateText, QISelectedOldClip))
    {
        ToolTip, ¸¸³ªÀÌ´Â »ý³â¿ùÀÏÀ» ¸ÕÀú ºí·Ï ÁöÁ¤ÇØ¾ß ÇÕ´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1600
        return
    }

    if (!QI_ParseSimpleDate(QISelectedDateText, QIBirthY, QIBirthM, QIBirthD, QIBirthStyle))
    {
        ToolTip, ¼±ÅÃÇÑ ³¯Â¥¸¦ ÀÎ½ÄÇÏÁö ¸øÇß½À´Ï´Ù. ¿¹: 2026. 1.1.
        SetTimer, QI_RemoveToolTip, -1700
        return
    }

    QITodayNumber := (A_YYYY + 0) * 10000 + (A_MM + 0) * 100 + (A_DD + 0)
    QIBirthNumber := QIBirthY * 10000 + QIBirthM * 100 + QIBirthD
    if (QIBirthNumber > QITodayNumber)
    {
        ToolTip, »ý³â¿ùÀÏÀÌ ¿À´Ãº¸´Ù ´Ê½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1500
        return
    }

    QIAge := (A_YYYY + 0) - QIBirthY
    if (((A_MM + 0) * 100 + (A_DD + 0)) < (QIBirthM * 100 + QIBirthD))
        QIAge -= 1

    QISelectedDateText := Trim(QISelectedDateText, " `t`r`n")
    QIBaseY := A_YYYY + 0
    QIBaseM := A_MM + 0
    QIBaseD := A_DD + 0
    QIInputText := QISelectedDateText . " (¸¸" . QIAge . "¼¼, " . QIBaseY . "." . QIBaseM . "." . QIBaseD . ".±âÁØ)"
    Gosub, QI_PasteText
return

QI_DateWeekday:
    if (!QI_DateGetSelection(QISelectedDateText, QISelectedOldClip))
    {
        ToolTip, ¿äÀÏÀ» Ç¥½ÃÇÒ ³¯Â¥¸¦ ¸ÕÀú ºí·Ï ÁöÁ¤ÇØ¾ß ÇÕ´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1600
        return
    }

    if (!QI_ParseSimpleDate(QISelectedDateText, QIDateY, QIDateM, QIDateD, QIDateStyle))
    {
        ToolTip, ¼±ÅÃÇÑ ³¯Â¥¸¦ ÀÎ½ÄÇÏÁö ¸øÇß½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1500
        return
    }

    QIDateStamp := Format("{:04}{:02}{:02}000000", QIDateY, QIDateM, QIDateD)
    FormatTime, QIDateWDay, %QIDateStamp%, WDay
    QIDateDays := ["ÀÏ", "¿ù", "È­", "¼ö", "¸ñ", "±Ý", "Åä"]
    QISelectedDateText := Trim(QISelectedDateText, " `t`r`n")
    QIInputText := QISelectedDateText . "(" . QIDateDays[QIDateWDay] . ")"
    Gosub, QI_PasteText
return

QI_DateFormatToggle:
    if (!QI_DateGetSelection(QISelectedDateText, QISelectedOldClip))
    {
        ToolTip, Çü½ÄÀ» ¹Ù²Ü ³¯Â¥¸¦ ¸ÕÀú ºí·Ï ÁöÁ¤ÇØ¾ß ÇÕ´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1600
        return
    }

    if (!QI_ParseSimpleDate(QISelectedDateText, QIDateY, QIDateM, QIDateD, QIDateStyle))
    {
        ToolTip, ³¯Â¥ Çü½ÄÀ» ÀÎ½ÄÇÏÁö ¸øÇß½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1500
        return
    }

    if (QIDateStyle = "compact")
        QIInputText := QIDateY . ". " . QIDateM . ". " . QIDateD . "."
    else if (QIDateStyle = "spaced")
        QIInputText := Format("{:04}-{:02}-{:02}", QIDateY, QIDateM, QIDateD)
    else
        QIInputText := QIDateY . "." . QIDateM . "." . QIDateD . "."

    Gosub, QI_PasteText
return

QI_DateGetSelection(ByRef outText, ByRef oldClip)
{
    global QILastTargetHwnd

    oldClip := ClipboardAll
    outText := ""

    if (QILastTargetHwnd != "")
    {
        WinActivate, ahk_id %QILastTargetHwnd%
        WinWaitActive, ahk_id %QILastTargetHwnd%,, 0.6
        Sleep, 80
    }

    if (!SSOK_Tool_CopyClipboardText(QIDateSelectionRaw, 0.35, 2))
    {
        Clipboard := oldClip
        return false
    }

    outText := Trim(QIDateSelectionRaw, " `t`r`n")
    Clipboard := oldClip
    return (outText != "")
}

QI_ParseSimpleDate(dateText, ByRef y, ByRef m, ByRef d, ByRef style)
{
    dateText := Trim(dateText, " `t`r`n")
    style := ""

    if (RegExMatch(dateText, "^(\d{4})\.(\d{1,2})\.(\d{1,2})\.$", md))
        style := "compact"
    else if (RegExMatch(dateText, "^(\d{4})\.\s+(\d{1,2})\.\s+(\d{1,2})\.$", md))
        style := "spaced"
    else if (RegExMatch(dateText, "^(\d{4})-(\d{1,2})-(\d{1,2})$", md))
        style := "dash"
    else if (RegExMatch(dateText, "^(\d{4})\.\s*(\d{1,2})\.\s*(\d{1,2})\.$", md))
        style := "compact"
    else
        return false

    y := md1 + 0
    m := md2 + 0
    d := md3 + 0

    if (m < 1 || m > 12 || d < 1 || d > 31)
        return false

    stamp := Format("{:04}{:02}{:02}000000", y, m, d)
    expected := Format("{:04}{:02}{:02}", y, m, d)
    FormatTime, checked, %stamp%, yyyyMMdd
    return (checked = expected)
}


; =========================================================
; 8¹ø ÀúÀå && ½ÇÇà
; - 1~7¹ø ÇöÀç ¼öÁ¤ ³»¿ëÀº ÀúÀå
; - ¿ø·¡ ÀÛ¾÷ Ã¢À¸·Î µ¹¾Æ°¡ Shift+F2 ³¯Â¥/¿äÀÏ/±â°£ ±â´É ½ÇÇà
; =========================================================
QI_Input8:
    ; ÇØÁ¦ »óÅÂ¿¡¼­¸¸ ÇöÀç ¹®±¸µéÀ» ÀúÀåÇÕ´Ï´Ù.
    ; °íÁ¤ »óÅÂ¿¡¼­´Â ÀúÀåÇÏÁö ¾Ê°í ³¯Â¥ ±â´É¸¸ ½ÇÇàÇÕ´Ï´Ù.
    if (!QIPinMode)
        Gosub, QI_SaveFromGui

    ; ÇØÁ¦ »óÅÂ¿¡¼­´Â ±âÁ¸Ã³·³ ¹Ù·Î ´Ý°í, °íÁ¤ »óÅÂ¿¡¼­´Â Ã¢À» À¯ÁöÇÕ´Ï´Ù.
    if (!QIPinMode)
        Gui, QIQuick:Destroy

    if (QILastTargetHwnd != "")
    {
        WinActivate, ahk_id %QILastTargetHwnd%
        Sleep, 150
    }

    Gosub, QI_RunDateTool
    QI_RestorePinnedGuiFocus()
return


; =========================================================
; 11¹ø Æ¯¼ö¹®ÀÚ ¹Ù·Î Å¬¸¯ ÀÔ·Â
; =========================================================
QI_QuickSpecialPick:
    QISymbolIndex := RegExReplace(A_GuiControl, "\D")
    if (QISymbolIndex = "" || !IsObject(QISymbolMap))
        return

    QIInputText := QISymbolMap[QISymbolIndex]
    Gosub, QI_PasteText
return


; =========================================================
; 11¹ø Æ¯¼ö¹®ÀÚ °³º° ¼±ÅÃ ÀÔ·Â
; =========================================================
QI_Input9:
    Gosub, QI_ShowSpecialPicker
return

QI_ShowSpecialPicker:
    Gui, QISpecial:Destroy
    QISymbolMap := StrSplit("¡¤|¡î|¢Ñ|¢¡|¡Ø|¢¹|¢º|¡Û|¡Ü|¡Ý|¡à|¡á|¢Ã|¡¸|¡¹|¡¼|¡½|¡²|¡³|¡¶|¡·|¡º|¡»|¡Þ|¡ß|¡Ú|¡â|¡ã|¡ä|¡å|¡ç|¡è|¡é|¡ê|¢Ï|¥°|¥±|¥²|¥³|¥´|¨ç|¨è|¨é|¨ê|¨ë|¡É|§®|§¯|§°|§³|§¨|§±|§¸|¢ß|¡À|¡¿", "|")

    Gui, QISpecial:New, +AlwaysOnTop +ToolWindow, Æ¯¼ö¹®ÀÚ ¼±ÅÃ
    Gui, QISpecial:Font, s11 norm, Malgun Gothic

    Loop, % QISymbolMap.Length()
    {
        QISymbolIndex := A_Index
        QISymbol := QISymbolMap[QISymbolIndex]
        QISymbolCol := Mod(QISymbolIndex - 1, 3)
        QISymbolRow := Floor((QISymbolIndex - 1) / 3)
        QISymbolX := 10 + (QISymbolCol * 72)
        QISymbolY := 10 + (QISymbolRow * 30)
        QISymbolCtrl := "QISymbolBtn" . QISymbolIndex
        Gui, QISpecial:Add, Button, x%QISymbolX% y%QISymbolY% w62 h24 v%QISymbolCtrl% gQI_SpecialPick, %QISymbol%
    }

    Gui, QISpecial:Show, AutoSize, Æ¯¼ö¹®ÀÚ ¼±ÅÃ
return

QI_SpecialPick:
    QISymbolIndex := RegExReplace(A_GuiControl, "\D")
    if (QISymbolIndex = "" || !IsObject(QISymbolMap))
        return

    QIInputText := QISymbolMap[QISymbolIndex]
    Gui, QISpecial:Destroy
    Gosub, QI_PasteText
return

QISpecialGuiClose:
QISpecialGuiEscape:
    Gui, QISpecial:Destroy
    QI_RestorePinnedGuiFocus()
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
    SSOK_Tool_CopyClipboardText(QISelectedDateRaw, 0.25, 2)
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
    ; Win+F1 ÀÔ·ÂÄ­¿¡¼­ Enter·Î ¸¸µç ÁÙ¹Ù²ÞÀ» ±×´ë·Î ÀÔ·ÂÇÏµµ·Ï
    ; Windows Ç¥ÁØ CRLF·Î Á¤¸®ÇÕ´Ï´Ù.
    QIInputText := StrReplace(QIInputText, "`r`n", "`n")
    QIInputText := StrReplace(QIInputText, "`r", "`n")
    QIInputText := StrReplace(QIInputText, "`n", "`r`n")

    if (QIInputText = "")
    {
        ToolTip, ÀÔ·ÂÇÒ ¹®±¸°¡ ºñ¾î ÀÖ½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1200
        return
    }

    ; ÇØÁ¦ »óÅÂ¿¡¼­´Â ÀÔ·Â°ú µ¿½Ã¿¡ Ã¢À» ´Ý°í,
    ; °íÁ¤ »óÅÂ¿¡¼­´Â Ã¢À» ±×´ë·Î µÐ Ã¤ ¿ø·¡ ÀÛ¾÷ Ã¢¿¡ ÀÔ·ÂÇÕ´Ï´Ù.
    if (!QIPinMode)
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
        QI_RestorePinnedGuiFocus()
        return
    }

    QIOldClip := ClipboardAll
    if (!SSOK_Tool_SetClipboardTextWithWait(QIInputText, 0.7, 3))
    {
        Clipboard := QIOldClip
        ToolTip, Å¬¸³º¸µå¿¡ ÀÔ·Â ¹®±¸¸¦ ´ãÁö ¸øÇß½À´Ï´Ù.
        SetTimer, QI_RemoveToolTip, -1200
        QI_RestorePinnedGuiFocus()
        return
    }

    Send, ^v
    Sleep, 120

    Clipboard := QIOldClip
    QI_RestorePinnedGuiFocus()
return


QI_RestorePinnedGuiFocus()
{
    global QIPinMode, QIQuickHwnd

    if (!QIPinMode || QIQuickHwnd = "")
        return false

    if !WinExist("ahk_id " . QIQuickHwnd)
        return false

    WinActivate, ahk_id %QIQuickHwnd%
    WinWaitActive, ahk_id %QIQuickHwnd%,, 0.5
    GuiControl, QIQuick:Focus, QIFocusDummy
    return true
}

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

SSOK_Tool_RemoveToolTip:
    ToolTip
return
SSOK_Tool_StandaloneOpenCalculator:
    if (!SSOK_ToolStandalone)
        return
    Gosub, SSOK_ShowCalculator
return

SSOK_Sidebar_Calc:
    Gosub, SSOK_ShowCalculator
return

SSOK_Tool_CopyClipboardText(ByRef outText, timeoutSeconds := 0.3, retries := 2, useInput := false)
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

SSOK_Tool_SetClipboardTextWithWait(value, timeoutSeconds := 0.7, retries := 3)
{
    Loop, %retries%
    {
        Clipboard := ""
        Sleep, 30
        Clipboard := value
        ClipWait, %timeoutSeconds%
        if (!ErrorLevel)
            return true
        Sleep, 80
    }
    return false
}

SSOK_Tool_SaveUnifiedIni()
{
    if IsFunc("SSOK_SaveUnifiedIni")
        return Func("SSOK_SaveUnifiedIni").Call()
    return true
}

SSOK_Tool_GetSidebarAttachedGuiPos(guiW, guiH, ByRef outX, ByRef outY, forceLeft := false)
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

SSOK_Tool_IsKoreaNonWorkday(date8)
{
    global SSOK_ToolStandalone
    if (!SSOK_ToolStandalone && IsFunc("SSOK_IsKoreaNonWorkday"))
        return Func("SSOK_IsKoreaNonWorkday").Call(date8)
    stamp := date8 . "000000"
    FormatTime, wday, %stamp%, WDay
    if (wday = 1 || wday = 7)
        return true
    md := SubStr(date8, 5, 4)
    return (md = "0101" || md = "0301" || md = "0505" || md = "0606"
        || md = "0815" || md = "1003" || md = "1009" || md = "1225")
}

SSOK_Tool_OpenUrlPreferred(url)
{
    if IsFunc("SSOK_OpenUrlPreferred")
        return Func("SSOK_OpenUrlPreferred").Call(url)
    Run, %url%,, UseErrorLevel
    return ErrorLevel ? "" : "default"
}

SSOK_Tool_QU_UrlEncode(value)
{
    _size := StrPut(value, "UTF-8")
    VarSetCapacity(_buf, _size, 0)
    _len := StrPut(value, &_buf, _size, "UTF-8") - 1
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

SSOK_Tool_ACC_ActivateBrowser(browserExe := "")
{
    if IsFunc("SSOK_ACC_ActivateBrowser")
        return Func("SSOK_ACC_ActivateBrowser").Call(browserExe)
    return
}

SSOK_Tool_CreateHwpxReportFromText(reportSource, templateName)
{
    if IsFunc("SSOK_CreateHwpxReportFromText")
        return Func("SSOK_CreateHwpxReportFromText").Call(reportSource, templateName)
    return false
}

SSOK_Tool_QU_NormalizeUrl(url)
{
    u := Trim(url)
    if (u = "")
        return ""
    if RegExMatch(u, "i)^(https?://|file:|mailto:)")
        return u
    return "https://" . u
}
SSOK_Tool_GetCalculatorPos(guiW, guiH, ByRef outX, ByRef outY)
{
    global SSOK_ToolStandalone
    global SSOK_SidebarHwnd, SSOK_SidebarMiniHwnd, SSOK_SidebarSavedY

    ; ssok_tool.ahk ´Üµ¶ ½ÇÇà: ÇöÀç ÁÖ ¸ð´ÏÅÍ ÀÛ¾÷¿µ¿ª Áß¾Ó
    if (SSOK_ToolStandalone)
    {
        SysGet, SSOK_ToolWork, MonitorWorkArea
        outX := SSOK_ToolWorkLeft + Floor((SSOK_ToolWorkRight - SSOK_ToolWorkLeft - guiW) / 2)
        outY := SSOK_ToolWorkTop + Floor((SSOK_ToolWorkBottom - SSOK_ToolWorkTop - guiH) / 2)

        if (outX < SSOK_ToolWorkLeft)
            outX := SSOK_ToolWorkLeft
        if (outY < SSOK_ToolWorkTop)
            outY := SSOK_ToolWorkTop
        return
    }

    ; ssok.ahk¿¡¼­ IncludeµÈ °æ¿ì:
    ; ±âÁ¸ SSOK_Tool_GetSidebarAttachedGuiPos()¿Í µ¿ÀÏÇÑ À§Ä¡ °è»êÀ» ±×´ë·Î ¼öÇà
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
SSOK_ShowCalculator:
    ; SSOK º»Ã¼¿¡¼­ IncludeµÈ °æ¿ì¿¡´Â ±âÁ¸ Windows ¸Þ´º Â÷´Ü µ¿ÀÛÀ» ±×´ë·Î ¼öÇà
    if (!SSOK_ToolStandalone)
    {
        SSOK_ToolMainLabel := "SSOK_WinHelp_BlockWindowsMenu"
        if IsLabel(SSOK_ToolMainLabel)
            Gosub, %SSOK_ToolMainLabel%
    }

    ; ´Üµ¶ ½ÇÇà¿¡¼­µµ °æ·Â±â°£ ÅÇÀÌ Á¤»ó »ý¼ºµÇµµ·Ï º¸Àå
    if !IsObject(SSOK_CareerSelected)
        SSOK_CareerSelected := []

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

    ; 9. ¿¹»ê »êÃâ³»¿ª ¹Ù·Î ¾Æ·¡¿¡ °æ·Â±â°£À» Ãß°¡ÇÏ°í ¿À¸¥ÂÊ 3Ä­Àº ºñ¿öµÒ
    Gui, SSOKCalc:Add, Radio, x12 y68 w103 h20 vSSOK_CalcTab9 +0x1000 +Center gSSOK_CalcModeCareer, °æ·Â±â°£

    ; 2. µµ¿ò¸» ¾È³»
    Gui, SSOKCalc:Font, s8 norm c2A5C70, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y102 w656 h20 vSSOK_CalcHelp, ¿¹: 5,000 * 2°³ * 4ÁÖ=  ¶Ç´Â  (1,000 + 2,000) * 10

    ; 3. ºÐ¸®µÈ ÀÔ·ÂÄ­ 1 & 2 (3¹è ´ëÇüÈ­ h54)
    Gui, SSOKCalc:Font, s8 bold c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y126 w300 h18 vSSOK_CalcPrompt1, °è»ê ¼ö½Ä ¶Ç´Â ±Ý¾× ÀÔ·Â:
    Gui, SSOKCalc:Add, Text, x324 y126 w300 h18 vSSOK_CalcPrompt2, Ãß°¡ ¿É¼Ç:
    Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x12 y146 w656 h54 -WantReturn vSSOK_CalcInput1 gSSOK_CalcInput1Changed HwndSSOK_CalcInput1Hwnd
    Gui, SSOKCalc:Font, s15 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x324 y146 w300 h54 -WantReturn vSSOK_CalcInput2

    ; ³¯Â¥ ¼±ÅÃ DateTime ÄÁÆ®·Ñ (³¯Â¥¡¤¿äÀÏ, ³ªÀÌ¡¤ÅðÁ÷, ÀÔÂû°ø°í, ±Ù¹«½Ã°£ Àü¿ë)
    Gui, SSOKCalc:Font, s13 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, DateTime, x12 y146 w300 h42 vSSOK_CalcDate_Start Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd
    Gui, SSOKCalc:Add, DateTime, x12 y146 w300 h42 vSSOK_CalcAge_Birth Choose19900515 Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd
    Gui, SSOKCalc:Add, DateTime, x324 y146 w300 h42 vSSOK_CalcAge_Ref Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd
    Gui, SSOKCalc:Add, DateTime, x12 y146 w300 h42 vSSOK_CalcBid_Date Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd

    ; ±Ù¹«½Ã°£ Àü¿ë DateTime ÄÁÆ®·Ñ (ÀÏ½Ã 1ºÐ´ÜÀ§ Á¤È® ¼±ÅÃ)
    FormatTime, todayWorkStart,, yyyyMMdd083000
    FormatTime, todayWorkEnd,, yyyyMMdd163000
    Gui, SSOKCalc:Font, s11 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, DateTime, x12 y146 w300 h42 vSSOK_CalcWork_Start Choose%todayWorkStart% Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd HH:mm
    Gui, SSOKCalc:Add, DateTime, x324 y146 w300 h42 vSSOK_CalcWork_End Choose%todayWorkEnd% Hidden gSSOK_CalcDatePickChanged, yyyy-MM-dd HH:mm

    ; ÀÎÁ¤·ü ÄÁÆ®·Ñ (³¯Â¥¡¤¿äÀÏ Àü¿ë)
    Gui, SSOKCalc:Font, s8 bold c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x500 y210 w52 h20 Right vSSOK_CalcRateLabel, ÀÎÁ¤·ü:
    Gui, SSOKCalc:Font, s9 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x556 y207 w66 h24 Center -WantReturn vSSOK_CalcRate, 100
    Gui, SSOKCalc:Font, s8 bold c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x626 y210 w24 h20 Left vSSOK_CalcRateUnit, `%

    ; Á¶´Þ¼ö¼ö·á °è¾à ¹æ½Ä ¼±ÅÃ ¶óµð¿À (Á¶´Þ¼ö¼ö·á Àü¿ë)
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Radio, x12 y210 w150 h22 vSSOK_CalcProcureRad1 Group Checked gSSOK_CalcProcureTypeChanged, ¡Ü ³»ÀÚ±¸¸Å ÃÑ¾×°è¾à
    Gui, SSOKCalc:Add, Radio, x168 y210 w180 h22 vSSOK_CalcProcureRad2 gSSOK_CalcProcureTypeChanged, Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç°

    ; 4-1. ¿¹»êºñ¸ñ ¼±ÅÃ ¹öÆ° (¿¹»ê »êÃâ³»¿ª Àü¿ë)
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y210 w42 h22 vSSOK_CalcBudgetLabel, ºñ¸ñ:
    Gui, SSOKCalc:Font, s8 norm c222222, Malgun Gothic
    Gui, SSOKCalc:Add, Button, x56 y206 w74 h28 vSSOK_CalcBudgetBtn1 gSSOK_CalcBudgetBtnClick, ±³À°¿î¿µºñ
    Gui, SSOKCalc:Add, Button, x133 y206 w70 h28 vSSOK_CalcBudgetBtn2 gSSOK_CalcBudgetBtnClick, ¿î¿µ¼ö´ç
    Gui, SSOKCalc:Add, Button, x206 y206 w74 h28 vSSOK_CalcBudgetBtn3 gSSOK_CalcBudgetBtnClick, ÀÏ¹Ý¼ö¿ëºñ
    Gui, SSOKCalc:Add, Button, x283 y206 w74 h28 vSSOK_CalcBudgetBtn4 gSSOK_CalcBudgetBtnClick, ¾÷¹«ÃßÁøºñ
    Gui, SSOKCalc:Add, Button, x360 y206 w82 h28 vSSOK_CalcBudgetBtn5 gSSOK_CalcBudgetBtnClick, ºñÇ°ºñ

    ; 4. ½ÇÇà ¹öÆ° ¿µ¿ª (°è»ê 1.5¹è ±æ°Ô: 295px / °á°ú º¹»ç 60% ÀÛ°Ô: 125px)
    Gui, SSOKCalc:Font, s9 bold, Malgun Gothic
    Gui, SSOKCalc:Add, Button, x12 y242 w455 h30 Default vSSOK_CalcCalculateBtn gSSOK_CalcCalculate, °è»ê (Enter)
    Gui, SSOKCalc:Font, s9 norm, Malgun Gothic
    Gui, SSOKCalc:Add, Button, x477 y242 w191 h30 vSSOK_CalcCopyBtn gSSOK_CalcCopyResult, °á°ú º¹»ç

    ; 5. ÀÚ¸´¼ö ¿É¼Ç (Ä­À» ³ÐÇô¼­ 2ÁÙ ÁÙ¹Ù²Þ ¹æÁö)
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y280 w48 h20 vSSOK_CalcPrecisionLabel, ÀÚ¸´¼ö:
    Gui, SSOKCalc:Font, s8 norm c333333, Malgun Gothic
    Gui, SSOKCalc:Add, Radio, x65 y279 w55 h20 vSSOK_CalcRadPrec0 gSSOK_CalcPrecisionChanged Checked, Á¤¼ö
    Gui, SSOKCalc:Add, Radio, x124 y279 w92 h20 vSSOK_CalcRadPrec1 gSSOK_CalcPrecisionChanged, ¼Ò¼ö 1ÀÚ¸®
    Gui, SSOKCalc:Add, Radio, x220 y279 w92 h20 vSSOK_CalcRadPrec2 gSSOK_CalcPrecisionChanged, ¼Ò¼ö 2ÀÚ¸®
    Gui, SSOKCalc:Add, Radio, x316 y279 w55 h20 vSSOK_CalcRadPrec4 gSSOK_CalcPrecisionChanged, ÀÚµ¿

    ; 6. °è»ê °á°ú ¿µ¿ª
    Gui, SSOKCalc:Font, s8 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y308 w100 h18 vSSOK_CalcResultLabel, °è»ê °á°ú:
    Gui, SSOKCalc:Font, s10 bold c006C73, Malgun Gothic
    Gui, SSOKCalc:Add, Edit, x12 y330 w656 h170 ReadOnly +Multi +Wrap -WantReturn HwndSSOK_CalcResultHwnd vSSOK_CalcResult,

    ; =====================================================
    ; °æ·Â±â°£ ÀÔ·Â ¿µ¿ª (ÃÖ´ë 10°³)
    ; 9°³ ¸Þ´º ¾Æ·¡¿¡ Ç¥½Ã / ¼±ÅÃ ¹öÆ°À¸·Î ÀÎÁ¤ ¿©ºÎ °áÁ¤
    ; =====================================================
    thisYear := A_YYYY + 0
    ; °æ·Â ±âº»°ª: 1¹øÀº ¿ÃÇØ 3/1~´ÙÀ½ ÇØ 2¿ù ¸»ÀÏ, 2¹øºÎÅÍ °ú°Å ¿¬µµ ¼øÀ¸·Î 10°³
    careerDefaultStarts := {}
    careerDefaultEnds := {}
    Loop, 10
    {
        idx := A_Index
        sy := thisYear - (idx - 1)
        ey := sy + 1
        careerDefaultStarts[idx] := sy . "0301000000"
        endDay := (Mod(ey, 4) = 0 && (Mod(ey, 100) != 0 || Mod(ey, 400) = 0)) ? 29 : 28
        careerDefaultEnds[idx] := ey . "02" . endDay . "000000"
    }

    Gui, SSOKCalc:Font, s11 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x12 y98 w656 h28 Hidden vSSOK_CareerTitle, °æ·Â±â°£
    Gui, SSOKCalc:Font, s9 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, GroupBox, x12 y126 w656 h700 Hidden vSSOK_CareerGroup, °æ·Â±â°£ ÀÔ·Â
    Gui, SSOKCalc:Add, Text, x20 y148 w52 h20 Center Hidden vSSOK_CareerHeadV, ¼±ÅÃ
    Gui, SSOKCalc:Add, Text, x74 y148 w28 h20 Center Hidden vSSOK_CareerHeadNo, ±¸ºÐ
    Gui, SSOKCalc:Add, Text, x108 y148 w140 h20 Center Hidden vSSOK_CareerHeadStart, ½ÃÀÛÀÏ
    Gui, SSOKCalc:Add, Text, x256 y148 w140 h20 Center Hidden vSSOK_CareerHeadEnd, Á¾·áÀÏ
    Gui, SSOKCalc:Add, Text, x404 y148 w72 h20 Center Hidden vSSOK_CareerHeadRate, ÀÎÁ¤·ü
    Gui, SSOKCalc:Add, Text, x550 y148 w105 h20 Center Hidden vSSOK_CareerHeadYMD, ÀÎÁ¤ °æ·Â

    Gui, SSOKCalc:Font, s8 norm c173F52, Malgun Gothic
    SSOK_CareerYMDHwnd := {}
    Loop, 10
    {
        idx := A_Index
        y := 172 + ((idx - 1) * 40)
        ; ½ÇÁ¦ CheckBox ÄÁÆ®·ÑÀ» »ç¿ëÇÕ´Ï´Ù.
        ; 1¹øÀº °æ·Â±â°£ È­¸éÀ» ¿­ ¶§ ±âº» ¼±ÅÃ(Ã¼Å©) »óÅÂÀÔ´Ï´Ù.
        SSOK_CareerSelected[idx] := (idx = 1)
        checkOpt := (idx = 1) ? "Checked" : ""
        Gui, SSOKCalc:Add, CheckBox, x20 y%y% w52 h28 Center Hidden vSSOK_CareerUse%idx% gSSOK_CareerSelectionChanged %checkOpt%, ¼±ÅÃ
        Gui, SSOKCalc:Add, Text, x74 y%y% w28 h28 Center +0x200 Hidden vSSOK_CareerNo%idx%, %idx%

        chooseStart := careerDefaultStarts[idx]
        chooseEnd := careerDefaultEnds[idx]

        Gui, SSOKCalc:Add, DateTime, x108 y%y% w140 h28 Hidden vSSOK_CareerStart%idx% Choose%chooseStart% gSSOK_CareerDateChanged, yyyy-MM-dd
        Gui, SSOKCalc:Add, DateTime, x256 y%y% w140 h28 Hidden vSSOK_CareerEnd%idx% Choose%chooseEnd% gSSOK_CareerDateChanged, yyyy-MM-dd
        ; ÀÎÁ¤·ü: 0~100% ¼ýÀÚ ÀÔ·Â + ½ÇÁ¦ UpDown(¡ã¡å) Á¶Àý
        Gui, SSOKCalc:Add, Edit, x404 y%y% w72 h28 Center Number Limit3 Hidden vSSOK_CareerRate%idx% gSSOK_CareerRateChanged, 100
        Gui, SSOKCalc:Add, UpDown, Hidden Range0-100 0x80 vSSOK_CareerRateUD%idx% gSSOK_CareerRateChanged, 100
        ; °³º° ÀÎÁ¤°æ·Â Ãâ·ÂÄ­Àº 1~10¹øÀ» ½ÇÁ¦ ÄÁÆ®·Ñ¸íÀ¸·Î ¸í½ÃÇÕ´Ï´Ù.
        ; µ¿Àû vº¯¼ö ¹ÙÀÎµù ¹®Á¦¸¦ ÇÇÇÏ±â À§ÇÑ ¹æ½ÄÀÔ´Ï´Ù.
        if (idx = 1)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD1, -
        else if (idx = 2)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD2, -
        else if (idx = 3)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD3, -
        else if (idx = 4)

Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD4, -
        else if (idx = 5)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD5, -
        else if (idx = 6)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD6, -
        else if (idx = 7)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD7, -
        else if (idx = 8)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD8, -
        else if (idx = 9)
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD9, -
        else
            Gui, SSOKCalc:Add, Text, x550 y%y% w105 h28 Center +0x200 Hidden HwndhCareerYMD vSSOK_CareerYMD10, -

        SSOK_CareerYMDHwnd[idx] := hCareerYMD

        ; ÄÁÆ®·ÑÀ» ¸¸µé ¶§ V º¯¼öµµ Áï½Ã ÃÊ±âÈ­ÇÕ´Ï´Ù.
        ; Ã¹ °è»ê Àü¿¡ Submit¿¡ ÀÇÁ¸ÇÏÁö ¾Ê¾Æ ±âº» ÀÎÁ¤°æ·ÂÀÌ ¹Ýµå½Ã °è»êµÇµµ·Ï ÇÕ´Ï´Ù.
    }

    Gui, SSOKCalc:Font, s9 bold c173F52, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x22 y590 w95 h24 +0x200 Hidden vSSOK_CareerTotalLabel, ÃÑ ±Ù¹«³âÇÑ
    Gui, SSOKCalc:Add, Text, x120 y590 w180 h24 Center +0x200 Hidden vSSOK_CareerTotalYMD, 0³â 0¿ù 0ÀÏ
    Gui, SSOKCalc:Add, Text, x310 y590 w345 h24 Center +0x200 Hidden vSSOK_CareerTotalMonths, ÃÑ ÀÎÁ¤°³¿ù: 0°³¿ù
    Gui, SSOKCalc:Add, Text, x22 y620 w633 h24 Center +0x200 Hidden vSSOK_CareerTotalDays, ÃÑ 0ÀÏ (ÆòÀÏ 0ÀÏ / ÁÖ¸» 0ÀÏ) / ÀÎÁ¤ÀÏ¼ö 0ÀÏ

    ; ±â°£ Áßº¹ °æ°í Ç¥½Ã
    Gui, SSOKCalc:Font, s9 bold cRed, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x22 y646 w633 h20 Center +0x200 Hidden vSSOK_CareerWarnText,

    Gui, SSOKCalc:Font, s8 norm c2A5C70, Malgun Gothic
    Gui, SSOKCalc:Add, Text, x22 y670 w633 h38 Left Hidden vSSOK_CareerHelp1, ¡Ø ¼±ÅÃ ¹öÆ°À» ´©¸¥ °æ·Â¸¸ °è»êÇÕ´Ï´Ù. ½ÃÀÛÀÏ°ú Á¾·áÀÏÀÌ °°À¸¸é 1ÀÏ·Î °è»êÇÕ´Ï´Ù.`n¡Ø ÀÎÁ¤·üÀº °æ·Âº°·Î ÀÔ·ÂÇÏ¸ç ±âº»°ªÀº 100ÀÔ´Ï´Ù.
    Gui, SSOKCalc:Add, Text, x22 y712 w633 h42 Left Hidden vSSOK_CareerHelp2, ¿¹½Ã: 1¹ø = ¿ÃÇØ 3¿ù 1ÀÏ ~ ´ÙÀ½ ÇØ 2¿ù ¸»ÀÏ / 2¹ø = ÀÛ³â 3¿ù 1ÀÏ ~ ¿ÃÇØ 2¿ù ¸»ÀÏ.`n¡Ø À±³âÀÇ 2¿ù ¸»ÀÏÀº 29ÀÏÀÌ¸ç, ¼±ÅÃµÈ ±â°£ÀÌ ¼­·Î °ãÄ¡¸é Áßº¹ ³¯Â¥´Â ÇÑ ¹ø¸¸ ÇÕ»êÇÕ´Ï´Ù.

    Gui, SSOKCalc:Add, Button, x22 y770 w633 h34 Hidden vSSOK_CareerCopyBtn gSSOK_CareerCopy, °æ·Â °á°ú º¹»ç
    SSOK_Tool_GetCalculatorPos(680, 850, SSOK_CalcWinX, SSOK_CalcWinY)
    Gui, SSOKCalc:Show, x%SSOK_CalcWinX% y%SSOK_CalcWinY% w680 h850, SSOK ÇàÁ¤¾÷¹« °£Æí °è»ê±â

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

    ; °æ·Â±â°£¿¡¼­ µ¹¾Æ¿Íµµ °øÅë Á¦¸ñ°ú °á°ú ¿µ¿ªÀ» ´Ù½Ã Ç¥½ÃÇÕ´Ï´Ù.
    GuiControl, SSOKCalc:Show, SSOK_CalcHelp
    GuiControl, SSOKCalc:Show, SSOK_CalcPrompt1
    GuiControl, SSOKCalc:Show, SSOK_CalcResultLabel
    GuiControl, SSOKCalc:Show, SSOK_CalcResult
    GuiControl, SSOKCalc:Hide, SSOK_CareerWarnText

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

    ; °æ·Â±â°£ Àü¿ë ÄÁÆ®·ÑÀº ±âº»ÀûÀ¸·Î ¼û±è
    GuiControl, SSOKCalc:Hide, SSOK_CareerTitle
    GuiControl, SSOKCalc:Hide, SSOK_CareerGroup
    GuiControl, SSOKCalc:Hide, SSOK_CareerHeadNo
    GuiControl, SSOKCalc:Hide, SSOK_CareerHeadStart
    GuiControl, SSOKCalc:Hide, SSOK_CareerHeadEnd
    GuiControl, SSOKCalc:Hide, SSOK_CareerHeadV
    GuiControl, SSOKCalc:Hide, SSOK_CareerHeadRate
    GuiControl, SSOKCalc:Hide, SSOK_CareerHeadYMD
    Loop, 10
    {
        idx := A_Index
        GuiControl, SSOKCalc:Hide, % "SSOK_CareerUse" . idx
        GuiControl, SSOKCalc:Hide, % "SSOK_CareerNo" . idx
        GuiControl, SSOKCalc:Hide, % "SSOK_CareerStart" . idx
        GuiControl, SSOKCalc:Hide, % "SSOK_CareerEnd" . idx
        GuiControl, SSOKCalc:Hide, % "SSOK_CareerRate" . idx
        GuiControl, SSOKCalc:Hide, % "SSOK_CareerRateUD" . idx
        GuiControl, SSOKCalc:Hide, % "SSOK_CareerYMD" . idx
    }
    GuiControl, SSOKCalc:Hide, SSOK_CareerTotalLabel
    GuiControl, SSOKCalc:Hide, SSOK_CareerTotalYMD
    GuiControl, SSOKCalc:Hide, SSOK_CareerTotalMonths
    GuiControl, SSOKCalc:Hide, SSOK_CareerTotalDays
    GuiControl, SSOKCalc:Hide, SSOK_CareerHelp1
    GuiControl, SSOKCalc:Hide, SSOK_CareerHelp2
    GuiControl, SSOKCalc:Hide, SSOK_CareerCopyBtn

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

    if (SSOK_CalcMode = "career")
    {
        Gui, SSOKCalc:Show, x%SSOK_CalcWinX% y%SSOK_CalcWinY% w680 h850, SSOK ÇàÁ¤¾÷¹« °£Æí °è»ê±â - °æ·Â±â°£

        GuiControl, SSOKCalc:Hide, SSOK_CalcHelp
        GuiControl, SSOKCalc:Hide, SSOK_CalcPrompt1
        GuiControl, SSOKCalc:Hide, SSOK_CalcPrompt2
        GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
        GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
        GuiControl, SSOKCalc:Hide, SSOK_CalcDate_Start
        GuiControl, SSOKCalc:Hide, SSOK_CalcAge_Birth
        GuiControl, SSOKCalc:Hide, SSOK_CalcAge_Ref
        GuiControl, SSOKCalc:Hide, SSOK_CalcBid_Date
        GuiControl, SSOKCalc:Hide, SSOK_CalcWork_Start
        GuiControl, SSOKCalc:Hide, SSOK_CalcWork_End
        GuiControl, SSOKCalc:Hide, SSOK_CalcRateLabel
        GuiControl, SSOKCalc:Hide, SSOK_CalcRate
        GuiControl, SSOKCalc:Hide, SSOK_CalcRateUnit
        GuiControl, SSOKCalc:Hide, SSOK_CalcProcureRad1
        GuiControl, SSOKCalc:Hide, SSOK_CalcProcureRad2
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetLabel
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn1
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn2
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn3
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn4
        GuiControl, SSOKCalc:Hide, SSOK_CalcBudgetBtn5
        GuiControl, SSOKCalc:Hide, SSOK_CalcCalculateBtn
        GuiControl, SSOKCalc:Hide, SSOK_CalcCopyBtn
        GuiControl, SSOKCalc:Hide, SSOK_CalcPrecisionLabel
        GuiControl, SSOKCalc:Hide, SSOK_CalcRadPrec0
        GuiControl, SSOKCalc:Hide, SSOK_CalcRadPrec1
        GuiControl, SSOKCalc:Hide, SSOK_CalcRadPrec2
        GuiControl, SSOKCalc:Hide, SSOK_CalcRadPrec4
        GuiControl, SSOKCalc:Hide, SSOK_CalcResultLabel
        GuiControl, SSOKCalc:Hide, SSOK_CalcResult

        GuiControl, SSOKCalc:Show, SSOK_CareerTitle
        GuiControl, SSOKCalc:Show, SSOK_CareerGroup
        GuiControl, SSOKCalc:Show, SSOK_CareerHeadNo
        GuiControl, SSOKCalc:Show, SSOK_CareerHeadStart
        GuiControl, SSOKCalc:Show, SSOK_CareerHeadEnd
        GuiControl, SSOKCalc:Show, SSOK_CareerHeadV
        GuiControl, SSOKCalc:Show, SSOK_CareerHeadRate
        GuiControl, SSOKCalc:Show, SSOK_CareerHeadYMD
        Loop, 10
        {
            idx := A_Index
            GuiControl, SSOKCalc:Show, % "SSOK_CareerUse" . idx
            GuiControl, SSOKCalc:Show, % "SSOK_CareerNo" . idx
            GuiControl, SSOKCalc:Show, % "SSOK_CareerStart" . idx
            GuiControl, SSOKCalc:Show, % "SSOK_CareerEnd" . idx
            GuiControl, SSOKCalc:Show, % "SSOK_CareerRate" . idx
            GuiControl, SSOKCalc:Show, % "SSOK_CareerRateUD" . idx
            GuiControl, SSOKCalc:Show, % "SSOK_CareerYMD" . idx
            SSOK_CareerShowYMD(idx)
        }
        GuiControl, SSOKCalc:Show, SSOK_CareerTotalLabel
        GuiControl, SSOKCalc:Show, SSOK_CareerTotalYMD
        GuiControl, SSOKCalc:Show, SSOK_CareerTotalMonths
        GuiControl, SSOKCalc:Show, SSOK_CareerTotalDays
        GuiControl, SSOKCalc:Show, SSOK_CareerUse1
        GuiControl, SSOKCalc:Show, SSOK_CareerWarnText
        GuiControl, SSOKCalc:+Redraw, SSOK_CareerTotalYMD
        GuiControl, SSOKCalc:+Redraw, SSOK_CareerTotalMonths
        GuiControl, SSOKCalc:+Redraw, SSOK_CareerTotalDays
        GuiControl, SSOKCalc:Show, SSOK_CareerHelp1
        GuiControl, SSOKCalc:Show, SSOK_CareerHelp2
        GuiControl, SSOKCalc:Show, SSOK_CareerCopyBtn

        Gosub, SSOK_CareerCalculate
        SetTimer, SSOK_CareerInitialCalculate, -100
        return
    }
    else if (SSOK_CalcMode = "budget")
    {
        SSOK_CalcSetPrecisionVisible(false)
        ; °è»ê(Enter) ¹öÆ°Àº ¿¹»ê ¸ðµå¿¡¼­ ¿ÏÀü °Ý¸®/¼û±è (Áßº¹ ¿À¹ö·¦ ¹æÁö)
        GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x-999 y-999 w10 h10
        GuiControl, SSOKCalc:Hide, SSOK_CalcCalculateBtn

        ; ¿¹»ê ÃÑ¾× ÀÔ·ÂÄ­: ³ôÀÌ 3¹è(h54), ±ÛÀÚ Å©±â 2¹è(s18 bold)
        Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
        GuiControl, SSOKCalc:Font, SSOK_CalcInput1
        GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y146 w656 h54
        GuiControl, SSOKCalc:Show, SSOK_CalcInput1

        ; ¿¹»êºñ¸ñÀº ÀÔ·ÂÄ­ ÇÏ´Ü(y200) ¾Æ·¡ µ¶¸³µÈ Çà¿¡ ¹èÄ¡
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetLabel, x12 y210 w42 h22
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn1, x56 y206 w74 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn2, x133 y206 w70 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn3, x206 y206 w74 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn4, x283 y206 w74 h28
        GuiControl, SSOKCalc:Move, SSOK_CalcBudgetBtn5, x360 y206 w82 h28

        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetLabel
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn1
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn2
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn3
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn4
        GuiControl, SSOKCalc:Show, SSOK_CalcBudgetBtn5

        ; °á°ú º¹»ç ¹öÆ° ÀüÃ¼ ³Êºñ ¹èÄ¡
        GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x12 y242 w656 h30
        GuiControl, SSOKCalc:Show, SSOK_CalcCopyBtn
        GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y308
        GuiControl, SSOKCalc:Move, SSOK_CalcResult, y330 h170

        GuiControl, SSOKCalc:, SSOK_CalcHelp, ¿¹»ê »êÃâ³»¿ª: ¿¹»ê ÃÑ¾×À» ÀÔ·ÂÇÏ°í ºñ¸ñ ¹öÆ°À» ´©¸£¸é »êÃâ½ÄÀÌ ÀÚµ¿ ÀÛ¼ºµË´Ï´Ù.
        GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ¿¹»ê ÃÑ¾× ÀÔ·Â (¿¹: 1,000,000):
        GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 y126 w656
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
        GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x12 y242 w455 h30
        GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x477 y242 w191 h30
        GuiControl, SSOKCalc:Show, SSOK_CalcCalculateBtn
        GuiControl, SSOKCalc:Show, SSOK_CalcCopyBtn
        GuiControl, SSOKCalc:Text, SSOK_CalcCalculateBtn, °è»ê (Enter)

        if (SSOK_CalcMode = "expr")
        {
            ; ÀÏ¹Ý°è»ê: ´ëÇü ÀÔ·ÂÄ­ (h54, s18 bold)
            Gui, SSOKCalc:Font, s18 bold c173F52, Malgun Gothic
            GuiControl, SSOKCalc:Font, SSOK_CalcInput1
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y146 w656 h54
            GuiControl, SSOKCalc:Show, SSOK_CalcInput1

            SSOK_CalcSetPrecisionVisible(true)
            GuiControl, SSOKCalc:Move, SSOK_CalcPrecisionLabel, y280
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec0, y279
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec1, y279
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec2, y279
            GuiControl, SSOKCalc:Move, SSOK_CalcRadPrec4, y279

            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y308
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y330 h170
            GuiControl, SSOKCalc:, SSOK_CalcHelp, ¿¹: 5,000 * 2°³ * 4ÁÖ=  ¶Ç´Â  (1,000 + 2,000) * 10
            GuiControl, SSOKCalc:, SSOK_CalcPrompt1, °è»ê ¼ö½Ä ¶Ç´Â ±Ý¾× ÀÔ·Â:
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 y126 w656
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
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y146 w656 h54
            GuiControl, SSOKCalc:Show, SSOK_CalcInput1

            SSOK_CalcSetPrecisionVisible(false)
            GuiControl, SSOKCalc:Text, SSOK_CalcCalculateBtn, VAT °è»ê (Enter)
            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y280
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y304 h196
            GuiControl, SSOKCalc:, SSOK_CalcHelp, % "VAT °è»ê: ±Ý¾×À» ÀÔ·ÂÇÏ¸é °ø±Þ°¡¾×(¿ø°¡)°ú ºÎ°¡¼¼(10%)¸¦ Áï½Ã ÀÚµ¿ °è»êÇÕ´Ï´Ù."
            GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ±Ý¾× ÀÔ·Â (¿¹: 10,000):
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 y126 w656
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
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y146 w656 h54
            GuiControl, SSOKCalc:Show, SSOK_CalcInput1

            SSOK_CalcSetPrecisionVisible(false)
            GuiControl, SSOKCalc:Text, SSOK_CalcCalculateBtn, Á¶´Þ¼ö¼ö·á °è»ê (Enter)
            GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x12 y242 w455 h30
            GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x477 y242 w191 h30
            GuiControl, SSOKCalc:Show, SSOK_CalcProcureRad1
            GuiControl, SSOKCalc:Show, SSOK_CalcProcureRad2
            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y308
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y330 h170
            GuiControl, SSOKCalc:, SSOK_CalcHelp, % "Á¶´Þ¼ö¼ö·á: °è¾à(±¸¸Å) ±Ý¾×À» ³Ö°í °è¾à ¹æ½ÄÀ» ¼±ÅÃÇÏ¸é Á¶´ÞÃ» ¼ö¼ö·á¸¦ Áï½Ã °è»êÇÕ´Ï´Ù."
            GuiControl, SSOKCalc:, SSOK_CalcPrompt1, °è¾à(±¸¸Å) ±Ý¾× ÀÔ·Â (¿¹: 30,000,000 ¶Ç´Â 3000¸¸):
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 y126 w656
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
            GuiControl, SSOKCalc:Move, SSOK_CalcInput1, x12 y146 w300 h42
            GuiControl, SSOKCalc:Move, SSOK_CalcInput2, x324 y146 w300 h42

            SSOK_CalcSetPrecisionVisible(false)
            GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y280
            GuiControl, SSOKCalc:Move, SSOK_CalcResult, y304 h196
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt1, x12 y126 w300
            GuiControl, SSOKCalc:Move, SSOK_CalcPrompt2, x324 y126 w300
            GuiControl, SSOKCalc:Show, SSOK_CalcPrompt2
            GuiControl, SSOKCalc:Show, SSOK_CalcInput2

            if (SSOK_CalcMode = "date")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Show, SSOK_CalcDate_Start
                GuiControl, SSOKCalc:Move, SSOK_CalcDate_Start, x12 y146 w300 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcInput2
                Gui, SSOKCalc:Font, s13 bold c173F52, Malgun Gothic
                GuiControl, SSOKCalc:Font, SSOK_CalcInput2
                GuiControl, SSOKCalc:Move, SSOK_CalcInput2, x324 y146 w300 h42

                GuiControl, SSOKCalc:, SSOK_CalcHelp, ³¯Â¥¡¤¿äÀÏ °è»ê: ³¯Â¥¿Í ¿äÀÏÀ» È®ÀÎÇÏ°Å³ª ±â°£(+100ÀÏ µî)À» °è»êÇÕ´Ï´Ù.
                GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ½ÃÀÛÀÏÀÚ:
                GuiControl, SSOKCalc:, SSOK_CalcPrompt2, Á¾·áÀÏÀÚ ¶Ç´Â ÀÏ¼ö (¿¹: +100):

                ; ÀÎÁ¤·ü ÄÁÆ®·Ñ Ç¥½Ã ¹× ¹öÆ°/°á°úÃ¢ ÀÌµ¿
                GuiControl, SSOKCalc:Show, SSOK_CalcRateLabel
                GuiControl, SSOKCalc:Show, SSOK_CalcRate
                GuiControl, SSOKCalc:Show, SSOK_CalcRateUnit
                GuiControl, SSOKCalc:Move, SSOK_CalcCalculateBtn, x12 y242 w455 h30
                GuiControl, SSOKCalc:Move, SSOK_CalcCopyBtn, x477 y242 w191 h30
                GuiControl, SSOKCalc:Move, SSOK_CalcResultLabel, y280
                GuiControl, SSOKCalc:Move, SSOK_CalcResult, y304 h196
            }
            else if (SSOK_CalcMode = "age")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
                GuiControl, SSOKCalc:Show, SSOK_CalcAge_Birth
                GuiControl, SSOKCalc:Move, SSOK_CalcAge_Birth, x12 y146 w300 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcAge_Ref
                GuiControl, SSOKCalc:Move, SSOK_CalcAge_Ref, x324 y146 w300 h42

                GuiControl, SSOKCalc:, SSOK_CalcHelp, ³ªÀÌ.ÅðÁ÷: »ý³â¿ùÀÏÀ» ³ÖÀ¸¸é ¸¸ ³ªÀÌ ¹× °ø¹«¿ø/°ø¹«Á÷ Á¤³âÅðÁ÷ÀÏÀÌ °è»êµË´Ï´Ù.
                GuiControl, SSOKCalc:, SSOK_CalcPrompt1, »ý³â¿ùÀÏ:
                GuiControl, SSOKCalc:, SSOK_CalcPrompt2, ±âÁØÀÏ:
            }
            else if (SSOK_CalcMode = "workday")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput2
                GuiControl, SSOKCalc:Show, SSOK_CalcWork_Start
                GuiControl, SSOKCalc:Move, SSOK_CalcWork_Start, x12 y146 w300 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcWork_End
                GuiControl, SSOKCalc:Move, SSOK_CalcWork_End, x324 y146 w300 h42

                GuiControl, SSOKCalc:, SSOK_CalcHelp, ±Ù¹«½Ã°£ °è»ê: ½ÃÀÛÀÏ½Ã¿Í Á¾·áÀÏ½Ã¸¦ ¼±ÅÃ/ÀÔ·ÂÇÏ¸é ÃÑ ±Ù¹«½Ã°£À» 1ºÐ ´ÜÀ§·Î Á¤È®È÷ °è»êÇÕ´Ï´Ù.
                GuiControl, SSOKCalc:, SSOK_CalcPrompt1, ½ÃÀÛ½Ã°£ (ÀÏ½Ã ¼±ÅÃ):
                GuiControl, SSOKCalc:, SSOK_CalcPrompt2, Á¾·á½Ã°£ (ÀÏ½Ã ¼±ÅÃ):
            }
            else if (SSOK_CalcMode = "bid")
            {
                GuiControl, SSOKCalc:Hide, SSOK_CalcInput1
                GuiControl, SSOKCalc:Show, SSOK_CalcBid_Date
                GuiControl, SSOKCalc:Move, SSOK_CalcBid_Date, x12 y146 w300 h42
                GuiControl, SSOKCalc:Show, SSOK_CalcInput2
                Gui, SSOKCalc:Font, s13 bold c173F52, Malgun Gothic
                GuiControl, SSOKCalc:Font, SSOK_CalcInput2
                GuiControl, SSOKCalc:Move, SSOK_CalcInput2, x324 y146 w300 h42

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
    activeIdx := (SSOK_CalcMode = "expr") ? 1 : (SSOK_CalcMode = "date") ? 2 : (SSOK_CalcMode = "age") ? 3 : (SSOK_CalcMode = "workday") ? 4 : (SSOK_CalcMode = "bid") ? 5 : (SSOK_CalcMode = "budget") ? 6 : (SSOK_CalcMode = "vat") ? 7 : (SSOK_CalcMode = "procure") ? 8 : 9
    tabNamesList := ["°è»ê±â", "³¯Â¥¡¤¿äÀÏ", "³ªÀÌ.ÅðÁ÷", "±Ù¹«½Ã°£", "ÀÔÂû°ø°í", "¿¹»ê »êÃâ³»¿ª", "VAT °è»ê", "Á¶´Þ¼ö¼ö·á", "°æ·Â±â°£"]
    Loop, 9
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

SSOK_CalcModeCareer:
    SSOK_CalcMode := "career"
    Gosub, SSOK_CalcApplyModeUI
return

SSOK_CalcProcureTypeChanged:
    Gui, SSOKCalc:Submit, NoHide
    GuiControl, SSOKCalc:Text, SSOK_CalcProcureRad1, % SSOK_CalcProcureRad1 ? "¡Ü ³»ÀÚ±¸¸Å ÃÑ¾×°è¾à" : "³»ÀÚ±¸¸Å ÃÑ¾×°è¾à"
    GuiControl, SSOKCalc:Text, SSOK_CalcProcureRad2, % SSOK_CalcProcureRad2 ? "¡Ü Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç°" : "Á¾ÇÕ¼îÇÎ¸ô ÀÏ¹Ý ¹°Ç°"
    if (SSOK_CalcMode = "procure")
        Gosub, SSOK_CalcCalculate
return
SSOK_CareerSelectionChanged:
    if (SSOK_CalcMode != "career")
        return

    if !RegExMatch(A_GuiControl, "(\d+)$", m)
        return
    idx := m1 + 0

    ; ½ÇÁ¦ CheckBoxÀÇ Ã¼Å© »óÅÂ¸¦ ÀÐ½À´Ï´Ù.
    GuiControlGet, checked, SSOKCalc:, %A_GuiControl%
    SSOK_CareerSelected[idx] := (checked = 1)

    Gosub, SSOK_CareerCalculate
return

SSOK_CareerDateChanged:
    if (SSOK_CalcMode = "career")
        Gosub, SSOK_CareerCalculate
return

SSOK_CareerRateChanged:
    if (SSOK_CalcMode = "career")
    {
        ; ¼ýÀÚ¸¦ Á÷Á¢ ÀÔ·ÂÇÏ´Â µ¿¾È¿¡´Â °ªÀ» µ¤¾î¾²Áö ¾Ê½À´Ï´Ù.
        ; ÀÔ·ÂÀÌ ³¡³­ µÚ 400ms ÈÄ ÇÑ ¹ø¸¸ °è»êÇÕ´Ï´Ù.
        SetTimer, SSOK_CareerRateCalcTimer, Off
        SetTimer, SSOK_CareerRateCalcTimer, -400
    }
return

SSOK_CareerRateCalcTimer:
    if (SSOK_CalcMode = "career")
        Gosub, SSOK_CareerCalculate
return

SSOK_CareerInitialCalculate:
    if (SSOK_CalcMode = "career")
        Gosub, SSOK_CareerCalculate
return

SSOK_CareerCalculate:
    if (SSOK_CalcMode != "career")
        return

    ; ÇöÀç È­¸éÀÇ DateTime/Edit/CheckBox °ªÀ» AHK vº¯¼ö¿¡ È®Á¤
    Gui, SSOKCalc:Submit, NoHide

    ; ³¯Â¥¿Í ÀÎÁ¤·üÀº SubmitÀ¸·Î È®Á¤µÈ vº¯¼ö¿¡¼­ ÀÐ½À´Ï´Ù.
    totalStdDays := 0
    totalCalendarDays := 0
    totalWeekdays := 0
    totalWeekends := 0
    totalRecognizedCalendarDays := 0
    totalMonths := 0
    selectedPeriods := []
    ; v52: Create row state objects before writing indexed values.
    ; AHK v1 does not turn an empty variable into an object on indexed assignment.
    SSOK_CareerValid := {}
    SSOK_CareerOverlap := {}
    SSOK_CareerD1 := {}
    SSOK_CareerD2 := {}
    SSOK_CareerRateValue := {}
    resultText := "[°æ·Â±â°£ °è»ê °á°ú]`n`n"
    hasOverlap := false

    ; 1. ³¯Â¥¿Í ÀÎÁ¤·ü ¼öÁý
    Loop, 10
    {
        idx := A_Index
        SSOK_CareerValid[idx] := false
        SSOK_CareerOverlap[idx] := false
        SSOK_CareerD1[idx] := ""
        SSOK_CareerD2[idx] := ""

        startControl := "SSOK_CareerStart" . idx
        endControl := "SSOK_CareerEnd" . idx
        rateControl := "SSOK_CareerRate" . idx
        ymdControl := "SSOK_CareerYMD" . idx
        useControl := "SSOK_CareerUse" . idx
        GuiControlGet, checked, SSOKCalc:, %useControl%
        SSOK_CareerSelected[idx] := (checked = 1)

        ; DateTime PickerÀÇ ½ÇÁ¦ ¼±ÅÃ ³¯Â¥¸¦ Á÷Á¢ ÀÐ½À´Ï´Ù.
        startDate := SSOK_CareerReadDateControl(startControl, careerDefaultStarts[idx])
        endDate := SSOK_CareerReadDateControl(endControl, careerDefaultEnds[idx])

        ; ÀÎÁ¤·üÀº ½ÇÁ¦ Edit ÄÁÆ®·ÑÀÇ ÇöÀç ÅØ½ºÆ®¸¦ ¿ì¼± ÀÐ½À´Ï´Ù.
        GuiControlGet, rateText, SSOKCalc:, %rateControl%
        if (rateText = "")
        {
            GuiControlGet, rateHwnd, SSOKCalc:Hwnd, %rateControl%
            if (rateHwnd)
                ControlGetText, rateText,, ahk_id %rateHwnd%
        }

        if (startDate = "" || endDate = "")
        {
            SSOK_CareerSetYMD(idx, "³¯Â¥ È®ÀÎ", true)
            continue
        }

        if (startDate > endDate)
        {
            SSOK_CareerSetYMD(idx, "½ÃÀÛÀÏ > Á¾·áÀÏ", true)
            continue
        }

        rateText := RegExReplace(Trim(rateText), "[^0-9]")
        if (rateText = "")
            rate := 100
        else
            rate := rateText + 0

        if (rate < 0)
            rate := 0
        if (rate > 100)
            rate := 100

        ; »ç¿ëÀÚ°¡ ÀÔ·ÂÇÑ ÀÎÁ¤·üÀ» ±×´ë·Î À¯ÁöÇÕ´Ï´Ù.
        ; ¹üÀ§ ¹Û ¼ýÀÚ¸¸ ³»ºÎ °è»ê°ª¿¡¼­ 0~100À¸·Î Á¦ÇÑÇÕ´Ï´Ù.

        SSOK_CareerD1[idx] := startDate
        SSOK_CareerD2[idx] := endDate
        SSOK_CareerRateValue[idx] := rate
        SSOK_CareerValid[idx] := true

        p := {"index": idx, "start": startDate, "end": endDate, "rate": rate}
        if (SSOK_CareerSelected[idx])
            selectedPeriods.Push(p)
    }

    ; 2. ¼±ÅÃµÈ ±â°£ÀÇ Start~End ±³Â÷ °ËÁõ
    selectedCount := selectedPeriods.Length()
    Loop, %selectedCount%
    {
        i := A_Index
        p1 := selectedPeriods[i]

        Loop, %selectedCount%
        {
            j := A_Index
            if (j <= i)
                continue

            p2 := selectedPeriods[j]

            if (p1.start <= p2.end && p2.start <= p1.end)
            {
                SSOK_CareerOverlap[p1.index] := true
                SSOK_CareerOverlap[p2.index] := true
                hasOverlap := true
            }
        }
    }

    ; 3. °¢ ÇàÀÇ ÀÎÁ¤°æ·ÂÀ» Ç¥½ÃÇÏ±â Àü¿¡ 1~10¹ø °á°úÄ­À» ¸ðµÎ Ç¥½Ã
    Loop, 10
    {
        SSOK_CareerShowYMD(A_Index)
    }

    Loop, 10
    {
        idx := A_Index
        ymdControl := "SSOK_CareerYMD" . idx

        if (!SSOK_CareerSelected[idx])
        {
            SSOK_CareerSetYMD(idx, "0³â 0¿ù 0ÀÏ", false)
            continue
        }

        if (!SSOK_CareerValid[idx])
        {
            continue
        }

        d1 := SSOK_CareerD1[idx]
        d2 := SSOK_CareerD2[idx]
        rate := SSOK_CareerRateValue[idx]

        calendarDays := SSOK_CareerDaysInclusive(d1, d2)
        if (calendarDays <= 0)
        {
            SSOK_CareerSetYMD(idx, "°è»ê ¿À·ù", true)
            continue
        }

        ymd := SSOK_CareerCalcYMD(d1, d2)
        stdDays := SSOK_CareerYMDTo360Days(ymd)
        if (stdDays <= 0)
            stdDays := calendarDays

        recognizedStdDays := Floor(stdDays * rate / 100)
        if (calendarDays = 1 && rate > 0)
            recognizedStdDays := 1

        recognizedYMD := SSOK_Career360DaysToYMD(recognizedStdDays)

        if (SSOK_CareerOverlap[idx])
            displayYMD := "Áßº¹ / " . recognizedYMD
        else
            displayYMD := recognizedYMD

        ; 1¹ø¡æYMD1 ... 10¹ø¡æYMD10
        ; »ö»ó°ú ÅØ½ºÆ®¸¦ ÇÑ ÇÔ¼ö¿¡¼­ µ¿½Ã¿¡ Àû¿ëÇÕ´Ï´Ù.
        SSOK_CareerSetYMD(idx, displayYMD, SSOK_CareerOverlap[idx])


        resultText .= idx . ". " . d1 . " ~ " . d2 . " | ÀÎÁ¤·ü " . rate . " | " . displayYMD . "`n"
    }

    ; 4. ¼±ÅÃµÈ °¢ ÇàÀÇ ÀÎÁ¤°æ·ÂÀ» °¢°¢ ÇÕ»ê
    ; Áß¿ä: ±â°£À» ÇÏ³ª·Î º´ÇÕÇÏ¸é¼­ ÃÖ°í ÀÎÁ¤·üÀ» Àû¿ëÇÏ¸é
    ; ¼­·Î ´Ù¸¥ ÀÎÁ¤·ü(¿¹: 90% + 100%)¿¡¼­ ÇÕ°è°¡ Æ²¾îÁý´Ï´Ù.
    ; µû¶ó¼­ °¢ ¼±ÅÃ ÇàÀ» µ¶¸³ÀûÀ¸·Î °è»êÇÏ¿© ÇÕ»êÇÕ´Ï´Ù.
    Loop, %selectedCount%
    {
        p := selectedPeriods[A_Index]
        idx := p.index

        ; ¼­·Î °ãÄ¡´Â ¼±ÅÃ ±â°£Àº Áßº¹ °è»êÀ» ¹æÁöÇÏ±â À§ÇØ ÇÕ°è¿¡¼­ Á¦¿Ü
        if (SSOK_CareerOverlap[idx])
            continue

        d1 := p.start
        d2 := p.end
        rate := p.rate

        calendarDays := SSOK_CareerDaysInclusive(d1, d2)
        ymd := SSOK_CareerCalcYMD(d1, d2)
        stdDays := SSOK_CareerYMDTo360Days(ymd)
        if (stdDays <= 0)
            stdDays := calendarDays

        recognizedStdDays := Floor(stdDays * rate / 100)
        if (calendarDays = 1 && rate > 0)
            recognizedStdDays := 1

        weekdays := SSOK_CareerWeekdays(d1, calendarDays)
        weekends := calendarDays - weekdays
        recognizedCalendarDays := Floor(calendarDays * rate / 100)
        if (calendarDays = 1 && rate > 0)
            recognizedCalendarDays := 1

        totalStdDays += recognizedStdDays
        totalCalendarDays += calendarDays
        totalWeekdays += weekdays
        totalWeekends += weekends
        totalRecognizedCalendarDays += recognizedCalendarDays
    }

    totalMonths := Floor(totalStdDays / 30)
    totalYMD := SSOK_Career360DaysToYMD(totalStdDays)

    ; 5. ÇÕ°è Ç¥½Ã
    GuiControl, SSOKCalc:Show, SSOK_CareerTotalYMD
    GuiControl, SSOKCalc:Show, SSOK_CareerTotalMonths
    GuiControl, SSOKCalc:Show, SSOK_CareerTotalDays
    totalMonthsText := "ÃÑ ÀÎÁ¤°³¿ù: " . SSOK_CalcAddCommas(totalMonths) . "°³¿ù"
    totalDaysText := "ÃÑ " . SSOK_CalcAddCommas(totalCalendarDays) . "ÀÏ (ÆòÀÏ " . SSOK_CalcAddCommas(totalWeekdays) . "ÀÏ / ÁÖ¸» " . SSOK_CalcAddCommas(totalWeekends) . "ÀÏ) / ÀÎÁ¤ÀÏ¼ö " . SSOK_CalcAddCommas(totalRecognizedCalendarDays) . "ÀÏ"

    GuiControl, SSOKCalc:, SSOK_CareerTotalYMD, %totalYMD%
    GuiControl, SSOKCalc:, SSOK_CareerTotalMonths, %totalMonthsText%
    GuiControl, SSOKCalc:, SSOK_CareerTotalDays, %totalDaysText%
    GuiControl, SSOKCalc:+Redraw, SSOK_CareerTotalYMD
    GuiControl, SSOKCalc:+Redraw, SSOK_CareerTotalMonths
    GuiControl, SSOKCalc:+Redraw, SSOK_CareerTotalDays

    ; 6. Áßº¹ °æ°í
    if (hasOverlap)
    {
        GuiControl, SSOKCalc:+cRed, SSOK_CareerWarnText
        GuiControl, SSOKCalc:, SSOK_CareerWarnText, [°æ°í] ¼±ÅÃµÈ °æ·Â±â°£¿¡ Áßº¹/°ãÄ§ÀÌ ÀÖ½À´Ï´Ù. Áßº¹ ³¯Â¥´Â ÇÑ ¹ø¸¸ ÇÕ»êÇß½À´Ï´Ù.
    }
    else if (selectedCount > 0)
    {
        GuiControl, SSOKCalc:+c0078D7, SSOK_CareerWarnText
        GuiControl, SSOKCalc:, SSOK_CareerWarnText, [Á¤»ó] ¼±ÅÃµÈ °æ·Â±â°£¿¡ Áßº¹ÀÌ ¾ø½À´Ï´Ù.
    }
    else
    {
        GuiControl, SSOKCalc:+c777777, SSOK_CareerWarnText
        GuiControl, SSOKCalc:, SSOK_CareerWarnText, ¼±ÅÃµÈ °æ·Â±â°£ÀÌ ¾ø½À´Ï´Ù.
    }
    GuiControl, SSOKCalc:+Redraw, SSOK_CareerWarnText

    if (selectedCount = 0)
        resultText .= "`n¼±ÅÃµÈ °æ·Â±â°£ÀÌ ¾ø½À´Ï´Ù. °¢ ÇàÀÇ ¼±ÅÃ ¹öÆ°À» ´­·¯ ÀÎÁ¤ÇÒ °æ·ÂÀ» ÁöÁ¤ÇÏ¼¼¿ä."
    else
    {
        resultText .= "`n[ÇÕ°è]`n"
        resultText .= "- ÃÑ ±Ù¹«³âÇÑ: " . totalYMD . "`n"
        resultText .= "- ÃÑ ÀÎÁ¤°³¿ù: " . SSOK_CalcAddCommas(totalMonths) . "°³¿ù`n"
        resultText .= "- ÃÑ ÀÏ¼ö: " . SSOK_CalcAddCommas(totalCalendarDays) . "ÀÏ`n"
        resultText .= "- ÆòÀÏ: " . SSOK_CalcAddCommas(totalWeekdays) . "ÀÏ / ÁÖ¸»: " . SSOK_CalcAddCommas(totalWeekends) . "ÀÏ`n"
        resultText .= "- ÀÎÁ¤ÀÏ¼ö: " . SSOK_CalcAddCommas(totalRecognizedCalendarDays) . "ÀÏ"
    }

    SSOK_CareerResultText := resultText
return

SSOK_MergeCareerPeriods(periods)
{
    merged := []
    n := periods.Length()
    if (n = 0)
        return merged

    sorted := []
    for _, p in periods
        sorted.Push({"start": p.start, "end": p.end, "rate": p.rate})

    Loop, %n%
    {
        i := A_Index
        Loop, % n - i
        {
            j := A_Index
            if (sorted[j].start > sorted[j+1].start)
            {
                tmp := sorted[j]
                sorted[j] := sorted[j+1]
                sorted[j+1] := tmp
            }
        }
    }

    curr := {"start": sorted[1].start, "end": sorted[1].end, "rate": sorted[1].rate}

    Loop, % n - 1
    {
        nextP := sorted[A_Index + 1]

        if (nextP.start <= SSOK_CareerNextDate(curr.end))
        {
            if (nextP.end > curr.end)
                curr.end := nextP.end
            if (nextP.rate > curr.rate)
                curr.rate := nextP.rate
        }
        else
        {
            merged.Push(curr)
            curr := {"start": nextP.start, "end": nextP.end, "rate": nextP.rate}
        }
    }

    merged.Push(curr)
    return merged
}


SSOK_CareerWeekdays(startDate, totalDays)
{
    startDate := RegExReplace(startDate, "[^0-9]", "")
    if (StrLen(startDate) < 8 || totalDays <= 0)
        return 0

    currentDate := SubStr(startDate, 1, 8) . "000000"
    weekdays := 0

    Loop, %totalDays%
    {
        FormatTime, wday, %currentDate%, WDay

        ; 1=ÀÏ¿äÀÏ, 7=Åä¿äÀÏ
        if (wday != 1 && wday != 7)
            weekdays++

        EnvAdd, currentDate, 1, Days
        if (ErrorLevel)
            break
    }

    return weekdays
}

SSOK_CareerNextDate(date8)
{
    dt := SubStr(date8, 1, 8) . "000000"
    EnvAdd, dt, 1, Days
    return SubStr(dt, 1, 8)
}

SSOK_CareerShowYMD(idx)
{
    ctrl := "SSOK_CareerYMD" . idx
    GuiControl, SSOKCalc:Show, %ctrl%
}

SSOK_CareerSetYMD(idx, value, isRed := false)
{
    ; Use the named GUI control directly; no unchecked DLL call / early return.
    ctrl := "SSOK_CareerYMD" . idx
    color := isRed ? "+cRed" : "+c173F52"
    GuiControl, SSOKCalc:%color%, %ctrl%
    GuiControl, SSOKCalc:, %ctrl%, %value%
    GuiControl, SSOKCalc:Show, %ctrl%
    GuiControl, SSOKCalc:+Redraw, %ctrl%
}


SSOK_CareerReadDateControl(controlName, fallbackRaw := "")
{
    GuiControlGet, hCtrl, SSOKCalc:Hwnd, %controlName%
    if (hCtrl)
    {
        ; DTM_GETSYSTEMTIME (WM_USER + 1)
        VarSetCapacity(st, 16, 0)
        SendMessage, 0x1001, 0, &st,, ahk_id %hCtrl%
        result := ErrorLevel

        ; GDT_VALID = 0
        if (result = 0)
        {
            year := NumGet(st, 0, "UShort")
            month := NumGet(st, 2, "UShort")
            day := NumGet(st, 6, "UShort")

            if (year >= 1000 && month >= 1 && month <= 12 && day >= 1 && day <= 31)
                return Format("{:04}{:02}{:02}", year, month, day)
        }

        ; DateTime Ç¥½Ã ¹®ÀÚ¿­µµ º¸Á¶ÀûÀ¸·Î È®ÀÎ
        ControlGetText, visible,, ahk_id %hCtrl%
        parsed := SSOK_CareerNormalizeDate(visible)
        if (parsed != "")
            return parsed
    }

    parsed := SSOK_CareerNormalizeDate(fallbackRaw)
    return parsed
}


SSOK_CareerNormalizeDate(raw)
{
    raw := Trim(raw)
    if (raw = "")
        return ""

    ; Ç¥½Ã ¹®ÀÚ¿­¿¡¼­ ¼ýÀÚ¸¸ ÃßÃâÇÏ¿© YYYYMMDD¸¦ ¸¸µì´Ï´Ù.
    digits := RegExReplace(raw, "[^0-9]", "")
    if (StrLen(digits) < 8)
        return ""

    date8 := SubStr(digits, 1, 8)

    ; YYYYMMDD 8ÀÚ¸®ÀÎÁö È®ÀÎ
    if !RegExMatch(date8, "^\d{8}$")
        return ""

    y := SubStr(date8, 1, 4) + 0
    m := SubStr(date8, 5, 2) + 0
    d := SubStr(date8, 7, 2) + 0

    if (y < 1000 || m < 1 || m > 12 || d < 1 || d > 31)
        return ""

    return date8
}

SSOK_CareerCalcYMD(a, b)
{
    startDT := SubStr(a, 1, 8) . "000000"
    endDT := SubStr(b, 1, 8) . "000000"

    ; Á¾·áÀÏ Æ÷ÇÔ: Á¾·áÀÏ ´ÙÀ½³¯À» ±âÁØÀ¸·Î °è»ê

EnvAdd, endDT, 1, Days
    if (ErrorLevel)
        return "0³â 0¿ù 0ÀÏ"

    y1 := SubStr(startDT, 1, 4) + 0
    m1 := SubStr(startDT, 5, 2) + 0
    d1 := SubStr(startDT, 7, 2) + 0

    y2 := SubStr(endDT, 1, 4) + 0
    m2 := SubStr(endDT, 5, 2) + 0
    d2 := SubStr(endDT, 7, 2) + 0

    if (d2 < d1)
    {
        m2--
        if (m2 < 1)
        {
            m2 := 12
            y2--
        }

        if (m2 = 2)
        {
            leap := (Mod(y2, 4) = 0 && (Mod(y2, 100) != 0 || Mod(y2, 400) = 0))
            d2 += leap ? 29 : 28
        }
        else if (m2 = 4 || m2 = 6 || m2 = 9 || m2 = 11)
            d2 += 30
        else
            d2 += 31
    }

    diffD := d2 - d1

    if (m2 < m1)
    {
        m2 += 12
        y2--
    }

    diffM := m2 - m1
    diffY := y2 - y1

    return diffY . "³â " . diffM . "¿ù " . diffD . "ÀÏ"
}

SSOK_CareerYMDTo360Days(ymd)
{
    if !RegExMatch(ymd, "([0-9]+)³â\s*([0-9]+)¿ù\s*([0-9]+)ÀÏ", m)
        return 0
    return (m1 + 0) * 360 + (m2 + 0) * 30 + (m3 + 0)
}

SSOK_Career360DaysToYMD(days)
{
    days := Floor(days)
    if (days < 0)
        days := 0

    y := Floor(days / 360)
    rem := Mod(days, 360)
    mo := Floor(rem / 30)
    d := Mod(rem, 30)

    return y . "³â " . mo . "¿ù " . d . "ÀÏ"
}

SSOK_CareerCopy:
    if (SSOK_CareerResultText != "")
    {
        Clipboard := SSOK_CareerResultText
        ToolTip, °æ·Â °á°ú¸¦ Å¬¸³º¸µå¿¡ º¹»çÇß½À´Ï´Ù.
        SetTimer, SSOK_CalcRemoveToolTip, -900
    }
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
            if (!SSOK_Tool_IsKoreaNonWorkday(d8))
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
        if (!SSOK_Tool_IsKoreaNonWorkday(d8))
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
        if (SSOK_Tool_IsKoreaNonWorkday(d8))
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

SSOK_Tool_SidebarDeleteProxy:
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_Delete"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return
SSOK_Sidebar_WorkTools:
    Gosub, SSOK_ShowWorkToolsGui
return

SSOK_ShowWorkToolsGui:
    ; ¾÷¹«¿ë µµ±¸ °¡·ÎÆøÀº ÇöÀç ¸ÞÀÎ ¸Þ´º(»çÀÌµå¹Ù)º¸´Ù 20px ³Ð°Ô »ç¿ë
    SSOK_WorkToolsW := SSOK_SidebarW + 20
    if (SSOK_WorkToolsW = "" || SSOK_WorkToolsW < 132)
        SSOK_WorkToolsW := 132

    SSOK_WorkToolsButtonW := SSOK_WorkToolsW - 16
    SSOK_WorkToolsSettingsW := 30
    SSOK_WorkToolsGap := 4
    SSOK_WorkToolsCalendarW := SSOK_WorkToolsButtonW - SSOK_WorkToolsSettingsW - SSOK_WorkToolsGap
    SSOK_WorkToolsSettingsX := 8 + SSOK_WorkToolsCalendarW + SSOK_WorkToolsGap

    ; ¼ýÀÚ ±â´É 2°³´Â °°Àº ÁÙ¿¡ ¹Ý¾¿ ¹èÄ¡
    SSOK_WorkToolsNumGap := 4
    SSOK_WorkToolsNumW := Floor((SSOK_WorkToolsButtonW - SSOK_WorkToolsNumGap) / 2)
    SSOK_WorkToolsNumX2 := 8 + SSOK_WorkToolsNumW + SSOK_WorkToolsNumGap

    Gui, SSOKWorkTools:Destroy
    Gui, SSOKWorkTools:+AlwaysOnTop +ToolWindow +HwndSSOK_WorkToolsHwnd
    Gui, SSOKWorkTools:Color, F7FBFF
    ; ±âÁ¸ s5.6¿¡¼­ 20% È®´ë = s6.72
    Gui, SSOKWorkTools:Font, s6.72 bold, Malgun Gothic
    Gui, SSOKWorkTools:Add, Button, x8 y8 w%SSOK_WorkToolsCalendarW% h25 vSSOK_WorkTools_AdminCalendar gSSOK_WorkTools_AdminCalendarOpen, ÇàÁ¤¾÷¹«´Þ·Â
    Gui, SSOKWorkTools:Add, Button, x%SSOK_WorkToolsSettingsX% y8 w%SSOK_WorkToolsSettingsW% h25 gSSOK_WorkTools_AdminCalendarSettings, ¼³Á¤
    Gui, SSOKWorkTools:Add, Button, x8 y39  w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_BudgetDashboard, ¿¹»ê DashBoard
    Gui, SSOKWorkTools:Add, Button, x8 y70  w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_Travel, ¿©ºñÁ¤»ê¼­
    Gui, SSOKWorkTools:Add, Button, x8 y101 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_Calc, °è»ê±â
    Gui, SSOKWorkTools:Add, Button, x8 y132 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_AutoClick, ¸¶¿ì½º ¸ÅÅ©·Î
    Gui, SSOKWorkTools:Add, Button, x8 y163 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_Timer, ¾÷¹«¿ë Å¸ÀÌ¸Ó
    Gui, SSOKWorkTools:Add, Button, x8 y194 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_CompanyInfo, ±¹¼¼Ã»¡¤Á¶´ÞÃ» ¾÷Ã¼Á¶È¸
    Gui, SSOKWorkTools:Add, Button, x8 y225 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_Privacy, °³ÀÎÁ¤º¸ ¼û±â±â
    Gui, SSOKWorkTools:Add, Button, x8 y256 w%SSOK_WorkToolsNumW% h25 gSSOK_WorkTools_CommaToggle, ¼ýÀÚ-Ãµ¿ø
    Gui, SSOKWorkTools:Add, Button, x%SSOK_WorkToolsNumX2% y256 w%SSOK_WorkToolsNumW% h25 gSSOK_WorkTools_MoneyToggle, ¼ýÀÚ-±Ý¾×
    Gui, SSOKWorkTools:Add, Button, x8 y287 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_CardCompare, ¹ýÀÎÄ«µå³»¿ªºñ±³
    Gui, SSOKWorkTools:Add, Button, x8 y318 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_WorkPublic, ¾÷¹«ÃßÁøºñ°ø°³
    Gui, SSOKWorkTools:Add, Button, x8 y349 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_SchoolSearch, ÇÐ±³°Ë»ö (Àü±¹)
    Gui, SSOKWorkTools:Add, Button, x8 y380 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_SchoolSearchNational, ÇÐ±³°Ë»ö (¼¼Á¾)
    Gui, SSOKWorkTools:Add, Button, x8 y411 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_LocalFinanceInfo, Áö¹æ±³À°ÀçÁ¤Á¤º¸
    Gui, SSOKWorkTools:Add, Button, x8 y442 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_ContractG2B, °è¾àÇöÈ² (³ª¶óÀåÅÍ)
    Gui, SSOKWorkTools:Add, Button, x8 y473 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_ContractLofin365, °è¾àÇöÈ² (Áö¹æÀçÁ¤365)
    Gui, SSOKWorkTools:Add, Button, x8 y504 w%SSOK_WorkToolsButtonW% h25 gSSOK_WorkTools_ContractSejong, °è¾àÇöÈ² (¼¼Á¾)
    Gui, SSOKWorkTools:Add, Button, x8 y535 w%SSOK_WorkToolsButtonW% h25 vSSOK_WorkTools_Exit gSSOK_Tool_SidebarDeleteProxy, Á¾·á
    Gui, SSOKWorkTools:Add, Button, x8 y566 w%SSOK_WorkToolsButtonW% h25 vSSOK_WorkTools_BetaToggle gSSOK_WorkTools_BetaToggle, Å×½ºÆ®¹öÀü Beta
    Gui, SSOKWorkTools:Add, Button, x8 y628 w%SSOK_WorkToolsButtonW% h25 vSSOK_WorkTools_Win1 gSSOK_Advanced_Win1 Hidden, °£Æí ¿øÀÎÇàÀ§(win+2)
    Gui, SSOKWorkTools:Add, Button, x8 y659 w%SSOK_WorkToolsButtonW% h25 vSSOK_WorkTools_Win2 gSSOK_Advanced_Win2 Hidden, °£Æí ¿øÀÎÇàÀ§(win+4)
    Gui, SSOKWorkTools:Add, Button, x8 y690 w%SSOK_WorkToolsButtonW% h25 vSSOK_WorkTools_ExpenseDraft gSSOK_Advanced_ExpenseDraft Hidden, °£Æí ÁöÃâÇ°ÀÇ(win+1)

    SSOK_WorkToolsH := 598
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

SSOK_WorkTools_AdminCalendarOpen:
    ; ¾÷¹«¿ë µµ±¸¿¡¼­´Â ON/OFF Åä±Û ¾øÀÌ Áï½Ã ¿À´ÃÀÇ ÇàÁ¤¾÷¹«´Þ·Â ÆË¾÷À» ¿±´Ï´Ù.
    SSOK_AdminCalendar_ShowTodayPopup(true)
return

SSOK_WorkTools_AdminCalendarSettings:
    SSOK_AdminCalendar_ShowSettings()
return

SSOK_WorkTools_BudgetDashboard:
    ; ¿¹»ê DashboardÀÇ ½ÇÁ¦ ±â´ÉÀº ssok_tool_expense.ahk¿¡ µÓ´Ï´Ù.
    SSOK_ToolDynamicLabel := "SSOK_Expense_Tools_BudgetDashboard"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_WorkTools_BetaToggle:
    ; ÇöÀç ¾÷¹«¿ë µµ±¸ Ã¢ÀÇ À§Ä¡/Å©±â¸¦ ±â¾ïÇÑ µÚ ¼û±â°í,
    ; ±× ÀÚ¸®¿¡ Beta Ã¢À» Ç¥½ÃÇÕ´Ï´Ù.
    global SSOK_WorkToolsHwnd
    global SSOK_BetaReplaceX, SSOK_BetaReplaceY, SSOK_BetaReplaceW, SSOK_BetaReplaceH

    SSOK_BetaReplaceX := ""
    SSOK_BetaReplaceY := ""
    SSOK_BetaReplaceW := ""
    SSOK_BetaReplaceH := ""

    if (SSOK_WorkToolsHwnd != "")
    {
        WinGetPos, SSOK_BetaReplaceX, SSOK_BetaReplaceY, SSOK_BetaReplaceW, SSOK_BetaReplaceH, ahk_id %SSOK_WorkToolsHwnd%
        Gui, SSOKWorkTools:Hide
    }

    SSOK_ToolDynamicLabel := "SSOK_Expense_Tools_Open"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_WorkTools_Travel:
    SSOK_ToolDynamicLabel := "SSOK_TrayOpenTravel"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_WorkTools_Calc:
    Gosub, SSOK_Sidebar_Calc
return

SSOK_WorkTools_AutoClick:
    Gosub, SSOK_Advanced_AutoClick
return

SSOK_WorkTools_Timer:
    Gosub, SSOK_WorkTimer_Show
return

SSOK_WorkTools_CompanyInfo:
    SSOK_CompanyInfo_Show()
return

SSOK_WorkTools_Privacy:
    Gosub, SSOK_Advanced_Privacy
return

SSOK_WorkTools_CommaToggle:
    Gosub, SSOK_Advanced_CommaToggle
return

SSOK_WorkTools_MoneyToggle:
    Gosub, SSOK_Advanced_MoneyToggle
return

SSOK_WorkTools_CardCompare:
    SSOK_ToolDynamicLabel := "SSOK_Expense_Tools_CardCompare"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_WorkTools_WorkPublic:
    SSOK_ToolDynamicLabel := "SSOK_Expense_Tools_WorkPublic"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_WorkTools_SchoolSearch:
    Gosub, SSOK_Advanced_SchoolSearch
return

SSOK_WorkTools_SchoolSearchNational:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    Gosub, SSOK_SchoolSearch_ShowNational
return

SSOK_WorkTools_LocalFinanceInfo:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    SSOK_OpenLocalFinanceInfoForSejongElementary()
return

SSOK_WorkTools_ContractG2B:
    ; ¾÷¹«¿ë µµ±¸ÀÇ ÇöÀç À§Ä¡/Å©±â¸¦ ÀúÀåÇÏ°í °°Àº ÀÚ¸®¿¡ ±³À°Ã» ¼±ÅÃÃ¢ Ç¥½Ã
    SSOK_BetaReplaceX := ""
    SSOK_BetaReplaceY := ""
    SSOK_BetaReplaceW := ""
    SSOK_BetaReplaceH := ""

    if (SSOK_WorkToolsHwnd != "" && WinExist("ahk_id " . SSOK_WorkToolsHwnd))
    {
        WinGetPos, SSOK_BetaReplaceX, SSOK_BetaReplaceY, SSOK_BetaReplaceW, SSOK_BetaReplaceH, ahk_id %SSOK_WorkToolsHwnd%
        Gui, SSOKWorkTools:Hide
    }

    if IsFunc("SSOK_Expense_G2B_Show")
    {
        SSOK_G2B_ShowFunc := Func("SSOK_Expense_G2B_Show")
        SSOK_G2B_ShowFunc.Call()
    }
    else
        MsgBox, 48, SSOK ¾È³», ³ª¶óÀåÅÍ ±³À°Ã» ¼±ÅÃ ±â´ÉÀ» ºÒ·¯¿ÀÁö ¸øÇß½À´Ï´Ù.
return

SSOK_WorkTools_ContractLofin365:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    SSOK_Tool_OpenUrlPreferred("https://www.lofin365.go.kr/portal/LF3120302.do")
return

SSOK_WorkTools_ContractSejong:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    SSOK_Tool_OpenUrlPreferred("https://www.sje.go.kr/sje/ir/selectCntrInfoList.do?mi=52495")
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
    Gui, SSOKAdvanced:Add, Button, x8 y8 w166 h25 gSSOK_Advanced_Win1, °£Æí ¿øÀÎÇàÀ§(win+2)
    Gui, SSOKAdvanced:Add, Button, x8 y39 w166 h25 gSSOK_Advanced_Win2, °£Æí ¿øÀÎÇàÀ§(win+4)
    Gui, SSOKAdvanced:Add, Button, x8 y70 w166 h25 gSSOK_Advanced_ExpenseDraft, °£Æí ÁöÃâÇ°ÀÇ(win+1)
    SSOK_AdvancedW := 182
    SSOK_AdvancedH := 107
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
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    Gosub, SSOK_DoPrivacyMask
return

SSOK_Advanced_Win1:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    SSOK_ToolDynamicLabel := "SSOK_Expense_DoWin1_KEdufine_TabSeq_10_1_4"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_Advanced_Win2:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    SSOK_ToolDynamicLabel := "SSOK_Expense_DoWin4_KEdufine_TabSeq"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_Advanced_ExpenseDraft:
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    ; ´Üµ¶ ½ÇÇà¿¡¼­´Â expense ¸ðµâÀÌ ¾øÀ¸¹Ç·Î Á¸ÀçÇÒ ¶§¸¸ È£Ãâ
    if IsFunc("SSOK_Expense_Run")
        Func("SSOK_Expense_Run").Call()
return

SSOK_Advanced_CommaToggle:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    SSOK_ToolDynamicLabel := "SSOK_DoCommaToggle"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_Advanced_MoneyToggle:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    ; Win+F2¿Í µ¿ÀÏÇÑ ±âÁ¸ ±Ý¾× ÇÑ±ÛÈ­/Åä±Û ·ÎÁ÷ »ç¿ë
    SSOK_ToolDynamicLabel := "SSOK_DoF2"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
return

SSOK_Advanced_AutoClick:
    Gosub, SSOK_Advanced_SaveMovedPos
    Gosub, SSOK_AutoClick_Show
return

SSOK_WorkTimer_Show:
    if (SSOK_WorkTimerHwnd && WinExist("ahk_id " . SSOK_WorkTimerHwnd))
    {
        Gui, SSOKWorkTimer:Show
        WinActivate, ahk_id %SSOK_WorkTimerHwnd%
        return
    }

    SSOK_WorkTimerRunning := 0
    SSOK_WorkTimerPaused := 0
    SSOK_WorkTimerInitialSec := 180
    SSOK_WorkTimerRemainingSec := 180
    SSOK_WorkTimerStartTick := 0
    SSOK_WorkTimerDurationMs := 0
    SSOK_WorkTimerAlarmActive := 0

    Gui, SSOKWorkTimer:Destroy
    Gui, SSOKWorkTimer:+AlwaysOnTop +ToolWindow +HwndSSOK_WorkTimerHwnd
    Gui, SSOKWorkTimer:Color, F7FBFF

    Gui, SSOKWorkTimer:Font, s11 bold, Malgun Gothic
    Gui, SSOKWorkTimer:Add, Text, x0 y10 w540 h26 Center c005BAC, ±³À°ÇàÁ¤ ¾÷¹«¿ë Å¸ÀÌ¸Ó

    Gui, SSOKWorkTimer:Font, s9 norm, Malgun Gothic
    Gui, SSOKWorkTimer:Add, GroupBox, x12 y42 w516 h58, Presets
    Gui, SSOKWorkTimer:Add, Radio, x24  y64 w58 h22 Group vSSOK_WorkTimerPreset gSSOK_WorkTimer_Preset Checked, 3ºÐ
    Gui, SSOKWorkTimer:Add, Radio, x84  y64 w58 h22 gSSOK_WorkTimer_Preset, 5ºÐ
    Gui, SSOKWorkTimer:Add, Radio, x144 y64 w58 h22 gSSOK_WorkTimer_Preset, 10ºÐ
    Gui, SSOKWorkTimer:Add, Radio, x204 y64 w58 h22 gSSOK_WorkTimer_Preset, 15ºÐ
    Gui, SSOKWorkTimer:Add, Radio, x264 y64 w58 h22 gSSOK_WorkTimer_Preset, 30ºÐ
    Gui, SSOKWorkTimer:Add, Radio, x324 y64 w58 h22 gSSOK_WorkTimer_Preset, 45ºÐ
    Gui, SSOKWorkTimer:Add, Radio, x384 y64 w58 h22 gSSOK_WorkTimer_Preset, 50ºÐ
    Gui, SSOKWorkTimer:Add, Radio, x444 y64 w58 h22 gSSOK_WorkTimer_Preset, 60ºÐ

    Gui, SSOKWorkTimer:Add, GroupBox, x12 y108 w350 h84, Á÷Á¢ ¼³Á¤
    Gui, SSOKWorkTimer:Add, Text, x34 y128 w72 h20 Center, ½Ã
    Gui, SSOKWorkTimer:Add, Text, x142 y128 w72 h20 Center, ºÐ
    Gui, SSOKWorkTimer:Add, Text, x250 y128 w72 h20 Center, ÃÊ
    Gui, SSOKWorkTimer:Add, Edit, x34 y150 w72 h24 Center Number Limit2 vSSOK_WorkTimerHours gSSOK_WorkTimer_EditChanged, 0
    Gui, SSOKWorkTimer:Add, UpDown, Range0-99, 0
    Gui, SSOKWorkTimer:Add, Edit, x142 y150 w72 h24 Center Number Limit2 vSSOK_WorkTimerMinutes gSSOK_WorkTimer_EditChanged, 3
    Gui, SSOKWorkTimer:Add, UpDown, Range0-59, 3
    Gui, SSOKWorkTimer:Add, Edit, x250 y150 w72 h24 Center Number Limit2 vSSOK_WorkTimerSeconds gSSOK_WorkTimer_EditChanged, 0
    Gui, SSOKWorkTimer:Add, UpDown, Range0-59, 0

    Gui, SSOKWorkTimer:Add, Button, x382 y120 w126 h30 vSSOK_WorkTimerStartStop gSSOK_WorkTimer_StartStop, ½ÃÀÛ
    Gui, SSOKWorkTimer:Add, Button, x382 y158 w126 h30 gSSOK_WorkTimer_Reset, ÃÊ±âÈ­

    Gui, SSOKWorkTimer:Font, s30 bold, Malgun Gothic
    Gui, SSOKWorkTimer:Add, Text, x20 y202 w500 h52 Center vSSOK_WorkTimerDisplay, 00:03:00
    Gui, SSOKWorkTimer:Font, s9 norm, Malgun Gothic
    Gui, SSOKWorkTimer:Add, Progress, x20 y258 w500 h24 Range0-100 c00B050 BackgroundE6E6E6 vSSOK_WorkTimerProgress, 100

    Gui, SSOKWorkTimer:Add, CheckBox, x302 y292 w105 h22 vSSOK_WorkTimerAutoRestart, ÀÚµ¿ Àç½ÃÀÛ
    Gui, SSOKWorkTimer:Add, CheckBox, x416 y292 w104 h22 vSSOK_WorkTimerRingForever, ¾Ë¸² °è¼Ó
    Gui, SSOKWorkTimer:Add, Text, x20 y294 w260 h20 c666666 vSSOK_WorkTimerStatus, ´ë±â Áß

    SSOK_Tool_GetSidebarAttachedGuiPos(540, 324, SSOK_WorkTimerWinX, SSOK_WorkTimerWinY)
    Gui, SSOKWorkTimer:Show, x%SSOK_WorkTimerWinX% y%SSOK_WorkTimerWinY% w540 h324, ±³À°ÇàÁ¤ ¾÷¹«¿ë Å¸ÀÌ¸Ó
return

SSOK_WorkTimer_Preset:
    if (SSOK_WorkTimerRunning)
    {
        SetTimer, SSOK_WorkTimer_Tick, Off
        SSOK_WorkTimerRunning := 0
    }
    Gosub, SSOK_WorkTimer_StopAlarm
    SSOK_WorkTimerPaused := 0
    Gui, SSOKWorkTimer:Submit, NoHide

    if (SSOK_WorkTimerPreset = 1)
        SSOK_WorkTimerPresetMin := 3
    else if (SSOK_WorkTimerPreset = 2)
        SSOK_WorkTimerPresetMin := 5
    else if (SSOK_WorkTimerPreset = 3)
        SSOK_WorkTimerPresetMin := 10
    else if (SSOK_WorkTimerPreset = 4)
        SSOK_WorkTimerPresetMin := 15
    else if (SSOK_WorkTimerPreset = 5)
        SSOK_WorkTimerPresetMin := 30
    else if (SSOK_WorkTimerPreset = 6)
        SSOK_WorkTimerPresetMin := 45
    else if (SSOK_WorkTimerPreset = 7)
        SSOK_WorkTimerPresetMin := 50
    else
        SSOK_WorkTimerPresetMin := 60

    SSOK_WorkTimerPresetH := Floor(SSOK_WorkTimerPresetMin / 60)
    SSOK_WorkTimerPresetM := Mod(SSOK_WorkTimerPresetMin, 60)
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerHours, %SSOK_WorkTimerPresetH%
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerMinutes, %SSOK_WorkTimerPresetM%
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerSeconds, 0
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ½ÃÀÛ
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ´ë±â Áß
    SSOK_WorkTimerInitialSec := SSOK_WorkTimerPresetMin * 60
    SSOK_WorkTimerRemainingSec := SSOK_WorkTimerInitialSec
    Gosub, SSOK_WorkTimer_UpdateDisplay
return

SSOK_WorkTimer_EditChanged:
    if (SSOK_WorkTimerRunning)
    {
        SetTimer, SSOK_WorkTimer_Tick, Off
        SSOK_WorkTimerRunning := 0
        Gosub, SSOK_WorkTimer_StopAlarm
        GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ½ÃÀÛ
    }

    SSOK_WorkTimerPaused := 0
    Gui, SSOKWorkTimer:Submit, NoHide
    SSOK_WorkTimerH := SSOK_WorkTimerHours + 0
    SSOK_WorkTimerM := SSOK_WorkTimerMinutes + 0
    SSOK_WorkTimerS := SSOK_WorkTimerSeconds + 0
    if (SSOK_WorkTimerH < 0)
        SSOK_WorkTimerH := 0
    if (SSOK_WorkTimerM < 0)
        SSOK_WorkTimerM := 0
    if (SSOK_WorkTimerM > 59)
        SSOK_WorkTimerM := 59
    if (SSOK_WorkTimerS < 0)
        SSOK_WorkTimerS := 0
    if (SSOK_WorkTimerS > 59)
        SSOK_WorkTimerS := 59

    SSOK_WorkTimerInitialSec := (SSOK_WorkTimerH * 3600) + (SSOK_WorkTimerM * 60) + SSOK_WorkTimerS
    SSOK_WorkTimerRemainingSec := SSOK_WorkTimerInitialSec
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ´ë±â Áß
    Gosub, SSOK_WorkTimer_UpdateDisplay
return

SSOK_WorkTimer_StartStop:
    if (SSOK_WorkTimerAlarmActive && !SSOK_WorkTimerRunning)
    {
        Gosub, SSOK_WorkTimer_StopAlarm
        GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ½ÃÀÛ
        GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ¾Ë¸² ÁßÁö
        return
    }

    if (SSOK_WorkTimerRunning)
    {
        Gosub, SSOK_WorkTimer_Pause
        return
    }

    Gosub, SSOK_WorkTimer_StopAlarm

    if (!SSOK_WorkTimerPaused)
    {
        Gui, SSOKWorkTimer:Submit, NoHide
        SSOK_WorkTimerH := SSOK_WorkTimerHours + 0
        SSOK_WorkTimerM := SSOK_WorkTimerMinutes + 0
        SSOK_WorkTimerS := SSOK_WorkTimerSeconds + 0

        if (SSOK_WorkTimerM > 59 || SSOK_WorkTimerS > 59)
        {
            MsgBox, 48, ±³À°ÇàÁ¤ ¾÷¹«¿ë Å¸ÀÌ¸Ó, ºÐ°ú ÃÊ´Â 0~59 ¹üÀ§·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
            return
        }

        SSOK_WorkTimerInitialSec := (SSOK_WorkTimerH * 3600) + (SSOK_WorkTimerM * 60) + SSOK_WorkTimerS
        SSOK_WorkTimerRemainingSec := SSOK_WorkTimerInitialSec
    }

    if (SSOK_WorkTimerRemainingSec <= 0)
    {
        MsgBox, 48, ±³À°ÇàÁ¤ ¾÷¹«¿ë Å¸ÀÌ¸Ó, ½Ã°£À» 1ÃÊ ÀÌ»ó ¼³Á¤ÇØ ÁÖ¼¼¿ä.
        return
    }

    if (SSOK_WorkTimerInitialSec <= 0)
        SSOK_WorkTimerInitialSec := SSOK_WorkTimerRemainingSec

    SSOK_WorkTimerDurationMs := SSOK_WorkTimerRemainingSec * 1000
    SSOK_WorkTimerStartTick := A_TickCount
    SSOK_WorkTimerRunning := 1
    SSOK_WorkTimerPaused := 0
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ÁßÁö
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ½ÇÇà Áß
    SetTimer, SSOK_WorkTimer_Tick, 200
    Gosub, SSOK_WorkTimer_UpdateDisplay
return

SSOK_WorkTimer_Pause:
    if (!SSOK_WorkTimerRunning)
        return

    SSOK_WorkTimerElapsedMs := A_TickCount - SSOK_WorkTimerStartTick
    if (SSOK_WorkTimerElapsedMs < 0)
        SSOK_WorkTimerElapsedMs += 4294967296
    SSOK_WorkTimerRemainMs := SSOK_WorkTimerDurationMs - SSOK_WorkTimerElapsedMs
    if (SSOK_WorkTimerRemainMs < 0)
        SSOK_WorkTimerRemainMs := 0

    SSOK_WorkTimerRemainingSec := Ceil(SSOK_WorkTimerRemainMs / 1000)
    SSOK_WorkTimerRunning := 0
    SSOK_WorkTimerPaused := 1
    SetTimer, SSOK_WorkTimer_Tick, Off
    Gosub, SSOK_WorkTimer_StopAlarm
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ½ÃÀÛ
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ÀÏ½Ã Á¤Áö
    Gosub, SSOK_WorkTimer_UpdateDisplay
return

SSOK_WorkTimer_Reset:
    SetTimer, SSOK_WorkTimer_Tick, Off
    SSOK_WorkTimerRunning := 0
    SSOK_WorkTimerPaused := 0
    Gosub, SSOK_WorkTimer_StopAlarm
    Gui, SSOKWorkTimer:Submit, NoHide

    SSOK_WorkTimerH := SSOK_WorkTimerHours + 0
    SSOK_WorkTimerM := SSOK_WorkTimerMinutes + 0
    SSOK_WorkTimerS := SSOK_WorkTimerSeconds + 0
    if (SSOK_WorkTimerM > 59)
        SSOK_WorkTimerM := 59
    if (SSOK_WorkTimerS > 59)
        SSOK_WorkTimerS := 59
    SSOK_WorkTimerInitialSec := (SSOK_WorkTimerH * 3600) + (SSOK_WorkTimerM * 60) + SSOK_WorkTimerS
    SSOK_WorkTimerRemainingSec := SSOK_WorkTimerInitialSec
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ½ÃÀÛ
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ´ë±â Áß
    Gosub, SSOK_WorkTimer_UpdateDisplay
return

SSOK_WorkTimer_Tick:
    if (!SSOK_WorkTimerRunning)
        return

    SSOK_WorkTimerElapsedMs := A_TickCount - SSOK_WorkTimerStartTick
    if (SSOK_WorkTimerElapsedMs < 0)
        SSOK_WorkTimerElapsedMs += 4294967296
    SSOK_WorkTimerRemainMs := SSOK_WorkTimerDurationMs - SSOK_WorkTimerElapsedMs

    if (SSOK_WorkTimerRemainMs <= 0)
    {
        SSOK_WorkTimerRemainingSec := 0
        Gosub, SSOK_WorkTimer_UpdateDisplay
        Gui, SSOKWorkTimer:Submit, NoHide

        if (SSOK_WorkTimerRingForever)
        {
            SSOK_WorkTimerAlarmActive := 1
            SetTimer, SSOK_WorkTimer_Ring, 850
            Gosub, SSOK_WorkTimer_Ring
        }
        else
        {
            SoundBeep, 1200, 180
            SoundBeep, 1600, 180
            SoundBeep, 1200, 180
        }

        if (SSOK_WorkTimerAutoRestart && SSOK_WorkTimerInitialSec > 0)
        {
            SSOK_WorkTimerRemainingSec := SSOK_WorkTimerInitialSec
            SSOK_WorkTimerDurationMs := SSOK_WorkTimerInitialSec * 1000
            SSOK_WorkTimerStartTick := A_TickCount
            SSOK_WorkTimerRunning := 1
            SSOK_WorkTimerPaused := 0
            GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ÁßÁö
            GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ÀÚµ¿ Àç½ÃÀÛ
            Gosub, SSOK_WorkTimer_UpdateDisplay
            return
        }

        SSOK_WorkTimerRunning := 0
        SSOK_WorkTimerPaused := 0
        SetTimer, SSOK_WorkTimer_Tick, Off
        if (SSOK_WorkTimerAlarmActive)
        {
            GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ÁßÁö
            GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ½Ã°£ Á¾·á - ¾Ë¸² Áß
        }
        else
        {
            GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStartStop, ½ÃÀÛ
            GuiControl, SSOKWorkTimer:, SSOK_WorkTimerStatus, ½Ã°£ Á¾·á
        }
        return
    }

    SSOK_WorkTimerRemainingSec := Ceil(SSOK_WorkTimerRemainMs / 1000)
    Gosub, SSOK_WorkTimer_UpdateDisplay
return

SSOK_WorkTimer_Ring:
    if (!SSOK_WorkTimerAlarmActive)
    {
        SetTimer, SSOK_WorkTimer_Ring, Off
        return
    }
    SoundBeep, 1450, 180
return

SSOK_WorkTimer_StopAlarm:
    SSOK_WorkTimerAlarmActive := 0
    SetTimer, SSOK_WorkTimer_Ring, Off
return

SSOK_WorkTimer_UpdateDisplay:
    SSOK_WorkTimerDisplayText := SSOK_WorkTimer_FormatTime(SSOK_WorkTimerRemainingSec)
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerDisplay, %SSOK_WorkTimerDisplayText%

    if (SSOK_WorkTimerInitialSec > 0)
        SSOK_WorkTimerPercent := Floor((SSOK_WorkTimerRemainingSec * 100) / SSOK_WorkTimerInitialSec)
    else
        SSOK_WorkTimerPercent := 0

    if (SSOK_WorkTimerPercent < 0)
        SSOK_WorkTimerPercent := 0
    if (SSOK_WorkTimerPercent > 100)
        SSOK_WorkTimerPercent := 100
    GuiControl, SSOKWorkTimer:, SSOK_WorkTimerProgress, %SSOK_WorkTimerPercent%
return

SSOKWorkTimerGuiClose:
SSOKWorkTimerGuiEscape:
    Gui, SSOKWorkTimer:Hide
return

SSOK_WorkTimer_FormatTime(totalSec)
{
    totalSec := Floor(totalSec + 0)
    if (totalSec < 0)
        totalSec := 0
    hours := Floor(totalSec / 3600)
    minutes := Floor(Mod(totalSec, 3600) / 60)
    seconds := Mod(totalSec, 60)
    return SSOK_WorkTimer_Pad2(hours) . ":" . SSOK_WorkTimer_Pad2(minutes) . ":" . SSOK_WorkTimer_Pad2(seconds)
}

SSOK_WorkTimer_Pad2(value)
{
    value := Floor(value + 0)
    return (value < 10 ? "0" . value : value)
}

SSOK_Advanced_SchoolSearch:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    SSOK_OpenSchoolInfo2ForSejongElementary()
return

SSOK_SchoolSearch_ShowNational:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    Gosub, SSOK_SchoolSearch_Show
return

SSOK_Advanced_EduOfficeSearch:
    Gosub, SSOK_Advanced_SaveMovedPos
    SSOK_ToolDynamicLabel := "SSOK_Sidebar_PrepareAction"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    Gosub, SSOK_EduOfficeSearch_Show
return

SSOK_AutoClick_Show:
    if (SSOK_AutoClickHwnd && WinExist("ahk_id " . SSOK_AutoClickHwnd))
    {
        Gui, SSOKAutoClick:Show
        return
    }
    Gosub, SSOK_AutoClick_Stop
    Gosub, SSOK_AutoClick_StopSchedule
    SSOK_AutoClickIni := SSOK_IniFile
    IniRead, SSOK_AutoClickSec, %SSOK_AutoClickIni%, AutoClick, Sec, 0
    SSOK_AutoClickDefaultEnabled := (SSOK_AutoClickSec > 0 ? 1 : 0)
    SSOK_AutoClickDefaultValue := (SSOK_AutoClickSec > 0 ? SSOK_AutoClickSec : 5)
    IniRead, SSOK_AutoClickEnabled, %SSOK_AutoClickIni%, AutoClick, IntervalEnabled, %SSOK_AutoClickDefaultEnabled%
    IniRead, SSOK_AutoClickIntervalValue, %SSOK_AutoClickIni%, AutoClick, IntervalValue, %SSOK_AutoClickDefaultValue%
    IniRead, SSOK_AutoClickIntervalUnit, %SSOK_AutoClickIni%, AutoClick, IntervalUnit, 1
    SSOK_AutoClickEnabled := (SSOK_AutoClickEnabled = 1 ? 1 : 0)
    if (SSOK_AutoClickIntervalUnit != 2 && SSOK_AutoClickIntervalUnit != 3)
        SSOK_AutoClickIntervalUnit := 1
    SSOK_AutoClickToday := SubStr(A_Now, 1, 8)
    IniRead, SSOK_AutoClickModeSaved, %SSOK_AutoClickIni%, AutoClick, Mode, 1
    IniRead, SSOK_AutoClickTimeModeSaved, %SSOK_AutoClickIni%, AutoClick, TimeMode, 1
    IniRead, SSOK_AutoClickIX, %SSOK_AutoClickIni%, AutoClick, IX, __SSOK_EMPTY__
    IniRead, SSOK_AutoClickIY, %SSOK_AutoClickIni%, AutoClick, IY, __SSOK_EMPTY__
    IniRead, SSOK_AutoClickCoordOneVer, %SSOK_AutoClickIni%, AutoClick, CoordOneVer, 0
    if (SSOK_AutoClickIX = "__SSOK_EMPTY__")
        SSOK_AutoClickIX := ""
    if (SSOK_AutoClickIY = "__SSOK_EMPTY__")
        SSOK_AutoClickIY := ""
    Loop, 5
    {
        idx := A_Index
        IniRead, SSOK_AutoClickUse%idx%, %SSOK_AutoClickIni%, AutoClick, Use%idx%, 0
        IniRead, SSOK_AutoClickX%idx%, %SSOK_AutoClickIni%, AutoClick, X%idx%, __SSOK_EMPTY__
        IniRead, SSOK_AutoClickY%idx%, %SSOK_AutoClickIni%, AutoClick, Y%idx%, __SSOK_EMPTY__
        IniRead, SSOK_AutoClickH%idx%, %SSOK_AutoClickIni%, AutoClick, H%idx%, 00
        IniRead, SSOK_AutoClickM%idx%, %SSOK_AutoClickIni%, AutoClick, M%idx%, 00
        IniRead, SSOK_AutoClickS%idx%, %SSOK_AutoClickIni%, AutoClick, S%idx%, 00
        IniRead, SSOK_AutoClickDate%idx%, %SSOK_AutoClickIni%, AutoClick, Date%idx%, %SSOK_AutoClickToday%
        IniRead, SSOK_AutoClickAmPm%idx%, %SSOK_AutoClickIni%, AutoClick, AmPm%idx%, __SSOK_EMPTY__
        if (SSOK_AutoClickAmPm%idx% = "__SSOK_EMPTY__")
        {
            ; Migrate the previous 24-hour schedule without changing its time of day.
            SSOK_AutoClickAmPm%idx% := (SSOK_AutoClickH%idx% >= 12 ? 2 : 1)
            SSOK_AutoClickH%idx% := Mod(SSOK_AutoClickH%idx%, 12)
            if (SSOK_AutoClickH%idx% = 0)
                SSOK_AutoClickH%idx% := 12
        }
        if (SSOK_AutoClickAmPm%idx% != 2)
            SSOK_AutoClickAmPm%idx% := 1
        if (!SSOK_AutoClickValidDate(SSOK_AutoClickDate%idx%))
            SSOK_AutoClickDate%idx% := SSOK_AutoClickToday
        IniRead, SSOK_AutoClickTextHex, %SSOK_AutoClickIni%, AutoClick, TextHex%idx%, __SSOK_EMPTY__
        SSOK_AutoClickText%idx% := SSOK_AutoClickDecodeText(SSOK_AutoClickTextHex)
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
    Gui, SSOKAutoClick:Add, Text, x0 y10 w980 h26 Center c005BAC, ÀÚµ¿ ¸¶¿ì½º Å¬¸¯
    Gui, SSOKAutoClick:Font, s9 norm, Malgun Gothic
    Gui, SSOKAutoClick:Add, GroupBox, x14 y42 w952 h186, 1. °£°Ý ¹Ýº¹ Å¬¸¯
    Gui, SSOKAutoClick:Add, CheckBox, x30 y70 w150 h24 vSSOK_AutoClickEnabled Checked%SSOK_AutoClickEnabled% gSSOK_AutoClick_ToggleInterval, ¹Ýº¹ Å¬¸¯ »ç¿ë
    Gui, SSOKAutoClick:Add, Text, x200 y70 w65 h24 +0x200, ¹Ýº¹ °£°Ý
    Gui, SSOKAutoClick:Add, Edit, x270 y70 w70 h24 Center vSSOK_AutoClickIntervalValue, %SSOK_AutoClickIntervalValue%
    Gui, SSOKAutoClick:Add, DropDownList, x350 y70 w68 vSSOK_AutoClickIntervalUnit AltSubmit Choose%SSOK_AutoClickIntervalUnit%, ÃÊ|ºÐ|½Ã°£
    Gui, SSOKAutoClick:Add, Text, x436 y70 w490 h24 +0x200 c555555, ¸¶´Ù Å¬¸¯ (¿¹: 5ÃÊ / 1ºÐ / 2½Ã°£, ÃÖ¼Ò 0.1ÃÊ)
    Gui, SSOKAutoClick:Add, Radio, x30 y104 w280 h22 Group vSSOK_AutoClickMode hwndSSOK_AutoClickModeCursorHwnd Checked%SSOK_AutoClickCursorChecked%, ÁÂÇ¥ ¹ÌÁöÁ¤ (ÇöÀç ¸¶¿ì½º À§Ä¡)
    Gui, SSOKAutoClick:Add, Radio, x30 y134 w90 h24 hwndSSOK_AutoClickModeCoordHwnd Checked%SSOK_AutoClickCoordChecked%, ÁÂÇ¥ ÁöÁ¤
    Gui, SSOKAutoClick:Add, Text, x130 y134 w16 h24 +0x200, X
    Gui, SSOKAutoClick:Add, Edit, x150 y134 w70 h24 Center vSSOK_AutoClickIX, %SSOK_AutoClickIX%
    Gui, SSOKAutoClick:Add, Text, x232 y134 w16 h24 +0x200, Y
    Gui, SSOKAutoClick:Add, Edit, x252 y134 w70 h24 Center vSSOK_AutoClickIY, %SSOK_AutoClickIY%
    Gui, SSOKAutoClick:Add, Button, x340 y133 w82 h26 vSSOK_AutoClickIntervalFind gSSOK_AutoClick_FindInterval, ÁÂÇ¥Ã£±â
    Gui, SSOKAutoClick:Add, Button, x30 y180 w90 h30 vSSOK_AutoClickIntervalStart gSSOK_AutoClick_Start, ½ÃÀÛ
    Gui, SSOKAutoClick:Add, Button, x132 y180 w90 h30 gSSOK_AutoClick_Stop, ÁßÁö
    Gui, SSOKAutoClick:Add, Text, x240 y184 w480 h24 vSSOK_AutoClickIntervalStatus c005BAC, ´ë±â Áß

    Gui, SSOKAutoClick:Add, GroupBox, x14 y242 w952 h354, 2. ³¯Â¥ / ½Ã°£ ¿¹¾à Å¬¸¯ + ÅØ½ºÆ® ÀÔ·Â
    Gui, SSOKAutoClick:Add, Radio, x30 y268 w280 h22 Group vSSOK_AutoClickTimeMode hwndSSOK_AutoClickTimeModeCursorHwnd Checked%SSOK_AutoClickTimeCursorChecked%, ÁÂÇ¥ ¹ÌÁöÁ¤ (ÇöÀç ¸¶¿ì½º À§Ä¡)
    Gui, SSOKAutoClick:Add, Radio, x330 y268 w280 h22 hwndSSOK_AutoClickTimeModeCoordHwnd Checked%SSOK_AutoClickTimeCoordChecked%, ÁÂÇ¥ ÁöÁ¤ (È¸Â÷º° X / Y »ç¿ë)
    Gui, SSOKAutoClick:Add, Text, x30 y304 w45 h22, »ç¿ë
    Gui, SSOKAutoClick:Add, Text, x78 y304 w45 h22, È¸Â÷
    Gui, SSOKAutoClick:Add, Text, x130 y304 w126 h22 Center, ½ÇÇà ³¯Â¥ (´Þ·Â ¼±ÅÃ)
    Gui, SSOKAutoClick:Add, Text, x264 y304 w194 h22 Center, ¿ÀÀü / ¿ÀÈÄ  ½Ã : ºÐ : ÃÊ
    Gui, SSOKAutoClick:Add, Text, x470 y304 w56 h22 Center, X
    Gui, SSOKAutoClick:Add, Text, x536 y304 w56 h22 Center, Y
    Gui, SSOKAutoClick:Add, Text, x688 y304 w260 h22, ÀÔ·ÂÇÒ ÅØ½ºÆ® (¼±ÅÃ)
    Loop, 5
    {
        idx := A_Index
        rowY := 332 + ((idx - 1) * 36)
        useChecked := SSOK_AutoClickUse%idx%
        chooseDate := SSOK_AutoClickDate%idx%
        chooseAmPm := SSOK_AutoClickAmPm%idx%
        Gui, SSOKAutoClick:Add, CheckBox, x40 y%rowY% w24 h24 vSSOK_AutoClickUse%idx% Checked%useChecked%
        Gui, SSOKAutoClick:Add, Text, x78 y%rowY% w48 h24 +0x200, %idx%È¸Â÷
        Gui, SSOKAutoClick:Add, DateTime, x130 y%rowY% w126 h24 vSSOK_AutoClickDate%idx% Choose%chooseDate%, yyyy-MM-dd
        Gui, SSOKAutoClick:Add, DropDownList, x264 y%rowY% w62 vSSOK_AutoClickAmPm%idx% AltSubmit Choose%chooseAmPm%, ¿ÀÀü|¿ÀÈÄ
        Gui, SSOKAutoClick:Add, Edit, x334 y%rowY% w34 h24 Center Limit2 vSSOK_AutoClickH%idx%, % SSOK_AutoClickH%idx%
        Gui, SSOKAutoClick:Add, Text, x370 y%rowY% w10 h24 +0x200, :
        Gui, SSOKAutoClick:Add, Edit, x380 y%rowY% w34 h24 Center Limit2 vSSOK_AutoClickM%idx%, % SSOK_AutoClickM%idx%
        Gui, SSOKAutoClick:Add, Text, x416 y%rowY% w10 h24 +0x200, :
        Gui, SSOKAutoClick:Add, Edit, x426 y%rowY% w34 h24 Center Limit2 vSSOK_AutoClickS%idx%, % SSOK_AutoClickS%idx%
        Gui, SSOKAutoClick:Add, Edit, x470 y%rowY% w56 h24 Center vSSOK_AutoClickX%idx%, % SSOK_AutoClickX%idx%
        Gui, SSOKAutoClick:Add, Edit, x536 y%rowY% w56 h24 Center vSSOK_AutoClickY%idx%, % SSOK_AutoClickY%idx%
        Gui, SSOKAutoClick:Add, Button, x602 y%rowY% w78 h24 gSSOK_AutoClick_FindRange%idx%, ÁÂÇ¥Ã£±â
        Gui, SSOKAutoClick:Add, Edit, x688 y%rowY% w260 h24 vSSOK_AutoClickText%idx%, % SSOK_AutoClickText%idx%
    }
    Gui, SSOKAutoClick:Add, Text, x30 y510 w918 h36 c555555, »ç¿ë Ã¼Å©ÇÑ È¸Â÷¸¦ ÁöÁ¤ ÀÏ½Ã¿¡ ÇÑ ¹ø ½ÇÇàÇÕ´Ï´Ù. ¿ÀÀü 12½Ã = ÀÚÁ¤ / ¿ÀÈÄ 12½Ã = Á¤¿À.`nÅØ½ºÆ®°¡ ºñ¾î ÀÖÀ¸¸é Å¬¸¯¸¸ ÇÕ´Ï´Ù. ÀýÀü µîÀ¸·Î ½ÇÇà ½Ã°¢ÀÌ 2ÃÊ ³Ñ°Ô Áö³ª¸é ÇØ´ç ¿¹¾àÀº °Ç³Ê¶Ý´Ï´Ù.
    Gui, SSOKAutoClick:Add, Button, x30 y552 w90 h30 gSSOK_AutoClick_StartSchedule, ½ÃÀÛ
    Gui, SSOKAutoClick:Add, Button, x132 y552 w90 h30 gSSOK_AutoClick_StopSchedule, ÁßÁö
    Gui, SSOKAutoClick:Add, Text, x240 y556 w700 h24 vSSOK_AutoClickScheduleStatus c005BAC, ´ë±â Áß
    Gui, SSOKAutoClick:Add, Text, x24 y610 w930 h24 vSSOK_AutoClickStatus c777777, µÎ ¿µ¿ªÀÇ ½ÃÀÛ / ÁßÁö´Â °¢°¢ µ¶¸³ÀûÀ¸·Î µ¿ÀÛÇÕ´Ï´Ù.
    Gosub, SSOK_AutoClick_UpdateRangeText
    Gosub, SSOK_AutoClick_ApplyIntervalEnabled
    Gosub, SSOK_AutoClick_SaveSettings
    SSOK_Tool_GetSidebarAttachedGuiPos(980, 644, SSOK_AutoClickWinX, SSOK_AutoClickWinY)
    Gui, SSOKAutoClick:Show, x%SSOK_AutoClickWinX% y%SSOK_AutoClickWinY% w980 h644, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯
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

SSOK_AutoClick_FindRange4:
    SSOK_AutoClickFindIndex := 4
    Gosub, SSOK_AutoClick_FindRange
return

SSOK_AutoClick_FindRange5:
    SSOK_AutoClickFindIndex := 5
    Gosub, SSOK_AutoClick_FindRange
return

SSOK_AutoClick_FindRange:
    Gui, SSOKAutoClick:Submit, NoHide
    if (SSOK_AutoClickFindIndex < 0 || SSOK_AutoClickFindIndex > 5)
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
    Loop, 5
    {
        idx := A_Index
        GuiControl, SSOKAutoClick:, SSOK_AutoClickX%idx%, % SSOK_AutoClickX%idx%
        GuiControl, SSOKAutoClick:, SSOK_AutoClickY%idx%, % SSOK_AutoClickY%idx%
    }

return

SSOK_AutoClick_ToggleInterval:
    GuiControlGet, SSOK_AutoClickEnabled, SSOKAutoClick:, SSOK_AutoClickEnabled
    Gosub, SSOK_AutoClick_ApplyIntervalEnabled
    Gosub, SSOK_AutoClick_SaveSettings
return

SSOK_AutoClick_ApplyIntervalEnabled:
    SSOK_AutoClickEnableCommand := (SSOK_AutoClickEnabled ? "Enable" : "Disable")
    for _, controlName in ["SSOK_AutoClickIntervalValue", "SSOK_AutoClickIntervalUnit", "SSOK_AutoClickIntervalFind", "SSOK_AutoClickIntervalStart", "SSOK_AutoClickIX", "SSOK_AutoClickIY"]
        GuiControl, SSOKAutoClick:%SSOK_AutoClickEnableCommand%, %controlName%
    for _, radioHwnd in [SSOK_AutoClickModeCursorHwnd, SSOK_AutoClickModeCoordHwnd]
        DllCall("EnableWindow", "Ptr", radioHwnd, "Int", SSOK_AutoClickEnabled)
    if (!SSOK_AutoClickEnabled)
    {
        Gosub, SSOK_AutoClick_Stop
        GuiControl, SSOKAutoClick:, SSOK_AutoClickIntervalStatus, »ç¿ë ¾È ÇÔ
    }
    else if (!SSOK_AutoClickRunning)
        GuiControl, SSOKAutoClick:, SSOK_AutoClickIntervalStatus, ´ë±â Áß - ½ÃÀÛ ¹öÆ°À» ´©¸£¼¼¿ä.
return

SSOK_AutoClick_Start:
    Gui, SSOKAutoClick:Submit, NoHide
    if (!SSOK_AutoClickEnabled)
        return
    if (!SSOK_AutoClickIntervalSeconds(SSOK_AutoClickIntervalValue, SSOK_AutoClickIntervalUnit, SSOK_AutoClickSec))
    {
        MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, ¹Ýº¹ °£°ÝÀº 0.1ÃÊ ÀÌ»óÀÎ ¼ýÀÚ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä. ÃÖ´ë ¾à 596½Ã°£±îÁö ¼³Á¤ÇÒ ¼ö ÀÖ½À´Ï´Ù.
        return
    }
    if (SSOK_AutoClickSec > 0 && SSOK_AutoClickMode = 2)
    {
        SSOK_AutoClickIX := Trim(SSOK_AutoClickIX)
        SSOK_AutoClickIY := Trim(SSOK_AutoClickIY)
        if !(RegExMatch(SSOK_AutoClickIX, "^-?\d+$") && RegExMatch(SSOK_AutoClickIY, "^-?\d+$"))
        {
            MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, 1¹øÀÇ X / Y ÁÂÇ¥¸¦ ¼ýÀÚ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
            return
        }
    }
    Gosub, SSOK_AutoClick_Stop
    SSOK_AutoClickIntervalRun := {mode: SSOK_AutoClickMode, x: SSOK_AutoClickIX, y: SSOK_AutoClickIY}
    SSOK_AutoClickTimerMs := Max(100, Round(SSOK_AutoClickSec * 1000))
    Gosub, SSOK_AutoClick_SaveSettings
    SSOK_AutoClickRunning := 1
    SetTimer, SSOK_AutoClick_DoClick, %SSOK_AutoClickTimerMs%
    SSOK_AutoClickUnitName := ["ÃÊ", "ºÐ", "½Ã°£"][SSOK_AutoClickIntervalUnit]
    GuiControl, SSOKAutoClick:, SSOK_AutoClickIntervalStatus, % SSOK_AutoClickIntervalValue . SSOK_AutoClickUnitName . "¸¶´Ù Å¬¸¯ ½ÇÇà Áß"

return

SSOK_AutoClick_Stop:
    SSOK_AutoClickRunning := 0
    SetTimer, SSOK_AutoClick_DoClick, Off
    GuiControl, SSOKAutoClick:, SSOK_AutoClickIntervalStatus, ÁßÁöµÊ
return

SSOK_AutoClick_StartSchedule:
    Gui, SSOKAutoClick:Submit, NoHide
    SSOK_AutoClickPending := []
    SSOK_AutoClickStartStamp := A_Now
    Loop, 5
    {
        idx := A_Index
        if (SSOK_AutoClickUse%idx% != 1)
            continue
        if (!SSOK_AutoClickMakeStamp(SSOK_AutoClickDate%idx%, SSOK_AutoClickAmPm%idx%, SSOK_AutoClickH%idx%, SSOK_AutoClickM%idx%, SSOK_AutoClickS%idx%, runStamp))
        {
            MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %idx%È¸Â÷ÀÇ ³¯Â¥¿Í ¿ÀÀü/¿ÀÈÄ¸¦ ¼±ÅÃÇÏ°í 01~12½Ã / 00~59ºÐ / 00~59ÃÊ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
            return
        }
        if (runStamp <= SSOK_AutoClickStartStamp)
        {
            MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %idx%È¸Â÷ÀÇ ¿¹¾à ½Ã°¢ÀÌ ÀÌ¹Ì Áö³µ½À´Ï´Ù. ÇöÀçº¸´Ù ÀÌÈÄÀÇ ³¯Â¥¿Í ½Ã°£À» ÁöÁ¤ÇØ ÁÖ¼¼¿ä.
            return
        }
        runX := Trim(SSOK_AutoClickX%idx%)
        runY := Trim(SSOK_AutoClickY%idx%)
        if (SSOK_AutoClickTimeMode = 2 && !(RegExMatch(runX, "^-?\d+$") && RegExMatch(runY, "^-?\d+$")))
        {
            MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, %idx%È¸Â÷ÀÇ X / Y ÁÂÇ¥¸¦ ¼ýÀÚ·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
            return
        }
        SSOK_AutoClickPending.Push({index: idx, stamp: runStamp, mode: SSOK_AutoClickTimeMode, x: runX, y: runY, text: SSOK_AutoClickText%idx%, done: false})
    }
    if (!SSOK_AutoClickPending.Length())
    {
        MsgBox, 48, SSOK ÀÚµ¿ ¸¶¿ì½º Å¬¸¯, ½ÇÇàÇÒ È¸Â÷ÀÇ »ç¿ëÀ» Ã¼Å©ÇØ ÁÖ¼¼¿ä.
        return
    }
    Gosub, SSOK_AutoClick_StopSchedule
    SSOK_AutoClickScheduleRun := SSOK_AutoClickPending
    Gosub, SSOK_AutoClick_SaveSettings
    SSOK_AutoClickScheduleRunning := 1
    SSOK_AutoClickCompleted := 0
    SSOK_AutoClickMissed := 0
    SetTimer, SSOK_AutoClick_CheckSchedule, 100
    GuiControl, SSOKAutoClick:, SSOK_AutoClickScheduleStatus, ¿¹¾à ´ë±â Áß - ÁöÁ¤ÇÑ ³¯Â¥ / ½Ã°£¿¡ ÇÑ ¹ø ½ÇÇà
return

SSOK_AutoClick_StopSchedule:
    SSOK_AutoClickScheduleRunning := 0
    SetTimer, SSOK_AutoClick_CheckSchedule, Off
    GuiControl, SSOKAutoClick:, SSOK_AutoClickScheduleStatus, ÁßÁöµÊ
return

SSOK_AutoClick_DoClick:
    Critical
    if (!SSOK_AutoClickRunning || SSOK_AutoClickFindActive)
        return
    SSOK_AutoClickExecute(SSOK_AutoClickIntervalRun)
return

SSOK_AutoClick_CheckSchedule:
    Critical
    if (!SSOK_AutoClickScheduleRunning || SSOK_AutoClickFindActive)
        return
    for _, action in SSOK_AutoClickScheduleRun
    {
        dueState := SSOK_AutoClickDueState(action, A_Now)
        if (dueState = 0)
            continue
        action.done := true
        if (dueState = 1)
        {
            SSOK_AutoClickExecute(action)
            SSOK_AutoClickCompleted += 1
        }
        else
            SSOK_AutoClickMissed += 1
    }
    SSOK_AutoClickRemaining := SSOK_AutoClickScheduleRun.Length() - SSOK_AutoClickCompleted - SSOK_AutoClickMissed
    if (!SSOK_AutoClickRemaining)
    {
        SSOK_AutoClickScheduleRunning := 0
        SetTimer, SSOK_AutoClick_CheckSchedule, Off
    }
    GuiControl, SSOKAutoClick:, SSOK_AutoClickScheduleStatus, % "´ë±â " . SSOK_AutoClickRemaining . " / ½ÇÇà ¿Ï·á " . SSOK_AutoClickCompleted . " / ½Ã°£ °æ°ú " . SSOK_AutoClickMissed

return

SSOK_AutoClick_SaveSettings:
    Gui, SSOKAutoClick:Submit, NoHide
    SSOK_AutoClickIni := SSOK_IniFile
    if (!SSOK_AutoClickEnabled)
        SSOK_AutoClickSec := 0
    else
        SSOK_AutoClickIntervalSeconds(SSOK_AutoClickIntervalValue, SSOK_AutoClickIntervalUnit, SSOK_AutoClickSec)
    IniWrite, %SSOK_AutoClickEnabled%, %SSOK_AutoClickIni%, AutoClick, IntervalEnabled
    IniWrite, %SSOK_AutoClickIntervalValue%, %SSOK_AutoClickIni%, AutoClick, IntervalValue
    IniWrite, %SSOK_AutoClickIntervalUnit%, %SSOK_AutoClickIni%, AutoClick, IntervalUnit
    IniWrite, %SSOK_AutoClickSec%, %SSOK_AutoClickIni%, AutoClick, Sec
    IniWrite, %SSOK_AutoClickMode%, %SSOK_AutoClickIni%, AutoClick, Mode
    IniWrite, %SSOK_AutoClickTimeMode%, %SSOK_AutoClickIni%, AutoClick, TimeMode
    IniWrite, %SSOK_AutoClickIX%, %SSOK_AutoClickIni%, AutoClick, IX
    IniWrite, %SSOK_AutoClickIY%, %SSOK_AutoClickIni%, AutoClick, IY
    IniWrite, 2, %SSOK_AutoClickIni%, AutoClick, CoordOneVer
    Loop, 5
    {
        idx := A_Index
        IniWrite, % SSOK_AutoClickUse%idx%, %SSOK_AutoClickIni%, AutoClick, Use%idx%
        IniWrite, % SSOK_AutoClickX%idx%, %SSOK_AutoClickIni%, AutoClick, X%idx%
        IniWrite, % SSOK_AutoClickY%idx%, %SSOK_AutoClickIni%, AutoClick, Y%idx%
        IniWrite, % SubStr(SSOK_AutoClickDate%idx%, 1, 8), %SSOK_AutoClickIni%, AutoClick, Date%idx%
        IniWrite, % SSOK_AutoClickAmPm%idx%, %SSOK_AutoClickIni%, AutoClick, AmPm%idx%
        IniWrite, % SSOK_AutoClickH%idx%, %SSOK_AutoClickIni%, AutoClick, H%idx%
        IniWrite, % SSOK_AutoClickM%idx%, %SSOK_AutoClickIni%, AutoClick, M%idx%
        IniWrite, % SSOK_AutoClickS%idx%, %SSOK_AutoClickIni%, AutoClick, S%idx%
        SSOK_AutoClickTextHex := SSOK_AutoClickEncodeText(SSOK_AutoClickText%idx%)
        IniWrite, %SSOK_AutoClickTextHex%, %SSOK_AutoClickIni%, AutoClick, TextHex%idx%
    }
return

SSOK_AutoClickExecute(action)
{
    CoordMode, Mouse, Screen
    if (action.mode = 2)
    {
        x := action.x + 0
        y := action.y + 0
        Click, %x%, %y%
    }
    else
        Click
    if (action.text != "")
    {
        ; Keep the click and literal Unicode input together, even with both timers active.
        Sleep, 100
        text := action.text
        SendInput, {Text}%text%
    }
}

SSOK_AutoClickEncodeText(text)
{
    hex := ""
    Loop, % StrLen(text)
        hex .= Format("{:04X}", NumGet(&text + (A_Index - 1) * 2, 0, "UShort"))
    return hex
}

SSOK_AutoClickDecodeText(hex)
{
    if (hex = "" || Mod(StrLen(hex), 4) || !RegExMatch(hex, "^[0-9A-Fa-f]+$"))
        return ""
    count := StrLen(hex) // 4
    VarSetCapacity(buffer, (count + 1) * 2, 0)
    Loop, %count%
        NumPut("0x" . SubStr(hex, (A_Index - 1) * 4 + 1, 4), buffer, (A_Index - 1) * 2, "UShort")
    return StrGet(&buffer, count, "UTF-16")
}

SSOK_AutoClickIntervalSeconds(value, unit, ByRef seconds)
{
    value := Trim(value)
    if (!RegExMatch(value, "^[0-9]+(\.[0-9]+)?$") || (unit != 1 && unit != 2 && unit != 3))
        return false
    candidate := value * (unit = 3 ? 3600 : unit = 2 ? 60 : 1)
    if (candidate < 0.1 || candidate * 1000 > 2147483647)
        return false
    seconds := candidate
    return true
}

SSOK_AutoClickValidDate(date)
{
    date := SubStr(date, 1, 8)
    if (!RegExMatch(date, "^\d{8}$"))
        return false
    stamp := date . "000000"
    if stamp is not time
        return false
    return true
}

SSOK_AutoClickMakeStamp(date, ampm, hh, mm, ss, ByRef stamp)
{
    date := SubStr(date, 1, 8)
    hh := Trim(hh), mm := Trim(mm), ss := Trim(ss)
    if (!SSOK_AutoClickValidDate(date) || (ampm != 1 && ampm != 2))
        return false
    if !(RegExMatch(hh, "^\d{1,2}$") && RegExMatch(mm, "^\d{1,2}$") && RegExMatch(ss, "^\d{1,2}$"))
        return false
    if (hh < 1 || hh > 12 || mm > 59 || ss > 59)
        return false
    hour24 := Mod(hh, 12) + (ampm = 2 ? 12 : 0)
    stamp := date . Format("{:02}{:02}{:02}", hour24, mm + 0, ss + 0)
    return true
}

SSOK_AutoClickDueState(action, now)
{
    if (action.done || now < action.stamp)
        return 0
    elapsed := now
    EnvSub, elapsed, % action.stamp, Seconds
    return (elapsed <= 2 ? 1 : -1)
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
    Gosub, SSOK_AutoClick_Stop
    Gosub, SSOK_AutoClick_StopSchedule
    Gosub, SSOK_AutoClick_SaveSettings
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
    ; °ø°øµ¥ÀÌÅÍÆ÷ÅÐÀÇ ÇöÀç °ø½Ä°ªÀ» fallbackÀ¸·Î ¸ÕÀú Ç¥½ÃÇÏ°í
    ; Ã¢ÀÌ ¶á µÚ Æ÷ÅÐ ÆäÀÌÁö¿¡¼­ ÃÖ½Å ¸ÞÅ¸µ¥ÀÌÅÍ¸¦ ´Ù½Ã ÀÐ¾î °»½ÅÇÕ´Ï´Ù.
    SSOK_SchoolDataTitle := "¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»_¼¼Á¾½Ã °ü³» ÇÐ±³±Þº° ÇöÈ² ¾È³»_20260702"
    SSOK_SchoolDataMeta := "°ü¸®ºÎ¼­: ±³À°º¹Áö°ú    ÀüÃ¼: 173°Ç`nµî·ÏÀÏ: 2025.09.17.    ¼öÁ¤ÀÏ: 2026.07.02.`n¾÷µ¥ÀÌÆ®: ¿¬°£    Â÷±âµî·Ï: 2027.07.30.    (°ø°øµ¥ÀÌÅÍÆ÷ÅÐ)"
    Gui, SSOKSchool:Font, s12 bold, Malgun Gothic
    Gui, SSOKSchool:Add, Text, x18 y12 w710 h30 c005BAC +0x200 vSSOK_SchoolDataTitleText, %SSOK_SchoolDataTitle%
    Gui, SSOKSchool:Font, s8 norm, Malgun Gothic
    Gui, SSOKSchool:Add, Text, x748 y4 w425 h62 c555555 Right vSSOK_SchoolDataMetaText, %SSOK_SchoolDataMeta%
    Gui, SSOKSchool:Font, s9 norm, Malgun Gothic
    Gui, SSOKSchool:Add, Text, x20 y64 w60 h24 +0x200, °Ë»ö¾î
    Gui, SSOKSchool:Add, Edit, x82 y62 w420 h26 vSSOK_SchoolSearchQuery
    Gui, SSOKSchool:Add, Button, x510 y61 w80 h28 Default gSSOK_SchoolSearch_DoSearch, °Ë»ö
    Gui, SSOKSchool:Add, Text, x20 y98 w1145 h38 vSSOK_SchoolSearchStatus c777777, °ø°øµ¥ÀÌÅÍÆ÷ÅÐ ÇÐ±³ Á¤º¸¸¦ ºÒ·¯¿À´Â ÁßÀÔ´Ï´Ù...
    Gui, SSOKSchool:Add, ListView, x18 y146 w1145 h410 vSSOK_SchoolSearchLV gSSOK_SchoolSearch_LVClick Grid AltSubmit, ±¸ºÐ|ÇÐ±³¸í|Áö¿ª¸í|ÀüÈ­|ÆÑ½º|ÇÐ±Þ¼ö|ÇÐ»ý¼ö|±³¿ø¼ö|ÁÖ¼Ò|È¨ÆäÀÌÁö
    SSOK_Tool_GetSidebarAttachedGuiPos(1180, 610, SSOK_SchoolSearchWinX, SSOK_SchoolSearchWinY)
    Gui, SSOKSchool:Show, x%SSOK_SchoolSearchWinX% y%SSOK_SchoolSearchWinY% w1180 h610, %SSOK_SchoolDataTitle%
    ; Ã¢ÀÌ ¿ÏÀüÈ÷ Ç¥½ÃµÇ±â Àü¿¡ API¸¦ ¹Ù·Î È£ÃâÇÏ¸é Ã¹ È£Ãâ¿¡¼­¸¸ 400/999·ù ¿À·ù°¡ ¶ß´Â °æ¿ì°¡ ÀÖ¾î
    ; ÀÚµ¿ ºÒ·¯¿À±â´Â Á¶±Ý ´ÊÃß°í, ÃÖÃÊ ÀÚµ¿ È£Ãâ ½ÇÆÐ ½Ã ÆË¾÷ ¾øÀÌ ÇÑ ¹ø ´õ Àç½ÃµµÇÕ´Ï´Ù.
    SSOK_SchoolSearch_IsAutoLoading := 0
    SSOK_SchoolSearch_AutoRetryDone := 0
    SetTimer, SSOK_SchoolSearch_AutoLoad, -700
    ; µ¥ÀÌÅÍÆ÷ÅÐ ¸ÞÅ¸µ¥ÀÌÅÍ´Â º°µµ·Î ÀÐ¾î »ó´Ü Á¦¸ñ/³¯Â¥/°Ç¼ö¸¦ ÃÖ½ÅÈ­

SetTimer, SSOK_SchoolSearch_LoadPortalMeta, -120
return

SSOK_SchoolSearch_LoadPortalMeta:
    SSOK_SchoolSearch_UpdatePortalMeta()
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
        url := "https://duckduckgo.com/?q=" . SSOK_Tool_QU_UrlEncode("!ducky " . query)
    }

    if (schoolName != "")
        GuiControl, SSOKSchool:, SSOK_SchoolSearchStatus, %schoolName% È¨ÆäÀÌÁö¸¦ ¿©´Â Áß...
    SSOK_Tool_OpenUrlPreferred(url)
return

SSOK_EduOfficeSearch_Show:
    ; ±³À°Ã» ¾÷¹«´ã´ç Á¶È¸: ¾÷¹«¸í °Ë»öÀÌ ±âº» ¼±ÅÃµÈ ºÎ¼­ ¾÷¹« ÆäÀÌÁö¸¦ ¿±´Ï´Ù.
    SSOK_Tool_OpenUrlPreferred(SSOK_EduOfficeSearch_GetUrl())
return

SSOK_EduOfficeSearch_OpenStaffPage:
    SSOK_Tool_OpenUrlPreferred(SSOK_EduOfficeSearch_GetUrl())
return

SSOK_EduOfficeSearch_OpenOfficePhone:
    SSOK_Tool_OpenUrlPreferred(SSOK_EduOfficeSearch_GetUrl())
return

SSOK_QU_OpenSchoolSearchFromMenu:
    if (!SSOK_QU_PinMode)
        Gui, SSOKQuickUrl:Destroy
    Gosub, SSOK_SchoolSearch_Show
return

SSOK_QU_OpenSchoolInfoFromMenu:
    if (!SSOK_QU_PinMode)
        Gui, SSOKQuickUrl:Destroy
    SSOK_Tool_OpenUrlPreferred("https://www.schoolinfo.go.kr/ei/ss/pneiss_a08_s0.do?SIDO_CODE=3611000000")
return

SSOK_QU_OpenSchoolInfo2FromMenu:
    if (!SSOK_QU_PinMode)
        Gui, SSOKQuickUrl:Destroy
    SSOK_OpenSchoolInfo2ForSejongElementary()
return

SSOK_QU_OpenLocalFinanceInfoFromMenu:
    if (!SSOK_QU_PinMode)
        Gui, SSOKQuickUrl:Destroy
    SSOK_OpenLocalFinanceInfoForSejongElementary()
return

SSOK_QU_OpenEduOfficeSearchFromMenu:
    if (!SSOK_QU_PinMode)
        Gui, SSOKQuickUrl:Destroy
    Gosub, SSOK_EduOfficeSearch_Show
return

SSOK_QU_OpenSchoolSupportInfoFromMenu:
    if (!SSOK_QU_PinMode)
        Gui, SSOKQuickUrl:Destroy
    SSOK_Tool_OpenUrlPreferred("https://sssc.sje.go.kr/sssc/cm/conts/contsView.do?mi=201304&contsId=201058")
return

SSOK_QU_OpenContractInfoFromMenu:
    if (!SSOK_QU_PinMode)
        Gui, SSOKQuickUrl:Destroy
    Gosub, SSOK_QU_OpenContractInfo
return

SSOK_QU_OpenContractInfo:
    SSOK_Tool_OpenUrlPreferred("https://www.sje.go.kr/sje/ir/selectCntrInfoList.do?mi=52495")
return

SSOK_OpenSchoolInfo2ForSejongElementary()
{
    url := "https://www.schoolinfo.go.kr/ng/go/pnnggo_a01_l2.do"
    browserExe := SSOK_Tool_OpenUrlPreferred(url)
    if (browserExe = "")
        return false

    Sleep, 4800
    SSOK_Tool_ACC_ActivateBrowser(browserExe)
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
    browserExe := SSOK_Tool_OpenUrlPreferred(url)
    if (browserExe = "")
        return false

    ; ÆäÀÌÁöÀÇ ¼­¿ï ±âº» °Ë»öÀÌ ³¡³­ µÚ ¼¼Á¾ °Ë»öÀ¸·Î ¹Ù²ß´Ï´Ù.
    Sleep, 5200
    SSOK_Tool_ACC_ActivateBrowser(browserExe)
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


SSOK_SchoolSearch_GetPortalUrl()
{
    return "https://www.data.go.kr/data/15050938/fileData.do"
}

SSOK_SchoolSearch_UpdatePortalMeta()
{
    global SSOK_SchoolDataTitle, SSOK_SchoolDataMeta

    meta := SSOK_SchoolSearch_FetchPortalMeta(err)

    if (!IsObject(meta) || !meta.ok)
        return false

    SSOK_SchoolDataTitle := meta.name

    metaText := "°ü¸®ºÎ¼­: " . meta.department
    if (meta.totalRows != "")
        metaText .= "    ÀüÃ¼: " . meta.totalRows . "°Ç"

    metaText .= "`nµî·ÏÀÏ: " . SSOK_SchoolSearch_FormatPortalDate(meta.registered)
        . "    ¼öÁ¤ÀÏ: " . SSOK_SchoolSearch_FormatPortalDate(meta.modified)

    metaText .= "`n¾÷µ¥ÀÌÆ®: " . meta.updateCycle
    if (meta.nextDate != "")
        metaText .= "    Â÷±âµî·Ï: " . SSOK_SchoolSearch_FormatPortalDate(meta.nextDate)
    metaText .= "    (°ø°øµ¥ÀÌÅÍÆ÷ÅÐ)"

    SSOK_SchoolDataMeta := metaText

    GuiControl, SSOKSchool:, SSOK_SchoolDataTitleText, %SSOK_SchoolDataTitle%
    GuiControl, SSOKSchool:, SSOK_SchoolDataMetaText, %SSOK_SchoolDataMeta%

    return true
}

SSOK_SchoolSearch_FetchPortalMeta(ByRef errMsg)
{
    errMsg := ""
    url := SSOK_SchoolSearch_GetPortalUrl()

    try
    {
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(3000, 3000, 6000, 6000)
        req.Open("GET", url, false)
        req.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) SSOK/1.0")
        req.SetRequestHeader("Accept-Language", "ko-KR,ko;q=0.9")
        req.Send()

        if (req.Status < 200 || req.Status >= 400)
        {
            errMsg := "°ø°øµ¥ÀÌÅÍÆ÷ÅÐ ¸ÞÅ¸Á¤º¸ ÀÀ´ä ¿À·ù: HTTP " . req.Status
            return {ok:false}
        }

        ; data.go.krÀº UTF-8ÀÌ¹Ç·Î ResponseBody¸¦ ¸í½ÃÀûÀ¸·Î UTF-8·Î ÀÐ½À´Ï´Ù.
        html := SSOK_SchoolSearch_ResponseBodyToUtf8(req.ResponseBody)

        if (html = "")
            html := req.ResponseText . ""

        if (html = "")
        {
            errMsg := "°ø°øµ¥ÀÌÅÍÆ÷ÅÐ ¸ÞÅ¸Á¤º¸¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù."
            return {ok:false}
        }

        plain := SSOK_SchoolSearch_HtmlToPlainText(html)

        ; ÇÑ ÆäÀÌÁö ¾È¿¡ ÆÄÀÏµ¥ÀÌÅÍ/¿ÀÇÂAPI Á¤º¸°¡ ¸ðµÎ ÀÖÀ¸¹Ç·Î
        ; Ã¹ ¹øÂ° 'ÆÄÀÏµ¥ÀÌÅÍ Á¤º¸' ¿µ¿ªÀ» ±âÁØÀ¸·Î ÆÄ½ÌÇÕ´Ï´Ù.
        filePos := InStr(plain, "ÆÄÀÏµ¥ÀÌÅÍ Á¤º¸")
        apiPos := InStr(plain, "¿ÀÇÂAPI Á¤º¸", false, filePos + 1)

        if (filePos > 0)
        {
            if (apiPos > filePos)
                section := SubStr(plain, filePos, apiPos - filePos)
            else
                section := SubStr(plain, filePos)
        }
        else
            section := plain

        name := SSOK_SchoolSearch_MetaValue(section, "ÆÄÀÏµ¥ÀÌÅÍ¸í", "ºÐ·ùÃ¼°è")
        department := SSOK_SchoolSearch_MetaValue(section, "°ü¸®ºÎ¼­¸í", "°ü¸®ºÎ¼­ ÀüÈ­¹øÈ£")
        updateCycle := SSOK_SchoolSearch_MetaValue(section, "¾÷µ¥ÀÌÆ® ÁÖ±â", "Â÷±â µî·Ï ¿¹Á¤ÀÏ")
        nextDate := SSOK_SchoolSearch_MetaValue(section, "Â÷±â µî·Ï ¿¹Á¤ÀÏ", "»ó¼¼ ¹× Á¦°øÁ¤º¸")
        totalRows := SSOK_SchoolSearch_MetaValue(section, "ÀüÃ¼ Çà", "Å°¿öµå")
        registered := SSOK_SchoolSearch_MetaValue(section, "µî·ÏÀÏ", "¼öÁ¤ÀÏ")
        modified := SSOK_SchoolSearch_MetaValue(section, "¼öÁ¤ÀÏ", "±âÅ¸ À¯ÀÇ»çÇ×")

        name := SSOK_SchoolSearch_CleanMetaValue(name)
        department := SSOK_SchoolSearch_CleanMetaValue(department)
        updateCycle := SSOK_SchoolSearch_CleanMetaValue(updateCycle)
        nextDate := SSOK_SchoolSearch_CleanMetaValue(nextDate)
        totalRows := SSOK_SchoolSearch_CleanMetaValue(totalRows)
        registered := SSOK_SchoolSearch_CleanMetaValue(registered)
        modified := SSOK_SchoolSearch_CleanMetaValue(modified)

        ; Æ÷ÅÐ ±¸Á¶°¡ Á¶±Ý ¹Ù²î´õ¶óµµ ÇÙ½É°ªÀÌ ¾øÀ¸¸é ±âÁ¸ fallbackÀ» À¯Áö
        if (name = "" || registered = "" || modified = "")
        {
            errMsg := "°ø°øµ¥ÀÌÅÍÆ÷ÅÐ ¸ÞÅ¸Á¤º¸ ±¸Á¶¸¦ ÇØ¼®ÇÏÁö ¸øÇß½À´Ï´Ù."
            return {ok:false}
        }

        if (department = "")
            department := "±³À°º¹Áö°ú"
        if (updateCycle = "")
            updateCycle := "¿¬°£"

        return {ok:true
            , name:name
            , department:department
            , updateCycle:updateCycle
            , nextDate:nextDate
            , totalRows:totalRows
            , registered:registered
            , modified:modified}
    }
    catch e
    {
        errMsg := e.Message
        return {ok:false}
    }
}

SSOK_SchoolSearch_ResponseBodyToUtf8(body)
{
    try
    {
        stream := ComObjCreate("ADODB.Stream")
        stream.Type := 1
        stream.Open()
        stream.Write(body)
        stream.Position := 0
        stream.Type := 2
        stream.Charset := "utf-8"
        text := stream.ReadText()
        stream.Close()
        return text
    }
    catch e
    {
        return ""
    }
}

SSOK_SchoolSearch_HtmlToPlainText(html)
{
    try
    {
        doc := ComObjCreate("HTMLFile")
        doc.Open()
        doc.Write(html)
        doc.Close()

        if IsObject(doc.body)
            plain := doc.body.innerText . ""
        else
            plain := ""
    }
    catch e
    {
        plain := ""
    }

    if (plain = "")
    {
        plain := RegExReplace(html, "is)<script\b[^>]*>.*?</script>", " ")
        plain := RegExReplace(plain, "is)<style\b[^>]*>.*?</style>", " ")
        plain := RegExReplace(plain, "is)<br\s*/?>", "`n")
        plain := RegExReplace(plain, "is)</(li|p|div|dt|dd|tr|h\d)>", "`n")
        plain := RegExReplace(plain, "is)<[^>]+>", " ")
        plain := StrReplace(plain, "&nbsp;", " ")
        plain := StrReplace(plain, "&#160;", " ")
        plain := StrReplace(plain, "&amp;", "&")
    }

    plain := StrReplace(plain, "`r", "")
    plain := RegExReplace(plain, "[ `t]+", " ")
    plain := RegExReplace(plain, " *`n *", "`n")
    plain := RegExReplace(plain, "`n{2,}", "`n")

    return Trim(plain)
}

SSOK_SchoolSearch_MetaValue(section, label, nextLabel)
{
    p1 := InStr(section, label)

    if (!p1)
        return ""

    p1 += StrLen(label)

    p2 := InStr(section, nextLabel, false, p1)

    if (!p2)
        return ""

    return Trim(SubStr(section, p1, p2 - p1))
}

SSOK_SchoolSearch_CleanMetaValue(value)
{
    s := Trim(value . "")
    s := RegExReplace(s, "^[\s:£º\-]+", "")
    s := RegExReplace(s, "[\s`r`n]+", " ")
    return Trim(s)
}

SSOK_SchoolSearch_FormatPortalDate(value)
{
    s := Trim(value . "")

    if RegExMatch(s, "(\d{4})[-./](\d{1,2})[-./](\d{1,2})", m)
        return Format("{:04}.{:02}.{:02}.", m1 + 0, m2 + 0, m3 + 0)

    return s
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
        encodedKey := SSOK_Tool_QU_UrlEncode(serviceKey)

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

; =========================================================
; Win + F9 : Gemini ¹Ù·Î ¿­±â
; - ºí·Ï ÁöÁ¤ ½Ã: ¼±ÅÃ ¹®±¸¸¦ Gemini ÀÔ·ÂÃ¢¿¡ °Ë»ö¾î/Áú¹®À¸·Î ºÙ¿©³Ö±â
; - ºí·Ï ¹ÌÁöÁ¤ ½Ã: Gemini »õ ÅÇ¸¸ ¿­±â
; - Chrome ¡æ Edge ¡æ ±âº» ºê¶ó¿ìÀú ¼øÀ¸·Î ½ÇÇà
; =========================================================
#F9::
    SSOK_ToolDynamicLabel := "SSOK_WinHelp_CancelDirect"
    if IsLabel(SSOK_ToolDynamicLabel)
        Gosub, %SSOK_ToolDynamicLabel%
    Gosub, SSOK_DoF9
return

SSOK_DoF9:
    ClipSavedF9 := ClipboardAll
    ; ºí·Ï ÁöÁ¤ ¿©ºÎ È®ÀÎ
    f9Text := ""
    if (SSOK_Tool_CopyClipboardText(f9RawText, 0.35, 2) && f9RawText != "")
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
    SSOK_Tool_OpenUrlPreferred("https://gemini.google.com/app")
}

SSOK_OpenGeminiAndPaste(queryText)
{
    ClipSavedGemini := ClipboardAll

    browserExe := SSOK_Tool_OpenUrlPreferred("https://gemini.google.com/app")
    if (browserExe = "")
        Sleep, 1800

    if (browserExe != "" && browserExe != "default")
        WinWaitActive, ahk_exe %browserExe%, , 8

    ; ÆäÀÌÁö ·Îµå ¿©À¯ ´ë±â ÈÄ ¼±ÅÃ ¹®±¸ ÀÔ·Â
    Sleep, 1800
    if (!SSOK_Tool_SetClipboardTextWithWait(queryText, 0.7, 3))
    {
        Clipboard := ClipSavedGemini
        return
    }
    Send, ^v
    Sleep, 250
    Clipboard := ClipSavedGemini
}



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
    Gui, SSOKGeminiAI:Add, Text, x20 y28 w640 h34 c005BAC Center, SSOK Gemini AI µµ¿ì¹Ì
    Gui, SSOKGeminiAI:Font, s9 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x20 y76 w640 h24 c555555 Center, ÀÛ¼ºÀ» ¿øÇÏ´Â ¹®±¸¸¦ ºí·° ÁöÁ¤ÇÏ°í ¾Æ·¡ ¹öÆ°À» ¼±ÅÃÇÏ¸é, Gemini¿¡ ÇÁ·ÒÇÁÆ®°¡ ÀÚµ¿ ÀÔ·ÂµË´Ï´Ù.
    Gui, SSOKGeminiAI:Font, s11 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, GroupBox, x30 y116 w300 h180 c005BAC, ±â¾È¹®
    Gui, SSOKGeminiAI:Add, GroupBox, x350 y116 w300 h180 c005BAC, °èÈ¹¼­
    Gui, SSOKGeminiAI:Font, s10 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Button, x40 y160 w280 h54 gSSOK_AI_DraftMemo, 1. AI ÀÛ¼º
    Gui, SSOKGeminiAI:Add, Button, x360 y160 w280 h54 gSSOK_AI_PlanDoc, 1. AI ÀÛ¼º
    Gui, SSOKGeminiAI:Add, Button, x40 y226 w280 h54 gSSOK_AI_ReportConvert1, 2. HWP ¾ç½Ä º¯È¯
    Gui, SSOKGeminiAI:Add, Button, x360 y226 w280 h54 gSSOK_AI_ReportConvert2, 2. HWP ¾ç½Ä º¯È¯

    Gui, SSOKGeminiAI:Font, s9 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x40 y315 w600 h22 c777777, ºí·Ï ÁöÁ¤ÇÏÁö ¾Ê¾Æµµ Gemini¿¡¼­ ¿øÇÏ´Â ¹®±¸¸¦ ÀÛ¼ºÇÒ ¼ö ÀÖ½À´Ï´Ù.

    Gui, SSOKGeminiAI:Font, s9 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Button, x40 y337 w116 h30 gSSOK_AI_OpenSite1, %SSOK_AI_SiteName1%
    Gui, SSOKGeminiAI:Add, Button, x164 y337 w116 h30 gSSOK_AI_OpenSite2, %SSOK_AI_SiteName2%
    Gui, SSOKGeminiAI:Add, Button, x288 y337 w116 h30 gSSOK_AI_OpenSite3, %SSOK_AI_SiteName3%
    Gui, SSOKGeminiAI:Add, Button, x412 y337 w116 h30 gSSOK_AI_OpenSite4, %SSOK_AI_SiteName4%
    Gui, SSOKGeminiAI:Add, Button, x536 y337 w116 h30 gSSOK_AI_OpenSite5, %SSOK_AI_SiteName5%

    Gui, SSOKGeminiAI:Font, s10 bold, Malgun Gothic
    Gui, SSOKGeminiAI:Add, GroupBox, x30 y382 w620 h205 c005BAC, AI »çÀÌÆ® ¹Ù·Î°¡±â / ÀÌ¸§¡¤ÁÖ¼Ò ¼öÁ¤
    Gui, SSOKGeminiAI:Font, s8 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x60 y408 w120 h18 c005BAC Center, ÀÌ¸§
    Gui, SSOKGeminiAI:Add, Text, x190 y408 w300 h18 c005BAC Center, ÁÖ¼Ò

    Gui, SSOKGeminiAI:Font, s9 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x40 y433 w24 h24 c005BAC Center, 1
    Gui, SSOKGeminiAI:Add, Edit, x60 y429 w120 h28 vSSOK_AI_SiteNameEdit1, %SSOK_AI_SiteName1%
    Gui, SSOKGeminiAI:Add, Edit, x190 y429 w300 h28 vSSOK_AI_SiteUrlEdit1, %SSOK_AI_SiteUrl1%
    Gui, SSOKGeminiAI:Add, Button, x500 y428 w135 h30 gSSOK_AI_OpenSite1, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x40 y464 w24 h24 c005BAC Center, 2
    Gui, SSOKGeminiAI:Add, Edit, x60 y460 w120 h28 vSSOK_AI_SiteNameEdit2, %SSOK_AI_SiteName2%
    Gui, SSOKGeminiAI:Add, Edit, x190 y460 w300 h28 vSSOK_AI_SiteUrlEdit2, %SSOK_AI_SiteUrl2%
    Gui, SSOKGeminiAI:Add, Button, x500 y459 w135 h30 gSSOK_AI_OpenSite2, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x40 y495 w24 h24 c005BAC Center, 3
    Gui, SSOKGeminiAI:Add, Edit, x60 y491 w120 h28 vSSOK_AI_SiteNameEdit3, %SSOK_AI_SiteName3%
    Gui, SSOKGeminiAI:Add, Edit, x190 y491 w300 h28 vSSOK_AI_SiteUrlEdit3, %SSOK_AI_SiteUrl3%
    Gui, SSOKGeminiAI:Add, Button, x500 y490 w135 h30 gSSOK_AI_OpenSite3, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x40 y526 w24 h24 c005BAC Center, 4
    Gui, SSOKGeminiAI:Add, Edit, x60 y522 w120 h28 vSSOK_AI_SiteNameEdit4, %SSOK_AI_SiteName4%
    Gui, SSOKGeminiAI:Add, Edit, x190 y522 w300 h28 vSSOK_AI_SiteUrlEdit4, %SSOK_AI_SiteUrl4%
    Gui, SSOKGeminiAI:Add, Button, x500 y521 w135 h30 gSSOK_AI_OpenSite4, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Add, Text, x40 y557 w24 h24 c005BAC Center, 5
    Gui, SSOKGeminiAI:Add, Edit, x60 y553 w120 h28 vSSOK_AI_SiteNameEdit5, %SSOK_AI_SiteName5%
    Gui, SSOKGeminiAI:Add, Edit, x190 y553 w300 h28 vSSOK_AI_SiteUrlEdit5, %SSOK_AI_SiteUrl5%
    Gui, SSOKGeminiAI:Add, Button, x500 y552 w135 h30 gSSOK_AI_OpenSite5, ÀúÀå&&¿­±â

    Gui, SSOKGeminiAI:Font, s8 norm, Malgun Gothic
    Gui, SSOKGeminiAI:Add, Text, x40 y602 w400 h18 c999999, 5°³ AI »çÀÌÆ® ÀÌ¸§°ú ÁÖ¼Ò´Â ssok.ini¿¡ ÀúÀåµË´Ï´Ù.
    Gui, SSOKGeminiAI:Add, Button, x465 y595 w100 h30 gSSOK_AI_SaveSites, ÀüÃ¼ ÀúÀå
    Gui, SSOKGeminiAI:Add, Text, x350 y632 w290 h24 Right c999999, ÀúÀÛ±Ç: ¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã» ÁÖ¹«°ü ÀÌ¸íÈ£
    SSOK_Tool_GetSidebarAttachedGuiPos(680, 667, SSOK_AI_WinX, SSOK_AI_WinY)
    Gui, SSOKGeminiAI:Show, x%SSOK_AI_WinX% y%SSOK_AI_WinY% w680 h667, SSOK Gemini AI µµ¿ì¹Ì
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
    SSOK_Tool_CreateHwpxReportFromText(reportSource, "ssok_ai_report2_template.hwtx")
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
    SSOK_Tool_CreateHwpxReportFromText(reportSource, "ssok_ai_report1_template.hwtx")
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
    SSOK_Tool_SaveUnifiedIni()
    SSOK_AI_SaveActive := 0
    if (showNotice)
        MsgBox, 64, SSOK ¾È³», Win+F3 AI »çÀÌÆ® 5°³¸¦ ÀúÀåÇß½À´Ï´Ù.`n`nÀúÀå À§Ä¡: ssok.ini
}

SSOK_AI_OpenSiteIndex(index)
{
    global
    SSOK_AI_SaveSitesFromGui(0)
    urlVar := SSOK_AI_SiteUrl%index%
    urlVar := SSOK_Tool_QU_NormalizeUrl(urlVar)
    if (urlVar = "")
    {
        MsgBox, 48, SSOK ¾È³», AI »çÀÌÆ® ÁÖ¼Ò°¡ ºñ¾î ÀÖ½À´Ï´Ù.`n`nÁÖ¼Ò¸¦ ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    SetTimer, SSOK_AI_TrackTargetWindow, Off
    Gui, SSOKGeminiAI:Destroy
    SSOK_Tool_OpenUrlPreferred(urlVar)
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

SSOK_RunGeminiWithPrompt:
    ClipSaved2 := ClipboardAll

    if (prompt = "")
    {
        Clipboard := ClipSaved2
        return
    }

    browserExe := SSOK_Tool_OpenUrlPreferred("https://gemini.google.com/app")
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
    if (!SSOK_Tool_SetClipboardTextWithWait(prompt, 0.7, 3))
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



; =====================================

; =========================================================
; Win + 1 / Win + 2 / Win + 3
; - ¼¼ ´ÜÃàÅ° ¸ðµÎ ssok_tool_expense.ahk°¡ Àü´ãÇÕ´Ï´Ù.
; =========================================================

; =========================================================
; Win + 1 / Win + 2 / Win + 3
; - K-¿¡µàÆÄÀÎ °ü·Ã ´ÜÃàÅ°¿Í ½ÇÇà ·çÆ¾Àº ssok_tool_expense.ahk°¡ Àü´ãÇÕ´Ï´Ù.
; =========================================================

SSOK_CareerDaysInclusive(a, b)
{
    ; YYYYMMDD ¿ÜÀÇ ¹®ÀÚ¸¦ Á¦°ÅÇÑ µÚ ³¯Â¥½Ã°£ Çü½ÄÀ¸·Î º¯È¯
    a := RegExReplace(a, "[^0-9]", "")
    b := RegExReplace(b, "[^0-9]", "")

    if (StrLen(a) < 8 || StrLen(b) < 8)
        return 0

    startDT := SubStr(a, 1, 8) . "000000"
    endDT := SubStr(b, 1, 8) . "000000"

    EnvSub, endDT, %startDT%, Days
    if (ErrorLevel)
        return 0

    return (endDT + 1)
}

; [´Üµ¶ ½ÇÇà È£È¯] ssok_tool_expense.ahk´Â ssok.ahk º»Ã¼¿¡¼­ º°µµ·Î IncludeÇÕ´Ï´Ù.


; ============================================================================
; ÇàÁ¤¾÷¹«´Þ·Â - ¼­¿ïÆ¯º°½Ã±³À°Ã»(ÃÊ) + ºÎ»ê±¤¿ª½Ã±³À°Ã» + ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã» ÅëÇÕ ¾Ë¸²
; ¼³Á¤ ÀúÀå: ssok.ini [AdminCalendar]
; ±âº»°ª: Áö¿ª ¼­¿ï+ºÎ»ê+ÀüºÏ / ON / 09:00, 11:00, 14:00, 16:30
; ============================================================================

SSOK_AdminCalendar_StandaloneInit:
    Gosub, SSOK_AdminCalendar_Init
return

SSOK_AdminCalendar_Init:
    SSOK_AdminCalendar_LoadSettings()
    SetTimer, SSOK_AdminCalendar_Timer, 15000
    ; ÇÁ·Î±×·¥ ½ÃÀÛ Á÷ÈÄ¿¡µµ ¿ÀÀü ÃÖÃÊ 1È¸ Ç¥½Ã Á¶°ÇÀ» È®ÀÎÇÕ´Ï´Ù.
    SetTimer, SSOK_AdminCalendar_StartupCheck, -1200
return

SSOK_AdminCalendar_StartupCheck:
    SSOK_AdminCalendar_CheckNow()
return

SSOK_AdminCalendar_Timer:
    SSOK_AdminCalendar_CheckNow()
return

SSOK_AdminCalendar_ToggleTipHide:
    ToolTip
return

SSOK_AdminCalendar_PopupHide:
    Gui, SSOKAdminCalPopup:Destroy
return

; ÇàÁ¤¾÷¹« ´Þ·Â ÆË¾÷ÀÇ [½Ä´ÜÁ¤º¸ ¹Ù·Î°¡±â]
; ¸ÞÀÎ¿¡ ÀúÀåµÈ ¿ì¸®ÇÐ±³¸¦ SSOK ±³À°Á¤º¸ Ã¢À¸·Î ¿­°í ½Ä´ÜÁ¤º¸ ÅÇÀ» ¹Ù·Î ¼±ÅÃÇÕ´Ï´Ù.
SSOK_AdminCalendar_OpenMealInfo:
    Gui, SSOKAdminCalPopup:Destroy
    SSOK_AdminCalendar_OpenMySchoolMealInfo()
return

; ÇàÁ¤¾÷¹« ´Þ·Â ÆË¾÷ÀÇ [ÇÐ»çÁ¤º¸ ¹Ù·Î°¡±â]
; ¸ÞÀÎ¿¡ ÀúÀåµÈ ¿ì¸®ÇÐ±³¸¦ SSOK ±³À°Á¤º¸ Ã¢À¸·Î ¿­°í ÇÐ»çÀÏÁ¤ ÅÇÀ» ¹Ù·Î ¼±ÅÃÇÕ´Ï´Ù.
SSOK_AdminCalendar_OpenScheduleInfo:
    Gui, SSOKAdminCalPopup:Destroy
    SSOK_AdminCalendar_OpenMySchoolScheduleInfo()
return

; ÇàÁ¤¾÷¹« ´Þ·Â ÆË¾÷ÀÇ [¼³Á¤] - ±âÁ¸ ´Þ·Â ¼³Á¤Ã¢À» ¿±´Ï´Ù.
SSOK_AdminCalendar_OpenSettings:
    Gui, SSOKAdminCalPopup:Destroy
    SSOK_AdminCalendar_ShowSettings()
return

; ÇàÁ¤¾÷¹« ´Þ·Â ³¯Â¥ ÀÌµ¿/¼±ÅÃ
SSOK_AdminCalendar_DatePrev:
    SSOK_AdminCalendar_ShiftSelectedDate(-1)
return

SSOK_AdminCalendar_DateNext:
    SSOK_AdminCalendar_ShiftSelectedDate(1)
return

SSOK_AdminCalendar_DateToday:
    todayYmd := A_YYYY . A_MM . A_DD
    SSOK_AdminCalendar_ShowDatePopup(todayYmd, true)
return

SSOK_AdminCalendar_DatePickChanged:
    Gui, SSOKAdminCalPopup:Submit, NoHide
    pickedYmd := SubStr(SSOK_AdminCalDatePick, 1, 8)
    if RegExMatch(pickedYmd, "^\d{8}$")
        SSOK_AdminCalendar_ShowDatePopup(pickedYmd, true)
return

SSOK_AdminCalendar_Save:
    Gui, SSOKAdminCalSettings:Submit, NoHide

    t1 := SSOK_AdminCalendar_NormalizeTime(SSOK_AdminCalCfgTime1)
    t2 := SSOK_AdminCalendar_NormalizeTime(SSOK_AdminCalCfgTime2)
    t3 := SSOK_AdminCalendar_NormalizeTime(SSOK_AdminCalCfgTime3)
    t4 := SSOK_AdminCalendar_NormalizeTime(SSOK_AdminCalCfgTime4)

    if (SSOK_AdminCalCfgUse1 && t1 = "")
    {
        MsgBox, 48, ÇàÁ¤¾÷¹«´Þ·Â, 1È¸ ½Ã°£À» HH:mm Çü½ÄÀ¸·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    if (SSOK_AdminCalCfgUse2 && t2 = "")
    {
        MsgBox, 48, ÇàÁ¤¾÷¹«´Þ·Â, 2È¸ ½Ã°£À» HH:mm Çü½ÄÀ¸·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    if (SSOK_AdminCalCfgUse3 && t3 = "")
    {
        MsgBox, 48, ÇàÁ¤¾÷¹«´Þ·Â, 3È¸ ½Ã°£À» HH:mm Çü½ÄÀ¸·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }
    if (SSOK_AdminCalCfgUse4 && t4 = "")
    {
        MsgBox, 48, ÇàÁ¤¾÷¹«´Þ·Â, 4È¸ ½Ã°£À» HH:mm Çü½ÄÀ¸·Î ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }

    ; ²¨Áø È¸Â÷µµ ³ªÁß¿¡ ´Ù½Ã ÄÓ ¼ö ÀÖµµ·Ï Á¤»ó°ªÀº À¯Áö
    if (t1 = "")
        t1 := "09:00"
    if (t2 = "")
        t2 := "11:00"
    if (t3 = "")
        t3 := "14:00"
    if (t4 = "")
        t4 := "16:30"

    enabled := SSOK_AdminCalCfgOn ? 1 : 0
    useSeoul := SSOK_AdminCalCfgSeoul ? 1 : 0
    useBusan := SSOK_AdminCalCfgBusan ? 1 : 0
    useJeonbuk := SSOK_AdminCalCfgJeonbuk ? 1 : 0

    if (!useSeoul && !useBusan && !useJeonbuk)
    {
        MsgBox, 48, ÇàÁ¤¾÷¹«´Þ·Â, Áö¿ªÀ» ÇÏ³ª ÀÌ»ó ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }

    SSOK_AdminCalendar_WriteSettings(enabled
        , SSOK_AdminCalCfgUse1 ? 1 : 0, t1
        , SSOK_AdminCalCfgUse2 ? 1 : 0, t2
        , SSOK_AdminCalCfgUse3 ? 1 : 0, t3
        , SSOK_AdminCalCfgUse4 ? 1 : 0, t4
        , useSeoul, useJeonbuk, useBusan)

    SSOK_AdminCalLoaded := false
    SSOK_AdminCalendar_LoadSettings(true)
    SSOK_AdminCalendar_UpdateMenuText()

    count := 0
    times := ""
    if (SSOK_AdminCalCfgUse1)
    {
        count++
        times .= (times = "" ? "" : " / ") . t1
    }
    if (SSOK_AdminCalCfgUse2)
    {
        count++
        times .= (times = "" ? "" : " / ") . t2
    }
    if (SSOK_AdminCalCfgUse3)
    {
        count++
        times .= (times = "" ? "" : " / ") . t3
    }
    if (SSOK_AdminCalCfgUse4)
    {
        count++
        times .= (times = "" ? "" : " / ") . t4
    }

    regions := (useSeoul ? "¼­¿ï" : "")
    if (useBusan)
        regions .= (regions != "" ? " / " : "") . "ºÎ»ê"
    if (useJeonbuk)
        regions .= (regions != "" ? " / " : "") . "ÀüºÏ"

    msg := "¼³Á¤À» ÀúÀåÇß½À´Ï´Ù.`n`n»óÅÂ: " . (enabled ? "ON" : "OFF")
        . "`nÁö¿ª: " . regions
        . "`nPOPUP È½¼ö: " . count . "È¸"
        . (times != "" ? "`n½Ã°£: " . times : "")

    MsgBox, 64, ÇàÁ¤¾÷¹«´Þ·Â, %msg%
return

SSOK_AdminCalendar_Defaults:
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgOn, 1
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgOff, 0
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgSeoul, 1
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgBusan, 1
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgJeonbuk, 1

    ; ±âº» ¾Ë¸²Àº 09:00 / 14:00 µÎ ¹ø¸¸ »ç¿ë
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse1, 1
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse2, 0
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse3, 1
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse4, 0

    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgTime1, 09:00
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgTime2, 11:00
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgTime3, 14:00
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgTime4, 16:30
return

SSOK_AdminCalendar_Preview:
    SSOK_AdminCalendar_ShowTodayPopup(true)
return

SSOK_AdminCalendar_OpenSite:
    SSOK_AdminCalendar_LoadSettings()
    if (SSOK_AdminCalUseSeoul)
        SSOK_Tool_OpenUrlPreferred(SSOK_AdminCalendar_GetSeoulUrl())
    if (SSOK_AdminCalUseBusan)
        SSOK_Tool_OpenUrlPreferred(SSOK_AdminCalendar_GetBusanUrl())
    if (SSOK_AdminCalUseJeonbuk)
        SSOK_Tool_OpenUrlPreferred(SSOK_AdminCalendar_GetUrl())
return

SSOKAdminCalSettingsGuiClose:
SSOKAdminCalSettingsGuiEscape:
    Gui, SSOKAdminCalSettings:Destroy
return

SSOK_AdminCalendar_Toggle()
{
    global SSOK_AdminCalEnabled
    global SSOK_AdminCalUse1, SSOK_AdminCalUse2, SSOK_AdminCalUse3, SSOK_AdminCalUse4
    global SSOK_AdminCalTime1, SSOK_AdminCalTime2, SSOK_AdminCalTime3, SSOK_AdminCalTime4
    global SSOK_AdminCalUseSeoul, SSOK_AdminCalUseBusan, SSOK_AdminCalUseJeonbuk
    global SSOK_AdminCalLoaded

    SSOK_AdminCalendar_LoadSettings()
    enabled := SSOK_AdminCalEnabled ? 0 : 1

    SSOK_AdminCalendar_WriteSettings(enabled
        , SSOK_AdminCalUse1, SSOK_AdminCalTime1
        , SSOK_AdminCalUse2, SSOK_AdminCalTime2
        , SSOK_AdminCalUse3, SSOK_AdminCalTime3
        , SSOK_AdminCalUse4, SSOK_AdminCalTime4
        , SSOK_AdminCalUseSeoul, SSOK_AdminCalUseJeonbuk, SSOK_AdminCalUseBusan)

    SSOK_AdminCalLoaded := false
    SSOK_AdminCalendar_LoadSettings(true)
    SSOK_AdminCalendar_UpdateMenuText()

    ToolTip, % "ÇàÁ¤¾÷¹«´Þ·Â [" . (enabled ? "ON" : "OFF") . "]"
    SetTimer, SSOK_AdminCalendar_ToggleTipHide, -1200
}

SSOK_AdminCalendar_ShowSettings()
{
    global SSOK_AdminCalEnabled
    global SSOK_AdminCalUse1, SSOK_AdminCalUse2, SSOK_AdminCalUse3, SSOK_AdminCalUse4
    global SSOK_AdminCalTime1, SSOK_AdminCalTime2, SSOK_AdminCalTime3, SSOK_AdminCalTime4
    global SSOK_AdminCalCfgOn, SSOK_AdminCalCfgOff
    global SSOK_AdminCalUseSeoul, SSOK_AdminCalUseBusan, SSOK_AdminCalUseJeonbuk
    global SSOK_AdminCalCfgSeoul, SSOK_AdminCalCfgBusan, SSOK_AdminCalCfgJeonbuk
    global SSOK_AdminCalCfgUse1, SSOK_AdminCalCfgUse2, SSOK_AdminCalCfgUse3, SSOK_AdminCalCfgUse4
    global SSOK_AdminCalCfgTime1, SSOK_AdminCalCfgTime2, SSOK_AdminCalCfgTime3, SSOK_AdminCalCfgTime4

    SSOK_AdminCalendar_LoadSettings()

    Gui, SSOKAdminCalSettings:Destroy
    Gui, SSOKAdminCalSettings:New, +AlwaysOnTop +ToolWindow, ÇàÁ¤¾÷¹«´Þ·Â ¼³Á¤
    Gui, SSOKAdminCalSettings:Margin, 16, 14
    Gui, SSOKAdminCalSettings:Color, F7FBFF

    Gui, SSOKAdminCalSettings:Font, s11 Bold, Malgun Gothic
    Gui, SSOKAdminCalSettings:Add, Text, w390 h26, ÇàÁ¤¾÷¹«´Þ·Â

    Gui, SSOKAdminCalSettings:Font, s9 Bold, Malgun Gothic
    Gui, SSOKAdminCalSettings:Add, Text, y+4 w390 h22, ÀüÃ¼ »ç¿ë ¼³Á¤

    Gui, SSOKAdminCalSettings:Font, s9 Norm, Malgun Gothic
    Gui, SSOKAdminCalSettings:Add, Radio, y+2 w70 vSSOK_AdminCalCfgOn Group, ON
    Gui, SSOKAdminCalSettings:Add, Radio, x+15 yp w70 vSSOK_AdminCalCfgOff, OFF

    if (SSOK_AdminCalEnabled)
    {
        GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgOn, 1
        GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgOff, 0
    }
    else
    {
        GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgOn, 0
        GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgOff, 1
    }

    Gui, SSOKAdminCalSettings:Font, s9 Bold, Malgun Gothic
    Gui, SSOKAdminCalSettings:Add, Text, x16 y+15 w390 h22, Áö¿ª

Gui, SSOKAdminCalSettings:Font, s9 Norm, Malgun Gothic
    Gui, SSOKAdminCalSettings:Add, Checkbox, x24 y+2 w80 h24 vSSOK_AdminCalCfgSeoul, ¼­¿ï
    Gui, SSOKAdminCalSettings:Add, Checkbox, x112 yp w80 h24 vSSOK_AdminCalCfgBusan, ºÎ»ê
    Gui, SSOKAdminCalSettings:Add, Checkbox, x200 yp w80 h24 vSSOK_AdminCalCfgJeonbuk, ÀüºÏ
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgSeoul, %SSOK_AdminCalUseSeoul%
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgBusan, %SSOK_AdminCalUseBusan%
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgJeonbuk, %SSOK_AdminCalUseJeonbuk%

    Gui, SSOKAdminCalSettings:Font, s9 Bold, Malgun Gothic
    Gui, SSOKAdminCalSettings:Add, Text, x16 y+15 w390 h22, POPUP È½¼ö / ½Ã°£ ¼³Á¤
    Gui, SSOKAdminCalSettings:Add, Text, y+0 w390 h22 c005BAC, [±âº»] 2È¸  ¡¤  09:00 / 14:00   (11:00 / 16:30Àº ÇÊ¿ä ½Ã Ãß°¡)

    ; °¢ È¸Â÷¸¦ °³º° Ã¼Å©ÇØ¼­ »ç¿ë ¿©ºÎ¸¦ Á¤ÇÏ°í, ¿À¸¥ÂÊ¿¡¼­ ½Ã°£À» ¼öÁ¤
    Gui, SSOKAdminCalSettings:Font, s9 Norm, Malgun Gothic

    Gui, SSOKAdminCalSettings:Add, Checkbox, x24 y+10 w90 h24 vSSOK_AdminCalCfgUse1, 1È¸ »ç¿ë
    Gui, SSOKAdminCalSettings:Add, Edit, x125 yp w78 h24 Center vSSOK_AdminCalCfgTime1, %SSOK_AdminCalTime1%
    Gui, SSOKAdminCalSettings:Add, Text, x212 yp w165 h24 +0x200 c666666, ¿¹: 09:00

    Gui, SSOKAdminCalSettings:Add, Checkbox, x24 y+7 w90 h24 vSSOK_AdminCalCfgUse2, 2È¸ »ç¿ë
    Gui, SSOKAdminCalSettings:Add, Edit, x125 yp w78 h24 Center vSSOK_AdminCalCfgTime2, %SSOK_AdminCalTime2%
    Gui, SSOKAdminCalSettings:Add, Text, x212 yp w165 h24 +0x200 c666666, ¿¹: 11:00

    Gui, SSOKAdminCalSettings:Add, Checkbox, x24 y+7 w90 h24 vSSOK_AdminCalCfgUse3, 3È¸ »ç¿ë
    Gui, SSOKAdminCalSettings:Add, Edit, x125 yp w78 h24 Center vSSOK_AdminCalCfgTime3, %SSOK_AdminCalTime3%
    Gui, SSOKAdminCalSettings:Add, Text, x212 yp w165 h24 +0x200 c666666, ¿¹: 14:00

    Gui, SSOKAdminCalSettings:Add, Checkbox, x24 y+7 w90 h24 vSSOK_AdminCalCfgUse4, 4È¸ »ç¿ë
    Gui, SSOKAdminCalSettings:Add, Edit, x125 yp w78 h24 Center vSSOK_AdminCalCfgTime4, %SSOK_AdminCalTime4%
    Gui, SSOKAdminCalSettings:Add, Text, x212 yp w165 h24 +0x200 c666666, ¿¹: 16:30

    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse1, %SSOK_AdminCalUse1%
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse2, %SSOK_AdminCalUse2%
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse3, %SSOK_AdminCalUse3%
    GuiControl, SSOKAdminCalSettings:, SSOK_AdminCalCfgUse4, %SSOK_AdminCalUse4%

    Gui, SSOKAdminCalSettings:Add, Button, x16 y+17 w84 h30 gSSOK_AdminCalendar_Save, ÀúÀå
    Gui, SSOKAdminCalSettings:Add, Button, x106 yp w84 h30 gSSOK_AdminCalendar_Defaults, ±âº»°ª
    Gui, SSOKAdminCalSettings:Add, Button, x196 yp w84 h30 gSSOK_AdminCalendar_Preview, ¿À´Ã ÀÏÁ¤
    Gui, SSOKAdminCalSettings:Add, Button, x286 yp w104 h30 gSSOK_AdminCalendar_OpenSite, ÇàÁ¤´Þ·Â ¿­±â

    Gui, SSOKAdminCalSettings:Font, s8 Norm, Malgun Gothic
    Gui, SSOKAdminCalSettings:Add, Text, x16 y+12 w390 h42 c666666, ¼±ÅÃÇÑ Áö¿ªÀÇ ¿À´Ã ÀÏÁ¤À» ÇÑ È­¸é¿¡ ÇÕÃÄ Ç¥½ÃÇÕ´Ï´Ù. ÀÏÁ¤ ¾Õ¿¡´Â ¼­¿ï/ºÎ»ê/ÀüºÏ Áö¿ª¸íÀ» ºÙÀÌÁö ¾Ê½À´Ï´Ù. ¾Ë¸² È½¼ö¿Í ½Ã°£Àº ±âÁ¸ ¼³Á¤À» ±×´ë·Î »ç¿ëÇÕ´Ï´Ù.

    Gui, SSOKAdminCalSettings:Show, AutoSize Center
}

SSOK_AdminCalendar_LoadSettings(force := false)
{
    global SSOK_AdminCalLoaded, SSOK_AdminCalEnabled
    global SSOK_AdminCalUse1, SSOK_AdminCalUse2, SSOK_AdminCalUse3, SSOK_AdminCalUse4
    global SSOK_AdminCalTime1, SSOK_AdminCalTime2, SSOK_AdminCalTime3, SSOK_AdminCalTime4
    global SSOK_AdminCalUseSeoul, SSOK_AdminCalUseBusan, SSOK_AdminCalUseJeonbuk

    if (SSOK_AdminCalLoaded && !force)
        return

    ini := SSOK_AdminCalendar_GetIniFile()

    IniRead, enabled, %ini%, AdminCalendar, Enabled, 1
    IniRead, presetVersion, %ini%, AdminCalendar, PresetVersion, 0
    IniRead, useSeoul, %ini%, AdminCalendar, UseSeoul, 1
    IniRead, useBusan, %ini%, AdminCalendar, UseBusan, 1
    IniRead, useJeonbuk, %ini%, AdminCalendar, UseJeonbuk, 1

    IniRead, use1, %ini%, AdminCalendar, Use1, 1
    IniRead, t1, %ini%, AdminCalendar, Time1, 09:00

    ; 11:00Àº ¼±ÅÃ Ãß°¡
    IniRead, use2, %ini%, AdminCalendar, Use2, 0
    IniRead, t2, %ini%, AdminCalendar, Time2, 11:00

    ; 14:00Àº ±âº» »ç¿ë
    IniRead, use3, %ini%, AdminCalendar, Use3, 1
    IniRead, t3, %ini%, AdminCalendar, Time3, 14:00

    ; 16:30Àº ¼±ÅÃ Ãß°¡
    IniRead, use4, %ini%, AdminCalendar, Use4, 0
    IniRead, t4, %ini%, AdminCalendar, Time4, 16:30

    ; ÀÌÀü °³¹ß¹öÀü¿¡¼­ 4È¸°¡ ±âº»ÀÌ´ø ¼³Á¤À» ÀÌ¹ø ±âº»°ªÀ¸·Î ÇÑ ¹ø¸¸ ÀüÈ¯
    if (presetVersion < 2)
    {
        use1 := 1
        use2 := 0
        use3 := 1
        use4 := 0

        IniWrite, 1, %ini%, AdminCalendar, Use1
        IniWrite, 0, %ini%, AdminCalendar, Use2
        IniWrite, 1, %ini%, AdminCalendar, Use3
        IniWrite, 0, %ini%, AdminCalendar, Use4
        IniWrite, 2, %ini%, AdminCalendar, PresetVersion
    }

    t1 := SSOK_AdminCalendar_NormalizeTime(t1)
    t2 := SSOK_AdminCalendar_NormalizeTime(t2)
    t3 := SSOK_AdminCalendar_NormalizeTime(t3)
    t4 := SSOK_AdminCalendar_NormalizeTime(t4)

    SSOK_AdminCalEnabled := (enabled = 0 || enabled = "0" || enabled = "OFF") ? 0 : 1
    SSOK_AdminCalUseSeoul := (useSeoul = 0 || useSeoul = "0") ? 0 : 1
    SSOK_AdminCalUseBusan := (useBusan = 0 || useBusan = "0") ? 0 : 1
    SSOK_AdminCalUseJeonbuk := (useJeonbuk = 0 || useJeonbuk = "0") ? 0 : 1

    if (!SSOK_AdminCalUseSeoul && !SSOK_AdminCalUseBusan && !SSOK_AdminCalUseJeonbuk)
        SSOK_AdminCalUseJeonbuk := 1

    SSOK_AdminCalUse1 := (use1 = 0 || use1 = "0") ? 0 : 1
    SSOK_AdminCalUse2 := (use2 = 0 || use2 = "0") ? 0 : 1
    SSOK_AdminCalUse3 := (use3 = 0 || use3 = "0") ? 0 : 1
    SSOK_AdminCalUse4 := (use4 = 0 || use4 = "0") ? 0 : 1

    SSOK_AdminCalTime1 := (t1 != "") ? t1 : "09:00"
    SSOK_AdminCalTime2 := (t2 != "") ? t2 : "11:00"
    SSOK_AdminCalTime3 := (t3 != "") ? t3 : "14:00"
    SSOK_AdminCalTime4 := (t4 != "") ? t4 : "16:30"

    SSOK_AdminCalLoaded := true
}

SSOK_AdminCalendar_WriteSettings(enabled, use1, t1, use2, t2, use3, t3, use4, t4, useSeoul := 1, useJeonbuk := 1, useBusan := 1)
{
    ini := SSOK_AdminCalendar_GetIniFile()
    SplitPath, ini,, iniDir
    if (iniDir != "")
        FileCreateDir, %iniDir%

    IniWrite, %enabled%, %ini%, AdminCalendar, Enabled
    IniWrite, %useSeoul%, %ini%, AdminCalendar, UseSeoul
    IniWrite, %useBusan%, %ini%, AdminCalendar, UseBusan
    IniWrite, %useJeonbuk%, %ini%, AdminCalendar, UseJeonbuk

    IniWrite, %use1%, %ini%, AdminCalendar, Use1
    IniWrite, %t1%, %ini%, AdminCalendar, Time1

    IniWrite, %use2%, %ini%, AdminCalendar, Use2
    IniWrite, %t2%, %ini%, AdminCalendar, Time2

    IniWrite, %use3%, %ini%, AdminCalendar, Use3
    IniWrite, %t3%, %ini%, AdminCalendar, Time3

    IniWrite, %use4%, %ini%, AdminCalendar, Use4
    IniWrite, %t4%, %ini%, AdminCalendar, Time4

    IniWrite, 2, %ini%, AdminCalendar, PresetVersion
}

SSOK_AdminCalendar_GetIniFile()
{
    global SSOK_IniFile

    if (SSOK_IniFile != "")
        return SSOK_IniFile

    return A_ScriptDir . "\ssok.ini"
}

SSOK_AdminCalendar_NormalizeTime(value)
{
    s := Trim(value . "")

    if RegExMatch(s, "^(\d{1,2})\s*[:½Ã]\s*(\d{1,2})", m)
    {
        h := m1 + 0
        mi := m2 + 0
    }
    else
    {
        digits := RegExReplace(s, "\D", "")

        if (StrLen(digits) = 3)
        {
            h := SubStr(digits, 1, 1) + 0
            mi := SubStr(digits, 2, 2) + 0
        }
        else if (StrLen(digits) = 4)
        {
            h := SubStr(digits, 1, 2) + 0
            mi := SubStr(digits, 3, 2) + 0
        }
        else
            return ""
    }

    if (h > 23 || mi > 59)
        return ""

    return Format("{:02}:{:02}", h, mi)
}

SSOK_AdminCalendar_UpdateMenuText()
{
    ; ¾÷¹«¿ë µµ±¸ ¹öÆ°Àº »óÅÂÇ¥½Ã°¡ ¾Æ´Ï¶ó Ç×»ó 'ÇàÁ¤¾÷¹«´Þ·Â' Á÷Á¢ ½ÇÇà ¹öÆ°ÀÔ´Ï´Ù.
    GuiControl, SSOKWorkTools:, SSOK_WorkTools_AdminCalendar, ÇàÁ¤¾÷¹«´Þ·Â
}

SSOK_AdminCalendar_CheckNow()
{
    global SSOK_AdminCalEnabled
    global SSOK_AdminCalUse1, SSOK_AdminCalUse2, SSOK_AdminCalUse3, SSOK_AdminCalUse4
    global SSOK_AdminCalTime1, SSOK_AdminCalTime2, SSOK_AdminCalTime3, SSOK_AdminCalTime4
    global SSOK_AdminCalLastShownKey

    SSOK_AdminCalendar_LoadSettings()

    if (!SSOK_AdminCalEnabled)
        return

    now := Format("{:02}:{:02}", A_Hour + 0, A_Min + 0)
    nowMinutes := (A_Hour + 0) * 60 + (A_Min + 0)
    todayKey := A_YYYY . A_MM . A_DD
    ini := SSOK_AdminCalendar_GetIniFile()

    ; ¿ÀÀü 07:00~09:30 »çÀÌ¿¡´Â PC/ÇÁ·Î±×·¥ÀÌ Ã³À½ ÄÑÁø ½ÃÁ¡¿¡ ¿À´Ã ÀÏÁ¤À» ÇÏ·ç 1È¸¸¸ Ç¥½ÃÇÕ´Ï´Ù.
    ; ½ºÅ©¸³Æ®°¡ ´Ù½Ã ½ÇÇàµÇ¾îµµ °°Àº ³¯¿¡´Â Áßº¹ Ç¥½ÃµÇÁö ¾Êµµ·Ï ³¯Â¥¸¦ INI¿¡ ÀúÀåÇÕ´Ï´Ù.
    if (nowMinutes >= 420 && nowMinutes <= 570)
    {
        IniRead, morningShownDate, %ini%, AdminCalendar, MorningStartupShownDate,
        if (morningShownDate != todayKey)
        {
            IniWrite, %todayKey%, %ini%, AdminCalendar, MorningStartupShownDate
            SSOK_AdminCalLastShownKey := todayKey . "|MORNING"
            SSOK_AdminCalendar_ShowTodayPopup(false)
            return
        }
    }

    ; ¿ÀÀü ÃÖÃÊ Ç¥½Ã¸¦ »ç¿ëÇÏ¹Ç·Î ±âÁ¸ 09:00 ¿¹¾àÀº Áßº¹À¸·Î ¶ç¿ìÁö ¾Ê½À´Ï´Ù.
    if (now = "09:00")
        return

    ; Åð±Ù ½Ã°¢ 16:30¿¡´Â ³»ÀÏÀÇ ¾÷¹« ÀÏÁ¤À» ÇÏ·ç 1È¸ Ç¥½ÃÇÏ°í 5ÃÊ µÚ ÀÚµ¿À¸·Î ´Ý½À´Ï´Ù.
    if (now = "16:30")
    {
        IniRead, eveningShownDate, %ini%, AdminCalendar, TomorrowPopupShownDate,
        if (eveningShownDate != todayKey)
        {
            IniWrite, %todayKey%, %ini%, AdminCalendar, TomorrowPopupShownDate
            tomorrowTs := todayKey . "000000"
            EnvAdd, tomorrowTs, 1, Days
            tomorrowYmd := SubStr(tomorrowTs, 1, 8)
            SSOK_AdminCalLastShownKey := todayKey . "|16:30-TOMORROW"
            SSOK_AdminCalendar_ShowDatePopup(tomorrowYmd, false, 5000)
        }
        return
    }

    matched := false

    if (SSOK_AdminCalUse1 && now = SSOK_AdminCalTime1)
        matched := true
    else if (SSOK_AdminCalUse2 && now = SSOK_AdminCalTime2)
        matched := true
    else if (SSOK_AdminCalUse3 && now = SSOK_AdminCalTime3)
        matched := true
    else if (SSOK_AdminCalUse4 && now = SSOK_AdminCalTime4)
        matched := true

    if (!matched)
        return

    key := todayKey . "|" . now

    if (SSOK_AdminCalLastShownKey = key)
        return

    SSOK_AdminCalLastShownKey := key
    SSOK_AdminCalendar_ShowTodayPopup(false)
}

SSOK_AdminCalendar_ShowTodayPopup(manual := false)
{
    todayYmd := A_YYYY . A_MM . A_DD
    SSOK_AdminCalendar_ShowDatePopup(todayYmd, manual)
}

SSOK_AdminCalendar_ShowDatePopup(targetYmd := "", manual := false, autoHideMs := 0)
{
    global SSOK_AdminCalSelectedDate

    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := A_YYYY . A_MM . A_DD

    SSOK_AdminCalSelectedDate := targetYmd
    result := SSOK_AdminCalendar_GetScheduleForDate(targetYmd)

    y := SubStr(targetYmd, 1, 4) + 0
    m := SubStr(targetYmd, 5, 2) + 0
    d := SubStr(targetYmd, 7, 2) + 0
    todayYmd := A_YYYY . A_MM . A_DD
    tomorrowTs := todayYmd . "000000"
    EnvAdd, tomorrowTs, 1, Days
    tomorrowYmd := SubStr(tomorrowTs, 1, 8)

    if (targetYmd = todayYmd)
        title := "¿À´ÃÀÇ ±³À°ÇàÁ¤ ¾÷¹« ÀÏÁ¤"
    else if (targetYmd = tomorrowYmd)
        title := "³»ÀÏÀÇ ±³À°ÇàÁ¤ ¾÷¹« ÀÏÁ¤"
    else
        title := m . "¿ù " . d . "ÀÏ ±³À°ÇàÁ¤ ¾÷¹« ÀÏÁ¤"

    ; ¼±ÅÃÇÑ ³¯Â¥°¡ ¼ÓÇÑ ÁÖÀÇ ÇÐ»çÀÏÁ¤ + ¼±ÅÃÇÑ ³¯Â¥ÀÇ ±Þ½ÄÀ» ÇÔ²² Á¶È¸ÇÕ´Ï´Ù.
    schoolWeek := SSOK_AdminCalendar_GetMySchoolWeekScheduleForDate(targetYmd)
    schoolLine := IsObject(schoolWeek) ? schoolWeek.text : ""
    schoolMeal := SSOK_AdminCalendar_GetMySchoolMealsForDate(targetYmd)
    mealLine := IsObject(schoolMeal) ? schoolMeal.text : ""

    ; ÇÑ È­¸é¿¡´Â ¼±ÅÃÇÑ ³¯Â¥ 1ÀÏÄ¡¸¸ Ç¥½Ã: ¼­¿ï / ºÎ»ê / ÀüºÏ 3Ä­.
    seoulEvents := (IsObject(result) && IsObject(result.seoulEvents)) ? result.seoulEvents : []
    jeonbukEvents := (IsObject(result) && IsObject(result.jeonbukEvents)) ? result.jeonbukEvents : []
    SSOK_AdminCalendar_ShowPopupColumns(title, seoulEvents, jeonbukEvents, schoolLine, mealLine, targetYmd, result.seoulError, result.jeonbukError, autoHideMs, result.busanEvents, result.busanError)
}

SSOK_AdminCalendar_ShiftSelectedDate(deltaDays)
{
    global SSOK_AdminCalSelectedDate

    ymd := SSOK_AdminCalSelectedDate
    if !RegExMatch(ymd, "^\d{8}$")
        ymd := A_YYYY . A_MM . A_DD

    ts := ymd . "000000"
    EnvAdd, ts, %deltaDays%, Days
    SSOK_AdminCalendar_ShowDatePopup(SubStr(ts, 1, 8), true)
}

SSOK_AdminCalendar_ShowPopup(title, body, duration := 8500)
{
    global SSOK_AdminCalPopupHwnd

    Gui, SSOKAdminCalPopup:Destroy
    Gui, SSOKAdminCalPopup:New, +AlwaysOnTop -Caption +ToolWindow +Border +HwndSSOK_AdminCalPopupHwnd
    Gui, SSOKAdminCalPopup:Color, FFF8D8
    Gui, SSOKAdminCalPopup:Margin, 22, 16

    ; ¿À·ù/¾È³» ÆË¾÷µµ ±âº» Å©±â ±Û²ÃÀ» »ç¿ëÇÕ´Ï´Ù.
    Gui, SSOKAdminCalPopup:Font, s9 Bold, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, w620 h24 Center, %title%
    Gui, SSOKAdminCalPopup:Font, s9 Normal, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, y+8 w620 Center, %body%
    Gui, SSOKAdminCalPopup:Add, Button, x272 y+16 w120 h30 gSSOK_AdminCalendar_PopupHide, È®ÀÎ

    SysGet, SSOK_AdminWork, MonitorWorkArea
    workLeft := SSOK_AdminWorkLeft
    workRight := SSOK_AdminWorkRight
    workTop := SSOK_AdminWorkTop
    if (workLeft = "")
        workLeft := 0
    if (workRight = "" || workRight <= workLeft)
        workRight := A_ScreenWidth
    if (workTop = "")
        workTop := 0

    popupOuterW := 664
    popupX := workLeft + ((workRight - workLeft - popupOuterW) // 2)
    popupY := workTop + 28
    if (popupX < workLeft)
        popupX := workLeft
    if (popupY < workTop)
        popupY := workTop

    SetTimer, SSOK_AdminCalendar_PopupHide, Off
    Gui, SSOKAdminCalPopup:Show, x%popupX% y%popupY% AutoSize NoActivate, %title%
}

SSOK_AdminCalendar_ShowSchoolOnlyPopup(title, schoolLine, mealLine := "")
{
    global SSOK_AdminCalPopupHwnd, SSOK_AdminCalSchoolBody

    schoolDisplay := Trim(schoolLine)
    mealDisplay := Trim(mealLine)
    if (schoolDisplay = "" && mealDisplay = "")
        return

    Gui, SSOKAdminCalPopup:Destroy
    Gui, SSOKAdminCalPopup:New, +AlwaysOnTop -Caption +ToolWindow +Border +HwndSSOK_AdminCalPopupHwnd
    Gui, SSOKAdminCalPopup:Color, FFF8D8
    Gui, SSOKAdminCalPopup:Margin, 18, 12

    ; °¡·ÎÆøÀº À¯ÁöÇÏ°í, º»¹® ±Û²ÃÀº ÁÖ°£ÀÏÁ¤ ±âÁØ 8pt·Î ÅëÀÏ
    Gui, SSOKAdminCalPopup:Font, s8 Bold, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, x20 y13 w920 h22 Center, %title%

    nextY := 45
    if (schoolDisplay != "")
    {
        Gui, SSOKAdminCalPopup:Font, s8 Bold c30445A, Malgun Gothic
        Gui, SSOKAdminCalPopup:Add, Text, x24 y%nextY% w910 vSSOK_AdminCalSchoolBody Left, %schoolDisplay%
        GuiControlGet, schoolPos, Pos, SSOK_AdminCalSchoolBody
        schoolH := schoolPosH
        if (schoolH < 18)
            schoolH := 18
        nextY += schoolH + 4
    }

    ; Á¶½Ä/Áß½Ä/¼®½ÄÀº ¶óº§°ú ³»¿ëÀ» ºÐ¸®ÇØ ÁÙ¹Ù²ÞµÇ¾îµµ ³»¿ë ½ÃÀÛÁ¡¿¡ ¸ÂÃç µé¿©¾²±â
    if (mealDisplay != "")
        nextY := SSOK_AdminCalendar_AddMealRows(mealDisplay, 24, nextY, 910)

    buttonY := nextY + 4
    Gui, SSOKAdminCalPopup:Add, Button, x420 y%buttonY% w120 h28 gSSOK_AdminCalendar_PopupHide, È®ÀÎ
    linkY := buttonY + 4
    Gui, SSOKAdminCalPopup:Font, s8 underline c0066CC, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, x550 y%linkY% w135 h20 +0x200 Center gSSOK_AdminCalendar_OpenMealInfo, ½Ä´ÜÁ¤º¸ ¹Ù·Î°¡±â
    Gui, SSOKAdminCalPopup:Add, Text, x690 y%linkY% w135 h20 +0x200 Center gSSOK_AdminCalendar_OpenScheduleInfo, ÇÐ»çÁ¤º¸ ¹Ù·Î°¡±â
    Gui, SSOKAdminCalPopup:Font, s7 underline c666666, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, x875 y%linkY% w60 h20 +0x200 Center gSSOK_AdminCalendar_OpenSettings, ¼³Á¤

    SysGet, SSOK_AdminWork, MonitorWorkArea
    workLeft := SSOK_AdminWorkLeft
    workRight := SSOK_AdminWorkRight
    workTop := SSOK_AdminWorkTop
    if (workLeft = "")
        workLeft := 0
    if (workRight = "" || workRight <= workLeft)
        workRight := A_ScreenWidth
    if (workTop = "")
        workTop := 0

    popupOuterW := 960
    popupX := workLeft + ((workRight - workLeft - popupOuterW) // 2)
    popupY := workTop + 24
    if (popupX < workLeft)
        popupX := workLeft
    if (popupY < workTop)
        popupY := workTop

    SetTimer, SSOK_AdminCalendar_PopupHide, Off
    Gui, SSOKAdminCalPopup:Show, x%popupX% y%popupY% AutoSize NoActivate, %title%
}

SSOK_AdminCalendar_ShowPopupColumns(title, seoulEvents, jeonbukEvents, schoolLine := "", mealLine := "", targetYmd := "", seoulError := "", jeonbukError := "", autoHideMs := 0, busanEvents := "", busanError := "")
{
    global SSOK_AdminCalPopupHwnd, SSOK_AdminCalSeoulBody, SSOK_AdminCalBusanBody, SSOK_AdminCalJeonbukBody
    global SSOK_AdminCalSchoolBody, SSOK_AdminCalSelectedDate, SSOK_AdminCalDatePick

    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := (RegExMatch(SSOK_AdminCalSelectedDate, "^\d{8}$") ? SSOK_AdminCalSelectedDate : A_YYYY . A_MM . A_DD)
    SSOK_AdminCalSelectedDate := targetYmd

    seoulText := SSOK_AdminCalendar_FormatEventsAll(seoulEvents)
    busanText := SSOK_AdminCalendar_FormatEventsAll(busanEvents)
    if (busanError != "")
        busanText := "Á¶È¸ ½ÇÆÐ: " . busanError
    jeonbukText := SSOK_AdminCalendar_FormatEventsAll(jeonbukEvents)
    if (seoulError != "")
        seoulText := "Á¶È¸ ½ÇÆÐ: " . seoulError
    if (jeonbukError != "")
        jeonbukText := "Á¶È¸ ½ÇÆÐ: " . jeonbukError
    schoolDisplay := Trim(schoolLine)
    mealDisplay := Trim(mealLine)

    ; ÀÏÁ¤ÀÌ ¾ø´Â Áö¿ªÀº 'ÀÏÁ¤ ¾øÀ½'À» ¾²Áö ¾Ê°í ºóÄ­À¸·Î µÓ´Ï´Ù.
    seoulDisplay := (seoulText = "" ? " " : seoulText)
    busanDisplay := (busanText = "" ? " " : busanText)
    jeonbukDisplay := (jeonbukText = "" ? " " : jeonbukText)

    Gui, SSOKAdminCalPopup:Destroy
    Gui, SSOKAdminCalPopup:New, +AlwaysOnTop -Caption +ToolWindow +Border +HwndSSOK_AdminCalPopupHwnd
    Gui, SSOKAdminCalPopup:Color, FFF8D8
    Gui, SSOKAdminCalPopup:Margin, 18, 12

    ; Á¦¸ñ: ¼±ÅÃÇÑ ³¯Â¥¸¦ Ç¥½ÃÇÕ´Ï´Ù. Ã³À½ ¿­ ¶§´Â ¿À´Ã ³¯Â¥ÀÔ´Ï´Ù.
    Gui, SSOKAdminCalPopup:Font, s8 Bold, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, x20 y10 w920 h22 Center, %title%

    ; ³¯Â¥ ¼±ÅÃ: ÀÌÀü³¯ / Á÷Á¢ ¼±ÅÃ / ´ÙÀ½³¯ / ¿À´Ã
    chooseDate := targetYmd . "000000"
    Gui, SSOKAdminCalPopup:Font, s8 Normal c222222, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Button, x304 y36 w34 h25 gSSOK_AdminCalendar_DatePrev, <
    Gui, SSOKAdminCalPopup:Font, s10 Normal c222222, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, DateTime, x346 y34 w190 h29 vSSOK_AdminCalDatePick gSSOK_AdminCalendar_DatePickChanged Choose%chooseDate%, yyyy-MM-dd dddd
    Gui, SSOKAdminCalPopup:Font, s8 Normal c222222, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Button, x544 y36 w34 h25 gSSOK_AdminCalendar_DateNext, >
    Gui, SSOKAdminCalPopup:Add, Button, x588 y36 w58 h25 gSSOK_AdminCalendar_DateToday, ¿À´Ã

    ; ¼±ÅÃÇÑ ³¯Â¥ÀÇ ¼­¿ï/ºÎ»ê/ÀüºÏ ÀÏÁ¤Àº Ç×»ó 3Ä­¸¸ »ç¿ëÇÕ´Ï´Ù.
    ; ÇØ´ç Áö¿ª¿¡ Ç¥½ÃÇÒ ÀÏÁ¤(¶Ç´Â Á¶È¸ ¿À·ù)ÀÌ ÀÖÀ» ¶§¸¸ Áö¿ª¸íÀ» Ç¥½ÃÇÕ´Ï´Ù.
    Gui, SSOKAdminCalPopup:Font, s7 Bold c555555, Malgun Gothic
    if (Trim(seoulText) != "")
        Gui, SSOKAdminCalPopup:Add, Text, x24 y70 w286 h18 Left, ¼­¿ï
    if (Trim(busanText) != "")
        Gui, SSOKAdminCalPopup:Add, Text, x338 y70 w286 h18 Left, ºÎ»ê
    if (Trim(jeonbukText) != "")
        Gui, SSOKAdminCalPopup:Add, Text, x654 y70 w286 h18 Left, ÀüºÏ

    bodyY := 91
    Gui, SSOKAdminCalPopup:Font, s8 Normal c000000, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, x24 y%bodyY% w286 +0x80 Left vSSOK_AdminCalSeoulBody, %seoulDisplay%
    Gui, SSOKAdminCalPopup:Add, Text, x338 y%bodyY% w286 +0x80 Left vSSOK_AdminCalBusanBody, %busanDisplay%
    Gui, SSOKAdminCalPopup:Add, Text, x654 y%bodyY% w286 +0x80 Left vSSOK_AdminCalJeonbukBody, %jeonbukDisplay%

    GuiControlGet, seoulPos, Pos, SSOK_AdminCalSeoulBody
    GuiControlGet, jeonbukPos, Pos, SSOK_AdminCalJeonbukBody
    GuiControlGet, busanPos, Pos, SSOK_AdminCalBusanBody
    contentH := Max(seoulPosH, busanPosH, jeonbukPosH)
    if (contentH < 18)
        contentH := 18

    ; ¼¼·Î ±¸ºÐ¼±Àº ¼­¿ï/ºÎ»ê/ÀüºÏ ÀÏÁ¤ ¿µ¿ª±îÁö¸¸ Ç¥½ÃÇÕ´Ï´Ù.
    sepY := 68
    sepH := bodyY + contentH - sepY + 2
    Gui, SSOKAdminCalPopup:Add, Progress, x322 y%sepY% w1 h%sepH% cE8E3D3 BackgroundE8E3D3, 100
    Gui, SSOKAdminCalPopup:Add, Progress, x638 y%sepY% w1 h%sepH% cE8E3D3 BackgroundE8E3D3, 100

    nextY := bodyY + contentH + 7

    ; ¼­¿ï/ºÎ»ê/ÀüºÏ ÇàÁ¤ÀÏÁ¤°ú ¿ì¸®ÇÐ±³ ÁÖ°£ÀÏÁ¤/±Þ½ÄÀ» °¡·Î¼±À¸·Î ±¸ºÐ
    Gui, SSOKAdminCalPopup:Add, Progress, x24 y%nextY% w916 h1 cD7D1C1 BackgroundD7D1C1, 100
    nextY += 8

    ; ¼±ÅÃÇÑ ³¯Â¥°¡ ¼ÓÇÑ ÁÖÀÇ ÇÐ±³ ÇÐ»çÀÏÁ¤
    if (schoolDisplay != "")
    {
        Gui, SSOKAdminCalPopup:Font, s8 Bold c30445A, Malgun Gothic
        Gui, SSOKAdminCalPopup:Add, Text, x24 y%nextY% w916 vSSOK_AdminCalSchoolBody Left, %schoolDisplay%
        GuiControlGet, schoolPos, Pos, SSOK_AdminCalSchoolBody
        schoolH := schoolPosH
        if (schoolH < 18)
            schoolH := 18
        nextY += schoolH + 3
    }

    ; ¼±ÅÃÇÑ ³¯Â¥ÀÇ Á¶½Ä/Áß½Ä/¼®½Ä
    if (mealDisplay != "")
        nextY := SSOK_AdminCalendar_AddMealRows(mealDisplay, 24, nextY, 916)

    buttonY := nextY + 3
    Gui, SSOKAdminCalPopup:Font, s8 Normal c000000, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Button, x420 y%buttonY% w120 h28 gSSOK_AdminCalendar_PopupHide, È®ÀÎ
    linkY := buttonY + 4
    Gui, SSOKAdminCalPopup:Font, s8 underline c0066CC, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, x550 y%linkY% w135 h20 +0x200 Center gSSOK_AdminCalendar_OpenMealInfo, ½Ä´ÜÁ¤º¸ ¹Ù·Î°¡±â
    Gui, SSOKAdminCalPopup:Add, Text, x690 y%linkY% w135 h20 +0x200 Center gSSOK_AdminCalendar_OpenScheduleInfo, ÇÐ»çÁ¤º¸ ¹Ù·Î°¡±â
    Gui, SSOKAdminCalPopup:Font, s7 underline c666666, Malgun Gothic
    Gui, SSOKAdminCalPopup:Add, Text, x875 y%linkY% w60 h20 +0x200 Center gSSOK_AdminCalendar_OpenSettings, ¼³Á¤

    SysGet, SSOK_AdminWork, MonitorWorkArea
    workLeft := SSOK_AdminWorkLeft
    workRight := SSOK_AdminWorkRight
    workTop := SSOK_AdminWorkTop
    if (workLeft = "")
        workLeft := 0
    if (workRight = "" || workRight <= workLeft)
        workRight := A_ScreenWidth
    if (workTop = "")
        workTop := 0

    popupOuterW := 960
    popupX := workLeft + ((workRight - workLeft - popupOuterW) // 2)
    popupY := workTop + 24
    if (popupX < workLeft)
        popupX := workLeft
    if (popupY < workTop)
        popupY := workTop

    SetTimer, SSOK_AdminCalendar_PopupHide, Off
    Gui, SSOKAdminCalPopup:Show, x%popupX% y%popupY% AutoSize NoActivate, %title%
    if (autoHideMs > 0)
    {
        hideDelay := -Abs(autoHideMs)
        SetTimer, SSOK_AdminCalendar_PopupHide, %hideDelay%
    }
}

; ±Þ½Ä ÇàÀ» "Á¶½Ä:/Áß½Ä:/¼®½Ä:" ¶óº§°ú ³»¿ëÀ¸·Î ³ª´² ±×¸³´Ï´Ù.
; ³»¿ëÀÌ µÎ ÁÙ ÀÌ»óÀ¸·Î ³»·Á°¡µµ Ã¹ ÁÙÀÇ ¸Þ´º ½ÃÀÛ À§Ä¡¿¡ ¸ÂÃç ÀÚµ¿ µé¿©¾²±âµË´Ï´Ù.
SSOK_AdminCalendar_AddMealRows(mealDisplay, x, y, totalW)
{
    lines := StrSplit(StrReplace(mealDisplay, "`r", ""), "`n")
    labelW := 38
    gap := 5
    bodyX := x + labelW + gap
    bodyW := totalW - labelW - gap

    Gui, SSOKAdminCalPopup:Font, s8 Normal c30445A, Malgun Gothic

    for _, rawLine in lines
    {
        line := Trim(rawLine)
        if (line = "")
            continue

        colonPos := InStr(line, ":")
        if (colonPos > 0)
        {
            label := Trim(SubStr(line, 1, colonPos))
            body := Trim(SubStr(line, colonPos + 1))
        }
        else
        {
            label := ""
            body := line
        }

        if (label != "")
        {
            Gui, SSOKAdminCalPopup:Font, s8 Bold c30445A, Malgun Gothic
            Gui, SSOKAdminCalPopup:Add, Text, x%x% y%y% w%labelW% h18 Left, %label%
        }

        Gui, SSOKAdminCalPopup:Font, s8 Normal c30445A, Malgun Gothic
        Gui, SSOKAdminCalPopup:Add, Text, x%bodyX% y%y% w%bodyW% hwndhMealBody Left, %body%
        GuiControlGet, mealPos, Pos, %hMealBody%
        rowH := mealPosH
        if (rowH < 18)
            rowH := 18
        y += rowH + 2
    }

    return y + 2
}
SSOK_AdminCalendar_GetTodaySchedule()
{
    todayYmd := A_YYYY . A_MM . A_DD
    return SSOK_AdminCalendar_GetScheduleForDate(todayYmd)
}

SSOK_AdminCalendar_GetScheduleForDate(targetYmd)
{
    global SSOK_AdminCalLoaded, SSOK_AdminCalUseSeoul, SSOK_AdminCalUseBusan, SSOK_AdminCalUseJeonbuk
    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := A_YYYY . A_MM . A_DD
    results := {}, merged := [], seen := {}
    for _, region in [{code:"S", enabled:SSOK_AdminCalUseSeoul}, {code:"B", enabled:SSOK_AdminCalUseBusan}, {code:"J", enabled:SSOK_AdminCalUseJeonbuk}]
    {
        result := {ok:false, events:[], error:""}
        if (!SSOK_AdminCalLoaded || region.enabled)
        {
            html := SSOK_AdminCalendar_DownloadMonth(region.code, targetYmd, error)
            if (html = "")
                result.error := error
            else if (region.code = "S")
                result := SSOK_AdminCalendar_ParseDateSeoul(html, targetYmd)
            else if (region.code = "B")
                result := SSOK_AdminCalendar_ParseDateBusan(html, targetYmd)
            else
                result := SSOK_AdminCalendar_ParseDate(html, targetYmd)
        }
        results[region.code] := result
        SSOK_AdminCalendar_MergeEvents(merged, seen, result.events)
    }
    return {ok:results.S.ok || results.B.ok || results.J.ok, text:SSOK_AdminCalendar_FormatEvents(merged), count:merged.Length()
        , events:merged, seoulEvents:results.S.events, busanEvents:results.B.events, jeonbukEvents:results.J.events
        , seoulError:results.S.error, busanError:results.B.error, jeonbukError:results.J.error}
}

; =========================================================
; ÇàÁ¤¾÷¹« ´Þ·Â -> SSOK ±³À°Á¤º¸ -> ¿ì¸®ÇÐ±³ ½Ä´ÜÁ¤º¸ ¹Ù·Î°¡±â
; - [MySchool]¿¡ ÀúÀåµÈ ÇÐ±³¸¦ ¿ì¼± »ç¿ë
; - ÇÐ±³ÄÚµå°¡ ¾øÀ¸¸é ¸ÞÀÎ ±â°ü¸íÀ» Á¤È®È÷ °Ë»öÇÏ¿© ÀÚµ¿ ¿¬°á
; - SSOK º»Ã¼ÀÇ ±³À°Á¤º¸ Ã¢À» ¿­°í '½Ä´ÜÁ¤º¸' ÅÇ(2¹ø)À» ¹Ù·Î ¼±ÅÃ
; =========================================================
SSOK_AdminCalendar_OpenMySchoolMealInfo()
{
    ini := SSOK_AdminCalendar_GetIniFile()

    IniRead, orgName, %ini%, MajorTodos, OrgName, __SSOK_EMPTY__
    IniRead, schoolName, %ini%, MySchool, Name, __SSOK_EMPTY__
    IniRead, officeCode, %ini%, MySchool, OfficeCode, __SSOK_EMPTY__
    IniRead, schoolCode, %ini%, MySchool, SchoolCode, __SSOK_EMPTY__
    IniRead, officeName, %ini%, MySchool, OfficeName, __SSOK_EMPTY__
    IniRead, schoolKind, %ini%, MySchool, SchoolKind, __SSOK_EMPTY__
    IniRead, supportOffice, %ini%, MySchool, SupportOffice, __SSOK_EMPTY__
    IniRead, schoolAddress, %ini%, MySchool, Address, __SSOK_EMPTY__

    orgName := Trim(orgName)
    schoolName := Trim(schoolName)
    officeCode := Trim(officeCode)
    schoolCode := Trim(schoolCode)
    officeName := Trim(officeName)
    schoolKind := Trim(schoolKind)
    supportOffice := Trim(supportOffice)
    schoolAddress := Trim(schoolAddress)

    needResolve := (schoolName = "" || schoolName = "__SSOK_EMPTY__"
        || officeCode = "" || officeCode = "__SSOK_EMPTY__"
        || schoolCode = "" || schoolCode = "__SSOK_EMPTY__")

    if (!needResolve && orgName != "" && orgName != "__SSOK_EMPTY__" && schoolName != orgName)
        needResolve := true

    if (needResolve)
    {
        if (orgName = "" || orgName = "__SSOK_EMPTY__")
        {
            MsgBox, 48, SSOK ¾È³», ¸ÞÀÎ È­¸éÀÇ ±â°ü¸íÀ» ¸ÕÀú ¼³Á¤ÇØ ÁÖ¼¼¿ä.
            return false
        }

        exact := SSOK_AdminCalendar_FindExactSchool(orgName)
        cnt := IsObject(exact) ? exact.Length() : 0
        if (cnt != 1)
        {
            MsgBox, 48, SSOK ¾È³», ÇöÀç ±â°ü¸í°ú Á¤È®È÷ ÀÏÄ¡ÇÏ´Â ÇÐ±³¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`n`n±â°ü¸í: %orgName%
            return false
        }

        school := exact[1]
        schoolName := school.schoolName
        officeCode := school.officeCode
        schoolCode := school.schoolCode
        officeName := school.officeName
        schoolKind := school.kind
        supportOffice := school.parentOrg
        schoolAddress := school.address

        IniWrite, %schoolName%, %ini%, MySchool, Name
        IniWrite, %officeCode%, %ini%, MySchool, OfficeCode
        IniWrite, %schoolCode%, %ini%, MySchool, SchoolCode
        IniWrite, %officeName%, %ini%, MySchool, OfficeName
        IniWrite, %schoolKind%, %ini%, MySchool, SchoolKind
        IniWrite, %supportOffice%, %ini%, MySchool, SupportOffice
        IniWrite, %schoolAddress%, %ini%, MySchool, Address
    }

    if (!IsFunc("SSOK_EDU_OpenSchool"))
    {
        MsgBox, 48, SSOK ¾È³», ÀÌ ¹Ù·Î°¡±â´Â SSOK º»Ã¼ÀÇ [±³À°Á¤º¸] ±â´É°ú ÇÔ²² »ç¿ëÇÒ ¶§ µ¿ÀÛÇÕ´Ï´Ù.
        return false
    }

    school := {schoolName:schoolName
             , officeCode:officeCode
             , schoolCode:schoolCode
             , officeName:(officeName = "__SSOK_EMPTY__" ? "" : officeName)
             , kind:(schoolKind = "__SSOK_EMPTY__" ? "" : schoolKind)
             , parentOrg:(supportOffice = "__SSOK_EMPTY__" ? "" : supportOffice)
             , address:(schoolAddress = "__SSOK_EMPTY__" ? "" : schoolAddress)
             , homepage:""}

    fn := Func("SSOK_EDU_OpenSchool")
    fn.Call(school)

    ; SSOK ±³À°Á¤º¸ Ã¢ÀÌ ¸¸µé¾îÁø µÚ µÎ ¹øÂ° ÅÇÀÎ '½Ä´ÜÁ¤º¸'¸¦ ¼±ÅÃÇÕ´Ï´Ù.
    GuiControl, SSOKEDU:Choose, SSOK_EDU_Tab, 2
    if (IsFunc("SSOK_EDU_LoadMeal"))
    {
        fnMeal := Func("SSOK_EDU_LoadMeal")
        fnMeal.Call()
    }
    return true
}

; =========================================================
; ÇàÁ¤¾÷¹« ´Þ·Â -> SSOK ±³À°Á¤º¸ -> ¿ì¸®ÇÐ±³ ÇÐ»çÁ¤º¸ ¹Ù·Î°¡±â
; - [MySchool]¿¡ ÀúÀåµÈ ÇÐ±³¸¦ ¿ì¼± »ç¿ë
; - ÇÐ±³ÄÚµå°¡ ¾øÀ¸¸é ¸ÞÀÎ ±â°ü¸íÀ» Á¤È®È÷ °Ë»öÇÏ¿© ÀÚµ¿ ¿¬°á
; - SSOK º»Ã¼ÀÇ ±³À°Á¤º¸ Ã¢À» ¿­°í 'ÇÐ»çÀÏÁ¤' ÅÇ(4¹ø)À» ¹Ù·Î ¼±ÅÃ
; =========================================================
SSOK_AdminCalendar_OpenMySchoolScheduleInfo()
{
    ini := SSOK_AdminCalendar_GetIniFile()

    IniRead, orgName, %ini%, MajorTodos, OrgName, __SSOK_EMPTY__
    IniRead, schoolName, %ini%, MySchool, Name, __SSOK_EMPTY__
    IniRead, officeCode, %ini%, MySchool, OfficeCode, __SSOK_EMPTY__
    IniRead, schoolCode, %ini%, MySchool, SchoolCode, __SSOK_EMPTY__
    IniRead, officeName, %ini%, MySchool, OfficeName, __SSOK_EMPTY__
    IniRead, schoolKind, %ini%, MySchool, SchoolKind, __SSOK_EMPTY__
    IniRead, supportOffice, %ini%, MySchool, SupportOffice, __SSOK_EMPTY__
    IniRead, schoolAddress, %ini%, MySchool, Address, __SSOK_EMPTY__

    orgName := Trim(orgName)
    schoolName := Trim(schoolName)
    officeCode := Trim(officeCode)
    schoolCode := Trim(schoolCode)
    officeName := Trim(officeName)
    schoolKind := Trim(schoolKind)
    supportOffice := Trim(supportOffice)
    schoolAddress := Trim(schoolAddress)

    needResolve := (schoolName = "" || schoolName = "__SSOK_EMPTY__"
        || officeCode = "" || officeCode = "__SSOK_EMPTY__"
        || schoolCode = "" || schoolCode = "__SSOK_EMPTY__")

    if (!needResolve && orgName != "" && orgName != "__SSOK_EMPTY__" && schoolName != orgName)
        needResolve := true

    if (needResolve)
    {
        if (orgName = "" || orgName = "__SSOK_EMPTY__")
        {
            MsgBox, 48, SSOK ¾È³», ¸ÞÀÎ È­¸éÀÇ ±â°ü¸íÀ» ¸ÕÀú ¼³Á¤ÇØ ÁÖ¼¼¿ä.
            return false
        }

        exact := SSOK_AdminCalendar_FindExactSchool(orgName)
        cnt := IsObject(exact) ? exact.Length() : 0
        if (cnt != 1)
        {
            MsgBox, 48, SSOK ¾È³», ÇöÀç ±â°ü¸í°ú Á¤È®È÷ ÀÏÄ¡ÇÏ´Â ÇÐ±³¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`n`n±â°ü¸í: %orgName%
            return false
        }

        school := exact[1]
        schoolName := school.schoolName
        officeCode := school.officeCode
        schoolCode := school.schoolCode
        officeName := school.officeName
        schoolKind := school.kind
        supportOffice := school.parentOrg
        schoolAddress := school.address

        IniWrite, %schoolName%, %ini%, MySchool, Name
        IniWrite, %officeCode%, %ini%, MySchool, OfficeCode
        IniWrite, %schoolCode%, %ini%, MySchool, SchoolCode
        IniWrite, %officeName%, %ini%, MySchool, OfficeName
        IniWrite, %schoolKind%, %ini%, MySchool, SchoolKind
        IniWrite, %supportOffice%, %ini%, MySchool, SupportOffice
        IniWrite, %schoolAddress%, %ini%, MySchool, Address
    }

    if (!IsFunc("SSOK_EDU_OpenSchool"))
    {
        MsgBox, 48, SSOK ¾È³», ÀÌ ¹Ù·Î°¡±â´Â SSOK º»Ã¼ÀÇ [±³À°Á¤º¸] ±â´É°ú ÇÔ²² »ç¿ëÇÒ ¶§ µ¿ÀÛÇÕ´Ï´Ù.
        return false
    }

    school := {schoolName:schoolName
             , officeCode:officeCode
             , schoolCode:schoolCode
             , officeName:(officeName = "__SSOK_EMPTY__" ? "" : officeName)
             , kind:(schoolKind = "__SSOK_EMPTY__" ? "" : schoolKind)
             , parentOrg:(supportOffice = "__SSOK_EMPTY__" ? "" : supportOffice)
             , address:(schoolAddress = "__SSOK_EMPTY__" ? "" : schoolAddress)
             , homepage:""}

    fn := Func("SSOK_EDU_OpenSchool")
    fn.Call(school)

    ; SSOK ±³À°Á¤º¸ Ã¢ÀÌ ¸¸µé¾îÁø µÚ ³× ¹øÂ° ÅÇÀÎ 'ÇÐ»çÀÏÁ¤'À» ¼±ÅÃÇÕ´Ï´Ù.
    GuiControl, SSOKEDU:Choose, SSOK_EDU_Tab, 4
    if (IsFunc("SSOK_EDU_LoadSchedule"))
    {
        fnSchedule := Func("SSOK_EDU_LoadSchedule")
        fnSchedule.Call()
    }
    return true
}

; =========================================================
; ¸ÞÀÎ ±â°ü¸í¿¡ ¿¬°áµÈ ÇÐ±³ÀÇ ±ÝÁÖ(¿ù~ÀÏ) ÇÐ»çÀÏÁ¤ - ³ªÀÌ½º OPEN API
; [MySchool]ÀÇ ±³À°Ã»ÄÚµå/ÇÐ±³ÄÚµå¸¦ ¿ì¼± »ç¿ëÇÏ°í, ¾øÀ» ¶§¸¸ ±â°ü¸íÀ» Á¤È®È÷ °Ë»öÇÕ´Ï´Ù.
; =========================================================
SSOK_AdminCalendar_GetMySchoolWeekSchedule()
{
    todayYmd := A_YYYY . A_MM . A_DD
    return SSOK_AdminCalendar_GetMySchoolWeekScheduleForDate(todayYmd)
}

SSOK_AdminCalendar_GetMySchoolWeekScheduleForDate(targetYmd)
{
    global SSOK_AdminCalSchoolWeekCacheKey, SSOK_AdminCalSchoolWeekCacheText, SSOK_AdminCalSchoolWeekCacheHasEvents

    ini := SSOK_AdminCalendar_GetIniFile()
    IniRead, orgName, %ini%, MajorTodos, OrgName, __SSOK_EMPTY__
    orgName := Trim(orgName)
    if (orgName = "" || orgName = "__SSOK_EMPTY__")
        return {ok:false, text:""}

    IniRead, savedName, %ini%, MySchool, Name, __SSOK_EMPTY__
    IniRead, officeCode, %ini%, MySchool, OfficeCode, __SSOK_EMPTY__
    IniRead, schoolCode, %ini%, MySchool, SchoolCode, __SSOK_EMPTY__
    savedName := Trim(savedName)
    officeCode := Trim(officeCode)
    schoolCode := Trim(schoolCode)

    ; ±â°ü¸íÀÌ ¹Ù²î¾ú°Å³ª ¾ÆÁ÷ ÇÐ±³ÄÚµå°¡ ¾øÀ¸¸é Á¤È®È÷ °°Àº ÇÐ±³¸íÀ» ÇÑ ¹ø ÀÚµ¿ °Ë»öÇÕ´Ï´Ù.
    if (savedName != orgName || officeCode = "" || officeCode = "__SSOK_EMPTY__"
        || schoolCode = "" || schoolCode = "__SSOK_EMPTY__")
    {
        exact := SSOK_AdminCalendar_FindExactSchool(orgName)
        cnt := IsObject(exact) ? exact.Length() : 0
        if (cnt = 1)
        {
            school := exact[1]
            officeCode := school.officeCode
            schoolCode := school.schoolCode
            IniWrite, % school.schoolName, %ini%, MySchool, Name
            IniWrite, % officeCode, %ini%, MySchool, OfficeCode
            IniWrite, % schoolCode, %ini%, MySchool, SchoolCode
            IniWrite, % school.officeName, %ini%, MySchool, OfficeName
            IniWrite, % school.kind, %ini%, MySchool, SchoolKind
            IniWrite, % school.parentOrg, %ini%, MySchool, SupportOffice
            IniWrite, % school.address, %ini%, MySchool, Address
        }
        else if (cnt > 1)
            return {ok:false, text:orgName . ": µ¿¸íÀÌ±³ ¼±ÅÃ ÇÊ¿ä"}
        else
            return {ok:false, text:orgName . ": ³ªÀÌ½º ÇÐ±³Á¤º¸ ¾øÀ½"}
    }

    SSOK_AdminCalendar_GetWeekRangeForDate(targetYmd, weekFrom, weekTo)
    cacheKey := orgName . "|" . officeCode . "|" . schoolCode . "|" . weekFrom
    if (SSOK_AdminCalSchoolWeekCacheKey = cacheKey && SSOK_AdminCalSchoolWeekCacheText != "")
        return {ok:true, text:SSOK_AdminCalSchoolWeekCacheText, hasEvents:SSOK_AdminCalSchoolWeekCacheHasEvents}

    params := Object("ATPT_OFCDC_SC_CODE", officeCode
                   , "SD_SCHUL_CODE", schoolCode
                   , "AA_FROM_YMD", weekFrom
                   , "AA_TO_YMD", weekTo)
    url := SSOK_AdminCalendar_NeisBuildUrl("SchoolSchedule", params, 100)
    resp := SSOK_AdminCalendar_NeisHttpGet(url)

    if (!resp.ok)
        return {ok:false, text:orgName . ": ÇÐ»çÀÏÁ¤ Á¶È¸ ½ÇÆÐ"}

    events := SSOK_AdminCalendar_ParseNeisSchoolSchedule(resp.text)
    hasEvents := IsObject(events) && events.Length() > 0
    if (!hasEvents)
        line := ""
    else
        line := orgName . " ÇÐ»çÀÏÁ¤: " . SSOK_AdminCalendar_FormatSchoolWeekEvents(events)

    SSOK_AdminCalSchoolWeekCacheKey := cacheKey
    SSOK_AdminCalSchoolWeekCacheText := line
    SSOK_AdminCalSchoolWeekCacheHasEvents := hasEvents
    return {ok:true, text:line, hasEvents:hasEvents}
}

; =========================================================
; ¸ÞÀÎ ±â°ü¸í¿¡ ¿¬°áµÈ ÇÐ±³ÀÇ ¿À´Ã ±Þ½Ä - ³ªÀÌ½º OPEN API
; Á¶½Ä/Áß½Ä/¼®½Ä Áß ½ÇÁ¦·Î Á¦°øµÇ´Â ±Þ½Ä¸¸ Ç¥½ÃÇÕ´Ï´Ù.
; =========================================================
SSOK_AdminCalendar_GetMySchoolTodayMeals()
{
    todayYmd := A_YYYY . A_MM . A_DD
    return SSOK_AdminCalendar_GetMySchoolMealsForDate(todayYmd)
}

SSOK_AdminCalendar_GetMySchoolMealsForDate(targetYmd)
{
    global SSOK_AdminCalMealCacheKey, SSOK_AdminCalMealCacheText

    ini := SSOK_AdminCalendar_GetIniFile()
    IniRead, orgName, %ini%, MajorTodos, OrgName, __SSOK_EMPTY__
    orgName := Trim(orgName)
    if (orgName = "" || orgName = "__SSOK_EMPTY__")
        return {ok:false, text:""}

    IniRead, savedName, %ini%, MySchool, Name, __SSOK_EMPTY__
    IniRead, officeCode, %ini%, MySchool, OfficeCode, __SSOK_EMPTY__
    IniRead, schoolCode, %ini%, MySchool, SchoolCode, __SSOK_EMPTY__
    savedName := Trim(savedName)
    officeCode := Trim(officeCode)
    schoolCode := Trim(schoolCode)

    ; ÇÐ±³ÄÚµå°¡ ¾ø°Å³ª ±â°ü¸íÀÌ ¹Ù²î¾úÀ¸¸é Á¤È®È÷ °°Àº ÇÐ±³¸íÀ» ÀÚµ¿ °Ë»öÇÕ´Ï´Ù.
    if (savedName != orgName || officeCode = "" || officeCode = "__SSOK_EMPTY__"
        || schoolCode = "" || schoolCode = "__SSOK_EMPTY__")
    {
        exact := SSOK_AdminCalendar_FindExactSchool(orgName)
        cnt := IsObject(exact) ? exact.Length() : 0
        if (cnt = 1)
        {
            school := exact[1]
            officeCode := school.officeCode
            schoolCode := school.schoolCode
            IniWrite, % school.schoolName, %ini%, MySchool, Name
            IniWrite, % officeCode, %ini%, MySchool, OfficeCode
            IniWrite, % schoolCode, %ini%, MySchool, SchoolCode
            IniWrite, % school.officeName, %ini%, MySchool, OfficeName
            IniWrite, % school.kind, %ini%, MySchool, SchoolKind
            IniWrite, % school.parentOrg, %ini%, MySchool, SupportOffice
            IniWrite, % school.address, %ini%, MySchool, Address
        }
        else
            return {ok:false, text:""}
    }

    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := A_YYYY . A_MM . A_DD
    todayKey := targetYmd
    cacheKey := orgName . "|" . officeCode . "|" . schoolCode . "|" . todayKey
    if (SSOK_AdminCalMealCacheKey = cacheKey)
        return {ok:true, text:SSOK_AdminCalMealCacheText}

    params := Object("ATPT_OFCDC_SC_CODE", officeCode
                   , "SD_SCHUL_CODE", schoolCode
                   , "MLSV_YMD", todayKey)
    url := SSOK_AdminCalendar_NeisBuildUrl("mealServiceDietInfo", params, 20)
    resp := SSOK_AdminCalendar_NeisHttpGet(url)

    if (!resp.ok)
        return {ok:false, text:""}

    meals := SSOK_AdminCalendar_ParseNeisMeals(resp.text)
    line := SSOK_AdminCalendar_FormatTodayMeals(meals)

    SSOK_AdminCalMealCacheKey := cacheKey
    SSOK_AdminCalMealCacheText := line
    return {ok:true, text:line}
}

SSOK_AdminCalendar_ParseNeisMeals(xml)
{
    meals := []
    seen := {}
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return meals

        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            mealType := SSOK_AdminCalendar_CleanNeisText(SSOK_AdminCalendar_XmlText(row, "MMEAL_SC_NM"))
            mealCode := SSOK_AdminCalendar_XmlText(row, "MMEAL_SC_CODE")
            dish := SSOK_AdminCalendar_CleanMealText(SSOK_AdminCalendar_XmlText(row, "DDISH_NM"))
            calInfo := SSOK_AdminCalendar_CleanNeisText(SSOK_AdminCalendar_XmlText(row, "CAL_INFO"))
            if (mealType = "" || dish = "")
                continue
            uniq := mealType . "|" . dish
            if (seen.HasKey(uniq))
                continue
            seen[uniq] := 1
            meals.Push({mealType:mealType, mealCode:mealCode, dish:dish, calInfo:calInfo})
        }
    }
    catch
    {
        return []
    }
    return meals
}

SSOK_AdminCalendar_CleanMealText(text)
{
    text := RegExReplace(text, "i)<br\s*/?>", " ¡¤ ")
    text := StrReplace(text, "`r", " ")
    text := StrReplace(text, "`n", " ¡¤ ")
    text := StrReplace(text, "*", "")
    ; ³ªÀÌ½º ±Þ½Ä ¸Þ´º µÚÀÇ ¾Ë·¹¸£±â ¹øÈ£ Ç¥±â (¿¹: 5.6.9.)´Â È­¸é¿¡¼­ Á¦°ÅÇÕ´Ï´Ù.
    text := RegExReplace(text, "\(\s*\d+(?:\.\d+)*\.?\s*\)", "")
    text := RegExReplace(text, "\s*¡¤\s*", " ¡¤ ")
    text := RegExReplace(text, "( ¡¤ ){2,}", " ¡¤ ")
    text := RegExReplace(text, "\s+", " ")
    return Trim(text, " ¡¤`t`r`n")
}

SSOK_AdminCalendar_FormatTodayMeals(meals)
{
    if (!IsObject(meals) || meals.Length() < 1)
        return ""

    out := ""
    order := ["Á¶½Ä", "Áß½Ä", "¼®½Ä"]

    for _, wanted in order
    {
        for idx, item in meals
        {
            if (item.mealType != wanted)
                continue
            part := wanted . ": " . item.dish
            if (Trim(item.calInfo) != "")
                part .= " ¡¤ " . Trim(item.calInfo)
            out .= (out = "" ? "" : "`n") . part
        }
    }

    ; Ç¥ÁØ 3Á¾ ¿ÜÀÇ ±Þ½Ä ±¸ºÐÀÌ ³»·Á¿À¸é ´©¶ôÇÏÁö ¾Ê°í µÚ¿¡ Ç¥½ÃÇÕ´Ï´Ù.
    for idx, item in meals
    {
        if (item.mealType = "Á¶½Ä" || item.mealType = "Áß½Ä" || item.mealType = "¼®½Ä")
            continue
        part := item.mealType . ": " . item.dish
        if (Trim(item.calInfo) != "")
            part .= " ¡¤ " . Trim(item.calInfo)
        out .= (out = "" ? "" : "`n") . part
    }
    return out
}

SSOK_AdminCalendar_GetWeekRange(ByRef weekFrom, ByRef weekTo)
{
    todayYmd := A_YYYY . A_MM . A_DD
    SSOK_AdminCalendar_GetWeekRangeForDate(todayYmd, weekFrom, weekTo)
}

SSOK_AdminCalendar_GetWeekRangeForDate(targetYmd, ByRef weekFrom, ByRef weekTo)
{
    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := A_YYYY . A_MM . A_DD

    ts := targetYmd . "000000"
    FormatTime, targetWDay, %ts%, WDay
    targetWDay += 0
    ; WDay: ÀÏ=1, ¿ù=2 ... Åä=7
    offset := (targetWDay = 1 ? -6 : 2 - targetWDay)
    EnvAdd, ts, %offset%, Days
    weekFrom := SubStr(ts, 1, 8)

    ts2 := ts
    EnvAdd, ts2, 6, Days
    weekTo := SubStr(ts2, 1, 8)
}

SSOK_AdminCalendar_GetNeisApiKey()
{
    ; SSOK4edu °ø¿ë ³ªÀÌ½º ±³À°Á¤º¸ °³¹æ Æ÷ÅÐ ÀÎÁõÅ°
    return "bdf805328d4546d1a4574fd266f5ae63"
}

SSOK_AdminCalendar_NeisBuildUrl(endpoint, params, pSize := 100)
{
    key := SSOK_AdminCalendar_GetNeisApiKey()
    url := "https://open.neis.go.kr/hub/" . endpoint
        . "?KEY=" . SSOK_Tool_QU_UrlEncode(key)
        . "&Type=xml&pIndex=1&pSize=" . pSize

    if IsObject(params)
    {
        for k, v in params
        {
            v := Trim(v)
            if (v != "")
                url .= "&" . k . "=" . SSOK_Tool_QU_UrlEncode(v)
        }
    }
    return url
}

SSOK_AdminCalendar_NeisHttpGet(url)
{
    out := {ok:false, text:"", status:0}
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
    catch
    {
        out.ok := false
    }
    return out
}

SSOK_AdminCalendar_FindExactSchool(orgName)
{
    exact := []
    params := Object("SCHUL_NM", orgName)
    url := SSOK_AdminCalendar_NeisBuildUrl("schoolInfo", params, 100)
    resp := SSOK_AdminCalendar_NeisHttpGet(url)
    if (!resp.ok)
        return exact

    rows := SSOK_AdminCalendar_ParseNeisSchools(resp.text)
    if !IsObject(rows)
        return exact

    for idx, item in rows
    {
        if (Trim(item.schoolName) = orgName)
            exact.Push(item)
    }
    return exact
}

SSOK_AdminCalendar_ParseNeisSchools(xml)
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
            schoolName := SSOK_AdminCalendar_XmlText(row, "SCHUL_NM")
            officeCode := SSOK_AdminCalendar_XmlText(row, "ATPT_OFCDC_SC_CODE")
            schoolCode := SSOK_AdminCalendar_XmlText(row, "SD_SCHUL_CODE")
            if (schoolName = "" || officeCode = "" || schoolCode = "")
                continue

            uniq := officeCode . "|" . schoolCode
            if (seen.HasKey(uniq))
                continue
            seen[uniq] := 1

            results.Push({schoolName:SSOK_AdminCalendar_CleanNeisText(schoolName)
                        , officeCode:officeCode
                        , schoolCode:schoolCode
                        , officeName:SSOK_AdminCalendar_CleanNeisText(SSOK_AdminCalendar_XmlText(row, "ATPT_OFCDC_SC_NM"))
                        , kind:SSOK_AdminCalendar_CleanNeisText(SSOK_AdminCalendar_XmlText(row, "SCHUL_KND_SC_NM"))
                        , parentOrg:SSOK_AdminCalendar_CleanNeisText(SSOK_AdminCalendar_XmlText(row, "JU_ORG_NM"))
                        , address:SSOK_AdminCalendar_CleanNeisText(SSOK_AdminCalendar_XmlText(row, "ORG_RDNMA"))})
        }
    }
    catch
    {
        return []
    }
    return results
}

SSOK_AdminCalendar_ParseNeisSchoolSchedule(xml)
{
    events := []
    seen := {}
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        if (!dom.loadXML(xml))
            return events

        nodes := dom.selectNodes("//*[local-name()='row']")
        Loop, % nodes.length
        {
            row := nodes.item(A_Index - 1)
            date := SSOK_AdminCalendar_XmlText(row, "AA_YMD")
            name := SSOK_AdminCalendar_CleanNeisText(SSOK_AdminCalendar_XmlText(row, "EVENT_NM"))
            ; Åä¿äÈÞ¾÷ÀÏ¸¸ Á¦¿ÜÇÕ´Ï´Ù. Àç·®ÈÞ¾÷ÀÏ°ú ´Ù¸¥ Åä¿äÀÏ Çà»ç´Â À¯ÁöÇÕ´Ï´Ù.
            if (RegExReplace(name, "\s+", "") = "Åä¿äÈÞ¾÷ÀÏ")
                continue
            if (date = "" || name = "")
                continue
            uniq := date . "|" . name
            if (seen.HasKey(uniq))
                continue
            seen[uniq] := 1
            events.Push({date:date, name:name})
        }
    }
    catch
    {
        return []
    }
    return events
}

SSOK_AdminCalendar_XmlText(parent, tagName)
{
    if (!IsObject(parent) || tagName = "")
        return ""
    try
    {
        node := parent.selectSingleNode(".//*[local-name()='" . tagName . "']")
        if IsObject(node)
            return Trim(node.text)

}
    catch
    {
    }
    return ""
}

SSOK_AdminCalendar_CleanNeisText(text)
{
    text := StrReplace(text, "`r", " ")
    text := StrReplace(text, "`n", " ")
    text := RegExReplace(text, "\s+", " ")
    return Trim(text)
}

SSOK_AdminCalendar_FormatSchoolWeekEvents(events)
{
    if !IsObject(events)
        return "±ÝÁÖ ÇÐ»çÀÏÁ¤ ¾øÀ½"

    parts := []
    total := events.Length()
    maxShow := 4

    for idx, item in events
    {
        if (idx > maxShow)
            break
        dateText := SSOK_AdminCalendar_FormatShortDateDay(item.date)
        parts.Push(dateText . " " . item.name)
    }

    out := ""
    for idx, item in parts
        out .= (out != "" ? " ¡¤ " : "") . item

    if (total > maxShow)
        out .= " ¡¤ ¿Ü " . (total - maxShow) . "°Ç"

    ; ÇÑ ÁÙ Ç¥½Ã¸¦ À¯ÁöÇÏ±â À§ÇØ Áö³ªÄ¡°Ô ±ä ¹®±¸¸¸ ³¡¿¡¼­ ÁÙÀÔ´Ï´Ù.
    if (StrLen(out) > 115)
        out := SubStr(out, 1, 112) . "..."
    return out
}

SSOK_AdminCalendar_FormatShortDateDay(ymd)
{
    d := RegExReplace(Trim(ymd), "[^0-9]", "")
    if (StrLen(d) != 8)
        return ymd

    m := SubStr(d, 5, 2) + 0
    day := SubStr(d, 7, 2) + 0
    wd := SSOK_AdminCalendar_DayName(d)
    return m . "/" . day . "(" . wd . ")"
}

SSOK_AdminCalendar_DayName(ymd)
{
    ts := ymd . "000000"
    FormatTime, wd, %ts%, ddd
    if (wd = "Mon" || InStr(wd, "¿ù"))
        return "¿ù"
    if (wd = "Tue" || InStr(wd, "È­"))
        return "È­"
    if (wd = "Wed" || InStr(wd, "¼ö"))
        return "¼ö"
    if (wd = "Thu" || InStr(wd, "¸ñ"))
        return "¸ñ"
    if (wd = "Fri" || InStr(wd, "±Ý"))
        return "±Ý"
    if (wd = "Sat" || InStr(wd, "Åä"))
        return "Åä"
    if (wd = "Sun" || InStr(wd, "ÀÏ"))
        return "ÀÏ"
    return wd
}

; =========================================================
; ÇàÁ¤¾÷¹«´Þ·Â ¼±ÅÃ ¿ù ÆäÀÌÁö ÀÚµ¿ Å½»ö
; ±âº» URLÀÌ Ç×»ó 'ÇöÀç ¿ù'¸¸ ³»·ÁÁÖ´Â °æ¿ì¸¦ º¸¿ÏÇÕ´Ï´Ù.
; ÇöÀç HTML¿¡¼­ ³¯Â¥/¿ù ÆÄ¶ó¹ÌÅÍ¸íÀ» ¿ì¼± Ã£°í,
; ÀÏ¹ÝÀûÀ¸·Î ¾²´Â ¿¬¿ù ÆÄ¶ó¹ÌÅÍ¸¦ GET/POST·Î ¼øÂ÷ ½ÃµµÇÕ´Ï´Ù.
; =========================================================
SSOK_AdminCalendar_HttpText(method, url, body := "", ByRef error := "")
{
    error := ""

    try
    {
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(1800, 1800, 2600, 3200)
        req.Open(method, url, false)
        req.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) SSOK/1.0")
        req.SetRequestHeader("Accept-Language", "ko-KR,ko;q=0.9")
        if (method = "POST")
            req.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
        req.Send(body)

        if (req.Status < 200 || req.Status >= 400)
        {
            error := "HTTP " . req.Status
            return ""
        }

        htmlUtf8 := SSOK_AdminCalendar_ResponseBodyToUtf8(req.ResponseBody)
        if (htmlUtf8 != "")
            return htmlUtf8

        return req.ResponseText . ""
    }
    catch e
    {
        error := e.Message
        return ""
    }
}

SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, siteCode)
{
    if !RegExMatch(targetYmd, "^\d{8}$")
        return false
    y := SubStr(targetYmd, 1, 4)
    m := SubStr(targetYmd, 5, 2)
    if (siteCode = "B")
    {
        if !RegExMatch(html, "is)<p\b[^>]*class\s*=\s*[""']date[""'][^>]*>(.*?)</p>", heading)
            return false
        title := RegExReplace(heading1, "is)<a\b.*?</a>", "")
        title := RegExReplace(title, "is)<[^>]+>|\s+", "")
        return title = y . "." . m && InStr(html, "calendar_list_tb")
    }
    if (siteCode = "J")
    {
        ; <em>2026</em>.<strong>10</strong>Ã³·³ ÅÂ±×·Î ³ª´¶ ½ÇÁ¦ ´Þ·Â Á¦¸ñ¸¸ È®ÀÎÇÕ´Ï´Ù.
        if !RegExMatch(html, "is)<p\b[^>]*class\s*=\s*[""']month[""'][^>]*>(.*?)</p>", heading)
            return false
        title := RegExReplace(heading1, "is)<button\b.*?</button>", "")
        title := RegExReplace(title, "is)<[^>]+>|\s+", "")
        return (title = y . "." . m)
    }
    return RegExMatch(html, "is)<strong\b[^>]*>\s*" . y . "-" . m . "\s*</strong>")
        && RegExMatch(html, "i)<ul\b[^>]*class\s*=\s*[""']calendar[""']")
}

SSOK_AdminCalendar_FindMonthPage(baseUrl, seedHtml, targetYmd, siteCode, ByRef error := "")
{
    error := ""

    y := SubStr(targetYmd, 1, 4)
    m2 := SubStr(targetYmd, 5, 2)
    ym := y . m2
    ymDash := y . "-" . m2
    ymd := targetYmd
    ymdDash := y . "-" . m2 . "-" . SubStr(targetYmd, 7, 2)

    ; -----------------------------------------------------
    ; 0) ½ÇÁ¦ ÆäÀÌÁöÀÇ ´Þ·Â formÀ» ÅëÂ°·Î º¹Á¦ÇØ¼­ ¼±ÅÃ ¿ùÀ» Á¦Ãâ
    ;    (boardId/menuCd/hidden ÇÊµå°¡ ÇÔ²² ÇÊ¿äÇÑ »çÀÌÆ® ´ëÀÀ)
    ; -----------------------------------------------------
    formHtml := SSOK_AdminCalendar_TryCalendarForms(baseUrl, seedHtml, targetYmd, siteCode, formErr)
    if (formHtml != "")
        return formHtml

    ; -----------------------------------------------------
    ; 1) HTML ¾È¿¡ ¸ñÇ¥ ¿ùÀÌ µé¾î°£ Á÷Á¢ ¸µÅ©°¡ ÀÖÀ¸¸é ÃÖ¿ì¼±
    ; -----------------------------------------------------
    directUrl := SSOK_AdminCalendar_FindDirectMonthUrl(seedHtml, baseUrl, targetYmd)
    if (directUrl != "")
    {
        html := SSOK_AdminCalendar_HttpText("GET", directUrl, "", reqErr)
        if (html != "" && SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, siteCode))
            return html
    }

    ; -----------------------------------------------------
    ; 2) ÇöÀç ÆäÀÌÁö ¼Ò½º¿¡ ½ÇÁ¦·Î ¾²ÀÎ ³¯Â¥ °ü·Ã ÆÄ¶ó¹ÌÅÍ¸íÀ» ÀÚµ¿ ÃßÃâ
    ; -----------------------------------------------------
    keys := SSOK_AdminCalendar_FindDateKeys(seedHtml)

    ; °¡´É¼ºÀÌ ³ôÀº ÀÌ¸§Àº ¾ÕÂÊ¿¡ Ãß°¡
    preferred := ["searchYm","searchYM","searchMonth","searchDate","searchYmd"
        ,"schdulYm","schdlYm","scheduleYm","calendarYm","calYm","currYm","currentYm"
        ,"yyyymm","yearMonth","ym","monthDate","viewDate","date"]

    for _, k in preferred
        SSOK_AdminCalendar_ArrayAddUnique(keys, k)

    ; ÀÌ¸§¿¡ µû¶ó °¡Àå °¡´É¼º ³ôÀº °ª Çü½ÄÀ» ¸ÕÀú ½Ãµµ
    for _, key in keys
    {
        keyLow := key
        StringLower, keyLow, keyLow

        vals := []
        if (InStr(keyLow, "ymd") || InStr(keyLow, "date"))
        {
            vals.Push(ymdDash)
            vals.Push(ymd)
            vals.Push(ym)
        }
        else
        {
            vals.Push(ym)
            vals.Push(ymDash)
            vals.Push(ymdDash)
        }

        for _, val in vals
        {
            pair := SSOK_AdminCalendar_UrlEncode(key) . "=" . SSOK_AdminCalendar_UrlEncode(val)

            testUrl := SSOK_AdminCalendar_AddQuery(baseUrl, pair)
            html := SSOK_AdminCalendar_HttpText("GET", testUrl, "", reqErr)
            if (html != "" && SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, siteCode))
                return html

            html := SSOK_AdminCalendar_HttpText("POST", baseUrl, pair, reqErr)
            if (html != "" && SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, siteCode))
                return html
        }
    }

    ; -----------------------------------------------------
    ; 3) ¿¬µµ/¿ùÀ» µû·Î ¹Þ´Â ¹æ½Ä
    ; -----------------------------------------------------
    pairs := []
    pairs.Push("year=" . y . "&month=" . m2)
    pairs.Push("searchYear=" . y . "&searchMonth=" . m2)
    pairs.Push("srchYear=" . y . "&srchMonth=" . m2)
    pairs.Push("schdlYear=" . y . "&schdlMonth=" . m2)
    pairs.Push("schdulYear=" . y . "&schdulMonth=" . m2)
    pairs.Push("calYear=" . y . "&calMonth=" . m2)
    pairs.Push("yyyy=" . y . "&mm=" . m2)

    for _, pair in pairs
    {
        testUrl := SSOK_AdminCalendar_AddQuery(baseUrl, pair)
        html := SSOK_AdminCalendar_HttpText("GET", testUrl, "", reqErr)
        if (html != "" && SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, siteCode))
            return html

        html := SSOK_AdminCalendar_HttpText("POST", baseUrl, pair, reqErr)
        if (html != "" && SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, siteCode))
            return html
    }

    error := "¼±ÅÃÇÑ ¿ù(" . ymDash . ")ÀÇ ÆäÀÌÁö¸¦ ¼­¹ö¿¡¼­ Ã£Áö ¸øÇß½À´Ï´Ù."
    return ""
}

SSOK_AdminCalendar_FindDateKeys(html)
{
    out := []
    seen := {}

    ; input/select ÀÌ¸§ Áß ³¯Â¥/¿ù/´Þ·Â °è¿­À» ÀÚµ¿ ¼öÁý
    pos := 1
    while (pos := RegExMatch(html, "is)<(?:input|select)\b[^>]*\bname\s*=\s*[""']([^""']+)[""'][^>]*>", m, pos))
    {
        key := Trim(m1)
        keyLow := key
        StringLower, keyLow, keyLow

        if (InStr(keyLow, "date") || InStr(keyLow, "month") || InStr(keyLow, "year")
            || InStr(keyLow, "ym") || InStr(keyLow, "cal") || InStr(keyLow, "schd"))
        {
            if (!seen.HasKey(key))
            {
                seen[key] := true
                out.Push(key)
            }
        }

        pos += StrLen(m)
    }

    ; ÇöÀç °ª ÀÚÃ¼°¡ YYYYMM / YYYY-MM / YYYY-MM-DD ÇüÅÂÀÎ inputµµ ÈÄº¸·Î Æ÷ÇÔ
    pos := 1
    while (pos := RegExMatch(html, "is)<input\b[^>]*>", t, pos))
    {
        name := SSOK_AdminCalendar_GetHtmlAttr(t, "name")
        value := SSOK_AdminCalendar_GetHtmlAttr(t, "value")
        if (name != "" && RegExMatch(Trim(value), "^20\d{2}[-./]?\d{2}(?:[-./]?\d{2})?$"))
        {
            if (!seen.HasKey(name))
            {
                seen[name] := true
                out.Push(name)
            }
        }
        pos += StrLen(t)
    }

    ; document.form.field.value = ... / document.getElementById(...).value = ...
    pos := 1
    while (pos := RegExMatch(html, "i)(?:document\.[A-Za-z0-9_]+\.)?([A-Za-z_][A-Za-z0-9_]*)\.value\s*=", m, pos))
    {
        key := Trim(m1)
        keyLow := key
        StringLower, keyLow, keyLow
        if (InStr(keyLow, "date") || InStr(keyLow, "month") || InStr(keyLow, "year")
            || InStr(keyLow, "ym") || InStr(keyLow, "cal") || InStr(keyLow, "schd"))
        {
            if (!seen.HasKey(key))
            {
                seen[key] := true
                out.Push(key)
            }
        }
        pos += StrLen(m)
    }

    ; jQuery $('...').val(...) ÇüÅÂ¿¡¼­ id/name ÈÄº¸ ¼öÁý
    pos := 1
    while (pos := RegExMatch(html, "i)\$\(\s*[""'][#]?([A-Za-z_][A-Za-z0-9_-]*)[""']\s*\)\.val\s*\(", m, pos))
    {
        key := Trim(m1)
        keyLow := key
        StringLower, keyLow, keyLow
        if (InStr(keyLow, "date") || InStr(keyLow, "month") || InStr(keyLow, "year")
            || InStr(keyLow, "ym") || InStr(keyLow, "cal") || InStr(keyLow, "schd"))
        {
            if (!seen.HasKey(key))
            {
                seen[key] := true
                out.Push(key)
            }
        }
        pos += StrLen(m)
    }

    ; ÀÚ¹Ù½ºÅ©¸³Æ® °´Ã¼/º¯¼öÀÇ ³¯Â¥ Å°µµ ¼öÁý
    pos := 1
    while (pos := RegExMatch(html, "i)([A-Za-z_][A-Za-z0-9_]*)\s*[:=]\s*[""']20\d{2}[-./]?\d{2}(?:[-./]?\d{2})?[""']", m, pos))
    {
        key := Trim(m1)
        keyLow := key
        StringLower, keyLow, keyLow

        if (InStr(keyLow, "date") || InStr(keyLow, "month") || InStr(keyLow, "year")
            || InStr(keyLow, "ym") || InStr(keyLow, "cal") || InStr(keyLow, "schd"))
        {
            if (!seen.HasKey(key))
            {
                seen[key] := true
                out.Push(key)
            }
        }

        pos += StrLen(m)
    }

    return out
}

SSOK_AdminCalendar_ArrayAddUnique(ByRef arr, value)
{
    if (!IsObject(arr))
        arr := []

    for _, old in arr
    {
        if (old = value)
            return
    }
    arr.Push(value)
}

SSOK_AdminCalendar_FindDirectMonthUrl(html, baseUrl, targetYmd)
{
    y := SubStr(targetYmd, 1, 4)
    m2 := SubStr(targetYmd, 5, 2)

    tokens := [y . m2, y . "-" . m2, y . "." . m2]

    for _, token in tokens
    {
        safe := RegExReplace(token, "([\.\-\+\*\?\[\]\(\)\{\}\^\$\|\\])", "\$1")

        ; href / data-url µî ¼Ó¼º¿¡¼­ ¸ñÇ¥ ¿ùÀÌ µé¾î°£ URL Ã£±â
        pos := 1
        pat := "is)(?:href|data-url|data-href)\s*=\s*[""']([^""']*" . safe . "[^""']*)[""']"
        while (pos := RegExMatch(html, pat, m, pos))
        {
            href := Trim(m1)
            href := StrReplace(href, "&amp;", "&")
            href := StrReplace(href, "&#38;", "&")

            if (href != "" && href != "#" && !InStr(href, "javascript:"))
                return SSOK_AdminCalendar_AbsoluteUrl(baseUrl, href)

            pos += StrLen(m)
        }

        ; ½ºÅ©¸³Æ® ¾ÈÀÇ ¿Ï¼º URL ¹®ÀÚ¿­µµ È®ÀÎ
        pos := 1
        pat2 := "is)[""']([^""']*\.do\?[^""']*" . safe . "[^""']*)[""']"
        while (pos := RegExMatch(html, pat2, m2u, pos))
        {
            href := Trim(m2u1)
            href := StrReplace(href, "&amp;", "&")
            if (href != "")
                return SSOK_AdminCalendar_AbsoluteUrl(baseUrl, href)
            pos += StrLen(m2u)
        }
    }

    return ""
}

SSOK_AdminCalendar_AddQuery(url, query)
{
    return url . (InStr(url, "?") ? "&" : "?") . query
}

SSOK_AdminCalendar_AbsoluteUrl(baseUrl, href)
{
    if RegExMatch(href, "i)^https?://")
        return href

    if (SubStr(href, 1, 2) = "//")
        return "https:" . href

    if !RegExMatch(baseUrl, "i)^(https?://[^/]+)", m)
        return href

    root := m1

    if (SubStr(href, 1, 1) = "/")
        return root . href

    clean := RegExReplace(baseUrl, "[?#].*$", "")
    clean := RegExReplace(clean, "[^/]*$", "")
    return clean . href
}

SSOK_AdminCalendar_UrlEncode(text)
{
    size := StrPut(text, "UTF-8")
    VarSetCapacity(buf, size, 0)
    len := StrPut(text, &buf, size, "UTF-8") - 1
    out := ""

    Loop, %len%
    {
        ch := NumGet(buf, A_Index - 1, "UChar")
        if ((ch >= 0x30 && ch <= 0x39) || (ch >= 0x41 && ch <= 0x5A)
            || (ch >= 0x61 && ch <= 0x7A) || ch = 0x2D || ch = 0x2E
            || ch = 0x5F || ch = 0x7E)
            out .= Chr(ch)
        else
            out .= "%" . Format("{:02X}", ch)
    }

    return out
}


; ---------------------------------------------------------
; ´Þ·Â form ÀüÃ¼ Á¦Ãâ ¹æ½Ä
; ---------------------------------------------------------
SSOK_AdminCalendar_TryCalendarForms(baseUrl, html, targetYmd, siteCode, ByRef error := "")
{
    error := ""
    y := SubStr(targetYmd, 1, 4)
    m2 := SubStr(targetYmd, 5, 2)
    ym := y . m2
    ymDash := y . "-" . m2
    ymd := targetYmd
    ymdDash := y . "-" . m2 . "-" . SubStr(targetYmd, 7, 2)

    formFound := false
    pos := 1

    while (pos := RegExMatch(html, "is)<form\b([^>]*)>(.*?)</form>", fm, pos))
    {
        attrs := fm1
        body := fm2
        whole := fm

        ; ´Þ·Â/ÀÌÀü´Þ/´ÙÀ½´Þ/ÇÐ±³±Þº° ÀÏÁ¤°ú °ü·ÃµÈ formÀ» ¿ì¼± Ã³¸®
        if (!InStr(body, "´ÙÀ½´Þ") && !InStr(body, "ÀÌÀü´Þ")
            && !InStr(body, "ÇàÁ¤´Þ·Â") && !InStr(body, "ÇÐ±³±Þº° ÀÏÁ¤")
            && !InStr(body, "calendar") && !InStr(body, "Calendar"))
        {
            pos += StrLen(fm)
            continue
        }

        formFound := true
        action := SSOK_AdminCalendar_GetHtmlAttr("<form " . attrs . ">", "action")
        method := SSOK_AdminCalendar_GetHtmlAttr("<form " . attrs . ">", "method")
        StringUpper, method, method
        if (method != "POST")
            method := "GET"

        if (action = "")
            action := baseUrl
        else
            action := SSOK_AdminCalendar_AbsoluteUrl(baseUrl, action)

        params := SSOK_AdminCalendar_ParseFormInputs(whole)
        SSOK_AdminCalendar_MergeUrlQueryIntoMap(baseUrl, params)

        keys := SSOK_AdminCalendar_FindDateKeys(whole)
        for k, v in params
        {
            v2 := Trim(v)
            if RegExMatch(v2, "^20\d{2}[-./]?\d{2}(?:[-./]?\d{2})?$")
                SSOK_AdminCalendar_ArrayAddUnique(keys, k)
        }

        preferred := ["searchYm","searchYM","searchMonth","searchDate","searchYmd"
            ,"schdulYm","schdlYm","scheduleYm","calendarYm","calYm","currYm","currentYm"
            ,"yyyymm","yearMonth","ym","monthDate","viewDate","date","calendarDate","schdulDate"]

        for _, k in preferred
            SSOK_AdminCalendar_ArrayAddUnique(keys, k)

        for _, key in keys
        {
            keyLow := key
            StringLower, keyLow, keyLow
            vals := []

            if (InStr(keyLow, "ymd") || InStr(keyLow, "date"))
            {
                vals.Push(ymdDash)
                vals.Push(ymd)
                vals.Push(ymDash)
                vals.Push(ym)
            }
            else
            {
                vals.Push(ym)
                vals.Push(ymDash)
                vals.Push(ymdDash)
                vals.Push(ymd)
            }

            for _, val in vals
            {
                data := SSOK_AdminCalendar_BuildFormData(params, key, val)

                ; form method ¿ì¼±
                if (method = "POST")
                    resp := SSOK_AdminCalendar_HttpText("POST", action, data, reqErr)
                else
                    resp := SSOK_AdminCalendar_HttpText("GET", SSOK_AdminCalendar_AddQuery(action, data), "", reqErr)

                if (resp != "" && SSOK_AdminCalendar_PageIsTargetMonth(resp, targetYmd, siteCode))
                    return resp

                ; »çÀÌÆ® ±¸Çö Â÷ÀÌ ´ëºñ GET/POST ¹Ý´ë ¹æ½Äµµ ÇÑ ¹ø ½Ãµµ
                if (method = "POST")
                    resp := SSOK_AdminCalendar_HttpText("GET", SSOK_AdminCalendar_AddQuery(action, data), "", reqErr)
                else
                    resp := SSOK_AdminCalendar_HttpText("POST", action, data, reqErr)

                if (resp != "" && SSOK_AdminCalendar_PageIsTargetMonth(resp, targetYmd, siteCode))
                    return resp
            }
        }

        pos += StrLen(fm)
    }

    if (!formFound)
        error := "´Þ·Â formÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
    else
        error := "´Þ·Â form Á¦Ãâ·Î ¼±ÅÃ ¿ùÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
    return ""
}

SSOK_AdminCalendar_ParseFormInputs(formHtml)
{
    params := {}
    pos := 1

    while (pos := RegExMatch(formHtml, "is)<input\b[^>]*>", tag, pos))
    {
        inputTag := tag
        name := SSOK_AdminCalendar_GetHtmlAttr(inputTag, "name")
        value := SSOK_AdminCalendar_GetHtmlAttr(inputTag, "value")
        type := SSOK_AdminCalendar_GetHtmlAttr(inputTag, "type")
        StringLower, type, type

        if (name != "" && type != "submit" && type != "button" && type != "image"
            && type != "file" && type != "reset")
        {
            ; checkbox/radio´Â checkedÀÏ ¶§¸¸ Àü¼Û
            if ((type = "checkbox" || type = "radio") && !RegExMatch(inputTag, "i)\bchecked(?:\s*=\s*[""'][^""']*[""'])?"))
            {
                pos += StrLen(tag)
                continue
            }
            params[name] := value
        }

        pos += StrLen(tag)
    }

    ; selectÀÇ ÇöÀç ¼±ÅÃ°ªµµ Æ÷ÇÔ
    pos := 1
    while (pos := RegExMatch(formHtml, "is)<select\b([^>]*)>(.*?)</select>", sm, pos))
    {
        selTag := "<select " . sm1 . ">"
        name := SSOK_AdminCalendar_GetHtmlAttr(selTag, "name")
        if (name != "")
        {
            value := ""
            if RegExMatch(sm2, "is)<option\b[^>]*\bselected\b[^>]*>", om)
                value := SSOK_AdminCalendar_GetHtmlAttr(om, "value")
            else if RegExMatch(sm2, "is)<option\b[^>]*>", om)
                value := SSOK_AdminCalendar_GetHtmlAttr(om, "value")
            params[name] := value
        }
        pos += StrLen(sm)
    }

    return params
}

SSOK_AdminCalendar_GetHtmlAttr(tag, attrName)
{
    safe := RegExReplace(attrName, "([\\.^$|?*+(){}\[\]])", "\\$1")

    if RegExMatch(tag, "is)\b" . safe . "\s*=\s*[""']([^""']*)[""']", m)
        return m1
    if RegExMatch(tag, "is)\b" . safe . "\s*=\s*([^\s>]+)", m)
        return m1
    return ""
}

SSOK_AdminCalendar_MergeUrlQueryIntoMap(url, ByRef params)
{
    qPos := InStr(url, "?")
    if (!qPos)
        return

    query := SubStr(url, qPos + 1)
    hashPos := InStr(query, "#")
    if (hashPos)
        query := SubStr(query, 1, hashPos - 1)

    Loop, Parse, query, &
    {
        pair := A_LoopField
        eq := InStr(pair, "=")
        if (eq)
        {
            k := SubStr(pair, 1, eq - 1)
            v := SubStr(pair, eq + 1)
        }
        else
        {
            k := pair
            v := ""
        }

        if (k != "" && !params.HasKey(k))
            params[k] := v
    }
}

SSOK_AdminCalendar_BuildFormData(params, overrideKey := "", overrideValue := "")
{
    out := ""
    usedOverride := false

    for k, v in params
    {
        if (k = overrideKey)
        {
            v := overrideValue
            usedOverride := true
        }

        part := SSOK_AdminCalendar_UrlEncode(k) . "=" . SSOK_AdminCalendar_UrlEncode(v)
        out .= (out = "" ? "" : "&") . part
    }

    if (overrideKey != "" && !usedOverride)
    {
        part := SSOK_AdminCalendar_UrlEncode(overrideKey) . "=" . SSOK_AdminCalendar_UrlEncode(overrideValue)
        out .= (out = "" ? "" : "&") . part
    }

    return out
}

SSOK_AdminCalendar_GetSeoulUrl()
{
    return "https://baro.sen.go.kr/"
}

SSOK_AdminCalendar_DownloadSeoulHtml(ByRef error, targetYmd := "")
{
    return SSOK_AdminCalendar_DownloadMonth("S", targetYmd, error)
}

SSOK_AdminCalendar_ParseTodaySeoul(html)
{
    todayYmd := A_YYYY . A_MM . A_DD
    return SSOK_AdminCalendar_ParseDateSeoul(html, todayYmd)
}

SSOK_AdminCalendar_ParseDateSeoul(html, targetYmd)
{
    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := A_YYYY . A_MM . A_DD

    dateText := SubStr(targetYmd, 1, 4) . "-" . SubStr(targetYmd, 5, 2) . "-" . SubStr(targetYmd, 7, 2)
    targetMonth := SubStr(targetYmd, 1, 4) . "-" . SubStr(targetYmd, 5, 2)
    plain := SSOK_AdminCalendar_HtmlToLines(html)

    if !SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, "S")
        return {ok:false, text:"", count:0, error:"¼±ÅÃÇÑ ¿ùÀÇ ¼­¿ï±³À°Ã» ÀÏÁ¤À» ÇöÀç ÆäÀÌÁö¿¡¼­ Ã£Áö ¸øÇß½À´Ï´Ù.", events:[]}

    lines := StrSplit(plain, "`n")
    events := []
    seen := {}
    foundDate := false

    for i, line in lines
    {
        if (Trim(line) != dateText)
            continue

        foundDate := true

        Loop, 100
        {
            idx := i + A_Index
            if (idx > lines.Length())
                break

            item := Trim(lines[idx])
            if (item = "")
                continue

            ; ´ÙÀ½ ³¯Â¥ ¶Ç´Â ´Ù¸¥ ÇÐ±³±Þ ºí·ÏÀ¸·Î ³Ñ¾î°¡¸é ÇöÀç ³¯Â¥ ºí·Ï Á¾·á
            if RegExMatch(item, "^20\d{2}-\d{2}-\d{2}$")
                break
            if (item = "À¯" || item = "ÃÊ" || item = "Áß" || item = "°í")
                break
            if RegExMatch(item, "^\d{1,2}$")
                break
            if (InStr(item, "ÇÐ±³±Þº° ÀÏÁ¤") || InStr(item, "°³ÀÎÁ¤º¸Ã³¸®¹æÄ§"))
                break
            if (item = "À¯Ä¡¿ø" || item = "ÃÊµîÇÐ±³" || item = "ÁßÇÐ±³" || item = "°íµîÇÐ±³"
                || item = "¾÷¹«ÀÏÁ¤Ç¥" || item = "³ªÀÇ ÀÏÁ¤")
                continue

            item := SSOK_AdminCalendar_CleanText(item)
            if (item = "" || item = "ÀÏÁ¤ ´Ý±â" || seen.HasKey(item))
                continue

            seen[item] := true
            events.Push(item)
        }
    }

    ; ÇØ´ç ³¯Â¥°¡ ´Þ·Â¿¡´Â Á¸ÀçÇÏÁö¸¸ ÀÏÁ¤ÀÌ ¾øÀ¸¸é Á¤»ó ºóÄ­
    if (!foundDate)
        return {ok:true, text:"", count:0, error:"", events:[]}

    out := SSOK_AdminCalendar_FormatEvents(events)
    return {ok:true, text:out, count:events.Length(), error:"", events:events}
}

SSOK_AdminCalendar_HtmlToLines(fragment)
{
    s := fragment . ""
    s := RegExReplace(s, "is)<br\s*/?>", "`n")
    s := RegExReplace(s, "is)</(?:p|div|li|td|tr|a|span|button|h[1-6])\s*>", "`n")
    s := RegExReplace(s, "is)<[^>]+>", " ")

    s := StrReplace(s, "&nbsp;", " ")
    s := StrReplace(s, "&#160;", " ")
    s := StrReplace(s, "&amp;", "&")
    s := StrReplace(s, "&lt;", "<")
    s := StrReplace(s, "&gt;", ">")
    s := StrReplace(s, "&quot;", Chr(34))
    s := StrReplace(s, "&#39;", "'")
    s := StrReplace(s, "`r", "")
    s := RegExReplace(s, "[ `t]+", " ")
    s := RegExReplace(s, " *`n *", "`n")
    s := RegExReplace(s, "`n{2,}", "`n")
    return Trim(s)
}

SSOK_AdminCalendar_MergeEvents(ByRef merged, ByRef seen, events)
{
    if (!IsObject(events))
        return

    for _, item in events
    {
        item := SSOK_AdminCalendar_CleanText(item)
        if (item = "ÀÏÁ¤ ´Ý±â")
            continue
        if (item = "" || seen.HasKey(item))
            continue
        seen[item] := true
        merged.Push(item)
    }
}

SSOK_AdminCalendar_FormatEvents(events)
{
    if (!IsObject(events) || !events.Length())
        return ""

    out := ""
    maxShow := events.Length() > 6 ? 6 : events.Length()
    Loop, %maxShow%
        out .= (out = "" ? "" : "`n") . "- " . events[A_Index]

    if (events.Length() > maxShow)
        out .= "`n- ¿Ü " . (events.Length() - maxShow) . "°Ç"
    if (StrLen(out) > 900)
        out := SubStr(out, 1, 897) . "..."
    return out
}

SSOK_AdminCalendar_FormatEventsAll(events)
{
    if (!IsObject(events) || !events.Length())
        return ""

    out := ""
    seen := {}
    for _, item in events
    {
        item := Trim(SSOK_AdminCalendar_CleanText(item), " `t`r`n")
        if (item = "" || item = "ÀÏÁ¤ ´Ý±â" || seen.HasKey(item))
            continue
        seen[item] := true
        out .= (out = "" ? "" : "`n") . "¡¤ " . item
    }
    return out
}

SSOK_AdminCalendar_GetUrl()
{
    return "https://www.jbe.go.kr/board/list.jbe?boardId=BBS_0000084&contentsSid=335&cpath=%2Fsupport&menuCd=DOM_000000106002001000"
}

SSOK_AdminCalendar_DownloadHtml(ByRef error, targetYmd := "")
{
    return SSOK_AdminCalendar_DownloadMonth("J", targetYmd, error)
}

; ½ÇÁ¦ È¨ÆäÀÌÁöÀÇ ¿ù ÀÌµ¿ ¿äÃ»À» »ç¿ëÇÕ´Ï´Ù. ÃßÃø ÆÄ¶ó¹ÌÅÍ Å½»öÀº ÇÏÁö ¾Ê½À´Ï´Ù.
SSOK_AdminCalendar_DownloadMonth(siteCode, targetYmd, ByRef error)
{
    static pages := {}
    error := ""
    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := A_YYYY . A_MM . A_DD
    ym := SubStr(targetYmd, 1, 6)
    key := siteCode . "|" . ym
    if (pages.HasKey(key) && A_TickCount >= pages[key].tick && A_TickCount - pages[key].tick < 900000)
        return pages[key].html

    y := SubStr(ym, 1, 4)
    m := SubStr(ym, 5, 2)
    if (siteCode = "S")
    {
        body := "schedule_year=" . y . "&schedule_month=" . m . "&searchKeyword=" . ym . "&sch_school=CD1601"
        html := SSOK_AdminCalendar_HttpText("POST", "https://baro.sen.go.kr/fus/main/mainScheduleCal0010f.do", body, error)
    }
    else if (siteCode = "B")
        html := SSOK_AdminCalendar_HttpText("GET", SSOK_AdminCalendar_GetBusanUrl() . "&dateY=" . y . "&dateM=" . (m + 0), "", error)
    else
    {
        query := "boardId=BBS_0000084&menuCd=DOM_000000106002001000&searchStartDt=" . y . "-" . m . "-01&searchEndDt=" . y . "-" . m . "-31"
        html := SSOK_AdminCalendar_HttpText("GET", "https://www.jbe.go.kr/schedule/list.jbe?" . query, "", error)
        if (!SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, "J"))
            html := SSOK_AdminCalendar_HttpText("GET", "https://www.jbe.go.kr/board/list.jbe?" . query, "", error)
    }
    if (html != "" && SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, siteCode))
    {
        pages[key] := {html:html, tick:A_TickCount}
        error := ""
        return html
    }
    if (error = "")
        error := "¼±ÅÃÇÑ ¿ù(" . y . "-" . m . ")ÀÇ ´Þ·Â ÀÀ´äÀ» È®ÀÎÇÏÁö ¸øÇß½À´Ï´Ù."
    return ""
}

SSOK_AdminCalendar_ResponseBodyToUtf8(body)
{
    try
    {
        stream := ComObjCreate("ADODB.Stream")
        stream.Type := 1
        stream.Open()
        stream.Write(body)
        stream.Position := 0
        stream.Type := 2
        stream.Charset := "utf-8"

        text := stream.ReadText()
        stream.Close()

        return text
    }
    catch e
    {
        return ""
    }
}

SSOK_AdminCalendar_ParseToday(html)
{
    todayYmd := A_YYYY . A_MM . A_DD
    return SSOK_AdminCalendar_ParseDate(html, todayYmd)
}

SSOK_AdminCalendar_ParseDate(html, targetYmd)
{
    if !RegExMatch(targetYmd, "^\d{8}$")
        targetYmd := A_YYYY . A_MM . A_DD
    if !SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, "J")
        return {ok:false, text:"", count:0, error:"¼±ÅÃÇÑ ¿ùÀÇ ÀüºÏ±³À°Ã» ´Þ·ÂÀ» È®ÀÎÇÏÁö ¸øÇß½À´Ï´Ù.", events:[]}
    ; ´Ù¸¥ Ç¥ÀÇ ¼ýÀÚ¸¦ ³¯Â¥·Î ¿ÀÀÎÇÏÁö ¾Êµµ·Ï ¿ùº°ÀÏÁ¤ Ç¥·Î ÇÑÁ¤ÇÕ´Ï´Ù.
    if !RegExMatch(html, "is)<table\b[^>]*>\s*<caption>\s*<strong>¿ùº°ÀÏÁ¤</strong>.*?</table>", calendarTable)
        return {ok:false, text:"", count:0, error:"ÀüºÏ±³À°Ã» ´Þ·Â Ç¥¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.", events:[]}
    html := calendarTable
    day := SubStr(targetYmd, 7, 2) + 0
    cellHtml := ""

    ; ¿À´ÃÀ» ¼±ÅÃÇÑ °æ¿ì¿¡´Â ¼­¹öÀÇ '¿À´Ã³¯Â¥' Ç¥½Ã¸¦ °¡Àå ¸ÕÀú »ç¿ëÇÕ´Ï´Ù.
    todayYmd := A_YYYY . A_MM . A_DD
    if (targetYmd = todayYmd)
    {
        patToday := "is)<td\b[^>]*>(?:(?!</td>)[\s\S])*?¿À´Ã³¯Â¥(?:(?!</td>)[\s\S])*?</td>"
        if RegExMatch(html, patToday, mToday)
            cellHtml := mToday
    }

    ; 2¼øÀ§: ¸ðµç td¸¦ ¼øÈ¸ÇÏ¸ç ¼¿ÀÇ Ã¹ ¼ýÀÚ°¡ ¼±ÅÃ ³¯Â¥ÀÎÁö È®ÀÎ
    if (cellHtml = "")
    {
        pos := 1

        while (pos := RegExMatch(html, "is)<td\b[^>]*>.*?</td>", mCell, pos))
        {
            plain := SSOK_AdminCalendar_HtmlToText(mCell)

            if RegExMatch(plain, "^\s*0?" . day . "(?:\s|¿À´Ã³¯Â¥|$)")
            {
                cellHtml := mCell
                break
            }

            pos += StrLen(mCell)
        }
    }

    if (cellHtml = "")
        return {ok:false, text:"", count:0, error:"¼±ÅÃ ³¯Â¥ÀÇ ´Þ·Â Ä­À» Ã£Áö ¸øÇß½À´Ï´Ù.", events:[]}

    ; ¼±ÅÃ ³¯Â¥ Ä­À» Ã£¾ÒÀ¸¸é ÀÏÁ¤ÀÌ ÇÑ °Çµµ ¾ø¾îµµ Á¤»óÀÔ´Ï´Ù.
    events := []
    pos := 1

    while (pos := RegExMatch(cellHtml, "is)<li\b[^>]*>(.*?)</li>", mItem, pos))
    {
        item := SSOK_AdminCalendar_HtmlToText(mItem1)
        item := RegExReplace(item, "^\s*\d{1,2}\.\d{1,2}\.\s*", "")

        if (item != "")
            events.Push(item)

        pos += StrLen(mItem)
    }

    if (!events.Length())
        return {ok:true, text:"", count:0, error:"", events:events}

    out := SSOK_AdminCalendar_FormatEvents(events)
    return {ok:true, text:out, count:events.Length(), error:"", events:events}
}

SSOK_AdminCalendar_HtmlToText(fragment)
{
    s := fragment . ""

    ; ÁÙ¹Ù²Þ ÅÂ±×´Â ÅØ½ºÆ® ÁÙ¹Ù²ÞÀ¸·Î
    s := RegExReplace(s, "is)<br\s*/?>", "`n")
    s := RegExReplace(s, "is)</p\s*>", "`n")
    s := RegExReplace(s, "is)</div\s*>", "`n")

    ; ³ª¸ÓÁö ÅÂ±× Á¦°Å
    s := RegExReplace(s, "is)<[^>]+>", " ")

    ; ÀÚÁÖ ¾²´Â HTML entity º¹¿ø
    s := StrReplace(s, "&nbsp;", " ")
    s := StrReplace(s, "&#160;", " ")
    s := StrReplace(s, "&amp;", "&")
    s := StrReplace(s, "&lt;", "<")
    s := StrReplace(s, "&gt;", ">")
    s := StrReplace(s, "&quot;", Chr(34))
    s := StrReplace(s, "&#39;", "'")

    return SSOK_AdminCalendar_CleanText(s)
}

SSOK_AdminCalendar_CleanText(text)
{
    s := text . ""
    s := StrReplace(s, Chr(160), " ")
    s := StrReplace(s, "`r", " ")
    s := RegExReplace(s, "[ `t]+", " ")
    s := RegExReplace(s, " *`n *", "`n")
    s := RegExReplace(s, "`n{2,}", "`n")

    return Trim(s)
}


; ============================================================================
; ±¹¼¼Ã» ¡¤ Á¶´ÞÃ» ¾÷Ã¼Á¤º¸ Á¶È¸
; ±¹¼¼Ã»: »ç¾÷ÀÚµî·Ï »óÅÂÁ¶È¸
; Á¶´ÞÃ»: ¾÷Ã¼ ±âº»Á¤º¸ / µî·Ï¾÷Á¾ / ÇöÀç À¯È¿ ºÎÁ¤´çÁ¦Àç
; ============================================================================

SSOK_CompanyInfo_Search:
    Gui, SSOKCompanyInfo:Submit, NoHide

    bizno := RegExReplace(SSOK_CompanyBizNo, "\D", "")
    inputName := Trim(SSOK_CompanyName)

    if (bizno = "" && inputName = "")
    {
        MsgBox, 48, ¾÷Ã¼Á¤º¸ Á¶È¸, »ç¾÷ÀÚµî·Ï¹øÈ£ ¶Ç´Â ¾÷Ã¼¸í/±â°ü¸íÀ» ÀÔ·ÂÇØ ÁÖ¼¼¿ä.
        return
    }

    if (bizno != "" && StrLen(bizno) != 10)
    {
        MsgBox, 48, ¾÷Ã¼Á¤º¸ Á¶È¸, »ç¾÷ÀÚµî·Ï¹øÈ£´Â ¼ýÀÚ 10ÀÚ¸®¿©¾ß ÇÕ´Ï´Ù.
        return
    }

    if (bizno != "")
    {
        SSOK_CompanyBizNo := bizno
        GuiControl, SSOKCompanyInfo:, SSOK_CompanyBizNo, %bizno%
        GuiControl, SSOKCompanyInfo:, SSOK_CompanyStatus, Á¶È¸ Áß... ±¹¼¼Ã»¡¤Á¶´Þ¾÷Ã¼¡¤¼ö¿ä±â°ü Á¤º¸¸¦ È®ÀÎÇÏ°í ÀÖ½À´Ï´Ù.
        GuiControl, SSOKCompanyInfo:, SSOK_CompanyResult, Á¶È¸ ÁßÀÔ´Ï´Ù...

        result := SSOK_CompanyInfo_QueryAll(bizno, inputName)
    }
    else
    {
        ; ÀÌ¸§¸¸ ÀÔ·ÂÇÑ °æ¿ì Á¶´Þ¾÷Ã¼ ¿ª°Ë»öÀº °ø½Ä »ç¿ëÀÚÁ¤º¸ API°¡ Áö¿øÇÏÁö ¾ÊÁö¸¸
        ; ¼ö¿ä±â°üÀº ¼ö¿ä±â°ü¸í(dminsttNm)À¸·Î °Ë»öÇÒ ¼ö ÀÖ½À´Ï´Ù.
        GuiControl, SSOKCompanyInfo:, SSOK_CompanyStatus, ¼ö¿ä±â°ü¸íÀ¸·Î Á¶´ÞÃ» ¼ö¿ä±â°ü Á¤º¸¸¦ °Ë»öÇÏ°í ÀÖ½À´Ï´Ù.
        GuiControl, SSOKCompanyInfo:, SSOK_CompanyResult, Á¶È¸ ÁßÀÔ´Ï´Ù...

        result := SSOK_CompanyInfo_QueryByName(inputName)
    }

    GuiControl, SSOKCompanyInfo:, SSOK_CompanyResult, %result%
    GuiControl, SSOKCompanyInfo:, SSOK_CompanyStatus, Á¶È¸ ¿Ï·á
return

SSOK_CompanyInfo_Clear:
    SSOK_CompanyBizNo := ""
    SSOK_CompanyName := ""
    GuiControl, SSOKCompanyInfo:, SSOK_CompanyBizNo,
    GuiControl, SSOKCompanyInfo:, SSOK_CompanyName,
    GuiControl, SSOKCompanyInfo:, SSOK_CompanyResult,
    GuiControl, SSOKCompanyInfo:, SSOK_CompanyStatus, »ç¾÷ÀÚ¹øÈ£ ¶Ç´Â ¾÷Ã¼¸í/±â°ü¸íÀ» ÀÔ·ÂÇÏ¼¼¿ä. ÀÌ¸§¸¸ ÀÔ·ÂÇØµµ °Ë»öÇÕ´Ï´Ù. (ÀÌ¸§¸¸ Á¶È¸µµ °¡´É)
return

SSOK_CompanyInfo_OpenNTS:
    SSOK_Tool_OpenUrlPreferred("https://www.data.go.kr/data/15081808/openapi.do")
return

SSOK_CompanyInfo_OpenG2B:
    SSOK_Tool_OpenUrlPreferred("https://www.data.go.kr/data/15129466/openapi.do")
return

SSOK_CompanyInfo_OpenFSC:
    SSOK_Tool_OpenUrlPreferred("https://www.data.go.kr/data/15043184/openapi.do")
return

SSOKCompanyInfoGuiClose:
SSOKCompanyInfoGuiEscape:
    Gui, SSOKCompanyInfo:Destroy
return

SSOK_CompanyInfo_Show()
{
    global SSOK_CompanyBizNo, SSOK_CompanyName
    global SSOK_CompanyResult, SSOK_CompanyStatus

    Gui, SSOKCompanyInfo:Destroy
    Gui, SSOKCompanyInfo:New, +AlwaysOnTop +ToolWindow, ±¹¼¼Ã» ¡¤ Á¶´ÞÃ» ¾÷Ã¼Á¤º¸ Á¶È¸
    Gui, SSOKCompanyInfo:Color, F7FBFF
    Gui, SSOKCompanyInfo:Margin, 14, 12

    Gui, SSOKCompanyInfo:Font, s12 Bold, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Text, x14 y12 w726 h28, ±¹¼¼Ã» ¡¤ Á¶´ÞÃ» ¾÷Ã¼Á¤º¸ Á¶È¸

    Gui, SSOKCompanyInfo:Font, s8 Norm, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Text, x14 y43 w726 h32 c555555, »ç¾÷ÀÚ¹øÈ£´Â ±¹¼¼Ã»¡¤Á¶´ÞÃ»À», ¾÷Ã¼¸í/±â°ü¸íÀº Á¶´ÞÃ» ¼ö¿ä±â°ü + ±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸¸¦ ÇÔ²² Á¶È¸ÇÕ´Ï´Ù.

    Gui, SSOKCompanyInfo:Font, s9 Bold, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Text, x14 y82 w85 h25 +0x200, »ç¾÷ÀÚ¹øÈ£
    Gui, SSOKCompanyInfo:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Edit, x102 y82 w175 h25 vSSOK_CompanyBizNo, %SSOK_CompanyBizNo%

    Gui, SSOKCompanyInfo:Font, s9 Bold, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Text, x286 y82 w90 h25 +0x200, ¾÷Ã¼¸í/±â°ü¸í
    Gui, SSOKCompanyInfo:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Edit, x380 y82 w195 h25 vSSOK_CompanyName, %SSOK_CompanyName%

    Gui, SSOKCompanyInfo:Add, Button, x586 y81 w72 h27 Default gSSOK_CompanyInfo_Search, Á¶È¸
    Gui, SSOKCompanyInfo:Add, Button, x666 y81 w72 h27 gSSOK_CompanyInfo_Clear, ÃÊ±âÈ­

    Gui, SSOKCompanyInfo:Font, s8 Norm, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Text, x14 y116 w724 h24 c005BAC vSSOK_CompanyStatus, »ç¾÷ÀÚ¹øÈ£¸¦ ÀÔ·ÂÇÑ µÚ Á¶È¸ÇÏ¼¼¿ä.

    Gui, SSOKCompanyInfo:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Edit, x14 y143 w724 h405 vSSOK_CompanyResult ReadOnly -Wrap HScroll

    Gui, SSOKCompanyInfo:Font, s8 Norm, Malgun Gothic
    Gui, SSOKCompanyInfo:Add, Button, x14 y558 w125 h27 gSSOK_CompanyInfo_OpenNTS, ±¹¼¼Ã» API Á¤º¸
    Gui, SSOKCompanyInfo:Add, Button, x146 y558 w125 h27 gSSOK_CompanyInfo_OpenG2B, Á¶´ÞÃ» API Á¤º¸
    Gui, SSOKCompanyInfo:Add, Button, x278 y558 w135 h27 gSSOK_CompanyInfo_OpenFSC, ±ÝÀ¶À§ ±â¾÷Á¤º¸
    Gui, SSOKCompanyInfo:Add, Text, x424 y555 w314 h40 c666666, ¡Ø ¾÷Ã¼¸í¸¸ Á¶È¸ÇÒ ¶§´Â ¼ö¿ä±â°ü°ú ±ÝÀ¶À§ ±â¾÷Á¤º¸¸¦ ÇÔ²² °Ë»öÇÕ´Ï´Ù.

    Gui, SSOKCompanyInfo:Show, w752 h600 Center, ±¹¼¼Ã» ¡¤ Á¶´ÞÃ» ¾÷Ã¼Á¤º¸ Á¶È¸
}

SSOK_CompanyInfo_QueryAll(bizno, enteredName := "")
{
    out := ""

    ; ---------------- ±¹¼¼Ã» ----------------
    nts := SSOK_CompanyInfo_QueryNTS(bizno, ntsErr)

    out .= "¡á ±¹¼¼Ã» »ç¾÷ÀÚµî·Ï »óÅÂ`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"

    if (IsObject(nts) && nts.ok)
    {
        out .= "»ç¾÷ÀÚµî·Ï¹øÈ£ : " . SSOK_CompanyInfo_FormatBizNo(bizno) . "`r`n"
        out .= "»ç¾÷ÀÚ»óÅÂ     : " . SSOK_CompanyInfo_ValueOrDash(nts.b_stt) . "`r`n"
        out .= "°ú¼¼À¯Çü       : " . SSOK_CompanyInfo_ValueOrDash(nts.tax_type) . "`r`n"

        if (nts.end_dt != "")
            out .= "Æó¾÷ÀÏ         : " . SSOK_CompanyInfo_FormatDate(nts.end_dt) . "`r`n"
        if (nts.tax_type_change_dt != "")
            out .= "°ú¼¼À¯Çü ÀüÈ¯ÀÏ: " . SSOK_CompanyInfo_FormatDate(nts.tax_type_change_dt) . "`r`n"
        if (nts.invoice_apply_dt != "")
            out .= "¼¼±Ý°è»ê¼­ Àû¿ëÀÏ: " . SSOK_CompanyInfo_FormatDate(nts.invoice_apply_dt) . "`r`n"
        if (nts.rbf_tax_type != "")
            out .= "Á÷Àü °ú¼¼À¯Çü  : " . nts.rbf_tax_type . "`r`n"
    }
    else
        out .= "Á¶È¸ ½ÇÆÐ : " . SSOK_CompanyInfo_ValueOrDash(ntsErr) . "`r`n"

    out .= "`r`n"

    ; ---------------- Á¶´ÞÃ» ±âº»Á¤º¸ ----------------
    basicDoc := SSOK_CompanyInfo_G2BQuery("getPrcrmntCorpBasicInfo02", 3, bizno, basicErr)

    out .= "¡á Á¶´ÞÃ» ³ª¶óÀåÅÍ Á¶´Þ¾÷Ã¼ ±âº»Á¤º¸`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"

    g2bName := ""

    if IsObject(basicDoc)
    {
        item := basicDoc.selectSingleNode("//item")

        if IsObject(item)
        {
            g2bName := SSOK_CompanyInfo_XmlText(item, "corpNm")
            basicBizno := SSOK_CompanyInfo_XmlText(item, "bizno")
            ceoNm := SSOK_CompanyInfo_XmlText(item, "ceoNm")
            rgnNm := SSOK_CompanyInfo_XmlText(item, "rgnNm")
            zip := SSOK_CompanyInfo_XmlText(item, "zip")
            adrs := SSOK_CompanyInfo_XmlText(item, "adrs")
            dtlAdrs := SSOK_CompanyInfo_XmlText(item, "dtlAdrs")
            telNo := SSOK_CompanyInfo_XmlText(item, "telNo")
            faxNo := SSOK_CompanyInfo_XmlText(item, "faxNo")
            corpBsnsDivNm := SSOK_CompanyInfo_XmlText(item, "corpBsnsDivNm")
            mnfctDivNm := SSOK_CompanyInfo_XmlText(item, "mnfctDivNm")
            hdoffceDivNm := SSOK_CompanyInfo_XmlText(item, "hdoffceDivNm")
            opbizDt := SSOK_CompanyInfo_XmlText(item, "opbizDt")
            rgstDt := SSOK_CompanyInfo_XmlText(item, "rgstDt")
            chgDt := SSOK_CompanyInfo_XmlText(item, "chgDt")

            out .= "¾÷Ã¼¸í         : " . SSOK_CompanyInfo_ValueOrDash(g2bName) . "`r`n"
            out .= "»ç¾÷ÀÚµî·Ï¹øÈ£ : " . SSOK_CompanyInfo_FormatBizNo((basicBizno != "") ? basicBizno : bizno) . "`r`n"
            out .= "´ëÇ¥ÀÚ         : " . SSOK_CompanyInfo_ValueOrDash(ceoNm) . "`r`n"
            out .= "Áö¿ª           : " . SSOK_CompanyInfo_ValueOrDash(rgnNm) . "`r`n"
            out .= "ÁÖ¼Ò           : " . SSOK_CompanyInfo_JoinAddress(zip, adrs, dtlAdrs) . "`r`n"
            out .= "ÀüÈ­ / ÆÑ½º    : " . SSOK_CompanyInfo_ValueOrDash(telNo) . " / " . SSOK_CompanyInfo_ValueOrDash(faxNo) . "`r`n"
            out .= "¾÷Ã¼¾÷¹«±¸ºÐ   : " . SSOK_CompanyInfo_ValueOrDash(corpBsnsDivNm) . "`r`n"
            out .= "Á¦Á¶±¸ºÐ       : " . SSOK_CompanyInfo_ValueOrDash(mnfctDivNm) . "`r`n"
            out .= "º»»ç±¸ºÐ       : " . SSOK_CompanyInfo_ValueOrDash(hdoffceDivNm) . "`r`n"

            if (opbizDt != "")
                out .= "°³¾÷ÀÏ         : " . SSOK_CompanyInfo_FormatDate(opbizDt) . "`r`n"
            if (rgstDt != "")
                out .= "³ª¶óÀåÅÍ µî·Ï  : " . SSOK_CompanyInfo_FormatDateTime(rgstDt) . "`r`n"
            if (chgDt != "")
                out .= "ÃÖ±Ù º¯°æ      : " . SSOK_CompanyInfo_FormatDateTime(chgDt) . "`r`n"

            if (enteredName != "")
            {
                nInput := RegExReplace(enteredName, "[\s\(\)¢ßÁÖ½ÄÈ¸»ç]+", "")
                nG2B := RegExReplace(g2bName, "[\s\(\)¢ßÁÖ½ÄÈ¸»ç]+", "")

                if (nG2B != "" && nInput != "" && !InStr(nG2B, nInput) && !InStr(nInput, nG2B))
                    out .= "¡Ø ÀÔ·Â ¾÷Ã¼¸í [" . enteredName . "]°ú Á¶´ÞÃ» µî·Ï ¾÷Ã¼¸íÀÌ ´Ù¸¨´Ï´Ù.`r`n"
                else
                    out .= "¡Ø ÀÔ·Â ¾÷Ã¼¸í°ú Á¶´ÞÃ» µî·Ï ¾÷Ã¼¸íÀÌ ÀÏÄ¡ÇÕ´Ï´Ù.`r`n"
            }
        }
        else
            out .= "³ª¶óÀåÅÍ Á¶´Þ¾÷Ã¼ ±âº»Á¤º¸°¡ Á¶È¸µÇÁö ¾Ê¾Ò½À´Ï´Ù.`r`n"
    }
    else
        out .= "Á¶È¸ ½ÇÆÐ : " . SSOK_CompanyInfo_ValueOrDash(basicErr) . "`r`n"

    out .= "`r`n"

    ; ---------------- Á¶´ÞÃ» ¼ö¿ä±â°üÁ¤º¸ ----------------
    out .= "¡á Á¶´ÞÃ» ¼ö¿ä±â°üÁ¤º¸`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"

    if (enteredName != "")
    {
        demandDoc := SSOK_CompanyInfo_G2BDemandQuery(enteredName, demandErr)

        if IsObject(demandDoc)
        {
            nodes := demandDoc.selectNodes("//item")
            dcnt := nodes.length

            if (dcnt <= 0)
                out .= "ÀÔ·ÂÇÑ ±â°ü¸íÀ¸·Î Á¶È¸µÇ´Â ¼ö¿ä±â°üÀÌ ¾ø½À´Ï´Ù.`r`n"
            else
            {
                showD := (dcnt > 8) ? 8 : dcnt

                Loop, %showD%
                {
                    dnode := nodes.item(A_Index - 1)

                    dNm := SSOK_CompanyInfo_XmlFirstText(dnode, "dminsttNm|insttNm")
                    dCd := SSOK_CompanyInfo_XmlFirstText(dnode, "dminsttCd|insttCd")
                    dDiv := SSOK_CompanyInfo_XmlFirstText(dnode, "dminsttDivNm|dminsttClsfcNm|insttDivNm|jurisdctnDivNm")
                    dRgn := SSOK_CompanyInfo_XmlFirstText(dnode, "rgnNm|areaNm")
                    dZip := SSOK_CompanyInfo_XmlFirstText(dnode, "zip|zipNo")
                    dAdrs := SSOK_CompanyInfo_XmlFirstText(dnode, "adrs|addr")
                    dDtl := SSOK_CompanyInfo_XmlFirstText(dnode, "dtlAdrs|dtlAddr")
                    dTopCd := SSOK_CompanyInfo_XmlFirstText(dnode, "topInsttCd|topDminsttCd")
                    dTopNm := SSOK_CompanyInfo_XmlFirstText(dnode, "topInsttNm|topDminsttNm")
                    dTel := SSOK_CompanyInfo_XmlFirstText(dnode, "telNo|tel")
                    dFax := SSOK_CompanyInfo_XmlFirstText(dnode, "faxNo|fax")

                    out .= "[" . A_Index . "] ±â°ü¸í : " . SSOK_CompanyInfo_ValueOrDash(dNm) . "`r`n"

                    if (dCd != "")
                        out .= "    ¼ö¿ä±â°üÄÚµå : " . dCd . "`r`n"
                    if (dDiv != "")
                        out .= "    ¼Ò°ü/±¸ºÐ    : " . dDiv . "`r`n"
                    if (dRgn != "")
                        out .= "    Áö¿ª         : " . dRgn . "`r`n"

                    dFullAddr := SSOK_CompanyInfo_JoinAddress(dZip, dAdrs, dDtl)
                    if (dFullAddr != "-")
                        out .= "    ÁÖ¼Ò         : " . dFullAddr . "`r`n"

                    if (dTopNm != "" || dTopCd != "")
                        out .= "    ÃÖ»óÀ§±â°ü   : " . SSOK_CompanyInfo_ValueOrDash(dTopNm)
                            . (dTopCd != "" ? " [" . dTopCd . "]" : "") . "`r`n"

                    if (dTel != "" || dFax != "")
                        out .= "    ÀüÈ­ / ÆÑ½º  : " . SSOK_CompanyInfo_ValueOrDash(dTel)
                            . " / " . SSOK_CompanyInfo_ValueOrDash(dFax) . "`r`n"

                    if (A_Index < showD)
                        out .= "`r`n"
                }

                if (dcnt > showD)
                    out .= "`r`n¿Ü " . (dcnt - showD) . "°Ç`r`n"
            }
        }
        else
            out .= "Á¶È¸ ½ÇÆÐ : " . SSOK_CompanyInfo_ValueOrDash(demandErr) . "`r`n"
    }
    else
    {
        out .= "±â°ü¸íÀ» ÇÔ²² ÀÔ·ÂÇÏ¸é ³ª¶óÀåÅÍ ¼ö¿ä±â°üÁ¤º¸¸¦ °Ë»öÇÕ´Ï´Ù.`r`n"
        out .= "¡Ø ¼ö¿ä±â°üÁ¤º¸ API´Â ±â°ü¸í ±âÁØ °Ë»öÀ» Áö¿øÇÕ´Ï´Ù.`r`n"
    }

    out .= "`r`n"

    ; ---------------- ±ÝÀ¶À§¿øÈ¸ ±â¾÷±âº»Á¤º¸ ----------------
    out .= "¡á ±ÝÀ¶À§¿øÈ¸ ±â¾÷±âº»Á¤º¸`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"

    if (enteredName != "")
        out .= SSOK_CompanyInfo_FSCResultText(enteredName, bizno)
    else
        out .= "¾÷Ã¼¸íÀ» ÇÔ²² ÀÔ·ÂÇÏ¸é ±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸¸¦ Ãß°¡ Á¶È¸ÇÕ´Ï´Ù.`r`n"

    out .= "`r`n"

    ; ---------------- Á¶´ÞÃ» µî·Ï¾÷Á¾ ----------------
    industryDoc := SSOK_CompanyInfo_G2BQuery("getPrcrmntCorpIndstrytyInfo02", 1, bizno, industryErr)

    out .= "¡á Á¶´ÞÃ» µî·Ï¾÷Á¾`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"

    if IsObject(industryDoc)
    {
        nodes := industryDoc.selectNodes("//item")
        cnt := nodes.length

        if (cnt <= 0)
            out .= "µî·Ï¾÷Á¾ Á¤º¸°¡ Á¶È¸µÇÁö ¾Ê¾Ò½À´Ï´Ù.`r`n"
        else
        {
            showCnt := (cnt > 15) ? 15 : cnt

            Loop, %showCnt%
            {
                node := nodes.item(A_Index - 1)
                cd := SSOK_CompanyInfo_XmlText(node, "indstrytyCd")
                nm := SSOK_CompanyInfo_XmlText(node, "indstrytyNm")
                stats := SSOK_CompanyInfo_XmlText(node, "indstrytyStatsNm")
                expiry := SSOK_CompanyInfo_XmlText(node, "vldPrdExprtDt")
                rep := SSOK_CompanyInfo_XmlText(node, "rprsntIndstrytyYn")

                line := A_Index . ". [" . SSOK_CompanyInfo_ValueOrDash(cd) . "] " . SSOK_CompanyInfo_ValueOrDash(nm)

                if (stats != "")
                    line .= " / " . stats
                if (expiry != "")
                    line .= " / À¯È¿±â°£ " . SSOK_CompanyInfo_FormatDate(expiry)
                if (rep = "Y")
                    line .= " / ´ëÇ¥¾÷Á¾"

                out .= line . "`r`n"
            }

            if (cnt > showCnt)
                out .= "¿Ü " . (cnt - showCnt) . "°Ç`r`n"
        }
    }
    else
        out .= "Á¶È¸ ½ÇÆÐ : " . SSOK_CompanyInfo_ValueOrDash(industryErr) . "`r`n"

    out .= "`r`n"

    ; ---------------- Á¶´ÞÃ» ºÎÁ¤´ç Á¦Àç ----------------
    sanctionDoc := SSOK_CompanyInfo_G2BQuery("getUnptRsttCorpInfo02", 1, bizno, sanctionErr)

    out .= "¡á Á¶´ÞÃ» ºÎÁ¤´ç Á¦Àç¾÷Ã¼ Á¤º¸`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"

    if IsObject(sanctionDoc)
    {
        nodes := sanctionDoc.selectNodes("//item")
        cnt := nodes.length

        if (cnt <= 0)
        {
            out .= "ÇöÀç À¯È¿ÇÑ ºÎÁ¤´ç Á¦Àç : ¾øÀ½`r`n"
            out .= "¡Ø ÇöÀç Á¶È¸µÇ´Â À¯È¿ Á¦Àç°¡ ¾ø´Ù´Â ¶æÀÌ¸ç, °ú°Å ¸¸·á¡¤ÇØÁ¦ Á¦ÀçÀÇ Á¸Àç ¿©ºÎ±îÁö ÀÇ¹ÌÇÏÁö´Â ¾Ê½À´Ï´Ù.`r`n"
        }
        else
        {
            out .= "ÇöÀç À¯È¿ÇÑ ºÎÁ¤´ç Á¦Àç : ÀÖÀ½ (" . cnt . "°Ç)`r`n"

            showCnt := (cnt > 10) ? 10 : cnt

            Loop, %showCnt%
            {
                node := nodes.item(A_Index - 1)

                sCorp := SSOK_CompanyInfo_XmlText(node, "corpNm")
                sBegin := SSOK_CompanyInfo_XmlText(node, "rsttBgnDate")
                sEnd := SSOK_CompanyInfo_XmlText(node, "rsttEndDate")
                sInst := SSOK_CompanyInfo_XmlText(node, "insttNm")
                sLaw := SSOK_CompanyInfo_XmlText(node, "lawordNm")
                sClause := SSOK_CompanyInfo_XmlText(node, "lawordArtclClause")
                sProgress := SSOK_CompanyInfo_XmlText(node, "rsttProgrsNm")

                out .= "`r`n[" . A_Index . "] " . SSOK_CompanyInfo_ValueOrDash(sCorp) . "`r`n"
                out .= "Á¦Àç±â°£ : " . SSOK_CompanyInfo_FormatDate(sBegin) . " ~ " . SSOK_CompanyInfo_FormatDate(sEnd) . "`r`n"
                out .= "Á¦Àç±â°ü : " . SSOK_CompanyInfo_ValueOrDash(sInst) . "`r`n"
                out .= "±Ù°Å¹ý·É : " . SSOK_CompanyInfo_ValueOrDash(sLaw)

                if (sClause != "")
                    out .= " " . sClause

                out .= "`r`n"
                out .= "Á¦Àç»óÅÂ : " . SSOK_CompanyInfo_ValueOrDash(sProgress) . "`r`n"
            }
        }
    }
    else
        out .= "Á¶È¸ ½ÇÆÐ : " . SSOK_CompanyInfo_ValueOrDash(sanctionErr) . "`r`n"

    out .= "`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"
    out .= "ÃâÃ³: ±¹¼¼Ã» »ç¾÷ÀÚµî·ÏÁ¤º¸ »óÅÂÁ¶È¸ / Á¶´ÞÃ» ³ª¶óÀåÅÍ »ç¿ëÀÚÁ¤º¸¼­ºñ½º`r`n"
    out .= "Á¶È¸ »ç¾÷ÀÚ¹øÈ£: " . SSOK_CompanyInfo_FormatBizNo(bizno)

    return out
}

SSOK_CompanyInfo_QueryByName(name)
{
    out := ""

    ; ==========================================================
    ; 1. Á¶´ÞÃ» ¼ö¿ä±â°ü¸í °Ë»ö
    ; ==========================================================
    out .= "¡á Á¶´ÞÃ» ¼ö¿ä±â°ü¸í °Ë»ö`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"
    out .= "°Ë»ö¾î : " . name . "`r`n`r`n"

    demandDoc := SSOK_CompanyInfo_G2BDemandQuery(name, demandErr)

    if IsObject(demandDoc)
    {
        nodes := demandDoc.selectNodes("//item")
        cnt := nodes.length

        if (cnt <= 0)
            out .= "ÀÏÄ¡ÇÏ´Â ¼ö¿ä±â°üÀ» Ã£Áö ¸øÇß½À´Ï´Ù.`r`n"
        else
        {
            showCnt := (cnt > 15) ? 15 : cnt

            Loop, %showCnt%
            {
                node := nodes.item(A_Index - 1)

                nm := SSOK_CompanyInfo_XmlFirstText(node, "dminsttNm|insttNm")
                cd := SSOK_CompanyInfo_XmlFirstText(node, "dminsttCd|insttCd")
                divNm := SSOK_CompanyInfo_XmlFirstText(node, "dminsttDivNm|dminsttClsfcNm|insttDivNm|jurisdctnDivNm")
                rgn := SSOK_CompanyInfo_XmlFirstText(node, "rgnNm|areaNm")
                zip := SSOK_CompanyInfo_XmlFirstText(node, "zip|zipNo")
                adrs := SSOK_CompanyInfo_XmlFirstText(node, "adrs|addr")
                dtl := SSOK_CompanyInfo_XmlFirstText(node, "dtlAdrs|dtlAddr")
                topCd := SSOK_CompanyInfo_XmlFirstText(node, "topInsttCd|topDminsttCd")
                topNm := SSOK_CompanyInfo_XmlFirstText(node, "topInsttNm|topDminsttNm")

                out .= "[" . A_Index . "] " . SSOK_CompanyInfo_ValueOrDash(nm) . "`r`n"

                if (cd != "")
                    out .= "    ¼ö¿ä±â°üÄÚµå : " . cd . "`r`n"
                if (divNm != "")
                    out .= "    ¼Ò°ü/±¸ºÐ    : " . divNm . "`r`n"
                if (rgn != "")
                    out .= "    Áö¿ª         : " . rgn . "`r`n"

                fullAddr := SSOK_CompanyInfo_JoinAddress(zip, adrs, dtl)
                if (fullAddr != "-")
                    out .= "    ÁÖ¼Ò         : " . fullAddr . "`r`n"

                if (topNm != "" || topCd != "")
                    out .= "    ÃÖ»óÀ§±â°ü   : " . SSOK_CompanyInfo_ValueOrDash(topNm)
                        . (topCd != "" ? " [" . topCd . "]" : "") . "`r`n"

                if (A_Index < showCnt)
                    out .= "`r`n"
            }

            if (cnt > showCnt)
                out .= "`r`n¿Ü " . (cnt - showCnt) . "°Ç`r`n"
        }
    }
    else
        out .= "Á¶È¸ ½ÇÆÐ : " . SSOK_CompanyInfo_ValueOrDash(demandErr) . "`r`n"

    ; ==========================================================
    ; 2. ±ÝÀ¶À§¿øÈ¸ ±â¾÷±âº»Á¤º¸
    ; ==========================================================
    out .= "`r`n"
    out .= "¡á ±ÝÀ¶À§¿øÈ¸ ±â¾÷±âº»Á¤º¸`r`n"
    out .= "¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"
    out .= SSOK_CompanyInfo_FSCResultText(name)

    out .= "`r`n¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡`r`n"
    out .= "¡Ø ±â°ü¸íÀº Á¶´ÞÃ» ¼ö¿ä±â°ü¿¡¼­, ÀÏ¹Ý ¹ýÀÎ¸íÀº ±ÝÀ¶À§¿øÈ¸ ±â¾÷±âº»Á¤º¸¿¡¼­ Ã£½À´Ï´Ù.`r`n"
    out .= "¡Ø ±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸´Â ½Ç½Ã°£ ÀÚ·á°¡ ¾Æ´Ï¶ó ÀÏ ´ÜÀ§·Î °»½ÅµË´Ï´Ù."

    return out
}

SSOK_CompanyInfo_G2BDemandQuery(name, ByRef errMsg)
{
    errMsg := ""

    ; getDminsttInfo02´Â Á¶È¸±¸ºÐ(inqryDiv)ÀÌ ÇÊ¼öÀÔ´Ï´Ù.
    ; ±â°ü¸í °Ë»ö¿ë Á¶È¸±¸ºÐÀ» ¿ì¼± È£ÃâÇÏ°í,
    ; API Ãø Á¶È¸±¸ºÐ Á¤ÀÇ°¡ ´Þ¶óÁø °æ¿ì ÇÊ¼ö°ª ¿À·ù(08/10)¿¡ ÇÑÇØ¼­¸¸
    ; ÈÄº¸ Á¶È¸±¸ºÐÀ» ¼øÂ÷ È®ÀÎÇÏ¿© ½ÇÁ¦ ±â°ü¸íÀÌ °Ë»öµÇ´Â Á¤»óÀÀ´ä¸¸ »ç¿ëÇÕ´Ï´Ù.
    modes := ["2", "1", "3", "4"]

    firstNormalDoc := ""
    lastErr := ""

    for _, mode in modes
    {
        doc := SSOK_CompanyInfo_G2BDemandRequest(name, mode, resultCode, resultMsg)

        if !IsObject(doc)
        {
            if (resultMsg != "")
                lastErr := resultMsg
            continue
        }

        ; ÇÊ¼ö°ª/Á¶È¸Á¶°Ç ¿À·ùÀÌ¸é ´ÙÀ½ Á¶È¸±¸ºÐÀ» È®ÀÎ
        if (resultCode = "08" || resultCode = "10" || resultCode = "11" || resultCode = "12")
        {
            lastErr := "Á¶´ÞÃ» ¼ö¿ä±â°ü API ¿À·ù [" . resultCode . "] " . resultMsg
            continue
        }

        ; µ¥ÀÌÅÍ ¾øÀ½Àº Á¤»óÀûÀÎ ºó °á°ú
        if (resultCode = "03" || resultCode = "07")
        {
            if !IsObject(firstNormalDoc)
                firstNormalDoc := doc
            continue
        }

        if (resultCode != "" && resultCode != "00" && resultCode != "0")
        {
            lastErr := "Á¶´ÞÃ» ¼ö¿ä±â°ü API ¿À·ù [" . resultCode . "] " . resultMsg
            continue
        }

        if !IsObject(firstNormalDoc)
            firstNormalDoc := doc

        ; ½ÇÁ¦ ¹ÝÈ¯ ±â°ü¸í Áß °Ë»ö¾î¿Í ´ëÀÀÇÏ´Â Ç×¸ñÀÌ ÀÖÀ¸¸é ÀÌ Á¶È¸±¸ºÐÀÌ ¸ÂÀ½
        if SSOK_CompanyInfo_DemandHasNameMatch(doc, name)
            return doc

        ; Á¤»ó 0°ÇÀÌ¸é ´Ù¸¥ Á¶È¸±¸ºÐ±îÁö È®ÀÎÇØ º»´Ù.
        nodes := doc.selectNodes("//item")
        if (nodes.length <= 0)
            continue
    }

    if IsObject(firstNormalDoc)
        return firstNormalDoc

    if (lastErr = "")
        lastErr := "Á¶´ÞÃ» ¼ö¿ä±â°ü Á¤º¸¸¦ Á¶È¸ÇÏÁö ¸øÇß½À´Ï´Ù."

    errMsg := lastErr
    return ""

}

SSOK_CompanyInfo_G2BDemandRequest(name, inqryDiv, ByRef resultCode, ByRef resultMsg)
{
    resultCode := ""
    resultMsg := ""

    key := SSOK_CompanyInfo_GetServiceKey()

    url := "https://apis.data.go.kr/1230000/ao/UsrInfoService02/getDminsttInfo02"
        . "?serviceKey=" . SSOK_Tool_QU_UrlEncode(key)
        . "&numOfRows=100"
        . "&pageNo=1"
        . "&type=xml"
        . "&inqryDiv=" . inqryDiv
        . "&dminsttNm=" . SSOK_Tool_QU_UrlEncode(name)

    try
    {
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(4000, 4000, 8000, 8000)
        req.Open("GET", url, false)
        req.SetRequestHeader("Accept", "application/xml,text/xml,*/*")
        req.Send()

        httpStatus := req.Status
        body := req.ResponseText . ""
    }
    catch e
    {
        resultMsg := "Á¶´ÞÃ» ¼ö¿ä±â°ü API È£Ãâ ½ÇÆÐ: " . e.Message
        return ""
    }

    if (httpStatus < 200 || httpStatus >= 300)
    {
        resultMsg := "Á¶´ÞÃ» ¼ö¿ä±â°ü API ÀÀ´ä ¿À·ù: HTTP " . httpStatus
        return ""
    }

    try
    {
        doc := ComObjCreate("MSXML2.DOMDocument.6.0")
        doc.async := false
        doc.validateOnParse := false

        if !doc.loadXML(body)
        {
            resultMsg := "Á¶´ÞÃ» ¼ö¿ä±â°ü API XML ÀÀ´äÀ» ÇØ¼®ÇÏÁö ¸øÇß½À´Ï´Ù."
            return ""
        }

        codeNode := doc.selectSingleNode("//resultCode")
        msgNode := doc.selectSingleNode("//resultMsg")

        resultCode := IsObject(codeNode) ? Trim(codeNode.text . "") : ""
        resultMsg := IsObject(msgNode) ? Trim(msgNode.text . "") : ""

        return doc
    }
    catch e
    {
        resultMsg := "Á¶´ÞÃ» ¼ö¿ä±â°ü API ÀÀ´ä Ã³¸® ½ÇÆÐ: " . e.Message
        return ""
    }
}

SSOK_CompanyInfo_DemandHasNameMatch(doc, searchName)
{
    if !IsObject(doc)
        return false

    needle := SSOK_CompanyInfo_NormalizeName(searchName)

    if (needle = "")
        return false

    nodes := doc.selectNodes("//item")

    Loop, % nodes.length
    {
        node := nodes.item(A_Index - 1)
        nm := SSOK_CompanyInfo_XmlFirstText(node, "dminsttNm|insttNm")
        hay := SSOK_CompanyInfo_NormalizeName(nm)

        if (hay != "" && (InStr(hay, needle) || InStr(needle, hay)))
            return true
    }

    return false
}

SSOK_CompanyInfo_XmlFirstText(parentNode, tagNames)
{
    if !IsObject(parentNode)
        return ""

    Loop, Parse, tagNames, |
    {
        tag := A_LoopField
        try
            node := parentNode.selectSingleNode("./" . tag)
        catch
            node := ""

        if IsObject(node)
        {
            value := Trim(node.text . "")
            if (value != "")
                return value
        }
    }

    return ""
}

SSOK_CompanyInfo_FSCResultText(name, compareBizNo := "")
{
    doc := SSOK_CompanyInfo_FSCQueryByName(name, errMsg)

    if !IsObject(doc)
        return "Á¶È¸ ½ÇÆÐ : " . SSOK_CompanyInfo_ValueOrDash(errMsg) . "`r`n"

    nodes := doc.selectNodes("//item")
    cnt := nodes.length

    if (cnt <= 0)
        return "ÀÏÄ¡ÇÏ´Â ±â¾÷Á¤º¸¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`r`n"

    out := ""
    seen := {}
    shown := 0
    compareBizNo := RegExReplace(compareBizNo . "", "\D", "")

    Loop, % cnt
    {
        node := nodes.item(A_Index - 1)

        corpNm := SSOK_CompanyInfo_XmlFirstText(node, "corpNm")
        crno := SSOK_CompanyInfo_XmlFirstText(node, "crno")
        bzno := SSOK_CompanyInfo_XmlFirstText(node, "bzno")

        dedupKey := corpNm . "|" . crno . "|" . bzno

        if seen.HasKey(dedupKey)
            continue

        seen[dedupKey] := true
        shown++

        if (shown > 10)
            break

        rpr := SSOK_CompanyInfo_XmlFirstText(node, "enpRprFnm")
        corpType := SSOK_CompanyInfo_XmlFirstText(node, "corpDcdNm")
        market := SSOK_CompanyInfo_XmlFirstText(node, "corpRegMrktDcdNm")
        estbDt := SSOK_CompanyInfo_XmlFirstText(node, "enpEstbDt")
        sicNm := SSOK_CompanyInfo_XmlFirstText(node, "sicNm")
        mainBiz := SSOK_CompanyInfo_XmlFirstText(node, "enpMainBizNm")
        zip := SSOK_CompanyInfo_XmlFirstText(node, "enpOzpno")
        addr := SSOK_CompanyInfo_XmlFirstText(node, "enpBsadr")
        dtlAddr := SSOK_CompanyInfo_XmlFirstText(node, "enpDtadr")
        tel := SSOK_CompanyInfo_XmlFirstText(node, "enpTlno")
        homepage := SSOK_CompanyInfo_XmlFirstText(node, "enpHmpgUrl")
        empCnt := SSOK_CompanyInfo_XmlFirstText(node, "enpEmpeCnt")

        out .= "[" . shown . "] " . SSOK_CompanyInfo_ValueOrDash(corpNm) . "`r`n"

        if (bzno != "")
        {
            out .= "    »ç¾÷ÀÚ¹øÈ£   : " . SSOK_CompanyInfo_FormatBizNo(bzno)

            if (compareBizNo != "")
            {
                if (RegExReplace(bzno, "\D", "") = compareBizNo)
                    out .= "  [ÀÔ·Â »ç¾÷ÀÚ¹øÈ£¿Í ÀÏÄ¡]"
                else
                    out .= "  [ÀÔ·Â »ç¾÷ÀÚ¹øÈ£¿Í ´Ù¸§]"
            }

            out .= "`r`n"
        }

        if (crno != "")
            out .= "    ¹ýÀÎµî·Ï¹øÈ£ : " . crno . "`r`n"
        if (rpr != "")
            out .= "    ´ëÇ¥ÀÚ       : " . rpr . "`r`n"
        if (corpType != "")
            out .= "    ¹ýÀÎ±¸ºÐ     : " . corpType . "`r`n"
        if (market != "")
            out .= "    ½ÃÀå±¸ºÐ     : " . market . "`r`n"
        if (estbDt != "")
            out .= "    ¼³¸³ÀÏ       : " . SSOK_CompanyInfo_FormatDate(estbDt) . "`r`n"
        if (sicNm != "")
            out .= "    ¾÷Á¾         : " . sicNm . "`r`n"
        if (mainBiz != "")
            out .= "    ÁÖ¿ä»ç¾÷     : " . mainBiz . "`r`n"

        fullAddr := SSOK_CompanyInfo_JoinAddress(zip, addr, dtlAddr)
        if (fullAddr != "-")
            out .= "    ÁÖ¼Ò         : " . fullAddr . "`r`n"

        if (tel != "")
            out .= "    ÀüÈ­         : " . tel . "`r`n"
        if (homepage != "")
            out .= "    È¨ÆäÀÌÁö     : " . homepage . "`r`n"
        if (empCnt != "" && empCnt != "0")
            out .= "    Á¾¾÷¿ø¼ö     : " . empCnt . "`r`n"

        out .= "`r`n"
    }

    if (shown = 0)
        return "ÀÏÄ¡ÇÏ´Â ±â¾÷Á¤º¸¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`r`n"

    if (shown > 10)
        out .= "¿Ü Ãß°¡ °á°ú°¡ ÀÖ½À´Ï´Ù.`r`n"

    return out
}

SSOK_CompanyInfo_FSCQueryByName(name, ByRef errMsg)
{
    errMsg := ""
    key := SSOK_CompanyInfo_GetServiceKey()

    base := "https://apis.data.go.kr/1160100/service/GetCorpBasicInfoService_V2/getCorpOutline_V2"

    url := base
        . "?ServiceKey=" . SSOK_Tool_QU_UrlEncode(key)
        . "&pageNo=1"
        . "&numOfRows=100"
        . "&resultType=xml"
        . "&corpNm=" . SSOK_Tool_QU_UrlEncode(name)

    doc := SSOK_CompanyInfo_FSCRequestXml(url, firstErr)

    if IsObject(doc)
        return doc

    ; ÀÏºÎ È¯°æ¿¡¼­ resultType °ª Ã³¸® ¹æ½ÄÀÌ ´Ù¸¥ °æ¿ì ±âº» XML·Î ÇÑ ¹ø ´õ ½Ãµµ
    url2 := base
        . "?ServiceKey=" . SSOK_Tool_QU_UrlEncode(key)
        . "&pageNo=1"
        . "&numOfRows=100"
        . "&corpNm=" . SSOK_Tool_QU_UrlEncode(name)

    doc := SSOK_CompanyInfo_FSCRequestXml(url2, secondErr)

    if IsObject(doc)
        return doc

    errMsg := (secondErr != "") ? secondErr : firstErr
    return ""
}

SSOK_CompanyInfo_FSCRequestXml(url, ByRef errMsg)
{
    errMsg := ""

    try
    {
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(4000, 4000, 8000, 8000)
        req.Open("GET", url, false)
        req.SetRequestHeader("Accept", "application/xml,text/xml,*/*")
        req.Send()

        httpStatus := req.Status
        body := req.ResponseText . ""
    }
    catch e
    {
        errMsg := "±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸ API È£Ãâ ½ÇÆÐ: " . e.Message
        return ""
    }

    if (httpStatus < 200 || httpStatus >= 300)
    {
        errMsg := "±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸ API ÀÀ´ä ¿À·ù: HTTP " . httpStatus
        return ""
    }

    try
    {
        doc := ComObjCreate("MSXML2.DOMDocument.6.0")
        doc.async := false
        doc.validateOnParse := false

        if !doc.loadXML(body)
        {
            errMsg := "±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸ XML ÀÀ´äÀ» ÇØ¼®ÇÏÁö ¸øÇß½À´Ï´Ù."
            return ""
        }

        codeNode := doc.selectSingleNode("//resultCode")
        msgNode := doc.selectSingleNode("//resultMsg")

        resultCode := IsObject(codeNode) ? Trim(codeNode.text . "") : ""
        resultMsg := IsObject(msgNode) ? Trim(msgNode.text . "") : ""

        if (resultCode != "" && resultCode != "00" && resultCode != "0")
        {
            errMsg := "±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸ API ¿À·ù [" . resultCode . "] " . resultMsg

            if (resultCode = "20" || resultCode = "30" || resultCode = "31")
                errMsg .= " / °ø°øµ¥ÀÌÅÍÆ÷ÅÐ¿¡¼­ ±ÝÀ¶À§¿øÈ¸_±â¾÷±âº»Á¤º¸ È°¿ë½ÅÃ» »óÅÂ¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä."

            return ""
        }

        return doc
    }
    catch e
    {
        errMsg := "±ÝÀ¶À§¿øÈ¸ ±â¾÷Á¤º¸ ÀÀ´ä Ã³¸® ½ÇÆÐ: " . e.Message
        return ""
    }
}

SSOK_CompanyInfo_NormalizeName(value)
{
    s := Trim(value . "")
    s := RegExReplace(s, "\s+", "")
    s := StrReplace(s, "(ÁÖ)", "")
    s := StrReplace(s, "¢ß", "")
    s := StrReplace(s, "ÁÖ½ÄÈ¸»ç", "")
    s := StrReplace(s, "£¨ÁÖ£©", "")
    return s
}


SSOK_CompanyInfo_GetServiceKey()
{
    return "230ae6fe40480dce9f264334da7b436e300be9d6ce2ba45772563b6eb5a42854"
}

SSOK_CompanyInfo_QueryNTS(bizno, ByRef errMsg)
{
    errMsg := ""
    key := SSOK_CompanyInfo_GetServiceKey()
    url := "https://api.odcloud.kr/api/nts-businessman/v1/status?serviceKey=" . SSOK_Tool_QU_UrlEncode(key)

    dq := Chr(34)
    payload := "{" . dq . "b_no" . dq . ":[" . dq . bizno . dq . "]}"

    try
    {
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(4000, 4000, 8000, 8000)
        req.Open("POST", url, false)
        req.SetRequestHeader("Content-Type", "application/json")
        req.SetRequestHeader("Accept", "application/json")
        req.Send(payload)

        httpStatus := req.Status
        body := req.ResponseText . ""
    }
    catch e
    {
        errMsg := "±¹¼¼Ã» API È£Ãâ ½ÇÆÐ: " . e.Message
        return {ok:false}
    }

    if (httpStatus < 200 || httpStatus >= 300)
    {
        errMsg := "±¹¼¼Ã» API ÀÀ´ä ¿À·ù: HTTP " . httpStatus
        return {ok:false}
    }

    statusCode := SSOK_CompanyInfo_JsonString(body, "status_code")

    if (statusCode != "" && statusCode != "OK")
    {
        errMsg := "±¹¼¼Ã» API »óÅÂ: " . statusCode
        return {ok:false}
    }

    bNo := SSOK_CompanyInfo_JsonString(body, "b_no")
    bStt := SSOK_CompanyInfo_JsonString(body, "b_stt")
    taxType := SSOK_CompanyInfo_JsonString(body, "tax_type")
    endDt := SSOK_CompanyInfo_JsonString(body, "end_dt")
    taxChangeDt := SSOK_CompanyInfo_JsonString(body, "tax_type_change_dt")
    invoiceDt := SSOK_CompanyInfo_JsonString(body, "invoice_apply_dt")
    rbfTaxType := SSOK_CompanyInfo_JsonString(body, "rbf_tax_type")

    if (bNo = "" && bStt = "" && taxType = "")
    {
        errMsg := "»ç¾÷ÀÚ »óÅÂÁ¤º¸¸¦ È®ÀÎÇÒ ¼ö ¾ø½À´Ï´Ù."
        return {ok:false}
    }

    return {ok:true
        , b_no:bNo
        , b_stt:bStt
        , tax_type:taxType
        , end_dt:endDt
        , tax_type_change_dt:taxChangeDt
        , invoice_apply_dt:invoiceDt
        , rbf_tax_type:rbfTaxType}
}

SSOK_CompanyInfo_G2BQuery(operation, inqryDiv, bizno, ByRef errMsg)
{
    errMsg := ""
    key := SSOK_CompanyInfo_GetServiceKey()

    url := "https://apis.data.go.kr/1230000/ao/UsrInfoService02/" . operation
        . "?serviceKey=" . SSOK_Tool_QU_UrlEncode(key)
        . "&numOfRows=100&pageNo=1"
        . "&inqryDiv=" . inqryDiv
        . "&bizno=" . bizno

    try
    {
        req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(4000, 4000, 8000, 8000)
        req.Open("GET", url, false)
        req.SetRequestHeader("Accept", "application/xml,text/xml,*/*")
        req.Send()

        httpStatus := req.Status
        body := req.ResponseText . ""
    }
    catch e
    {
        errMsg := "Á¶´ÞÃ» API È£Ãâ ½ÇÆÐ: " . e.Message
        return ""
    }

    if (httpStatus < 200 || httpStatus >= 300)
    {
        errMsg := "Á¶´ÞÃ» API ÀÀ´ä ¿À·ù: HTTP " . httpStatus
        return ""
    }

    try
    {
        doc := ComObjCreate("MSXML2.DOMDocument.6.0")
        doc.async := false
        doc.validateOnParse := false

        if !doc.loadXML(body)
        {
            errMsg := "Á¶´ÞÃ» API XML ÀÀ´äÀ» ÇØ¼®ÇÏÁö ¸øÇß½À´Ï´Ù."
            return ""
        }

        codeNode := doc.selectSingleNode("//resultCode")
        msgNode := doc.selectSingleNode("//resultMsg")

        resultCode := IsObject(codeNode) ? Trim(codeNode.text . "") : ""
        resultMsg := IsObject(msgNode) ? Trim(msgNode.text . "") : ""

        if (resultCode != "" && resultCode != "00" && resultCode != "0")
        {
            errMsg := "Á¶´ÞÃ» API ¿À·ù [" . resultCode . "] " . resultMsg

            if (resultCode = "20" || resultCode = "30")
                errMsg .= " / °ø°øµ¥ÀÌÅÍÆ÷ÅÐ¿¡¼­ Á¶´ÞÃ» API È°¿ë½ÅÃ» ½ÂÀÎ »óÅÂ¸¦ È®ÀÎÇØ ÁÖ¼¼¿ä."

            return ""
        }

        return doc
    }
    catch e
    {
        errMsg := "Á¶´ÞÃ» API ÀÀ´ä Ã³¸® ½ÇÆÐ: " . e.Message
        return ""
    }
}

SSOK_CompanyInfo_XmlText(parentNode, tagName)
{
    if !IsObject(parentNode)
        return ""

    try
        node := parentNode.selectSingleNode("./" . tagName)
    catch
        return ""

    if !IsObject(node)
        return ""

    return Trim(node.text . "")
}

SSOK_CompanyInfo_JsonString(json, key)
{
    dq := Chr(34)
    pattern := dq . key . dq . "\s*:\s*" . dq . "((?:\\.|[^" . dq . "])*)" . dq

    if !RegExMatch(json, pattern, m)
        return ""

    v := m1
    v := StrReplace(v, "\" . dq, dq)
    v := StrReplace(v, "\/", "/")
    v := StrReplace(v, "\r", "`r")
    v := StrReplace(v, "\n", "`n")
    v := StrReplace(v, "\t", "`t")
    v := StrReplace(v, "\\", "\")

    return v
}

SSOK_CompanyInfo_FormatBizNo(value)
{
    s := RegExReplace(value . "", "\D", "")

    if (StrLen(s) = 10)
        return SubStr(s, 1, 3) . "-" . SubStr(s, 4, 2) . "-" . SubStr(s, 6, 5)

    return value
}

SSOK_CompanyInfo_FormatDate(value)
{
    s := RegExReplace(value . "", "\D", "")

    if (StrLen(s) >= 8)
        return SubStr(s, 1, 4) . "." . SubStr(s, 5, 2) . "." . SubStr(s, 7, 2)

    return (value != "") ? value : "-"
}

SSOK_CompanyInfo_FormatDateTime(value)
{
    s := RegExReplace(value . "", "\D", "")

    if (StrLen(s) >= 14)
        return SubStr(s, 1, 4) . "." . SubStr(s, 5, 2) . "." . SubStr(s, 7, 2)
            . " " . SubStr(s, 9, 2) . ":" . SubStr(s, 11, 2) . ":" . SubStr(s, 13, 2)

    return SSOK_CompanyInfo_FormatDate(value)
}

SSOK_CompanyInfo_ValueOrDash(value)
{
    s := Trim(value . "")
    return (s = "") ? "-" : s
}

SSOK_CompanyInfo_JoinAddress(zip, adrs, dtlAdrs)
{
    out := ""

    if (zip != "")
        out := "[" . zip . "] "

    out .= Trim(adrs . " " . dtlAdrs)
    out := Trim(out)

    return (out = "") ? "-" : out
}

SSOK_AdminCalendar_GetBusanUrl()
{
    return "https://bsss.pen.go.kr/view.do?no=58"
}

SSOK_AdminCalendar_ParseDateBusan(html, targetYmd)
{
    if !SSOK_AdminCalendar_PageIsTargetMonth(html, targetYmd, "B")
        return {ok:false, text:"", count:0, error:"¼±ÅÃÇÑ ¿ùÀÇ ºÎ»ê±³À°Ã» ´Þ·ÂÀ» Ã£Áö ¸øÇß½À´Ï´Ù.", events:[]}
    if !RegExMatch(html, "is)<div\b[^>]*id=[""']excel[""'][^>]*>.*?<table\b[^>]*>(.*?)</table>", table)
        return {ok:false, text:"", count:0, error:"ºÎ»ê±³À°Ã» ÀÏÁ¤ Ç¥¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.", events:[]}
    events := [], seen := {}, pos := 1
    date := SubStr(targetYmd, 1, 4) . "-" . SubStr(targetYmd, 5, 2) . "-" . SubStr(targetYmd, 7, 2)
    while (pos := RegExMatch(table1, "is)<tr\b[^>]*>(.*?)</tr>", row, pos))
    {
        pos += StrLen(row)
        cells := [], cellPos := 1
        while (cellPos := RegExMatch(row1, "is)<td\b[^>]*>(.*?)</td>", cell, cellPos))
        {
            cellPos += StrLen(cell)
            cells.Push(SSOK_AdminCalendar_CleanText(SSOK_AdminCalendar_HtmlToText(cell1)))
        }
        if (cells.Length() < 5 || !RegExMatch(cells[2], "^20\d{2}-\d{2}-\d{2}$") || !RegExMatch(cells[3], "^20\d{2}-\d{2}-\d{2}$"))
            continue
        if (date < cells[2] || date > cells[3])
            continue
        item := cells[5]
        if (item != "" && !seen.HasKey(item))
        {
            seen[item] := true
            events.Push(item)
        }
    }
    return {ok:true, text:SSOK_AdminCalendar_FormatEvents(events), count:events.Length(), error:"", events:events}
}
