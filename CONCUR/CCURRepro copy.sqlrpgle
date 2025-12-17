**FREE
  // ------------------------------------------------------------------------
  // - Modulo CONCUR
  //   Segun registros een un TRANSAC temporal genera fichero con operaciones
  //   para CONCUR
  // - Autor: Ludolfo Montero
  // - Fecha: Noviembre 2025
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/ CONTAB100 ) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR( CONTAB100 ) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  * Ejecuta la función para Copiar ficheros necesarios en el Paralelo
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
          decedit('0,') datedit(*DMY/)
          dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------


  // --------------------------
  // Cpys y Include
  // --------------------------
  /Copy Explota/Qrpglesrc,CCURCPY  

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

  Dcl-ds dsT_MSOCIO likeds(dsT_MSOCIOTPL) Inz;
  Dcl-ds dsTRANSAC likeds(dsTRANSACTpl) Inz;
  Dcl-ds dsESTA1 likeds(dsESTA1Tpl) Inz;
  Dcl-ds dsINDEPROV likeds(dsINDEPROVTpl) Inz;
  Dcl-ds dsTABACTI likeds(dsTABACTITpl) Inz;
  Dcl-ds dsSGCCURTV likeds(dsSGCCURTVTpl) Inz;
  Dcl-ds dsSGCCURIM likeds(dsSGCCURIMTpl) Inz;
  Dcl-ds dsSGCCURMCC likeds(dsSGCCURMCCTpl) Inz;
  Dcl-ds dsPAISESISOL likeds(dsPAISESISOLTpl) Inz;
  Dcl-ds dsSISGESOPE likeds(dsSISGESOPETpl) Inz;
  Dcl-ds dsSISGESTAR likeds(dsSISGESTARTpl) Inz;
  Dcl-ds dsLINAEREA likeds(dsLINAEREATpl) Inz;
  Dcl-ds dsIATA likeds(dsIATATpl) Inz;
  Dcl-ds dsCIUDAD likeds(dsCIUDADTpl) Inz;

  // --------------------------
  // Declaracion de Variables
  // --------------------------
  dcl-s WID_Transac Zoned(10);
  Dcl-s WNUMREAL Zoned(8);
  Dcl-s WNUMEST Zoned(7);
  Dcl-S TASAS Packed(15:2);
  Dcl-s WES_Ferrovial ind;
  Dcl-s WES_REPSOL ind;
  Dcl-s WINDRA ind;
  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *none,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

  Exec Sql declare  C_Transac Cursor For
    Select ID_TRANSAC
    From CONCUR_TRANSACCIONES_PENDIENTES_PROCESAR
    Where   
      Estatus = ' ';

  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    dcl-pi *n;
      //P_NomProc   Char(10);
    end-pi;

    Dcl-s WCen_Reconc Char( 1);
    Dcl-s Reg_Concur Char(2000);
     
    Exec Sql Open  C_Transac;
    sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_Transac into :WID_Transac;
      If sqlStt <> '00000';
        Leave;
      EndIf;

      Exec Sql
        Select * 
          Into :dsTRANSAC
        From Atrium.Transac
        Where
          TR_NUMEdsTRANSAC.GETRANSACCION = :WID_Transac
      ;

      Monitor;
        WNUMREAL = %Dec(%SubSt(%Editc(dsTRANSAC.GENUMTAR:'X'):8:8):8:0);
      on-error;
        Iter;
      endmon;  

      Exec Sql
        Select *
          Into :dsT_MSOCIO
        From T_MSOCIO
        Where
          NUREAL = :WNUMREAL
      ;
      If SQLCODE = 100;
        Iter;
      EndIf;

      Exec Sql
        Select *
          Into :dsSISGESTAR
        From SISGESTAR
        Where
          TFBASG = 0
          AND TCODSG = 1
          AND TNREAL = :WNUMREAL
      ;
      Monitor;
        WNUMEST =
          %Dec(%SubSt(%Editc(dsTRANSAC.GENUCOFA:'X'):1:7):7:0);
      on-error;
        WNUMEST = 0;
      endmon;

      Exec Sql 
        Select * 
        Into :dsESTA1
        From ESTA1 
        Where NUMEST = :WNUMEST;

      Exec Sql 
        Select * 
        Into :dsINDEPROV
        From INDEPROV 
        Where PNUPRO = :dsESTA1.EPROPV;

        // Datos comunes para el CONCUR_OUT
        Genera_DatosComunes_SISGESOPE();

      IF dsSISGESTAR.TCENRE = '1'; 
        Genera_RegistdsTRANSAC.GE400();   // Formato: 400
      Else;
        Genera_RegistdsTRANSAC.GE200();   // Formato: 200
      ENDIF;

      SELECT;
        WHEN dsTRANSAC.GETIPRE = 'RR' // FERROCARRILES
             AND dsTRANSAC.GESERFEE <> ' ';  // Formato: 303 y 304
          Genera_Registros_RR_303_304();
        WHEN dsTRANSAC.GETIPRE = 'RA' // LINEAS AEREAS
             AND dsTRANSAC.GESERFEE <> ' ';    // Formato: 303 y 304
          Genera_Registros_RA_303_304();
        WHEN dsTRANSAC.GETIPRE = 'RV' // ALQUILER COCHES
             AND dsTRANSAC.GESERFEE <> ' ';    // Formato: 301
          Genera_Registros_RV_301();
        WHEN dsTRANSAC.GETIPRE = 'RH' // HOTELES
             AND dsTRANSAC.GESERFEE <> ' ';    // Formato: 302 y 307
          //Reg_Concur = Genera_RegistdsTRANSAC.GE302_307();
      ENDSL;

    EndDo;  

  end-proc;
  // ****************************************************************************
  // Genera Registro tipo 200
  // ****************************************************************************
  dcl-proc Genera_RegistdsTRANSAC.GE200;
    dcl-pi Genera_RegistdsTRANSAC.GE200;

    end-pi;

    Dcl-s TASAX  packed(15:2);
    reset dsCCURFR200T;

    dsCCURFR200T.F200IDR = 200;

    dsCCURFR200T.F200CCN = %SubSt(%Editc(dsTRANSAC.GENUMTAR:'X'):6:10) + '9999';

    // Nº Referencia Operación
    //-----------------------------
    dsCCURFR200T.F200TRN = 
        %EDITC(*DATE:'X') + 
        %EDITC(WNUMREAL:'X') + 
        dsTRANSAC.GENUTRAN;

    // Fecha Consumo
    //-----------------------------
    dsCCURFR200T.F200TDA = dsTRANSAC.GEFECOMP;

    // Fecha Entrada Diners
    //-----------------------------
    dsCCURFR200T.F200PDA = dsTRANSAC.GEFEINSE;      // OJOOOOOO

    // Codigo ISO Moneda Origen
    //-----------------------------
    dsCCURFR200T.F200FTI = %Editc(dsTRANSAC.GEISOMON:'X');

    // Importe Moneda Origen
    //-----------------------------
    dsCCURFR200T.F200IMO = %EDITC(dsTRANSAC.GEIMPOP:'X');

    IF dsTRANSAC.GESIGIMOP = '-';
      %Subst(dsCCURFR200T.F200IMO:1:1) = '-';
    ENDIF;

    // Codigo ISO Moneda Facturada
    //-----------------------------
    dsCCURFR200T.F200ITF = %Editc(dsTRANSAC.GEISOMON:'X');

    // Importe Moneda Facturada
    //-----------------------------
    dsCCURFR200T.F200IMF = %EDITC(dsTRANSAC.GEIMPOP:'X');

    IF dsTRANSAC.GESIGIMOP = '-';
      %Subst(dsCCURFR200T.F200IMF:1:1) = '-';
    ENDIF;

    // Nombre Comercio   
    //-----------------------------------
    dsCCURFR200T.F200MNA = dsTransac.GEPROOV;
    // Nombre Comercio
    //-----------------------------
    IF WNUMEST > 0;
      dsCCURFR200T.F200MNA = dsESTA1.ENOMBR;
    ELSE;
      dsCCURFR200T.F200MNA = '';
    ENDIF;

  
    // Actividad ISO Comercio (MCC)
    //-----------------------------
    Exec Sql 
      Select * 
      Into :dsTABACTI
      From TABACTI 
      Where TACDIN = :dsESTA1.EACTPR;

    dsCCURFR200T.F200MCC = %EDITC(dsTABACTI.TACDCI:'X');

    // Localidad Comercio
    //-----------------------------
    dsCCURFR200T.F200MCI = %SUBST(dsESTA1.ELOCPV:7:26);

    // Provincia Comercio
    //-----------------------------
    dsCCURFR200T.F200MSP = dsINDEPROV.PNOPRO;

    // Codigo Postal Comercio
    //-----------------------------
    dsCCURFR200T.F200MPC = %Subst(dsESTA1.ELOCPV:1:5);

    // Codigo ISO Pais Comercio
    //-----------------------------
    dsCCURFR200T.F200IMC = '724';

    // Total Importe Tasas
    //-----------------------------
    TASAS = dsTRANSAC.GEIMIVA1 + 
            dsTRANSAC.GEIMIVA2 + 
            dsTRANSAC.GEIMIVA3;
    dsCCURFR200T.F200ITT = %EDITC(TASAS:'X');

    IF dsTRANSAC.GESIGIMOP = 'A' AND TASAS <> 0;
      %Subst(dsCCURFR200T.F200ITT:1:1) = '-';  
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
    dsCCURFR200T.F200MRN = %EDITC(WNumEst:'X');

    //-----------------------------
    IF WNumEst > 0;
      dsCCURFR200T.F200MTN = dsESTA1.ENNIF;
    ELSE;
      dsCCURFR200T.F200MTN = *BLANKS;
    ENDIF;

    // CIF Empresa
    //-----------------------------
    dsCCURFR200T.F200CTN = dsT_MSOCIO.SNNIF;

    // Indicador de IVA
    //-----------------------------
    Select;
      When WNumEst > 0 And TASAS = 0;
        dsCCURFR200T.F200VDI = '0'; // Desconocido
      When WNumEst > 0 And TASAS <> 0;
        dsCCURFR200T.F200VDI = '2'; // Con Iva
      When WNumEst = 0 And TASAS = 0;
        dsCCURFR200T.F200VDI = '0'; // Desconocido
      When WNumEst = 0 And TASAS <> 0;
        dsCCURFR200T.F200VDI = '2'; // Con Iva
    ENDSL;

    // Tipo Facturación
    //-----------------------------
    dsCCURFR200T.F200BTY = '01'; // Individual

    // Descripción Transaccion
    //-----------------------------
    dsCCURFR200T.F200TDE = dsTRANSAC.GEDESLIB;

    // Referencias (1-10)
    //-----------------------------
    dsCCURFR200T.F200C01 = dsTRANSAC.GEREF01;
    dsCCURFR200T.F200C02 = dsTRANSAC.GEREF02;
    dsCCURFR200T.F200C03 = dsTRANSAC.GEREF03;
    dsCCURFR200T.F200C04 = dsTRANSAC.GEREF04;
    dsCCURFR200T.F200C05 = dsTRANSAC.GEREF05;
    dsCCURFR200T.F200A01 = dsTRANSAC.GEREF06;
    dsCCURFR200T.F200A02 = dsTRANSAC.GEREF07;
    dsCCURFR200T.F200A03 = dsTRANSAC.GEREF08;
    dsCCURFR200T.F200A04 = dsTRANSAC.GEREF09;
    dsCCURFR200T.F200A05 = dsTRANSAC.GEREF10;

    // Identificacion Empleado
    //-----------------------------
    dsCCURFR200T.F200EID = dsTRANSAC.GEREF01;

    //------------------------------------//
    // TO DO - Validaciones Adicionales   //
    //------------------------------------//

    //--------------------------------------------------
    // CAMPOS VARIOS   MCC (Mechant Code)
    //--------------------------------------------------
    IF dsTRANSAC.GESERFEE =  '3'; // La operación no es un cargo por emisión
      Exec SQL
        Select *
        Into :dsSGCCURMCC
        From SGCCURMCC
        Where
          MTARJE = :WNUMREAL
          AND MFECBAJ = 0; 

      IF SqlCode = 0; 

        IF dsTRANSAC.GEPROOV   <> ' ';
          dsCCURFR200T.F200MNA = dsTRANSAC.GEPROOV;
        ENDIF;

        IF dsTRANSAC.GECIUDES  <> ' ';
          dsCCURFR200T.F200MCI = dsTRANSAC.GECIUDES;
          dsCCURFR200T.F200MSP = dsTRANSAC.GECIUDES;
        ENDIF;

        IF dsTRANSAC.GECOISOPD <> ' ';
          Exec SQL
            Select *
            Into :dsPAISESISOL
            From PAISESISOL
            Where
              C_CODEISO = :dsTRANSAC.GECOISOPD; 

          IF SqlCode = 0;
            dsCCURFR200T.F200IMC = %EDITC(dsPAISESISOL.C_CODE:'X');
          ENDIF;
        ENDIF;        
        Select;
          When dsTRANSAC.GETIPRE = 'RH';
            dsCCURFR200T.F200MCC = '7011';  // HOTELES
          When dsTRANSAC.GETIPRE = 'RV';
            dsCCURFR200T.F200MCC = '7512';  // ALQUILER COCHES
          When dsTRANSAC.GETIPRE = 'RR';
            dsCCURFR200T.F200MCC = '4011';  // FERROCARRIL
          When dsTRANSAC.GETIPRE = 'RA';
            dsCCURFR200T.F200MCC = '4011';  // LINEA AEREAS

            // ---------------------------------------
            // Aqui Validaciones si es REPSOL para MCC
            // CAU-10743
            // ---------------------------------------
            WES_REPSOL = '0';
            Exec SQL
                Select '1'
                Into :WES_REPSOL
                From SISGESTAR
                Where
                  TNREAL = :WNUMREAL
                  AND TGRUPO = 10030462
                  AND TFBASG = 0;
            If WES_REPSOL;

              If dsTRANSAC.GENUMAUD = 0  AND // Cod. Autoriz  es Cero
                 dsTRANSAC.GEIMPOP > 0 AND
                 dsTRANSAC.GESIGIMOP = '+'; 
                dsCCURFR200T.F200MCC = '4722';
              EndIf;
               If dsTRANSAC.GENUMAUD = 0  AND // Cod. Autoriz  es Cero
                 dsTRANSAC.GEIMPOP > 0 AND
                 dsTRANSAC.GESIGIMOP = '+'; 
                dsCCURFR200T.F200MCC = '4711';
              EndIf;

            Endif;  

        ENDSL;

      EndIf;

    EndIf;

    // Reservado (Libre)
    //-----------------------------
    dsCCURFR200T.F200lib = *BLANKS;
    
    //------------------------------------//
    // TO DO - AD HOC                     //
    //------------------------------------//
    AD_HOC_FR200();

    // Graba registro en el historico CCURFR200T
    //------------------------------------------
    Graba_Reg_FR200();

  End-Proc;
  // ****************************************************************************
  // Genera Registro tipo 400 y 401
  // ****************************************************************************
  dcl-proc Genera_RegistdsTRANSAC.GE400;
    dcl-pi Genera_RegistdsTRANSAC.GE400;

    end-pi;

    Dcl-s WNOMAGE Char(30);
    Dcl-s TASAX  packed(15:2);

    reset dsCCURFR400T;
    // =================================
    // CCURFR400T (CABECERAS)
    // =================================
    Reset dsCCURFR400T;

    // Identificacion Registro
    //----------------------------------------
    dsCCURFR400T.F400IDR = 400;

    // Vendor identifier
    //----------------------------------------
    dsCCURFR400T.F400VVI = *BLANKS;

    // Vendor Name
    //----------------------------------------
    Exec SQL
      Select FNOAGE
      Into :WNOMAGE
      From FAGENCON
      Where
        FAGORD = :dsTRANSAC.AGNUMAGE;

    If Sqlcode = 0;
      dsCCURFR400T.F400VVN = WNOMAGE;
    Else;
      dsCCURFR400T.F400VVN = '';
    Endif;

    // Ivoice Account Number
    //----------------------------------------
    dsCCURFR400T.F400IAN = %Editc(WNUMREAL:'X') + '9999';

    // INVOICE ACCO. name
    //----------------------------------------
    dsCCURFR400T.F400ACN = dsT_MSOCIO.SNOMEM;

    // Reservado (Libre)
    //----------------------------------------
    dsCCURFR400T.F400LIB = *BLANKS;

    // Graba registro en el historico CCURFR200T
    //------------------------------------------
    Graba_Reg_FR400();

    // =================================
    // CCURFR401T (DETALLES)
    // =================================
    Reset dsCCURFR401T;

    // // Identificacion Registro
    // //----------------------------------------
    // dsCCURFR401T.F401IDR = 401;

    // // Ivoice Account Number
    // //----------------------------------------
    // dsCCURFR401T.F401IAN = %Editc(WNUMREAL:'X') + '9999';

    // // Statement Identifier
    // //----------------------------------------
    // dsCCURFR401T.F401SID  = %SUBST(OMIFFA_ALF:1:6);

    // // Reference number
    // //----------------------------------------
    // dsCCURFR401T.F401REN =
    //       %EDITC(*DATE:'X') +
    //       %EDITC(WNUMREAL:'X') +
    //       dsTRANSAC.GENUTRAN;

    // // Invoice Number    Nº.FACTURA _ REFERENCIA1
    // //----------------------------------------

    // IF OMINFA = *BLANKS;
    //   dsCCURFR401T.F401INU  = OMIFFA_ALF + '_' + OREF01;
    //   ELSE;
    //   dsCCURFR401T.F401INU  = %TRIM(OMINFA) + '_' + OREF01;
    // ENDIF;

    // //----------------------------------------
    // // AGENCIA 4065 GLOBAL BUSINESS TRAVEL (AMEX)
    // // Invoice Number    Nº.FACTURA _ REFERENCIA2
    // //----------------------------------------

    // IF ONUAGE = 4065;

    //   IF OMINFA = *BLANKS;
    //     dsCCURFR401T.F401INU  = OMIFFA_ALF + '_' + OREF02;
    //   ELSE;
    //     dsCCURFR401T.F401INU  = %TRIM(OMINFA) + '_' + OREF02;
    //   ENDIF;

    // ENDIF;

    // // Invoice Date
    // //----------------------------------------
    // dsCCURFR401T.F401IDA  = OMIFFA;

    // // Invoice Type
    // //----------------------------------------

    // dsCCURFR401T.F401ITY = '1';

    // PIMPOR15 = IMPORTE;

    // IF PIMPOR15 < 0;
    //   dsCCURFR401T.F401ITY = '2';
    // ENDIF;

    // // Related Invoice Nnumber
    // //----------------------------------------
    // dsCCURFR401T.F401RIN = *BLANKS;

    // // Transaction Date
    // //----------------------------------------

    // dsCCURFR401T.F401FTR = OMIFVE;

    // // Original/Foreign Transaction Amount ISO
    // //----------------------------------------
    // dsCCURFR401T.F401TAI = '978';

    // // Importe Transaccion   Original/foreign
    // //----------------------------------------
    // PIMPOR15 = IMPORTE;

    // IF PIMPOR15   < 0;
    //   PIMPOR15     *= -1;
    // ENDIF;

    // dsCCURFR401T.F401OTA = %EDITC(PIMPOR15:'X');

    // IF IMPORTE < 0;
    //   %SubSt(dsCCURFR401T.F401OTA:1:1) = '-';
    //   //C        MOVEL     '-'           dsCCURFR401T.F401OTA
    // ENDIF;


    // // Original/Foreign Transaction Amount ISO
    // //----------------------------------------
    // dsCCURFR401T.F401PBA = '978';

    // // Importe Transaccion   Posted/Billing
    // //----------------------------------------

    // dsCCURFR401T.F401PAM = %EDITC(PIMPOR15:'X');

    // IF IMPORTE < 0;
    //   %SubSt(dsCCURFR401T.F401PAM:1:1) = '-';
    //     //C       MOVEL     '-'           dsCCURFR401T.F401PAM
    // ENDIF;

    // // Merchant Name
    // //----------------------------------------
    // dsCCURFR401T.F401MNA = OMINPR;

    // // Nombre Comercio   oper. bagencond
    // //--------------------------------------------------------
    // IF PA_BAGEN = 'B';      //Operaciones de Agencia  -AG-
    //   dsCCURFR401T.F401MNA = OMINPR;
    // ENDIF;

    // dsCCURFR401T.F401MCO = '4722';

    // IF  OMITRE = 'RH' AND  OMIFEE = '3';           //HOTELES
    //   dsCCURFR401T.F401MCO = '7011 ';
    // ENDIF;

    // IF  OMITRE = 'RV' AND  OMIFEE = '3';           // ALQUILER COCHES
    //   dsCCURFR401T.F401MCO = '7512';
    // ENDIF;

    // IF  OMITRE = 'RR' AND  OMIFEE = '3';           // FERROCARRIL
    //   dsCCURFR401T.F401MCO = '4011';
    // ENDIF;

    // IF OMITRE  = 'RA' AND OMIFEE = '3' AND       // LINEA AEREAS
    //     ONUAUT <> 0 AND IMPORTE > 0;
    //   dsCCURFR401T.F401MCO = '4722';
    // ENDIF;

    // IF OMITRE  = 'RA' AND OMIFEE = '3';          // LINEA AEREAS
    //   dsCCURFR401T.F401MCO = '4511';
    // ENDIF;

    // // Localidad Comercio
    // //-----------------------------
    // IF WNUMES > 0;
    //   dsCCURFR401T.F401MCI = %SUBST(ELOCPV:7:26);
    // ELSE;
    //   dsCCURFR401T.F401MCI = LCITY;
    // ENDIF;

    // // Provincia Comercio
    // //-----------------------------

    // dsCCURFR401T.F401MPO = *BLANKS;

    // IF WNUMES > 0 AND WNUMES <> 9999999;
    //   dsCCURFR401T.F401MPO = PNOPRO;
    // ENDIF;

    // // Codigo Postal Comercio
    // //-----------------------------
    // IF WNUMES > 0;
    //   dsCCURFR401T.F401MPC = %Subst(ELOCPV:1:5);
    // ELSE;
    //   dsCCURFR401T.F401MPC = ESTZP;
    // ENDIF;

    // // Codigo ISO Pais Comercio
    // //-----------------------------
    // IF WNUMES > 0;
    //   dsCCURFR401T.F401MCU = '724';
    // ELSE;
    //   dsCCURFR401T.F401MCU = %EDITC(GEOCD:'X');
    // ENDIF;

    // // Tax Amount
    // //-----------------------------
    // TASAS = 0;
    // TASAS = OMIIVA1;

    // dsCCURFR401T.F401TAA = %EDITC(TASAS:'X');

    // IF IMPORTE < 0 AND TASAS <> 0;
    //   %SubSt(dsCCURFR401T.F401TAA:1:1) = '-';
    //     //C    MOVEL     '-'           dsCCURFR401T.F401TAA
    // ENDIF;

    // // Local Tax Amount
    // //-----------------------------
    // dsCCURFR401T.F401LTA = *BLANKS;

    // // Value Tax Amount
    // //-----------------------------
    // dsCCURFR401T.F401VAT = *BLANKS;

    // // Sales Tax Amount
    // //-----------------------------
    // dsCCURFR401T.F401STA = *BLANKS;

    // // Other Tax Amount
    // //-----------------------------
    // dsCCURFR401T.F401OAM = *BLANKS;

    // // Merchant  Other Tax Amount
    // //-----------------------------
    // dsCCURFR401T.F401MTN = *BLANKS;

    // // Customer Tax Number
    // //-----------------------------
    // dsCCURFR401T.F401CTN = *BLANKS;

    // // Vat Data Indicator
    // //-----------------------------
    // dsCCURFR401T.F401VDI = ' ';

    // // Transaction Descripcion
    // //-----------------------------
    // dsCCURFR401T.F401TRD = ODESLI;

    // // Visa Fee Indicator
    // //-----------------------------
    // dsCCURFR401T.F401VFI =  '0';

    // // Visa Type
    // //-----------------------------
    // dsCCURFR401T.F401VTI = *BLANKS;

    // // Visa Type descripcion
    // //-----------------------------
    // dsCCURFR401T.F401VTD = *BLANKS;

    // // Visa Destination Country ISO
    // //-----------------------------
    // dsCCURFR401T.F401VDC = *BLANKS;

    // // Original Visa Service Charge ISO
    // //-----------------------------
    // dsCCURFR401T.F401VSC = *BLANKS;

    // // Original Visa Service Charge
    // //-----------------------------
    // dsCCURFR401T.F401VCH = *BLANKS;

    // // Visa Service Charge ISO
    // //-----------------------------
    // dsCCURFR401T.F401BSH = *BLANKS;

    // // Posted Visa Service Charge ISO
    // //-----------------------------
    // dsCCURFR401T.F401PSC = *BLANKS;

    // // Visa Other Charge Description
    // //-----------------------------
    // dsCCURFR401T.F401OCD = *BLANKS;

    // // Origianl Visa Other Charge ISO
    // //-----------------------------
    // dsCCURFR401T.F401OCI = *BLANKS;

    // // Origianl Visa Other Charge
    // //-----------------------------
    // dsCCURFR401T.F401OOC = *BLANKS;

    // // Posted/billed Visa Other Change ISO
    // //-----------------------------
    // dsCCURFR401T.F401POC = *BLANKS;

    // // Posted  Visa Other Change
    // //-----------------------------
    // dsCCURFR401T.F401PCH = *BLANKS;

    // // Referencias (1-10)
    // //-----------------------------
    // dsCCURFR401T.F401CF1 = OREF01;             //REQUEST ID ANTES DE LA POSICIONES 895-898
    // dsCCURFR401T.F401CF2 = OREF02;
    // dsCCURFR401T.F401CF3 = OREF03;
    // dsCCURFR401T.F401CF4 = OREF04;
    // dsCCURFR401T.F401CF5 = OREF05;
    // dsCCURFR401T.F401CF6 = OREF06;
    // dsCCURFR401T.F401CF7 = OREF07;
    // dsCCURFR401T.F401CF8 = OREF08;
    // dsCCURFR401T.F401CF9 = OREF09;
    // dsCCURFR401T.F401C10 = OREF10;

    // // Reservado (Libre)
    // //----------------------------------------
    // dsCCURFR401T.F401LIB = *BLANKS;

    // //TODOREG = CCURFR401PF;  // CCURFR401
    // TODOREG = dsCCURFR401T;  // CCURFR401
    // EXCEPT;

    // // Graba registro en el historico CCURFR401T
    // //------------------------------------------
    // Graba_Reg_FR401(PARAM_IDP:PARAM_IDH);
    // =================================
    // FINAL DE PROGRAMA
    // =================================



  End-Proc;
  // ****************************************************************************
  // Validaciones Adicionales FR200
  // ****************************************************************************
  dcl-proc Validaciones_Adicionales_FR200;
    dcl-pi Validaciones_Adicionales_FR200;

    end-pi;

    // //--------------------------------------------------
    // // CAMPOS VARIOS   MCC (Mechant Code)
    // //--------------------------------------------------
    // IF dsTRANSAC.GETIPRE = 'RH' AND 
    //    dsTRANSAC.GESERFEE =  '3';  // HOTELES

    //   Exec SQL
    //     Select *
    //     Into :dsSGCCURMCC
    //     From SGCCURMCC
    //     Where
    //       MTARJE = :WNUMREAL
    //       AND MFECBAJ = 0; 

    //   IF SqlCode = 0;          // ENCONTRADO

    //     dsCCURFR200T.F200MCC = '7011';

    //     IF dsTRANSAC.GEPROOV   <> ' ';
    //       dsCCURFR200T.F200MNA = dsTRANSAC.GEPROOV;
    //     ENDIF;

    //     IF dsTRANSAC.GECIUDES  <> ' ';
    //       dsCCURFR200T.F200MCI = dsTRANSAC.GECIUDES;
    //       dsCCURFR200T.F200MSP = dsTRANSAC.GECIUDES;
    //     ENDIF;

    //     IF dsTRANSAC.GECOISOPD <> ' ';
    //       Exec SQL
    //         Select *
    //         Into :dsPAISESISOL
    //         From PAISESISOL
    //         Where
    //           C_CODEISO = :dsTRANSAC.GECOISOPD; 

    //       IF SqlCode = 0;
    //         dsCCURFR200T.F200IMC = %EDITC(dsPAISESISOL.C_CODE:'X');
    //       ENDIF;
    //     ENDIF;
    //   ENDIF;            //ENCONTRADO

    // ENDIF;               //FIN MCC  HOTELES


    // //---------------------------------------------------
    // // OPERACIONES FACTURADAS   -RV- ALQUILER COCHES  
    // //---------------------------------------------------
    // IF dsTRANSAC.GETIPRE = 'RV' AND 
    //    dsTRANSAC.GESERFEE =  '3';  // COCHES

    //   Exec SQL
    //     Select *
    //     Into :dsSGCCURMCC
    //     From SGCCURMCC
    //     Where
    //       MTARJE = :WNUMREAL
    //       AND MFECBAJ = 0; 

    //   IF SqlCode = 0;          // ENCONTRADO

    //     dsCCURFR200T.F200MCC = '7512';

    //     IF dsTRANSAC.GEPROOV   <> ' ';
    //       dsCCURFR200T.F200MNA = dsTRANSAC.GEPROOV;
    //     ENDIF;

    //     IF dsTRANSAC.GECIUDES  <> ' ';
    //       dsCCURFR200T.F200MCI = dsTRANSAC.GECIUDES;
    //       dsCCURFR200T.F200MSP = dsTRANSAC.GECIUDES;
    //     ENDIF;

    //     IF dsTRANSAC.GECOISOPD <> ' ';
    //       Exec SQL
    //         Select *
    //         Into :dsPAISESISOL
    //         From PAISESISOL
    //         Where
    //           C_CODEISO = :dsTRANSAC.GECOISOPD; 

    //       IF SqlCode = 0;
    //         dsCCURFR200T.F200IMC = %EDITC(dsPAISESISOL.C_CODE:'X');
    //       ENDIF;
    //     ENDIF;

    //   ENDIF;            //ENCONTRADO  ALQUILER COCHES

    // ENDIF;               //FIN MCC  COCHES

    // //---------------------------------------------------
    // // OPERACIONES FACTURADAS   -RR-  FERROCARRIL     
    // //---------------------------------------------------
    // IF dsTRANSAC.GETIPRE = 'RR' AND 
    //    dsTRANSAC.GESERFEE =  '3';  // FERROCARRIL

    //   Exec SQL
    //     Select *
    //     Into :dsSGCCURMCC
    //     From SGCCURMCC
    //     Where
    //       MTARJE = :WNUMREAL
    //       AND MFECBAJ = 0; 

    //   IF SqlCode = 0;          // ENCONTRADO FERROCARRIL

    //     dsCCURFR200T.F200MCC = '4011';

    //     IF dsTRANSAC.GEPROOV   <> ' ';
    //       dsCCURFR200T.F200MNA = dsTRANSAC.GEPROOV;
    //     ENDIF;

    //     IF dsTRANSAC.GECIUDES  <> ' ';
    //       dsCCURFR200T.F200MCI = dsTRANSAC.GECIUDES;
    //       dsCCURFR200T.F200MSP = dsTRANSAC.GECIUDES;
    //     ENDIF;

    //     IF dsTRANSAC.GECOISOPD <> ' ';
    //       Exec SQL
    //         Select *
    //         Into :dsPAISESISOL
    //         From PAISESISOL
    //         Where
    //           C_CODEISO = :dsTRANSAC.GECOISOPD; 

    //       IF SqlCode = 0;
    //         dsCCURFR200T.F200IMC = %EDITC(dsPAISESISOL.C_CODE:'X');
    //       ENDIF;
    //     ENDIF;

    //   ENDIF;            //ENCONTRADO FERROCARRIL

    // ENDIF;               //FIN MCC

    // //---------------------------------------------------
    // // OPERACIONES FACTURADAS   -RA-  LINEA AEREAS    
    // //---------------------------------------------------
    // IF dsTRANSAC.GETIPRE  = 'RA' AND  
    //    dsTRANSAC.GESERFEE = '3' AND
    //    dsTRANSAC.GENUMAUD <> 0  AND // Cod. Autoriz Dif Cero
    //    dsTRANSAC.GEIMPOP > 0 AND
    //    dsTRANSAC.GESIGIMOP = '+';            // LINEA AEREAS    15-02-23 CAU-4787

    //   Exec SQL
    //     Select *
    //     Into :dsSGCCURMCC
    //     From SGCCURMCC
    //     Where
    //       MTARJE = :WNUMREAL
    //       AND MFECBAJ = 0; 

    //   IF SqlCode = 0;   // ENCONTRADO LINEA AEREAS

    //     dsCCURFR200T.F200MCC = '4511';

    //     IF dsTRANSAC.GEPROOV   <> ' ';
    //       dsCCURFR200T.F200MNA = dsTRANSAC.GEPROOV;
    //     ENDIF;

    //     IF dsTRANSAC.GECIUDES  <> ' ';
    //       dsCCURFR200T.F200MCI = dsTRANSAC.GECIUDES;
    //       dsCCURFR200T.F200MSP = dsTRANSAC.GECIUDES;
    //     ENDIF;

    //     IF dsTRANSAC.GECOISOSA <> ' ';
    //       Exec SQL
    //         Select *
    //         Into :dsPAISESISOL
    //         From PAISESISOL
    //         Where
    //           C_CODEISO = :dsTRANSAC.GECOISOSA; 

    //       IF SqlCode = 0;
    //         dsCCURFR200T.F200IMC = %EDITC(dsPAISESISOL.C_CODE:'X');
    //       ENDIF;
    //     ENDIF;

    //     // Aqui Validaciones si es REPSOL para MCC
    //     // CAU-10743
    //     WES_REPSOL = '0';
    //     Exec SQL
    //         Select '1'
    //         Into :WES_REPSOL
    //         From SISGESTAR
    //         Where
    //           TNREAL = :WNUMREAL
    //           AND TGRUPO = 10030462
    //           AND TFBASG = 0
    //       ;
    //     If WES_REPSOL;
    //       dsCCURFR200T.F200MCC = '4722';
    //     EndIf;
    //   ENDIF;            //ENCONTRADO LINEA AEREAS

    // ENDIF;               //FIN MCC LINEA AEREAS

    // // CAU-10743 Tarjetas REPSOL
    // // --------------------------
    // IF dsTRANSAC.GETIPRE  = 'RA' AND  
    //    dsTRANSAC.GESERFEE = '3' AND
    //    dsTRANSAC.GENUMAUD = 0  AND // Cod. Autoriz  es Cero
    //    dsTRANSAC.GEIMPOP > 0 AND
    //    dsTRANSAC.GESIGIMOP = '+';

    //   WES_REPSOL = '0';
    //   Exec SQL
    //     Select '1'
    //     Into :WES_REPSOL
    //     From SISGESTAR
    //     Where
    //       TNREAL = :WNUMREAL
    //       AND TGRUPO = 10030462
    //       AND TFBASG = 0
    //     ;
    //   If WES_REPSOL;
    //     dsCCURFR200T.F200MCC = '4511';
    //   EndIf;
    // Endif;


  End-Proc;
  // ****************************************************************************
  // AD_HOC_FR200: Cambio personalizados por peticiones de Clientes
  // ****************************************************************************
  dcl-proc AD_HOC_FR200;
    dcl-pi AD_HOC_FR200;

    end-pi;

    Dcl-s WIMPIVA  Zoned(15:0);
    //--------------------------------------------------
    // Especial para Tarjeta 08611112  -BANCO SANTANDER-
    //--------------------------------------------------
    // Fecha Entrada Diners  a Fecha de servicio
    // DESCLIB  A REFERENCIA 4
    // CIUDAD DESTINO   A REFERENCIA 5
    // dsCCURFR200T.F200C05 = %Subst(dsTRANSAC.GECIUDES:1:20);
    // DESLIB   A REFERENCIA 5  NUEVA PETICION POR EMAIL-13-04-2023
    // dsCCURFR200T.F200C05 = %Subst(dsTRANSAC.GEDESLIB:21:20);      MAITE PEREZ
    //--------------------------------------------------------------
    IF WNUMREAL = 08611112 AND dsTRANSAC.GETIPRE = 'RO';
      dsCCURFR200T.F200PDA = dsTRANSAC.GEFEINSE;
      dsCCURFR200T.F200C04 = %Subst(dsTRANSAC.GEDESLIB:1:20);
      dsCCURFR200T.F200C05 = %Subst(dsTRANSAC.GEDESLIB:21:20);
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
        TNREAL = :WNUMREAL
        AND TGRUPO = 10068676  // hay que confirmar el codigo
        AND TFBASG = 0
    ;
    If WES_Ferrovial;
      dsCCURFR200T.F200C05 = %Editc(dsTRANSAC.GEFEINSE:'X');
      dsCCURFR200T.F200A01 = %Editc(dsTRANSAC.GEFEFISE:'X');
      WIMPIVA = dsTRANSAC.GEIMIVA1*100;
      dsCCURFR200T.F200A02 = %Char(WIMPIVA);
      dsCCURFR200T.F200A05 = dsTRANSAC.GENUFACT;
    EndIf;
    //--------------------------------------------------

    //--------------------------------------------------
    // Referencias (2) talón de Venta de VECI -SGCCURTV
    //--------------------------------------------------
    Exec SQL
      Select *
      Into :dsSGCCURTV
      From SGCCURTV
      Where
        STARJE = :WNUMREAL;
    
    If Sqlcode = 0;
      IF dsSGCCURTV.SFECBAJ = 0 and
         dsTRANSAC.GENUALBA<>'';        // TALON VENTA
        dsCCURFR200T.F200C02 = dsTRANSAC.GENUALBA;
      ENDIF;
    EndIf;

    //----------------------------------------
    // Referencias (4) Importe Neto   -SGCCURIM
    //----------------------------------------
    Exec SQL
      Select *
      Into :dsSGCCURIM
      From SGCCURIM
      Where
        ITARJE = :WNUMREAL;
    
    If Sqlcode = 0;
      IF dsSGCCURIM.IFECBAJ = 0 And
        dsTRANSAC.GEIMNETA<>0;        // Importe neto
        dsCCURFR200T.F200C04 =  %EDITC(dsTRANSAC.GEIMNETA:'X');
      ENDIF;
    EndIf;

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
        AND TNREAL = :WNUMREAL;

    If WIndra;
      dsCCURFR200T.F200MNA = 
          %Editc(dsTRANSAC.GEFEINSE:'X') + '-' +
          %Trim(dsTRANSAC.GENUALBA)      + '-' +
          %Trim(dsTRANSAC.GEPROOV);
    Endif;

  End-Proc;
  //---------------------------------------------------------------
  // Grabar registros 303 y 304 (Ferrocarriles)
  //---------------------------------------------------------------
  dcl-proc Genera_Registros_RR_303_304;

    dcl-pi Genera_Registros_RR_303_304;

    end-pi;

    Dcl-s WTOTGAST Zoned(15:0);
    Dcl-s WRRNUTER Char(5);
    Dcl-s WRRSEC Char(4);
    Dcl-s WRRSUCTER Char(3);

    reset dsCCURFR303T;

    dsCCURFR303T.F303IDR = 303;
    dsCCURFR303T.F303TRN =
        %EDITC(*DATE:'X') + 
        %EDITC(WNUMREAL:'X') + 
        dsTRANSAC.GENUTRAN;

    // Numero Billete
    //----------------------------------------
    dsCCURFR303T.F303TNU = %TRIM(dsTRANSAC.GENUMDOC);

    // Nombre Pasajero
    //----------------------------------------
    dsCCURFR303T.F303PNA = dsTRANSAC.GENOMPA;

    // CODIGO AGENCIA VIAJES (IATA)
    //----------------------------------------
    dsCCURFR303T.F303TAC = 'RAIL'; 

    // NOMBRE AGENCIA VIAJES (IATA)
    //----------------------------------------
    dsCCURFR303T.F303TAN = dsTRANSAC.GEPROOV;

    // FECHA SALIDA SEGMENTO
    //----------------------------------------
    dsCCURFR303T.F303DDA = dsTRANSAC.GEFEINSE;

    // NUMERO DE SEGMENTOS
    //----------------------------------------
    dsCCURFR303T.F303NLE = 01;

    // INDICADOR DE RESTRICCION
    //----------------------------------------
    dsCCURFR303T.F303RFL = '0'; // SIN RESTRICCION

    // FECHA EMISION (FECHA DE COMPRA)
    //----------------------------------------
      dsCCURFR303T.F303IDA = dsTRANSAC.GEFECOMP;

    // ABREVIATURA LLAA QUE VUELA
    //----------------------------------------
    dsCCURFR303T.F303ICA = dsTRANSAC.GEPROOV;

    // DATO DEFINIDO POR CLIENTE
    //----------------------------------------
    dsCCURFR303T.F303CDA = *BLANKS; // ¿?

    // TARIFA BASE (IMPORTE NETO)
    //----------------------------------------
    dsCCURFR303T.F303BFA = %EDITC(dsTRANSAC.GEIMNETA:'X');

    // IMPORTE TOTAL BILLETE
    //----------------------------------------
    dsCCURFR303T.F303TFA = %EDITC(dsTRANSAC.GEIMPOP:'X');

    IF dsTRANSAC.GESIGIMOP = '-';
      %SubSt(dsCCURFR303T.F303TFA:1:1) = '-';
    ENDIF;

    // IMPORTE TOTAL GASTOS
    //----------------------------------------
    WTOTGAST = 0;
    dsCCURFR303T.F303TFE = *ALL'0';

    IF dsTRANSAC.GEIMNETA <> 0;
      WTOTGAST = dsTRANSAC.GEIMPOP - dsTRANSAC.GEIMNETA;
      dsCCURFR303T.F303TFE = %EDITC(WTOTGAST:'X');
    ENDIF;

    // INDICADOR DE CAMBIO
    //----------------------------------------
    dsCCURFR303T.F303ETF = ' '; 

    // BILLETE CON MAS DE 4 SEGMENTOS
    //----------------------------------------
    dsCCURFR303T.F303CID = *BLANKS; 

    // NUMERO BILLETE REEMBOLSO
    //----------------------------------------
    dsCCURFR303T.F303RTN = *BLANKS; 

    // NUMERO BILLETE CAMBIADO
    //----------------------------------------
    dsCCURFR303T.F303ETN = *BLANKS; 

    // IMPORTE BILLETE CAMBIADO
    //----------------------------------------
    dsCCURFR303T.F303ETA = *ALL'0';

    // CODIGO MERCANCIA
    //----------------------------------------
    dsCCURFR303T.F303CCO = *BLANKS; 

    // Referencias (1-5)
    //----------------------------------------
    dsCCURFR303T.F303C01 = dsTRANSAC.GEREF01;
    dsCCURFR303T.F303C02 = dsTRANSAC.GEREF02;
    dsCCURFR303T.F303C03 = dsTRANSAC.GEREF03;
    dsCCURFR303T.F303C04 = dsTRANSAC.GEREF04;
    dsCCURFR303T.F303C05 = dsTRANSAC.GEREF05;

    // Reservado (Libre)
    //----------------------------------------
    dsCCURFR303T.F303LIB = *BLANKS;


    // Graba registro en el historico CCURFR303T
    //------------------------------------------
    Graba_Reg_FR303();

    // ====================================================================
    // GRABAR: CCURFR304T  SEGMENTO-1
    // ====================================================================
    Reset dsCCURFR304T;

    // Se busca datos Adicionales para RR en el atrium.Ferroca
    Exec Sql
      Select RRNUTER, RRSEC, RRSUCTER
      Into :WRRNUTER, :WRRSEC, :WRRSUCTER
      From Atrium.Ferroca
      Where
        AGNUMAGE = :dsTRANSAC.AGNUMAGE AND
        HONUMFIC = :dsTRANSAC.HONUMFIC AND 
        GENUMTRA = :dsTRANSAC.GENUMTRA;

    If Sqlcode <> 0;    
      // Graba registro en el historico CCURFR304T
      //------------------------------------------
      Graba_Reg_FR304();
      return;
    EndIf;

    dsCCURFR304T.F304IDR = 304;
    dsCCURFR304T.F304TRN =
        %EDITC(*DATE:'X') + 
        %EDITC(WNUMREAL:'X') + 
        dsTRANSAC.GENUTRAN;

    // Nº.DEL SEGMENTO
    //----------------------------------------
    dsCCURFR304T.F304TLN = '01';

    // CODIGO ABREVIADO LLAA
    //----------------------------------------
    dsCCURFR304T.F304CCO = *BLANKS; 

    // CLASE O CODIGO SERVICIO
    //----------------------------------------
    dsCCURFR304T.F304CSC = *BLANKS; 

    // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
    //----------------------------------------
    dsCCURFR304T.F304DLO = dsTRANSAC.GECIUDOR;
    dsCCURFR304T.F304DCO = dsTRANSAC.GEPAISA;
    dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
    dsCCURFR304T.F304DDA = dsTRANSAC.GEFEINSE;

    // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
    //----------------------------------------
    dsCCURFR304T.F304ALO = dsTRANSAC.GECIUDES;
    dsCCURFR304T.F304ACO = dsTRANSAC.GEPAILLE;
    dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
    dsCCURFR304T.F304ADA = dsTRANSAC.GEFEFISE;

    // NUMERO DE VUELO
    //----------------------------------------
    dsCCURFR304T.F304FNU = *BLANKS; 

    // INDICADOR SEGMENTO (ORIGEN/FINAL)
    //----------------------------------------
    dsCCURFR304T.F304OFL = '1'; // SI ORIGEN
    dsCCURFR304T.F304DFL = '1'; // SI FINAL

    // IMPORTE/GASTOS DE ESTE SEGMENTO
    //----------------------------------------
    dsCCURFR304T.F304FAR = *ALL'0'; 
    dsCCURFR304T.F304FEE = *ALL'0'; 

    // NUMERO DE BILLETE CONCATENADO
    //----------------------------------------
    dsCCURFR304T.F304CTN = *BLANKS; 

    // NUMERO BILLETE CAMBIADO
    //----------------------------------------
    dsCCURFR304T.F304ETN = *BLANKS; 

    // Referencias (1-5)
    //----------------------------------------
    dsCCURFR304T.F304C01 = dsTRANSAC.GEREF01;
    dsCCURFR304T.F304C02 = dsTRANSAC.GEREF02;
    dsCCURFR304T.F304C03 = dsTRANSAC.GEREF03;
    dsCCURFR304T.F304C04 = dsTRANSAC.GEREF04;
    dsCCURFR304T.F304C05 = dsTRANSAC.GEREF05;

    // Reservado (Libre)
    //----------------------------------------
    dsCCURFR304T.F304LIB = *BLANKS;

    // Graba registro en el historico CCURFR303T
    //------------------------------------------
    Graba_Reg_FR304();
  End-proc;
  //---------------------------------------------------------------
  // Grabar registros 303 y 304 (Ferrocarriles)
  //---------------------------------------------------------------
  dcl-proc Genera_Registros_RA_303_304;

    dcl-pi Genera_Registros_RA_303_304;

    end-pi;

    Dcl-s WTOTGAST Zoned(15:0);
    Dcl-s NUIATA7  Zoned( 7:0);

    // -----------------------------------
    // RECUPERAR DATOS DE FICHEROS
    // -----------------------------------
    // Se busca datos Adicionales para RV en el atrium.Alqcoch
    Exec Sql
      Select *
      Into :dsLINAEREA
      From atrium.linaerea
      Where
        AGNUMAGE = :dsTRANSAC.AGNUMAGE AND
        HONUMFIC = :dsTRANSAC.HONUMFIC AND 
        GENUMTRA = :dsTRANSAC.GENUMTRA;

    If Sqlcode <> 0;    
      // Graba registro en el historico CCURFR301T
      //------------------------------------------
      Graba_Reg_FR303();
      return;
    EndIf;

    NUIATA7 = dsTRANSAC.GENUIATA / 10;
    
    // Datos de la Agencia de Viajes (IATA)
    Exec SQL
      Select *
      Into :dsIATA
      From IATA
      Where
        RIATA = :NUIATA7; 

    // ====================================================================
    // GRABAR: CCURFR303PF (CABECERAS)                                    
    // ====================================================================

    reset dsCCURFR303T;
    dsCCURFR303T.F303IDR = 303;
    dsCCURFR303T.F303TRN = 
        %EDITC(*DATE:'X') + 
        %EDITC(WNUMREAL:'X') + 
        dsTRANSAC.GENUTRAN;

    // Numero Billete
    //----------------------------------------
    dsCCURFR303T.F303TNU = %TRIM(dsTRANSAC.GENUMDOC);

    // Nombre Pasajero
    //----------------------------------------
    dsCCURFR303T.F303PNA = dsTRANSAC.GENOMPA;

    // CODIGO AGENCIA VIAJES (IATA)
    //----------------------------------------
    dsCCURFR303T.F303TAC = %EDITC(dsTRANSAC.GENUIATA:'X');

    // NOMBRE AGENCIA VIAJES (IATA)
    //----------------------------------------
    dsCCURFR303T.F303TAN = dsIATA.RNOMBR;

    // FECHA SALIDA SEGMENTO-1
    //----------------------------------------
    dsCCURFR303T.F303DDA = dsTRANSAC.GEFEINSE;

    // NUMERO DE SEGMENTOS
    //----------------------------------------
    SEGMENTOS = 0;

    NSEGMENTOS();
    dsCCURFR303T.F303NLE = SEGMENTOS;

    // INDICADOR DE RESTRICCION
    //----------------------------------------
    dsCCURFR303T.F303RFL = '0'; // SIN RESTRICCION

    // FECHA EMISION (FECHA DE COMPRA)
    //----------------------------------------
    IF WNUMES > 0;
      dsCCURFR303T.F303IDA = dsTRANSAC.GEFECOMP;
    ELSE;
      dsCCURFR303T.F303IDA = %DEC(%DATE(FECONSU:*EUR):*ISO);
    ENDIF;

    // ABREVIATURA LLAA QUE VUELA
    //----------------------------------------
    dsCCURFR303T.F303ICA = dsTRANSAC.GEPROOV;

    // DATO DEFINIDO POR CLIENTE
    //----------------------------------------
    dsCCURFR303T.F303CDA = *BLANKS; 

    // TARIFA BASE (IMPORTE NETO)
    //----------------------------------------
    dsCCURFR303T.F303BFA = %EDITC(dsTRANSAC.GEIMNETA:'X');

    // IMPORTE TOTAL BILLETE
    //----------------------------------------
    dsCCURFR303T.F303TFA = %EDITC(dsTRANSAC.GEIMPOP:'X');

    IF dsTRANSAC.GESIGIMOP = '-';
      %SubSt(dsCCURFR303T.F303TFA:1:1) = '-';
    ENDIF;

    // IMPORTE TOTAL GASTOS
    //----------------------------------------
    TOTGAST = 0;
    dsCCURFR303T.F303TFE = *ALL'0';

    IF dsTRANSAC.GEIMNETA <> 0;
      TOTGAST = dsTRANSAC.GEIMPOP - dsTRANSAC.GEIMNETA;
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
    dsCCURFR303T.F303CID = *BLANKS; 

    // NUMERO BILLETE REEMBOLSO
    //----------------------------------------
    dsCCURFR303T.F303RTN = %TRIM(dsLINAEREA.RANUREEM);

    // NUMERO BILLETE CAMBIADO
    //----------------------------------------
    IF dsLINAEREA.RATIPDOC <> '1';
      dsCCURFR303T.F303ETN = %TRIM(dsTRANSAC.GENUMDOC);
    ENDIF;

    // IMPORTE BILLETE CAMBIADO
    //----------------------------------------
    dsCCURFR303T.F303ETA = *ALL'0';

    IF dsLINAEREA.RATIPDOC <> '1';
      dsCCURFR303T.F303ETA = %EDITC(dsTRANSAC.GEIMPOP:'X');
      IF dsTRANSAC.GESIGIMOP = '-';
        %subSt(dsCCURFR303T.F303ETA:1:1) = '-';
      ENDIF;
    ENDIF;

    // CODIGO MERCANCIA
    //----------------------------------------
    dsCCURFR303T.F303CCO = *BLANKS; // ¿?

    // Referencias (1-5)
    //----------------------------------------
    dsCCURFR303T.F303C01 = dsTRANSAC.GEREF01;
    dsCCURFR303T.F303C02 = dsTRANSAC.GEREF02;
    dsCCURFR303T.F303C03 = dsTRANSAC.GEREF03;
    dsCCURFR303T.F303C04 = dsTRANSAC.GEREF04;
    dsCCURFR303T.F303C05 = dsTRANSAC.GEREF05;

    // Reservado (Libre)
    //----------------------------------------
    dsCCURFR303T.F303LIB = *BLANKS;


    // Graba registro en el historico CCURFR303T
    //------------------------------------------
    Graba_Reg_FR303();

    // ====================================================================
    // GRABAR: CCURFR304PF  SEGMENTO-1                                    
    // ====================================================================
    //  Primer segmento siempre tiene compañia, excepto las compañia LOW COST

    Reset dsCCURFR304T;
    dsCCURFR304T.F304IDR = 304;
    dsCCURFR304T.F304TRN = 
      %EDITC(*DATE:'X') + 
      %EDITC(WNUMREAL:'X') + 
      dsTRANSAC.GENUTRAN;

    // Nº.DEL SEGMENTO
    //----------------------------------------
    dsCCURFR304T.F304TLN = '01';

    // CODIGO ABREVIADO LLAA
    //----------------------------------------
    dsCCURFR304T.F304CCO = dsLINAEREA.RACOALCO1;

    // CLASE O CODIGO SERVICIO
    //----------------------------------------
    dsCCURFR304T.F304CSC = dsLINAEREA.RACLASER1;

    // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
    //----------------------------------------
    // Datos de la Agencia de Viajes (IATA)
    Exec SQL
      Select *
      Into :dsCIUDAD
      From CIUDAD
      Where
        xclave = :dsLINAEREA.RAAERSAL1; 

    IF SqlCode = 0;
      dsCCURFR304T.F304DLO = dsCIUDAD.XCIUDA;
      dsCCURFR304T.F304DCO = dsCIUDAD.XPAIS;
      IF %FOUND;
        IF dsCIUDAD.XISONU = '724';
          dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
        ELSE;
          dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
        ENDIF;
      ENDIF;
    ENDIF;

    dsCCURFR304T.F304DDA = dsTRANSAC.GEFEINSE;

    // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
    //----------------------------------------
    // Datos de la Agencia de Viajes (IATA)
    Exec SQL
      Select *
      Into :dsCIUDAD
      From CIUDAD
      Where
        xclave = :dsLINAEREA.RAAERDES1; 

    IF SqlCode = 0;
      dsCCURFR304T.F304ALO = dsCIUDAD.XCIUDA;
      dsCCURFR304T.F304ACO = dsCIUDAD.XPAIS;
      IF dsCIUDAD.XISONU = '724';
        dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
      ELSE;
        dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
      ENDIF;
    ENDIF;

    dsCCURFR304T.F304ADA = dsLINAEREA.RAFLLEGA1;

    // NUMERO DE VUELO
    //----------------------------------------
    dsCCURFR304T.F304FNU = %EDITC(dsLINAEREA.RANUVUEL1:'X');

    // INDICADOR SEGMENTO (ORIGEN/FINAL)
    //----------------------------------------
    dsCCURFR304T.F304OFL = '1'; // SI ORIGEN

    IF dsLINAEREA.RAAERDES2 <> ' ' AND 
       dsLINAEREA.RAAERDES2 <> '000';
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
    dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

    // NUMERO BILLETE CAMBIADO
    //----------------------------------------
    IF RA_TIPDOC <> '1';
      dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
    ENDIF;

    // Referencias (1-5)
    //----------------------------------------
    dsCCURFR304T.F304C01 = dsTRANSAC.GEREF01;
    dsCCURFR304T.F304C02 = dsTRANSAC.GEREF02;
    dsCCURFR304T.F304C03 = dsTRANSAC.GEREF03;
    dsCCURFR304T.F304C04 = dsTRANSAC.GEREF04;
    dsCCURFR304T.F304C05 = dsTRANSAC.GEREF05;

    // Reservado (Libre)
    //----------------------------------------
    dsCCURFR304T.F304LIB = *BLANKS;

    // Graba registro en el historico CCURFR304T
    //------------------------------------------
    Graba_Reg_FR304();

    // ====================================================================
    // GRABAR: CCURFR304PF  SEGMENTO-2                                   
    // ====================================================================
    IF dsLINAEREA.RACOALCO2 <> ' ' AND 
       dsLINAEREA.RACOALCO2 <> '00';

      Reset dsCCURFR304T;
      dsCCURFR304T.F304IDR = 304;
      dsCCURFR304T.F304TRN = 
        %EDITC(*DATE:'X') + 
        %EDITC(WNUMREAL:'X') + 
        dsTRANSAC.GENUTRAN;

      // Nº.DEL SEGMENTO
      //----------------------------------------
      dsCCURFR304T.F304TLN = '02';

      // CODIGO ABREVIADO LLAA
      //----------------------------------------
      dsCCURFR304T.F304CCO = dsLINAEREA.RACOALCO2;

      // CLASE O CODIGO SERVICIO
      //----------------------------------------
      dsCCURFR304T.F304CSC = dsLINAEREA.RACLASER2;

      // SALIDA: LOCALIDAD/PAIS/FECHA/IND.SAL.EX
      //----------------------------------------
      Exec SQL
        Select *
        Into :dsCIUDAD
        From CIUDAD
        Where
          xclave = :dsLINAEREA.RAAERDES1; 

      IF SqlCode = 0;
        dsCCURFR304T.F304DLO = dsCIUDAD.XCIUDA;
        dsCCURFR304T.F304DCO = dsCIUDAD.XPAIS;
        IF dsCIUDAD.XISONU = '724';
          dsCCURFR304T.F304FDF = '0'; // NO EXTRANJERO
        ELSE;
          dsCCURFR304T.F304FDF = '1'; // SI EXTRANJERO
        ENDIF;
      ENDIF;

      dsCCURFR304T.F304DDA = dsLINAEREA.RAFLLEGA1;

      // LLEGADA: LOCALIDAD/PAIS/FECHA/IND.LLE.
      //----------------------------------------
      Exec SQL
        Select *
        Into :dsCIUDAD
        From CIUDAD
        Where
          xclave = :dsLINAEREA.RAAERDES2; 

      IF SqlCode = 0;
        dsCCURFR304T.F304ALO = dsCIUDAD.XCIUDA;
        dsCCURFR304T.F304ACO = dsCIUDAD.XPAIS;
        IF dsCIUDAD.XISONU = '724';
          dsCCURFR304T.F304FAF = '0'; // NO EXTRANJERO
        ELSE;
          dsCCURFR304T.F304FAF = '1'; // SI EXTRANJERO
        ENDIF;
      ENDIF;

      dsCCURFR304T.F304ADA = dsLINAEREA.RAFLLEGA2;

      // NUMERO DE VUELO
      //----------------------------------------
      dsCCURFR304T.F304FNU = %EDITC(dsLINAEREA.RANUVUEL2:'X');

      // INDICADOR SEGMENTO (ORIGEN/FINAL)
      //----------------------------------------
      dsCCURFR304T.F304OFL = '0'; // NO ORIGEN

      IF dsLINAEREA.RAAERDES3 <> ' ' AND 
         dsLINAEREA.RAAERDES3 <> '000';
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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF dsLINAEREA.RATIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF01;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF02;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF03;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF04;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF05;

      // Reservado (Libre)
      //----------------------------------------
      dsCCURFR304T.F304LIB = *BLANKS;

      // Graba registro en el historico CCURFR304T
      //------------------------------------------
      Graba_Reg_FR304();
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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
      dsCCURFR304T.F304CTN = %TRIM(dsTRANSAC.GENUMDOC);

      // NUMERO BILLETE CAMBIADO
      //----------------------------------------
      IF RA_TIPDOC <> '1';
        dsCCURFR304T.F304ETN = %TRIM(dsTRANSAC.GENUMDOC);
      ENDIF;

      // Referencias (1-5)
      //----------------------------------------
      dsCCURFR304T.F304C01 = dsTRANSAC.GEREF1;
      dsCCURFR304T.F304C02 = dsTRANSAC.GEREF2;
      dsCCURFR304T.F304C03 = dsTRANSAC.GEREF3;
      dsCCURFR304T.F304C04 = dsTRANSAC.GEREF4;
      dsCCURFR304T.F304C05 = dsTRANSAC.GEREF5;

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
    //                         FINAL DE PROGRAMA                        
    // ====================================================================

  End-proc;
  //---------------------------------------------------------------
  // Grabar registro en CCURFR301T Historico
  //---------------------------------------------------------------
  dcl-proc Genera_Registros_RV_301;

    dcl-pi Genera_Registros_RV_301;

    end-pi;

    Dcl-s RVNUCONT Packed(15:0);
    Dcl-s WRVCOCOALQ Char(2);
    Dcl-s WRVCLASVEH Char(1);
    Dcl-s WRVNOSHOW Char(1);

    // ---------------------------------
    // GRABAR: CCURFR301T
    // ---------------------------------
    Reset dsCCURFR301T;

    // Se busca datos Adicionales para RV en el atrium.Alqcoch
    Exec Sql
      Select RVNUCONT, RVCOCOALQ, RVCLASVEH, RVNOSHOW
      Into :RVNUCONT, :WRVCOCOALQ, :WRVCLASVEH, :WRVNOSHOW
      From Atrium.Alqcoch
      Where
        AGNUMAGE = :dsTRANSAC.AGNUMAGE AND
        HONUMFIC = :dsTRANSAC.HONUMFIC AND 
        GENUMTRA = :dsTRANSAC.GENUMTRA;

    If Sqlcode <> 0;    
      // Graba registro en el historico CCURFR301T
      //------------------------------------------
      Graba_Reg_FR301();
      return;
    EndIf;
    dsCCURFR301T.F301IDR = 301;
    dsCCURFR301T.F301TRN =
        %EDITC(*DATE:'X') + 
        %EDITC(WNUMREAL:'X') + 
        dsTRANSAC.GENUTRAN;

    dsCCURFR301T.F301RAN = %TRIM(dsTRANSAC.GENUMDOC);
    dsCCURFR301T.F301RNA = dsTRANSAC.GEPROOV;

    // Datos Recogida Vehiculo
    dsCCURFR301T.F301PDA = dsTRANSAC.GEFEINSE;
    dsCCURFR301T.F301PCI = dsTRANSAC.GECIUDOR;
    dsCCURFR301T.F301PCO = dsTRANSAC.GEPAISA;

    // Datos Devolucion Vehiculo
    dsCCURFR301T.F301RDA = dsTRANSAC.GEFEFISE;
    dsCCURFR301T.F301RCI = dsTRANSAC.GECIUDES;
    dsCCURFR301T.F301RCO = dsTRANSAC.GEPAILLE;

    // Indicador: No se Presenta
    IF WRVNOSHOW = 'S';
      dsCCURFR301T.F301NSF = '1';
    ELSE;
      dsCCURFR301T.F301NSF = '0';
    ENDIF;

    // Importe por Distancia
    dsCCURFR301T.F301ADU = *ALL'0';

    // Importe por Dia
    dsCCURFR301T.F301DRE = *ALL'0';

    // Importe por Semana
    dsCCURFR301T.F301WRA = *ALL'0';

    // Codigo Clase Vehiculo
    dsCCURFR301T.F301VCC = WRVCLASVEH;

    // Numero de Vehiculo
    dsCCURFR301T.F301NVE = 001;

    // Distancia total del periodo

    dsCCURFR301T.F301TDI = 0;

    // Importe distancia recorrida
    dsCCURFR301T.F301RDC = *ALL'0';

    // Importe distancia extra
    dsCCURFR301T.F301EDR = *ALL'0';

    // Importe devolucion distinta localidad
    dsCCURFR301T.F301OWD = *ALL'0';

    // Importe retraso devolucion vehiculo
    dsCCURFR301T.F301LCH = *ALL'0';

    // Importe carburante
    dsCCURFR301T.F301FCH = *ALL'0';

    // Importe del seguro
    dsCCURFR301T.F301ICH = *ALL'0';

    // Importe Otros
    dsCCURFR301T.F301OCH = *ALL'0';

    // Importe Ajuste
    dsCCURFR301T.F301AAM = *ALL'0';

    // Codigo cargos extra
    dsCCURFR301T.F301ECA = *ALL'0';

    // Referencias (1-5)
    dsCCURFR301T.F301C01 = dsTRANSAC.GEREF01;
    dsCCURFR301T.F301C02 = dsTRANSAC.GEREF02;
    dsCCURFR301T.F301C03 = dsTRANSAC.GEREF03;
    dsCCURFR301T.F301C04 = dsTRANSAC.GEREF04;
    dsCCURFR301T.F301C05 = dsTRANSAC.GEREF05;

    // Graba registro en el historico CCURFR303T
    //------------------------------------------
    Graba_Reg_FR301();

  End-proc;
  //---------------------------------------------------------------
  // Grabar registro en CCURFR200T Historico
  //---------------------------------------------------------------
  dcl-proc Graba_Reg_FR200;

    dcl-pi Graba_Reg_FR200;

    end-pi;

    Dcl-s WCampoOut Char(2580) Inz('');

    %SubSt(WCampoOut:1:2000) = dsCCURFR200T;
    %SubSt(WCampoOut:2413:167) = dsSISGESOPE;

    Exec Sql
      INSERT INTO CONCUR_OUT (CONCUR_OUT)
      VALUES (:WCampoOut);

    // If Sqlcode <> 0;
    //   observacionSql = 'Error al grabar en la tabla CCURFR200T';
    //   Clear Nivel_Alerta;
    //   Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
    // Endif;

  end-proc;
  //---------------------------------------------------------------
  // Grabar registro en CCURFR400T Historico
  //---------------------------------------------------------------
  dcl-proc Graba_Reg_FR400;

    dcl-pi Graba_Reg_FR400;

    end-pi;

    Dcl-s WCampoOut Char(2580) Inz('');

    %SubSt(WCampoOut:1:2000) = dsCCURFR400T;
    %SubSt(WCampoOut:2413:167) = dsSISGESOPE;

    Exec Sql
      INSERT INTO CONCUR_OUT (CONCUR_OUT)
      VALUES (:WCampoOut);

    // If Sqlcode <> 0;
    //   observacionSql = 'Error al grabar en la tabla CCURFR200T';
    //   Clear Nivel_Alerta;
    //   Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
    // Endif;

  end-proc;
  //---------------------------------------------------------------
  // Grabar registro en CCURFR301T Historico
  //---------------------------------------------------------------
  dcl-proc Graba_Reg_FR301;

    dcl-pi Graba_Reg_FR301;

    end-pi;

    Dcl-s WCampoOut Char(2580) Inz('');

    %SubSt(WCampoOut:1:2000) = dsCCURFR301T;
    %SubSt(WCampoOut:2413:167) = dsSISGESOPE;

    Exec Sql
      INSERT INTO CONCUR_OUT (CONCUR_OUT)
      VALUES (:WCampoOut);

    // If Sqlcode <> 0;
    //   observacionSql = 'Error al grabar en la tabla CCURFR200T';
    //   Clear Nivel_Alerta;
    //   Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
    // Endif;

  end-proc;
  //---------------------------------------------------------------
  // Grabar registro en CCURFR303T Historico
  //---------------------------------------------------------------
  dcl-proc Graba_Reg_FR303;

    dcl-pi Graba_Reg_FR303;

    end-pi;

    Dcl-s WCampoOut Char(2580) Inz('');

    %SubSt(WCampoOut:1:2000) = dsCCURFR303T;
    %SubSt(WCampoOut:2413:167) = dsSISGESOPE;

    Exec Sql
      INSERT INTO CONCUR_OUT (CONCUR_OUT)
      VALUES (:WCampoOut);

    // If Sqlcode <> 0;
    //   observacionSql = 'Error al grabar en la tabla CCURFR200T';
    //   Clear Nivel_Alerta;
    //   Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
    // Endif;

  end-proc;
  //---------------------------------------------------------------
  // Grabar registro en CCURFR304T Historico
  //---------------------------------------------------------------
  dcl-proc Graba_Reg_FR304;

    dcl-pi Graba_Reg_FR304;

    end-pi;

    Dcl-s WCampoOut Char(2580) Inz('');

    %SubSt(WCampoOut:1:2000) = dsCCURFR304T;
    %SubSt(WCampoOut:2413:167) = dsSISGESOPE;

    Exec Sql
      INSERT INTO CONCUR_OUT (CONCUR_OUT)
      VALUES (:WCampoOut);

    // If Sqlcode <> 0;
    //   observacionSql = 'Error al grabar en la tabla CCURFR200T';
    //   Clear Nivel_Alerta;
    //   Nivel_Alerta = Diagnostico(Sds.ProgramName:observacionSql);
    // Endif;

  end-proc;
  //---------------------------------------------------------------
  // Genera y Graba Datos Comunes del SISGESOPE
  //---------------------------------------------------------------
  dcl-proc Genera_DatosComunes_SISGESOPE;

    dcl-pi Genera_DatosComunes_SISGESOPE;

    end-pi;

    reset dsSISGESOPE;
    dsSISGESOPE.ONREAL = dsSISGESTAR.TNREAL;
    dsSISGESOPE.OCODSG = dsSISGESTAR.TCODSG;
    dsSISGESOPE.ONAGEN = dsSISGESTAR.TNAGEN;
    dsSISGESOPE.OFENOP = *DATE;
    dsSISGESOPE.OCOPDI = '7';
    dsSISGESOPE.OTSEMI = dsTRANSAC.GETIPRE;
    // determinar cuando va PE o AG para este proceso
    //dsSISGESOPE.OESOPE = 'PE';
    dsSISGESOPE.OESOPE = 'AG';
    // Determinar que referencia grabar 
    dsSISGESOPE.ONDESC = dsTRANSAC.TR_NUMEdsTRANSAC.GETRANSACCION;
    dsSISGESOPE.OFCOOP = 
        %DEC(%DATE(dsTRANSAC.GEFECOMP:*ISO):*EUR);

    If dsTRANSAC.GESIGIMOP='+';
      dsSISGESOPE.OIMPOR = dsTRANSAC.GEIMPOP;
    Else;
      dsSISGESOPE.OIMPOR = dsTRANSAC.GEIMPOP * (-1);
    Endif;  

    dsSISGESOPE.ONUCRU = %Editc(dsTRANSAC.GENUMAUD:'X');
    dsSISGESOPE.OBILLR = dsTRANSAC.GENUMDOC;
    dsSISGESOPE.OFECFA = *ZEROS;
    dsSISGESOPE.ONTRAM = dsTRANSAC.GENUTRAN;
    dsSISGESOPE.ONFIMI = dsTRANSAC.HONUMFIC;

    dsSISGESOPE.OREFOP = 
        %EDITC(*DATE:'X') + 
        %EDITC(WNUMREAL:'X') + 
        dsTRANSAC.GENUTRAN;
  end-proc;
  //---------------------------------------------------------------
  // Calculo de Nuemros Segmentos a Generar
  //---------------------------------------------------------------
  dcl-proc NSEGMENTOS;

    dcl-pi NSEGMENTOS;

    end-pi;

    IF RA_AERSAL1 <> ' ';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES1 <> ' ' AND 
       dsLINAEREA.RAAERDES1 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES2 <> ' ' AND 
       dsLINAEREA.RAAERDES2 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES3 <> ' ' AND 
       dsLINAEREA.RAAERDES3 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES4 <> ' ' AND 
       dsLINAEREA.RAAERDES4 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES5 <> ' ' AND 
       dsLINAEREA.RAAERDES5 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES6 <> ' ' AND 
       dsLINAEREA.RAAERDES6 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES7 <> ' ' AND 
       dsLINAEREA.RAAERDES7 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES8 <> ' ' AND 
       dsLINAEREA.RAAERDES8 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES9 <> ' ' AND 
       dsLINAEREA.RAAERDES9 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES10 <> ' ' AND 
       dsLINAEREA.RAAERDES10 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES11 <> ' ' AND 
       dsLINAEREA.RAAERDES11 <> '000';
      SEGMENTOS += 1;
    ENDIF;

    IF dsLINAEREA.RAAERDES12 <> ' ' AND 
       dsLINAEREA.RAAERDES12 <> '000';
      SEGMENTOS += 1;
    ENDIF;

  end-proc;        