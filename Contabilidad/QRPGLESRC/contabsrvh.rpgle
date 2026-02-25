**FREE
  //------------------------------------------------------------------------
  // UTILSCONTH - COPY FILE PARA CONTABSRV
  // Fecha: Octubre 2025                                            LM
  //------------------------------------------------------------------------
  //------------------------------------------------------------------------
  // Prototipos 
  //------------------------------------------------------------------------
  /IF DEFINED(PGM_ULTKEY)
    dcl-pr ULTKEY extPgm('ULTKEY');
      NumRefer    Zoned(9:0);
    end-pr;
  /ENDIF
  /IF DEFINED(Funciones_CONTABSRV)
  // EVIDENCIAS CONTABLES
  dcl-pr CONTABSRV_Guardar_Evidencias_Contables_Cabecera ind;
    dsCabevi likeds(dsCabeviTempl);
    sqlError char(5);
    sqlMensaje char(70);
    in_NomCabpar Char(10);
  end-pr;

  dcl-pr CONTABSRV_Borrar_Evidencias_Contables_Cabecera ind;
    dsCabevi likeds(dsCabeviTempl);
    sqlError char(5);
    sqlMensaje char(70);
    in_NomCabpar Char(10);
  end-pr;

  dcl-pr CONTABSRV_Guardar_Evidencias_Contables_Detalle ind;
    // Marca: C - Crear Fic. Temporal
    //        G - Grabar en Fic Temporal
    //        F - Finalizar y Grabar en Fichero Final
    marca char(1);
    dsDetevi likeds(dsDeteviTempl);
    sqlError char(5);
    sqlMensaje char(70);
    in_NomDetpar Char(10);
  end-pr;

  dcl-pr CONTABSRV_Crear_Fichero_Detalle_Evidencia_Temporal ind;
    nombreFichero char(50);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr CONTABSRV_Grabar_Detalle_Evidencia_Temporal ind;
    nombreFichero char(50);
    dsDetevi likeds(dsDeteviTempl);
    sqlError char(5);
    sqlMensaje char(70);
  end-pr;

  dcl-pr CONTABSRV_Grabar_Detalles_Evidencias ind;
    nombreFichero char(50);
    dsDetevi likeds(dsDeteviTempl);
    sqlError char(5);
    sqlMensaje char(70);
    in_NomDetpar char(10);
  end-pr;

  // ASIENTO
  dcl-pr CONTABSRV_Obtener_Datos_Asiento ind;
    // Puede venir informada la clave para acceder a la tabla 
    // ASIENTOS_CUENTAS_POR_PRODUCTO
    // y los datos parametrizables los cogemos de ahí. 
    // ESTE PARAMETRO TIENE PRIORIDAD.
    dsKeyAsiento likeds(dsKeyAsientoTpl);
    // O puede venir informada una DS con los datos, que en vez de 
    // parametrizarse en tabla,
    // se mandan directamente por ser casos especiales.
    dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl);
    // Estos son los datos del asiento que no se pueden parametrizar
    dsDatosAsientoNoParametrizables likeds(dsDatosAsientoNoParametrizablesTpl);
    dsAsifilen likeds(dsAsifilenTpl); // Parámetro de salida
    textoError char(100); // Parámetro de salida si hay error
  end-pr;

  dcl-pr CONTABSRV_Obtener_Datos_Parametrizados_Asiento ind;
    dsKeyAsiento likeds(dsKeyAsientoTpl);   // Parámetro de entrada
    // Parámetro de salida
    dsDatosAsientoParametrizables likeds(dsDatosAsientoParametrizablesTpl); 
  end-pr;

  dcl-pr CONTABSRV_Grabar_Asiento ind;
    dsAsifilen likeds(dsAsifilenTpl) const;
    sqlError char(5);
    sqlMensaje char(70);
    P_NomAsiPar char(10);
  end-pr;

  dcl-pr CONTABSRV_Asignar_Numero_Apunte char(6);
    fecha timestamp const;
  end-pr;

  dcl-pr CONTABSRV_Genera_Contabilidad_Totales_Producto;
    Acumulador   likeds(AcumuladorTpl) Dim(100);
    Inx          Zoned(3);
    ID_Contab    Zoned(5);
    Num_Apunte   Char(6);
    fecproces    Zoned(8);
    P_NomAsiPar  Char(10);
  end-pr;

  dcl-pr CONTABSRV_Copy_Ficheros_Paralelo Ind;
    P_NomProc  Char(10);
    P_ENV      Char(10);
  end-pr;

  dcl-pr CONTABSRV_Registro_Auditoria_Paralelo;
    P_ProcEjec    Char(10);
    P_NomProc     Char(10);
    P_NumApun     Char(6);
    P_NomAsiPar   Char(10);
    P_NomCabpar   Char(10);
    P_NomDetpar   Char(10);
  end-pr;
  /ENDIF  
  /IF DEFINED(PGM_ASBUNU)
  dcl-pr ASBUNU extPgm('ASBUNU');
    anio char(2);
    mes char(2);
    apunte char(6);
  end-pr;
  /ENDIF  
  //------------------------------------------------------------------------
  // Estructuras - templates
  //------------------------------------------------------------------------
  /IF DEFINED(Estructuras_Asientos_Evidencias)
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
  /ENDIF

  /IF DEFINED(dsBLODIANTpl)
    dcl-ds dsBLODIANTpl qualified template inz;
      BFICHE   char(1);
      BCLAVA   char(1);
      BCPONE   packed(1:0);   // NUMERIC
      BLIBR1   char(2);
      BACTIV   packed(2:0);   // NUMERIC
      BLIBR2   char(1);
      BNUMES   zoned(7:0);    // DECIMAL
      BDIGIT   packed(1:0);   // NUMERIC
      BDUPLI   char(1);
      BCODRE   char(1);
      BNUMSO   packed(14:0);  // NUMERIC
      BADICI   char(1);
      BIMPOR   packed(9:0);   // NUMERIC
      BLIBR5   char(1);
      BFECON   zoned(9:0);    // DECIMAL
      BDICON   packed(2:0);   // NUMERIC
      BAPROB   char(1);
      BPOURM   char(1);
      BCOBRO   char(1);
      BNUREG   zoned(7:0);    // DECIMAL
      BNOIMP   char(1);
      BDESCT   packed(5:3);   // NUMERIC
      BCONCO   char(1);
      BPANTA   char(1);
      BOPDIF   packed(5:0);   // NUMERIC
      BPLDIF   packed(2:0);   // NUMERIC
      BIRREG   char(8);
      BPAIS    packed(3:0);   // NUMERIC
      BESTPV   zoned(7:0);    // DECIMAL
      BLIBR3   char(1);
      BREFER   zoned(9:0);    // DECIMAL
      BLIBR4   char(6);
      BSEDOL   char(36);
      BNUPRO   packed(7:0);   // NUMERIC
      BTIPRO   char(1);
      BNUMTF   char(5);
      BNUBIL   char(10);
      BEUROS   zoned(9:0);    // DECIMAL
      BMONED   char(1);
      BNOPRE   char(5);
      BNREEM   char(10);
      BTARJE   char(19);
      BPUREN   char(5);
      BSUREN   char(3);
      BBIREN   char(15);
      BAGENC   packed(4:0);   // NUMERIC
      BMMSS    char(4);
    end-ds;
  /ENDIF
  /IF DEFINED(dsAUBOLSATpl)
    dcl-ds dsAUBOLSATpl qualified template inz;
      AKEY     packed(14:0);
      ANUMTA   char(19);
      ANOMTA   char(26);
      ADESDE   packed(6:0);
      AHASTA   packed(6:0);
      APAIS    packed(3:0);
      AWSENT   char(2);
      AWSDA    char(2);
      AFECTF   packed(8:0);
      AHORTF   zoned(6:0);
      AFECDA   packed(8:0);
      AHORDA   zoned(6:0);
      ANOMES   char(32);
      AACTI    packed(2:0);
      ADOMES   char(32);
      ALOCES   char(32);
      ALIBRE   char(1);
      ANUMES   zoned(7:0);
      APESET   zoned(9:0);
      ADOLAR   packed(5:0);
      AMERCA   char(30);
      ATELEX   char(1);
      APECA    char(15);
      AOBSER   char(39);
      AINDET   char(14);
      AFETF2   packed(8:0);
      AHOTF2   zoned(6:0);
      AFEDA2   packed(8:0);
      AHODA2   zoned(6:0);
      ACODAP   char(1);
      ACOREC   char(1);
      ANUMTF   char(5);
      ADIAS    packed(2:0);
      APECA1   char(2);
      APECA2   char(2);
      ACLDNI   packed(1:0);
      ANUDNI   char(9);
      ADIAS9   packed(1:0);
      AOPER9   packed(2:0);
      ASEOPE   char(18);
      ASEDOL   char(36);
      AIMPRE   char(3);
      AYAIMP   packed(1:0);
      ADUPLI   char(1);
      ARESDA   char(1);
      ATIDAT   char(1);
      ANUDAT   char(2);
      ASEGLI   char(26);
      AÑINGE   char(2);        // ojo cambiado de AÑINGE
      ACLAVE   char(2);
      AALFAB   char(2);
      AACTIN   char(3);
      APFRCJ   char(1);
      AREFCA   char(12);
      ACLOPE   char(4);
      AIDEST   char(15);
      AFHCAJ   char(12);
      ACARCA   char(12);
      AFEREC   char(6);
      APISTA   char(76);
      ARFAVI   char(61);
      AIMPMO   zoned(9:2);
      AMONED   packed(3:0);
      ACAMBI   packed(6:3);
      AREFER   char(20);
      APECAD   char(8);
      AEMV     char(30);
    end-ds;
  /ENDIF
  /IF DEFINED(dsOPGENXDTpl)
    dcl-ds dsOPGENXDTpl qualified template inz;
      SFTER    char(3);
      RCPNO    packed(3:0);
      DFTER    char(3);
      ACCT     char(19);
      CAMTR    packed(15:2);
      CHGDT    packed(6:0);
      DATYP    char(2);
      CHTYP    packed(3:0);
      ESTAB    char(36);
      LCITY    char(26);
      GEOCD    packed(3:0);
      APPCD    packed(3:0);
      TYPCH    char(2);
      REFNO    char(8);
      ANBR     char(6);
      SENUM    char(15);
      BLCUR    char(3);
      BLAMT    packed(15:2);
      INTES    char(4);
      ESTST    char(35);
      ESTCO    char(20);
      ESTZP    char(11);
      ESTPN    char(20);
      MSCCD    char(4);
      MCCCD    char(4);
      TAX1     packed(15:2);
      TAX2     packed(15:2);
      ORIGD    char(15);
      CUSRF    char(30);
      CUSRF2   char(30);
      CUSRF3   char(30);
      CUSRF4   char(30);
      CUSRF5   char(30);
      CUSRF6   char(30);
      CHOLDP   char(1);
      CARDP    char(1);
      CPTRM    char(1);
      ECI      char(1);
      CAVV     char(4);
      NRID     char(15);
      CRDINP   char(1);
      SURFEE   char(10);
      TRMTYP   char(1);
      AQGEO    char(3);
      VCRDD    char(1);
      TKNID    char(19);
      TKRQID   char(11);
      TKLVL    char(2);
      CVVRST   char(2);
      AUTYP    char(1);
      AURCDE   char(2);
      SECFAR   char(2);
      CVVIND   char(2);
      AUTHTR   char(16);
      VERACT2  char(2);
      IPADDR   char(8);
      SCAEXE   char(2);
      RPAIS    packed(3:0);
      RSOCIO   packed(8:0);
      RREFER   zoned(9:0);
      RFEREC   packed(8:0);
      SEQNO    packed(3:0);
    end-ds;
  /ENDIF
  /IF DEFINED(dsDIN1Tpl)
    dcl-ds dsDIN1Tpl qualified template inz;
      DIDENT   char(1);
      DRECEX   packed(1:0);
      DZONA    char(3);
      DACTIV   packed(2:0);
      DLIBR2   char(1);
      DNESTA   zoned(7:0);
      DDIGIT   packed(1:0);
      DLIBR1   char(1);
      DPS2D1   char(1);
      DNUMSO   char(19);
      DADICI   char(1);
      DORDEN   char(1);
      DIMPOR   packed(8:0);
      DLIBR3   char(1);
      DFECON   zoned(9:0);
      DDICON   packed(2:0);
      DNUTRA   packed(3:0);
      DNUREG   zoned(6:0);
      DZIM     packed(1:0);
      DLIBR4   char(1);
      DNUMRE   zoned(8:0);
      DPTLLA   char(1);
      DRENTO   packed(7:0);
      DCODIG   char(8);
      DPAIS    packed(3:0);
      DNACI4   char(5);
      DNUREF   zoned(9:0);
      DACTIN   packed(3:0);
      DESTAB   char(32);
      DLIBR5   char(3);
      DEUROS   zoned(9:2);
      DRENPE   packed(7:0);
      DMONED   char(1);
      DNUMAU   char(6);
      DP23     char(3);
      DP55     char(256);
      DPLLV55  char(2);
      DP22     char(12);
      DP39     char(3);
    end-ds;
  /ENDIF
  /IF DEFINED(dsRSYPRICETpl)
    dcl-ds dsRSYPRICETpl qualified template inz;
      RMSG     char(800);
      RTIPMS   packed(4:0);
      RP32     char(11);
      RP12     char(12);
      RP11     char(6);
      RREINT   packed(1:0);
      RSER     char(192);
      RKEYAU   packed(14:0);
      R32ORI   char(11);
      RANULA   char(1);
      RFEHOR   timestamp;
      RIDMSG   packed(9:0);
      RMDMID   char(24);
      RMDCID   char(24);
    end-ds;
  /ENDIF
  /IF DEFINED(dsPRICEBOLTpl)
    dcl-ds dsPRICEBOLTpl qualified template inz;
      PMSG     char(464);
      PTIPMS   packed(4:0);
      PP32     char(11);
      PP12     char(12);
      PP11     char(6);
      PREINT   packed(1:0);
      PSER     char(192);
      PKEYAU   packed(14:0);
      P32ORI   char(11);
      PANULA   char(1);
      PFEHOR   char(14);
    end-ds;
  /ENDIF
  /IF DEFINED(dsESTA1TPL)
    dcl-ds dsESTA1TPL qualified template inz;
      NUMEST   packed(7:0);
      EDIG     packed(1:0);
      ESTYPE   char(2);
      ELIB10   char(3);
      EACTPR   packed(2:0);
      ECATEG   packed(1:0);
      EITE     packed(3:2);
      EMODRE   packed(3:0);
      EMODCA   packed(4:0);
      EEXIRE   packed(3:0);
      EEXICA   packed(4:0);
      ECOENV   packed(1:0);
      ECONOR   packed(1:0);
      EEMPCO   char(30);
      ENOCOB   packed(1:0);
      ENUMPV   zoned(5:0);
      ENIF     packed(1:0);
      ENNIF    char(10);
      ELIBR0   char(1);
      EFCONT   zoned(9:0);
      EESTCI   char(1);
      ELOCON   packed(4:0);
      ELOFIR   packed(4:0);
      ELIBR2   char(1);
      EFRESP   zoned(9:0);
      ERESER   char(1);
      EDIAF    char(4);
      EFEPAG   packed(2:0);
      ENUFUC   zoned(11:0);
      ELIBR1   char(5);
      EXX2     packed(3:0);
      ECARGO   char(12);
      ENOMFI   char(35);
      EFALTA   zoned(4:0);
      ENOMBE   char(35);
      EDOMBE   char(35);
      ELOCBE   char(35);
      ENOMEN   char(30);
      ENIMPR   packed(1:0);
      ECLIMP   char(1);
      ECADEN   char(1);
      EDESCU   packed(5:3);
      ENIVEL   packed(10:2);
      EBOLIT   packed(3:0);
      ECOBOL   char(1);
      AGENTE   char(1);
      ECOPAA   char(1);
      ENOCHE   char(1);
      EMOTBA   char(1);
      EMANTE   char(1);
      EFULT    zoned(6:0);
      ECAULT   char(1);
      EFPENU   zoned(6:0);
      ECAPNL   char(1);
      EOPES3   zoned(8:0);
      EIMES3   packed(9:0);
      EOPEX3   zoned(8:0);
      EIMEX3   packed(9:0);
      EOPES2   zoned(8:0);
      EIMES2   packed(9:0);
      EOPEX2   zoned(8:0);
      EIMEX2   packed(9:0);
      EOPES1   zoned(8:0);
      EIMES1   packed(9:0);
      EOPEX1   zoned(8:0);
      EIMEX1   packed(9:0);
      ESALDO   packed(10:2);
      ENOMBR   char(32);
      ECADES   char(3);
      EDOPV    char(32);
      ELIB4    char(3);
      ELOCPV   char(32);
      ELIB5    packed(3:0);
      ENLOPV   packed(4:0);
      EFESAL   packed(6:0);
      EFBAJA   zoned(6:0);
      ESALI    packed(1:0);
      ECBAJA   packed(1:0);
      ECMOVI   packed(1:0);
      ETELF    char(8);
      ENUTAL   char(6);
      ESALRO   packed(1:0);
      EPROPV   packed(2:0);
      ESALCE   packed(1:0);
      EDISPV   packed(2:0);
      ENOTFA   packed(5:0);
      ENOTIM   packed(5:0);
      ENOIMP   packed(1:0);
      EMENSA   packed(1:0);
      ELIBR3   char(1);
      EENVCH   char(1);
      EZONAB   packed(4:0);
      EDISTB   packed(2:0);
      EPROB    packed(2:0);
      EOPRPM   packed(5:0);
      EIMPPM   packed(9:0);
      EDESDE   char(1);
      EHASTA   char(1);
      ETOEST   char(1);
      ECORBE   packed(1:0);
      EFORPA   char(1);
      ELIB8    char(1);
      ENOOFE   char(1);
      ELIB7    char(1);
      ENUBCO   zoned(5:0);
      ENUSUC   packed(4:0);
      ENUCC    char(10);
      EDIRBC   char(35);
      EZOBCO   packed(4:0);
      EIPROR   zoned(9:0);
      ELIBR4   char(1);
      EFPROR   zoned(9:0);
      ECPROR   packed(1:0);
      EFEALT   zoned(6:0);
      EOPDR3   zoned(8:0);
      EIMDR3   packed(9:0);
      EOPDR2   zoned(8:0);
      EIMDR2   packed(9:0);
      EOPDR1   zoned(8:0);
      EIMDR1   packed(9:0);
      EACDIS   char(1);
      ENIFBE   packed(1:0);
      ENNIFB   char(10);
    end-ds;
  /ENDIF

  /IF DEFINED(dsDESCRFACTpl)
    dcl-ds dsDESCRFACTpl qualified template inz;
      GKEY      Zoned(9:0);
      GPAIS     Packed(3:0);
      GLIBR1    Char(1);
      GPURGE    Zoned(9:0);
      GREFIN    Char(8);
      GLIN1     Char(59);
      GLIN2     Char(59);
      GNOMES    Char(32);
      GLOCES    Char(26);
      GDESCH    Char(40);
      GNUMSO    Zoned(8:0);
      GCINTA    Char(150);
      GREFUS    Char(15);
      GISOMA    Char(15);
      GLIN3     Char(59);
      GACTIN    Packed(3:0);
    End-DS;
  /ENDIF
  /IF DEFINED(dsOPATMXCTpl)
    Dcl-DS dsOPATMXCTpl Qualified Inz;
      AXCREF   Zoned(9:0);
      AXCFEC   Packed(8:0);
      AXCSOC   Packed(8:0);
      AXCPAI   Packed(3:0);
      AXCREC   Packed(4:0);
      SCGMT    Char(6);
      SCDAT    Char(6);
      LCTIM    Char(6);
      LCDAT    Char(6);
      ATMID    Char(8);
    End-DS;
  /ENDIF

  /IF DEFINED(Common_Variables)
    // Array para Acumular Importes a contabilizar
    // Totalizados por Producto
    dcl-ds AcumuladorTpl Qualified template Inz;
      Cod_prod  Zoned(3:0);
      Total    Packed(14:3);
    end-ds;
    //------------------------------------------------------------------------
    // Declaraciones de Variables 
    //------------------------------------------------------------------------
    //--------------------------------------        
    // Para evidencias                              
    //--------------------------------------        
    dcl-s  sqlError char(5) inz;                    
    dcl-s  sqlMensaje char(70) inz;                 
    dcl-s  marca char(1) inz;                       
    dcl-s  numeroLinea zoned(5:0) inz;              
    Dcl-s  V_observacion Varchar(5000) inz;         
    Dcl-s  WnumLinea Zoned(5);                      
    dcl-c  CREAR_TEMPORAL const('C');               
    dcl-c  GRABAR_TEMPORAL const('G');              
    dcl-c  GRABAR_A_FICHERO const('F');             
    dcl-ds dsDetevi likeds(dsDeteviTempl) inz;      
    //------------------------------------------------------------------------
    // Variables y Constantes
    //------------------------------------------------------------------------
    Dcl-c WComi   const(x'7D');
  /ENDIF  