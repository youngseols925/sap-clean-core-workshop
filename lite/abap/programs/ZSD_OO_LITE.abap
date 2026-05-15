*&---------------------------------------------------------------------*
*& Report  ZSD_OO_LITE
*& Open Order 진행현황 조회 (워크샵 경량화 버전)
*& 목적: Clean Core 워크샵 AS-IS 시연
*&       VBAK + VBAP 만 사용 (KNA1/VBEP/VBFA/LIPS/VBRP/KONV 제거)
*& 기반: ZSD_OPENORD_STATUS (Full 버전)
*&---------------------------------------------------------------------*
REPORT zsd_oo_lite
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
    audat_ym     TYPE spmon,       " 오더 생성년월 (YYYYMM)
    elapsed_days TYPE i,           " 오더 생성 후 경과일수
    aging_grp    TYPE char3,       " Aging 구간 (030/060/090/90+)
    " ── 영업 조직 ──────────────────────────────────────────────
    vkorg        TYPE vkorg,       " 영업 조직
    vtweg        TYPE vtweg,       " 유통 경로
    spart        TYPE spart,       " 제품군
    " ── 고객 ────────────────────────────────────────────────────
    kunnr        TYPE kunnr,       " 고객 코드
    " ── 자재 ────────────────────────────────────────────────────
    matnr        TYPE matnr,       " 자재 번호
    arktx        TYPE arktx,       " 자재 설명 (VBAP)
    matkl        TYPE matkl,       " 자재 그룹
    meins        TYPE meins,       " 기본 단위
    vrkme        TYPE vrkme,       " 판매 단위
    " ── 수량 / 금액 ──────────────────────────────────────────────
    waerk        TYPE waerk,       " 오더 통화 (VBAK-WAERK)
    ord_qty      TYPE kwmeng,      " 오더 수량 (VBAP-KWMENG)
    ord_amt      TYPE wertv8,      " 오더 금액 (VBAP-NETWR)
  END OF ty_openord.

*----------------------------------------------------------------------*
* DB 조회용 타입
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_vbak,
    vbeln TYPE vbeln_va,
    audat TYPE audat,
    auart TYPE auart,
    vkorg TYPE vkorg,
    vtweg TYPE vtweg,
    spart TYPE spart,
    kunnr TYPE kunnr,
    waerk TYPE waerk,
  END OF ty_vbak,

  BEGIN OF ty_vbap,
    vbeln  TYPE vbeln_va,
    posnr  TYPE posnr_va,
    matnr  TYPE matnr,
    matkl  TYPE matkl,
    arktx  TYPE arktx,
    meins  TYPE meins,
    vrkme  TYPE vrkme,
    kwmeng TYPE kwmeng,
    netwr  TYPE p LENGTH 8 DECIMALS 2,
    abgru  TYPE abgru,
  END OF ty_vbap.

*----------------------------------------------------------------------*
* 내부 테이블 선언
*----------------------------------------------------------------------*
DATA:
  gt_openord  TYPE STANDARD TABLE OF ty_openord,
  gt_vbak     TYPE STANDARD TABLE OF ty_vbak,
  gt_vbap     TYPE STANDARD TABLE OF ty_vbap,
  gs_openord  TYPE ty_openord,
  gv_lines    TYPE i,
  gv_save_cnt TYPE i.

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
    s_audat  FOR sy-datum   OBLIGATORY,    " 오더 생성일
    s_vkorg  FOR sy-mandt,                 " 영업 조직
    s_vtweg  FOR sy-mandt,                 " 유통 경로
    s_spart  FOR sy-mandt,                 " 제품군
    s_kunnr  FOR sy-mandt,                 " 고객
    s_matnr  FOR sy-mandt,                 " 자재
    s_matkl  FOR sy-mandt,                 " 자재 그룹
    s_auart  FOR sy-mandt.                 " 오더 유형
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_save   TYPE xfeld AS CHECKBOX,
    p_delold TYPE xfeld AS CHECKBOX DEFAULT 'X',
    p_nodisp TYPE xfeld AS CHECKBOX DEFAULT ' '.  " No screen output
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

  PERFORM f_get_vbak.       " STEP1: 오더 헤더 (미완료만)
  CHECK gt_vbak IS NOT INITIAL.

  PERFORM f_get_vbap.       " STEP2: 오더 아이템
  CHECK gt_vbap IS NOT INITIAL.

  PERFORM f_merge_data.     " STEP3: 통합 및 계산

  IF p_save = 'X'.
    PERFORM f_save_ztable.
  ENDIF.

