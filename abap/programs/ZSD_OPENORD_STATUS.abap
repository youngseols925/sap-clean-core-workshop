*&---------------------------------------------------------------------*
*& Report  ZSD_OPENORD_STATUS
*& Open Order 진행현황 조회 및 Z-Table 저장 프로그램
*& 목적: 워크샵 시연용 - ERP 리소스를 많이 사용하는 CBO 프로그램 예시
*&---------------------------------------------------------------------*
REPORT zsd_openord_status
  LINE-SIZE 255
  LINE-COUNT 65
  MESSAGE-ID zmsd.

*----------------------------------------------------------------------*
* 타입 정의
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_openord,
    " ── 오더 기본 ──────────────────────────────────────────────
    vbeln        TYPE vbeln_va,    " 판매 오더 번호
    posnr        TYPE posnr_va,    " 오더 아이템
    auart        TYPE auart,       " 오더 유형
    audat        TYPE audat,       " 오더 생성일
    audat_ym     TYPE spmon,       " 오더 생성년월
    elapsed_days TYPE i,           " 오더 생성 후 경과일수
    aging_grp    TYPE char3,       " Aging 구간 (030/060/090/090+)
    " ── 영업 조직 ──────────────────────────────────────────────
    vkorg        TYPE vkorg,       " 영업 조직
    vtweg        TYPE vtweg,       " 유통 경로
    spart        TYPE spart,       " 제품군
    " ── 고객 ────────────────────────────────────────────────────
    kunnr        TYPE kunnr,       " 고객 코드
    kunnr_name   TYPE name1_gp,    " 고객 명
    kdgrp        TYPE kdgrp,       " 고객 그룹
    land1        TYPE land1_gp,    " 국가
    credit_group TYPE knkk-ctlpc,  " 신용 관리 그룹
    klimk        TYPE klimk,       " 신용 한도액
    skfor        TYPE skfor,       " 현재 오픈 금액 (AR)
    credit_exc   TYPE char1,       " 신용 한도 초과 여부 (X)
    " ── 자재 ────────────────────────────────────────────────────
    matnr        TYPE matnr,       " 자재 번호
    arktx        TYPE arktx,       " 자재 설명
    matkl        TYPE matkl,       " 자재 그룹
    mtart        TYPE mtart,       " 자재 유형
    meins        TYPE meins,       " 기본 단위
    vrkme        TYPE vrkme,       " 판매 단위
    " ── 수량 ────────────────────────────────────────────────────
    ord_qty      TYPE menge_d,     " 오더 수량
    conf_qty     TYPE menge_d,     " 납품 확정 수량 (VBEP.BMENG)
    open_qty     TYPE menge_d,     " 미납품 잔량
    dlv_qty      TYPE menge_d,     " 실납품 수량 (LIPS)
    bil_qty      TYPE menge_d,     " 청구 수량
    dlv_rate     TYPE p DECIMALS 2," 납품율(%)
    bil_rate     TYPE p DECIMALS 2," 청구율(%)
    " ── 금액 ────────────────────────────────────────────────────
    waers        TYPE waers,       " 오더 통화
    ord_amt      TYPE wertv8,      " 오더 금액
    dlv_amt      TYPE wertv8,      " 납품 금액
    bil_amt      TYPE wertv8,      " 청구 금액
    open_amt     TYPE wertv8,      " 미결 금액 (오더 - 청구)
    " ── 납품 일정 ───────────────────────────────────────────────
    edatu        TYPE edatu,       " 납품 예정일 (VBEP 최초)
    lddat        TYPE lddat,       " 최종납품일
    wbs_delay    TYPE char1,       " 납품 지연 여부 (X)
    delay_days   TYPE i,           " 지연 일수
    " ── 상태 ────────────────────────────────────────────────────
    gbstk        TYPE gbstk,       " 전체 처리 상태
    dlv_stat     TYPE char1,       " 납품 상태 (A:미납/B:부분납/C:완납)
    bil_stat     TYPE char1,       " 청구 상태 (A:미청구/B:부분청구/C:완료)
    " ── 신호등 ──────────────────────────────────────────────────
    traffic      TYPE char1,       " G/Y/R
  END OF ty_openord,

  BEGIN OF ty_vbep_sel,
    vbeln TYPE vbeln_va,
    posnr TYPE posnr_va,
    etenr TYPE etenr,
    edatu TYPE edatu,
    lddat TYPE lddat,
    bmeng TYPE bmeng,
    wmeng TYPE wmeng,
  END OF ty_vbep_sel,

  BEGIN OF ty_knkk_sel,
    kunnr TYPE kunnr,
    kkber TYPE kkber,
    ctlpc TYPE knkk-ctlpc,
    klimk TYPE klimk,
    skfor TYPE skfor,
    ssobl TYPE ssobl,
  END OF ty_knkk_sel,

  " Aging 집계용
  BEGIN OF ty_aging_summary,
    vkorg    TYPE vkorg,
    spart    TYPE spart,
    kunnr    TYPE kunnr,
    aging030 TYPE wertv8,  " 30일 이하
    aging060 TYPE wertv8,  " 31~60일
    aging090 TYPE wertv8,  " 61~90일
    aging90p TYPE wertv8,  " 90일 초과
    total    TYPE wertv8,
  END OF ty_aging_summary.

