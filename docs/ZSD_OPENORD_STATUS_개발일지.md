# ZSD_OPENORD_STATUS 개발 & 디버깅 전과정 기록

> 작성일: 2026-05-15  
> 작성자: Kai (AI Assistant)  
> 대상: youngseols925/sap-clean-core-workshop

---

## 1. 프로그램 개요

| 항목 | 내용 |
|------|------|
| 프로그램명 | `ZSD_OPENORD_STATUS` |
| 목적 | SAP ERP Open Order 진행현황 조회 및 Z-Table 저장 |
| 용도 | BDC 워크샵 시연 — ERP CBO → Datasphere 마이그레이션 예시 |
| 라인수 | 초기 837줄 → 최종 ~894줄 |
| GitHub | `youngseols925/sap-clean-core-workshop/abap/programs/ZSD_OPENORD_STATUS.abap` |

---

## 2. 전체 아키텍처

```
[ SAP S/4HANA ]
    VBAK (오더헤더) + VBAP (아이템) + VBEP (스케줄)
  + VBFA (문서흐름) + LIPS (납품) + VBRP (청구)
  + KONV (가격조건) + KNA1 (고객) + KNVV (영업) + KNKK (신용)
         ↓
  ZSD_OPENORD_STATUS (ABAP 프로그램)
  - 10개 테이블 조인 및 집계
  - Aging 분석 (030/060/090/90+)
  - 신호등 로직 (G/Y/R)
  - 납품율/청구율 계산
         ↓
  ZSDT_OPENORD (Z-Table 저장)
         ↓
  [ SAP Datasphere ]
  RF → TF → AM
```

---

## 3. 초기 소스 현황 (최초 커밋: bf05c1a)

- **837줄** ABAP 프로그램 생성
- Selection Screen: 조회 조건 + 상태 필터 + 저장 옵션
- 10개 테이블 STEP 방식으로 순차 조회
- ALV Grid 출력
- ZSDT_OPENORD Z-Table INSERT 로직 포함

**초기 설계 의도는 좋았으나**, SAP 실제 DDIC를 참조하지 않고 생성된 코드라 다수의 필드명 오류 존재.

---

## 4. 디버깅 이력 (커밋별 상세)

### Phase 1 — 타입 정의 누락 수정

#### `977d777` | 2026-05-14 22:53
**문제:** SE38 활성화 시 6개 타입 미정의 오류  
**원인:** `ty_vbfa_sel`, `ty_lips_sel`, `ty_vbrp_sel`, `ty_konv_sel`, `ty_kna1_sel`, `ty_knvv_sel` 타입 선언 누락  
**수정:** 6개 타입 블록 inline 추가

---

### Phase 2 — KONV 테이블 필드명 오류

#### `6666de4` | 2026-05-14 22:55
**문제:** `loevm_ko` → `loekz` 로 수정 시도  
**원인:** KONV 테이블의 삭제 플래그 필드명을 `loevm_ko`로 잘못 생성  
**수정:** `loevm_ko` → `loekz` 변경

#### `dbe6969` | 2026-05-14 22:57
**문제:** `loekz`도 KONV 테이블에 존재하지 않음  
**교훈:** KONV 테이블에는 레코드 삭제 플래그 필드가 없음  
**수정:** `loekz` 필드 완전 제거 (타입 선언 + SELECT 컬럼 + WHERE 조건 모두)

---

### Phase 3 — SELECT 마침표 누락 및 전수검사

#### `4547874` | 2026-05-14 22:57
**문제:** `f2_get_konv` FORM의 SELECT 마지막 마침표 누락  
**발견:** 전수 검사 중 발견  
**수정:** 마침표 추가

---

### Phase 4 — SELECT-OPTIONS DDIC 참조 오류

#### `22ec08e` | 2026-05-14 22:59
**문제:** `FIELD "VBAK-AUDAT" is unknown` 에러  
**원인:** `gt_vbak TYPE STANDARD TABLE OF ty_openord` 변수명이 `VBAK` DDIC와 충돌  
**수정:** `gt_vbak` → `gt_vbak_unused` 로 이름 변경

#### `0ce2951` | 2026-05-14 23:01
**문제:** 이름 변경으로도 여전히 같은 에러  
**수정:** `gt_vbak_unused` 변수 선언 자체를 완전 삭제 (어차피 미사용 변수)

#### `a00a3d7` | 2026-05-14 23:06
**문제:** `s_audat FOR vbak-audat` 등 SELECT-OPTIONS의 DDIC 참조 오류  
**원인:** 이 시스템에서 일부 DDIC 테이블 참조가 SELECT-OPTIONS에서 실패  
**수정:** `FOR vbak-*` / `FOR vbap-*` → `FOR sy-datum` / `FOR sy-mandt` 로 교체

