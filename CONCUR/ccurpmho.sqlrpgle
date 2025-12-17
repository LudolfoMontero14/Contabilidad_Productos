     H DECEDIT('0,') DATEDIT(*YMD.) DFTACTGRP(*NO)
     H BNDDIR('UTILITIES/UTILITIES')
      *********************************************************************
      *
      *  CONCUR EXPENSE: ENVIO DE OPERACIONES A SISTEMA DE GESTION
      *      FORMATO: 302 HOTELES -CABECERAS-  (LODGING HEADER)
      *      FORMATO: 307 HOTELES -DETALLES-   (LODGING DETAIL)
      *
      *      FORMATO: 401   -DETALLES-   (VENDOR INVOICE TRANSACTION)
      *********************************************************************
       //FOPAGECOLG7IF   E       K DISK    EXTFILE(LABOPAGE)         USROPN     OPAGECO_B (PA/PAVC)
     FOPAGECOLGDIF   E           K DISK    RENAME(OPAGCOW:OPAGTRMI)  USROPN     OPAGECO_B (BAGENCONB
     FOPAGECOL1 IF   E           K DISK    RENAME(OPAGCOW:OPAGFACTU) USROPN     OPAGECO   (BS)
       // Solo cuando vienen del BAGENCON_VC
     FOPAGEVCLG8IF   E           K DISK    RENAME(OPAGCOW:OPALG8)               OPAGECO_VC
       // Solo cuando vienen del BAGENCON_B
     FOPAGECOLI3IF   E           K DISK    RENAME(OPAGCOW:OPALI3)               OPAGECO_B

     FSISGESTAR IF   E           K DISK                                         -Control de tarjetas

     FOPGENXDL4 IF   E           K DISK                                         -Logico: OPGENXD
     FOPHOTXH   IF   E           K DISK                                         -Hoteles: Dat.Adici.
     FESTA1     IF   E           K DISK                                         -Comercios Espaoles
     FINDEPROV  IF   E           K DISK
     FCONCUR_OUTO    F 2580        DISK                                         -Para CONCUR

      *-------------------------------------------------
      * PROTOTIPOS DE PROGRAMAS
      *-------------------------------------------------
      *                                                                         Formato 400 Y 401
      *------------------------
      * EXTRUCTURAS EXTERNAS
      *------------------------
      *DCCURFR302PF    E DS                  Extname(CCURFR302) Inz               -CABECERAS
      *DCCURFR307PF    E DS                  Extname(CCURFR307) Inz               -DETALLES
       Dcl-ds dsCCURFR302T likeds(dsCCURFR302TTpl) Inz;
       Dcl-ds dsCCURFR307T likeds(dsCCURFR307TTpl) Inz;

     DROMIGPF        E DS                  Extname(ROMIG) Inz Prefix(RO_)       -DATOS GENERALES

     DRHMIGPF        E DS                  Extname(RHMIG) Inz Prefix(RH_)       -DATOS HOTELES
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
     D TODOREG         S           2000
     D WPOS            S              3S 0 Inz
     D ENVIO           S              2

      /COPY EXPLOTA/QRPGLESRC,DSCONCUR

       Dcl-s PARAM_IDP Zoned(10);
       Dcl-s PARAM_IDH1 Zoned(10);
       Dcl-s PARAM_IDH2 Zoned(10);
       Dcl-s WES_Ferrovial Ind;     

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

          CHAIN (NUDES:SOCIO) OPAGFACTU;        // OPAGECOL1
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXH;  //  OPHOTXH
          // DGR MODIF 30/4/2024
          CHAIN (PA_PREFOR:SOCIO) RIREGXD;      //  OPGENXDL4
          CHAIN (WNUMES)      ESTA1W;           //  ESTA1
          CHAIN (EPROPV)      INPROW;           //  INDEPROV
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

          //CHAIN (NUDES:SOCIO) OPAGCOW;          //  OPAGECOLG7 / OPAGEVCLG7
          // Si no encuentra registro en OPAGECO* lo busca por numero transaccion minerva
          //IF NOT %FOUND(OPAGECOLG7);
            If PROCESO = 'V';
              CHAIN (SOCIO:TRANMIN) OPAGEVCLG8; // Lee OPAGECO_VC
            Else;
              CHAIN (SOCIO:TRANMIN) OPAGECOLI3; // Lee OPAGECO_B
            EndIf;
          //ENDIF;
          CHAIN (NUDES:SOCIO:FECONSU) RIREGXH;  //  OPHOTXH
            // DGR MODIF 30/4/2024
          CHAIN (PA_PREFOR:SOCIO) RIREGXD;      //  OPGENXDL4
          CHAIN (WNUMES)      ESTA1W;           //  ESTA1
          CHAIN (EPROPV)      INPROW;           //  INDEPROV
        ENDIF;

        //----------------------------------------------------
        // OPERACIONES SIN CRUZAR - IDENTIFICACION DE FICHEROS
        //----------------------------------------------------

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
     C                   MOVE      OFICHE        RHMIGPF
        // =================================
        // GRABAR: CCURFR302PF (CABECERAS)
        // =================================

        //CLEAR CCURFR302PF;
        Reset dsCCURFR302T;
        dsCCURFR302T.F302IDR = 302;
        dsCCURFR302T.F302TRN =
            %EDITC(*DATE:'X') +
            %EDITC(SOCIO:'X') +
            %EDITC(NUDES:'X');

        IF PA_BAGEN = 'B';
          dsCCURFR302T.F302TRN =
              %EDITC(*DATE:'X') +
              %EDITC(SOCIO:'X') +
              TRANMIN;
        ENDIF;

        // Nº. Comercio
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302LPI = %EDITC(WNUMES:'X');
        ELSE;
          dsCCURFR302T.F302LPI = SENUM;
        ENDIF;

        // Nº. Telefono Comercio
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302PTN = ELIB4 + ETELF;
        ELSE;
          dsCCURFR302T.F302PTN = ESTPN;
        ENDIF;

        // Ciudad Comercio
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302LCI = RO_CIUDES;
        ELSE;
          dsCCURFR302T.F302LCI = ESTCO;
        ENDIF;

        // Fecha Salida
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302COD = RO_FEFISE;
        ELSE;
          If %Found(OPHOTXH);
            FECHA_SAL = '20' + HCODT;
            dsCCURFR302T.F302COD = %INT(FECHA_SAL);
          Else;
            dsCCURFR302T.F302COD = RO_FEFISE;
          Endif;
        ENDIF;

        // Fecha Llegada
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302CID = RO_FEINSE;
        ELSE;
          If %Found(OPHOTXH);
            FECHA_LLE = '20' + HCIDT;
            dsCCURFR302T.F302CID = %INT(FECHA_LLE);
          Else;
            dsCCURFR302T.F302CID = RO_FEINSE;
          EndIf;
        ENDIF;

        // Importe por Noche
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302RRN = *ALL'0';
        ELSE;
          dsCCURFR302T.F302RRN = *ALL'0';
          If HRMRT <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HRMRT);
            Dow Wpos <> 0;
              HRMRT = %Replace('0':HRMRT:Wpos:1);
              Wpos = %Scan('.':HRMRT:Wpos+1);
            Enddo;
            dsCCURFR302T.F302RRN = HRMRT;
          Endif;
        ENDIF;

        // Importe Telefono
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302PHO = *ALL'0';
        ELSE;
          dsCCURFR302T.F302PHO = *ALL'0';
          If HPHAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HPHAM);
            Dow Wpos <> 0;
              HPHAM = %Replace('0':HPHAM:Wpos:1);
              Wpos = %Scan('.':HPHAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302PHO = HPHAM;
          Endif;
        ENDIF;

        // Importe Tienda Regalo
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302GSA = *ALL'0';
        ELSE;
          dsCCURFR302T.F302GSA = *ALL'0';
          If HGSAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HGSAM);
            Dow Wpos <> 0;
              HGSAM = %Replace('0':HGSAM:Wpos:1);
              Wpos = %Scan('.':HGSAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302GSA = HGSAM;
          Endif;
        ENDIF;

        // Importe Bar / Mini-Bar (HRBAM/HMBAM)
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302BAR = *ALL'0';
        ELSE;
          dsCCURFR302T.F302BAR = *ALL'0';
          If HRBAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HRBAM);
            Dow Wpos <> 0;
              HRBAM = %Replace('0':HRBAM:Wpos:1);
              Wpos = %Scan('.':HRBAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302BAR = HRBAM;
          Endif;
        ENDIF;

        // Importe Lavanderia
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302CLA = *ALL'0';
        ELSE;
          dsCCURFR302T.F302CLA = *ALL'0';
          If HLAAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HLAAM);
            Dow Wpos <> 0;
              HLAAM = %Replace('0':HLAAM:Wpos:1);
              Wpos = %Scan('.':HLAAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302CLA = HLAAM;
          Endif;
        ENDIF;

        // Numero Folio
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302FNU = *BLANKS;
        ELSE;
          dsCCURFR302T.F302FNU = HFOLI;
        ENDIF;

        // Numero de Noches
        //----------------------------------------
        IF WNUMES > 0;
          Monitor;
            IF RH_NUNOCHE < 0;
              RH_NUNOCHE =  000;
            ENDIF;
          on-error;
            RH_NUNOCHE =  000;
          endmon;
          dsCCURFR302T.F302NON = RH_NUNOCHE;
        ELSE;
          dsCCURFR302T.F302NON = 0;
        ENDIF;

        // Importe Tasas por Dia
        //----------------------------------------
        dsCCURFR302T.F302DRT = *ALL'0';

        // Importe Comida + Bebida
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302FCH = *ALL'0';
        ELSE;
          dsCCURFR302T.F302FCH = *ALL'0';
          If HREAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HREAM);
            Dow Wpos <> 0;
              HLAAM = %Replace('0':HREAM:Wpos:1);
              Wpos = %Scan('.':HREAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302FCH = HREAM;
          Endif;
        ENDIF;

        // Importe Parking
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302PCH = *ALL'0';
        ELSE;
          dsCCURFR302T.F302PCH = *ALL'0';
          If HPKAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HPKAM);
            Dow Wpos <> 0;
              HPKAM = %Replace('0':HPKAM:Wpos:1);
              Wpos = %Scan('.':HPKAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302PCH = HPKAM;
          Endif;
        ENDIF;

        // Importe Audio/Video
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302MCH = *ALL'0';
        ELSE;
          dsCCURFR302T.F302MCH = *ALL'0';
          If HAUDI <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HAUDI);
            Dow Wpos <> 0;
              HPKAM = %Replace('0':HAUDI:Wpos:1);
              Wpos = %Scan('.':HAUDI:Wpos+1);
            Enddo;
            dsCCURFR302T.F302MCH = HAUDI;
          Endif;
        ENDIF;

        // Importe Propina
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302TCH = *ALL'0';
        ELSE;
          dsCCURFR302T.F302TCH = *ALL'0';
          If HTIPS <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HTIPS);
            Dow Wpos <> 0;
              HTIPS = %Replace('0':HTIPS:Wpos:1);
              Wpos = %Scan('.':HTIPS:Wpos+1);
            Enddo;
            dsCCURFR302T.F302TCH = HTIPS;
          Endif;
        ENDIF;

        // Importe Otros
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302OCH = *ALL'0';
        ELSE;
          dsCCURFR302T.F302OCH = *ALL'0';
          If HOTAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HOTAM);
            Dow Wpos <> 0;
              HOTAM = %Replace('0':HOTAM:Wpos:1);
              Wpos = %Scan('.':HOTAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302OCH = HOTAM;
          Endif;
        ENDIF;

        // Descripcion Tipo Propina
        //----------------------------------------
        dsCCURFR302T.F302TAC = *BLANKS;

        // Nombre Acompaante
        //----------------------------------------
        dsCCURFR302T.F302GNA = *BLANKS;
        //--------------------------------------------------
        // Control para Ferrovial (10068676) (PT-1404)
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
          dsCCURFR302T.F302GNA = RO_NOMPA;
        EndIf;
        //--------------------------------------------------
        // Nº. Invitados en Habitacion
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302NIP = 0;
        ENDIF;

        IF WNUMES = 0;
          IF %CHECK(SOLONUM:%SUBST(HNOPT:1:3):1) > 0;
            dsCCURFR302T.F302NIP = 0;
          ELSE;
            dsCCURFR302T.F302NIP = %INT(HNOPT);
          ENDIF;
        ENDIF;

        // Tipo Habitación
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302RTY = *BLANKS;
        ELSE;
          dsCCURFR302T.F302RTY = HRMTY;
        ENDIF;

        // Nº. Habitacion Reservadas
        //----------------------------------------
        dsCCURFR302T.F302NRO = 1;

        // Importe Reserva
        //----------------------------------------
        dsCCURFR302T.F302PAM = *ALL'0';

        // Importe Total Tasas
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302TRT = *ALL'0';
        ELSE;
          dsCCURFR302T.F302TRT = *ALL'0';
          If HRMTX <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HRMTX);
            Dow Wpos <> 0;
              HRMTX = %Replace('0':HRMTX:Wpos:1);
              Wpos = %Scan('.':HRMTX:Wpos+1);
            Enddo;
            dsCCURFR302T.F302TRT = HRMTX;
          Endif;
        ENDIF;

        // Importe de Ajustes
        //----------------------------------------
        IF WNUMES > 0;
          dsCCURFR302T.F302AAM = *ALL'0';
        ELSE;
          dsCCURFR302T.F302AAM = *ALL'0';
          If HBAAM <> *Blanks;
            Wpos = *Zeros;
            Wpos = %Scan('.':HBAAM);
            Dow Wpos <> 0;
              HBAAM = %Replace('0':HBAAM:Wpos:1);
              Wpos = %Scan('.':HBAAM:Wpos+1);
            Enddo;
            dsCCURFR302T.F302AAM = HBAAM;
          Endif;
        ENDIF;

        // Importe Total Estancia
        //----------------------------------------
        PIMPOR15 = IMPORTE;
        dsCCURFR302T.F302TLA = %EDITC(PIMPOR15:'X');

        IF PIMPOR15 < 0;
          PIMPOR15 *= -1;
          dsCCURFR302T.F302TLA = %EDITC(PIMPOR15:'X');
          %SubSt(dsCCURFR302T.F302TLA:1:1) = '-';
        ENDIF;

        // Importe Ajenos a la Habitación
        //----------------------------------------
        dsCCURFR302T.F302TNR = *ALL'0';

        // Codigo Mercancia
        //----------------------------------------
        dsCCURFR302T.F302CCO = *BLANKS;

        // Codigo Programa
        //----------------------------------------
        dsCCURFR302T.F302PCO = *BLANKS;

        // Codigo Otros Servicios
        //----------------------------------------
        dsCCURFR302T.F302OSC = *BLANKS;

        // Numero Orden Reserva
        //----------------------------------------
        dsCCURFR302T.F302MON = %TRIM(RO_NUMDOC);


        // Provincia/Cod.Postal/Region/Pais
        //----------------------------------------
        dsCCURFR302T.F302LSA = %Trim(RO_CIUDOR);
        dsCCURFR302T.F302LPC = *BLANKS;
        dsCCURFR302T.F302LRE = *BLANKS;
        dsCCURFR302T.F302LCO = RO_PAILLE;


        // Referencias (1-5)
        //----------------------------------------
        dsCCURFR302T.F302C01 = RO_REF1;
        dsCCURFR302T.F302C02 = RO_REF2;
        dsCCURFR302T.F302C03 = RO_REF3;
        dsCCURFR302T.F302C04 = RO_REF4;
        dsCCURFR302T.F302C05 = RO_REF5;

        // Reservado (Libre)
        //----------------------------------------
        dsCCURFR302T.F302LIB = *BLANKS;

        //TODOREG = CCURFR302PF;  // CCURFR302
        TODOREG = dsCCURFR302T;  // CCURFR302
        EXCEPT;

        // Graba registro en el historico CCURFR302T
        //------------------------------------------
        PARAM_IDH1 = Graba_Reg_FR302(PARAM_IDP);


        // =================================
        // GRABAR: CCURFR307PF (DETALLES)
        // =================================
        //CLEAR CCURFR307PF;
        Reset dsCCURFR307T;

        // Identificacion Registro
        //----------------------------------------
        dsCCURFR307T.F307IDR = 307;

        // Nº Referencia Operación
        //----------------------------------------
        FECHA_ALF = %EDITC(*DATE:'X');
        SOCIO_ALF = %EDITC(SOCIO:'X');
        NUDES_ALF = %EDITC(NUDES:'X');
        dsCCURFR307T.F307TRN = FECHA_ALF + SOCIO_ALF + NUDES_ALF;

        IF PA_BAGEN = 'B';
          dsCCURFR307T.F307TRN = FECHA_ALF + SOCIO_ALF + TRANMIN;
        ENDIF;


        // Nº Secuencia Servicio
        //----------------------------------------
        dsCCURFR307T.F307ISN = '0001';

        // Fecha Operación
        //----------------------------------------
        dsCCURFR307T.F307TDA = RO_FECOMP;

        // Fecha Cargo en Cta. (Entrada en Diners)
        //----------------------------------------
        dsCCURFR307T.F307PDA = OFEEDI;

        // Importe Operación
        //----------------------------------------
        PIMPOR15 = IMPORTE;
        dsCCURFR307T.F307TAM = %EDITC(PIMPOR15:'X');

        IF PIMPOR15 < 0;
          PIMPOR15 *= -1;
          dsCCURFR307T.F307TAM = %EDITC(PIMPOR15:'X');
          %SubSt(dsCCURFR307T.F307TAM:1:1) = '-';
          //C      MOVEL     '-'           dsCCURFR307T.F307TAM
        ENDIF;

        // Tipo Servicio
        //----------------------------------------
        dsCCURFR307T.F307ITY = 'BZCNT'; // Centro Negocios

        // Descripción Servicio
        //----------------------------------------
        dsCCURFR307T.F307IDE = RO_DESLIB;

        // Reservado (Libre)
        //----------------------------------------
        dsCCURFR307T.F307LIB = *BLANKS;

        //TODOREG = CCURFR307PF;  // CCURFR307
        TODOREG = dsCCURFR307T;  // CCURFR307
        EXCEPT;


        // Graba registro en el historico CCURFR307T
        //------------------------------------------
        PARAM_IDH2 = Graba_Reg_FR307(PARAM_IDP);

        // =================================
        // FINAL DE PROGRAMA
        // =================================
        *INLR = *ON;
        RETURN;


      *=========================================================================
      **        Fichero: CONCUR_OUT  FORMATO: 302 y 307 HOTELES             **
      *=========================================================================
     OCONCUR_OUTE
     O                       TODOREG           2000
     O                       DSSISGESOPE       2580
        //---------------------------------------------------------------
        // Grabar registro en CCURFR302T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR302;

          dcl-pi Graba_Reg_FR302 Zoned(10);
            P_IDFR302_P  Zoned(10);
          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);
          Dcl-s WDSSISGESOPE Char(167);

          WDSSISGESOPE = DSSISGESOPE;

          Exec Sql
            SELECT ID_F302
              INTO :WID_Gen
              FROM FINAL TABLE (
                INSERT INTO CCURFR302T
                VALUES (default,
                  :P_IDFR302_P,
                  :dsCCURFR302T,
                  default,
                  :WUser,
                  :WDSSISGESOPE)
                  );

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR302T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;
        //---------------------------------------------------------------
        // Grabar registro en CCURFR307T Historico
        //---------------------------------------------------------------
        dcl-proc Graba_Reg_FR307;

          dcl-pi Graba_Reg_FR307 Zoned(10);
            P_IDFR307_P  Zoned(10);
          end-pi;

          dcl-s WUser char(10) inz(*user);
          Dcl-s WID_Gen zoned(10) inz(0);
          Dcl-s WDSSISGESOPE Char(167);

          WDSSISGESOPE = DSSISGESOPE;
          Exec Sql
            SELECT ID_F307
              INTO :WID_Gen
              FROM FINAL TABLE (
                INSERT INTO CCURFR307T
                VALUES (default,
                  :P_IDFR307_P,
                  :dsCCURFR307T,
                  default,
                  :WUser,
                  :WDSSISGESOPE)
                  );

          If Sqlcode <> 0;
            observacionSql = 'Error al grabar en la tabla CCURFR307T';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;