*----------------------------------------------------------------------*
* 내부 테이블 선언
*----------------------------------------------------------------------*
DATA:
  gt_openord    TYPE STANDARD TABLE OF ty_openord,
  gt_vbep       TYPE STANDARD TABLE OF ty_vbep_sel,
  gt_knkk       TYPE STANDARD TABLE OF ty_knkk_sel,
  gt_aging      TYPE STANDARD TABLE OF ty_aging_summary,
  gs_openord    TYPE ty_openord,
  gv_lines      TYPE i,
  gv_save_cnt   TYPE i.

" VBAK/VBAP/VBFA/LIPS/VBRP/KONV/KNA1 - 이전 프로그램과 동일 구조 재선언
TYPES:
  BEGIN OF ty_vbak2,
    vbeln TYPE vbeln_va,
    erdat TYPE erdat,
    audat TYPE audat,
    auart TYPE auart,
    vkorg TYPE vkorg,
    vtweg TYPE vtweg,
    spart TYPE spart,
    kunnr TYPE kunnr,
    waerk TYPE waerk,
    netwr TYPE netwr_ap,
    knumv TYPE knumv,
  END OF ty_vbak2,

  BEGIN OF ty_vbap2,
    vbeln  TYPE vbeln_va,
    posnr  TYPE posnr_va,
    matnr  TYPE matnr,
    matkl  TYPE matkl,
    arktx  TYPE arktx,
    meins  TYPE meins,
    vrkme  TYPE vrkme,
    kwmeng TYPE kwmeng,
    netwr  TYPE netwr_ap,
    waers  TYPE waers,
    abgru  TYPE abgru,
  END OF ty_vbap2,
  BEGIN OF ty_vbfa_sel,
    vbelv   TYPE vbfa-vbelv,
    posnv   TYPE vbfa-posnv,
    vbeln   TYPE vbfa-vbeln,
    posnn   TYPE vbfa-posnn,
    vbtyp_n TYPE vbfa-vbtyp_n,
  END OF ty_vbfa_sel,

  BEGIN OF ty_lips_sel,
    vbeln TYPE lips-vbeln,
    posnr TYPE lips-posnr,
    vgbel TYPE lips-vgbel,
    vgpos TYPE lips-vgpos,
    lfimg TYPE lips-lfimg,
    meins TYPE lips-meins,
  END OF ty_lips_sel,

  BEGIN OF ty_vbrp_sel,
    vbeln TYPE vbrp-vbeln,
    posnr TYPE vbrp-posnr,
    aubel TYPE vbrp-aubel,
    aupos TYPE vbrp-aupos,
    fkimg TYPE vbrp-fkimg,
    netwr TYPE vbrp-netwr,
    mwsbp TYPE vbrp-mwsbp,
  END OF ty_vbrp_sel,

  BEGIN OF ty_konv_sel,
    knumv    TYPE konv-knumv,
    kposn    TYPE konv-kposn,
    kschl    TYPE konv-kschl,
    kbetr    TYPE konv-kbetr,
    kwert    TYPE konv-kwert,
    kkurs    TYPE konv-kkurs,
    waers    TYPE konv-waers,
  END OF ty_konv_sel,

  BEGIN OF ty_kna1_sel,
    kunnr TYPE kna1-kunnr,
    name1 TYPE kna1-name1,
    ktokd TYPE kna1-ktokd,
    land1 TYPE kna1-land1,
    regio TYPE kna1-regio,
  END OF ty_kna1_sel,

  BEGIN OF ty_knvv_sel,
    kunnr TYPE knvv-kunnr,
    vkorg TYPE knvv-vkorg,
    vtweg TYPE knvv-vtweg,
    spart TYPE knvv-spart,
    kdgrp TYPE knvv-kdgrp,
    kalks TYPE knvv-kalks,
  END OF ty_knvv_sel.

DATA:
  gt_vbak2    TYPE STANDARD TABLE OF ty_vbak2,
  gt_vbap2    TYPE STANDARD TABLE OF ty_vbap2,
  gt_vbfa2    TYPE STANDARD TABLE OF ty_vbfa_sel,
  gt_lips2    TYPE STANDARD TABLE OF ty_lips_sel,
  gt_vbrp2    TYPE STANDARD TABLE OF ty_vbrp_sel,
  gt_konv2    TYPE STANDARD TABLE OF ty_konv_sel,
  gt_kna12    TYPE STANDARD TABLE OF ty_kna1_sel,
  gt_knvv2    TYPE STANDARD TABLE OF ty_knvv_sel.

