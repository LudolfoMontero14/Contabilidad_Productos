**FREE
  Ctl-Opt DECEDIT('0,') DATEDIT(*DMY.) DFTACTGRP(*NO)
          BNDDIR('CONTBNDDIR':'UTILITIES/UTILITIES') main(main);
  //****************************************************************
  //*  -FACT.SOCIOS- ASIENTO TRASPASO -PA- A -FA-                 **
  //****************************************************************
  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
  /copy EXPLOTA/QRPGLESRC,CONTABSRVH       // Utilidades contabilidad
  ///copy EXPLOTA/QRPGLESRC,MCARD_H

  Dcl-S fechaSistema Timestamp;

  Dcl-S import       Zoned(11:0);
  Dcl-s WInd         Zoned(3);
  Dcl-s fecproces    Zoned(8);
  Dcl-s WCodContab   Zoned(5) Inz(5); //Id_Asiento FSPAFAN
  Dcl-s WApunte      Char(6);
  Dcl-s WCRFS01      Char(96);
  Dcl-s WCodpro      zoned(3);
  Dcl-s v_tipo_error Char(3) Inz('PGM');
  Dcl-s WNomAsiPar Char(10);
  Dcl-s WNomCabpar Char(10);
  Dcl-s WNomDetPar Char(10);
  Dcl-s WPGM       Char(10) Inz('FSPAFAN');

  // Array / Matriz que totaliza importes por productos
  dcl-ds Acumulador likeds(AcumuladorTpl) Dim(100) Inz;

  dcl-ds BS_DTA Qualified;
    NUREAL    Zoned(8);
    IMPOR     Zoned(9:0);
    NOMEMP    Char(30);
    CODFORPAG Zoned(1);
    DSCFORPAG Char(20);
    CODPROD   Zoned(3);
  end-ds;

  // declaracion de Cursores
  Exec sql
    Set Option Commit=*None, CloSQLCsr=*EndMod, Datfmt=*dmy,
    Decmpt =*comma;

  Exec Sql declare C_BS Cursor For
    Select
      b.BNUMRE, b.Tot_Impor, m.SNOMEM, m.SFPAGO,
      Case
        When m.SFPAGO = 1 Then 'Banco'
        else 'Directamente'
      End Dsc_FPago,
      m.SCODPR
    From
      (SELECT
        BNUMRE, SUM(BIMPOR) Tot_Impor
      FROM BS
      WHERE
        BCODMO IN ('4', '5', '7')
      GROUP BY BNUMRE) b
      Inner Join Ficheros.T_MSOCIO m
        On (m.NUREAL = b.BNUMRE)
    Order By m.SCODPR, b.BNUMRE;

  // ****************************************************************************
  // PROCESO PRINCIPAL
  // ****************************************************************************
  dcl-proc main;

    dcl-pi *n;
      P_NonProc     Char(10);
      P_NomAsiPar   Char(10);
      P_NomCabpar   Char(10);
      P_NomDetPar   Char(10);
    end-pi;

    WNomAsiPar = P_NomAsiPar;
    WNomCabpar = P_NomCabpar;
    WNomDetPar = P_NomDetPar;
    
    InicializarDatos();

    Exec Sql
      Select CRFS01
      Into :WCRFS01
      From CRFS01;

    Monitor;
      fecproces = %Dec(%SubSt(WCRFS01:50:8):8:0);
    on-error;
      fecproces = %Dec(%date():*EUR);
    endmon;

    fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);
    if not Crear_Temporal_Detalle_Evidencia(dsDetevi);
      //leave;
    endif;

    //***********************
    //*   LECTURA DEL BS   **
    //***********************
    Exec Sql Open C_BS;
    Exec Sql Fetch From C_BS into :BS_DTA;
    If Sqlcode < 0;
      observacionSql = 'FSPAFAN: Error en el Fech del Cursor';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;
    dow sqlStt = '00000';

      IMPORT = IMPORT + BS_DTA.IMPOR;
      WCodpro = BS_DTA.CODPROD;
      // Acumula importe por producto
      Acumula_importe(BS_DTA.IMPOR/100:BS_DTA.CODPROD);

      Inserta_Detalle_Evi();

      Exec Sql Fetch From C_BS into :BS_DTA;
      If Sqlcode < 0;
        observacionSql = 'FSPAFAN: Error en el Fech del Cursor';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      EndIf;
    ENDDO;

    Exec Sql Close C_BS;

    If IMPORT > 0;
      CONTABSRV_Genera_Contabilidad_Totales_Producto(
                Acumulador      // Arreglo de Totales por Producto
                :WInd           // Indice de registros Grabados en el Arreglo
                :WCodContab     // Indice Contable: 5 Para este proceso
                :WApunte        // NUmero de Apunte
                :fecproces      // Fecha del asiento DDMMAAAA
                :WNomAsiPar    // Nombre Fichero Parcial ASIFILEn
                );

      Inserta_Totales_Evi();

      Grabar_Temporal_A_Detevi(dsDetevi);
      Guardar_Cabecera_Evidencia(dsDetevi);
      CONTABSRV_Registro_Auditoria_Paralelo(
          P_NonProc            // Proceso que Ejecuta
          :WPGM                // Proceso Actual 'FSPAFAN'
          :WApunte             // Numero de Apunte
          :WNomAsiPar          // Nombre Asifilen Parcial
          :WNomCabpar           // Nombre Cabevi Parcial
          :WNomDetPar          // Nombre Detevi Parcial
      );

    EndIf;

    *InLR = *On;
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
      V_observacion = 'FSPAFAN: Error al crear temporal de Evidencias';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return *off;
    endif;

    Inserta_Cabecera_detalle();

    return *on;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Detalle de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Detalle_Evi;

    dcl-s marca char(1);
    dcl-s WImpdec Zoned(9:2);
    dcl-ds dsDetalleEvi Qualified;
      Esp01     Char(1);
      NUREAL    Zoned(8);

      Esp02     Char(2);
      IMPORTE   Char(14);

      Esp03     Char(2);
      NomSoc    Char(30);

      Esp04     Char(2);
      DscForPag Char(20);

      Esp05     CHAR(5);
      Producto  Zoned(3);
    End-ds;


    marca = GRABAR_TEMPORAL;

    dsDetalleEvi.NUREAL    = BS_DTA.NUREAL;
    WImpdec = BS_DTA.IMPOR/100;
    dsDetalleEvi.IMPORTE   = %Editc(WImpdec:'J');
    dsDetalleEvi.NomSoc    = BS_DTA.NOMEMP;
    dsDetalleEvi.DscForPag = BS_DTA.DSCFORPAG;
    dsDetalleEvi.Producto = BS_DTA.CODPROD;

    dsDetevi.lineaTexto = dsDetalleEvi;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'FSPAFAN: Error al registro de Evidencia en el temporal';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      Return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Inserta registro de Cabecera en el Detalle
  //-----------------------------------------------------------------
  dcl-proc Inserta_Cabecera_detalle;

    dcl-s marca char(1);
    Dcl-s WNomProd  Char(30);
    Dcl-s I         Zoned(3);
    Dcl-s WCod_Prod Zoned(3);

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto =
      'FSPAFAN EVIDENCIA CONTABLE FACT. AL ' +
      %SubSt(%Editc(fecproces:'X'):1:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):3:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):5:4);
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'FSPAFAN: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      'NUMERO REAL     IMPORTE    NOMBRE SOCIO                    '+
      'FORMA DE PAGO         PRODUCTO';

    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi:
          sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'FSPAFAN: Error al registro de Evidencia Inserta_Totales_Evi';
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
      V_observacion = 'FSPAFAN: Error al registro de Evidencia Inserta_Totales_Evi';
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
      V_observacion = 'FSPAFAN: Error al registro de Evidencia Inserta_Totales_Evi';
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
      V_observacion = 'FSPAFAN: Error al registro de Evidencia Inserta_Totales_Evi';
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
        V_observacion = 'FSPAFAN: Error al registro de Evidencia Inserta_Totales_Evi';
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
      V_observacion = 'FSPAFAN: Error al grabar temporal en el DETEVI';
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

    dsCabevi.descripcion =
      'FSPAFAN EVIDENCIA CONTABLE FACT. AL ' +
      %SubSt(%Editc(fecproces:'X'):1:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):3:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):5:4);

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