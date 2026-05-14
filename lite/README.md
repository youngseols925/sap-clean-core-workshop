# Open Order Lite — 1-Day 워크샵 경량화 버전

> Full Version 대비 핵심 개념만 추려서 **하루 안에 완주** 가능한 버전

---

## 경량화 포인트

| | Full Version | **Lite Version** |
|---|---|---|
| ABAP 조회 테이블 | 10개 | **3개** (VBAK, VBAP, KNA1) |
| Z-Table 필드 | 29개 | **13개** |
| 계산 로직 | Aging + 납품율/청구율/신호등 | **Aging 구간만** |
| RF 소스 | 5개 | **2개** |
| TF 조인 | 5-way JOIN | **2-way JOIN** |
| AM 지표 | BASE 8 + CALC 3 + RESTR 4 | **BASE 2 + RESTR 4** |

---

## 디렉토리 구조

```
lite/
├── docs/
│   └── 설계.md                  ← AS-IS/TO-BE 전체 설계, 시간표
├── abap/
│   ├── ddic/
│   │   └── ZSDT_OO_LITE.abap    ← SE11 Z-Table 생성 가이드
│   └── programs/
│       └── ZSD_OO_LITE.abap     ← ABAP Report (VBAK+VBAP+KNA1)
└── datasphere/
    ├── local-table/
    │   ├── LT_OO_VAHDR.json     ← RF 타겟 (오더 헤더)
    │   └── LT_OO_VAITM.json     ← RF 타겟 (오더 아이템)
    ├── replication-flow/
    │   └── RF_OO_LITE.json      ← 2LIS_11_VAHDR + 2LIS_11_VAITM
    ├── target-table/
    │   └── TT_OO_LITE.json      ← TF 결과 저장
    ├── transformation-flow/
    │   └── TF_OO_LITE.json      ← JOIN + Aging CASE WHEN
    ├── fact-view/
    │   └── V_OO_LITE_F.json     ← ANALYTICAL_FACT
    └── analytic-model/
        └── AM_OO_LITE.json      ← P_MONTH 변수 + RESTRICTION 4
```

---

## 워크샵 흐름 요약

```
[오전] AS-IS
  SE11: ZSDT_OO_LITE 생성
  SE38: ZSD_OO_LITE 작성/실행
  → "ABAP + Z-Table의 문제" 토론

[오후] TO-BE
  DSP: RF_OO_LITE (2LIS 직접 복제)
  DSP: TF_OO_LITE (JOIN + Aging SQL)
  DSP: AM_OO_LITE (P_MONTH 변수, 기간비교)
```

**핵심 교육 메시지**: Z-Table을 DSP 소스로 재활용하면 ERP 의존성이 사라지지 않습니다.
Standard DataSource(2LIS_11_*) → ODP → DSP가 진정한 Clean Core 전환입니다.
