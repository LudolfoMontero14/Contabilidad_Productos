**Free
  Ctl-Opt DECEDIT('0,') DATEDIT(*YMD.)
          bnddir('UTILITIES/UTILITIES');

  /DEFINE CCURPRINCI
  //*************************************************************************
  //        ENVIA        OPERACIONES DEL BAGENCONVC o BAGENCONB SEGUN PARAME
  //        CONCUR : OPERACIONES CRUZADAS O NO CRUZADAS            
  //                                      Y PENDIENTES DE FACTURAR 
  //   EXPENSE: DESDE FICHERO "SISGESCCUR" TARJETAR CON OPER.PDTES.DE ENVIO
  //   E.C.I. : DESDE FICHERO "SISGESCCVC" TARJETAR CON OPER.PDTES.DE ENVIO
  //   - SEGUN TIPO DE OPERACION ELIGE PROGRAMA PARA FORMATO RGTRO.
  //   - GRABA FICHERO "SISGESOPE"  CONTROL OPERACION ENVIADA.
  //========================================================================
  // CAMBIOS:
  //  - Excluir operaciones de Indra < 16-05-2024             LMG 15052024
  //*************************************************************************
  Dcl-F SISGESCCUR Usage(*Input) Keyed EXTFILE(LABSISGES)  USROPN; //-Tarjetas CONCUR
  Dcl-F PA Usage(*Update:*Delete:*Output) Keyed EXTFILE(LABPA)      USROPN; //-Oper.Pdtes.Facturar
  Dcl-F OPAGEVCLG8 Usage(*Input) Keyed; //-Log. OPAGECO_VC
  Dcl-F SISGESTAR  Usage(*Input) Keyed RENAME(TSISGESW:TSISGESR); //-Control de tarjetas
  Dcl-F SISGESFEEN Usage(*Input) Keyed; //-NO enviar FEE
  Dcl-F BAGENCONB  Usage(*Update:*Delete:*Output) Keyed USROPN; //-BAGENCONB
  Dcl-F BAGENCONVC Usage(*Update:*Delete:*Output) Keyed USROPN; //-BAGENCONVC
  Dcl-F OPAGECOLI3 Usage(*Input) Keyed RENAME(OPAGCOW:OPAGTRMI); //-Logico: OPAGECO_B
  Dcl-F CTLPROCES Usage(*Update:*Delete:*Output) Keyed;
  //-Hist.Oper.Enviadas
  Dcl-F SISGESOPL7 Usage(*Update:*Delete:*Output) Keyed RENAME(OSISGESW:NUMTRMIN);
  //-Hist.Oper.Enviadas
  Dcl-F SISGESOPL8 Usage(*Update:*Delete:*Output) Keyed RENAME(OSISGESW:OSISGES7);

  //-------------------------------------------------
  // OPAGECO: DATOS ADICIONALES, MINERVA (V-01.00) 
  //-------------------------------------------------
  Dcl-DS *N;
    OFICHE         Char(1910) Pos(1);
    GETIPRE        Char(2)    Pos(1); //-TIPO REGISTRO
    GESERFEE       Char(1)    Pos(492); //-CARGO POR EMISION
    BILLEREN       Char(13)   Pos(500); //-N.BILLETE RENFE
  End-DS;
  //-------------------------------------------------
  // PROTOTIPOS DE PROGRAMAS
  //-------------------------------------------------
  // Javier turegano 04-02-13 (concur)
  // TITULAR          PR                  EXTPGM('CCURDATI')
  //                                 8  0 CONST
  //                                 3  0 CONST
  //-------------------------------------------------------------------------
  Dcl-PI CCUROPPE2;
    TIPPRO   Char(1);
  End-PI;

  Dcl-PR CCURDAOPP  EXTPGM('CCURDAOPP'); //Operacion Formato 200
    *N             Zoned(10);
    *N             Pointer;
  End-PR;
    //-------------------------------------------------------------------------
  Dcl-PR CCURPMAC  EXTPGM('CCURPMAC'); //Alquiler de Coches
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Pointer;
  End-PR;
    //-------------------------------------------------------------------------
  Dcl-PR CCURPMHO  EXTPGM('CCURPMHO'); //Hoteles
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Pointer;
  End-PR;
    //-------------------------------------------------------------------------
  Dcl-PR CCURPMVI1  EXTPGM('CCURPMVI1'); //Viajes 1
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Pointer;
  End-PR;
    //-------------------------------------------------------------------------
  Dcl-PR CCURPMVI2  EXTPGM('CCURPMVI2'); //Viajes 2
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Pointer;
  End-PR;
    //-------------------------------------------------------------------------
  Dcl-PR CCURPMCRE  EXTPGM('CCURPMCRE'); //Operacion Formato 400
    *N             Zoned(10);
    *N             Zoned(10);
    *N             Pointer;
  End-PR;
    //-------------------------------------------------------------------------


  //-------------------------------------------------
  // DEFINICION DE CAMPOS
  //-------------------------------------------------
  Dcl-S FECCON       Packed(8:0);
  Dcl-S LABSISGES    Char(10);
  Dcl-S LABPA        Char(10);
  Dcl-S LABOPAGECO   Char(10);
  Dcl-S LABBAGENCO   Char(10);
  Dcl-S OFENOP_ALF   Char(8);
  Dcl-S ONREAL_ALF   Char(8);
  Dcl-S ONDESC_ALF   Char(9);
  Dcl-S UNAVEZ       Ind;
  Dcl-S ENVIO        Char(2);
  Dcl-s ES_V         Ind;
  dcl-s WIndra       ind;
  dcl-s Fec_Consumo  Zoned(8);
  dcl-s WReg         Int(5);
  dcl-s Fec_recp     Zoned(8);
  dcl-s P_IDFRXXX_P  Zoned(10);
  dcl-s P_IDFRXXX_H1 Zoned(10);
  dcl-s P_IDFRXXX_H2 Zoned(10);
  dcl-s WOpageco     Char(10);
  Dcl-s WID_Control  Zoned(10);
  Dcl-s WID_Fichero  Zoned(10);
  Dcl-s WTlabel      Char(10);

  /Copy Explota/Qrpglesrc,CCURCPY
  /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
  /copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
  /COPY EXPLOTA/QRPGLESRC,DSCONCUR

  Dcl-ds dsCCUROPEENV likeds(dsCCUROPEENVTpl) Inz;
  Dcl-ds dsCCURCTLENV likeds(dsCCURCTLENVTpl) Inz;


  LABSISGES  = 'SISGESCCUR';
  LABPA      = 'PA';
  LABBAGENCO = 'BAGENCONB';
  WOpageco   = 'OPAGECO_B';

  ES_V = *Off;
  IF TIPPRO = 'V';
    LABSISGES  = 'SISGESCCUR';
    LABPA      = 'PAVC';
    LABBAGENCO = 'BAGENCONVC';
    WOpageco   = 'OPAGECO_VC';
    ES_V = *On;
    If Not %open(BAGENCONVC);
      OPEN  BAGENCONVC;
    EndIf;
  Else;
    If Not %open(BAGENCONB);
      OPEN  BAGENCONB;
    EndIf;
  ENDIF;

  WID_Control = Graba_Registro_Control();

  OPEN  SISGESCCUR;
  OPEN  PA;
  // ====================================================
  // SISGESCCUR: TARJETAS QUE TIENEN OPER. SIN ENVIAR   
  // ====================================================
  DOW '1';
    READ TSISGESW;

    // ----------------
    // FIN DE PROGRAMA
    // ----------------
    IF %EOF;
      *INLR = *ON;
      RETURN;
    ENDIF;

    // -------------------------------------------------
    // SISTEMA DE GESTION "CONCUR" = 001
    // -------------------------------------------------
    IF TCODSG <> 001;
      ITER;
    ENDIF;

    Exec SQL
      Select tlabel
      Into :Wtlabel
      From SISGESCFAC
      Where
        tgrupo = :TGRUPO
        AND tempre = :TEMPRE 
        AND tnreal = :TNREAL;

      If Sqlcode <> 0;
          observacionSql = 'Error en lectura del SISGESCFAC';
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
          ITER;
      Endif;

      WID_Fichero = Graba_Ficheros_Enviados();    
    //                                                            
    //   BAGENCON          OPERACIONES SIN CRUZAR                 
    //                                                            

    IF TCATRA = 'A';
      If ES_V;
        SETLL TNREAL BAGENCW;  // BAGENCONVC
      Else;
        SETLL TNREAL BAGENCB;  // BAGENCONB
      EndIf;

      DOW '1';

        If ES_V;
          READ BAGENCW;
        Else;
          READ BAGENCB;
        EndIf;

        IF %EOF OR BNUREA <> TNREAL;
          LEAVE;
        ENDIF;

        CHAIN (BNUREA:BNTRMI) NUMTRMIN;   // SISGESOPL7  

        IF %FOUND;
          ITER;
        ENDIF;

        WReg=0;
        Exec SQL
          Select Count(*)
          Into :Wreg
          From Ficheros.SISGESOPEH
          Where
            ONREAL = :BNUREA
            AND ONTRAM = :BNTRMI;

        If Sqlcode <> 0;
           observacionSql = 'Error en chequeo de Registro en el SISGESOPEH';
           Clear Nivel_Alerta;
           Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
           ITER;
        Endif;

        If Sqlcode = 0 And WReg<>0;
          ITER;
        EndIf;

        Exec SQL
            Select HOFECFIC
              Into :Fec_recp
            From Atrium.Minerva
            Where
                  AGNUMAGE = :BNAGMI
              And HONUMFIC = :BNFIMI;

        If Sqlcode <> 0;
           observacionSql = 'Error en chequeo de Registro en el SISGESOPEH';
           Clear Nivel_Alerta;
           Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
           ITER;
        Endif;

        If Fec_recp < 20240701;
          ITER;
        EndIf;

        IF BENVSG = *BLANKS;
          If ES_V;
            CHAIN (BNUREA:BNTRMI) OPAGEVCLG8; // Lee OPAGECO_VC
          Else;
            CHAIN (BNUREA:BNTRMI) OPAGECOLI3; // Lee OPAGECO_B
          EndIf;

          IF %FOUND;
          // -------------------------------------------------
          // CONTROL PARA NO ENVIAR A LOS SISTEMAS DE GESTION
          // OPERACIONES DE FEE   --SISGESFEEN
          // -------------------------------------------------

            IF  GESERFEE =  '1';     //Cargo por emision de billete aéreo
              CHAIN BNUREA NFSISGESW;
              IF %FOUND AND NFFEBAJA = 0;
                ITER;
              ENDIF;
            ENDIF;

            IF  GESERFEE =  '2';     //Cargo por emision cobrado por la Agencia de V.
              CHAIN BNUREA NFSISGESW;
              IF %FOUND AND NFFEBAJA = 0;
                ITER;
              ENDIF;
            ENDIF;

            EXSR OPERBAGEN;                          // GRABACION -SISGESOPE-

            // Valida si es INDRA e Inicializa P_VARIOS
            WIndra = *Off;
            Exec SQL
              Select '1'
              Into :WIndra
              From Ficheros.SISGESTAR
              Where
                TGRUPO=10082321         -- (INDRA)
                AND TCODSG=001
                AND TFBASG = 0
                AND TNREAL = :BNUREA;

            If WIndra And BFECON < 20240516;
              ITER;
            Endif;

            CLEAR PARAM;
            SOCIO    = BNUREA;
            PROCESO  = TIPPRO;
            FECONSU  = BFECON;
            WNUMES   = 9999999;
            TRANMIN  = BNTRMI;
            PA_BAGEN = 'B';
            IMPORTE  = BIMPOR;
            P_SISGES = %ADDR(DSSISGESOPE);

            PARAM_PTR = %ADDR(PARAM);

            ENVIO = 'NO';                            //NO  ENVIO FORMATO-400/401
            CHAIN (BNUREA:001) TSISGESR;
            IF %FOUND and TCENRE = '1';
              ENVIO = 'SI';                        //SI  ENVIO FORMATO-400/401
            ENDIF;

            IF ENVIO  = 'SI'; 
              P_IDFRXXX_P  = 0;
              P_IDFRXXX_H1 = 0;
              CCURPMCRE(P_IDFRXXX_P:P_IDFRXXX_H1:PARAM_PTR);   // Formato: 400
              Graba_Operaciones_Reg_Control(400:P_IDFRXXX_P:0:'  ');
              Graba_Operaciones_Reg_Control(401:P_IDFRXXX_P:P_IDFRXXX_H1:'  ');  
            ENDIF;

            IF ENVIO  = 'NO';
              P_IDFRXXX_P = 0;
              CCURDAOPP(P_IDFRXXX_P:PARAM_PTR);             // Formato: 200
              Graba_Operaciones_Reg_Control(200:P_IDFRXXX_P:0:'  ');
            ENDIF;

            SELECT;
              WHEN GETIPRE = 'RR' AND GESERFEE <> ' ';      // Formato: 303 y 304
                P_IDFRXXX_H1 = 0;
                P_IDFRXXX_H2 = 0;
                CCURPMVI1(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                Graba_Operaciones_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
                Graba_Operaciones_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
              WHEN GETIPRE = 'RA' AND GESERFEE <> ' ';    // Formato: 303 y 304
                P_IDFRXXX_H1 = 0;
                P_IDFRXXX_H2 = 0;
                CCURPMVI2(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                Graba_Operaciones_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
                Graba_Operaciones_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
              WHEN GETIPRE = 'RV' AND GESERFEE <> ' ';    // Formato: 301
                P_IDFRXXX_H1 = 0;
                P_IDFRXXX_H2 = 0;
                CCURPMAC(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                Graba_Operaciones_Reg_Control(301:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
              WHEN GETIPRE = 'RH' AND GESERFEE <> ' ';    // Formato: 302 y 307
                P_IDFRXXX_H1 = 0;
                P_IDFRXXX_H2 = 0;
                CCURPMHO(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                Graba_Operaciones_Reg_Control(302:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
                Graba_Operaciones_Reg_Control(307:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
            ENDSL;

            WRITE NUMTRMIN;

            // Registro de Control Generacion y Envio
            // --------------------------------------


            // --------------------------------------

            BENVSG = 'E';                    // Enviada a Sistema de Gestion
            If ES_V;
              UPDATE BAGENCW %FIELDS(BENVSG);
            else;
              UPDATE BAGENCB %FIELDS(BENVSG);
            EndIf;

          ENDIF;

        ENDIF;

      ENDDO;

      ITER;
    ENDIF;

    //                                                            
    //     PA -OPERACIONES CRUZADAS Y PENDIENTES DE FACTURAR-     
    //                                                            

    UNAVEZ = *OFF;
    SETLL TNREAL PPA;

    DOW '1';
      READ PPA;

      // ----------------
      // DISTINTO SOCIO
      // ----------------
      IF %EOF OR TNREAL <> PNUREA;
        LEAVE;
      ENDIF;

      // ----------------
      // SOLO CODIGOS (7)
      // ----------------
      IF PCR <> '7';
        ITER;
      ENDIF;

      // --------------------------
      // SOLO CODIGOS (7) CRUZADOS
      // --------------------------
      IF PAGENC = 0;
        ITER;
      ENDIF;

      // --------------------------
      // SOLO CODIGOS (7) FORZADOS
      // --------------------------
      IF PAGENC = 9999;
        ITER;
      ENDIF;

      // --------------------------------
      // ¿OPERACION YA ENVIADA A CONCUR?
      // --------------------------------
      FECCON = PFCONS;

      CHAIN (TNREAL:PNTRMI) NUMTRMIN;   // SISGESOPL7  
      IF %FOUND;
        ITER;
      ENDIF;

      CHAIN (TNREAL:PNUREF:PIMPOR) OSISGES7;  // SISGESOPL8  
      IF %FOUND;
        ITER;
      ENDIF;
      //--------- Validacion contra el Historico
      WReg=0;
      Exec SQL
        Select Count(*)
          Into :Wreg
        From Ficheros.SISGESOPEH
        Where
          ONREAL = :TNREAL
          AND ONTRAM = :PNTRMI;

      If Sqlcode <> 0;
          observacionSql = 'Error en chequeo de Registro en el SISGESOPEH';
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
          ITER;
        Endif;

      If Sqlcode = 0 And WReg<>0;
        ITER;
      EndIf;

      WReg=0;
      Exec SQL
        Select Count(*)
          Into :Wreg
        From Ficheros.SISGESOPEH
        Where
          ONREAL = :TNREAL
          AND ONDESC = :PNUREF
          AND OIMPOR = :PIMPOR;

      If Sqlcode <> 0;
        observacionSql = 'Error en chequeo de Registro en el SISGESOPEH';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
        ITER;
      Endif;

      If Sqlcode = 0 And WReg<>0;
        ITER;
      EndIf;
      // ---------------------------------------
      // LOCALIZAR EN OPAGECO "TIPO SERVICIO"
      // ---------------------------------------

      If ES_V;
        CHAIN (PNUREA:PNTRMI) OPAGEVCLG8; // Lee OPAGECO_VC
      Else;
        CHAIN (PNUREA:PNTRMI) OPAGECOLI3; // Lee OPAGECO_B
      EndIf;

      //  -------------------------
      //  Omitir tarjeta   CAU-4663
      //  -------------------------
      IF TNREAL= 08611112;
        IF GETIPRE = 'RO' AND GESERFEE =  '2';
          ITER;
        ENDIF;
      ENDIF;

      // -------------------------------------------------
      // CONTROL PARA NO ENVIAR A LOS SISTEMAS DE GESTION
      // OPERACIONES DE FEE   --SISGESFEEN
      // -------------------------------------------------
      IF  GESERFEE =  '1';     //Cargo por emision de billete aéreo
        CHAIN TNREAL NFSISGESW;
        IF %FOUND AND NFFEBAJA = 0;
          ITER;
        ENDIF;
      ENDIF;

      IF  GESERFEE =  '2';     //Cargo por emision cobrado por la Agencia de V.
        CHAIN TNREAL NFSISGESW;
        IF %FOUND AND NFFEBAJA = 0;
          ITER;
        ENDIF;
      ENDIF;

      //---------------------------------------------------
      //  CARGAR DATOS PARA GRABAR EN SISGESOPE Y SISGESBOL
      //---------------------------------------------------
      EXSR OPENVIADA;            // GRABACION -SISGESOPE-

      // Valida si es INDRA e Inicializa P_VARIOS
      WIndra = *Off;
      Exec SQL
        Select '1'
          Into :WIndra
        From Ficheros.SISGESTAR
        Where
          TGRUPO=10082321         -- (INDRA)
          AND TCODSG=001
          AND TFBASG = 0
          AND TNREAL = :PNUREA;

      Fec_Consumo = %Dec(
          (%Subst(%Editc(PFCONS:'X'):5:4)  +
           %Subst(%Editc(PFCONS:'X'):3:2)  +
           %Subst(%Editc(PFCONS:'X'):1:2))
            :8:0);

      If WIndra And Fec_Consumo < 20240516;
          ITER;
      Endif;

      // ----------------------------
      //   CARGAR ESTRUCTURA DE DATOS
      // ----------------------------
      CLEAR PARAM;
      SOCIO    = PNUREA;
      NUDES    = PNUREF;
      PROCESO  = TIPPRO;
      FECONSU  = PFCONS;
      WNUMES   = PNUMES;
      TRANMIN  = PNTRMI;
      PA_BAGEN = 'P';
      IMPORTE  = PIMPOR;
      P_PVARIO = PVARIO;
      PA_PREFOR= PREFOR;

      If WIndra;
        P_PVARIO = ' ';
      Endif;

      P_PMONED = PMONED;
      P_SISGES = %ADDR(DSSISGESOPE);
      PARAM_PTR = %ADDR(PARAM);

      // ------------------------------------------------
      // LLAMADA A PROGRAMAS: OPERACION "MINERVA" 
      // ------------------------------------------------
      IF (%FOUND(OPAGECOLI3) And Not ES_V) or
          (%FOUND(OPAGEVCLG8) And ES_V);

        ENVIO = 'NO';                                //NO  ENVIO FORMATO-400/401
        CHAIN (PNUREA:001) TSISGESR;

        IF %FOUND and TCENRE = '1';
          ENVIO = 'SI';                           //SI  ENVIO FORMATO-400/401
        ENDIF;

        IF ENVIO  = 'SI'; 
          P_IDFRXXX_P  = 0;
          P_IDFRXXX_H1 = 0;
          CCURPMCRE(P_IDFRXXX_P:P_IDFRXXX_H1:PARAM_PTR);   // Formato: 400
          Graba_Operaciones_Reg_Control(400:P_IDFRXXX_P:0:'  ');
          Graba_Operaciones_Reg_Control(401:P_IDFRXXX_P:P_IDFRXXX_H1:'  ');  
        ENDIF;

        IF ENVIO  = 'NO';
          P_IDFRXXX_P = 0;
          CCURDAOPP(P_IDFRXXX_P:PARAM_PTR);             // Formato: 200
          Graba_Operaciones_Reg_Control(200:P_IDFRXXX_P:0:'  ');
        ENDIF;

        SELECT;
          WHEN GETIPRE = 'RR' AND GESERFEE <> ' ';      // Formato: 303 y 304
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMVI1(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
            Graba_Operaciones_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
            Graba_Operaciones_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
          WHEN GETIPRE = 'RA' AND GESERFEE <> ' ';    // Formato: 303 y 304
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMVI2(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
            Graba_Operaciones_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
            Graba_Operaciones_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
          WHEN GETIPRE = 'RV' AND GESERFEE <> ' ';    // Formato: 301
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMAC(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
            Graba_Operaciones_Reg_Control(301:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
          WHEN GETIPRE = 'RH' AND GESERFEE <> ' ';    // Formato: 302 y 307
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMHO(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
            Graba_Operaciones_Reg_Control(302:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
            Graba_Operaciones_Reg_Control(307:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
        ENDSL;

        WRITE NUMTRMIN;
      Else;
        ITER;
      ENDIF;

      IF TIPPRO = 'V';
        PNTRAM  = %EDITC(*DATE:'X');     // Fecha de envio en PAVC
      ENDIF;

      PENVSG = 'E';                    // Enviada a Sistema de Gestion
      UPDATE PPA %FIELDS(PNTRAM:PENVSG);
    ENDDO;

  ENDDO;

  Close  SISGESCCUR;
  Close  PA;

  If ES_V;
    Close  BAGENCONVC;
  Else;
    Close  BAGENCONB;
  EndIf;
  //***********************************************************************
  //**    SUBRUTINA: GRABACION EN FICHERO  -SISGESOPE-
  //***********************************************************************
  BEGSR OPENVIADA;

    CLEAR NUMTRMIN;
    ONREAL = TNREAL;
    OCODSG = TCODSG;
    ONAGEN = TNAGEN;
    OCOPDI = PCR;
    OTSEMI = GETIPRE;
    OESOPE = 'PE';
    ONDESC = PNUREF;
    OFCOOP = PFCONS;
    OFENOP = *DATE;
    OIMPOR = PIMPOR;
    ONUCRU = PNUCRU;
    OBILLR = PBIREN;
    OFECFA = *ZEROS;
    ONTRAM = PNTRMI;
    ONFIMI = PNFICM;

    IF TIPPRO = ' ';
      ONAGEN = PAGENC;
    ENDIF;

    IF OBILLR = ' ' AND GETIPRE = 'RR';
      OBILLR = BILLEREN;
    ENDIF;

    OFENOP_ALF = %EDITC(OFENOP:'X');
    ONREAL_ALF = %EDITC(ONREAL:'X');
    ONDESC_ALF = %EDITC(ONDESC:'X');

    OREFOP = OFENOP_ALF + ONREAL_ALF + ONDESC_ALF;
  ENDSR;
  //***********************************************************************
  //     CARGA DATOS PARA GRABAR SISGESOPE PROCESANDO EL BAGENCOB
  //***********************************************************************
  BEGSR OPERBAGEN;
    CLEAR NUMTRMIN;
    ONREAL = TNREAL;
    OCODSG = TCODSG;
    ONAGEN = BAGORD;

    //CAU-3583 (28-03-22)  OP DIRECTAS DE AGENCIA   (AAAAMMDD + NUMERO DE TRANSAC.)
    // OREFOP = BNTRMI;

    OFENOP = *DATE;
    OFENOP_ALF = %EDITC(OFENOP:'X');
    OREFOP = OFENOP_ALF + BNTRMI;

    IF BAGORD = 4001;
      OREFOP = OFENOP_ALF + %SUBST(BNTRMI:1:1) + %SUBST(BNTRMI:3);
    ENDIF;

    OCOPDI = '7';
    OTSEMI = GETIPRE;
    OESOPE = 'AG';

    CHAIN 028 CTLREG;
    CTL091 += 1;
    ONDESC = CTL091;
    UPDATE CTLREG;

    OFCOOP = %DEC(%DATE(BFECON:*ISO):*EUR);
    OIMPOR = BIMPOR;
    ONUCRU = BNUCRU;
    OBILLR = BRENBI;

    IF OBILLR = ' ' AND GETIPRE = 'RR';
      OBILLR = BILLEREN;
    ENDIF;

    OFECFA = 0;
    ONTRAM = BNTRMI;
    ONFIMI = BNFIMI;
  ENDSR;
  //---------------------------------------------------------------
  // Grabar registro de Control de Generacion y envio CONCUR
  //---------------------------------------------------------------
  dcl-proc Graba_Operaciones_Reg_Control;

    dcl-pi Graba_Operaciones_Reg_Control ind;
      P_Tipo_Msg like(dsCCUROPEENV.Tipo_Msg_Concur) const;
      P_ID_Msg_Padre like(dsCCUROPEENV.ID_Msg_Padre) const;
      P_ID_Msg_Hijo like(dsCCUROPEENV.ID_Msg_Hijo) const;
      p_Tipo_Servicio_Minerva like(dsCCUROPEENV.Tipo_Servicio_Minerva) const;
    end-pi;

    dcl-s WUser char(10) inz(*user);
    
    Reset dsCCUROPEENV;
    dsCCUROPEENV.ID_Control = WID_Control;
    dsCCUROPEENV.NUREAL = SOCIO;
    If PA_BAGEN = 'P';
      dsCCUROPEENV.Num_Agencia_Minerva = PAGENC;
      dsCCUROPEENV.FICHERO_MINERVA = PNFICM;
      dsCCUROPEENV.Transaccion_Minerva = PNTRMI;
    Else;
      dsCCUROPEENV.Num_Agencia_Minerva = BNAGMI;
      dsCCUROPEENV.FICHERO_MINERVA = BNFIMI;
      dsCCUROPEENV.Transaccion_Minerva = BNTRMI;
    Endif;  
    dsCCUROPEENV.TR_NUMERO_TRANSACCION = 0; 
    dsCCUROPEENV.Tipo_Msg_Concur = P_Tipo_Msg;
    dsCCUROPEENV.ID_Msg_Padre = P_ID_Msg_Padre;
    dsCCUROPEENV.ID_Msg_Hijo = P_ID_Msg_Hijo;
    dsCCUROPEENV.Tipo_Servicio_Minerva = p_Tipo_Servicio_Minerva;
    dsCCUROPEENV.Fecha_Generacion = %Timestamp();
    dsCCUROPEENV.Usuario_Generacion = WUser;
    //dsCCUROPEENV.Fecha_Concur_Out = '0001-01-01-00.00.00.000000';
    //dsCCUROPEENV.ID_Ficheros = WID_Fichero;

    Exec SQL
      INSERT INTO CONCUR_OPERACIONES_ENVIADAS 
      VALUES (:dsCCUROPEENV,Default,:WID_Fichero);

    If Sqlcode <> 0;
      observacionSql = 'Error al grabar en la tabla CONCUR_OPERACIONES_ENVIADAS';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    Return *On;
  end-proc;
  //---------------------------------------------------------------
  // Graba Registro Control de proceso 
  //---------------------------------------------------------------
  dcl-proc Graba_Registro_Control;

    dcl-pi Graba_Registro_Control Zoned(10);

    end-pi;

    dcl-s WUser char(10) inz(*user);
    Dcl-s WID_Gen zoned(10) inz(0);
    
    Reset dsCCURCTLENV;
    dsCCURCTLENV.Tipo_Proceso = TIPPRO;
    dsCCURCTLENV.PA_Utilizado = LABPA;
    dsCCURCTLENV.BA_Utilizado = LABBAGENCO;
    dsCCURCTLENV.OP_Utilizado = WOpageco;
    dsCCURCTLENV.Fecha_Generacion = %Timestamp();
    dsCCURCTLENV.Usuario_Generacion = WUser;

    Exec Sql
      SELECT ID_CTLENV
        INTO :WID_Gen
      FROM FINAL TABLE (
          INSERT INTO CONCUR_Control_Ope_Env 
          VALUES (default, 
              :dsCCURCTLENV));

    If Sqlcode <> 0;
      observacionSql = 'Error al grabar en la tabla CONCUR_Control_Ope_Env';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return 0;
    Endif;

    Return WID_Gen;
  end-proc;
  //---------------------------------------------------------------
  // Graba Registro control de Ficheros a Enviar a CONCUR
  //---------------------------------------------------------------
  dcl-proc Graba_Ficheros_Enviados;

    dcl-pi Graba_Ficheros_Enviados Zoned(10);

    end-pi;

    dcl-s WUser char(10) inz(*user);
    Dcl-s WID_Gen zoned(10) inz(0);

    Exec Sql
      SELECT ID_Fichero
        INTO :WID_Gen
      FROM FINAL TABLE (
          INSERT INTO CONCUR_Ficheros_Enviados 
          VALUES (default,:Wtlabel,default));

    If Sqlcode <> 0;
      observacionSql = 'Error al grabar en la tabla CONCUR_Ficheros_Enviados';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return 0;
    Endif;

    Return WID_Gen;
  end-proc;