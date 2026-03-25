**FREE
  // ------------------------------------------------------------------------
  // - Borrado de Spooler con mas de 20 dias de antiguedad en colas especificas
  // - Autor: Ludolfo Montero
  // - Fecha: Marzo 2025
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/DLTSPOOL) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR(DLTSPOOL) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  *
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
    decedit('0,') datedit(*DMY/)
    //bnddir('UTILITIES/UTILITIES')
    dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------
  dcl-pr Execute extpgm('QCMDEXC');
    *n char(32000) const options(*varsize);
    *n packed(15: 5) const;
  end-pr;

  // --------------------------
  // Cpys y Include
  // --------------------------

  // --------------------------
  // Declaracion Estructuras
  // --------------------------
  dcl-ds dsList_CMD_Borrado qualified inz;
    CMD      VarChar(2000);
    Dias     Int(10);
  end-ds;

  // --------------------------
  // Declaracion de Variables
  // --------------------------
  dcl-s WDiaSpool   Zoned(3) Inz(20);
  dcl-s StrCmd      VarChar(2000);

  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
      SET OPTION Commit = *none,
              CloSqlCsr = *endmod,
              AlwCpyDta = *yes;

    // Solicitudes Pendientes
  Exec Sql declare  C_Spooller Cursor For
    SELECT
      'DLTSPLF FILE(' ||
      Trim(SPOOLED_FILE_NAME) || ') JOB(' ||
      Trim(QUALIFIED_JOB_NAME) || ') SPLNBR(' ||
      Trim(CHAR(SPOOLED_FILE_NUMBER)) || ')',
      Days(current timestamp)- Days(Creation_timestamp) Dias_Generado
    FROM
      TABLE(QSYS2.SPOOLED_FILE_INFO(USER_NAME => '*ALL')) AS X
    Where
      OUTPUT_QUEUE In
        ('P7', 'P77', 'P10', 'P3', 'P11', 'P9', 'P12', 'QDIGITAL',
         'PX', 'QEZJOBLOG', 'QAUTOBANCO', 'CTLSYS', 'PRT01')
      and (Days(current timestamp)- Days(Creation_timestamp)) > :WDiaSpool
    Order by OUTPUT_QUEUE
    ;

  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    Lectura_Spooler_a_Borrar();


  end-proc;
  //-----------------------------------------------------------------------------
  // Proceso de lectura de registros Pendientes EXPORT400
  //-----------------------------------------------------------------------------
  dcl-proc Lectura_Spooler_a_Borrar;

    Exec Sql Open  C_Spooller;

    dow SqlCode = 0;
      Exec Sql Fetch From  C_Spooller into :dsList_CMD_Borrado;
      If sqlStt <> '00000';
        Leave;
      EndIf;

      StrCmd = %Trim(dsList_CMD_Borrado.CMD);

      Monitor;
        Execute(StrCmd:%Len(%trim(StrCmd)));
      On-error;
        // En caso de error, se registra la incidencia pero se continua con el proceso
      Endmon;

    enddo;

    Exec Sql Close  C_Spooller;
  End-Proc;