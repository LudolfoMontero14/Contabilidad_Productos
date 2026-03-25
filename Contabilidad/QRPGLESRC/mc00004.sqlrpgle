**FREE
// ****************************************************************************
// MC00004
//   Programa para generar asiento contable Mastercard a la entrada de
//     operaciones.
//   También genera evidencias contables
// ****************************************************************************
// PROGRAMADOR: JMMM
// FECHA: 25/09/2023
// ****************************************************************************
// COMPILACION: 14 con DBGVIEW = *LIST
// ****************************************************************************
//Modificado Por: Jose daniel Martin Perez                       22.02.2024
// Se incorpora punto de interrucion Halt Indicators para errores de sql
// ****************************************************************************
//Modificado Por: Ludolfo Montero                                24.06.2025
// CAU-10676: La contabilidad debe ser por ficheros y la fecha de contabilizacion
// debe ser la misma de la recepcion del fichero.
// ****************************************************************************
ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
  bnddir('EXPLOTA/CALDIG':'UTILITIES/UTILITIES')
  datedit(*DMY/) decedit('0,')
  dftactgrp(*no) actgrp(*New) main(main);

dcl-c PROGRAMA const('MC00004');
dcl-c CREAR_TEMPORAL const('C');
dcl-c GRABAR_TEMPORAL const('G');
dcl-c GRABAR_A_FICHERO const('F');
dcl-c TIPO_OPERACION const('OPERACIONES');

// Para gestión de errores y envío de correo
dcl-s wNumFichero zoned(9:0) inz;
dcl-s wNumError char(2) inz;
dcl-s fechaSistema timestamp inz;
dcl-ds dsLog likeDs(dsLogTpl) inz;
dcl-ds dsCorreoMC likeDs(dsCorreoMCTpl) inz;
dcl-s sqlError char(5) inz;
dcl-s sqlMensaje char(70) inz;
dcl-s WNUM_FICHERO Zoned(9);
dcl-s WFecha_grabacion Timestamp;

dcl-pr MC00002 extPgm('MC00002');
  dsCorreoMC likeDs(dsCorreoMCTpl);
end-pr;

/copy EXPLOTA/QRPGLESRC,MCARD_H       // dsBlomastgerTpl
/copy EXPLOTA/QRPGLESRC,DSAEVIDE      // Evidencias contables
/copy EXPLOTA/QRPGLESRC,UTILSCONTH    // Utilidades contabilidad
/copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
/copy UTILITIES/QRPGLESRC,PSDSCP      // psds

Exec Sql
  SET OPTION Commit = *none,
          CloSqlCsr = *endmod,
          AlwCpyDta = *yes;
//--------------------------------------------------------
// Declaración de Cursores
//--------------------------------------------------------

exec Sql declare C0 Scroll Cursor For
  Select
    numero_fichero, Fecha_hora_grabacion
  From FICHEROS.V_OPERACIONES_MC_NO_APUNTE
  Group by numero_fichero, Fecha_hora_grabacion
  Order by numero_fichero, Fecha_hora_grabacion
;

exec Sql declare C1 Scroll Cursor For
  SELECT NUMERO_FICHERO, NUMERO_OPERACION, PANTOKEN, CODIGO_PRODUCTO, ACTIVIDAD_DINERS,
    ACTIVIDAD_DXS, IMPORTE, FECHA_HORA_CONSUMO, DIA_CONTABLE, CODIGO_GEOGRAFICO,
    CODIGO_ADQUIRENTE, CAMBIO_MONEDA, IMPORTE_EUROS, CLASE_MONEDA, IMPORTE_COMISION,
    NUMERO_REGISTRO, HAY_DATOS_ADICIONALES, ID_INFORMACION_ADICIONAL, PAIS_FACTURADOR,
    CLAVE_ALFABETICA_MONEDA, NUMERO_ESTABLECIMIENTO, FECHA_HORA_GRABACION
  FROM FICHEROS.V_OPERACIONES_MC_NO_APUNTE
  WHERE
    NUMERO_FICHERO = :WNum_Fichero
  ORDER BY CODIGO_PRODUCTO, NUMERO_ESTABLECIMIENTO, PANTOKEN, ABS(IMPORTE)
