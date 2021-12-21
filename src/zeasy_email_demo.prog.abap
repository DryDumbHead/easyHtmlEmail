*&---------------------------------------------------------------------*
*& Title:  Easy Beautiful Email with ABAP + HTML Templates
*& Author: DryDumbHead (Nitinkumar Gupta)
*& email:  nitinsgupta193@gmail.com
*& Date:   27 Sep 2021
*& gitHub: DryDumbHead/easyHtmlEmail
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&The Report Demonstrate the useage of ZCL_EASY_EMAIL to Genrate
*&Beautiful email using HTML Templates (Uploaded Tcode- SMW0)
*&-------------------------PRE-REQUISITE-------------------------------*
*&    1)HTML template ZTESTEMAIL uploaded in SMW0, Template should have
*&      !VBELN!, !PRICE! , !LOG! placeholder for dynamic values
*&    2)Table ZMAIL_TEMP_CONF , with following defination:
*&     Fields            Data Element
*&     ------            ------------
*&      MANDT	            MANDT
*&      LANG              SPRAS
*&      SCOPE1            CHAR10
*&      SCOPE2            CHAR10
*&      TYPE              CHAR3
*&      TEMPLATENAME      SYCHAR40
*&      MASTERTEMPLATE    SYCHAR40
*&    3)Below entry in table ZMAIL_TEMP_CONF:
*&      030 | E | TEST1 | TEST1 | HTM | ZTESTEMAIL | ZTESTEMAILMASTER  |
*&    4)Class ZCL_EASY_EMAIL & FM Z_TEMP_SEND_MAIL
*&---------------------------------------------------------------------*

REPORT  zeasy_email_demo.

DATA: ok_code LIKE sy-ucomm.

* Declare the SWWW Type-Pool
TYPE-POOLS: swww.

* Data Declarations
DATA: lt_html_table   TYPE  swww_t_html_table.

DATA: lv_string TYPE string,
      lines     TYPE i.

DATA : ref_cont TYPE REF TO cl_gui_custom_container,
       ref_html TYPE REF TO cl_gui_html_viewer.
DATA : go_easy_email TYPE REF TO zcl_easy_email,
       return        TYPE sy-subrc.

PARAMETERS: p_price TYPE char10 .
PARAMETERS: p_vbeln TYPE char10 .
PARAMETERS: p_email TYPE ad_smtpadr .
PARAMETERS: snd_mail AS CHECKBOX DEFAULT ' '.

START-OF-SELECTION .


  CREATE OBJECT go_easy_email .

  go_easy_email->set_subject(
      title = 'mail subject '
  ).

  go_easy_email->set_template(
    EXPORTING
      scope1        = 'TEST1'
      scope2        = 'TEST1'
    RECEIVING
      return        = return
  ).
  IF return IS NOT INITIAL.
    go_easy_email->set_template(
      EXPORTING
*      language         = SY-LANGU         " Language Key
*      template_type    = 'HTM'
        p_template       = 'ZTESTEMAIL'           " email template
        p_mastertemplate = 'ZTESTEMAILMASTER'     " master template
*    RECEIVING
*      return           =                  " ABAP System Field: Return Code of ABAP Statements
    ).
  ENDIF.


  go_easy_email->replace_placeholder(
    EXPORTING
      placeholder_name = '!VBELN!'                 " Placeholder to be replaced
      replacement_type = 'R'              " ('A','B','R',' ')control value & placeholder
      single_value     = p_vbeln               " To be filled when 'A', 'B', 'R'
*    multi_line       =                  " To be filled when ' ' .
  ).

  go_easy_email->replace_placeholder(
    EXPORTING
      placeholder_name = '!PRICE!'                 " Placeholder to be replaced
      replacement_type = 'R'              " ('A','B','R',' ')control value & placeholder
      single_value     = p_price                " To be filled when 'A', 'B', 'R'
*    multi_line       =                  " To be filled when ' ' .
  ).

  DATA : multi_line TYPE soli_tab,
         line       TYPE soli.

  line = 'LINE 1 : LINE1 </br>'.
  APPEND line TO multi_line.
  line = 'LINE 2 : LINE2 </br>'.
  APPEND line TO multi_line.

  go_easy_email->replace_placeholder(
    EXPORTING
      placeholder_name = '!LOG!'                 " Placeholder to be replaced
      replacement_type = ' '              " ('A','B','R',' ')control value & placeholder
*    single_value     = ''                " To be filled when 'A', 'B', 'R'
      multi_line       =  multi_line                " To be filled when ' ' .
  ).


  "bulidng attachment
  DATA: lc_crlf   TYPE c VALUE cl_bcs_convert=>gc_crlf.

  DATA lv_binary_content TYPE solix_tab.
  DATA lv_size           TYPE so_obj_len.
  LOOP AT multi_line INTO line.
    CONCATENATE lv_string line lc_crlf INTO lv_string.
  ENDLOOP.

  TRY.
      cl_bcs_convert=>string_to_solix(
      EXPORTING
        iv_string   = lv_string
        iv_codepage = '4103'
        iv_add_bom  = ' '
      IMPORTING
        et_solix  = lv_binary_content
        ev_size   = lv_size ).
    CATCH cx_bcs.
      MESSAGE e445(so).

  ENDTRY.



  CLEAR multi_line[].

  go_easy_email->add_email( email = p_email ).
