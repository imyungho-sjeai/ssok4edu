#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
SetFormat, FloatFast, 0.6

; 트레이 및 기본 아이콘 설정 (쏙 FOR 여비 정산_아이콘.ico)
iconPath := A_ScriptDir . "\쏙 FOR 여비 정산_아이콘.ico"
if (!FileExist(iconPath))
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
global ST_GoDistance, ST_BackDistance, ST_GoViaCheck, ST_BackViaCheck
global ST_RailGo, ST_RailVia, ST_RailBack, ST_BusGo, ST_BusVia, ST_BusBack, ST_ShipGo, ST_ShipVia, ST_ShipBack, ST_AirGo, ST_AirVia, ST_AirBack, ST_TransitTotalText
global ST_MealOption, ST_MealCount, ST_MealActual, ST_LblMealDesc, ST_LblMealClosing, ST_LblMealWon, ST_LblMealDoc
global ST_LodgingAutoText, ST_LodgingActual, ST_LodgingInfoText, ST_SharedStayCheck, ST_SharedStayPeople, ST_FamilyStayCheck, ST_FamilyStayNights, ST_SharedStayInfo
global ST_Total, ST_TotalSummary, ST_CarFareTotalText

; 동적 표시/숨김용 컨트롤 변수
global ST_LblFuel, ST_LblDist, ST_LblKm, ST_LblPrice, ST_LblWon1, ST_BtnRecalcCar, ST_BtnLookupCar
global ST_ChargeAmount, ST_ChargeKwh, ST_ChargeRateResult, ST_EvRateGuide
global ST_LblViaSelect, ST_GoViaCheck, ST_BackViaCheck, ST_LblRoute, ST_GoRouteText, ST_BackRouteText
global ST_GoRouteLine, ST_BackRouteLine
global ST_LblToll, ST_LblWon2, ST_LblPark, ST_LblWon3, ST_LblParkCap, ST_LblCarTotal, ST_HiPassLink
global ST_LblTransitType, ST_LblTransitGo, ST_LblWonGo, ST_LblTransitVia, ST_LblWonVia, ST_LblTransitBack, ST_LblWonBack, ST_LblTransitAir, ST_LblWonAir, ST_LblTransitTotal
global ST_DescGov, ST_DescCarpool

; HWND 변수 (IME 포커스 아웃 및 포맷팅 처리)
global hTravelGui, hRadioCar, hEditOrg, hEditDep, hEditDest, hEditStopover, hEditMealAct, hEditLodgingAct, hEditToll, hEditPark, hEditName, hRankCombo, hFuelCombo, hReasonCombo
global ST_LastFocusedEdit := ""
global ST_DestinationNeedInput := false

; 장소 선택 다이얼로그용 글로벌 변수
global ST_SelectedPlaceIdx := 0, ST_PlaceListView

; 자동 주행 및 지도 좌표 캐시 변수
global ST_DepLon := 0, ST_DepLat := 0, ST_DepName := ""
global ST_DestLon := 0, ST_DestLat := 0, ST_DestName := ""
global ST_ViaLon := 0, ST_ViaLat := 0, ST_ViaName := ""
global ST_GoDistance := 0, ST_BackDistance := 0, ST_GoViaCheck := 0, ST_BackViaCheck := 0

; 포커스 이동(EN_KILLFOCUS) 및 마우스 클릭(WM_LBUTTONDOWN) 감지 메시지 등록
OnMessage(0x0111, "SSOK_Travel_WM_COMMAND")
OnMessage(0x0201, "SSOK_Travel_WM_LBUTTONDOWN")
OnMessage(0x0134, "SSOK_Travel_WM_CTLCOLORLISTBOX")
OnMessage(0x0133, "SSOK_Travel_WM_CTLCOLOREDIT")

SSOK_Travel_Show()
Gui, SSOKTravel:Default
Gui, SSOKTravel:Submit, NoHide
SSOK_Travel_HighlightDestination(Trim(ST_Destination) = "")
return

SSOKTravelGuiClose:
SSOKTravelGuiEscape:
    ; 우측 상단 X / Esc = 프로그램 완전 종료
    SSOK_Travel_AutoSave()
    ExitApp
    return

