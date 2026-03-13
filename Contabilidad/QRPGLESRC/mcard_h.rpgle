**FREE
//------------------------------------------------------------------------
// MCARD_H - COPY FILE PARA MASTERCARD
//------------------------------------------------------------------------

dcl-ds dsBlomasterTpl qualified template inz;
  numFichero zoned(9:0);
  numOperacion zoned(13:0);
  pantoken char(19);
  codProducto zoned(3:0);
  actividadDiners zoned(2:0);
  actividadDxs zoned(3:0);
  importe zoned(12:0);
  fechaHoraConsumo timestamp;
  diaContable zoned(2:0);
  codigoGeografico zoned(3:0);
  codigoAdquirente zoned(3:0);
  cambioMoneda zoned(7:3);
  importeEuros zoned(15:3);
  claseMoneda zoned(3:0);
  importeComision zoned(15:3);
  numRegistro zoned(4:0);
  hayDatosAdicionales char(1);
  idInformacionAdicional zoned(9:0);
  paisFacturador zoned(3:0);
  claveAlfabeticaMoneda char(3);
  numeroEstablecimiento char(15);
  fechaHoraGrabacion timestamp;
end-ds;

dcl-ds dsFeesMasterTpl qualified template inz;
  numFichero zoned(9:0);
  numLinea zoned(13:0);
  numOperacion zoned(13:0);
  tipoMensaje char(4);
  fechaHoraTransaccion zoned(12:0);
  fee char(44);
  textoTransaccion varchar(256);
end-ds;

dcl-ds dsMensajeTpl qualified template inz;
  numLinea zoned(11:0);
  numOperacion zoned(13:0);
  tipoMensaje char(4);
  p002 char(19);    // Número de tarjeta
  p003 zoned(6:0);  // 20 es abono
  p004 zoned(12:0); // Importe de la transacción
  p006 zoned(12:0); // Importe en moneda del titular
  p012 zoned(12:0); // Fecha y hora local de la transacción
  p019 zoned(3:0);  // Cod. geográfico y adquirente acceder a PAIMON
  P026 zoned(4:0);  // Activdad ISO. Acceder a TABACTI
  P028 zoned(9:0);  // Fecha alta/ sesion
  P038 char(6);  // Codigo autorizacion
  p042 char(15);    // Establecimiento
  // Hay una longitud de 2 posiciones, seguido de un tipo de 2 posiciones
  // por ahora con valor 06. Otro campo de 1 posición que indica C -> credit
  // (abono) o D -> Debit (cargo) y el importe.
  // Ejemplo longitud es 11 --> tipo (2) + creditODebit(1) = 3
  //                            El importe será de 8 --> 3 + 8 = 11
  // Podría venir más de un campo
  p043 char(40); //nombre localida estable
  p046 char(44);    // Comisiones
  p049 zoned(3:0);  // Código moneda transacción
  p051 zoned(3:0);  // Código moneda del titular
  p037 char(12);   // Numero referencia
  P011 zoned(6:0);  // Numero transaccion
  P032 char(11);  // Cod.Identificacion adquirente
end-ds;

dcl-ds dsActividadTpl qualified template inz;
  actividadDiners zoned(2:0);
  actividadDxs zoned(3:0);
end-ds;

dcl-ds dsLogTpl qualified template inz;
  observacion char(1000);
  campo char(20);
  valor char(100);
  programa char(10);
  lineaFuente char(13);
  lineaFichero char(13);
  time_Stamp timestamp;
end-ds;

dcl-ds dsCorreoMCTpl qualified template inz;
  listaDistribucion zoned(2:0);
  programa char(10);
  asunto char(200);
  mensaje char(200);
  esError ind;
  dsClaveValorMsg likeDs(dsClaveValorMsgTpl) dim(20);
end-ds;

dcl-ds dsClaveValorMsgTpl qualified template inz;
  clave char(20);
  valor char(100);
end-ds;

