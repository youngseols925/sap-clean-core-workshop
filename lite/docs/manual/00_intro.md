# SAP Clean Core 전환 워크샵
## ERP CBO → SAP Datasphere 실습 가이드

> **대상**: SAP 파트너 개발자, 컨설턴트  
> **소요시간**: 1일 (9:00 ~ 17:30)  
> **레벨**: 초급 — SAP GUI와 DSP 기본 접속만 가능하면 OK

---

## 📋 이 워크샵에서 배우는 것

| 세션 | 무엇을 만드는가 | 핵심 개념 |
|------|--------------|-----------|
| **오전 AS-IS** | Z-Table + ABAP Report | CBO 개발의 문제점 직접 체험 |
| **전환 설명** | — | 왜 Clean Core인가? |
| **오후 TO-BE** | RF → TF → AM | Standard DataSource + DSP 파이프라인 |

---

## 🏗️ 전체 아키텍처

```
[ AS-IS: 기존 CBO 방식 ]

  ERP DB (VBAK / VBAP)
       │
       ▼ ZSD_OO_LITE (ABAP Report)
       │  ① VBAK 조회 → ② VBAP 조회 → ③ Aging 계산
       ▼
  ZSDT_OO_LITE (Z-Table)    ← ERP DB에 직접 쓰기
       ↓
  (DSP가 이걸 소스로 쓰면? → Clean Core 위반!)


[ TO-BE: SAP Clean Core 방식 ]

  ERP ODP Extractor
  2LIS_11_VAHDR ──┐
  2LIS_11_VAITM ──┼──► RF_OO_LITE ──► LT_OO_VAHDR / LT_OO_VAITM
  0CUSTOMER_ATTR──┘                    LT_OO_CUST
                                            │
                                    TF_OO_LITE (SQL JOIN + Aging 계산)
                                            │
                                    TT_OO_LITE (Target Table)
                                            │
                                    V_OO_LITE_F (Fact View)
                                            │
                                    AM_OO_LITE (Analytic Model)
                                    ← 당월/전월/YTD 비교 분석 가능!
```

---

## 💻 실습 환경

| 항목 | 값 |
|------|----|
| ERP Host | `s4-2020.sapexperienceacademy.com` |
| ERP System | System **00** |
| DSP URL | `https://poc-dsp-1.ap12.hcs.cloud.sap` |
| DSP Space | `WORKSHOP` |

---

## ⏰ 시간표

| 시간 | 세션 | 내용 |
|------|------|------|
| 09:00 – 09:30 | **Intro** | Clean Core 개념, 전체 아키텍처 설명 |
| 09:30 – 10:30 | **AS-IS ①** | SE11: ZSDT_OO_LITE Z-Table 생성 |
| 10:30 – 12:00 | **AS-IS ②** | SE38: ZSD_OO_LITE ABAP 작성 + 실행 |
| 12:00 – 13:00 | — | 🍱 점심 |
| 13:00 – 13:30 | **전환 설명** | Z-Table 소스의 문제 → Standard DataSource 소개 |
| 13:30 – 14:30 | **TO-BE ①** | DSP: RF_OO_LITE (Replication Flow) |
| 14:30 – 15:30 | **TO-BE ②** | DSP: TF_OO_LITE (Transformation Flow) |
| 15:30 – 17:00 | **TO-BE ③** | DSP: V_OO_LITE_F + AM_OO_LITE |
| 17:00 – 17:30 | **정리** | AS-IS vs TO-BE 비교, Q&A |

---

## ✅ 사전 준비 체크리스트

실습 시작 전 아래 항목을 확인하세요.

- [ ] SAP GUI 설치 및 ERP 접속 테스트
- [ ] DSP 테넌트 로그인 가능 확인
- [ ] DSP Space `WORKSHOP` 접근 권한 확인
- [ ] SE11 / SE38 트랜잭션 실행 가능 확인
- [ ] Message Class `ZMSD` 존재 확인 (없으면 SE91에서 생성)