;
//--------------------------------------------------------
// ****************************************************************************
// PROCESO PRINCIPAL
// ****************************************************************************
dcl-proc main;

  dcl-pi *n;
    error char(1);
  end-pi;

  dcl-ds dsBlomaster likeds(dsBlomasterTpl) inz;
  dcl-ds dsImportesMC likeDs(dsImportesMCTpl) inz;
  dcl-ds dsImportesTotalEvidencia likeDs(dsImportesMCTpl) inz;
  dcl-s codSql char(5) inz;
  dcl-s hayDatos ind inz;
  dcl-s apunte char(6) inz;
  dcl-s establecimientoAux char(15) inz;
  dcl-s productoAux zoned(3:0) inz;

  // Para evidencias
  dcl-s marca char(1) inz;
  dcl-ds dsDetevi likeds(dsDeteviTempl) inz;
  dcl-s numeroLinea zoned(5:0) inz;

  // registro de error y notificaciones
  dcl-s observacionSql varchar(5000) inz;
  dcl-ds dsCorreoMC likeDs(dsCorreoMCTpl) inz;
  dcl-s observacion varchar(200) inz;


  // Para errores
  dcl-s correoErrorAlias ind;

  error = 'N';
  //Blomaster no debe tener ningun registro con apuntes
  if Valida_blomaster() =*on;
      error = 'S';
      return;
  Endif;

  correoErrorAlias = *off;
  if not Crear_Alias_Asifilen(correoErrorAlias);
    Borrar_Alias_Asifilen();
    correoErrorAlias = *on;
    if not Crear_Alias_Asifilen(correoErrorAlias);
      error = 'S';
      return;
    endif;
  endif;

  Exec Sql Open C0;

  dow SqlCode=0;
    Exec Sql Fetch C0 into :WNum_Fichero, :WFecha_grabacion;
    If Sqlcode<>0;
      leave;
    EndIf;

    fechaSistema = %timestamp();
    apunte = Asignar_Numero_Apunte(fechaSistema);
    establecimientoAux = '';
    productoAux = 0;
    hayDatos = *Off;

    //Montar_Consulta();

    Exec Sql Open C1;
    Exec Sql Fetch C1 into :dsBlomaster;

    dow sqlStt = '00000';

      if not hayDatos;// or wNumFichero <> dsBlomaster.numFichero;

        if hayDatos;
          exsr EvidenciasAsientoCambioFichero;
        endif;

        exsr InicializarDatos;

        if not Crear_Temporal_Detalle_Evidencia(dsDetevi);
          exsr IndicarError;
          return;
        endif;

        if not Guardar_Evidencia_Contable_Detalle_Cabecera(dsDetevi:numeroLinea);
          exsr IndicarError;
          return;
        endif;

        hayDatos = *on;
      endif;

      // Subtotal
        if  productoAux <> dsBlomaster.codProducto;
        if not Guardar_Evidencia_Contable_Detalle_Subtotal(dsDetevi:dsBlomaster.numFichero
              :productoAux:establecimientoAux:numeroLinea);
          exsr IndicarError;
          return;
        endif;

        // Asiento cuando cambia el producto
        if productoAux <> dsBlomaster.codProducto;
          if not Guardar_Asiento(productoAux:dsImportesMC:apunte:WFecha_grabacion);
            exsr IndicarError;
            return;
          endif;

          dsImportesMC.total = 0;
          dsImportesMC.comision = 0;
        endif;

        establecimientoAux = dsBlomaster.numeroEstablecimiento;
        productoAux = dsBlomaster.codProducto;
      endif;

      // Detalle
      if not Guardar_Evidencia_Contable_Detalle(dsBlomaster:dsDetevi:numeroLinea);
        exsr IndicarError;
        return;
      endif;

      dsImportesMC.total += dsBlomaster.importeEuros;
      dsImportesMC.comision += dsBlomaster.importeComision;
      dsImportesTotalEvidencia.total += dsBlomaster.importeEuros;
      dsImportesTotalEvidencia.comision += dsBlomaster.importeComision;


      Exec Sql Fetch C1 into :dsBlomaster;
    enddo;

    If sqlcode < 0 ;
      observacionSql = 'Error Montar_Consulta (FICHEROS.V_OPERACIONES_MC_NO_APUNTE)';
      clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROGRAMA:observacionSql);

      If Nivel_Alerta = 'HI';
          *INH1 =*On;
          *InLR = *on;
      Endif;

    Endif;
    Exec Sql Close C1;

    if hayDatos;
      exsr EvidenciasAsientoCambioFichero;
    endif;
  Enddo;

  Exec Sql Close C0;

  Borrar_Alias_Asifilen();

  *inlr = *on;

  //-----------------------------------------------------------------------------
  // Inicializamos datos
  //-----------------------------------------------------------------------------
  begsr InicializarDatos;

    numeroLinea = 0;
    dsImportesMC.total = 0;
    dsImportesMC.comision = 0;
    dsImportesTotalEvidencia.total = 0;
    dsImportesTotalEvidencia.comision = 0;

    wNumFichero = dsBlomaster.numFichero;
    establecimientoAux = dsBlomaster.numeroEstablecimiento;
    productoAux = dsBlomaster.codProducto;

    //apunte = Asignar_Numero_Apunte(fechaSistema);

    // Guardamos datos fijos de dsDetevi.
    // Luego creamos el fichero temporal de detalle y metemos la cabecera del detalle.
    dsDetevi.numeroApunte = apunte;
    dsDetevi.fechaConciliacion = %dec(%date(WFecha_grabacion):*ISO);
    dsDetevi.numeroEvidencia = %editc(%dec(%time(fechaSistema):*HMS):'X');

  endsr;

  //-----------------------------------------------------------------------------
  // Acciones a realizar al cambiar de fichero o para el último registro
  //-----------------------------------------------------------------------------
  begsr EvidenciasAsientoCambioFichero;

    // Ultimo subtotal
    if not Guardar_Evidencia_Contable_Detalle_Subtotal(dsDetevi:wNumFichero
          :productoAux:establecimientoAux:numeroLinea);
      exsr IndicarError_2;
      return;
    endif;

    // Gran total
    if not Guardar_Evidencia_Contable_Detalle_Gran_Total(dsDetevi:dsImportesTotalEvidencia
        :numeroLinea);
      exsr IndicarError_2;
      return;
    endif;

    // Asiento
    if not Guardar_Asiento(productoAux:dsImportesMC:apunte:WFecha_grabacion );
      exsr IndicarError_2;
      return;
    endif;

    // Pasar del temporal a Fichero DETEVI y grabamos por último la cabecera CABEVI
    if not Grabar_Temporal_A_Detevi(dsDetevi);
      exsr IndicarError_2;
      return;
    else;
      Guardar_Cabecera_Evidencia(wNumFichero:dsDetevi:WFecha_grabacion);
      Actualizar_Apunte_En_Control_Operaciones_MC(apunte);
    endif;

  endsr;

  //-----------------------------------------------------------------------------
  // Indicar error
  //-----------------------------------------------------------------------------
  begsr IndicarError;

    exec sql Close C1;
    error = 'S';
    Borrar_Alias_Asifilen();

  endsr;

  //-----------------------------------------------------------------------------
  // Indicar error 2
  //-----------------------------------------------------------------------------
  begsr IndicarError_2;

    error = 'S';
    Borrar_Alias_Asifilen();

  endsr;

