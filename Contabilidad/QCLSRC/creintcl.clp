 /*****************************************************************/
 /*  CREACION DEL INTER A PARTIR DE LA BOLSA INTERNACIONAL        */
 /*****************************************************************/
             PGM        PARM(&ELECT &NUMORD)
             DCL        VAR(&ELECT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NUMORD) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&NUMREG) TYPE(*DEC) LEN(10 0)
             DCL        VAR(&REST1) TYPE(*CHAR) LEN(10) /*ESTFACMEmm*/
             DCL        VAR(&REST2)    TYPE(*CHAR) LEN(6)
             DCL        VAR(&REST3) TYPE(*CHAR) LEN(10) /*ESTFACGNmm*/
             DCL        VAR(&ESTIN)    TYPE(*CHAR) LEN(10)
             DCL        VAR(&ETIQUET1) TYPE(*CHAR) LEN(2)
             DCL        VAR(&ETIQUET2) TYPE(*DEC)  LEN(2)
             DCL        VAR(&IMOV)     TYPE(*CHAR) LEN(10)
             DCL        VAR(&IMOVMAL)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&DATOS) TYPE(*CHAR) LEN(14) +
                          VALUE('CREINTCL')
             DCL        VAR(&FECHA1)   TYPE(*CHAR) LEN(6)
             DCL        VAR(&FECHA)    TYPE(*CHAR) LEN(6)
             DCL        VAR(&TEX)      TYPE(*CHAR) LEN(50)
             DCL        VAR(&RTCDE)  TYPE(*CHAR) LEN(1)

             DCL        VAR(&PRIORID) TYPE(*DEC) LEN(1 0) VALUE(9) +
                          /* para fichero incidencias */
             DCL        VAR(&DESCRIP) TYPE(*CHAR) LEN(80)
             DCL        VAR(&PROCE) TYPE(*CHAR) LEN(10) +
                          VALUE('CREINTCL')
             DCL        VAR(&MSG) TYPE(*CHAR) LEN(250)
             DCL        VAR(&NOMPARA) TYPE(*CHAR) LEN(10)
/*-----------------------------------------------*/
/*    COMENZAR TRACES                            */
/*-----------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROCESO PARA CREAR +
                          UN IMOVxx CON LA FACTURACION RECIBIDA DEL +
                          DCISC.           ' ' ' CREINTCL)
 /*------------------------------------------------------------------*/
 /*                  REARRANQUE AUTOMATICO                           */
 /*------------------------------------------------------------------*/
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '01') +
                          THEN(GOTO CMDLBL(UNO))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '02') +
                          THEN(GOTO CMDLBL(DOS))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '03') +
                          THEN(GOTO CMDLBL(TRES))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '04') +
                          THEN(GOTO CMDLBL(CUATRO))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '05') +
                          THEN(GOTO CMDLBL(CINCO))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '06') +
                          THEN(GOTO CMDLBL(SEIS))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '07') +
                          THEN(GOTO CMDLBL(SIETE))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '08') +
                          THEN(GOTO CMDLBL(OCHO))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '09') +
                          THEN(GOTO CMDLBL(NUEVE))
 /*------------------------------------------------------------------*/
             CALL       PGM(PRDIACTL) PARM('A' 'CREINTCL  ')
 /*------------------------------------------------------------------*/
 /*                      RECIBE FECHA DEL SISTEMA                    */
 /*------------------------------------------------------------------*/

             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&FECHA)

             CHGVAR     VAR(&FECHA1) VALUE(&FECHA)
             CHGJOB     DATE(&FECHA1)
/*-----------------------------------------------*/
/*      VER SI HAY REGISTROS PARA FAC.INTER      */
/*-----------------------------------------------*/
             CHGJOB     SWS(00000000)
/*---*/
             RTVMBRD    FILE(FICHEROS/IMOVFAC) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG = 0) THEN(DO)

             GOTO       CMDLBL(SALE)
             ENDDO

