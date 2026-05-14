*&---------------------------------------------------------------------*
*& Report  ZSD_SELLIN_PERF
*& Sell-In 실적현황 조회 및 Z-Table 저장 프로그램
*& 목적: 워크샵 시연용 - ERP 리소스를 많이 사용하는 CBO 프로그램 예시
*&---------------------------------------------------------------------*
REPORT zsd_sellin_perf
  LINE-SIZE 255
  LINE-COUNT 65
  MESSAGE-ID zmsd.

*----------------------------------------------------------------------*
* 타입 정의
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_sellin,
    vkorg        TYPE vkorg,       " 영업 조직
    vtweg        TYPE vtweg,       " 유통 경로
    spart        TYPE spart,       " 제품군
    vbeln        TYPE vbeln_va,    " 판매 오더 번호
    posnr        TYPE posnr_va,    " 오더 아이템
    audat        TYPE audat,       " 오더 생성일
    gjahr        TYPE gjahr,       " 회계 연도
    spmon        TYPE spmon,       " 기간(YYYYMM)
    kunnr        TYPE kunnr,       " 고객 코드
    kunag        TYPE kunag,       " 판매처(sold-to)
    kunnr_name   TYPE name1_gp,    " 고객 명
    credit_group TYPE knkk-ctlpc,  " 신용 그룹
    matnr        TYPE matnr,       " 자재 번호
    arktx        TYPE arktx,       " 자재 설명
    matkl        TYPE matkl,       " 자재 그룹
    mtart        TYPE mtart,       " 자재 유형
    meins        TYPE meins,       " 기본 단위
    vrkme        TYPE vrkme,       " 판매 단위
    ord_qty      TYPE menge_d,     " 오더 수량
    dlv_qty      TYPE menge_d,     " 납품 수량
    bil_qty      TYPE menge_d,     " 청구 수량
    dlv_rate     TYPE p DECIMALS 2," 납품율(%)
    bil_rate     TYPE p DECIMALS 2," 청구율(%)
    waers        TYPE waers,       " 오더 통화
    pr00_kbetr   TYPE kbetr,       " 정가 단가 (PR00 조건)
    netwr        TYPE netwr_ap,    " 순액 (오더통화)
    disc_amt     TYPE wertv8,      " 할인금액 합계
    disc_rate    TYPE p DECIMALS 2," 할인율(%)
    mwst_rate    TYPE p DECIMALS 2," 세율(%)
    tax_amt      TYPE wertv8,      " 세액
    cogs         TYPE wertv8,      " 매출원가 (MBEW 이동평균/표준원가)
    margin       TYPE wertv8,      " 마진금액
    margin_rate  TYPE p DECIMALS 2," 마진율(%)
    net_lc       TYPE wertv8,      " 로컬통화 순매출
    cogs_lc      TYPE wertv8,      " 로컬통화 원가
    margin_lc    TYPE wertv8,      " 로컬통화 마진
    lwaers       TYPE waers,       " 로컬 통화
    py_amt       TYPE wertv8,      " 전년동기 금액
    achv_rate    TYPE p DECIMALS 2," 달성율(%)
    vbreln       TYPE vbeln_vf,    " 청구 문서번호
    vbrelp       TYPE posnr_vf,    " 청구 아이템
    lips_vl      TYPE vbeln_vl,    " 납품 문서번호
    lfdat        TYPE lfdat,       " 납품 예정일
    ikpif        TYPE p DECIMALS 2," 납품완료율 (item)
    traffic      TYPE char1,       " 신호등(G/Y/R)
  END OF ty_sellin,

  BEGIN OF ty_vbak_sel,
    vbeln TYPE vbeln_va,
    erdat TYPE erdat,
    audat TYPE audat,
    vkorg TYPE vkorg,
    vtweg TYPE vtweg,
    spart TYPE spart,
    kunnr TYPE kunnr,
    kunag TYPE kunag,
    gbstk TYPE gbstk,
    waers TYPE waers,
    netwr TYPE netwr_ap,
    knumv TYPE knumv,
  END OF ty_vbak_sel,

  BEGIN OF ty_vbap_sel,
    vbeln TYPE vbeln_va,
    posnr TYPE posnr_va,
    matnr TYPE matnr,
    matkl TYPE matkl,
    mtart TYPE mtart,
    arktx TYPE arktx,
    meins TYPE meins,
    vrkme TYPE vrkme,
    kwmeng TYPE kwmeng,
    netwr  TYPE netwr_ap,
    waers  TYPE waers,
    abgru  TYPE abgru,
    gbsta  TYPE gbsta,
  END OF ty_vbap_sel,

  BEGIN OF ty_vbfa_sel,
    vbelv TYPE vbelv,
    posnv TYPE posnv,
    vbeln TYPE vbeln,
    posnn TYPE posnn,
    vbtyp_n TYPE vbtyp,
  END OF ty_vbfa_sel,

  BEGIN OF ty_vbrp_sel,
    vbeln TYPE vbeln_vf,
    posnr TYPE posnr_vf,
    aubel TYPE aubel,
    aupos TYPE aupos,
    fkimg TYPE fkimg,
    netwr TYPE netwr_ap,
    mwsbp TYPE mwsbp,
  END OF ty_vbrp_sel,

  BEGIN OF ty_lips_sel,
    vbeln TYPE vbeln_vl,
    posnr TYPE posnr_vl,
    vgbel TYPE vgbel,
    vgpos TYPE vgpos,
    lfimg TYPE lfimg,
    meins TYPE meins,
  END OF ty_lips_sel,

  BEGIN OF ty_konv_sel,
    knumv TYPE knumv,
    kposn TYPE kposn,
    kschl TYPE kschl,
    kbetr TYPE kbetr,
    kwert TYPE kwert,
    kkurs TYPE kkurs,
    waers TYPE waers,
    loevm_ko TYPE loevm_ko,
  END OF ty_konv_sel,

  BEGIN OF ty_mbew_sel,
    matnr TYPE matnr,
    bwkey TYPE bwkey,
    vprsv TYPE vprsv,
    verpr TYPE verpr,
    stprs TYPE stprs,
    peinh TYPE peinh,
    bklas TYPE bklas,
  END OF ty_mbew_sel,

  BEGIN OF ty_kna1_sel,
    kunnr TYPE kunnr,
    name1 TYPE name1_gp,
    ktokd TYPE ktokd,
    land1 TYPE land1_gp,
    regio TYPE regio,
  END OF ty_kna1_sel,

  BEGIN OF ty_knvv_sel,
    kunnr TYPE kunnr,
    vkorg TYPE vkorg,
    vtweg TYPE vtweg,
    spart TYPE spart,
    kdgrp TYPE kdgrp,
    kalks TYPE kalks,
  END OF ty_knvv_sel,

  " 전년동기 집계용
  BEGIN OF ty_py_amt,
    vkorg    TYPE vkorg,
    kunnr    TYPE kunnr,
    matnr    TYPE matnr,
    spart    TYPE spart,
    matkl    TYPE matkl,
    spmon    TYPE spmon,
    net_amt  TYPE wertv8,
  END OF ty_py_amt.

