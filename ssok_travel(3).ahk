#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
SetFormat, FloatFast, 0.1

; 트레이 및 기본 아이콘 설정 (SSOK.ico)
iconPath := A_ScriptDir . "\ssok.ico"
if (!FileExist(iconPath))
    iconPath := A_ScriptDir . "\SSOK.ico"
if (FileExist(iconPath))
    Menu, Tray, Icon, %iconPath%

global SSOK_Ini := A_ScriptDir . "\ssok.ini"
global SSOK_Travel_LastHtml := ""

; GUI 글로벌 변수 선언
global ST_Org, ST_Rank, ST_Name, ST_TravelCategory1, ST_TravelCategory2, ST_TravelCategory3
global ST_StartDate, ST_EndDate, ST_DaysText
global ST_Departure, ST_Destination, ST_Stopover
global ST_TransType1, ST_TransType2, ST_TransType3, ST_TransType4
global ST_FuelType, ST_TransitType, ST_CarReason, ST_LblCarReason
global ST_Distance, ST_FuelPrice, ST_Toll, ST_Parking
global ST_RailGo, ST_RailVia, ST_RailBack, ST_BusGo, ST_BusVia, ST_BusBack, ST_ShipGo, ST_ShipVia, ST_ShipBack, ST_AirGo, ST_AirVia, ST_AirBack, ST_TransitTotalText
global ST_MealOption, ST_MealCount, ST_MealActual, ST_LblMealDesc, ST_LblMealClosing, ST_LblMealWon, ST_LblMealDoc
global ST_LodgingAutoText, ST_LodgingActual, ST_LodgingInfoText
global ST_Total, ST_TotalSummary, ST_CarFareTotalText

; 동적 표시/숨김용 컨트롤 변수
global ST_LblFuel, ST_LblDist, ST_LblKm, ST_LblPrice, ST_LblWon1, ST_BtnRecalcCar, ST_BtnLookupCar
global ST_LblToll, ST_LblWon2, ST_LblPark, ST_LblWon3, ST_LblParkCap, ST_LblCarTotal
global ST_LblTransitType, ST_LblTransitGo, ST_LblWonGo, ST_LblTransitVia, ST_LblWonVia, ST_LblTransitBack, ST_LblWonBack, ST_LblTransitAir, ST_LblWonAir, ST_LblTransitTotal
global ST_DescGov, ST_DescCarpool

; HWND 변수 (IME 포커스 아웃 및 포맷팅 처리)
global hTravelGui, hRadioCar, hEditOrg, hEditDep, hEditDest, hEditStopover, hEditMealAct, hEditLodgingAct, hEditToll, hEditPark
global ST_LastFocusedEdit := ""

; 장소 선택 다이얼로그용 글로벌 변수
global ST_SelectedPlaceIdx := 0, ST_PlaceListView

; 자동 주행 및 지도 좌표 캐시 변수
global ST_DepLon := 0, ST_DepLat := 0, ST_DepName := ""
global ST_DestLon := 0, ST_DestLat := 0, ST_DestName := ""
global ST_ViaLon := 0, ST_ViaLat := 0, ST_ViaName := ""
global ST_RouteCoords := ""

; 포커스 이동(EN_KILLFOCUS) 및 마우스 클릭(WM_LBUTTONDOWN) 감지 메시지 등록
OnMessage(0x0111, "SSOK_Travel_WM_COMMAND")
OnMessage(0x0201, "SSOK_Travel_WM_LBUTTONDOWN")

SSOK_Travel_Show()
return

SSOKTravelGuiClose:
SSOKTravelGuiEscape:
    SSOK_Travel_AutoSave()
    Gui, SSOKTravel:Destroy
    return

SSOK_Travel_Show()
{
    global
    Gui, SSOKTravel:Destroy
    Gui, SSOKTravel:New, +Resize +MinSize880x530 +HwndhTravelGui, % "세종특별자치시교육청 여비정산 신청"
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Color, F8F9FA, FFFFFF
    Gui, SSOKTravel:Margin, 16, 10
    Gui, SSOKTravel:Font, s10 c212529, Malgun Gothic

    defaultOrg := SSOK_Travel_GetDefaultOrg()

    ; 새 여비신청서는 저장된 출장 구분과 관계없이 항상 일반출장으로 시작한다.
    ; 사용자가 이후 교육훈련 등으로 변경하면 그 변경값은 저장한다.
    savedCategory := "1"

    IniRead, savedRank, %SSOK_Ini%, Travel, Rank, 교사
    if (savedRank = "ERROR" || savedRank = "" || savedRank = "행정실장")
        savedRank := "교사"

    IniRead, savedName, %SSOK_Ini%, Travel, Name, %A_Space%
    if (savedName = "ERROR")
        savedName := ""

    IniRead, oldSavedOrg, %SSOK_Ini%, Travel, Org, %A_Space%
    IniRead, savedDep, %SSOK_Ini%, Travel, Departure, %defaultOrg%
    if (savedDep = "ERROR" || savedDep = "" || StrLen(savedDep) <= 1 || savedDep = oldSavedOrg)
        savedDep := defaultOrg
    ; 접두사 잘림(도담중학 vs 도담중학교) 자동 보정
    if (defaultOrg != "" && InStr(defaultOrg, savedDep) = 1 && StrLen(savedDep) < StrLen(defaultOrg))
        savedDep := defaultOrg

    ; 도착지는 이전 신청서의 값을 불러오지 않고 매번 빈칸으로 시작한다.
    ; 사용자가 새 도착지를 입력하고 Enter로 장소를 확정할 수 있다.
    savedDest := ""

    IniRead, savedStopover, %SSOK_Ini%, Travel, Stopover, %A_Space%
    if (savedStopover = "ERROR")
        savedStopover := ""

    IniRead, savedTransitVia, %SSOK_Ini%, Travel, TransitVia, 0
    if (savedTransitVia = "ERROR" || savedTransitVia = "")
        savedTransitVia := "0"

    IniRead, savedFuelType, %SSOK_Ini%, Travel, FuelType, 휘발유 (11.97 km/L)
    if (savedFuelType = "ERROR" || savedFuelType = "")
        savedFuelType := "휘발유 (11.97 km/L)"

    IniRead, savedTransitType, %SSOK_Ini%, Travel, TransitType, 기차
    if (savedTransitType = "ERROR" || savedTransitType = "" || InStr(savedTransitType, "버스"))
        savedTransitType := (InStr(savedTransitType, "버스") ? "버스" : "기차")
    if (InStr(savedTransitType, "기타"))
        savedTransitType := "기타"
    ; 새 여비신청서는 항상 대중교통(2)으로 시작한다.
    ; 이전 신청에서 자가용을 마지막으로 선택했더라도 이어받지 않는다.
    savedTransType := "2"

    ; 기본 날짜: 작성일 기준 5일 전, 당일 출장 (0박 1일)
    startDate := A_Now
    EnvAdd, startDate, -5, Days
    endDate := startDate
    FormatTime, startStr, %startDate%, yyyyMMdd
    FormatTime, endStr, %endDate%, yyyyMMdd

    IniRead, savedToll, %SSOK_Ini%, Travel, Toll, 0
    IniRead, savedParking, %SSOK_Ini%, Travel, Parking, 0
    IniRead, savedRailGo, %SSOK_Ini%, Travel, RailGo, 0
    IniRead, savedRailVia, %SSOK_Ini%, Travel, RailVia, 0
    IniRead, savedRailBack, %SSOK_Ini%, Travel, RailBack, 0
    IniRead, savedBusGo, %SSOK_Ini%, Travel, BusGo, 0
    IniRead, savedBusVia, %SSOK_Ini%, Travel, BusVia, 0
    IniRead, savedBusBack, %SSOK_Ini%, Travel, BusBack, 0
    IniRead, savedShipGo, %SSOK_Ini%, Travel, ShipGo, 0
    IniRead, savedShipVia, %SSOK_Ini%, Travel, ShipVia, 0
    IniRead, savedShipBack, %SSOK_Ini%, Travel, ShipBack, 0
    IniRead, savedAirGo, %SSOK_Ini%, Travel, AirGo, 0
    IniRead, savedAirVia, %SSOK_Ini%, Travel, AirVia, 0
    IniRead, savedAirBack, %SSOK_Ini%, Travel, AirBack, 0
    IniRead, savedMealActual, %SSOK_Ini%, Travel, MealActual, 0
    IniRead, savedLodgingActual, %SSOK_Ini%, Travel, LodgingActual, 0
    IniRead, savedCarReason, %SSOK_Ini%, Travel, CarReason, %A_Space%

    ; 천원 단위 콤마 포맷 적용
    savedToll := SSOK_Travel_Comma(savedToll)
    savedParking := SSOK_Travel_Comma(savedParking)
    savedRailGo := SSOK_Travel_Comma(savedRailGo)
    savedRailVia := SSOK_Travel_Comma(savedRailVia)
    savedRailBack := SSOK_Travel_Comma(savedRailBack)
    savedBusGo := SSOK_Travel_Comma(savedBusGo)
    savedBusVia := SSOK_Travel_Comma(savedBusVia)
    savedBusBack := SSOK_Travel_Comma(savedBusBack)
    savedShipGo := SSOK_Travel_Comma(savedShipGo)
    savedShipVia := SSOK_Travel_Comma(savedShipVia)
    savedShipBack := SSOK_Travel_Comma(savedShipBack)
    savedAirGo := SSOK_Travel_Comma(savedAirGo)
    savedAirVia := SSOK_Travel_Comma(savedAirVia)
    savedAirBack := SSOK_Travel_Comma(savedAirBack)
    savedMealActual := SSOK_Travel_Comma(savedMealActual)
    savedLodgingActual := SSOK_Travel_Comma(savedLodgingActual)

    savedFuelPrice := SSOK_Travel_GetCachedOrFetchFuelPrice(savedFuelType, SubStr(startStr, 1, 8))
    if (savedFuelPrice <= 0)
        savedFuelPrice := ""
    ; 2026.08.01 이전의 공공충전 단일단가(324.4원/kWh)를
    ; 현재 전기차 적용단가로 재사용하지 않는다.
    if (InStr(savedFuelType, "전기") && Abs((savedFuelPrice + 0) - 324.4) < 0.01)
        savedFuelPrice := ""

    ; ==============================================================================
    ; [출장 구분] - "1. 출장자 정보" 바로 위 우측 정렬, ~90% 크기 (s9)
    ; ==============================================================================
    chkCat1 := (savedCategory = "1" ? "Checked" : "")
    chkCat2 := (savedCategory = "2" ? "Checked" : "")
    chkCat3 := (savedCategory = "3" ? "Checked" : "")
    if (chkCat1 = "" && chkCat2 = "" && chkCat3 = "")
        chkCat1 := "Checked"

    Gui, SSOKTravel:Font, s9 Bold c6C757D, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x390 y7 w65 Right, % "출장 구분:"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Radio, x460 y5 w105 vST_TravelCategory1 %chkCat1% gSSOK_Travel_OnCategoryChange, % "일반출장"
    Gui, SSOKTravel:Add, Radio, x570 y5 w155 vST_TravelCategory2 %chkCat2% gSSOK_Travel_OnCategoryChange, % "교육훈련 (합숙·기숙사)"
    Gui, SSOKTravel:Add, Radio, x730 y5 w135 vST_TravelCategory3 %chkCat3% gSSOK_Travel_OnCategoryChange, % "교육훈련 (비합숙)"
    Gui, SSOKTravel:Font, s10 c212529, Malgun Gothic

    ; ==============================================================================
    ; [1] 출장자 정보 (폭 848, 높이 54)
    ; ==============================================================================
    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x16 y26 w848 h54, % " 1. 출장자 정보 "
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x32 y44 w45, % "소속:"
    Gui, SSOKTravel:Add, Edit, x78 y40 w220 vST_Org hwndhEditOrg gSSOK_Travel_OnOrgChange, %defaultOrg%
    Gui, SSOKTravel:Add, Text, x315 y44 w45, % "직급:"
    Gui, SSOKTravel:Add, DropDownList, x360 y40 w145 vST_Rank gSSOK_Travel_OnRankChange, % "교사|교감|교장|주무관|사무관|장학사|장학관|기타"
    Gui, SSOKTravel:Add, Text, x535 y44 w45, % "성명:"
    Gui, SSOKTravel:Add, Edit, x580 y40 w160 vST_Name gSSOK_Travel_AutoSave, %savedName%

    ; ==============================================================================
    ; [2] 출장 일정 및 경로 (폭 848, 높이 88)
    ; ==============================================================================
    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x16 y86 w848 h88, % " 2. 출장 일정 및 경로 "
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x32 y110 w55, % "출발일:"
    Gui, SSOKTravel:Add, DateTime, x90 y106 w130 vST_StartDate Choose%startStr% gSSOK_Travel_OnDateChange, yyyy-MM-dd
    Gui, SSOKTravel:Add, Text, x235 y110 w55, % "도착일:"
    Gui, SSOKTravel:Add, DateTime, x290 y106 w130 vST_EndDate Choose%endStr% gSSOK_Travel_OnDateChange, yyyy-MM-dd
    Gui, SSOKTravel:Add, Text, x440 y110 w65, % "출장일수:"
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x510 y110 w340 vST_DaysText, % "1일 (0박 1일)"
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic

    Gui, SSOKTravel:Add, Text, x32 y140 w50, % "출발지:"
    Gui, SSOKTravel:Add, Edit, x85 y136 w180 vST_Departure hwndhEditDep gSSOK_Travel_AutoSave, %savedDep%
    Gui, SSOKTravel:Add, Text, x275 y140 w50, % "도착지:"
    Gui, SSOKTravel:Add, Edit, x328 y136 w190 vST_Destination hwndhEditDest gSSOK_Travel_OnDestChange, %savedDest%
    Gui, SSOKTravel:Add, Text, x528 y140 w50, % "경유지:"
    Gui, SSOKTravel:Add, Edit, x580 y136 w180 vST_Stopover hwndhEditStopover gSSOK_Travel_AutoSave, %savedStopover%
    Gui, SSOKTravel:Add, Text, x765 y140 w75 cADB5BD, % "(선택입력)"

    Gui, SSOKTravel:Add, Button, Default x-20 y-20 w1 h1 gSSOK_Travel_OnEnter, % "Enter"

    ; ==============================================================================
    ; [3] 교통편 및 운임 (폭 848, 높이 156)
    ; ==============================================================================
    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x16 y180 w848 h180, % " 3. 교통편 및 운임 "
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic

    chk1 := (savedTransType = "1" ? "Checked" : "")
    chk2 := (savedTransType = "2" ? "Checked" : "")
    chk3 := (savedTransType = "3" ? "Checked" : "")
    chk4 := (savedTransType = "4" ? "Checked" : "")
    if (chk1 = "" && chk2 = "" && chk3 = "" && chk4 = "")
        chk2 := "Checked"

    Gui, SSOKTravel:Font, s10 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Radio, x32 y200 w110 vST_TransType2 %chk2% gSSOK_Travel_OnTransChange, % "대중교통"
    Gui, SSOKTravel:Add, Radio, x150 y200 w90 vST_TransType1 hwndhRadioCar %chk1% gSSOK_Travel_OnTransChange, % "자가용"
    Gui, SSOKTravel:Add, Radio, x250 y200 w155 vST_TransType3 %chk3% gSSOK_Travel_OnTransChange, % "관용차량·임차버스"
    Gui, SSOKTravel:Add, Radio, x415 y200 w195 vST_TransType4 %chk4% gSSOK_Travel_OnTransChange, % "기타 (타인차량 동승 외)"
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic

    ; 자가용 전용 컨트롤
    Gui, SSOKTravel:Add, Text, x32 y228 w40 vST_LblFuel, % "유종:"
    Gui, SSOKTravel:Add, DropDownList, x72 y224 w170 vST_FuelType gSSOK_Travel_OnFuelTypeChange, % "휘발유 (11.97 km/L)||경유 (12.52 km/L)|하이브리드 (15.37 km/L)|LPG (8.83 km/L)|전기 (5.22 km/kWh)|수소 (94.9 km/kg)"
    Gui, SSOKTravel:Add, Text, x252 y228 w35 vST_LblDist, % "거리:"
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Edit, x288 y224 w55 vST_Distance +ReadOnly, 0.0
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x346 y228 w25 vST_LblKm, % "km"
    Gui, SSOKTravel:Add, Text, x378 y228 w35 vST_LblPrice, % "단가:"
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Edit, x414 y224 w65 vST_FuelPrice gSSOK_Travel_OnFuelPriceChange, %savedFuelPrice%
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x482 y228 w40 vST_LblWon1, % "원/L"
    Gui, SSOKTravel:Add, Button, x540 y222 w140 h30 vST_BtnRecalcCar gSSOK_Travel_RecalculateCar, % "거리 / 유가 재산정"
    Gui, SSOKTravel:Add, Button, x685 y222 w140 h30 vST_BtnLookupCar gSSOK_Travel_OpenCarLookup, % "조회"

    Gui, SSOKTravel:Add, Text, x32 y262 w55 vST_LblToll, % "통행료:"
    Gui, SSOKTravel:Add, Edit, x90 y258 w80 vST_Toll hwndhEditToll gSSOK_Travel_Calc, %savedToll%
    Gui, SSOKTravel:Add, Text, x174 y262 w20 vST_LblWon2, % "원"
    Gui, SSOKTravel:Add, Text, x205 y262 w55 vST_LblPark, % "주차료:"
    Gui, SSOKTravel:Add, Edit, x260 y258 w80 vST_Parking hwndhEditPark gSSOK_Travel_Calc, %savedParking%
    Gui, SSOKTravel:Add, Text, x344 y262 w20 vST_LblWon3, % "원"
    Gui, SSOKTravel:Add, Text, x370 y262 w140 vST_LblParkCap cADB5BD, % "(1일 상한 10,000원)"
    Gui, SSOKTravel:Font, s10 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x520 y262 w75 vST_LblCarTotal, % "운임 소계:"
    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x598 y261 w235 vST_CarFareTotalText, % "0 원"
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic

    Gui, SSOKTravel:Add, Text, x32 y296 w75 vST_LblCarReason, % "신청사유:"
    carReasonList := "1. 출장경로가 매우 복잡･다양하여 대중교통을 사실상 이용할 수 없는 경우|2. 자가용을 이용함으로써 운임이 적게 소요되는 경우|3. 산간오지, 도서벽지 등 대중교통수단이 없어 부득이 자가용 이용|4. 하중이 무거운 수하물을 운송해야 하는 경우|5. 공무목적상 부득이한 심야시간대 이동 또는 긴급한 사유가 있는 경우|6. 기관장 인정사유( 학생 현장실습 및 취업지원을 위한 학생 동승시 )|7. 대중교통을 이용에 어려움이 있는 장애인 공무원"
    Gui, SSOKTravel:Add, DropDownList, x110 y292 w715 vST_CarReason gSSOK_Travel_OnCarReasonChange, %carReasonList%

    ; 대중교통: 철도/버스/선박/항공 × 가는편/경유지/오는편
    Gui, SSOKTravel:Add, Text, x32 y228 w80 h22 Center vST_TransitHeader, % "구분"
    Gui, SSOKTravel:Add, Text, x115 y228 w210 h22 Center vST_TransitGoHeader, % "가는편 운임"
    Gui, SSOKTravel:Add, Text, x335 y228 w210 h22 Center vST_TransitViaHeader, % "경유지 운임"
    Gui, SSOKTravel:Add, Text, x555 y228 w210 h22 Center vST_TransitBackHeader, % "오는편 운임"

    Gui, SSOKTravel:Add, Text, x32 y252 w80 h22 Center vST_LblRail, % "철도"
    Gui, SSOKTravel:Add, Edit, x115 y248 w165 h22 vST_RailGo gSSOK_Travel_Calc, %savedRailGo%
    Gui, SSOKTravel:Add, Edit, x335 y248 w165 h22 vST_RailVia gSSOK_Travel_Calc, %savedRailVia%
    Gui, SSOKTravel:Add, Edit, x555 y248 w165 h22 vST_RailBack gSSOK_Travel_Calc, %savedRailBack%

    Gui, SSOKTravel:Add, Text, x32 y278 w80 h22 Center vST_LblBus, % "버스"
    Gui, SSOKTravel:Add, Edit, x115 y274 w165 h22 vST_BusGo gSSOK_Travel_Calc, %savedBusGo%
    Gui, SSOKTravel:Add, Edit, x335 y274 w165 h22 vST_BusVia gSSOK_Travel_Calc, %savedBusVia%
    Gui, SSOKTravel:Add, Edit, x555 y274 w165 h22 vST_BusBack gSSOK_Travel_Calc, %savedBusBack%

    Gui, SSOKTravel:Add, Text, x32 y304 w80 h22 Center vST_LblShip, % "선박"
    Gui, SSOKTravel:Add, Edit, x115 y300 w165 h22 vST_ShipGo gSSOK_Travel_Calc, %savedShipGo%
    Gui, SSOKTravel:Add, Edit, x335 y300 w165 h22 vST_ShipVia gSSOK_Travel_Calc, %savedShipVia%
    Gui, SSOKTravel:Add, Edit, x555 y300 w165 h22 vST_ShipBack gSSOK_Travel_Calc, %savedShipBack%

    Gui, SSOKTravel:Add, Text, x32 y330 w80 h22 Center vST_LblAir, % "항공"
    Gui, SSOKTravel:Add, Edit, x115 y326 w165 h22 vST_AirGo gSSOK_Travel_Calc, %savedAirGo%
    Gui, SSOKTravel:Add, Edit, x335 y326 w165 h22 vST_AirVia gSSOK_Travel_Calc, %savedAirVia%
    Gui, SSOKTravel:Add, Edit, x555 y326 w165 h22 vST_AirBack gSSOK_Travel_Calc, %savedAirBack%

    Gui, SSOKTravel:Font, s10 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x32 y352 w120 vST_LblTransitTotal, % "대중교통 운임 소계:"
    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x155 y351 w660 vST_TransitTotalText, % "0 원"
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x32 y228 w790 vST_DescGov c0D6EFD, % "※ 관용차량·임차버스 이용: 운임 0원 / 일비 50%"
    Gui, SSOKTravel:Add, Text, x32 y228 w790 vST_DescCarpool c6C757D, % "※ 기타 (타인차량 동승 외): 운임 0원 (동행자 차량 이용 등에 따른 운임 미지급)"

    ; ==============================================================================
    ; [4] 식비 (폭 848, 높이 52) - 1줄 가로 배치
    ; ==============================================================================
    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x16 y370 w848 h52, % " 4. 식비 "
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x32 y388 w270 vST_LblMealDesc, % "식사를 무료로 제공 받은 경우를 제외한"
    Gui, SSOKTravel:Font, s9 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x302 y388 w135 vST_LblMealDescBold, % "실제 지출한 식사수"
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    ; 1~3일 출장: 0식~9식 중 선택
    Gui, SSOKTravel:Add, DropDownList, x440 y384 w65 vST_MealOption gSSOK_Travel_OnMealOptionChange, % "0식|1식|2식|3식"
    ; 4일 이상 출장: 식사수를 직접 입력
    Gui, SSOKTravel:Add, Edit, x440 y384 w65 vST_MealCount gSSOK_Travel_OnMealCountChange Number, 0
    Gui, SSOKTravel:Add, Text, x510 y388 w35 vST_LblMealClosing, % "(식)"
    Gui, SSOKTravel:Add, Text, x555 y388 w85 vST_LblMealActualLabel, % "실제소요액 ("
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Edit, x640 y384 w95 vST_MealActual hwndhEditMealAct gSSOK_Travel_OnMealActualChange ReadOnly, 0
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x740 y388 w35 vST_LblMealWon, % ")원"
    Gui, SSOKTravel:Add, Text, x770 y388 w85 vST_LblMealLimit cADB5BD, % "최대 0식"

    ; ==============================================================================
    ; [5] 숙박비 (폭 848, 높이 52) - 실제 숙박비 default 0 유지
    ; ==============================================================================
    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x16 y426 w848 h52, % " 5. 숙박비 "
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x32 y444 w50, % ""
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x85 y444 w435 vST_LodgingAutoText, % "해당없음 (당일 출장)"
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x525 y444 w75 vST_LodgingInfoText, % "실제소요액 ("
    Gui, SSOKTravel:Add, Edit, x605 y440 w100 vST_LodgingActual hwndhEditLodgingAct +Disabled gSSOK_Travel_Calc, %savedLodgingActual%
    Gui, SSOKTravel:Add, Text, x710 y444 w35, % ")원"

    ; ==============================================================================
    ; 하단 액션 바 (신청총액 + [📄 여비정산서 인쇄] + [초기화]) - [닫기] 버튼 완전 제거
    ; ==============================================================================
    Gui, SSOKTravel:Font, s12 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x24 y490 w125, % "정산 신청 총액:"
    Gui, SSOKTravel:Font, s16 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x150 y484 w390 vST_Total, % "0 원"
    Gui, SSOKTravel:Font, s9 Normal c6C757D, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x24 y516 w515 vST_TotalSummary, % "운임 0원 | 일비 0원 | 식비 0원 | 숙박비 0원"

    Gui, SSOKTravel:Font, s11 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Button, x550 y488 w190 h44 gSSOK_Travel_PrintHtml, % "📄 여비정산서 인쇄"
    Gui, SSOKTravel:Font, s10 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Button, x755 y488 w105 h44 gSSOK_Travel_Reset, % "초기화"

    ; UI 초기 갱신
    ; 신규 화면은 항상 일반출장 + 대중교통으로 시작
    GuiControl, SSOKTravel:, ST_TravelCategory1, 1
    GuiControl, SSOKTravel:, ST_TravelCategory2, 0
    GuiControl, SSOKTravel:, ST_TravelCategory3, 0
    GuiControl, SSOKTravel:, ST_TransType1, 0
    GuiControl, SSOKTravel:, ST_TransType2, 1
    GuiControl, SSOKTravel:, ST_TransType3, 0
    GuiControl, SSOKTravel:, ST_TransType4, 0
    ST_TransType1 := 0
    ST_TransType2 := 1
    ST_TransType3 := 0
    ST_TransType4 := 0
    if (Trim(savedDest) = "")
        GuiControl, SSOKTravel:Disable, ST_TransType1
    else
        GuiControl, SSOKTravel:Enable, ST_TransType1
    Gosub, SSOK_Travel_UpdateTransportUI
    Gosub, SSOK_Travel_UpdateCategoryUI
    Gosub, SSOK_Travel_UpdateMealUI
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc

    Gui, SSOKTravel:Show, w880 h550, % "세종특별자치시교육청 여비정산 신청"

    ; 창 좌측 상단 아이콘을 SSOK.ico로 적용
    iconFile := A_ScriptDir . "\ssok.ico"
    if (!FileExist(iconFile))
        iconFile := A_ScriptDir . "\SSOK.ico"
    if (FileExist(iconFile) && hTravelGui)
    {
        hIconSm := DllCall("LoadImage", "Ptr", 0, "Str", iconFile, "UInt", 1, "Int", 16, "Int", 16, "UInt", 0x00000010, "Ptr")
        hIconLg := DllCall("LoadImage", "Ptr", 0, "Str", iconFile, "UInt", 1, "Int", 32, "Int", 32, "UInt", 0x00000010, "Ptr")
        if (hIconSm)
            SendMessage, 0x0080, 0, hIconSm,, ahk_id %hTravelGui% ; WM_SETICON, ICON_SMALL
        if (hIconLg)
            SendMessage, 0x0080, 1, hIconLg,, ahk_id %hTravelGui% ; WM_SETICON, ICON_BIG
    }
}

