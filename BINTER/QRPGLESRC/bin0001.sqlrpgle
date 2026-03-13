**FREE
  // ------------------------------------------------------------------------
  // - Modulo de BINTER - Servicio Web
  //       Procesamiento de Solicitudes
  // - Autor: Ludolfo Montero
  // - Fecha: Marzo 2026
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/BIN0001) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR(BIN0001) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  * Procesa CRUD de la tabla ANX_CATALOGO_ANEXOS
  //  * Utiliza el SRVPGM ANXSRV
  //
  // ------------------------------------------------------------------------
  // COMPILATION:
  // CRTSQLRPGI OBJ(APISDINERS/MCACCV1) SRCFILE(DGIANNINI/QRPGLESRC) COMMIT(*NONE)
  // OPTION(*SQL) CLOSQLCSR(*ENDMOD) DBGVIEW(*SOURCE)
  // ###############################################################################################
  // #################################           S T A R T            ##############################
  // ###############################################################################################
  ctl-opt dftactgrp(*no) option(*SRCSTMT) actgrp(*CALLER)
          bnddir('NOXDB':'UTWSSRVBD':'LOGTOOL':'HTTPAPI':'EXPLOTA/SERVWEB')
          decedit('0.');
  // Include y Copy obligatorios en todos los desarrollos
  // ----------------------------------------------------
  /Define UTWSSRV_WEB
  /Define SetLibraryList
  /Define getenvvar
  /Define UTWSSRV_SendHttpError
  /Define UTWSSRV_PSDS
  /Define result_Gen_Sql_t
  /Define UTWSSRV_Variables
  /Include APISDINERS/QRPGLESRC,UTWSSRV_H2

  // Include y Copy particulares al desarrollo
  // ----------------------------------------------------
  /Define BIN_Process
  /Include EXPLOTA/QRPGLESRC,BINCPY_H
  // ###############################################################################################
  // --------------------------
  // Declaracion de Variables
  // --------------------------
  dcl-s  posIniIdSolic      int(3);
  dcl-s  posFinIdSolic      int(3);
  dcl-s  lenIdSolic         int(3);
  dcl-s  idSolicParm      varchar(10);
  Dcl-s  WIDFile            Int(10);
  Dcl-s  NoUri              Ind;

  dcl-s WDsply                  char(1);
  // --------------------------
  // Declaracion de Estructuras
  // --------------------------

  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *chg,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

  // -------------------------------------------------------------------------------------
  // Init
  // ----...........................................................----------------------
  // Carga libreria del ambiente
  SetLibraryList();

  //Recupera datos del JOB
  job = psds.jobnumber + SLASH + %trim(psds.jobuser) + SLASH + %trim(psds.jobname);

  //dsply 'BIN0001' ' ' WDSPLY;

  // ID de la Aplicaciones de LOGs
  P_ID = 'BINTER';

  // Validating request data.
  varp = getenvvar('DOCUMENT_URI');
  if varp <> *null;
    uri = %str(varp);
    If %scan('/binter/':uri) > 0;
      posIniIdSolic = %scan('/binter/':uri) + 8;
      posFinIdSolic = posIniIdSolic + 10;
      monitor;
        lenIdSolic = posFinIdSolic-posIniIdSolic;
        idSolicParm=%subst(uri:posIniIdSolic:lenIdSolic);
        WIDFile=%int(idSolicParm);

      on-error;
        UTWSSRV_SendHttpError(400: job : BAD_REQUEST: 'Error id_request');
        return;
      endmon;
    EndIf;
  else;
    UTWSSRV_SendHttpError(400: job : BAD_REQUEST: 'URI is missing.');
    return;
  endif;

  // Checking the method
  varp = getenvvar('REQUEST_METHOD');
  if varp = *null;
    UTWSSRV_SendHttpError(400: job : BAD_REQUEST: 'There request''s Method is missing.');
    return;
  else;
    method = %str(varp);
  endif;

  // Determina Metodos autoirzados
  select;
    when method = POST;    //Insert
      PostRequest();
    other;
      UTWSSRV_SendHttpError(405: job : BAD_REQUEST: 'The requested Method not allowed.');
  endsl;

  *inlr = *on;
  // ########################################################################################
  // ##########################         M E T H O D S          ##############################
  // ########################################################################################
  // ######################################################################
  // ################              POST              ######################
  // ######################################################################
  dcl-proc PostRequest;
    dcl-pi *n;
    end-pi;

    // ---------------------------------
    // Declaracion de Variables Locales
    // ---------------------------------
    dcl-s jsonIn                  pointer;
    dcl-s jsonOut                 pointer;

    Dcl-s WMsg_Error              Char(200);
    Dcl-s WRstProc                Char(  2);
    Dcl-s WRegProc                Zoned(6);

    dcl-ds resultSql     likeds(result_Gen_Sql_t);

    // ----------------------------------
    // Declaracion de Estructuras Locales
    // ----------------------------------

    jsonOut = json_newObject();

    MONITOR;
  
      Exec Sql
        Select 
          Count(*)
        Into :WRegProc
        From FICHEROS.AMADEUS_BINTER_INVOICE_FILE_DETAILS bin
        Where
          bin.Processed <> 0
          and ID_FILE = :WIDFile
        Group by ID_FILE;
      If Sqlcode = 0 and WRegProc > 0;
        UTWSSRV_SendHttpError(400: job : BAD_REQUEST: 
        'El fichero ya ha sido procesado. Registros: ' + 
        %Editc(WRegProc: 'X') );
        return;
      Endif;

      ProcBINTER(WRstProc);
      // Insercion de Datos recibidos

      select;
        when WRstProc = 'OK';
          JSON_SetStr( jsonOut : 'response' :
          'Solicitud procesada correctamente' );
          JSON_SendHTTPResponse( jsonOut : 200 );
        when WRstProc = 'KO';
          JSON_SetStr( jsonOut : 'message'
          :'La solicitud no se ha realizado');
          JSON_SendHTTPResponse( jsonOut : 500 );
      endsl;

    ON-ERROR;
      Write_log(p_id: 'ERR': 'BIN0001-Error en el PostRequest');

    ENDMON;

    json_delete(jsonOut);
    json_delete(jsonIn);

  end-proc;