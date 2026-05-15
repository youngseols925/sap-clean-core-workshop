# 워크샵 메뉴얼 — 목차

> SAP Clean Core 전환 워크샵 (1-Day Lite)  
> ERP CBO → SAP Datasphere 실습 가이드

---

## 📚 목차

| 파일 | 내용 | 시간 |
|------|------|------|
| [00_intro.md](00_intro.md) | 전체 구조, 시간표, 사전 준비 | 30분 |
| [01_as-is.md](01_as-is.md) | SE11 Z-Table + SE38 ABAP Report | 150분 |
| [02_transition.md](02_transition.md) | 왜 Clean Core인가? (전환 설명) | 30분 |
| [03_rf.md](03_rf.md) | RF_OO_LITE — Replication Flow | 60분 |
| [04_tf.md](04_tf.md) | TF_OO_LITE — Transformation Flow | 60분 |
| [05_fact-view.md](05_fact-view.md) | V_OO_LITE_F — Fact View | 20분 |
| [06_am.md](06_am.md) | AM_OO_LITE — Analytic Model | 90분 |
| [07_wrapup.md](07_wrapup.md) | AS-IS vs TO-BE 비교 + Q&A | 30분 |

---

## 🗓️ 시간표 요약

```
09:00  오프닝 + 아키텍처 설명
09:30  AS-IS ① SE11: Z-Table 생성
10:30  AS-IS ② SE38: ABAP 작성 + 실행
12:00  🍱 점심
13:00  전환 설명: 왜 Clean Core인가?
13:30  TO-BE ① RF_OO_LITE
14:30  TO-BE ② TF_OO_LITE
15:30  TO-BE ③ Fact View + AM
17:00  마무리 비교 + Q&A
17:30  종료
```

---

## 📎 관련 파일

- ABAP 소스: [`lite/abap/`](../../abap/)
- DSP 오브젝트: [`lite/datasphere/`](../../datasphere/)
- 설계 문서: [`lite/docs/설계.md`](../설계.md)
