# SAP Clean Core 전환 워크샵 설계 문서
## "ERP CBO 프로그램 → SAP Datasphere 이전"

---

## 1. 워크샵 시나리오 개요

### 배경 및 문제 정의

```
[AS-IS: CBO 방식의 악순환]

고객 요구
    │
    ▼
Z-Program 개발 (ABAP)
    │  VBAK+VBAP+VBFA+VBRK+VBRP+LIPS
    │  MARC+MARA+KNA1+KNVV+KONV+MBEW
    │  복잡한 JOIN/LOOP/READ TABLE
    ▼
Z-Table 저장 (배치 주기적 실행)
    │
    ├─── ERP DB I/O 과부하
    ├─── Dialog Work Process 독점
    ├─── Transport 관리 복잡
    ├─── BW/DSP도 Z-Table을 소스로 사용
    └─── 업그레이드/마이그레이션 장애
         (Clean Core 위반)

[TO-BE: Clean Core + Datasphere 방식]

SAP Standard
    │
    ├── ODP DataSource (2LIS_11_VAHDR, 2LIS_11_VAITM)
    ├── Standard CDS View (C_SALESDOCUMENTITEMDEX_1)
    └── Replication Flow (S4 HANA → DSP)
         │
         ▼
    Datasphere
    ├── Local Tables (복제된 raw data)
    ├── Transformation Flow (복잡한 조인/계산 로직)
    ├── Analytic View (집계/KPI)
    └── Analytic Model (분석 모델 + 변수)
         │
         ▼
    SAC / BEx / 3rd Party BI
```

---

## 2. Z-Table DDIC 정의

> **설계 원칙**: Header/Item 분리 없이 오더 아이템 단위로 단일 테이블에 저장.
> 집계(월별 합산 등)는 SELECT + GROUP BY로 처리.

### 2-1. ZSDT_SELLIN (Sell-In 실적 단일 테이블)

| 필드명 | 타입 | 길이 | 키 | 설명 |
|--------|------|------|----|------|
| MANDT | MANDT | 3 | ✓ | 클라이언트 |
| VBELN | VBELN | 10 | ✓ | 판매오더번호 |
| POSNR | POSNR | 6 | ✓ | 오더 아이템 |
| VKORG | VKORG | 4 | | 영업 조직 |
| KUNNR | KUNNR | 10 | | 고객 코드 |
| MATNR | MATNR | 18 | | 자재 번호 |
| SPART | SPART | 2 | | 제품군 |
| MATKL | MATKL | 9 | | 자재 그룹 |
| GJAHR | GJAHR | 4 | | 회계 연도 |
| SPMON | SPMON | 6 | | 기간(YYYYMM) |
| AUDAT | DATS | 8 | | 오더 생성일 |
| WAERS | WAERS | 5 | | 통화(로컬환산) |
| ORD_QTY | MENGE | 13,3 | | 오더 수량 |
| DLV_QTY | MENGE | 13,3 | | 납품 수량 |
| BIL_QTY | MENGE | 13,3 | | 청구 수량 |
| DLV_RATE | P | 7,2 | | 납품율(%) |
| BIL_RATE | P | 7,2 | | 청구율(%) |
| NETWR | WERTV8 | 15,2 | | 순매출(로컬통화) |
| DISC_AMT | WERTV8 | 15,2 | | 할인금액 |
| COGS | WERTV8 | 15,2 | | 매출원가(MBEW) |
| MARGIN | WERTV8 | 15,2 | | 마진금액 |
| DISC_RATE | P | 7,2 | | 할인율(%) |
| MARGIN_RATE | P | 7,2 | | 마진율(%) |
| PR00_KBETR | KBETR | 11,2 | | 정가 단가(PR00) |
| MWST_RATE | P | 7,2 | | 세율(%) |
| PY_AMT | WERTV8 | 15,2 | | 전년동기 금액 |
| ACHV_RATE | P | 7,2 | | 달성율(%) |
| VBRELN | VBELN | 10 | | 청구 문서번호 |
| VBRELP | POSNR | 6 | | 청구 아이템 |
| LIPS_VL | VBELN | 10 | | 납품 문서번호 |
| ERDAT | DATS | 8 | | 레코드 생성일 |
| ERNAM | ERNAM | 12 | | 생성자 |

### 2-2. ZSDT_OPENORD (Open Order 진행 단일 테이블)

