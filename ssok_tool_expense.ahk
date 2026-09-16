; 간편 지출품의: 선택한 견적서 읽기 → 품명 첫 칸에서 Win+1 입력
; AutoHotkey v1 지출품의 모듈입니다. Win+1 / Win+2 / Win+3를 이 파일에서 직접 처리합니다.
#If SSOK_Expense_HotkeyContext()
; ------------------------------------------------------------
; 지출품의 전용 Win 단축키
; - Win+1 : 견적서 읽기 / 지출품의 품목 등록
; - Win+2 : K-에듀파인 화면을 MSAA로 읽어 검수여부·전자조달구매·총원인행위액 처리
; - Win+3 : K-에듀파인 사용자 지정 Tab 순서 실행
; Win+1 / Win+2 / Win+3를 이 파일에서 직접 처리합니다.
;
; 별도 #If 컨텍스트를 사용하여 구형 ssok_tool.ahk에 같은 단축키가
; 남아 있어도 AHK의 Duplicate hotkey 파싱 오류가 발생하지 않게 합니다.
; ------------------------------------------------------------
#1::
    KeyWait, LWin
    KeyWait, RWin
    SSOK_Expense_Run()
return

#2::
    KeyWait, LWin
    KeyWait, RWin
    SSOK_Expense_Win2Smart()
return

#If (SSOK_ExpenseBusy)
Esc::
    SSOK_ExpenseCancel := true
return
#If

SSOK_Expense_Run()
{
    global SSOK_ExpenseBusy, SSOK_ExpenseReady, SSOK_ExpenseRows
    if (SSOK_ExpenseBusy || WinActive("간편 지출품의 - 견적서 확인"))
        return
    if (SSOK_ExpenseReady)
    {
        SSOK_Expense_Write()
        return
    }
    SSOK_Expense_Capture()
}

SSOK_Expense_Capture()
{
    global SSOK_ExpenseRows, SSOK_ExpenseReady, SSOK_ExpenseSource
    global SSOK_ExpenseSourceWindow, SSOK_ExpenseBusy, SSOK_ExpenseStage
    SSOK_ExpenseBusy := true
    SSOK_ExpenseSourceWindow := WinExist("A")
    saved := ClipboardAll
    Clipboard := ""
    SendInput, ^c
    ClipWait, 2
    copied := Clipboard
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
        ; 품명/수량/단가/금액 미인식 안내만 큰 2초 자동종료 창으로 표시
        if InStr(result.error, "견적서의 품명, 수량, 단가, 금액이 없습니다.")
            SSOK_Expense_ShowParseMissingNotice()
        else
            MsgBox, 48, 간편 지출품의, % result.error
        return
    }
    ; 실제 입력용 행을 별도로 구성합니다.
    ; 상품 행 뒤에 배송비가 있으면 마지막 행으로 자동 추가합니다.
    SSOK_ExpenseRows := []
    for _, row in result.rows
        SSOK_ExpenseRows.Push(row)
    if (result.shipping > 0)
        SSOK_ExpenseRows.Push({name: "배송비", spec: "", qty: 1, amount: result.shipping, price: result.shipping})
    SSOK_ExpenseSource := result.source
    SSOK_Expense_ResetRegistration()
    SSOK_ExpenseReady := false
    SSOK_ExpenseStage := ""
    SSOK_Expense_Preview(result)
}



; ------------------------------------------------------------
; 견적서 필수 열 미인식 안내
; - 큰 글씨 / 굵게
; - 가운데 정렬
; - 확인 버튼 없음
; - 2초 후 자동 종료
; ------------------------------------------------------------
SSOK_Expense_ShowParseMissingNotice()
{
    Gui, SSOKExpenseParseNotice:Destroy
    Gui, SSOKExpenseParseNotice:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKExpenseParseNotice:Color, FFF7DF
    Gui, SSOKExpenseParseNotice:Margin, 18, 20

    ; 4줄을 각각 별도 Text로 분리해 높이 부족으로 잘리지 않도록 함
    Gui, SSOKExpenseParseNotice:Font, s16 Bold, Malgun Gothic
    Gui, SSOKExpenseParseNotice:Add, Text, w620 h36 Center c222222, 견적서의 품명 · 수량 · 단가 · 금액을

    Gui, SSOKExpenseParseNotice:Add, Text, y+1 w620 h36 Center c222222, 찾지 못했습니다.

    Gui, SSOKExpenseParseNotice:Font, s14 Bold, Malgun Gothic
    Gui, SSOKExpenseParseNotice:Add, Text, y+5 w620 h34 Center c222222, 견적서 표를 범위(Block) 지정한 후

    Gui, SSOKExpenseParseNotice:Add, Text, y+1 w620 h34 Center c222222, 품의(Win+1)를 다시 눌러주세요.

    Gui, SSOKExpenseParseNotice:Show, AutoSize Center NoActivate

    SetTimer, SSOKExpenseParseNoticeClose, -2000
}

SSOKExpenseParseNoticeClose:
    Gui, SSOKExpenseParseNotice:Destroy
return

; ------------------------------------------------------------
; Win+1 범위 미지정 안내
; - 큰 글씨
; - 가운데 정렬
; - 확인 버튼 없음
; - 2초 후 자동 종료
; ------------------------------------------------------------
SSOK_Expense_ShowCaptureNotice()
{
    Gui, SSOKExpenseCaptureNotice:Destroy
    Gui, SSOKExpenseCaptureNotice:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKExpenseCaptureNotice:Color, FFFBEA
    Gui, SSOKExpenseCaptureNotice:Margin, 18, 16

    ; 한 줄이 길어지지 않도록 3줄로 완전히 분리
    Gui, SSOKExpenseCaptureNotice:Font, s16 Bold, Malgun Gothic
    Gui, SSOKExpenseCaptureNotice:Add, Text, w620 h34 Center c222222, 견적서에서 품목 · 단가 · 금액을 범위 지정한 후

    Gui, SSOKExpenseCaptureNotice:Font, s15 Bold, Malgun Gothic
    Gui, SSOKExpenseCaptureNotice:Add, Text, y+2 w620 h34 Center c222222, 품의(Win+1)를 다시 눌러주세요.

    Gui, SSOKExpenseCaptureNotice:Font, s11 Norm, Malgun Gothic
    Gui, SSOKExpenseCaptureNotice:Add, Text, y+2 w620 h26 Center c555555, 견적서 표 전체를 선택하면 더 정확하게 인식합니다.

    Gui, SSOKExpenseCaptureNotice:Show, AutoSize Center NoActivate

    ; 2초 후 자동 종료
    SetTimer, SSOKExpenseCaptureNoticeClose, -2000
}

SSOKExpenseCaptureNoticeClose:
    Gui, SSOKExpenseCaptureNotice:Destroy
return

