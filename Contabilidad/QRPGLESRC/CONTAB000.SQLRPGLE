**FREE
  // ------------------------------------------------------------------------
  // - Modulo de Contabilidad (por Producto)
  //   Crea y prepara el ambiente paralelo PARAXXXX para el proceso
  // - Autor: Ludolfo Montero
  // - Fecha: Enero 2026
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/CONTAB000 ) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR( CONTAB000 ) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
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
  /Define Funciones_CONTABSRV
  /define Common_Variables
  /Define Estructuras_Asientos_Evidencias
  /include QRPGLESRC,CONTABSRVH         // Definiciones Contables

  /copy Utilities/QRPGLESRC,PSDSCP         // psds
  /Include Utilities/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

  // --------------------------
  // Declaracion Estructuras
  // --------------------------


  // --------------------------
  // Declaracion de Variables
  // --------------------------
  Dcl-s WNameLIB   Char(10);
  dcl-s ProcContab  Char(10);
  dcl-s ProcOrig    Char(10);
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
      P_ProcOrig   Char(10);
      P_ProcContab Char(10);
      P_NomEnv Char(10);
    end-pi;

    ProcContab = P_ProcContab;
    ProcOrig    = P_ProcOrig;

    If Not CRT_LIB_ENV();
      *inlr = *on;
      Return;
    EndIf;

    //-----------------------------------------------------------------
    // Prepara el ambiente paralelo para la ejecución del proceso
    //-----------------------------------------------------------------
    If Not CONTABSRV_Copy_Ficheros_Paralelo(ProcContab:WNameLIB);
      *inlr = *on;
      Return;      
    EndIf;

    //-----------------------------------------------------------------
    // Ejecución del proceso Contable en el paralelo
    //-----------------------------------------------------------------
    If Not Ejecucion_Proceso_Paralelo();
      *inlr = *on;
      Return;      
    EndIf;

    P_NomEnv = WNameLIB;
    *inlr = *on;

  end-proc;

  //-----------------------------------------------------------------
  // Crea Libreria PARALXXXXX correspondiente para el proceso  
  //-----------------------------------------------------------------
  dcl-proc CRT_LIB_ENV;
    dcl-pi *n Ind;

    end-pi;

    Dcl-s WLastID    Zoned(5);
    Dcl-s WSQL       Varchar(2000);
    Dcl-s WTXT       Char(100);
    Dcl-s WUser      Char(10)  Inz(*user);

    Exec SQL
      Select IFNULL(Max(ID_ENVIROMENT), 0) 
      Into :WLastID
      From Paralelo_Ctl_Env;

    WNameLIB = 'PARAL' + %Editc(WLastID + 1: 'X');

    WTXT = 'Paralelo Contable ' + %trim(ProcOrig) + '-' + %trim(ProcContab);
    WSQL = 'CRTLIB LIB('               +
           WNameLIB                    +
           ') TEXT(' + WComi           +
           %Trim(WTXT)                 + 
           %trim(ProcOrig) +  '-'      +
           %trim(ProcContab) +  ')';

    exec sql 
      CALL QSYS2.QCMDEXC(:WSQL) ;

    If Sqlcode < 0;
      observacionSql = 'Error Al crear la libreria ' + %Trim(WNameLIB);
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

      If Nivel_Alerta = 'HI';
        *InH1 = *On;
        *InLR = *On;
      EndIf;
      Return *Off;
    EndIf;

    EXEC SQL
      INSERT INTO Paralelo_Ctl_Env
        (ID_ENVIROMENT, NAME_PROCESS, DESCR_PROCESS, Date_Create,
        User)
      VALUES (
        Defult, 
        :ProcContab, 
        :WTXT, 
        Current TimeStamp, 
        :WUSER);

    If Sqlcode < 0;
      observacionSql = 'Error Al insert Registro en Paralelo_Ctl_Env';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

      If Nivel_Alerta = 'HI';
        *InH1 = *On;
        *InLR = *On;
      EndIf;
      Return *Off;
    EndIf;

    Return *On;

  end-proc;
  //-----------------------------------------------------------------
  // Crea Libreria PARALXXXXX correspondiente para el proceso  
  //-----------------------------------------------------------------
  dcl-proc Ejecucion_Proceso_Paralelo;
    dcl-pi *n Ind;

    end-pi;

    Dcl-s WLastID    Zoned(5);
    Dcl-s WCMD       Varchar(2000);
    Dcl-s WTXT       Char(100);
    Dcl-s WUser      Char(10)  Inz(*user);


// SBMJOB     CMD(CALL PGM(PARALELOC/CEREFSN_P) PARM(('FS01COM'))) +
//                         JOB(CEREFSN_P) INLLIBL(PARALELOC EXPLOTA)

    WCMD = 
      'SBMJOB     CMD(CALL PGM(PARALELOC/'       +
      %Trim(ProcContab)                          +
      'PARM(('                                   + 
      WComi + %Trim(ProcOrig) + WComi + ' '      + 
      WComi + %Trim(WNameLIB) + WComi            +
      '))) JOB(' + %Trim(ProcContab) + ') '      +
      'INLLIBL(' + %trim(WNameLIB)               +
      ' PARALELOC EXPLOTA)';

    exec sql 
      CALL QSYS2.QCMDEXC(:WCMD) ;

    If Sqlcode < 0;
      observacionSql = 'Error en el SBMJOB del proceso ' + %Trim(ProcContab);
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

      If Nivel_Alerta = 'HI';
        *InH1 = *On;
        *InLR = *On;
      EndIf;
      Return *Off;
    EndIf;

    Return *On;    
  end-proc;