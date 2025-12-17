 /********************************************************************/
 /* ================================================================ */
 /* CONTROL-M   CONTROL-M   CONTROL-M   CONTROL-M   CONTROL-M      */
 /* ================================================================ */
 /*                                                                  */
 /*   F A C T U R A C I O N     D E    S O C I O S    N O R M A L    */
 /*                                                                  */
 /* Modificado 13/07/2023 APG : No realizar CUADAU con DIGE00        */
 /* por estar en desuso                                              */
 /*                                                                  */
 /* 24/01/2024 | APG2 | Se comentan los programas BCH12 y FSCREBO    */
 /*                     En proceso de descatalogación.               */
 /********************************************************************/
             PGM
             DCL        VAR(&ACCION) TYPE(*CHAR) LEN(1)
             DCL        VAR(&CODRET)  TYPE(*CHAR)  LEN(1)
             DCL        VAR(&CODRET1) TYPE(*CHAR) LEN(1) /* SI SE +
                          HACE FACTURACION */
             DCL        VAR(&CODRET2) TYPE(*CHAR) LEN(1) /* EXITE EN +
                          PRDIARIO */
             DCL        VAR(&DATOS)   TYPE(*CHAR)  LEN(14)  VALUE('FS01')
             DCL        VAR(&XDIA) TYPE(*DEC) LEN(2)
             DCL        VAR(&DD)      TYPE(*DEC)   LEN(2)
             DCL        VAR(&DDMM)    TYPE(*CHAR)  LEN(4)
             DCL        VAR(&DDMMP)   TYPE(*DEC)   LEN(4)
             DCL        VAR(&DDPRO)   TYPE(*CHAR)  LEN(2)
             DCL        VAR(&ESTADO)  TYPE(*CHAR)  LEN(1)
             DCL        VAR(&FCONTA)  TYPE(*CHAR)  LEN(25)
             DCL        VAR(&FECHA)   TYPE(*CHAR)  LEN(6)
             DCL        VAR(&FECHAX)  TYPE(*DEC)   LEN(6 0)
             DCL        VAR(&FECHAZ)  TYPE(*CHAR) LEN(6)
             DCL        VAR(&LABAL)   TYPE(*CHAR)  LEN(8)
             DCL        VAR(&LABEL)   TYPE(*CHAR)  LEN(10)
             DCL        VAR(&LABELCS) TYPE(*CHAR)  LEN(10)
             DCL        VAR(&LAFA)    TYPE(*CHAR)  LEN(6)
             DCL        VAR(&MM)      TYPE(*CHAR)  LEN(2)
             DCL        VAR(&MSG)     TYPE(*CHAR)  LEN(128)
             DCL        VAR(&MSG1)    TYPE(*CHAR)  LEN(256)
             DCL        VAR(&NUMREG)  TYPE(*DEC)   LEN(10 0)
             DCL        VAR(&REST1)   TYPE(*CHAR)  LEN(10)
             DCL        VAR(&RTCDE)   TYPE(*CHAR)  LEN(1)
             DCL        VAR(&SECU)    TYPE(*DEC)   LEN(4 0)
             DCL        VAR(&SS)      TYPE(*CHAR)  LEN(2)
             DCL        VAR(&TEX)     TYPE(*CHAR)  LEN(50)
             DCL        VAR(&CLAVES) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')
             DCL        VAR(&AGRUP1) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')
             DCL        VAR(&AGRUP2) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')

             DCL        VAR(&TOTCUA) TYPE(*DEC) LEN(11 0)
             DCL        VAR(&NOCUA)  TYPE(*CHAR) LEN(1)
             DCL        VAR(&MSG)    TYPE(*CHAR) LEN(128)
             DCL        VAR(&PRIORID) TYPE(*DEC) LEN(1 0) VALUE(9) +
                          /* para fichero incidencias */
             DCL        VAR(&DESCRIP) TYPE(*CHAR) LEN(80) /* para +
                          fichero incidencias */
             DCL        VAR(&PROCE) TYPE(*CHAR) LEN(10) +
                          VALUE('FS01M     ') /* /fichero de +
                          incidencias */
             DCL        VAR(&DESCTOT) TYPE(*CHAR) LEN(200) /* para +
                          ENVIO mensaje del incidencias al CONTROL-M */
             DCL        VAR(&BLOQUEA) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TEXTO) TYPE(*CHAR) LEN(60) VALUE(' ')

             DCL        VAR(&PARAM)   TYPE(*CHAR) LEN(10) VALUE(' ')
             DCL        VAR(&CADENA)  TYPE(*CHAR) LEN(10) VALUE('FS01M')
             DCL        VAR(&NUMAPU) TYPE(*CHAR) LEN(6) VALUE(' ')

/*-------------------------------------------------------------------*/
/*    ARRANCAR EL TRACE                                              */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

             CALL       PGM(EXPLOTA/TRACE) PARM('F A C T U R A C I O +
                          N   D E   S O C I O S' ' ' FS01)
 /*------------------------------------------------------------------*/
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&FECHAZ)

/*-------------------------------------------------------------------*/
/*      CONTROL ULTIMA FACT.DEL AÑO POR TEMA BAUTSO                  */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'CTRULTBAU ')

             IF         COND(&ACCION = 'S') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('ESTAMOS A PRIMEROS DE +
                          AÑO Y AUN NO SE HAN MOVIDO LAS +
                          ESTADIST.DEL BAUTSO  FS01')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operador@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01M     ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FIN)

             ENDDO
/*-------------------------------------------------------------------*/
/*           ESTA ARRANCADA LA FACTURACION DE SOCIOS CONCILIACION    */
/*-------------------------------------------------------------------*/
             CHKOBJ     OBJ(FICHEROS/FIFS01CO) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(RECIBE))

             CHGVAR     VAR(&DESCRIP) VALUE('HAY UNA FACTURACION DE +
                          CONCILIACION ARRANCADA  INVESTIGAR    FS01')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01M     ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE('HAY UNA FACTURACION DE +
                          CONCILIACION ARRANCADA  INVESTIGAR    +
                          FS01M **SE CANCELA')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             IF         COND(&CODRET *EQ '1') THEN(DO)
                    GOTO       CMDLBL(FIN)
             ENDDO

 /*------------------------------------------------------------------*/
 /* HAY UNA FACTURACION DE ESTABLECIMIENTOS SIN TERMINAR             */
 /*------------------------------------------------------------------*/
 RECIBE:     CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'NOACES    ')

             IF         COND(&ACCION = 'S') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('HAY UNA FACTURACION DE +
                          ESTABLECIMIENTOS ARRANCADA  INVESTIGAR    +
                          FS01M')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACT. ESTABLECIMIENTOS CONTABLE') +
                          LONGMSG(&MSG)

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('HAY UNA FACTURACION DE +
                          ESTABLECIMIENTOS ARRANCADA  INVESTIGAR    +
                          FS01M  **SE CANCELA')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             IF         COND(&CODRET *EQ '1') THEN(DO)
                    GOTO       CMDLBL(FIN)
             ENDDO

             ENDDO
 /*------------------------------------------------------------------*/
 /*        SE RECIBE FECHA DEL SISTEMA  RESTANDO UN DIA              */
 /*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/RTVFECHA) PARM(&FECHAX)

             CHGVAR     VAR(&FECHA) VALUE(&FECHAX)
             CHGJOB     DATE(&FECHA) SWS(00000000)
             CHGVAR     VAR(&DD) VALUE(%SUBSTRING(&FECHA 1 2))
             CHGVAR     VAR(&MM) VALUE(%SUBSTRING(&FECHA 3 2))
             CHGVAR     VAR(&DDMMP) VALUE(%SUBSTRING(&FECHA 1 4))
             CHGVAR     VAR(&DDPRO) VALUE(%SUBSTRING(&FECHA 1 2))
             IF         COND(&DD *GE 28) THEN(DO)
             CHGVAR     VAR(&DDPRO) VALUE(30)
             ENDDO

             CALL       PGM(PRDIACTL) PARM('A' 'FS01M     ')
 /*------------------------------------------------------------------*/
 /*        COMPROBAR SI TOCA FACTURACION O HAY ALGUNA PENDIENTE      */
 /*        EN EL FICHERO DE CONTROL PRDIARIO -                       */
 /*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/CTLSOCPRO) PARM('FS01M     ' +
                          &CODRET1 &CODRET2 &FECHA)

             IF         COND(&CODRET1 = '0') THEN(DO)

             CALL       PGM(PRDIACTL) PARM('B' 'FS01M     ')
             GOTO       CMDLBL(FIN)

   /* NO TOCA FACT.SOCIOS/EMPRESAS EN FICHERO CALESTAB   **FIN**   */

             ENDDO
 /*------------------------------------------------------------------*/
             IF         COND(&CODRET2 = '2') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('UN PROCESO DE +
                          FACT.SOCIOS NO HA TERMINADO BIEN  -PRDIARIO')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01M     ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FIN)

             ENDDO
/*------------------------------------*/
/*- CUADRE        -PA- -FA-          -*/
/*-----------------------------------*/

             CALLSUBR   SUBR(CUADREPA)
             CALLSUBR   SUBR(CUADREFA)

/*-------------------------------------------------------------------*/
/*    FICHEROS DE CONTROL                                            */
/*-------------------------------------------------------------------*/

             CL1        LABEL(FIFS01) LIB(FICHEROS) LON(1) /* +
                          Control Permisos Trabajos -CONCILIACION-  */

             CALL       PGM(PRFICCTL) PARM('A' 'NOPROC    ')
             CALL       PGM(PRFICCTL) PARM('A' 'FACRECI   ')

/*-------------------------------------------------------------------*/
/*    CREA Y VALIDA FICHERO DE CONTROL CRFS01                       */
/*-------------------------------------------------------------------*/
             D1         LABEL(CRFS01) LIB(FICHEROS)
             MONMSG     MSGID(CPF0000)

             CALL       PGM(FSFECHA)

             CL1        LABEL(CRFS01) LIB(FICHEROS) LON(96)

             CALL       PGM(EXPLOTA/CRFS01AUT)

             CHGJOB     DATE(&FECHA)

/*-------------------------------------------------------------------*/
/*  CREACION CONTROL COMPENSACION DE SALDOS                          */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, COMPENSAR ANTES   DE +
                          PGM-COMPENOPE         ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(COMPENSAR +
                          FICHEROS COMPENSAR LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

             CRTPF      FILE(FICHEROS/COMPENFAS) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(COMPENSAR) TEXT('Control +
                          compensacion de saldos') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/COMPENFAS))

             CALL       PGM(COMPENCREA) PARM('S')
             CALL       PGM(COMPENOPE)

             CHGVAR     VAR(&TEX) VALUE('FS01M, COMPENFAS DESPUES DE +
                          PGM-COMPENCREA        ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(COMPENFAS +
                          FICHEROS COMPENFAS LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

             CHGJOB     DATE(&FECHA)
/*-------------------------------------------------------------------*/
/*--                    REARRANQUE AUTOMATICO                        */
/*-------------------------------------------------------------------*/
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '01') +
                          THEN(GOTO CMDLBL(RE1))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '02') +
                          THEN(GOTO CMDLBL(RE2))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '03') +
                          THEN(GOTO CMDLBL(RE3))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '04') +
                          THEN(GOTO CMDLBL(RE4))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '05') +
                          THEN(GOTO CMDLBL(RE5))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '06') +
                          THEN(GOTO CMDLBL(RE6))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '07') +
                          THEN(GOTO CMDLBL(RE7))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '08') +
                          THEN(GOTO CMDLBL(RE8))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '09') +
                          THEN(GOTO CMDLBL(RE9))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '10') +
                          THEN(GOTO CMDLBL(RE10))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '11') +
                          THEN(GOTO CMDLBL(RE11))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '12') +
                          THEN(GOTO CMDLBL(RE12))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '13') +
                          THEN(GOTO CMDLBL(RE13))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '14') +
                          THEN(GOTO CMDLBL(RE14))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '15') +
                          THEN(GOTO CMDLBL(RE15))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '16') +
                          THEN(GOTO CMDLBL(RE16))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '17') +
                          THEN(GOTO CMDLBL(RE17))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '18') +
                          THEN(GOTO CMDLBL(RE18))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '19') +
                          THEN(GOTO CMDLBL(RE19))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '20') +
                          THEN(GOTO CMDLBL(RE20))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '21') +
                          THEN(GOTO CMDLBL(RE21))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '22') +
                          THEN(GOTO CMDLBL(RE22))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '23') +
                          THEN(GOTO CMDLBL(RE23))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '24') +
                          THEN(GOTO CMDLBL(RE24))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '25') +
                          THEN(GOTO CMDLBL(RE25))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '26') +
                          THEN(GOTO CMDLBL(RE26))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '27') +
                          THEN(GOTO CMDLBL(RE27))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '28') +
                          THEN(GOTO CMDLBL(RE28))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '29') +
                          THEN(GOTO CMDLBL(RE29))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '30') +
                          THEN(GOTO CMDLBL(RE30))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '31') +
                          THEN(GOTO CMDLBL(RE31))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '32') +
                          THEN(GOTO CMDLBL(RE32))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '33') +
                          THEN(GOTO CMDLBL(RE33))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '34') +
                          THEN(GOTO CMDLBL(RE34))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '35') +
                          THEN(GOTO CMDLBL(RE35))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '36') +
                          THEN(GOTO CMDLBL(RE36))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '37') +
                          THEN(GOTO CMDLBL(RE37))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '38') +
                          THEN(GOTO CMDLBL(RE38))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '39') +
                          THEN(GOTO CMDLBL(RE39))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '40') +
                          THEN(GOTO CMDLBL(RE40))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '41') +
                          THEN(GOTO CMDLBL(RE41))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '42') +
                          THEN(GOTO CMDLBL(RE42))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '43') +
                          THEN(GOTO CMDLBL(RE43))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '44') +
                          THEN(GOTO CMDLBL(RE44))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '45') +
                          THEN(GOTO CMDLBL(RE45))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '46') +
                          THEN(GOTO CMDLBL(RE46))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '47') +
                          THEN(GOTO CMDLBL(RE47))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '48') +
                          THEN(GOTO CMDLBL(RE48))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '49') +
                          THEN(GOTO CMDLBL(RE49))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '50') +
                          THEN(GOTO CMDLBL(RE50))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '51') +
                          THEN(GOTO CMDLBL(RE51))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '52') +
                          THEN(GOTO CMDLBL(RE52))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '53') +
                          THEN(GOTO CMDLBL(RE53))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '54') +
                          THEN(GOTO CMDLBL(RE54))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '55') +
                          THEN(GOTO CMDLBL(RE55))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '56') +
                          THEN(GOTO CMDLBL(RE56))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '57') +
                          THEN(GOTO CMDLBL(RE57))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '58') +
                          THEN(GOTO CMDLBL(RE58))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '59') +
                          THEN(GOTO CMDLBL(RE59))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '60') +
                          THEN(GOTO CMDLBL(RE60))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '61') +
                          THEN(GOTO CMDLBL(RE61))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '62') +
                          THEN(GOTO CMDLBL(RE62))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '63') +
                          THEN(GOTO CMDLBL(RE63))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '64') +
                          THEN(GOTO CMDLBL(RE64))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '65') +
                          THEN(GOTO CMDLBL(RE65))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '66') +
                          THEN(GOTO CMDLBL(RE66))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '67') +
                          THEN(GOTO CMDLBL(RE67))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '68') +
                          THEN(GOTO CMDLBL(RE68))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '69') +
                          THEN(GOTO CMDLBL(RE69))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '70') +
                          THEN(GOTO CMDLBL(RE70))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '71') +
                          THEN(GOTO CMDLBL(RE71))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '72') +
                          THEN(GOTO CMDLBL(RE72))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '73') +
                          THEN(GOTO CMDLBL(RE73))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '74') +
                          THEN(GOTO CMDLBL(RE74))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '75') +
                          THEN(GOTO CMDLBL(RE75))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '76') +
                          THEN(GOTO CMDLBL(RE76))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '77') +
                          THEN(GOTO CMDLBL(RE77))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '78') +
                          THEN(GOTO CMDLBL(RE78))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '79') +
                          THEN(GOTO CMDLBL(RE79))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '80') +
                          THEN(GOTO CMDLBL(RE80))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '81') +
                          THEN(GOTO CMDLBL(RE81))

