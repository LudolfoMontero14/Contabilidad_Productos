**FREE
// ****************************************************************************
// FSBALAMC
//   Programa que crea BSMC, CONTROFSMC, RECIBOSMC
//
//   BSMC: Detalle Movimiento Extractos. Incorporando cuotras de entrada y
//         vencimiento
//   CONTROFSMC: Control de Facturación.
//   RECIBOSMC: Recibos Bancarios.
// ****************************************************************************
// PROGRAMADOR: JMMM
// FECHA: 11/10/2023
// ****************************************************************************
//         MODIFICACIONES:
// PROGRAMADOR: Ludolfo Montero
//
// ****************************************************************************
//
// COMPILACION: 14 con DBGVIEW = *LIST
// ****************************************************************************
ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
  datedit(*DMY/) decedit('0,')
  bnddir('UTILITIES/UTILITIES':'EXPLOTA/CALDIG')
  dftactgrp(*no) actgrp(*new) main(main);

dcl-pr CALDIA1 extPgm('CALDIA1');
  fecha packed(8:0);
  dias packed(3:0);
  formatoInput char(4);
  formatoOut char(4);
end-pr;

dcl-pr ACUTOTN extPgm('ACUTOTN');
  *N      Char(6);
  *N      Char(30);
  *N      Packed(13:0);
  *N      Packed( 6:0);
end-pr;

/copy EXPLOTA/QRPGLESRC,SOCIOSRV_H    // Utilidades Socio
/copy EXPLOTA/QRPGLESRC,MCARD_H       // dsBlomastgerTpl
/copy UTILITIES/QRPGLESRC,PSDSCP      // psds
/copy UTILITIES/QRPGLESRC,P_SDS       // SDS
/copy UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL
/COPY EXPLOTA/QRPGLESRC,DSNUMSOCI
/copy EXPLOTA/QRPGLESRC,UTILSCONTH    // Utilidades contabilidad

dcl-ds Acumulador Qualified dim(50) Inz;
  Cod_prod  Zoned(3:0);
  Total    Packed(9:0);
end-ds;

dcl-ds dsFechaProceso likeds(dsFechaProcesoTempl) inz;

dcl-s WsaldoFa      zoned(9:0) inz;
dcl-s WTot_FAPA     zoned(10:0);
dcl-s WTot_CUOTAVTO zoned(10:0);
dcl-s WCUOTA_SOC    zoned(10:0);
Dcl-s WInd          Zoned(5);

dcl-s NumApun       char(6);
Dcl-s WDSPLY        char(40);

dcl-s fechaSistema TimeStamp;

dcl-s CabeceraEvid Ind;

dcl-c ADEUDO    const('045679JKLMW');
dcl-c ABONO     const('123ABCD');
dcl-c ES_PA     const('457');

// ****************************************************************************
// PROCESO PRINCIPAL
// ****************************************************************************
dcl-proc main;

  dcl-pi *n;
    P_NumApun   Char(6);
  end-pi;

  dcl-ds dsSocio likeDs(dsSocioTpl) inz;
  dcl-ds dsFapa88MC  likeDS(dsFapa88MCTempl) inz;

  dcl-s numBasico char(10) inz;
  dcl-s pantoken char(14) inz;
  dcl-s ciclo char(4) inz;

  dcl-s tarjeta zoned(14:0) inz;
  dcl-s wNureal zoned(8:0) inz(-1);
  dcl-s TSaldo   zoned(9:0) inz;
  dcl-s TSaldoPa zoned(9:0) inz;
  dcl-s TNotas zoned(5:0) inz;

  dcl-s GeneraRecibo Ind;

  Exec Sql
    SET OPTION Commit = *none,
              CloSqlCsr = *endmod,
              AlwCpyDta = *yes;

  dsFechaProceso = Obtener_Fecha_Proceso();

  fechaSistema = %timestamp();
  NumApun = Asignar_Numero_Apunte(fechaSistema);
  P_NumApun = NumApun;

  Reset Acumulador;

  // Todas las tarjetas de MSOCIO88
  Exec Sql declare C1 Cursor For
    SELECT SNUSO1, NUREAL, SNUSO2, SCUOTE, SNOMBR, SDOMIC, CODPOS, PROTG1,
      SLOCAL, SAPEPM, PROTG2, ZONA, SCARNE, SEXTTE, SLIBR0, SEXENT, SLIBR1,
      SFSTAT, SNOMEM, SNOMBA, SDOMBA, SLOCBA, SZOBAN, SNCTAC, SMCTAC, SFPAGO,
      SCONSO, SCONPM, SNOMPM, SDUPEX, SOFESE, SMESCU, SCOBHA, SCLTLF, STELEF,
      STVPER, SMYGAS, SFMGAS, SCLDNI, SCONBA, SNIDEM, SPLAST, SCODPO, SCODVI,
      SMOTBA, NBANCO, SNOREN, SOPCAM, SGTEXT, SLIBR2, SNOATM, SSEXO, SOFEPM,
      SACREC, SMOCTA, SEXNIF, SF1STA, SCLPRO, SCONCU, SDIAPA, SSUBHA, SLIBR3,
      SFREC1, SIMPR1, SLIBR4, SFREC2, SIMPR2, SLIBR5, SFREC3, SIMPR3, SLIBR6,
      SFREC4, SIMPR4, SCODEV, SFDEVO, SNOGTS, SLICRE, SACREB, SLIBR7, SCORDV,
      SREANT, SACDNI, SMESRE, SDIAPR, SCLIEX, SNUIDE, SVARTR, SCODNT, "STATUS",
      SNNIF, SCATEM, SSALAN, SRECAU, SHNORE, SDEVIM, SDNODI, SOPSER, SIMNSE,
      SOPINT, SIMINT, SDIFAL, SDIRES, SOPRPM, SIMPPM, SIMPAP, SOPNCO, SIMNCO,
      SANACI, SPREFI, SCOPER, "SAÑVPM", SVIGPM, "SVIPMÑ", SPODER, S@, SAUSEO,
      SAUSER, SAUCAO, SAUCAL, SINFLE, SIN10C, SINFFA, SIMPPA, SACC3, SREGEM,
      SSEGTA, SLIBR8, SAPECA, SAUTIN, SAUTOT, SAUINO, SAUOTO, SPORCE, SMOFAC,
      STIPRE, SPORAN, SPENOF, SPIN, SMUSCA, SLIBR9, SFNCAJ, SBCHRE, SINGRE,
      SALTPM, SVIGTR, SFACRB, SCODPR
    FROM MSOCIO88MC
    WHERE (SDIAPR = :dsFechaProceso.diaProceso or SMOFAC = 'X')
    ORDER BY NUREAL;

  Exec Sql Open C1;
  Exec Sql Fetch From C1 into :dsSocio;
  dow sqlStt = '00000';
    numBasico = %editc(dsSocio.snuso1:'X') + %editc(dsSocio.nureal:'X');
    pantoken = %editc(dsSocio.nureal:'X') + %editc(dsSocio.snuso2:'X');
    ciclo = %subst(%editc(dsSocio.nureal:'X'):1:4);

    // Todas las operaciones FAPA88 para esa tarjeta
    Exec Sql Declare C2 Cursor For
      SELECT FPDAT1, FPNUES, FPDAT2, FPTIRE, FPNUSO, FPDAT3, FPIMPO, FPDAT4, FPFECO,
            Case
              WHEN hex(FPDICO) = '4040' THEN 0 ELSE FPDICO end,
            DATOS2, FCODGE, FNUCR2, FCADIN, FPUREN, FSUREN, FBIREN, FOMMSS,
            FNOPGM,
            Case
              WHEN hex(FNFICM) = '404040404040404040' THEN 0 ELSE FNFICM end,
            FNTRAM,
            Case
              WHEN hex(FREFOR) = '404040404040404040' THEN 0 ELSE FREFOR end,
            Case
              WHEN hex(FSAUNA) = '4040404040404040'   THEN 0 ELSE FSAUNA end,
            FNTRMI,
            Case
              WHEN hex(FFFAMI) = '4040404040404040'   THEN 0 ELSE FFFAMI end,
            FENVSG, FESTAD,
            FCOMI0, FAMPLI
      FROM FAPA88MC
      WHERE FPNUSO = :dsSocio.nureal;

    TSaldo   = 0;
    TSaldoPa = 0;
    TNotas   = 0;

    Exec Sql Open C2;
    Exec Sql Fetch From C2 into :dsFapa88MC;
    dow sqlStt = '00000';

      Genera_Registro_Fact_BS(dsSocio:dsFapa88MC:TSaldo:TSaldoPa);
      TNotas += 1;

      Exec Sql Fetch From C2 into :dsFapa88MC;

    enddo;

    Exec Sql Close C2;

    Balance_Fact_Socios_CONTROFS(dsSocio:TSaldo:TNotas:TSaldoPa);
    If TSaldo<>0;
      Actualiza_MSOCIO(dsSocio:TSaldo);
      WTot_FAPA += TSaldo;
    EndIf;

    Exec Sql Fetch From C1 into :dsSocio;
  enddo;

  Exec Sql Close C1;

  // Genera_Asiento_Cuotas(NumApun);
  Genera_Contabilidad();

  Genera_Totales();

  If WTot_CUOTAVTO<>0;
    Inserta_Totales_Evi();
  EndIf;

  *inlr = *on;


