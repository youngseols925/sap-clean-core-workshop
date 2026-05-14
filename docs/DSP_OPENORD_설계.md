# ZSD_OPENORD_STATUS → SAP Datasphere Clean Core 전환 설계서

> 작성일: 2026-05-15  
> 대상: youngseols925/sap-clean-core-workshop  
> 시나리오: SAP Clean Core — ERP CBO Z-Program → Datasphere 이전

---

## 1. 문제 정의 (AS-IS의 악순환)

```
[ 나쁜 패턴 — 현재 고객사 현실 ]

ERP: ZSD_OPENORD_STATUS
 ├─ VBAK + VBAP + VBEP + VBFA + LIPS + VBRP
 │   + KONV + KNA1 + KNVV + KNKK (10개 테이블 조인)
 ├─ 복잡한 ABAP 계산 로직 (Aging, 신호등, 납품율...)
 └─→ ZSDT_OPENORD (Z-Table에 저장)
           │
           │  BW/Datasphere가 Z-Table을 소스로 사용
           ▼
    BW InfoProvider / DSP Local Table
           ↓
    Query / Analytic Model

문제점:
  ① ERP 리소스 점유 — 대용량 조인이 OLTP 트랜잭션 성능 저하
  ② Z-Program + Z-Table이 ERP에 계속 존재 → Clean Core 위반
  ③ S/4HANA 업그레이드 시 CBO 검증 부담 증가
  ④ ZSDT_OPENORD는 ABAP 로직이 이미 계산된 결과물 → DSP에서 재계산 불가
```

---

## 2. 해결 방향 (TO-BE: Clean Core)

```
[ 올바른 패턴 — Standard DataSource 기반 ]

ERP Standard DataSources / CDS Views (SAP 표준 유지)
  ├─ 2LIS_11_VAHDR  또는  C_SalesOrderHeaderDEX_1   (오더 헤더)
  ├─ 2LIS_11_VAITM  또는  C_SalesDocumentItemDEX_1  (오더 아이템)
  ├─ 2LIS_11_VASCL                                   (납품 스케줄)
  ├─ 2LIS_12_VCITM  또는  C_DeliveryDocumentItemDEX_1 (납품 아이템)
  └─ 2LIS_13_VDITM  또는  C_BillingDocumentItemDEX_1  (청구 아이템)
           │
           │  Replication Flow (표준 소스 → DSP Local Table)
           ▼
  DSP Local Tables (원천 그대로 저장)
           │
           │  Transformation Flow ← ABAP 계산 로직 이전
           ▼
  DSP Target Table (TT_OPENORD: 조인 + 계산 결과)
           │
           ▼
  Fact View → Analytic Model (AM_OPENORD)

핵심 변화:
  ① ERP Z-Program, Z-Table 제거 가능 → Clean Core 실현
  ② ABAP 로직(조인, Aging 계산, 납품율 등)을 TF 로직으로 이전
  ③ AM 변수/지표로 기간 분석, 비교 분석 구현
  ④ Standard Source 사용 → 업그레이드 영향 최소화
```

---

## 3. 전체 오브젝트 구성

```
[ ERP ]                         [ SAP Datasphere — ALEX Space ]
                                
2LIS_11_VAHDR ──RF──→ LT_SD_VAHDR  ─┐
2LIS_11_VAITM ──RF──→ LT_SD_VAITM  ─┤
2LIS_11_VASCL ──RF──→ LT_SD_VASCL  ─┼─→ TF_OPENORD ──→ TT_OPENORD
2LIS_12_VCITM ──RF──→ LT_SD_DLVITM ─┤      (ABAP 로직)
2LIS_13_VDITM ──RF──→ LT_SD_BLITM  ─┘          │
                                                  ▼
                                         V_OPENORD_F (Fact View)
                                                  │
                                    V_MONTH_COMPARISON (Helper)
                                                  │
                                         AM_OPENORD (Analytic Model)
```