END-OF-SELECTION.
  IF p_nodisp = ' '.
    PERFORM f_show_alv.
  ENDIF.

*----------------------------------------------------------------------*
* FORM: STEP1 — VBAK 미완료 오더 헤더 조회
*   ※ 워크샵 설명 포인트:
*      GBSTK <> 'C' 조건으로 완료 오더를 제외하지만
*      아이템 단위 상태(VBAP-ABGRU)는 VBAP에서 필터
*----------------------------------------------------------------------*
FORM f_get_vbak.
  REFRESH gt_vbak.

  SELECT vbeln audat auart vkorg vtweg spart kunnr waerk
    INTO TABLE gt_vbak
    FROM vbak
    WHERE audat IN s_audat
      AND vkorg IN s_vkorg
      AND vtweg IN s_vtweg
      AND spart IN s_spart
      AND kunnr IN s_kunnr
      AND auart IN s_auart
      AND vbtyp = 'C'         " 판매오더
      AND gbstk <> 'C'.       " 완료 제외 (미결/부분처리만)

  DESCRIBE TABLE gt_vbak LINES gv_lines.
  MESSAGE s003(zmsd) WITH gv_lines '건의 Open Order 헤더 조회'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP2 — VBAP 오더 아이템 조회 (거부 안 된 것만)
*   ※ 워크샵 설명 포인트:
*      ABGRU = ' ' 조건으로 거부 라인 제외
*      KWMENG = 오더 수량 (확정수량 BMENG는 VBEP에서만 가능)
*----------------------------------------------------------------------*
FORM f_get_vbap.
  REFRESH gt_vbap.

  DATA: lt_vbeln TYPE RANGE OF vbeln_va,
        ls_vbeln LIKE LINE OF lt_vbeln.

  LOOP AT gt_vbak INTO DATA(ls_vbak).
    ls_vbeln-sign = 'I'. ls_vbeln-option = 'EQ'.
    ls_vbeln-low = ls_vbak-vbeln.
    APPEND ls_vbeln TO lt_vbeln.
  ENDLOOP.

  SELECT vbeln posnr matnr matkl arktx meins vrkme kwmeng netwr abgru
    INTO TABLE gt_vbap
    FROM vbap
    WHERE vbeln IN lt_vbeln
      AND matnr IN s_matnr
      AND matkl IN s_matkl
      AND abgru = ' '.         " 거부 아이템 제외

  DESCRIBE TABLE gt_vbap LINES gv_lines.
  MESSAGE s004(zmsd) WITH gv_lines '건의 Open Order 아이템 조회'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP3 — 데이터 통합 및 계산
