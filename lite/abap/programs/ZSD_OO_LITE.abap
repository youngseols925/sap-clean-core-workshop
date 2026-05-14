*&---------------------------------------------------------------------*
*& Report  ZSD_OO_LITE
*& Open Order 진행현황 조회 (워크샵 경량화 버전)
*& 목적: Clean Core 워크샵 시연 — AS-IS CBO 패턴 예시
*& 조회 테이블: VBAK, VBAP, KNA1 (3개)
*&---------------------------------------------------------------------*
REPORT zsd_oo_lite
  LINE-SIZE 200
  LINE-COUNT 65
  MESSAGE-ID zmsd.

*----------------------------------------------------------------------*
* 타입 정의
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_oo_lite,
    vbeln        TYPE vbeln_va,    " 판매 오더 번호
    posnr        TYPE posnr_va,    " 오더 아이템
    auart        TYPE auart,       " 오더 유형
    audat        TYPE audat,       " 오더 생성일
    audat_ym     TYPE spmon,       " 오더 생성년월 (YYYYMM)
    vkorg        TYPE vkorg,       " 영업 조직
    spart        TYPE spart,       " 제품군
    kunnr        TYPE kunnr,       " 고객 코드
    kunnr_name   TYPE name1_gp,   " 고객명
    matnr        TYPE matnr,       " 자재 번호
    matkl        TYPE matkl,       " 자재 그룹
    arktx        TYPE arktx,       " 자재 설명
    meins        TYPE meins,       " 단위
    ord_qty      TYPE kwmeng,      " 오더 수량
    ord_amt      TYPE netwr,       " 오더 금액
    waerk        TYPE waerk,       " 통화
    elapsed_days TYPE i,           " 경과일수
    aging_grp    TYPE char3,       " Aging 구간 (030/060/090/90+)
  END OF ty_oo_lite,

  BEGIN OF ty_vbak_s,
    vbeln TYPE vbeln_va,
    audat TYPE audat,
    auart TYPE auart,
    vkorg TYPE vkorg,
    spart TYPE spart,
    kunnr TYPE kunnr,
    netwr TYPE netwr,
    waerk TYPE waerk,
  END OF ty_vbak_s,

  BEGIN OF ty_vbap_s,
    vbeln TYPE vbeln_va,
    posnr TYPE posnr_va,
    matnr TYPE matnr,
    matkl TYPE matkl,
    arktx TYPE arktx,
    meins TYPE meins,
    kwmeng TYPE kwmeng,
    abgru  TYPE abgru,
  END OF ty_vbap_s,

  BEGIN OF ty_kna1_s,
    kunnr TYPE kna1-kunnr,
    name1 TYPE kna1-name1,
  END OF ty_kna1_s.

*----------------------------------------------------------------------*
* 내부 테이블 선언
*----------------------------------------------------------------------*
DATA:
  gt_oo_lite   TYPE STANDARD TABLE OF ty_oo_lite,
  gs_oo_lite   TYPE ty_oo_lite,
  gt_vbak      TYPE STANDARD TABLE OF ty_vbak_s,
  gt_vbap      TYPE STANDARD TABLE OF ty_vbap_s,
  gt_kna1      TYPE STANDARD TABLE OF ty_kna1_s,
  gv_lines     TYPE i,
  gv_save_cnt  TYPE i.

*----------------------------------------------------------------------*
* ALV
*----------------------------------------------------------------------*
DATA:
  go_alv       TYPE REF TO cl_gui_alv_grid,
  gt_fieldcat  TYPE lvc_t_fcat,
  gs_fieldcat  TYPE lvc_s_fcat,
  gs_layout    TYPE lvc_s_layo,
  gt_sort      TYPE lvc_t_sort,
  gs_sort      TYPE lvc_s_sort.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS:
    s_audat FOR sy-datum OBLIGATORY,  " 오더 생성일
    s_vkorg FOR sy-mandt,             " 영업 조직
    s_kunnr FOR sy-mandt,             " 고객 코드
    s_matnr FOR sy-mandt.             " 자재 번호
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_save   TYPE xfeld AS CHECKBOX,             " Z-Table 저장
    p_delold TYPE xfeld AS CHECKBOX DEFAULT 'X'. " 저장 전 기존 삭제
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF s_audat[] IS INITIAL.
    MESSAGE e001(zmsd) WITH '오더 생성일 기간을 입력하세요.'.
  ENDIF.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM f_get_vbak.     " STEP 1: 오더 헤더
  CHECK gt_vbak IS NOT INITIAL.

  PERFORM f_get_vbap.     " STEP 2: 오더 아이템
  CHECK gt_vbap IS NOT INITIAL.

  PERFORM f_get_kna1.     " STEP 3: 고객 마스터
  PERFORM f_merge_data.   " STEP 4: 통합 + Aging 계산

  IF p_save = 'X'.
    PERFORM f_save_ztable.
  ENDIF.