SSOK_Travel_Show()
{
    global
    Gui, SSOKTravel:Destroy
    Gui, SSOKTravel:New, +Resize +MinSize960x868 +HwndhTravelGui, % "세종특별자치시교육청 여비정산 신청"
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Color, F8F9FA, FFFFFF
    Gui, SSOKTravel:Margin, 16, 10
    Gui, SSOKTravel:Font, s9 c212529, Malgun Gothic

    defaultOrg := SSOK_Travel_GetDefaultOrg()

    ; 새 여비신청서는 저장된 출장 구분과 관계없이 항상 일반출장으로 시작한다.
    ; 사용자가 이후 교육훈련 등으로 변경하면 그 변경값은 저장한다.
    savedCategory := "1"

    ; 여비신청에서 INI에 남기는 값은 개인 기본정보만 유지한다.
    ; 저장: 소속 / 직급 / 성명 / 출발지
    savedOrg := defaultOrg

    IniRead, savedRank, %SSOK_Ini%, Travel, Rank, 교사
    if (savedRank = "ERROR" || savedRank = "" || savedRank = "행정실장")
        savedRank := "교사"

    IniRead, savedName, %SSOK_Ini%, Travel, Name, %A_Space%
    if (savedName = "ERROR")
        savedName := ""

    savedDep := savedOrg

    ; 나머지 출장 입력값은 저장/복원하지 않고 매번 새 신청서로 시작한다.
    savedDest := ""
    savedStopover := ""
    savedFuelType := "휘발유 (11.97 km/L)"
    savedFuelPrice := ""
    savedTransitVia := "0"
    savedTransitType := "기차"
    savedTransType := "2"

    savedToll := ""
    savedParking := ""
    savedRailGo := ""
    savedRailVia := ""
    savedRailBack := ""
    savedBusGo := ""
    savedBusVia := ""
    savedBusBack := ""
    savedShipGo := ""
    savedShipVia := ""
    savedShipBack := ""
    savedAirGo := ""
    savedAirVia := ""
    savedAirBack := ""
    savedMealActual := ""
    savedLodgingActual := ""
    savedSharedStayCheck := "0"
    savedSharedStayPeople := "0"
    savedFamilyStayCheck := "0"
    savedFamilyStayNights := "0"
    savedCarReason := ""

    ; ==============================================================================
    ; [출장 구분] - "1. 출장자 정보" 바로 위 우측 정렬, ~90% 크기 (s9)
    ; ==============================================================================
    chkCat1 := (savedCategory = "1" ? "Checked" : "")
    chkCat2 := (savedCategory = "2" ? "Checked" : "")
    chkCat3 := (savedCategory = "3" ? "Checked" : "")
    if (chkCat1 = "" && chkCat2 = "" && chkCat3 = "")
        chkCat1 := "Checked"

    Gui, SSOKTravel:Font, s16 Bold c123B6D, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x24 y14 w700 h32, % "세종특별자치시교육청 여비정산 신청"
    Gui, SSOKTravel:Font, s9 Bold c6C757D, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x32 y52 w80 Right h20, % "출장 구분:"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Radio, x124 y50 w132 vST_TravelCategory1 %chkCat1% gSSOK_Travel_OnCategoryChange h22, % "일반출장"
    Gui, SSOKTravel:Add, Radio, x276 y50 w230 vST_TravelCategory2 %chkCat2% gSSOK_Travel_OnCategoryChange h22, % "교육훈련 (합숙·기숙사)"
    Gui, SSOKTravel:Add, Radio, x526 y50 w200 vST_TravelCategory3 %chkCat3% gSSOK_Travel_OnCategoryChange h22, % "교육훈련 (비합숙)"
    Gui, SSOKTravel:Font, s9 c212529, Malgun Gothic

    ; ==============================================================================
    ; [1] 출장자 정보 (폭 848, 높이 54)
    ; ==============================================================================
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x24 y82 w912 h62, % " 1. 출장자 정보 "
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x41 y103 w48, % "소속:"
    Gui, SSOKTravel:Add, Edit, x91 y99 w237 vST_Org hwndhEditOrg gSSOK_Travel_OnOrgChange h26, %savedOrg%
    Gui, SSOKTravel:Add, Text, x346 y103 w48, % "직급:"
    Gui, SSOKTravel:Add, DropDownList, x394 y99 w156 vST_Rank hwndhRankCombo gSSOK_Travel_OnRankChange, % "교사|교감|교장|주무관|사무관|장학사|장학관|기타"
    Gui, SSOKTravel:Add, Text, x582 y103 w48, % "성명:"
    Gui, SSOKTravel:Add, Edit, x631 y99 w172 vST_Name hwndhEditName gSSOK_Travel_AutoSave h26, %savedName%

    ; ==============================================================================
    ; [2] 출장 일정 및 경로 (폭 848, 높이 88)
    ; ==============================================================================
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x24 y154 w912 h96, % " 2. 출장 일정 "
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x41 y177 w59, % "출발일:"
    Gui, SSOKTravel:Add, DateTime, x104 y173 w140 vST_StartDate Choose%startStr% gSSOK_Travel_OnDateChange, yyyy-MM-dd
    Gui, SSOKTravel:Add, Text, x260 y177 w59, % "도착일:"
    Gui, SSOKTravel:Add, DateTime, x319 y173 w140 vST_EndDate Choose%endStr% gSSOK_Travel_OnDateChange, yyyy-MM-dd
    Gui, SSOKTravel:Add, Text, x480 y177 w70, % "출장일수:"
    Gui, SSOKTravel:Font, s9 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x555 y177 w366 vST_DaysText, % "1일"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    Gui, SSOKTravel:Add, Text, x41 y212 w54, % "출발지:"
    Gui, SSOKTravel:Add, Edit, x98 y208 w194 vST_Departure hwndhEditDep gSSOK_Travel_AutoSave h26, %savedDep%
    Gui, SSOKTravel:Add, Text, x303 y212 w54, % "도착지:"
    Gui, SSOKTravel:Add, Edit, x360 y208 w204 vST_Destination hwndhEditDest gSSOK_Travel_OnDestChange h26, %savedDest%
    Gui, SSOKTravel:Add, Text, x575 y212 w54, % "경유지:"
    Gui, SSOKTravel:Add, Edit, x631 y208 w194 vST_Stopover hwndhEditStopover gSSOK_Travel_AutoSave h26, %savedStopover%
    Gui, SSOKTravel:Add, Text, x830 y212 w81 cADB5BD, % "(선택입력)"

    Gui, SSOKTravel:Add, Button, Default x-20 y-20 w1 h1 gSSOK_Travel_OnEnter, % "Enter"

    ; ==============================================================================
    ; [3] 교통편 및 운임
    ; ==============================================================================
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x24 y260 w912 h258, % " 3. 교통비 "
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    chk1 := (savedTransType = "1" ? "Checked" : "")
    chk2 := (savedTransType = "2" ? "Checked" : "")
    chk3 := (savedTransType = "3" ? "Checked" : "")
    chk4 := (savedTransType = "4" ? "Checked" : "")
    if (chk1 = "" && chk2 = "" && chk3 = "" && chk4 = "")
        chk2 := "Checked"

    Gui, SSOKTravel:Font, s9 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Radio, x41 y280 w118 vST_TransType2 %chk2% gSSOK_Travel_OnTransChange, % "대중교통"
    Gui, SSOKTravel:Add, Radio, x168 y280 w97 vST_TransType1 hwndhRadioCar %chk1% gSSOK_Travel_OnTransChange, % "자가용"
    Gui, SSOKTravel:Add, Radio, x276 y280 w220 vST_TransType3 %chk3% gSSOK_Travel_OnTransChange, % "관용차량·임차버스·렌트카 등"
    Gui, SSOKTravel:Add, Radio, x507 y280 w204 vST_TransType4 %chk4% gSSOK_Travel_OnTransChange, % "타인차량 동승 등 기타"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    ; 자가용 전용 컨트롤
    Gui, SSOKTravel:Add, Text, x41 y308 w43 vST_LblFuel, % "유종:"
    Gui, SSOKTravel:Add, DropDownList, x84 y304 w263 vST_FuelType gSSOK_Travel_OnFuelTypeChange hwndhFuelCombo, % "선택하세요||휘발유 (11.97 km/L)|경유 (12.52 km/L)|일반 하이브리드(휘발유, 15.37 km/L)|일반 하이브리드(경유, 15.37 km/L)|플러그인 하이브리드(휘발유, 10.61 km/L)|플러그인 하이브리드(전기, 2.84 km/kWh)|LPG (8.83 km/L)|전기 (5.22 km/kWh)|수소 (94.9 km/kg)"
    Gui, SSOKTravel:Add, Text, x358 y308 w38 vST_LblDist, % "거리:"
    Gui, SSOKTravel:Font, s9 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Edit, x397 y304 w70 vST_Distance +ReadOnly h26, 0.0
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x472 y308 w27 vST_LblKm, % "km"
    Gui, SSOKTravel:Add, Text, x505 y308 w38 vST_LblPrice, % "단가:"
    Gui, SSOKTravel:Font, s9 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Edit, x543 y304 w75 vST_FuelPrice gSSOK_Travel_OnFuelPriceChange h26, %savedFuelPrice%
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x622 y308 w43 vST_LblWon1, % "원/L"
    Gui, SSOKTravel:Add, Button, x670 y302 w151 h30 vST_BtnRecalcCar gSSOK_Travel_RecalculateCar, % "거리·유가 재산정"
    Gui, SSOKTravel:Font, s8 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Button, x826 y302 w79 h30 vST_BtnLookupCar gSSOK_Travel_OpenCarLookup, % "인터넷 조회"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    ; 경로
    Gui, SSOKTravel:Add, Text, x41 y338 w41 vST_LblRoute, % "경로:"
    Gui, SSOKTravel:Font, s8 Normal c888888, Malgun Gothic
    Gui, SSOKTravel:Add, Checkbox, x84 y336 w48 vST_GoViaCheck gSSOK_Travel_OnStopoverRouteChange h22, % "경유"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x134 y338 w330 vST_GoRouteLine, % "가는편: 출발지 → 도착지 (0.0 km)"
    Gui, SSOKTravel:Font, s8 Normal c888888, Malgun Gothic
    Gui, SSOKTravel:Add, Checkbox, x471 y336 w48 vST_BackViaCheck gSSOK_Travel_OnStopoverRouteChange h22, % "경유"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x522 y338 w400 vST_BackRouteLine, % "오는편: 도착지 → 출발지 (0.0 km)"

    ; 전기차/PHEV 전기 충전단가 산정 입력란
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x41 y368 w113 vST_EvRateLabel, % "전기차 단가산정:"
    Gui, SSOKTravel:Add, Text, x154 y368 w70 vST_EvChargeLabel, % "충전요금("
    Gui, SSOKTravel:Add, Edit, x224 y364 w81 vST_ChargeAmount gSSOK_Travel_OnChargeInput h26, % ""
    Gui, SSOKTravel:Add, Text, x305 y368 w113 vST_EvChargeMid, % "원) ÷ 충전량("
    Gui, SSOKTravel:Add, Edit, x418 y364 w76 vST_ChargeKwh gSSOK_Travel_OnChargeInput h26, % ""
    Gui, SSOKTravel:Add, Text, x498 y368 w70 vST_EvChargeEnd, % "kWh) ="
    Gui, SSOKTravel:Font, s9 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x568 y366 w140 vST_ChargeRateResult, % "295.0 원/kWh"
    Gui, SSOKTravel:Font, s8 Normal c777777, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x718 y364 w200 h88 vST_EvRateGuide, % "공공충전시설 출력별 기준단가`n30kW 미만: 295.0원/kWh`n30~50kW: 307.2원/kWh`n50~100kW: 325.6원/kWh`n100~200kW: 348.4원/kWh`n200kW 이상: 393.1원/kWh"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    Gui, SSOKTravel:Add, Text, x41 y458 w59 vST_LblToll, % "통행료:"
    Gui, SSOKTravel:Add, Edit, x104 y454 w86 vST_Toll hwndhEditToll gSSOK_Travel_OnAmountEditChange h26, %savedToll%
    Gui, SSOKTravel:Add, Text, x194 y458 w22 vST_LblWon2, % "원"
    Gui, SSOKTravel:Add, Text, x227 y458 w59 vST_LblPark, % "주차료:"
    Gui, SSOKTravel:Add, Edit, x286 y454 w86 vST_Parking hwndhEditPark gSSOK_Travel_OnAmountEditChange h26, %savedParking%
    Gui, SSOKTravel:Add, Text, x377 y458 w22 vST_LblWon3, % "원"
    Gui, SSOKTravel:Add, Text, x405 y458 w151 vST_LblParkCap cADB5BD, % "(1일 상한 10,000원)"
    Gui, SSOKTravel:Font, s9 Underline c1A5AA6, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x571 y458 w339 h22 vST_HiPassLink gSSOK_Travel_OpenHiPass, % "고속도로 통행료 조회  (www.hipass.co.kr)"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    Gui, SSOKTravel:Add, Text, x41 y486 w72 vST_LblCarReason, % "신청사유:"
    carReasonList := "선택하세요|1. 출장경로가 매우 복잡･다양하여 대중교통을 사실상 이용할 수 없는 경우|2. 자가용을 이용함으로써 운임이 적게 소요되는 경우|3. 산간오지, 도서벽지 등 대중교통수단이 없어 부득이 자가용 이용|4. 하중이 무거운 수하물을 운송해야 하는 경우|5. 공무목적상 부득이한 심야시간대 이동 또는 긴급한 사유가 있는 경우|6. 기관장 인정사유( 학생 현장실습 및 취업지원을 위한 학생 동승시 )|7. 대중교통을 이용에 어려움이 있는 장애인 공무원"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, DropDownList, x120 y482 w801 vST_CarReason gSSOK_Travel_OnCarReasonChange hwndhReasonCombo, %carReasonList%
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    ; 대중교통: 철도/버스/선박/항공 × 가는편/경유지/오는편
    Gui, SSOKTravel:Add, Text, x41 y308 w86 h22 Center vST_TransitHeader, % "구분"
    Gui, SSOKTravel:Add, Text, x144 y308 w248 h22 Center vST_TransitGoHeader, % "가는편 운임"
    Gui, SSOKTravel:Add, Text, x410 y308 w248 h22 Center vST_TransitViaHeader, % "경유지 운임"
    Gui, SSOKTravel:Add, Text, x676 y308 w248 h22 Center vST_TransitBackHeader, % "오는편 운임"
    Gui, SSOKTravel:Add, Text, x41 y334 w86 h22 Center vST_LblRail, % "철도"
    Gui, SSOKTravel:Add, Edit, x144 y330 w248 h26 vST_RailGo gSSOK_Travel_Calc, %savedRailGo%
    Gui, SSOKTravel:Add, Edit, x410 y330 w248 h26 vST_RailVia gSSOK_Travel_Calc, %savedRailVia%
    Gui, SSOKTravel:Add, Edit, x676 y330 w248 h26 vST_RailBack gSSOK_Travel_Calc, %savedRailBack%
    Gui, SSOKTravel:Add, Text, x41 y366 w86 h22 Center vST_LblBus, % "버스"
    Gui, SSOKTravel:Add, Edit, x144 y362 w248 h26 vST_BusGo gSSOK_Travel_Calc, %savedBusGo%
    Gui, SSOKTravel:Add, Edit, x410 y362 w248 h26 vST_BusVia gSSOK_Travel_Calc, %savedBusVia%
    Gui, SSOKTravel:Add, Edit, x676 y362 w248 h26 vST_BusBack gSSOK_Travel_Calc, %savedBusBack%
    Gui, SSOKTravel:Add, Text, x41 y398 w86 h22 Center vST_LblShip, % "선박"
    Gui, SSOKTravel:Add, Edit, x144 y394 w248 h26 vST_ShipGo gSSOK_Travel_Calc, %savedShipGo%
    Gui, SSOKTravel:Add, Edit, x410 y394 w248 h26 vST_ShipVia gSSOK_Travel_Calc, %savedShipVia%
    Gui, SSOKTravel:Add, Edit, x676 y394 w248 h26 vST_ShipBack gSSOK_Travel_Calc, %savedShipBack%
    Gui, SSOKTravel:Add, Text, x41 y430 w86 h22 Center vST_LblAir, % "기타"
    Gui, SSOKTravel:Add, Edit, x144 y426 w248 h26 vST_AirGo gSSOK_Travel_Calc, %savedAirGo%
    Gui, SSOKTravel:Add, Edit, x410 y426 w248 h26 vST_AirVia gSSOK_Travel_Calc, %savedAirVia%
    Gui, SSOKTravel:Add, Edit, x676 y426 w248 h26 vST_AirBack gSSOK_Travel_Calc, %savedAirBack%

    Gui, SSOKTravel:Font, s9 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x41 y308 w850 vST_DescGov c0D6EFD, % "※ 관용차량·임차버스·렌트카 등 이용: 운임 0원 / 일비 50%"
    Gui, SSOKTravel:Add, Text, x41 y308 w850 vST_DescCarpool c6C757D, % "※ 타인차량 동승 등 기타: 운임 0원 (동행자 차량 이용 등에 따른 운임 미지급)"

    ; ==============================================================================
    ; [4] 식비
    ; ==============================================================================
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x24 y532 w912 h72, % " 4. 식비 "
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x41 y556 w272 h22 vST_LblMealDesc, % "식사를 무료로 제공 받은 경우를 제외한 "
    Gui, SSOKTravel:Font, s9 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x321 y556 w145 h22 vST_LblMealCountDesc, % "실제 지출한 식사수"
    Gui, SSOKTravel:Font, s9 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, DropDownList, x475 y552 w75 vST_MealOption gSSOK_Travel_OnMealOptionChange, % "0식|1식|2식|3식"
    Gui, SSOKTravel:Add, Edit, x475 y552 w75 vST_MealCount gSSOK_Travel_OnMealCountChange Number h26, 0
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x555 y556 w27 vST_LblMealClosing, % "식"
    Gui, SSOKTravel:Add, Text, x604 y556 w74 vST_LblMealActualLabel, % "실제소요액"
    Gui, SSOKTravel:Font, s9 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Edit, x684 y552 w102 vST_MealActual hwndhEditMealAct gSSOK_Travel_OnMealActualChange ReadOnly h26, 0
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x792 y556 w27 vST_LblMealWon, % "원"
    Gui, SSOKTravel:Add, Text, x835 y556 w91 vST_LblMealLimit cADB5BD, % "최대 0식"

    ; ==============================================================================
    ; [5] 숙박비
    ; ==============================================================================
    Gui, SSOKTravel:Font, s10 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, GroupBox, x24 y618 w912 h126, % " 5. 숙박비 "
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x41 y643 w560 h22 vST_LodgingAutoText, % "당일출장으로 해당없음"
    Gui, SSOKTravel:Add, Text, x652 y643 w81 h22 vST_LodgingInfoText, % "실제소요액 ("
    Gui, SSOKTravel:Add, Edit, x733 y639 w97 vST_LodgingActual hwndhEditLodgingAct gSSOK_Travel_OnAmountEditChange +Disabled h26, %savedLodgingActual%
    Gui, SSOKTravel:Add, Text, x835 y643 w38 h22 vST_LodgingWon, % ")원"

    ; 1박 이상: 공동숙박/친지숙박 관련 글씨는 약 80% 크기 + 회색
    Gui, SSOKTravel:Font, s8 Normal c808080, Malgun Gothic
    Gui, SSOKTravel:Add, Checkbox, x41 y672 w81 h20 vST_SharedStayCheck gSSOK_Travel_OnSharedStayChange, % "공동숙박"
    Gui, SSOKTravel:Add, Edit, x125 y668 w45 h22 vST_SharedStayPeople gSSOK_Travel_OnSharedStayPeopleChange Number +Disabled, %savedSharedStayPeople%
    Gui, SSOKTravel:Add, Text, x172 y672 w26 h20 vST_LblSharedStayPeopleDesc, % "명"
    Gui, SSOKTravel:Add, Checkbox, x706 y672 w77 h20 vST_FamilyStayCheck gSSOK_Travel_OnFamilyStayChange, % "친지숙박"
    Gui, SSOKTravel:Add, Edit, x785 y668 w45 h22 vST_FamilyStayNights gSSOK_Travel_Calc Number +Disabled, %savedFamilyStayNights%
    Gui, SSOKTravel:Add, Text, x833 y672 w26 h20 vST_LblFamilyStayNightsDesc, % "박"
    Gui, SSOKTravel:Add, Text, x41 y696 w882 h42 vST_SharedStayInfo, % "공동숙박 선택 시 2명`n상한: 1박 단가 × 인원 × 숙박박수"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    ; ==============================================================================
    ; 하단 액션 바
    ; ==============================================================================
    Gui, SSOKTravel:Font, s12 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x33 y758 w134 h24, % "정산 신청 총액:"
    Gui, SSOKTravel:Font, s16 Bold c0D6EFD, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x168 y752 w344 h32 vST_Total, % "0 원"
    Gui, SSOKTravel:Font, s9 Normal c6C757D, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x33 y796 w462 h22 vST_TotalSummary, % "운임 0원 | 일비 0원 | 식비 0원 | 숙박비 0원"

    ; 하단 버튼은 총액/요약과 분리된 독립 영역에 배치한다.
    Gui, SSOKTravel:Font, s8 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Button, x545 y790 w97 h36 vST_SaveSettingsButton gSSOK_Travel_SaveSettings, % "설정 저장"
    Gui, SSOKTravel:Font, s9 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Button, x647 y790 w204 h36 gSSOK_Travel_PrintHtml, % "📄 여비정산서 인쇄"
    Gui, SSOKTravel:Font, s8 Bold c212529, Malgun Gothic
    Gui, SSOKTravel:Add, Button, x856 y790 w75 h36 gSSOK_Travel_Reset, % "초기화"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic

    ; 저작권 표시는 신청 화면 하단
    Gui, SSOKTravel:Font, s8 Underline c1A5AA6, Malgun Gothic
    Gui, SSOKTravel:Add, Text, x24 y834 w912 h18 Center +0x100 vST_Copyright gSSOK_Travel_OpenCopyright, % "쏙(SSOK) for 에듀파인  |  제작: 세종특별자치시교육청 이명호  |  blog.naver.com/ssok4edu"
    Gui, SSOKTravel:Font, s9 Normal c212529, Malgun Gothic


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
    GuiControl, SSOKTravel:Enable, ST_TransType1
    Gosub, SSOK_Travel_UpdateTransportUI
    Gosub, SSOK_Travel_UpdateChargeUI
    Gosub, SSOK_Travel_UpdateCategoryUI
    Gosub, SSOK_Travel_UpdateMealUI
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc

    SSOK_Travel_GetMainLeftPos(960, 868, travelWinX, travelWinY)
    Gui, SSOKTravel:Show, x%travelWinX% y%travelWinY% w960 h868, % "세종특별자치시교육청 여비정산 신청"
    GuiControl, MoveDraw, ST_SaveSettingsButton, x545 y790 w97 h36

    ; 메인 화면의 미입력 필수 입력칸을 연노랑으로 즉시 강조
    SSOK_Travel_UpdateInputHighlights()

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

SSOK_Travel_GetMainLeftPos(guiW, guiH, ByRef outX, ByRef outY)
{
    SysGet, travelWork, MonitorWorkArea
    gap := 8
    sideX := ""
    sideY := ""
    sideW := 112

    WinGetPos, sideX, sideY, sideW, , 쏙(SSOK)
    if (sideX = "")
    {
        sideX := travelWorkRight - sideW
        sideY := travelWorkTop + 76
    }

    outX := sideX - guiW - gap
    if (outX < travelWorkLeft)
        outX := travelWorkLeft
    if (outX + guiW > travelWorkRight)
        outX := travelWorkRight - guiW

    outY := sideY
    if (outY + guiH > travelWorkBottom)
        outY := travelWorkBottom - guiH
    if (outY < travelWorkTop)
        outY := travelWorkTop
}

SSOK_Travel_OpenCopyright:
    try Run, https://blog.naver.com/ssok4edu
return

SSOK_Travel_OpenHiPass:
    try Run, https://www.hipass.co.kr/main.do
return

; 윈도우 컨트롤 메시지 후킹 (포커스 아웃 시 한글 IME 누락 방지 및 천원 단위 콤마 자동 포맷)

SSOK_Travel_WM_CTLCOLORLISTBOX(wParam, lParam, msg, hwnd)
{
    ; 드롭다운 목록도 연노랑으로 표시한다.
    static hDropBrush := 0
    if (!hDropBrush)
        hDropBrush := DllCall("CreateSolidBrush", "UInt", 0xD6F9FF, "Ptr")

    DllCall("SetBkColor", "Ptr", wParam, "UInt", 0xD6F9FF)
    DllCall("SetTextColor", "Ptr", wParam, "UInt", 0x000000)
    return hDropBrush
}

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
                Gosub, SSOK_Travel_Calc
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
SSOK_Travel_SetEditBackColor(hEdit, isEmpty)
{
    if (!hEdit)
        return
    ; EM_SETBKGNDCOLOR: Edit 컨트롤 실제 배경색. COLORREF(RGB) 기준.
    color := (isEmpty ? 0xCCFFFF : 0xFFFFFF) ; 연노랑 FFFFCC
    SendMessage, 0x0443, 0, %color%,, ahk_id %hEdit%
    WinSet, Redraw,, ahk_id %hEdit%
}

SSOK_Travel_HighlightDestination(on := true)
{
    global hEditDest, ST_DestinationNeedInput
    ST_DestinationNeedInput := on ? true : false
    if (hEditDest)
        WinSet, Redraw,, ahk_id %hEditDest%
}

SSOK_Travel_SetComboBackColor(hCombo, isEmpty := true)
{
    if (!hCombo)
        return
    color := (isEmpty ? 0xCCFFFF : 0xFFFFFF)
    SendMessage, 0x0166, 0, %color%,, ahk_id %hCombo%
    WinSet, Redraw,, ahk_id %hCombo%
}

SSOK_Travel_SetEmptyHighlight(ctrl, isEmpty)
{
    if (isEmpty)
        GuiControl, SSOKTravel: +BackgroundFFFFCC, %ctrl%
    else
        GuiControl, SSOKTravel: +BackgroundFFFFFF, %ctrl%
}

SSOK_Travel_UpdateInputHighlights()
{
    global ST_Name, ST_Rank, ST_Departure, ST_Destination, ST_TransType1, ST_FuelType, ST_FuelPrice
    global ST_CarReason, ST_ChargeAmount, ST_ChargeKwh, ST_LodgingActual
    global hEditName, hRankCombo, hEditDep, hEditDest, hFuelCombo, hReasonCombo, hEditLodgingAct

    ; 기본 필수 입력
    SSOK_Travel_SetEditBackColor(hEditName, Trim(ST_Name) = "")
    SSOK_Travel_SetComboBackColor(hRankCombo, (Trim(ST_Rank) = "" || InStr(ST_Rank, "선택하세요")))
    SSOK_Travel_SetEditBackColor(hEditDep, Trim(ST_Departure) = "")
    SSOK_Travel_SetEditBackColor(hEditDest, Trim(ST_Destination) = "")

    ; 자가용을 선택했을 때만 유종/신청사유를 입력 유도
    if (ST_TransType1)
    {
        SSOK_Travel_SetComboBackColor(hFuelCombo, Trim(ST_FuelType) = "" || InStr(ST_FuelType, "선택하세요"))
        SSOK_Travel_SetComboBackColor(hReasonCombo, Trim(ST_CarReason) = "" || InStr(ST_CarReason, "선택하세요"))
    }
    else
    {
        SSOK_Travel_SetComboBackColor(hFuelCombo, false)
        SSOK_Travel_SetComboBackColor(hReasonCombo, false)
    }

    ; 숙박이 있거나 숙박비를 입력한 경우 실제소요액 입력 유도
    if (ST_SharedStayCheck || ST_FamilyStayCheck || Trim(ST_LodgingActual) != "")
        SSOK_Travel_SetEditBackColor(hEditLodgingAct, Trim(ST_LodgingActual) = "")
    else
        SSOK_Travel_SetEditBackColor(hEditLodgingAct, false)

    ; 전기차 입력칸은 기존 GuiControl 방식으로 보조 강조
    if (ST_TransType1 && InStr(ST_FuelType, "전기"))
    {
        SSOK_Travel_SetEmptyHighlight("ST_FuelPrice", Trim(ST_FuelPrice) = "")
        SSOK_Travel_SetEmptyHighlight("ST_ChargeAmount", Trim(ST_ChargeAmount) = "")
        SSOK_Travel_SetEmptyHighlight("ST_ChargeKwh", Trim(ST_ChargeKwh) = "")
    }
}

SSOK_Travel_WM_CTLCOLOREDIT(wParam, lParam, msg, hwnd)
{
    global hEditName, hEditDep, hEditDest, ST_DestinationNeedInput
    static hYellowBrush := 0
    static hWhiteBrush := 0

    if (!hYellowBrush)
        hYellowBrush := DllCall("CreateSolidBrush", "UInt", 0xCCFFFF, "Ptr")
    if (!hWhiteBrush)
        hWhiteBrush := DllCall("CreateSolidBrush", "UInt", 0xFFFFFF, "Ptr")

    if (lParam = hEditDest && ST_DestinationNeedInput)
    {
        DllCall("SetBkColor", "Ptr", wParam, "UInt", 0xCCFFFF)
        DllCall("SetTextColor", "Ptr", wParam, "UInt", 0x000000)
        return hYellowBrush
    }

    if (lParam = hEditName || lParam = hEditDep)
    {
        ControlGetText, ctlText, , ahk_id %lParam%
        if (Trim(ctlText) = "")
        {
            DllCall("SetBkColor", "Ptr", wParam, "UInt", 0xCCFFFF)
            DllCall("SetTextColor", "Ptr", wParam, "UInt", 0x000000)
            return hYellowBrush
        }
    }

    DllCall("SetBkColor", "Ptr", wParam, "UInt", 0xFFFFFF)
    DllCall("SetTextColor", "Ptr", wParam, "UInt", 0x000000)
    return hWhiteBrush
}

SSOK_Travel_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
    global hTravelGui, hRadioCar, ST_Destination
    if (hwnd = hRadioCar)
    {
        GuiControlGet, curDest, SSOKTravel:, ST_Destination
        if (Trim(curDest) = "")
        {
            SSOK_Travel_HighlightDestination(true)
            ToolTip, % "도착지를 먼저 입력해 주세요."
            SetTimer, SSOK_Travel_RemoveToolTip, -1800
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
                ToolTip, % "도착지를 먼저 입력해 주세요."
                SetTimer, SSOK_Travel_RemoveToolTip, -1800
                SSOK_Travel_HighlightDestination(true)
                GuiControl, SSOKTravel:Focus, ST_Destination
            }
        }
    }
}

SSOK_Travel_AutoSave()
{
    global SSOK_Ini, ST_Org, ST_Rank, ST_Name, ST_Departure
    if (SSOK_Ini = "")
        return

    ; 이전 버전에서 남아 있던 출장 입력 캐시를 정리한다.
    ; 앞으로는 소속/직급/성명/출발지만 Travel 섹션에 보관한다.
    oldTravelKeys := ["FuelType","Category","TransType","CarReason","Toll","Parking","RailGo","RailVia","RailBack","BusGo","BusVia","BusBack","ShipGo","ShipVia","ShipBack","AirGo","AirVia","AirBack","MealActual","LodgingActual","SharedStayCheck","SharedStayPeople","FamilyStayCheck","FamilyStayNights","TransitVia","TransitType"]
    for _, key in oldTravelKeys
        IniDelete, %SSOK_Ini%, Travel, %key%
    IniDelete, %SSOK_Ini%, TravelFuelPrices

    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    ; 자주 사용하는 개인 기본정보만 INI에 저장한다.
    IniWrite, %ST_Org%, %SSOK_Ini%, Travel, Org
    IniWrite, %ST_Rank%, %SSOK_Ini%, Travel, Rank
    IniWrite, %ST_Name%, %SSOK_Ini%, Travel, Name
    IniWrite, %ST_Departure%, %SSOK_Ini%, Travel, Departure
}