| # | 오브젝트 타입 | 기술명 | 소스 | 비고 |
|---|------------|--------|------|------|
| 1 | Replication Flow | `RF_SD_OO_TRAN` | ERP → DSP | 5개 표준 소스 복제 |
| 2 | Local Table | `LT_SD_VAHDR` | 2LIS_11_VAHDR | 오더 헤더 |
| 3 | Local Table | `LT_SD_VAITM` | 2LIS_11_VAITM | 오더 아이템 |
| 4 | Local Table | `LT_SD_VASCL` | 2LIS_11_VASCL | 납품 스케줄 |
| 5 | Local Table | `LT_SD_DLVITM` | 2LIS_12_VCITM | 납품 아이템 |
| 6 | Local Table | `LT_SD_BLITM` | 2LIS_13_VDITM | 청구 아이템 |
| 7 | Transformation Flow | `TF_OPENORD` | LT_* → TT_OPENORD | ABAP 로직 이전 |
| 8 | Target Table | `TT_OPENORD` | TF 결과 저장 | Fact View 소스 |
| 9 | Fact View | `V_OPENORD_F` | TT_OPENORD | ANALYTICAL_FACT |
| 10 | Helper View | `V_MONTH_COMPARISON` | SAP.TIME | 시간비교 변수 |
| 11 | Analytic Model | `AM_OPENORD` | V_OPENORD_F | 최종 분석 |

---

## 4. RF_SD_OO_TRAN (Replication Flow)

### 4-1. 소스 DataSource 선택 기준

| ABAP 테이블 | ODP DataSource (BW 방식) | CDS View (S/4HANA 방식) | 선택 |
|------------|------------------------|------------------------|------|
| VBAK | `2LIS_11_VAHDR` | `C_SalesOrderHeaderDEX_1` | `2LIS_11_VAHDR` |
| VBAP | `2LIS_11_VAITM` | `C_SalesDocumentItemDEX_1` | `2LIS_11_VAITM` |
| VBEP | `2LIS_11_VASCL` | `C_SalesOrderSchedLineDEX_1` | `2LIS_11_VASCL` |
| LIPS | `2LIS_12_VCITM` | `C_DeliveryDocumentItemDEX_1` | `2LIS_12_VCITM` |
| VBRP | `2LIS_13_VDITM` | `C_BillingDocumentItemDEX_1` | `2LIS_13_VDITM` |

> **워크샵 선택 이유**: ODP DataSource(2LIS_*)는 BW 시절부터 표준으로 검증되었고,  
> Delta 추출(변경분만)을 지원하여 초기 부하 이후 증분 복제 가능.  
> S/4HANA 환경에서는 CDS View 방식도 동일하게 적용 가능.

### 4-2. RF 구성

| 항목 | 값 |
|------|----|
| 소스 커넥션 | S4_HANA (connectionType: ABAP) |
| 소스 컨테이너 | `/ODP_BW` (ODP DataSource) |
| Load 타입 | REPLICATE (Delta) |
| 타겟 스페이스 | ALEX |

---

## 5. TF_OPENORD (Transformation Flow) — ABAP 로직 이전 핵심

**역할**: ABAP `ZSD_OPENORD_STATUS`의 10개 테이블 조인 + 계산 로직을 TF로 구현

### 5-1. 조인 구조

```
LT_SD_VAHDR (기준)
    INNER JOIN LT_SD_VAITM  ON  VBELN
         LEFT JOIN LT_SD_VASCL   ON  VBELN, POSNR  (납품 스케줄 집계)
         LEFT JOIN LT_SD_DLVITM  ON  VBELN, POSNR  (납품 수량 집계)
         LEFT JOIN LT_SD_BLITM   ON  VBELN, POSNR  (청구 수량/금액 집계)
```

> **참고**: KONV(가격조건), KNA1(고객마스터), KNVV(영업데이터), KNKK(신용한도)는  
> 2LIS DataSource에 이미 denormalized되어 포함되어 있어 별도 조인 불필요.

