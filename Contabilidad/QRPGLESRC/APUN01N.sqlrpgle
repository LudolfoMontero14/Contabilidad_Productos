**FREE
  // ------------------------------------------------------------------------
  // - Modulo procesamiento de ficheros de Internacional (IMOV)
  // - Autor: Ludolfo Montero
  // - Fecha: Febrero 2026
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/APUN01N) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR(APUN01N) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  *
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
    decedit('0,') datedit(*DMY/)
    bnddir('UTILITIES/UTILITIES':'CONTBNDDIR')
    dftactgrp(*no) actgrp(*new) main(main);

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------


  // --------------------------
  // Cpys y Include
  // --------------------------
  /Define Funciones_CONTABSRV
  /Define PGM_ASBUNU
  /Define Estructuras_Asientos_Evidencias
  /define Common_Variables
  /Include Explota/QRPGLESRC,CONTABSRVH

  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

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
    Num_Tarjeta    VarChar(19);
    NamePassg      VarChar(25);
    DocNumber      VarChar(10);
    Txn_Code       Char(2);
    Importe        Zoned(13:2);
    Cod_Error      Char(7);
    Dsc_Error      VarChar(200);
  End-Ds;

  // --------------------------
  // Declaracion de Variables Globales
  // --------------------------
  dcl-s WNumEstab     Packed(7:0);  //Cod. Estab. BINTER
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

  Dcl-S WTarj_Si_14      Ind;
  Dcl-s Wsocio        Zoned(8);
  dcl-s Wtarjeta      Char(16);

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
      IFNULL(APPROVAL_CODE, '          '),
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
      IFNULL(MERCHANT_NUMBER, 0),
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
         Iter;
      EndIf;

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
    dcl-s P_Tarjeta   Char(19);

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

      Wtarjeta = %Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X');

      P_Tarjeta = ' ';
      If %Subst(Wtarjeta:1:2) = '00';
         %SubSt(P_Tarjeta:1:14) = %Subst(Wtarjeta:3:14);
      Else;  
         %SubSt(P_Tarjeta:1:16) = Wtarjeta;
      Endif;  

      If Not PCISRV_MaskPan(P_Tarjeta);
        dsRecord(Z).Num_Tarjeta = %Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X');
      else;
        dsRecord(Z).Num_Tarjeta = %Trim(P_Tarjeta);
      Endif;  

      dsRecord(Z).Cod_File    = dsAMADEUS_Files.ID;
      
      dsRecord(Z).NamePassg   = dsAMABINDET.PASSENGER_NAME;
      dsRecord(Z).DocNumber   = dsAMABINDET.DOCUMENT_NUMBER;
      dsRecord(Z).Txn_Code    = dsAMABINDET.ID_DEBIT_CREDIT_CODE;
      If dsAMABINDET.ID_DEBIT_CREDIT_CODE = '22';
        dsRecord(Z).Importe     = dsAMABINDET.DEBIT_CREDIT_AMOUNT * (-1);
      Else;
        dsRecord(Z).Importe     = dsAMABINDET.DEBIT_CREDIT_AMOUNT;
      EndIf;

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

      Wcontador += 1;
      Wnumref   += 1;

      // Aqui la logica para los NMOV
      Reset dsNMOV;
      Llena_Campos_NMOV();
      Graba_datos_adicionales();
      p_numero_operacion =
        GRABA_ADQUIRENCIA_PROPIA(
          P_id_fichero:
          P_codigo_origen :dsNMOV);
          Genera_DescrFac();

        // Actualizacion del Registro con el numero de operacion
        if Not Actualiza_Record_Detail(1:ErrorRecord:p_numero_operacion);
           sqlStt = '00000';
           Iter;
        EndIf;
      EndIf;

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

    Dcl-s WPais_Bin     Zoned(3);
    Dcl-s WStatus       Packed(1);
    dcl-s Wexiste_Estab Ind Inz(*Off);
    dcl-s Wexiste_Bin   Ind Inz(*Off);
    dcl-s Wexiste_Tarj  Ind Inz(*Off);
    dcl-s Wtarj_8       Char(8);
    dcl-s Wtarj_6       Char(6);
    dcl-s WPAN          Char(50);
    dcl-s WDC_Ent       Char(1);
    dcl-s WDC_Cal       Char(1);
    Dcl-s Wfec_Baj_Est  Zoned(6);

    // Se valida que no sea Moneda diferente a EUR
    If dsAMABINDET.CURRENCY_CODE<>'EUR';
      // Error existen operaciones en Moneda Extranjera
      ErrorRecord = 'BIN0002';
      Return *Off;
    EndIf;

    WNumEstab = 0;

    // Se valida el FUC y el codigo de Establecimiento
    Exec Sql
      SELECT FNEPAG 
      Into :WNumEstab
      FROM PRICEFUC
      Where
        FNUFUC <> ' '
        AND dec(FNUFUC, 9, 0) = :dsAMABINDET.MERCHANT_NUMBER;

    If Sqlcode < 0;
      observacionSql = 'Error en lectura de PRICEFUC para FUC ' +
                       %Char(dsAMABINDET.MERCHANT_NUMBER);
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      If Nivel_Alerta = 'HI';
        *InH1 = *On;
        *InLR = *On;
        Return *Off;
      EndIf;
      Return *Off;
    EndIf;

    If Sqlcode = 100;
      // Error FUC no valido
      ErrorRecord = 'BIN0003';
      Return *Off;
    EndIf;

    // Se valida codigo de Establecimiento
    Exec Sql
      Select '1', EFBAJA
      Into :Wexiste_Estab, :Wfec_Baj_Est    
      From ESTA1
      Where NUMEST = :WNumEstab;

    If SqlCode <> 0;
      // Error Codigo de Establecimiento no valido
      ErrorRecord = 'BIN0004';
      Return *Off;
    EndIf;

    If Wfec_Baj_Est <> 0;
      // Error Codigo de Establecimiento esta dado de baja
      ErrorRecord = 'BIN0010';
      Return *Off;
    EndIf;

    // validación del BIN de la tarjeta
    Wtarj_6  = %Subst(%Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X'):3:6);
    Wtarj_8  = %Subst(%Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X'):1:8);

    // Se busca BIN de 6 digitos
    Wexiste_Bin = *Off;
    Exec Sql
      Select '1', PAIS_RECAP
      Into :Wexiste_Bin, :WPais_Bin
      From BINES
      Where BINES_DOCHOC = :Wtarj_6;

    If Not Wexiste_Bin oR SqlCode = 100;
      // Se busca BIN de 8 digitos
      Wexiste_Bin = *Off;
      Exec Sql
        Select '1', PAIS_RECAP
        Into :Wexiste_Bin, :WPais_Bin
        From BINES
        Where BINES_DOCHOC = :Wtarj_8;

      If SqlCode = 0 Or Not Wexiste_Bin;
        // Error BIN no valido
        ErrorRecord = 'BIN0005';
        Return *Off;
      EndIf;
    EndIf;

    // Validación del Digito Verificador
    // Tarjeta de 14 Digitos
    WTarj_Si_14 = *Off;
    If %Subst(Wtarjeta:1:2) = '00';
      WTarj_Si_14 = *On;
      WPAN = %Subst(Wtarjeta:3:13);
      WDC_Cal = cryGe_getValidDigit(%trim(WPAN));
      WDC_Ent = %Subst(Wtarjeta:15:1);
      Wsocio  = %Dec(%Subst(
        %Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X')
            :5:8):8:0);
    Else;
      // Tarjeta de 16 Digitos
      WDC_Cal = cryGe_getValidDigit(%trim(Wtarjeta));
      Wsocio  = %Dec(%Subst(
        %Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X')
            :3:8):8:0);
    Endif;    

    If WDC_Cal <> %Subst(Wtarjeta:16:1);
      // Error BIN no valido
      ErrorRecord = 'BIN0006';
      Return *Off;
    Endif;

    // Si es Tarjeta Propia
    If WPais_Bin = 999;
      // Se valida Si existe en CARDVAULT
      Exec Sql
        Select '1'
        Into :Wexiste_Tarj    
        From Atrium.CARDVAULT
        Where Trim(V_PAN) = Trim(Char(:dsAMABINDET.CREDIT_CARD_NUMBER))
        Limit 1;

      If SqlCode <> 0;
        // Error Tarjeta no existe en CARDVAULT
        ErrorRecord = 'BIN0007';
        Return *Off;
      EndIf;      

      // Se valida tarjeta en el MSOCIO
      Exec Sql
        Select '1', Status
        Into :Wexiste_Tarj, :WStatus    
        From T_MSOCIO
        Where NUREAL = :Wsocio;

      If SqlCode = 100 Or Not Wexiste_Tarj;
        // Error Tarjeta Propia no existe en MSOCIO
        ErrorRecord = 'BIN0008';
        Return *Off;
      EndIf;      

      If Wexiste_Tarj and WStatus <> 0;
        // Error Tarjeta Propia esta Inactiva
        ErrorRecord = 'BIN0009';
        Return *Off;
      EndIf;      

    EndIf;

    Return *On;

  end-proc;
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
              :5:8):8:0);
    Wciclo  = %Dec(%Subst(%Editc(dsAMABINDET.CREDIT_CARD_NUMBER:'X')
              :3:6):6:0);

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
    If dsAMABINDET.ID_DEBIT_CREDIT_CODE = '11';
      dsNMOV.VNEGAT = '0';
    Else;
      dsNMOV.VNEGAT = '1';
    EndIf;

    dsNMOV.VLIBR1 = '  61 ';

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
    // IF dsAMABINDET.ID_DEBIT_CREDIT_CODE <> '11';
    //   dsNMOV.VLIBR1 = %REPLACE('2':dsNMOV.VLIBR1:5:1);
    // ENDIF;

    dsNMOV.VNESTA = WNumEstab;
    dsNMOV.VDIGIT = WDIGEST;
    dsNMOV.VDUPLI = DUPLIC;
    dsNMOV.VCODRE = '7';
    dsNMOV.VNUSO  = 0;
    dsNMOV.VADICI = '1'; 
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
    dsNMOV.VNEST1 = WNumEstab;  
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
    dsNMOV.VNUMTF = %Subst(dsAMABINDET.APPROVAL_CODE:2:5); //Codigo de Aprobacion
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
      'CODIGO FICHERO;NUMERO DE TARJETA;NOMBRE DEL PASAJERO;NUMERO DE DOCUMENTO;'+
      'CODIGO TRANSACCION; IMPORTE;CODIGO ERROR;DESCRIPCION ERROR';
    Exec Sql
        Insert Into QTEMP.BIN_REG_PROCESS VALUES(:WReg) ;

    For I = 1 to Z;
      Wreg =
        %Editc(dsRecord(I).Cod_File:'X')      + ';' +
        %Trim(dsRecord(I).Num_Tarjeta)        + ';' +
        %Trim(dsRecord(I).NamePassg)          + ';' +
        %Trim(dsRecord(I).DocNumber)          + ';' +
        %Trim(dsRecord(I).Txn_Code)           + ';' +
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
      '<td style="padding:10px 8px; border:1px solid #d9d9d9;">' + 
            %Char(dsFiles_Proc(I).Cod_File)            + '</td>'   +
      '<td style="padding:10px 8px; border:1px solid #d9d9d9;">' + 
            %Trim(dsFiles_Proc(I).Dsc_File)              + '</td>' +
      '<td style="padding:10px 8px; border:1px solid #d9d9d9; text-align:right;">' + 
            %Editc(dsFiles_Proc(I).Tot_Proc:'2') + Euro + '</td>'  +
      '<td style="padding:10px 8px; border:1px solid #d9d9d9; text-align:right;">' + 
            %Editc(dsFiles_Proc(I).Tot_Rec:'2')  + Euro + '</td>'  +
      '<td style="padding:10px 8px; border:1px solid #d9d9d9; text-align:right;">' + 
            %Editc(dsFiles_Proc(I).Can_Rec:'2')        + '</td>'   +
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
    Obtener_email('APUN01N':Email_DES:Email_CC:Email_CCO);

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
        NOMBRE_PROGRAMA='APUN01N'
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
  // ********************************************************************
  // Graba_datos_adicionales
  // ********************************************************************
  dcl-proc Graba_datos_adicionales;

    EXEC Sql
      INSERT INTO OPERACIONES_LIQUIDACION_DATOS_ADICIONALES
        (NUMERO_OPERACION, AUT_NUMERO_AUTORIZACION, REFERENCIA_CREACION,
        FLQ_NUMERO_FACTURA_PROVEEDOR,  REF_ESTA,
        FLQ_NUMERO_BILLETE_PROVEEDOR,  FLQ_REFERENCIA_COMERCIO)
        values(-1, :dsAMABINDET.APPROVAL_CODE  ,
        :Wnumref,
        :dsAMABINDET.INVOICE_NUMBER , :dsAMABINDET.DOCUMENT_NUMBER,
        :dsAMABINDET.DOCUMENT_NUMBER, :dsAMABINDET.DOCUMENT_NUMBER) ;

  end-proc;
  // ********************************************************************
  // Genera_DescrFac
  // ********************************************************************
  dcl-proc Genera_DescrFac;

    dcl-pi *n;
    end-pi;

  dcl-s wnombre varchar(100);
  dcl-s wagente zoned(9);
  dcl-s wcodcia char(2);
  dcl-c C_ESPFEE  CONST('SERVICE FEE N.BILL: ');
  dcl-ds DsDescrFac qualified ;
    gkey packed(9);
    gpais zoned(3);
    glibr1 char(1);
    gpurge packed(9);
    grefin char(8);
    glin1 char(59);
    glin2 char(59);
    gnomes char(32);
    gloces char(26);
    gdesch char(40);
    gnumso packed(8);
    gcinta char(150);
    grefus char(15);
    gisoma char(15);
    glin3 char(59);
    gactin zoned(3);
  end-ds;

    DsDescrFac.gkey = Wnumref;
    DsDescrFac.gpais = dsNMOV.VPAIS;
    DsDescrFac.glibr1 = '';
    DsDescrFac.gpurge =  %DEC(%DATE():*ISO);
    DsDescrFac.grefin = '';
    If  DsDescrFac.gpais= 999;
      clear wnombre;
     //recupera nombre de agente
     wagente =  %Dec((dsAMABINDET.agent_iata_code):9:0);
     exec sql
      select RDESCR
       INTO :WNombre
      from iata
       where Rkey = :wagente;
       // si no existe nombre establecimiento
       if sqlcode <> 0 ;
       exec sql
        select  ENOMBR
         into :Wnombre
         From ESTA1
         Where NUMEST = :dsNMOV.VNESTA;
        endif;
      clear wcodcia;
        exec sql
        select BIDCIA
        into :wcodcia
        from  BSPCIAS
        where bnucia=:dsAMABINDET.AIRLINE_CODE;


      DsDescrFac.glin1=wnombre;
      DsDescrFac.glin2=dsAMABINDET.agent_iata_code+'/'+
      wcodcia+dsAMABINDET.document_number+'-'+
      dsAMABINDET.invoice_number;
      DsDescrFac.glin3=dsAMABINDET.PASSENGER_NAME;
       DsDescrFac.gcinta='';
    else;
      DsDescrFac.glin1='';
      DsDescrFac.glin2='';
      DsDescrFac.glin3='';
      // Contruye campo para interchain concetando otros campos
      DsDescrFac.gcinta='';
       // Compañia 3 primeras posiciones
      if dsAMABINDET.AIRLINE_CODE <>'';
        %subst(DsDescrFac.gcinta:1:3) =
        dsAMABINDET.AIRLINE_CODE;
      else;
       %subst(DsDescrFac.gcinta:1:3) = '000';
      endif;
      if dsAMABINDET.DOCUMENT_NUMBER <>'';
        %subst(DsDescrFac.gcinta:4:10) =
         dsAMABINDET.DOCUMENT_NUMBER;
      endif;
       %subst(DsDescrFac.gcinta:14:1) = '0';
      if dsAMABINDET.CITY_NAME_1  <>'';
        %subst(DsDescrFac.gcinta:15:3) =
          dsAMABINDET.CITY_NAME_1 ;
      endif;
      if dsAMABINDET.CITY_NAME_2  <>'';
        %subst(DsDescrFac.gcinta:18:3) =
         dsAMABINDET.CITY_NAME_2 ;
      endif;
      if dsAMABINDET.CITY_NAME_3  <>'';
        %subst(DsDescrFac.gcinta:21:3) =
        dsAMABINDET.CITY_NAME_3 ;
      endif;
      if dsAMABINDET.CITY_NAME_4  <>'';
        %subst(DsDescrFac.gcinta:24:3) =
         dsAMABINDET.CITY_NAME_4;
      endif;
      if dsAMABINDET.CITY_NAME_5  <>'';
        %subst(DsDescrFac.gcinta:27:3) =
         dsAMABINDET.CITY_NAME_5 ;
      endif;
      if dsAMABINDET.PASSENGER_NAME   <>'';
        %subst(DsDescrFac.gcinta:78:25) =
         dsAMABINDET.PASSENGER_NAME  ;
      endif;

    endif;
    DsDescrFac.gloces='';
    DsDescrFac.gnomes='';
    DsDescrFac.gdesch=''; //factura para microficha
    DsDescrFac.gnumso= Wsocio;
    DsDescrFac.grefus='';
    DsDescrFac.gisoma=dsAMABINDET.document_number;
    DsDescrFac.gactin=500;//????????????????

    exec sql
    INSERT INTO FICHEROS.DESCRFAC (
      GKEY, GPAIS,  GLIBR1,  GPURGE,  GREFIN,  GLIN1,
      GLIN2, GNOMES, GLOCES,  GDESCH,  GNUMSO,  GCINTA,
      GREFUS,  GISOMA,  GLIN3,  GACTIN )
    VALUES :DsDescrFac;

  end-proc;  