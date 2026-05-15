*&---------------------------------------------------------------------*
*& ZSDT_OO_LITE — Z-Table DDIC 정의
*& Open Order Lite 저장 테이블 (VBAK + VBAP 기반)
*&
*& SE11 생성 절차:
*&  1. SE11 → 데이터베이스 테이블 → ZSDT_OO_LITE → 신규
*&  2. 설명: Open Order Lite (워크샵 — VBAK/VBAP Only)
*&  3. 전달 클래스: A
*&  4. Technical Settings:
*&       Data Class: APPL0
*&       Size Category: 1
*&       Buffering: No Buffering
*&  5. 활성화 후 SE38에서 ZSD_OO_LITE 활성화
*&---------------------------------------------------------------------*

* ======================================================================
* 테이블 필드 정의
* ======================================================================
*
* Field Name    Key  Ini  Data Elem        Type   Len  Desc
* ------------- ---  ---  ---------------  -----  ---  ----------------------------
* MANDT          ✅   ✅  MANDT            CLNT     3  클라이언트
* VBELN          ✅   ✅  VBELN_VA         CHAR    10  판매 오더 번호
* POSNR          ✅   ✅  POSNR_VA         NUMC     6  오더 아이템
* AUDAT               ✅  AUDAT            DATS     8  오더 생성일          ← VBAK
* AUDAT_YM            ✅  SPMON            NUMC     6  오더 생성년월(YYYYMM) ← 계산
* VKORG                   VKORG            CHAR     4  영업 조직             ← VBAK
* SPART                   SPART            CHAR     2  제품군                ← VBAK
* KUNNR                   KUNNR            CHAR    10  고객 코드             ← VBAK
* MATNR                   MATNR            CHAR    18  자재 번호             ← VBAP
* MATKL                   MATKL            CHAR     9  자재 그룹             ← VBAP
* ORD_QTY                 KWMENG           DEC   13,3  오더 수량             ← VBAP
* ORD_AMT                 WERTV8           CURR  15,2  오더 금액 (ref: WAERK) ← VBAP
* WAERK                   WAERK            CUKY     5  통화 키               ← VBAK
* ELAPSED_DAYS            —                INT4     4  경과일수              ← 계산
* AGING_GRP               —                CHAR     3  Aging 구간(030/060/090/90+) ← 계산

* ======================================================================
* Currency Field 선언 (SE11 → Currency/Quantity Fields 탭)
* ======================================================================
* ORD_AMT  → Reference Field: WAERK (같은 테이블)

* ======================================================================
* 인덱스 (선택)
* ======================================================================
* Index: ZSD_OO_LITE_I001  Fields: VKORG, AUDAT, KUNNR

* ======================================================================
* 소스 매핑 요약
* ======================================================================
*  필드          소스 테이블  소스 필드
*  VBELN         VBAK         VBELN
*  AUDAT         VBAK         AUDAT
*  AUDAT_YM      계산         VBAK-AUDAT(6)
*  VKORG         VBAK         VKORG
*  SPART         VBAK         SPART
*  KUNNR         VBAK         KUNNR
*  WAERK         VBAK         WAERK
*  POSNR         VBAP         POSNR
*  MATNR         VBAP         MATNR
*  MATKL         VBAP         MATKL
*  ORD_QTY       VBAP         KWMENG
*  ORD_AMT       VBAP         NETWR
*  ELAPSED_DAYS  계산         SY-DATUM - VBAK-AUDAT
*  AGING_GRP     계산         ELAPSED_DAYS 기준 구간

* ======================================================================
* ABAP 타입 참조
* ======================================================================
*  DATA: ls_oo_lite TYPE zsdt_oo_lite.
*  DATA: lt_oo_lite TYPE TABLE OF zsdt_oo_lite.
*
*  INSERT zsdt_oo_lite FROM TABLE lt_oo_lite.
*
*  DELETE FROM zsdt_oo_lite
*    WHERE vkorg IN s_vkorg
*    AND   audat IN s_audat.
