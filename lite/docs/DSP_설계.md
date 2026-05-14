# DSP Lite — Standard DataSource 기반 설계서

> **AS-IS → TO-BE 전환의 핵심**  
> ZSD_OO_LITE(VBAK+VBAP+KNA1)의 각 테이블/로직을 SAP Standard DataSource + DSP로 1:1 대체

---

## 1. 핵심 개념: 왜 Z-Table 소스를 쓰면 안 되는가?

```
❌ BAD (Z-Table 재활용 패턴)
  ERP: ZSD_OO_LITE 배치 → ZSDT_OO_LITE 저장
  DSP: ZSDT_OO_LITE RF → Local Table → AM
  문제: ERP 배치 실패 → DSP 데이터 오염, ERP 부하 여전히 존재

✅ GOOD (Clean Core 패턴)
  ERP: Standard ODP Extractor (SAP 표준 델타 메커니즘)
  DSP: 2LIS_11_VAHDR / 2LIS_11_VAITM / 0CUSTOMER_ATTR → RF → TF → AM
  효과: ERP 배치잡 완전 제거, 표준 델타 활용, Z 코드 의존성 0
```

---

## 2. ABAP 테이블 → Standard DataSource 매핑

### 2-1. VBAK → `2LIS_11_VAHDR` (판매오더 헤더)

| ABAP (VBAK) | DataSource 필드 | 설명 |
|-------------|----------------|------|
| VBELN | DOC_NUMBER | 판매오더 번호 |
| ERDAT | CREAT_DATE | 오더 생성일 |
| AUDAT | AUDAT | 오더 일자 |
| AUART | DOC_TYPE | 오더 유형 |
| VKORG | SALES_ORG | 영업 조직 |
| VTWEG | DISTR_CHAN | 유통 경로 |
| SPART | DIVISION | 제품군 |
| KUNNR | SOLD_TO | 판매처 고객 코드 |
| NETWR | NET_VALUE | 오더 금액 |
| WAERK | CURRENCY | 통화 |

> ODP 컨테이너: `/ODP_BW`, 오브젝트: `2LIS_11_VAHDR`  
> Delta 방식: AIE (After Image with Extraction) — 오더 변경 시 자동 델타

### 2-2. VBAP → `2LIS_11_VAITM` (판매오더 아이템)

| ABAP (VBAP) | DataSource 필드 | 설명 |
|-------------|----------------|------|
| VBELN | DOC_NUMBER | 판매오더 번호 |
| POSNR | S_ORD_ITEM | 오더 아이템 번호 |
| MATNR | MATERIAL | 자재 번호 |
| MATKL | MATL_GROUP | 자재 그룹 |
| ARKTX | SHORT_TEXT | 자재 설명 |
| MEINS | BASE_UOM | 기본 단위 |
| VRKME | SALES_UOM | 판매 단위 |
| KWMENG | ORD_QTY | 오더 수량 |
| NETWR | NET_VALUE | 아이템 금액 |
| ABGRU | REJ_REASON | 거부 이유 |

> Delta 방식: 헤더와 동일 AIE

### 2-3. KNA1 → `0CUSTOMER_ATTR` (고객 마스터 속성)

| ABAP (KNA1) | DataSource 필드 | 설명 |
|-------------|----------------|------|
| KUNNR | CUSTOMER | 고객 코드 (Key) |
| NAME1 | NAME | 고객명 |
| KTOKD | ACCT_GRP | 고객 계정 그룹 |
| LAND1 | COUNTRY | 국가 |
| REGIO | REGION | 지역 |

> ODP 컨테이너: `/ODP_BW`, 오브젝트: `0CUSTOMER_ATTR`  
> Delta 방식: Full + Attribute Change Run (마스터 데이터 변경 시 배치)

---

## 3. ABAP 로직 → DSP TF SQL 전환

### 3-1. ABAP 조건 → TF WHERE절

```abap
" ABAP: VBAK WHERE vbtyp = 'C'
" ABAP: VBAP WHERE abgru = ' '
```
↓
```sql
-- TF SQL에서 WHERE 조건으로 처리
WHERE H.VBTYP_N = 'C'   -- 판매오더만 (헤더)
  AND I.REJ_REASON = ''  -- 거부 안 된 아이템만
```