end-proc;

//-----------------------------------------------------------------------------
// Guardar Asiento
//-----------------------------------------------------------------------------
dcl-proc Guardar_Asiento;

  dcl-pi *n ind;
    codProducto zoned(3:0);
    dsImportesMC likeDs(dsImportesMCTpl);
    apunte char(6) const;
    fechaSistema timestamp;
  end-pi;

  dcl-ds dsKeyAsiento likeds(dsKeyAsientoTpl) inz;
  dcl-ds dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl) inz;
  dcl-ds dsDatosAsientoNoParametrizables likeds(dsDatosAsientoNoParametrizablesTpl) inz;
  dcl-ds dsAsifilen likeds(dsAsifilenTpl) inz;
  dcl-s textoError char(100) inz;

  dsDatosAsientoNoParametrizables.numApunte = apunte;
  dsDatosAsientoNoParametrizables.fechaContable = %dec(%date(WFecha_grabacion):*EUR);
  dsDatosAsientoNoParametrizables.referenciaOperacion = *blanks;
  dsDatosAsientoNoParametrizables.fechaVencimiento = 0;
  dsDatosAsientoNoParametrizables.codMoneda = '1';
  dsDatosAsientoNoParametrizables.apunteProvisional = *blanks;
  dsDatosAsientoNoParametrizables.tipoOperacion = 0;

  if dsImportesMC.total <> 0;  // Esta es la validacion
    dsKeyAsiento.idAsiento = 1;
    dsKeyAsiento.ordenApunte = 1;
    dsKeyAsiento.codProducto = codProducto;
    if dsImportesMC.total >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(dsImportesMC.total);
    if not Obtener_Datos_Asiento(dsKeyAsiento:dsDatosAsientoParametrizables
        :dsDatosAsientoNoParametrizables:dsAsifilen:textoError);
      wNumError = '01';
      exsr LogCorreoError;
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      wNumError = '02';
      exsr LogCorreoError;
      return *off;
    endif;
  Endif;

  if dsImportesMC.comision <> 0;
    dsKeyAsiento.idAsiento = 1;
    dsKeyAsiento.ordenApunte = 3;
    dsKeyAsiento.codProducto = codProducto;
    if dsImportesMC.comision < 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(dsImportesMC.comision);
    if not Obtener_Datos_Asiento(dsKeyAsiento:dsDatosAsientoParametrizables
        :dsDatosAsientoNoParametrizables:dsAsifilen:textoError);
      wNumError = '04';
      exsr LogCorreoError;
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      wNumError = '05';
      exsr LogCorreoError;
      return *off;
    endif;
  endif;

  if dsImportesMC.total <> 0 ;

    dsKeyAsiento.idAsiento = 1;
    dsKeyAsiento.ordenApunte = 2;
    dsKeyAsiento.codProducto = codProducto;
    if dsImportesMC.total >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    endif;
    dsDatosAsientoNoParametrizables.importe =
          %abs(dsImportesMC.total) - %abs(dsImportesMC.comision);
    if not Obtener_Datos_Asiento(dsKeyAsiento:dsDatosAsientoParametrizables
        :dsDatosAsientoNoParametrizables:dsAsifilen:textoError);
      wNumError = '03';
      exsr LogCorreoError;
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      exsr LogCorreoError;
      return *off;
    endif;

  Endif;

  return *on;
  //---------------------------------------------------------------
  // Generar log y mandar correo de error
  //---------------------------------------------------------------
  begSr LogCorreoError;

    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Cod. Producto';
    dsLog.valor = %char(codProducto);
    dsLog.observacion = wNumError + '. Subrutina Guardar_Asiento';
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. Error al guardar el asiento al cambiar producto';
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Guardar_Asiento';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    dsCorreoMC.dsClaveValorMsg(3).clave = 'Producto';
    dsCorreoMC.dsClaveValorMsg(3).valor = %char(codProducto);
    dsCorreoMC.dsClaveValorMsg(4).clave = 'Apunte';
    dsCorreoMC.dsClaveValorMsg(4).valor = apunte;
    MC00002(dsCorreoMC);

  endSr;

