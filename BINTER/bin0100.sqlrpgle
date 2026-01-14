**FREE
  // ------------------------------------------------------------------------
  // - Modulo de BINTER/AMADEUS - Lee y procesa los ficheros de Amadeus
  // - Autor: Ludolfo Montero
  // - Fecha: Marzo 2025
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/BIN0100) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR(BIN0100) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  *
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
    decedit('0,') datedit(*DMY/)
    bnddir('UTILITIES/UTILITIES':'NOXDB':'HTTPAPI':'EXPLOTA/CALDIG')
    dftactgrp(*no) actgrp(*new) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------

  dcl-pr GENDUP extPgm('GENDUP');
    *N      Packed(7:0);
    *N      Packed(1:0) Const;
    *N      Char(1);
  end-pr;
  // --------------------------
  // Cpys y Include
  // --------------------------
  /copy EXPLOTA/QRPGLESRC,BINCPY_H    // Estructuras BINTER
  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
  /COPY   EXPLOTA/QRPGLESRC,UTILITIESH


  /copy EXPLOTA/QRPGLESRC,OPECRTSRVH  // Procedimientos de Operaciones
  /copy EXPLOTA/QRPGLESRC,OPE_DS_COP  // DS Tablas de Operaciones

  // Define para el NOXDB
  /Define UTWSSRV_WEB
  /Include APISDINERS/QRPGLESRC,UTWSSRV_H2
  // --------------------------
  // Declaracion Estructuras
  // --------------------------
  dcl-ds dsAMADEUS_Files      likeDs(dsAMADEUS_FilesTpl) Inz;
  dcl-ds dsAMABINDET          likeDs(dsAMABINDETTpl) Inz;
  dcl-ds dsNMOV               likeDs(dsNmov_tpl) Inz;

  dcl-ds dsFiles_Proc Qualified dim(50) Inz;
    Cod_File    Zoned(10);
    Dsc_File    VarChar(300);
    Tot_Reg_Rec Zoned(5);
    Tot_Proc    Zoned(13:2);
    Tot_Rec     Zoned(13:2);
    Can_Rec     Zoned(5);
  end-ds;

  dcl-ds dsRecord Qualified dim(1000) Inz;
    Cod_File       Zoned(10);
    Num_Tarjeta    VarChar(16);
    NamePassg      VarChar(25);
    DocNumber      VarChar(10);
    Importe        Zoned(13:2);
    Cod_Error      Char(7);
    Dsc_Error      VarChar(200);
  End-Ds;

  // --------------------------
  // Declaracion de Variables Globales
  // --------------------------
  dcl-s WNumEstab     Packed(7:0) Inz(251896);  //Cod. Estab. BINTER
  // Analizar crear tabla de configuracion
  // SGF_Establecimientos_Facturadores
  dcl-s filePath       varchar(256) inz('/usr/AWS-mails/attachment/');
  dcl-s templatesDir   varchar(256) inz('/usr/AWS-mails/html/');
  dcl-s templateName   varchar(256) inz('BinterMadeusFicherosProcesados.html');

  Dcl-S Wcontador     Zoned(6) INZ;
  Dcl-s Wnumref       Zoned(9);
  Dcl-S Wdesde        Zoned(6:0) INZ;
  Dcl-s ID_File       Zoned(10);
  dcl-s I_Fil         Zoned(3) Inz(0);
  Dcl-s Z             Zoned(5) Inz(0);

  dcl-s P_numero_Operacion zoned(13:0);
  dcl-s p_id_fichero       zoned(9:0);

  Dcl-s Duplic             Char(1);
  dcl-s NameFile           VarChar(256);
  dcl-s Content_data       varchar(2000);
  dcl-s subject            char(200);
  dcl-s toEmail          varchar(100);

  dcl-s P_codigo_origen      char(5);
  dcl-s P_tipo_fichero       char(1);
  dcl-s p_file_libreria      char(10);
  dcl-s p_file_nuevo         char(10);
  dcl-s P_Control_Compromiso ind inz(*off);

  dcl-s ErrorRecord          char(7) inz;

  Dcl-S V_Observacion    Char(1000);
  Dcl-S V_Campo          Char(20);
  Dcl-S V_Valor          Char(100);
  Dcl-S V_Srclin         Char(13);
  Dcl-S V_Linea          Char(13);
  Dcl-S V_Time_Stamp     timestamp ;

  dcl-c Euro      const(x'20');
  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *chg,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

  // Solicitudes Pendientes
  Exec Sql declare  C_Header Cursor For
    Select 
      bin.ID_FILE, aut.FileName, Count(*) as cant_reg
    From FICHEROS.AMADEUS_BINTER_INVOICE_FILE_DETAILS bin
    Inner Join Automat.File_IN aut
      On (bin.ID_FILE = aut.ID) 
    Where
      bin.Processed = 0
    Group by bin.ID_FILE, aut.FileName;

  // Solicitudes Pendientes
  Exec Sql declare  C_Detail Cursor For
    SELECT
      IFNULL(ID, 0),
      IFNULL(ID_DEBIT_CREDIT_CODE, ' '),
      IFNULL(AIRLINE_CODE, ' '),
      IFNULL(DOCUMENT_NUMBER, ' '),
      IFNULL(AGENT_IATA_CODE, ' '),
      IFNULL(ISSUE_DATE, '0001-01-01'),
      IFNULL(BILLING_PERIOD, ' '),
      IFNULL(BILLING_MONTH, 0),
      IFNULL(BILLING_YEAR, 0),
      IFNULL(INVOICE_REFERENCE, ' '),
      IFNULL(PASSENGER_NAME, ' '),
      IFNULL(ENTITY_CODE, ' '),
      IFNULL(CREDIT_CARD_NUMBER, 0),
      IFNULL(RESERVED_SPACE_1, ' '),
      IFNULL(CLIENT_REFERENCE, ' '),
      IFNULL(DEBIT_CREDIT_AMOUNT, 0),
      IFNULL(APPROVAL_CODE, ' '),
      IFNULL(SEQUENCE_NUMBER, ' '),
      IFNULL(INVOICE_DATE, '0001-01-01'),
      IFNULL(RESERVED_SPACE_2, ' '),
      IFNULL(CITY_NAME_1, ' '),
      IFNULL(FARE_BASIS_1, ' '),
      IFNULL(CARRIER_1, ' '),
      IFNULL(CLASS_OF_SERVICE_1, ' '),
      IFNULL(CITY_NAME_2, ' '),
      IFNULL(FARE_BASIS_2, ' '),
      IFNULL(CARRIER_2, ' '),
      IFNULL(CLASS_OF_SERVICE_2, ' '),
      IFNULL(CITY_NAME_3, ' '),
      IFNULL(FARE_BASIS_3, ' '),
      IFNULL(CARRIER_3, ' '),
      IFNULL(CLASS_OF_SERVICE_3, ' '),
      IFNULL(CITY_NAME_4, ' '),
      IFNULL(FARE_BASIS_4, ' '),
      IFNULL(CARRIER_4, ' '),
      IFNULL(CLASS_OF_SERVICE_4, ' '),
      IFNULL(CITY_NAME_5, ' '),
      IFNULL(CURRENCY_CODE, ' '),
      IFNULL(CURRENCY_DECIMALS, 0),
      IFNULL(RESERVED_SPACE_3, ' '),
      IFNULL(DESTINATION_CITY, ' '),
      IFNULL(RESERVED_SPACE_4, ' '),
      IFNULL(SUBENTITY_CODE, ' '),
      IFNULL(INVOICE_NUMBER, ' '),
      IFNULL(MERCHANT_NUMBER, ' '),
      IFNULL(EXTENDED_FORM_OF_PAYMENT, ' '),
      IFNULL(EXPIRY_DATE_CREDIT_CARD, ' '),
      IFNULL(COMMISSION, ' '),
      IFNULL(FIRST_FLIGHT_DATE, ' ')
    FROM FICHEROS.AMADEUS_BINTER_INVOICE_FILE_DETAILS
    WHERE ID_FILE = :dsAMADEUS_Files.ID;

  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    dcl-pi *n;
      Pnumtra    Char(3);
      Prandes    Char(6);
      Pranhas    Char(6);
    End-Pi;

    dcl-s CARABO          Packed(1:0) Inz(0);
    dcl-s Parada          Packed(1:0);
    dcl-s Cero            Packed(1:0) Inz(0);
    dcl-s subject         varchar(250);
    dcl-s insuredEmail    varchar(100);
    dcl-s WCrt_File       Ind;

    Wdesde  =  %Dec((Pranhas):6:0);
    Wnumref = %Dec(%Subst(Pnumtra:1:3) + (%Subst(Pranhas:1:6)):9:0);

    GENDUP(WNumEstab:CARABO:DUPLIC);

    Reset dsRecord;

    Exec Sql Open  C_Header;

    sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_Header into :dsAMADEUS_Files;
      If sqlStt <> '00000';
        Leave;
      EndIf;

      //Exec Sql Close  C_Header;

      If Not WCrt_File;
        Crea_File();
        WCrt_File = *On;
      EndIf;

      I_Fil += 1;
      dsFiles_Proc(I_Fil).Cod_File = dsAMADEUS_Files.ID;
      dsFiles_Proc(I_Fil).Dsc_File = dsAMADEUS_Files.Filename;
      dsFiles_Proc(I_Fil).Tot_Reg_Rec = dsAMADEUS_Files.Cant_Reg;
      dsFiles_Proc(I_Fil).Tot_Proc = 0;
      dsFiles_Proc(I_Fil).Tot_Rec  = 0;

      Wcontador = 0;
      If Not Procesa_ANADEUS_Detail(dsAMADEUS_Files.ID);
         // Actualiza Registro Cabecera Fichero (ERROR)
         //Actualiza_Record_File(2);
         Iter;
      EndIf;

      // Actualizacion Registro Cabecera Fichero (Procesado)
      // If Not Actualiza_Record_File(1);
      //   Iter;
      // EndIf;

    enddo;

    Exec Sql Close  C_Header;

    Wdesde = Wdesde + 1;
    Prandes = %Editc(Wdesde:'X');
    Pranhas = %SubSt(%Editc(Wnumref:'X'):4:6);

    iF I_Fil > 0;
      Genera_Adjunto();
      Snd_File_IFS();
      Genera_Content_data();
      Envio_Correo();
    Endif;

  end-proc;
  //-----------------------------------------------------------------
  // Crear fichero temporal para los registros procesados
  //-----------------------------------------------------------------
  dcl-proc Crea_File;

    dcl-pi *n;
    end-pi;

    dcl-s StrCmd         VarChar(256);

    Exec SQL
      CREATE TABLE QTEMP.BIN_REG_PROCESS FOR SYSTEM NAME BINREGPRO
        ( CAMPO_REG      CHAR(300) CCSID 284 DEFAULT ' ')
    ;

    If Sqlcode = -601;
      Exec SQL
        Truncate Table QTEMP.BIN_REG_PROCESS ;
    Else;

    StrCmd =
      'STRJRNPF FILE(QTEMP/BINREGPRO) JRN(FICHEROS/JOURNAL)' ;

    Execute(StrCmd:%Len(%trim(StrCmd)));

    EndIf;

  end-proc;
  //-----------------------------------------------------------------------------
  // Procesa ID File de ANADEUS
  //-----------------------------------------------------------------------------
  dcl-proc Procesa_ANADEUS_Detail;

    dcl-pi *n Ind;
      ID_File     Zoned(10);
    end-pi;

    dcl-s DSC_ERROR   varChar(200);

    P_codigo_origen ='BINTE';
    MONITOR;
      P_tipo_fichero ='N';
      p_file_libreria='FICHEROS';
      OPE_CRT_FILE(P_codigo_origen: P_tipo_fichero: procedureName:
      p_file_libreria : p_file_nuevo : p_id_fichero );

    On-error;
      V_Observacion = 'Adquirencia_BINTER '+ ExceptionData;
      V_Srclin = srcListLineNum;
      V_Time_Stamp = %timeStamp();

      Pgm_Grabamos_error(V_Observacion
                        :V_Campo
                        :V_Valor
                        :PROCEDURENAME
                        :V_Srclin
                        :V_Linea
                        :V_Time_Stamp);
      dump(a);
      Return *Off;
    Endmon;

    Exec Sql Open  C_Detail;
    sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_Detail into :dsAMABINDET;
      If sqlStt <> '00000';
        Leave;
      EndIf;

      Z += 1;
      dsRecord(Z).Cod_File    = dsAMADEUS_Files.ID;
      dsRecord(Z).Num_Tarjeta = %Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X');
      dsRecord(Z).NamePassg   = dsAMABINDET.PASSENGER_NAME;
      dsRecord(Z).DocNumber   = dsAMABINDET.DOCUMENT_NUMBER;
      dsRecord(Z).Importe     = dsAMABINDET.DEBIT_CREDIT_AMOUNT;

      ErrorRecord = '';
      If Not Validar_Record(ErrorRecord);
        dsFiles_Proc(I_Fil).Tot_Rec += dsAMABINDET.DEBIT_CREDIT_AMOUNT;
        dsFiles_Proc(I_Fil).Can_Rec +=1;
        dsRecord(Z).Cod_Error   = ErrorRecord;

        Exec SQL
          Select Descripcion_Error
                    Into :Dsc_Error
                    From TABLA_CODIGOS_ERROR
                    Where codigo_error = trim(:ErrorRecord);
        If SqlCode <> 0;
          Dsc_Error = 'Error no definido';
        Endif;
        dsRecord(Z).Dsc_Error = Dsc_Error;

        // Actualizacion del Registro con el Error
        p_numero_operacion = 0;
        Actualiza_Record_Detail(2:ErrorRecord:p_numero_operacion);
            sqlStt = '00000';
        Iter;

      Else;
        dsFiles_Proc(I_Fil).Tot_Proc += dsAMABINDET.DEBIT_CREDIT_AMOUNT;

        p_numero_operacion =
        GRABA_ADQUIRENCIA_PROPIA(
          P_id_fichero:
          P_codigo_origen :dsNMOV) ;

        // Actualizacion del Registro con el numero de operacion
        if Not Actualiza_Record_Detail(1:ErrorRecord:p_numero_operacion);
           sqlStt = '00000';
           Iter;
        EndIf;
      EndIf;

      Wcontador += 1;
      Wnumref   += 1;

      // Aqui la logica para los NMOV
      Reset dsNMOV;
      Llena_Campos_NMOV();

    enddo;

    Exec Sql Close  C_Detail;

    MONITOR;
      p_tipo_fichero='N';
      OPE_END_FILE (procedureName:
                p_file_nuevo :
                p_id_fichero :
                P_tipo_fichero:
                P_Control_Compromiso
                );

    On-error;
      V_Observacion = 'BINTER_Cierre_Operaciones. '+ ExceptionData;
      V_Srclin = srcListLineNum;
      V_Time_Stamp = %timeStamp();

      Pgm_Grabamos_error(V_Observacion
                          :V_Campo
                          :V_Valor
                          :PROCEDURENAME
                          :V_Srclin
                          :V_Linea
                          :V_Time_Stamp);
      dump(a);
      Return *Off;
    Endmon;

    Return *On;
  end-proc;
  //-----------------------------------------------------------------
  // Validaciones del File de AMADEUS
  //-----------------------------------------------------------------
  dcl-proc Validar_Record;

    dcl-pi *n Ind;
      ErrorRecord     char(7);
    end-pi;

    Dcl-s Wsocio        Zoned(8);
    Dcl-s WExiste_Tarj  Ind Inz(*Off);

    // Wsocio  = %Dec(%Subst(dsAMABINDET.CREDITCARDNUMBER:3:8):8:0);

    // Exec Sql
    //   Select
    //     '1'
    //   Into :WExiste_Tarj
    //   From T_MSOCIO
    //   Where NUREAL = :Wsocio;

    // If SqlCode < 0;
    //   observacionSql = 'Error en lectura de T_MSOCIO. ' +
    //                    'Numero Tarjeta: ' + 
    //                    %Trim(dsAMABINDET.CREDIT_CARD_NUMBER);
    //   Clear Nivel_Alerta;
    //   Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    //   If Nivel_Alerta = 'HI';
    //     *InH1 = *On;
    //     *InLR = *On;
    //     Return *Off;
    //   EndIf;
    //   Return *Off;
    // EndIf;

    // If SqlCode = 100;
    //   observacionSql = 'Tarjeta no existente en T_MSOCIO. ' +
    //                    'Numero Tarjeta: ' + 
    //                    %Trim(dsAMABINDET.CREDIT_CARD_NUMBER);
    //   Clear Nivel_Alerta;
    //   Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    //   ErrorRecord = 'BIN0001';
    //   Return *Off;
    // EndIf;

    // Se valida que no sea Moneda diferente a EUR
    If dsAMABINDET.CURRENCY_CODE<>'EUR';
      // Error existen operaciones en Moneda Extranjera
      ErrorRecord = 'BIN0002';
      Return *Off;
    EndIf;

    Return *On;

  end-proc;
  // //-----------------------------------------------------------------
  // // Actualiza Registro AMADEUS_BINTER_INVOICE_FILES
  // //-----------------------------------------------------------------
  // dcl-proc Actualiza_Record_File;

  //   dcl-pi *n Ind;
  //     Cod_Proc  Zoned(2) Const;
  //   end-pi;

  //   Exec Sql
  //     Update AMADEUS_BINTER_INVOICE_FILES
  //     Set
  //       PROCESSED = :Cod_Proc,
  //       UPDATE_DATE = current timestamp
  //     Where
  //       ID = :dsAMADEUS_Files.ID
  //   ;

  //   If Sqlcode < 0;
  //     observacionSql = 'Error en el Update del AMADEUS_BINTER_INVOICE_FILES';
  //     Clear Nivel_Alerta;
  //     Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
  //     If Nivel_Alerta = 'HI';
  //       *InH1 = *On;
  //       *InLR = *On;
  //       Return *Off;
  //     EndIf;
  //     Return *Off;
  //   EndIf;

  //   Return *On;

  // end-proc;
  //-----------------------------------------------------------------
  // Actualiza Registro
  //-----------------------------------------------------------------
  dcl-proc Actualiza_Record_Detail;

    dcl-pi *n Ind;
      Cod_Proc  Zoned(2) Const;
      Cod_Err   Char(7);
      Num_Oper  Zoned(13:0);
    end-pi;

    // Actualizacion del Registro con el numero de operacion
    Exec Sql
      Update AMADEUS_BINTER_INVOICE_FILE_DETAILS
      Set
        OPERATION_NUMBER = :Num_Oper,
        PROCESSED    = :Cod_Proc,
        UPDATE_DATE  = Current TimeStamp,
        ERROR_CODE = :Cod_Err
      Where
        ID = :dsAMABINDET.ID
    ;
    If Sqlcode < 0;
      observacionSql = 'Error en el Update del AMADEUS_BINTER_INVOICE_FILE_DETAILS';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      If Nivel_Alerta = 'HI';
        *InH1 = *On;
        *InLR = *On;
        Return *Off;
      EndIf;
      Return *Off;
    EndIf;

    Return *On;

  end-proc;
  //-----------------------------------------------------------------------------
  // Llena los Campos del NMOV
  //-----------------------------------------------------------------------------
  dcl-proc Llena_Campos_NMOV;

    dcl-pi *n;
    end-pi;

    Dcl-s WCodAct       Char(2);
    Dcl-s Wsocio        Zoned(8);
    Dcl-s Wciclo        Zoned(6);
    Dcl-s WPais         packed(3:0);
    Dcl-s WSDUPEX       Char(1);
    Dcl-s WSTVPER       Char(2);
    Dcl-s WSPLAST       Char(1);
    Dcl-s WDIGEST       Packed(1:0);
    Dcl-s Num1          Zoned(10);
    Dcl-s Alf1          Char(10);
    Dcl-s Alf2          Char(2);

    // 36111540800334   Socio=11154080  Ciclo=611154
    // determina Tarjeta y numero de SOCIO
    Wsocio  = %Dec(%Subst(
        %Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X')
              :3:8):8:0);
    Wciclo  = %Dec(%Subst(%Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X')
              :2:6):6:0);

    Exec Sql
      SELECT CPAIRE
      Into :WPais
      FROM FICHEROS.CICLOS
      WHERE CICLO  = :Wciclo
      ORDER BY CICLO
      Limit 1;

    If SqlCode <> 0;
      WPais = 0;
    EndIf;

    dsNMOV.VCPO2  = 'N ';
    If dsAMABINDET.ID_DEBIT_CREDIT_CODE = '22';
      dsNMOV.VNEGAT = '0';
    Else;
      dsNMOV.VNEGAT = '1';
    EndIf;

    dsNMOV.VLIBR1 = '  611';

    Exec Sql
      Select Digits(EACTPR), EDIG
      Into :WCodAct, :WDIGEST
      From ESTA1
      Where NUMEST = :WNumEstab;

    If SqlCode <> 0;
      // Que hacer si no existe
    EndIf;

    Exec Sql
      Select
        SDUPEX, STVPER, SPLAST
      Into :WSDUPEX, :WSTVPER, :WSPLAST
      From T_MSOCIO
      Where NUREAL = :Wsocio;

    If SqlCode <> 0;
      // Que pasa si no es una tarjeta de DIner;
    EndIf;

    dsNMOV.VLIBR1 = %REPLACE(WCodAct:dsNMOV.VLIBR1:3:2);
    IF WPais = 999 And
      WSDUPEX = 'V' And
      WSTVPER = ' ' And
      WSPLAST = ' ';
      dsNMOV.VLIBR1 = %REPLACE('V':dsNMOV.VLIBR1:1:1);
    ENDIF;
    IF dsAMABINDET.ID_DEBIT_CREDIT_CODE <> '11';
      dsNMOV.VLIBR1 = %REPLACE('2':dsNMOV.VLIBR1:5:1);
    ENDIF;

    dsNMOV.VNESTA = WNumEstab;
    dsNMOV.VDIGIT = WDIGEST;
    dsNMOV.VDUPLI = DUPLIC;
    dsNMOV.VCODRE = '7';
    dsNMOV.VNUSO  = 0;
    dsNMOV.VADICI = ' '; // veirificar que otros valores
    dsNMOV.VIMPOR = %Int(dsAMABINDET.DEBIT_CREDIT_AMOUNT * 100);
    If dsAMABINDET.ID_DEBIT_CREDIT_CODE = '22';
      dsNMOV.VIMPOR = dsNMOV.VIMPOR * (-1);
    EndIf;

    //dsAMABINDET.INVOICEDATE = '2025-03-01';
    dsNMOV.VFECON =
      %Dec(
      (%SubSt(%Editc(%dec(dsAMABINDET.INVOICE_DATE: *ISO):'X'):7:2) +
       %SubSt(%Editc(%dec(dsAMABINDET.INVOICE_DATE: *ISO):'X'):5:2) +
       %SubSt(%Editc(%dec(dsAMABINDET.INVOICE_DATE: *ISO):'X'):3:2)):6:0)
      ;
    dsNMOV.VDICON = *Day;
    dsNMOV.VCPO3  = '';
    dsNMOV.VNUREG = Wcontador;
    dsNMOV.VCPO7  = '';
    dsNMOV.VNEST1 = WNumEstab;  //TRANSAC.GENUCOPV
    dsNMOV.VCPO7X = '';
    dsNMOV.VPTLLA = 'Z';
    dsNMOV.VCPO77 = '';
    dsNMOV.VIRREG = 'K       ';
    dsNMOV.VPAIS  = WPais;
    dsNMOV.VEUROS = 0;
    dsNMOV.VNUREF = Wnumref;
    dsNMOV.VSEDOL = '';
    dsNMOV.VMICRO = '';
    dsNMOV.VNUPRO = 0;
    dsNMOV.VTIPRO = '';
    dsNMOV.VMOTVO = '';
    dsNMOV.VNUMTF = %Trim(dsAMABINDET.APPROVAL_CODE); //Codigo de Aprobacion
    dsNMOV.VNUBIL = dsAMABINDET.DOCUMENT_NUMBER; // Numero de Billete
    dsNMOV.VMONED = '0';
    dsNMOV.VNOPRE = '';
    dsNMOV.VNREEM = '';
    dsNMOV.VTARJE = %Char(dsAMABINDET.CREDIT_CARD_NUMBER);
    dsNMOV.VPUREN = '';
    dsNMOV.VSUREN = '';
    dsNMOV.VBIREN = '';
    dsNMOV.VAGENC = 0;
    dsNMOV.VMMSS  = '';

    sqlStt = '00000';
    SqlCode = 0;

  end-proc;
  //-----------------------------------------------------------------------------
  // Genera Fichero Adjunto
  //-----------------------------------------------------------------------------
  dcl-proc Genera_Adjunto;

    dcl-pi *n;
    end-pi;

    Dcl-s I             Zoned(5);
    Dcl-s WReg         VarChar(300);

    Wreg = 'DINERS CLUB SPAIN';
    Exec Sql
      Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;

    Wreg = ' ';
    Exec Sql
      Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;


    Wreg = 'TRANSACCIONES PROCESADAS BINTER-AMADEUS';
    Exec Sql
      Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;

    Wreg = ' ';
    Exec Sql
      Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;

    Wreg =
      'CODIGO FICHERO;NUMERO DE TARJETA;NOMBRE DEL PASAJERO;NUMERO DE DOCUMENTO;IMPORTE;' +
      'CODIGO ERROR;DESCRIPCION ERROR';
    Exec Sql
        Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;

    // Wreg = ' ';
    // Exec Sql
    //   Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;

    For I = 1 to Z;
      Wreg =
        %Editc(dsRecord(I).Cod_File:'X')      + ';' +
        %Trim(dsRecord(I).Num_Tarjeta)        + ';' +
        %Trim(dsRecord(I).NamePassg)          + ';' +
        %Trim(dsRecord(I).DocNumber)          + ';' +
        %Editc(dsRecord(I).Importe:'2')       + ';' +
        %trim(dsRecord(I).Cod_Error)          + ';' +
        %Trim(dsRecord(I).Dsc_Error);
      Exec Sql
        Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;
    EndFor;

  End-Proc;
  //-----------------------------------------------------------------------------
  // Envio de Fichero al IFS
  //-----------------------------------------------------------------------------
  dcl-proc Snd_File_IFS;
    dcl-pi *n;
    end-pi;

    dcl-s StrCmd         VarChar(1000);

    dcl-s Longitud       Packed(15:5);

    NameFile = 'BINREGPRO_' + %Char(%TimeStamp()) + '.CSV';

    StrCmd =
      'CPYTOIMPF '                                 +
      'FROMFILE(QTEMP/BINREGPRO) '                 +
      'TOSTMF(' + WComi + %Trim(filePath)           +
      %Trim(NameFile) + WComi + ') '               +
      'MBROPT(*REPLACE) '                          +
      'FROMCCSID(285) '                            +
      'STMFCODPAG(*PCASCII) '                      +
      'STMFAUT(*INDIR) '                           +
      'RCDDLM(*CRLF) '                             +
      'DTAFMT(*DLM) '                              +
      'STRDLM(*NONE) '                             +
      'RMVBLANK(*BOTH) '                           +
      'FLDDLM(' + WComi + ';' + WComi + ') '       +
      'DECPNT(*COMMA) '
    ;

    Longitud = %len(%trimr(StrCmd));
    Execute(StrCmd:Longitud);

  End-Proc;
  //-----------------------------------------------------------------------------
  // Genera el Content_data para el Correo
  //-----------------------------------------------------------------------------
  dcl-proc Genera_Content_data;
    dcl-pi *n;
    end-pi;

    Dcl-s I             Zoned(5);
    dcl-s StrData       VarChar(2000);

    For I = 1 to I_Fil;
      StrData = %Trim(StrData) + '<tr>' +
      '<td style="text-align: center;">' + %Char(dsFiles_Proc(I).Cod_File)            + '</td>' +
      '<td style="text-align: left;">' + %Trim(dsFiles_Proc(I).Dsc_File)              + '</td>' +
      '<td style="text-align: right;">' + %Editc(dsFiles_Proc(I).Tot_Proc:'2') + Euro + '</td>' +
      '<td style="text-align: right;">' + %Editc(dsFiles_Proc(I).Tot_Rec:'2')  + Euro + '</td>' +
      '<td style="text-align: center;">' + %Editc(dsFiles_Proc(I).Can_Rec:'2')        + '</td>' +
      '</tr>';
    EndFor;

    Content_data = %trim(StrData);

  End-Proc;
  //-----------------------------------------------------------------------------
  // Arma Envio_Correo
  //-----------------------------------------------------------------------------
  dcl-proc Envio_Correo;
    dcl-pi *n;
    end-pi;

    // Declare email variables
    dcl-s url                     varchar(256);

    dcl-s request                 pointer;
    dcl-s requestStr              varchar(4000000);
    dcl-s response                pointer;
    dcl-s responseStr             varchar(10000);

    dcl-s templatePath            varchar(256);
    dcl-s templateBase64          sqltype(clob : 6000000);
    dcl-s attachmentArr           pointer;
    dcl-s attachment              pointer;
    dcl-s parameters              pointer;
    dcl-s SysName                 VarChar(10);
    dcl-s Email_DES               VarChar(100) inz;
    dcl-s Email_CC                VarChar(100) inz;
    dcl-s Email_CCO               VarChar(100) inz;

    subject = 'BINTER-AMADEUS Ficheros Procesados';
    Email_DES = '';
    Email_CC  = '';
    Email_CCO = '';
    Obtener_email('BIN0100':Email_DES:Email_CC:Email_CCO);

    request = json_newObject();

    JSON_SetStr( request : 'to' : %Trim(Email_DES) );
    If Email_CC <> '';
      JSON_SetStr( request : 'cc' : %Trim(Email_CC) );
    EndIf;
    If Email_CCO <> '';
      JSON_SetStr( request : 'bcc' : %Trim(Email_CCO) );
    EndIf;

    JSON_SetStr( request : 'subject' : subject );

    // Get template
    templatePath = %concat('' : templatesDir : templateName);
    exec sql values(qsys2.base64_encode(
                (select line from table (
                  qsys2.ifs_read_binary(
                    path_name => trim(:templatePath) )))))
                    into :templateBase64;

    JSON_SetBool( request : 'html_is_base64' : *ON );
    JSON_SetStr( request : 'html' : %trimr(templateBase64_data));

    // Si hay HTML con parametros se activa
    JSON_SetBool( request : 'has_parameters' : *ON );

    parameters = json_newObject();
    JSON_SetStr( parameters : 'contentData' : Content_data );

    json_MoveObjectInto(request : 'parameters' : parameters);

    // Activacion del attachment
    JSON_SetBool( request : 'has_attachment' : *ON );

    // Crea arreglo para los attachments
    attachmentArr = json_NewArray();

    // crear objeto que contiene los datos del Attachment
    attachment = json_newObject();
    JSON_SetStr( attachment : 'path' : %trim(filePath) + %trim(NameFile) );
    JSON_SetStr( attachment : 'filename' : %trim(NameFile) );

    // Adiciona Objecto Attachment al Arreglo de Attachment
    json_arrayPush(attachmentArr : attachment : json_COPY_CLONE);

    // Adiciona Arrglo (JSON) al JSON request
    json_MoveObjectInto(request : 'attachments' : attachmentArr);

    // Determinar si es Desarrollo o Produccion
    Exec SQL
      Set :SysName = Trim(GET_HOST_NAME())
    ;

    If SysName = 'GORDO';
      url = 'https://qpx1h8rqwg.execute-api.eu-west-1.amazonaws.com/v1/emails/send';
    Else;
      url = 'https://r7ahklz5q0.execute-api.eu-west-1.amazonaws.com/v1/emails/send';
    Endif;

    requestStr = json_asJsonText(request); // TRANSFORMAMOS EL BODY A TEXTO

    http_setOption('local-ccsid': '0');
    http_setOption('network-ccsid': '1208');

    monitor;
      responseStr = http_string('POST': url: requestStr: 'application/json');
    on-error;
      dsply ('Error en llamada http_string');
      //Envio_Correo_Interno();
    endmon;
    response = json_parseString(responseStr);

    json_delete(request);
    json_delete(response);

  end-proc;
  // ********************************************************************
  // ENVIO CORREO
  // ********************************************************************
  dcl-proc Obtener_email;

    dcl-pi *n Ind;
      ProceName   Char(7) const;
      Email_DES    VarChar(100);
      Email_CC     VarChar(100);
      Email_CCO    VarChar(100);
    end-pi;

    Dcl-s Wtipo char (3);
    dcl-s Wmail char (100);
    Dcl-s Separador1  Ind Inz(*Off);
    Dcl-s Separador2  Ind Inz(*Off);
    Dcl-s Separador3  Ind Inz(*Off);

    // Email registrados por programa
    Exec Sql
      Declare  C_email Cursor For
      Select
        TIPO, MAIL
      From FICHEROS.V_MAILS_POR_PROGRAMA_1
      Where
        NOMBRE_PROGRAMA='BIN0100'
      Order by tipo, mail;

    Exec Sql Open  C_email;

    //sqlStt = '00000';
    dow Sqlcode = 0;
      Exec Sql Fetch From  C_email into :Wtipo, :Wmail;
      If Sqlcode <> 0;
        Leave;
      EndIf;

      Select;
        When Wtipo = 'DES';
          If Separador1;
            Email_DES = %Trim(Email_DES) + ';';
          EndIf;
          Email_DES = %Trim(Email_DES) + %Trim(Wmail);
          Separador1 = *On;
        When Wtipo = 'CC';
          If Separador2;
            Email_CC  = %Trim(Email_CC) + ';';
          EndIf;
          Email_CC  = %Trim(Email_CC) + %Trim(Wmail);
          Separador2 = *On;
        When Wtipo = 'CCO';
          If Separador3;
            Email_CCO = %Trim(Email_CCO) + ';';
          EndIf;
          Email_CCO = %Trim(Email_CCO) + %Trim(Wmail);
          Separador3 = *On;
      EndSl;

    Enddo;

    Exec Sql Close  C_email;

    Return *On;
  end-proc;
