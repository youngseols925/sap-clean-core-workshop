# Lesson 4 · Data Product 설치 (SAP Datasphere)

> ⏱ 5분 | **직접 실습**

## 학습 목표

SAP Databricks에서 게시한 **현금 흐름 예측 Data Product**를  
SAP Datasphere 내 나의 스페이스에 설치합니다.

---

## 개념 이해

### Data Product 설치란?

Catalog에 등록된 Data Product를 내 스페이스의 **Local Table**로 가져오는 것입니다.  
설치 후 이 테이블을 **View, Fact View, Analytic Model** 등에서 소스로 사용할 수 있습니다.

```
SAP BDC Catalog
  └── cashflow forecast data product (from Databricks)
               │
               ▼ Install
  내 스페이스 (AC317935U01)
  └── cashflow_forecast (Local Table)
               │
               ▼ 다음 레슨에서 사용
          Fact View (BW 실적 + Databricks 예측 UNION)
```

---

## 실습

### Step 1 · SAP Datasphere 로그인

브라우저에서 SAP Datasphere URL 접속

- Username: `AC317935U01`
- Password: (강사 제공)

[📸 스크린샷: SAP Datasphere 메인 화면]

### Step 2 · Catalog & Marketplace 접속

[📸 스크린샷: 좌측 네비게이션 — Catalog & Marketplace → Search]

좌측 네비게이션 → **Catalog & Marketplace** → **Search**

### Step 3 · 검색 필터 설정

[📸 스크린샷: 필터 아이콘 클릭 — Data Products + Databricks 필터 선택]

1. 🔍 **Filter** 아이콘 클릭
2. **All → Data Products** 선택
3. System Type: **SAP Databricks** 선택
4. 우상단 **Display as List** 클릭 (찾기 쉽게)

### Step 4 · Data Product 검색

검색창에 입력:
```
cashflow forecast data product
```
→ **Enter** 또는 🔍 클릭

[📸 스크린샷: 검색 결과 — cashflow forecast data product]

> **내 것이 없으면**: `cashflow forecast data product`(강사 제공 pre-delivered 버전) 사용

### Step 5 · Data Product 상세 확인

검색 결과에서 **cashflow forecast data product** 선택

[📸 스크린샷: Data Product 상세 화면 — 메타데이터, 버전 정보]

확인 항목:
- Source: SAP Databricks
- 포함 테이블: `cashflow_forecast`
- 컬럼 구조 (POSTINGDATE, COMPANYCODE, CASHFLOW_FORECAST, CASHFLOW_FORECAST_UPPER, CASHFLOW_FORECAST_LOWER)

### Step 6 · Data Product 설치

[📸 스크린샷: Install 버튼 클릭]

1. **Install** 버튼 클릭
2. 대상 스페이스: `AC317935U01` 선택
3. **Install** 확인

### Step 7 · 설치 완료 확인

[📸 스크린샷: Data Builder — cashflow_forecast 테이블 확인]

**Data Builder** → 내 스페이스에서 `cashflow_forecast` 테이블 확인  
**Data Preview**로 예측 데이터 레코드 확인

---

## 설치된 테이블 구조

| 컬럼명 | 설명 |
|--------|------|
| `POSTINGDATE` | 전기 일자 (예측 기간) |
| `COMPANYCODE` | 회사 코드 (1710, 1720, 1730) |
| `CASHFLOW_FORECAST` | ML 예측 현금 흐름 |
| `CASHFLOW_FORECAST_UPPER` | 예측 상한값 |
| `CASHFLOW_FORECAST_LOWER` | 예측 하한값 |

---

## 핵심 포인트 요약

| 항목 | 설명 |
|------|------|
| 설치 위치 | Catalog & Marketplace → Search |
| 필터 | Data Products + SAP Databricks |
| 설치 결과 | 내 스페이스 Local Table |
| 다음 단계 | 이 테이블을 Fact View에서 BW 실적 데이터와 UNION |

---

*다음 레슨: [05 · 데이터 모델링 (Fact View + AM) →](./05_data_modeling.md)*