dcl-ds dsPaPreTpl qualified template inz;
  pcoreg char(1);
  pcores char(1);
  plibr3 char(3);
  pactnu zoned(2:0);
  pclapa char(1);
  pnumes zoned(7:0);
  pdigit zoned(1:0);
  pdupli char(1);
  pcr char(1);
  pnurea zoned(8:0);
  pnuref zoned(9:0);
  pimpor zoned(9:0);
  plibr8 char(3);
  plibr2 char(1);
  padici char(1);
  plibr4 char(1);
  pfcons zoned(9:0);
  pdicon zoned(2:0);
  paprob char(1);
  pncomp zoned(5:0);
  pnupai zoned(3:0);
  pcambi zoned(6:3);
  pmoned zoned(3:0);
  pvario char(11);
  pconpm char(1);
  precob zoned(1:0);
  pcodi1 char(4);
  precap zoned(4:0);
  pconco zoned(1:0);
  pusopr char(27);
  pajust char(1);
  plibr5 char(1);
  pfdevo zoned(9:0);
  pcodi2 char(4);
  p3638 zoned(2:0);
  pconbl char(1);
  presto char(1);
  pnucru char(15);
  pcoven char(1);
  pconci char(1);
  pagenc zoned(4:0);
  pmacon zoned(6:0);
  peseta zoned(9:0);
  pcomon char(1);
  psecfa zoned(5:0);
  pnbope zoned(10:0);
  pnbres zoned(4:0);
  pnopre char(5);
  pnreem char(10);
  pprote char(1);
  pcodge char(3);
  pnucr2 char(14);
  pcadin char(3);
  ppuren char(5);
  psuren char(3);
  pbiren char(15);
  pommss char(4);
  pnopgm char(10);
  pnficm zoned(9:0);
  pntram char(15);
  prefor zoned(9:0);
  psauna zoned(8:0);
  pntrmi char(20);
  pffami zoned(8:0);
  penvsg char(1);
  pestad char(1);
  pcomi0 char(2);
  pampli char(200);
end-ds;

dcl-ds dsDataWHMCTpl qualified template inz;
  dnbaso zoned(10:0);
  dnrest char(9);
  dnpais zoned(3:0);
  dcoope zoned(1:0);
  dimpop zoned(9:0);
  dsigop char(1);
  dnumes zoned(7:0);
  dactes zoned(2:0);
  dimpco zoned(8:0);
  dsigco char(1);
  dnpafa zoned(3:0);
  dmonga zoned(3:0);
  dactin zoned(3:0);
  dfecop zoned(8:0);
  dfecon zoned(8:0);
  doppmc char(1);
  dmocta char(2);
  dcopro char(1);
  dsucre zoned(4:0);
  dcsexo char(1);
  dfnsoc zoned(8:0);
  dfasoc zoned(8:0);
  dcpsoc zoned(5:0);
  dfpsoc char(1);
  dbcoso zoned(4:0);
  dmofac char(1);
  ddfaso zoned(2:0);
  ddpaso zoned(2:0);
  dconci char(1);
  dnagso zoned(4:0);
  dstatu zoned(1:0);
  dcatem zoned(1:0);
  dregem zoned(6:0);
  dpunto char(1);
  dfaest zoned(6:0);
  dnages zoned(4:0);
  dcpest zoned(5:0);
  dcfaes char(31);
  ddpaes zoned(2:0);
  dbcoes zoned(4:0);
  ddeses zoned(5:3);
  dtrala char(12);
  dclala char(4);
  dneext char(30);
  dleext char(30);
  dbcome zoned(4:0);
  dsucme zoned(4:0);
  dempme zoned(7:0);
  dfepro zoned(8:0);
  dsecop zoned(6:0);
  dfefic zoned(8:0);
  dtiope char(1);
  dclisch char(1);
  dctavia char(1);
  dnurefe zoned(9:0);
  dnumpro zoned(7:0);
  dtippro char(1);
  dnompro char(35);
  dtipupi char(1);
  dsucren char(3);
  dsenum char(15);
  drecap zoned(4:0);
  drate char(5);
  dcodgeo zoned(3:0);
  dibrul zoned(9:0);
  dinetl zoned(9:0);
  dicoml zoned(9:0);
  dibruo zoned(9:0);
  dineto zoned(9:0);
  dicomo zoned(9:0);
  dcmoma char(3);
  dibrua zoned(9:0);
  dineta zoned(9:0);
  dicoma zoned(9:0);
  dcaapl zoned(6:3);
  dtapre char(1);
  dtipro char(1);
  dtvcna char(19);
  num_ope zoned(13:0);
