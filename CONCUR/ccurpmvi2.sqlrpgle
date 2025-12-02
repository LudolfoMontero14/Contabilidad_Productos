     H DECEDIT('0,') DATEDIT(*YMD.) DFTACTGRP(*NO)
     H BNDDIR('UTILITIES/UTILITIES')
      *********************************************************************
      *
      *  CONCUR EXPENSE: ENVIO DE OPERACIONES A SISTEMA DE GESTION  
      *                     **  LINEAS AEREAS  **
      *      FORMATO: 303 VIAJES -CABECERAS-  (TRAVEL ROUTING HEADER)
      *      FORMATO: 304 VIAJES -DETALLES-   (TRAVEL ROUTING DETAIL)
      *
      *      FORMATO: 401   -DETALLES-   (VENDOR INVOICE TRANSACTION)
      *********************************************************************
       //FOPAGECOLG7IF   E     K DISK    EXTFILE(LABOPAGE)         USROPN     OPAGECO_B (PA/PAVC)
     FOPAGECOLGDIF   E           K DISK    RENAME(OPAGCOW:OPAGTRMI)  USROPN     OPAGECO_B (BAGENCONB
     FOPAGECOL1 IF   E           K DISK    RENAME(OPAGCOW:OPAGFACTU) USROPN     OPAGECO   (BS)
        // Solo cuando vienen del BAGENCON_VC
     FOPAGEVCLG8IF   E           K DISK    RENAME(OPAGCOW:OPALG8)               OPAGECO_VC
       // Solo cuando vienen del BAGENCON_B
     FOPAGECOLI3IF   E           K DISK    RENAME(OPAGCOW:OPALI3)               OPAGECO_B

     FSISGESTAR IF   E           K DISK                                         -Control de tarjetas

     FOPGENXDL4 IF   E           K DISK                                         -Logico: OPGENXD
     FOPLAEXA   IF   E           K DISK                                         -LLAA: Dat.Interchan
     FOPLAEXBL1 IF   E           K DISK                                         -LLAA: Dat.Interchan
     FIATA      IF   E           K DISK                                         -Agencia de Viajes
     FCIUDAD    IF   E           K DISK                                         -Aeropuertos
     FCONCUR_OUTO    F 2580        DISK                                         -Para CONCUR

      *-------------------------------------------------
      * PROTOTIPOS DE PROGRAMAS
      *-------------------------------------------------
      *                                                                         Formato 400 Y 401
      *------------------------
      * EXTRUCTURAS EXTERNAS
      *------------------------
      *DCCURFR303PF    E DS                  Extname(CCURFR303) Inz               -CABECERAS
      *DCCURFR304PF    E DS                  Extname(CCURFR304) Inz               -DETALLES

       Dcl-ds dsCCURFR303T likeds(dsCCURFR303TTpl) Inz;
       Dcl-ds dsCCURFR304T likeds(dsCCURFR304TTpl) Inz;

     DROMIGPF        E DS                  Extname(ROMIG) Inz Prefix(RO_)       -DATOS GENERALES

     DRAMIGPF        E DS                  Extname(RAMIG) Inz  Prefix(RA_)         TOS LLAA

      *------------------------
      * DEFINICION DE CAMPOS
      *------------------------
      /Copy Explota/Qrpglesrc,CCURCPY
      /COPY EXPLOTA/QRPGLESRC,MINERVA_H
      /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
      /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
     D LABOPAGE        S             10
     D LABPACON        S             10
     D FECHA_ALF       S              8
     D FECHA_LLE       S              8
     D FECHA_SAL       S              8
     D SOCIO_ALF       S              8
     D SEGMENTOS       S              2  0
     D NUDES_ALF       S              9
     D NUIATA7         S              7  0
     D TOTGAST         S             15  2
     D TODOREG         S           2000
     D WPOS            S              3S 0 Inz
     D ENVIO           S              2

      /COPY EXPLOTA/QRPGLESRC,DSCONCUR

       Dcl-s PARAM_IDP Zoned(10);
       Dcl-s PARAM_IDH1 Zoned(10);
       Dcl-s PARAM_IDH2 Zoned(10);

      *------------------------
      * PARAMETROS
      *------------------------
     C     *ENTRY        PLIST
     C                   PARM                    PARAM_IDP
     C                   PARM                    PARAM_IDH1
     C                   PARM                    PARAM_IDH2
     C                   PARM                    PARAM_PTR

        //----------------------------------------------------
        // OPERACIONES FACTURADAS - IDENTIFICACION DE FICHEROS
        //----------------------------------------------------

        IF PA_BAGEN = 'F';
          OPEN OPAGECOL1;

          CHAIN (NUDES:SOCIO) OPAGFACTU;         // OPAGECOL1   
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXA;   //  OPLAEXA    
          CHAIN (NUDES:SOCIO)         RIREGXB;   //  OPLAEXB    
            // LMG MODIF 06/5/2024
          CHAIN (PA_PREFOR:SOCIO)     RIREGXD;   //  OPGENXDL4  
        ENDIF;

        //--------------------------------------------------
        // OPERACIONES CRUZADAS - IDENTIFICACION DE FICHEROS
        //--------------------------------------------------

        IF PA_BAGEN = 'P';
          LABOPAGE = 'OPAGECOLG7';

          IF PROCESO = 'V';                    // Viajes El Corte Ingles
            LABOPAGE = 'OPAGEVCLG7';
          ENDIF;

          //OPEN OPAGECOLG7;

          //CHAIN (NUDES:SOCIO) OPAGCOW;          //  OPAGECOLG7 / OPAGEVCLG7 
          // Si no encuentra registro en OPAGECO* lo busca por numero transaccion minerva
          //IF NOT %FOUND(OPAGECOLG7);
             If PROCESO = 'V';
               CHAIN (SOCIO:TRANMIN) OPAGEVCLG8; // Lee OPAGECO_VC
             Else;
               CHAIN (SOCIO:TRANMIN) OPAGECOLI3; // Lee OPAGECO_B
             EndIf;
          //ENDIF;

          CHAIN (NUDES:SOCIO:FECONSU) RIREGXA;  //  OPLAEXA    
          CHAIN (NUDES:SOCIO)        RIREGXB;   //  OPLAEXB    
            // LMG MODIF 30/4/2024
          CHAIN (PA_PREFOR:SOCIO)    RIREGXD;   //  OPGENXDL4  
        ENDIF;

        //----------------------------------------------------
        // OPERACIONES SIN CRUZAR - IDENTIFICACION DE FICHEROS
        //----------------------------------------------------

        IF PA_BAGEN = 'B';
          IF NOT %OPEN(OPAGECOLGD);
            OPEN OPAGECOLGD;
          ENDIF;
            //CHAIN (SOCIO:TRANMIN) OPAGTRMI;         //OPAGECOLGD  
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
        // CARGAR: EXTRUCTURAS EXTERNAS
        // -----------------------------------
     C                   MOVEL     OFICHE        ROMIGPF
     C                   MOVE      OFICHE        RAMIGPF
        // -----------------------------------
        // RECUPERAR DATOS DE FICHEROS
        // -----------------------------------
        NUIATA7 = RO_NUIATA / 10;
        CHAIN (NUIATA7)            RIATA;    //  IATA       

        // ====================================================================
        // GRABAR: CCURFR303PF (CABECERAS)                                    
        // ====================================================================

        //CLEAR CCURFR303PF;
        reset dsCCURFR303T;
        dsCCURFR303T.F303IDR = 303;
        dsCCURFR303T.F303TRN = 
          %EDITC(*DATE:'X') + 
          %EDITC(SOCIO:'X') + 
          %EDITC(NUDES:'X');

        IF PA_BAGEN = 'B';
          dsCCURFR303T.F303TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            TRANMIN;
        ENDIF;

        // Numero Billete
        //----------------------------------------
        dsCCURFR303T.F303TNU = %TRIM(RO_NUMDOC);

        // Nombre Pasajero
        //----------------------------------------
        dsCCURFR303T.F303PNA = RO_NOMPA;

        // CODIGO AGENCIA VIAJES (IATA)
        //----------------------------------------
        dsCCURFR303T.F303TAC = %EDITC(RO_NUIATA:'X');

        // NOMBRE AGENCIA VIAJES (IATA)
        //----------------------------------------
        dsCCURFR303T.F303TAN = RNOMBR;

        // FECHA SALIDA SEGMENTO-1
        //----------------------------------------
        dsCCURFR303T.F303DDA = RO_FEINSE;

        // NUMERO DE SEGMENTOS
        //----------------------------------------
        SEGMENTOS = 0;

        IF WNUMES > 0;
          EXSR NSEGMENTOS;
          dsCCURFR303T.F303NLE = SEGMENTOS;
        ELSE;
          EXSR NSEGMENTOS;
          // 28-11-2018: enviamos todo desde MInerva
          // EXSR ISEGMENTOS; 28-11-18: Tiene 5 segmentos (OPLAEXB) y Minerva tiene 12
          dsCCURFR303T.F303NLE = SEGMENTOS;
        ENDIF;

        // INDICADOR DE RESTRICCION
        //----------------------------------------
        dsCCURFR303T.F303RFL = '0'; // SIN RESTRICCION

        // FECHA EMISION (FECHA DE COMPRA)
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR303T.F303IDA = RO_FECOMP;
        ELSE;
          dsCCURFR303T.F303IDA = %DEC(%DATE(FECONSU:*EUR):*ISO);
          //dsCCURFR303T.F303IDA = FECONSU;
        ENDIF;

        // ABREVIATURA LLAA QUE VUELA
        //----------------------------------------
        dsCCURFR303T.F303ICA = RO_PROOV;

        // DATO DEFINIDO POR CLIENTE
        //----------------------------------------
        dsCCURFR303T.F303CDA = *BLANKS; // ¿?

        // TARIFA BASE (IMPORTE NETO)
        //----------------------------------------
        dsCCURFR303T.F303BFA = %EDITC(RO_IMNETA:'X');

        // IMPORTE TOTAL BILLETE
        //----------------------------------------
        dsCCURFR303T.F303TFA = %EDITC(RO_IMPOP:'X');

        IF RO_SIGIMOP = '-';
          %SubSt(dsCCURFR303T.F303TFA:1:1) = '-';
         // C          MOVEL     '-'           dsCCURFR303T.F303TFA
        ENDIF;

        // IMPORTE TOTAL GASTOS
        //----------------------------------------
        TOTGAST = 0;
        dsCCURFR303T.F303TFE = *ALL'0';

        IF RO_IMNETA <> 0;
          TOTGAST = RO_IMPOP - RO_IMNETA;
          dsCCURFR303T.F303TFE = %EDITC(TOTGAST:'X');
        ENDIF;

        // INDICADOR DE CAMBIO
        //----------------------------------------
        IF RA_TIPDOC = '1';
          dsCCURFR303T.F303ETF = '0'; // NO CAMBIADO
        ELSE;
          dsCCURFR303T.F303ETF = '1'; // SI CAMBIADO
        ENDIF;

        // BILLETE CON MAS DE 4 SEGMENTOS
        //----------------------------------------
        dsCCURFR303T.F303CID = *BLANKS; // ¿?

        // NUMERO BILLETE REEMBOLSO
        //----------------------------------------
        dsCCURFR303T.F303RTN = %TRIM(RA_NUREEM);

        // NUMERO BILLETE CAMBIADO
        //----------------------------------------
        IF RA_TIPDOC <> '1';
          dsCCURFR303T.F303ETN = %TRIM(RO_NUMDOC);
        ENDIF;

        // IMPORTE BILLETE CAMBIADO
        //----------------------------------------
        dsCCURFR303T.F303ETA = *ALL'0';

        IF RA_TIPDOC <> '1';
          dsCCURFR303T.F303ETA = %EDITC(RO_IMPOP:'X');
          IF RO_SIGIMOP = '-';
            %subSt(dsCCURFR303T.F303ETA:1:1) = '-';
         //C    MOVEL     '-'           dsCCURFR303T.F303ETA
          ENDIF;
        ENDIF;

        // CODIGO MERCANCIA
        //----------------------------------------
        dsCCURFR303T.F303CCO = *BLANKS; // ¿?

        // Referencias (1-5)
        //----------------------------------------
        dsCCURFR303T.F303C01 = RO_REF1;
        dsCCURFR303T.F303C02 = RO_REF2;
        dsCCURFR303T.F303C03 = RO_REF3;
        dsCCURFR303T.F303C04 = RO_REF4;
        dsCCURFR303T.F303C05 = RO_REF5;

        // Reservado (Libre)
        //----------------------------------------
        dsCCURFR303T.F303LIB = *BLANKS;

        //TODOREG = CCURFR303PF;  // CCURFR303   
        TODOREG = dsCCURFR303T;  // CCURFR303   
        EXCEPT;

        // Graba registro en el historico CCURFR303T
        //------------------------------------------
        PARAM_IDH1 = Graba_Reg_FR303(PARAM_IDP);

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-1                                    
        // ====================================================================
        //  Primer segmento siempre tiene compañia, excepto las compañia LOW COST
        //IF RA_COALCO1 <> ' ' AND RA_COALCO1 <> '00';

        //CLEAR CCURFR304PF;
        Reset dsCCURFR304T;
        dsCCURFR304T.F304IDR = 304;
        dsCCURFR304T.F304TRN = 
          %EDITC(*DATE:'X') + 
          %EDITC(SOCIO:'X') + 
          %EDITC(NUDES:'X');

        IF PA_BAGEN = 'B';
           dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            TRANMIN;
        ENDIF;

        // Nº.DEL SEGMENTO
        //----------------------------------------
        dsCCURFR304T.F304TLN = '01';

        // CODIGO ABREVIADO LLAA
        //----------------------------------------
        dsCCURFR304T.F304CCO = RA_COALCO1;

        // CLASE O CODIGO SERVICIO
        //----------------------------------------
        dsCCURFR304T.F304CSC = RA_CLASER1;

        // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
        //----------------------------------------
        CHAIN (RA_AERSAL1)         XCITY;    //  CIUDAD     

        IF %FOUND;
          dsCCURFR304T.F304DLO = XCIUDA;
          dsCCURFR304T.F304DCO = XPAIS;
          IF %FOUND;
            IF XISONU = '724';
              dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
            ELSE;
              dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
            ENDIF;
          ENDIF;
        ENDIF;

        dsCCURFR304T.F304DDA = RO_FEINSE;

        // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
        //----------------------------------------
        CHAIN (RA_AERDES1)         XCITY;    //  CIUDAD     

        IF %FOUND;
          dsCCURFR304T.F304ALO = XCIUDA;
          dsCCURFR304T.F304ACO = XPAIS;
          IF %FOUND;
            IF XISONU = '724';
              dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
            ELSE;
              dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
            ENDIF;
          ENDIF;
        ENDIF;

        dsCCURFR304T.F304ADA = RA_FLLEGA1;

        // NUMERO DE VUELO
        //----------------------------------------
        dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL1:'X');

        // INDICADOR SEGMENTO (ORIGEN/FINAL)
        //----------------------------------------
        dsCCURFR304T.F304OFL = '1'; // SI ORIGEN

        IF RA_AERDES2 <> ' ' AND RA_AERDES2 <> '000';
          dsCCURFR304T.F304DFL = '0'; // NO FINAL
        ELSE;
          dsCCURFR304T.F304DFL = '1'; // SI FINAL
        ENDIF;

        // IMPORTE/GASTOS DE ESTE SEGMENTO
        //----------------------------------------
        dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
        dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

        // NUMERO DE BILLETE CONCATENADO
        //----------------------------------------
        dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

        // NUMERO BILLETE CAMBIADO
        //----------------------------------------
        IF RA_TIPDOC <> '1';
          dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
        ENDIF;

        // Referencias (1-5)
        //----------------------------------------
        dsCCURFR304T.F304C01 = RO_REF1;
        dsCCURFR304T.F304C02 = RO_REF2;
        dsCCURFR304T.F304C03 = RO_REF3;
        dsCCURFR304T.F304C04 = RO_REF4;
        dsCCURFR304T.F304C05 = RO_REF5;

        // Reservado (Libre)
        //----------------------------------------
        dsCCURFR304T.F304LIB = *BLANKS;

        //TODOREG = CCURFR304PF;  // CCURFR304   
        TODOREG = dsCCURFR304T;  // CCURFR304   
        EXCEPT;

        // Graba registro en el historico CCURFR304T
        //------------------------------------------
        PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-2                                    
        // ====================================================================
        IF RA_COALCO2 <> ' ' AND RA_COALCO2 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '02';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO2;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER2;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES1)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA1;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES2)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA2;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL2:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES3 <> ' ' AND RA_AERDES3 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-3                                    
        // ====================================================================
        IF RA_COALCO3 <> ' ' AND RA_COALCO3 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '03';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO3;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER3;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES2)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA2;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES3)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA3;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL3:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES4 <> ' ' AND RA_AERDES4 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR303T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);

        ENDIF;
        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-4                                    
        // ====================================================================
        IF RA_COALCO4 <> ' ' AND RA_COALCO4 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '04';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO4;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER4;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES3)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA3;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES4)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA4;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL4:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES5 <> ' ' AND RA_AERDES5 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-5                                    
        // ====================================================================
        IF RA_COALCO5 <> ' ' AND RA_COALCO5 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '05';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO5;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER5;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES4)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA4;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES5)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA5;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL5:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES6 <> ' ' AND RA_AERDES6 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-6                                    
        // ====================================================================
        IF RA_COALCO6 <> ' ' AND RA_COALCO6 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '06';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO6;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER6;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES5)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA5;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES6)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA6;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL6:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES7 <> ' ' AND RA_AERDES7 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-7                                    
        // ====================================================================
        IF RA_COALCO7 <> ' ' AND RA_COALCO7 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '07';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO7;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER7;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES6)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA6;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES7)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA7;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL7:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES8 <> ' ' AND RA_AERDES8 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-8                                    
        // ====================================================================
        IF RA_COALCO8 <> ' ' AND RA_COALCO8 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '08';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO8;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER8;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES7)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA7;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES8)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA8;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL8:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES9 <> ' ' AND RA_AERDES9 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-9                                    
        // ====================================================================
        IF RA_COALCO9 <> ' ' AND RA_COALCO9 <> '00';

          //CLEAR CCURFR304PF;
          reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '09';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO9;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER9;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES8)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA8;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES9)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA9;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL9:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES10 <> ' ' AND RA_AERDES10 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-10                                   
        // ====================================================================
        IF RA_COALCO10 <> ' ' AND RA_COALCO10 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '10';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO10;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER10;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES9)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA9;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES10)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA10;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL10:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES11 <> ' ' AND RA_AERDES11 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-11                                   
        // ====================================================================
        IF RA_COALCO11 <> ' ' AND RA_COALCO11 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '11';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO11;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER11;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES10)         XCITY;    //  CIUDAD     

          IF %FOUND;
          dsCCURFR304T.F304DLO = XCIUDA;
          dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA10;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES11)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA11;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL11:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

          IF RA_AERDES12 <> ' ' AND RA_AERDES12 <> '000';
            dsCCURFR304T.F304DFL = '0'; // NO FINAL
          ELSE;
            dsCCURFR304T.F304DFL = '1'; // SI FINAL
          ENDIF;

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-12                                   
        // ====================================================================
        IF RA_COALCO12 <> ' ' AND RA_COALCO12 <> '00';

          //CLEAR CCURFR304PF;
          Reset dsCCURFR304T;
          dsCCURFR304T.F304IDR = 304;
          dsCCURFR304T.F304TRN =
             %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

          IF PA_BAGEN = 'B';
            dsCCURFR304T.F304TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
          ENDIF;

          // Nº.DEL SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304TLN = '12';

          // CODIGO ABREVIADO LLAA
          //----------------------------------------
          dsCCURFR304T.F304CCO = RA_COALCO12;

          // CLASE O CODIGO SERVICIO
          //----------------------------------------
          dsCCURFR304T.F304CSC = RA_CLASER12;

          // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
          //----------------------------------------
          CHAIN (RA_AERDES11)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304DLO = XCIUDA;
            dsCCURFR304T.F304DCO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304DDA = RA_FLLEGA11;

          // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
          //----------------------------------------
          CHAIN (RA_AERDES12)         XCITY;    //  CIUDAD     

          IF %FOUND;
            dsCCURFR304T.F304ALO = XCIUDA;
            dsCCURFR304T.F304ACO = XPAIS;
            IF %FOUND;
              IF XISONU = '724';
                dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
              ELSE;
                dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
              ENDIF;
            ENDIF;
          ENDIF;

          dsCCURFR304T.F304ADA = RA_FLLEGA12;

          // NUMERO DE VUELO
          //----------------------------------------
          dsCCURFR304T.F304FNU = %EDITC(RA_NUVUEL12:'X');

          // INDICADOR SEGMENTO (ORIGEN/FINAL)
          //----------------------------------------
          dsCCURFR304T.F304OFL = '0'; // NO ORIGEN
          dsCCURFR304T.F304DFL = '1'; // SI FINAL

          // IMPORTE/GASTOS DE ESTE SEGMENTO
          //----------------------------------------
          dsCCURFR304T.F304FAR = *ALL'0'; // NO NOS LO ENVIAN ¿?
          dsCCURFR304T.F304FEE = *ALL'0'; // NO NOS LO ENVIAN ¿?

          // NUMERO DE BILLETE CONCATENADO
          //----------------------------------------
          dsCCURFR304T.F304CTN = %TRIM(RO_NUMDOC);

          // NUMERO BILLETE CAMBIADO
          //----------------------------------------
          IF RA_TIPDOC <> '1';
            dsCCURFR304T.F304ETN = %TRIM(RO_NUMDOC);
          ENDIF;

          // Referencias (1-5)
          //----------------------------------------
          dsCCURFR304T.F304C01 = RO_REF1;
          dsCCURFR304T.F304C02 = RO_REF2;
          dsCCURFR304T.F304C03 = RO_REF3;
          dsCCURFR304T.F304C04 = RO_REF4;
          dsCCURFR304T.F304C05 = RO_REF5;

          // Reservado (Libre)
          //----------------------------------------
          dsCCURFR304T.F304LIB = *BLANKS;

          //TODOREG = CCURFR304PF;  // CCURFR304   
          TODOREG = dsCCURFR304T;  // CCURFR304   
          EXCEPT;

          // Graba registro en el historico CCURFR304T
          //------------------------------------------
           PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);
        ENDIF;

        // ====================================================================
        //                         FINAL DE PROGRAMA                          
        // ====================================================================
        *INLR = *ON;
        RETURN;

        //***********************************************************************
        //**    SUBRUTINA: NUMERO DE SEGMENTOS (Operacion en España)
        //***********************************************************************
        BEGSR NSEGMENTOS;

          IF RA_AERSAL1 <> ' ';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES1 <> ' ' AND RA_AERDES1 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES2 <> ' ' AND RA_AERDES2 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES3 <> ' ' AND RA_AERDES3 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES4 <> ' ' AND RA_AERDES4 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES5 <> ' ' AND RA_AERDES5 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES6 <> ' ' AND RA_AERDES6 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES7 <> ' ' AND RA_AERDES7 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES8 <> ' ' AND RA_AERDES8 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES9 <> ' ' AND RA_AERDES9 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES10 <> ' ' AND RA_AERDES10 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES11 <> ' ' AND RA_AERDES11 <> '000';
            SEGMENTOS += 1;
          ENDIF;

          IF RA_AERDES12 <> ' ' AND RA_AERDES12 <> '000';
            SEGMENTOS += 1;
          ENDIF;

        ENDSR;
        //***********************************************************************
        //**    SUBRUTINA: NUMERO DE SEGMENTOS (Operacion de Internacional)
        //***********************************************************************
        BEGSR ISEGMENTOS;

          IF DAPC1 <> ' ';
            SEGMENTOS += 1;
          ENDIF;

          IF AAPC1 <> ' ';
            SEGMENTOS += 1;
          ENDIF;

          IF AAPC2 <> ' ';
            SEGMENTOS += 1;
          ENDIF;

          IF AAPC3 <> ' ';
            SEGMENTOS += 1;
          ENDIF;

          IF AAPC4 <> ' ';
            SEGMENTOS += 1;
          ENDIF;

        ENDSR;
        //***********************************************************************

      *========================================================================= 
      **        Fichero: CONCUR_OUT  FORMATO: 303 y 304 LINEAS AEREAS       **
      *========================================================================= 
     OCONCUR_OUTE
     O                       TODOREG           2000
     O                       DSSISGESOPE       2580
        //---------------------------------------------------------------
        // Grabar registro en CCURFR303T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR303;

          dcl-pi Graba_Reg_FR303 Zoned(10);
            P_IDFR303_P  Zoned(10);
          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);

          Exec Sql
            SELECT ID_F303
              INTO :WID_Gen
              FROM FINAL TABLE (
                INSERT INTO CCURFR303T 
                VALUES (default,
                  :P_IDFR303_P,
                  :dsCCURFR303T, 
                  default,
                  :WUser));

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR303T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;

        //---------------------------------------------------------------
        // Grabar registro en CCURFR304T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR304;

          dcl-pi Graba_Reg_FR304 Zoned(10);
            P_IDFR304_P  Zoned(10);
          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);

          Exec Sql
            SELECT ID_F304
              INTO :WID_Gen
              FROM FINAL TABLE (
                INSERT INTO CCURFR304T 
                VALUES (default,
                  :P_IDFR304_P,
                  :dsCCURFR304T, 
                  default,
                  :WUser));

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR304T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;      