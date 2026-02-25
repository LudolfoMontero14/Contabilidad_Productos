**FREE
  // ------------------------------------------------------------------------
  // - Modulo de Contabilidad (por Producto)
  //   Llama a la funcion para copiar los ficheros necesario para el paralo 
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
    BNDDIR('CONTBNDDIR')
    dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------


  // --------------------------
  // Cpys y Include
  // --------------------------
  /Define Funciones_CONTABSRV
  /Define Estructuras_Asientos_Evidencias
  /define Common_Variables
  /include QRPGLESRC,CONTABSRVH         // Definiciones Contables

  // --------------------------
  // Declaracion Estructuras
  // --------------------------


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

  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    dcl-pi *n;
      P_NomProc   Char(10);
    end-pi;

    CONTABSRV_Copy_Ficheros_Paralelo(P_NomProc);

    *inlr = *on;

  end-proc;