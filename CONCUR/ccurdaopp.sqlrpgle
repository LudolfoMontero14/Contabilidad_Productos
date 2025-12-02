     H DECEDIT('0,') DATEDIT(*YMD.) DFTACTGRP(*NO)
     H BNDDIR('UTILITIES/UTILITIES')
      *********************************************************************
      *    PAVC    PACONLGSGV     /   PACONLGSG   --PA
      *  CONCUR EXPENSE: ENVIO DE OPERACIONES A SISTEMA DE GESTION  
      *  FORMATO: 200 DATOS OPERACION (EXPENSE/PURCHASE TRANSACTIONS)
      *
      *********************************************************************
     FPACONLGSG IF   E           K DISK    EXTFILE(LABPA)            USROPN     PA/PAVC
       //FOPAGECOLG7IF   E    K DISK    EXTFILE(LABOPAGE)         USROPN     OPAGECO_B (PA/PAVC)
     FOPAGECOLGDIF   E           K DISK    RENAME(OPAGCOW:OPAGTRMI)  USROPN     OPAGECO_B (BAGENCONB
      // Solo cuando vienen del BAGENCON_VC
     FOPAGEVCLG8IF   E           K DISK    RENAME(OPAGCOW:OPALG8)               OPAGECO_VC
      // Solo cuando vienen del BAGENCON_B
     FOPAGECOLI3IF   E           K DISK    RENAME(OPAGCOW:OPALI3)               OPAGECO_B

     FOPAGECOL1 IF   E           K DISK    RENAME(OPAGCOW:OPAGFACTU) USROPN     OPAGECO   (BS)

     FOPGENXDL4 IF   E           K DISK                                         -Logico: OPGENXD
     FMSOCIO    IF   F  731     8AIDISK    KEYLOC(3)
     FESTA1     IF   E           K DISK
     FTABACTI   IF   E           K DISK
     FINDEPROV  IF   E           K DISK
     FSGCCURTV  IF   E           K DISK                                         -TALON VENTA VECI
     FSGCCURIM  IF   E           K DISK                                         -IMPORTE NETO
     FSGCCURMCC IF   E           K DISK                                         -MCC
     FPAISESISOLIF   E           K DISK                                         -PAIS ISO
     FCONCUR_OUTO    F 2580        DISK                                         -Para CONCUR

      *-------------------------------------------------
      * OPAGECO_B : TIPO OPERACION             (V-01.00) 
      *-------------------------------------------------
     D                 DS
     D  OFICHE                 1   1910
     D   GETIPRE               1      2                                         -TIPO REGISTRO
     D   GESERFEE            492    492                                         -CARGO POR EMISION
     D
      *------------------------
      * EXTRUCTURAS EXTERNAS
      *------------------------
      *DCCURFR200PF    E DS                  Extname(CCURFR200) Inz
       Dcl-ds dsCCURFR200T likeds(dsCCURFR200TTpl) Inz;

     DROMIGPF        E DS                  Extname(ROMIG) Inz Prefix(RO_)

      //------------------------
      // DEFINICION DE CAMPOS
      //------------------------
      /Copy Explota/Qrpglesrc,CCURCPY
      /COPY EXPLOTA/QRPGLESRC,MINERVA_H
      /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
      /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
       Dcl-S ABONO        Char(1);
       Dcl-S BNUCR22      Char(14);
       Dcl-S PIMPOR15     Packed(15:0);
       Dcl-S PIMPMO15     Packed(15:0);
       Dcl-S PIMPISO      Packed(15:0);
       Dcl-S LABPA        Char(10);
       Dcl-S LABOPAGE     Char(10);
       Dcl-S LABPACON     Char(10);
       Dcl-S FECHA_ALF    Char(8);
       Dcl-S SOCIO_ALF    Char(8);
       Dcl-S SOCIO_OPA    Packed(8:0);
       Dcl-S NUDES_ALF    Char(9);
       Dcl-S NUDES_NUM    Packed(9:0);
       Dcl-S TASAS        Packed(15:2);
       Dcl-S TASAX        Packed(15:2);
       Dcl-S TODOREG      Char(2000);

       Dcl-s WNUMEST  Zoned(7);
       Dcl-s WIndra   Ind;
       Dcl-s WES_REPSOL    Ind;
       Dcl-s WES_Ferrovial Ind;
       Dcl-s WIMPIVA  Zoned(15:0);
       Dcl-s WGENUFACT Char(20);

       dcl-s prueba char(1);
       Dcl-s PARAM_ID Zoned(10);

       Dcl-ds dsTRASAC      likeds(dsTRASACTpl) INZ;

      /COPY EXPLOTA/QRPGLESRC,DSCONCUR
     D  PIMPMO                64     74  0
     D  PIMPMO10              64     73  0

     IMSOCIO    NS
     I                                  1   14  NTAR14
     I                                  1   10  NTAR10
     I                                  1    6  NSBIN
     I                                  7   10  NSSEC
     I                                 11   14  NSRES
     I                                513  521  SNNIF

      *------------------------
      * PARAMETROS
      *------------------------
     C     *ENTRY        PLIST
     C                   PARM                    PARAM_ID
     C                   PARM                    PARAM_PTR
      /Free

        CHAIN SOCIO  MSOCIO;

        //----------------------------------------------------
        // OPERACIONES FACTURADAS - IDENTIFICACION DE FICHEROS
        //----------------------------------------------------

        IF PA_BAGEN = 'F';
          OPEN OPAGECOL1;

          CHAIN (NUDES:SOCIO) OPAGFACTU;   // OPAGECOL1   
          CHAIN (PA_PREFOR:SOCIO) RIREGXD; //  OPGENXDL4  
          CHAIN (WNUMES)      ESTA1W;      //  ESTA1      
          CHAIN (EPROPV)      INPROW;      //  INDEPROV   
        ENDIF;

        //--------------------------------------------------
        // OPERACIONES CRUZADAS - IDENTIFICACION DE FICHEROS
        //--------------------------------------------------

        IF PA_BAGEN = 'P';
          LABOPAGE = 'OPAGECOLG7';  // OPAGECO_B
          LABPA    = 'PACONLGSG';   // PA

          IF PROCESO = 'V';           // Viajes El Corte Ingles
            LABOPAGE = 'OPAGEVCLG7';  // OPAGECO_VC
            LABPA    = 'PACONLGSGV';  // PAVC
          ENDIF;

          //OPEN OPAGECOLG7;
          OPEN PACONLGSG;

          CHAIN (SOCIO:NUDES) PPA;      //  PACONLGSG  / PACONLGSGV 
          //CHAIN (NUDES:SOCIO) OPAGCOW;  //  OPAGECOLG7 / OPAGECO_B 
          // Si no encuentra registro en OPAGECO* lo busca por numero transaccion minerva
          //IF NOT %FOUND(OPAGECOLG7);
            If PROCESO = 'V';
              CHAIN (SOCIO:TRANMIN) OPAGEVCLG8; // Lee OPAGECO_VC
            Else;
              CHAIN (SOCIO:TRANMIN) OPAGECOLI3; // Lee OPAGECO_B
            EndIf;
          //ENDIF;
          CHAIN (PA_PREFOR:SOCIO) RIREGXD; //  OPGENXDL4  
          CHAIN WNUMES ESTA1W;
          CHAIN EPROPV INPROW;
        ENDIF;

        //----------------------------------------------------
        // OPERACIONES SIN CRUZAR - IDENTIFICACION DE FICHEROS
        //----------------------------------------------------

        IF PA_BAGEN = 'B';
          OPEN OPAGECOLGD;
          //CHAIN (SOCIO:TRANMIN) OPAGTRMI;         //OPAGECOLGD  
          CHAIN (SOCIO:TRANMIN) OPAGEVCLG8;
          If Not %Found(OPAGEVCLG8);
            CHAIN (SOCIO:TRANMIN) OPAGECOLI3;
            If Not %Found(OPAGECOLI3);
              *INLR = *ON;
              RETURN;
            EndIf;
          EndIf;

          SELECT;
            WHEN GETIPRE = 'RR' AND GESERFEE <> ' ';   // FERROCARRIL
              EACTPR    = 61;
            WHEN GETIPRE = 'RA' AND GESERFEE <> ' ';  // LINEA AEREAS
              EACTPR    = 66;
            WHEN GETIPRE = 'RV' AND GESERFEE <> ' ';  // ALQUILER COCHES
              EACTPR    = 62;
            WHEN GETIPRE = 'RH' AND GESERFEE <> ' ';  // HOTELES
              EACTPR    = 10;
            OTHER;
            EACTPR    = 72;
          ENDSL;

        ENDIF;

        ROMIGPF = OFICHE;

        // *************************************************
        // Busqueda de Datos Originales en el TRANSAC
        // posteriormente se eliminara la lectura del OPAGECO
        Reset dsTRASAC;
        // Exec SQL
        //   SELECT
        //   AGNUMAGE,HONUMFIC,GENUMTRA,GETIPRE,GENUTRAN,GENUMTAR,GEPROOV,GEFEINSE,
        //   GEFEFISE,GECIUDOR,GECOISOSA,GEPAISA,GECIUDES,GECOISOPD,GEPAILLE,GENOMPA,
        //   GEFECOMP,GENUFACT,GEFEFAG,GENUALBA,GEIMPOP,GESIGIMOP,GEISOMON,GEIMNETA,
        //   GEIMTASA,GEISIIVA1,GEIMIVA1,GEPOIVA1,GEISIIVA2,GEIMIVA2,GEPOIVA2,GEISIIVA3,
        //   GEIMIVA3,GEPOIVA3,GEINOIVA1,GESERFEE,GENUMDOC,GETIPODOC,GETOURCO,GENUMAUD,
        //   GENUCOPV,GENUCOFA,GENOTPV,GENUIATA,GETARCON,GEREF01,GEREF02,GEREF03,
        //   GEREF04,GEREF05,GEREF06,GEREF07,GEREF08,GEREF09,GEREF10,GEDESLIB,
        //   GENUSEC,GENADINE,GERECHA,ERCODEST,GEREGIST,AAFECMOD,AAHORMOD,AAUSUMOD,
        //   OP_NUMERO_OPERACION, TR_NUMERO_TRANSACCION
        // Into :dsTRASAC
        // FROM ATRIUM.TRANSAC
        // WHERE
        //   AGNUMAGE = :PAGENC
        //   AND HONUMFIC = :PNFICM
        //   AND GENUMTRA = :TRANMIN
        // ;
        WGENUFACT = ' ';
        // Exec SQL
        //   SELECT
        //     IFNULL(GENUFACT, ' '),
        //     IFNULL(GEIMNETA, 0)
        //     Into :WGENUFACT, :GEIMNETA
        //   FROM ATRIUM.TRANSAC
        //   WHERE
        //     AGNUMAGE = :PAGENC
        //     AND HONUMFIC = :PNFICM
        //     AND GENUMTRA = :TRANMIN
        // ;

        // If Sqlcode < 0;
        //   If 1=1;
        //     prueba='2';
        //   EndIf;
          // observacionSql = 'TRANSAC: Error en Select. PAGENC:' +
          //                   %editc(PAGENC:'X') + '. PNFICM:' +
          //                   %editc(PNFICM:'X') + '. TRANMIN:' + %trim(TRANMIN);
          // Clear Nivel_Alerta;
          // Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
        // EndIf;
        // If Sqlcode = 100;
        //   prueba='3';
          // observacionSql = 'TRANSAC: Error no encontro registro. PAGENC:' +
          //                   %editc(PAGENC:'X') + '. PNFICM:' +
          //                   %editc(PNFICM:'X') + '. TRANMIN:' + %trim(TRANMIN);
          // Clear Nivel_Alerta;
          // Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
        //Endif;
        //If Sqlcode <> 0; // Si hay un error en la busqueda en el TRANS se mueve el de OPAGECO
          WGENUFACT = RO_NUFACT;
        //EndIf;
        // *************************************************

        IF PA_BAGEN = 'B';
          Monitor;
            WNUMEST =
              %Dec(%SubSt(%Editc(RO_NUCOFA:'X'):1:7):7:0);
          on-error;
            WNUMEST = 0;
          endmon;
          CHAIN WNUMEST ESTA1W;
          CHAIN EPROPV    INPROW;
        EndIf;

        // ---------------------------------
        // GRABAR: CCURFR200PF             
        // ---------------------------------

        //CLEAR CCURFR200PF;
        Reset dsCCURFR200T;

        dsCCURFR200T.F200IDR = 200;

        // Javier turegaono 04-02-13 (concur)
        // Numero Tarjeta
        //-----------------------------
        //dsCCURFR200T.F200CCN = NSBIN + '****' + NSRES;
        //dsCCURFR200T.F200CCN = NTAR14;

        dsCCURFR200T.F200CCN = NTAR10 + '9999';

        // Nº Referencia Operación
        //-----------------------------

        //  para operaciones -PE- Y -FA-
        dsCCURFR200T.F200TRN = %EDITC(*DATE:'X') + 
                               %EDITC(SOCIO:'X') + 
                               %EDITC(NUDES:'X');

        IF PA_BAGEN = 'B'; 
        // -AG: Directamente de agecia (Bagenconb) NO CRUZADAS
        // 03/11/2025 POr no cuadrar con la referencia de los 
        //registros 303, 304..
        // Se utiliza el campo de No de Referencia Minerva
        // dsCCURFR200T.F200TRN = %EDITC(*DATE:'X') + %EDITC(SOCIO:'X') 
        //+ OREFOP;
          dsCCURFR200T.F200TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
        ENDIF;

        // Fecha Consumo
        //-----------------------------
        dsCCURFR200T.F200TDA = RO_FECOMP;

        // Fecha Entrada Diners
        //-----------------------------
        dsCCURFR200T.F200PDA = OFEEDI;

        // Codigo ISO Moneda Origen
        //-----------------------------
        dsCCURFR200T.F200FTI = %EDITC(P_PMONED:'X');
        IF dsCCURFR200T.F200FTI = '000';
          dsCCURFR200T.F200FTI = '978';
        ENDIF;

        // Importe Moneda Origen
        //-----------------------------
        ABONO = ' ';

        PIMPISO  = IMPORTE;                 //PARA IMPORTE MCC  ISO

        IF IMPORTE < 0;
          IMPORTE *= -1;
          ABONO   = 'A';
        ENDIF;

        IF P_PVARIO = ' ';
          P_PVARIO = *ALL'0';
        ENDIF;

        IF PIMPMO < 0;
          PIMPMO *= -1;
        ENDIF;

        PIMPMO15 = PIMPMO10;
        PIMPOR15 = IMPORTE;

        dsCCURFR200T.F200IMO = %EDITC(PIMPMO15:'X');
        IF PIMPMO = 0;
          dsCCURFR200T.F200IMO = %EDITC(PIMPOR15:'X');
        ENDIF;

        IF ABONO = 'A';
          %Subst(dsCCURFR200T.F200IMO:1:1) = '-';
          //C                   MOVEL     '-'           dsCCURFR200T.F200IMO
        ENDIF;

        // Codigo ISO Moneda Facturada
        //-----------------------------
        dsCCURFR200T.F200ITF = '978';

        // Importe Moneda Facturada
        //-----------------------------
        dsCCURFR200T.F200IMF = %EDITC(PIMPOR15:'X');

        IF ABONO = 'A';
          %Subst(dsCCURFR200T.F200IMF:1:1) = '-';
         //C                   MOVEL     '-'           dsCCURFR200T.F200IMF
        ENDIF;

        // Nombre Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR200T.F200MNA = ENOMBR;
        ELSE;
          dsCCURFR200T.F200MNA = ESTAB;
        ENDIF;

        // Nombre Comercio   oper. bagencond
        //--------------------------------------------------------
        IF PA_BAGEN = 'B';      //Operaciones de Agencia  -AG-
          dsCCURFR200T.F200MNA = RO_PROOV;
        ENDIF;

        // Actividad ISO Comercio (MCC)
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR200T.F200MCC = %EDITC(EMODCA:'X');
        ELSE;
          dsCCURFR200T.F200MCC = MCCCD;
        ENDIF;

        // Actividad ISO Comercio (MCC)  oper. bagencond
        //--------------------------------------------------------
        IF PA_BAGEN = 'B';      //Operaciones de Agencia  -AG-
          CHAIN EACTPR TABACT;
          dsCCURFR200T.F200MCC = %EDITC(TACDCI:'X');
        ENDIF;

        // Localidad Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR200T.F200MCI = %SUBST(ELOCPV:7:26);
        ELSE;
          dsCCURFR200T.F200MCI = LCITY;
        ENDIF;

        // Provincia Comercio
        //-----------------------------

        dsCCURFR200T.F200MSP = *BLANKS;

        IF WNUMES > 0 AND WNUMES <> 9999999;
          dsCCURFR200T.F200MSP = PNOPRO;
        ENDIF;

        IF PA_BAGEN = 'B';      //Operaciones de Agencia  -AG-
          dsCCURFR200T.F200MSP = PNOPRO;
        ENDIF;
        // Codigo Postal Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR200T.F200MPC = %Subst(ELOCPV:1:5);
        ELSE;
          dsCCURFR200T.F200MPC = ESTZP;
        ENDIF;

        // Codigo ISO Pais Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR200T.F200IMC = '724';
        ELSE;
          dsCCURFR200T.F200IMC = %EDITC(GEOCD:'X');
        ENDIF;

        // Total Importe Tasas
        //-----------------------------
        TASAS = 0;

        IF WNUMES > 0;
          TASAS = RO_IMIVA1 + RO_IMIVA2 + RO_IMIVA3;
          dsCCURFR200T.F200ITT = %EDITC(TASAS:'X');
        ELSE;
          TASAS = TAX1 + TAX2;
          dsCCURFR200T.F200ITT = %EDITC(TASAS:'X');
        ENDIF;

        IF ABONO = 'A' AND TASAS <> 0;
          %Subst(dsCCURFR200T.F200ITT:1:1) = '-';  
         //C                   MOVEL     '-'           dsCCURFR200T.F200ITT
        ENDIF;

        // Tasas: Local/Goods/Sales/Other
        //--------------------------------
        TASAX = 0;
        dsCCURFR200T.F200ITL = %EDITC(TASAX:'X');
        dsCCURFR200T.F200ITG = %EDITC(TASAX:'X');
        dsCCURFR200T.F200ITS = %EDITC(TASAX:'X');
        dsCCURFR200T.F200ITO = %EDITC(TASAX:'X');

        // Numero de Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR200T.F200MRN = %EDITC(WNUMES:'X');
        ELSE;
          dsCCURFR200T.F200MRN = SENUM;
        ENDIF;

        IF PA_BAGEN = 'B';
          dsCCURFR200T.F200MRN = %EDITC(WNumEst:'X');
        EndIf;
        // NIF/CIF del Comercio
        //-----------------------------
        IF WNUMES > 0;
          dsCCURFR200T.F200MTN = ENNIF;
        ELSE;
          dsCCURFR200T.F200MTN = *BLANKS;
        ENDIF;

        // CIF Empresa
        //-----------------------------
        dsCCURFR200T.F200CTN = SNNIF;

        // Indicador de IVA
        //-----------------------------
        IF WNUMES > 0;
          IF TASAS = 0;
            dsCCURFR200T.F200VDI = '0'; // Desconocido
          ELSE;
            dsCCURFR200T.F200VDI = '2'; // Con Iva
          ENDIF;
        ENDIF;

        IF WNUMES = 0;
          IF TASAX = 0;
            dsCCURFR200T.F200VDI = '0'; // Desconocido
          ELSE;
            dsCCURFR200T.F200VDI = '2'; // Con Iva
          ENDIF;
        ENDIF;

        // Tipo Facturación
        //-----------------------------
        //dsCCURFR200T.F200BTY = '02'; // Individual: se cambia de valor segur e-mail 5.11.2011
        dsCCURFR200T.F200BTY = '01'; // Individual

        // Descripción Transaccion
        //-----------------------------
        dsCCURFR200T.F200TDE = RO_DESLIB;

        // Referencias (1-10)
        //-----------------------------
        dsCCURFR200T.F200C01 = RO_REF1;
        dsCCURFR200T.F200C02 = RO_REF2;
        dsCCURFR200T.F200C03 = RO_REF3;
        dsCCURFR200T.F200C04 = RO_REF4;
        dsCCURFR200T.F200C05 = RO_REF5;
        dsCCURFR200T.F200A01 = RO_REF6;
        dsCCURFR200T.F200A02 = RO_REF7;
        dsCCURFR200T.F200A03 = RO_REF8;
        dsCCURFR200T.F200A04 = RO_REF9;
        dsCCURFR200T.F200A05 = RO_REF10;

        // Identificacion Empleado
        //-----------------------------
        dsCCURFR200T.F200EID = RO_REF1;

        //--------------------------------------------------
        // Especial para Tarjeta 08611112  -BANCO SANTANDER-
        //--------------------------------------------------
        // Fecha Entrada Diners  a Fecha de servicio
        // DESCLIB  A REFERENCIA 4
        // CIUDAD DESTINO   A REFERENCIA 5
        // dsCCURFR200T.F200C05 = %Subst(RO_CIUDES:1:20);
        // DESLIB   A REFERENCIA 5  NUEVA PETICION POR EMAIL-13-04-2023
        // dsCCURFR200T.F200C05 = %Subst(RO_DESLIB:21:20);      MAITE PEREZ
        //--------------------------------------------------------------
        IF SOCIO = 08611112 AND GETIPRE = 'RO';
          dsCCURFR200T.F200PDA = RO_FEINSE;
          dsCCURFR200T.F200C04 = %Subst(RO_DESLIB:1:20);
          dsCCURFR200T.F200C05 = %Subst(RO_DESLIB:21:20);
        ENDIF;

        //--------------------------------------------------
        // Control para Ferrovial (10068676) (PT-1250)
        //--------------------------------------------------
            WES_Ferrovial = *Off;
            Exec SQL
              Select '1'
              Into :WES_Ferrovial
              From SISGESTAR
              Where
                TNREAL = :SOCIO
                AND TGRUPO = 10068676  // hay que confirmar el codigo
                AND TFBASG = 0
            ;
            If WES_Ferrovial;
              dsCCURFR200T.F200C05 = %Editc(RO_FEINSE:'X');
              dsCCURFR200T.F200A01 = %Editc(RO_FEFISE:'X');
              //WIMPIVA = RO_IMNETA*100;
              //WIMPIVA = RO_ISIIVA1*100;    // Solicitud Maite  06-10-2024
              WIMPIVA = RO_IMIVA1*100;       // Solicitud Paloma 22-10-2024
              //dsCCURFR200T.F200A02 = %Editc(WIMPIVA:'X');
              dsCCURFR200T.F200A02 = %Char(WIMPIVA);
              dsCCURFR200T.F200A05 = WGENUFACT;   // Se agrega por peticion de Maite
            EndIf;
        //--------------------------------------------------

        //--------------------------------------------------
        // Referencias (2) talón de Venta de VECI -SGCCURTV
        //--------------------------------------------------

        // OPERACIONES FACTURADAS                
        SOCIO_OPA = ONREAL;
        NUDES_NUM = NUDES;

        CHAIN SOCIO_OPA SGCCURW;

        IF %FOUND AND SFECBAJ = 0;                // TALON VENTA

          IF PA_BAGEN = 'F';
            IF RO_NUALBA  <> ' ';
              dsCCURFR200T.F200C02 = RO_NUALBA;
            ENDIF;
          ENDIF;

          // OPERACIONES PENDIENTES  PA / PAVC     
          IF PA_BAGEN = 'P' OR PROCESO = 'V';
            IF RO_NUALBA  <> ' ';
              dsCCURFR200T.F200C02 = RO_NUALBA;
            ENDIF;
          ENDIF;

        ENDIF;               //FIN DE TALON VENTA

        //----------------------------------------
        // Referencias (4) Importe Neto   -SGCCURIM
        //----------------------------------------

        // OPERACIONES FACTURADAS                
        SOCIO_OPA = ONREAL;

        CHAIN SOCIO_OPA IGCCURW;
        IF %FOUND AND IFECBAJ = 0;                // Importe neto

          IF PA_BAGEN = 'F';
            IF RO_IMNETA  <> 0;
              dsCCURFR200T.F200C04 =  %EDITC(RO_IMNETA:'X');
            ENDIF;
          ENDIF;

          // OPERACIONES PENDIENTES  PA / PAVC     

          IF PA_BAGEN = 'P' OR PROCESO = 'V';
            IF RO_IMNETA  <> 0;
              dsCCURFR200T.F200C04 =  %EDITC(RO_IMNETA:'X');
            ENDIF;
          ENDIF;

        ENDIF;               //FIN DE IMPORTE NETO
        //--------------------------------------------------
        // CAMPOS VARIOS   MCC (Mechant Code)
        //--------------------------------------------------

        // OPERACIONES FACTURADAS   -RH-HOTELES  
        SOCIO_OPA = ONREAL;

        IF GETIPRE = 'RH' AND GESERFEE =  '3';  // HOTELES

          CHAIN SOCIO_OPA MGCCURW;
          IF %FOUND AND MFECBAJ = 0;          // ENCONTRADO

            IF PA_BAGEN = 'F';             // OPER. FACTURADAS

              dsCCURFR200T.F200MCC = '7011';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOPD <> ' ';
                CHAIN RO_COISOPD PAISEISOW;
                IF %FOUND;
                  dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                ENDIF;
              ENDIF;
            ENDIF;                             // FIN OPER FACTURADAS

            // OPERACIONES PENDIENTES  PA / PAVC   HOTELES  

            IF PA_BAGEN = 'P' OR PROCESO = 'V';      // OPER PENDIENTES
              dsCCURFR200T.F200MCC = '7011';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOPD <> ' ';
                CHAIN RO_COISOPD PAISEISOW;
                IF %FOUND;
                  dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                ENDIF;
              ENDIF;

            ENDIF;         // FIN OPER PENDIENTES

          ENDIF;            //ENCONTRADO

        ENDIF;               //FIN MCC  HOTELES


        // OPERACIONES FACTURADAS   -RV- ALQUILER COCHES  

        SOCIO_OPA = ONREAL;

        IF GETIPRE = 'RV' AND GESERFEE =  '3';  // COCHES

          CHAIN SOCIO_OPA MGCCURW;
          IF %FOUND AND MFECBAJ = 0;          // ENCONTRADO ALQUILER COCHES

            IF PA_BAGEN = 'F';             // OPER. FACTURADAS

              dsCCURFR200T.F200MCC = '7512';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOSA <> ' ';
                CHAIN RO_COISOSA PAISEISOW;
                  IF %FOUND;
                    dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                  ENDIF;
              ENDIF;
            ENDIF;                             // FIN OPER FACTURADAS

            // OPERACIONES PENDIENTES  PA / PAVC   RV -ALQUILER COCHES 

            IF PA_BAGEN = 'P' OR PROCESO = 'V';      // OPER PENDIENTES

              dsCCURFR200T.F200MCC = '7512';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOPD <> ' ';
                CHAIN RO_COISOSA PAISEISOW;
                IF %FOUND;
                  dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                ENDIF;
              ENDIF;

            ENDIF;         // FIN OPER PENDIENTES

          ENDIF;            //ENCONTRADO  ALQUILER COCHES

        ENDIF;               //FIN MCC  COCHES


        // OPERACIONES FACTURADAS   -RR-  FERROCARRIL     

        SOCIO_OPA = ONREAL;

        IF GETIPRE = 'RR' AND GESERFEE =  '3';  // FERROCARRIL

          CHAIN SOCIO_OPA MGCCURW;

          IF %FOUND AND MFECBAJ = 0;          // ENCONTRADO FERROCARRIL

            IF PA_BAGEN = 'F';             // OPER. FACTURADAS

              dsCCURFR200T.F200MCC = '4011';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOSA <> ' ';
                CHAIN RO_COISOSA PAISEISOW;
                IF %FOUND;
                  dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                ENDIF;
              ENDIF;
            ENDIF;                             // FIN OPER FACTURADAS

             // OPERACIONES PENDIENTES  PA / PAVC   RV -FERROCARRIL     

            IF PA_BAGEN = 'P' OR PROCESO = 'V';      // OPER PENDIENTES

              dsCCURFR200T.F200MCC = '4011';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOPD <> ' ';
                CHAIN RO_COISOSA PAISEISOW;
                IF %FOUND;
                  dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                ENDIF;
              ENDIF;

            ENDIF;         // FIN OPER PENDIENTES

          ENDIF;            //ENCONTRADO FERROCARRIL

        ENDIF;               //FIN MCC


        // OPERACIONES FACTURADAS   -RA-  LINEA AEREAS    

        SOCIO_OPA = ONREAL;

        IF GETIPRE  = 'RA' AND  GESERFEE = '3'  AND
           RO_NUMAUD <> 0  AND PIMPISO > 0;            // LINEA AEREAS    15-02-23 CAU-4787

          CHAIN SOCIO_OPA MGCCURW;
          IF %FOUND AND MFECBAJ = 0;          // ENCONTRADO LINEA AEREAS

            IF PA_BAGEN = 'F';             // OPER. FACTURADAS

              dsCCURFR200T.F200MCC = '4511';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
              dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOSA <> ' ';
                CHAIN RO_COISOSA PAISEISOW;
                IF %FOUND;
                  dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                ENDIF;
              ENDIF;
            ENDIF;                             // FIN OPER FACTURADAS

            // OPERACIONES PENDIENTES  PA / PAVC   RA -LINEA AEREAS    
            IF PA_BAGEN = 'P' OR PROCESO = 'V';      // OPER PENDIENTES

              dsCCURFR200T.F200MCC = '4511';

              IF RO_PROOV   <> ' ';
                dsCCURFR200T.F200MNA = RO_PROOV;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MCI = RO_CIUDES;
              ENDIF;

              IF RO_CIUDES  <> ' ';
                dsCCURFR200T.F200MSP = RO_CIUDES;
              ENDIF;

              IF RO_COISOPD <> ' ';
                CHAIN RO_COISOSA PAISEISOW;
                IF %FOUND;
                  dsCCURFR200T.F200IMC = %EDITC(C_CODE:'X');
                ENDIF;
              ENDIF;

            ENDIF;         // FIN OPER PENDIENTES

            // Aqui Validaciones si es REPSOL para MCC
            // CAU-10743
            WES_REPSOL = '0';
            Exec SQL
              Select '1'
              Into :WES_REPSOL
              From SISGESTAR
              Where
                TNREAL = :SOCIO
                AND TGRUPO = 10030462
                AND TFBASG = 0
            ;
            If WES_REPSOL;
              dsCCURFR200T.F200MCC = '4722';
            EndIf;
          ENDIF;            //ENCONTRADO LINEA AEREAS

        ENDIF;               //FIN MCC LINEA AEREAS

        // CAU-10743 Tarjetas REPSOL
        // --------------------------
        IF GETIPRE  = 'RA' AND  GESERFEE = '3'  AND
           RO_NUMAUD = 0  AND PIMPISO > 0;
          CHAIN SOCIO MGCCURW;
          IF %FOUND AND MFECBAJ = 0;
            WES_REPSOL = '0';
            Exec SQL
              Select '1'
              Into :WES_REPSOL
              From SISGESTAR
              Where
                TNREAL = :SOCIO
                AND TGRUPO = 10030462
                AND TFBASG = 0
            ;
            If WES_REPSOL;
              dsCCURFR200T.F200MCC = '4511';
            EndIf;
          EndIf;
        Endif;

        // Reservado (Libre)
        //-----------------------------
        dsCCURFR200T.F200lib = *BLANKS;

        //---------------------------------------
        // Cambios en el campo dsCCURFR200T.F200MNA para INDRA
        //---------------------------------------
        WIndra = *Off;
        Exec SQL
          Select '1'
            Into :WIndra
          From Ficheros.SISGESTAR
          Where
            TGRUPO=10082321         -- (INDRA)
            AND TCODSG = 001
            AND TFBASG = 0
            AND TNREAL = :SOCIO;

        If WIndra;
          dsCCURFR200T.F200MNA = %Editc(RO_FEINSE:'X') + '-' +
                    %Trim(RO_NUALBA)      + '-' +
                    %Trim(RO_PROOV)
          ;
        Endif;
        //---------------------------------------


        //TODOREG = CCURFR200PF;  // CCURFR200   
        TODOREG = dsCCURFR200T;
        EXCEPT;

        // Graba registro en el historico CCURFR400T
        //------------------------------------------
        PARAM_ID = Graba_Reg_FR200();

        // ---------------------------------
        // FINAL DE PROGRAMA
        // ---------------------------------
        *INLR = *ON;
        RETURN;

      *========================================================================= 
      **        Fichero: CONCUR_OUT  FORMATO: 200 DATOS OPERACION           **
      *========================================================================= 
     OCONCUR_OUTE
     O                       TODOREG           2000
     O                       DSSISGESOPE       2580
        //---------------------------------------------------------------
        // Grabar registro en CCURFR200T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR200;

          dcl-pi Graba_Reg_FR200 Zoned(10);

          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);


          Exec Sql
            SELECT ID_F200
              INTO :WID_Gen
              FROM FINAL TABLE (
                  INSERT INTO CCURFR200T 
                  VALUES (default, 
                      :dsCCURFR200T, 
                      default,
                      :WUser));

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR200T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;