*----------------------------------------------------------------------*
* ALV
*----------------------------------------------------------------------*
DATA:
  go_alv2      TYPE REF TO cl_gui_alv_grid,
  gt_fieldcat2 TYPE lvc_t_fcat,
  gs_fieldcat2 TYPE lvc_s_fcat,
  gs_layout2   TYPE lvc_s_layo,
  gt_sort2     TYPE lvc_t_sort,
  gs_sort2     TYPE lvc_s_sort.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS:
    s_audat  FOR sy-datum   OBLIGATORY,    " 오더 생성일
    s_vkorg  FOR sy-mandt,                            " 영업 조직
    s_vtweg  FOR sy-mandt,                            " 유통 경로
    s_spart  FOR sy-mandt,                            " 제품군
    s_kunnr  FOR sy-mandt,                            " 고객
    s_matnr  FOR sy-mandt,                            " 자재
    s_matkl  FOR sy-mandt,                            " 자재 그룹
    s_auart  FOR sy-mandt.                            " 오더 유형
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_open   TYPE char1 AS CHECKBOX DEFAULT 'X', " 미납품 포함
    p_part   TYPE char1 AS CHECKBOX DEFAULT 'X', " 부분납품 포함
    p_delay  TYPE char1 AS CHECKBOX DEFAULT ' ', " 지연 건만 조회
    p_credit TYPE char1 AS CHECKBOX DEFAULT ' ', " 신용초과 건만
    p_kkber  TYPE kkber                DEFAULT '1000'.      " 신용관리영역
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS:
    p_save   TYPE xfeld AS CHECKBOX,
    p_delold TYPE xfeld AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b3.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF s_audat[] IS INITIAL.
    MESSAGE e001(zmsd) WITH '오더 생성일 기간을 입력하세요.'.
  ENDIF.
  IF p_open = ' ' AND p_part = ' '.
    MESSAGE e002(zmsd) WITH '조회 상태 조건을 최소 1개 이상 선택하세요.'.
  ENDIF.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM f2_get_vbak.       " STEP1: 오더 헤더 (미완료만)
  CHECK gt_vbak2 IS NOT INITIAL.

  PERFORM f2_get_vbap.       " STEP2: 오더 아이템
  CHECK gt_vbap2 IS NOT INITIAL.

  PERFORM f2_get_vbep.       " STEP3: 납품 스케줄 (VBEP - 확정수량, 예정일)
  PERFORM f2_get_vbfa.       " STEP4: 문서 흐름
  PERFORM f2_get_lips.       " STEP5: 납품 아이템
  PERFORM f2_get_vbrp.       " STEP6: 청구 아이템
  PERFORM f2_get_konv.       " STEP7: 가격 조건 (금액 재계산)
  PERFORM f2_get_kna1.       " STEP8: 고객 마스터
  PERFORM f2_get_knvv.       " STEP9: 고객 영업 데이터
  PERFORM f2_get_knkk.       " STEP10: 신용 한도 데이터

  PERFORM f2_merge_data.     " STEP11: 통합 및 계산
  PERFORM f2_filter_result.  " STEP12: 최종 필터 (지연/신용초과 등)

  IF p_save = 'X'.
    PERFORM f2_save_ztable.
  ENDIF.

END-OF-SELECTION.
  PERFORM f2_show_alv.

*----------------------------------------------------------------------*
* FORM: STEP1 - VBAK 미완료 오더 헤더 조회
*----------------------------------------------------------------------*
FORM f2_get_vbak.
  REFRESH gt_vbak2.

  " 오더 상태: 'C'=완료 제외, ' '=미처리, 'A'=부분처리만
  SELECT vbeln erdat audat auart vkorg vtweg spart kunnr netwr waerk knumv
    INTO TABLE gt_vbak2
    FROM vbak
    WHERE audat IN s_audat
      AND vkorg IN s_vkorg
      AND vtweg IN s_vtweg
      AND spart IN s_spart
      AND kunnr IN s_kunnr
      AND auart IN s_auart
      AND vbtyp = 'C'.

  DESCRIBE TABLE gt_vbak2 LINES gv_lines.
  MESSAGE s003(zmsd) WITH gv_lines '건의 Open Order 헤더 조회'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP2 - VBAP 오더 아이템 조회 (잔량 있는 것만)
*----------------------------------------------------------------------*
FORM f2_get_vbap.
  REFRESH gt_vbap2.

  DATA: lt_vbeln TYPE RANGE OF vbeln_va,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbak2 INTO DATA(ls_vbak).
    ls_vbeln-sign = 'I'. ls_vbeln-option = 'EQ'.
    ls_vbeln-low = ls_vbak-vbeln.
    APPEND ls_vbeln TO lt_vbeln.
  ENDLOOP.

  SELECT vbeln posnr matnr matkl arktx meins vrkme kwmeng netwr waers abgru
    INTO TABLE gt_vbap2
    FROM vbap
    WHERE vbeln IN lt_vbeln
      AND matnr IN s_matnr
      AND matkl IN s_matkl
      AND abgru = ' '.       " 거부 안 된 것

  DESCRIBE TABLE gt_vbap2 LINES gv_lines.
  MESSAGE s004(zmsd) WITH gv_lines '건의 Open Order 아이템 조회'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP3 - VBEP 납품 스케줄 라인 조회 (확정수량, 납품예정일)
