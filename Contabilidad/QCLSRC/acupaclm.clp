 /********************************************************************/
 /*     ---------------------------------------------------------    */
 /*           DESDE -BLONAC/BLOQINTE- ADICION DIARIA A -PA-          */
 /*           DESDE -BLOMASTER      - ADICION DIARIA A -PA-          */
 /*     ---------------------------------------------------------    */
 /********************************************************************/
             PGM        PARM(&CPO1)
             DCL        VAR(&ACCION) TYPE(*CHAR) LEN(1)
             DCL        VAR(&DATOS)  TYPE(*CHAR) LEN(14) +
                          VALUE('ACUPACL')
             DCL        VAR(&TEX)    TYPE(*CHAR) LEN(50)
             DCL        VAR(&FECPRO) TYPE(*CHAR) LEN(6)
             DCL        VAR(&CODRET) TYPE(*CHAR) LEN(1)
             DCL        VAR(&ERRORMC) TYPE(*CHAR) LEN(1)
             DCL        VAR(&CLIB)   TYPE(*CHAR) LEN(10)
             DCL        VAR(&LABEL)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&SECU)   TYPE(*DEC)  LEN(4 0) VALUE(0000)
             DCL        VAR(&CPO1)   TYPE(*CHAR) LEN(6)
             DCL        VAR(&NUMREG) TYPE(*DEC)  LEN(10 0)

             DCL        VAR(&DD)     TYPE(*CHAR) LEN(2)
             DCL        VAR(&MM)     TYPE(*CHAR) LEN(2)

             DCL        VAR(&CLAVES) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')
             DCL        VAR(&AGRUP1) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')
             DCL        VAR(&AGRUP2) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')

             DCL        VAR(&PRIORID) TYPE(*DEC) LEN(1 0) VALUE(9) +
                          /* para fichero incidencias */
             DCL        VAR(&DESCRIP) TYPE(*CHAR) LEN(80) /* para +
                          fichero incidencias */
             DCL        VAR(&PROCE) TYPE(*CHAR) LEN(10) +
                          VALUE('ACUPACL   ') /* /fichero de +
                          incidencias */
             DCL        VAR(&DESCTOT) TYPE(*CHAR) LEN(200) /* para +
                          ENVIO mensaje del incidencias al CONTROL-M */

             DCL        VAR(&NOCUA)  TYPE(*CHAR) LEN(1)
             DCL        VAR(&TOTCUA) TYPE(*DEC) LEN(11 0)
             DCL        VAR(&MSG)    TYPE(*CHAR) LEN(128) VALUE(' ')
             /* SE HA COPIADO BLOMASTER A BLOMASTERH */
             DCL        VAR(&ENHISTMC) TYPE(*CHAR) LEN(1) VALUE('N')

             RTVSYSVAL  SYSVAL(QDAY) RTNVAR(&DD)
             RTVSYSVAL  SYSVAL(QMONTH) RTNVAR(&MM)

/*-------------------------------------------------------------------*/
             CHGJOB     DATE(&CPO1)
/*-------------------------------------------------------------------*/
/*                 CARGAR SEGUIMIENTO DE CL'S                        */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

/*-------------------------------------------------------------------*/
/*                      REARRANQUE AUTOMATICO                        */
/*-------------------------------------------------------------------*/
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
                          THEN(GOTO CMDLBL(REA07))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '08') +
                          THEN(GOTO CMDLBL(REA08))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '09') +
                          THEN(GOTO CMDLBL(REA09))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '10') +
                          THEN(GOTO CMDLBL(REA10))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '11') +
                          THEN(GOTO CMDLBL(REA11))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '12') +
                          THEN(GOTO CMDLBL(REA12))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '13') +
                          THEN(GOTO CMDLBL(REA13))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '14') +
                          THEN(GOTO CMDLBL(REA14))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '15') +
                          THEN(GOTO CMDLBL(FINPGM))

/*-------------------------------------------------------------------*/
/* CONTROLA SI SE HA HECHO LA FACT. SOCIOS DEL ULTIMO PROCESO, DE NO */
/* SER ASI, NO SE HARÁ LA ACUMULACION AL PA HASTA QUE ESTE TERMINADA */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&FECPRO) VALUE(&CPO1)
             CALL       PGM(EXPLOTA/CTRFASO2) PARM(&FECPRO)

/*-------------------------------------------------------------------*/
/*      -PAPRE- PENDIENTE DE ACUMULAR AL PA GENERAL                  */
/*-------------------------------------------------------------------*/
VERPAPRE:    CHKOBJ     OBJ(FICHEROS/PAPRE) OBJTYPE(*FILE)
             MONMSG     CPF0000 EXEC(GOTO NOPAPRE)

             CALL       PGM(EXPLOTA/TRACE) PARM('Hay un PAPRE en la +
                          ficheros, la ultima acumulacion al PA no +
                          se ha hecho o     ' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('finalizo mal.' ' ' +
                          ACUPACL)

             CHGVAR     VAR(&DESCRIP) VALUE('Hay un PAPRE, la ultima +
                          acumulacion al PA no se ha hecho o +
                          finalizo mal.')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCRIP) VALUE('El fichero PAPRE, se +
                          mueve a la LIBSEG1D     INVESTIGAR')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&TEX) VALUE('PAPRE, FICHERO DEL DIA +
                          ANTERIOR INVESTIGAR')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAPRE FICHEROS +
                          PAPRE LIBSEG1D M ' ' ' ' &TEX ACUPACL)

             GOTO       CMDLBL(VERPAPRE)

