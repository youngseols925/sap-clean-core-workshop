# ZSD_OPENORD_STATUS → SAP Datasphere 전환 설계서

> 작성일: 2026-05-15  
> 대상: youngseols925/sap-clean-core-workshop  
> 시나리오: SAP Clean Core — ERP CBO Z-Program → Datasphere 이전

---

## 1. 전체 아키텍처 개요

```
[ SAP S/4HANA ERP ]
  ZSD_OPENORD_STATUS (ABAP Report, 10개 테이블 조인/계산)
  → ZSDT_OPENORD (Z-Table, 아이템 단위 저장)
           │
           │  Replication Flow (RF_SD_OPENORD)
           ▼
[ SAP Datasphere — ALEX Space ]
  ┌─────────────────────────────────────────────────────┐
  │  LT_OPENORD          (Local Table - RF Target)      │
  │         ↓                                           │
  │  V_OPENORD_F         (Fact View - ANALYTICAL_FACT)  │
  │         ↓                                           │
  │  AM_OPENORD          (Analytic Model - CUBE)        │
  │         ↑                                           │
  │  V_MONTH_COMPARISON  (Helper View - 시간비교 변수)   │
  └─────────────────────────────────────────────────────┘
```

**설계 원칙**
- ABAP의 10개 테이블 조인 + 복잡 계산 로직을 **DSP 레이어로 이전**
- ERP는 ZSDT_OPENORD에 데이터 저장만 → **RF로 DSP에 복제**
- DSP에서 **AM 변수/지표**로 ABAP 계산 로직 대체
- Flat Fact View 구조 (Dim View 조인 없음 — 워크샵 단순화)

---

## 2. 오브젝트 목록

| # | 오브젝트 타입 | 기술명 | 레이블 | 비고 |
|---|------------|--------|--------|------|
| 1 | Replication Flow | `RF_SD_OPENORD` | Open Order RF | INITIAL |
| 2 | Local Table | `LT_OPENORD` | Open Order 로컬 테이블 | RF 타겟 |
| 3 | Fact View | `V_OPENORD_F` | Open Order Fact View | ANALYTICAL_FACT |
| 4 | Helper View | `V_MONTH_COMPARISON` | 월 비교 헬퍼 뷰 | 재사용 가능 |
| 5 | Analytic Model | `AM_OPENORD` | Open Order 현황 분석 | ANALYTICAL_CUBE |

---

## 3. ZSDT_OPENORD 테이블 → LT_OPENORD 컬럼 매핑

ZSDT_OPENORD SE11 구조 기준 (개발일지 Section 7):

| 필드 | Key | 타입 | 설명 | DSP 타입 |
|------|-----|------|------|---------|
| MANDT | ✅ | MANDT | 클라이언트 | cds.String(3) |
| VBELN | ✅ | VBELN_VA | 판매 오더 번호 | cds.String(10) |
| POSNR | ✅ | POSNR_VA | 오더 아이템 | cds.String(6) |
| AUART | | AUART | 오더 유형 | cds.String(4) |
| AUDAT | | AUDAT | 오더 생성일 | cds.Date |
| AUDAT_YM | | SPMON | 오더 생성년월 (YYYYMM) | cds.String(6) |
| VKORG | | VKORG | 영업 조직 | cds.String(4) |
| VTWEG | | VTWEG | 유통 경로 | cds.String(2) |
| SPART | | SPART | 제품군 | cds.String(2) |
| KUNNR | | KUNNR | 고객 코드 | cds.String(10) |
| MATNR | | MATNR | 자재 번호 | cds.String(18) |
| MATKL | | MATKL | 자재 그룹 | cds.String(9) |
| WAERS | | WAERS | 오더 통화 | cds.String(5) |
| ORD_QTY | | DEC(13,3) | 오더 수량 | cds.Decimal(13,3) |
| CONF_QTY | | DEC(13,3) | 납품 확정 수량 | cds.Decimal(13,3) |
| OPEN_QTY | | DEC(13,3) | 미납품 잔량 | cds.Decimal(13,3) |
| DLV_QTY | | DEC(13,3) | 실납품 수량 | cds.Decimal(13,3) |
| BIL_QTY | | DEC(13,3) | 청구 수량 | cds.Decimal(13,3) |
| ORD_AMT | | DEC(15,2) | 오더 금액 | cds.Decimal(15,2) |
| OPEN_AMT | | DEC(15,2) | 미결 금액 | cds.Decimal(15,2) |
| BIL_AMT | | DEC(15,2) | 청구 금액 | cds.Decimal(15,2) |
| EDATU | | EDATU | 납품 예정일 | cds.Date |
| WBS_DELAY | | XFELD | 납품 지연 여부 (X) | cds.String(1) |
| DELAY_DAYS | | INT4 | 지연 일수 | cds.Integer |
| AGING_GRP | | CHAR3 | Aging 구간 (030/060/090/90+) | cds.String(3) |
| DLV_STAT | | CHAR1 | 납품 상태 (A/B/C) | cds.String(1) |
| BIL_STAT | | CHAR1 | 청구 상태 (A/B/C) | cds.String(1) |
| CREDIT_EXC | | XFELD | 신용 한도 초과 여부 | cds.String(1) |
| TRAFFIC | | CHAR1 | 신호등 (G/Y/R) | cds.String(1) |