*----------------------------------------------------------------------*
FORM f2_get_vbep.
  REFRESH gt_vbep.

  DATA: lt_vbeln TYPE RANGE OF vbeln_va,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbap2 INTO DATA(ls_vbap).
    ls_vbeln-sign = 'I'. ls_vbeln-option = 'EQ'.
    ls_vbeln-low = ls_vbap-vbeln. COLLECT ls_vbeln INTO lt_vbeln.
  ENDLOOP.

  SELECT vbeln posnr etenr edatu lddat bmeng wmeng
    INTO TABLE gt_vbep
    FROM vbep
    WHERE vbeln IN lt_vbeln
      AND wmeng > 0.   " 스케줄 수량 있는 것만

  DESCRIBE TABLE gt_vbep LINES gv_lines.
  MESSAGE s005(zmsd) WITH gv_lines '건의 납품 스케줄 조회'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP4 - VBFA 문서흐름
*----------------------------------------------------------------------*
FORM f2_get_vbfa.
  REFRESH gt_vbfa2.

  DATA: lt_vbeln TYPE RANGE OF vbeln_va,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbap2 INTO DATA(ls_vbap).
    ls_vbeln-sign = 'I'. ls_vbeln-option = 'EQ'.
    ls_vbeln-low = ls_vbap-vbeln. COLLECT ls_vbeln INTO lt_vbeln.
  ENDLOOP.

  SELECT vbelv posnv vbeln posnn vbtyp_n
    INTO TABLE gt_vbfa2
    FROM vbfa
    WHERE vbelv IN lt_vbeln
      AND ( vbtyp_n = 'J' OR vbtyp_n = 'M' ).
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP5 - LIPS 납품 아이템
*----------------------------------------------------------------------*
FORM f2_get_lips.
  REFRESH gt_lips2.

  DATA: lt_vbeln TYPE RANGE OF vbeln_vl,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbfa2 INTO DATA(ls_vbfa) WHERE vbtyp_n = 'J'.
    ls_vbeln-sign = 'I'. ls_vbeln-option = 'EQ'.
    ls_vbeln-low = ls_vbfa-vbeln. COLLECT ls_vbeln INTO lt_vbeln.
  ENDLOOP.

  CHECK lt_vbeln IS NOT INITIAL.

  SELECT vbeln posnr vgbel vgpos lfimg meins
    INTO TABLE gt_lips2
    FROM lips
    WHERE vbeln IN lt_vbeln.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP6 - VBRP 청구 아이템
*----------------------------------------------------------------------*
FORM f2_get_vbrp.
  REFRESH gt_vbrp2.

  DATA: lt_vbeln TYPE RANGE OF vbeln_vf,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbfa2 INTO DATA(ls_vbfa) WHERE vbtyp_n = 'M'.
    ls_vbeln-sign = 'I'. ls_vbeln-option = 'EQ'.
    ls_vbeln-low = ls_vbfa-vbeln. COLLECT ls_vbeln INTO lt_vbeln.
  ENDLOOP.

  CHECK lt_vbeln IS NOT INITIAL.

  SELECT vbeln posnr aubel aupos fkimg netwr mwsbp
    INTO TABLE gt_vbrp2
    FROM vbrp
    WHERE vbeln IN lt_vbeln.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP7 - KONV 가격조건 (PR00 기반 오더금액 재계산)
*----------------------------------------------------------------------*
FORM f2_get_konv.
  REFRESH gt_konv2.

  DATA: lt_knumv TYPE RANGE OF knumv,
        ls_knumv LIKE LINE OF lt_knumv.

  LOOP AT gt_vbak2 INTO DATA(ls_vbak).
    CHECK ls_vbak-knumv IS NOT INITIAL.
    ls_knumv-sign = 'I'. ls_knumv-option = 'EQ'.
    ls_knumv-low = ls_vbak-knumv. COLLECT ls_knumv INTO lt_knumv.
  ENDLOOP.

  CHECK lt_knumv IS NOT INITIAL.

  SELECT knumv kposn kschl kbetr kwert kkurs waers
    INTO TABLE gt_konv2
    FROM konv
    WHERE knumv IN lt_knumv
      AND kschl = 'PR00'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP8 - KNA1 고객 마스터
*----------------------------------------------------------------------*
FORM f2_get_kna1.
  REFRESH gt_kna12.

  DATA: lt_kunnr TYPE RANGE OF kunnr,
        ls_kunnr LIKE LINE OF lt_kunnr.

  LOOP AT gt_vbak2 INTO DATA(ls_vbak).
    ls_kunnr-sign = 'I'. ls_kunnr-option = 'EQ'.
    ls_kunnr-low = ls_vbak-kunnr. COLLECT ls_kunnr INTO lt_kunnr.
  ENDLOOP.

  SELECT kunnr name1 ktokd land1 regio
    INTO TABLE gt_kna12
    FROM kna1
    WHERE kunnr IN lt_kunnr.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP9 - KNVV 고객 영업 데이터