; 윈도우 컨트롤 메시지 후킹 (포커스 아웃 시 한글 IME 누락 방지 및 천원 단위 콤마 자동 포맷)
SSOK_Travel_WM_COMMAND(wParam, lParam, msg, hwnd)
{
    global hEditOrg, hEditDep, hEditDest, hEditStopover, hEditMealAct, hEditLodgingAct, hEditToll, hEditPark, SSOK_Ini, ST_LastFocusedEdit
    static lastDestQuery := ""
    code := wParam >> 16
    ; EN_SETFOCUS = 0x0100
    if (code = 0x0100)
    {
        if (lParam = hEditDep)
            ST_LastFocusedEdit := "ST_Departure"
        else if (lParam = hEditDest)
            ST_LastFocusedEdit := "ST_Destination"
        else if (lParam = hEditStopover)
            ST_LastFocusedEdit := "ST_Stopover"
        else if (lParam = hEditOrg)
            ST_LastFocusedEdit := "ST_Org"
    }
    ; EN_KILLFOCUS = 0x0200
    else if (code = 0x0200)
    {
        if (lParam = hEditOrg)
        {
            ControlGetText, curOrg, , ahk_id %hEditOrg%
            ControlGetText, curDep, , ahk_id %hEditDep%
            if (curOrg != "" && (curDep = "" || InStr(curOrg, curDep) = 1))
            {
                GuiControl, SSOKTravel:, ST_Departure, %curOrg%
                IniWrite, %curOrg%, %SSOK_Ini%, Travel, Departure
            }
        }
        else if (lParam = hEditDest)
        {
            ControlGetText, curDest, , ahk_id %hEditDest%
            if (curDest != "" && curDest != lastDestQuery && StrLen(curDest) >= 2)
            {
                lastDestQuery := curDest
                SetTimer, SSOK_Travel_DelayedDestResolve, -300
            }
        }
        else if (lParam = hEditMealAct)
        {
            ControlGetText, val, , ahk_id %hEditMealAct%
            fVal := SSOK_Travel_Floor10(val)
            GuiControl, SSOKTravel:, ST_MealActual, % SSOK_Travel_Comma(fVal)
        }
        else if (lParam = hEditLodgingAct)
        {
            ControlGetText, val, , ahk_id %hEditLodgingAct%
            fVal := SSOK_Travel_Floor10(val)
            GuiControl, SSOKTravel:, ST_LodgingActual, % SSOK_Travel_Comma(fVal)
        }
        else if (lParam = hEditToll)
        {
            ControlGetText, val, , ahk_id %hEditToll%
            fVal := SSOK_Travel_Floor10(val)
            GuiControl, SSOKTravel:, ST_Toll, % SSOK_Travel_Comma(fVal)
        }
        else if (lParam = hEditPark)
        {
            ControlGetText, val, , ahk_id %hEditPark%
            fVal := SSOK_Travel_Floor10(val)
            GuiControl, SSOKTravel:, ST_Parking, % SSOK_Travel_Comma(fVal)
        }
    }
}

; 마우스 좌클릭 감지 (도착지 미입력 상태에서 비활성화된 자가용 클릭 시 안내 툴팁 표시 및 도착지 포커스 이동)
SSOK_Travel_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
    global hTravelGui, hRadioCar, ST_Destination
    if (hwnd = hRadioCar)
    {
        GuiControlGet, curDest, SSOKTravel:, ST_Destination
        if (Trim(curDest) = "")
        {
            ToolTip, % "도착지를 먼저 입력해 주세요. (도착지 입력 후 자가용 선택 가능)"
            SetTimer, SSOK_Travel_RemoveToolTip, -2500
            GuiControl, SSOKTravel:Focus, ST_Destination
            return 0
        }
    }
    else if (hwnd = hTravelGui)
    {
        x := lParam & 0xFFFF
        y := (lParam >> 16) & 0xFFFF
        ; 자가용 라디오 버튼 위치: x150 y200 w90 h25 부근
        if (x >= 145 && x <= 245 && y >= 195 && y <= 228)
        {
            GuiControlGet, curDest, SSOKTravel:, ST_Destination
            if (Trim(curDest) = "")
            {
                ToolTip, % "도착지를 먼저 입력해 주세요. (도착지 입력 후 자가용 선택 가능)"
                SetTimer, SSOK_Travel_RemoveToolTip, -2500
                GuiControl, SSOKTravel:Focus, ST_Destination
            }
        }
    }
}

SSOK_Travel_AutoSave()
{
    global SSOK_Ini, ST_Rank, ST_Name, ST_Departure, ST_Destination, ST_Stopover, ST_FuelType, ST_TransitType, ST_TransType1, ST_TransType2, ST_TransType3, ST_TransType4
    global ST_Toll, ST_Parking, ST_RailGo, ST_RailVia, ST_RailBack, ST_BusGo, ST_BusVia, ST_BusBack, ST_ShipGo, ST_ShipVia, ST_ShipBack, ST_AirGo, ST_AirVia, ST_AirBack, ST_MealActual, ST_LodgingActual, ST_CarReason
    if (SSOK_Ini = "")
        return
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    ; 소속은 ssok.ini 기본 조직 정보를 직접 사용하므로 별도 Travel Org 저장은 제외
    IniWrite, %ST_Rank%, %SSOK_Ini%, Travel, Rank
    IniWrite, %ST_Name%, %SSOK_Ini%, Travel, Name
    IniWrite, %ST_Departure%, %SSOK_Ini%, Travel, Departure
    IniWrite, %ST_Destination%, %SSOK_Ini%, Travel, Destination
    IniWrite, %ST_Stopover%, %SSOK_Ini%, Travel, Stopover
    IniWrite, %ST_FuelType%, %SSOK_Ini%, Travel, FuelType
    ; 대중교통은 4종 독립 입력으로 ST_TransitType 저장을 사용하지 않음

    selCat := (ST_TravelCategory1 ? "1" : (ST_TravelCategory2 ? "2" : "3"))
    IniWrite, %selCat%, %SSOK_Ini%, Travel, Category

    selType := (ST_TransType1 ? "1" : (ST_TransType2 ? "2" : (ST_TransType3 ? "3" : "4")))
    IniWrite, %selType%, %SSOK_Ini%, Travel, TransType

    IniWrite, % SSOK_Travel_Number(ST_Toll), %SSOK_Ini%, Travel, Toll
    IniWrite, % SSOK_Travel_Number(ST_Parking), %SSOK_Ini%, Travel, Parking
    IniWrite, % SSOK_Travel_Number(ST_RailGo), %SSOK_Ini%, Travel, RailGo
    IniWrite, % SSOK_Travel_Number(ST_RailVia), %SSOK_Ini%, Travel, RailVia
    IniWrite, % SSOK_Travel_Number(ST_RailBack), %SSOK_Ini%, Travel, RailBack
    IniWrite, % SSOK_Travel_Number(ST_BusGo), %SSOK_Ini%, Travel, BusGo
    IniWrite, % SSOK_Travel_Number(ST_BusVia), %SSOK_Ini%, Travel, BusVia
    IniWrite, % SSOK_Travel_Number(ST_BusBack), %SSOK_Ini%, Travel, BusBack
    IniWrite, % SSOK_Travel_Number(ST_ShipGo), %SSOK_Ini%, Travel, ShipGo
    IniWrite, % SSOK_Travel_Number(ST_ShipVia), %SSOK_Ini%, Travel, ShipVia
    IniWrite, % SSOK_Travel_Number(ST_ShipBack), %SSOK_Ini%, Travel, ShipBack
    IniWrite, % SSOK_Travel_Number(ST_AirGo), %SSOK_Ini%, Travel, AirGo
    IniWrite, % SSOK_Travel_Number(ST_AirVia), %SSOK_Ini%, Travel, AirVia
    IniWrite, % SSOK_Travel_Number(ST_AirBack), %SSOK_Ini%, Travel, AirBack
    IniWrite, % SSOK_Travel_Number(ST_MealActual), %SSOK_Ini%, Travel, MealActual
    IniWrite, % SSOK_Travel_Number(ST_LodgingActual), %SSOK_Ini%, Travel, LodgingActual
    IniWrite, %ST_CarReason%, %SSOK_Ini%, Travel, CarReason
    Gosub, SSOK_Travel_Calc
}

SSOK_Travel_GetDefaultOrg()
{
    global SSOK_Ini
    fn := Func("SSOK_GetOrgName")
    if (fn)
    {
        org := fn.Call()
        org := Trim(org)
        if (org != "" && org != "ERROR")
            return org
    }
    if (SSOK_Ini != "")
    {
        IniRead, org, %SSOK_Ini%, MajorTodos, OrgName, %A_Space%
        org := Trim(org)
        if (org != "" && org != "ERROR")
            return org
        IniRead, baseOrg, %SSOK_Ini%, Settings, SchoolName, %A_Space%
        baseOrg := Trim(baseOrg)
        if (baseOrg != "" && baseOrg != "ERROR")
            return baseOrg
    }
    return "으뜸초등학교"
}

; 소속 변경 이벤트 핸들러 (출장자가 소속 입력/수정 시 출발지 실시간 동기화)
SSOK_Travel_OnOrgChange:
    Gui, SSOKTravel:Default
    GuiControlGet, curOrg, SSOKTravel:, ST_Org
    GuiControl, SSOKTravel:, ST_Departure, %curOrg%
    SSOK_Travel_AutoSave()
    Gosub, SSOK_Travel_Calc
    return

; 도착지 변경 시 자동 저장, 자가용 선택 활성화/비활성화 및 교육훈련 키워드 자동 감지
SSOK_Travel_OnDestChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    SSOK_Travel_AutoSave()
    if (Trim(ST_Destination) = "")
    {
        GuiControl, SSOKTravel:Disable, ST_TransType1
        if (ST_TransType1)
        {
            GuiControl, SSOKTravel:, ST_TransType1, 0
            GuiControl, SSOKTravel:, ST_TransType2, 1
            ST_TransType1 := 0, ST_TransType2 := 1
            Gosub, SSOK_Travel_OnTransChange
        }
    }
    else
    {
        GuiControl, SSOKTravel:Enable, ST_TransType1
    }
    Gosub, SSOK_Travel_CheckAutoCategory
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc
    return

; 도착지 포커스 아웃 시 좌표 백그라운드 확인 (모달 창 띄우지 않음)
SSOK_Travel_DelayedDestResolve:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (ST_Destination = "" || StrLen(ST_Destination) < 2)
        return
    outLon := 0, outLat := 0, outName := ""
    if (SSOK_Travel_GetCoords(ST_Destination, outLon, outLat, outName))
    {
        ST_DestLon := outLon, ST_DestLat := outLat, ST_DestName := outName
    }
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc
    return

; 도착지 키워드(교육원, 연수원, 훈련원 등) 기반 교육훈련 자동 전환
SSOK_Travel_CheckAutoCategory:
    Gui, SSOKTravel:Default
    GuiControlGet, curDest, SSOKTravel:, ST_Destination
    if (curDest = "")
        return

    isTraining := false
    keywords := ["교육원", "연수원", "훈련원", "인재개발원", "연수"]
    for idx, kw in keywords
    {
        if (InStr(curDest, kw))
        {
            isTraining := true
            break
        }
    }

    if (isTraining)
    {
        GuiControlGet, sDate, SSOKTravel:, ST_StartDate
        GuiControlGet, eDate, SSOKTravel:, ST_EndDate
        sD := SubStr(sDate, 1, 8)
        eD := SubStr(eDate, 1, 8)
        diffD := SSOK_Travel_DateDiffDays(sD, eD)
        days := diffD + 1
        if (days <= 1)
        {
            ; 당일이면 비합숙
            GuiControl, SSOKTravel:, ST_TravelCategory1, 0
            GuiControl, SSOKTravel:, ST_TravelCategory2, 0
            GuiControl, SSOKTravel:, ST_TravelCategory3, 1
        }
        else
        {
            ; 2일 이상이면 합숙·기숙사
            GuiControl, SSOKTravel:, ST_TravelCategory1, 0
            GuiControl, SSOKTravel:, ST_TravelCategory2, 1
            GuiControl, SSOKTravel:, ST_TravelCategory3, 0
        }
        Gosub, SSOK_Travel_OnCategoryChange
    }
    return

; 출장 구분 라디오 변경 핸들러
SSOK_Travel_OnCategoryChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    selCat := (ST_TravelCategory1 ? "1" : (ST_TravelCategory2 ? "2" : "3"))
    IniWrite, %selCat%, %SSOK_Ini%, Travel, Category
    Gosub, SSOK_Travel_UpdateCategoryUI
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_UpdateCategoryUI:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (ST_TravelCategory1 || ST_TravelCategory3) ; 일반출장 또는 교육훈련(비합숙)
    {
        GuiControl, Hide, ST_LblMealClosing
        GuiControl, Show, ST_LblMealDesc
        GuiControl, Show, ST_LblMealDescBold
        GuiControl, Show, ST_LblMealActualLabel
        GuiControl, Show, ST_MealActual
        GuiControl, Show, ST_LblMealWon
        GuiControl, Show, ST_LblMealLimit
        GuiControl, SSOKTravel:, ST_LblMealDesc, % "식사를 무료로 제공받은 경우를 제외한"
        GuiControl, Move, ST_LblMealDesc, x32 y388 w270 h20
        GuiControl, Move, ST_MealActual, x640 y384 w95 h23
        GuiControl, Move, ST_LblMealWon, x740 y388 w35 h20
        ; 날짜에 따라 1~3일은 선택형, 4일 이상은 직접입력형으로 전환한다.
        Gosub, SSOK_Travel_UpdateMealUI
    }
    else ; 교육훈련 합숙(2)
    {
        GuiControl, Hide, ST_MealOption
        GuiControl, Hide, ST_MealCount
        GuiControl, Hide, ST_LblMealClosing
        GuiControl, Hide, ST_LblMealDescBold
        GuiControl, Hide, ST_LblMealLimit
        GuiControl, Hide, ST_LblMealActualLabel
        if (ST_TravelCategory2)
        {
            GuiControl, Show, ST_LblMealDesc
            GuiControl, Hide, ST_LblMealDescBold
            GuiControl, Hide, ST_LblMealActualLabel
            GuiControl, Hide, ST_LblMealLimit
            GuiControl, Hide, ST_LblMealClosing
            GuiControl, SSOKTravel:, ST_LblMealDesc, % "교육훈련기관이 청구하는 금액 또는 구내 식당 가격"
            GuiControl, Move, ST_LblMealDesc, x32 y388 w500 h20
            GuiControl, Move, ST_MealActual, x540 y384 w95 h23
            GuiControl, Move, ST_LblMealWon, x640 y388 w25 h20
            GuiControl, Show, ST_MealActual
            GuiControl, -ReadOnly, ST_MealActual
            GuiControl, Show, ST_LblMealWon
        }
        else
        {
            GuiControl, Show, ST_LblMealDesc
            GuiControl, Hide, ST_LblMealDescBold
            GuiControl, Hide, ST_LblMealActualLabel
            GuiControl, Hide, ST_LblMealLimit
            GuiControl, Hide, ST_LblMealClosing
            GuiControl, SSOKTravel:, ST_LblMealDesc, % "식사를 무료로 제공받은 경우를 제외한 실제 지출한 식사수"
            GuiControl, Move, ST_LblMealDesc, x32 y388 w270 h20
            GuiControl, Move, ST_MealActual, x640 y384 w95 h23
            GuiControl, Move, ST_LblMealWon, x740 y388 w35 h20
            Gosub, SSOK_Travel_UpdateMealUI
        }
    }
    return

