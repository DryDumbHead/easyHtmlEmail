class ZCL_EASY_EMAIL definition
  public
  final
  create public .

public section.

  data PLACEHOLDER_PATTERN type CHAR20 value '.!(\W{1,}).!' ##NO_TEXT.

  methods REPLACE_PLACEHOLDER
    importing
      !PLACEHOLDER_NAME type CHAR30
      !REPLACEMENT_TYPE type CHAR1 default 'R'
      !SINGLE_VALUE type DATA optional
      !MULTI_LINE type SOLI_TAB optional .
  methods SET_TEMPLATE
    importing
      !LANGUAGE type SPRAS default SY-LANGU
      !SCOPE1 type CHAR10
      !SCOPE2 type CHAR10
      !TEMPLATE_TYPE type CHAR3 default 'HTM' .
  methods ADD_EMAIL
    importing
      !EMAIL type AD_SMTPADR .
  methods ADD_DIST_LIST
    importing
      !DL type SO_OBJ_NAM .
  methods SEND_MAIL
    importing
      !COMMIT type CHAR1
    returning
      value(SENT_TO_ALL) type CHAR1 .
  methods GET_BODY
    returning
      value(MAIL_BODY) type SOLI_TAB .
  methods SET_SUBJECT
    importing
      !TITLE type STRING default 'NO Title' .
  methods BUILD_BODY
    importing
      !RM_UNHNDL_PLCHLDR type CHAR1 default 'X' .
  methods REMOVE_UNHANDLE_PLACEHOLDER
    importing
      !PLACEHOLDER_PATTERN type CHAR20 .
protected section.
private section.

  data EMAIL_TEMPLATE type SYCHAR40 .
  data MAIL_BODY type SOLI_TAB .
  data SUBJECT type SO_OBJ_DES .
  data RETURN type SY-SUBRC .
  data PLACEHOLDERS type SWWW_T_MERGE_TABLE .
  data:
    recipient TYPE TABLE OF SOMLRECI1 .

*REGEX for Alphanumeric chars encapsulated by '!'
*  EG: "!Alpha_123!"
  CONSTANTS REGX_EXCL_ALPHANUM_EXCL(20) VALUE '.!(\W{1,}).!'.
ENDCLASS.



CLASS ZCL_EASY_EMAIL IMPLEMENTATION.


  method ADD_DIST_LIST.
    DATA : lt_members1 TYPE STANDARD TABLE OF sodlienti1,
         ls_members1 TYPE sodlienti1,
         ls_recipient TYPE SOMLRECI1.

    CALL FUNCTION 'SO_DLI_READ_API1'
    EXPORTING
        dli_name                         = DL
*              DLI_ID                           = ' '
        shared_dli                       = 'X'
*            IMPORTING
*              DLI_DATA                         =
     TABLES
       dli_entries                      = lt_members1
     EXCEPTIONS
       dli_not_exist                    = 1
       operation_no_authorization       = 2
       parameter_error                  = 3
       x_error                          = 4
       OTHERS                           = 5
              .
    IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

    LOOP AT lt_members1 INTO ls_members1.
      MOVE: ls_members1-member_adr TO ls_recipient-receiver.
      APPEND ls_recipient to recipient.
    ENDLOOP.


  endmethod.


  METHOD add_email.
    DATA ls_recipient TYPE somlreci1.
    IF email IS NOT INITIAL.
      ls_recipient-receiver = email.
      TRANSLATE ls_recipient-receiver TO UPPER CASE.
      APPEND ls_recipient TO recipient.
    ENDIF.
  ENDMETHOD.


  METHOD build_body.

    IF placeholders[] IS NOT INITIAL AND email_template IS NOT INITIAL.
      CALL FUNCTION 'WWW_HTML_MERGER'
        EXPORTING
          template    = email_template
        IMPORTING
          html_table  = mail_body[]
        CHANGING
          merge_table = placeholders.
    ENDIF.

    if RM_UNHNDL_PLCHLDR is NOT INITIAL.
      me->remove_unhandle_placeholder( me->placeholder_pattern ).
    ENDIF.

  ENDMETHOD.


  method GET_BODY.
    MAIL_BODY = me->MAIL_BODY.
  endmethod.


  method REMOVE_UNHANDLE_PLACEHOLDER.

  DATA: RESULT_TAB TYPE MATCH_RESULT_TAB, W_RESULT_TAB LIKE LINE OF RESULT_TAB .
  DATA: DELETED_ROWS_COUNT TYPE I .




*Find lines containing pattern
  FIND ALL OCCURRENCES OF REGEX  placeholder_PATTERN
           IN TABLE me->MAIL_BODY
           RESULTS RESULT_TAB.

*Delete lines containing pattern
  LOOP AT RESULT_TAB INTO W_RESULT_TAB.
    SUBTRACT DELETED_ROWS_COUNT FROM W_RESULT_TAB-LINE.
    DELETE ME->mail_body INDEX W_RESULT_TAB-LINE.
    IF SY-SUBRC = 0.
      ADD 1 TO DELETED_ROWS_COUNT.
    ENDIF.
  ENDLOOP.
  endmethod.


  METHOD REPLACE_PLACEHOLDER.

    DATA PLACEHOLDER TYPE SWWW_T_MERGE_ITEM.
    DATA LV_STRING TYPE STRING.

    CLEAR: PLACEHOLDER, LV_STRING.

    PLACEHOLDER-NAME = PLACEHOLDER_NAME.
    PLACEHOLDER-COMMAND = REPLACEMENT_TYPE.

    IF REPLACEMENT_TYPE CA ( 'ABR' ).
      LV_STRING = SINGLE_VALUE.
      CONDENSE LV_STRING.
      APPEND LV_STRING TO PLACEHOLDER-HTML[].
    ELSE.
      PLACEHOLDER-HTML[] = MULTI_LINE[].
    ENDIF.

    APPEND PLACEHOLDER TO PLACEHOLDERS.

  ENDMETHOD.


  METHOD send_mail.




    CALL FUNCTION 'Z_TEMP_SEND_MAIL'
     EXPORTING
       SUBJECT           = subject
       MAIL_BODY         = MAIL_BODY

       COMMIT_WORK       = COMMIT
       UNAME             = SY-UNAME
     IMPORTING
       SENT_TO_ALL       = SENT_TO_ALL
      TABLES
        receiver          = recipient
              .
  endmethod.


  method SET_SUBJECT.
    ME->subject = title.
  endmethod.


  method SET_TEMPLATE.


    IF SCOPE1 IS INITIAL AND SCOPE2 IS INITIAL.
      RETURN = 1.
      EXIT.
    ENDIF.

    select SINGLE TEMPLATENAME FROM ZMAIL_TEMP_CONF
                        INTO  EMAIL_TEMPLATE
                        WHERE LANG = LANGUage
                          AND SCOPE1 = scope1
                          AND SCOPE2 = scope2
                          AND TYPE = TEMPLATE_TYPE.
    if sy-subrc <> 0.
     RETURN = 4.
     EXIT.
    endif.

  endmethod.
ENDCLASS.
