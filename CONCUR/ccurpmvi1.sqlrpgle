     H DECEDIT('0,') DATEDIT(*YMD.) DFTACTGRP(*NO)
     H BNDDIR('UTILITIES/UTILITIES')
      *********************************************************************
      *
      *  CONCUR EXPENSE: ENVIO DE OPERACIONES A SISTEMA DE GESTION
      *                     **  FERROCARRILES **
      *      FORMATO: 303 VIAJES -CABECERAS-  (TRAVEL ROUTING HEADER)
      *      FORMATO: 304 VIAJES -DETALLES-   (TRAVEL ROUTING DETAIL)
      *
      *      FORMATO: 401   -DETALLES-   (VENDOR INVOICE TRANSACTION)
      *********************************************************************
     FOPAGECOLG7IF   E           K DISK    EXTFILE(LABOPAGE)         USROPN     OPAGECO_B (PA/PAVC)
     FOPAGECOLGDIF   E           K DISK    RENAME(OPAGCOW:OPAGTRMI)  USROPN     OPAGECO_B (BAGENCONB
     FOPAGECOL1 IF   E           K DISK    RENAME(OPAGCOW:OPAGFACTU) USROPN     OPAGECO   (BS)
       // Solo cuando vienen del BAGENCON_VC
     FOPAGEVCLG8IF   E           K DISK    RENAME(OPAGCOW:OPALG8)               OPAGECO_VC
       // Solo cuando vienen del BAGENCON_B
     FOPAGECOLI3IF   E           K DISK    RENAME(OPAGCOW:OPALI3)               OPAGECO_B

     FSISGESTAR IF   E           K DISK                                         -Control de tarjetas

     FOPGENXDL4 IF   E           K DISK                                         -Logico: OPGENXD
     FOPFERXL   IF   E           K DISK                                         -LLAA: Dat.Interchan
     FOPFERXR   IF   E           K DISK                                         -LLAA: Dat.Interchan
     FCONCUR_OUTO    F 2580        DISK                                         -Para CONCUR

      *-------------------------------------------------
      * PROTOTIPOS DE PROGRAMAS
      *-------------------------------------------------
      *                                                                         Formato 401
      *---------------------------------------------------------------------------------------------
      *------------------------
      * EXTRUCTURAS EXTERNAS
      *------------------------
      *DCCURFR303PF    E DS                  Extname(CCURFR303) Inz               -CABECERAS
      *DCCURFR304PF    E DS                  Extname(CCURFR304) Inz               -DETALLES

       Dcl-ds dsCCURFR303T likeds(dsCCURFR303TTpl) Inz;
       Dcl-ds dsCCURFR304T likeds(dsCCURFR304TTpl) Inz;

     DROMIGPF        E DS                  Extname(ROMIG) Inz Prefix(RO_)       -DATOS GENERALES

     DRRMIGPF        E DS                  Extname(RRMIG) Inz Prefix(RR_)       -DATOS LLAA

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
     D SOCIO_ALF       S              8
     D NUDES_ALF       S              9
     D TOTGAST         S             15  2
     D TODOREG         S           2000
     D ENVIO           S              2

       Dcl-s PARAM_IDP Zoned(10);
       Dcl-s PARAM_IDH1 Zoned(10);
       Dcl-s PARAM_IDH2 Zoned(10);

      /COPY EXPLOTA/QRPGLESRC,DSCONCUR

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
          CHAIN (NUDES:SOCIO) OPAGFACTU;         // OPAGECOL1
          CHAIN (PA_PREFOR:SOCIO) RIREGXD;       //  OPGENXDL4
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXL;   //  OPFERXL
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXR;   //  OPLAEXR
        ENDIF;

        //--------------------------------------------------
        // OPERACIONES CRUZADAS - IDENTIFICACION DE FICHEROS
        //--------------------------------------------------

        IF PA_BAGEN = 'P';
          LABOPAGE = 'OPAGECOLG7';

          IF PROCESO = 'V';                    // Viajes El Corte Ingles
            LABOPAGE = 'OPAGEVCLG7';
          ENDIF;

          OPEN OPAGECOLG7;

          CHAIN (NUDES:SOCIO) OPAGCOW;    //  OPAGECOLG7 / OPAGEVCLG7
          // Si no encuentra registro en OPAGECO* lo busca por numero transaccion minerva
          IF NOT %FOUND(OPAGECOLG7);
            If PROCESO = 'V';
              CHAIN (SOCIO:TRANMIN) OPAGEVCLG8; // Lee OPAGECO_VC
            Else;
              CHAIN (SOCIO:TRANMIN) OPAGECOLI3; // Lee OPAGECO_B
            EndIf;
          ENDIF;
            // LMG MODIF 30/4/2024
          CHAIN (PA_PREFOR:SOCIO) RIREGXD;      //  OPGENXDL4
            //CHAIN (NUDES:SOCIO) RIREGXD;       //  OPGENXDL4
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXL;  //  OPFERXL
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXR;  //  OPLAEXR
        ENDIF;

        //-----------------------------------------------------
        // OPERACIONES SIN CRUZAR - RECUPERAR DATOS DE FICHEROS
        //-----------------------------------------------------

        IF PA_BAGEN = 'B';
          IF NOT %OPEN(OPAGECOLGD);
            OPEN OPAGECOLGD;
          ENDIF;
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
     C                   MOVE      OFICHE        RRMIGPF

        // ====================================================================
        // GRABAR: CCURFR303PF (CABECERAS)
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
        dsCCURFR303T.F303TAC = 'RAIL'; // ¿?

        // NOMBRE AGENCIA VIAJES (IATA)
        //----------------------------------------
        dsCCURFR303T.F303TAN = RO_PROOV;

        // FECHA SALIDA SEGMENTO
        //----------------------------------------
        dsCCURFR303T.F303DDA = RO_FEINSE;

        // NUMERO DE SEGMENTOS
        //----------------------------------------
        dsCCURFR303T.F303NLE = 01;

        // INDICADOR DE RESTRICCION
        //----------------------------------------
        dsCCURFR303T.F303RFL = '0'; // SIN RESTRICCION

        // FECHA EMISION (FECHA DE COMPRA)
        //----------------------------------------
          dsCCURFR303T.F303IDA = RO_FECOMP;

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
           //C     MOVEL     '-'           dsCCURFR303T.F303TFA
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
        dsCCURFR303T.F303ETF = ' '; // ¿?

        // BILLETE CON MAS DE 4 SEGMENTOS
        //----------------------------------------
        dsCCURFR303T.F303CID = *BLANKS; // ¿?

        // NUMERO BILLETE REEMBOLSO
        //----------------------------------------
        dsCCURFR303T.F303RTN = *BLANKS; // ¿?

        // NUMERO BILLETE CAMBIADO
        //----------------------------------------
        dsCCURFR303T.F303ETN = *BLANKS; // ¿?

        // IMPORTE BILLETE CAMBIADO
        //----------------------------------------
        dsCCURFR303T.F303ETA = *ALL'0';

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

        //TODOREG = CCURFR303PF;  // CCURFR303
        TODOREG = dsCCURFR303T;  // CCURFR303
        EXCEPT;

        // Graba registro en el historico CCURFR303T
        //------------------------------------------
        PARAM_IDH1 = Graba_Reg_FR303(PARAM_IDP);
        // ---------------------------------

        // ====================================================================
        // GRABAR: CCURFR304PF  SEGMENTO-1
        // ====================================================================

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
        dsCCURFR304T.F304CCO = *BLANKS; // ¿?

        // CLASE O CODIGO SERVICIO
        //----------------------------------------
        dsCCURFR304T.F304CSC = *BLANKS; // ¿?

        // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
        //----------------------------------------
        dsCCURFR304T.F304DLO = RO_CIUDOR;
        dsCCURFR304T.F304DCO = RO_PAISA;
        dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
        dsCCURFR304T.F304DDA = RO_FEINSE;

        // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
        //----------------------------------------
        dsCCURFR304T.F304ALO = RO_CIUDES;
        dsCCURFR304T.F304ACO = RO_PAILLE;
        dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
        dsCCURFR304T.F304ADA = RO_FEFISE;

        // NUMERO DE VUELO
        //----------------------------------------
        dsCCURFR304T.F304FNU = *BLANKS; // ¿?

        // INDICADOR SEGMENTO (ORIGEN/FINAL)
        //----------------------------------------
        dsCCURFR304T.F304OFL = '1'; // SI ORIGEN
        dsCCURFR304T.F304DFL = '1'; // SI FINAL

        // IMPORTE/GASTOS DE ESTE SEGMENTO
        //----------------------------------------
        dsCCURFR304T.F304FAR = *ALL'0'; // ¿?
        dsCCURFR304T.F304FEE = *ALL'0'; // ¿?

        // NUMERO DE BILLETE CONCATENADO
        //----------------------------------------
        dsCCURFR304T.F304CTN = *BLANKS; // ¿?

        // NUMERO BILLETE CAMBIADO
        //----------------------------------------
        dsCCURFR304T.F304ETN = *BLANKS; // ¿?

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

        //TODOREG = CCURFR304PF;  // CCURFR304
        TODOREG = dsCCURFR304T;  // CCURFR304
        EXCEPT;

        // Graba registro en el historico CCURFR303T
        //------------------------------------------
        PARAM_IDH2 = Graba_Reg_FR304(PARAM_IDP);

        // ====================================================================
        //                         FINAL DE PROGRAMA
        // ====================================================================
        *INLR = *ON;
        RETURN;

      *=========================================================================
      **        Fichero: CONCUR_OUT  FORMATO: 303 y 304  FERROCARRILES      **
      *=========================================================================
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