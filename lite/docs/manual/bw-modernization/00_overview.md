# Lesson 0 · BW Modernization 개요

> ⏱ 3분 | 개념 이해

## 학습 목표

SAP BW 현대화 전략과 SAP Business Data Cloud(BDC)의 핵심 가치를 이해합니다.

---

## 왜 BW Modernization인가?

SAP BW에는 수년간의 **중요한 비즈니스 데이터**가 축적되어 있습니다.  
이 데이터를 클라우드 기반 AI/Analytics 플랫폼에서 활용할 수 있게 하는 것이 핵심 목표입니다.

### 3가지 핵심 전략

| 단계 | 전략 | 설명 |
|------|------|------|
| 1️⃣ | **LIFT** | 기존 SAP BW 시스템을 클라우드(Private Cloud Edition)로 이전 — BW 투자 보호 |
| 2️⃣ | **SHIFT** | BW 데이터를 **Data Product**로 패키징하여 공유 — Datasphere/Databricks에서 활용 |
| 3️⃣ | **INNOVATE** | SAP Datasphere + SAP Databricks 기반 AI/ML 분석으로 비즈니스 가치 창출 |

### 핵심 이점 3가지

- 📦 **BW 데이터를 현대 데이터 패브릭에 노출** — Datasphere/Databricks와 연결
- 🤖 **AI 기반 강화** — 누적된 BW 데이터로 예측 모델 학습
- ⏱ **자신의 속도로 클라우드 전환** — 기존 BW 운영 중단 없이 단계적 전환

---

## 워크샵 시나리오: 현금 흐름 예측

> *"기업이 전략적 목표를 달성하고 위기를 극복하려면 정확한 현금 흐름 예측이 필수입니다."*

### 데이터 흐름

```
SAP BW (실제 Cash Flow ADSO)
        │
        ▼  Data Product Generator
SAP Datasphere BW Ingestion Space
        │
        ▼  Data Product 정의 + 공유
SAP Databricks
        │  ML 모델로 미래 Cash Flow 예측
        ▼  Delta Share로 역공유
SAP Datasphere (예측값 설치)
        │
        ▼  Fact View (실적 + 예측 UNION)
Analytic Model
        │
        ▼
SAP Analytics Cloud 대시보드
```

### 워크샵에서 수행할 작업

1. **Data Product Generator**로 BW 실적 현금 흐름 데이터를 Datasphere로 복제
2. BW 데이터에 대한 **Data Product 정의** 및 Databricks 공유
3. SAP Databricks에서 **ML 예측 모델** 학습 및 예측 Data Product 생성
4. 예측 Data Product를 Datasphere에 **설치**
5. 실적 + 예측 데이터를 **Fact View**로 통합 → **Analytic Model** 생성
6. SAC에서 **대시보드** 제작 — 실적/예측 현금 흐름 시각화

---

## 핵심 개념 정리

### SAP Business Data Cloud (BDC)
SAP BW + SAP Datasphere + SAP Databricks를 하나의 통합 플랫폼으로 묶는 솔루션.  
BW 데이터를 Data Product로 패키징하여 기업 전체에서 발견하고 사용할 수 있게 합니다.

### Data Product
특정 목적을 위해 큐레이션된 데이터셋. BW의 원시 데이터를 분석/AI에 바로 활용 가능한 형태로 포장한 것.  
Catalog에 등록되어 전사적으로 검색·구독·사용 가능.

### BW Ingestion Space
SAP Datasphere 내에서 BW 데이터를 수신하는 전용 스페이스.  
Data Product Generator가 BW ADSO 데이터를 이 스페이스의 Local Table로 적재합니다.

### Delta Sharing
Databricks가 지원하는 오픈 프로토콜. Databricks ↔ Datasphere 간 데이터 공유에 사용됩니다.

---

*다음 레슨: [01 · Data Product Generator →](./01_data_product_generator.md)*
