FUNCTION Z_TEMP_SEND_MAIL.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SUBJECT) TYPE  SO_OBJ_DES DEFAULT 'no title'
*"     VALUE(MAIL_BODY) TYPE  SOLI_TAB OPTIONAL
*"     VALUE(LANG) TYPE  SY-LANGU OPTIONAL
*"     VALUE(COMMIT_WORK) TYPE  SONV-FLAG DEFAULT 'X'
*"     VALUE(UNAME) TYPE  SY-UNAME DEFAULT SY-UNAME
*"  EXPORTING
*"     VALUE(SENT_TO_ALL) TYPE  OS_BOOLEAN
*"  TABLES
*"      RECEIVER STRUCTURE  SOMLRECI1
*"  EXCEPTIONS
*"      NO_RECEPIENT
*"----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*& Title:  Function module to send email
*& Author: DryDumbHead (Nitinkumar Gupta)
*& email:  nitinsgupta193@gmail.com
*& Date:   27 Sep 2021
*& gitHub: DryDumbHead/easyHtmlEmail
*&---------------------------------------------------------------------*

  "******************************************************"
  " SAP send mail with CL_BCS
  "******************************************************"
  DATA: lo_document         TYPE REF TO cl_document_bcs.
  DATA: lx_document_bcs     TYPE REF TO cx_document_bcs.
  DATA: lo_send_request     TYPE REF TO cl_bcs.
  DATA: lo_sender           TYPE REF TO if_sender_bcs.
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





  "-------------------------------------------"
  " Assining values
  "-------------------------------------------"
  lv_mail_subject = subject.
  lt_body = MAIL_BODY.


  if receiver[] is INITIAL.
    RAISE NO_RECEPIENT.
  ENDIF.
  "-------------------------------------------"
  " Send Email
  "-------------------------------------------"
  TRY.

    lo_send_request = cl_bcs=>create_persistent( ).

    " Set the subjest of email
    "lv_mail_subject up to 50 c.

    " Send in HTML format
    lo_document = cl_document_bcs=>create_document(
    i_type    = 'HTM'
    i_text     = lt_body
    i_subject = lv_mail_subject ) .

    " add the document as an attachment
    IF attachment[] IS NOT INITIAL .

      lv_attachment_size    = lv_length_mime.
      lt_att_content_hex[]  = attachment[].

      lv_attachment_subject = 'Your Attachment Name' .

      lo_document->add_attachment(
      i_attachment_type    = lv_attachment_type
      i_attachment_size    = lv_attachment_size
      i_attachment_subject = lv_attachment_subject
      i_att_content_hex    = lt_att_content_hex ).
    ENDIF.

    "****************************"
    " EMAIL
    "*****************************"
    " set the e-mail address of the sender:
    if uname is INITIAL.
      lo_sender = cl_sapuser_bcs=>create( sy-uname ).
    else.
    lo_sender = cl_sapuser_bcs=>create( uname ).
    ENDIF.

    " set the e-mail address of the recipient

    LOOP AT receiver .
      lv_email = receiver-receiver.
      lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_email ).
      lo_send_request->add_recipient( lo_recipient ) .
    ENDLOOP.

    " assign document to the send request:
    lo_send_request->set_document( lo_document ).

    " add the sender:
    lo_send_request->set_sender( lo_sender ).


    MOVE space TO lv_with_error_screen.
    " SAP Send Email CL_BCS
    sent_to_all  = lo_send_request->send( lv_with_error_screen ).

  CATCH cx_document_bcs INTO lx_document_bcs.


  ENDTRY.

  if sent_to_all is not INITIAL.
    COMMIT WORK.
  ENDIF.
ENDFUNCTION.