### 3-2. Aging 계산 — 핵심 전환 포인트

```abap
" ABAP: ERP에서 sy-datum 기준 실시간 계산
gs_openord-audat_ym     = ls_vbak-audat(6).
gs_openord-elapsed_days = sy-datum - ls_vbak-audat.
IF gs_openord-elapsed_days <= 30.
  gs_openord-aging_grp = '030'.
ELSEIF gs_openord-elapsed_days <= 60.
  gs_openord-aging_grp = '060'.
ELSEIF gs_openord-elapsed_days <= 90.
  gs_openord-aging_grp = '090'.
ELSE.
  gs_openord-aging_grp = '90+'.
ENDIF.
```
↓
```sql
-- DSP TF: SAP HANA SQL로 동일 로직 구현
LEFT(TO_VARCHAR(H.AUDAT, 'YYYYMMDD'), 6)           AS AUDAT_YM,
DAYS_BETWEEN(H.AUDAT, CURRENT_DATE)                AS ELAPSED_DAYS,
CASE
  WHEN DAYS_BETWEEN(H.AUDAT, CURRENT_DATE) <= 30   THEN '030'
  WHEN DAYS_BETWEEN(H.AUDAT, CURRENT_DATE) <= 60   THEN '060'
  WHEN DAYS_BETWEEN(H.AUDAT, CURRENT_DATE) <= 90   THEN '090'
  ELSE '90+'
END                                                AS AGING_GRP
```

> **교육 포인트**: `sy-datum`(ERP 실행 시점)이 `CURRENT_DATE`(DSP 실행 시점)로 대체.  
> TF를 스케줄 실행하면 Aging이 자동 최신화 — ABAP 배치잡 불필요!

### 3-3. 3-way JOIN (ABAP LOOP 대체)

```abap
" ABAP: 이중 LOOP + READ TABLE (O(n²) 탐색)
LOOP AT gt_vbak2 INTO ls_vbak.
  LOOP AT gt_vbap2 INTO ls_vbap WHERE vbeln = ls_vbak-vbeln.
    READ TABLE gt_kna12 INTO ls_kna1 WITH KEY kunnr = ls_vbak-kunnr.
    ...
  ENDLOOP.
ENDLOOP.
```
↓
```sql
-- DSP TF: HANA 엔진의 최적화된 JOIN (인덱스 활용)
FROM   LT_OO_VAHDR    H                          -- 헤더
INNER JOIN LT_OO_VAITM I  ON H.DOC_NUMBER = I.DOC_NUMBER
LEFT  JOIN LT_OO_CUST  C  ON H.SOLD_TO    = C.CUSTOMER
```

> **교육 포인트**: ABAP의 O(n²) LOOP → HANA JOIN으로 성능 대폭 향상.  
> KNA1이 마스터 데이터라 `LEFT JOIN` 사용 (고객명 없어도 오더 데이터 유지).

---

## 4. TO-BE DSP 아키텍처

```
[ ERP S/4HANA — ODP Extractor ]
  2LIS_11_VAHDR ─────────────────────┐
  2LIS_11_VAITM ─────────────────────┤──► RF_OO_LITE
  0CUSTOMER_ATTR ────────────────────┘        │
                                              │ (delta 복제)
                                              ▼
                              ┌───────────────────────────┐
                              │  LT_OO_VAHDR  (Local Table) │
                              │  LT_OO_VAITM  (Local Table) │
                              │  LT_OO_CUST   (Local Table) │
                              └───────────────────────────┘
                                              │
                                    TF_OO_LITE (SQL)
                                    • 3-way JOIN
                                    • WHERE REJ_REASON=''
                                    • DAYS_BETWEEN → ELAPSED_DAYS
                                    • CASE WHEN → AGING_GRP
                                    • LEFT(AUDAT,6) → AUDAT_YM
                                              │
                                              ▼
                                    TT_OO_LITE (Target Table)
                                              │
                                    V_OO_LITE_F (Fact View)
                                    [ANALYTICAL_FACT]
                                              │
                                    AM_OO_LITE (Analytic Model)
                                    • BASE: ORD_AMT, ORD_QTY
                                    • RESTRICTION: 당월/전월/YTD
                                    • Variable: P_MONTH
```