*----------------------------------------------------------------------*
* 내부 테이블 선언
*----------------------------------------------------------------------*
DATA:
  gt_sellin    TYPE STANDARD TABLE OF ty_sellin,
  gt_vbak      TYPE STANDARD TABLE OF ty_vbak_sel,
  gt_vbap      TYPE STANDARD TABLE OF ty_vbap_sel,
  gt_vbfa      TYPE STANDARD TABLE OF ty_vbfa_sel,
  gt_vbrp      TYPE STANDARD TABLE OF ty_vbrp_sel,
  gt_lips      TYPE STANDARD TABLE OF ty_lips_sel,
  gt_konv      TYPE STANDARD TABLE OF ty_konv_sel,
  gt_mbew      TYPE STANDARD TABLE OF ty_mbew_sel,
  gt_kna1      TYPE STANDARD TABLE OF ty_kna1_sel,
  gt_knvv      TYPE STANDARD TABLE OF ty_knvv_sel,
  gt_py_amt    TYPE STANDARD TABLE OF ty_py_amt,
  gs_sellin    TYPE ty_sellin,
  gs_vbak      TYPE ty_vbak_sel,
  gs_vbap      TYPE ty_vbap_sel,
  gs_vbrp      TYPE ty_vbrp_sel,
  gs_lips      TYPE ty_lips_sel,
  gs_konv      TYPE ty_konv_sel,
  gs_mbew      TYPE ty_mbew_sel,
  gs_kna1      TYPE ty_kna1_sel,
  gv_lines     TYPE i,
  gv_save_cnt  TYPE i,
  gv_err_cnt   TYPE i.

*----------------------------------------------------------------------*
* ALV 관련 선언
*----------------------------------------------------------------------*
DATA:
  go_alv       TYPE REF TO cl_gui_alv_grid,
  go_container TYPE REF TO cl_gui_custom_container,
  gt_fieldcat  TYPE lvc_t_fcat,
  gs_fieldcat  TYPE lvc_s_fcat,
  gs_layout    TYPE lvc_s_layo,
  gs_variant   TYPE disvariant,
  gt_sort      TYPE lvc_t_sort,
  gs_sort      TYPE lvc_s_sort.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS:
    s_audat  FOR vbak-audat OBLIGATORY,    " 오더 생성일
    s_spmon  FOR vbak-audat NO-DISPLAY,    " 기간 (YYYYMM) - 내부 변환용
    s_vkorg  FOR vbak-vkorg,               " 영업 조직
    s_vtweg  FOR vbak-vtweg,               " 유통 경로
    s_spart  FOR vbak-spart,               " 제품군
    s_kunnr  FOR vbak-kunnr,               " 고객
    s_matnr  FOR vbap-matnr,               " 자재 번호
    s_matkl  FOR vbap-matkl.               " 자재 그룹
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_waers  TYPE waers DEFAULT 'KRW',     " 환산 통화
    p_auart  TYPE auart DEFAULT 'OR',      " 오더 유형
    p_gbstk  TYPE gbstk DEFAULT 'C'.       " 전체 처리 상태 ('C'=청구완료 포함)
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS:
    p_save   TYPE xfeld AS CHECKBOX,       " Z-Table 저장 여부
    p_delold TYPE xfeld AS CHECKBOX DEFAULT 'X'. " 기존 데이터 삭제 후 저장
