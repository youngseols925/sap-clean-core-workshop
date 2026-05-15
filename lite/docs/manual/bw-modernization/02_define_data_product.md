# Lesson 2 · Data Product 정의 (Data Sharing Cockpit)

> ⏱ 10분 | Guided Tour (탐색만 — 직접 생성 불필요)

## 학습 목표

**Data Sharing Cockpit**에서 SAP BW 데이터에 대한 Data Product를 생성하고,  
SAP Databricks로 공유하는 방법을 이해합니다.

> ⚠️ **참고**: 이 레슨의 Data Product는 이미 생성되어 있습니다.  
> 수강생 계정에는 Data Catalog Administrator 역할이 없으므로 **읽기 전용**으로 탐색합니다.

---

## 개념 이해

### Data Sharing Cockpit이란?

Data Provider(데이터를 제공하는 팀/담당자)의 **중앙 관리 포털**입니다.

주요 기능:
- Data Product 생성 및 신규 릴리스 게시
- Catalog 등록 — 전사 검색 가능
- SAP Databricks 등 외부 시스템으로 공유

### SAP BW Data Product란?

SAP BW에서 추출된 **큐레이션된 데이터셋**으로:
- 분석 및 AI 애플리케이션에서 바로 사용 가능한 형태
- SAP BDC(Business Data Cloud) Catalog에 등록
- 전사적으로 검색·발견·구독 가능

---

## 데이터 흐름

```
Datasphere BW Ingestion Space
        (Local Table: DDS_...)
               │
               ▼
    Data Sharing Cockpit
    ┌─────────────────────────────────┐
    │  ① Data Product 생성           │
    │     - 이름, 설명, 버전          │
    │     - 소스 테이블 지정          │
    │  ② Catalog에 게시               │
    │     (전사 검색 가능)            │
    │  ③ SAP Databricks로 공유        │
    │     (Delta Sharing 방식)        │
    └─────────────────────────────────┘
               │
               ▼
    SAP Databricks Catalog
    (Delta Shares Received 섹션)
```

---

## Guided Tour: 탐색 순서

### Step 1 · Data Sharing Cockpit 접속

![Data Sharing Cockpit 메인 화면](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_3_image03.png)

- SAP BDC 메인 메뉴에서 **Data Sharing Cockpit** 선택
- 기 생성된 Data Product 목록 확인

### Step 2 · Data Product 생성 방식 확인

![Data Product 상세 화면 — 소스 테이블 매핑](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_3_image05.png)

Data Product 생성 시 설정 항목:
| 항목 | 예시값 |
|------|--------|
| Data Product 이름 | Cash Flow Actual |
| 소스 테이블 | BW Ingestion Space의 ZCASHACT 테이블 |
| 버전 | 1.0.0 |
| 공개 범위 | 내부 + Databricks |

### Step 3 · Catalog 게시 확인

![BDC Catalog — Cash Flow Data Product 검색 결과](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_3_image03.png)

- **Catalog & Marketplace** → Search에서 Data Product 검색
- IT Data Analyst가 등록하면 전사 누구나 검색·구독 가능

### Step 4 · Databricks 공유 설정 확인

![Data Product — Databricks 공유 설정 화면](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_3_image05.png)

- **Recipients**: `sap-business-data-cloud` (SAP BDC 시스템)
- 공유 후 Databricks Catalog의 **Delta Shares Received** 섹션에 등장

> 📌 **Note**: Databricks Delta Shares 기능은 wave **2025.17**에 릴리스되었습니다.  
> 실습 환경에 따라 정확한 위치가 다를 수 있습니다.

---

## 핵심 포인트 요약

| 항목 | 설명 |
|------|------|
| Data Sharing Cockpit 역할 | Data Provider 전용 관리 포털 |
| Data Product 게시 대상 | SAP BDC Catalog (전사 검색) |
| 외부 공유 방식 | Delta Sharing 프로토콜 |
| 수강생 권한 | 읽기 전용 (Data Catalog Admin 역할 없음) |
| 다음 단계 | Databricks에서 이 Data Product 활용 |

---

*다음 레슨: [03 · SAP Databricks에서 Data Product 강화 →](./03_enhance_in_databricks.md)*