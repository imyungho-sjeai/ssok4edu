SSOK_AI_GetPrivateWorkDir(subDir := "")
{
    root := A_LocalAppData "\SSOK\work"
    if (subDir != "")
        root := root "\" subDir
    FileCreateDir, %root%
    return root
}

global SSOK_AI_TempCleanupLastDate := ""

SSOK_AI_TempCleanupNoonTick:
SSOK_AI_CleanupTempFilesAtNoon()
return

SSOK_AI_CleanupTempFilesAtNoon()
{
    global SSOK_AI_TempCleanupLastDate
    today := A_YYYY A_MM A_DD
    if (SSOK_AI_TempCleanupLastDate = today)
        return true
    ; ¾÷¹« Áß ¹æÇØ¸¦ ÁÙÀÌ±â À§ÇØ ¸ÅÀÏ 12:30 ÀÌÈÄ ÇÑ ¹ø¸¸ Á¤¸®ÇÕ´Ï´Ù.
    if (A_Hour != 12 || A_Min < 30)
        return true
    SSOK_AI_TempCleanupLastDate := today
    return SSOK_AI_CleanupTempFiles(1, 2)
}

SSOK_AI_CleanupTempFiles(xmlAgeHours := 1, draftAgeDays := 2)
{
    if (IsFunc("SSOK_CleanupPrivateWorkRoot"))
        return SSOK_CleanupPrivateWorkRoot(SSOK_AI_GetPrivateWorkDir(), 24, xmlAgeHours, draftAgeDays)
    return false
}

SSOK_AI_RemoveTempDir(tempRoot)
{
    if (tempRoot = "")
        return true
    if !InStr(tempRoot, SSOK_AI_GetPrivateWorkDir() . "\SSOK_AI_")
        return false
    if InStr(FileExist(tempRoot), "D")
        FileRemoveDir, %tempRoot%, 1
    return !InStr(FileExist(tempRoot), "D")
}
; SSOK AI º¸°í¼­ º¯È¯ ¸ðµâ
; ssok.ahk¿¡¼­ #Include·Î ºÒ·¯¿É´Ï´Ù.
; ÆÄÀÏ¸í: ssok_ai_report.ahk

SSOK_GetReportTemplatePath(templateFileName := "ssok_ai_report2_template.hwtx")
{
    tempPath := SSOK_AI_GetPrivateWorkDir("templates") . "\SSOK_" . templateFileName
    externalPath := A_ScriptDir . "\" . templateFileName

    ; »ç¿ëÀÚ°¡ °°Àº Æú´õÀÇ HWTX ¾ç½ÄÀ» Á÷Á¢ ¼öÁ¤ÇÑ °æ¿ì ±× ÃÖ½Å ÆÄÀÏÀ» ¿ì¼± »ç¿ëÇÕ´Ï´Ù.
    if FileExist(externalPath)
        return externalPath

    ; EXE ¹èÆ÷ ½Ã FileInstallÀÌ ¾ç½ÄÀ» tempPath·Î Ç®¾îÁÝ´Ï´Ù.
    ; AHK ¿øº» ½ÇÇà ½Ã¿¡´Â °°Àº Æú´õÀÇ ¾ç½Ä ÆÄÀÏÀ» º¹»çÇÕ´Ï´Ù.
    try
    {
        if (templateFileName = "ssok_ai_report1_template.hwtx")
            FileInstall, ssok_ai_report1_template.hwtx, %tempPath%, 1
        else if (templateFileName = "ssok_ai_report2_template.hwtx")
            FileInstall, ssok_ai_report2_template.hwtx, %tempPath%, 1
        else
            FileInstall, ssok_ai_report2_template.hwtx, %tempPath%, 1
    }
    catch
    {
    }

    if FileExist(tempPath)
        return tempPath

    legacyPath := A_ScriptDir . "\¾ç½Ä_¾÷¹«º¸°í ±³À°Ã» ¾ç½Ä.hwtx"
    if FileExist(legacyPath)
        return legacyPath

    return ""
}