SSOK_Travel_GetDefaultOrg()
{
    global SSOK_Ini
    ; 메인 SSOK의 기관명을 여비정산 기본 소속/출발지로 사용한다.
    IniRead, orgName, %SSOK_Ini%, MajorTodos, OrgName, 도담중학교
    orgName := Trim(orgName)
    if (orgName = "" || orgName = "ERROR")
        orgName := "도담중학교"
    return orgName
}

; 소속 변경 이벤트 핸들러 (출장자가 소속 입력/수정 시 출발지 실시간 동기화)
SSOK_Travel_OnOrgChange:
    Gui, SSOKTravel:Default
    GuiControlGet, curOrg, SSOKTravel:, ST_Org

    ; 소속을 입력/변경하면 출발지도 즉시 동일하게 변경한다.
    ; 출발지 주소 표시/연결에 사용하는 값도 같은 출발지로 다시 설정한다.
    GuiControl, SSOKTravel:, ST_Departure, %curOrg%
    ST_Departure := curOrg

    ; 기존에 선택되어 있던 출발지 좌표/주소가 있다면 새 소속 기준으로 다시 계산한다.
    ST_GoLon := 0
    ST_GoLat := 0
    ST_GoResolvedName := curOrg

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
        SSOK_Travel_HighlightDestination(true)
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
        ; 도착지 문자가 입력되면 강조를 해제하고 자가용 선택을 허용한다.
        SSOK_Travel_HighlightDestination(false)
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
        GuiControl, SSOKTravel:Enable, ST_TransType1
    }
    else if (Trim(ST_Destination) != "")
    {
        ; 장소 좌표 확인이 지연되더라도 도착지 문자가 입력되어 있으면 자가용 선택을 막지 않는다.
        GuiControl, SSOKTravel:Enable, ST_TransType1
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
    Gosub, SSOK_Travel_UpdateCategoryUI
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_UpdateCategoryUI:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    if (ST_TravelCategory1) ; 일반출장
    {
        GuiControl, Show, ST_MealOption
        GuiControl, Show, ST_MealCount
        GuiControl, Hide, ST_LblMealClosing
        GuiControl, Show, ST_LblMealDesc
        GuiControl, Show, ST_LblMealCountDesc
        GuiControl, Show, ST_LblMealActualLabel
        GuiControl, Show, ST_MealActual
        GuiControl, Show, ST_LblMealWon
        GuiControl, Show, ST_LblMealLimit

        GuiControl, SSOKTravel:, ST_LblMealDesc, % "식사를 무료로 제공 받은 경우를 제외한 "
        GuiControl, SSOKTravel:, ST_LblMealCountDesc, % "실제 지출한 식사수"
        GuiControl, Move, ST_LblMealDesc, x41 y556 w272 h22
        GuiControl, Move, ST_LblMealCountDesc, x321 y556 w145 h22
        GuiControl, Move, ST_MealOption, x475 y552 w75 h23
        GuiControl, Move, ST_MealCount, x475 y552 w75 h23
        GuiControl, Move, ST_LblMealClosing, x555 y556 w38 h22
        GuiControl, Move, ST_LblMealActualLabel, x604 y556 w74 h22
        GuiControl, Move, ST_MealActual, x684 y552 w102 h23
        GuiControl, Move, ST_LblMealWon, x792 y556 w27 h22

        Gosub, SSOK_Travel_UpdateMealUI
    }
    else if (ST_TravelCategory2) ; 교육훈련(합숙·기숙사)
    {
        GuiControl, Hide, ST_MealOption
        GuiControl, Hide, ST_MealCount
        GuiControl, Hide, ST_LblMealClosing
        GuiControl, Hide, ST_LblMealActualLabel
        GuiControl, Hide, ST_LblMealLimit
        GuiControl, Hide, ST_LblMealCountDesc

        GuiControl, Show, ST_LblMealDesc
        GuiControl, Show, ST_MealActual
        GuiControl, Show, ST_LblMealWon

        GuiControl, SSOKTravel:, ST_LblMealDesc, % "교육훈련기관이 청구하는 금액 또는 구내 식당 가격"
        ; 긴 안내문이 한 줄로 보이도록 설명과 입력칸의 폭·간격을 확보한다.
        GuiControl, MoveDraw, ST_LblMealDesc, x41 y556 w610 h22
        GuiControl, MoveDraw, ST_MealActual, x660 y552 w150 h23
        GuiControl, MoveDraw, ST_LblMealWon, x816 y556 w27 h22
        GuiControl, -ReadOnly, ST_MealActual
    }
    else ; 교육훈련(비합숙)
    {
        GuiControl, SSOKTravel:, ST_MealActual, 0
        GuiControl, Hide, ST_MealOption
        GuiControl, Hide, ST_MealCount
        GuiControl, Hide, ST_LblMealClosing
        GuiControl, Hide, ST_LblMealActualLabel
        GuiControl, Hide, ST_LblMealLimit

        GuiControl, Show, ST_LblMealDesc
        GuiControl, Show, ST_LblMealCountDesc
        GuiControl, Show, ST_MealActual
        GuiControl, Show, ST_LblMealWon

        ; 교육훈련(비합숙)은 "실제 지출한 식비"로 표시한다.
        GuiControl, SSOKTravel:, ST_LblMealDesc, % "식사를 무료로 제공 받은 경우를 제외한 "
        GuiControl, SSOKTravel:, ST_LblMealCountDesc, % "실제 지출한 식비"
        GuiControl, Move, ST_LblMealDesc, x41 y556 w272 h22
        GuiControl, Move, ST_LblMealCountDesc, x321 y556 w145 h22
        GuiControl, Move, ST_MealActual, x588 y552 w102 h23
        GuiControl, Move, ST_LblMealWon, x695 y556 w27 h22
        GuiControl, -ReadOnly, ST_MealActual
    }
    ; 출장 구분을 연속 전환할 때 숨긴 컨트롤의 잔상이 남지 않도록 즉시 다시 그린다.
    WinSet, Redraw,, ahk_id %hTravelGui%
    return


SSOK_Travel_OnMealActualChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (!ST_TravelCategory1)
    {
        rawVal := SSOK_Travel_Number(ST_MealActual)
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

    ; 현재 실제 키보드 포커스된 컨트롤 식별 (변수명)
    GuiControlGet, focusedVar, SSOKTravel:FocusV

    ; 성명 입력칸에서 Enter를 눌러도 장소검색을 실행하지 않음
    if (focusedVar = "ST_Name")
        return

    ; 소속에서도 Enter를 누르면 동일한 장소 검색/정확한 주소 선택창을 연다.
    ; 선택 결과는 소속과 출발지에 한꺼번에 적용하고 좌표도 함께 사용한다.
    if (focusedVar = "ST_Org")
    {
        if (ST_Org != "")
        {
            ToolTip, % "소속 주소 확인 중..."
            outLon := 0, outLat := 0, outName := ""
            if (SSOK_Travel_ResolvePlace(ST_Org, outLon, outLat, outName, "소속 검색 결과 선택 및 확인"))
            {
                ST_Org := outName
                ST_Departure := outName

                GuiControl, SSOKTravel:, ST_Org, %ST_Org%
                GuiControl, SSOKTravel:, ST_Departure, %ST_Departure%

                ; 선택한 정확한 소속의 좌표를 출발지 좌표에 동시에 적용
                ST_DepLon := outLon
                ST_DepLat := outLat
                ST_DepName := outName
                ST_GoLon := outLon
                ST_GoLat := outLat
                ST_GoResolvedName := outName

                SSOK_Travel_AutoSave()
                SSOK_Travel_AutoUpdateDistance()
            }
            SetTimer, SSOK_Travel_RemoveToolTip, -2000
        }
        return
    }

    ; Enter는 현재 실제 포커스가 출발지/경유지/도착지일 때만 장소확인을 실행한다.
    ; 이전에 사용했던 ST_LastFocusedEdit를 사용하면 통행료·주차료·숙박비 등
    ; 다른 입력창에서도 마지막으로 기억된 도착지가 다시 실행되는 문제가 생긴다.
    target := ""
    if (focusedVar = "ST_Departure")
        target := "ST_Departure"
    else if (focusedVar = "ST_Stopover")
        target := "ST_Stopover"
    else if (focusedVar = "ST_Destination")
        target := "ST_Destination"
    else
    {
        return
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
                GuiControl, SSOKTravel:, ST_GoViaCheck, 0
                GuiControl, SSOKTravel:, ST_BackViaCheck, 0
                ST_GoViaCheck := 0, ST_BackViaCheck := 0
                Gosub, SSOK_Travel_UpdateTransportUI
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
                GuiControl, SSOKTravel:, ST_GoViaCheck, 0
                GuiControl, SSOKTravel:, ST_BackViaCheck, 0
                ST_GoViaCheck := 0, ST_BackViaCheck := 0
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
    selType := (ST_TransType1 ? "1" : (ST_TransType2 ? "2" : (ST_TransType3 ? "3" : "4")))
    Gosub, SSOK_Travel_UpdateTransportUI

    ; 자가용 선택 시 메시지를 띄우지 않고 신청사유 선택창을 바로 펼친다.
    if (ST_TransType1)
    {
        GuiControl, SSOKTravel:Focus, ST_CarReason
        GuiControlGet, hCarReason, SSOKTravel:HWND, ST_CarReason
        SendMessage, 0x014F, 1, 0,, ahk_id %hCarReason%
        if (ST_Departure != "" && ST_Destination != "" && ST_DepLon != 0 && ST_DestLon != 0)
            SSOK_Travel_AutoUpdateDistance()
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
    GuiControl, Hide, ST_HiPassLink
    GuiControl, Hide, ST_LblCarReason
    GuiControl, Hide, ST_CarReason
    GuiControl, Hide, ST_LblViaSelect
    GuiControl, Hide, ST_GoViaCheck
    GuiControl, Hide, ST_BackViaCheck
    GuiControl, Hide, ST_LblRoute
    GuiControl, Hide, ST_GoRouteLine
    GuiControl, Hide, ST_BackRouteLine
    GuiControl, Hide, ST_DescGov
    GuiControl, Hide, ST_DescCarpool
    GuiControl, Hide, ST_EvRateLabel
    GuiControl, Hide, ST_EvChargeLabel
    GuiControl, Hide, ST_ChargeAmount
    GuiControl, Hide, ST_EvChargeMid
    GuiControl, Hide, ST_ChargeKwh
    GuiControl, Hide, ST_EvChargeEnd
    GuiControl, Hide, ST_ChargeRateResult
    GuiControl, Hide, ST_EvRateGuide
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
        GuiControl, Show, ST_HiPassLink
        GuiControl, Show, ST_LblCarReason
        GuiControl, Show, ST_CarReason
        if (Trim(ST_Stopover) != "")
        {
            GuiControl, Show, ST_LblViaSelect
            GuiControl, Show, ST_GoViaCheck
            GuiControl, Show, ST_BackViaCheck
        }
        GuiControl, Show, ST_LblRoute
        GuiControl, Show, ST_GoRouteLine
        GuiControl, Show, ST_BackRouteLine
        Gosub, SSOK_Travel_UpdateChargeUI
        Gosub, SSOK_Travel_UpdateCarRouteDisplay
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
    daysLabel := (days = 1 ? "1일" : nights . "박 " . days . "일")
    GuiControl, SSOKTravel:, ST_DaysText, %daysLabel%

    Gosub, SSOK_Travel_CheckAutoCategory
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_UpdateMealUI

    if (ST_TransType1)
    {
        if (!InStr(ST_FuelType, "전기") && !InStr(ST_FuelType, "수소"))
        {
            price := SSOK_Travel_GetCachedOrFetchFuelPrice(ST_FuelType, sDate)
            if (price > 0)
                GuiControl, SSOKTravel:, ST_FuelPrice, %price%
            else
                GuiControl, SSOKTravel:, ST_FuelPrice, ""
        }
    }
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnCarReasonChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    ; 신청사유 변경만으로 교통편 선택이나 자가용 UI가 닫히거나 바뀌지 않도록 유지한다.
    if (ST_Destination != "" && ST_DestLon != 0 && ST_DestLat != 0)
    {
        ST_TransType1 := 1
        ST_TransType2 := 0
        ST_TransType3 := 0
        ST_TransType4 := 0
        GuiControl, SSOKTravel:Enable, ST_TransType1
        GuiControl, SSOKTravel:, ST_TransType1, 1
        GuiControl, SSOKTravel:, ST_TransType2, 0
        GuiControl, SSOKTravel:, ST_TransType3, 0
        GuiControl, SSOKTravel:, ST_TransType4, 0
    }
    if (ST_CarReason != "")
    
    if (ST_TransType1)
    {
        GuiControlGet, curFuel, SSOKTravel:, ST_FuelType
        if (curFuel = "" || InStr(curFuel, "선택하세요"))
        {
            GuiControl, SSOKTravel:Focus, ST_FuelType
            GuiControlGet, hFuel, SSOKTravel:HWND, ST_FuelType
            SendMessage, 0x014F, 1, 0,, ahk_id %hFuel%
        }
    }

    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnFuelTypeChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    sDate := SubStr(ST_StartDate, 1, 8)

    if (InStr(ST_FuelType, "전기"))
    {
        ; 전기차는 최종 적용단가(원/kWh)를 사용자가 반드시 입력한다.
        ; 충전요금÷충전량은 참고용 자동 산출이며, 최종 단가는 직접 수정할 수 있다.
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/kWh"
        GuiControl, SSOKTravel:, ST_ChargeAmount,
        GuiControl, SSOKTravel:, ST_ChargeKwh,
        GuiControl, SSOKTravel:, ST_FuelPrice, 295.0
        GuiControl, SSOKTravel:, ST_ChargeRateResult, % "295.0 원/kWh (기본)"
    }
    else if (InStr(ST_FuelType, "수소"))
    {
        ; 충전요금÷충전량(kg)으로 자동 산출할 수 있으며, 최종 단가는 사용자가 직접 수정할 수도 있다.
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/kg"
        GuiControl, SSOKTravel:, ST_ChargeAmount,
        GuiControl, SSOKTravel:, ST_ChargeKwh,
        GuiControl, SSOKTravel:, ST_FuelPrice, 9900
        GuiControl, SSOKTravel:, ST_ChargeRateResult, % "9,900 원/kg (기본)"
    }
    else if (InStr(ST_FuelType, "플러그인 하이브리드(휘발유"))
    {
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        price := SSOK_Travel_GetCachedOrFetchFuelPrice("휘발유", sDate)
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, % ""
    }
    else if (InStr(ST_FuelType, "일반 하이브리드(경유"))
    {
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        price := SSOK_Travel_GetCachedOrFetchFuelPrice("경유", sDate)
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, % ""
    }
    else if (InStr(ST_FuelType, "일반 하이브리드(휘발유"))
    {
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        price := SSOK_Travel_GetCachedOrFetchFuelPrice("휘발유", sDate)
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, % ""
    }
    else if (InStr(ST_FuelType, "LPG"))
    {
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        price := SSOK_Travel_GetCachedOrFetchFuelPrice("LPG", sDate)
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, % ""
    }
    else if (InStr(ST_FuelType, "경유"))
    {
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        price := SSOK_Travel_GetCachedOrFetchFuelPrice("경유", sDate)
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, % ""
    }
    else if (InStr(ST_FuelType, "휘발유"))
    {
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        price := SSOK_Travel_GetCachedOrFetchFuelPrice("휘발유", sDate)
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, % ""
    }
    else
    {
        GuiControl, SSOKTravel:-ReadOnly, ST_FuelPrice
        GuiControl, Show, ST_LblPrice
        GuiControl, Show, ST_FuelPrice
        GuiControl, Show, ST_LblWon1
        GuiControl, SSOKTravel:, ST_LblWon1, % "원/L"
        GuiControl, SSOKTravel:, ST_LblPrice, % "단가:"
    }
    Gosub, SSOK_Travel_UpdateChargeUI
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnChargeInput:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (!InStr(ST_FuelType, "전기") && !InStr(ST_FuelType, "수소"))
        return

    chargeAmount := SSOK_Travel_Number(ST_ChargeAmount)
    chargeQty := SSOK_Travel_Number(ST_ChargeKwh)

    if (InStr(ST_FuelType, "수소"))
    {
        defaultRate := 9900
        unit := "원/kg"
        rateText := "9,900"
    }
    else
    {
        defaultRate := 295.0
        unit := "원/kWh"
        rateText := "295.0"
    }

    if (chargeAmount > 0 && chargeQty > 0)
    {
        rate := chargeAmount / chargeQty
        rateText := (InStr(ST_FuelType, "수소") ? SSOK_Travel_Comma(rate) : SSOK_Travel_FormatChargeRate(rate))
        GuiControl, SSOKTravel:, ST_FuelPrice, %rateText%
        GuiControl, SSOKTravel:, ST_ChargeRateResult, % rateText . " " . unit
    }
    else
    {
        GuiControl, SSOKTravel:, ST_FuelPrice, %defaultRate%
        GuiControl, SSOKTravel:, ST_ChargeRateResult, % rateText . " " . unit . " (기본)"
    }
    Gosub, SSOK_Travel_Calc
    return

; 전기차/수소차 충전단가 산정 입력란의 표시·단위·기본값을 한 곳에서 관리한다.
SSOK_Travel_UpdateChargeUI:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    isElectric := InStr(ST_FuelType, "전기")
    isHydrogen := InStr(ST_FuelType, "수소")
    if (!ST_TransType1 || (!isElectric && !isHydrogen))
    {
        GuiControl, Hide, ST_EvRateLabel
        GuiControl, Hide, ST_EvChargeLabel
        GuiControl, Hide, ST_ChargeAmount
        GuiControl, Hide, ST_EvChargeMid
        GuiControl, Hide, ST_ChargeKwh
        GuiControl, Hide, ST_EvChargeEnd
        GuiControl, Hide, ST_ChargeRateResult
        GuiControl, Hide, ST_EvRateGuide
        return
    }

    GuiControl, Show, ST_EvRateLabel
    GuiControl, Show, ST_EvChargeLabel
    GuiControl, Show, ST_ChargeAmount
    GuiControl, Show, ST_EvChargeMid
    GuiControl, Show, ST_ChargeKwh
    GuiControl, Show, ST_EvChargeEnd
    GuiControl, Show, ST_ChargeRateResult
    GuiControl, Show, ST_EvRateGuide

    if (isHydrogen)
    {
        GuiControl, SSOKTravel:, ST_EvRateLabel, % "수소차 단가산정:"
        GuiControl, SSOKTravel:, ST_EvChargeLabel, % "충전요금("
        GuiControl, SSOKTravel:, ST_EvChargeMid, % "원) ÷ 충전량("
        GuiControl, SSOKTravel:, ST_EvChargeEnd, % "kg) ="
        GuiControl, SSOKTravel:, ST_EvRateGuide, % "※ 수소 기본단가: 9,900 원/kg`n※ 영수증 충전요금 ÷ 충전량(kg) 입력 시 자동 산출"
        GuiControl, SSOKTravel:, ST_ChargeRateResult, % "9,900 원/kg (기본)"
        GuiControl, SSOKTravel:, ST_FuelPrice, 9900
    }
    else
    {
        GuiControl, SSOKTravel:, ST_EvRateLabel, % "전기 kWh 단가:"
        GuiControl, SSOKTravel:, ST_EvChargeLabel, % "충전요금("
        GuiControl, SSOKTravel:, ST_EvChargeMid, % "원) ÷ 충전량("
        GuiControl, SSOKTravel:, ST_EvChargeEnd, % "kWh) ="
        GuiControl, SSOKTravel:, ST_EvRateGuide, % "공공충전시설 출력별 기준단가`n30kW 미만: 295.0원/kWh`n30~50kW: 307.2원/kWh`n50~100kW: 325.6원/kWh`n100~200kW: 348.4원/kWh`n200kW 이상: 393.1원/kWh"
        GuiControl, SSOKTravel:, ST_ChargeRateResult, % "전기 kWh 단가를 입력하세요"
        GuiControl, SSOKTravel:, ST_FuelPrice, 295.0
    }
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
    ; 일반출장 전용 식사수 UI가 교육훈련 화면에 다시 나타나 겹치지 않도록 한다.
    if (!ST_TravelCategory1)
        return
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
        GuiControl, SSOKTravel:, ST_LodgingAutoText, % "당일출장으로 해당없음"
        GuiControl, SSOKTravel:Disable, ST_LodgingActual
        GuiControl, SSOKTravel:, ST_LodgingActual, 0
        GuiControl, Hide, ST_LodgingInfoText
        GuiControl, Hide, ST_LodgingActual
        GuiControl, Hide, ST_LodgingWon
        GuiControl, Hide, ST_SharedStayCheck
        GuiControl, Hide, ST_SharedStayPeople
        GuiControl, Hide, ST_LblSharedStayPeopleDesc
        GuiControl, Hide, ST_SharedStayInfo
        GuiControl, Hide, ST_FamilyStayCheck
        GuiControl, Hide, ST_FamilyStayNights
        GuiControl, Hide, ST_LblFamilyStayNightsDesc
        GuiControl, SSOKTravel:, ST_SharedStayCheck, 0
        GuiControl, SSOKTravel:, ST_SharedStayPeople, 0
        GuiControl, SSOKTravel:, ST_FamilyStayCheck, 0
        GuiControl, SSOKTravel:, ST_FamilyStayNights, 0
        GuiControl, Disable, ST_SharedStayPeople
        GuiControl, Disable, ST_FamilyStayNights
    }
    else
    {
        ; 1박 이상이면 숙박 실제소요액 영역을 다시 표시한다.
        GuiControl, Show, ST_LodgingInfoText
        GuiControl, Show, ST_LodgingActual
        GuiControl, Show, ST_LodgingWon

        ; 1박 이상 숙박 시 공동숙박/친지숙박 선택을 표시
        GuiControl, Show, ST_SharedStayCheck
        GuiControl, Show, ST_SharedStayPeople
        GuiControl, Show, ST_LblSharedStayPeopleDesc
        GuiControl, Show, ST_SharedStayInfo

        if (ST_TravelCategory2 || ST_TravelCategory3)
        {
            ; 교육훈련(합숙·기숙사 / 비합숙)은 공동숙박·친지숙박을 사용하지 않는다.
            GuiControl, Hide, ST_SharedStayCheck
            GuiControl, Hide, ST_SharedStayPeople
            GuiControl, Hide, ST_LblSharedStayPeopleDesc
            GuiControl, Hide, ST_SharedStayInfo
            GuiControl, Hide, ST_FamilyStayCheck
            GuiControl, Hide, ST_FamilyStayNights
            GuiControl, Hide, ST_LblFamilyStayNightsDesc

            ST_SharedStayCheck := 0
            ST_SharedStayPeople := 0
            ST_FamilyStayCheck := 0
            ST_FamilyStayNights := 0
            GuiControl, SSOKTravel:, ST_SharedStayCheck, 0
            GuiControl, SSOKTravel:, ST_SharedStayPeople, 0
            GuiControl, SSOKTravel:, ST_FamilyStayCheck, 0
            GuiControl, SSOKTravel:, ST_FamilyStayNights, 0
            GuiControl, Disable, ST_SharedStayPeople
            GuiControl, Disable, ST_FamilyStayNights
        }
        else if (ST_FamilyStayCheck)
        {
            ; 친지숙박 선택 상태에서는 공동숙박 관련 컨트롤/문구를 전부 숨긴다.
            GuiControl, Hide, ST_SharedStayCheck
            GuiControl, Hide, ST_SharedStayPeople
            GuiControl, Hide, ST_LblSharedStayPeopleDesc
            GuiControl, Hide, ST_SharedStayInfo
            GuiControl, Show, ST_FamilyStayCheck
            GuiControl, Show, ST_FamilyStayNights
            GuiControl, Show, ST_LblFamilyStayNightsDesc
            GuiControl, Enable, ST_FamilyStayNights
        }
        else
        {
            GuiControl, Show, ST_SharedStayCheck
            GuiControl, Show, ST_SharedStayPeople
            GuiControl, Show, ST_LblSharedStayPeopleDesc
            GuiControl, Show, ST_SharedStayInfo
            GuiControl, Show, ST_FamilyStayCheck
            GuiControl, Show, ST_FamilyStayNights
            GuiControl, Show, ST_LblFamilyStayNightsDesc
            GuiControl, Disable, ST_FamilyStayNights
            GuiControl, Disable, ST_SharedStayPeople
        }

        if (ST_SharedStayCheck)
        {
            if (SSOK_Travel_Number(ST_SharedStayPeople) < 2)
            {
                ST_SharedStayPeople := 2
                GuiControl, SSOKTravel:, ST_SharedStayPeople, 2
            }
            GuiControl, Enable, ST_SharedStayPeople
            GuiControl, Hide, ST_FamilyStayCheck
            GuiControl, Hide, ST_FamilyStayNights
            GuiControl, Hide, ST_LblFamilyStayNightsDesc
        }

        if (ST_TravelCategory2)
        {
            infoStr := "당해 교육훈련기관이 청구하는 금액"
            GuiControl, SSOKTravel:, ST_LodgingAutoText, %infoStr%
            GuiControl, Enable, ST_LodgingActual
        }
        else
        {
            rName := SSOK_Travel_DetectLodgingRegionName(ST_Destination)
            if (isNoCap)
            {
                infoStr := rName . " (" . nights . "박) / 직급별 실비 지원 (상한액 없음)"
                GuiControl, SSOKTravel:, ST_LodgingAutoText, %infoStr%
                GuiControl, Enable, ST_LodgingActual
            }
            else
            {
                cap := SSOK_Travel_DetectLodgingCap(ST_Destination)
                capTotal := cap * nights
                capTotalStr := SSOK_Travel_Comma(capTotal)
                sharedPeopleDisplay := SSOK_Travel_Number(ST_SharedStayPeople)
                if (ST_SharedStayCheck && sharedPeopleDisplay < 2)
                    sharedPeopleDisplay := 2
                if (ST_SharedStayCheck && sharedPeopleDisplay >= 2)
                {
                    capDisplay := cap * sharedPeopleDisplay * nights
                    capUnitText := "(1박 " . SSOK_Travel_Comma(cap) . "원 × " . sharedPeopleDisplay . "명 × " . nights . "박)"
                    infoStr := rName . " (" . nights . "박) / 상한 " . SSOK_Travel_Comma(capDisplay) . "원 " . capUnitText
                }
                else
                    infoStr := rName . " (" . nights . "박) / 상한 " . capTotalStr . "원 (1박 " . SSOK_Travel_Comma(cap) . "원)"
                GuiControl, SSOKTravel:, ST_LodgingAutoText, %infoStr%
                GuiControl, Enable, ST_LodgingActual
            }
        }
        GuiControl, SSOKTravel:, ST_SharedStayInfo, % "공동숙박 선택 시 2명`n상한: 1박 단가 × 인원 × 숙박박수"
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

SSOK_Travel_GuiClose:
    ; 우측 상단 X 클릭 시 창만 숨기지 않고 SSOK 출장비 프로그램을 완전히 종료
    ExitApp
    return

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
        }
        else
        {
            eff := 11.97
            effUnit := "km/L"
            ; 플러그인은 일반 하이브리드와 분리하여 정확한 기준연비/전비 적용
            ; 플러그인 하이브리드(휘발유): 업무처리기준 10.61 km/L
            ; 일반 휘발유: 11.97 km/L
            ; 동일 유가라면 10.61 km/L 쪽의 산출 연료비가 더 높아지는 것이 산식상 정상이다.
            if (InStr(ST_FuelType, "플러그인 하이브리드(휘발유"))
                eff := 10.61
            else if (InStr(ST_FuelType, "플러그인 하이브리드(전기"))
            {
                eff := 2.84
                effUnit := "km/kWh"
            }
            else if (InStr(ST_FuelType, "일반 하이브리드(휘발유"))
                eff := 15.37
            else if (InStr(ST_FuelType, "일반 하이브리드(경유"))
                eff := 15.37
            else if (InStr(ST_FuelType, "경유"))
                eff := 12.52
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
            roundKm := oneWayKm
            fuelPriceRaw := RegExReplace(Trim(ST_FuelPrice . ""), ",", "")
            price := SSOK_Travel_Number(fuelPriceRaw)
            if (InStr(ST_FuelType, "전기") && price <= 0)
            {
                fuelCost := 0
                formulaStr := "전기차 충전단가 미입력 (영수증 단가 입력 필요)"
                carTotalText := "⚠️ 실제 충전단가(원/kWh)를 입력해주세요"
                return
            }
            else if (roundKm > 0 && price > 0 && eff > 0)
            {
                ; 가는편/오는편을 각각 계산하여 산출내용을 간결하게 표시한다.
                goFuelCalc := SSOK_Travel_Floor10((ST_GoDistance * 1.0 * price) / eff)
                backFuelCalc := SSOK_Travel_Floor10((ST_BackDistance * 1.0 * price) / eff)
                fuelCost := goFuelCalc + backFuelCalc
                formulaStr := "가는편 유류비 " . SSOK_Travel_Comma(goFuelCalc) . "원 / 오는편 유류비 " . SSOK_Travel_Comma(backFuelCalc) . "원"
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
        formulaStr := "대중교통 운임 " . SSOK_Travel_Comma(transportTotal) . "원"
    }
    else if (ST_TransType3) ; 관용차량
    {
        transportTotal := 0
        formulaStr := "관용차량·임차버스·렌트카 등 (운임 0원)"
    }
    else ; 기타 (타인차량 동승 외)
    {
        transportTotal := 0
        formulaStr := "타인차량 동승 등 기타 (운임 0원)"
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
    sharedStayPeople := SSOK_Travel_Number(ST_SharedStayPeople)
    if (sharedStayPeople < 0)
        sharedStayPeople := 0
    familyStayNights := SSOK_Travel_Number(ST_FamilyStayNights)
    if (familyStayNights < 0)
        familyStayNights := 0
    if (familyStayNights > nights)
        familyStayNights := nights

    ; 공동숙박: 총 숙박비가 지역별 숙박비 단가 × (출장자수-1) 이하일 때만 적용
    ; 숙박비를 지출하지 않은 인원수 = 총 출장인원 - (총숙박비/지역별 숙박비 단가), 소수점 이하는 올림
    sharedStayNights := (nights > 0 ? nights : 0)
    sharedStayAmount := 0
    sharedNoPayPeople := 0
    sharedCapBase := 0
    paidPeople := 0
    rawNoPay := 0
    if (ST_SharedStayCheck && sharedStayPeople > 1 && nights > 0)
    {
        isNoCap := (InStr(ST_Rank, "교장") || InStr(ST_Rank, "교육전문직"))
        sharedCapRate := SSOK_Travel_DetectLodgingCap(ST_Destination)
        ; 2026 학교회계 지침 기준:
        ; 총 숙박비 <= 기준단가 × (출장자수 - 1)
        ; 미지출 인원수 = 총 출장인원 - (총숙박비 ÷ 기준단가), 소수점 이하는 올림
        sharedPeriodCap := sharedCapRate * sharedStayNights
        sharedCapBase := sharedPeriodCap * (sharedStayPeople - 1)
        if (sharedCapRate > 0 && lodgingActual > 0 && lodgingActual <= sharedCapBase)
        {
            paidPeople := Ceil(lodgingActual / sharedPeriodCap)
            rawNoPay := sharedStayPeople - paidPeople
            sharedNoPayPeople := rawNoPay
            if (sharedNoPayPeople < 0)
                sharedNoPayPeople := 0
            sharedStayAmount := sharedNoPayPeople * 20000 * sharedStayNights
        }
    }

    familyStayAmount := ((!ST_TravelCategory2 && ST_FamilyStayCheck) ? familyStayNights * 20000 : 0)
    lodgingPayableNights := nights - familyStayNights
    if (lodgingPayableNights < 0)
        lodgingPayableNights := 0

    if (nights > 0)
    {
        if (ST_TravelCategory2)
        {
            lodgingTotal := lodgingActual
        }
        else
        {
            isNoCap := (InStr(ST_Rank, "교장") || InStr(ST_Rank, "교육전문직"))
            lodgingCap := SSOK_Travel_DetectLodgingCap(ST_Destination)
            lodgingCapTotal := lodgingCap * lodgingPayableNights

            ; 공동숙박 적용 시 실제 공동숙박 총액을 개인 1인의 상한액으로
            ; 잘라버리지 않는다. 공동숙박 추가지원과 별도로 실제 숙박비를 인정한다.
            ; 예: 광역시 3명·1박 / 상한 80,000원 / 실제 160,000원
            ;     → 실제 숙박비 160,000원 + 추가지원 20,000원 = 180,000원
            if (ST_SharedStayCheck && sharedStayPeople > 1 && sharedStayNights > 0)
            {
                sharedGroupCapTotal := lodgingCap * sharedStayPeople * sharedStayNights
                lodgingTotal := (isNoCap ? lodgingActual : (lodgingActual > sharedGroupCapTotal ? sharedGroupCapTotal : lodgingActual))
            }
            else
                lodgingTotal := (isNoCap ? lodgingActual : (lodgingActual > lodgingCapTotal ? lodgingCapTotal : lodgingActual))
        }
        ; 숙박비 총액 = 인정되는 실제 숙박비 + 공동숙박 추가지원금 + 친지숙박 지급액
        lodgingRecognizedActual := lodgingTotal
        lodgingAdditionalTotal := sharedStayAmount + familyStayAmount
        lodgingTotal := lodgingRecognizedActual + lodgingAdditionalTotal
    }
    else
    {
        lodgingRecognizedActual := 0
        lodgingTotal := 0
    }

    ; 5. 총액 산출 및 화면 표시
    ; --------------------------------------------------------------------------
    ; 출발지-도착지간 편도 주행거리가 12km 이하이면 무조건 일비 20,000원만 지급한다.
    localDistanceKm := SSOK_Travel_Number(ST_GoDistance)
    if (localDistanceKm <= 0 && SSOK_Travel_Number(ST_Distance) > 0)
        localDistanceKm := SSOK_Travel_Number(ST_Distance) / 2.0
    if (localDistanceKm > 0 && localDistanceKm <= 12.0)
    {
        transportTotal := 0
        dailyTotal := 20000
        mealTotal := 0
        lodgingTotal := 0
    }
    if (ST_SharedStayCheck && sharedStayPeople > 1 && nights > 0)
    {
        if (sharedStayAmount > 0)
            sharedInfoText := "실제소요액이 상한액×(출장자수-1)×숙박박수 이하로 지출하여 숙박비를 지출하지 않은 인원수당 20,000원(1야 기준) 추가 지급`n" . "숙박비 미지출 인원수 × " . sharedStayNights . "박 = 총 출장인원 " . sharedStayPeople . "명 − ⌈실제소요액(" . SSOK_Travel_Comma(lodgingActual) . "원) ÷ (" . SSOK_Travel_Comma(sharedCapRate) . "원 × " . sharedStayNights . "박)⌉ = " . sharedNoPayPeople . "명`n" . sharedNoPayPeople . "명 × 20,000원 × " . sharedStayNights . "박 = " . SSOK_Travel_Comma(sharedStayAmount) . "원"
        else if (lodgingActual <= 0)
            sharedInfoText := "공동숙박 " . sharedStayPeople . "명 / 실제소요액 0원 → 공동숙박 추가지원금 0원"
        else
            sharedInfoText := "공동숙박 " . sharedStayPeople . "명 / 적용조건 미충족`n실제소요액 " . SSOK_Travel_Comma(lodgingActual) . "원 > 상한액×(출장자수-1)×숙박박수 " . SSOK_Travel_Comma(sharedCapBase) . "원"
        GuiControl, SSOKTravel:, ST_SharedStayInfo, %sharedInfoText%
    }
    else if (nights > 0)
        GuiControl, SSOKTravel:, ST_SharedStayInfo, % "공동숙박 선택 시 2명`n상한: 1박 단가 × 인원 × 숙박박수"

    grandTotal := transportTotal + dailyTotal + mealTotal + lodgingTotal

    totalStr := SSOK_Travel_Comma(grandTotal) . " 원"
    GuiControl, SSOKTravel:, ST_Total, %totalStr%

    summaryText := "운임 " . SSOK_Travel_Comma(transportTotal) . "원 | 일비 " . SSOK_Travel_Comma(dailyTotal) . "원 | 식비 " . SSOK_Travel_Comma(mealTotal) . "원 | 숙박비 " . SSOK_Travel_Comma(lodgingTotal) . "원"
    GuiControl, SSOKTravel:, ST_TotalSummary, %summaryText%
    SSOK_Travel_UpdateInputHighlights()

    return

; ==============================================================================
; [거리 / 유가 조회] - 모호한 목적지 확인/선택 팝업 및 정확한 거리 산출
; ==============================================================================
; 경유지 반영 선택 변경
SSOK_Travel_OnStopoverRouteChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    SSOK_Travel_RecalculateCarRoutes()
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnAmountEditChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    ; 입력 중인 값을 다시 GuiControl로 덮어쓰지 않는다.
    ; 따라서 숫자를 자유롭게 입력할 수 있고, 공동숙박/숙박비 변경도 즉시 반영된다.
    SSOK_Travel_AutoSave()
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnSharedStayPeopleChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    ; 공동숙박 인원 입력 변경 시 왼쪽 숙박 상한을 즉시 갱신한다.
    ; 도착지 검색/자동경로 함수는 호출하지 않는다.
    people := SSOK_Travel_Number(ST_SharedStayPeople)
    if (ST_SharedStayCheck && people < 2)
    {
        people := 2
        ST_SharedStayPeople := 2
        GuiControl, SSOKTravel:, ST_SharedStayPeople, 2
    }

    Gosub, SSOK_Travel_UpdateLodgingInfo
    SSOK_Travel_AutoSave()
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnSharedStayChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (ST_SharedStayCheck)
    {
        ; 공동숙박을 선택하면 친지숙박은 즉시 해제하고 관련 문구를 숨긴다.
        ST_FamilyStayCheck := 0
        ST_FamilyStayNights := 0
        GuiControl, SSOKTravel:, ST_FamilyStayCheck, 0
        GuiControl, SSOKTravel:, ST_FamilyStayNights, 0
        GuiControl, SSOKTravel:Disable, ST_FamilyStayNights
        GuiControl, Hide, ST_FamilyStayCheck
        GuiControl, Hide, ST_FamilyStayNights
        GuiControl, Hide, ST_LblFamilyStayNightsDesc

        ; 공동숙박을 처음 선택하면 기본 인원은 2명
        if (SSOK_Travel_Number(ST_SharedStayPeople) < 2)
        {
            ST_SharedStayPeople := 2
            GuiControl, SSOKTravel:, ST_SharedStayPeople, 2
        }
        GuiControl, Show, ST_SharedStayCheck
        GuiControl, Show, ST_SharedStayPeople
        GuiControl, Show, ST_LblSharedStayPeopleDesc
        GuiControl, Show, ST_SharedStayInfo
        GuiControl, SSOKTravel:Enable, ST_SharedStayPeople
        ; 인원을 2명으로 설정한 직후 왼쪽 상한액도 2명 기준으로 즉시 갱신한다.
        Gosub, SSOK_Travel_UpdateLodgingInfo
        GuiControl, SSOKTravel:Focus, ST_SharedStayPeople
    }
    else
    {
        ; 공동숙박 해제: 공동숙박 인원/추가 지급 계산을 즉시 0으로 되돌린다.
        ST_SharedStayPeople := 0
        GuiControl, SSOKTravel:, ST_SharedStayPeople, 0
        GuiControl, SSOKTravel:Disable, ST_SharedStayPeople
        GuiControl, Show, ST_FamilyStayCheck
        GuiControl, Show, ST_FamilyStayNights
        GuiControl, Show, ST_LblFamilyStayNightsDesc
        GuiControl, Hide, ST_SharedStayInfo
    }
    ; 체크/해제 직후 현재 선택 상태를 기준으로 숙박비와 총액을 다시 산출한다.
    Gosub, SSOK_Travel_UpdateLodgingInfo
    SSOK_Travel_AutoSave()
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_OnFamilyStayChange:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    if (ST_FamilyStayCheck)
    {
        ; 친지숙박을 선택하면 공동숙박은 즉시 해제하고 관련 문구를 숨긴다.
        ST_SharedStayCheck := 0
        ST_SharedStayPeople := 0
        GuiControl, SSOKTravel:, ST_SharedStayCheck, 0
        GuiControl, SSOKTravel:, ST_SharedStayPeople, 0
        GuiControl, SSOKTravel:Disable, ST_SharedStayPeople
        GuiControl, Hide, ST_SharedStayCheck
        GuiControl, Hide, ST_SharedStayPeople
        GuiControl, Hide, ST_LblSharedStayPeopleDesc
        GuiControl, Hide, ST_SharedStayInfo

        GuiControl, SSOKTravel:, ST_FamilyStayNights, 1
        GuiControl, SSOKTravel:Enable, ST_FamilyStayNights
        GuiControl, Show, ST_FamilyStayCheck
        GuiControl, Show, ST_FamilyStayNights
        GuiControl, Show, ST_LblFamilyStayNightsDesc
        Gosub, SSOK_Travel_UpdateLodgingInfo
    }
    else
    {
        ; 친지숙박 해제: 친지숙박 박수/추가 지급 계산을 즉시 0으로 되돌린다.
        ST_FamilyStayNights := 0
        GuiControl, SSOKTravel:, ST_FamilyStayNights, 0
        GuiControl, SSOKTravel:Disable, ST_FamilyStayNights
        GuiControl, Show, ST_SharedStayCheck
        GuiControl, Show, ST_SharedStayPeople
        GuiControl, Show, ST_LblSharedStayPeopleDesc
        GuiControl, Show, ST_SharedStayInfo
    }
    ; 체크/해제 직후 현재 선택 상태를 기준으로 숙박비와 총액을 다시 산출한다.
    Gosub, SSOK_Travel_UpdateLodgingInfo
    SSOK_Travel_AutoSave()
    Gosub, SSOK_Travel_Calc
    return

SSOK_Travel_UpdateCarRouteDisplay:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    depShort := SSOK_Travel_ShortPlace(ST_Departure)
    destShort := SSOK_Travel_ShortPlace(ST_Destination)
    viaShort := SSOK_Travel_ShortPlace(ST_Stopover)

    goLine := "가는편: " . depShort
    if (ST_GoViaCheck && Trim(ST_Stopover) != "")
        goLine .= " → " . viaShort
    goLine .= " → " . destShort . " (" . SSOK_Travel_FormatDist(ST_GoDistance) . " km)"

    backLine := "오는편: " . destShort
    if (ST_BackViaCheck && Trim(ST_Stopover) != "")
        backLine .= " → " . viaShort
    backLine .= " → " . depShort . " (" . SSOK_Travel_FormatDist(ST_BackDistance) . " km)"

    GuiControl, SSOKTravel:, ST_GoRouteLine, %goLine%
    GuiControl, SSOKTravel:, ST_BackRouteLine, %backLine%
    if (Trim(ST_Stopover) != "")
    {
        GuiControl, SSOKTravel:Show, ST_GoViaCheck
        GuiControl, SSOKTravel:Show, ST_BackViaCheck
    }
    else
    {
        GuiControl, SSOKTravel:Hide, ST_GoViaCheck
        GuiControl, SSOKTravel:Hide, ST_BackViaCheck
    }
    return

SSOK_Travel_ShortPlace(name)
{
    name := Trim(name)
    if (name = "")
        return "미입력"

    ; 주요 광역시·특별자치시가 장소명 중간에 포함되어도 지명만 표시한다.
    if RegExMatch(name, "(서울|부산|대구|인천|광주|대전|울산|세종|제주)")
        return RegExReplace(name, ".*(서울|부산|대구|인천|광주|대전|울산|세종|제주).*", "$1")

    ; 국립한국해양대학교 등 장소명에 지역명이 없는 대표 장소는 실제 소재 도시명으로 표시한다.
    if InStr(name, "한국해양대학교")
        return "부산"

    if RegExMatch(name, "^(경기|강원|충북|충남|전북|전남|경북|경남)")
        return RegExReplace(name, "^(경기|강원|충북|충남|전북|전남|경북|경남).*$", "$1")

    if RegExMatch(name, "^([가-힣]{2,3})(시|군|구)")
        return RegExReplace(name, "^([가-힣]{2,3})(시|군|구).*$", "$1")

    if (StrLen(name) > 3)
        return SubStr(name, 1, 3)
    return name
}

SSOK_Travel_RecalculateCarRoutes()
{
    global ST_Departure, ST_Destination, ST_Stopover
    global ST_DepLon, ST_DepLat, ST_DepName, ST_DestLon, ST_DestLat, ST_DestName
    global ST_ViaLon, ST_ViaLat, ST_ViaName, ST_Distance
    global ST_GoDistance, ST_BackDistance, ST_GoViaCheck, ST_BackViaCheck

    ST_GoDistance := 0
    ST_BackDistance := 0

    if (ST_DepLon = 0 || ST_DepLat = 0)
    {
        if (ST_Departure != "")
            SSOK_Travel_GetCoords(ST_Departure, ST_DepLon, ST_DepLat, ST_DepName)
    }
    if (ST_DestLon = 0 || ST_DestLat = 0)
    {
        if (ST_Destination != "")
            SSOK_Travel_GetCoords(ST_Destination, ST_DestLon, ST_DestLat, ST_DestName)
    }
    if (Trim(ST_Stopover) != "" && (ST_ViaLon = 0 || ST_ViaLat = 0))
        SSOK_Travel_GetCoords(ST_Stopover, ST_ViaLon, ST_ViaLat, ST_ViaName)

    if (ST_DepLon = 0 || ST_DepLat = 0 || ST_DestLon = 0 || ST_DestLat = 0)
    {
        GuiControl, SSOKTravel:, ST_Distance, 0.0
        Gosub, SSOK_Travel_UpdateCarRouteDisplay
        return
    }

    coordsGo := ""
    if (ST_GoViaCheck && ST_ViaLon != 0 && ST_ViaLat != 0)
        ST_GoDistance := SSOK_Travel_GetDistanceAndRoute(ST_DepLon, ST_DepLat, ST_DestLon, ST_DestLat, coordsGo, ST_ViaLon, ST_ViaLat)
    else
        ST_GoDistance := SSOK_Travel_GetDistanceAndRoute(ST_DepLon, ST_DepLat, ST_DestLon, ST_DestLat, coordsGo)

    coordsBack := ""
    if ((!ST_GoViaCheck && !ST_BackViaCheck) || (ST_GoViaCheck && ST_BackViaCheck))
    {
        ; 같은 경로 조건에서는 방향에 따른 API 거리 차이를 없애고 동일한 편도거리로 사용한다.
        ST_BackDistance := ST_GoDistance
    }
    else if (ST_BackViaCheck && ST_ViaLon != 0 && ST_ViaLat != 0)
        ST_BackDistance := SSOK_Travel_GetDistanceAndRoute(ST_DestLon, ST_DestLat, ST_DepLon, ST_DepLat, coordsBack, ST_ViaLon, ST_ViaLat)
    else
        ST_BackDistance := SSOK_Travel_GetDistanceAndRoute(ST_DestLon, ST_DestLat, ST_DepLon, ST_DepLat, coordsBack)

    totalKm := ST_GoDistance + ST_BackDistance
    GuiControl, SSOKTravel:, ST_Distance, % SSOK_Travel_FormatDist(totalKm)
    ST_Distance := SSOK_Travel_FormatDist(totalKm)

    Gosub, SSOK_Travel_UpdateCarRouteDisplay
    return
}

; 거리 / 유가 재산정: 웹 재조회 없이 현재 숫자만 검증하여 재계산
SSOK_Travel_RecalculateCar:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide
    sDate := SubStr(ST_StartDate, 1, 8)
    dist := SSOK_Travel_Number(ST_Distance)
    ; 유가는 숫자로 다시 포맷하지 않고 원문 문자열을 별도로 보존한다.
    ; AHK SetFormat(FloatFast) 때문에 1859.33이 1859.30으로 바뀌는 것을 방지한다.
    fuelPriceRaw := RegExReplace(Trim(ST_FuelPrice . ""), ",", "")
    price := SSOK_Travel_Number(fuelPriceRaw)
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
        GuiControl, SSOKTravel:, ST_ChargeRateResult, % "전기 kWh 단가를 입력하세요"
    }
    else if (InStr(ST_FuelType, "수소") && price <= 0)
    {
        GuiControl, SSOKTravel:, ST_FuelPrice, 9900
        price := 9900
    }
    GuiControl, SSOKTravel:, ST_Distance, % SSOK_Travel_FormatDist(dist)

    ; 휘발유/경유/LPG/하이브리드는 재산정 시 오피넷 공식 가격을 다시 조회하고
    ; 반환된 문자열을 그대로 화면에 넣는다. 따라서 1859.33 → 1859.30 변환이 발생하지 않는다.
    if (!InStr(ST_FuelType, "전기") && !InStr(ST_FuelType, "수소") && !InStr(ST_FuelType, "플러그인 하이브리드(전기"))
    {
        priceFuelLookup := ST_FuelType
        if (InStr(ST_FuelType, "일반 하이브리드(휘발유") || InStr(ST_FuelType, "플러그인 하이브리드(휘발유"))
            priceFuelLookup := "휘발유"
        else if (InStr(ST_FuelType, "일반 하이브리드(경유"))
            priceFuelLookup := "경유"
        officialRaw := SSOK_Travel_GetCachedOrFetchFuelPrice(priceFuelLookup, sDate)
        if (officialRaw > 0)
        {
            fuelPriceRaw := Trim(officialRaw . "")
            price := SSOK_Travel_Number(fuelPriceRaw)
            GuiControl, SSOKTravel:, ST_FuelPrice, %fuelPriceRaw%
        }
    }
    else if (price > 0)
    {
        ; 전기/수소는 사용자가 입력한 단가의 원문을 그대로 유지한다.
        GuiControl, SSOKTravel:, ST_FuelPrice, %fuelPriceRaw%
    }

    Gosub, SSOK_Travel_Calc
    ToolTip, % "거리·유가를 오피넷 기준으로 재산정했습니다."
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
    if (InStr(ST_FuelType, "전기"))
        fuelUrl := "https://ev.or.kr/nportal/evcarInfo/initEvcarChargePriceV2.do"
    else if (InStr(ST_FuelType, "수소"))
        fuelUrl := "https://www.ev.or.kr/nportal/evcarInfo/initH2ChargePrice.do"
    else if (InStr(ST_FuelType, "LPG"))
        fuelUrl := "https://www.opinet.co.kr/user/dopvsavsel/dopVsAvselSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_K015_P=Y"
    else
        fuelUrl := "https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_B027=Y&OIL_CD_D047=Y"

    ; 경유지가 입력되어 있는데 좌표가 아직 없으면 인터넷 조회 전에 다시 좌표를 확보한다.
    if (ST_Stopover != "" && (ST_ViaLon = 0 || ST_ViaLat = 0))
        SSOK_Travel_GetCoords(ST_Stopover, ST_ViaLon, ST_ViaLat, ST_ViaName)

    enc1 := SSOK_Travel_UriEncode(ST_DepName != "" ? ST_DepName : ST_Departure)
    enc2 := SSOK_Travel_UriEncode(ST_DestName != "" ? ST_DestName : ST_Destination)

    ; 인터넷 조회는 카카오맵 자동차 길찾기만 사용한다.
    ; 카카오 공식 URL은 출발지 / 경유지 / 목적지를 순서대로 지정할 수 있다.
    kakaoRouteUrl := ""
    if (ST_Stopover != "" && ST_ViaLon != 0 && ST_ViaLat != 0)
    {
        encVia := SSOK_Travel_UriEncode(ST_ViaName != "" ? ST_ViaName : ST_Stopover)
        kakaoRouteUrl := "https://map.kakao.com/link/by/car/" . enc1 . "," . ST_DepLat . "," . ST_DepLon . "/" . encVia . "," . ST_ViaLat . "," . ST_ViaLon . "/" . enc2 . "," . ST_DestLat . "," . ST_DestLon
    }
    else
    {
        kakaoRouteUrl := "https://map.kakao.com/link/by/car/" . enc1 . "," . ST_DepLat . "," . ST_DepLon . "/" . enc2 . "," . ST_DestLat . "," . ST_DestLon
    }
    try Run, %kakaoRouteUrl%
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
        if (ST_GoViaCheck && lonVia && latVia)
            km := SSOK_Travel_GetDistanceAndRoute(lon1, lat1, lon2, lat2, routeCoords, lonVia, latVia)
        else
            km := SSOK_Travel_GetDistanceAndRoute(lon1, lat1, lon2, lat2, routeCoords)
    }

    kmStr := SSOK_Travel_FormatDist(km)
    if (km > 0)
        GuiControl, SSOKTravel:, ST_Distance, %kmStr%
    else
        GuiControl, SSOKTravel:, ST_Distance, 0.0

    sDate := SubStr(ST_StartDate, 1, 8)
    if (!InStr(ST_FuelType, "플러그인 하이브리드(전기"))
    {
        price := SSOK_Travel_GetCachedOrFetchFuelPrice(ST_FuelType, sDate)
        if (price > 0 && ST_TransType1)
            GuiControl, SSOKTravel:, ST_FuelPrice, %price%
    }

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
        ; 수소차는 전기차 충전요금 페이지가 아니라 수소충전소 정보 조회로 연결한다.
        statUrl := "https://www.ev.or.kr/nportal/monitor/evMap.do?p_etc=Y"
    }
    else if (InStr(ST_FuelType, "LPG"))
    {
        statUrl := "https://www.opinet.co.kr/user/dopvsavsel/dopVsAvselSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_K015_P=Y"
    }
    else
    {
        statUrl := "https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_B027=Y&OIL_CD_D047=Y"
    }

    if (lon1 && lat1 && lon2 && lat2 && ST_TransType1)
    {
        enc1 := SSOK_Travel_UriEncode(ST_DepName)
        enc2 := SSOK_Travel_UriEncode(ST_DestName)
        kakaoRouteUrl := ""

        if (lonVia && latVia)
        {
            encVia := SSOK_Travel_UriEncode(ST_ViaName)
            kakaoRouteUrl := "https://map.kakao.com/link/by/car/" . enc1 . "," . lat1 . "," . lon1 . "/" . encVia . "," . latVia . "," . lonVia . "/" . enc2 . "," . lat2 . "," . lon2
        }
        else
        {
            kakaoRouteUrl := "https://map.kakao.com/link/by/car/" . enc1 . "," . lat1 . "," . lon1 . "/" . enc2 . "," . lat2 . "," . lon2
        }

        try {
            Run, %kakaoRouteUrl%
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
    global ST_TransType1, ST_StartDate, ST_FuelType
    SSOK_Travel_RecalculateCarRoutes()

    sDate := SubStr(ST_StartDate, 1, 8)
    if (ST_TransType1 && !InStr(ST_FuelType, "플러그인 하이브리드(전기"))
    {
        price := SSOK_Travel_GetCachedOrFetchFuelPrice(ST_FuelType, sDate)
        if (price > 0)
            GuiControl, SSOKTravel:, ST_FuelPrice, % SSOK_Travel_FormatFuelPrice(price)
        else
            GuiControl, SSOKTravel:, ST_FuelPrice, ""
    }
    Gosub, SSOK_Travel_Calc
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
    ; 소속/직급/성명/출발지만 INI에서 유지
    keepOrg := defaultOrg
    IniRead, keepRank, %SSOK_Ini%, Travel, Rank, 교사
    if (keepRank = "ERROR" || keepRank = "")
        keepRank := "교사"
    IniRead, keepName, %SSOK_Ini%, Travel, Name, %A_Space%
    if (keepName = "ERROR")
        keepName := ""
    keepDep := keepOrg
    GuiControl, SSOKTravel:, ST_Org, %keepOrg%
    GuiControl, SSOKTravel:ChooseString, ST_Rank, %keepRank%
    GuiControl, SSOKTravel:, ST_Name, %keepName%
    GuiControl, SSOKTravel:, ST_Departure, %keepDep%
    GuiControl, SSOKTravel:, ST_Destination, 
    GuiControl, SSOKTravel:, ST_Stopover, 
    GuiControl, SSOKTravel:, ST_GoViaCheck, 0
    GuiControl, SSOKTravel:, ST_BackViaCheck, 0
    GuiControl, SSOKTravel:Disable, ST_FamilyStayNights
    GuiControl, SSOKTravel:, ST_GoRouteLine, % "가는편: 출발지 → 도착지 (0.0 km)"
    GuiControl, SSOKTravel:, ST_BackRouteLine, % "오는편: 도착지 → 출발지 (0.0 km)"
    GuiControl, SSOKTravel:, ST_Distance, 0.0
    GuiControl, SSOKTravel:, ST_ChargeAmount,
    GuiControl, SSOKTravel:, ST_ChargeKwh,
    GuiControl, SSOKTravel:, ST_ChargeRateResult, % "전기 kWh 단가를 입력하세요"
    GuiControl, SSOKTravel:, ST_FuelPrice, 295.0
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
    GuiControl, SSOKTravel:, ST_SharedStayCheck, 0
    GuiControl, SSOKTravel:, ST_SharedStayPeople, 0
    GuiControl, SSOKTravel:, ST_FamilyStayCheck, 0
    GuiControl, SSOKTravel:, ST_FamilyStayNights, 0
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
    ST_GoDistance := 0, ST_BackDistance := 0, ST_GoViaCheck := 0, ST_BackViaCheck := 0

    Gosub, SSOK_Travel_UpdateTransportUI
    Gosub, SSOK_Travel_UpdateCategoryUI
    Gosub, SSOK_Travel_UpdateMealUI
    Gosub, SSOK_Travel_UpdateLodgingInfo
    Gosub, SSOK_Travel_Calc
    return

; ==============================================================================
; [설정 저장] 소속 / 출발지 / 직급 / 성명만 저장
; ==============================================================================
SSOK_Travel_SaveSettings:
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    if (Trim(ST_Org) = "")
    {
        MsgBox, 48, 설정 저장, 소속을 입력해 주세요.
        GuiControl, SSOKTravel:Focus, ST_Org
        return
    }

    ; 소속을 저장하면 출발지도 같은 값으로 저장한다.
    ST_Departure := ST_Org
    GuiControl, SSOKTravel:, ST_Departure, %ST_Departure%

    IniWrite, %ST_Org%, %SSOK_Ini%, Travel, Org
    IniWrite, %ST_Departure%, %SSOK_Ini%, Travel, Departure
    IniWrite, %ST_Rank%, %SSOK_Ini%, Travel, Rank
    IniWrite, %ST_Name%, %SSOK_Ini%, Travel, Name

    ; 저장 후 버튼이 가려지지 않도록 실제 컨트롤을 다시 배치하고 즉시 그린다.
    GuiControl, MoveDraw, ST_SaveSettingsButton, x545 y790 w97 h36

    ; 설정 저장 완료 안내창은 표시하지 않는다.
return

; ==============================================================================
; [여비정산서 인쇄] (HTML 생성 및 인쇄 다이얼로그)
; ==============================================================================
SSOK_Travel_PrintHtml:
    SSOK_Travel_AutoSave()
    Gui, SSOKTravel:Default
    Gui, SSOKTravel:Submit, NoHide

    global ST_RailGo, ST_RailVia, ST_RailBack, ST_BusGo, ST_BusVia, ST_BusBack, ST_ShipGo, ST_ShipVia, ST_ShipBack, ST_AirGo, ST_AirVia, ST_AirBack
    global ST_GoDistance, ST_BackDistance, ST_GoViaCheck, ST_BackViaCheck
    ; 출발지 자동 보정
    if (ST_Org != "" && (ST_Departure = "" || InStr(ST_Org, ST_Departure) = 1))
    {
        ST_Departure := ST_Org
        GuiControl, SSOKTravel:, ST_Departure, %ST_Departure%
    }

    if (Trim(ST_Destination) = "")
    {
        MsgBox, 48, 필수 입력, 도착지를 입력해야 정산서를 인쇄할 수 있습니다.
        GuiControl, Focus, ST_Destination
        return
    }

    if (ST_TransType1)
    {
        if (ST_CarReason = "" || InStr(ST_CarReason, "선택하세요"))
        {
            MsgBox, 48, 필수 입력, 자가용 이용 시 신청사유를 선택해 주세요.
            GuiControl, Focus, ST_CarReason
            return
        }
        if (ST_FuelType = "" || InStr(ST_FuelType, "선택하세요"))
        {
            MsgBox, 48, 필수 입력, 자가용 이용 시 유종을 선택해 주세요.
            GuiControl, Focus, ST_FuelType
            return
        }
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

    ; 전기차·수소차는 충전단가가 없을 경우 각각의 기본단가를 적용한다.
    ; 충전요금과 충전량을 모두 입력하면 OnChargeInput에서 실제 단가로 자동 산출한다.
    if (ST_TransType1 && (InStr(ST_FuelType, "전기") || InStr(ST_FuelType, "수소")))
    {
        chargePrice := SSOK_Travel_Number(ST_FuelPrice)
        if (chargePrice <= 0)
        {
            chargePrice := (InStr(ST_FuelType, "수소") ? 9900 : 295.0)
            GuiControl, SSOKTravel:, ST_FuelPrice, %chargePrice%
        }
        ; 충전 증빙 확인 팝업은 표시하지 않는다.
        ; 제출 안내는 인쇄물의 [증빙서류 첨부] 항목으로만 표시한다.
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

    hasVia := (ST_TransType2 ? hasValidTransitVia : (ST_GoViaCheck || ST_BackViaCheck))
    ; 인쇄용 편도/왕복 거리를 실제 가는편·오는편 거리에서 계산한다.
    ; 화면 표시는 항상 소수점 1자리로 반올림한다.
    oneWayDist := (SSOK_Travel_Number(ST_GoDistance) + SSOK_Travel_Number(ST_BackDistance)) / 2.0
    roundDist := SSOK_Travel_Number(ST_GoDistance) + SSOK_Travel_Number(ST_BackDistance)
    displayOneWayDist := oneWayDist
    fuelPriceRawPrint := RegExReplace(Trim(ST_FuelPrice . ""), ",", "")
    price := SSOK_Travel_Number(fuelPriceRawPrint)

    ; 정산서의 유가는 화면 입력값이 아니라 오피넷 원문 단가를 다시 조회하여 사용한다.
    ; 전기·수소는 기존 입력/기준 로직을 그대로 유지한다.
    if (!InStr(ST_FuelType, "전기") && !InStr(ST_FuelType, "수소") && !InStr(ST_FuelType, "플러그인 하이브리드(전기"))
    {
        printFuelLookup := ST_FuelType
        if (InStr(ST_FuelType, "일반 하이브리드(휘발유") || InStr(ST_FuelType, "플러그인 하이브리드(휘발유"))
            printFuelLookup := "휘발유"
        else if (InStr(ST_FuelType, "일반 하이브리드(경유"))
            printFuelLookup := "경유"
        officialPrintPrice := SSOK_Travel_GetCachedOrFetchFuelPrice(printFuelLookup, sDate)
        if (officialPrintPrice > 0)
        {
            fuelPriceRawPrint := Trim(officialPrintPrice . "")
            price := SSOK_Travel_Number(fuelPriceRawPrint)
        }
    }

    eff := 11.97
    effUnit := "km/L"
    fuelNameOnly := "휘발유"
    if (InStr(ST_FuelType, "일반 하이브리드(휘발유"))
    {
        eff := 15.37, fuelNameOnly := "일반 하이브리드(휘발유)"
    }
    else if (InStr(ST_FuelType, "일반 하이브리드(경유"))
    {
        eff := 15.37, fuelNameOnly := "일반 하이브리드(경유)"
    }
    else if (InStr(ST_FuelType, "플러그인 하이브리드(휘발유"))
    {
        eff := 10.61, fuelNameOnly := "플러그인 하이브리드(휘발유)"
    }
    else if (InStr(ST_FuelType, "플러그인 하이브리드(전기"))
    {
        eff := 2.84, fuelNameOnly := "플러그인 하이브리드(전기)"
    }
    else if (InStr(ST_FuelType, "경유"))
    {
        eff := 12.52, fuelNameOnly := "경유"
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
        ; 공무원 여비업무 처리기준 산식:
        ; 여행거리(km) × 유가/충전단가 ÷ 연비(전비)
        ; 가는편과 오는편을 각각 계산한 뒤 합산한다.
        goFuelPrint := SSOK_Travel_Floor10((ST_GoDistance * price) / eff)
        backFuelPrint := SSOK_Travel_Floor10((ST_BackDistance * price) / eff)
        fuelCost := goFuelPrint + backFuelPrint
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
    lodgingActual := SSOK_Travel_Floor10(ST_LodgingActual)
    sharedStayPeople := SSOK_Travel_Number(ST_SharedStayPeople)
    if (sharedStayPeople < 0)
        sharedStayPeople := 0
    familyStayNights := SSOK_Travel_Number(ST_FamilyStayNights)
    if (familyStayNights < 0)
        familyStayNights := 0
    if (familyStayNights > nights)
        familyStayNights := nights
    sharedStayNights := (nights > 0 ? nights : 0)
    sharedStayAmount := 0
    sharedNoPayPeople := 0
    sharedCapBase := 0
    sharedCapRate := lodgingCap
    if (ST_SharedStayCheck && sharedStayPeople > 1 && nights > 0)
    {
        ; 2026 학교회계 지침 기준:
        ; 총 숙박비 <= 기준단가 × (출장자수 - 1)
        ; 미지출 인원수 = 총 출장인원 - (총숙박비 ÷ 기준단가), 소수점 이하는 올림
        sharedPeriodCap := sharedCapRate * sharedStayNights
        sharedCapBase := sharedPeriodCap * (sharedStayPeople - 1)
        if (sharedCapRate > 0 && lodgingActual > 0 && lodgingActual <= sharedCapBase)
        {
            paidPeople := Ceil(lodgingActual / sharedPeriodCap)
            rawNoPay := sharedStayPeople - paidPeople
            sharedNoPayPeople := rawNoPay
            if (sharedNoPayPeople < 0)
                sharedNoPayPeople := 0
            sharedStayAmount := sharedNoPayPeople * 20000 * sharedStayNights
        }
    }
    familyStayAmount := ((!ST_TravelCategory2 && ST_FamilyStayCheck) ? familyStayNights * 20000 : 0)
    lodgingPayableNights := nights - familyStayNights
    if (lodgingPayableNights < 0)
        lodgingPayableNights := 0
    lodgingCapTotal := lodgingCap * lodgingPayableNights
    lodgingTotal := 0
    if (nights > 0)
    {
        if (ST_TravelCategory2)
            lodgingTotal := lodgingActual
        else if (ST_SharedStayCheck && sharedStayPeople > 1 && sharedStayNights > 0)
        {
            sharedGroupCapTotal := lodgingCap * sharedStayPeople * sharedStayNights
            lodgingTotal := (isNoCap ? lodgingActual : (lodgingActual > sharedGroupCapTotal ? sharedGroupCapTotal : lodgingActual))
        }
        else
            lodgingTotal := (isNoCap ? lodgingActual : (lodgingActual > lodgingCapTotal ? lodgingCapTotal : lodgingActual))
        lodgingRecognizedActual := lodgingTotal
        ; 인쇄용 숙박비 총액 = 인정 실제숙박비 + 공동숙박 추가지원금 + 친지숙박 지급액
        lodgingTotal := lodgingRecognizedActual + sharedStayAmount + familyStayAmount
    }
    else
    {
        lodgingRecognizedActual := 0
        lodgingTotal := 0
    }
    ; 출발지-도착지간 편도 주행거리가 12km 이하이면 무조건 일비 20,000원만 지급한다.
    localDistanceKm := SSOK_Travel_Number(ST_GoDistance)
    if (localDistanceKm <= 0 && SSOK_Travel_Number(ST_Distance) > 0)
        localDistanceKm := SSOK_Travel_Number(ST_Distance) / 2.0
    if (localDistanceKm > 0 && localDistanceKm <= 12.0)
    {
        transportTotal := 0
        dailyTotal := 20000
        mealTotal := 0
        lodgingTotal := 0
    }
    grandTotal := transportTotal + dailyTotal + mealTotal + lodgingTotal

    ; --------------------------------------------------------------------------
    ; 원문 조회 주소
    ; --------------------------------------------------------------------------
    sY := SubStr(sDate, 1, 4)
    sM := SubStr(sDate, 5, 2)
    sD := SubStr(sDate, 7, 2)
    opinetUrl := ""
    if (InStr(ST_FuelType, "전기"))
        opinetUrl := "https://ev.or.kr/nportal/evcarInfo/initEvcarChargePriceV2.do"
    else if (InStr(ST_FuelType, "수소"))
        opinetUrl := "https://www.ev.or.kr/nportal/monitor/evMap.do?p_etc=Y"
    else if (InStr(ST_FuelType, "LPG"))
        opinetUrl := "https://www.opinet.co.kr/user/dopvsavsel/dopVsAvselSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_K015_P=Y"
    else
        opinetUrl := "https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgSelect.do?TERM=D&STA_Y=" . sY . "&STA_M=" . sM . "&STA_D=" . sD . "&END_Y=" . sY . "&END_M=" . sM . "&END_D=" . sD . "&OIL_CD_B027=Y&OIL_CD_D047=Y"

    ; --------------------------------------------------------------------------


    ; --------------------------------------------------------------------------
    ; 인쇄용 HTML - 정확히 3매 (A4 실물 규격 미리보기 및 인쇄)
    ; 1매: 여비 정산 신청서
    ; 2매: 붙임 1. 여비 산출내역 상세 (산출내역표 + 경로지도 + 공식 유가통계표)
    ; 3매: 증빙서류 첨부 (영수증 부착란)
    ; --------------------------------------------------------------------------
    destShort := ST_Destination
    destPrintHtml := ST_Destination

    if (nights > 0)
    {
        if (isNoCap)
            lodgingCapShow := "실비 전액"
        else if (ST_SharedStayCheck && sharedStayPeople >= 2 && sharedCapRate > 0)
        {
            sharedPrintCap := sharedCapRate * nights * sharedStayPeople
            sharedPrintNightsText := (nights > 1 ? " × " . nights . "박" : "")
            lodgingCapShow := SSOK_Travel_Comma(sharedPrintCap) . "원<br><span style=""font-size:7pt;"">(1박 " . SSOK_Travel_Comma(sharedCapRate) . "원 × " . sharedStayPeople . "명" . sharedPrintNightsText . ")</span>"
        }
        else
            lodgingCapShow := (lodgingCapTotal > 0 ? SSOK_Travel_Comma(lodgingCapTotal) . "원" : "0원")
    }
    else
        lodgingCapShow := "-"
    lodgingActShow := (lodgingActual > 0 ? SSOK_Travel_Comma(lodgingActual) . "원" : "0원")

    mealCapShow := (mealCapTotal > 0 ? SSOK_Travel_Comma(mealCapTotal) . "원" : "0원")
    mealActShow := (mealTotal > 0 ? SSOK_Travel_Comma(mealTotal) . "원" : "0원")

    ; 운임 행 생성 (도착지 폭 24%, 금액 폭 15%로 최적화하여 학교명 잘림 및 우측 짤림 방지)
    fareRowsHtml := ""
    if (ST_TransType1) ; 자가용
    {
        ; 인쇄에서는 가는편/오는편 유류비를 실제 각 편 거리로 별도 계산한다.
        ; 합계와 10원 절사 기준을 기존 계산과 동일하게 유지하기 위해 오는편에 잔액을 배분한다.
        outboundFare := SSOK_Travel_Floor10((ST_GoDistance * price) / eff)
        returnFare := SSOK_Travel_Floor10((ST_BackDistance * price) / eff)
        tName := "자가용(" . fuelNameOnly . ")"

        goTarget := ST_Destination
        if (ST_GoViaCheck && hasVia)
            goTarget := ST_Stopover . " → " . ST_Destination
        backTarget := ST_Departure
        if (ST_BackViaCheck && hasVia)
            backTarget := ST_Stopover . " → " . ST_Departure

        goDestPrintHtml := ST_Destination
        if (ST_GoViaCheck && hasVia)
            goDestPrintHtml .= "<br><span style=""font-size:7pt;color:#666;"">경유: " . ST_Stopover . "</span>"

        backDestPrintHtml := ST_Departure
        if (ST_BackViaCheck && hasVia)
            backDestPrintHtml .= "<br><span style=""font-size:7pt;color:#666;"">경유: " . ST_Stopover . "</span>"

        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . sDateStr . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . tName . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Departure . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . goDestPrintHtml . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (outboundFare > 0 ? SSOK_Travel_Comma(outboundFare) . "원" : "0원") . "</td>`n"
        fareRowsHtml .= "    </tr>`n"

        fareRowsHtml .= "    <tr>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . eDateStr . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . tName . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . ST_Destination . "</td>`n"
        fareRowsHtml .= "      <td class=""dashed-b"">" . backDestPrintHtml . "</td>`n"
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
            fareRowsHtml .= "      <td class=""dashed-b"">" . destPrintHtml . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (viaFare > 0 ? SSOK_Travel_Comma(viaFare) . "원" : "0원") . "</td>`n"
            fareRowsHtml .= "    </tr>`n"

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . eDateStr . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . backName . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . destPrintHtml . "</td>`n"
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
            fareRowsHtml .= "      <td class=""dashed-b"">" . destPrintHtml . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">-</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"" style=""text-align: right; padding-right: 8px;"">" . (goFare > 0 ? SSOK_Travel_Comma(goFare) . "원" : "0원") . "</td>`n"
            fareRowsHtml .= "    </tr>`n"

            fareRowsHtml .= "    <tr>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . eDateStr . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . backName . "</td>`n"
            fareRowsHtml .= "      <td class=""dashed-b"">" . destPrintHtml . "</td>`n"
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
        fareRowsHtml .= "      <td class=""dashed-b"">" . destPrintHtml . "</td>`n"
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
        goRouteDetail := SSOK_Travel_ShortPlace(ST_Departure) . (ST_GoViaCheck && hasVia ? " → " . SSOK_Travel_ShortPlace(ST_Stopover) : "") . " → " . SSOK_Travel_ShortPlace(ST_Destination)
        backRouteDetail := SSOK_Travel_ShortPlace(ST_Destination) . (ST_BackViaCheck && hasVia ? " → " . SSOK_Travel_ShortPlace(ST_Stopover) : "") . " → " . SSOK_Travel_ShortPlace(ST_Departure)
        if (price > 0)
        {
            detailGoFuel := SSOK_Travel_Floor10((ST_GoDistance * price) / eff)
            detailBackFuel := SSOK_Travel_Floor10((ST_BackDistance * price) / eff)
            transportDetail := "<b>가는편 유류비</b> " . SSOK_Travel_Comma(detailGoFuel) . "원 (" . SSOK_Travel_FormatDist(ST_GoDistance) . "km × " . SSOK_Travel_Comma(price) . "원/" . effUnit . " ÷ " . eff . " " . effUnit . ") / <b>오는편 유류비</b> " . SSOK_Travel_Comma(detailBackFuel) . "원 (" . SSOK_Travel_FormatDist(ST_BackDistance) . "km × " . SSOK_Travel_Comma(price) . "원/" . effUnit . " ÷ " . eff . " " . effUnit . ")"
        }
        else
            transportDetail := "유류비 : 조회자료 없음"
        if (toll > 0)
            transportDetail .= " + <b>통행료</b> " . SSOK_Travel_Comma(toll) . "원"
        if (parking > 0)
            transportDetail .= " + <b>주차료</b> " . SSOK_Travel_Comma(parking) . "원"
    }
    else if (ST_TransType2)
    {
        if (transportTotal > 0)
        {
            transportDetail := "대중교통 운임 " . SSOK_Travel_Comma(transportTotal) . "원"
            legDetails := ""
            if (goFare > 0)
                legDetails .= (legDetails != "" ? " + " : "") . "<b>가는편</b> " . SSOK_Travel_Comma(goFare) . "원"
            if (hasValidTransitVia && viaFare > 0)
                legDetails .= (legDetails != "" ? " + " : "") . "경유지 " . SSOK_Travel_Comma(viaFare) . "원"
            if (backFare > 0)
                legDetails .= (legDetails != "" ? " + " : "") . "<b>오는편</b> " . SSOK_Travel_Comma(backFare) . "원"
            if (legDetails != "")
                transportDetail .= " (" . legDetails . ")"
        }
        else
            transportDetail := "입력된 대중교통 운임 없음"
    }
    else if (ST_TransType3)
    {
        transportDetail := "관용차량·임차버스·렌트카 등 운임 0원 (일비 50% 적용)"
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
        dailyBasisText .= " (관용차량·임차버스·렌트카 등: 기준 일비 50%)"
    else if (!ST_TravelCategory2 && !ST_TravelCategory3)
        dailyBasisText .= " (기준단가)"
    if (localDistanceKm > 0 && localDistanceKm <= 12.0)
    {
        dailyBasisText := "출발지-도착지간 편도거리 " . SSOK_Travel_FormatDist(localDistanceKm) . "km (12km 이하) → 일비 20,000원만 지급"
        transportDetail := "출발지-도착지간 편도거리 12km 이하 → 교통비 0원 (일비만 20,000원 지급)"
        mealBasisText := "12km 이하 출장 → 식비 0원"
        lodgingBasisText := "12km 이하 출장 → 숙박비 0원"
    }
    mealBasisText := (mealTotal > 0 ? "실제 소요액 및 지급한도 적용 (" . SSOK_Travel_Comma(mealTotal) . "원)" : "해당없음 (0원)")
    if (nights > 0)
    {
        ; 숙박비 산출내용: 짧은 요약 1줄 + 아래 상세 산출내역
        lodgingBasisText := "실제소요액 " . SSOK_Travel_Comma(lodgingRecognizedActual) . "원"
        if (sharedStayAmount > 0)
            lodgingBasisText .= " + 공동숙박 " . SSOK_Travel_Comma(sharedStayAmount) . "원"
        if (familyStayAmount > 0)
            lodgingBasisText .= " + 친지숙박 " . SSOK_Travel_Comma(familyStayAmount) . "원"
        if (ST_SharedStayCheck && sharedStayPeople > 1 && sharedStayAmount > 0)
        {
            if (lodgingActual <= 0)
                lodgingBasisText .= "<br><span style=""color:#666;"">[공동숙박] 실제소요액 0원 → 추가지원금 0원</span>"
            else
                lodgingBasisText .= "<br><span style=""color:#666;"">[공동숙박 산출] 적용상한 = " . SSOK_Travel_Comma(sharedCapRate) . "원 × " . sharedStayNights . "박 × (" . sharedStayPeople . "명-1) = " . SSOK_Travel_Comma(sharedCapBase) . "원; 미지출 인원 = " . sharedStayPeople . "명 - ⌈" . SSOK_Travel_Comma(lodgingActual) . "원 ÷ (" . SSOK_Travel_Comma(sharedCapRate) . "원 × " . sharedStayNights . "박)⌉ = " . sharedNoPayPeople . "명; 추가지원 = " . sharedNoPayPeople . "명 × 20,000원 × " . sharedStayNights . "박 = " . SSOK_Travel_Comma(sharedStayAmount) . "원</span>"
        }
        if (familyStayAmount > 0)
            lodgingBasisText .= "<br><span style=""color:#666;"">[친지숙박 산출] " . familyStayNights . "박 × 20,000원 = " . SSOK_Travel_Comma(familyStayAmount) . "원</span>"
    }
    else
        lodgingBasisText := "당일 출장"

    FormatTime, todayY, %A_Now%, yyyy
    FormatTime, todayM, %A_Now%, M
    FormatTime, todayD, %A_Now%, d

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
    viaLatVal := (hasVia && ST_ViaLat ? ST_ViaLat : 0)
    viaLonVal := (hasVia && ST_ViaLon ? ST_ViaLon : 0)

    encDep := SSOK_Travel_UriEncode(ST_Departure)
    encDest := SSOK_Travel_UriEncode(ST_Destination)
    kakaoMapLink := ""
    if (hasVia && ST_ViaLon && ST_ViaLat)
    {
        encVia := SSOK_Travel_UriEncode(ST_ViaName != "" ? ST_ViaName : ST_Stopover)
        kakaoMapLink := "https://map.kakao.com/link/by/car/" . encDep . "," . depLatVal . "," . depLonVal . "/" . encVia . "," . ST_ViaLat . "," . ST_ViaLon . "/" . encDest . "," . destLatVal . "," . destLonVal
    }
    else
        kakaoMapLink := "https://map.kakao.com/link/by/car/" . encDep . "," . depLatVal . "," . depLonVal . "/" . encDest . "," . destLatVal . "," . destLonVal

    ; 카카오 자동차 길찾기 화면을 Edge/Chrome Headless로 실제 PNG 캡처하여 인쇄용 지도 이미지로 사용
    ; 사용자가 지정한 ssok_travel_20260912 작업.ahk의 캡처 방식(브라우저 실제 화면 캡처)을 사용한다.
    kakaoMapImageFile := ""
    if (ST_TransType1 && kakaoMapLink != "")
    {
        kakaoMapImageFile := A_Temp . "\SSOK_Travel_KakaoMap_" . A_TickCount . ".png"
        if (!SSOK_Travel_CaptureWebPage(kakaoMapLink, kakaoMapImageFile, 1280, 720))
            kakaoMapImageFile := ""
    }

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
    html .= "  .map-box { width: 100%; height: 78mm; border: 1px solid #888; border-radius: 2px; position: relative; top: 0; margin-top: 1mm; margin-bottom: 3mm; overflow: hidden; }`n"
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
    html .= "    .map-box { width: 100% !important; height: 78mm !important; top: 0 !important; margin-top: 1mm !important; margin-bottom: 3mm !important; }`n"
    html .= "    .map-box img { width: 100% !important; height: 90% !important; object-fit: contain !important; object-position: center center !important; transform: translateY(10%) !important; }`n"

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
    if (ST_TravelCategory1)
        travelCategoryText := "일반출장"
    else if (ST_TravelCategory2)
        travelCategoryText := "교육훈련(합숙·기숙사)"
    else
        travelCategoryText := "교육훈련(비합숙)"
    html .= "<div class=""page-box""" . (ST_TransType3 || ST_TransType4 ? " one-page-form" : "") . ">`n"
    html .= "  <div class=""title"" style=""display:flex;justify-content:space-between;align-items:flex-end;"">여비 정산 신청서<span style=""font-size:9pt;font-weight:normal;"">(출장구분: " . travelCategoryText . ")</span></div>`n"
    html .= "  <table class=""main-tbl"">`n"
    html .= "    <colgroup>`n"
    html .= "      <col style=""width: 8%;"">`n"
    html .= "      <col style=""width: 12%;"">`n"
    html .= "      <col style=""width: 14%;"">`n"
    html .= "      <col style=""width: 15%;"">`n"
    html .= "      <col style=""width: 21%;"">`n"
    html .= "      <col style=""width: 13%;"">`n"
    html .= "      <col style=""width: 17%;"">`n"
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
    html .= "      <td colspan=""5"">" . destPrintHtml . "</td>`n"
    html .= "    </tr>`n"
    html .= "    <tr>`n"
    html .= "      <th>숙박비</th>`n"
    html .= "      <th class=""dashed-r"">상한액 또는<br>지급받은 선금</th>`n"
    html .= "      <td class=""solid-r"">" . lodgingCapShow . "</td>`n"
    html .= "      <th class=""dashed-r"">실제<br>소요액</th>`n"
    html .= "      <td class=""solid-r"">" . lodgingActShow . "</td>`n"
    html .= "      <th>초과<br>지출<br>사유</th>`n"
    html .= "      <td>&nbsp;</td>`n"
    html .= "    </tr>`n"
    html .= "    <tr>`n"
    html .= "      <th>식 &nbsp; 비</th>`n"
    html .= "      <th class=""dashed-r"">지급받은 금액</th>`n"
    html .= "      <td class=""solid-r"">" . mealCapShow . "</td>`n"
    html .= "      <th class=""dashed-r"">실제<br>소요액</th>`n"
    html .= "      <td class=""solid-r"">" . mealActShow . "</td>`n"
    html .= "      <th>초과<br>지출<br>사유</th>`n"
    html .= "      <td>&nbsp;</td>`n"
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
    detailTblHtml := "  <table class=""detail-tbl"">`n"
    detailTblHtml .= "    <colgroup><col style=""width:16%""><col style=""width:64%""><col style=""width:20%""></colgroup>`n"
    detailTblHtml .= "    <tr><th>구 &nbsp; 분</th><th>산 &nbsp; 출 &nbsp; 내 &nbsp; 용</th><th>금 &nbsp; 액</th></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc;"">교통비</th><td>" . transportDetail . "</td><td class=""right"" style=""font-weight:bold;"">" . SSOK_Travel_Comma(transportTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc;"">일 &nbsp; 비</th><td>" . dailyBasisText . "</td><td class=""right"" style=""font-weight:bold;"">" . SSOK_Travel_Comma(dailyTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc;"">식 &nbsp; 비</th><td>" . mealBasisText . "</td><td class=""right"" style=""font-weight:bold;"">" . SSOK_Travel_Comma(mealTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr><th style=""background:#f8fafc; vertical-align:top;"">숙박비</th><td style=""line-height:1.6; word-break:normal; overflow-wrap:anywhere;"">" . lodgingBasisText . "</td><td class=""right"" style=""font-weight:bold; vertical-align:top; white-space:nowrap;"">" . SSOK_Travel_Comma(lodgingTotal) . "원</td></tr>`n"
    detailTblHtml .= "    <tr style=""background:#f0f4fb;""><th colspan=""2"" style=""text-align:center;font-size:9pt;font-weight:bold;"">합 &nbsp; 계</th><td class=""right"" style=""font-weight:bold;color:#0b4a8b;font-size:9.5pt;"">" . SSOK_Travel_Comma(grandTotal) . "원</td></tr>`n"
    detailTblHtml .= "  </table>`n"

    if (ST_TransType3 || ST_TransType4)
    {
        ; 관용차량 및 기타 차량: 증빙서류 부착 불필요, 산출내역을 신청서 하단에 배치하여 1매 출력
        html .= "    <div class=""sign-area"" style=""margin-top: 3mm; line-height: 1.65;"">`n"
        html .= "      「공무원여비규정」 제16조 제1항·제2항에 의하여 위와 같이 여비의 정산을 신청합니다.<br>`n"
        html .= "      첨 &nbsp; 부 : 여비 산출내역 1부 (하단 기재)<br>`n"
        html .= "      <div style=""letter-spacing: 1px;"">" . todayY . "년 " . todayM . "월 " . todayD . "일</div>`n"
        html .= "      <div style=""text-align: right; padding-right: 25px; margin-top: 2mm;"">`n"
        html .= "        신 &nbsp; 청 &nbsp; 인 &nbsp;&nbsp;&nbsp;&nbsp; 성 &nbsp; 명 &nbsp;&nbsp;&nbsp;&nbsp; <b style=""font-size: 11pt;"">" . ST_Name . "</b> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; (인)`n"
        html .= "      </div>`n"
        html .= "    </div>`n"

        html .= "    <div class=""foot-area"" style=""margin-top: 22mm; margin-bottom: 2mm; line-height: 1.55; font-size: 8.5pt;"">`n"
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
        if (ST_TransType1)
        {
            carReasonPrint := RegExReplace(Trim(ST_CarReason), "^\s*\d+\.\s*", "")
            html .= "    <div style=""text-align:left; margin-top:3mm; line-height:2.15; padding-left:12px;"">"
            html .= "□&nbsp; 유류비 신청사유: " . carReasonPrint . "<br>"
            if (ST_SharedStayCheck && sharedStayPeople >= 2)
                html .= "□&nbsp; 동행자: 공동숙박 " . sharedStayPeople . "명 &nbsp;&nbsp;&nbsp; ____________ &nbsp;&nbsp;&nbsp; ______________<br>"
            else
                html .= "□&nbsp; 동행자: ______________________________________________<br>"
            html .= "□&nbsp; 첨부: 신용카드 매출전표 등 1부"
            html .= "    </div><br>`n"
        }
        else
        {
            if (ST_SharedStayCheck && sharedStayPeople >= 2)
                html .= "    □&nbsp; 동행자: 공동숙박 " . sharedStayPeople . "명 &nbsp;&nbsp;&nbsp; ____________ &nbsp;&nbsp;&nbsp; ______________<br>`n"
            html .= "    첨 &nbsp; 부 : 신용카드 매출전표 등 1부<br><br>`n"
        }
        html .= "    <div style=""letter-spacing: 1px;"">신청일자: " . todayY . "년 " . todayM . "월 " . todayD . "일</div><br>`n"
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
    html .= "  <div class=""status-box"" style=""display:flex;justify-content:space-between;align-items:center;height:8mm;padding:1mm 3mm;font-size:8pt;line-height:1.2;overflow:hidden;"">`n"
    goPrintRoute := SSOK_Travel_ShortPlace(ST_Departure)
    if (ST_GoViaCheck && Trim(ST_Stopover) != "")
        goPrintRoute .= " → " . SSOK_Travel_ShortPlace(ST_Stopover)
    goPrintRoute .= " → " . SSOK_Travel_ShortPlace(ST_Destination)

    backPrintRoute := SSOK_Travel_ShortPlace(ST_Destination)
    if (ST_BackViaCheck && Trim(ST_Stopover) != "")
        backPrintRoute .= " → " . SSOK_Travel_ShortPlace(ST_Stopover)
    backPrintRoute .= " → " . SSOK_Travel_ShortPlace(ST_Departure)
    goPrintDistance := SSOK_Travel_FormatDist(ST_GoDistance)
    backPrintDistance := SSOK_Travel_FormatDist(ST_BackDistance)
    html .= "    <div>• <b>출장경로:</b> 가는편 " . goPrintRoute . " (" . goPrintDistance . "km) / 오는편 " . backPrintRoute . " (" . backPrintDistance . "km)</div>`n"
    html .= "    <div class=""no-print"" style=""font-size:8pt;""><a href=""" . kakaoMapLink . """ target=""_blank"" style=""color:#392020;font-weight:bold;text-decoration:none;"">[카카오 자동차 길찾기]</a></div>`n"
    html .= "  </div>`n"
    if (kakaoMapImageFile != "")
    {
        mapImageUrl := SSOK_Travel_FileUrl(kakaoMapImageFile)
        html .= "  <div id=""route-map"" class=""map-box"" style=""padding:0;overflow:hidden;background:#fff;""><img src=""" . mapImageUrl . """ style=""display:block;width:100%;height:90%;object-fit:contain;object-position:center center;transform:translateY(10%);"" alt=""카카오맵 출장경로""></div>`n"
    }
    else
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
        valHyb := valGas ; 일반 하이브리드(휘발유)는 보통휘발유 단가 적용

        isGas := (InStr(ST_FuelType, "휘발유") && !InStr(ST_FuelType, "하이브리드"))
        isDie := (InStr(ST_FuelType, "경유") && !InStr(ST_FuelType, "하이브리드"))
        isLpg := InStr(ST_FuelType, "LPG")
        isHybGas := InStr(ST_FuelType, "일반 하이브리드(휘발유")
        isHybDie := InStr(ST_FuelType, "일반 하이브리드(경유")
        isPhevGas := InStr(ST_FuelType, "플러그인 하이브리드(휘발유")
        isPhevElec := InStr(ST_FuelType, "플러그인 하이브리드(전기")

        ; 유가 기준표는 화면의 임의 수정값을 사용하지 않는다.
        ; 반드시 오피넷 조회값을 그대로 표시하여 기준표와 오피넷 가격을 일치시킨다.

        rowGas := (isGas ? " class=""active-fuel""" : "")
        rowDie := (isDie ? " class=""active-fuel""" : "")
        rowLpg := (isLpg ? " class=""active-fuel""" : "")
        rowHybGas := (isHybGas ? " class=""active-fuel""" : "")
        rowHybDie := (isHybDie ? " class=""active-fuel""" : "")
        rowPhevGas := (isPhevGas ? " class=""active-fuel""" : "")
        rowPhevElec := (isPhevElec ? " class=""active-fuel""" : "")

        noteGas := (isGas ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        noteDie := (isDie ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        noteLpg := (isLpg ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        noteHybGas := (isHybGas ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        noteHybDie := (isHybDie ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        notePhevGas := (isPhevGas ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")
        notePhevElec := (isPhevElec ? "<b style=""color:#0b4a8b;"">신청유종 (적용)</b>" : "-")

        priceGasStr := (valGas > 0 ? SSOK_Travel_FormatFuelPrice(valGas) . " 원/L" : "조회자료 없음")
        priceDieStr := (valDie > 0 ? SSOK_Travel_FormatFuelPrice(valDie) . " 원/L" : "조회자료 없음")
        priceLpgStr := (valLpg > 0 ? SSOK_Travel_FormatFuelPrice(valLpg) . " 원/L" : "조회자료 없음")
        priceHybGasStr := (valGas > 0 ? SSOK_Travel_FormatFuelPrice(valGas) . " 원/L" : "조회자료 없음")
        priceHybDieStr := (valDie > 0 ? SSOK_Travel_FormatFuelPrice(valDie) . " 원/L" : "조회자료 없음")
        pricePhevGasStr := (valGas > 0 ? SSOK_Travel_FormatFuelPrice(valGas) . " 원/L" : "조회자료 없음")
        pricePhevElecStr := (isPhevElec ? (SSOK_Travel_Number(ST_FuelPrice) > 0 ? SSOK_Travel_FormatChargeRate(ST_FuelPrice) . " 원/kWh" : "충전단가 입력") : "-" )

        if (isGas)
            priceGasStr := "<b>" . priceGasStr . "</b>"
        if (isDie)
            priceDieStr := "<b>" . priceDieStr . "</b>"
        if (isLpg)
            priceLpgStr := "<b>" . priceLpgStr . "</b>"
        if (isHybGas)
            priceHybGasStr := "<b>" . priceHybGasStr . "</b>"
        if (isHybDie)
            priceHybDieStr := "<b>" . priceHybDieStr . "</b>"
        if (isPhevGas)
            pricePhevGasStr := "<b>" . pricePhevGasStr . "</b>"
        if (isPhevElec)
            pricePhevElecStr := "<b>" . pricePhevElecStr . "</b>"

        html .= "    <table class=""cert-tbl"">"
        html .= "      <colgroup><col style=""width:28%""><col style=""width:24%""><col style=""width:26%""><col style=""width:22%""></colgroup>"
        html .= "      <tr><th>유 &nbsp; 종</th><th>공인 기준연비</th><th>공시 판매가격 (단가)</th><th>비 &nbsp; 고</th></tr>"
        html .= "      <tr" . rowGas . "><td>보통휘발유</td><td>11.97 km/L</td><td class=""right"">" . priceGasStr . "</td><td>" . noteGas . "</td></tr>"
        html .= "      <tr" . rowDie . "><td>자동차용경유</td><td>12.52 km/L</td><td class=""right"">" . priceDieStr . "</td><td>" . noteDie . "</td></tr>"
        html .= "      <tr" . rowLpg . "><td>자동차용부탄(LPG)</td><td>8.83 km/L</td><td class=""right"">" . priceLpgStr . "</td><td>" . noteLpg . "</td></tr>"
        html .= "      <tr" . rowHybGas . "><td>일반 하이브리드(휘발유)</td><td>15.37 km/L</td><td class=""right"">" . priceHybGasStr . "</td><td>" . noteHybGas . "</td></tr>"
        html .= "      <tr" . rowHybDie . "><td>일반 하이브리드(경유)</td><td>15.37 km/L</td><td class=""right"">" . priceHybDieStr . "</td><td>" . noteHybDie . "</td></tr>"
        html .= "      <tr" . rowPhevGas . "><td>플러그인 하이브리드(휘발유)</td><td>10.61 km/L</td><td class=""right"">" . pricePhevGasStr . "</td><td>" . notePhevGas . "</td></tr>"
        html .= "      <tr" . rowPhevElec . "><td>플러그인 하이브리드(전기)</td><td>2.84 km/kWh</td><td class=""right"">" . pricePhevElecStr . "</td><td>" . notePhevElec . "</td></tr>"
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
    html .= "    <span style=""font-size:9.5pt;color:#888;"">해당되는 증빙서류를 이곳에 부착하세요. (신용카드 매출전표, 승차권, 숙박비·통행료·주차료 영수증 등)</span>`n"
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
    html .= "    var depName = """ . SSOK_Travel_ShortPlace(ST_Departure) . """;`n"
    html .= "    var destName = """ . SSOK_Travel_ShortPlace(ST_Destination) . """;`n"
    html .= "    var viaName = """ . (hasVia ? SSOK_Travel_ShortPlace(ST_Stopover) : "") . """;`n"
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
    html .= "    document.getElementById('route-map').innerHTML = '<div style=""display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;background:#f4f7fb;color:#333;font-size:9.5pt;border:1px dashed #90a4ae;padding:3mm;text-align:center;""><b>🗺️ 출장 경로 안내 (카카오맵 연동)</b><div style=""margin-top:2mm;font-size:9pt;color:#1a365d;""><b>' + depName + '</b>' + (viaName ? ' → <b>' + viaName + '</b>' : '') + ' → <b>' + destName + '</b></div><div style=""margin-top:1.5mm;font-size:8pt;color:#666;""></div><div style=""margin-top:2mm;font-size:7.5pt;color:#888;"">※ 카카오 디벨로퍼스(developers.kakao.com)에서 [카카오맵] 활성화(ON) 설정 시 정식 지도가 즉시 표시됩니다.</div></div>';`n"
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

    ; HTML을 임시파일로 저장한 뒤 기본 브라우저에서 엽니다.
    ; 인쇄가 안 되는 PC를 위해 파일 생성/브라우저 실행 여부를 확인하고
    ; 실패하면 Windows의 기본 HTML 연결(ShellExecute)로 다시 엽니다.
    SSOK_Travel_LastHtml := html
    tmpFile := A_Temp . "\ssok_travel_print_" . A_TickCount . ".html"
    FileDelete, %tmpFile%
    FileAppend, %html%, %tmpFile%, UTF-8

    if (!FileExist(tmpFile))
    {
        MsgBox, 48, 인쇄 오류, 여비정산서 인쇄용 HTML 파일을 만들지 못했습니다.`n`n임시폴더: %A_Temp%
        return
    }

    Run, %tmpFile%,, UseErrorLevel
    if (ErrorLevel)
    {
        ; 기본 연결 실행이 막힌 경우 ShellExecute로 재시도
        DllCall("Shell32\ShellExecute", "Ptr", 0, "Str", "open", "Str", tmpFile, "Ptr", 0, "Ptr", 0, "Int", 1)
        Sleep, 800
        if (!WinExist("여비 정산 신청서"))
        {
            ; 마지막 fallback: explorer.exe로 HTML 열기
            Run, % "explorer.exe """ . tmpFile . """",, UseErrorLevel
        }
    }
    return
SSOK_Travel_DecodeSecret(key, encoded)
{
    ; 단순 문자열 난독화: 실제 보안 저장소가 아니라 평문 검색 노출을 줄이기 위한 용도.
    VarSetCapacity(bin, 0)
    DllCall("Crypt32\\CryptStringToBinary", "Str", encoded, "UInt", 1, "UInt", 0
        , "Ptr", 0, "UIntP", size, "Ptr", 0, "Ptr", 0)
    VarSetCapacity(bin, size, 0)
    DllCall("Crypt32\\CryptStringToBinary", "Str", encoded, "UInt", 1, "UInt", 0
        , "Ptr", &bin, "UIntP", size, "Ptr", 0, "Ptr", 0)
    out := ""
    Loop, %size%
        out .= Chr(NumGet(bin, A_Index - 1, "UChar") ^ Asc(SubStr(key, Mod(A_Index - 1, StrLen(key)) + 1, 1)))
    return out
}

SSOK_Travel_FormatChargeRate(v)
{
    s := RegExReplace(Trim(v . ""), ",", "")
    if (s = "")
        return ""
    if (!RegExMatch(s, "^-?[0-9]+(?:\.[0-9]+)?$"))
        return ""
    ; 영수증에서 계산한 단가는 계산 정밀도를 보존하되 화면은 최대 소수 넷째 자리까지 표시한다.
    return Round(s + 0, 4)
}

SSOK_Travel_FormatFuelPrice(v)
{
    ; 오피넷 원문 단가의 소수 둘째 자리까지 그대로 보존한다.
    ; 숫자로 다시 반올림/변환하지 않아 1859.33 -> 1859.30 같은 변경이 생기지 않도록 한다.
    s := RegExReplace(Trim(v . ""), ",", "")
    if (s = "")
        return ""
    if (!RegExMatch(s, "^-?[0-9]+(?:\.[0-9]+)?$"))
        return ""
    if (!InStr(s, "."))
        return s . ".00"
    parts := StrSplit(s, ".")
    frac := SubStr(parts[2] . "00", 1, 2)
    return parts[1] . "." . frac
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
        return "기타"
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

SSOK_Travel_FileUrl(path)
{
    p := StrReplace(path, "\", "/")
    return "file:///" . p
}
; ------------------------------------------------------------------------------
; 카카오맵 실제 화면 PNG 캡처 (ssok_travel_20260912 작업 방식)
; ------------------------------------------------------------------------------
SSOK_Travel_CaptureWebPage(url, outFile, width := 1280, height := 720)
{
    edge := SSOK_Travel_GetEdgePath()
    if (edge = "" || url = "" || outFile = "")
        return false

    FileDelete, %outFile%
    profileDir := A_Temp . "\SSOKTravelEdge_" . A_TickCount
    FileCreateDir, %profileDir%

    cmd := """" . edge . """ --headless=new --disable-gpu --hide-scrollbars --no-first-run --no-default-browser-check --disable-background-networking --disable-component-update --disable-sync --disable-default-apps --disable-extensions --run-all-compositor-stages-before-draw --user-data-dir=""" . profileDir . """ --window-size=" . width . "," . height . " --virtual-time-budget=6000 --screenshot=""" . outFile . """ """ . url . """"
    try
        RunWait, %cmd%,, Hide
    catch
        return false

    FileGetSize, sz, %outFile%
    return (sz > 5000)
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
    ; 실제 계산값을 1자리까지 반올림하여 표시한다. 정수값이면 .0이 붙고,
    ; 140.34 → 140.3 / 140.36 → 140.4처럼 실제 소수값을 그대로 반영한다.
    num := Round(km + 0.0, 1)
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

    ; 1차: 장소 검색 API
    places := SSOK_Travel_SearchPlacesApi(query)
    if (places.Length() > 0)
    {
        lon := places[1].x
        lat := places[1].y
        resolvedName := places[1].name
        return true
    }

    ; 주소 검색 실패
    return false
}

SSOK_Travel_GetDistanceAndRoute(lon1, lat1, lon2, lat2, ByRef coordsJson, lonVia := 0, latVia := 0)
{
    if (!lon1 || !lat1 || !lon2 || !lat2)
        return 0
    try
    {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(1000, 1000, 1500, 2000)
        if (lonVia && latVia)
            url := "https://router.project-osrm.org/route/v1/driving/" . lon1 . "," . lat1 . ";" . lonVia . "," . latVia . ";" . lon2 . "," . lat2 . "?overview=full&geometries=geojson"
        else
            url := "https://router.project-osrm.org/route/v1/driving/" . lon1 . "," . lat1 . ";" . lon2 . "," . lat2 . "?overview=full&geometries=geojson"

        whr.Open("GET", url, false)
        whr.SetRequestHeader("User-Agent", "Mozilla/5.0")
        whr.Send()
        res := whr.ResponseText

        km := 0
        pos := 1
        maxDist := 0
        while (pos := RegExMatch(res, """distance"":([0-9\.]+)", mDist, pos))
        {
            curDist := mDist1 + 0.0
            if (curDist > maxDist)
                maxDist := curDist
            pos += StrLen(mDist)
        }
        if (maxDist > 0)
            km := Format("{:0.1f}", maxDist / 1000.0)

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
    else if (InStr(fuelType, "일반 하이브리드(경유"))
        fuelKey := "diesel"
    else if (InStr(fuelType, "하이브리드") && !InStr(fuelType, "경유"))
        fuelKey := "gasoline"
    else if (InStr(fuelType, "전기"))
        return 0
    else if (InStr(fuelType, "수소"))
        return 9900

    ; 오피넷 가격은 캐시값을 절대로 우선 사용하지 않는다.
    ; 공식 오피넷 최근가격 API를 1순위로 조회하고, 해당 날짜가 API 범위를 벗어나면
    ; 오피넷 원문 페이지를 조회한다. 둘 다 실패한 경우에는 예전 캐시값을 사용하지 않는다.
    ; 이렇게 해야 여비신청서의 유가가 오래된 캐시값으로 오피넷과 달라지는 일이 없다.
    apiVal := SSOK_Travel_FetchOpinetRecentApi(fuelKey, dateStr)
    if (apiVal > 0)
    {
        ; API가 준 단가 문자열을 그대로 저장/반환한다.
        return apiVal
    }

    fetchedVal := SSOK_Travel_FetchOpinetDirect(fuelKey, dateStr)
    if (fetchedVal > 0)
    {
        return fetchedVal
    }

    ; 오피넷에 해당 날짜 자료가 없으면 임의의 유가를 넣지 않는다.
    ; 0 반환 = 조회자료 없음
    return 0
}

SSOK_Travel_FetchOpinetRecentApi(fuelKey, dateStr)
{
    ; 오피넷 공식 최근가격 API.
    ; 최근 7일 범위에 해당 날짜가 있으면 해당 날짜의 정확한 PRICE(소수 둘째 자리)를 사용한다.
    ; API가 실패하거나 날짜가 범위 밖이면 기존 페이지 조회로 자동 fallback한다.
    prodCd := ""
    if (fuelKey = "gasoline")
        prodCd := "B027"
    else if (fuelKey = "diesel")
        prodCd := "D047"
    else if (fuelKey = "lpg")
        prodCd := "K015"
    else
        return 0

    try
    {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(1200, 1200, 1500, 2000)
        ; 오피넷 공개 최근가격 조회에 사용되는 API 코드
        opinetCode := SSOK_Travel_DecodeSecret("S5", "FQRqBGICYwJhBA==")
        url := "https://www.opinet.co.kr/api/avgRecentPrice.do?code=" . opinetCode . "&out=json&prodcd=" . prodCd
        whr.Open("GET", url, false)
        whr.SetRequestHeader("User-Agent", "Mozilla/5.0")
        whr.Send()
        res := whr.ResponseText

        ; JSON의 공백/줄바꿈 여부와 관계없이 해당 날짜·유종의 PRICE를 정확히 추출한다.
        pattern := """DATE""\s*:\s*""" . dateStr . """\s*,\s*""PRODCD""\s*:\s*""" . prodCd . """\s*,\s*""PRICE""\s*:\s*([0-9]+(?:\.[0-9]+)?)"
        if (RegExMatch(res, pattern, m))
        {
            exactPrice := "" . m1
            if ((exactPrice + 0) > 300)
                return exactPrice . ""
        }
    }
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
                lpgValStr := RegExReplace(m1, ",", "")
                lpgVal := lpgValStr + 0.0
                if (lpgVal > 300)
                {
                    if (SSOK_Ini != "")
                                    return lpgValStr . ""
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
            gasValStr := RegExReplace(m1, ",", "")
            dieValStr := RegExReplace(m2, ",", "")
            gasVal := gasValStr + 0.0
            dieVal := dieValStr + 0.0

            if (gasVal > 500 && SSOK_Ini != "")
                    if (dieVal > 500 && SSOK_Ini != "")
        
            if (fuelKey = "diesel" && dieVal > 500)
                return dieValStr
            if (fuelKey = "gasoline" && gasVal > 500)
                return gasValStr
        }
    }
    return 0
}