### 5-2. TF 계산 컬럼 (ABAP 로직 → SQL 변환)

| 계산 항목 | ABAP 원본 로직 | TF SQL 로직 |
|---------|--------------|-----------|
| **AUDAT_YM** (년월) | `ls_vbak-audat(6)` | `LEFT(AUDAT, 6)` |
| **ELAPSED_DAYS** (경과일) | `sy-datum - ls_vbak-audat` | `DAYS_BETWEEN(AUDAT, CURRENT_DATE)` |
| **AGING_GRP** (Aging 구간) | IF elapsed ≤ 30 → '030'<br>≤ 60 → '060'<br>≤ 90 → '090'<br>else → '90+' | `CASE WHEN elapsed ≤ 30 THEN '030' WHEN elapsed ≤ 60 THEN '060' WHEN elapsed ≤ 90 THEN '090' ELSE '90+' END` |
| **CONF_QTY** (확정수량) | `SUM(vbep-bmeng)` per item | `SUM(LT_SD_VASCL.WMENG)` GROUP BY VBELN, POSNR |
| **OPEN_QTY** (미납잔량) | `ord_qty - conf_qty` | `KWMENG - CONF_QTY` |
| **DLV_QTY** (납품수량) | VBFA→LIPS 조인 집계 | `SUM(LT_SD_DLVITM.LFIMG)` GROUP BY ref VBELN, POSNR |
| **BIL_QTY** (청구수량) | VBFA→VBRP 조인 집계 | `SUM(LT_SD_BLITM.FKIMG)` GROUP BY ref VBELN, POSNR |
| **BIL_AMT** (청구금액) | `SUM(vbrp-netwr)` | `SUM(LT_SD_BLITM.NETWR)` |
| **OPEN_AMT** (미결금액) | `ord_amt - bil_amt` | `ORD_AMT - BIL_AMT` |
| **DLV_STAT** (납품상태) | dlv_qty=0 → 'A'<br>= ord_qty → 'C'<br>else → 'B' | `CASE WHEN DLV_QTY = 0 THEN 'A' WHEN DLV_QTY >= KWMENG THEN 'C' ELSE 'B' END` |
| **BIL_STAT** (청구상태) | bil_qty=0 → 'A'<br>= dlv_qty → 'C'<br>else → 'B' | `CASE WHEN BIL_QTY = 0 THEN 'A' WHEN BIL_QTY >= DLV_QTY THEN 'C' ELSE 'B' END` |
| **WBS_DELAY** (납품지연) | datum > edatu AND dlv_stat≠'C' → 'X' | `CASE WHEN CURRENT_DATE > EDATU AND DLV_STAT != 'C' THEN 'X' ELSE '' END` |
| **DELAY_DAYS** (지연일수) | `sy-datum - edatu` if delay | `CASE WHEN WBS_DELAY='X' THEN DAYS_BETWEEN(EDATU, CURRENT_DATE) ELSE 0 END` |
| **CREDIT_EXC** (신용초과) | `skfor + ssobl > klimk` | 2LIS_11_VAHDR의 신용관련 필드 활용 |
| **TRAFFIC** (신호등) | credit_exc → 'R'<br>delay>7 → 'R'<br>delay≤7 → 'Y'<br>aging='90+' → 'Y'<br>else → 'G' | `CASE WHEN CREDIT_EXC='X' THEN 'R' WHEN DELAY_DAYS > 7 THEN 'R' WHEN WBS_DELAY='X' THEN 'Y' WHEN AGING_GRP='90+' THEN 'Y' ELSE 'G' END` |