/****************************************************************/
/************************************************************ */
/*              FACTURACION DE EMPRESAS (10 de cada Mes)      */
/*  RASTREO: VALORES EURIBOR  (Departamento: Contabilidad)    */
/************************************************************ */
/****************************************************************/
             IF         COND(&DD *EQ 10) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('RASTREO: VALORES +
                          EURIBOR                       ' ' ' FS01)

             CALL       PGM(EXPLOTA/RASEURIBOR) PARM(&CODRET)

             IF         (&CODRET *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0044' ' ' FS01)

             CHGVAR     VAR(&DESCRIP) VALUE('Avisar Depart.de +
                          CONTABILIDAD de que debe actualizar +
                          Valores Euribor-FS01M-')

             CHGVAR     VAR(&MSG) VALUE('Avisar al Departamento de +
                          CONTABILIDAD de que debe actualizar +
                          Valores Euribor-FS01M- ***SE CANCELA****')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01M     ') +
                          LONGMSG(&MSG)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((grupoas400@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01M     ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FIN)

             ENDDO

             ENDDO
/****************************************************************/
/************************************************************ */
/*              FACTURACION DE SOCIOS                         */
/*  RASTREO: VALORES SPREAD   (Departamento: Contabilidad)    */
/************************************************************ */
/****************************************************************/

             CALL       PGM(EXPLOTA/RASSPREACL)

/*-------------------------------------------------------------------*/
/*  COPIA DE SEGURIDAD DEL MSOCIO                                    */
/*-------------------------------------------------------------------*/

OTRO_LABEL:  RTVSYSVAL  SYSVAL(QSECOND) RTNVAR(&SS)
             CHGVAR     VAR(&LABEL) VALUE('MSOCIO' || &DDPRO || &SS)
             CHKOBJ     OBJ(LIBSEG30D/&LABEL) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LABEL_OK))
             GOTO       CMDLBL(OTRO_LABEL)

LABEL_OK:    CRTPF      FILE(LIBSEG30D/&LABEL) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(MSOCIO_PF) +
                          TEXT('FS01 - PRINCIPIO FACTURACION +
                          SOCIOS') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)

             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(LIBSEG30D/&LABEL))

             CPYF       FROMFILE(FICHEROS/T_MSOCIO) +
                          TOFILE(LIBSEG30D/&LABEL) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)

             IF         COND(&DD *GE 28) THEN(DO)
             DLTF       FILE(FICHEROS/XOPAMSOC)
             MONMSG     MSGID(CPF0000)
             CRTDUPOBJ  OBJ(&LABEL) FROMLIB(LIBSEG30D) +
                          OBJTYPE(*FILE) TOLIB(FICHEROS) +
                          NEWOBJ(XOPAMSOC) DATA(*YES)
             ENDDO

/*================================================================= */
/*=                     --- M E N S U A L --                      = */
/*= 1ª FACTURACION MES (05) CREA EXTRASOCmm (Spooles/Microfichas) = */
/*================================================================= */

             IF         COND(&DD *EQ 05) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('    PRIMERA +
                          FACTURACION DEL MES, CREA EXTRASOCmm +
                          (Microfichas Mensuales)      ' ' ' FS01)
             CALL       PGM(EXPLOTA/CRMICROMES) PARM(&MM)
             CHGJOB     DATE(&FECHA)
             ENDDO
/*********************************************************************/
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 01 */
/*-------------------------------------------------------------------*/
/*-- ACT.LOGICO -MSOCILG4- SEGUN DIA FACT. Y CREA: MSOCIO88 Y 87   --*/
/*-------------------------------------------------------------------*/
/*----------------------------------------*/
/* -FS1MS- PARA MOD. EL QDDSSRC.MSOCILG4  */
/*----------------------------------------*/
 RE1:        CALL       PGM(EXPLOTA/TRACE) PARM('                +
                          PROGRAMA -FS1MS-  EN EJECUCION        ' ' +
                          ' FS01)
             OVRDBF     FILE(MSOCILG4) TOFILE(FICHEROS/QDDSSRC) +
                          MBR(MSOCILG4) SHARE(*YES)

             CL1        LABEL(INCFS1MS) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCFS1MS)

             CALL       PGM(EXPLOTA/FS1MS)

             DLTOVR IMP0017

             RTVMBRD    FILE(FICHEROS/INCFS1MS) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 0 ) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('FS1MS -INCIDENCIAS EN +
                          LA MODIFICACION DEL MSOCILG4 PARA LA FAC. +
                          DE SOCIOS')

             CHGVAR     VAR(&TEX) VALUE('FS1MS -INCIDENCIAS EN +
                          MSOCILG4 PARA FAC.SOCIOS')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE(&DESCRIP)

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             CHGVAR     VAR(&TEX) VALUE(&DESCRIP)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(INCFS1MS FICHEROS +
                          INCFS1MS LIBSEG30D C ' ' ' ' &TEX FS01)

             ENDDO
             CHGJOB     DATE(&FECHA)
/*---------------*/
/* CREA MSOCILG4 */
/*---------------*/
             DLTOVR     MSOCILG4
             DLTF       FILE(FICHEROS/MSOCILG4)
             MONMSG     CPF0000
             CRTLF      FILE(FICHEROS/MSOCILG4) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
/*-------------------------------------*/
/* -FS2MS- CREACION MSOCIO87-MSOCIO88  */
/*-------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('                +
                          PROGRAMA -FS2MS-  EN EJECUCION        ' ' +
                          ' FS01)

             CRTPF      FILE(FICHEROS/MSOCIO88) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(MSOCIO_PF) +
                          TEXT('facturacion de socios') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/MSOCIO88))

             CRTPF      FILE(FICHEROS/MSOCIO87) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(MSOCIO_PF) +
                          TEXT('facturacion de socios') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/MSOCIO87))

             CL1        LABEL(INCFS2MS) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCFS2MS)

             CALL       PGM(EXPLOTA/FS2MS)

             DLTOVR     IMP0017

             RTVMBRD    FILE(FICHEROS/INCFS2MS) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 4 ) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('HAY INCIDENCIAS EN EL +
                          *FS2MS** FS2MS   -SE CANCELA')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE(&DESCRIP)

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             IF         COND(&CODRET *EQ '1') THEN(DO)
                    GOTO       CMDLBL(FIN)
             ENDDO

             ENDDO

             CHGJOB     DATE(&FECHA)

             /* PARTE MASTERCARD */
             /* FILTRAMOS DE MSOCIO88 LOS PRODUCTOS MASTERCARD Y LOS */
             /* LLEVAMOS A MSOCIO88MC */
             CRTPF      FILE(FICHEROS/MSOCIO88MC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(MSOCIO_PF) +
                          TEXT('Facturacion de Socios MC') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/MSOCIO88MC))

       /* Se crea y copia los registros en el MSOCIO88DI para dejar DINERS*/
             CPYF       FROMFILE(FICHEROS/MSOCIO88) +
                        TOFILE(FICHEROS/MSOCIO88DI) +
                        MBROPT(*REPLACE) CRTFILE(*YES)

       /* Deja en MSOCIO88DI Solo DINERS */
       /* Deja en MSOCIO88MC Solo MASTERCARD */

          /* CALL       PGM(PARONMC1)  */
     /* VERIFICACIONES MC ************************************ */
     /*    *MSOCIO87: SOLO PE                                  */
     /*    *MSOCIO88: *10, 20, 30: (INCLUIDO DIN + MC)         */
     /*                            *5, 15, 25: PI              */
     /* ****************************************************** */
             CALL       PGM(EXPLOTA/MC00005)
          /* CALL       PGM(PARONMC2)  */
     /* VERIFICACIONES MC ************************************ */
     /*     *MSOCIO88DI: SOLO DINERS                           */
     /*     *MSOCIO88MC: SOLO MASTERCARD                       */
     /* ****************************************************** */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 02 */
/*-------------------------------------------------------------------*/
/*   "CONCILIACION CUENTAS DE VIAJES"    ---- M E N S U A L ----     */
/* CLP.CIBOLSAS: CONTABILIDAD SITUACION BOLSAS AGENCIAS/PROVEEDORES  */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/*    INFORME DE TARJETA DEL BANCO SANTANDER --10052378              */
/*    ENVIO MENSUAL     **ISANTANTER CLP                             */
/*-------------------------------------------------------------------*/
 RE2:        IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(EXPLOTA/CIBOLSAS) PARM(&FECHA)
             CALL       PGM(EXPLOTA/ISANTANDER) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)
             ENDDO

/*---------------------------------------------------------------------*/
/*-CLP.ATRCRUPACL-ENRIQUECIMIENTO DATOS DESDE MINERVA,TARJ.T2 (CRUCES) */
/*                                                                     */
/*SE EJECUTA ESTE PROCESO POR EL ENVIO DE FICHEROS DE AGENCIAS(VIERNES)*/
/*Y NO EJECUTARSE LA MIGRACION HASTA EL DOMINGO MADRUGADA              */
/*---------------------------------------------------------------------*/

             IF         COND((&DD = 10) *OR (&DD = 20) *OR (&DD > +
                          28)) THEN(DO)

             CALL       PGM(EXPLOTA/ATRCRUPACL)

             ENDDO
/*********************************************************************/
/*-------------------------------------------------------------------*/
/*                " CONCILIACION CUENTAS DE VIAJES "                 */
/*                     ---- Q U I N C E N A L ----                   */
/* 15 DE CADA MES, RECLAMAR A LAS AGENCIAS FICHEROS NO ENVIADOS      */
/* 15 DE CADA MES, RECORDATORIO REGULARIZAR/ENVIAR BOLSAS            */
/*-------------------------------------------------------------------*/
             IF         COND(&DD *EQ 15) THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('                +
                          PROGRMA -CON15D- EN EJECUCION         ' ' +
                          ' FS01)

             CHKOBJ     OBJ(FICHEROS/ECTASCON) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOECTAS))

             CRTLF      FILE(FICHEROS/ECTASLG1) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('conciliacion, ectascon- para +
                          rpg.con15d') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CALL       PGM(EXPLOTA/CON15D) /* Reclamar */

             D1         LABEL(ECTASLG1) LIB(FICHEROS)
/*-----------------*/
/*- MESES IMPARES -*/
/*-----------------*/
 NOECTAS:    IF         COND(&MM = '02') THEN(GOTO CMDLBL(NOIMPAR))
             IF         COND(&MM = '04') THEN(GOTO CMDLBL(NOIMPAR))
             IF         COND(&MM = '06') THEN(GOTO CMDLBL(NOIMPAR))
             IF         COND(&MM = '08') THEN(GOTO CMDLBL(NOIMPAR))
             IF         COND(&MM = '10') THEN(GOTO CMDLBL(NOIMPAR))
             IF         COND(&MM = '12') THEN(GOTO CMDLBL(NOIMPAR))
             CALL       PGM(EXPLOTA/CRE15D) /* Recordatorio */
 NOIMPAR:
/*-----------------*/
             ENDDO
             CHGJOB     DATE(&FECHA)
/*********************************************************************/
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 03 */
/*-------------------------------------------------------------------*/
/*  COPIA A LIBSEG30D: FA, PA, MENLACE, MACFACEN                     */
/*               --- DE ENTRADA EN FACTURACION ---                   */
/*-------------------------------------------------------------------*/
 RE3:        CHGVAR     VAR(&TEX) VALUE('FS01, DE ENTRADA EN +
                          FACTURACION                   ')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FA FICHEROS FA +
                          LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MENLACE FICHEROS +
                          MENLACE LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MACFACEN FICHEROS +
                          MACFACEN LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(NOGASTOS FICHEROS +
                          NOGASTOS LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(REGEMP FICHEROS +
                          REGEMP LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(AMPLISEG FICHEROS +
                          AMPLISEG LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CUOTEHIS FICHEROS +
                          CUOTEHIS LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CTLDEVO FICHEROS +
                          CTLDEVO LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSIBANUE FICHEROS +
                          MSIBANUE LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DESCRFAC FICHEROS +
                          DESCRFAC LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 04 */
/*-------------------------------------------------------------------*/
/*--     LIBRE                                                     --*/
/*-------------------------------------------------------------------*/
 RE4:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 05 */
/*-------------------------------------------------------------------*/
/*--  LIBRE  LIBRE                                                 --*/
/*-------------------------------------------------------------------*/
 RE5:
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 06 */
/*-------------------------------------------------------------------*/
/*-- LIBRE  LIBRE  LIBRE  LIBRE                                    --*/
/*-------------------------------------------------------------------*/
 RE6:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 07 */
/*-------------------------------------------------------------------*/
/*--        CHEQUEA SI ESTA: NOABONOS, SINO MANDO CREAR            --*/
/*-------------------------------------------------------------------*/
 RE7:        CHKOBJ     OBJ(FICHEROS/NOABONOS) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('fichero -NOABONOS- +
                          no existe. Comprobar si hay evidencias, +
                          si no hay, ' ' ' FS01)

             CRTPF      FILE(FICHEROS/NOABONOS) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('NOABONOS +
                          PARA LA FACTURACION DE SOCIO') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             ENDDO
/*-----*/
             CHGVAR     VAR(&TEX) VALUE('FS01, DE ENTRADA EN +
                          FACTURACION')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(NOABONOS FICHEROS +
                          NOABONOS LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 08 */
/*-------------------------------------------------------------------*/
/*-- LIBRE   LIBRE                                                 --*/
/*-------------------------------------------------------------------*/
 RE8:

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 09 */
/*-------------------------------------------------------------------*/
/*-- LIBRE LIBRE                                                   --*/
/*-------------------------------------------------------------------*/
 RE9:


             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 10 */
/*-------------------------------------------------------------------*/
/*--    RPG.ANVIES  -ANEXOS OP.VIRTUALES A CARGO DE SOCIOS-        --*/
/*-------------------------------------------------------------------*/
 RE10:       IF         COND(&DD *GE 28) THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA ANVIES EN EJECUCION ' ' ' FS01)

             CRTPF      FILE(FICHEROS/ASIANVIES) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIANVIES))

/*  ¿Hay Oper.Virtuales Especiales a cargo de un Socio? */
/*  El numero de socio es baja   no se utiliza desde 2007 */
             RTVMBRD    FILE(FICHEROS/FOPVIEL1) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG = 0) THEN(GOTO CMDLBL(NOANVIES))

             CRTPF      FILE(FICHEROS/FAPRE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FA) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000 EXEC(CLRPFM FICHEROS/FAPRE)

             CHGVAR     VAR(&TEX) VALUE('FS01, ANTES   DEL PGM-ANVIES')
             CALL       PGM(CONCOPCL) PARM(FOPVIES   FICHEROS +
                          FOPVIES   LIBSEG30D C ' ' ' ' &TEX FS01)

             CRTPF      FILE(FICHEROS/DETE33) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE33))

             CRTPF      FILE(FICHEROS/CABE33) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE33))

             OVRDBF     FILE(ASIANVIE) TOFILE(FICHEROS/ASIANVIES)
             CALL       EXPLOTA/ANVIES
             DLTOVR     FILE(ASIANVIE)
/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */
             CPYF       FROMFILE(FICHEROS/DETE33) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE33) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01    , DESPUES DEL +
                          PGM-ANVIES')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE33 FICHEROS +
                          DETE33 LIBSEG1D M ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE33 FICHEROS +
                          CABE33 LIBSEG1D M ' ' ' ' &TEX FS01)

             CPYF       FROMFILE(FICHEROS/FAPRE) TOFILE(FICHEROS/FA) +
                          MBROPT(*ADD)
             MONMSG    CPF0000

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-ANVIES')
             CALL       PGM(CONCOPCL) PARM(FOPVIES   FICHEROS +
                          FOPVIES   LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(CONCOPCL) PARM(FAPRE     FICHEROS +
                          FAPRE     LIBSEG30D M ' ' ' ' &TEX FS01)
             ENDDO

             CHGJOB     DATE(&FECHA)
/*-----------------------------------------------------*/
/*-- LIBRE                                            -*/
/*-----------------------------------------------------*/
 NOANVIES:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 11 */
/*-------------------------------------------------------------------*/
/*--   LIBRE  LIBRE                                                --*/
/*-------------------------------------------------------------------*/
 RE11:
             CRTPF      FILE(FICHEROS/PLARESER) RCDLEN(155) +
                          TEXT('plazos reserva para facturar') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PLARESER))


             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 12 */
/*-------------------------------------------------------------------*/
/*--   LIBRE  LIBRE                                                --*/
/*-------------------------------------------------------------------*/
RE12:



             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 13 */
/*-------------------------------------------------------------------*/
/* DELOITTE: CREA LINEA-2 PARA OPERACIONES DE TPV'S (130/10020367).*/
/*           A DIARIO SE EJECUTA PGM-DELOITTE EN CLP-SEGDIACL.     */
/*                                                                  */
/*          CHEQUEAR DESCRIPCIONES ENTRE -PA- Y -DESCRFAC-           */
/*-------------------------------------------------------------------*/
 RE13:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                           PROGRAMA +
                          -DELOITTE- EN EJECUCION' ' ' FS01)

             CALL       PGM(EXPLOTA/DELOITTE)

            /*----*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -CHKDESDICL          - EN +
                          EJECUCION' ' ' FS01)

             CALL       PGM(EXPLOTA/CHKDESDICL)

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -CHKDES- EN EJECUCION' ' ' FS01)
             CL1        LABEL(INCCHKDE) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCCHKDE)

             CALL       PGM(EXPLOTA/CHKDES)

             DLTOVR     FILE(IMP0017)


             RTVMBRD    FILE(FICHEROS/INCCHKDE) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 15 ) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('Hay mas de 10 +
                          incidencias de un num. de trabajo, FS01M. +
                          Revisar INCCHKDE.')

             CHGVAR     VAR(&DESCTOT) VALUE('Hay mas de 10 +
                          incidencias de un mismo num. de +
                          trabajo,CHKDES. PARAR facturacion Socios +
                          e investigar el motivo  **LLAMAR A Diners +
                          Club Spain')

             CALLSUBR   SUBR(INCIDENCIA)

             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 14 */