SELECTION-SCREEN END OF BLOCK b3.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  " 필수값 검증
  IF s_audat[] IS INITIAL.
    MESSAGE e001(zmsd) WITH '오더 생성일 기간을 입력하세요.'.
  ENDIF.
  IF s_vkorg[] IS INITIAL.
    MESSAGE w002(zmsd) WITH '영업조직을 입력하지 않으면 전체 조회됩니다.'.
  ENDIF.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM f_get_vbak.       " STEP1: 판매 오더 헤더 조회
  CHECK gt_vbak IS NOT INITIAL.

  PERFORM f_get_vbap.       " STEP2: 판매 오더 아이템 조회
  CHECK gt_vbap IS NOT INITIAL.

  PERFORM f_get_vbfa.       " STEP3: 문서흐름 조회 (오더→납품→청구)
  PERFORM f_get_vbrp.       " STEP4: 청구 아이템 조회
  PERFORM f_get_lips.       " STEP5: 납품 아이템 조회
  PERFORM f_get_konv.       " STEP6: 가격조건 조회 (할인, 세금)
  PERFORM f_get_mbew.       " STEP7: 자재평가 조회 (원가)
  PERFORM f_get_kna1.       " STEP8: 고객 마스터
  PERFORM f_get_knvv.       " STEP9: 고객 영업 데이터
  PERFORM f_get_py_amt.     " STEP10: 전년동기 실적 조회

  PERFORM f_merge_data.     " STEP11: 데이터 통합 및 계산

  " 저장 옵션
  IF p_save = 'X'.
    PERFORM f_save_ztable.
  ENDIF.

*----------------------------------------------------------------------*
* END-OF-SELECTION
*----------------------------------------------------------------------*
END-OF-SELECTION.
  PERFORM f_show_alv.

*----------------------------------------------------------------------*
* FORM: STEP1 - VBAK 판매 오더 헤더 조회
*----------------------------------------------------------------------*
FORM f_get_vbak.
  REFRESH gt_vbak.

  " 청구완료 여부에 따른 필터 (의도적으로 복잡한 조건)
  SELECT vbeln erdat audat vkorg vtweg spart kunnr kunag gbstk waers netwr knumv
    INTO TABLE gt_vbak
    FROM vbak
    WHERE audat IN s_audat
      AND vkorg IN s_vkorg
      AND vtweg IN s_vtweg
      AND spart IN s_spart
      AND kunnr IN s_kunnr
      AND auart = p_auart
      AND ( gbstk = 'C' OR gbstk = 'B' OR gbstk = ' ' )
      AND vbtyp = 'C'.   " 판매오더만

  IF sy-subrc <> 0.
    MESSAGE s003(zmsd) WITH '조건에 맞는 판매 오더가 없습니다.'.
    RETURN.
  ENDIF.

  " 거부된 오더 제거 (ABGRU 있는 헤더는 별도 VBAK 필드 없으므로 아이템에서 처리)
  DESCRIBE TABLE gt_vbak LINES gv_lines.
  MESSAGE s004(zmsd) WITH gv_lines '건의 판매오더 헤더 조회 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP2 - VBAP 판매 오더 아이템 조회
*----------------------------------------------------------------------*
FORM f_get_vbap.
  REFRESH gt_vbap.

  " VBAK에서 조회된 오더번호 범위로 VBAP 조회
  " 의도적으로 비효율적인 루프 방식 사용 (워크샵 시연용)
  DATA: lt_vbeln TYPE RANGE OF vbeln_va,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbak INTO gs_vbak.
    ls_vbeln-sign   = 'I'.
    ls_vbeln-option = 'EQ'.
    ls_vbeln-low    = gs_vbak-vbeln.
    APPEND ls_vbeln TO lt_vbeln.
  ENDLOOP.

  SELECT vbeln posnr matnr matkl mtart arktx meins vrkme kwmeng netwr waers abgru gbsta
    INTO TABLE gt_vbap
    FROM vbap
    WHERE vbeln IN lt_vbeln
      AND matnr IN s_matnr
      AND matkl IN s_matkl
      AND abgru = ' '.     " 거부되지 않은 아이템만

  " 자재 추가 필터 처리 (IN 조건으로 처리 안된 케이스 재필터)
  DELETE gt_vbap WHERE matnr NOT IN s_matnr.
  DELETE gt_vbap WHERE matkl NOT IN s_matkl.

  DESCRIBE TABLE gt_vbap LINES gv_lines.
  MESSAGE s005(zmsd) WITH gv_lines '건의 판매오더 아이템 조회 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP3 - VBFA 문서 흐름 조회 (오더→납품→청구)
*----------------------------------------------------------------------*
FORM f_get_vbfa.
  REFRESH gt_vbfa.

  DATA: lt_vbeln TYPE RANGE OF vbeln_va,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbap INTO DATA(ls_vbap).
    ls_vbeln-sign   = 'I'.
    ls_vbeln-option = 'EQ'.
    ls_vbeln-low    = ls_vbap-vbeln.
    COLLECT ls_vbeln INTO lt_vbeln.
  ENDLOOP.

  " 납품문서 흐름
  SELECT vbelv posnv vbeln posnn vbtyp_n
    INTO TABLE gt_vbfa
    FROM vbfa
    WHERE vbelv IN lt_vbeln
      AND ( vbtyp_n = 'J'    " 납품
         OR vbtyp_n = 'M' ). " 청구

  DESCRIBE TABLE gt_vbfa LINES gv_lines.
  MESSAGE s006(zmsd) WITH gv_lines '건의 문서흐름 조회 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP4 - VBRP 청구 아이템 조회
*----------------------------------------------------------------------*
FORM f_get_vbrp.
  REFRESH gt_vbrp.

  DATA: lt_vbreln TYPE RANGE OF vbeln_vf,
        ls_vbreln LIKE LINE OF lt_vbreln.

  " VBFA에서 청구 문서번호 수집
  LOOP AT gt_vbfa INTO DATA(ls_vbfa) WHERE vbtyp_n = 'M'.
    ls_vbreln-sign   = 'I'.
    ls_vbreln-option = 'EQ'.
    ls_vbreln-low    = ls_vbfa-vbeln.
    COLLECT ls_vbreln INTO lt_vbreln.
  ENDLOOP.

  CHECK lt_vbreln IS NOT INITIAL.

  SELECT vbeln posnr aubel aupos fkimg netwr mwsbp
    INTO TABLE gt_vbrp
    FROM vbrp
    WHERE vbeln IN lt_vbreln.

  DESCRIBE TABLE gt_vbrp LINES gv_lines.
  MESSAGE s007(zmsd) WITH gv_lines '건의 청구 아이템 조회 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP5 - LIPS 납품 아이템 조회