end-proc;

//-----------------------------------------------------------------------------
// Guardar fichero temporal a DETEVI
//-----------------------------------------------------------------------------
dcl-proc Grabar_Temporal_A_Detevi;

  dcl-pi *n ind;
    dsDetevi likeDs(dsDeteviTempl);
  end-pi;

  dcl-s marca char(1) inz(GRABAR_A_FICHERO);

  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '17';
    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Fichero';
    dsLog.valor = %char(wNumFichero);
    dsLog.observacion = wNumError + '. Grabar_Temporal_A_Detevi. ' +
        sqlError + ' - ' + %trim(sqlMensaje);
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. ' + sqlError + ' - ' + %trim(sqlMensaje);
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Grabar_Temporal_A_Detevi';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    MC00002(dsCorreoMC);

    return *off;
  endif;

  return *on;

end-proc;

//-----------------------------------------------------------------------------
// Guardar cabecera evidencia contable
//-----------------------------------------------------------------------------
dcl-proc Guardar_Cabecera_Evidencia;

  dcl-pi *n ind;
    numFichero zoned(9:0);
    dsDetevi likeDs(dsDeteviTempl);
    fechaSistema timestamp;
  end-pi;

  dcl-ds dsCabevi likeds(dsCabeviTempl) inz;
  dcl-s fecha10 char(10) inz;

  fecha10 = Obtener_Fecha_Formateada(WFecha_grabacion);
  dsCabevi.descripcion = 'MASTERCARD. Fichero: ' +
             %Editc(WNum_Fichero:'X') + ' BLOMASTER '  +
             fecha10;
  dsCabevi.numeroApunte = dsDetevi.numeroApunte;
  dsCabevi.fechaConciliacion = dsDetevi.fechaConciliacion;
  dsCabevi.fechaBaja = 0;
  dsCabevi.pteModificar = *blanks;
  dsCabevi.numeroEvidencia = dsDetevi.numeroEvidencia;

  if not Guardar_Evidencias_Contables_Cabecera(dsCabevi:sqlError:sqlMensaje);
    wNumError = '15';

    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Num. Fichero';
    dsLog.valor = %char(wNumFichero);
    dsLog.observacion = wNumError + '. Guardar_Cabecera_Evidencia. ' +
        sqlError + ' - ' + %trim(sqlMensaje);
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. ' + sqlError + ' - ' + %trim(sqlMensaje);
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Guardar_Cabecera_Evidencia';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    MC00002(dsCorreoMC);

    return *off;
  endif;

  return *on;

