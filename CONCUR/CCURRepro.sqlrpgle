**FREE
  // ------------------------------------------------------------------------
  // - Modulo CONCUR
  //   Segun registros een un TRANSAC temporal genera fichero con operaciones
  //   para CONCUR
  // - Autor: Ludolfo Montero
  // - Fecha: Noviembre 2025
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/ CONTAB100 ) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR( CONTAB100 ) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  * Ejecuta la función para Copiar ficheros necesarios en el Paralelo
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
    decedit('0,') datedit(*DMY/)
    //BNDDIR('CONTBNDDIR')
    dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------


  // --------------------------
  // Cpys y Include
  // --------------------------
  

  // --------------------------
  // Declaracion Estructuras
  // --------------------------
  Dcl-ds DsCCURFR200  Extname(CCURFR100) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR100) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR200) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR201) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR301) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR302) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR303) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR304) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR305) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR306) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR307) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR400) qualified Inz; 
  Dcl-ds DsCCURFR200  Extname(CCURFR401) qualified Inz; 

  // --------------------------
  // Declaracion de Variables
  // --------------------------


  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *none,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

  Exec Sql declare  C_Transac Cursor For
    Select * 
    From TRANSACTMP
  ;


  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    dcl-pi *n;
      //P_NomProc   Char(10);
    end-pi;

    Exec Sql Open  C_Transac;
    sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_Transac into :dsANXSOLANX;
      If sqlStt <> '00000';
        Leave;
      EndIf;


    *inlr = *on;

  end-proc;