*   ※ 워크샵 설명 포인트 (AS-IS 문제):
*      중첩 LOOP으로 VBAK × VBAP 매칭 → 대용량시 성능 문제
*      TO-BE DSP TF에서는 단순 SQL JOIN으로 대체됨
*----------------------------------------------------------------------*
FORM f_merge_data.
  REFRESH gt_openord.

  LOOP AT gt_vbak INTO DATA(ls_vbak).
    LOOP AT gt_vbap INTO DATA(ls_vbap) WHERE vbeln = ls_vbak-vbeln.

      CLEAR gs_openord.

      " ── 기본 정보 (VBAK + VBAP) ──────────────────────────
      gs_openord-vbeln    = ls_vbak-vbeln.
      gs_openord-posnr    = ls_vbap-posnr.
      gs_openord-auart    = ls_vbak-auart.
      gs_openord-audat    = ls_vbak-audat.
      gs_openord-audat_ym = ls_vbak-audat(6).   " YYYYMM
      gs_openord-vkorg    = ls_vbak-vkorg.
      gs_openord-vtweg    = ls_vbak-vtweg.
      gs_openord-spart    = ls_vbak-spart.
      gs_openord-kunnr    = ls_vbak-kunnr.
      gs_openord-matnr    = ls_vbap-matnr.
      gs_openord-arktx    = ls_vbap-arktx.
      gs_openord-matkl    = ls_vbap-matkl.
      gs_openord-meins    = ls_vbap-meins.
      gs_openord-vrkme    = ls_vbap-vrkme.
      gs_openord-waerk    = ls_vbak-waerk.
      gs_openord-ord_qty  = ls_vbap-kwmeng.     " 오더 수량
      gs_openord-ord_amt  = ls_vbap-netwr.      " 아이템 금액 (VBAP)

      " ── 경과일수 및 Aging 구간 계산 ──────────────────────
      " ※ TO-BE TF: DAYS_BETWEEN(AUDAT, CURRENT_DATE) + CASE WHEN
      gs_openord-elapsed_days = sy-datum - ls_vbak-audat.
      CASE 'X'.
        WHEN gs_openord-elapsed_days <= 30.
          gs_openord-aging_grp = '030'.
        WHEN gs_openord-elapsed_days <= 60.
          gs_openord-aging_grp = '060'.
        WHEN gs_openord-elapsed_days <= 90.
          gs_openord-aging_grp = '090'.
        WHEN OTHERS.
          gs_openord-aging_grp = '90+'.
      ENDCASE.

      APPEND gs_openord TO gt_openord.

    ENDLOOP.  " gt_vbap
  ENDLOOP.    " gt_vbak

  DESCRIBE TABLE gt_openord LINES gv_lines.
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

  LOOP AT gt_openord INTO gs_openord.
    CLEAR ls_db.
    ls_db-vbeln        = gs_openord-vbeln.
    ls_db-posnr        = gs_openord-posnr.
    ls_db-audat        = gs_openord-audat.
    ls_db-audat_ym     = gs_openord-audat_ym.
    ls_db-vkorg        = gs_openord-vkorg.
    ls_db-spart        = gs_openord-spart.
    ls_db-kunnr        = gs_openord-kunnr.
    ls_db-matnr        = gs_openord-matnr.
    ls_db-matkl        = gs_openord-matkl.
    ls_db-ord_qty      = gs_openord-ord_qty.
    ls_db-ord_amt      = gs_openord-ord_amt.
    ls_db-waerk        = gs_openord-waerk.
    ls_db-elapsed_days = gs_openord-elapsed_days.
    ls_db-aging_grp    = gs_openord-aging_grp.
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

  m_fcat 'AGING_GRP'    'Aging'       5  'C' ' '.
  m_fcat 'VKORG'        '영업조직'    4  'C' ' '.
  m_fcat 'VTWEG'        '유통경로'    2  'C' ' '.
  m_fcat 'SPART'        '제품군'      4  'C' ' '.
  m_fcat 'KUNNR'        '고객코드'   10  'C' ' '.
  m_fcat 'MATKL'        '자재그룹'    9  'C' ' '.
  m_fcat 'MATNR'        '자재번호'   18  'L' ' '.
  m_fcat 'ARKTX'        '자재명'     20  'L' ' '.
  m_fcat 'VBELN'        '오더번호'   10  'C' ' '.
  m_fcat 'POSNR'        '아이템'      6  'C' ' '.
  m_fcat 'AUART'        '오더유형'    4  'C' ' '.
  m_fcat 'AUDAT'        '오더일'      8  'C' ' '.
  m_fcat 'AUDAT_YM'     '년월'        6  'C' ' '.
  m_fcat 'ELAPSED_DAYS' '경과일'      5  'R' ' '.
  m_fcat 'WAERK'        '통화'        5  'C' ' '.
  m_fcat 'ORD_QTY'      '오더수량'   13  'R' 'X'.
  m_fcat 'ORD_AMT'      '오더금액'   15  'R' 'X'.

  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-grid_title = '【Open Order 현황 (Lite — VBAK+VBAP)】'.

  gs_sort-fieldname = 'VKORG'.     gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.
  gs_sort-fieldname = 'KUNNR'.     gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.
  gs_sort-fieldname = 'AGING_GRP'. gs_sort-up = 'X'. APPEND gs_sort TO gt_sort.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program   = sy-repid
      is_layout_lvc        = gs_layout
      it_fieldcat_lvc      = gt_fieldcat
      it_sort_lvc          = gt_sort
      i_save               = 'A'
    TABLES
      t_outtab             = gt_openord
    EXCEPTIONS
      program_error        = 1
      OTHERS               = 2.
ENDFORM.