| 필드명 | 타입 | 길이 | 키 | 설명 |
|--------|------|------|----|------|
| MANDT | MANDT | 3 | ✓ | 클라이언트 |
| VBELN | VBELN | 10 | ✓ | 판매오더번호 |
| POSNR | POSNR | 6 | ✓ | 오더 아이템 |
| AUART | AUART | 4 | | 오더 유형 |
| AUDAT | DATS | 8 | | 오더 생성일 |
| AUDAT_YM | SPMON | 6 | | 오더 생성년월 |
| VKORG | VKORG | 4 | | 영업 조직 |
| KUNNR | KUNNR | 10 | | 고객 코드 |
| MATNR | MATNR | 18 | | 자재 번호 |
| SPART | SPART | 2 | | 제품군 |
| MATKL | MATKL | 9 | | 자재 그룹 |
| WAERS | WAERS | 5 | | 통화 |
| ORD_QTY | MENGE | 13,3 | | 오더 수량 |
| CONF_QTY | MENGE | 13,3 | | 납품확정 수량 |
| OPEN_QTY | MENGE | 13,3 | | 미납품 잔량 |
| DLV_QTY | MENGE | 13,3 | | 실납품 수량 |
| BIL_QTY | MENGE | 13,3 | | 청구 수량 |
| DLV_RATE | P | 7,2 | | 납품율(%) |
| BIL_RATE | P | 7,2 | | 청구율(%) |
| ORD_AMT | WERTV8 | 15,2 | | 오더 금액 |
| OPEN_AMT | WERTV8 | 15,2 | | 미결 금액 |
| BIL_AMT | WERTV8 | 15,2 | | 청구 금액 |
| EDATU | DATS | 8 | | 납품 예정일 |
| WBS_DELAY | CHAR | 1 | | 지연여부(X) |
| DELAY_DAYS | INT4 | 4 | | 지연 일수 |
| AGING_GRP | CHAR | 3 | | Aging 구간(030/060/090/90+) |
| DLV_STAT | CHAR | 1 | | 납품상태(A/B/C) |
| BIL_STAT | CHAR | 1 | | 청구상태 |
| CREDIT_EXC | CHAR | 1 | | 신용초과여부 |
| ERDAT | DATS | 8 | | 레코드 생성일 |

---

## 3. Datasphere 전환 매핑

### Sell-In (ZSD_SELLIN_PERF → DSP)

| ABAP 로직 | ERP 테이블 | DSP 대체 |
|-----------|-----------|---------|
| 청구완료 오더 조회 | VBAK+VBAP (GBSTK='C') | `C_SALESDOCUMENTITEMDEX_1` (CDS) |
| 오더→청구 문서 연결 | VBFA (VBTYP_N='M') | RF: `C_BILLINGDOCITEMBASICDEX_1` + TF JOIN |
| 청구금액/수량 | VBRK+VBRP | RF: `C_BILLINGDOCITEMBASICDEX_1` |
| 납품수량/날짜 | LIPS+LIKP | TF에서 조인 처리 |
| 할인율 계산 | KONV (KA00, K004) | `C_SALESDOCITMPRCGELMNTDEX_1` |
| 매출원가(COGS) | MBEW (VERPR/STPRS) | RF: 자재평가 CDS |
| 통화환산 | TCURR + FM | DSP Currency Conversion 함수 |
| 자재 정보 | MARA+MAKT+MARC | RF: `I_PRODUCT`, `I_PRODUCTDESCRIPTION` |
| 고객 정보 | KNA1+KNVV | RF: `I_CUSTOMER` |
| 월별/연별 집계 | LOOP+COLLECT | AM: 기간 변수 + 집계 Measure |
| 마진율 계산 | 내부 계산 | AM: CALCULATION Measure |
| 달성율 계산 | 비교 LOOP | AM: RESTRICTION + 변수 |

### Open Order (ZSD_OPENORD_STATUS → DSP)

| ABAP 로직 | ERP 테이블 | DSP 대체 |
|-----------|-----------|---------|
| 미결 오더 조회 | VBAK (GBSTK≠'C') | `C_SALESDOCUMENTITEMDEX_1` (GBSTK 필터) |
| 납품확정 수량 | VBEP (BMENG) | TF에서 VBEP 데이터 활용 |
| 납품상태 | LIPS+LIKP | RF: `I_OUTBOUNDDELIVERYITEM` CDS |
| 청구상태 | VBRP | RF: `C_BILLINGDOCITEMBASICDEX_1` |
| 지연여부 계산 | SY-DATUM vs EDATU | TF: CASE WHEN TODAY() > EDATU |
| Aging 분석 | DATEDIFF 수동계산 | TF: DAYS_BETWEEN 함수 |
| 신용한도 조회 | KNKK.KLIMK | RF: `I_CUSTOMERCREDITACCOUNT` CDS |
| 오더 Aging 구간 | IF/ELSEIF 분기 | TF: CASE WHEN 구문 |
| 미결금액 계산 | 수량×단가 재계산 | TF: 계산 컬럼 |

---

## 4. 워크샵 진행 순서

```
Step 1 (AS-IS 시연)
├── SE38에서 ZSD_SELLIN_PERF / ZSD_OPENORD_STATUS 임포트
├── Selection Screen에서 조회 실행
├── ST05/SM50으로 DB 부하 확인
└── Z-Table 저장 후 SE16에서 데이터 확인

Step 2 (문제점 분석)
├── 코드 복잡성: 500+ 라인, 다중 테이블 JOIN
├── DB 부하: 수백만 레코드 풀스캔
├── 유지보수: 비즈니스 로직이 ABAP에 하드코딩
└── Clean Core 위반: 업그레이드/RISE 이전 장애

Step 3 (TO-BE 구현)
├── Replication Flow로 Standard CDS View → DSP Local Table
├── Transformation Flow로 동일 조인/계산 로직 구현
├── Analytic Model로 KPI 변수/집계 구현
└── 동일 결과 비교 검증

Step 4 (효과 측정)
├── ERP DB 부하 제거 확인
├── DSP에서 실시간 분석
└── Clean Core 달성 확인
```