---

## 5. RF_OO_LITE 상세 (3개 태스크)

| # | Source DataSource | Container | Local Table | Load Type | Delta 방식 |
|---|------------------|-----------|-------------|-----------|-----------|
| 1 | `2LIS_11_VAHDR` | `/ODP_BW` | `LT_OO_VAHDR` | REPLICATE | AIE Delta |
| 2 | `2LIS_11_VAITM` | `/ODP_BW` | `LT_OO_VAITM` | REPLICATE | AIE Delta |
| 3 | `0CUSTOMER_ATTR` | `/ODP_BW` | `LT_OO_CUST`  | INITIAL + DELTA | Attr. Change |

> 소스 커넥션: `S4_HANA` (connectionType: `ABAP`)

---

## 6. Local Table 구조 상세

### LT_OO_VAHDR (2LIS_11_VAHDR → Key 필드만)

| 컬럼 | Key | 타입 | 2LIS 필드 | VBAK 필드 |
|------|-----|------|----------|----------|
| DOC_NUMBER | ✅ | String(10) | DOC_NUMBER | VBELN |
| CREAT_DATE | | Date | CREAT_DATE | ERDAT |
| AUDAT | | Date | AUDAT | AUDAT |
| DOC_TYPE | | String(4) | DOC_TYPE | AUART |
| SALES_ORG | | String(4) | SALES_ORG | VKORG |
| DISTR_CHAN | | String(2) | DISTR_CHAN | VTWEG |
| DIVISION | | String(2) | DIVISION | SPART |
| SOLD_TO | | String(10) | SOLD_TO | KUNNR |
| NET_VALUE | | Decimal(15,2) | NET_VALUE | NETWR |
| CURRENCY | | String(5) | CURRENCY | WAERK |
| VBTYP_N | | String(1) | VBTYP_N | VBTYP |

### LT_OO_VAITM (2LIS_11_VAITM → Key 필드만)

| 컬럼 | Key | 타입 | 2LIS 필드 | VBAP 필드 |
|------|-----|------|----------|----------|
| DOC_NUMBER | ✅ | String(10) | DOC_NUMBER | VBELN |
| S_ORD_ITEM | ✅ | String(6) | S_ORD_ITEM | POSNR |
| MATERIAL | | String(18) | MATERIAL | MATNR |
| MATL_GROUP | | String(9) | MATL_GROUP | MATKL |
| SHORT_TEXT | | String(40) | SHORT_TEXT | ARKTX |
| BASE_UOM | | String(3) | BASE_UOM | MEINS |
| SALES_UOM | | String(3) | SALES_UOM | VRKME |
| ORD_QTY | | Decimal(13,3) | ORD_QTY | KWMENG |
| NET_VALUE | | Decimal(15,2) | NET_VALUE | NETWR |
| REJ_REASON | | String(2) | REJ_REASON | ABGRU |

### LT_OO_CUST (0CUSTOMER_ATTR → 필요 필드만)

| 컬럼 | Key | 타입 | 0CUSTOMER_ATTR | KNA1 필드 |
|------|-----|------|---------------|----------|
| CUSTOMER | ✅ | String(10) | CUSTOMER | KUNNR |
| NAME | | String(35) | NAME | NAME1 |
| ACCT_GRP | | String(4) | ACCT_GRP | KTOKD |
| COUNTRY | | String(3) | COUNTRY | LAND1 |
| REGION | | String(3) | REGION | REGIO |

---

## 7. TF_OO_LITE 전체 SQL