; ------------------------------------------------------------
; 견적서 확인 화면 표시 전용 숫자 포맷
; 실제 입력값은 변경하지 않고 천 단위 쉼표만 표시합니다.
; 소수 단가가 있으면 소수점 이하도 그대로 보존합니다.
; 예: 935000 -> 935,000 / 32503.334 -> 32,503.334
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

    ; 혹시 기존 쉼표가 들어 있어도 제거 후 다시 정리
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
    Gui, SSOKExpense:New, +AlwaysOnTop +LabelSSOKExpense +HwndSSOK_ExpensePreviewHwnd, 간편 지출품의 - 견적서 확인
    Gui, SSOKExpense:Font, s9, Malgun Gothic

    displayTotal := SSOK_Expense_FormatPreviewNumber(result.total)
    displayShipping := SSOK_Expense_FormatPreviewNumber(result.shipping)
    displayGrandTotal := SSOK_Expense_FormatPreviewNumber(result.total + result.shipping)
    Gui, SSOKExpense:Add, Text, w980, % result.source . " / 상품 " . result.rows.Length() . "개 / 상품 " . displayTotal . "원, 배송비 " . displayShipping . "원 합계 " . displayGrandTotal . "원"

    ; 품의/품목 등록은 앞 6칸을 사용하고, 원인행위는 8칸 전체를 사용합니다.
    ; 견적서에 조달수수료/용도 값이 없으면 두 칸은 빈칸으로 처리합니다.
    Gui, SSOKExpense:Add, ListView, w980 h280, 품명|규격|수량|단위|단가|금액|조달수수료|용도(적요)

    for i, row in result.rows
    {
        displayPrice := SSOK_Expense_FormatPreviewNumber(row.price)
        displayAmount := SSOK_Expense_FormatPreviewNumber(row.amount)
        LV_Add("", row.name, row.spec, row.qty, "개", displayPrice, displayAmount, "", "")
    }

    if (result.shipping > 0)
    {
        displayShipping := SSOK_Expense_FormatPreviewNumber(result.shipping)
        LV_Add("", "배송비", "", 1, "개", displayShipping, displayShipping, "", "")
    }

    LV_ModifyCol(1, 350)
    LV_ModifyCol(2, 120)
    LV_ModifyCol(3, 55)
    LV_ModifyCol(4, 55)
    LV_ModifyCol(5, 85)
    LV_ModifyCol(6, 85)
    LV_ModifyCol(7, 90)
    LV_ModifyCol(8, 120)

    ; --------------------------------------------------------
    ; 기존 3개 메뉴 유지 + 우측 소형 원인행위 메뉴 추가
    ; --------------------------------------------------------
    ; --------------------------------------------------------
    ; 하단 버튼: 왼쪽 3개는 촘촘하게, 원인행위는 오른쪽 끝에 작게 분리
    ; --------------------------------------------------------
    Gui, SSOKExpense:Font, s9 Bold, Malgun Gothic
    Gui, SSOKExpense:Add, Button, x16 y+8 w300 h58 gSSOKExpenseArm Default, K-에듀파인 지출품의`n(품목.개요.제목)`n자동 입력하기

    Gui, SSOKExpense:Font, s9 Norm, Malgun Gothic
    Gui, SSOKExpense:Add, Button, x326 yp w200 h58 gSSOKExpenseItemsArm, 품의목록 입력하기`n(행추가 후 실행)

    Gui, SSOKExpense:Add, Button, x536 yp w120 h58 gSSOKExpenseCancel, 취소하기

    ; 원행목록은 다른 버튼과 완전히 분리하여 창 제일 우측에 아주 작게 배치
    Gui, SSOKExpense:Font, s6 Norm, Malgun Gothic
    Gui, SSOKExpense:Add, Button, x930 yp+14 w50 h30 gSSOKExpenseCauseArm, 원행목록`n입력하기


    ; 실제 창 크기로 계산하되 공간이 부족해도 메인 메뉴 오른쪽으로 넘기지 않습니다.
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
    if (InStr(text, "상품번호") && InStr(text, "세액"))
        out.source := "11번가"
    else if (InStr(text, "공급자명") && InStr(text, "공급합계"))
    {
        ; 지마켓은 HTML 표에서 복사한 탭 형식과 PDF에서 복사한 세로 형식이
        ; 같은 견적서라도 서로 다르게 들어올 수 있습니다.
        ; 7열 고정/1<TAB> 여부로 나누지 않고 공통 파서에서 둘 다 처리합니다.
        return SSOK_Expense_ParseGmarketUniversal(text)
    }
    else
    {
        ; G마켓/11번가가 아니면 표의 머리글을 읽는 범용 견적서 파서로 처리합니다.
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
        if (RegExMatch(line, "^배송비(?:\(선결제\))?[\s|]+([\d,]+)원?", ship))
            out.shipping := StrReplace(ship1, ",") + 0

        ; 원본 견적서 합계도 읽어 파싱 결과와 대조합니다.
        if (RegExMatch(line, "^합계"))
        {
            nums := []
            posNum := 1
            while (posNum := RegExMatch(line, "([\d,]+)원", n, posNum))
            {
                nums.Push(StrReplace(n1, ",") + 0)
                posNum += StrLen(n)
            }
            if (nums.Length())
                out.quoteTotal := nums[nums.Length()]
        }

        if (RegExMatch(line, "^총 구매금액[\s|]+([\d,]+)원?", gm))
            out.grandTotal := StrReplace(gm1, ",") + 0

        if (RegExMatch(line, "^(합계|배송비|총합계|총 구매금액|\*)"))
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
            need := (out.source = "11번가" ? 8 : 7)
            if (cells.Length() != need || !RegExMatch(cells[1], "^\d+$"))
            {
                out.error := "상품 행의 열을 구분하지 못했습니다. 원본 견적서 표에서 복사해 주세요. 문제 행: " . line
                return out
            }
            if (cells[1] + 0 != expected)
            {
                out.error := "상품 번호가 1번부터 연속되지 않습니다. 전체 상품 내역을 다시 선택해 주세요."
                return out
            }
            expected++
            name := cells[out.source = "11번가" ? 3 : 2]
            qty := SSOK_Expense_Number(cells[4])
            amount := SSOK_Expense_Number(cells[need])
            if (name = "" || qty = "" || qty <= 0 || amount = "" || amount < 0)
            {
                out.error := "상품명·수량·금액을 확인해 주세요. 문제 행: " . line
                return out
            }
            ; K-에듀파인은 소수 단가 × 수량 결과의 소수 부분을 버릴 수 있습니다.
            ; 일반 반올림으로 6자리 단가를 만들면 목표금액보다 1원 작아질 수 있으므로,
            ; 나누어떨어지지 않는 경우 단가를 소수 6자리에서 "올림"하여
            ; 예상금액이 견적서의 원래 공급합계와 정확히 맞도록 합니다.
            price := SSOK_Expense_CalcExpectedPrice(amount, qty, out)

            out.rows.Push({name: name, spec: "", qty: qty, amount: amount, price: price})
            out.total += amount
        }
        else if (out.source = "지마켓" && out.rows.Length())
        {
            ; 지마켓의 상품 바로 다음 줄에 표시되는 필수선택/추가구성/색상은
            ; 상품명에 붙이지 않고 K에듀파인 "규격" 값으로 보존합니다.
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
        out.error := "읽을 수 있는 상품 행이 없습니다. 원본 견적서의 표를 선택해 주세요."
        return out
    }

    ; 상품 합계가 원본 합계와 다르면 자동입력을 시작하지 않습니다.
    if (out.quoteTotal > 0 && Round(out.total) != Round(out.quoteTotal))
    {
        out.error := "견적서 상품 합계 검증에 실패했습니다.`n원본 합계: " . out.quoteTotal . "원`n인식 합계: " . out.total . "원`n자동입력을 중단합니다."
        return out
    }

    ; 총 구매금액 = 상품합계 + 배송비 검증
    if (out.grandTotal > 0 && Round(out.total + out.shipping) != Round(out.grandTotal))
    {
        out.error := "견적서 총 구매금액 검증에 실패했습니다.`n원본 총 구매금액: " . out.grandTotal . "원`n인식 금액: " . (out.total + out.shipping) . "원`n자동입력을 중단합니다."
        return out
    }

    return out
}


; ============================================================================
; G마켓 HTML / PDF 공통 파서
;
; 지원 형식
; 1) HTML 표 복사: 번호<TAB>상품명<TAB>공급자명<TAB>수량<TAB>공급가액<TAB>할인금액<TAB>공급합계
; 2) PDF 복사: 위 각 셀이 줄바꿈되어 세로로 내려오는 형식
; 3) Markdown/파이프 표: | 번호 | 상품명 | ... |
;
; 핵심은 행의 열 개수를 고정하지 않는 것입니다.
; 탭/줄바꿈/파이프를 모두 셀 토큰으로 만든 뒤
; "수량 + 공급가액 + 할인금액 + 공급합계" 패턴으로 각 상품행을 확정합니다.
; ============================================================================
SSOK_Expense_ParseGmarketUniversal(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "지마켓(HTML/PDF 자동인식)"

    text := StrReplace(text, "`r")
    tokens := []

    for _, rawLine in StrSplit(text, "`n")
    {
        line := Trim(rawLine, " `t" . Chr(160))
        if (line = "")
            continue

        ; Markdown 표라면 파이프를 실제 셀 구분자로 취급합니다.
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
            cell := StrReplace(cell, "　", " ")
            cell := RegExReplace(cell, "[ `t]+", " ")
            cell := Trim(cell)

            if (cell = "")
                continue

            ; Markdown 정렬선은 데이터가 아닙니다.
            if RegExMatch(cell, "^:?-{2,}:?$")
                continue

            tokens.Push(cell)
        }
    }

    if (tokens.Length() < 8)
    {
        out.error := "지마켓 견적서의 상품 표를 충분히 읽지 못했습니다."
        return out
    }

    ; HTML에서는 머리글이 여러 셀, 일부 브라우저/복사 방식에서는 한 셀로
    ; 붙어서 들어올 수 있으므로 '공급합계'가 포함된 토큰까지만 머리글로 봅니다.
    headerEnd := 0
    Loop, % tokens.Length()
    {
        if InStr(tokens[A_Index], "공급합계")
        {
            headerEnd := A_Index
            break
        }
    }

    if (!headerEnd)
    {
        out.error := "지마켓 견적서의 '공급합계' 머리글을 찾지 못했습니다."
        return out
    }

    pos := headerEnd + 1
    while (pos <= tokens.Length() && Trim(tokens[pos]) != "1")
        pos++

    if (pos > tokens.Length())
    {
        out.error := "지마켓 견적서에서 1번 상품을 찾지 못했습니다."
        return out
    }

    expected := 1

    while (pos <= tokens.Length())
    {
        ; 다음 상품 번호를 찾습니다. 옵션에 포함된 '00_...' 같은 값은
        ; 정확히 숫자 하나와 같지 않으므로 상품번호로 오인하지 않습니다.
        while (pos <= tokens.Length() && Trim(tokens[pos]) != expected . "")
            pos++

        if (pos > tokens.Length())
            break

        pos++
        if (pos > tokens.Length())
            break

        ; 번호 바로 다음 셀이 상품명입니다. HTML/Markdown 표에서는 셀 하나,
        ; PDF 세로 복사에서도 첫 다음 줄이 상품명으로 들어옵니다.
        name := Trim(tokens[pos])
        if (name = "" || RegExMatch(name, "^\\d+$") || SSOK_Expense_IsWonLine(name))
        {
            out.error := "지마켓 견적서의 " . expected . "번 상품명을 읽지 못했습니다."
            return out
        }

        pos++
        qtyPos := 0
        qty := ""
        finalAmount := ""

        ; 공급자명은 한 셀/여러 줄 모두 무시하고,
        ; 수량 + 공급가액 + 할인금액 + 공급합계가 연속되는 위치를 찾습니다.
        scan := pos
        scanLimit := Min(tokens.Length() - 3, pos + 30)
        while (scan <= scanLimit)
        {
            qText := Trim(tokens[scan])
            q := SSOK_Expense_Number(qText)

            if (q != "" && q > 0 && !InStr(qText, "원")
                && SSOK_Expense_IsWonLine(tokens[scan + 1])
                && SSOK_Expense_IsWonLine(tokens[scan + 2])
                && SSOK_Expense_IsWonLine(tokens[scan + 3]))
            {
                supplyAmount := SSOK_Expense_Number(tokens[scan + 1])
                discountAmount := SSOK_Expense_Number(tokens[scan + 2])
                totalAmount := SSOK_Expense_Number(tokens[scan + 3])

                ; 지마켓은 공급가액 - 할인금액 = 공급합계입니다.
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
            out.error := "지마켓 견적서의 " . expected . "번 상품에서 수량·공급가액·할인금액·공급합계를 읽지 못했습니다."
            return out
        }

        price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)

        ; 공급합계 다음부터 다음 상품번호 전까지는 선택옵션/추가구성입니다.
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

            if RegExMatch(cell, "^(합계|배송비|총합계|총 구매금액|결제금액|주문금액)")
                break

            ; 금액과 순수 숫자는 옵션에서 제외합니다.
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
        out.error := "읽을 수 있는 상품 행이 없습니다. 지마켓 상품 표 전체를 선택해 주세요."

    return out
}


