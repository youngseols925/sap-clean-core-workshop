# SAP Clean Core Workshop
## "ERP CBO 프로그램 → SAP Datasphere 이전"

> SAP 파트너 대상 워크샵 시나리오: ERP에 복잡한 CBO Z-Program + Z-Table을 직접 만들고 (AS-IS),
> 동일한 로직을 SAP Datasphere의 Transformation Flow + Analytic Model로 이전하는 (TO-BE) Clean Core 전환 시연

---

## 📁 프로젝트 구조

```
sap-clean-core-workshop/
│
├── docs/                          # 설계 문서
│   └── ZSD_WORKSHOP_DESIGN.md     # 아키텍처, DDIC, Datasphere 전환 매핑
│
├── abap/
│   ├── programs/                  # ABAP 프로그램 소스
│   │   ├── ZSD_SELLIN_PERF.abap   # Sell-In 실적현황 (AS-IS)
│   │   └── ZSD_OPENORD_STATUS.abap # Open Order 진행현황 (AS-IS)
│   └── ddic/                      # Z-Table DDIC 정의 (추가 예정)
│
└── datasphere/                    # Datasphere TO-BE 구현
    ├── replication-flow/          # RF JSON (S4 → DSP 추출)
    ├── transformation-flow/       # TF JSON (조인/계산 로직)
    └── analytic-model/            # AM JSON (KPI 분석 모델)
```

---

## 🎯 워크샵 시나리오

### AS-IS: ERP CBO 방식 (문제점 시연)

| 프로그램 | 설명 | 사용 테이블 |
|---------|------|------------|
| `ZSD_SELLIN_PERF` | Sell-In 실적현황 조회 + Z-Table 저장 | VBAK, VBAP, VBFA, VBRK, VBRP, LIPS, KONV, MBEW, KNA1, KNVV, TCURR |
| `ZSD_OPENORD_STATUS` | Open Order 진행현황 조회 + Z-Table 저장 | VBAK, VBAP, VBFA, VBEP, LIPS, VBRP, KONV, KNA1, KNVV, KNKK |

**Z-Table 4개:** `ZSDSI_HEADER`, `ZSDSI_ITEM`, `ZSDOO_HEADER`, `ZSDOO_ITEM`

### TO-BE: SAP Datasphere Clean Core 방식

| 단계 | 컴포넌트 | Standard 대체 |
|------|---------|--------------|
| 추출 | Replication Flow | `C_SALESDOCUMENTITEMDEX_1`, `C_BILLINGDOCITEMBASICDEX_1` 등 |
| 변환 | Transformation Flow | 조인/계산 로직 (CASE WHEN, DAYS_BETWEEN 등) |
| 분석 | Analytic Model | RESTRICTION 변수, 기간 비교, KPI 집계 |

---

## 🔑 핵심 메시지

```
ERP CBO의 악순환:
Z-Program 개발 → ERP DB 부하 → 트랜잭션 지연 → 더 많은 Z-Table → Clean Core 위반

Datasphere Clean Core 선순환:
Standard ODP/CDS → Datasphere 복제 → TF 변환 → AM 분석 → ERP 리소스 해방
```

---

## 📋 사전 요구사항

- SAP ERP (S/4HANA 또는 ECC) 샌드박스
- SAP Datasphere 테넌트
- ABAP 개발 권한 (SE38, SE11)
- Datasphere Space 관리자 권한

---

## 🗂️ 관련 Standard CDS Views

| CDS View | 설명 | 대체 테이블 |
|----------|------|------------|
| `C_SALESDOCUMENTITEMDEX_1` | 판매오더 아이템 | VBAK + VBAP |
| `C_BILLINGDOCITEMBASICDEX_1` | 청구 아이템 | VBRK + VBRP |
| `C_SALESDOCITMPRCGELMNTDEX_1` | 오더 가격 조건 | KONV |
| `C_BILLGDOCITMPRCGELMNTBSCDEX_1` | 청구 가격 조건 | KONV |
| `I_CUSTOMER` | 고객 마스터 | KNA1 |
| `I_PRODUCT` | 자재 마스터 | MARA |

---

*Created for SAP Partner Workshop — Clean Core & SAP Datasphere*
