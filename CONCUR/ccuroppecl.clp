/*************************************************************************/
/** ================================================================== */
/**  CONCUR EXPENSE :                                                  */
/**  OPERACIONES CRUZADAS PENDIENTES DE FACTURA                        */
/**  CONCUR -** PROCESO   FICTICIO   ***** PAVC  (&PROCESO = 'V')       */
/**  CONCUR -** PROCESO   REAL       ***** PA    (&PROCESO = ' ')       */
/** ================================================================== */
/*************************************************************************/
             PGM        &PROCESO
             DCL        VAR(&DATOS) TYPE(*CHAR) LEN(14) +
                          VALUE('CCUROPPE')
             DCL        VAR(&TEX)   TYPE(*CHAR) LEN(50)
             DCL        VAR(&FECHA)  TYPE(*CHAR) LEN(6)
             DCL        VAR(&NUMREG) TYPE(*DEC)  LEN(10 0)
             DCL        VAR(&PRIORID) TYPE(*DEC) LEN(1 0) VALUE(9) +
                          /* para fichero incidencias */
             DCL        VAR(&DESCRIP) TYPE(*CHAR) LEN(80)
             DCL        VAR(&PROCE) TYPE(*CHAR) LEN(10) +
                          VALUE('CCUROPPECL')
             DCL        VAR(&CODRE1) TYPE(*CHAR) LEN(1) VALUE(' ')
             DCL        VAR(&PROCESO)  TYPE(*CHAR) LEN(1)
             DCL        VAR(&RTCDE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&ACCION) TYPE(*CHAR) LEN(1)
             DCL        VAR(&MSG)   TYPE(*CHAR) LEN(300)

/*-----------------------------------------------------------------------*/
/*                     CARGAR SEGUIMIENTO DE CL'S                      */
/*-----------------------------------------------------------------------*/
             RTVJOBA    DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

             CALL       PGM(TRACE) PARM('**  CONCUR EXPENSE: ENVIO +
                          DE OPERACIONES PENDIENTES DE +
                          FACTURAR  V.C.I.    **' ' ' CCUROPPE)

 /*------------------------------------------------------------------*/
 /* CONTROL DESCUADRE CONTE1VCCL                                     */
 /*------------------------------------------------------------------*/
             CALL       PGM(PRFICCTL) PARM(&ACCION 'NOCONTE1VC')

             IF         COND(&ACCION = 'S') THEN(DO)

             CHGVAR     VAR(&MSG) VALUE('NO CUADRA EL REPAVC +
                          -CONTE1VCCL- 4001-')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('NO SE ENVIA FICHERO A CONCUR +
                          -CCUROPPECL-') LONGMSG(&MSG)

             GOTO       FINAL
             ENDDO
 /*------------------------------------------------------------------*/
 /* CONTROL TRABAJO EJECUTADO  --PRDIARIO Y PRDIARIOHI               */
 /*------------------------------------------------------------------*/
             CALL       PGM(PRDIACTL) PARM('A' 'CCUROPPE  ')
/*-----------------------------------------------------------------------*/
/*                       REARRANQUE AUTOMATICO                         */
/*-----------------------------------------------------------------------*/
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '01') +
                          THEN(GOTO CMDLBL(REA01))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '02') +
                          THEN(GOTO CMDLBL(REA02))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '03') +
                          THEN(GOTO CMDLBL(REA03))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '04') +
                          THEN(GOTO CMDLBL(REA04))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '05') +
                          THEN(GOTO CMDLBL(REA05))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '06') +
                          THEN(GOTO CMDLBL(REA06))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '07') +
                          THEN(GOTO CMDLBL(FINAL))

