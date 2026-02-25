**FREE
  // ------------------------------------------------------------------------
  // - Modulo de Contabilidad (por Producto)
  //   Realiza las copias a los ficheros historicos de ASIFILEN, DETEVI, CABEVI
  // - Autor: Ludolfo Montero
  // - Fecha: Enero 2026
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/CONTAB102 ) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR( CONTAB102 ) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  * 
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
    decedit('0,') datedit(*DMY/)
    BNDDIR('UTILITIES/UTILITIES':'CONTBNDDIR')
    dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------


  // --------------------------
  // Cpys y Include
  // --------------------------
  /Define Estructuras_Asientos_Evidencias
  /define Common_Variables
  /Include Explota/QRPGLESRC,CONTABSRVH

  /copy Utilities/QRPGLESRC,PSDSCP         // psds
  /Include Utilities/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
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
      P_NomAsiPar   Char(10) ; // Nombre del fichero Parcial Asifilen
      P_AsiNew      Char(1) ;  // V=ASIFILE, N=ASIFILEN
      P_NomCabpar   Char(10) ; // Nombre del fichero Parcial Cabevi
      P_NomDetPar   Char(10) ; // Nombre del fichero Parcial Detevi
      P_NomEnv      Char(10) ; // Nombre del ambiente Paralelo
    end-pi;

    Dcl-s SqlStr      VarChar(2000);
    Dcl-s WUser       VarChar(10) Inz(*User);
    Dcl-s WTot_reg    Zoned(5);


    SqlStr = 
      'SELECT COUNT(*) '                                           +
      ' From ' + %Trim(P_NomEnv) + '.' + %Trim(P_NomAsiPar);    

    exec sql prepare SX0 from :SqlStr;

    exec sql declare C1 cursor for SX0;

    exec sql open C1;

    exec sql fetch C1 into :WTot_reg;

    If sqlStt <> '00000';
      observacionSql = 'Error al determinar total de Registros ' + 
        %Trim(P_NomAsiPar);

      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

      exec sql close C1;
      return;
    EndIf;

    exec sql close C1;

    If WTot_reg = 0;
      observacionSql = 'No se Generaraon Registros en el ' + 
        %Trim(P_NomAsiPar);
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      return;
    EndIf;

    // ******************************************************
    // ** Copia al ASIFILEN_HIS_TABLE del parcial generado **
    SqlStr = 
      'INSERT INTO '                                               +
      'FICHEROS.ASIFILEN_HIS_TABLE '                               +
      '(CAPUNT, CCTAMA, CCTAFI, CCTAAU, CCODIG, CPROGR, CFECON, '  +
      'CDEHA, CREFOP, CFEVTO, CCONCE, CIMPOR, CMONED, CPROVI, '    +
      'CTIPOP, CTIPRO, CCTANA, CCODMA, CREFDE, CDDEPT, CDANLT, '   +
      'CDEBAN, CDPERS, CDGFIN, CDIM06, CDIM07, CDIM08, CDNAMEENV, '+
      'CDEFEC_CREA, CDEUSR_CREA ) '                                +

      'SELECT '                                                    +
      'CAPUNT, CCTAMA, CCTAFI, CCTAAU, CCODIG, CPROGR, CFECON, '   +
      'CDEHA, CREFOP, CFEVTO, CCONCE, CIMPOR, CMONED, CPROVI, '    +
      'CTIPOP, CTIPRO, CCTANA, CCODMA, CREFDE, CDDEPT, CDANLT, '   + 
      'CDEBAN, CDPERS, CDGFIN, CDIM06, CDIM07, CDIM08, '           +
      %Trim(P_NomEnv) + ', current Timestamp, '                    +
      %trim(WUser) +
      ' From ' + %Trim(P_NomEnv) + '.' + %Trim(P_NomAsiPar);    

      exec sql prepare SX1 from :SqlStr;

      Monitor;
        exec sql execute SX1;
      
        If sqlStt <> '00000';
          observacionSql = 'Error en el COPY del Parcial ' + 
            %Trim(P_NomAsiPar);
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
          return;
        EndIf;

      On-Error;
        observacionSql = 'Error en el COPY del Parcial ' + 
          %Trim(P_NomAsiPar);
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

        If Nivel_Alerta = 'HI';
          *InH1 = *On;
          *InLR = *On;
        EndIf;
        Return;
      EndMon;

    // ******************************************************
    // ** Copia al CABEVI_HIS_TABLE del parcial generado **
    SqlStr = 
      'INSERT INTO '                                               +
      'FICHEROS.CABEVI_HIS_TABLE '                                 +
      '(CDESCR, CNUAPU, CFEALT, CFEBAJ, CNUEVI, CIDMOD, '          +
      'CNAMEENV, FEC_CREA, USR_CREA) '                             +

      'SELECT '                                                    +
      'CDESCR, CNUAPU, CFEALT, CFEBAJ, CNUEVI, CIDMOD, '           +
      %Trim(P_NomEnv) + ', current Timestamp, '                    +
      %trim(WUser) +
      ' From ' + %Trim(P_NomEnv) + '.' + %Trim(P_NomCabpar);    

      exec sql prepare SX2 from :SqlStr;

      Monitor;
        exec sql execute SX2;
      
        If sqlStt <> '00000';
          observacionSql = 'Error en el COPY del Parcial ' + 
            %Trim(P_NomCabpar);
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
          return;
        EndIf;

      On-Error;
        observacionSql = 'Error en el COPY del Parcial ' + 
          %Trim(P_NomCabpar);
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

        If Nivel_Alerta = 'HI';
          *InH1 = *On;
          *InLR = *On;
        EndIf;
        Return;
      EndMon;


    // ******************************************************
    // ** Copia al DETEVI_HIS_TABLE del parcial generado **
    SqlStr = 
      'INSERT INTO '                                               +
      'FICHEROS.DETEVI_HIS_TABLE '                                 +
      '(ELINEA, ENULIN, ENUAPU, EFEALT, ENUEVI, ENAMEENV, '        + 
      'EFEC_CREA, EUSR_CREA) '                                     +

      'SELECT '                                                    +
      'ELINEA, ENULIN, ENUAPU, EFEALT, ENUEVI, '                   +
      %Trim(P_NomEnv) + ', current Timestamp, '                    +
      %trim(WUser) +
      ' From ' + %Trim(P_NomEnv) + '.' + %Trim(P_NomDetPar);    

      exec sql prepare SX3 from :SqlStr;

      Monitor;
        exec sql execute SX3;
      
        If sqlStt <> '00000';
          observacionSql = 'Error en el COPY del Parcial ' + 
            %Trim(P_NomDetPar);
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
          return;
        EndIf;

      On-Error;
        observacionSql = 'Error en el COPY del Parcial ' + 
          %Trim(P_NomDetPar);
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

        If Nivel_Alerta = 'HI';
          *InH1 = *On;
          *InLR = *On;
        EndIf;
        Return;
      EndMon;


    *inlr = *on;

  end-proc;