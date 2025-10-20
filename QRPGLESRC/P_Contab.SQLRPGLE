**Free
  //*----------------------------------------------------------*//
  // Proceso que prepara el ambiente para ejecutar programa de *//
  // Contabilidad Modificado y tener un Paraelo                *//
  // Fecha: Octubre 2025                                   LM  *//
  //*----------------------------------------------------------*//
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
            decedit('0,') datedit(*DMY/)
            dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------
  //* Declarar prototipo de QCMDEXC */
  Dcl-Pr QCMDEXC ExtPgm('QCMDEXC');
    CmdString VarChar(32767) Const;
    CmdLength Packed(15:5) Const;
  End-Pr;
  // --------------------------
  // Cpys y Include
  // --------------------------

  /Include UTILITIES/QRPGLESRC,PSDSCP  
  /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
  ///Define dsOPATMXCTpl
  ///Include EXPLOTA/QRPGLESRC,CONTAB_H

  // --------------------------
  //Declaracion de variables
  // --------------------------
  Dcl-S WLibParalelo Char(10) Inz('PARALELOC');
  Dcl-S Comando VarChar(500);


  // --------------------------
  // Declaracion Estructuras
  // --------------------------
  Dcl-DS DS_ConfigProcess Qualified Template Inz;
    ID_PROCESO             Char(10);
    DESCRIPCION_PROCESO    Char(200);
    FILE_REQUERIDO         Char(10);
    FILE_TYPE              Char(1);
    FILE_LIB_ORIGEN        Char(10);
    SI_DATA                Char(1);
    ESTATUS                Char(1);
    FEC_CREACION           Timestamp;
    USUARIO_CREACION       Char(10);
    FEC_MODIFICACION       Timestamp;
    USUARIO_MODIFICACION   Char(10);
  End-DS;

  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *none,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

    // Solicitudes Pendientes
  Exec Sql declare  C_PARALELO Cursor For
    Select 
      ID_PROCESO, DESCRIPCION_PROCESO, FILE_REQUERIDO,
      FILE_TYPE, FILE_LIB_ORIGEN, SI_DATA
    From PARALELOC.PARALELO_COFIG_PROCESS
    Where 
      ID_PROCESO = :WId_Process
      AND ESTATUS = 'A';

  // ******************************************************************
  // PROCESO PRINCIPAL
  // ******************************************************************
  dcl-proc main;

    dcl-pi *n;
      WId_Process Char(10) const; // Id del Proceso a ejecutar
    end-pi;

    Exec Sql Open  C_PARALELO;
    sqlStt = '00000';

    Exec Sql Fetch From  C_PARALELO into :DS_ConfigProcess;
    dow sqlStt = '00000';

      If DS_ConfigProcess.SI_DATA = 'S';
        If Not Copia_Data_Origen();
          // Error en la copia de datos
          Return;
        EndIf;
      EndIf;

      Exec Sql Fetch From  C_PARALELO into :DS_ConfigProcess;
    EndDo;

    Exec Sql Close  C_PARALELO;

  End-Proc;

  //-----------------------------------------------------------------
  // Copia Fichero desde el Origen con data o Sin Data
  //-----------------------------------------------------------------
  dcl-proc Copia_Data_Origen_CD;
    dcl-pi *n Ind;
    end-pi;

    Dcl-s WIndx    Zoned(3);
    Dcl-s WImp_Gastos Zoned(14:3);
    Dcl-S MsgId   Char(7);
    Dcl-S MsgText Varchar(512);

    If DS_ConfigProcess.SI_DATA = 'S';
      Comando = 
        'CPYF FROMFILE('                                               +
        %Trim(DS_ConfigProcess.FILE_LIB_ORIGEN.FILE_LIB_ORIGEN)        +
        '/'                                                            +
        %trim(DS_ConfigProcess.FILE_REQUERIDO)                         +  
        ') TOFILE(PARALELOC/'                                          +
        %trim(DS_ConfigProcess.FILE_REQUERIDO)                         +  
        ') MBROPT(*REPLACE) CRTFILE(*YES)';
    Else;
      Comando = 
        'CRTDUPOBJ OBJ('                                               +
        %Trim(DS_ConfigProcess.FILE_LIB_ORIGEN.FILE_LIB_ORIGEN)        +
        '/'                                                            +
        %trim(DS_ConfigProcess.FILE_REQUERIDO)                         +  
        ') FROMLIB(FICHEROS) OBJTYPE(*FILE) TOLIB(PARALELOC)';
    EndIf;    

    Exec SQL
      CALL QSYS2.QCMDEXC(:Comando);       // segunda parm (espera) es opcional

    If SQLCODE < 0;
      Exec SQL
        Get Diagnostics Condition 1
           :MsgId   = MESSAGE_ID,
           :MsgText = MESSAGE_TEXT;

      V_observacion = %Editc(MsgId:'X') + %Trim(MsgText);
      Diagnostico(jobname:V_observacion:V_tipo_error);
    endif;

    Return *On;

  end-proc;