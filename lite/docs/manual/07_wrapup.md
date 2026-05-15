# 마무리 — AS-IS vs TO-BE 비교 & Q&A
> **소요시간**: 30분

---

## 8-1. 오늘 만든 것 전체 정리

```
[ AS-IS — 오전에 만든 것 ]

ERP (VBAK, VBAP)
    ↓ SE38: ZSD_OO_LITE (ABAP 100+ 줄)
ZSDT_OO_LITE (Z-Table) ← ERP DB에 직접 저장


[ TO-BE — 오후에 만든 것 ]

ERP ODP Extractor
  2LIS_11_VAHDR ──┐
  2LIS_11_VAITM ──┼─► RF_OO_LITE ─► LT_OO_VAHDR / LT_OO_VAITM / LT_OO_CUST
  0CUSTOMER_ATTR──┘
                          ↓
                   TF_OO_LITE (SQL JOIN + CASE WHEN Aging)
                          ↓
                   TT_OO_LITE → V_OO_LITE_F → AM_OO_LITE
                          ↓
                   당월/전월/YTD 자동 비교 분석 📊
```

---

## 8-2. AS-IS vs TO-BE 핵심 비교

| 항목 | AS-IS (CBO) | TO-BE (Clean Core) |
|------|-------------|-------------------|
| **코드량** | ABAP 100+ 줄 | ABAP 없음 |
| **ERP 부하** | 매일 배치 대량 SELECT | Delta: 변경분만 복제 |
| **데이터 신선도** | 배치 실행 시점 기준 | 항상 오늘 기준 Aging |
| **전월 비교** | 별도 ABAP 개발 필요 | AM에서 P_MONTH 한 번 |
| **S/4 업그레이드** | Z코드 재개발 필요 | 표준 DataSource 유지 |
| **RISE 이전** | Z-Table 마이그레이션 별도 | 바로 이전 가능 |
| **개발 시간** | 3~5일 | 반나절 |

---

## 8-3. 오늘 적용한 Clean Core 원칙

1. **표준 DataSource 사용** — VBAK/VBAP 직접 SELECT 대신 2LIS_11_VAHDR/VAITM
2. **비즈니스 로직을 DSP로** — Aging 계산이 ERP→DSP로 이동
3. **Z-Table 제거** — ERP DB에 데이터 직접 저장하지 않음
4. **확장 대신 표준** — ABAP CBO 대신 SAP Datasphere 표준 파이프라인

---

## 8-4. 다음 단계 (심화 과정 안내)

| 주제 | 내용 |
|------|------|
| **BW 오브젝트 마이그레이션** | InfoObject, DSO, Transformation 자동 마이그레이션 |
| **SAP Analytics Cloud** | AM_OO_LITE를 SAC Story로 시각화 |
| **Delta 복제 운영** | RF Delta Load 스케줄링, 오류 처리 |
| **Dimension View** | 고객/자재 마스터를 별도 Dimension으로 관리 |

---

## 8-5. Q&A 자주 나오는 질문

**Q. 2LIS DataSource가 ERP에서 활성화되어 있어야 하나요?**  
A. 네. ERP에서 `RSA5` 트랜잭션으로 DataSource 활성화가 필요합니다.  
오늘 실습 환경에는 이미 활성화되어 있습니다.

**Q. Delta 복제는 얼마나 자주 실행되나요?**  
A. RF 스케줄 설정에 따라 다릅니다. 15분, 1시간, 매일 등 선택 가능합니다.

**Q. Z-Table에 이미 데이터가 있는데 마이그레이션 경로는?**  
A. Z-Table 데이터를 TT_OO_LITE로 일괄 마이그레이션한 후 RF Initial Load로 대체합니다.  
상세 방법은 심화 과정에서 다룹니다.

**Q. AM_OO_LITE를 SAC에서 바로 쓸 수 있나요?**  
A. 네. DSP에서 AM을 배포하면 SAC Live Connection으로 바로 사용 가능합니다.

---

## 8-6. 실습 파일 다운로드

- **ABAP 소스**: https://github.com/youngseols925/sap-clean-core-workshop
  - `lite/abap/ddic/ZSDT_OO_LITE.abap` — Z-Table 필드 정의
  - `lite/abap/programs/ZSD_OO_LITE.abap` — ABAP Report 소스
- **DSP RF JSON**: `lite/datasphere/RF_OO_LITE.json`
- **설계 문서**: `lite/docs/설계.md`