```sql
SELECT
  H.DOC_NUMBER                                            AS VBELN,
  I.S_ORD_ITEM                                           AS POSNR,
  H.DOC_TYPE                                             AS AUART,
  H.AUDAT                                                AS AUDAT,
  LEFT(TO_VARCHAR(H.AUDAT, 'YYYYMMDD'), 6)               AS AUDAT_YM,
  H.SALES_ORG                                            AS VKORG,
  H.DISTR_CHAN                                           AS VTWEG,
  H.DIVISION                                             AS SPART,
  H.SOLD_TO                                              AS KUNNR,
  C.NAME                                                 AS KUNNR_NAME,
  C.COUNTRY                                              AS LAND1,
  I.MATERIAL                                             AS MATNR,
  I.MATL_GROUP                                           AS MATKL,
  I.SHORT_TEXT                                           AS ARKTX,
  I.BASE_UOM                                             AS MEINS,
  I.SALES_UOM                                            AS VRKME,
  H.CURRENCY                                             AS WAERS,
  I.ORD_QTY                                              AS ORD_QTY,
  I.NET_VALUE                                            AS ORD_AMT,
  DAYS_BETWEEN(H.AUDAT, CURRENT_DATE)                    AS ELAPSED_DAYS,
  CASE
    WHEN DAYS_BETWEEN(H.AUDAT, CURRENT_DATE) <= 30  THEN '030'
    WHEN DAYS_BETWEEN(H.AUDAT, CURRENT_DATE) <= 60  THEN '060'
    WHEN DAYS_BETWEEN(H.AUDAT, CURRENT_DATE) <= 90  THEN '090'
    ELSE '90+'
  END                                                    AS AGING_GRP
FROM   LT_OO_VAHDR  H
INNER JOIN LT_OO_VAITM I  ON  H.DOC_NUMBER = I.DOC_NUMBER
LEFT  JOIN LT_OO_CUST  C  ON  H.SOLD_TO    = C.CUSTOMER
WHERE  I.REJ_REASON = ''          -- ABAP의 "abgru = ' '" 대응
```

---

## 8. ABAP vs DSP 비교 요약 (워크샵 토론 포인트)

| 항목 | AS-IS (ABAP) | TO-BE (DSP) |
|------|-------------|------------|
| 데이터 소스 | VBAK, VBAP, KNA1 직접 SELECT | Standard DataSource (ODP) |
| 조인 방식 | ABAP 이중 LOOP + READ TABLE | HANA SQL 3-way JOIN |
| Aging 계산 | `sy-datum - audat` | `DAYS_BETWEEN(AUDAT, CURRENT_DATE)` |
| 년월 추출 | `audat(6)` | `LEFT(TO_VARCHAR(AUDAT,'YYYYMMDD'),6)` |
| 거부 필터 | `WHERE abgru = ' '` | `WHERE REJ_REASON = ''` |
| 실행 시점 | 수동 배치 or 스케줄 | TF 스케줄 자동 실행 |
| ERP 부하 | 실행 시마다 ERP 조회 | Delta 복제 후 HANA에서 처리 |
| Z 코드 의존 | **있음** | **없음 (Standard DataSource만)** |
| 유지보수 | ABAP 개발자 필요 | SQL/DSP UI로 누구나 수정 |

---

## 9. 워크샵 실습 순서 (오후 세션)

```
Step 1 (15분)  RF_OO_LITE 생성
  - Source Connection: S4_HANA
  - Task 1: 2LIS_11_VAHDR → LT_OO_VAHDR
  - Task 2: 2LIS_11_VAITM → LT_OO_VAITM
  - Task 3: 0CUSTOMER_ATTR → LT_OO_CUST
  - Initial Load 실행 후 데이터 확인

Step 2 (30분)  TF_OO_LITE 생성
  - Source: LT_OO_VAHDR (as H)
  - INNER JOIN LT_OO_VAITM (as I)
  - LEFT JOIN LT_OO_CUST (as C)
  - Projection: 위 Section 7 SQL 입력
  - WHERE REJ_REASON = ''
  - Target: TT_OO_LITE (Truncate & Insert)
  - 실행 후 TT_OO_LITE 데이터 확인 — AGING_GRP 컬럼 주목!

Step 3 (45분)  AM_OO_LITE 생성
  - Fact Source: V_OO_LITE_F
  - Dimensions: VKORG, SPART, KUNNR, MATNR, AGING_GRP, AUDAT_YM 등
  - BASE Measures: ORD_AMT, ORD_QTY
  - RESTRICTION Measures: CURR_MONTH_AMT, PREV_MONTH_AMT, CURR_YTD_AMT, PREV_YTD_AMT
  - Variables: P_MONTH → RV_CURR_MONTH / RV_PREVIOUS_MONTH (Lookup)
  - 데이터 프리뷰: AGING_GRP별 오더금액 분석
```
