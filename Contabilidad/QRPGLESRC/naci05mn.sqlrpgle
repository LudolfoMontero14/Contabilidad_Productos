**Free
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
        decedit('0,') datedit(*DMY/)
        bnddir('UTILITIES/UTILITIES':'CONTBNDDIR')
        dftactgrp(*no) actgrp(*new) main(main);
  //*************************************************************************
  //*          FACTURACION DIARIA DE ESTABLECIMIENTOS
  //*        ===============================================
  //*
  //*   -- SACA TOTALES DE LA ENTRADA DE LA FACTURACION.
  //*   -- GENERA FICHEROS PARA EL DINERS (Service Center).
  //*   -- 15.04.98 NO COBRAR 0,60 EUROS ACT. 65 A ESPAÑOLES.
  //*   -- 01.05.04 NO COBRAR 0,60 EUROS ACT. 65 A EXTRANJEROS.
  //*
  //*   -- NOTA: 12-2001 "SEGREGAR CUENTA DE -PA- 4321"  LINEAS (%)
  //*   ------------------------------------------------------------
  //*   ANTES EL ELEMENTO -6- DE LAS SERIES ERAN TODAS LAS -TE'S-.
  //*   AHORA EL ELEMENTO -6- SON TARJETAS -TE'S- QUE NO CONCILIAN
  //*   A LA CTA. 4321 Y EL ELEMENTO -10- (NO SE UTILIZA SEGUN FICH.
  //*   CLESPAÑA) SON TARJETAS -TE'S- QUE SI CONCILIAN A LA CTA.4325
  //*
  //*   -- 06.2005: Tarjetas "DUAL DINERS-SANTANDER"
  //*   Del total de Operaciones Españolas (TOTAL PA), segregamos las ope-
  //*   raciones en "Tarjetas NO Dual" y "Tarjetas Dual". Asimismo tambien
  //*   lo hacemos para la cuenta contable (4321) llevandolo a (4305 03 05).
  //*
  //*************************************************************************

  // --------------------------
  // Declaracion de Prototipos
  // --------------------------
  // ** Actualiza Total del FAGE00
  dcl-pr ACUTOTN extpgm('ACUTOTN');
    pOpcion char(6) const;
    pTexto char(30) const;
    pImporte packed(13:0) const;
    pUDate zoned(6:0) const; // UDATE (AAMMDD) tal y como lo usa el original
  end-pr;

  // --------------------------
  // Cpys y Include
  // --------------------------
  ///COPY EXPLOTA/QRPGLESRC,DSTIMSYS

  /Define Estructuras_Asientos_Evidencias
  /define PGM_ULTKEY
  /Define dsBLODIANTpl
  /Define dsAUBOLSATpl
  /Define dsOPGENXDTpl
  /Define dsDIN1Tpl
  /Define dsRSYPRICETpl
  /Define dsPRICEBOLTpl
  /Define dsESTA1Tpl
  /Define dsDESCRFACTpl
  /Define dsOPATMXCTpl
  /Define Common_Variables
  /define Funciones_CONTABSRV
  /Include EXPLOTA/QRPGLESRC,CONTABSRVH  // Servicios de contabilidad

  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
  // --------------------------
  // Declaracion Estructuras
  // --------------------------

  // Estructura del BLODIAN
  dcl-ds dsBLODIAN likeDS(dsBLODIANTpl) inz;

  // Estructura del AUBOLSA
  dcl-ds dsAUBOLSA likeDS(dsAUBOLSATpl) inz;

  // Estructura del OPGENXD
  dcl-ds dsOPGENXD likeDS(dsOPGENXDTpl) inz;

  // Estructura del DIN1
  dcl-ds dsDIN1 likeDS(dsDIN1Tpl) inz;

  // Estructura del RSYPRICE
  dcl-ds dsRSYPRICE likeDS(dsRSYPRICETpl) inz;

  // Estructura del PRICEBOL
  dcl-ds dsPRICEBOL likeDS(dsPRICEBOLTpl) inz;

  // Estructura del ESTA1
  dcl-ds dsESTA1 likeDS(dsESTA1Tpl) inz;

  // Estructura del ESTA1
  dcl-ds dsDESCRFAC likeDS(dsDESCRFACTpl) inz;

  // Estructura del OPATMXC
  dcl-ds dsOPATMXC likeDS(dsOPATMXCTpl) inz;


  // Array/Matriz que totaliza importes por productos
  dcl-ds Acumulador likeds(AcumuladorTpl) Dim(100) Inz;
  // Array/Matriz que totaliza importes de gastos por productos
  dcl-ds Acumulador_Gastos likeds(AcumuladorTpl) Dim(100) Inz;
  // --------------------------
  // Declaracion de Variables
  // --------------------------
  Dcl-s WInd Zoned(3);
  Dcl-s WInd_Gtos Zoned(3);
  Dcl-s WCodContab Zoned(5) Inz(33); //Id_Asiento NACI05NEW
  Dcl-s WApunte Char(6);
  Dcl-s fecproces Zoned(8);
  Dcl-s WCod_Prod Zoned(3);
  Dcl-s WNOM_TARJETA Char(35);
  Dcl-s WimpTotal Zoned(10:0);
  Dcl-s WimpTotal_Gtos Zoned(10:0);
  Dcl-S fechaSistema Timestamp;
  Dcl-s v_tipo_error Char(3) Inz('PGM');
  Dcl-s WNomDetPar Char(10);
  Dcl-s WNomAsiPar Char(10);
  Dcl-s WNomCabpar Char(10);
  // --------------------------
  // Declaracion de Cursores
  // --------------------------
  Exec Sql
        SET OPTION Commit = *none,
                CloSqlCsr = *endmod,
                AlwCpyDta = *yes;

    // Solicitudes Pendientes
  Exec Sql declare  C_BLODIAN Cursor For
        SELECT
          BFICHE, BCLAVA, BCPONE, BLIBR1, BACTIV, BLIBR2, BNUMES,
          BDIGIT, BDUPLI, BCODRE, BNUMSO, BADICI, BIMPOR, BLIBR5,
          BFECON, BDICON, BAPROB, BPOURM, BCOBRO, BNUREG, BNOIMP,
          BDESCT, BCONCO, BPANTA, BOPDIF, BPLDIF, BIRREG, BPAIS,
          BESTPV, BLIBR3, BREFER, BLIBR4, BSEDOL, BNUPRO, BTIPRO,
          BNUMTF, BNUBIL, BEUROS, BMONED, BNOPRE, BNREEM, BTARJE,
          BPUREN, BSUREN, BBIREN, BAGENC, BMMSS
        FROM BLODIAN
        WHERE
          BFICHE = 'N'
          AND BCODRE <> 'R'
        Order By BNUMES;

  // ******************************************************************
  // PROCESO PRINCIPAL
  // ******************************************************************
  dcl-proc main;

    dcl-pi *n;
      TOTCUB   Packed(11:0);
      P_NomAsiPar   Char(10);
      P_NomCabpar   Char(10);
      P_NomDetPar   Char(10);
      P_NumApunte   Char( 6);
    end-pi;

    dcl-s BNUMES_ANT like(dsBLODIAN.BNUMES) inz(*loval); // Valor anterior de BNUMES

    WNomAsiPar = P_NomAsiPar;
    WNomCabpar = P_NomCabpar;
    WNomDetPar = P_NomDetPar;

    InicializarDatos();

    fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);
    if not Crear_Temporal_Detalle_Evidencia(dsDetevi);
          //leave;
    endif;

    Reset Acumulador; // Inicializamos Acumulador de Productos
    Reset Acumulador_Gastos; // Inicializamos Acumulador de Gastos x Productos

    Exec Sql Open  C_BLODIAN;
    sqlStt = '00000';

    Exec Sql Fetch From  C_BLODIAN into :dsBLODIAN;
    dow sqlStt = '00000';

      // Detectar cambio de BNUMES
      if dsBLODIAN.BNUMES <> BNUMES_ANT;
        Busca_Datos_ESTA1(dsBLODIAN.BNUMES:dsESTA1);

      // Actualizar el valor anterior
        BNUMES_ANT = dsBLODIAN.BNUMES;
      endif;

      If dsBLODIAN.BCODRE = '7' and dsBLODIAN.BCLAVA = '1';
        // *In21
      EndIf;

      WimpTotal += dsBLODIAN.BIMPOR;
      Reset dsDIN1;
      If dsBLODIAN.BCODRE = '7'; // Solo operaciones de consumo
        // Solo Internacionales
        If dsBLODIAN.BPAIS > 0 and
          dsBLODIAN.BPAIS <> 999;
          If Not Busca_Autorizacion();
            Iter;
          EndIf;

          // Asigno 777 solo a las operaciones Internacionales
          WCod_Prod = 777;
          WNOM_TARJETA = 'Tarjeta Internacional';
          Acumula_importe(dsBLODIAN.BIMPOR/100:WCod_Prod);

          Genera_Registros_DIN1();
          // Calculo de gastos de cajeros tarjetas Internacional
          If dsBLODIAN.BACTIV = 99;
            WimpTotal_Gtos += dsBLODIAN.BIMPOR;
            Acumula_Gastos_producto(dsBLODIAN.BIMPOR/100:WCod_Prod);
          EndIf;
          //Genera_Registros_DIN1();
        EndIf;

        // Solo Tarjetas Diners Spain
        If dsBLODIAN.BPAIS = 999;
          Exec SQL
            Select SCODPR, SNOMEM
            Into :WCod_Prod,:WNOM_TARJETA
            From T_MSOCIO
            Where
              NUREAL = Dec(SubString(:dsBLODIAN.BTARJE, 3, 8), 8, 0);

          Select;
            When Sqlcode < 0;
              observacionSql = 'Error busqueda de de datos de Tarjeta Diners Spain';
              Clear Nivel_Alerta;
              Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
              WCod_Prod= 888;
              WNOM_TARJETA= 'ERROR en el T_MSOCIO';
            When sqlcode = 100;
              observacionSql = 'Error Tarjeta Diners Spain NO Existe';
              Clear Nivel_Alerta;
              Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
              WCod_Prod= 888;
              WNOM_TARJETA= 'ERROR no existe Socio en el T_MSOCIO';
          endSl;

          Acumula_importe(dsBLODIAN.BIMPOR/100:WCod_Prod);

          // Calculo de gastos de cajeros tarjetas Diners
          If dsBLODIAN.BACTIV = 99;
            WimpTotal_Gtos += dsBLODIAN.BIMPOR;
            Acumula_Gastos_producto(dsBLODIAN.BIMPOR/100:WCod_Prod);
          EndIf;

        EndIf;

        Inserta_Detalle_Evi();
      Endif;

      Exec Sql Fetch From  C_BLODIAN into :dsBLODIAN;
    EndDo;

    Exec Sql Close  C_BLODIAN;

    If WimpTotal > 0;
      CONTABSRV_Genera_Contabilidad_Totales_Producto(
          Acumulador     // Arreglo de Totales por Producto
          :WInd           // Indice de registros Grabados en el Arreglo
          :WCodContab     // Indice Contable: 5 Para este proceso
          :WApunte        // NUmero de Apunte
          :fecproces      // Fecha del asiento DDMMAAAA
          :WNomAsiPar     // Nombre Fichero Parcial ASIFILEn
            );

      If WimpTotal_Gtos > 0;
        WCodContab = 34;      // Id Asientos gastos x productos
        CONTABSRV_Genera_Contabilidad_Totales_Producto(
          Acumulador_Gastos  // Arreglo de Totales Gastos x productos
          :WInd_Gtos         // Indice de registros Grabados en el Arreglo
          :WCodContab        // Indice Contable: 5 Para este proceso
          :WApunte           // NUmero de Apunte
          :fecproces         // Fecha del asiento DDMMAAAA
          :WNomAsiPar        // Nombre Fichero Parcial ASIFILEn
            );
      EndIf;

      Inserta_Totales_Evi();

      Grabar_Temporal_A_Detevi(dsDetevi);
      Guardar_Cabecera_Evidencia(dsDetevi);

    EndIf;

  End-Proc;
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
  //-----------------------------------------------------------------------------
  // Busca Datos del ESTA1
  //-----------------------------------------------------------------------------
  dcl-proc Busca_Datos_ESTA1;
    dcl-pi *n Ind;
      Cod_Estab Zoned(7:0);
      dsESTA1   likeDS(dsESTA1Tpl);
    end-pi;

    exec sql
      select
        NUMEST, EDIG, ESTYPE, ELIB10, EACTPR, ECATEG, EITE, EMODRE, EMODCA,
        EEXIRE, EEXICA, ECOENV, ECONOR, EEMPCO, ENOCOB, ENUMPV, ENIF, ENNIF,
        ELIBR0, EFCONT, EESTCI, ELOCON, ELOFIR, ELIBR2, EFRESP, ERESER, EDIAF,
        EFEPAG, ENUFUC, ELIBR1, EXX2, ECARGO, ENOMFI, EFALTA, ENOMBE, EDOMBE,
        ELOCBE, ENOMEN, ENIMPR, ECLIMP, ECADEN, EDESCU, ENIVEL, EBOLIT, ECOBOL,
        AGENTE, ECOPAA, ENOCHE, EMOTBA, EMANTE, EFULT, ECAULT, EFPENU, ECAPNL,
        EOPES3, EIMES3, EOPEX3, EIMEX3, EOPES2, EIMES2, EOPEX2, EIMEX2, EOPES1,
        EIMES1, EOPEX1, EIMEX1, ESALDO, ENOMBR, ECADES, EDOPV, ELIB4, ELOCPV,
        ELIB5, ENLOPV, EFESAL, EFBAJA, ESALI, ECBAJA, ECMOVI, ETELF, ENUTAL,
        ESALRO, EPROPV, ESALCE, EDISPV, ENOTFA, ENOTIM, ENOIMP, EMENSA, ELIBR3,
        EENVCH, EZONAB, EDISTB, EPROB, EOPRPM, EIMPPM, EDESDE, EHASTA, ETOEST,
        ECORBE, EFORPA, ELIB8, ENOOFE, ELIB7, ENUBCO, ENUSUC, ENUCC, EDIRBC,
        EZOBCO, EIPROR, ELIBR4, EFPROR, ECPROR, EFEALT, EOPDR3, EIMDR3, EOPDR2,
        EIMDR2, EOPDR1, EIMDR1, EACDIS, ENIFBE, ENNIFB
      into :dsESTA1
      from ESTA1
      Where
        NUMEST = :Cod_Estab;

    If Sqlcode < 0;
      observacionSql = 'Error busqueda Codigo Establecimiento: ' +
                        %Char(Cod_Estab);
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      Return *On;
    EndIf;

    If Sqlcode = 100;
      observacionSql = 'Error Codigo Establecimiento no se encuentra: ' +
                        %Char(Cod_Estab);
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      //Reset dsESTA1;
      Return *On;
    EndIf;
    Return *Off;
  End-Proc;
  //-----------------------------------------------------------------------------
  // Busca Autorizacion
  //-----------------------------------------------------------------------------
  dcl-proc Busca_Autorizacion;

    dcl-pi *n Ind;
    end-pi;

    Dcl-s NumSocio    Zoned(8);
    Dcl-s NUMCPO      Packed(3:0);
    Dcl-S POS_DES     Packed(3:0);
    Dcl-S POS_HAS     Packed(3:0);
    Dcl-s CHGDTO      Packed(9:0);

    // Si BNUMTF no está en blanco y 1er caracter es espacio, poner '0' en BNUMTF
    if dsBLODIAN.BNUMTF <> *blanks and
        %sUBST(dsBLODIAN.BNUMTF:1:1) = ' ';
      dsBLODIAN.BNUMTF = '0';
    endif;

    // Buscar en AUBOLSA
    exec sql
        select
          AKEY, ANUMTA, ANOMTA, ADESDE, AHASTA, APAIS,
          AWSENT, AWSDA, AFECTF, AHORTF, AFECDA, AHORDA,
          ANOMES, AACTI, ADOMES, ALOCES, ALIBRE, ANUMES,
          APESET, ADOLAR, AMERCA, ATELEX, APECA, AOBSER,
          AINDET, AFETF2, AHOTF2, AFEDA2, AHODA2, ACODAP,
          ACOREC, ANUMTF, ADIAS, APECA1, APECA2, ACLDNI,
          ANUDNI, ADIAS9, AOPER9, ASEOPE, ASEDOL, AIMPRE,
          AYAIMP, ADUPLI, ARESDA, ATIDAT, ANUDAT, ASEGLI,
          AÑINGE, ACLAVE, AALFAB, AACTIN, APFRCJ, AREFCA,
          ACLOPE, AIDEST, AFHCAJ, ACARCA, AFEREC, APISTA,
          ARFAVI, AIMPMO, AMONED, ACAMBI, AREFER, APECAD,
          AEMV
        into :dsAUBOLSA
        from SADE.AUBOLSA
        where
          ANUMTA = :dsBLODIAN.BTARJE
          and ANUMTF = :dsBLODIAN.BNUMTF
          and AFECTF = :dsBLODIAN.BFECON
          and AIMPMO = :dsBLODIAN.BIMPOR / 100
        fetch first 1 row only;

    If Sqlcode < 0;
      observacionSql = 'Error busqueda de Autorizacion (AUBOLSA) ';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      return *Off;
    EndIf;

    if sqlcode = 100;
      // No encontrado: buscar en OPGENXDL1
      monitor;
        NumSocio = %Dec(%SubSt(dsBLODIAN.BTARJE:3:8):8:0);
      on-error;
        NumSocio = 0;
      endmon;

      exec sql
          select
            SFTER, RCPNO, DFTER, ACCT, CAMTR, CHGDT, DATYP, CHTYP,
            ESTAB, LCITY, GEOCD, APPCD, TYPCH, REFNO, ANBR, SENUM,
            BLCUR, BLAMT, INTES, ESTST, ESTCO, ESTZP, ESTPN, MSCCD,
            MCCCD, TAX1, TAX2, ORIGD, CUSRF, CUSRF2, CUSRF3, CUSRF4,
            CUSRF5, CUSRF6, CHOLDP, CARDP, CPTRM, ECI, CAVV, NRID,
            CRDINP, SURFEE, TRMTYP, AQGEO, VCRDD, TKNID, TKRQID, TKLVL,
            CVVRST, AUTYP, AURCDE, SECFAR, CVVIND, AUTHTR, VERACT2,
            IPADDR, SCAEXE, RPAIS, RSOCIO, RREFER, RFEREC, SEQNO
          into :dsOPGENXD
          from FICHEROS.OPGENXD
          where
            RREFER = :dsBLODIAN.BREFER
            and RSOCIO = :NumSocio
          fetch first 1 row only;

      Select;
        When Sqlcode < 0;
          observacionSql = 'Error busqueda de Autorizacion (OPGENXD) ';
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
          return *Off;
        When sqlcode = 0;
          dsDIN1.DNUMAU = dsOPGENXD.ANBR;
        When sqlcode = 100;
          return *On;
      endSl;

    else;
      // Encontrado en AUTORIZW: procesar datos
      if %subst(dsAUBOLSA.APECA:4:6) = *blanks;
        dsDIN1.DNUMAU = dsAUBOLSA.ANUMTF;
      else;
        dsDIN1.DNUMAU = %subst(dsAUBOLSA.APECA:4:6);
      endif;
      dsDIN1.DP22 = dsAUBOLSA.ACARCA;

      // Código respuesta
      select;
        when %subst(dsAUBOLSA.APECA:11:3) <> *blanks;
          dsDIN1.DP39 = %subst(dsAUBOLSA.APECA:11:3);
        when dsAUBOLSA.ACLOPE = '1120' or
              dsAUBOLSA.ACLOPE = '1220';
          dsDIN1.DP39 = '082';
          if dsAUBOLSA.AIMPMO > 0;
            dsDIN1.DP39 = '083';
          endif;
          if dsAUBOLSA.ACOREC = 'D' or
              dsAUBOLSA.ACOREC = 'T';
            dsDIN1.DP39 = '181';
          endif;
        other;
          dsDIN1.DP39 = %subst(dsAUBOLSA.APECA:1:3);
      endsl;

      if dsDIN1.DP39 = '000';
        dsDIN1.DP39 = '081';
      endif;

      if %subst(dsAUBOLSA.ASEDOL:18:1) <> '5';
        return *On;
      endif;
    endif;

    // Número sec. tarjeta
    dsDIN1.DP23 = %subst(dsAUBOLSA.AEMV:5:3);

    Exec SQL
      SELECT
        RMSG, RTIPMS, RP32, RP12,
        RP11, RREINT, RSER, RKEYAU,
        R32ORI, RANULA, RFEHOR, RIDMSG,
        RMDMID, RMDCID
      into :dsRSYPRICE
      FROM PRICE.RSYPRICE
      where
        SubString(Digits(RKEYAU), 1, 10) =
          SubString(:dsAUBOLSA.ANUMTA, 1, 10) //PBASIC=ANUMTA
        and RP12 = :dsAUBOLSA.AFHCAJ
        and RTIPMS = Dec(:dsAUBOLSA.ACLOPE, 4, 0);

    Select;
      When Sqlcode < 0;
        observacionSql = 'Error busqueda de Autorizacion (AUBOLSA) ';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
        return *Off;

      When sqlcode = 100;
        Exec SQL
            SELECT
              PMSG, PTIPMS, PP32, PP12,
              PP11, PREINT, PSER, PKEYAU,
              P32ORI, PANULA, PFEHOR
            into :dsPRICEBOL
            FROM PRICE.PRICEBOL
            Where
              SubString(Digits(PKEYAU), 1, 10) =
                SubString(:dsAUBOLSA.ANUMTA, 1, 10) //PBASIC=ANUMTA
              and PP12 = :dsAUBOLSA.AFHCAJ
              and PTIPMS = Dec(:dsAUBOLSA.ACLOPE, 4, 0);

      When sqlcode = 0;
         dsRSYPRICE.RSER = dsPRICEBOL.PSER;
         dsRSYPRICE.RMSG = dsPRICEBOL.PMSG;
    endSl;


    //if sqlcode = 0;
    for NUMCPO = 31 by 6 to 187;
      if %subst(dsRSYPRICE.RSER:NUMCPO:3) = '055';
        POS_DES = %int(%subst(dsRSYPRICE.RSER:NUMCPO + 3:3)) + 2;
        POS_HAS = %int(%subst(dsRSYPRICE.RSER:NUMCPO + 9:3)) - POS_DES;
        if %subst(dsRSYPRICE.RMSG:POS_DES:1) = x'02';
          POS_DES += 3;
          POS_HAS -= 3;
        endif;
        dsDIN1.DP55 = %subst(dsRSYPRICE.RMSG:POS_DES:POS_HAS);
        CHGDTO  = POS_HAS * 10;
        dsDIN1.DPLLV55 = %SubSt(%editc(CHGDTO:'X'):7:2);
        leave;
      endif;
    endfor;
    //endif;
      return *On;
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
  // Acumula_Gastos por producto
  //-----------------------------------------------------------------
  dcl-proc Acumula_Gastos_producto;
    dcl-pi *n Ind;
      P_Impor   Packed(14:3) const;
      p_Product Zoned(3);
    end-pi;

    Dcl-s WIndx    Zoned(3);
    Dcl-s WImp_Gastos Zoned(14:3);

    // La tasa de Intercambio esta fijo en 0.04 (deberia haber tabla)
    WImp_Gastos = P_Impor * 0.04;
    // Calculo del importe minimo a cobra si Tarjeta DINERS
    If dsBLODIAN.BPAIS = 999;
      If %abs(WImp_Gastos) < 2.40;
        If WImp_Gastos < 0;
          WImp_Gastos = -2.40;
        Else;
          WImp_Gastos = 2.40;
        EndIf;
      EndIf;
    EndIf;

    WIndx = %lookup(p_Product: Acumulador_Gastos(*).Cod_prod:1);
    if WIndx > 0;
      Acumulador_Gastos(WIndx).Total += WImp_Gastos;
    else;
      WInd_Gtos += 1;
      Acumulador_Gastos(WInd_Gtos).Cod_prod = p_Product;
      Acumulador_Gastos(WInd_Gtos).Total    = WImp_Gastos;
    endif;

    Return *On;

  end-proc;
  //---------------------------------------------------------------
  // Crear el fichero temporal del detalle de la evidencia
  //---------------------------------------------------------------
  dcl-proc Crear_Temporal_Detalle_Evidencia;

    dcl-pi *n ind;
      dsDetevi likeds(dsDeteviTempl);
    end-pi;

    dcl-s marca char(1) inz(CREAR_TEMPORAL);

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
      marca
      :dsDetevi
      :sqlError
      :sqlMensaje
      :WNomDetPar);
      V_observacion = 'NACI05NEW: Error al crear temporal de Evidencias';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
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
      Esp01      Char(1);
      Tarjeta    Char(19);
      Esp02      Char(2);
      CodPais    Zoned(3);
      Esp03      Char(2);
      NomTarjeta Char(30);
      Esp04      Char(2);
      CodOpe     Char(1);
      Esp05      Char(2);
      Importe    Char(14);
      Esp06      Char(2);
      CodProd    Zoned(3);
      Esp07      Char(5);
      CodCajero  Zoned(3);
    End-ds;

    marca = GRABAR_TEMPORAL;

    dsDetalleEvi.Tarjeta = dsBLODIAN.BTARJE;
    dsDetalleEvi.CodPais = dsBLODIAN.BPAIS;
    dsDetalleEvi.NomTarjeta = WNOM_TARJETA;
    WImpdec = dsBLODIAN.BIMPOR/100;
    Evalr dsDetalleEvi.Importe = %Char(WImpdec);
    dsDetalleEvi.CodProd = WCod_Prod;
    dsDetalleEvi.CodCajero = dsBLODIAN.BACTIV;

    dsDetevi.lineaTexto = dsDetalleEvi;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
      marca
      :dsDetevi
      :sqlError
      :sqlMensaje
      :WNomDetPar);
      V_observacion = 'NACI05NEW: Error al registro de Evidencia en el temporal';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
      Return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Inserta registro de Cabecera en el Detalle
  //-----------------------------------------------------------------
  dcl-proc Inserta_Cabecera_detalle;

    dcl-s marca char(1);
    Dcl-s I         Zoned(3);

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto =
          'NACI05NEW EVIDENCIA CONTABLE AL ' +
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
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Cabecera_detalle';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
          '  TARJETA             PAIS  NOMBRE TARJETA' +
          '                          IMPORTE   PROD    CAJERO';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
      marca
      :dsDetevi
      :sqlError
      :sqlMensaje
      :WNomDetPar);
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Cabecera_detalle';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
          '---------------------------------------------'+
          '--------------------------------------------------';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
      marca
      :dsDetevi
      :sqlError
      :sqlMensaje
      :WNomDetPar);
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Cabecera_detalle';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
      return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Totales de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Totales_Evi;

    dcl-s marca char(1);
    Dcl-s I         Zoned(3);
    Dcl-s WNomProd  Char(30);

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
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
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
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
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
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
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
        V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
        Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
        Leave;
      EndIf;
    EndFor;
    //----------------------------------------------------

    dsDetevi.lineaTexto = '';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
      marca
      :dsDetevi
      :sqlError
      :sqlMensaje
      :WNomDetPar);
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
          'Codigo Producto'             +
          '  Gastos Cajero            ' +
          '         Total' ;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
      marca
      :dsDetevi
      :sqlError
      :sqlMensaje
      :WNomDetPar);
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
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
      V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
      return;
    EndIf;

      // Ordenamiento del Arreglo por Codigo de Producto
    sorta %subarr(Acumulador_Gastos(*).Cod_prod : 1 : WInd_Gtos);

    For I=1 to WInd_Gtos;

      WCod_Prod = Acumulador_Gastos(I).Cod_prod;
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
            %Editc(Acumulador_Gastos(I).Cod_prod:'X') +
            ' - ' + WNomProd + '    '    +
            %Editc(%Dec(Acumulador_Gastos(I).Total:16:2):'2');
      WnumLinea += 1;
      dsDetevi.numeroLinea = numeroLinea;

      if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
        marca
        :dsDetevi
        :sqlError
        :sqlMensaje
        :WNomDetPar);
        V_observacion = 'NACI05NEW: Error al registro de Evidencia Inserta_Totales_Evi';
        Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
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
      V_observacion = 'NACI05NEW: Error al grabar temporal en el DETEVI';
      Diagnostico(PROCEDURENAME:V_observacion:V_tipo_error);
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
          'NACI05NEW EVIDENCIA CONTABLE AL ' +
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
  //-----------------------------------------------------------------------------
  // Genera Registros en DIN1
  //-----------------------------------------------------------------------------
  dcl-proc Genera_Registros_DIN1;

    Dcl-s WGKEY  Zoned(9:0);

    dsDIN1.DIDENT = 'D';
    dsDIN1.DRECEX = 0;
    dsDIN1.DZONA  = ' ';
    dsDIN1.DACTIV = dsESTA1.EACTPR;
    dsDIN1.DLIBR2 = dsBLODIAN.BLIBR2;
    dsDIN1.DNESTA = dsBLODIAN.BNUMES;
    dsDIN1.DDIGIT = dsBLODIAN.BDIGIT;
    dsDIN1.DLIBR1 = dsBLODIAN.BDUPLI;
    dsDIN1.DPS2D1 = dsBLODIAN.BCODRE;
    dsDIN1.DNUMSO = dsBLODIAN.BTARJE;
    dsDIN1.DADICI = dsBLODIAN.BADICI;
    Select;
      When dsESTA1.EACTPR = 74;
        dsDIN1.DORDEN = '4';
      When dsESTA1.EACTPR = 99;
        dsDIN1.DORDEN = '5';
      Other;
        dsDIN1.DORDEN = '3';
    EndSl;
    dsDIN1.DIMPOR = dsBLODIAN.BEUROS;
    dsDIN1.DLIBR3 = '';
    dsDIN1.DFECON = dsBLODIAN.BFECON;
    dsDIN1.DDICON = dsBLODIAN.BDICON;
    dsDIN1.DNUTRA = %Dec(%SubSt(%Editc(dsBLODIAN.BREFER:'X'):1:3):3:0);
    dsDIN1.DNUREG = dsBLODIAN.BNUREG;
    dsDIN1.DZIM   = 0;
    dsDIN1.DLIBR4 = '';
    dsDIN1.DNUMRE = %Dec(%SubSt(dsBLODIAN.BTARJE: 3: 8): 8: 0);
    dsDIN1.DPTLLA = dsBLODIAN.BPANTA;
    dsDIN1.DRENTO = dsESTA1.EDESCU;
    dsDIN1.DCODIG = dsBLODIAN.BIRREG;
    dsDIN1.DPAIS  = dsBLODIAN.BPAIS;
    dsDIN1.DNACI4 = ' ';
    dsDIN1.DNUREF = dsBLODIAN.BREFER;
    dsDIN1.DACTIN = 830;
    dsDIN1.DESTAB = dsESTA1.ENOMBR;
    dsDIN1.DLIBR5 = ' ';
    dsDIN1.DEUROS = dsBLODIAN.BIMPOR/100;
    dsDIN1.DRENPE = dsBLODIAN.BIMPOR * dsESTA1.EDESCU;
    dsDIN1.DMONED = dsBLODIAN.BMONED;

    // Daos de Autorizacion
    // dsDIN1.DNUMAU =
    // dsDIN1.DP23
    // dsDIN1.DP55
    // dsDIN1.DPLLV55
    // dsDIN1.DP22
    // dsDIN1.DP39

    exec sql
      insert into DIN1
      values(:dsDIN1);

    if sqlcode < 0;
      observacionSql = 'NACI05NEW Error alta en DIN1';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    Endif;

    If dsESTA1.EACTPR = 99;
      dsDIN1.DACTIN = 832;
      // La tasa de Intercambio esta fijo en 0.04 (deberia haber tabla)
      dsDIN1.DEUROS = (dsBLODIAN.BIMPOR/100) * 0.04;

      // Determina la referencia en el DESCRFAC
      Exec SQL
         Select
          GKEY, GPAIS, GLIBR1, GPURGE, GREFIN,
          GLIN1, GLIN2, GNOMES, GLOCES, GDESCH,
          GNUMSO, GCINTA, GREFUS, GISOMA, GLIN3, GACTIN
         Into :dsDESCRFAC
         From DESCRFAC
        Where GKEY = :dsBLODIAN.BREFER;

      Select;
        When SqlCode = 100;
          WGKEY = dsBLODIAN.BREFER + 100000;
        When Sqlcode < 0;
          observacionSql = 'NACI05NEW Error en lectura en DESCRFAC';
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
        When SqlCode = 0;
          Exec SQL
            Select
              GKEY, GPAIS, GLIBR1, GPURGE, GREFIN,
              GLIN1, GLIN2, GNOMES, GLOCES, GDESCH,
              GNUMSO, GCINTA, GREFUS, GISOMA, GLIN3, GACTIN
            Into :dsDESCRFAC
            From DESCRFAC
            Where GKEY = :dsBLODIAN.BREFER + 1;

          If SqlCode = 0;
            Exec SQL
               Select
                GKEY, GPAIS, GLIBR1, GPURGE, GREFIN,
                GLIN1, GLIN2, GNOMES, GLOCES, GDESCH,
                GNUMSO, GCINTA, GREFUS, GISOMA, GLIN3, GACTIN
              Into :dsDESCRFAC
              From DESCRFAC
              Where GKEY = :dsBLODIAN.BREFER;

            WGKEY = dsBLODIAN.BREFER;
            ULTKEY(WGKEY);
            dsDESCRFAC.GKEY = WGKEY + 1;
            dsDESCRFAC.GNOMES = dsESTA1.ENOMBR;
            dsDESCRFAC.GLOCES = dsESTA1.ELOCPV;
            dsDESCRFAC.GACTIN = 832;

            // Generacion de Registro en el DESCRFAC
            exec sql
              insert into DESCRFAC
              values(:dsDESCRFAC);

            if sqlcode < 0;
              observacionSql = 'NACI05NEW Error alta en DESCRFAC';
              Clear Nivel_Alerta;
              Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
            Endif;

            // Generacion de Registro en el DESCRCAJ
            exec sql
              insert into DESCRCAJ
              values(:dsDESCRFAC);

            if sqlcode < 0;
              observacionSql = 'NACI05NEW Error alta en DESCRCAJ';
              Clear Nivel_Alerta;
              Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
            Endif;

            exec sql
               select
                AXCREF, AXCFEC, AXCSOC, AXCPAI, AXCREC,
                SCGMT, SCDAT, LCTIM, LCDAT, ATMID
             into :dsOPATMXC
             from FICHEROS.OPATMXC
            where
              AXCREF = :WGKEY
              and AXCSOC = Dec(SubString(:dsBLODIAN.BTARJE, 3, 8), 8, 0)
              and AXCFEC = :dsBLODIAN.BFECON;

            if sqlcode < 0;
              observacionSql = 'NACI05NEW Error en lectura en OPATMXC';
              Clear Nivel_Alerta;
              Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
            Endif;

            If SqlCode = 100;
              // Generacion de Registro en el OPATMXC
              exec sql
                insert into OPATMXCI05
                values(:dsOPATMXC);

              if sqlcode < 0;
                observacionSql = 'NACI05NEW Error alta en DESCRCAJ';
                Clear Nivel_Alerta;
                Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
              Endif;
            Endif;
          EndIf;
      EndSl;

      dsDIN1.DNUREF = WGKEY;
      exec sql
        insert into DIN1
        values(:dsDIN1);

      if sqlcode < 0;
        observacionSql = 'NACI05NEW Error alta en DIN1 - Gastos';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      Endif;
    EndIf;


  End-Proc;