end-proc;

// --------------------------------------------
// Obtener fecha del proceso
// --------------------------------------------
dcl-proc Obtener_Fecha_Proceso;
  dcl-pi *n likeDs(dsFechaProcesoTempl);
  end-pi;

  dcl-ds dsFechaProceso likeds(dsFechaProcesoTempl) inz;

  Exec Sql
  SELECT SUBSTR(CRFS01, 3, 8), SUBSTR(CRFS01, 50, 8)
    into :dsFechaProceso
  FROM CRFS01;

  return dsFechaProceso;

end-proc;
  // ------------------------------------------
  // Guardar balance de los socios (BS)
  // ------------------------------------------
  dcl-proc Genera_Registro_Fact_BS;

    dcl-pi *n;
      dsSocio likeDs(dsSocioTpl);
      dsFapa88MC likeDS(dsFapa88MCTempl);
      TSaldo     Zoned(9:0);
      TSaldoPa   Zoned(9:0);
    end-pi;

    dcl-ds dsBsMC likeDS(dsBSMCTempl) inz;
    dcl-ds dsDatos2 likeDS(dsDatos2Templ) inz;
    dcl-ds dsL5 likeDS(dsL5Templ) inz;

    dcl-s wpenofa   Zoned(9:0) Inz;
    Dcl-s Solo_PA      Ind Inz;

    dsDatos2.datos2 = dsFapa88MC.datos2;

    dsBsMC.bcodre = 'B';

    // fpdat1 contiene todo esto
    dsBsMC.bcodre = %subst(dsFapa88MC.fpdat1:1:2);
    dsBsMC.l7 = %subst(dsFapa88MC.fpdat1:3:3);
    Monitor;
      dsBsMC.bactiv = %dec(%subst(dsFapa88MC.fpdat1:6:2):2:0);
    on-error;
      dsBsMC.bactiv = 0;
    endmon;
    dsBsMC.bclapa = %subst(dsFapa88MC.fpdat1:8:1);

    dsBsMC.bnumes = dsFapa88MC.fpnues;

    // fpdat2 contiene todo esto
    Monitor;
      dsBsMC.bdigit = %dec(%subst(dsFapa88MC.fpdat2:1:1):1:0);
    on-error;
      dsBsMC.bdigit = 0;
    endmon;
    dsBsMC.bdupli = %subst(dsFapa88MC.fpdat2:2:1);

    dsBsMC.bcodmo = dsFapa88MC.fptire;
    dsBsMC.bnumre = dsFapa88MC.fpnuso;
    dsBsMC.l1 = dsFapa88MC.fpdat3;
    dsBsMC.bimpor = dsFapa88MC.fpimpo;

    // fpdat4 contiene todo esto
    dsBsMC.l8 = %subst(dsFapa88MC.fpdat4:1:3);
    dsBsMC.l2 = %subst(dsFapa88MC.fpdat4:4:2);
    dsBsMC.l6 = %subst(dsFapa88MC.fpdat4:6:1);

    dsBsMC.bfecon = dsFapa88MC.fpfeco;
    dsBsMC.bdicon = dsFapa88MC.fpdico;
    dsBsMC.l3 = %subst(dsDatos2.datos2:1:1);


    // TODO:OJO REVISAR TIPO DE REGISTRO 2 ,0,7
    dsBsMC.lnumco = 0;

    If dsFapa88MC.fptire <> '0' AND
     dsFapa88MC.fptire <> '2' AND
     dsFapa88MC.fptire <> '7';

      if %subst(dsDatos2.datos2:2:2) = *blanks;
        dsBsMC.lnumco = dsDatos2.numAutorizacion;
      else;
        Monitor;
          dsBsMC.lnumco = %dec(%subst(dsDatos2.datos2:2:2) +
                        %editc(dsDatos2.numAutorizacion:'X'):5:0);
        on-error;
          dsBsMC.lnumco = 0;
        endmon;
      endif;
    Endif;

    Monitor;
      dsBsMC.bnupai = %editc(dsDatos2.numPais:'X');
    on-error;
      dsBsMC.bnupai = '000';
    endmon;
    // a l4 van todas esas posiciones de datos2
    dsBsMC.l4 = %subst(dsDatos2.datos2:10:20);

    if %subst(dsDatos2.datos2:30:1) = *blanks;
      dsBsMC.conpm = 0;
    else;
      Monitor;
        dsBsMC.conpm = %dec(%subst(dsDatos2.datos2:30:1):1:0);
      on-error;
        dsBsMC.conpm = 0;
      endmon;
    endif;

    // Para que no falle al pasar a L5
    if dsDatos2.fncam = *blanks;
      dsDatos2.fncam = *all'0';
    endif;
    dsL5.l5 = %subst(dsDatos2.datos2:31:52);

    dsBsMC.bdiapr = dsFechaProceso.diafacturacion; //ojo
    dsBsMC.bte130 = 99999999;
    dsBsMC.bregem = dsSocio.SREGEM;

    if dsSocio.SBCHRE > 0 and dsSocio.SCOBHA <> 'Z';
      dsBsMC.bbchre = dsSocio.SBCHRE;
    else;
      dsBsMC.bbchre = 0;
    endif;

    dsBsMC.l5 = dsL5.l5;

    Monitor;
      dsBsMC.beuros = dsDatos2.ptspts;
    on-error;
      dsBsMC.beuros = 0;
    endmon;

    dsBsMC.bmoned = dsDatos2.monent;
    Monitor;
      dsBsMC.bseaco = %dec(dsDatos2.pseage:5:0);
    on-error;
      dsBsMC.bseaco = 0;
    endmon;
    dsBsMC.boexco = dsDatos2.pagrup;

    Monitor;
      dsBsMC.bnubas = dsDatos2.pnubac;
    on-error;
      dsBsMC.bnubas  = 0;
    endmon;

    dsBsMC.bcorel = dsDatos2.ptirel;
    Monitor;
      dsBsMC.bresto = %dec(dsDatos2.pnbres:4:0);
    on-error;
      dsBsMC.bresto = 0;
    endmon;
    Monitor;
      dsBsMC.bentdi = %dec(dsDatos2.fendin:6:0);
    on-error;
      dsBsMC.bentdi = 0;
    endmon;
    dsBsMC.bprofa = dsFechaProceso.fechaProcesoFacturacion;
    dsBsMC.bfreal = dsFechaProceso.mesAnioProcesoFacturacion; //ojo
    Monitor;
      dsBsMC.bagenc = %dec(%subst(dsDatos2.pdatco:1:4):4:0);
    on-error;
      dsBsMC.bagenc = 0;
    endmon;
    dsBsMC.bcruce = %subst(dsDatos2.pdatco:5:15);
    dsBsMC.btipop = %subst(dsDatos2.pdatco:20:1);
    dsBsMC.brenfe = %subst(dsDatos2.pdatco:21:5);
    dsBsMC.breemb = %subst(dsDatos2.pdatco:26:10);

    dsBsMC.bcodge = dsFapa88MC.fcodge;
    dsBsMC.bnucr2 = dsFapa88MC.fnucr2;
    dsBsMC.bcadin = dsFapa88MC.fcadin;
    dsBsMC.bpuren = dsFapa88MC.fpuren;
    dsBsMC.bsuren = dsFapa88MC.fsuren;
    dsBsMC.bbiren = dsFapa88MC.fbiren;
    dsBsMC.bommss = dsFapa88MC.fommss;
    dsBsMC.bnopgm = dsFapa88MC.fnopgm;
    dsBsMC.bnficm = dsFapa88MC.fnficm;
    dsBsMC.bntram = dsFapa88MC.fntram;
    dsBsMC.brefor = dsFapa88MC.frefor;
    dsBsMC.bsauna = dsFapa88MC.fsauna;
    dsBsMC.bntrmi = dsFapa88MC.fntrmi;
    dsBsMC.bffami = dsFapa88MC.fffami;
    dsBsMC.benvsg = dsFapa88MC.fenvsg;
    dsBsMC.bestad = dsFapa88MC.festad;
    dsBsMC.bcomi0 = dsFapa88MC.fcomi0;
    dsBsMC.bampli = dsFapa88MC.fampli;

    Exec Sql
    INSERT INTO BSMC (BCODRE, L7, BACTIV, BCLAPA, BNUMES, BDIGIT, BDUPLI,
        BCODMO, BNUMRE, L1, BIMPOR, L8, L2, L6, BFECON, BDICON, L3, LNUMCO, BNUPAI,
        L4, CONPM, L5, BDIAPR, BTE130, BREGEM, BBCHRE, BEUROS, BMONED, BSEACO,
        BOEXCO, BNUBAS, BCOREL, BRESTO, BENTDI, BPROFA, BFREAL, BAGENC, BCRUCE,
        BTIPOP, BRENFE, BREEMB, BCODGE, BNUCR2, BCADIN, BLIN1, BLIN2, BLIN3, BPUREN,
        BSUREN, BBIREN, BOMMSS, BNOPGM, BNFICM, BNTRAM, BREFOR, BSAUNA, BNTRMI,
        BFFAMI, BENVSG, BESTAD, BCOMI0, BAMPLI)
      VALUES(:dsBsMC);

    If Sqlcode < 0;
      observacionSql = 'Error al insertar en el BSMC';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;

    monitor;
      wpenofa = dsDatos2.penofa;
    on-error;
      wpenofa = 0;
    endmon;

    // WsaldoFa += wpenofa;

    Solo_PA = Determina_Si_Suma_PA(dsFapa88MC.fptire:dsDatos2.numAutorizacion);

    if Es_Adeudo(dsFapa88MC.fptire);
      TSaldo +=  dsFapa88MC.fpimpo;

      If Solo_PA;
        TSaldoPa +=  dsFapa88MC.fpimpo;
      EndIf;
    else;
      TSaldo += -dsFapa88MC.fpimpo;
      If Solo_PA;
        TSaldoPa += -dsFapa88MC.fpimpo;
      Endif;
    endif;

    if dsFapa88MC.fptire = '0';
      TSaldo += wpenofa;
    endif;

    // WTot_FAPA += TSaldo;

  end-proc;

  // -----------------------------------------------------------------------------
  // Guardar en el fichero de control de facturación para control de extractos
  //
  // DISEÑO DEL REGISTRO
  //
  //  2- 9     NUMERO REAL DE SOCIO
  // 10-10     CUENTA ANUAL -A-, SOPORTE MAGNETICO -C-
  // 11-11     CONDICION DUPLICADOS
  // 12-16 -P- TOTAL SALDO SOCIOS
  // 19-20     PROVINCIA
  // 21-29     TOTAL MOVIMIENTO MES
  // 30-30     ACCION DE RECOBRO
  // 31-31     -1- CONDICION DE SALDO ATRASADO
  // 32-32     -1- SALDO CERO, -2- SALDO ACREEDOR
  // 33-35     NUMERO DE NOTAS
  // 36-36     -1- NO SE HACE EXTRACTO
  // 37-37     LIBRES
  // 38-42 -P- FECHA DEL PAGO -DDMMAAAA-
  // 43-50     TARJ. -TE- ASOC-110
  // 51-56     TARJ. -TE- REG.EMPRESA
  // 57-58     PERIODO TARJETA VIRTUAL
  // 59-59     PLAZOS  TARJETA VIRTUAL
  // 60-69     Nº.TARJETA TITULAR EXTRACTO UNIFICADO
  // -----------------------------------------------------------------------------
  dcl-proc Balance_Fact_Socios_CONTROFS;

    dcl-pi *n;
      dsSocio      likeDs(dsSocioTpl);
      TSaldo       Zoned(9:0);
      TNotas       Zoned(5:0);
      TSaldoPa     Zoned(9:0);
    end-pi;

    dcl-ds dsControFSMC likeDs(dsControFSMCTempl) inz;

    dcl-s GenRecibo ind;
    dcl-s WCuota zoned(6:0) inz;
    dcl-s WCuota_Fin zoned(6:0) inz;
    dcl-s WCuota_Bill zoned(6:0) inz;
    dcl-s Wtte130 zoned(8:0) Inz;

    dcl-s Tipo char(3)inz('PGM');

    dsControFSMC.txc = 'C';
    dsControFSMC.tnumso = dsSocio.nureal;

    if dsSocio.smofac = 'A';
      dsControFSMC.tanual = dsSocio.smofac;
    else;
      dsControFSMC.tanual = *blanks;
    endif;

    dsControFSMC.tdupli = *blanks;

    dsControFSMC.tlibr1 = '  ' +
           %subst(%editc(dsSocio.sclpro:'X'):1:1);
    dsControFSMC.tlibr2 =
           %subst(%editc(dsSocio.sclpro:'X'):2:1);

    dsControFSMC.tacrec = Obtener_Codigo_Recobro(dsSocio:dsControFSMC.tsalso:WsaldoFa);
    dsControFSMC.tconfa = Obtener_Condicion_Saldo_Atrasado(WsaldoFa);
    // dsControFSMC.tsacer = Obtener_Codigo_Saldo_Cero(dsControFSMC.tsalso);
    dsControFSMC.tsacer = Obtener_Codigo_Saldo_Cero(TSaldo);
    // dsControFSMC.tnotas = Obtener_Numero_Notas(dsFapa88MC.fptire);
    dsControFSMC.tnoext = No_Hace_Extracto(dsControFSMC.tsalso:dsSocio.status);
    dsControFSMC.tlibr3 = *blanks;
    dsControFSMC.tfepag = Obtener_Fecha_Pago(dsSocio.sdiapa:dsSocio.sdiapr:dsSocio.smofac);

    If Determina_Codigo_Grupo(dsSocio:Wtte130);
      dsControFSMC.tte130 = Wtte130;
    Else;
      dsControFSMC.tte130 = 99999999;
    Endif;
    dsControFSMC.tregem = dsSocio.sregem;

    Control_Virtuales(dsSocio.stvper:dsSocio.splast:dsSocio.sdupex
      :dsControFSMC.tpervi:dsControFSMC.tplavi);

    // TODO: No hay extracto unificado
    dsControFSMC.titueu = 0;

    dsControFSMC.tsvieu = 0;
    // 01.07.2025 se aplica control por error al superar las 999 operaciones por socio
    // el campo Tnota es de 3,0
    If TNotas <= 999;
       dsControFSMC.TNotas = TNotas;
    Else ;
     // TODO: Amplicar campo en la tabla correspondientes
      dsControFSMC.TNotas = 999;  // No puede ser mayor de 999
      observacionSql = 'FSBALAMC:Tnotas superado se asigna 999, Numero real: ' +
                        %Char(dsSocio.nureal) +
                       ' Tnotas : '+ %char(TNotas);
      Diagnostico(PROCEDURENAME:observacionSql:Tipo);


    Endif;

    // If hay que generar otros cobros - Cuota de Mantenimiento  en el BS
    WCUOTA_SOC = 0;
    WCuota = Genera_Cuota_Mtto(dsSocio);
    If WCuota <> 0;
      If Not CabeceraEvid;
        Inserta_Cebecera_Evi();
        CabeceraEvid = *on;
      Endif;
      Inserta_Detalle_Evi(dsSocio:dsControFSMC:WCuota);
      Inserta_Reg_CONCPVF(dsSocio:WCuota);
      // dsControFSMC.tsalso += WCuota;
      TSaldo += WCuota;
      // Acumula_importe_Prod(dsSocio:WCuota);
      If Not Acumula_importe(dsSocio.nureal:WCuota:WInd);

      Endif;
      WCUOTA_SOC     = WCuota;
      WTot_CUOTAVTO += WCuota;
    EndIf;

    // If hay que generar otros cobros - Financiamiento          en el BS
    // WCuota_Fin = Genera_Cuota_Financ(dsSocio);
    // If WCuota_Fin <> 0;
    //    If Not CabeceraEvid;
    //       Inserta_Cebecera_Evi();
    //       CabeceraEvid = *on;
    //    Endif;
    //    Inserta_Detalle_Evi(dsSocio:dsControFSMC:WCuota_Fin);
    //    //dsControFSMC.tsalso += WCuota_Fin;
    //    TSaldo += WCuota_Fin;
    //    //Acumula_importe_Prod(dsSocio:WCuota_Fin);
    //    //If Not Acumula_importe(dsSocio.nureal:WCuota:WInd);

    //    //Endif;
    //    WTot_CUOTAVTO += WCuota_Fin;
    // EndIf;

    // If hay que generar otros cobros - Cuota de BILLHOP        en el BS
    // WCuota_Bill = Genera_Cuota_BillHop(dsSocio:dsControFSMC.tsalso);
    // If WCuota_Bill <> 0;
    //    If Not CabeceraEvid;
    //       Inserta_Cebecera_Evi();
    //       CabeceraEvid = *on;
    //    Endif;
    //    Inserta_Detalle_Evi(dsSocio:dsControFSMC:WCuota_Bill);
    //    //dsControFSMC.tsalso += WCuota_Bill;
    //    TSaldo += WCuota_Bill;
    //    //Acumula_importe_Prod(dsSocio:WCuota_Bill);
    //    //If Not Acumula_importe(dsSocio.nureal:WCuota:WInd);

    //    //Endif;
    //    WTot_CUOTAVTO += WCuota_Bill;
    // Endif;

    dsControFSMC.tsalso = TSaldo;
    dsControFSMC.tsalpa = TSaldoPa;

    if Produce_Recibo(dsSocio:dsControFSMC.tacrec);
      dsControFSMC.trecib = '1';
      GenRecibo = *On;
    else;
      dsControFSMC.trecib = *blanks;
      GenRecibo = *Off;
    endif;

    TSaldo = dsControFSMC.tsalso;

    If TSaldo <> 0;
      // Las tarjetas con Saldo Negativo(A favor) No generan Recibo
      If GenRecibo and TSaldo > 0;
        Informar_RecibosMC(dsSocio:dsControFSMC.tsalso:dsControFSMC.tacrec);
      EndIf;

      Exec Sql
      INSERT INTO CONTROFSMC (TXC, TNUMSO, TANUAL, TDUPLI, TSALSO, TLIBR1, TLIBR2,
          TSALPA, TACREC, TCONFA, TSACER, TNOTAS, TNOEXT, TLIBR3, TFEPAG, TTE130,
          TREGEM, TPERVI, TPLAVI, TITUEU, TRECIB, TSVIEU)
        VALUES(:dsControFSMC);

      If Sqlcode < 0;
        observacionSql = 'Error al insertar en el CONTROFSMC';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      EndIf;

      If Nivel_Alerta = 'HI';
        *InH1 = *On;
        *InLR = *On;
      EndIf;
    EndIf;
  end-proc;
  // -----------------------------------------------------------------------------
  // calcula y Genera Cuota de Mantenimiento / Especial
  // -----------------------------------------------------------------------------
  dcl-proc Genera_Cuota_Mtto;

    dcl-pi *n zoned(6:0);
      dsSocio likeDs(dsSocioTpl);
    end-pi;

    dcl-s CobraCuota  Ind;
    dcl-s ImpCuota    zoned(9:0) inz;
    dcl-s ImpCuotaEsp zoned(6:0) inz;
    dcl-s ImpCuotaOfe zoned(6:0) inz;
    dcl-s ImpCuotaVto zoned(6:0) inz;
    dcl-s PorcCuota   zoned(3:0) inz;
    dcl-s CodOferta   zoned(8:0) inz;

    CobraCuota = *Off;
    Select;
        // Eximir de   Cuota Primer Año
      When dsSocio.SMESCU = 98;
        ImpCuota = 0;
        Return ImpCuota;
        // Cobra Cuota (Sin Cargar Cuota Vencimiento)
        // Se fuerta al Cobro
      When dsSocio.SMESCU = 99;
        CobraCuota = *On;
        //  Verificar porque le esta moviendo la fecha OJOOOOOOOO
        dsSocio.SMESCU = dsFechaProceso.diaProceso; //ojo
      When (dsSocio.SMESCU>=1 and dsSocio.SMESCU<=12) And
         dsSocio.SMESCU = dsFechaProceso.MesProcesoFacturacion and
         dsSocio.SCODPO<> %Editc(dsFechaProceso.AnioProcesoFacturacion2:'X');
        CobraCuota = *On;
      When dsSocio.SMESCU = 97;
        CobraCuota = *On;
    EndSl;

    If Not CobraCuota;
      ImpCuota = 0;
      Return ImpCuota;
    EndIf;

    // Cobra Cuota segun Mes  ...................... Corregir porque es Mes de Proceso
    // If (dsSocio.SMESCU>=1 and dsSocio.SMESCU<=12) And
    //     dsSocio.SMESCU <> dsFechaProceso.diaProceso;
    //     CobraCuota = *On;
    // EndIf;

    // Determina porcenta de la cuoata a Aplicar
    Select;
      When dsSocio.SPORCE = 97;
        PorcCuota = 100;
      When dsSocio.SPORCE = 98;
        PorcCuota = 100;  // ????????
      When dsSocio.SPORCE = 99;
        ImpCuota = 0;
        Return ImpCuota;
      Other;
        PorcCuota = dsSocio.SPORCE;
    EndSl;

    // Verficar si hay Cuota Especial (CUOTAESPE)
    // ------------------------------------------
    Exec SQL
    SELECT
      CIMPORT
    Into :ImpCuotaEsp
    FROM CUOTAESPE
    Where
      CFEBAJA = 0 AND
      CNUREAL = :dsSocio.Nureal;
    Select;
      When Sqlcode <> 0;
        observacionSql = 'Error NO existe registro de Cuota Especial';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

        // If Nivel_Alerta = 'HI';
        //   *InH1 = *On;
        //   *InLR = *On;
        // EndIf;
      When Sqlcode = 0 and ImpCuotaEsp=0;
        observacionSql = 'Error el registro de Cuota Especial esta en Cero';
        Clear Nivel_Alerta;
        Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);

        // If Nivel_Alerta = 'HI';
        //   *InH1 = *On;
        //   *InLR = *On;
        // EndIf;
      When SqlCode = 0 And ImpCuotaEsp<>0;
        ImpCuotaEsp = ImpCuotaEsp * PorcCuota / 100;
        Genera_Reg_Cuota_BS(dsSocio:ImpCuotaEsp:'BT':'9');
        Return ImpCuotaEsp;
    EndSl;

    // Verficar si hay Cuota Oferta
    // -----------------------------
    // Exec SQL
    //   SELECT
    //     FOFERTA
    //     Into :CodOferta
    //   FROM CUOTEHIS
    //   WHERE
    //     FBAJA = 0  AND
    //     FOFERTA<>0 AND
    //     FSOCIO = :DsSocio.Nureal;

    // If  SqlCode = 0;
    //     Exec SQL
    //       Select
    //         MANUIMP
    //       Into :ImpCuotaOfe
    //       From CUOTEOFER
    //       WHERE
    //         MFBAJA = 0 AND
    //         MOFERTA = :CodOferta;

    //     If SqlCode = 0 And ImpCuotaOfe<>0;
    //        ImpCuotaOfe = ImpCuotaOfe * PorcCuota;
    //        Genera_Reg_Cuota_BS(dsSocio:ImpCuotaOfe:'BT':'9');
    //        Return ImpCuotaOfe;
    //     EndIf;
    // Endif;

    // Verficar si hay Cuota Vencimiento (CUOTAVTO)
    // ------------------------------------------
    // Exec SQL
    //   SELECT
    //     CPO1
    //   Into :ImpCuotaVto
    //   FROM CUOTAVTO
    //   Where
    //     KEY = :DsSocio.SMOCTA;

    // If SqlCode = 0 And ImpCuotaVto<>0;
    //    ImpCuotaVto = ImpCuotaVto * PorcCuota;
    //    Genera_Reg_Cuota_BS(dsSocio:ImpCuotaVto:'BT':'9');
    //    Return ImpCuotaVto;
    // Endif;

    Return 0;

  end-proc;
  // -----------------------------------------------------------------------------
  // Genera Registro de Cuota Especial/Vencimiento en el BS
  // -----------------------------------------------------------------------------
  dcl-proc Genera_Reg_Cuota_BS;

    dcl-pi *n;
      dsSocio likeDs(dsSocioTpl);
      ImpCuota  zoned(6:0);
      P_bcodre  Char(2) const;
      P_BCODMO  Char(1) const;
    end-pi;

    dcl-ds dsBsMC likeDS(dsBSMCTempl) inz;
    dcl-ds dsDatos2 likeDS(dsDatos2Templ) inz;
    dcl-ds dsL5 likeDS(dsL5Templ) inz;

    dcl-s Wtte130 Zoned(8:0);

    Reset dsBsMC;
    Reset dsL5;

    dsBsMC.bcodre = P_bcodre;   //'BT';
    dsBsMC.BCODMO = P_BCODMO;   //'9';
    dsBsMC.BNUMRE = dsSocio.Nureal;
    dsBsMC.BIMPOR = ImpCuota;
    dsBsMC.BFECON = dsFechaProceso.fechaProcesoFacturacion;
    dsBsMC.BDICON = dsFechaProceso.diafacturacion;  //ojo
    If P_bcodre = 'BR';
      dsBsMC.LNUMCO = 982;
      %SubSt(dsBsMC.l4:11:1) = '1';
    EndIf;

    dsBsMC.L5     = dsL5;

    dsBsMC.BDIAPR = dsFechaProceso.diafacturacion; //ojo

    If Determina_Codigo_Grupo(dsSocio:Wtte130);
      dsBsMC.bte130 = Wtte130;
    Else;
      dsBsMC.bte130 = 99999999;
    Endif;

    dsBsMC.BREGEM = dsSocio.SREGEM;
    if dsSocio.SBCHRE > 0 and dsSocio.SCOBHA <> 'Z';
      dsBsMC.bbchre = dsSocio.SBCHRE;
    else;
      dsBsMC.bbchre = 0;
    endif;
    dsBsMC.BMONED = '0';

    dsBsMC.BENTDI = dsFechaProceso.mesAnioProcesoFacturacion;//ojo
    dsBsMC.BPROFA = dsFechaProceso.fechaProcesoFacturacion;
    dsBsMC.BFREAL = dsFechaProceso.mesAnioProcesoFacturacion; //ojo

    Exec Sql
    INSERT INTO BSMC (BCODRE, L7, BACTIV, BCLAPA, BNUMES, BDIGIT, BDUPLI,
        BCODMO, BNUMRE, L1, BIMPOR, L8, L2, L6, BFECON, BDICON, L3, LNUMCO, BNUPAI,
        L4, CONPM, L5, BDIAPR, BTE130, BREGEM, BBCHRE, BEUROS, BMONED, BSEACO,
        BOEXCO, BNUBAS, BCOREL, BRESTO, BENTDI, BPROFA, BFREAL, BAGENC, BCRUCE,
        BTIPOP, BRENFE, BREEMB, BCODGE, BNUCR2, BCADIN, BLIN1, BLIN2, BLIN3, BPUREN,
        BSUREN, BBIREN, BOMMSS, BNOPGM, BNFICM, BNTRAM, BREFOR, BSAUNA, BNTRMI,
        BFFAMI, BENVSG, BESTAD, BCOMI0, BAMPLI)
      VALUES(:dsBsMC);

    If Sqlcode < 0;
      observacionSql = 'Error al insertar en el BSMC por Cuotas';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;
  end-proc;
  // -----------------------------------------------------------------------------
  // calcula y Genera Cuota de Financiamiento
  // -----------------------------------------------------------------------------
  dcl-proc Genera_Cuota_Financ;

    dcl-pi *n zoned(6:0);
      dsSocio likeDs(dsSocioTpl);
    end-pi;

    dcl-s CobraCuota  Ind;
    dcl-s ImpCuota    zoned(6:0) inz;

    Return 0;

    CobraCuota = *Off;

    // Verficar si hay registros de Financiamiento
    Exec SQL
    SELECT
      round(Dec( (FINTANU * FDIAPLA * FSALDOC) / 36000, 9, 2), 2)
    Into :ImpCuota
    FROM MSTAFAFAC
    Where
      FNUREAL = :dsSocio.Nureal;

    If SqlCode = 0 And ImpCuota<>0;
      Genera_Reg_Cuota_BS(dsSocio:ImpCuota:'BR':'L');

      // Aca hay que actualizar el MSTAFAFAC
      ImpCuota = ImpCuota;
      Return ImpCuota;
    Endif;

    Return ImpCuota;

  end-proc;
  // -----------------------------------------------------------------------------
  // calcula y Genera Cuota de BILLHOP
  // -----------------------------------------------------------------------------
  dcl-proc Genera_Cuota_BillHop;

    dcl-pi *n zoned(6:0);
      dsSocio likeDs(dsSocioTpl);
      saldoSocio zoned(9:0);
    end-pi;

    dcl-ds dsMS_BILLFAC likeds(dsMS_BILLFACTempl) inz;

    dcl-s CobraCuota  Ind;
    dcl-s ImpCuota    zoned(6:0) inz;

    Return 0;
    CobraCuota = *Off;

    // Verficar si hay registros de Financiamiento
    Exec SQL
    SELECT
      FBNUREAL, FBCOMISI, FBFEEXT, FBFECPA,
      FBSALDOC, FBINTERE, FBSALDOF
    Into :dsMS_BILLFAC
    FROM MS_BILLFAC
    Where
      FBNUREAL = :dsSocio.Nureal;

    If SqlCode = 0;
      dsMS_BILLFAC.FBFEEXT = dsFechaProceso.fechaProcesoFacturacion;
      dsMS_BILLFAC.FBFECPA = dsFechaProceso.fechaProcesoFacturacion;
      dsMS_BILLFAC.FBSALDOC= saldoSocio / 100;

      EVAL(H) dsMS_BILLFAC.FBINTERE = (dsMS_BILLFAC.FBCOMISI * saldoSocio) / 100;
      dsMS_BILLFAC.FBSALDOF += dsMS_BILLFAC.FBINTERE;
      ImpCuota = dsMS_BILLFAC.FBINTERE * 100;
      Genera_Reg_Cuota_BS(dsSocio:ImpCuota:'BR':'L');

      // Aca hay que actualizar el MS_BILLFAC
      Return ImpCuota;
    Endif;

    Return ImpCuota;

  end-proc;
  // -----------------------------------------------------------------------------
  // Devuelve si es adeudo o abono
  // -----------------------------------------------------------------------------
  dcl-proc Es_Adeudo;

    dcl-pi *n ind;
      codigo char(1);
    end-pi;

    if %scan(codigo:ADEUDO) > 0;
      return *on;
    else;
      return *off;
    endif;

  end-proc;

  // -----------------------------------------------------------------------------
  // Devuelve si es un registro FA
  // -----------------------------------------------------------------------------
  dcl-proc Determina_Si_Suma_PA;

    dcl-pi *n ind;
      Codigo char(1);
      CodPro Zoned(3:0);
    end-pi;

    Dcl-s CodProArr Zoned(3) Dim(10) Inz;

    CodProArr(1) = 990;
    CodProArr(2) = 989;
    CodProArr(3) = 988;
    CodProArr(4) = 986;
    CodProArr(5) = 985;
    CodProArr(6) = 984;

    Select;
        // Si es Codigo: 4, 5 o 7 es PA
      When %scan(Codigo:ES_PA) > 0;
        Return *On;
        // Es Oferta No suma
      When Codigo = '9' and CodPro = 987;
        Return *On;
        // Es Oferta No suma
      When Codigo ='L' and
         (%LOOKUP(CodPro:CodProArr))>0;
        Return *On;
    EndSl;

    return *off;

  end-proc;

  // CODIGO <> 4
  // CODIGO <> 5
  // CODIGO <> 7 t
  // CODIGO = '9' AND COMPRO = 987 OR             -OFERTAS: CUOTA ANUA
  // CODIGO = 'L' AND COMPRO = 990 OR             -OFERTAS: CUOTA UG-1
  // CODIGO = 'L' AND COMPRO = 989 OR             -OFERTAS: CUOTA UG-2
  // CODIGO = 'L' AND COMPRO = 988 OR             -OFERTAS: COSTES CON
  // CODIGO = 'L' AND COMPRO = 986 OR             -OFERTAS: CTA. CLASS
  // CODIGO = 'L' AND COMPRO = 985 OR             -OFERTAS: CTA. BUS.
  // CODIGO = 'L' AND COMPRO = 984                -OFERTAS: CTA. CORP.

  // -----------------------------------------------------------------------------
  // Devuelve código de recobro
  // -----------------------------------------------------------------------------
  dcl-proc Obtener_Codigo_Recobro;

    dcl-pi *n zoned(1:0);
      dsSocio likeDs(dsSocioTpl);
      saldoSocio zoned(9:0);
      saldoFa zoned(9:0);
    end-pi;

    dcl-s codRecobro zoned(1:0) inz;
    dcl-s accionRecobroBanco char(1) inz;

    if saldoSocio <= 0 or saldoFa <= 0;
      codRecobro = 0;
      if dsSocio.status = 0;
        Obtener_Codigo_Recobro_2(dsSocio.status:codRecobro);
        return codRecobro;
      endif;
    endif;

    if dsSocio.status > 0 and dsSocio.status < 9;
      codRecobro = 4;
      Obtener_Codigo_Recobro_2(dsSocio.status:codRecobro);
      return codRecobro;
    endif;

    // Socio A
    if dsSocio.sconso = 2;
      codRecobro = 1;
    else;
      codRecobro = dsSocio.sacrec + 1;
    endif;

    // Si la forma de pago no es banco
    if codRecobro <> 0 and dsSocio.sfPago <> 1;
      Obtener_Codigo_Recobro_2(dsSocio.status:codRecobro);
      return codRecobro;
    endif;

    if dsSocio.sacreb = 'LSR' or dsSocio.sacreb = 'LP';
      codRecobro = 1;
      Obtener_Codigo_Recobro_2(dsSocio.status:codRecobro);
      return codRecobro;
    elseif %subst(dsSocio.sacreb:2:1) = 'P';
      codRecobro = 2;
      Obtener_Codigo_Recobro_2(dsSocio.status:codRecobro);
      return codRecobro;
    elseif %subst(dsSocio.sacreb:2:1) = 'S' and codRecobro <= 3;
      codRecobro = 3;
      Obtener_Codigo_Recobro_2(dsSocio.status:codRecobro);
      return codRecobro;
    endif;

    return codRecobro;

  end-proc;

  // -----------------------------------------------------------------------------
  // Devuelve código de recobro
  // -----------------------------------------------------------------------------
  dcl-proc Obtener_Codigo_Recobro_2;

    dcl-pi *n;
      status zoned(1:0);
      codRecobro zoned(1:0);
    end-pi;

    if codRecobro > 3 and status = 0;
      codRecobro = 3;
    elseif codRecobro > 3 and status <> 0;
      codRecobro = 4;
    endif;

  end-proc;

  // -----------------------------------------------------------------------------
  // Obtener la condición de saldo atrasado
  // -----------------------------------------------------------------------------
  dcl-proc Obtener_Condicion_Saldo_Atrasado;

    dcl-pi *n zoned(1:0);
      saldoFa zoned(9:0);
    end-pi;

    if saldoFa > 0;
      return 1;
    endif;

    return 0;

  end-proc;

  // -----------------------------------------------------------------------------
  // Obtener codigo saldo cero
  // -----------------------------------------------------------------------------
  dcl-proc Obtener_Codigo_Saldo_Cero;

    dcl-pi *n zoned(1:0);
      saldoSocio zoned(9:0);
    end-pi;

    if saldoSocio < 0;
      return 2;
    elseif saldoSocio = 0;
      return 1;
    endif;

    return 0;

  end-proc;

  // -----------------------------------------------------------------------------
  // Obtener núm. notas
  // -----------------------------------------------------------------------------
  dcl-proc Obtener_Numero_Notas;

    dcl-pi *n zoned(3:0);
      codigo char(1);
    end-pi;

    if codigo = '4' or codigo = '7';
      return 1;
    endif;

    return 0;

  end-proc;

  // -----------------------------------------------------------------------------
  // Devuelve si no hace extracto
  // 1 - No extracto
  // 0 - Si extracto
  // -----------------------------------------------------------------------------
  dcl-proc No_Hace_Extracto;

    dcl-pi *n zoned(1:0);
      saldoSocio zoned(9:0);
      status zoned(1:0);
    end-pi;

    if saldoSocio = 0 or status >= 2;
      return 1;
    endif;

    return 0;

  end-proc;

  // -----------------------------------------------------------------------------
  // Obtener la fecha de pago
  // -----------------------------------------------------------------------------
  dcl-proc Obtener_Fecha_Pago;

    dcl-pi *n zoned(8:0);   // ddmmyyyy
      diaPago zoned(2:0);
      diaFacturacion zoned(2:0);
      modalidadFacturacion char(1);
    end-pi;

    dcl-s dia1 packed(3:0) inz;
    dcl-s dateProceso packed(8:0) inz;
    dcl-s fmtInput char(4) inz('*DMY');
    dcl-s fmtOutput char(4) inz('*DMY');
    dcl-ds dsFechaPago inz;
      fechaPago zoned(8:0);
      dd zoned(2:0) pos(1);
      mm zoned(2:0) pos(3);
      yyyy zoned(4:0) pos(5);
    end-ds;

    // Fecha pago especial
    if diaPago > 30 or modalidadFacturacion = 'X';
      dia1 = diaPago;
      dateProceso = dsFechaProceso.fechaProcesoFacturacion;
      callP CALDIA1(dateProceso:dia1:fmtInput:fmtOutput);
      fechaPago = dateProceso;
      // Fecha pago normal
    else;
      dd = diaPago;
      // mm = %subdt(%date():*MONTHS);
      mm = %dec(%SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X')
           :3:2):2:0);//ojo
      // yyyy = %subdt(%date():*YEARS);
      yyyy = %dec(%SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X')
           :5:4):4:0);//ojo

      if diaFacturacion >= diaPago;
        mm += 1;
      endif;

      if mm > 12;
        mm = 1;
        yyyy += 1;
      endif;

      // Calculo del último día del mes (el real)
      if dd = 30;
        Exec Sql
        SET :dd = SUBSTR(CHAR(LAST_DAY(TRIM(CHAR(:yyyy)) || '-' || TRIM(CHAR(:mm)) || '-01'),
                    ISO), 9, 2);
      endif;

    endif;

    return fechaPago;

  end-proc;

  // -----------------------------------------------------------------------------
  // Control de virtuales
  // -----------------------------------------------------------------------------
  dcl-proc Control_Virtuales;

    dcl-pi *n;
      tarjetaVirtual char(2) const;
      plazosTarjetaVirtual char(1) const;
      tipoPlastico char(1) const;
      periodoTarjetaVirtual zoned(2:0);
      plazosTarjetaVirtualResult zoned(1:0);
    end-pi;

    if tarjetaVirtual = '00' or plazosTarjetaVirtual = '0' or tipoPlastico <> 'V';
      periodoTarjetaVirtual = 0;
      plazosTarjetaVirtualResult = 0;
    else;
      periodoTarjetaVirtual = %dec(tarjetaVirtual:2:0);
      plazosTarjetaVirtualResult = %dec(plazosTarjetaVirtual:1:0);
    endif;

  end-proc;

  // -----------------------------------------------------------------------------
  // Calcular si se produce recibo
  // -----------------------------------------------------------------------------
  dcl-proc Produce_Recibo;

    dcl-pi *n ind;
      dsSocio likeDs(dsSocioTpl);
      codigoRecobro zoned(1:0);
    end-pi;

    dcl-s ciclo zoned(4:0) inz;
    dcl-s tarjeta zoned(14:0) inz;
    dcl-s noAbonos ind inz;

    ciclo = %dec(%subst(%editc(dsSocio.NUREAL:'X'):1:4):4:0);
    tarjeta = Obtener_Tarjeta(dsSocio.SNUSO1:dsSocio.NUREAL:dsSocio.SNUSO2);

    // Exec Sql
    // SELECT '1'
    //   into :noAbonos
    // FROM NOABONOS
    // WHERE RNUMSO = :tarjeta;

    // Si la forma de pago no es banco
    //if noAbonos or dsSocio.sfPago <> 1;
    if dsSocio.sfPago <> 1;
      return *off;
    endif;

    if (codigoRecobro > 1 and dsSocio.status <> 1) or dsSocio.status > 1;
      return *off;
    endif;

    return *on;

  end-proc;

  // -----------------------------------------------------------------------------
  // Informar RecibosMC
  // -----------------------------------------------------------------------------
  dcl-proc Informar_RecibosMC;

    dcl-pi *n;
      dsSocio likeDs(dsSocioTpl);
      saldoSocio zoned(9:0);
      codigoRecobro zoned(1:0);
    end-pi;

    dcl-ds dsRecibosMC likeDs(dsRecibosMCTempl) inz;

    dsRecibosMC.rnumso = Obtener_Tarjeta(dsSocio.SNUSO1:dsSocio.NUREAL:dsSocio.SNUSO2);
    dsRecibosMC.rnomso = dsSocio.snombr;
    dsRecibosMC.rnomba = dsSocio.snomba;
    dsRecibosMC.rdirba = dsSocio.sdomba;
    dsRecibosMC.rlocba = dsSocio.slocba;
    dsRecibosMC.rzonba = dsSocio.szoban;
    dsRecibosMC.rnumcc = dsSocio.snctac;
    dsRecibosMC.rnomcc = dsSocio.smctac;
    dsRecibosMC.rpts = saldoSocio;
    dsRecibosMC.rlibr1 = *blanks;
    dsRecibosMC.rlibr2 = *blanks;
    dsRecibosMC.rlibr5 = 'E';
    dsRecibosMC.rfecre = 0;
    dsRecibosMC.rnumbc = dsSocio.nbanco;
    dsRecibosMC.rlibr3 = *blanks;
    dsRecibosMC.rregem = dsSocio.sregem;
    dsRecibosMC.rlibr4 = *blanks;

    // Socio A
    if dsSocio.sconso = 2;
      dsRecibosMC.raccre = 'A';
    else;
      dsRecibosMC.raccre = %editc(codigoRecobro:'X');
    endif;
    dsRecibosMC.rnusuc = dsSocio.ssubha;
    dsRecibosMC.rlibr6 = *blanks;
    dsRecibosMC.rvtore = Obtener_Fecha_Pago(dsSocio.sdiapa:dsSocio.sdiapr:dsSocio.smofac);
    dsRecibosMC.rdiapr = dsFechaProceso.diafacturacion; //ojo

    Control_Virtuales(dsSocio.stvper:dsSocio.splast:dsSocio.sdupex
      :dsRecibosMC.rvirpe:dsRecibosMC.rvirpl);

    dsRecibosMC.reuros = 0;
    if saldoSocio <> 0;
      eval(h) dsRecibosMC.reuros = (saldoSocio / 100) * 166,386;
    endif;

    // TODO: No hay extracto unificado
    dsRecibosMC.rtiteu = 0;

    dsRecibosMC.relim1 = *blanks;

    Exec Sql
    INSERT INTO RECIBOSMC (RNUMSO, RNOMSO, RNOMBA, RDIRBA, RLOCBA, RZONBA,
        RNUMCC, RNOMCC, RPTS, RLIBR1, RLIBR2, RLIBR5, RFECRE, RNUMBC, RLIBR3, RREGEM,
        RLIBR4, RACCRE, RNUSUC, RLIBR6, RVTORE, RDIAPR, RVIRPE, RVIRPL, REUROS, RTITEU,
        RELIM1)
    VALUES (:dsRecibosMC);

    If Sqlcode < 0;
      observacionSql = 'Error al insertar en el RECIBOSMC';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;
  end-proc;

  // -----------------------------------------------------------------------------
  // Obtener tarjeta
  // -----------------------------------------------------------------------------
  dcl-proc Obtener_Tarjeta;

    dcl-pi *n zoned(14:0);
      nuso1 zoned(2:0);
      nureal zoned(8:0);
      nuso2 zoned(4:0);
    end-pi;

    return %dec(%editc(nuso1:'X') + %editc(nureal:'X') +
      %editc(nuso2:'X'):14:0);

  end-proc;
  // -----------------------------------------------------------------
  // Acumula_importe
  // -----------------------------------------------------------------
  dcl-proc Acumula_importe;
    dcl-pi *n Ind;
      P_NumSoc  Zoned(8:0);
      P_Impor   Zoned(6:0);
      P_Ind     Zoned(5);
    end-pi;

    Dcl-s WCodpro  Zoned(3);
    Dcl-s WIndx    Zoned(5);

    Exec SQL
      SELECT SCODPR
        Into :WCodpro
      FROM t_msocio
      Where NUREAL = :P_NumSoc;

    If SQLCODE<>0;
      Return *Off;
    EndIf;

    WIndx = %lookup(WCodpro: Acumulador(*).Cod_prod:1);
    if WIndx > 0;
      Acumulador(WIndx).Total += P_Impor;
    else;
      P_Ind += 1;
      Acumulador(P_Ind).Cod_prod = WCodpro;
      Acumulador(P_Ind).Total    = P_Impor;
    endif;

    Return *On;

  end-proc;
  // -----------------------------------------------------------------
  // Actualiza Saldos en MSOCIO
  // -----------------------------------------------------------------
  dcl-proc Actualiza_MSOCIO;

    dcl-pi *n;
      dsSocio likeDs(dsSocioTpl);
      TSaldo  zoned(9:0);
    end-pi;

    Dcl-s FecRecibo Zoned(8:0);
    Dcl-s ImpRecibo Zoned(9:0);

    If TSaldo > 0;
      // FecRecibo = %dec(
      //   (
      //   %SubSt(%Editc(dsFechaProceso.fechaProceso:'X'):5:4) +
      //   %SubSt(%Editc(dsFechaProceso.fechaProceso:'X'):3:2) +
      //   %SubSt(%Editc(dsFechaProceso.fechaProceso:'X'):1:2)
      //   ):8:0)
      //   ;
      FecRecibo = %dec(
        (
        %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):5:4) +
        %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):3:2) +
        %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):1:2)
        ):8:0)
        ;
      ImpRecibo  = TSaldo;
    else;
      ImpRecibo = 0;
      FecRecibo = 0;
    EndIf;

    If WCUOTA_SOC <> 0;
      dsSocio.SCODPO = %Editc(dsFechaProceso.AnioProcesoFacturacion2:'X');
      dsSocio.smescu = dsFechaProceso.MesProcesoFacturacion;
    Endif;

    Exec Sql
      UPDATE MSOCIO
      SET
        SFREC1 = :dsSocio.SFREC2,
        SIMPR1 = :dsSocio.SIMPR2,
        SFREC2 = :dsSocio.SFREC3,
        SIMPR2 = :dsSocio.SIMPR3,
        SFREC3 = :dsSocio.SFREC4,
        SIMPR3 = :dsSocio.SIMPR4,
        SFREC4 = :FecRecibo,
        SCODPO = :dsSocio.SCODPO,
        SMESCU = :dsSocio.smescu,
        SIMPR4 = :ImpRecibo,
        SSALAN = :TSaldo,
        SRECAU = :ImpRecibo
    // SFACRB = :FecRecibo
      WHERE
        NUREAL = :dsSocio.NUREAL;

    If Sqlcode < 0;
      observacionSql = 'Error al Actualizar MSOCIO los Saldos de Recibo';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;
  end-proc;
  // -----------------------------------------------------------------
  // Genera Contabilidad
  // -----------------------------------------------------------------
  dcl-proc Genera_Contabilidad;

    Dcl-s I  Zoned(3);

    For I=1 to WInd;
      if not Guardar_Asiento(
          Acumulador(I).Cod_prod:
          Acumulador(I).Total:
          NumApun:
          fechaSistema);
        return;
      endif;

    EndFor;

  end-proc;
  // -----------------------------------------------------------------------------
  // Guardar Asiento
  // -----------------------------------------------------------------------------
  dcl-proc Guardar_Asiento;

    dcl-pi *n ind;
      codProducto  zoned(3:0);
      P_Impor      Packed(9:0);
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
    dsDatosAsientoNoParametrizables.fechaContable =
            %dec(%date(fechaSistema):*EUR);
    dsDatosAsientoNoParametrizables.referenciaOperacion = *blanks;
    dsDatosAsientoNoParametrizables.fechaVencimiento = 0;
    dsDatosAsientoNoParametrizables.codMoneda = '1';
    dsDatosAsientoNoParametrizables.apunteProvisional = *blanks;
    dsDatosAsientoNoParametrizables.tipoOperacion = 0;

    // ************  Asiento 3 orden 1 (Haber)
    dsKeyAsiento.idAsiento = 3;
    dsKeyAsiento.ordenApunte = 1;
    dsKeyAsiento.codProducto = codProducto;

    if P_Impor >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(P_Impor/100);

    if not Obtener_Datos_Asiento(
          dsKeyAsiento:
          dsDatosAsientoParametrizables:
          dsDatosAsientoNoParametrizables:
          dsAsifilen:textoError);
      // wNumError = '01';
      // exsr LogCorreoError;
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      // wNumError = '02';
      // exsr LogCorreoError;
      return *off;
    endif;

    // ************  Asiento 3 orden 2 (Debito)
    dsKeyAsiento.idAsiento = 3;
    dsKeyAsiento.ordenApunte = 2;
    dsKeyAsiento.codProducto = codProducto;

    if P_Impor >= 0;
      dsDatosAsientoNoParametrizables.debeHaber = 'D';
    else;
      dsDatosAsientoNoParametrizables.debeHaber = 'H';
    endif;
    dsDatosAsientoNoParametrizables.importe = %abs(P_Impor/100);
    if not Obtener_Datos_Asiento(
          dsKeyAsiento:
          dsDatosAsientoParametrizables:
          dsDatosAsientoNoParametrizables:
          dsAsifilen:textoError);
      // wNumError = '03';
      // exsr LogCorreoError;
      return *off;
    endif;

    if not Grabar_Asiento(dsAsifilen:sqlError:sqlMensaje);
      // wNumError = '04';
      // exsr LogCorreoError;
      return *off;
    endif;

    return *on;
  end-proc;
  // -----------------------------------------------------------------
  // Genera Inserta Cabecera de Evidencia Contable
  // -----------------------------------------------------------------
  dcl-proc Inserta_Cebecera_Evi;

    dcl-pi *n Ind;
    end-pi;

    Dcl-s WReg  Char(132);

    WReg = 'FSBALAMC        EVIDENCIA CONTABLE CUOTAS COBRADAS AL ' +
         %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):1:2) + '-' +
         %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):3:2) + '-' +
         %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):5:4) +
         '        ** CONTABILIDAD **';
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    WReg = '                ------------------------------------------------';
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    WReg = ' ';
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    WReg = 'NUMERO REAL   NOMBRE DEL SOCIO                       ' +
        'IMPORTE CUOTA   FECHA PAGO   MEMPRE';
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    Return *Off;

  end-proc;
  // -----------------------------------------------------------------
  // Genera Inserta Detalle de Evidencia Contable
  // -----------------------------------------------------------------
  dcl-proc Inserta_Detalle_Evi;

    dcl-pi *n ind;
      dsSocio      likeDs(dsSocioTpl);
      dsControFSMC likeDs(dsControFSMCTempl);
      WCuota       zoned(6:0);
    end-pi;

    Dcl-s WReg  Char(132);
    Dcl-s WImpCuo Zoned(6:2);

    dcl-ds dsDetalEvi Qualified;
      Esp01     Char(1);
      NumReal   Zoned(8);
      Esp02     Char(5);
      NomSoc    Char(35);
      Esp03     Char(8);
      ImpCuo    Char(8);
      Esp04     Zoned(4);
      FecPag    Char(10);
      Esp05     Zoned(3);
      NumEmp    Zoned(6);
    End-ds;

    dsDetalEvi.NumReal = dsSocio.NUREAL;
    dsDetalEvi.NomSoc  = dsSocio.SNOMBR;
    WImpCuo = WCuota/100;
    dsDetalEvi.ImpCuo  = %Editc(WImpCuo:'2');
    dsDetalEvi.FecPag  =
         %SubSt(%Editc(dsControFSMC.TFEPAG:'X'):1:2) + '-' +
         %SubSt(%Editc(dsControFSMC.TFEPAG:'X'):3:2) + '-' +
         %SubSt(%Editc(dsControFSMC.TFEPAG:'X'):5:4);
    dsDetalEvi.NumEmp  = dsControFSMC.TREGEM;

    WReg = dsDetalEvi;
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Det. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    Return *Off;

  end-proc;
  // -----------------------------------------------------------------
  // Genera Inserta Totales de Evidencia Contable
  // -----------------------------------------------------------------
  dcl-proc Inserta_Totales_Evi;

    dcl-pi *n Ind;
    end-pi;

    Dcl-s WReg      Char(132);
    Dcl-s WNomProd  Char(30);
    Dcl-s I         Zoned(3);
    Dcl-s WCod_Prod Zoned(3);

    WReg = '';
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    WReg = 'Codigo Producto'       +
         '                           ' +
         'Total' ;
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    WReg = '------------------------------------' +
         '    ' +
         '------------' ;
    Exec Sql
    INSERT INTO EVIBALAMC (EVIBALAMC)
      Values(:WReg);

    If Sqlcode<>0;
      WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
      dsply WDSPLY;
      Return *On;
    EndIf;

    For I=1 to WInd;
      If Acumulador(I).Cod_prod<>999;

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
      Else;
        WNomProd = 'DINERS';
      EndIf;

      WReg = %Editc(Acumulador(I).Cod_prod:'X') +
            ' - ' + WNomProd + '    '    +
            %Editc(
              %Dec(Acumulador(I).Total/100:9:2)
              :'2');
      Exec Sql
      INSERT INTO EVIBALAMC (EVIBALAMC)
        Values(:WReg);

      If Sqlcode<>0;
        WDSPLY = 'FSBALAMC Error Insert Cab. Eviden.';
        dsply WDSPLY;
        Return *On;
      EndIf;
    EndFor;

    Return *Off;

  end-proc;
  // -----------------------------------------------------------------
  // Genera Registro de Cuota en el CONCPVF
  // -----------------------------------------------------------------
  dcl-proc Inserta_Reg_CONCPVF;

    dcl-pi *n ind;
      dsSocio      likeDs(dsSocioTpl);
      WCuota       zoned(6:0);
    end-pi;

    dcl-ds dsCONCPVF likeDs(dsCONCPVFTempl) inz;

    // dcl-ds dsBsMC likeDS(dsBSMCTempl) inz;

    // Reset dsCONCPVF;
    dsCONCPVF.BTARJE = dsSocio.NUREAL;
    dsCONCPVF.BTIPOC = 'CV';
    Monitor;
      dsCONCPVF.BFEALT = %Dec(
      (%SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):5:4) +   //AAAA
       %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):3:2) +   //Mes
       %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):1:2))    //Dia
      :8:0)
      ;
    on-error;
      dsCONCPVF.BFEALT =  %dec(%date(fechaSistema):*EUR);
    endmon;

    dsCONCPVF.BNPLAZ = 12;
    dsCONCPVF.BIMPOR = WCuota/100;
    dsCONCPVF.BNPLAP = 12;
    dsCONCPVF.BIMPOP = WCuota/100;
    dsCONCPVF.BTITAR = dsSocio.smocta;

    Exec Sql
    INSERT INTO CONCPVF (BTARJE, BTIPOC, BFEALT, BNPLAZ, BIMPOR,
        BNPLAP, BIMPOP, BFEULP, BFEVAB, BMOVAB, BIMPAB, BTITAR)
    VALUES (:dsCONCPVF);

    If Sqlcode < 0;
      observacionSql = 'Error al insertar en CONCPVF';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;

    Return *Off;

  end-proc;
  // -----------------------------------------------------------------
  // Genera Totales
  // -----------------------------------------------------------------
  dcl-proc Genera_Totales;

    dcl-pi *n;
    end-pi;

    Dcl-s WClave   Char( 6);
    Dcl-s WTxt     Char(30);
    Dcl-s WImporte Packed(13:0);
    Dcl-s WFecha   Packed( 6:0);

    // Fecha del proceso DD/MM/AA
    WFecha = %Dec(
        (%SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):1:4) +
         %SubSt(%Editc(dsFechaProceso.fechaProcesoFacturacion:'X'):7:2))
        :6:0);

    If WTot_CUOTAVTO<>0;
      // Actualiza Total PAGE00
      WClave   = 'PAGE00';
      WTxt     = 'MC - CUOTAS DE VENCIMIENTO';
      WImporte = WTot_CUOTAVTO;
      ACUTOTN(WClave:WTxt:WImporte:WFecha);

      // Actualiza Total DATAWH
      WClave   = 'DATAWH';
      ACUTOTN(WClave:WTxt:WImporte:WFecha);

      // Actualiza Total FSOCEM
      WClave   = 'FSOCEM';
      ACUTOTN(WClave:WTxt:WImporte:WFecha);

    EndIf;

    If WTot_FAPA <> 0;
      // Actualiza Total BSACU0
      WClave   = 'BSACU0';
      WTxt     = 'FSBALAMC - EMPRESAS';
      WImporte = WTot_FAPA;
      ACUTOTN(WClave:WTxt:WImporte:WFecha);

      // Actualiza Total PAGE00
      WClave   = 'PAGE00';
      WTxt     = 'MC - TOTAL SE FACTURA';
      WImporte = -WTot_FAPA;
      ACUTOTN(WClave:WTxt:WImporte:WFecha);

      // Actualiza Total FSOCEM
      WClave   = 'FSOCEM';
      WImporte = -WTot_FAPA;
      ACUTOTN(WClave:WTxt:WImporte:WFecha);

    EndIf;

  end-proc;
  // -----------------------------------------------------------------
  // Determina Codigo de Grupo de empresa (ASODETA)
  // -----------------------------------------------------------------
  dcl-proc Determina_Codigo_Grupo;

    dcl-pi *n ind;
      dsSocio likeDs(dsSocioTpl);
      NUMREL  zoned(8:0);
    end-pi;

    Dcl-s WAso_Numrel  Zoned(8:0);
    Dcl-s WAso_Numrel2 Zoned(8:0);

    Exec Sql
    SELECT dnurel
    Into :WAso_Numrel
    FROM ASODETA
    WHERE
      DNUMRE = :dsSocio.NUREAL AND
      dnumas=131;

    If Sqlcode<>0;
      NUMREL = 99999999;
      Return *Off;
    Endif;

    Exec Sql
    SELECT dnurel
    Into :WAso_Numrel2
    FROM ASODETA
    WHERE
      DNUMRE = :WAso_Numrel AND
      DNUMAS = 130;

    If Sqlcode<>0;
      NUMREL = 99999999;
      Return *Off;
    Endif;

    NUMREL = WAso_Numrel2;
    Return *On;

  end-proc;
