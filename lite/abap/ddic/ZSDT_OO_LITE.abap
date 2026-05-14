*&---------------------------------------------------------------------*
*& ZSDT_OO_LITE — Z-Table DDIC 정의
*& Open Order Lite 저장 테이블
*&
*& SE11 생성 절차:
*&  1. SE11 → 데이터베이스 테이블 → ZSDT_OO_LITE → 신규
*&  2. 설명: Open Order Lite (워크샵)
*&  3. 전달 클래스: A
*&  4. 필드 탭: 아래 정의 참조
*&  5. Technical Settings:
*&       Data Class: APPL0
*&       Size Category: 1
*&       Buffering: No Buffering
*&  6. 활성화 후 SE38에서 ZSD_OO_LITE Report 활성화
*&---------------------------------------------------------------------*

* ======================================================================
* 테이블 필드 정의
* ======================================================================
*
* Field Name    Key  Ini  Data Elem        Domain/Type  Len  Desc
* ------------- ---  ---  ---------------  -----------  ---  ---------
* MANDT          ✅   ✅  MANDT            CLNT           3  클라이언트
* VBELN          ✅   ✅  VBELN_VA         CHAR          10  판매 오더 번호
* POSNR          ✅   ✅  POSNR_VA         NUMC           6  오더 아이템
* AUDAT               ✅  AUDAT            DATS           8  오더 생성일
* AUDAT_YM            ✅  SPMON            NUMC           6  오더 생성년월(YYYYMM)
* VKORG                   VKORG            CHAR           4  영업 조직
* SPART                   SPART            CHAR           2  제품군
* KUNNR                   KUNNR            CHAR          10  고객 코드
* KUNNR_NAME              NAME1_GP         CHAR          35  고객명
* MATNR                   MATNR            CHAR          18  자재 번호
* MATKL                   MATKL            CHAR           9  자재 그룹
* ORD_QTY                 KWMENG           DEC           13  오더 수량
* ORD_AMT                 NETWR            CURR          15  오더 금액 (통화키: WAERK)
* WAERK                   WAERK            CUKY           5  통화 키
* ELAPSED_DAYS            —                INT4           4  경과일수
* AGING_GRP               —                CHAR           3  Aging 구간(030/060/090/90+)

* ======================================================================
* 포함 구조 (Currency Field 선언 — SE11 Currency/Quantity Fields 탭)
* ======================================================================
* ORD_AMT  → Reference Field: WAERK (같은 테이블)

* ======================================================================
* 인덱스 (선택)
* ======================================================================
* SE11 → 인덱스 탭:
*   Index Name: ZSD_OO_LITE_I001
*   Fields    : VKORG, AUDAT, KUNNR

* ======================================================================
* ABAP 타입 참조용 구조체 (ABAPDoc)
* ======================================================================
*
*  DATA: ls_oo_lite TYPE zsdt_oo_lite.
*  DATA: lt_oo_lite TYPE TABLE OF zsdt_oo_lite.
*
*  " 저장 예시
*  INSERT zsdt_oo_lite FROM TABLE lt_oo_lite.
*
*  " 삭제 예시
*  DELETE FROM zsdt_oo_lite
*    WHERE vkorg IN s_vkorg
*    AND   audat IN s_audat.
*
* ======================================================================
* Z-Table 남용 경고 (워크샵 토론 포인트)
* ======================================================================
*
*  ❌ ANTI-PATTERN: BW/DSP에서 ZSDT_OO_LITE를 RF 소스로 사용
*       → Z-Table 업데이트 주기에 DSP 데이터가 종속됨
*       → ABAP 배치잡이 실패하면 DSP 데이터도 오염
*       → ERP 배치 부하가 사라지지 않음 (악순환)
*
*  ✅ CLEAN CORE: DSP에서 2LIS_11_VAHDR / 2LIS_11_VAITM 직접 사용
*       → SAP Standard DataSource → ODP(Operational Data Provider)
*       → ERP 표준 델타 메커니즘 활용
*       → Z-Table 의존성 완전 제거