SSOK_ApplyOrgNameToText(text)
{
    org := SSOK_GetOrgName()
    if (org = "")
        org := "µµ´ãÁß"

    text := StrReplace(text, "OOÇÐ±³-OOOO", org . "-0000")
    text := StrReplace(text, "OOÇÐ±³-0000", org . "-0000")
    text := StrReplace(text, "OOÇÐ±³-¡Û¡Û¡Û¡Û", org . "-0000")
    text := StrReplace(text, "OOÇÐ±³-¡Û¡Û", org . "-0000")
    text := StrReplace(text, "¡Û¡ÛÇÐ±³-OOOO", org . "-0000")
    text := StrReplace(text, "¡Û¡ÛÇÐ±³-0000", org . "-0000")
    text := StrReplace(text, "¡Û¡ÛÇÐ±³-¡Û¡Û¡Û¡Û", org . "-0000")
    text := StrReplace(text, "¡Û¡ÛÇÐ±³-¡Û¡Û", org . "-0000")
    text := StrReplace(text, "00ÇÐ±³-OOOO", org . "-0000")
    text := StrReplace(text, "00ÇÐ±³-0000", org . "-0000")
    text := StrReplace(text, "OOÇÐ±³", org)
    text := StrReplace(text, "¡Û¡ÛÇÐ±³", org)
    text := StrReplace(text, "00ÇÐ±³", org)
    return text
}
SSOK_CreateHwpxReportFromText(sourceText, templateFileName := "ssok_ai_report2_template.hwtx")
{
    sourceText := SSOK_ApplyOrgNameToText(sourceText)
    templatePath := SSOK_GetReportTemplatePath(templateFileName)
    if (templatePath = "" || !FileExist(templatePath))
    {
        MsgBox, 48, SSOK AI HWP ¾ç½Ä º¯È¯, AI HWP ¾ç½ÄÀ» ÁØºñÇÏÁö ¸øÇß½À´Ï´Ù.`n`n%templateFileName% ÆÄÀÏÀ» È®ÀÎÇØ ÁÖ¼¼¿ä.
        return false
    }

    workPath := SSOK_GetNextReportDraftPath()
    if FileExist(workPath)
        FileDelete, %workPath%

    if (templateFileName = "ssok_ai_report1_template.hwtx")
    {
        if (!SSOK_CreateDraftHwpxByCloningTemplateXml(templatePath, workPath, sourceText))
        {
            Clipboard := SSOK_CleanGeminiTextBlock(sourceText)
            MsgBox, 48, SSOK AI HWP ¾ç½Ä º¯È¯1, HWTX ±â¾È¹® ¾ç½Ä º¯È¯¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n`n¿ø¹® ÅØ½ºÆ®¸¦ Å¬¸³º¸µå¿¡ º¹»çÇß½À´Ï´Ù.
            return false
        }
    }
    else
    {
        report := SSOK_BuildEducationReportParts(sourceText)
        if (!IsObject(report) || Trim(report.Body) = "")
        {
            MsgBox, 48, SSOK AI HWP ¾ç½Ä º¯È¯, º¯È¯ÇÒ ºí·° º¹»ç ÅØ½ºÆ®¸¦ Ã£Áö ¸øÇß½À´Ï´Ù.`n`n¸ÕÀú º¯È¯ÇÒ ³»¿ëÀ» ºí·° ÁöÁ¤ÇÑ µÚ ´Ù½Ã ½ÇÇàÇØ ÁÖ¼¼¿ä.
            return false
        }

        ; ÇÙ½É: HWP¿¡ Paste/InsertText·Î º»¹®À» ³ÖÁö ¾Ê½À´Ï´Ù.
        ; HWTX ³»ºÎ section0.xml¿¡¼­ Á¦¸ñ/¡à/?/-/¡Ø/* ¹®´Ü XMLÀ» ±×´ë·Î º¹Á¦ÇÏ°í,
        ; <hp:t> ±ÛÀÚ¸¸ ±³Ã¼ÇÕ´Ï´Ù. µû¶ó¼­ paraPrIDRef/styleIDRef/charPrIDRef°¡ »ì¾Æ³³´Ï´Ù.
        if (!SSOK_CreateReportHwpxByCloningTemplateXml(templatePath, workPath, report))
        {
            Clipboard := SSOK_BuildEducationReportTextFromParts(report)
            MsgBox, 48, SSOK AI HWP ¾ç½Ä º¯È¯, HWTX ¾ç½Ä ¹®´Ü º¹Á¦ ¹æ½ÄÀ¸·Î º¸°í¼­ ÆÄÀÏ »ý¼º¿¡ ½ÇÆÐÇß½À´Ï´Ù.`n`nº¸°í¼­¿ë ÅØ½ºÆ®¸¦ Å¬¸³º¸µå¿¡ º¹»çÇß½À´Ï´Ù.
            return false
        }
    }

    try
    {
        hwp := ComObjCreate("HWPFrame.HwpObject")
        try hwp.SetMessageBoxMode(0x00010001)
        try hwp.RegisterModule("FilePathCheckDLL", "FilePathCheckerModule")
        ; ¾ÈÁ¤È­: XML ¿©¹é Á÷Á¢ ¼öÁ¤Àº ÇÏÁö ¾Ê°í, ÇÑ±Û¿¡¼­ ¿­¸° µÚ COMÀ¸·Î¸¸ ÆíÁý¿ëÁö¸¦ º¸Á¤ÇÕ´Ï´Ù.
        if (!SSOK_HwpOpenReportWorkFile(hwp, workPath))
            throw Exception("HWPX open failed")
        try SSOK_HwpForceReportPageMargins(hwp)
        try hwp.XHwpWindows.Item(0).Visible := true
        try hwp.HAction.Run("MoveDocBegin")
        WinActivate, ahk_exe hwp.exe
    }
    catch
    {
        Run, %workPath%
    }

    return true
}

SSOK_CreateDraftHwpxByCloningTemplateXml(templatePath, workPath, sourceText)
{
    tempRoot := SSOK_AI_GetPrivateWorkDir() . "\SSOK_AI_DraftXml_" . A_TickCount
    if InStr(FileExist(tempRoot), "D")
        FileRemoveDir, %tempRoot%, 1
    FileCreateDir, %tempRoot%

    if (!SSOK_ZipExtractToFolder(templatePath, tempRoot))
        return false

    sectionPath := tempRoot . "\Contents\section0.xml"
    if !FileExist(sectionPath)
        return false

    FileRead, xml, *P65001 %sectionPath%
    if (ErrorLevel || xml = "")
        return false
    xml := SSOK_ApplyOrgNameToText(xml)

    draft := SSOK_BuildDraftDocumentParts(sourceText)
    if (!IsObject(draft) || Trim(draft.Body) = "")
        return false

    titleSubList := SSOK_XML_FindDraftEditableSubList(xml)
    if (titleSubList != "")
        titlePara := SSOK_XML_FindNthParagraph(titleSubList, 1)
    else
        titlePara := SSOK_XML_FindParagraphByContains(xml, "Á¦¸ñ:")
    if (titlePara = "")
        titlePara := SSOK_XML_FindNthParagraph(xml, 1)

    sectionPara := SSOK_XML_FindParagraphAroundText(xml, "1. °ü·Ã")
    gaPara := sectionPara
    numPara := sectionPara
    notePara := sectionPara
    attachPara := sectionPara

    if (titlePara = "" || sectionPara = "")
        return false

    titleText := draft.Title
    if (titleText != "" && !RegExMatch(titleText, "i)^Á¦\s*¸ñ\s*[:£º]"))
        titleText := "Á¦¸ñ: " . titleText
    titleBlock := SSOK_XML_SetParagraphTextForKind(titlePara, titleText, "exact", 8001)
    if (titleSubList != "")
        xml := SSOK_XML_ReplaceDraftEditableSubList(xml, titleBlock)
    else
        xml := StrReplace(xml, titlePara, titleBlock)

    newBlock := ""
    paraId := 8000

    draftBody := draft.Body
    Loop, Parse, draftBody, `n, `r
    {
        rawLine := RTrim(A_LoopField, " `t")
        line := Trim(rawLine, " `t")
        if (line = "")
        {
            paraId++
            newBlock .= SSOK_XML_SetParagraphTextForKind(gaPara, "", "exact", paraId)
            continue
        }

        if RegExMatch(line, "^ºÙÀÓ")
            tmpl := attachPara
        else if RegExMatch(line, "^\d+\)")
            tmpl := numPara
        else if RegExMatch(line, "^¡Ø")
            tmpl := notePara
        else if RegExMatch(line, "^[°¡-ÇÏ]\.")
            tmpl := gaPara
        else if RegExMatch(line, "^\d+\.")
            tmpl := sectionPara
        else
            tmpl := gaPara

        paraId++
        newBlock .= SSOK_XML_SetParagraphTextForKind(tmpl, rawLine, "exact", paraId)
    }

    if (newBlock = "")
        return false

    xmlBeforeReplace := xml
    xml := SSOK_XML_ReplaceFromParagraphToSectionEnd(xml, "1. °ü·Ã", newBlock)
    if (xml = xmlBeforeReplace)
        return false

    if (!SSOK_XML_IsWellFormed(xml))
        return false

    SSOK_WriteUtf8File(sectionPath, xml)

    if FileExist(workPath)
        FileDelete, %workPath%

    if (!SSOK_ZipFolderToFile(tempRoot, workPath))
    {
        SSOK_AI_RemoveTempDir(tempRoot)
        return false
    }

    ok := FileExist(workPath)
    SSOK_AI_RemoveTempDir(tempRoot)
    return ok
}

SSOK_CreateReportHwpxByCloningTemplateXml(templatePath, workPath, report)
{
    tempRoot := SSOK_AI_GetPrivateWorkDir() . "\SSOK_AI_ReportXml_" . A_TickCount
    if InStr(FileExist(tempRoot), "D")
        FileRemoveDir, %tempRoot%, 1
    try
        FileCreateDir, %tempRoot%
    catch
        return false

    if (!SSOK_ZipExtractToFolder(templatePath, tempRoot))
        return false

    sectionPath := tempRoot . "\Contents\section0.xml"
    if !FileExist(sectionPath)
        return false

    FileRead, xml, *P65001 %sectionPath%
    if (ErrorLevel || xml = "")
        return false
    xml := SSOK_ApplyOrgNameToText(xml)

    ; 1) »ó´Ü °íÁ¤ ¹®±¸ Ä¡È¯: HWTX ¾ç½ÄÀÇ °íÁ¤ ¹®´Ü ¼ø¼­¸¦ ¿ì¼± »ç¿ëÇÕ´Ï´Ù.
    categoryPara := SSOK_XML_FindNthParagraph(xml, 1)
    titleTopPara := SSOK_XML_FindNthParagraph(xml, 2)
    metaPara := SSOK_XML_FindNthParagraph(xml, 3)
    if (categoryPara != "")
        xml := StrReplace(xml, categoryPara, SSOK_XML_SetParagraphTextForKind(categoryPara, report.CategoryLine, "replace", ""))
    else
        xml := SSOK_XML_ReplaceParagraphTextByContains(xml, "Á¤Ã¥°áÁ¤", report.CategoryLine)

    if (titleTopPara != "")
        xml := StrReplace(xml, titleTopPara, SSOK_XML_SetParagraphTextForKind(titleTopPara, report.Title, "replace", ""))
    else
        xml := SSOK_XML_ReplaceParagraphTextByContains(xml, "Á¦¸ñ(¾È)", report.Title)

    if (metaPara != "")
        xml := StrReplace(xml, metaPara, SSOK_XML_SetParagraphTextForKind(metaPara, report.Meta, "replace", ""))
    else
    {
        xmlBeforeMeta := xml
        xml := SSOK_XML_ReplaceParagraphTextByContains(xml, "¹Î¿ø±â·ÏÆÀ", report.Meta)
        if (xml = xmlBeforeMeta)
            xml := SSOK_XML_ReplaceParagraphTextByRegex(xml, "^\s*<[^>]*\d{1,4}\.\s*\d{1,2}\.\s*\d{1,2}\.\([^)]+\),.*¢Ï.*>\s*$", report.Meta)
    }

    ; 2) ¾ç½ÄÀÇ ½ÇÁ¦ ¼­½Ä ¹®´Ü ÃßÃâ
    overviewPara := SSOK_XML_FindNthParagraph(xml, 4)
    if (overviewPara = "")
        overviewPara := SSOK_XML_FindParagraphByContains(xml, "°³¿ä(")
    if (overviewPara = "")
        overviewPara := SSOK_XML_FindParagraphByContains(xml, "¡Ø (")
    if (overviewPara = "")
        overviewPara := SSOK_XML_FindParagraphByContains(xml, "¤±¤±¤±À» ÅëÇØ")

    sectionPara := SSOK_XML_FindNthParagraph(xml, 6)
    bulletPara  := SSOK_XML_FindNthParagraph(xml, 7)
    dashPara    := SSOK_XML_FindNthParagraph(xml, 8)
    notePara    := SSOK_XML_FindNthParagraph(xml, 9)
    starPara    := SSOK_XML_FindNthParagraph(xml, 10)

    if (sectionPara = "")
        sectionPara := SSOK_XML_FindParagraphByContains(xml, "¼ÒÁ¦¸ñ")
    if (bulletPara = "")
        bulletPara := SSOK_XML_FindParagraphByContains(xml, "³»¿ë")
    if (dashPara = "")
        dashPara := SSOK_XML_FindParagraphByContains(xml, "»ó¼¼³»¿ë")
    if (notePara = "")
        notePara := SSOK_XML_FindParagraphByContains(xml, "Áß¿ä")
    if (starPara = "")
        starPara := SSOK_XML_FindParagraphByContains(xml, "ÂüÁ¶")

    if (sectionPara = "" || bulletPara = "" || dashPara = "" || notePara = "" || starPara = "")
        return false

    ; 3) °³¿ä´Â Ç¥ ¾ÈÀÇ ¹®´ÜÀÌ¹Ç·Î Ç¥ ±¸Á¶¸¦ °Çµå¸®Áö ¾Ê°í ÅØ½ºÆ®¸¸ ¹Ù²ß´Ï´Ù.
    ;    º»¹® »ùÇÃ ¹®´Ü(¡à/?/-/¡Ø/*)¸¸ º¹Á¦ÇØ¼­ ±³Ã¼ÇØ¾ß HWPX XMLÀÌ ±úÁöÁö ¾Ê½À´Ï´Ù.
    overviewText := Trim(report.Summary, " `t`r`n")
    if (overviewText = "")
        overviewText := SSOK_BuildReportOverviewText(report.Title)
    if (overviewPara != "")
        xml := StrReplace(xml, overviewPara, SSOK_XML_SetParagraphTextForKind(overviewPara, overviewText, "replace", ""))

    attachTitle := Trim(report.AttachmentTitle, " `t`r`n")
    if (attachTitle != "")
        xml := SSOK_XML_ReplaceLastParagraphTextByRegex(xml, "^\s*Á¦¸ñ\s*\(HY°ß°íµñ19\)\s*$", attachTitle)

    ; 4) ±âÁ¸ »ùÇÃ º»¹® ¿µ¿ª(¡à ¼ÒÁ¦¸ñ~* ÂüÁ¶)À» »õ º»¹®À¸·Î ±³Ã¼
    newBlock := ""
    paraId := 9000

    bodyText := report.Body
    Loop, Parse, bodyText, `n, `r
    {
        line := Trim(A_LoopField, " `t")
        if (line = "")
            continue

        line := SSOK_NormalizeReportDisplayLine(line)
        kind := SSOK_ReportLineKind(line)
        if (kind = "section")
            tmpl := sectionPara
        else if (kind = "bullet")
            tmpl := bulletPara
        else if (kind = "dash")
            tmpl := dashPara
        else if (kind = "note")
            tmpl := notePara
        else if (kind = "star")
            tmpl := starPara
        else
            tmpl := bulletPara

        paraId++
        newBlock .= SSOK_XML_SetParagraphTextForKind(tmpl, line, kind, paraId)
    }

    if (newBlock = "")
        return false

    ; °³¿ä Ç¥¸¦ Æ÷ÇÔÇØ¼­ ¹üÀ§ Ä¡È¯ÇÏ¸é Ç¥ÀÇ ´Ý´Â ÅÂ±×°¡ ³²¾Æ ºó ¹®¼­Ã³·³ ¿­¸± ¼ö ÀÖ½À´Ï´Ù.
    ; µû¶ó¼­ Ç×»ó Ç¥ ¹ÛÀÇ ¡à ¼ÒÁ¦¸ñ ¹®´ÜºÎÅÍ * ÂüÁ¶ ¹®´Ü±îÁö¸¸ ¹Ù²ß´Ï´Ù.
    xmlBeforeReplace := xml
    xml := SSOK_XML_ReplaceParagraphRangeByContains(xml, "¡à ¼ÒÁ¦¸ñ", "* ÂüÁ¶", newBlock)

    ; ¹üÀ§ Ä¡È¯ ½ÇÆÐ ½Ã¿¡´Â ¿øº» ¹®´Ü ¹®ÀÚ¿­ ±âÁØÀ¸·Î¸¸ º¸Á¶ÇÕ´Ï´Ù.
    ; ³ÐÀº Á¤±Ô½Ä fallbackÀº Ç¥/ºÙÀÓ ¹®´Ü±îÁö Àß¸ø Áö¿ï ¼ö ÀÖ¾î »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.
    if (xml = xmlBeforeReplace)
        xml := SSOK_XML_ReplaceParagraphRangeByExactParagraphs(xml, sectionPara, starPara, newBlock)
    if (xml = xmlBeforeReplace)
        return false

    attachmentTitles := report.AttachmentTitles
    if (!IsObject(attachmentTitles) && Trim(report.AttachmentTitle, " `t`r`n") != "")
    {
        attachmentTitles := []
        attachmentTitles.Push(report.AttachmentTitle)
    }
    xml := SSOK_XML_ReplaceReportAttachmentPages(xml, attachmentTitles)

    ; ºÙÀÓ ÆäÀÌÁö º¹Á¦ ½Ã ¾ç½Ä ¼³¸í ¹®±¸°¡ ÀÏºÎ ³²À» ¼ö ÀÖÀ¸¹Ç·Î,
    ; ÆÄÀÏ »ý¼º ÀÚÃ¼¸¦ ¸·Áö´Â ¾Ê½À´Ï´Ù. ÇÙ½É º»¹® Ä¡È¯ ½ÇÆÐ´Â À§ÀÇ newBlock/¹üÀ§ Ä¡È¯¿¡¼­ ÀÌ¹Ì °É·¯Áý´Ï´Ù.
    if (!SSOK_XML_IsWellFormed(xml))
        return false

    SSOK_WriteUtf8File(sectionPath, xml)

    if FileExist(workPath)
        FileDelete, %workPath%

    if (!SSOK_ZipFolderToFile(tempRoot, workPath))
    {
        SSOK_AI_RemoveTempDir(tempRoot)
        return false
    }

    Loop, 30
    {
        if FileExist(workPath)
        {
            FileGetSize, zsize, %workPath%
            if (zsize > 1000)
            {
                SSOK_AI_RemoveTempDir(tempRoot)
                return true
            }
        }
        Sleep, 100
    }
    SSOK_AI_RemoveTempDir(tempRoot)
    return false
}

SSOK_XML_IsWellFormed(xml)
{
    try
    {
        dom := ComObjCreate("MSXML2.DOMDocument.6.0")
        dom.async := false
        dom.validateOnParse := false
        dom.resolveExternals := false
        return dom.loadXML(xml) ? true : false
    }
    catch
    {
        return true
    }
}
SSOK_XML_ReplaceParagraphRangeByExactParagraphs(xml, startPara, endPara, newBlock)
{
    if (startPara = "" || endPara = "")
        return xml

    startPos := InStr(xml, startPara)
    if (!startPos)
        return xml

    endPos := InStr(xml, endPara, false, startPos)
    if (!endPos)
        return xml

    endPos += StrLen(endPara)
    return SubStr(xml, 1, startPos - 1) . newBlock . SubStr(xml, endPos)
}
SSOK_XML_ReplaceReportAttachmentPages(xml, attachmentTitles)
{
    if (!IsObject(attachmentTitles) || attachmentTitles.MaxIndex() = "")
        return xml

    endPara := SSOK_XML_FindLastParagraphByContains(xml, "¡Ø ÇÑÄÄµ¸¿ò")
    if (endPara = "")
        return xml

    startPos := SSOK_XML_FindReportAttachmentBlockStart(xml)
    endPos := InStr(xml, endPara, false, startPos)
    if (!startPos || !endPos)
        return xml
    endPos += StrLen(endPara)

    attachBlock := SubStr(xml, startPos, endPos - startPos)
    count := attachmentTitles.MaxIndex()
    newBlock := ""
    paraBase := 9300

    Loop, % count
    {
        title := SSOK_CleanReportAttachmentTitle(attachmentTitles[A_Index])
        if (title = "")
            continue

        label := "ºÙÀÓ"
        if (count > 1)
            label := "ºÙÀÓ  " . A_Index

        pageBlock := attachBlock
        pageBlock := SSOK_XML_ReplaceNthTextNode(pageBlock, 1, label)
        pageBlock := SSOK_XML_ReplaceNthTextNode(pageBlock, 2, title)
        newBlock .= pageBlock
    }

    if (newBlock = "")
        return xml

    return SubStr(xml, 1, startPos - 1) . newBlock . SubStr(xml, endPos)
}

SSOK_XML_FindReportAttachmentBlockStart(xml)
{
    markerPos := InStr(xml, "ºÙÀÓ")
    if (!markerPos)
        return 0

    pos := 1
    foundPageBreakPara := 0
    while (pos := InStr(xml, "<hp:p", false, pos))
    {
        if (pos >= markerPos)
            break

        tagEnd := InStr(xml, ">", false, pos)
        if (!tagEnd)
            break

        tagText := SubStr(xml, pos, tagEnd - pos + 1)
        if InStr(tagText, "pageBreak=""1""")
            foundPageBreakPara := pos

        pos += 5
    }

    if (foundPageBreakPara)
        return foundPageBreakPara

    return SSOK_LastIndexOfBefore(xml, "<hp:p", markerPos)
}
SSOK_XML_ReplaceNthTextNode(xml, nth, newText)
{
    if (nth <= 0)
        return xml

    esc := SSOK_XML_Escape(newText)
    pos := 1
    count := 0
    while (pos := RegExMatch(xml, "s)<hp:t>.*?</hp:t>", m, pos))
    {
        count++
        if (count = nth)
            return SubStr(xml, 1, pos - 1) . "<hp:t>" . esc . "</hp:t>" . SubStr(xml, pos + StrLen(m))
        pos += StrLen(m)
    }
    return xml
}
SSOK_XML_FindReportAttachmentTitleParagraph(attachBlock)
{
    pos := 1
    foundCount := 0
    while (pos := RegExMatch(attachBlock, "s)<hp:p\b.*?</hp:p>", m, pos))
    {
        foundCount++
        if (foundCount = 2)
            return m
        pos += StrLen(m)
    }
    return ""
}
SSOK_XML_FindLastParagraphByRegex(xml, pattern)
{
    pos := 1
    foundPara := ""
    while (pos := RegExMatch(xml, "s)<hp:p\b.*?</hp:p>", m, pos))
    {
        para := m
        plain := SSOK_XML_ParagraphText(para)
        if RegExMatch(plain, pattern)
            foundPara := para
        pos += StrLen(m)
    }
    return foundPara
}

SSOK_XML_FindLastParagraphByContains(xml, containsText)
{
    pos := 1
    foundPara := ""
    while (pos := RegExMatch(xml, "s)<hp:p\b.*?</hp:p>", m, pos))
    {
        para := m
        plain := SSOK_XML_ParagraphText(para)
        if InStr(plain, containsText)
            foundPara := para
        pos += StrLen(m)
    }
    return foundPara
}
SSOK_XML_FindParagraphByContains(xml, containsText)
{
    pos := 1
    while (pos := RegExMatch(xml, "s)<hp:p\b.*?</hp:p>", m, pos))
    {
        para := m
        plain := SSOK_XML_ParagraphText(para)
        if InStr(plain, containsText)
            return para
        pos += StrLen(m)
    }
    return ""
}

SSOK_XML_FindDraftEditableSubList(xml)
{
    editablePos := InStr(xml, "editable=""1""")
    if (!editablePos)
        return ""

    startPos := SSOK_LastIndexOfBefore(xml, "<hp:subList", editablePos)
    if (!startPos)
        startPos := InStr(xml, "<hp:subList", false, editablePos)
    endPos := InStr(xml, "</hp:subList>", false, startPos)
    if (!startPos || !endPos)
        return ""

    endPos += StrLen("</hp:subList>")
    return SubStr(xml, startPos, endPos - startPos)
}

SSOK_XML_ReplaceDraftEditableSubList(xml, newBlock)
{
    editablePos := InStr(xml, "editable=""1""")
    if (!editablePos)
        return xml

    startPos := SSOK_LastIndexOfBefore(xml, "<hp:subList", editablePos)
    if (!startPos)
        startPos := InStr(xml, "<hp:subList", false, editablePos)
    contentStart := InStr(xml, ">", false, startPos)
    endPos := InStr(xml, "</hp:subList>", false, startPos)
    if (!startPos || !contentStart || !endPos)
        return xml

    return SubStr(xml, 1, contentStart) . newBlock . SubStr(xml, endPos)
}

SSOK_XML_FindParagraphAroundText(xml, markerText)
{
    markerPos := InStr(xml, markerText)
    if (!markerPos)
        return ""

    startPos := SSOK_LastIndexOfBefore(xml, "<hp:p", markerPos)
    endPos := InStr(xml, "</hp:p>", false, markerPos)
    if (!startPos || !endPos)
        return ""

    endPos += StrLen("</hp:p>")
    return SubStr(xml, startPos, endPos - startPos)
}

SSOK_XML_ReplaceFromParagraphToSectionEnd(xml, markerText, newBlock)
{
    markerPos := InStr(xml, markerText)
    if (!markerPos)
        return xml

    startPos := SSOK_LastIndexOfBefore(xml, "<hp:p", markerPos)
    endPos := InStr(xml, "</hs:sec>", false, markerPos)
    if (!startPos || !endPos)
        return xml

    return SubStr(xml, 1, startPos - 1) . newBlock . SubStr(xml, endPos)
}

SSOK_XML_FindNthParagraph(xml, nth)
{
    pos := 1
    count := 0
    while (pos := InStr(xml, "<hp:p", false, pos))
    {
        endPos := InStr(xml, "</hp:p>", false, pos)
        if (!endPos)
            break
        endPos += StrLen("</hp:p>")

        count++
        if (count = nth)
            return SubStr(xml, pos, endPos - pos)

        pos := endPos
    }
    return ""
}

SSOK_LastIndexOfBefore(text, needle, beforePos)
{
    found := 0
    pos := 1
    while (pos := InStr(text, needle, false, pos))
    {
        if (pos >= beforePos)
            break
        found := pos
        pos += StrLen(needle)
    }
    return found
}

SSOK_XML_ReplaceParagraphRangeByContains(xml, startText, endText, newBlock)
{
    startPos := 0
    endPos := 0
    endLen := 0
    pos := 1

    while (pos := RegExMatch(xml, "s)<hp:p\b.*?</hp:p>", m, pos))
    {
        para := m
        plain := SSOK_XML_ParagraphText(para)

        if (!startPos && InStr(plain, startText))
            startPos := pos

        if (startPos && InStr(plain, endText))
        {
            endPos := pos
            endLen := StrLen(m)
            break
        }

        pos += StrLen(m)
    }

    if (!startPos || !endPos || endLen <= 0)
        return xml

    return SubStr(xml, 1, startPos - 1) . newBlock . SubStr(xml, endPos + endLen)
}

SSOK_XML_ReplaceParagraphTextByContains(xml, containsText, newText)
{
    oldPara := SSOK_XML_FindParagraphByContains(xml, containsText)
    if (oldPara = "")
        return xml
    newPara := SSOK_XML_SetParagraphTextForKind(oldPara, newText, "replace", "")
    return StrReplace(xml, oldPara, newPara)
}

SSOK_XML_ReplaceParagraphTextByRegex(xml, pattern, newText)
{
    pos := 1
    while (pos := RegExMatch(xml, "s)<hp:p\b.*?</hp:p>", m, pos))
    {
        oldPara := m
        plain := SSOK_XML_ParagraphText(oldPara)
        if RegExMatch(plain, pattern)
        {
            newPara := SSOK_XML_SetParagraphTextForKind(oldPara, newText, "replace", "")
            return StrReplace(xml, oldPara, newPara)
        }
        pos += StrLen(m)
    }
    return xml
}

SSOK_XML_ReplaceLastParagraphTextByRegex(xml, pattern, newText)
{
    pos := 1
    foundPara := ""
    while (pos := RegExMatch(xml, "s)<hp:p\b.*?</hp:p>", m, pos))
    {
        oldPara := m
        plain := SSOK_XML_ParagraphText(oldPara)
        if RegExMatch(plain, pattern)
            foundPara := oldPara
        pos += StrLen(m)
    }
    if (foundPara = "")
        return xml
    newPara := SSOK_XML_SetParagraphTextForKind(foundPara, newText, "replace", "")
    return StrReplace(xml, foundPara, newPara)
}

SSOK_XML_ParagraphText(para)
{
    text := ""
    pos := 1
    while (pos := RegExMatch(para, "s)<hp:t>(.*?)</hp:t>", m, pos))
    {
        text .= m1
        pos += StrLen(m)
    }
    text := StrReplace(text, "&lt;", "<")
    text := StrReplace(text, "&gt;", ">")
    text := StrReplace(text, "&amp;", "&")
    return text
}

SSOK_XML_SetParagraphTextForKind(para, newText, kind="replace", newId="")
{
    ; HWTX »ùÇÃ ¹®´ÜÀÇ paraPrIDRef / styleIDRef / charPrIDRef´Â ±×´ë·Î µÓ´Ï´Ù.
    ; ¹Ù²î´Â °ÍÀº <hp:t> ÅØ½ºÆ®»ÓÀÔ´Ï´Ù.
    ; µé¿©¾²±âÃ³·³ ¾ç½Ä¿¡ µé¾îÀÖ´Â ¾Õ °ø¹éµµ Á¾·ùº°·Î µÇ»ì¸³´Ï´Ù.
    finalText := SSOK_XML_NormalizeTextForTemplateKind(para, newText, kind)
    esc := SSOK_XML_Escape(finalText)

    ; º¹Á¦ ¹®´ÜÀÇ linesegarray¿¡´Â ¿øº» ¹®´ÜÀÇ ÁÂÇ¥/³ôÀÌ°¡ µé¾î ÀÖ¾î ¿©·¯ ¹®´ÜÀ» º¹Á¦ÇÏ¸é
    ; °ãÄ¡°Å³ª Á¤·ÄÀÌ Æ²¾îÁú ¼ö ÀÖ½À´Ï´Ù. »èÁ¦ÇÏ¿© ÇÑ±ÛÀÌ ¿­ ¶§ ´Ù½Ã °è»êÇÏ°Ô ÇÕ´Ï´Ù.
    para := RegExReplace(para, "s)<hp:linesegarray>.*?</hp:linesegarray>", "")

    result := ""
    pos := 1
    done := false
    while (pos2 := RegExMatch(para, "s)<hp:t>.*?</hp:t>", m, pos))
    {
        result .= SubStr(para, pos, pos2 - pos)
        if (!done)
        {
            result .= "<hp:t>" . esc . "</hp:t>"
            done := true
        }
        else
        {
            result .= "<hp:t></hp:t>"
        }
        pos := pos2 + StrLen(m)
    }
    result .= SubStr(para, pos)

    if (newId != "")
        result := RegExReplace(result, "^<hp:p([^>]*) id=""[^""]*""", "<hp:p$1 id=""" . newId . """", outCount, 1)

    return result
}

SSOK_XML_NormalizeTextForTemplateKind(para, text, kind)
{
    if (kind = "exact")
        return RTrim(text, " `t`r`n")

    t := Trim(text, " `t`r`n")

    if (kind = "title" || kind = "replace" || kind = "overview")
        return t

    if (kind = "section")
    {
        t := RegExReplace(t, "^\s*[¡à¡á¤±]\s*", "")
        return "¡à " . t
    }

    if (kind = "bullet")
    {
        t := RegExReplace(t, "^\s*[¤·¡ÛoO]\s*", "")
        return "  ¤· " . t
    }

    if (kind = "dash")
    {
        t := RegExReplace(t, "^\s*[-??]\s*", "")
        return SSOK_XML_TemplatePrefixBeforeMarker(para, "-") . "- " . t
    }

    if (kind = "note")
    {
        t := RegExReplace(t, "^\s*¡Ø\s*", "")
        return SSOK_XML_TemplatePrefixBeforeMarker(para, "¡Ø") . "¡Ø " . t
    }

    if (kind = "star")
    {
        t := RegExReplace(t, "^\s*\*\s*", "")
        return SSOK_XML_TemplatePrefixBeforeMarker(para, "*") . "* " . t
    }

    return t
}

SSOK_XML_TemplatePrefixBeforeMarker(para, marker)
{
    plain := SSOK_XML_ParagraphText(para)
    pos := InStr(plain, marker)
    if (pos > 1)
        return SubStr(plain, 1, pos - 1)
    return ""
}

SSOK_XML_Escape(text)
{
    text := StrReplace(text, "&", "&amp;")
    text := StrReplace(text, "<", "&lt;")
    text := StrReplace(text, ">", "&gt;")
    return text
}

SSOK_WriteUtf8File(path, text)
{
    try
    {
        stream := ComObjCreate("ADODB.Stream")
        stream.Type := 2
        stream.Charset := "utf-8"
        stream.Open()
        stream.WriteText(text)
        stream.SaveToFile(path, 2)
        stream.Close()
        return true
    }
    catch
    {
        FileDelete, %path%
        FileAppend, %text%, %path%, UTF-8
        return !ErrorLevel
    }
}

SSOK_ZipExtractToFolder(zipPath, destDir)
{
    ; Shell.Application CopyHere´Â PC¿¡ µû¶ó ºñµ¿±â·Î ³¡³ª°Å³ª ½ÇÆÐÇØ ºó ¹®¼­Ã³·³ º¸ÀÏ ¼ö ÀÖ½À´Ï´Ù.
    ; HWTX´Â ZIP ±¸Á¶ÀÌ¹Ç·Î Windows ±âº» tar.exe·Î µ¿±â ÇØÁ¦ÇÕ´Ï´Ù.
    try
        FileCreateDir, %destDir%
    catch
        return false

    tmpZip := SSOK_AI_GetPrivateWorkDir("zip") . "\SSOK_AI_Template_" . A_TickCount . ".zip"
    if FileExist(tmpZip)
        FileDelete, %tmpZip%
    try
        FileCopy, %zipPath%, %tmpZip%, 1
    catch
        return false
    if (!FileExist(tmpZip))
        return false

    tarExe := A_WinDir . "\System32\tar.exe"
    if (!FileExist(tarExe))
        tarExe := "tar.exe"
    RunWait, "%tarExe%" -xf "%tmpZip%" -C "%destDir%",, Hide UseErrorLevel
    if FileExist(tmpZip)
        FileDelete, %tmpZip%

    if (ErrorLevel)
        return false

    if FileExist(destDir . "\Contents\section0.xml")
        return true

    Loop, 20
    {
        if FileExist(destDir . "\Contents\section0.xml")
            return true
        Sleep, 100
    }
    return false
}

SSOK_ZipFolderToFile(srcDir, zipPath)
{
    ; Shell.Application CopyHere´Â ¿Ï·á Àü ¹ÝÈ¯µÇ´Â °æ¿ì°¡ ÀÖ¾î HWPX°¡ ºó ¹®¼­Ã³·³ ¿­¸± ¼ö ÀÖ½À´Ï´Ù.
    ; Windows ±âº» tar.exe·Î µ¿±â ¾ÐÃàÇÕ´Ï´Ù.
    tmpZip := SSOK_AI_GetPrivateWorkDir("zip") . "\SSOK_AI_Report_" . A_TickCount . ".zip"
    if FileExist(tmpZip)
        FileDelete, %tmpZip%
    if FileExist(zipPath)
        FileDelete, %zipPath%

    tarExe := A_WinDir . "\System32\tar.exe"
    if (!FileExist(tarExe))
        tarExe := "tar.exe"
    RunWait, "%tarExe%" -a -cf "%tmpZip%" -C "%srcDir%" mimetype version.xml settings.xml Contents Preview META-INF,, Hide UseErrorLevel

    if (ErrorLevel || !FileExist(tmpZip))
    {
        if FileExist(tmpZip)
            FileDelete, %tmpZip%
        if (!SSOK_ZipFolderToFileByShell(srcDir, tmpZip))
            return false
    }

    if !FileExist(tmpZip)
        return false

    FileGetSize, size, %tmpZip%
    if (size < 1000)
        return false

    FileMove, %tmpZip%, %zipPath%, 1
    if !FileExist(zipPath)
        return false

    return true
}

SSOK_ZipFolderToFileByShell(srcDir, zipPath)
{
    if FileExist(zipPath)
        FileDelete, %zipPath%
    if (!SSOK_CreateEmptyZip(zipPath))
        return false

    try
    {
        shell := ComObjCreate("Shell.Application")
        zipNs := shell.NameSpace(zipPath)
        if (!zipNs)
            return false

        items := ["mimetype", "version.xml", "settings.xml", "Contents", "Preview", "META-INF"]
        for _, item in items
        {
            itemPath := srcDir . "" . item
            if FileExist(itemPath)
                zipNs.CopyHere(itemPath, 20)
        }

        Loop, 80
        {
            FileGetSize, zsize, %zipPath%
            if (zsize > 1000)
                return true
            Sleep, 100
        }
    }
    catch
    {
        return false
    }

    return false
}
SSOK_PSQuote(text)
{
    text := StrReplace(text, "'", "''")
    return "'" . text . "'"
}

SSOK_CreateEmptyZip(zipPath)
{
    try
    {
        f := FileOpen(zipPath, "w")
        if (!IsObject(f))
            return false
        VarSetCapacity(eocd, 22, 0)
        NumPut(0x06054B50, eocd, 0, "UInt")
        f.RawWrite(eocd, 22)
        f.Close()
        return true
    }
    catch
    {
        return false
    }
}

SSOK_PrepareReportWorkHwpx(templatePath, stamp)
{
    workPath := SSOK_GetNextReportDraftPath()
    if FileExist(workPath)
        FileDelete, %workPath%

    FileCopy, %templatePath%, %workPath%, 1
    if FileExist(workPath)
        return workPath

    return templatePath
}


SSOK_HwpForceReportPageMargins(hwp)
{
    ; ÆíÁý¿ëÁö °­Á¦ º¸Á¤: ÁÂ/¿ì 20mm, À§/¾Æ·¡ 10mm, ¸Ó¸®¸»/²¿¸®¸» 10mm, Á¦º» 0mm
    ; »ý¼º XML¿¡µµ °°Àº °ªÀ» ³Ö°í, ÇÑ±Û¿¡¼­ ¿­¸° µÚ COM PageSetupÀ¸·Î ÇÑ ¹ø ´õ º¸Á¤ÇÕ´Ï´Ù.
    try hwp.HAction.GetDefault("PageSetup", hwp.HParameterSet.HSecDef.HSet)
    catch
        return false

    ; ÇÑ±Û/HWPX ³»ºÎ ´ÜÀ§: 5669 = 20mm, 2834 = 10mm
    try hwp.HParameterSet.HSecDef.PageDef.LeftMargin := 5669
    try hwp.HParameterSet.HSecDef.PageDef.RightMargin := 5669
    try hwp.HParameterSet.HSecDef.PageDef.TopMargin := 2834
    try hwp.HParameterSet.HSecDef.PageDef.BottomMargin := 2834
    try hwp.HParameterSet.HSecDef.PageDef.HeaderLen := 2834
    try hwp.HParameterSet.HSecDef.PageDef.FooterLen := 2834
    try hwp.HParameterSet.HSecDef.PageDef.GutterLen := 0

    ; ÀÏºÎ ÇÑ±Û ¹öÀüÀº SetItem ¹æ½ÄÀÌ ´õ ¾ÈÁ¤ÀûÀÌ¶ó º¸Á¶·Î ÇÑ ¹ø ´õ ÁöÁ¤ÇÕ´Ï´Ù.
    try hwp.HParameterSet.HSecDef.PageDef.SetItem("LeftMargin", 5669)
    try hwp.HParameterSet.HSecDef.PageDef.SetItem("RightMargin", 5669)
    try hwp.HParameterSet.HSecDef.PageDef.SetItem("TopMargin", 2834)
    try hwp.HParameterSet.HSecDef.PageDef.SetItem("BottomMargin", 2834)
    try hwp.HParameterSet.HSecDef.PageDef.SetItem("HeaderLen", 2834)
    try hwp.HParameterSet.HSecDef.PageDef.SetItem("FooterLen", 2834)
    try hwp.HParameterSet.HSecDef.PageDef.SetItem("GutterLen", 0)

    try
    {
        hwp.HAction.Execute("PageSetup", hwp.HParameterSet.HSecDef.HSet)
        return true
    }
    catch
    {
        return false
    }
}

SSOK_GetNextReportDraftPath()
{
    ; Å×½ºÆ® Áß ¹ÙÅÁÈ­¸é¿¡ ÆÄÀÏÀÌ °è¼Ó ½×ÀÌÁö ¾Êµµ·Ï SSOK ÀÓ½Ã ÀÛ¾÷Æú´õ¸¦ »ç¿ëÇÕ´Ï´Ù.
    ; ÇÑ±Û¿¡¼­ ¿­¸° µÚ ÇÊ¿äÇÑ °æ¿ì »ç¿ëÀÚ°¡ Á÷Á¢ [´Ù¸¥ ÀÌ¸§À¸·Î ÀúÀå]ÇÏ¸é µË´Ï´Ù.
    FormatTime, today,, yyyyMMdd
    workDir := SSOK_AI_GetPrivateWorkDir("report_draft")
    FileCreateDir, %workDir%
    basePath := workDir . "\SSOK_¾÷¹«º¸°í_" . today . "_"

    Loop, 99
    {
        seq := A_Index
        if (seq < 10)
            seqText := "0" . seq
        else
            seqText := seq

        path := basePath . seqText . ".hwpx"
        if !FileExist(path)
            return path
    }

    FormatTime, fallback,, yyyyMMdd_HHmmss
    return workDir . "\SSOK_¾÷¹«º¸°í_" . fallback . ".hwpx"
}

SSOK_HwpOpenReportWorkFile(hwp, workPath)
{
    try
    {
        hwp.Open(workPath, "HWPX", "forceopen:true")
        return true
    }
    catch
    {
    }

    try
    {
        hwp.Open(workPath, "", "forceopen:true")
        return true
    }
    catch
    {
    }

    try
    {
        hwp.Open(workPath)
        return true
    }
    catch
    {
    }

    return false
}

SSOK_HwpCloseBlankDocuments(hwp, keepPath)
{
    try
    {
        count := hwp.XHwpDocuments.Count
    }
    catch
    {
        return
    }

    Loop, %count%
    {
        idx := count - A_Index
        docPath := ""
        gotPath := false

        try
        {
            doc := hwp.XHwpDocuments.Item(idx)
        }
        catch
        {
            continue
        }

        try
        {
            docPath := doc.Path
            gotPath := true
        }
        catch
        {
            docPath := ""
        }

        if (gotPath && docPath = "")
        {
            try
            {
                doc.Close(false)
            }
            catch
            {
            }
        }
    }
}

SSOK_HwpQuitNoPrompt(hwp)
{
    try
        hwp.SetMessageBoxMode(0x00010001)

    try
    {
        hwp.Quit()
        return
    }
    catch
    {
    }

    try
        hwp.Run("FileQuit")
    catch
    {
        try
            hwp.Run("FileClose")
    }
}

SSOK_FillReportTemplateInHwp(hwp, report)
{
    ; HWTX ÆÄÀÏÀº Ç¥Áö/¿©¹é/±âº» À§Ä¡¸¦ Àâ´Â ¡°Æ²¡±·Î »ç¿ëÇÏ°í,
    ; ½ÇÁ¦ Á¦¸ñ/º»¹® ¼­½ÄÀº HWP ÀÚµ¿È­·Î Á÷Á¢ Àû¿ëÇÕ´Ï´Ù.
    ; XML builder ¹æ½ÄÀº ÇÑ±Û¿¡¼­ ±âº» ÇÔÃÊ·Õ¹ÙÅÁ 10pt·Î ¶³¾îÁö´Â ¹®Á¦°¡ ÀÖ¾î »ç¿ëÇÏÁö ¾Ê½À´Ï´Ù.

    changed := false

    try
        hwp.HAction.Run("MoveDocBegin")

    if (SSOK_HwpReplaceTextExact(hwp, "? Á¤Ã¥°áÁ¤    ¡à »ç¾Èº¸°í   ¡à Çà»ç    ¡à Áö½Ã°ËÅä    ¡à ±âÅ¸", report.CategoryLine))
        changed := true

    if (SSOK_HwpReplaceTextExact(hwp, "2025 ÁÖ¿ä¾÷¹«°èÈ¹ ¼ö¸³ ÃßÁø °èÈ¹(¾È)", report.Title))
        changed := true

    if (SSOK_HwpReplaceTextExact(hwp, "<'26.5.16.(Åä), ¿î¿µÁö¿ø°ú ¹Î¿ø±â·ÏÆÀ ÁÖ¹«°ü ¹üÇÇ½º, ¢Ï1234>", report.Meta)
     || SSOK_HwpReplaceTextExact(hwp, "<¡¯26.5.16.(Åä), ¿î¿µÁö¿ø°ú ¹Î¿ø±â·ÏÆÀ ÁÖ¹«°ü ¹üÇÇ½º, ¢Ï1234>", report.Meta))
        changed := true

    if (Trim(report.Summary, " `t`r`n") != "")
    {
        if (SSOK_HwpReplaceTextExact(hwp, "»ó´ãÀü¹®±â°ü°ú Á¦ÈÞ¸¦ ÅëÇØ »ó´ãÀ» Èñ¸ÁÇÏ´Â Áö¹æ°ø¹«¿øÀÌ Àü¹®°¡¿ÍÀÇ »ó´ãÀ» ÅëÇØ ¾î·Á¿òÀ» ÇØ¼ÒÇÒ ¼ö ÀÖµµ·Ï Áö¿ø", report.Summary))
            changed := true
    }

    if (SSOK_HwpReplaceBodyFromMarker(hwp, report.Body))
        return true

    ; º»¹® ¸¶Ä¿¸¦ Ã£Áö ¸øÇÏ¸é ¿¹ÀüÃ³·³ ¾ç½Ä¸¸ ¿­°í ³¡³ªÁö ¾Êµµ·Ï
    ; ÀüÃ¼ ¹®¼­¸¦ ºñ¿ì°í AI º¸°í¼­¿ë ¼­½ÄÀ» Á÷Á¢ ¸¸µé¾î ³Ö½À´Ï´Ù.
    ; ÀÌ °æ·Î´Â HWTX ¼­½Ä º¹Á¦ ½ÇÆÐ ½Ã¿¡µµ ÃÖ¼ÒÇÑ Á¦¸ñ/¡à/?/- ±¸Á¶°¡ º¸ÀÌµµ·Ï ÇÏ´Â ¾ÈÀü °æ·ÎÀÔ´Ï´Ù.
    if (SSOK_HwpInsertReportFallbackFull(hwp, report))
        return true

    return changed
}

SSOK_HwpInsertReportFallbackFull(hwp, report)
{
    if (!SSOK_HwpClearTemplateDocument(hwp))
        return false

    try
        hwp.HAction.Run("MoveDocBegin")

    inserted := false

    ; º¸°í À¯Çü ÁÙ
    SSOK_HwpApplyReportParaShapeByKind(hwp, "body")
    if (!SSOK_HwpSafeInsertLine(hwp, report.CategoryLine))
        return false
    try hwp.HAction.Run("MoveParaBegin")
    try hwp.HAction.Run("MoveSelParaEnd")
    Sleep, 30
    SSOK_HwpApplyReportCharShapeByKind(hwp, "body")
    try hwp.HAction.Run("MoveParaEnd")
    inserted := true
    SSOK_HwpBreakPara(hwp)
    SSOK_HwpBreakPara(hwp)

    ; Á¦¸ñ
    SSOK_HwpApplyReportParaShapeByKind(hwp, "title")
    if (!SSOK_HwpSafeInsertLine(hwp, report.Title))
        return false
    try hwp.HAction.Run("MoveParaBegin")
    try hwp.HAction.Run("MoveSelParaEnd")
    Sleep, 30
    SSOK_HwpApplyReportCharShape(hwp, "HYÇìµå¶óÀÎM", 1800, true)
    SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 800, 1)
    try hwp.HAction.Run("MoveParaEnd")
    SSOK_HwpBreakPara(hwp)

    ; ¸ÞÅ¸
    SSOK_HwpApplyReportParaShapeByKind(hwp, "summary")
    if (!SSOK_HwpSafeInsertLine(hwp, report.Meta))
        return false
    try hwp.HAction.Run("MoveParaBegin")
    try hwp.HAction.Run("MoveSelParaEnd")
    Sleep, 30
    SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
    SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 500, 0)
    try hwp.HAction.Run("MoveParaEnd")
    SSOK_HwpBreakPara(hwp)
    SSOK_HwpBreakPara(hwp)

    ; ¿ä¾à
    if (Trim(report.Summary, " `t`r`n") != "")
    {
        SSOK_HwpApplyReportParaShapeByKind(hwp, "summary")
        if (!SSOK_HwpSafeInsertLine(hwp, report.Summary))
            return false
        try hwp.HAction.Run("MoveParaBegin")
        try hwp.HAction.Run("MoveSelParaEnd")
        Sleep, 30
        SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
        SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 500, 0)
        try hwp.HAction.Run("MoveParaEnd")
        SSOK_HwpBreakPara(hwp)
        SSOK_HwpBreakPara(hwp)
    }

    if (!SSOK_HwpInsertReportBodyStyled(hwp, report.Body))
        return false

    return true
}

SSOK_HwpSafeInsertLine(hwp, line)
{
    ; Å¬¸³º¸µå ºÙ¿©³Ö±â¸¦ ¿ì¼± »ç¿ëÇÕ´Ï´Ù.
    ; InsertText(HInsertText)´Â ÀÏºÎ PC¿¡¼­ ÇÑ±Û¡¤Æ¯¼ö¹®ÀÚ(¡à ? ? ¡Ø µî)¸¦
    ; Á¡(¡¤)ÀÌ³ª ±úÁø ¹®ÀÚ·Î »ðÀÔÇÏ¸é¼­µµ COM ¼º°øÀ» ¹ÝÈ¯ÇÏ±â ¶§¹®¿¡
    ; InsertText¸¦ ¸ÕÀú ¾²¸é ¿À·ù¸¦ °¨ÁöÇÒ ¼ö ¾ø½À´Ï´Ù.
    if (SSOK_HwpPastePlainText(hwp, line))
        return true
    return SSOK_HwpInsertPlainText(hwp, line)
}

SSOK_HwpSelectCurrentPara(hwp)
{
    try
    {
        hwp.HAction.Run("MoveParaBegin")
        hwp.HAction.Run("MoveSelParaEnd")
        return true
    }
    catch
    {
    }
    try
    {
        hwp.HAction.Run("MoveLineBegin")
        hwp.HAction.Run("MoveSelLineEnd")
        return true
    }
    catch
    {
        return false
    }
}

SSOK_HwpApplyReportTitleStyle(hwp)
{
    SSOK_HwpApplyReportCharShape(hwp, "HYÇìµå¶óÀÎM", 1800, true)
    SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 800, 1)
}

SSOK_HwpApplyReportSummaryStyle(hwp)
{
    SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
    SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 500, 0)
}

SSOK_BuildEducationReportTextFromParts(report)
{
    text := report.CategoryLine . "`r`n`r`n"
    text .= "<" . report.Title . ">`r`n`r`n"
    text .= report.Meta . "`r`n`r`n"

    if (Trim(report.Summary, " `t`r`n") != "")
        text .= "<" . report.Summary . ">`r`n`r`n"

    text .= report.Body
    return RTrim(text, "`r`n")
}

SSOK_HwpClearTemplateDocument(hwp)
{
    cleared := false

    try
        hwp.HAction.Run("MoveDocBegin")

    try
    {
        hwp.HAction.Run("SelectAll")
        Sleep, 50
        hwp.HAction.Run("Delete")
        cleared := true
    }
    catch
    {
    }

    if (!cleared)
    {
        try
        {
            hwp.HAction.Run("MoveDocBegin")
            hwp.HAction.Run("MoveSelDocEnd")
            Sleep, 50
            hwp.HAction.Run("Delete")
            cleared := true
        }
        catch
        {
        }
    }

    if (!cleared)
    {
        try
        {
            hwp.Run("SelectAll")
            Sleep, 50
            hwp.Run("Delete")
            cleared := true
        }
        catch
        {
        }
    }

    if (!cleared)
        return false

    Sleep, 50
    try
        hwp.HAction.Run("MoveDocBegin")

    return true
}

SSOK_HwpInsertReportDocumentText(hwp, reportText)
{
    ; ÇÑ±Û COM InsertText°¡ ÀÏºÎ PC¿¡¼­ ±âÈ£¸¸ ÂïÈ÷´Â ¹®Á¦°¡ ÀÖ¾î
    ; º¸°í¼­ º¯È¯Àº ÀüÃ¼ ÅØ½ºÆ®¸¦ Å¬¸³º¸µå·Î ÇÑ ¹ø¿¡ ºÙ¿©³Ö´Â ¹æ½ÄÀ» ¿ì¼± »ç¿ëÇÕ´Ï´Ù.
    if (SSOK_HwpPastePlainText(hwp, reportText))
        return true

    if (SSOK_HwpInsertReportBodyStyled(hwp, reportText))
        return true

    SSOK_HwpClearTemplateDocument(hwp)

    try
        hwp.HAction.Run("MoveDocBegin")

    return SSOK_HwpInsertPlainText(hwp, reportText)
}

SSOK_HwpReplaceBodyFromMarker(hwp, bodyText)
{
    if (!SSOK_HwpFindReportBodyMarker(hwp))
        return false

    try
    {
        hwp.HAction.Run("MoveParaBegin")
    }
    catch
    {
        try
        {
            hwp.HAction.Run("MoveLineBegin")
        }
        catch
        {
        }
    }

    Sleep, 50

    try
    {
        hwp.HAction.Run("MoveSelDocEnd")
        Sleep, 50
        hwp.HAction.Run("Delete")
        Sleep, 80

        ; hwtx ¾ç½ÄÀÇ ¡à / ? / - / ¡Ø / * ¹®´Ü ¼­½ÄÀ» »ì¸®±â À§ÇØ
        ; º»¹® ÀüÃ¼¸¦ ÇÑ ¹ø¿¡ ºÙ¿©³ÖÁö ¾Ê°í, ÁÙ ´ÜÀ§·Î ¾ç½Ä ¼­½ÄÀ» Àû¿ëÇØ ÀÔ·ÂÇÕ´Ï´Ù.
        if (SSOK_HwpInsertReportBodyStyled(hwp, bodyText))
            return true

        ; ÀÏºÎ PC¿¡¼­ ÁÙ ´ÜÀ§ ÀÔ·ÂÀÌ ½ÇÆÐÇÒ °æ¿ì¿¡¸¸ ¸¶Áö¸· ¾ÈÀüÀåÄ¡·Î ÀÏ¹Ý ºÙ¿©³Ö±â
        return SSOK_HwpPastePlainText(hwp, bodyText)
    }
    catch
    {
        return false
    }
}

SSOK_HwpFindReportBodyMarker(hwp)
{
    markers := "¡à °³¿ä ¹× ±Ù°Å|°³¿ä ¹× ±Ù°Å|¡à °³¿ä|¡à ³»¿ë ÀÛ¼º ¼ø¼­|³»¿ë ÀÛ¼º ¼ø¼­"

    Loop, Parse, markers, |
    {
        try
            hwp.HAction.Run("MoveDocBegin")

        if (SSOK_HwpFindText(hwp, A_LoopField))
            return true
    }

    return false
}

SSOK_HwpInsertReportBodyStyled(hwp, bodyText)
{
    ; ¦¡¦¡ ¼­½Ä Àû¿ë ¼ø¼­ ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡
    ; [ÀÌÀü] ¼­½Ä ÁöÁ¤ ¡æ ÅØ½ºÆ® »ðÀÔ
    ;   ¹®Á¦: Å¬¸³º¸µå ºÙ¿©³Ö±â ½Ã HWPÀÌ ±ÛÀÚ ¼­½ÄÀ» ±âº»°ª(ÇÔÃÊ·Ò¹ÙÅÁ 10pt)À¸·Î
    ;         ¸®¼ÂÇÏ¹Ç·Î, »ðÀÔ Àü¿¡ ¼³Á¤ÇÑ CharShapeÀÌ ½ÇÁ¦·Î Àû¿ëµÇÁö ¾Ê½À´Ï´Ù.
    ;
    ; [¼öÁ¤] ´Ü¶ô ¼­½Ä ÁöÁ¤ ¡æ ÅØ½ºÆ® »ðÀÔ ¡æ ÁÙ ÀüÃ¼ ¼±ÅÃ ¡æ ±ÛÀÚ ¼­½Ä ÀçÀû¿ë
    ;   ´Ü¶ô ¼­½Ä(ParaShape)Àº »ðÀÔ Àü¿¡ Àû¿ëÇØµµ À¯ÁöµÇÁö¸¸,
    ;   ±ÛÀÚ ¼­½Ä(CharShape)Àº ÅØ½ºÆ®¸¦ ¸ÕÀú ³ÖÀº µÚ ¼±ÅÃÇØ¼­ µ¤¾î¾º¿ö¾ß ÇÕ´Ï´Ù.
    ; ¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡¦¡

    inserted := false

    Loop, Parse, bodyText, `n, `r
    {
        rawLine := RTrim(A_LoopField, " `t")
        line := Trim(rawLine, " `t")

        if (line = "")
        {
            if (inserted)
                SSOK_HwpBreakPara(hwp)
            continue
        }

        ; ÁÙ ¾Õ °ø¹é ¶§¹®¿¡ ±ÛÀÚ°¡ È­¸é ¹ÛÀ¸·Î ¹Ð¸®´Â ¹®Á¦¸¦ ¸·±â À§ÇØ
        ; ½ÇÁ¦ ÀÔ·ÂÀº ±âÈ£ ±âÁØÀ¸·Î ´Ù½Ã Á¤¸®ÇÕ´Ï´Ù.
        line := SSOK_NormalizeReportDisplayLine(line)
        kind := SSOK_ReportLineKind(line)

        ; ¨ç ´Ü¶ô ¼­½Ä ¸ÕÀú Àû¿ë (ºó ÁÙ »óÅÂ¿¡¼­µµ ´Ü¶ô ¼Ó¼ºÀº À¯ÁöµÊ)
        SSOK_HwpApplyReportParaShapeByKind(hwp, kind)

        ; ¨è ÅØ½ºÆ® »ðÀÔ (Å¬¸³º¸µå ¿ì¼± ¡æ InsertText º¸Á¶)
        if (!SSOK_HwpSafeInsertLine(hwp, line))
            return false

        ; ¨é ÇöÀç ´Ü¶ô ÀüÃ¼ ¼±ÅÃ ÈÄ ±ÛÀÚ ¼­½Ä ÀçÀû¿ë
        ;    Å¬¸³º¸µå ºÙ¿©³Ö±â°¡ ±ÛÀÚ ¼­½ÄÀ» ÃÊ±âÈ­ÇÏ¹Ç·Î, »ðÀÔ ÈÄ ¼±ÅÃÇØ µ¤¾î¾¹´Ï´Ù.
        try hwp.HAction.Run("MoveParaBegin")
        try hwp.HAction.Run("MoveSelParaEnd")
        Sleep, 30
        SSOK_HwpApplyReportCharShapeByKind(hwp, kind)

        ; ¨ê Ä¿¼­¸¦ ÁÙ ³¡À¸·Î ÀÌµ¿ (¼±ÅÃ ÇØÁ¦)
        try hwp.HAction.Run("MoveParaEnd")

        inserted := true
        SSOK_HwpBreakPara(hwp)
    }

    return inserted
}

; ´Ü¶ô ¼­½Ä¸¸ kind¿¡ µû¶ó Àû¿ë
SSOK_HwpApplyReportParaShapeByKind(hwp, kind)
{
    if (kind = "section")
        SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 1500, 0)
    else if (kind = "note" || kind = "star")
        SSOK_HwpApplyReportParaShape(hwp, 2100, -700, 150, 500, 0)
    else if (kind = "dash")
        SSOK_HwpApplyReportParaShape(hwp, 2400, -600, 150, 800, 0)
    else if (kind = "bullet")
        SSOK_HwpApplyReportParaShape(hwp, 1400, -500, 150, 1000, 0)
    else
        SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 800, 0)
}

; ±ÛÀÚ ¼­½Ä¸¸ kind¿¡ µû¶ó Àû¿ë (ÅØ½ºÆ® ¼±ÅÃ ÈÄ È£Ãâ)
SSOK_HwpApplyReportCharShapeByKind(hwp, kind)
{
    if (kind = "section")
        SSOK_HwpApplyReportCharShape(hwp, "HYÇìµå¶óÀÎM", 1600, true)
    else if (kind = "note" || kind = "star")
        SSOK_HwpApplyReportCharShape(hwp, "ÇÑ¾çÁß°íµñ", 1300, false)
    else if (kind = "dash")
        SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
    else if (kind = "bullet")
        SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
    else
        SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
}

SSOK_NormalizeReportDisplayLine(line)
{
    t := Trim(line, " `t")
    if RegExMatch(t, "^¡à\s*(.+)$", m)
        return "¡à " . Trim(m1)
    if RegExMatch(t, "^(¤·|¡Û|o|O)\s*(.+)$", m)
        return "  ¤· " . Trim(m2)
    if RegExMatch(t, "^[-£­]\s*(.+)$", m)
        return "- " . Trim(m1)
    if RegExMatch(t, "^¡Ø\s*(.+)$", m)
        return "¡Ø " . Trim(m1)
    if RegExMatch(t, "^\*\s*(.+)$", m)
        return "* " . Trim(m1)
    return t
}

SSOK_ReportLineKind(line)
{
    t := Trim(line, " `t")

    if RegExMatch(t, "^¡à")
        return "section"
    if RegExMatch(t, "^(¤·|¡Û|o|O)")
        return "bullet"
    if RegExMatch(t, "^[-£­]")
        return "dash"
    if RegExMatch(t, "^¡Ø")
        return "note"
    if RegExMatch(t, "^\*")
        return "star"

    return "body"
}

SSOK_HwpApplyReportLineStyle(hwp, kind)
{
    if (kind = "section")
    {
        SSOK_HwpApplyReportCharShape(hwp, "HYÇìµå¶óÀÎM", 1600, true)
        SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 1500, 0)
        return
    }

    if (kind = "note")
    {
        SSOK_HwpApplyReportCharShape(hwp, "ÇÑ¾çÁß°íµñ", 1300, false)
        SSOK_HwpApplyReportParaShape(hwp, 2100, -700, 150, 500, 0)
        return
    }

    if (kind = "star")
    {
        SSOK_HwpApplyReportCharShape(hwp, "ÇÑ¾çÁß°íµñ", 1300, false)
        SSOK_HwpApplyReportParaShape(hwp, 2100, -700, 150, 500, 0)
        return
    }

    if (kind = "dash")
    {
        SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
        SSOK_HwpApplyReportParaShape(hwp, 2400, -600, 150, 800, 0)
        return
    }

    if (kind = "bullet")
    {
        SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
        SSOK_HwpApplyReportParaShape(hwp, 1400, -500, 150, 1000, 0)
        return
    }

    SSOK_HwpApplyReportCharShape(hwp, "ÈÞ¸Õ¸íÁ¶", 1500, false)
    SSOK_HwpApplyReportParaShape(hwp, 0, 0, 150, 800, 0)
}

SSOK_HwpApplyReportCharShape(hwp, faceName, height, bold=false)
{
    try
        hwp.HAction.GetDefault("CharShape", hwp.HParameterSet.HCharShape.HSet)
    catch
        return

    try
        hwp.HParameterSet.HCharShape.FaceNameHangul := faceName
    try
        hwp.HParameterSet.HCharShape.FaceNameLatin := faceName
    try
        hwp.HParameterSet.HCharShape.FaceNameHanja := faceName
    try
        hwp.HParameterSet.HCharShape.FaceNameJapanese := faceName
    try
        hwp.HParameterSet.HCharShape.FaceNameOther := faceName
    try
        hwp.HParameterSet.HCharShape.FaceNameSymbol := faceName
    try
        hwp.HParameterSet.HCharShape.FaceNameUser := faceName
    try
        hwp.HParameterSet.HCharShape.Height := height
    try
        hwp.HParameterSet.HCharShape.Bold := (bold ? 1 : 0)

    try
        hwp.HParameterSet.HCharShape.SetItem("FaceNameHangul", faceName)
    try
        hwp.HParameterSet.HCharShape.SetItem("FaceNameLatin", faceName)
    try
        hwp.HParameterSet.HCharShape.SetItem("FaceNameHanja", faceName)
    try
        hwp.HParameterSet.HCharShape.SetItem("FaceNameJapanese", faceName)
    try
        hwp.HParameterSet.HCharShape.SetItem("FaceNameOther", faceName)
    try
        hwp.HParameterSet.HCharShape.SetItem("FaceNameSymbol", faceName)
    try
        hwp.HParameterSet.HCharShape.SetItem("FaceNameUser", faceName)
    try
        hwp.HParameterSet.HCharShape.SetItem("Height", height)
    try
        hwp.HParameterSet.HCharShape.SetItem("Bold", (bold ? 1 : 0))

    try
        hwp.HAction.Execute("CharShape", hwp.HParameterSet.HCharShape.HSet)
}

SSOK_HwpApplyReportParaShape(hwp, leftMargin, indent, lineSpacing, prevSpacing, alignType=0)
{
    try
        hwp.HAction.GetDefault("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)
    catch
        return

    try
        hwp.HParameterSet.HParaShape.AlignType := alignType
    try
        hwp.HParameterSet.HParaShape.LeftMargin := leftMargin
    try
        hwp.HParameterSet.HParaShape.Indent := indent
    try
        hwp.HParameterSet.HParaShape.LineSpacing := lineSpacing
    try
        hwp.HParameterSet.HParaShape.PrevSpacing := prevSpacing

    try
        hwp.HParameterSet.HParaShape.SetItem("AlignType", alignType)
    try
        hwp.HParameterSet.HParaShape.SetItem("LeftMargin", leftMargin)
    try
        hwp.HParameterSet.HParaShape.SetItem("Indent", indent)
    try
        hwp.HParameterSet.HParaShape.SetItem("LineSpacing", lineSpacing)
    try
        hwp.HParameterSet.HParaShape.SetItem("PrevSpacing", prevSpacing)

    try
        hwp.HAction.Execute("ParagraphShape", hwp.HParameterSet.HParaShape.HSet)
}

SSOK_HwpBreakPara(hwp)
{
    try
    {
        hwp.HAction.Run("BreakPara")
    }
    catch
    {
        SSOK_HwpInsertPlainText(hwp, "`r`n")
    }
}

SSOK_HwpFindText(hwp, findText)
{
    try
    {
        hwp.HAction.GetDefault("Find", hwp.HParameterSet.HFindReplace.HSet)
        SSOK_HwpSetFindReplaceParams(hwp, findText, "")
        result := hwp.HAction.Execute("Find", hwp.HParameterSet.HFindReplace.HSet)
        return (result != false)
    }
    catch
    {
        return false
    }
}

SSOK_HwpReplaceTextExact(hwp, findText, replaceText)
{
    if (findText = "")
        return false

    try
        hwp.HAction.Run("MoveDocBegin")

    if (!SSOK_HwpFindText(hwp, findText))
        return false

    Sleep, 50
    return SSOK_HwpPastePlainText(hwp, replaceText)
}

SSOK_HwpPastePlainText(hwp, text)
{
    if (text = "")
        return true

    ClipSavedReport := ClipboardAll
    okClip := false
    Loop, 3
    {
        Clipboard := ""
        Sleep, 30
        Clipboard := text
        ClipWait, 1.0
        if (!ErrorLevel)
        {
            okClip := true
            break
        }
        Sleep, 80
    }
    if (!okClip)
    {
        Clipboard := ClipSavedReport
        return false
    }

    ok := false
    try
    {
        hwp.HAction.Run("Paste")
        ok := true
    }
    catch
    {
    }

    if (!ok)
    {
        try
        {
            hwp.Run("Paste")
            ok := true
        }
        catch
        {
        }
    }

    Sleep, 80
    Clipboard := ClipSavedReport
    return ok
}

SSOK_HwpReplaceText(hwp, findText, replaceText)
{
    if (findText = "")
        return false

    try
    {
        hwp.HAction.GetDefault("AllReplace", hwp.HParameterSet.HFindReplace.HSet)
        SSOK_HwpSetFindReplaceParams(hwp, findText, replaceText)
        hwp.HAction.Execute("AllReplace", hwp.HParameterSet.HFindReplace.HSet)
        return true
    }
    catch
    {
    }

    if (SSOK_HwpFindText(hwp, findText))
        return SSOK_HwpInsertPlainText(hwp, replaceText)

    return false
}

SSOK_HwpSetFindReplaceParams(hwp, findText, replaceText)
{
    try
        hwp.HParameterSet.HFindReplace.FindString := findText
    try
        hwp.HParameterSet.HFindReplace.ReplaceString := replaceText
    try
        hwp.HParameterSet.HFindReplace.Direction := 1
    try
        hwp.HParameterSet.HFindReplace.IgnoreMessage := 1
    try
        hwp.HParameterSet.HFindReplace.ReplaceMode := 1
    try
        hwp.HParameterSet.HFindReplace.MatchCase := 0
    try
        hwp.HParameterSet.HFindReplace.WholeWordOnly := 0
    try
        hwp.HParameterSet.HFindReplace.UseWildCards := 0

    try
        hwp.HParameterSet.HFindReplace.SetItem("FindString", findText)
    try
        hwp.HParameterSet.HFindReplace.SetItem("ReplaceString", replaceText)
    try
        hwp.HParameterSet.HFindReplace.SetItem("Direction", 1)
    try
        hwp.HParameterSet.HFindReplace.SetItem("IgnoreMessage", 1)
    try
        hwp.HParameterSet.HFindReplace.SetItem("ReplaceMode", 1)
    try
        hwp.HParameterSet.HFindReplace.SetItem("MatchCase", 0)
    try
        hwp.HParameterSet.HFindReplace.SetItem("WholeWordOnly", 0)
    try
        hwp.HParameterSet.HFindReplace.SetItem("UseWildCards", 0)
}

SSOK_HwpInsertPlainText(hwp, text)
{
    try
    {
        hwp.HAction.GetDefault("InsertText", hwp.HParameterSet.HInsertText.HSet)
        hwp.HParameterSet.HInsertText.Text := text
        hwp.HAction.Execute("InsertText", hwp.HParameterSet.HInsertText.HSet)
        return true
    }
    catch
    {
        return false
    }
}

SSOK_BuildEducationReportText(sourceText)
{
    report := SSOK_BuildEducationReportParts(sourceText)
    if (!IsObject(report))
        return ""

    return SSOK_BuildEducationReportTextFromParts(report)
}

SSOK_BuildDraftDocumentParts(sourceText)
{
    cleanText := SSOK_CleanGeminiTextBlock(sourceText)
    if (Trim(cleanText) = "")
        return ""

    title := ""
    body := ""
    lines := StrSplit(cleanText, "`n", "`r")

    for idx, rawLine in lines
    {
        line := Trim(rawLine, " `t")
        if (line = "")
        {
            if (body != "")
                body .= "`r`n"
            continue
        }

        if (title = "" && RegExMatch(line, "i)^Á¦\s*¸ñ\s*[:£º]\s*(.+)$", m))
        {
            title := Trim(m1)
            continue
        }

        if (title = "" && RegExMatch(line, "i)^Á¦\s*¸ñ\s*[:£º]\s*$"))
            continue

        if (title = "" && line = "Á¦¸ñ")
            continue

        body .= line . "`r`n"
    }

    body := RTrim(body, "`r`n")
    body := SSOK_NormalizeDraftOfficialText(body)
    return {Title: title, Body: body}
}

SSOK_NormalizeDraftOfficialText(text)
{
    try
    {
        if (IsFunc("DOC_ProcessText"))
        {
            docFn := Func("DOC_ProcessText")
            cleaned := docFn.Call(text)
            if (Trim(cleaned) != "")
                return SSOK_NormalizeDraftAttachSpacing(cleaned)
        }
    }
    catch
    {
    }

    result := ""
    Loop, Parse, text, `n, `r
    {
        line := SSOK_NormalizeDraftOfficialLine(A_LoopField)
        if (line = "")
            continue
        result .= line . "`r`n"
    }

    return RTrim(result, "`r`n")
}

SSOK_NormalizeDraftAttachSpacing(text)
{
    result := ""
    Loop, Parse, text, `n, `r
    {
        line := A_LoopField
        t := Trim(line, " `t")

        if RegExMatch(t, "^ºÙÀÓ\s+(.+)$", mAttach)
            line := "ºÙÀÓ " . Trim(mAttach1)

        result .= line . "`r`n"
    }

    return RTrim(result, "`r`n")
}

SSOK_NormalizeDraftOfficialLine(line)
{
    t := Trim(line, " `t")
    if (t = "")
        return ""

    ; °ø¹®¼­ º»¹® µé¿©¾²±â: °¡. 2Ä­, 1) 4Ä­, °¡) 6Ä­.
    if RegExMatch(t, "^([°¡-ÇÏ])\)\s*(.*)$", mHangulSub)
        return "      " . mHangulSub1 . ") " . Trim(mHangulSub2)

    if RegExMatch(t, "^(\d+)\)\s*(.*)$", mNumSub)
        return "    " . mNumSub1 . ") " . Trim(mNumSub2)

    if RegExMatch(t, "^([°¡-ÇÏ])\s*[\.,£¬¡¢¤ý:£º]\s*(.*)$", mHangul)
        return "  " . mHangul1 . ". " . Trim(mHangul2)

    if RegExMatch(t, "^(\d+)\.\s*(.*)$", mNum)
        return mNum1 . ". " . Trim(mNum2)

    if RegExMatch(t, "^ºÙÀÓ\s*(.*)$", mAttach)
    {
        attachText := Trim(mAttach1)
        if (attachText = "")
            return "ºÙÀÓ"
        return "ºÙÀÓ " . attachText
    }

    return t
}

SSOK_BuildEducationReportParts(sourceText)
{
    cleanText := SSOK_CleanGeminiTextBlock(sourceText)
    if (Trim(cleanText) = "")
        return ""

    title := ""
    bodyText := ""
    seenBody := false
    inAttachmentList := false
    lines := StrSplit(cleanText, "`n", "`r")

    for idx, rawLine in lines
    {
        line := Trim(rawLine, " `t")
        if (line = "")
        {
            if (inAttachmentList)
                continue
            if (bodyText != "")
                bodyText .= "`r`n"
            continue
        }

        if (SSOK_IsReportAttachmentListLine(line, inAttachmentList))
        {
            inAttachmentList := true
            continue
        }
        else if (inAttachmentList)
        {
            inAttachmentList := false
        }

        if (title = "" && RegExMatch(line, "i)^Á¦\s*¸ñ\s*[:£º]\s*(.+)$", m))
        {
            title := Trim(m1)
            continue
        }

        if (title = "" && RegExMatch(line, "i)^Á¦\s*¸ñ\s*[:£º]\s*$"))
            continue

        if (title = "" && !seenBody && !SSOK_IsReportTitlelessFirstLine(line))
        {
            title := line
            continue
        }

        convertedLine := SSOK_ConvertReportBodyLine(line)
        if (convertedLine != "")
        {
            bodyText .= convertedLine . "`r`n"
            seenBody := true
        }
    }

    bodyText := RTrim(bodyText, "`r`n")
    summary := SSOK_BuildReportOverviewText(title)
    attachmentTitles := SSOK_BuildReportAttachmentTitles(cleanText)
    attachmentTitle := ""
    if (IsObject(attachmentTitles) && attachmentTitles.MaxIndex() != "")
        attachmentTitle := attachmentTitles[1]
    meta := SSOK_BuildReportMetaText()
    categoryLine := SSOK_BuildReportCategoryLine(cleanText, title)
    return {Title: title, Meta: meta, Summary: summary, Body: bodyText, CategoryLine: categoryLine, AttachmentTitle: attachmentTitle, AttachmentTitles: attachmentTitles}
}

SSOK_IsReportAttachmentListLine(line, alreadyInList := false)
{
    t := Trim(line, " `t")
    if (t = "")
        return alreadyInList

    if RegExMatch(t, "^(ºÙÀÓ|Âü°í|ÂüÁ¶)\s*[:£º]?\s*.*$")
        return true

    if (alreadyInList && RegExMatch(t, "^\d+\s*[.)]\s*.+"))
        return true

    if (alreadyInList && RegExMatch(t, "^³¡\.?$"))
        return true

    return false
}

SSOK_BuildReportOverviewText(title)
{
    cleanTitle := RegExReplace(title, "\s*\((ºÙÀÓ|Âü°í|ºÙÀÓ¡¤Âü°í)\)\s*$", "")
    cleanTitle := Trim(cleanTitle, " `t`r`n")
    if (cleanTitle = "")
        return "º¸°íÇÔ"
    return cleanTitle . SSOK_KoreanObjectParticle(cleanTitle) . " º¸°íÇÔ"
}

SSOK_KoreanObjectParticle(text)
{
    text := RegExReplace(text, "\s+", "")
    if (text = "")
        return "À»"
    lastChar := SubStr(text, 0)
    code := Asc(lastChar)
    if (code >= 0xAC00 && code <= 0xD7A3)
    {
        if (Mod(code - 0xAC00, 28) = 0)
            return "¸¦"
        return "À»"
    }
    return "À»"
}

SSOK_BuildReportAttachmentTitle(sourceText)
{
    titles := SSOK_BuildReportAttachmentTitles(sourceText)
    if (IsObject(titles) && titles.MaxIndex() != "")
        return titles[1]
    return ""
}

SSOK_BuildReportAttachmentTitles(sourceText)
{
    titles := []
    inAttach := false

    Loop, Parse, sourceText, `n, `r
    {
        line := Trim(A_LoopField, " `t")
        if (line = "")
        {
            if (inAttach)
                continue
            else
                continue
        }

        if RegExMatch(line, "^(ºÙÀÓ|Âü°í|ÂüÁ¶)\s*[:£º]?\s*(.*)$", m)
        {
            inAttach := true
            title := SSOK_CleanReportAttachmentTitle(m2)
            if (title != "")
                titles.Push(title)
            continue
        }

        if (inAttach && RegExMatch(line, "^\d+\s*[.)]\s*(.+)$", mItem))
        {
            title := SSOK_CleanReportAttachmentTitle(mItem1)
            if (title != "")
                titles.Push(title)
            continue
        }

        if (inAttach && RegExMatch(line, "^³¡\.?$"))
            continue

        if (inAttach)
            break
    }

    return titles
}

SSOK_CleanReportAttachmentTitle(text)
{
    title := Trim(text, " `t")
    title := RegExReplace(title, "^\d+\s*[.)]\s*", "")
    title := RegExReplace(title, "\s*\d+\s*ºÎ\.?\s*(³¡\.?)?\s*$", "")
    title := RegExReplace(title, "\s*³¡\.?\s*$", "")
    title := Trim(title, " `t.¡£")
    return title
}

SSOK_AddReportSourceMarkersToTitle(title, sourceText)
{
    markers := SSOK_DetectReportSourceMarkers(sourceText)
    if (markers = "")
        return title

    if (InStr(markers, "ºÙÀÓ") && InStr(title, "ºÙÀÓ"))
        markers := RegExReplace(markers, "^ºÙÀÓ¡¤?|¡¤?ºÙÀÓ$", "")
    if ((InStr(markers, "Âü°í") || InStr(markers, "ÂüÁ¶")) && RegExMatch(title, "Âü°í|ÂüÁ¶"))
        markers := RegExReplace(markers, "^Âü°í¡¤?|¡¤?Âü°í$", "")

    markers := Trim(markers, " ¡¤")
    if (markers = "")
        return title
    return title . " (" . markers . ")"
}

SSOK_DetectReportSourceMarkers(sourceText)
{
    hasAttach := RegExMatch(sourceText, "m)^\s*ºÙÀÓ\b|ºÙÀÓ\s*\d*\s*[.)]?")
    hasRef := RegExMatch(sourceText, "m)^\s*(Âü°í|ÂüÁ¶)\b|(Âü°í|ÂüÁ¶)\s*\d*\s*[.)]?")

    if (hasAttach && hasRef)
        return "ºÙÀÓ¡¤Âü°í"
    if (hasAttach)
        return "ºÙÀÓ"
    if (hasRef)
        return "Âü°í"
    return ""
}

SSOK_IsReportTitlelessFirstLine(line)
{
    t := Trim(line, " `t")
    if (t = "")
        return true
    if RegExMatch(t, "^(\d+\.|[¡à¡á¤±]|?|¡Û|[-£­¡Ø*]|[°¡-ÆR]\.|ºÙÀÓ|³¡\.?)")
        return true
    return false
}

SSOK_BuildReportCategoryLine(sourceText, title)
{
    category := SSOK_DetectReportCategory(sourceText, title)
    checked := Chr(0x2611)
    empty := "¡à"

    if (category = "»ç¾Èº¸°í")
        return empty . " Á¤Ã¥°áÁ¤    " . checked . " »ç¾Èº¸°í   " . empty . " Çà»ç    " . empty . " Áö½Ã°ËÅä    " . empty . " ±âÅ¸"
    if (category = "Çà»ç")
        return empty . " Á¤Ã¥°áÁ¤    " . empty . " »ç¾Èº¸°í   " . checked . " Çà»ç    " . empty . " Áö½Ã°ËÅä    " . empty . " ±âÅ¸"
    if (category = "Áö½Ã°ËÅä")
        return empty . " Á¤Ã¥°áÁ¤    " . empty . " »ç¾Èº¸°í   " . empty . " Çà»ç    " . checked . " Áö½Ã°ËÅä    " . empty . " ±âÅ¸"
    if (category = "±âÅ¸")
        return empty . " Á¤Ã¥°áÁ¤    " . empty . " »ç¾Èº¸°í   " . empty . " Çà»ç    " . empty . " Áö½Ã°ËÅä    " . checked . " ±âÅ¸"

    return checked . " Á¤Ã¥°áÁ¤    " . empty . " »ç¾Èº¸°í   " . empty . " Çà»ç    " . empty . " Áö½Ã°ËÅä    " . empty . " ±âÅ¸"
}

SSOK_DetectReportCategory(sourceText, title)
{
    text := title . "`n" . sourceText

    if RegExMatch(text, "(ºÐ·ù|º¸°í\s*À¯Çü|À¯Çü)\s*[:£º]?\s*(Á¤Ã¥\s*(°áÁ¤|º¸°í)|Á¤Ã¥°áÁ¤|Á¤Ã¥º¸°í)")
        return "Á¤Ã¥°áÁ¤"
    if RegExMatch(text, "(ºÐ·ù|º¸°í\s*À¯Çü|À¯Çü)\s*[:£º]?\s*»ç¾È\s*º¸°í")
        return "»ç¾Èº¸°í"
    if RegExMatch(text, "(ºÐ·ù|º¸°í\s*À¯Çü|À¯Çü)\s*[:£º]?\s*Çà»ç")
        return "Çà»ç"
    if RegExMatch(text, "(ºÐ·ù|º¸°í\s*À¯Çü|À¯Çü)\s*[:£º]?\s*Áö½Ã\s*°ËÅä")
        return "Áö½Ã°ËÅä"
    if RegExMatch(text, "(ºÐ·ù|º¸°í\s*À¯Çü|À¯Çü)\s*[:£º]?\s*±âÅ¸")
        return "±âÅ¸"

    if RegExMatch(text, "(»ç¾Èº¸°í|»óÈ²º¸°í|»ç°í|¹Î¿ø|¹ß»ý|ÇÇÇØ|±ä±Þ|ÇöÈ²\s*º¸°í|Á¶Ä¡\s*°á°ú)")
        return "»ç¾Èº¸°í"
    if RegExMatch(text, "(Áö½Ã°ËÅä|Áö½Ã\s*»çÇ×|°ËÅä\s*º¸°í)")
        return "Áö½Ã°ËÅä"
    if RegExMatch(text, "(Çà»ç|°³ÃÖ|¿î¿µ\s*°èÈ¹|Ã¼ÇèÇÐ½À|¿öÅ©¼ó|¿¬¼ö|¼³¸íÈ¸|°£´ãÈ¸|ÇùÀÇÈ¸|´ëÈ¸|ÃàÁ¦|Ä·ÇÁ)")
        return "Çà»ç"

    return "Á¤Ã¥°áÁ¤"
}

SSOK_BuildReportMetaText()
{
    FormatTime, yyyy,, yyyy
    FormatTime, mm,, M
    FormatTime, dd,, d
    org := SSOK_GetOrgName()
    if (org = "")
        org := "µµ´ãÁß"

    return "<" . yyyy . ". " . mm . ". " . dd . "., " . org . ", ¢Ï>"
}

SSOK_BuildReportSummary(sourceText, title, bodyText)
{
    captureNext := false

    Loop, Parse, sourceText, `n, `r
    {
        line := Trim(A_LoopField, " `t")
        if (line = "")
            continue

        if RegExMatch(line, "i)^Á¦\s*¸ñ\s*[:£º]")
            continue

        if RegExMatch(line, "^(°³¿ä|¿ä¾à|ÃßÁø\s*¹è°æ|¸ñÀû|ÇÊ¿ä¼º)\s*[:£º]\s*(.*)$", m)
        {
            candidate := SSOK_CleanReportSummaryLine(m2)
            if (candidate != "")
                return candidate
            captureNext := true
            continue
        }

        if (captureNext)
        {
            candidate := SSOK_CleanReportSummaryLine(line)
            if (candidate != "")
                return candidate
            if RegExMatch(line, "^(ÃßÁø\s*±Ù°Å|°ü·Ã\s*±Ù°Å|±Ù°Å|¡à|1\.|°¡\.)")
                break
        }
    }

    Loop, Parse, bodyText, `n, `r
    {
        candidate := SSOK_CleanReportSummaryLine(A_LoopField)
        if (candidate != "")
            return candidate
    }

    return ""
}

SSOK_CleanReportSummaryLine(line)
{
    line := Trim(line, " `t")
    line := RegExReplace(line, "^(¡à|?|-|¡Ø|\*|\d+\.|[°¡-ÆR]\.|\d+\))\s*", "")
    line := Trim(line, " `t")

    if (line = "")
        return ""
    if RegExMatch(line, "^(°³¿ä|¿ä¾à|ÃßÁø\s*¹è°æ|¸ñÀû|ÇÊ¿ä¼º|ÃßÁø\s*±Ù°Å|°ü·Ã\s*±Ù°Å|±Ù°Å|°ü·Ã|ÃßÁø\s*³»¿ë|¼¼ºÎ\s*³»¿ë|°ËÅä\s*»çÇ×|¼Ò¿ä\s*¿¹»ê|ÇâÈÄ\s*°èÈ¹|±â´ë\s*È¿°ú|ÇàÁ¤\s*»çÇ×|ÇùÁ¶\s*»çÇ×|Âü°í\s*»çÇ×|ºÙÀÓ|Âü°í|ÂüÁ¶|³¡\.?)\s*:?\s*$")
        return ""

    if (StrLen(line) > 90)
        line := SubStr(line, 1, 90)
    return line
}

SSOK_CleanGeminiTextBlock(text)
{
    text := StrReplace(text, "```text", "")
    text := StrReplace(text, "```", "")
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    return Trim(text, " `t`n")
}

SSOK_ConvertReportBodyLine(line)
{
    t := Trim(line, " `t")

    if RegExMatch(t, "^(¤·|¡Û|o|O|¡à).*(Á¤Ã¥°áÁ¤|Á¤Ã¥º¸°í|»ç¾Èº¸°í|Çà»ç|Áö½Ã°ËÅä|±âÅ¸)")
        return ""
    if RegExMatch(t, "^(ºÐ·ù|º¸°í\s*À¯Çü|À¯Çü)\s*[:£º]")
        return ""
    if RegExMatch(t, "^(³¡\.?|ºÙÀÓ\s*:?.*)$")
        return ""

    if RegExMatch(t, "^¡à\s*(.+)$", m)
        return "¡à " . Trim(m1)
    if RegExMatch(t, "^(¤·|¡Û|o|O)\s*(.+)$", m)
        return "  ¤· " . Trim(m2)
    if RegExMatch(t, "^[-£­]\s*(.+)$", m)
        return "    - " . Trim(m1)
    if RegExMatch(t, "^¡Ø\s*(.+)$", m)
        return "      ¡Ø " . Trim(m1)
    if RegExMatch(t, "^\*\s*(.+)$", m)
        return "      * " . Trim(m1)

    if RegExMatch(t, "^(\d+)\.\s*(.+)$", m)
        return "¡à " . Trim(m2)
    if RegExMatch(t, "^([°¡-ÆR])\.\s*(.+)$", m)
        return "  ¤· " . Trim(m2)
    if RegExMatch(t, "^(\d+)\)\s*(.+)$", m)
        return "    - " . Trim(m2)

    if (SSOK_IsReportSectionHeading(t))
        return "¡à " . RegExReplace(t, "\s*[:£º]\s*$", "")

    return t
}

SSOK_IsReportSectionHeading(text)
{
    t := Trim(text, " `t")
    t := RegExReplace(t, "\s*[:£º]\s*$", "")

    if RegExMatch(t, "^(°³¿ä|°³¿ä\s*¹×\s*±Ù°Å|ÃßÁø\s*±Ù°Å|°ü·Ã\s*±Ù°Å|±Ù°Å|¸ñÀû|ÃßÁø\s*³»¿ë|¼¼ºÎ\s*³»¿ë|°ËÅä\s*»çÇ×|¼Ò¿ä\s*¿¹»ê|ÇâÈÄ\s*°èÈ¹|±â´ë\s*È¿°ú|ÇàÁ¤\s*»çÇ×|ÇùÁ¶\s*»çÇ×|Âü°í\s*»çÇ×)$")
        return true

    return false
}
