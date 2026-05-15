# BW Modernization 워크샵 메뉴얼

> SAP Business Data Cloud — BW Modernization 실습 가이드 (한글판)

## 학습 목표

SAP BW에 쌓인 **수년간의 핵심 비즈니스 데이터**를 현대적인 데이터 플랫폼으로 전환하는 전 과정을 실습합니다.  
본 워크샵에서는 **현금 흐름(Cash Flow) 예측** 시나리오를 통해 BW 데이터를 AI/ML 분석에 활용하는 방법을 배웁니다.

## 전체 아키텍처

```
SAP BW                SAP Datasphere           SAP Databricks
(실제 데이터)  ──────▶  BW Ingestion Space  ──▶  ML 예측 모델
                        ↓                          ↓
                      Data Product        Data Product (예측값)
                        ↓                          ↓
                      Fact View ◀────────────────◀
                        ↓
                      Analytic Model
                        ↓
                   SAP Analytics Cloud
                   (대시보드 시각화)
```

## 커리큘럼 (총 약 70분)

| # | 레슨 | 시간 | 유형 |
|---|------|------|------|
| 0 | [개요 및 전략](./00_overview.md) | 3분 | 개념 |
| 1 | [Data Product Generator](./01_data_product_generator.md) | 10분 | Guided Tour |
| 2 | [Data Product 정의](./02_define_data_product.md) | 10분 | Guided Tour |
| 3 | [SAP Databricks에서 Data Product 강화](./03_enhance_in_databricks.md) | 15분 | 실습 |
| 4 | [Data Product 설치](./04_install_data_product.md) | 5분 | 실습 |
| 5 | [데이터 모델링 (Fact View + AM)](./05_data_modeling.md) | 15분 | 실습 |
| 6 | [데이터 시각화 (SAC 대시보드)](./06_data_visualization.md) | 15분 | 실습 |

## 유형 구분

- **Guided Tour**: 시스템이 이미 준비된 결과를 탐색하며 개념 이해 (직접 생성 불필요)
- **실습**: 수강생이 직접 오브젝트를 만들고 배포

## 접속 URL

| 시스템 | URL |
|--------|-----|
| SAP Datasphere | [Learning Journey 접속](https://trials.cfapps.eu10-004.hana.ondemand.com/learning-journey/ws_bdc/bw-dataproduct) |
| SAP Databricks | 강사 제공 |
| SAP Analytics Cloud | Datasphere 앱 스위처 → SAC |

---
*원본: SAP Business Data Cloud Learning Journey — BW Modernization*