end-ds;

dcl-ds dsAcutotTpl qualified template inz;
  clave char(6);
  texto char(30);
  importe zoned(11:0);
  fecha zoned(6:0);
end-ds;

dcl-ds dsAcutotnTpl qualified template inz;
  clave char(6);
  texto char(30);
  importe packed(13:0);
  fecha packed(6:0);
end-ds;

dcl-ds dsImportesMCTpl qualified template;
  total zoned(15:2) inz;
  comision zoned(11:2) inz;
end-ds;

dcl-ds dsLineaTextoMCTpl qualified inz template;
  lineaTexto char(132) pos(1);
  pantoken char(19) pos(1);
  importe char(13) pos(25);
  comision char(13) pos(37);
  total char(13) pos(53);
  establecimiento char(15) pos(69);
  numFichero char(9) pos(86);
  numOperacion char(13) pos(96);
  abreviaturaProducto char(5) pos(111);
end-ds;

dcl-ds dsLineaTextoSubtotalesMCTempl qualified inz template;
  lineaTexto char(132) pos(1);
  abreviaturaProducto char(5) pos(2);
  importe char(15) pos(21);
  comision char(15) pos(37);
  total char(15) pos(53);
  establecimiento char(15) pos(69);
end-ds;

dcl-ds dsLineaTextoGranTotalMCTempl qualified inz template;
  lineaTexto char(132) pos(1);
  abreviaturaProducto char(5) pos(2);
  importe char(15) pos(21);
  comision char(15) pos(37);
  total char(15) pos(53);
end-ds;

dcl-ds dsFechaProcesoTempl qualified inz template;
  fechaProceso zoned(8:0) pos(1);              //ddmmyyyy (proceso)
  diaProceso zoned(2:0) pos(1);                //dd       (proceso)
  fechaProcesoFacturacion zoned(8:0) pos(9);   //ddmmyyyy (facturacion)
  diaFacturacion zoned(2:0) pos(9);           //dd
  MesProcesoFacturacion zoned(2:0) pos(11);    //mm       (facturacion)
  AnioProcesoFacturacion2 zoned(2:0) pos(15);  //yy  - 24 (facturacion)
  AnioProcesoFacturacion4 zoned(4:0) pos(13);  //yyyy-2024(facturacion)
  mesAnioProcesoFacturacion zoned(6:0) pos(11);//mmyyyy   (facturacion)
end-ds;

dcl-ds dsFapa88MCTempl qualified inz template;
  fpdat1 char(8);
  fpnues zoned(7:0);
  fpdat2 char(2);
  fptire char(1);
  fpnuso zoned(8:0);
  fpdat3 char(5);
  fpimpo zoned(9:0);
  fpdat4 char(6);
  fpfeco zoned(8:0);
  fpdico zoned(2:0);
  datos2 char(160);
  fcodge char(3);
  fnucr2 char(14);
  fcadin char(3);
  fpuren char(5);
  fsuren char(3);
  fbiren char(15);
  fommss char(4);
  fnopgm char(10);
  fnficm zoned(9:0);
  fntram char(15);
  frefor zoned(9:0);
  fsauna zoned(8:0);
  fntrmi char(20);
  fffami zoned(8:0);
  fenvsg char(1);
  festad char(1);
  fcomi0 char(2);
  fampli char(200);