end-proc;

//---------------------------------------------------------------
// Crear el fichero temporal del detalle de la evidencia
//---------------------------------------------------------------
dcl-proc Crear_Temporal_Detalle_Evidencia;

  dcl-pi *n ind;
    dsDetevi likeds(dsDeteviTempl);
  end-pi;

  dcl-s marca char(1) inz(CREAR_TEMPORAL);

  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '16';
    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Fichero';
    dsLog.valor = %char(wNumFichero);
    dsLog.observacion = wNumError + '. Crear_Temporal_Detalle_Evidencia. ' +
        sqlError + ' - ' + %trim(sqlMensaje);
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. ' + sqlError + ' - ' + %trim(sqlMensaje);
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Crear_Temporal_Detalle_Evidencia';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    MC00002(dsCorreoMC);

    return *off;
  endif;

  return *on;

end-proc;

//---------------------------------------------------------------
// Guardar el detalle de la evidencia. Parte de la cabecera
//---------------------------------------------------------------
dcl-proc Guardar_Evidencia_Contable_Detalle_Cabecera;

  dcl-pi Guardar_Evidencia_Contable_Detalle_Cabecera ind;
    dsDetevi likeds(dsDeteviTempl);
    numeroLinea zoned(5:0);
  end-pi;

  dcl-s marca char(1) inz;

  marca = GRABAR_TEMPORAL;
  dsDetevi.lineaTexto = 'NUMERO DE TARJETA   IMPORTE         COMISION        +
      TOTAL           ESTABLECIMIENTO  FICHERO   OPERACION      PRODUCTO';
  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;
  If not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '06';
    exsr LogCorreoError;
    return *off;
  EndIf;

  marca = GRABAR_TEMPORAL;
  dsDetevi.lineaTexto = '------------------  --------------- -------------   +
      -------------   ---------------  --------- -------------  --------';
  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;

  If not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '07';
    exsr LogCorreoError;
    return *off;
  EndIf;

  return *on;

  //---------------------------------------------------------------
  // Generar log y mandar correo de error
  //---------------------------------------------------------------
  begSr LogCorreoError;

    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Num. Fichero';
    dsLog.valor = %char(wNumFichero);
    dsLog.observacion = wNumError + '. Guardar_Evidencia_Contable_Detalle_Cabecera. ' +
        sqlError + ' - ' + %trim(sqlMensaje);
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. ' + sqlError + ' - ' + %trim(sqlMensaje);
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Guardar_Evidencia_Contable_Detalle_Cabecera';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    MC00002(dsCorreoMC);

  endSr;

end-proc;

//---------------------------------------------------------------
// Guardar detalle de evidencia contable
//---------------------------------------------------------------
dcl-proc Guardar_Evidencia_Contable_Detalle;

  dcl-pi Guardar_Evidencia_Contable_Detalle ind;
    dsBlomaster likeds(dsBlomasterTpl);
    dsDetevi likeds(dsDeteviTempl);
    numeroLinea zoned(5:0);
  end-pi;

  dcl-ds dsLineaTextoMC likeDs(dsLineaTextoMCTpl) inz;
  dcl-s total zoned(15:2) inz;
  dcl-s marca char(1);
  dcl-s wImporte zoned(15:3) inz;
  dcl-s wComision zoned(8:2) inz;

  marca = GRABAR_TEMPORAL;

  wImporte = dsBlomaster.importeEuros;
  wComision = dsBlomaster.importeComision;

  dsLineaTextoMC.pantoken = dsBlomaster.pantoken;
  dsLineaTextoMC.importe = %editc(wImporte:'K');
  dsLineaTextoMC.comision = %editc(wComision:'K');
  total = wImporte + wComision;
  dsLineaTextoMC.total = %editc(total:'K');

  dsLineaTextoMC.establecimiento = dsBlomaster.numeroEstablecimiento;
  dsLineaTextoMC.numFichero = %char(dsBlomaster.numFichero);
  dsLineaTextoMC.numOperacion = %char(dsBlomaster.numOperacion);

  Exec Sql
    SET :dsLineaTextoMC.abreviaturaProducto =
        OBTENER_ABREVIATURA_CORTA_PRODUCTO(:dsBlomaster.codProducto);

  dsDetevi.lineaTexto = dsLineaTextoMC.lineaTexto;
  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;

  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '08';
    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Num. Operacion';
    dsLog.valor = %char(dsBlomaster.numOperacion);
    dsLog.observacion = wNumError + '. Guardar_Evidencia_Contable_Detalle. ' +
      sqlError + ' - ' + %trim(sqlMensaje);
    dsLog.lineaFichero = %char(dsBlomaster.numOperacion);
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. ' + sqlError + ' - ' + %trim(sqlMensaje);
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Guardar_Evidencia_Contable_Detalle';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    dsCorreoMC.dsClaveValorMsg(3).clave = 'Num. Operacion';
    dsCorreoMC.dsClaveValorMsg(3).valor = %char(dsBlomaster.numOperacion);
    MC00002(dsCorreoMC);

    return *off;
  endif;

  return *on;

