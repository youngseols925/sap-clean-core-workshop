# Lesson 3 · SAP Databricks에서 Data Product 강화

> ⏱ 15분 | **직접 실습**

## 학습 목표

SAP BDC에서 공유된 현금 흐름 데이터를 **SAP Databricks**에서 받아,  
**ML 예측 모델(Prophet)**로 미래 현금 흐름을 예측하고,  
결과를 다시 SAP Datasphere로 역공유하는 전 과정을 실습합니다.

---

## 전체 흐름

```
SAP Datasphere → Delta Share → SAP Databricks
                                    │
                         ① 데이터 탐색 (Notebook)
                         ② ML 모델 최적화 (MLflow)
                         ③ 예측 결과 테이블 생성
                         ④ Delta Share로 역공유
                         ⑤ sap-bdc-connect-sdk로 Data Product 게시
                                    │
                                    ▼
                              SAP Datasphere Catalog
                              (cashflow_forecast 등록)
```

---

## Part 1 · SAP Databricks 로그인

### Step 1 · 접속

브라우저에서 SAP Databricks URL 접속 (강사 제공 또는 Learning Journey 링크 클릭)

- Email: `AC317935U01@sapexperienceacademy.com`
- **Continue with SSO** 선택
- **default workspace** 선택

![SAP Databricks Welcome 화면](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_4_image02.png)

---

## Part 2 · BW Data Product 데이터 탐색

### Step 2 · Catalog에서 실제 현금 흐름 테이블 확인

좌측 네비게이션 **Catalog** 선택

```
My organization
  └── cashflow_data_product
        └── cashflow
              └── zcashflow  ← 여기 클릭
```

![zcashflow 테이블 — Sample Data 탭](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_4_image03.png)

- **Sample Data** 탭에서 데이터 확인 (컴퓨팅 리소스가 없으면 **Select compute → Serverless → Start**)
- 이것이 SAP BDC에서 공유된 **실제 현금 흐름 데이터**

### Step 3 · 예측 결과 테이블 확인

```
My organization
  └── cashflow_data_product
        └── cashflow
              └── cashflow_forecast  ← 예측 결과
```

- 이 테이블은 ML 모델이 생성한 **미래 현금 흐름 예측값**
- Sample Data 탭으로 데이터 구조 확인

---

## Part 3 · ML 모델 검토 (Notebook 탐색)

> ℹ️ **이 파트는 코드를 다시 실행하지 않습니다** — 이미 실행된 결과를 검토합니다.

### Step 4 · 데이터 탐색 Notebook 임포트

![Workspace → Import 화면](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_4_image04.png)

1. Learning Journey에서 **`10_Exploratory_Data_Analysis.py`** 다운로드
2. 좌측 **Workspace** → Users → 내 사용자명 우클릭 → **Import**
3. 파일 선택 후 임포트
4. 파일 열기 → Environment Settings → **v5** 설정 → Apply

### Step 5 · 데이터 탐색 코드 실행

노트북을 순서대로 실행하며 `zcashflow` 소스 데이터 구조와 내용을 SQL/Python으로 확인

- DDL(테이블 구조), 데이터 샘플, 기본 통계 등을 확인
- 완료 후 노트북 닫기

### Step 6 · ML 모델 최적화 Notebook 검토

```
Workspace → Project_Artifacts
  └── 50 Cash flow Model Optimization
```

이 Notebook의 핵심 내용:
- **Prophet 모델** (시계열 예측에 최적화된 Meta 오픈소스 라이브러리) 사용
- **Bayesian Optimization**으로 하이퍼파라미터 튜닝 (회사 코드별)
- **MLflow Tracking**으로 모든 실험 파라미터/결과 기록

> ⚠️ 코드를 다시 실행하지 마세요 — 테이블이 재생성됩니다

### Step 7 · MLflow 실험 결과 확인

좌측 네비게이션 → **Experiments**

- "Only my experiments" 체크 해제 → **"50 Cash flow"** 검색
- **Derek Ian** 실험 선택 → 회사 코드별 모델 최적화 실행 결과 확인