*----------------------------------------------------------------------*
FORM f_get_lips.
  REFRESH gt_lips.

  DATA: lt_liefn TYPE RANGE OF vbeln_vl,
        ls_liefn LIKE LINE OF lt_liefn.

  LOOP AT gt_vbfa INTO DATA(ls_vbfa) WHERE vbtyp_n = 'J'.
    ls_liefn-sign   = 'I'.
    ls_liefn-option = 'EQ'.
    ls_liefn-low    = ls_vbfa-vbeln.
    COLLECT ls_liefn INTO lt_liefn.
  ENDLOOP.

  CHECK lt_liefn IS NOT INITIAL.

  SELECT vbeln posnr vgbel vgpos lfimg meins
    INTO TABLE gt_lips
    FROM lips
    WHERE vbeln IN lt_liefn.

  DESCRIBE TABLE gt_lips LINES gv_lines.
  MESSAGE s008(zmsd) WITH gv_lines '건의 납품 아이템 조회 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP6 - KONV 가격조건 조회 (PR00, K004, KA00, MWST 등)
*----------------------------------------------------------------------*
FORM f_get_konv.
  REFRESH gt_konv.

  DATA: lt_knumv TYPE RANGE OF knumv,
        ls_knumv LIKE LINE OF lt_knumv.

  LOOP AT gt_vbak INTO gs_vbak.
    CHECK gs_vbak-knumv IS NOT INITIAL.
    ls_knumv-sign   = 'I'.
    ls_knumv-option = 'EQ'.
    ls_knumv-low    = gs_vbak-knumv.
    COLLECT ls_knumv INTO lt_knumv.
  ENDLOOP.

  CHECK lt_knumv IS NOT INITIAL.

  " 주요 가격 조건 유형만 조회
  SELECT knumv kposn kschl kbetr kwert kkurs waers loevm_ko
    INTO TABLE gt_konv
    FROM konv
    WHERE knumv IN lt_knumv
      AND kschl IN ('PR00', 'K004', 'K005', 'KA00', 'HA00', 'MWST', 'SKTO')
      AND loevm_ko = ' '.   " 삭제 안 된 것만

  DESCRIBE TABLE gt_konv LINES gv_lines.
  MESSAGE s009(zmsd) WITH gv_lines '건의 가격조건 조회 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP7 - MBEW 자재평가 조회 (원가 산출용)
*----------------------------------------------------------------------*
FORM f_get_mbew.
  REFRESH gt_mbew.

  DATA: lt_matnr TYPE RANGE OF matnr,
        ls_matnr LIKE LINE OF lt_matnr.

  LOOP AT gt_vbap INTO DATA(ls_vbap).
    ls_matnr-sign   = 'I'.
    ls_matnr-option = 'EQ'.
    ls_matnr-low    = ls_vbap-matnr.
    COLLECT ls_matnr INTO lt_matnr.
  ENDLOOP.

  CHECK lt_matnr IS NOT INITIAL.

  " 현재 기간의 이동평균/표준원가 조회
  SELECT matnr bwkey vprsv verpr stprs peinh bklas
    INTO TABLE gt_mbew
    FROM mbew
    WHERE matnr IN lt_matnr
      AND bwval = ' '.   " 현재 기간 (공백 = 현재)

  DESCRIBE TABLE gt_mbew LINES gv_lines.
  MESSAGE s010(zmsd) WITH gv_lines '건의 자재평가 조회 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP8 - KNA1 고객 마스터 조회
*----------------------------------------------------------------------*
FORM f_get_kna1.
  REFRESH gt_kna1.

  DATA: lt_kunnr TYPE RANGE OF kunnr,
        ls_kunnr LIKE LINE OF lt_kunnr.

  LOOP AT gt_vbak INTO gs_vbak.
    ls_kunnr-sign   = 'I'.
    ls_kunnr-option = 'EQ'.
    ls_kunnr-low    = gs_vbak-kunnr.
    COLLECT ls_kunnr INTO lt_kunnr.
  ENDLOOP.

  CHECK lt_kunnr IS NOT INITIAL.

  SELECT kunnr name1 ktokd land1 regio
    INTO TABLE gt_kna1
    FROM kna1
    WHERE kunnr IN lt_kunnr.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP9 - KNVV 고객 영업 데이터
*----------------------------------------------------------------------*
FORM f_get_knvv.
  REFRESH gt_knvv.

  DATA: lt_kunnr TYPE RANGE OF kunnr,
        ls_kunnr LIKE LINE OF lt_kunnr.

  LOOP AT gt_vbak INTO gs_vbak.
    ls_kunnr-sign   = 'I'.
    ls_kunnr-option = 'EQ'.
    ls_kunnr-low    = gs_vbak-kunnr.
    COLLECT ls_kunnr INTO lt_kunnr.
  ENDLOOP.

  CHECK lt_kunnr IS NOT INITIAL.

  SELECT kunnr vkorg vtweg spart kdgrp kalks
    INTO TABLE gt_knvv
    FROM knvv
    WHERE kunnr IN lt_kunnr
      AND vkorg IN s_vkorg.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP10 - 전년동기 실적 조회 (ZSDT_SELLIN에서 GROUP BY)