SSOK_Travel_OnMealActualChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (!ST_TravelCategory1)
    {
        rawVal := SSOK_Travel_Number(ST_MealActual)
        IniWrite, %rawVal%, %SSOK_Ini%, Travel, MealActual
        Gosub, SSOK_Travel_Calc
    }
    return

SSOK_Travel_OnRankChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    IniWrite, %ST_Rank%, %SSOK_Ini%, Travel, Rank
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnFuelPriceChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnEnter:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    ; 현재 포커스된 컨트롤 식별 (변수명)
    GuiControlGet, focusedVar, SSOKTravel:FocusV

    ; 성명 입력칸에서 Enter를 눌러도 장소검색을 실행하지 않음
    if (focusedVar = "ST_Name")
        return

    target := ""
    if (focusedVar = "ST_Departure" || ST_LastFocusedEdit = "ST_Departure")
        target := "ST_Departure"
    else if (focusedVar = "ST_Stopover" || ST_LastFocusedEdit = "ST_Stopover")
        target := "ST_Stopover"
    else if (focusedVar = "ST_Destination" || ST_LastFocusedEdit = "ST_Destination")
        target := "ST_Destination"
    else
    {
        ; 포커스 식별이 애매한 경우
        if (ST_Destination != "" && (ST_DestLon = 0 || ST_DestName != ST_Destination))
            target := "ST_Destination"
        else if (ST_Stopover != "" && (ST_ViaLon = 0 || ST_ViaName != ST_Stopover))
            target := "ST_Stopover"
        else if (ST_Departure != "" && (ST_DepLon = 0 || ST_DepName != ST_Departure))
            target := "ST_Departure"
        else
            target := "ST_Destination"
    }

    if (target = "ST_Departure")
    {
        if (ST_Departure != "")
        {
            ToolTip, % "출발지 장소 확인 중..."
            outLon := 0, outLat := 0, outName := ""
            if (SSOK_Travel_ResolvePlace(ST_Departure, outLon, outLat, outName, "출발지 검색 결과 선택 및 확인"))
            {
                ST_DepLon := outLon, ST_DepLat := outLat, ST_DepName := outName
                ST_Departure := outName
                GuiControl, SSOKTravel:, ST_Departure, %outName%
                IniWrite, %outName%, %SSOK_Ini%, Travel, Departure
                SSOK_Travel_AutoUpdateDistance()
            }
            SetTimer, SSOK_Travel_RemoveToolTip, -2000
        }
    }
    else if (target = "ST_Stopover")
    {
        if (ST_Stopover != "")
        {
            ToolTip, % "경유지 장소 확인 중..."
            outLon := 0, outLat := 0, outName := ""
            if (SSOK_Travel_ResolvePlace(ST_Stopover, outLon, outLat, outName, "경유지 검색 결과 선택 및 확인"))
            {
                ST_ViaLon := outLon, ST_ViaLat := outLat, ST_ViaName := outName
                ST_Stopover := outName
                GuiControl, SSOKTravel:, ST_Stopover, %outName%
                IniWrite, %outName%, %SSOK_Ini%, Travel, Stopover
                SSOK_Travel_AutoUpdateDistance()
            }
            SetTimer, SSOK_Travel_RemoveToolTip, -2000
        }
    }
    else if (target = "ST_Destination")
    {
        if (ST_Destination != "")
        {
            ToolTip, % "도착지 장소 확인 중..."
            outLon := 0, outLat := 0, outName := ""
            if (SSOK_Travel_ResolvePlace(ST_Destination, outLon, outLat, outName, "도착지 검색 결과 선택 및 확인"))
            {
                ST_DestLon := outLon, ST_DestLat := outLat, ST_DestName := outName
                ST_Destination := outName
                GuiControl, SSOKTravel:, ST_Destination, %outName%
                GuiControl, SSOKTravel:Enable, ST_TransType1
                IniWrite, %outName%, %SSOK_Ini%, Travel, Destination
                ; 도착지를 장소검색으로 확정한 뒤에는 대중교통을 자동 선택
                ; (경유지가 있어도 동일하게 대중교통으로 처리)
                GuiControl, SSOKTravel:, ST_TransType2, 1
                GuiControl, SSOKTravel:, ST_TransType1, 0
                GuiControl, SSOKTravel:, ST_TransType3, 0
                GuiControl, SSOKTravel:, ST_TransType4, 0
                ST_TransType2 := 1, ST_TransType1 := 0, ST_TransType3 := 0, ST_TransType4 := 0
                Gosub, SSOK_Travel_OnTransChange
                Gosub, SSOK_Travel_CheckAutoCategory
                Gosub, SSOK_Travel_UpdateLodgingInfo
                SSOK_Travel_AutoUpdateDistance()
            }
            SetTimer, SSOK_Travel_RemoveToolTip, -2000
        }
    }
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnTransChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (ST_TransType1 && Trim(ST_Destination) = "")
    {
        ToolTip, % "도착지를 먼저 입력해 주세요. (도착지 입력 후 자가용 선택 가능)"
        SetTimer, SSOK_Travel_RemoveToolTip, -2500
        GuiControl, SSOKTravel:, ST_TransType1, 0
        GuiControl, SSOKTravel:, ST_TransType2, 1
        GuiControl, SSOKTravel:Disable, ST_TransType1
        ST_TransType1 := 0, ST_TransType2 := 1
        selType := "2"
        IniWrite, %selType%, %SSOK_Ini%, Travel, TransType
        Gosub, SSOK_Travel_UpdateTransportUI
        Gosub, SSOK_Travel_Calc
        GuiControl, SSOKTravel:Focus, ST_Destination
        return
    }
    selType := (ST_TransType1 ? "1" : (ST_TransType2 ? "2" : (ST_TransType3 ? "3" : "4")))
    IniWrite, %selType%, %SSOK_Ini%, Travel, TransType
    Gosub, SSOK_Travel_UpdateTransportUI

    ; 자가용 선택 시 이미 확정된 장소 좌표로만 거리/단가를 자동 반영한다.
    ; 도착지를 다시 검색하지 않는다.
    if (ST_TransType1)
    {
        if (ST_Departure != "" && ST_Destination != "" && ST_DepLon != 0 && ST_DestLon != 0)
            SSOK_Travel_AutoUpdateDistance()
        else
        {
            ToolTip, % "도착지를 먼저 입력하고 Enter로 장소를 확정해 주세요."
            SetTimer, SSOK_Travel_RemoveToolTip, -2500
        }
    }

    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_UpdateTransportUI:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    ; 먼저 대중교통 관련 컨트롤을 전부 숨긴다.
    ; 자가용/관용차량·임차버스/기타에서는 철도·버스·선박·항공 입력칸이 보이지 않는다.
    GuiControl, Hide, ST_TransitHeader
    GuiControl, Hide, ST_TransitGoHeader
    GuiControl, Hide, ST_TransitViaHeader
    GuiControl, Hide, ST_TransitBackHeader
    GuiControl, Hide, ST_LblRail
    GuiControl, Hide, ST_RailGo
    GuiControl, Hide, ST_RailVia
    GuiControl, Hide, ST_RailBack
    GuiControl, Hide, ST_LblBus
    GuiControl, Hide, ST_BusGo
    GuiControl, Hide, ST_BusVia
    GuiControl, Hide, ST_BusBack
    GuiControl, Hide, ST_LblShip
    GuiControl, Hide, ST_ShipGo
    GuiControl, Hide, ST_ShipVia
    GuiControl, Hide, ST_ShipBack
    GuiControl, Hide, ST_LblAir
    GuiControl, Hide, ST_AirGo
    GuiControl, Hide, ST_AirVia
    GuiControl, Hide, ST_AirBack
    GuiControl, Hide, ST_LblTransitTotal
    GuiControl, Hide, ST_TransitTotalText

    ; 자가용 전용 컨트롤도 먼저 숨긴 뒤 필요한 경우에만 표시한다.
    GuiControl, Hide, ST_LblFuel
    GuiControl, Hide, ST_FuelType
    GuiControl, Hide, ST_LblDist
    GuiControl, Hide, ST_Distance
    GuiControl, Hide, ST_LblKm
    GuiControl, Hide, ST_LblPrice
    GuiControl, Hide, ST_FuelPrice
    GuiControl, Hide, ST_LblWon1
    GuiControl, Hide, ST_BtnRecalcCar
    GuiControl, Hide, ST_BtnLookupCar
    GuiControl, Hide, ST_LblToll
    GuiControl, Hide, ST_Toll
    GuiControl, Hide, ST_LblWon2
    GuiControl, Hide, ST_LblPark
    GuiControl, Hide, ST_Parking
    GuiControl, Hide, ST_LblWon3
    GuiControl, Hide, ST_LblParkCap
    GuiControl, Hide, ST_LblCarTotal
    GuiControl, Hide, ST_CarFareTotalText
    GuiControl, Hide, ST_LblCarReason
    GuiControl, Hide, ST_CarReason
    GuiControl, Hide, ST_DescGov
    GuiControl, Hide, ST_DescCarpool

    if (ST_TransType1) ; 자가용
    {
        GuiControl, Show, ST_LblFuel
        GuiControl, Show, ST_FuelType
        GuiControl, Show, ST_LblDist
        GuiControl, Show, ST_Distance
        GuiControl, Show, ST_LblKm
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, Show, ST_BtnRecalcCar
        GuiControl, Show, ST_BtnLookupCar
        GuiControl, Show, ST_LblToll
        GuiControl, Show, ST_Toll
        GuiControl, Show, ST_LblWon2
        GuiControl, Show, ST_LblPark
        GuiControl, Show, ST_Parking
        GuiControl, Show, ST_LblWon3
        GuiControl, Show, ST_LblParkCap
        GuiControl, Show, ST_LblCarTotal
        GuiControl, Show, ST_CarFareTotalText
        GuiControl, Show, ST_LblCarReason
        GuiControl, Show, ST_CarReason
    }
    else if (ST_TransType2) ; 대중교통
    {
        ; 대중교통은 4종 × 3구간 운임표만 표시한다.
        GuiControl, Show, ST_TransitHeader
        GuiControl, Show, ST_TransitGoHeader
        GuiControl, Show, ST_TransitViaHeader
        GuiControl, Show, ST_TransitBackHeader
        GuiControl, Show, ST_LblRail
        GuiControl, Show, ST_RailGo
        GuiControl, Show, ST_RailVia
        GuiControl, Show, ST_RailBack
        GuiControl, Show, ST_LblBus
        GuiControl, Show, ST_BusGo
        GuiControl, Show, ST_BusVia
        GuiControl, Show, ST_BusBack
        GuiControl, Show, ST_LblShip
        GuiControl, Show, ST_ShipGo
        GuiControl, Show, ST_ShipVia
        GuiControl, Show, ST_ShipBack
        GuiControl, Show, ST_LblAir
        GuiControl, Show, ST_AirGo
        GuiControl, Show, ST_AirVia
        GuiControl, Show, ST_AirBack
        GuiControl, Show, ST_LblTransitTotal
        GuiControl, Show, ST_TransitTotalText

    }
    else if (ST_TransType3) ; 관용차량·임차버스
    {
        ; 철도·버스·선박·항공 운임표는 표시하지 않는다.
        GuiControl, Show, ST_DescGov
    }
    else ; 기타
    {
        ; 철도·버스·선박·항공 운임표는 표시하지 않는다.
        GuiControl, Show, ST_DescCarpool
    }
    return

SSOK_Travel_OnDateChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    sDate := SubStr(ST_StartDate, 1, 8)
    eDate := SubStr(ST_EndDate, 1, 8)
    diffDays := SSOK_Travel_DateDiffDays(sDate, eDate)
    if (diffDays < 0)
    {
        GuiControl, SSOKTravel:, ST_DaysText, % "[오류] 출발일이 도착일보다 늦음"
        GuiControl, SSOKTravel:, ST_Total, % "0 원 (출발일 확인 필요)"
        return
    }
    days := diffDays + 1
    nights := diffDays
    daysLabel := days . "일 (" . nights . "박 " . days . "일)"
    GuiControl, SSOKTravel:, ST_DaysText, %daysLabel%

    Gosub, SSOK_Travel_CheckAutoCategory
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_UpdateMealUI

    if (ST_TransType1)
    {
        price := SSOK_Travel_GetCachedOrFetchFuelPrice(ST_FuelType, sDate)
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, %price%
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, ""
    }
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnCarReasonChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (ST_CarReason != "")
        IniWrite, %ST_CarReason%, %SSOK_Ini%, Travel, CarReason
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnFuelTypeChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    IniWrite, %ST_FuelType%, %SSOK_Ini%, Travel, FuelType
    sDate := SubStr(ST_StartDate, 1, 8)
    price := SSOK_Travel_GetCachedOrFetchFuelPrice(ST_FuelType, sDate)
    if (InStr(ST_FuelType, "전기") && Abs((price + 0) - 324.4) < 0.01)
        price := 0
    if (price > 0)
        GuiControl, SSOKTravel:, ST_FuelPrice, %price%
    else
        GuiControl, SSOKTravel:, ST_FuelPrice, ""
    if (InStr(ST_FuelType, "전기"))
    {
        ; 전기차는 단일 고정단가를 자동 적용하지 않는다.
        ; 사용자가 충전기 출력에 맞는 실제 적용단가를 직접 입력해야 한다.
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/kWh"
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가(필수입력)"
        GuiControl, SSOKTravel:, ST_FuelPrice, ""
        MsgBox, 48, 전기차 충전요금 단가 입력 필수, % "전기차를 선택했습니다.`n`n충전기 출력별 기준단가를 확인한 후 [단가]에 실제 적용 단가(원/kWh)를 입력해 주세요.`n`n30kW 미만: 295.0원/kWh`n30~50kW 미만: 307.2원/kWh`n50~100kW 미만: 325.6원/kWh`n100~200kW 미만: 348.4원/kWh`n200kW 이상: 393.1원/kWh`n`n※ 단가를 입력하지 않으면 여비 정산을 진행할 수 없습니다."
        ToolTip, % "전기차: 충전요금 단가를 반드시 입력해야 정산할 수 있습니다."
        SetTimer, SSOK_Travel_RemoveToolTip, -3000
    }
    else if (InStr(ST_FuelType, "수소"))
    {
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/kg"
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가(실제)"
        if (price <= 0)
        {
            price := 9900
            GuiControl, SSOKTravel:, ST_FuelPrice, 9900
        }
        ToolTip, % "수소차: 공인연비 94.9km/kg 적용 (단가는 전국평균 9,900원/kg 또는 영수증 실단가 수정 가능)"
        SetTimer, SSOK_Travel_RemoveToolTip, -3500
    }
    else
    {
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
    }
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnTransitTypeChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    ; 대중교통은 철도/버스/선박/항공 4개 운임을 각각 저장
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_UpdateMealUI:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    sDate := SubStr(ST_StartDate, 1, 8)
    eDate := SubStr(ST_EndDate, 1, 8)
    diffDays := SSOK_Travel_DateDiffDays(sDate, eDate)
    if (diffDays < 0)
        return
    days := diffDays + 1
    maxMealCount := days * 3

    ; 일반출장
    ; 1일: 0~3식 선택
    ; 2일: 0~6식 선택
    ; 3일: 0~9식 선택
    ; 4일 이상: 식사수를 직접 입력
    if (days <= 3)
    {
        GuiControl, Show, ST_MealOption
        GuiControl, Hide, ST_MealCount
        GuiControl, Hide, ST_LblMealClosing

        mealList := "|0식"
        Loop, %maxMealCount%
        {
            n := A_Index
            mealList .= "|" . n . "식"
        }

        GuiControl, SSOKTravel:, ST_MealOption, %mealList%
        GuiControl, SSOKTravel:Choose, ST_MealOption, 1
        GuiControl, SSOKTravel:, ST_MealCount, 0
        GuiControl, SSOKTravel:, ST_LblMealLimit, % "최대 " . maxMealCount . "식"
        mealCount := 0
    }
    else
    {
        GuiControl, Hide, ST_MealOption
        GuiControl, Show, ST_MealCount
        GuiControl, Show, ST_LblMealClosing
        GuiControl, SSOKTravel:, ST_MealCount, 0
        GuiControl, SSOKTravel:, ST_LblMealLimit, % "최대 " . maxMealCount . "식"
        mealCount := 0
    }

    mealAmt := SSOK_Travel_Floor10(SSOK_Travel_CalcMealCost(mealCount))
    GuiControl, SSOKTravel:, ST_MealActual, % SSOK_Travel_Comma(mealAmt)
    GuiControl, +ReadOnly, ST_MealActual
    return

SSOK_Travel_OnMealOptionChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    mealCount := 0
    if (RegExMatch(ST_MealOption, "(\d+)", mCount))
        mealCount := mCount1 + 0

    sDate := SubStr(ST_StartDate, 1, 8)
    eDate := SubStr(ST_EndDate, 1, 8)
    diffDays := SSOK_Travel_DateDiffDays(sDate, eDate)
    if (diffDays >= 0)
    {
        days := diffDays + 1
        if (days <= 3)
        {
            maxMealCount := days * 3
            if (mealCount > maxMealCount)
                mealCount := maxMealCount
        }
    }

    GuiControl, SSOKTravel:, ST_MealCount, %mealCount%
    mealAmt := SSOK_Travel_Floor10(SSOK_Travel_CalcMealCost(mealCount))
    GuiControl, SSOKTravel:, ST_MealActual, % SSOK_Travel_Comma(mealAmt)
    GuiControl, +ReadOnly, ST_MealActual
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnMealCountChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    sDate := SubStr(ST_StartDate, 1, 8)
    eDate := SubStr(ST_EndDate, 1, 8)
    diffDays := SSOK_Travel_DateDiffDays(sDate, eDate)
    if (diffDays < 0)
        return
    days := diffDays + 1
    if (days <= 3)
        return

    maxMealCount := days * 3
    cVal := SSOK_Travel_Number(ST_MealCount)
    if (cVal < 0)
        cVal := 0
    if (cVal > maxMealCount)
    {
        cVal := maxMealCount
        GuiControl, SSOKTravel:, ST_MealCount, %cVal%
        ToolTip, % "최대 가능 식사수는 " . maxMealCount . "식입니다."
        SetTimer, SSOK_Travel_RemoveToolTip, -1800
    }

    mealAmt := SSOK_Travel_Floor10(SSOK_Travel_CalcMealCost(cVal))
    GuiControl, SSOKTravel:, ST_MealActual, % SSOK_Travel_Comma(mealAmt)
    GuiControl, +ReadOnly, ST_MealActual
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_UpdateLodgingInfo:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    sDate := SubStr(ST_StartDate, 1, 8)
    eDate := SubStr(ST_EndDate, 1, 8)
    diffDays := SSOK_Travel_DateDiffDays(sDate, eDate)
    if (diffDays < 0)
        return
    nights := diffDays
    isNoCap := (InStr(ST_Rank, "교장") || InStr(ST_Rank, "교육전문직"))

    if (nights <= 0)
    {
        GuiControl, SSOKTravel:, ST_LodgingAutoText, % "해당없음 (당일 출장)"
        GuiControl, SSOKTravel:Disable, ST_LodgingActual
        GuiControl, SSOKTravel:, ST_LodgingActual, 0
    }
    else
    {
        if (ST_TravelCategory2) ; 교육훈련 합숙(기숙사)
        {
            infoStr := "당해 교육훈련기관이 청구하는 금액"
            GuiControl, SSOKTravel:, ST_LodgingAutoText, %infoStr%
            GuiControl, SSOKTravel:Enable, ST_LodgingActual
        }
        else ; 일반출장 또는 교육훈련 비합숙
        {
            rName := SSOK_Travel_DetectLodgingRegionName(ST_Destination)
            if (isNoCap)
            {
                infoStr := rName . " (" . nights . "박) / 직급별 실비 지원 (상한액 없음)"
                GuiControl, SSOKTravel:, ST_LodgingAutoText, %infoStr%
                GuiControl, SSOKTravel:Enable, ST_LodgingActual
            }
            else
            {
                cap := SSOK_Travel_DetectLodgingCap(ST_Destination)
                capTotal := cap * nights
                capTotalStr := SSOK_Travel_Comma(capTotal)

                infoStr := rName . " (" . nights . "박) / 상한 " . capTotalStr . "원 (1박 " . SSOK_Travel_Comma(cap) . "원)"
                GuiControl, SSOKTravel:, ST_LodgingAutoText, %infoStr%
                GuiControl, SSOKTravel:Enable, ST_LodgingActual
            }
        }
    }
    return

