**FREE
  Ctl-Opt DECEDIT('0,') DATEDIT(*DMY.) DFTACTGRP(*NO)
          BNDDIR('EXPLOTA/CALDIG':'UTILITIES/UTILITIES');
  //****************************************************************
  //*  -FACT.SOCIOS- ASIENTO TRASPASO -PA- A -FA-                 **
  //****************************************************************
  Dcl-S fechaSistema Timestamp;

  Dcl-S import       Zoned(11:0);
  Dcl-s WInd         Zoned(5);
  Dcl-s fecproces    Zoned(8);
  Dcl-s WFECAMD      Zoned(8);
  Dcl-s WNUEVID      Zoned(6);
  Dcl-s WnumLinea    Zoned(5);
  Dcl-s WCodContab   Zoned(5) Inz(5); //Id_Asiento FSPAFAN
  Dcl-s WApunte      Char(6);
  Dcl-s WCRFS01      Char(96);
  Dcl-s WDSPLY       char(40);

  dcl-s CabeceraEvid Ind;
  //Motivado a casque del dia 01.07.2025 de desbordamiento del campo
  //Acumulador.total que estaba de definido de 9.0 pasa a 16.0
  dcl-ds Acumulador Qualified dim(50) Inz;
    Cod_prod  Zoned(3:0);
    Total    Packed(16:0);
  end-ds;

  dcl-ds BS_DTA Qualified;
    BNUMRE    Zoned(8);
    BIMPOR    Packed(9:0);
    BDIAPR    Zoned(2);
    BFECON    Zoned(8);
    BREFOR    Zoned(9);
    SCODPR    Zoned(3);
  end-ds;

  ///Define P_dsAsientoCtaTempl
  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
  /copy EXPLOTA/QRPGLESRC,UTILSCONTH       // Utilidades contabilidad
  /copy EXPLOTA/QRPGLESRC,MCARD_H
  //****************************************************************
  fechaSistema = %timestamp();
  WApunte = Asignar_Numero_Apunte(fechaSistema);
  fechaSistema = fechaSistema -  %days(1);

  Exec Sql
    Select CRFS01
    Into :WCRFS01
    From CRFS01;

  Monitor;
    fecproces = %Dec(%SubSt(WCRFS01:50:8):8:0);
  on-error;
    fecproces = %Dec(%date():*EUR);
  endmon;

  WFECAMD = %dec(%char(%date(fechaSistema):*iso0):8:0);
  fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);

  WNUEVID = %Dec(%Time());
  Reset Acumulador;

  Exec Sql declare C_BS Cursor For
    SELECT
      BNUMRE, BIMPOR, BDIAPR, BFECON,
      Case
        WHEN hex(BREFOR) = '404040404040404040' THEN 0 ELSE BREFOR end BREFOR,
      SCODPR
    FROM BS
      Inner Join Ficheros.T_MSOCIO
        On BNUMRE=NUREAL
    WHERE
      BCODMO In ('4','5','7')
    Order By SCODPR, BNUMRE
    ;

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

    IMPORT = IMPORT + BS_DTA.BIMPOR;

    If Not Acumula_importe(
           BS_DTA.BIMPOR:
           BS_DTA.SCODPR:
           WInd);
      DSPLY ('ERROR EN CODIGO PRODUCTO ')  %eDITC(BS_DTA.BNUMRE:'X');
    EndIf;

    If Not CabeceraEvid;
        Inserta_Cebecera_Evi();
        CabeceraEvid = *on;
    Endif;
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
    Genera_Contabilidad();
    Inserta_Totales_Evi();
  EndIf;

  *InLR = *On;
  //-----------------------------------------------------------------
  // Acumula_importe
  //-----------------------------------------------------------------
  dcl-proc Acumula_importe;
      dcl-pi *n Ind;
        P_Impor   Packed(9:0);
        p_Product Zoned(3);
        P_Ind     Zoned(5);
      end-pi;

      Dcl-s WCodpro  Zoned(3);
      Dcl-s WIndx    Zoned(5);
      Dcl-s WMarca   Zoned(2);
      Dcl-s WExiste_Cod  Ind;

      WIndx = %lookup(p_Product: Acumulador(*).Cod_prod:1);
      if WIndx > 0;
          Acumulador(WIndx).Total += P_Impor;
      else;
          P_Ind += 1;
          Acumulador(P_Ind).Cod_prod = p_Product;
          Acumulador(P_Ind).Total    = P_Impor;
      endif;

      Return *On;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Contabilidad
  //-----------------------------------------------------------------
  dcl-proc Genera_Contabilidad;

    Dcl-s I        Zoned(3);
    Dcl-s WMarca   Zoned(2);
    Dcl-s WCodProd Zoned(3);
    Dcl-s WExiste_Cod   Ind;

    For I=1 to WInd;

      // Se verifica Producto
      WCodProd = Acumulador(I).Cod_prod;
      Exec SQL
        Select Codigo_Marca
        Into :WMarca
        From PRODUCTOS_DCS
        Where
          CODIGO_PRODUCTO = :WCodProd
      ;

      If Sqlcode < 0;
        observacionSql = 'FSPAFAN: Error select de PRODUCTOS';
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
          ID_ASIENTO = :WCodContab
          AND CODIGO_PRODUCTO = :WCodProd
        Limit 1;

      If Sqlcode < 0;
        observacionSql = 'FSPAFAN: Error select de ASIENTOS_CUENTAS_POR_PRODUCTO';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      EndIf;

      Select;
        When Not WExiste_Cod and WMarca=1; // Valida Diners s/conciliacion
          WCodprod = 999;
        When Not WExiste_Cod and WMarca=2; // Valida Mastercard
          WCodprod = 998;
      EndSl;

      if not Guardar_Asiento(
            WCodprod:
            Acumulador(I).Total:
            WApunte:
            fechaSistema);
        Leave;
      endif;

    EndFor;

  end-proc;
  //-----------------------------------------------------------------------------
  // Guardar Asiento
  //-----------------------------------------------------------------------------
  dcl-proc Guardar_Asiento;

    dcl-pi *n ind;
      codProducto  zoned(3:0);
      P_Impor      Packed(16:0);
      apunte       char(6) const;
      fechaSistema timestamp;
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

    dsDatosAsientoNoParametrizables.numApunte = apunte;
    dsDatosAsientoNoParametrizables.fechaContable = fecproces ;
    dsDatosAsientoNoParametrizables.referenciaOperacion = *blanks;
    dsDatosAsientoNoParametrizables.fechaVencimiento = 0;
    dsDatosAsientoNoParametrizables.codMoneda = '1';
    dsDatosAsientoNoParametrizables.apunteProvisional = *blanks;
    dsDatosAsientoNoParametrizables.tipoOperacion = 0;

    // ************  Asiento 5 orden 1 (Haber)
    dsKeyAsiento.idAsiento = WCodContab;
    dsKeyAsiento.ordenApunte = 1;
    dsKeyAsiento.codProducto = codProducto;

    if P_Impor >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(P_Impor)/100;

    if not Obtener_Datos_Asiento(
            dsKeyAsiento:
            dsDatosAsientoParametrizables:
            dsDatosAsientoNoParametrizables:
            dsAsifilen:textoError);
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      return *off;
    endif;

    // ************  Asiento 5 orden 2 (Debito)
    dsKeyAsiento.idAsiento = WCodContab;
    dsKeyAsiento.ordenApunte = 2;
    dsKeyAsiento.codProducto = codProducto;

    if P_Impor >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(P_Impor)/100;
    if not Obtener_Datos_Asiento(
            dsKeyAsiento:
            dsDatosAsientoParametrizables:
            dsDatosAsientoNoParametrizables:
            dsAsifilen:textoError);
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      return *off;
    endif;

    return *on;
  end-proc;
  //-----------------------------------------------------------------