; ============================================================================
; G마켓 계열 PDF 세로형 파서
;
; PDF에서 표를 복사했을 때 아래처럼 셀 내용이 세로로 풀리는 형태를 처리합니다.
;
; 번호
; 상품명 / 필수선택 / 추가구성
; 공급자명
; 수량
; 공급가액
; 할인금액
; 공급합계
; 1
; 상품명
; 공급자명(여러 줄 가능)
; 8
; 30,400원
; 2,000원
; 28,400원
; 선택옵션(있을 수 있음)
; 2
; ...
;
; 핵심:
; - 상품명은 번호 바로 다음의 첫 텍스트를 사용
; - 공급자명은 몇 줄로 갈라져도 무시
; - "수량 + 공급가액 + 할인금액 + 공급합계" 4줄 패턴을 찾아 행을 확정
; - K-에듀파인 금액은 할인 반영 후 "공급합계"를 사용
; - 공급합계 뒤 다음 상품번호 전까지의 텍스트는 규격/옵션으로 보존
; ============================================================================
SSOK_Expense_ParseGmarketPdfVertical(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "지마켓 PDF(구형 세로형 파서)"

    text := StrReplace(text, "`r")
    rawLines := StrSplit(text, "`n")
    lines := []

    for _, raw in rawLines
    {
        line := Trim(raw, " `t" . Chr(160))
        if (line = "")
            continue

        line := StrReplace(line, Chr(160), " ")
        line := StrReplace(line, "　", " ")
        line := RegExReplace(line, "[ `t]+", " ")
        lines.Push(Trim(line))
    }

    if (lines.Length() < 10)
    {
        out.error := "지마켓 PDF의 상품 표를 충분히 읽지 못했습니다."
        return out
    }

    ; 헤더 확인
    headerOK := false
    headerEnd := 0
    Loop, % lines.Length()
    {
        s := lines[A_Index]
        if (InStr(s, "공급합계"))
        {
            headerEnd := A_Index
            headerOK := true
            break
        }
    }

    if (!headerOK)
    {
        out.error := "지마켓 PDF의 '공급합계' 머리글을 찾지 못했습니다."
        return out
    }

    ; 첫 상품 번호 1 찾기
    pos := headerEnd + 1
    while (pos <= lines.Length() && Trim(lines[pos]) != "1")
        pos++

    if (pos > lines.Length())
    {
        out.error := "지마켓 PDF에서 1번 상품을 찾지 못했습니다."
        return out
    }

    expected := 1

    while (pos <= lines.Length())
    {
        ; 현재 행 번호가 맞는 위치를 찾습니다.
        while (pos <= lines.Length() && Trim(lines[pos]) != expected . "")
            pos++

        if (pos > lines.Length())
            break

        rowNoPos := pos
        pos++

        if (pos > lines.Length())
            break

        ; 번호 바로 다음 첫 텍스트를 상품명으로 사용합니다.
        name := Trim(lines[pos])
        if (name = "" || RegExMatch(name, "^\d+$") || SSOK_Expense_IsWonLine(name))
        {
            out.error := "지마켓 PDF의 " . expected . "번 상품명을 읽지 못했습니다."
            return out
        }

        pos++
        qtyPos := 0
        qty := ""
        supplyAmount := ""
        discountAmount := ""
        finalAmount := ""

        ; 공급자명은 여러 줄일 수 있으므로 건너뛰면서
        ; 수량 + 공급가액 + 할인금액 + 공급합계 패턴을 찾습니다.
        scan := pos
        while (scan + 3 <= lines.Length())
        {
            qText := Trim(lines[scan])
            q := SSOK_Expense_Number(qText)

            if (q != "" && q > 0 && !InStr(qText, "원")
                && SSOK_Expense_IsWonLine(lines[scan + 1])
                && SSOK_Expense_IsWonLine(lines[scan + 2])
                && SSOK_Expense_IsWonLine(lines[scan + 3]))
            {
                s1 := SSOK_Expense_Number(lines[scan + 1])
                s2 := SSOK_Expense_Number(lines[scan + 2])
                s3 := SSOK_Expense_Number(lines[scan + 3])

                ; 이 견적서 구조에서는 공급가액 - 할인금액 = 공급합계입니다.
                ; 수식이 맞는 패턴을 우선 채택하여 다른 숫자를 수량으로 오인하지 않게 합니다.
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

            ; 다음 품목 번호까지 갔는데 가격 패턴을 못 찾았으면 현재 행 실패
            if (scan > pos && Trim(lines[scan]) = (expected + 1) . "")
                break

            scan++
        }

        if (!qtyPos)
        {
            out.error := "지마켓 PDF의 " . expected . "번 상품에서 수량·공급가액·할인금액·공급합계를 읽지 못했습니다."
            return out
        }

        if (qty <= 0 || finalAmount < 0)
        {
            out.error := "지마켓 PDF의 " . expected . "번 상품 수량 또는 공급합계가 올바르지 않습니다."
            return out
        }

        price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)

        ; 공급합계 뒤의 옵션/추가구성은 다음 상품 번호 전까지 규격으로 저장합니다.
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

            ; 마지막 상품 뒤의 합계/배송비 영역은 옵션으로 넣지 않습니다.
            if RegExMatch(s, "^(합계|배송비|총합계|총 구매금액|결제금액|주문금액)")
                break

            ; 금액/숫자만 있는 잔여값은 규격에서 제외
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
        out.error := "읽을 수 있는 상품 행이 없습니다. 지마켓 PDF 상품 표 전체를 선택해 주세요."

    return out
}

SSOK_Expense_IsWonLine(s)
{
    ; HTML/Markdown 복사 시 금액이 **28,400원**처럼 강조 기호를 포함할 수 있습니다.
    s := StrReplace(s, "*")
    s := Trim(s, " `t" . Chr(160))
    return RegExMatch(s, "^\d[\d,]*(?:\.\d+)?\s*원$")
}


; ============================================================================
; 범용 견적서 표 파서
;
; 지원 예:
;   No / 품명 / Description of goods / 수량 / Quantity / 금액 / Amount
;      / 부가세 / VAT / 합계 / Total
;
;   No / 품목·규격 / 단위 / 수량 / 단가 / 공급가 / 세액 / 합계
;
; 규칙:
;   - 최종 합계(Total/합계)를 실제 금액으로 사용
;   - 단가 = 최종 합계 / 수량
;   - 규격 열이 따로 있으면 규격 입력, 없으면 빈칸
;   - 단위는 원본과 관계없이 K-에듀파인에서 항상 "개"
;   - 금액 = 견적서의 원래 최종 합계
;   - 조달수수료 / 용도(적요)는 빈칸으로 유지
; ============================================================================
SSOK_Expense_ParseGenericTable(text)
{
    ; 1순위: Excel/스프레드시트 표
    result := SSOK_Expense_ParseExcelTable(text)
    if IsObject(result) && (result.rows.Length() || result.recognized)
        return result

    ; 2순위: PDF에서 한 품목 전체가 한 줄로 복사되는 형태
    result := SSOK_Expense_ParseGenericPdfCompact(text)
    if IsObject(result) && result.rows.Length()
        return result

    ; 3순위: 기존 탭/웹 표
    result := SSOK_Expense_ParseGenericTabbed(text)
    if IsObject(result) && result.rows.Length()
        return result

    ; 4순위: PDF에서 셀 하나가 한 줄씩 내려오는 형태
    result := SSOK_Expense_ParseGenericVertical(text)
    if IsObject(result) && result.rows.Length()
        return result

    out := SSOK_Expense_NewGenericResult()
    out.error := "견적서의 품명, 수량, 단가, 금액이 없습니다. `n견적서 표를 먼저 범위(Block) 지정한 후 품의(win+1)을 눌러주세요."
    return out
}


; ============================================================================
; PDF 압축형 표 파서
;
; PDF에서 범위 지정 복사 시 셀마다 줄바꿈되지 않고 다음처럼 한 행으로
; 합쳐지는 경우를 처리합니다.
;
; 형식 A
; 1 Service Package(통합전해조) 1 500,000 50,000 550,000
;   = 번호 / 품명 / 수량 / 금액 / VAT / 합계
;
; 형식 B
; 1 마술사 EA 16 13,000 189,091 18,909 208,000
;   = 번호 / 품목·규격 / 단위 / 수량 / 단가 / 공급가 / 세액 / 합계
;
; 두 형식 모두 K-에듀파인 예상단가는 VAT 포함 최종 "합계 ÷ 수량"을
; 기준으로 만듭니다.
; ============================================================================
SSOK_Expense_ParseGenericPdfCompact(text)
{
    out := SSOK_Expense_NewGenericResult()
    out.source := "PDF 견적서(행 자동인식)"

    cleanText := StrReplace(text, "`r")
    flatHeader := RegExReplace(cleanText, "[\s/·ㆍ_\-().]+", "")

    mode := 0

    ; 형식 A: 품명 / 수량 / 금액 / 부가세 / 합계
    if ((InStr(cleanText, "부가세") || InStr(cleanText, "VAT"))
        && (InStr(cleanText, "합계") || InStr(cleanText, "Total"))
        && (InStr(cleanText, "금액") || InStr(cleanText, "Amount")))
    {
        mode := 1
    }
    ; 형식 B: 품목·규격 / 단위 / 수량 / 단가 / 공급가 / 세액 / 합계
    else if (InStr(flatHeader, "품목규격")
        && InStr(flatHeader, "단위")
        && InStr(flatHeader, "수량")
        && InStr(flatHeader, "단가")
        && InStr(flatHeader, "공급가")
        && InStr(flatHeader, "세액")
        && InStr(flatHeader, "합계"))
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

        ; 여러 종류의 특수 공백을 일반 공백으로 정리
        line := StrReplace(line, Chr(160), " ")
        line := StrReplace(line, "　", " ")
        line := RegExReplace(line, "[ `t]+", " ")
        line := Trim(line)

        matched := false

        if (mode = 1)
        {
            ; 번호 + 품명 + 수량 + 금액 + VAT + 합계
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
            ; 번호 + 품목·규격 + 단위 + 수량 + 단가 + 공급가 + 세액 + 합계
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

        ; 1번부터 실제 품목 시작
        if (!started)
        {
            if (rowNo != 1)
                continue

            started := true
        }

        if (rowNo != expected)
        {
            out.error := "PDF 견적서의 품목 번호가 1번부터 연속되지 않습니다.`n예상 번호: " . expected . "`n인식 번호: " . rowNo
            return out
        }

        if (name = "" || qty = "" || qty <= 0 || finalAmount = "" || finalAmount < 0)
        {
            out.error := "PDF 견적서의 " . rowNo . "번 품목에서 품명·수량·합계를 정확히 읽지 못했습니다."
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
; Excel / 스프레드시트 표 전용 파서
; ============================================================================
SSOK_Expense_ParseExcelTable(text)
{
    out := {rows: [], source: "엑셀 견적서(헤더 자동인식)", total: 0, shipping: 0, quoteTotal: 0, grandTotal: 0, fractional: false, error: "", recognized: false, skipped: 0}

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

        ; 수량·단가·금액이 전부 빈 행은 제목/구분행으로 제외
        if (qty = "" && unitPrice = "" && amount = "")
        {
            out.skipped++
            continue
        }

        ; 수량이 없으면 합계/설명행 가능성이 높으므로 제외
        if (qty = "" || qty <= 0)
        {
            out.skipped++
            continue
        }

        ; 단가와 금액이 모두 없으면 가격을 만들 수 없으므로 제외
        if (unitPrice = "" && amount = "")
        {
            out.skipped++
            continue
        }

        content := ""
        spec := ""

        ; 품목/규격 하나의 열
        if (combinedText != "")
        {
            content := combinedText
        }
        ; 품목+품명이 둘 다 있는 표
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

        ; Excel은 명시된 단가를 우선 사용
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
        out.error := "엑셀 표의 머리글은 찾았지만 입력할 품목 행을 찾지 못했습니다.`n수량과 단가 또는 금액이 있는 행이 포함되도록 다시 복사해 주세요."
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

    compact := RegExReplace(s, "[\s" . Chr(160) . "　/·ㆍ_\-().]+", "")
    lower := compact
    StringLower, lower, lower

    if (lower = "no" || compact = "번호" || compact = "순번")
        return "no"

    if (InStr(compact, "품목규격") || InStr(compact, "품명규격"))
        return "name_spec"

    if (compact = "품목" || compact = "상품" || compact = "물품")
        return "item"

    if (compact = "품명" || compact = "상품명" || compact = "내용")
        return "name"

    if (compact = "규격" || compact = "사이즈"
        || lower = "spec" || lower = "specification" || lower = "size")
        return "spec"

    if (compact = "수량" || lower = "quantity" || lower = "qty")
        return "qty"

    if (compact = "단위" || lower = "unit")
        return "unit"

    if (compact = "단가" || compact = "예상단가"
        || compact = "판매가" || compact = "판매단가" || compact = "가격"
        || lower = "unitprice" || lower = "price" || lower = "sellingprice")
        return "unitprice"

    if (compact = "금액" || compact = "합계" || compact = "총액"
        || compact = "공급합계" || compact = "공급가" || compact = "공급가액"
        || compact = "공급금액" || lower = "amount" || lower = "total")
        return "amount"

    if (compact = "비고" || compact = "참고" || lower = "remark" || lower = "remarks")
        return "remark"

    if (InStr(compact, "G2B") || InStr(compact, "식별번호") || InStr(compact, "조달식별번호"))
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
    s := StrReplace(s, "　", " ")
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
    s := StrReplace(s, "원")
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
    return {rows: [], source: "일반 견적서(헤더 자동인식)", total: 0, shipping: 0, quoteTotal: 0, grandTotal: 0, fractional: false, error: ""}
}

; ------------------------------------------------------------
; 탭/마크다운 표 형태
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

        ; Markdown 표 복사도 탭형식으로 변환
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

        ; 합계가 있으면 최우선. 합계가 없을 때는 VAT도 없는 단순 금액표만 허용.
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

        ; 표 구분선은 건너뜀
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
            out.error := "일반 견적서의 품목 번호가 1번부터 연속되지 않습니다. 문제 번호: " . rowNo
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
        out.error := "일반 견적서에서 품명·수량·합계를 정확히 읽지 못했습니다."
        return ""
    }

    price := SSOK_Expense_CalcExpectedPrice(finalAmount, qty, out)
    return {name:name, spec:spec, qty:qty, amount:finalAmount, price:price}
}

; ------------------------------------------------------------
; 셀 하나가 한 줄씩 복사되는 표 형태
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

        ; markdown 장식 제거
        line := Trim(line, "|")
        if (line = "" || RegExMatch(line, "^[-: |]+$"))
            continue

        lines.Push(line)
    }

    if (lines.Length() < 5)
        return ""

    ; 첫 번째 데이터 번호 1을 찾고, 그 앞에서 가장 가까운 No/번호 헤더를 찾습니다.
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

        ; 알 수 없는 머리글도 실제 열일 수 있으므로 ignore 열로 보존
        if (kind = "")
            kind := "ignore"

        ; 품명/Description, 수량/Quantity처럼 같은 열의 한글/영문이 연속되면 하나로 합침
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

            ; 규격은 선택사항. 다음 열 형식이 이미 맞으면 규격은 빈칸으로 간주.
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

            ; 단위도 원본에서 비어 있을 수 있으며 K-에듀파인에는 어차피 "개"를 사용.
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
            out.error := "일반 견적서의 " . expected . "번 품목을 읽는 중 열 구분에 실패했습니다."
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
            out.error := "일반 견적서의 " . expected . "번 품목에서 품명·수량·합계를 찾지 못했습니다."
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
        return RegExMatch(Trim(value), "i)^(EA|PCS?|SET|개|식|대|권|매|병|박스|BOX)$")

    return false
}