![MLflow — 회사 코드별 실험 결과 (Color-coded 차트)](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_4_image05.png)

- 회사 코드 **1730** 실행 결과 클릭
- Metrics, Parameters, Artifacts 탭 확인
- 샘플 예측 코드 확인

### Step 8 · 예측 모델 적용 Notebook 검토

```
Workspace → Project_Artifacts
  └── 60 Cash flow forecast Best Model Productive
```

- 최적 MAPE 점수의 모델을 선택하여 예측 실행
- **cashflow_forecast** 테이블 생성·적재
- > ⚠️ 코드 재실행 금지

---

## Part 4 · 예측 Data Product를 SAP Datasphere로 역공유

### Step 9 · Delta Share 생성

![Catalog — cashflow_forecast → Share → Share via Delta Sharing](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_4_image06.png)

1. **Catalog** → cashflow_data_product → cashflow → **cashflow_forecast** 선택
2. **Share** → **Share via Delta Sharing** 클릭
3. **Create a new share with the table** 선택
4. 설정:
   - Share name: `cashflow_forecast_data_product_share_AC317935U01`
   - Recipients: `sap-business-data-cloud`
5. **Share** 클릭

### Step 10 · Delta Share 확인

Catalog → ⚙️ Gear → **Delta Sharing** → **Shared by me** 탭  
→ 사용자명 `AC317935U01`로 필터 → 방금 만든 Share 확인

![Delta Sharing — Shared by me 탭](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_4_image07.png)

---

## Part 5 · sap-bdc-connect-sdk로 Data Product 게시

### Step 11 · Publish Notebook 임포트

Learning Journey에서 **`Publish_Data_Product_Cashflow_Forecast.py`** 다운로드 후 임포트 (Step 4와 동일한 방법)

### Step 12 · 5개 코드 블록 순서대로 실행

| 블록 | 역할 |
|------|------|
| ① | **SDK 설치** (`sap-bdc-connect-sdk`) — 완료까지 약 1분 소요 |
| ② | **Client 생성** — DatabricksClient + BdcConnectClient 초기화 |
| ③ | **Share 생성** — Open Resource Discovery 프로토콜 기반 |
| ④ | **CSN 생성** — 데이터 구조 표준 메타데이터 기술 |
| ⑤ | **Data Product 게시** — SAP Datasphere Catalog에 등록 |

> ℹ️ ① 실행 시 버전 관련 경고/pip 의존성 에러 메시지는 무시해도 됩니다

### Step 13 · SAP Datasphere Catalog에서 게시 결과 확인

SAP Datasphere → **Catalog & Marketplace** → Search

1. 필터: **Data Products** + **SAP Databricks** (System Type)
2. 검색어: `cashflow forecast data product from AC317935U01`
3. 목록에서 내 Data Product 확인

![Datasphere Catalog — cashflow forecast data product 검색 결과](https://raw.githubusercontent.com/youngseols925/sap-clean-core-workshop/main/lite/docs/manual/bw-modernization/images/545_4_image08.png)

> ⏳ Catalog에 즉시 나타나지 않을 수 있습니다. 몇 분 대기 후 재검색하거나,  
> 강사가 미리 준비한 **pre-delivered 데이터 상품**을 다음 단계에서 사용합니다.

---

## 핵심 포인트 요약

| 항목 | 내용 |
|------|------|
| ML 라이브러리 | **Prophet** (Meta 시계열 예측) + **MLflow** (실험 추적) |
| 하이퍼파라미터 최적화 | Bayesian Optimization (회사 코드별 개별 최적화) |
| BW → Databricks 방향 | Delta Sharing (SAP BDC 공유) |
| Databricks → Datasphere 방향 | Delta Share + sap-bdc-connect-sdk |
| SDK 역할 | Python으로 Datasphere Catalog에 Data Product 자동 등록 |

---

*다음 레슨: [04 · Data Product 설치 →](./04_install_data_product.md)*