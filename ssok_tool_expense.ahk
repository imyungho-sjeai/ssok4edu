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
    labels := "ÃÑ¼Ò¿ä¿¹»ê¾×|ÃÑ±¸¸Å¾×|ÃÑ±Ý¾×|ÃÑ¾×|ÇÕ°è±Ý¾×|ÇÕ°è¾×|ÇÕ°è|±¸¸Å±Ý¾×|±¸¸Å¾×|±¸ÀÔ±Ý¾×|±¸ÀÔ¾×|Áö±Þ±Ý¾×|Áö±Þ¾×|ÁýÇà±Ý¾×|ÁýÇà¾×|°è¾à±Ý¾×|¿øÀÎÇàÀ§±Ý¾×|¼Ò¿ä±Ý¾×|¼Ò¿ä¾×|¼Ò¿ä¿¹»ê|¿¹»ê±Ý¾×|¿¹»ê¾×|¿¹»ê|°­»çºñ|°­»ç·á|¿©ºñ|±Ý¾×"

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
    Gui, SSOKExpenseTools:Font, s8 Bold, Malgun Gothic

    ; ±âº»°ªÀº ±âÁ¸ ¾÷¹«¿ë µµ±¸¿Í °°Àº 182px Æø.
    betaW := (SSOK_BetaReplaceW != "" && SSOK_BetaReplaceW > 0) ? SSOK_BetaReplaceW : 182
    betaH := (SSOK_BetaReplaceH != "" && SSOK_BetaReplaceH > 0) ? SSOK_BetaReplaceH : 443

    btnW := betaW - 16
    if (btnW < 130)
        btnW := 166

    Gui, SSOKExpenseTools:Add, Button, x8 y8   w%btnW% h25 gSSOK_Expense_Tools_Win1, °£Æí ÁöÃâÇ°ÀÇ(win + 1)
    Gui, SSOKExpenseTools:Add, Button, x8 y39  w%btnW% h25 gSSOK_Expense_Tools_Win2, °£Æí ¿øÀÎÇàÀ§(win + 2)
    Gui, SSOKExpenseTools:Add, Button, x8 y70  w%btnW% h25 gSSOK_Expense_Tools_Win3, °£Æí ¿øÀÎÇàÀ§(win + 3)
    Gui, SSOKExpenseTools:Add, Button, x8 y101 w%btnW% h25 gSSOK_Expense_Tools_Win4, °£Æí ¿øÀÎÇàÀ§(win + 4)
    Gui, SSOKExpenseTools:Add, Button, x8 y132 w%btnW% h25 gSSOK_Expense_Tools_CardCompare, ¹ýÀÎÄ«µå³»¿ªºñ±³
    Gui, SSOKExpenseTools:Add, Button, x8 y163 w%btnW% h25 gSSOK_Expense_Tools_WorkPublic, ¾÷¹«ÃßÁøºñ°ø°³

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
        status := "Excel 2°³°¡ ¼±ÅÃµÇ¾ú½À´Ï´Ù. ´ÙÀ½ ´Ü°è¿¡¼­ ºñ±³ ±ÔÄ¢À» ¿¬°áÇÕ´Ï´Ù."
    else if (FileExist(SSOK_CardCompareUsePath) || FileExist(SSOK_CardCompareStatementPath))
        status := "Excel 1°³°¡ ¼±ÅÃµÇ¾ú½À´Ï´Ù. ³ª¸ÓÁö ÆÄÀÏµµ ¼±ÅÃÇØ ÁÖ¼¼¿ä."
    else
        status := "¹ýÀÎÄ«µå»ç¿ëºÎ¿Í ¹ýÀÎÄ«µåÀÌ¿ë³»¿ª¼­ ExcelÀ» °¢°¢ ¼±ÅÃÇØ ÁÖ¼¼¿ä."

    GuiControl, SSOKCardCompare:, SSOK_CardCompareStatus, %status%
return

SSOK_Expense_CardCompare_Check:
    Gosub, SSOK_Expense_CardCompare_UpdateStatus

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

    MsgBox, 64, ¹ýÀÎÄ«µå³»¿ªºñ±³, µÎ Excel ÆÄÀÏÀ» Á¤»óÀûÀ¸·Î ºÒ·¯¿Ô½À´Ï´Ù.`n`n´ÙÀ½ ´Ü°è¿¡¼­ µÎ ÆÄÀÏÀÇ ¿­ ±¸Á¶¸¦ È®ÀÎÇÏ¿© ºñ±³ ±ÔÄ¢À» ¿¬°áÇÏ¸é µË´Ï´Ù.
return