*----------------------------------------------------------------------*
FORM f_get_py_amt.
  REFRESH gt_py_amt.

  " 선택 기간의 전년도 계산
  DATA: lv_py_low  TYPE spmon,
        lv_py_high TYPE spmon.

  " AUDAT 범위에서 년월 추출 (저장된 ZSDT_SELLIN에서 전년 조회)
  IF s_audat-low IS NOT INITIAL.
    lv_py_low = s_audat-low(6).
    lv_py_low+0(4) = lv_py_low+0(4) - 1.
  ENDIF.
  IF s_audat-high IS NOT INITIAL.
    lv_py_high = s_audat-high(6).
    lv_py_high+0(4) = lv_py_high+0(4) - 1.
  ENDIF.

  CHECK lv_py_low IS NOT INITIAL.

  " 단일 테이블에서 GROUP BY 집계로 전년동기 금액 조회
  SELECT vkorg kunnr matnr spart matkl spmon SUM( netwr ) AS net_amt
    INTO TABLE gt_py_amt
    FROM zsdt_sellin
    WHERE vkorg IN s_vkorg
      AND kunnr IN s_kunnr
      AND spmon BETWEEN lv_py_low AND lv_py_high
    GROUP BY vkorg kunnr matnr spart matkl spmon.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP11 - 데이터 통합 및 계산 (핵심 로직 - 복잡한 부분)