SSOK_Expense_HeaderKind(s)
{
    s := Trim(s, " `t" . Chr(160))
    s := StrReplace(s, "*")
    compact := RegExReplace(s, "[\s/·ㆍ_\-().]+", "")

    if RegExMatch(s, "i)^(No\.?|번호|순번)$")
        return "no"

    ; 품목/규격이 한 셀에 같이 있는 경우 내용으로 사용하고 규격은 비워 둡니다.
    if (InStr(compact, "품목규격") || InStr(compact, "품명규격"))
        return "name_spec"

    if RegExMatch(s, "i)(품명|품목|상품명|내용|Description\s*of\s*goods)")
        return "name"

    if RegExMatch(s, "i)^(규격|Spec|Specification)$")
        return "spec"

    if RegExMatch(s, "i)^(수량|Quantity|Qty\.?)$")
        return "qty"

    if RegExMatch(s, "i)^(단위|Unit)$")
        return "unit"

    if RegExMatch(s, "i)^(단가|Unit\s*Price)$")
        return "unitprice"

    if RegExMatch(s, "i)^(공급가|공급가액|공급금액|Supply\s*Amount)$")
        return "supply"

    if RegExMatch(s, "i)^(부가세|세액|VAT)$")
        return "vat"

    if RegExMatch(s, "i)^(합계|Total|총액|공급합계)$")
        return "total"

    if RegExMatch(s, "i)^(금액|Amount)$")
        return "amount"

    return ""
}

; 최종 합계 ÷ 수량으로 K-에듀파인 예상단가 생성
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
    s := Trim(StrReplace(StrReplace(s, ","), "원"))
    return RegExMatch(s, "^\d+(?:\.\d+)?$") ? s + 0 : ""
}

