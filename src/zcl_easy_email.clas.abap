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
      !SCOPE1 type CHAR10 optional
      !SCOPE2 type CHAR10 optional
      !TEMPLATE_TYPE type CHAR3 default 'HTM'
      !P_TEMPLATE type SYCHAR40 optional
      !P_MASTERTEMPLATE type SYCHAR40 optional
    returning
      value(RETURN) type SY-SUBRC .
  methods ADD_EMAIL
    importing
      !EMAIL type AD_SMTPADR .
  methods ADD_DIST_LIST
    importing
      !DL type SO_OBJ_NAM .
  methods SEND_MAIL
    importing
      !COMMIT type CHAR1
      !UNAME type UNAME default SY-UNAME
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
  methods BUILD_MAIL
    returning
      value(SEND_REQ_OBJECT) type ref to CL_BCS
    exceptions
      NO_RECEPIENT .
  methods ADD_ATTACHMENT
    importing
      !ATTACHMENT_TYPE type SOODK-OBJTP
      !ATTACHMENT_SIZE type SOOD-OBJLEN
      !ATTACHMENT_SUBJECT type SOOD-OBJDES default 'Attachment'
      !ATT_CONTENT_HEX type SOLIX_TAB .
protected section.
private section.

  data EMAIL_TEMPLATE type SYCHAR40 .
  data MASTER_TEMPLATE type SYCHAR40 .
  data MAIL_BODY type SOLI_TAB .
  data SUBJECT type SO_OBJ_DES .
  data PLACEHOLDERS type SWWW_T_MERGE_TABLE .
  data:
    recipient TYPE TABLE OF SOMLRECI1 .
  constants:
*REGEX for Alphanumeric chars encapsulated by '!'
*  EG: "!Alpha_123!"
    REGX_EXCL_ALPHANUM_EXCL(20) value '.!(\W{1,}).!' ##NO_TEXT.
  data GO_SEND_REQUEST type ref to CL_BCS .
  data GO_DOCUMENT type ref to CL_DOCUMENT_BCS .

  methods REMOVE_UNHANDLE_PLACEHOLDER
    importing
      !PLACEHOLDER_PATTERN type CHAR20 .
ENDCLASS.