*----------------------------------------------------------------------*
FORM f2_get_knvv.
  REFRESH gt_knvv2.

  DATA: lt_kunnr TYPE RANGE OF kunnr,
        ls_kunnr LIKE LINE OF lt_kunnr.

  LOOP AT gt_vbak2 INTO DATA(ls_vbak).
    ls_kunnr-sign = 'I'. ls_kunnr-option = 'EQ'.
    ls_kunnr-low = ls_vbak-kunnr. COLLECT ls_kunnr INTO lt_kunnr.
  ENDLOOP.

  SELECT kunnr vkorg vtweg spart kdgrp kalks
    INTO TABLE gt_knvv2
    FROM knvv
    WHERE kunnr IN lt_kunnr
      AND vkorg IN s_vkorg.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP10 - KNKK 신용 한도 데이터
*----------------------------------------------------------------------*
FORM f2_get_knkk.
  REFRESH gt_knkk.

  DATA: lt_kunnr TYPE RANGE OF kunnr,
        ls_kunnr LIKE LINE OF lt_kunnr.

  LOOP AT gt_vbak2 INTO DATA(ls_vbak).
    ls_kunnr-sign = 'I'. ls_kunnr-option = 'EQ'.
    ls_kunnr-low = ls_vbak-kunnr. COLLECT ls_kunnr INTO lt_kunnr.
  ENDLOOP.

  SELECT kunnr kkber ctlpc klimk skfor ssobl
    INTO TABLE gt_knkk
    FROM knkk
    WHERE kunnr IN lt_kunnr
      AND kkber = p_kkber.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP11 - 데이터 통합 및 계산 (핵심 복잡 로직)