/*-------------------------------------------------------------------*/
/*--                CHEQUEO: FCTASCON-MSOCIO-PA                    --*/
/*-------------------------------------------------------------------*/
 RE14:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -CHKCON- EN EJECUCION' ' ' FS01)

             CL1        LABEL(INCCHKCO) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCCHKCO)

             CALL       PGM(EXPLOTA/CHKCON) PARM(&RTCDE)
             DLTOVR     FILE(IMP0017)

             IF         COND(&RTCDE = '1') THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('RECOGER DE LA +
                          IMPRESORA EL LISTADO DE INCIDENCIAS -TEMA +
                          CONCILIACION-         ' ' ' FS01)

             RTVMBRD    FILE(FICHEROS/INCCHKCO) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 3 ) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('HAY INCIDENCIAS EN +
                          CUENTAS (SUBSIDIARIAS) MARCAS DE +
                          CONCIL.FCTASCON/MSOCIO/PA')

             CHGVAR     VAR(&DESCTOT) VALUE('INCIDENCIAS EN CONTROL +
                          CUENTAS (SUBSIDIARIAS) DEBEN TENER TODAS +
                          LAS  MARCAS DE LA CONCILIACION. +
                          FCTASCON/MSOCIO/PA **FACT.SOCIOS FS01M  +
                          **LLAMAR A Diners Club Spain')

             CALLSUBR   SUBR(INCIDENCIA)

             DLTDLO     DLO(INCCHKCO) FLR(VARMAIL)
             MONMSG     MSGID(CPF0000)

             CPYTOPCD   FROMFILE(FICHEROS/INCCHKCO) TOFLR(VARMAIL) +
                          REPLACE(*YES)

             CHGVAR     VAR(&TEX) VALUE('CONCILIACION MARCAS: +
                          FCTASCON-MSOCIO-PA (INVESTIGAR) CLP.FS01M +
                          (PGM-CHKCON)')

             SNDDST     TYPE(*DOC) +
                          TOINTNET((grupoas400@dinersclub.es *PRI)) +
                          DSTD('CHKCON-CHEQUEO: +
                          FCTASCON-MSOCIO-PA') MSG(&TEX) +
                          DOC(INCCHKCO) FLR(VARMAIL)

             CHGVAR     VAR(&TEX) VALUE('FS01M, INCCHKCO INCIDENCIAS +
                          MARCAS CONCILIACION   ')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(INCCHKCO FICHEROS +
                          INCCHKCO LIBSEG1D C ' ' ' ' &TEX FS01)

             ENDDO

             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 15 */
/*-------------------------------------------------------------------*/
/*--  LIBRE                                                        --*/
/*-------------------------------------------------------------------*/
RE15:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 16 */
/*-------------------------------------------------------------------*/
/*-- AL 10 DE ENERO LIMPIO EL MEMPRE  -CTAS. QUE CONCILIAN (NO)-   --*/
/*-------------------------------------------------------------------*/
 RE16:       IF         COND(&DDMMP = 1001) THEN(DO)
/*---*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -LIMPEM- EN EJECUCION' ' ' FS01)
/*---------------*/
/*  L I M P E M  */
/*---------------*/
             CALL       PGM(EXPLOTA/LIMPEM)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-LIMPEM')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MEMPRE FICHEROS +
                          MEMPRE LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('- COMPROBAR QUE +
                          VARIAS EMPRESAS TIENEN LIMPIOS LOS +
                          ACUMULATIVOS.         ' ' ' FS01)

             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 17 */
/*-------------------------------------------------------------------*/
/*- CLASIFICACION FA Y PA. "CONCILIACION" LIMPIAR HISTORICOS (BATCH) */
/*-------------------------------------------------------------------*/
 RE17:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  SORT DEL -FA-      ' ' ' FS01)

             CL1        LABEL(SORTFAPA) /* Control Proximo Extracto */
/*=============*/
/*  SORT -FA-  */
/*=============*/
 ALOCA1:     ALCOBJ     OBJ((FICHEROS/FA *FILE *EXCL))
             MONMSG     MSGID(CPF0000) EXEC(DO)
/*----------------------------------------------------------------------*/
/*   QUIEN TIENE ALOCATADO EL -FA   - SE MANDA MENSAJE Y SE CANCELA JOB */
/*----------------------------------------------------------------------*/
             CHGVAR     VAR(&MSG) VALUE('Facturacion de Socios, +
                          pongase en el menu general durante 5 +
                          minutos, de lo contrario esta pantalla se +
                          cancelara.')

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(FA *FILE +
                          FICHEROS &MSG &BLOQUEA)

             IF         COND(&BLOQUEA *EQ 'B') THEN(DO)
             GOTO       ALOCA1
             ENDDO

             ENDDO

/*=============*/

/*--------------------------------------------------------------*/
/*   01/6/2023 ELIMINAR SORT (SFA) QUE CLASIFICABA EL -FA-    */
/*--------------------------------------------------------------*/
             CRTLF      FILE(FICHEROS/SFA) SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('LOGICO -FA- POR Nº.TARJETA Y CODIGO +
                          OPERACION') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             RGZPFM     FILE(FICHEROS/FA) KEYFILE(FICHEROS/SFA SFA)

             D1         LABEL(SFA) LIB(FICHEROS)
/*--------------------------------------------------------------*/

             DLCOBJ     OBJ((FICHEROS/FA *FILE *EXCL))
             MONMSG     MSGID(CPF0000)

/*=============*/
/*  SORT -PA-  */
/*=============*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  SORT DEL -PA-      ' ' ' FS01)

 ALOCA2:     ALCOBJ     OBJ((FICHEROS/PA *FILE *EXCL))
             MONMSG     MSGID(CPF0000) EXEC(DO)
/*----------------------------------------------------------------------*/
/*   QUIEN TIENE ALOCATADO EL -PA   - SE MANDA MENSAJE Y SE CANCELA JOB */
/*----------------------------------------------------------------------*/
             CHGVAR     VAR(&MSG) VALUE('Facturacion de Socios, +
                          pongase en el menu general durante 5 +
                          minutos, de lo contrario esta pantalla se +
                          cancelara.')

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(PA *FILE +
                          FICHEROS &MSG &BLOQUEA)

             IF         COND(&BLOQUEA *EQ 'B') THEN(DO)
             GOTO       CMDLBL(ALOCA2)
             ENDDO

             ENDDO

/*=============*/

             DLTF       FILE(FICHEROS/PACONL*)
             MONMSG     MSGID(CPF0000)

/*-------------------------------------------------------------*/
/*    1/6/2023 ELIMINAR SORT (SPA) QUE CLASIFICABA EL -PA-   */
/*-------------------------------------------------------------*/
             CRTLF      FILE(FICHEROS/SPA) SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('LOGICO -PA- SUSTITUYE AL SORT +
                          SPA') OPTION(*NOLIST *NOSRC) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             RGZPFM     FILE(FICHEROS/PA) KEYFILE(FICHEROS/SPA SPA)

             D1         LABEL(SPA) LIB(FICHEROS)
/*-------------------------------------------------------------*/

             DLCOBJ     OBJ((FICHEROS/PA *FILE *EXCL))
             MONMSG     MSGID(CPF0000)

             D1         LABEL(SORTFAPA) LIB(FICHEROS)
/*-------------------------------------------*/
/* "CONCILIACION" LIMPIAR HISTORICOS (BATCH)  */
/*  SE EJECUTA EN LA 2º PARTE DE LA CONTABLE  */
/*-------------------------------------------*/
/*           IF         COND(&DD *GE 28) THEN(DO)                    */
/*           SBMQBATCH  NOMJOB(CLIMHICL) FECPRO(&FECHA) +            */
/*                        DESBRE('Proceso FIN DE MES -FS01- ') +     */
/*                        CMD('call explota/CLIMHICL')               */
/*           ENDDO                                                   */
/*-------------------------------------------*/

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 18 */
/*-------------------------------------------------------------------*/
/*-- SAPNB_aux  (Fichero Auxiliar Condiciones Aplazamiento TE'S)   --*/
/*-------------------------------------------------------------------*/
 RE18:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -MSAPNB2- EN EJECUCION' ' ' FS01)

             CRTLF      FILE(FICHEROS/SAPNBLG1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('SAPNB- +
                          PARA RPG.MSAPNB2') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/SAPNB_AUX) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('FICHERO +
                          AUXILIAR CONDICIONES DE APLAZAMIENTO +
                          TE''S') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SAPNB_AUX))

             CALL       PGM(EXPLOTA/MSAPNB2)

             CHGVAR     VAR(&TEX) VALUE('FS01, ANTES DE EJECUTAR +
                          -FSFAPA-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SAPNB FICHEROS +
                          SAPNB LIBSEG30D C ' ' ' ' &TEX FS01) /* +
                          Maestro */
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SAPNB_AUX +
                          FICHEROS SAPNBA LIBSEG30D C ' ' ' ' &TEX +
                          FS01) /* Auxiliar */

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 19 */
/*-------------------------------------------------------------------*/
/*--                     RPG. F S F A P A                          --*/
/*-------------------------------------------------------------------*/
 RE19:

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -FSFAPA- EN EJECUCION' ' ' FS01)

             CRTPF      FILE(FICHEROS/FAPA) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('FUSION DE +
                          FA Y PA, FAPA DE SALIDA') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/FAPA))

             CRTPF      FILE(FICHEROS/FASALE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FA) +
                          TEXT('FA DE SALIDA') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FASALE))

             CRTPF      FILE(FICHEROS/PASALE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(PA) +
                          TEXT('PA DE SALIDA EN EL FSFAPA') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PASALE))

             CRTPF      FILE(FICHEROS/ASIFAPA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('asiento regularizacion moneda') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFAPA))

             CRTPF      FILE(FICHEROS/EVIDEMO) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/EVIDEMO))

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAPA)

             CRTPF      FILE(FICHEROS/DETEPA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEPA))
             CRTPF      FILE(FICHEROS/CABEPA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABEPA))

/* -PARA EVIDENCIAS CONTABLES DIGITALES */
      /* -GASTOS CUENTAS ANUALES */
             CL1        EVIFSFAP1 FICHEROS 132
             OVRDBF     FILE(IMP3017) TOFILE(EVIFSFAP1)
      /* -GASTOS CUENTAS ANUALES (TARJETAS PE) */
             CL1        EVIFSFAP2 FICHEROS 132
             OVRDBF     FILE(IMP4017) TOFILE(EVIFSFAP2)
      /* -TRASPASOS POR CAMBIOS FECHA FACTURACION */
             CL1        EVIFSFAP3 FICHEROS 132
             OVRDBF     FILE(IMP5017) TOFILE(EVIFSFAP3)
      /* -AJUSTES DE MONEDA */
             CL1        EVIFSFAP4 FICHEROS 132
             OVRDBF     FILE(IMP7017) TOFILE(EVIFSFAP4)
/*-----*/
             CHGJOB     SWS(XXXXXX00)

  /* SE LLENA EL PAENT, FAENT, PAENRMC Y FAENTMC CON TODO PA Y FA */
  /* -LOS FILTRARA EL PGM MC0100 PARA DEJAR SOLO DINERS O SOLO MC */

             CPYF       FROMFILE(FICHEROS/PA) TOFILE(FICHEROS/PAENT) +
                          MBROPT(*REPLACE) CRTFILE(*YES)

             CPYF       FROMFILE(FICHEROS/PA) TOFILE(FICHEROS/PAENTMC) +
                          MBROPT(*REPLACE) CRTFILE(*YES)

             CPYF       FROMFILE(FICHEROS/FA) TOFILE(FICHEROS/FAENT) +
                          MBROPT(*REPLACE) CRTFILE(*YES)

             CPYF       FROMFILE(FICHEROS/FA) TOFILE(FICHEROS/FAENTMC) +
                          MBROPT(*REPLACE) CRTFILE(*YES)
  /* Elimina Registros de MC o deja solo MC PAENT, FAENT, PAENRMC Y FAENTMC */
         /*  CALL       PGM(PARONMC3)   */
     /* VERIFICACIONES MC ************************************ */
     /* A1*TOTALIZAR      PAENT     DINERS + MC                */
     /* A2*TOTALIZAR      FAENT     DINERS + MC                */
     /* ****************************************************** */
             CALL MC0100
          /* CALL       PGM(PARONMC4)   */
     /* VERIFICACIONES MC ************************************ */
     /* B1*TOTALIZAR      PAENT     DINERS                     */
     /* B2*TOTALIZAR      FAENT     DINERS                     */
     /* B3*TOTALIZAR      PAENTMC   DINERS                     */
     /* B4*TOTALIZAR      FAENTMC   DINERS                     */
     /* *VERIFICAR:                                            */
     /*  A1=B1+B3                                              */
     /*  A2=B2+B4                                              */
     /* ****************************************************** */

             OVRDBF     FILE(FAENTRA) TOFILE(FICHEROS/FAENT) +
                          LVLCHK(*NO) /* FA DE ENTRADA */
             OVRDBF     FILE(PAENTRA) TOFILE(FICHEROS/PAENT) +
                          LVLCHK(*NO) /* PA DE ENTRADA */

  /* ESTE PROGRAMA DEBE VER EL PA Y EL FA SIN MC */
             CALL       PGM(EXPLOTA/FSFAPA)

          /* CALL       PGM(PARONMC5) */
     /* VERIFICACIONES MC ************************************ */
     /*   *REVISAR TOTALIZADORES                               */
     /*              PAGE00 Y FAGE00   (SOLO DINERS)           */
     /*       -CUADRAR Nº OPERACIONES CON SPOOL FSFAPA (P12)   */
     /*       -REVISAR SOLO TARJETAS MC EN FAPA                */
     /*       -SALIDA: FAPA            (FACTURADAS)            */
     /*                FASALE + PASALE (NO FACTURADAS)         */
     /* ****************************************************** */

             DLTOVR     FILE(PAENTRA)
             DLTOVR     FILE(FAENTRA)

 /*------------------------------------------------*/
 /* EVIADDCL CREA LA EVIDENCIA CONTABLE            */
 /* LA PARTE MASTERCARD NO SE HACE POR EVIADDCL    */
 /*  -GASTOS CTAS. ANULES                          */
 /*------------------------------------------------*/
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFSFAP1 ' +
                          'ASIFAPA   ' 'GASTOS CUENTAS +
                          ANUALES                            ' +
                          'FS01      ' '      ' ' ')

             CHGJOB     DATE(&FECHA)

 /*--------------------------------------*/
 /* EVIADDCL CREA LA EVIDENCIA CONTABLE  */
 /*  -GASTOS CTAS. ANULES - TARJETAS PE  */
 /*--------------------------------------*/
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFSFAP2 ' +
                          'ASIFAPA   ' 'GASTOS CUENTAS +
                          ANUALES (TARJETAS P. EMPRESA)      ' +
                          'FS01      ' '      ' ' ')

             CHGJOB     DATE(&FECHA)

 /*--------------------------------------*/
 /* EVIADDCL CREA LA EVIDENCIA CONTABLE  */
 /*  -TRASPASOS POR CAMBIOS FECHA FACT.  */
 /*--------------------------------------*/
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFSFAP3 ' +
                          'ASIFAPA   ' 'TRASPASOS POR CAMBIOS EN +
                          FECHA FACTURACION        ' 'FS01      ' +
                          '      ' ' ')

             CHGJOB     DATE(&FECHA)

 /*--------------------------------------*/
 /* EVIADDCL CREA LA EVIDENCIA CONTABLE  */
 /*  -AJUSTES DE MONEDA                  */
 /*--------------------------------------*/
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFSFAP4 ' +
                          'ASIFAPA   ' 'AJUSTES DE +
                          MONEDA                                 ' +
                          'FS01      ' '      ' ' ')

             CHGJOB     DATE(&FECHA)
/*-------------------------------------------------------------*/
/*-- Copias Seguridad Parciales Evidencias Contables (FSFAPA) -*/
/*-------------------------------------------------------------*/
             CPYF       FROMFILE(FICHEROS/CABEPA) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/DETEPA) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/EVIDEMO) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FROMRCD(1)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSFAPA ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEPA FICHEROS +
                          DETEPA LIBSEG1D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEPA FICHEROS +
                          CABEPA LIBSEG1D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(EVIDEMO FICHEROS +
                          EVIDEMO LIBSEG1D C ' ' ' ' &TEX FS01)

/*----------------------*/
/*-- COPIAS SEGURIDAD --*/
/*----------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-FSFAPA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PLARESER FICHEROS +
                          PLARESER LIBSEG30D C ' ' ' ' &TEX FS01)
 /*·····························*/
 /* FAPA: CONTROLES IMPORTANTES */
 /*·····························*/
             IF         COND(%SWITCH(xxxxxx11))   THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('En el PA hay al +
                          menos una operacion con fecha de entrada +
                          en Diners superior a ' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('la del presente +
                          proceso.' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('U7 Y U8 Asteriscado +
                          en PGM' ' ' FS01)
             ENDDO
 /*······*/
             CHGVAR     VAR(&CODRET) VALUE(' ')
             CALL       PGM(EXPLOTA/CHKFAPA) PARM(&CODRET) /* T.DUAL */

             IF         (&CODRET *EQ 'D') THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('En el fichero +
                          -FAPA- hay al menos una operación de +
                          "Tarjetas Duales".         ' ' ' FS01)
             ENDDO
/*------------------------------------------------*/
/* PARTE MASTERCARD *******************************/
/*------------------------------------------------*/
             CRTPF      FILE(FICHEROS/FAPAMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FAPA) +
                          TEXT('FUSION DE FA Y PA, FAPA DE SALIDA') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/FAPAMC))

             CRTPF      FILE(FICHEROS/FASALEMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FA) +
                          TEXT('FA DE SALIDA') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FASALEMC))

             CRTPF      FILE(FICHEROS/PASALEMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(PA) +
                          TEXT('PA DE SALIDA EN EL FSFAPA') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PASALEMC))

             CRTPF      FILE(FICHEROS/ASIFAPAMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILEN) +
                          TEXT('Asiento Gastos Demora') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFAPAMC))

             CRTPF      FILE(FICHEROS/DETEPAMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          TEXT('Evidencias Contable FSFAPA MC') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEPAMC))

             CRTPF      FILE(FICHEROS/CABEPAMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          TEXT('Cab. Evid. Contables FSFAPA MC') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABEPAMC))

             OVRDBF     FILE(ASIFILEN) TOFILE(FICHEROS/ASIFAPAMC)

/* COPIAS DE SEGURIDAD DE LA DATA DE ENTRADA MC */
             CHGVAR     VAR(&TEX)    +
                        VALUE('FS01, ANTES DEL PGM-FSFAPAMC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAENTMC FICHEROS +
                          FAENTMC LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAENTMC FICHEROS +
                          PAENTMC LIBSEG30D C ' ' ' ' &TEX FS01)

/* -PARA EVIDENCIAS CONTABLES DIGITALES */
      /* -GASTOS CUENTAS ANUALES */
             CL1        EVIFSFAP1 FICHEROS 132
             OVRDBF     FILE(IMP3017) TOFILE(EVIFSFAP1)
      /* -GASTOS CUENTAS ANUALES (TARJETAS PE) */
             CL1        EVIFSFAP2 FICHEROS 132
             OVRDBF     FILE(IMP4017) TOFILE(EVIFSFAP2)
      /* -TRASPASOS POR CAMBIOS FECHA FACTURACION */
             CL1        EVIFSFAP3 FICHEROS 132
             OVRDBF     FILE(IMP5017) TOFILE(EVIFSFAP3)
      /* -AJUSTES DE MONEDA */
             CL1        EVIFSFAP4 FICHEROS 132
             OVRDBF     FILE(IMP7017) TOFILE(EVIFSFAP4)
  /* ESTE PROGRAMA DEBE VER EL PA Y EL FA SOLO MC */

             CALL       PGM(EXPLOTA/FSFAPAMC)

          /* CALL       PGM(PARONMC6) */
     /* VERIFICACIONES MC ************************************ */
     /*   *REVISAR TOTALIZADORES                               */
     /*              PAGE00 Y FAGE00   (SOLO MC)               */
     /*       -CUADRAR Nº OPERACIONES CON SPOOL FSFAPAMC (P12) */
     /*       -REVISAR SOLO TARJETAS MC EN FAPAMC              */
     /*       -SALIDA: FAPAMC          (FACTURADAS)            */
     /*                FASALEMC + PASALEMC (NO FACTURADAS)     */
     /*       -REVISAR ASIENTOS TRASPASO (ASIFAPAMA  VACIO)    */
     /*       -REVISAR MOVIMIENTOS MC(NINGUN 'L' EN FAPAMC)    */
     /*                              (995-SEGURO, 998-DEMORA)  */
     /* ****************************************************** */

             /*------------------------------------------*/
             /*    Copias luego del FSFAPAMC             */
             /*------------------------------------------*/
              CPYF FROMFILE(FICHEROS/FAPAMC) +
                   TOFILE(FICHEROS/FAPA)     +
                   MBROPT(*ADD)

              CPYF FROMFILE(FICHEROS/FASALEMC) +
                   TOFILE(FICHEROS/FASALE)       +
                   MBROPT(*ADD)
              CPYF FROMFILE(FICHEROS/PASALEMC) +
                   TOFILE(FICHEROS/PASALE)       +
                   MBROPT(*ADD)
             /*------------------------------------------*/

             CHGVAR     VAR(&TEX)    +
                        VALUE('FS01, DESPUES DEL PGM-FSFAPAMC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPAMC FICHEROS +
                          FAPAMC LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FASALEMC FICHEROS +
                          FASALEMC LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PASALEMC FICHEROS +
                          PASALEMC LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FASALE FICHEROS +
                          FASALE LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PASALE FICHEROS +
                          PASALE LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)

 /* INFORME TARJETAS MULTIPROCESO */
             CALL       PGM(EXPLOTA/FSINMU)

             DLTOVR     FILE(IMP3017)
             DLTOVR     FILE(IMP4017)
             DLTOVR     FILE(IMP5017)
             DLTOVR     FILE(IMP7017)

             CHGJOB     DATE(&FECHA)
/*------------------------------------------------*/
/* PARTE MASTERCARD EVIDENCIAS CONTABLES          */
/*------------------------------------------------*/
             DLTOVR     FILE(ASIFILEN)
             CPYF       FROMFILE(FICHEROS/DETEPAMC) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABEPAMC) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01M - MC - EVIDENCIAS +
                            CONT. RECIBOS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEPAMC FICHEROS +
                          DETEPAMC LIBSEG1D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEPAMC FICHEROS +
                          CABEPAMC LIBSEG1D C ' ' ' ' &TEX FS01)

            /* PARTE MASTERCARD ASIFILEN */
            /* TO-DO SE HACE AQUI - YA TIENEN APUNTE CONTABLE */
            RTVMBRD FILE(FICHEROS/ASIFAPAMC) NBRCURRCD(&NUMREG)
            IF COND(&NUMREG > 0) THEN(DO)
              CHGVAR VAR(&TEXTO) VALUE('Copia parcial ASIFAPAMC a +
                  fichero general')
              CALL PGM(EXPLOTA/TRACE) PARM(&TEXTO &PARAM &CADENA)

              OVRDBF FILE(ASIFILE) TOFILE(FICHEROS/ASIFAPAMC)
              CALL PGM(EXPLOTA/ACASBON) PARM('002')
              DLTOVR FILE(ASIFILE)

              CHGVAR VAR(&TEX) VALUE('FS01M, DESPUES DE PGM-ACASBON')
              CALL PGM(EXPLOTA/CONCOPCL) PARM(ASIFAPAMC FICHEROS +
                   ASIFAPAMC LIBSEG30D 'M' ' ' ' ' &TEX FS01)
            ENDDO

            CLRPFM FILE(FICHEROS/ASIFAPAMC)
            MONMSG MSGID(CPF0000)

             CHGJOB     DATE(&FECHA)

/*=====================================================*/
/*  CLP-FSCUOTE1CL "CUOTAS Y COSTES POR SERVICIOS"   */
/*=====================================================*/
             CALL       PGM(EXPLOTA/FSCUOTE1CL) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CHKOBJ     OBJ(FICHEROS/FAPACUOTE5) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOFAPAC5))

             RTVMBRD    FILE(FICHEROS/FAPACUOTE5) NBRCURRCD(&NUMREG)

/*==*/
             IF         COND(&NUMREG > 0) THEN(DO)
             CPYF       FROMFILE(FICHEROS/FAPACUOTE5) +
                          TOFILE(FICHEROS/FAPA) MBROPT(*ADD) FROMRCD(1)

             CHGVAR     VAR(&TEX) VALUE('FS01, FAPACUOTE5 "CUOTAS Y +
                          COSTES POR SERVICIOS   ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPACUOTE5 +
                          FICHEROS FAPACUOTE5 LIBSEG30D M ' ' ' ' +
                          &TEX FS01)
             FMTDTA     INFILE((FICHEROS/FAPA)) +
                          OUTFILE(FICHEROS/FAPA) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(SFAPA) +
                          OPTION(*NOPRT)
             ENDDO
/*=====================================================*/
 NOFAPAC5:

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 20 */
/*-------------------------------------------------------------------*/
/*--                F S S E G U  -ADICIONAL SEGURO-                --*/
/*-------------------------------------------------------------------*/
 RE20:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -FSSEGU- EN EJECUCION' ' ' FS01)

             CRTPF      FILE(FICHEROS/ASIFISEG) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('Apunte contratacion adicional +
                          seguros') OPTION(*NOSRC *NOLIST) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFISEG))

             OVRPRTF    FILE(IMP00P5) TOFILE(IMP00P7) PAGESIZE(51 +
                          132) OVRFLW(51) DRAWER(2) OUTQ(P7) +
                          FORMTYPE(IMP00P7) SAVE(*YES)

             CRTPF      FILE(FICHEROS/DETEGU) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEGU))
             CRTPF      FILE(FICHEROS/CABEGU) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABEGU))

             CALL       PGM(EXPLOTA/FSSEGU) PARM('1')

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/EVINUM)

             CHGJOB     DATE(&FECHA)
/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETEGU) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABEGU) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSSEGU')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEGU FICHEROS +
                          DETEGU LIBSEG1D M ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEGU FICHEROS +
                          CABEGU LIBSEG1D M ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/TRACE) PARM('. El apunte de la +
                          contratacion adicional de seguros saldra +
                          pa la P7.         +' ' ' FS01)
             OVRDBF     FILE(ASIFILE) TOFILE(ASIFISEG)
             CALL       PGM(EXPLOTA/ACASBO) PARM('024')
             CHGVAR     VAR(&TEX) VALUE('FS01, SALIDO DEL FSSEGU')
             CALL       PGM(CONCOPCL) PARM(ASIFISEG FICHEROS +
                          ASIFISEG LIBSEG30D M ' ' ' ' &TEX FS01)
             DLTOVR     FILE(IMP00P5)
             DLTOVR     FILE(ASIFILE)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 21 */
/*-------------------------------------------------------------------*/
/*--     LIBRE   LIBRE  LIBRE  LIBRE                               --*/
/*-------------------------------------------------------------------*/
 RE21:
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 22 */

/*-------------------------------------------------------------------*/
/*--     LIBRE   LIBRE  LIBRE  LIBRE                               --*/
/*-------------------------------------------------------------------*/
RE22:
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 23 */
/*-------------------------------------------------------------------*/
/*-- RPG.RASFEU "RASTREO EXTRACTO UNIFICADO" (FAPA/MSOCIO/MENLACE) --*/
/*-------------------------------------------------------------------*/
 RE23:       IF         COND((&DD = 10) *OR (&DD = 20) *OR (&DD = +
                          30)) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  NUEMP   EN EJECUCION.' ' ' FS01)

             CRTPF      FILE(FICHEROS/DETE24) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE24))
             CRTPF      FILE(FICHEROS/CABE24) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE24))

             CALL       PGM(EXPLOTA/NUEMP)

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETE24) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE24) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-NUEMP')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE24 FICHEROS +
                          DETE24 LIBSEG1D M ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE24 FICHEROS +
                          CABE24 LIBSEG1D M ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  RASFEU  +
                          EN EJECUCION' ' ' FS01)

  /* **************************************************** */
  /* DAVID 14/2/2023: EXTRACTO UNIFICADO YA NO SE UTILIZA */
  /*                 -ASTERISCO LA LLAMADA                */
  /* **************************************************** */
       /*  CALL       PGM(EXPLOTA/RASFEU) PARM(&RTCDE) */ /* Extracto +
                          Unificado */
             /*CHGVAR VAR(&RTCDE) VALUE(' ')*/

             /*IF         COND(&RTCDE = '1') THEN(DO)*/

             /*CHGVAR     VAR(&DESCRIP) VALUE('PGM-RASFEU +
                          --FACT.SOCIOS *HAY incidencia, pararse +
                          hasta que se resuelva ...Llamar a Diners +
                          Club Spain')*/

             /*CALLSUBR   SUBR(INCIDENCIA)*/

             /*CHGVAR     VAR(&DESCTOT) VALUE('PGM-RASFEU +
                          --FACT.SOCIOS *HAY incidencia, pararse +
                          hasta que se resuelva ...Llamar a Diners +
                          Club Spain')*/

             /*CHGVAR     VAR(&CODRET) VALUE('0')*/

             /*CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)*/
             /*ENDDO*/

             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 24 */
