     H DECEDIT('0,') DATEDIT(*YMD.) DFTACTGRP(*NO)
     H BNDDIR('UTILITIES/UTILITIES')
      *********************************************************************
      *
      *  CONCUR EXPENSE: ENVIO DE OPERACIONES A SISTEMA DE GESTION
      *               CENTRO RECONCILIACION
      *         FORMATO: 400   -CABECERAS-  (VENDOR ACCOUNT)
      *         FORMATO: 401   -DETALLES-   (VENDOR INVOICE TRANSACTION)
      *
      *********************************************************************
       //FOPAGECOLG7IF   E      K DISK    EXTFILE(LABOPAGE)         USROPN     OPAGECO_B (PA/PAVC)
     FOPAGECOLGDIF   E           K DISK    RENAME(OPAGCOW:OPAGTRMI)  USROPN     OPAGECO_B (BAGENCONB
     FOPAGECOL1 IF   E           K DISK    RENAME(OPAGCOW:OPAGFACTU) USROPN     OPAGECO   (BS)
        // Solo cuando vienen del BAGENCON_VC
     FOPAGEVCLG8IF   E           K DISK    RENAME(OPAGCOW:OPALG8)               OPAGECO_VC
       // Solo cuando vienen del BAGENCON_B
     FOPAGECOLI3IF   E           K DISK    RENAME(OPAGCOW:OPALI3)               OPAGECO_B

     FOPGENXDL4 IF   E           K DISK                                         -Logico: OPGENXD

     FSISGESTAR IF   E           K DISK                                         -Sistema de Gestion
     FTABACTI   IF   E           K DISK
     FINDEPROV  IF   E           K DISK
     FESTA1     IF   E           K DISK
     FFAGENCON  IF   E           K DISK                                         -Agencias Conciliar
     FMSOCIO    IF   F  731     8AIDISK    KEYLOC(3)
     FCONCUR_OUTO    F 2580        DISK                                         -Para CONCUR

      *------------------------
      * EXTRUCTURAS EXTERNAS
      *------------------------
      *DCCURFR400PF    E DS                  Extname(CCURFR400) Inz               -CABECERAS
      *DCCURFR401PF    E DS                  Extname(CCURFR401) Inz               -DETALLES

       Dcl-ds dsCCURFR400T likeds(dsCCURFR400TTpl) Inz;
       Dcl-ds dsCCURFR401T likeds(dsCCURFR401TTpl) Inz;

      *------------------------
      * DEFINICION DE CAMPOS
      *------------------------
      /Copy Explota/Qrpglesrc,CCURCPY
      /COPY EXPLOTA/QRPGLESRC,MINERVA_H
      /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
      /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
     D SOLONUM         C                   CONST('0123456789')
     D PIMPOR15        S             15  0
     D LABOPAGE        S             10
     D LABPACON        S             10
     D FECHA_ALF       S              8
     D FECHA_LLE       S              8
     D FECHA_SAL       S              8
     D SOCIO_ALF       S              8
     D NUDES_ALF       S              9
     D TASAS           S             15  2
     D TODOREG         S           2000
     D WPOS            S              3S 0 Inz
     D*------------------------------
     D* OPAGECO: MINERVA (V-01.00)
     D*------------------------------
     D                 DS
     D OFICHE                  1   1910
     D  OMITRE                 1      2                                         -Tipo Registro
     D  OMINPR                37     71                                         -Nombre Proveedor
     D  OMICOR                88    122                                         -Ciudad Origen
     D  OMICDE               160    194                                         -Ciudad Destino
     D  OMINPA               232    266                                         -Nombre Pasajero
     D  OMIFVE               267    274  0                                      -Minerva:FECHA VENTA
     D  OMIFVE_ALF           267    274                                         -Minerva:FECHA VENTA
     D  OMINFA               275    294                                         -Numero Factura
     D  OMIFFA               295    302  0                                      -Fecha  Factura
     D  OMIFFA_ALF           295    302                                         -Fecha  Factura
     D  OMINAL               303    322                                         -Nombre Pasajero
     D  OMIIVA1              387    401  0                                      -IMPORTE IVA-1
     D  OMIFEE               492    492                                         -Cargo por Emision
     D  OMINDO               493    512                                         -Numero Documento
     D  ONUAUT               531    534  0                                      -Numero Autorizacion
     D  OMIIAT               552    559                                         -Numero Iata (7)
     D  OREF01               561    580                                         -REFERENCIA 1 CIF.
     D  OREF02               581    600                                         -REFERENCIA 2 CIF.
     D  OREF03               601    620                                         -REFERENCIA 3 CIF.
     D  OREF04               621    640                                         -REFERENCIA 4 CIF.
     D  OREF05               641    660                                         -REFERENCIA 5 CIF.
     D  OREF06               661    680                                         -REFERENCIA 6 CIF.
     D  OREF07               681    700                                         -REFERENCIA 7 CIF.
     D  OREF08               701    720                                         -REFERENCIA 8 CIF.
     D  OREF09               721    740                                         -REFERENCIA 9 CIF.
     D  OREF10               741    760                                         -REFERENCIA10 CIF.
     D  ODESLI               761    810                                         -DESCRIPCION LIBRE
     D  OMINRE               914    928                                         -Numero Reembolso
     D  OMIAOR               942    944                                         -Aeropuerto Salida
     D  OMIAD1               954    956                                         -Aeropuerto Destino1
     D  OMICL1               995    995                                         -Aeropuerto Clase-1
     D  OMIAD2              1020   1022                                         -Aeropuerto Destino2
     D  OMIAD3              1086   1088                                         -Aeropuerto Destino3
     D  OMIAD4              1152   1154                                         -Aeropuerto Destino4
     D  OMICL2              1061   1061                                         -Aeropuerto Clase-2
     D  OMICL3              1127   1127                                         -Aeropuerto Clase-3
     D  OMICL4              1193   1193                                         -Aeropuerto Clase-4

       Dcl-s PARAM_IDP Zoned(10);
       Dcl-s PARAM_IDH Zoned(10);
       
      /COPY EXPLOTA/QRPGLESRC,DSCONCUR

     IMSOCIO    NS
     I                                  1   14  NTAR14
     I                                  1   10  NTAR10
     I                                161  190  SNOMEM


      *------------------------
      * PARAMETROS
      *------------------------
     C     *ENTRY        PLIST
     C                   PARM                    PARAM_IDP
     C                   PARM                    PARAM_IDH
     C                   PARM                    PARAM_PTR

        //----------------------------------------------------
        // OPERACIONES FACTURADAS - IDENTIFICACION DE FICHEROS
        //----------------------------------------------------

        IF PA_BAGEN = 'F';
          OPEN OPAGECOL1;

          CHAIN (NUDES:SOCIO) OPAGFACTU;        // OPAGECOL1
          CHAIN (WNUMES)      ESTA1W;           //  ESTA1
          CHAIN (EPROPV)      INPROW;           //  INDEPROV
          CHAIN (SOCIO:001)   TSISGESW;         //  SISGESTAR
        ENDIF;

        //--------------------------------------------------
        // OPERACIONES CRUZADAS - IDENTIFICACION DE FICHEROS
        //--------------------------------------------------

        IF PA_BAGEN = 'P';
          LABOPAGE = 'OPAGECOLG7';

          IF PROCESO = 'V';                    // Viajes El Corte Ingles
            CHAIN (SOCIO:001)   TSISGESW;         //  SISGESTAR
            LABOPAGE = 'OPAGEVCLG7';
          ENDIF;

          //OPEN OPAGECOLG7;

          //CHAIN (NUDES:SOCIO) OPAGCOW;          //  OPAGECOLG7 / OPAGEVCLG7
          // Si no encuentra registro en OPAGECO* lo busca por numero transaccion minerva
          //IF NOT %FOUND(OPAGECOLG7);
            If PROCESO = 'V';
              CHAIN (SOCIO:TRANMIN) OPAGEVCLG8; // Lee OPAGECO_VC
            Else;
              CHAIN (SOCIO:TRANMIN) OPAGECOLI3; // Lee OPAGECO_B
            EndIf;
          //ENDIF;
          CHAIN (WNUMES)      ESTA1W;           //  ESTA1
          CHAIN (EPROPV)      INPROW;           //  INDEPROV
        ENDIF;

        //----------------------------------------------------
        // OPERACIONES SIN CRUZAR - IDENTIFICACION DE FICHEROS
        //----------------------------------------------------

        IF PA_BAGEN = 'B';
          IF NOT %OPEN(OPAGECOLGD);
            OPEN OPAGECOLGD;                          //quitarrrrrrrr
          ENDIF;
          //CHAIN (SOCIO:TRANMIN) OPAGTRMI;         //OPAGECOLGD
          CHAIN (SOCIO:TRANMIN) OPAGEVCLG8;
          If Not %Found(OPAGEVCLG8);
            CHAIN (SOCIO:TRANMIN) OPAGECOLI3;
            If Not %Found(OPAGECOLI3);
              *INLR = *ON;
              RETURN;
            EndIf;
          EndIf;
         ENDIF;

        // -----------------------------------
        // CARGAR: TARJETA SOCIO
        // -----------------------------------

        CHAIN SOCIO  MSOCIO;

        // =================================
        // GRABAR: CCURFR400PF (CABECERAS)
        // =================================

        //CLEAR CCURFR400PF;
        Reset dsCCURFR400T;

        // Identificacion Registro
        //----------------------------------------

        dsCCURFR400T.F400IDR = 400;

        // Vendor identifier
        //----------------------------------------
        dsCCURFR400T.F400VVI = *BLANKS;

        // Vendor Name
        //----------------------------------------

        CHAIN (ONUAGE)      FAGENCW;          //  FAGENCON
        dsCCURFR400T.F400VVN = FNOAGE;

        // Ivoice Account Number
        //----------------------------------------

        dsCCURFR400T.F400IAN = NTAR10 + '9999';

        // INVOICE ACCO. name
        //----------------------------------------

        dsCCURFR400T.F400ACN = SNOMEM;

        // Reservado (Libre)
        //----------------------------------------
        dsCCURFR400T.F400LIB = *BLANKS;

        //TODOREG = CCURFR400PF;  // CCURFR400
        TODOREG = dsCCURFR400T;  // CCURFR400
        EXCEPT;
        
        // Graba registro en el historico CCURFR400T
        //------------------------------------------
        PARAM_IDP = Graba_Reg_FR400();

        // =================================
        // GRABAR: CCURFR401PF (DETALLES)
        // =================================
        //CLEAR CCURFR401PF;
        Reset dsCCURFR401T;

        // Identificacion Registro
        //----------------------------------------
        dsCCURFR401T.F401IDR = 401;

        // Ivoice Account Number
        //----------------------------------------

        dsCCURFR401T.F401IAN = NTAR10 + '9999';

        // Statement Identifier
        //----------------------------------------

        dsCCURFR401T.F401SID  = %SUBST(OMIFFA_ALF:1:6);

        // Reference number
        //----------------------------------------

        dsCCURFR401T.F401REN = %EDITC(*DATE:'X') + 
                               %EDITC(SOCIO:'X') + 
                               %EDITC(NUDES:'X');

        IF PA_BAGEN = 'B';
          dsCCURFR401T.F401REN = 
                               %EDITC(*DATE:'X') + 
                               %EDITC(SOCIO:'X') + 
                               TRANMIN;
        ENDIF;

        // Invoice Number    Nº.FACTURA _ REFERENCIA1
        //----------------------------------------

        IF OMINFA = *BLANKS;
          dsCCURFR401T.F401INU  = OMIFFA_ALF + '_' + OREF01;
          ELSE;
          dsCCURFR401T.F401INU  = %TRIM(OMINFA) + '_' + OREF01;
        ENDIF;

        //----------------------------------------
        // AGENCIA 4065 GLOBAL BUSINESS TRAVEL (AMEX)
        // Invoice Number    Nº.FACTURA _ REFERENCIA2
        //----------------------------------------

        IF ONUAGE = 4065;

          IF OMINFA = *BLANKS;
            dsCCURFR401T.F401INU  = OMIFFA_ALF + '_' + OREF02;
          ELSE;
            dsCCURFR401T.F401INU  = %TRIM(OMINFA) + '_' + OREF02;
          ENDIF;

        ENDIF;

        // Invoice Date
        //----------------------------------------
        dsCCURFR401T.F401IDA  = OMIFFA;

        // Invoice Type
        //----------------------------------------

        dsCCURFR401T.F401ITY = '1';

        PIMPOR15 = IMPORTE;

        IF PIMPOR15 < 0;
          dsCCURFR401T.F401ITY = '2';
        ENDIF;

        // Related Invoice Nnumber
        //----------------------------------------
        dsCCURFR401T.F401RIN = *BLANKS;

        // Transaction Date
        //----------------------------------------

        dsCCURFR401T.F401FTR = OMIFVE;

        // Original/Foreign Transaction Amount ISO
        //----------------------------------------
        dsCCURFR401T.F401TAI = '978';

        // Importe Transaccion   Original/foreign
        //----------------------------------------
        PIMPOR15 = IMPORTE;

        IF PIMPOR15   < 0;
          PIMPOR15     *= -1;
        ENDIF;

        dsCCURFR401T.F401OTA = %EDITC(PIMPOR15:'X');

        IF IMPORTE < 0;
          %SubSt(dsCCURFR401T.F401OTA:1:1) = '-';
         //C        MOVEL     '-'           dsCCURFR401T.F401OTA
        ENDIF;


        // Original/Foreign Transaction Amount ISO
        //----------------------------------------
        dsCCURFR401T.F401PBA = '978';

        // Importe Transaccion   Posted/Billing
        //----------------------------------------

        dsCCURFR401T.F401PAM = %EDITC(PIMPOR15:'X');

        IF IMPORTE < 0;
          %SubSt(dsCCURFR401T.F401PAM:1:1) = '-';
           //C       MOVEL     '-'           dsCCURFR401T.F401PAM
        ENDIF;

        // Merchant Name
        //----------------------------------------
        dsCCURFR401T.F401MNA = OMINPR;

        // Nombre Comercio   oper. bagencond
        //--------------------------------------------------------
        IF PA_BAGEN = 'B';      //Operaciones de Agencia  -AG-
          dsCCURFR401T.F401MNA = OMINPR;
        ENDIF;

        dsCCURFR401T.F401MCO = '4722';

        IF  OMITRE = 'RH' AND  OMIFEE = '3';           //HOTELES
          dsCCURFR401T.F401MCO = '7011 ';
        ENDIF;

        IF  OMITRE = 'RV' AND  OMIFEE = '3';           // ALQUILER COCHES
          dsCCURFR401T.F401MCO = '7512';
        ENDIF;

        IF  OMITRE = 'RR' AND  OMIFEE = '3';           // FERROCARRIL
          dsCCURFR401T.F401MCO = '4011';
        ENDIF;

        IF OMITRE  = 'RA' AND OMIFEE = '3' AND       // LINEA AEREAS
           ONUAUT <> 0 AND IMPORTE > 0;
          dsCCURFR401T.F401MCO = '4722';
        ENDIF;

        IF OMITRE  = 'RA' AND OMIFEE = '3';          // LINEA AEREAS
          dsCCURFR401T.F401MCO = '4511';
        ENDIF;

        // Localidad Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR401T.F401MCI = %SUBST(ELOCPV:7:26);
        ELSE;
          dsCCURFR401T.F401MCI = LCITY;
        ENDIF;

        // Provincia Comercio
        //-----------------------------

        dsCCURFR401T.F401MPO = *BLANKS;

        IF WNUMES > 0 AND WNUMES <> 9999999;
          dsCCURFR401T.F401MPO = PNOPRO;
        ENDIF;

        // Codigo Postal Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR401T.F401MPC = %Subst(ELOCPV:1:5);
        ELSE;
          dsCCURFR401T.F401MPC = ESTZP;
        ENDIF;

        // Codigo ISO Pais Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR401T.F401MCU = '724';
        ELSE;
          dsCCURFR401T.F401MCU = %EDITC(GEOCD:'X');
        ENDIF;

        // Tax Amount
        //-----------------------------
        TASAS = 0;
        TASAS = OMIIVA1;

        dsCCURFR401T.F401TAA = %EDITC(TASAS:'X');

        IF IMPORTE < 0 AND TASAS <> 0;
          %SubSt(dsCCURFR401T.F401TAA:1:1) = '-';
           //C    MOVEL     '-'           dsCCURFR401T.F401TAA
        ENDIF;

        // Local Tax Amount
        //-----------------------------
        dsCCURFR401T.F401LTA = *BLANKS;

        // Value Tax Amount
        //-----------------------------
        dsCCURFR401T.F401VAT = *BLANKS;

        // Sales Tax Amount
        //-----------------------------
        dsCCURFR401T.F401STA = *BLANKS;

        // Other Tax Amount
        //-----------------------------
        dsCCURFR401T.F401OAM = *BLANKS;

        // Merchant  Other Tax Amount
        //-----------------------------
        dsCCURFR401T.F401MTN = *BLANKS;

        // Customer Tax Number
        //-----------------------------
        dsCCURFR401T.F401CTN = *BLANKS;

        // Vat Data Indicator
        //-----------------------------
        dsCCURFR401T.F401VDI = ' ';

        // Transaction Descripcion
        //-----------------------------
        dsCCURFR401T.F401TRD = ODESLI;

        // Visa Fee Indicator
        //-----------------------------
        dsCCURFR401T.F401VFI =  '0';

        // Visa Type
        //-----------------------------
        dsCCURFR401T.F401VTI = *BLANKS;

        // Visa Type descripcion
        //-----------------------------
        dsCCURFR401T.F401VTD = *BLANKS;

        // Visa Destination Country ISO
        //-----------------------------
        dsCCURFR401T.F401VDC = *BLANKS;

        // Original Visa Service Charge ISO
        //-----------------------------
        dsCCURFR401T.F401VSC = *BLANKS;

        // Original Visa Service Charge
        //-----------------------------
        dsCCURFR401T.F401VCH = *BLANKS;

        // Visa Service Charge ISO
        //-----------------------------
        dsCCURFR401T.F401BSH = *BLANKS;

        // Posted Visa Service Charge ISO
        //-----------------------------
        dsCCURFR401T.F401PSC = *BLANKS;

        // Visa Other Charge Description
        //-----------------------------
        dsCCURFR401T.F401OCD = *BLANKS;

        // Origianl Visa Other Charge ISO
        //-----------------------------
        dsCCURFR401T.F401OCI = *BLANKS;

        // Origianl Visa Other Charge
        //-----------------------------
        dsCCURFR401T.F401OOC = *BLANKS;

        // Posted/billed Visa Other Change ISO
        //-----------------------------
        dsCCURFR401T.F401POC = *BLANKS;

        // Posted  Visa Other Change
        //-----------------------------
        dsCCURFR401T.F401PCH = *BLANKS;

        // Referencias (1-10)
        //-----------------------------
        dsCCURFR401T.F401CF1 = OREF01;             //REQUEST ID ANTES DE LA POSICIONES 895-898
        dsCCURFR401T.F401CF2 = OREF02;
        dsCCURFR401T.F401CF3 = OREF03;
        dsCCURFR401T.F401CF4 = OREF04;
        dsCCURFR401T.F401CF5 = OREF05;
        dsCCURFR401T.F401CF6 = OREF06;
        dsCCURFR401T.F401CF7 = OREF07;
        dsCCURFR401T.F401CF8 = OREF08;
        dsCCURFR401T.F401CF9 = OREF09;
        dsCCURFR401T.F401C10 = OREF10;

        // Reservado (Libre)
        //----------------------------------------
        dsCCURFR401T.F401LIB = *BLANKS;

        //TODOREG = CCURFR401PF;  // CCURFR401
        TODOREG = dsCCURFR401T;  // CCURFR401
        EXCEPT;

        // Graba registro en el historico CCURFR401T
        //------------------------------------------
        Graba_Reg_FR401(PARAM_IDP:PARAM_IDH);
        // =================================
        // FINAL DE PROGRAMA
        // =================================
        *INLR = *ON;
        RETURN;

      *=========================================================================
      **        Fichero: CONCUR_OUT  FORMATO: 400 y 401 HOTELES             **
      *=========================================================================
     OCONCUR_OUTE
     O                       TODOREG           2000
     O                       DSSISGESOPE       2580
        //---------------------------------------------------------------
        // Grabar registro en CCURFR400T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR400;

          dcl-pi Graba_Reg_FR400 Zoned(10);

          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);
          Dcl-s WDSSISGESOPE Char(167);

          WDSSISGESOPE = DSSISGESOPE;

          Exec Sql
            SELECT ID_F400
              INTO :WID_Gen
              FROM FINAL TABLE (
                  INSERT INTO CCURFR400T 
                  VALUES (default, 
                      :dsCCURFR400T, 
                      default,
                      :WUser,
                      :WDSSISGESOPE)
                  );

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR400T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;
        //---------------------------------------------------------------
        // Grabar registro en CCURFR401T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR401;

          dcl-pi Graba_Reg_FR401;
            P_IDFR400_P  Zoned(10);
            P_IDFR400_H  Zoned(10);
          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);
          Dcl-s WDSSISGESOPE Char(167);

          WDSSISGESOPE = DSSISGESOPE;

          Exec Sql
            SELECT ID_F401
              INTO :WID_Gen
              FROM FINAL TABLE (
            INSERT INTO CCURFR401T 
            VALUES (default,
                :P_IDFR400_P,
                :dsCCURFR401T, 
                default,
                :WUser,
                :WDSSISGESOPE)
                );

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR401T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
          Endif;

          P_IDFR400_H = WID_Gen;
        end-proc;