*----------------------------------------------------------------------*
FORM f2_merge_data.
  REFRESH gt_openord.

  DATA:
    lv_conf_qty   TYPE menge_d,
    lv_dlv_qty    TYPE menge_d,
    lv_bil_qty    TYPE menge_d,
    lv_bil_amt    TYPE wertv8,
    lv_pr00_kbetr TYPE kbetr,
    lv_ord_amt    TYPE wertv8,
    lv_open_amt   TYPE wertv8,
    lv_edatu      TYPE edatu,
    lv_delay_days TYPE i.

  LOOP AT gt_vbak2 INTO DATA(ls_vbak).
    LOOP AT gt_vbap2 INTO DATA(ls_vbap) WHERE vbeln = ls_vbak-vbeln.

      CLEAR gs_openord.

      " ── 기본 정보 ──────────────────────────────────────────
      gs_openord-vbeln     = ls_vbak-vbeln.
      gs_openord-posnr     = ls_vbap-posnr.
      gs_openord-auart     = ls_vbak-auart.
      gs_openord-audat     = ls_vbak-audat.
      gs_openord-audat_ym  = ls_vbak-audat(6).
      gs_openord-vkorg     = ls_vbak-vkorg.
      gs_openord-vtweg     = ls_vbak-vtweg.
      gs_openord-spart     = ls_vbak-spart.
      gs_openord-kunnr     = ls_vbak-kunnr.
      gs_openord-matnr     = ls_vbap-matnr.
      gs_openord-arktx     = ls_vbap-arktx.
      gs_openord-matkl     = ls_vbap-matkl.
      gs_openord-meins     = ls_vbap-meins.
      gs_openord-vrkme     = ls_vbap-vrkme.
      gs_openord-waers     = ls_vbak-waerk.
      gs_openord-ord_qty   = ls_vbap-kwmeng.

      " ── 경과일수 및 Aging 구간 계산 ──────────────────────
      gs_openord-elapsed_days = sy-datum - ls_vbak-audat.
      IF gs_openord-elapsed_days <= 30.
        gs_openord-aging_grp = '030'.
      ELSEIF gs_openord-elapsed_days <= 60.
        gs_openord-aging_grp = '060'.
      ELSEIF gs_openord-elapsed_days <= 90.
        gs_openord-aging_grp = '090'.
      ELSE.
        gs_openord-aging_grp = '90+'.
      ENDIF.

      " ── 고객 정보 ──────────────────────────────────────────
      READ TABLE gt_kna12 INTO DATA(ls_kna1) WITH KEY kunnr = ls_vbak-kunnr.
      IF sy-subrc = 0.
        gs_openord-kunnr_name = ls_kna1-name1.
        gs_openord-land1      = ls_kna1-land1.
      ENDIF.

      READ TABLE gt_knvv2 INTO DATA(ls_knvv)
        WITH KEY kunnr = ls_vbak-kunnr
                 vkorg = ls_vbak-vkorg.
      IF sy-subrc = 0.
        gs_openord-kdgrp = ls_knvv-kdgrp.
      ENDIF.

      " ── 신용 한도 조회 ─────────────────────────────────────
      READ TABLE gt_knkk INTO DATA(ls_knkk) WITH KEY kunnr = ls_vbak-kunnr.
      IF sy-subrc = 0.
        gs_openord-credit_group = ls_knkk-ctlpc.
        gs_openord-klimk        = ls_knkk-klimk.
        gs_openord-skfor        = ls_knkk-skfor.

        " 신용 초과 여부: AR잔액 + 오픈오더 > 신용한도
        DATA(lv_total_exposure) = ls_knkk-skfor + ls_knkk-ssobl.
        IF lv_total_exposure > ls_knkk-klimk AND ls_knkk-klimk > 0.
          gs_openord-credit_exc = 'X'.
        ENDIF.
      ENDIF.

      " ── VBEP 납품 스케줄: 확정수량 및 최초 납품예정일 ──────
      CLEAR: lv_conf_qty, lv_edatu.
      LOOP AT gt_vbep INTO DATA(ls_vbep)
        WHERE vbeln = ls_vbap-vbeln
          AND posnr = ls_vbap-posnr.

        lv_conf_qty = lv_conf_qty + ls_vbep-bmeng.
        IF lv_edatu IS INITIAL OR ls_vbep-edatu < lv_edatu.
          lv_edatu = ls_vbep-edatu.
        ENDIF.
      ENDLOOP.
      gs_openord-conf_qty = lv_conf_qty.
      gs_openord-edatu    = lv_edatu.

      " 미납품 잔량 = 오더수량 - 납품확정수량
      gs_openord-open_qty = gs_openord-ord_qty - gs_openord-conf_qty.
      IF gs_openord-open_qty < 0. gs_openord-open_qty = 0. ENDIF.

      " ── 납품 수량 (VBFA → LIPS) ────────────────────────────
      CLEAR lv_dlv_qty.
      LOOP AT gt_vbfa2 INTO DATA(ls_vbfa)
        WHERE vbelv = ls_vbap-vbeln
          AND posnv = ls_vbap-posnr
          AND vbtyp_n = 'J'.

        READ TABLE gt_lips2 INTO DATA(ls_lips)
          WITH KEY vbeln = ls_vbfa-vbeln
                   posnr = ls_vbfa-posnn.
        IF sy-subrc = 0.
          lv_dlv_qty = lv_dlv_qty + ls_lips-lfimg.
        ENDIF.
      ENDLOOP.
      gs_openord-dlv_qty = lv_dlv_qty.

      " ── 청구 수량/금액 (VBFA → VBRP) ──────────────────────
      CLEAR: lv_bil_qty, lv_bil_amt.
      LOOP AT gt_vbfa2 INTO ls_vbfa
        WHERE vbelv = ls_vbap-vbeln
          AND posnv = ls_vbap-posnr
          AND vbtyp_n = 'M'.

        READ TABLE gt_vbrp2 INTO DATA(ls_vbrp)
          WITH KEY vbeln = ls_vbfa-vbeln
                   posnr = ls_vbfa-posnn.
        IF sy-subrc = 0.
          lv_bil_qty = lv_bil_qty + ls_vbrp-fkimg.
          lv_bil_amt = lv_bil_amt + ls_vbrp-netwr.
        ENDIF.
      ENDLOOP.
      gs_openord-bil_qty = lv_bil_qty.
      gs_openord-bil_amt = lv_bil_amt.

      " ── 오더 금액 재계산 (PR00 단가 × 오더수량) ────────────
      DATA(lv_kposn) = CONV kposn( ls_vbap-posnr ).
      READ TABLE gt_konv2 INTO DATA(ls_konv)
        WITH KEY knumv = ls_vbak-knumv
                 kposn = lv_kposn
                 kschl = 'PR00'.
      IF sy-subrc = 0.
        lv_pr00_kbetr = ls_konv-kbetr.
        " 단가×수량 (조건금액 기준)
        lv_ord_amt = ls_konv-kwert.  " 전체 조건금액
      ELSE.
        lv_ord_amt = ls_vbap-netwr.  " fallback
      ENDIF.
      gs_openord-ord_amt = lv_ord_amt.

      " 미결 금액 = 오더금액 - 청구금액
      gs_openord-open_amt = gs_openord-ord_amt - gs_openord-bil_amt.
      IF gs_openord-open_amt < 0. gs_openord-open_amt = 0. ENDIF.

      " ── 납품율 / 청구율 ────────────────────────────────────
      IF gs_openord-ord_qty > 0.
        gs_openord-dlv_rate = ( gs_openord-dlv_qty / gs_openord-ord_qty ) * 100.
        gs_openord-bil_rate = ( gs_openord-bil_qty / gs_openord-ord_qty ) * 100.
      ENDIF.

      " ── 납품 상태 코드 ─────────────────────────────────────
      CASE gs_openord-dlv_qty.
        WHEN 0.
          gs_openord-dlv_stat = 'A'.   " 미납품
        WHEN gs_openord-ord_qty.
          gs_openord-dlv_stat = 'C'.   " 완납
        WHEN OTHERS.
          gs_openord-dlv_stat = 'B'.   " 부분납품
      ENDCASE.

      " ── 청구 상태 코드 ─────────────────────────────────────
      CASE gs_openord-bil_qty.
        WHEN 0.
          gs_openord-bil_stat = 'A'.   " 미청구
        WHEN gs_openord-dlv_qty.
          gs_openord-bil_stat = 'C'.   " 완료
        WHEN OTHERS.
          gs_openord-bil_stat = 'B'.   " 부분청구
      ENDCASE.

      " ── 납품 지연 여부 ─────────────────────────────────────
      IF gs_openord-edatu IS NOT INITIAL
         AND gs_openord-dlv_stat <> 'C'
         AND sy-datum > gs_openord-edatu.
        gs_openord-wbs_delay  = 'X'.
        gs_openord-delay_days = sy-datum - gs_openord-edatu.
      ENDIF.

      " ── 신호등 로직 (납품지연 + 신용초과 복합) ─────────────
      IF gs_openord-credit_exc = 'X'.
        gs_openord-traffic = 'R'.   " 신용초과 → 적색
      ELSEIF gs_openord-wbs_delay = 'X'.
        IF gs_openord-delay_days <= 7.
          gs_openord-traffic = 'Y'.  " 1~7일 → 황색
        ELSE.
          gs_openord-traffic = 'R'.  " 7일 초과 → 적색
        ENDIF.
      ELSEIF gs_openord-aging_grp = '90+'.
        gs_openord-traffic = 'Y'.   " 90일 초과 오더 → 황색 경고
      ELSE.
        gs_openord-traffic = 'G'.   " 정상
      ENDIF.

      APPEND gs_openord TO gt_openord.

    ENDLOOP.  " gt_vbap2
  ENDLOOP.    " gt_vbak2

  DESCRIBE TABLE gt_openord LINES gv_lines.
  MESSAGE s011(zmsd) WITH gv_lines '건의 Open Order 데이터 생성'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP12 - 최종 필터 적용