---

### Phase 5 — 실제 SAP DDIC 확인 (RFC 직접 조회)

> **전환점:** 추측으로 코드를 수정하는 것의 한계를 인식.  
> VPN 연결 후 node-rfc로 실제 S/4HANA DDIC를 직접 조회.

**시스템 정보:**
- Host: `cloudl000373.internal.sde.cloud.sap`
- SysNr: `00`, Client: `400`
- RFC 함수: `DDIF_FIELDINFO_GET`
- 조회 대상: `VBAK`, `VBAP`, `VBFA`, `VBEP`, `LIPS`, `VBRP`, `KONV`, `KNA1`, `KNVV`, `KNKK`

**발견된 실제 필드명 (주요):**

| 테이블 | 잘못된 필드 | 실제 필드 | 비고 |
|--------|-----------|---------|------|
| VBAK | `WAERS` | `WAERK` | 통화키 필드명 다름 |
| VBAK | `GBSTK` | ❌ 없음 | 전체 처리 상태 |
| VBAP | `MTART` | ❌ 없음 | 자재 유형 |
| VBAP | `GBSTA` | ❌ 없음 | 아이템 처리 상태 |
| KNKK | `UVALL` | ❌ 없음 | 전체 미결금액 |
| KONV | `LOEVM_KO` / `LOEKZ` | ❌ 없음 | 삭제 플래그 없음 |

#### `562909a` | 2026-05-14 23:11
**수정:**
- VBAK SELECT: `gbstk` 제거, `waers` → `waerk` 수정
- VBAP SELECT: `gbsta`, `mtart` 제거
- KNKK SELECT: `uvall` 제거
- `CASE WHEN 0 TO 30` → `IF ... ELSEIF` 로 교체 (ABAP CASE는 범위 비교 불가)

#### `b2dcda6` | 2026-05-14 23:21
**수정:**
- `ty_vbak2`: `gbstk` 타입 선언 제거, `waerk` 추가
- `ty_vbap2`: `gbsta` 타입 선언 제거
- merge_data: `ls_vbak-gbstk` 참조 제거
- `ls_vbap-waers` → `ls_vbak-waerk` 수정

---

### Phase 6 — Selection Screen 타입 오류

#### `8e24aef` | 2026-05-14 23:26
**문제:**
- `WAERK` / `NETWR` 타입 불일치 (CURR+CUKY 쌍 매핑 문제)
- `VBAP.WAERS` unknown
- `ZSDT_OPENORD` 타입 unknown (Z-Table 미생성)

**수정:**
- `ty_vbak2`에서 `waerk` 완전 제거 (CURR/CUKY 쌍 문제 해결)
- VBAP SELECT에서 `waers` 제거 (실제 DDIC에 없음)
- `lt_openord_db` → `ty_openord` 사용, DB 조작 주석처리

#### `f9f1a07` | 2026-05-14 23:30
**수정:**
- `ty_vbak2`: `waerk` + `CURR/CUKY` 완전 제거
- `ls_openord_db-mandt/erdat/ernam` 제거 (ty_openord에 없는 필드)
- `waers` = `'KRW'` 하드코딩

---

### Phase 7 — Selection Screen 블록 타이틀 오류

#### `ddf3369` | 2026-05-14 23:33
**문제:** `WITH FRAME TITLE '조회 조건'` — 한국어 문자열 인코딩 오류  
**수정:** 블록 타이틀 한국어 직접 입력 시도 (실패)

#### `4c71cc7` | 2026-05-15 00:01
**추가 기능:** `p_nodisp` 파라미터 추가 (화면 출력 없이 저장만 하는 옵션)

#### `f13fe92` → `1a47d34` → `f052dc2` | 2026-05-15 00:02~07
**문제 연속:**
1. 한국어 문자열 리터럴 → INITIALIZATION에서 TEXT 심볼 대입 불가
2. `'Search Criteria'` → 8자 초과 오류
3. `'CRITERIA'` → 여전히 블록 타이틀 문자열 리터럴 불가

**최종 해결:** `WITH FRAME TITLE TEXT-001` 사용 + SE38 Text Elements에서 직접 입력

**교훈:** SAP SELECTION-SCREEN `FRAME TITLE`은 **반드시 TEXT 심볼**(`TEXT-nnn`)만 사용 가능. 문자열 리터럴 불가.

---

### Phase 8 — Unicode 호환성 오류