/*                                                                  */
/*          Primer día del Mes: Controla si esta ESTFACMExx"        */
/*          Primer día del Mes: Controla si esta ESTFACGNxx"        */
/*                                                                  */

             CHGVAR     VAR(&REST1) VALUE('ESTFACME' *CAT +
                          (%SUBSTRING(&FECHA1 3 2)))
             CHKOBJ     OBJ(FICHEROS/&REST1) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(CRTPF +
                          FILE(FICHEROS/&REST1) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(ESTFACME) TEXT('Datos Informes +
                          Estadisticos Diarios') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL))
/*---*/
             CHGVAR     VAR(&REST3) VALUE('ESTFACGN' *CAT +
                          (%SUBSTRING(&FECHA1 3 2)))
             CHKOBJ     OBJ(FICHEROS/&REST3) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(CRTPF +
                          FILE(FICHEROS/&REST3) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(ESTFACGN) TEXT('Datos Informes +
                          Estadisticos, GLOBAL-NET') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL))
/*------------------------------------------------------------------*/
/*                 CARGA NUMERO DE IMOVXX                           */
/*------------------------------------------------------------------*/
             CHGVAR     VAR(&ETIQUET2) VALUE(0)
 REST:       IF         COND(&ETIQUET2 *EQ 99) THEN(GOTO +
                          CMDLBL(PANTA))
             CHGVAR     VAR(&ETIQUET2) VALUE(&ETIQUET2 + 1)
             CHGVAR     VAR(&ETIQUET1) VALUE(&ETIQUET2)
             CHGVAR     VAR(&IMOV) VALUE('          ')
             CHGVAR     VAR(&IMOV) VALUE('IMOV' *CAT &ETIQUET1)
             CHKOBJ     OBJ(FICHEROS/&IMOV) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(PANTA))
             GOTO       REST
/*--------------------------------------------*/
/* COPIA SEGURIDAD POR SI HAY PROBLEMAS       */
/*--------------------------------------------*/
 PANTA:      CALL       PGM(EXPLOTA/TRACE) PARM('Con estas copias se +
                          podrian dejar los ficheros como estaban +
                          antes de este CL. ' ' ' CREINTCL)

             CHGVAR     VAR(&TEX) VALUE('CREINTCL, COPIA PRINCIPIO +
                          PROCESO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(IMOVFAC FICHEROS +
                          IMOVFAC LIBSEG1D C ' ' ' ' &TEX CREINTCL)

             CRTPF      FILE(FICHEROS/DESCSAL) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DESCRFAC) OPTION(*NOSRC *NOLIST) +
                          LVLCHK(*NO) AUT(*ALL)

             CRTPF      FILE(FICHEROS/MISBSAL) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(MISBOLSA) OPTION(*NOSRC *NOLIST) +
                          LVLCHK(*NO) AUT(*ALL)

             CALL       PGM(EXPLOTA/CODEIN)

             CHGVAR     VAR(&TEX) VALUE('CREINTCL, DESPUES DEL +
                          PGM-CODEIN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DESCSAL FICHEROS +
                          DESCSAL LIBSEG1D M ' ' ' ' &TEX CREINTCL)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MISBSAL FICHEROS +
                          MISBSAL LIBSEG1D M ' ' ' ' &TEX CREINTCL)
             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*-----------------------------*/
/*  CREIN3 / CREIN2 /          */
/*-----------------------------*/
 UNO:        CRTPF      FILE(FICHEROS/ASIATM) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('Asiento Regularizacion Gastos +
                          Comisiones Caixa') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIATM))

             CRTLF      FILE(FICHEROS/IMOVXXL1) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000

             CRTLF      FILE(FICHEROS/IMOVXXL2) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000

             CRTLF      FILE(FICHEROS/IMOVXXL3) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000

             CRTLF      FILE(FICHEROS/IMOXXL33) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000

             CRTLF      FILE(FICHEROS/IMOVXXL4) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000
/*----------------------------------*/
/* COPIA ANTES DE ACTULIZAR REMESA  */
/*----------------------------------*/

             CHGVAR     VAR(&TEX) VALUE('CREINTCL,ANTES BORRAR OPER. +
                          ACTUALIZAR REMESA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(IMOVFAC FICHEROS +
                          IMOVFAC LIBSEG1D C ' ' ' ' &TEX CREINTCL)

             OVRDBF     FILE(IMOVXX) TOFILE(FICHEROS/IMOVFAC)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  CREIN3  +
                          EN EJECUCION' ' ' CREINTCL)
             CALL       PGM(EXPLOTA/CREIN3)

/*----------------------------------*/
/* BORRAR OPERACIONES 832           */
/* ACTUALIZAR IMPORTE DE REMESA     */
/*----------------------------------*/

             CALL       PGM(EXPLOTA/CREIN832)

/*----------------------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  CREIN2  +
                          EN EJECUCION' ' ' CREINTCL)
             CL1        LABEL(PAPELIN) LIB(FICHEROS) LON(132)
             OVRPRTF    FILE(IMP0017) TOFILE(FICHEROS/PAPELIN)

             CALL       PGM(EXPLOTA/CREIN2)
             DLTOVR     FILE(*ALL)

/*-----------------------------*/
/* PROCESO DEL APUNTE CONTABLE */
/*-----------------------------*/
             IF         COND(%SWITCH(XXXXXXX1)) THEN(DO)
             OVRDBF     FILE(ASIFILE) TOFILE(ASIATM)
             CALL       PGM(EXPLOTA/ACASBO) PARM('007')
             CHGVAR     VAR(&TEX) VALUE('CREINTCL, SALIDO DEL CREIN3')
             CALL       PGM(CONCOPCL) PARM(ASIATM FICHEROS +
                          ASIATM LIBSEG1D M ' ' ' ' &TEX CREINTCL)
             DLTOVR     FILE(ASIFILE)
             ENDDO

             DLTF       FILE(FICHEROS/ASIATM)
             MONMSG     MSGID(CPF0000)
/*-------------------*/
/* CREACION FICHEROS */
/*-------------------*/
             DLTF       FILE(FICHEROS/IMOVXXLG2)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/IMOVXXLG2) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)

             CRTPF      FILE(FICHEROS/&IMOV) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(IMOVXX) +
                          TEXT('facturacion internacional -imov-') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)

             DLTF       FILE(IMOVFACPY)
             MONMSG     MSGID(CPF0000)
             CRTDUPOBJ  OBJ(IMOVFAC) FROMLIB(FICHEROS) +
                          OBJTYPE(*FILE) NEWOBJ(IMOVFACPY) DATA(*YES)

             CL1        LABEL(PAPELI1) LIB(FICHEROS) LON(132)
             CL1        LABEL(PAPELI2) LIB(FICHEROS) LON(132)

             OVRDBF     FILE(IMOV) TOFILE(*LIBL/&IMOV)
             OVRDBF     FILE(IMOVXX) TOFILE(*LIBL/IMOVXXLG2)
             OVRPRTF    FILE(IMP10P7) TOFILE(FICHEROS/PAPELI1)
             OVRPRTF    FILE(IMP00P7) TOFILE(FICHEROS/PAPELI2)

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  CREINT  EN EJECUCION' ' ' CREINTCL)

             CALL       PGM(*LIBL/CREINT) PARM(&RTCDE)

             DLTOVR     FILE(IMP00P7)
             DLTOVR     FILE(IMP10P7)
             DLTOVR     FILE(MSOCIO)
             MONMSG     MSGID(CPF0000)

/*---------------------------------------------*/
/* NO CUADRA REMESA CONTRA CARGO DE LO MARCADO */
/*---------------------------------------------*/
             IF         COND(&RTCDE *EQ '2') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('Fichero NO CUADRA +
                          NO se procesa' ' ' CREINTCL)
             CALL       PGM(EXPLOTA/TRACE) PARM('Se CANCELA trabajo +
                          ' ' ' CREINTCL)

             CHGVAR     VAR(&DESCRIP) VALUE('Fichero -NO CUADRA  +
                          -SERVICE CENTER-- NO SE PROCESA -ver File +
                          PAPELI1')


             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)
             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('PROCESO -CREINTCL') +
                          LONGMSG(&MSG)

             CHGVAR     VAR(&PRIORID) VALUE(9)

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&TEX) VALUE('CREINTCL, ERROR CUADRE ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(IMOVFAC FICHEROS +
                          IMOVFAC LIBSEG1D M ' ' ' ' &TEX CREINTCL)

             CHGVAR     VAR(&IMOVMAL) VALUE('IMOVMAL' *TCAT &ETIQUET1)
MOV_MAL:     RNMOBJ     OBJ(&IMOV) OBJTYPE(*FILE) NEWOBJ(&IMOVMAL)
             MONMSG     MSGID(CPF3201) EXEC(DO)
             IF         COND(&ETIQUET2 *LT 99) THEN(DO )
             CHGVAR     VAR(&ETIQUET2) VALUE(&ETIQUET2 + 1)
             CHGVAR     VAR(&ETIQUET1) VALUE(&ETIQUET2)
             CHGVAR     VAR(&IMOVMAL) VALUE('IMOVMAL' *TCAT &ETIQUET1)
             GOTO       MOV_MAL
             ENDDO
             ENDDO
             GOTO       CMDLBL(SALE)
             ENDDO

/*---------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('CREINTCL, DESPUES DE +
                          PGM-CREINT  ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(IMOVFAC FICHEROS +
                          IMOVFAC LIBSEG1D C ' ' ' ' &TEX CREINTCL)
             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*------------------*/
/*  I N T E 0 4     */
/*------------------*/
DOS:         CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  INTE04  EN EJECUCION' ' ' CREINTCL)

             CALL       PGM(EXPLOTA/INTE04)

             FMTDTA     INFILE((FICHEROS/&IMOV)) +
                          OUTFILE(FICHEROS/&IMOV) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(SINTE55) +
                          OPTION(*NOPRT)

             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*------------------*/
/*  I N T E 5 5     */
/*------------------*/
 TRES:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  INTE55  EN EJECUCION' ' ' CREINTCL)

             CHGVAR     VAR(&ESTIN) VALUE('          ')
             CHGVAR     VAR(&ESTIN) VALUE('ESTINTE' *CAT &ETIQUET1)

             CRTPF      FILE(FICHEROS/&ESTIN) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(ESTFACVA) TEXT('ESTADISTICAS +
                          -FACT.INTERNACIONAL-') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)

  /* ASTERISCADO POR PROBLEMAS EL 14/9/2023           */
  /* PREFERIMOS QUE NOS AVISE DEL PROCESO (DEMOMENTO) */
  /*         MONMSG     MSGID(CPF0000) EXEC(CLRPFM +  */
  /*                      FILE(FICHEROS/&ESTIN))      */

 ARRI:       ALCOBJ     OBJ((FICHEROS/&ESTIN *FILE *EXCL))
             MONMSG     CPF0000 *NONE EXEC(DO)

             GOTO       ARRI
             ENDDO

             OVRDBF     FILE(ESTFACVA) TOFILE(FICHEROS/&ESTIN)
             OVRPRTF    FILE(QSYSPRT) OUTQ(P9) SAVE(*YES)
             CALL       PGM(EXPLOTA/INTE55)
             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*-------------------------------------------------------------------*/
/*            ACUMULACION AL ESTFACME -ESTAF2-  (ESTINTE'S)          */
/*-------------------------------------------------------------------*/
CUATRO:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  ESTAF2  EN EJECUCION' ' ' CREINTCL)

             CHGVAR     VAR(&REST1) VALUE('          ')
             CHGVAR     VAR(&REST2) VALUE('      ')
             CHGVAR     VAR(&REST1) VALUE('ESTFACME' *CAT +
                          (%SUBSTRING(&FECHA1 3 2)))
             CHGVAR     &REST2 VALUE('INTE' *CAT &ETIQUET1)
             CHGVAR     VAR(&REST3) VALUE('ESTFACGN' *CAT +
                          (%SUBSTRING(&FECHA1 3 2)))

             OVRDBF     FILE(ESTFACME) TOFILE(FICHEROS/&REST1)
             OVRDBF     FILE(ESTFACGN) TOFILE(FICHEROS/&REST3)
             CALL       PGM(EXPLOTA/ESTAF2) PARM(&REST2)
             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*---------------*/
/*  A P U N 0 1  */
/*---------------*/
CINCO:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  APUN01  EN EJECUCION' ' ' CREINTCL)

     /*--------------------------------------------------------*/
     /*    Nueva version del APUN01 (APUN01N)             LM   */
     /*--------------------------------------------------------*/

      CALL       PGM(EXPLOTA/APUN01NCL) PARM(&IMOV 'CREINTCL')

     /*--------------------------------------------------------*/

             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*---------------*/
/* LIBRE  LIBRE  */
/*---------------*/
SEIS:

             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*---------------*/
/*  ACASBO       */
/*---------------*/
SIETE:       

             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*---------------*/
/*  ASINUM       */
/*---------------*/
OCHO:        CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  ASINUM  EN EJECUCION' ' ' CREINTCL)

             CALL       PGM(EXPLOTA/ASINUM)
             CALL       PGM(EXPLOTA/TRACE) PARM('Comprobar que se +
                          han acumulado al totales los asientos del +
                          internacional.' ' ' CREINTCL)
             CALL       PGM(EXPLOTA/TRACE) PARM('Puede haber alguna +
                          pequeña diferencia, esto no significa que +
                          este mal.        ' ' ' CREINTCL)
 /*---*/
             DLTOVR     FILE(ASIFIVA)
             DLTOVR     FILE(ASIFILE)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASICXINTER +
                          FICHEROS ASICXINTER LIBSEG1D M ' ' ' ' +
                          &TEX CREINTCL)
             DLTF       FILE(FICHEROS/IMOVXXL5)
             MONMSG     CPF0000
             DLTF       FILE(IMOVFACPY)
             MONMSG     CPF0000
             CALL       PGM(TRACE) PARM('+1' ' ' CREINTCL)
/*-----------------------------------------------------*/
/*--     COPIAS: ESTINTExx / ESTFACMExx / IMOVxx     --*/
/*-----------------------------------------------------*/
NUEVE:       DLCOBJ     OBJ((FICHEROS/&ESTIN *FILE *EXCL))
             CHGVAR     VAR(&TEX) VALUE('CREINTCL, DESPUES DEL +
                          RPG.INTE55')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&ESTIN FICHEROS +
                          &ESTIN LIBSEG1D M ' ' ' ' &TEX CREINTCL)

             CHGVAR     VAR(&TEX) VALUE('CREINTCL, DESPUES DEL +
                          RPG.ESTAF2')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&REST3 FICHEROS +
                          &REST3 LIBSEG1D C ' ' ' ' &TEX CREINTCL)

             DLTOVR     FILE(*ALL)

             RNMOBJ     OBJ(FICHEROS/&IMOV) OBJTYPE(*FILE) NEWOBJ(IMOV)

             STRCMTCTL  LCKLVL(*CHG)
             CALL       PGM(OPE_CRT1) PARM(('CREINTCL') (&IMOV) +
                          ('IMOV') ('IMOV') ('FICHEROS'))
             MONMSG     MSGID(CPF0000 RPG0000) EXEC(ROLLBACK)
             COMMIT
             ENDCMTCTL

             CHGVAR     VAR(&TEX) VALUE('CREINTCL, DESPUES DEL +
                          PGM-INTE55')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(IMOV FICHEROS +
                          &IMOV LIBSEG1D C ' ' ' ' &TEX CREINTCL)
             RNMOBJ     OBJ(FICHEROS/IMOV) OBJTYPE(*FILE) NEWOBJ(&IMOV)
 /* Lista tabulaso de inter por consumo mensual P9  Peticion contabilidad   */

             CRTPF      FILE(FICHEROS/INTERXX) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/INTERXX))
             CPYF       FROMFILE(FICHEROS/&IMOV) +
                          TOFILE(FICHEROS/INTERXX) MBROPT(*REPLACE) +
                          FMTOPT(*NOCHK)
             RUNQRY     QRY(EXPLOTA/TABINTER)
             DLTF       FILE(FICHEROS/INTERXX)
/*-------------------------------------------------------------------*/
/*                        ENVIO SPOLES  POR FICHEROS                 */
/*-------------------------------------------------------------------*/
             CL1        LABEL(RECIBIIN) LON(132)

/*-----------------------------*/
             RTVMBRD    FILE(FICHEROS/PAPELIN) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 3 ) THEN(DO)
             CPYF       FROMFILE(FICHEROS/PAPELIN) TOFILE(RECIBIIN) +
                          MBROPT(*ADD) FMTOPT(*NOCHK)
             ENDDO
/*-----------------------------*/
             RTVMBRD    FILE(FICHEROS/PAPELI1) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 3 ) THEN(DO)
             CPYF       FROMFILE(FICHEROS/PAPELI1) TOFILE(RECIBIIN) +
                          MBROPT(*ADD) FMTOPT(*NOCHK)
             ENDDO
/*-----------------------------*/
             RTVMBRD    FILE(FICHEROS/PAPELI2) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 3 ) THEN(DO)
             CPYF       FROMFILE(FICHEROS/PAPELI2) TOFILE(RECIBIIN) +
                          MBROPT(*ADD) FMTOPT(*NOCHK)
             ENDDO