SSOK_Expense_Write()
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
        MsgBox, 48, 간편 지출품의, 견적서는 보관 중입니다. 입력을 시작했던 K-에듀파인 창에서 예산 선택 후 Win+1을 눌러 주세요.
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
    ; 경로 문자열은 다음 실행에도 유지하되, COM 객체와 창 핸들은 위에서 초기화합니다.
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
    ; 이 단계에서는 오직 행추가 버튼만 확보합니다.
    ; 개요/제목 객체는 품목 입력이 모두 끝난 뒤에만 접근합니다.
    ; --------------------------------------------------------
    if (!SSOK_Expense_MSAA_PrepareAddButtonOnly(target))
    {
        SSOK_ExpenseBusy := false
        SSOK_ExpenseReady := true
        SSOK_ExpenseStage := "auto"
        ToolTip
        MsgBox, 48, 간편 지출품의, 행추가 버튼을 찾지 못했습니다.`n%SSOK_ExpenseLastError%`n품목 표와 행추가 버튼이 보이는 상태에서 다시 Win+1을 눌러 주세요.`n진단 기록: ssok_expense_diagnostic.log
        return
    }

    ; --------------------------------------------------------
    ; 행추가와 품목 입력을 마친 다음 개요, 제목 순으로 입력합니다.
    ToolTip, % needRows . "개 행 생성 중..."

    currentRows := SSOK_Expense_ItemRowSnapshot(target)
    remaining := needRows
    if (IsObject(SSOK_ExpensePendingAdd))
    {
        remaining := SSOK_Expense_RemainingRows(SSOK_ExpensePendingAdd.before, currentRows, needRows)
        if (remaining <= 0)
        {
            ; 이미 모든 행이 있거나 행 수를 확정할 수 없으면 추가 클릭을 하지 않습니다.
            SSOK_ExpenseBusy := false
            SSOK_ExpenseReady := true
            SSOK_ExpenseStage := "resume-input"
            ToolTip
            MsgBox, 64, 간편 지출품의, 견적서는 그대로 보관 중입니다.`n입력할 빈 행을 필요한 수만큼 준비하고 첫 행의 '품명' 칸을 클릭한 뒤 Win+1을 누르세요.`n다음에는 행추가 없이 저장된 견적서를 입력합니다.
            return
        }
        SSOK_Expense_Log("resume-add remaining=" . remaining . " currentRows=" . currentRows)
    }
    else
        SSOK_ExpensePendingAdd := {target:target, before:currentRows}
    if (!SSOK_Expense_AddRowsOneClick(target, remaining)
        || !SSOK_Expense_MSAA_IsFixedAddButton(SSOK_ExpenseAddButtonCache))
    {
        SSOK_Expense_StopForBudget()
        ToolTip
        SSOK_ExpenseBusy := true
        MsgBox, 64, 간편 지출품의, 예산 선택 후 견적서를 다시 진행해 주세요., 1
        SSOK_ExpenseBusy := false
        return
    }
    SSOK_ExpensePendingAdd := ""
    ; 마지막 행 생성 및 포커스 반영 시간
    Sleep, 70

    ; N개 생성 후 마지막 생성 행에 있으므로 첫 행까지 N-1칸 위로 이동.
    ; 대량 행에서는 {Up 31} 같은 묶음 전송을 Nexacro가 놓칠 수 있으므로
    ; 한 칸씩 보내어 정확하게 첫 행으로 이동합니다.
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

    ; 스크롤/포커스 반영 대기
    Sleep, 220

    ToolTip
    ; Busy는 DoInput의 finally에서만 해제합니다.
    SSOK_ExpenseStage := "input"

    ; 다시 Win+1을 누르지 않고 바로 기존 입력
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
            MsgBox, 48, 간편 지출품의, 입력이 중단되었습니다. 이미 입력된 내용은 유지됩니다.`n다시 자동입력하려면 견적서를 새로 읽어 주세요.
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
            ToolTip, 품목 입력은 완료했지만 개요 자동입력에 실패했습니다.
            SetTimer, SSOKExpenseClearTip, -5000
            return false
        }
        SSOK_ExpenseStage := "title"
        Sleep, 80
        if (!SSOK_Expense_WriteTitleOnly(target))
        {
            SSOK_Expense_Log("title-input-failed")
            ToolTip, 품목과 개요 입력은 완료했지만 제목 자동입력에 실패했습니다.
            SetTimer, SSOKExpenseClearTip, -5000
            return false
        }
        SSOK_Expense_Log("input-sequence-completed")
        return true
    }
    finally
    {
        ; 개요/제목 입력이 끝날 때까지 Busy를 유지해 중간 재실행을 차단합니다.
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
        calcText := firstItem . " 외 " . (itemCount - 1) . "건"
    else
        calcText := firstItem

    institution := SSOK_Expense_GetInstitutionName(target)
    if (institution = "")
        institution := "○○○"

    FormatTime, currentYear,, yyyy
    FormatTime, currentMonth,, M
    yearMonth := currentYear . "." . currentMonth . "."

    overviewText := ""
    overviewText .= "1. 관련: " . institution . "-○○○(" . yearMonth . ")(대호 없을시 생략가능)`r`n"
    overviewText .= "2. ○○○ 관련 물품을 아래와 같이 구입하고자 합니다.`r`n"
    overviewText .= "  가. 용도: `r`n"
    overviewText .= "  나. 소요예산: 금" . amountNumber . "원(금" . amountKorean . "원)`r`n"
    overviewText .= "  다. 산출내역: " . calcText . "`r`n"
    overviewText .= "`r`n"
    overviewText .= "붙임  지출품의서 1부.  끝."

    return SSOK_Expense_WriteDetailOnce(target, "overview", overviewText)
}

SSOK_Expense_WriteTitleOnly(target)
{
    if (!SSOK_Expense_Active(target))
        return false

    return SSOK_Expense_WriteDetailOnce(target, "title", "[품의] 000 운영 물품 구입")
}

; ------------------------------------------------------------
; 정수를 한국어 금액 읽기로 변환
; 예: 831770 -> 팔십삼만일천칠백칠십
; ------------------------------------------------------------
SSOK_Expense_NumberToKorean(value)
{
    value := Round(value)

    if (value = 0)
        return "영"

    digitNames := ["", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"]
    smallUnits := ["", "십", "백", "천"]
    bigUnits := ["", "만", "억", "조", "경"]

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

        ; 10, 100, 1000 단위의 '1'은 보통 생략
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
; 품의등록 화면 상단 기관명 추출
; 예: "품의등록 ( 도담중학교 / A00FAD... )" -> "도담중학교"
; ------------------------------------------------------------
SSOK_Expense_GetInstitutionName(topHwnd)
{
    ; --------------------------------------------------------
    ; 전체 MSAA 트리를 절대 검색하지 않습니다.
    ; 품의등록 제목이 있는 화면 상단 고정 영역 몇 점만 즉시 조회합니다.
    ; --------------------------------------------------------
    WinGetPos, wx, wy, ww, wh, ahk_id %topHwnd%

    if (ww = "" || wh = "" || ww <= 0 || wh <= 0)
        return ""

    ; 품의등록(기관명 / 문서번호) 영역 주변의 고정 상대 위치
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

        ; hit simple child / 객체 자체
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

        ; 전체 트리가 아니라 현재 지점의 부모만 최대 5단계 확인
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

    ; 예: 품의등록 ( 도담중학교 / A00FAD0102002001 )
    if RegExMatch(text, "품의등록\s*\(\s*([^/()]+?)\s*/", m)
        return Trim(m1)

    return ""
}

; ------------------------------------------------------------
; K-에듀파인 Nexacro Grid 행 수 확인 - MSAA
;
; 진단 결과:
;   0행 -> Name=[선택] 객체 0개
;   1행 -> Name=[선택] 객체 2개
;   2행 -> Name=[선택] 객체 4개
;
; 따라서 아직 입력하지 않은 빈 행에서는:
;   현재 행 수 = 정확히 "선택"인 MSAA 객체 수 / 2
;
; 객체 수가 홀수이면 화면 구조가 예상과 다르다고 보고 -1을 반환합니다.
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
; 부족한 행을 MSAA '행추가' PushButton으로 직접 생성
; 매 행마다 버튼 유효성을 확인하고 실행합니다. 실행 횟수는 실제 행 수와 다를 수 있습니다.
; 좌표 / ImageSearch / Tab 이동을 사용하지 않습니다.
; ------------------------------------------------------------
SSOK_Expense_AddRowsOneClick(target, count)
{
    global SSOK_ExpenseAddButtonCache, SSOK_ExpenseLastError
    global SSOK_ExpenseRowsAdded
    SSOK_ExpenseRowsAdded := 0
    Loop, %count%
    {
        if (!SSOK_Expense_Active(target))
            return false
        ; 예산 안내 등으로 버튼이 사라지면 재탐색/재클릭하지 않고 다음 Win+1을 기다립니다.
        if (!SSOK_Expense_MSAA_IsFixedAddButton(SSOK_ExpenseAddButtonCache))
        {
            SSOK_Expense_Log("row-button-unavailable-await-win1 completed=" . SSOK_ExpenseRowsAdded)
            return false
        }
        if (!SSOK_Expense_Active(target))
            return false
        if (!SSOK_Expense_MSAA_DoAction(SSOK_ExpenseAddButtonCache))
        {
            ; 예외가 나도 실제 클릭은 처리됐을 수 있으므로 무조건 재클릭하지 않습니다.
            SSOK_ExpenseLastError := "행추가 실행 결과를 확인할 수 없습니다."
            SSOK_Expense_Log("add-action-uncertain completed=" . SSOK_ExpenseRowsAdded)
            return false
        }
        SSOK_ExpenseRowsAdded++
        ToolTip, % "행추가 실행 중... " . SSOK_ExpenseRowsAdded . "/" . count
        Sleep, 140
    }
    SSOK_Expense_Log("add-actions-completed=" . SSOK_ExpenseRowsAdded)
    return SSOK_Expense_Active(target)
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
; 확정된 K-에듀파인 MSAA 내부 경로
;
; 2026-09 진단 결과:
; Root class = Chrome_RenderWidgetHostHWND
; Root name  = K-에듀파인 ... _WebDRM[85T]
;
; 고정 경로가 달라지면 표시 중인 접근성 트리에서 이름과 역할로 다시 찾습니다.
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
    ; 먼저 저장된 경로를 확인하고, 순서가 바뀌었으면 이름/역할로 재탐색합니다.
    oldPath := "/obj[1]/obj[1]/obj[1]/obj[1]/obj[3]/obj[1]/obj[3]/obj[1]/obj[1]/obj[1]/obj[55]/obj[1]/obj[1]/obj[1]/obj[1]/obj[11]/obj[1]/obj[3]/obj[1]/obj[6]/obj[1]/obj[1]/obj[1]/obj[8]"
    Loop, 3
    {
        if (!SSOK_Expense_Active(target))
            return false
        ToolTip, % "K-에듀파인 행추가 버튼 확인 중... (" . A_Index . "/3)"
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
            SSOK_ExpenseLastError := "K-에듀파인 접근성 화면을 읽지 못했습니다."
        ; 재부팅 직후 브라우저가 접근성 트리를 준비할 시간을 줍니다.
        Sleep, 600
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

; 현재 대상 창의 표시 중인 Chrome renderer root를 찾습니다.
; 전체 접근성 트리는 순회하지 않습니다.
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
        ; WebDRM 접미사는 세션에 따라 없어질 수 있으므로 필수 조건으로 쓰지 않습니다.
        if (InStr(name, "에듀파인") || (name = "" && InStr(windowTitle, "에듀파인")))
        {
            SSOK_ExpenseEdufineRootHwnd := hwnd
            return root
        }
    }
    return ""
}

; /obj[1]/obj[3]... 경로를 그대로 따라감.
; 각 단계에서 AccessibleChildren 한 번만 호출합니다.
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
; 현재 활성 Edge/K-에듀파인 창과 모든 자식 HWND의
; OBJID_CLIENT MSAA 트리를 AccessibleChildren()으로 순회합니다.
;
; mode="count" : Name이 정확히 "선택"인 객체 개수 계산
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
    if (name = "선택")
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

            if (cName = "선택")
                state.selectCount++
        }
        else if (item.kind = 2)
        {
            SSOK_Expense_MSAA_WalkCount(item.acc, depth + 1, state)
        }
    }
}