### 5-3. TT_OPENORD 컬럼 (TF Output)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| VBELN | String(10) | 판매 오더 번호 |
| POSNR | String(6) | 오더 아이템 |
| AUART | String(4) | 오더 유형 |
| AUDAT | Date | 오더 생성일 |
| AUDAT_YM | String(6) | 오더 생성년월 (YYYYMM) — **시간비교 기준** |
| VKORG | String(4) | 영업 조직 |
| VTWEG | String(2) | 유통 경로 |
| SPART | String(2) | 제품군 |
| KUNNR | String(10) | 고객 코드 |
| KUNNR_NAME | String(40) | 고객명 |
| MATNR | String(18) | 자재 번호 |
| MATKL | String(9) | 자재 그룹 |
| WAERS | String(5) | 통화 |
| ORD_QTY | Decimal(13,3) | 오더 수량 |
| CONF_QTY | Decimal(13,3) | 납품 확정 수량 |
| OPEN_QTY | Decimal(13,3) | 미납품 잔량 |
| DLV_QTY | Decimal(13,3) | 실납품 수량 |
| BIL_QTY | Decimal(13,3) | 청구 수량 |
| ORD_AMT | Decimal(15,2) | 오더 금액 |
| OPEN_AMT | Decimal(15,2) | 미결 금액 |
| BIL_AMT | Decimal(15,2) | 청구 금액 |
| EDATU | Date | 납품 예정일 |
| ELAPSED_DAYS | Integer | 오더 경과일수 |
| AGING_GRP | String(3) | Aging 구간 (030/060/090/90+) |
| DLV_STAT | String(1) | 납품 상태 (A/B/C) |
| BIL_STAT | String(1) | 청구 상태 (A/B/C) |
| WBS_DELAY | String(1) | 납품 지연 여부 (X) |
| DELAY_DAYS | Integer | 지연 일수 |
| CREDIT_EXC | String(1) | 신용 초과 여부 (X) |
| TRAFFIC | String(1) | 신호등 (G/Y/R) |

---

## 6. V_OPENORD_F (Fact View)

- **소스**: TT_OPENORD
- **어노테이션**: `ANALYTICAL_FACT`
- **핵심 역할**: 집계 지표 선언 (`@Aggregation.default: SUM`)

| 컬럼 | 역할 | @Aggregation |
|------|------|-------------|
| AUDAT_YM | **시간비교 기준** (BASE_MONTH) | — |
| ORD_AMT, OPEN_AMT, BIL_AMT | BASE 지표 | SUM |
| ORD_QTY, OPEN_QTY, DLV_QTY, BIL_QTY | BASE 지표 | SUM |
| DELAY_DAYS | BASE 지표 | SUM |
| 나머지 | 차원 (Attribute) | — |

---

## 7. AM_OPENORD (Analytic Model) 설계

### 7-1. BASE 지표 (TF 계산 결과를 집계)

| 기술명 | 레이블 |
|--------|--------|
| ORD_AMT | 오더 금액 |
| OPEN_AMT | 미결 금액 |
| BIL_AMT | 청구 금액 |
| ORD_QTY | 오더 수량 |
| OPEN_QTY | 미납 수량 |
| DLV_QTY | 납품 수량 |
| BIL_QTY | 청구 수량 |
| DELAY_DAYS | 지연 일수 |

### 7-2. CALCULATION 지표 (AM에서 계산)

| 기술명 | 레이블 | 공식 |
|--------|--------|------|
| DLV_RATE | 납품율(%) | `DLV_QTY / ORD_QTY * 100` |
| BIL_RATE | 청구율(%) | `BIL_QTY / ORD_QTY * 100` |
| OPEN_RATE | 미결율(%) | `OPEN_AMT / ORD_AMT * 100` |

### 7-3. RESTRICTION 지표 (기간별 필터)

| 기술명 | 레이블 | 조건 |
|--------|--------|------|
| CURR_MONTH_OPEN | 당월 미결금액 | BASE_MONTH = 당월 |
| PREV_MONTH_OPEN | 전월 미결금액 | BASE_MONTH = 전월 |
| CURR_YTD_OPEN | 당년누계 미결금액 | 당년1월 ≤ BASE_MONTH ≤ 당월 |
| PREV_YTD_OPEN | 전년누계 미결금액 | 전년1월 ≤ BASE_MONTH ≤ 전년동월 |

### 7-4. 변수 (Variables)