/*-----------------------------*/

             CHGVAR     VAR(&TEX) VALUE('PROCESO  FACTURACION  +
                          SERVICE CENTER')

             DLTDLO     DLO(RECIBIIN) FLR(VARMAIL)
             MONMSG     MSGID(CPF0000)

             CPYTOPCD   FROMFILE(FICHEROS/RECIBIIN) TOFLR(VARMAIL) +
                           REPLACE(*YES)

             SNDDST     TYPE(*DOC) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD(&TEX) MSG(&TEX) DOC(RECIBIIN) +
                          FLR(VARMAIL)

             SNDDST     TYPE(*DOC) +
                          TOINTNET((cdfacturacion@dinersclub.es)) +
                          DSTD('PROCESADO   SERVICE CENTER') +
                          MSG('PROCESADO   SERVICE CENTER') +
                          DOC(RECIBIIN) FLR(VARMAIL)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECIBIIN FICHEROS +
                          RECIBIIN LIBSEG1D C ' ' ' ' &TEX BSPDIACL)

             CHGVAR     VAR(&TEX) VALUE('CREINTCL, FIN DEL PROCESO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(IMOVFAC FICHEROS +
                          IMOVFAC LIBSEG1D M ' ' ' ' &TEX CREINTCL)
/*---------------*/
/*  F I N        */
/*---------------*/
SALE:        D1         LABEL(IMOVXXLG2) LIB(FICHEROS)
             D1         LABEL(IMOVXXL1) LIB(FICHEROS)
             D1         LABEL(IMOVXXL2) LIB(FICHEROS)
             D1         LABEL(IMOVXXL3) LIB(FICHEROS)
             D1         LABEL(IMOXXL33) LIB(FICHEROS)
             D1         LABEL(IMOVXXL4) LIB(FICHEROS)
             D1         LABEL(FCREINT) LIB(SERVISEG)
             CHGJOB     SWS(00000000)
 /*------------------------------------------------------------------*/
             CALL       PGM(PRDIACTL) PARM('B' 'CREINTCL  ')
/*-----------------------------*/
             CALL       PGM(TRACE) PARM('FIN    GUARDA ' ' ' +
                          'CREINTCL')
             ENDPGM