> **참고**: `DLV_RATE`, `BIL_RATE`는 ZSDT_OPENORD에 없음 → AM CALCULATION 지표로 대체

---

## 4. RF_SD_OPENORD (Replication Flow)

| 항목 | 값 |
|------|----|
| 소스 시스템 | S4_HANA (connectionType: ABAP) |
| 소스 컨테이너 | `/CDS_EXTRACTION` (단, Z-Table은 직접 RFC 방식) |
| 소스 오브젝트 | `ZSDT_OPENORD` |
| 타겟 공간 | ALEX |
| 타겟 테이블 | `LT_OPENORD` |
| Load 타입 | `INITIAL` (Full Load) |
| 실행 방식 | 스케줄러 (일 1회, p_nodisp=X 옵션으로 ABAP 먼저 실행 후) |

> **⚠️ 주의**: Z-Table은 RF에서 CDS View가 아닌 직접 테이블 복제 방식 사용. `INITIAL` load 권장. 증분 방식은 Change Pointer 설정 필요.

---

## 5. V_OPENORD_F (Fact View)

**목적**: LT_OPENORD를 Datasphere에서 분석 가능한 Fact View로 변환

**어노테이션**:
- `@ObjectModel.modelingPattern: ANALYTICAL_FACT`
- `@ObjectModel.supportedCapabilities: [DATA_STRUCTURE]`

**주요 변환 로직**:

| 소스 컬럼 | Fact View 컬럼 | 변환 | 비고 |
|----------|--------------|------|------|
| AUDAT_YM | BASE_MONTH | 그대로 (YYYYMM) | 시간비교 기준 |
| AUDAT | AUDAT | cds.Date | 날짜 필터용 |
| ORD_AMT | ORD_AMT | @Aggregation.default: SUM | BASE 지표 |
| OPEN_AMT | OPEN_AMT | @Aggregation.default: SUM | BASE 지표 |
| BIL_AMT | BIL_AMT | @Aggregation.default: SUM | BASE 지표 |
| ORD_QTY | ORD_QTY | @Aggregation.default: SUM | BASE 지표 |
| OPEN_QTY | OPEN_QTY | @Aggregation.default: SUM | BASE 지표 |
| DLV_QTY | DLV_QTY | @Aggregation.default: SUM | BASE 지표 |
| BIL_QTY | BIL_QTY | @Aggregation.default: SUM | BASE 지표 |
| DELAY_DAYS | DELAY_DAYS | @Aggregation.default: SUM | BASE 지표 |
| 나머지 | 차원 필드 | 그대로 | VKORG, KUNNR 등 |

---

## 6. AM_OPENORD (Analytic Model) 상세 설계

### 6-1. 차원 (Attributes / 분석 축)

| 컬럼 | 레이블 | 설명 |
|------|--------|------|
| VKORG | 영업 조직 | |
| VTWEG | 유통 경로 | |
| SPART | 제품군 | |
| KUNNR | 고객 코드 | |
| MATNR | 자재 번호 | |
| MATKL | 자재 그룹 | |
| AUART | 오더 유형 | |
| WAERS | 통화 | |
| BASE_MONTH | 기준 년월 | AUDAT_YM, YYYYMM, 시간비교 기준 |
| AUDAT | 오더 생성일 | |
| AGING_GRP | Aging 구간 | 030/060/090/90+ |
| DLV_STAT | 납품 상태 | A:미납/B:부분납/C:완납 |
| BIL_STAT | 청구 상태 | A:미청구/B:부분청구/C:완료 |
| WBS_DELAY | 납품 지연 | X=지연 |
| CREDIT_EXC | 신용 초과 | X=초과 |
| TRAFFIC | 신호등 | G/Y/R |

### 6-2. BASE 지표 (Fact View에서 직접 집계)

| 기술명 | 레이블 | 집계 | ABAP 대응 필드 |
|--------|--------|------|--------------|
| ORD_AMT | 오더 금액 | SUM | gs_openord-ord_amt |
| OPEN_AMT | 미결 금액 | SUM | gs_openord-open_amt |
| BIL_AMT | 청구 금액 | SUM | gs_openord-bil_amt |
| ORD_QTY | 오더 수량 | SUM | gs_openord-ord_qty |
| OPEN_QTY | 미납품 잔량 | SUM | gs_openord-open_qty |
| DLV_QTY | 납품 수량 | SUM | gs_openord-dlv_qty |
| BIL_QTY | 청구 수량 | SUM | gs_openord-bil_qty |
| DELAY_DAYS | 지연 일수 합계 | SUM | gs_openord-delay_days |

### 6-3. CALCULATION 지표 (AM에서 계산 — ABAP ty_openord 계산 로직 대체)