/*-------------------------------------------------------------------*/
/*--        RPG.FSSEFA PARA CREACION DE: FAPA88 Y FAPA87           --*/
/*-------------------------------------------------------------------*/
 RE24:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  FSSEFA  EN EJECUCION' ' ' FS01)

             CRTPF      FILE(FICHEROS/FAPA88) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FAPA) +
                          TEXT('FUSION DE FA Y PA') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FAPA88))

             CRTPF      FILE(FICHEROS/FAPA87) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FAPA) +
                          TEXT('FUSION DE FA Y PA') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FAPA87))

             CALL       PGM(EXPLOTA/FSSEFA)

             CHGJOB     DATE(&FECHA)

             /* PARTE MASTERCARD */
             /* FILTRAMOS DE LA SIGUIENTE FORMA:                   */
             /* -FAPA88: DIN + MC                                  */
             /* -FAPA88DI: SOLO DIN                                */
             /* -FAPA88MC: SOLO MC                                 */
             CRTPF      FILE(FICHEROS/FAPA88MC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FAPA) +
                          TEXT('FUSION DE FA Y PA MASTERCARD') +
                          OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FAPA88MC))

             CRTPF      FILE(FICHEROS/FAPA88DI) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FAPA) +
                          TEXT('FUSION DE FA Y PA MASTERCARD') +
                          OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FAPA88DI))

             CPYF FROMFILE(FICHEROS/FAPA88) +
                  TOFILE(FICHEROS/FAPA88MC) +
                  MBROPT(*ADD)

             CPYF FROMFILE(FICHEROS/FAPA88) +
                  TOFILE(FICHEROS/FAPA88DI) +
                  MBROPT(*ADD)

             CALL       PGM(EXPLOTA/MC00006)
          /* CALL       PGM(PARONMC7) */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR                                           */
     /*     -FAPA88: DIN + MC                                  */
     /*     -FAPA88DI: SOLO DIN                                */
     /*     -FAPA88MC: SOLO MC                                 */
     /* ****************************************************** */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 25 */
/*-------------------------------------------------------------------*/
/*    L I B R E                                                      */
/*-------------------------------------------------------------------*/
 RE25:
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 26 */
/*-------------------------------------------------------------------*/
/*-                SORT DEL PENCUOTA (SCUOTA)                       -*/
/*-       SE ENVIA A LIBRERIA -NEGRA- "DESCATALOGADO"  15/06/2023   -*/
/*-------------------------------------------------------------------*/
 RE26:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 27 */
/*-------------------------------------------------------------------*/
/*-                    PGM-FSBALA                                   -*/
/*-------------------------------------------------------------------*/
 RE27:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                              +
                          PROGRAMA FSBALA- EN EJECUCION' ' ' FS01)
/*---------------------------------------------------------------------*/
/*         -COPIA DE FICHEROS ANTES DE ACTUALIZAR                    */
/*---------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, ANTES DE FSBALA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88 FICHEROS +
                          MSOCIO88 LIBSEG1D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA88 FICHEROS +
                          FAPA88 LIBSEG1D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCUOTA FICHEROS +
                          PENCUOTA LIBSEG1D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(NOGASTOS FICHEROS +
                          NOGASTOS LIBSEG1D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DINBCH FICHEROS +
                          DINBCH LIBSEG1D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CTLDEVO FICHEROS +
                          CTLDEVO LIBSEG1D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONCPVF FICHEROS +
                          CONCPVF LIBSEG1D C ' ' ' ' &TEX FS01)

/*-------------------------------------------------------------------*/

             CHGVAR     VAR(&REST1) VALUE('FSNOEX' *CAT &DDPRO)
             D1         LABEL(&REST1) LIB(FICHEROS)
             CRTPF      FILE(FICHEROS/&REST1) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(FSNOEXTR) OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)

             /* Se creo el CONTROFSDI solo para Diners */
             CRTPF      FILE(FICHEROS/BSDI) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BS) +
                          OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BSDI))
             /*------------------------------------------ */

             CRTPF      FILE(FICHEROS/FSANUAL) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('control +
                          anuales') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FSANUAL))

            /* Se creo el CONTROFSDI solo para Diners */
             CRTPF      FILE(FICHEROS/CONTROFSDI) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CONTROFS) +
                          OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTROFSDI))
             /*------------------------------------------ */

             CRTPF      FILE(FICHEROS/RECIBOS) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/RECIBOS))

             CRTPF      FILE(FICHEROS/PENCUSAL) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(PENCUOTA) TEXT('CUOTAS +
                          PENDIENTES') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PENCUSAL))

             CRTPF      FILE(FICHEROS/CUOTERCE) RCDLEN(73) +
                          TEXT('CUOTAS TERCEROS') SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CUOTERCE))

             CRTPF      FILE(FICHEROS/ASIBALAN) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILEN) +
                          TEXT('ASIENTO REGULARIZACION MONEDA') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIBALAN))

             CRTPF      FILE(FICHEROS/SFSBALA1) RCDLEN(170) +
                          TEXT('saltadas') SIZE(*NOMAX) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SFSBALA1))

             CRTPF      FILE(FICHEROS/BCHCUOT) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/CPUNTOS) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(LIBROIVA) TEXT('CUOTAS PUNTOS +
                          DINERS -CONTABILIDAD-') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CPUNTOS))

             CRTPF      FILE(FICHEROS/FNETFS) RCDLEN(172) +
                          TEXT(CAIXA) OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FNETFS))

/* TA FINANCIACION AMPLIADA --ACTUALIZA FICHERO **MSTAFAFAC        */
             CRTPF      FILE(FICHEROS/MSTAFAFAC) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('(TA) CON +
                          FINANCIACION AMPLIADA') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/MSTAFAFAC))
             CLRPFM     FILE(FICHEROS/MSTAFAFAC)

             OVRDBF     FILE(MSOCIO) TOFILE(FICHEROS/MSOCIO88)
             CALL       PGM(EXPLOTA/TAFA04)
             DLTOVR     FILE(MSOCIO)

/*-----*/
/* BILLHOP -PLATAFORMA DE PAGO --ACTUALIZA FICHERO **MS_BILLFAC    */
             CRTPF      FILE(FICHEROS/MS_BILLFA1) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(MS_BILLFAC) TEXT('BILLHOP +
                          -Plataforma de Pagos') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/MS_BILLFA1))

             OVRDBF     FILE(MS_BILLFAC) TOFILE(FICHEROS/MS_BILLFA1)
             OVRDBF     FILE(MSOCIO) TOFILE(FICHEROS/MSOCIO88DI)
             CALL       PGM(EXPLOTA/BILLHOP3)
             DLTOVR     FILE(MSOCIO)
             DLTOVR     FILE(MS_BILLFAC)

             CPYF       FROMFILE(FICHEROS/MS_BILLFA1) +
                          TOFILE(FICHEROS/MS_BILLFAC) MBROPT(*ADD) +
                          CRTFILE(*YES) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

/*-----*/
             OVRDBF     FILE(FSNOEXTR) TOFILE(FICHEROS/&REST1)
             OVRDBF     FILE(FNET)     TOFILE(FICHEROS/FNETFS)
             OVRPRTF    FILE(QSYSPRT)  TOFILE(*FILE) OUTQ(P10) +
                          FORMTYPE(IMP00P10) SAVE(*YES)

             CL1        LABEL(EVIFSBALA) LIB(FICHEROS) LON(132) /* +
                          EVIDENCIA CONTABLE DIGITAL */
             OVRDBF     FILE(IMP5017) TOFILE(EVIFSBALA)

/*-----*/
             OVRDBF FILE(FAPAXX) TOFILE(FAPA88DI)
             OVRDBF FILE(MSOCIOXX) TOFILE(MSOCIO88DI)
             CALL       PGM(EXPLOTA/FSBALA)
             DLTOVR     FILE(FAPAXX)
             DLTOVR     FILE(MSOCIOXX)
/*-----*/
             DLTOVR     FILE(IMP5017)
             DLTOVR     FILE(QSYSPRT)
             DLTOVR     FILE(FSNOEXTR)
             DLTOVR     FILE(FNET)

         /*  CALL       PGM(PARONMC8)  */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR SALIDA                                    */
     /*     -BS        SOLO DIN                                */
     /*     -CONTROFS  SOLO DIN                                */
     /*     -RECIBOS   SOLO DIN                                */
     /*     -SFSBALA1   (SALTADAS VACIO)                       */
     /* ****************************************************** */

             CHGJOB     DATE(&FECHA)
 /*--------------------------------------*/
 /* EVIADDCL CREA LA EVIDENCIA CONTABLE  */
 /*--------------------------------------*/
             RTVMBRD    FILE(FICHEROS/ASIBALAN) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFSBALA ' +
                          'ASIBALAN  ' 'CUOTAS VENCIMIENTO +
                          COBRANDED AMERICAN AIRLINES    ' +
                          'FS01      ' '      ' ' ')
             CHGJOB     DATE(&FECHA)
             ENDDO

             CHGJOB     DATE(&FECHA)

/*-------------------------------------------------------------------*/
/*--            CUADRAR TOTALES DE RPG.FSBALA                      --*/
/*-------------------------------------------------------------------*/

/* SI NO CUADRA Y HAY QUE REPETIR EL PROCESO   OJOJOJOJOJOJO */

 /*          CLRPFM     FILE(FICHEROS/BS)                 */
 /*          CLRPFM     FILE(FICHEROS/BSMC)               */
 /*          CLRPFM     FILE(FICHEROS/CONTROFS)           */
 /*          CLRPFM     FILE(FICHEROS/CONTROFSDI)         */
 /*          CLRPFM     FILE(FICHEROS/CONTROFSMC)         */
 /*          CLRPFM     FILE(FICHEROS/RECIBOS)            */
 /*          CLRPFM     FILE(FICHEROS/RECIBOSMC)          */
 /*          CLRPFM     FILE(FICHEROS/PENCUSAL)           */
 /*          CLRPFM     FILE(FICHEROS/CUOTERCE)           */
 /*          CLRPFM     FILE(FICHEROS/FSANUAL)            */
 /*          CLRPFM     FILE(FICHEROS/ASIBALA1)           */
 /*          CLRPFM     FILE(FICHEROS/SFSBALA1)           */
 /*          CLRPFM     FILE(FICHEROS/FSNOEXdd)           */
 /*          CLRPFM     FILE(FICHEROS/CPUNTOS)            */

       CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0054' ' ' FS01)

/* INVESTIGAR LOS MOTÍVOS DEL DESCUADRE Y REPETIR EL PROCESO */

             CHGJOB     DATE(&FECHA)

/*---------------------------------------------------------------------*/
/*          FSBALAMC PARA MASTERCARD                                   */
/*---------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
              PARM('                            +
               PROGRAMA FSBALAMC- EN EJECUCION' ' ' FS01)

/*---------------------------------------------------------------------*/
/*         -COPIA DE FICHEROS ANTES DE ACTUALIZAR                    */
/*---------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, ANTES DE FSBALAMC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88MC FICHEROS +
                        MSOCIO88MC LIBSEG1D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA88MC FICHEROS +
                        FAPA88MC LIBSEG1D C ' ' ' ' &TEX FS01)

/*-------------------------------------------------------------------*/

             CRTPF      FILE(FICHEROS/BSMC) SRCFILE(FICHEROS/QDDSSRC) +
                        SRCMBR(BS) +
                        TEXT('BALANCE SOCIOS MASTERCARD') OPTION(*NOSRC +
                        *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/BSMC))

             CRTPF      FILE(FICHEROS/CONTROFSMC) +
                        SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CONTROFS) +
                        OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                        LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTROFSMC))

             CRTPF      FILE(FICHEROS/RECIBOSMC) +
                        SRCFILE(FICHEROS/QDDSSRC) SRCMBR(RECIBOS) +
                        OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                        LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/RECIBOSMC))

             CRTPF      FILE(FICHEROS/ASIBALANMC) +
                        SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILEN) +
                        TEXT('ASIENTO REGULARIZACION MONEDA') +
                        OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                        LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                        FILE(FICHEROS/ASIBALANMC))

             CL1        LABEL(EVIBALAMC) LIB(FICHEROS) LON(132)
             OVRDBF     FILE(ASIFILEN) TOFILE(ASIBALANMC)

     /*      CALL       PGM(PARONMC9)      */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR ENTRADA                                   */
     /*     MSOCIO88MC  (SOLO MC)                              */
     /*     FAPA88MC    (SOLO MC)                              */
     /*     CONTROFSMC   VACIO                                 */
     /*     RECIBOSMC    VACIO                                 */
     /*     BSMC         VACIO                                 */
     /* ****************************************************** */
             CALL       PGM(EXPLOTA/FSBALAMC) PARM((&NUMAPU))

     /*      CALL       PGM(PARONMC10)    */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR SALIDA                                    */
     /*     CONTROFSMC  (TOTAL FACTURADO MC)                   */
     /*     RECIBOSMC   (FACTURADO  MC)                        */
     /*                 (VERIF. IMPORTE Y VENCIMIENTO)         */
     /*     BSMC        (MOVIMIENTOS BS (26 OPER.)             */
     /*                 (NO COD. '9' DE CUOTA                  */
     /*     ASIBALANMC  (VACIO)                                */
     /* ****************************************************** */

             CHGJOB     DATE(&FECHA)

 /*---------------------------------------------*/
 /* EVIADDCL CREA LA EVIDENCIA CONTABLE PARA MC */
 /*---------------------------------------------*/
             RTVMBRD    FILE(FICHEROS/ASIBALANMC) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM(('EVIBALAMC ') +
                          ('ASIBALANMC') ('CUOTAS VENCIMIENTO ') +
                          ('FS01      ') (&NUMAPU) (' '))
             CHGJOB     DATE(&FECHA)

 /*ASIENTO CONTABLE*/

             OVRDBF     FILE(ASIFILE) TOFILE(ASIBALANMC)
             CALL       PGM(EXPLOTA/ACASBON) PARM('002')
           /*  CALL       PGM(EXPLOTA/ACASBO) PARM('002') */
             DLTOVR     FILE(ASIFILE)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSBALAMC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM((ASIBALANMC) +
                          (FICHEROS) (ASIBALANMC) (LIBSEG30D) (C) +
                          (' ') (' ') (&TEX) (FS01))

             ENDDO

/*---------------------------------------------------------------------*/
/*      COPIA DE FICHEROS BSDI y CONTROFSDI ANTES DE ACTUALIZAR        */
/*       *RECORDAR EN CASO DE CASQUE REGULARIZAR TOTALIZADORES*        */
/*---------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, DESPUES DEL FSBALA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSDI FICHEROS +
                          BSDI LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFSDI FICHEROS +
                          CONTROFSDI LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSMC FICHEROS +
                          BSMC LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFSMC FICHEROS +
                          CONTROFSMC LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECIBOSMC FICHEROS  +
                          RECIBOSMC LIBSEG30D C ' ' ' ' &TEX FS01)

              CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECIBOS FICHEROS  +
                          RECIBOS LIBSEG30D C ' ' ' ' &TEX FS01)

/* -------------------------------------------------- */
/* Fusionamos:                                        */
/*      BSDI y BSMC en el BS                          */
/*      CONTROFSDI y CONTROFSMC en el CONTROFS        */
/* -------------------------------------------------- */
             /* BS */
             CRTPF      FILE(FICHEROS/BS) SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('BALANCE SOCIOS') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/BS))
             /* CONTROFS */
             CRTPF      FILE(FICHEROS/CONTROFS) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTROFS))

            /* Copia de Parciales CONTROFS */
             CPYF   FROMFILE(FICHEROS/CONTROFSDI) +
                          TOFILE(FICHEROS/CONTROFS) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             CLRPFM  FICHEROS/CONTROFSDI

             CPYF   FROMFILE(FICHEROS/CONTROFSMC) +
                          TOFILE(FICHEROS/CONTROFS) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             D1         LABEL(CONTROFSMC) LIB(FICHEROS)

             /* Copia de Parciales BS */
             CPYF   FROMFILE(FICHEROS/BSDI) +
                          TOFILE(FICHEROS/BS) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             CLRPFM  FICHEROS/BSDI

             CPYF   FROMFILE(FICHEROS/BSMC) +
                          TOFILE(FICHEROS/BS) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             D1         LABEL(BSMC) LIB(FICHEROS)

         /*  CALL       PGM(PARONMC11)  */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR FUSIONES                                  */
     /*     CONTROFS:    CONTROFSDI + CONTROFSMC => CONTROFS   */
     /*     BS:          BSDI + BSMC => BS                     */
     /* ****************************************************** */

/*---------------------------------------------------------------------*/
/*      COPIA DE FICHEROS BS y CONTROFS DESPUES DEL FSBALA             */
/*---------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, BS DESPUES FSBALA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS FICHEROS +
                          BS LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01M,CONTROFS DESP. FSBALA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFS FICHEROS +
                          CONTROFS LIBSEG30D C ' ' ' ' &TEX FS01)
/* -------------------------------------------------- */
 /*--------------------------------------*/
 /* CONTROL SALDOS ACREEDORES STATUS 1   */
 /*--------------------------------------*/
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ACRESTA1 FICHEROS +
                          ACRESTA1 LIBSEG30D C ' ' ' ' &TEX FS01)
             OVRPRTF    FILE(QSYSPRT) TOFILE(*FILE) OUTQ(P11) +
                          FORMTYPE(IMP00P11) SAVE(*YES)
             CALL       PGM(EXPLOTA/FSACRESTA)
             DLTOVR     FILE(QSYSPRT)

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 28 */
/*-------------------------------------------------*/
/* CUOCTACL                                        */
/*-------------------------------------------------*/
 RE28:

