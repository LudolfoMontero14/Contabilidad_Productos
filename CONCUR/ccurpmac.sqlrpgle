     H DECEDIT('0,') DATEDIT(*YMD.) DFTACTGRP(*NO)
     H BNDDIR('UTILITIES/UTILITIES')
      *********************************************************************
      *
      *  CONCUR EXPENSE: ENVIO DE OPERACIONES A SISTEMA DE GESTION
      *      FORMATO: 301 ALQUILER COCHES (CAR RENTAL DETAIL)
      *
      *      FORMATO: 401   -DETALLES-   (VENDOR INVOICE TRANSACTION)
      *********************************************************************
     FOPAGECOLG7IF   E           K DISK    EXTFILE(LABOPAGE)         USROPN     OPAGECO_B (PA/PAVC)
     FOPAGECOLGDIF   E           K DISK    RENAME(OPAGCOW:OPAGTRMI)  USROPN     OPAGECO_B (BAGENCONB
       // Solo cuando vienen del BAGENCON_VC
     FOPAGEVCLG8IF   E           K DISK    RENAME(OPAGCOW:OPALG8)               OPAGECO_VC
      // Solo cuando vienen del BAGENCON_B
     FOPAGECOLI3IF   E           K DISK    RENAME(OPAGCOW:OPALI3)               OPAGECO_B
     FOPAGECOL1 IF   E           K DISK    RENAME(OPAGCOW:OPAGFACTU) USROPN     OPAGECO   (BS)
     FSISGESTAR IF   E           K DISK                                         -Control de tarjetas
     FOPCARXV   IF   E           K DISK                                         -Alq.Coches: Interna
     FCONCUR_OUTO    F 2580        DISK
      *-------------------------------------------------
      * PROTOTIPOS DE PROGRAMAS
      *-------------------------------------------------
      *                                                                         Formato 401
      *------------------------
      * EXTRUCTURAS EXTERNAS
      *------------------------
      *DCCURFR301PF    E DS                  Extname(CCURFR301) Inz
        Dcl-ds dsCCURFR301T likeds(dsCCURFR301TTpl) Inz;

     DROMIGPF        E DS                  Extname(ROMIG)     Inz Prefix(RO_)    DATOS GENERALES

     DRVMIGPF        E DS                  Extname(RVMIG)     Inz  Prefix(RV_)   ATOS ALQ.COCHES

      *------------------------
      * DEFINICION DE CAMPOS
      *------------------------
     D LABOPAGE        S             10
     D FECHA_REC       S              8
     D FECHA_DEV       S              8
     D TODOREG         S           2000
     D WPOS            S              3S 0 Inz
     D ENVIO           S              2

      /Copy Explota/Qrpglesrc,CCURCPY
      /COPY EXPLOTA/QRPGLESRC,MINERVA_H
      /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
      /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL 
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
          CHAIN (NUDES:SOCIO) OPAGFACTU;         // OPAGECOL1
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXV;   //  OPCARXV
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

          CHAIN (NUDES:SOCIO) OPAGCOW;           //OPAGECOLG7 / OPAGEVCLG7
          // Si no encuentra registro en OPAGECO* lo busca por numero transaccion minerva
          IF NOT %FOUND(OPAGECOLG7);
            If PROCESO = 'V';
              CHAIN (SOCIO:TRANMIN) OPAGEVCLG8; // Lee OPAGECO_VC
            Else;
              CHAIN (SOCIO:TRANMIN) OPAGECOLI3; // Lee OPAGECO_B
            EndIf;
          ENDIF;
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXV;   //  OPCARXV
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

        //------------------------------------
        // CARGAR: EXTRUCTURAS EXTERNAS
        //------------------------------------

     C                   MOVEL     OFICHE        ROMIGPF
     C                   MOVE      OFICHE        RVMIGPF

        // ---------------------------------
        // GRABAR: CCURFR301PF
        // ---------------------------------

        //CLEAR CCURFR301PF;
        Reset dsCCURFR301T;
        dsCCURFR301T.F301IDR = 301;
        dsCCURFR301T.F301TRN = 
            %EDITC(*DATE:'X') + 
            %EDITC(SOCIO:'X') + 
            %EDITC(NUDES:'X');

        IF PA_BAGEN = 'B';
          dsCCURFR301T.F301TRN = 
              %EDITC(*DATE:'X') + 
              %EDITC(SOCIO:'X') + 
              TRANMIN;
        ENDIF;

        dsCCURFR301T.F301RAN = %TRIM(RO_NUMDOC);
        dsCCURFR301T.F301RNA = RO_PROOV;

        //    Datos Recogida Vehiculo

        IF WNUMES > 0;
          dsCCURFR301T.F301PDA = RO_FEINSE;
          dsCCURFR301T.F301PCI = RO_CIUDOR;
          dsCCURFR301T.F301PCO = RO_PAISA;
        ELSE;
          FECHA_REC = '20' + %EDITC(RENDT:'X');
          dsCCURFR301T.F301PDA = %INT(FECHA_REC);
          dsCCURFR301T.F301PCI = RENCY;
          dsCCURFR301T.F301PCO = RENST;
        ENDIF;

        //    Datos Devolucion Vehiculo

        IF WNUMES > 0;
          dsCCURFR301T.F301RDA = RO_FEFISE;
          dsCCURFR301T.F301RCI = RO_CIUDES;
          dsCCURFR301T.F301RCO = RO_PAILLE;
        ELSE;
        FECHA_DEV = '20' + %EDITC(RETDT:'X');
          dsCCURFR301T.F301RDA = %INT(FECHA_DEV);
          dsCCURFR301T.F301RCI = RETCY;
          dsCCURFR301T.F301RCO = RETST;
        ENDIF;

        //  Indicador: No se Presenta

        IF WNUMES > 0;
          IF RV_NOSHOW = 'S';
            dsCCURFR301T.F301NSF = '1';
          ELSE;
            dsCCURFR301T.F301NSF = '0';
          ENDIF;
        ELSE;
          IF RNOSH = '1';
            dsCCURFR301T.F301NSF = '1';
          ELSE;
            dsCCURFR301T.F301NSF = '0';
          ENDIF;
        ENDIF;

        //  Importe por Distancia

        IF WNUMES > 0;
          dsCCURFR301T.F301ADU = *ALL'0';
        ELSE;
          dsCCURFR301T.F301ADU = *ALL'0';
          If RMRTE <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':RMRTE);
            Dow Wpos <> 0;
              RMRTE = %Replace('0':RMRTE:Wpos:1);
              Wpos = %Scan('.':RMRTE:Wpos+1);
            Enddo;
            dsCCURFR301T.F301ADU = RMRTE;
          Endif;
        ENDIF;

        //  Importe por Dia

        IF WNUMES > 0;
          dsCCURFR301T.F301DRE = *ALL'0';
        ELSE;
          dsCCURFR301T.F301DRE = *ALL'0';
          If RDRTE <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':RDRTE);
            Dow Wpos <> 0;
              RDRTE = %Replace('0':RDRTE:Wpos:1);
              Wpos = %Scan('.':RDRTE:Wpos+1);
            Enddo;
            dsCCURFR301T.F301DRE = RDRTE;
          Endif;
        ENDIF;

        //  Importe por Semana

        IF WNUMES > 0;
          dsCCURFR301T.F301WRA = *ALL'0';
        ELSE;
          dsCCURFR301T.F301WRA = *ALL'0';
          If RWRTE <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':RWRTE);
            Dow Wpos <> 0;
              RWRTE = %Replace('0':RWRTE:Wpos:1);
              Wpos = %Scan('.':RWRTE:Wpos+1);
            Enddo;
            dsCCURFR301T.F301WRA = RWRTE;
          Endif;
        ENDIF;

        //  Codigo Clase Vehiculo

        IF WNUMES > 0;
          dsCCURFR301T.F301VCC = RV_CLASVEH;
        ELSE;
          dsCCURFR301T.F301VCC = RCCAR;
        ENDIF;

        //  Numero de Vehiculo

        dsCCURFR301T.F301NVE = 001;

        //  Distancia total del periodo

        IF WNUMES > 0;
          dsCCURFR301T.F301TDI = 0;
        ELSE;
          dsCCURFR301T.F301TDI = 0;
          IF RDIST <> *BLANKS;
            dsCCURFR301T.F301TDI = %INT(RDIST);
          ENDIF;
        ENDIF;

        // Importe distancia recorrida

        IF WNUMES > 0;
          dsCCURFR301T.F301RDC = *ALL'0';
        ELSE;
          dsCCURFR301T.F301RDC = *ALL'0';
          If RRMIC <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':RRMIC);
            Dow Wpos <> 0;
              RRMIC = %Replace('0':RRMIC:Wpos:1);
              Wpos = %Scan('.':RRMIC:Wpos+1);
            Enddo;
            dsCCURFR301T.F301RDC = RRMIC;
          Endif;
        ENDIF;

        // Importe distancia extra

        IF WNUMES > 0;
          dsCCURFR301T.F301EDR = *ALL'0';
        ELSE;
          dsCCURFR301T.F301EDR = *ALL'0';
          If REMIC <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':REMIC);
            Dow Wpos <> 0;
              REMIC = %Replace('0':REMIC:Wpos:1);
              Wpos = %Scan('.':REMIC:Wpos+1);
            Enddo;
            dsCCURFR301T.F301EDR = REMIC;
          Endif;
        ENDIF;

        // Importe devolucion distinta localidad

        IF WNUMES > 0;
          dsCCURFR301T.F301OWD = *ALL'0';
        ELSE;
          dsCCURFR301T.F301OWD = *ALL'0';
          If ROWDC <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':ROWDC);
            Dow Wpos <> 0;
              ROWDC = %Replace('0':ROWDC:Wpos:1);
              Wpos = %Scan('.':ROWDC:Wpos+1);
            Enddo;
            dsCCURFR301T.F301OWD = ROWDC;
          Endif;
        ENDIF;

        // Importe retraso devolucion vehiculo

        IF WNUMES > 0;
          dsCCURFR301T.F301LCH = *ALL'0';
        ELSE;
          dsCCURFR301T.F301LCH = *ALL'0';
          If RLRTC <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':RLRTC);
            Dow Wpos <> 0;
              RLRTC = %Replace('0':RLRTC:Wpos:1);
              Wpos = %Scan('.':RLRTC:Wpos+1);
            Enddo;
            dsCCURFR301T.F301LCH = RLRTC;
          Endif;
        ENDIF;

        // Importe carburante

        IF WNUMES > 0;
          dsCCURFR301T.F301FCH = *ALL'0';
        ELSE;
          dsCCURFR301T.F301FCH = *ALL'0';
          If RFUEC <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':RFUEC);
            Dow Wpos <> 0;
              RFUEC = %Replace('0':RFUEC:Wpos:1);
              Wpos = %Scan('.':RFUEC:Wpos+1);
            Enddo;
            dsCCURFR301T.F301FCH = RFUEC;
          Endif;
        ENDIF;

        // Importe del seguro

        IF WNUMES > 0;
          dsCCURFR301T.F301ICH = *ALL'0';
        ELSE;
          dsCCURFR301T.F301ICH = *ALL'0';
          If RINSC <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':RINSC);
            Dow Wpos <> 0;
              RINSC = %Replace('0':RINSC:Wpos:1);
              Wpos = %Scan('.':RINSC:Wpos+1);
            Enddo;
            dsCCURFR301T.F301ICH = RINSC;
          Endif;
        ENDIF;

        // Importe Otros

        IF WNUMES > 0;
          dsCCURFR301T.F301OCH = *ALL'0';
        ELSE;
          dsCCURFR301T.F301OCH = *ALL'0';
          If ROTHC <> *Blanks;
            Wpos = 0;
            Wpos = %Scan('.':ROTHC);
            Dow Wpos <> 0;
              ROTHC = %Replace('0':ROTHC:Wpos:1);
              Wpos = %Scan('.':ROTHC:Wpos+1);
            Enddo;
            dsCCURFR301T.F301OCH = ROTHC;
          Endif;
          ENDIF;

        // Importe Ajuste

        IF WNUMES > 0;
          dsCCURFR301T.F301AAM = *ALL'0';
        ELSE;
          dsCCURFR301T.F301AAM = *ALL'0';
        ENDIF;

        // Codigo cargos extra

        dsCCURFR301T.F301ECA = *ALL'0';

        // Referencias (1-5)

        dsCCURFR301T.F301C01 = RO_REF1;
        dsCCURFR301T.F301C02 = RO_REF2;
        dsCCURFR301T.F301C03 = RO_REF3;
        dsCCURFR301T.F301C04 = RO_REF4;
        dsCCURFR301T.F301C05 = RO_REF5;

        //TODOREG = CCURFR301PF;  // CCURFR301
        TODOREG = dsCCURFR301T;  // CCURFR301
        EXCEPT;

        // Graba registro en el historico CCURFR303T
        //------------------------------------------
        PARAM_IDH1 = Graba_Reg_FR301(PARAM_IDP);

        // ---------------------------------
        // FINAL DE PROGRAMA
        // ---------------------------------
        *INLR = *ON;
        RETURN;

      *=========================================================================
      **        Fichero: CONCUR_OUT  FORMATO: 301 ALQUILER DE COCHES        **
      *=========================================================================
     OCONCUR_OUTE
     O                       TODOREG           2000
     O                       DSSISGESOPE       2580
        //---------------------------------------------------------------
        // Grabar registro en CCURFR301T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR301;

          dcl-pi Graba_Reg_FR301 Zoned(10);
            P_IDFR301_P  Zoned(10);
          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);

          Exec Sql
            SELECT ID_F301
              INTO :WID_Gen
              FROM FINAL TABLE (
                INSERT INTO CCURFR301T 
                VALUES (default,
                  :P_IDFR301_P,
                  :dsCCURFR301T, 
                  default,
                  :WUser));

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR301T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;