*----------------------------------------------------------------------*
FORM f_merge_data.
  REFRESH gt_sellin.

  DATA:
    ls_vbfa   TYPE ty_vbfa_sel,
    ls_lips   TYPE ty_lips_sel,
    lv_dlv_qty TYPE menge_d,
    lv_bil_qty TYPE menge_d,
    lv_pr00   TYPE kbetr,
    lv_disc   TYPE wertv8,
    lv_mwst   TYPE p DECIMALS 4,
    lv_cogs   TYPE wertv8,
    lv_net_lc TYPE wertv8,
    lv_cogs_lc TYPE wertv8,
    lv_exc_rate TYPE p DECIMALS 5,
    lv_spmon  TYPE spmon,
    lv_gjahr  TYPE gjahr.

  " 오더 헤더 루프
  LOOP AT gt_vbak INTO gs_vbak.

    " 해당 헤더의 아이템들 처리
    LOOP AT gt_vbap INTO DATA(ls_vbap) WHERE vbeln = gs_vbak-vbeln.

      CLEAR gs_sellin.

      " ── 기본 정보 설정 ──────────────────────────────────────
      gs_sellin-vkorg  = gs_vbak-vkorg.
      gs_sellin-vtweg  = gs_vbak-vtweg.
      gs_sellin-spart  = gs_vbak-spart.
      gs_sellin-vbeln  = gs_vbak-vbeln.
      gs_sellin-posnr  = ls_vbap-posnr.
      gs_sellin-audat  = gs_vbak-audat.
      gs_sellin-kunnr  = gs_vbak-kunnr.
      gs_sellin-matnr  = ls_vbap-matnr.
      gs_sellin-arktx  = ls_vbap-arktx.
      gs_sellin-matkl  = ls_vbap-matkl.
      gs_sellin-mtart  = ls_vbap-mtart.
      gs_sellin-meins  = ls_vbap-meins.
      gs_sellin-vrkme  = ls_vbap-vrkme.
      gs_sellin-waers  = gs_vbak-waers.
      gs_sellin-ord_qty = ls_vbap-kwmeng.
      gs_sellin-netwr  = ls_vbap-netwr.

      " ── 기간(YYYYMM) 계산 ───────────────────────────────────
      gs_sellin-spmon  = gs_vbak-audat(6).
      gs_sellin-gjahr  = gs_vbak-audat(4).

      " ── 고객 정보 매핑 ──────────────────────────────────────
      READ TABLE gt_kna1 INTO gs_kna1 WITH KEY kunnr = gs_vbak-kunnr.
      IF sy-subrc = 0.
        gs_sellin-kunnr_name = gs_kna1-name1.
      ENDIF.

      " ── 납품 수량 계산 (VBFA → LIPS) ───────────────────────
      CLEAR lv_dlv_qty.
      LOOP AT gt_vbfa INTO ls_vbfa
        WHERE vbelv = gs_vbak-vbeln
          AND posnv = ls_vbap-posnr
          AND vbtyp_n = 'J'.

        READ TABLE gt_lips INTO ls_lips
          WITH KEY vbeln = ls_vbfa-vbeln
                   posnr = ls_vbfa-posnn.
        IF sy-subrc = 0.
          lv_dlv_qty = lv_dlv_qty + ls_lips-lfimg.
          IF gs_sellin-lips_vl IS INITIAL.
            gs_sellin-lips_vl = ls_lips-vbeln.
          ENDIF.
        ENDIF.
      ENDLOOP.
      gs_sellin-dlv_qty = lv_dlv_qty.

      " ── 청구 수량/금액 계산 (VBFA → VBRP) ──────────────────
      CLEAR lv_bil_qty.
      LOOP AT gt_vbfa INTO ls_vbfa
        WHERE vbelv = gs_vbak-vbeln
          AND posnv = ls_vbap-posnr
          AND vbtyp_n = 'M'.

        READ TABLE gt_vbrp INTO gs_vbrp
          WITH KEY vbeln = ls_vbfa-vbeln
                   posnr = ls_vbfa-posnn.
        IF sy-subrc = 0.
          lv_bil_qty = lv_bil_qty + gs_vbrp-fkimg.
          IF gs_sellin-vbreln IS INITIAL.
            gs_sellin-vbreln = gs_vbrp-vbeln.
            gs_sellin-vbrelp = gs_vbrp-posnr.
          ENDIF.
        ENDIF.
      ENDLOOP.
      gs_sellin-bil_qty = lv_bil_qty.

      " ── 납품율/청구율 계산 ──────────────────────────────────
      IF gs_sellin-ord_qty > 0.
        gs_sellin-dlv_rate = ( gs_sellin-dlv_qty / gs_sellin-ord_qty ) * 100.
        gs_sellin-bil_rate = ( gs_sellin-bil_qty / gs_sellin-ord_qty ) * 100.
      ENDIF.

      " ── 가격조건 분석 (KONV) ────────────────────────────────
      CLEAR: lv_pr00, lv_disc, lv_mwst.

      " 아이템 번호를 KONV kposn 형식으로 변환 (6자리 → 6자리)
      DATA(lv_kposn) = CONV kposn( ls_vbap-posnr ).

      " PR00: 정가
      READ TABLE gt_konv INTO gs_konv
        WITH KEY knumv = gs_vbak-knumv
                 kposn = lv_kposn
                 kschl = 'PR00'.
      IF sy-subrc = 0.
        lv_pr00 = gs_konv-kbetr.
        gs_sellin-pr00_kbetr = lv_pr00.
      ENDIF.

      " 할인 조건 합산 (K004, K005, KA00, HA00)
      LOOP AT gt_konv INTO gs_konv
        WHERE knumv = gs_vbak-knumv
          AND kposn = lv_kposn
          AND kschl IN ('K004', 'K005', 'KA00', 'HA00').
        lv_disc = lv_disc + gs_konv-kwert.
      ENDLOOP.
      gs_sellin-disc_amt = ABS( lv_disc ).

      " MWST: 세율
      READ TABLE gt_konv INTO gs_konv
        WITH KEY knumv = gs_vbak-knumv
                 kposn = lv_kposn
                 kschl = 'MWST'.
      IF sy-subrc = 0.
        lv_mwst = gs_konv-kbetr / 100.
        gs_sellin-mwst_rate = gs_konv-kbetr.
        gs_sellin-tax_amt = gs_sellin-netwr * lv_mwst.
      ENDIF.

      " 할인율 계산
      IF gs_sellin-netwr + gs_sellin-disc_amt > 0.
        gs_sellin-disc_rate = gs_sellin-disc_amt
                            / ( gs_sellin-netwr + gs_sellin-disc_amt )
                            * 100.
      ENDIF.

      " ── 매출원가 계산 (MBEW) ─────────────────────────────────
      CLEAR lv_cogs.
      READ TABLE gt_mbew INTO gs_mbew WITH KEY matnr = ls_vbap-matnr.
      IF sy-subrc = 0.
        CASE gs_mbew-vprsv.
          WHEN 'V'.   " 이동평균가
            IF gs_mbew-peinh > 0.
              lv_cogs = ( gs_mbew-verpr / gs_mbew-peinh )
                      * gs_sellin-bil_qty.
            ENDIF.
          WHEN 'S'.   " 표준원가
            IF gs_mbew-peinh > 0.
              lv_cogs = ( gs_mbew-stprs / gs_mbew-peinh )
                      * gs_sellin-bil_qty.
            ENDIF.
          WHEN OTHERS.
            lv_cogs = 0.
        ENDCASE.
        gs_sellin-cogs = lv_cogs.
      ENDIF.

      " ── 마진 계산 ────────────────────────────────────────────
      gs_sellin-margin = gs_sellin-netwr - gs_sellin-cogs.
      IF gs_sellin-netwr > 0.
        gs_sellin-margin_rate = ( gs_sellin-margin / gs_sellin-netwr ) * 100.
      ENDIF.

      " ── 통화 환산 (로컬 통화로) ─────────────────────────────
      IF gs_vbak-waers <> p_waers.
        CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
          EXPORTING
            date             = gs_vbak-audat
            foreign_amount   = gs_sellin-netwr
            foreign_currency = gs_vbak-waers
            local_currency   = p_waers
          IMPORTING
            local_amount     = lv_net_lc
          EXCEPTIONS
            no_rate_found    = 1
            overflow         = 2
            no_factors_found = 3
            OTHERS           = 4.
        IF sy-subrc = 0.
          gs_sellin-net_lc = lv_net_lc.
        ELSE.
          gs_sellin-net_lc = gs_sellin-netwr.
        ENDIF.

        CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
          EXPORTING
            date             = gs_vbak-audat
            foreign_amount   = gs_sellin-cogs
            foreign_currency = gs_vbak-waers
            local_currency   = p_waers
          IMPORTING
            local_amount     = lv_cogs_lc
          EXCEPTIONS
            OTHERS           = 1.
        IF sy-subrc = 0.
          gs_sellin-cogs_lc = lv_cogs_lc.
        ELSE.
          gs_sellin-cogs_lc = gs_sellin-cogs.
        ENDIF.
      ELSE.
        gs_sellin-net_lc  = gs_sellin-netwr.
        gs_sellin-cogs_lc = gs_sellin-cogs.
      ENDIF.
      gs_sellin-margin_lc = gs_sellin-net_lc - gs_sellin-cogs_lc.
      gs_sellin-lwaers    = p_waers.

      " ── 전년동기 매핑 ─────────────────────────────────────────
      DATA(lv_py_spmon) = gs_sellin-spmon.
      lv_py_spmon+0(4) = lv_py_spmon+0(4) - 1.

      READ TABLE gt_py_amt INTO DATA(ls_py)
        WITH KEY vkorg = gs_sellin-vkorg
                 kunnr = gs_sellin-kunnr
                 matnr = gs_sellin-matnr
                 spmon = lv_py_spmon.
      IF sy-subrc = 0.
        gs_sellin-py_amt = ls_py-net_amt.
        IF gs_sellin-py_amt > 0.
          gs_sellin-achv_rate = ( gs_sellin-net_lc / gs_sellin-py_amt ) * 100.
        ENDIF.
      ENDIF.

      " ── 신호등 설정 ───────────────────────────────────────────
      CASE gs_sellin-bil_rate.
        WHEN 0 TO 49.     gs_sellin-traffic = 'R'. " 적색: 50% 미만
        WHEN 50 TO 79.    gs_sellin-traffic = 'Y'. " 황색: 50~80%
        WHEN 80 TO 999.   gs_sellin-traffic = 'G'. " 녹색: 80% 이상
        WHEN OTHERS.      gs_sellin-traffic = ' '.
      ENDCASE.

      APPEND gs_sellin TO gt_sellin.

    ENDLOOP.  " gt_vbap
  ENDLOOP.    " gt_vbak

  DESCRIBE TABLE gt_sellin LINES gv_lines.
  MESSAGE s011(zmsd) WITH gv_lines '건의 Sell-In 데이터 생성 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: Z-Table 저장 (단일 테이블 ZSDT_SELLIN)
