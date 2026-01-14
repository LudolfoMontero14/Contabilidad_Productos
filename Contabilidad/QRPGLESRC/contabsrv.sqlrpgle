**FREE
  //**********************************************************************
  // CONTABSRV
  // UTLIDADES CONTABILIDAD
  //
  //**********************************************************************
  // PROGRAMADOR: Ludolfo Montero 
  // FECHA: Octubre 2025
  //**********************************************************************
  // PROTOTYPES:
  //   CONTABSRVH
  // BINDING LANGUAGE:
  //   CONTABSRV - EN EXPLOTA/QSRVSRC
  //
  // BINDING DIRECTORY
  //   EXPLOTA/CALDING
  //
  // COMPILAR:
  // CRTSQLRPGI OBJ(EXPLOTA/CONTABSRV) COMMIT(*NONE)
  //     CLOSQLCSR(*ENDMOD) DBGVIEW(*SOURCE) OBJTYPE(*MODULE)
  //
  // CREAR SRVPGM:
  // CRTSRVPGM SRVPGM(EXPLOTA/CONTABSRV) EXPORT(*SRCFILE)
  // SRCFILE(EXPLOTA/QSRVSRC) BNDSRVPGM((UTILITIES/SQLDIAGSRV))
  // ACTGRP(*CALLER)
  //
  // ADDBNDDIRE BNDDIR(EXPLOTA/CONTBNDDIR) OBJ(EXPLOTA/CONTABSRV)
  //**********************************************************************
  ctl-opt decedit('0,') datedit(*dmy.)
    option(*srcstmt : *nodebugio : *noexpdds) nomain;

  /copy Explota/QRPGLESRC,CONTABSRVH
  /copy Utilities/QRPGLESRC,PSDSCP         // psds
  /Include Utilities/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

  //---------------------------------------------------------------
  // Guardar Evidencias Contables - Cabecera
  //---------------------------------------------------------------
  dcl-proc CONTABSRV_Guardar_Evidencias_Contables_Cabecera export;

    dcl-pi CONTABSRV_Guardar_Evidencias_Contables_Cabecera ind;
      in_dsCabevi likeds(dsCabeviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
      in_NomCabpar Char(10);
    end-pi;

    dcl-s SqlStr char(1000) inz;

    out_sqlError = *blanks;
    out_sqlMensaje = *blanks;

    SqlStr = 
      'INSERT INTO '                                       +
      %Trim(in_NomCabpar)                                  +
      ' (CDESCR, CNUAPU, CFEALT, CFEBAJ, CNUEVI, CIDMOD) ' +
      'VALUES(?,?,?,?,?,?)';

    exec sql prepare SZ from :SqlStr;
    exec sql execute SZ using 
        :in_dsCabevi.descripcion,
        :in_dsCabevi.numeroApunte,
        :in_dsCabevi.fechaConciliacion,
        :in_dsCabevi.fechaBaja,
        :in_dsCabevi.numeroEvidencia,
        :in_dsCabevi.pteModificar;


    If sqlStt <> '00000';
      out_sqlError = sqlStt;
      Exec Sql
        GET DIAGNOSTICS EXCEPTION 1 
        :out_sqlMensaje = MESSAGE_TEXT;
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
  dcl-proc CONTABSRV_Guardar_Evidencias_Contables_Detalle export;

    dcl-pi CONTABSRV_Guardar_Evidencias_Contables_Detalle ind;
      in_marca char(1);
      in_dsDetevi likeds(dsDeteviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
      in_NomDetpar Char(10);
    end-pi;

    dcl-s nombreFichero char(50) inz;

    out_sqlError = *blanks;
    out_sqlMensaje = *blanks;

    nombreFichero = 'DETEVI' + in_dsDetevi.numeroApunte +
      %editc(in_dsDetevi.fechaConciliacion:'X') + in_dsDetevi.numeroEvidencia;

    Select;
      When in_marca = 'C';
        return CONTABSRV_Crear_Fichero_Detalle_Evidencia_Temporal(
          nombreFichero
          :out_sqlError
          :out_sqlMensaje);
      When in_marca = 'G';
        return CONTABSRV_Grabar_Detalle_Evidencia_Temporal(
          nombreFichero
          :in_dsDetevi
          :out_sqlError
          :out_sqlMensaje);
      When in_marca = 'F';
        return CONTABSRV_Grabar_Detalles_Evidencias(
          nombreFichero
          :in_dsDetevi
          :out_sqlError
          :out_sqlMensaje
          :in_NomDetpar);
      Other;
        out_sqlMensaje = 'Marca Errónea: ' + in_marca;
        return *off;
    EndSl;

  end-proc;

  //---------------------------------------------------------------
  // Crear fichero detalle de Evidencia Temporal
  //---------------------------------------------------------------
  dcl-proc CONTABSRV_Crear_Fichero_Detalle_Evidencia_Temporal;

    dcl-pi CONTABSRV_Crear_Fichero_Detalle_Evidencia_Temporal ind;
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
      out_sqlMensaje = 
      'Error Monitorizado. CONTABSRV_Crear_Fichero_Detalle_Evidencia_Temporal';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Grabar registro en el temporal de Detalle de Evidencias
  //---------------------------------------------------------------
  dcl-proc CONTABSRV_Grabar_Detalle_Evidencia_Temporal;

    dcl-pi CONTABSRV_Grabar_Detalle_Evidencia_Temporal ind;
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
      out_sqlMensaje = 
        'Error Monitorizado. CONTABSRV_Grabar_Detalle_Evidencia_Temporal';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Grabar desde el fichero temporal al fichero final
  //---------------------------------------------------------------
  dcl-proc CONTABSRV_Grabar_Detalles_Evidencias;

    dcl-pi CONTABSRV_Grabar_Detalles_Evidencias ind;
      in_nombreFichero char(50);
      in_dsDetevi likeds(dsDeteviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
      in_NomDetpar char(10);
    end-pi;

    dcl-s consulta char(500) inz;

    consulta = 'INSERT INTO '                +
    in_NomDetpar                             +
    'SELECT * FROM QTEMP.' + %trim(in_nombreFichero);

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
      out_sqlMensaje = 
        'Error Monitorizado. CONTABSRV_Grabar_Detalles_Evidencias';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Borrar Evidencia Contable - Cabecera
  //---------------------------------------------------------------
  dcl-proc CONTABSRV_Borrar_Evidencias_Contables_Cabecera export;

    dcl-pi CONTABSRV_Borrar_Evidencias_Contables_Cabecera ind;
      in_dsCabevi likeds(dsCabeviTempl);
      out_sqlError char(5);
      out_sqlMensaje char(70);
      in_NomCabpar Char(10);
    end-pi;

    dcl-s SqlStr char(1000) inz;

    out_sqlError = *blanks;
    out_sqlMensaje = *blanks;

    SqlStr = 
      'DELETE FROM '                                    +
      %trim(in_NomCabpar)                               +
      ' WHERE CNUAPU = ' + in_dsCabevi.numeroApunte     +
      '   AND CFEALT = ' + %Editc(in_dsCabevi.fechaConciliacion:'X') +
      '   AND CNUEVI = ' + in_dsCabevi.numeroEvidencia;


    Monitor;
      Exec Sql
        Execute Immediate :SqlStr;
    
      If sqlStt <> '00000';
        out_sqlError = sqlStt;
        Exec Sql
          GET DIAGNOSTICS EXCEPTION 1 :out_sqlMensaje = MESSAGE_TEXT;
        return *off;
      EndIf;

    On-Error;
      out_sqlMensaje = 
        'Error Monitorizado. CONTABSRV_Borrar_Evidencias_Contables_Cabecera';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //---------------------------------------------------------------
  // Obtener Datos de Asiento
  // Si está informado dsKeyAsiento lo uso para cargar 
  // dsDatosAsientoParametrizables
  // Si no está informado dsKeyAsiento uso dsDatosAsientoParametrizables
  //---------------------------------------------------------------
  dcl-proc CONTABSRV_Obtener_Datos_Asiento export;

    dcl-pi *n ind;
      dsKeyAsiento likeds(dsKeyAsientoTpl);
      dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl);
      dsDatosAsientoNoParametrizables 
          likeds(dsDatosAsientoNoParametrizablesTpl);
      dsAsifilen likeds(dsAsifilenTpl);
      textoError char(100);
    end-pi;

    dcl-ds dsDatosAsientoParametrizablesSinDato 
           likeds(dsDatosAsientoNoParametrizablesTpl) inz;

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
    dsAsifilen.crefde = 
               dsDatosAsientoParametrizables.referenciaDocumentoExterna;
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
          and (dsDatosAsientoNoParametrizables = 
              dsDatosAsientoParametrizablesSinDato);
        textoError = 'No enviados ni clave ni datos parametrizados de asiento';
      endif;

      if textoError = *blanks and dsKeyAsiento.idAsiento > 0
          and not CONTABSRV_Obtener_Datos_Parametrizados_Asiento(
                  dsKeyAsiento
                  :dsDatosAsientoParametrizables);
        textoError = 'Enviada clave, pero no se han podido obtener datos +
            parametrizados de asiento';
      endif;

      if textoError = *blanks and 
          (dsDatosAsientoParametrizables.proceso = *blanks
          or dsDatosAsientoParametrizables.descripcionAsiento = *blanks
          or dsDatosAsientoParametrizables.tipoProcedencia = *blanks
          //or dsDatosAsientoParametrizables.cuentaNavision = *blanks
          or dsDatosAsientoParametrizables.codigoMayor = *blanks);
        textoError = 
            'Faltan algunos campos clave de datos parametrizados del asiento';
      endif;

      if textoError = *blanks and 
         dsDatosAsientoNoParametrizables.numApunte = *blanks;
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
      if textoError = *blanks and 
         dsDatosAsientoNoParametrizables.fechaVencimiento <> 0;
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

    endsr;

  end-proc;

  //---------------------------------------------------------------
  // Obtener los datos parametrizados del Asiento
  //---------------------------------------------------------------
  dcl-proc CONTABSRV_Obtener_Datos_Parametrizados_Asiento export;

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
      SELECT 
        PROCESO, DESCRIPCION_ASIENTO, TIPO_PROCEDENCIA, CUENTA_NAVISION, 
        CODIGO_MAYOR, CUENTA_MAYOR, FICHERO_ASOCIADO, CUENTA_AUXILIAR, 
        CODIGO_CONCEPTO, TEXTO_CONCEPTO, REFERENCIA_DOCUMENTO_EXTERNA, 
        DIMENSION_DEPARTAMENTO, DIMENSION_CONCEPTO, DIMENSION_JERARQUIA, 
        DIMENSION_GASTOS, DIMENSION_PRODUCTO, DIMENSION_LIBRE1,
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
  dcl-proc CONTABSRV_Grabar_Asiento export;

    dcl-pi *n ind;
      dsAsifilen likeds(dsAsifilenTpl) const;
      sqlError char(5);
      sqlMensaje char(70);
      P_NomAsiPar char(10);
    end-pi;

    dcl-s SqlStr char(1000) inz;

    SqlStr = 
      'INSERT INTO '                                               +
      P_NomAsiPar                                                  +
      ' (CAPUNT, CCTAMA, CCTAFI, CCTAAU, CCODIG, CPROGR, '         +
        'CFECON, CDEHA, CREFOP, CFEVTO, CCONCE, CIMPOR, '          +
        'CMONED, CPROVI, CTIPOP, CTIPRO, CCTANA, CCODMA, '         +
        'CREFDE, CDDEPT, CDANLT, CDEBAN, CDPERS, CDGFIN, '         +
        'CDIM06, CDIM07, CDIM08) '                                 +
      'VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
    ;    

    exec sql prepare SX from :SqlStr;

    Monitor;
      exec sql execute SX using 
        :dsAsifilen.capunt,
        :dsAsifilen.cctama,
        :dsAsifilen.cctafi,
        :dsAsifilen.cctaau,
        :dsAsifilen.ccodig,
        :dsAsifilen.cprogr,
        :dsAsifilen.cfecon,
        :dsAsifilen.cdeha, 
        :dsAsifilen.crefop,
        :dsAsifilen.cfevto,
        :dsAsifilen.cconce,
        :dsAsifilen.cimpor,
        :dsAsifilen.cmoned,
        :dsAsifilen.cprovi,
        :dsAsifilen.ctipop,
        :dsAsifilen.ctipro,
        :dsAsifilen.cctana,
        :dsAsifilen.ccodma,
        :dsAsifilen.crefde,
        :dsAsifilen.cddept,
        :dsAsifilen.cdanlt,
        :dsAsifilen.cdeban,
        :dsAsifilen.cdpers,
        :dsAsifilen.cdgfin,
        :dsAsifilen.cdim06,
        :dsAsifilen.cdim07,
        :dsAsifilen.cdim08;
      // Exec Sql
      //   Execute Immediate :SqlStr;
    
      If sqlStt <> '00000';
        sqlError = sqlStt;
        Exec Sql
          GET DIAGNOSTICS EXCEPTION 1 :sqlMensaje = MESSAGE_TEXT;
        return *off;
      EndIf;

    On-Error;
      sqlMensaje = 'CONTABSRV_Grabar_Asiento. Error al grabar asiento';
      return *off;
    EndMon;

    return *on;

  end-proc;

  //-------------------------------------------------------
  // Asignar número de apunte
  //-------------------------------------------------------
  dcl-proc CONTABSRV_Asignar_Numero_Apunte export;

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
  dcl-proc CONTABSRV_Genera_Contabilidad_Totales_Producto export;

    dcl-pi *n;
      Acumulador   likeds(AcumuladorTpl) Dim(100);
      Inx          Zoned(3);
      ID_Contab    Zoned(5);
      Num_Apunte   Char(6);
      fecproces    Zoned(8);
      P_NomAsiPar  Char(10);
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
        observacionSql = 'CONTABSRV_Genera_Contabilidad_Totales_Producto: ' +
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
        observacionSql = 'CONTABSRV_Genera_Contabilidad_Totales_Producto: ' +
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

      if not CONTABSRV_Guardar_Asiento_Total_producto(
             WCodprod
            :Acumulador(I).Total
            :Num_Apunte
            :fecproces
            :ID_Contab
            :P_NomAsiPar);
        Leave;
      endif;

    EndFor;

  end-proc;
  //-----------------------------------------------------------
  // Guardar Asiento por Total por producto
  //-----------------------------------------------------------
  dcl-proc CONTABSRV_Guardar_Asiento_Total_producto;

    dcl-pi *n ind;
      WCodprod     zoned(3:0);
      P_Impor      Packed(14:3);
      Num_Apunte   char(6) const;
      fecproces    Zoned(8);
      ID_Contab    Zoned(5);
      P_NomAsiPar  Char(10);
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

    if not CONTABSRV_Obtener_Datos_Asiento(
             dsKeyAsiento
            :dsDatosAsientoParametrizables
            :dsDatosAsientoNoParametrizables
            :dsAsifilen
            :textoError);
      // Agregar funcion de monitoreo de Errores y correo
      return *off;
    endif;

    if not CONTABSRV_Grabar_Asiento(dsAsifilen
          :sqlError
          :sqlMensaje
          :P_NomAsiPar);
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
    if not CONTABSRV_Obtener_Datos_Asiento(
            dsKeyAsiento
            :dsDatosAsientoParametrizables
            :dsDatosAsientoNoParametrizables
            :dsAsifilen
            :textoError);
      // Agregar funcion de monitoreo de Errores y correo
      return *off;
    endif;

    if not CONTABSRV_Grabar_Asiento(dsAsifilen
          :sqlError
          :sqlMensaje
          :P_NomAsiPar);
      observacionSql = 
          'CONTABSRV_Grabar_Asiento: Error: ' + sqlError       +
          '.' + %Trim(sqlMensaje);
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      return *off;
    endif;

    return *on;
  end-proc;
  //-----------------------------------------------------------------
  // Copia Ficheros requeridos para un proceso en el Paralelo
  //-----------------------------------------------------------------
  dcl-proc CONTABSRV_Copy_Ficheros_Paralelo export;

    dcl-pi *n;
      P_NomProc  Char(10);
    end-pi;

    Dcl-s WFile_Req Char(10);
    Dcl-s WFile_Typ Char( 1);
    Dcl-s WFile_Lib Char(10);
    Dcl-s WFile_Data Char( 1);
    Dcl-s WCmd varchar(1000);
    dcl-s SqlState char(5)   inz;
    dcl-s SqlCode  int(10)   inz(0);
    dcl-s MsgTxt   varchar(500) inz;

    // Declaracion de Cursor de los ficheros a Copiar
    Exec Sql declare  C_Fic_Copy Cursor For
      Select 
        FILE_REQUERIDO, FILE_TYPE, FILE_LIB_ORIGEN, SI_DATA 
      From PARALELOC.PARALELO_COFIG_PROCESS
      Where
        ID_PROCESO = :P_NomProc
        And ESTATUS = 'A';

    Exec Sql Open  C_Fic_Copy;
    If Sqlcode < 0;
        observacionSql = 'CONTABSRV_Copy_Ficheros_Paralelo: ' +
                         'Error en OPEN del Cursor';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
        //Return *Off;
      EndIf;
      
    //sqlStt = '00000';

    dow sqlStt = '00000';
      Exec Sql Fetch From  C_Fic_Copy into 
            :WFile_Req, :WFile_Typ, :WFile_Lib, :WFile_Data;
      If sqlStt <> '00000';
        Leave;
      EndIf;    

      If WFile_Data = 'S';
        WCmd = 
          'CPYF FROMFILE('                                  +
          %Trim(WFile_Lib) + '/'                            +
          %Trim(WFile_Req) + ') '                           + 
          'TOFILE(PARALELOC/'                               +
          %Trim(WFile_Req) + ') '                           + 
          'MBROPT(*REPLACE) CRTFILE(*YES)';
      Else;
        WCmd = 
        'CRTDUPOBJ '                                        + 
        'OBJ('                                              +
        %Trim(WFile_Req) + ') '                             + 
        'FROMLIB('                                          +
        %Trim(WFile_Lib) + ') '                             + 
        'OBJTYPE(*FILE) TOLIB(PARALELOC) DATA(*NO)';
      Endif;

      monitor;
        exec sql CALL QSYS2.QCMDEXC(:WCmd) ;      
      on-error;
        // Captura de diagnóstico SQL estándar
        exec sql
          GET DIAGNOSTICS CONDITION 1
            :SqlState = RETURNED_SQLSTATE,
            :SqlCode  = DB2_RETURNED_SQLCODE,
            :MsgTxt   = MESSAGE_TEXT;

        observacionSql = 'CONTABSRV_Copy_Ficheros_Paralelo: ' +
            'SqlState=' + SqlState                            + 
            ' SqlCode=' + %Editc(SqlCode:'X')                 +
            ' MSG:' + %Trim(MsgTxt);
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

        //return *off;
        leave;
      endmon;
    EndDo;

    Exec Sql Close  C_SolPend; 

    //Return *On;
  end-proc;
  //-----------------------------------------------------------------
  // Inserta registro de Auditoria 
  //-----------------------------------------------------------------
  dcl-proc CONTABSRV_Registro_Auditoria_Paralelo export;

    dcl-pi *n;
      P_ProcEjec    Char(10);
      P_NomProc     Char(10);
      P_NumApun     Char(6);
      P_NomAsiPar   Char(10);
      P_NomCabpar   Char(10);
      P_NomDetpar   Char(10);
    end-pi;
    
    dcl-s WUSER    Char(10) Inz(*USER);

    EXEC SQL
      INSERT INTO PARALELOC.Paralelo_Audit_Process 
        (ID_PROCESO, ID_PROC_EJECUTOR, NUM_APUNTE, NOM_ASI_PARCIAL,
        NOM_CAB_PARCIAL, NOM_DET_PARCIAL, FEC_CREACION, USUARIO_CREACION)
      VALUES (
        :P_NomProc, 
        :P_ProcEjec, 
        :P_NumApun, 
        :P_NomAsiPar, 
        :P_NomCabpar, 
        :P_NomDetpar, 
        Current TimeStamp, 
        :WUSER);

    If Sqlcode < 0;
      observacionSql = 'CONTABSRV_Registro_Auditoria_Paralelo: ' +
                      'Error al insertar en el PARALELOC.PARALAUD';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      //Return *Off;
    EndIf;
  end-proc;  