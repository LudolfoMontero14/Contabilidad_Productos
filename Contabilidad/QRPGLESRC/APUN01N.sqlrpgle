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
  Ctl-Opt DECEDIT('0,') DATEDIT(*DMY.) DFTACTGRP(*NO)
          BNDDIR('CONTBNDDIR':'UTILITIES/UTILITIES') main(main);

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
  // Array / Matriz que totaliza importes por productos
  dcl-ds Acumulador likeds(AcumuladorTpl) Dim(100) Inz;

  dcl-ds DS_IMOV_TARJ Qualified;
    PAIS       Zoned(3);
    RECAP      Zoned(4);
    TARJETA    Char(16);
    NOMEMPRESA Char(30);
    NOMSOCIO   Char(35);
    IMPCONS    Zoned(11:2);
    CODPROD    Zoned(3);
  end-ds;

  dcl-ds DS_RECAP Qualified;
    PAIS       Zoned(3);
    RECAP      Zoned(4);
    IMP_NETO   Zoned(11:2);
    IMP_COMIS  Zoned(11:2);
    IMP_Mon_Orig  Zoned(11:2);
    Fecha_Recap Char(10);
  end-ds;

  dcl-ds Acumulador_Pais_Recap Qualified Dim(100) Inz;
    Key       char(7);          // 3 + 4 (Pais + Recad)
    Cod_Pais  Zoned(3:0);
    Cod_Recad Zoned(4:0);
    Total     Zoned(11:2);
  end-ds;
  // --------------------------
  // Declaracion de Variables Globales
  // --------------------------
  Dcl-S fechaSistema Timestamp;

  Dcl-S TOT_COSUMO   Zoned(11:2);
  Dcl-S TOT_RECAP    Zoned(11:2);
  Dcl-S TOT_COMIS    packed(14:3);
  Dcl-s WInd         Zoned(3);
  Dcl-s WInd_PR      Zoned(3);
  Dcl-s fecproces    Zoned(8);
  Dcl-s ID_Contab    Zoned(5) Inz(41); //Id_Asiento APUN01N
  Dcl-s WApunte      Char(6);
  Dcl-s v_tipo_error Char(3) Inz('PGM');
  Dcl-s WNomAsiPar Char(10);
  Dcl-s WNomCabpar Char(10);
  Dcl-s WNomDetPar Char(10);
  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
    SET OPTION Commit = *none,
            CloSqlCsr = *endmod,
            AlwCpyDta = *yes;

  // Consumos por tarjeta
  Exec Sql declare  C_Consumos Cursor For
    Select
      WPAIS,
      WRECAP,
      SubString(WCPO37, 1, 14) Tarjeta,
      SNOMEM NomEmpresa,
      SNOMBR NomSocio,
      Dec(DECIMAL(
       (
       CASE
        WHEN SUBSTR(SUBSTRING(WCPO37, 17, 8), 8, 1)
          IN ('}', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R')
          THEN -1 ELSE 1 END) *
      DECIMAL(SUBSTR(SUBSTRING(WCPO37, 17, 8), 1, 7) CONCAT
      TRANSLATE(SUBSTR(SUBSTRING(WCPO37, 17, 8), 8, 1),
      '01234567890123456789', '}JKLMNOPQR{ABCDEFGHI'),
      15, 3), 15, 2) / 100, 11, 2) AS Consumo,
      SCODPR
    From IMOVAPUN01 a
      inner Join Ficheros.T_MSOCIO b
      On (Dec(SubString(WCPO37, 3, 8), 8, 0) = b.NUREAL)
    Where
      WTIPRE = '7'
    Order by WPAIS, WRECAP;


  // Registros de Recap por Pais
  Exec Sql declare  C_Recap Cursor For
    Select
      WPAIS, WRECAP,
      Dec(Round((WIMPMO - (WIMPMO * WRATE/100)) * b.BULTCB, 2), 11, 2)
        Imp_Neto_Recap_IMOV,
      Dec(Round((WIMPMO * WRATE/100) * b.BULTCB, 2), 11, 2) Imp_Comision_Conv,
      BNETRE Imp_Mon_orig,
      (SubString(Digits(WFEREC), 1, 2) || '-' ||
       SubString(Digits(WFEREC), 3, 2) || '-' ||
       SubString(Digits(WFEREC), 5, 4)) as Fecha_Recap
    From IMOV a
      Inner join BOLRECAP b
        On (WPAIS = BPAIS
            and WRECAP = BRECAP
            and SubString(WCPO25, 19, 3) = BMONEP
            and dec(SubString(WCPO37, 25, 4) || '20' || SubString(WCPO37, 29, 2), 8, 0) = BFEREC)
    Where
      WTIPRE = 'R'
    Order by WPAIS, WRECAP;

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


    WNomAsiPar = P_NomAsiPar;
    WNomCabpar = P_NomCabpar;
    WNomDetPar = P_NomDetPar;

    InicializarDatos();

    fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);
    if not Crear_Temporal_Detalle_Evidencia(dsDetevi);
      //leave;
    endif;

    // Lectura del IMOV registros tipo 7
    Lectura_Consumos_Tarjetas();

    // Contabilidad de Consumos por Totales por Producto
    If TOT_COSUMO > 0;
      P_NumApunte = WApunte;   // Para devolver el numero de Apunte por paramatro
      Genera_Contabilidad_DEBE_PRODUCTO();
      Inserta_Totales_Evi();
    EndIf;
    // Lectura del IMOV registros tipo R (RECAP)
    Lectura_Recap_Contab();


    If TOT_COMIS > 0;
      Genera_Contabilidad_Haber_Comisiones();
    Endif;

    Grabar_Temporal_A_Detevi(dsDetevi);
    Guardar_Cabecera_Evidencia(dsDetevi);

    *InLR = *On;
  end-proc;
  //-----------------------------------------------------------------
  // Lectura de los Consumos por Tarjeta
  //-----------------------------------------------------------------
  dcl-proc Lectura_Consumos_Tarjetas;

    dcl-pi *n ;

    end-pi;

    //*************************
    //*   LECTURA DEL IMOV   **
    //*************************
    Exec Sql Open C_Consumos;
    Exec Sql Fetch From C_Consumos into :DS_IMOV_TARJ;
    If Sqlcode < 0;
      observacionSql = 'APUN01N: Error en el Fech del Cursor C_Consumos';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;
    dow sqlStt = '00000';

      TOT_COSUMO += DS_IMOV_TARJ.IMPCONS;
      // Acumula importe por producto
      Acumula_importe(DS_IMOV_TARJ.IMPCONS:DS_IMOV_TARJ.CODPROD);

      Inserta_Detalle_Evi_Consumos();

      Exec Sql Fetch From C_Consumos into :DS_IMOV_TARJ;
      If Sqlcode < 0;
        observacionSql = 'APUN01N: Error en el Fech del Cursor C_Consumos';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      EndIf;
    ENDDO;

    Exec Sql Close C_Consumos;

  End-Proc;
  //-----------------------------------------------------------------
  // Lectura de RECAPs por Pais, Recap - Contabilizacion de Recap
  //-----------------------------------------------------------------
  dcl-proc Lectura_Recap_Contab;

    dcl-pi *n;

    end-pi;

    dcl-s IndCab Ind Inz(*Off);
    //*************************
    //*   LECTURA DEL IMOV   **
    //*************************
    Exec Sql Open C_Recap;
    Exec Sql Fetch From C_Recap into :DS_RECAP;
    If Sqlcode < 0;
      observacionSql = 'APUN01N: Error en el Fech del Cursor C_Recap';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;
    dow sqlStt = '00000';

      If Not IndCab;
        Inserta_Cabecera_detalle_Recap();
        IndCab = *On;
      EndIf;

      TOT_RECAP += DS_RECAP.IMP_NETO;
      TOT_COMIS += DS_RECAP.IMP_COMIS;

      If Not Genera_Contabilidad_Haber_Pais_Recap();

      EndIf;

      Inserta_Detalle_Evi_Recap();

      Exec Sql Fetch From C_Recap into :DS_RECAP;
      If Sqlcode < 0;
        observacionSql = 'APUN01N: Error en el Fech del Cursor C_Recap';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      EndIf;
    ENDDO;

    Exec Sql Close C_Recap;

  End-Proc;
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
  //-----------------------------------------------------------------
  // Acumula Importes por Pais y Recap
  //-----------------------------------------------------------------
  // dcl-proc Acumula_Imp_Pais_Recap;

  //   dcl-pi *n;
  //     pCod_Pais  zoned(3:0);
  //     pCod_Recad zoned(4:0);
  //     pImporte   zoned(11:2);
  //   end-pi;

  //   dcl-s WIndx  int(10) inz(0);
  //   dcl-s Key    char(7);

  //   // Construye clave en el mismo orden del fichero (Pais+Recad) con ceros a la izquierda
  //   Key = %editc(pCod_Pais:'X') + %editc(pCod_Recad:'X');

  //   // Buscar desde 1 (array ya ordenado porque la lectura viene ordenada)
  //   WIndx = %lookup(Key : Acumulador_Pais_Recap(*).Key : 1);

  //   if WIndx > 0;
  //     Acumulador_Pais_Recap(WIndx).Total += pImporte;
  //   else;
  //     WInd_PR += 1;

  //     // (opcional) control de overflow
  //     if WIndx > %elem(Acumulador_Pais_Recap);
  //       dsply 'Acumulador lleno';
  //       return;
  //     endif;

  //     Acumulador_Pais_Recap(WInd_PR).Key       = Key;
  //     Acumulador_Pais_Recap(WInd_PR).Cod_Pais  = pCod_Pais;
  //     Acumulador_Pais_Recap(WInd_PR).Cod_Recad = pCod_Recad;
  //     Acumulador_Pais_Recap(WInd_PR).Total     = pImporte;
  //   endif;

  // end-proc;
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
      V_observacion = 'APUN01N: Error al crear temporal de Evidencias';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return *off;
    endif;

    Inserta_Cabecera_detalle();

    return *on;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Detalle de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Detalle_Evi_Consumos;

    dcl-s marca char(1);
    dcl-s WImpdec Zoned(9:2);
    dcl-ds dsDetalleEvi Qualified;
      Esp01     Char(1);
      PAIS      Zoned(3);

      Esp02     Char(2);
      RECAP     Zoned(4);

      Esp03     Char(2);
      Tarjeta   Char(16);

      Esp04     Char(2);
      NomEmpresa Char(30);

      Esp05     Char(2);
      NomSocio  Char(35);

      Esp06     Char(2);
      Consumo   Char(15); //123.456.789,01

      Esp07     CHAR(5);
      Producto  Zoned(3);
    End-ds;


    marca = GRABAR_TEMPORAL;

    dsDetalleEvi.PAIS       = DS_IMOV_TARJ.PAIS;
    dsDetalleEvi.RECAP      = DS_IMOV_TARJ.RECAP;
    dsDetalleEvi.Tarjeta    = %Trim(DS_IMOV_TARJ.TARJETA);
    dsDetalleEvi.NomEmpresa = %Trim(DS_IMOV_TARJ.NOMEMPRESA);
    dsDetalleEvi.NomSocio   = %Trim(DS_IMOV_TARJ.NOMSOCIO);
    dsDetalleEvi.Consumo   = %Editc(DS_IMOV_TARJ.IMPCONS:'J');
    dsDetalleEvi.Producto = DS_IMOV_TARJ.CODPROD;

    dsDetevi.lineaTexto = dsDetalleEvi;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'APUN01N: Error Inserta_Detalle_Evi_Consumos';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      Return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Inserta registro de Cabecera en el Detalle RECAP
  //-----------------------------------------------------------------
  dcl-proc Inserta_Cabecera_detalle_Recap;

    dcl-s marca char(1);
    Dcl-s WNomProd  Char(30);
    Dcl-s I         Zoned(3);
    Dcl-s WCod_Prod Zoned(3);

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto =
      ' ';

    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi:
          sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion =
      'APUN01N: Error al registro de Evidencia Inserta_Cabecera_detalle_Recap';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      'APUN01N EVIDENCIA CONTABLE AL ' +
      %SubSt(%Editc(fecproces:'X'):1:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):3:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):5:4) + ' ** RECAPS';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion =
      'APUN01N: Error al registro de Evidencia Inserta_Cabecera_detalle_Recap';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      'PAIS  RECAP      IMP. NETO    IMP. COMISION    IMP. ORIGINAL  FECHA';

    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi:
          sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion =
      'APUN01N: Error al registro de Evidencia Inserta_Cabecera_detalle_Recap';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Detalle de Evidencia Contable - RECAP
  //-----------------------------------------------------------------
  dcl-proc Inserta_Detalle_Evi_Recap;

    dcl-s marca char(1);
    dcl-s WImpdec Zoned(9:2);
    dcl-ds dsDetalleEviRec Qualified;
      Esp01     Char(1);
      PAIS      Zoned(3);

      Esp02     Char(2);
      RECAP     Zoned(4);

      Esp03     Char(2);
      Imp_Neto_Recap   Char(14); //123.456.789,01

      Esp04     Char(2);
      Imp_Comision  Char(14); //123.456.789,01

      Esp05     Char(2);
      Imp_Mon_Orig  Char(14); //123.456.789,01

      Esp06     Char(4);
      Fecha_recap  Char(10);

    End-ds;

    marca = GRABAR_TEMPORAL;

    dsDetalleEviRec.PAIS = DS_RECAP.PAIS;
    dsDetalleEviRec.RECAP = DS_RECAP.RECAP;
    dsDetalleEviRec.Imp_Neto_Recap = %Editc(DS_RECAP.IMP_NETO:'J');
    dsDetalleEviRec.Imp_Comision = %Editc(DS_RECAP.IMP_COMIS:'J');
    dsDetalleEviRec.Imp_Mon_Orig = %Editc(DS_RECAP.IMP_COMIS:'J');
    dsDetalleEviRec.Fecha_recap = DS_RECAP.Fecha_Recap;

    dsDetevi.lineaTexto = dsDetalleEviRec;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'APUN01N: Error al Inserta_Detalle_Evi_Recap';
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
      'APUN01N EVIDENCIA CONTABLE AL ' +
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
      V_observacion = 'APUN01N: Error al Inserta_Cabecera_detalle';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      'PAIS RECAP  TARJETA           NOMBRE EMPRESA' +
      '                  NOMBRE SOCIO'             +
      '                             CONSUMO      PROD';

    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi:
          sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'APUN01N: Error al Inserta_Cabecera_detalle';
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
      V_observacion = 'APUN01N: Error al Inserta_Totales_Evi';
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
      V_observacion = 'APUN01N: Error al Inserta_Totales_Evi';
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
      V_observacion = 'APUN01N: Error al Inserta_Totales_Evi';
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
        V_observacion = 'APUN01N: Error al Inserta_Totales_Evi';
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
      V_observacion = 'APUN01N: Error al Grabar_Temporal_A_Detevi';
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
      'APUN01N EVIDENCIA CONTABLE AL ' +
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
  //-----------------------------------------------------------------
  // Genera Contabilidad Asientos al DEBE por Producto
  //-----------------------------------------------------------------
  dcl-proc Genera_Contabilidad_DEBE_PRODUCTO;

    dcl-pi *n;

    end-pi;

    Dcl-s I        Zoned(3);
    Dcl-s WMarca   Zoned(2);
    Dcl-s WCodProd Zoned(3);
    Dcl-s WExiste_Cod   Ind;
    Dcl-s WCodDiv  Char(3);
    Dcl-s WNumOrden Zoned(2);

    dcl-ds dsKeyAsiento likeds(dsKeyAsientoTpl) inz;
    dcl-ds dsDatosAsientoParametrizables
            likeds(dsDatosAsientoParametrizablesTpl) inz;
    dcl-ds dsDatosAsientoNoParametrizables
            likeds(dsDatosAsientoNoParametrizablesTpl) inz;
    dcl-ds dsAsifilen likeds(dsAsifilenTpl) inz;
    dcl-s textoError char(100) inz;
    dcl-s sqlError char(5) inz;
    dcl-s sqlMensaje char(70) inz;


    Sqlcode = 0;
    For I=1 to WInd;
      WCodProd = Acumulador(I).Cod_prod;

      dsKeyAsiento.idAsiento = ID_Contab; // 41
      dsKeyAsiento.ordenApunte = 1; // Para Consumos por Producto
      dsKeyAsiento.codProducto = WCodprod;

      dsDatosAsientoNoParametrizables.numApunte = WApunte;
      dsDatosAsientoNoParametrizables.fechaContable = fecproces ;
      dsDatosAsientoNoParametrizables.referenciaOperacion = *blanks;
      dsDatosAsientoNoParametrizables.fechaVencimiento = 0;
      dsDatosAsientoNoParametrizables.codMoneda = '1';
      dsDatosAsientoNoParametrizables.apunteProvisional = *blanks;
      dsDatosAsientoNoParametrizables.tipoOperacion = 0;

      dsDatosAsientoNoParametrizables.debeHaber = 'D';
      if Acumulador(I).Total < 0;
        dsDatosAsientoNoParametrizables.debeHaber = 'H';
      endif;

      dsDatosAsientoNoParametrizables.importe =
            %abs(Acumulador(I).Total);

      if not CONTABSRV_Obtener_Datos_Asiento(
              dsKeyAsiento
              :dsDatosAsientoParametrizables
              :dsDatosAsientoNoParametrizables
              :dsAsifilen
              :textoError);
        Iter;
      endif;

      if not CONTABSRV_Grabar_Asiento(dsAsifilen
            :sqlError
            :sqlMensaje
            :WNomAsiPar);
        // Agregar funcion de monitoreo de Errores y correo
        Iter;
      endif;

    EndFor;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Contabilidad Asientos al HABER por Pais recap
  //-----------------------------------------------------------------
  dcl-proc Genera_Contabilidad_Haber_Pais_Recap;

    dcl-pi *n ind;

    end-pi;

    Dcl-s I        Zoned(3);
    Dcl-s WMarca   Zoned(2);
    Dcl-s WCodProd Zoned(3);
    Dcl-s WExiste_Cod   Ind;
    Dcl-s WCodDiv  Char(3);
    Dcl-s WNumOrden Zoned(2);

    dcl-ds dsKeyAsiento likeds(dsKeyAsientoTpl) inz;
    dcl-ds dsDatosAsientoParametrizables
            likeds(dsDatosAsientoParametrizablesTpl) inz;
    dcl-ds dsDatosAsientoNoParametrizables
            likeds(dsDatosAsientoNoParametrizablesTpl) inz;
    dcl-ds dsAsifilen likeds(dsAsifilenTpl) inz;
    dcl-s textoError char(100) inz;
    dcl-s sqlError char(5) inz;
    dcl-s sqlMensaje char(70) inz;

    dsDatosAsientoNoParametrizables.numApunte = WApunte;
    dsDatosAsientoNoParametrizables.fechaContable = fecproces ;
    dsDatosAsientoNoParametrizables.referenciaOperacion = *blanks;
    dsDatosAsientoNoParametrizables.fechaVencimiento = 0;
    dsDatosAsientoNoParametrizables.codMoneda = '1';
    dsDatosAsientoNoParametrizables.apunteProvisional = *blanks;
    dsDatosAsientoNoParametrizables.tipoOperacion = 0;

    dsKeyAsiento.idAsiento = ID_Contab; // 41
    dsKeyAsiento.ordenApunte = 2; // Para Recap por Pais
    dsKeyAsiento.codProducto = 0; // Para Recap por Pais

    dsDatosAsientoNoParametrizables.debeHaber = 'H';
    if DS_RECAP.IMP_NETO < 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    endif;
    dsDatosAsientoNoParametrizables.importe =
          %abs(DS_RECAP.IMP_NETO);

    if not CONTABSRV_Obtener_Datos_Asiento(
            dsKeyAsiento
            :dsDatosAsientoParametrizables
            :dsDatosAsientoNoParametrizables
            :dsAsifilen
            :textoError);
      return *off;
    endif;

    dsAsifilen.cconce =
      'RECAP ' +
      DS_RECAP.Fecha_Recap + ' ' +
      %Editc(DS_RECAP.IMP_Mon_Orig:'J');
    dsAsifilen.cctana = %editc(DS_RECAP.PAIS:'X');
    dsAsifilen.crefde = %editc(DS_RECAP.RECAP:'X');

    if not CONTABSRV_Grabar_Asiento(dsAsifilen
          :sqlError
          :sqlMensaje
          :WNomAsiPar);
      // Agregar funcion de monitoreo de Errores y correo
      return *off;
    endif;

    return *on;
  end-proc;
  //-----------------------------------------------------------------
  //Genera Contabilidad para las Comisiones
  //-----------------------------------------------------------------
  dcl-proc Genera_Contabilidad_Haber_Comisiones;

    dcl-pi *n;

    end-pi;

    Dcl-s I        Zoned(3);
    Dcl-s WCodProd Zoned(3);
    Dcl-s WCodDiv  Char(3);
    Dcl-s WNumOrden Zoned(2);

    WNumOrden = 3; // Orden para Haber - Comisiones
    WCodProd  = 0; // Codigo Producto para Comisiones
    if not CONTABSRV_Guardar_Single_Asiento(
          ID_Contab
          :WNumOrden
          :WCodprod
          :TOT_COMIS
          :WApunte
          :fecproces
          :WNomAsiPar);
      Return;
    endif;

  end-proc;