*----------------------------------------------------------------------*
FORM f2_filter_result.

  " 상태 필터 (미납품/부분납품 선택)
  IF p_open = 'X' AND p_part = ' '.
    DELETE gt_openord WHERE dlv_stat <> 'A'.
  ELSEIF p_open = ' ' AND p_part = 'X'.
    DELETE gt_openord WHERE dlv_stat <> 'B'.
  ENDIF.

  " 지연 건만 조회
  IF p_delay = 'X'.
    DELETE gt_openord WHERE wbs_delay <> 'X'.
  ENDIF.

  " 신용초과 건만 조회
  IF p_credit = 'X'.
    DELETE gt_openord WHERE credit_exc <> 'X'.
  ENDIF.

  DESCRIBE TABLE gt_openord LINES gv_lines.
  MESSAGE s012(zmsd) WITH '필터 적용 후 ' gv_lines '건'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: Z-Table 저장 (단일 테이블 ZSDT_OPENORD)
*----------------------------------------------------------------------*
FORM f2_save_ztable.
  DATA:
    lt_openord_db TYPE STANDARD TABLE OF zsdt_openord,
    ls_openord_db TYPE zsdt_openord.

  " 기존 데이터 삭제
  IF p_delold = 'X'.
    DELETE FROM zsdt_openord
      WHERE vkorg IN s_vkorg
        AND audat IN s_audat.
  ENDIF.

  " 단일 테이블 저장 (아이템 단위)
  LOOP AT gt_openord INTO gs_openord.
    CLEAR ls_openord_db.
    ls_openord_db-mandt       = sy-mandt.
    ls_openord_db-vbeln       = gs_openord-vbeln.
    ls_openord_db-posnr       = gs_openord-posnr.
    ls_openord_db-auart       = gs_openord-auart.
    ls_openord_db-audat       = gs_openord-audat.
    ls_openord_db-audat_ym    = gs_openord-audat_ym.
    ls_openord_db-vkorg       = gs_openord-vkorg.
    ls_openord_db-kunnr       = gs_openord-kunnr.
    ls_openord_db-matnr       = gs_openord-matnr.
    ls_openord_db-spart       = gs_openord-spart.
    ls_openord_db-matkl       = gs_openord-matkl.
    ls_openord_db-waers       = gs_openord-waers.
    ls_openord_db-ord_qty     = gs_openord-ord_qty.
    ls_openord_db-conf_qty    = gs_openord-conf_qty.
    ls_openord_db-open_qty    = gs_openord-open_qty.
    ls_openord_db-dlv_qty     = gs_openord-dlv_qty.
    ls_openord_db-bil_qty     = gs_openord-bil_qty.
    ls_openord_db-dlv_rate    = gs_openord-dlv_rate.
    ls_openord_db-bil_rate    = gs_openord-bil_rate.
    ls_openord_db-ord_amt     = gs_openord-ord_amt.
    ls_openord_db-open_amt    = gs_openord-open_amt.
    ls_openord_db-bil_amt     = gs_openord-bil_amt.
    ls_openord_db-edatu       = gs_openord-edatu.
    ls_openord_db-wbs_delay   = gs_openord-wbs_delay.
    ls_openord_db-delay_days  = gs_openord-delay_days.
    ls_openord_db-aging_grp   = gs_openord-aging_grp.
    ls_openord_db-dlv_stat    = gs_openord-dlv_stat.
    ls_openord_db-bil_stat    = gs_openord-bil_stat.
    ls_openord_db-credit_exc  = gs_openord-credit_exc.
    ls_openord_db-erdat       = sy-datum.
    ls_openord_db-ernam       = sy-uname.
    APPEND ls_openord_db TO lt_openord_db.
  ENDLOOP.

  INSERT zsdt_openord FROM TABLE lt_openord_db.
  COMMIT WORK AND WAIT.

  gv_save_cnt = lines( lt_openord_db ).
  MESSAGE s013(zmsd) WITH gv_save_cnt '건 ZSDT_OPENORD 저장 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: ALV 출력
