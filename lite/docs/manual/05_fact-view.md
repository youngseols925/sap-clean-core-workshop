# TO-BE 세션 ③ — Fact View (V_OO_LITE_F)
> **소요시간**: 20분  
> **목표**: TT_OO_LITE를 Analytic Model이 읽을 수 있는 Fact View로 감싼다

---

## 6-1. Fact View란?

```
TT_OO_LITE (Target Table)
      ↓
V_OO_LITE_F (Fact View)   ← "AM이 읽는 창구"
      ↓
AM_OO_LITE (Analytic Model)
```

> 💬 **왜 Fact View가 필요한가?**  
> AM은 ANALYTICAL_FACT 패턴이 설정된 View만 소스로 사용합니다.  
> 테이블을 직접 AM에 연결할 수 없으므로, 얇은 View 한 장이 필요합니다.
>
> 또한 이 단계에서 **타입 변환**을 처리합니다.  
> 예: `AUDAT_YM` (NUMC 6자리) → AM의 시간 필터가 인식할 수 있는 `String(6)` 형태로 정제

---

## 6-2. 신규 Graphical View 생성

1. 좌측 메뉴 **Data Layer** → **Graphical Views** 클릭
2. **New** 버튼 클릭
3. 이름 입력: `V_OO_LITE_F`
4. **Create** 클릭

```
[📸 스크린샷: Graphical View 신규 생성]
```

---

## 6-3. Semantic Usage 설정

우측 속성 패널 → **Semantic Usage** 드롭다운:

- `Fact` 선택

> 💡 이 설정이 핵심입니다.  
> `Fact`를 선택해야 AM이 이 View를 소스로 인식합니다.

```
[📸 스크린샷: Semantic Usage = Fact 선택]
```

---

## 6-4. Source 연결 — TT_OO_LITE

1. 캔버스에 **Source** 노드 추가
2. `TT_OO_LITE` 검색 후 선택

```
[📸 스크린샷: Source = TT_OO_LITE 연결]
```

---

## 6-5. 출력 컬럼 설정 (Projection)

**Source** 노드 클릭 → **Columns** 탭에서 아래 컬럼 모두 포함:

| 컬럼명 | 역할 | 유형 |
|--------|------|------|
| `VBELN` | 오더 번호 | Attribute |
| `POSNR` | 아이템 번호 | Attribute |
| `AUDAT` | 오더 일자 | Attribute |
| `AUDAT_YM` | **시간 차원** (월별 분석 기준) | Attribute |
| `VKORG` | 영업 조직 | Attribute |
| `SPART` | 제품군 | Attribute |
| `KUNNR` | 고객 코드 | Attribute |
| `MATNR` | 자재 번호 | Attribute |
| `MATKL` | 자재 그룹 | Attribute |
| `WAERK` | 통화 | Attribute |
| `ELAPSED_DAYS` | 경과일수 | Attribute |
| `AGING_GRP` | Aging 구간 | Attribute |
| `ORD_QTY` | **오더 수량** | **Measure** |
| `ORD_AMT` | **오더 금액** | **Measure** |

---

## 6-6. Measure 속성 설정 — 핵심!

`ORD_QTY`, `ORD_AMT` 두 필드는 반드시 **Measure**로 설정:

1. `ORD_AMT` 컬럼 클릭
2. 우측 패널 → **Semantic Type**: `Measure` 선택
3. **Aggregation**: `SUM` 선택

4. 동일하게 `ORD_QTY` 도 `Measure` + `SUM` 설정

```
[📸 스크린샷: ORD_AMT — Semantic Type = Measure, Aggregation = SUM]
```

> ⚠️ **이걸 빠뜨리면** AM에서 지표로 인식이 안 됩니다!

---

## 6-7. AUDAT_YM 연결 — 시간 차원 설정

1. `AUDAT_YM` 컬럼 클릭
2. 우측 패널 → **Semantic Type**: `Date (Month)` 선택

> 💡 이 설정으로 AM에서 `AUDAT_YM`을 기준으로  
> "당월 / 전월 / 올해 누계" 필터 변수가 동작합니다.

```
[📸 스크린샷: AUDAT_YM — Semantic Type = Date (Month)]
```

---

## 6-8. 저장 및 Deploy

1. **Save** 클릭
2. **Deploy** 클릭 → `Deployed` 상태 확인
3. **Data Preview** → 데이터 확인

```
[📸 스크린샷: V_OO_LITE_F Deploy 완료 + 데이터 프리뷰]
```