SSOKCardCompareGuiDropFiles:
    ; Å½»ö±â¿¡¼­ Excel ÆÄÀÏÀ» GUI/ÀÔ·ÂÄ­À¸·Î ²ø¾î ³õÀ¸¸é ÀÚµ¿ µî·Ï
    SSOK_Expense_CardCompare_HandleDrop(A_GuiEvent, A_GuiControl)
return

SSOKCardCompareGuiClose:
SSOKCardCompareGuiEscape:
    Gui, SSOKCardCompare:Destroy
return

SSOK_Expense_CardCompare_Show()
{
    global SSOK_CardCompareUsePath, SSOK_CardCompareStatementPath
    global SSOK_CardCompareStatus

    Gui, SSOKCardCompare:Destroy
    Gui, SSOKCardCompare:New, +ToolWindow, ¹ýÀÎÄ«µå³»¿ªºñ±³
    Gui, SSOKCardCompare:Margin, 14, 14
    Gui, SSOKCardCompare:Color, F7FBFF
    Gui, SSOKCardCompare:Font, s10 Bold, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, w610 h25, ¹ýÀÎÄ«µå³»¿ªºñ±³
    Gui, SSOKCardCompare:Font, s8 Norm, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, y+0 w610 h28 c555555, Å½»ö±â¿¡¼­ Excel ÆÄÀÏÀ» °¢ ÀÔ·ÂÄ­À¸·Î ²ø¾î ³õ°Å³ª [ÆÄÀÏ ¼±ÅÃ]À» ÀÌ¿ëÇÏ¼¼¿ä.

    Gui, SSOKCardCompare:Font, s9 Bold, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, y+10 w160 h22 +0x200, ¹ýÀÎÄ«µå»ç¿ëºÎ
    Gui, SSOKCardCompare:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCardCompare:Add, Edit, x130 yp w390 h24 vSSOK_CardCompareUsePath, %SSOK_CardCompareUsePath%
    Gui, SSOKCardCompare:Add, Button, x528 yp-1 w95 h26 gSSOK_Expense_CardCompare_BrowseUse, ÆÄÀÏ ¼±ÅÃ

    Gui, SSOKCardCompare:Font, s9 Bold, Malgun Gothic
    Gui, SSOKCardCompare:Add, Text, x14 y+12 w160 h22 +0x200, ¹ýÀÎÄ«µåÀÌ¿ë³»¿ª¼­
    Gui, SSOKCardCompare:Font, s9 Norm, Malgun Gothic
    Gui, SSOKCardCompare:Add, Edit, x130 yp w390 h24 vSSOK_CardCompareStatementPath, %SSOK_CardCompareStatementPath%
    Gui, SSOKCardCompare:Add, Button, x528 yp-1 w95 h26 gSSOK_Expense_CardCompare_BrowseStatement, ÆÄÀÏ ¼±ÅÃ

    Gui, SSOKCardCompare:Add, Text, x14 y+14 w610 h38 +0x200 vSSOK_CardCompareStatus c005BAC, ¹ýÀÎÄ«µå»ç¿ëºÎ¿Í ¹ýÀÎÄ«µåÀÌ¿ë³»¿ª¼­ ExcelÀ» °¢°¢ ¼±ÅÃÇØ ÁÖ¼¼¿ä.
    Gui, SSOKCardCompare:Add, Button, x14 y+8 w150 h30 gSSOK_Expense_CardCompare_Check, ÆÄÀÏ È®ÀÎ
    Gui, SSOKCardCompare:Add, Button, x473 yp w150 h30 gSSOKCardCompareGuiClose, ´Ý±â

    Gui, SSOKCardCompare:Show, w640 h220 Center
}


; ============================================================================
; ¾÷¹«ÃßÁøºñ°ø°³ - 1Â÷ ±âº» UI
; ¨ç Áö³­´Þ °ø°³ÀÚ·á Excel
; ¨è ÀÌ¹ø´Þ ¾÷¹«ÃßÁøºñÁýÇà³»¿ª Excel
; ÇöÀç´Â µÎ ÆÄÀÏ ÀÔ·Â/È®ÀÎ ±â´É±îÁö¸¸ ±¸Çö
; ============================================================================