; 10원 단위 미만 절사 함수
SSOK_Travel_Floor10(val)
{
    num := SSOK_Travel_Number(val)
    if (num <= 0)
        return 0
    return Floor(num / 10) * 10
}

SSOK_Travel_Calc:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    sDate := SubStr(ST_StartDate, 1, 8)
    eDate := SubStr(ST_EndDate, 1, 8)
    diffDays := SSOK_Travel_DateDiffDays(sDate, eDate)
    if (diffDays < 0)
    {
        GuiControl, SSOKTravel:, ST_DaysText, % "[오류] 출발일이 도착일보다 늦음"
        GuiControl, SSOKTravel:, ST_Total, % "0 원 (출발일 확인 필요)"
        GuiControl, SSOKTravel:, ST_TotalSummary, % "출발일이 도착일보다 늦습니다. 일정을 확인해주세요."
        return
    }
    days := diffDays + 1
    nights := diffDays

    ; --------------------------------------------------------------------------
    ; 1. 운임 계산 (자가용, 대중교통, 관용차량, 동승)
    ; --------------------------------------------------------------------------
    transportTotal := 0
    fuelCost := 0
    formulaStr := ""

    if (ST_TransType1) ; 자가용
    {
        isReasonSelected := (ST_CarReason != "" && !InStr(ST_CarReason, "선택하세요"))
        if (!isReasonSelected)
        {
            transportTotal := 0
            fuelCost := 0
            formulaStr := "자가용 이용 신청사유 미선택 (사유 선택 시 운임 산출)"
            carTotalText := "⚠️ 신청사유를 선택해주세요 (미선택 시 자가용 운임 미지급)"
            GuiControl, SSOKTravel:, ST_CarFareTotalText, %carTotalText%
        }
        else
        {
            eff := 11.97
            effUnit := "km/L"
            if (InStr(ST_FuelType, "경유"))
                eff := 12.52
            else if (InStr(ST_FuelType, "하이브리드"))
                eff := 15.37
            else if (InStr(ST_FuelType, "LPG"))
                eff := 8.83
            else if (InStr(ST_FuelType, "전기"))
            {
                eff := 5.22
                effUnit := "km/kWh"
            }
            else if (InStr(ST_FuelType, "수소"))
            {
                eff := 94.9
                effUnit := "km/kg"
            }

            oneWayKm := SSOK_Travel_Number(ST_Distance)
            roundKm := oneWayKm * 2.0
            price := SSOK_Travel_Number(ST_FuelPrice)

            ; 전기차 충전단가는 필수 입력. 미입력 상태에서는 유류비/교통비를 산출하지 않는다.
            if (InStr(ST_FuelType, "전기") && price <= 0)
            {
                fuelCost := 0
                formulaStr := "전기차 충전요금 단가 미입력 (단가 입력 후 정산 가능)"
                carTotalText := "⚠️ 전기차 충전요금 단가를 입력해주세요"
                GuiControl, SSOKTravel:, ST_CarFareTotalText, %carTotalText%
                return
            }

            if (roundKm > 0 && price > 0 && eff > 0)
            {
                rawFuel := (roundKm * 1.0 * price) / eff
                fuelCost := SSOK_Travel_Floor10(rawFuel)
                priceText := Format("{:0.2f}", price)
                formulaStr := "유류비 : " . SSOK_Travel_FormatDist(roundKm) . "km ÷ " . eff . " × " . priceText . "원/L = " . SSOK_Travel_Comma(fuelCost) . "원"
            }
            else
            {
                fuelCost := 0
                formulaStr := "유류비 : 조회자료 없음"
            }

            toll := SSOK_Travel_Floor10(ST_Toll)
            parking := SSOK_Travel_Floor10(ST_Parking)

            ; 주차료 1일 상한액 10,000원 검증
            parkCap := days * 10000
            if (parking > parkCap)
                parking := parkCap

            transportTotal := fuelCost + toll + parking

            carTotalText := SSOK_Travel_Comma(transportTotal) . " 원"
            if (toll > 0 || parking > 0)
            {
                subInfo := " (유류 " . SSOK_Travel_Comma(fuelCost)
                if (toll > 0)
                    subInfo .= " + 통행 " . SSOK_Travel_Comma(toll)
                if (parking > 0)
                    subInfo .= " + 주차 " . SSOK_Travel_Comma(parking)
                subInfo .= ")"
                carTotalText .= subInfo
            }
            GuiControl, SSOKTravel:, ST_CarFareTotalText, %carTotalText%
        }
    }
    else if (ST_TransType2) ; 대중교통
    {
        hasStopover := (Trim(ST_Stopover) != "")
        railGo := SSOK_Travel_Floor10(ST_RailGo), railBack := SSOK_Travel_Floor10(ST_RailBack)
        busGo := SSOK_Travel_Floor10(ST_BusGo), busBack := SSOK_Travel_Floor10(ST_BusBack)
        shipGo := SSOK_Travel_Floor10(ST_ShipGo), shipBack := SSOK_Travel_Floor10(ST_ShipBack)
        airGo := SSOK_Travel_Floor10(ST_AirGo), airBack := SSOK_Travel_Floor10(ST_AirBack)

        rawRailVia := SSOK_Travel_Floor10(ST_RailVia)
        rawBusVia := SSOK_Travel_Floor10(ST_BusVia)
        rawShipVia := SSOK_Travel_Floor10(ST_ShipVia)
        rawAirVia := SSOK_Travel_Floor10(ST_AirVia)
        totalRawVia := rawRailVia + rawBusVia + rawShipVia + rawAirVia

        ; 경유지와 경유지 운임이 모두 정상 입력되어야만 계산 및 표시에 반영
        hasValidTransitVia := (hasStopover && (totalRawVia > 0))

        railVia := (hasValidTransitVia ? rawRailVia : 0)
        busVia := (hasValidTransitVia ? rawBusVia : 0)
        shipVia := (hasValidTransitVia ? rawShipVia : 0)
        airVia := (hasValidTransitVia ? rawAirVia : 0)

        railFare := railGo + railVia + railBack
        busFare := busGo + busVia + busBack
        shipFare := shipGo + shipVia + shipBack
        airFare := airGo + airVia + airBack
        transportTotal := railFare + busFare + shipFare + airFare

        tStr := SSOK_Travel_Comma(transportTotal) . " 원"
        tDetail := ""
        if (railFare > 0)
        {
            if (hasValidTransitVia && railVia > 0)
                tDetail .= " (철도: 가는 " . SSOK_Travel_Comma(railGo) . " / 경유 " . SSOK_Travel_Comma(railVia) . " / 오는 " . SSOK_Travel_Comma(railBack) . "원)"
            else
                tDetail .= " (철도: 가는 " . SSOK_Travel_Comma(railGo) . " / 오는 " . SSOK_Travel_Comma(railBack) . "원)"
        }
        if (busFare > 0)
        {
            if (hasValidTransitVia && busVia > 0)
                tDetail .= " (버스: 가는 " . SSOK_Travel_Comma(busGo) . " / 경유 " . SSOK_Travel_Comma(busVia) . " / 오는 " . SSOK_Travel_Comma(busBack) . "원)"
            else
                tDetail .= " (버스: 가는 " . SSOK_Travel_Comma(busGo) . " / 오는 " . SSOK_Travel_Comma(busBack) . "원)"
        }
        if (shipFare > 0)
        {
            if (hasValidTransitVia && shipVia > 0)
                tDetail .= " (선박: 가는 " . SSOK_Travel_Comma(shipGo) . " / 경유 " . SSOK_Travel_Comma(shipVia) . " / 오는 " . SSOK_Travel_Comma(shipBack) . "원)"
            else
                tDetail .= " (선박: 가는 " . SSOK_Travel_Comma(shipGo) . " / 오는 " . SSOK_Travel_Comma(shipBack) . "원)"
        }
        if (airFare > 0)
        {
            if (hasValidTransitVia && airVia > 0)
                tDetail .= " (항공: 가는 " . SSOK_Travel_Comma(airGo) . " / 경유 " . SSOK_Travel_Comma(airVia) . " / 오는 " . SSOK_Travel_Comma(airBack) . "원)"
            else
                tDetail .= " (항공: 가는 " . SSOK_Travel_Comma(airGo) . " / 오는 " . SSOK_Travel_Comma(airBack) . "원)"
        }
        if (tDetail != "")
            tStr .= tDetail
        GuiControl, SSOKTravel:, ST_TransitTotalText, %tStr%
        formulaStr := "대중교통 운임 " . SSOK_Travel_Comma(transportTotal) . "원"
    }
    else if (ST_TransType3) ; 관용차량
    {
        transportTotal := 0
        formulaStr := "관용차량·임차버스 (운임 0원)"
    }
    else ; 기타 (타인차량 동승 외)
    {
        transportTotal := 0
        formulaStr := "기타 (타인차량 동승 외: 운임 0원)"
    }

    ; --------------------------------------------------------------------------
    ; 2. 일비 계산
    ; --------------------------------------------------------------------------
    ; 일비 계산
    ; 관용차량: 기준 일비의 1/2, 임차버스: 기준 일비의 100%
    dailyRate := 25000
    if (ST_TransType3)
        dailyRate := 12500

    ; 교육훈련 일비 지급기준
    ; 합숙·기숙사: 출발일·도착일 100%, 중간일 0%
    ; 비합숙: 출발일·도착일 100%, 중간일 50%
    if (ST_TravelCategory2)
    {
        if (days <= 1)
            dailyTotal := dailyRate
        else
            dailyTotal := dailyRate * 2
    }
    else if (ST_TravelCategory3)
    {
        if (days <= 1)
            dailyTotal := dailyRate
        else
            dailyTotal := (dailyRate * 2) + (dailyRate * 0.5 * (days - 2))
    }
    else
    {
        dailyTotal := days * dailyRate
    }

    ; --------------------------------------------------------------------------
    ; 3. 식비 계산
    ; --------------------------------------------------------------------------
    mealTotal := 0
    if (ST_TravelCategory1) ; 일반출장
    {
        mealCapTotal := days * 25000
        mOptCount := 0
        if (RegExMatch(ST_MealOption, "(\d+)", mOptMatch))
            mOptCount := mOptMatch1 + 0
        else
            mOptCount := 0

        maxMealCount := days * 3
        mealCount := 0

        if (days <= 3)
        {
            mealCount := mOptCount
            if (mealCount < 0)
                mealCount := 0
            if (mealCount > maxMealCount)
                mealCount := maxMealCount
        }
        else
        {
            mealCount := SSOK_Travel_Number(ST_MealCount)
            if (mealCount < 0)
                mealCount := 0
            if (mealCount > maxMealCount)
                mealCount := maxMealCount
        }

        ; 일반출장 식비는 식사수에 따라 자동 계산한다.
        mealTotal := SSOK_Travel_Floor10(SSOK_Travel_CalcMealCost(mealCount))
        GuiControl, SSOKTravel:, ST_MealActual, % SSOK_Travel_Comma(mealTotal)

        if (mealTotal > mealCapTotal)
            mealTotal := mealCapTotal
    }
    else ; 교육훈련 출장 (합숙/비합숙 공통: 영수증 실비 지급)
    {
        mealTotal := SSOK_Travel_Floor10(ST_MealActual)
    }

    ; --------------------------------------------------------------------------
    ; 4. 숙박비 계산
    ; --------------------------------------------------------------------------
    lodgingTotal := 0
    lodgingCapTotal := 0
    lodgingActual := SSOK_Travel_Floor10(ST_LodgingActual)
    if (nights > 0)
    {
        if (ST_TravelCategory2) ; 합숙·기숙사: 청구금액 전액 실비 지원 (상한액 없음)
        {
            lodgingTotal := lodgingActual
        }
        else ; 일반출장
        {
            isNoCap := (InStr(ST_Rank, "교장") || InStr(ST_Rank, "교육전문직"))
            lodgingCap := SSOK_Travel_DetectLodgingCap(ST_Destination)
            lodgingCapTotal := lodgingCap * nights

            if (isNoCap)
                lodgingTotal := lodgingActual
            else
            {
                if (lodgingActual > 0)
                    lodgingTotal := (lodgingActual > lodgingCapTotal ? lodgingCapTotal : lodgingActual)
                else
                    lodgingTotal := 0
            }
        }
    }

    ; --------------------------------------------------------------------------
    ; 5. 총액 산출 및 화면 표시
    ; --------------------------------------------------------------------------
    grandTotal := transportTotal + dailyTotal + mealTotal + lodgingTotal

    totalStr := SSOK_Travel_Comma(grandTotal) . " 원"
    GuiControl, SSOKTravel:, ST_Total, %totalStr%

    summaryText := "운임 " . SSOK_Travel_Comma(transportTotal) . "원 | 일비 " . SSOK_Travel_Comma(dailyTotal) . "원 | 식비 " . SSOK_Travel_Comma(mealTotal) . "원 | 숙박비 " . SSOK_Travel_Comma(lodgingTotal) . "원"
    GuiControl, SSOKTravel:, ST_TotalSummary, %summaryText%

    return

; ==============================================================================
; [거리 / 유가 조회] - 모호한 목적지 확인/선택 팝업 및 정확한 거리 산출
; ==============================================================================
; 거리 / 유가 재산정: 웹 재조회 없이 현재 숫자만 검증하여 재계산
SSOK_Travel_RecalculateCar:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    dist := SSOK_Travel_Number(ST_Distance)
    price := SSOK_Travel_Number(ST_FuelPrice)
    toll := SSOK_Travel_Number(ST_Toll)
    parking := SSOK_Travel_Number(ST_Parking)

    if (ST_DestLon = 0 || ST_DestLat = 0)
    {
        MsgBox, 48, 도착지 미확정, 도착지를 입력한 뒤 Enter를 눌러 장소를 먼저 확정해 주세요.
        return
    }
    if (dist < 0 || price < 0 || toll < 0 || parking < 0)
    {
        MsgBox, 48, 숫자 확인, 거리·단가·통행료·주차료에는 0 이상의 숫자만 입력해 주세요.
        return
    }
    if (InStr(ST_FuelType, "전기") && price <= 0)
    {
        MsgBox, 48, 전기차 충전요금 단가 입력 필수, % "전기차 충전요금 단가를 입력하지 않았습니다.`n`n충전기 출력에 맞는 적용 단가(원/kWh)를 [단가]에 입력한 후 다시 진행해 주세요.`n`n단가 미입력 상태에서는 정산을 진행할 수 없습니다."
        GuiControl, Focus, ST_FuelPrice
        return
    }
    GuiControl, SSOKTravel:, ST_Distance, % SSOK_Travel_FormatDist(dist)
    if (price > 0)
        GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
    Gosub, SSOK_Travel_Calc
    ToolTip, % "거리·유가 숫자를 검증하여 재산정했습니다."
    SetTimer, SSOK_Travel_RemoveToolTip, -2200
    return

; 조회: 계산값을 바꾸지 않고 원문/지도 링크만 연다.
SSOK_Travel_OpenCarLookup:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (ST_Destination = "" || ST_DestLon = 0 || ST_DestLat = 0)
    {
        MsgBox, 48, 도착지 미확정, 도착지를 입력한 뒤 Enter를 눌러 장소를 먼저 확정해 주세요.
        return
    }

    sDate := SubStr(ST_StartDate, 1, 8)
    sY := SubStr(sDate,1,4), sM := SubStr(sDate,5,2), sD := SubStr(sDate,7,2)
    if (InStr(ST_FuelType, "전기") || InStr(ST_FuelType, "수소"))
        fuelUrl := "https://ev.or.kr/nportal/evcarInfo/initEvcarChargePriceV2.do"
    else if (InStr(ST_FuelType, "LPG"))
        fuelUrl := "https://www.opinet.co.kr/user/dopvsavsel/dopVsAvselSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_K015_P=Y"
    else
        fuelUrl := "https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_B027=Y&OIL_CD_D047=Y"

    enc1 := SSOK_Travel_UriEncode(ST_DepName != "" ? ST_DepName : ST_Departure)
    enc2 := SSOK_Travel_UriEncode(ST_DestName != "" ? ST_DestName : ST_Destination)
    naverUrl := "https://map.naver.com/p/directions/" . ST_DepLon . "," . ST_DepLat . "," . enc1 . "/" . ST_DestLon . "," . ST_DestLat . "," . enc2 . "/-/car?c=14.00,0,0,0,dh"
    try Run, %naverUrl%
    try Run, %fuelUrl%
    return

SSOK_Travel_SearchRoute:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    ; 출발지 자동 보정 (소속의 접두사 상태이면 온전한 소속으로 자동 복구)
    if (ST_Org != "" && (ST_Departure = "" || InStr(ST_Org, ST_Departure) = 1))
    {
        ST_Departure := ST_Org
        GuiControl, SSOKTravel:, ST_Departure, %ST_Departure%
    }

    if (ST_Destination = "")
    {
        ToolTip, % "도착지(건물명 또는 주소지)를 먼저 입력해주세요."
        SetTimer, SSOK_Travel_RemoveToolTip, -2500
        return
    }

    ToolTip, % "목적지 검색 및 거리/유가 정보 확인 중..."

    lon1 := 0, lat1 := 0, name1 := ""
    lon2 := 0, lat2 := 0, name2 := ""
    lonVia := 0, latVia := 0, nameVia := ""

    ; 1. 출발지 좌표 조회
    SSOK_Travel_GetCoords(ST_Departure, lon1, lat1, name1)

    ; 2. 경유지 좌표 조회 (입력된 경우)
    if (ST_Stopover != "")
        SSOK_Travel_GetCoords(ST_Stopover, lonVia, latVia, nameVia)

    ; 3. 도착지 장소 검색 및 모호성 확인 다이얼로그
    destFound := SSOK_Travel_ResolveDestination(ST_Destination, lon2, lat2, name2)
    if (!destFound)
    {
        ToolTip, % "도착지 확인이 취소되었거나 장소를 찾을 수 없어 거리 산출을 중단합니다."
        SetTimer, SSOK_Travel_RemoveToolTip, -3000
        return
    }

    ST_DepLon := lon1, ST_DepLat := lat1, ST_DepName := (name1 != "" ? name1 : ST_Departure)
    ST_DestLon := lon2, ST_DestLat := lat2, ST_DestName := (name2 != "" ? name2 : ST_Destination)
    ST_ViaLon := lonVia, ST_ViaLat := latVia, ST_ViaName := (nameVia != "" ? nameVia : ST_Stopover)

    km := 0
    routeCoords := ""
    if (lon1 && lat1 && lon2 && lat2)
    {
        km := SSOK_Travel_GetDistanceAndRoute(lon1, lat1, lon2, lat2, routeCoords, lonVia, latVia)
        if (routeCoords != "")
            ST_RouteCoords := routeCoords
    }

    kmStr := SSOK_Travel_FormatDist(km)
    if (km > 0)
        GuiControl, SSOKTravel:, ST_Distance, %kmStr%
    else
        GuiControl, SSOKTravel:, ST_Distance, 0.0

    sDate := SubStr(ST_StartDate, 1, 8)
    price := SSOK_Travel_GetCachedOrFetchFuelPrice(ST_FuelType, sDate)
    if (price > 0 && ST_TransType1)
        GuiControl, SSOKTravel:, ST_FuelPrice, %price%

    Gosub, SSOK_Travel_CheckAutoCategory
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc

    ; 웹 브라우저 연동
    sY := SubStr(sDate, 1, 4)
    sM := SubStr(sDate, 5, 2)
    sD := SubStr(sDate, 7, 2)

    statUrl := ""
    if (InStr(ST_FuelType, "전기"))
    {
        statUrl := "https://ev.or.kr/nportal/evcarInfo/initEvcarChargePriceV2.do"
    }
    else if (InStr(ST_FuelType, "수소"))
    {
        statUrl := "https://ev.or.kr/nportal/evcarInfo/initEvcarChargePriceV2.do"
    }
    else if (InStr(ST_FuelType, "LPG"))
    {
        statUrl := "https://www.opinet.co.kr/user/dopvsavsel/dopVsAvselSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_K015_P=Y"
    }
    else
    {
        statUrl := "https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_B027=Y&OIL_CD_D047=Y"
    }

    if (lon1 && lat1 && lon2 && lat2)
    {
        enc1 := SSOK_Travel_UriEncode(ST_DepName)
        enc2 := SSOK_Travel_UriEncode(ST_DestName)
        mode := (ST_TransType2 ? "transit" : "car")

        if (lonVia && latVia)
        {
            encVia := SSOK_Travel_UriEncode(ST_ViaName)
            naverUrl := "https://map.naver.com/p/directions/" . lon1 . "," . lat1 . "," . enc1 . "/" . lonVia . "," . latVia . "," . encVia . "/" . lon2 . "," . lat2 . "," . enc2 . "/-/" . mode . "?c=14.00,0,0,0,dh"
        }
        else
        {
            naverUrl := "https://map.naver.com/p/directions/" . lon1 . "," . lat1 . "," . enc1 . "/" . lon2 . "," . lat2 . "," . enc2 . "/-/" . mode . "?c=14.00,0,0,0,dh"
        }

        try {
            Run, %naverUrl%
        }
    }

    if (statUrl != "")
    {
        try {
            Run, %statUrl%
        }
    }

    ToolTip, % "거리 및 유가 조회가 완료되었습니다."
    SetTimer, SSOK_Travel_RemoveToolTip, -2500
    return