end-ds;

dcl-ds dsFapa88MCTempl2 qualified inz;
  fpdat1 char(8);
  fpnues char(7);
  fpdat2 char(2);
  fptire char(1);
  fpnuso char(8);
  fpdat3 char(5);
  fpimpo Char(9);
  fpdat4 char(6);
  fpfeco Char(8);
  fpdico char(2);
  datos2 char(160);
  fcodge char(3);
  fnucr2 char(14);
  fcadin char(3);
  fpuren char(5);
  fsuren char(3);
  fbiren char(15);
  fommss char(4);
  fnopgm char(10);
  fnficm Char(9);
  fntram char(15);
  frefor Char(9);
  fsauna Char(8);
  fntrmi char(20);
  fffami Char(8);
  fenvsg char(1);
  festad char(1);
  fcomi0 char(2);
  fampli char(200);
end-ds;

dcl-ds dsDatos2Templ qualified inz template;
  datos2 char(160) pos(1);
  numAutorizacion zoned(3:0) pos(4);
  numPais zoned(3:0) pos(7);
  pldif zoned(2:0) pos(23);
  accionRecobro zoned(1:0) pos(31);
  cobro zoned(1:0) pos(40);
  penofa packed(5:0) pos(64);
  fncam char(5) pos(70);
  fdiapr zoned(2:0) pos(83);
  ptspts zoned(9:0) pos(85);
  monent char(1) pos(94);
  pseage char(5) pos(95);
  pagrup char(5) pos(100);
  pnubac zoned(10:0) pos(105);
  ptirel char(1) pos(115);
  pnbres char(4) pos(116);
  fendin char(6) pos(120);
  pdatco char(35) pos(126);
end-ds;

dcl-ds dsBSMCTempl qualified inz template;
  bcodre char(2);
  l7 char(3);
  bactiv zoned(2:0);
  bclapa char(1);
  bnumes zoned(7:0);
  bdigit zoned(1:0);
  bdupli char(1);
  bcodmo char(1);
  bnumre zoned(8:0);
  l1 char(5);
  bimpor zoned(9:0);
  l8 char(3);
  l2 char(2);
  l6 char(1);
  bfecon zoned(8:0);
  bdicon zoned(2:0);
  l3 char(1);
  lnumco zoned(5:0);
  bnupai char(3);
  l4 char(20);
  conpm zoned(1:0);
  l5 char(52);
  bdiapr zoned(2:0);
  bte130 zoned(8:0);
  bregem zoned(6:0);
  bbchre zoned(4:0);
  beuros zoned(9:0);
  bmoned char(1);
  bseaco zoned(5:0);
  boexco char(5);
  bnubas zoned(10:0);
  bcorel char(1);
  bresto zoned(4:0);
  bentdi zoned(6:0);
  bprofa zoned(8:0);
  bfreal zoned(6:0);
  bagenc zoned(4:0);
  bcruce char(15);
  btipop char(1);
  brenfe char(5);
  breemb char(10);
  bcodge char(3);
  bnucr2 char(14);
  bcadin char(3);
  blin1 char(59);
  blin2 char(59);
  blin3 char(59);
  bpuren char(5);
  bsuren char(3);
  bbiren char(15);
  bommss char(4);
  bnopgm char(10);
  bnficm zoned(9:0);
  bntram char(15);
  brefor zoned(9:0);
  bsauna zoned(8:0);
  bntrmi char(20);
  bffami zoned(8:0);
  benvsg char(1);
  bestad char(1);
  bcomi0 char(2);
  bampli char(200);
end-ds;

dcl-ds dsL5Templ qualified inz template;
  l5 char(52) pos(1);
  cero zoned(1:0) pos(1);
  codIrregularidad1 char(4) pos(2);
  numRecap zoned(4:0) pos(6);
  marcaCobro char(1) pos(10);
  actividadInternacional char(3) pos(16);
  numSocioInternacional char(14) pos(20);
  ctaAnualPteNoFacturado char(5) pos(34);
  fechaDevolAjuste char(5) pos(40);
  codIrregularidad2 char(4) pos(45);
  dosPrimerosDigitosTarjeta char(2) pos(49);
