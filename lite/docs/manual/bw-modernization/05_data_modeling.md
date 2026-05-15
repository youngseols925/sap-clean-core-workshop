# Lesson 5 · 데이터 모델링 — Fact View + Analytic Model

> ⏱ 15분 | **직접 실습**

## 학습 목표

SAP BW 실적 데이터와 Databricks 예측 데이터를 **Fact View**로 통합(UNION)하고,  
**Analytic Model**을 생성하여 SAC에서 분석 가능한 상태로 만듭니다.

---

## 최종 결과물 구조

```
[BW 실적 데이터]              [Databricks 예측 데이터]
DDS_... (ADSO 복제본)         cashflow_forecast
     │                               │
     ▼ Rename (컬럼명 통일)          ▼ Convert (날짜 형식 변환)
  Projection 1                 Calculated Columns 1
     │                               │
     └──────────────┬────────────────┘
                    ▼
                  UNION
                    │
                    ▼ Add Dates (현재 날짜 보완)
             Calculated Columns 2
                    │
                    ▼ Exclude 불필요 컬럼
                 Projection 2
                    │
                    ▼ Output Node
           [FV_Combined_CashFlow]  ← Fact View
                    │
                    ▼
           [AM_Combined_Forecast_Model]  ← Analytic Model
```

---

## 사전 조건 확인

- [ ] BW Ingestion Space의 `Actual Cashflow - ZCASHACT (ADSO)` 테이블이 내 스페이스에 공유됨
- [ ] `cashflow_forecast` Data Product가 내 스페이스에 설치됨
- [ ] SAP Datasphere 로그인 상태

---

## Part 1 · Fact View 생성

### Step 1 · 새 Graphical View 생성

![Data Builder → New Graphical View 타일](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image02.png)

**Data Builder** → 내 스페이스 선택 → **New Graphical View** 클릭

### Step 2 · BW 실적 데이터 소스 추가

![Repository 탭 검색 — ZCASHACT](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image03.png)

우측 **Repository** 탭에서 검색:
```
Actual Cashflow - ZCASHACT
```
→ 캔버스로 **드래그 앤 드롭**

> 테이블 노드명이 `DDS_...` 형태로 표시됩니다 (자동 생성 기술명)

---

### [선택사항] Step 3 · 컬럼명 통일 (Rename)

두 소스의 컬럼명이 달라 UNION 매핑을 위해 사전 통일합니다.

`DDS_...` 노드 클릭 → **Rename/Exclude Columns** 선택

변경 목록:

| 원래 이름 | 변경 후 (기술명 + 비즈니스명) |
|-----------|-------------------------------|
| Posting Date | **POSTINGDATE** |
| Company Code | **COMPANYCODE** |
| Cash Flow | **CASHFLOW_ACTUAL** |
| 1st Currency Key (COMPCODECURRENCY) | **COMPANYCODECURRENCY** |
| 2nd Currency Key (TRANSACTIONCURRENCY) | **TRANSACTIONCURRENCY** |

![Rename 완료된 Projection 노드 컬럼 목록](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image04.png)

---

### Step 4 · Databricks 예측 데이터 소스 추가

Repository에서 `cashflow_forecast` 검색 → 캔버스로 드래그

---

### Step 5 · 날짜 형식 변환 (문자열 → 날짜)

Databricks의 `POSTINGDATE`는 **문자열(String)** 타입입니다. 날짜로 변환해야 합니다.

`cashflow_forecast` 노드 클릭 → **Calculated Columns** 선택

POSTINGDATE 컬럼의 Edit Expression 클릭:

```sql
-- 기존값 교체
TO_DATE(POSTINGDATE)
```

**Validate** → 데이터 타입이 **Date**로 변경 확인

![TO_DATE 표현식 입력 및 Validate 결과](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image05.png)

---

### Step 6 · UNION으로 두 소스 결합

![Calculated Columns 1 노드를 Projection 1 위에 드롭 → Union 선택](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image06.png)

`Calculated Columns 1` 노드를 `Projection 1` 노드 위로 **드래그 앤 드롭** → **Union** 선택

UNION 노드 설정:
1. `Calculated Columns 1` 소스 선택 → ⚙️ Settings → **Add All Source Columns as UNION Columns**
2. `Projections 1` 소스 선택 → 매핑 확인 (컬럼명 통일했으면 자동 매핑)

---

### Step 7 · 날짜 보완 (Calculated Column)

> BW 소스 데이터는 **2025년 6월**까지만 있습니다.  
> 현재 날짜까지 자동으로 날짜를 앞당기는 계산식을 추가합니다.

UNION 노드 클릭 → **Calculated Columns** 선택

POSTINGDATE Edit Expression:

