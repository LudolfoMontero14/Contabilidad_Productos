**FREE
  //**********************************************************************
  // UTILSCONTA
  // UTLIDADES CONTABILIDAD
  //
  //**********************************************************************
  // PROGRAMADOR: JOSE MANUEL MUÑOZ
  // FECHA: 29/11/2022
  //**********************************************************************
  // PROTOTYPES:
  //   UTILSCONTH
  // BINDING LANGUAGE:
  //   UTILSCONTA - EN EXPLOTA/QSRVSRC
  //
  // BINDING DIRECTORY
  //   EXPLOTA/CALDING
  //
  // COMPILAR:
  // CRTSQLRPGI OBJ(EXPLOTA/UTILSCONTA) COMMIT(*NONE)
  //     CLOSQLCSR(*ENDMOD) DBGVIEW(*SOURCE) OBJTYPE(*MODULE)
  //
  // CREAR SRVPGM:
  // CRTSRVPGM SRVPGM(EXPLOTA/UTILSCONTA) EXPORT(*SRCFILE)
  // SRCFILE(EXPLOTA/QSRVSRC) BNDSRVPGM((UTILITIES/SQLDIAGSRV))
  // ACTGRP(*CALLER)
  //
  // ADDBNDDIRE BNDDIR(EXPLOTA/CALDIG) OBJ(EXPLOTA/UTILSCONTA)
  //**********************************************************************
  ctl-opt decedit('0,') datedit(*dmy.)
    option(*srcstmt : *nodebugio : *noexpdds) nomain;

  /copy QRPGLESRC,UTILSCONTH
  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

  //---------------------------------------------------------------
  // Guardar Evidencias Contables - Cabecera
  //---------------------------------------------------------------
  dcl-proc Guardar_Evidencias_Contables_Cabecera export;

    dcl-pi Guardar_Evidencias_Contables_Cabecera ind;
      in_dsCabevi likeds(dsCabeviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
    end-pi;

    out_sqlError = *blanks;
    out_sqlMensaje = *blanks;

    Exec Sql
      INSERT INTO FICHEROS.CABEVI (CDESCR,
                                   CNUAPU,
                                   CFEALT,
                                   CFEBAJ,
                                   CNUEVI,
                                   CIDMOD)
                    VALUES(:in_dsCabevi.descripcion,
                           :in_dsCabevi.numeroApunte,
                           :in_dsCabevi.fechaConciliacion,
                           :in_dsCabevi.fechaBaja,
                           :in_dsCabevi.numeroEvidencia,
                           :in_dsCabevi.pteModificar);

    If sqlStt <> '00000';
      out_sqlError = sqlStt;
      Exec Sql
        GET DIAGNOSTICS EXCEPTION 1 :out_sqlMensaje = MESSAGE_TEXT;
      return *off;
    EndIf;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Guardar Evidencias Contables - Detalle
  // Marca: C - Crear Fic. Temporal
  //        G - Grabar en Fic Temporal
  //        F - Finalizar y Grabar en Fichero Final
  //---------------------------------------------------------------
  dcl-proc Guardar_Evidencias_Contables_Detalle export;

    dcl-pi Guardar_Evidencias_Contables_Detalle ind;
      in_marca char(1);
      in_dsDetevi likeds(dsDeteviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
    end-pi;

    dcl-s nombreFichero char(50) inz;

    out_sqlError = *blanks;
    out_sqlMensaje = *blanks;

    nombreFichero = 'DETEVI' + in_dsDetevi.numeroApunte +
      %editc(in_dsDetevi.fechaConciliacion:'X') + in_dsDetevi.numeroEvidencia;

    Select;
      When in_marca = 'C';
        return Crear_Fichero_Detalle_Evidencia_Temporal(nombreFichero
          :out_sqlError:out_sqlMensaje);
      When in_marca = 'G';
        return Grabar_Detalle_Evidencia_Temporal(nombreFichero:in_dsDetevi
          :out_sqlError:out_sqlMensaje);
      When in_marca = 'F';
        return Grabar_Detalles_Evidencias(nombreFichero:in_dsDetevi
          :out_sqlError:out_sqlMensaje);
      Other;
        out_sqlMensaje = 'Marca Errónea: ' + in_marca;
        return *off;
    EndSl;

  end-proc;

  //---------------------------------------------------------------
  // Crear fichero detalle de Evidencia Temporal
  //---------------------------------------------------------------
  dcl-proc Crear_Fichero_Detalle_Evidencia_Temporal;

    dcl-pi Crear_Fichero_Detalle_Evidencia_Temporal ind;
      in_nombreFichero char(50);
      out_sqlError char(5);
      out_sqlMensaje char(70);
    end-pi;

    dcl-s consulta char(1000) inz;

    consulta = 'DROP TABLE QTEMP.' + %trim(in_nombreFichero);

    Monitor;
      Exec Sql
        Execute Immediate :consulta;
    On-Error;
    EndMon;

    consulta = 'CREATE TABLE QTEMP.' + %trim(in_nombreFichero) +
      ' AS (SELECT * FROM FICHEROS.DETEVI) WITH NO DATA';

    Monitor;
      Exec Sql
        Execute Immediate :consulta;

      If sqlStt <> '00000';
        out_sqlError = sqlStt;
        Exec Sql
          GET DIAGNOSTICS EXCEPTION 1 :out_sqlMensaje = MESSAGE_TEXT;
        return *off;
      EndIf;

    On-Error;
      out_sqlMensaje = 'Error Monitorizado. Crear_Fichero_Detalle_Evidencia_Temporal';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Grabar registro en el temporal de Detalle de Evidencias
  //---------------------------------------------------------------
  dcl-proc Grabar_Detalle_Evidencia_Temporal;

    dcl-pi Grabar_Detalle_Evidencia_Temporal ind;
      in_nombreFichero char(50);
      in_dsDetevi likeds(dsDeteviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
    end-pi;

    dcl-s consulta char(1000) inz;

    consulta = 'INSERT INTO  QTEMP.' + %trim(in_nombreFichero) +
      '(ELINEA, ENULIN, ENUAPU, EFEALT, ENUEVI) +
      VALUES(''' + in_dsDetevi.lineaTexto +
             ''', ' + %editc(in_dsDetevi.numeroLinea:'X') +
             ', ''' + %trim(in_dsDetevi.numeroApunte) +
             ''', ' + %editc(in_dsDetevi.fechaConciliacion:'X') +
             ', ''' + %trim(in_dsDetevi.numeroEvidencia) + ''')';

    Monitor;
      Exec Sql
        Execute Immediate :consulta;

      If sqlStt <> '00000';
        out_sqlError = sqlStt;
        Exec Sql
          GET DIAGNOSTICS EXCEPTION 1 :out_sqlMensaje = MESSAGE_TEXT;
        return *off;
      EndIf;

    On-Error;
      out_sqlMensaje = 'Error Monitorizado. Grabar_Detalle_Evidencia_Temporal';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Grabar desde el fichero temporal al fichero final
  //---------------------------------------------------------------
  dcl-proc Grabar_Detalles_Evidencias;

    dcl-pi Grabar_Detalles_Evidencias ind;
      in_nombreFichero char(50);
      in_dsDetevi likeds(dsDeteviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
    end-pi;

    dcl-s consulta char(500) inz;

    consulta = 'INSERT INTO FICHEROS.DETEVI +
     SELECT * FROM QTEMP.' + %trim(in_nombreFichero);

    Monitor;
      Exec Sql
        Execute Immediate :consulta;

      If sqlStt <> '00000';
        out_sqlError = sqlStt;
        Exec Sql
          GET DIAGNOSTICS EXCEPTION 1 :out_sqlMensaje = MESSAGE_TEXT;
        return *off;
      EndIf;

    On-Error;
      out_sqlMensaje = 'Error Monitorizado. Grabar_Detalles_Evidencias';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Borrar Evidencia Contable - Cabecera
  //---------------------------------------------------------------
  dcl-proc Borrar_Evidencias_Contables_Cabecera export;

    dcl-pi Borrar_Evidencias_Contables_Cabecera ind;
      in_dsCabevi likeds(dsCabeviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
    end-pi;

    out_sqlError = *blanks;
    out_sqlMensaje = *blanks;

    Exec Sql
      DELETE FROM FICHEROS.CABEVI
      WHERE CNUAPU = :in_dsCabevi.numeroApunte
        AND CFEALT = :in_dsCabevi.fechaConciliacion
        AND CNUEVI = :in_dsCabevi.numeroEvidencia;

    If sqlStt <> '00000';
      out_sqlError = sqlStt;
      Exec Sql
        GET DIAGNOSTICS EXCEPTION 1 :out_sqlMensaje = MESSAGE_TEXT;
      return *off;
    EndIf;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Obtener Datos de Asiento
  //
  // Si está informado dsKeyAsiento lo uso para cargar dsDatosAsientoParametrizables
  // Si no está informado dsKeyAsiento uso dsDatosAsientoParametrizables
  //---------------------------------------------------------------
  dcl-proc Obtener_Datos_Asiento export;

    dcl-pi *n ind;
      dsKeyAsiento likeds(dsKeyAsientoTpl);
      dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl);
      dsDatosAsientoNoParametrizables likeds(dsDatosAsientoNoParametrizablesTpl);
      dsAsifilen likeds(dsAsifilenTpl);
      textoError char(100);
    end-pi;

    dcl-ds dsDatosAsientoParametrizablesSinDato likeds(dsDatosAsientoNoParametrizablesTpl) inz;

    exsr ValidacionesDatosAsiento;
    if textoError <> *blanks;
      return *off;
    endif;

    dsAsifilen.capunt = dsDatosAsientoNoParametrizables.numApunte;
    dsAsifilen.cctama = dsDatosAsientoParametrizables.cuentaMayor;
    dsAsifilen.cctafi = dsDatosAsientoParametrizables.ficheroAsociado;
    dsAsifilen.cctaau = dsDatosAsientoParametrizables.cuentaAuxiliar;
    dsAsifilen.ccodig = dsDatosAsientoParametrizables.codigoConcepto;
    dsAsifilen.cprogr = dsDatosAsientoParametrizables.proceso;
    dsAsifilen.cfecon = dsDatosAsientoNoParametrizables.fechaContable;
    dsAsifilen.cdeha = dsDatosAsientoNoParametrizables.debeHaber;
    dsAsifilen.crefop = dsDatosAsientoNoParametrizables.referenciaOperacion;
    dsAsifilen.cfevto = dsDatosAsientoNoParametrizables.fechaVencimiento;
    dsAsifilen.cconce = dsDatosAsientoParametrizables.textoConcepto;
    dsAsifilen.cimpor = dsDatosAsientoNoParametrizables.importe;
    dsAsifilen.cmoned = dsDatosAsientoNoParametrizables.codMoneda;
    dsAsifilen.cprovi = dsDatosAsientoNoParametrizables.apunteProvisional;
    dsAsifilen.ctipop = dsDatosAsientoNoParametrizables.tipoOperacion;
    dsAsifilen.ctipro = dsDatosAsientoParametrizables.tipoProcedencia;
    dsAsifilen.cctana = dsDatosAsientoParametrizables.cuentaNavision;
    dsAsifilen.ccodma = dsDatosAsientoParametrizables.codigoMayor;
    dsAsifilen.crefde = dsDatosAsientoParametrizables.referenciaDocumentoExterna;
    dsAsifilen.cddept = dsDatosAsientoParametrizables.dimensionDepartamento;
    dsAsifilen.cdanlt = dsDatosAsientoParametrizables.dimensionConcepto;
    dsAsifilen.cdeban = dsDatosAsientoParametrizables.dimensionJerarquia;
    dsAsifilen.cdpers = dsDatosAsientoParametrizables.dimensionGastos;
    dsAsifilen.cdgfin = dsDatosAsientoParametrizables.dimensionProducto;
    dsAsifilen.cdim06 = dsDatosAsientoParametrizables.dimensionLibre1;
    dsAsifilen.cdim07 = dsDatosAsientoParametrizables.dimensionLibre2;
    dsAsifilen.cdim08 = dsDatosAsientoParametrizables.dimensionLibre3;

    return *on;

    //---------------------------------------------------------------
    // Validar los datos del asiento
    //---------------------------------------------------------------
    begsr ValidacionesDatosAsiento;

      textoError = *blanks;

      if textoError = *blanks and (dsKeyAsiento.idAsiento <= 0
          or dsKeyAsiento.ordenApunte <= 0
          or dsKeyAsiento.codProducto <= 0)
          and (dsDatosAsientoNoParametrizables = dsDatosAsientoParametrizablesSinDato);
        textoError = 'No enviados ni clave ni datos parametrizados de asiento';
      endif;

      if textoError = *blanks and dsKeyAsiento.idAsiento > 0
          and not Obtener_Datos_Parametrizados_Asiento(dsKeyAsiento:dsDatosAsientoParametrizables);
        textoError = 'Enviada clave, pero no se han podido obtener datos +
            parametrizados de asiento';
      endif;

      if textoError = *blanks and (dsDatosAsientoParametrizables.proceso = *blanks
          or dsDatosAsientoParametrizables.descripcionAsiento = *blanks
          or dsDatosAsientoParametrizables.tipoProcedencia = *blanks
          //or dsDatosAsientoParametrizables.cuentaNavision = *blanks
          or dsDatosAsientoParametrizables.codigoMayor = *blanks);
        textoError = 'Faltan algunos campos clave de datos parametrizados del asiento';
      endif;

      if textoError = *blanks and dsDatosAsientoNoParametrizables.numApunte = *blanks;
        textoError = 'Número de apunte no enviado';
      endif;

      monitor;
        if textoError = *blanks and
          %dec(dsDatosAsientoNoParametrizables.numApunte:6:0) <= 0;
          textoError = 'Número de apunte erroneo. Valor ' +
              %trim(dsDatosAsientoNoParametrizables.numApunte);
        endif;
      on-error;
          textoError = 'Número de apunte erroneo. Error monitorizado. Valor' +
              %trim(dsDatosAsientoNoParametrizables.numApunte);
      endmon;

      if textoError = *blanks;
        test(de) *eur dsDatosAsientoNoParametrizables.fechaContable;
        if (%error);
          textoError = 'Fecha contable erronea' +
              %char(dsDatosAsientoNoParametrizables.fechaContable);
        endif;
      endif;

      if textoError = *blanks and not
          (dsDatosAsientoNoParametrizables.debeHaber in %list('D':'H'));
        textoError = 'Debe/Haber distinto de D o H. Valor enviado ' +
            dsDatosAsientoNoParametrizables.debeHaber;
      endif;

      // Opcional pero si se envía debe ser correcta
      if textoError = *blanks and dsDatosAsientoNoParametrizables.fechaVencimiento <> 0;
        test(de) *eur dsDatosAsientoNoParametrizables.fechaVencimiento;
        if (%error);
          textoError = 'Fecha vencimiento enviada erronea. ' +
              %char(dsDatosAsientoNoParametrizables.fechaVencimiento);
        endif;
      endif;

      if textoError = *blanks and dsDatosAsientoNoParametrizables.importe = 0;
        textoError = 'Importe enviado es cero';
      endif;

      // Las monedas ahora mismo son blanco (Ptas) o 1 (Euros)
      // Esto puede cambiar!!!!
      if textoError = *blanks and not
          (dsDatosAsientoNoParametrizables.codMoneda in %list(' ':'1'));
        textoError = 'Código de moneda erroneo';
      endif;

      // Apunte Provisional no es obligatorio y no están definidos los valores posibles
      // dsDatosAsientoParametrizables.apunteProvisional

      // Tipo de operación no es obligatorio y no están definidos los valores posibles
      // dsDatosAsientoParametrizables.tipoOperacion

    endsr;

  end-proc;

  //---------------------------------------------------------------
  // Obtener los datos parametrizados del Asiento
  //---------------------------------------------------------------
  dcl-proc Obtener_Datos_Parametrizados_Asiento export;

    dcl-pi *n ind;
      dsKeyAsiento likeds(dsKeyAsientoTpl);
      dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl);
    end-pi;

    if dsKeyAsiento.idAsiento <= 0
        or dsKeyAsiento.ordenApunte <= 0
        or dsKeyAsiento.codProducto <= 0;
      return *off;
    endif;

    Exec Sql
      SELECT PROCESO, DESCRIPCION_ASIENTO, TIPO_PROCEDENCIA, CUENTA_NAVISION, CODIGO_MAYOR,
             CUENTA_MAYOR, FICHERO_ASOCIADO, CUENTA_AUXILIAR, CODIGO_CONCEPTO, TEXTO_CONCEPTO,
             REFERENCIA_DOCUMENTO_EXTERNA, DIMENSION_DEPARTAMENTO, DIMENSION_CONCEPTO,
             DIMENSION_JERARQUIA, DIMENSION_GASTOS, DIMENSION_PRODUCTO, DIMENSION_LIBRE1,
             DIMENSION_LIBRE2, DIMENSION_LIBRE3
      into :dsDatosAsientoParametrizables
      FROM FICHEROS.ASIENTOS_CUENTAS_POR_PRODUCTO
      WHERE ID_ASIENTO = :dsKeyAsiento.idAsiento
        AND ORDEN_APUNTE = :dsKeyAsiento.ordenApunte
        AND CODIGO_PRODUCTO = :dsKeyAsiento.codProducto;

    return sqlStt = '00000';

  end-proc;

  //---------------------------------------------------------------
  // Grabar Asiento
  //---------------------------------------------------------------
  dcl-proc Grabar_Asiento export;

    dcl-pi *n ind;
      dsAsifilen likeds(dsAsifilenTpl) const;
      sqlError char(5);
      sqlMensaje char(70);
    end-pi;

    dcl-s consulta char(500) inz;

    Exec Sql
      INSERT INTO FICHEROS.ASIFILEN
                      (CAPUNT, CCTAMA, CCTAFI, CCTAAU, CCODIG, CPROGR,
                      CFECON, CDEHA, CREFOP, CFEVTO, CCONCE, CIMPOR,
                      CMONED, CPROVI, CTIPOP, CTIPRO, CCTANA, CCODMA,
                      CREFDE, CDDEPT, CDANLT, CDEBAN, CDPERS, CDGFIN,
                      CDIM06, CDIM07, CDIM08)
              VALUES (:dsAsifilen);

    if sqlStt <> '00000';
      sqlError = sqlStt;
      exec sql
        GET DIAGNOSTICS EXCEPTION 1 :sqlMensaje = MESSAGE_TEXT;
      return *off;
    endif;

    return *on;

  end-proc;

  //-----------------------------------------------------------------------------
  // Asignar número de apunte
  //-----------------------------------------------------------------------------
  dcl-proc Asignar_Numero_Apunte export;

    dcl-pi *n char(6);
      fecha timestamp const;
    end-pi;

    dcl-s anio char(2) inz;
    dcl-s wMes zoned(2:0) inz;
    dcl-s mes char(2) inz;
    dcl-s apunte char(6) inz;

    anio = %subst(%char(%subdt(fecha:*YEARS)):3:2);
    wMes = %subdt((fecha):*MONTHS);
    mes = %editc(wMes:'X');

    ASBUNU(anio:mes:apunte);

    return apunte;

  end-proc;

  //-----------------------------------------------------------------
  // Genera Contabilidad por Totales por Prodicto
  //-----------------------------------------------------------------
  dcl-proc Genera_Contabilidad_Totales_Producto export;

    dcl-pi *n;
      Acumulador   likeds(Acumulador_Array) Dim(100);
      Inx          Zoned(3);
      ID_Contab    Zoned(5);
      Num_Apunte   Char(6);
      fecproces    Zoned(8);
    end-pi;

    Dcl-s I        Zoned(3);
    Dcl-s WMarca   Zoned(2);
    Dcl-s WCodProd Zoned(3);
    Dcl-s WExiste_Cod   Ind;

    For I=1 to Inx;

      // Se verifica Producto
      WCodProd = Acumulador(I).Cod_prod;
      If WCodProd = 777;
        WMarca = 1; // Diners por defecto
      Else;
        Exec SQL
          Select Codigo_Marca
          Into :WMarca
          From PRODUCTOS_DCS
          Where
            CODIGO_PRODUCTO = :WCodProd;
      Endif;

      If Sqlcode < 0;
        observacionSql = 'Genera_Contabilidad_Totales_Producto: ' +
                         'Error en Select PRODUCTOS_DCS';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      EndIf;
      If SQLCODE<>0;
          Iter;
      EndIf;

      Exec SQL
        Select '1'
        Into :WExiste_Cod
        From ASIENTOS_CUENTAS_POR_PRODUCTO
        Where
          ID_ASIENTO = :ID_Contab
          AND CODIGO_PRODUCTO = :WCodProd
        Limit 1;

      If Sqlcode < 0;
        observacionSql = 'Genera_Contabilidad_Totales_Producto: ' +
                         'Error en Select ASIENTOS_CUENTAS_POR_PRODUCTO';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      EndIf;

      Select;
        When Not WExiste_Cod and WMarca=1; // Valida Diners s/conciliacion
          WCodprod = 999;
        When Not WExiste_Cod and WMarca=2; // Valida Mastercard
          WCodprod = 998;
      EndSl;

      if not Guardar_Asiento_Total_producto(
            WCodprod:
            Acumulador(I).Total:
            Num_Apunte:
            fecproces:
            ID_Contab);
        Leave;
      endif;

    EndFor;

  end-proc;
  //-----------------------------------------------------------------------------
  // Guardar Asiento por Total por producto
  //-----------------------------------------------------------------------------
  dcl-proc Guardar_Asiento_Total_producto;

    dcl-pi *n ind;
      WCodprod     zoned(3:0);
      P_Impor      Packed(14:3);
      Num_Apunte   char(6) const;
      fecproces    Zoned(8);
      ID_Contab    Zoned(5);
    end-pi;

    dcl-ds dsKeyAsiento likeds(dsKeyAsientoTpl) inz;
    dcl-ds dsDatosAsientoParametrizables
            likeds(dsDatosAsientoParametrizablesTpl) inz;
    dcl-ds dsDatosAsientoNoParametrizables
            likeds(dsDatosAsientoNoParametrizablesTpl) inz;
    dcl-ds dsAsifilen likeds(dsAsifilenTpl) inz;
    dcl-s textoError char(100) inz;
    dcl-s sqlError char(5) inz;
    dcl-s sqlMensaje char(70) inz;

    dsDatosAsientoNoParametrizables.numApunte = Num_Apunte;
    dsDatosAsientoNoParametrizables.fechaContable = fecproces ;
    dsDatosAsientoNoParametrizables.referenciaOperacion = *blanks;
    dsDatosAsientoNoParametrizables.fechaVencimiento = 0;
    dsDatosAsientoNoParametrizables.codMoneda = '1';
    dsDatosAsientoNoParametrizables.apunteProvisional = *blanks;
    dsDatosAsientoNoParametrizables.tipoOperacion = 0;

    // ************  Orden 1 (Haber)
    dsKeyAsiento.idAsiento = ID_Contab;
    dsKeyAsiento.ordenApunte = 1;
    dsKeyAsiento.codProducto = WCodprod;

    if P_Impor >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(P_Impor);

    if not Obtener_Datos_Asiento(
            dsKeyAsiento:
            dsDatosAsientoParametrizables:
            dsDatosAsientoNoParametrizables:
            dsAsifilen:textoError);
      // Agregar funcion de monitoreo de Errores y correo
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      // Agregar funcion de monitoreo de Errores y correo
      return *off;
    endif;

    // ************  Orden 2 (Debito)
    dsKeyAsiento.idAsiento = ID_Contab;
    dsKeyAsiento.ordenApunte = 2;
    dsKeyAsiento.codProducto = WCodprod;

    if P_Impor >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(P_Impor);
    if not Obtener_Datos_Asiento(
            dsKeyAsiento:
            dsDatosAsientoParametrizables:
            dsDatosAsientoNoParametrizables:
            dsAsifilen:textoError);
      // Agregar funcion de monitoreo de Errores y correo
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      // Agregar funcion de monitoreo de Errores y correo
      return *off;
    endif;

    return *on;
  end-proc;