/*---------------------------------------------------*/
/* CUOCTACL - GENERAR CONTABILIZADO Y ASIENTO CUOTAS */
/*---------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA CUOCTACL EN +
                          EJECUCION                  ' ' ' FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/CUOCTACL) PARM('F')
             CHGJOB     DATE(&FECHA)
/*-------------------------------------------------*/
/*SEATBFTOI1 - SEAT: Tarjetas Operativa Interna. */
/* (Fin de Mes) Rescatar Operaciones facturadas. */
/*-------------------------------------------------*/
             IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                            +
                          PROGRAMA SEATBFTOI1 EN +
                          EJECUCION                  ' ' ' FS01)

             CALL       PGM(EXPLOTA/SEATBFTOI1)

             CHGVAR     VAR(&TEX) VALUE('FS01, SEAT_BFTOI DESPUES DE +
                          PGM-SEATBFTOI1')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SEAT_BFTOI +
                          FICHEROS SEAT_BFTOI LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             ENDDO
/*-------------------------------------------------*/

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 29 */
/*-------------------------------------------------------------------*/
/*    CUOTAS Y COSTES POR SERVICIOS    (ACUMULACION DE PARCIALES)    */
/*                                     (FICHERO CARGOS/ABONOS)       */
/*-------------------------------------------------------------------*/
 RE29:       CALL       PGM(EXPLOTA/FSCUOTE2CL) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/CUOTE09CL)
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 30 */
/*-------------------------------------------------------------------*/
/*--         RPG. FSLISS     --INFORME DE SALTADAS--                 */
/*-------------------------------------------------------------------*/
 RE30:
             RTVMBRD    FILE(FICHEROS/SFSBALA1) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 0) THEN(DO)

                  CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  FSLISS  EN EJECUCION' ' ' FS01)

             CL1        LABEL(INCFSLIS) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCFSLIS)

             CALL       PGM(EXPLOTA/FSLISS)

             DLTOVR     IMP0017

             CHGVAR     VAR(&DESCRIP) VALUE('PGM* FSLISS  Hay  +
                          Saltadas -Facturacion Socios-')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE('PGM* FSLISS  Hay +
                          Saltadas -Facturacion Socios- **LLAMAR A +
                          Diners Club Spain')

       /* CORREO DE SALTADAS A DESARROLLO2 */
       /*----------------------------------*/
             CHGVAR     VAR(&MSG) VALUE('HAY SALTADAS EN EL PROCESO +
                          VERIFICAR LISTADO Y TOTALES - FS01M')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((grupodesarrollo2@dinersclub.es)) +
                          DSTD('FS01M: SALTADAS EN EL +
                          PROCESO.VERIFICAR..') LONGMSG(&MSG)

             CPYF       FROMFILE(FICHEROS/SFSBALA1) +
                          TOFILE(FICHEROS/SFSBALAH) MBROPT(*ADD) +
                          CRTFILE(*YES)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES PGM-FSBALA +
                          FS01M')
             CALL       PGM(CONCOPCL) PARM(SFSBALA1 FICHEROS +
                          SFSBALA1 LIBSEG30D C ' ' ' ' &TEX FS01)
       /*----------------------------------*/
             CHGVAR     VAR(&CODRET) VALUE('0')

   /*        CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)   */

             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 31 */
/*-------------------------------------------------------------------*/
/*--          COPIAS DE SEGURIDAD, DESPUES DE RPG.FSBALA           --*/
/*-------------------------------------------------------------------*/
RE31:        RTVMBRD    FILE(FICHEROS/FNETFS) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CPYF       FROMFILE(FICHEROS/FNETFS) +
                          TOFILE(FICHEROS/FNET) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSBALA, FNET PARCIAL')
             CALL       PGM(CONCOPCL) PARM(FNETFS    FICHEROS +
                          FNETFS    LIBSEG30D M ' ' ' ' &TEX FS01)
             ENDDO

             CRTPF      FILE(FICHEROS/BSSALTA) RCDLEN(130) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/BSSALTA))

             CPYF       FROMFILE(FICHEROS/SFSBALA1) +
                          TOFILE(FICHEROS/BSSALTA) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-FSBALA')
             CALL       PGM(CONCOPCL) PARM(SFSBALA1 FICHEROS +
                          SFSBALA1 LIBSEG30D M ' ' ' ' &TEX FS01)
             CALL       PGM(CONCOPCL) PARM(DINBCH FICHEROS +
                          DINBCH LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 32 */
/*-------------------------------------------------------------------*/
/*--                   RPG. B C H 1 2                              --*/
/*-------------------------------------------------------------------*/
 RE32:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  BCH12   EN EJECUCION' ' ' FS01)

             GOTO       CMDLBL(NOBCH12)

             CRTLF      FILE(FICHEROS/BCHCUOL1) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000
             CRTPF      FILE(FICHEROS/ASIBCH12) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIBCH12))
             OVRDBF     ASIFILE FICHEROS/ASIBCH12
     /* APG2 ASTERISCADO POR AMPARO - DESCATALOGADO PARA QUE NO MOLESTE MC */
     /*      CALL       PGM(EXPLOTA/BCH12) PARM(&CODRET)       */
/*----*/
             IF         (&CODRET *EQ '*') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('Cuadrar en el +
                          totales el listado del BCH12. INTRO' ' ' +
                          FS01)

    /*       CALL       PGM(EXPLOTA/TOTAL) PARM(BCHCUO)    */
/*----*/
             CALL       PGM(EXPLOTA/ACASBO) PARM('014')
             CALL       PGM(EXPLOTA/TRACE) PARM('Ver que se han +
                          acumulado al ASI000 los asientos de +
                          FAC.CUOTAS SOCIOS BCH' ' ' FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-BCH12 ')
             CALL       PGM(CONCOPCL) PARM(BCHCUOT   FICHEROS +
                          BCHCUOT   LIBSEG30D C ' ' ' ' &TEX FS01)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-BCH12 ')
             CALL       PGM(CONCOPCL) PARM(ASIBCH12  FICHEROS +
                          ASIBCH12  LIBSEG30D M ' ' ' ' &TEX FS01)
             ENDDO

NOBCH12:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 33 */
/*-------------------------------------------------------------------*/
/*--                     RPG. T E R C E 1                          --*/
/*-------------------------------------------------------------------*/
 RE33:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  TERCE1 EN EJECUCION  ' ' ' FS01)
             CRTPF      FILE(FICHEROS/TERCE) RCDLEN(84) +
                          TEXT('proceso cuotas a terceros') +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/TERCE))
             CALL       PGM(EXPLOTA/TERCE1)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 34 */
/*-------------------------------------------------------------------*/
/*                      CLASIFICACION -TERCE-                        */
/*-------------------------------------------------------------------*/
 RE34:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             SHORT +
                          PARA LITERCE EN EJECUCION' ' ' FS01)
             FMTDTA     INFILE((FICHEROS/TERCE)) +
                          OUTFILE(FICHEROS/TERCE) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(STERCE) +
                          OPTION(*NOPRT)
             MONMSG     MSGID(CPF1124) EXEC(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('+2' ' ' FS01) /* 36 */
             GOTO       NOTERCE
             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 35 */
/*-------------------------------------------------------------------*/
/*--                      RPG. L I T E R C E                       --*/
/*-------------------------------------------------------------------*/
 RE35:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  LITERCE EN EJECUCION  Retener +
                          el spool ' ' ' FS01)
             OVRPRTF    FILE(IMP00PX) TOFILE(IMP00P11) COPIES(1)
             CALL       PGM(EXPLOTA/LITERCE)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 36 */
/*-------------------------------------------------------------------*/
/*--              COPIAS DE SEGURIDAD                              --*/
/*-------------------------------------------------------------------*/
 RE36:
 NOTERCE:    CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-LITERCE')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CUOTERCE FICHEROS +
                          CUOTERCE LIBSEG30D M ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(TERCE FICHEROS +
                          TERCE LIBSEG30D M ' ' ' ' &TEX FS01)
             CHGVAR     VAR(&TEX) VALUE('FS01, ANTES DEL PGM-FSBALA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCUOTA FICHEROS +
                          PENCUOTA LIBSEG30D M ' ' ' ' &TEX FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-FSFAPA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA FICHEROS +
                          FAPA LIBSEG30D P ' ' ' ' &TEX FS01)
             RNMOBJ     OBJ(FICHEROS/PENCUSAL) OBJTYPE(*FILE) +
                          NEWOBJ(PENCUOTA)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSBALA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECIBOS FICHEROS +
                          RECIBOS LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 37 */
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*++         EN PROCESO DE EMPRESAS SE EJECUTA EL FS03             ++*/
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
 RE37:       IF         COND(&DD = 05) THEN(GOTO CMDLBL(CINCOX))
             IF         COND(&DD = 15) THEN(GOTO CMDLBL(CINCOX))
             IF         COND(&DD = 25) THEN(GOTO CMDLBL(CINCOX))


          /* CALL       PGM(PARONMC12) */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR                                           */
     /*     -ABRIR DEBUG FS03M                                 */
     /* ****************************************************** */

             CALL       PGM(EXPLOTA/FS03M) PARM(&FECHA)

/*---------------------------------------------------------------------*/
/*      COPIA DE FICHEROS BSDI y CONTROFSDI ANTES   DE FUSIONAR FS03M  */
/*---------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, BSDI DESPUES FS03M')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM((BSDI) (FICHEROS) +
                          (BSDI) (LIBSEG1D) (C) (' ') (' ') (&TEX) +
                          (FS01))

             CHGVAR     VAR(&TEX) VALUE('FS01M,CONTROFSDI DESP. FS03M')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM((CONTROFSDI) +
                          (FICHEROS) (CONTROFSDI) (LIBSEG1D) (C) (' +
                          ') (' ') (&TEX) (FS01))

      /* Verificamos si ha generados Movimientos el FS03M     */
             RTVMBRD    FILE(FICHEROS/BSDI) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 0 ) THEN(DO)

/* -------------------------------------------------- */
/* FuSionamos:                                        */
/*      BSDI  en el BS                                */
/*      CONTROFSDI  en el CONTROFS                    */
/* -------------------------------------------------- */
            /* Copia de Parciales CONTROFS */
             CPYF   FROMFILE(FICHEROS/CONTROFSDI) +
                          TOFILE(FICHEROS/CONTROFS) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             CLRPFM  FICHEROS/CONTROFSDI

             /* Copia de Parciales BS */
             CPYF   FROMFILE(FICHEROS/BSDI) +
                          TOFILE(FICHEROS/BS) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             CLRPFM  FICHEROS/BSDI

          /* CALL       PGM(PARONMC14) */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR                                           */
     /*     -BS (VER SQL EN EXCEL POR PRODUCTO)                */
     /*     -CONTROFS (DIN(TE + PE) + MC)                      */
     /* ****************************************************** */
/*---------------------------------------------------------------------*/
/*      COPIA DE FICHEROS BS   y CONTROFS   DESPUES DE FUSIONAR FS03M  */
/*---------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, BS DESPUES FS03M')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS FICHEROS +
                          BS LIBSEG1D C ' ' ' ' &TEX FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01M,CONTROFS DESP. FS03M')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFS FICHEROS +
                          CONTROFS LIBSEG1D C ' ' ' ' &TEX FS01)
             EndDo
/* -------------------------------------------------- */

             CHGJOB     DATE(&FECHA)
 CINCOX:
 /*--EVIDENCIAS EXTRA-CONTABLE---*/
             CPYF       FROMFILE(FICHEROS/RECIBOS) +
                          TOFILE(FICHEROS/RECIBOSM) +
                          MBROPT(*REPLACE) CRTFILE(*YES) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/BS) +
                          TOFILE(FICHEROS/BSFS02M) MBROPT(*REPLACE) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)
/*-------------------------------------------------------------------*/
/*       GENERACION DE TRANSFERENCIAS A SALDOS ACREEDORES            */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/FSACRECL)
/*========================================*/
/*== DATA WAREHOUSE: CUOTAS (CODIGOS:9) ==*/
/*========================================*/
             CRTPF      FILE(FICHEROS/DATAWCUO) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DATAWHOUSE) TEXT('DATAWAREHOUSE, +
                          CUOTAS -CODIGOS:9-') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DATAWCUO))
             CALL       PGM(EXPLOTA/DATAWC)
/*========================================*/
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 38 */
/*-------------------------------------------------------------------*/
/*--      RPG. F S T A B 1    --TABULADO PARA CONTABILIDAD--       --*/
/*-------------------------------------------------------------------*/
 RE38:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  FSTAB1 EN EJECUCION  ' ' ' FS01)

             CRTPF      FILE(FICHEROS/DETE36) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE36))
             CRTPF      FILE(FICHEROS/CABE36) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE36))

             CALL       PGM(EXPLOTA/FSTAB1)

             CHGJOB     DATE(&FECHA)
/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETE36) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE36) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01    , DESPUES DEL +
                          PGM-FSTAB1')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE36 FICHEROS +
                          DETE36 LIBSEG1D M ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE36 FICHEROS +
                          CABE36 LIBSEG1D M ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 39 */
/*-------------------------------------------------------------------*/
/*--      SALVO: BS, CONTROFS, PENCUOTA, FSANUAL                   --*/
/*-------------------------------------------------------------------*/
 RE39:       CHGVAR     VAR(&LAFA) VALUE(&FECHA)
             CHGVAR     VAR(&LABAL) VALUE('BS' *CAT &LAFA)
             RNMOBJ     OBJ(FICHEROS/BS) OBJTYPE(*FILE) NEWOBJ(&LABAL)
             CHGVAR     VAR(&REST1) VALUE(&LABAL)
             RNMOBJ     OBJ(FICHEROS/&LABAL) OBJTYPE(*FILE) NEWOBJ(BS)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSBALA   ')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS FICHEROS +
                          &REST1 LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFS FICHEROS +
                          CONTROFS LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FSANUAL FICHEROS +
                          FSANUAL LIBSEG30D C ' ' ' ' &TEX FS01)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCUOTA FICHEROS +
                          PENCUOTA LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01, FSANUAL PARA-FSEXAN')
             CHGVAR     VAR(&LABEL) VALUE('          ')
             CHGVAR     VAR(&LABEL) VALUE('FAN' *CAT &FECHA)
    /*       CALL       PGM(EXPLOTA/CONCOKCL) PARM(FSANUAL FICHEROS +  */
    /*                    &LABEL INFOBACKUP P &TEX FS01)               */

/*---*/
             DLTF       FILE(FICHEROS/FAPA)
             DLTF       FILE(FICHEROS/NOABONOS)
/*-----------------------*/
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 40 */
/*-------------------------------------------------------------------*/
/*-- CONTROL PARA INFORMES ESTADISTICOS --*/
/*-------------------------------------------------------------------*/
 RE40:       IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(PRFICCTL) PARM('A' 'CTLINF1   ')
             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 41 */