```sql
TO_DATE(ADD_DAYS(POSTINGDATE, DAYS_BETWEEN('2025-06-24', CURRENT_DATE())))
```

**Validate** 클릭

> ⚠️ 복사-붙여넣기 오류 시: 노트패드에 먼저 붙여넣은 후 다시 복사하세요

---

### Step 8 · 실적 금액 타입 변환

같은 Calculated Columns 노드에서:

`CASHFLOW_ACTUAL` Edit Expression:

```sql
TO_DOUBLE(CASHFLOW_ACTUAL)
```

**Validate** → 타입 변경 확인

---

### Step 9 · 불필요 컬럼 제외 (Projection)

`Calculated Columns 2` 클릭 → **Rename/Exclude** 선택

`id` 컬럼 → More (…) → **Exclude Column**

---

### Step 10 · Fact View 속성 설정

**Output Node (View 1)** 클릭 → Properties 패널:

| 항목 | 값 |
|------|-----|
| Business Name | **Combined Cashflow** |
| Technical Name | **FV_Combined_CashFlow** |
| Semantic Usage | **Fact** |
| Expose for Consumption | **ON** |

**Measures 설정** (Attributes에서 변환):
- `CASHFLOW_ACTUAL` → **Change to Measure**
- `CASHFLOW_FORECAST` → **Change to Measure**
- `CASHFLOW_FORECAST_LOWER` → **Change to Measure**
- `CASHFLOW_FORECAST_UPPER` → **Change to Measure**

![Fact View 속성 — Measures 4개 + Attributes 4개](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image07.png)

---

### Step 11 · 시맨틱 타입 지정

**Attributes 편집 모드** (✏️ 아이콘):
- `COMPANYCODECURRENCY` → Semantic Type: **Currency Code**

**Measures 편집 모드** (✏️ 아이콘):
- `CASHFLOW_ACTUAL` → Semantic Type: **Amount with Currency**, Unit: `COMPANYCODECURRENCY`
- 나머지 3개 Measure도 동일하게 설정

---

### Step 12 · Time Dimension Association 추가

Properties 패널 하단 **Associations** → **+ Create Association**

Select Association Target 창에서 검색:
```
SAP.TIME.VIEW_DIMENSION_DAY
```
선택 후 **Select**

매핑 설정:
- `POSTINGDATE` → `Date` (드래그 앤 드롭)

---

### Step 13 · Fact View 저장 및 배포

![Deploy 아이콘 클릭](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image08.png)

헤더 메뉴 **Deploy** (🚀) 클릭

팝업 확인:
- Business Name: **Combined Cashflow**
- Technical Name: **FV_Combined_CashFlow**

**Save** 클릭 → 배포 완료 알림 확인

### Step 14 · 데이터 미리보기

Output 노드 클릭 → **Data Viewer** → 실적 + 예측 데이터 통합 결과 확인

![Data Viewer — 실적(CASHFLOW_ACTUAL) + 예측(CASHFLOW_FORECAST) 레코드](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image09.png)

---

## Part 2 · Analytic Model 생성

### Step 15 · Fact View에서 AM 자동 생성

Output 노드 클릭 → Properties 패널 → **Create Analytic Model** 링크 클릭

![Analytic Model 에디터 — Fact View + Time Dimension 자동 연결](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image10.png)

### Step 16 · AM 이름 설정

Properties 패널:

| 항목 | 값 |
|------|-----|
| Business Name | **Combined Forecast Model** |
| Technical Name | **AM_Combined_Forecast_Model** |

### Step 17 · AM 저장 및 배포

헤더 **Deploy** (🚀) 클릭 → 이름 확인 → **Save**

### Step 18 · AM 미리보기

우상단 **Preview** 토글 ON

- 왼쪽 패널에서 `COMPANYCODE` Dimension 선택 → Rows에 추가
- 회사 코드별 실적/예측 금액 확인

![AM Preview — COMPANYCODE별 CASHFLOW_ACTUAL + CASHFLOW_FORECAST](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_6_image11.png)

---

## 핵심 포인트 요약

| 항목 | 값 |
|------|-----|
| Fact View 이름 | `FV_Combined_CashFlow` |
| 통합 방식 | UNION (BW 실적 + Databricks 예측) |
| Measure 수 | 4개 (Actual + Forecast + Upper + Lower) |
| 날짜 보완 공식 | `ADD_DAYS(date, DAYS_BETWEEN('2025-06-24', CURRENT_DATE()))` |
| Analytic Model | `AM_Combined_Forecast_Model` |
| 다음 단계 | SAC에서 이 AM을 데이터 소스로 사용 |

---

*다음 레슨: [06 · 데이터 시각화 (SAC 대시보드) →](./06_data_visualization.md)*