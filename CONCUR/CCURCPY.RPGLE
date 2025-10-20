**FREE
  //------------------------------------------------------------------------
  // COPY FILE PARA CONCUR
  // Fecha: Noviembre 2025                                               LM
  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  // Prototipos
  //------------------------------------------------------------------------


  //------------------------------------------------------------------------
  // Estructuras - templates
  //------------------------------------------------------------------------
  dcl-ds dsCCURCTLENVTpl qualified inz template;
    Tipo_Proceso          Char( 1);
    PA_Utilizado          Char(10);
    BA_Utilizado          Char(10);
    OP_Utilizado          Char(10);

    Fecha_Generacion     Timestamp;
    Usuario_Generacion   Char(10);
  end-ds;
  dcl-ds dsCCUROPEENVTpl qualified inz template;
    ID_Control           Int(10);
    NUREAL               Packed(8:0);
    Num_Agencia_Minerva  Packed(4:0);
    FICHERO_MINERVA      Packed(9:0);
    Transaccion_Minerva  Char(20);
    TR_NUMERO_TRANSACCION Int(10);
    Tipo_Msg_Concur      Packed(3:0);
    ID_Msg_Padre         Int(10);
    ID_Msg_Hijo          Int(10);
    Tipo_Servicio_Minerva Char(2);
    Fecha_Generacion     Timestamp;
    Usuario_Generacion   Char(10);
  end-ds;
  // ==========================================================
  // DS: Estructura CCURFR200T  Formato 200
  // ==========================================================
  Dcl-DS dsCCURFR200TTpl Qualified inz template;
    F200IDR Zoned(3:0)    Inz(0);          // IDENTIF.REGISTRO-200
    F200CCN Char(16)       Inz('');         // NUMERO TARJETA
    F200TRN Char(50)       Inz('');         // Nº.REFERENCIA OPERAC
    F200TDA Zoned(8:0)    Inz(0);          // FECHA CONSUMO
    F200PDA Zoned(8:0)    Inz(0);          // FECHA ENTRADA DINERS
    F200FTI Char(3)        Inz('');         // COD.ISO MONED.ORIGIN
    F200IMO Char(15)       Inz('');         // IMPORTE MONED.ORIGIN
    F200ITF Char(3)        Inz('');         // COD.ISO MONED.FACTUR
    F200IMF Char(15)       Inz('');         // IMPORTE MONED.FACTUR
    F200MNA Char(32)       Inz('');         // NOMBRE COMERCIO
    F200MCC Char(5)        Inz('');         // ACT.ISO MCC COMERCIO
    F200MCI Char(32)       Inz('');         // LOCALIDAD COMERCIO
    F200MSP Char(32)       Inz('');         // PROVINCIA COMERCIO
    F200MPC Char(20)       Inz('');         // COD.POSTAL COMERCIO
    F200IMC Char(3)        Inz('');         // CO.ISO PAIS COMERCIO
    F200ITT Char(15)       Inz('');         // IMPORTE TASAS TOTAL
    F200ITL Char(15)       Inz('');         // IMPORTE TASAS LOCAL
    F200ITG Char(15)       Inz('');         // IMPORTE TASAS GOODS
    F200ITS Char(15)       Inz('');         // IMPORTE TASAS SALES
    F200ITO Char(15)       Inz('');         // IMPORTE TASAS OTHER
    F200MRN Char(12)       Inz('');         // Nº.COMERCIO + DIGITO
    F200MTN Char(20)       Inz('');         // CIF COMERCIO -PV-
    F200CTN Char(20)       Inz('');         // CIF EMPRESA
    F200VDI Char(1)        Inz('');         // INDICADOR DE IVA
    F200BTY Char(2)        Inz('');         // TIPO FACTURACION
    F200TDE Char(32)       Inz('');         // DESCRIPCION TRANSAC.
    F200C01 Char(48)       Inz('');         // REFERENCIA-1 CLIENTE
    F200C02 Char(48)       Inz('');         // REFERENCIA-2 CLIENTE
    F200C03 Char(48)       Inz('');         // REFERENCIA-3 CLIENTE
    F200C04 Char(48)       Inz('');         // REFERENCIA-4 CLIENTE
    F200C05 Char(48)       Inz('');         // REFERENCIA-5 CLIENTE
    F200A01 Char(48)       Inz('');         // REFERENCIA-1 CUENTA
    F200A02 Char(48)       Inz('');         // REFERENCIA-2 CUENTA
    F200A03 Char(48)       Inz('');         // REFERENCIA-3 CUENTA
    F200A04 Char(48)       Inz('');         // REFERENCIA-4 CUENTA
    F200A05 Char(48)       Inz('');         // REFERENCIA-5 CUENTA
    F200EID Char(48)       Inz('');         // REF. IDENT.EMPLEADO
    F200LIB Char(1065)     Inz('');         // RESERVADO - LIBRE
  End-DS;
  //---------------------------------------------------------------------
  // DS: Estructura CCURFR301T  Formato 301
  //---------------------------------------------------------------------
  Dcl-DS dsCCURFR301TTpl Qualified inz template;
    F301IDR    Zoned(3:0)    Inz(0);        // IDENTIF.REGISTRO-301
    F301TRN    Char(50)       Inz('');       // Nº.REFERENCIA OPERAC
    F301RAN    Char(30)       Inz('');       // NUMERO CONTRATO
    F301RNA    Char(50)       Inz('');       // NOMBRE AGENCIA
    F301PDA    Zoned(8:0)    Inz(0);        // FECHA  RECOGIDA VEH.
    F301PPI    Char(30)       Inz('');       // ID.AG. RECOGIDA VEH.
    F301PCI    Char(32)       Inz('');       // CIUDAD RECOGIDA VEH.
    F301PSP    Char(32)       Inz('');       // PROVIN.RECOGIDA VEH.
    F301PCO    Char(32)       Inz('');       // PAIS   RECOGIDA VEH.
    F301RDA    Zoned(8:0)    Inz(0);        // FECHA  DEVOLUC. VEH.
    F301RPI    Char(30)       Inz('');       // ID.AG. DEVOLUC. VEH.
    F301RCI    Char(32)       Inz('');       // CIUDAD DEVOLUC. VEH.
    F301RSP    Char(32)       Inz('');       // PROVIN.DEVOLUC. VEH.
    F301RCO    Char(32)       Inz('');       // PAIS   DEVOLUC. VEH.
    F301NSF    Char(1)        Inz('');       // FLAG: NO SE PRESENTA
    F301ADU    Char(15)       Inz('');       // IMPORTE POR DISTANC.
    F301DRE    Char(15)       Inz('');       // IMPORTE POR DIA
    F301WRA    Char(15)       Inz('');       // IMPORTE POR SEMANA
    F301VCC    Char(32)       Inz('');       // CODIGO CLASE VEHIC.
    F301NVE    Zoned(3:0)    Inz(0);        // NUMERO DE VEHICULO
    F301TDI    Zoned(6:0)    Inz(0);        // DIS.TOTAL,TOT.PERIOD
    F301RDC    Char(15)       Inz('');       // IMPORTE DISTAN.RECOR
    F301EDR    Char(15)       Inz('');       // IMPORTE DISTAN.EXTRA
    F301OWD    Char(15)       Inz('');       // IMPORTE DEV.DIST.LOC
    F301LCH    Char(15)       Inz('');       // IMPORTE RETRASO DEV.
    F301FCH    Char(15)       Inz('');       // IMPORTE CARBURANTE
    F301ICH    Char(15)       Inz('');       // IMPORTE SEGURO
    F301OCH    Char(15)       Inz('');       // IMPORTE OTROS
    F301AAM    Char(15)       Inz('');       // IMPORTE AJUSTES
    F301ECC    Char(6)        Inz('');       // CODIGO CARGOS EXTRAS
    F301ECA    Char(15)       Inz('');       // IMPORT.TOT.CARG.EXTR
    F301RED    Zoned(5:0)    Inz(0);        // DIAS DE ALQUILER
    F301MFD    Zoned(6:0)    Inz(0);        // DIST.TOT.PERM.ANT.EX
    F301CCO    Char(20)       Inz('');       // CODIGO MERCANCIA
    F301C01    Char(48)       Inz('');       // REFERENCIA-1 CLIENTE
    F301C02    Char(48)       Inz('');       // REFERENCIA-2 CLIENTE
    F301C03    Char(48)       Inz('');       // REFERENCIA-3 CLIENTE
    F301C04    Char(48)       Inz('');       // REFERENCIA-4 CLIENTE
    F301C05    Char(48)       Inz('');       // REFERENCIA-5 CLIENTE
    F301LIB    Char(1100)     Inz('');       // RESERVADO - LIBRE
  End-DS;
  //---------------------------------------------------------------------
  // DS: Estructura CCURFR301T  Formato 302
  //---------------------------------------------------------------------
  Dcl-DS dsCCURFR302TTpl Qualified inz template;
    F302IDR  Zoned(3:0)    Inz(0);        // IDENTIF.REGISTRO-302
    F302TRN  Char(50)       Inz('');       // Nº.REFERENCIA OPERAC
    F302LPI  Char(30)       Inz('');       // Nº.IDENTIF. COMERCIO
    F302PTN  Char(16)       Inz('');       // Nº.TELEFONO COMERCIO
    F302LCI  Char(32)       Inz('');       // CIUDAD COMERCIO
    F302COD  Zoned(8:0)    Inz(0);        // FECHA SALIDA
    F302CID  Zoned(8:0)    Inz(0);        // FECHA LLEGADA
    F302RRN  Char(15)       Inz('');       // COSTE POR NOCHE
    F302PHO  Char(15)       Inz('');       // IMPORTE USO TFNO.
    F302GSA  Char(15)       Inz('');       // IMPORTE TIEND.REGAL.
    F302BAR  Char(15)       Inz('');       // IMPORTE BAR/MINI BAR
    F302CLA  Char(15)       Inz('');       // IMPORTE LAVANDERIA
    F302FNU  Char(32)       Inz('');       // NUMERO RESERVA
    F302NON  Zoned(3:0)    Inz(0);        // NUMERO TOTAL NOCHES
    F302DRT  Char(15)       Inz('');       // IMPORT.TASAS POR DIA
    F302FCH  Char(15)       Inz('');       // IMPORT.COMIDA/BEBIDA
    F302PCH  Char(15)       Inz('');       // IMPORTE PARKING
    F302MCH  Char(15)       Inz('');       // IMPORTE PELICULAS
    F302TCH  Char(15)       Inz('');       // IMPORTE PROPINA
    F302OCH  Char(15)       Inz('');       // IMPORTE OTROS
    F302TAC  Char(30)       Inz('');       // DESCRIP.TIPO PROPINA
    F302GNA  Char(50)       Inz('');       // NOMBRE ACOMPAÑANTE
    F302NIP  Zoned(2:0)    Inz(0);        // Nº.INVITADOS EN HAB.
    F302RTY  Char(4)        Inz('');       // TIPO HABITACION
    F302NRO  Zoned(2:0)    Inz(0);        // Nº.HABIT.RESERVADAS
    F302PAM  Char(15)       Inz('');       // IMPORTE RESERVA
    F302TRT  Char(15)       Inz('');       // IMPORTE TOTAL TASAS
    F302AAM  Char(15)       Inz('');       // IMPORTE DE AJUSTES
    F302TLA  Char(15)       Inz('');       // IMPORTE TOT.ESTANCIA
    F302TNR  Char(15)       Inz('');       // IMPORTE AJENOS HABIT
    F302CCO  Char(20)       Inz('');       // CODIGO MERCANCIA
    F302PCO  Char(2)        Inz('');       // CODIGO PROGRAMA
    F302OSC  Char(6)        Inz('');       // CODIGO OTROS SERVIC.
    F302MON  Char(30)       Inz('');       // NUMERO ORDEN RESERVA
    F302LSA  Char(32)       Inz('');       // PROVINCIA
    F302LPC  Char(20)       Inz('');       // CODIGO POSTAL
    F302LRE  Char(3)        Inz('');       // REGION
    F302LCO  Char(64)       Inz('');       // PAIS
    F302C01  Char(48)       Inz('');       // REFERENCIA-1 CLIENTE
    F302C02  Char(48)       Inz('');       // REFERENCIA-2 CLIENTE
    F302C03  Char(48)       Inz('');       // REFERENCIA-3 CLIENTE
    F302C04  Char(48)       Inz('');       // REFERENCIA-4 CLIENTE
    F302C05  Char(48)       Inz('');       // REFERENCIA-5 CLIENTE
    F302LIB  Char(1073)     Inz('');       // RESERVADO - LIBRE
  End-DS;
  // ==========================================================
  // DS: Estructura CCURFR303T
  // ==========================================================
  Dcl-DS dsCCURFR303TTpl Qualified inz template;
    F303IDR Zoned(3:0)    Inz(0);          // IDENTIF.REGISTRO-303
    F303TRN Char(50)       Inz('');         // Nº.REFERENCIA OPERAC
    F303TNU Char(32)       Inz('');         // NUMERO BILLETE
    F303PNA Char(50)       Inz('');         // NOMBRE PASAJERO
    F303TAC Char(8)        Inz('');         // CODIGO AG.VIAJ.IATA
    F303TAN Char(50)       Inz('');         // NOMBRE AGENC.VIAJES
    F303DDA Zoned(8:0)    Inz(0);          // FECHA SALIDA SEGTO-1
    F303NLE Zoned(2:0)    Inz(0);          // NUMERO DE SEGMENTOS
    F303RFL Char(1)        Inz('');         // INDICADOR RESTRICC.
    F303IDA Zoned(8:0)    Inz(0);          // FECHA EMISION
    F303ICA Char(20)       Inz('');         // ABREV.LLAA QUE VUELA
    F303CDA Char(30)       Inz('');         // DATO DEFINIDO CLIENT
    F303BFA Char(15)       Inz('');         // TARIFA BASE
    F303TFA Char(15)       Inz('');         // IMPORTE TOTAL BILLET
    F303TFE Char(15)       Inz('');         // IMPORTE TOTAL GASTOS
    F303ETF Char(1)        Inz('');         // INDICADOR CAMBIO
    F303CID Char(7)        Inz('');         // ID.POR MAS DE 4 SEG.
    F303RTN Char(30)       Inz('');         // Nº.BILLETE REEMBOLSO
    F303ETN Char(30)       Inz('');         // Nº.BILLETE CAMBIADO
    F303ETA Char(15)       Inz('');         // IMP.TOT.BIL.CAMBIADO
    F303CCO Char(20)       Inz('');         // CODIGO MERCANCIA
    F303C01 Char(48)       Inz('');         // REFERENCIA-1 CLIENTE
    F303C02 Char(48)       Inz('');         // REFERENCIA-2 CLIENTE
    F303C03 Char(48)       Inz('');         // REFERENCIA-3 CLIENTE
    F303C04 Char(48)       Inz('');         // REFERENCIA-4 CLIENTE
    F303C05 Char(48)       Inz('');         // REFERENCIA-5 CLIENTE
    F303LIB Char(1350)     Inz('');         // RESERVADO - LIBRE
  End-DS;
  // ==========================================================
  // DS: Estructura CCURFR304T
  // ==========================================================
  Dcl-DS dsCCURFR304TTpl Qualified inz template;
    F304IDR Zoned(3:0)    Inz(0);          // IDENTIF.REGISTRO-304
    F304TRN Char(50)       Inz('');         // Nº.REFERENCIA OPERAC
    F304TLN Char(2)        Inz('');         // NUMERO DEL SEGMENTO
    F304CCO Char(2)        Inz('');         // CODIGO ABREV. LLAA
    F304CSC Char(8)        Inz('');         // CLASE O COD.SERVICIO
    F304DLO Char(32)       Inz('');         // COD/LOCALIDAD SALIDA
    F304ALO Char(32)       Inz('');         // COD/LOCALIDAD LLEGAD
    F304FNU Char(5)        Inz('');         // NUMERO DE VUELO
    F304DDA Zoned(8:0)    Inz(0);          // FECHA SALIDA
    F304ADA Zoned(8:0)    Inz(0);          // FECHA LLEGADA
    F304FDF Char(1)        Inz('');         // IND.SALIDA EXTRANJER
    F304DCO Char(64)       Inz('');         // PAIS SALIDA
    F304OFL Char(1)        Inz('');         // IND. DE SEGMENTO-1
    F304FAF Char(1)        Inz('');         // IND.LLEGADA EXTRANJE
    F304ACO Char(64)       Inz('');         // PAIS LLEGADA
    F304DFL Char(1)        Inz('');         // IND. SEGMENTO FINAL
    F304FAR Char(15)       Inz('');         // IMP.DE ESTE SEGMENTO
    F304FEE Char(15)       Inz('');         // IMP.GTOS    SEGMENTO
    F304CTN Char(32)       Inz('');         // Nº.BILL.CONCATENADO
    F304ETN Char(32)       Inz('');         // Nº.BILLETE CAMBIADO
    F304C01 Char(48)       Inz('');         // REFERENCIA-1 CLIENTE
    F304C02 Char(48)       Inz('');         // REFERENCIA-2 CLIENTE
    F304C03 Char(48)       Inz('');         // REFERENCIA-3 CLIENTE
    F304C04 Char(48)       Inz('');         // REFERENCIA-4 CLIENTE
    F304C05 Char(48)       Inz('');         // REFERENCIA-5 CLIENTE
    F304LIB Char(1384)     Inz('');         // RESERVADO - LIBRE
  End-DS;

  // ==========================================================
  // DS: Estructura CCURFR306T
  // ==========================================================
  Dcl-DS dsCCURFR306TTpl Qualified inz template;
    F306IDR  Zoned(3:0)    Inz(0);          // IDENTIF.REGISTRO-306
    F306TRN  Char(50)       Inz('');         // Nº.REFERENCIA OPERAC
    F306IID  Char(32)       Inz('');         // IDENTIF. ELEMENTO
    F306IQU  Zoned(9:3)    Inz(0);          // CANTIDAD ELEMENTOS
    F306UMC  Char(3)        Inz('');         // CODIGO UNIDAD MEDIDA
    F306UAM  Char(15)       Inz('');         // IMPORTE POR UNIDAD
    F306DAM  Char(15)       Inz('');         // IMPORTE DCTOS.APLIC.
    F306EAM  Char(15)       Inz('');         // IMPORTE AMPLIADO
    F306LIT  Char(15)       Inz('');         // IMPORTE TOT.ELEMENTO
    F306NET  Char(1)        Inz('');         // INDICADOR IMPUESTOS
    F306DFL  Char(1)        Inz('');         // INDICADOR DESCUENTOS
    F306SFP  Char(10)       Inz('');         // COD.POS.ENVIO ELEMEN
    F306STP  Char(10)       Inz('');         // COD.POS.DESTI.ELEMEN
    F306CCO  Char(20)       Inz('');         // CODIGO MERCANCIA
    F306CCE  Char(20)       Inz('');         // COD.MERCANCIA AMPLIA
    F306DSN  Zoned(6:0)    Inz(0);          // Nº.SECUENCIA ELEMENT
    F306C01  Char(48)       Inz('');         // REFERENCIA-1 CLIENTE
    F306C02  Char(48)       Inz('');         // REFERENCIA-2 CLIENTE
    F306C03  Char(48)       Inz('');         // REFERENCIA-3 CLIENTE
    F306C04  Char(48)       Inz('');         // REFERENCIA-4 CLIENTE
    F306C05  Char(48)       Inz('');         // REFERENCIA-5 CLIENTE
    F306C06  Char(48)       Inz('');         // REFERENCIA-6 CLIENTE
    F306C07  Char(48)       Inz('');         // REFERENCIA-7 CLIENTE
    F306C08  Char(48)       Inz('');         // REFERENCIA-8 CLIENTE
    F306C09  Char(48)       Inz('');         // REFERENCIA-9 CLIENTE
    F306C10  Char(48)       Inz('');         // REFERENCIA-10 CLIENTE
    F306LIB  Char(1500)     Inz('');         // RESERVADO - LIBRE
  End-DS;
  // ==========================================================
  // DS: Estructura F307 con etiquetas de negocio como comentarios
  // ==========================================================
  Dcl-DS dsCCURFR307TTpl Qualified inz template;
    F307IDR Zoned(3:0)    Inz(0);          // IDENTIF.REGISTRO-307
    F307TRN Char(50)       Inz('');         // Nº.REFERENCIA OPERAC
    F307ISN Char(4)        Inz('');         // Nº.SECUENCIA SERVIC.
    F307TDA Zoned(8:0)    Inz(0);          // FECHA OPERACION
    F307PDA Zoned(8:0)    Inz(0);          // FECHA CARGO EN CTA.
    F307TAM Char(15)       Inz('');         // IMPORTE OPERACION
    F307ITY Char(5)        Inz('');         // TIPO SERVICIO
    F307IDE Char(32)       Inz('');         // DESCRIPCION SERVICIO
    F307LIB Char(1875)     Inz('');         // RESERVADO - LIBRE
  End-DS;

  // ==========================================================
  // DS: Estructura CCURFR400T  Formato 400
  // ==========================================================
  Dcl-DS dsCCURFR400TTpl Qualified inz template;
    F400IDR   Zoned(3:0)    Inz(0);           // IDENTIF.REGISTRO-400
    F400VVI   Char(50)       Inz('');          // VENDOR IDENTIFIER
    F400VVN   Char(50)       Inz('');          // VENDOR NAME
    F400IAN   Char(50)       Inz('');          // INVOICE ACCO. NUMBER
    F400ACN   Char(50)       Inz('');          // INVOICE ACCO. NAME
    F400LIB   Char(1797)     Inz('');          // RESERVADO - LIBRE
  End-DS;

  // ==========================================================
  // DS: Estructura CCURFR401T  Formato 401
  // ==========================================================
  Dcl-DS dsCCURFR401TTpl Qualified inz template;
    F401IDR   Zoned(3:0)    Inz(0);          // IDENTIF.REGISTRO-401
    F401IAN   Char(50)       Inz('');         // INVOICE ACCO. NUMBER
    F401SID   Char(50)       Inz('');         // STATERMENT IDENTIFIE
    F401REN   Char(50)       Inz('');         // REFERENCE NUMBER
    F401INU   Char(32)       Inz('');         // INVOICE NUMBER
    F401IDA   Zoned(8:0)    Inz(0);          // INVOICE DATE
    F401ITY   Char(1)        Inz('');         // INVOICE TYPE
    F401RIN   Char(32)       Inz('');         // RELATED INVOI.NUMBER
    F401FTR   Zoned(8:0)    Inz(0);          // TRANSACTION DATE
    F401TAI   Char(3)        Inz('');         // ORI.TRANS.AMOUNT ISO
    F401OTA   Char(15)       Inz('');         // ORI.TRANS. AMOUNT
    F401PBA   Char(3)        Inz('');         // POSTED AMOUNT ISO
    F401PAM   Char(15)       Inz('');         // POSTED AMOUNT
    F401MNA   Char(32)       Inz('');         // MERCHANT NAME
    F401MCO   Char(5)        Inz('');         // MERCHANT CODE (MCC)
    F401MCI   Char(32)       Inz('');         // MERCHANT CITY
    F401MPO   Char(32)       Inz('');         // MERCHANT PROVINCE
    F401MPC   Char(20)       Inz('');         // MERCHANT POSTAL CODE
    F401MCU   Char(3)        Inz('');         // MERCHANT COUNTRY
    F401TAA   Char(15)       Inz('');         // TAX AMOUNT  IVA
    F401LTA   Char(15)       Inz('');         // TAX AMOUNT  IVA LOCA
    F401VAT   Char(15)       Inz('');         // VALUE ADDED TAX AMOU
    F401STA   Char(15)       Inz('');         // SALES TAX AMOUNT
    F401OAM   Char(15)       Inz('');         // OTHER TAX AMOUNT
    F401MTN   Char(20)       Inz('');         // MERCHANT TAX NUMBER
    F401CTN   Char(20)       Inz('');         // CUSTOMER TAX NUMBER
    F401VDI   Char(1)        Inz('');         // VAT DATE UBDUCATIR
    F401TRD   Char(32)       Inz('');         // TRANSACI.DESCRIPCION
    F401VFI   Char(1)        Inz('');         // VISA FEE INDICATOR
    F401VTI   Char(5)        Inz('');         // VISA TYPE
    F401VTD   Char(42)       Inz('');         // VISA TYPE DESCRIPCIO
    F401VDC   Char(3)        Inz('');         // VISA DESTINA.COUNTRY
    F401VSC   Char(3)        Inz('');         // VISA SERV.CHARGE ISO
    F401VCH   Char(15)       Inz('');         // VISA SERV.CHARGE
    F401BSH   Char(3)        Inz('');         // BILLED SERVI.CHARGE
    F401PSC   Char(15)       Inz('');         // POSTED SERVI.CHARGE
    F401OCD   Char(42)       Inz('');         // OTHER CHARGE DESCRIP
    F401OCI   Char(3)        Inz('');         // OTHER CHANGE ISO
    F401OOC   Char(15)       Inz('');         // ORIGIN.OTHER CHANGE
    F401POC   Char(3)        Inz('');         // BILLED O.CHANGE ISO
    F401PCH   Char(15)       Inz('');         // POSTED OTHER CHANGE
    F401CF1   Char(48)       Inz('');         // CUSTOM FIED 1 -REF-1
    F401CF2   Char(48)       Inz('');         // CUSTOM FIED 2 -REF-2
    F401CF3   Char(48)       Inz('');         // CUSTOM FIED 3 -REF-3
    F401CF4   Char(48)       Inz('');         // CUSTOM FIED 4 -REF-4
    F401CF5   Char(48)       Inz('');         // CUSTOM FIED 5 -REF-5
    F401CF6   Char(48)       Inz('');         // CUSTOM FIED 6 -REF-6
    F401CF7   Char(48)       Inz('');         // CUSTOM FIED 7 -REF-7
    F401CF8   Char(48)       Inz('');         // CUSTOM FIED 8 -REF-8
    F401CF9   Char(48)       Inz('');         // CUSTOM FIED 9 -REF-9
    F401C10  Char(48)        Inz('');         // CUSTOM FIED10 -REF10
    F401LIB  Char(777)       Inz('');         // RESERVADO - LIBRE
  End-DS;

  //------------------------------------------------------------------------
  // Declaraciones de Variables
  //------------------------------------------------------------------------

  //------------------------------------------------------------------------
  // Variables y Constantes
  //------------------------------------------------------------------------
  Dcl-c WComi   const(x'7D');