end-proc;

//---------------------------------------------------------------
// Guardar el subtotal de la evidencia por establecimiento
//---------------------------------------------------------------
dcl-proc Guardar_Evidencia_Contable_Detalle_Subtotal;

  dcl-pi Guardar_Evidencia_Contable_Detalle_Subtotal ind;
    dsDetevi likeds(dsDeteviTempl);
    numFichero zoned(9:0);
    codProducto zoned(3:0);
    establecimiento char(15);
    numeroLinea zoned(5:0);
  end-pi;

  dcl-s marca char(1) inz;
  dcl-ds dsLineaTextoSubtotalesMC likeds(dsLineaTextoSubtotalesMCTempl);
  dcl-ds dsSubtotal likeds(dsImportesMCTpl) inz;
  dcl-s total zoned(9:2) inz;

  marca = GRABAR_TEMPORAL;
  dsDetevi.lineaTexto = '                    --------------- --------------- +
      --------------  ---------------';
  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;
  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '09';
    exsr LogCorreoError;
    return *off;
  endif;

  dsSubtotal = Obtener_Importe_Parcial_Establecimiento(numFichero
      :codProducto:establecimiento);

  Exec Sql
    SET :dsLineaTextoSubtotalesMC.abreviaturaProducto =
        OBTENER_ABREVIATURA_CORTA_PRODUCTO(:codProducto);

  dsLineaTextoSubtotalesMC.importe = %editc(dsSubtotal.total:'K');
  dsLineaTextoSubtotalesMC.comision = %editc(dsSubtotal.comision:'K');
  total = dsSubtotal.total + dsSubtotal.comision;

  dsLineaTextoSubtotalesMC.total = %editc(total:'K');
  dsDetevi.lineaTexto = dsLineaTextoSubtotalesMC.lineaTexto;

  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;
  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '10';
    exsr LogCorreoError;
    return *off;
  endif;

  marca = GRABAR_TEMPORAL;
  dsDetevi.lineaTexto = '------------------  --------------- -------------   +
      -------------   ---------------  --------- -------------  --------';
  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;
  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '11';
    exsr LogCorreoError;
    return *off;
  endif;

  return *on;

  //---------------------------------------------------------------
  // Generar log y mandar correo de error
  //---------------------------------------------------------------
  begSr LogCorreoError;

    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Establecimiento';
    dsLog.valor = establecimiento;
    dsLog.observacion = wNumError + '. Guardar_Evidencia_Contable_Detalle_Subtotal. ' +
        sqlError + ' - ' + %trim(sqlMensaje);
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. ' + sqlError + ' - ' + %trim(sqlMensaje);
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Guardar_Evidencia_Contable_Detalle_Subtotal';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    dsCorreoMC.dsClaveValorMsg(3).clave = 'Establecimiento';
    dsCorreoMC.dsClaveValorMsg(3).valor = establecimiento;
    dsCorreoMC.dsClaveValorMsg(4).clave = 'Producto';
    dsCorreoMC.dsClaveValorMsg(4).valor = %char(codProducto);
    MC00002(dsCorreoMC);

  endSr;

end-proc;