#### `d8538eb` | 2026-05-15 00:04
**문제:** `LT_OPENORD_DB`의 Unicode 불호환 (CURR/QUAN/INT 타입)  
**원인:** `lt_openord_db TYPE STANDARD TABLE OF ty_openord` → `ty_openord` 안에 CURR/QUAN 타입 필드 포함

**수정 시도:** `dlv_rate/bil_rate` → `numc3` 변경 (부분 해결)

#### `97986e4` | 2026-05-15 00:08
**시도:** `ty_openord_db` 별도 타입 생성 (CHAR 기반) — 과도한 변경으로 오류 유발

#### `b3cd167` | 2026-05-15 00:11
**결정:** 에러 없던 안정 버전(`f9f1a07`)으로 롤백 후 최소 변경만 적용

---

### Phase 9 — Z-Table 저장 기능 완성

#### `b6f5943` | 2026-05-15 00:21
**문제:** ZSDT_OPENORD 건수 0건  
**원인:** 롤백 시 INSERT/DELETE 주석이 포함된 버전으로 복원됨  
**수정:** 주석 해제

#### `c0696e6` | 2026-05-15 00:23
**문제:** `lt_openord_db TYPE STANDARD TABLE OF ty_openord` → Unicode 불호환  
**최종 해결:** `TYPE STANDARD TABLE OF zsdt_openord` 로 변경  
**이유:** `ZSDT_OPENORD` 테이블은 SE11에서 DEC 타입으로 정의 → Unicode 호환

#### `3ad4a76` | 2026-05-15 00:24
**문제:** `DLV_RATE`, `BIL_RATE` 필드가 ZSDT_OPENORD 테이블에 없음  
**수정:** `ls_openord_db-dlv_rate/bil_rate` 대입 라인 제거

---

## 5. 최종 완성 기능 목록

### Selection Screen
| 파라미터 | 설명 | 비고 |
|---------|------|------|
| `S_AUDAT` | 오더 생성일 (필수) | `FOR sy-datum` |
| `S_VKORG` | 영업 조직 | |
| `S_VTWEG` | 유통 경로 | |
| `S_SPART` | 제품군 | |
| `S_KUNNR` | 고객 코드 | |
| `S_MATNR` | 자재 번호 | |
| `S_MATKL` | 자재 그룹 | |
| `S_AUART` | 오더 유형 | |
| `P_OPEN` | 미납품 포함 | Default: X |
| `P_PART` | 부분납품 포함 | Default: X |
| `P_DELAY` | 납품 지연 건만 | |
| `P_CREDIT` | 신용 초과 건만 | |
| `P_KKBER` | 신용관리영역 | Default: 1000 |
| `P_SAVE` | Z-Table 저장 | |
| `P_DELOLD` | 기존 데이터 삭제 후 저장 | Default: X |
| `P_NODISP` | **화면 출력 안함 (저장 전용)** | 🆕 신규 |

### 조회 테이블 (10개)
| STEP | 테이블 | 내용 |
|------|--------|------|
| 1 | VBAK | 오더 헤더 (미완료만) |
| 2 | VBAP | 오더 아이템 |
| 3 | VBEP | 납품 스케줄 (확정수량/예정일) |
| 4 | VBFA | 문서 흐름 |
| 5 | LIPS | 납품 아이템 |
| 6 | VBRP | 청구 아이템 |
| 7 | KONV | 가격 조건 (PR00) |
| 8 | KNA1 | 고객 마스터 |
| 9 | KNVV | 고객 영업 데이터 |
| 10 | KNKK | 신용 한도 |

### 계산 로직
- **Aging 분석**: 오더생성일 기준 030/060/090/90+ 구간
- **납품율**: 납품수량 / 오더수량 × 100
- **청구율**: 청구수량 / 오더수량 × 100
- **신용 초과**: AR잔액 + 특수부채 > 신용한도
- **신호등**: G(정상) / Y(경고) / R(위험)

### ALV 출력 컬럼 (주요)
신호등, 오더번호, 아이템, 오더유형, 생성일, Aging그룹, 영업조직, 고객, 자재, 오더수량, 납품수량, 청구수량, 오더금액, 미결금액, 납품예정일, 납품지연, 신용초과 등

---

## 6. 핵심 교훈 및 ABAP 개발 규칙

### ❌ 하지 말아야 할 것
1. **DDIC 확인 없이 필드명 추측 금지** — 특히 KONV, KNKK 같은 테이블
2. **SELECTION-SCREEN FRAME TITLE에 문자열 리터럴 사용 금지** — TEXT 심볼만 가능
3. **CASE WHEN 0 TO 30 범위 비교 금지** — ABAP CASE는 범위 비교 불가, IF 사용
4. **LOOP 안에 SELECT 금지** — N+1 성능 문제
5. **CURR/QUAN 타입 필드를 DB 저장용 내부 테이블에 직접 사용 금지** — Unicode 불호환