// Genera Inserta Cabecera de Evidencia Contable
//-----------------------------------------------------------------
dcl-proc Inserta_Cebecera_Evi;

  dcl-pi *n Ind;
  end-pi;

  Dcl-s WReg  Char(132);

  WReg = 'FSPAFAN EVIDENCIA CONTABLE FACT. AL ' +
         %SubSt(%Editc(fecproces:'X'):1:2) + '-' +
         %SubSt(%Editc(fecproces:'X'):3:2) + '-' +
         %SubSt(%Editc(fecproces:'X'):5:4);
  Exec Sql
    INSERT INTO CABEPAFA
      Values(Trim(:WReg), :WApunte, :WFECAMD, 0, :WNUEVID, ' ');

  If Sqlcode < 0;
     observacionSql = 'FSPAFAN: Error al insertar en el CABEPAFA';
     Clear Nivel_Alerta;
     Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
  EndIf;

  If Sqlcode<>0;
     WDSPLY = 'FSPAFAN: Error al insertar en el CABEPAFA';
     dsply WDSPLY;
     Return *On;
  EndIf;

  WnumLinea += 1;
  WReg = 'NUMERO REAL       IMPORTE     DIA FACT.  ' +
        ' FECHA CONSUMO    REFERENCIA   PRODUCTO';
  Exec Sql
    INSERT INTO DETEPAFA
      Values(Trim
      (:WReg), :WnumLinea, :WApunte, :WFECAMD, :WNUEVID);

  If Sqlcode < 0;
     observacionSql = 'FSPAFAN: Error al insertar en el DETEPAFA';
     Clear Nivel_Alerta;
     Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
  EndIf;

  If Sqlcode<>0;
     WDSPLY = 'FSPAFAN: Error al insertar en el DETEPAFA';
     dsply WDSPLY;
     Return *On;
  EndIf;

  Return *Off;