/*-------------------------------------------------------------------*/
/*================================================================ */
/*                  CONCILIACION "SEAT, S.A."                      */
/*                 ===========================                     */
/* Bloques de Oper. (BLONAC/BLOQINTE). Identificar las operaciones */
/* realizadas con tarjetas del grupo -SEAT- que no sean de LLAA    */
/* y Alquiler de Automoviles para asignarles un Nº de AUTORIZACION */
/*================================================================ */
/*-------------------------------------------------------------------*/
 NOPAPRE:    CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                      PROGRAMA +
                          -SEATBLOQIN- EN EJECUCION    ' ' ' ACUPACL)

             CALL       PGM(EXPLOTA/SEATBLOQIN) /*Op.Internacional*/

             CALL       PGM(EXPLOTA/SEATBLONAC) /*Op.Nacional*/

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, DESPUES DEL +
                          PGM-SEATBLOQIN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLOQINTE FICHEROS +
                          BLOQINTE LIBSEG1D C ' ' ' ' &TEX ACUPACL)

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, DESPUES DEL +
                          PGM-SEATBLONAC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLONAC FICHEROS +
                          BLONAC LIBSEG1D C ' ' ' ' &TEX ACUPACL)
/*================================================================ */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/*      CONTROL OPERACIONES FACTURADAS POR REDENCION DE BONOS        */
/*-------------------------------------------------------------------*/
   /*···································································*/
   /*        CALL       PGM(EXPLOTA/TRACE) +                            */
   /*                     PARM('                             +          */
   /*                     PROGRAMA PBOICRCL EN EJECUCION ' ' ' ACUPACL) */
   /*                                                                   */
   /*        CALL       PGM(EXPLOTA/PBOICRCL) PARM(&CPO1)               */
   /*        CHGJOB     DATE(&CPO1)                                     */
   /*···································································*/

/*-------------------------------------------------------------------*/
/*                     A C U P A                                     */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA ACUPA EN EJECUCION    ' ' ' ACUPACL)

             CRTPF      FILE(FICHEROS/PAPRE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(PA) +
                          TEXT('Fichero PA previo a la acumulacion +
                          al PA') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PAPRE))

             CRTPF      FILE(FICHEROS/PASALTA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(PA) +
                          TEXT('SALTADAS NO ACUMULADAS AL -PAPRE-') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PASALTA))

             D1         LABEL(BLONALG2) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/BLONALG2) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)

/*------------------------------------------------------*/
/*- Conciliación: CTARJETA (Tarjetas bajo una Agencia) -*/
/*------------------------------------------------------*/
             CHKOBJ     OBJ(FICHEROS/CTARJETA) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(DO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                        PROGRAMA +
                          -COREN1- EN EJECUCION   ' ' ' ACUPACL)

             CRTPF      FILE(FICHEROS/CTARJETA) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RELACION +
                          TARJETAS QUE CONCILIAN CON UNA +
                          AGE.VIAJES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CTARJETA))

             CALL       PGM(EXPLOTA/COREN1)
             ENDDO

 /*======================================================================= */
                    /* T E M P O R A L  (AVISOS)  */
 /*======================================================================= */
 /*----------------------------------*/
 /* FACT. CENTRALIZADA Y FACT. PYMES */
 /*----------------------------------*/
             RTVMBRD    FILE(FICHEROS/MACFACEN) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : Es la +
                          primera vez que hay datos en el fichero +
                          MACFACEN, avisar a' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('explotacion para +
                          que verifiquen en pa las operaciones de +
                          fac. centralizada.   ' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('Si no toca fact. de +
                          socios, pulsar intro y seguir de lo +
                          contrario PARAR.      ' ' ' ACUPACL)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE : Es la +
                          primera vez que hay datos en el fichero +
                          MACFACEN, avisar a Diners Club Spain +
                          -para que verifiquen en PA las +
                          operaciones de fac. centralizada.-ACUPACL-')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO
 /*======================================================================= */