*----------------------------------------------------------------------*
FORM f2_show_alv.

  DEFINE m_fcat2.
    CLEAR gs_fieldcat2.
    gs_fieldcat2-fieldname = &1.
    gs_fieldcat2-coltext   = &2.
    gs_fieldcat2-outputlen = &3.
    gs_fieldcat2-just      = &4.
    gs_fieldcat2-do_sum    = &5.
    APPEND gs_fieldcat2 TO gt_fieldcat2.
  END-OF-DEFINITION.

  m_fcat2 'TRAFFIC'      '상태'       3  'C' ' '.
  m_fcat2 'VKORG'        '영업조직'   4  'C' ' '.
  m_fcat2 'SPART'        '제품군'     4  'C' ' '.
  m_fcat2 'MATKL'        '자재그룹'   9  'C' ' '.
  m_fcat2 'KUNNR'        '고객코드'  10  'C' ' '.
  m_fcat2 'KUNNR_NAME'   '고객명'    20  'L' ' '.
  m_fcat2 'KDGRP'        '고객그룹'   2  'C' ' '.
  m_fcat2 'CREDIT_GROUP' '신용그룹'   2  'C' ' '.
  m_fcat2 'KLIMK'        '신용한도'  15  'R' ' '.
  m_fcat2 'CREDIT_EXC'   '신용초과'   3  'C' ' '.
  m_fcat2 'MATNR'        '자재번호'  18  'L' ' '.
  m_fcat2 'ARKTX'        '자재명'    20  'L' ' '.
  m_fcat2 'VBELN'        '오더번호'  10  'C' ' '.
  m_fcat2 'POSNR'        '아이템'     6  'C' ' '.
  m_fcat2 'AUART'        '오더유형'   4  'C' ' '.
  m_fcat2 'AUDAT'        '오더일'     8  'C' ' '.
  m_fcat2 'AUDAT_YM'     '년월'       6  'C' ' '.
  m_fcat2 'ELAPSED_DAYS' '경과일'     5  'R' ' '.
  m_fcat2 'AGING_GRP'    'Aging'      5  'C' ' '.
  m_fcat2 'WAERS'        '통화'       5  'C' ' '.
  m_fcat2 'ORD_QTY'      '오더수량'  13  'R' 'X'.
  m_fcat2 'CONF_QTY'     '확정수량'  13  'R' 'X'.
  m_fcat2 'OPEN_QTY'     '미납수량'  13  'R' 'X'.
  m_fcat2 'DLV_QTY'      '납품수량'  13  'R' 'X'.
  m_fcat2 'BIL_QTY'      '청구수량'  13  'R' 'X'.
  m_fcat2 'DLV_RATE'     '납품율%'    8  'R' ' '.
  m_fcat2 'BIL_RATE'     '청구율%'    8  'R' ' '.
  m_fcat2 'ORD_AMT'      '오더금액'  15  'R' 'X'.
  m_fcat2 'BIL_AMT'      '청구금액'  15  'R' 'X'.
  m_fcat2 'OPEN_AMT'     '미결금액'  15  'R' 'X'.
  m_fcat2 'EDATU'        '납품예정일'  8  'C' ' '.
  m_fcat2 'WBS_DELAY'    '지연'       3  'C' ' '.
  m_fcat2 'DELAY_DAYS'   '지연일수'   5  'R' ' '.
  m_fcat2 'DLV_STAT'     '납품상태'   3  'C' ' '.
  m_fcat2 'BIL_STAT'     '청구상태'   3  'C' ' '.

  " 신호등 아이콘
  READ TABLE gt_fieldcat2 INTO gs_fieldcat2 WITH KEY fieldname = 'TRAFFIC'.
  IF sy-subrc = 0.
    gs_fieldcat2-icon   = 'X'.
    gs_fieldcat2-no_sum = 'X'.
    MODIFY gt_fieldcat2 FROM gs_fieldcat2 INDEX sy-tabix.
  ENDIF.

  gs_layout2-zebra      = 'X'.
  gs_layout2-cwidth_opt = 'X'.
  gs_layout2-grid_title = '【Open Order 진행현황】'.

  " Sort
  gs_sort2-fieldname = 'VKORG'.   gs_sort2-up = 'X'. APPEND gs_sort2 TO gt_sort2.
  gs_sort2-fieldname = 'KUNNR'.   gs_sort2-up = 'X'. APPEND gs_sort2 TO gt_sort2.
  gs_sort2-fieldname = 'AGING_GRP'. gs_sort2-up = 'X'. APPEND gs_sort2 TO gt_sort2.
  gs_sort2-fieldname = 'WBS_DELAY'. gs_sort2-up = 'X'. APPEND gs_sort2 TO gt_sort2.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program   = sy-repid
      is_layout_lvc        = gs_layout2
      it_fieldcat_lvc      = gt_fieldcat2
      it_sort_lvc          = gt_sort2
      i_save               = 'A'
    TABLES
      t_outtab             = gt_openord
    EXCEPTIONS
      program_error        = 1
      OTHERS               = 2.
ENDFORM.