end-proc;
//-----------------------------------------------------------------
// Genera Inserta Detalle de Evidencia Contable
//-----------------------------------------------------------------
dcl-proc Inserta_Detalle_Evi;

  dcl-pi *n ind;
  end-pi;

  Dcl-s WReg  Char(132);

  dcl-ds dsDetalEvi Qualified;
      Esp01     Char(1);
      BNUMRE    Zoned(8);
      Esp02     Char(2);
      BIMPOR    Char(15);
      Esp03     Char(6);
      BDIAPR    Zoned(2);
      Esp04     Zoned(10);
      BFECON    Char(10);
      Esp05     CHAR(6);
      BREFOR    Zoned(9);
      Esp06     Char(5);
      SCODPR    Zoned(3);
  End-ds;

  dsDetalEvi.BNUMRE = BS_DTA.BNUMRE;
  dsDetalEvi.BIMPOR = %Editc(BS_DTA.BIMPOR/100:'2');
  dsDetalEvi.BDIAPR = BS_DTA.BDIAPR;
  dsDetalEvi.BFECON  =
         %SubSt(%Editc(BS_DTA.BFECON:'X'):1:2) + '-' +
         %SubSt(%Editc(BS_DTA.BFECON:'X'):3:2) + '-' +
         %SubSt(%Editc(BS_DTA.BFECON:'X'):5:4);
  dsDetalEvi.BREFOR  = BS_DTA.BREFOR;
  dsDetalEvi.SCODPR  = BS_DTA.SCODPR;

  WReg = dsDetalEvi;
  If WnumLinea < 99000;
     WnumLinea += 1;
  Endif;
  Exec Sql
    INSERT INTO DETEPAFA
      Values(Trim
      (:WReg), :WnumLinea, :WApunte, :WFECAMD, :WNUEVID);

  If Sqlcode < 0;
     observacionSql = 'FSPAFAN: Error al insertar en el DETEPAFA';
     Clear Nivel_Alerta;
     Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
  EndIf;

  If Sqlcode<>0;
     WDSPLY = 'FSPAFAN: Error al insertar en el DETEPAFA';
     dsply WDSPLY;
     Return *On;
  EndIf;

  Return *Off;

end-proc;
//-----------------------------------------------------------------
// Genera Inserta Totales de Evidencia Contable
//-----------------------------------------------------------------
dcl-proc Inserta_Totales_Evi;

  dcl-pi *n Ind;
  end-pi;

  Dcl-s WReg      Char(132);
  Dcl-s WNomProd  Char(30);
  Dcl-s I         Zoned(3);
  Dcl-s WCod_Prod Zoned(3);

  WReg = '';
  WnumLinea += 1;
  Exec Sql
    INSERT INTO DETEPAFA
      Values(Trim
      (:WReg), :WnumLinea, :WApunte, :WFECAMD, :WNUEVID);

  If Sqlcode < 0;
     observacionSql = 'FSPAFAN: Error al insertar en el DETEPAFA';
     Clear Nivel_Alerta;
     Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
  EndIf;

  If Sqlcode<>0;
    WDSPLY = 'FSPAFAN: Error al insertar en el DETEPAFA';
    dsply WDSPLY;
    Return *On;
  EndIf;

  WReg = 'Codigo Producto'       +
         '                           ' +
         'Total' ;
  WnumLinea += 1;
  Exec Sql
    INSERT INTO DETEPAFA
      Values(Trim
      (:WReg), :WnumLinea, :WApunte, :WFECAMD, :WNUEVID);

  If Sqlcode < 0;
     observacionSql = 'FSPAFAN: Error al insertar en el DETEPAFA';
     Clear Nivel_Alerta;
     Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
  EndIf;

  If Sqlcode<>0;
    WDSPLY = 'FSPAFAN: Error al insertar en el DETEPAFA';
    dsply WDSPLY;
    Return *On;
  EndIf;

  WReg = '------------------------------------' +
         '    ' +
         '------------' ;
  WnumLinea += 1;
  Exec Sql
    INSERT INTO DETEPAFA
      Values(Trim
      (:WReg), :WnumLinea, :WApunte, :WFECAMD, :WNUEVID);

  If Sqlcode < 0;
     observacionSql = 'FSPAFAN: Error al insertar en el DETEPAFA';
     Clear Nivel_Alerta;
     Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
  EndIf;

  If Sqlcode<>0;
    WDSPLY = 'FSPAFAN: Error al insertar en el DETEPAFA';
    dsply WDSPLY;
    Return *On;
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

    WReg =
      %Editc(Acumulador(I).Cod_prod:'X') +
      ' - ' + WNomProd + '    '    +
      %Editc(
        %Dec(Acumulador(I).Total/100:16:2)
      :'2');
    WnumLinea += 1;

    Exec Sql
      INSERT INTO DETEPAFA
      Values(Trim
      (:WReg), :WnumLinea, :WApunte, :WFECAMD, :WNUEVID);

    If Sqlcode < 0;
      observacionSql = 'FSPAFAN: Error al insertar en el DETEPAFA';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Sqlcode<>0;
      WDSPLY = 'FSPAFAN: Error al insertar en el DETEPAFA';
      dsply WDSPLY;
      Return *On;
    EndIf;
  EndFor;

  Return *Off;

end-proc;
