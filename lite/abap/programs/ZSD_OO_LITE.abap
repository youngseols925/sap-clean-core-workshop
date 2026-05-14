*&---------------------------------------------------------------------*
*& Report  ZSD_OO_LITE
*& Open Order 진행현황 조회 (워크샵 경량화 버전)
*& 목적: Clean Core 워크샵 AS-IS 시연 — 핵심 로직만 추려 1-Day 완주
*& ※ 기준: ZSD_OPENORD_STATUS (Kai 디버깅 완료본) 기반으로
*&         VBEP/VBFA/LIPS/VBRP/KONV/KNVV/KNKK 제거, VBAK+VBAP+KNA1만 유지
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
    audat_ym     TYPE spmon,       " 오더 생성년월
    elapsed_days TYPE i,           " 오더 생성 후 경과일수
    aging_grp    TYPE char3,       " Aging 구간 (030/060/090/90+)
    " ── 영업 조직 ──────────────────────────────────────────────
    vkorg        TYPE vkorg,       " 영업 조직
    vtweg        TYPE vtweg,       " 유통 경로
    spart        TYPE spart,       " 제품군
    " ── 고객 ────────────────────────────────────────────────────
    kunnr        TYPE kunnr,       " 고객 코드
    kunnr_name   TYPE name1_gp,    " 고객 명
    land1        TYPE land1_gp,    " 국가
    " ── 자재 ────────────────────────────────────────────────────
    matnr        TYPE matnr,       " 자재 번호
    arktx        TYPE arktx,       " 자재 설명
    matkl        TYPE matkl,       " 자재 그룹
    mtart        TYPE mtart,       " 자재 유형
    meins        TYPE meins,       " 기본 단위
    vrkme        TYPE vrkme,       " 판매 단위
    " ── 수량 / 금액 ──────────────────────────────────────────────
    waers        TYPE waers,       " 오더 통화
    ord_qty      TYPE menge_d,     " 오더 수량
    ord_amt      TYPE wertv8,      " 오더 금액 (VBAP-NETWR)
  END OF ty_openord.

*----------------------------------------------------------------------*
* 내부 테이블 선언
*----------------------------------------------------------------------*
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
    netwr TYPE p LENGTH 8 DECIMALS 2,
    waerk TYPE waerk,
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
    netwr  TYPE p LENGTH 8 DECIMALS 2,
    abgru  TYPE abgru,
  END OF ty_vbap2,

  BEGIN OF ty_kna1_sel,
    kunnr TYPE kna1-kunnr,
    name1 TYPE kna1-name1,
    ktokd TYPE kna1-ktokd,
    land1 TYPE kna1-land1,
    regio TYPE kna1-regio,
  END OF ty_kna1_sel.

DATA:
  gt_openord  TYPE STANDARD TABLE OF ty_openord,
  gt_vbak2    TYPE STANDARD TABLE OF ty_vbak2,
  gt_vbap2    TYPE STANDARD TABLE OF ty_vbap2,
  gt_kna12    TYPE STANDARD TABLE OF ty_kna1_sel,
  gs_openord  TYPE ty_openord,
  gv_lines    TYPE i,
  gv_save_cnt TYPE i.

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
    p_open   TYPE char1 AS CHECKBOX DEFAULT 'X', " 미납품 포함
    p_part   TYPE char1 AS CHECKBOX DEFAULT 'X'. " 부분납품 포함
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS:
    p_save   TYPE xfeld AS CHECKBOX,
    p_delold TYPE xfeld AS CHECKBOX DEFAULT 'X',
    p_nodisp TYPE xfeld AS CHECKBOX DEFAULT ' '. " No screen output
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

  PERFORM f2_get_kna1.       " STEP3: 고객 마스터 (Lite: STEP8 위치에서 앞으로)

  PERFORM f2_merge_data.     " STEP4: 통합 및 계산
  PERFORM f2_filter_result.  " STEP5: 최종 필터

  IF p_save = 'X'.
    PERFORM f2_save_ztable.
  ENDIF.

END-OF-SELECTION.
  IF p_nodisp = ' '.
    PERFORM f2_show_alv.
  ENDIF.

