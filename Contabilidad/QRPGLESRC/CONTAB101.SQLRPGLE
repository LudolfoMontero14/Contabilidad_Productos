**FREE
  // ------------------------------------------------------------------------
  // - Modulo de Contabilidad (por Producto)
  //   Llama a la funcion grabar registro de auditoria del Paralelo Contable
  // - Autor: Ludolfo Montero
  // - Fecha: Noviembre 2025
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/ CONTAB101 ) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR( CONTAB101 ) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
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
  /include QRPGLESRC/CONTABSRVH         // Definiciones Contables

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
      P_NomProc     Char(10) ;
      P_NomAsiPar   Char(10) ;
      P_NomCabpar   Char(10) ;
      P_NomDetPar   Char(10) ;
      P_NumApunte   Char( 6) ;
      P_NomPgm      Char(10) ;
    end-pi;

    CONTABSRV_Registro_Auditoria_Paralelo(
          P_NomProc            // Proceso que Ejecuta
          :P_NomPgm            // Proceso Actual 'FSPAFAN'
          :P_NumApunte         // Numero de Apunte
          :P_NomAsiPar         // Nombre Asifilen Parcial
          :P_NomCabpar         // Nombre Cabevi Parcial
          :P_NomDetPar         // Nombre Detevi Parcial
      );

    *inlr = *on;

  end-proc;