//---------------------------------------------------------------
// Guardar el gran total de la evidencia
//---------------------------------------------------------------
dcl-proc Guardar_Evidencia_Contable_Detalle_Gran_Total;

  dcl-pi Guardar_Evidencia_Contable_Detalle_Gran_Total ind;
    dsDetevi likeds(dsDeteviTempl);
    dsImportesEvidencia likeds(dsImportesMCTpl);
    numeroLinea zoned(5:0);
  end-pi;

  dcl-ds dsLineaTextoGranTotalMC likeds(dsLineaTextoGranTotalMCTempl);
  dcl-s total zoned(9:2) inz;
  dcl-s marca char(1) inz;

  marca = GRABAR_TEMPORAL;
  dsDetevi.lineaTexto = '                    --------------- --------------- +
        ---------------                                                        ';
  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;
  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '12';
    exsr LogCorreoError;
    return *off;
  endif;

  dsLineaTextoGranTotalMC.importe = %editc(dsImportesEvidencia.total:'K');
  dsLineaTextoGranTotalMC.comision = %editc(dsImportesEvidencia.comision:'K');
  total = dsImportesEvidencia.total + dsImportesEvidencia.comision;
  dsLineaTextoGranTotalMC.total = %editc(total:'K');
  dsDetevi.lineaTexto = dsLineaTextoGranTotalMC.lineaTexto;

  numeroLinea += 1;
  dsDetevi.numeroLinea = numeroLinea;
  if not Guardar_Evidencias_Contables_Detalle(marca:dsDetevi:sqlError:sqlMensaje);
    wNumError = '13';
    exsr LogCorreoError;
    return *off;
  endif;

  return *on;

  //---------------------------------------------------------------
  // Generar log y mandar correo de error
  //---------------------------------------------------------------
  begSr LogCorreoError;

    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Fichero';
    dsLog.valor = %char(wNumFichero);
    dsLog.observacion = wNumError + '. Guardar_Evidencia_Contable_Detalle_Gran_Total. ' +
        sqlError + ' - ' + %trim(sqlMensaje);
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. ' + sqlError + ' - ' + %trim(sqlMensaje);
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Guardar_Evidencia_Contable_Detalle_Gran_Total';
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(1).valor = %char(wNumFichero);
    MC00002(dsCorreoMC);

  endSr;

end-proc;

//---------------------------------------------------------------
// Obtener importe parcial del fichero
//  SE MODIFICA POR CODIGO DE PRODUCTO
//---------------------------------------------------------------
dcl-proc Obtener_Importe_Parcial_Establecimiento;

  dcl-pi Obtener_Importe_Parcial_Establecimiento likeds(dsImportesMCTpl);
    numFichero zoned(9:0) const;
    codProducto zoned(3) const;
    establecimiento char(15) const;
  end-pi;

  dcl-ds dsImporte likeds(dsImportesMCTpl) inz;

  Exec Sql
    SELECT SUM(IMPORTE_EUROS), SUM(IMPORTE_COMISION)
      Into :dsImporte
    FROM FICHEROS.BLOMASTER
    WHERE
      CODIGO_PRODUCTO = :codProducto
      AND NUMERO_FICHERO = :WNUM_FICHERO
    ;

  return dsImporte;

end-proc;

//---------------------------------------------------------------
// Obtener fecha formateada
//---------------------------------------------------------------
dcl-proc Obtener_Fecha_Formateada;

  dcl-pi Obtener_Fecha_Formateada char(10);
    fecha timestamp const;
  end-pi;

  dcl-s wFecha char(8) inz;

  wFecha = %editc(%dec(%date(fecha):*ISO):'X');

  return %subst(wFecha:7:2) + '/' + %subst(wFecha:5:2) +
    '/' + %subst(wFecha:1:4);

end-proc;

//-----------------------------------------------------------------------------
// Crear el alias para ASIFILEN
//-----------------------------------------------------------------------------
dcl-proc Crear_Alias_Asifilen;

  dcl-pi *n ind;
    correoError ind;
  end-pi;

  Exec SQL
    CREATE ALIAS ASIFILEN FOR FICHEROS.ASIFILMC;

  if sqlStt <> '00000' and correoError;
    wNumError = '14';
    clear dsLog;
    clear dsCorreoMC;

    dsLog.programa = PROGRAMA;
    dsLog.campo = 'Num. Fichero';
    dsLog.valor = %char(wNumFichero);
    dsLog.observacion = wNumError + '. Crear_Alias_Asifilen. ' + sqlStt;
    dsLog.lineaFichero = *blanks;
    dsLog.lineaFuente = %char(srcListLineNum);
    dsLog.time_stamp = fechaSistema;
    Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
          dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);

    dsCorreoMC.listaDistribucion = 1;
    dsCorreoMC.programa = PROGRAMA;
    dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
    dsCorreoMC.mensaje = wNumError + '. Error al crear ALIAS del fichero ASIFILMC';
    dsCorreoMC.esError = *on;
    dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure Error';
    dsCorreoMC.dsClaveValorMsg(1).valor = 'Crear_Alias_Asifilen';
    dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
    dsCorreoMC.dsClaveValorMsg(2).valor = %char(wNumFichero);
    MC00002(dsCorreoMC);
  endif;

  if sqlStt <> '00000';
    return *off;
  endif;

  return *on;