; ------------------------------------------------------------
; Name에 "행추가"가 포함되고 Role=PushButton(43)인 객체 자동검색
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

    if (InStr(name, "행추가") && role = 43)
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

            if (InStr(cName, "행추가") && cRole = 43)
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

        ; Nexacro가 이전 셀 값을 확정한 후 다음 셀로 이동하도록 여유를 둠
        SendInput, {Tab}
        Sleep, 70
    }
    return SSOK_Expense_Active(target)
}

SSOK_Expense_Unit(target)
{
    if (!SSOK_Expense_Active(target))
        return false

    SendInput, {Home}
    Sleep, 55
    SendInput, {Down}
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
        SendInput, {Text}개
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

    ; 긴 견적서에서 붙여넣기/셀 확정이 끝나기 전에 Tab이 들어가는 것을 방지
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
    name := RegExReplace(SSOK_Expense_MSAA_Get(acc, "Name", child), "[\s\x{00A0}:：*]", "")
    if (kind = "add")
        return role = 43 && RegExMatch(name, "^(행추가|행추가버튼)(\(.*\))?$")
    if (role != 42)
        return false
    if (kind = "title")
        return RegExMatch(name, "^(제목|품의제목|문서제목)(입력)?$")
    return RegExMatch(name, "^(개요|품의개요)(입력)?$")
}

SSOK_Expense_MSAA_FindNamed(root, kind, target := 0)
{
    state := {nodes:0, limit:30000, deadline:A_TickCount + 18000, hits:[], stopped:false, target:target, stack:[]}
    SSOK_Expense_MSAA_WalkNamed(root, 0, "", kind, state)
    n := state.hits.Length()
    ; 모든 후보를 읽기 전에 선택하면 뒤에 있는 품목 버튼을 놓치므로 끝까지 수집합니다.
    if (state.stopped)
    {
        if (kind = "add")
            SSOK_Expense_MSAA_ChooseItemButton(state.hits) ; diagnostics only; incomplete scans never click
        SSOK_Expense_Log("search-incomplete kind=" . kind . " nodes=" . state.nodes . " candidates=" . n)
        return {ok:false, retryable:true, nodes:state.nodes, reason:"화면 탐색이 중단되거나 제한 시간을 초과했습니다."}
    }
    if (kind = "add")
    {
        result := SSOK_Expense_MSAA_ChooseItemButton(state.hits)
        result.nodes := state.nodes
        return result
    }
    if (n != 1)
        return {ok:false, nodes:state.nodes, reason:(n ? "입력란을 하나로 구분하지 못했습니다." : "표시 중인 대상 요소를 찾지 못했습니다.")}
    return {ok:true, hit:state.hits[1], nodes:state.nodes}
}

SSOK_Expense_MSAA_WalkNamed(acc, depth, path, kind, state)
{
    if (state.stopped)
        return
    if (depth > 70 || state.nodes >= state.limit || A_TickCount > state.deadline
        || (state.target && !SSOK_Expense_Active(state.target)))
    {
        state.stopped := true
        return
    }
    state.nodes++
    status := SSOK_Expense_MSAA_Get(acc, "State", 0)
    if (status != "" && (status & 0x8000))
        return
    frame := {path:path, mask:0, hits:[]}
    state.stack.Push(frame)
    SSOK_Expense_MSAA_RecordNode(acc, 0, path, kind, state)
    ; 이름이 붙은 컨테이너도 자식을 조사합니다. 헤더나 동일 버튼의 노출이 있을 수 있습니다.
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
    ; 행추가와 같은 품의 폼을 기준으로 제목/개요의 상대 경로를 다시 계산합니다.
    ; 재로그인으로 상위 obj[55], obj[11] 번호가 바뀌어도 따라갑니다.
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
            ; 명시적인 다른 필드 이름이 있으면 상대 위치만 믿고 입력하지 않습니다.
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
    ; 포커스가 확인되지 않으면 Ctrl+A/Ctrl+V를 보내지 않습니다.
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
    name := RegExReplace(name, "[\s\x{00A0}:：*]", "")
    name := RegExReplace(name, "\((원|필수)\)$", "")

    ; 구형/신형 K-에듀파인 물품내역 머리글을 모두 인정합니다.
    if (name = "내용" || name = "품목명" || name = "품명")
        return 1
    if (name = "규격")
        return 2
    if (name = "수량")
        return 4
    if (name = "단위")
        return 8
    if (name = "예상단가" || name = "단가")
        return 16
    if (name = "예상금액" || name = "금액")
        return 32
    if (name = "조달수수료")
        return 64
    if (name = "용도(적요)" || name = "용도" || name = "적요")
        return 128
    return 0
}

SSOK_Expense_MSAA_IsItemHeaderMask(mask)
{
    ; 품명 + 수량 + 단가가 보이고, 규격/단위/금액 중 하나 이상이 함께 있으면
    ; 물품내역 표로 판단합니다. 조달수수료/용도는 존재 여부와 무관합니다.
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
    return {ok:false, retryable:!hits.Length(), reason:(hits.Length() ? "행추가 후보 중 품목 표의 버튼을 구분하지 못했습니다. 진단 기록에 후보 경로를 남겼습니다." : "표시 중인 행추가 버튼을 찾지 못했습니다.")}
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
    global SSOK_ConfigDir
    dir := SSOK_ConfigDir != "" ? SSOK_ConfigDir : A_ScriptDir
    return dir . "\ssok_expense_path.ini"
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
    ; 쓰기 권한이 없더라도 메모리 경로로 계속 동작합니다.
    ; 저장된 경로는 클릭 전에 현재 화면의 버튼 이름/역할/상태로 다시 검증합니다.
    IniRead, saved, %file%, ExpenseMSAA, RowPath, ERROR
    if (saved = path)
        return true
    IniWrite, %path%, %file%, ExpenseMSAA, RowPath
    return !ErrorLevel
}

SSOK_Expense_InputRows(target)
{
    global SSOK_ExpenseRows, SSOK_ExpenseMode
    saved := ClipboardAll
    ok := true
    try
    {
        for i, row in SSOK_ExpenseRows
        {
            ; 공통 6칸:
            ; 품명 -> 규격 -> 수량 -> 단위 -> 단가 -> 금액
            if (!SSOK_Expense_Field(row.name, target) || !SSOK_Expense_Tab(target)
                || !SSOK_Expense_Field(row.spec, target) || !SSOK_Expense_Tab(target)
                || !SSOK_Expense_Field(row.qty, target) || !SSOK_Expense_Tab(target)
                || !SSOK_Expense_Unit(target) || !SSOK_Expense_Tab(target)
                || !SSOK_Expense_Field(row.price, target) || !SSOK_Expense_Tab(target)
                || !SSOK_Expense_Field(row.amount, target))
            {
                ok := false
                break
            }

            if (SSOK_ExpenseMode = "cause")
            {
                ; 원인행위는 8칸 전체 사용:
                ; ... 금액 -> 조달수수료 -> 용도(적요)
                procurementFee := row.HasKey("procurementFee") ? row.procurementFee : ""
                purposeText := row.HasKey("purpose") ? row.purpose : ""

                if (!SSOK_Expense_Tab(target)
                    || !SSOK_Expense_Field(procurementFee, target)
                    || !SSOK_Expense_Tab(target)
                    || !SSOK_Expense_Field(purposeText, target))
                {
                    ok := false
                    break
                }

                ; 8번째 칸(용도)에서 다음 행 품명으로 1칸 이동
                if (i < SSOK_ExpenseRows.Length() && !SSOK_Expense_Tab(target))
                {
                    ok := false
                    break
                }
            }
            else
            {
                ; 품의 자동 등록 / 품목만 등록은 6칸 표 기준.
                ; 금액에서 다음 행 품명으로 1칸 이동.
                if (i < SSOK_ExpenseRows.Length() && !SSOK_Expense_Tab(target))
                {
                    ok := false
                    break
                }
            }

            if (i < SSOK_ExpenseRows.Length())
                Sleep, 85
        }

        return ok && SSOK_Expense_Active(target)
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
    ; 새 견적서 확인을 시작할 때만 1회 입력 기록을 초기화합니다.
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

    ; 작은 ToolTip 대신 큰 중앙 안내창을 2초만 표시
    SSOK_Expense_ShowModeNotice(SSOK_ExpenseMode)
}


; ------------------------------------------------------------
; 등록 방식 선택 후 안내
; - 큰 글씨
; - 가운데 정렬
; - 화면 중앙
; - 2초 후 자동 종료
; ------------------------------------------------------------
SSOK_Expense_ShowModeNotice(mode)
{
    Gui, SSOKExpenseModeNotice:Destroy
    Gui, SSOKExpenseModeNotice:+AlwaysOnTop -Caption +ToolWindow +Border
    Gui, SSOKExpenseModeNotice:Color, FFFBEA
    Gui, SSOKExpenseModeNotice:Margin, 18, 16

    if (mode = "items")
    {
        noticeText := "K-에듀파인에서 필요한 빈 행을 준비한 뒤`n"
        noticeText .= "입력을 시작할 행의 '품명' 칸을 클릭하고 Win+1을 누르세요.`n"
        noticeText .= "품명 · 규격 · 수량 · 단위 · 단가 · 금액 6칸을 입력합니다."
    }
    else if (mode = "cause")
    {
        noticeText := "K-에듀파인 원인행위 화면에서 필요한 빈 행을 준비한 뒤`n"
        noticeText .= "입력을 시작할 행의 '품명' 칸을 클릭하고 Win+1을 누르세요.`n"
        noticeText .= "품명 · 규격 · 수량 · 단위 · 단가 · 금액 · 조달수수료 · 용도를 입력합니다."
    }
    else
    {
        noticeText := "K-에듀파인 품의등록 화면으로 이동한 뒤`n"
        noticeText .= "품목 입력 테이블이 보이는 상태에서 Win+1을 눌러주세요."
    }

    Gui, SSOKExpenseModeNotice:Font, s14 Bold, Malgun Gothic
    Gui, SSOKExpenseModeNotice:Add, Text, w720 h100 +0x200 Center c222222, %noticeText%
    Gui, SSOKExpenseModeNotice:Show, AutoSize Center NoActivate

    SetTimer, SSOKExpenseModeNoticeClose, -2000
}

SSOKExpenseModeNoticeClose:
    Gui, SSOKExpenseModeNotice:Destroy
return

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
    if (!SSOK_Expense_MSAA_FocusField(field, target))
        return false
    ; 화면 값의 공백 여부와 무관하게 한번 시도한 개요/제목은 재입력하지 않습니다.
    ; 전부 삭제하거나 수정한 사용자 내용을 그대로 유지합니다.
    SSOK_ExpenseDetailSent[kind] := true
    ok := SSOK_Expense_PasteDetailText(target, value)
    SSOK_Expense_Log("detail-paste-once kind=" . kind . " completed=" . (ok ? 1 : 0))
    return ok
}