*----------------------------------------------------------------------*
* FORM: STEP1 — VBAK 미완료 오더 헤더 조회
*----------------------------------------------------------------------*
FORM f2_get_vbak.
  REFRESH gt_vbak2.

  SELECT vbeln erdat audat auart vkorg vtweg spart kunnr netwr waerk
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
* FORM: STEP2 — VBAP 오더 아이템 조회 (거부 안 된 것만)
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

  SELECT vbeln posnr matnr matkl arktx meins vrkme kwmeng netwr abgru
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
* FORM: STEP3 — KNA1 고객 마스터
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
* FORM: STEP4 — 데이터 통합 및 계산
*   ※ 이 복잡한 LOOP/계산 로직이 ERP 리소스를 점유하는 CBO 패턴
*   ※ TO-BE에서는 TF SQL(DAYS_BETWEEN + CASE WHEN)으로 대체됨
*----------------------------------------------------------------------*
FORM f2_merge_data.
  REFRESH gt_openord.

  LOOP AT gt_vbak2 INTO DATA(ls_vbak).
    LOOP AT gt_vbap2 INTO DATA(ls_vbap) WHERE vbeln = ls_vbak-vbeln.

      CLEAR gs_openord.

      " ── 기본 정보 ──────────────────────────────────────────
      gs_openord-vbeln    = ls_vbak-vbeln.
      gs_openord-posnr    = ls_vbap-posnr.
      gs_openord-auart    = ls_vbak-auart.
      gs_openord-audat    = ls_vbak-audat.
      gs_openord-audat_ym = ls_vbak-audat(6).
      gs_openord-vkorg    = ls_vbak-vkorg.
      gs_openord-vtweg    = ls_vbak-vtweg.
      gs_openord-spart    = ls_vbak-spart.
      gs_openord-kunnr    = ls_vbak-kunnr.
      gs_openord-matnr    = ls_vbap-matnr.
      gs_openord-arktx    = ls_vbap-arktx.
      gs_openord-matkl    = ls_vbap-matkl.
      gs_openord-meins    = ls_vbap-meins.
      gs_openord-vrkme    = ls_vbap-vrkme.
      gs_openord-waers    = ls_vbak-waerk.
      gs_openord-ord_qty  = ls_vbap-kwmeng.
      gs_openord-ord_amt  = ls_vbap-netwr.   " 아이템 단가 기준 금액

      " ── 경과일수 및 Aging 구간 계산 ──────────────────────
      " ※ TO-BE TF에서 DAYS_BETWEEN(AUDAT, CURRENT_DATE) + CASE WHEN으로 대체
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

      APPEND gs_openord TO gt_openord.

    ENDLOOP.  " gt_vbap2
  ENDLOOP.    " gt_vbak2

  DESCRIBE TABLE gt_openord LINES gv_lines.
  MESSAGE s011(zmsd) WITH gv_lines '건의 Open Order 데이터 생성'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: STEP5 — 최종 필터 적용
*----------------------------------------------------------------------*
FORM f2_filter_result.

  " 상태 필터 (미납품/부분납품 선택)
  " Lite: VBFA/LIPS 없으므로 납품수량 기반 상태 판별 불가
  " → 필터 선택지는 유지(Selection Screen 구조 보존) 단, 실제 필터링 스킵
  " (워크샵에서 "Full 버전은 이 필터도 동작한다"고 설명 포인트로 활용)

  DESCRIBE TABLE gt_openord LINES gv_lines.
  MESSAGE s012(zmsd) WITH '필터 적용 후 ' gv_lines '건'.
ENDFORM.

*----------------------------------------------------------------------*
* FORM: Z-Table 저장 (ZSDT_OO_LITE)
*----------------------------------------------------------------------*
FORM f2_save_ztable.
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
  LOOP AT gt_openord INTO gs_openord.
    CLEAR ls_db.
    ls_db-vbeln        = gs_openord-vbeln.
    ls_db-posnr        = gs_openord-posnr.
    ls_db-audat        = gs_openord-audat.
    ls_db-audat_ym     = gs_openord-audat_ym.
    ls_db-vkorg        = gs_openord-vkorg.
    ls_db-spart        = gs_openord-spart.
    ls_db-kunnr        = gs_openord-kunnr.
    ls_db-kunnr_name   = gs_openord-kunnr_name.
    ls_db-matnr        = gs_openord-matnr.
    ls_db-matkl        = gs_openord-matkl.
    ls_db-ord_qty      = gs_openord-ord_qty.
    ls_db-ord_amt      = gs_openord-ord_amt.
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

  m_fcat2 'AGING_GRP'    'Aging'      5  'C' ' '.
  m_fcat2 'VKORG'        '영업조직'   4  'C' ' '.
  m_fcat2 'VTWEG'        '유통경로'   2  'C' ' '.
  m_fcat2 'SPART'        '제품군'     4  'C' ' '.
  m_fcat2 'MATKL'        '자재그룹'   9  'C' ' '.
  m_fcat2 'KUNNR'        '고객코드'  10  'C' ' '.
  m_fcat2 'KUNNR_NAME'   '고객명'    20  'L' ' '.
  m_fcat2 'LAND1'        '국가'       3  'C' ' '.
  m_fcat2 'MATNR'        '자재번호'  18  'L' ' '.
  m_fcat2 'ARKTX'        '자재명'    20  'L' ' '.
  m_fcat2 'VBELN'        '오더번호'  10  'C' ' '.
  m_fcat2 'POSNR'        '아이템'     6  'C' ' '.
  m_fcat2 'AUART'        '오더유형'   4  'C' ' '.
  m_fcat2 'AUDAT'        '오더일'     8  'C' ' '.
  m_fcat2 'AUDAT_YM'     '년월'       6  'C' ' '.
  m_fcat2 'ELAPSED_DAYS' '경과일'     5  'R' ' '.
  m_fcat2 'WAERS'        '통화'       5  'C' ' '.
  m_fcat2 'ORD_QTY'      '오더수량'  13  'R' 'X'.
  m_fcat2 'ORD_AMT'      '오더금액'  15  'R' 'X'.

  gs_layout2-zebra      = 'X'.
  gs_layout2-cwidth_opt = 'X'.
  gs_layout2-grid_title = '【Open Order 현황 (Lite)】'.

  gs_sort2-fieldname = 'VKORG'.     gs_sort2-up = 'X'. APPEND gs_sort2 TO gt_sort2.
  gs_sort2-fieldname = 'KUNNR'.     gs_sort2-up = 'X'. APPEND gs_sort2 TO gt_sort2.
  gs_sort2-fieldname = 'AGING_GRP'. gs_sort2-up = 'X'. APPEND gs_sort2 TO gt_sort2.

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