*----------------------------------------------------------------------*
FORM f_save_ztable.
  DATA:
    lt_sellin_db TYPE STANDARD TABLE OF zsdt_sellin,
    ls_sellin_db TYPE zsdt_sellin.

  CLEAR: gv_save_cnt, gv_err_cnt.

  " ── 기존 데이터 삭제 (선택 기간 범위) ──────────────────────
  IF p_delold = 'X'.
    DATA(lv_spmon_low)  = CONV spmon( s_audat-low(6)  ).
    DATA(lv_spmon_high) = CONV spmon( s_audat-high(6) ).

    DELETE FROM zsdt_sellin
      WHERE vkorg IN s_vkorg
        AND spmon BETWEEN lv_spmon_low AND lv_spmon_high.
  ENDIF.

  " ── 단일 테이블 저장 (아이템 단위, 집계는 SELECT GROUP BY로) ─
  LOOP AT gt_sellin INTO gs_sellin.
    CLEAR ls_sellin_db.
    ls_sellin_db-mandt       = sy-mandt.
    ls_sellin_db-vbeln       = gs_sellin-vbeln.
    ls_sellin_db-posnr       = gs_sellin-posnr.
    ls_sellin_db-vkorg       = gs_sellin-vkorg.
    ls_sellin_db-kunnr       = gs_sellin-kunnr.
    ls_sellin_db-matnr       = gs_sellin-matnr.
    ls_sellin_db-spart       = gs_sellin-spart.
    ls_sellin_db-matkl       = gs_sellin-matkl.
    ls_sellin_db-gjahr       = gs_sellin-gjahr.
    ls_sellin_db-spmon       = gs_sellin-spmon.
    ls_sellin_db-audat       = gs_sellin-audat.
    ls_sellin_db-waers       = gs_sellin-lwaers.
    ls_sellin_db-ord_qty     = gs_sellin-ord_qty.
    ls_sellin_db-dlv_qty     = gs_sellin-dlv_qty.
    ls_sellin_db-bil_qty     = gs_sellin-bil_qty.
    ls_sellin_db-dlv_rate    = gs_sellin-dlv_rate.
    ls_sellin_db-bil_rate    = gs_sellin-bil_rate.
    ls_sellin_db-netwr       = gs_sellin-net_lc.
    ls_sellin_db-disc_amt    = gs_sellin-disc_amt.
    ls_sellin_db-cogs        = gs_sellin-cogs_lc.
    ls_sellin_db-margin      = gs_sellin-margin_lc.
    ls_sellin_db-disc_rate   = gs_sellin-disc_rate.
    ls_sellin_db-margin_rate = gs_sellin-margin_rate.
    ls_sellin_db-pr00_kbetr  = gs_sellin-pr00_kbetr.
    ls_sellin_db-mwst_rate   = gs_sellin-mwst_rate.
    ls_sellin_db-py_amt      = gs_sellin-py_amt.
    ls_sellin_db-achv_rate   = gs_sellin-achv_rate.
    ls_sellin_db-vbreln      = gs_sellin-vbreln.
    ls_sellin_db-vbrelp      = gs_sellin-vbrelp.
    ls_sellin_db-lips_vl     = gs_sellin-lips_vl.
    ls_sellin_db-erdat       = sy-datum.
    ls_sellin_db-ernam       = sy-uname.
    APPEND ls_sellin_db TO lt_sellin_db.
  ENDLOOP.

  " ── DB INSERT ───────────────────────────────────────────────
  INSERT zsdt_sellin FROM TABLE lt_sellin_db.
  IF sy-subrc = 0.
    gv_save_cnt = lines( lt_sellin_db ).
  ELSE.
    gv_err_cnt  = lines( lt_sellin_db ).
    MESSAGE w012(zmsd) WITH 'ZSDT_SELLIN 저장 중 오류 발생'.
  ENDIF.

  COMMIT WORK AND WAIT.

  MESSAGE s014(zmsd) WITH gv_save_cnt '건 ZSDT_SELLIN 저장 완료 (오류:' gv_err_cnt ')'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: ALV 출력