/*-----------------------------------------------------------------------*/
/*  COPIAS DE SEGURIDAD ANTES DE INICIAR PROCESO                         */
/*-----------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0071' ' ' CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, SISGESFOPE +
                          ANTES DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SISGESFOPE +
                          FICHEROS SISGESFOPE LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, SISGESOPE ANTES +
                          DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SISGESOPE +
                          FICHEROS SISGESOPE LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, BAGENCONVC +
                          ANTES DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BAGENCONVC +
                          FICHEROS BAGENCONVC LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, BAGENCONB +
                          ANTES DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BAGENCONB +
                          FICHEROS BAGENCONB LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, PAVC +
                          ANTES DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAVC +
                          FICHEROS PAVC LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, PA +
                          ANTES DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA +
                          FICHEROS PA LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, OPAGECO_VC +
                          ANTES DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(OPAGECO_VC +
                          FICHEROS OPAGECO_VC LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, OPAGECO_B +
                          ANTES DE INICIAR PROCESO.   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(OPAGECO_B +
                          FICHEROS OPAGECO_B LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)
/*-----------------------------------------------------------------------*/
/*       SISGESTRG - ACTUALIZA LA MARCA PARA ELEGIR PROCESO             */
/*  SE COLOCA EN COMENTARIO PARA EVITAR FALLA DE CONCUR (INDRA) 240712   */
/*-----------------------------------------------------------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' CCUROPPE) /* 01 */
/*-----------------------------------------------------------------------*/
/* SISTEMA DE GESTION                                                */
/*-----------------------------------------------------------------------*/
 REA01:      CALL       PGM(EXPLOTA/TRACE) PARM('PMG-CCUVCPPE1 EN +
                          EJECUCION ' ' ' CCUROPPE)

             CRTPF      FILE(FICHEROS/SISGESCCUR) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          C.I.: TARJETAS CON OPER.PDTES. DE +
                          ENVIAR') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/SISGESCCUR))

             CRTPF      FILE(FICHEROS/SISGESCFAC) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          C.I.: TARJETAS CON OPER.PDTES. DE +
                          ENVIAR') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/SISGESCFAC))

/* CONCUR -VECI   ** PROCESO   FICTICIO   ***** PAVC          */

             IF         COND(&PROCESO = 'V') THEN(DO)
             CALL       PGM(EXPLOTA/SISGESGENS) PARM('V')
             ENDDO

/* CONCUR -VECI   ** PROCESO   REAL       ***** PA            */

             IF         COND(&PROCESO = ' ') THEN(DO)
             CALL       PGM(EXPLOTA/SISGESGENP) PARM(' ')
             ENDDO

/*-----------------------------------------------------*/
/*- ¿HAY TARJETAS CON OPERACIONES PENDIENTES DE ENVIAR */
/*-----------------------------------------------------*/
             RTVMBRD    FILE(FICHEROS/SISGESCCUR) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG = 0) THEN(DO)

             CALL       PGM(TRACE) PARM(' FICHERO PARA -CONCUR- ESTA +
                          VACIO, NO HAY ENVIO.' ' ' CCUROPPE)

             CHGVAR     VAR(&DESCRIP) VALUE('FICHERO PARA -CONCUR- +
                          ESTA VACIO, NO HAY ENVIO.-CCUROPPE-')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             GOTO       CMDLBL(FINAL)
             ENDDO


             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' CCUROPPE) /* 02 */
/*-----------------------------------------------------------------------*/
/*  CCUROPPE2  POR TIPO OPERAC.SELECCIONA FORMATO. CREA -CONCUR_OUT-   */
/*-----------------------------------------------------------------------*/
 REA02:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                     PMG-CCUROPPE2 +
                          EN EJECUCION            ' ' ' CCUROPPE)

             CRTLF      FILE(FICHEROS/PACONLGSG) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -PAVC-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/OPAGEVCLG7) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -OPAGECO_VC-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/OPGENXDL4) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -OPGENXD-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/OPLAEXBL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -OPLAEXB-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)


             CRTLF      FILE(FICHEROS/PACONLGSGV) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -') OPTION(*NOLIST *NOSRC) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000)

  /*--------------------------------*/
  /* Fichero para enviar a CONCUR */
  /*--------------------------------*/

             CRTPF      FILE(FICHEROS/CONCUR_OUT) RCDLEN(2580) +
                          TEXT('CONCUR: FICHERO CON OPERAC. +
                          FACTURADAS PARA ENVIAR') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CONCUR_OUT))

  /*--------------------------------*/
  /* Fichero Extructuras Externas */
  /*--------------------------------*/
             /*CRTPF      FILE(FICHEROS/CCURFR100) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-100 DATOS TITULAR') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR100))*/

             /*CRTPF      FILE(FICHEROS/CCURFR200) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-200 DATOS OPERACION') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR200))*/

             /*CRTPF      FILE(FICHEROS/CCURFR201) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-201 DATOS CAJEROS') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR201))*/

             /*CRTPF      FILE(FICHEROS/CCURFR301) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-301 DATOS ALQUILER +
                          COCHES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR301))*/

             /*CRTPF      FILE(FICHEROS/CCURFR302) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-302 DATOS HOTELES +
                          CABEC.') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR302))*/

             /*CRTPF      FILE(FICHEROS/CCURFR303) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-303 DATOS VIAJES +
                          CABECERAS') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR303))*/

             /*CRTPF      FILE(FICHEROS/CCURFR304) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-304 DATOS VIAJES +
                          DETALLES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR304))*/

             /*CRTPF      FILE(FICHEROS/CCURFR305) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-305 DATOS COMPRAS +
                          CABEC.') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR305))*/

             /*CRTPF      FILE(FICHEROS/CCURFR306) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-306 DATOS COMPRAS +
                          DETALLES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR306))*/

             /*CRTPF      FILE(FICHEROS/CCURFR307) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-307 DATOS HOTELES +
                          DETALLES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR307))*/

             /*CRTPF      FILE(FICHEROS/CCURFR400) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-400 DATOS DE FACTURACION +
                          C') OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR400))*/

             /*CRTPF      FILE(FICHEROS/CCURFR401) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONCUR +
                          EXPENSE: FORMATO-401 DATOS DE FACTURACION +
                          D') OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/CCURFR401))*/

  /*-------------------------------------------------------------*/
  /*  LLAMADA A PROGRAMA'S (Formatos) SEGUN TIPO DE OPERACION  */
  /*  -------------------------------------------------------  */
  /*  Nota: Desde pgm-CCUROPPE2    llama a los siguiente pgm's */
  /*  Siempre por Tarjeta   PGM-CCURDATI  --> Datos Titular    */
  /*  Siempre por Operacion PGM-CCURDAOPP --> Datos Operación  */
  /*  RR (FERROCARRILES)    PGM-CCURPMVI1                      */
  /*  RA (LINEAS AEREAS)    PGM-CCURPMVI2                      */
  /*  RV (ALQ.COCHES)       PGM-CCURPMAC                       */
  /*  RH (HOTELES)          PGM-CCURPMHO                       */
  /*-------------------------------------------------------------*/

/* CONCUR -VECI   ** PROCESO   FICTICIO   ***** PAVC          */

             IF         COND(&PROCESO = 'V') THEN(DO)
             CALL       PGM(EXPLOTA/CCUROPPE2) PARM('V')
             ENDDO

/* CONCUR -VECI   ** PROCESO   REAL       ***** PA            */

             IF         COND(&PROCESO = ' ') THEN(DO)
             CALL       PGM(EXPLOTA/CCUROPPE2) PARM(' ')
             ENDDO

/*--------------------------------*/
/*- ¿HAY REGISTROS PARA ENVIAR ? -*/
/*--------------------------------*/
             RTVMBRD    FILE(FICHEROS/CONCUR_OUT) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG = 0) THEN(DO)

             CALL       PGM(TRACE) PARM(' FICHERO PARA -CONCUR CORTE +
                          INGLES ESTA VACIO, NO HAY ENVIO. ' ' ' +
                          CCUROPPE)

             CHGVAR     VAR(&DESCRIP) VALUE('FICHERO PARA -CONCUR +
                          CORTE INGLES- ESTA VACIO, NO HAY +
                          ENVIO.-CCUROPPE-')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             GOTO       CMDLBL(FINAL)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' CCUROPPE) /* 03 */
