**FREE
  // ------------------------------------------------------------------------
  // - Modulo CONCUR
  //   Genera fichero CONCUR_OUT a partir de los registros generados en los
  //   Historicos
  // - Autor: Ludolfo Montero
  // - Fecha: Diciembre 2025
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/CCURGENOUT ) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR( CCURGENOUT ) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  *
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
          decedit('0,') datedit(*DMY/) BNDDIR('UTILITIES/UTILITIES')
          dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------


  // --------------------------
  // Cpys y Include
  // --------------------------
  /Copy Explota/Qrpglesrc,CCURCPY
  /copy UTILITIES/QRPGLESRC,P_SDS       // SDS
  /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

  // --------------------------
  // Declaracion Estructuras
  // --------------------------
  Dcl-ds dsCCURFR200T likeds(dsCCURFR200TTpl) Inz;
  Dcl-ds dsCCURFR301T likeds(dsCCURFR301TTpl) Inz;
  Dcl-ds dsCCURFR302T likeds(dsCCURFR302TTpl) Inz;
  Dcl-ds dsCCURFR303T likeds(dsCCURFR303TTpl) Inz;
  Dcl-ds dsCCURFR304T likeds(dsCCURFR304TTpl) Inz;
  Dcl-ds dsCCURFR307T likeds(dsCCURFR307TTpl) Inz;
  Dcl-ds dsCCURFR400T likeds(dsCCURFR400TTpl) Inz;
  Dcl-ds dsCCURFR401T likeds(dsCCURFR401TTpl) Inz;

  Dcl-ds dsCCUROPEENV likeds(dsCCUROPEENVTpl) Inz;
  //Dcl-ds dsSISGESOPE likeds(dsSISGESOPETpl) Inz;
  Dcl-s dsSISGESOPE Char(167) Inz(' ');
  // --------------------------
  // Declaracion de Variables
  // --------------------------
  Dcl-s WId_Fichero Int(10) Inz(0);
  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *none,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

  Exec Sql declare  C_Pen_IDFichero Cursor For
    Select
      ID_Control, NUREAL, Num_Agencia_Minerva, FICHERO_MINERVA,
      Transaccion_Minerva, TR_NUMERO_TRANSACCION, Tipo_Msg_Concur,
      ID_Msg_Padre, ID_Msg_Hijo, Tipo_Servicio_Minerva,
      Fecha_Generacion, Usuario_Generacion
    From CONCUR_OPERACIONES_ENVIADAS
    Where
      Fecha_Concur_Out = '0001-01-01 00:00:00.000000'
      AND ID_Fichero = :WId_Fichero
    Order By ID_msg_padre, id_msg_hijo;

  Exec Sql declare  C_Pen_All Cursor For
    Select
      ID_Control, NUREAL, Num_Agencia_Minerva, FICHERO_MINERVA,
      Transaccion_Minerva, TR_NUMERO_TRANSACCION, Tipo_Msg_Concur,
      ID_Msg_Padre, ID_Msg_Hijo, Tipo_Servicio_Minerva,
      Fecha_Generacion, Usuario_Generacion
    From CONCUR_OPERACIONES_ENVIADAS
    Where
      Fecha_Concur_Out = '0001-01-01 00:00:00.000000'
      and ID_CONTROL = 3
    Order By ID_msg_padre, id_msg_hijo;

  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    dcl-pi *n;
      P_IDFichero   Int(10);
    end-pi;

    Dcl-s WCen_Reconc Char( 1);
    Dcl-s Reg_Concur Char(2000);

    WId_Fichero = P_IDFichero;
    If WId_Fichero <> 0;
      // Lectura de un unico fichero
      Arma_CONCUR_OUT_IDFichero();
    Else;
      // Lectura de registros pendientes de todos los ficheros
      Arma_CONCUR_OUT_Pendiente();
    EndIf;
  end-proc;

  // ****************************************************************************
  // Arma CONCUR_OUT con registros Pendientes
  // ****************************************************************************
  dcl-proc Arma_CONCUR_OUT_Pendiente;

    dcl-pi Arma_CONCUR_OUT_Pendiente;
      //P_IDFichero   Int(10);
    end-pi;

    Dcl-s WCen_Reconc Char( 1);
    Dcl-s Reg_Concur Char(2000);

    Exec Sql Open  C_Pen_All;
    sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_Pen_All into :dsCCUROPEENV;
      If sqlStt <> '00000';
        Leave;
      EndIf;

      Determina_Tipo_Registro();

    EndDo;

  end-proc;
  // ****************************************************************************
  // Arma CONCUR_OUT con registros Pendientes de un ID_Fichero
  // ****************************************************************************
  dcl-proc Arma_CONCUR_OUT_IDFichero;

    dcl-pi Arma_CONCUR_OUT_IDFichero;

    end-pi;

    Dcl-s WCen_Reconc Char( 1);
    Dcl-s Reg_Concur Char(2000);

    Exec Sql Open  C_Pen_IDFichero;
    sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_Pen_IDFichero into :dsCCUROPEENV;
      If sqlStt <> '00000';
        Leave;
      EndIf;

      Determina_Tipo_Registro();

    EndDo;

  end-proc;
  // ****************************************************************************
  // Genera Registro tipo 200
  // ****************************************************************************
  dcl-proc Determina_Tipo_Registro;

    dcl-pi Determina_Tipo_Registro;

    end-pi;

    Select;
      When dsCCUROPEENV.TIPO_MSG_CONCUR = 200;
        If Not Genera_Reg_CONCUR_OUT_200();// Formato: 200
          //Iter;
        EndIf;

      When dsCCUROPEENV.TIPO_MSG_CONCUR = 400;
        If Not Genera_Reg_CONCUR_OUT_400();   // Formato: 400
          //Iter;
        EndIf;

      When dsCCUROPEENV.TIPO_MSG_CONCUR = 401;
        If Not Genera_Reg_CONCUR_OUT_401();   // Formato: 401
          //Iter;
        EndIf;

      When dsCCUROPEENV.TIPO_MSG_CONCUR = 301;
        If Not Genera_Reg_CONCUR_OUT_301();   // Formato: 301
          //Iter;
        EndIf;

      When dsCCUROPEENV.TIPO_MSG_CONCUR = 302;
        If Not Genera_Reg_CONCUR_OUT_302();   // Formato: 302
          //Iter;
        EndIf;

      When dsCCUROPEENV.TIPO_MSG_CONCUR = 303;
        If Not Genera_Reg_CONCUR_OUT_303();   // Formato: 303
          //Iter;
        EndIf;

      When dsCCUROPEENV.TIPO_MSG_CONCUR = 304;
        If Not Genera_Reg_CONCUR_OUT_304();   // Formato: 304
          //Iter;
        EndIf;

      //When dsCCUROPEENV.TIPO_MSG_CONCUR = 305;
        //If Not Genera_Reg_CONCUR_OUT_305();   // Formato: 305
          //Iter;
        //EndIf;

      // When dsCCUROPEENV.TIPO_MSG_CONCUR = 306;
      //   If Not Genera_Reg_CONCUR_OUT_306();   // Formato: 306
      //     //Iter;
      //   EndIf;

      When dsCCUROPEENV.TIPO_MSG_CONCUR = 307;
        If Not Genera_Reg_CONCUR_OUT_307();   // Formato: 307
          //Iter;
        EndIf;

    EndSl;

  end-proc;
  // ****************************************************************************
  // Genera Registro tipo 200
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_200;

    dcl-pi Genera_Reg_CONCUR_OUT_200 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F200IDR,           // F200IDR  IDENTIF.REGISTRO-200 */
        F200CCN,           // F200CCN  NUMERO TARJETA       */
        F200TRN,           // F200TRN  Nº.REFERENCIA OPERAC */
        F200TDA,           // F200TDA  FECHA CONSUMO        */
        F200PDA,           // F200PDA  FECHA ENTRADA DINERS */
        F200FTI,           // F200FTI  COD.ISO MONED.ORIGIN */
        F200IMO,           // F200IMO  IMPORTE MONED.ORIGIN */
        F200ITF,           // F200ITF  COD.ISO MONED.FACTUR */
        F200IMF,           // F200IMF  IMPORTE MONED.FACTUR */
        F200MNA,           // F200MNA  NOMBRE      COMERCIO */
        F200MCC,           // F200MCC  ACT.ISO MCC COMERCIO */
        F200MCI,           // F200MCI  LOCALIDAD   COMERCIO */
        F200MSP,           // F200MSP  PROVINCIA   COMERCIO */
        F200MPC,           // F200MPC  COD.POSTAL  COMERCIO */
        F200IMC,           // F200IMC  CO.ISO PAIS COMERCIO */
        F200ITT,           // F200ITT  IMPORTE TASAS TOTAL  */
        F200ITL,           // F200ITL  IMPORTE TASAS LOCAL  */
        F200ITG,           // F200ITG  IMPORTE TASAS GOODS  */
        F200ITS,           // F200ITS  IMPORTE TASAS SALES  */
        F200ITO,           // F200ITO  IMPORTE TASAS OTHER  */
        F200MRN,           // F200MRN  Nº.COMERCIO + DIGITO */
        F200MTN,           // F200MTN  CIF COMERCIO  -PV-   */
        F200CTN,           // F200CTN  CIF EMPRESA          */
        F200VDI,           // F200VDI  INDICADOR DE IVA     */
        F200BTY,           // F200BTY  TIPO FACTURACION     */
        F200TDE,           // F200TDE  DESCRIPCION TRANSAC. */
        F200C01,           // F200C01  REFERENCIA-1 CLIENTE */
        F200C02,           // F200C02  REFERENCIA-2 CLIENTE */
        F200C03,           // F200C03  REFERENCIA-3 CLIENTE */
        F200C04,           // F200C04  REFERENCIA-4 CLIENTE */
        F200C05,           // F200C05  REFERENCIA-5 CLIENTE */
        F200A01,           // F200A01  REFERENCIA-1 CUENTA  */
        F200A02,           // F200A02  REFERENCIA-2 CUENTA  */
        F200A03,           // F200A03  REFERENCIA-3 CUENTA  */
        F200A04,           // F200A04  REFERENCIA-4 CUENTA  */
        F200A05,           // F200A05  REFERENCIA-5 CUENTA  */
        F200EID,           // F200EID  REF. IDENT.EMPLEADO  */
        F200LIB,           // F200LIB  RESERVADO - LIBRE    */
        F200_SISGESOPE     // SISGESOPE                     */
      Into :dsCCURFR200T, :dsSISGESOPE
      FROM FICHEROS.CCURFR200T
      Where ID_F200 = :dsCCUROPEENV.ID_Msg_Padre;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFR200T';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR200T
    //------------------------------------------
    WConcurOut = dsCCURFR200T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;
  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 400
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_400;

    dcl-pi Genera_Reg_CONCUR_OUT_400 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F400IDR,           // IDENTIF.REGISTRO-400 */
        F400VVI,           // VENDOR IDENTIFIER    */
        F400VVN,           // VENDOR NAME          */
        F400IAN,           // INVOICE ACCO. NUMBER */
        F400ACN,           // INVOICE ACCO. NAME   */
        F400LIB,           // RESERVADO - LIBRE    */
        F400_SISGESOPE     // Datos del SISGESOPE  */
      Into :dsCCURFR400T, :dsSISGESOPE
      FROM FICHEROS.CCURFR400T
      Where ID_F400 = :dsCCUROPEENV.ID_Msg_Padre;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFR400T';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR400T
    //------------------------------------------
    WConcurOut = dsCCURFR400T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;

  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 401
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_401;

    dcl-pi Genera_Reg_CONCUR_OUT_401 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F401IDR,           // IDENTIF.REGISTRO-401 */
        F401IAN,           // INVOICE ACCO. NUMBER */
        F401SID,           // STATERMENT IDENTIFIE */
        F401REN,           // REFERENCE NUMBER     */
        F401INU,           // INVOICE NUMBER       */
        F401IDA,           // INVOICE DATE         */
        F401ITY,           // INVOICE TYPE         */
        F401RIN,           // RELATED INVOI.NUMBER */
        F401FTR,           // TRANSACTION DATE     */
        F401TAI,           // ORI.TRANS.AMOUNT ISO */
        F401OTA,           // ORI.TRANS. AMOUNT    */
        F401PBA,           // POSTED AMOUNT ISO    */
        F401PAM,           // POSTED AMOUNT        */
        F401MNA,           // MERCHANT NAME        */
        F401MCO,           // MERCHANT CODE (MCC)  */
        F401MCI,           // MERCHANT CITY        */
        F401MPO,           // MERCHANT PROVINCE    */
        F401MPC,           // MERCHANT POSTAL CODE */
        F401MCU,           // MERCHANT COUNTRY     */
        F401TAA,           // TAX AMOUNT  IVA      */
        F401LTA,           // TAX AMOUNT  IVA LOCA */
        F401VAT,           // VALUE ADDED TAX AMOU */
        F401STA,           // SALES TAX AMOUNT     */
        F401OAM,           // OTHER TAX AMOUNT     */
        F401MTN,           // MERCHANT TAX NUMBER  */
        F401CTN,           // CUSTOMER TAX NUMBER  */
        F401VDI,           // VAT DATE UBDUCATIR   */
        F401TRD,           // TRANSACI.DESCRIPCION */
        F401VFI,           // VISA FEE INDICATOR   */
        F401VTI,           // VISA TYPE            */
        F401VTD,           // VISA TYPE DESCRIPCIO */
        F401VDC,           // VISA DESTINA.COUNTRY */
        F401VSC,           // VISA SERV.CHARGE ISO */
        F401VCH,           // VISA SERV.CHARGE     */
        F401BSH,           // BILLED SERVI.CHARGE  */
        F401PSC,           // POSTED SERVI.CHARGE  */
        F401OCD,           // OTHER CHARGE DESCRIP */
        F401OCI,           // OTHER CHANGE ISO     */
        F401OOC,           // ORIGIN.OTHER CHANGE  */
        F401POC,           // BILLED O.CHANGE ISO  */
        F401PCH,           // POSTED OTHER CHANGE  */
        F401CF1,           // CUSTOM FIED 1 -REF-1 */
        F401CF2,           // CUSTOM FIED 2 -REF-2 */
        F401CF3,           // CUSTOM FIED 3 -REF-3 */
        F401CF4,           // CUSTOM FIED 4 -REF-4 */
        F401CF5,           // CUSTOM FIED 5 -REF-5 */
        F401CF6,           // CUSTOM FIED 6 -REF-6 */
        F401CF7,           // CUSTOM FIED 7 -REF-7 */
        F401CF8,           // CUSTOM FIED 8 -REF-8 */
        F401CF9,           // CUSTOM FIED 9 -REF-9 */
        F401C10,           // CUSTOM FIED10 -REF10 */
        F401LIB,           // RESERVADO - LIBRE    */
        F401_SISGESOPE     // SISGESOPE            */
      Into :dsCCURFR401T, :dsSISGESOPE
      FROM FICHEROS.CCURFR401T
      Where ID_F401 = :dsCCUROPEENV.ID_Msg_Hijo;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFR401T';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR401T
    //------------------------------------------
    WConcurOut = dsCCURFR401T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;

  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 301
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_301;

    dcl-pi Genera_Reg_CONCUR_OUT_301 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F301IDR,           // IDENTIF.REGISTRO-301 */
        F301TRN,           // Nº.REFERENCIA OPERAC */
        F301RAN,           // NUMERO CONTRATO      */
        F301RNA,           // NOMBRE AGENCIA       */
        F301PDA,           // FECHA  RECOGIDA VEH. */
        F301PPI,           // ID.AG. RECOGIDA VEH. */
        F301PCI,           // CIUDAD RECOGIDA VEH. */
        F301PSP,           // PROVIN.RECOGIDA VEH. */
        F301PCO,           // PAIS   RECOGIDA VEH. */
        F301RDA,           // FECHA  DEVOLUC. VEH. */
        F301RPI,           // ID.AG. DEVOLUC. VEH. */
        F301RCI,           // CIUDAD DEVOLUC. VEH. */
        F301RSP,           // PROVIN.DEVOLUC. VEH. */
        F301RCO,           // PAIS   DEVOLUC. VEH. */
        F301NSF,           // FLAG: NO SE PRESENTA */
        F301ADU,           // IMPORTE POR DISTANC. */
        F301DRE,           // IMPORTE POR DIA      */
        F301WRA,           // IMPORTE POR SEMANA   */
        F301VCC,           // CODIGO CLASE VEHIC.  */
        F301NVE,           // NUMERO DE VEHICULO   */
        F301TDI,           // DIS.TOTAL,TOT.PERIOD */
        F301RDC,           // IMPORTE DISTAN.RECOR */
        F301EDR,           // IMPORTE DISTAN.EXTRA */
        F301OWD,           // IMPORTE DEV.DIST.LOC */
        F301LCH,           // IMPORTE RETRASO DEV. */
        F301FCH,           // IMPORTE CARBURANTE   */
        F301ICH,           // IMPORTE SEGURO       */
        F301OCH,           // IMPORTE OTROS        */
        F301AAM,           // IMPORTE AJUSTES      */
        F301ECC,           // CODIGO CARGOS EXTRAS */
        F301ECA,           // IMPORT.TOT.CARG.EXTR */
        F301RED,           // DIAS DE ALQUILER     */
        F301MFD,           // DIST.TOT.PERM.ANT.EX */
        F301CCO,           // CODIGO MERCANCIA     */
        F301C01,           // REFERENCIA-1 CLIENTE */
        F301C02,           // REFERENCIA-2 CLIENTE */
        F301C03,           // REFERENCIA-3 CLIENTE */
        F301C04,           // REFERENCIA-4 CLIENTE */
        F301C05,           // REFERENCIA-5 CLIENTE */
        F301LIB,           // RESERVADO - LIBRE    */
        F301_SISGESOPE     // SISGESOPE            */
      Into :dsCCURFR301T, :dsSISGESOPE
      FROM FICHEROS.CCURFR301T
      Where
        ID_F301 = :dsCCUROPEENV.ID_Msg_Hijo;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFRT301';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR301T
    //------------------------------------------
    WConcurOut = dsCCURFR301T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;

  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 302
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_302;

    dcl-pi Genera_Reg_CONCUR_OUT_302 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F302IDR,           // IDENTIF.REGISTRO-302 */
        F302TRN,           // Nº.REFERENCIA OPERAC */
        F302LPI,           // Nº.IDENTIF. COMERCIO */
        F302PTN,           // Nº.TELEFONO COMERCIO */
        F302LCI,           // CIUDAD      COMERCIO */
        F302COD,           // FECHA SALIDA         */
        F302CID,           // FECHA LLEGADA        */
        F302RRN,           // COSTE POR NOCHE      */
        F302PHO,           // IMPORTE USO TFNO.    */
        F302GSA,           // IMPORTE TIEND.REGAL. */
        F302BAR,           // IMPORTE BAR/MINI BAR */
        F302CLA,           // IMPORTE LAVANDERIA   */
        F302FNU,           // NUMERO RESERVA       */
        F302NON,           // NUMERO TOTAL NOCHES  */
        F302DRT,           // IMPORT.TASAS POR DIA */
        F302FCH,           // IMPORT.COMIDA/BEBIDA */
        F302PCH,           // IMPORTE PARKING      */
        F302MCH,           // IMPORTE PELICULAS    */
        F302TCH,           // IMPORTE PROPINA      */
        F302OCH,           // IMPORTE OTROS        */
        F302TAC,           // DESCRIP.TIPO PROPINA */
        F302GNA,           // NOMBRE ACOMPAÑANTE   */
        F302NIP,           // Nº.INVITADOS EN HAB. */
        F302RTY,           // TIPO HABITACION      */
        F302NRO,           // Nº.HABIT.RESERVADAS  */
        F302PAM,           // IMPORTE RESERVA      */
        F302TRT,           // IMPORTE TOTAL TASAS  */
        F302AAM,           // IMPORTE DE AJUSTES   */
        F302TLA,           // IMPORTE TOT.ESTANCIA */
        F302TNR,           // IMPORTE AJENOS HABIT */
        F302CCO,           // CODIGO MERCANCIA     */
        F302PCO,           // CODIGO PROGRAMA      */
        F302OSC,           // CODIGO OTROS SERVIC. */
        F302MON,           // NUMERO ORDEN RESERVA */
        F302LSA,           // PROVINCIA            */
        F302LPC,           // CODIGO POSTAL        */
        F302LRE,           // REGION               */
        F302LCO,           // PAIS                 */
        F302C01,           // REFERENCIA-1 CLIENTE */
        F302C02,           // REFERENCIA-2 CLIENTE */
        F302C03,           // REFERENCIA-3 CLIENTE */
        F302C04,           // REFERENCIA-4 CLIENTE */
        F302C05,           // REFERENCIA-5 CLIENTE */
        F302LIB,           // RESERVADO - LIBRE    */
        F302_SISGESOPE     // SISGESOPE            */
      Into :dsCCURFR302T, :dsSISGESOPE
      FROM FICHEROS.CCURFR302T
      Where
        ID_F302 = :dsCCUROPEENV.ID_Msg_Hijo;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFR302T';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR302T
    //------------------------------------------
    WConcurOut = dsCCURFR302T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;

  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 303
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_303;

    dcl-pi Genera_Reg_CONCUR_OUT_303 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F303IDR,           // IDENTIF.REGISTRO-303 */
        F303TRN,           // Nº.REFERENCIA OPERAC */
        F303TNU,           // NUMERO BILLETE       */
        F303PNA,           // NOMBRE PASAJERO      */
        F303TAC,           // CODIGO AG.VIAJ.IATA  */
        F303TAN,           // NOMBRE AGENC.VIAJES  */
        F303DDA,           // FECHA SALIDA SEGTO-1 */
        F303NLE,           // NUMERO DE SEGMENTOS  */
        F303RFL,           // INDICADOR RESTRICC.  */
        F303IDA,           // FECHA EMISION        */
        F303ICA,           // ABREV.LLAA QUE VUELA */
        F303CDA,           // DATO DEFINIDO CLIENT */
        F303BFA,           // TARIFA BASE          */
        F303TFA,           // IMPORTE TOTAL BILLET */
        F303TFE,           // IMPORTE TOTAL GASTOS */
        F303ETF,           // INDICADOR CAMBIO     */
        F303CID,           // ID.POR MAS DE 4 SEG. */
        F303RTN,           // Nº.BILLETE REEMBOLSO */
        F303ETN,           // Nº.BILLETE  CAMBIADO */
        F303ETA,           // IMP.TOT.BIL.CAMBIADO */
        F303CCO,           // CODIGO MERCANCIA     */
        F303C01,           // REFERENCIA-1 CLIENTE */
        F303C02,           // REFERENCIA-2 CLIENTE */
        F303C03,           // REFERENCIA-3 CLIENTE */
        F303C04,           // REFERENCIA-4 CLIENTE */
        F303C05,           // REFERENCIA-5 CLIENTE */
        F303LIB,           // RESERVADO - LIBRE    */
        F303_SISGESOPE     // */
      Into :dsCCURFR303T, :dsSISGESOPE
      FROM FICHEROS.CCURFR303T
      Where
        ID_F303 = :dsCCUROPEENV.ID_Msg_Hijo;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFR303T';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR303T
    //------------------------------------------
    WConcurOut = dsCCURFR303T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;

  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 304
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_304;

    dcl-pi Genera_Reg_CONCUR_OUT_304 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F304IDR,           // IDENTIF.REGISTRO-304 */
        F304TRN,           // Nº.REFERENCIA OPERAC */
        F304TLN,           // NUMERO DEL SEGMENTO  */
        F304CCO,           // CODIGO ABREV. LLAA   */
        F304CSC,           // CLASE O COD.SERVICIO */
        F304DLO,           // COD/LOCALIDAD SALIDA */
        F304ALO,           // COD/LOCALIDAD LLEGAD */
        F304FNU,           // NUMERO DE VUELO      */
        F304DDA,           // FECHA SALIDA         */
        F304ADA,           // FECHA LLEGADA        */
        F304FDF,           // IND.SALIDA EXTRANJER */
        F304DCO,           // PAIS SALIDA          */
        F304OFL,           // IND. DE SEGMENTO-1   */
        F304FAF,           // IND.LLEGADA EXTRANJE */
        F304ACO,           // PAIS LLEGADA         */
        F304DFL,           // IND. SEGMENTO FINAL  */
        F304FAR,           // IMP.DE ESTE SEGMENTO */
        F304FEE,           // IMP.GTOS    SEGMENTO */
        F304CTN,           // Nº.BILL.CONCATENADO  */
        F304ETN,           // Nº.BILLETE CAMBIADO  */
        F304C01,           // REFERENCIA-1 CLIENTE */
        F304C02,           // REFERENCIA-2 CLIENTE */
        F304C03,           // REFERENCIA-3 CLIENTE */
        F304C04,           // REFERENCIA-4 CLIENTE */
        F304C05,           // REFERENCIA-5 CLIENTE */
        F304LIB,           // RESERVADO - LIBRE    */
        F304_SISGESOPE     // SISGESOPE            */
      Into :dsCCURFR304T, :dsSISGESOPE
      FROM FICHEROS.CCURFR304T
      Where
        ID_F304 = :dsCCUROPEENV.ID_Msg_Hijo;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFR304T';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR304T
    //------------------------------------------
    WConcurOut = dsCCURFR304T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;

  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 305
  // ****************************************************************************
  // dcl-proc Genera_Reg_CONCUR_OUT_305;

  //   dcl-pi Genera_Reg_CONCUR_OUT_305 Ind;

  //   end-pi;

  //   Dcl-s WConcurOut Char(2580) Inz(' ');

  //   Exec SQL
  //     SELECT
  //       F305IDR,           // IDENTIF.REGISTRO-305 */
  //       F305TRN,           // Nº.REFERENCIA OPERAC */
  //       F305ODA,           // FECHA PETICION COMPR */
  //       F305PDA,           // FECHA EFECTIVA COMPR */
  //       F305DCI,           // CIUDAD     DESTINO   */
  //       F305DST,           // PROVINCIA  DESTINO   */
  //       F305SPC,           // COD.POSTAL DESTINO   */
  //       F305SST,           // PROVINCIA  PROVEEDOR */
  //       F305PCO,           // CODIGO PRODUCTO      */
  //       F305MON,           // NUMERO PEDIDO        */
  //       F305DES,           // DESCRIPCION COMPRA   */
  //       F305INU,           // NUMERO FACTURA       */
  //       F305CCO,           // CODIGO MERCANCIA     */
  //       F305DIA,           // IMPORTE DESCUENTOS   */
  //       F305SHA,           // IMPORTE A LA ENTREGA */
  //       F305DUA,           // IMPORTE TOT.IMPUESTO */
  //       F305SFP,           // COD.POS.SALIDA COMPR */
  //       F305STP,           // COD.POS.DESTIN.COMPR */
  //       F305STC,           // C. PAIS DESTIN.COMPR */
  //       F305NLI,           // NUMERO DE PAQUETES   */
  //       F305VAT,           // IMPORTE IVA DESTINO  */
  //       F305C01,           // REFERENCIA-1 CLIENTE */
  //       F305C02,           // REFERENCIA-2 CLIENTE */
  //       F305C03,           // REFERENCIA-3 CLIENTE */
  //       F305C04,           // REFERENCIA-4 CLIENTE */
  //       F305C05,           // REFERENCIA-5 CLIENTE */
  //       F305C06,           // REFERENCIA-6 CLIENTE */
  //       F305C07,           // REFERENCIA-7 CLIENTE */
  //       F305C08,           // REFERENCIA-8 CLIENTE */
  //       F305C09,           // REFERENCIA-9 CLIENTE */
  //       F305C10,           // REFERENCIA-10CLIENTE */
  //       F305LIB,           // RESERVADO - LIBRE    */
  //       F305_SISGESOPE     // SISGESOPE            */
  //     Into :dsCCURFR305T, :dsSISGESOPE
  //     FROM FICHEROS.CCURFR305T
  //     Where
  //       ID_F305 = :dsCCUROPEENV.ID_Msg_Padre;

  //   If Sqlcode <> 0;
  //     observacionSql = 'Error en lectura de la tabla CCURFR305T';
  //     Clear Nivel_Alerta;
  //     Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
  //     Return *Off;
  //   Endif;

  //   // Graba registro en el historico CCURFR305T
  //   //------------------------------------------
  //   WConcurOut = dsCCURFR305T;
  //   %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

  //   If Not Graba_Reg_CONCUR_OUT(WConcurOut);
  //     Return *Off;
  //   EndIf;

  //   Return *On;

  // End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 306
  // ****************************************************************************
  // dcl-proc Genera_Reg_CONCUR_OUT_306;

  //   dcl-pi Genera_Reg_CONCUR_OUT_306 Ind;

  //   end-pi;

  //   Dcl-s WConcurOut Char(2580) Inz(' ');

  //   Exec SQL
  //     SELECT
  //       F306IDR,           // IDENTIF.REGISTRO-306 */
  //       F306TRN,           // Nº.REFERENCIA OPERAC */
  //       F306IID,           // IDENTIF. ELEMENTO    */
  //       F306IQU,           // CANTIDAD ELEMENTOS   */
  //       F306UMC,           // CODIGO UNIDAD MEDIDA */
  //       F306UAM,           // IMPORTE POR UNIDAD   */
  //       F306DAM,           // IMPORTE DCTOS.APLIC. */
  //       F306EAM,           // IMPORTE AMPLIADO     */
  //       F306LIT,           // IMPORTE TOT.ELEMENTO */
  //       F306NET,           // INDICADOR IMPUESTOS  */
  //       F306DFL,           // INDICADOR DESCUENTOS */
  //       F306SFP,           // COD.POS.ENVIO ELEMEN */
  //       F306STP,           // COD.POS.DESTI.ELEMEN */
  //       F306CCO,           // CODIGO MERCANCIA     */
  //       F306CCE,           // COD.MERCANCIA AMPLIA */
  //       F306DSN,           // Nº.SECUENCIA ELEMENT */
  //       F306C01,           // REFERENCIA-1 CLIENTE */
  //       F306C02,           // REFERENCIA-2 CLIENTE */
  //       F306C03,           // REFERENCIA-3 CLIENTE */
  //       F306C04,           // REFERENCIA-4 CLIENTE */
  //       F306C05,           // REFERENCIA-5 CLIENTE */
  //       F306C06,           // REFERENCIA-6 CLIENTE */
  //       F306C07,           // REFERENCIA-7 CLIENTE */
  //       F306C08,           // REFERENCIA-8 CLIENTE */
  //       F306C09,           // REFERENCIA-9 CLIENTE */
  //       F306C10,           // REFERENCIA-10CLIENTE */
  //       F306LIB,           // RESERVADO - LIBRE    */
  //       F306_SISGESOPE     // SISGESOPE            */
  //     Into :dsCCURFR306T, :dsSISGESOPE
  //     FROM FICHEROS.CCURFR306T
  //     Where
  //       ID_F306 = :dsCCUROPEENV.ID_Msg_Padre;

  //   If Sqlcode <> 0;
  //     observacionSql = 'Error en lectura de la tabla CCURFR306T';
  //     Clear Nivel_Alerta;
  //     Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
  //     Return *Off;
  //   Endif;

  //   // Graba registro en el historico CCURFR306T
  //   //------------------------------------------
  //   WConcurOut = dsCCURFR306T;
  //   %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

  //   If Not Graba_Reg_CONCUR_OUT(WConcurOut);
  //     Return *Off;
  //   EndIf;

  //   Return *On;

  // End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 307
  // ****************************************************************************
  dcl-proc Genera_Reg_CONCUR_OUT_307;

    dcl-pi Genera_Reg_CONCUR_OUT_307 Ind;

    end-pi;

    Dcl-s WConcurOut Char(2580) Inz(' ');

    Exec SQL
      SELECT
        F307IDR,           // IDENTIF.REGISTRO-307 */
        F307TRN,           // Nº.REFERENCIA OPERAC */
        F307ISN,           // Nº.SECUENCIA SERVIC. */
        F307TDA,           // FECHA OPERACION      */
        F307PDA,           // FECHA CARGO EN CTA.  */
        F307TAM,           // IMPORTE OPERACION    */
        F307ITY,           // TIPO SERVICIO        */
        F307IDE,           // DESCRIPCION SERVICIO */
        F307LIB,           // RESERVADO - LIBRE    */
        F307_SISGESOPE     // SISGESOPE            */
      Into :dsCCURFR307T, :dsSISGESOPE
      FROM FICHEROS.CCURFR307T
      Where
        ID_F307 = :dsCCUROPEENV.ID_Msg_Hijo;

    If Sqlcode <> 0;
      observacionSql = 'Error en lectura de la tabla CCURFR307T';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    // Graba registro en el historico CCURFR307T
    //------------------------------------------
    WConcurOut = dsCCURFR200T;
    %subst(WConcurOut : 2414 : 167) = dsSISGESOPE;

    If Not Graba_Reg_CONCUR_OUT(WConcurOut);
      Return *Off;
    EndIf;

    Return *On;

  End-Proc;
  // ****************************************************************************
  // Graba Registro en el CONCUR_OUT
  // ****************************************************************************
  dcl-proc Graba_Reg_CONCUR_OUT;
    dcl-pi Graba_Reg_CONCUR_OUT Ind;
      P_Registro   Char(2580);
    end-pi;

    // Graba registro
    //------------------------------------------
    Exec SQL
      INSERT INTO CONCUR_OUT
      VALUES
        (:P_Registro);

    If Sqlcode <> 0;
      observacionSql = 'Error al grabar en la tabla CONCUR_OUT';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
      Return *Off;
    Endif;

    Return *On;
  End-Proc;