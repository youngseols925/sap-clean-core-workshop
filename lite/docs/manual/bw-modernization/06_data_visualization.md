# Lesson 6 · 데이터 시각화 — SAP Analytics Cloud 대시보드

> ⏱ 15분 | **직접 실습**

## 학습 목표

SAP Analytics Cloud(SAC)에서 실적 + 예측 현금 흐름 데이터를  
**대시보드 Story**로 시각화합니다.

---

## 최종 결과물 (Story 구성)

```
┌─────────────────────────────────────────────────┐
│  Cash Flow Forecast Dashboard                   │
├──────────────┬──────────────────────────────────┤
│  [KPI]        │  [KPI]                          │
│  Cash Flow    │  Cash Flow                      │
│  Actual       │  Forecast                       │
│  vs 전년比    │  (예측치)                       │
├──────────────┴──────────────────────────────────┤
│  [Bar Chart]                                    │
│  회사 코드별 실적 현금 흐름                      │
├─────────────────────────────────────────────────┤
│  [Time Series Chart]                            │
│  실적 + 예측 + 상한/하한 트렌드                 │
└─────────────────────────────────────────────────┘
```

> 📝 수강생마다 데이터값은 다를 수 있습니다.

---

## Part 1 · SAP Analytics Cloud 접속

### Step 1 · SAC 로그인

**방법 1**: SAP Datasphere 접속 상태 → 우상단 **App Switcher** → **SAP Analytics Cloud**

**방법 2**: 브라우저에서 SAC URL 직접 접속
- Username: `AC317935U01`
- Password: (강사 제공)

알림 수신 요청 → **Decline**

![SAP Analytics Cloud 메인 화면](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image01a.png)

---

## Part 2 · Story 생성

### Step 2 · 템플릿에서 Story 시작

![Stories → CashFlowForecast Template 선택](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image02.png)

좌측 **Stories** → **CashFlowForecast Template** 선택

- 좌측 사이드 패널 **X** 닫기
- 우측 **Layouts** 패널 닫기

### Step 3 · 데이터 소스 연결

![Tools 메뉴 → Add New Data](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image05.png)

상단 **Tools** 메뉴 → **Add New Data**

> 화면이 좁으면 **More** 메뉴에서 찾기

1. **Data from an existing dataset or model** 선택
2. **SAP Datasphere connections** 스크롤 → **SAPSRC** 선택
3. 내 스페이스 **AC317935U01** 선택
4. **Combined Forecast Model** (AM) 선택 → **OK**

### Step 4 · 페이지 필터 설정 (현재 연도 + 1년)

![Filters 탭 — Add New Filter → Year](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image06.png)

**View** 메뉴 → **Left Side Panel** 열기 → **Filters** 탭

1. **Add New Filter** → **Current** → **Year**
2. `POSTINGDATE` 필터 확장
3. **Look Ahead years**: `1` 입력
4. **Allow for forecast values** 체크
5. **Back** 클릭

View 메뉴 → Left Side Panel 닫기

---

## Part 3 · KPI 위젯 추가

### Step 5 · Cash Flow Actual KPI 추가

![왼쪽 '+' Numeric Point Chart 플레이스홀더 클릭](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image07.png)

템플릿 좌측 **'+ Create a Numeric Point Chart'** 플레이스홀더 클릭

우측 **Builder** 탭에서:
- Primary Value: **CASHFLOW_ACTUAL** 추가

**동적 필터 추가:**
1. **+ Add Filters** 클릭
2. **POSTINGDATE (Range)** 선택
3. 기본값 유지 → **SET** 클릭 (현재 연도 자동 필터)

**전년비 Variance 추가:**
1. **Chart Add-Ons** → **Variance** 확장
2. COMPARE (A): Dynamic, **Add Version/Time** → `POSTINGDATE` → **Current Time Interval**
3. TO (B): Dynamic, `POSTINGDATE`, **Previous Time Interval** → **Done**

![Variance 설정 완료 화면](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image08.png)

**Styling 설정:**
- **Styling** 탭 → Number Format:
  - Scale: **Million**
  - Decimal Places: **0**
  - Data Labels: **체크 해제**
- Font → Text Selection: **Primary Variance Title** → Size: **14**