| 변수명 | 타입 | 레이블 |
|--------|------|--------|
| P_MONTH | Input | 기준 월 (사용자 입력) |
| RV_CURR_MONTH | Lookup (hidden) | 당월 |
| RV_PREVIOUS_MONTH | Lookup (hidden) | 전월 |
| RV_CURR_YEAR_JAN | Lookup (hidden) | 당년 1월 |
| RV_PREVIOUS_YEAR_SAME_MONTH | Lookup (hidden) | 전년동월 |
| RV_PREVIOUS_YEAR_JAN | Lookup (hidden) | 전년 1월 |

---

## 8. AS-IS vs TO-BE 전환 대응표

| 항목 | AS-IS (ABAP CBO) | TO-BE (Clean Core DSP) |
|------|-----------------|----------------------|
| **데이터 소스** | VBAK/VBAP/VBEP 등 10개 테이블 직접 조인 | Standard DataSource (2LIS_11_VAHDR 등) |
| **ERP Z-Object** | ZSD_OPENORD_STATUS + ZSDT_OPENORD 존재 | 제거 가능 |
| **조인 로직** | ABAP LOOP + READ TABLE | TF JOIN 절 |
| **Aging 계산** | ABAP IF/ELSEIF | TF CASE WHEN |
| **납품율/청구율** | ABAP 산술 계산 → ZSDT_OPENORD 저장 | AM CALCULATION 지표 |
| **신호등 로직** | ABAP IF → ZSDT_OPENORD.TRAFFIC | TF CASE WHEN → TT_OPENORD.TRAFFIC |
| **기간 필터** | Selection Screen (s_audat) | AM 입력변수 P_MONTH |
| **결과 조회** | SE38 실행 → ALV | Stories / SAC Dashboard |
| **ERP 리소스** | 매 실행 시 OLTP DB 조인 | RF 이후 DSP 독립 처리 |

---

## 9. 워크샵 시연 스토리

```
[ STEP 1: 문제 제기 ]
  "고객사에서 ZSD_OPENORD_STATUS 같은 CBO Report를 수백 개 운영 중
   → 매일 배치로 실행, ERP OLTP 성능 저하
   → ZSDT_OPENORD를 BW/DSP 소스로 사용 → 악순환"

[ STEP 2: Clean Core 전환 선언 ]
  "Z-Program, Z-Table 없이 Standard DataSource만으로 동일한 분석을!"

[ STEP 3: DSP 시연 ]
  RF: 2LIS_11_VAHDR/VAITM → LT_SD_VAHDR/VAITM 자동 복제
  TF: 10개 테이블 조인 + Aging/신호등 계산 → TT_OPENORD
  AM: 납품율/청구율 지표 + 당월/전월/누계 비교 분석

[ STEP 4: 효과 ]
  ① ERP Z-Object 제거 → Clean Core 달성
  ② ERP 리소스 분리 → OLTP 성능 보호
  ③ DSP에서 실시간 대시보드 → 분석 고도화
```

---

## 10. 구현 순서 (다음 작업)

```
Step 1: LT_SD_VAHDR, LT_SD_VAITM, LT_SD_VASCL, LT_SD_DLVITM, LT_SD_BLITM
        → Local Table JSON (5개, 2LIS DataSource 컬럼 기준)

Step 2: RF_SD_OO_TRAN
        → Replication Flow JSON (5개 소스 → 5개 LT)

Step 3: TT_OPENORD
        → TF Target Table JSON (섹션 5-3 컬럼 기준)

Step 4: TF_OPENORD
        → Transformation Flow JSON (조인 + CASE WHEN 계산 로직)

Step 5: V_OPENORD_F
        → Fact View JSON (ANALYTICAL_FACT, @Aggregation.default: SUM)

Step 6: V_MONTH_COMPARISON
        → Helper View JSON (기존 패턴 재사용)

Step 7: AM_OPENORD
        → Analytic Model JSON (지표 + 변수)

Step 8: DSP CLI/UI 배포
```
