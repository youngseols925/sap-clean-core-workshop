# SAP Clean Core Workshop
## "ERP CBO 프로그램 → SAP Datasphere 이전"

> SAP 파트너 대상 워크샵 시나리오: ERP에 복잡한 CBO Z-Program + Z-Table을 직접 만들고 (AS-IS),
> 동일한 로직을 SAP Datasphere의 Replication Flow + Transformation Flow + Analytic Model로 이전하는 (TO-BE) Clean Core 전환 시연

---

## 📁 프로젝트 구조

```
sap-clean-core-workshop/
│
├── docs/                               # 설계 문서
│   ├── ZSD_WORKSHOP_DESIGN.md          # 아키텍처, Z-Table DDIC 정의
│   ├── DSP_OPENORD_설계.md             # Open Order → DSP 전환 상세 설계
│   └── ZSD_OPENORD_STATUS_개발일지.md  # ABAP 디버깅 히스토리 (20 커밋)
│
├── abap/
│   ├── programs/                       # ABAP 프로그램 소스 (AS-IS)
│   │   ├── ZSD_SELLIN_PERF.abap        # Sell-In 실적현황
│   │   └── ZSD_OPENORD_STATUS.abap     # Open Order 진행현황
│   └── ddic/                           # Z-Table DDIC 정의 (추가 예정)
│
└── datasphere/                         # Datasphere TO-BE 구현
    ├── replication-flow/               # RF JSON (Standard DataSource → DSP)
    ├── local-table/                    # LT JSON (RF 타겟 테이블)
    ├── target-table/                   # TT JSON (TF 결과 저장 테이블)
    ├── transformation-flow/            # TF JSON (조인/계산 로직 — ABAP 대체)
    ├── fact-view/                      # Fact View JSON (ANALYTICAL_FACT)
    └── analytic-model/                 # AM JSON (KPI 분석 모델)
```

---

## 🎯 워크샵 시나리오

### AS-IS: ERP CBO 방식 (문제점 시연)

| 프로그램 | 설명 | 사용 테이블 |
|---------|------|------------|
| `ZSD_SELLIN_PERF` | Sell-In 실적현황 조회 + Z-Table 저장 | VBAK, VBAP, VBFA, VBRK, VBRP, LIPS, KONV, MBEW, KNA1, KNVV, TCURR |
| `ZSD_OPENORD_STATUS` | Open Order 진행현황 조회 + Z-Table 저장 | VBAK, VBAP, VBFA, VBEP, LIPS, VBRP, KONV, KNA1, KNVV, KNKK |

**AS-IS Z-Table (문제의 산물):**
- `ZSDT_SELLIN` — Sell-In 아이템 단위 저장 (ERP 리소스 점유 결과물)
- `ZSDT_OPENORD` — Open Order 아이템 단위 저장 (ERP 리소스 점유 결과물)

> ⚠️ **핵심 문제**: Z-Table을 BW/Datasphere 소스로 재활용 시 악순환 발생
> — Z-Program이 OLTP DB를 직접 조인 → ERP 트랜잭션 성능 저하 → Clean Core 위반

---

### TO-BE: SAP Datasphere Clean Core 방식

**Open Order 시나리오 기준 오브젝트 구성:**

```
[ ERP Standard DataSources ]          [ SAP Datasphere ]

2LIS_11_VAHDR (오더 헤더)   ──RF──→  LT_SD_VAHDR  ─┐
2LIS_11_VAITM (오더 아이템) ──RF──→  LT_SD_VAITM  ─┤
2LIS_11_VASCL (납품 스케줄) ──RF──→  LT_SD_VASCL  ─┼──→ TF_OPENORD ──→ TT_OPENORD
2LIS_12_VCITM (납품 아이템) ──RF──→  LT_SD_DLVITM ─┤    (ABAP 로직)        │
2LIS_13_VDITM (청구 아이템) ──RF──→  LT_SD_BLITM  ─┘                       │
                                                               V_OPENORD_F (Fact View)
                                                                       │
                                                               AM_OPENORD (Analytic Model)
```

| 단계 | 컴포넌트 | 역할 | ABAP 대체 내용 |
|------|---------|------|--------------|
| 추출 | Replication Flow | Standard DataSource → Local Table | Z-Program의 SELECT 10개 테이블 |
| 변환 | Transformation Flow | 조인 + 계산 로직 | ABAP LOOP/IF/CASE → SQL CASE WHEN |
| 저장 | Target Table | TF 결과 저장 | ZSDT_OPENORD 대체 (ERP 아님) |
| 집계 | Fact View | 지표 선언 | @Aggregation.default: SUM |
| 분석 | Analytic Model | KPI + 기간 비교 | Selection Screen → 입력변수 P_MONTH |

---

## 🔑 핵심 메시지

```
AS-IS (ERP CBO 악순환):
Z-Program 개발 → 10개 테이블 직접 조인 → ERP DB 부하
→ Z-Table 저장 → BW/DSP가 Z-Table을 소스로 재사용
→ Z-Object 증가 → Clean Core 위반 → 업그레이드 위험

TO-BE (Clean Core 선순환):
Standard ODP DataSource (2LIS_*) → RF 자동 복제
→ TF에서 ABAP 로직 대체 (SQL CASE WHEN, DAYS_BETWEEN)
→ AM 변수/지표로 분석 고도화
→ ERP Z-Object 제거 → 리소스 해방 → Clean Core 달성
```

---

## 📋 사전 요구사항

- SAP ERP (S/4HANA 또는 ECC) 샌드박스
- SAP Datasphere 테넌트
- ABAP 개발 권한 (SE38, SE11)
- Datasphere Space 관리자 권한

---

## 🗂️ Standard DataSources / CDS Views

### ODP DataSources (BW 방식, Delta 지원)

| DataSource | 설명 | 대체 테이블 |
|------------|------|------------|
| `2LIS_11_VAHDR` | 판매오더 헤더 | VBAK |
| `2LIS_11_VAITM` | 판매오더 아이템 | VBAP |
| `2LIS_11_VASCL` | 납품 스케줄 | VBEP |
| `2LIS_12_VCITM` | 납품 아이템 | LIPS |
| `2LIS_13_VDITM` | 청구 아이템 | VBRP |

### CDS Views (S/4HANA 방식)

| CDS View | 설명 | 대체 테이블 |
|----------|------|------------|
| `C_SalesOrderHeaderDEX_1` | 판매오더 헤더 | VBAK |
| `C_SalesDocumentItemDEX_1` | 판매오더 아이템 | VBAP |
| `C_SalesOrderSchedLineDEX_1` | 납품 스케줄 | VBEP |
| `C_DeliveryDocumentItemDEX_1` | 납품 아이템 | LIPS |
| `C_BillingDocumentItemDEX_1` | 청구 아이템 | VBRP |
| `C_SALESDOCUMENTITEMDEX_1` | 판매오더 아이템 (통합) | VBAK + VBAP |
| `C_BILLINGDOCITEMBASICDEX_1` | 청구 아이템 (통합) | VBRK + VBRP |

---

*Created for SAP Partner Workshop — Clean Core & SAP Datasphere*
