*&---------------------------------------------------------------------*
*& Title:  demo usage of zcl_easy_email
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
*&      030 | E | TEST1 | TEST1 | HTM | ZTESTEMAIL |      |
*&    4)Class ZCL_EASY_EMAIL & FM Z_TEMP_SEND_MAIL
*&---------------------------------------------------------------------*

REPORT  zeasy_email_demo.

 data: ok_code LIKE sy-ucomm.

* Declare the SWWW Type-Pool
TYPE-POOLS: swww.

* Data Declarations
DATA: lt_html_table   TYPE  swww_t_html_table.

DATA: lv_string       TYPE string,
      lines TYPE I.

DATA : ref_cont TYPE REF TO cl_gui_custom_container,
       ref_html TYPE REF TO cl_gui_html_viewer.
DATA : go_EASY_EMAIL TYPE REF TO ZCL_EASY_EMAIL.

PARAMETERS: p_Price TYPE char10.
PARAMETERS: p_VBELN TYPE char10.
PARAMETERS: P_email TYPE AD_SMTPADR.
PARAMETERS: SND_MAIL AS CHECKBOX DEFAULT ' '.

START-OF-SELECTION .


CREATE OBJECT go_EASY_EMAIL .

go_EASY_EMAIL->set_subject(
    title = 'mail subject '
).

go_EASY_EMAIL->set_template(
  EXPORTING
    scope1        = 'TEST1'
    scope2        = 'TEST1'
).

go_EASY_EMAIL->replace_placeholder(
  EXPORTING
    placeholder_name = '!VBELN!'                 " Placeholder to be replaced
    replacement_type = 'R'              " ('A','B','R',' ')control value & placeholder
    single_value     = p_VBELN               " To be filled when 'A', 'B', 'R'
*    multi_line       =                  " To be filled when ' ' .
).

go_EASY_EMAIL->replace_placeholder(
  EXPORTING
    placeholder_name = '!PRICE!'                 " Placeholder to be replaced
    replacement_type = 'R'              " ('A','B','R',' ')control value & placeholder
    single_value     = p_price                " To be filled when 'A', 'B', 'R'
*    multi_line       =                  " To be filled when ' ' .
).

 data : multi_line TYPE soli_tab,
        line TYPE soli.

 line = 'LINE 1 : LINE1'.
 APPEND LINE to multi_line.
  line = 'LINE 2 : LINE2'.
 APPEND LINE to multi_line.
  line = 'LINE 3 : LINE3'.
 APPEND LINE to multi_line.
  line = 'LINE 4 : LINE4'.
 APPEND LINE to multi_line.

go_EASY_EMAIL->replace_placeholder(
  EXPORTING
    placeholder_name = '!LOG!'                 " Placeholder to be replaced
    replacement_type = ' '              " ('A','B','R',' ')control value & placeholder
*    single_value     = ''                " To be filled when 'A', 'B', 'R'
    multi_line       =  multi_line                " To be filled when ' ' .
).

 clear multi_line[].

 go_EASY_EMAIL->add_email( email = p_email ).
* go_EASY_EMAIL->add_email( email = 'test2.test@domain.com' ).

 go_EASY_EMAIL->build_body( ).

 lt_html_table = go_EASY_EMAIL->get_body( ).
 IF SND_MAIL IS NOT INITIAL.
   go_EASY_EMAIL->send_mail( 'X' ).
 ENDIF.

CALL SCREEN 200.


*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module STATUS_0200 output.
*  SET PF-STATUS 'xxxxxxxx'.
*  SET TITLEBAR 'xxx'.

CREATE OBJECT ref_cont
  EXPORTING
*    parent                      =
    container_name              = 'CONT'
*    style                       =
*    lifetime                    = lifetime_default
*    repid                       =
*    dynnr                       =
*    no_autodef_progid_dynnr     =
*  EXCEPTIONS
*    cntl_error                  = 1
*    cntl_system_error           = 2
*    create_error                = 3
*    lifetime_error              = 4
*    lifetime_dynpro_dynpro_link = 5
*    others                      = 6
    .
IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
ENDIF.


CREATE OBJECT ref_html
  EXPORTING
*    shellstyle         =
    parent             = ref_cont
*    lifetime           = lifetime_default
*    saphtmlp           =
*    uiflag             =
*    name               =
*    saphttp            =
*    query_table_disabled = ''
*  EXCEPTIONS
*    cntl_error         = 1
*    cntl_install_error = 2
*    dp_install_error   = 3
*    dp_error           = 4
*    others             = 5
    .
IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
ENDIF.
DATA: url(200) TYPE c.
 CALL METHOD ref_html->load_data
   EXPORTING
*     url                  = lv_string
     type                 = 'text'
     subtype              = 'html'
*     size                 = 0
*     encoding             =
*     charset              =
*     language             =
   IMPORTING
     assigned_url         = url
   CHANGING
     data_table           = lt_html_table
*   EXCEPTIONS
*     dp_invalid_parameter = 1
*     dp_error_general     = 2
*     cntl_error           = 3
*     others               = 4
         .
 IF sy-subrc <> 0.
*  MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*             WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
 ENDIF.

CALL METHOD ref_html->show_url
  EXPORTING
    url                    = url
*    frame                  =
*    in_place               = ' X'
*  EXCEPTIONS
*    cntl_error             = 1
*    cnht_error_not_allowed = 2
*    cnht_error_parameter   = 3
*    dp_error_general       = 4
*    others                 = 5
        .
IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
ENDIF.


endmodule.                 " STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module USER_COMMAND_0200 input.

  case ok_code.
    when 'BACK'.

      IF NOT ref_html IS INITIAL.
        CALL METHOD ref_html->free.
        FREE ref_html.
      ENDIF.
      LEAVE to SCREEN  0.
  ENDCASE.

endmodule.                 " USER_COMMAND_0200  INPUT