/*-------------------------------------------------------------------*/
/*     EXTRACTOS EN PDF, CREAR FICHERO "FESOCI_PDF"                */
/* * PARA DESCATALOGAR: NO SE USA EN ATRIUM                          */
/*-------------------------------------------------------------------*/
 RE41:       CALL       PGM(EXPLOTA/TRACE) PARM('       (Extractos +
                          en PDF)    PROGRAMA FESOCI1 EN EJECUCION  +
                          ' ' ' FS01)

             D1         LABEL(FESOCI_PL1) LIB(FICHEROS)
             D1         LABEL(FESOCI_PDF) LIB(FICHEROS)

             CRTPF      FILE(FICHEROS/FESOCI_PDF) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('Extractos +
                          en PDF a nivel de socios -desglosado-') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)

             CALL       PGM(EXPLOTA/FESOCI1)

             RTVMBRD    FILE(FICHEROS/FESOCI_PDF) NBRCURRCD(&NUMREG)

             CHGJOB     DATE(&FECHA)
/************************************************************+++******/
/* Solo se realizan los procesos si FESOCI_PDF tiene registros     */

/*     20120830 AHMED NO SE PASA A MICRO                           */
/*************************************************************+++*****/
             IF         COND(&NUMREG > 0) THEN(DO)

             CHGVAR     VAR(&ESTADO) VALUE(' ')
/*           CALL       PGM(EXPLOTA/CTREXPORT1) PARM('PCFICHEROS' +
                          'FESOCI_PDF' &ESTADO)                   */

/*SE VERIFICA QUE NO HAYA UN FESOCI_PDF PENDIENTE DE EXPORTAR   */
             IF         COND(&ESTADO *NE ' ') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('EXISTE UN +
                          FESOCI_PDF/PCFICHEROS PENDIENTE DE +
                          EXPORTAR SE RNMOBJ FESOCI_PD2')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01M     ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             D1         LABEL(FESOCI_PD2) LIB(PCFICHEROS)

             RNMOBJ     OBJ(PCFICHEROS/FESOCI_PDF) OBJTYPE(*FILE) +
                          NEWOBJ(FESOCI_PD2)
             ENDDO

             CHGJOB     DATE(&FECHA)
/*-------------------------------------------------------------------*/
/*     20120830 AHMED NO SE PASA A MICRO                           */
/*-------------------------------------------------------------------*/
/*  "FESOCI_PDF" PARA "MICROINFORMATICA"                        */
             D1         LABEL(FESOCI_PDF) LIB(PCFICHEROS)

/*           CRTDUPOBJ  OBJ(FESOCI_PDF) FROMLIB(FICHEROS) +
                          OBJTYPE(*FILE) TOLIB(PCFICHEROS) +
                          NEWOBJ(FESOCI_PDF) DATA(*YES)                */

/*           OVRDBF     FILE(FESOCI_PDF) TOFILE(PCFICHEROS/FESOCI_PDF) */
/*           CALL       PGM(EXPLOTA/MICSOEMAIL) PARM('FESOCI_PDF' +    */
/*                        &MSG &MM)                                    */
/*           DLTOVR     FILE(FESOCI_PDF)                               */


/*Control de ficheros a exporta a SQL Server (EXPOR_SQL)             */
/*           CHGVAR     VAR(&CLAVES) +                                 */
/*                        VALUE('FESOCI_PDF                    ')      */
/*           CALL       PGM(EXPLOTA/CTREXPORTA) PARM('PCFICHEROS' +    */
/*                        'FESOCI_PDF' &CLAVES &AGRUP1 &AGRUP2)        */

/*Copias de Seguridad                                           */
             CHGVAR     VAR(&TEX) VALUE('FS01, FESOCI_PDF CREADO +
                          PGM-FESOCI1')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FESOCI_PDF +
                          FICHEROS FESOCI_PDF LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             ENDDO
/******************************************************************/

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 42 */
/*-------------------------------------------------------------------*/
/*   LIBRE  LIBRE                                                  --*/
/*-------------------------------------------------------------------*/
 RE42:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 43 */
/*-------------------------------------------------------------------*/
/*   RPG. C R E A B S  --DA ORDEN A LOS REGISTROS PARA EXTRACTO--    */
/*-------------------------------------------------------------------*/
 RE43:       CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  CREABS EN EJECUCION  ' ' ' FS01)

             CRTPF      FILE(FICHEROS/BSEXTRA) RCDLEN(751) TEXT('BS +
                          MAS EL CAMPO ADICIONAL DE ORDEN') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BSEXTRA))

  /* PARA DESCATALOGAR (EL VALIDO PARA EXTRACTOS ATRIUM ES EL BSAT)*/
  /*      ESTE BSEXTRA ORDENADO SE UTILIZA PARA EXTRASOC           */
             CALL       PGM(EXPLOTA/CREABS)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 44 */
/*-------------------------------------------------------------------*/
/*--                   CLASIFICACION -BSEXTRA-                     --*/
/*-------------------------------------------------------------------*/
 RE44:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          COMIENZA SORT DEL +
                          BSEXTRA                        ' ' ' FS01)

             CLRPFM     FILE(FICHEROS/BS)

             FMTDTA     INFILE((FICHEROS/BSEXTRA)) +
                          OUTFILE(FICHEROS/BS) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(SCREABS) +
                          OPTION(*NOPRT)

             DLTF       FILE(FICHEROS/BSEXTRA)

             CHGVAR     VAR(&TEX) VALUE('FS01M, DESPUES DEL +
                          PGM-CREABS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS FICHEROS BS +
                          LIBSEG30D P ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 45 */
/*-------------------------------------------------------------------*/
/*-- LIBRE  LIBRE                                                    */
/*-------------------------------------------------------------------*/
 RE45:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 46 */
/*-------------------------------------------------------------------*/
/*-- LIBRE  LIBRE                                                  --*/
/*-------------------------------------------------------------------*/
 RE46:
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 47 */
/*-------------------------------------------------------------------*/
/*  =============================================================   */
/*  =         RPG. F S B S   --SEGREGAR: BS/CONTROFS--          =   */
/*  =         ****************************************          =   */
/*  =     (*) BSEMPREL / CONTREML  (TARJETAS TE'S)              =   */
/*  =     (*) BSPERSO  / CONTRPER  (TARJETAS PI'S Y PE'S)       =   */
/*  =============================================================   */
/*  PARA DESCATALOGAR CUANDO SE QUITE EXTRASOC                      */
/*   (EXTRASOC ES MENSUAL, EXTRASOC01, EXTRASOC02,...)              */
/*-------------------------------------------------------------------*/
 RE47:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  -FSBS-  EN +
                          EJECUCION.                  ' ' ' FS01)

             CRTPF      FILE(FICHEROS/BSPERSO) RCDLEN(154) TEXT('BS +
                          TARJETAS -PI/PE-') SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BSPERSO))

             CRTPF      FILE(FICHEROS/BSEMPREL) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BSOLD) +
                          TEXT('BS TARJETAS -TE-') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BSEMPREL))

             CRTPF      FILE(FICHEROS/CONTRPER) RCDLEN(59) +
                          TEXT('CONTROFS DE TARJETAS -PI/PE-') +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTRPER))

             CRTPF      FILE(FICHEROS/CONTREML) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(CONTROFS) TEXT('CONTROFS DE +
                          TARJETAS -TE-') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTREML))

             CALL       PGM(EXPLOTA/FSBS)

             CHGJOB     DATE(&FECHA)
/*-----------------------------------*/
/*- COPIAS BSEMPREL/CONTREML (TE'S) -*/
/*-----------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DE RPG.FSBS Y +
                          DE ENTRADA CL.FS01TE')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSEMPREL FICHEROS +
                          BSEMPREL LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTREML FICHEROS +
                          CONTREML LIBSEG30D C ' ' ' ' &TEX FS01)
/*----------------------------------------*/
/*- COPIAS BSPERSO/CONTRPER  (PI'S/PE'S) -*/
/*----------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DE RPG.FSBS +
                          (CL.FS01PIPE/FS01ANUA)')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSPERSO FICHEROS +
                          BSPERSO LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTRPER FICHEROS +
                          CONTRPER LIBSEG30D C ' ' ' ' &TEX FS01)

/*----------------------------------------*/
/*- Elimina del BSEMPREL y CONTREML las MC*/
/*----------------------------------------*/

             CALL PGM(EXPLOTA/MC0106)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 48 */
/*********************************************************************/
/*=================================================================*/
/*1) FICHEROS MSOCIO87 Y MSOCIO88 PARA ATRIUM  (label+AT)         */
/*                                                                */
/*2) RENAME DE -BS- A -BSGENE- Y RENAME DE -CONTROFS- A -CONTROGE */
/*    (SOLO PARA EXTRASOC)                                        */
/*=================================================================*/
/* *******************************************************************/
/*   MSOCIO87: TARJETAS "PE" (10, 20 Y 30)                           */
/*   MSOCIO88: TARJETAS "TE" (10, 20 Y 30)                           */
/*             TARJETAS "PI" ( 5, 15 Y 25)                           */
/*   MSOCIO88: CONTIENE TODAS (DINERS + MC)                          */
/*   * SE CARGAN LOS FICHEROS MSOCIO88AT Y MSOCIO87AT                */
/*       CON *ADD, SE ACUMULAN DIARIAMENTE PARA ATRIUM               */
/*       -SI NO SE HACE MIGRACION 1 DIA SE QUEDA ACUMULADO           */
/*            HASTA QUE SE HAGA                                      */
/*   * SE ACUMULAN TAMBIEN LAS TARJETAS DE CONCILIACION              */
/*        Y LAS DEL EXTRACTO ADICIONAL (LLEVA FECHA FACTURACION      */
/*         P.E. 31/01/2024 Y FECHA EXTRACTO LA DEL DIA QUE SE PIDE)  */
/* *******************************************************************/
/*********************************************************************/
 RE48:       CALL       PGM(EXPLOTA/TRACE) PARM('    FICHEROS PARA +
                          LIBRERIA ATRIUM: MSOCIO87 Y +
                          MSOCIO88.                       ' ' ' FS01)

             CPYF       FROMFILE(FICHEROS/MSOCIO87) +
                          TOFILE(FICHEROS/MSOCIO87AT) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/MSOCIO88) +
                          TOFILE(FICHEROS/MSOCIO88AT) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

              /*-------------------------------------------*/
              /*--------- MC ------------------------------*/
              /*CPYF       FROMFILE(FICHEROS/MSOCIO88MC) +
                          TOFILE(FICHEROS/MSOCIO88AT) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)*/
              /*-------------------------------------------*/

             CPYF       FROMFILE(FICHEROS/CONTROFS) +
                          TOFILE(FICHEROS/CONTROFSAT) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CONTROFS) +
                          TOFILE(ATRIUMDEMO/CONTROFSFA) +
                          MBROPT(*ADD) CRTFILE(*YES) FROMRCD(1) +
                          FMTOPT(*NOCHK)
              /*-------------------------------------------*/

             CHGVAR     VAR(&TEX) VALUE('FS01, MSOCIO87AT PDTE. +
                          -MIGRACION DIARIA- A ATRIUM')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO87AT +
                          FICHEROS MSOCIO87AT LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01, MSOCIO88AT PDTE. +
                          -MIGRACION DIARIA- A ATRIUM')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88AT +
                          FICHEROS MSOCIO88AT LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01, CONTROFSAT PDTE. +
                          -MIGRAR- A ATRIUM          ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFSAT +
                          FICHEROS CONTROFSAT LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01, CONTROFSFA PDTE. +
                          -MIGRAR- A ATRIUMDEMO    ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFSFA +
                          ATRIUMDEMO CONTROFSFA LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

      /*-------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('    Guardar BS en +
                          BSGENE y CONTROFS en CONTROGE  (Seguridad +
                          Auxiliar)         ' ' ' FS01)

             RNMOBJ     OBJ(FICHEROS/BS) OBJTYPE(*FILE) NEWOBJ(BSGENE)

             RNMOBJ     OBJ(FICHEROS/CONTROFS) OBJTYPE(*FILE) +
                          NEWOBJ(CONTROGE)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 49 */
/*-------------------------------------------------------------------*/
/*********************************************************************/
/*=================================================================*/
/*       --FS01TEM--    (EXTRACTOS TE'S IMP.LASER) JULIO-2002      */
/*=================================================================*/
/*********************************************************************/
/*-------------------------------------------------------------------*/
 RE49:       IF         COND(&DD = 05) THEN(GOTO CMDLBL(NOTES))
             IF         COND(&DD = 15) THEN(GOTO CMDLBL(NOTES))
             IF         COND(&DD = 25) THEN(GOTO CMDLBL(NOTES))

             CALL       PGM(EXPLOTA/FS01TEM) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CHGJOB     DATE(&FECHA)
 NOTES:      CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 50 */
/*-------------------------------------------------------------------*/
/*********************************************************************/
/*=================================================================*/
/*     --FS01PIPEM--  (EXTRACTOS PI/PE IMP.LASER) NOVIEMBRE-2002   */
/*=================================================================*/
/*********************************************************************/
/*-------------------------------------------------------------------*/
 RE50:       CALL       PGM(EXPLOTA/FS01PIPEM) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 51 */
/*-------------------------------------------------------------------*/
/*********************************************************************/
/*=================================================================*/
/*      --FS01ANUAM- (EXT. PI/PE -ANUALES- IMP.LASER) 20-2-2003    */
/*=================================================================\Z\Z*/
/*********************************************************************/
/*-------------------------------------------------------------------*/
 RE51:       CALL       PGM(EXPLOTA/FS01ANUAM) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 52 */
/*-------------------------------------------------------------------*/
/*********************************************************************/
/*=================================================================*/
/*                     --- PROCESOS COMUNES ---                    */
/*       RETORNO DESPUES DE CLS: FS01TE - FS01PIPE - FS01ANUA      */
/*  RENAME DE -BSGENE- A -BS- Y RENAME DE -CONTROGE- A -CONTROFS-  */
/*=================================================================*/
/*********************************************************************/
/*-------------------------------------------------------------------*/
 RE52:       D1         LABEL(BSEMPREL) LIB(FICHEROS)
             D1         LABEL(CONTREML) LIB(FICHEROS)
             D1         LABEL(BSPERSO)  LIB(FICHEROS)
             D1         LABEL(CONTRPER) LIB(FICHEROS)
             D1         LABEL(BS)       LIB(FICHEROS)
             D1         LABEL(CONTROFS) LIB(FICHEROS)
             DLTOVR     FILE(*ALL)
/*---*/
             RNMOBJ     OBJ(FICHEROS/BSGENE) OBJTYPE(*FILE) NEWOBJ(BS)
             RNMOBJ     OBJ(FICHEROS/CONTROGE) OBJTYPE(*FILE) +
                          NEWOBJ(CONTROFS)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 53 */
/*-------------------------------------------------------------------*/
/*--             CONTROL ERRORES EN DESCRIPCIONES                  --*/
/*-------------------------------------------------------------------*/
RE53:        RTVMBRD    FILE(FICHEROS/ERRDESCR) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(CPYF +
                          FROMFILE(FICHEROS/ERRDESCR) +
                          TOFILE(*PRINT) OUTFMT(*HEX))

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 54 */
/*-------------------------------------------------------------------*/
/*-- RPG. FSCRECON  CREA: CONTROEU (UN REGTRO.POR CADA TITULAR -EU-) */
/*-------------------------------------------------------------------*/
 RE54:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                           +
                          PROGRAMA  FSCRECON  EN EJECUCION.' ' ' FS01)
             D1         LABEL(CONTRL1) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/CONTRL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONTROFS- +
                          PARA RPG.FSCRECON') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO) AUT(*ALL)
             D1         LABEL(RECIBL2) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL2) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RECIBOS- +
                          PARA RPG.FSCRECON') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO) AUT(*ALL)
             CRTPF      FILE(FICHEROS/CONTROEU) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('control +
                          titulares extracto unificado') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTROEU))
/*---*/
             CALL       PGM(EXPLOTA/FSCRECON)
/*---*/
             DLTF       FILE(FICHEROS/RECIBL2)
             DLTF       FILE(FICHEROS/CONTRL1)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSCRECON')
             CALL       PGM(CONCOPCL) PARM(CONTROEU FICHEROS +
                          CONTROEU LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 55 */
/*-------------------------------------------------------------------*/
/*-- RPG. CEREFS    "ACUMULACION A LA BOLSA DE RECIBOS"            --*/
/*-- CLP. EVIADDCL  -GENERACION AUTOMATICA EVIDENCIAS CONTABLES    --*/
/*-------------------------------------------------------------------*/
 RE55:
             CL1        LABEL(CTLREC) LIB(FICHEROS)
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA CEREFS EN +
                          EJECUCION' ' ' FS01)

VERECI:      CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'CTLFS01   ')

             IF         COND(&ACCION = 'S') THEN(DO)
 /*----------------------------------------------------------*/
 /*  HAY UNA EXTRACCION  DE RECIBOS SE ESPERA   5 MINUTOS    */
 /*----------------------------------------------------------*/

             DLYJOB     DLY(300)

             GOTO       CMDLBL(VERECI)
             ENDDO
/*---*/
             CHGVAR     VAR(&TEX) VALUE('FS01, ANTES DE PGM-CEREFS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BORECI FICHEROS +
                          BORECI LIBSEG30D P ' ' ' ' &TEX FS01)

             D1         LABEL(RECIBL1) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RECIBOS- +
                          PARA RPG.CEREFS') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)

             D1         LABEL(RECIBL2) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL2) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RECIBOS- +
                          PARA RPG.CEREFS') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)

             CRTPF      FILE(FICHEROS/ASIRECFS) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFIVA) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIRECFS))

             /*CRTPF      FILE(FICHEROS/EVICEREFS) RCDLEN(132) +
                          TEXT('PREVIO CABECERA EVIDENCIA +
                          CONTABLE') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/EVICEREFS))*/

             /* Cambios al CEREFS                                  */
             CRTPF      FILE(FICHEROS/DETECERE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          TEXT('Evidencias Contables CEREFS - Recibos') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETECERE))

             CRTPF      FILE(FICHEROS/CABECERE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          TEXT('Cab. Evid. Contables CEREFS - Recibos') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABECERE))

       /*-------- DINERS ---------------*/

/*------------------------------------------------------------------*/
/* Respaldo del Fichero RECIBOS antes del CEREFS      LMG 20-08-2025*/
/*------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, ANTES DEL +
                          CEREFS y CEREFSMC')
             CALL       PGM(CONCOPCL) PARM(RECIBOS FICHEROS +
                        RECIBOS LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(CONCOPCL) PARM(RECIBOSMC FICHEROS +
                        RECIBOSMC LIBSEG30D C ' ' ' ' &TEX FS01)
/*------------------------------------------------------------------*/
         /*  CALL       PGM(PARONMC15)   */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR ENTRADA:                                  */
     /*     -RECIBOS (SOLO DINERS)                             */
     /* ****************************************************** */

             CALL       PGM(EXPLOTA/CEREFS)

         /*  CALL       PGM(PARONMC16) */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR SALIDA:                                   */
     /*     -BORECI  (SOLO DINERS)                             */
     /*              -TOTALIZADOR "BORECI"                     */
     /*     -ASIRECFS(ASIENTOS SOLO DINERS)                    */
     /* ****************************************************** */

             CHGJOB     DATE(&FECHA)

/*---------------------------------------------------------------*/
/*     MasterCard                                                */
/*---------------------------------------------------------------*/
             D1         LABEL(RECIBMCL1) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBMCL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RECIBOS- +
                          PARA RPG.CEREFS') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)

             D1         LABEL(RECIBMCL2) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBMCL2) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RECIBOS- +
                          PARA RPG.CEREFS') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)

             CRTPF      FILE(FICHEROS/ASIRECFSMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILEN) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIRECFSMC))

             CRTPF      FILE(FICHEROS/DETEREMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          TEXT('Evidencias Contables MC Recibos') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEREMC))

             CRTPF      FILE(FICHEROS/CABEREMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          TEXT('Cab. Evid. Contables MC Recibos') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABEREMC))

             CRTPF      FILE(FICHEROS/BORECIMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BORECI) +
                          TEXT('BORECI para MC Recibos') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BORECIMC))
/*---*/

        /*   CALL       PGM(PARONMC15)   */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR ENTRADA:                                  */
     /*     -RECIBOSMC (SOLO MC)                               */
     /* ****************************************************** */
             OVRDBF     FILE(ASIFILEN) TOFILE(FICHEROS/ASIRECFSMC)
             CALL       PGM(EXPLOTA/CEREFSMC)
             DLTOVR     FILE(ASIFILEN)

         /*  CALL       PGM(PARONMC16)  */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR SALIDA:                                   */
     /*     -BORECIMC(SOLO MC    )                             */
     /*              -TOTALIZADOR "BORECI"                     */
     /*     -ASIRECFSMC (ASIENTOS SOLO MC)                     */
     /*     -EVIDENCIAS: CABEREMC + DETEREMC                   */
     /* ****************************************************** */

             /*-----------------------------------------------*/
             /*   Copio BORECIMC a BORECI (*ADD)  MC          */
             /*-----------------------------------------------*/
             CPYF       FROMFILE(FICHEROS/BORECIMC) +
                          TOFILE(FICHEROS/BORECI) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             /*-----------------------------------------------*/

             /*------------------------------------------*/
             /*    Copias luego del CEREFS               */
             /*------------------------------------------*/
             CPYF FROMFILE(FICHEROS/RECIBOSMC) +
                   TOFILE(FICHEROS/RECIBOS)    +
                   MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             /*------------------------------------------*/

          /* DLTOVR     IMP00P10    */
/*---*/
             CALLSUBR   SUBR(CUADRERECI)
/*---*/
             D1         LABEL(RECIBL1) LIB(FICHEROS)
             D1         LABEL(RECIBL2) LIB(FICHEROS)
    /*       DLTOVR     FILE(ASIFIVA ASIFILEN)    */

/*------------------------------------------------*/
/* PGM-EVIADDCL                                   */
/*                                                */
/* LA PARTE MASTERCARD NO SE HACE POR EVIADDCL    */
/* Y SU ASIENTO NO ES POR ASIFIVA                 */
/*------------------------------------------------*/
             /*CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVICEREFS ' +
                          'ASIRECFS  ' 'ACUMULACION DE RECIBOS A LA +
                          BOLSA -BORECI-        ' 'FS01      ' +
                          '      ' ' ')*/
             CHGJOB     DATE(&FECHA)
/*-------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 56 */
/*-------------------------------------------------------------------*/
/*--         ACUMULACION FICHEROS ASIENTOS DE "RECIBOS"            --*/
/*-------------------------------------------------------------------*/
 RE56:
/*------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA ACASBO EN EJECUCION.' ' ' FS01)

            /* PARTE DINERS */
             RTVMBRD FILE(FICHEROS/ASIRECFS) NBRCURRCD(&NUMREG)
             IF COND(&NUMREG > 0) THEN(DO)

               /* Actualiza Evidencia */
               CPYF       FROMFILE(FICHEROS/DETECERE) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

               CPYF       FROMFILE(FICHEROS/CABECERE) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             /* Actualiza Apunte Contable */
               OVRDBF FILE(ASIFILE) TOFILE(FICHEROS/ASIRECFS)
               CALL PGM(EXPLOTA/ACASBO) PARM('002')
               DLTOVR FILE(ASIFILE)

               CHGJOB     DATE(&FECHA)

             /* Respaldo de Parciales Apuntes Contables Evidencias*/
               CHGVAR     VAR(&TEX) VALUE('FS01M - DI - EVIDENCIAS +
                            CONT. CEREFS')
               CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETECERE FICHEROS +
                          DETECERE LIBSEG1D C ' ' ' ' &TEX FS01)
               CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABECERE FICHEROS +
                          CABECERE LIBSEG1D C ' ' ' ' &TEX FS01)

               CHGVAR     VAR(&TEX) VALUE('FS01COM - DI APUNTES +
                            CONT. DESPUES DEL CEREFS')
               CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFS FICHEROS +
                          ASIRECFS LIBSEG1D C ' ' ' ' &TEX FS01)

             ENDDO

             CLRPFM FILE(FICHEROS/ASIRECFS)
             MONMSG MSGID(CPF0000)


            /* PARTE MASTERCARD */
            /* TO-DO SE HACE AQUI - YA TIENEN APUNTE CONTABLE */
            RTVMBRD FILE(FICHEROS/ASIRECFSMC) NBRCURRCD(&NUMREG)
            IF COND(&NUMREG > 0) THEN(DO)

              CPYF       FROMFILE(FICHEROS/DETEREMC) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

              CPYF       FROMFILE(FICHEROS/CABEREMC) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

              CHGVAR     VAR(&TEX) VALUE('FS01M - MC - EVIDENCIAS +
                            CONT. RECIBOS')
              CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEREMC FICHEROS +
                          DETEREMC LIBSEG1D C ' ' ' ' &TEX FS01)
              CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEREMC FICHEROS +
                          CABEREMC LIBSEG1D C ' ' ' ' &TEX FS01)
              CHGVAR VAR(&TEXTO) VALUE('Copia parcial ASIRECFSMC a +
                  fichero general')
              CALL PGM(EXPLOTA/TRACE) PARM(&TEXTO &PARAM &CADENA)

              OVRDBF FILE(ASIFILE) TOFILE(FICHEROS/ASIRECFSMC)
              CALL PGM(EXPLOTA/ACASBON) PARM('002')
              DLTOVR FILE(ASIFILE)

              CHGVAR VAR(&TEX) VALUE('FS01M, DESPUES DE PGM-ACASBON')
              CALL PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFSMC FICHEROS +
                   ASIRECFSMC LIBSEG30D 'C' ' ' ' ' &TEX FS01)
            ENDDO

            CLRPFM FILE(FICHEROS/ASIRECFSMC)
            MONMSG MSGID(CPF0000)

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 57 */
/*-------------------------------------------------------------------*/
/*         L I B R E                                                 */
/*-------------------------------------------------------------------*/
 RE57:
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 58 */
/*-------------------------------------------------------------------*/
/*--           COPIAS DE SEGURIDAD DESPUES DEL RPG.CEREFS          --*/
/*-------------------------------------------------------------------*/
 RE58:       CALL       PGM(EXPLOTA/TRACE) PARM('             COPIAS +
                          SEGURIDAD DESPUES DE +
                          RPG.CEREFS/ACASBO/ACASBON  ' ' ' FS01)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-ASICO2')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFS FICHEROS +
                          ASIRECFS LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFS2 +
                          FICHEROS ASIRECFS2 LIBSEG30D M ' ' ' ' +
                          &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFSMC FICHEROS +
                          ASIRECFSMC LIBSEG30D C ' ' ' ' &TEX FS01)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-CEREFS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BORECI FICHEROS +
                          BORECI LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 59 */
/*-------------------------------------------------------------------*/
/*--  RPG.FSCREBO   -SUBSIDIARIAS DE EXTRACTO UNIFICADO A "BOREUN" --*/
/*--  CLP.EVIADDCL  -GENERACION AUTOMATICA EVIDENCIAS CONTABLES    --*/
/*-------------------------------------------------------------------*/
 RE59:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                            +
                          PROGRAMA -FSCREBO- EN EJECUCION.' ' ' FS01)

             CHGVAR     VAR(&TEX) VALUE('FS01, ANTES DEL PGM-FSCREBO ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOREUN FICHEROS +
                          BOREUN LIBSEG30D C ' ' ' ' &TEX FS01)

             D1         LABEL(CONTRL1) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/CONTRL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('CONTROFS- +
                          PARA RPG.FSCREBO') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)

             D1         LABEL(RECIBL3) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL3) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RECIBOS- +
                          PARA RPG.FSCREBO') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)

             CRTLF      FILE(FICHEROS/BOREUNL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('BOREUN- +
                          PARA RPG.FSCREBO') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/BOLINGSOEU) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(BOLINGSO) TEXT('TRANSFERENCIAS +
                          SOCIOS -EXT.UNIFICADO') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BOLINGSOEU))

             CRTPF      FILE(FICHEROS/FACOMPEEU) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FA) +
                          TEXT('fa compensaciones -EXT.UNIFICADO-') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FACOMPEEU))

             CRTPF      FILE(FICHEROS/ASIFSCREBO) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('asiento rpg.fscrebo') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFSCREBO))

             CRTPF      FILE(FICHEROS/EVIFSCREBO) RCDLEN(132) +
                          TEXT('evidencia contable ') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/EVIFSCREBO))