*----------------------------------------------------------------------*
FORM f_show_alv.

  " ── FieldCat 구성 ────────────────────────────────────────────
  DEFINE m_fieldcat.
    CLEAR gs_fieldcat.
    gs_fieldcat-fieldname  = &1.
    gs_fieldcat-coltext    = &2.
    gs_fieldcat-outputlen  = &3.
    gs_fieldcat-just       = &4.
    gs_fieldcat-do_sum     = &5.
    APPEND gs_fieldcat TO gt_fieldcat.
  END-OF-DEFINITION.

  m_fieldcat 'TRAFFIC'      '상태'        3  'C' ' '.
  m_fieldcat 'VKORG'        '영업조직'     4  'C' ' '.
  m_fieldcat 'SPART'        '제품군'       4  'C' ' '.
  m_fieldcat 'MATKL'        '자재그룹'     9  'C' ' '.
  m_fieldcat 'KUNNR'        '고객코드'    10  'C' ' '.
  m_fieldcat 'KUNNR_NAME'   '고객명'      20  'L' ' '.
  m_fieldcat 'MATNR'        '자재번호'    18  'L' ' '.
  m_fieldcat 'ARKTX'        '자재명'      20  'L' ' '.
  m_fieldcat 'SPMON'        '기간'         6  'C' ' '.
  m_fieldcat 'VBELN'        '오더번호'    10  'C' ' '.
  m_fieldcat 'POSNR'        '아이템'       6  'C' ' '.
  m_fieldcat 'AUDAT'        '오더일'       8  'C' ' '.
  m_fieldcat 'WAERS'        '통화'         5  'C' ' '.
  m_fieldcat 'ORD_QTY'      '오더수량'    13  'R' 'X'.
  m_fieldcat 'DLV_QTY'      '납품수량'    13  'R' 'X'.
  m_fieldcat 'BIL_QTY'      '청구수량'    13  'R' 'X'.
  m_fieldcat 'DLV_RATE'     '납품율%'      8  'R' ' '.
  m_fieldcat 'BIL_RATE'     '청구율%'      8  'R' ' '.
  m_fieldcat 'PR00_KBETR'   '정가단가'    13  'R' ' '.
  m_fieldcat 'DISC_RATE'    '할인율%'      8  'R' ' '.
  m_fieldcat 'DISC_AMT'     '할인금액'    15  'R' 'X'.
  m_fieldcat 'MWST_RATE'    '세율%'        7  'R' ' '.
  m_fieldcat 'TAX_AMT'      '세액'        15  'R' 'X'.
  m_fieldcat 'NETWR'        '순매출(오더)' 15  'R' 'X'.
  m_fieldcat 'LWAERS'       '환산통화'     5  'C' ' '.
  m_fieldcat 'NET_LC'       '순매출(로컬)' 15  'R' 'X'.
  m_fieldcat 'COGS_LC'      '매출원가'    15  'R' 'X'.
  m_fieldcat 'MARGIN_LC'    '마진금액'    15  'R' 'X'.
  m_fieldcat 'MARGIN_RATE'  '마진율%'      8  'R' ' '.
  m_fieldcat 'PY_AMT'       '전년동기'    15  'R' 'X'.
  m_fieldcat 'ACHV_RATE'    '달성율%'      8  'R' ' '.
  m_fieldcat 'LIPS_VL'      '납품번호'    10  'C' ' '.
  m_fieldcat 'VBRELN'       '청구번호'    10  'C' ' '.

  " ── 신호등 컬럼 설정 ─────────────────────────────────────────
  READ TABLE gt_fieldcat INTO gs_fieldcat WITH KEY fieldname = 'TRAFFIC'.
  IF sy-subrc = 0.
    gs_fieldcat-icon     = 'X'.
    gs_fieldcat-no_sum   = 'X'.
    MODIFY gt_fieldcat FROM gs_fieldcat INDEX sy-tabix.
  ENDIF.

  " ── Layout 설정 ───────────────────────────────────────────────
  gs_layout-zebra        = 'X'.
  gs_layout-cwidth_opt   = 'X'.
  gs_layout-totals_bef   = ' '.
  gs_layout-grid_title   = '【Sell-In 실적현황】'.

  " ── Sort 설정 ─────────────────────────────────────────────────
  CLEAR gs_sort.
  gs_sort-fieldname = 'VKORG'. gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.
  gs_sort-fieldname = 'KUNNR'. gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.
  gs_sort-fieldname = 'SPMON'. gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.

  " ── ALV 출력 ──────────────────────────────────────────────────
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_user_command  = 'CB_USER_COMMAND'
      is_layout_lvc            = gs_layout
      it_fieldcat_lvc          = gt_fieldcat
      it_sort_lvc              = gt_sort
      i_save                   = 'A'
      is_variant               = gs_variant
    TABLES
      t_outtab                 = gt_sellin
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE e015(zmsd) WITH 'ALV 출력 오류 발생'.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* ALV 사용자 커맨드 콜백
*----------------------------------------------------------------------*
FORM cb_user_command USING r_ucomm     TYPE sy-ucomm
                           rs_selfield TYPE slis_selfield.
  CASE r_ucomm.
    WHEN 'SAVE'.
      PERFORM f_save_ztable.
    WHEN 'DETAIL'.
      " 선택된 행 상세 팝업 (추가 구현 가능)
      MESSAGE i016(zmsd) WITH '상세 조회 기능은 추후 구현 예정'.
  ENDCASE.
ENDFORM.
