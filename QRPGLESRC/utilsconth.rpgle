**FREE

  //------------------------------------------------------------------------
  // UTILSCONTH - COPY FILE PARA UTILSCONTA
  //------------------------------------------------------------------------

  // EVIDENCIAS CONTABLES
  dcl-pr Guardar_Evidencias_Contables_Cabecera ind;
    dsCabevi likeds(dsCabeviTempl);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr Borrar_Evidencias_Contables_Cabecera ind;
    dsCabevi likeds(dsCabeviTempl);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr Guardar_Evidencias_Contables_Detalle ind;
    // Marca: C - Crear Fic. Temporal
    //        G - Grabar en Fic Temporal
    //        F - Finalizar y Grabar en Fichero Final
    marca char(1);
    dsDetevi likeds(dsDeteviTempl);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr Crear_Fichero_Detalle_Evidencia_Temporal ind;
    nombreFichero char(50);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr Grabar_Detalle_Evidencia_Temporal ind;
    nombreFichero char(50);
    dsDetevi likeds(dsDeteviTempl);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr Grabar_Detalles_Evidencias ind;
    nombreFichero char(50);
    dsDetevi likeds(dsDeteviTempl);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  // ASIENTO
  dcl-pr Obtener_Datos_Asiento ind;
    // Puede venir informada la clave para acceder a la tabla ASIENTOS_CUENTAS_POR_PRODUCTO
    // y los datos parametrizables los cogemos de ahí. ESTE PARAMETRO TIENE PRIORIDAD.
    dsKeyAsiento likeds(dsKeyAsientoTpl);
    // O puede venir informada una DS con los datos, que en vez de parametrizarse en tabla,
    // se mandan directamente por ser casos especiales.
    dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl);
    // Estos son los datos del asiento que no se pueden parametrizar
    dsDatosAsientoNoParametrizables likeds(dsDatosAsientoNoParametrizablesTpl);
    dsAsifilen likeds(dsAsifilenTpl); // Parámetro de salida
    textoError char(100); // Parámetro de salida si hay error
  end-pr;

  dcl-pr Obtener_Datos_Parametrizados_Asiento ind;
    dsKeyAsiento likeds(dsKeyAsientoTpl);   // Parámetro de entrada
    dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl); // Parámetro de salida
  end-pr;

  dcl-pr Grabar_Asiento ind;
    dsAsifilen likeds(dsAsifilenTpl) const;
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr Asignar_Numero_Apunte char(6);
    fecha timestamp const;
  end-pr;

  dcl-pr ASBUNU extPgm('ASBUNU');
    anio char(2);
    mes char(2);
    apunte char(6);
  end-pr;

  dcl-ds dsCabeviTempl qualified inz template;
    descripcion char(50);
    numeroApunte char(6);
    fechaConciliacion zoned(8:0);
    fechaBaja zoned(8:0);
    numeroEvidencia char(6);  // Es la hora + cajon (1 al 9 en sg)
    pteModificar char(1);
  end-ds;

  dcl-ds dsDeteviTempl qualified inz template;
    lineaTexto char(132);
    numeroLinea zoned(5:0);
    numeroApunte char(6);
    fechaConciliacion zoned(8:0);
    numeroEvidencia char(6);
  end-ds;

  dcl-ds dsKeyAsientoTpl qualified inz template;
    idAsiento zoned(5:0);
    ordenApunte zoned(2:0);
    codProducto zoned(3:0);
  end-ds;

  dcl-ds dsDatosAsientoParametrizablesTpl qualified inz template;
    proceso char(6);
    descripcionAsiento varchar(100);
    tipoProcedencia char(1);
    cuentaNavision char(20);
    codigoMayor char(20);
    cuentaMayor char(5);
    ficheroAsociado char(2);
    cuentaAuxiliar char(5);
    codigoConcepto zoned(3:0);
    textoConcepto varchar(30);
    referenciaDocumentoExterna char(20);
    dimensionDepartamento char(20);
    dimensionConcepto char(20);
    dimensionJerarquia char(20);
    dimensionGastos char(20);
    dimensionProducto char(20);
    dimensionLibre1 char(20);
    dimensionLibre2 char(20);
    dimensionLibre3 char(20);
  end-ds;

  dcl-ds dsDatosAsientoNoParametrizablesTpl qualified inz template;
    numApunte char(6);
    fechaContable zoned(8:0);
    debeHaber char(1);
    referenciaOperacion char(6);
    fechaVencimiento zoned(8:0);
    importe zoned(14:3);
    codMoneda char(1);
    apunteProvisional char(6);
    tipoOperacion zoned(3:0);
  end-ds;

  dcl-ds dsAsifilenTpl qualified template inz;
    capunt char(6);
    cctama char(5);
    cctafi char(2);
    cctaau char(5);
    ccodig zoned(3:0);
    cprogr char(6);
    cfecon zoned(8:0);
    cdeha char(1);
    crefop char(6);
    cfevto zoned(8:0);
    cconce char(30);
    cimpor zoned(14:3);
    cmoned char(1);
    cprovi char(6);
    ctipop zoned(3:0);
    ctipro char(1);
    cctana char(20);
    ccodma char(20);
    crefde char(20);
    cddept char(20);
    cdanlt char(20);
    cdeban char(20);
    cdpers char(20);
    cdgfin char(20);
    cdim06 char(20);
    cdim07 char(20);
    cdim08 char(20);
  end-ds;

  Dcl-Ds DsAcuenproTpl Qualified template Inz;
    ID_ASIENTO          Zoned(5: 0);  //ID DEL ASIENTO
    ORDEN_APUNTE        Zoned(2: 0); //ORDEN DEL APUNTE
    CODIGO_PRODUCTO     Zoned(3: 0); //CODIGO_PRODUCTO
    PROCESO             Char(6); //NOMBRE PROCESO
    DESCRIPCION_ASIENTO VARCHAR(100);//DESCRIPCION DEL ASIENTO
    TIPO_PROCEDENCIA    Char(1); //TIPO DE PROCEDENCIA
    CUENTA_NAVISION     Char(20); //CUENTA DE NAVISION
    CODIGO_MAYOR        Char(20); //CODIGO MAYOR
    CUENTA_MAYOR        Char(5); //CUENTA DE MAYOR
    FICHERO_ASOCIADO    Char(2); //FICHERO ASOCIADO
    CUENTA_AUXILIAR     Char(5); //CUENTA AUXILIAR
    CODIGO_CONCEPTO     Zoned(3: 0); //CODIGO DEL CONCEPTO
    TEXTO_CONCEPTO      VARCHAR(30); //TEXTO DEL CONCEPTO
    REFERENCIA_DOCUMENTO_EXTERNA  Char(20);//REFERENCIA DOCUMENTO EXTERN
    DIMENSION_DEPARTAMENTO  Char(20); //DIMENSION DEPARTAMENTO
    DIMENSION_CONCEPTO    Char(20); //DIMENSION CONCEPTO
    DIMENSION_JERARQUIA Char(20); //DIMENSION JERARQUIA
    DIMENSION_GASTOS   Char(20); //DIMENSION GASTOS
    DIMENSION_PRODUCTO Char(20); //DIMENSION PRODUCTO
    DIMENSION_LIBRE1   Char(20); //DIMENSION LIBRE 1
    DIMENSION_LIBRE2   Char(20); //DIMENSION LIBRE 2
    DIMENSION_LIBRE3   Char(20); //DIMENSION LIBRE 3
    DEBE_HABER         Char(1); //DEBE O HABER
  End-Ds;
  // Array para Acumular Importes a contabilizar
  // Totalizados por Producto
  dcl-ds AcumuladorTpl Qualified dim(100) template Inz;
    Cod_prod  Zoned(3:0);
    Total    Packed(14:3);
  end-ds;
