     H DECEDIT('0,') DATEDIT(*YMD.) bnddir('UTILITIES/UTILITIES')
     H DFTACTGRP(*NO)

      /DEFINE CCURPRINCI
      *********************************************************************
      *
      *             CONCUR EXPENSE: OPERACIONES FACTURADAS   
      *   - DESDE FICHERO "SISGESCCUR" TARJETAR CON OPER.PDTES.DE ENVIO.   
      *   - SEGUN TIPO DE OPERACION ELIGE PROGRAMA PARA FORMATO RGTRO.
      *   - GRABA FICHERO "SISGESOPE"  CONTROL OPERACION ENVIADA.
      *
      *========================================================================
      * CAMBIOS:
      *  - Excluir operaciones de Indra < 16-05-2024             LMG 15052024
      *********************************************************************
     FSISGESCCURIF   E           K DISK                                         -Tarjetas CONCUR
     FBSSG      IF   F  541     8AIDISK    KEYLOC(16)                           -Operac. Facturadas
     FOPAGECOLGFIF   E           K DISK                                         -Logico: OPAGECO
     FSISGESFEENIF   E           K DISK                                         -NO enviar FEE
     FSISGESOPL7UF A E           K DISK    RENAME(OSISGESW:NUMTRMIN)            -Hist.Oper.Enviadas
     F                                     BLOCK(*NO)
     FSISGESTAR IF   E           K DISK    RENAME(TSISGESW:TSISGESR)            -Control de tarjetas
     FSISGESOPL8UF   E           K DISK    RENAME(OSISGESW:OSISGES7)            -Hist.Oper.Enviadas

      *-------------------------------------------------
      * OPAGECO: DATOS ADICIONALES, MINERVA (V-01.00) 
      *-------------------------------------------------
     D                 DS
     D  OFICHE                 1   1910
     D   GETIPRE               1      2                                         -TIPO REGISTRO
     D   GESERFEE            492    492                                         -CARGO POR EMISION
     D   BILLEREN            500    512                                         -N.BILLETE RENFE

      *-------------------------------------------------
      * PROTOTIPOS DE PROGRAMAS
      *-------------------------------------------------
      ///Free
        Dcl-PR CCURDAOPP  EXTPGM('CCURDAOPP'); //Operacion
         *N             Zoned(10:0);
         *N             Pointer;
        End-PR;
        Dcl-PR CCURPMAC  EXTPGM('CCURPMAC'); //Alquiler de Coches
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Pointer;
        End-PR;
        Dcl-PR CCURPMHO  EXTPGM('CCURPMHO'); //Hoteles
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Pointer;
        End-PR;
        Dcl-PR CCURPMVI1  EXTPGM('CCURPMVI1'); //Viajes 1
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Pointer;
        End-PR;
        Dcl-PR CCURPMVI2  EXTPGM('CCURPMVI2'); //Viajes 2
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Pointer;
        End-PR;
        Dcl-PR CCURPMCRE  EXTPGM('CCURPMCRE'); //Operacion
         *N             Zoned(10:0);
         *N             Zoned(10:0);
         *N             Pointer;
        End-PR;
      *---------------------------------------------------------------------------------------------

      *-------------------------------------------------
      * DEFINICION DE CAMPOS
      *-------------------------------------------------
     D FECCON          S              8  0
     D OFENOP_ALF      S              8
     D ONREAL_ALF      S              8
     D ONDESC_ALF      S              9
     D ONFIMI_GUA      S              9  0
     D UNAVEZ          S              2  0
     D ENVIO           S              2

       dcl-s WIndra       ind;
       dcl-s Fec_Consumo  Zoned(8);
       Dcl-S LABPA        Char(10);
       Dcl-S LABBAGENCO   Char(10);
       dcl-s WOpageco     Char(10);
       Dcl-s WID_Control  Zoned(10);
       dcl-s P_IDFRXXX_P  Zoned(10);
       dcl-s P_IDFRXXX_H1 Zoned(10);
       dcl-s P_IDFRXXX_H2 Zoned(10);
       Dcl-s WID_Fichero  Zoned(10);
       Dcl-s WTlabel      Char(10);

       /Copy Explota/QRPGLESRC,CCURCPY
       /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
       /copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
       /COPY EXPLOTA/QRPGLESRC,DSCONCUR

       dcl-ds dsCCUROPEENV qualified inz;
          ID_Control           Int(10);
          NUREAL               Packed(8:0);
          Num_Agencia_Minerva  Packed(4:0);
          FICHERO_MINERVA      Packed(9:0);
          Transaccion_Minerva  Char(20);
          TR_NUMERO_TRANSACCION Int(10);
          Tipo_Msg_Concur      Packed(3:0);
          ID_Msg_Padre         Int(10);
          ID_Msg_Hijo          Int(10);
          Tipo_Servicio_Minerva Char(2);
          Fecha_Generacion     Timestamp;
          Usuario_Generacion   Char(10);
        end-ds;

       dcl-ds dsCCURCTLENV qualified inz;
          Tipo_Proceso          Char( 1);
          PA_Utilizado          Char(10);
          BA_Utilizado          Char(10);
          OP_Utilizado          Char(10);
          Fecha_Generacion     Timestamp;
          Usuario_Generacion   Char(10);
       end-ds;
      *-------------------------------------------------
      * OPERACIONES FACTURADAS
      *-------------------------------------------------
     IBSSG      NS
     I                             P    9   12 0BNUMES
     I                                 15   15  BCODMO                          -Codigo Operación
     I                                 16   23 0BNUMRE                          -Nº. Real de Socio
     I                             P   24   28 0BNUREF                          -Nº. Descripción
     I                             P   29   33 0BIMPOR                          -Importe
     I                             P   40   44 0BFECON                          -Formato: 0ddmmaaaa
     I                                 56   75  L4
     I                                186  193 0BPROFA                          -Fecha Real Factur.
     I                                200  203 0BAGENC                          -Agencia Concilia.
     I                                204  218  BCRUCE                          -Conci-Nº.BILL./AUT
     I                                219  219  BTIPOP                          -Tipo de Operacion
     I                                440  454  BBIREN                          -Billete REnfe
     I                                469  477 0BNFICM
     I                                493  501 0BREFOR                          -Referencia Origen
     I                                510  529  BNTRMI

      /Free

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

          // ================================
          // BSSG -OPERACIONES FACTURADAS-  
          // ================================
          UNAVEZ = 0;
          SETLL TNREAL BSSG;

          DOW '1';
          READ BSSG;

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

            IF  GESERFEE =  '1';  //Cargo por emision de billete aéreo
              CHAIN TNREAL NFSISGESW;
              IF %FOUND AND NFFEBAJA = 0;
                ITER;
              ENDIF;
            ENDIF;

            IF  GESERFEE =  '2';//Cargo por emision cobrado por la Agencia de V.
              CHAIN TNREAL NFSISGESW;
                IF %FOUND AND NFFEBAJA = 0;
                  ITER;
                ENDIF;
            ENDIF;


            ONFIMI_GUA = ONFIMI;            // Por el clear del SISGESOPE

            //---------------------------------------------------
            //  CARGAR DATOS PARA GRABAR EN SISGESOPE Y SISGESBOL
            //---------------------------------------------------

            CLEAR NUMTRMIN;  // Tambien limpia ONFIMI del OPAGECO  OSISGESW

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

              ENVIO = 'NO';                        //NO  ENVIO FORMATO-401
              CHAIN (BNUMRE:001) TSISGESR;

              IF %FOUND and TCENRE = '1';
                ENVIO = 'SI';                     //SI  ENVIO FORMATO-400/401
              ENDIF;

              //IF ENVIO  = 'SI' AND GETIPRE <> 'RO';
              //   CCURPMCRE(PARAM_PTR);             // Formato: 400/401
              //ENDIF;

              //IF ENVIO  = 'SI' AND GETIPRE = 'RO';
              //   CCURPMCRE(PARAM_PTR);              // Formato: 400/401
              //ENDIF;

              IF ENVIO  = 'NO';
                P_IDFRXXX_P = 0;
                CCURDAOPP(P_IDFRXXX_P:PARAM_PTR);     // Formato: 200
                Graba_Reg_Control(200:P_IDFRXXX_P:0:'  ');
              ENDIF;

              SELECT;
                WHEN GETIPRE = 'RR' AND GESERFEE <> ' ';// Formato: 303 y 304
                  P_IDFRXXX_H1 = 0;
                  P_IDFRXXX_H2 = 0;
                  CCURPMVI1(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                  Graba_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
                  Graba_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
                WHEN GETIPRE = 'RA' AND GESERFEE <> ' '; // Formato: 303 y 304
                  P_IDFRXXX_H1 = 0;
                  P_IDFRXXX_H2 = 0;
                  CCURPMVI2(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                  Graba_Reg_Control(303:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
                  Graba_Reg_Control(304:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
                WHEN GETIPRE = 'RV' AND GESERFEE <> ' '; // Formato: 301
                  P_IDFRXXX_H1 = 0;
                  P_IDFRXXX_H2 = 0;
                  CCURPMAC(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                  Graba_Reg_Control(301:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
                WHEN GETIPRE = 'RH' AND GESERFEE <> ' '; // Formato: 302 y 307
                  P_IDFRXXX_H1 = 0;
                  P_IDFRXXX_H2 = 0;
                  CCURPMHO(P_IDFRXXX_P:P_IDFRXXX_H1:P_IDFRXXX_H2:PARAM_PTR);
                  Graba_Reg_Control(302:P_IDFRXXX_P:P_IDFRXXX_H1:GETIPRE);
                  Graba_Reg_Control(307:P_IDFRXXX_P:P_IDFRXXX_H2:GETIPRE);
              ENDSL;

              WRITE NUMTRMIN;

            ENDIF;

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
            p_Tipo_Servicio_Minerva
                  like(dsCCUROPEENV.Tipo_Servicio_Minerva) const;
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
            VALUES (:dsCCUROPEENV, Default, :WID_Fichero);

          If Sqlcode <> 0;
            observacionSql =
              'Error al grabar en la tabla CONCUR_OPERACIONES_ENVIADAS';
            Clear Nivel_Alerta;
            Nivel_Alerta =
              Diagnostico(Sds.ProgramName:observacionSql);
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
                VALUES (default, :dsCCURCTLENV)
                );

          If Sqlcode <> 0;
            observacionSql =
              'Error al grabar en la tabla CONCUR_Control_Ope_Env';
            Clear Nivel_Alerta;
            Nivel_Alerta =
              Diagnostico(Sds.ProgramName:observacionSql);
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
                VALUES (default, :Wtlabel, default));

          If Sqlcode <> 0;
            observacionSql = 
            'Error al grabar en la tabla CONCUR_Ficheros_Enviados';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
            Return 0;
          Endif;

          Return WID_Gen;
        end-proc;