/*----------------------------*/
/*- ACUPA: Crea (PA) Parcial -*/
/*----------------------------*/
             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(EXPLOTA/ACUPA) PARM(&CODRET)

             IF         (&CODRET = '1') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('Hay una actividad +
                          internacional que no esta en el +
                          tabacti.                    ' ' ' ACUPACL)

             CHGVAR     VAR(&DESCTOT) VALUE('Hay una actividad +
                          internacional que no esta en el +
                          TABACTI    -ACUPACL-  Avisar a Diners +
                          Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO

            /* GRABAMOS EN PAPRE MASTERCARD */
             CHGVAR     VAR(&ERRORMC) VALUE('N')
             CALL       PGM(EXPLOTA/ACUMASTER) PARM(&ERRORMC)
             IF         (&ERRORMC = 'S') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('Hay errores en ACUMASTER' +
                              ' ' ACUPACL)

             CHGVAR     VAR(&DESCTOT) VALUE('Hay errores en ACUMASTER +
                          -ACUPACL-  Avisar a Diners +
                          Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO

             CHGVAR     VAR(&TEX) VALUE('PAPRE, ACUPACLM  +
                          DESPUES DE ACUMASTER')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAPRE FICHEROS +
                          PAPRE LIBSEG1D C ' ' ' ' &TEX ACUPACL)
/*----------------------------------------------*/
/*- CHKFECHA: Valida en PAPRE la Fecha Consumo  */
/*----------------------------------------------*/
             CALL       PGM(EXPLOTA/CHKFECHA)

/*------------------*/
/*- ¿HAY SALTADAS? -*/
/*------------------*/
             RTVMBRD    FILE(FICHEROS/PASALTA) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG = 0) THEN(DO)
             DLTF       FILE(FICHEROS/PASALTA)
             GOTO       CMDLBL(NOSALTA)
             ENDDO
 /*------------------------------------------------------------------*/
 /*- CREA FICHERO SALTSO Y FSALSO.TXT ESTE ULTIMO LO ENVIA COMO     -*/
 /*- FICHERO A DETERMINADAS DIRECCIONES DE CORREO ELECTRONICO       -*/
 /*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -PASALT- EN EJECUCION' ' ' ACUPACL)

             DLTF       FILE(FICHEROS/FSALSO.TXT)

             DLTDLO     DLO(FSALSO.TXT) FLR(VARMAIL) /* Suprime +
                          fichero de carpeta VARMAIL */
             MONMSG     MSGID(CPF0000)

             CL1        LABEL(FSALSO.TXT) LON(132)

             OVRDBF     FILE(IMP0017) TOFILE(FICHEROS/FSALSO.TXT)
             CALL       PGM(EXPLOTA/PASALT)
             DLTOVR     FILE(IMP0017)

             CHGVAR     VAR(&TEX)  VALUE('OJO SALTADAS SOCIOS')
             CHGVAR     VAR(&SECU) VALUE(2014)
             CHGVAR     VAR(&CLIB) VALUE(FICHEROS)

             CALL       PGM(EXPLOTA/EMAILCL) PARM(&SECU &TEX &CLIB +
                          'FSALSO.TXT' 'VARMAIL   ')

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, DESPUES DEL PGM-+
                          ACUPA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PASALTA FICHEROS +
                          PASALTA LIBSEG1D M ' ' ' ' &TEX ACUPACL)

/*-------------------------------------------------------------------*/
/*================================================================ */
/*  (SEAT) Tarjetas HOTELES, Operaciones para AMEX via e-mail      */
/*  (SEAT) Tarjetas VIAJES,  Operac. AMEX via e-mail (7.5.2007)    */
/*================================================================ */
/*-------------------------------------------------------------------*/
 NOSALTA:    CALL       PGM(EXPLOTA/TRACE) PARM('    ENVIAR +
                          OPERACIONES DE -SEAT- A -AMERICAN EXPRESS +
                          VIAJES-                  ' ' ' ACUPACL)

             CRTLF      FILE(FICHEROS/PATRAHISLG) +
                          TEXT('CONCILIACION, LOGICO -PATRAHIS- POR +
                          Nº.REAL SOCIO') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLG3) TEXT('CONCILIACION, +
                          LOGICO -PA-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

/*---------*/
/* HOTELES */
/*---------*/

             CRTPF      FILE(FICHEROS/SEATOPHO) RCDLEN(236) +
                          TEXT('SEAT, OPERACIONES DE TARJETAS PARA +
                          HOTELES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SEATOPHO))

             CALL       PGM(EXPLOTA/SEATDIARIO) /* Papre */

             CALL       PGM(EXPLOTA/SEATTRASPA) /* Patrahis */

/*---------*/
/* VIAJES  */
/*---------*/

             CRTPF      FILE(FICHEROS/SEATOPVI) RCDLEN(236) +
                          TEXT('SEAT, OPERACIONES DE TARJETAS PARA +
                          VIAJES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SEATOPVI))

             CALL       PGM(EXPLOTA/SEATDIARI1) /* Papre */

             CALL       PGM(EXPLOTA/SEATTRASP1) /* Patrahis */

/*---------------------------*/
/* HOTELES: e-mail para AMEX */
/*---------------------------*/
             DLTDLO     DLO(SEATHO.TXT) FLR(VARMAIL) /* Suprime +
                          fichero de carpeta VARMAIL */
             MONMSG     MSGID(CPF0000)

             CHGVAR     VAR(&TEX) VALUE('Grupo SEAT Operaciones de +
                          las Tarjetas de Hoteles ' *CAT &FECPRO)
             CHGVAR     VAR(&SECU) VALUE(0053) /* SEAT-AMEX */
             CHGVAR     VAR(&CLIB) VALUE(FICHEROS)

             /*ENMASCARAR TARJETA  6X4  */

             OVRDBF     FILE(FICHEROELE) TOFILE(FICHEROS/SEATOPHO)
             CALL       PGM(EXPLOTA/SEAT6X4)
             DLTOVR     FILE(*ALL)

             RNMM       FILE(FICHEROS/SEATOPHO) MBR(SEATOPHO) +
                          NEWMBR(SEATHO.TXT)

             RNMOBJ     OBJ(FICHEROS/SEATOPHO) OBJTYPE(*FILE) +
                          NEWOBJ(SEATHO.TXT)

             CALL       PGM(EXPLOTA/EMAILCL) PARM(&SECU &TEX &CLIB +
                          'SEATHO.TXT' 'VARMAIL   ')

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, SEATHO.TXT -SEAT +
                          TARJ.HOTELES- OPER. AMEX')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SEATHO.TXT +
                          FICHEROS SEATHO.TXT LIBSEG30D C ' ' ' ' +
                          &TEX ACUPACL)

             DLTF       FICHEROS/SEATHO.TXT
/*---------------------------*/
/* VIAJES: e-mail para AMEX  */
/*---------------------------*/
             DLTDLO     DLO(SEATVI.TXT) FLR(VARMAIL) /* Suprime +
                          fichero de carpeta VARMAIL */
             MONMSG     MSGID(CPF0000)

             CHGVAR     VAR(&TEX) VALUE('Grupo SEAT Operaciones de +
                          las Tarjetas de Viajes ' *CAT &FECPRO)
             CHGVAR     VAR(&SECU) VALUE(0084) /* SEAT-AMEX */
             CHGVAR     VAR(&CLIB) VALUE(FICHEROS)

             /*ENMASCARAR TARJETA  6X4  */

             OVRDBF     FILE(FICHEROELE) TOFILE(FICHEROS/SEATOPVI)
             CALL       PGM(EXPLOTA/SEAT6X4)
             DLTOVR     FILE(*ALL)

             RNMM       FILE(FICHEROS/SEATOPVI) MBR(SEATOPVI) +
                          NEWMBR(SEATVI.TXT)

             RNMOBJ     OBJ(FICHEROS/SEATOPVI) OBJTYPE(*FILE) +
                          NEWOBJ(SEATVI.TXT)

             CALL       PGM(EXPLOTA/EMAILCL) PARM(&SECU &TEX &CLIB +
                          'SEATVI.TXT' 'VARMAIL   ')

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, SEATVI.TXT -SEAT +
                          TARJ.VIAJES-  OPER. AMEX')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SEATVI.TXT +
                          FICHEROS SEATVI.TXT LIBSEG30D C ' ' ' ' +
                          &TEX ACUPACL)

             DLTF       FICHEROS/SEATVI.TXT
/*-------------------------------------------------------*/
/*- RASTREO OPERACIONES "SEAT": TARJETAS VIAJES/HOTELES -*/
/*-------------------------------------------------------*/

             CRTPF      FILE(FICHEROS/SEATOPe1) RCDLEN(236) +
                          TEXT('SEAT, Operac. Tarjetas de Viajes en +
                          Hoteles') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SEATOPe1))

             CRTPF      FILE(FICHEROS/SEATOPe2) RCDLEN(236) +
                          TEXT('SEAT, Operac. Tarjetas de Hoteles +
                          en Viajes') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SEATOPe2))

             CALL       PGM(EXPLOTA/SEATerror)

/*----------------------------*/
/* (ERRORES) e-mail para AMEX */
/*----------------------------*/
             DLTDLO     DLO(SEATe1.TXT) FLR(VARMAIL) /* Suprime +
                          fichero de carpeta VARMAIL */
             MONMSG     MSGID(CPF0000)

             CHGVAR     VAR(&TEX) VALUE('SEAT: Error Oper.Tarjetas +
                          de VIAJES en Hoteles')
             CHGVAR     VAR(&SECU) VALUE(0053) /* SEAT-AMEX */
             CHGVAR     VAR(&CLIB) VALUE(FICHEROS)

             /*ENMASCARAR TARJETA  6X4  */

             OVRDBF     FILE(FICHEROELE) TOFILE(FICHEROS/SEATOPe1)
             CALL       PGM(EXPLOTA/SEAT6X4)
             DLTOVR     FILE(*ALL)


             RNMM       FILE(FICHEROS/SEATOPe1) MBR(SEATOPe1) +
                          NEWMBR(SEATe1.TXT)

             RNMOBJ     OBJ(FICHEROS/SEATOPe1) OBJTYPE(*FILE) +
                          NEWOBJ(SEATe1.TXT)

             CALL       PGM(EXPLOTA/EMAILCL) PARM(&SECU &TEX &CLIB +
                          'SEATe1.TXT' 'VARMAIL   ')

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, SEATE1.TXT +
                          -TARJ.VIAJES CON OP.EN HOTELES')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SEATE1.TXT +
                          FICHEROS SEATE1.TXT LIBSEG30D C ' ' ' ' +
                          &TEX ACUPACL)

             DLTF       FICHEROS/SEATE1.TXT
/*-------*/
/* <===> */
/*-------*/
             DLTDLO     DLO(SEATe2.TXT) FLR(VARMAIL) /* Suprime +
                          fichero de carpeta VARMAIL */
             MONMSG     MSGID(CPF0000)

             CHGVAR     VAR(&TEX) VALUE('SEAT: Error Oper.Tarjetas +
                          de HOTELES en Viajes')
             CHGVAR     VAR(&SECU) VALUE(0053) /* SEAT-AMEX */
             CHGVAR     VAR(&CLIB) VALUE(FICHEROS)

             /*ENMASCARAR TARJETA  6X4  */

             OVRDBF     FILE(FICHEROELE) TOFILE(FICHEROS/SEATOPe2)
             CALL       PGM(EXPLOTA/SEAT6X4)
             DLTOVR     FILE(*ALL)

             RNMM       FILE(FICHEROS/SEATOPe2) MBR(SEATOPe2) +
                          NEWMBR(SEATe2.TXT)

             RNMOBJ     OBJ(FICHEROS/SEATOPe2) OBJTYPE(*FILE) +
                          NEWOBJ(SEATe2.TXT)

             CALL       PGM(EXPLOTA/EMAILCL) PARM(&SECU &TEX &CLIB +
                          'SEATe2.TXT' 'VARMAIL   ')

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, SEATE2.TXT +
                          -TARJ.HOTELES CON OP.EN VIAJES')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SEATE2.TXT +
                          FICHEROS SEATE2.TXT LIBSEG30D C ' ' ' ' +
                          &TEX ACUPACL)

             DLTF       FICHEROS/SEATE2.TXT
/*-------------------------------------------------------------------*/
/*  FACT. DE SOCIOS SIN EJECUTARSE, NO SE PUEDE ACUMULAR EL -PAPRE- */
/*------------------------------------------------------------------*/
             IF         (&FECPRO = '999999') THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('* Debido a que no +
                          se ha hecho la ultima fact. de socios, no +
                          se puede acumular ' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('* el PAPRE, +
                          quedandose pendiente hasta que se haga. +
                          Al final de dicha factur. ' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('* se ejecutara el +
                          ACUPACL2  el cual acumulara dicho PAPRE  +
                          al PA.           ' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('Conservar totales +
                          del pgm-ACUPA hasta que se produzca la +
                          acumulacion.         ' ' ' ACUPACL)

             CHGVAR     VAR(&DESCRIP) VALUE('Fact.Socios ,EL PAPRE +
                          se acumulara en la Fact.Socios -ACUPACLM +
                          INVEST')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             GOTO       NOPAPRE2
             ENDDO
/*------------------------------------------------------------------*/

 NOPAPRE2:   CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*------------------------------------------------------------------*/
/*  FACT. DE SOCIOS SIN EJECUTARSE, NO SE PUEDE ACUMULAR EL -PAPRE- */
/*------------------------------------------------------------------*/
 REA01:      IF         (&FECPRO = '999999') THEN(GOTO NOACUMX)

/*------------------------------------------------------------------*/
/*  FACT. DE SOCIOS EN EJECUCION, NO SE PUEDE ACUMULAR EL -PAPRE-   */
/*------------------------------------------------------------------*/
             CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'NOPROC    ')

             IF         COND(&ACCION = 'S') THEN(DO)
 NOACUMX:    OVRDBF     FILE(FICHERO) TOFILE(FICHEROS/QTXTSRC) +
                          MBR(ACUPA01)
             OVRPRTF    FILE(PRTMSG) OUTQ(P12) FORMTYPE(IMP00P5) +
                          SAVE(*YES)

             CALL       PGM(EXPLOTA/AVIGEN) PARM(' ')

             DLTOVR     FILE(FICHERO)
             DLTOVR     FILE(PRTMSG)

             CALL       PGM(EXPLOTA/TRACE) PARM('* OJO, hay un +
                          proceso de fact. socios en curso, no se +
                          puede acumular el PAPRE' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('* recoger el aviso +
                          generado por el pgm-avigen de la +
                          impresora y seguir.       ' ' ' ACUPACL)


             CHGVAR     VAR(&DESCRIP) VALUE('OJO, hay un proceso de +
                          fact.socios ,no se puede acumular el +
                          PAPRE   ACUPACLM')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             GOTO       CMDLBL(NOACUM)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*  --SOLUCION AUNA CONTROL "TODAS LAS OPERAC.EN TARJETA MATRIZ"   */
/*  -- ADICION DEL -PAPRE- AL FICHERO -PA-                           */
/*  -- RENFE Nº.DE BILLETES: TABULADO/HISTORICO DE OPERACIONES       */
/*-------------------------------------------------------------------*/
 REA02:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                         ADICION +
                          DEL -PAPRE- AL -PA- EN EJECUCION' ' ' +
                          ACUPACL)


             CALL       PGM(EXPLOTA/AUNAPACL)  /* SOLUCION AUNA */
             CHGJOB     DATE(&CPO1)

        /*---------*/

             CPYF       FROMFILE(FICHEROS/PAPRE) TOFILE(FICHEROS/PA) +
                          MBROPT(*ADD) FROMRCD(1)

    /*  ************************************************************** */
    /* DAVID 16/01/2024: PROVISIONAL HASTA QUE OPER. MC PASEN AL FS01M */
    /*       MUEVE LOS REGISTROS DE FICHEROS/PA A ATRIUM/PAMCAUX       */
    /*  ************************************************************** */

         /*  CALL       PGM(EXPLOTA/MC0105)  */

/*--------------------------------------------------------------*/
/*--  HISTORICOS PARA CONTABILIDAD: BLONAC, BLOQINTE y PA   --*/
/*--  01.07.2022 DETALLE OPERACIONES CONTABILIZADAS (NAV)   --*/
/*--------------------------------------------------------------*/

             CPYF       FROMFILE(FICHEROS/BLONAC) +
                          TOFILE(FICHEROS/BLONAC_HI) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/BLOQINTE) +
                          TOFILE(FICHEROS/BLOQINTE_H) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

             IF         COND(&ERRORMC *NE 'S') THEN(DO)
               CPYF       FROMFILE(FICHEROS/BLOMASTER) +
                          TOFILE(FICHEROS/BLOMASTERH) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

               CHGVAR     VAR(&ENHISTMC) VALUE('S')
             ENDDO

             CPYF       FROMFILE(FICHEROS/PAPRE) +
                          TOFILE(FICHEROS/PA_HI) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

/*--------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('RENFE Nº.BILLETE: +
                          Tabulado/Historico de Operaciones +
                          (clp.RENBI4CL)            ' ' ' ACUPACL)

             CALL       PGM(EXPLOTA/RENBI4CL)


             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*          CLASIFICACION DEL FICHERO PA                             */
/*-------------------------------------------------------------------*/
 REA03:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          CLASIFICACION DEL FICHERO PA        ' ' ' +
                          ACUPACL)

/*=============================================================*/
/*   24/5/2023 ELIMINAR SORT (SPA) QUE CLASIFICABA EL -PA-   */
/*=============================================================*/

             CRTLF      FILE(FICHEROS/SPA) SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('LOGICO -PA- SUSTITUYE AL SORT +
                          SPA') OPTION(*NOLIST *NOSRC) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             RGZPFM     FILE(FICHEROS/PA) KEYFILE(FICHEROS/SPA SPA)

             D1         LABEL(SPA) LIB(FICHEROS)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*----------------------------------------------------------------*/
/*  CRUCE DEL PAPRE CON EL AUTORIZ                                */
/*----------------------------------------------------------------*/
 REA04:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA CRUZAOPER EN +
                          EJECUCION                ' ' ' ACUPACL)

            /* NO LIMPIAR EN CASO DE REARRANQUE  */
             CRTPF      FILE(FICHEROS/BDCRUZAUT) +
                          SRCFILE(SADE/QDDSSRC) SRCMBR(BDAUTOR) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CALL       LONDRES/CRUZAOPER

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BDCRUZAUT +
                          FICHEROS BDCRUZAUT LIBSEG1D C ' ' ' ' +
                          'OPERACIONES CRUZADAS ENTRE BLOQINTE Y +
                          AUTORIZ     ' ACUPACL)

             CALL       PGM(BD38ADD) PARM('BDCRUZAUT ' '13' +
                          'AUBOLSA   ' 'ACUPACL   ')


             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
 /*------------------------------------------------------------------*/
 /**************************************************************** */
 /*              CONCILIACION "VIAJES EL CORTE INGLES"             */
 /*                                                                */
 /*  TARJETAS: Organismos Oficiales --> TITULAR: El Corte Ingles   */
 /*                                                                */
 /*          ESPECIAL: TRASPASO DE OPERACIONES ENTRE TARJETAS      */
 /*                                                                */
 /**************************************************************** */
 /*------------------------------------------------------------------*/
 REA05:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                         PROGRAMA +
                          -COVECISA- EN EJECUCION        ' ' ' ACUPACL)

             CALL       PGM(EXPLOTA/COVECISA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*                 S U M A P A                                       */
/*-------------------------------------------------------------------*/
 REA06:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA SUMAPA EN EJECUCION        ' ' ' +
                          ACUPACL)

             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CALL       PGM(EXPLOTA/SUMAPAM) PARM(&TOTCUA)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTCUA 'PAGE00' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('NO CUADRA EL +
                          TOTALES "PAGE00". CUPAFAM -IN02 +
                          INVESTIGAR.' ' ' ACUPACL)

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "PAGE00". CUPAFAM-IN02   INVESTIGAR. +
                          FACT.ESTABLEC.')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "PAGE00" DEL PGM-CUPAFAM DE +
                          FACT.ESTABLECIMIENTOSS **LLAMAR A Diners +
                          Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO
/*---*/
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*          BLANQUEO DE CAPITALES                                    */
/*-------------------------------------------------------------------*/
REA07:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA BCDIARIO EN +
                          EJECUCION                   ' ' ' ACUPACL)

             CALL       PGM(EXPLOTA/BCDIARIO)

/*-------------------------------------------------------------------*/
 /* SI CASCA DEJAR NOTA Y CONTINUARRRRR                            */
/*          BLANQUEO DE CAPITALES       RIESGO 3 o 4                 */
/*          BLANCA304   *FILE ALERTA  MENSUAL                        */
/*-------------------------------------------------------------------*/
 /*          CRTPF      FILE(FICHEROS/BLANCA304) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
 /*          MONMSG     MSGID(CPF0000)                     */

             CALL       PGM(EXPLOTA/BCDIARIOP)
/*-------------------------------------------------------------------*/
 /* SI CASCA DEJAR NOTA Y CONTINUARRRRR                            */
/*          BLANQUEO DE CAPITALES                                    */
/*          -- ALERTAS EN OPERACIONES DE PAPRE                       */
/*          <     5.000,00        RIESGO -S                          */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/PBCFACTSCL)
/*-------------------------------------------------------------------*/
 /* SI CASCA DEJAR NOTA Y CONTINUARRRRR                            */
/*          ALERTAS   PI / PE                                        */
/*          -- SIN CORREO  Y  ENVIO PAPEL                            */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/ALERTAPICL)
/*-------------------------------------------------------------------*/
/*                  COPIAS  DE  SEGURIDAD                            */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('ACUPACL, DESPUES DEL PGM-+
                          ACUPA')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLANCA304T +
                          FICHEROS BLANCA304T LIBSEG1D C ' ' ' ' +
                          &TEX ACUPACL)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG1D C ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAPRE FICHEROS +
                          PAPRE LIBSEG1D C ' ' ' ' &TEX ACUPACL)
/*-------------------------------------------------------------------*/
/* COPIAR REGISTRO DEL PAPRE A PAVC (SISTEMAS DE GESTION: FICTICIO)  */
/*-------------------------------------------------------------------*/

             CALL       PGM(EXPLOTA/ATRCONCU02)

/*=============================================================*/
/*   24/5/2023 ELIMINAR SORT (SPA) QUE CLASIFICABA -PAVC-    */
/*=============================================================*/

             CRTLF      FILE(FICHEROS/SPAVC) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -PAVC- SUSTITUYE AL SORT SPA') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             RGZPFM     FILE(FICHEROS/PAVC) KEYFILE(FICHEROS/SPAVC +
                          SPAVC)

             D1         LABEL(SPAVC) LIB(FICHEROS)

/*==================*/

             DLTF       FICHEROS/PAPRE

             CHGVAR     VAR(&TEX) VALUE('ACUPACL, ANTES DE EJECUTAR +
                          PGM-NEGR02')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PTEPREPR FICHEROS +
                          PTEPREPR LIBSEG1D C ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PTEPRHIS FICHEROS +
                          PTEPRHIS LIBSEG1D C ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DESCRFAC FICHEROS +
                          DESCRFAC LIBSEG1D C ' ' ' ' &TEX ACUPACL)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*                    N E G R 0 2                                    */
/*-------------------------------------------------------------------*/
 REA08:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA NEGR02 EN EJECUCION   ' ' ' ACUPACL)

             CRTPF      FILE(FICHEROS/ASINEGR2) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('ASIENTO CONTABLE') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASINEGR2))

             CRTPF      FILE(FICHEROS/ASINEG22) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('CUENTAS FA/PA') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASINEG22))

             CRTPF      FILE(FICHEROS/PTEPRHIS) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(PTEPRHIS) TEXT('Historico, +
                          Pte.Presentar Proveedor -CRUZADO-') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/DETEVI22) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEVI22))

             CRTLF      FILE(FICHEROS/PTEPRLG1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -PTEPREPR-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/SOCIOLG1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -PA-') OPTION(*NOLIST *NOSRC) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/SOCIOLG2) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -PA-') OPTION(*NOLIST *NOSRC) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/SOCIOLG3) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -PA-') OPTION(*NOLIST *NOSRC) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/DETE27) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE27))

             CRTPF      FILE(FICHEROS/CABE27) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE27))

             CALL       PGM(EXPLOTA/NEGR02)

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETE27) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE27) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/DETEVI22) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FROMRCD(1)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE27 FICHEROS +
                          DETE27 LIBSEG1D M ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE27 FICHEROS +
                          CABE27 LIBSEG1D M ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEVI22 FICHEROS +
                          DETEVI22 LIBSEG1D M ' ' ' ' &TEX ACUPACL)

             CALL       PGM(EXPLOTA/TRACE) PARM('Comprobar que se +
                          han acumulado al totales -LO PRESENTADO +
                          POR PROVEEDORES ' ' ' ACUPACL)
             CALL       PGM(EXPLOTA/TRACE) PARM('Y YA LO HIZO LA +
                          AGENCIA.                                    -
             ' ' ' ACUPACL)

             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CALL       PGM(EXPLOTA/SUMAPAM) PARM(&TOTCUA)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTCUA 'PAGE00' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('NO CUADRA EL +
                          TOTALES "PAGE00". NEGR02  -IN02 +
                          INVESTIGAR.' ' ' ACUPACL)

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "PAGE00". NEGR02 -IN02   INVESTIGAR. +
                          FACT.ESTABLEC.')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "PAGE00" DEL PGM-NEGR02  DE +
                          FACT.ESTABLECIMIENTOSS **LLAMAR A Diners +
                          Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO
/*-----*/
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*  COPIAS DE SEGURIDAD                                              */
/*-------------------------------------------------------------------*/
 REA09:      CHGVAR     VAR(&TEX) VALUE('ACUPACL, SALIDO DE EJECUTAR +
                          PGM-NEGR02')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG1D P ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PTEPREPR FICHEROS +
                          PTEPREPR LIBSEG1D C ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PTEPRHIS FICHEROS +
                          PTEPRHIS LIBSEG1D C ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DESCRFAC FICHEROS +
                          DESCRFAC LIBSEG1D C ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINEGR2 FICHEROS +
                          ASINEGR2 LIBSEG1D C ' ' ' ' &TEX ACUPACL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINEG22 FICHEROS +
                          ASINEG22 LIBSEG1D C ' ' ' ' &TEX ACUPACL)

             CALL       PGM(EXPLOTA/OPADISAV) PARM('ALL' 'ACUPACL   +
                          ' 'ACUPACL   ')
/*-------------------------------------------------------------------*/
/*  ASIENTO CONTABLE                                                 */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA ACASBO  EN EJECUCION  ' ' ' ACUPACL)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASINEGR2)
             CALL       PGM(EXPLOTA/FCTIME)
             CALL       PGM(EXPLOTA/ACASBO) PARM('020')
             CHGJOB     DATE(&CPO1)

             DLTOVR     FILE(ASIFILE)
/*---*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA ACASBO  EN EJECUCION  ' ' ' ACUPACL)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASINEG22)
             CALL       PGM(EXPLOTA/FCTIME)
             CALL       PGM(EXPLOTA/ACASBO) PARM('022')
             CHGJOB     DATE(&CPO1)

             DLTOVR     FILE(ASIFILE)
             CHGJOB     DATE(&CPO1)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*===================================================================*/
/*==>>>  NO ACUMULAR - NO ACUMULAR - NO ACUMULAR - NO ACUMULAR  <<<==*/
/*===================================================================*/
NOACUM:

/*-------------------------------------------------------------------*/
/*  DATA WAREHOUSE: OPER. ESPAÑOLES/EXTRANJERO EN ESPAÑA (BLONAC)    */
/*-------------------------------------------------------------------*/
 REA10:      CALL       PGM(EXPLOTA/TRACE) PARM(' DATAWAREHOUSE: +
                          OPER.ESPAÑOLES/EXTRANJEROS EN ESPAÑA +
                          -DATAWN-                 ' ' ' ACUPACL)

             CRTPF      FILE(FICHEROS/DATAWNAC) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DATAWHOUSE) TEXT('DATAWAREHOUSE, +
                          OPER.ESPAÑOLES/EXTRANJEROS -ESPAÑA-') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DATAWNAC))

             CALL       PGM(EXPLOTA/DATAWN)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*  DATA WAREHOUSE: OPER. ESPAÑOLES EN EL EXTRANJERO     (BLOQINTE)  */
/*-------------------------------------------------------------------*/
 REA11:      CALL       PGM(EXPLOTA/TRACE) PARM(' DATAWAREHOUSE: +
                          OPER.ESPAÑOLES EN EL EXTRANJERO      +
                          -DATAWI-                 ' ' ' ACUPACL)

             CRTPF      FILE(FICHEROS/DATAWINT) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DATAWHOUSE) TEXT('DATAWAREHOUSE, +
                          OPER. ESPAÑOLES -EN EL EXTRANJERO- ') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DATAWINT))

             CALL       PGM(EXPLOTA/DATAWI)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)

/*-------------------------------------------------------------------*/
/*  DATA WAREHOUSE: OPER. MASTERCARD     (BLOMASTER)                 */
/*-------------------------------------------------------------------*/
 REA12:      CALL       PGM(EXPLOTA/TRACE) PARM(' DATAWAREHOUSE: +
                          OPERACIONES MASTERCARD      +
                          -DATAWMC-               ' ' ' ACUPACL)

             CRTPF      FILE(FICHEROS/DATAWMCD) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DATAWHOUSE) TEXT('DATAWAREHOUSE, +
                          OPER. MASTERCARD- ') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DATAWMCD))

             CALL       PGM(EXPLOTA/DATAWMC)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)

/*-------------------------------------------------------------------*/
/*  ACTUALIZACION DEL MSOCIOAUX CON LOS SALDOS CEROP A LOS STATUS    */
/*-------------------------------------------------------------------*/
 REA13:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA LORTAD01 EN +
                          EJECUCION                ' ' ' ACUPACL)

             CALL       EXPLOTA/LORTAD01
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*-------------------------------------------------------------------*/
/*                      DELETES FINALES                              */
/*-------------------------------------------------------------------*/
REA14:       D1         BLONALG2
             DLTF       FILE(FICHEROS/SOCIOLG1)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(FICHEROS/SOCIOLG2)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(FICHEROS/SOCIOLG3)
             MONMSG     MSGID(CPF0000)
             D1         LABEL(ASINEGR2)   LIB(FICHEROS)
             D1         LABEL(ASINEG22)   LIB(FICHEROS)
             D1         LABEL(PENCOMSOPA) LIB(FICHEROS)
             /* LIMPIAMOS BLOMASTER UNA VEZ HEMOS LLEVADO AL HISTORICO */
             IF         COND(&ENHISTMC *EQ 'S')  THEN(DO)
               CHGVAR     VAR(&TEX) VALUE('BLOMASTER COPIADO Y LIMPIEZA')
               CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLOMASTER FICHEROS +
                          BLOMASTER LIBSEG1D C ' ' ' ' &TEX ACUPACL)
               CLRPFM     FILE(FICHEROS/BLOMASTER)
             ENDDO

/*-------------------------------------------------------------------*/
/*                   E-MAIL  DE FINALIZACION DEL PROCESO             */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&MSG) VALUE('** ACABA DE FINALIZAR EL +
                          PROCESO ** DE CLP.PROCNOCHE --> CLP.IN02M +
                          --> CLP.ACUPACLM')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((GrupoAS400@dinersclub.es)) +
                          DSTD('ADICION DIARIA A +
                          -PA-                     ') LONGMSG(&MSG)

/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' ACUPACL)
/*********************************************************************/
/*                       F I N                                       */
/*********************************************************************/
FINPGM:      CALL       PGM(EXPLOTA/TRACE) PARM('FIN' ' ' 'ACUPACL')
             DLTOVR *ALL
             ENDPGM