CLASS ZCL_EASY_EMAIL IMPLEMENTATION.


  method ADD_ATTACHMENT.

    IF go_document is NOT BOUND.
       me->build_mail( ).
    endif.


    go_document->add_attachment(
      i_attachment_type    = attachment_type
      i_attachment_size    = attachment_size
      i_attachment_subject = attachment_subject
      i_att_content_hex    = att_content_hex ).
  endmethod.


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

    DATA: master_placeholder TYPE swww_t_merge_table,
          ls_placeholder     LIKE LINE OF master_placeholder,
          mail_body2         TYPE soli_tab.
    CLEAR mail_body[].
    IF placeholders[] IS NOT INITIAL AND me->email_template IS NOT INITIAL.
      CALL FUNCTION 'WWW_HTML_MERGER'
        EXPORTING
          template    = email_template
        IMPORTING
          html_table  = mail_body[]
        CHANGING
          merge_table = placeholders.
      IF me->master_template IS NOT INITIAL.
        CLEAR : ls_placeholder, master_placeholder.

        ls_placeholder-name = '!MAIN_BODY!'.
        ls_placeholder-command = ' '.
        APPEND LINES OF mail_body[] TO ls_placeholder-html[].
        APPEND ls_placeholder TO master_placeholder.

        CALL FUNCTION 'WWW_HTML_MERGER'
          EXPORTING
            template    = me->master_template
          IMPORTING
            html_table  = mail_body2[]
          CHANGING
            merge_table = master_placeholder.
        IF sy-subrc = 0.
          mail_body[] = mail_body2[].
          CLEAR mail_body2[].
        ENDIF.

      ENDIF.
    ENDIF.

    IF rm_unhndl_plchldr IS NOT INITIAL.
      me->remove_unhandle_placeholder( me->placeholder_pattern ).
    ENDIF.

  ENDMETHOD.


  method BUILD_MAIL.


  "******************************************************"
  " SAP send mail with CL_BCS
  "******************************************************"

  DATA: lx_document_bcs     TYPE REF TO cx_document_bcs.
  DATA: lt_att_content_hex  TYPE solix_tab .
  DATA: lt_message_body     TYPE bcsy_text.
  DATA: lo_recipient        TYPE REF TO if_recipient_bcs  .
  DATA: lv_with_error_screen  TYPE os_boolean .
  DATA: lv_length_mime      TYPE num12.
  DATA: lv_mime_type        TYPE w3conttype.
  DATA: attachment       TYPE solix_tab.
  DATA: lv_attachment_type  TYPE soodk-objtp.
  DATA: lv_attachment_size  TYPE sood-objlen.
  DATA: lv_attachment_subject TYPE sood-objdes.
  DATA: lt_body         TYPE soli_tab.
  DATA: lv_mail_subject     TYPE  so_obj_des.
  DATA: lv_type             TYPE string.
  DATA: lv_extension        TYPE string.
  DATA: lv_docid_str(12)    .
  DATA: lv_email            TYPE adr6-smtp_addr.
  DATA: wa_recipient        LIKE LINE OF recipient.




  "-------------------------------------------"
  " Assining values
  "-------------------------------------------"
  lv_mail_subject = subject.

  me->build_body( ).
  lt_body = MAIL_BODY.


  if recipient[] is INITIAL.
    RAISE NO_RECEPIENT.
  ENDIF.
  "-------------------------------------------"
  " Send Email
  "-------------------------------------------"
  TRY.

    go_send_request = cl_bcs=>create_persistent( ).

    " Set the subjest of email
    "lv_mail_subject up to 50 c.

    " Send in HTML format
    go_document = cl_document_bcs=>create_document(
    i_type    = 'HTM'
    i_text     = lt_body
    i_subject = lv_mail_subject ) .

    " add the document as an attachment
    IF attachment[] IS NOT INITIAL .

      lv_attachment_size    = lv_length_mime.
      lt_att_content_hex[]  = attachment[].

      lv_attachment_subject = 'Your Attachment Name' .

      go_document->add_attachment(
      i_attachment_type    = lv_attachment_type
      i_attachment_size    = lv_attachment_size
      i_attachment_subject = lv_attachment_subject
      i_att_content_hex    = lt_att_content_hex ).
    ENDIF.


    " set the e-mail address of the recipient
    LOOP AT recipient INTO wa_recipient.
      lv_email = wa_recipient-receiver.
      lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_email ).
      go_send_request->add_recipient( lo_recipient ) .
    ENDLOOP.

    " assign document to the send request:
    go_send_request->set_document( go_document ).


    SEND_REQ_OBJECT = go_send_request.


  CATCH cx_document_bcs INTO lx_document_bcs.


  ENDTRY.

  endmethod.


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

    DATA: lo_sender           TYPE REF TO if_sender_bcs.


    if go_send_request IS NOT BOUND.
      me->BUILD_MAIL( ).
    endif.
    "****************************"
    " EMAIL
    "*****************************"
    " set the e-mail address of the sender:
    IF uname IS INITIAL.
      lo_sender = cl_sapuser_bcs=>create( sy-uname ).
    ELSE.
      lo_sender = cl_sapuser_bcs=>create( uname ).
    ENDIF.
    " add the sender:
    go_send_request->set_sender( lo_sender ).


    sent_to_all  = go_send_request->send( ).
    IF sent_to_all IS NOT INITIAL AND commit EQ 'X'.
      COMMIT WORK.
    ENDIF.

*
*    CALL FUNCTION 'Z_TEMP_SEND_MAIL'
*     EXPORTING
*       SUBJECT           = subject
*       MAIL_BODY         = MAIL_BODY
*
*       COMMIT_WORK       = COMMIT
*       UNAME             = SY-UNAME
*     IMPORTING
*       SENT_TO_ALL       = SENT_TO_ALL
*      TABLES
*        receiver          = recipient
*              .
  ENDMETHOD.


  method SET_SUBJECT.
    ME->subject = title.
  endmethod.


  method SET_TEMPLATE.


    IF ( SCOPE1 IS NOT INITIAL OR SCOPE2 IS NOT INITIAL ) .
        select SINGLE TEMPLATENAME MASTERTEMPLATE
                        INTO  ( EMAIL_TEMPLATE , master_template )
                        FROM ZMAIL_TEMP_CONF
                        WHERE LANG   = LANGUage
                          AND SCOPE1 = scope1
                          AND SCOPE2 = scope2
                          AND TYPE = TEMPLATE_TYPE.
        if sy-subrc <> 0.
         RETURN = 4.
         EXIT.
        endif.
    ELSEIF ( P_TEMPLATE IS  NOT INITIAL ).
        EMAIL_TEMPLATE = P_TEMPLATE.
        MASTER_TEMPLATE = P_MASTERTEMPLATE.
    ELSE.
      RETURN = 1.
      EXIT.

    ENDIF.

  endmethod.
ENDCLASS.