**위젯 타이틀**: `Cash Flow Actual` 로 변경

More Actions (…) → More Options → Show/Hide → **Primary Value Labels** 체크 해제

---

### Step 6 · Cash Flow Forecast KPI 추가 (복제)

![Cash Flow Actual KPI → More Actions → Duplicate](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image09.png)

1. Cash Flow Actual KPI 선택 → More Actions (…) → **Copy → Duplicate**
2. Builder 탭 → Primary Value를 **CASHFLOW_FORECAST** 로 교체
3. 타이틀: `Cash Flow Forecast` 로 변경

---

## Part 4 · Bar Chart 추가

### Step 7 · 회사 코드별 실적 Bar Chart

![Bar Chart 플레이스홀더 클릭](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image10.png)

**'+ Create Bar Chart'** 플레이스홀더 클릭

**Builder** 탭 설정:
- Measures: **CASHFLOW_ACTUAL**
- Dimensions: **COMPANYCODE**

**[선택사항]** COMPANYCODE 필터 추가 → Member: **1710, 1720, 1730** 선택  
(1800은 예측 모델 미생성)

**Styling** 탭:
- Scale: **Million**
- Decimal Places: **0**

타이틀: `Cash Flow Actual per Company Code` 로 변경

More Actions → **Sort** → CASHFLOW_ACTUAL → **Highest to Lowest**

![정렬 적용된 Bar Chart](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image11.png)

---

## Part 5 · Time Series Chart 추가

### Step 8 · 실적 + 예측 트렌드 차트

![Time Series Chart 플레이스홀더 클릭](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image12.png)

**'+ Create a Time Series'** 플레이스홀더 클릭

**Builder** 탭 설정:

| 항목 | 값 |
|------|-----|
| Measures | CASHFLOW_ACTUAL |
| | CASHFLOW_FORECAST |
| | CASHFLOW_FORECAST_UPPER |
| | CASHFLOW_FORECAST_LOWER |
| Time Dimension | POSTINGDATE |

COMPANYCODE 필터: **1710, 1720, 1730** (1800 제외)

**Styling** 탭:
- Scale: **Million**
- Decimal Places: **0**
- Legend Placement: **Above Chart**

우측 패널 닫기 (View → Right Side Panel)

타이틀: `Cash Flow Forecast Analysis` 로 변경

![완성된 Time Series Chart — 실선(실적) + 점선(예측)](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image13.png)

시계열 범위 변경 (예: 1 month) → 차트와 슬라이더 업데이트 확인

---

## Part 6 · Story 저장

### Step 9 · 저장

**File** 메뉴 → **Save**

- **My Files** 선택
- 이름: `Cash Flow Forecast`
- **Save** 클릭

![완성된 전체 Story 화면](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_7_image13b.png)

---

## 최종 결과물 체크리스트

- [ ] KPI 위젯 2개: Cash Flow Actual (전년비 포함) + Cash Flow Forecast
- [ ] Bar Chart: 회사 코드별 실적 현금 흐름
- [ ] Time Series Chart: 4개 Measure (실적 + 예측 3종)
- [ ] 페이지 필터: 현재 연도 + 1년
- [ ] Story 이름: Cash Flow Forecast

---

## 핵심 포인트 요약

| 항목 | 설명 |
|------|------|
| 데이터 소스 | AM_Combined_Forecast_Model (Datasphere 연결) |
| KPI 차트 | Numeric Point + Variance (전년비) |
| Bar Chart | 회사 코드별 실적 비교 |
| Time Series | 실적 + 예측(상한/하한 포함) 시계열 트렌드 |
| 저장 위치 | My Files / Cash Flow Forecast |

---

## 🎉 워크샵 완료!

**SAP BW → SAP Business Data Cloud 현대화 전체 흐름을 완성했습니다.**

```
SAP BW (과거 실적 ADSO)
    → Datasphere BW Ingestion Space
    → Data Product (Catalog 등록)
    → SAP Databricks (ML 예측 모델)
    → cashflow_forecast Data Product
    → Datasphere Fact View (실적 + 예측 UNION)
    → Analytic Model
    → SAC Dashboard (시각화)
```

---

*[← 05 · 데이터 모델링](./05_data_modeling.md) | [목차로 →](./README.md)*