; 출발지 및 도착지 좌표 기반 주행거리 및 여비 자동 산출 함수
SSOK_Travel_AutoUpdateDistance()
{
    global ST_Departure, ST_Destination, ST_Stopover
    global ST_DepLon, ST_DepLat, ST_DepName
    global ST_DestLon, ST_DestLat, ST_DestName
    global ST_ViaLon, ST_ViaLat, ST_ViaName
    global ST_RouteCoords, ST_Distance, ST_StartDate, ST_FuelType, ST_TransType1

    ; 출발지 좌표가 아직 없으면 출발지 좌표 자동 조회
    if (ST_DepLon = 0 || ST_DepLat = 0)
    {
        if (ST_Departure != "")
            SSOK_Travel_GetCoords(ST_Departure, ST_DepLon, ST_DepLat, ST_DepName)
    }

    ; 경유지 좌표 조회
    if (ST_Stopover != "" && (ST_ViaLon = 0 || ST_ViaLat = 0))
    {
        SSOK_Travel_GetCoords(ST_Stopover, ST_ViaLon, ST_ViaLat, ST_ViaName)
    }

    ; 도착지 좌표 조회
    if (ST_DestLon = 0 || ST_DestLat = 0)
    {
        if (ST_Destination != "")
            SSOK_Travel_GetCoords(ST_Destination, ST_DestLon, ST_DestLat, ST_DestName)
    }

    ; 출발지와 도착지 좌표가 모두 확보되면 주행거리 자동 산출
    if (ST_DepLon != 0 && ST_DepLat != 0 && ST_DestLon != 0 && ST_DestLat != 0)
    {
        routeCoords := ""
        km := 0
        if (ST_ViaLon != 0 && ST_ViaLat != 0)
            km := SSOK_Travel_GetDistanceAndRoute(ST_DepLon, ST_DepLat, ST_DestLon, ST_DestLat, routeCoords, ST_ViaLon, ST_ViaLat)
        else
            km := SSOK_Travel_GetDistanceAndRoute(ST_DepLon, ST_DepLat, ST_DestLon, ST_DestLat, routeCoords)

        if (routeCoords != "")
            ST_RouteCoords := routeCoords

        if (km > 0)
        {
            kmStr := SSOK_Travel_FormatDist(km)
            GuiControl, SSOKTravel:, ST_Distance, %kmStr%
            ST_Distance := kmStr
        }

        sDate := SubStr(ST_StartDate, 1, 8)
        price := SSOK_Travel_GetCachedOrFetchFuelPrice(ST_FuelType, sDate)
        if (ST_TransType1)
        {
            if (price > 0)
                GuiControl, SSOKTravel:, ST_FuelPrice, %price%
            else
                GuiControl, SSOKTravel:, ST_FuelPrice, ""
        }

        Gosub, SSOK_Travel_Calc
        ToolTip, % "거리 자동 산출 완료: " . ST_Distance . " km"
        SetTimer, SSOK_Travel_RemoveToolTip, -2500
    }
}

; 장소 검색 및 정확한 명칭/주소 선택 확인 함수 (dge-te.com 스타일)
SSOK_Travel_ResolvePlace(query, ByRef outLon, ByRef outLat, ByRef outName, title := "장소 검색 결과 선택 및 확인")
{
    outLon := 0, outLat := 0, outName := query
    if (query = "" || StrLen(query) <= 1)
        return false

    places := SSOK_Travel_SearchPlacesApi(query)
    pCount := places.Length()

    if (pCount = 0)
    {
        ; Fallback: OpenStreetMap Nominatim
        if (SSOK_Travel_GetCoordsNominatim(query, nomLon, nomLat, nomName))
        {
            outLon := nomLon, outLat := nomLat, outName := nomName
            return true
        }
        ToolTip, % "'" . query . "' 검색 결과가 없습니다. 정식 명칭이나 주소로 입력해 주세요."
        SetTimer, SSOK_Travel_RemoveToolTip, -2500
        return false
    }

    ; 검색된 장소 목록을 다이얼로그로 보여주고 사용자가 정확한 명칭과 도로명 주소를 확인 후 선택
    chosenIdx := SSOK_Travel_ShowPlaceSelectDialog(query, places, title)
    if (chosenIdx <= 0 || chosenIdx > pCount)
        return false

    outLon := places[chosenIdx].lon
    outLat := places[chosenIdx].lat
    outName := places[chosenIdx].name

    return true
}

; 기존 호환용 도착지 래퍼 함수
SSOK_Travel_ResolveDestination(query, ByRef outLon, ByRef outLat, ByRef outName)
{
    global ST_Destination, SSOK_Ini
    if (!SSOK_Travel_ResolvePlace(query, outLon, outLat, outName, "도착지 검색 결과 선택 및 확인"))
        return false
    ST_Destination := outName
    GuiControl, SSOKTravel:, ST_Destination, %ST_Destination%
    GuiControl, SSOKTravel:Enable, ST_TransType1
    IniWrite, %ST_Destination%, %SSOK_Ini%, Travel, Destination
    return true
}

; 장소 검색 결과 선택 모달 창 (dge-te.com 스타일)
SSOK_Travel_ShowPlaceSelectDialog(query, places, title := "장소 검색 결과 선택 및 확인")
{
    global ST_SelectedPlaceIdx, ST_PlaceListView
    ST_SelectedPlaceIdx := 0

    Gui, SSOKPlaceSelect:Destroy
    Gui, SSOKPlaceSelect:New, +OwnerSSOKTravel +AlwaysOnTop +ToolWindow +HwndhPlaceDlg, %title%
    Gui, SSOKPlaceSelect:Font, s10, Malgun Gothic

    Gui, SSOKPlaceSelect:Add, Text, x16 y12 w560 c003366, % "입력하신 '" . query . "'의 검색 결과입니다. 정확한 장소를 선택해 주세요:"

    Gui, SSOKPlaceSelect:Add, ListView, x16 y38 w560 h180 vST_PlaceListView gSSOK_Travel_OnPlaceDoubleClick +Grid -Multi, % "번호|장소명|도로명 주소 (위치)"
    LV_ModifyCol(1, 45)
    LV_ModifyCol(2, 210)
    LV_ModifyCol(3, 290)

    for idx, p in places
    {
        LV_Add("", idx, p.name, p.address)
    }
    LV_Modify(1, "Select Focus")

    Gui, SSOKPlaceSelect:Add, Button, x140 y226 w170 h36 gSSOK_Travel_OnPlaceSelectConfirm Default, % "선택한 장소로 확정"
    Gui, SSOKPlaceSelect:Add, Button, x320 y226 w140 h36 gSSOK_Travel_OnPlaceSelectCancel, % "취소"

    Gui, SSOKPlaceSelect:Show, w592 h275 Center

    WinWaitClose, ahk_id %hPlaceDlg%

    return ST_SelectedPlaceIdx
}

SSOK_Travel_OnPlaceDoubleClick:
    if (A_GuiEvent = "DoubleClick")
        Gosub, SSOK_Travel_OnPlaceSelectConfirm
    return

SSOK_Travel_OnPlaceSelectConfirm:
    Gui, SSOKPlaceSelect:Default
    row := LV_GetNext(0)
    if (row > 0)
    {
        LV_GetText(selNum, row, 1)
        ST_SelectedPlaceIdx := selNum + 0
    }
    Gui, SSOKPlaceSelect:Destroy
    return

SSOK_Travel_OnPlaceSelectCancel:
SSOKPlaceSelectGuiClose:
SSOKPlaceSelectGuiEscape:
    ST_SelectedPlaceIdx := 0
    Gui, SSOKPlaceSelect:Destroy
    return

; 카카오맵 기반 고정밀 국내 장소/주소 검색 API
SSOK_Travel_SearchPlacesApi(query)
{
    places := []
    if (query = "" || StrLen(query) <= 1)
        return places

    try
    {
        enc := SSOK_Travel_UriEncode(query)
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(5000, 5000, 5000, 5000)
        url := "https://search.map.kakao.com/mapsearch/map.daum?q=" . enc . "&msFlag=A&sort=0"
        whr.Open("GET", url, false)
        whr.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        whr.SetRequestHeader("Referer", "https://map.kakao.com/")
        whr.Send()

        body := whr.ResponseBody
        pData := NumGet(ComObjValue(body) + 8 + A_PtrSize)
        size := body.MaxIndex() + 1
        res := StrGet(pData, size, "UTF-8")

        pStart := InStr(res, """place"":[{")
        if (pStart)
        {
            pEnd := InStr(res, "],""busStop""", false, pStart)
            if (!pEnd)
                pEnd := InStr(res, "],""filter""", false, pStart)
            if (!pEnd)
                pEnd := InStr(res, "],", false, pStart)
            placeBlock := SubStr(res, pStart, pEnd - pStart + 2)

            parts := StrSplit(placeBlock, "{""confirmid"":""")
            for idx, chunk in parts
            {
                if (idx = 1)
                    continue

                name := "", addr := "", lon := 0, lat := 0

                if RegExMatch(chunk, "O)""name"":""([^""]+)""", nm)
                    name := nm.Value(1)
                if RegExMatch(chunk, "O)""new_address"":""([^""]+)""", adm)
                    addr := adm.Value(1)
                if (addr = "") && RegExMatch(chunk, "O)""address"":""([^""]+)""", adm)
                    addr := adm.Value(1)

                if RegExMatch(chunk, "O)""lon"":([0-9\.]+)", lm)
                    lon := lm.Value(1)
                if RegExMatch(chunk, "O)""lat"":([0-9\.]+)", lm)
                    lat := lm.Value(1)

                if (name != "" && lon != 0 && lat != 0)
                {
                    p := {}
                    p.name := name
                    p.address := addr
                    p.lon := lon
                    p.lat := lat
                    p.x := lon
                    p.y := lat
                    places.Push(p)
                    if (places.Length() >= 10)
                        break
                }
            }
        }
    }
    catch e
    {
    }
    return places
}

SSOK_Travel_RemoveToolTip:
    ToolTip
    return

SSOK_Travel_Reset:
    Gui, SSOKTravel:Default
    defaultOrg := SSOK_Travel_GetDefaultOrg()
    ; 소속/직급/성명은 ini에서 읽어 유지 (자주 사용하는 값 보존)
    IniRead, keepRank, %SSOK_Ini%, Travel, Rank, 교사
    if (keepRank = "ERROR" || keepRank = "")
        keepRank := "교사"
    IniRead, keepName, %SSOK_Ini%, Travel, Name, %A_Space%
    if (keepName = "ERROR")
        keepName := ""
    GuiControl, SSOKTravel:, ST_Org, %defaultOrg%
    GuiControl, SSOKTravel:ChooseString, ST_Rank, %keepRank%
    GuiControl, SSOKTravel:, ST_Name, %keepName%
    GuiControl, SSOKTravel:, ST_Departure, %defaultOrg%
    GuiControl, SSOKTravel:, ST_Destination, 
    GuiControl, SSOKTravel:, ST_Stopover, 
    GuiControl, SSOKTravel:, ST_Distance, 0.0
    GuiControl, SSOKTravel:, ST_Toll, 0
    GuiControl, SSOKTravel:, ST_Parking, 0
    GuiControl, SSOKTravel:, ST_RailGo, 0
    GuiControl, SSOKTravel:, ST_RailVia, 0
    GuiControl, SSOKTravel:, ST_RailBack, 0
    GuiControl, SSOKTravel:, ST_BusGo, 0
    GuiControl, SSOKTravel:, ST_BusVia, 0
    GuiControl, SSOKTravel:, ST_BusBack, 0
    GuiControl, SSOKTravel:, ST_ShipGo, 0
    GuiControl, SSOKTravel:, ST_ShipVia, 0
    GuiControl, SSOKTravel:, ST_ShipBack, 0
    GuiControl, SSOKTravel:, ST_AirGo, 0
    GuiControl, SSOKTravel:, ST_AirVia, 0
    GuiControl, SSOKTravel:, ST_AirBack, 0
    GuiControl, SSOKTravel:, ST_MealActual, 0
    GuiControl, SSOKTravel:, ST_LodgingActual, 0
    GuiControl, SSOKTravel:, ST_CarReason, |1. 출장경로가 매우 복잡･다양하여 대중교통을 사실상 이용할 수 없는 경우|2. 자가용을 이용함으로써 운임이 적게 소요되는 경우|3. 산간오지, 도서벽지 등 대중교통수단이 없어 부득이 자가용 이용|4. 하중이 무거운 수하물을 운송해야 하는 경우|5. 공무목적상 부득이한 심야시간대 이동 또는 긴급한 사유가 있는 경우|6. 기관장 인정사유( 학생 현장실습 및 취업지원을 위한 학생 동승시 )|7. 대중교통을 이용에 어려움이 있는 장애인 공무원

    GuiControl, SSOKTravel:, ST_TravelCategory1, 1
    GuiControl, SSOKTravel:, ST_TravelCategory2, 0
    GuiControl, SSOKTravel:, ST_TravelCategory3, 0

    GuiControl, SSOKTravel:, ST_TransType2, 1
    GuiControl, SSOKTravel:, ST_TransType1, 0
    GuiControl, SSOKTravel:, ST_TransType3, 0
    GuiControl, SSOKTravel:, ST_TransType4, 0
    GuiControl, SSOKTravel:Disable, ST_TransType1

    ST_DepLon := 0, ST_DepLat := 0, ST_DepName := ""
    ST_DestLon := 0, ST_DestLat := 0, ST_DestName := ""
    ST_ViaLon := 0, ST_ViaLat := 0, ST_ViaName := ""
    ST_RouteCoords := ""

    Gosub, SSOK_Travel_UpdateTransportUI
    Gosub, SSOK_Travel_UpdateCategoryUI
    Gosub, SSOK_Travel_UpdateMealUI
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc
    return