SSOK_Expense_WorkPublic_PastePrev:
    path := SSOK_Expense_GetCopiedFilePath()
    if (path = "")
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Å½»ö±â¿¡¼­ Áö³­´Þ °ø°³ÀÚ·á ExcelÀ» Ctrl+C·Î º¹»çÇÑ µÚ ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä.
        return
    }
    SSOK_WorkPublicPrevPath := path
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevPath, %path%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_PasteCurrent:
    path := SSOK_Expense_GetCopiedFilePath()
    if (path = "")
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Å½»ö±â¿¡¼­ ÀÌ¹ø´Þ ¾÷¹«ÃßÁøºñÁýÇà³»¿ª ExcelÀ» Ctrl+C·Î º¹»çÇÑ µÚ ´Ù½Ã ´­·¯ ÁÖ¼¼¿ä.
        return
    }
    SSOK_WorkPublicCurrentPath := path
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentPath, %path%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_BrowsePrev:
    FileSelectFile, picked, 3,, Áö³­´Þ °ø°³ÀÚ·á Excel ¼±ÅÃ, Excel ÆÄÀÏ (*.xlsx; *.xls)
    if (ErrorLevel)
        return
    SSOK_WorkPublicPrevPath := picked
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevPath, %picked%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_BrowseCurrent:
    FileSelectFile, picked, 3,, ÀÌ¹ø´Þ ¾÷¹«ÃßÁøºñÁýÇà³»¿ª Excel ¼±ÅÃ, Excel ÆÄÀÏ (*.xlsx; *.xls)
    if (ErrorLevel)
        return
    SSOK_WorkPublicCurrentPath := picked
    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentPath, %picked%
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus
return

SSOK_Expense_WorkPublic_UpdateStatus:
    Gui, SSOKWorkPublic:Submit, NoHide

    if (FileExist(SSOK_WorkPublicPrevPath) && FileExist(SSOK_WorkPublicCurrentPath))
        status := "Excel 2°³°¡ ¼±ÅÃµÇ¾ú½À´Ï´Ù. Áö³­´Þ °ø°³ÀÚ·á¸¦ ±âÁØ ¾ç½ÄÀ¸·Î »ç¿ëÇÒ ÁØºñ°¡ µÇ¾ú½À´Ï´Ù."
    else if (FileExist(SSOK_WorkPublicPrevPath) || FileExist(SSOK_WorkPublicCurrentPath))
        status := "Excel 1°³°¡ ¼±ÅÃµÇ¾ú½À´Ï´Ù. ³ª¸ÓÁö ÆÄÀÏµµ ¼±ÅÃÇØ ÁÖ¼¼¿ä."
    else
        status := "Áö³­´Þ °ø°³ÀÚ·á¿Í ÀÌ¹ø´Þ ¾÷¹«ÃßÁøºñÁýÇà³»¿ª ExcelÀ» °¢°¢ ¼±ÅÃÇØ ÁÖ¼¼¿ä."

    GuiControl, SSOKWorkPublic:, SSOK_WorkPublicStatus, %status%
return

SSOK_Expense_WorkPublic_Check:
    Gosub, SSOK_Expense_WorkPublic_UpdateStatus

    if (!FileExist(SSOK_WorkPublicPrevPath))
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Áö³­´Þ °ø°³ÀÚ·á ExcelÀ» ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }

    if (!FileExist(SSOK_WorkPublicCurrentPath))
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, ÀÌ¹ø´Þ ¾÷¹«ÃßÁøºñÁýÇà³»¿ª ExcelÀ» ¼±ÅÃÇØ ÁÖ¼¼¿ä.
        return
    }

    MsgBox, 64, ¾÷¹«ÃßÁøºñ°ø°³, µÎ Excel ÆÄÀÏÀ» Á¤»óÀûÀ¸·Î ºÒ·¯¿Ô½À´Ï´Ù.`n`n´ÙÀ½ ´Ü°è¿¡¼­ Áö³­´Þ °ø°³ÀÚ·áÀÇ ¾ç½ÄÀ» À¯ÁöÇÏ¸é¼­ ÀÌ¹ø´Þ ÁýÇà³»¿ªÀ» º¯È¯ÇÏµµ·Ï ¿¬°áÇÏ¸é µË´Ï´Ù.
return

SSOKWorkPublicGuiDropFiles:
    ; Å½»ö±â¿¡¼­ Excel ÆÄÀÏÀ» GUI/ÀÔ·ÂÄ­À¸·Î ²ø¾î ³õÀ¸¸é ÀÚµ¿ µî·Ï
    SSOK_Expense_WorkPublic_HandleDrop(A_GuiEvent, A_GuiControl)
return

SSOKWorkPublicGuiClose:
SSOKWorkPublicGuiEscape:
    Gui, SSOKWorkPublic:Destroy
return