/*-----------------------------------------------------------------------*/
/*  SISGESCUEN  CUADRE DE OPERACIONES ENVIADAS                         */
/*-----------------------------------------------------------------------*/
 REA03:      CALL       PGM(EXPLOTA/SISGESCUEN) PARM(&CODRE1)

/*--------------------------------*/
/*- ¿CUADRAN REGISTROS       R ? -*/
/*--------------------------------*/

             IF         (&CODRE1 = '1') THEN(DO)

             CALL       PGM(TRACE) PARM(' HAY DESCUADRES EN EL ENVIO +
                          DE OPERARCIONES A CONCUR **INVESTIGAR   +
                          FIN. ' ' ' CCUROPPE)

             CHGVAR     VAR(&DESCRIP) VALUE('HAY DESCUADRES EN EL +
                          ENVIO DE OPERARCIONES A CONCUR +
                          **INVESTIGAR   FIN.')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((grupoas400@dinersclub.es *PRI)) +
                          DSTD('DESCUADRE EN REGISTROS ENVIADOS +
                          *CCUROPPECL') LONGMSG('DESCUADRE EN +
                          REGISTROS ENVIADOS OPERACIONES DEL +
                          SISGESOPE FECHA DE HOY Y EL FICHERO +
                          GENERADO CONCUR_OUT')

             GOTO       CMDLBL(FINAL)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' CCUROPPE) /* 04 */
/*-----------------------------------------------------------------------*/
/*  CPXX        CREACION FICHEROS POR CLIENTES PARA SU ENVIO           */
/*-----------------------------------------------------------------------*/
 REA04:      CALL       PGM(EXPLOTA/TRACE) PARM('CREACION FICHERO/S  +
                          POR CLIENTE  PARA SU ENVIO' ' ' CCUROPPE)

             CRTLF      FILE(FICHEROS/SISGESCFLG) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CALL       PGM(EXPLOTA/CCONCURFIC)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' CCUROPPE) +
                          /* 05 */
/*-----------------------------------------------------------------------*/
/*  CPXX        ENVIO DE FICHEROS A MICROINFORMATICA                   */
/*-----------------------------------------------------------------------*/
 REA05:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                     ENVIAR E-MAIL +
                          CON FICHERO ADJUNTO     ' ' ' CCUROPPE)

          /* CONCUR         ** PROCESO   FICTICIO   */

             IF         COND(&PROCESO = 'V') THEN(DO)
             CALL       PGM(EXPLOTA/ENVCCURVCV) PARM(&RTCDE)
             ENDDO

          /* CONCUR         ** PROCESO   REAL       */

             IF         COND(&PROCESO = ' ') THEN(DO)
             CALL       PGM(EXPLOTA/ENVCCURVCP) PARM(&RTCDE)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' CCUROPPE) /* 06 */
/*-----------------------------------------------------------------------*/
/*  COPIAS DE SEGURIDAD POR FIN DE PROCESO                               */
/*-----------------------------------------------------------------------*/
REA06:       CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0062' ' ' CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL,SISGESOPE   POR +
                          FINALIZACION DE PROCESO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SISGESOPE +
                          FICHEROS SISGESOPE LIBSEG1D C ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, sisgescfac POR +
                          FINALIZACION DE PROCESO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SISGESCFAC +
                          FICHEROS SISGESCFAC LIBSEG1D M ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, CONCUR_OUT POR +
                          FINALIZACION DE PROCESO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONCUR_OUT +
                          FICHEROS CONCUR_OUT LIBSEG1D M ' ' ' ' +
                          &TEX CCUROPPE)

             CHGVAR     VAR(&TEX) VALUE('CCUROPPECL, SISGESCCUR POR +
                          FINALIZACION DE PROCESO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SISGESCCUR +
                          FICHEROS SISGESCCUR LIBSEG1D M ' ' ' ' +
                          &TEX CCUROPPE)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' CCUROPPE) /* 07 */
/*-----------------------------------------------------------------------*/
/*                        --FIN DE PROCESO--                             */
/*-----------------------------------------------------------------------*/
 FINAL:      CALL       PGM(PRDIACTL) PARM('B' 'CCUROPPE  ')


             D1         LABEL(SISGESCFLG) LIB(FICHEROS)

             CALL       PGM(TRACE) PARM('FIN' ' ' 'CCUROPPE')
             ENDPGM