; ==============================================================================
; [여비정산서 인쇄] (HTML 생성 및 인쇄 다이얼로그)
; ==============================================================================
SSOK_Travel_PrintHtml:
    SSOK_Travel_AutoSave()
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    global ST_RailGo, ST_RailVia, ST_RailBack, ST_BusGo, ST_BusVia, ST_BusBack, ST_ShipGo, ST_ShipVia, ST_ShipBack, ST_AirGo, ST_AirVia, ST_AirBack
    ; 출발지 자동 보정
    if (ST_Org != "" && (ST_Departure = "" || InStr(ST_Org, ST_Departure) = 1))
    {
        ST_Departure := ST_Org
        GuiControl, SSOKTravel:, ST_Departure, %ST_Departure%
    }

    sDate := SubStr(ST_StartDate, 1, 8)
    eDate := SubStr(ST_EndDate, 1, 8)
    diffDays := SSOK_Travel_DateDiffDays(sDate, eDate)
    if (diffDays < 0)
    {
        MsgBox, 48, 일정 오류, 출발일이 도착일보다 늦습니다. 일정을 확인해주세요.
        return
    }

    if (ST_TransType1 && (ST_CarReason = "" || InStr(ST_CarReason, "선택하세요")))
    {
        MsgBox, 48, 자가용 신청사유 미선택, 자가용을 이용하시는 경우 [신청사유]를 선택해주세요.
        return
    }

    ; 전기차는 충전요금 단가를 반드시 입력해야 최종 정산/인쇄 진행 가능
    if (ST_TransType1 && InStr(ST_FuelType, "전기"))
    {
        evPrice := SSOK_Travel_Number(ST_FuelPrice)
        if (evPrice <= 0)
        {
            MsgBox, 48, 전기차 충전요금 단가 입력 필수, % "전기차 충전요금 단가가 입력되지 않았습니다.`n`n충전기 출력에 맞는 실제 적용 단가(원/kWh)를 [단가]에 입력해 주세요.`n`n30kW 미만: 295.0원/kWh`n30~50kW 미만: 307.2원/kWh`n50~100kW 미만: 325.6원/kWh`n100~200kW 미만: 348.4원/kWh`n200kW 이상: 393.1원/kWh`n`n단가를 입력하지 않으면 최종 정산/인쇄를 진행할 수 없습니다."
            GuiControl, Focus, ST_FuelPrice
            return
        }
    }

    Gosub, SSOK_Travel_Calc

    FormatTime, sDateStr, %ST_StartDate%, yyyy-MM-dd
    FormatTime, eDateStr, %ST_EndDate%, yyyy-MM-dd
    FormatTime, sYear, %ST_StartDate%, yyyy
    FormatTime, sMonth, %ST_StartDate%, MM
    FormatTime, sDay, %ST_StartDate%, dd
    FormatTime, eYear, %ST_EndDate%, yyyy
    FormatTime, eMonth, %ST_EndDate%, MM
    FormatTime, eDay, %ST_EndDate%, dd

    days := diffDays + 1
    nights := diffDays
    ; 대중교통 4종 × 가는편/경유지/오는편 운임
    railGo := SSOK_Travel_Floor10(ST_RailGo), railBack := SSOK_Travel_Floor10(ST_RailBack)
    busGo := SSOK_Travel_Floor10(ST_BusGo), busBack := SSOK_Travel_Floor10(ST_BusBack)
    shipGo := SSOK_Travel_Floor10(ST_ShipGo), shipBack := SSOK_Travel_Floor10(ST_ShipBack)
    airGo := SSOK_Travel_Floor10(ST_AirGo), airBack := SSOK_Travel_Floor10(ST_AirBack)

    hasStopover := (Trim(ST_Stopover) != "")
    rawRailVia := SSOK_Travel_Floor10(ST_RailVia)
    rawBusVia := SSOK_Travel_Floor10(ST_BusVia)
    rawShipVia := SSOK_Travel_Floor10(ST_ShipVia)
    rawAirVia := SSOK_Travel_Floor10(ST_AirVia)
    totalRawVia := rawRailVia + rawBusVia + rawShipVia + rawAirVia

    ; 경유지와 경유지 운임이 모두 정상 입력되어야만 계산 및 표시에 반영
    hasValidTransitVia := (hasStopover && (totalRawVia > 0))

    railVia := (hasValidTransitVia ? rawRailVia : 0)
    busVia := (hasValidTransitVia ? rawBusVia : 0)
    shipVia := (hasValidTransitVia ? rawShipVia : 0)
    airVia := (hasValidTransitVia ? rawAirVia : 0)

    hasVia := (ST_TransType2 ? hasValidTransitVia : hasStopover)
    oneWayDist := SSOK_Travel_Number(ST_Distance)
    roundDist := oneWayDist * 2.0
    ; 인쇄용 거리 표시는 네이버 지도와 비교하기 쉽도록 편도 거리 1개만 표시한다.
    ; 유류비 계산 자체는 기존처럼 왕복거리(roundDist)를 사용한다.
    displayOneWayDist := oneWayDist
    price := SSOK_Travel_Number(ST_FuelPrice)

    eff := 11.97
    effUnit := "km/L"
    fuelNameOnly := "휘발유"
    if (InStr(ST_FuelType, "경유"))
    {
        eff := 12.52, fuelNameOnly := "경유"
    }
    else if (InStr(ST_FuelType, "하이브리드"))
    {
        eff := 15.37, fuelNameOnly := "하이브리드"
    }
    else if (InStr(ST_FuelType, "LPG"))
    {
        eff := 8.83, fuelNameOnly := "LPG"
    }
    else if (InStr(ST_FuelType, "전기"))
    {
        eff := 5.22, effUnit := "km/kWh", fuelNameOnly := "전기"
    }
    else if (InStr(ST_FuelType, "수소"))
    {
        eff := 94.9, effUnit := "km/kg", fuelNameOnly := "수소"
    }

    fuelPriceUnit := "원/L"
    fuelSourceName := "오피넷"
    if (InStr(ST_FuelType, "전기"))
    {
        fuelPriceUnit := "원/kWh"
        fuelSourceName := "무공해차 통합누리집"
    }
    else if (InStr(ST_FuelType, "수소"))
    {
        fuelPriceUnit := "원/kg"
        fuelSourceName := "수소충전요금"
    }

    toll := SSOK_Travel_Floor10(ST_Toll)
    parking := SSOK_Travel_Floor10(ST_Parking)
    parkCap := days * 10000
    if (parking > parkCap)
        parking := parkCap

    if (ST_TransType1)
    {
        rawFuel := (eff > 0 ? (roundDist * price) / eff : 0)
        fuelCost := SSOK_Travel_Floor10(rawFuel)
        transportTotal := fuelCost + toll + parking
    }
    else if (ST_TransType2)
    {
        transportTotal := railGo + railVia + railBack + busGo + busVia + busBack + shipGo + shipVia + shipBack + airGo + airVia + airBack
    }
    else
    {
        transportTotal := 0
    }

    dailyRate := 25000
    if (ST_TransType3)
        dailyRate := 12500

    ; 교육훈련 일비 지급기준
    ; 합숙·기숙사: 출발일·도착일 100%, 중간일 0%
    ; 비합숙: 출발일·도착일 100%, 중간일 50%
    if (ST_TravelCategory2)
    {
        if (days <= 1)
            dailyTotal := dailyRate
        else
            dailyTotal := dailyRate * 2
    }
    else if (ST_TravelCategory3)
    {
        if (days <= 1)
            dailyTotal := dailyRate
        else
            dailyTotal := (dailyRate * 2) + (dailyRate * 0.5 * (days - 2))
    }
    else
    {
        dailyTotal := days * dailyRate
    }

    mealTotal := 0
    mealCapTotal := days * 25000
    if (ST_TravelCategory1)
    {
        mealCount := 0
        if (days <= 3)
        {
            if (RegExMatch(ST_MealOption, "(\d+)", mOptM))
                mealCount := mOptM1 + 0
        }
        else
            mealCount := SSOK_Travel_Number(ST_MealCount)

        mealTotal := SSOK_Travel_Floor10(SSOK_Travel_CalcMealCost(mealCount))
        if (mealTotal > mealCapTotal)
            mealTotal := mealCapTotal
    }
    else
        mealTotal := SSOK_Travel_Floor10(ST_MealActual)

    isNoCap := (InStr(ST_Rank, "교장") || InStr(ST_Rank, "교육전문직"))
    lodgingCap := SSOK_Travel_DetectLodgingCap(ST_Destination)
    lodgingCapTotal := lodgingCap * nights
    lodgingActual := SSOK_Travel_Floor10(ST_LodgingActual)
    lodgingTotal := 0
    if (nights > 0)
    {
        if (ST_TravelCategory2)
            lodgingTotal := lodgingActual
        else
            lodgingTotal := (isNoCap ? lodgingActual : (lodgingActual > lodgingCapTotal ? lodgingCapTotal : lodgingActual))
    }
    grandTotal := transportTotal + dailyTotal + mealTotal + lodgingTotal

    ; --------------------------------------------------------------------------
    ; 원문 조회 주소
    ; --------------------------------------------------------------------------
    sY := SubStr(sDate, 1, 4)
    sM := SubStr(sDate, 5, 2)
    sD := SubStr(sDate, 7, 2)
    opinetUrl := ""
    if (InStr(ST_FuelType, "전기") || InStr(ST_FuelType, "수소"))
        opinetUrl := "https://ev.or.kr/nportal/evcarInfo/initEvcarChargePriceV2.do"
    else if (InStr(ST_FuelType, "LPG"))
        opinetUrl := "https://www.opinet.co.kr/user/dopvsavsel/dopVsAvselSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_K015_P=Y"
    else
        opinetUrl := "https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_B027=Y&OIL_CD_D047=Y"

    naverUrl := ""
    if (ST_DepLon && ST_DepLat && ST_DestLon && ST_DestLat)
    {
        enc1 := SSOK_Travel_UriEncode(ST_DepName != "" ? ST_DepName : ST_Departure)
        enc2 := SSOK_Travel_UriEncode(ST_DestName != "" ? ST_DestName : ST_Destination)
        mode := (ST_TransType2 ? "transit" : "car")
        if (ST_ViaLon && ST_ViaLat)
        {
            encVia := SSOK_Travel_UriEncode(ST_ViaName != "" ? ST_ViaName : ST_Stopover)
            naverUrl := "https://map.naver.com/p/directions/" . ST_DepLon . "," . ST_DepLat . "," . enc1 . "/" . ST_ViaLon . "," . ST_ViaLat . "," . encVia . "/" . ST_DestLon . "," . ST_DestLat . "," . enc2 . "/-/" . mode . "?c=14.00,0,0,0,dh"
        }
        else
            naverUrl := "https://map.naver.com/p/directions/" . ST_DepLon . "," . ST_DepLat . "," . enc1 . "/" . ST_DestLon . "," . ST_DestLat . "," . enc2 . "/-/" . mode . "?c=14.00,0,0,0,dh"
    }

    ; --------------------------------------------------------------------------


    ; --------------------------------------------------------------------------
    ; 인쇄용 HTML - 정확히 3매 (A4 실물 규격 미리보기 및 인쇄)
    ; 1매: 여비 정산 신청서
    ; 2매: 붙임 1. 여비 산출내역 상세 (산출내역표 + 경로지도 + 공식 유가통계표)
    ; 3매: 증빙서류 첨부 (영수증 부착란)
    ; --------------------------------------------------------------------------
    destShort := ST_Departure . (hasVia ? " → " . ST_Stopover : "") . " → " . ST_Destination

    lodgingCapShow := (nights > 0 ? (isNoCap ? "실비 전액" : (lodgingCapTotal > 0 ? SSOK_Travel_Comma(lodgingCapTotal) . "원" : "-")) : "-")
    lodgingActShow := (lodgingActual > 0 ? SSOK_Travel_Comma(lodgingActual) . "원" : "0")

    mealCapShow := (mealCapTotal > 0 ? SSOK_Travel_Comma(mealCapTotal) . "원" : "")
    mealActShow := (mealTotal > 0 ? SSOK_Travel_Comma(mealTotal) . "원" : "0")

    ; 운임 행 생성 (도착지 폭 24%, 금액 폭 15%로 최적화하여 학교명 잘림 및 우측 짤림 방지)
    fareRowsHtml := ""
    if (ST_TransType1) ; 자가용
    {
        oneWayFuel := SSOK_Travel_Floor10(fuelCost / 2.0)
        returnFuel := fuelCost - oneWayFuel
        outboundFare := oneWayFuel
        returnFare := returnFuel
        tName := "자가용(" . fuelNameOnly . ")"

        destTarget := ST_Destination . (hasVia ? "<br><span style=""font-size:7.5pt;color:#444;"">(경유: " . ST_Stopover . ")</span>" : "")
        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . sDateStr . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . tName . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . destTarget . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (outboundFare > 0 ? SSOK_Travel_Comma(outboundFare) . "원" : "0원") . "</td>`n"
        fareRowsHtml .= "    </tr>`n"

        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . eDateStr . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . tName . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Destination . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (returnFare > 0 ? SSOK_Travel_Comma(returnFare) . "원" : "0원") . "</td>`n"
        fareRowsHtml .= "    </tr>`n"

        if (toll > 0 || parking > 0)
        {
            if (toll > 0 && parking > 0)
            {
                fareRowsHtml .= "    <tr>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">통행료</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . SSOK_Travel_Comma(toll) . "원</td>`n"
                fareRowsHtml .= "    </tr>`n"

                fareRowsHtml .= "    <tr>`n"
                fareRowsHtml .= "      <td>&nbsp;</td>`n"
                fareRowsHtml .= "      <td>주차료</td>`n"
                fareRowsHtml .= "      <td>&nbsp;</td>`n"
                fareRowsHtml .= "      <td>&nbsp;</td>`n"
                fareRowsHtml .= "      <td>-</td>`n"
                fareRowsHtml .= "      <td style=""text-align: right; padding-right: 8px;"">" . SSOK_Travel_Comma(parking) . "원</td>`n"
                fareRowsHtml .= "    </tr>`n"
            }
            else if (toll > 0)
            {
                fareRowsHtml .= "    <tr>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">통행료</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . SSOK_Travel_Comma(toll) . "원</td>`n"
                fareRowsHtml .= "    </tr>`n"

                fareRowsHtml .= "    <tr>`n"
                fareRowsHtml .= "      <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>`n"
                fareRowsHtml .= "    </tr>`n"
            }
            else
            {
                fareRowsHtml .= "    <tr>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">주차료</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
                fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . SSOK_Travel_Comma(parking) . "원</td>`n"
                fareRowsHtml .= "    </tr>`n"

                fareRowsHtml .= "    <tr>`n"
                fareRowsHtml .= "      <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>`n"
                fareRowsHtml .= "    </tr>`n"
            }
        }
        else
        {
            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td>`n"
            fareRowsHtml .= "    </tr>`n"
            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>`n"
            fareRowsHtml .= "    </tr>`n"
        }
    }
    else if (ST_TransType2) ; 대중교통
    {
        goFare := railGo + busGo + shipGo + airGo
        viaFare := railVia + busVia + shipVia + airVia
        backFare := railBack + busBack + shipBack + airBack

        goName := SSOK_Travel_GetTransitName(railGo, busGo, shipGo, airGo)
        viaName := SSOK_Travel_GetTransitName(railVia, busVia, shipVia, airVia)
        backName := SSOK_Travel_GetTransitName(railBack, busBack, shipBack, airBack)

        if (hasValidTransitVia && viaFare > 0)
        {
            viaPlace := ST_Stopover

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . sDateStr . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . goName . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . viaPlace . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (goFare > 0 ? SSOK_Travel_Comma(goFare) . "원" : "0원") . "</td>`n"
            fareRowsHtml .= "    </tr>`n"

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . sDateStr . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . viaName . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . viaPlace . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Destination . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (viaFare > 0 ? SSOK_Travel_Comma(viaFare) . "원" : "0원") . "</td>`n"
            fareRowsHtml .= "    </tr>`n"

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . eDateStr . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . backName . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Destination . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (backFare > 0 ? SSOK_Travel_Comma(backFare) . "원" : "0원") . "</td>`n"
            fareRowsHtml .= "    </tr>`n"

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>`n"
            fareRowsHtml .= "    </tr>`n"
        }
        else
        {
            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . sDateStr . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . goName . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Destination . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (goFare > 0 ? SSOK_Travel_Comma(goFare) . "원" : "0원") . "</td>`n"
            fareRowsHtml .= "    </tr>`n"

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . eDateStr . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . backName . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Destination . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (backFare > 0 ? SSOK_Travel_Comma(backFare) . "원" : "0원") . "</td>`n"
            fareRowsHtml .= "    </tr>`n"

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td>`n"
            fareRowsHtml .= "    </tr>`n"
            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>`n"
            fareRowsHtml .= "    </tr>`n"
        }
    }
    else
    {
        tName := (ST_TransType3 ? "관용차량" : "기타")
        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . sDateStr . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . tName . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Destination . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">0원</td>`n"
        fareRowsHtml .= "    </tr>`n"
        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td>`n"
        fareRowsHtml .= "    </tr>`n"
        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td><td class=""dashed-b"">&nbsp;</td>`n"
        fareRowsHtml .= "    </tr>`n"
        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>`n"
        fareRowsHtml .= "    </tr>`n"
    }

    ; 2페이지 상세 교통비 텍스트
    if (ST_TransType1)
    {
        if (price > 0)
            transportDetail := formulaStr
        else
            transportDetail := "유류비 : 조회자료 없음"
        if (toll > 0)
            transportDetail .= " + 통행료 " . SSOK_Travel_Comma(toll) . "원"
        if (parking > 0)
            transportDetail .= " + 주차료 " . SSOK_Travel_Comma(parking) . "원"
    }
    else if (ST_TransType2)
    {
        if (transportTotal > 0)
        {
            transportDetail := "대중교통 운임 " . SSOK_Travel_Comma(transportTotal) . "원"
            legDetails := ""
            if (goFare > 0)
                legDetails .= (legDetails != "" ? " + " : "") . "가는편 " . SSOK_Travel_Comma(goFare) . "원"
            if (hasValidTransitVia && viaFare > 0)
                legDetails .= (legDetails != "" ? " + " : "") . "경유지 " . SSOK_Travel_Comma(viaFare) . "원"
            if (backFare > 0)
                legDetails .= (legDetails != "" ? " + " : "") . "오는편 " . SSOK_Travel_Comma(backFare) . "원"
            if (legDetails != "")
                transportDetail .= " (" . legDetails . ")"
        }
        else
            transportDetail := "입력된 대중교통 운임 없음"
    }
    else if (ST_TransType3)
    {
        transportDetail := "관용차량·임차버스 운임 0원 (일비 50% 적용)"
    }
    else
    {
        transportDetail := "기타 운임 0원 (동행자 차량 이용 등)"
    }

    dailyRateText := SSOK_Travel_Comma(dailyRate)
    if (ST_TravelCategory2)
        dailyBasisText := (days <= 1 ? "출발일·도착일 100% (당일)" : "출발일·도착일 100%, 중간일 0%")
    else if (ST_TravelCategory3)
        dailyBasisText := (days <= 1 ? "출발일·도착일 100% (당일)" : "출발일·도착일 100%, 중간일 50%")
    else
        dailyBasisText := days . "일 × " . dailyRateText . "원"
    if (ST_TransType3)
        dailyBasisText .= " (관용차량·임차버스: 기준 일비 50%)"
    else if (!ST_TravelCategory2 && !ST_TravelCategory3)
        dailyBasisText .= " (기준단가)"
    mealBasisText := (mealTotal > 0 ? "실제 소요액 및 지급한도 적용 (" . SSOK_Travel_Comma(mealTotal) . "원)" : "해당없음 (0원)")
    lodgingBasisText := (nights > 0 ? nights . "박 × 지급한도 내 실소요액 (" . SSOK_Travel_Comma(lodgingTotal) . "원)" : "해당없음 (당일 출장)")

    FormatTime, todayY, %A_Now%, yyyy
    FormatTime, todayM, %A_Now%, MM
    FormatTime, todayD, %A_Now%, dd

    ; 좌표가 미확보된 상태라면 출력 전 자동 보정 조회 (지도 및 거리 표시 보장)
    if (ST_DepLat = 0 || ST_DepLon = 0)
    {
        tLon := 0, tLat := 0, tName := ""
        if (SSOK_Travel_GetCoords(ST_Departure, tLon, tLat, tName))
            ST_DepLon := tLon, ST_DepLat := tLat, ST_DepName := tName
    }
    if (ST_DestLat = 0 || ST_DestLon = 0)
    {
        tLon := 0, tLat := 0, tName := ""
        if (SSOK_Travel_GetCoords(ST_Destination, tLon, tLat, tName))
            ST_DestLon := tLon, ST_DestLat := tLat, ST_DestName := tName
    }
    if (hasVia && (ST_ViaLat = 0 || ST_ViaLon = 0))
    {
        tLon := 0, tLat := 0, tName := ""
        if (SSOK_Travel_GetCoords(ST_Stopover, tLon, tLat, tName))
            ST_ViaLon := tLon, ST_ViaLat := tLat, ST_ViaName := tName
    }

    depLatVal := (ST_DepLat ? ST_DepLat : 0)
    depLonVal := (ST_DepLon ? ST_DepLon : 0)
    destLatVal := (ST_DestLat ? ST_DestLat : 0)
    destLonVal := (ST_DestLon ? ST_DestLon : 0)
    viaLatVal := (ST_ViaLat ? ST_ViaLat : 0)
    viaLonVal := (ST_ViaLon ? ST_ViaLon : 0)

    encDep := SSOK_Travel_UriEncode(ST_Departure)
    encDest := SSOK_Travel_UriEncode(ST_Destination)
    naverMapLink := "https://map.naver.com/p/directions/" . depLonVal . "," . depLatVal . "," . encDep . "/" . destLonVal . "," . destLatVal . "," . encDest . "/-/car"
    kakaoMapLink := "https://map.kakao.com/link/to/" . encDest . "," . destLatVal . "," . destLonVal

    html := "<!DOCTYPE html>`n<html lang=""ko"">`n<head>`n<meta charset=""utf-8"">`n"
    html .= "<title>여비 정산 신청서 - " . ST_Name . "</title>`n"
    html .= "<link rel=""shortcut icon"" href=""ssok.ico"" type=""image/x-icon"">`n"
    if (ST_TransType1)
    {
        kakaoKey := "7cc8832f2613effed8fddca0381fb4cf"
        IniRead, savedKakaoKey, %SSOK_Ini%, Kakao, JavaScriptKey, %kakaoKey%
        if (savedKakaoKey != "" && savedKakaoKey != "ERROR")
            kakaoKey := savedKakaoKey
        else
            IniWrite, %kakaoKey%, %SSOK_Ini%, Kakao, JavaScriptKey

        html .= "<script type=""text/javascript"" src=""https://dapi.kakao.com/v2/maps/sdk.js?appkey=" . kakaoKey . "&autoload=false""></script>`n"
    }
    html .= "<style>`n"
    html .= "  @page { size: A4 portrait; margin: 8mm 12mm; }`n"
    html .= "  * { box-sizing: border-box; }`n"
    html .= "  body { background-color: #525659; margin: 0; padding: 20px 0 40px 0; font-family: 'Malgun Gothic', '맑은 고딕', Dotum, sans-serif; font-size: 9pt; color: #000; -webkit-print-color-adjust: exact; print-color-adjust: exact; }`n"
    html .= "  .no-print { text-align: center; margin-bottom: 18px; }`n"
    html .= "  .btn-print { background-color: #0b4a8b; color: #ffffff; font-size: 14.5px; font-weight: bold; padding: 9px 24px; border: none; border-radius: 4px; cursor: pointer; box-shadow: 0 2px 6px rgba(0,0,0,0.35); }`n"
    html .= "  .btn-print:hover { background-color: #083462; }`n"
    html .= "  .btn-close { background-color: #6c757d; color: #ffffff; font-size: 14.5px; padding: 9px 16px; border: none; border-radius: 4px; cursor: pointer; margin-left: 8px; }`n"
    html .= "  .page-box { background: #ffffff; width: 210mm; height: 280mm; min-height: 280mm; max-height: 282mm; margin: 0 auto 25px auto; padding: 12mm 14mm; box-shadow: 0 4px 15px rgba(0,0,0,0.35); position: relative; overflow: hidden; }`n"
    html .= "  .title { text-align: center; font-size: 19pt; font-weight: bold; letter-spacing: 5px; margin: 0 0 6mm 0; color: #000; }`n"
    html .= "  .sub-title { text-align: center; font-size: 15pt; font-weight: bold; letter-spacing: 2px; margin: 0 0 4mm 0; color: #000; }`n"
    html .= "  table { border-collapse: collapse; width: 100%; table-layout: fixed; }`n"
    html .= "  table.main-tbl { border: 1.5px solid #000; margin-bottom: 4mm; }`n"
    html .= "  table.main-tbl th, table.main-tbl td { border: 1px solid #000; padding: 5.5px 3px; font-size: 9pt; text-align: center; vertical-align: middle; word-break: break-all; line-height: 1.25; }`n"
    html .= "  table.main-tbl th { background-color: #ffffff; font-weight: normal; }`n"
    html .= "  .dashed-b { border-bottom: 1px dotted #555 !important; }`n"
    html .= "  .dashed-r { border-right: 1px dotted #555 !important; }`n"
    html .= "  .solid-r { border-right: 1px solid #000 !important; }`n"
    html .= "  .right { text-align: right !important; padding-right: 3mm !important; }`n"
    html .= "  .sign-area { margin-top: 5mm; text-align: center; line-height: 1.9; font-size: 9.5pt; }`n"
    html .= "  .foot-area { margin-top: 4mm; font-size: 7.2pt; line-height: 1.45; border-top: 1px solid #888; padding-top: 2mm; color: #111; }`n"
    html .= "  table.detail-tbl { border: 1.2px solid #000; margin-bottom: 3.5mm; }`n"
    html .= "  table.detail-tbl th, table.detail-tbl td { border: 1px solid #000; padding: 4.5px 5px; font-size: 8.5pt; line-height: 1.25; }`n"
    html .= "  table.detail-tbl th { background-color: #f5f7fa; font-weight: bold; text-align: center; }`n"
    html .= "  .sec-header { font-size: 10pt; font-weight: bold; margin: 3.5mm 0 1.5mm 0; border-left: 3.5px solid #1a365d; padding-left: 6px; color: #1a365d; }`n"
    html .= "  .status-box { border: 1px solid #999; background: #f8fafc; padding: 2mm 3mm; font-size: 8.3pt; line-height: 1.45; margin-bottom: 2mm; }`n"
    html .= "  .map-box { width: 100%; height: 65mm; border: 1px solid #888; border-radius: 2px; position: relative; top: 0; margin-top: 1mm; margin-bottom: 3mm; }`n"
    html .= "  .cert-box { border: 1.5px solid #1a365d; background: #ffffff; padding: 2.5mm 3.5mm; margin-top: 1mm; position: relative; border-radius: 2px; box-shadow: inset 0 0 0 1px #d0d7de; }`n"
    html .= "  .cert-title-row { display: flex; justify-content: space-between; align-items: flex-end; border-bottom: 1.5px solid #1a365d; padding-bottom: 1.2mm; margin-bottom: 1.8mm; }`n"
    html .= "  .cert-title { font-size: 10pt; font-weight: bold; color: #1a365d; letter-spacing: 0.5px; }`n"
    html .= "  .cert-meta { font-size: 7.2pt; color: #555; text-align: right; line-height: 1.3; }`n"
    html .= "  .cert-tbl { width: 100%; border-collapse: collapse; margin-bottom: 1.8mm; }`n"
    html .= "  .cert-tbl th, .cert-tbl td { border: 1px solid #b0bec5; padding: 3.5px 5px; font-size: 8pt; text-align: center; }`n"
    html .= "  .cert-tbl th { background: #f0f4f9; color: #1a365d; font-weight: bold; }`n"
    html .= "  .cert-tbl tr.active-fuel { background: #eaf2fc !important; font-weight: bold; }`n"
    html .= "  .attach-box { height: 232mm; border: 1.5px dashed #777; display: flex; align-items: center; justify-content: center; color: #666; font-size: 11pt; background: #fafafa; margin-top: 3mm; text-align: center; line-height: 1.8; }`n"
    html .= "  @media print {`n"
    html .= "    body { background: none !important; padding: 0 !important; }`n"
    html .= "    .no-print { display: none !important; }`n"
    html .= "    .page-box { width: 100% !important; height: 275mm !important; min-height: auto !important; max-height: 275mm !important; margin: 0 !important; padding: 20mm 0 0 0 !important; border: none !important; box-shadow: none !important; page-break-after: always !important; }`n"
    html .= "    .page-box.one-page-form { display: flex !important; flex-direction: column !important; }`n"
    html .= "    .page-box:last-child { page-break-after: avoid !important; }`n"
    html .= "    .map-box { width: 100% !important; height: 65mm !important; top: 0 !important; margin-top: 1mm !important; margin-bottom: 3mm !important; }`n"
    html .= "  }`n"
    html .= "</style>`n</head>`n<body>`n"

    ; 화면 상단 툴바
    pageInfoNotice := (ST_TransType1 ? "1매: 신청서 / 2매: 산출내역 및 지도·유가 / 3매: 증빙서류" : (ST_TransType2 ? "1매: 신청서 / 2매: 산출내역 및 영수증 증빙부착란" : "1매: 여비 정산 신청서 (산출내역 포함 1부 출력)"))
    html .= "<div class=""no-print"">`n"
    html .= "  <button class=""btn-print"" onclick=""window.print()"">🖨️ 여비 정산 신청서 인쇄하기 (Ctrl+P)</button>`n"
    html .= "  <button class=""btn-close"" onclick=""window.close()"">닫기</button>`n"
    html .= "  <div style=""margin-top: 6px; font-size: 11.5px; color: #eee;"">※ 화면의 A4 규격 모습 그대로 인쇄됩니다. (" . pageInfoNotice . ")</div>`n"
    html .= "</div>`n"

    ; ==========================================================================
    ; 1매 : 여비 정산 신청서
    ; ==========================================================================
    html .= "<div class=""page-box""" . (ST_TransType3 || ST_TransType4 ? " one-page-form" : "") . ">`n"
    html .= "  <div class=""title"">여비 정산 신청서</div>`n"
    html .= "  <table class=""main-tbl"">`n"
    html .= "    <colgroup>`n"
    html .= "      <col style=""width: 9%;"">`n"
    html .= "      <col style=""width: 13%;"">`n"
    html .= "      <col style=""width: 15%;"">`n"
    html .= "      <col style=""width: 16%;"">`n"
    html .= "      <col style=""width: 24%;"">`n"
    html .= "      <col style=""width: 8%;"">`n"
    html .= "      <col style=""width: 15%;"">`n"
    html .= "    </colgroup>`n"
    html .= "    <tr>`n"
    html .= "      <th>소 &nbsp; 속</th>`n"
    html .= "      <td colspan=""2"">" . ST_Org . "</td>`n"
    html .= "      <th>직 &nbsp; 급<br>(직위)</th>`n"
    html .= "      <td>" . ST_Rank . "</td>`n"
    html .= "      <th>성 &nbsp; 명</th>`n"
    html .= "      <td>" . ST_Name . "</td>`n"
    html .= "    </tr>`n"
    html .= "    <tr>`n"
    html .= "      <th rowspan=""2"">출 &nbsp; 장<br>(부임)<br>일 &nbsp; 정</th>`n"
    html .= "      <th class=""dashed-b dashed-r"">일 &nbsp; 시</th>`n"
    html .= "      <td colspan=""5"" class=""dashed-b"">" . sYear . "년 &nbsp; " . sMonth . "월 " . sDay . "일 &nbsp; ~ &nbsp; " . eYear . "년 &nbsp; " . eMonth . "월 &nbsp; " . eDay . "일</td>`n"
    html .= "    </tr>`n"
    html .= "    <tr>`n"
    html .= "      <th class=""dashed-r"">출장(부임)지</th>`n"
    html .= "      <td colspan=""5"">" . destShort . "</td>`n"
    html .= "    </tr>`n"
    html .= "    <tr>`n"
    html .= "      <th>숙박비</th>`n"
    html .= "      <th class=""dashed-r"">상한액 또는<br>지급받은 선금</th>`n"
    html .= "      <td class=""solid-r"">" . lodgingCapShow . "</td>`n"
    html .= "      <th class=""dashed-r"">실제<br>소요액</th>`n"
    html .= "      <td class=""solid-r"">" . lodgingActShow . "</td>`n"
    html .= "      <th colspan=""2"">초과지출<br>사 &nbsp; 유</th>`n"
    html .= "    </tr>`n"
    html .= "    <tr>`n"
    html .= "      <th>식 &nbsp; 비</th>`n"
    html .= "      <th class=""dashed-r"">지급받은 금액</th>`n"
    html .= "      <td class=""solid-r"">" . mealCapShow . "</td>`n"
    html .= "      <th class=""dashed-r"">실제<br>소요액</th>`n"
    html .= "      <td class=""solid-r"">" . mealActShow . "</td>`n"
    html .= "      <th colspan=""2"">초과지출<br>사 &nbsp; 유</th>`n"
    html .= "    </tr>`n"
    html .= "    <tr>`n"
    html .= "      <th rowspan=""5"">운 &nbsp; 임</th>`n"
    html .= "      <th>일 &nbsp; 자</th>`n"
    html .= "      <th>교통편</th>`n"
    html .= "      <th>출발지</th>`n"
    html .= "      <th>도착지</th>`n"
    html .= "      <th>등 &nbsp; 급</th>`n"
    html .= "      <th>금 &nbsp; 액</th>`n"
    html .= "    </tr>`n"
    html .= fareRowsHtml
    html .= "  </table>`n"

    ; 상세 산출내역 테이블 공통 HTML
    if (ST_TravelCategory1)
        travelCategoryText := "일반출장"
    else if (ST_TravelCategory2)
        travelCategoryText := "교육훈련(합숙·기숙사)"
    else
        travelCategoryText := "교육훈련(비합숙)"

    detailTblHtml := "  <table class=""detail-tbl"">`n"
    detailTblHtml .= "    <colgroup><col style=""width:16%""><col style=""width:64%""><col style=""width:20%""></colgroup>`n"
    detailTblHtml .= "    <tr><th>구 &nbsp; 분</th><th>산 &nbsp; 출 &nbsp; 내 &nbsp; 용</th><th>금 &nbsp; 액</th></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc;"">교통비</th><td>" . transportDetail . "</td><td class=""right"" style=""font-weight:bold;"">" . SSOK_Travel_Comma(transportTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc;"">일 &nbsp; 비</th><td>" . dailyBasisText . "</td><td class=""right"" style=""font-weight:bold;"">" . SSOK_Travel_Comma(dailyTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc;"">식 &nbsp; 비</th><td>" . mealBasisText . "</td><td class=""right"" style=""font-weight:bold;"">" . SSOK_Travel_Comma(mealTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc;"">숙박비</th><td>" . lodgingBasisText . "</td><td class=""right"" style=""font-weight:bold;"">" . SSOK_Travel_Comma(lodgingTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr style=""background:#f0f4fb;""><th colspan=""2"" style=""text-align:center;font-size:9pt;font-weight:bold;"">합 &nbsp; 계</th><td class=""right"" style=""font-weight:bold;color:#0b4a8b;font-size:9.5pt;"">" . SSOK_Travel_Comma(grandTotal) . "원</td></tr>`n"
    detailTblHtml .= "  </table>`n"

    if (ST_TransType3 || ST_TransType4)
    {
        ; 관용차량 및 기타 차량: 증빙서류 부착 불필요, 산출내역을 신청서 하단에 배치하여 1매 출력
        html .= "    <div class=""sign-area"" style=""margin-top: 3mm; line-height: 1.65;"">`n"
        html .= "      「공무원여비규정」 제16조 제1항·제2항에 의하여 위와 같이 여비의 정산을 신청합니다.<br>`n"
        html .= "      첨 &nbsp; 부 : 여비 산출내역 1부 (하단 기재)<br>`n"
        html .= "      <div style=""letter-spacing: 2px;"">" . todayY . "년 &nbsp;&nbsp;&nbsp;&nbsp; 월 &nbsp;&nbsp;&nbsp;&nbsp; 일</div>`n"
        html .= "      <div style=""text-align: right; padding-right: 25px; margin-top: 2mm;"">`n"
        html .= "        신 &nbsp; 청 &nbsp; 인 &nbsp;&nbsp;&nbsp;&nbsp; 성 &nbsp; 명 &nbsp;&nbsp;&nbsp;&nbsp; <b style=""font-size: 11pt;"">" . ST_Name . "</b> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (인)`n"
        html .= "      </div>`n"
        html .= "    </div>`n"

        html .= "    <div class=""foot-area"" style=""margin-top: 2.5mm; margin-bottom: 2mm; line-height: 1.55; font-size: 8.5pt;"">`n"
        html .= "      <div>※ 정산하는 여비항목 중 식비와 준비금은 국외여행에 한하며, 숙박비는 국내여행에 한함(국외여행의 숙박비는 별지 제7호 서식 사용)</div>`n"
        html .= "      <div>※ 정산하는 여비항목 중 운임은 국내여행에 한함. 다만, 국내·외 항공운임은 별지 제6호 서식에 의함</div>`n"
        html .= "      <div style=""font-weight:bold;"">※ <b>부득이한 사유에 따른 자가용 이용 운임 정산시 교통편에 차량 유류 종류(경유, 휘발유, LPG 등) 기재</b></div>`n"
        html .= "      <div style=""border-top: 1px solid #888; margin-top: 2mm; padding-top: 1.5mm; text-align: right;"">여비 산출내역 참조</div>`n"
        html .= "    </div>`n"

        html .= "    <div style=""margin-top: 4mm;"">`n"
        html .= "      <div class=""sec-header"" style=""margin-top: 2mm; margin-bottom: 1.5mm; display:flex; justify-content:space-between; align-items:flex-end;""><span>[붙임] 여비 산출내역</span><span style=""font-size:9pt; font-weight:normal;"">(출장구분: " . travelCategoryText . ")</span></div>`n"
        html .= detailTblHtml
        html .= "    </div>`n"
        html .= "  </div>`n"
    }
    else
    {
        html .= "  <div class=""sign-area"">`n"
        html .= "    「공무원여비규정」 제16조 제1항·제2항에 의하여 관계서류를 첨부하여 위와 같이 여비의 정산을 신청합니다.<br>`n"
        html .= "    첨 &nbsp; 부 : 신용카드 매출전표 등 1부<br><br>`n"
        html .= "    <div style=""letter-spacing: 2px;"">" . todayY . "년 &nbsp;&nbsp;&nbsp;&nbsp; 월 &nbsp;&nbsp;&nbsp;&nbsp; 일</div><br>`n"
        html .= "    <div style=""text-align: right; padding-right: 25px;"">`n"
        html .= "      신 &nbsp; 청 &nbsp; 인 &nbsp;&nbsp;&nbsp;&nbsp; 성 &nbsp; 명 &nbsp;&nbsp;&nbsp;&nbsp; <b style=""font-size: 11pt;"">" . ST_Name . "</b> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (인)`n"
        html .= "    </div>`n"
        html .= "  </div>`n"
        html .= "  <div class=""foot-area"">`n"
        html .= "    ※ 정산하는 여비항목 중 식비와 준비금은 국외여행에 한하며, 숙박비는 국내여행에 한함(국외여행의 숙박비는 별지 제7호 서식 사용)<br>`n"
        html .= "    ※ 정산하는 여비항목 중 운임은 국내여행에 한함. 다만, 국내·외 항공운임은 별지 제6호 서식에 의함<br>`n"
        html .= "    <b>★ 부득이한 사유에 따른 자가용 이용 운임 정산시 교통편에 차량 유류 종류(경유, 휘발유, LPG 등) 기재</b>`n"
        html .= "  </div>`n"
        html .= "</div>`n"

        ; ==========================================================================
        ; 2매 : 붙임 1. 여비 산출내역 상세
        ; ==========================================================================
        html .= "<div class=""page-box"">`n"
        html .= "  <div class=""sub-title"" style=""display:flex; justify-content:space-between; align-items:flex-end;""><span>붙임 1. 여비 산출내역</span><span style=""font-size:9pt; font-weight:normal;"">(출장구분: " . travelCategoryText . ")</span></div>`n"
        html .= detailTblHtml

    if (ST_TransType1)
    {
        ; 경로 지도 (출발지, 도착지, 거리 명시 및 외부 길찾기 연동)
    html .= "  <div class=""sec-header"">출장 경로 지도</div>`n"
    html .= "  <div class=""status-box"" style=""display:flex;justify-content:space-between;align-items:center;"">`n"
    html .= "    <div>• <b>출장 경로:</b> " . ST_Departure . (hasVia ? " → " . ST_Stopover : "") . " → " . ST_Destination . "　/　<b>편도 거리:</b> " . SSOK_Travel_FormatDist(displayOneWayDist) . " km (왕복: " . SSOK_Travel_FormatDist(roundDist) . " km)</div>`n"
    html .= "    <div class=""no-print"" style=""font-size:8pt;""><a href=""" . naverMapLink . """ target=""_blank"" style=""color:#03c75a;font-weight:bold;text-decoration:none;margin-right:8px;"">[네이버 길찾기]</a><a href=""" . kakaoMapLink . """ target=""_blank"" style=""color:#392020;font-weight:bold;text-decoration:none;"">[카카오 길찾기]</a></div>`n"
    html .= "  </div>`n"
    html .= "  <div id=""route-map"" class=""map-box""></div>`n"

    ; 유가·전기차 충전요금 기준표
    html .= "  <div class=""sec-header"">유가·충전요금 기준표</div>`n"
    html .= "  <div class=""cert-box"">`n"
    html .= "    <div class=""cert-title-row"">`n"
    if (InStr(ST_FuelType, "전기"))
    {
        html .= "      <div class=""cert-title"">공공충전시설 충전요금 기준</div>`n"
        html .= "      <div class=""cert-meta"">기준일자: " . sYear . "년 " . sMonth . "월 " . sDay . "일　|　출처: 환경부 무공해차 통합누리집</div>`n"
    }
    else if (InStr(ST_FuelType, "수소"))
    {
        html .= "      <div class=""cert-title"">수소충전소 고시 기준</div>`n"
        html .= "      <div class=""cert-meta"">기준일자: " . sYear . "년 " . sMonth . "월 " . sDay . "일　|　출처: 무공해차 통합누리집</div>`n"
    }
    else
    {
        html .= "      <div class=""cert-title"">국내 유가 통계 기준 (전국 주유소 평균)</div>`n"
        html .= "      <div class=""cert-meta"">조회일자: " . sYear . "년 " . sMonth . "월 " . sDay . "일　|　출처: 한국석유공사 오피넷</div>`n"
    }
    html .= "    </div>`n"

    if (InStr(ST_FuelType, "전기"))
    {
        html .= "    <table class=""cert-tbl"">"
        html .= "      <colgroup><col style=""width:32%""><col style=""width:26%""><col style=""width:42%""></colgroup>"
        html .= "      <tr><th>충전기 출력 구분</th><th>기준 단가</th><th>비고 및 시설 구분</th></tr>"
        html .= "      <tr><td>30kW 미만 (완속)</td><td class=""right"">295.0원/kWh</td><td>공동주택 및 완속 충전시설</td></tr>"
        html .= "      <tr><td>30kW 이상 ~ 50kW 미만</td><td class=""right"">307.2원/kWh</td><td>중속 급속충전기</td></tr>"
        html .= "      <tr><td>50kW 이상 ~ 100kW 미만</td><td class=""right"">325.6원/kWh</td><td>표준 급속충전시설</td></tr>"
        html .= "      <tr><td>100kW 이상 ~ 200kW 미만</td><td class=""right"">348.4원/kWh</td><td>초고속 충전기</td></tr>"
        html .= "      <tr><td>200kW 이상 (초급속)</td><td class=""right"">393.1원/kWh</td><td>초급속 집중충전시설</td></tr>"
        html .= "    </table>"
        html .= "    <div style=""font-size:7.4pt;color:#555;margin-top:1.5mm;line-height:1.4;"">※ 적용근거: 공무원 여비업무 처리기준 (출장자는 충전기 출력 구분에 따른 실제 적용단가로 정산)</div>`n"
    }
    else if (InStr(ST_FuelType, "수소"))
    {
        valHyd := (price > 0 ? price : 9900)
        priceHydStr := SSOK_Travel_FormatFuelPrice(valHyd) . " 원/kg"
        html .= "    <table class=""cert-tbl"">"
        html .= "      <colgroup><col style=""width:28%""><col style=""width:24%""><col style=""width:26%""><col style=""width:22%""></colgroup>"
        html .= "      <tr><th>구 &nbsp; 분</th><th>공인 기준연비</th><th>적용 충전단가</th><th>비 &nbsp; 고</th></tr>"
        html .= "      <tr class=""active-fuel""><td>수소전기차</td><td>94.9 km/kg</td><td class=""right""><b>" . priceHydStr . "</b></td><td><b style=""color:#0b4a8b;"">신청유종 (적용)</b></td></tr>"
        html .= "    </table>"
        html .= "    <div style=""font-size:7.4pt;color:#555;margin-top:1.5mm;line-height:1.4;"">※ 적용근거: 「공무원 여비업무 처리기준」 [별표 1] (수소차 공인연비 94.9 km/kg, 단가는 H2NTIS 공시단가 또는 실제 충전소 영수증 확인 정산)</div>`n"
    }
    else
    {
        ; 전체 유종 단가 일괄 조회 (보통휘발유, 자동차용경유, LPG, 하이브리드)
        valGas := SSOK_Travel_GetCachedOrFetchFuelPrice("휘발유", sDate)
        valDie := SSOK_Travel_GetCachedOrFetchFuelPrice("경유", sDate)
        valLpg := SSOK_Travel_GetCachedOrFetchFuelPrice("LPG", sDate)
        valHyb := valGas ; 하이브리드는 보통휘발유 단가 적용

        isGas := (InStr(ST_FuelType, "휘발유") && !InStr(ST_FuelType, "하이브리드"))
        isDie := InStr(ST_FuelType, "경유")
        isLpg := InStr(ST_FuelType, "LPG")
        isHyb := InStr(ST_FuelType, "하이브리드")

        ; 사용자가 화면에서 단가를 직접 수정한 경우(price 변수), 선택된 유종의 단가는 사용자가 수정한 price를 우선 적용
        if (price > 0)
        {
            if (isGas)
                valGas := price
            else if (isDie)
                valDie := price
            else if (isLpg)
                valLpg := price
            else if (isHyb)
                valHyb := price
        }

        rowGas := (isGas ? " class=""active-fuel""" : "")
        rowDie := (isDie ? " class=""active-fuel""" : "")
        rowLpg := (isLpg ? " class=""active-fuel""" : "")
        rowHyb := (isHyb ? " class=""active-fuel""" : "")

        noteGas := (isGas ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        noteDie := (isDie ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        noteLpg := (isLpg ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        noteHyb := (isHyb ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")

        priceGasStr := (valGas > 0 ? SSOK_Travel_FormatFuelPrice(valGas) . " 원/L" : "조회자료 없음")
        priceDieStr := (valDie > 0 ? SSOK_Travel_FormatFuelPrice(valDie) . " 원/L" : "조회자료 없음")
        priceLpgStr := (valLpg > 0 ? SSOK_Travel_FormatFuelPrice(valLpg) . " 원/L" : "조회자료 없음")
        priceHybStr := (valHyb > 0 ? SSOK_Travel_FormatFuelPrice(valHyb) . " 원/L" : "조회자료 없음")

        if (isGas)
            priceGasStr := "<b>" . priceGasStr . "</b>"
        if (isDie)
            priceDieStr := "<b>" . priceDieStr . "</b>"
        if (isLpg)
            priceLpgStr := "<b>" . priceLpgStr . "</b>"
        if (isHyb)
            priceHybStr := "<b>" . priceHybStr . "</b>"

        html .= "    <table class=""cert-tbl"">"
        html .= "      <colgroup><col style=""width:28%""><col style=""width:24%""><col style=""width:26%""><col style=""width:22%""></colgroup>"
        html .= "      <tr><th>유 &nbsp; 종</th><th>공인 기준연비</th><th>공시 판매가격 (단가)</th><th>비 &nbsp; 고</th></tr>"
        html .= "      <tr" . rowGas . "><td>보통휘발유</td><td>11.97 km/L</td><td class=""right"">" . priceGasStr . "</td><td>" . noteGas . "</td></tr>"
        html .= "      <tr" . rowDie . "><td>자동차용경유</td><td>12.52 km/L</td><td class=""right"">" . priceDieStr . "</td><td>" . noteDie . "</td></tr>"
        html .= "      <tr" . rowLpg . "><td>자동차용부탄(LPG)</td><td>8.83 km/L</td><td class=""right"">" . priceLpgStr . "</td><td>" . noteLpg . "</td></tr>"
        html .= "      <tr" . rowHyb . "><td>하이브리드(휘발유)</td><td>15.37 km/L</td><td class=""right"">" . priceHybStr . "</td><td>" . noteHyb . "</td></tr>"
        html .= "    </table>"
        html .= "    <div style=""font-size:7.4pt;color:#555;margin-top:1.5mm;line-height:1.4;"">※ 적용근거: 「공무원 여비규정」 및 공무원 여비업무 처리기준 [별표 1] (출장일자 기준 전국 주유소 평균 판매가격)</div>`n"
    }
    html .= "  </div>`n"
    html .= "</div>`n"

    ; ==========================================================================
    ; 3매 : 증빙서류 첨부
    ; ==========================================================================
    html .= "<div class=""page-box"">`n"
    html .= "  <div class=""sub-title"">증빙서류 첨부</div>`n"
    html .= "  <div class=""status-box"">소속: " . ST_Org . "　|　직급: " . ST_Rank . "　|　성명: " . ST_Name . "　|　출장일: " . sDateStr . " ~ " . eDateStr . "</div>`n"
    html .= "  <div class=""attach-box"">`n"
    html .= "    여비 정산 증빙서류 부착란<br><br>`n"
    html .= "    <span style=""font-size:9.5pt;color:#888;"">숙박비, 고속도로 통행료·주차료 영수증(신용카드 매출전표) 등 관련 증빙 원본을 부착하세요.</span>`n"
    html .= "  </div>`n"
    html .= "</div>`n"

    ; 카카오맵 렌더링 스크립트 (카카오 지도 공식 연동)
    html .= "<script>`n"
    html .= "  try {`n"
    html .= "    var depLat = " . depLatVal . ";`n"
    html .= "    var depLon = " . depLonVal . ";`n"
    html .= "    var destLat = " . destLatVal . ";`n"
    html .= "    var destLon = " . destLonVal . ";`n"
    html .= "    var viaLat = " . viaLatVal . ";`n"
    html .= "    var viaLon = " . viaLonVal . ";`n"
    html .= "    var depName = """ . ST_Departure . """;`n"
    html .= "    var destName = """ . ST_Destination . """;`n"
    html .= "    var viaName = """ . (hasVia ? ST_Stopover : "") . """;`n"
    html .= "    if (typeof kakao !== 'undefined' && kakao.maps && depLat && destLat) {`n"
    html .= "      kakao.maps.load(function() {`n"
    html .= "        var container = document.getElementById('route-map');`n"
    html .= "        var midLat = (depLat + destLat) / 2.0;`n"
    html .= "        var midLon = (depLon + destLon) / 2.0;`n"
    html .= "        if (viaLat && viaLon) { midLat = (depLat + viaLat + destLat) / 3.0; midLon = (depLon + viaLon + destLon) / 3.0; }`n"
    html .= "        var map = new kakao.maps.Map(container, { center: new kakao.maps.LatLng(midLat, midLon), level: 8 });`n"
    html .= "        var bounds = new kakao.maps.LatLngBounds();`n"
    html .= "        var pStart = new kakao.maps.LatLng(depLat, depLon);`n"
    html .= "        var pDest = new kakao.maps.LatLng(destLat, destLon);`n"
    html .= "        var mStart = new kakao.maps.Marker({ position: pStart, map: map });`n"
    html .= "        bounds.extend(pStart);`n"
    html .= "        var iwStart = new kakao.maps.InfoWindow({ position: pStart, content: '<div style=""padding:3px 6px;font-size:13px;font-weight:bold;color:#0b4a8b;white-space:nowrap;"">🚩 출발: ' + depName + '</div>' });`n"
    html .= "        iwStart.open(map, mStart);`n"
    html .= "        var path = [pStart];`n"
    html .= "        if (viaLat && viaLon) {`n"
    html .= "          var pVia = new kakao.maps.LatLng(viaLat, viaLon);`n"
    html .= "          var mVia = new kakao.maps.Marker({ position: pVia, map: map });`n"
    html .= "          bounds.extend(pVia);`n"
    html .= "          var iwVia = new kakao.maps.InfoWindow({ position: pVia, content: '<div style=""padding:3px 6px;font-size:13px;font-weight:bold;color:#1a365d;white-space:nowrap;"">📍 경유: ' + viaName + '</div>' });`n"
    html .= "          iwVia.open(map, mVia);`n"
    html .= "          path.push(pVia);`n"
    html .= "        }`n"
    html .= "        var mDest = new kakao.maps.Marker({ position: pDest, map: map });`n"
    html .= "        bounds.extend(pDest);`n"
    html .= "        var iwDest = new kakao.maps.InfoWindow({ position: pDest, content: '<div style=""padding:3px 6px;font-size:13px;font-weight:bold;color:#c92a2a;white-space:nowrap;"">🏁 도착: ' + destName + '</div>' });`n"
    html .= "        iwDest.open(map, mDest);`n"
    html .= "        path.push(pDest);`n"
    html .= "        var polyline = new kakao.maps.Polyline({ path: path, strokeWeight: 4, strokeColor: '#0b4a8b', strokeOpacity: 0.85, strokeStyle: 'solid' });`n"
    html .= "        polyline.setMap(map);`n"
    html .= "        map.setBounds(bounds);`n"
    html .= "      });`n"
    html .= "    } else {`n"
    html .= "      throw new Error('Kakao Maps API uninitialized');`n"
    html .= "    }`n"
    html .= "  } catch(e) {`n"
    html .= "    document.getElementById('route-map').innerHTML = '<div style=""display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;background:#f4f7fb;color:#333;font-size:9.5pt;border:1px dashed #90a4ae;padding:3mm;text-align:center;""><b>🗺️ 출장 경로 안내 (카카오맵 연동)</b><div style=""margin-top:2mm;font-size:9pt;color:#1a365d;""><b>' + depName + '</b>' + (viaName ? ' → <b>' + viaName + '</b>' : '') + ' → <b>' + destName + '</b></div><div style=""margin-top:1.5mm;font-size:8pt;color:#666;"">(편도 약 " . SSOK_Travel_FormatDist(displayOneWayDist) . " km / 왕복 " . SSOK_Travel_FormatDist(roundDist) . " km)</div><div style=""margin-top:2mm;font-size:7.5pt;color:#888;"">※ 카카오 디벨로퍼스(developers.kakao.com)에서 [카카오맵] 활성화(ON) 설정 시 정식 지도가 즉시 표시됩니다.</div></div>';`n"
    html .= "  }`n"
    html .= "</script>`n"
    }
        else
        {
            ; 대중교통: 2페이지 산출 총액 바로 밑에 영수증 부착란 (정확히 2매 출력)
            ; 2면 출력 시에는 상단 산출내역과 한 장에 출력되므로 소속/직급/성명/출장일 정보는 생략
            html .= "  <div class=""sec-header"" style=""margin-top: 4mm;"">증빙서류 첨부 (영수증 부착란)</div>`n"
            html .= "  <div class=""attach-box"" style=""height: 175mm; margin-top: 2.5mm;"">`n"
            html .= "    여비 정산 증빙서류 부착란<br><br>`n"
            html .= "    <span style=""font-size:9.5pt;color:#888;"">승차권, 숙박비, 주차료·통행료 영수증(신용카드 매출전표) 등 관련 증빙 원본을 부착하세요.</span>`n"
            html .= "  </div>`n"
            html .= "</div>`n"
        }
    }

    html .= "</body></html>`n"

    SSOK_Travel_LastHtml := html
    tmpFile := A_Temp . "\ssok_travel_print_" . A_TickCount . ".html"
    FileDelete, %tmpFile%
    FileAppend, %html%, %tmpFile%, UTF-8

    Run, %tmpFile%
    return
SSOK_Travel_FormatFuelPrice(v)
{
    return Format("{:.2f}", v + 0.0)
}

SSOK_Travel_GetTransitName(rail, bus, ship, air)
{
    cnt := (rail > 0 ? 1 : 0) + (bus > 0 ? 1 : 0) + (ship > 0 ? 1 : 0) + (air > 0 ? 1 : 0)
    if (cnt > 1)
        return "대중교통"
    if (rail > 0)
        return "철도"
    if (bus > 0)
        return "버스"
    if (ship > 0)
        return "선박"
    if (air > 0)
        return "항공"
    return "대중교통"
}

SSOK_Travel_SimpleHash(s)
{
    hash := 2166136261
    Loop, Parse, s
    {
        hash := Mod((hash ^ Asc(A_LoopField)) * 16777619, 2147483647)
        if (hash < 0)
            hash := hash + 2147483647
    }
    return hash
}

SSOK_Travel_CropImage(src, dest, x, y, w, h)
{
    ; 1순위: ImageMagick
    magick := ""
    candidates := [A_ProgramFiles . "\ImageMagick-7.0.\magick.exe", A_ProgramFiles . "\ImageMagick-7.1.\magick.exe", "magick.exe"]
    for _, c in candidates
    {
        if (c = "magick.exe" || FileExist(c))
        {
            magick := c
            break
        }
    }
    if (magick != "")
    {
        cmd := """" . magick . """ """ . src . """ -crop " . w . "x" . h . "+" . x . "+" . y . " +repage """ . dest . """"
        try
            RunWait, %cmd%,, Hide
        catch
        {
        }
        FileGetSize, sz, %dest%
        if (sz > 5000)
            return true
    }

    ; 2순위: Windows 기본 .NET System.Drawing
    ps := A_Temp . "\SSOK_Travel_Crop_" . A_TickCount . ".ps1"
    script := "$ErrorActionPreference='Stop';"
    script .= "Add-Type -AssemblyName System.Drawing;"
    script .= "$src=[System.Drawing.Image]::FromFile('" . StrReplace(src, "'", "''") . "');"
    script .= "$bmp=New-Object System.Drawing.Bitmap(" . w . "," . h . ");"
    script .= "$g=[System.Drawing.Graphics]::FromImage($bmp);"
    script .= "$g.DrawImage($src,0,0," . w . "," . h . ");"
    script .= "$bmp.Save('" . StrReplace(dest, "'", "''") . "',[System.Drawing.Imaging.ImageFormat]::Png);"
    script .= "$g.Dispose();$bmp.Dispose();$src.Dispose();"
    FileDelete, %ps%
    FileAppend, %script%, %ps%, UTF-8

    cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ . ps . """"
    try
        RunWait, %cmd%,, Hide
    catch
        return false

    FileGetSize, sz, %dest%
    return (sz > 5000)
}

; ------------------------------------------------------------------------------
; 외부 웹페이지를 Edge Headless로 실제 화면 캡처
; ------------------------------------------------------------------------------
SSOK_Travel_CaptureWebPage(url, outFile, width := 1280, height := 760)
{
    edge := SSOK_Travel_GetEdgePath()
    if (edge = "" || url = "" || outFile = "")
        return false

    FileDelete, %outFile%
    profileDir := A_Temp . "\SSOKTravelEdge_" . A_TickCount
    FileCreateDir, %profileDir%

    cmd := """" . edge . """ --headless=new --disable-gpu --hide-scrollbars --no-first-run --no-default-browser-check --disable-background-networking --disable-component-update --disable-sync --disable-default-apps --disable-extensions --user-data-dir=""" . profileDir . """ --window-size=" . width . "," . height . " --virtual-time-budget=4500 --screenshot=""" . outFile . """ """ . url . """"
    try
    {
        RunWait, %cmd%,, Hide
    }
    catch
    {
        return false
    }

    FileGetSize, sz, %outFile%
    if (sz > 5000)
        return true
    return false
}

SSOK_Travel_GetEdgePath()
{
    paths := []
    paths.Push(A_ProgramFiles . "\Microsoft\Edge\Application\msedge.exe")
    paths.Push(A_ProgramFiles . " (x86)\Microsoft\Edge\Application\msedge.exe")
    paths.Push(A_LocalAppData . "\Microsoft\Edge\Application\msedge.exe")
    paths.Push(A_ProgramFiles . "\Google\Chrome\Application\chrome.exe")
    paths.Push(A_ProgramFiles . " (x86)\Google\Chrome\Application\chrome.exe")
    paths.Push(A_LocalAppData . "\Google\Chrome\Application\chrome.exe")

    for _, p in paths
    {
        if (FileExist(p))
            return p
    }
    return ""
}

SSOK_Travel_FileUrl(path)
{
    p := StrReplace(path, "\", "/")
    return "file:///" . p
}
; ------------------------------------------------------------------------------
; 유틸리티 및 보조 계산 함수
; ------------------------------------------------------------------------------

SSOK_Travel_DetectLodgingCap(dest)
{
    if (dest = "")
        return 70000
    if (InStr(dest, "서울"))
        return 100000
    if (InStr(dest, "국립한국해양대학교") || InStr(dest, "한국해양대학교"))
        return 80000
    if (InStr(dest, "부산") || InStr(dest, "대구") || InStr(dest, "인천") || InStr(dest, "광주") || InStr(dest, "대전") || InStr(dest, "울산") || InStr(dest, "경기"))
        return 80000
    return 70000
}

SSOK_Travel_DetectLodgingRegionName(dest)
{
    if (dest = "")
        return "기타 지역"
    if (InStr(dest, "서울"))
        return "서울특별시"
    if (InStr(dest, "국립한국해양대학교") || InStr(dest, "한국해양대학교"))
        return "부산광역시"
    if (InStr(dest, "부산") || InStr(dest, "대구") || InStr(dest, "인천") || InStr(dest, "광주") || InStr(dest, "대전") || InStr(dest, "울산"))
        return "광역시"
    if (InStr(dest, "경기"))
        return "경기도"
    return "기타 지역"
}

SSOK_Travel_CalcMealCost(mealCount)
{
    if (mealCount <= 0)
        return 0
    return Round(mealCount * (25000.0 / 3.0))
}

SSOK_Travel_DateDiffDays(d1, d2)
{
    t1 := SubStr(d1, 1, 8) . "000000"
    t2 := SubStr(d2, 1, 8) . "000000"
    EnvSub, t2, %t1%, Days
    return t2
}

SSOK_Travel_Number(val)
{
    clean := RegExReplace(val, "[^\d\.-]", "")
    if (clean = "" || clean = "-")
        return 0
    return clean + 0
}

SSOK_Travel_Comma(num)
{
    clean := Floor(SSOK_Travel_Number(num))
    return RegExReplace(clean, "\G\d+?(?=(\d{3})+(?:\D|$))", "$0,")
}

SSOK_Travel_FormatDist(km)
{
    num := km + 0.0
    return Format("{:0.1f}", num)
}

SSOK_Travel_UriEncode(str)
{
    res := ""
    Loop, Parse, str
    {
        c := A_LoopField
        if (c ~= "[a-zA-Z0-9_\-\.~]")
            res .= c
        else
        {
            varSetCapacity(buf, 8, 0)
            StrPut(c, &buf, "UTF-8")
            Loop
            {
                byte := NumGet(buf, A_Index - 1, "UChar")
                if (byte = 0)
                    break
                res .= "%" . Format("{:02X}", byte)
            }
        }
    }
    return res
}

SSOK_Travel_GetCoords(query, ByRef lon, ByRef lat, ByRef resolvedName)
{
    lon := 0, lat := 0, resolvedName := query
    if (query = "" || StrLen(query) <= 1)
        return false

    ; 1차: dge-te
    places := SSOK_Travel_SearchPlacesApi(query)
    if (places.Length() > 0)
    {
        lon := places[1].x
        lat := places[1].y
        resolvedName := places[1].name
        return true
    }

    ; 2차: Nominatim
    return SSOK_Travel_GetCoordsNominatim(query, lon, lat, resolvedName)
}

SSOK_Travel_GetCoordsNominatim(query, ByRef lon, ByRef lat, ByRef resolvedName)
{
    lon := 0, lat := 0, resolvedName := query
    try
    {
        enc := SSOK_Travel_UriEncode(query)
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(1000, 1000, 1500, 2000)
        whr.Open("GET", "https://nominatim.openstreetmap.org/search?q=" . enc . "&format=json&countrycodes=kr", false)
        whr.SetRequestHeader("User-Agent", "SSOKTravelApp/1.0")
        whr.Send()
        res := whr.ResponseText
        if (RegExMatch(res, """lat"":""([0-9\.]+)""", mLat) && RegExMatch(res, """lon"":""([0-9\.]+)""", mLon))
        {
            lat := mLat1
            lon := mLon1
            return true
        }
    }
    return false
}

SSOK_Travel_GetDistanceAndRoute(lon1, lat1, lon2, lat2, ByRef coordsJson, lonVia := 0, latVia := 0)
{
    coordsJson := ""
    if (!lon1 || !lat1 || !lon2 || !lat2)
        return 0
    try
    {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(1000, 1000, 1500, 2000)
        if (lonVia && latVia)
            url := "http://router.project-osrm.org/route/v1/driving/" . lon1 . "," . lat1 . ";" . lonVia . "," . latVia . ";" . lon2 . "," . lat2 . "?overview=full&geometries=geojson"
        else
            url := "http://router.project-osrm.org/route/v1/driving/" . lon1 . "," . lat1 . ";" . lon2 . "," . lat2 . "?overview=full&geometries=geojson"

        whr.Open("GET", url, false)
        whr.SetRequestHeader("User-Agent", "Mozilla/5.0")
        whr.Send()
        res := whr.ResponseText

        km := 0
        if (RegExMatch(res, """distance"":([0-9\.]+)", mDist))
            km := Format("{:0.1f}", mDist1 / 1000.0)

        if (RegExMatch(res, """coordinates"":(\[\[.+?\]\])", mCoords))
            coordsJson := mCoords1

        return km
    }
    return 0
}

SSOK_Travel_GetCachedOrFetchFuelPrice(fuelType, dateStr)
{
    global SSOK_Ini
    if (SSOK_Ini = "")
        SSOK_Ini := A_ScriptDir . "\ssok.ini"

    fuelKey := "gasoline"
    if (InStr(fuelType, "경유"))
        fuelKey := "diesel"
    else if (InStr(fuelType, "LPG"))
        fuelKey := "lpg"
    else if (InStr(fuelType, "하이브리드"))
        fuelKey := "gasoline"
    else if (InStr(fuelType, "전기"))
        return 0
    else if (InStr(fuelType, "수소"))
        return 9900

    IniRead, cachedVal, %SSOK_Ini%, TravelFuelPrices, %dateStr%_%fuelKey%, 0
    if (cachedVal > 0)
        return cachedVal

    fetchedVal := SSOK_Travel_FetchOpinetDirect(fuelKey, dateStr)
    if (fetchedVal > 0)
    {
        IniWrite, %fetchedVal%, %SSOK_Ini%, TravelFuelPrices, %dateStr%_%fuelKey%
        return fetchedVal
    }

    ; 오피넷에 해당 날짜 자료가 없으면 임의의 유가를 넣지 않는다.
    ; 0 반환 = 조회자료 없음
    return 0
}

SSOK_Travel_FetchOpinetDirect(fuelKey, dateStr)
{
    global SSOK_Ini
    sY := SubStr(dateStr, 1, 4)
    sM := SubStr(dateStr, 5, 2)
    sD := SubStr(dateStr, 7, 2)

    if (fuelKey = "lpg")
    {
        try
        {
            whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr.SetTimeouts(1200, 1200, 1500, 2000)
            url := "https://www.opinet.co.kr/user/dopvsavsel/dopVsAvselSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_K015_P=Y"
            whr.Open("GET", url, false)
            whr.SetRequestHeader("User-Agent", "Mozilla/5.0")
            whr.Send()
            res := whr.ResponseText

            if (RegExMatch(res, "(?s)<td class=""nobd_l"">[^<]*</td>\s*<td>([0-9,.]+)</td>", m))
            {
                lpgVal := RegExReplace(m1, ",", "") + 0.0
                if (lpgVal > 300)
                {
                    if (SSOK_Ini != "")
                        IniWrite, %lpgVal%, %SSOK_Ini%, TravelFuelPrices, %dateStr%_lpg
                    return lpgVal
                }
            }
        }
        return 0
    }

    try
    {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(1200, 1200, 1500, 2000)
        url := "https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_B027=Y&OIL_CD_D047=Y"
        whr.Open("GET", url, false)
        whr.SetRequestHeader("User-Agent", "Mozilla/5.0")
        whr.Send()
        res := whr.ResponseText

        if (RegExMatch(res, "(?s)<td class=""nobd_l t_center"">[^<]*</td>\s*<td>([0-9,.]+)</td>\s*<td>([0-9,.]+)</td>", m))
        {
            gasVal := RegExReplace(m1, ",", "") + 0.0
            dieVal := RegExReplace(m2, ",", "") + 0.0

            if (gasVal > 500 && SSOK_Ini != "")
                IniWrite, %gasVal%, %SSOK_Ini%, TravelFuelPrices, %dateStr%_gasoline
            if (dieVal > 500 && SSOK_Ini != "")
                IniWrite, %dieVal%, %SSOK_Ini%, TravelFuelPrices, %dateStr%_diesel

            if (fuelKey = "diesel" && dieVal > 500)
                return dieVal
            if (fuelKey = "gasoline" && gasVal > 500)
                return gasVal
        }
    }
    return 0
}
