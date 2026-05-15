# Lesson 1 · SAP Data Product Generator

> ⏱ 10분 | Guided Tour (탐색만 — 직접 생성 불필요)

## 학습 목표

BW Cockpit의 **Data Subscription** 기능을 사용하여  
SAP BW InfoProvider 데이터를 SAP Datasphere 테이블로 복제하는 방법을 이해합니다.

---

## 개념 이해

### Data Product Generator란?

SAP BW 시스템의 데이터를 **SAP Datasphere Object Store**로 **푸시(Push)**하는 메커니즘입니다.

```
SAP BW                           SAP Datasphere
┌─────────────────┐              ┌──────────────────────────┐
│  BW DataStore   │  Data        │  BW Ingestion Space      │
│  (ADSO)         │─Subscription─▶  Local Table             │
│  ex. ZCASHACT   │              │  (DDS_...기술명)         │
└─────────────────┘              └──────────────────────────┘
                                          │
                                          ▼ Share to other spaces
                                  ┌──────────────────────────┐
                                  │  분석용 스페이스          │
                                  │  (View, AM 생성)          │
                                  └──────────────────────────┘
```

**핵심 포인트:**
- BW의 **Data Subscription** = "이 ADSO 데이터를 Datasphere로 주기적으로 전송"
- Datasphere에 생성되는 테이블의 기술명은 `DDS_...` 형태의 자동 생성 ID
- BW 비즈니스 시맨틱(계층, 특수 오브젝트 타입 등)은 **초기 버전에서는 포함 안 됨** ⚠️

> **Disclaimer**: Data Product Generator는 현재 초기 단계입니다.  
> BW 고유 기능(계층, 특수 오브젝트 타입, 자동화)은 향후 버전에 추가 예정입니다.

---

## Guided Tour: 탐색 순서

### Step 1 · BW Cockpit에서 DataStore 확인

![BW Cockpit — ZCASHACT DataStore 조회 화면](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_2_image02.png)

- BW Cockpit에서 현금 흐름 데이터가 저장된 **ZCASHACT** DataStore를 조회합니다
- 데이터 구조와 레코드 수를 확인합니다

### Step 2 · Data Subscription 정의

![Data Product Generator — Data Subscription 생성 화면](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_2_image05b.png)

Data Subscription 생성 시 지정 항목:
- **소스**: BW DataStore (ZCASHACT)
- **대상**: SAP Datasphere BW Ingestion Space
- **실행 방식**: 수동 또는 스케줄 실행

### Step 3 · Data Subscription 실행

![Data Subscription 실행 결과 — 전송된 레코드 수](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_2_image08b.png)

- Subscription을 **Run** 하면 BW 레코드가 Datasphere로 전송됩니다
- 완료 후 Datasphere의 BW Ingestion Space에 Local Table이 생성됩니다

### Step 4 · SAP Datasphere에서 데이터 확인

![Datasphere Data Builder — DDS_... 테이블 데이터 미리보기](https://da4ug0lohul1.cloudfront.net/prod/AcademyContentFileImage/Trial_BTP-BDC/545_BW_Modernization/Images/545_2_image12b.png)

- Data Builder → BW Ingestion Space에서 생성된 테이블 확인
- **Data Preview**로 실제 현금 흐름 데이터 레코드 확인

---

## 핵심 포인트 요약

| 항목 | 설명 |
|------|------|
| 소스 오브젝트 | SAP BW ADSO (Advanced DataStore Object) |
| 전송 방식 | Data Subscription (Pull이 아닌 Push) |
| 대상 위치 | Datasphere BW Ingestion Space → Local Table |
| 기술명 규칙 | `DDS_` + 자동 생성 ID (비즈니스명 별도 부여 가능) |
| 공유 방법 | Ingestion Space → 분석 스페이스로 **Share** |

---

*다음 레슨: [02 · Data Product 정의 →](./02_define_data_product.md)*