SSOK_Expense_PasteDetailText(target, value)
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
        ; 붙여넣은 뒤 입력란을 벗어나 화면의 편집값을 확정합니다. 재붙여넣기는 없습니다.
        SendInput, {Tab}
        Sleep, 70
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
    ; 기존에 관찰한 Nexacro 품목 표에서 '선택' 2개가 빈 행 1개입니다.
    ; 전체 페이지의 다른 표는 세지 않고 행추가가 속한 품목 영역만 확인합니다.
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
    state := {nodes:0, mask:0, selects:0, stopped:false, deadline:A_TickCount + 3000, target:target}
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
    state.nodes++
    status := SSOK_Expense_MSAA_Get(acc, "State", 0)
    if (status != "" && (status & 0x8000))
        return
    name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", 0))
    state.mask |= SSOK_Expense_MSAA_ItemHeaderBit(name)
    if (name = "선택")
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
            if (name = "선택")
                state.selects++
        }
    }
}

; ============================================================
; Win+2 스마트 원인행위 설정 지원
; ------------------------------------------------------------
; 기존 Tab 횟수 방식 대신 K-에듀파인 MSAA 화면을 실제로 읽어 처리합니다.
; - 검수여부      -> 아니오
; - 전자조달구매  -> 자체
; - 총원인행위액을 읽어 개요의 기존 소요예산 금액을 교체
;
; 이 파일 상단의 #2:: 핫키가 아래 함수를 직접 호출합니다.
; Win+2는 외부 연결 없이 이 파일 내부에서 바로 실행됩니다.
; ============================================================

SSOK_Expense_Win2Smart()
{
    global SSOK_ExpenseCancel

    KeyWait, LWin
    KeyWait, RWin
    SendInput, {LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}
    SSOK_ExpenseCancel := false
    Sleep, 80

    ; 1. 현재 활성화된 K-에듀파인 화면을 MSAA로 읽음
    target := WinExist("A")
    if (!target)
        return false

    root := SSOK_Expense_MSAA_GetEdufineRoot(target, true)
    if !IsObject(root)
    {
        MsgBox, 0x40030, 간편 원인행위 Win+2, K-에듀파인 화면을 읽지 못했습니다.`n원인행위 등록 화면을 맨 앞으로 연 뒤 다시 Win+2를 눌러 주세요.
        return false
    }

    ToolTip, Win+2 화면 확인 중...`n검수여부 / 전자조달구매
    scan := SSOK_Expense_Win2_Scan(root, target)

    if (!IsObject(scan) || scan.stopped)
    {
        ToolTip
        MsgBox, 0x40030, 간편 원인행위 Win+2, K-에듀파인 화면 항목을 끝까지 읽지 못했습니다.`n화면이 완전히 열린 뒤 다시 Win+2를 눌러 주세요.
        return false
    }

    ; 2. 검수여부 -> 아니오
    okInspect := SSOK_Expense_Win2_SetInspectionNo(target, scan.items)
    Sleep, 150

    ; 3. 전자조달구매 -> 자체
    ; 콤보 조작 과정에서 MSAA 트리가 바뀔 수 있으므로 기존 함수 내부 재탐색 사용
    okProcure := SSOK_Expense_Win2_SetProcurementOwn(target, scan.items)
    Sleep, 180

    ; 4. 변경된 화면을 다시 MSAA로 읽고 "총원인행위액" 금액을 찾음
    totalCauseAmount := ""
    root2 := SSOK_Expense_MSAA_GetEdufineRoot(target, true)

    if IsObject(root2)
    {
        scan2 := SSOK_Expense_Win2_Scan(root2, target)

        if (IsObject(scan2) && !scan2.stopped)
            totalCauseAmount := SSOK_Expense_Win2_ReadTotalCauseAmount(scan2.items)
    }

    ; 5. 개요에 사전 입력되어 있는 소요예산 금액을 총원인행위액으로 교체
    okOverviewAmount := false

    if (totalCauseAmount != "")
        okOverviewAmount := SSOK_Expense_Win2_ReplaceOverviewAmount(target, totalCauseAmount)

    ToolTip

    ; 6. 처리 결과를 약 3초 표시
    msg := "Win+2 처리 결과"
    msg .= "`n검수여부 → 아니오: " . (okInspect ? "완료" : "확인 필요")
    msg .= "`n전자조달구매 → 자체: " . (okProcure ? "완료" : "확인 필요")

    if (totalCauseAmount = "")
    {
        msg .= "`n총원인행위액 → 금액을 찾지 못함 / 확인 필요"
    }
    else
    {
        msg .= "`n총원인행위액 → " . SSOK_Expense_FormatNumber(totalCauseAmount) . "원"
        msg .= " / 개요 금액 입력: " . (okOverviewAmount ? "완료" : "확인 필요")
    }

    ToolTip, %msg%
    SetTimer, SSOKExpenseClearTip, -3000

    SSOK_Expense_Log("win2-total-cause inspect=" . (okInspect ? 1 : 0)
        . " procure=" . (okProcure ? 1 : 0)
        . " totalCauseFound=" . (totalCauseAmount != "" ? 1 : 0)
        . " overviewAmountSet=" . (okOverviewAmount ? 1 : 0))

    return okInspect || okProcure || okOverviewAmount
}

; ------------------------------------------------------------
; 화면의 "총원인행위액"을 MSAA에서 찾아 숫자만 반환
; 같은 객체의 Value/Name을 먼저 보고, 없으면 같은 행 오른쪽 값을 찾습니다.
; ------------------------------------------------------------
SSOK_Expense_Win2_ReadTotalCauseAmount(items)
{
    if !IsObject(items)
        return ""

    label := ""

    ; 1차: 총원인행위액 이름/값을 가진 객체 자체에서 금액 확인
    for _, node in items
    {
        n := SSOK_Expense_Win2_Normalize(node.name)
        v := SSOK_Expense_Win2_Normalize(node.value)

        if (!InStr(n, "총원인행위액") && !InStr(v, "총원인행위액"))
            continue

        if !IsObject(label)
            label := node

        amount := SSOK_Expense_Win2_ExtractNumericAmount(node.value)

        if (amount = "")
            amount := SSOK_Expense_Win2_ExtractNumericAmount(node.name)

        if (amount != "")
            return amount

        if (!IsObject(label) || (IsObject(node.rect) && !IsObject(label.rect)))
            label := node
    }

    ; 2차: 정확한 라벨 탐색
    if !IsObject(label)
        label := SSOK_Expense_Win2_FindLabel(items, ["총원인행위액", "총 원인행위액"])

    if !IsObject(label) || !IsObject(label.rect)
        return ""

    ; 3차: 라벨과 같은 행, 오른쪽에 있는 숫자/금액 객체 중 가장 가까운 것
    bestAmount := ""
    bestScore := 2147483647

    for _, node in items
    {
        if !IsObject(node.rect)
            continue

        dy := Abs(node.rect.cy - label.rect.cy)
        if (dy > 70)
            continue

        dx := node.rect.cx - label.rect.cx
        if (dx < 10)
            continue

        amount := SSOK_Expense_Win2_ExtractNumericAmount(node.value)

        if (amount = "")
            amount := SSOK_Expense_Win2_ExtractNumericAmount(node.name)

        if (amount = "")
            continue

        ; 같은 행 + 라벨 바로 오른쪽을 우선
        score := dy * 15 + Abs(dx - 180)

        if (score < bestScore)
        {
            bestScore := score
            bestAmount := amount
        }
    }

    return bestAmount
}

SSOK_Expense_Win2_ExtractNumericAmount(text)
{
    if (text = "")
        return ""

    ; 1,234,567원 / 1,234,567 / 1234567 모두 허용
    if RegExMatch(text, "([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{4,})\s*원?", m)
        return RegExReplace(m1, "[^0-9]", "")

    ; 소액도 허용하되 0은 제외
    if RegExMatch(text, "(?:^|[^0-9])([1-9][0-9]{0,2})\s*원(?:$|[^0-9])", m)
        return m1 + 0

    return ""
}

; ------------------------------------------------------------
; 개요의 사전입력된 "소요예산" 금액 부분만 총원인행위액으로 교체
; 개요의 나머지 문구는 그대로 유지합니다.
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

    if (currentText = "" || !InStr(currentText, "소요예산"))
        return false

    amountNumber := SSOK_Expense_FormatNumber(amount)
    amountKorean := SSOK_Expense_NumberToKorean(amount)
    newAmountText := "금" . amountNumber . "원(금" . amountKorean . "원)"

    ; 기존:
    ;   나. 소요예산: 금935,000원(금구십삼만오천원)
    ; 금액 부분만 교체하고 앞뒤 문구는 그대로 둡니다.
    pattern := "(소요예산\s*:\s*)금?\s*[0-9][0-9,]*\s*원(?:\s*\(금[^)\r\n]*원\))?"
    replacement := "$1" . newAmountText
    changedText := RegExReplace(currentText, pattern, replacement, replacedCount, 1)

    ; 화면 문구가 조금 다른 경우: 소요예산: 뒤의 한 줄만 교체
    if (replacedCount = 0)
    {
        pattern2 := "(소요예산\s*:\s*)[^\r\n]*"
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

        ; 가능한 경우 실제 반영값까지 확인
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


SSOK_Expense_Win2_Scan(root, target)
{
    state := {items:[], nodes:0, limit:26000, deadline:A_TickCount + 9000, target:target, stopped:false}
    SSOK_Expense_Win2_Walk(root, 0, state)
    return state
}

SSOK_Expense_Win2_Walk(acc, depth, state)
{
    if (state.stopped)
        return
    if (depth > 70 || state.nodes >= state.limit || A_TickCount > state.deadline
        || !WinActive("ahk_id " . state.target))
    {
        state.stopped := true
        return
    }

    state.nodes++
    status := SSOK_Expense_MSAA_Get(acc, "State", 0)
    if (status != "" && (status & 0x8000))
        return

    SSOK_Expense_Win2_Record(acc, 0, state)
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
                || !WinActive("ahk_id " . state.target))
            {
                state.stopped := true
                return
            }
            SSOK_Expense_Win2_Record(acc, item.id, state)
        }
    }
}