END-OF-SELECTION.
  PERFORM f_show_alv.

*----------------------------------------------------------------------*
* FORM: STEP 1 — VBAK 오더 헤더 조회
*----------------------------------------------------------------------*
FORM f_get_vbak.
  REFRESH gt_vbak.

  SELECT vbeln audat auart vkorg spart kunnr netwr waerk
    INTO TABLE gt_vbak
    FROM vbak
    WHERE audat IN s_audat
      AND vkorg IN s_vkorg
      AND kunnr IN s_kunnr
      AND vbtyp = 'C'.        " 판매오더만

  DESCRIBE TABLE gt_vbak LINES gv_lines.
  MESSAGE s003(zmsd) WITH gv_lines '건의 오더 헤더 조회'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP 2 — VBAP 오더 아이템 조회
*----------------------------------------------------------------------*
FORM f_get_vbap.
  REFRESH gt_vbap.

  DATA: lt_vbeln TYPE RANGE OF vbeln_va,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbak INTO DATA(ls_vbak).
    ls_vbeln-sign = 'I'. ls_vbeln-option = 'EQ'.
    ls_vbeln-low  = ls_vbak-vbeln.
    APPEND ls_vbeln TO lt_vbeln.
  ENDLOOP.

  SELECT vbeln posnr matnr matkl arktx meins kwmeng abgru
    INTO TABLE gt_vbap
    FROM vbap
    WHERE vbeln  IN lt_vbeln
      AND matnr  IN s_matnr
      AND abgru  = ' '.      " 거부 안 된 아이템만

  DESCRIBE TABLE gt_vbap LINES gv_lines.
  MESSAGE s004(zmsd) WITH gv_lines '건의 오더 아이템 조회'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP 3 — KNA1 고객 마스터 조회
*----------------------------------------------------------------------*
FORM f_get_kna1.
  REFRESH gt_kna1.

  DATA: lt_kunnr TYPE RANGE OF kunnr,
        ls_kunnr LIKE LINE OF lt_kunnr.

  LOOP AT gt_vbak INTO DATA(ls_vbak).
    ls_kunnr-sign = 'I'. ls_kunnr-option = 'EQ'.
    ls_kunnr-low  = ls_vbak-kunnr.
    COLLECT ls_kunnr INTO lt_kunnr.
  ENDLOOP.

  SELECT kunnr name1
    INTO TABLE gt_kna1
    FROM kna1
    WHERE kunnr IN lt_kunnr.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP 4 — 데이터 통합 + Aging 계산
*    ※ 핵심 로직: ERP 리소스를 점유하는 CBO 계산 로직
*    ※ TO-BE에서 TF의 CASE WHEN으로 대체됨
*----------------------------------------------------------------------*
FORM f_merge_data.
  REFRESH gt_oo_lite.

  LOOP AT gt_vbak INTO DATA(ls_vbak).
    LOOP AT gt_vbap INTO DATA(ls_vbap)
      WHERE vbeln = ls_vbak-vbeln.

      CLEAR gs_oo_lite.

      " ── 기본 정보 ──────────────────────────────────────────
      gs_oo_lite-vbeln    = ls_vbak-vbeln.
      gs_oo_lite-posnr    = ls_vbap-posnr.
      gs_oo_lite-auart    = ls_vbak-auart.
      gs_oo_lite-audat    = ls_vbak-audat.
      gs_oo_lite-audat_ym = ls_vbak-audat(6).
      gs_oo_lite-vkorg    = ls_vbak-vkorg.
      gs_oo_lite-spart    = ls_vbak-spart.
      gs_oo_lite-kunnr    = ls_vbak-kunnr.
      gs_oo_lite-matnr    = ls_vbap-matnr.
      gs_oo_lite-matkl    = ls_vbap-matkl.
      gs_oo_lite-arktx    = ls_vbap-arktx.
      gs_oo_lite-meins    = ls_vbap-meins.
      gs_oo_lite-ord_qty  = ls_vbap-kwmeng.
      gs_oo_lite-ord_amt  = ls_vbak-netwr.
      gs_oo_lite-waerk    = ls_vbak-waerk.

      " ── 고객명 조회 ─────────────────────────────────────────
      READ TABLE gt_kna1 INTO DATA(ls_kna1)
        WITH KEY kunnr = ls_vbak-kunnr.
      IF sy-subrc = 0.
        gs_oo_lite-kunnr_name = ls_kna1-name1.
      ENDIF.

      " ── Aging 계산 (핵심 로직 — TO-BE에서 TF CASE WHEN으로 대체) ──
      gs_oo_lite-elapsed_days = sy-datum - ls_vbak-audat.
      IF gs_oo_lite-elapsed_days <= 30.
        gs_oo_lite-aging_grp = '030'.
      ELSEIF gs_oo_lite-elapsed_days <= 60.
        gs_oo_lite-aging_grp = '060'.
      ELSEIF gs_oo_lite-elapsed_days <= 90.
        gs_oo_lite-aging_grp = '090'.
      ELSE.
        gs_oo_lite-aging_grp = '90+'.
      ENDIF.

      APPEND gs_oo_lite TO gt_oo_lite.

    ENDLOOP.
  ENDLOOP.

  DESCRIBE TABLE gt_oo_lite LINES gv_lines.
  MESSAGE s011(zmsd) WITH gv_lines '건의 Open Order 데이터 생성'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: Z-Table 저장 (ZSDT_OO_LITE)