/*---*/
             CHKOBJ     OBJ(FICHEROS/RECMSOREC) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NORECUMS))


             CALL       PGM(EXPLOTA/TRACE) PARM('(OJO) EXISTE +
                          FICHERO -RECMSOREC-. SI ES UN REARRANQUE +
                          DEL RPG.FSCREBO, VA A   ' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('DEJAR EL -MSOCIO- +
                          COMO ESTABA ANTES DE REEJECUTAR EL +
                          RPG.FSCREBO ...          ' ' ' FS01)


             CHGVAR     VAR(&DESCRIP) VALUE('OJO, existe el fichero +
                          -RECMSOREC-. Esto puede ser de una +
                          reejecución  FS01')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE('OJO, existe fichero +
                          -RECMSOREC-. FS01M -INVESTIGAR  **VER +
                          CLP,VA A DEJAR EL -MSOCIO- COMO ESTABA +
                          ANTES DE REEJECUTAR EL RPG.FSCREBO +
                          **Llamar a Diners Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)


             GOTO       CMDLBL(SIRECUMS)
/*---*/
 NORECUMS:   CRTPF      FILE(FICHEROS/RECMSOREC) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('Rearranque rpg.fscrebo -RECUPERAR- +
                          msocio') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
/*---*/
 SIRECUMS:   OVRDBF     FILE(BOLINGSO) TOFILE(FICHEROS/BOLINGSOEU)
             OVRDBF     FILE(FA) TOFILE(FICHEROS/FACOMPEEU)
             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFSCREBO)
             OVRDBF     FILE(RECMSORE) TOFILE(FICHEROS/RECMSOREC)
             OVRDBF     FILE(IMP00P10) TOFILE(FICHEROS/EVIFSCREBO)
    /* APG2 ASTERISCADO POR AMPARO POR estar en Descatalog PARA NO MOLESTAR MC*/
    /*       CALL       PGM(EXPLOTA/FSCREBO) PARM(&CODRET)     */
             DLTOVR     FILE(BOLINGSO FA ASIFILE RECMSORE)
             DLTOVR     FILE(IMP00P10)
/*---*/
             IF         (&CODRET *EQ '1') THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('. Recoger impreso y +
                          cuadrar -FSCREBO- con el TOTALES  +
                          "SDOS.COMPENSADOS -EU-"' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('. y +
                          "TRANSFERENCIAS."                           -
                           ' ' ' FS01)
             CHGJOB     DATE(&FECHA)
/*-------------*/
/* PGM-EVIADDCL*/
/*-------------*/
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFSCREBO' +
                          'ASIFSCREBO' 'COMPENSACION DE SALDOS DE +
                          EXTRACO UNIFICADO       ' 'FS01      ' +
                          '      ' ' ')
             CHGJOB     DATE(&FECHA)
/*-------------*/
             ENDDO
/*---*/
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOREUN FICHEROS +
                          BOREUN LIBSEG30D C ' ' ' ' &TEX FS01)
             D1         LABEL(CONTRL1) LIB(FICHEROS)
             D1         LABEL(BORECL3) LIB(FICHEROS)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /*60*/
/*-------------------------------------------------------------------*/
/*--  ADICION -FACOMPEEU- "EXTRACTO UNIFICADO" A -FASALE-          --*/
/*-------------------------------------------------------------------*/
 RE60:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                         ADICION +
                          DEL -FACOMPEEU- A -FASALE-          ' ' ' +
                          FS01)

             CPYF       FROMFILE(FICHEROS/FACOMPEEU) +
                          TOFILE(FICHEROS/FASALE) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

/*----------------------------------------------------------------*/
/*   01/6/2023 ELIMINAR SORT (SFA) QUE CLASIFICABA EL -FASALE   */
/*----------------------------------------------------------------*/
             CRTLF      FILE(FICHEROS/SFASALE) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -FA- POR Nº.TARJETA Y CODIGO OPERACION') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             RGZPFM     FILE(FICHEROS/FASALE) +
                          KEYFILE(FICHEROS/SFASALE SFASALE)

             D1         LABEL(SFASALE) LIB(FICHEROS)
/*----------------------------------------------------------------*/

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FACOMPEEU +
                          FICHEROS FACOMPEEU LIBSEG30D M ' ' ' ' +
                          &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /*61*/
/*-------------------------------------------------------------------*/
/*--  ADICION -BOLINGSOEU-  "EXTRACTO UNIFICADO" A -BOLINGSO-      --*/
/*--  Y CALENDARIO POR VENCIMIENTOS PGM-FEINGS                     --*/
/*-------------------------------------------------------------------*/
 RE61:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                         ADICION +
                          DEL -BOLINGSOEU- A -BOLINGSO-        ' ' +
                          ' FS01)
             CPYF       FROMFILE(FICHEROS/BOLINGSOEU) +
                          TOFILE(FICHEROS/BOLINGSO) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOLINGSOEU +
                          FICHEROS BOLINGSOEU LIBSEG30D M ' ' ' ' +
                          &TEX FS01)
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DE ADICION +
                          -BOLINGSOEU-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOLINGSO FICHEROS +
                          BOLINGSO LIBSEG30D C ' ' ' ' &TEX FS01)
/*-------------*/
/* PGM-FEINGS  */
/*-------------*/
             RTVMBRD    FILE(FICHEROS/BOLINGSO) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       EXPLOTA/FEINGS
             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /*62*/
/*-------------------------------------------------------------------*/
/*--     RPG. F S C R E A     --CREACION DE NUEVOS SALDOS--        --*/
/*-------------------------------------------------------------------*/
 RE62:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  FSCREA  EN EJECUCION.' ' ' FS01)
/*----------------------------------------------------------------*/
/* ESTAS COPIAS SON PARA EL PROGRAMA 'POSICION' MIENTRAS DURA EL  */
/* PROCESO DEL FSCREA                                             */
/*----------------------------------------------------------------*/
             CRTDUPOBJ  OBJ(PA) FROMLIB(FICHEROS) OBJTYPE(*FILE) +
                          NEWOBJ(PAFSCREA) DATA(*YES)

             CRTDUPOBJ  OBJ(FA) FROMLIB(FICHEROS) OBJTYPE(*FILE) +
                          NEWOBJ(FAFSCREA) DATA(*YES)
/*----------------------------------------------------------------*/

             CRTPF      FILE(FICHEROS/PA) SRCFILE(FICHEROS/QDDSSRC) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL) /* P.A. SALIDO DE +
                          LA FACTURACION */
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/PA))

             CRTPF      FILE(FICHEROS/FA) SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('FA SALIDO DE LA FACTURACION  ') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/FA))

             CRTPF      FILE(FICHEROS/ASIFSCRE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFIVA) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFSCRE))

             CRTPF      FILE(FICHEROS/DETE34) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE34))

             CRTPF      FILE(FICHEROS/CABE34) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE34))

             D1         LABEL(RECIBL10) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL10) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('RECIBOS- +
                          PARA RPG.FSCREA') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)

             /*---------------------------------*/
             /* Reorganizamos los ficheros:     */
             /*      RECIBOS (DI + MC)          */
             /*      CONTROFS (DI + MC)         */
             /*      PASALE  (DI + MC)          */
             /*      FASALE  (DI + MC)          */
             /*---------------------------------*/
             RGZPFM FILE(FICHEROS/RECIBOS) KEYFILE(RECIBL10 RECIBL10)
             RGZPFM FILE(FICHEROS/CONTROFS) KEYFILE(*FILE)
             RGZPFM FILE(FICHEROS/FASALE) KEYFILE(*FILE)
             RGZPFM FILE(FICHEROS/PASALE) KEYFILE(*FILE)

             /*---------------------------------*/

          /* CALL       PGM(PARONMC18)  */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR ENTRADA:                                  */
     /*     -CONTROFS (DIN + MC)                               */
     /*     -RECIBOS  (DIN + MC)                               */
     /*     -PASALE   (DIN + MC)                               */
     /*     -FASALE   (DIN + MC)                               */
     /* ****************************************************** */

             CALL       PGM(EXPLOTA/FSCREA)
             DLTF       FILE(PAFSCREA)
             DLTF       FILE(FAFSCREA)

          /* CALL       PGM(PARONMC19)  */
     /* VERIFICACIONES MC ************************************ */
     /*   *VERIFICAR SALIDA :                                  */
     /*     -PASALE   (DIN + MC) DEBEN LLEVAR MOVIM. '0' Y '2' */
     /*     -FASALE   (DIN + MC) DEBEN LLEVAR MOVIM. '0' Y '2' */
     /* ****************************************************** */

             /*---------------------------------*/
             /*----- MC ------------------------*/
             /*---------------------------------*/
             /*CRTPF      FILE(FICHEROS/PAMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(PA) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL) */
             /*MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/PAMC))*/

             /*CRTPF      FILE(FICHEROS/FAMC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FA) +
                          TEXT('FA SALIDO DE LA FACTURACION  ') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)*/
             /*MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/FAMC))*/

            /* CALL       PGM(EXPLOTA/FSCREAMC)*/

             /*--------------------------------------------------*/
             /* Respaldo de Parciales FA y PA Diners y MC        */
             /*--------------------------------------------------*/
             /*CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-FSCREAMC')*/
             /*CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAMC FICHEROS PAMC +
                          LIBSEG30D P ' ' ' ' &TEX FS01)*/
             /*CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAMC FICHEROS FAMC +
                          LIBSEG30D P ' ' ' ' &TEX FS01)*/

             /*CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-FSCREA')*/
             /*CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG30D P ' ' ' ' &TEX FS01)*/
             /*CALL       PGM(EXPLOTA/CONCOPCL) PARM(FA FICHEROS FA +
                          LIBSEG30D P ' ' ' ' &TEX FS01)*/
             /*------------------------------------------*/
             /*    Copia de FAMC a FA y PAMC a PA        */
             /*------------------------------------------*/
             /*CPYF       FROMFILE(FICHEROS/FAMC) TOFILE(FICHEROS/FA) +
                          MBROPT(*ADD)*/
             /*CPYF       FROMFILE(FICHEROS/PAMC) TOFILE(FICHEROS/PA) +
                          MBROPT(*ADD)*/
             /*------------------------------------------*/

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 63 */
/*-------------------------------------------------------------------*/
/*--      CUADRAR -FSCREA-   TOTALES DE --FA Y PA-- CREADOS        --*/
/*-------------------------------------------------------------------*/
 RE63:       CALLSUBR   SUBR(CUADREFA)
             CALLSUBR   SUBR(CUADREPA)

  /*---*/
             CRTLF      FILE(FICHEROS/PALG5) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO)
             MONMSG     CPF0000

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 64 */
/*-------------------------------------------------------------------*/
/*--            COPIAS DE SEGURIDAD DESPUES DE RPG.FSCREA          --*/
/*-------------------------------------------------------------------*/
RE64:        CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-FSCREA')
             CALL       PGM(CONCOPCL) PARM(FNET      FICHEROS +
                          FNET      LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG30D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FA FICHEROS FA +
                          LIBSEG30D C ' ' ' ' &TEX FS01)


             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECMSOREC +
                          FICHEROS RECMSOREC LIBSEG30D M ' ' ' ' +
                          &TEX FS01)
/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */
             CPYF       FROMFILE(FICHEROS/DETE34) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE34) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01    , DESPUES DEL +
                          PGM-FSCREA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE34 FICHEROS +
                          DETE34 LIBSEG1D M ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE34 FICHEROS +
                          CABE34 LIBSEG1D M ' ' ' ' &TEX FS01)

/*----------------------------*/
/*- FIN CONTROL CONCILIACION -*/
/*----------------------------*/
             D1         LABEL(FIFS01) LIB(FICHEROS)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 65 */