| 기술명 | 레이블 | 공식 | ABAP 원본 로직 |
|--------|--------|------|--------------|
| DLV_RATE | 납품율 (%) | `DLV_QTY / ORD_QTY * 100` | `dlv_qty / ord_qty * 100` |
| BIL_RATE | 청구율 (%) | `BIL_QTY / ORD_QTY * 100` | `bil_qty / ord_qty * 100` |
| OPEN_RATE | 미결율 (%) | `OPEN_AMT / ORD_AMT * 100` | 신규 (DSP 추가) |
| DELAY_ORDER_CNT | 지연 오더 건수 | 별도 COUNT 처리 | 신규 (DSP 추가) |

### 6-4. RESTRICTION 지표 (기간별 필터 지표)

ABAP에서는 Selection Screen으로 기간 입력 → DSP에서는 **변수 기반 RESTRICTION**으로 대체

| 기술명 | 레이블 | 조건 | 대응 지표 |
|--------|--------|------|---------|
| Measure_Value | (기준값) | 항상 1 | - |
| CURR_MONTH_OPEN | 당월 미결금액 | BASE_MONTH = 당월 | OPEN_AMT |
| PREV_MONTH_OPEN | 전월 미결금액 | BASE_MONTH = 전월 | OPEN_AMT |
| CURR_YTD_OPEN | 당년누계 미결금액 | 당년1월 ≤ BASE_MONTH ≤ 당월 | OPEN_AMT |
| DELAY_OPEN | 지연 오더 미결금액 | WBS_DELAY = 'X' | OPEN_AMT |

> **참고**: RESTRICTION은 `crossCalculations` 섹션에 등록

### 6-5. 변수 (Variables / Params)

| 변수명 | 타입 | 레이블 | 설명 |
|--------|------|--------|------|
| P_MONTH | Input | 기준 월 | 사용자 직접 입력 (예: 202503) |
| RV_CURR_MONTH | Lookup (hidden) | 당월 변수 | V_MONTH_COMPARISON.CURRENT_MONTH |
| RV_PREVIOUS_MONTH | Lookup (hidden) | 전월 변수 | V_MONTH_COMPARISON.PREVIOUS_MONTH |
| RV_CURR_YEAR_JAN | Lookup (hidden) | 당년 1월 | V_MONTH_COMPARISON.CURRENT_YEAR_JAN |
| RV_PREVIOUS_YEAR_SAME_MONTH | Lookup (hidden) | 전년동월 | V_MONTH_COMPARISON.PREVIOUS_YEAR_SAME_MONTH |

---

## 7. ABAP 로직 → DSP 전환 대응 표

| ABAP 로직 | DSP 대응 |
|----------|---------|
| SELECT 10개 테이블 조인 | RF로 ZSDT_OPENORD 복제 → LT_OPENORD |
| elapsed_days 계산 | ABAP에서 계산 후 저장 (DELAY_DAYS 필드 재활용) |
| aging_grp (030/060/090/90+) | ABAP에서 계산 후 저장 → AM 차원으로 활용 |
| dlv_rate = dlv_qty/ord_qty*100 | AM CALCULATION 지표 |
| bil_rate = bil_qty/ord_qty*100 | AM CALCULATION 지표 |
| open_amt = ord_amt - bil_amt | ABAP에서 계산 후 저장 → BASE 지표 |
| traffic = G/Y/R 신호등 | ABAP에서 계산 후 저장 → AM 차원 (신호등 아이콘) |
| Selection Screen 기간 필터 | AM 입력 변수 P_MONTH |
| p_open/p_part 상태 필터 | AM에서 DLV_STAT 차원 필터로 대체 |
| ALV 신호등 출력 | Stories/Dashboards의 조건부 색상 포맷 |

---

## 8. 워크샵 시연 포인트

```
[ AS-IS: ERP CBO 방식 ]                [ TO-BE: Clean Core 방식 ]

ZSD_OPENORD_STATUS                      Datasphere AM_OPENORD
 ├─ 10개 테이블 직접 조인                 ├─ RF로 단일 테이블 복제
 ├─ 복잡 ABAP 계산 로직                   ├─ View/AM에서 집계/계산
 ├─ 분석 = ABAP Report 재실행             ├─ 실시간 대시보드
 ├─ ERP 리소스 점유 (KONV 등 대용량)      ├─ ERP 분리, 독립 확장
 └─ 커스터마이징 → 업그레이드 위험         └─ Clean Core 유지
```

**핵심 메시지**: ABAP에서 복잡하게 계산하던 **납품율, 청구율, Aging 분석, 신호등 로직**을 
Datasphere의 **지표(Measure) + 변수(Variable)** 구조로 표현 → ERP 코드 없이 동일한 분석 가능

---

## 9. 구현 순서 (다음 작업)

```
Step 1: LT_OPENORD Local Table JSON 생성
Step 2: RF_SD_OPENORD Replication Flow JSON 생성  
Step 3: V_OPENORD_F Fact View JSON 생성 (CSN)
Step 4: V_MONTH_COMPARISON Helper View JSON 생성 (기존 패턴 재사용)
Step 5: AM_OPENORD Analytic Model JSON 생성
Step 6: DSP CLI/UI로 배포
```