### ✅ 해야 할 것
1. **DDIF_FIELDINFO_GET RFC로 실제 DDIC 먼저 확인**
2. **SELECT-OPTIONS는 `FOR sy-datum` / `FOR sy-mandt` 사용**
3. **DB 저장용 타입은 테이블 자체 타입 사용** (`TYPE STANDARD TABLE OF zsdt_openord`)
4. **범위 비교는 IF ... ELSEIF 사용**
5. **데이터 볼륨 고려 — 조회 기간 좁게 테스트**

### SAP 테이블 실제 DDIC 메모
| 잘못 알고 있던 것 | 실제 |
|----------------|------|
| `VBAK-WAERS` | `VBAK-WAERK` (통화키) |
| `VBAK-GBSTK` | 없음 |
| `VBAP-MTART` | 없음 (MARA에 있음) |
| `VBAP-GBSTA` | 없음 |
| `KNKK-UVALL` | 없음 |
| `KONV-LOEKZ` | 없음 |

---

## 7. Z-Table (ZSDT_OPENORD) 구조

SE11에서 직접 생성 필요:

| 필드 | Key | 타입 | 비고 |
|------|-----|------|------|
| MANDT | ✅ | MANDT | |
| VBELN | ✅ | VBELN_VA | |
| POSNR | ✅ | POSNR_VA | |
| AUART | | AUART | |
| AUDAT | | AUDAT | |
| AUDAT_YM | | SPMON | |
| VKORG | | VKORG | |
| VTWEG | | VTWEG | |
| SPART | | SPART | |
| KUNNR | | KUNNR | |
| MATNR | | MATNR | |
| MATKL | | MATKL | |
| WAERS | | WAERS | |
| ORD_QTY | | DEC(13,3) | |
| CONF_QTY | | DEC(13,3) | |
| OPEN_QTY | | DEC(13,3) | |
| DLV_QTY | | DEC(13,3) | |
| BIL_QTY | | DEC(13,3) | |
| ORD_AMT | | DEC(15,2) | |
| OPEN_AMT | | DEC(15,2) | |
| BIL_AMT | | DEC(15,2) | |
| EDATU | | EDATU | |
| WBS_DELAY | | XFELD | |
| DELAY_DAYS | | INT4 | |
| AGING_GRP | | CHAR3 | |
| DLV_STAT | | CHAR1 | |
| BIL_STAT | | CHAR1 | |
| CREDIT_EXC | | XFELD | |
| TRAFFIC | | CHAR1 | |

> Technical Settings: Data Class `APPL0`, Size Category `1`

---

## 8. 커밋 히스토리 요약

| 시각 | 커밋 | 내용 |
|------|------|------|
| 22:26 | `180dddb` | 최초 커밋 |
| 22:40 | `bf05c1a` | Z-Table 통합 |
| 22:53 | `977d777` | 6개 타입 누락 수정 |
| 22:55 | `6666de4` | KONV 필드명 수정 시도 |
| 22:57 | `dbe6969` | KONV loekz 완전 제거 |
| 22:57 | `4547874` | SELECT 마침표 누락 수정 |
| 22:59 | `22ec08e` | gt_vbak 변수명 변경 |
| 23:01 | `0ce2951` | gt_vbak 완전 삭제 |
| 23:06 | `a00a3d7` | SELECT-OPTIONS sy-mandt로 변경 |
| 23:11 | `562909a` | VBAK/VBAP/KNKK 잘못된 필드 제거 |
| 23:21 | `b2dcda6` | **RFC DDIC 직접 확인 기반 수정** |
| 23:26 | `8e24aef` | WAERK/NETWR/ZSDT_OPENORD 타입 수정 |
| 23:30 | `f9f1a07` | 안정 버전 (에러 0) |
| 23:33 | `ddf3369` | UI 한국어 블록 타이틀 시도 |
| 00:01 | `4c71cc7` | p_nodisp 기능 추가 |
| 00:04 | `d8538eb` | Unicode 호환 타입 수정 |
| 00:11 | `b3cd167` | 안정 버전 복원 + p_nodisp만 추가 |
| 00:21 | `b6f5943` | INSERT 주석 해제 |
| 00:23 | `c0696e6` | lt_openord_db → TYPE zsdt_openord |
| 00:24 | `3ad4a76` | dlv_rate/bil_rate 대입 제거 |

---

*총 20개 커밋, 약 2시간의 디버깅 과정*
