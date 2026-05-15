# 전환 설명 — 왜 Clean Core인가?
> **소요시간**: 30분 (점심 후 집중력 회복 세션)  
> **목표**: Z-Table 패턴의 문제점을 이해하고, TO-BE 방향을 납득한다

---

## 3-1. 오전 실습 복기

오전에 만든 것을 다시 보겠습니다.

```
ZSD_OO_LITE (ABAP)
  └─ VBAK / VBAP 직접 SELECT
  └─ ERP에서 Aging 계산
  └─ ZSDT_OO_LITE (Z-Table) 에 저장
         ↓
  (만약 DSP에서 이 Z-Table을 소스로 쓴다면?)
  DSP → RF → ZSDT_OO_LITE → Local Table → AM
```

**❓ 퀴즈**: 이 구조에서 문제가 생기는 상황은?

---

## 3-2. Z-Table 패턴의 3가지 문제

### ❌ 문제 1: 데이터 신뢰성

```
ERP 배치잡 실패 (네트워크 오류, 잠금 등)
        ↓
ZSDT_OO_LITE 업데이트 안 됨
        ↓
DSP 데이터 = 어제 데이터
        ↓
사용자: "왜 오늘 오더가 안 보여요?" 😡
```

### ❌ 문제 2: ERP 부하 제거 안 됨

```
원래 목적: "ERP 조회 부하를 줄이기 위해 DSP로 이전"

현실:
  ERP 배치잡이 여전히 매일 수백만 건 SELECT
  + DSP도 Z-Table RF 실행
  = 부하가 줄기는커녕 늘어남 😱
```

### ❌ 문제 3: SAP 업그레이드/RISE 장애

```
S/4HANA Cloud (RISE) 이전 시:
  ✅ Standard 테이블(VBAK, VBAP 등) → 자동 마이그레이션
  ❌ Z-Table(ZSDT_OO_LITE) → 별도 마이그레이션 필요
  ❌ Z-Program(ZSD_OO_LITE) → 전면 재개발 필요
```

---

## 3-3. Clean Core의 해법

> **핵심 원칙**: "ERP DB를 직접 건드리지 말고, SAP 표준 채널(ODP)을 통해 데이터를 꺼내라"

| 항목 | AS-IS (CBO) | TO-BE (Clean Core) |
|------|-------------|-------------------|
| 데이터 소스 | Z-Table | SAP Standard DataSource |
| ERP 부하 | 배치잡 매일 실행 | Delta 복제 (변경분만) |
| 데이터 신뢰성 | 배치 성공 여부에 종속 | SAP ODP 표준 메커니즘 |
| 업그레이드 영향 | Z 코드 전면 재개발 | 표준 DataSource 유지 |
| Aging 계산 위치 | ERP (ABAP) | DSP TF (HANA SQL) |

---

## 3-4. Standard DataSource란?

SAP가 표준으로 제공하는 "검증된 데이터 추출 채널"입니다.

```
VBAK (헤더 테이블) → 2LIS_11_VAHDR DataSource
VBAP (아이템 테이블) → 2LIS_11_VAITM DataSource
KNA1 (고객 마스터) → 0CUSTOMER_ATTR DataSource
```

> 💬 **핵심**: Z-Table을 만들 필요가 없습니다.  
> SAP가 이미 만들어 놓은 길을 쓰면 됩니다.

---

## 3-5. 오후 실습 미리보기

```
오후에 만들 것:

RF_OO_LITE ──► LT_OO_VAHDR  (2LIS_11_VAHDR 복제본)
           ──► LT_OO_VAITM  (2LIS_11_VAITM 복제본)
           ──► LT_OO_CUST   (0CUSTOMER_ATTR 복제본)
                    ↓
           TF_OO_LITE (SQL로 JOIN + Aging 계산)
                    ↓
           TT_OO_LITE → V_OO_LITE_F → AM_OO_LITE
                    ↓
           당월/전월/올해누계/작년누계 비교 분석! 📊
```

> 💬 **마무리 멘트**:  
> "오전에 ABAP으로 힘들게 만든 것을 오후에 DSP에서 클릭 몇 번으로 만들어봅니다.  
> 그리고 Aging 분석에서 끝나지 않고 전월 비교, 작년 동기 비교까지 자동으로 됩니다."