SSOK_Expense_WorkPublic_Show()
{
    global SSOK_WorkPublicPrevPath, SSOK_WorkPublicCurrentPath
    global SSOK_WorkPublicStatus

    Gui, SSOKWorkPublic:Destroy
    Gui, SSOKWorkPublic:New, +ToolWindow, ¾÷¹«ÃßÁøºñ°ø°³
    Gui, SSOKWorkPublic:Margin, 14, 14
    Gui, SSOKWorkPublic:Color, F7FBFF
    Gui, SSOKWorkPublic:Font, s10 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, w610 h25, ¾÷¹«ÃßÁøºñ°ø°³
    Gui, SSOKWorkPublic:Font, s8 Norm, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, y+0 w610 h28 c555555, Å½»ö±â¿¡¼­ Excel ÆÄÀÏÀ» °¢ ÀÔ·ÂÄ­À¸·Î ²ø¾î ³õ°Å³ª [ÆÄÀÏ ¼±ÅÃ]À» ÀÌ¿ëÇÏ¼¼¿ä.

    Gui, SSOKWorkPublic:Font, s9 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, y+10 w160 h22 +0x200, Áö³­´Þ °ø°³ÀÚ·á
    Gui, SSOKWorkPublic:Font, s9 Norm, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Edit, x150 yp w370 h24 vSSOK_WorkPublicPrevPath, %SSOK_WorkPublicPrevPath%
    Gui, SSOKWorkPublic:Add, Button, x528 yp-1 w95 h26 gSSOK_Expense_WorkPublic_BrowsePrev, ÆÄÀÏ ¼±ÅÃ

    Gui, SSOKWorkPublic:Font, s9 Bold, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Text, x14 y+12 w160 h22 +0x200, ÀÌ¹ø´Þ ¾÷¹«ÃßÁøºñÁýÇà³»¿ª
    Gui, SSOKWorkPublic:Font, s9 Norm, Malgun Gothic
    Gui, SSOKWorkPublic:Add, Edit, x150 yp w370 h24 vSSOK_WorkPublicCurrentPath, %SSOK_WorkPublicCurrentPath%
    Gui, SSOKWorkPublic:Add, Button, x528 yp-1 w95 h26 gSSOK_Expense_WorkPublic_BrowseCurrent, ÆÄÀÏ ¼±ÅÃ

    Gui, SSOKWorkPublic:Add, Text, x14 y+14 w610 h38 +0x200 vSSOK_WorkPublicStatus c005BAC, Áö³­´Þ °ø°³ÀÚ·á¿Í ÀÌ¹ø´Þ ¾÷¹«ÃßÁøºñÁýÇà³»¿ª ExcelÀ» °¢°¢ ¼±ÅÃÇØ ÁÖ¼¼¿ä.
    Gui, SSOKWorkPublic:Add, Button, x14 y+8 w150 h30 gSSOK_Expense_WorkPublic_Check, ÆÄÀÏ È®ÀÎ
    Gui, SSOKWorkPublic:Add, Button, x473 yp w150 h30 gSSOKWorkPublicGuiClose, ´Ý±â

    Gui, SSOKWorkPublic:Show, w640 h220 Center
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

SSOK_Expense_WorkPublic_HandleDrop(dropText, targetControl := "")
{
    global SSOK_WorkPublicPrevPath, SSOK_WorkPublicCurrentPath

    files := SSOK_Expense_DropExcelFiles(dropText)
    if (!IsObject(files) || !files.Length())
    {
        MsgBox, 48, ¾÷¹«ÃßÁøºñ°ø°³, Excel ÆÄÀÏ(.xlsx ¶Ç´Â .xls)¸¸ ²ø¾î ³õÀ» ¼ö ÀÖ½À´Ï´Ù.
        return
    }

    if (targetControl = "SSOK_WorkPublicPrevPath")
    {
        SSOK_WorkPublicPrevPath := files[1]
        GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevPath, % SSOK_WorkPublicPrevPath

        if (files.Length() >= 2)
        {
            SSOK_WorkPublicCurrentPath := files[2]
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentPath, % SSOK_WorkPublicCurrentPath
        }
    }
    else if (targetControl = "SSOK_WorkPublicCurrentPath")
    {
        SSOK_WorkPublicCurrentPath := files[1]
        GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentPath, % SSOK_WorkPublicCurrentPath

        if (files.Length() >= 2)
        {
            SSOK_WorkPublicPrevPath := files[2]
            GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevPath, % SSOK_WorkPublicPrevPath
        }
    }
    else
    {
        for _, path in files
        {
            if (SSOK_WorkPublicPrevPath = "")
            {
                SSOK_WorkPublicPrevPath := path
                GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevPath, %path%
            }
            else if (SSOK_WorkPublicCurrentPath = "")
            {
                SSOK_WorkPublicCurrentPath := path
                GuiControl, SSOKWorkPublic:, SSOK_WorkPublicCurrentPath, %path%
            }
            else
            {
                SSOK_WorkPublicPrevPath := path
                GuiControl, SSOKWorkPublic:, SSOK_WorkPublicPrevPath, %path%
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