end-proc;

//-----------------------------------------------------------------------------
// Actualizar el número de apunte en el control de operaciones MC
//-----------------------------------------------------------------------------
dcl-proc Actualizar_Apunte_En_Control_Operaciones_MC;

  dcl-pi *n;
    apunte char(6) const;
  end-pi;

  dcl-s observacionSql varchar(5000) inz;

  Exec Sql
    UPDATE FICHEROS.CONTROL_OPERACIONES_ENTRADA_MC A
      SET NUMERO_APUNTE = :apunte, FECHA_GRABACION_APUNTE = :fechaSistema
      WHERE TIPO = :TIPO_OPERACION
        AND A.NUMERO_FICHERO = :WNUM_FICHERO;

   If sqlcode < 0;
      clear Nivel_Alerta;
      observacionSql = 'Error en actualizar apuntes '+
                       '(FICHEROS.CONTROL_OPERACIONES_ENTRADA_MC)';
      Nivel_Alerta = Diagnostico(PROGRAMA:observacionSql);
   Endif;

end-proc;

//-----------------------------------------------------------------------------
// Borrar el alias para ASIFILEN
//-----------------------------------------------------------------------------
dcl-proc Borrar_Alias_Asifilen;

  dcl-pi *n ;
  end-pi;

  Exec SQL
    DROP ALIAS FICHEROS.ASIFILEN;

end-proc;

//-----------------------------------------------------------------------------
// Valida blomaster no debe tener apuntes si tiene no se procesa
//-----------------------------------------------------------------------------
Dcl-Proc Valida_Blomaster;
  Dcl-Pi *N Ind;
  End-Pi;

  Dcl-s hay_apunte char(1) inz;

  Exec SQL
    SELECT '1'
      into :hay_apunte
      FROM Blomaster B
           INNER JOIN Control_Operaciones_Entrada_Mc C
           ON B.Numero_Fichero = C.Numero_Fichero
           AND C.Tipo = 'OPERACIONES'
      WHERE C.Numero_Apunte <> ''
      limit 1;

      If hay_apunte = '1';
          clear dsLog;
          clear dsCorreoMC;
          dsLog.programa = PROGRAMA;
          dsLog.campo = 'Fichero';
          dsLog.valor =  '(Blomaster/Control_Operaciones_Entrada_Mc)';
          dsLog.observacion = 'BLOMASTER CON APUNTES, No debe tener'+
                              ' hasta despues de su ejecucion';
          dsLog.lineaFichero = *blanks;
          dsLog.lineaFuente = *blanks;
          dsLog.time_stamp = fechaSistema;
          Pgm_Grabamos_error(dsLog.observacion:dsLog.campo:dsLog.valor:dsLog.programa:
                dsLog.lineaFuente:dsLog.lineaFichero:dsLog.time_stamp);
          dsCorreoMC.listaDistribucion = 1;
          dsCorreoMC.programa = PROGRAMA;
          dsCorreoMC.asunto = %trim(PROGRAMA) + ' - KO';
          dsCorreoMC.mensaje = 'AL EJECUTAR MC000004,BLOMASTER YA TENIA APUNTES '+
          'Blomaster /Control_Operaciones_Entrada_Mc';
          dsCorreoMC.esError = *on;
          dsCorreoMC.dsClaveValorMsg(1).clave = 'Procedure MAIN';
          dsCorreoMC.dsClaveValorMsg(1).valor = 'validacion inicial';
          dsCorreoMC.dsClaveValorMsg(2).clave = 'Fichero';
          dsCorreoMC.dsClaveValorMsg(2).valor = 'Blomaster/Control_Operaciones_Entrada_Mc';
          MC00002(dsCorreoMC);

         return *on;

      Else;
         return *off;
      Endif;

end-proc;