end-ds;

dcl-ds dsControFSMCTempl qualified inz template;
  txc char(1);
  tnumso zoned(8:0);
  tanual char(1);
  tdupli char(1);
  tsalso zoned(9:0);
  tlibr1 char(3);
  tlibr2 char(1);
  tsalpa zoned(9:0);
  tacrec zoned(1:0);
  tconfa zoned(1:0);
  tsacer zoned(1:0);
  tnotas zoned(3:0);
  tnoext zoned(1:0);
  tlibr3 char(1);
  tfepag zoned(8:0);
  tte130 zoned(8:0);
  tregem zoned(6:0);
  tpervi zoned(2:0);
  tplavi zoned(1:0);
  titueu zoned(10:0);
  trecib char(1);
  tsvieu zoned(9:0);
end-ds;

dcl-ds dsRecibosMCTempl qualified inz template;
  rnumso zoned(14:0);
  rnomso char(35);
  rnomba char(25);
  rdirba char(35);
  rlocba char(35);
  rzonba zoned(4:0);
  rnumcc char(13);
  rnomcc char(25);
  rpts zoned(9:0);
  rlibr1 char(3);
  rlibr2 char(2);
  rlibr5 char(1);
  rfecre zoned(8:0);
  rnumbc zoned(5:0);
  rlibr3 char(1);
  rregem zoned(6:0);
  rlibr4 char(3);
  raccre char(1);
  rnusuc zoned(4:0);
  rlibr6 char(1);
  rvtore zoned(8:0);
  rdiapr zoned(2:0);
  rvirpe zoned(2:0);
  rvirpl zoned(1:0);
  reuros zoned(9:0);
  rtiteu zoned(10:0);
  relim1 char(1);
end-ds;

dcl-ds dsMS_BILLFACTempl qualified inz template;
  FBNUREAL zoned(8:0);
  FBCOMISI zoned(5:3);
  FBFEEXT  zoned(8:0);
  FBFECPA  zoned(8:0);
  FBSALDOC zoned(9:2);
  FBINTERE zoned(9:2);
  FBSALDOF zoned(9:2);
end-ds;

dcl-ds dsAsifilenTempl qualified inz template;
  CAPUNT  Char(6);
  CCTAMA  Char(5);
  CCTAFI  Char(2);
  CCTAAU  Char(5);
  CCODIG  Zoned(3:0);
  CPROGR  Char(6);
  CFECON  Zoned(8:0);
  CDEHA   Char(1);
  CREFOP  Char(6);
  CFEVTO  Zoned(8:0);
  CCONCE  Char(30);
  CIMPOR  Zoned(14:3);
  CMONED  Char(1);
  CPROVI  Char(6);
  CTIPOP  Zoned(3:0);
  CTIPRO  Char(1);
  CCTANA  Char(20);
  CCODMA  Char(20);
  CREFDE  Char(20);
  CDDEPT  Char(20);
  CDANLT  Char(20);
  CDEBAN  Char(20);
  CDPERS  Char(20);
  CDGFIN  Char(20);
  CDIM06  Char(20);
  CDIM07  Char(20);
  CDIM08  Char(20);
end-ds;
dcl-ds dsCONCPVFTempl qualified inz template;
  BTARJE  zoned(8:0);
  BTIPOC  Char(2);
  BFEALT  zoned(8:0);
  BNPLAZ  zoned(2:0);
  BIMPOR  zoned(9:2);
  BNPLAP  zoned(2:0);
  BIMPOP  zoned(9:2);
  BFEULP  zoned(8:0);
  BFEVAB  zoned(8:0);
  BMOVAB  Char(2);
  BIMPAB  zoned(9:2);
  BTITAR  Char(3);
end-ds;
