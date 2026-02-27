**FREE
  // ------------------------------------------------------------------------
  // - Modulo de Anexos de Tarjeta - Actualizacion de Solicitudes Pendientes
  // - Autor: Ludolfo Montero
  // - Fecha: Septiembre 2024
  // ------------------------------------------------------------------------
  //   CRTSQLRPGI OBJ(EXPLOTA/ANX0100) SRCFILE(EXPLOTA/QRPGLESRC)
  //            SRCMBR(ANX0100) COMMIT(*NONE) OBJTYPE(*PGM) CLOSQLCSR(*ENDMOD)
  //            REPLACE(*YES) DBGVIEW(*SOURCE)
  //
  // ------------------------------------------------------------------------
  // Notas:
  //  * Ejecuta el ANX0101 para la validacion y generacion del FA_ANX
  //  * Genera contabilidad del Anexos en ASIANEXOS
  //  * Genera Evidencias contables CABEANX / DETEANX
  //
  // ------------------------------------------------------------------------
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
    decedit('0,') datedit(*DMY/)
    bnddir('UTILITIES/UTILITIES':'CONTBNDDIR')
    //:'EXPLOTA/CALDIG')
    dftactgrp(*no) actgrp(*caller) main(main);

  // --------------------------
  // Cpys y Include
  // --------------------------
  /Define Funciones_CONTABSRV
  /Define PGM_ASBUNU
  /Define Estructuras_Asientos_Evidencias
  /define Common_Variables
  /Include Explota/QRPGLESRC,CONTABSRVH

  /copy EXPLOTA/QRPGLESRC,ANXCPY_H      // Estructuras Anexos
  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
   ////copy EXPLOTA/QRPGLESRC,UTILSCONTH    // Utilidades contabilidad
  // --------------------------
  // Declaracion de Prototipos
  // --------------------------
  // ** Actualiza Total del FAGE00
  dcl-pr ACUTOT extPgm('ACUTOT');
    *N      Char(6);
    *N      Char(30);
    *N      Packed(10:0);
    *N      Packed( 6:0);
  end-pr;

  // ** Actualiza Total del FAGE00
  dcl-pr ANX0101 extPgm('ANX0101');
    *N      Zoned(9);    // ID Solicitud
    *N      Char(1);     // Actualiza Totales
    *N      Char(20);    // Error
    *N      Packed(11:2);// Importe Procesado
  end-pr;

  // --------------------------
  // Declaracion Estructuras
  // --------------------------
  // Array / Matriz que totaliza importes por productos
  dcl-ds Acumulador likeds(AcumuladorTpl) Dim(100) Inz;

  dcl-ds dsSocio     likeDs(dsT_MSOCIOTpl) inz;
  // --------------------------
  // Declaracion de Variables
  // --------------------------
  dcl-s WTot_FA       zoned(10:2);
  dcl-s WTot_PA       zoned(10:2);
  dcl-s WTot_IdAnexo  zoned(10:2);
  Dcl-s AMDSYS        Zoned(8);
  Dcl-s WLin          Zoned(5);
  Dcl-s WIndice       Zoned(5);
  Dcl-s fecproces    Zoned(8);
  Dcl-s WInd         Zoned(3);
  Dcl-s WIDCONTAB    Zoned(5);  
  
  Dcl-s WImpProc      packed(11:2);

  dcl-s NumApun       char(6);
  Dcl-s WDSPLY        char(40);
  dcl-s APROVI        char(6);
  dcl-s WActTot       Char(1);
  Dcl-s v_tipo_error Char(3) Inz('PGM');
  dcl-s fechaSistema TimeStamp;

  dcl-s CabeceraEvid Ind;
  Dcl-s WNomAsiPar Char(10);
  Dcl-s WNomCabpar Char(10);
  Dcl-s WNomDetPar Char(10);
  Dcl-s WApunte      Char(6);

  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *chg,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

    // Solicitudes Pendientes
  Exec Sql declare  C_SolPend Cursor For
    SELECT
      ID_SOLICITUD, ID_ANEXO, DESCRIP,
      IFNULL(NUREAL, 0),
      IFNULL(NUM_ESTAB, 0),
      IMPORTE,
      date('2030-12-31'),
      Numero_Apunte, Numero_Evidencia,
      NUM_OPERACION, ESTATUS,
      COD_ERROR, FEC_CREACION, USER_CREACION, FEC_MODIF,
      USER_MODIF
    FROM FICHEROS.ANX_SOLICITUD_ANEXOS
    WHERE ESTATUS = 'P'
    ORDER BY ID_ANEXO, NUREAL;

  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    dcl-pi *n;
      P_NomAsiPar   Char(10);
      P_NomCabpar   Char(10);
      P_NomDetPar   Char(10);
      P_NumApunte   Char( 6);
    end-pi;

    dcl-ds dsANXSOLANX likeDs(dsANXSOLANXTpl) Inz;
    dcl-ds dsFa        likeDS(dsFATpl) inz;
    dcl-ds dsANXCATALG likeDS(dsANXCATALGTpl) inz;

    dcl-s ErroAnx      char(20) inz;
    dcl-s WSum_Res     char(1);
    dcl-s WID_Anexo    Zoned(9);
    dcl-s CabeceraEvid Ind;
    dcl-s WCODPRO      Zoned(3);

    WNomAsiPar = P_NomAsiPar;
    WNomCabpar = P_NomCabpar;
    WNomDetPar = P_NomDetPar;
    
    InicializarDatos();

    fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);
    if not Crear_Temporal_Detalle_Evidencia(dsDetevi);
      //leave;
    endif;

    Reset Acumulador;

    Exec Sql Open  C_SolPend;
    sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_SolPend into :dsANXSOLANX;
      If sqlStt <> '00000';
        Leave;
      EndIf;

      WActTot = 'N';
      ErroAnx = '';
      ANX0101(
         dsANXSOLANX.ID_Solicitud // Id Solicitud
        :WActTot                  // Actualiza Totales
        :ErroAnx                  // Cod Error
        :WImpProc);               // Importe Procesado

      If ErroAnx <> '';
        Iter;
      EndIf;

      If WID_Anexo <> dsANXSOLANX.ID_Anexo;

        If WTot_IdAnexo<>0;
          WIDCONTAB = WID_Anexo;
          // Genera Asiento Contable
          CONTABSRV_Genera_Contabilidad_Totales_Producto(
            Acumulador      // Arreglo de Totales por Producto
            :WInd           // Indice de registros Grabados en el Arreglo
            :WIDCONTAB     // Indice Contable: ANEXOS
            :WApunte        // NUmero de Apunte
            :fecproces      // Fecha del asiento DDMMAAAA
            :WNomAsiPar     // Nombre Fichero Parcial ASIFILEn
            );

          Inserta_Totales_Evi();
        Endif;

        Reset Acumulador;
        WID_Anexo    = dsANXSOLANX.ID_Anexo;
        WTot_IdAnexo = 0;
        WIndice      = 0;
        //Impresion de cabecera de Tipo de Anexo
        Inserta_Cebecera_Evi_Det(WID_Anexo);
      EndIf;

      Exec SQL
        Select
          ID_Anexo, Name_Anexo, Desc_Anexo, Tipo_Anexo,
          Destino, Tipo_Registro, Cod_FAPA,
          IFNULL(Num_Estab, 0),
          Num_Comprob, Id_Contab, Estatus, Fec_Creacion, User_Creacion,
          Fec_Modif, User_Modif
        Into :dsANXCATALG
        From ANX_CATALOGO_ANEXOS
        Where
          ID_Anexo = :dsANXSOLANX.ID_Anexo
      ;

      Exec SQL
        Select SCODPR  
          Into :WCODPRO
        From T_MSOCIO
        Where
          NUREAL= :dsANXSOLANX.nureal;
      //Acumula importe por Producto
      If Not Acumula_importe(dsANXSOLANX.Importe
                :WCODPRO);
        dsANXSOLANX.Estatus   = 'E';
        dsANXSOLANX.Cod_Error = 'ANXERR000';  // Error en Codigo producto
        dsANXSOLANX.FECHA_CONTAB = %Date('0001-01-01');
        Actualiza_Solicitud(dsANXSOLANX);
        Iter;
      Endif;

      WTot_IdAnexo += dsANXSOLANX.Importe;

      Reset dsSocio;
      Exec SQL
        Select
          SNUSO1, NUREAL, SNUSO2, SCUOTE, SNOMBR, SDOMIC, CODPOS, PROTG1,
          SLOCAL, SAPEPM, PROTG2, ZONA, SCARNE, SEXTTE, SLIBR0, SEXENT,
          SLIBR1, SFSTAT, SNOMEM, SNOMBA, SDOMBA, SLOCBA, SZOBAN,SNCTAC,
          SMCTAC, SFPAGO, SCONSO, SCONPM, SNOMPM, SDUPEX, SOFESE, SMESCU,
          SCOBHA, SCLTLF, STELEF, STVPER, SMYGAS, SFMGAS, SCLDNI, SCONBA,
          SNIDEM, SPLAST, SCODPO, SCODVI, SMOTBA, NBANCO, SNOREN, SOPCAM,
          SGTEXT, SLIBR2, SNOATM, SSEXO, SOFEPM, SACREC, SMOCTA, SEXNIF,
          SF1STA, SCLPRO,SCONCU,SDIAPA,SSUBHA,SLIBR3,SFREC1,SIMPR1,SLIBR4,
          SFREC2,SIMPR2,SLIBR5,SFREC3,SIMPR3,SLIBR6,SFREC4,SIMPR4,
          SCODEV,SFDEVO,SNOGTS,SLICRE,SACREB,SLIBR7,SCORDV,SREANT,
          SACDNI,SMESRE,SDIAPR,SCLIEX,SNUIDE,SVARTR,SCODNT,STATUS,
          SNNIF,SCATEM,SSALAN,SRECAU,SHNORE,SDEVIM,SDNODI,SOPSER,
          SIMNSE,SOPINT,SIMINT,SDIFAL,SDIRES,SOPRPM,SIMPPM,SIMPAP,
          SOPNCO,SIMNCO,SANACI,SPREFI,SCOPER,SAÑVPM,SVIGPM,SVIPMÑ,
          SPODER,S@,SAUSEO,SAUSER,SAUCAO,SAUCAL,SINFLE,SIN10C,
          SINFFA,SIMPPA,SACC3,SREGEM,SSEGTA,SLIBR8,SAPECA,SAUTIN,
          SAUTOT,SAUINO,SAUOTO,SPORCE,SMOFAC,STIPRE,SPORAN,SPENOF,
          SPIN, SMUSCA,SLIBR9,SFNCAJ,SBCHRE,SINGRE,SALTPM,SVIGTR,
          SFACRB,SCODPR,SOFFSET
        Into :dsSocio
        From T_MSOCIO
        Where
          NUREAL = :dsANXSOLANX.NUREAL
      ;

      If dsANXCATALG.Destino = 'F';
        Inserta_Detalle_Evi(dsANXCATALG:dsANXSOLANX:dsSocio);
        //Genera_Reg_Descripcion(dsANXCATALG:dsANXSOLANX:dsSocio);

        Exec SQL
          Select Operacion
          Into :WSum_Res
          From OPE_CODIGOS_PA_FA
          Where
            Codigo_Ope = :dsANXCATALG.Cod_FAPA
        ;
        If WSum_Res = '+';
          WTot_FA += dsANXSOLANX.Importe;
        Else;
          WTot_FA -= dsANXSOLANX.Importe;
        Endif;
      Else;
        //Genera_Registro_PA(dsANXCATALG:dsANXSOLANX);
      Endif;

      //actualizacion de los datos contables en la solicitud
      dsANXSOLANX.FECHA_CONTAB = %Date();
      dsANXSOLANX.Estatus   = 'C';
      dsANXSOLANX.Cod_Error = '';
      dsANXSOLANX.Numero_Apunte    = NumApun;
      dsANXSOLANX.Numero_Evidencia = APROVI;
      Actualiza_Solicitud(dsANXSOLANX);
    enddo;

    Exec Sql Close  C_SolPend;

    If WTot_IdAnexo<>0;
      // Genera Asiento Contable
      //Genera_Contabilidad(WID_Anexo);
      WIDCONTAB = WID_Anexo;
      CONTABSRV_Genera_Contabilidad_Totales_Producto(
                Acumulador      // Arreglo de Totales por Producto
                :WInd           // Indice de registros Grabados en el Arreglo
                :WIDCONTAB      // Indice Contable: ANEXOS
                :WApunte        // NUmero de Apunte
                :fecproces      // Fecha del asiento DDMMAAAA
                :WNomAsiPar     // Nombre Fichero Parcial ASIFILEn
                );
      Inserta_Totales_Evi();

      Grabar_Temporal_A_Detevi(dsDetevi);
      Guardar_Cabecera_Evidencia(dsDetevi);
    Endif;

    Genera_Totales();
    P_NumApunte = WApunte;
    *inlr = *on;

  end-proc;
  //-----------------------------------------------------------------
  // Acumula_importe
  //-----------------------------------------------------------------
  dcl-proc Acumula_importe;

    dcl-pi *n Ind;
      P_Impor   Packed(14:3) const;
      p_Product Zoned(3);
    end-pi;

    Dcl-s WIndx    Zoned(3);

    WIndx = %lookup(p_Product: Acumulador(*).Cod_prod:1);
    if WIndx > 0;
      Acumulador(WIndx).Total += P_Impor;
    else;
      WInd += 1;
      Acumulador(WInd).Cod_prod = p_Product;
      Acumulador(WInd).Total    = P_Impor;
    endif;

    Return *On;

  end-proc;
  //-----------------------------------------------------------------------------
  // Actualiza registro de Solicitus con Errores
  //-----------------------------------------------------------------------------
  dcl-proc Actualiza_Solicitud;

    dcl-pi *n;
      dsANXSOLANX likeDs(dsANXSOLANXTpl);
    end-pi;

    Exec Sql
      UPDATE ANX_SOLICITUD_ANEXOS
      SET
        FECHA_CONTAB     = :dsANXSOLANX.FECHA_CONTAB,
        Numero_Apunte    = :dsANXSOLANX.Numero_Apunte,
        Numero_Evidencia = :dsANXSOLANX.Numero_Evidencia,
        Estatus          = :dsANXSOLANX.Estatus,
        Cod_Error        = :dsANXSOLANX.Cod_Error,
        Fec_Modif        = Current TimeStamp,
        User_Modif       = :USER
      WHERE
        ID_Solicitud = :dsANXSOLANX.ID_Solicitud;

    If Sqlcode < 0;
      observacionSql = 'ANEXOS: Error al Actualizar Solicitud';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;

  end-proc;

  //-----------------------------------------------------------------
  // Genera Inserta Cabecera de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Cebecera_Evi_Det;

    dcl-pi *n;
      PID_Anexo    Zoned(9);
    end-pi;

    dcl-s marca char(1);
    Dcl-s WDscAnexo Char(60);

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto = ' ';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error en Inserta_Cebecera_Evi_Det';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    Exec SQL
      Select Name_Anexo
        Into :WDscAnexo
      From ANX_CATALOGO_ANEXOS
      Where
        ID_Anexo = :PID_Anexo
    ;

    dsDetevi.lineaTexto = 
      'ANEXO: ' + 
      %SubSt((%Editc(PID_Anexo:'X')):7:3) + 
      '-' + %trim(WDscAnexo);
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error en Inserta_Cebecera_Evi_Det';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto = 
      'NUMERO REAL   NOMBRE DEL SOCIO                       ' +
          '    IMPORTE    PRODUCTO';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error en Inserta_Cebecera_Evi_Det';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto = 
      '-----------------------------------------------------' +
          '-----------------------';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error en Inserta_Cebecera_Evi_Det';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;
  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Detalle de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Detalle_Evi;

    dcl-pi *n;
      dsANXCATALG likeDS(dsANXCATALGTpl);
      dsANXSOLANX likeDs(dsANXSOLANXTpl);
      dsSocio      likeDs(dsT_MSOCIOTpl);
    end-pi;

    Dcl-s WReg     Char(132);
    Dcl-s WImpCuo  Zoned(6:2);
    Dcl-s WNomProd Char(30);

    dcl-ds dsDetalEvi Qualified;
        Esp01     Char(1);
        NumReal   Char(9);
        Esp02     Char(4);
        NomSoc    Char(35);
        Esp03     Char(1);
        ImpCuo    Char(15);
        Esp04     Zoned(3);
        DesAnx    Char(60);
    End-ds;

    Exec SQL
      Select NOMBRE_PRODUCTO
        Into :WNomProd
      From Productos
      Where
        CODIGO_PRODUCTO=:dsSocio.SCODPR;

    If Sqlcode<>0;
        WNomProd = 'Producto No Definido';
    EndIf;
    dsDetalEvi.NumReal = %Editw(dsSocio.NUREAL:'    -    ');
    If dsSocio.SMOCTA = 'PI' Or dsSocio.SMOCTA = 'PE';
      dsDetalEvi.NomSoc  = dsSocio.SNOMBR;
    Else;
      dsDetalEvi.NomSoc  = dsSocio.SNOMEM;
    EndIf;

    dsDetalEvi.ImpCuo  = %Editc(dsANXSOLANX.Importe:'2');
    dsDetalEvi.DesAnx  = %editc(dsSocio.SCODPR:'X') + ' - ' + %trim(WNomProd);

    dsDetevi.lineaTexto = dsDetalEvi;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error en Inserta_Detalle_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      Return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Totales
  //-----------------------------------------------------------------
  dcl-proc Genera_Totales;

    dcl-pi *n;
    end-pi;

    Dcl-s WClave   Char( 6);
    Dcl-s WTxt     Char(30);
    Dcl-s WImporte Packed(10:0);
    Dcl-s WFecha   Packed( 6:0);
    Dcl-s Dia  Zoned(2);
    Dcl-s Mes  Zoned(2);
    Dcl-s AAAA Zoned(4);

    Dia = %SubDt(fechaSistema:*DAYS);
    Mes = %SubDt(fechaSistema:*MONTHS);
    AAAA= %SubDt(fechaSistema:*YEARS);
    // Fecha del proceso DD/MM/AA
    WFecha = %Dec((
             %Editc(Dia:'X')      +
             %Editc(mes:'X')      +
             %SubSt(%Editc(AAAA:'X'):3:2)
           ):6:0);

    If WTot_FA <> 0;
      // Actualiza Total BSACU0
      WClave   = 'FAGE00';
      WTxt     = 'ANX0100 - ANEXOS';
      WImporte = WTot_FA*100;

      ACUTOT(WClave:WTxt:WImporte:WFecha);
    EndIf;

  end-proc;

  //-----------------------------------------------------------------------------
  // Inicializamos datos
  //-----------------------------------------------------------------------------
  dcl-proc InicializarDatos;

    // inicializamos Array / Matriz
    Reset Acumulador;

    fechaSistema = %timestamp();
    WApunte = CONTABSRV_Asignar_Numero_Apunte(fechaSistema);
    fechaSistema = fechaSistema -  %days(1);

    // Guardamos datos fijos de dsDetevi.
    // Luego creamos el fichero temporal de detalle y metemos la cabecera del detalle.
    dsDetevi.numeroApunte = WApunte;
    dsDetevi.fechaConciliacion = %dec(%date(fechaSistema):*ISO);
    dsDetevi.numeroEvidencia = %editc(%dec(%time():*HMS):'X');

  end-proc;
  //---------------------------------------------------------------
  // Crear el fichero temporal del detalle de la evidencia
  //---------------------------------------------------------------
  dcl-proc Crear_Temporal_Detalle_Evidencia;

    dcl-pi *n ind;
      dsDetevi likeds(dsDeteviTempl);
    end-pi;

    dcl-s marca char(1) inz(CREAR_TEMPORAL);

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error al crear temporal de Evidencias';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return *off;
    endif;

    Inserta_Cabecera_detalle();

    return *on;

  end-proc;

  //-----------------------------------------------------------------
  // Inserta registro de Cabecera en el Detalle
  //-----------------------------------------------------------------
  dcl-proc Inserta_Cabecera_detalle;

    dcl-s marca char(1);
    Dcl-s WNomProd  Char(30);
    Dcl-s I         Zoned(3);
    Dcl-s WCod_Prod Zoned(3);
    Dcl-s Dia  Zoned(2);               
    Dcl-s Mes  Zoned(2);               
    Dcl-s AAAA Zoned(4);               
                                      
    Dia = %SubDt(fechaSistema:*DAYS);  
    Mes = %SubDt(fechaSistema:*MONTHS);
    AAAA= %SubDt(fechaSistema:*YEARS); 

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto =
      'ANX0100 - CONTABILIDAD DE ANEXOS AL ' +
      %Editc(Dia:'X') + '-' + %Editc(Mes:'X') + '-' + %Editc(AAAA:'X') ;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error en Inserta_Cabecera_detalle';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      '               ---------------------------------------';

    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi:
          sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error en Inserta_Cabecera_detalle';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Totales de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Totales_Evi;

    dcl-s marca char(1);
    Dcl-s WNomProd  Char(30);
    Dcl-s I         Zoned(3);
    Dcl-s WCod_Prod Zoned(3);

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto = '';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
        marca
        :dsDetevi
        :sqlError
        :sqlMensaje
        :WNomDetPar);
      V_observacion = 'ANX0100: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      'Codigo Producto'             +
      '                           ' +
      '         Total' ;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      '------------------------------------' +
      '    '                                 +
      '         ------------' ;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    // Ordenamiento del Arreglo por Codigo de Producto
    sorta %subarr(Acumulador(*).Cod_prod : 1 : WInd);

    For I=1 to WInd;

      WCod_Prod = Acumulador(I).Cod_prod;
      Exec SQL
        Select NOMBRE_PRODUCTO
          Into :WNomProd
        From Productos
        Where
          CODIGO_PRODUCTO=:WCod_Prod;
      If Sqlcode<>0;
          WNomProd = 'Producto No Definido';
      EndIf;

      dsDetevi.lineaTexto =
        %Editc(Acumulador(I).Cod_prod:'X') +
        ' - ' + WNomProd + '    '    +
        %Editc(
          %Dec(Acumulador(I).Total:16:2)
        :'2');
      WnumLinea += 1;
      dsDetevi.numeroLinea = numeroLinea;

      if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
            marca  
            :dsDetevi
            :sqlError
            :sqlMensaje
            :WNomDetPar);
        V_observacion = 'ANX0100: Error al registro de Evidencia Inserta_Totales_Evi';
        Diagnostico(jobname:V_observacion:V_tipo_error);
        Leave;
      EndIf;
    EndFor;

  end-proc;
  //-----------------------------------------------------------------------------
  // Guardar fichero temporal a DETEVI
  //-----------------------------------------------------------------------------
  dcl-proc Grabar_Temporal_A_Detevi;

    dcl-pi *n;
      dsDetevi likeDs(dsDeteviTempl);
    end-pi;

    dcl-s marca char(1) inz(GRABAR_A_FICHERO);

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'ANX0100: Error al grabar temporal en el DETEVI';
      Diagnostico(jobname:V_observacion:V_tipo_error);
    endif;

  end-proc;
  //-----------------------------------------------------------------------------
  // Guardar cabecera evidencia contable
  //-----------------------------------------------------------------------------
  dcl-proc Guardar_Cabecera_Evidencia;

    dcl-pi *n ind;
      dsDetevi likeDs(dsDeteviTempl);
    end-pi;

    dcl-ds dsCabevi likeds(dsCabeviTempl) inz;
    Dcl-s Dia  Zoned(2);
    Dcl-s Mes  Zoned(2);
    Dcl-s AAAA Zoned(4);

    Dia = %SubDt(fechaSistema:*DAYS);
    Mes = %SubDt(fechaSistema:*MONTHS);
    AAAA= %SubDt(fechaSistema:*YEARS);

    dsCabevi.descripcion =
      'ANX0100 - CONTABILIDAD DE ANEXOS AL ' +
      %Editc(Dia:'X') + '-' + %Editc(Mes:'X') + '-' + %Editc(AAAA:'X') ;

    dsCabevi.numeroApunte = dsDetevi.numeroApunte;
    dsCabevi.fechaConciliacion = dsDetevi.fechaConciliacion;
    dsCabevi.fechaBaja = 0;
    dsCabevi.pteModificar = *blanks;
    dsCabevi.numeroEvidencia = dsDetevi.numeroEvidencia;

    if not CONTABSRV_Guardar_Evidencias_Contables_Cabecera(
      dsCabevi
      :sqlError
      :sqlMensaje
      :WNomCabpar);
      return *off;
    endif;

    return *on;

  end-proc;