SSOK_Expense_Win2_Record(acc, child, state)
{
    name := Trim(SSOK_Expense_MSAA_Get(acc, "Name", child))
    value := Trim(SSOK_Expense_MSAA_Get(acc, "Value", child))
    role := SSOK_Expense_MSAA_Get(acc, "Role", child)
    status := SSOK_Expense_MSAA_Get(acc, "State", child)

    ; 텍스트가 없는 입력/콤보/라디오도 라벨 근접 탐색에 필요합니다.
    if (name = "" && value = "" && role != 42 && role != 43 && role != 44 && role != 45 && role != 46)
        return

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
    text := RegExReplace(text, "[\s\x{00A0}:：*·]", "")
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

    ; 화면에 실제 위치가 있는 텍스트 라벨을 우선합니다.
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

        ; 같은 행에서 라벨 오른쪽의 컨트롤을 가장 우선합니다.
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
    label := SSOK_Expense_Win2_FindLabel(items, ["검수여부", "검수 여부"])
    noNode := ""

    if IsObject(label)
        noNode := SSOK_Expense_Win2_FindNear(items, label, "45,44,43,42", ["아니오"], 80)

    if !IsObject(noNode)
    {
        hits := SSOK_Expense_Win2_FindExact(items, ["아니오"], "45,44,43")
        if (hits.Length() = 1)
            noNode := hits[1]
    }

    if !IsObject(noNode)
        return false

    ; MSAA checked 상태(0x10)이면 이미 아니오가 선택된 상태입니다.
    if (noNode.state != "" && (noNode.state & 0x10))
        return true

    return SSOK_Expense_Win2_ActivateNode(noNode, target)
}

SSOK_Expense_Win2_SetProcurementOwn(target, items)
{
    labelNames := ["전자조달구매", "전자도달구매"]
    label := SSOK_Expense_Win2_FindLabel(items, labelNames)
    combo := ""

    ; 라벨 자체가 ComboBox로 노출되는 경우
    hits := SSOK_Expense_Win2_FindExact(items, labelNames, "46")
    if (hits.Length())
        combo := hits[1]

    ; 라벨과 별도의 ComboBox인 경우
    if (!IsObject(combo) && IsObject(label))
        combo := SSOK_Expense_Win2_FindNear(items, label, "46", "", 90)

    ; 일부 Nexacro 화면은 ComboBox를 editable text(role 42)로 노출합니다.
    if (!IsObject(combo) && IsObject(label))
    {
        candidate := SSOK_Expense_Win2_FindNear(items, label, "42", "", 90)
        if (IsObject(candidate) && SSOK_Expense_Win2_Normalize(candidate.name) != SSOK_Expense_Win2_Normalize(label.name))
            combo := candidate
    }

    if !IsObject(combo)
        return false

    if (SSOK_Expense_Win2_Normalize(combo.value) = "자체"
        || SSOK_Expense_Win2_Normalize(combo.name) = "자체")
        return true

    ; 실제 전자조달구매 컨트롤을 찾아서 목록을 엽니다.
    if (!SSOK_Expense_Win2_ActivateNode(combo, target))
        return false
    Sleep, 260

    root := SSOK_Expense_MSAA_GetEdufineRoot(target, true)
    if !IsObject(root)
        return false
    scan := SSOK_Expense_Win2_Scan(root, target)
    if (!IsObject(scan) || scan.stopped)
        return false

    ownHits := SSOK_Expense_Win2_FindExact(scan.items, ["자체"])
    if (!ownHits.Length())
        return false

    ; 펼쳐진 목록에서 원래 콤보박스와 가장 가까운 '자체' 항목을 선택합니다.
    own := ""
    best := 2147483647
    for _, node in ownHits
    {
        if (!IsObject(node.rect))
            continue
        if (IsObject(combo.rect))
            score := Abs(node.rect.cx - combo.rect.cx) + Abs(node.rect.cy - combo.rect.cy)
        else
            score := 0
        if (score < best)
        {
            best := score
            own := node
        }
    }
    if (!IsObject(own))
        own := ownHits[1]

    return SSOK_Expense_Win2_ActivateNode(own, target)
}

SSOK_Expense_Win2_ReadOverviewAmount(target, items := "")
{
    ; Win+1에서 이미 검증한 개요 필드 탐색 로직을 우선 재사용합니다.
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

    ; 개요 필드 이름이 세션에 따라 다르게 노출되는 경우 전체 표시 텍스트에서 보조 탐색합니다.
    if IsObject(items)
    {
        for _, node in items
        {
            text := node.value != "" ? node.value : node.name
            if (!InStr(text, "소요예산") && !InStr(text, "금액"))
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

    if RegExMatch(text, "소요예산\s*[:：]?\s*금?\s*([0-9][0-9,]*)\s*원", m)
        return RegExReplace(m1, "[^0-9]", "")

    if RegExMatch(text, "금액\s*[:：]?\s*금?\s*([0-9][0-9,]*)\s*원", m)
        return RegExReplace(m1, "[^0-9]", "")

    ; 개요 안에 금액 표기가 하나뿐인 경우를 위한 최종 보조 패턴
    if RegExMatch(text, "금\s*([0-9][0-9,]*)\s*원", m)
        return RegExReplace(m1, "[^0-9]", "")

    return ""
}

SSOK_Expense_Win2_SetCauseAmount(target, items, amount)
{
    label := SSOK_Expense_Win2_FindLabel(items, ["원인행위액", "원인 행위액"])
    field := ""

    ; 원인행위액이라는 이름 자체를 가진 편집 컨트롤을 먼저 찾습니다.
    for _, node in items
    {
        n := SSOK_Expense_Win2_Normalize(node.name)
        if (!RegExMatch(n, "^원인행위액(입력)?$") || node.role != 42)
            continue
        if (SSOK_Expense_MSAA_Usable(node.acc, node.child, true))
        {
            field := node
            break
        }
    }

    ; 라벨 오른쪽의 편집 가능한 입력칸을 찾습니다.
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
; Win + 1 / Win + 3 K-에듀파인 보조 실행 루틴
; - 기존 ssok_tool.ahk에 있던 기능을 그대로 이동
; - Win+1 / Win+2 / Win+3 관련 기능을 expense 모듈에서 일괄 관리
; =========================================================
; =========================================================
; Win + 3 : K-에듀파인 사용자 지정 Tab 순서 실행
; ---------------------------------------------------------
; 순서: Tab 12 → Left 1 → Tab 7 → Space → Tab 1 → Space → Tab 16 → Down 1
; =========================================================
#If SSOK_Expense_HotkeyContext()
#3::
    Gosub, SSOK_Expense_DoWin3_KEdufine_TabSeq
return
#If

SSOK_Expense_HotkeyContext()
{
    return true
}


; =========================================================
; =========================================================
; 원인행위유형선택 확인 후 Win+2 뒷부분 자동 실행
; ---------------------------------------------------------
; 현재 비활성화: SSOK_EnableCauseTypeAutoAfter := 1 로 켜기 전까지 실행되지 않습니다.
; UIA/마우스 위치 판독은 사용하지 않습니다.
; 별도 선택창 제목이 잡히는 경우에만, 선택 후 창이 닫히면 Space 없이 Tab 10부터 실행
; =========================================================
; 원인행위유형선택 후 Enter/LButton 자동감시는 현재 비활성화 상태이므로
; 다른 모듈의 동일 핫키와 충돌하지 않도록 핫키 등록은 하지 않습니다.
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

SSOK_Expense_DoWin3_KEdufine_TabSeq:
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

    ToolTip, Win+1 K-에듀파인 사용자 지정 Tab 순서 실행 중...
    SetTimer, SSOK_Expense_Win1_TabSeq_ClearTip, -2500

    ; 요청 순서 그대로 실행
    ; Tab 10번 → ↓ 1번 → Tab 1번 → ↓ 4번 → Tab 2번 → Enter → 11 → Enter
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
    return InStr(SSOK_CauseTypeTitle, "원인행위유형선택")
}

SSOK_Expense_Win1_TabSeq_ClearTip:
    ToolTip
return
