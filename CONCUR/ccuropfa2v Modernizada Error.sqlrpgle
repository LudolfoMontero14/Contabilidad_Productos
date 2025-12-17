**Free
  Ctl-Opt DECEDIT('0,') DATEDIT(*YMD.) bnddir('UTILITIES/UTILITIES');

  /DEFINE CCURPRINCI
  //********************************************************************
  //             CONCUR EXPENSE: OPERACIONES FACTURADAS   
  //   - DESDE FICHERO "SISGESCCUR" TARJETAR CON OPER.PDTES.DE ENVIO.   
  //   - SEGUN TIPO DE OPERACION ELIGE PROGRAMA PARA FORMATO RGTRO.
  //   - GRABA FICHERO "SISGESOPE"  CONTROL OPERACION ENVIADA.
  //========================================================================
  // CAMBIOS:
  //  - Excluir operaciones de Indra < 16-05-2024             LMG 15052024
  //********************************************************************
  Dcl-F SISGESCCUR Usage(*Input) Keyed; //-Tarjetas CONCUR
  Dcl-F BSSG Usage(*Input) Keyed; //-Operac. Facturadas
  Dcl-F OPAGECOLGF Usage(*Input) Keyed; //-Logico: OPAGECO
  Dcl-F SISGESFEEN Usage(*Input) Keyed; //-NO enviar FEE
  //-Hist.Oper.Enviadas
  Dcl-F SISGESOPL7 Usage(*Update:*Delete:*Output) Keyed RENAME(OSISGESW:NUMTRMIN) BLOCK(*NO);
  Dcl-F SISGESTAR Usage(*Input) Keyed RENAME(TSISGESW:TSISGESR); //-Control de tarjetas
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
  //-------------------------------------------------------------------------
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
  //-------------------------------------------------
  // DEFINICION DE CAMPOS
  //-------------------------------------------------
  Dcl-S FECCON       Packed(8:0);
  Dcl-S OFENOP_ALF   Char(8);
  Dcl-S ONREAL_ALF   Char(8);
  Dcl-S ONDESC_ALF   Char(9);
  Dcl-S ONFIMI_GUA   Packed(9:0);
  Dcl-S UNAVEZ       Packed(2:0);
  Dcl-S ENVIO        Char(2);

  dcl-s WIndra       ind;
  dcl-s Fec_Consumo  Zoned(8);
  dcl-s P_IDFRXXX_P  Zoned(10);
  dcl-s P_IDFRXXX_H1 Zoned(10);
  dcl-s P_IDFRXXX_H2 Zoned(10);
  Dcl-S LABSISGES    Char(10);
  Dcl-S LABPA        Char(10);
  Dcl-S LABBAGENCO   Char(10);
  dcl-s WOpageco     Char(10);
  Dcl-s WID_Control  Zoned(10);

  dcl-s BBSRec char(541);   // Aquí se lee el formato BBS completo

  dcl-ds BBSDS overlay(BBSRec);
    // Posiciones extraídas de tus I-spec originales:
    BNUMES  packed(4:0)  pos(9);     // P 9-12
    BCODMO  char(1)      pos(15);   // 15
    BNUMRE  packed(8:0)  pos(16);   // 16-23
    BNUREF  packed(5:0)  pos(24);   // 24-28
    BIMPOR  packed(5:0)  pos(29);   // 29-33
    BFECON  packed(8:0)  pos(40);   // 40-44
    L4      char(20)     pos(56);   // 56-75
    BPROFA  packed(8:0)  pos(186);  // 186-193
    BCRUCE  char(15)     pos(204);  // 204-218
    BTIPOP  char(1)      pos(219);  // 219
    BBIREN  char(15)     pos(440);  // 440-454
    BREFOR  packed(9:0)  pos(493);  // 493-501
    BNTRMI  char(20)     pos(510);  // 510-529
  end-ds;


  /Copy Explota/QRPGLESRC,CCURCPY
  /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
  /copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
  /COPY EXPLOTA/QRPGLESRC,DSCONCUR

  Dcl-ds dsCCUROPEENV likeds(dsCCUROPEENVTpl) Inz;
  Dcl-ds dsCCURCTLENV likeds(dsCCURCTLENVTpl) Inz;


  LABSISGES  = 'SISGESCCUR';
  LABPA      = 'BSSG';
  LABBAGENCO = '';
  WOpageco   = 'OPAGECO';

  WID_Control = Graba_Registro_Control();
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

    // --------------------------------------
    // SOLO SISTEMA DE GESTION "CONCUR"
    // --------------------------------------
    IF TCODSG <> 001;
      ITER;
    ENDIF;

    // ================================
    // BSSG -OPERACIONES FACTURADAS-  
    // ================================
    UNAVEZ = 0;
    SETLL TNREAL BSSG;

    DOW '1';
      READ BSSG BBSRec;

      // ----------------
      // DISTINTO SOCIO
      // ----------------
      IF %EOF OR TNREAL <> BNUMRE;
        LEAVE;
      ENDIF;

      // ----------------
      // SOLO CODIGOS (7)
      // ----------------
      IF BCODMO <> '7';
        ITER;
      ENDIF;

      // --------------------------------
      // ¿OPERACION YA ENVIADA A CONCUR?
      // --------------------------------
      FECCON = BFECON;

      IF BNTRMI <> ' ';
        CHAIN (TNREAL:BNTRMI) NUMTRMIN;   // SISGESOPL7  
        IF %FOUND;
          OFECFA = BPROFA;
          UPDATE NUMTRMIN;
          UNLOCK SISGESOPL7;
          ITER;
        ENDIF;
      ENDIF;

      BNUREF = L1_P;
      CHAIN (TNREAL:BNUREF:BIMPOR) OSISGES7;  // SISGESOPL8  

      IF %FOUND;
        OFECFA = BPROFA;
        UPDATE OSISGES7;
        UNLOCK SISGESOPL8;
        ITER;
      ENDIF;

      // -------------------------------------------------
      // LOCALIZAR EN OPAGECO "TIPO SERVICIO"
      // -------------------------------------------------
      CHAIN (TNREAL:BNTRMI) OPAGCOW;  // (OPAGECOLGF)

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

      // -------------------------------------------------
      //  IF %FOUND AND BNTRMI <> ONTRMI;
      //    CHAIN (TNREAL:BNTRMI) NUMTRMIN;   // SISGESOPL7  
      //  ENDIF;
      // -------------------------------------------------

      ONFIMI_GUA = ONFIMI;            // Por el clear del SISGESOPE
      //---------------------------------------------------
      //  CARGAR DATOS PARA GRABAR EN SISGESOPE Y SISGESBOL
      //---------------------------------------------------

      CLEAR NUMTRMIN;               // Tambien limpia ONFIMI del OPAGECO  OSISGESW

      IF TNAGEN > 4000;
        TNAGEN = TNAGEN - 2000;
      ENDIF;

      ONREAL = TNREAL;
      OCODSG = TCODSG;
      ONAGEN = TNAGEN;
      OCOPDI = BCODMO;
      OTSEMI = GETIPRE;
      OESOPE = 'FA';
      ONDESC = BNUREF;
      OFCOOP = BFECON;
      OFENOP = *DATE;
      OIMPOR = BIMPOR;
      ONUCRU = BCRUCE;
      OBILLR = BBIREN;

      IF OBILLR = ' ' AND GETIPRE = 'RR';
        OBILLR = BILLEREN;
      ENDIF;

      OFECFA = BPROFA;
      ONTRAM = ONTRMI;         // Del OPAGECO
      ONFIMI = ONFIMI_GUA;     // Del OPAGECO

      OFENOP_ALF = %EDITC(OFENOP:'X');
      ONREAL_ALF = %EDITC(ONREAL:'X');
      ONDESC_ALF = %EDITC(ONDESC:'X');
      OREFOP = OFENOP_ALF + ONREAL_ALF + ONDESC_ALF;

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
          AND TNREAL = :BNUMRE
      ;

      Fec_Consumo = %Dec(
          (%Subst(%Editc(BFECON:'X'):5:4)  +
           %Subst(%Editc(BFECON:'X'):3:2)  +
           %Subst(%Editc(BFECON:'X'):1:2))
           :8:0);

      If WIndra And Fec_Consumo < 20240516;
        ITER;
      Endif;

      // ----------------------------
      //   CARGAR ESTRUCTURA DE DATOS
      // ----------------------------
      CLEAR PARAM;
      SOCIO    = BNUMRE;
      NUDES    = BNUREF;
      PROCESO  = *BLANKS;
      FECONSU  = BFECON;
      WNUMES   = BNUMES;
      TRANMIN  = BNTRMI;
      PA_BAGEN = 'F';
      IMPORTE  = BIMPOR;
      P_PVARIO = %SUBST(L4:10:11);
      PA_PREFOR= BREFOR;

      If WIndra;
        P_PVARIO = ' ';
      Endif;

      P_PMONED = %INT(%SUBST(L4:7:3));
      P_SISGES = %ADDR(DSSISGESOPE);
      PARAM_PTR = %ADDR(PARAM);

      // ------------------------------------------------
      // LLAMADA A PROGRAMAS: OPERACION "MINERVA" 
      // ------------------------------------------------
      IF %FOUND;

        // Jovier toregano 04-02-13 (concur)
        // IF UNAVEZ = 0;                            // Formato: 100
        // TITULAR(TNREAL:TCODSG);                   // Formato: 100
        // UNAVEZ += 1;                              // Formato: 100
        // ENDIF;                                    // Formato: 100
        // ------------------------------------------------

        ENVIO = 'NO';                            //NO  ENVIO FORMATO-401
        CHAIN (BNUMRE:001) TSISGESR;
        IF %FOUND and TCENRE = '1';
          ENVIO = 'SI';                        //SI  ENVIO FORMATO-400/401
        ENDIF;


        IF ENVIO  = 'SI';
          P_IDFRXXX_P  = 0;
          P_IDFRXXX_H1 = 0;
          CCURPMCRE(P_IDFRXXX_P:P_IDFRXXX_H1:PARAM_PTR);   // Formato: 400/401
          Graba_Reg_Control(400:P_IDFRXXX_P:0:'  ');
          Graba_Reg_Control(401:P_IDFRXXX_P:P_IDFRXXX_H1:'  ');
        ENDIF;

        // IF ENVIO  = 'SI' AND GETIPRE <> 'RO';
        //   CCURPMCRE(PARAM_PTR);                    // Formato: 400/401
        // ENDIF;

        // IF ENVIO  = 'SI' AND GETIPRE = 'RO';
        //   CCURPMCRE(PARAM_PTR);                    // Formato: 400/401
        // ENDIF;

        IF ENVIO  = 'NO';
          P_IDFRXXX_P = 0;
          CCURDAOPP(P_IDFRXXX_P:PARAM_PTR);             // Formato: 200
          Graba_Reg_Control(200:P_IDFRXXX_P:0:'  ');
        ENDIF;

        SELECT;
          WHEN GETIPRE = 'RR' AND GESERFEE <> ' ';
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMVI1(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);// Formato: 303 y 304
            Graba_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
            Graba_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
          WHEN GETIPRE = 'RA' AND GESERFEE <> ' ';
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMVI2(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);// Formato: 303 y 304
            Graba_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
            Graba_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
          WHEN GETIPRE = 'RV' AND GESERFEE <> ' ';
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMAC(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);// Formato: 301
            Graba_Reg_Control(301:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
          WHEN GETIPRE = 'RH' AND GESERFEE <> ' ';
            P_IDFRXXX_H1 = 0;
            P_IDFRXXX_H2 = 0;
            CCURPMHO(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);// Formato: 302 y 307
            Graba_Reg_Control(302:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
            Graba_Reg_Control(307:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
        ENDSL;

        WRITE NUMTRMIN;

      ENDIF;

      // ------------------------------------------------
      // LLAMADA A PROGRAMAS: OPERACION "-NO- MINERVA" 
      // ------------------------------------------------
      //IF NOT %FOUND;
      //   GETIPRE = 'ZZ';

      // Javier toregano 04-02-13 (concur)
      // IF UNAVEZ = 0;                            // Formato: 100
      // TITULAR(TNREAL:TCODSG);                  // Formato: 100
      // UNAVEZ += 1;                             // Formato: 100
      // ENDIF;                                    // Formato: 100

      //   CCURDAOPP(PARAM_PTR);                     // Formato: 200

      //WRITE OSISGESW;
      //ENDIF;
      // ---------------------------------------------

    ENDDO;
    // ==============================
  ENDDO;
  //---------------------------------------------------------------
  // Grabar registro de Control de Generacion y envio CONCUR
  //---------------------------------------------------------------
  dcl-proc Graba_Reg_Control;

    dcl-pi Graba_Reg_Control ind;
      P_Tipo_Msg like(dsCCUROPEENV.Tipo_Msg_Concur) const;
      P_ID_Msg_Padre like(dsCCUROPEENV.ID_Msg_Padre) const;
      P_ID_Msg_Hijo like(dsCCUROPEENV.ID_Msg_Hijo) const;
      p_Tipo_Servicio_Minerva like(dsCCUROPEENV.Tipo_Servicio_Minerva) const;
    end-pi;

    dcl-s WUser char(10) inz(*user);

    Reset dsCCUROPEENV;
    dsCCUROPEENV.ID_Control = WID_Control;
    dsCCUROPEENV.NUREAL = SOCIO;
    dsCCUROPEENV.Num_Agencia_Minerva = BAGENC;
    dsCCUROPEENV.FICHERO_MINERVA = BNFICM;
    dsCCUROPEENV.Transaccion_Minerva = BNTRMI;
    dsCCUROPEENV.TR_NUMERO_TRANSACCION = 0;
    dsCCUROPEENV.Tipo_Msg_Concur = P_Tipo_Msg;
    dsCCUROPEENV.ID_Msg_Padre = P_ID_Msg_Padre;
    dsCCUROPEENV.ID_Msg_Hijo = P_ID_Msg_Hijo;
    dsCCUROPEENV.Tipo_Servicio_Minerva = p_Tipo_Servicio_Minerva;
    dsCCUROPEENV.Fecha_Generacion = %Timestamp();
    dsCCUROPEENV.Usuario_Generacion = WUser;

    Exec Sql
      INSERT INTO CONCUR_OPERACIONES_ENVIADAS
      VALUES (:dsCCUROPEENV);

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
    dsCCURCTLENV.Tipo_Proceso = 'F';
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