* go_EASY_EMAIL->add_email( email = 'test2.test@domain.com' ).

  go_easy_email->build_mail( ).

IF snd_mail IS NOT INITIAL.
  go_easy_email->add_attachment(
    EXPORTING
      attachment_type    = 'txt'                 " Code for document class
      attachment_size    = lv_size           " Size of Document Content
*    attachment_subject = 'Attachment'     " Short description of contents
      att_content_hex    =  lv_binary_content
  ).

  go_easy_email->add_attachment(
    EXPORTING
      attachment_type    = 'txt'                 " Code for document class
      attachment_size    = lv_size           " Size of Document Content
    attachment_subject = 'Attachment2'     " Short description of contents
      att_content_hex    =  lv_binary_content
  ).
ELSE.
  go_easy_email->build_body( ).
ENDIF.

  lt_html_table = go_easy_email->get_body( ).
  IF snd_mail IS NOT INITIAL.
    go_easy_email->send_mail( 'X' ).
  ENDIF.

  CALL SCREEN 200.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
*  SET PF-STATUS 'xxxxxxxx'.
*  SET TITLEBAR 'xxx'.

  CREATE OBJECT ref_cont
    EXPORTING
*     parent         =
      container_name = 'CONT'
*     style          =
*     lifetime       = lifetime_default
*     repid          =
*     dynnr          =
*     no_autodef_progid_dynnr     =
*  EXCEPTIONS
*     cntl_error     = 1
*     cntl_system_error           = 2
*     create_error   = 3
*     lifetime_error = 4
*     lifetime_dynpro_dynpro_link = 5
*     others         = 6
    .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


  CREATE OBJECT ref_html
    EXPORTING
*     shellstyle         =
      parent = ref_cont
*     lifetime           = lifetime_default
*     saphtmlp           =
*     uiflag =
*     name   =
*     saphttp            =
*     query_table_disabled = ''
*  EXCEPTIONS
*     cntl_error         = 1
*     cntl_install_error = 2
*     dp_install_error   = 3
*     dp_error           = 4
*     others = 5
    .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  DATA: url(200) TYPE c.
  CALL METHOD ref_html->load_data
    EXPORTING
*     url          = lv_string
      type         = 'text'
      subtype      = 'html'
*     size         = 0
*     encoding     =
*     charset      =
*     language     =
    IMPORTING
      assigned_url = url
    CHANGING
      data_table   = lt_html_table
*   EXCEPTIONS
*     dp_invalid_parameter = 1
*     dp_error_general     = 2
*     cntl_error   = 3
*     others       = 4
    .
  IF sy-subrc <> 0.
*  MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*             WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CALL METHOD ref_html->show_url
    EXPORTING
      url = url
*     frame                  =
*     in_place               = ' X'
*  EXCEPTIONS
*     cntl_error             = 1
*     cnht_error_not_allowed = 2
*     cnht_error_parameter   = 3
*     dp_error_general       = 4
*     others                 = 5
    .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDMODULE.                 " STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok_code.
    WHEN 'BACK'.

      IF NOT ref_html IS INITIAL.
        CALL METHOD ref_html->free.
        FREE ref_html.
      ENDIF.
      LEAVE TO SCREEN  0.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0200  INPUT
