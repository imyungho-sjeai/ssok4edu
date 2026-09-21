; SSOK_BUILD_CARD_COMPARE_SIMPLE_FILENAME_NO_POPUP_20260921
; °£Æí ÁöÃâÇ°ÀÇ: ¼±ÅÃÇÑ °ßÀû¼­ ÀÐ±â ¡æ Ç°¸í Ã¹ Ä­¿¡¼­ Win+1 ÀÔ·Â
; AutoHotkey v1 ÁöÃâÇ°ÀÇ ¸ðµâÀÔ´Ï´Ù. Win+1 / Win+2 / Win+3¸¦ ÀÌ ÆÄÀÏ¿¡¼­ Á÷Á¢ Ã³¸®ÇÕ´Ï´Ù.
#If SSOK_Expense_HotkeyContext()
; ------------------------------------------------------------
; ÁöÃâÇ°ÀÇ Àü¿ë Win ´ÜÃàÅ°
; - Win+1 : °ßÀû¼­ ÀÐ±â / ÁöÃâÇ°ÀÇ Ç°¸ñ µî·Ï
; - Win+2 : K-¿¡µàÆÄÀÎ È­¸éÀ» MSAA·Î ÀÐ¾î °Ë¼ö¿©ºÎ¡¤ÀüÀÚÁ¶´Þ±¸¸Å¡¤ÃÑ¿øÀÎÇàÀ§¾× Ã³¸®
; - Win+3 : °³¿ä ÇÑ¹æ Á¤¸® + ¿øÀÎÇàÀ§ÃÑ¾× ¹Ý¿µ / Win+4 : ±âÁ¸ Tab ¼ø¼­ ½ÇÇà
; Win+1 / Win+2 / Win+3¸¦ ÀÌ ÆÄÀÏ¿¡¼­ Á÷Á¢ Ã³¸®ÇÕ´Ï´Ù.
;
; º°µµ #If ÄÁÅØ½ºÆ®¸¦ »ç¿ëÇÏ¿© ±¸Çü ssok_tool.ahk¿¡ °°Àº ´ÜÃàÅ°°¡
; ³²¾Æ ÀÖ¾îµµ AHKÀÇ Duplicate hotkey ÆÄ½Ì ¿À·ù°¡ ¹ß»ýÇÏÁö ¾Ê°Ô ÇÕ´Ï´Ù.
; ------------------------------------------------------------
#1::
    KeyWait, LWin
    KeyWait, RWin
    SSOK_Expense_Run()
return

#2::
    KeyWait, LWin
    KeyWait, RWin
    SendInput, {LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}
    SetKeyDelay, 80, 40
    Sleep, 150
    SendInput, {Tab 10}
    Sleep, 120
    SendInput, {Right}
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
return

#If (SSOK_ExpenseBusy)
Esc::
    SSOK_ExpenseCancel := true
return
#If

SSOK_Expense_Run()
{
    global SSOK_ExpenseBusy, SSOK_ExpenseReady, SSOK_ExpenseRows
    if (SSOK_ExpenseBusy || WinActive("°£Æí ÁöÃâÇ°ÀÇ - °ßÀû¼­ È®ÀÎ"))
        return
    if (SSOK_ExpenseReady)
    {
        SSOK_Expense_Write()
        return
    }
    SSOK_Expense_Capture()
}

SSOK_Expense_GetClipboardHtml()
{
    format := DllCall("RegisterClipboardFormat", "Str", "HTML Format", "UInt")
    if (!format)
        return ""

    ; º¹»ç Á÷ÈÄ ChromeÀÌ Àá±ñ Å¬¸³º¸µå¸¦ Àâ°í ÀÖÀ» ¼ö ÀÖ¾î Âª°Ô Àç½ÃµµÇÕ´Ï´Ù.
    Loop, 4
    {
        if DllCall("OpenClipboard", "Ptr", 0)
            break
        Sleep, 25
    }

    if !DllCall("IsClipboardFormatAvailable", "UInt", format)
    {
        try DllCall("CloseClipboard")
        return ""
    }

    html := ""
    hData := DllCall("GetClipboardData", "UInt", format, "Ptr")
    if (hData)
    {
        pData := DllCall("GlobalLock", "Ptr", hData, "Ptr")
        if (pData)
        {
            size := DllCall("GlobalSize", "Ptr", hData, "UPtr")
            if (size > 0)
                html := StrGet(pData, size, "UTF-8")
            DllCall("GlobalUnlock", "Ptr", hData)
        }
    }

    DllCall("CloseClipboard")
    return html
}

SSOK_Expense_Capture()
{
    global SSOK_ExpenseRows, SSOK_ExpenseReady, SSOK_ExpenseSource
    global SSOK_ExpenseSourceWindow, SSOK_ExpenseBusy, SSOK_ExpenseStage
    global SSOK_ExpenseCopiedHtml
    SSOK_ExpenseBusy := true
    SSOK_ExpenseSourceWindow := WinExist("A")
    saved := ClipboardAll
    Clipboard := ""
    SendInput, ^c
    ClipWait, 2
    copied := Clipboard

    ; Chrome/Edge À¥Ç¥´Â ÀÏ¹Ý ÅØ½ºÆ®°¡ ±úÁ®µµ CF_HTML¿¡´Â ¿ø·¡ Ç¥ ±¸Á¶°¡ ³²¾Æ ÀÖ½À´Ï´Ù.
    ; S2B Àü¿ë ÃÖÁ¾ fallback¿¡¼­¸¸ »ç¿ëÇÕ´Ï´Ù.
    SSOK_ExpenseCopiedHtml := SSOK_Expense_GetClipboardHtml()

    Clipboard := saved
    saved := ""
    SSOK_ExpenseBusy := false
    if (copied = "")
    {
        SSOK_Expense_ShowCaptureNotice()
        return
    }
    result := SSOK_Expense_Parse(copied)
    if (result.error != "")
    {
        ; Ç°¸í/¼ö·®/´Ü°¡/±Ý¾× ¹ÌÀÎ½Ä ¾È³»¸¸ Å« 2ÃÊ ÀÚµ¿Á¾·á Ã¢À¸·Î Ç¥½Ã
        if InStr(result.error, "°ßÀû¼­ÀÇ Ç°¸í, ¼ö·®, ´Ü°¡, ±Ý¾×ÀÌ ¾ø½À´Ï´Ù.")
            SSOK_Expense_ShowParseMissingNotice()
        else
            MsgBox, 48, °£Æí ÁöÃâÇ°ÀÇ, % result.error
        return
    }
    ; ½ÇÁ¦ ÀÔ·Â¿ë ÇàÀ» º°µµ·Î ±¸¼ºÇÕ´Ï´Ù.
    ; »óÇ° Çà µÚ¿¡ ¹è¼Ûºñ°¡ ÀÖÀ¸¸é ¸¶Áö¸· ÇàÀ¸·Î ÀÚµ¿ Ãß°¡ÇÕ´Ï´Ù.
    SSOK_ExpenseRows := []
    for _, row in result.rows
        SSOK_ExpenseRows.Push(row)
    if (result.shipping > 0)
        SSOK_ExpenseRows.Push({name: "¹è¼Ûºñ", spec: "", qty: 1, amount: result.shipping, price: result.shipping})
    SSOK_ExpenseSource := result.source
    SSOK_Expense_ResetRegistration()
    SSOK_ExpenseReady := false
    SSOK_ExpenseStage := ""
    SSOK_Expense_Preview(result)
}



; ------------------------------------------------------------
; °ßÀû¼­ ÇÊ¼ö ¿­ ¹ÌÀÎ½Ä ¾È³»
; - Å« ±Û¾¾ / ±½°Ô
; - °¡¿îµ¥ Á¤·Ä
; - È®ÀÎ ¹öÆ° ¾øÀ½
; - 3ÃÊ ÈÄ ÀÚµ¿ Á¾·á
; ------------------------------------------------------------
SSOK_Expense_ShowParseMissingNotice()
{
    Gui, SSOKExpenseParseNotice:Destroy
    Gui, SSOKExpenseParseNotice:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKExpenseParseNotice:Color, FFF7DF
    Gui, SSOKExpenseParseNotice:Margin, 18, 20

    ; 4ÁÙÀ» °¢°¢ º°µµ Text·Î ºÐ¸®ÇØ ³ôÀÌ ºÎÁ·À¸·Î Àß¸®Áö ¾Êµµ·Ï ÇÔ
    Gui, SSOKExpenseParseNotice:Font, s16 Bold, Malgun Gothic
    Gui, SSOKExpenseParseNotice:Add, Text, w620 h36 Center c222222, °ßÀû¼­ÀÇ Ç°¸í ¡¤ ¼ö·® ¡¤ ´Ü°¡ ¡¤ ±Ý¾×À»

    Gui, SSOKExpenseParseNotice:Add, Text, y+1 w620 h36 Center c222222, Ã£Áö ¸øÇß½À´Ï´Ù.

    Gui, SSOKExpenseParseNotice:Font, s14 Bold, Malgun Gothic
    Gui, SSOKExpenseParseNotice:Add, Text, y+5 w620 h34 Center c222222, °ßÀû¼­ Ç¥¸¦ ¹üÀ§(Block) ÁöÁ¤ÇÑ ÈÄ

    Gui, SSOKExpenseParseNotice:Add, Text, y+1 w620 h34 Center c222222, Ç°ÀÇ(Win+1)¸¦ ´Ù½Ã ´­·¯ÁÖ¼¼¿ä.

    Gui, SSOKExpenseParseNotice:Show, AutoSize Center NoActivate

    SetTimer, SSOKExpenseParseNoticeClose, -2000
}

SSOKExpenseParseNoticeClose:
    Gui, SSOKExpenseParseNotice:Destroy
return

; ------------------------------------------------------------
; Win+1 ¹üÀ§ ¹ÌÁöÁ¤ ¾È³»
; - Å« ±Û¾¾
; - °¡¿îµ¥ Á¤·Ä
; - È®ÀÎ ¹öÆ° ¾øÀ½
; - 2ÃÊ ÈÄ ÀÚµ¿ Á¾·á
; ------------------------------------------------------------
SSOK_Expense_ShowCaptureNotice()
{
    Gui, SSOKExpenseCaptureNotice:Destroy
    Gui, SSOKExpenseCaptureNotice:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKExpenseCaptureNotice:Color, FFFBEA
    Gui, SSOKExpenseCaptureNotice:Margin, 18, 16

    ; ÇÑ ÁÙÀÌ ±æ¾îÁöÁö ¾Êµµ·Ï 3ÁÙ·Î ¿ÏÀüÈ÷ ºÐ¸®
    Gui, SSOKExpenseCaptureNotice:Font, s16 Bold, Malgun Gothic
    Gui, SSOKExpenseCaptureNotice:Add, Text, w620 h34 Center c222222, °ßÀû¼­¿¡¼­ Ç°¸ñ ¡¤ ´Ü°¡ ¡¤ ±Ý¾×À» ¹üÀ§ ÁöÁ¤ÇÑ ÈÄ

    Gui, SSOKExpenseCaptureNotice:Font, s15 Bold, Malgun Gothic
    Gui, SSOKExpenseCaptureNotice:Add, Text, y+2 w620 h34 Center c222222, Ç°ÀÇ(Win+1)¸¦ ´Ù½Ã ´­·¯ÁÖ¼¼¿ä.

    Gui, SSOKExpenseCaptureNotice:Font, s11 Norm, Malgun Gothic
    Gui, SSOKExpenseCaptureNotice:Add, Text, y+2 w620 h26 Center c555555, °ßÀû¼­ Ç¥ ÀüÃ¼¸¦ ¼±ÅÃÇÏ¸é ´õ Á¤È®ÇÏ°Ô ÀÎ½ÄÇÕ´Ï´Ù.

    Gui, SSOKExpenseCaptureNotice:Show, AutoSize Center NoActivate

    ; 2ÃÊ ÈÄ ÀÚµ¿ Á¾·á
    SetTimer, SSOKExpenseCaptureNoticeClose, -2000
}

SSOKExpenseCaptureNoticeClose:
    Gui, SSOKExpenseCaptureNotice:Destroy
return

; ------------------------------------------------------------
; °ßÀû¼­ È®ÀÎ È­¸é Ç¥½Ã Àü¿ë ¼ýÀÚ Æ÷¸Ë
; ½ÇÁ¦ ÀÔ·Â°ªÀº º¯°æÇÏÁö ¾Ê°í Ãµ ´ÜÀ§ ½°Ç¥¸¸ Ç¥½ÃÇÕ´Ï´Ù.
; ¼Ò¼ö ´Ü°¡°¡ ÀÖÀ¸¸é ¼Ò¼öÁ¡ ÀÌÇÏµµ ±×´ë·Î º¸Á¸ÇÕ´Ï´Ù.
; ¿¹: 935000 -> 935,000 / 32503.334 -> 32,503.334
; ------------------------------------------------------------
SSOK_Expense_FormatPreviewNumber(value)
{
    s := value . ""

    sign := ""
    if (SubStr(s, 1, 1) = "-")
    {
        sign := "-"
        s := SubStr(s, 2)
    }

    dotPos := InStr(s, ".")
    if (dotPos)
    {
        intPart := SubStr(s, 1, dotPos - 1)
        decPart := SubStr(s, dotPos + 1)
    }
    else
    {
        intPart := s
        decPart := ""
    }

    ; È¤½Ã ±âÁ¸ ½°Ç¥°¡ µé¾î ÀÖ¾îµµ Á¦°Å ÈÄ ´Ù½Ã Á¤¸®
    intPart := StrReplace(intPart, ",")
    out := ""

    while (StrLen(intPart) > 3)
    {
        out := "," . SubStr(intPart, -2) . out
        intPart := SubStr(intPart, 1, StrLen(intPart) - 3)
    }

    result := sign . intPart . out

    if (decPart != "")
        result .= "." . decPart

    return result
}

SSOK_Expense_Preview(result)
{
    Gui, SSOKExpense:Destroy
    Gui, SSOKExpense:New, +AlwaysOnTop +LabelSSOKExpense +HwndSSOK_ExpensePreviewHwnd, °£Æí ÁöÃâÇ°ÀÇ - °ßÀû¼­ È®ÀÎ
    Gui, SSOKExpense:Font, s9, Malgun Gothic

    displayTotal := SSOK_Expense_FormatPreviewNumber(result.total)
    displayShipping := SSOK_Expense_FormatPreviewNumber(result.shipping)
    displayGrandTotal := SSOK_Expense_FormatPreviewNumber(result.total + result.shipping)
    Gui, SSOKExpense:Add, Text, w980, % result.source . " / »óÇ° " . result.rows.Length() . "°³ / »óÇ° " . displayTotal . "¿ø, ¹è¼Ûºñ " . displayShipping . "¿ø ÇÕ°è " . displayGrandTotal . "¿ø"

    ; È®ÀÎ Ç¥´Â °øÅë 6Ä­¸¸ Ç¥½ÃÇÏ°í, ¿øÇà¸ñ·Ï ÀÔ·Â ½Ã¿¡¸¸ 2Ä­À» Ãß°¡ÇÕ´Ï´Ù.
    ; °ßÀû¼­¿¡ Á¶´Þ¼ö¼ö·á/¿ëµµ °ªÀÌ ¾øÀ¸¸é µÎ Ä­Àº ºóÄ­À¸·Î Ã³¸®ÇÕ´Ï´Ù.
    Gui, SSOKExpense:Add, ListView, w980 h280, Ç°¸í|±Ô°Ý|¼ö·®|´ÜÀ§|´Ü°¡|±Ý¾×

    for i, row in result.rows
    {
        displayPrice := SSOK_Expense_FormatPreviewNumber(row.price)
        displayAmount := SSOK_Expense_FormatPreviewNumber(row.amount)
        LV_Add("", row.name, row.spec, row.qty, "°³", displayPrice, displayAmount)
    }

    if (result.shipping > 0)
    {
        displayShipping := SSOK_Expense_FormatPreviewNumber(result.shipping)
        LV_Add("", "¹è¼Ûºñ", "", 1, "°³", displayShipping, displayShipping)
    }

    LV_ModifyCol(1, 350)
    LV_ModifyCol(2, 120)
    LV_ModifyCol(3, 55)
    LV_ModifyCol(4, 55)
    LV_ModifyCol(5, 85)
    LV_ModifyCol(6, 85)
    Gui, SSOKExpense:Add, Text, w980, ±âº» ÀÔ·Â: Ç°¸í ¡¤ ±Ô°Ý ¡¤ ¼ö·® ¡¤ ´ÜÀ§ ¡¤ ´Ü°¡ ¡¤ ±Ý¾× / ¿øÇà¸ñ·Ï¸¸ Á¶´Þ¼ö¼ö·á ¡¤ ¿ëµµ(Àû¿ä) Ãß°¡

    ; --------------------------------------------------------
    ; ±âÁ¸ 3°³ ¸Þ´º À¯Áö + ¿ìÃø ¼ÒÇü ¿øÀÎÇàÀ§ ¸Þ´º Ãß°¡
    ; --------------------------------------------------------
    ; --------------------------------------------------------
    ; ÇÏ´Ü ¹öÆ°: ¿ÞÂÊ 3°³´Â ÃÎÃÎÇÏ°Ô, ¿øÀÎÇàÀ§´Â ¿À¸¥ÂÊ ³¡¿¡ ÀÛ°Ô ºÐ¸®
    ; --------------------------------------------------------
    Gui, SSOKExpense:Font, s9 Bold, Malgun Gothic
    Gui, SSOKExpense:Add, Button, x16 y+8 w300 h58 gSSOKExpenseArm Default, K-¿¡µàÆÄÀÎ ÁöÃâÇ°ÀÇ`n(Ç°¸ñ.°³¿ä.Á¦¸ñ)`nÀÚµ¿ ÀÔ·ÂÇÏ±â

    Gui, SSOKExpense:Font, s9 Norm, Malgun Gothic
    Gui, SSOKExpense:Add, Button, x326 yp w200 h58 gSSOKExpenseItemsArm, Ç°ÀÇ¸ñ·Ï ÀÔ·ÂÇÏ±â`n(ÇàÃß°¡ ÈÄ ½ÇÇà)

    Gui, SSOKExpense:Add, Button, x536 yp w120 h58 gSSOKExpenseCancel, Ãë¼ÒÇÏ±â

    ; ¿øÇà¸ñ·ÏÀº ´Ù¸¥ ¹öÆ°°ú ¿ÏÀüÈ÷ ºÐ¸®ÇÏ¿© Ã¢ Á¦ÀÏ ¿ìÃø¿¡ ¾ÆÁÖ ÀÛ°Ô ¹èÄ¡
    Gui, SSOKExpense:Font, s6 Norm, Malgun Gothic
    Gui, SSOKExpense:Add, Button, x930 yp+14 w50 h30 gSSOKExpenseCauseArm, ¿øÇà¸ñ·Ï`nÀÔ·ÂÇÏ±â


    ; ½ÇÁ¦ Ã¢ Å©±â·Î °è»êÇÏµÇ °ø°£ÀÌ ºÎÁ·ÇØµµ ¸ÞÀÎ ¸Þ´º ¿À¸¥ÂÊÀ¸·Î ³Ñ±âÁö ¾Ê½À´Ï´Ù.
    Gui, SSOKExpense:Show, Hide AutoSize
    expenseDetectHidden := A_DetectHiddenWindows
    DetectHiddenWindows, On
    WinGetPos, , , SSOK_ExpensePreviewW, SSOK_ExpensePreviewH, ahk_id %SSOK_ExpensePreviewHwnd%
    DetectHiddenWindows, %expenseDetectHidden%
    if (SSOK_ExpensePreviewW = "")
        SSOK_ExpensePreviewW := 1000
    if (SSOK_ExpensePreviewH = "")
        SSOK_ExpensePreviewH := 390
    SSOK_GetSidebarAttachedGuiPos(SSOK_ExpensePreviewW, SSOK_ExpensePreviewH, SSOK_ExpensePreviewX, SSOK_ExpensePreviewY, true)
    if (SSOK_ExpensePreviewX = "")
        SSOK_ExpensePreviewX := 0
    if (SSOK_ExpensePreviewY = "")
        SSOK_ExpensePreviewY := 0
    Gui, SSOKExpense:Show, x%SSOK_ExpensePreviewX% y%SSOK_ExpensePreviewY%
}

SSOKExpenseArm:
    SSOK_Expense_Arm("all")
return

SSOKExpenseItemsArm:
    SSOK_Expense_Arm("items")
return

SSOKExpenseCauseArm:
    SSOK_Expense_Arm("cause")
return

SSOKExpenseClose:
SSOKExpenseEscape:
SSOKExpenseCancel:
    SSOK_ExpenseReady := false
    SSOK_ExpenseStage := ""
    SSOK_ExpenseRows := []
    SSOK_ExpensePendingAdd := ""
    Gui, SSOKExpense:Destroy
return

SSOKExpenseClearTip:
    ToolTip
return

SSOK_Expense_Parse(text)
{
    out := {rows: [], source: "", total: 0, shipping: 0, quoteTotal: 0, grandTotal: 0, fractional: false, error: ""}
    text := StrReplace(text, "`r")
    if (InStr(text, "»óÇ°¹øÈ£") && InStr(text, "¼¼¾×"))
        out.source := "11¹ø°¡"
    else if (InStr(text, "°ø±ÞÀÚ¸í") && InStr(text, "°ø±ÞÇÕ°è"))
    {
        ; Áö¸¶ÄÏÀº HTML Ç¥¿¡¼­ º¹»çÇÑ ÅÇ Çü½Ä°ú PDF¿¡¼­ º¹»çÇÑ ¼¼·Î Çü½ÄÀÌ
        ; °°Àº °ßÀû¼­¶óµµ ¼­·Î ´Ù¸£°Ô µé¾î¿Ã ¼ö ÀÖ½À´Ï´Ù.
        ; 7¿­ °íÁ¤/1<TAB> ¿©ºÎ·Î ³ª´©Áö ¾Ê°í °øÅë ÆÄ¼­¿¡¼­ µÑ ´Ù Ã³¸®ÇÕ´Ï´Ù.
        return SSOK_Expense_ParseGmarketUniversal(text)
    }
    else
    {
        ; G¸¶ÄÏ/11¹ø°¡°¡ ¾Æ´Ï¸é Ç¥ÀÇ ¸Ó¸®±ÛÀ» ÀÐ´Â ¹ü¿ë °ßÀû¼­ ÆÄ¼­·Î Ã³¸®ÇÕ´Ï´Ù.
        return SSOK_Expense_ParseGenericTable(text)
    }
    ended := false
    expected := 1
    for _, line in StrSplit(text, "`n")
    {
        line := Trim(line, " `t" . Chr(160))
        if (line = "")
            continue
        if (SubStr(line, 1, 1) = "|")
        {
            line := Trim(line, "|")
            line := Trim(RegExReplace(line, " *\| *", "`t"), " `t")
        }
        if (RegExMatch(line, "^¹è¼Ûºñ(?:\(¼±°áÁ¦\))?[\s|]+([\d,]+)¿ø?", ship))
            out.shipping := StrReplace(ship1, ",") + 0

        ; ¿øº» °ßÀû¼­ ÇÕ°èµµ ÀÐ¾î ÆÄ½Ì °á°ú¿Í ´ëÁ¶ÇÕ´Ï´Ù.
        if (RegExMatch(line, "^ÇÕ°è"))
        {
            nums := []
            posNum := 1
            while (posNum := RegExMatch(line, "([\d,]+)¿ø", n, posNum))
            {
                nums.Push(StrReplace(n1, ",") + 0)
                posNum += StrLen(n)
            }
            if (nums.Length())
                out.quoteTotal := nums[nums.Length()]
        }

        if (RegExMatch(line, "^ÃÑ ±¸¸Å±Ý¾×[\s|]+([\d,]+)¿ø?", gm))
            out.grandTotal := StrReplace(gm1, ",") + 0

        if (RegExMatch(line, "^(ÇÕ°è|¹è¼Ûºñ|ÃÑÇÕ°è|ÃÑ ±¸¸Å±Ý¾×|\*)"))
        {
            ended := true
            continue
        }
        if (ended)
            continue
        if (RegExMatch(line, "^\d+[\t ]"))
        {
            cells := StrSplit(line, "`t")
            for i, cell in cells
                cells[i] := Trim(cell, " " . Chr(160))
            while (cells.Length() && cells[cells.Length()] = "")
                cells.Pop()
            need := (out.source = "11¹ø°¡" ? 8 : 7)
            if (cells.Length() != need || !RegExMatch(cells[1], "^\d+$"))
            {
                out.error := "»óÇ° ÇàÀÇ ¿­À» ±¸ºÐÇÏÁö ¸øÇß½À´Ï´Ù. ¿øº» °ßÀû¼­ Ç¥¿¡¼­ º¹»çÇØ ÁÖ¼¼¿ä. ¹®Á¦ Çà: " . line
                return out
            }
            if (cells[1] + 0 != expected)
            {
                out.error := "»óÇ° ¹øÈ£°¡ 1¹øºÎÅÍ ¿¬¼ÓµÇÁö ¾Ê½À´Ï´Ù. ÀüÃ¼ »óÇ° ³»¿ªÀ» ´Ù½Ã ¼±ÅÃÇØ ÁÖ¼¼¿ä."
                return out
            }
            expected++
            name := cells[out.source = "11¹ø°¡" ? 3 : 2]
            qty := SSOK_Expense_Number(cells[4])
            amount := SSOK_Expense_Number(cells[need])
            if (name = "" || qty = "" || qty <= 0 || amount = "" || amount < 0)
            {
                out.error := "»óÇ°¸í¡¤¼ö·®¡¤±Ý¾×À» È®ÀÎÇØ ÁÖ¼¼¿ä. ¹®Á¦ Çà: " . line
                return out
            }
            ; K-¿¡µàÆÄÀÎÀº ¼Ò¼ö ´Ü°¡ ¡¿ ¼ö·® °á°úÀÇ ¼Ò¼ö ºÎºÐÀ» ¹ö¸± ¼ö ÀÖ½À´Ï´Ù.
            ; ÀÏ¹Ý ¹Ý¿Ã¸²À¸·Î 6ÀÚ¸® ´Ü°¡¸¦ ¸¸µé¸é ¸ñÇ¥±Ý¾×º¸´Ù 1¿ø ÀÛ¾ÆÁú ¼ö ÀÖÀ¸¹Ç·Î,
            ; ³ª´©¾î¶³¾îÁöÁö ¾Ê´Â °æ¿ì ´Ü°¡¸¦ ¼Ò¼ö 6ÀÚ¸®¿¡¼­ "¿Ã¸²"ÇÏ¿©
            ; ¿¹»ó±Ý¾×ÀÌ °ßÀû¼­ÀÇ ¿ø·¡ °ø±ÞÇÕ°è¿Í Á¤È®È÷ ¸Âµµ·Ï ÇÕ´Ï´Ù.
            price := SSOK_Expense_CalcExpectedPrice(amount, qty, out)

            out.rows.Push({name: name, spec: "", qty: qty, amount: amount, price: price})
            out.total += amount
        }
        else if (out.source = "Áö¸¶ÄÏ" && out.rows.Length())
        {
            ; Áö¸¶ÄÏÀÇ »óÇ° ¹Ù·Î ´ÙÀ½ ÁÙ¿¡ Ç¥½ÃµÇ´Â ÇÊ¼ö¼±ÅÃ/Ãß°¡±¸¼º/»ö»óÀº
            ; »óÇ°¸í¿¡ ºÙÀÌÁö ¾Ê°í K¿¡µàÆÄÀÎ "±Ô°Ý" °ªÀ¸·Î º¸Á¸ÇÕ´Ï´Ù.
            option := Trim(RegExReplace(line, "\t+", " "))
            if (option != "" && !RegExMatch(option, "^[-: ]+$"))
            {
                idx := out.rows.Length()
                if (out.rows[idx].spec = "")
                    out.rows[idx].spec := option
                else
                    out.rows[idx].spec .= " / " . option
            }
        }
    }
    if (!out.rows.Length())
    {
        out.error := "ÀÐÀ» ¼ö ÀÖ´Â »óÇ° ÇàÀÌ ¾ø½À´Ï´Ù. ¿øº» °ßÀû¼­ÀÇ Ç¥¸¦ ¼±ÅÃÇØ ÁÖ¼¼¿ä."
        return out
    }

    ; »óÇ° ÇÕ°è°¡ ¿øº» ÇÕ°è¿Í ´Ù¸£¸é ÀÚµ¿ÀÔ·ÂÀ» ½ÃÀÛÇÏÁö ¾Ê½À´Ï´Ù.
    if (out.quoteTotal > 0 && Round(out.total) != Round(out.quoteTotal))
    {
        out.error := "°ßÀû¼­ »óÇ° ÇÕ°è °ËÁõ¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n¿øº» ÇÕ°è: " . out.quoteTotal . "¿ø`nÀÎ½Ä ÇÕ°è: " . out.total . "¿ø`nÀÚµ¿ÀÔ·ÂÀ» Áß´ÜÇÕ´Ï´Ù."
        return out
    }

    ; ÃÑ ±¸¸Å±Ý¾× = »óÇ°ÇÕ°è + ¹è¼Ûºñ °ËÁõ
    if (out.grandTotal > 0 && Round(out.total + out.shipping) != Round(out.grandTotal))
    {
        out.error := "°ßÀû¼­ ÃÑ ±¸¸Å±Ý¾× °ËÁõ¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n¿øº» ÃÑ ±¸¸Å±Ý¾×: " . out.grandTotal . "¿ø`nÀÎ½Ä ±Ý¾×: " . (out.total + out.shipping) . "¿ø`nÀÚµ¿ÀÔ·ÂÀ» Áß´ÜÇÕ´Ï´Ù."
        return out
    }

    return out
}


; ============================================================================
; G¸¶ÄÏ HTML / PDF °øÅë ÆÄ¼­
;
; Áö¿ø Çü½Ä
; 1) HTML Ç¥ º¹»ç: ¹øÈ£<TAB>»óÇ°¸í<TAB>°ø±ÞÀÚ¸í<TAB>¼ö·®<TAB>°ø±Þ°¡¾×<TAB>ÇÒÀÎ±Ý¾×<TAB>°ø±ÞÇÕ°è
; 2) PDF º¹»ç: À§ °¢ ¼¿ÀÌ ÁÙ¹Ù²ÞµÇ¾î ¼¼·Î·Î ³»·Á¿À´Â Çü½Ä
; 3) Markdown/ÆÄÀÌÇÁ Ç¥: | ¹øÈ£ | »óÇ°¸í | ... |
;
; ÇÙ½ÉÀº ÇàÀÇ ¿­ °³¼ö¸¦ °íÁ¤ÇÏÁö ¾Ê´Â °ÍÀÔ´Ï´Ù.
; ÅÇ/ÁÙ¹Ù²Þ/ÆÄÀÌÇÁ¸¦ ¸ðµÎ ¼¿ ÅäÅ«À¸·Î ¸¸µç µÚ
; "¼ö·® + °ø±Þ°¡¾× + ÇÒÀÎ±Ý¾× + °ø±ÞÇÕ°è" ÆÐÅÏÀ¸·Î °¢ »óÇ°ÇàÀ» È®Á¤ÇÕ´Ï´Ù.
; ============================================================================
SSOK_Expense_ParseGmarketUniversal(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "Áö¸¶ÄÏ(HTML/PDF ÀÚµ¿ÀÎ½Ä)"

    text := StrReplace(text, "`r")
    tokens := []

    for _, rawLine in StrSplit(text, "`n")
    {
        line := Trim(rawLine, " `t" . Chr(160))
        if (line = "")
            continue

        ; Markdown Ç¥¶ó¸é ÆÄÀÌÇÁ¸¦ ½ÇÁ¦ ¼¿ ±¸ºÐÀÚ·Î Ãë±ÞÇÕ´Ï´Ù.
        isPipe := (SubStr(line, 1, 1) = "|")
        if (isPipe)
        {
            line := Trim(line, "|")
            parts := StrSplit(line, "|")
        }
        else if InStr(line, "`t")
        {
            parts := StrSplit(line, "`t")
        }
        else
        {
            parts := [line]
        }

        for _, part in parts
        {
            cell := Trim(part, " `t" . Chr(160))
            cell := StrReplace(cell, Chr(160), " ")
            cell := StrReplace(cell, "¡¡", " ")
            cell := RegExReplace(cell, "[ `t]+", " ")
            cell := Trim(cell)

            if (cell = "")
                continue

            ; Markdown Á¤·Ä¼±Àº µ¥ÀÌÅÍ°¡ ¾Æ´Õ´Ï´Ù.
            if RegExMatch(cell, "^:?-{2,}:?$")
                continue

            tokens.Push(cell)
        }
    }

    if (tokens.Length() < 8)
    {
        out.error := "Áö¸¶ÄÏ °ßÀû¼­ÀÇ »óÇ° Ç¥¸¦ ÃæºÐÈ÷ ÀÐÁö ¸øÇß½À´Ï´Ù."
        return out
    }

    ; HTML¿¡¼­´Â ¸Ó¸®±ÛÀÌ ¿©·¯ ¼¿, ÀÏºÎ ºê¶ó¿ìÀú/º¹»ç ¹æ½Ä¿¡¼­´Â ÇÑ ¼¿·Î
    ; ºÙ¾î¼­ µé¾î¿Ã ¼ö ÀÖÀ¸¹Ç·Î '°ø±ÞÇÕ°è'°¡ Æ÷ÇÔµÈ ÅäÅ«±îÁö¸¸ ¸Ó¸®±Û·Î º¾´Ï´Ù.
    headerEnd := 0
    Loop, % tokens.Length()
    {
        if InStr(tokens[A_Index], "°ø±ÞÇÕ°è")
        {
            headerEnd := A_Index
            break
        }
    }

    if (!headerEnd)
    {
        out.error := "Áö¸¶ÄÏ °ßÀû¼­ÀÇ '°ø±ÞÇÕ°è' ¸Ó¸®±ÛÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
        return out
    }

    pos := headerEnd + 1
    while (pos <= tokens.Length() && Trim(tokens[pos]) != "1")
        pos++

    if (pos > tokens.Length())
    {
        out.error := "Áö¸¶ÄÏ °ßÀû¼­¿¡¼­ 1¹ø »óÇ°À» Ã£Áö ¸øÇß½À´Ï´Ù."
        return out
    }

    expected := 1

    while (pos <= tokens.Length())
    {
        ; ´ÙÀ½ »óÇ° ¹øÈ£¸¦ Ã£½À´Ï´Ù. ¿É¼Ç¿¡ Æ÷ÇÔµÈ '00_...' °°Àº °ªÀº
        ; Á¤È®È÷ ¼ýÀÚ ÇÏ³ª¿Í °°Áö ¾ÊÀ¸¹Ç·Î »óÇ°¹øÈ£·Î ¿ÀÀÎÇÏÁö ¾Ê½À´Ï´Ù.
        while (pos <= tokens.Length() && Trim(tokens[pos]) != expected . "")
            pos++

        if (pos > tokens.Length())
            break

        pos++
        if (pos > tokens.Length())
            break

        ; ¹øÈ£ ¹Ù·Î ´ÙÀ½ ¼¿ÀÌ »óÇ°¸íÀÔ´Ï´Ù. HTML/Markdown Ç¥¿¡¼­´Â ¼¿ ÇÏ³ª,
        ; PDF ¼¼·Î º¹»ç¿¡¼­µµ Ã¹ ´ÙÀ½ ÁÙÀÌ »óÇ°¸íÀ¸·Î µé¾î¿É´Ï´Ù.
        name := Trim(tokens[pos])
        if (name = "" || RegExMatch(name, "^\\d+$") || SSOK_Expense_IsWonLine(name))
        {
            out.error := "Áö¸¶ÄÏ °ßÀû¼­ÀÇ " . expected . "¹ø »óÇ°¸íÀ» ÀÐÁö ¸øÇß½À´Ï´Ù."
            return out
        }

        pos++
        qtyPos := 0
        qty := ""
        finalAmount := ""

        ; °ø±ÞÀÚ¸íÀº ÇÑ ¼¿/¿©·¯ ÁÙ ¸ðµÎ ¹«½ÃÇÏ°í,
        ; ¼ö·® + °ø±Þ°¡¾× + ÇÒÀÎ±Ý¾× + °ø±ÞÇÕ°è°¡ ¿¬¼ÓµÇ´Â À§Ä¡¸¦ Ã£½À´Ï´Ù.
        scan := pos
        scanLimit := Min(tokens.Length() - 3, pos + 30)
        while (scan <= scanLimit)
        {
            qText := Trim(tokens[scan])
            q := SSOK_Expense_Number(qText)

            if (q != "" && q > 0 && !InStr(qText, "¿ø")
                && SSOK_Expense_IsWonLine(tokens[scan + 1])
                && SSOK_Expense_IsWonLine(tokens[scan + 2])
                && SSOK_Expense_IsWonLine(tokens[scan + 3]))
            {
                supplyAmount := SSOK_Expense_Number(tokens[scan + 1])
                discountAmount := SSOK_Expense_Number(tokens[scan + 2])
                totalAmount := SSOK_Expense_Number(tokens[scan + 3])

                ; Áö¸¶ÄÏÀº °ø±Þ°¡¾× - ÇÒÀÎ±Ý¾× = °ø±ÞÇÕ°èÀÔ´Ï´Ù.
                if (supplyAmount != "" && discountAmount != "" && totalAmount != ""
                    && Round(supplyAmount - discountAmount) = Round(totalAmount))
                {
                    qtyPos := scan
                    qty := q
                    finalAmount := totalAmount
                    break
                }
            }
            scan++
        }

        if (!qtyPos)
        {
            out.error := "Áö¸¶ÄÏ °ßÀû¼­ÀÇ " . expected . "¹ø »óÇ°¿¡¼­ ¼ö·®¡¤°ø±Þ°¡¾×¡¤ÇÒÀÎ±Ý¾×¡¤°ø±ÞÇÕ°è¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù."
            return out
        }

        price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)

        ; °ø±ÞÇÕ°è ´ÙÀ½ºÎÅÍ ´ÙÀ½ »óÇ°¹øÈ£ Àü±îÁö´Â ¼±ÅÃ¿É¼Ç/Ãß°¡±¸¼ºÀÔ´Ï´Ù.
        spec := ""
        seek := qtyPos + 4
        nextNoPos := 0
        while (seek <= tokens.Length())
        {
            cell := Trim(tokens[seek])

            if (cell = (expected + 1) . "")
            {
                nextNoPos := seek
                break
            }

            if RegExMatch(cell, "^(ÇÕ°è|¹è¼Ûºñ|ÃÑÇÕ°è|ÃÑ ±¸¸Å±Ý¾×|°áÁ¦±Ý¾×|ÁÖ¹®±Ý¾×)")
                break

            ; ±Ý¾×°ú ¼ø¼ö ¼ýÀÚ´Â ¿É¼Ç¿¡¼­ Á¦¿ÜÇÕ´Ï´Ù.
            if (cell != "" && !SSOK_Expense_IsWonLine(cell) && !RegExMatch(cell, "^\\d+(?:\\.\\d+)?$"))
            {
                if (spec = "")
                    spec := cell
                else
                    spec .= " / " . cell
            }
            seek++
        }

        out.rows.Push({name:name, spec:spec, qty:qty, amount:finalAmount, price:price})
        out.total += finalAmount
        expected++

        if (!nextNoPos)
            break
        pos := nextNoPos
    }

    if (!out.rows.Length())
        out.error := "ÀÐÀ» ¼ö ÀÖ´Â »óÇ° ÇàÀÌ ¾ø½À´Ï´Ù. Áö¸¶ÄÏ »óÇ° Ç¥ ÀüÃ¼¸¦ ¼±ÅÃÇØ ÁÖ¼¼¿ä."

    return out
}


; ============================================================================
; G¸¶ÄÏ °è¿­ PDF ¼¼·ÎÇü ÆÄ¼­
;
; PDF¿¡¼­ Ç¥¸¦ º¹»çÇßÀ» ¶§ ¾Æ·¡Ã³·³ ¼¿ ³»¿ëÀÌ ¼¼·Î·Î Ç®¸®´Â ÇüÅÂ¸¦ Ã³¸®ÇÕ´Ï´Ù.
;
; ¹øÈ£
; »óÇ°¸í / ÇÊ¼ö¼±ÅÃ / Ãß°¡±¸¼º
; °ø±ÞÀÚ¸í
; ¼ö·®
; °ø±Þ°¡¾×
; ÇÒÀÎ±Ý¾×
; °ø±ÞÇÕ°è
; 1
; »óÇ°¸í
; °ø±ÞÀÚ¸í(¿©·¯ ÁÙ °¡´É)
; 8
; 30,400¿ø
; 2,000¿ø
; 28,400¿ø
; ¼±ÅÃ¿É¼Ç(ÀÖÀ» ¼ö ÀÖÀ½)
; 2
; ...
;
; ÇÙ½É:
; - »óÇ°¸íÀº ¹øÈ£ ¹Ù·Î ´ÙÀ½ÀÇ Ã¹ ÅØ½ºÆ®¸¦ »ç¿ë
; - °ø±ÞÀÚ¸íÀº ¸î ÁÙ·Î °¥¶óÁ®µµ ¹«½Ã
; - "¼ö·® + °ø±Þ°¡¾× + ÇÒÀÎ±Ý¾× + °ø±ÞÇÕ°è" 4ÁÙ ÆÐÅÏÀ» Ã£¾Æ ÇàÀ» È®Á¤
; - K-¿¡µàÆÄÀÎ ±Ý¾×Àº ÇÒÀÎ ¹Ý¿µ ÈÄ "°ø±ÞÇÕ°è"¸¦ »ç¿ë
; - °ø±ÞÇÕ°è µÚ ´ÙÀ½ »óÇ°¹øÈ£ Àü±îÁöÀÇ ÅØ½ºÆ®´Â ±Ô°Ý/¿É¼ÇÀ¸·Î º¸Á¸
; ============================================================================
SSOK_Expense_ParseGmarketPdfVertical(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "Áö¸¶ÄÏ PDF(±¸Çü ¼¼·ÎÇü ÆÄ¼­)"

    text := StrReplace(text, "`r")
    rawLines := StrSplit(text, "`n")
    lines := []

    for _, raw in rawLines
    {
        line := Trim(raw, " `t" . Chr(160))
        if (line = "")
            continue

        line := StrReplace(line, Chr(160), " ")
        line := StrReplace(line, "¡¡", " ")
        line := RegExReplace(line, "[ `t]+", " ")
        lines.Push(Trim(line))
    }

    if (lines.Length() < 10)
    {
        out.error := "Áö¸¶ÄÏ PDFÀÇ »óÇ° Ç¥¸¦ ÃæºÐÈ÷ ÀÐÁö ¸øÇß½À´Ï´Ù."
        return out
    }

    ; Çì´õ È®ÀÎ
    headerOK := false
    headerEnd := 0
    Loop, % lines.Length()
    {
        s := lines[A_Index]
        if (InStr(s, "°ø±ÞÇÕ°è"))
        {
            headerEnd := A_Index
            headerOK := true
            break
        }
    }

    if (!headerOK)
    {
        out.error := "Áö¸¶ÄÏ PDFÀÇ '°ø±ÞÇÕ°è' ¸Ó¸®±ÛÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
        return out
    }

    ; Ã¹ »óÇ° ¹øÈ£ 1 Ã£±â
    pos := headerEnd + 1
    while (pos <= lines.Length() && Trim(lines[pos]) != "1")
        pos++

    if (pos > lines.Length())
    {
        out.error := "Áö¸¶ÄÏ PDF¿¡¼­ 1¹ø »óÇ°À» Ã£Áö ¸øÇß½À´Ï´Ù."
        return out
    }

    expected := 1

    while (pos <= lines.Length())
    {
        ; ÇöÀç Çà ¹øÈ£°¡ ¸Â´Â À§Ä¡¸¦ Ã£½À´Ï´Ù.
        while (pos <= lines.Length() && Trim(lines[pos]) != expected . "")
            pos++

        if (pos > lines.Length())
            break

        rowNoPos := pos
        pos++

        if (pos > lines.Length())
            break

        ; ¹øÈ£ ¹Ù·Î ´ÙÀ½ Ã¹ ÅØ½ºÆ®¸¦ »óÇ°¸íÀ¸·Î »ç¿ëÇÕ´Ï´Ù.
        name := Trim(lines[pos])
        if (name = "" || RegExMatch(name, "^\d+$") || SSOK_Expense_IsWonLine(name))
        {
            out.error := "Áö¸¶ÄÏ PDFÀÇ " . expected . "¹ø »óÇ°¸íÀ» ÀÐÁö ¸øÇß½À´Ï´Ù."
            return out
        }

        pos++
        qtyPos := 0
        qty := ""
        supplyAmount := ""
        discountAmount := ""
        finalAmount := ""

        ; °ø±ÞÀÚ¸íÀº ¿©·¯ ÁÙÀÏ ¼ö ÀÖÀ¸¹Ç·Î °Ç³Ê¶Ù¸é¼­
        ; ¼ö·® + °ø±Þ°¡¾× + ÇÒÀÎ±Ý¾× + °ø±ÞÇÕ°è ÆÐÅÏÀ» Ã£½À´Ï´Ù.
        scan := pos
        while (scan + 3 <= lines.Length())
        {
            qText := Trim(lines[scan])
            q := SSOK_Expense_Number(qText)

            if (q != "" && q > 0 && !InStr(qText, "¿ø")
                && SSOK_Expense_IsWonLine(lines[scan + 1])
                && SSOK_Expense_IsWonLine(lines[scan + 2])
                && SSOK_Expense_IsWonLine(lines[scan + 3]))
            {
                s1 := SSOK_Expense_Number(lines[scan + 1])
                s2 := SSOK_Expense_Number(lines[scan + 2])
                s3 := SSOK_Expense_Number(lines[scan + 3])

                ; ÀÌ °ßÀû¼­ ±¸Á¶¿¡¼­´Â °ø±Þ°¡¾× - ÇÒÀÎ±Ý¾× = °ø±ÞÇÕ°èÀÔ´Ï´Ù.
                ; ¼ö½ÄÀÌ ¸Â´Â ÆÐÅÏÀ» ¿ì¼± Ã¤ÅÃÇÏ¿© ´Ù¸¥ ¼ýÀÚ¸¦ ¼ö·®À¸·Î ¿ÀÀÎÇÏÁö ¾Ê°Ô ÇÕ´Ï´Ù.
                if (s1 != "" && s2 != "" && s3 != "" && Round(s1 - s2) = Round(s3))
                {
                    qtyPos := scan
                    qty := q
                    supplyAmount := s1
                    discountAmount := s2
                    finalAmount := s3
                    break
                }
            }

            ; ´ÙÀ½ Ç°¸ñ ¹øÈ£±îÁö °¬´Âµ¥ °¡°Ý ÆÐÅÏÀ» ¸ø Ã£¾ÒÀ¸¸é ÇöÀç Çà ½ÇÆÐ
            if (scan > pos && Trim(lines[scan]) = (expected + 1) . "")
                break

            scan++
        }

        if (!qtyPos)
        {
            out.error := "Áö¸¶ÄÏ PDFÀÇ " . expected . "¹ø »óÇ°¿¡¼­ ¼ö·®¡¤°ø±Þ°¡¾×¡¤ÇÒÀÎ±Ý¾×¡¤°ø±ÞÇÕ°è¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù."
            return out
        }

        if (qty <= 0 || finalAmount < 0)
        {
            out.error := "Áö¸¶ÄÏ PDFÀÇ " . expected . "¹ø »óÇ° ¼ö·® ¶Ç´Â °ø±ÞÇÕ°è°¡ ¿Ã¹Ù¸£Áö ¾Ê½À´Ï´Ù."
            return out
        }

        price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)

        ; °ø±ÞÇÕ°è µÚÀÇ ¿É¼Ç/Ãß°¡±¸¼ºÀº ´ÙÀ½ »óÇ° ¹øÈ£ Àü±îÁö ±Ô°ÝÀ¸·Î ÀúÀåÇÕ´Ï´Ù.
        spec := ""
        afterPrice := qtyPos + 4
        nextNoPos := 0
        seek := afterPrice
        while (seek <= lines.Length())
        {
            s := Trim(lines[seek])

            if (s = (expected + 1) . "")
            {
                nextNoPos := seek
                break
            }

            ; ¸¶Áö¸· »óÇ° µÚÀÇ ÇÕ°è/¹è¼Ûºñ ¿µ¿ªÀº ¿É¼ÇÀ¸·Î ³ÖÁö ¾Ê½À´Ï´Ù.
            if RegExMatch(s, "^(ÇÕ°è|¹è¼Ûºñ|ÃÑÇÕ°è|ÃÑ ±¸¸Å±Ý¾×|°áÁ¦±Ý¾×|ÁÖ¹®±Ý¾×)")
                break

            ; ±Ý¾×/¼ýÀÚ¸¸ ÀÖ´Â ÀÜ¿©°ªÀº ±Ô°Ý¿¡¼­ Á¦¿Ü
            if (s != "" && !SSOK_Expense_IsWonLine(s) && !RegExMatch(s, "^\d+(?:\.\d+)?$"))
            {
                if (spec = "")
                    spec := s
                else
                    spec .= " / " . s
            }

            seek++
        }

        out.rows.Push({name:name, spec:spec, qty:qty, amount:finalAmount, price:price})
        out.total += finalAmount

        expected++

        if (!nextNoPos)
            break

        pos := nextNoPos
    }

    if (!out.rows.Length())
        out.error := "ÀÐÀ» ¼ö ÀÖ´Â »óÇ° ÇàÀÌ ¾ø½À´Ï´Ù. Áö¸¶ÄÏ PDF »óÇ° Ç¥ ÀüÃ¼¸¦ ¼±ÅÃÇØ ÁÖ¼¼¿ä."

    return out
}

SSOK_Expense_IsWonLine(s)
{
    ; HTML/Markdown º¹»ç ½Ã ±Ý¾×ÀÌ **28,400¿ø**Ã³·³ °­Á¶ ±âÈ£¸¦ Æ÷ÇÔÇÒ ¼ö ÀÖ½À´Ï´Ù.
    s := StrReplace(s, "*")
    s := Trim(s, " `t" . Chr(160))
    return RegExMatch(s, "^\d[\d,]*(?:\.\d+)?\s*¿ø$")
}


; ============================================================================
; ¹ü¿ë °ßÀû¼­ Ç¥ ÆÄ¼­
;
; Áö¿ø ¿¹:
;   No / Ç°¸í / Description of goods / ¼ö·® / Quantity / ±Ý¾× / Amount
;      / ºÎ°¡¼¼ / VAT / ÇÕ°è / Total
;
;   No / Ç°¸ñ¡¤±Ô°Ý / ´ÜÀ§ / ¼ö·® / ´Ü°¡ / °ø±Þ°¡ / ¼¼¾× / ÇÕ°è
;
; ±ÔÄ¢:
;   - ÃÖÁ¾ ÇÕ°è(Total/ÇÕ°è)¸¦ ½ÇÁ¦ ±Ý¾×À¸·Î »ç¿ë
;   - ´Ü°¡ = ÃÖÁ¾ ÇÕ°è / ¼ö·®
;   - ±Ô°Ý ¿­ÀÌ µû·Î ÀÖÀ¸¸é ±Ô°Ý ÀÔ·Â, ¾øÀ¸¸é ºóÄ­
;   - ´ÜÀ§´Â ¿øº»°ú °ü°è¾øÀÌ K-¿¡µàÆÄÀÎ¿¡¼­ Ç×»ó "°³"
;   - ±Ý¾× = °ßÀû¼­ÀÇ ¿ø·¡ ÃÖÁ¾ ÇÕ°è
;   - Á¶´Þ¼ö¼ö·á / ¿ëµµ(Àû¿ä)´Â ºóÄ­À¸·Î À¯Áö
; ============================================================================
SSOK_Expense_ParseGenericTable(text)
{
    ; 0¼øÀ§: S2B À¥º¹»ç °ßÀû/¹°Ç° Ç¥
    result := SSOK_Expense_ParseS2BPaste(text)
    if IsObject(result) && (result.rows.Length() || result.recognized)
        return result

    ; 1¼øÀ§: YES24 À¥ °ßÀû¼­ ºÙ¿©³Ö±â Ç¥
    ; ¹øÈ£ / ³»¿ë / ±Ô°Ý / ¼ö·® / ¿¹»ó´Ü°¡ / ¿¹»ó±Ý¾×(Âü°í¿ë)
    result := SSOK_Expense_ParseYes24Paste(text)
    if IsObject(result) && (result.rows.Length() || result.recognized)
        return result

    ; 1¼øÀ§: Excel/½ºÇÁ·¹µå½ÃÆ® Ç¥
    result := SSOK_Expense_ParseExcelTable(text)
    if IsObject(result) && (result.rows.Length() || result.recognized)
        return result

    ; 2¼øÀ§: PDF - ¹øÈ£/±Ô°Ý/¼ö·®/´ÜÀ§/´Ü°¡/±Ý¾×ÀÌ ÇÑ ÁÙ·Î ºÙ´Â ¾ç½Ä
    result := SSOK_Expense_ParsePdfQtyUnitPriceAmount(text)
    if IsObject(result) && (result.rows.Length() || result.error != "")
        return result

    ; 3¼øÀ§: PDF - No/Ç°¸ñ¸í/±Ô°Ý/´ÜÀ§/ÃÑ¼ö·®/´Ü°¡/±Ý¾×/ºñ°í ¾ç½Ä
    result := SSOK_Expense_ParsePdfMaintenanceMixed(text)
    if IsObject(result) && (result.rows.Length() || result.error != "")
        return result

    ; 4¼øÀ§: PDF¿¡¼­ ÇÑ Ç°¸ñ ÀüÃ¼°¡ ÇÑ ÁÙ·Î º¹»çµÇ´Â ÇüÅÂ
    result := SSOK_Expense_ParseGenericPdfCompact(text)
    if IsObject(result) && result.rows.Length()
        return result

    ; 5¼øÀ§: ±âÁ¸ ÅÇ/À¥ Ç¥
    result := SSOK_Expense_ParseGenericTabbed(text)
    if IsObject(result) && result.rows.Length()
        return result

    ; 6¼øÀ§: PDF¿¡¼­ ¼¿ ÇÏ³ª°¡ ÇÑ ÁÙ¾¿ ³»·Á¿À´Â ÇüÅÂ
    result := SSOK_Expense_ParseGenericVertical(text)
    if IsObject(result) && result.rows.Length()
        return result

    out := SSOK_Expense_NewGenericResult()
    out.error := "°ßÀû¼­ÀÇ Ç°¸í, ¼ö·®, ´Ü°¡, ±Ý¾×ÀÌ ¾ø½À´Ï´Ù. `n°ßÀû¼­ Ç¥¸¦ ¸ÕÀú ¹üÀ§(Block) ÁöÁ¤ÇÑ ÈÄ Ç°ÀÇ(win+1)À» ´­·¯ÁÖ¼¼¿ä."
    return out
}


; ============================================================================
; PDF Ãß°¡ ¾ç½Ä 1
;   ¹øÈ£ / (Ç°¸í) / ±Ô°Ý / ¼ö·® / ´ÜÀ§ / ´Ü°¡ / ±Ý¾×
;
; PDF¿¡¼­ ¼¿ °æ°è°¡ »ç¶óÁ® ¾Æ·¡Ã³·³ ÇÑ ÁÙ·Î ºÙ¾î º¹»çµÇ´Â °æ¿ì¸¦ Ã³¸®ÇÕ´Ï´Ù.
;   1¸°½ºR(¼¼Ã´±â¸°½º) 18.7L 2Åë62,000 124,000
;   2ÀÏÈ¸¿ë¸¶½ºÅ©/À¯ÇÑ½Ç²öÇü/50¸Å5°û9,900 49,500
;
; ÇàÀÇ ¿À¸¥ÂÊ ³¡ "¼ö·® + ´ÜÀ§ + ´Ü°¡ + ±Ý¾×"À» ±âÁØÀ¸·Î Ç°¸ñÀ» ºÐ¸®ÇÏ¹Ç·Î
; ±Ô°Ý ¾ÈÀÇ ¼ýÀÚ(50¸Å, 5°³ÀÔ µî)¸¦ ¼ö·®À¸·Î ¿ÀÀÎÇÏÁö ¾Êµµ·Ï ÇÕ´Ï´Ù.
; ============================================================================
SSOK_Expense_ParsePdfQtyUnitPriceAmount(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "PDF °ßÀû¼­(¼ö·®/´ÜÀ§/´Ü°¡/±Ý¾× ÀÚµ¿ÀÎ½Ä)"

    flat := StrReplace(text, "`r", " ")
    flat := StrReplace(flat, "`n", " ")
    flat := StrReplace(flat, Chr(160), " ")
    flat := StrReplace(flat, "¡¡", " ")
    flat := RegExReplace(flat, "[ `t]+", " ")
    flat := Trim(flat)

    ; ÀÌ Àü¿ë ¾ç½ÄÀÇ ¸Ó¸®±ÛÀÌ ¾Æ´Ï¸é ±âÁ¸ ÆÄ¼­·Î ³Ñ±é´Ï´Ù.
    if !RegExMatch(flat, "i)¹øÈ£\s*(?:Ç°\s*¸í\s*)?±Ô°Ý\s*¼ö·®\s*´ÜÀ§\s*´Ü°¡\s*±Ý¾×", h)
        return out

    headerPos := RegExMatch(flat, "i)¹øÈ£\s*(?:Ç°\s*¸í\s*)?±Ô°Ý\s*¼ö·®\s*´ÜÀ§\s*´Ü°¡\s*±Ý¾×", h)
    if (!headerPos)
        return out

    data := LTrim(SubStr(flat, headerPos + StrLen(h)))
    expected := 1
    unitPat := "(?:Åë|°û|¹Ú½º|BOX|¹­À½|ÄÓ·¹|°³|´ë|½Ä|¼¼Æ®|SET|EA|º´|±Ç|¸Å)"

    while (data != "")
    {
        ; ¹øÈ£ + Ç°¸í/±Ô°Ý + ¼ö·® + ´ÜÀ§ + ´Ü°¡ + ±Ý¾×
        ; ´ÜÀ§¿Í ´Ü°¡´Â PDF¿¡¼­ ºÙ¾î¼­ º¹»çµÉ ¼ö ÀÖÀ¸¹Ç·Î »çÀÌ °ø¹éÀº ¼±ÅÃ»çÇ×ÀÔ´Ï´Ù.
        pat := "is)^\s*" . expected . "\s*(.+?)\s*(\d+(?:\.\d+)?)\s*(" . unitPat . ")\s*([\d,]+)\s+([\d,]+)"
        if !RegExMatch(data, pat, m)
        {
            if (expected = 1)
                return SSOK_Expense_NewGenericResult()

            ; PDF Ç¥ÀÇ ¸¶Áö¸· ºó Çà(¿¹: "20- 884,300")Àº ½ÇÁ¦ Ç°¸ñÀÌ ¾Æ´Õ´Ï´Ù.
            ; ÀÌ °æ¿ì ¾Õ ¹øÈ£±îÁö Á¤»ó Ç°¸ñÀ¸·Î ÀÎÁ¤ÇÏ°í ¿©±â¼­ Á¾·áÇÕ´Ï´Ù.
            if RegExMatch(data, "^\s*" . expected . "\s*-\s*(?:[\d,]+\s*)?$")
                break

            ; ´ÙÀ½ ¹øÈ£°¡ º¸ÀÌ´Âµ¥ ÇàÀ» ¸ø ÀÐ¾ú´Ù¸é ÀÏºÎ¸¸ ÀÔ·ÂÇÏÁö ¾Ê°í Áß´ÜÇÕ´Ï´Ù.
            if RegExMatch(data, "^\s*" . expected . "\s*[^\d\s,]")
                out.error := "PDF °ßÀû¼­ÀÇ " . expected . "¹ø Ç°¸ñ¿¡¼­ ¼ö·®¡¤´ÜÀ§¡¤´Ü°¡¡¤±Ý¾×À» ÀÐÁö ¸øÇß½À´Ï´Ù."
            break
        }

        descriptor := Trim(m1)
        qty := SSOK_Expense_Number(m2)
        unitPrice := SSOK_Expense_Number(m4)
        finalAmount := SSOK_Expense_Number(m5)

        if (descriptor = "" || qty = "" || qty <= 0 || unitPrice = "" || finalAmount = "" || finalAmount < 0)
        {
            out.error := "PDF °ßÀû¼­ÀÇ " . expected . "¹ø Ç°¸ñÀ» Á¤È®È÷ ÀÐÁö ¸øÇß½À´Ï´Ù."
            return out
        }

        ; ´Ü°¡¡¿¼ö·®°ú ±Ý¾×ÀÌ ¸ÂÁö ¾ÊÀ¸¸é Àß¸øµÈ ¼ýÀÚ¸¦ ¼ö·®À¸·Î ÀâÀº °ÍÀÌ¹Ç·Î Áß´ÜÇÕ´Ï´Ù.
        if (Round(unitPrice * qty) != Round(finalAmount))
        {
            out.error := "PDF °ßÀû¼­ÀÇ " . expected . "¹ø Ç°¸ñ ±Ý¾× °ËÁõ¿¡ ½ÇÆÐÇß½À´Ï´Ù."
            return out
        }

        SSOK_Expense_SplitPdfNameSpec(descriptor, name, spec)
        if (name = "")
            name := descriptor

        ; ¿øº» ´Ü°¡¸¦ ±×´ë·Î »ç¿ëÇÕ´Ï´Ù. ±Ý¾×Àº ¿øº» ±Ý¾×À¸·Î º¸Á¸ÇÕ´Ï´Ù.
        out.rows.Push({name:name, spec:spec, qty:qty, amount:finalAmount, price:unitPrice})
        out.total += finalAmount

        data := LTrim(SubStr(data, StrLen(m) + 1))
        expected++
    }

    if (!out.rows.Length())
        return SSOK_Expense_NewGenericResult()

    return out
}


; ============================================================================
; PDF Ãß°¡ ¾ç½Ä 2
;   No / Ç°¸ñ¸í / ±Ô°Ý / ´ÜÀ§ / ÃÑ¼ö·® / ´Ü°¡ / ±Ý¾× / ºñ°í
;
; ÀÏºÎ PDF´Â º¹»ç ¼ø¼­°¡ ½Ã°¢ÀûÀÎ ¿­ ¼ø¼­¿Í ´Þ¶óÁ® Ã¹ ÇàÀÇ ÀÏºÎ°¡
; ¸Ó¸®±Û "´Ü°¡/±Ý¾×/ºñ°í" ¾ÕµÚ·Î °¥¶óÁö´Â °æ¿ì°¡ ÀÖ½À´Ï´Ù.
; Á¤»ó Çà ¼ø¼­¿Í ÀÌ ¼¯ÀÎ ¼ø¼­¸¦ ¸ðµÎ Ã³¸®ÇÕ´Ï´Ù.
; ============================================================================
SSOK_Expense_ParsePdfMaintenanceMixed(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "PDF °ßÀû¼­(No/Ç°¸ñ¸í/±Ô°Ý/ÃÑ¼ö·® ÀÚµ¿ÀÎ½Ä)"

    flat := StrReplace(text, "`r", " ")
    flat := StrReplace(flat, "`n", " ")
    flat := StrReplace(flat, Chr(160), " ")
    flat := StrReplace(flat, "¡¡", " ")
    flat := RegExReplace(flat, "[ `t]+", " ")
    flat := Trim(flat)

    compact := RegExReplace(flat, "\s+", "")
    if (!RegExMatch(compact, "i)NoÇ°¸ñ¸í±Ô°Ý´ÜÀ§ÃÑ¼ö·®")
        || !RegExMatch(compact, "i)´Ü°¡±Ý¾×ºñ°í"))
        return out

    unitPat := "(?:Åë|°û|¹Ú½º|BOX|¹­À½|ÄÓ·¹|°³|´ë|½Ä|¼¼Æ®|SET|EA|º´|±Ç|¸Å)"

    ; --------------------------------------------------------
    ; A. ¸Ó¸®±Û µÚ¿¡ °¢ ÇàÀÌ Á¤»ó ¼ø¼­·Î ÀÌ¾îÁö´Â °æ¿ì
    ; --------------------------------------------------------
    headerPos := RegExMatch(flat, "i)No\s*Ç°\s*¸ñ¸í\s*±Ô°Ý\s*´ÜÀ§\s*ÃÑ\s*¼ö·®\s*´Ü°¡\s*±Ý¾×\s*ºñ\s*°í", fullHeader)
    if (headerPos)
    {
        data := LTrim(SubStr(flat, headerPos + StrLen(fullHeader)))
        expected := 1

        while (data != "")
        {
            nextNo := expected + 1
            pat := "is)^\s*" . expected . "\s*(.+?)\s+(" . unitPat . ")\s+(\d+(?:\.\d+)?)\s+([\d,]+)\s+([\d,]+)(?:\s+(.*?))?(?=\s*" . nextNo . "\s*[^\d\s,]|\s*$)"
            if !RegExMatch(data, pat, m)
                break

            descriptor := Trim(m1)
            qty := SSOK_Expense_Number(m3)
            unitPrice := SSOK_Expense_Number(m4)
            finalAmount := SSOK_Expense_Number(m5)

            if (descriptor = "" || qty = "" || qty <= 0 || unitPrice = "" || finalAmount = "")
                break

            SSOK_Expense_SplitPdfNameSpec(descriptor, name, spec)
            if (name = "")
                name := descriptor

            out.rows.Push({name:name, spec:spec, qty:qty, amount:finalAmount, price:unitPrice})
            out.total += finalAmount

            data := LTrim(SubStr(data, StrLen(m) + 1))
            expected++
        }

        if (out.rows.Length())
            return out
    }

    ; --------------------------------------------------------
    ; B. ½ÇÁ¦ È®ÀÎµÈ PDF º¹»ç ¼ø¼­:
    ;   No/Ç°¸ñ¸í/±Ô°Ý/´ÜÀ§/ÃÑ¼ö·®
    ;   1¹ø Ç°¸ñ¸í/±Ô°Ý
    ;   ´Ü°¡/±Ý¾×/ºñ°í
    ;   1¹ø ´ÜÀ§/¼ö·®
    ;   2¹ø Ç°¸ñ¸í/±Ô°Ý
    ;   1¹ø ´Ü°¡/±Ý¾×/ºñ°í
    ;   2¹ø ´ÜÀ§/¼ö·®/´Ü°¡/±Ý¾×/ºñ°í
    ; --------------------------------------------------------
    header2Pos := RegExMatch(flat, "i)´Ü°¡\s*±Ý¾×\s*ºñ\s*°í", header2)
    if (!header2Pos)
        return SSOK_Expense_NewGenericResult()

    left := Trim(SubStr(flat, 1, header2Pos - 1))
    right := LTrim(SubStr(flat, header2Pos + StrLen(header2)))

    if !RegExMatch(left, "is)ÃÑ\s*¼ö·®\s*1\s*(.+?)\s+(\S+)\s*$", a)
        return SSOK_Expense_NewGenericResult()

    ; ÇöÀç È®ÀÎµÈ ÀÌ PDF ¹èÄ¡¿¡¼­´Â 2°³ Ç°¸ñÀÇ ÁÂ/¿ì ¿­ÀÌ À§ ¼ø¼­·Î ¼¯¿© µé¾î¿É´Ï´Ù.
    pat2 := "is)^\s*(" . unitPat . ")\s+(\d+(?:\.\d+)?)\s+2\s*(.+?)\s+(\S+)\s+([\d,]+)\s+([\d,]+)\s+(.*?)\s+(" . unitPat . ")\s+(\d+(?:\.\d+)?)\s+([\d,]+)\s+([\d,]+)\s*(.*)$"
    if !RegExMatch(right, pat2, b)
        return SSOK_Expense_NewGenericResult()

    name1 := Trim(a1)
    spec1 := Trim(a2)
    qty1 := SSOK_Expense_Number(b2)
    unitPrice1 := SSOK_Expense_Number(b5)
    amount1 := SSOK_Expense_Number(b6)

    name2 := Trim(b3)
    spec2 := Trim(b4)
    qty2 := SSOK_Expense_Number(b9)
    unitPrice2 := SSOK_Expense_Number(b10)
    amount2 := SSOK_Expense_Number(b11)

    if (name1 = "" || name2 = "" || qty1 <= 0 || qty2 <= 0
        || unitPrice1 = "" || unitPrice2 = "" || amount1 = "" || amount2 = "")
    {
        out.error := "PDF °ßÀû¼­ÀÇ Ç°¸ñ¸í¡¤¼ö·®¡¤´Ü°¡¡¤±Ý¾×À» Á¤È®È÷ ÀÐÁö ¸øÇß½À´Ï´Ù."
        return out
    }

    out.rows.Push({name:name1, spec:spec1, qty:qty1, amount:amount1, price:unitPrice1})
    out.rows.Push({name:name2, spec:spec2, qty:qty2, amount:amount2, price:unitPrice2})
    out.total := amount1 + amount2

    return out
}


; Ç°¸í°ú ±Ô°ÝÀÌ ºÙ¾î¼­ º¹»çµÈ PDF¿ë º¸Á¶ ºÐ¸®±âÀÔ´Ï´Ù.
; È®½ÇÈ÷ ±¸ºÐµÇ´Â °æ¿ì¸¸ ±Ô°ÝÀ¸·Î ¶¼°í, ¾Ö¸ÅÇÏ¸é ÀüÃ¼¸¦ Ç°¸íÀ¸·Î º¸Á¸ÇÕ´Ï´Ù.
SSOK_Expense_SplitPdfNameSpec(descriptor, ByRef name, ByRef spec)
{
    descriptor := Trim(RegExReplace(descriptor, "[ `t]+", " "))
    name := descriptor
    spec := ""

    if (descriptor = "")
        return

    ; ¿¹: ¹°Æ¼½´100¸Å/Ä¸Çü/10°³ÀÔ, Åõ¸íºñ´ÒºÀÅõ50L*70¸ÅÀÔ
    if RegExMatch(descriptor, "i)^([°¡-ÆRA-Za-z()]+?)(\d.*(?:¸Å|°³|ÀÔ|L|ml|mL|cm|mm|\*).*)$", m)
    {
        name := Trim(m1)
        spec := Trim(m2)
        return
    }

    ; ¿¹: ÀÏÈ¸¿ë¸¶½ºÅ©/À¯ÇÑ½Ç²öÇü/50¸Å, Ã»¼ö¼¼¹Ì/3M 5°³ÀÔ
    slashPos := InStr(descriptor, "/")
    spacePos := InStr(descriptor, " ")
    if (slashPos > 1 && (spacePos = 0 || slashPos < spacePos))
    {
        name := Trim(SubStr(descriptor, 1, slashPos - 1))
        spec := Trim(SubStr(descriptor, slashPos + 1))
        return
    }

    ; ¿¹: ¸°½ºR(¼¼Ã´±â¸°½º) 18.7L, °í¹«Àå°©(ÅÂÈ­) L/ºÐÈ«
    if RegExMatch(descriptor, "^(.+?)\s+((?:\d|[A-Za-z]).*)$", m)
    {
        name := Trim(m1)
        spec := Trim(m2)
    }
}


; ============================================================================
; PDF ¾ÐÃàÇü Ç¥ ÆÄ¼­
;
; PDF¿¡¼­ ¹üÀ§ ÁöÁ¤ º¹»ç ½Ã ¼¿¸¶´Ù ÁÙ¹Ù²ÞµÇÁö ¾Ê°í ´ÙÀ½Ã³·³ ÇÑ ÇàÀ¸·Î
; ÇÕÃÄÁö´Â °æ¿ì¸¦ Ã³¸®ÇÕ´Ï´Ù.
;
; Çü½Ä A
; 1 Service Package(ÅëÇÕÀüÇØÁ¶) 1 500,000 50,000 550,000
;   = ¹øÈ£ / Ç°¸í / ¼ö·® / ±Ý¾× / VAT / ÇÕ°è
;
; Çü½Ä B
; 1 ¸¶¼ú»ç EA 16 13,000 189,091 18,909 208,000
;   = ¹øÈ£ / Ç°¸ñ¡¤±Ô°Ý / ´ÜÀ§ / ¼ö·® / ´Ü°¡ / °ø±Þ°¡ / ¼¼¾× / ÇÕ°è
;
; µÎ Çü½Ä ¸ðµÎ K-¿¡µàÆÄÀÎ ¿¹»ó´Ü°¡´Â VAT Æ÷ÇÔ ÃÖÁ¾ "ÇÕ°è ¡À ¼ö·®"À»
; ±âÁØÀ¸·Î ¸¸µì´Ï´Ù.
; ============================================================================
SSOK_Expense_ParseGenericPdfCompact(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "PDF °ßÀû¼­(Çà ÀÚµ¿ÀÎ½Ä)"

    cleanText := StrReplace(text, "`r")
    flatHeader := RegExReplace(cleanText, "[\s/¡¤¤ý_\-().]+", "")

    mode := 0

    ; Çü½Ä A: Ç°¸í / ¼ö·® / ±Ý¾× / ºÎ°¡¼¼ / ÇÕ°è
    if ((InStr(cleanText, "ºÎ°¡¼¼") || InStr(cleanText, "VAT"))
        && (InStr(cleanText, "ÇÕ°è") || InStr(cleanText, "Total"))
        && (InStr(cleanText, "±Ý¾×") || InStr(cleanText, "Amount")))
    {
        mode := 1
    }
    ; Çü½Ä B: Ç°¸ñ¡¤±Ô°Ý / ´ÜÀ§ / ¼ö·® / ´Ü°¡ / °ø±Þ°¡ / ¼¼¾× / ÇÕ°è
    else if (InStr(flatHeader, "Ç°¸ñ±Ô°Ý")
        && InStr(flatHeader, "´ÜÀ§")
        && InStr(flatHeader, "¼ö·®")
        && InStr(flatHeader, "´Ü°¡")
        && InStr(flatHeader, "°ø±Þ°¡")
        && InStr(flatHeader, "¼¼¾×")
        && InStr(flatHeader, "ÇÕ°è"))
    {
        mode := 2
    }

    if (!mode)
        return out

    expected := 1
    started := false

    for _, rawLine in StrSplit(cleanText, "`n")
    {
        line := Trim(rawLine, " `t" . Chr(160))
        if (line = "")
            continue

        ; ¿©·¯ Á¾·ùÀÇ Æ¯¼ö °ø¹éÀ» ÀÏ¹Ý °ø¹éÀ¸·Î Á¤¸®
        line := StrReplace(line, Chr(160), " ")
        line := StrReplace(line, "¡¡", " ")
        line := RegExReplace(line, "[ `t]+", " ")
        line := Trim(line)

        matched := false

        if (mode = 1)
        {
            ; ¹øÈ£ + Ç°¸í + ¼ö·® + ±Ý¾× + VAT + ÇÕ°è
            if RegExMatch(line, "^(\d+)\s+(.+?)\s+(\d+(?:\.\d+)?)\s+([\d,]+)\s+([\d,]+)\s+([\d,]+)\s*$", m)
            {
                rowNo := m1 + 0
                name := Trim(m2)
                qty := SSOK_Expense_Number(m3)
                finalAmount := SSOK_Expense_Number(m6)
                matched := true
            }
        }
        else if (mode = 2)
        {
            ; ¹øÈ£ + Ç°¸ñ¡¤±Ô°Ý + ´ÜÀ§ + ¼ö·® + ´Ü°¡ + °ø±Þ°¡ + ¼¼¾× + ÇÕ°è
            if RegExMatch(line, "^(\d+)\s+(.+?)\s+(\S+)\s+(\d+(?:\.\d+)?)\s+([\d,]+)\s+([\d,]+)\s+([\d,]+)\s+([\d,]+)\s*$", m)
            {
                rowNo := m1 + 0
                name := Trim(m2)
                qty := SSOK_Expense_Number(m4)
                finalAmount := SSOK_Expense_Number(m8)
                matched := true
            }
        }

        if (!matched)
            continue

        ; 1¹øºÎÅÍ ½ÇÁ¦ Ç°¸ñ ½ÃÀÛ
        if (!started)
        {
            if (rowNo != 1)
                continue

            started := true
        }

        if (rowNo != expected)
        {
            out.error := "PDF °ßÀû¼­ÀÇ Ç°¸ñ ¹øÈ£°¡ 1¹øºÎÅÍ ¿¬¼ÓµÇÁö ¾Ê½À´Ï´Ù.`n¿¹»ó ¹øÈ£: " . expected . "`nÀÎ½Ä ¹øÈ£: " . rowNo
            return out
        }

        if (name = "" || qty = "" || qty <= 0 || finalAmount = "" || finalAmount < 0)
        {
            out.error := "PDF °ßÀû¼­ÀÇ " . rowNo . "¹ø Ç°¸ñ¿¡¼­ Ç°¸í¡¤¼ö·®¡¤ÇÕ°è¸¦ Á¤È®È÷ ÀÐÁö ¸øÇß½À´Ï´Ù."
            return out
        }

        price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)

        out.rows.Push({name:name, spec:"", qty:qty, amount:finalAmount, price:price})
        out.total += finalAmount
        expected++
    }

    if (!out.rows.Length())
        return SSOK_Expense_NewGenericResult()

    return out
}



; ============================================================================
; S2B À¥º¹»ç °ßÀû/¹°Ç° Ç¥ Àü¿ë ÆÄ¼­
;
; À¥¿¡¼­ º¹»çÇÑ S2B Ç¥´Â HTMLÀÇ rowspan/colspan ¶§¹®¿¡ ÇÑ Ç°¸ñÀÌ
; ¿©·¯ °³ÀÇ Markdown Ç¥/ÇàÀ¸·Î ºÐ¸®µÇ¾î µé¾î¿Ã ¼ö ÀÖ½À´Ï´Ù.
;
; ÀÎ½Ä ±âÁØ
;   ¹°Ç°¸í(Ã¹ ¹øÂ° fnGoodsInfo ¸µÅ©) -> Ç°¸í
;   ¸ðµ¨¸í(°°Àº ÁÙ <br> µÚ µÎ ¹øÂ° ¸µÅ©) -> ±Ô°Ý
;   Á¦½Ã±Ý¾× -> ´Ü°¡
;   ÃÑÁ¦½Ã±Ý¾× -> ±Ý¾×
;   ¼ö·® -> À¥º¹»ç¿¡¼­ °ªÀÌ ¾øÀ¸¸é ÃÑÁ¦½Ã±Ý¾× / Á¦½Ã±Ý¾×À¸·Î º¹¿ø
;
; ¿äÃ»ÀÚ/À¯È¿±â°£/¹è¼Ûºñ/°ø±Þ¾÷Ã¼/¼öÀÇ½Ã´ãÀº Ç°¸ñ ÀÔ·Â¿¡¼­ Á¦¿ÜÇÕ´Ï´Ù.
; ============================================================================
; ============================================================================
; S2B À¥º¹»ç Àü¿ë ÆÄ¼­
;
; ÇÙ½É ¿øÄ¢
; 1) Ç°¸ñÀº fnGoodsInfoÀÇ "»óÇ° ID" ´ÜÀ§·Î ¹­½À´Ï´Ù.
;    - ¸ðµ¨¸íÀÌ ¾øÀ¸¸é ¸µÅ© 1°³: Ç°¸í¸¸ »ç¿ë
;    - ¸ðµ¨¸íÀÌ ÀÖÀ¸¸é °°Àº »óÇ° ID ¸µÅ© 2°³: Ã¹ ¸µÅ©=Ç°¸í, µÑÂ°=±Ô°Ý
; 2) ±Ý¾× ÇàÀº ¿­ À§Ä¡ ±âÁØÀ¸·Î ÀÐ½À´Ï´Ù.
;    ³¯Â¥ ´ÙÀ½ Ä­ = ¼ö·®, ±× ´ÙÀ½ = Á¦½Ã±Ý¾×, ±× ´ÙÀ½ = ÃÑÁ¦½Ã±Ý¾×
; 3) ¼ö·®ÀÌ ºñ¾î ÀÖÀ¸¸é ÃÑÁ¦½Ã±Ý¾× / Á¦½Ã±Ý¾×À¸·Î¸¸ º¹¿øÇÕ´Ï´Ù.
;    ¹è¼Ûºñ µî µÚÂÊ ¼ýÀÚ´Â ¼ö·®/´Ü°¡·Î »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
; ============================================================================
SSOK_Expense_ParseS2BPaste(text)
{
    global SSOK_ExpenseCopiedHtml

    out := {rows: [], source: "S2B À¥º¹»ç", total: 0, shipping: 0, quoteTotal: 0, grandTotal: 0, fractional: false, error: "", recognized: false}

    compact := RegExReplace(text, "[\s" . Chr(160) . "¡¡|/¡¤¤ý_\-().]+", "")

    if !(InStr(compact, "S2B")
        && InStr(compact, "¹°Ç°¿ë¿ª¸í¸ðµ¨¸í")
        && InStr(compact, "Á¦½Ã±Ý¾×"))
        return out

    out.recognized := true

    ; °¢ ¹æ½ÄÀº µ¶¸³ÀûÀ¸·Î ³¡±îÁö ÀÐ°í, °¡Àå ¸¹Àº Ç°¸ñÀ» ÀÐÀº °á°ú¸¦ »ç¿ëÇÕ´Ï´Ù.
    best := {rows: [], total: 0}

    md := {rows: [], total: 0}
    SSOK_Expense_S2B_ParseMarkdown(text, md)
    if (md.rows.Length() > best.rows.Length())
        best := md

    plain := {rows: [], total: 0}
    SSOK_Expense_S2B_ParsePlain(text, plain)
    if (plain.rows.Length() > best.rows.Length())
        best := plain

    ; Çà/¿­ ±¸Á¶°¡ ±úÁø ½ÇÁ¦ ºê¶ó¿ìÀú Clipboard¿ë ÅäÅ« ½ºÆ®¸² ÆÄ¼­
    token := {rows: [], total: 0}
    SSOK_Expense_S2B_ParseTokenStream(text, token)
    if (token.rows.Length() > best.rows.Length())
        best := token

    if (SSOK_ExpenseCopiedHtml != "")
    {
        html := {rows: [], total: 0}
        SSOK_Expense_S2B_ParseHtml(SSOK_ExpenseCopiedHtml, html)
        if (html.rows.Length() > best.rows.Length())
            best := html
    }

    out.rows := best.rows
    out.total := best.total

    SSOK_Expense_Log("s2b-scan md=" . md.rows.Length()
        . " plain=" . plain.rows.Length()
        . " token=" . token.rows.Length()
        . " html=" . (IsObject(html) ? html.rows.Length() : 0)
        . " tabs=" . (InStr(text, "`t") ? 1 : 0)
        . " textLen=" . StrLen(text)
        . " htmlLen=" . StrLen(SSOK_ExpenseCopiedHtml))

    if (!out.rows.Length())
    {
        out.error := "S2B Ç¥´Â È®ÀÎÇßÁö¸¸ Ç°¸ñÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`n¹°Ç°(¿ë¿ª)¸í/¸ðµ¨¸í°ú ¼ö·®¡¤Á¦½Ã±Ý¾×ÀÌ Æ÷ÇÔµÇµµ·Ï Ç¥¸¦ º¹»çÇØ ÁÖ¼¼¿ä."
        return out
    }

    SSOK_Expense_Log("s2b-items-ok rows=" . out.rows.Length())
    return out
}

; ------------------------------------------------------------
; Markdown Çü½Ä
; ÇÑ »óÇ° ÁÙ ¾È¿¡¼­ °°Àº »óÇ° IDÀÇ fnGoodsInfo ¸µÅ©¸¦ ¹­½À´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_S2B_ParseMarkdown(text, out)
{
    groups := []
    lines := StrSplit(text, "`n")

    for lineNo, rawLine in lines
    {
        line := Trim(rawLine, " `t`r" . Chr(160))
        if (!InStr(line, "fnGoodsInfo"))
            continue

        links := []
        pos := 1

        ; javascript\:fnGoodsInfo / javascript:fnGoodsInfo µÑ ´Ù Çã¿ë
        while (pos := RegExMatch(line, "\[([^\]]+)\]\((?:<)?javascript\\?:fnGoodsInfo\('([0-9]+)'", m, pos))
        {
            label := Trim(m1, " `t`r`n" . Chr(160))
            id := m2

            if (label != "" && id != "")
                links.Push({id:id, text:label})

            pos += Max(1, StrLen(m))
        }

        if (!links.Length())
            continue

        ; ÇÑ Ç°¸ñ ÁÙÀÇ Ã¹ ¸µÅ©´Â Ç°¸í.
        ; µÎ ¹øÂ° ¸µÅ©°¡ ÀÖ°í »óÇ° ID°¡ °°À» ¶§¸¸ ±Ô°ÝÀ¸·Î »ç¿ëÇÕ´Ï´Ù.
        group := {line:lineNo, id:links[1].id, name:links[1].text, spec:""}

        if (links.Length() >= 2 && links[2].id = group.id)
            group.spec := links[2].text

        groups.Push(group)
    }

    if (!groups.Length())
        return false

    for gi, g in groups
    {
        nextLine := (gi < groups.Length()) ? groups[gi + 1].line : lines.Length() + 1

        Loop, % nextLine - g.line - 1
        {
            lineNo := g.line + A_Index
            line := lines[lineNo]

            if !RegExMatch(line, "\b\d{4}-\d{2}-\d{2}\b")
                continue

            if (SSOK_Expense_S2B_ParseMarkdownAmountRow(line, qty, unitPrice, amount))
            {
                out.rows.Push({name:g.name, spec:g.spec, qty:qty, amount:amount, price:unitPrice})
                out.total += amount
                break
            }
        }
    }

    return out.rows.Length() > 0
}

SSOK_Expense_S2B_ParseMarkdownAmountRow(line, ByRef qty, ByRef unitPrice, ByRef amount)
{
    qty := ""
    unitPrice := ""
    amount := ""

    cells := StrSplit(line, "|")
    datePos := 0

    for ci, rawCell in cells
    {
        cell := SSOK_Expense_S2B_CleanCell(rawCell)
        if RegExMatch(cell, "^\d{4}-\d{2}-\d{2}$")
        {
            datePos := ci
            break
        }
    }

    if (!datePos)
        return false

    nums := []

    ; ³¯Â¥ µÚ¿¡¼­ ¸µÅ©/¾÷Ã¼¸íÀÌ ³ª¿À±â ÀüÀÇ ¾ÕÂÊ ¼ýÀÚ¸¸ ¼öÁýÇÕ´Ï´Ù.
    Loop, % cells.Length() - datePos
    {
        ci := datePos + A_Index
        raw := cells[ci]
        cell := SSOK_Expense_S2B_CleanCell(raw)

        if (InStr(raw, "javascript") || InStr(raw, "http")
            || InStr(raw, "[image]") || InStr(raw, "fnSupplyInfo")
            || InStr(raw, "fnBagain"))
            break

        n := SSOK_Expense_S2B_Number(cell)
        if (n != "")
        {
            nums.Push(n)
            if (nums.Length() >= 3)
                break
        }
    }

    return SSOK_Expense_S2B_ResolveLeadingNumbers(nums, qty, unitPrice, amount)
}

; ------------------------------------------------------------
; ÀÏ¹Ý ÅØ½ºÆ®/ÅÇ Å¬¸³º¸µå
; S2B ÇàÀ» ¸¸³ª¸é »õ Ç°¸ñ ½ÃÀÛÀ¸·Î º¸°í ±× ´ÙÀ½ Ç°¸í/±Ô°ÝÀ» ¼öÁýÇÕ´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_S2B_ParsePlain(text, out)
{
    table := SSOK_Expense_ExcelBuildRows(text)
    if !IsObject(table) || !table.Length()
        return false

    active := false
    pendingName := ""
    pendingSpec := ""

    for _, row in table
    {
        if !IsObject(row)
            continue

        hasS2B := false
        datePos := 0

        for ci, rawCell in row
        {
            cell := SSOK_Expense_S2B_CleanCell(rawCell)

            if (cell = "S2B")
                hasS2B := true

            if RegExMatch(cell, "^\d{4}-\d{2}-\d{2}$")
                datePos := ci
        }

        ; ¿äÃ»ÀÚ/S2B/ÀÌ¹ÌÁö ÇàÀº Ç°¸ñ µ¥ÀÌÅÍ°¡ ¾Æ´Ï¸ç ´ÙÀ½ Ç°¸ñÀÇ ½ÃÀÛÁ¡ÀÔ´Ï´Ù.
        if (hasS2B)
        {
            active := true
            pendingName := ""
            pendingSpec := ""
            continue
        }

        if (!active)
            continue

        if (datePos)
        {
            if (pendingName != "")
            {
                nums := []
                Loop, % row.Length() - datePos
                {
                    ci2 := datePos + A_Index
                    raw2 := row[ci2]
                    cell2 := SSOK_Expense_S2B_CleanCell(raw2)

                    if (InStr(raw2, "javascript") || InStr(raw2, "http")
                        || InStr(raw2, "image") || InStr(raw2, "fnSupplyInfo")
                        || InStr(raw2, "fnBagain"))
                        break

                    n2 := SSOK_Expense_S2B_Number(cell2)
                    if (n2 != "")
                    {
                        nums.Push(n2)
                        if (nums.Length() >= 3)
                            break
                    }
                }

                if (SSOK_Expense_S2B_ResolveLeadingNumbers(nums, qty, unitPrice, amount))
                {
                    out.rows.Push({name:pendingName, spec:pendingSpec, qty:qty, amount:amount, price:unitPrice})
                    out.total += amount
                }
            }

            active := false
            pendingName := ""
            pendingSpec := ""
            continue
        }

        ; S2B ½ÃÀÛÇà ´ÙÀ½ºÎÅÍ ³¯Â¥Çà Àü±îÁö º¸ÀÌ´Â ÅØ½ºÆ® Áß
        ; Ã¹ ¹øÂ°¸¦ Ç°¸í, µÎ ¹øÂ°¸¦ ±Ô°ÝÀ¸·Î »ç¿ëÇÕ´Ï´Ù.
        for _, rawCell in row
        {
            cell := SSOK_Expense_S2B_CleanCell(rawCell)

            if !SSOK_Expense_S2B_IsProductText(cell)
                continue

            if (pendingName = "")
                pendingName := cell
            else if (pendingSpec = "" && cell != pendingName)
                pendingSpec := cell
        }
    }

    return out.rows.Length() > 0
}

; ------------------------------------------------------------
; CF_HTML Å¬¸³º¸µå
; fnGoodsInfo ¸µÅ©¸¦ »óÇ° ID·Î ±×·ìÈ­ÇÕ´Ï´Ù.
; ¸ðµ¨¸íÀÌ ¾ø´Â Ç°¸ñµµ 1°³ÀÇ ¸µÅ©¸¸À¸·Î Á¤»ó Ç°¸ñ Ã³¸®ÇÕ´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_S2B_ParseTokenStream(text, out)
{
    ; ÅÇ/ÁÙ¹Ù²ÞÀ» ¸ðµÎ µ¿ÀÏÇÑ ÅäÅ« °æ°è·Î º¾´Ï´Ù.
    normalized := StrReplace(text, "`r`n", "`n")
    normalized := StrReplace(normalized, "`r", "`n")
    normalized := StrReplace(normalized, "`t", "`n")

    tokens := []
    for _, raw in StrSplit(normalized, "`n")
    {
        t := SSOK_Expense_S2B_CleanCell(raw)
        if (t != "")
            tokens.Push(t)
    }

    if (!tokens.Length())
        return false

    active := false
    skipRequester := false
    name := ""
    spec := ""
    i := 1

    while (i <= tokens.Length())
    {
        tok := tokens[i]
        compact := RegExReplace(tok, "[\s" . Chr(160) . "¡¡|]", "")

        ; S2B Ç¥ÀÇ »õ Ç°¸ñ ½ÃÀÛ
        if (compact = "S2B")
        {
            active := true
            skipRequester := true
            name := ""
            spec := ""
            i++
            continue
        }

        if (!active)
        {
            i++
            continue
        }

        ; ³¯Â¥¸¦ ¸¸³ª¸é ±× µÚ ¾ÕÂÊ ¼ýÀÚµé·Î ¼ö·®/´Ü°¡/ÃÑ¾×À» È®Á¤
        if RegExMatch(tok, "^\d{4}-\d{2}-\d{2}$")
        {
            nums := []
            j := i + 1

            while (j <= tokens.Length() && nums.Length() < 3)
            {
                t2 := tokens[j]
                c2 := RegExReplace(t2, "[\s" . Chr(160) . "¡¡]", "")

                if (c2 = "S2B" || c2 = "Y" || c2 = "N")
                    break

                if (InStr(t2, "javascript") || InStr(t2, "http")
                    || InStr(t2, "image") || InStr(t2, "fnSupplyInfo")
                    || InStr(t2, "fnBagain"))
                    break

                n := SSOK_Expense_S2B_Number(t2)
                if (n != "")
                    nums.Push(n)
                else if (nums.Length() >= 2)
                    break

                j++
            }

            if (name != "" && SSOK_Expense_S2B_ResolveLeadingNumbers(nums, qty, unitPrice, amount))
            {
                out.rows.Push({name:name, spec:spec, qty:qty, amount:amount, price:unitPrice})
                out.total += amount
            }

            active := false
            name := ""
            spec := ""
            i := j
            continue
        }

        ; Ã¹ ¹øÂ° ÅØ½ºÆ®´Â ¿äÃ»ÀÚÀÌ¹Ç·Î °Ç³Ê¶Ý´Ï´Ù.
        if (skipRequester)
        {
            if (SSOK_Expense_S2B_IsProductText(tok))
            {
                skipRequester := false
                i++
                continue
            }
        }
        else if (SSOK_Expense_S2B_IsProductText(tok))
        {
            if (name = "")
                name := SSOK_Expense_S2B_ExtractVisibleLabel(tok)
            else if (spec = "")
            {
                candidate := SSOK_Expense_S2B_ExtractVisibleLabel(tok)
                if (candidate != "" && candidate != name)
                    spec := candidate
            }
        }

        i++
    }

    return out.rows.Length() > 0
}

SSOK_Expense_S2B_ExtractVisibleLabel(s)
{
    ; Markdown ¸µÅ©¸é [] ¾ÈÀÇ º¸ÀÌ´Â ±ÛÀÚ¸¸ »ç¿ë
    if RegExMatch(s, "^\[([^\]]+)\]", m)
        return Trim(m1)

    ; <br> µÚ ¸ðµ¨¸íÀÌ ÇÔ²² ºÙÀº °æ¿ì 2°³·Î ³ª´©´Â °ÍÀº Plain ÆÄ¼­°¡ Ã³¸®ÇÏ¸ç,
    ; ¿©±â¼­´Â ÀüÃ¼ º¸ÀÌ´Â ¹®ÀÚ¿­À» Ç°¸í ÈÄº¸·Î µÓ´Ï´Ù.
    return Trim(s)
}

SSOK_Expense_S2B_ResolveLeadingNumbers(nums, ByRef qty, ByRef unitPrice, ByRef amount)
{
    qty := ""
    unitPrice := ""
    amount := ""

    count := nums.Length()
    if (count < 2)
        return false

    a := nums[1]
    b := nums[2]

    ; ¼ö·®ÀÌ ½ÇÁ¦·Î º¹»çµÈ °æ¿ì:
    ; ¿¹) 8, 21,000, 168,000  => 8 ¡¿ 21,000 = 168,000
    if (count >= 3)
    {
        c := nums[3]

        if (a >= 1 && a = Round(a) && a <= 9999
            && b > 0 && c > 0
            && Abs((a * b) - c) < 0.000001)
        {
            qty := Round(a)
            unitPrice := b
            amount := c
            return true
        }
    }

    ; S2B À¥º¹»ç¿¡¼­ ¼ö·® Ä­ÀÌ ºó °æ¿ì:
    ; ¾ÕÀÇ µÎ ¼ýÀÚ°¡ Á¦½Ã±Ý¾× / ÃÑÁ¦½Ã±Ý¾×ÀÔ´Ï´Ù.
    ; µÚÀÇ ¼¼ ¹øÂ° ¼ýÀÚ°¡ ¹è¼Ûºñ¿©µµ ¹«½ÃÇÕ´Ï´Ù.
    if (a > 0 && b > 0)
    {
        ratio := b / a
        inferred := Round(ratio)

        if (inferred >= 1 && Abs(ratio - inferred) < 0.000001)
        {
            qty := inferred
            unitPrice := a
            amount := b
            return true
        }
    }

    return false
}

SSOK_Expense_S2B_ParseHtml(html, out)
{
    if (html = "")
        return false

    anchors := []
    pos := 1

    while (pos := RegExMatch(html, "is)<a\b([^>]*)>(.*?)</a>", m, pos))
    {
        attrs := m1
        body := m2

        if InStr(attrs, "fnGoodsInfo")
        {
            id := ""
            if RegExMatch(attrs, "([0-9]{10,})", im)
                id := im1

            label := SSOK_Expense_S2B_HtmlText(body)

            if (id != "" && label != "")
                anchors.Push({id:id, text:label, pos:pos, len:StrLen(m)})
        }

        pos += Max(1, StrLen(m))
    }

    if (!anchors.Length())
        return false

    groups := []
    current := ""

    for _, a in anchors
    {
        if !IsObject(current) || current.id != a.id
        {
            if IsObject(current)
                groups.Push(current)

            current := {id:a.id, name:a.text, spec:"", pos:a.pos, endPos:a.pos + a.len}
        }
        else
        {
            if (current.spec = "" && a.text != current.name)
                current.spec := a.text
            current.endPos := a.pos + a.len
        }
    }

    if IsObject(current)
        groups.Push(current)

    for gi, g in groups
    {
        segStart := g.endPos

        if (gi < groups.Length())
            segLen := groups[gi + 1].pos - segStart
        else
            segLen := StrLen(html) - segStart + 1

        if (segLen < 0)
            segLen := 0

        segment := SubStr(html, segStart, segLen)

        if (SSOK_Expense_S2B_ParseHtmlAmountRow(segment, qty, unitPrice, amount))
        {
            out.rows.Push({name:g.name, spec:g.spec, qty:qty, amount:amount, price:unitPrice})
            out.total += amount
        }
    }

    return out.rows.Length() > 0
}

SSOK_Expense_S2B_ParseHtmlAmountRow(segment, ByRef qty, ByRef unitPrice, ByRef amount)
{
    qty := ""
    unitPrice := ""
    amount := ""

    ; ÅÂ±×/URL/ÀÚ¹Ù½ºÅ©¸³Æ® ¼Ó¼ºÀ» Á¦°ÅÇÑ "È­¸é¿¡ º¸ÀÌ´Â ±ÛÀÚ"¸¸ »ç¿ëÇÕ´Ï´Ù.
    visible := SSOK_Expense_S2B_HtmlText(segment)

    datePos := RegExMatch(visible, "\b\d{4}-\d{2}-\d{2}\b", dm)
    if (!datePos)
        return false

    tail := SubStr(visible, datePos + StrLen(dm))
    nums := []
    pos := 1

    ; ³¯Â¥ µÚ¿¡¼­ Ã³À½ ³ªÅ¸³ª´Â ¼ýÀÚ ÃÖ´ë 3°³¸¸ »ç¿ëÇÕ´Ï´Ù.
    ; ÀÌÈÄ °ø±Þ¾÷Ã¼¸í/±âÅ¸ ¼ýÀÚ´Â º¸Áö ¾Ê½À´Ï´Ù.
    while (pos := RegExMatch(tail, "(?<![\d,])(\d[\d,]*(?:\.\d+)?)(?![\d,])", nm, pos))
    {
        val := StrReplace(nm1, ",") + 0
        nums.Push(val)

        if (nums.Length() >= 3)
            break

        pos += Max(1, StrLen(nm))
    }

    return SSOK_Expense_S2B_ResolveLeadingNumbers(nums, qty, unitPrice, amount)
}

; ------------------------------------------------------------
; ¼ö·®/´Ü°¡/ÃÑ¾× È®Á¤
; q = ¼ö·®, p = Á¦½Ã±Ý¾×, t = ÃÑÁ¦½Ã±Ý¾×
; ------------------------------------------------------------
SSOK_Expense_S2B_ResolveQPT(q, p, t, ByRef qty, ByRef unitPrice, ByRef amount)
{
    qty := ""
    unitPrice := ""
    amount := ""

    if (p = "" || p <= 0)
        return false

    unitPrice := p

    ; ¼ö·®ÀÌ È­¸é¿¡¼­ Á¤»ó º¹»çµÈ °æ¿ì
    if (q != "" && q > 0 && q = Round(q))
    {
        qty := Round(q)

        if (t != "" && t > 0)
            amount := t
        else
            amount := qty * unitPrice

        return true
    }

    ; ¼ö·®ÀÌ ºñ¾î ÀÖÀ¸¸é ÃÑÁ¦½Ã±Ý¾×/Á¦½Ã±Ý¾×À¸·Î¸¸ º¹¿øÇÕ´Ï´Ù.
    if (t != "" && t > 0)
    {
        ratio := t / unitPrice
        inferred := Round(ratio)

        if (inferred >= 1 && Abs(ratio - inferred) < 0.000001)
        {
            qty := inferred
            amount := t
            return true
        }
    }

    return false
}

SSOK_Expense_S2B_NumberAt(cells, index)
{
    if !IsObject(cells) || index < 1 || index > cells.Length()
        return ""

    return SSOK_Expense_S2B_Number(cells[index])
}

SSOK_Expense_S2B_Number(s)
{
    s := SSOK_Expense_S2B_CleanCell(s)
    s := RegExReplace(s, "[\s" . Chr(160) . "¡¡]", "")

    if RegExMatch(s, "^\d[\d,]*(?:\.\d+)?$")
        return StrReplace(s, ",") + 0

    return ""
}

SSOK_Expense_S2B_CleanCell(s)
{
    s := s . ""
    s := StrReplace(s, "`r", " ")
    s := StrReplace(s, "`n", " ")
    s := StrReplace(s, Chr(160), " ")
    s := StrReplace(s, "¡¡", " ")
    s := RegExReplace(s, "i)<br\s*/?>", " ")
    s := RegExReplace(s, "[ `t]+", " ")
    return Trim(s, " |")
}

SSOK_Expense_S2B_IsProductText(s)
{
    if (s = "")
        return false

    compact := RegExReplace(s, "[\s" . Chr(160) . "¡¡]", "")

    if (compact = "S2B" || compact = "Y" || compact = "N")
        return false

    if (compact = "±¸ºÐ" || compact = "¿äÃ»ÀÚ" || compact = "¹°Ç°(¿ë¿ª)¸í/¸ðµ¨¸í"
        || compact = "À¯È¿±â°£" || compact = "¼ö·®" || compact = "Á¦½Ã±Ý¾×"
        || compact = "ÃÑÁ¦½Ã±Ý¾×" || compact = "¹è¼Ûºñ¹­À½¹è¼Û"
        || compact = "°ø±Þ¾÷Ã¼" || compact = "¼öÀÇ½Ã´ã"
        || InStr(compact, "ÃÑ°è¾à±Ý¾×"))
        return false

    if (InStr(compact, "javascript") || InStr(compact, "http")
        || InStr(compact, "[image]") || InStr(compact, "image")
        || InStr(compact, "fnSearch") || InStr(compact, "fnSupplyInfo")
        || InStr(compact, "fnBagain"))
        return false

    if RegExMatch(compact, "^\d{4}-\d{2}-\d{2}$")
        return false

    if RegExMatch(compact, "^\d[\d,]*(?:\.\d+)?$")
        return false

    if RegExMatch(compact, "^:?-{2,}:?$")
        return false

    return true
}

SSOK_Expense_S2B_HtmlText(html)
{
    if (html = "")
        return ""

    s := html
    s := RegExReplace(s, "is)<script\b[^>]*>.*?</script>", " ")
    s := RegExReplace(s, "is)<style\b[^>]*>.*?</style>", " ")
    s := RegExReplace(s, "is)<br\s*/?>", " ")
    s := RegExReplace(s, "is)</(?:td|th|tr|div|p|li)>", " ")
    s := RegExReplace(s, "is)<[^>]+>", " ")

    s := StrReplace(s, "&nbsp;", " ")
    s := StrReplace(s, "&#160;", " ")
    s := StrReplace(s, "&amp;", "&")
    s := StrReplace(s, "&lt;", "<")
    s := StrReplace(s, "&gt;", ">")
    s := StrReplace(s, "&quot;", """")
    s := StrReplace(s, "&#39;", "'")

    s := StrReplace(s, "`r", " ")
    s := StrReplace(s, "`n", " ")
    s := RegExReplace(s, "[ `t" . Chr(160) . "¡¡]+", " ")

    return Trim(s)
}

; ============================================================================
; YES24 °ßÀû¼­ ºÙ¿©³Ö±â Àü¿ë ÆÄ¼­
;   ¹øÈ£ / ³»¿ë / ±Ô°Ý / ¼ö·® / ¿¹»ó´Ü°¡ / ¿¹»ó±Ý¾×(Âü°í¿ë)
;
; ºê¶ó¿ìÀú¿¡¼­ Ç¥¸¦ º¹»çÇÏ¸é ½ÇÁ¦ Å¬¸³º¸µå°¡ TSV(ÅÇ) ¶Ç´Â
; Markdown/ÆÄÀÌÇÁ Ç¥ ÇüÅÂ·Î µé¾î¿Ã ¼ö ÀÖÀ¸¹Ç·Î µÑ ´Ù Ã³¸®ÇÕ´Ï´Ù.
; °¢ ¼¿ µÚ¿¡ µû¶ó¿À´Â "º¹»ç" ¸µÅ©/¹®±¸´Â ÀÔ·Â µ¥ÀÌÅÍ¿¡¼­ Á¦°ÅÇÕ´Ï´Ù.
; ============================================================================
SSOK_Expense_ParseYes24Paste(text)
{
    out := {rows: [], source: "YES24 °ßÀû¼­(ºÙ¿©³Ö±â)", total: 0, shipping: 0, quoteTotal: 0, grandTotal: 0, fractional: false, error: "", recognized: false}

    compactAll := RegExReplace(text, "[\s" . Chr(160) . "¡¡|/¡¤¤ý_\-().]+", "")

    ; YES24 Çü½Ä A
    ; ¹øÈ£ / ³»¿ë / ±Ô°Ý / ¼ö·® / ¿¹»ó´Ü°¡ / ¿¹»ó±Ý¾×(Âü°í¿ë)
    isSimple := (InStr(compactAll, "¹øÈ£") && InStr(compactAll, "³»¿ë")
        && InStr(compactAll, "±Ô°Ý") && InStr(compactAll, "¼ö·®")
        && InStr(compactAll, "¿¹»ó´Ü°¡") && InStr(compactAll, "¿¹»ó±Ý¾×"))

    ; YES24 µµ¼­ °ßÀû Çü½Ä B
    ; NO. / À¯Çü / ¼­¸í / ÃâÆÇ»ç / ISBN / ¼ö·® / Á¤°¡ / Á¤°¡ÃÑ¾× / °ø±Þ´Ü°¡ / °ø±ÞÃÑ¾×
    isBook := (InStr(compactAll, "¼­¸í") && InStr(compactAll, "ÃâÆÇ»ç")
        && InStr(compactAll, "ISBN") && InStr(compactAll, "¼ö·®")
        && InStr(compactAll, "°ø±Þ´Ü°¡") && InStr(compactAll, "°ø±ÞÃÑ¾×"))

    if (!isSimple && !isBook)
        return out

    table := SSOK_Expense_ExcelBuildRows(text)
    if !IsObject(table) || !table.Length()
        return out

    headerRow := 0
    bookMap := ""

    ; ------------------------------------------------------------
    ; Çü½Ä B: YES24 µµ¼­ °ßÀû¼­
    ; ¼­¸í=Ç°¸ñ, ÃâÆÇ»ç=±Ô°Ý, °ø±Þ´Ü°¡=´Ü°¡, °ø±ÞÃÑ¾×=±Ý¾×
    ; À¯Çü/ISBN/Á¤°¡/Á¤°¡ÃÑ¾×Àº K-¿¡µàÆÄÀÎ ÀÔ·Â¿¡¼­ Á¦¿Ü
    ; ------------------------------------------------------------
    if (isBook)
    {
        for ri, row in table
        {
            if !IsObject(row)
                continue

            m := {no:0, title:0, publisher:0, qty:0, supplyPrice:0, supplyTotal:0}

            for ci, raw in row
            {
                cell := SSOK_Expense_Yes24CleanCell(raw)
                key := RegExReplace(cell, "[\s" . Chr(160) . "¡¡.()]+", "")
                lower := key
                StringLower, lower, lower

                if (lower = "no" || key = "¹øÈ£")
                    m.no := ci
                else if (key = "¼­¸í")
                    m.title := ci
                else if (key = "ÃâÆÇ»ç")
                    m.publisher := ci
                else if (key = "¼ö·®")
                    m.qty := ci
                else if (key = "°ø±Þ´Ü°¡")
                    m.supplyPrice := ci
                else if (key = "°ø±ÞÃÑ¾×")
                    m.supplyTotal := ci
            }

            if (m.title && m.publisher && m.qty && m.supplyPrice && m.supplyTotal)
            {
                headerRow := ri
                bookMap := m
                break
            }
        }

        if (!headerRow || !IsObject(bookMap))
            return out

        out.recognized := true
        out.source := "YES24 µµ¼­ °ßÀû¼­"

        expected := 1

        Loop, % table.Length()
        {
            ri := A_Index
            if (ri <= headerRow)
                continue

            row := table[ri]
            if !IsObject(row)
                continue

            ; ¹øÈ£ ¿­ÀÌ ÀÖÀ¸¸é 1¹øºÎÅÍ ¿¬¼ÓµÈ ½ÇÁ¦ µµ¼­ Çà¸¸ ÀÎ½Ä
            if (bookMap.no)
            {
                noText := SSOK_Expense_Yes24CleanCell(SSOK_Expense_ExcelCell(row, bookMap.no))
                if !RegExMatch(noText, "^\d+$")
                    continue

                rowNo := noText + 0
                if (rowNo != expected)
                {
                    ; ÇÕ°è/¼³¸í Çà ¶Ç´Â Ç¥ Á¾·á·Î ÆÇ´Ü
                    if (rowNo < expected)
                        continue

                    out.error := "YES24 µµ¼­ °ßÀû¼­ÀÇ ¹øÈ£°¡ ¿¬¼ÓµÇÁö ¾Ê½À´Ï´Ù. ¹®Á¦ ¹øÈ£: " . rowNo
                    return out
                }
            }

            nameText := SSOK_Expense_Yes24CleanCell(SSOK_Expense_ExcelCell(row, bookMap.title))
            specText := SSOK_Expense_Yes24CleanCell(SSOK_Expense_ExcelCell(row, bookMap.publisher))
            qtyText := SSOK_Expense_Yes24CleanCell(SSOK_Expense_ExcelCell(row, bookMap.qty))
            priceText := SSOK_Expense_Yes24CleanCell(SSOK_Expense_ExcelCell(row, bookMap.supplyPrice))
            amountText := SSOK_Expense_Yes24CleanCell(SSOK_Expense_ExcelCell(row, bookMap.supplyTotal))

            qty := SSOK_Expense_Yes24Number(qtyText)
            unitPrice := SSOK_Expense_Yes24Number(priceText)
            amount := SSOK_Expense_Yes24Number(amountText)

            if (nameText = "" || qty = "" || qty <= 0)
                continue

            if (unitPrice = "" && amount = "")
                continue

            if (unitPrice = "")
                unitPrice := SSOK_Expense_CalcExpectedPrice(amount, qty, out)

            if (amount = "")
                amount := unitPrice * qty

            out.rows.Push({name:nameText, spec:specText, qty:qty, amount:amount, price:unitPrice})
            out.total += amount
            expected++
        }

        if (!out.rows.Length())
        {
            out.error := "YES24 µµ¼­ °ßÀû¼­ Ç¥´Â È®ÀÎÇßÁö¸¸ µµ¼­ Ç°¸ñÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`nNO.ºÎÅÍ °ø±ÞÃÑ¾×±îÁö Ç¥ ÀüÃ¼¸¦ ¼±ÅÃÇÏ¿© ´Ù½Ã º¹»çÇØ ÁÖ¼¼¿ä."
            return out
        }

        return out
    }

    ; ------------------------------------------------------------
    ; Çü½Ä A: ±âÁ¸ YES24 À¥ °ßÀû¼­ ºÙ¿©³Ö±â
    ; ------------------------------------------------------------
    for ri, row in table
    {
        if !IsObject(row)
            continue

        joined := ""
        for _, cell in row
            joined .= SSOK_Expense_Yes24CleanCell(cell)

        h := RegExReplace(joined, "[\s" . Chr(160) . "¡¡|/¡¤¤ý_\-().]+", "")
        if (InStr(h, "¹øÈ£") && InStr(h, "³»¿ë") && InStr(h, "±Ô°Ý")
            && InStr(h, "¼ö·®") && InStr(h, "¿¹»ó´Ü°¡") && InStr(h, "¿¹»ó±Ý¾×"))
        {
            headerRow := ri
            break
        }
    }

    if (!headerRow)
        return out

    out.recognized := true

    ; ±âº» YES24 µ¥ÀÌÅÍ ¿­:
    ; 1 ¹øÈ£ / 2 ³»¿ë / 3 ±Ô°Ý / 4 ¼ö·® / 5 ¿¹»ó´Ü°¡ / 6 ¿¹»ó±Ý¾×(Âü°í¿ë)
    Loop, % table.Length()
    {
        ri := A_Index
        if (ri <= headerRow)
            continue

        row := table[ri]
        if !IsObject(row) || row.Length() < 5
            continue

        noText := SSOK_Expense_Yes24CleanCell(row[1])
        if !RegExMatch(noText, "^\d+$")
            continue

        ; 6¿­ Á¤»óÇüÀ» ¿ì¼± »ç¿ëÇÕ´Ï´Ù.
        if (row.Length() >= 6)
        {
            nameText := SSOK_Expense_Yes24CleanCell(row[2])
            specText := SSOK_Expense_Yes24CleanCell(row[3])
            qtyText := SSOK_Expense_Yes24CleanCell(row[4])
            priceText := SSOK_Expense_Yes24CleanCell(row[5])
            amountText := SSOK_Expense_Yes24CleanCell(row[6])
        }
        else
        {
            ; ±Ô°Ý ºó ¼¿ÀÌ º¹»ç °úÁ¤¿¡¼­ »ç¶óÁ® 5¿­ÀÌ µÈ °æ¿ìµµ Çã¿ëÇÕ´Ï´Ù.
            nameText := SSOK_Expense_Yes24CleanCell(row[2])
            specText := ""
            qtyText := SSOK_Expense_Yes24CleanCell(row[3])
            priceText := SSOK_Expense_Yes24CleanCell(row[4])
            amountText := SSOK_Expense_Yes24CleanCell(row[5])
        }

        qty := SSOK_Expense_Yes24Number(qtyText)
        unitPrice := SSOK_Expense_Yes24Number(priceText)
        amount := SSOK_Expense_Yes24Number(amountText)

        if (nameText = "" || qty = "" || qty <= 0)
            continue

        if (unitPrice = "" && amount = "")
            continue

        if (unitPrice = "")
            unitPrice := SSOK_Expense_CalcExpectedPrice(amount, qty, out)

        if (amount = "")
            amount := unitPrice * qty

        out.rows.Push({name:nameText, spec:specText, qty:qty, amount:amount, price:unitPrice})
        out.total += amount
    }

    if (!out.rows.Length())
    {
        out.error := "YES24 °ßÀû¼­ Ç¥´Â È®ÀÎÇßÁö¸¸ Ç°¸ñÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`n¹øÈ£ºÎÅÍ ¿¹»ó±Ý¾×(Âü°í¿ë)±îÁö Ç¥ ÀüÃ¼¸¦ ¼±ÅÃÇÏ¿© ´Ù½Ã º¹»çÇØ ÁÖ¼¼¿ä."
        return out
    }

    return out
}

SSOK_Expense_Yes24CleanCell(s)
{
    s := SSOK_Expense_ExcelCleanCell(s)

    ; ChatGPT/Markdown ÇüÅÂ·Î Àü´ÞµÈ º¹»ç ¸µÅ©
    ; ¿¹: [*º¹»ç*](javascript:void(0))
    s := RegExReplace(s, "i)\[\*{0,2}º¹»ç\*{0,2}\]\([^`r`n]*\)\s*$", "")

    ; ºê¶ó¿ìÀúÀÇ ÀÏ¹Ý ÅØ½ºÆ® º¹»ç ¹öÆ°ÀÌ ¼¿ ³¡¿¡ ³²Àº °æ¿ì
    s := RegExReplace(s, "\s+\*{0,2}º¹»ç\*{0,2}\s*$", "")

    ; Markdown ÀÌ½ºÄÉÀÌÇÁ°¡ ³²Àº °æ¿ì Á¤¸®
    s := StrReplace(s, "\(", "(")
    s := StrReplace(s, "\)", ")")
    s := StrReplace(s, "\:", ":")

    return Trim(s)
}

SSOK_Expense_Yes24Number(s)
{
    s := SSOK_Expense_Yes24CleanCell(s)

    if RegExMatch(s, "-?\d[\d,]*(?:\.\d+)?", m)
        return StrReplace(m, ",") + 0

    return ""
}

; ============================================================================
; Excel / ½ºÇÁ·¹µå½ÃÆ® Ç¥ Àü¿ë ÆÄ¼­
; ============================================================================
SSOK_Expense_ParseExcelTable(text)
{
    out := {rows: [], source: "¿¢¼¿ °ßÀû¼­(Çì´õ ÀÚµ¿ÀÎ½Ä)", total: 0, shipping: 0, quoteTotal: 0, grandTotal: 0, fractional: false, error: "", recognized: false, skipped: 0}

    table := SSOK_Expense_ExcelBuildRows(text)
    if !IsObject(table) || !table.Length()
        return out

    headerRow := 0
    map := ""
    bestScore := -1
    maxScan := Min(table.Length(), 30)

    Loop, %maxScan%
    {
        ri := A_Index
        row := table[ri]
        candidate := SSOK_Expense_ExcelBuildHeaderMap(row)

        if !IsObject(candidate)
            continue

        if (candidate.score > bestScore)
        {
            bestScore := candidate.score
            headerRow := ri
            map := candidate
        }
    }

    if (!headerRow || !IsObject(map) || !SSOK_Expense_ExcelHeaderValid(map))
        return out

    out.recognized := true

    Loop, % table.Length()
    {
        ri := A_Index
        if (ri <= headerRow)
            continue

        row := table[ri]

        if !IsObject(row)
            continue

        if (SSOK_Expense_ExcelRowBlank(row))
            continue

        itemText := SSOK_Expense_ExcelCell(row, map.item)
        nameText := SSOK_Expense_ExcelCell(row, map.name)
        combinedText := SSOK_Expense_ExcelCell(row, map.nameSpec)
        specText := SSOK_Expense_ExcelCell(row, map.spec)

        qtyRaw := SSOK_Expense_ExcelCell(row, map.qty)
        priceRaw := SSOK_Expense_ExcelCell(row, map.unitprice)
        amountRaw := SSOK_Expense_ExcelCell(row, map.amount)

        qty := SSOK_Expense_ExcelNumber(qtyRaw)
        unitPrice := SSOK_Expense_ExcelNumber(priceRaw)
        amount := SSOK_Expense_ExcelNumber(amountRaw)

        ; ¼ö·®¡¤´Ü°¡¡¤±Ý¾×ÀÌ ÀüºÎ ºó ÇàÀº Á¦¸ñ/±¸ºÐÇàÀ¸·Î Á¦¿Ü
        if (qty = "" && unitPrice = "" && amount = "")
        {
            out.skipped++
            continue
        }

        ; ¼ö·®ÀÌ ¾øÀ¸¸é ÇÕ°è/¼³¸íÇà °¡´É¼ºÀÌ ³ôÀ¸¹Ç·Î Á¦¿Ü
        if (qty = "" || qty <= 0)
        {
            out.skipped++
            continue
        }

        ; ´Ü°¡¿Í ±Ý¾×ÀÌ ¸ðµÎ ¾øÀ¸¸é °¡°ÝÀ» ¸¸µé ¼ö ¾øÀ¸¹Ç·Î Á¦¿Ü
        if (unitPrice = "" && amount = "")
        {
            out.skipped++
            continue
        }

        content := ""
        spec := ""

        ; Ç°¸ñ/±Ô°Ý ÇÏ³ªÀÇ ¿­
        if (combinedText != "")
        {
            content := combinedText
        }
        ; Ç°¸ñ+Ç°¸íÀÌ µÑ ´Ù ÀÖ´Â Ç¥
        else if (itemText != "")
        {
            content := itemText

            if (nameText != "")
                spec := nameText

            if (specText != "")
            {
                if (spec != "")
                    spec .= " / " . specText
                else
                    spec := specText
            }
        }
        else
        {
            content := nameText
            spec := specText
        }

        content := SSOK_Expense_ExcelCleanCell(content)
        spec := SSOK_Expense_ExcelCleanCell(spec)

        if (content = "")
        {
            out.skipped++
            continue
        }

        ; ExcelÀº ¸í½ÃµÈ ´Ü°¡¸¦ ¿ì¼± »ç¿ë
        if (unitPrice != "")
        {
            price := unitPrice

            if (amount = "")
                amount := unitPrice * qty
        }
        else
        {
            price := SSOK_Expense_CalcExpectedPrice(amount, qty, out)
        }

        if (amount = "")
            amount := price * qty

        out.rows.Push({name:content, spec:spec, qty:qty, amount:amount, price:price})
        out.total += amount
    }

    if (!out.rows.Length())
    {
        out.error := "¿¢¼¿ Ç¥ÀÇ ¸Ó¸®±ÛÀº Ã£¾ÒÁö¸¸ ÀÔ·ÂÇÒ Ç°¸ñ ÇàÀ» Ã£Áö ¸øÇß½À´Ï´Ù.`n¼ö·®°ú ´Ü°¡ ¶Ç´Â ±Ý¾×ÀÌ ÀÖ´Â ÇàÀÌ Æ÷ÇÔµÇµµ·Ï ´Ù½Ã º¹»çÇØ ÁÖ¼¼¿ä."
        return out
    }

    return out
}

SSOK_Expense_ExcelBuildRows(text)
{
    if InStr(text, "`t")
        return SSOK_Expense_ParseTSV(text)

    rows := []
    text := StrReplace(text, "`r")

    for _, raw in StrSplit(text, "`n")
    {
        line := Trim(raw)

        if (line = "")
            continue

        if (SubStr(line, 1, 1) != "|")
            continue

        line := Trim(line, "|")

        if RegExMatch(line, "^[\s|:\-]+$")
            continue

        row := []
        for _, cell in StrSplit(line, "|")
            row.Push(SSOK_Expense_ExcelCleanCell(cell))

        rows.Push(row)
    }

    return rows
}

SSOK_Expense_ParseTSV(text)
{
    rows := []
    row := []
    cell := ""
    inQuote := false
    i := 1
    len := StrLen(text)

    while (i <= len)
    {
        ch := SubStr(text, i, 1)

        if (ch = """")
        {
            next := (i < len ? SubStr(text, i + 1, 1) : "")

            if (inQuote && next = """")
            {
                cell .= """"
                i += 2
                continue
            }

            inQuote := !inQuote
            i++
            continue
        }

        if (!inQuote && ch = "`t")
        {
            row.Push(SSOK_Expense_ExcelCleanCell(cell))
            cell := ""
            i++
            continue
        }

        if (!inQuote && (ch = "`r" || ch = "`n"))
        {
            if (ch = "`r" && i < len && SubStr(text, i + 1, 1) = "`n")
                i++

            row.Push(SSOK_Expense_ExcelCleanCell(cell))
            cell := ""

            if (!SSOK_Expense_ExcelRowBlank(row))
                rows.Push(row)

            row := []
            i++
            continue
        }

        cell .= ch
        i++
    }

    if (cell != "" || row.Length())
    {
        row.Push(SSOK_Expense_ExcelCleanCell(cell))

        if (!SSOK_Expense_ExcelRowBlank(row))
            rows.Push(row)
    }

    return rows
}

SSOK_Expense_ExcelBuildHeaderMap(row)
{
    m := {no:0, item:0, name:0, nameSpec:0, spec:0, qty:0, unit:0, unitprice:0, amount:0, remark:0, g2b:0, score:0}

    if !IsObject(row)
        return m

    for i, raw in row
    {
        kind := SSOK_Expense_ExcelHeaderKind(raw)

        if (kind = "")
            continue

        if (kind = "no" && !m.no)
            m.no := i
        else if (kind = "item" && !m.item)
            m.item := i
        else if (kind = "name" && !m.name)
            m.name := i
        else if (kind = "name_spec" && !m.nameSpec)
            m.nameSpec := i
        else if (kind = "spec" && !m.spec)
            m.spec := i
        else if (kind = "qty" && !m.qty)
            m.qty := i
        else if (kind = "unit" && !m.unit)
            m.unit := i
        else if (kind = "unitprice" && !m.unitprice)
            m.unitprice := i
        else if (kind = "amount" && !m.amount)
            m.amount := i
        else if (kind = "remark" && !m.remark)
            m.remark := i
        else if (kind = "g2b" && !m.g2b)
            m.g2b := i
    }

    if (m.item || m.name || m.nameSpec)
        m.score += 6

    if (m.spec)
        m.score += 2

    if (m.qty)
        m.score += 5

    if (m.unitprice)
        m.score += 5

    if (m.amount)
        m.score += 5

    if (m.no)
        m.score += 1

    if (m.unit)
        m.score += 1

    return m
}

SSOK_Expense_ExcelHeaderValid(m)
{
    if !IsObject(m)
        return false

    hasContent := (m.item || m.name || m.nameSpec)
    hasPriceInfo := (m.unitprice || m.amount)

    return (hasContent && m.qty && hasPriceInfo)
}

SSOK_Expense_ExcelHeaderKind(s)
{
    s := SSOK_Expense_ExcelCleanCell(s)

    compact := RegExReplace(s, "[\s" . Chr(160) . "¡¡/¡¤¤ý_\-().]+", "")
    lower := compact
    StringLower, lower, lower

    if (lower = "no" || compact = "¹øÈ£" || compact = "¼ø¹ø")
        return "no"

    if (InStr(compact, "Ç°¸ñ±Ô°Ý") || InStr(compact, "Ç°¸í±Ô°Ý"))
        return "name_spec"

    if (compact = "Ç°¸ñ" || compact = "»óÇ°" || compact = "¹°Ç°")
        return "item"

    if (compact = "Ç°¸í" || compact = "»óÇ°¸í" || compact = "³»¿ë")
        return "name"

    if (compact = "±Ô°Ý" || compact = "»çÀÌÁî"
        || lower = "spec" || lower = "specification" || lower = "size")
        return "spec"

    if (compact = "¼ö·®" || lower = "quantity" || lower = "qty")
        return "qty"

    if (compact = "´ÜÀ§" || lower = "unit")
        return "unit"

    if (compact = "´Ü°¡" || compact = "¿¹»ó´Ü°¡"
        || compact = "ÆÇ¸Å°¡" || compact = "ÆÇ¸Å´Ü°¡" || compact = "°¡°Ý"
        || lower = "unitprice" || lower = "price" || lower = "sellingprice")
        return "unitprice"

    if (compact = "±Ý¾×" || compact = "ÇÕ°è" || compact = "ÃÑ¾×"
        || compact = "°ø±ÞÇÕ°è" || compact = "°ø±Þ°¡" || compact = "°ø±Þ°¡¾×"
        || compact = "°ø±Þ±Ý¾×" || lower = "amount" || lower = "total")
        return "amount"

    if (compact = "ºñ°í" || compact = "Âü°í" || lower = "remark" || lower = "remarks")
        return "remark"

    if (InStr(compact, "G2B") || InStr(compact, "½Äº°¹øÈ£") || InStr(compact, "Á¶´Þ½Äº°¹øÈ£"))
        return "g2b"

    return ""
}

SSOK_Expense_ExcelCell(row, idx)
{
    if (!idx || !IsObject(row) || idx > row.Length())
        return ""

    return SSOK_Expense_ExcelCleanCell(row[idx])
}

SSOK_Expense_ExcelCleanCell(s)
{
    s := s . ""

    s := RegExReplace(s, "i)<br\s*/?>", " ")
    s := StrReplace(s, "`r", " ")
    s := StrReplace(s, "`n", " ")
    s := StrReplace(s, "\:", ":")
    s := StrReplace(s, "\*", "*")
    s := StrReplace(s, Chr(160), " ")
    s := StrReplace(s, "¡¡", " ")
    s := RegExReplace(s, "[ `t]+", " ")

    return Trim(s)
}

SSOK_Expense_ExcelNumber(s)
{
    s := SSOK_Expense_ExcelCleanCell(s)

    if (s = "")
        return ""

    s := StrReplace(s, "*")
    s := StrReplace(s, ",")
    s := StrReplace(s, "¿ø")
    s := StrReplace(s, Chr(8361))
    s := StrReplace(s, Chr(65510))
    s := StrReplace(s, " ")

    negative := false
    if RegExMatch(s, "^\((.+)\)$", m)
    {
        s := m1
        negative := true
    }

    if !RegExMatch(s, "^-?\d+(?:\.\d+)?$")
        return ""

    n := s + 0

    if (negative)
        n := -Abs(n)

    return n
}

SSOK_Expense_ExcelRowBlank(row)
{
    if !IsObject(row)
        return true

    for _, cell in row
    {
        if (SSOK_Expense_ExcelCleanCell(cell) != "")
            return false
    }

    return true
}

SSOK_Expense_NewGenericResult()
{
    return {rows: [], source: "ÀÏ¹Ý °ßÀû¼­(Çì´õ ÀÚµ¿ÀÎ½Ä)", total: 0, shipping: 0, quoteTotal: 0, grandTotal: 0, fractional: false, error: ""}
}

; ------------------------------------------------------------
; ÅÇ/¸¶Å©´Ù¿î Ç¥ ÇüÅÂ
; ------------------------------------------------------------
SSOK_Expense_ParseGenericTabbed(text)
{
    out := SSOK_Expense_NewGenericResult()
    text := StrReplace(text, "`r")
    lines := StrSplit(text, "`n")

    headerKinds := ""
    headerCount := 0
    headerLineIndex := 0

    for li, rawLine in lines
    {
        line := Trim(rawLine, " `t" . Chr(160))
        if (line = "")
            continue

        ; Markdown Ç¥ º¹»çµµ ÅÇÇü½ÄÀ¸·Î º¯È¯
        if (SubStr(line, 1, 1) = "|")
        {
            line := Trim(line, "|")
            line := Trim(RegExReplace(line, " *\| *", "`t"), " `t")
        }

        if !InStr(line, "`t")
            continue

        cells := StrSplit(line, "`t")
        kinds := []
        hasNo := false
        hasName := false
        hasQty := false
        hasTotal := false
        hasAmount := false
        hasVat := false

        for ci, cell in cells
        {
            kind := SSOK_Expense_HeaderKind(cell)
            kinds.Push(kind)

            if (kind = "no")
                hasNo := true
            else if (kind = "name" || kind = "name_spec")
                hasName := true
            else if (kind = "qty")
                hasQty := true
            else if (kind = "total")
                hasTotal := true
            else if (kind = "amount")
                hasAmount := true
            else if (kind = "vat")
                hasVat := true
        }

        ; ÇÕ°è°¡ ÀÖÀ¸¸é ÃÖ¿ì¼±. ÇÕ°è°¡ ¾øÀ» ¶§´Â VATµµ ¾ø´Â ´Ü¼ø ±Ý¾×Ç¥¸¸ Çã¿ë.
        finalOK := hasTotal || (hasAmount && !hasVat)

        if (hasNo && hasName && hasQty && finalOK)
        {
            headerKinds := kinds
            headerCount := cells.Length()
            headerLineIndex := li
            break
        }
    }

    if !IsObject(headerKinds)
        return ""

    expected := 1
    started := false

    Loop, % lines.Length()
    {
        li := A_Index
        if (li <= headerLineIndex)
            continue

        line := Trim(lines[li], " `t" . Chr(160))
        if (line = "")
            continue

        if (SubStr(line, 1, 1) = "|")
        {
            line := Trim(line, "|")
            line := Trim(RegExReplace(line, " *\| *", "`t"), " `t")
        }

        if !InStr(line, "`t")
            continue

        cells := StrSplit(line, "`t")
        while (cells.Length() && Trim(cells[cells.Length()]) = "")
            cells.Pop()

        ; Ç¥ ±¸ºÐ¼±Àº °Ç³Ê¶Ü
        if (cells.Length() && RegExMatch(Trim(cells[1]), "^-+$"))
            continue

        noIdx := SSOK_Expense_FindHeaderIndex(headerKinds, "no")
        if (noIdx <= 0 || noIdx > cells.Length())
            continue

        rowNoText := Trim(cells[noIdx])
        if !RegExMatch(rowNoText, "^\d+$")
            continue

        rowNo := rowNoText + 0
        if (!started && rowNo != 1)
            continue

        if (rowNo != expected)
        {
            out.error := "ÀÏ¹Ý °ßÀû¼­ÀÇ Ç°¸ñ ¹øÈ£°¡ 1¹øºÎÅÍ ¿¬¼ÓµÇÁö ¾Ê½À´Ï´Ù. ¹®Á¦ ¹øÈ£: " . rowNo
            return out
        }

        started := true
        row := SSOK_Expense_GenericRowFromCells(cells, headerKinds, out)
        if !IsObject(row)
            return out

        out.rows.Push(row)
        out.total += row.amount
        expected++
    }

    if (!out.rows.Length())
        return ""

    return out
}

SSOK_Expense_FindHeaderIndex(kinds, wanted)
{
    for i, kind in kinds
    {
        if (kind = wanted)
            return i
    }
    return 0
}

SSOK_Expense_GenericRowFromCells(cells, kinds, ByRef out)
{
    name := ""
    spec := ""
    qty := ""
    finalAmount := ""
    amountValue := ""
    hasVatValue := false

    for i, kind in kinds
    {
        if (i > cells.Length())
            continue

        value := Trim(cells[i], " " . Chr(160))

        if (kind = "name" || kind = "name_spec")
        {
            if (name = "")
                name := value
        }
        else if (kind = "spec")
        {
            spec := value
        }
        else if (kind = "qty")
        {
            qty := SSOK_Expense_Number(value)
        }
        else if (kind = "total")
        {
            finalAmount := SSOK_Expense_Number(value)
        }
        else if (kind = "amount")
        {
            amountValue := SSOK_Expense_Number(value)
        }
        else if (kind = "vat")
        {
            if (SSOK_Expense_Number(value) != "")
                hasVatValue := true
        }
    }

    if (finalAmount = "" && !hasVatValue)
        finalAmount := amountValue

    if (name = "" || qty = "" || qty <= 0 || finalAmount = "" || finalAmount < 0)
    {
        out.error := "ÀÏ¹Ý °ßÀû¼­¿¡¼­ Ç°¸í¡¤¼ö·®¡¤ÇÕ°è¸¦ Á¤È®È÷ ÀÐÁö ¸øÇß½À´Ï´Ù."
        return ""
    }

    price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)
    return {name:name, spec:spec, qty:qty, amount:finalAmount, price:price}
}

; ------------------------------------------------------------
; ¼¿ ÇÏ³ª°¡ ÇÑ ÁÙ¾¿ º¹»çµÇ´Â Ç¥ ÇüÅÂ
; ------------------------------------------------------------
SSOK_Expense_ParseGenericVertical(text)
{
    out := SSOK_Expense_NewGenericResult()
    text := StrReplace(text, "`r")
    rawLines := StrSplit(text, "`n")
    lines := []

    for _, raw in rawLines
    {
        line := Trim(raw, " `t" . Chr(160))
        if (line = "")
            continue

        ; markdown Àå½Ä Á¦°Å
        line := Trim(line, "|")
        if (line = "" || RegExMatch(line, "^[-: |]+$"))
            continue

        lines.Push(line)
    }

    if (lines.Length() < 5)
        return ""

    ; Ã¹ ¹øÂ° µ¥ÀÌÅÍ ¹øÈ£ 1À» Ã£°í, ±× ¾Õ¿¡¼­ °¡Àå °¡±î¿î No/¹øÈ£ Çì´õ¸¦ Ã£½À´Ï´Ù.
    firstData := 0
    Loop, % lines.Length()
    {
        if (Trim(lines[A_Index]) = "1")
        {
            firstData := A_Index
            break
        }
    }

    if (!firstData)
        return ""

    headerStart := 0
    i := firstData - 1
    while (i >= 1)
    {
        if (SSOK_Expense_HeaderKind(lines[i]) = "no")
        {
            headerStart := i
            break
        }
        i--
    }

    if (!headerStart)
        return ""

    schema := []
    previousKind := ""

    Loop, % (firstData - headerStart)
    {
        idx := headerStart + A_Index - 1
        kind := SSOK_Expense_HeaderKind(lines[idx])

        ; ¾Ë ¼ö ¾ø´Â ¸Ó¸®±Ûµµ ½ÇÁ¦ ¿­ÀÏ ¼ö ÀÖÀ¸¹Ç·Î ignore ¿­·Î º¸Á¸
        if (kind = "")
            kind := "ignore"

        ; Ç°¸í/Description, ¼ö·®/QuantityÃ³·³ °°Àº ¿­ÀÇ ÇÑ±Û/¿µ¹®ÀÌ ¿¬¼ÓµÇ¸é ÇÏ³ª·Î ÇÕÄ§
        if (kind = previousKind)
            continue

        schema.Push(kind)
        previousKind := kind
    }

    if (!SSOK_Expense_GenericSchemaValid(schema))
        return ""

    pos := firstData
    expected := 1

    while (pos <= lines.Length())
    {
        if (Trim(lines[pos]) != expected . "")
            break

        pos++
        vals := {}
        parseOK := true

        Loop, % schema.Length()
        {
            si := A_Index
            kind := schema[si]

            if (kind = "no")
                continue

            if (pos > lines.Length())
            {
                parseOK := false
                break
            }

            current := Trim(lines[pos], " " . Chr(160))
            nextKind := (si < schema.Length() ? schema[si + 1] : "")

            ; ±Ô°ÝÀº ¼±ÅÃ»çÇ×. ´ÙÀ½ ¿­ Çü½ÄÀÌ ÀÌ¹Ì ¸ÂÀ¸¸é ±Ô°ÝÀº ºóÄ­À¸·Î °£ÁÖ.
            if (kind = "spec")
            {
                if (nextKind != "" && SSOK_Expense_ValueLooksLikeKind(current, nextKind))
                {
                    vals.spec := ""
                    continue
                }

                vals.spec := current
                pos++
                continue
            }

            ; ´ÜÀ§µµ ¿øº»¿¡¼­ ºñ¾î ÀÖÀ» ¼ö ÀÖÀ¸¸ç K-¿¡µàÆÄÀÎ¿¡´Â ¾îÂ÷ÇÇ "°³"¸¦ »ç¿ë.
            if (kind = "unit")
            {
                if (nextKind = "qty" && SSOK_Expense_ValueLooksLikeKind(current, "qty"))
                    continue

                pos++
                continue
            }

            if (kind = "ignore")
            {
                pos++
                continue
            }

            if (kind = "name" || kind = "name_spec")
            {
                vals.name := current
                pos++
                continue
            }

            if (kind = "qty")
            {
                n := SSOK_Expense_Number(current)
                if (n = "" || n <= 0)
                {
                    parseOK := false
                    break
                }
                vals.qty := n
                pos++
                continue
            }

            if (kind = "total" || kind = "amount" || kind = "vat" || kind = "supply" || kind = "unitprice")
            {
                n := SSOK_Expense_Number(current)
                if (n = "")
                {
                    parseOK := false
                    break
                }
                vals[kind] := n
                pos++
                continue
            }
        }

        if (!parseOK)
        {
            out.error := "ÀÏ¹Ý °ßÀû¼­ÀÇ " . expected . "¹ø Ç°¸ñÀ» ÀÐ´Â Áß ¿­ ±¸ºÐ¿¡ ½ÇÆÐÇß½À´Ï´Ù."
            return out
        }

        name := vals.HasKey("name") ? vals.name : ""
        spec := vals.HasKey("spec") ? vals.spec : ""
        qty := vals.HasKey("qty") ? vals.qty : ""

        if (vals.HasKey("total"))
            finalAmount := vals.total
        else if (vals.HasKey("amount") && !vals.HasKey("vat"))
            finalAmount := vals.amount
        else
            finalAmount := ""

        if (name = "" || qty = "" || finalAmount = "")
        {
            out.error := "ÀÏ¹Ý °ßÀû¼­ÀÇ " . expected . "¹ø Ç°¸ñ¿¡¼­ Ç°¸í¡¤¼ö·®¡¤ÇÕ°è¸¦ Ã£Áö ¸øÇß½À´Ï´Ù."
            return out
        }

        price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)
        out.rows.Push({name:name, spec:spec, qty:qty, amount:finalAmount, price:price})
        out.total += finalAmount
        expected++
    }

    if (!out.rows.Length())
        return ""

    return out
}

SSOK_Expense_GenericSchemaValid(schema)
{
    hasNo := false
    hasName := false
    hasQty := false
    hasTotal := false
    hasAmount := false
    hasVat := false

    for _, kind in schema
    {
        if (kind = "no")
            hasNo := true
        else if (kind = "name" || kind = "name_spec")
            hasName := true
        else if (kind = "qty")
            hasQty := true
        else if (kind = "total")
            hasTotal := true
        else if (kind = "amount")
            hasAmount := true
        else if (kind = "vat")
            hasVat := true
    }

    return (hasNo && hasName && hasQty && (hasTotal || (hasAmount && !hasVat)))
}

SSOK_Expense_ValueLooksLikeKind(value, kind)
{
    if (kind = "qty" || kind = "total" || kind = "amount" || kind = "vat" || kind = "supply" || kind = "unitprice")
        return (SSOK_Expense_Number(value) != "")

    if (kind = "unit")
        return RegExMatch(Trim(value), "i)^(EA|PCS?|SET|°³|½Ä|´ë|±Ç|¸Å|º´|¹Ú½º|BOX)$")

    return false
}

SSOK_Expense_HeaderKind(s)
{
    s := Trim(s, " `t" . Chr(160))
    s := StrReplace(s, "*")
    compact := RegExReplace(s, "[\s/¡¤¤ý_\-().]+", "")

    if RegExMatch(s, "i)^(No\.?|¹øÈ£|¼ø¹ø)$")
        return "no"

    ; Ç°¸ñ/±Ô°ÝÀÌ ÇÑ ¼¿¿¡ °°ÀÌ ÀÖ´Â °æ¿ì ³»¿ëÀ¸·Î »ç¿ëÇÏ°í ±Ô°ÝÀº ºñ¿ö µÓ´Ï´Ù.
    if (InStr(compact, "Ç°¸ñ±Ô°Ý") || InStr(compact, "Ç°¸í±Ô°Ý"))
        return "name_spec"

    if RegExMatch(s, "i)(Ç°¸í|Ç°¸ñ|»óÇ°¸í|³»¿ë|Description\s*of\s*goods)")
        return "name"

    if RegExMatch(s, "i)^(±Ô°Ý|Spec|Specification)$")
        return "spec"

    if RegExMatch(s, "i)^(¼ö·®|Quantity|Qty\.?)$")
        return "qty"

    if RegExMatch(s, "i)^(´ÜÀ§|Unit)$")
        return "unit"

    if RegExMatch(s, "i)^(´Ü°¡|Unit\s*Price)$")
        return "unitprice"

    if RegExMatch(s, "i)^(°ø±Þ°¡|°ø±Þ°¡¾×|°ø±Þ±Ý¾×|Supply\s*Amount)$")
        return "supply"

    if RegExMatch(s, "i)^(ºÎ°¡¼¼|¼¼¾×|VAT)$")
        return "vat"

    if RegExMatch(s, "i)^(ÇÕ°è|Total|ÃÑ¾×|°ø±ÞÇÕ°è)$")
        return "total"

    if RegExMatch(s, "i)^(±Ý¾×|Amount)$")
        return "amount"

    return ""
}

; ÃÖÁ¾ ÇÕ°è ¡À ¼ö·®À¸·Î K-¿¡µàÆÄÀÎ ¿¹»ó´Ü°¡ »ý¼º
SSOK_Expense_CalcExpectedPrice(amount, qty, ByRef out)
{
    if (Mod(amount, qty) = 0)
        return amount / qty

    scaledPrice := Ceil((amount * 1000) / qty)
    price := RTrim(RTrim(Format("{:.3f}", scaledPrice / 1000), "0"), ".")
    out.fractional := true
    return price
}

SSOK_Expense_Number(s)
{
    s := StrReplace(s, "*")
    s := Trim(StrReplace(StrReplace(s, ","), "¿ø"))
    return RegExMatch(s, "^\d+(?:\.\d+)?$") ? s + 0 : ""
}

SSOK_Expense_Write()
{
    global SSOK_ExpenseMode

    showProgress := (SSOK_ExpenseMode = "all")

    if (showProgress)
        SSOK_Expense_ShowRegisterProgress()

    try
    {
        return SSOK_Expense_Write_Impl()
    }
    finally
    {
        if (showProgress)
            SSOK_Expense_HideRegisterProgress()
    }
}

SSOK_Expense_ShowRegisterProgress()
{
    global SSOK_ExpenseRegisterProgressVisible

    Gui, SSOKExpenseRegisterProgress:Destroy
    Gui, SSOKExpenseRegisterProgress:New, +AlwaysOnTop -Caption +ToolWindow +Border +E0x20
    Gui, SSOKExpenseRegisterProgress:Color, FFE066
    Gui, SSOKExpenseRegisterProgress:Margin, 34, 24
    Gui, SSOKExpenseRegisterProgress:Font, s26 Bold c202020, Malgun Gothic

    ; ½ÇÁ¦ Text ÄÁÆ®·Ñ 2°³·Î ºÐ¸®ÇÏ¿© È®½ÇÈ÷ µÎ ÁÙ Ç¥½Ã
    Gui, SSOKExpenseRegisterProgress:Add, Text, w500 h52 Center c202020, µî·Ï ÀÛ¾÷Áß
    Gui, SSOKExpenseRegisterProgress:Add, Text, y+4 w500 h44 Center c202020, ¸¶¿ì½º¸¦ ¿òÁ÷ÀÌÁö ¸¶¼¼¿ä

    Gui, SSOKExpenseRegisterProgress:Show, AutoSize Center NoActivate
    SSOK_ExpenseRegisterProgressVisible := true
}

SSOK_Expense_HideRegisterProgress()
{
    global SSOK_ExpenseRegisterProgressVisible
    Gui, SSOKExpenseRegisterProgress:Destroy
    SSOK_ExpenseRegisterProgressVisible := false
}

SSOK_Expense_ShowBudgetNotice()
{
    Gui, SSOKExpenseBudgetNotice:Destroy
    Gui, SSOKExpenseBudgetNotice:New, +AlwaysOnTop -Caption +ToolWindow +Border +E0x20
    Gui, SSOKExpenseBudgetNotice:Color, FFE066
    Gui, SSOKExpenseBudgetNotice:Margin, 28, 24
    Gui, SSOKExpenseBudgetNotice:Font, s20 Bold c202020, Malgun Gothic
    Gui, SSOKExpenseBudgetNotice:Add, Text, w760 h74 Center +0x200, K-¿¡µàÆÄÀÎ Ç°ÀÇµî·Ï ¸Þ´º¿¡¼­ ¿¹»ê¼±ÅÃÀ» ¸ÕÀú ÁøÇàÇØÁÖ¼¼¿ä
    Gui, SSOKExpenseBudgetNotice:Show, AutoSize Center NoActivate
    SetTimer, SSOKExpenseBudgetNoticeClose, -3000
}

SSOK_Expense_Write_Impl()
{
    global SSOK_ExpenseBusy, SSOK_ExpenseCancel, SSOK_ExpenseReady, SSOK_ExpenseRows
    global SSOK_ExpenseStage, SSOK_ExpenseMode, SSOK_ExpensePendingAdd
    global SSOK_ExpenseAddButtonCache
    global SSOK_ExpenseEdufineRootHwnd

    target := WinExist("A")
    if (!target)
        return

    needRows := SSOK_ExpenseRows.Length()
    if (needRows <= 0)
        return

    if (IsObject(SSOK_ExpensePendingAdd) && SSOK_ExpensePendingAdd.target != target)
    {
        SSOK_Expense_HideRegisterProgress()
        SSOK_Expense_ShowBudgetNotice()
        return
    }
    SSOK_ExpenseBusy := true
    SSOK_ExpenseCancel := false
    if (SSOK_ExpenseStage = "resume-input")
    {
        SSOK_ExpensePendingAdd := ""
        SSOK_Expense_DoInput(target, SSOK_ExpenseMode != "items")
        return
    }
    if (SSOK_ExpenseMode = "items" || SSOK_ExpenseMode = "cause")
    {
        SSOK_Expense_Log((SSOK_ExpenseMode = "cause" ? "cause-action-start rows=" : "items-only-start rows=") . needRows)
        ToolTip
        SSOK_Expense_DoInput(target, false)
        return
    }
    SSOK_ExpenseAddButtonCache := ""
    SSOK_ExpenseEdufineRootHwnd := 0
    global SSOK_ExpenseResolvedRowPath, SSOK_ExpenseLastError
    ; °æ·Î ¹®ÀÚ¿­Àº ´ÙÀ½ ½ÇÇà¿¡µµ À¯ÁöÇÏµÇ, COM °´Ã¼¿Í Ã¢ ÇÚµéÀº À§¿¡¼­ ÃÊ±âÈ­ÇÕ´Ï´Ù.
    SSOK_ExpenseLastError := ""
    SSOK_Expense_Log("write-start rows=" . needRows)

    WinActivate, ahk_id %target%
    WinWaitActive, ahk_id %target%,, 2
    if (ErrorLevel)
    {
        SSOK_ExpenseBusy := false
        return
    }

    ; --------------------------------------------------------
    ; ÀÌ ´Ü°è¿¡¼­´Â ¿ÀÁ÷ ÇàÃß°¡ ¹öÆ°¸¸ È®º¸ÇÕ´Ï´Ù.
    ; °³¿ä/Á¦¸ñ °´Ã¼´Â Ç°¸ñ ÀÔ·ÂÀÌ ¸ðµÎ ³¡³­ µÚ¿¡¸¸ Á¢±ÙÇÕ´Ï´Ù.
    ; --------------------------------------------------------
    if (!SSOK_Expense_MSAA_PrepareAddButtonOnly(target))
    {
        SSOK_ExpenseBusy := false
        SSOK_ExpenseReady := true
        SSOK_ExpenseStage := "auto"
        ToolTip
        MsgBox, 48, °£Æí ÁöÃâÇ°ÀÇ, ÇàÃß°¡ ¹öÆ°À» Ã£Áö ¸øÇß½À´Ï´Ù.`n%SSOK_ExpenseLastError%`nÇ°¸ñ Ç¥¿Í ÇàÃß°¡ ¹öÆ°ÀÌ º¸ÀÌ´Â »óÅÂ¿¡¼­ ´Ù½Ã Win+1À» ´­·¯ ÁÖ¼¼¿ä.`nÁø´Ü ±â·Ï: ssok_expense_diagnostic.log
        return
    }

    ; --------------------------------------------------------
    ; ÇàÃß°¡¿Í Ç°¸ñ ÀÔ·ÂÀ» ¸¶Ä£ ´ÙÀ½ °³¿ä, Á¦¸ñ ¼øÀ¸·Î ÀÔ·ÂÇÕ´Ï´Ù.
    if (!SSOK_ExpenseRegisterProgressVisible)
        ToolTip, % needRows . "°³ Çà »ý¼º Áß..."

    currentRows := SSOK_Expense_ItemRowSnapshot(target)
    remaining := needRows
    if (IsObject(SSOK_ExpensePendingAdd))
    {
        remaining := SSOK_Expense_RemainingRows(SSOK_ExpensePendingAdd.before, currentRows, needRows)
        if (remaining <= 0)
        {
            ; ÀÌ¹Ì ¸ðµç ÇàÀÌ ÀÖ°Å³ª Çà ¼ö¸¦ È®Á¤ÇÒ ¼ö ¾øÀ¸¸é Ãß°¡ Å¬¸¯À» ÇÏÁö ¾Ê½À´Ï´Ù.
            SSOK_ExpenseBusy := false
            SSOK_ExpenseReady := true
            SSOK_ExpenseStage := "resume-input"
            ToolTip
            MsgBox, 64, °£Æí ÁöÃâÇ°ÀÇ, °ßÀû¼­´Â ±×´ë·Î º¸°ü ÁßÀÔ´Ï´Ù.`nÀÔ·ÂÇÒ ºó ÇàÀ» ÇÊ¿äÇÑ ¼ö¸¸Å­ ÁØºñÇÏ°í Ã¹ ÇàÀÇ 'Ç°¸í' Ä­À» Å¬¸¯ÇÑ µÚ Win+1À» ´©¸£¼¼¿ä.`n´ÙÀ½¿¡´Â ÇàÃß°¡ ¾øÀÌ ÀúÀåµÈ °ßÀû¼­¸¦ ÀÔ·ÂÇÕ´Ï´Ù.
            return
        }
        SSOK_Expense_Log("resume-add remaining=" . remaining . " currentRows=" . currentRows)
    }
    else
        SSOK_ExpensePendingAdd := {target:target, before:currentRows}
    if (!SSOK_Expense_AddRowsOneClick(target, remaining)
        || !SSOK_Expense_MSAA_IsFixedAddButton(SSOK_ExpenseAddButtonCache))
    {
        SSOK_Expense_Log("row-add-stopped: " . SSOK_ExpenseLastError)
        SSOK_Expense_StopForBudget()
        ToolTip
        SSOK_Expense_HideRegisterProgress()
        SSOK_Expense_ShowBudgetNotice()
        return
    }
    SSOK_ExpensePendingAdd := ""
    ; ¸¶Áö¸· Çà »ý¼º ¹× Æ÷Ä¿½º ¹Ý¿µ ½Ã°£
    Sleep, 70

    ; N°³ »ý¼º ÈÄ ¸¶Áö¸· »ý¼º Çà¿¡ ÀÖÀ¸¹Ç·Î Ã¹ Çà±îÁö N-1Ä­ À§·Î ÀÌµ¿.
    ; ´ë·® Çà¿¡¼­´Â {Up 31} °°Àº ¹­À½ Àü¼ÛÀ» Nexacro°¡ ³õÄ¥ ¼ö ÀÖÀ¸¹Ç·Î
    ; ÇÑ Ä­¾¿ º¸³»¾î Á¤È®ÇÏ°Ô Ã¹ ÇàÀ¸·Î ÀÌµ¿ÇÕ´Ï´Ù.
    upCount := needRows - 1
    if (upCount > 0)
    {
        Loop, %upCount%
        {
            if (!SSOK_Expense_Active(target))
            {
                SSOK_ExpenseBusy := false
                SSOK_ExpenseReady := false
                return
            }
            SendInput, {Up}
            Sleep, 28
        }
    }

    ; ½ºÅ©·Ñ/Æ÷Ä¿½º ¹Ý¿µ ´ë±â
    Sleep, 220

    ToolTip
    ; Busy´Â DoInputÀÇ finally¿¡¼­¸¸ ÇØÁ¦ÇÕ´Ï´Ù.
    SSOK_ExpenseStage := "input"

    ; ´Ù½Ã Win+1À» ´©¸£Áö ¾Ê°í ¹Ù·Î ±âÁ¸ ÀÔ·Â
    SSOK_Expense_DoInput(target)
}

SSOK_Expense_DoInput(target, includeDetails := true)
{
    global SSOK_ExpenseBusy, SSOK_ExpenseCancel, SSOK_ExpenseReady, SSOK_ExpenseRows
    global SSOK_ExpenseStage, SSOK_ExpenseMode
    SSOK_ExpenseReady := false
    SSOK_ExpenseBusy := true
    try
    {
        if (!SSOK_Expense_Active(target))
            return false
        SSOK_ExpenseStage := "input"
        if (!SSOK_Expense_InputRows(target))
        {
            MsgBox, 48, °£Æí ÁöÃâÇ°ÀÇ, ÀÔ·ÂÀÌ Áß´ÜµÇ¾ú½À´Ï´Ù. ÀÌ¹Ì ÀÔ·ÂµÈ ³»¿ëÀº À¯ÁöµË´Ï´Ù.`n´Ù½Ã ÀÚµ¿ÀÔ·ÂÇÏ·Á¸é °ßÀû¼­¸¦ »õ·Î ÀÐ¾î ÁÖ¼¼¿ä.
            return false
        }
        if (!includeDetails || SSOK_ExpenseMode = "items" || SSOK_ExpenseMode = "cause")
        {
            SSOK_Expense_Log(SSOK_ExpenseMode = "cause" ? "cause-action-completed" : "items-only-completed")
            return true
        }
        SSOK_ExpenseStage := "overview"
        Sleep, 180
        if (!SSOK_Expense_WriteOverviewOnly(target))
        {
            SSOK_Expense_Log("overview-input-failed")
            ToolTip, Ç°¸ñ ÀÔ·ÂÀº ¿Ï·áÇßÁö¸¸ °³¿ä ÀÚµ¿ÀÔ·Â¿¡ ½ÇÆÐÇß½À´Ï´Ù.
            SetTimer, SSOKExpenseClearTip, -5000
            return false
        }
        SSOK_ExpenseStage := "title"
        Sleep, 80
        if (!SSOK_Expense_WriteTitleOnly(target))
        {
            SSOK_Expense_Log("title-input-failed")
            ToolTip, Ç°¸ñ°ú °³¿ä ÀÔ·ÂÀº ¿Ï·áÇßÁö¸¸ Á¦¸ñ ÀÚµ¿ÀÔ·Â¿¡ ½ÇÆÐÇß½À´Ï´Ù.
            SetTimer, SSOKExpenseClearTip, -5000
            return false
        }
        SSOK_Expense_Log("input-sequence-completed")
        return true
    }
    finally
    {
        ; °³¿ä/Á¦¸ñ ÀÔ·ÂÀÌ ³¡³¯ ¶§±îÁö Busy¸¦ À¯ÁöÇØ Áß°£ Àç½ÇÇàÀ» Â÷´ÜÇÕ´Ï´Ù.
        SSOK_ExpenseBusy := false
        SSOK_ExpenseReady := false
        SSOK_ExpenseStage := ""
    }
}

SSOK_Expense_WriteOverviewOnly(target)
{
    global SSOK_ExpenseRows

    if (!SSOK_Expense_Active(target))
        return false

    total := 0
    for _, row in SSOK_ExpenseRows
        total += row.amount

    amountNumber := SSOK_Expense_FormatNumber(total)
    amountKorean := SSOK_Expense_NumberToKorean(total)

    itemCount := SSOK_ExpenseRows.Length()
    firstItem := ""

    if (itemCount >= 1)
        firstItem := SSOK_ExpenseRows[1].name

    if (itemCount > 1)
        calcText := firstItem . " ¿Ü " . (itemCount - 1) . "°Ç"
    else
        calcText := firstItem

    institution := SSOK_Expense_GetInstitutionName(target)
    if (institution = "")
        institution := "¡Û¡Û¡Û"

    FormatTime, currentYear,, yyyy
    FormatTime, currentMonth,, M
    yearMonth := currentYear . "." . currentMonth . "."

    overviewText := ""
    overviewText .= "1. °ü·Ã: " . institution . "-¡Û¡Û¡Û(" . yearMonth . ")(´ëÈ£ ¾øÀ»½Ã »ý·«°¡´É)`r`n"
    overviewText .= "2. ¡Û¡Û¡Û °ü·Ã ¹°Ç°À» ¾Æ·¡¿Í °°ÀÌ ±¸ÀÔÇÏ°íÀÚ ÇÕ´Ï´Ù.`r`n"
    overviewText .= "  °¡. ¿ëµµ: `r`n"
    overviewText .= "  ³ª. ¼Ò¿ä¿¹»ê: ±Ý" . amountNumber . "¿ø(±Ý" . amountKorean . "¿ø)`r`n"
    overviewText .= "  ´Ù. »êÃâ³»¿ª: " . calcText . "`r`n"
    overviewText .= "`r`n"
    overviewText .= "ºÙÀÓ  ÁöÃâÇ°ÀÇ¼­ 1ºÎ.  ³¡."

    return SSOK_Expense_WriteDetailOnce(target, "overview", overviewText)
}

SSOK_Expense_WriteTitleOnly(target)
{
    if (!SSOK_Expense_Active(target))
        return false

    return SSOK_Expense_WriteDetailOnce(target, "title", "[Ç°ÀÇ] 000 ¿î¿µ ¹°Ç° ±¸ÀÔ")
}

; ------------------------------------------------------------
; Á¤¼ö¸¦ ÇÑ±¹¾î ±Ý¾× ÀÐ±â·Î º¯È¯
; ¿¹: 831770 -> ÆÈ½Ê»ï¸¸ÀÏÃµÄ¥¹éÄ¥½Ê
; ------------------------------------------------------------
SSOK_Expense_NumberToKorean(value)
{
    value := Round(value)

    if (value = 0)
        return "¿µ"

    digitNames := ["", "ÀÏ", "ÀÌ", "»ï", "»ç", "¿À", "À°", "Ä¥", "ÆÈ", "±¸"]
    smallUnits := ["", "½Ê", "¹é", "Ãµ"]
    bigUnits := ["", "¸¸", "¾ï", "Á¶", "°æ"]

    s := value . ""
    result := ""
    groupIndex := 0

    while (StrLen(s) > 0)
    {
        len := StrLen(s)

        if (len > 4)
        {
            group := SubStr(s, len - 3, 4)
            s := SubStr(s, 1, len - 4)
        }
        else
        {
            group := s
            s := ""
        }

        groupValue := group + 0

        if (groupValue != 0)
        {
            groupText := SSOK_Expense_KoreanGroup(groupValue, digitNames, smallUnits)

            if (groupIndex > 0)
                groupText .= bigUnits[groupIndex + 1]

            result := groupText . result
        }

        groupIndex++
    }

    return result
}

SSOK_Expense_KoreanGroup(value, digitNames, smallUnits)
{
    s := value . ""
    len := StrLen(s)
    out := ""

    Loop, %len%
    {
        ch := SubStr(s, A_Index, 1) + 0
        pos := len - A_Index

        if (ch = 0)
            continue

        ; 10, 100, 1000 ´ÜÀ§ÀÇ '1'Àº º¸Åë »ý·«
        if (!(ch = 1 && pos > 0))
            out .= digitNames[ch + 1]

        out .= smallUnits[pos + 1]
    }

    return out
}

SSOK_Expense_FormatNumber(value)
{
    value := Round(value)

    sign := ""
    if (value < 0)
    {
        sign := "-"
        value := Abs(value)
    }

    s := value . ""
    out := ""

    while (StrLen(s) > 3)
    {
        out := "," . SubStr(s, -2) . out
        s := SubStr(s, 1, StrLen(s) - 3)
    }

    return sign . s . out
}

; ------------------------------------------------------------
; Ç°ÀÇµî·Ï È­¸é »ó´Ü ±â°ü¸í ÃßÃâ
; ¿¹: "Ç°ÀÇµî·Ï ( µµ´ãÁßÇÐ±³ / A00FAD... )" -> "µµ´ãÁßÇÐ±³"
; ------------------------------------------------------------
SSOK_Expense_GetInstitutionName(topHwnd)
{
    ; --------------------------------------------------------
    ; ÀüÃ¼ MSAA Æ®¸®¸¦ Àý´ë °Ë»öÇÏÁö ¾Ê½À´Ï´Ù.
    ; Ç°ÀÇµî·Ï Á¦¸ñÀÌ ÀÖ´Â È­¸é »ó´Ü °íÁ¤ ¿µ¿ª ¸î Á¡¸¸ Áï½Ã Á¶È¸ÇÕ´Ï´Ù.
    ; --------------------------------------------------------
    WinGetPos, wx, wy, ww, wh, ahk_id %topHwnd%

    if (ww = "" || wh = "" || ww <= 0 || wh <= 0)
        return ""

    ; Ç°ÀÇµî·Ï(±â°ü¸í / ¹®¼­¹øÈ£) ¿µ¿ª ÁÖº¯ÀÇ °íÁ¤ »ó´ë À§Ä¡
    points := []
    points.Push({rx:0.08, ry:0.025})
    points.Push({rx:0.12, ry:0.025})
    points.Push({rx:0.16, ry:0.025})
    points.Push({rx:0.20, ry:0.025})
    points.Push({rx:0.12, ry:0.040})

    for _, p in points
    {
        x := wx + Round(ww * p.rx)
        y := wy + Round(wh * p.ry)

        hit := SSOK_Expense_MSAA_FromPointFast(x, y)
        if !IsObject(hit)
            continue

        ; hit simple child / °´Ã¼ ÀÚÃ¼
        institution := SSOK_Expense_ParseInstitutionText(SSOK_Expense_MSAA_Get(hit.acc, "Name", hit.child))
        if (institution != "")
            return institution

        institution := SSOK_Expense_ParseInstitutionText(SSOK_Expense_MSAA_Get(hit.acc, "Value", hit.child))
        if (institution != "")
            return institution

        institution := SSOK_Expense_ParseInstitutionText(SSOK_Expense_MSAA_Get(hit.acc, "Name", 0))
        if (institution != "")
            return institution

        institution := SSOK_Expense_ParseInstitutionText(SSOK_Expense_MSAA_Get(hit.acc, "Value", 0))
        if (institution != "")
            return institution

        ; ÀüÃ¼ Æ®¸®°¡ ¾Æ´Ï¶ó ÇöÀç ÁöÁ¡ÀÇ ºÎ¸ð¸¸ ÃÖ´ë 5´Ü°è È®ÀÎ
        current := hit.acc

        Loop, 5
        {
            try
            {
                parent := current.accParent
            }
            catch
            {
                break
            }

            if !IsObject(parent)
                break

            institution := SSOK_Expense_ParseInstitutionText(SSOK_Expense_MSAA_Get(parent, "Name", 0))
            if (institution != "")
                return institution

            institution := SSOK_Expense_ParseInstitutionText(SSOK_Expense_MSAA_Get(parent, "Value", 0))
            if (institution != "")
                return institution

            current := parent
        }
    }

    return ""
}

SSOK_Expense_ParseInstitutionText(text)
{
    text := Trim(text)

    if (text = "")
        return ""

    ; ¿¹: Ç°ÀÇµî·Ï ( µµ´ãÁßÇÐ±³ / A00FAD0102002001 )
    if RegExMatch(text, "Ç°ÀÇµî·Ï\s*\(\s*([^/()]+?)\s*/", m)
        return Trim(m1)

    return ""
}

; ------------------------------------------------------------
; K-¿¡µàÆÄÀÎ Nexacro Grid Çà ¼ö È®ÀÎ - MSAA
;
; Áø´Ü °á°ú:
;   0Çà -> Name=[¼±ÅÃ] °´Ã¼ 0°³
;   1Çà -> Name=[¼±ÅÃ] °´Ã¼ 2°³
;   2Çà -> Name=[¼±ÅÃ] °´Ã¼ 4°³
;
; µû¶ó¼­ ¾ÆÁ÷ ÀÔ·ÂÇÏÁö ¾ÊÀº ºó Çà¿¡¼­´Â:
;   ÇöÀç Çà ¼ö = Á¤È®È÷ "¼±ÅÃ"ÀÎ MSAA °´Ã¼ ¼ö / 2
;
; °´Ã¼ ¼ö°¡ È¦¼öÀÌ¸é È­¸é ±¸Á¶°¡ ¿¹»ó°ú ´Ù¸£´Ù°í º¸°í -1À» ¹ÝÈ¯ÇÕ´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_CountRows(target)
{
    scan := SSOK_Expense_MSAA_Scan(target, "count")

    if (!scan.ok)
        return -1

    if (Mod(scan.selectCount, 2) != 0)
        return -1

    return Floor(scan.selectCount / 2)
}

; ------------------------------------------------------------
; ºÎÁ·ÇÑ ÇàÀ» MSAA 'ÇàÃß°¡' PushButtonÀ¸·Î Á÷Á¢ »ý¼º
; ¸Å Çà¸¶´Ù ¹öÆ° À¯È¿¼ºÀ» È®ÀÎÇÏ°í ½ÇÇàÇÕ´Ï´Ù. ½ÇÇà È½¼ö´Â ½ÇÁ¦ Çà ¼ö¿Í ´Ù¸¦ ¼ö ÀÖ½À´Ï´Ù.
; ÁÂÇ¥ / ImageSearch / Tab ÀÌµ¿À» »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_AddRowsOneClick(target, count)
{
    global SSOK_ExpenseAddButtonCache, SSOK_ExpenseLastError, SSOK_ExpenseRowsAdded
    SSOK_ExpenseRowsAdded := 0
    before := SSOK_Expense_ItemRowSnapshot(target)
    Loop, %count%
    {
        if (!SSOK_Expense_Active(target))
        {
            SSOK_ExpenseLastError := "È­¸é ÀüÈ¯ ¶Ç´Â Ãë¼Ò·Î ÇàÃß°¡¸¦ Áß´ÜÇß½À´Ï´Ù."
            return false
        }
        ; Å¬¸¯ Àü ÀÏ½ÃÀûÀÎ °´Ã¼ ±³Ã¼¸¸ º¹±¸ÇÕ´Ï´Ù. Å¬¸¯ ÈÄ ºÒÈ®½ÇÇÑ °á°ú´Â ÀçÅ¬¸¯ÇÏÁö ¾Ê½À´Ï´Ù.
        if (!SSOK_Expense_MSAA_IsFixedAddButton(SSOK_ExpenseAddButtonCache)
            && !SSOK_Expense_RefreshAddAtKnownPath(target))
        {
            SSOK_ExpenseLastError := "ÇàÃß°¡ ¹öÆ°ÀÌ ºñÈ°¼ºÈ­µÇ¾ú°Å³ª È­¸éÀÌ º¯°æµÇ¾ú½À´Ï´Ù. ¿¹»ê ¾È³» ¶Ç´Â ÆË¾÷À» È®ÀÎÇØ ÁÖ¼¼¿ä."
            return false
        }
        if (!SSOK_Expense_Active(target))
            return false
        if (!SSOK_Expense_ClickVisibleAddButton(SSOK_ExpenseAddButtonCache, target))
        {
            SSOK_ExpenseLastError := "ÇàÃß°¡ Å¬¸¯ °á°ú°¡ ºÒÈ®½ÇÇÏ¿© Áßº¹ Å¬¸¯À» Áß´ÜÇß½À´Ï´Ù."
            SSOK_Expense_Log("add-action-uncertain completed=" . SSOK_ExpenseRowsAdded)
            return false
        }
        Sleep, 220
        if (before >= 0)
        {
            after := -1
            Loop, 3
            {
                if (!SSOK_Expense_Active(target))
                    return false
                after := SSOK_Expense_ItemRowSnapshot(target)
                if (after = before + 1)
                    break
                if (after > before + 1)
                    break
                Sleep, 180
            }
            if (after != before + 1)
            {
                SSOK_ExpenseLastError := "Çà Áõ°¡¸¦ È®ÀÎÇÏÁö ¸øÇØ Áß´ÜÇß½À´Ï´Ù. ÇöÀç Çà ¼ö¸¦ È®ÀÎÇÑ µÚ Ç°ÀÇ¸ñ·Ï ÀÔ·ÂÇÏ±â¸¦ »ç¿ëÇØ ÁÖ¼¼¿ä."
                SSOK_Expense_Log("row-growth-unconfirmed before=" . before . " after=" . after)
                return false
            }
            before := after
        }
        SSOK_ExpenseRowsAdded++
        if (!SSOK_ExpenseRegisterProgressVisible)
            ToolTip, % "ÇàÃß°¡ ½ÇÇà Áß... " . SSOK_ExpenseRowsAdded . "/" . count
    }
    SSOK_Expense_Log("add-actions-completed=" . SSOK_ExpenseRowsAdded . " rowCountVerified=" . (before >= 0 ? 1 : 0))
    return SSOK_Expense_Active(target)
}

SSOK_Expense_RefreshAddAtKnownPath(target)
{
    global SSOK_ExpenseResolvedRowPath, SSOK_ExpenseAddButtonCache
    if (SSOK_ExpenseResolvedRowPath = "")
        return false
    Loop, 3
    {
        if (!SSOK_Expense_Active(target))
            return false
        Sleep, 180
        root := SSOK_Expense_MSAA_GetEdufineRoot(target, true)
        if (!IsObject(root))
            continue
        candidate := {acc:SSOK_Expense_MSAA_FollowFixedPath(root, SSOK_ExpenseResolvedRowPath),child:0,path:SSOK_ExpenseResolvedRowPath}
        if (SSOK_Expense_MSAA_IsFixedAddButton(candidate))
        {
            SSOK_ExpenseAddButtonCache := candidate
            SSOK_Expense_Log("row-button-refreshed-before-click")
            return true
        }
    }
    return false
}

SSOK_Expense_MSAA_IsFixedAddButton(btn)
{
    if !IsObject(btn)
        return false
    if IsObject(btn.acc)
        return SSOK_Expense_MSAA_Matches(btn.acc, btn.child, "add")
    return SSOK_Expense_MSAA_Matches(btn, 0, "add")
}

; ------------------------------------------------------------
; È®Á¤µÈ K-¿¡µàÆÄÀÎ MSAA ³»ºÎ °æ·Î
;
; 2026-09 Áø´Ü °á°ú:
; Root class = Chrome_RenderWidgetHostHWND
; Root name  = K-¿¡µàÆÄÀÎ ... _WebDRM[85T]
;
; °íÁ¤ °æ·Î°¡ ´Þ¶óÁö¸é Ç¥½Ã ÁßÀÎ Á¢±Ù¼º Æ®¸®¿¡¼­ ÀÌ¸§°ú ¿ªÇÒ·Î ´Ù½Ã Ã£½À´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_MSAA_PrepareAddButtonOnly(target, force := false)
{
    global SSOK_ExpenseAddButtonCache, SSOK_ExpenseCacheTarget
    global SSOK_ExpenseResolvedRowPath, SSOK_ExpenseLastError
    if (!force && SSOK_ExpenseCacheTarget = target
        && SSOK_Expense_MSAA_IsFixedAddButton(SSOK_ExpenseAddButtonCache))
        return true

    SSOK_ExpenseAddButtonCache := ""
    SSOK_ExpenseCacheTarget := target
    started := A_TickCount
    if (SSOK_ExpenseResolvedRowPath = "")
        SSOK_ExpenseResolvedRowPath := SSOK_Expense_LoadRowPath()
    ; ¸ÕÀú ÀúÀåµÈ °æ·Î¸¦ È®ÀÎÇÏ°í, ¼ø¼­°¡ ¹Ù²î¾úÀ¸¸é ÀÌ¸§/¿ªÇÒ·Î ÀçÅ½»öÇÕ´Ï´Ù.
    oldPath := "/obj[1]/obj[1]/obj[1]/obj[1]/obj[3]/obj[1]/obj[3]/obj[1]/obj[1]/obj[1]/obj[55]/obj[1]/obj[1]/obj[1]/obj[1]/obj[11]/obj[1]/obj[3]/obj[1]/obj[6]/obj[1]/obj[1]/obj[1]/obj[8]"
    Loop, 5
    {
        if (!SSOK_Expense_Active(target))
            return false
        if (!SSOK_ExpenseRegisterProgressVisible)
            ToolTip, % "K-¿¡µàÆÄÀÎ ÇàÃß°¡ ¹öÆ° È®ÀÎ Áß... (" . A_Index . "/5)"
        root := SSOK_Expense_MSAA_GetEdufineRoot(target, force || A_Index > 1)
        if IsObject(root)
        {
            path := SSOK_ExpenseResolvedRowPath != "" ? SSOK_ExpenseResolvedRowPath : oldPath
            candidate := {acc:SSOK_Expense_MSAA_FollowFixedPath(root, path), child:0, path:path}
            if (SSOK_Expense_MSAA_IsFixedAddButton(candidate))
            {
                SSOK_ExpenseAddButtonCache := candidate
                SSOK_ExpenseResolvedRowPath := path
                SSOK_Expense_SaveRowPath(path)
                SSOK_Expense_Log("button-path-ok elapsedMs=" . (A_TickCount - started))
                return true
            }
            result := SSOK_Expense_MSAA_FindNamed(root, "add", target)
            if (result.ok)
            {
                SSOK_ExpenseAddButtonCache := result.hit
                SSOK_ExpenseResolvedRowPath := result.hit.child = 0 ? result.hit.path : ""
                SSOK_Expense_SaveRowPath(SSOK_ExpenseResolvedRowPath)
                SSOK_Expense_Log("button-search-ok nodes=" . result.nodes . " elapsedMs=" . (A_TickCount - started))
                return true
            }
            SSOK_ExpenseLastError := result.reason
            if (result.HasKey("retryable") && !result.retryable)
                break
        }
        else
            SSOK_ExpenseLastError := "K-¿¡µàÆÄÀÎ Á¢±Ù¼º È­¸éÀ» ÀÐÁö ¸øÇß½À´Ï´Ù."
        ; ÀçºÎÆÃ Á÷ÈÄ ºê¶ó¿ìÀú°¡ Á¢±Ù¼º Æ®¸®¸¦ ÁØºñÇÒ ½Ã°£À» ÁÝ´Ï´Ù.
        if (A_Index < 5)
            Sleep, % 600 * A_Index
    }
    SSOK_Expense_Log("button-not-found: " . SSOK_ExpenseLastError)
    return false
}

SSOK_Expense_MSAA_IsFixedTitleText(obj)
{
    return SSOK_Expense_MSAA_Usable(obj, 0, true)
        && SSOK_Expense_MSAA_Get(obj, "Role", 0) = 42
}


SSOK_Expense_MSAA_IsFixedOverviewText(obj)
{
    return SSOK_Expense_MSAA_Usable(obj, 0, true)
        && SSOK_Expense_MSAA_Get(obj, "Role", 0) = 42
}

; ÇöÀç ´ë»ó Ã¢ÀÇ Ç¥½Ã ÁßÀÎ Chrome renderer root¸¦ Ã£½À´Ï´Ù.
; ÀüÃ¼ Á¢±Ù¼º Æ®¸®´Â ¼øÈ¸ÇÏÁö ¾Ê½À´Ï´Ù.
SSOK_Expense_MSAA_GetEdufineRoot(target, force := false)
{
    global SSOK_ExpenseEdufineRootHwnd, SSOK_ExpenseRootTarget
    global SSOK_ExpenseMSAAWindows
    if (!force && SSOK_ExpenseRootTarget = target && SSOK_ExpenseEdufineRootHwnd
        && DllCall("IsWindow", "Ptr", SSOK_ExpenseEdufineRootHwnd)
        && DllCall("IsChild", "Ptr", target, "Ptr", SSOK_ExpenseEdufineRootHwnd))
    {
        root := SSOK_Expense_MSAA_FromWindow(SSOK_ExpenseEdufineRootHwnd, -4)
        if IsObject(root)
            return root
    }
    SSOK_ExpenseEdufineRootHwnd := 0
    SSOK_ExpenseRootTarget := target
    SSOK_ExpenseMSAAWindows := []
    cb := RegisterCallback("SSOK_Expense_MSAA_EnumChildCB", "Fast", 2)
    DllCall("EnumChildWindows", "Ptr", target, "Ptr", cb, "Ptr", 0)
    DllCall("GlobalFree", "Ptr", cb)
    WinGetTitle, windowTitle, ahk_id %target%
    for _, hwnd in SSOK_ExpenseMSAAWindows
    {
        WinGetClass, cls, ahk_id %hwnd%
        if (cls != "Chrome_RenderWidgetHostHWND" || !DllCall("IsWindowVisible", "Ptr", hwnd))
            continue
        root := SSOK_Expense_MSAA_FromWindow(hwnd, -4)
        if !IsObject(root)
            continue
        name := SSOK_Expense_MSAA_Get(root, "Name", 0)
        ; WebDRM Á¢¹Ì»ç´Â ¼¼¼Ç¿¡ µû¶ó ¾ø¾îÁú ¼ö ÀÖÀ¸¹Ç·Î ÇÊ¼ö Á¶°ÇÀ¸·Î ¾²Áö ¾Ê½À´Ï´Ù.
        if (InStr(name, "¿¡µàÆÄÀÎ") || (name = "" && InStr(windowTitle, "¿¡µàÆÄÀÎ")))
        {
            SSOK_ExpenseEdufineRootHwnd := hwnd
            return root
        }
    }
    return ""
}

; /obj[1]/obj[3]... °æ·Î¸¦ ±×´ë·Î µû¶ó°¨.
; °¢ ´Ü°è¿¡¼­ AccessibleChildren ÇÑ ¹ø¸¸ È£ÃâÇÕ´Ï´Ù.
SSOK_Expense_MSAA_FollowFixedPath(root, path)
{
    current := root
    pos := 1

    while (pos := RegExMatch(path, "/obj\[(\d+)\]", m, pos))
    {
        idx := m1 + 0
        children := SSOK_Expense_MSAA_GetChildren(current)

        if !IsObject(children)
            return ""

        if (idx < 1 || idx > children.Length())
            return ""

        item := children[idx]

        if (item.kind != 2)
            return ""

        current := item.acc
        pos += StrLen(m)
    }

    return current
}

SSOK_Expense_MSAA_FromPointFast(x, y)
{
    VarSetCapacity(varChild, 8 + 2*A_PtrSize, 0)
    pt := (y << 32) | (x & 0xFFFFFFFF)

    hr := DllCall("oleacc\AccessibleObjectFromPoint", "Int64", pt, "PtrP", pAcc, "Ptr", &varChild, "UInt")

    if (hr != 0 || !pAcc)
        return ""

    try
    {
        acc := ComObjEnwrap(9, pAcc, 1)
    }
    catch
    {
        return ""
    }

    child := NumGet(varChild, 8, "Int")
    return {acc:acc, child:child}
}

; ------------------------------------------------------------
; ÇöÀç È°¼º Edge/K-¿¡µàÆÄÀÎ Ã¢°ú ¸ðµç ÀÚ½Ä HWNDÀÇ
; OBJID_CLIENT MSAA Æ®¸®¸¦ AccessibleChildren()À¸·Î ¼øÈ¸ÇÕ´Ï´Ù.
;
; mode="count" : NameÀÌ Á¤È®È÷ "¼±ÅÃ"ÀÎ °´Ã¼ °³¼ö °è»ê
; ------------------------------------------------------------
SSOK_Expense_MSAA_Scan(topHwnd, mode := "count")
{
    global SSOK_ExpenseMSAAWindows

    SSOK_ExpenseMSAAWindows := []
    SSOK_ExpenseMSAAWindows.Push(topHwnd)

    cb := RegisterCallback("SSOK_Expense_MSAA_EnumChildCB", "Fast", 2)
    DllCall("EnumChildWindows", "Ptr", topHwnd, "Ptr", cb, "Ptr", 0)
    DllCall("GlobalFree", "Ptr", cb)

    state := {nodes:0, limit:20000, selectCount:0, roots:0}

    for _, hwnd in SSOK_ExpenseMSAAWindows
    {
        root := SSOK_Expense_MSAA_FromWindow(hwnd, -4)
        if !IsObject(root)
            continue

        state.roots++
        SSOK_Expense_MSAA_WalkCount(root, 0, state)

        if (state.nodes > state.limit)
            break
    }

    return {ok:(state.roots > 0), selectCount:state.selectCount, nodes:state.nodes}
}

SSOK_Expense_MSAA_WalkCount(acc, depth, state)
{
    if (depth > 45 || state.nodes > state.limit)
        return

    state.nodes++

    name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", 0))
    if (name = "¼±ÅÃ")
        state.selectCount++

    children := SSOK_Expense_MSAA_GetChildren(acc)
    if !IsObject(children)
        return

    for _, item in children
    {
        if (state.nodes > state.limit)
            return

        if (item.kind = 1)
        {
            state.nodes++
            cName := Trim(SSOK_Expense_MSAA_Get(acc, "Name", item.id))

            if (cName = "¼±ÅÃ")
                state.selectCount++
        }
        else if (item.kind = 2)
        {
            SSOK_Expense_MSAA_WalkCount(item.acc, depth + 1, state)
        }
    }
}

; ------------------------------------------------------------
; Name¿¡ "ÇàÃß°¡"°¡ Æ÷ÇÔµÇ°í Role=PushButton(43)ÀÎ °´Ã¼ ÀÚµ¿°Ë»ö
; ------------------------------------------------------------

SSOK_Expense_MSAA_WalkFindButton(acc, depth, state)
{
    if (depth > 45)
        return ""

    state.nodes++
    if (state.nodes > state.limit)
        return ""

    name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", 0))
    role := SSOK_Expense_MSAA_Get(acc, "Role", 0)

    if (InStr(name, "ÇàÃß°¡") && role = 43)
        return {acc:acc, child:0}

    children := SSOK_Expense_MSAA_GetChildren(acc)
    if !IsObject(children)
        return ""

    for _, item in children
    {
        if (item.kind = 1)
        {
            state.nodes++
            if (state.nodes > state.limit)
                return ""

            cName := Trim(SSOK_Expense_MSAA_Get(acc, "Name", item.id))
            cRole := SSOK_Expense_MSAA_Get(acc, "Role", item.id)

            if (InStr(cName, "ÇàÃß°¡") && cRole = 43)
                return {acc:acc, child:item.id}
        }
        else if (item.kind = 2)
        {
            found := SSOK_Expense_MSAA_WalkFindButton(item.acc, depth + 1, state)

            if IsObject(found)
                return found
        }
    }

    return ""
}

SSOK_Expense_MSAA_EnumChildCB(hwnd, lParam)
{
    global SSOK_ExpenseMSAAWindows
    SSOK_ExpenseMSAAWindows.Push(hwnd)
    return 1
}

SSOK_Expense_MSAA_FromWindow(hwnd, objid)
{
    VarSetCapacity(iid, 16, 0)
    hr := DllCall("ole32\CLSIDFromString", "WStr", "{618736E0-3C3D-11CF-810C-00AA00389B71}", "Ptr", &iid, "Int")

    if (hr != 0)
        return ""

    pAcc := 0
    hr := DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hwnd, "UInt", objid, "Ptr", &iid, "PtrP", pAcc, "UInt")

    if (hr != 0 || !pAcc)
        return ""

    try
    {
        return ComObjEnwrap(9, pAcc, 1)
    }
    catch
    {
        return ""
    }
}

SSOK_Expense_MSAA_GetChildren(acc)
{
    try
    {
        count := acc.accChildCount
    }
    catch
    {
        return ""
    }

    arr := []

    if (count <= 0)
        return arr

    vsize := 8 + 2*A_PtrSize
    VarSetCapacity(buf, count * vsize, 0)

    got := 0
    hr := DllCall("oleacc\AccessibleChildren", "Ptr", ComObjValue(acc), "Int", 0, "Int", count, "Ptr", &buf, "IntP", got, "UInt")

    if ((hr != 0 && hr != 1) || got <= 0)
        return arr

    Loop, %got%
    {
        off := (A_Index - 1) * vsize
        vt := NumGet(buf, off, "UShort")

        if (vt = 3)
        {
            cid := NumGet(buf, off + 8, "Int")
            arr.Push({kind:1, id:cid})
        }
        else if (vt = 9)
        {
            pDisp := NumGet(buf, off + 8, "Ptr")

            if (pDisp)
            {
                childAcc := SSOK_Expense_MSAA_QueryAccessible(pDisp)
                ObjRelease(pDisp)

                if IsObject(childAcc)
                    arr.Push({kind:2, acc:childAcc})
            }
        }
    }

    return arr
}

SSOK_Expense_MSAA_QueryAccessible(pDisp)
{
    try
    {
        pAcc := ComObjQuery(pDisp, "{618736E0-3C3D-11CF-810C-00AA00389B71}")

        if (!pAcc)
            return ""

        return ComObj(9, pAcc, 1)
    }
    catch
    {
        return ""
    }
}

SSOK_Expense_MSAA_Get(acc, prop, child)
{
    try
    {
        if (prop = "Name")
            return acc.accName(child)

        if (prop = "Value")
            return acc.accValue(child)

        if (prop = "Role")
            return acc.accRole(child)

        if (prop = "Action")
            return acc.accDefaultAction(child)

        if (prop = "State")
            return acc.accState(child)
    }
    catch
    {
        return ""
    }

    return ""
}

SSOK_Expense_MSAA_DoAction(btn)
{
    try
    {
        btn.acc.accDoDefaultAction(btn.child)
        return true
    }
    catch
    {
        return false
    }
}

SSOK_Expense_Active(target)
{
    global SSOK_ExpenseCancel
    return !SSOK_ExpenseCancel && WinActive("ahk_id " . target)
}

SSOK_Expense_Tab(target, count := 1)
{
    Loop, %count%
    {
        if (!SSOK_Expense_Active(target))
            return false

        ; Nexacro°¡ ÀÌÀü ¼¿ °ªÀ» È®Á¤ÇÑ ÈÄ ´ÙÀ½ ¼¿·Î ÀÌµ¿ÇÏµµ·Ï ¿©À¯¸¦ µÒ
        SendInput, {Tab}
        Sleep, 70
    }
    return SSOK_Expense_Active(target)
}

SSOK_Expense_Unit(target, mode := "all")
{
    if (!SSOK_Expense_Active(target))
        return false

    ; ¿øÇà¸ñ·ÏÀº Ã¹ Ç×¸ñÀÌ '°³', Ç°ÀÇ´Â '¼±ÅÃ' ´ÙÀ½ Ç×¸ñÀÌ '°³'ÀÔ´Ï´Ù.
    SendInput, {Home}
    Sleep, 55
    if (mode != "cause")
    {
        if (!SSOK_Expense_Active(target))
            return false
        SendInput, {Down}
    }
    Sleep, 80
    return SSOK_Expense_Active(target)
}

SSOK_Expense_Field(value, target, unit := false)
{
    if (!SSOK_Expense_Active(target))
        return false

    if (unit)
    {
        SendInput, {Home}
        Sleep, 30
        SendInput, {Text}°³
    }
    else if (value = "")
    {
        SendInput, ^a
        Sleep, 18
        SendInput, {Delete}
    }
    else
    {
        Clipboard := ""
        Clipboard := value . ""
        ClipWait, 0.5

        if (ErrorLevel || !SSOK_Expense_Active(target))
            return false

        SendInput, ^a
        Sleep, 18
        SendInput, ^v
    }

    ; ±ä °ßÀû¼­¿¡¼­ ºÙ¿©³Ö±â/¼¿ È®Á¤ÀÌ ³¡³ª±â Àü¿¡ TabÀÌ µé¾î°¡´Â °ÍÀ» ¹æÁö
    Sleep, 90
    return SSOK_Expense_Active(target)
}

; Session-independent discovery. Logs contain stages/counts only, not quotation/form contents.
SSOK_Expense_Log(message)
{
    FormatTime, stamp,, yyyy-MM-dd HH:mm:ss
    path := A_ScriptDir . "\ssok_expense_diagnostic.log"
    FileGetSize, bytes, %path%
    if (bytes > 262144)
        FileDelete, %path%
    FileAppend, % stamp . " " . message . "`r`n", %path%, UTF-8
}

SSOK_Expense_MSAA_Usable(acc, child, editable := false)
{
    if !IsObject(acc)
        return false
    state := SSOK_Expense_MSAA_Get(acc, "State", child)
    mask := editable ? 0x8001 : 0x18001 ; offscreen edit fields may receive focus and scroll into view
    if (state = "" || (state & mask))
        return false
    return !(editable && (state & 0x40)) ; readonly
}

SSOK_Expense_MSAA_Matches(acc, child, kind)
{
    if (!SSOK_Expense_MSAA_Usable(acc, child, kind != "add"))
        return false
    role := SSOK_Expense_MSAA_Get(acc, "Role", child)
    name := RegExReplace(SSOK_Expense_MSAA_Get(acc, "Name", child), "[\s\x{00A0}:£º*]", "")
    if (kind = "add")
        return role = 43 && RegExMatch(name, "^(ÇàÃß°¡|ÇàÃß°¡¹öÆ°)(\(.*\))?$")
    if (role != 42)
        return false
    if (kind = "title")
        return RegExMatch(name, "^(Á¦¸ñ|Ç°ÀÇÁ¦¸ñ|¹®¼­Á¦¸ñ)(ÀÔ·Â)?$")
    return RegExMatch(name, "^(°³¿ä|Ç°ÀÇ°³¿ä)(ÀÔ·Â)?$")
}

SSOK_Expense_MSAA_FindNamed(root, kind, target := 0)
{
    state := {nodes:0, limit:30000, deadline:A_TickCount + 18000, hits:[], stopped:false, target:target, stack:[]}
    SSOK_Expense_MSAA_WalkNamed(root, 0, "", kind, state)
    n := state.hits.Length()
    ; ¸ðµç ÈÄº¸¸¦ ÀÐ±â Àü¿¡ ¼±ÅÃÇÏ¸é µÚ¿¡ ÀÖ´Â Ç°¸ñ ¹öÆ°À» ³õÄ¡¹Ç·Î ³¡±îÁö ¼öÁýÇÕ´Ï´Ù.
    if (state.stopped)
    {
        if (kind = "add")
            SSOK_Expense_MSAA_ChooseItemButton(state.hits) ; diagnostics only; incomplete scans never click
        SSOK_Expense_Log("search-incomplete kind=" . kind . " nodes=" . state.nodes . " candidates=" . n)
        return {ok:false, retryable:true, nodes:state.nodes, reason:"È­¸é Å½»öÀÌ Áß´ÜµÇ°Å³ª Á¦ÇÑ ½Ã°£À» ÃÊ°úÇß½À´Ï´Ù."}
    }
    if (kind = "add")
    {
        result := SSOK_Expense_MSAA_ChooseItemButton(state.hits)
        result.nodes := state.nodes
        return result
    }
    if (n != 1)
        return {ok:false, nodes:state.nodes, reason:(n ? "ÀÔ·Â¶õÀ» ÇÏ³ª·Î ±¸ºÐÇÏÁö ¸øÇß½À´Ï´Ù." : "Ç¥½Ã ÁßÀÎ ´ë»ó ¿ä¼Ò¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.")}
    return {ok:true, hit:state.hits[1], nodes:state.nodes}
}

SSOK_Expense_MSAA_WalkNamed(acc, depth, path, kind, state)
{
    if (state.stopped)
        return
    if (depth > 160 || state.nodes >= state.limit || A_TickCount > state.deadline
        || (state.target && !SSOK_Expense_Active(state.target)))
    {
        state.stopped := true
        return
    }
    ; °°Àº COM °´Ã¼°¡ ¿©·¯ °æ·Î·Î ³ëÃâµÇ¾îµµ ÇÑ ¹ø¸¸ ÀÐ½À´Ï´Ù.
    identity := SSOK_Expense_MSAA_Identity({acc:acc, child:0})
    if (identity != "")
    {
        if (state.seen.HasKey(identity))
        {
            state.duplicates++
            return
        }
        state.seen[identity] := acc
    }
    state.nodes++
    status := SSOK_Expense_MSAA_Get(acc, "State", 0)
    if (status != "" && (status & 0x8000))
        return
    frame := {path:path, mask:0, hits:[]}
    state.stack.Push(frame)
    SSOK_Expense_MSAA_RecordNode(acc, 0, path, kind, state)
    ; ÀÌ¸§ÀÌ ºÙÀº ÄÁÅ×ÀÌ³Êµµ ÀÚ½ÄÀ» Á¶»çÇÕ´Ï´Ù. Çì´õ³ª µ¿ÀÏ ¹öÆ°ÀÇ ³ëÃâÀÌ ÀÖÀ» ¼ö ÀÖ½À´Ï´Ù.
    children := SSOK_Expense_MSAA_GetChildren(acc)
    for index, item in children
    {
        if (state.stopped)
            break
        if (item.kind = 2)
            SSOK_Expense_MSAA_WalkNamed(item.acc, depth + 1, path . "/obj[" . index . "]", kind, state)
        else
        {
            state.nodes++
            if (state.nodes >= state.limit || A_TickCount > state.deadline
                || (state.target && !SSOK_Expense_Active(state.target)))
            {
                state.stopped := true
                break
            }
            SSOK_Expense_MSAA_RecordNode(acc, item.id, path, kind, state)
        }
    }
    state.stack.Pop()
}

SSOK_Expense_MSAA_ResolveField(target, kind)
{
    global SSOK_ExpenseResolvedRowPath
    root := SSOK_Expense_MSAA_GetEdufineRoot(target, false)
    if !IsObject(root)
        return ""
    ; ÇàÃß°¡¿Í °°Àº Ç°ÀÇ ÆûÀ» ±âÁØÀ¸·Î Á¦¸ñ/°³¿äÀÇ »ó´ë °æ·Î¸¦ ´Ù½Ã °è»êÇÕ´Ï´Ù.
    ; Àç·Î±×ÀÎÀ¸·Î »óÀ§ obj[55], obj[11] ¹øÈ£°¡ ¹Ù²î¾îµµ µû¶ó°©´Ï´Ù.
    suffix := "/obj[6]/obj[1]/obj[1]/obj[1]/obj[8]"
    if (SubStr(SSOK_ExpenseResolvedRowPath, 1 - StrLen(suffix)) = suffix)
    {
        prefix := SubStr(SSOK_ExpenseResolvedRowPath, 1, StrLen(SSOK_ExpenseResolvedRowPath) - StrLen(suffix))
        tail := "/obj[1]/obj[1]/obj[1]/obj[1]/obj["
        title := SSOK_Expense_MSAA_FollowFixedPath(root, prefix . tail . "17]/obj[1]")
        overview := SSOK_Expense_MSAA_FollowFixedPath(root, prefix . tail . "18]/obj[1]/obj[1]")
        if (SSOK_Expense_MSAA_IsFixedTitleText(title) && SSOK_Expense_MSAA_IsFixedOverviewText(overview))
        {
            obj := kind = "title" ? title : overview
            ; ¸í½ÃÀûÀÎ ´Ù¸¥ ÇÊµå ÀÌ¸§ÀÌ ÀÖÀ¸¸é »ó´ë À§Ä¡¸¸ ¹Ï°í ÀÔ·ÂÇÏÁö ¾Ê½À´Ï´Ù.
            name := Trim(SSOK_Expense_MSAA_Get(obj, "Name", 0))
            if (name = "" || SSOK_Expense_MSAA_Matches(obj, 0, kind))
                return {acc:obj, child:0}
        }
    }
    result := SSOK_Expense_MSAA_FindNamed(root, kind, target)
    SSOK_Expense_Log(kind . (result.ok ? "-search-ok" : "-search-failed"))
    return result.ok ? result.hit : ""
}

SSOK_Expense_MSAA_FocusField(field, target)
{
    if (!IsObject(field) || !SSOK_Expense_Active(target)
        || !SSOK_Expense_MSAA_Usable(field.acc, field.child, true))
        return false
    try
        field.acc.accSelect(1, field.child)
    Sleep, 70
    state := SSOK_Expense_MSAA_Get(field.acc, "State", field.child)
    if (!(state & 4))
    {
        if (!SSOK_Expense_Active(target) || !SSOK_Expense_MSAA_DoAction(field))
            return false
        Sleep, 70
        state := SSOK_Expense_MSAA_Get(field.acc, "State", field.child)
    }
    ; Æ÷Ä¿½º°¡ È®ÀÎµÇÁö ¾ÊÀ¸¸é Ctrl+A/Ctrl+V¸¦ º¸³»Áö ¾Ê½À´Ï´Ù.
    if (!(state & 4))
        SSOK_Expense_Log("field-focus-not-confirmed")
    return (state & 4) && SSOK_Expense_Active(target)
}
; Collect nearby table headers alongside candidates in one traversal.
SSOK_Expense_MSAA_RecordNode(acc, child, path, kind, state)
{
    if (kind = "add")
    {
        status := SSOK_Expense_MSAA_Get(acc, "State", child)
        if (status != "" && !(status & 0x8000))
        {
            bit := SSOK_Expense_MSAA_ItemHeaderBit(SSOK_Expense_MSAA_Get(acc, "Name", child))
            if (bit)
            {
                for _, frame in state.stack
                    frame.mask |= bit
            }
        }
    }
    if (!SSOK_Expense_MSAA_Matches(acc, child, kind))
        return
    hit := {acc:acc, child:child, path:path, contexts:[]}
    if (kind = "add")
    {
        ; Only local containers count as evidence; not an entire page with unrelated tables.
        first := Max(1, state.stack.Length() - 8)
        for index, frame in state.stack
        {
            if (index < first)
                continue
            hit.contexts.Push(frame)
            ; Store lightweight identities, not hit objects (avoid cyclic COM references).
            frame.hits.Push({acc:acc, child:child, path:path})
        }
    }
    state.hits.Push(hit)
}

SSOK_Expense_MSAA_ItemHeaderBit(name)
{
    name := RegExReplace(name, "[\s\x{00A0}:£º*]", "")
    name := RegExReplace(name, "\((¿ø|ÇÊ¼ö)\)$", "")

    ; ±¸Çü/½ÅÇü K-¿¡µàÆÄÀÎ ¹°Ç°³»¿ª ¸Ó¸®±ÛÀ» ¸ðµÎ ÀÎÁ¤ÇÕ´Ï´Ù.
    if (name = "³»¿ë" || name = "Ç°¸ñ¸í" || name = "Ç°¸í")
        return 1
    if (name = "±Ô°Ý")
        return 2
    if (name = "¼ö·®")
        return 4
    if (name = "´ÜÀ§")
        return 8
    if (name = "¿¹»ó´Ü°¡" || name = "´Ü°¡")
        return 16
    if (name = "¿¹»ó±Ý¾×" || name = "±Ý¾×")
        return 32
    if (name = "Á¶´Þ¼ö¼ö·á")
        return 64
    if (name = "¿ëµµ(Àû¿ä)" || name = "¿ëµµ" || name = "Àû¿ä")
        return 128
    return 0
}

SSOK_Expense_MSAA_IsItemHeaderMask(mask)
{
    ; Ç°¸í + ¼ö·® + ´Ü°¡°¡ º¸ÀÌ°í, ±Ô°Ý/´ÜÀ§/±Ý¾× Áß ÇÏ³ª ÀÌ»óÀÌ ÇÔ²² ÀÖÀ¸¸é
    ; ¹°Ç°³»¿ª Ç¥·Î ÆÇ´ÜÇÕ´Ï´Ù. Á¶´Þ¼ö¼ö·á/¿ëµµ´Â Á¸Àç ¿©ºÎ¿Í ¹«°üÇÕ´Ï´Ù.
    return (mask & 21) = 21 && (mask & 42)
}

SSOK_Expense_MSAA_Identity(hit)
{
    ; Compare COM identity, not the language wrapper's memory address.
    try
    {
        ptr := ComObjQuery(hit.acc, "{00000000-0000-0000-C000-000000000046}")
        if (ptr)
        {
            key := ptr . ":" . hit.child
            ObjRelease(ptr)
            return key
        }
    }
    return ""
}

SSOK_Expense_MSAA_ButtonRect(hit)
{
    ; Geometry is read only to identify duplicate accessibility representations, never for clicking.
    try
    {
        VarSetCapacity(x, 4, 0), VarSetCapacity(y, 4, 0)
        VarSetCapacity(w, 4, 0), VarSetCapacity(h, 4, 0)
        hit.acc.accLocation(ComObj(0x4003, &x), ComObj(0x4003, &y)
            , ComObj(0x4003, &w), ComObj(0x4003, &h), hit.child)
        x := NumGet(x, 0, "Int"), y := NumGet(y, 0, "Int")
        w := NumGet(w, 0, "Int"), h := NumGet(h, 0, "Int")
        if (w > 0 && h > 0)
            return x . "," . y . "," . w . "," . h
    }
    return ""
}

SSOK_Expense_MSAA_UniqueButtons(hits, useRect := false)
{
    out := [], identities := {}, rectangles := {}
    for _, hit in hits
    {
        key := SSOK_Expense_MSAA_Identity(hit)
        rect := useRect ? SSOK_Expense_MSAA_ButtonRect(hit) : ""
        duplicate := (key != "" && identities.HasKey(key)) || (rect != "" && rectangles.HasKey(rect))
        if (key != "")
            identities[key] := true
        if (rect != "")
            rectangles[rect] := true
        if (!duplicate)
            out.Push(hit)
    }
    return out
}

SSOK_Expense_MSAA_ChooseItemButton(hits)
{
    eligible := []
    for index, hit in hits
    {
        matched := false, mask := 0
        ; Use the smallest ancestor containing the item columns and only one physical button.
        Loop, % hit.contexts.Length()
        {
            frame := hit.contexts[hit.contexts.Length() - A_Index + 1]
            mask |= frame.mask
            if (SSOK_Expense_MSAA_IsItemHeaderMask(frame.mask)
                && SSOK_Expense_MSAA_UniqueButtons(frame.hits, true).Length() = 1)
            {
                matched := true
                break
            }
        }
        if (matched)
            eligible.Push(hit)
        SSOK_Expense_Log("button-candidate=" . index . " path=" . hit.path . " child=" . hit.child
            . " itemHeaders=" . mask . " itemContext=" . (matched ? 1 : 0))
    }
    ; Rectangle deduplication is restricted to candidates independently tied to the item table.
    chosen := SSOK_Expense_MSAA_UniqueButtons(eligible, true)
    allUnique := SSOK_Expense_MSAA_UniqueButtons(hits)
    SSOK_Expense_Log("button-candidates=" . hits.Length() . " identities=" . allUnique.Length() . " itemButtons=" . chosen.Length())
    if (chosen.Length() = 1)
        return {ok:true, hit:SSOK_Expense_MSAA_PreferRowPath(chosen[1], eligible)}
    ; Retain compatibility with screens exposing only one named button and no header names.
    if (allUnique.Length() = 1)
        return {ok:true, hit:SSOK_Expense_MSAA_PreferRowPath(allUnique[1], hits)}
    return {ok:false, retryable:!hits.Length(), reason:(hits.Length() ? "ÇàÃß°¡ ÈÄº¸ Áß Ç°¸ñ Ç¥ÀÇ ¹öÆ°À» ±¸ºÐÇÏÁö ¸øÇß½À´Ï´Ù. Áø´Ü ±â·Ï¿¡ ÈÄº¸ °æ·Î¸¦ ³²°å½À´Ï´Ù." : "Ç¥½Ã ÁßÀÎ ÇàÃß°¡ ¹öÆ°À» Ã£Áö ¸øÇß½À´Ï´Ù.")}
}
SSOK_Expense_MSAA_PreferRowPath(selected, aliases)
{
    ; Preserve the known item-form relative path when the same button has several representations.
    suffix := "/obj[6]/obj[1]/obj[1]/obj[1]/obj[8]"
    key := SSOK_Expense_MSAA_Identity(selected)
    rect := SSOK_Expense_MSAA_ButtonRect(selected)
    for _, hit in aliases
    {
        if (hit.child != 0 || SubStr(hit.path, 1 - StrLen(suffix)) != suffix)
            continue
        if ((key != "" && key = SSOK_Expense_MSAA_Identity(hit))
            || (rect != "" && rect = SSOK_Expense_MSAA_ButtonRect(hit)))
            return hit
    }
    return selected
}
SSOK_Expense_PathCacheFile()
{
    global SSOK_ConfigDir, SSOK_IniFile
    static migrated := false

    ; ÁöÃâÇ°ÀÇ Àü¿ë º°µµ INI¸¦ ¸¸µéÁö ¾Ê°í SSOK °ø¿ë ssok.ini¸¦ »ç¿ëÇÕ´Ï´Ù.
    if (SSOK_IniFile != "")
        file := SSOK_IniFile
    else
    {
        dir := SSOK_ConfigDir != "" ? SSOK_ConfigDir : A_ScriptDir
        file := dir . "\ssok.ini"
    }

    ; ¿¹Àü ssok_expense_path.ini°¡ ÀÖÀ¸¸é ÃÖÃÊ 1È¸ ±âÁ¸ Ä³½Ã¸¦ ssok.ini·Î ¿Å±é´Ï´Ù.
    ; ±âÁ¸ ÆÄÀÏÀº ¾ÈÀüÀ» À§ÇØ ÀÚµ¿ »èÁ¦ÇÏÁö ¾Ê½À´Ï´Ù.
    if (!migrated)
    {
        migrated := true
        SSOK_Expense_MigratePathCacheToMainIni(file)
    }

    return file
}

SSOK_Expense_MigratePathCacheToMainIni(mainFile)
{
    global SSOK_ConfigDir

    dir := SSOK_ConfigDir != "" ? SSOK_ConfigDir : A_ScriptDir
    oldFile := dir . "\ssok_expense_path.ini"

    if (!FileExist(oldFile) || oldFile = mainFile)
        return

    keys := ["RowPath", "TotalLabelX", "TotalLabelY", "TotalLabelW", "TotalLabelH"]

    for _, key in keys
    {
        ; ssok.ini¿¡ ÀÌ¹Ì °ªÀÌ ÀÖÀ¸¸é ±âÁ¸ °ªÀ» ¿ì¼±ÇÕ´Ï´Ù.
        IniRead, current, %mainFile%, ExpenseMSAA, %key%, ERROR
        if (current != "ERROR" && current != "")
            continue

        IniRead, oldValue, %oldFile%, ExpenseMSAA, %key%, ERROR
        if (oldValue = "ERROR" || oldValue = "")
            continue

        ; RowPath´Â Çü½Ä±îÁö °ËÁõÇÏ°í, ÁÂÇ¥°ªÀº ¼ýÀÚ¸¸ ¿Å±é´Ï´Ù.
        if (key = "RowPath")
        {
            if (!SSOK_Expense_IsRowPath(oldValue))
                continue
        }
        else if !RegExMatch(oldValue, "^-?\d+(?:\.\d+)?$")
            continue

        IniWrite, %oldValue%, %mainFile%, ExpenseMSAA, %key%
    }
}

SSOK_Expense_IsRowPath(path)
{
    return StrLen(path) <= 2048 && RegExMatch(path, "^(?:/obj\[[1-9]\d*\]){1,70}$")
}

SSOK_Expense_LoadRowPath()
{
    file := SSOK_Expense_PathCacheFile()
    IniRead, path, %file%, ExpenseMSAA, RowPath, ERROR
    return SSOK_Expense_IsRowPath(path) ? path : ""
}

SSOK_Expense_SaveRowPath(path)
{
    if (!SSOK_Expense_IsRowPath(path))
        return false
    file := SSOK_Expense_PathCacheFile()
    ; ¾²±â ±ÇÇÑÀÌ ¾ø´õ¶óµµ ¸Þ¸ð¸® °æ·Î·Î °è¼Ó µ¿ÀÛÇÕ´Ï´Ù.
    ; ÀúÀåµÈ °æ·Î´Â Å¬¸¯ Àü¿¡ ÇöÀç È­¸éÀÇ ¹öÆ° ÀÌ¸§/¿ªÇÒ/»óÅÂ·Î ´Ù½Ã °ËÁõÇÕ´Ï´Ù.
    IniRead, saved, %file%, ExpenseMSAA, RowPath, ERROR
    if (saved = path)
        return true
    IniWrite, %path%, %file%, ExpenseMSAA, RowPath
    return !ErrorLevel
}

SSOK_Expense_RowFields(row, mode)
{
    fields := [row.name, row.spec, row.qty, "°³", row.price, row.amount]
    if (mode = "cause")
    {
        fields.Push(row.HasKey("procurementFee") ? row.procurementFee : "")
        fields.Push(row.HasKey("purpose") ? row.purpose : "")
    }
    return fields
}

SSOK_Expense_InputRows(target)
{
    global SSOK_ExpenseRows, SSOK_ExpenseMode
    saved := ClipboardAll
    ; ½ÃÀÛ ½Ã ¼±ÅÃÇÑ ¸Þ´º¸¦ °íÁ¤: Ç°ÀÇ 6Ä­, ¿øÇà 8Ä­.
    mode := SSOK_ExpenseMode
    try
    {
        for i, row in SSOK_ExpenseRows
        {
            fields := SSOK_Expense_RowFields(row, mode)
            for column, value in fields
            {
                if (column = 4)
                    ok := SSOK_Expense_Unit(target, mode)
                else
                    ok := SSOK_Expense_Field(value, target)
                if (!ok)
                    return false
                ; Ç°ÀÇ È­¸éÀº ±Ý¾× µÚ µÎ Tab À§Ä¡¸¦ °Ç³Ê¾ß ´ÙÀ½ Çà Ç°¸íÀÔ´Ï´Ù.
                ; ¿øÇà¸ñ·ÏÀº ¿ëµµ(Àû¿ä)¿¡¼­ ´ÙÀ½ Çà Ç°¸í±îÁö Tab 2È¸ÀÔ´Ï´Ù.
                ; °Ç³Ê°¡´Â À§Ä¡¿¡´Â °ªÀ» ¾²°Å³ª Áö¿ìÁö ¾Ê½À´Ï´Ù.
                if (column < fields.Length())
                {
                    if (!SSOK_Expense_Tab(target))
                        return false
                }
                else if (i < SSOK_ExpenseRows.Length())
                {
                    if (!SSOK_Expense_Tab(target, mode = "cause" ? 2 : 3))
                        return false
                }
            }
            if (i < SSOK_ExpenseRows.Length())
                Sleep, 85
        }
        return SSOK_Expense_Active(target)
    }
    finally
    {
        Clipboard := saved
        saved := ""
    }
}

SSOK_Expense_ResetRegistration()
{
    global SSOK_ExpenseMode, SSOK_ExpenseDetailSent, SSOK_ExpensePendingAdd
    SSOK_ExpensePendingAdd := ""
    ; »õ °ßÀû¼­ È®ÀÎÀ» ½ÃÀÛÇÒ ¶§¸¸ 1È¸ ÀÔ·Â ±â·ÏÀ» ÃÊ±âÈ­ÇÕ´Ï´Ù.
    SSOK_ExpenseMode := "all"
    SSOK_ExpenseDetailSent := {}
}

SSOK_Expense_Arm(mode)
{
    global SSOK_ExpenseMode, SSOK_ExpenseReady, SSOK_ExpenseStage

    if (mode = "items")
        SSOK_ExpenseMode := "items"
    else if (mode = "cause")
        SSOK_ExpenseMode := "cause"
    else
        SSOK_ExpenseMode := "all"

    SSOK_ExpenseReady := true
    SSOK_ExpenseStage := SSOK_ExpenseMode
    Gui, SSOKExpense:Destroy

    ; ÀÛÀº ToolTip ´ë½Å Å« Áß¾Ó ¾È³»Ã¢À» 3ÃÊ Ç¥½Ã
    SSOK_Expense_ShowModeNotice(SSOK_ExpenseMode)
}


; ------------------------------------------------------------
; µî·Ï ¹æ½Ä ¼±ÅÃ ÈÄ ¾È³»
; - Å« ±Û¾¾
; - °¡¿îµ¥ Á¤·Ä
; - È­¸é Áß¾Ó
; - 2ÃÊ ÈÄ ÀÚµ¿ Á¾·á
; ------------------------------------------------------------
SSOK_Expense_ShowModeNotice(mode)
{
    Gui, SSOKExpenseModeNotice:Destroy
    Gui, SSOKExpenseModeNotice:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKExpenseModeNotice:Color, FFFBEA
    Gui, SSOKExpenseModeNotice:Margin, 18, 16
    Gui, SSOKExpenseModeNotice:Font, s14 Bold, Malgun Gothic

    if (mode = "items" || mode = "cause")
    {
        ; ÇÑ Text ¾ÈÀÇ `n ´ë½Å µÎ °³ÀÇ Text ÄÁÆ®·Ñ·Î È®½ÇÇÏ°Ô 2ÁÙ Ç¥½Ã
        Gui, SSOKExpenseModeNotice:Add, Text, w720 h36 Center c222222, ¸ÕÀú Ç°¸ñ³»¿ª¿¡¼­ ÇàÃß°¡·Î ºó Ä­À» ¸¸µç ÈÄ
        Gui, SSOKExpenseModeNotice:Add, Text, y+2 w720 h36 Center c222222, Win + 1À» ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä
    }
    else
    {
        noticeText := "K¿¡µàÆÄÀÎ Ç°¸ñµî·Ï Ã¢¿¡¼­`n"
        noticeText .= "¿¹»ê³»¿ªÀ» ¼±ÅÃ ÈÄ`n"
        noticeText .= "´Ù½Ã WIN + 1 À» ´­·¯ÁÖ¼¼¿ä"

        Gui, SSOKExpenseModeNotice:Add, Text, w720 h100 +0x200 Center c222222, %noticeText%
    }

    Gui, SSOKExpenseModeNotice:Show, AutoSize Center NoActivate
    SetTimer, SSOKExpenseModeNoticeClose, -3000
}

SSOKExpenseModeNoticeClose:
    Gui, SSOKExpenseModeNotice:Destroy
return

SSOKExpenseBudgetNoticeClose:
    Gui, SSOKExpenseBudgetNotice:Destroy
return

SSOK_Expense_DetailIsEmpty(field)
{
    if (!IsObject(field) || !IsObject(field.acc))
        return false
    try
    {
        value := field.acc.accValue(field.child)
        return StrLen(Trim(value, " `t`r`n" . Chr(160))) = 0
    }
    catch
        return false
}
SSOK_Expense_WriteDetailOnce(target, kind, value)
{
    global SSOK_ExpenseMode, SSOK_ExpenseDetailSent
    if (!SSOK_Expense_Active(target) || SSOK_ExpenseMode = "items")
        return false
    if (!IsObject(SSOK_ExpenseDetailSent))
        SSOK_ExpenseDetailSent := {}
    if (SSOK_ExpenseDetailSent.HasKey(kind))
    {
        SSOK_Expense_Log("detail-skip-already-sent kind=" . kind)
        return true
    }
    field := SSOK_Expense_MSAA_ResolveField(target, kind)
    if (!IsObject(field))
        return false
    ; ÀÐ±â ½ÇÆÐ¸¦ ºóÄ­À¸·Î °£ÁÖÇÏÁö ¾Ê½À´Ï´Ù. ±âÁ¸ ³»¿ëÀº ±×´ë·Î º¸Á¸ÇÕ´Ï´Ù.
    if (!SSOK_Expense_DetailIsEmpty(field))
    {
        SSOK_ExpenseDetailSent[kind] := true
        SSOK_Expense_Log("detail-skip-existing-or-unreadable kind=" . kind)
        return true
    }
    if (!SSOK_Expense_MSAA_FocusField(field, target))
        return false
    ; Æ÷Ä¿½º¸¦ ¾ò´Â µ¿¾È °ªÀÌ ¹Ù²î¾úÀ» ¼ö ÀÖ¾î ºÙ¿©³Ö±â Á÷Àü¿¡ ´Ù½Ã È®ÀÎÇÕ´Ï´Ù.
    if (!SSOK_Expense_DetailIsEmpty(field))
    {
        SSOK_ExpenseDetailSent[kind] := true
        SSOK_Expense_Log("detail-skip-changed kind=" . kind)
        return true
    }
    ; È­¸é °ªÀÇ °ø¹é ¿©ºÎ¿Í ¹«°üÇÏ°Ô ÇÑ¹ø ½ÃµµÇÑ °³¿ä/Á¦¸ñÀº ÀçÀÔ·ÂÇÏÁö ¾Ê½À´Ï´Ù.
    ; ÀüºÎ »èÁ¦ÇÏ°Å³ª ¼öÁ¤ÇÑ »ç¿ëÀÚ ³»¿ëÀ» ±×´ë·Î À¯ÁöÇÕ´Ï´Ù.
    SSOK_ExpenseDetailSent[kind] := true
    ok := SSOK_Expense_PasteDetailText(target, value)
    SSOK_Expense_Log("detail-paste-once kind=" . kind . " completed=" . (ok ? 1 : 0))
    return ok
}

SSOK_Expense_PasteDetailText(target, value, leaveField := true)
{
    saved := ClipboardAll
    try
    {
        Clipboard := ""
        Clipboard := value
        ClipWait, 0.3
        if (ErrorLevel || !SSOK_Expense_Active(target))
            return false
        SendInput, ^a
        Sleep, 20
        if (!SSOK_Expense_Active(target))
            return false
        SendInput, ^v
        Sleep, 120
        if (!SSOK_Expense_Active(target))
            return false
        ; Win+3Àº °°Àº ÀÔ·ÂÄ­¿¡¼­ Win+F2·Î ÀÌ¾îÁö¹Ç·Î TabÀ» º¸³»Áö ¾Ê½À´Ï´Ù.
        if (leaveField)
        {
            SendInput, {Tab}
            Sleep, 70
        }
        return SSOK_Expense_Active(target)
    }
    finally
    {
        Clipboard := saved
        saved := ""
    }
}
SSOK_Expense_StopForBudget()
{
    global SSOK_ExpenseBusy, SSOK_ExpenseReady, SSOK_ExpenseStage, SSOK_ExpensePendingAdd
    SSOK_ExpenseBusy := false
    SSOK_ExpenseReady := false
    SSOK_ExpenseStage := ""
    SSOK_ExpensePendingAdd := ""
    SSOK_Expense_Log("registration-stopped budget-notice")
}

SSOK_Expense_RemainingRows(before, current, required)
{
    if (before < 0 || current < 0 || current < before || current - before > required)
        return -1
    return required - (current - before)
}

SSOK_Expense_ItemRowSnapshot(target)
{
    global SSOK_ExpenseResolvedRowPath
    ; ±âÁ¸¿¡ °üÂûÇÑ Nexacro Ç°¸ñ Ç¥¿¡¼­ '¼±ÅÃ' 2°³°¡ ºó Çà 1°³ÀÔ´Ï´Ù.
    ; ÀüÃ¼ ÆäÀÌÁöÀÇ ´Ù¸¥ Ç¥´Â ¼¼Áö ¾Ê°í ÇàÃß°¡°¡ ¼ÓÇÑ Ç°¸ñ ¿µ¿ª¸¸ È®ÀÎÇÕ´Ï´Ù.
    tail := "/obj[1]/obj[1]/obj[1]/obj[8]"
    if (SubStr(SSOK_ExpenseResolvedRowPath, 1 - StrLen(tail)) != tail)
        return -1
    root := SSOK_Expense_MSAA_GetEdufineRoot(target, false)
    if (!IsObject(root))
        return -1
    path := SubStr(SSOK_ExpenseResolvedRowPath, 1, StrLen(SSOK_ExpenseResolvedRowPath) - StrLen(tail))
    panel := SSOK_Expense_MSAA_FollowFixedPath(root, path)
    if (!IsObject(panel))
        return -1
    state := {seen:{}, duplicates:0, nodes:0, mask:0, selects:0, stopped:false, deadline:A_TickCount + 3000, target:target}
    SSOK_Expense_ScanItemRows(panel, 0, state)
    if (state.stopped || !SSOK_Expense_MSAA_IsItemHeaderMask(state.mask) || Mod(state.selects, 2))
        return -1
    count := state.selects // 2
    SSOK_Expense_Log("item-row-snapshot rows=" . count)
    return count
}

SSOK_Expense_ScanItemRows(acc, depth, state)
{
    if (state.stopped)
        return
    if (depth > 45 || state.nodes >= 10000 || A_TickCount > state.deadline || !SSOK_Expense_Active(state.target))
    {
        state.stopped := true
        return
    }
    ; °°Àº COM °´Ã¼°¡ ¿©·¯ °æ·Î·Î ³ëÃâµÇ¾îµµ ÇÑ ¹ø¸¸ ÀÐ½À´Ï´Ù.
    identity := SSOK_Expense_MSAA_Identity({acc:acc, child:0})
    if (identity != "")
    {
        if (state.seen.HasKey(identity))
        {
            state.duplicates++
            return
        }
        state.seen[identity] := acc
    }
    state.nodes++
    status := SSOK_Expense_MSAA_Get(acc, "State", 0)
    if (status != "" && (status & 0x8000))
        return
    name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", 0))
    state.mask |= SSOK_Expense_MSAA_ItemHeaderBit(name)
    if (name = "¼±ÅÃ")
        state.selects++
    for _, child in SSOK_Expense_MSAA_GetChildren(acc)
    {
        if (state.stopped)
            return
        if (child.kind = 2)
            SSOK_Expense_ScanItemRows(child.acc, depth + 1, state)
        else
        {
            state.nodes++
            if (state.nodes >= 10000 || A_TickCount > state.deadline || !SSOK_Expense_Active(state.target))
            {
                state.stopped := true
                return
            }
            name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", child.id))
            state.mask |= SSOK_Expense_MSAA_ItemHeaderBit(name)
            if (name = "¼±ÅÃ")
                state.selects++
        }
    }
}

; ============================================================
; Win+2 ½º¸¶Æ® ¿øÀÎÇàÀ§ ¼³Á¤ Áö¿ø
; ------------------------------------------------------------
; ±âÁ¸ Tab È½¼ö ¹æ½Ä ´ë½Å K-¿¡µàÆÄÀÎ MSAA È­¸éÀ» ½ÇÁ¦·Î ÀÐ¾î Ã³¸®ÇÕ´Ï´Ù.
; - °Ë¼ö¿©ºÎ      -> ¾Æ´Ï¿À
; - ÀüÀÚÁ¶´Þ±¸¸Å  -> ÀÚÃ¼
; - ÃÑ¿øÀÎÇàÀ§¾×À» ÀÐ¾î °³¿äÀÇ ±âÁ¸ ¼Ò¿ä¿¹»ê ±Ý¾×À» ±³Ã¼
;
; ÀÌ ÆÄÀÏ »ó´ÜÀÇ #2:: ÇÖÅ°°¡ ¾Æ·¡ ÇÔ¼ö¸¦ Á÷Á¢ È£ÃâÇÕ´Ï´Ù.
; Win+2´Â ¿ÜºÎ ¿¬°á ¾øÀÌ ÀÌ ÆÄÀÏ ³»ºÎ¿¡¼­ ¹Ù·Î ½ÇÇàµË´Ï´Ù.
; ============================================================

SSOK_Expense_Win2Smart()
{
    global SSOK_ExpenseCancel

    KeyWait, LWin
    KeyWait, RWin
    SendInput, {LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}
    SSOK_ExpenseCancel := false
    Sleep, 80

    ; 1. ÇöÀç È°¼ºÈ­µÈ K-¿¡µàÆÄÀÎ È­¸éÀ» MSAA·Î ÀÐÀ½
    target := WinExist("A")
    if (!target)
        return false

    root := SSOK_Expense_MSAA_GetEdufineRoot(target, true)
    if !IsObject(root)
    {
        MsgBox, 0x40030, °£Æí ¿øÀÎÇàÀ§ Win+2, K-¿¡µàÆÄÀÎ È­¸éÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.`n¿øÀÎÇàÀ§ µî·Ï È­¸éÀ» ¸Ç ¾ÕÀ¸·Î ¿¬ µÚ ´Ù½Ã Win+2¸¦ ´­·¯ ÁÖ¼¼¿ä.
        return false
    }

    ToolTip, Win+2 È­¸é È®ÀÎ Áß...`n°Ë¼ö¿©ºÎ / ÀüÀÚÁ¶´Þ±¸¸Å
    scan := SSOK_Expense_Win2_Scan(root, target)

    if (!IsObject(scan) || scan.stopped)
    {
        ToolTip
        reasonText := scan.reason = "timeout" ? "È­¸é Å½»ö ½Ã°£ ÃÊ°ú(30ÃÊ)" : scan.reason = "inactive-or-cancelled" ? "È­¸é ÀüÈ¯ ¶Ç´Â Ãë¼Ò" : scan.reason
        MsgBox, 0x40030, °£Æí ¿øÀÎÇàÀ§ Win+2, % "Win+2 È­¸é Å½»ö Áß´Ü [°³¼± v3]`n»çÀ¯: " . reasonText . "`nÀÐÀº Ç×¸ñ: " . scan.nodes . " / Áßº¹ Á¦¿Ü: " . scan.duplicates
        return false
    }

    ; 2. °Ë¼ö¿©ºÎ -> ¾Æ´Ï¿À
    okInspect := SSOK_Expense_Win2_SetInspectionNo(target, scan.items)
    Sleep, 150

    ; 3. ÀüÀÚÁ¶´Þ±¸¸Å -> ÀÚÃ¼
    ; ÄÞº¸ Á¶ÀÛ °úÁ¤¿¡¼­ MSAA Æ®¸®°¡ ¹Ù²ð ¼ö ÀÖÀ¸¹Ç·Î ±âÁ¸ ÇÔ¼ö ³»ºÎ ÀçÅ½»ö »ç¿ë
    okProcure := SSOK_Expense_Win2_SetProcurementOwn(target, scan.items)
    Sleep, 180

    ; 4. º¯°æµÈ È­¸éÀ» ´Ù½Ã MSAA·Î ÀÐ°í "ÃÑ¿øÀÎÇàÀ§¾×" ±Ý¾×À» Ã£À½
    totalCauseAmount := ""
    root2 := SSOK_Expense_MSAA_GetEdufineRoot(target, true)

    if IsObject(root2)
    {
        scan2 := SSOK_Expense_Win2_Scan(root2, target)

        if (IsObject(scan2) && !scan2.stopped)
            totalCauseAmount := SSOK_Expense_Win2_ReadTotalCauseAmount(scan2.items)
    }

    ; 5. °³¿ä¿¡ »çÀü ÀÔ·ÂµÇ¾î ÀÖ´Â ¼Ò¿ä¿¹»ê ±Ý¾×À» ÃÑ¿øÀÎÇàÀ§¾×À¸·Î ±³Ã¼
    okOverviewAmount := false

    if (totalCauseAmount != "")
        okOverviewAmount := SSOK_Expense_Win2_ReplaceOverviewAmount(target, totalCauseAmount)

    ToolTip

    ; °è¾à¼³Á¤Àº ÆË¾÷À» ¿­ ¼ö ÀÖÀ¸¹Ç·Î °³¿ä °»½Å ÈÄ ¸¶Áö¸·¿¡ ½ÇÇàÇÕ´Ï´Ù.
    okContract := SSOK_Expense_Win2_OpenContract(target)

    ; 6. Ã³¸® °á°ú¸¦ ¾à 3ÃÊ Ç¥½Ã
    msg := "Win+2 Ã³¸® °á°ú"
    msg .= "`n°Ë¼ö¿©ºÎ ¡æ ¾Æ´Ï¿À: " . (okInspect ? "¿Ï·á" : "È®ÀÎ ÇÊ¿ä")
    msg .= "`nÀüÀÚÁ¶´Þ±¸¸Å ¡æ ÀÚÃ¼: " . (okProcure ? "¿Ï·á" : "È®ÀÎ ÇÊ¿ä")
    msg .= "`n°è¾à¼³Á¤ Å¬¸¯: " . (okContract ? "½ÇÇà" : "È®ÀÎ ÇÊ¿ä")

    if (totalCauseAmount = "")
    {
        msg .= "`nÃÑ¿øÀÎÇàÀ§¾× ¡æ ±Ý¾×À» Ã£Áö ¸øÇÔ / È®ÀÎ ÇÊ¿ä"
    }
    else
    {
        msg .= "`nÃÑ¿øÀÎÇàÀ§¾× ¡æ " . SSOK_Expense_FormatNumber(totalCauseAmount) . "¿ø"
        msg .= " / °³¿ä ±Ý¾× ÀÔ·Â: " . (okOverviewAmount ? "¿Ï·á" : "È®ÀÎ ÇÊ¿ä")
    }

    ToolTip, %msg%
    SetTimer, SSOKExpenseClearTip, -3000

    SSOK_Expense_Log("win2-total-cause inspect=" . (okInspect ? 1 : 0)
        . " procure=" . (okProcure ? 1 : 0)
        . " totalCauseFound=" . (totalCauseAmount != "" ? 1 : 0)
        . " overviewAmountSet=" . (okOverviewAmount ? 1 : 0))

    return okInspect || okProcure || okOverviewAmount || okContract
}

; ------------------------------------------------------------
; È­¸éÀÇ "ÃÑ¿øÀÎÇàÀ§¾×"À» MSAA¿¡¼­ Ã£¾Æ ¼ýÀÚ¸¸ ¹ÝÈ¯
; °°Àº °´Ã¼ÀÇ Value/NameÀ» ¸ÕÀú º¸°í, ¾øÀ¸¸é °°Àº Çà ¿À¸¥ÂÊ °ªÀ» Ã£½À´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_Win2_ReadTotalCauseAmount(items)
{
    labels := []
    direct := ""
    for _, node in items
    {
        n := SSOK_Expense_Win2_Normalize(node.name)
        if (!RegExMatch(n, "^(ÃÑ¿øÀÎÇàÀ§¾×|¿øÀÎÇàÀ§ÃÑ¾×)(\(¿ø\))?$"))
            continue
        labels.Push(node)
        value := SSOK_Expense_StrictAmount(node.value)
        if (value != "")
        {
            if (direct != "" && direct != value)
                return ""
            direct := value
        }
    }
    if (direct != "")
        return direct
    if (labels.Length() != 1 || !IsObject(labels[1].rect))
        return ""
    label := labels[1].rect
    best := ""
    bestGap := 100000
    for _, node in items
    {
        if (!IsObject(node.rect))
            continue
        r := node.rect
        ; °°Àº ÁÙ¿¡¼­ ¶óº§ ¹Ù·Î ¿À¸¥ÂÊ °ª¸¸ Çã¿ëÇÕ´Ï´Ù. ³¯Â¥/¹®Àå ¼ýÀÚ´Â Á¦¿ÜÇÕ´Ï´Ù.
        gap := r.x - (label.x + label.w)
        if (Abs(r.cy - label.cy) > 8 || gap < -2 || gap > 120)
            continue
        value := SSOK_Expense_StrictAmount(node.value)
        if (value = "")
            value := SSOK_Expense_StrictAmount(node.name)
        if (value = "")
            continue
        if (gap < bestGap)
        {
            bestGap := gap
            best := value
        }
        else if (gap = bestGap && best != value)
            return ""
    }
    return best
}

SSOK_Expense_StrictAmount(text)
{
    text := Trim(text, " `t`r`n" . Chr(160))
    if (!RegExMatch(text, "^([0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)\s*¿ø?$", m))
        return ""
    return StrReplace(m1, ",") + 0
}

SSOK_Expense_Win2_ExtractNumericAmount(text)
{
    if (text = "")
        return ""

    ; 1,234,567¿ø / 1,234,567 / 1234567 ¸ðµÎ Çã¿ë
    if RegExMatch(text, "([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{4,})\s*¿ø?", m)
        return RegExReplace(m1, "[^0-9]", "")

    ; ¼Ò¾×µµ Çã¿ëÇÏµÇ 0Àº Á¦¿Ü
    if RegExMatch(text, "(?:^|[^0-9])([1-9][0-9]{0,2})\s*¿ø(?:$|[^0-9])", m)
        return m1 + 0

    return ""
}

; ------------------------------------------------------------
; °³¿äÀÇ »çÀüÀÔ·ÂµÈ "¼Ò¿ä¿¹»ê" ±Ý¾× ºÎºÐ¸¸ ÃÑ¿øÀÎÇàÀ§¾×À¸·Î ±³Ã¼
; °³¿äÀÇ ³ª¸ÓÁö ¹®±¸´Â ±×´ë·Î À¯ÁöÇÕ´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_Win2_ReplaceOverviewAmount(target, amount)
{
    if (amount = "" || amount <= 0 || !WinActive("ahk_id " . target))
        return false

    field := SSOK_Expense_MSAA_ResolveField(target, "overview")
    if !IsObject(field)
        return false

    currentText := SSOK_Expense_MSAA_Get(field.acc, "Value", field.child)

    if (currentText = "")
        currentText := SSOK_Expense_MSAA_Get(field.acc, "Name", field.child)

    if (currentText = "" || !InStr(currentText, "¼Ò¿ä¿¹»ê"))
        return false

    amountNumber := SSOK_Expense_FormatNumber(amount)
    amountKorean := SSOK_Expense_NumberToKorean(amount)
    newAmountText := "±Ý" . amountNumber . "¿ø(±Ý" . amountKorean . "¿ø)"

    ; ±âÁ¸:
    ;   ³ª. ¼Ò¿ä¿¹»ê: ±Ý935,000¿ø(±Ý±¸½Ê»ï¸¸¿ÀÃµ¿ø)
    ; ±Ý¾× ºÎºÐ¸¸ ±³Ã¼ÇÏ°í ¾ÕµÚ ¹®±¸´Â ±×´ë·Î µÓ´Ï´Ù.
    pattern := "(¼Ò¿ä¿¹»ê\s*:\s*)±Ý?\s*[0-9][0-9,]*\s*¿ø(?:\s*\(±Ý[^)\r\n]*¿ø\))?"
    replacement := "$1" . newAmountText
    changedText := RegExReplace(currentText, pattern, replacement, replacedCount, 1)

    ; È­¸é ¹®±¸°¡ Á¶±Ý ´Ù¸¥ °æ¿ì: ¼Ò¿ä¿¹»ê: µÚÀÇ ÇÑ ÁÙ¸¸ ±³Ã¼
    if (replacedCount = 0)
    {
        pattern2 := "(¼Ò¿ä¿¹»ê\s*:\s*)[^\r\n]*"
        changedText := RegExReplace(currentText, pattern2, "$1" . newAmountText, replacedCount, 1)
    }

    if (replacedCount = 0 || changedText = currentText)
        return false

    if (!SSOK_Expense_MSAA_FocusField(field, target))
        return false

    saved := ClipboardAll

    try
    {
        Clipboard := ""
        Clipboard := changedText
        ClipWait, 0.5

        if (ErrorLevel || !WinActive("ahk_id " . target))
            return false

        SendInput, ^a
        Sleep, 25
        SendInput, ^v
        Sleep, 130
        SendInput, {Tab}
        Sleep, 100

        if (!WinActive("ahk_id " . target))
            return false

        ; °¡´ÉÇÑ °æ¿ì ½ÇÁ¦ ¹Ý¿µ°ª±îÁö È®ÀÎ
        verify := SSOK_Expense_MSAA_Get(field.acc, "Value", field.child)

        if (verify = "")
            return true

        return InStr(verify, amountNumber) || InStr(RegExReplace(verify, "[^0-9]", ""), amount . "")
    }
    finally
    {
        Clipboard := saved
        saved := ""
    }
}


SSOK_Expense_Win2_OpenContract(target)
{
    if (!SSOK_Expense_Active(target))
        return false
    root := SSOK_Expense_MSAA_GetEdufineRoot(target, true)
    if (!IsObject(root))
        return false
    scan := SSOK_Expense_Win2_Scan(root, target)
    if (scan.stopped)
        return false
    hits := SSOK_Expense_Win2_FindExact(scan.items, ["°è¾à¼³Á¤"], "43")
    if (hits.Length() != 1)
        return false
    ; Æ÷Ä¿½º¸¸ ¿Å±â´Â µ¿ÀÛÀ» Å¬¸¯ ¼º°øÀ¸·Î Ã³¸®ÇÏÁö ¾Ê½À´Ï´Ù.
    try
    {
        hits[1].acc.accDoDefaultAction(hits[1].child)
        SSOK_Expense_Log("win2-contract-action")
        return true
    }
    catch
        return false
}
SSOK_Expense_Win2_Scan(root, target, overviewOnly := false)
{
    state := {overviewOnly:overviewOnly, items:[], seen:{}, duplicates:0, nodes:0, limit:40000, deadline:A_TickCount + 30000, target:target, stopped:false}
    started := A_TickCount
    SSOK_Expense_Win2_Walk(root, 0, state)
    SSOK_Expense_Log("win2-scan-v3 duplicates=" . state.duplicates . " nodes=" . state.nodes . " items=" . state.items.Length() . " stopped=" . state.stopped . " reason=" . state.reason . " elapsedMs=" . (A_TickCount - started))
    return state
}

SSOK_Expense_Win2_Walk(acc, depth, state)
{
    if (state.stopped)
        return
    if (depth > 160 || state.nodes >= state.limit || A_TickCount > state.deadline
        || !SSOK_Expense_Active(state.target))
    {
        state.reason := depth > 160 ? "depth" : state.nodes >= state.limit ? "node-limit" : A_TickCount > state.deadline ? "timeout" : "inactive-or-cancelled"
        state.stopped := true
        return
    }

    ; °°Àº COM °´Ã¼°¡ ¿©·¯ °æ·Î·Î ³ëÃâµÇ¾îµµ ÇÑ ¹ø¸¸ ÀÐ½À´Ï´Ù.
    identity := SSOK_Expense_MSAA_Identity({acc:acc, child:0})
    if (identity != "")
    {
        if (state.seen.HasKey(identity))
        {
            state.duplicates++
            return
        }
        state.seen[identity] := acc
    }
    state.nodes++
    status := SSOK_Expense_MSAA_Get(acc, "State", 0)
    ; ·çÆ® ¾Æ·¡ ¼û±è/È­¸é ¹Û ºÐ±â´Â ÇöÀç Ç¥½ÃµÈ Ç×¸ñ Å½»ö¿¡¼­ Á¦¿ÜÇÕ´Ï´Ù.
    if (status != "" && ((status & 0x8000) || (depth > 0 && (status & 0x10000))))
        return

    SSOK_Expense_Win2_Record(acc, 0, state, status)
    children := SSOK_Expense_MSAA_GetChildren(acc)
    if !IsObject(children)
        return

    for _, item in children
    {
        if (state.stopped)
            return

        if (item.kind = 2)
            SSOK_Expense_Win2_Walk(item.acc, depth + 1, state)
        else
        {
            state.nodes++
            if (state.nodes >= state.limit || A_TickCount > state.deadline
                || !SSOK_Expense_Active(state.target))
            {
                state.reason := state.nodes >= state.limit ? "node-limit" : A_TickCount > state.deadline ? "timeout" : "inactive-or-cancelled"
                state.stopped := true
                return
            }
            SSOK_Expense_Win2_Record(acc, item.id, state)
        }
    }
}

SSOK_Expense_Win2_Record(acc, child, state, status := "")
{
    role := SSOK_Expense_MSAA_Get(acc, "Role", child)
    ; ±¸Á¶¿ë ÄÁÅ×ÀÌ³ÊÀÇ ÀÌ¸§/°ª/ÁÂÇ¥´Â ÀÔ·Â Ç×¸ñ ¸ÅÄª¿¡ »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    if (InStr(",9,10,15,16,18,20,24,25,26,", "," . role . ","))
        return
    name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", child))
    value := Trim(SSOK_Expense_MSAA_Get(acc, "Value", child))
    if (status = "")
        status := SSOK_Expense_MSAA_Get(acc, "State", child)
    if (status != "" && (status & 0x8000))
        return

    ; ÅØ½ºÆ®°¡ ¾ø´Â ÀÔ·Â/ÄÞº¸/¶óµð¿Àµµ ¶óº§ ±ÙÁ¢ Å½»ö¿¡ ÇÊ¿äÇÕ´Ï´Ù.
    if (name = "" && value = "" && role != 42 && role != 43 && role != 44 && role != 45 && role != 46)
        return

    ; Win+3Àº ÃÑ¾×/°³¿ä ÈÄº¸¿¡¸¸ ÁÂÇ¥¸¦ ¿äÃ»ÇÕ´Ï´Ù.
    ; ÀüÃ¼ ÄÁÆ®·ÑÀÇ accLocation È£ÃâÀ» ÇÇÇÏµÇ Å½»ö ÀÚÃ¼´Â ³¡±îÁö ¼öÇàÇÕ´Ï´Ù.
    if (state.overviewOnly)
    {
        n := SSOK_Expense_Win2_Normalize(name)
        relevant := RegExMatch(n, "^(ÃÑ¿øÀÎÇàÀ§¾×|¿øÀÎÇàÀ§ÃÑ¾×)(\(¿ø\))?$")
            || (role = 42 && RegExMatch(value, "¼Ò¿ä¿¹»ê\s*[:£º]"))
            || SSOK_Expense_StrictAmount(value) != "" || SSOK_Expense_StrictAmount(name) != ""
        if (!relevant)
            return
    }
    rect := SSOK_Expense_Win2_GetRect(acc, child)
    state.items.Push({acc:acc, child:child, name:name, value:value, role:role, state:status, rect:rect})
}

SSOK_Expense_Win2_GetRect(acc, child)
{
    try
    {
        VarSetCapacity(x, 4, 0), VarSetCapacity(y, 4, 0)
        VarSetCapacity(w, 4, 0), VarSetCapacity(h, 4, 0)
        acc.accLocation(ComObj(0x4003, &x), ComObj(0x4003, &y)
            , ComObj(0x4003, &w), ComObj(0x4003, &h), child)
        x := NumGet(x, 0, "Int"), y := NumGet(y, 0, "Int")
        w := NumGet(w, 0, "Int"), h := NumGet(h, 0, "Int")
        if (w > 0 && h > 0)
            return {x:x, y:y, w:w, h:h, cx:x + w/2, cy:y + h/2}
    }
    return ""
}

SSOK_Expense_Win2_Normalize(text)
{
    text := Trim(text)
    text := RegExReplace(text, "[\s\x{00A0}:£º*¡¤]", "")
    return text
}

SSOK_Expense_Win2_FindExact(items, names, roles := "")
{
    out := []
    for _, node in items
    {
        n := SSOK_Expense_Win2_Normalize(node.name)
        v := SSOK_Expense_Win2_Normalize(node.value)
        matched := false
        for _, wanted in names
        {
            wantedN := SSOK_Expense_Win2_Normalize(wanted)
            if (n = wantedN || v = wantedN)
            {
                matched := true
                break
            }
        }
        if (!matched)
            continue
        if (roles != "" && !InStr("," . roles . ",", "," . node.role . ","))
            continue
        out.Push(node)
    }
    return out
}

SSOK_Expense_Win2_FindLabel(items, names)
{
    hits := SSOK_Expense_Win2_FindExact(items, names)
    if (!hits.Length())
        return ""

    ; È­¸é¿¡ ½ÇÁ¦ À§Ä¡°¡ ÀÖ´Â ÅØ½ºÆ® ¶óº§À» ¿ì¼±ÇÕ´Ï´Ù.
    for _, node in hits
    {
        if (IsObject(node.rect) && node.role = 42)
            return node
    }
    for _, node in hits
    {
        if IsObject(node.rect)
            return node
    }
    return hits[1]
}

SSOK_Expense_Win2_FindNear(items, anchor, roles, exactNames := "", maxY := 95)
{
    if (!IsObject(anchor) || !IsObject(anchor.rect))
        return ""

    best := ""
    bestScore := 2147483647
    for _, node in items
    {
        if (!IsObject(node.rect))
            continue
        if (roles != "" && !InStr("," . roles . ",", "," . node.role . ","))
            continue

        if IsObject(exactNames)
        {
            n := SSOK_Expense_Win2_Normalize(node.name)
            v := SSOK_Expense_Win2_Normalize(node.value)
            nameOk := false
            for _, wanted in exactNames
            {
                wantedN := SSOK_Expense_Win2_Normalize(wanted)
                if (n = wantedN || v = wantedN)
                {
                    nameOk := true
                    break
                }
            }
            if (!nameOk)
                continue
        }

        dy := Abs(node.rect.cy - anchor.rect.cy)
        if (dy > maxY)
            continue

        ; °°Àº Çà¿¡¼­ ¶óº§ ¿À¸¥ÂÊÀÇ ÄÁÆ®·ÑÀ» °¡Àå ¿ì¼±ÇÕ´Ï´Ù.
        dx := node.rect.cx - anchor.rect.cx
        if (dx < -60)
            continue
        score := dy * 12 + Abs(dx - 150)
        if (score < bestScore)
        {
            bestScore := score
            best := node
        }
    }
    return best
}

SSOK_Expense_Win2_ActivateNode(node, target)
{
    if (!IsObject(node) || !WinActive("ahk_id " . target))
        return false

    try
    {
        node.acc.accDoDefaultAction(node.child)
        Sleep, 120
        return WinActive("ahk_id " . target)
    }
    catch
    {
    }

    try
    {
        ; TAKEFOCUS(1) + TAKESELECTION(2)
        node.acc.accSelect(3, node.child)
        Sleep, 100
        return WinActive("ahk_id " . target)
    }
    catch
    {
        return false
    }
}

SSOK_Expense_Win2_SetInspectionNo(target, items)
{
    label := SSOK_Expense_Win2_FindLabel(items, ["°Ë¼ö¿©ºÎ", "°Ë¼ö ¿©ºÎ"])
    noNode := ""

    if IsObject(label)
        noNode := SSOK_Expense_Win2_FindNear(items, label, "45,44,43,42", ["¾Æ´Ï¿À", "¾Æ´Ï¿ä"], 80)

    if !IsObject(noNode)
    {
        hits := SSOK_Expense_Win2_FindExact(items, ["¾Æ´Ï¿À", "¾Æ´Ï¿ä"], "45,44,43")
        if (hits.Length() = 1)
            noNode := hits[1]
    }

    if !IsObject(noNode)
        return false

    ; MSAA checked »óÅÂ(0x10)ÀÌ¸é ÀÌ¹Ì ¾Æ´Ï¿À°¡ ¼±ÅÃµÈ »óÅÂÀÔ´Ï´Ù.
    if (noNode.state != "" && (noNode.state & 0x10))
        return true

    return SSOK_Expense_Win2_ActivateNode(noNode, target)
}

SSOK_Expense_Win2_SelectOwnKeys(target)
{
    if (!SSOK_Expense_Active(target))
        return false
    SendInput, !{Down}
    Sleep, 150
    if (!SSOK_Expense_Active(target))
        return false
    SendInput, {Home}
    Sleep, 80
    Loop, 4
    {
        if (!SSOK_Expense_Active(target))
            return false
        SendInput, {Down}
        Sleep, 80
    }
    if (!SSOK_Expense_Active(target))
        return false
    SendInput, {Enter}
    Sleep, 180
    return SSOK_Expense_Active(target)
}
SSOK_Expense_Win2_SetProcurementOwn(target, items)
{
    labelNames := ["ÀüÀÚÁ¶´Þ±¸¸Å", "ÀüÀÚµµ´Þ±¸¸Å"]
    label := SSOK_Expense_Win2_FindLabel(items, labelNames)
    combo := ""

    ; ¶óº§ ÀÚÃ¼°¡ ComboBox·Î ³ëÃâµÇ´Â °æ¿ì
    hits := SSOK_Expense_Win2_FindExact(items, labelNames, "46")
    if (hits.Length())
        combo := hits[1]

    ; ¶óº§°ú º°µµÀÇ ComboBoxÀÎ °æ¿ì
    if (!IsObject(combo) && IsObject(label))
        combo := SSOK_Expense_Win2_FindNear(items, label, "46", "", 90)

    ; ÀÏºÎ Nexacro È­¸éÀº ComboBox¸¦ editable text(role 42)·Î ³ëÃâÇÕ´Ï´Ù.
    if (!IsObject(combo) && IsObject(label))
    {
        candidate := SSOK_Expense_Win2_FindNear(items, label, "42", "", 90)
        if (IsObject(candidate) && SSOK_Expense_Win2_Normalize(candidate.name) != SSOK_Expense_Win2_Normalize(label.name))
            combo := candidate
    }

    if !IsObject(combo)
        return false

    if (SSOK_Expense_Win2_Normalize(combo.value) = "ÀÚÃ¼"
        || SSOK_Expense_Win2_Normalize(combo.name) = "ÀÚÃ¼")
        return true

    ; ¸ñ·Ï: ¼±ÅÃ / G2B(Áß¾ÓÁ¶´Þ) / S2B / eaT / ÀÚÃ¼ / G2B(ÀÚÃ¼Á¶´Þ)
    ; ±âº»µ¿ÀÛÀÌ Æ÷Ä¿½º¸¸ ¿Å±â´Â Nexacro ÄÞº¸µµ ¸í½ÃÀûÀ¸·Î ÆîÄ¨´Ï´Ù.
    if (!SSOK_Expense_MSAA_FocusField(combo, target))
    {
        SSOK_Expense_Log("win2-procurement-focus-failed")
        return false
    }
    if (!SSOK_Expense_Win2_SelectOwnKeys(target))
        return false
    ; Å° Àü¼Û ¼º°ø¸¸À¸·Î ¿Ï·á·Î º¸°íÇÏÁö ¾Ê½À´Ï´Ù.
    Loop, 4
    {
        if (!SSOK_Expense_Active(target))
            return false
        current := SSOK_Expense_MSAA_Get(combo.acc, "Value", combo.child)
        if (SSOK_Expense_Win2_Normalize(current) = "ÀÚÃ¼")
        {
            SSOK_Expense_Log("win2-procurement-own-verified")
            return true
        }
        Sleep, 150
    }
    SSOK_Expense_Log("win2-procurement-selection-not-verified")
    return false
}

SSOK_Expense_Win2_ReadOverviewAmount(target, items := "")
{
    ; Win+1¿¡¼­ ÀÌ¹Ì °ËÁõÇÑ °³¿ä ÇÊµå Å½»ö ·ÎÁ÷À» ¿ì¼± Àç»ç¿ëÇÕ´Ï´Ù.
    field := SSOK_Expense_MSAA_ResolveField(target, "overview")
    if IsObject(field)
    {
        text := SSOK_Expense_MSAA_Get(field.acc, "Value", field.child)
        if (text = "")
            text := SSOK_Expense_MSAA_Get(field.acc, "Name", field.child)
        amount := SSOK_Expense_Win2_ExtractAmount(text)
        if (amount != "")
            return amount
    }

    ; °³¿ä ÇÊµå ÀÌ¸§ÀÌ ¼¼¼Ç¿¡ µû¶ó ´Ù¸£°Ô ³ëÃâµÇ´Â °æ¿ì ÀüÃ¼ Ç¥½Ã ÅØ½ºÆ®¿¡¼­ º¸Á¶ Å½»öÇÕ´Ï´Ù.
    if IsObject(items)
    {
        for _, node in items
        {
            text := node.value != "" ? node.value : node.name
            if (!InStr(text, "¼Ò¿ä¿¹»ê") && !InStr(text, "±Ý¾×"))
                continue
            amount := SSOK_Expense_Win2_ExtractAmount(text)
            if (amount != "")
                return amount
        }
    }
    return ""
}

SSOK_Expense_Win2_ExtractAmount(text)
{
    if (text = "")
        return ""

    if RegExMatch(text, "¼Ò¿ä¿¹»ê\s*[:£º]?\s*±Ý?\s*([0-9][0-9,]*)\s*¿ø", m)
        return RegExReplace(m1, "[^0-9]", "")

    if RegExMatch(text, "±Ý¾×\s*[:£º]?\s*±Ý?\s*([0-9][0-9,]*)\s*¿ø", m)
        return RegExReplace(m1, "[^0-9]", "")

    ; °³¿ä ¾È¿¡ ±Ý¾× Ç¥±â°¡ ÇÏ³ª»ÓÀÎ °æ¿ì¸¦ À§ÇÑ ÃÖÁ¾ º¸Á¶ ÆÐÅÏ
    if RegExMatch(text, "±Ý\s*([0-9][0-9,]*)\s*¿ø", m)
        return RegExReplace(m1, "[^0-9]", "")

    return ""
}

SSOK_Expense_Win2_SetCauseAmount(target, items, amount)
{
    label := SSOK_Expense_Win2_FindLabel(items, ["¿øÀÎÇàÀ§¾×", "¿øÀÎ ÇàÀ§¾×"])
    field := ""

    ; ¿øÀÎÇàÀ§¾×ÀÌ¶ó´Â ÀÌ¸§ ÀÚÃ¼¸¦ °¡Áø ÆíÁý ÄÁÆ®·ÑÀ» ¸ÕÀú Ã£½À´Ï´Ù.
    for _, node in items
    {
        n := SSOK_Expense_Win2_Normalize(node.name)
        if (!RegExMatch(n, "^¿øÀÎÇàÀ§¾×(ÀÔ·Â)?$") || node.role != 42)
            continue
        if (SSOK_Expense_MSAA_Usable(node.acc, node.child, true))
        {
            field := node
            break
        }
    }

    ; ¶óº§ ¿À¸¥ÂÊÀÇ ÆíÁý °¡´ÉÇÑ ÀÔ·ÂÄ­À» Ã£½À´Ï´Ù.
    if (!IsObject(field) && IsObject(label))
    {
        near := SSOK_Expense_Win2_FindNear(items, label, "42", "", 80)
        if (IsObject(near) && SSOK_Expense_MSAA_Usable(near.acc, near.child, true))
            field := near
    }

    if !IsObject(field)
        return false
    if (!SSOK_Expense_MSAA_FocusField(field, target))
        return false

    saved := ClipboardAll
    try
    {
        Clipboard := ""
        Clipboard := amount
        ClipWait, 0.5
        if (ErrorLevel || !WinActive("ahk_id " . target))
            return false
        SendInput, ^a
        Sleep, 30
        SendInput, ^v
        Sleep, 130
        SendInput, {Tab}
        Sleep, 100
        return WinActive("ahk_id " . target)
    }
    finally
    {
        Clipboard := saved
        saved := ""
    }
}

; =========================================================
; Win + 1 / Win + 3 K-¿¡µàÆÄÀÎ º¸Á¶ ½ÇÇà ·çÆ¾
; - ±âÁ¸ ssok_tool.ahk¿¡ ÀÖ´ø ±â´ÉÀ» ±×´ë·Î ÀÌµ¿
; - Win+1 / Win+2 / Win+3 °ü·Ã ±â´ÉÀ» expense ¸ðµâ¿¡¼­ ÀÏ°ý °ü¸®
; =========================================================
; =========================================================
; Win + 4 : K-¿¡µàÆÄÀÎ »ç¿ëÀÚ ÁöÁ¤ Tab ¼ø¼­ ½ÇÇà
; ---------------------------------------------------------
; ¼ø¼­: Tab 12 ¡æ Left 1 ¡æ Tab 7 ¡æ Space ¡æ Tab 1 ¡æ Space ¡æ Tab 16 ¡æ Down 1
; =========================================================
#If SSOK_Expense_HotkeyContext()
#3::
    KeyWait, LWin
    KeyWait, RWin
    SSOK_Expense_Win3Overview()
return

#4::
    Gosub, SSOK_Expense_DoWin4_KEdufine_TabSeq
return
#If

SSOK_Expense_HotkeyContext()
{
    return true
}


; =========================================================
; =========================================================
; ¿øÀÎÇàÀ§À¯Çü¼±ÅÃ È®ÀÎ ÈÄ Win+2 µÞºÎºÐ ÀÚµ¿ ½ÇÇà
; ---------------------------------------------------------
; ÇöÀç ºñÈ°¼ºÈ­: SSOK_EnableCauseTypeAutoAfter := 1 ·Î ÄÑ±â Àü±îÁö ½ÇÇàµÇÁö ¾Ê½À´Ï´Ù.
; UIA/¸¶¿ì½º À§Ä¡ ÆÇµ¶Àº »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
; º°µµ ¼±ÅÃÃ¢ Á¦¸ñÀÌ ÀâÈ÷´Â °æ¿ì¿¡¸¸, ¼±ÅÃ ÈÄ Ã¢ÀÌ ´ÝÈ÷¸é Space ¾øÀÌ Tab 10ºÎÅÍ ½ÇÇà
; =========================================================
; ¿øÀÎÇàÀ§À¯Çü¼±ÅÃ ÈÄ Enter/LButton ÀÚµ¿°¨½Ã´Â ÇöÀç ºñÈ°¼ºÈ­ »óÅÂÀÌ¹Ç·Î
; ´Ù¸¥ ¸ðµâÀÇ µ¿ÀÏ ÇÖÅ°¿Í Ãæµ¹ÇÏÁö ¾Êµµ·Ï ÇÖÅ° µî·ÏÀº ÇÏÁö ¾Ê½À´Ï´Ù.
SSOK_Expense_Win1_AutoAfterTypeConfirm_Start:
    if (SSOK_Expense_Win1_AutoAfterTypeConfirmPending)
        return
    WinGet, SSOK_Expense_Win1_AutoCauseHwnd, ID, A
    if (SSOK_Expense_Win1_AutoCauseHwnd = "")
        return
    SSOK_Expense_Win1_AutoAfterTypeConfirmPending := 1
    SetTimer, SSOK_Expense_Win1_AutoAfterTypeConfirm_Run, -80
return

SSOK_Expense_Win1_AutoAfterTypeConfirm_Run:
    WinWaitClose, ahk_id %SSOK_Expense_Win1_AutoCauseHwnd%,, 5
    if (ErrorLevel)
    {
        SSOK_Expense_Win1_AutoAfterTypeConfirmPending := 0
        return
    }
    Sleep, 900
    Gosub, SSOK_Expense_DoWin1_KEdufine_TabSeq_AfterTypeConfirm
    SSOK_Expense_Win1_AutoAfterTypeConfirmPending := 0
return

SSOK_Expense_DoWin4_KEdufine_TabSeq:
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

SSOK_Expense_DoWin1_KEdufine_TabSeq_10_1_4:
    KeyWait, LWin
    KeyWait, RWin
    SendInput, {LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}
    SetKeyDelay, 80, 40
    Sleep, 150

    ToolTip, Win+1 K-¿¡µàÆÄÀÎ »ç¿ëÀÚ ÁöÁ¤ Tab ¼ø¼­ ½ÇÇà Áß...
    SetTimer, SSOK_Expense_Win1_TabSeq_ClearTip, -2500

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

SSOK_Expense_DoWin1_KEdufine_TabSeq_AfterTypeConfirm:
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

SSOK_Expense_IsCauseTypeWindowActive()
{
    WinGetTitle, SSOK_CauseTypeTitle, A
    return InStr(SSOK_CauseTypeTitle, "¿øÀÎÇàÀ§À¯Çü¼±ÅÃ")
}

SSOK_Expense_Win1_TabSeq_ClearTip:
    ToolTip
return


SSOK_Expense_Win3AmountText(text, amount)
{
    ; Win+3¿¡¼­´Â ¼ýÀÚ ÃÑ±Ý¾×¸¸ ¹Ù²Ù°í, ÇÑ±Û ±Ý¾× ÀÛ¼ºÀº ¸¶Áö¸· Win+F2¿¡ ¸Ã±é´Ï´Ù.
    replacement := "±Ý" . SSOK_Expense_FormatNumber(amount) . "¿ø"

    ; Win+F2ÀÇ ±Ý¾× ÀÎ½Ä ¿ë¾î¸¦ ±âÁØÀ¸·Î ÃÑ±Ý¾× ¼º°ÝÀÇ Ç×¸ñ¸¸ ±³Ã¼ÇÕ´Ï´Ù.
    ; ´Ü°¡/°³´ç ±Ý¾×Àº ´ë»ó¿¡ Æ÷ÇÔÇÏÁö ¾Ê½À´Ï´Ù.
    labels := "ÃÑ[ `t]*¼Ò¿ä[ `t]*¿¹»ê[ `t]*¾×|ÃÑ[ `t]*¼Ò¿ä[ `t]*¿¹»ê[ `t]*±Ý¾×|ÃÑ[ `t]*¼Ò¿ä[ `t]*¿¹»ê|¼Ò¿ä[ `t]*¿¹»ê[ `t]*ÃÑ¾×|¼Ò¿ä[ `t]*¿¹»ê[ `t]*±Ý¾×|¼Ò¿ä[ `t]*¿¹»ê[ `t]*¾×|¼Ò¿ä[ `t]*¿¹»ê|¿¹»ê[ `t]*ÃÑ¾×|ÃÑ[ `t]*¿¹»ê[ `t]*±Ý¾×|ÃÑ[ `t]*¿¹»ê[ `t]*¾×|ÃÑ[ `t]*¿¹»ê|¿¹»ê[ `t]*±Ý¾×|¿¹»ê[ `t]*¾×|¿¹»ê|ÃÑ[ `t]*ÁöÃâ[ `t]*±Ý¾×|ÁöÃâ[ `t]*ÃÑ¾×|ÁöÃâ[ `t]*±Ý¾×|ÁöÃâ[ `t]*¾×|ÃÑ[ `t]*ÁýÇà[ `t]*±Ý¾×|ÁýÇà[ `t]*ÃÑ¾×|ÁýÇà[ `t]*±Ý¾×|ÁýÇà[ `t]*¾×|ÃÑ[ `t]*±¸¸Å[ `t]*±Ý¾×|ÃÑ[ `t]*±¸¸Å[ `t]*¾×|±¸¸Å[ `t]*ÃÑ¾×|±¸¸Å[ `t]*±Ý¾×|±¸¸Å[ `t]*¾×|ÃÑ[ `t]*±¸ÀÔ[ `t]*±Ý¾×|ÃÑ[ `t]*±¸ÀÔ[ `t]*¾×|±¸ÀÔ[ `t]*ÃÑ¾×|±¸ÀÔ[ `t]*±Ý¾×|±¸ÀÔ[ `t]*¾×|ÃÑ[ `t]*Áö±Þ[ `t]*±Ý¾×|ÃÑ[ `t]*Áö±Þ[ `t]*¾×|Áö±Þ[ `t]*ÃÑ¾×|Áö±Þ[ `t]*±Ý¾×|Áö±Þ[ `t]*¾×|ÃÑ[ `t]*°è¾à[ `t]*±Ý¾×|°è¾à[ `t]*ÃÑ¾×|°è¾à[ `t]*±Ý¾×|°è¾à[ `t]*¾×|¿øÀÎÇàÀ§[ `t]*ÃÑ¾×|¿øÀÎÇàÀ§[ `t]*±Ý¾×|¿øÀÎÇàÀ§[ `t]*¾×|ÃÑ[ `t]*»ç¿ë[ `t]*±Ý¾×|»ç¿ë[ `t]*ÃÑ¾×|»ç¿ë[ `t]*±Ý¾×|»ç¿ë[ `t]*¾×|ÃÑ[ `t]*°áÁ¦[ `t]*±Ý¾×|°áÁ¦[ `t]*ÃÑ¾×|°áÁ¦[ `t]*±Ý¾×|°áÁ¦[ `t]*¾×|ÃÑ[ `t]*Ã»±¸[ `t]*±Ý¾×|Ã»±¸[ `t]*ÃÑ¾×|Ã»±¸[ `t]*±Ý¾×|Ã»±¸[ `t]*¾×|ÇÕ°è[ `t]*±Ý¾×|ÇÕ°è[ `t]*¾×|ÇÕ°è|ÃÑ[ `t]*±Ý¾×|ÃÑ¾×|¼Ò¿ä[ `t]*±Ý¾×|¼Ò¿ä[ `t]*¾×|°­»çºñ|°­»ç·á|¿©ºñ|±Ý¾×"

    ; ±âÁ¸ ¼ýÀÚ µÚ¿¡ ºÙÀº ÇÑ±Û ±Ý¾×Àº ¸ðµÎ Áö¿ó´Ï´Ù.
    ; ¿¹: ±Ý207,000¿ø(±ÝÀÌ½Ê¸¸Ä¥Ãµ¿ø)(ÀÌ½Ê¸¸Ä¥Ãµ¿øÁ¤) -> ±Ý151,560¿ø
    ; ÀÌÈÄ Win+F2°¡ ¼±ÅÃµÈ °³¿ä ÀüÃ¼¸¦ ´Ù½Ã Á¤¸®ÇÏ¸é¼­ »õ ¼ýÀÚ ±âÁØ ÇÑ±Û±Ý¾×À» ÀÛ¼ºÇÕ´Ï´Ù.
    oldKoreanAmount := "(?:±Ý[ `t]*[¿µÀÏÀÌ»ï»ç¿ÀÀ°Ä¥ÆÈ±¸½Ê¹éÃµ¸¸¾ïÁ¶°æ0-9, `t]+[ `t]*¿ø(?:Á¤)?|[¿µÀÏÀÌ»ï»ç¿ÀÀ°Ä¥ÆÈ±¸½Ê¹éÃµ¸¸¾ïÁ¶°æ0-9, `t]+[ `t]*¿ø(?:Á¤)?)"
    pattern := "(?<![°¡-ÆRA-Za-z0-9])(" . labels . "[ `t]*[:£º]?[ `t]*)±Ý?[ `t]*[0-9][0-9,]*[ `t]*¿ø?(?:[ `t]*\(" . oldKoreanAmount . "\))*"

    pos := RegExMatch(text, pattern, m)
    if (!pos)
        return ""

    return SubStr(text, 1, pos - 1) . m1 . replacement . SubStr(text, pos + StrLen(m))
}

SSOK_Expense_Win3Overview()
{
    global SSOK_ExpenseBusy, SSOK_ExpenseCancel
    if (SSOK_ExpenseBusy)
        return false
    target := WinExist("A")
    SSOK_ExpenseCancel := false
    SSOK_ExpenseBusy := true
    try
    {
        SSOK_Expense_Win3Progress(target)

        ; 1¼øÀ§: ÀÌÀü¿¡ Ã£Àº ¿øÀÎÇàÀ§ÃÑ¾× ¶óº§ À§Ä¡¸¦ ¹Ù·Î ÀÐ½À´Ï´Ù.
        ; MSAA Æ®¸® ÀüÃ¼¸¦ ´Ù½Ã ÈÈÁö ¾ÊÀ¸¹Ç·Î ¹Ýº¹ ½ÇÇà ½Ã °¡Àå ºü¸¨´Ï´Ù.
        amount := SSOK_Expense_Win3_ReadTotalCauseCached(target)

        ; ÀúÀå À§Ä¡°¡ ¾ø°Å³ª È­¸é À§Ä¡°¡ ´Þ¶óÁ³À» ¶§¸¸ ±âÁ¸ Fast Å½»öÀ» 1È¸ »ç¿ëÇÕ´Ï´Ù.
        ; ¼º°øÇÏ¸é À§Ä¡¸¦ ´Ù½Ã ÀúÀåÇÏ¿© ´ÙÀ½ Win+3ºÎÅÍ Áï½Ã ÀÐ½À´Ï´Ù.
        if (amount = "")
            amount := SSOK_Expense_Win3_FindTotalCauseFast(target)

        ; ±âÁ¸ ÀüÃ¼ MSAA ½ºÄµÀº »èÁ¦ÇÏÁö ¾Ê°í º¸·ùÇÕ´Ï´Ù.
        ; Win+3¿¡¼­´Â ¼Óµµ ¶§¹®¿¡ ½ÇÇàÇÏÁö ¾Ê½À´Ï´Ù.
        if (amount = "")
        {
            root := SSOK_Expense_MSAA_GetEdufineRoot(target, true)
            if (!IsObject(root))
                throw Exception("K-¿¡µàÆÄÀÎ È­¸éÀ» Ã£Áö ¸øÇß½À´Ï´Ù.")
            scan := SSOK_Expense_Win2_Scan(root, target, true)
            if (scan.stopped)
                throw Exception("È­¸é Å½»öÀÌ Áß´ÜµÇ¾ú½À´Ï´Ù. ¿øÀÎÇàÀ§ÃÑ¾×ÀÌ º¸ÀÌ°Ô ÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.")
            amount := SSOK_Expense_Win2_ReadTotalCauseAmount(scan.items)
            if (amount != "")
                SSOK_Expense_Win3_RememberTotal(scan.items, target)
        }

        if (amount = "")
            throw Exception("¿øÀÎÇàÀ§ÃÑ¾×À» Ã£Áö ¸øÇß½À´Ï´Ù.")

        ; °³¿ä ÀÔ·Â¶õÀº Ã£Áö ¾Ê½À´Ï´Ù. »ç¿ëÀÚ°¡ ÇöÀç Ä¿¼­¸¦ µÐ ÀÔ·ÂÄ­À» ±×´ë·Î »ç¿ëÇÕ´Ï´Ù.
        if (!SSOK_Expense_Active(target))
            return false

        saved := ClipboardAll
        try
        {
            Clipboard := ""
            SendInput, ^a
            Sleep, 40
            SendInput, ^c
            ClipWait, 0.5
            if (ErrorLevel)
                throw Exception("ÇöÀç ÀÔ·Â¶õÀÇ ³»¿ëÀ» ÀÐÁö ¸øÇß½À´Ï´Ù.")
            current := Clipboard

            if (Trim(current) = "")
                throw Exception("ÇöÀç ÀÔ·Â¶õÀÌ ºñ¾î ÀÖ¾î Á¤¸®ÇÒ ³»¿ëÀÌ ¾ø½À´Ï´Ù.")
            if (DOC_FindTableStartLine(current) > 0)
                throw Exception("ÇöÀç ÀÔ·Â¶õ¿¡ Ç¥°¡ ÀÖ¾î ÀÚµ¿ Á¤¸®¸¦ Áß´ÜÇß½À´Ï´Ù.")

            changed := SSOK_Expense_Win3AmountText(current, amount)
            if (changed = "")
                throw Exception("ÇöÀç ÀÔ·Â¶õ¿¡¼­ ÃÑ¾×¡¤±Ý¾×¡¤±¸¸Å¾×¡¤Áö±Þ¾× µî ÃÑ±Ý¾× Ç×¸ñÀ» Ã£Áö ¸øÇß½À´Ï´Ù. ±âÁ¸ ³»¿ëÀº À¯ÁöµË´Ï´Ù.")

            Clipboard := ""
            Clipboard := changed
            ClipWait, 0.5
            if (ErrorLevel || !SSOK_Expense_Active(target))
                throw Exception("±Ý¾×À» ÀÔ·ÂÇÒ ÁØºñ¸¦ ÇÏÁö ¸øÇß½À´Ï´Ù.")

            SendInput, ^a
            Sleep, 30
            SendInput, ^v
            Sleep, 120
        }
        finally
        {
            Clipboard := saved
            saved := ""
        }

        ; ¼ø¼­ °íÁ¤:
        ; 1) ¼ýÀÚ ÃÑ±Ý¾× ±³Ã¼  2) ±âÁ¸ ÇÑ±Û±Ý¾× »èÁ¦  3) °³¿ä ÀüÃ¼ ¼±ÅÃ  4) ¸¶Áö¸·¿¡ ±âÁ¸ Win+F2 ½ÇÇà
        if (!SSOK_Expense_Active(target))
            return false
        SendInput, ^a
        Sleep, 120
        SSOK_Expense_Win3Progress(0)

        ; Win+3 ÇÔ¼ö ³»ºÎ¿¡¼­ ¹Ù·Î SSOK_DoF2¸¦ È£ÃâÇÏÁö ¾Ê½À´Ï´Ù.
        ; ÇÔ¼ö°¡ ¿ÏÀüÈ÷ Á¾·áµÈ µÚ º°µµ Å¸ÀÌ¸Ó¿¡¼­ ÇöÀç °³¿ä¸¦ ´Ù½Ã ÀüÃ¼ ¼±ÅÃÇÏ°í
        ; ±âÁ¸ Win+F2 ·çÆ¾(SSOK_DoF2)À» ½ÇÇàÇÕ´Ï´Ù.
        SetTimer, SSOK_Expense_Win3_RunFinalF2, -180
        return true
    }
    catch error
    {
        SSOK_Expense_Win3Progress(0)
        MsgBox, 48, °£Æí ¿øÀÎÇàÀ§ Win+3, % error.Message
        return false
    }
    finally
    {
        SSOK_Expense_Win3Progress(0)
        SSOK_ExpenseBusy := false
    }
}

; ------------------------------------------------------------
; Win+3 ¸¶Áö¸· Win+F2 ½ÇÇà
; - Win+3 ÇÔ¼ö°¡ ¿ÏÀüÈ÷ ³¡³­ µÚ º°µµ ½º·¹µå¿¡¼­ ½ÇÇà
; - ÇöÀç °³¿ä ÀÔ·ÂÄ­À» ´Ù½Ã ÀüÃ¼ ¼±ÅÃÇÑ ÈÄ ±âÁ¸ SSOK_DoF2¸¦ ±×´ë·Î È£Ãâ
; ------------------------------------------------------------
SSOK_Expense_Win3_RunFinalF2:
    SendInput, {End}
    Sleep, 120
    Gosub, SSOK_DoF2
return


; ------------------------------------------------------------
; Win+3 ¿øÀÎÇàÀ§ÃÑ¾× À§Ä¡ Ä³½Ã
; - ÇÑ ¹ø Ã£Àº ¶óº§ À§Ä¡¸¦ Ã¢ ±âÁØ »ó´ëÁÂÇ¥·Î ÀúÀåÇÕ´Ï´Ù.
; - ´ÙÀ½ ½ÇÇàºÎÅÍ´Â Æ®¸® Å½»ö ¾øÀÌ ÇØ´ç À§Ä¡¸¸ Á÷Á¢ È®ÀÎÇÕ´Ï´Ù.
; - È­¸é ¹èÄ¡°¡ ´Þ¶óÁ® ÀÐ±â¿¡ ½ÇÆÐÇÏ¸é ±âÁ¸ Fast Å½»öÀ¸·Î ÀÚµ¿ ÀçÇÐ½ÀÇÕ´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_Win3_ReadTotalCauseCached(target)
{
    if (!SSOK_Expense_Active(target))
        return ""

    file := SSOK_Expense_PathCacheFile()
    IniRead, rx, %file%, ExpenseMSAA, TotalLabelX, ERROR
    IniRead, ry, %file%, ExpenseMSAA, TotalLabelY, ERROR
    IniRead, rw, %file%, ExpenseMSAA, TotalLabelW, ERROR
    IniRead, rh, %file%, ExpenseMSAA, TotalLabelH, ERROR

    if (rx = "ERROR" || ry = "ERROR" || rw = "ERROR" || rh = "ERROR")
        return ""

    WinGetPos, wx, wy,,, ahk_id %target%
    if (wx = "" || wy = "")
        return ""

    rect := {x:wx + rx + 0, y:wy + ry + 0, w:rw + 0, h:rh + 0}
    rect.cx := rect.x + rect.w/2
    rect.cy := rect.y + rect.h/2

    ; ¶óº§ °´Ã¼ ÀÚÃ¼¿¡ ±Ý¾×ÀÌ °°ÀÌ ³ëÃâµÇ´Â È¯°æÀ» ¸ÕÀú 1È¸ Á¡ Á¶È¸ÇÕ´Ï´Ù.
    hit := SSOK_Expense_Win3ProgressPoint(Round(rect.cx), Round(rect.cy))
    if (!SSOK_Expense_Win3_IsTotalLabel(hit))
        return ""
    if (IsObject(hit))
    {
        amount := SSOK_Expense_StrictAmount(SSOK_Expense_MSAA_Get(hit.acc, "Value", hit.child))
        if (amount = "")
            amount := SSOK_Expense_StrictAmount(SSOK_Expense_MSAA_Get(hit.acc, "Name", hit.child))
        if (amount != "")
            return amount
    }

    ; ÀÏ¹Ý Nexacro È­¸éÀº ÀúÀåµÈ ¶óº§ ¹Ù·Î ¿À¸¥ÂÊÀÇ ±Ý¾×¸¸ È®ÀÎÇÕ´Ï´Ù.
    return SSOK_Expense_Win3_AmountRightOfLabel(rect, target)
}

SSOK_Expense_Win3_SaveTotalCauseCache(rect, target)
{
    if (!IsObject(rect) || !SSOK_Expense_Active(target))
        return false

    WinGetPos, wx, wy,,, ahk_id %target%
    if (wx = "" || wy = "")
        return false

    rx := Round(rect.x - wx)
    ry := Round(rect.y - wy)
    rw := Round(rect.w)
    rh := Round(rect.h)

    file := SSOK_Expense_PathCacheFile()
    IniWrite, %rx%, %file%, ExpenseMSAA, TotalLabelX
    IniWrite, %ry%, %file%, ExpenseMSAA, TotalLabelY
    IniWrite, %rw%, %file%, ExpenseMSAA, TotalLabelW
    IniWrite, %rh%, %file%, ExpenseMSAA, TotalLabelH
    return true
}

; ------------------------------------------------------------
; Win+3 Àü¿ë ¿øÀÎÇàÀ§ÃÑ¾× ºü¸¥ Å½»ö
; - ±âÁ¸ Win+2 ÀüÃ¼ ½ºÄµ ÇÔ¼ö´Â ¼öÁ¤/»èÁ¦ÇÏÁö ¾Ê½À´Ï´Ù.
; - Name/Value¸¸ ÃÖ¼Ò Á¶È¸ÇÏ°í ¶óº§ ¹ß°ß Áï½Ã Áß´ÜÇÕ´Ï´Ù.
; - ¶óº§ ¿À¸¥ÂÊ 120px ¹üÀ§¸¦ AccessibleObjectFromPoint·Î È®ÀÎÇÕ´Ï´Ù.
; - ½ÇÆÐÇÏ¸é È£ÃâºÎ¿¡¼­ ±âÁ¸ ÀüÃ¼ MSAA ½ºÄµÀ¸·Î ÀÚµ¿ fallback ÇÕ´Ï´Ù.
; ------------------------------------------------------------
SSOK_Expense_Win3_FindTotalCauseFast(target)
{
    if (!SSOK_Expense_Active(target))
        return ""

    started := A_TickCount
    root := SSOK_Expense_MSAA_GetEdufineRoot(target, false)
    if (!IsObject(root))
        root := SSOK_Expense_MSAA_GetEdufineRoot(target, true)
    if (!IsObject(root))
        return ""

    ; ºü¸¥ °Ë»öµµ ±âÁ¸ ÀüÃ¼ °Ë»ö°ú µ¿ÀÏÇÏ°Ô Áßº¹ °´Ã¼¸¦ Á¦°ÅÇÏ°í ¼û±è/È­¸é ¹Û °¡Áö¸¦ °Ç³Ê¶Ý´Ï´Ù.
    ; ºÒÇÊ¿äÇÑ ¹Ýº¹ Å½»öÀ» Å©°Ô ÁÙÀÌµÇ, ´À¸° PC¿¡¼­µµ ³Ê¹« ÀÏÂï Á¾·áµÇÁö ¾Êµµ·Ï ÃÖ´ë 6ÃÊ¸¸ Çã¿ëÇÕ´Ï´Ù.
    state := {target:target, nodes:0, limit:30000, deadline:A_TickCount + 6000
        , found:"", stopped:false, seen:{}, duplicates:0}
    SSOK_Expense_Win3_WalkTotalFast(root, 0, state)

    if (!IsObject(state.found))
    {
        SSOK_Expense_Log("win3-fast-total miss nodes=" . state.nodes . " duplicates=" . state.duplicates . " elapsedMs=" . (A_TickCount - started))
        return ""
    }

    ; ¶óº§ °´Ã¼ ÀÚÃ¼ Value¿¡ ±Ý¾×ÀÌ °°ÀÌ ³ëÃâµÇ´Â °æ¿ì°¡ °¡Àå ºü¸¨´Ï´Ù.
    amount := SSOK_Expense_StrictAmount(state.found.value)
    if (amount = "")
        amount := SSOK_Expense_StrictAmount(state.found.name)
    if (amount != "")
    {
        if (IsObject(state.found.rect))
            SSOK_Expense_Win3_SaveTotalCauseCache(state.found.rect, target)
        SSOK_Expense_Log("win3-fast-total direct nodes=" . state.nodes . " duplicates=" . state.duplicates . " elapsedMs=" . (A_TickCount - started))
        return amount
    }

    ; ÀÏ¹ÝÀûÀÎ Nexacro È­¸é: ¶óº§ ¹Ù·Î ¿À¸¥ÂÊÀÇ ±Ý¾× ÄÁÆ®·ÑÀ» Á¡ Á¶È¸ÇÕ´Ï´Ù.
    if (IsObject(state.found.rect))
    {
        amount := SSOK_Expense_Win3_AmountRightOfLabel(state.found.rect, target)
        if (amount != "")
        {
            SSOK_Expense_Win3_SaveTotalCauseCache(state.found.rect, target)
            SSOK_Expense_Log("win3-fast-total point nodes=" . state.nodes . " duplicates=" . state.duplicates . " elapsedMs=" . (A_TickCount - started))
            return amount
        }
    }

    SSOK_Expense_Log("win3-fast-total label-only nodes=" . state.nodes . " duplicates=" . state.duplicates . " elapsedMs=" . (A_TickCount - started))
    return ""
}

SSOK_Expense_Win3_WalkTotalFast(acc, depth, state)
{
    if (state.stopped || IsObject(state.found))
        return

    if (depth > 160 || state.nodes >= state.limit || A_TickCount > state.deadline
        || !SSOK_Expense_Active(state.target))
    {
        state.stopped := true
        return
    }

    ; °°Àº COM/MSAA °´Ã¼°¡ ¿©·¯ °æ·Î·Î ¹Ýº¹ ³ëÃâµÇ´Â °æ¿ì ÇÑ ¹ø¸¸ Å½»öÇÕ´Ï´Ù.
    identity := SSOK_Expense_MSAA_Identity({acc:acc, child:0})
    if (identity != "")
    {
        if (state.seen.HasKey(identity))
        {
            state.duplicates++
            return
        }
        state.seen[identity] := true
    }

    ; ¼û±è ¶Ç´Â È­¸é ¹ÛÀÇ Å« °¡Áö´Â ³»·Á°¡Áö ¾Ê½À´Ï´Ù.
    status := SSOK_Expense_MSAA_Get(acc, "State", 0)
    if (status != "" && ((status & 0x8000) || (depth > 0 && (status & 0x10000))))
        return

    state.nodes++
    SSOK_Expense_Win3_CheckTotalNode(acc, 0, state)
    if (IsObject(state.found) || state.stopped)
        return

    children := SSOK_Expense_MSAA_GetChildren(acc)
    if (!IsObject(children))
        return

    for _, item in children
    {
        if (state.stopped || IsObject(state.found))
            return

        if (state.nodes >= state.limit || A_TickCount > state.deadline
            || !SSOK_Expense_Active(state.target))
        {
            state.stopped := true
            return
        }

        if (item.kind = 2)
            SSOK_Expense_Win3_WalkTotalFast(item.acc, depth + 1, state)
        else
        {
            state.nodes++
            SSOK_Expense_Win3_CheckTotalNode(acc, item.id, state)
        }
    }
}

SSOK_Expense_Win3_CheckTotalNode(acc, child, state)
{
    ; ¼û±è child´Â ÀÌ¸§/°ª Á¶È¸ ÀÚÃ¼¸¦ »ý·«ÇÕ´Ï´Ù.
    childState := SSOK_Expense_MSAA_Get(acc, "State", child)
    if (childState != "" && (childState & 0x8000))
        return

    ; ´ëºÎºÐÀÇ ¶óº§Àº Name¿¡ ÀÖÀ¸¹Ç·Î NameÀ» ¸ÕÀú º¸°í,
    ; NameÀÌ ÀÏÄ¡ÇÏÁö ¾ÊÀ» ¶§¸¸ Value¸¦ Ãß°¡ Á¶È¸ÇÕ´Ï´Ù.
    name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", child))
    n := SSOK_Expense_Win2_Normalize(name)
    value := ""

    if (!RegExMatch(n, "^(ÃÑ¿øÀÎÇàÀ§¾×|¿øÀÎÇàÀ§ÃÑ¾×)(\(¿ø\))?$"))
    {
        value := Trim(SSOK_Expense_MSAA_Get(acc, "Value", child))
        v := SSOK_Expense_Win2_Normalize(value)
        if (!RegExMatch(v, "^(ÃÑ¿øÀÎÇàÀ§¾×|¿øÀÎÇàÀ§ÃÑ¾×)(\(¿ø\))?$"))
            return
    }
    else
        value := Trim(SSOK_Expense_MSAA_Get(acc, "Value", child))

    rect := SSOK_Expense_Win2_GetRect(acc, child)

    ; È­¸é ¹Û/¼û±è º¹Á¦ °´Ã¼°¡ ¸ÕÀú ÀâÈ÷¸é ½ÇÁ¦ Ç¥½Ã ¶óº§À» °è¼Ó Ã£½À´Ï´Ù.
    if (!IsObject(rect) && SSOK_Expense_StrictAmount(value) = "")
        return

    state.found := {acc:acc, child:child, name:name, value:value, rect:rect}
}

SSOK_Expense_Win3_AmountRightOfLabel(labelRect, target)
{
    global SSOK_ExpenseTotalValueCache
    if (!IsObject(labelRect) || !SSOK_Expense_Active(target))
        return ""

    cache := SSOK_ExpenseTotalValueCache
    if (IsObject(cache) && cache.target = target)
    {
        r := SSOK_Expense_Win2_GetRect(cache.hit.acc, cache.hit.child)
        if (IsObject(r) && Abs(r.cy - labelRect.cy) <= 8
            && r.x >= labelRect.x + labelRect.w - 2 && r.x <= labelRect.x + labelRect.w + 120)
        {
            value := SSOK_Expense_StrictAmount(SSOK_Expense_MSAA_Get(cache.hit.acc, "Value", cache.hit.child))
            if (value != "")
            {

                return value
            }
        }
        SSOK_ExpenseTotalValueCache := ""
    }
    ; ±âÁ¸ ÆÇÁ¤°ú µ¿ÀÏÇÏ°Ô '°°Àº ÁÙ + ¶óº§ ¿À¸¥ÂÊ 120px ÀÌ³»'¸¸ Çã¿ëÇÕ´Ï´Ù.
    startX := Round(labelRect.x + labelRect.w + 2)
    centerY := Round(labelRect.cy)
    yOffsets := [0, -4, 4]
    seen := {}

    Loop, 16
    {
        x := startX + (A_Index - 1) * 8
        for _, dy in yOffsets
        {
            if (!SSOK_Expense_Active(target))
                return ""

            hit := SSOK_Expense_Win3ProgressPoint(x, centerY + dy)
            if (!IsObject(hit))
                continue

            key := SSOK_Expense_MSAA_Identity(hit)
            if (key != "" && seen.HasKey(key))
                continue
            if (key != "")
                seen[key] := true

            value := SSOK_Expense_StrictAmount(SSOK_Expense_MSAA_Get(hit.acc, "Value", hit.child))
            if (value = "")
                value := SSOK_Expense_StrictAmount(SSOK_Expense_MSAA_Get(hit.acc, "Name", hit.child))
            if (value != "")
            {
                SSOK_ExpenseTotalValueCache := {target:target, hit:hit}
                return value
            }
        }
    }

    return ""
}


SSOK_Expense_Win3FindOverview(items)
{
    ; Nexacro´Â '°³¿ä' ¶óº§°ú ÀÌ¸§ ¾ø´Â ½ÇÁ¦ ÆíÁýÄ­À» º°µµ·Î ³ëÃâÇÕ´Ï´Ù.
    ; ¼Ò¿ä¿¹»ê ¹®ÀåÀÌ ´ã±ä À¯ÀÏÇÑ ÆíÁýÄ­À» Ã£°í, º¹¼öÀÌ¸é ÃßÃøÇÏÁö ¾Ê½À´Ï´Ù.
    found := ""
    seen := {}
    for _, node in items
    {
        if (node.role != 42 || !RegExMatch(node.value, "¼Ò¿ä¿¹»ê\s*[:£º]"))
            continue
        if (!SSOK_Expense_MSAA_Usable(node.acc, node.child, true))
            continue
        key := SSOK_Expense_MSAA_Identity(node)
        if (key != "" && seen.HasKey(key))
            continue
        if (key != "")
            seen[key] := true
        if (IsObject(found))
            return ""
        found := node
    }
    return found
}
SSOK_Expense_Win3_IsTotalLabel(hit)
{
    if (!IsObject(hit))
        return false
    name := SSOK_Expense_Win2_Normalize(SSOK_Expense_MSAA_Get(hit.acc, "Name", hit.child))
    value := SSOK_Expense_Win2_Normalize(SSOK_Expense_MSAA_Get(hit.acc, "Value", hit.child))
    return RegExMatch(name, "^(ÃÑ¿øÀÎÇàÀ§¾×|¿øÀÎÇàÀ§ÃÑ¾×)(\(¿ø\))?$")
        || RegExMatch(value, "^(ÃÑ¿øÀÎÇàÀ§¾×|¿øÀÎÇàÀ§ÃÑ¾×)(\(¿ø\))?$")
}

SSOK_Expense_Win3_RememberTotal(items, target)
{
    hits := []
    for _, node in items
    {
        if (SSOK_Expense_Win3_IsTotalLabel(node) && IsObject(node.rect))
            hits.Push(node)
    }
    if (hits.Length() = 1)
        SSOK_Expense_Win3_SaveTotalCauseCache(hits[1].rect, target)
}

SSOK_Expense_Win3Progress(target)
{
    global SSOK_ExpenseProgressVisible
    Gui, SSOKExpenseProgress:Destroy
    SSOK_ExpenseProgressVisible := false
    if (!target)
        return
    Gui, SSOKExpenseProgress:New, +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, SSOKExpenseProgress:Color, FFE066
    Gui, SSOKExpenseProgress:Margin, 36, 26
    Gui, SSOKExpenseProgress:Font, s28 Bold c202020, Malgun Gothic
    Gui, SSOKExpenseProgress:Add, Text, w360 h58 Center +0x200, win 3 ÀÛ¾÷Áß
    Gui, SSOKExpenseProgress:Font, s11 Norm c404040, Malgun Gothic
    Gui, SSOKExpenseProgress:Add, Text, y+6 w360 h24 Center, ¸¶¿ì½º¸¦ ¿òÁ÷ÀÌÁö ¸¶¼¼¿ä.
    WinGetPos, x, y, w, h, ahk_id %target%
    px := Round(x + (w - 432)/2)
    py := Round(y + (h - 140)/2)
    Gui, SSOKExpenseProgress:Show, x%px% y%py% w432 h140 NoActivate
    SSOK_ExpenseProgressVisible := true
}

SSOK_Expense_Win3ProgressPoint(x, y)
{
    global SSOK_ExpenseProgressVisible
    visible := SSOK_ExpenseProgressVisible
    if (visible)
        Gui, SSOKExpenseProgress:Hide
    try
        return SSOK_Expense_MSAA_FromPointFast(x, y)
    finally
    {
        if (visible)
            Gui, SSOKExpenseProgress:Show, NoActivate
    }
}
SSOK_Expense_MSAA_PointBelongsToAddButton(hit)
{
    if !IsObject(hit)
        return false

    if (SSOK_Expense_MSAA_IsFixedAddButton(hit))
        return true

    current := hit.acc

    if (hit.child)
    {
        parentCandidate := {acc:current, child:0}
        if (SSOK_Expense_MSAA_IsFixedAddButton(parentCandidate))
            return true
    }

    Loop, 5
    {
        try
            parent := current.accParent
        catch
            break

        if !IsObject(parent)
            break

        parentCandidate := {acc:parent, child:0}
        if (SSOK_Expense_MSAA_IsFixedAddButton(parentCandidate))
            return true

        current := parent
    }

    return false
}

SSOK_Expense_ClickVisibleAddButton(button, target)
{
    if (!SSOK_Expense_Active(target) || !SSOK_Expense_MSAA_IsFixedAddButton(button))
        return false

    rect := SSOK_Expense_Win2_GetRect(button.acc, button.child)
    if (!IsObject(rect))
    {
        SSOK_Expense_Log("row-click-no-visible-rect")
        return false
    }

    ; Nexacro¿¡¼­ ¹öÆ° Áß¾ÓÁ¡ÀÌ ³»ºÎ ÅØ½ºÆ®/ÀÚ½Ä °´Ã¼·Î ¹ÝÈ¯µÇ´Â °æ¿ì°¡ ÀÖ¾î
    ; Á¤Áß¾Ó 1Á¡ ´ë½Å ¹öÆ° ³»ºÎÀÇ 5°³ ¾ÈÀü ÁöÁ¡À» È®ÀÎÇÕ´Ï´Ù.
    points := []
    points.Push({x:Round(rect.x + rect.w*0.50), y:Round(rect.y + rect.h*0.50)})
    points.Push({x:Round(rect.x + rect.w*0.30), y:Round(rect.y + rect.h*0.50)})
    points.Push({x:Round(rect.x + rect.w*0.70), y:Round(rect.y + rect.h*0.50)})
    points.Push({x:Round(rect.x + rect.w*0.50), y:Round(rect.y + rect.h*0.35)})
    points.Push({x:Round(rect.x + rect.w*0.50), y:Round(rect.y + rect.h*0.65)})

    clickX := ""
    clickY := ""
    coveredSeen := false
    targetPointSeen := false

    for idx, p in points
    {
        if (!SSOK_Expense_Active(target))
            return false

        x := p.x
        y := p.y

        packed := (x & 0xFFFFFFFF) | ((y & 0xFFFFFFFF) << 32)
        hwnd := DllCall("WindowFromPoint", "Int64", packed, "Ptr")
        root := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")

        if (root != target)
        {
            coveredSeen := true
            continue
        }

        targetPointSeen := true
        hit := SSOK_Expense_MSAA_FromPointFast(x, y)

        ; Á¡ Á¶È¸ °á°ú°¡ ÇàÃß°¡ ¹öÆ° ÀÚÃ¼ÀÌ°Å³ª ±× ÀÚ½Ä/³»ºÎ °´Ã¼ÀÌ¸é ÀÎÁ¤ÇÕ´Ï´Ù.
        if (SSOK_Expense_MSAA_PointBelongsToAddButton(hit))
        {
            clickX := x
            clickY := y
            SSOK_Expense_Log("row-click-point-verified index=" . idx)
            break
        }
    }

    ; ¾ÈÀü¼º À¯Áö: 5°³ ÁöÁ¡ ¸ðµÎ ÇàÃß°¡ ¹öÆ°À¸·Î È®ÀÎµÇÁö ¾ÊÀ¸¸é Å¬¸¯ÇÏÁö ¾Ê½À´Ï´Ù.
    if (clickX = "")
    {
        if (!targetPointSeen && coveredSeen)
            SSOK_Expense_Log("row-click-covered")
        else
            SSOK_Expense_Log("row-click-point-not-add-button")
        return false
    }

    if (!SSOK_Expense_Active(target))
        return false

    previousMode := A_CoordModeMouse
    try
    {
        CoordMode, Mouse, Screen
        Click, %clickX%, %clickY%
        SSOK_Expense_Log("row-visible-click-sent")
        return true
    }
    finally
    {
        CoordMode, Mouse, %previousMode%
    }
}


; ============================================================================
; SSOK ¾÷¹«¿ë µµ±¸ - Å×½ºÆ®¹öÀü Beta (º°µµ ¼ÒÇü Ã¢)
; ±âÁ¸ Win+1~4 ±â´ÉÀº ¼öÁ¤ÇÏÁö ¾Ê°í ¸µÅ©¸¸ ¿¬°áÇÕ´Ï´Ù.
; ½Å±Ô 2°³ ±â´ÉÀº ÇöÀç ´Ü°è¿¡¼­ Excel 2°³ ÆÄÀÏ ÀÔ·Â UI¸¸ ±¸ÇöÇÕ´Ï´Ù.
; ============================================================================

SSOK_Expense_Tools_Open:
    SSOK_Expense_Tools_Show()
return

SSOKExpenseToolsGuiClose:
SSOKExpenseToolsGuiEscape:
    Gui, SSOKExpenseTools:Destroy
return

SSOK_Expense_Tools_Win1:
    SSOK_Expense_Tools_ActivateTarget()
    SSOK_Expense_Run()
return

SSOK_Expense_Tools_Win2:
    SSOK_Expense_Tools_ActivateTarget()
    SSOK_Expense_Tools_RunWin2()
return

SSOK_Expense_Tools_Win3:
    SSOK_Expense_Tools_ActivateTarget()
    SSOK_Expense_Win3Overview()
return

SSOK_Expense_Tools_Win4:
    SSOK_Expense_Tools_ActivateTarget()
    Gosub, SSOK_Expense_DoWin4_KEdufine_TabSeq
return

SSOK_Expense_Tools_CardCompare:
    ; Beta ¸Þ´º´Â ´ÝÁö ¾Ê½À´Ï´Ù.
    SSOK_Expense_CardCompare_Show()
return

SSOK_Expense_Tools_WorkPublic:
    ; Beta ¸Þ´º´Â ´ÝÁö ¾Ê½À´Ï´Ù.
    SSOK_Expense_WorkPublic_Show()
return

SSOK_Expense_Tools_Show()
{
    global SSOK_ExpenseToolsHwnd
    global SSOK_BetaReplaceX, SSOK_BetaReplaceY, SSOK_BetaReplaceW, SSOK_BetaReplaceH
    global SSOK_WorkToolsHwnd, SSOK_SidebarHwnd

    Gui, SSOKExpenseTools:Destroy
    Gui, SSOKExpenseTools:New, +AlwaysOnTop +ToolWindow +HwndSSOK_ExpenseToolsHwnd, Å×½ºÆ®¹öÀü Beta
    Gui, SSOKExpenseTools:Color, F7FBFF
    Gui, SSOKExpenseTools:Font, s6.72 Bold, Malgun Gothic

    ; ±âº»°ªÀº ±âÁ¸ ¾÷¹«¿ë µµ±¸¿Í °°Àº 182px Æø.
    betaW := (SSOK_BetaReplaceW != "" && SSOK_BetaReplaceW > 0) ? SSOK_BetaReplaceW : 182
    betaH := (SSOK_BetaReplaceH != "" && SSOK_BetaReplaceH > 0) ? SSOK_BetaReplaceH : 443

    btnW := betaW - 16
    if (btnW < 130)
        btnW := 166

    Gui, SSOKExpenseTools:Add, Button, x8 y8   w%btnW% h25 +0x100 gSSOK_Expense_Tools_Win1, °£Æí ÁöÃâÇ°ÀÇ(win + 1)
    Gui, SSOKExpenseTools:Add, Button, x8 y39  w%btnW% h25 +0x100 gSSOK_Expense_Tools_Win2, °£Æí ¿øÀÎÇàÀ§(win + 2)
    Gui, SSOKExpenseTools:Add, Button, x8 y70  w%btnW% h25 +0x100 gSSOK_Expense_Tools_Win3, °£Æí ¿øÀÎÇàÀ§(win + 3)
    Gui, SSOKExpenseTools:Add, Button, x8 y101 w%btnW% h25 +0x100 gSSOK_Expense_Tools_Win4, °£Æí ¿øÀÎÇàÀ§(win + 4)

    ; Beta¸¦ ´©¸£±â Á÷Àü ¾÷¹«¿ë µµ±¸ÀÇ ¹Ù·Î ±× ÀÚ¸®/Å©±â »ç¿ë
    x := SSOK_BetaReplaceX
    y := SSOK_BetaReplaceY

    if (x = "" || y = "")
    {
        ; ¿¹¿ÜÀûÀ¸·Î À§Ä¡ ÀúÀåÀÌ ¾È µÆÀ¸¸é ¾÷¹«¿ë µµ±¸ ¶Ç´Â »çÀÌµå¹Ù À§Ä¡ »ç¿ë
        if (SSOK_WorkToolsHwnd != "")
        {
            WinGetPos, wtX, wtY, wtW, wtH, ahk_id %SSOK_WorkToolsHwnd%
            if (wtX != "")
            {
                x := wtX
                y := wtY
                if (SSOK_BetaReplaceW = "")
                    betaW := wtW
                if (SSOK_BetaReplaceH = "")
                    betaH := wtH
            }
        }
    }

    if (x = "" && SSOK_SidebarHwnd != "")
    {
        WinGetPos, sideX, sideY, sideW, sideH, ahk_id %SSOK_SidebarHwnd%
        if (sideX != "")
        {
            x := sideX - betaW - 4
            y := sideY
        }
    }

    SysGet, betaWork, MonitorWorkArea
    if (x = "")
        x := betaWorkRight - betaW
    if (y = "")
        y := betaWorkTop + 80

    if (x < betaWorkLeft)
        x := betaWorkLeft
    if (x + betaW > betaWorkRight)
        x := betaWorkRight - betaW
    if (y < betaWorkTop)
        y := betaWorkTop
    if (y + betaH > betaWorkBottom)
        y := betaWorkBottom - betaH

    Gui, SSOKExpenseTools:Show, x%x% y%y% w%betaW% h%betaH%, Å×½ºÆ®¹öÀü Beta
    WinSet, AlwaysOnTop, On, ahk_id %SSOK_ExpenseToolsHwnd%
}

SSOK_Expense_Tools_ActivateTarget()
{
    global SSOK_SidebarTargetHwnd

    ; Beta Ã¢Àº ±×´ë·Î À¯ÁöÇÏ°í ½ÇÁ¦ ¾÷¹« ´ë»ó Ã¢¸¸ È°¼ºÈ­
    if (SSOK_SidebarTargetHwnd != "")
    {
        WinActivate, ahk_id %SSOK_SidebarTargetHwnd%
        Sleep, 140
    }
}

SSOK_Expense_Tools_RunWin2()
{
    ; ÇöÀç Win+2 µ¿ÀÛÀ» ±×´ë·Î ¿¬°á
    KeyWait, LWin
    KeyWait, RWin
    SendInput, {LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}
    SetKeyDelay, 80, 40
    Sleep, 150
    SendInput, {Tab 10}
    Sleep, 120
    SendInput, {Right}
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
}



; ============================================================================
; °è¾àÇöÈ²(³ª¶óÀåÅÍ) - ¾÷¹«¿ë µµ±¸ ¿¬°á ±â´É
; - ±âÁ¸ Win+1~4 ¹× ´Ù¸¥ ±âÁ¸ ±â´ÉÀº ¼öÁ¤ÇÏÁö ¾ÊÀ½
; - ±³À°Ã»¸¸ ¼±ÅÃÇÏ°í, ¼±ÅÃ Áï½Ã ÇØ´ç ±³À°Ã» ³ª¶óÀåÅÍ ÅëÇÕ»ó¼¼°Ë»ö È­¸éÀ» ¿®
; - ´Ü°è±¸ºÐ/°Ë»öÀÏÀÚ/ÆäÀÌÁö¼ö ÀÚµ¿ º¯°æ ±â´ÉÀº »ç¿ëÇÏÁö ¾ÊÀ½
; ============================================================================

SSOKG2BGuiClose:
SSOKG2BGuiEscape:
    Gui, SSOKG2B:Destroy
return

SSOK_Expense_G2B_OfficeChanged:
    global SSOK_ExpenseG2BOffice

    Gui, SSOKG2B:Submit, NoHide
    officeName := Trim(SSOK_ExpenseG2BOffice)

    ; Ã¹ ¾È³» Ç×¸ñÀº ¾Æ¹« µ¿ÀÛµµ ÇÏÁö ¾Ê½À´Ï´Ù.
    if (officeName = "" || officeName = "±³À°Ã» ¼±ÅÃ")
        return

    ; ±¤ÁÖ±¤¿ª½Ã±³À°Ã»°ú Àü¶ó³²µµ±³À°Ã»Àº ¼­·Î ´Ù¸¥ »óÀ§±â°üÄÚµåÀÔ´Ï´Ù.
    ; ÅëÇÕ ¼±ÅÃ ½Ã µÎ ±³À°Ã» °Ë»ö °á°ú¸¦ °¢°¢ »õ ÅÇÀ¸·Î ¿±´Ï´Ù.
    if (officeName = "Àü¶ó³²µµ¡¤±¤ÁÖ ÅëÇÕ")
    {
        Gui, SSOKG2B:Destroy
        SSOK_Expense_G2B_OpenByCode("7380000")
        Sleep, 250
        SSOK_Expense_G2B_OpenByCode("8490000")
        return
    }

    code := SSOK_Expense_G2B_GetOfficeCode(officeName)
    if (code = "")
    {
        ToolTip, ±³À°Ã» ±â°üÄÚµå¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.
        SetTimer, SSOKExpenseClearTip, -2200
        return
    }

    Gui, SSOKG2B:Destroy
    SSOK_Expense_G2B_OpenByCode(code)
return

SSOK_Expense_G2B_OpenByCode(code)
{
    ; »ç¿ëÀÚ°¡ Á¦°øÇÑ ¿ø·¡ ³ª¶óÀåÅÍ ¸µÅ© Çü½Ä ±×´ë·Î ±³À°Ã» ÄÚµå¸¸ ¹Ù²ß´Ï´Ù.
    url := "https://www.g2b.go.kr/link/FIUA006_01/single/?untySrchSeCd=BKOB&rowCnt=&instCd="
        . code
        . "&demaInstNm=&hghrkInstCd=" . code
        . "&prcmBsneAreaCd=%EC%A0%84%EC%B2%B4&prcmMthoSeCd=&frcpYn=N&laseYn=N&rsrvYn=N&chkInstCd=&urlSrchSeCd=hghrkInstCd"

    if IsFunc("SSOK_Tool_OpenUrlPreferred")
        Func("SSOK_Tool_OpenUrlPreferred").Call(url)
    else
        Run, %url%,, UseErrorLevel
}

SSOK_Expense_G2B_Show()
{
    global SSOK_ExpenseG2BOffice, SSOK_ExpenseG2BHwnd
    global SSOK_ExpenseToolsHwnd, SSOK_BetaReplaceX, SSOK_BetaReplaceY, SSOK_BetaReplaceW, SSOK_BetaReplaceH

    ; È£ÃâÇÑ ¾÷¹«¿ë µµ±¸ Ã¢ÀÇ ½ÇÁ¦ À§Ä¡¸¦ »ç¿ëÇØ ±³À°Ã» ¼±ÅÃÃ¢À» Ç¥½ÃÇÕ´Ï´Ù.
    x := ""
    y := ""
    betaW := ""
    betaH := ""

    if (SSOK_ExpenseToolsHwnd != "" && WinExist("ahk_id " . SSOK_ExpenseToolsHwnd))
        WinGetPos, x, y, betaW, betaH, ahk_id %SSOK_ExpenseToolsHwnd%

    if (x = "")
        x := SSOK_BetaReplaceX
    if (y = "")
        y := SSOK_BetaReplaceY
    if (betaW = "" || betaW < 170)
        betaW := (SSOK_BetaReplaceW != "" && SSOK_BetaReplaceW >= 170) ? SSOK_BetaReplaceW : 182

    Gui, SSOKExpenseTools:Destroy
    Gui, SSOKG2B:Destroy
    Gui, SSOKG2B:New, +AlwaysOnTop +ToolWindow +HwndSSOK_ExpenseG2BHwnd, ±³À°Ã» ¼±ÅÃ
    Gui, SSOKG2B:Color, F7FBFF
    Gui, SSOKG2B:Font, s8 Bold, Malgun Gothic

    innerW := betaW - 16
    if (innerW < 154)
        innerW := 166

    Gui, SSOKG2B:Add, Text, x8 y10 w%innerW% h20 +0x200, ±³À°Ã» ¼±ÅÃ
    Gui, SSOKG2B:Font, s8 Norm, Malgun Gothic

    offices := "±³À°Ã» ¼±ÅÃ||¼­¿ïÆ¯º°½Ã±³À°Ã»|ºÎ»ê±¤¿ª½Ã±³À°Ã»|´ë±¸±¤¿ª½Ã±³À°Ã»|ÀÎÃµ±¤¿ª½Ã±³À°Ã»|±¤ÁÖ±¤¿ª½Ã±³À°Ã»|´ëÀü±¤¿ª½Ã±³À°Ã»|¿ï»ê±¤¿ª½Ã±³À°Ã»|¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»|°æ±âµµ±³À°Ã»|°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»|ÃæÃ»ºÏµµ±³À°Ã»|ÃæÃ»³²µµ±³À°Ã»|ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»|Àü¶ó³²µµ±³À°Ã»|Àü¶ó³²µµ¡¤±¤ÁÖ ÅëÇÕ|°æ»óºÏµµ±³À°Ã»|°æ»ó³²µµ±³À°Ã»|Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»"
    Gui, SSOKG2B:Add, DropDownList, x8 y34 w%innerW% vSSOK_ExpenseG2BOffice gSSOK_Expense_G2B_OfficeChanged, %offices%

    Gui, SSOKG2B:Font, s7 Norm, Malgun Gothic
    Gui, SSOKG2B:Add, Text, x8 y65 w%innerW% h20 c555555, ¼±ÅÃÇÏ¸é ¹Ù·Î ³ª¶óÀåÅÍ°¡ ¿­¸³´Ï´Ù.

    if (x = "" || y = "")
        Gui, SSOKG2B:Show, w%betaW% h92 Center, ±³À°Ã» ¼±ÅÃ
    else
        Gui, SSOKG2B:Show, x%x% y%y% w%betaW% h92, ±³À°Ã» ¼±ÅÃ

    WinSet, AlwaysOnTop, On, ahk_id %SSOK_ExpenseG2BHwnd%
}

SSOK_Expense_G2B_GetOfficeCode(name)
{
    ; ½Ãµµ±³À°Ã» ±â°üÄÚµå
    if (name = "¼­¿ïÆ¯º°½Ã±³À°Ã»")
        return "7010000"
    if (name = "ºÎ»ê±¤¿ª½Ã±³À°Ã»")
        return "7150000"
    if (name = "´ë±¸±¤¿ª½Ã±³À°Ã»")
        return "7240000"
    if (name = "ÀÎÃµ±¤¿ª½Ã±³À°Ã»")
        return "7310000"
    if (name = "±¤ÁÖ±¤¿ª½Ã±³À°Ã»")
        return "7380000"
    if (name = "´ëÀü±¤¿ª½Ã±³À°Ã»")
        return "7430000"
    if (name = "¿ï»ê±¤¿ª½Ã±³À°Ã»")
        return "7480000"
    if (name = "¼¼Á¾Æ¯º°ÀÚÄ¡½Ã±³À°Ã»")
        return "9300000"
    if (name = "°æ±âµµ±³À°Ã»")
        return "7530000"
    if (name = "°­¿øÆ¯º°ÀÚÄ¡µµ±³À°Ã»")
        return "7801000"
    if (name = "ÃæÃ»ºÏµµ±³À°Ã»")
        return "8000000"
    if (name = "ÃæÃ»³²µµ±³À°Ã»")
        return "8140000"
    if (name = "ÀüºÏÆ¯º°ÀÚÄ¡µµ±³À°Ã»")
        return "8321000"
    if (name = "Àü¶ó³²µµ±³À°Ã»")
        return "8490000"
    if (name = "°æ»óºÏµµ±³À°Ã»")
        return "8750000"
    if (name = "°æ»ó³²µµ±³À°Ã»")
        return "9010000"
    if (name = "Á¦ÁÖÆ¯º°ÀÚÄ¡µµ±³À°Ã»")
        return "9290000"
    return ""
}


; ============================================================================
; ¹ýÀÎÄ«µå³»¿ªºñ±³ - 1Â÷ ±âº» UI
; ¨ç ¹ýÀÎÄ«µå»ç¿ëºÎ Excel
; ¨è ¹ýÀÎÄ«µåÀÌ¿ë³»¿ª¼­ Excel
; ÇöÀç´Â µÎ ÆÄÀÏ ÀÔ·Â/È®ÀÎ ±â´É±îÁö¸¸ ±¸Çö
; ============================================================================

SSOK_Expense_CardCompare_PasteUse:
    path := SSOK_Expense_GetCopiedFilePath()
    if (path = "")
    {
        MsgBox, 48, ¹ýÀÎÄ«µå³»¿ªºñ±³, Å½»ö±â¿¡¼­ Excel ÆÄÀÏÀ» ¸ÕÀú Ctrl+C·Î º¹»çÇÑ µÚ ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä.
        return
    }
    SSOK_CardCompareUsePath := path
    GuiControl, SSOKCardCompare:, SSOK_CardCompareUsePath, %path%
    Gosub, SSOK_Expense_CardCompare_UpdateStatus
return

SSOK_Expense_CardCompare_PasteStatement:
    path := SSOK_Expense_GetCopiedFilePath()
    if (path = "")
    {
        MsgBox, 48, ¹ýÀÎÄ«µå³»¿ªºñ±³, Å½»ö±â¿¡¼­ Excel ÆÄÀÏÀ» ¸ÕÀú Ctrl+C·Î º¹»çÇÑ µÚ ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä.
        return
    }
    SSOK_CardCompareStatementPath := path
    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatementPath, %path%
    Gosub, SSOK_Expense_CardCompare_UpdateStatus
return

SSOK_Expense_CardCompare_BrowseUse:
    FileSelectFile, picked, 3,, ¹ýÀÎÄ«µå»ç¿ëºÎ Excel ¼±ÅÃ, Excel ÆÄÀÏ (*.xlsx; *.xls)
    if (ErrorLevel)
        return
    SSOK_CardCompareUsePath := picked
    GuiControl, SSOKCardCompare:, SSOK_CardCompareUsePath, %picked%
    Gosub, SSOK_Expense_CardCompare_UpdateStatus
return

SSOK_Expense_CardCompare_BrowseStatement:
    FileSelectFile, picked, 3,, ¹ýÀÎÄ«µåÀÌ¿ë³»¿ª¼­ Excel ¼±ÅÃ, Excel ÆÄÀÏ (*.xlsx; *.xls)
    if (ErrorLevel)
        return
    SSOK_CardCompareStatementPath := picked
    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatementPath, %picked%
    Gosub, SSOK_Expense_CardCompare_UpdateStatus
return

SSOK_Expense_CardCompare_UpdateStatus:
    Gui, SSOKCardCompare:Submit, NoHide

    if (FileExist(SSOK_CardCompareUsePath) && FileExist(SSOK_CardCompareStatementPath))
        status := "A/B ÀÚ·á ÀÔ·Â ¿Ï·á"
    else if (FileExist(SSOK_CardCompareUsePath))
        status := "A ÀÚ·á ÀÔ·Â ¿Ï·á"
    else if (FileExist(SSOK_CardCompareStatementPath))
        status := "B ÀÚ·á ÀÔ·Â ¿Ï·á"
    else
        status := ""

    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatus, %status%
return


SSOK_Expense_CardCompare_Reset:
    SSOK_CardCompareUsePath := ""
    SSOK_CardCompareStatementPath := ""
    GuiControl, SSOKCardCompare:, SSOK_CardCompareUsePath, ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä
    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatementPath, ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä
    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatus,
return

SSOK_Expense_CardCompare_Check:
    Gui, SSOKCardCompare:Submit, NoHide

    if (!FileExist(SSOK_CardCompareUsePath))
    {
        MsgBox, 48, ¹ýÀÎÄ«µå³»¿ªºñ±³, ¹ýÀÎÄ«µå»ç¿ëºÎ ExcelÀ» ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }

    if (!FileExist(SSOK_CardCompareStatementPath))
    {
        MsgBox, 48, ¹ýÀÎÄ«µå³»¿ªºñ±³, ¹ýÀÎÄ«µåÀÌ¿ë³»¿ª¼­ ExcelÀ» ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }

    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatus, ºñ±³ ÀÛ¾÷ÁßÀÔ´Ï´Ù. Àá½Ã¸¸ ±â´Ù·Á ÁÖ¼¼¿ä.

    if !SSOK_Expense_CardCompare_Run(SSOK_CardCompareUsePath, SSOK_CardCompareStatementPath, outputPath, report, errMsg)
    {
        GuiControl, SSOKCardCompare:, SSOK_CardCompareStatus, ºñ±³ ½ÇÆÐ
        MsgBox, 48, ¹ýÀÎÄ«µå³»¿ªºñ±³, %errMsg%
        return
    }

    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatus, ºñ±³ ¿Ï·á - °á°ú ExcelÀ» ¿­¾ú½À´Ï´Ù.
    Run, %outputPath%,, UseErrorLevel
return

SSOKCardCompareGuiDropFiles:
    ; Å½»ö±â¿¡¼­ Excel ÆÄÀÏÀ» GUI/ÀÔ·ÂÄ­À¸·Î ²ø¾î ³õÀ¸¸é ÀÚµ¿ µî·Ï
    SSOK_Expense_CardCompare_HandleDrop(A_GuiEvent, A_GuiControl)
return

SSOKCardCompareGuiClose:
SSOKCardCompareGuiEscape:
    Gui, SSOKCardCompare:Destroy
return

SSOKCardCompareOpenKEdufine:
    Run, https://sje.eduptl.kr/bpm_lgn_lg00_001.do?noEpSession
return

SSOKCardCompareOpenNHBizCard:
    Run, https://nhbizcard.nonghyup.com/icpm01.menu
return

SSOK_Expense_CardCompare_Show()
{
    global SSOK_CardCompareUsePath, SSOK_CardCompareStatementPath
    global SSOK_CardCompareStatus

    Gui, SSOKCardCompare:Destroy
    Gui, SSOKCardCompare:New, +ToolWindow, ¹ýÀÎÄ«µå »ç¿ë ³»¿ª ºñ±³ ÀÚµ¿ ÀÛ¼º
    Gui, SSOKCardCompare:Margin, 20, 18
    Gui, SSOKCardCompare:Color, F7FBFF

    Gui, SSOKCardCompare:Font, s12 Bold, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, w760 h30, ¹ýÀÎÄ«µå »ç¿ë ³»¿ª ºñ±³ ÀÚµ¿ ÀÛ¼º

    ; A ¹ýÀÎÄ«µå»ç¿ëºÎ
    Gui, SSOKCardCompare:Font, s10 Bold, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x20 y+18 w760 h24 +0x200, A ¹ýÀÎÄ«µå»ç¿ëºÎ

    Gui, SSOKCardCompare:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x20 y+2 w650 h24 c555555, ±Ù°ÅÀÚ·á: ÇÐ±³È¸°è-ÁöÃâ°ü¸®-±âÅ¸°ü¸®-¹ýÀÎÄ«µå»ç¿ëºÎ
    Gui, SSOKCardCompare:Font, s9 Underline, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x690 yp w90 h24 +0x200 c0066CC gSSOKCardCompareOpenKEdufine, ¹Ù·Î°¡±â
    Gui, SSOKCardCompare:Font, s9 Norm, Malgun Gothic

    useDisplay := FileExist(SSOK_CardCompareUsePath) ? SSOK_CardCompareUsePath : "ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä"
    Gui, SSOKCardCompare:Add, Text, x20 y+8 w760 h76 +Border Center 0x200 vSSOK_CardCompareUsePath c555555, %useDisplay%

    ; B ¹ýÀÎÄ«µå ÀÌ¿ë³»¿ª¼­
    Gui, SSOKCardCompare:Font, s10 Bold, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x20 y+24 w760 h24 +0x200, B ¹ýÀÎÄ«µå ÀÌ¿ë³»¿ª¼­

    Gui, SSOKCardCompare:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x20 y+2 w650 h24 c555555, ±Ù°ÅÀÚ·á: ³óÇù ÀÎÅÍ³Ý¹ðÅ· - ¿ùº° ÀÌ¿ë³»¿ª¼­ ¿¢¼¿ ÀÚ·á ´Ù¿î·Îµå
    Gui, SSOKCardCompare:Font, s9 Underline, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x690 yp w90 h24 +0x200 c0066CC gSSOKCardCompareOpenNHBizCard, ¹Ù·Î°¡±â
    Gui, SSOKCardCompare:Font, s9 Norm, Malgun Gothic

    statementDisplay := FileExist(SSOK_CardCompareStatementPath) ? SSOK_CardCompareStatementPath : "ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä"
    Gui, SSOKCardCompare:Add, Text, x20 y+8 w760 h76 +Border Center 0x200 vSSOK_CardCompareStatementPath c555555, %statementDisplay%

    ; »óÅÂ
    Gui, SSOKCardCompare:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x20 y+20 w760 h30 +0x200 vSSOK_CardCompareStatus c005BAC,

    ; ÇÏ´Ü ¹öÆ°
    Gui, SSOKCardCompare:Add, Button, x20 y+12 w180 h40 gSSOK_Expense_CardCompare_Reset, ÃÊ±âÈ­
    Gui, SSOKCardCompare:Add, Button, x214 yp w180 h40 gSSOK_Expense_CardCompare_Check Default, ÀÛ¾÷½ÇÇà

    Gui, SSOKCardCompare:Show, w800 h500 Center
}

; ============================================================================
; ¹ýÀÎÄ«µå³»¿ªºñ±³ - ½ÇÁ¦ ºñ±³ Ã³¸®
; - ¿øº» Excel 2°³´Â ÀÐ±â Àü¿ëÀ¸·Î ¿­¸ç Àý´ë ¼öÁ¤ÇÏÁö ¾Ê½À´Ï´Ù.
; - »ç¿ëºÎ: ¿øÀÎÇàÀ§ÀÏÀÚ + ÃÑ»ç¿ë±Ý¾×(¾øÀ¸¸é ¿øÀÎÇàÀ§±Ý¾×)
; - ¸í¼¼¼­: ÀÌ¿ëÀÏÀÚ + ÀÌ¿ëÄ«µå + ÀÌ¿ë°¡¸ÍÁ¡ + Ã»±¸¿ø±Ý
; - 1:1 ±Ý¾× ÀÏÄ¡ -> ±ÙÁ¢ÀÏÀÚ(¡¾3ÀÏ) -> µ¿ÀÏ¾÷Ã¼ ÇÕ»ê -> µ¿ÀÏÄ«µå/ÀÏÀÚ ÇÕ»ê
; - ³²Àº µ¿ÀÏÀÏÀÚ 1:1Àº "±Ý¾× »óÀÌ", ³ª¸ÓÁö´Â "ÇÑÂÊ¸¸ ÀÖÀ½"À¸·Î Ç¥½Ã
; ============================================================================

SSOK_Expense_CardCompare_Run(usePath, statementPath, ByRef outputPath, ByRef report, ByRef errMsg)
{
    outputPath := ""
    report := ""
    errMsg := ""

    xl := ""
    wbUse := ""
    wbStatement := ""
    wbOut := ""
    wsResult := ""
    wsDaily := ""
    stage := "Excel ½ÇÇà"

    try
    {
        stage := "Excel ½ÇÇà"
        xl := ComObjCreate("Excel.Application")
        xl.Visible := false
        xl.DisplayAlerts := false
        xl.EnableEvents := false
        xl.AskToUpdateLinks := false
        try xl.ScreenUpdating := false
        try xl.DisplayStatusBar := false
        try xl.Calculation := -4135  ; xlCalculationManual
        try xl.AutomationSecurity := 3

        stage := "¹ýÀÎÄ«µå»ç¿ëºÎ ¿­±â"
        wbUse := xl.Workbooks.Open(usePath, 0, true)

        stage := "ÀÌ¿ë´ë±Ý¸í¼¼¼­ ¿­±â"
        wbStatement := xl.Workbooks.Open(statementPath, 0, true)

        stage := "¹ýÀÎÄ«µå»ç¿ëºÎ ÀÐ±â"
        if !SSOK_Expense_CardCompare_ReadUseBook(wbUse, useRows, useErr)
        {
            errMsg := "¹ýÀÎÄ«µå»ç¿ëºÎ¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù.`n`n" . useErr
            return false
        }

        stage := "ÀÌ¿ë´ë±Ý¸í¼¼¼­ ÀÐ±â"
        if !SSOK_Expense_CardCompare_ReadStatementBook(wbStatement, statementRows, statementErr)
        {
            errMsg := "ÀÌ¿ë´ë±Ý¸í¼¼¼­¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù.`n`n" . statementErr
            return false
        }

        stage := "³»¿ª ºñ±³"
        SSOK_Expense_CardCompare_SortUseRows(useRows)
        results := SSOK_Expense_CardCompare_Match(useRows, statementRows)

        useTotal := 0
        for _, row in useRows
            useTotal += row.amount

        statementTotal := 0
        for _, row in statementRows
            statementTotal += row.amount

        mismatchCount := 0
        groupCount := 0
        nearDateCount := 0

        for _, row in results
        {
            if (row.status != "ÀÏÄ¡")
                mismatchCount++

            if InStr(row.matchType, "ÇÕ»ê")
                groupCount++

            if (row.dateDiff > 0 && row.status = "ÀÏÄ¡")
                nearDateCount++
        }

        outputPath := SSOK_Expense_CardCompare_BuildOutputPath(usePath, useRows)

        ; Excel È¯°æº° ±âº» ½ÃÆ® ¼ö ¼³Á¤ÀÇ ¿µÇâÀ» ¹ÞÁö ¾Êµµ·Ï
        ; ÀÎ¼ö ¾ø´Â Workbooks.Add()·Î »õ ÅëÇÕ¹®¼­¸¦ ¸¸µì´Ï´Ù.
        stage := "°á°ú ÅëÇÕ¹®¼­ ¸¸µé±â"
        wbOut := xl.Workbooks.Add()

        stage := "°á°ú ½ÃÆ® ÁØºñ"
        wsResult := wbOut.Worksheets(1)
        wsResult.Name := "ºñ±³°á°ú"

        if (wbOut.Worksheets.Count >= 2)
        {
            wsDaily := wbOut.Worksheets(2)
            wsDaily.Name := "ÀÏÀÚº°¿ä¾à"
        }
        else
        {
            wsDaily := wbOut.Worksheets.Add()
            wsDaily.Name := "ÀÏÀÚº°¿ä¾à"
        }

        ; Excel ¼³Á¤¿¡ µû¶ó ±âº» ½ÃÆ®°¡ 3°³ ÀÌ»ó ¸¸µé¾îÁö´Â °æ¿ì
        ; ºñ±³°á°ú/ÀÏÀÚº°¿ä¾à ÀÌ¿Ü ½ÃÆ®¸¸ Á¦°ÅÇÕ´Ï´Ù.
        while (wbOut.Worksheets.Count > 2)
        {
            extraSheet := wbOut.Worksheets(wbOut.Worksheets.Count)
            extraSheet.Delete()
        }

        global SSOK_CardCompareWriteStage
        SSOK_CardCompareWriteStage := ""

        stage := "ºñ±³°á°ú ½ÃÆ® ÀÛ¼º"
        SSOK_Expense_CardCompare_WriteResultSheet(wsResult, results
            , useTotal, statementTotal, groupCount, nearDateCount, mismatchCount)

        SSOK_CardCompareWriteStage := ""
        stage := "ÀÏÀÚº°¿ä¾à ½ÃÆ® ÀÛ¼º"
        SSOK_Expense_CardCompare_WriteDailySheet(wsDaily, results
            , useTotal, statementTotal, mismatchCount)

        SSOK_CardCompareWriteStage := ""

        stage := "°á°ú Excel ÀúÀå"
        ; 51 = xlOpenXMLWorkbook (.xlsx)
        wbOut.SaveAs(outputPath, 51)

        stage := "¿Ï·á"
        report := "ºñ±³°¡ ¿Ï·áµÇ¾ú½À´Ï´Ù."
        report .= "`n`n»ç¿ëºÎ: " . useRows.Length() . "°Ç / " . SSOK_Expense_CardCompare_FormatMoney(useTotal) . "¿ø"
        report .= "`n¸í¼¼¼­: " . statementRows.Length() . "°Ç / " . SSOK_Expense_CardCompare_FormatMoney(statementTotal) . "¿ø"
        report .= "`nÇÕ»êÀ¸·Î ¸ÂÃá »ç¿ëºÎ Ç×¸ñ: " . groupCount . "°Ç"
        report .= "`n±ÙÁ¢ÀÏÀÚ·Î ¸ÂÃá Ç×¸ñ: " . nearDateCount . "°Ç"
        report .= "`nÈ®ÀÎ ÇÊ¿äÇÑ Ç×¸ñ: " . mismatchCount . "°Ç"
        report .= "`n`n°á°úÆÄÀÏ:`n" . outputPath

        return true
    }
    catch e
    {
        errMsg := "ºñ±³ Áß ¿À·ù°¡ ¹ß»ýÇß½À´Ï´Ù."
        errMsg .= "`n`n¿À·ù ´Ü°è: " . stage

        global SSOK_CardCompareWriteStage
        if (SSOK_CardCompareWriteStage != "")
            errMsg .= "`n¼¼ºÎ ´Ü°è: " . SSOK_CardCompareWriteStage

        errMsg .= "`n`n" . e.Message
        return false
    }
    finally
    {
        try
        {
            if IsObject(wbOut)
                wbOut.Close(false)
        }

        try
        {
            if IsObject(wbUse)
                wbUse.Close(false)
        }

        try
        {
            if IsObject(wbStatement)
                wbStatement.Close(false)
        }

        try
        {
            if IsObject(xl)
                xl.Quit()
        }

        wsResult := ""
        wsDaily := ""
        wbOut := ""
        wbUse := ""
        wbStatement := ""
        xl := ""
    }
}

SSOK_Expense_CardCompare_ReadUseBook(wb, ByRef rows, ByRef errMsg)
{
    rows := []
    errMsg := ""

    Loop, % wb.Worksheets.Count
    {
        ws := wb.Worksheets(A_Index)

        if !SSOK_Expense_CardCompare_FindUseColumns(ws, headerRow, cols)
            continue

        used := ws.UsedRange
        lastRow := used.Row + used.Rows.Count - 1

        Loop, % lastRow - headerRow
        {
            r := headerRow + A_Index
            requestVal := SSOK_Expense_CardCompare_CellText(ws.Cells(r, cols.request))
            title := SSOK_Expense_CardCompare_CellText(ws.Cells(r, cols.title))

            if (requestVal = "ÇÕ°è" || title = "ÇÕ°è")
                continue

            dateKey := SSOK_Expense_CardCompare_DateKey(ws.Cells(r, cols.date).Value2)
            if (dateKey = "")
                continue

            amount := SSOK_Expense_CardCompare_Amount(ws.Cells(r, cols.amount).Value2)
            if (amount = "")
                continue

            if (amount = 0)
                continue

            rows.Push({date:dateKey
                , request:requestVal
                , title:title
                , causeNo:(cols.causeNo ? SSOK_Expense_CardCompare_CellText(ws.Cells(r, cols.causeNo)) : "")
                , amount:amount})
        }

        if (rows.Length())
            return true
    }

    errMsg := "¿­ Á¦¸ñ '¿øÀÎÇàÀ§ÀÏÀÚ', 'Á¦¸ñ', 'ÃÑ»ç¿ë±Ý¾×'À» Ã£Áö ¸øÇß°Å³ª ºñ±³ÇÒ µ¥ÀÌÅÍ°¡ ¾ø½À´Ï´Ù."
    return false
}

SSOK_Expense_CardCompare_ReadStatementBook(wb, ByRef rows, ByRef errMsg)
{
    rows := []
    errMsg := ""

    Loop, % wb.Worksheets.Count
    {
        ws := wb.Worksheets(A_Index)

        if !SSOK_Expense_CardCompare_FindStatementColumns(ws, headerRow, cols)
            continue

        used := ws.UsedRange
        lastRow := used.Row + used.Rows.Count - 1

        Loop, % lastRow - headerRow
        {
            r := headerRow + A_Index

            dateKey := SSOK_Expense_CardCompare_DateKey(ws.Cells(r, cols.date).Value2)
            if (dateKey = "")
                continue

            amount := SSOK_Expense_CardCompare_Amount(ws.Cells(r, cols.amount).Value2)
            if (amount = "" || amount = 0)
                continue

            merchant := SSOK_Expense_CardCompare_CellText(ws.Cells(r, cols.merchant))
            card := SSOK_Expense_CardCompare_CellText(ws.Cells(r, cols.card))

            rows.Push({date:dateKey
                , card:card
                , merchant:merchant
                , merchantKey:SSOK_Expense_CardCompare_NormalizeMerchant(merchant)
                , amount:amount
                , used:false})
        }

        if (rows.Length())
            return true
    }

    errMsg := "¿­ Á¦¸ñ 'ÀÌ¿ëÀÏÀÚ', 'ÀÌ¿ëÄ«µå', 'ÀÌ¿ë°¡¸ÍÁ¡', 'Ã»±¸¿ø±Ý'À» Ã£Áö ¸øÇß°Å³ª ºñ±³ÇÒ µ¥ÀÌÅÍ°¡ ¾ø½À´Ï´Ù."
    return false
}

SSOK_Expense_CardCompare_FindUseColumns(ws, ByRef headerRow, ByRef cols)
{
    cols := {date:0, title:0, amount:0, request:0, causeNo:0}
    used := ws.UsedRange

    firstRow := used.Row
    firstCol := used.Column
    maxRows := used.Rows.Count
    maxCols := used.Columns.Count

    if (maxRows > 80)
        maxRows := 80
    if (maxCols > 40)
        maxCols := 40

    Loop, %maxRows%
    {
        r := firstRow + A_Index - 1
        temp := {date:0, title:0, amount:0, fallbackAmount:0, request:0, causeNo:0}

        Loop, %maxCols%
        {
            c := firstCol + A_Index - 1
            key := SSOK_Expense_CardCompare_HeaderKey(SSOK_Expense_CardCompare_CellText(ws.Cells(r, c)))

            if (key = "¿øÀÎÇàÀ§ÀÏÀÚ")
                temp.date := c
            else if (key = "Á¦¸ñ")
                temp.title := c
            else if (key = "ÃÑ»ç¿ë±Ý¾×")
                temp.amount := c
            else if (key = "¿øÀÎÇàÀ§±Ý¾×")
                temp.fallbackAmount := c
            else if (key = "½ÅÃ»¹øÈ£")
                temp.request := c
            else if (key = "¿øÀÎÇàÀ§¹øÈ£")
                temp.causeNo := c
        }

        if (!temp.amount)
            temp.amount := temp.fallbackAmount

        if (temp.date && temp.title && temp.amount)
        {
            headerRow := r
            cols := temp
            return true
        }
    }

    return false
}

SSOK_Expense_CardCompare_FindStatementColumns(ws, ByRef headerRow, ByRef cols)
{
    cols := {date:0, card:0, merchant:0, amount:0}
    used := ws.UsedRange

    firstRow := used.Row
    firstCol := used.Column
    maxRows := used.Rows.Count
    maxCols := used.Columns.Count

    if (maxRows > 100)
        maxRows := 100
    if (maxCols > 50)
        maxCols := 50

    Loop, %maxRows%
    {
        r := firstRow + A_Index - 1
        temp := {date:0, card:0, merchant:0, amount:0}

        Loop, %maxCols%
        {
            c := firstCol + A_Index - 1
            key := SSOK_Expense_CardCompare_HeaderKey(SSOK_Expense_CardCompare_CellText(ws.Cells(r, c)))

            if (key = "ÀÌ¿ëÀÏÀÚ")
                temp.date := c
            else if (key = "ÀÌ¿ëÄ«µå")
                temp.card := c
            else if InStr(key, "ÀÌ¿ë°¡¸ÍÁ¡")
                temp.merchant := c
            else if (key = "Ã»±¸¿ø±Ý")
                temp.amount := c
        }

        if (temp.date && temp.card && temp.merchant && temp.amount)
        {
            headerRow := r
            cols := temp
            return true
        }
    }

    return false
}

SSOK_Expense_CardCompare_Match(useRows, statementRows)
{
    results := []
    unmatchedUse := []

    for _, useRow in useRows
    {
        idx := SSOK_Expense_CardCompare_FindSingle(statementRows, useRow.amount, useRow.date, 0)
        if (idx)
        {
            ids := [idx]
            results.Push(SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, "1:1 ÀÏÄ¡"))
            continue
        }

        idx := SSOK_Expense_CardCompare_FindSingle(statementRows, useRow.amount, useRow.date, 3)
        if (idx)
        {
            ids := [idx]
            results.Push(SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, "1:1 ÀÏÄ¡(±ÙÁ¢ÀÏÀÚ)"))
            continue
        }

        ids := SSOK_Expense_CardCompare_FindGroup(statementRows, useRow.date, useRow.amount, "merchant", 0)
        if IsObject(ids)
        {
            results.Push(SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, "ÇÕ»ê ÀÏÄ¡(µ¿ÀÏ¾÷Ã¼)"))
            continue
        }

        ids := SSOK_Expense_CardCompare_FindGroup(statementRows, useRow.date, useRow.amount, "card", 0)
        if IsObject(ids)
        {
            results.Push(SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, "ÇÕ»ê ÀÏÄ¡(µ¿ÀÏÄ«µå/ÀÏÀÚ)"))
            continue
        }

        ; »ç¿ëÀÚ°¡ ¿äÃ»ÇÑ "ºñ½ÁÇÑ °áÀçÀÏ" ÇÕ»ê:
        ; °°Àº ¾÷Ã¼/Ä«µåÀÇ ¸í¼¼¼­ °ÇµéÀÌ ¡¾3ÀÏ ¾È¿¡ ÀÖ°í ÇÕ°è°¡ »ç¿ëºÎ ±Ý¾×°ú °°À¸¸é ÀÏÄ¡ Ã³¸®
        ids := SSOK_Expense_CardCompare_FindGroup(statementRows, useRow.date, useRow.amount, "merchant", 3)
        if IsObject(ids)
        {
            results.Push(SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, "ÇÕ»ê ÀÏÄ¡(µ¿ÀÏ¾÷Ã¼/±ÙÁ¢ÀÏÀÚ)"))
            continue
        }

        ids := SSOK_Expense_CardCompare_FindGroup(statementRows, useRow.date, useRow.amount, "card", 3)
        if IsObject(ids)
        {
            results.Push(SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, "ÇÕ»ê ÀÏÄ¡(µ¿ÀÏÄ«µå/±ÙÁ¢ÀÏÀÚ)"))
            continue
        }

        unmatchedUse.Push(useRow)
    }

    ; °°Àº ³¯Â¥¿¡ ¾çÂÊ¿¡¼­ µü 1°Ç¾¿ ³²À¸¸é ±Ý¾× »óÀÌ·Î Á÷Á¢ ºñ±³
    handled := {}

    for ui, useRow in unmatchedUse
    {
        useSameDateCount := 0
        for _, otherUse in unmatchedUse
        {
            if (otherUse.date = useRow.date)
                useSameDateCount++
        }

        statementIdx := 0
        statementSameDateCount := 0

        for si, statementRow in statementRows
        {
            if (!statementRow.used && statementRow.date = useRow.date)
            {
                statementSameDateCount++
                statementIdx := si
            }
        }

        if (useSameDateCount = 1 && statementSameDateCount = 1)
        {
            ids := [statementIdx]
            row := SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, "°°Àº ÀÏÀÚ È®ÀÎ")
            row.status := "±Ý¾× »óÀÌ"
            row.note := "°°Àº ÀÏÀÚ¿¡ ¾çÂÊ 1°Ç¾¿ ³²¾Æ ±Ý¾× ºñ±³"
            results.Push(row)
            handled[ui] := true
        }
    }

    for ui, useRow in unmatchedUse
    {
        if (handled.HasKey(ui))
            continue

        results.Push({status:"»ç¿ëºÎ¸¸ ÀÖÀ½"
            , useDate:useRow.date
            , title:useRow.title
            , useAmount:useRow.amount
            , matchType:"¹Ì¸ÅÄª"
            , statementDate:""
            , card:""
            , merchant:""
            , statementAmount:""
            , diff:useRow.amount
            , note:"ÀÌ¿ë´ë±Ý¸í¼¼¼­¿¡¼­ ´ëÀÀ ±Ý¾×À» Ã£Áö ¸øÇÔ"
            , dateDiff:0})
    }

    for _, statementRow in statementRows
    {
        if (statementRow.used)
            continue

        results.Push({status:"¸í¼¼¼­¸¸ ÀÖÀ½"
            , useDate:""
            , title:""
            , useAmount:""
            , matchType:"¹Ì¸ÅÄª"
            , statementDate:statementRow.date
            , card:statementRow.card
            , merchant:statementRow.merchant
            , statementAmount:statementRow.amount
            , diff:0 - statementRow.amount
            , note:"¹ýÀÎÄ«µå»ç¿ëºÎ¿¡¼­ ´ëÀÀ ±Ý¾×À» Ã£Áö ¸øÇÔ"
            , dateDiff:0})
    }

    SSOK_Expense_CardCompare_SortResults(results)
    return results
}

SSOK_Expense_CardCompare_FindSingle(statementRows, targetAmount, targetDate, maxDays)
{
    bestIdx := 0
    bestDiff := 999999

    for idx, row in statementRows
    {
        if (row.used || row.amount != targetAmount)
            continue

        diff := SSOK_Expense_CardCompare_DateDiff(row.date, targetDate)

        if (diff > maxDays)
            continue

        if (diff < bestDiff)
        {
            bestDiff := diff
            bestIdx := idx
        }
    }

    return bestIdx
}

SSOK_Expense_CardCompare_FindGroup(statementRows, targetDate, targetAmount, mode, maxDays := 0)
{
    groups := {}

    for idx, row in statementRows
    {
        if (row.used)
            continue

        if (SSOK_Expense_CardCompare_DateDiff(row.date, targetDate) > maxDays)
            continue

        if (mode = "merchant")
            key := row.merchantKey
        else
            key := row.card

        if (key = "")
            continue

        if !groups.HasKey(key)
            groups[key] := []

        groups[key].Push(idx)
    }

    for _, ids in groups
    {
        if (ids.Length() < 2)
            continue

        total := 0
        for _, idx in ids
            total += statementRows[idx].amount

        if (total = targetAmount)
            return ids
    }

    return ""
}

SSOK_Expense_CardCompare_MakeMatch(useRow, statementRows, ids, matchType)
{
    total := 0
    maxDateDiff := 0
    dates := []
    cards := []
    merchants := []

    for _, idx in ids
    {
        row := statementRows[idx]
        statementRows[idx].used := true

        total += row.amount

        d := SSOK_Expense_CardCompare_DateDiff(useRow.date, row.date)
        if (d > maxDateDiff)
            maxDateDiff := d

        SSOK_Expense_CardCompare_ArrayPushUnique(dates, row.date)
        SSOK_Expense_CardCompare_ArrayPushUnique(cards, row.card)
        SSOK_Expense_CardCompare_ArrayPushUnique(merchants, row.merchant)
    }

    note := ""

    if (ids.Length() > 1)
        note := "¸í¼¼¼­ " . ids.Length() . "°Ç ÇÕ»ê"

    if (maxDateDiff > 0)
    {
        if (note != "")
            note .= " / "

        note .= "ÀÌ¿ëÀÏÀÚ " . maxDateDiff . "ÀÏ Â÷ÀÌ"
    }

    return {status:(useRow.amount = total ? "ÀÏÄ¡" : "±Ý¾× »óÀÌ")
        , useDate:useRow.date
        , title:useRow.title
        , useAmount:useRow.amount
        , matchType:matchType
        , statementDate:SSOK_Expense_CardCompare_Join(dates, " / ")
        , card:SSOK_Expense_CardCompare_Join(cards, " / ")
        , merchant:SSOK_Expense_CardCompare_Join(merchants, " / ")
        , statementAmount:total
        , diff:useRow.amount - total
        , note:note
        , dateDiff:maxDateDiff}
}

SSOK_Expense_CardCompare_WriteResultSheet(ws, results, useTotal, statementTotal, groupCount, nearDateCount, mismatchCount)
{
    global SSOK_CardCompareWriteStage

    headers := ["»óÅÂ","»ç¿ëºÎÀÏÀÚ","Á¦¸ñ","»ç¿ëºÎ±Ý¾×","¸ÅÄªÀ¯Çü","¸í¼¼¼­ÀÏÀÚ","ÀÌ¿ëÄ«µå","ÀÌ¿ë°¡¸ÍÁ¡","¸í¼¼¼­±Ý¾×","Â÷¾×","ºñ°í"]

    ; --------------------------------------------------------
    ; ÇÙ½É µ¥ÀÌÅÍ ¾²±â
    ; Excel COM È£È¯¼ºÀ» À§ÇØ ¹®ÀÚ¿­/¼ýÀÚ ¸ðµÎ Value2¸¸ »ç¿ëÇÕ´Ï´Ù.
    ; --------------------------------------------------------
    SSOK_CardCompareWriteStage := "Á¦¸ñ ÀÔ·Â"
    ws.Cells(1,1).Value2 := "¹ýÀÎÄ«µå »ç¿ëºÎ - ÀÌ¿ë´ë±Ý¸í¼¼¼­ ºñ±³"

    SSOK_CardCompareWriteStage := "¿ä¾à°ª ÀÔ·Â"
    ws.Cells(3,1).Value2 := "»ç¿ëºÎ ÃÑ¾×"
    ws.Cells(3,2).Value2 := useTotal
    ws.Cells(3,3).Value2 := "¸í¼¼¼­ ÃÑ¾×"
    ws.Cells(3,4).Value2 := statementTotal
    ws.Cells(3,5).Value2 := "ÃÑ¾× Â÷ÀÌ"
    ws.Cells(3,6).Value2 := useTotal - statementTotal
    ws.Cells(3,7).Value2 := "ÇÕ»ê¸ÅÄª"
    ws.Cells(3,8).Value2 := groupCount
    ws.Cells(3,9).Value2 := "±ÙÁ¢ÀÏÀÚ"
    ws.Cells(3,10).Value2 := nearDateCount
    ws.Cells(3,11).Value2 := "È®ÀÎÇÊ¿ä"
    ws.Cells(3,12).Value2 := mismatchCount

    SSOK_CardCompareWriteStage := "¿­ Á¦¸ñ ÀÔ·Â"
    for c, header in headers
        ws.Cells(6,c).Value2 := header

    r := 7

    for _, row in results
    {
        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà »óÅÂ"
        ws.Cells(r,1).Value2 := row.status

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà »ç¿ëºÎÀÏÀÚ"
        ws.Cells(r,2).Value2 := SSOK_Expense_CardCompare_DateDisplay(row.useDate)

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà Á¦¸ñ"
        ws.Cells(r,3).Value2 := row.title . ""

        if (row.useAmount != "")
        {
            SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà »ç¿ëºÎ±Ý¾×"
            ws.Cells(r,4).Value2 := row.useAmount
        }

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà ¸ÅÄªÀ¯Çü"
        ws.Cells(r,5).Value2 := row.matchType . ""

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà ¸í¼¼¼­ÀÏÀÚ"
        if (InStr(row.statementDate, " / "))
            ws.Cells(r,6).Value2 := SSOK_Expense_CardCompare_DateListDisplay(row.statementDate)
        else
            ws.Cells(r,6).Value2 := SSOK_Expense_CardCompare_DateDisplay(row.statementDate)

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà ÀÌ¿ëÄ«µå"
        ws.Cells(r,7).Value2 := row.card . ""

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà ÀÌ¿ë°¡¸ÍÁ¡"
        ws.Cells(r,8).Value2 := row.merchant . ""

        if (row.statementAmount != "")
        {
            SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà ¸í¼¼¼­±Ý¾×"
            ws.Cells(r,9).Value2 := row.statementAmount
        }

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà Â÷¾×"
        ws.Cells(r,10).Value2 := row.diff

        SSOK_CardCompareWriteStage := "ºñ±³°á°ú " . r . "Çà ºñ°í"
        ws.Cells(r,11).Value2 := row.note . ""

        r++
    }

    lastRow := r - 1

    ; --------------------------------------------------------
    ; ¼­½ÄÀº ÇÙ½É ±â´ÉÀÌ ¾Æ´Ï¹Ç·Î Excel ¹öÀü/È¯°æ¿¡ µû¶ó ½ÇÆÐÇØµµ ¹«½Ã
    ; --------------------------------------------------------
    SSOK_CardCompareWriteStage := "ºñ±³°á°ú ¼­½Ä"

    try ws.Range("A1:K1").Merge()
    try ws.Range("A1:K1").Interior.ColorIndex := 23
    try ws.Range("A1:K1").Font.ColorIndex := 2
    try ws.Range("A1:K1").Font.Bold := true
    try ws.Range("A1:K1").Font.Size := 14
    try ws.Range("A1:K1").HorizontalAlignment := -4108
    try ws.Rows(1).RowHeight := 27

    try ws.Range("A3:L3").Interior.ColorIndex := 36
    try ws.Range("A3:L3").Font.Bold := true
    try ws.Range("B3").NumberFormat := "#,##0"
    try ws.Range("D3").NumberFormat := "#,##0"
    try ws.Range("F3").NumberFormat := "#,##0"

    try ws.Range("A6:K6").Interior.ColorIndex := 23
    try ws.Range("A6:K6").Font.ColorIndex := 2
    try ws.Range("A6:K6").Font.Bold := true
    try ws.Range("A6:K6").HorizontalAlignment := -4108

    if (lastRow >= 7)
    {
        try ws.Range("D7:D" . lastRow).NumberFormat := "#,##0"
        try ws.Range("I7:J" . lastRow).NumberFormat := "#,##0"
        try ws.Range("A6:K" . lastRow).Borders.LineStyle := 1
        try ws.Range("A6:K" . lastRow).VerticalAlignment := -4108
        try ws.Range("C7:C" . lastRow).WrapText := true
        try ws.Range("H7:H" . lastRow).WrapText := true
        try ws.Range("K7:K" . lastRow).WrapText := true

        for rr, row in results
        {
            excelRow := rr + 6
            if (row.status != "ÀÏÄ¡")
                try ws.Range("A" . excelRow . ":K" . excelRow).Interior.ColorIndex := 38
        }

        try ws.Range("A6:K" . lastRow).AutoFilter()
    }

    try ws.Columns("A").ColumnWidth := 15
    try ws.Columns("B").ColumnWidth := 13
    try ws.Columns("C").ColumnWidth := 45
    try ws.Columns("D").ColumnWidth := 14
    try ws.Columns("E").ColumnWidth := 22
    try ws.Columns("F").ColumnWidth := 18
    try ws.Columns("G").ColumnWidth := 12
    try ws.Columns("H").ColumnWidth := 32
    try ws.Columns("I").ColumnWidth := 14
    try ws.Columns("J").ColumnWidth := 14
    try ws.Columns("K").ColumnWidth := 28

    SSOK_CardCompareWriteStage := ""
}

SSOK_Expense_CardCompare_WriteDailySheet(ws, results, useTotal, statementTotal, mismatchCount)
{
    global SSOK_CardCompareWriteStage

    daily := {}

    for _, row in results
    {
        if (row.useDate != "")
            key := row.useDate
        else
            key := SSOK_Expense_CardCompare_FirstDateKey(row.statementDate)

        if (key = "")
            continue

        if !daily.HasKey(key)
            daily[key] := {useAmount:0, statementAmount:0, issues:0, dateDiff:0}

        item := daily[key]

        if (row.useAmount != "")
            item.useAmount += row.useAmount

        if (row.statementAmount != "")
            item.statementAmount += row.statementAmount

        if (row.status != "ÀÏÄ¡")
            item.issues++

        if (row.dateDiff > 0)
            item.dateDiff++

        daily[key] := item
    }

    SSOK_CardCompareWriteStage := "ÀÏÀÚº°¿ä¾à Á¦¸ñ ÀÔ·Â"
    ws.Cells(1,1).Value2 := "ÀÏÀÚº° ¹ýÀÎÄ«µå ºñ±³ ¿ä¾à"

    SSOK_CardCompareWriteStage := "ÀÏÀÚº°¿ä¾à ÃÑ¾× ÀÔ·Â"
    ws.Cells(3,1).Value2 := "»ç¿ëºÎ ÃÑ¾×"
    ws.Cells(3,2).Value2 := useTotal
    ws.Cells(3,3).Value2 := "¸í¼¼¼­ ÃÑ¾×"
    ws.Cells(3,4).Value2 := statementTotal
    ws.Cells(3,5).Value2 := "ÃÑ¾× Â÷ÀÌ"
    ws.Cells(3,6).Value2 := useTotal - statementTotal

    headers := ["±âÁØÀÏ","»ç¿ëºÎ ÇÕ°è","¸ÅÄª ¸í¼¼¼­ ÇÕ°è","Â÷¾×","»óÅÂ","ÀÏÀÚÂ÷ÀÌ °Ç¼ö"]

    SSOK_CardCompareWriteStage := "ÀÏÀÚº°¿ä¾à ¿­ Á¦¸ñ ÀÔ·Â"
    for c, header in headers
        ws.Cells(6,c).Value2 := header

    keyText := ""
    for key, _ in daily
        keyText .= key . "`n"

    Sort, keyText

    r := 7

    Loop, Parse, keyText, `n, `r
    {
        key := Trim(A_LoopField)
        if (key = "")
            continue

        item := daily[key]
        diff := item.useAmount - item.statementAmount
        status := (diff = 0 && item.issues = 0) ? "ÀÏÄ¡" : "È®ÀÎÇÊ¿ä"

        SSOK_CardCompareWriteStage := "ÀÏÀÚº°¿ä¾à " . r . "Çà"
        ws.Cells(r,1).Value2 := SSOK_Expense_CardCompare_DateDisplay(key)
        ws.Cells(r,2).Value2 := item.useAmount
        ws.Cells(r,3).Value2 := item.statementAmount
        ws.Cells(r,4).Value2 := diff
        ws.Cells(r,5).Value2 := status
        ws.Cells(r,6).Value2 := item.dateDiff

        r++
    }

    lastRow := r - 1

    SSOK_CardCompareWriteStage := "ÀÏÀÚº°¿ä¾à ¼­½Ä"

    try ws.Range("A1:F1").Merge()
    try ws.Range("A1:F1").Interior.ColorIndex := 23
    try ws.Range("A1:F1").Font.ColorIndex := 2
    try ws.Range("A1:F1").Font.Bold := true
    try ws.Range("A1:F1").Font.Size := 14
    try ws.Range("A1:F1").HorizontalAlignment := -4108

    try ws.Range("A3:F3").Interior.ColorIndex := 36
    try ws.Range("A3:F3").Font.Bold := true
    try ws.Range("B3").NumberFormat := "#,##0"
    try ws.Range("D3").NumberFormat := "#,##0"
    try ws.Range("F3").NumberFormat := "#,##0"

    try ws.Range("A6:F6").Interior.ColorIndex := 23
    try ws.Range("A6:F6").Font.ColorIndex := 2
    try ws.Range("A6:F6").Font.Bold := true
    try ws.Range("A6:F6").HorizontalAlignment := -4108

    if (lastRow >= 7)
    {
        try ws.Range("B7:D" . lastRow).NumberFormat := "#,##0"
        try ws.Range("A6:F" . lastRow).Borders.LineStyle := 1
        try ws.Range("A6:F" . lastRow).VerticalAlignment := -4108

        ; È®ÀÎÇÊ¿ä Çà¸¸ »ö»ó Ç¥½Ã
        rr := 7
        Loop, Parse, keyText, `n, `r
        {
            key := Trim(A_LoopField)
            if (key = "")
                continue

            item := daily[key]
            diff := item.useAmount - item.statementAmount
            status := (diff = 0 && item.issues = 0) ? "ÀÏÄ¡" : "È®ÀÎÇÊ¿ä"

            if (status != "ÀÏÄ¡")
                try ws.Range("A" . rr . ":F" . rr).Interior.ColorIndex := 38

            rr++
        }

        try ws.Range("A6:F" . lastRow).AutoFilter()
    }

    try ws.Columns("A").ColumnWidth := 14
    try ws.Columns("B").ColumnWidth := 18
    try ws.Columns("C").ColumnWidth := 18
    try ws.Columns("D").ColumnWidth := 18
    try ws.Columns("E").ColumnWidth := 14
    try ws.Columns("F").ColumnWidth := 16

    SSOK_CardCompareWriteStage := ""
}

SSOK_Expense_CardCompare_BuildOutputPath(usePath, useRows := "")
{
    SplitPath, usePath,, dir

    latestYM := ""

    if IsObject(useRows)
    {
        for _, row in useRows
        {
            ym := SubStr(row.date, 1, 6)

            if (StrLen(ym) = 6 && ym > latestYM)
                latestYM := ym
        }
    }

    if (latestYM != "")
    {
        monthNum := SubStr(latestYM, 5, 2) + 0
        return dir . "\¹ýÀÎÄ«µå »ç¿ë³»¿ª ºñ±³(" . monthNum . "¿ù).xlsx"
    }

    return dir . "\¹ýÀÎÄ«µå »ç¿ë³»¿ª ºñ±³.xlsx"
}

SSOK_Expense_CardCompare_SortUseRows(ByRef rows)
{
    n := rows.Length()

    if (n < 2)
        return

    Loop, % n - 1
    {
        i := A_Index
        minIndex := i

        Loop, % n - i
        {
            j := i + A_Index

            if (rows[j].date < rows[minIndex].date)
                minIndex := j
            else if (rows[j].date = rows[minIndex].date && rows[j].amount < rows[minIndex].amount)
                minIndex := j
        }

        if (minIndex != i)
        {
            temp := rows[i]
            rows[i] := rows[minIndex]
            rows[minIndex] := temp
        }
    }
}

SSOK_Expense_CardCompare_SortResults(ByRef rows)
{
    n := rows.Length()

    if (n < 2)
        return

    Loop, % n - 1
    {
        i := A_Index
        minIndex := i

        Loop, % n - i
        {
            j := i + A_Index

            d1 := (rows[j].useDate != "") ? rows[j].useDate : SSOK_Expense_CardCompare_FirstDateKey(rows[j].statementDate)
            d2 := (rows[minIndex].useDate != "") ? rows[minIndex].useDate : SSOK_Expense_CardCompare_FirstDateKey(rows[minIndex].statementDate)

            if (d1 < d2)
                minIndex := j
        }

        if (minIndex != i)
        {
            temp := rows[i]
            rows[i] := rows[minIndex]
            rows[minIndex] := temp
        }
    }
}

SSOK_Expense_CardCompare_DateKey(value)
{
    s := Trim(value . "")

    if (s = "")
        return ""

    ; Excel serial date
    if RegExMatch(s, "^\d+(?:\.\d+)?$") && (s + 0) > 20000 && (s + 0) < 80000
    {
        days := Floor(s + 0)
        stamp := "18991230000000"
        EnvAdd, stamp, %days%, Days
        return SubStr(stamp, 1, 8)
    }

    digits := RegExReplace(s, "[^0-9]", "")

    if (StrLen(digits) >= 8)
        return SubStr(digits, 1, 8)

    return ""
}

SSOK_Expense_CardCompare_DateDisplay(dateKey)
{
    if (dateKey = "")
        return ""

    if (InStr(dateKey, "-") || InStr(dateKey, "."))
        dateKey := RegExReplace(dateKey, "[^0-9]", "")

    if (StrLen(dateKey) < 8)
        return dateKey

    return SubStr(dateKey,1,4) . "-" . SubStr(dateKey,5,2) . "-" . SubStr(dateKey,7,2)
}

SSOK_Expense_CardCompare_DateListDisplay(dateList)
{
    parts := StrSplit(dateList, " / ")
    out := ""

    for _, p in parts
    {
        if (out != "")
            out .= " / "

        out .= SSOK_Expense_CardCompare_DateDisplay(p)
    }

    return out
}

SSOK_Expense_CardCompare_FirstDateKey(dateList)
{
    if (dateList = "")
        return ""

    pos := InStr(dateList, " / ")

    if (pos)
        return SubStr(dateList, 1, pos - 1)

    return dateList
}

SSOK_Expense_CardCompare_DateDiff(a, b)
{
    if (a = "" || b = "")
        return 999999

    x := a . "000000"
    y := b . "000000"

    EnvSub, x, %y%, Days

    if (x < 0)
        x := 0 - x

    return x
}

SSOK_Expense_CardCompare_Amount(value)
{
    s := Trim(value . "")

    if (s = "")
        return ""

    s := StrReplace(s, ",", "")
    s := StrReplace(s, "¿ø", "")
    s := RegExReplace(s, "[^0-9\.-]", "")

    if !RegExMatch(s, "^-?\d+(?:\.\d+)?$")
        return ""

    return Round(s + 0)
}

SSOK_Expense_CardCompare_CellText(cell)
{
    try value := cell.Value2
    catch
        value := ""

    return Trim(value . "", " `t`r`n")
}

SSOK_Expense_CardCompare_HeaderKey(s)
{
    s := s . ""
    s := StrReplace(s, "`r", "")
    s := StrReplace(s, "`n", "")
    s := RegExReplace(s, "\s+", "")
    return s
}

SSOK_Expense_CardCompare_NormalizeMerchant(s)
{
    s := s . ""
    s := StrReplace(s, "(ÁÖ)", "")
    s := StrReplace(s, "¢ß", "")
    s := StrReplace(s, "ÁÖ½ÄÈ¸»ç", "")
    s := RegExReplace(s, "[\s\(\)\[\]\{\}\._\-]+", "")
    StringLower, s, s
    return s
}

SSOK_Expense_CardCompare_ArrayPushUnique(ByRef arr, value)
{
    if (value = "")
        return

    for _, old in arr
    {
        if (old = value)
            return
    }

    arr.Push(value)
}

SSOK_Expense_CardCompare_Join(arr, sep := ", ")
{
    out := ""

    for _, value in arr
    {
        if (out != "")
            out .= sep

        out .= value
    }

    return out
}

SSOK_Expense_CardCompare_FormatMoney(value)
{
    value := Round(value)
    s := value . ""
    sign := ""

    if (SubStr(s,1,1) = "-")
    {
        sign := "-"
        s := SubStr(s,2)
    }

    out := ""

    while (StrLen(s) > 3)
    {
        out := "," . SubStr(s, -2) . out
        s := SubStr(s, 1, StrLen(s) - 3)
    }

    return sign . s . out
}




; ============================================================================
; ¾÷¹«ÃßÁøºñ°ø°³
; A = °ø°³¿ë ¼­½Ä Excel
; B = °Å·¡Ã³º° ½ÇÀû Excel
;
; ÀÛ¼º ¹üÀ§
; - BÀÇ °¡Àå ÃÖ±Ù »ç¿ë¿ù = ÇØ´ç¿ù
; - ÇØ´ç¿ù ÁýÇà³»¿ª ÀÛ¼º
; - »ç¿ë½Ã°£ / ÁýÇà´ë»ó = °ø¶õ
; - È¸ÀÇºñ / °æÁ¶»ç / À§¹® / °Ý·Á / ¹°Ç° ±¸ÀÔ µî ÀÚµ¿ ºÐ·ù
; - À¯Çüº° »ç¿ëÇöÈ²ÀÇ Àü¿ù±îÁö »ç¿ë½ÇÀû / ´ç¿ù »ç¿ë½ÇÀû / ÇÕ°è ÀÛ¼º
; - ¿¹»ê¾×Àº ¼öÁ¤ÇÏÁö ¾ÊÀ½
; ============================================================================

SSOK_Expense_WorkPublic_PastePrev:
    path := SSOK_Expense_GetCopiedFilePath()
    if (path = "")
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Å½»ö±â¿¡¼­ °ø°³ ¼­½Ä ExcelÀ» Ctrl+C·Î º¹»çÇÑ µÚ ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä.
        return
    }
    SSOK_WorkPublicPrevPath := path
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevDrop, %path%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_PasteCurrent:
    path := SSOK_Expense_GetCopiedFilePath()
    if (path = "")
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Å½»ö±â¿¡¼­ B ¿øº»ÀÚ·á ExcelÀ» Ctrl+C·Î º¹»çÇÑ µÚ ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä.
        return
    }
    SSOK_WorkPublicCurrentPath := path
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentDrop, %path%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return


SSOK_Expense_WorkPublic_PasteCard:
    path := SSOK_Expense_GetCopiedFilePath()
    if (path = "")
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Å½»ö±â¿¡¼­ Ä«µå½ÂÀÎ³»¿ª ExcelÀ» Ctrl+C·Î º¹»çÇÑ µÚ ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä.
        return
    }
    SSOK_WorkPublicCardPath := path
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCardDrop, %path%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_BrowsePrev:
    FileSelectFile, picked, 3,, °ø°³ ¼­½Ä Excel ¼±ÅÃ, Excel ÆÄÀÏ (*.xlsx; *.xls)
    if (ErrorLevel)
        return
    SSOK_WorkPublicPrevPath := picked
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevDrop, %picked%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_BrowseCurrent:
    FileSelectFile, picked, 3,, B ¿øº»ÀÚ·á Excel ¼±ÅÃ, Excel ÆÄÀÏ (*.xlsx; *.xls)
    if (ErrorLevel)
        return
    SSOK_WorkPublicCurrentPath := picked
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentDrop, %picked%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_BrowseCard:
    FileSelectFile, picked, 3,, C Ä«µå ½ÂÀÎ³»¿ª Excel ¼±ÅÃ, Excel ÆÄÀÏ (*.xlsx; *.xls)
    if (ErrorLevel)
        return
    SSOK_WorkPublicCardPath := picked
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCardDrop, %picked%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_UpdateStatus:
    Gui, SSOKWorkPublic:Submit, NoHide

    hasA := FileExist(SSOK_WorkPublicPrevPath)
    hasB := FileExist(SSOK_WorkPublicCurrentPath)
    hasC := FileExist(SSOK_WorkPublicCardPath)

    status := ""
    if (hasA)
        status .= "A "
    if (hasB)
        status .= "B "
    if (hasC)
        status .= "C "
    if (status != "")
        status := RTrim(status) . " ÀÚ·á ÀÔ·Â ¿Ï·á"

    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, %status%
return

SSOK_Expense_WorkPublic_Check:
    ; ÃÊ±âÈ­: ¼±ÅÃÇÑ ÆÄÀÏ °æ·Î¸¸ ºñ¿ó´Ï´Ù.
    SSOK_WorkPublicPrevPath := ""
    SSOK_WorkPublicCurrentPath := ""
    SSOK_WorkPublicCardPath := ""
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevDrop, ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentDrop, ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCardDrop, ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus,
return

SSOK_Expense_WorkPublic_Convert:
    Gui, SSOKWorkPublic:Submit, NoHide

    ; A °ø°³ ¼­½ÄÀº ¼±ÅÃ»çÇ×ÀÔ´Ï´Ù.
    ; A°¡ ¾øÀ¸¸é ÇÁ·Î±×·¥¿¡ ³»ÀåµÈ ±âº» ¾÷¹«ÃßÁøºñ ¼­½ÄÀ» ÀÚµ¿À¸·Î »ç¿ëÇÕ´Ï´Ù.
    if (!FileExist(SSOK_WorkPublicCurrentPath))
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, B ¿øº»ÀÚ·á ExcelÀ» È®ÀÎÇØ ÁÖ¼¼¿ä.
        return
    }

    outputPath := SSOK_Expense_WorkPublic_BuildOutputPath(SSOK_WorkPublicPrevPath, SSOK_WorkPublicCurrentPath)

    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ÀÛ¾÷ÁßÀÔ´Ï´Ù. Àá½Ã¸¸ ±â´Ù·Á ÁÖ¼¼¿ä.

    if (SSOK_WorkPublicCardPath != "" && !FileExist(SSOK_WorkPublicCardPath))
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, C Ä«µå ½ÂÀÎ³»¿ª ExcelÀ» È®ÀÎÇØ ÁÖ¼¼¿ä.
        return
    }

    if !SSOK_Expense_WorkPublic_ConvertCore(SSOK_WorkPublicPrevPath, SSOK_WorkPublicCurrentPath, SSOK_WorkPublicCardPath, outputPath, resultReport, errMsg)
    {
        GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ½ÇÆÐ
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, %errMsg%
        return
    }

    openCount := 0

    if IsObject(SSOK_WorkPublicGeneratedPaths)
    {
        for _, generatedPath in SSOK_WorkPublicGeneratedPaths
        {
            if FileExist(generatedPath)
            {
                Run, %generatedPath%,, UseErrorLevel
                if (!ErrorLevel)
                    openCount++
            }
        }
    }

    if (FileExist(SSOK_WorkPublicCardPath))
    {
        if (openCount > 1)
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ¿Ï·á - %openCount%°³ ¿ùº° Excel / C ½ÂÀÎ½Ã°£ %SSOK_WorkPublicCardTimeMatched%°Ç ¹Ý¿µ
        else if (openCount = 1)
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ¿Ï·á - C ½ÂÀÎ½Ã°£ %SSOK_WorkPublicCardTimeMatched%°Ç ¹Ý¿µ
        else
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ¿Ï·á - C ½ÂÀÎ½Ã°£ %SSOK_WorkPublicCardTimeMatched%°Ç ¹Ý¿µ
    }
    else
    {
        if (openCount > 1)
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ¿Ï·á - %openCount%°³ ¿ùº° ExcelÀ» ¿­¾ú½À´Ï´Ù.
        else if (openCount = 1)
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ¿Ï·á - °á°ú ExcelÀ» ¿­¾ú½À´Ï´Ù.
        else
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, ÀÛ¼º ¿Ï·á - °á°úÆÄÀÏÀ» ÀúÀåÇß½À´Ï´Ù.
    }
return

SSOKWorkPublicGuiDropFiles:
    SSOK_Expense_WorkPublic_HandleDrop(A_GuiEvent, A_GuiControl)
return

SSOKWorkPublicGuiClose:
SSOKWorkPublicGuiEscape:
    Gui, SSOKWorkPublic:Destroy
return

SSOK_Expense_WorkPublic_Show()
{
    global SSOK_WorkPublicPrevPath, SSOK_WorkPublicCurrentPath, SSOK_WorkPublicCardPath
    global SSOK_WorkPublicStatus
    global SSOK_WorkPublicPrevDrop, SSOK_WorkPublicCurrentDrop, SSOK_WorkPublicCardDrop

    Gui, SSOKWorkPublic:Destroy
    Gui, SSOKWorkPublic:New, +ToolWindow, ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª °ø°³ ÀÚµ¿ ÀÛ¼º
    Gui, SSOKWorkPublic:Margin, 20, 18
    Gui, SSOKWorkPublic:Color, F7FBFF

    Gui, SSOKWorkPublic:Font, s12 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, w820 h30, ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª °ø°³ ÀÚµ¿ ÀÛ¼º

    ; A Àü¿ù ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª
    Gui, SSOKWorkPublic:Font, s10 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x20 y+18 w820 h24 +0x200, A Àü¿ù ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª (¼±ÅÃ)

    Gui, SSOKWorkPublic:Font, s9 Norm, Malgun Gothic
    prevDisplay := FileExist(SSOK_WorkPublicPrevPath) ? SSOK_WorkPublicPrevPath : "ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä"
    Gui, SSOKWorkPublic:Add, Text, x20 y+8 w820 h72 +Border Center 0x200 vSSOK_WorkPublicPrevDrop c555555, %prevDisplay%

    ; B ¿øÀÎÇàÀ§ ÁýÇà½ÇÀû
    Gui, SSOKWorkPublic:Font, s10 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x20 y+22 w820 h24 +0x200, B ¿øÀÎÇàÀ§ ÁýÇà½ÇÀû ÀÔ·Â (ÇÊ¼ö)

    Gui, SSOKWorkPublic:Font, s9 Norm, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x20 y+2 w820 h44 c555555, ±Ù°ÅÀÚ·á 1: ÇÐ±³È¸°è-ÁöÃâ°ü¸®-ÁöÃâÃ³¸®-¿øÀÎÇàÀ§¸ñ·Ï-¾÷¹«ÃßÁøºñ¸ñ·Ï`n   * »ó¼¼³»¿ª ÀÔ·ÂµÈ °Í¸¸ º¸±â ÇØÁ¦ ÈÄ Á¶È¸

    Gui, SSOKWorkPublic:Font, s9 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x20 y+3 w820 h22 +0x200, ¶Ç´Â

    Gui, SSOKWorkPublic:Font, s9 Norm, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x20 y+2 w820 h44 c555555, ±Ù°ÅÀÚ·á 2: ÇÐ±³È¸°è-ÁöÃâ°ü¸®-ÁöÃâÀåºÎ-ÁöÃâ½ÇÀûÁ¶È¸-¿øÀÎÇàÀ§-¿¹»ê°Å·¡Ã³º°½ÇÀûÁ¶È¸`n   * ¼¼Ãâ¼¼¸ñ¸í: ÀÏ¹Ý¾÷¹«ÃßÁøºñ·Î Á¶È¸

    currentDisplay := FileExist(SSOK_WorkPublicCurrentPath) ? SSOK_WorkPublicCurrentPath : "ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä"
    Gui, SSOKWorkPublic:Add, Text, x20 y+8 w820 h72 +Border Center 0x200 vSSOK_WorkPublicCurrentDrop c555555, %currentDisplay%

    ; C Ä«µå½ÂÀÎ³»¿ª
    Gui, SSOKWorkPublic:Font, s10 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x20 y+22 w820 h24 +0x200, C Ä«µå½ÂÀÎ³»¿ª (¼±ÅÃ)

    Gui, SSOKWorkPublic:Font, s9 Norm, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x20 y+2 w820 h24 c555555, ±Ù°ÅÀÚ·á: ÇÐ±³È¸°è-ÁöÃâ°ü¸®-±âÅ¸°ü¸®-Ä«µå½ÂÀÎ³»¿ªÁ¶È¸

    cardDisplay := FileExist(SSOK_WorkPublicCardPath) ? SSOK_WorkPublicCardPath : "ÆÄÀÏÀ» ¿©±â¿¡ ³õ¾ÆÁÖ¼¼¿ä"
    Gui, SSOKWorkPublic:Add, Text, x20 y+8 w820 h72 +Border Center 0x200 vSSOK_WorkPublicCardDrop c555555, %cardDisplay%

    ; »óÅÂ
    Gui, SSOKWorkPublic:Add, Text, x20 y+18 w820 h30 +0x200 vSSOK_WorkPublicStatus c005BAC,

    ; ÇÏ´Ü ¹öÆ°
    Gui, SSOKWorkPublic:Add, Button, x20 y+12 w180 h40 gSSOK_Expense_WorkPublic_Check, ÃÊ±âÈ­
    Gui, SSOKWorkPublic:Add, Button, x214 yp w180 h40 gSSOK_Expense_WorkPublic_Convert Default, ÀÛ¾÷½ÇÇà

    Gui, SSOKWorkPublic:Show, w860 h760 Center
}


; ============================================================================
; Windows Å½»ö±â¿¡¼­ Ctrl+C·Î º¹»çÇÑ ÆÄÀÏ °æ·Î °¡Á®¿À±â (CF_HDROP)
; ============================================================================

SSOK_Expense_DropExcelFiles(dropText)
{
    files := []

    ; GuiDropFilesÀÇ A_GuiEvent´Â ÁÙ¹Ù²ÞÀ¸·Î ±¸ºÐµÈ ÀüÃ¼ °æ·Î
    normalized := StrReplace(dropText, "`r`n", "`n")
    normalized := StrReplace(normalized, "`r", "`n")

    for _, raw in StrSplit(normalized, "`n")
    {
        path := Trim(raw, " `t" . Chr(34))
        if (path = "")
            continue

        if !RegExMatch(path, "i)\.(xlsx|xls)$")
            continue

        if FileExist(path)
            files.Push(path)
    }

    return files
}

SSOK_Expense_CardCompare_HandleDrop(dropText, targetControl := "")
{
    global SSOK_CardCompareUsePath, SSOK_CardCompareStatementPath

    files := SSOK_Expense_DropExcelFiles(dropText)
    if (!IsObject(files) || !files.Length())
    {
        MsgBox, 48, ¹ýÀÎÄ«µå³»¿ªºñ±³, Excel ÆÄÀÏ(.xlsx ¶Ç´Â .xls)¸¸ ²ø¾î ³õÀ» ¼ö ÀÖ½À´Ï´Ù.
        return
    }

    ; Á¤È®ÇÑ ÀÔ·ÂÄ­ À§¿¡ ³õÀ¸¸é ÇØ´ç Ä­¿¡ ¿ì¼± µî·Ï
    if (targetControl = "SSOK_CardCompareUsePath")
    {
        SSOK_CardCompareUsePath := files[1]
        GuiControl, SSOKCardCompare:, SSOK_CardCompareUsePath, % SSOK_CardCompareUsePath

        if (files.Length() >= 2)
        {
            SSOK_CardCompareStatementPath := files[2]
            GuiControl, SSOKCardCompare:, SSOK_CardCompareStatementPath, % SSOK_CardCompareStatementPath
        }
    }
    else if (targetControl = "SSOK_CardCompareStatementPath")
    {
        SSOK_CardCompareStatementPath := files[1]
        GuiControl, SSOKCardCompare:, SSOK_CardCompareStatementPath, % SSOK_CardCompareStatementPath

        if (files.Length() >= 2)
        {
            SSOK_CardCompareUsePath := files[2]
            GuiControl, SSOKCardCompare:, SSOK_CardCompareUsePath, % SSOK_CardCompareUsePath
        }
    }
    else
    {
        ; GUI ºó °÷¿¡ ³õ°Å³ª µÎ ÆÄÀÏÀ» ÇÑ ¹ø¿¡ ³õÀ¸¸é ºó Ä­ºÎÅÍ ¼ø¼­´ë·Î Ã¤¿ò
        for _, path in files
        {
            if (SSOK_CardCompareUsePath = "")
            {
                SSOK_CardCompareUsePath := path
                GuiControl, SSOKCardCompare:, SSOK_CardCompareUsePath, %path%
            }
            else if (SSOK_CardCompareStatementPath = "")
            {
                SSOK_CardCompareStatementPath := path
                GuiControl, SSOKCardCompare:, SSOK_CardCompareStatementPath, %path%
            }
            else
            {
                ; µÎ Ä­ÀÌ ¸ðµÎ Ã¡À» ¶§ ÇÑ ÆÄÀÏÀ» ´Ù½Ã µå·ÓÇÏ¸é Ã¹ ¹øÂ° Ä­ ±³Ã¼
                SSOK_CardCompareUsePath := path
                GuiControl, SSOKCardCompare:, SSOK_CardCompareUsePath, %path%
            }
        }
    }

    Gosub, SSOK_Expense_CardCompare_UpdateStatus
}


; ============================================================================
; ¾÷¹«ÃßÁøºñ°ø°³ - ½ÇÁ¦ º¯È¯
; ============================================================================

SSOK_Expense_WorkPublic_Preflight(templatePath, sourcePath, ByRef report, ByRef errMsg)
{
    report := ""
    errMsg := ""

    templatePath := Trim(templatePath)
    sourcePath := Trim(sourcePath)

    if (templatePath = "" || !FileExist(templatePath))
    {
        errMsg := "A °ø°³ ¼­½Ä ExcelÀ» È®ÀÎÇØ ÁÖ¼¼¿ä."
        return false
    }

    if (sourcePath = "" || !FileExist(sourcePath))
    {
        errMsg := "B ¿øº»ÀÚ·á ExcelÀ» È®ÀÎÇØ ÁÖ¼¼¿ä."
        return false
    }

    if !RegExMatch(templatePath, "i)\.(xlsx|xls)$")
    {
        errMsg := "A °ø°³ ¼­½ÄÀº Excel ÆÄÀÏ(.xlsx ¶Ç´Â .xls)ÀÌ¾î¾ß ÇÕ´Ï´Ù."
        return false
    }

    if !RegExMatch(sourcePath, "i)\.(xlsx|xls)$")
    {
        errMsg := "B ¿øº»ÀÚ·áÀº Excel ÆÄÀÏ(.xlsx ¶Ç´Â .xls)ÀÌ¾î¾ß ÇÕ´Ï´Ù."
        return false
    }

    if (SSOK_Expense_WorkPublic_NormalizePath(templatePath) = SSOK_Expense_WorkPublic_NormalizePath(sourcePath))
    {
        errMsg := "A¿Í B¿¡ °°Àº ÆÄÀÏÀ» ¼±ÅÃÇß½À´Ï´Ù.`n¼­·Î ´Ù¸¥ Excel ÆÄÀÏÀ» ¼±ÅÃÇØ ÁÖ¼¼¿ä."
        return false
    }

    aInfo := SSOK_Expense_WorkPublic_GetWorkbookInfo(templatePath, aErr)
    if !IsObject(aInfo)
    {
        errMsg := "A °ø°³ ¼­½Ä È®ÀÎ ½ÇÆÐ:`n" . aErr
        return false
    }

    bInfo := SSOK_Expense_WorkPublic_GetWorkbookInfo(sourcePath, bErr)
    if !IsObject(bInfo)
    {
        errMsg := "B ¿øº»ÀÚ·á È®ÀÎ ½ÇÆÐ:`n" . bErr
        return false
    }

    outputPath := SSOK_Expense_WorkPublic_BuildOutputPath(templatePath, sourcePath)

    report := "»çÀüÁ¡°ËÀÌ ¿Ï·áµÇ¾ú½À´Ï´Ù."
    report .= "`n`n[A] °ø°³ ¼­½Ä"
    report .= "`n- ÆÄÀÏ: " . aInfo.fileName
    report .= "`n- ½ÃÆ®: " . aInfo.sheetCount . "°³"
    report .= "`n- ±¸Á¶: " . aInfo.sheetSummary

    report .= "`n`n[B] °Å·¡Ã³º° ½ÇÀû"
    report .= "`n- ÆÄÀÏ: " . bInfo.fileName
    report .= "`n- ½ÃÆ®: " . bInfo.sheetCount . "°³"
    report .= "`n- ±¸Á¶: " . bInfo.sheetSummary

    report .= "`n`n[ÀÛ¼º ±ÔÄ¢]"
    report .= "`n- °Å·¡Ã³º° ½ÇÀûÀÇ °¡Àå ÃÖ±Ù ¿ùÀ» ÇØ´ç¿ù·Î »ç¿ë"
    report .= "`n- »ç¿ë½Ã°£ / ÁýÇà´ë»óÀº °ø¶õ"
    report .= "`n- ¿¹»ê¾×Àº ¼öÁ¤ÇÏÁö ¾ÊÀ½"
    report .= "`n- Àü¿ù±îÁö »ç¿ë½ÇÀûÀº ¼­½ÄÀÇ ±âÁ¸ ´©°è¸¦ »ç¿ë"

    report .= "`n`n[¿¹Á¤ °á°úÆÄÀÏ]"
    report .= "`n" . outputPath
    report .= "`n`n¿øº» A/B ÆÄÀÏÀº ¼öÁ¤ÇÏÁö ¾Ê½À´Ï´Ù."

    return true
}

SSOK_Expense_WorkPublic_GetWorkbookInfo(path, ByRef errMsg)
{
    errMsg := ""
    xl := ""
    wb := ""

    try
    {
        xl := ComObjCreate("Excel.Application")
        xl.Visible := false
        xl.DisplayAlerts := false
        xl.EnableEvents := false
        xl.AskToUpdateLinks := false
        try xl.AutomationSecurity := 3

        wb := xl.Workbooks.Open(path, 0, true)

        SplitPath, path, fileName

        sheetCount := wb.Worksheets.Count
        sheetSummary := ""

        Loop, %sheetCount%
        {
            ws := wb.Worksheets(A_Index)
            used := ws.UsedRange

            rowCount := used.Rows.Count
            colCount := used.Columns.Count

            if (sheetSummary != "")
                sheetSummary .= " / "

            sheetSummary .= ws.Name . " " . rowCount . "Çà¡¿" . colCount . "¿­"
        }

        if (sheetSummary = "")
            sheetSummary := "»ç¿ë ½ÃÆ® ¾øÀ½"

        return {fileName:fileName
            , sheetCount:sheetCount
            , sheetSummary:sheetSummary}
    }
    catch e
    {
        errMsg := e.Message
        return ""
    }
    finally
    {
        try
        {
            if IsObject(wb)
                wb.Close(false)
        }

        try
        {
            if IsObject(xl)
                xl.Quit()
        }

        wb := ""
        xl := ""
    }
}

SSOK_Expense_WorkPublic_BuildOutputPath(templatePath, sourcePath, currentMonth := "")
{
    SplitPath, sourcePath, sourceName, sourceDir,, sourceBase

    if (sourceDir = "")
        sourceDir := A_ScriptDir

    ext := "xlsx"

    if (FileExist(templatePath))
    {
        SplitPath, templatePath,,, templateExt
        if (templateExt != "")
            ext := templateExt
    }

    if (currentMonth != "" && StrLen(currentMonth) >= 6)
    {
        monthNum := SubStr(currentMonth, 5, 2) + 0
        return sourceDir . "\¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª(" . monthNum . "¿ù)." . ext
    }

    ; ½ÇÁ¦ »ç¿ë¿ùÀ» ÀÐ±â ÀüÀÇ ÀÓ½Ã °æ·Î
    return sourceDir . "\" . sourceBase . "_¾÷¹«ÃßÁøºñ°ø°³." . ext
}

SSOK_Expense_WorkPublic_NormalizePath(path)
{
    path := Trim(path)
    path := StrReplace(path, "/", "\")
    StringLower, path, path
    return path
}

SSOK_Expense_WorkPublic_ReadReferenceValues(xlRef, templatePath, ByRef budgetAmount, ByRef priorAmount, ByRef errMsg)
{
    budgetAmount := ""
    priorAmount := ""
    errMsg := ""

    if !FileExist(templatePath)
        return true

    wbRef := ""

    try
    {
        wbRef := xlRef.Workbooks.Open(templatePath, 0, true)

        layout := SSOK_Expense_WorkPublic_FindActualTemplateLayout(wbRef, layoutErr)
        if !IsObject(layout)
        {
            errMsg := "A °ø°³¼­½Ä¿¡¼­ ¿¹»ê¾×/Àü¿ù±îÁö À§Ä¡¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`n`n" . layoutErr
            return false
        }

        wsRef := layout.ws

        budgetAmount := SSOK_Expense_WorkPublic_Amount(wsRef.Cells(layout.budgetRow, layout.budgetCol).Value2)

        ; A °ø°³¼­½Ä¿¡¼­ °¡Á®¿Ã Àü¿ù±îÁö ½ÇÀû = ±âÁ¸ ´©°è°ª
        priorAmount := SSOK_Expense_WorkPublic_Amount(wsRef.Cells(layout.budgetRow, layout.cumCol).Value2)

        return true
    }
    catch e
    {
        errMsg := "A °ø°³¼­½Ä Âü°í°ªÀ» ÀÐ´Â Áß ¿À·ù°¡ ¹ß»ýÇß½À´Ï´Ù.`n`n" . e.Message
        return false
    }
    finally
    {
        try
        {
            if IsObject(wbRef)
                wbRef.Close(false)
        }

        wbRef := ""
    }
}

SSOK_Expense_WorkPublic_GetMonthList(rows)
{
    months := []
    seen := {}
    monthText := ""

    for _, row in rows
    {
        ym := SubStr(row.date, 1, 6)

        if (StrLen(ym) != 6)
            continue

        if !seen.HasKey(ym)
        {
            seen[ym] := true
            monthText .= ym . "`n"
        }
    }

    monthText := RTrim(monthText, "`n")

    if (monthText = "")
        return months

    ; YYYYMM ¼ýÀÚ ¿À¸§Â÷¼ø: 202608 -> 202609 -> ...
    Sort, monthText, N

    for _, ym in StrSplit(monthText, "`n")
    {
        ym := Trim(ym)
        if (ym != "")
            months.Push(ym)
    }

    return months
}

SSOK_Expense_WorkPublic_ConvertCore(templatePath, sourcePath, cardPath, ByRef outputPath, ByRef resultReport, ByRef errMsg)
{
    global SSOK_WorkPublicGeneratedPaths, SSOK_WorkPublicCardTimeMatched

    SSOK_WorkPublicGeneratedPaths := []
    SSOK_WorkPublicCardTimeMatched := 0
    resultReport := ""
    errMsg := ""

    xl := ""
    wbSource := ""
    wbCard := ""
    wbOut := ""
    stage := "ÁØºñ"
    outputPath := ""

    try
    {
        stage := "Excel ½ÇÇà"
        xl := ComObjCreate("Excel.Application")
        xl.Visible := false
        xl.DisplayAlerts := false
        xl.EnableEvents := false
        xl.AskToUpdateLinks := false
        try xl.AutomationSecurity := 3

        stage := "B ¿øº»ÀÚ·á ¿­±â"
        wbSource := xl.Workbooks.Open(sourcePath, 0, true)

        stage := "B ¿øº»ÀÚ·á Çü½Ä ÆÇº° ¹× ÀÐ±â"
        if !SSOK_Expense_WorkPublic_ReadActualSource(wbSource, sourceRows, sourceInfo, sourceErr)
        {
            errMsg := "B ¿øº»ÀÚ·á¸¦ ÀÐÁö ¸øÇß½À´Ï´Ù.`n`n" . sourceErr
            return false
        }

        ; ---------------------------------------------------------
        ; C Ä«µå ½ÂÀÎ³»¿ªÀÌ ÀÖÀ¸¸é ½ÂÀÎ½Ã°£À» ÀÐ¾î B ÀÚ·áÀÇ ½Ã°£º¸´Ù ¿ì¼± Àû¿ë
        ; ¸ÅÄª ±âÁØ: ±Ý¾× + »ç¿ëÃ³, Áßº¹ ÈÄº¸´Â °°Àº ³¯Â¥ ¿ì¼±
        ; ---------------------------------------------------------
        if FileExist(cardPath)
        {
            stage := "C Ä«µå ½ÂÀÎ³»¿ª ¿­±â"
            wbCard := xl.Workbooks.Open(cardPath, 0, true)

            stage := "C Ä«µå ½ÂÀÎ³»¿ª ÀÐ±â"
            if !SSOK_Expense_WorkPublic_ReadCardApprovals(wbCard, cardApprovals, cardErr)
            {
                errMsg := cardErr
                return false
            }

            stage := "C ½ÂÀÎ½Ã°£ ¸ÅÄª"
            SSOK_WorkPublicCardTimeMatched := SSOK_Expense_WorkPublic_ApplyCardApprovalTimes(sourceRows, cardApprovals)

            wbCard.Close(false)
            wbCard := ""
        }

        ; B ¿øº» ³»¿ëÀº sourceRows¿¡ ¸ðµÎ ÀÐ¾úÀ¸¹Ç·Î ¿©±â¼­ ´Ý¾Æ Excel ºÎ´ãÀ» ÁÙÀÓ
        if IsObject(wbSource)
        {
            wbSource.Close(false)
            wbSource := ""
        }

        ; ---------------------------------------------------------
        ; A °ø°³¼­½ÄÀº Ãâ·Â¿ë ¼­½ÄÀ¸·Î »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
        ; A¿¡¼­ °¡Á®¿À´Â °ªÀº ¿¹»ê¾× / Àü¿ù±îÁö »ç¿ë½ÇÀû µÎ °¡Áö»ÓÀÔ´Ï´Ù.
        ; ---------------------------------------------------------
        hasReferenceA := FileExist(templatePath)
        refBudget := ""
        refPrior := ""

        if (hasReferenceA)
        {
            stage := "A °ø°³¼­½Ä Âü°í°ª ÀÐ±â"
            if !SSOK_Expense_WorkPublic_ReadReferenceValues(xl, templatePath, refBudget, refPrior, refErr)
            {
                errMsg := refErr
                return false
            }
        }

        ; ---------------------------------------------------------
        ; ¿øº»¿¡ ÀÖ´Â ¸ðµç ¿ùÀ» ÃßÃâÇØ¼­ ¿À·¡µÈ ¿ùºÎÅÍ ¼ø¼­´ë·Î ÀÛ¼º
        ; ¿¹: 202608, 202609 -> 8¿ù ÆÄÀÏ + 9¿ù ÆÄÀÏ ¸ðµÎ »ý¼º
        ; ---------------------------------------------------------
        months := SSOK_Expense_WorkPublic_GetMonthList(sourceRows)

        if (!IsObject(months) || !months.Length())
        {
            errMsg := "B ¿øº»ÀÚ·á¿¡¼­ ÀÛ¼ºÇÒ ¾÷¹«ÃßÁøºñ »ç¿ë¿ùÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
            return false
        }

        ; Ã¹ ´ÞÀº »ç¿ëÀÚ°¡ ³ÖÀº A ¼­½ÄÀÌ ÀÖÀ¸¸é ±×°ÍÀ» »ç¿ë.
        ; A°¡ ¾øÀ¸¸é ³»Àå ±âº»¼­½ÄÀ» »ç¿ë.
        ; µÎ ¹øÂ° ´ÞºÎÅÍ´Â ¹Ù·Î ¾Õ¿¡¼­ »ý¼ºÇÑ ¿ùº° ÆÄÀÏÀ» ´ÙÀ½ ´ÞÀÇ ¼­½ÄÀ¸·Î ÀÌ¾î¼­ »ç¿ëÇÕ´Ï´Ù.
        ; °á°ú ExcelÀÇ ¼­½ÄÀº Ç×»ó ³»Àå ±âº»¼­½ÄÀ» »ç¿ëÇÕ´Ï´Ù.
        ; A´Â ¿¹»ê¾×/Àü¿ù±îÁö °ª¸¸ Âü°íÇÕ´Ï´Ù.
        runningCum := 0
        firstMonth := true
        generatedPaths := []

        for _, currentMonth in months
        {
            stage := currentMonth . "¿ù ÀÚ·á ÁØºñ"

            currentRows := []
            summary := {}
            summary["È¸ÀÇºñ"] := 0
            summary["À§¹®°Ý·Á"] := 0
            summary["°æÁ¶»çºñ"] := 0
            summary["¹°Ç°±âÅ¸"] := 0

            for _, row in sourceRows
            {
                if (SubStr(row.date, 1, 6) != currentMonth)
                    continue

                currentRows.Push(row)

                if summary.HasKey(row.category)
                    summary[row.category] += row.amount
                else
                    summary["¹°Ç°±âÅ¸"] += row.amount
            }

            if (!currentRows.Length())
                continue

            SSOK_Expense_WorkPublic_SortActualRows(currentRows)

            monthOutputPath := SSOK_Expense_WorkPublic_BuildOutputPath(templatePath, sourcePath, currentMonth)

            ; -----------------------------------------------------
            ; ÇØ´ç ¿ù °á°úÆÄÀÏ ¸¸µé±â
            ; A °ø°³¼­½Ä À¯¹«¿Í °ü°è¾øÀÌ Ç×»ó ³»Àå ±âº»¼­½ÄÀ» »ç¿ëÇÕ´Ï´Ù.
            ; -----------------------------------------------------
            stage := currentMonth . "¿ù °á°úÆÄÀÏ ¸¸µé±â"

            if FileExist(monthOutputPath)
            {
                FileDelete, %monthOutputPath%
                if FileExist(monthOutputPath)
                {
                    errMsg := "±âÁ¸ °á°úÆÄÀÏÀ» Áö¿ìÁö ¸øÇß½À´Ï´Ù.`nÆÄÀÏÀÌ ¿­·Á ÀÖ´ÂÁö È®ÀÎÇØ ÁÖ¼¼¿ä.`n`n" . monthOutputPath
                    return false
                }
            }

            stage := currentMonth . "¿ù ³»Àå ±âº»¼­½Ä ¸¸µé±â"
            if !SSOK_Expense_WorkPublic_CreateBuiltInTemplate(monthOutputPath, templateErr)
            {
                errMsg := "³»Àå ±âº»¼­½ÄÀ» ¸¸µéÁö ¸øÇß½À´Ï´Ù.`n`n" . templateErr
                return false
            }

            ; -----------------------------------------------------
            ; ÇØ´ç ¿ù ¼­½Ä ÀÛ¼º
            ; -----------------------------------------------------
            stage := currentMonth . "¿ù ¾÷¹«ÃßÁøºñ ¼­½Ä ¿­±â"
            wbOut := xl.Workbooks.Open(monthOutputPath, 0, false)

            stage := currentMonth . "¿ù ½ÇÁ¦ ¼­½Ä ±¸Á¶ È®ÀÎ"
            layout := SSOK_Expense_WorkPublic_FindActualTemplateLayout(wbOut, layoutErr)

            if !IsObject(layout)
            {
                errMsg := "¾÷¹«ÃßÁøºñ ¼­½ÄÀÇ ÀÛ¼º À§Ä¡¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`n`n" . layoutErr
                return false
            }

            ws := layout.ws

            ; A¿¡¼­ °¡Á®¿À´Â °ªÀº ¿¹»ê¾× / Àü¿ù±îÁö »ç¿ë½ÇÀû»ÓÀÔ´Ï´Ù.
            ; A°¡ ¾øÀ¸¸é ¸ðµç ¿ùÀÇ Àü¿ù±îÁö´Â °ø¶õ Ã³¸®ÇÕ´Ï´Ù.
            if (!hasReferenceA)
                prevCum := 0
            else if (firstMonth)
                prevCum := (refPrior = "") ? 0 : refPrior
            else
                prevCum := runningCum

            currentTotal := 0
            for _, row in currentRows
                currentTotal += row.amount

            ; Ä«Å×°í¸®º° ¼­½Ä ºóÄ­ ¼ö È®ÀÎ
            if !SSOK_Expense_WorkPublic_CheckActualCapacity(layout, currentRows, capacityErr)
            {
                errMsg := currentMonth . "¿ù: " . capacityErr
                return false
            }

            stage := currentMonth . "¿ù ±âÁ¸ »ç¿ë³»¿ª Áö¿ì±â"
            SSOK_Expense_WorkPublic_ClearActualDetail(ws, layout)

            stage := currentMonth . "¿ù »ç¿ë³»¿ª ÀÛ¼º"
            SSOK_Expense_WorkPublic_WriteActualDetail(ws, layout, currentRows)

            stage := currentMonth . "¿ù À¯Çüº° »ç¿ëÇöÈ² ÀÛ¼º"
            SSOK_Expense_WorkPublic_WriteActualTypeSummary(ws, layout, summary, currentTotal)

            stage := currentMonth . "¿ù ÁýÇàÃÑ°ý ÀÛ¼º"

            ; A°¡ ÀÖÀ¸¸é ¿¹»ê¾×Àº A °ª¸¸ °¡Á®¿Í ÇöÀç ³»Àå¼­½Ä¿¡ Àû¿ëÇÕ´Ï´Ù.
            if (hasReferenceA && refBudget != "")
                ws.Cells(layout.budgetRow, layout.budgetCol).Value2 := refBudget

            ; A°¡ ¾øÀ¸¸é ¿¹»ê¾×/Àü¿ù±îÁö °ø¶õ.
            ; A°¡ ÀÖÀ¸¸é Ã¹ ´ÞÀº AÀÇ Àü¿ù±îÁö, ÀÌÈÄ ´ÞÀº ¾Õ ´Þ ´©°è¸¦ Àü¿ù±îÁö·Î »ç¿ë.
            noReferenceA := !hasReferenceA
            SSOK_Expense_WorkPublic_WriteActualOverall(ws, layout, currentMonth, prevCum, currentTotal, noReferenceA)

            ; A ¹ÌÀÔ·Â ½Ã ÀúÀå Á÷Àü¿¡µµ ¿¹»ê¾×/Àü¿ù½ÇÀûÀ» ÃÖÁ¾ °­Á¦ °ø¶õ
            if (!hasReferenceA)
            {
                try ws.Cells(layout.budgetRow, layout.budgetCol).ClearContents()
                try ws.Cells(layout.budgetRow, layout.priorCol).ClearContents()
                try ws.Cells(layout.budgetRow, layout.budgetCol).Value2 := ""
                try ws.Cells(layout.budgetRow, layout.priorCol).Value2 := ""
            }

            ; ÀÛ¾÷ Áß ÀÚµ¿°è»êÀ» ²¨ µÎ¾úÀ¸¹Ç·Î ÀúÀå Á÷Àü¿¡ ÇØ´ç ½ÃÆ®¸¸ ÇÑ ¹ø °è»ê
            try ws.Calculate()

            stage := currentMonth . "¿ù °á°ú ÀúÀå"
            wbOut.Save()
            wbOut.Close(false)
            wbOut := ""

            runningCum := prevCum + currentTotal
            generatedPaths.Push(monthOutputPath)
            SSOK_WorkPublicGeneratedPaths.Push(monthOutputPath)

            ; ´ÙÀ½ ´Þµµ ³»Àå ±âº»¼­½ÄÀ» »õ·Î »ç¿ëÇÏ°í,
            ; °ªÀº runningCumÀ¸·Î¸¸ ÀÌ¾î°©´Ï´Ù.
            outputPath := monthOutputPath
            firstMonth := false
        }

        if (!generatedPaths.Length())
        {
            errMsg := "B ¿øº»ÀÚ·á¿¡¼­ ÀÛ¼ºÇÒ ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ªÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
            return false
        }

        ; ¿ùº° °á°úÆÄÀÏÀÌ ½ÇÁ¦·Î ¸ðµÎ »ý¼ºµÇ¾ú´ÂÁö ÃÖÁ¾ È®ÀÎ
        for _, generatedPath in generatedPaths
        {
            if !FileExist(generatedPath)
            {
                errMsg := "¿ùº° ¾÷¹«ÃßÁøºñ °á°úÆÄÀÏ »ý¼º È®ÀÎ¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n`n" . generatedPath
                return false
            }
        }

        ; ¿Ï·á ÆË¾÷Àº ¶ç¿ìÁö ¾ÊÁö¸¸ ³»ºÎ »óÅÂ¿ëÀ¸·Î »ý¼º °á°ú¸¦ ³²±è
        resultReport := generatedPaths.Length() . "°³¿ù ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª ÀÛ¼º ¿Ï·á"
        for _, path in generatedPaths
            resultReport .= "`n" . path

        return true
    }
    catch e
    {
        errMsg := "¾÷¹«ÃßÁøºñ °ø°³ÀÚ·á ÀÛ¼º Áß ¿À·ù°¡ ¹ß»ýÇß½À´Ï´Ù."
        errMsg .= "`n`n¿À·ù ´Ü°è: " . stage
        errMsg .= "`n`n" . e.Message
        return false
    }
    finally
    {
        try
        {
            if IsObject(wbOut)
                wbOut.Close(false)
        }

        try
        {
            if IsObject(wbSource)
                wbSource.Close(false)
        }

        try
        {
            if IsObject(wbCard)
                wbCard.Close(false)
        }

        try
        {
            if IsObject(xl)
                xl.Quit()
        }

        wbOut := ""
        wbSource := ""
        wbCard := ""
        xl := ""
    }
}


; ============================================================================
; ¾÷¹«ÃßÁøºñ°ø°³ - ½ÇÁ¦ ¾÷·Îµå ÆÄÀÏ ±¸Á¶ Àü¿ë
; A: "1 ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª.xlsx" (ÀÌÀü ´Þ °ø°³ ¼­½Ä)
; B: "¿¹»ê°Å·¡Ã³º°½ÇÀû(¿øÀÎÇàÀ§)" (ÇØ´ç¿ù ÁýÇàÀÚ·á)
; ============================================================================

SSOK_Expense_WorkPublic_ReadCardApprovals(wb, ByRef approvals, ByRef errMsg)
{
    approvals := []
    errMsg := ""

    Loop, % wb.Worksheets.Count
    {
        ws := wb.Worksheets(A_Index)

        if !SSOK_Expense_WorkPublic_FindCardApprovalColumns(ws, headerRow, cols)
            continue

        ; ¼Óµµ°³¼±: ±Ý¾×/»ç¿ëÃ³ ¿­Àº ÀÌ¹Ì Çì´õ Å½»ö¿¡¼­ È®ÀÎµÊ
        ; ½ÇÁ¦ µ¥ÀÌÅÍ°¡ ÀÖ´Â ¸¶Áö¸· ÇàÀ» Á÷Á¢ °è»ê
        lastRow := ws.Cells(ws.Rows.Count, cols.amount).End(-4162).Row
        lastRow2 := ws.Cells(ws.Rows.Count, cols.merchant).End(-4162).Row

        if (lastRow2 > lastRow)
            lastRow := lastRow2

        r := headerRow + 1

        while (r <= lastRow)
        {
            amount := SSOK_Expense_WorkPublic_Amount(ws.Cells(r, cols.amount).Value2)
            merchant := SSOK_Expense_WorkPublic_CellText(ws.Cells(r, cols.merchant))

            if (amount != "" && merchant != "")
            {
                dateKey := ""
                timeText := ""

                if (cols.datetime)
                {
                    dtValue := ws.Cells(r, cols.datetime).Value2
                    dateKey := SSOK_Expense_WorkPublic_DateKey(dtValue)
                    timeText := SSOK_Expense_WorkPublic_ApprovalTimeDisplay(dtValue)
                }
                else
                {
                    if (cols.date)
                        dateKey := SSOK_Expense_WorkPublic_DateKey(ws.Cells(r, cols.date).Value2)

                    if (cols.time)
                        timeText := SSOK_Expense_WorkPublic_ApprovalTimeDisplay(ws.Cells(r, cols.time).Value2)
                }

                if (timeText != "")
                {
                    approvals.Push({date:dateKey
                        , time:timeText
                        , amount:amount
                        , merchant:merchant
                        , used:false})
                }
            }

            r++
        }

        if (approvals.Length())
            return true
    }

    errMsg := "C Ä«µå ½ÂÀÎ³»¿ª¿¡¼­ ½ÂÀÎÀÏ½Ã(¶Ç´Â ½ÂÀÎ½Ã°£), ±Ý¾×, »ç¿ëÃ³/°¡¸ÍÁ¡ ¿­À» Ã£Áö ¸øÇß½À´Ï´Ù."
    errMsg .= "`n`nÀÎ½Ä ¿¹: ½ÂÀÎÀÏ½Ã / ½ÂÀÎ±Ý¾× / °¡¸ÍÁ¡¸í"
    return false
}

SSOK_Expense_WorkPublic_FindCardApprovalColumns(ws, ByRef headerRow, ByRef cols)
{
    used := ws.UsedRange
    firstRow := used.Row
    firstCol := used.Column
    totalRows := used.Rows.Count
    totalCols := used.Columns.Count

    ; 1Â÷: ÀÏ¹ÝÀûÀÎ Ä«µå ½ÂÀÎ³»¿ªÀº »ó´Ü/ÁÂÃø¿¡ ÀÖÀ¸¹Ç·Î ºü¸£°Ô Å½»ö
    fastRows := totalRows
    fastCols := totalCols

    if (fastRows > 25)
        fastRows := 25
    if (fastCols > 60)
        fastCols := 60

    Loop, %fastRows%
    {
        r := firstRow + A_Index - 1
        temp := {datetime:0, date:0, time:0, amount:0, merchant:0}

        Loop, %fastCols%
        {
            c := firstCol + A_Index - 1
            key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

            if (!temp.datetime && (InStr(key,"½ÂÀÎÀÏ½Ã") || InStr(key,"ÀÌ¿ëÀÏ½Ã") || InStr(key,"°Å·¡ÀÏ½Ã") || InStr(key,"»ç¿ëÀÏ½Ã")))
                temp.datetime := c
            else if (!temp.date && (InStr(key,"½ÂÀÎÀÏÀÚ") || InStr(key,"ÀÌ¿ëÀÏÀÚ") || InStr(key,"°Å·¡ÀÏÀÚ") || InStr(key,"»ç¿ëÀÏÀÚ") || InStr(key,"°áÁ¦ÀÏÀÚ")))
                temp.date := c
            else if (!temp.time && (InStr(key,"½ÂÀÎ½Ã°£") || InStr(key,"ÀÌ¿ë½Ã°£") || InStr(key,"°Å·¡½Ã°£") || InStr(key,"»ç¿ë½Ã°£")))
                temp.time := c

            if (!temp.amount && (InStr(key,"½ÂÀÎ±Ý¾×") || InStr(key,"ÀÌ¿ë±Ý¾×") || InStr(key,"»ç¿ë±Ý¾×") || InStr(key,"°áÁ¦±Ý¾×") || InStr(key,"¸ÅÃâ±Ý¾×") || key = "±Ý¾×"))
                temp.amount := c

            if (!temp.merchant && (InStr(key,"°¡¸ÍÁ¡¸í") || InStr(key,"°¡¸ÍÁ¡") || InStr(key,"»ç¿ëÃ³") || InStr(key,"°Å·¡Ã³") || InStr(key,"¾÷Ã¼¸í")))
                temp.merchant := c
        }

        if (temp.amount && temp.merchant && (temp.datetime || temp.time))
        {
            headerRow := r
            cols := temp
            return true
        }
    }

    ; 2Â÷ fallback: Æ¯¼öÇÑ ÆÄÀÏÀº ±âÁ¸Ã³·³ ÃÖ´ë 100Çà/100¿­±îÁö È®ÀÎ
    maxRows := totalRows
    maxCols := totalCols

    if (maxRows > 100)
        maxRows := 100
    if (maxCols > 100)
        maxCols := 100

    if (maxRows = fastRows && maxCols = fastCols)
        return false

    Loop, %maxRows%
    {
        r := firstRow + A_Index - 1

        ; 1Â÷¿¡¼­ ÀÌ¹Ì º» ¹üÀ§´Â °Ç³Ê¶Ü
        if (A_Index <= fastRows)
            startColIndex := fastCols + 1
        else
            startColIndex := 1

        temp := {datetime:0, date:0, time:0, amount:0, merchant:0}

        cIndex := startColIndex
        while (cIndex <= maxCols)
        {
            c := firstCol + cIndex - 1
            key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

            if (!temp.datetime && (InStr(key,"½ÂÀÎÀÏ½Ã") || InStr(key,"ÀÌ¿ëÀÏ½Ã") || InStr(key,"°Å·¡ÀÏ½Ã") || InStr(key,"»ç¿ëÀÏ½Ã")))
                temp.datetime := c
            else if (!temp.date && (InStr(key,"½ÂÀÎÀÏÀÚ") || InStr(key,"ÀÌ¿ëÀÏÀÚ") || InStr(key,"°Å·¡ÀÏÀÚ") || InStr(key,"»ç¿ëÀÏÀÚ") || InStr(key,"°áÁ¦ÀÏÀÚ")))
                temp.date := c
            else if (!temp.time && (InStr(key,"½ÂÀÎ½Ã°£") || InStr(key,"ÀÌ¿ë½Ã°£") || InStr(key,"°Å·¡½Ã°£") || InStr(key,"»ç¿ë½Ã°£")))
                temp.time := c

            if (!temp.amount && (InStr(key,"½ÂÀÎ±Ý¾×") || InStr(key,"ÀÌ¿ë±Ý¾×") || InStr(key,"»ç¿ë±Ý¾×") || InStr(key,"°áÁ¦±Ý¾×") || InStr(key,"¸ÅÃâ±Ý¾×") || key = "±Ý¾×"))
                temp.amount := c

            if (!temp.merchant && (InStr(key,"°¡¸ÍÁ¡¸í") || InStr(key,"°¡¸ÍÁ¡") || InStr(key,"»ç¿ëÃ³") || InStr(key,"°Å·¡Ã³") || InStr(key,"¾÷Ã¼¸í")))
                temp.merchant := c

            cIndex++
        }

        ; 1Â÷ ¹üÀ§ ¹Ù±ù¿¡ ¸Ó¸®±ÛÀÌ ¼¯¿© ÀÖ´Â Æ¯¼öÇü½ÄÀº ÀüÃ¼ÇàÀ» ´Ù½Ã È®ÀÎ
        if (A_Index <= fastRows && (temp.amount || temp.merchant || temp.datetime || temp.time))
        {
            cIndex := 1
            while (cIndex <= fastCols)
            {
                c := firstCol + cIndex - 1
                key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

                if (!temp.datetime && (InStr(key,"½ÂÀÎÀÏ½Ã") || InStr(key,"ÀÌ¿ëÀÏ½Ã") || InStr(key,"°Å·¡ÀÏ½Ã") || InStr(key,"»ç¿ëÀÏ½Ã")))
                    temp.datetime := c
                else if (!temp.date && (InStr(key,"½ÂÀÎÀÏÀÚ") || InStr(key,"ÀÌ¿ëÀÏÀÚ") || InStr(key,"°Å·¡ÀÏÀÚ") || InStr(key,"»ç¿ëÀÏÀÚ") || InStr(key,"°áÁ¦ÀÏÀÚ")))
                    temp.date := c
                else if (!temp.time && (InStr(key,"½ÂÀÎ½Ã°£") || InStr(key,"ÀÌ¿ë½Ã°£") || InStr(key,"°Å·¡½Ã°£") || InStr(key,"»ç¿ë½Ã°£")))
                    temp.time := c

                if (!temp.amount && (InStr(key,"½ÂÀÎ±Ý¾×") || InStr(key,"ÀÌ¿ë±Ý¾×") || InStr(key,"»ç¿ë±Ý¾×") || InStr(key,"°áÁ¦±Ý¾×") || InStr(key,"¸ÅÃâ±Ý¾×") || key = "±Ý¾×"))
                    temp.amount := c

                if (!temp.merchant && (InStr(key,"°¡¸ÍÁ¡¸í") || InStr(key,"°¡¸ÍÁ¡") || InStr(key,"»ç¿ëÃ³") || InStr(key,"°Å·¡Ã³") || InStr(key,"¾÷Ã¼¸í")))
                    temp.merchant := c

                cIndex++
            }
        }

        if (temp.amount && temp.merchant && (temp.datetime || temp.time))
        {
            headerRow := r
            cols := temp
            return true
        }
    }

    return false
}

SSOK_Expense_WorkPublic_ApprovalTimeDisplay(value)
{
    s := Trim(value . "", " `t`r`n")
    if (s = "")
        return ""

    ; Excel ÀÏ½Ã/½Ã°£ serial °ª
    if RegExMatch(s, "^-?[0-9]+(?:\.[0-9]+)?$")
    {
        n := s + 0
        frac := n - Floor(n)

        if (n >= 0 && n < 1)
            frac := n

        if (frac >= 0)
        {
            totalMinutes := Floor((frac * 1440) + 0.00001)
            if (totalMinutes >= 1440)
                totalMinutes := Mod(totalMinutes, 1440)

            hh := Floor(totalMinutes / 60)
            mm := Mod(totalMinutes, 60)
            return Format("{:02}:{:02}", hh, mm)
        }
    }

    ; ÅØ½ºÆ® ¿¹: 2026-09-21 12:32:48 -> 12:32
    if RegExMatch(s, "(\d{1,2})\s*:\s*(\d{1,2})", m)
    {
        hh := m1 + 0
        mm := m2 + 0

        if (hh >= 0 && hh <= 23 && mm >= 0 && mm <= 59)
            return Format("{:02}:{:02}", hh, mm)
    }

    ; ÅØ½ºÆ® ¿¹: 12½Ã 32ºÐ
    if RegExMatch(s, "(\d{1,2})\s*½Ã\s*(\d{1,2})\s*ºÐ", m)
    {
        hh := m1 + 0
        mm := m2 + 0

        if (hh >= 0 && hh <= 23 && mm >= 0 && mm <= 59)
            return Format("{:02}:{:02}", hh, mm)
    }

    return ""
}

SSOK_Expense_WorkPublic_MerchantMatchKey(value)
{
    s := SSOK_Expense_WorkPublic_HeaderKey(value)
    s := StrReplace(s, "ÁÖ½ÄÈ¸»ç", "")
    s := StrReplace(s, "À¯ÇÑÈ¸»ç", "")
    s := StrReplace(s, "(ÁÖ)", "")
    s := RegExReplace(s, "[\(\)\[\]\{\}\-_.,/\\]", "")
    return s
}

SSOK_Expense_WorkPublic_MerchantMatches(a, b)
{
    ak := SSOK_Expense_WorkPublic_MerchantMatchKey(a)
    bk := SSOK_Expense_WorkPublic_MerchantMatchKey(b)

    if (ak = "" || bk = "")
        return false

    if (ak = bk)
        return true

    if (StrLen(ak) >= 3 && StrLen(bk) >= 3)
    {
        if (InStr(ak, bk) || InStr(bk, ak))
            return true
    }

    return false
}

SSOK_Expense_WorkPublic_FindAmountCombination(sourceRows, candidateIndexes, targetAmount)
{
    result := []

    if (!IsObject(candidateIndexes) || candidateIndexes.Length() < 2)
        return result

    n := candidateIndexes.Length()

    ; ½ÇÁ¦ ¿¹»êºÐÇÒÀº º¸Åë 2~4ÇàÀÌ¹Ç·Î ÃÖ´ë 4°³ Á¶ÇÕ±îÁö Å½»ö
    ; 2°³ Á¶ÇÕ
    Loop, % n
    {
        i := A_Index
        if (i >= n)
            break

        Loop, % n - i
        {
            j := i + A_Index
            idx1 := candidateIndexes[i]
            idx2 := candidateIndexes[j]

            if (sourceRows[idx1].amount + sourceRows[idx2].amount = targetAmount)
                return [idx1, idx2]
        }
    }

    ; 3°³ Á¶ÇÕ
    if (n >= 3)
    {
        Loop, % n
        {
            i := A_Index
            if (i > n - 2)
                break

            j := i + 1
            while (j <= n - 1)
            {
                k := j + 1
                while (k <= n)
                {
                    idx1 := candidateIndexes[i]
                    idx2 := candidateIndexes[j]
                    idx3 := candidateIndexes[k]

                    sum := sourceRows[idx1].amount + sourceRows[idx2].amount + sourceRows[idx3].amount
                    if (sum = targetAmount)
                        return [idx1, idx2, idx3]

                    k++
                }
                j++
            }
        }
    }

    ; 4°³ Á¶ÇÕ
    if (n >= 4)
    {
        Loop, % n
        {
            i := A_Index
            if (i > n - 3)
                break

            j := i + 1
            while (j <= n - 2)
            {
                k := j + 1
                while (k <= n - 1)
                {
                    l := k + 1
                    while (l <= n)
                    {
                        idx1 := candidateIndexes[i]
                        idx2 := candidateIndexes[j]
                        idx3 := candidateIndexes[k]
                        idx4 := candidateIndexes[l]

                        sum := sourceRows[idx1].amount + sourceRows[idx2].amount + sourceRows[idx3].amount + sourceRows[idx4].amount
                        if (sum = targetAmount)
                            return [idx1, idx2, idx3, idx4]

                        l++
                    }
                    k++
                }
                j++
            }
        }
    }

    return result
}

SSOK_Expense_WorkPublic_ApplyCardApprovalTimes(ByRef sourceRows, ByRef approvals)
{
    matched := 0

    if (!IsObject(sourceRows) || !IsObject(approvals))
        return matched

    ; ------------------------------------------------------------
    ; 1´Ü°è: ±âÁ¸ ¹æ½Ä - B ÇÑ ÇàÀÇ ±Ý¾×°ú C ½ÂÀÎ±Ý¾×ÀÌ Á¤È®È÷ °°Àº 1:1 ¸ÅÄª
    ; ------------------------------------------------------------
    for rowIndex, row in sourceRows
    {
        bestIndex := 0
        bestScore := -1
        rowMerchantKey := SSOK_Expense_WorkPublic_MerchantMatchKey(row.merchant)

        for approvalIndex, approval in approvals
        {
            if (approval.used)
                continue

            if (approval.amount != row.amount)
                continue

            if !SSOK_Expense_WorkPublic_MerchantMatches(row.merchant, approval.merchant)
                continue

            score := 100
            approvalMerchantKey := SSOK_Expense_WorkPublic_MerchantMatchKey(approval.merchant)

            if (rowMerchantKey = approvalMerchantKey)
                score += 20

            ; °°Àº ³¯Â¥¸¦ ÃÖ¿ì¼±
            if (row.date != "" && approval.date != "" && row.date = approval.date)
                score += 50

            if (score > bestScore)
            {
                bestScore := score
                bestIndex := approvalIndex
            }
        }

        if (bestIndex)
        {
            sourceRows[rowIndex].time := approvals[bestIndex].time
            sourceRows[rowIndex].cardMatched := true
            approvals[bestIndex].used := true
            matched++
        }
    }

    ; ------------------------------------------------------------
    ; 2´Ü°è: ¿¹»ê ºÐÇÒ ¸ÅÄª
    ; ½ÇÁ¦ Ä«µå´Â 1¹ø °áÁ¦ÇßÁö¸¸ B¿¡¼­ ¿¹»ê ¶§¹®¿¡ 2°³ ÀÌ»óÀ¸·Î ³ª´¶ °æ¿ì
    ; °°Àº ³¯Â¥ + °°Àº »ç¿ëÃ³ÀÇ ¹Ì¸ÅÄª B Çà ÇÕ°è°¡ C ½ÂÀÎ±Ý¾×°ú °°À¸¸é
    ; °ø°³ÀÚ·á¿¡¼­´Â ½ÇÁ¦ Ä«µå ½ÂÀÎ 1°ÇÀ¸·Î ÇÕÄ¨´Ï´Ù.
    ; ------------------------------------------------------------
    for approvalIndex, approval in approvals
    {
        if (approval.used)
            continue

        candidateIndexes := []

        for rowIndex, row in sourceRows
        {
            if (row.HasKey("cardMatched") && row.cardMatched)
                continue

            if (row.HasKey("mergedAway") && row.mergedAway)
                continue

            if (approval.date != "" && row.date != "" && row.date != approval.date)
                continue

            if !SSOK_Expense_WorkPublic_MerchantMatches(row.merchant, approval.merchant)
                continue

            candidateIndexes.Push(rowIndex)
        }

        if (candidateIndexes.Length() < 2)
            continue

        groupIndexes := SSOK_Expense_WorkPublic_FindAmountCombination(sourceRows, candidateIndexes, approval.amount)

        if (!IsObject(groupIndexes) || groupIndexes.Length() < 2)
            continue

        ; Ã¹ ÇàÀ» ´ëÇ¥ÇàÀ¸·Î »ç¿ëÇÏ°í ³ª¸ÓÁö´Â Á¦°ÅÇ¥½Ã
        firstIndex := groupIndexes[1]
        mergedRow := sourceRows[firstIndex]

        mergedTitle := ""
        mergedTarget := ""
        mergedPlace := ""
        mergedCategory := mergedRow.category

        for _, idx in groupIndexes
        {
            r := sourceRows[idx]

            if (mergedTitle = "" && r.title != "")
                mergedTitle := r.title

            if (mergedTarget = "" && r.target != "")
                mergedTarget := r.target

            if (mergedPlace = "" && r.place != "")
                mergedPlace := r.place
        }

        sourceRows[firstIndex].amount := approval.amount
        sourceRows[firstIndex].time := approval.time
        sourceRows[firstIndex].cardMatched := true
        sourceRows[firstIndex].cardMerged := true

        if (mergedTitle != "")
            sourceRows[firstIndex].title := mergedTitle
        if (mergedTarget != "")
            sourceRows[firstIndex].target := mergedTarget
        if (mergedPlace != "")
            sourceRows[firstIndex].place := mergedPlace

        ; ´ëÇ¥Çà ¿Ü ³ª¸ÓÁö ºÐÇÒÇà Á¦°Å
        Loop, % groupIndexes.Length()
        {
            if (A_Index = 1)
                continue
            idx := groupIndexes[A_Index]
            sourceRows[idx].mergedAway := true
        }

        approvals[approvalIndex].used := true
        matched++
    }

    ; mergedAway Çà ½ÇÁ¦ Á¦°Å
    cleaned := []
    for _, row in sourceRows
    {
        if (row.HasKey("mergedAway") && row.mergedAway)
            continue
        cleaned.Push(row)
    }

    sourceRows := cleaned
    return matched
}

SSOK_Expense_WorkPublic_ReadActualSource(wb, ByRef rows, ByRef info, ByRef errMsg)
{
    rows := []
    info := ""
    errMsg := ""

    try
        ws := wb.Worksheets(1)
    catch e
    {
        errMsg := "B ¿øº»ÀÚ·áÀÇ Ã¹ ¹øÂ° ½ÃÆ®¸¦ ¿­Áö ¸øÇß½À´Ï´Ù.`n`n" . e.Message
        return false
    }

    ; Çü½Ä 1: ¿¹»ê°Å·¡Ã³º°½ÇÀû(¿øÀÎÇàÀ§)
    vendorH1 := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(3,1)))
    vendorH4 := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(3,4)))
    vendorH6 := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(3,6)))
    isVendorFormat := (vendorH1 = "ÀÏÀÚ" && vendorH4 = "Á¦¸ñ" && InStr(vendorH6, "¿øÀÎÇàÀ§"))

    ; Çü½Ä 2: ¾÷¹«ÃßÁøºñ¸ñ·Ï
    workH3 := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(1,3)))
    workH4 := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(1,4)))
    workH5 := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(1,5)))
    workH7 := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(1,7)))
    isWorkListFormat := (InStr(workH3, "¿øÀÎÇàÀ§ÀÏÀÚ") && workH4 = "Á¦¸ñ" && InStr(workH5, "¿øÀÎÇàÀ§±Ý¾×") && InStr(workH7, "»ç¿ëÃ³"))

    if (isVendorFormat)
        return SSOK_Expense_WorkPublic_ReadVendorSource(ws, rows, info, errMsg)

    if (isWorkListFormat)
        return SSOK_Expense_WorkPublic_ReadWorkListSource(ws, rows, info, errMsg)

    errMsg := "Áö¿øÇÏÁö ¾Ê´Â B ¿øº»ÀÚ·á Çü½ÄÀÔ´Ï´Ù."
    errMsg .= "`n`nÁö¿ø Çü½Ä:"
    errMsg .= "`n1) ¿¹»ê°Å·¡Ã³º°½ÇÀû(¿øÀÎÇàÀ§)"
    errMsg .= "`n2) ¾÷¹«ÃßÁøºñ¸ñ·Ï"
    return false
}

SSOK_Expense_WorkPublic_FindActualSourceColumns(ws, ByRef headerRow, ByRef cols)
{
    used := ws.UsedRange
    firstRow := used.Row
    firstCol := used.Column
    maxRows := used.Rows.Count
    maxCols := used.Columns.Count

    if (maxRows > 80)
        maxRows := 80
    if (maxCols > 80)
        maxCols := 80

    Loop, %maxRows%
    {
        r := firstRow + A_Index - 1
        temp := {date:0, title:0, amount:0, type:0, detail1:0, detail2:0
            , costItem:0, budgetItem:0, merchant:0, payment:0}

        Loop, %maxCols%
        {
            c := firstCol + A_Index - 1
            key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

            if (key = "ÀÏÀÚ")
                temp.date := c
            else if (key = "Á¦¸ñ")
                temp.title := c
            else if (key = "¿øÀÎÇàÀ§¾×" || key = "¿øÀÎÇàÀ§±Ý¾×")
                temp.amount := c
            else if (key = "À¯Çü")
                temp.type := c
            else if (key = "¼¼ºÎÇ×¸ñ")
                temp.detail1 := c
            else if (key = "»êÃâ³»¿ª")
                temp.detail2 := c
            else if (key = "¿ø°¡Åë°èºñ¸ñ")
                temp.costItem := c
            else if (key = "¸ñ")
                temp.budgetItem := c
            else if (key = "¼ö·ÉÀÎ")
                temp.merchant := c
            else if (key = "Áö±Þ¹æ¹ý")
                temp.payment := c
        }

        if (temp.date && temp.title && temp.amount)
        {
            headerRow := r
            cols := temp
            return true
        }
    }

    return false
}

SSOK_Expense_WorkPublic_ReadVendorSource(ws, ByRef rows, ByRef info, ByRef errMsg)
{
    rows := []
    info := ""
    errMsg := ""

    ; ¼Óµµ°³¼±: ½ÇÁ¦ ÀÏÀÚ(A¿­)°¡ ÀÖ´Â ¸¶Áö¸· Çà±îÁö¸¸ Ã³¸®
    lastRow := ws.Cells(ws.Rows.Count, 1).End(-4162).Row  ; xlUp

    currentMonth := ""

    r := 4
    while (r <= lastRow)
    {
        dateKey := SSOK_Expense_WorkPublic_DateKey(ws.Cells(r,1).Value2)

        if (dateKey != "")
        {
            amount := SSOK_Expense_WorkPublic_Amount(ws.Cells(r,6).Value2)

            if (amount != "" && amount != 0)
            {
                budgetItem := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,11))

                if InStr(SSOK_Expense_WorkPublic_HeaderKey(budgetItem), "¾÷¹«ÃßÁøºñ")
                {
                    title := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,4))
                    titleKey := SSOK_Expense_WorkPublic_HeaderKey(title)

                    ; ÇÐ±³Àå Á÷Ã¥±Þ ¾÷¹«¼öÇà°æºñ´Â ¹«Á¶°Ç Á¦¿Ü
                    if !(InStr(titleKey, "ÇÐ±³Àå") && InStr(titleKey, "Á÷Ã¥±Þ¾÷¹«¼öÇà°æºñ"))
                    {
                        merchant := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,14))

                        extra := ""
                        for _, c in [7,9,10,13]
                        {
                            t := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c))
                            if (t != "")
                                extra .= " " . t
                        }

                        category := SSOK_Expense_WorkPublic_ClassifyActual(title, extra)

                        rows.Push({date:dateKey
                            , title:title
                            , amount:amount
                            , merchant:merchant
                            , place:""
                            , time:""
                            , target:""
                            , category:category
                            , sourceType:"vendor"})

                        ym := SubStr(dateKey, 1, 6)
                        if (currentMonth = "" || ym > currentMonth)
                            currentMonth := ym
                    }
                }
            }
        }

        r++
    }

    if (!rows.Length())
    {
        errMsg := "¿¹»ê°Å·¡Ã³º°½ÇÀû¿¡¼­ °ø°³ÇÒ ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ªÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
        return false
    }

    info := {sheetName:ws.Name
        , headerRow:3
        , currentMonth:currentMonth
        , sourceType:"vendor"}

    return true
}

SSOK_Expense_WorkPublic_ReadWorkListSource(ws, ByRef rows, ByRef info, ByRef errMsg)
{
    rows := []
    info := ""
    errMsg := ""

    ; ¼Óµµ°³¼±: ¿øÀÎÇàÀ§ÀÏÀÚ(C¿­)ÀÇ ½ÇÁ¦ ¸¶Áö¸· µ¥ÀÌÅÍ Çà±îÁö¸¸ Ã³¸®
    lastRow := ws.Cells(ws.Rows.Count, 3).End(-4162).Row  ; xlUp

    currentMonth := ""

    r := 2
    while (r <= lastRow)
    {
        rowNo := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,2))

        ; ÇÕ°è Çà Á¦¿Ü
        if (SSOK_Expense_WorkPublic_HeaderKey(rowNo) = "ÇÕ°è")
        {
            r++
            continue
        }

        dateKey := SSOK_Expense_WorkPublic_DateKey(ws.Cells(r,3).Value2)

        if (dateKey != "")
        {
            amount := SSOK_Expense_WorkPublic_Amount(ws.Cells(r,5).Value2)

            if (amount != "" && amount != 0)
            {
                title := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,4))
                titleKey := SSOK_Expense_WorkPublic_HeaderKey(title)

                ; ÇÐ±³Àå Á÷Ã¥±Þ ¾÷¹«¼öÇà°æºñ´Â ¹«Á¶°Ç Á¦¿Ü
                if !(InStr(titleKey, "ÇÐ±³Àå") && InStr(titleKey, "Á÷Ã¥±Þ¾÷¹«¼öÇà°æºñ"))
                {
                    merchant := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,7))
                    attendees := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,8))
                    attendeeCount := SSOK_Expense_WorkPublic_Amount(ws.Cells(r,9).Value2)
                    place := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,10))
                    timeText := SSOK_Expense_WorkPublic_TimeDisplay(ws.Cells(r,11).Value2)
                    targetText := SSOK_Expense_WorkPublic_TargetDisplay(attendees, attendeeCount)

                    category := SSOK_Expense_WorkPublic_ClassifyActual(title)

                    rows.Push({date:dateKey
                        , title:title
                        , amount:amount
                        , merchant:merchant
                        , place:place
                        , time:timeText
                        , target:targetText
                        , category:category
                        , sourceType:"worklist"})

                    ym := SubStr(dateKey, 1, 6)
                    if (currentMonth = "" || ym > currentMonth)
                        currentMonth := ym
                }
            }
        }

        r++
    }

    if (!rows.Length())
    {
        errMsg := "¾÷¹«ÃßÁøºñ¸ñ·Ï¿¡¼­ °ø°³ÇÒ ÁýÇà³»¿ªÀ» Ã£Áö ¸øÇß½À´Ï´Ù."
        return false
    }

    info := {sheetName:ws.Name
        , headerRow:1
        , currentMonth:currentMonth
        , sourceType:"worklist"}

    return true
}

SSOK_Expense_WorkPublic_TimeDisplay(value)
{
    s := Trim(value . "", " `t`r`n")
    if (s = "")
        return ""

    ; Excel ½Ã°£ °ªÀÌ ¼ýÀÚÀÏ ¶§ HH:mmÀ¸·Î º¯È¯
    if RegExMatch(s, "^-?[0-9]+(?:\.[0-9]+)?$")
    {
        n := s + 0
        frac := n - Floor(n)

        if (n >= 0 && n < 1)
            frac := n

        if (frac > 0)
        {
            totalMinutes := Round(frac * 1440)
            if (totalMinutes >= 1440)
                totalMinutes -= 1440

            hh := Floor(totalMinutes / 60)
            mm := Mod(totalMinutes, 60)
            return Format("{:02}:{:02}", hh, mm)
        }
    }

    s := RegExReplace(s, "[`r`n]+", " ")
    s := RegExReplace(s, "[ `t]+", " ")
    return Trim(s)
}

SSOK_Expense_WorkPublic_TargetDisplay(attendees, attendeeCount)
{
    names := Trim(attendees . "", " `t`r`n,")
    names := RegExReplace(names, "[`r`n]+", ", ")
    names := RegExReplace(names, "[ `t]+", " ")

    count := attendeeCount + 0
    if (count > 0)
        count := Round(count)

    ; ¿¹: È«±æµ¿, ÀÌ¼ø½Å µî 5¸í
    if (names != "" && count > 0)
        return names . " µî " . count . "¸í"

    if (names != "")
        return names

    if (count > 0)
        return count . "¸í"

    return ""
}

SSOK_Expense_WorkPublic_MerchantPlaceDisplay(merchant, place)
{
    merchant := Trim(merchant . "", " `t`r`n")
    place := Trim(place . "", " `t`r`n")

    if (place = "")
        return merchant

    if (merchant = "")
        return place

    mKey := SSOK_Expense_WorkPublic_HeaderKey(merchant)
    pKey := SSOK_Expense_WorkPublic_HeaderKey(place)

    ; °°Àº ³»¿ëÀÌ¸é Áßº¹ÇÏÁö ¾ÊÀ½
    if (InStr(mKey, pKey) || InStr(pKey, mKey))
        return merchant

    ; °ø°³¼­½Ä¿¡ º°µµ Àå¼Ò ¿­ÀÌ ¾øÀ¸¹Ç·Î ¾÷Ã¼¸í Ä­¿¡ °°ÀÌ Ç¥±â
    return merchant . " (" . place . ")"
}

SSOK_Expense_WorkPublic_ClassifyActual(title, extra := "")
{
    ; Á¦¸ñÀ» ÃÖ¿ì¼±À¸·Î ºÐ·ùÇÕ´Ï´Ù.
    ; ¿¹: "³»¹æ°´¿ë ¹°Ç° ±¸ÀÔ"ÀÇ »êÃâ³»¿ª¿¡ 'ÇùÀÇÈ¸'°¡ ÀÖ¾îµµ ¹°Ç°±¸ÀÔÀ¸·Î ºÐ·ù.
    t := SSOK_Expense_WorkPublic_HeaderKey(title)
    e := SSOK_Expense_WorkPublic_HeaderKey(extra)
    all := t . e

    if (InStr(t,"°æÁ¶") || InStr(t,"Á¶ÀÇ") || InStr(t,"ºÎÀÇ")
        || InStr(t,"ÃàÀÇ") || InStr(t,"±ÙÁ¶") || InStr(t,"Á¶¹®")
        || InStr(t,"Àå·Ê") || InStr(t,"°áÈ¥"))
        return "°æÁ¶»çºñ"

    if (InStr(t,"À§¹®") || InStr(t,"À§·Î") || InStr(t,"º´¹®")
        || InStr(t,"°Ý·Á") || InStr(t,"Æ÷»ó") || InStr(t,"Ç¥Ã¢")
        || InStr(t,"»ç±âÁøÀÛ") || InStr(t,"°Ý·ÁÇ°"))
        return "À§¹®°Ý·Á"

    if (InStr(t,"¹°Ç°±¸ÀÔ") || InStr(t,"¹°Ç°±¸¸Å")
        || InStr(t,"±¸ÀÔ") || InStr(t,"±¸¸Å") || InStr(t,"¼Ò¸ðÇ°")
        || InStr(t,"±â³äÇ°") || InStr(t,"¼±¹°") || InStr(t,"¿ëÇ°"))
        return "¹°Ç°±âÅ¸"

    if (InStr(t,"È¸ÀÇ") || InStr(t,"°£´ã") || InStr(t,"ÇùÀÇ")
        || InStr(t,"Åä·Ð") || InStr(t,"¼³¸íÈ¸") || InStr(t,"¿ÀÂù")
        || InStr(t,"¸¸Âù") || InStr(t,"´Ù°ú") || InStr(t,"½Ä»ç"))
        return "È¸ÀÇºñ"

    ; Á¦¸ñÀ¸·Î ÆÇ´ÜµÇÁö ¾ÊÀ» ¶§¸¸ ¼¼ºÎÇ×¸ñ/»êÃâ³»¿ª µîÀ» º¸Á¶·Î »ç¿ë
    if (InStr(all,"°æÁ¶»çºñ") || InStr(all,"°æÁ¶"))
        return "°æÁ¶»çºñ"

    if (InStr(all,"À§¹®") || InStr(all,"°Ý·Á"))
        return "À§¹®°Ý·Á"

    if (InStr(all,"È¸ÀÇ") || InStr(all,"°£´ã") || InStr(all,"ÇùÀÇ"))
        return "È¸ÀÇºñ"

    ; Á÷Ã¥±Þ ¾÷¹«¼öÇà°æºñ µîÀº °ø°³¼­½ÄÀÇ '¹°Ç°±¸ÀÔºñ, ±âÅ¸¿î¿µºñ µî'À¸·Î Ã³¸®
    return "¹°Ç°±âÅ¸"
}

SSOK_Expense_WorkPublic_MapPayment(s)
{
    key := SSOK_Expense_WorkPublic_HeaderKey(s)

    if InStr(key, "Ä«µå")
        return "¹ýÀÎÄ«µå"

    if InStr(key, "°èÁÂÀÌÃ¼")
        return "°èÁÂÀÌÃ¼"

    return Trim(s)
}

SSOK_Expense_WorkPublic_FindActualTemplateLayout(wb, ByRef errMsg)
{
    errMsg := ""

    ; ------------------------------------------------------------
    ; ½ÇÁ¦ ¾÷·ÎµåÇÑ "1 ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª.xlsx" ¼­½ÄÀÇ È®Á¤ ÁÂÇ¥¸¦ »ç¿ëÇÕ´Ï´Ù.
    ; Excel COMÀ¸·Î ÀüÃ¼ ¼¿À» ¼øÈ¸ÇÏÁö ¾ÊÀ¸¹Ç·Î 0x800A03EC ¿À·ù¸¦ ÇÇÇÕ´Ï´Ù.
    ;
    ; A1:I40
    ; 1. ÁýÇàÃÑ°ý       : 2~6Çà
    ; 2. À¯Çüº° »ç¿ëÇöÈ²: 8~11Çà
    ; 3. »ç¿ë ³»¿ª      : 13~40Çà
    ; ------------------------------------------------------------
    try
        ws := wb.Worksheets(1)
    catch e
    {
        errMsg := "¾÷¹«ÃßÁøºñ ¼­½ÄÀÇ Ã¹ ¹øÂ° ½ÃÆ®¸¦ ¿­Áö ¸øÇß½À´Ï´Ù.`n`n" . e.Message
        return ""
    }

    ; ÃÖ¼ÒÇÑÀÇ ±âÁØ ¼¿¸¸ È®ÀÎÇÕ´Ï´Ù.
    ; ¼¿ ÀüÃ¼ °Ë»öÀº ÇÏÁö ¾Ê½À´Ï´Ù.
    titleText := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(1,1)))
    summaryText := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(2,1)))
    typeText := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(8,1)))
    detailText := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(13,1)))

    if !InStr(titleText, "¾÷¹«ÃßÁøºñÁýÇà³»¿ª")
    {
        errMsg := "A1¿¡¼­ ¾÷¹«ÃßÁøºñ ÁýÇà³»¿ª Á¦¸ñÀ» È®ÀÎÇÏÁö ¸øÇß½À´Ï´Ù."
        return ""
    }

    if !InStr(summaryText, "ÁýÇàÃÑ°ý")
    {
        errMsg := "A2¿¡¼­ '1. ÁýÇàÃÑ°ý'À» È®ÀÎÇÏÁö ¸øÇß½À´Ï´Ù."
        return ""
    }

    if !InStr(typeText, "À¯Çüº°»ç¿ëÇöÈ²")
    {
        errMsg := "A8¿¡¼­ '2. À¯Çüº° »ç¿ëÇöÈ²'À» È®ÀÎÇÏÁö ¸øÇß½À´Ï´Ù."
        return ""
    }

    if !InStr(detailText, "¾÷¹«ÃßÁøºñ»ç¿ë³»¿ª")
    {
        errMsg := "A13¿¡¼­ '3. ¾÷¹«ÃßÁøºñ »ç¿ë ³»¿ª'À» È®ÀÎÇÏÁö ¸øÇß½À´Ï´Ù."
        return ""
    }

    ; ½ÇÁ¦ ¼­½ÄÀÇ µ¥ÀÌÅÍ ÀÔ·ÂÄ­
    groups := {}

    ; È¸ÀÇºñ: ±âº» Ç¥½ÃÇà 20~28Çà + ¼û±è ¿¹ºñÇà 29, 15~19Çà
    ; 9°ÇÀ» ÃÊ°úÇÏ¸é ¿¹ºñÇàÀ» ÀÚµ¿À¸·Î Ç¥½ÃÇØ¼­ »ç¿ëÇÕ´Ï´Ù.
    meetingSlots := [20,21,22,23,24,25,26,27,28,29,15,16,17,18,19]

    groups["È¸ÀÇºñ"] := {groupRow:15
        , subtotalRow:30
        , slots:meetingSlots}

    ; À§¹®¡¤°Ý·Á: 31Çà, 32Çà ¼Ò°è
    encourageSlots := [31]
    groups["À§¹®°Ý·Á"] := {groupRow:31
        , subtotalRow:32
        , slots:encourageSlots}

    ; °æÁ¶»çºñ: 33Çà, 34Çà ¼Ò°è
    condolenceSlots := [33]
    groups["°æÁ¶»çºñ"] := {groupRow:33
        , subtotalRow:34
        , slots:condolenceSlots}

    ; ¹°Ç°±¸ÀÔºñ¡¤±âÅ¸¿î¿µºñ: 35~38Çà, 39Çà ¼Ò°è
    otherSlots := [35,36,37,38]
    groups["¹°Ç°±âÅ¸"] := {groupRow:35
        , subtotalRow:39
        , slots:otherSlots}

    return {ws:ws
        ; Á¦¸ñ
        , titleRow:1
        , titleCol:1

        ; 1. ÁýÇàÃÑ°ý
        , budgetRow:5
        , budgetCol:2
        , priorCol:4
        , currentCol:5
        , cumCol:6
        , budgetRatioRow:6

        ; 2. À¯Çüº° »ç¿ëÇöÈ²
        , typeHeaderRow:9
        , typeAmountRow:10
        , typeRatioRow:11
        , typeCols:{meeting:2
            , encourage:4
            , condolence:5
            , other:6
            , total:8}

        ; 3. ¾÷¹«ÃßÁøºñ »ç¿ë ³»¿ª
        , detailHeaderRow:14
        , detailCols:{date:2
            , time:3
            , content:4
            , amount:6
            , target:7
            , merchant:8
            , payment:9}

        , groups:groups
        , totalRow:40}
}

SSOK_Expense_WorkPublic_FindActualSubtotalRow(ws, startRow, lastRow)
{
    r := startRow

    while (r <= lastRow)
    {
        ; ¼Ò°è°¡ º´ÇÕ¼¿ ¾îµð¿¡ ÀÖµç ÇØ´ç Çà ÀüÃ¼¸¦ È®ÀÎ
        Loop, 9
        {
            c := A_Index
            key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

            if (key = "¼Ò°è")
                return r
        }

        r++
    }

    return 0
}

SSOK_Expense_WorkPublic_VisibleRows(ws, startRow, endRow)
{
    rows := []

    r := startRow
    while (r <= endRow)
    {
        hidden := false
        try hidden := ws.Rows(r).Hidden

        if (!hidden)
            rows.Push(r)

        r++
    }

    return rows
}

SSOK_Expense_WorkPublic_CheckActualCapacity(layout, rows, ByRef errMsg)
{
    errMsg := ""
    counts := {"È¸ÀÇºñ":0, "À§¹®°Ý·Á":0, "°æÁ¶»çºñ":0, "¹°Ç°±âÅ¸":0}

    for _, row in rows
    {
        if counts.HasKey(row.category)
            counts[row.category]++
        else
            counts["¹°Ç°±âÅ¸"]++
    }

    for _, cat in ["È¸ÀÇºñ","À§¹®°Ý·Á","°æÁ¶»çºñ","¹°Ç°±âÅ¸"]
    {
        slots := layout.groups[cat].slots
        if (counts[cat] > slots.Length())
        {
            errMsg := "¾÷¹«ÃßÁøºñ ¼­½ÄÀÇ '" . SSOK_Expense_WorkPublic_ActualCategoryDisplay(cat) . "' ºó ÇàÀÌ ºÎÁ·ÇÕ´Ï´Ù."
            errMsg .= "`nÇÊ¿ä: " . counts[cat] . "°Ç / ¼­½Ä ºó Çà: " . slots.Length() . "°Ç"
            return false
        }
    }

    return true
}

SSOK_Expense_WorkPublic_ClearActualDetail(ws, layout)
{
    ; B:I µ¥ÀÌÅÍ ¿µ¿ª¸¸ Áö¿ö A¿­ À¯Çü¸í/¼­½ÄÀº À¯ÁöÇÕ´Ï´Ù.
    ; ¼¿À» ÇÏ³ª¾¿ Áö¿ì´Â ´ë½Å 4°³ ±¸°£À¸·Î ÀÏ°ý Ã³¸®ÇÏ¿© ¼Óµµ¸¦ ÁÙÀÔ´Ï´Ù.
    try ws.Range("B15:I29").ClearContents()

    ; È¸ÀÇºñ ¿¹ºñÇàÀº ±âº»ÀûÀ¸·Î ¼û°Ü µÎ°í,
    ; ½ÇÁ¦ °Ç¼ö°¡ 9°ÇÀ» ³ÑÀ» ¶§¸¸ ÇÊ¿äÇÑ ¸¸Å­ ´Ù½Ã Ç¥½ÃÇÕ´Ï´Ù.
    try ws.Rows("15:19").Hidden := true
    try ws.Rows("29:29").Hidden := true
    try ws.Range("B31:I31").ClearContents()
    try ws.Range("B33:I33").ClearContents()
    try ws.Range("B35:I38").ClearContents()

    cols := layout.detailCols

    for _, cat in ["È¸ÀÇºñ","À§¹®°Ý·Á","°æÁ¶»çºñ","¹°Ç°±âÅ¸"]
    {
        g := layout.groups[cat]
        try ws.Cells(g.subtotalRow, cols.content).ClearContents()
        try ws.Cells(g.subtotalRow, cols.amount).ClearContents()
    }

    try ws.Cells(layout.totalRow, cols.content).ClearContents()
    try ws.Cells(layout.totalRow, cols.amount).ClearContents()
}

SSOK_Expense_WorkPublic_WriteActualDetail(ws, layout, rows)
{
    cols := layout.detailCols
    buckets := {"È¸ÀÇºñ":[], "À§¹®°Ý·Á":[], "°æÁ¶»çºñ":[], "¹°Ç°±âÅ¸":[]}

    for _, row in rows
    {
        cat := buckets.HasKey(row.category) ? row.category : "¹°Ç°±âÅ¸"
        buckets[cat].Push(row)
    }

    totalCount := 0
    totalAmount := 0

    for _, cat in ["È¸ÀÇºñ","À§¹®°Ý·Á","°æÁ¶»çºñ","¹°Ç°±âÅ¸"]
    {
        list := buckets[cat]
        slots := layout.groups[cat].slots
        subRow := layout.groups[cat].subtotalRow
        catTotal := 0

        usedCount := list.Length()

        ; 0°ÇÀÌ¾îµµ ÀÔ·ÂÄ­ 1°³´Â Ç×»ó Ç¥½Ã
        visibleCount := (usedCount > 0) ? usedCount : 1

        for slotIndex, slotRow in slots
        {
            if (slotIndex <= visibleCount)
                try ws.Rows(slotRow).Hidden := false
            else
                try ws.Rows(slotRow).Hidden := true
        }

        for idx, row in list
        {
            r := slots[idx]

            ; »ç¿ëÀÏÀÚ
            try ws.Cells(r, cols.date).NumberFormat := "@"
            ws.Cells(r, cols.date).Value2 := SSOK_Expense_WorkPublic_DateDisplay(row.date)

            ; ¿¹»ê°Å·¡Ã³º°½ÇÀûÀº °ø¶õ / ¾÷¹«ÃßÁøºñ¸ñ·ÏÀº K¿­ ½Ã°£
            if (cols.time)
                ws.Cells(r, cols.time).Value2 := row.time

            ; ³»¿ª
            ws.Cells(r, cols.content).Value2 := row.title

            ; ±Ý¾×
            ws.Cells(r, cols.amount).Value2 := row.amount

            ; ¾÷¹«ÃßÁøºñ¸ñ·Ï: Âü¼®ÀÚ¸í´Ü + Âü¼®ÀÚ¼ö -> "È«±æµ¿, ÀÌ¼ø½Å µî 5¸í"
            ; ¿¹»ê°Å·¡Ã³º°½ÇÀû: °ø¶õ
            if (cols.target)
                ws.Cells(r, cols.target).Value2 := row.target

            ; ¿¹»ê°Å·¡Ã³º°½ÇÀû: ¼ö·ÉÀÎ
            ; ¾÷¹«ÃßÁøºñ¸ñ·Ï: »ç¿ëÃ³(´ëÇ¥) + Àå¼Ò
            merchantText := SSOK_Expense_WorkPublic_MerchantPlaceDisplay(row.merchant, row.place)
            ws.Cells(r, cols.merchant).Value2 := merchantText

            ; °æÁ¶»çºñ¸¸ °èÁÂÀÌÃ¼, ³ª¸ÓÁö´Â ¸ðµÎ ¹ýÀÎÄ«µå
            paymentText := (cat = "°æÁ¶»çºñ") ? "°èÁÂÀÌÃ¼" : "¹ýÀÎÄ«µå"
            ws.Cells(r, cols.payment).Value2 := paymentText

            catTotal += row.amount
        }

        ws.Cells(subRow, cols.content).Value2 := list.Length() . "°Ç"
        ws.Cells(subRow, cols.amount).Value2 := catTotal

        totalCount += list.Length()
        totalAmount += catTotal
    }

    ws.Cells(layout.totalRow, cols.content).Value2 := totalCount
    ws.Cells(layout.totalRow, cols.amount).Value2 := totalAmount
}

SSOK_Expense_WorkPublic_WriteActualTypeSummary(ws, layout, summary, currentTotal)
{
    r := layout.typeAmountRow
    rr := layout.typeRatioRow
    c := layout.typeCols

    ws.Cells(r, c.meeting).Value2 := summary["È¸ÀÇºñ"]
    ws.Cells(r, c.encourage).Value2 := summary["À§¹®°Ý·Á"]
    ws.Cells(r, c.condolence).Value2 := summary["°æÁ¶»çºñ"]
    ws.Cells(r, c.other).Value2 := summary["¹°Ç°±âÅ¸"]
    ws.Cells(r, c.total).Value2 := currentTotal

    if (currentTotal > 0)
    {
        ws.Cells(rr, c.meeting).Value2 := summary["È¸ÀÇºñ"] / currentTotal
        ws.Cells(rr, c.encourage).Value2 := summary["À§¹®°Ý·Á"] / currentTotal
        ws.Cells(rr, c.condolence).Value2 := summary["°æÁ¶»çºñ"] / currentTotal
        ws.Cells(rr, c.other).Value2 := summary["¹°Ç°±âÅ¸"] / currentTotal
        ws.Cells(rr, c.total).Value2 := 1
    }
    else
    {
        ws.Cells(rr, c.meeting).Value2 := 0
        ws.Cells(rr, c.encourage).Value2 := 0
        ws.Cells(rr, c.condolence).Value2 := 0
        ws.Cells(rr, c.other).Value2 := 0
        ws.Cells(rr, c.total).Value2 := 0
    }
}

SSOK_Expense_WorkPublic_GetOrgName()
{
    global SSOK_IniFile, SSOK_ConfigDir

    iniFile := SSOK_IniFile
    if (iniFile = "" && SSOK_ConfigDir != "")
        iniFile := SSOK_ConfigDir . "\\ssok.ini"

    orgName := ""

    if (iniFile != "" && FileExist(iniFile))
    {
        IniRead, orgName, %iniFile%, MajorTodos, OrgName, __SSOK_EMPTY__
        if (orgName = "__SSOK_EMPTY__" || orgName = "ERROR")
            orgName := ""
    }

    orgName := Trim(orgName, " `t`r`n")

    ; µµ´ãÁß -> µµ´ãÁßÇÐ±³ / µµ´ãÃÊ -> µµ´ãÃÊµîÇÐ±³
    if (orgName != "")
    {
        if RegExMatch(orgName, "Áß$")
            orgName .= "ÇÐ±³"
        else if RegExMatch(orgName, "ÃÊ$")
            orgName .= "µîÇÐ±³"
    }

    return orgName
}

SSOK_Expense_WorkPublic_CreateBuiltInTemplate(outputPath, ByRef errMsg)
{
    errMsg := ""

    b64 := ""
    b64 .= "UEsDBBQABgAIAAAAIQB0NlqmegEAAIQFAAATAAgCW0NvbnRlbnRfVHlwZXNdLnhtbCCiBAIooAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACsVM1OAjEQvpv4DpteDVvwYIxh4YB6VBLwAWo7sA3dtukMCG/vbEFiDEIIXLbZtvP9TGemP1w3rlhBQht8"
    b64 .= "JXplVxTgdTDWzyvxMX3tPIoCSXmjXPBQiQ2gGA5ub/rTTQQsONpjJWqi+CQl6hoahWWI4PlkFlKjiH/TXEalF2oO8r7bfZA6eAJPHWoxxKD/DDO1dFS8rHl7"
    b64 .= "q+TTelGMtvdaqkqoGJ3VilioXHnzh6QTZjOrwQS9bBi6xJhAGawBqHFlTJYZ0wSI2BgKeZAzgcPzSHeuSo7MwrC2Ee/Y+j8M7cn/rnZx7/wcyRooxirRm2rY"
    b64 .= "u1w7+RXS4jOERXkc5NzU5BSVjbL+R/cR/nwZZV56VxbS+svAJ3QQ1xjI/L1cQoY5QYi0cYDXTnsGPcVcqwRmQly986sL+I19QodWTo9qLpErJ2GPe4yfW3qc"
    b64 .= "QkSeGgnOF/DTom10JzIQJLKwb9JDxb5n5JFzsWNoZ5oBc4Bb5hk6+AYAAP//AwBQSwMEFAAGAAgAAAAhALVVMCP0AAAATAIAAAsACAJfcmVscy8ucmVscyCi"
    b64 .= "BAIooAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACskk1PwzAMhu9I/IfI99XdkBBCS3dB"
    b64 .= "SLshVH6ASdwPtY2jJBvdvyccEFQagwNHf71+/Mrb3TyN6sgh9uI0rIsSFDsjtnethpf6cXUHKiZylkZxrOHEEXbV9dX2mUdKeSh2vY8qq7iooUvJ3yNG0/FE"
    b64 .= "sRDPLlcaCROlHIYWPZmBWsZNWd5i+K4B1UJT7a2GsLc3oOqTz5t/15am6Q0/iDlM7NKZFchzYmfZrnzIbCH1+RpVU2g5abBinnI6InlfZGzA80SbvxP9fC1O"
    b64 .= "nMhSIjQS+DLPR8cloPV/WrQ08cudecQ3CcOryPDJgosfqN4BAAD//wMAUEsDBBQABgAIAAAAIQCRhdoPrwMAAJEIAAAPAAAAeGwvd29ya2Jvb2sueG1spFbd"
    b64 .= "bts2FL4f0HfQhNzKFGVbtoXYRWxHmIGkCJosuTQYibY4S6RGUbG8onfdE2zDbtrr3exqKIb2meKH6KFkOXFcDF4q2KT49/E753yH1PHLIomNOyozJnjfxA3b"
    b64 .= "NCgPRMj4vG/+eOVbXdPIFOEhiQWnfXNFM/Pl4MV3x0shF7dCLAwA4FnfjJRKPYSyIKIJyRoipRxGZkImREFTzlGWSkrCLKJUJTFybNtFCWHcrBA8eQiGmM1Y"
    b64 .= "QMciyBPKVQUiaUwU0M8ilmY1WhIcApcQuchTKxBJChC3LGZqVYKaRhJ4kzkXktzGYHaB20Yh4efCH9tQOPVOMLS3VcICKTIxUw2ARhXpPfuxjTDecUGx74PD"
    b64 .= "kFpI0jumY7hlJd1nsnK3WO4DGLa/GQ2DtEqteOC8Z6K1t9wcc3A8YzG9rqRrkDR9RRIdqdg0YpKp05ApGvbNDjTFku50yDwd5iyG0abddFwTDbZyvpBGSGck"
    b64 .= "j9UVCLmGh8xw3Z7T1jNBGCexopITRUeCK9Dhxq5v1VyJPYoEKNx4TX/OmaSQWKAvsBVKEnjkNrsgKjJyGVcezHTK/URt7DhWsmpkEZE0FYxXwkvBOYKTGLFk"
    b64 .= "lfN5JKY0V4rmyRTWhDnNpguJ6mTK0C+I5EpEQi1WCI4AWjTR/T9/rD98Wn/+eP/be/RI8WQ/vf6H5kmgHYnAk5W11ftTr4LR0qt1faGkAe+T8RnE9pLcQaRB"
    b64 .= "T+HmIJhAKHFzygPp4embrt/tOC4eW51TPLJarju2eif+yLJxT3e7w54/egvGSNcLBJgcbUSkoftmCxSzN3ROinoE217Owgcab+zNY+n6SVGPvdUG6+PymtFl"
    b64 .= "9iA33TSKG8ZDseybTtftglWrum1hB5rLcvSGhSqCKT27te37gbJ5BJRxu6MnQl5pan1zh9K4ouTDY+lihxJ6xKk8mYFbWRu8zKb1n7/e//1x/e/v67/e3X9+"
    b64 .= "B3eBPr5Ld5uG9PRmchLiMpz1esgfxmmo0xHQHrU2mNMi5knjQoJKpydwJegEDUh8WSPb5uDJtt8fnRxh72hy1LKP0SNA0M3uZgATQAbrquTYw7bT0+Rooc4y"
    b64 .= "VdaQPAxcNGx3h3az51gtH/tWC/dsazh0W1Z77DfbHTwenbZ9LRJ9u3mFRpw989DqonI1JSqHhNa5XLY9Xfqb3m3nrOrYuGonp7zXY23KZvV/TbyE2zumB072"
    b64 .= "rw+cOHp1fnV+4Nyz06vpjV/K4qvWIggIRK8OC6q/JgZfAAAA//8DAFBLAwQUAAYACAAAACEAkgeU7AQBAAA/AwAAGgAIAXhsL19yZWxzL3dvcmtib29rLnht"
    b64 .= "bC5yZWxzIKIEASigAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "rJLLasQwDEX3hf6D0b5xMn1QhnFm0VKYbZt+gHCUOExiB1t95O9rUjrJwJBusjFIwvceibvbf3et+CQfGmcVZEkKgqx2ZWNrBe/Fy80jiMBoS2ydJQUDBdjn"
    b64 .= "11e7V2qR46dgmj6IqGKDAsPcb6UM2lCHIXE92TipnO+QY+lr2aM+Yk1yk6YP0s81ID/TFIdSgT+UtyCKoY/O/2u7qmo0PTv90ZHlCxYy8NDGBUSBviZW8Fsn"
    b64 .= "kRHkZfvNmvYcz0KT+1jK8c2WGLI1Gb6cPwZDxBPHqRXkOFmEuV8TRmOrnww2doI5tZYucrdqKAx6Kt/Yx8zPszFv/8HIs9jnPwAAAP//AwBQSwMEFAAGAAgA"
    b64 .= "AAAhAL2dbVH+DgAAQ0EAABgAAAB4bC93b3Jrc2hlZXRzL3NoZWV0MS54bWy0XFlvI7kRfg+Q/yDoKcFiJPWp7oathSW1DiCbLDK7ybNGbtnCWGql1fYci/z3"
    b64 .= "FMkiWTykkW3FGFvjYrFIfizWwcM3P3/dPXVequa4rfe33aA36Haq/bq+3+4fbru//zb7kHU7x3a1v1891fvqtvutOnZ/Hv35Tzdf6ubz8bGq2g5I2B9vu49t"
    b64 .= "eyj6/eP6sdqtjr36UO2hZFM3u1ULvzYP/eOhqVb3vNLuqR8OBml/t9ruu0JC0Vwio95stutqWq+fd9W+FUKa6mnVQv+Pj9vDUUrbrS8Rt1s1n58PH9b17gAi"
    b64 .= "Pm2ftu03LrTb2a2L5cO+blafnmDcX4N4te58beBfCN+RbIbTnZZ223VTH+tN2wPJfdFnd/h5P++v1kqSO/6LxARxv6letmwCtajwbV0KEiUr1MKiNwpLlTAG"
    b64 .= "V1M8b+9vu38M8OsDfAbsx0D/kGX/7Y5uuJ782oxuDquH6mPV/n74telstu1v9a9AAF3t9kc3fcV1vwWFYCB0mmpz270LimWcMhbO8a9t9eVI/t9pV58+Vk/V"
    b64 .= "uq2gT0G309aHv1WbdlI9PUFlGPz3ut59XK/Y3A9hUahf/84UGngYka2BT3X9mUlfgpwB6zaXyvqxWrfbl0pInAUAwfE/vGvw/2IJv6vus+pyKLSjM752YNT3"
    b64 .= "1Wb1/NT+s/6yqLYPjy30OO0lgClTyuL+27Q6rmE1QAd6XOy6foLBws/ObstWNSjz6iv//LK9bx9vu+Gwl4YgYP18bOvdvwWRA6oqAQS8EvQbKwVZ7wd1YqwD"
    b64 .= "n7JOfrYR6AJvBD6xQjLoZcPzPUuxEnzKVn48nCFWgk/ZUtyLftAS2D7ePfiUwCW9H9SBAfM68CnrRCdw64t54go6XbWr0U1Tf+mAGYAJOx5WzKgGBchhEx7D"
    b64 .= "fIjZUipwYv5h4pmMOyYE6sFcQPUjaObLKA1u+i+gaWvkGSse0EVea+JQpg6ldCgzhzJ3KAuHsqSUPgxdjR/GetH428ft+vO4ZuvBD0YCwxZoMJG33QgWrUIj"
    b64 .= "iEw0poInZwuTVyptwkIQYtBPLSU2pSwVD1vfdFTMArx7VpmQ224Caqx7kFizijygOZonNXkmgicdqMFOkQIfutbQrFUiT6xqzRzKHCmJ4ln4+pNZqGEtbrEN"
    b64 .= "1EB/r60LTCRgmKkejgUlFRaQrZ4JUkKNj6AwC6jxyS18PDzhwOSZCZ4hqImSE1rrco48wpiz/iycHi6RMuR+hOoZ9PByxH6rDydXj1o8TCJwUdUIQ0vpBA94"
    b64 .= "xdHNZhQMozRlnj0aQpg3AAg2zP4EURozsqWLWFWjPxWUMOTCZsmHElScS8iCOA9zS0BpssequTAIs8zGH1uLuUXMozQMhhbLHFmICqtK0jYsBSXnS8FQWHBL"
    b64 .= "11ZYJvK2C15Ia4xlu8aCJc04YuOkP5aIWao1QUZt5aaCEke86pRUHfSSfBjkYZJF+WAIUxlYq7YUVSPRakmqZr0sy4JhGCUZKEA4SKLyg6UxM1E5ZzZ6M5oZ"
    b64 .= "7aZZOhjGEXxneTSMA8vCzbEqtxbcVC/U+NUEIY+7PsB2vt8OMyGwJLQlHDuUiUOZIkUrVulQ5k6thUNZUoqhfCxbu8THvMJzMpGW5wwtnzcWPMFAwzFxSVOX"
    b64 .= "VCJJAzJDipY0dygLQTnvhhWP7YbBLV4bIiYSgmrDddpOWfDkxiK2eCbIQ9YmSqZBXGi58tLHYznuma91azHPndYXghIMaNQUWj5vKZlEPkYdUQD1ruyJuEjL"
    b64 .= "FUWW+R5LpgH6D8Yg/E+Qug5hoti1u50iLRTubBaB7eISEuHNaBBd2rywODiv7XiQL5EyAUgf31zyaX+4kCQxIBjgT9DqT7Pg7MCWspZINY2ZuTTDeIWdCEQ4"
    b64 .= "f9ZLIU/CnO9mBOPow9Dk5FhRgeTVtmGKpDAQrsqoHvfCPE/TfJglUTqIs9hxOKVZHRAkrTuTJUaDPQWkT/PO3Z4u6EAh7rGCXVnqRrvBpamPN/VXqZ/IQWD+"
    b64 .= "pTccc8GwcEiI65KmkqTD3tIlzdyKc5e0cElLg2T4Lb49Yjkulqw5Ke9rFFLkFEbOF1lTIfZlIE2mYb0dDvLOcR4J58IlsR0dnnBzfTUH58th4h5o2LuGh8mG"
    b64 .= "kQra+T3yGIvSXmeCJ4LuqPDSzowhzuFjg5hK8VgxQCl5eMDFg7IZkkLavB3KIY/RvOXhFj4ey8MtZVs069UezpwPX4YUsQ21x+39fSV2zPxTc1G6FGBuQN1m"
    b64 .= "ZMcDyBTppTaRJOqHUBRdkEjSXDNZkQRNkkRyGEnSUfNSktwgOfClMdfECMNzaqIwm6CIIIkigsmQHkXJ+wr5EdU8rEgRQRJFBEkUESR5EPHlDT9E5LydFnF8"
    b64 .= "TkEQJEMtkERBEKSMgoAkCgJWpCAgiYKAJAoCkjwg+BKMd4IgInUDBMw5qCYgiYIgSAYISKIgYEUKApIoCEiiICDJA4Ivhbjm2sBInKqFIBlqgSSKiCAZiCCJ"
    b64 .= "IoIVKSJIooggiSKCJBcRiJPdSJ8j8g4zyoXedqliIAlgYNtJcRqyvR4ajE8kB9vNeBnBDkZofllmeIr8ABnxfnaGJZkIiLIdsY0Ux7DLYfZkLjloZBHbnk0y"
    b64 .= "GY7Vdm2SiXr6WA/E3Dr3Rfb+mThrmiDGZh7fAF+QCPj2pjJWihT4bB8w0F8W/xT5TfDtPWfJRMHHngjwYdvB2VOcy65Q9FMHfZRjoG/vTEtJF6HvC9/fgj6e"
    b64 .= "PBALAJuhfB9Gq77V0YnkkOgPYd+OftmnHUKgCb69wYcyqWuVzSD4Qx/42FcKfmKtj4WUY4Bvby5IpovA9x2wvAV8Ecgbqo+phAI/sTYzJ2zzh22TKfDhdkMe"
    b64 .= "6y8bfMFugm+fJqBMA3xsRoCfxKm9vT2XHTGwt7KehWQyrJ5zkIVtXYS9L8V5C/Yi0TCwx/xEY29lJ5MQOZTZGZpf1lxNkd8A33YkpWSiZgfbQc2P8sg1+shi"
    b64 .= "oG+1v5D9pegn1qCWkuki9E8mNK87MmaHW7bRFyRt9BNLTSZYSWu+afMDi3+K/Cb6loKWkomijz0R6Ech24qzXS6yGOhbHn8h+2ug7+g+SroI/ZOp0ivRd1Oi"
    b64 .= "UKVEGO+kTryjMiSMdxLD7NgBxxQlmuhbClpKJoq+Sqj4QR6/qGOjrxIsHUoljstVKRdhcgIelYSR7YZTAc/JtOyV6Lu5WKhyMYm+Y/VVaibQTwf5kMabljud"
    b64 .= "okQTfWvll5KJoq8yOdbO0N2Ensu+no93VKpHwHfiHZX8XQD+yXTwleC7OSDbNGIOVZn91AFfpYQC/DijsWZgmZQpCjSxtzexJBPFXiWQXPMTOC527I5KKDVk"
    b64 .= "9kpdyAEZdseJd1TSeQH4b0pDz0f9buYZupmnJJHME0k085QkCqWbeUpZJPOUJJJ5SpKbebLdXfuMKcrJJS1yXeoVe8dcLKQ/ert8jCR6b8OavYlikfvEU6TE"
    b64 .= "7IT8ZWQHeLJUH/jNkDTkJxwff//lL7C5V8zC/K/njrDmWIvcF3EoS9mYc1+Ebb1eCuFZ7eGCYB/OuGRlH84hU5TLFD61T0Elh07hgyTUEV1mL2zZLJ0Z21iU"
    b64 .= "konsmiIpZudxLyPPyd5cctCtcbu7Cy+THc1JJtrHUyk8mLz/i0pjvkdVWpDOqrRgIYdwvHtwGgKWSl8stO2oZKKajYdSbOI3I67aUVDMokCqtncGRCVy0QMl"
    b64 .= "63lcyrZcxfYkhKdsw3nFVhkhuftl36WEABgdlrpMKUnEUCIp05fPSkmiWKk0T8qaS1n0Xh1yGVmco3kqi3PuI3pytmuYTkzhqJ7hMRTRGMd0ShZtOvHMSZhO"
    b64 .= "y4yUEZZS0ASJmM4oAv2KpH7ZXhtFUKOJ2Zs6Nl3KZlzd8qRcb9MtkWkYRpNdNzDu6UYqC9O6hSSqWyiK6haSKEwqj9K6pfImdcApWyROWJI8TtiTASEY1zlR"
    b64 .= "i0RCkGnlHyOJ7ohLEoUEK5KDEimLxCWyItkRlyS63FTqou6YSS4PJJ605LqQiDDdgETlK1pLVIKi1xVWpJAgiUKiMg6tJUiikKiEQkOi0gfH3niShQsgOW+Z"
    b64 .= "8cCHKoZKHDQKKlPQKGBFigKSKAoq9tcoqFhfrxUk0bWi4ngHBU/Ufg2ri+c81OoK0lnvLliod0c5YpfFuf+tSuXgZxDIMbdHrS4ErFF20uoKfurRbcoSZbp3"
    b64 .= "ayFWe9U502VvA7hUGAL1o4FtgiWT1o4JkuD4WamV5BJOy95Nl6XEGiMJdlz4LdgIbnVFIXzH8C0viAW+e8xz2bru0MIlLSWJ+wTzYv2Vwv5xLE5R3Pt/7M3K"
    b64 .= "NRKLMRckX3zRe2xwaflKLYgoyTOGVwRJ5yzVmD3EYTeGnUiCXT16F0qgfPhuCB68vVuUeFEnniPtquaBP2A7dtb1M3tgBg9PRjeKLJ7aTcO8KCFDh37YJVFa"
    b64 .= "lOAjfSUJlHC7Y9cJQFrglRYOoB1+JOb0IIASDq1TkkEJV36nJIQSfsPAKYmghAcRTkkMJdwsOSUwHthZ9ow0BAxgeftKhlDCl68lbZwXcBfYrTHLC7il69IX"
    b64 .= "eQHXcF06XLAs2PVWT0lWwHVsT58C6FPg69M0ACQDX51FUsBrCE+vsmLpbwMQEUbTGvcsLeBqv0dSWix99FlcwFMZD05JAW84XPpdPCjGYBE944aS0ltyB0nq"
    b64 .= "nYgyHe0GrYPE3qfdoFsn6oAGQVLhqwN6D47P0+sogR741xfMVuSdLUh9WGLpkxaBNH8PYIbhLYenDuxB3cH+kU9fQO/hFpmvDjxy9c2Nfv3qrHzARryocJCG"
    b64 .= "2fG2DxdzC3Zh2qMzUMJuQPtWRQCrwt+3AKT5SuBCL0jzloQFPPnz4Vzc+VAeRwU8LvPNfwFP5zzjgMfCXjlpAW95PKNLigmfj7623vCG+hFe77fbNXtCXe9b"
    b64 .= "9liZxYXfDvC8eV9P6j3+CQAm8NBs9+0/DvxFfeexbrbfocbqaQIvjKtGPJdmXPAI+5dV87DdHztP8HKaPT5OgiALgkEIj6rCQQwnId1OI94re8vgzTWvZVUD"
    b64 .= "R/mpbuFd8onCR/gjAhW8iYPHzvAaLB2kcPEbIqQkz6Dmpq6hl/5C7DW8JX8+dA6rQ9V83H4HAFj8KV56w/upDgwYRsr/oMBt91A3bbPatjCQgr1eb5b3woOr"
    b64 .= "P38w+h8AAAD//wMAUEsDBBQABgAIAAAAIQB1ro+8aQcAAAMhAAATAAAAeGwvdGhlbWUvdGhlbWUxLnhtbOxZ3YscNxJ/P7j/QfT7eL6652PxOMynN/aubbxj"
    b64 .= "hzxqZzTT8qpbg6TZ9RAMweHgAuHgIAl5CeQtDyFc4AIX7uX+GIPNne/+hyupe6alHU127ayPXNhd2J3W/KpUqir9VF26+d7ThKFTIiTlaSeo3qgEiKQTPqXp"
    b64 .= "vBM8Go9KrQBJhdMpZjwlnWBFZPDerd//7ibeUzFJCAL5VO7hThArtdgrl+UEhrG8wRckhe9mXCRYwaOYl6cCn4HehJVrlUqjnGCaBijFCai9P5vRCUG1SrWO"
    b64 .= "SvCvVkP/+cNnr7/9Y3BrPdOQwXSpknpgwsSRnofsFDdy05OqRsuV7DOBTjHrBGDAlJ+NyVMVIIalgi86QcX8BOVbN8t4LxdiaoesJTcyP7lcLjA9qZk5xfx4"
    b64 .= "M2kYRmGju9FvAExt44bNYWPY2OgzADyZwKozW1ydzVo/zLEWKPvo0T1oDupVB2/pr2/Z3I30r4M3oEx/uIUfjfrgRQdvQBk+2sJHvXZv4Oo3oAzf2MI3K91B"
    b64 .= "2HT0G1DMaHqyha5EjXp/vdoNZMbZvhfejsJRs5YrL1CQDZtM01PMeKouk3cJfsLFCMBaiGFFU6RWCzLDE0j1Pmb0WFB0QOcxJOECp1zCcKVWGVXq8Ff/huaT"
    b64 .= "iS7eI9iS1jaCVXJrSNuG5ETQheoEd0BrYEFe/vTTi+c/vnj+txeffPLi+V/yuY0qR24fp3Nb7vW3f/731x+jf/31m9eff5FNfR4vbfyr7z999fd//Jx6WHHh"
    b64 .= "ipdf/vDqxx9efvWnf373uUd7V+BjGz6mCZHoHjlDD3kCC/TYT47Fm0mMY0wdCRyDbo/qoYod4L0VZj5cj7gufCyAcXzA28snjq1HsVgq6pn5bpw4wEPOWY8L"
    b64 .= "rwPu6rksD4+X6dw/uVjauIcYn/rm7uPUCfBwuQDapT6V/Zg4Zj5gOFV4TlKikP6OnxDiWd2HlDp+PaQTwSWfKfQhRT1MvS4Z02MnkQqhfZpAXFY+AyHUjm8O"
    b64 .= "H6MeZ75VD8ipi4RtgZnH+DFhjhtv46XCiU/lGCfMdvgBVrHPyKOVmNi4oVQQ6TlhHA2nREqfzH0B67WCfhcYxh/2Q7ZKXKRQ9MSn8wBzbiMH/KQf42ThtZmm"
    b64 .= "sY19X55AimL0gCsf/JC7O0Q/QxxwujPcjylxwn0xETwCcrVNKhJEf7MUnljeJtzdjys2w8THMl2ROOzaFdSbHb3l3EntA0IYPsNTQtCj9z0W9PjC8Xlh9J0Y"
    b64 .= "WGWf+BLrDnZzVT+nRBJkapxtijyg0knZIzLnO+w5XJ0jnhVOEyx2ab4HUXdSF045L5XeZ5MTG3iPQo0I+eJ1yn0JOqzkHu7S+iDGztmln6U/X1fCid9l9hjs"
    b64 .= "yydvui9BhryxDBD7pX0zxsyZoEiYMYYCw0e3IOKEvxDR56oRW3rlZu6mLcIARZJT7yQ0vbD4OVf2RP+bssdfwFxBweNX/EtKnV2Usn+uwNmF+z8sawZ4mT4g"
    b64 .= "cJJsc9Z1VXNd1QS/+apm116+rmWua5nrWsb39vVOapmifIHKpuj4mP5Pcqn2z4wydqRWjBxI0wGS8HYzHcGgaVOZvuWmNbiI4WPeeHJwc4GNDBJcfUBVfBTj"
    b64 .= "BbSJqqaxOZe56rlECy6he2SGTe+VnNNtelDL5JBPsw5otaq7nZk7JVbFeCXajEPHSmXoRrPo6m3Umz7p3HRi1wZo2TcxwprMNaLuMaK5HoSI/JwRZmVXYkXb"
    b64 .= "Y0VLq1+Hah3FjSvAtE1U4PUbwUt7J4jCrLMMjTko1ac6TlmTeR1dHZwrjfQuZzI7A6DcXmdAEem2tnXn8vTqslS7RKQdI6x0c42w0jCGl+I8O+1W/FXGul2E"
    b64 .= "1DFPu2K9Gwozmq13EWtNKOe4gaU2U7AUnXWCRj2Ca5gJXnSCGXSP4WOygNyR+g0Msznc00yUyDb82zDLQkg1wDLOHG5IJ2ODhCoiEKNJJ9DL32QDSw2HGNuq"
    b64 .= "NSCEX61xbaCVX5txEHQ3yGQ2IxNlh90a0Z7OHoHhM67wfmvE3x6sJfkSwn0UT8/QMVuKhxhSLGpWtQOnVMIlQjXz5pTCDdmGyIr8O3cw5bRrX1GZHMrGMVvE"
    b64 .= "OD9RbDLP4IZEN+aYp40PrKd8zeDQbRcez/UB+4tP3YuPau05izSLM9NhFX1q+sn03R3yllXFIepYlVG3eb+WBde111wHieo9JS44dS9xIFimFZM5pmmLt2lY"
    b64 .= "c3Y+6pp2hQWB5YnGDr9tzgivJ9725Ae581mrD4h1jWkS39yx2zff/PgJkMcA7hKXTEkTSrjLFhiKvuxmMqMN2CJPVV4jwie0FLQTfFSJumG/FvVLlVY0LIX1"
    b64 .= "sFJqRd16qRtF9eowqlYGvdozOFhUnFSj7H5/BNcZbJXf8pvxrZv+ZH1jc2PCkzI3N/llY7i56a/WLrrpH+ub/ABRIKCPGrVRu97uNUrtendUCge9Vqndb/RK"
    b64 .= "g0a/ORgN+lGrPXoWoFMDDrv1ftgYtkqNar9fChsVvZRWu9QMa7Vu2Oy2hmH3WV7SgBcyKsn9Aq42Nt76LwAAAP//AwBQSwMEFAAGAAgAAAAhAEGyC4A8CgAA"
    b64 .= "S3kAAA0AAAB4bC9zdHlsZXMueG1s7F1bj+RGFX5H4j9YXoESRI+vfZt0d8jsbEOkBEXsIIGSaOXpds9Y60tjuzc9QUh54IXHCBAvuxIPkeCRCIR4yC/KTP4D"
    b64 .= "p8q3crfdLnt8KSNeZmy3XfXVqXOrU6eqZu/uLZN7pbue4dhzXjoTeU63V87asG/m/C+vloMJz3m+Zq8107H1OX+ne/y7i+9/b+b5d6b+/FbXfQ6KsL05f+v7"
    b64 .= "23NB8Fa3uqV5Z85Wt+GXjeNamg+37o3gbV1dW3voI8sUZFEcCZZm2HxQwrm1oinE0tyXu+1g5VhbzTeuDdPw73BZPGetzt+/sR1XuzYB6l5StRW3l0auzO3d"
    b64 .= "qBL89Kgey1i5juds/DMoV3A2G2OlH8OdClNBWyUlQcnVSpKGgiin2r53K5akCq7+ykDdxy9m9s5aWr7HrZyd7c95NX7EBb+8v4Y+Ho94LuiVp84a6PTirR9x"
    b64 .= "T3785In44u130PUnb+G7T4K7H/5m5/jvDIJ/+I2fvHibF6K6UgWP0wX/VLd1VzODT7/9+l/BRc63wGckqAjQx7/Q15/GiHK+naa/Fc/EH6A3hZAci9nGsROq"
    b64 .= "SDL0IOKN85e285m9RL8BWYBW6LXFzPuce6WZ8ERChawc03E5H3gaSIWf2JqlB2/c/+3LhzdfcN/+86/3f/ozenmjWYZ5F/yo4K9vNdcDEQkKlKfoGRaQsATL"
    b64 .= "AHbFWIO6g7/X6K0QhSwnKAx7re916MMJJkSM42e//u4vX93/8fX9m28e3vznw0MkQTsykAhkpVGFB2VXa2PLJbPRVZLaFcPELNsZgjyWzRacWhiWrBJkmgFZ"
    b64 .= "DRigXf0gjVhiujwNVb+mxBrGA5VrmGZs8EZIicODxQx8A1937SXccOH11d0WVLgNbkygcPF7BW/fuNqdJA/pP/Ac01gjFDdPScMhohKuw2cxkUZYXAUCKxit"
    b64 .= "AFEBrpxqwLL7BrL84tlwOp2OFGU8Hk8mI3kywW1oHcFUmUxH8nQiiWpbCNSEBmOgwUQaTSaTqapIqoqVRBka4M4AJrt23DX4yLFfNYEeDp4tZqa+8aFzXePm"
    b64 .= "Fv33nS3qasf3wZFczNaGduPYmonckegL8ktwrsGPnvOWvjZ2FhQb+BuHLIIqCeuIvvBvwXPOex+jwWAoKwDYEeroi7WzAz86t4qgifQtPImXaF9Aw/KwSxCb"
    b64 .= "FkpFUp8sPoPQBX3fFKEpSXzMSj1pX5qROgKdoxkoad9011PqkFihdQz7QL0yQsQC8U3kp2kyNmZDmDJoTVExktR+Kn36vq9qX2uWtkeSu6C9zVnZirjZUqFU"
    b64 .= "PJ5Bw5P2gtZYtSxotWBm2E3vV/s6dsMaHzyVGIUwNOTrfux0pB9rZeumx55UbFVWPz7WULOgrMub6UZQU7vojYYdGhf4ssq10wjPkcTXhKYuB60j4rQ0/GAi"
    b64 .= "uNcRv7bsgDbE19XDDjX3ffNhh1rNK1VhufHoAtoxOmZiBHVpM9xX3L2MkJf31bq12OV9teiLfpl2ZvqlQS+akZ75fwvRLHZ6ErtT49t4vOZ/u3UNxnXaH1KH"
    b64 .= "+ROQjrHSTfM5ypv41SbOyVAgUWG/IdJRIZMZpTeilFd0Cdk+4WWQfhHcLGaaadzYlm5Djqbu+sYKZX6u4FYP0jL3m4Niw/TZoGDINckpmNO2W/MO5Zbi6oM7"
    b64 .= "wJDcXeCckuT+vQhI8ugj1/H1lY9Ts0VoX1msOC+WVaQC2YtBnxLdKYnDSh3K7TdN92xQg8STXYyyh8v2DsGgw4SPFJ5LGBRuovakawvvMENFSCKGiu4JhkrD"
    b64 .= "u3Vc43PgTILVqzB/IehDEnUEmoLOIMdM0ZkCMlC/f6wRg2aENaQxXnYQqEhqfv75zrrW3SVe2ILWBNQomnQ2KJs94GmiOSTQ/af4owVlQWWAD0A2oLMIGKiz"
    b64 .= "s/2Ak7RqABRhmQtBwXIVwpl4lLbHuUg8pbLvCGPofFGCpBAFpUC7tysKaPFVKR58lGNRuraA1ZoVQ0LRwmWiswBsL0xaCjSIb7ZDyJS3k4JcYBrQmonErLXi"
    b64 .= "VWZbYZDbDFc4UoCdW+HUSJDg6ZQdhuV7J/mDmrx0ngGhs/MQxWOKR9qVCsPlxolEjmxK2bpsM5KSGuC7HowRUpDVDjFzn7na9krfQ/wDrz8VjiIpFDRX4B3G"
    b64 .= "TAKhqiQirpSiO6yDTtuEBnVVHSyf2xCGeT4Xc5dMD/HWk3yeD5q1SA8hnCTolG3LFc5Huay5NFKY81tQ+DcMMec52on9B2rhYRyNLmjB6ZKJHibAg1OQ+FzV"
    b64 .= "wDfpPxZbFRAkhvqkqhNCz07BFEMzMeBiasOK916IQClvJE8cVNbCxFhVhgqI2t1vTP+U4nUaxlGPYtyM6M5U2DiXW47CGYx7gblWgN2BTy7tYw88srppNdlB"
    b64 .= "iKPKyJwNUSUcBbTBExsB9GzvJeWeFoQTK/lYVe15f5zaHMc/HVdgb1iOtx47PY9XyZp0oCkomoK3MAsTHehHFR20BW81d9QtKTFVCiaFq0dIKdzXYC+8AoCx"
    b64 .= "Isme6u0eYHMU9G5dw3555SyN/DgeVRxcOYqJVRy4HIWdORqMFNY3JmIrcXEKQImQs4JIiSe7WkFEE5SPETHi6FFglllzTmkw92/yAwW4+jZhI/eRnVkLy9Kw"
    b64 .= "M8PhdiKQk3K65X4kKaYxH/ncHY/DaXiDtTQUCswKa/zcor9VeQK0TResMsiUc40QZ4VfioZQNQz8ygV3yWFVLuiCYVXboGnErIc5IEqcgMRMKLTNoEA9gpc7"
    b64 .= "uVJXaKDZLI6eJBek062Ym2wbE4G53HjukQPf0qRP5azp/NyffvhuqViiXKCg682rqJriloIMRxe0uFCjlnlwmWF9kjuJyRo3S6Q6IezL6fV/rGuTPEOJtEx7"
    b64 .= "y5GKuZzw/ZEAZnrVcLLCAebG5mPRdjMZy3LKhrbzm3IUcuxtU46VT3+b0l5+y2MYLHtglDZirYp3UZZtrhJq1dRmoqTRO8loPhqx9ZbDlX6o0HZnMKsPSSkk"
    b64 .= "8WgWk5F0PxolEkcqotlFNrDTZG7VNTHa5AKmLvPna1kNpHY4o1fPcqYeTpXBoUkMr8qtGhGvedklXZS+sTyiqg5RExmSOZ5mBBHv+gP7/BCbOKW2cIo3BeLQ"
    b64 .= "MXpz/v4fX9//+/cPr/8ecSFaoLIzTDjmDO3zg081O/zm4Q/ffPfla+5j8VNiHR7xUXBiXrSHVFgRfPHw1RcErxMf4NPbkv2KAPx6n+w8hX/10ZmzeE+quDmg"
    b64 .= "rdb6RtuZ/lX845xPrj/ER35Be8K3PjJeOT4uYs4n1x+gHdmCQ/5gMeUHHuzOBv+5nWvM+d8+uxhPL58t5cFEvJgMVEUfDqbDi8vBUH16cXm5nIqy+PR30CZ0"
    b64 .= "QO85nHn6iHNv8UG9sBeWpJ57JpyO64aNDcE/T57NeeImgI/PzwPYJPapPBLfG0riYKmI0kAdaZPBZKQMB8uhJF+O1Itnw+WQwD6seD6uKEhScNIuAj889w1L"
    b64 .= "Nw076quoh8in0Elwe6IRQtQTQnIK8uK/AAAA//8DAFBLAwQUAAYACAAAACEAOX/vpycFAAB4FwAAFAAAAHhsL3NoYXJlZFN0cmluZ3MueG1stFhRTxpZFH43"
    b64 .= "8T/czFObWBFMrRqg2TVpusk28aH7sI8sjpUEBpYZTd0nlNHgglFWKaADgQ0tssFkxNGMifuH5p75D3vuXLrVNdjZXjVGZGDOnHPud77znRN++T6VJGtyVk2k"
    b64 .= "lYgUnJySiKzE00sJ5V1E+untq2ezElG1mLIUS6YVOSKty6r0Mjo+FlZVjeC9ihqRVjQtMx8IqPEVORVTJ9MZWcFPltPZVEzDt9l3ATWTlWNL6oosa6lkIDQ1"
    b64 .= "NRNIxRKKROLpVUWLSLPTEllVEr+uygv8wswLKRpWE9GwFn3i2AWotGnxBAydzBM43n8aDmjRcGYFPdIS8cUsWU4r2g9LEQnNaOsZdFNJL6SVYVhSIBoOMFvc"
    b64 .= "nnPRJ4Re6iI2YLMPRz1oXENzX8hO0XBMIU/opkUIVE+FMmIX0EalLRRJt+x+2KGlHOQ3hOxUt2Bg0b+2hAIamNAyqNmjg4qQM9sl51wMKIZO+/YEcQY92uoQ"
    b64 .= "au6R8THobiCIEUOObRLo6tAsi0X7N7RNNEevxHy1GuT2j2DwwUmMjsECrIZjjfQt5KNo/w8J+LH3NRLwYwNqBdg076kbX0a6ZYIZuq/8/JjBo3fOW6NQ5MuR"
    b64 .= "lg7Hh85VCbo5ETu0eIV27uFXX+EUMBwhwEB1i/YtuDzE+rqnLnxhD+8H42Rk0/FjI4SlYLTcWoWe64R3D7emu/WeSKrdoxI0ahMMP2gSScbUadHCq4QenAlh"
    b64 .= "wSdriT7HGXyduXzBpX/t/lHAmobmFh7WBHIsUqubz8GRBbUNvCTsqSAaOQ2ObrE+omRqa17NxOIob1BOqXJ2TZaiZBqRdRvrQ3wRlAaCwoD+J6/jY+SB8/pM"
    b64 .= "CKYNi3YL7u82VPepXaKf+nTXhIYlXlOCjAHVPv2kw6BFaH4HZQgmzWv1HhoZFAkUDdA7/OCIY+Vo62R4jMStlbGqWRVDsYPfE4kmNBWacSt1uqXTPZ3gf87F"
    b64 .= "vmPvQLHxBMU05LEt5zBtni55/d3CwiL69nTo1b9+sPLBpoD3PZwrIeYLqh/2yry7zH2J+zGeh3GD0abnFxgIywOGzgRTO0dQwaNC41T6GE/mD6PdJlx23O0L"
    b64 .= "t9JDF1D+Ec5Nd8KGS6ET58C6caz80DE+bKhcsQxFGbYK7NWPm/bPx+yYBjY+t37Iz4FnwC098qFDw2atFllir44UQeihST/at8oAuzIrg8eBPM4g06yOR0Lg"
    b64 .= "gUsMpx0W8pVFD4QwxCEDzY9cWrQqjIjYO/L92x85bGG7hFc8Kpu7Z1jz1bwPDNo+dfMjZyBfRoodunvo7l4L9ZP8Bk6vdLMuKIGHpEZ4hTHIb/aJaJo4XXGe"
    b64 .= "8lCLFBIMCuYeWjpzz5tHyfPngtYccx/0M9Bt+BOH+FNWe62R6xFfM0mzTMvoXhmqqObQVVbMQt3d64B3kP0gOB7JcS9ED6nXZhxWvBKKvGbTJgoLC9pn1BSj"
    b64 .= "h4ZJxaZ5hjlkD6jbZFYoOVm2IGQiBzUEmfXyE8Br7HcR//yCmz/1N7IWS0akUIjtAePpZDpLEsqS/F7GfeEsu5Z9hdtD/qXXP7vVDrInxc1ew37DPl2OpRLJ"
    b64 .= "df5x0DOxEsuq8vCGYGjOWy96j9OiOPkSVFpY+NApcxq9q869WeCmOmcuf+Myc24yOIkKhmAh4+xDvhSzW6/h5OMJu1uLJmigmDN0t2J8FiBc5OOtbHoSos+K"
    b64 .= "zlQvtotjoaoPOmdCRX4jF2KOYALhQ5nz9wTBHRtKZUblTMB/O24DuDmP/gMAAP//AwBQSwMEFAAGAAgAAAAhADttMkvBAAAAQgEAACMAAAB4bC93b3Jrc2hl"
    b64 .= "ZXRzL19yZWxzL3NoZWV0MS54bWwucmVsc4SPwYrCMBRF9wP+Q3h7k9aFDENTNyK4VecDYvraBtuXkPcU/XuzHGXA5eVwz+U2m/s8qRtmDpEs1LoCheRjF2iw"
    b64 .= "8HvaLb9BsTjq3BQJLTyQYdMuvpoDTk5KiceQWBULsYVRJP0Yw37E2bGOCamQPubZSYl5MMn5ixvQrKpqbfJfB7QvTrXvLOR9V4M6PVJZ/uyOfR88bqO/zkjy"
    b64 .= "z4RJOZBgPqJIOchF7fKAYkHrd/aea30OBKZtzMvz9gkAAP//AwBQSwMEFAAGAAgAAAAhADEkBJJDBAAAXBMAACcAAAB4bC9wcmludGVyU2V0dGluZ3MvcHJp"
    b64 .= "bnRlclNldHRpbmdzMS5iaW7sV0tvHEUQrvq6t6f3vd5dO3bix3gTvwJ27MQJDuSxyeZhAwkhkBAgQAxjCSRkSzxukViQOOSGOOY3QOCGIvlCTj5x44bChR+B"
    b64 .= "hNBSPTO21w5Yix1MrKRarZnunqr6uurrx9z6uX3pt3s3f7r5wzB9QJdplE7RGbpKPtXoEB2lg3SERuifhXWf+oXqRfUrE1OSbqcnbSBvHl0D5ElSWWxObmBj"
    b64 .= "s0POOkIP0XO9ndrs/MK8dHZ3xCOi4HQShuhP/V2SbhT1rVKNZmmeFqT6dJ7m5DlHH0ks3pP2JfqQPqWP5e0KnZPo+DQjZb04DA2P6Lq6IK8csAIrpZGACZjl"
    b64 .= "Pa8L4tNrbliV5BSnkUEWOeQVpdwoFEI1eLBIOkOuh90gxA5rTqTEpgdPefKh9cVz+gFFKgechSVSUrXUhG98z6dsaDB2wJRbto8EG133dNXqKuVdr/WV9fUa"
    b64 .= "R+I457FVVIjUHBY2LF22mAS1CQoqBmx9KCo5uLqibIXmAonHqiMYiAaSSEHmrrKc47wqoI2LXOIy2tGBXehUXdiNPehGD3rRBx/9qGAv9mEAgxjCMEawH0/x"
    b64 .= "0zzKY3yAx3mCD/IhnuTDfISfwRQfxbN4DsdwHCdwElWc4tOo8RlbP4tzOI9pzOB5vIAXcQEX8RIugeAwmjD8uiIgXfx1SgtIXc2qnMpzgdtUESWUOUaJEKXu"
    b64 .= "1j26V/cZQckV3ssxSh7mEd7PghKjwVhwIBjHGpQ8hRClOsbH+QSf5CrHKHHWrIDUzSBfxmVbeQWv4gqu4jVcw+t4wzb4TVzHW3gb7/ANnlXvglTEwNUMccg1"
    b64 .= "znAYbzeTKN6m3XSYXabT6/J28x7u5h7u5T4VrEyFywNcHuTyEJdJ6GD7YduU/ZwSMQdc/kkICeGpLWhbiEiuhP0qocIwMtmI9yxdtt8Yz1iTNCmTNhmTNY77"
    b64 .= "kn8UTUmRMF4sZSULtitaEEbJWpXciD+36qanyHcrWEtNSpkUct9Ok+xSUXWkf1/aE19uPMr4Qvan72VldXY6e0G4gYhVZzgvTSGzK07EXChfueYn3y7ejdub"
    b64 .= "engEZxdLLWl/RnRxYX6OJg6PzdRqrTt8uHpgiYZs5jtGXKKSUhuNnYP5P0b6tdgfv0OLW3GzVf3pBxfSrJyvm5N6vb6ieE/4GYsnFw9PVrGcxq3J+J3fF4vf"
    b64 .= "+LTvx/bW1uQ6syuet4VqNuN2LLlZZWSHkj3MTVbE0h8NV4iXIjyJsF+2mqQIWLa3DUSWd7DxF9syt0fCSbTLRUGs132HqYUMP1wSyBkROy03xST0YaMBd7j9"
    b64 .= "e6muUym7U+7vb85byYXY3EFnxeND7W2dqSPWfbWGpY4UzdXhcdetZQ66MdcmkutLWN378i3sSZ4epQgkouu3O2mZlKTVNv1i5N1PEA/wIA/FP0Ed1Fp5kuTH"
    b64 .= "PgLyJ/6/xCA+tVZvkptEwdSQEslfAAAA//8DAFBLAwQUAAYACAAAACEANNHAS+8AAAA7AgAAEAAAAHhsL2NhbGNDaGFpbi54bWx0kV1OwzAQhN+RuIO179RJ"
    b64 .= "UypAcSqVxOIAcADLWZpI/olsC8HtMahOqElfLOXz7OxkXB8+tSIf6PxoDYNyUwBBI20/mhODt1d+9wDEB2F6oaxBBl/o4dDc3tRSKPk8iNGQ6GA8gyGE6YlS"
    b64 .= "LwfUwm/shCbevFunRYif7kT95FD0fkAMWtFtUeypjgbQ1JI4BryKy8cYAoj6OemZH8uZxzUL59X2rE9KXu0y0l2dfcyUx/vcbBm9jLNfTdlekfNdSp9SdmkT"
    b64 .= "ufiddh2/zL5pvl0P0CU8t5GDtozV/ha8VJuT7p+G/yV0fvbmGwAA//8DAFBLAwQUAAYACAAAACEAbaFuhF4BAABeAgAAEQAIAWRvY1Byb3BzL2NvcmUueG1s"
    b64 .= "IKIEASigAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAfJJLTsMw"
    b64 .= "FEXnSOwh8jyxk34oVpJKfDoCCdFWIGaW/dpGJE5kG9IugD0wYQOMGbAnYA84SRtSgRja9/r4+MnheJ2lziMoneQyQr5HkAOS5yKRywjNZxN3hBxtmBQszSVE"
    b64 .= "aAMajePDg5AXlOcKrlRegDIJaMeSpKa8iNDKmIJirPkKMqY925A2XOQqY8Yu1RIXjN+zJeCAkCHOwDDBDMMV0C1aItoiBW+RxYNKa4DgGFLIQBqNfc/HP10D"
    b64 .= "KtN/HqiTTjNLzKawb9rqdtmCN2HbXuukLZZl6ZW9WsP6+/j28mJaP9VNZDUrDigOBadcATO5iufT8+sQdzaq4aVMm0s750UC4mQTf768fbw+fT2/h/h3aGG1"
    b64 .= "e0ME4Vgb2rjvkpve6dlsguKABIHrE5cMZuSI9gntBXfV3XvnK7tmI9sa/E8cuuTYDfwZGdD+iPr9DnEHiGvv/R8RfwMAAP//AwBQSwMEFAAGAAgAAAAhAI48"
    b64 .= "U2jfAQAAuQMAABAACAFkb2NQcm9wcy9hcHAueG1sIKIEASigAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApFO/b9QwFN6R+B+C955zparQyXFVXUEdQJx0166VcV7uLBLbst3ojgmkY6EMDEUMPSQmunRCFYK/Ken/gJO0aY4i"
    b64 .= "Btjej0+fv/e9Z7Izz9IgB2OFkhHq90IUgOQqFnIaoYPJk41HKLCOyZilSkKEFmDRDr1/j4yM0mCcABt4CmkjNHNODzC2fAYZsz3flr6TKJMx51MzxSpJBIc9"
    b64 .= "xY8zkA5vhuE2hrkDGUO8oVtC1DAOcvevpLHilT57OFloL5iSXa1TwZnzU9JnghtlVeKCx3MOKcHdJvHqxsCPjXALGhLcTcmYsxSGnpgmLLVA8G2B7AOrTBsx"
    b64 .= "YSwluRvkwJ0ygRWvvG1bKHjBLFRyIpQzI5h0XlYFa5I6TrV1hpZn76/eXJQnq6t3Pwj2kKZch110NxZbtF8DfPBX4PUTny+Lr8ugPH9dfvlYfFgFxbfTcrX8"
    b64 .= "/9cquc3gXsa6JRPhUrDPkxEz7g8ObXYdqlU2/lwL/vS2uLgsv5+W58vi55rQ1qByHfNgZIR0R7sG2J256tV4hb9pGqpMM7nwjTZ6KuRLe6Anao85uFn7epGM"
    b64 .= "Z8xA7C+lPYu2QPb9xk1akQxnTE4hvsHcbVRHetj8RNrf7oUPQ39/nRrBt3+O/gIAAP//AwBQSwECLQAUAAYACAAAACEAdDZapnoBAACEBQAAEwAAAAAAAAAA"
    b64 .= "AAAAAAAAAAAAW0NvbnRlbnRfVHlwZXNdLnhtbFBLAQItABQABgAIAAAAIQC1VTAj9AAAAEwCAAALAAAAAAAAAAAAAAAAALMDAABfcmVscy8ucmVsc1BLAQIt"
    b64 .= "ABQABgAIAAAAIQCRhdoPrwMAAJEIAAAPAAAAAAAAAAAAAAAAANgGAAB4bC93b3JrYm9vay54bWxQSwECLQAUAAYACAAAACEAkgeU7AQBAAA/AwAAGgAAAAAA"
    b64 .= "AAAAAAAAAAC0CgAAeGwvX3JlbHMvd29ya2Jvb2sueG1sLnJlbHNQSwECLQAUAAYACAAAACEAvZ1tUf4OAABDQQAAGAAAAAAAAAAAAAAAAAD4DAAAeGwvd29y"
    b64 .= "a3NoZWV0cy9zaGVldDEueG1sUEsBAi0AFAAGAAgAAAAhAHWuj7xpBwAAAyEAABMAAAAAAAAAAAAAAAAALBwAAHhsL3RoZW1lL3RoZW1lMS54bWxQSwECLQAU"
    b64 .= "AAYACAAAACEAQbILgDwKAABLeQAADQAAAAAAAAAAAAAAAADGIwAAeGwvc3R5bGVzLnhtbFBLAQItABQABgAIAAAAIQA5f++nJwUAAHgXAAAUAAAAAAAAAAAA"
    b64 .= "AAAAAC0uAAB4bC9zaGFyZWRTdHJpbmdzLnhtbFBLAQItABQABgAIAAAAIQA7bTJLwQAAAEIBAAAjAAAAAAAAAAAAAAAAAIYzAAB4bC93b3Jrc2hlZXRzL19y"
    b64 .= "ZWxzL3NoZWV0MS54bWwucmVsc1BLAQItABQABgAIAAAAIQAxJASSQwQAAFwTAAAnAAAAAAAAAAAAAAAAAIg0AAB4bC9wcmludGVyU2V0dGluZ3MvcHJpbnRl"
    b64 .= "clNldHRpbmdzMS5iaW5QSwECLQAUAAYACAAAACEANNHAS+8AAAA7AgAAEAAAAAAAAAAAAAAAAAAQOQAAeGwvY2FsY0NoYWluLnhtbFBLAQItABQABgAIAAAA"
    b64 .= "IQBtoW6EXgEAAF4CAAARAAAAAAAAAAAAAAAAAC06AABkb2NQcm9wcy9jb3JlLnhtbFBLAQItABQABgAIAAAAIQCOPFNo3wEAALkDAAAQAAAAAAAAAAAAAAAA"
    b64 .= "AMI8AABkb2NQcm9wcy9hcHAueG1sUEsFBgAAAAANAA0AZAMAANc/AAAAAA=="

    return SSOK_Expense_WorkPublic_WriteBase64File(b64, outputPath, errMsg)
}

SSOK_Expense_WorkPublic_WriteBase64File(b64, outputPath, ByRef errMsg)
{
    errMsg := ""
    size := 0

    if !DllCall("Crypt32.dll\CryptStringToBinaryW"
        , "WStr", b64
        , "UInt", 0
        , "UInt", 1
        , "Ptr", 0
        , "UIntP", size
        , "Ptr", 0
        , "Ptr", 0)
    {
        errMsg := "³»Àå ¼­½Ä Å©±â È®ÀÎ¿¡ ½ÇÆÐÇß½À´Ï´Ù."
        return false
    }

    VarSetCapacity(bin, size, 0)

    if !DllCall("Crypt32.dll\CryptStringToBinaryW"
        , "WStr", b64
        , "UInt", 0
        , "UInt", 1
        , "Ptr", &bin
        , "UIntP", size
        , "Ptr", 0
        , "Ptr", 0)
    {
        errMsg := "³»Àå ¼­½Ä º¹¿ø¿¡ ½ÇÆÐÇß½À´Ï´Ù."
        return false
    }

    f := FileOpen(outputPath, "w")
    if !IsObject(f)
    {
        errMsg := "³»Àå ¼­½Ä ÆÄÀÏÀ» ¿­Áö ¸øÇß½À´Ï´Ù."
        return false
    }

    written := f.RawWrite(bin, size)
    f.Close()

    if (written != size || !FileExist(outputPath))
    {
        errMsg := "³»Àå ¼­½Ä ÆÄÀÏ ÀúÀå¿¡ ½ÇÆÐÇß½À´Ï´Ù."
        return false
    }

    return true
}

SSOK_Expense_WorkPublic_WriteActualOverall(ws, layout, currentMonth, prevCum, currentTotal, noReferenceA := false)
{
    ; Á¦¸ñ
    newTitle := ""
    yearText := SubStr(currentMonth, 1, 4)
    monthText := SubStr(currentMonth, 5, 2) + 0
    orgName := SSOK_Expense_WorkPublic_GetOrgName()

    if (yearText != "" && monthText > 0)
        newTitle := yearText . "³â " . monthText . "¿ù"

    if (orgName != "")
    {
        if RegExMatch(orgName, "Áß$")
            orgName .= "ÇÐ±³"
        else if RegExMatch(orgName, "ÃÊ$")
            orgName .= "µîÇÐ±³"

        if (newTitle != "")
            newTitle .= " "
        newTitle .= orgName
    }

    newTitle .= " ¾÷¹«ÃßÁøºñ ÁýÇà ³»¿ª"

    try ws.Range("A1:I1").Merge
    try ws.Range("A1").Value2 := newTitle

    ; ------------------------------------------------------------
    ; A °ø°³¼­½ÄÀÌ ¾ø´Â °æ¿ì
    ; ¿¹»ê¾× / Àü¿ù±îÁö ½ÇÀûÀº ¹«Á¶°Ç °ø¶õ
    ; ------------------------------------------------------------
    if (noReferenceA)
    {
        try ws.Cells(layout.budgetRow, layout.budgetCol).ClearContents()
        try ws.Cells(layout.budgetRow, layout.priorCol).ClearContents()

        ; È¤½Ã ³»Àå¼­½Ä¿¡ ³²¾Æ ÀÖ´Â °ª/¼ö½ÄÀÌ ÀÖ´õ¶óµµ ´Ù½Ã ÇÑ¹ø ºó °ªÀ¸·Î °­Á¦
        try ws.Cells(layout.budgetRow, layout.budgetCol).Value2 := ""
        try ws.Cells(layout.budgetRow, layout.priorCol).Value2 := ""

        ; ´ç¿ùºÐ¸¸ ±âÀç
        ws.Cells(layout.budgetRow, layout.currentCol).Value2 := currentTotal

        ; ´©°è´Â ´ç¿ùºÐ¸¸ Ç¥½Ã
        try ws.Cells(layout.budgetRow, layout.cumCol).Formula := "=" . ws.Cells(layout.budgetRow, layout.currentCol).Address(false, false)

        ; ¿¹»ê¾×ÀÌ ¾øÀ¸¹Ç·Î ÁýÇà·ü °ü·Ã ¼¿µµ ¸ðµÎ °ø¶õ
        try ws.Cells(layout.ratioRow, layout.budgetCol).ClearContents()
        try ws.Cells(layout.ratioRow, layout.priorCol).ClearContents()
        try ws.Cells(layout.ratioRow, layout.currentCol).ClearContents()
        try ws.Cells(layout.ratioRow, layout.cumCol).ClearContents()

        try ws.Cells(layout.ratioRow, layout.budgetCol).Value2 := ""
        try ws.Cells(layout.ratioRow, layout.priorCol).Value2 := ""
        try ws.Cells(layout.ratioRow, layout.currentCol).Value2 := ""
        try ws.Cells(layout.ratioRow, layout.cumCol).Value2 := ""

        return
    }

    ; ------------------------------------------------------------
    ; A °ø°³¼­½ÄÀÌ ÀÖ´Â °æ¿ì
    ; ¿¹»ê¾×Àº ÀÌ¹Ì A Âü°í°ªÀÌ µé¾î¿Í ÀÖ°í,
    ; Àü¿ù±îÁö´Â Àü´Þ¹ÞÀº prevCum »ç¿ë
    ; ------------------------------------------------------------
    ws.Cells(layout.budgetRow, layout.priorCol).Value2 := prevCum
    ws.Cells(layout.budgetRow, layout.currentCol).Value2 := currentTotal
    ws.Cells(layout.budgetRow, layout.cumCol).Formula := "="
        . ws.Cells(layout.budgetRow, layout.priorCol).Address(false, false)
        . "+"
        . ws.Cells(layout.budgetRow, layout.currentCol).Address(false, false)

    budgetAmount := SSOK_Expense_WorkPublic_Amount(ws.Cells(layout.budgetRow, layout.budgetCol).Value2)

    if (budgetAmount != "" && budgetAmount > 0)
    {
        try ws.Cells(layout.ratioRow, layout.priorCol).Formula := "="
            . ws.Cells(layout.budgetRow, layout.priorCol).Address(false, false)
            . "/"
            . ws.Cells(layout.budgetRow, layout.budgetCol).Address(false, false)

        try ws.Cells(layout.ratioRow, layout.currentCol).Formula := "="
            . ws.Cells(layout.budgetRow, layout.currentCol).Address(false, false)
            . "/"
            . ws.Cells(layout.budgetRow, layout.budgetCol).Address(false, false)

        try ws.Cells(layout.ratioRow, layout.cumCol).Formula := "="
            . ws.Cells(layout.budgetRow, layout.cumCol).Address(false, false)
            . "/"
            . ws.Cells(layout.budgetRow, layout.budgetCol).Address(false, false)
    }
    else
    {
        try ws.Cells(layout.ratioRow, layout.budgetCol).ClearContents()
        try ws.Cells(layout.ratioRow, layout.priorCol).ClearContents()
        try ws.Cells(layout.ratioRow, layout.currentCol).ClearContents()
        try ws.Cells(layout.ratioRow, layout.cumCol).ClearContents()
    }
}

SSOK_Expense_WorkPublic_ShortDate(dateKey)
{
    if (StrLen(dateKey) < 8)
        return dateKey

    yy := SubStr(dateKey, 3, 2) + 0
    mm := SubStr(dateKey, 5, 2) + 0
    dd := SubStr(dateKey, 7, 2) + 0

    return mm . "/" . dd . "/" . yy
}

SSOK_Expense_WorkPublic_SortActualRows(ByRef rows)
{
    n := rows.Length()
    if (n < 2)
        return

    Loop, % n - 1
    {
        i := A_Index
        minIndex := i

        Loop, % n - i
        {
            j := i + A_Index
            o1 := SSOK_Expense_WorkPublic_ActualCategoryOrder(rows[j].category)
            o2 := SSOK_Expense_WorkPublic_ActualCategoryOrder(rows[minIndex].category)

            if (o1 < o2)
                minIndex := j
            else if (o1 = o2 && rows[j].date < rows[minIndex].date)
                minIndex := j
        }

        if (minIndex != i)
        {
            temp := rows[i]
            rows[i] := rows[minIndex]
            rows[minIndex] := temp
        }
    }
}

SSOK_Expense_WorkPublic_ActualCategoryOrder(cat)
{
    if (cat = "È¸ÀÇºñ")
        return 1
    if (cat = "À§¹®°Ý·Á")
        return 2
    if (cat = "°æÁ¶»çºñ")
        return 3
    return 4
}

SSOK_Expense_WorkPublic_ActualCategoryDisplay(cat)
{
    if (cat = "È¸ÀÇºñ")
        return "È¸ÀÇºñ"
    if (cat = "À§¹®°Ý·Á")
        return "À§¹®, °Ý·Á ¹× Á÷¿ø»ç±â ÁøÀÛ"
    if (cat = "°æÁ¶»çºñ")
        return "°æÁ¶»çºñ"
    return "¹°Ç°±¸ÀÔºñ, ±âÅ¸¿î¿µºñ µî"
}


SSOK_Expense_WorkPublic_ReadSource(wb, ByRef rows, ByRef info, ByRef errMsg)
{
    rows := []
    info := ""
    errMsg := ""

    sheetCount := wb.Worksheets.Count

    Loop, %sheetCount%
    {
        ws := wb.Worksheets(A_Index)

        if !SSOK_Expense_WorkPublic_FindSourceColumns(ws, headerRow, cols)
            continue

        used := ws.UsedRange
        lastRow := used.Row + used.Rows.Count - 1
        currentMonth := ""

        Loop, % lastRow - headerRow
        {
            r := headerRow + A_Index

            dateKey := SSOK_Expense_WorkPublic_DateKey(ws.Cells(r, cols.date).Value2)
            if (dateKey = "")
                continue

            amount := SSOK_Expense_WorkPublic_Amount(ws.Cells(r, cols.amount).Value2)
            if (amount = "" || amount = 0)
                continue

            content := ""
            merchant := ""
            typeText := ""

            if (cols.content)
                content := SSOK_Expense_WorkPublic_CellText(ws.Cells(r, cols.content))

            if (cols.merchant)
                merchant := SSOK_Expense_WorkPublic_CellText(ws.Cells(r, cols.merchant))

            if (cols.type)
                typeText := SSOK_Expense_WorkPublic_CellText(ws.Cells(r, cols.type))

            category := SSOK_Expense_WorkPublic_Classify(typeText . " " . content . " " . merchant)

            if (content = "")
                content := merchant

            rows.Push({date:dateKey
                , amount:amount
                , content:content
                , merchant:merchant
                , typeText:typeText
                , category:category})

            ym := SubStr(dateKey,1,6)
            if (currentMonth = "" || ym > currentMonth)
                currentMonth := ym
        }

        if (rows.Length())
        {
            info := {sheetName:ws.Name
                , headerRow:headerRow
                , currentMonth:currentMonth
                , cols:cols}
            return true
        }
    }

    errMsg := "°Å·¡Ã³º° ½ÇÀû¿¡¼­ ³¯Â¥¿Í ±Ý¾× ¿­À» Ã£Áö ¸øÇß½À´Ï´Ù."
    errMsg .= "`nÀÎ½ÄÇÏ´Â ³¯Â¥ ¿¹: »ç¿ëÀÏÀÚ, ÁýÇàÀÏÀÚ, Áö±ÞÀÏÀÚ, °áÁ¦ÀÏ, ½ÂÀÎÀÏÀÚ"
    errMsg .= "`nÀÎ½ÄÇÏ´Â ±Ý¾× ¿¹: »ç¿ë±Ý¾×, ÁýÇà±Ý¾×, Áö±Þ±Ý¾×, ÁöÃâ±Ý¾×, ¿øÀÎÇàÀ§±Ý¾×"
    return false
}

SSOK_Expense_WorkPublic_FindSourceColumns(ws, ByRef headerRow, ByRef cols)
{
    used := ws.UsedRange
    firstRow := used.Row
    firstCol := used.Column
    maxRows := used.Rows.Count
    maxCols := used.Columns.Count

    if (maxRows > 120)
        maxRows := 120
    if (maxCols > 80)
        maxCols := 80

    Loop, %maxRows%
    {
        r := firstRow + A_Index - 1
        temp := {date:0, amount:0, content:0, merchant:0, type:0}

        Loop, %maxCols%
        {
            c := firstCol + A_Index - 1
            key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

            role := SSOK_Expense_WorkPublic_SourceHeaderRole(key)

            if (role = "date" && !temp.date)
                temp.date := c
            else if (role = "amount" && !temp.amount)
                temp.amount := c
            else if (role = "content" && !temp.content)
                temp.content := c
            else if (role = "merchant" && !temp.merchant)
                temp.merchant := c
            else if (role = "type" && !temp.type)
                temp.type := c
        }

        if (temp.date && temp.amount && (temp.content || temp.merchant || temp.type))
        {
            headerRow := r
            cols := temp
            return true
        }
    }

    return false
}

SSOK_Expense_WorkPublic_SourceHeaderRole(key)
{
    if (key = "")
        return ""

    if (InStr(key,"»ç¿ëÀÏÀÚ") || InStr(key,"ÁýÇàÀÏÀÚ") || InStr(key,"Áö±ÞÀÏÀÚ")
        || InStr(key,"°áÁ¦ÀÏ") || InStr(key,"½ÂÀÎÀÏÀÚ") || InStr(key,"È¸°èÀÏÀÚ")
        || InStr(key,"¿øÀÎÇàÀ§ÀÏÀÚ") || key = "ÀÏÀÚ" || key = "³¯Â¥")
        return "date"

    if (InStr(key,"»ç¿ë±Ý¾×") || InStr(key,"ÁýÇà±Ý¾×") || InStr(key,"Áö±Þ±Ý¾×")
        || InStr(key,"ÁöÃâ±Ý¾×") || InStr(key,"¿øÀÎÇàÀ§±Ý¾×") || InStr(key,"°áÁ¦±Ý¾×")
        || InStr(key,"Ã»±¸±Ý¾×") || key = "±Ý¾×")
        return "amount"

    if (InStr(key,"ÁýÇà³»¿ë") || InStr(key,"»ç¿ë³»¿ª") || InStr(key,"ÁýÇà³»¿ª")
        || InStr(key,"ÁöÃâ³»¿ë") || InStr(key,"Ç°ÀÇÁ¦¸ñ") || key = "Á¦¸ñ"
        || key = "Àû¿ä" || key = "³»¿ë")
        return "content"

    if (InStr(key,"°Å·¡Ã³") || InStr(key,"°¡¸ÍÁ¡") || InStr(key,"¾÷Ã¼¸í")
        || InStr(key,"Ã¤ÁÖ") || InStr(key,"»ó´ëÃ³"))
        return "merchant"

    if (InStr(key,"ÁýÇàÀ¯Çü") || InStr(key,"¾÷¹«ÃßÁøºñÀ¯Çü")
        || key = "À¯Çü" || key = "±¸ºÐ")
        return "type"

    return ""
}

SSOK_Expense_WorkPublic_FindTemplateLayout(wb, ByRef errMsg)
{
    errMsg := ""

    Loop, % wb.Worksheets.Count
    {
        ws := wb.Worksheets(A_Index)

        if !SSOK_Expense_WorkPublic_FindDetailHeader(ws, detailHeaderRow, detailCols)
            continue

        if !SSOK_Expense_WorkPublic_FindSummaryLayout(ws, detailHeaderRow, summaryInfo)
            continue

        if (summaryInfo.topRow <= detailHeaderRow + 1)
            continue

        return {ws:ws
            , detailHeaderRow:detailHeaderRow
            , dataStartRow:detailHeaderRow + 1
            , detailCols:detailCols
            , summaryTopRow:summaryInfo.topRow
            , priorCol:summaryInfo.priorCol
            , currentCol:summaryInfo.currentCol
            , categoryRows:summaryInfo.categoryRows
            , totalRow:summaryInfo.totalRow
            , categoryLabelCol:summaryInfo.labelCol}
    }

    errMsg := "¼­½Ä¿¡¼­ 'ÁýÇà³»¿ª' Ç¥¿Í 'À¯Çüº° »ç¿ëÇöÈ²' Ç¥¸¦ ÇÔ²² Ã£Áö ¸øÇß½À´Ï´Ù."
    errMsg .= "`nÁýÇà³»¿ª Ç¥¿¡´Â ³¯Â¥¿Í ±Ý¾× ¿­ÀÌ ÀÖ¾î¾ß ÇÕ´Ï´Ù."
    errMsg .= "`nÀ¯Çüº° »ç¿ëÇöÈ²¿¡´Â Àü¿ù±îÁö/´ç¿ù »ç¿ë½ÇÀû ¿­ÀÌ ÀÖ¾î¾ß ÇÕ´Ï´Ù."
    return ""
}

SSOK_Expense_WorkPublic_FindDetailHeader(ws, ByRef headerRow, ByRef cols)
{
    used := ws.UsedRange
    firstRow := used.Row
    firstCol := used.Column
    maxRows := used.Rows.Count
    maxCols := used.Columns.Count

    if (maxRows > 180)
        maxRows := 180
    if (maxCols > 60)
        maxCols := 60

    Loop, %maxRows%
    {
        r := firstRow + A_Index - 1
        temp := {date:0, time:0, content:0, target:0, amount:0, type:0, merchant:0}

        Loop, %maxCols%
        {
            c := firstCol + A_Index - 1
            key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

            if (!temp.date && (InStr(key,"»ç¿ëÀÏÀÚ") || InStr(key,"ÁýÇàÀÏÀÚ")
                || InStr(key,"ÁöÃâÀÏÀÚ") || key = "ÀÏÀÚ"))
                temp.date := c
            else if (!temp.time && (InStr(key,"»ç¿ë½Ã°£") || InStr(key,"ÁýÇà½Ã°£") || key = "½Ã°£"))
                temp.time := c
            else if (!temp.content && (InStr(key,"ÁýÇà³»¿ª") || InStr(key,"»ç¿ë³»¿ª")
                || InStr(key,"ÁýÇà³»¿ë") || InStr(key,"ÁöÃâ³»¿ë") || key = "³»¿ë"))
                temp.content := c
            else if (!temp.target && (InStr(key,"ÁýÇà´ë»ó") || InStr(key,"»ç¿ë´ë»ó") || key = "´ë»ó"))
                temp.target := c
            else if (!temp.amount && (InStr(key,"»ç¿ë±Ý¾×") || InStr(key,"ÁýÇà±Ý¾×")
                || InStr(key,"ÁöÃâ±Ý¾×") || key = "±Ý¾×"))
                temp.amount := c
            else if (!temp.type && (InStr(key,"ÁýÇàÀ¯Çü") || key = "À¯Çü" || key = "±¸ºÐ"))
                temp.type := c
            else if (!temp.merchant && (InStr(key,"°Å·¡Ã³") || InStr(key,"°¡¸ÍÁ¡") || InStr(key,"¾÷Ã¼")))
                temp.merchant := c
        }

        if (temp.date && temp.amount && (temp.content || temp.time || temp.target || temp.type))
        {
            headerRow := r
            cols := temp
            return true
        }
    }

    return false
}

SSOK_Expense_WorkPublic_FindSummaryLayout(ws, detailHeaderRow, ByRef info)
{
    used := ws.UsedRange
    firstCol := used.Column
    lastRow := used.Row + used.Rows.Count - 1
    lastCol := used.Column + used.Columns.Count - 1

    categoryRows := {}
    firstCatRow := 0
    lastCatRow := 0
    labelCol := 0
    totalRow := 0
    sectionRow := 0

    if (lastRow > detailHeaderRow + 250)
        lastRow := detailHeaderRow + 250
    if (lastCol > firstCol + 60)
        lastCol := firstCol + 60

    r := detailHeaderRow + 1
    while (r <= lastRow)
    {
        c := firstCol
        while (c <= lastCol)
        {
            txt := SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c))
            key := SSOK_Expense_WorkPublic_HeaderKey(txt)

            if (!sectionRow && InStr(key,"À¯Çüº°»ç¿ëÇöÈ²"))
                sectionRow := r

            cat := SSOK_Expense_WorkPublic_TemplateCategory(txt)
            if (cat != "")
            {
                if !categoryRows.HasKey(cat)
                    categoryRows[cat] := r

                if (!firstCatRow || r < firstCatRow)
                    firstCatRow := r

                if (r > lastCatRow)
                    lastCatRow := r

                if (!labelCol)
                    labelCol := c
            }

            if (key = "ÇÕ°è" && firstCatRow && r >= firstCatRow)
            {
                if (!totalRow || r < totalRow)
                    totalRow := r
            }

            c++
        }

        r++
    }

    if (!firstCatRow)
        return false

    topRow := sectionRow ? sectionRow : firstCatRow - 3
    if (topRow <= detailHeaderRow)
        topRow := firstCatRow - 1

    priorCol := 0
    currentCol := 0

    scanStart := topRow
    if (scanStart < 1)
        scanStart := 1

    r := scanStart
    while (r <= firstCatRow)
    {
        c := firstCol
        while (c <= lastCol)
        {
            key := SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c)))

            if (!priorCol && InStr(key,"Àü¿ù"))
                priorCol := c

            if (!currentCol && InStr(key,"´ç¿ù"))
                currentCol := c

            c++
        }

        r++
    }

    if (!priorCol || !currentCol)
        return false

    if (!totalRow)
    {
        r := lastCatRow + 1
        limit := r + 5

        while (r <= lastRow && r <= limit)
        {
            c := firstCol
            while (c <= lastCol)
            {
                if (SSOK_Expense_WorkPublic_HeaderKey(SSOK_Expense_WorkPublic_CellText(ws.Cells(r,c))) = "ÇÕ°è")
                {
                    totalRow := r
                    if (!labelCol)
                        labelCol := c
                    break
                }
                c++
            }

            if (totalRow)
                break

            r++
        }
    }

    info := {topRow:topRow
        , priorCol:priorCol
        , currentCol:currentCol
        , categoryRows:categoryRows
        , totalRow:totalRow
        , labelCol:labelCol}

    return true
}

SSOK_Expense_WorkPublic_ClearDetailArea(ws, layout)
{
    startRow := layout.dataStartRow
    endRow := layout.summaryTopRow - 1

    if (endRow < startRow)
        return

    cols := layout.detailCols

    for _, col in [cols.date, cols.time, cols.content, cols.target, cols.amount, cols.type, cols.merchant]
    {
        if (!col)
            continue

        try ws.Range(ws.Cells(startRow,col), ws.Cells(endRow,col)).ClearContents()
    }
}

SSOK_Expense_WorkPublic_WriteDetail(ws, layout, rows)
{
    r := layout.dataStartRow
    cols := layout.detailCols

    for _, row in rows
    {
        displayContent := row.content

        if (displayContent = "")
            displayContent := row.merchant

        if (!cols.type)
            displayContent := "[" . SSOK_Expense_WorkPublic_CategoryDisplay(row.category) . "] " . displayContent

        ws.Cells(r, cols.date).Value2 := SSOK_Expense_WorkPublic_DateDisplay(row.date)

        if (cols.time)
            ws.Cells(r, cols.time).Value2 := ""

        if (cols.content)
            ws.Cells(r, cols.content).Value2 := displayContent

        if (cols.target)
            ws.Cells(r, cols.target).Value2 := ""

        ws.Cells(r, cols.amount).Value2 := row.amount

        if (cols.type)
            ws.Cells(r, cols.type).Value2 := SSOK_Expense_WorkPublic_CategoryDisplay(row.category)

        if (cols.merchant)
            ws.Cells(r, cols.merchant).Value2 := row.merchant

        r++
    }
}

SSOK_Expense_WorkPublic_WriteSummary(ws, layout, summary)
{
    priorTotal := 0
    currentTotal := 0

    for _, cat in ["È¸ÀÇºñ","°æÁ¶»ç","À§¹®","°Ý·Á","¹°Ç°±¸ÀÔµî"]
    {
        item := summary[cat]
        priorTotal += item.prior
        currentTotal += item.current
    }

    for key, rowNo in layout.categoryRows
    {
        priorValue := 0
        currentValue := 0

        if (key = "À§¹®°Ý·Á")
        {
            priorValue := summary["À§¹®"].prior + summary["°Ý·Á"].prior
            currentValue := summary["À§¹®"].current + summary["°Ý·Á"].current
        }
        else if summary.HasKey(key)
        {
            priorValue := summary[key].prior
            currentValue := summary[key].current
        }
        else
            continue

        ws.Cells(rowNo, layout.priorCol).Value2 := priorValue
        ws.Cells(rowNo, layout.currentCol).Value2 := currentValue
    }

    if (layout.totalRow)
    {
        ws.Cells(layout.totalRow, layout.priorCol).Value2 := priorTotal
        ws.Cells(layout.totalRow, layout.currentCol).Value2 := currentTotal
    }
}

SSOK_Expense_WorkPublic_Classify(text)
{
    s := SSOK_Expense_WorkPublic_HeaderKey(text)

    if (s = "")
        return "¹°Ç°±¸ÀÔµî"

    if (InStr(s,"°æÁ¶") || InStr(s,"Á¶ÀÇ") || InStr(s,"ºÎÀÇ")
        || InStr(s,"ÃàÀÇ") || InStr(s,"±ÙÁ¶") || InStr(s,"Á¶¹®")
        || InStr(s,"Àå·Ê") || InStr(s,"°áÈ¥") || InStr(s,"È­È¯"))
        return "°æÁ¶»ç"

    if (InStr(s,"À§¹®") || InStr(s,"À§·Î") || InStr(s,"º´¹®"))
        return "À§¹®"

    if (InStr(s,"°Ý·Á") || InStr(s,"Æ÷»ó") || InStr(s,"Ç¥Ã¢")
        || InStr(s,"»ç±âÁøÀÛ") || InStr(s,"°Ý·ÁÇ°"))
        return "°Ý·Á"

    if (InStr(s,"È¸ÀÇ") || InStr(s,"°£´ã") || InStr(s,"ÇùÀÇ")
        || InStr(s,"Åä·Ð") || InStr(s,"¼³¸íÈ¸") || InStr(s,"¿ÀÂù")
        || InStr(s,"¸¸Âù") || InStr(s,"´Ù°ú") || InStr(s,"½Ä»ç")
        || InStr(s,"½Ä´ç") || InStr(s,"Ä«Æä") || InStr(s,"À½·á"))
        return "È¸ÀÇºñ"

    if (InStr(s,"±¸ÀÔ") || InStr(s,"±¸¸Å") || InStr(s,"¹°Ç°")
        || InStr(s,"¼Ò¸ðÇ°") || InStr(s,"±â³äÇ°") || InStr(s,"¼±¹°")
        || InStr(s,"¿ëÇ°") || InStr(s,"Á¦ÀÛ") || InStr(s,"ÀÎ¼â")
        || InStr(s,"È­ºÐ"))
        return "¹°Ç°±¸ÀÔµî"

    return "¹°Ç°±¸ÀÔµî"
}

SSOK_Expense_WorkPublic_TemplateCategory(text)
{
    s := SSOK_Expense_WorkPublic_HeaderKey(text)

    if (s = "")
        return ""

    if (InStr(s,"À§¹®") && InStr(s,"°Ý·Á"))
        return "À§¹®°Ý·Á"

    if (InStr(s,"È¸ÀÇ"))
        return "È¸ÀÇºñ"

    if (InStr(s,"°æÁ¶"))
        return "°æÁ¶»ç"

    if (InStr(s,"À§¹®"))
        return "À§¹®"

    if (InStr(s,"°Ý·Á"))
        return "°Ý·Á"

    if (InStr(s,"¹°Ç°") || InStr(s,"±¸ÀÔ") || InStr(s,"±¸¸Å") || InStr(s,"±âÅ¸"))
        return "¹°Ç°±¸ÀÔµî"

    return ""
}

SSOK_Expense_WorkPublic_CategoryDisplay(cat)
{
    if (cat = "È¸ÀÇºñ")
        return "È¸ÀÇºñ"
    if (cat = "°æÁ¶»ç")
        return "°æÁ¶»ç"
    if (cat = "À§¹®")
        return "À§¹®"
    if (cat = "°Ý·Á")
        return "°Ý·Á"
    if (cat = "À§¹®°Ý·Á")
        return "À§¹®¡¤°Ý·Á"
    return "¹°Ç° ±¸ÀÔ µî"
}

SSOK_Expense_WorkPublic_SortRows(ByRef rows)
{
    n := rows.Length()

    if (n < 2)
        return

    Loop, % n - 1
    {
        i := A_Index
        minIndex := i

        Loop, % n - i
        {
            j := i + A_Index

            order1 := SSOK_Expense_WorkPublic_CategoryOrder(rows[j].category)
            order2 := SSOK_Expense_WorkPublic_CategoryOrder(rows[minIndex].category)

            if (order1 < order2)
                minIndex := j
            else if (order1 = order2 && rows[j].date < rows[minIndex].date)
                minIndex := j
        }

        if (minIndex != i)
        {
            temp := rows[i]
            rows[i] := rows[minIndex]
            rows[minIndex] := temp
        }
    }
}

SSOK_Expense_WorkPublic_CategoryOrder(cat)
{
    if (cat = "È¸ÀÇºñ")
        return 1
    if (cat = "°æÁ¶»ç")
        return 2
    if (cat = "À§¹®")
        return 3
    if (cat = "°Ý·Á")
        return 4
    return 5
}

SSOK_Expense_WorkPublic_DateKey(value)
{
    s := Trim(value . "")

    if (s = "")
        return ""

    if RegExMatch(s, "^\d+(?:\.\d+)?$") && (s + 0) > 20000 && (s + 0) < 80000
    {
        days := Floor(s + 0)
        stamp := "18991230000000"
        EnvAdd, stamp, %days%, Days
        return SubStr(stamp, 1, 8)
    }

    digits := RegExReplace(s, "[^0-9]", "")

    if (StrLen(digits) >= 8)
        return SubStr(digits, 1, 8)

    return ""
}

SSOK_Expense_WorkPublic_DateDisplay(dateKey)
{
    if (dateKey = "")
        return ""

    if (StrLen(dateKey) < 8)
        return dateKey

    return SubStr(dateKey,1,4) . "-" . SubStr(dateKey,5,2) . "-" . SubStr(dateKey,7,2)
}

SSOK_Expense_WorkPublic_Amount(value)
{
    s := Trim(value . "")

    if (s = "")
        return ""

    s := StrReplace(s, ",", "")
    s := StrReplace(s, "¿ø", "")
    s := RegExReplace(s, "[^0-9\.-]", "")

    if !RegExMatch(s, "^-?\d+(?:\.\d+)?$")
        return ""

    return Round(s + 0)
}

SSOK_Expense_WorkPublic_CellText(cell)
{
    try value := cell.Value2
    catch
        value := ""

    return Trim(value . "", " `t`r`n")
}

SSOK_Expense_WorkPublic_HeaderKey(s)
{
    s := s . ""
    s := StrReplace(s, "`r", "")
    s := StrReplace(s, "`n", "")
    s := StrReplace(s, Chr(160), "")
    s := StrReplace(s, "¡¡", "")
    s := RegExReplace(s, "\s+", "")
    s := StrReplace(s, "¡¤", "")
    s := StrReplace(s, "¤ý", "")
    return s
}

SSOK_Expense_WorkPublic_FormatMoney(value)
{
    value := Round(value)
    s := value . ""
    sign := ""

    if (SubStr(s,1,1) = "-")
    {
        sign := "-"
        s := SubStr(s,2)
    }

    out := ""

    while (StrLen(s) > 3)
    {
        out := "," . SubStr(s, -2) . out
        s := SubStr(s, 1, StrLen(s) - 3)
    }

    return sign . s . out
}

SSOK_Expense_WorkPublic_HandleDrop(dropText, targetControl := "")
{
    global SSOK_WorkPublicPrevPath, SSOK_WorkPublicCurrentPath, SSOK_WorkPublicCardPath

    files := SSOK_Expense_DropExcelFiles(dropText)
    if (!IsObject(files) || !files.Length())
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Excel ÆÄÀÏ(.xlsx ¶Ç´Â .xls)¸¸ ²ø¾î ³õÀ» ¼ö ÀÖ½À´Ï´Ù.
        return
    }

    if (targetControl = "SSOK_WorkPublicPrevDrop")
    {
        SSOK_WorkPublicPrevPath := files[1]
        GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevDrop, % SSOK_WorkPublicPrevPath
    }
    else if (targetControl = "SSOK_WorkPublicCurrentDrop")
    {
        SSOK_WorkPublicCurrentPath := files[1]
        GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentDrop, % SSOK_WorkPublicCurrentPath
    }
    else if (targetControl = "SSOK_WorkPublicCardDrop")
    {
        SSOK_WorkPublicCardPath := files[1]
        GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCardDrop, % SSOK_WorkPublicCardPath
    }
    else
    {
        ; ºó °÷¿¡ ¿©·¯ ÆÄÀÏÀ» ³õ´Â °æ¿ì ºó Ä­À» A -> B -> C ¼ø¼­·Î Ã¤¿ó´Ï´Ù.
        for _, path in files
        {
            if (SSOK_WorkPublicPrevPath = "")
            {
                SSOK_WorkPublicPrevPath := path
                GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevDrop, %path%
            }
            else if (SSOK_WorkPublicCurrentPath = "")
            {
                SSOK_WorkPublicCurrentPath := path
                GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentDrop, %path%
            }
            else if (SSOK_WorkPublicCardPath = "")
            {
                SSOK_WorkPublicCardPath := path
                GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCardDrop, %path%
            }
        }
    }

    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
}


SSOK_Expense_GetCopiedFilePath()
{
    format := 15  ; CF_HDROP

    Loop, 4
    {
        if DllCall("OpenClipboard", "Ptr", 0)
            break
        Sleep, 25
    }

    if !DllCall("IsClipboardFormatAvailable", "UInt", format)
    {
        try DllCall("CloseClipboard")
        return ""
    }

    hDrop := DllCall("GetClipboardData", "UInt", format, "Ptr")
    if (!hDrop)
    {
        DllCall("CloseClipboard")
        return ""
    }

    count := DllCall("shell32\DragQueryFileW", "Ptr", hDrop, "UInt", 0xFFFFFFFF, "Ptr", 0, "UInt", 0, "UInt")

    if (count < 1)
    {
        DllCall("CloseClipboard")
        return ""
    }

    ; ÇÑ ¹ø¿¡ ¿©·¯ ÆÄÀÏÀ» º¹»çÇßÀ¸¸é Ã¹ ¹øÂ° Excel ÆÄÀÏÀ» ¿ì¼± »ç¿ë
    selected := ""

    Loop, %count%
    {
        index := A_Index - 1
        len := DllCall("shell32\DragQueryFileW", "Ptr", hDrop, "UInt", index, "Ptr", 0, "UInt", 0, "UInt")
        VarSetCapacity(buf, (len + 1) * 2, 0)
        DllCall("shell32\DragQueryFileW", "Ptr", hDrop, "UInt", index, "Ptr", &buf, "UInt", len + 1, "UInt")
        path := StrGet(&buf, len, "UTF-16")

        if RegExMatch(path, "i)\.(xlsx|xls)$")
        {
            selected := path
            break
        }

        if (selected = "")
            selected := path
    }

    DllCall("CloseClipboard")

    if (selected != "" && !RegExMatch(selected, "i)\.(xlsx|xls)$"))
        return ""

    return selected
}