/*-------------------------------------------------------------------*/
/*    COMPENSACION DE SALDOS - COMPENSOC                             */
/*-------------------------------------------------------------------*/
 RE65:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  COMPENSOC EN +
                          EJECUCION.                ' ' ' FS01)

 /*---------------------------------------------*/
 /*COPIAS ANTES DE EJECUTAR PGM-COMPENSOC     */
 /* COPIAS: CRFS01, CONTROFS, BORECI(BORECLG4), */
 /*         COMPENFAC, COMPENBOL, FA y XOPABP.  */
 /* OJO.- OJO TOTALIZADORES FICHERO: TOTASAX.   */
 /*---------------------------------------------*/

             CHGVAR     VAR(&TEX) VALUE('FS01M, ANTES DE +
                          PGM-COMPENSOC                     ')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CRFS01    +
                          FICHEROS CRFS01    LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFS  +
                          FICHEROS CONTROFS  LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BORECI    +
                          FICHEROS BORECI    LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(COMPENFAC +
                          FICHEROS COMPENFAC LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(COMPENBOL +
                          FICHEROS COMPENBOL LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FA        +
                          FICHEROS FA        LIBSEG30D C ' ' ' ' +
                          &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(XOPABP    +
                          FICHEROS XOPABP    LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

 /*CREACION FICHEROS*/

             CRTPF      FILE(FICHEROS/CABEVISOC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABEVISOC))

             CRTPF      FILE(FICHEROS/DETEVISOC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEVISOC))

             CRTPF      FILE(FICHEROS/ASIFISOC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILEN) +
                          OPTION(*NOSRC *NOLIST)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFISOC))

             CRTPF      FILE(FICHEROS/FASOC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FA) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000 EXEC(CLRPFM FICHEROS/FASOC)

      /*DGR: CREAR FASOC PARA PARCIAL */


 /*EJECUCION PROGRAMA*/

 /*          OVRDBF     FILE(CABEVI)      TOFILE(CABEVISOC)  */
 /*          OVRDBF     FILE(DETEVI)      TOFILE(DETEVISOC)  */
 /*          OVRDBF     FILE(ASIFIVA)     TOFILE(ASIFISOC)   */
 /*          OVRDBF     FILE(COMPENFAC)   TOFILE(COMPENFAS)  */

             CALL       PGM(COMPENSOC) PARM(&CODRET)

 /*          DLTOVR     FILE(CABEVI)                         */
 /*          DLTOVR     FILE(DETEVI)                         */
 /*          DLTOVR     FILE(ASIFIVA)                        */
 /*          DLTOVR     FILE(COMPENFAC)                      */
             CHGJOB     DATE(&FECHA)

 /*=======================*/
 /*EVIDENCIA CONTABLE   */
 /*=======================*/

             IF         (&CODRET *EQ '1') THEN(DO)
             CPYF       FROMFILE(FICHEROS/DETEVISOC) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABEVISOC) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/FASOC) +
                          TOFILE(FICHEROS/FA) MBROPT(*ADD)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL +
                          PGM-COMPENSOC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEVISOC FICHEROS +
                          DETEVISOC LIBSEG1D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEVISOC FICHEROS +
                          CABEVISOC LIBSEG1D C ' ' ' ' &TEX FS01)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FASOC FICHEROS +
                          FASOC LIBSEG1D C ' ' ' ' &TEX FS01)

 /*ASIENTO CONTABLE*/

             OVRDBF     FILE(ASIFILE) TOFILE(ASIFISOC)
             CALL       PGM(EXPLOTA/ACASBON) PARM('002')
             DLTOVR     FILE(ASIFILE)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIFISOC FICHEROS +
                          ASIFISOC LIBSEG30D C ' ' ' ' &TEX FS01)

 /*ENVIO DEL HISTORICO*/

             CHGVAR     VAR(&MSG1) VALUE('Bolsa general de saldos +
                          compensados entre socios y comercios.')
             CHGVAR     VAR(&SECU) VALUE(0080)
             CL1        LABEL(COMPEN.TXT) LON(100)
             CPYF       FROMFILE(FICHEROS/COMPENBOL) +
                          TOFILE(FICHEROS/COMPEN.TXT) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             CALL       PGM(EXPLOTA/EMAILCL2) PARM(&SECU &MSG1 +
                          'FICHEROS  ' 'COMPEN.TXT' 'VARMAIL   ')

 /*VERIFICAR TOTALES*/

 /*          CALL       PGM(EXPLOTA/TOTAL) PARM(BE0000)        */
 /*          CALL       PGM(EXPLOTA/TOTAL) PARM(BORECI)        */

/*--------------------------------------------------------------*/
/*   01/6/2023 ELIMINAR SORT (SFA) QUE CLASIFICABA EL -FA-    */
/*--------------------------------------------------------------*/
             CRTLF      FILE(FICHEROS/SFA) SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('LOGICO -FA- POR Nº.TARJETA Y CODIGO +
                          OPERACION') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             RGZPFM     FILE(FICHEROS/FA) KEYFILE(FICHEROS/SFA SFA)

             D1         LABEL(SFA) LIB(FICHEROS)
/*--------------------------------------------------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('ASEGURARSE QUE LOS +
                          SOCIOS DEL FICHERO COMPENFAS TIENEN LOS +
                          RECIBOS COMPENSADOS' ' ' FS01)

             ENDDO
 /*=======================*/
 /*NO HAY COMPENSACIONES*/
 /*=======================*/

             IF         (&CODRET *EQ ' ') THEN(DO)
             DLTF       FILE(FICHEROS/CABEVISOC)
             DLTF       FILE(FICHEROS/DETEVISOC)
             DLTF       FILE(FICHEROS/ASIFISOC)

             CHGVAR     VAR(&MSG) VALUE('** NO HAY COMPENSACION DE +
                          SALDOS. SI FACT.10,20 ó FIN MES +
                          (INVESTIGAR), PGM-COMPENSOC. **')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((GrupoAS400@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS +
                          -NORMAL- CLP.FS01M   ') LONGMSG(&MSG)
             ENDDO
 /*=======================*/

             D1         LABEL(CTLREC) LIB(FICHEROS)
/*-------------------------------------------------------------------*/
/*       CAREBA  -CREA CALENDARIO DE RECIBOS PENDIENTES DE VENCER-   */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                          PROGRAMA  +
                          CAREBA  EN EJECUCION' ' ' FS01)
             CRTLF      FILE(FICHEROS/BORECLG2) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000
             CALL       PGM(EXPLOTA/CAREBA)

             CALLSUBR   SUBR(CUADRERECI)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 66 */
/*-------------------------------------------------------------------*/
/*    RECO06: LISTADO DETALLE ACCIONES DE RECOBRO                    */
/* RECO09: CREA "RECOBRO003" DESDE -MSOCIO- YA ACTUALIZADO.          */
/* RECO10_FPD: INFORECOBRO "IMPAGO DE SALDOS ATRASADOS "PAGO DIRECTO"*/
/* RECO10_FPB: INFORECOBRO "DEVOLUCIONES REFACTURADAS DE "PAGO BANCO"*/
/*-------------------------------------------------------------------*/
 RE66:

             CHGVAR     VAR(&TEX) VALUE('FS01, DE SALIDA EN +
                          FACTURACION')
/*-------------------------------------*/
/* LISTADO DETALLE ACCIONES DE RECOBRO */
/*-------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -RECO06- +
                          EN +
                          EJECUCION                                   -
            ' ' ' FS01)
             CRTPF      FILE(FICHEROS/PRIM.TXT) RCDLEN(132) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PRIM.TXT))

/*           OVRDBF     FILE(MSOCIO) TOFILE(FICHEROS/MSOCIO88) */
             OVRDBF     FILE(IMP00P16) TOFILE(PRIM.TXT)
             CALL       PGM(EXPLOTA/RECO06) PARM('P')
             DLTOVR     FILE(IMP00P16)
/*           DLTOVR     FILE(MSOCIO)                           */

             ENMAIL3    SECU(0065) EMSG('Tarjetas con accion de +
                          recobro') CLIB(FICHEROS) FICH(PRIM.TXT) +
                          CARP(VARMAIL)

             DLTF       FILE(FICHEROS/PRIM.TXT)
             CHGJOB     DATE(&FECHA)
/*-------------------------------------*/
/*"InfoRecobro" FICHERO -RECOBRO003- */
/*-------------------------------------*/
/* PGM-RECO09, CON MSOCIO ACTUALIZADO  */
/*-------------------------------------*/
             CALL       PGM(TRACE) PARM('PROGRAMA -RECO09- EN +
                          EJECUCION                                   -
            ' ' ' FS01)

             CRTPF      FILE(FICHEROS/RECOBRO003) SRCMBR(RECOBRO001) +
                          TEXT('RECOBRO MICROINFORMATICA: +
                          FICHERO-0001') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/RECOBRO003))

             CRTLF      FILE(FICHEROS/GRANELG7) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -GRANEXFI-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             OVRDBF     FILE(RECOBRO001) TOFILE(FICHEROS/RECOBRO003)

             CALL       PGM(EXPLOTA/RECO09)

             DLTOVR     FILE(RECOBRO001)
             CHGJOB     DATE(&FECHA)
/*-------------------------------------*/
/*"InfoRecobro" FICHERO -RECOBRO004- */
/*-------------------------------------*/
/*   PGM-RECO10_FPD (PAGO DIRECTO)     */
/*-------------------------------------*/
             CALL       PGM(TRACE) PARM('PROGRAMA -RECO10_FPD- EN +
                          EJECUCION                                   -
        ' ' ' FS01)

             CRTPF      FILE(FICHEROS/RECOBRO004) SRCMBR(RECOBRO002) +
                          TEXT('RECOBRO MICROINFORMATICA: +
                          FICHERO-0002') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/RECOBRO004))

             OVRDBF     FILE(MSOCIOXX) TOFILE(FICHEROS/MSOCIO88)
             OVRDBF     FILE(RECOBRO002) TOFILE(FICHEROS/RECOBRO004)
             CALL       PGM(EXPLOTA/RECO10_FPD)
             DLTOVR     FILE(MSOCIOXX)

             OVRDBF     FILE(MSOCIOXX) TOFILE(FICHEROS/MSOCIO87)
             CALL       PGM(EXPLOTA/RECO10_FPD)
             DLTOVR     FILE(MSOCIOXX)

             CHGJOB     DATE(&FECHA)
/*-------------------------------------*/
/* PGM-RECO10_FPB (PAGO POR BANCO)     */
/*-------------------------------------*/
             CALL       PGM(TRACE) PARM('PROGRAMA -RECO10_FPB- EN +
                          EJECUCION                                   -
        ' ' ' FS01)

             OVRDBF     FILE(MSOCIOXX) TOFILE(FICHEROS/MSOCIO88)
             CALL       PGM(EXPLOTA/RECO10_FPB)
             DLTOVR     FILE(MSOCIOXX)

             OVRDBF     FILE(MSOCIOXX) TOFILE(FICHEROS/MSOCIO87)
             CALL       PGM(EXPLOTA/RECO10_FPB)
             DLTOVR     FILE(MSOCIOXX)
             DLTOVR     FILE(RECOBRO002)

             CHGJOB     DATE(&FECHA)
/*-------------------------------------*/
/*          "InfoRecobro"              */
/*  EXPORT_SQL y Seguridad Ficheros  */
/*-------------------------------------*/
             RTVMBRD    FILE(FICHEROS/RECOBRO004) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CHGVAR     VAR(&CLAVES) +
                          VALUE('RECOBRO004                    ')
             CALL       PGM(EXPLOTA/CTREXPORCL) PARM(&FECHA +
                          'RECOBRO004' 'FICHEROS' 'RECOBRO004' +
                          'PCFICHEROS' &CLAVES &AGRUP1 &AGRUP2)
             CHGVAR     VAR(&CLAVES) VALUE(' ')
             CHGJOB     DATE(&FECHA)
             ENDDO
             ELSE       CMD(DO)
             CLRPFM     FILE(FICHEROS/RECOBRO003) /* Por no tener +
                          registros el RECOBRO004 */
             ENDDO

             CHGVAR     VAR(&TEX) VALUE('FS01, RECOBRO004 SALIDO DE +
                          PGM-RECO10_FPD y _FPB  ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECOBRO004 +
                          FICHEROS RECOBRO004 LIBSEG30D 'M' ' ' ' ' +
                          &TEX FS01)
/*=====*/
             RTVMBRD    FILE(FICHEROS/RECOBRO003) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CHGVAR     VAR(&CLAVES) +
                          VALUE('RECOBRO003                    ')
             CALL       PGM(EXPLOTA/CTREXPORCL) PARM(&FECHA +
                          'RECOBRO003' 'FICHEROS' 'RECOBRO003' +
                          'PCFICHEROS' &CLAVES &AGRUP1 &AGRUP2)
             CHGVAR     VAR(&CLAVES) VALUE(' ')
             CHGJOB     DATE(&FECHA)
             ENDDO

             CHGVAR     VAR(&TEX) VALUE('FS01, RECOBRO003 SALIDO DE +
                          PGM-RECO09.            ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECOBRO003 +
                          FICHEROS RECOBRO003 LIBSEG30D 'M' ' ' ' ' +
                          &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 67 */
/*-------------------------------------------------------------------*/
/*   LIBRE  LIBRE  LIBRE                                           --*/
/*-------------------------------------------------------------------*/
 RE67:
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 68 */
/*-------------------------------------------------------------------*/
/*--           COPIAR: -MEMPRE- Y -COMTREMP- SI EMPRESAS           --*/
/*-------------------------------------------------------------------*/
 RE68:       IF         COND(&DD = 05) THEN(GOTO CMDLBL(NOSAEMP))
             IF         COND(&DD = 15) THEN(GOTO CMDLBL(NOSAEMP))
             IF         COND(&DD = 25) THEN(GOTO CMDLBL(NOSAEMP))
             CHGVAR     VAR(&TEX) VALUE('FS01, FINAL PROCESO FS01    ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MEMPRE FICHEROS +
                          MEMPRE LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
 NOSAEMP:    CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 69 */
/*-------------------------------------------------------------------*/
/*- LIBRE                                                            */
/*-------------------------------------------------------------------*/
 RE69:

             CHGJOB     DATE(&FECHA)

 IRRE70:     CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 70 */
/*-------------------------------------------------------------------*/
/*               DELETES Y COPIAS FINALES                          */
/*-------------------------------------------------------------------*/
 RE70:       CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0062' ' ' FS01)

             DLTF       FICHEROS/FASALE
             DLTF       FICHEROS/PASALE
             DLTF       FICHEROS/FASALEMC
             DLTF       FICHEROS/PASALEMC

             D1         LABEL(CONTROEU) LIB(FICHEROS)
             D1         LABEL(FSANUAL) LIB(FICHEROS)
             D1         LABEL(REACU)
             D1         LABEL(FS011)
             D1         LABEL(REAFA)
             D1         LABEL(NOFACSI)
             D1         LABEL(GRAMON)
             D1         LABEL(COPYPRU)
             D1         LABEL(ERRDESCR)
             D1         LABEL(CAADETAN)
             D1         LABEL(CAATOTAN)
             D1         LABEL(CAADETAA)
             D1         LABEL(CAATOTAA)
             D1         LABEL(SAPNB_AUX)
             D1         LABEL(FESOCI_PDF)
             D1         LABEL(CUOTEFAC)   LIB(FICHEROS)
             D1         LABEL(FAPACUOTE5) LIB(FICHEROS)
             D1         LABEL(FACTURA05)  LIB(FICHEROS)
             D1         LABEL(CABEVI05)   LIB(FICHEROS)
             D1         LABEL(DETEVI05)   LIB(FICHEROS)
             D1         LABEL(COMPENFAS)  LIB(FICHEROS)

/*--*/
             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-+
                          FSFAPA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA88 FICHEROS +
                          FAPA88  LIBSEG30D C ' ' ' ' &TEX FS01)
             DLTF       FICHEROS/FAPA88

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA88DI FICHEROS +
                          FAPA88DI  LIBSEG30D C ' ' ' ' &TEX FS01)
             DLTF       FICHEROS/FAPA88DI

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA88MC FICHEROS +
                          FAPA88MC  LIBSEG30D C ' ' ' ' &TEX FS01)
             DLTF       FICHEROS/FAPA88MC

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA87 FICHEROS +
                          FAPA87  LIBSEG30D C ' ' ' ' &TEX FS01)
             DLTF       FICHEROS/FAPA87

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 71 */
/*-------------------------------------------------------------------*/
/*   POR TEMA DE REARRANQUES SE CREA EL CL.FS02M --FINAL FACT.--   */
/*-------------------------------------------------------------------*/
 RE71:       DLTOVR     FILE(*ALL)
             CALL       PGM(EXPLOTA/FS02M) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

/*--------------------------------------------------------------------*/
/*  31.8.2012 SE ELIMINA ESTA EJECUCION DEL CLP.FEC03 POR COINCIDIR */
/*            SBMJOB (AUTOMATISMO) ANTES QUE CLP.SELBACL.           */
/* DLTDES.- SUPRIME RGTROS. ANTIGUOS DEL DESCRFAC DE MAS DE 32 DIAS,  */
/*          NO SUPRIME REGISTRO DE SOCIOS CON CONCILIACION.           */
/*--------------------------------------------------------------------*/
             IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(EXPLOTA/DLTDESCL) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)
             ENDDO
/*--------------------------------------------------------------------*/
/*   NO SE MUEVE "RECIBOS" HASTA FIN (FS02M) SE USA EN CL.SELBACLM  */
/*--------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01, MSOCIO87 DESPUES DEL +
                          PGM-FSBALA             ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO87 FICHEROS +
                          MSOCIO87 LIBSEG30D C ' ' ' ' &TEX FS01)

             DLTF       FICHEROS/MSOCIO87

             CHGVAR     VAR(&TEX) VALUE('FS01, MSOCIO88 DESPUES DEL +
                          PGM-FSBALA             ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88 FICHEROS +
                          MSOCIO88 LIBSEG30D C ' ' ' ' &TEX FS01)

             DLTF       FICHEROS/MSOCIO88

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-FSCREA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECIBOS FICHEROS +
                          RECIBOS LIBSEG30D C ' ' ' ' &TEX FS01)

             DLTF       FICHEROS/RECIBL3
             MONMSG     MSGID(CPF0000)

             DLTF       FICHEROS/RECIBL10
             MONMSG     MSGID(CPF0000)

             DLTF       FICHEROS/RECIBOS

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 72 */
/*-------------------------------------------------------------------*/
/*            ACUPACL2 -ACUMULACION DE UN PAPRE PENDIENTE-         */
/*-------------------------------------------------------------------*/
 RE72:       CHKOBJ     OBJ(FICHEROS/PAPRE) OBJTYPE(*FILE)
             MONMSG     CPF0000 EXEC(GOTO NOPAPRE)

             CALL       PGM(EXPLOTA/TRACE) PARM('* OJO, hay un PAPRE +
                          en la ficheros, esto solo puede ocurrir +
                          si en la ultima ' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('* facturacion de +
                          estab., no se pudo acumular al +
                          PA.                       ' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('* En ese caso +
                          debeis tener un aviso producido por el +
                          pgm-acupacl en el que se' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('* comenta este +
                          hecho.                                      -
                   ' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('* Por lo tanto al +
                          pulsar intro se ejecutara el pgm-acupacl2 +
                          para que dicho    ' ' ' FS01)
             CALL       PGM(EXPLOTA/TRACE) PARM('* PAPRE se acumule +
                          ahora.                                      -
              ' ' ' FS01)


             CALL       PGM(EXPLOTA/ACUPACL2M) PARM(&FECHA)

             CHGJOB     DATE(&FECHA)
 NOPAPRE:    CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 73 */
/*-------------------------------------------------------------------*/
/*    PGM-FSCREBO2-ACT. 4º RECIBO EXT.UNIF.SIN MOVIMIENTOS         */
/*-------------------------------------------------------------------*/
RE73:        IF         COND(&DD = 10 *OR &DD = 20 *OR &DD > 27) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA FSCREBO2 EN EJECUCION.' ' ' FS01)
             CALL       PGM(EXPLOTA/FSCREBO2)
             ENDDO

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CRFS01 FICHEROS +
                          CRFS01 LIBSEG1D M ' ' ' ' &TEX FS01)
             MONMSG     MSGID(CPF0000)

 /**         D1         LABEL(FAPACAMSO) LIB(FICHEROS)      **/

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 74 */
/*-------------------------------------------------------------------*/
/*    PGM-CTRFASO1, CONTROL PARA ACUMULACION AL PA EN EL ACUPACL   */
/*-------------------------------------------------------------------*/
 RE74:       CALL       PGM(EXPLOTA/CTRFASO1) PARM(&FECHA)

             CHGVAR     VAR(&TEX) VALUE('FS01, DESPUES DEL PGM-+
                          CTRFASO1')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CTFACSOC FICHEROS +
                        CTFACSOC  LIBSEG30D C ' ' ' ' &TEX FS01)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 75 */
/*-------------------------------------------------------------------*/
/* LIBRE                                                            */
/*-------------------------------------------------------------------*/
 RE75:

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 76 */
/*-------------------------------------------------------------------*/
/*    AUDITORIA INTERNA (Datos para Departamento Contabilidad)     */
/*    ========================================================     */
/*     - TARJETAS TE'S CON ACTIVIDADES FINACIERAS                  */
/*       Fichero (.csv) por e-mail, Saldos FAPA (+), Status 0 y 1. */
/*     - TRASPASOS DE SALDOS: FA, PA Y BOLSA DE AGENCIA            */
/*       Asientos y Evidencias Contables.                          */
/*-------------------------------------------------------------------*/
 RE76:       IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(EXPLOTA/TSDOSAUDI) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)
             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 77 */
/*-------------------------------------------------------------------*/
/*   PCCANUALCL (clp) FICHERO PARA DEPARTAMENTO RIESGOS            */
/*   FSCTANUAL  (pgm) CRONOLOGIA MENSUAL DE TARJETAS FACTURADAS    */
/*                    DATOS PARA RESUMEN TRIMESTRAL "CUENTA ANUAL" */
/*-------------------------------------------------------------------*/
 RE77:       IF         COND(&DD *GE 28) THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA +
                          -PCCANUALCL EN EJECUCION' ' ' FS01)

             CALL       PGM(EXPLOTA/PCCANUALCL)

   /*----*/
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA +
                          -FSCTANUAL- EN EJECUCION' ' ' FS01)

             CALL       PGM(EXPLOTA/FSCTANUAL)

             CHGVAR     VAR(&TEX) VALUE('FS01, DE SALIDA EN +
                          FACTURACION                    ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MS_CTANUAL +
                          FICHEROS MS_CTANUAL LIBSEG30D C ' ' ' ' +
                          &TEX FS01)

             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 78 */
/*-------------------------------------------------------------------*/
/*   RECIBOS FIN DE MES PARA RIESGOS                               */
/*-------------------------------------------------------------------*/
 RE78:       CHGVAR     VAR(&XDIA) VALUE(0)

             CHGJOB     DATE(&FECHAZ)

             CALL       PGM(EXPLOTA/RTVULTDICL) PARM(&XDIA)

             IF         COND(&DD *EQ &XDIA) THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('* ultimo de mes se +
                          ejecuta el Proceso recibos Banco  *' ' ' +
                          FS01)

             CALL       PGM(EXPLOTA/MICRECCLM) PARM(&FECHA)

             CHGJOB     DATE(&FECHA)

             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 79 */
/*-------------------------------------------------------------------*/
/*    LIBRERIA: BDEAAAAMM (FOTO FICHEROS "INFORME BANCO DE ESPAÑA" */
/*              TAREA SEMESTRAL: 30-JUNIO Y 31-DICIEMBRE.          */
/*     12/8/2021   SE DECIDE QUE SE CREE TODOS LOS MESES           */
/*-------------------------------------------------------------------*/
 RE79:
             IF         COND(&DD *GE 28) THEN(DO)

             CALL       PGM(EXPLOTA/SEGUBDE) PARM(&FECHA)

             CHGJOB     DATE(&FECHA)

             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 80 */
/*-------------------------------------------------------------------*/
/*    ATRDIAMUE MUEVE OPERACION -NO CONCILIACION-  FICHEROS.       */
/*    BSAT-MSOCIO88AT-CONTROFSAT-DESCRXXAT-EXTRASOCAT-MSOCIO87AT   */
/*                              A                                  */
/*    BSED-MSOCIO88ED-CONTROFSED-DESCRXXED-EXTRASOCED-MSOCIO87ED   */
/*-------------------------------------------------------------------*/
 RE80:       IF         COND(&DD = 10 *OR &DD = 20 *OR &DD > 27) +
                          THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA +
                          -ATRDIAMUE  EN EJECUCION' ' ' FS01)

             CALL       PGM(EXPLOTA/ATRDIAMUE) PARM('E')

             ENDDO
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01) /* 81 */
/*-------------------------------------------------------------------*/
/*    CRUCE DE OPERACIONES Y CREACION DE INFORMES Y ENVIO BOLSAS   */
/*    ATRDIAMUE MUEVE OPERAION -NO CONCILIACION-  FICHEROS:        */
/*    BSED-MSOCIO88ED-CONTROFSED-DESCRXXED-EXTRASOCED-MSOCIO87ED   */
/*                              A                                  */
/*    BSAT-MSOCIO88AT-CONTROFSAT-DESCRXXAT-EXTRASOCAT-MSOCIO87AT   */
/*-------------------------------------------------------------------*/
 RE81:       IF         COND(&DD = 05 *OR &DD = 15 *OR &DD = 25) +
                          THEN(DO)


             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA +
                          -ATRCRUBSCL EN EJECUCION' ' ' FS01)

             CALL       PGM(EXPLOTA/ATRCRUBSCL)

             CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'CRUZAOPT1 ')

             IF         COND(&ACCION = 'S') THEN(DO)
             GOTO       CMDLBL(NOMUEVE)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA +
                          -ATRDIAMUE  EN EJECUCION' ' ' FS01)

             CALL       PGM(EXPLOTA/ATRDIAMUE) PARM('S')

             ENDDO

 NOMUEVE:    CHGJOB     DATE(&FECHA)
/*-------------------------------------------------------------------*/
/*                       FIN CL. FS01                              */
/*-------------------------------------------------------------------*/
             CALL       PGM(PRFICCTL) PARM('B' 'FACRECI   ')
             DLTF       FILE(FICHEROS/XOPAMSOC)
             MONMSG     MSGID(CPF0000)
             CALL       PGM(PRDIACTL) PARM('B' 'FS01M     ')

             CHGVAR     VAR(&TEXTO) VALUE('Ejecutado proceso +
                          facturacion socios normal      PROCFACTSE')

             CALL       PGM(EXPLOTA/CTRPROC) PARM('002' 'FS01M     ' +
                          &TEXTO)
 /*------------------------------------------------------------------*/
 /*  TA-FINANCIACION AMPLIADA: ASIENTO Y EVIDENCIA CONTABLE        */
 /*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TAFA05CL) PARM(&FECHA)

 /*------------------------------------------------------------------*/
 /*  BILLHOP -PLATAFORMA DE PAGO ASIENTO Y EVIDENCIA CONTABLE      */
 /*------------------------------------------------------------------*/
             RTVMBRD    FILE(FICHEROS/MS_BILLFAC) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(EXPLOTA/BILLHOFACL) PARM(&FECHA)
             ENDDO

 /*------------------------------------------------------------------*/
 /*     E-MAIL  DE FINALIZACION DEL PROCESO                          */
 /*------------------------------------------------------------------*/
             CHGVAR     VAR(&MSG) VALUE('** ACABA DE FINALIZAR EL +
                          PROCESO ** DE CLP.PROCNOCHE --> +
                          CLP.PROCFACTSE --> CLP.FS01M')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((GrupoAS400@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS +
                          -NORMAL-             ') LONGMSG(&MSG)
 /*------*/

 FIN:        CALL       PGM(EXPLOTA/TRACE) PARM('FIN' ' ' 'FS01')
/********************************************************************/
/* GRABAR INCIDENCIA                                                */
/********************************************************************/
             SUBR       SUBR(INCIDENCIA)

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM((&PROCE) +
                          (&DESCRIP) (&PRIORID))

             CALL       PGM(EXPLOTA/TRACE) PARM((&DESCRIP) (' ') +
                          (FS01))
             ENDSUBR
/********************************************************************/
/* CUADRE   PA                                                      */
/********************************************************************/
             SUBR       SUBR(CUADREPA)


             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CALL       PGM(EXPLOTA/SUMAPAM) PARM(&TOTCUA)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTCUA 'PAGE00' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('NO CUADRA EL +
                          TOTALES "PAGE00". -FS01M INVESTIGAR.' ' ' +
                          FS01)

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "PAGE00". -FS01M-  INVESTIGAR. FACT.SOCIOS.')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "PAGE00" DEL  *-FS01M-  +
                          FACT.SOCIOS   **LLAMAR A Diners Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO
             ENDSUBR
/********************************************************************/
/* CUADRE      / FA /                                               */
/********************************************************************/
             SUBR       SUBR(CUADREFA)

             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CALL       PGM(EXPLOTA/SUMAFAM) PARM(&TOTCUA)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTCUA 'FAGE00' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('NO CUADRA EL +
                          TOTALES "FAGE00". -FS01M INVESTIGAR.' ' ' +
                          FS01)

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "FAGE00". -FS01M-  INVESTIGAR. +
                          FACT.SOCIOS.')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "FAGE00" DEL -PAFADI-  +
                          *-FS01M-  FACT.SOCIOS   **LLAMAR A Diners +
                          Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO
             ENDSUBR
/********************************************************************/
/* CUADRE      RECIBO                                               */
/********************************************************************/
             SUBR       SUBR(CUADRERECI)

             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CALL       PGM(EXPLOTA/SUMATORE) PARM(&TOTCUA)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTCUA 'BORECI' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('NO CUADRA EL +
                          TOTALES "BORECI". -FS01M INVESTIGAR.' ' ' +
                          FS01)

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "BORECI". -FS01M-  INVESTIGAR. +
                          FACT.SOCIOS.')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "BORECI" DEL *-FS01M-  +
                          FACT.SOCIOS   **LLAMAR A Diners Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO
             CALL       PGM(EXPLOTA/TRACE) PARM(&DESCRIP ' ' FS01)
             ENDSUBR
/********************************************************************/
             ENDPGM