*----------------------------------------------------------------------*
FORM f_save_ztable.
  DATA:
    lt_db TYPE STANDARD TABLE OF zsdt_oo_lite,
    ls_db TYPE zsdt_oo_lite.

  " 기존 데이터 삭제
  IF p_delold = 'X'.
    DELETE FROM zsdt_oo_lite
      WHERE vkorg IN s_vkorg
        AND audat IN s_audat.
  ENDIF.

  " 단일 테이블 저장
  LOOP AT gt_oo_lite INTO gs_oo_lite.
    CLEAR ls_db.
    ls_db-vbeln        = gs_oo_lite-vbeln.
    ls_db-posnr        = gs_oo_lite-posnr.
    ls_db-audat        = gs_oo_lite-audat.
    ls_db-audat_ym     = gs_oo_lite-audat_ym.
    ls_db-vkorg        = gs_oo_lite-vkorg.
    ls_db-spart        = gs_oo_lite-spart.
    ls_db-kunnr        = gs_oo_lite-kunnr.
    ls_db-kunnr_name   = gs_oo_lite-kunnr_name.
    ls_db-matnr        = gs_oo_lite-matnr.
    ls_db-matkl        = gs_oo_lite-matkl.
    ls_db-ord_qty      = gs_oo_lite-ord_qty.
    ls_db-ord_amt      = gs_oo_lite-ord_amt.
    ls_db-elapsed_days = gs_oo_lite-elapsed_days.
    ls_db-aging_grp    = gs_oo_lite-aging_grp.
    APPEND ls_db TO lt_db.
  ENDLOOP.

  INSERT zsdt_oo_lite FROM TABLE lt_db.
  COMMIT WORK AND WAIT.

  gv_save_cnt = lines( lt_db ).
  MESSAGE s013(zmsd) WITH gv_save_cnt '건 ZSDT_OO_LITE 저장 완료'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: ALV 출력
*----------------------------------------------------------------------*
FORM f_show_alv.

  DEFINE m_fcat.
    CLEAR gs_fieldcat.
    gs_fieldcat-fieldname = &1.
    gs_fieldcat-coltext   = &2.
    gs_fieldcat-outputlen = &3.
    gs_fieldcat-just      = &4.
    gs_fieldcat-do_sum    = &5.
    APPEND gs_fieldcat TO gt_fieldcat.
  END-OF-DEFINITION.

  m_fcat 'AGING_GRP'    'Aging'      5  'C' ' '.
  m_fcat 'VKORG'        '영업조직'   4  'C' ' '.
  m_fcat 'SPART'        '제품군'     4  'C' ' '.
  m_fcat 'KUNNR'        '고객코드'  10  'C' ' '.
  m_fcat 'KUNNR_NAME'   '고객명'    20  'L' ' '.
  m_fcat 'MATNR'        '자재번호'  18  'L' ' '.
  m_fcat 'ARKTX'        '자재명'    20  'L' ' '.
  m_fcat 'MATKL'        '자재그룹'   9  'C' ' '.
  m_fcat 'VBELN'        '오더번호'  10  'C' ' '.
  m_fcat 'POSNR'        '아이템'     6  'C' ' '.
  m_fcat 'AUART'        '오더유형'   4  'C' ' '.
  m_fcat 'AUDAT'        '오더일'     8  'C' ' '.
  m_fcat 'AUDAT_YM'     '년월'       6  'C' ' '.
  m_fcat 'ELAPSED_DAYS' '경과일'     5  'R' ' '.
  m_fcat 'WAERK'        '통화'       5  'C' ' '.
  m_fcat 'ORD_QTY'      '오더수량'  13  'R' 'X'.
  m_fcat 'ORD_AMT'      '오더금액'  15  'R' 'X'.

  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-grid_title = '【Open Order 현황 (Lite)】'.

  gs_sort-fieldname = 'VKORG'.    gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.
  gs_sort-fieldname = 'KUNNR'.    gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.
  gs_sort-fieldname = 'AGING_GRP'. gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program   = sy-repid
      is_layout_lvc        = gs_layout
      it_fieldcat_lvc      = gt_fieldcat
      it_sort_lvc          = gt_sort
      i_save               = 'A'
    TABLES
      t_outtab             = gt_oo_lite
    EXCEPTIONS
      program_error        = 1
      OTHERS               = 2.
ENDFORM.
