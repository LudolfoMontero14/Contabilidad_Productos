 /**================================================================**/
 /*   ==========================================================     */
 /*   FACTURACION DE ESTABLECIMIENTOS  N O R M A L  (1ª PARTE)     */
 /*   ==========================================================     */
 /**================================================================**/
 /*------------------------------------------------------------------*/
 /*  PARA ARRANCAR SI SE CANCELA EN CONTROL-M                      */
 /*                                                                */
 /*  HACER:                                                        */
 /*  CALL       PGM(PRFICCTL) PARM('B' 'FACTESTABL')               */
 /*  CALL       PGM(PRFICCTL) PARM('B' 'NOACES    ')               */
 /*  CALL       PGM(PRFICCTL) PARM('A' 'NOCHENEG  ')               */
 /*  CALL       PGM(PRFICCTL) PARM('A' 'RECOBRO   ')               */
 /*  Borrar Linea del Fichero PRDIARIO                             */
 /*  ejemplo:                                                      */
 /*  IN02      FACT.DIARIA ESTABLECIMIENTOS NORMAL 1ªPA            */
 /*                                                                */
 /*                                                                */
 /*  COMPROBAR TRACE1                                              */
 /*  -----------------                                             */
 /*  ARRANCAR CON  USUARIO AUTOBANCO -PANTALLA ASIGNADA  -ZZ-      */
 /*                                                                */
 /*------------------------------------------------------------------*/
 /*- MODIFICACIONES                                                 -*/
 /*- APG1 - 02/02/2023    PROYECTO IT-209 MULTIMONEDA               -*/
 /*-        BORRAR DE DIN1 LAS OPERACIONES YA ENVIADAS A DCI        -*/
 /*------------------------------------------------------------------*/
             PGM
             DCL        VAR(&ACCION)  TYPE(*CHAR) LEN(1)
             DCL        VAR(&LABDIN)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&LABMIC)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&DATOS)   TYPE(*CHAR) LEN(14) VALUE('IN02')
             DCL        VAR(&REST1)   TYPE(*CHAR) LEN(10) /* ESTFACMEmm */
             DCL        VAR(&REST2)   TYPE(*CHAR) LEN(10) /* ESTFACGNmm */
             DCL        VAR(&FECHA1)  TYPE(*CHAR) LEN(6)
             DCL        VAR(&FECHA)   TYPE(*DEC)  LEN(6 0)
             DCL        VAR(&FECHAZ)  TYPE(*CHAR) LEN(6)
             DCL        VAR(&FECHA8)  TYPE(*CHAR) LEN(8)
             DCL        VAR(&DD)      TYPE(*DEC)  LEN(2) /* FIN DE MES  */
             DCL        VAR(&DA)      TYPE(*CHAR) LEN(2) /* DIA PROCESO */
             DCL        VAR(&MES)     TYPE(*CHAR) LEN(2) /* MES PROCESO */
             DCL        VAR(&LABEL)   TYPE(*CHAR) LEN(10)
             DCL        VAR(&ORDEN)   TYPE(*CHAR) LEN(5)
             DCL        VAR(&LOGDIN)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&DIA)     TYPE(*DEC)  LEN(2) VALUE(0)
             DCL        VAR(&DIAL)    TYPE(*CHAR) LEN(2)
             DCL        VAR(&TEX)     TYPE(*CHAR) LEN(50)
             DCL        VAR(&ORIG)    TYPE(*CHAR) LEN(1) VALUE('0') /* ECI */
             DCL        VAR(&PTSSAL)  TYPE(*DEC)  LEN(11 0) VALUE(0)
             DCL        VAR(&COD)     TYPE(*DEC)  LEN(1) VALUE(0)
             DCL        VAR(&SQL)     TYPE(*CHAR) LEN(250)
             DCL        VAR(&MSG)     TYPE(*CHAR) LEN(128)
             DCL        VAR(&PRIORID) TYPE(*DEC)  LEN(1 0) VALUE(9) +
                          /* para fichero incidencias */
             DCL        VAR(&DESCRIP) TYPE(*CHAR) LEN(80) /* para +
                          fichero incidencias */
             DCL        VAR(&PROCE)   TYPE(*CHAR) LEN(10) +
                          VALUE('IN02      ') /* /fichero de Incidencias */
             DCL        VAR(&CODRET)  TYPE(*CHAR) LEN(1)
             DCL        VAR(&NOCUA)   TYPE(*CHAR) LEN(1)
             DCL        VAR(&TOTCUA)  TYPE(*DEC)  LEN(11 0)
             DCL        VAR(&TOTCUB)  TYPE(*DEC)  LEN(11 0)
             DCL        VAR(&XDIFZ)   TYPE(*DEC)  LEN(10 0)
             DCL        VAR(&XOTBE)   TYPE(*DEC)  LEN(11 0)
             DCL        VAR(&DESCTOT) TYPE(*CHAR) LEN(200) /* MSG CONTROL-M */
             DCL        VAR(&NUMREG)  TYPE(*DEC)  LEN(10 0)
             DCL        VAR(&BLOQUEA) TYPE(*CHAR) LEN(1)
             DCL        VAR(&ERROR)   TYPE(*CHAR) LEN(1)
             DCL        VAR(&TEXTO)   TYPE(*CHAR) LEN(80)
             DCL        VAR(&PARAM)   TYPE(*CHAR) LEN(10) VALUE(' ')
             DCL        VAR(&CADENA)  TYPE(*CHAR) LEN(10) VALUE('IN02')

 /*------------------------------------------------------------------*/
 /*   ARRANCAR EL TRACE                                              */
 /*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&FECHAZ)

 /*------------------------------------------------------------------*/
 /*   SI SE CANCELADO MANUALMENTE BORRAR ESTE FICHEROS -FACTESTABL-  */
 /*   YA HAY UN PROCESO DE FACTURACION DE ESTABLECIMIENTOS ARRANCADO */
 /*------------------------------------------------------------------*/
             CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'FACTESTABL')

             IF         COND(&ACCION = 'S') THEN(DO)

             CHGVAR     VAR(&MSG) VALUE('YA HAY UNA +
                          FACT.ESTABLECMIENTOS  ARRANCADA o TERMINO +
                          MAL  -Investigar')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACT.ESTABLECIMIENTOS  IN02M     ') +
                          LONGMSG(&MSG)

             CHGVAR     VAR(&DESCRIP) VALUE('YA HAY UNA  +
                          FACT.ESTABLECMIENTOS  ARRANCADA O +
                          TERMINO  MAL  -Investigar')

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FININ02)

             ENDDO
 /*------------------------------------------------------------------*/
 /*   FICHERO DE CONTROL D FACTURACION DE ESTABLECIMIENTOS           */
 /*------------------------------------------------------------------*/
             CALL       PGM(PRFICCTL) PARM('A' 'FACTESTABL')

 /*------------------------------------------------------------------*/
 /*        SE RECIBE FECHA DEL SISTEMA  RESTANDO UN DIA              */
 /*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/RTVFECHA) PARM(&FECHA)

             CHGVAR     VAR(&FECHA1) VALUE(&FECHA)
             CHGJOB     DATE(&FECHA1) SWS(00000000)
             CHGVAR     VAR(&DD) VALUE(%SUBSTRING(&FECHA1 1 2))
             CHGVAR     VAR(&DA) VALUE(%SUBSTRING(&FECHA1 1 2))
             CHGVAR     VAR(&MES) VALUE(%SUBSTRING(&FECHA1 3 2))

             CHGJOB     SWS(XXXXXX11)
             OVRDBF     FILE(ESTABLE) TOFILE(FICHEROS/ESTA1)
 /*------------------------------------------------------------------*/
 /* R E A R R A N Q U E    A U T O M A T I C O                       */
 /*------------------------------------------------------------------*/
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '01') +
                          THEN(GOTO CMDLBL(REA1))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '02') +
                          THEN(GOTO CMDLBL(REA2))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '03') +
                          THEN(GOTO CMDLBL(REA3))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '04') +
                          THEN(GOTO CMDLBL(REA4))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '05') +
                          THEN(GOTO CMDLBL(REA5))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '06') +
                          THEN(GOTO CMDLBL(REA6))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '07') +
                          THEN(GOTO CMDLBL(REA7))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '08') +
                          THEN(GOTO CMDLBL(REA8))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '09') +
                          THEN(GOTO CMDLBL(REA9))
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
                          THEN(GOTO CMDLBL(REA15))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '16') +
                          THEN(GOTO CMDLBL(REA16))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '17') +
                          THEN(GOTO CMDLBL(REA17))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '18') +
                          THEN(GOTO CMDLBL(REA18))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '19') +
                          THEN(GOTO CMDLBL(REA19))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '20') +
                          THEN(GOTO CMDLBL(REA20))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '21') +
                          THEN(GOTO CMDLBL(REA21))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '22') +
                          THEN(GOTO CMDLBL(REA22))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '23') +
                          THEN(GOTO CMDLBL(REA23))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '24') +
                          THEN(GOTO CMDLBL(REA24))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '25') +
                          THEN(GOTO CMDLBL(REA25))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '26') +
                          THEN(GOTO CMDLBL(REA26))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '27') +
                          THEN(GOTO CMDLBL(REA27))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '28') +
                          THEN(GOTO CMDLBL(REA28))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '29') +
                          THEN(GOTO CMDLBL(REA29))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '30') +
                          THEN(GOTO CMDLBL(REA30))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '31') +
                          THEN(GOTO CMDLBL(REA31))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '32') +
                          THEN(GOTO CMDLBL(REA32))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '33') +
                          THEN(GOTO CMDLBL(REA33))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '34') +
                          THEN(GOTO CMDLBL(REA34))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '35') +
                          THEN(GOTO CMDLBL(REA35))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '36') +
                          THEN(GOTO CMDLBL(REA36))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '37') +
                          THEN(GOTO CMDLBL(REA37))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '38') +
                          THEN(GOTO CMDLBL(REA38))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '39') +
                          THEN(GOTO CMDLBL(REA39))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '40') +
                          THEN(GOTO CMDLBL(REA40))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '41') +
                          THEN(GOTO CMDLBL(REA41))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '42') +
                          THEN(GOTO CMDLBL(REA42))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '43') +
                          THEN(GOTO CMDLBL(REA43))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '44') +
                          THEN(GOTO CMDLBL(REA44))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '45') +
                          THEN(GOTO CMDLBL(REA45))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '46') +
                          THEN(GOTO CMDLBL(REA46))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '47') +
                          THEN(GOTO CMDLBL(REA47))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '48') +
                          THEN(GOTO CMDLBL(REA48))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '49') +
                          THEN(GOTO CMDLBL(REA49))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '50') +
                          THEN(GOTO CMDLBL(REA50))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '51') +
                          THEN(GOTO CMDLBL(REA51))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '52') +
                          THEN(GOTO CMDLBL(REA52))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '53') +
                          THEN(GOTO CMDLBL(REA53))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '54') +
                          THEN(GOTO CMDLBL(REA54))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '55') +
                          THEN(GOTO CMDLBL(REA55))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '56') +
                          THEN(GOTO CMDLBL(REA56))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '57') +
                          THEN(GOTO CMDLBL(REA57))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '58') +
                          THEN(GOTO CMDLBL(REA58))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '59') +
                          THEN(GOTO CMDLBL(REA59))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '60') +
                          THEN(GOTO CMDLBL(REA60))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '61') +
                          THEN(GOTO CMDLBL(REA61))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '62') +
                          THEN(GOTO CMDLBL(REA62))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '63') +
                          THEN(GOTO CMDLBL(REA63))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '64') +
                          THEN(GOTO CMDLBL(REA64))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '65') +
                          THEN(GOTO CMDLBL(REA65))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '66') +
                          THEN(GOTO CMDLBL(REA66))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '67') +
                          THEN(GOTO CMDLBL(REA67))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '68') +
                          THEN(GOTO CMDLBL(REA68))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '69') +
                          THEN(GOTO CMDLBL(REA69))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '70') +
                          THEN(GOTO CMDLBL(REA70))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '71') +
                          THEN(GOTO CMDLBL(REA71))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '72') +
                          THEN(GOTO CMDLBL(REA72))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '73') +
                          THEN(GOTO CMDLBL(REA73))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '74') +
                          THEN(GOTO CMDLBL(REA74))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '75') +
                          THEN(GOTO CMDLBL(REA75))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '76') +
                          THEN(GOTO CMDLBL(REA76))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '77') +
                          THEN(GOTO CMDLBL(REA77))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '78') +
                          THEN(GOTO CMDLBL(REA78))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '79') +
                          THEN(GOTO CMDLBL(REA79))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '80') +
                          THEN(GOTO CMDLBL(REA80))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '81') +
                          THEN(GOTO CMDLBL(REA81))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '82') +
                          THEN(GOTO CMDLBL(REA82))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '83') +
                          THEN(GOTO CMDLBL(REA83))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '84') +
                          THEN(GOTO CMDLBL(REA84))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '85') +
                          THEN(GOTO CMDLBL(REA85))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '86') +
                          THEN(GOTO CMDLBL(REA86))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '87') +
                          THEN(GOTO CMDLBL(REA87))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '88') +
                          THEN(GOTO CMDLBL(REA88))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '89') +
                          THEN(GOTO CMDLBL(REA89))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '90') +
                          THEN(GOTO CMDLBL(REA90))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '91') +
                          THEN(GOTO CMDLBL(REA91))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '92') +
                          THEN(GOTO CMDLBL(REA92))

 /*-------------------------------------------------------------------------*/
 /* CUADRE IN02M - SUMO FICHEROS ENTRADA    PROCESO DIARIO                */
 /*-------------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  +
                          ADDNACMCL   EN EJECUCION' ' ' IN02)

             CALL       PGM(EXPLOTA/ADDNACMCL)

 /*------------------------------------------------------------------*/
 /* CONTROL TRABAJO EJECUTADO  --PRDIARIO Y PRDIARIOHI               */
 /*------------------------------------------------------------------*/
             CALL       PGM(PRDIACTL) PARM('A' 'IN02      ')

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  1 */
 /*------------------------------------------------------------------*/
 /* FICHEROS DE CONTROL  -NOACES-   -NOPAIN-   -PROPA-               */
 /*------------------------------------------------------------------*/
 REA1:       CALL       PGM(PRFICCTL) PARM('A' 'NOACES    ')
             CALL       PGM(PRFICCTL) PARM('A' 'NOPAIN    ')
             CALL       PGM(PRFICCTL) PARM('A' 'PROPA     ')

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  2 */
 /*------------------------------------------------------------------*/
 /*       EXISTE FICHEROS DE ANEXOS ESTABLECIMIENTOS -PENCOMES-      */
 /*       EXISTE FICHEROS DE ANEXOS ESTABLECIMIENTOS -PENCOMXX-      */
 /*       PENCOMXX ES FICHERO PENCOMES PARA ACUMULAR                 */
 /*       Primer día del Mes: Controla si esta ESTFACMExx"          */
 /*       Primer día del Mes: Controla si esta ESTFACGNxx"          */
 /*------------------------------------------------------------------*/
 REA2:       CALL       PGM(EXPLOTA/TRACE) PARM('Preparando Anexos +
                          de Establecimientos' ' ' IN02)

             CHKOBJ     OBJ(FICHEROS/PENCOMES) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(CRTPF +
                          FILE(FICHEROS/PENCOMES) TEXT('Anexos +
                          Establecimientos') OPTION(*NOSRC *NOLIST) +
                          LVLCHK(*NO) AUT(*ALL))

             CHKOBJ     OBJ(FICHEROS/PENCOMXX) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(PENB))

             CPYF       FROMFILE(FICHEROS/PENCOMXX) +
                          TOFILE(FICHEROS/PENCOMES) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             DLTF       FILE(PENCOMXX)

 PENB:       CHKOBJ     OBJ(FICHEROS/PENBILLHOP) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(PEN1))

             CPYF       FROMFILE(FICHEROS/PENBILLHOP) +
                          TOFILE(FICHEROS/PENCOMES) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENBILLHOP +
                          FICHEROS PENBILLHOP LIBSEG1D M ' ' ' ' +
                          &TEX IN02)

 PEN1:       CHGVAR     VAR(&REST1) VALUE('ESTFACME' *CAT +
                          (%SUBSTRING(&FECHA1 3 2)))
             CHKOBJ     OBJ(FICHEROS/&REST1) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(CRTPF +
                          FILE(FICHEROS/&REST1) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(ESTFACME) TEXT('Datos Informes +
                          Estadisticos Diarios') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL))
 /*---*/
             CHGVAR     VAR(&REST2) VALUE('ESTFACGN' *CAT +
                          (%SUBSTRING(&FECHA1 3 2)))
             CHKOBJ     OBJ(FICHEROS/&REST2) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(CRTPF +
                          FILE(FICHEROS/&REST2) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(ESTFACGN) TEXT('Datos Informes +
                          Estadisticos, GLOBAL-NET') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL))
 /*---*/
             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  3 */
 /*------------------------------------------------------------------*/
 /*    COPIAS DE SEGURIDAD: FICHEROS DE ENTRADA EN FACTURACION       */
 /*------------------------------------------------------------------*/
 REA3:       CALL       PGM(EXPLOTA/COPIFICHE) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  4 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA4:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  5 */
 /*------------------------------------------------------------------*/
 /* CREACION DEL NACIONAL DE ABONOS LINEAS AEREAS ANTICIPADAS        */
 /*------------------------------------------------------------------*/
 REA5:
             CHGJOB     DATE(&FECHA1)

 /*------------------------------------------------------------------*/
 /* CREACION DEL NACIONAL DE TRANSFERENCIAS DE SOCIOS                */
 /*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/NMOVTFRCL)
             CHGJOB     DATE(&FECHA1)

 /*------------------------------------------------------------------*/
 /* CREACION DEL NACIONAL DE LOTES 490 DE REDSYS                     */
 /*------------------------------------------------------------------*/
             CALL       PGM(SADE/LOTE490CL)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  6 */
 /*------------------------------------------------------------------*/
 /*       ADICIONO INTERNACIONALES AL BLOQINTE -RPG.INTTOD-          */
 /*------------------------------------------------------------------*/
 REA6:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -INTTOD- EN EJECUCION' ' ' IN02)

             CRTPF      FILE(FICHEROS/BLOQINTE) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('bloque +
                          diario de internacional') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BLOQINTE))

             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CHGVAR     VAR(&TOTCUB) VALUE(0)

             OVRPRTF    FILE(QSYSPRT) TOFILE(IMP0017) HOLD(*YES) +
                          SECURE(*YES)
             CALL       PGM(EXPLOTA/INTTOD) PARM(&TOTCUA)
             DLTOVR     FILE(QSYSPRT)
             CALL       PGM(EXPLOTA/INTTOD_N)

 /*----------------------------------------------------*/
 /* CONTROL CUADRE -INTERNACIONAL  SE QUEDE A  - 0 -   */
 /*----------------------------------------------------*/
             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTCUA 'INTERB' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : NO +
                          CUADRA EL TOTALES "INTERB".  INVESTIGAR.' +
                          ' ' IN02)

             CHGVAR     VAR(&DESCRIP) VALUE('IMPORTANTE : NO CUADRA +
                          EL TOTALES "INTERB".  INVESTIGAR. IN02')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "INTER0" CON EL FICHERO DE +
                          PGM-INTTODM -BLOQUINTE **LLAMAR A Diners +
                          Club Spain')

  /*         CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)         */

             ENDDO

             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR EL +
                          PGM-INTTOD')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLOQINTE FICHEROS +
                          BLOQINTE LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  7 */
 /*------------------------------------------------------------------*/
 /*  -CRBLINCL- CREA BLOQINTEF PARA INFORMAR DIARIAMENTE CON LOS     */
 /*  INTERNACIONALES EN P.INCID.  EN CASO DE REARRANCAR NUEVAMENTE   */
 /*  ESTE CL HABRIA QUE RESTAURAR LOS IMOVXX DEL DIA Y EJECUTARLO    */
 /*------------------------------------------------------------------*/
 REA7:       CALL       PGM(EXPLOTA/CRBLINCLM)
             CHGJOB     DATE(&FECHA1)

 /*------------------------------------------------*/
 /* SE CREA "CONCILATOS" PORQUE YA NO SE PROCESAN  */
 /* LOS CIERRES DE ATOS DESDE EL 27/07/2011        */
 /*------------------------------------------------*/

             CALL       PGM(PRFICCTL) PARM('A' 'CONCILATOS')

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  8 */
 /*------------------------------------------------------------------*/
 /*  COPIA AUTORIZA            A LIBSEG1D PARA RECUPERACIÓN        */
 /*------------------------------------------------------------------*/
 REA8:

             D1         LABEL(AUTORIZXX) LIB(LIBSEG1D)

             CPYF       FROMFILE(SADE/AUTORIZA) +
                          TOFILE(LIBSEG1D/AUTORIZXX) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

             CALL       PGM(PRFICCTL) PARM('B' 'CONCILATOS')

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /*  9 */
 /*------------------------------------------------------------------*/
 /*       TABULADOS DE USOS POR REDES                                */
 /*             CREACION DEL NACIONAL DE EL CORTE INGLES             */
 /*------------------------------------------------------------------*/
REA9:
     /*------------------------------------------------------------*/
     /*              TABULADO DE USOS POR REDES                    */
     /*------------------------------------------------------------*/
             CHGVAR     VAR(&FECHA8) VALUE(%SUBSTRING(&FECHA1 1 4) +
                          || '20' || %SUBSTRING(&FECHA1 5 2))
             CALL       PGM(SADE/TABUSOS) PARM(&FECHA8)
             CALL       PGM(SADE/TABUSOS1) PARM(&FECHA8)
     /*------------------------------------------------------------*/

             CALL       PGM(SADE/ECIFACCLM) PARM(&ORIG &FECHA)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 10 */
 /*------------------------------------------------------------------*/
 /*             CREACION DEL NACIONAL DE TELEPAGO                    */
 /*------------------------------------------------------------------*/
 REA10:      CALL       PGM(SADE/TELEFACCLM) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 11 */
 /*------------------------------------------------------------------*/
 /*   NMOV DE: CAJEROS, RENFE, H24 Y PRICE COMERCIOS                 */
 /*------------------------------------------------------------------*/
 REA11:      CALL       PGM(SADE/FACCAJCLM) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 12 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA12:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 13 */
 /*------------------------------------------------------------------*/
 /*      SELECCION DEL APARCA PARA FACTURAR Y LISTADO APARCADOS HOY  */
 /*------------------------------------------------------------------*/
 REA13:      CALL       PGM(SADE/APAR02CLM) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 14 */
 /*------------------------------------------------------------------*/
 /*        CONVERSION Y CLASIFICACION   DE  NMOVXX                   */
 /*------------------------------------------------------------------*/
 REA14:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  CVTNMOV EN EJECUCION' ' ' IN02)

             CALL       PGM(EXPLOTA/CVTNMOVCL)
             CHGJOB     DATE(&FECHA1)

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                            +
                          PROGRAMA NMOVCLACL EN EJECUCION' ' ' IN02)

             CALL       PGM(EXPLOTA/NMOVCLACL)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 15 */
 /*------------------------------------------------------------------*/
 /*    A C U D I A.- ACUMULACION FICHEROS DE NACIONAL  -NMOVXX-      */
 /*------------------------------------------------------------------*/
 REA15:      CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  ACUDIA EN +
                          EJECUCION.' ' ' IN02)

             D1         LABEL(BLODIAN) LIB(FICHEROS)

             CRTPF      FILE(FICHEROS/BLODIAEN) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BLODIAN) +
                          TEXT('bloque de nacional diario') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BLODIAEN))
             STRJRNPF   FILE(FICHEROS/BLODIAEN) +
                          JRN(FICHEROS/QSQJRN) IMAGES(*BOTH) +
                          OMTJRNE(*OPNCLO)

             CRTPF      FILE(FICHEROS/DUPFACES) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('Asignacion de nuevas duplicidades') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DUPFACES))

             CRTPF      FILE(FICHEROS/FRAUDEBD) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FRAUDEBD))


             CHGVAR     VAR(&TEX) VALUE('IN02,ANTES DE EJECUTAR EL +
                          PGM-ACUDIA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FRCRUCE FICHEROS +
                          FRCRUCE LIBSEG1D C ' ' ' ' &TEX IN02)

             OVRDBF     FILE(BLODIAN) TOFILE(FICHEROS/BLODIAEN)
             OVRPRTF    FILE(IMP0017) OUTQ(P12)

             CALL       PGM(EXPLOTA/ACUDIA)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAEN FICHEROS +
                          BLODIAEN LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/ACUDIA_N)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  CARVCN EN +
                          EJECUCION.' ' ' IN02)
             CALL       PGM(EXPLOTA/CARVCN)

             DLTOVR     FILE(IMP0017)
             DLTOVR     FILE(BLODIAN)

             CHGJOB     SWS(000000XX)
 /*----------------------------------------------------*/
 /* CONTROL CUADRE -BLOQUE-  SE QUEDE A  - 0 -         */
 /*----------------------------------------------------*/
             CHGVAR     VAR(&TOTCUA) VALUE(0)
             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTCUA 'BLOQUE' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : NO +
                          CUADRA EL TOTALES "BLOQUE".  INVESTIGAR.' +
                          ' ' IN02)

             CHGVAR     VAR(&DESCRIP) VALUE('IMPORTANTE : NO CUADRA +
                          EL TOTALES "BLOQUE".  INVESTIGAR. IN02')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "BLOQUE" EL SALDO NO ESTA A +
                          -0- PGM-ACUDIA DEL IN02 +
                          FACT.ESTABLECIMIENTOS **LLAMAR A Diners +
                          Club Spain   **-S-Seguir  o cancelar todo +
                          el proceso')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             CHGJOB     DATE(&FECHA1)
             ENDDO
 /*----------------------------------------------------*/
 /* BLODIAEN   A LAS REMESAS LE PONE PAIS 000-         */
 /*----------------------------------------------------*/
             RUNSQLSTM  SRCFILE(EXPLOTA/QCLSRC) SRCMBR(BLODIPAIS) +
                          COMMIT(*NONE)

 /*----------------------------------------------------*/
 /* RENOMBRAR "BLODIAEN" A "BLODIAN"                   */
 /*----------------------------------------------------*/
             RNMOBJ     OBJ(FICHEROS/BLODIAEN) OBJTYPE(*FILE) +
                          NEWOBJ(BLODIAN)

 /*----------------------------------------------------*/
 /*       COPIAS DE SEGURIDAD                          */
 /*----------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DEL PGM-ACUDIA')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(APARCA SADE +
                          APARCA LIBSEG1D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENROJO FICHEROS +
                          PENROJO LIBSEG1D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FRAUDEBD FICHEROS +
                          BRAUDEBD LIBSEG1D M ' ' ' ' &TEX IN02)

             CRTPF      FILE(FICHEROS/REMEFAC) TEXT('Actualizar +
                          remesa facturada en penrojo') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/REMEFAC))

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 16 */
 /*--------------------------------------------------------------------*/
 /*       CONTROL DEL RIESGO EN COMERCIOS                              */
 /*       -------------------------------                              */
 /*  SI HUBIERA QUE REPETIR ALGUNO DE ESTOS PROGRAMAS RECUPERAR LOS    */
 /*  FICHEROS BLODIAN, APARCA Y PENROJO COPIADOS ANTES DE ESTA         */
 /*  EJECUCION.                                                        */
 /*  REGULARIZAR TOTALES DEL APARCA, PINCID, BE0000, B5DIAS Y PENROJO  */
 /*--------------------------------------------------------------------*/
 REA16:      CALL       PGM(EXPLOTA/TRACE) PARM('COMIENZA PROGRAMA +
                          MAXFAC01' ' ' 'IN02')

             CALL       PGM(EXPLOTA/MAXFAC01)

             CALL       PGM(EXPLOTA/TRACE) PARM('COMIENZA PROGRAMA +
                          MAXFAC02' ' ' 'IN02')

             CALL       PGM(EXPLOTA/MAXFAC02)

             CALL       PGM(EXPLOTA/TRACE) PARM('COMIENZA PROGRAMA +
                          MAXFAC04' ' ' 'IN02')

             CALL       PGM(EXPLOTA/MAXFAC04)

 /*----------------------------------------------------*/
 /*       COPIAS DE SEGURIDAD                          */
 /*----------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DEL PGM-MAXFAC')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(APARCA SADE +
                          APARCA LIBSEG1D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENROJO FICHEROS +
                          PENROJO LIBSEG1D C ' ' ' ' &TEX IN02)
 /*------------------------------------------------------*/
 /*  LISTADO CONTROL DE RIESGOS -OPERACIONES APARCADAS-  */
 /*------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  APAR99  EN EJECUCION' ' ' IN02)

             OVRPRTF    FILE(IMP0017) OUTQ(P11) SAVE(*YES)
             CALL       PGM(SADE/APAR99)
             DLTOVR     FILE(IMP0017)

 /*------------------------------------------------------*/
 /*              S T A 1 0 - STATUS EXTRACONTABLES       */
 /*------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          COMIENZA PROGRAMA STA10 ' ' ' 'IN02')

             CRTPF      FILE(FICHEROS/ASISTA10) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASISTA10))

             CRTPF      FILE(FICHEROS/CABE10) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE10))

             CRTPF      FILE(FICHEROS/DETE10) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE10))

             OVRDBF     FILE(ASIFILE) TOFILE(ASISTA10)
             CALL       PGM(EXPLOTA/STA10) PARM('B')
             DLTOVR     FILE(ASIFILE)

             RTVMBRD    FILE(FICHEROS/ASISTA10) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CPYF       FROMFILE(FICHEROS/CABE10) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             CPYF       FROMFILE(FICHEROS/DETE10) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             ENDDO

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 17 */
 /*------------------------------------------------------------------*/
 /* FACTRANSI - TARJETAS FACTURABLES TRANSITORIAMENTE                */
 /*------------------------------------------------------------------*/
 REA17:      CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA FACTRANSI +
                          EN EJECUCION  ' ' ' IN02)

             CALL       PGM(EXPLOTA/FACTRANSI)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 18 */
 /*------------------------------------------------------------------*/
 /* A C U D I 1.- RECAUDACION DE ESTABLECIMIENTOS -CONTABILIDAD-     */
 /*------------------------------------------------------------------*/
 REA18:      OVRPRTF    FILE(IMP0017) OUTQ(P10) SAVE(*YES)

             CRTPF      FILE(FICHEROS/DETEAC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEAC))

             CRTPF      FILE(FICHEROS/CABEAC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABEAC))

             CALL       PGM(EXPLOTA/ACUDI1)

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETEAC) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABEAC) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DEL +
                          PGM-ACUDI1                     ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEAC FICHEROS +
                          DETEAC LIBSEG1D M ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEAC FICHEROS +
                          CABEAC LIBSEG1D M ' ' ' ' &TEX IN02)

             DLTOVR     IMP0017

/*-------------------------------------- */
/* RENOMBRAR  BLODIAN A BLODIAEN         */
/*-------------------------------------- */
             RNMOBJ     OBJ(FICHEROS/BLODIAN) OBJTYPE(*FILE) +
                          NEWOBJ(BLODIAEN)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 19 */
 /*------------------------------------------------------------------*/
 /* LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                            */
 /*------------------------------------------------------------------*/
 REA19:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 20 */
 /*------------------------------------------------------------------*/
 /* LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                            */
 /*------------------------------------------------------------------*/
 REA20:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 21 */
 /*------------------------------------------------------------------*/
 /* S E R O J O.- SEPARA REMESAS ROJAS SEGUN COD.RIESGOS -ESTA1-     */
 /*------------------------------------------------------------------*/
 REA21:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                            +
                          PROGRAMA  SEROJO EN EJECUCION.' ' ' IN02)

             CRTPF      FILE(FICHEROS/BLODIAN) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BLODIAN) +
                          TEXT('bloque de nacional diario - remesas +
                          rojas') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) FRCRATIO(1) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BLODIAN))

             D1         LABEL(BBLODILG) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/BBLODILG) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          BLODIAN PARA RPG.SEROJO') OPTION(*NOLIST +
                          *NOSRC) FRCRATIO(1) LVLCHK(*NO) AUT(*ALL)

             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES)
             CALL       PGM(EXPLOTA/SEROJO)
             DLTOVR     FILE(IMP0017)

 /*------------------------------------------------*/
 /*         -CUADRE   PENROJO                      */
 /*------------------------------------------------*/
             CHGVAR     VAR(&XOTBE) VALUE(0)
             CALL       PGM(EXPLOTA/SUMAPENRO) PARM(&XOTBE)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&XOTBE 'RROJAS' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : NO +
                          CUADRA EL TOTALES "RROJAS".  INVESTIGAR.' +
                          ' ' IN02)

             CHGVAR     VAR(&DESCRIP) VALUE('IMPORTANTE : NO CUADRA +
                          EL TOTALES "RROJAS".  INVESTIGAR. SEROJOM')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "RROJAS" CON EL FICHERO DE +
                          PGM-SEROJOM DEL IN02 +
                          FACT.ESTABLECIMIENTOS **LLAMAR A Diners +
                          Club Spain **-S-Seguir  o cancelar todo +
                          el proceso')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             CHGJOB     DATE(&FECHA1)
             ENDDO

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE EJECUTAR +
                          EL PGM-SEROJO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENROJO FICHEROS +
                          PENROJO LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)

             D1         LABEL(BBLODILG) LIB(FICHEROS)
             D1         LABEL(BLODIAEN) LIB(FICHEROS)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 22 */
 /*------------------------------------------------------------------*/
 /* A C T B L O.- ACT.BLODIAN EN ACT./DTO./COD.NOCOBRO Y FECHAS ERRO.*/
 /*------------------------------------------------------------------*/
 REA22:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  ACTBLO EN EJECUCION.' ' ' IN02)

             OVRPRTF    FILE(IMP1017) OUTQ(P12) HOLD(*YES)
             CALL       PGM(EXPLOTA/ACTBLO)
             DLTOVR     FILE(IMP1017)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 23 */
 /*------------------------------------------------------------------*/
 /* LIBRE  LIBRE   LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA23:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 24 */
 /*------------------------------------------------------------------*/
 /*   CLASIFICA BLODIAN POR N.EST/.N.SOCIO                           */
 /*------------------------------------------------------------------*/
 REA24:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM(('                             +
                          CLASIFICACION PARA EL BLODIAN') (' ') (IN02))

             D1         LABEL(BLODILG6) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/BLODILG6) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          BLODIAN SUSTITUYE AL SORT SNEGR05') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

   /* Se cambia el SORT SNEGR05 por RGZPFM*/

             RGZPFM     FILE(FICHEROS/BLODIAN) +
                          KEYFILE(FICHEROS/BLODILG6 BLODILG6)

             D1         LABEL(BLODILG6) LIB(FICHEROS)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 25 */
 /*------------------------------------------------------------------*/
 /* LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                            */
 /*------------------------------------------------------------------*/
 REA25:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 26 */
 /*------------------------------------------------------------------*/
 /* LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                            */
 /*------------------------------------------------------------------*/
 REA26:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 27 */
 /*------------------------------------------------------------------*/
 /* LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                            */
 /*------------------------------------------------------------------*/
 REA27:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 28 */
 /*------------------------------------------------------------------*/
 /* V E R B L O.- VERIFICA SI PUEDEN FACTURARSE REMESAS ROJAS  -     */
 /*------------------------------------------------------------------*/
 REA28:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  VERBLO EN EJECUCION.' ' ' IN02)

             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)
             OVRPRTF    FILE(QSYSPRT) OUTQ(PX) SAVE(*YES)
             CALL       PGM(EXPLOTA/VERBLO)
             DLTOVR IMP0017
             DLTOVR QSYSPRT

             CHGJOB     DATE(&FECHA1)

 /*------------------------------------------------*/
 /*         -CUADRE   PENROJO                      */
 /*------------------------------------------------*/
             CHGVAR     VAR(&XOTBE) VALUE(0)
             CALL       PGM(EXPLOTA/SUMAPENRO) PARM(&XOTBE)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&XOTBE 'RROJAS' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : NO +
                          CUADRA EL TOTALES "RROJAS".  INVESTIGAR.' +
                          ' ' IN02)

             CHGVAR     VAR(&DESCRIP) VALUE('IMPORTANTE : NO CUADRA +
                          EL TOTALES "RROJAS".  INVESTIGAR. VERBLO')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "RROJAS" CON EL FICHERO DE +
                          PGM-VERBLO  DEL IN02 +
                          FACT.ESTABLECIMIENTOS **LLAMAR A Diners +
                          Club Spain  **-S-Seguir  o cancelar todo +
                          el proceso')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             CHGJOB     DATE(&FECHA1)
             ENDDO


             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DEL +
                          PGM-VERBLO                     ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 29 */
 /*------------------------------------------------------------------*/
 /* LIBRE                                                            */
 /*------------------------------------------------------------------*/
 REA29:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 30 */
 /*------------------------------------------------------------------*/
 /* A P E N R O.- ACT.IMP.REMESA FACTURADA EN FICHERO PENROJO  -     */
 /*------------------------------------------------------------------*/
 REA30:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  APENRO EN EJECUCION.' ' ' IN02)

             CALL       PGM(EXPLOTA/APENRO)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 31 */
 /*------------------------------------------------------------------*/
 /*                COPIAS DE SEGURIDAD -REMESAS ROJAS-               */
 /*------------------------------------------------------------------*/
 REA31:      CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DEL +
                          PGM-APENRO                     ')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(REMEFAC FICHEROS +
                          REMEFAC LIBSEG1D M ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENROJO FICHEROS +
                          PENROJO LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(APARCA SADE +
                          APARCA LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 32 */
 /*------------------------------------------------------------------*/
 /* B P E N R O.- CREA FICHERO CON ABONOS FACT.DE UN MISMO DIA       */
 /*------------------------------------------------------------------*/
 REA32:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  BPENRO EN EJECUCION.' ' ' IN02)

             CRTPF      FILE(FICHEROS/BAPENRO) TEXT('posibles bajas +
                          de abonos del penrojo') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BAPENRO))

             CALL       PGM(EXPLOTA/BPENRO)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 33 */
 /*------------------------------------------------------------------*/
 /* B P E N R O 1.- BAJAS PENROJO ABONOS FACTURADOS MAS DE 30 DIAS   */
 /*------------------------------------------------------------------*/
 REA33:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA BPENRO1 EN EJECUCION.' ' ' IN02)

             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)
             CALL       PGM(EXPLOTA/BPENRO1)
             DLTOVR     FILE(IMP0017)

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE PGM-BPENRO1')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BAPENRO FICHEROS +
                          BAPENRO LIBSEG1D M ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENROJO FICHEROS +
                          PENROJO LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 34 */
 /*------------------------------------------------------------------*/
 /* L I R O J O.- LISTA FICHERO PENROJO, PENDIENTE REMESAS ROJAS     */
 /*------------------------------------------------------------------*/
 REA34:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA LIROJO  EN EJECUCION.' ' ' IN02)

             OVRPRTF    FILE(IMP0017) OUTQ(PX) SAVE(*YES)
             CALL       PGM(EXPLOTA/LIROJO)
             DLTOVR     FILE(IMP0017)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 35 */
 /*------------------------------------------------------------------*/
 /* CLASIFICA BLODIAN POR N.EST./DUP./DIA CON./COD.REGISTRO          */
 /*------------------------------------------------------------------*/
 REA35:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM(('                             +
                          CLASIFICACION PARA EL BLODIAN') (' ') (IN02))

   /* Se cambia el SORT SBLODIA por RGZPFM*/
             RGZPFM     FILE(FICHEROS/BLODIAN) KEYFILE(*FILE)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 36 */
 /*------------------------------------------------------------------*/
 /* A P R O R E.- ACT.PROMEDIO REMESADO ESTA1 CON MAYOR REM.NEGRA Y  */
 /*               LIMPIA CONDICION CORREO DEVUELTO SI FACTURA.       */
 /*------------------------------------------------------------------*/
 REA36:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  APRORE EN EJECUCION.' ' ' IN02)

             CALL       PGM(EXPLOTA/APRORE)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 37 */
 /*------------------------------------------------------------------*/
 /* S U M B L O.- SUMA Y RENUMERA Nº.REGISTRO EN BLODIAN             */
 /*------------------------------------------------------------------*/
 REA37:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  SUMBLO EN EJECUCION.' ' ' IN02)

             CALL       PGM(EXPLOTA/SUMBLO)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 38 */
 /*------------------------------------------------------------------*/
 /*  C H K B L O.- SUMA BLODIAN  -REMESAS/CARGOS -LISTA DIFERENCIAS- */
 /*------------------------------------------------------------------*/
 REA38:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  CHKBLO EN EJECUCION.' ' ' IN02)

             CHGVAR     VAR(&TOTCUA) VALUE(0)
             OVRPRTF    FILE(IMP0017) SAVE(*YES)
             CALL       PGM(EXPLOTA/CHKBLOM) PARM(&TOTCUA)
             DLTOVR     FILE(IMP0017)

             CALL       PGM(EXPLOTA/TRACE) PARM(' Importante: +
                          Recoger total de la impresora y no +
                          continuar si la suma de la    ' ' ' IN02)
             CALL       PGM(EXPLOTA/TRACE) PARM('DIFERENCIA no es +
                          cero.' ' ' IN02)

             IF         COND(&TOTCUA *NE 0) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('HAY DIFERENCIA NO +
                          ES CERO EN PGM-CHKBLOM- INVESTIGAR.' ' ' +
                          IN02)

             CHGVAR     VAR(&DESCRIP) VALUE('Importante:  DIFERENCIA +
                          no es cero. -CHKBLOM- INVESTIGAR''')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('LA DIFERENCIA DEL +
                          PGM-CHKBLOM- NO ES CERO IN02 +
                          FACT.ESTABLECIMIENTOS ***PARAR +
                          PARAR****LLAMAR A Diners Club +
                          Spain          **-S-Seguir  o cancelar +
                          todo el proceso')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             CHGJOB     DATE(&FECHA1)
             ENDDO

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 39 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA39:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 40 */
 /*------------------------------------------------------------------*/
 /*                   D E L E T E S  -NMOVXX-                        */
 /*------------------------------------------------------------------*/
 REA40:      CHGVAR     VAR(&DIA) VALUE(&DIA + 1)

             IF         COND(&DIA *EQ 99) THEN(GOTO CMDLBL(OTRO))
             CHGVAR     &DIAL VALUE(&DIA)
             CHGVAR     &LABEL VALUE('NMOV' *CAT &DIAL)
             CHKOBJ     OBJ(FICHEROS/&LABEL) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(REA40))
             DLTF       FILE(FICHEROS/&LABEL)

             GOTO       CMDLBL(REA40)

 /*-----------------------------------------------------*/
 /*  CREA "BLODIANxx" para PARTE DIARIO DE INCIDENCIAS  */
 /*-----------------------------------------------------*/
 OTRO:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                          Programa +
                          -BLODIACL- en ejecucion ' ' ' IN02)

             DLCOBJ     OBJ((FICHEROS/IMPORARA *DTAARA *EXCL))
             CALL       PGM(EXPLOTA/TRACE) PARM('Importante: YA SE +
                          PUEDEN CREAR NUEVOS +
                          NMOVXX                                  ' +
                          ' ' IN02)

             CALL       PGM(EXPLOTA/BLODIACL)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 41 */
 /*------------------------------------------------------------------*/
 /* LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                            */
 /*------------------------------------------------------------------*/
 REA41:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 42 */
 /*------------------------------------------------------------------*/
 /*  NACI05M: SEPARA BLOQUE DE NACIONAL E INTERNACIONAL              */
 /*------------------------------------------------------------------*/
 REA42:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  NACI05M  EN EJECUCION' ' ' IN02)

             CRTLF      FILE(FICHEROS/OPGENXDL1) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/DIN1) OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL) /* +
                          'FICHERO SALIDO DEL NACI05' */
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/DIN1))

             CRTPF      FILE(FICHEROS/DESNACI05) SRCMBR(DESCRFAC) +
                          TEXT('DESCRIPCIONES GTOS CAJEROS SALIDOS +
                          DE NACI05') OPTION(*NOLIST *NOSRC) +
                          SIZE(10000 1000) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DESNACI05))

             CRTPF      FILE(FICHEROS/ASINACI05) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFIVA) +
                          OPTION(*NOSRC *NOLIST) SIZE(100 100) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASINACI05))

             CRTPF      FILE(FICHEROS/ESNACI05) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(ESTFACVA) OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ESNACI05))

             CRTPF      FILE(FICHEROS/DETE22) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE22))

             CRTPF      FILE(FICHEROS/CABE22) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE22))

             CALL       PGM(EXPLOTA/OPADICRT) PARM('I05' 'IN02      ')

             OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASINACI05)
             OVRDBF     FILE(ESTFACVA) TOFILE(FICHEROS/ESNACI05)
             OVRDBF     FILE(DESCRCAJ) TOFILE(FICHEROS/DESNACI05)
             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)

             CHGJOB     DATE(&FECHA1)
             CHGVAR     VAR(&TOTCUB) VALUE(0)

   /*----------------------------------------------------------------*/
   /* REUNION 14/6/2022 (LETICIA, ESPERANZA,MARIANGELES, JUAN Y JLC  */
   /* DAILY DETALLE EXTRACONTABLE - COPIAS ANTES DE PROGRAMA         */
   /* TAMBIEN SE UTILIZARA PARA EVIDENCIAS-EXTRACONTABLES (NACI05M)  */
   /*----------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('IN02, COPIAS ANTES DE +
                          PGM-NACI05M (ExtraContable)')

   /*---------------------*/
   /*    AUDITORIA      */
   /*---------------------*/
             CPYF       FROMFILE(FICHEROS/BLODIAN) +
                          TOFILE(FICHEROS/BLODIAAUDI) +
                          MBROPT(*REPLACE) CRTFILE(*YES) FROMRCD(1) +
                          FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

   /*---------------------*/

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(T_MSOCIO FICHEROS +
                          T_MSOCIO LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ESTA1 FICHEROS +
                          ESTA1 LIBSEG1D C ' ' ' ' &TEX IN02)

   /*---------------------*/

             CALL       PGM(EXPLOTA/NACI05M) PARM(&TOTCUB)

             DLTOVR     FILE(ASIFIVA)
             DLTOVR     FILE(ESTFACVA)
             DLTOVR     FILE(DESCRCAJ)
             DLTOVR     FILE(IMP0017)

             CALL       PGM(EXPLOTA/OPADISAV) PARM('I05'   +
                          'IN02      ' 'IN02      ')
             CHGJOB     DATE(&FECHA1)
/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETE22) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE22) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('IN02,     DESPUES DEL +
                          PGM-NACI05')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE22 FICHEROS +
                          DETE22 LIBSEG1D M ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE22 FICHEROS +
                          CABE22 LIBSEG1D M ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 43 */
 /*------------------------------------------------------------------*/
 /*        COPIAS DE SEGURIDAD -DESPUES DE RPG.NACI05-               */
 /*------------------------------------------------------------------*/
 REA43:      CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE EJECUTAR +
                          PGM-NACI05')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINACI05 +
                          FICHEROS ASINACI05 LIBSEG1D C ' ' ' ' +
                          &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ESNACI05 FICHEROS +
                          ESNACI05 LIBSEG1D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DESNACI05 +
                          FICHEROS DESNACI05 LIBSEG1D M ' ' ' ' +
                          &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DIN1 FICHEROS +
                          DIN1 LIBSEG30D C ' ' ' ' &TEX IN02)
 /*------------------------------------------------------------------*/
 /* APG2 ** AÑADIR DIN1REJ  CON RECAPS A REINYECTGAR POR RECHAZO     */
 /*------------------------------------------------------------------*/
             CPYF       FROMFILE(FICHEROS/DIN1REJ) +
                          TOFILE(FICHEROS/DIN1) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('DIN1 TRAS COPIAR DIN1REJ  A +
                          DIN1-APG1 ')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DIN1 FICHEROS +
                          DIN1 LIBSEG30D C ' ' ' ' &TEX IN02)

             CLRPFM     FILE(FICHEROS/DIN1REJ) /* * BORRAR FICHERO +
                          DIN1REJ DESPUES DE REINYECTAR RECAPS +
                          RECHAZADAS ANTERIORMENTE PARA QUE NO SE +
                          REPITA CADA DIA* */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 46 */
     /* ---------------------------------------------------------*/
     /* PARTE MASTERCARD                                         */
     /* ASIENTO Y EVIDENCIAS CONTABLES DE ENTRADA DE OPERACIONES */
     /* EVIDENCIAS CONTABLES SE COPIA EN EL PROGRAMA             */
     /* ---------------------------------------------------------*/

             CALL PGM(MC00004CL) PARM(('IN02'))

             CHGJOB     DATE(&FECHA1)
 SIG:        CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 44 */
 /*------------------------------------------------------------------*/
 /*                     L I S D I 0 1                                */
 /*------------------------------------------------------------------*/
 REA44:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA LISDI01 EN +
                          EJECUCION                    ' ' ' IN02)

             CHGJOB     SWS(0XXXXXXX)
             OVRPRTF    FILE(IMP0017) PAGESIZE(88) LPI(8) OVRFLW(88)

             CRTPF      FILE(FICHEROS/FIDINERS) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FIDINERS))

             CHGVAR     &LABMIC  ('MICDIN' || &MES)

             CRTPF      FILE(FICHEROS/&LABMIC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(MICDIN) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CHGVAR     &LABDIN  ('DINERS' || &MES)
             CHGVAR     &LOGDIN  ('LGDIN'  || &MES)

             CRTPF      FILE(FICHEROS/&LABDIN) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DSPDINER) OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOLOGI))

             CRTLF      FILE(FICHEROS/&LOGDIN) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(&LOGDIN) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)

NOLOGI:      OVRDBF     FILE(DINERS) TOFILE(&LABDIN)
             OVRDBF     FILE(MICDIN) TOFILE(&LABMIC)

             CALL       PGM(PRINDDIN) PARM(&MES)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/LISDI01)

             DLTOVR     FILE(MICDIN)
             DLTOVR     FILE(IMP0017)
             DLTOVR     FILE(DINERS)

             CHGJOB     DATE(&FECHA1)
             CRTPF      FILE(FICHEROS/DIN1DES) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DESCRFAC) TEXT('descripciones +
                          -din1-') OPTION(*NOSRC *NOLIST) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DIN1DES))

             CALL       PGM(EXPLOTA/DESDIN1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 45 */
 /*------------------------------------------------------------------*/
 /*        COPIAS DE SEGURIDAD -DESPUES DE RPG.LISDI01-              */
 /*------------------------------------------------------------------*/
 REA45:      CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE EJECUTAR +
                          PGM-LISDI01')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DIN1 FICHEROS +
                          DIN1 LIBSEG30D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&LABDIN FICHEROS +
                          &LABDIN LIBSEG30D C ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&LABMIC FICHEROS +
                          &LABMIC LIBSEG30D C ' ' ' ' &TEX IN02)

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE EJECUTAR +
                          PGM-DESDIN1')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DIN1DES FICHEROS +
                          DIN1DES LIBSEG1D M ' ' ' ' &TEX IN02)

             CPYF       FROMFILE(FICHEROS/DIN1) +
                          TOFILE(GAMMA/DIN1GAMMA) MBROPT(*REPLACE) +
                          CRTFILE(*NO) FROMRCD(1) FMTOPT(*NOCHK) /* +
                          PARA ATSISTEMAS */

             CHGVAR     VAR(&SQL) VALUE('UPDATE GAMMA/DIN1GAMMA +
                          SET FPROCES = ' || &FECHA1)

             RUNSQL     SQL(&SQL) COMMIT(*NC)

             CPYF       FROMFILE(GAMMA/DIN1GAMMA) TOFILE(GAMMA/DIN1) +
                          MBROPT(*ADD) CRTFILE(*NO) FROMRCD(1) +
                          FMTOPT(*NOCHK) /* PARA ATSISTEMAS */
             MONMSG     MSGID(CPF0000)

 /*---------------------------------------------------*/
 /* ELIMINAR DE DIN1 REGISTROS YA ENVIADOS DCI (APG1) */
 /*---------------------------------------------------*/
             CALL       PGM(EXPLOTA/IBER014R)

             CHGJOB     DATE(&FECHA1)

 /*------------------------------------------------------------------*/
 /*                      D I N C I N                                 */
 /*------------------------------------------------------------------*/
 REA46:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA DINCIN  EN EJECUCION ' ' ' IN02)

             CRTPF      FILE(FICHEROS/CINTA2) RCDLEN(380) +
                          TEXT('Facturacion para DCISC') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          FRCRATIO(1) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CINTA2))

             CALL       PGM(EXPLOTA/OPADICRT) PARM('CIN' 'IN02      ')

             OVRDBF     FILE(OPGENXD) TOFILE(OPGENXDCIN)
             OVRPRTF    FILE(PRTMSG) OUTQ(P12)
             MONMSG     MSGID(CPF0000)
             CHGJOB     DATE(&FECHA1)

 /*                      D I N C I N - DATOS DE PRUEBA VOXEL         */
 /*          CALL       PGM(EXPLOTA/VOXELPRUCL)                      */

             CALL       PGM(EXPLOTA/DINCIN)

             DLTOVR     FILE(QSYSPRT)
             MONMSG     MSGID(CPF0000)

             DLTOVR     FILE(OPGENXD)
             MONMSG     MSGID(CPF0000)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/OPADISAV) PARM('CIN'   +
                          'IN02      ' 'IN02      ')

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 47 */
 /*------------------------------------------------------------------*/
 /*                   CREO LOGICOS                                   */
 /*------------------------------------------------------------------*/
 REA47:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          CREACION LOGICOS EN EJECUCION ' ' ' IN02)

             CRTLF      FILE(FICHEROS/PAISESLG) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PAISESLGA) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/TABACLG1) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 48 */
 /*------------------------------------------------------------------*/
 /*                       SALVAR FICHEROS                            */
 /*------------------------------------------------------------------*/
 REA48:      CHGVAR     VAR(&LABDIN) VALUE('DINLO2' *CAT +
                          (%SUBSTRING(&FECHA1 1 4)))

             RNMOBJ     OBJ(FICHEROS/CINTA2) OBJTYPE(*FILE) +
                          NEWOBJ(&LABDIN)

             CHGVAR     VAR(&TEX) VALUE('IN02, DINERS PARA ENVIO A +
                          DCISC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&LABDIN FICHEROS +
                          &LABDIN LIBSEG30D C ' ' ' ' &TEX IN02)

             CHGVAR     VAR(&LABDIN) VALUE('FIDIN' *CAT +
                          (%SUBSTRING(&FECHA1 1 4)))

             RNMOBJ     OBJ(FICHEROS/FIDINERS) OBJTYPE(*FILE) +
                          NEWOBJ(&LABDIN)

             CHGVAR     VAR(&TEX) VALUE('IN02, DINERS DIARIO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&LABDIN FICHEROS +
                          &LABDIN LIBSEG30D M ' ' ' ' &TEX IN02)

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE ACTUALIZAR +
                          EN FACT.ESTB.')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM((PAISESA) +
                          (FICHEROS) (PAISES) (LIBSEG1D) (C) (' ') +
                          (' ') (&TEX) (IN02))

             DLTF       FILE(FICHEROS/DIN1)
             D1         LABEL(CINTA2) LIB(FICHEROS)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 49 */
 /*------------------------------------------------------------------*/
 /*  PROCESO OPERACIONES DE TARJETAS VIRTUALES (Nacional/Internac.)  */
 /*------------------------------------------------------------------*/
 REA49:      CALL       PGM(EXPLOTA/VIRTUALESM) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 50 */
 /*------------------------------------------------------------------*/
 /*                        N A C 0 8 C                               */
 /*------------------------------------------------------------------*/
 REA50:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  NAC08C  EN EJECUCION ' ' ' IN02)

             CRTPF      FILE(FICHEROS/BLONORMA) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(BLONORMA) TEXT('BLONORMA - BLOQUE +
                          DIARIO DE NORMAL') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BLONORMA))

             CRTPF      FILE(FICHEROS/DESNAC08C) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DESCRFAC) TEXT('descripciones gtos +
                          cajeros salido del NAC08C') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DESNAC08C))

             CRTPF      FILE(FICHEROS/ASINAC08C) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFIVA) +
                          OPTION(*NOSRC *NOLIST) SIZE(100 100) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASINAC08C))

             CRTPF      FILE(FICHEROS/BLONAC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BLONAC) +
                          TEXT('Blonac Diario,sino hay errores se +
                          acumula a blonac') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/BLONAC))

       /*CREAMOS FICHERO EN VACIO HASTA QUE SE CAMBIE NAC08C*/
       /*---------------------------------------------------*/
             CRTPF      FILE(FICHEROS/CONTRO08) TEXT('REMESAS CON +
                          NOTAS AL COBRO') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTRO08))

             CRTPF      FILE(FICHEROS/PENCOM08) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(PENCOMES) TEXT('Anexos +
                          establecimientos -rpg.nac08c-') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/PENCOM08))

             CALL       PGM(EXPLOTA/OPADICRT) PARM('08C' 'IN02      ')

             OVRDBF     FILE(DESCRCAJ) TOFILE(FICHEROS/DESNAC08C)
             OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASINAC08C)
             OVRDBF     FILE(BLONACD) TOFILE(FICHEROS/BLONAC)
             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)

             CHGJOB     DATE(&FECHA1)

   /*----------------------------------------------------------------*/
   /* REUNION 14/6/2022 (LETICIA, ESPERANZA,MARIANGELES, JUAN Y JLC  */
   /* DAILY DETALLE EXTRACONTABLE - COPIAS ANTES DE PROGRAMA         */
   /*----------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('IN02, COPIAS ANTES DE +
                          PGM-NAC08C (ExtraContable)')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CTLPROCES +
                          FICHEROS CTLPROCES LIBSEG1D C ' ' ' ' +
                          &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTRO08 FICHEROS +
                          CONTRO08 LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(T_MSOCIO FICHEROS +
                          T_MSOCIO LIBSEG1D C ' ' ' ' &TEX IN02)

   /*--------------------------------------------------------------*/
   /*--  HISTORICOS PARA CONTABILIDAD: BLODIAN A BLODIAN_HI    --*/
   /*--  01.07.2022 DETALLE OPERACIONES CONTABILIZADAS (NAV)   --*/
   /*--------------------------------------------------------------*/

             CPYF       FROMFILE(FICHEROS/BLODIAN) +
                          TOFILE(FICHEROS/BLODIAN_HI) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

   /*----------------------------------------------------------------*/

             CALL       PGM(EXPLOTA/NAC08C)

  /* DATOS AMPLIADOS OPERACIONES */
             CALL       PGM(EXPLOTA/OPE_AMP)

             DLTOVR     FILE(DESCRCAJ)
             DLTOVR     FILE(ASIFIVA)
             DLTOVR     FILE(BLONACD)
             DLTOVR     FILE(IMP0017)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/OPADISAV) PARM('08C' 'IN02      +
                          ' 'IN02      ')

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 51 */
 /*------------------------------------------------------------------*/
 /*- ADICION DIARIA: PENCOM08 a fichero PENCOMES                     */
 /*------------------------------------------------------------------*/
 REA51:      CPYF       FROMFILE(FICHEROS/PENCOM08) +
                          TOFILE(FICHEROS/PENCOMES) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 52 */
 /*------------------------------------------------------------------*/
 /*- REGISTROS GASTOS CAJEROS PARA ACUMULAR A MSOCIO -SERVICIOS-     */
 /*  RENAME -GTOSCAJE- A -GTOSCAXX- PARA INF.EN P.INCIDENCIAS        */
 /*------------------------------------------------------------------*/
 REA52:      CRTPF      FILE(FICHEROS/GTOSCAJE) RCDLEN(160) +
                          TEXT('REGISTROS -GASTOS CAJEROS-') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/GTOSCAJE))

             CPYF       FROMFILE(FICHEROS/BLONAC) +
                          TOFILE(FICHEROS/GTOSCAJE) MBROPT(*ADD) +
                          FROMRCD(1) INCCHAR(*RCD 112 *EQ 4) +
                          FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)


             CALL       PGM(EXPLOTA/GTOSCACL)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 53 */
 /*------------------------------------------------------------------*/
 /*            COPIAS DE SEGURIDAD, DESPUES DE RPG.NAC08C            */
 /*------------------------------------------------------------------*/
 REA53:      CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE PGM-NAC08C')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINAC08C +
                          FICHEROS ASINAC08C LIBSEG1D C ' ' ' ' +
                          &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DESNAC08C +
                          FICHEROS DESNAC08C LIBSEG1D M ' ' ' ' +
                          &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLONORMA FICHEROS +
                          BLONORMA LIBSEG1D C ' ' ' ' &TEX IN02)

   /*---------------------*/
   /*    AUDITORIA      */
   /*---------------------*/
             CPYF       FROMFILE(FICHEROS/BLONORMA) +
                          TOFILE(FICHEROS/BLONORAUDI) +
                          MBROPT(*REPLACE) CRTFILE(*YES) FROMRCD(1) +
                          FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

   /*---------------------*/

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCOM08 FICHEROS +
                          PENCOM08 LIBSEG1D M ' ' ' ' &TEX IN02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLODIAN FICHEROS +
                          BLODIAN LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DEL +
                          PGM-NAC08C Y ADD BLODIAN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLONAC FICHEROS +
                          BLONAC LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 54 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA54:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 55 */
 /*------------------------------------------------------------------*/
 /* SE BORRA FICHERO -PROPA- PARA REALIZAR "PARTE DE INCIDENCIAS"    */
 /*------------------------------------------------------------------*/
 REA55:      CALL       PGM(PRFICCTL) PARM('B' 'PROPA     ')


             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR +
                          PGM-NUMREF')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTRO08 FICHEROS +
                          CONTRO08 LIBSEG1D M ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 56 */
 /*------------------------------------------------------------------*/
 /*   CLASIFICA FICHERO SPENEST                                      */
 /*------------------------------------------------------------------*/
 REA56:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM(('                             +
                          CLASIFICACION PARA EL SPENEST') (' ') (IN02))

 /*-----------------------------------------*/
 /* ANEXO:  CONCILIACION -MARSANS/MICHELIN- */
 /*-----------------------------------------*/
             CHKOBJ     OBJ(FICHEROS/PENCOMIC) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOMICHE))

             CPYF       FROMFILE(FICHEROS/PENCOMIC) +
                          TOFILE(FICHEROS/PENCOMES) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

             CHGVAR     VAR(&TEX) VALUE('IN02, PENCOMIC EN EUROS +
                          -MICHELIN-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCOMIC FICHEROS +
                          PENCOMIC LIBSEG1D M ' ' ' ' &TEX IN02)

 /*-----------------------------------------*/

 NOMICHE:    CHGVAR     VAR(&TEX) VALUE('IN02, PENCOMES ANTES DE +
                          RPG.CVTSPEN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCOMES FICHEROS +
                          PENCOMES LIBSEG1D C ' ' ' ' &TEX IN02)

             CRTPF      FILE(FICHEROS/SPENEST) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('--in02--') SIZE(*NOMAX) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SPENEST))

   /*Se cambia el SORT SEST05C por un CPYF con DDS ordenadas */
             CPYF       FROMFILE(FICHEROS/PENCOMES) +
                          TOFILE(FICHEROS/SPENEST) +
                          MBROPT(*ADD) FMTOPT(*NOCHK)

   /* *DAVID: CONVERTIR SPENEST  ******************************** */
   /*-------------------------------------------------------------*/

             CRTPF      FILE(FICHEROS/SPENESTCV) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(SPENEST) +
                          TEXT('--in02--') SIZE(*NOMAX) LVLCHK(*NO) +
                          AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SPENESTCV))

             CALL       PGM(EXPLOTA/CVTSPEN)

             CHGVAR     VAR(&TEX) VALUE('IN02, SPENEST antes de +
                          -ACUCOBR-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SPENEST FICHEROS +
                          SPENEST LIBSEG1D M ' ' ' ' &TEX IN02)
             RNMOBJ     OBJ(FICHEROS/SPENESTCV) OBJTYPE(*FILE) +
                          NEWOBJ(SPENEST)

   /* *DAVID: FIN CONVERTIR SPENEST  **************************** */
   /*-------------------------------------------------------------*/

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 57 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA57:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 58 */
 /*------------------------------------------------------------------*/
 /*  LIBRE   LIBRE  LIBRE  LIBRE  LIBRE ...                          */
 /*------------------------------------------------------------------*/
 REA58:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 59 */
 /*------------------------------------------------------------------*/
 /*  LIBRE   LIBRE  LIBRE  LIBRE  LIBRE ...                          */
 /*------------------------------------------------------------------*/
 REA59:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 60 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA60:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 61 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA61:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 62 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA62:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 63 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA63:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 64 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA64:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 65 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA65:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 66 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA66:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 67 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA67:

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 68 */
 /*------------------------------------------------------------------*/
 /*  COPIA DE FICHERO PENCOMES A FICHERO PENESTNO                    */
 /* Se cambia el SORT SESTB15 POR LA CREACION DEL FICHERO PENESTNO   */
 /*------------------------------------------------------------------*/
 REA68:
             CRTPF      FILE(FICHEROS/PENESTNO) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('Creado en +
                          IN02') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PENESTNO))

             CPYF       FROMFILE(FICHEROS/PENCOMES) +
                          TOFILE(FICHEROS/PENESTNO) +
                          MBROPT(*ADD) FMTOPT(*NOCHK)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 69 */
 /*------------------------------------------------------------------*/
 /*           PROGRAMA  ESTB05M (NORMAL)                            */
 /*------------------------------------------------------------------*/
 REA69:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                     PROGRAMA +
                          ESTB05 EN EJECUCION' ' ' IN02)

             CRTPF      FILE(FICHEROS/ACUNOR) RCDLEN(153) +
                          TEXT('acumulacion de establec. normal +
                          salido del  estb05') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ACUNOR))

             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)

             CALL       PGM(EXPLOTA/ESTB05M) PARM(&XDIFZ)

             DLTOVR     FILE(IMP0017)

             CHGJOB     DATE(&FECHA1)
             IF         COND(&XDIFZ *NE 0 ) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('ESTB05 hay diferecias  +
                          entre las remesas y los cargos. IN02 PARA +
                          PARA')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)


             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: El programa +
                          ESTB05 hay diferencias entre Remesas y +
                          Socios -Facturacion Establecimientos   +
                          IN02  **LLAMAR A Diners Club Spain  +
                          **-S-Seguir  o cancelar todo el proceso')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             CHGJOB     DATE(&FECHA1)
             ENDDO

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE EJECUTAR +
                          PGM-ESTB05')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ACUNOR FICHEROS +
                          ACUNOR LIBSEG1D C ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENESTNO FICHEROS +
                          PENESTNO LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 70 */
 /*------------------------------------------------------------------*/
 /*           PROGRAMA  SELENPE  (NORMAL)                            */
 /*------------------------------------------------------------------*/
 REA70:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                      PROGRAMA +
                          SELENPE EN EJECUCION' ' ' IN02)

             CRTPF      FILE(FICHEROS/ACUNOSAL) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BE1) +
                          TEXT('facturacion pendiente de facturar') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ACUNOSAL))

             CRTPF      FILE(FICHEROS/BENOFAC) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('ESTABLEC. +
                          NORMAL SALIDO DEL  SELENPE PARA FACTUR') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BENOFAC))

             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)

             CALL       PGM(EXPLOTA/SELENPE)

             DLTOVR     FILE(IMP0017)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 71 */
 /*------------------------------------------------------------------*/
 /*           PROGRAMA  NORCOFAC  (COBRO/NORMAL)                    */
 /*------------------------------------------------------------------*/
 REA71:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                      PROGRAMA +
                          NORCOFAC EN EJECUCION' ' ' IN02)

             CRTPF      FILE(FICHEROS/ASINORCOFA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFIVA) +
                          OPTION(*NOSRC *NOLIST) SIZE(100 100) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASINORCOFA))

             CRTPF      FILE(FICHEROS/DETE41) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE41))

             CRTPF      FILE(FICHEROS/CABE41) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE41))

             OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASINORCOFA)

             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)

             CALL       PGM(EXPLOTA/NORCOFAC)

             DLTOVR     FILE(IMP0017)

             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR +
                          PGM-NORCOFAC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINORCOFA +
                          FICHEROS ASINORCOFA LIBSEG1D C ' ' ' ' +
                          &TEX IN02)

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETE41) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE41) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE41 FICHEROS +
                          DETE41 LIBSEG1D M ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE41 FICHEROS +
                          CABE41 LIBSEG1D M ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 72 */
 /*------------------------------------------------------------------*/
 /*            PROGRAMA  NORCOPEN  (COBRO/NORMAL)                    */
 /*------------------------------------------------------------------*/
 REA72:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                      PROGRAMA +
                          NORCOPEN EN EJECUCION' ' ' IN02)

             CRTPF      FILE(FICHEROS/DETE42) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE42))

             CRTPF      FILE(FICHEROS/CABE42) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE42))

             OVRPRTF    FILE(IMP0017) OUTQ(P12) HOLD(*YES) SAVE(*YES)

             CALL       PGM(EXPLOTA/NORCOPEN)

             DLTOVR     FILE(IMP0017)

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */
             CPYF       FROMFILE(FICHEROS/DETE42) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE42) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR +
                          PGM-NORCOPEN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE42 FICHEROS +
                          DETE42 LIBSEG1D M ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE42 FICHEROS +
                          CABE42 LIBSEG1D M ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 73 */
 /*------------------------------------------------------------------*/
 /* DELETES Y RENAMES DE ACUMULADO NORMAL Y COBRO                    */
 /*------------------------------------------------------------------*/
 REA73:      CALL       PGM(EXPLOTA/TRACE) PARM('COMPRUEBA SI ESTA +
                          ALOCATADO EL BE                    ' ' ' +
                          'IN02')

 ALOC:       ALCOBJ     OBJ((FICHEROS/BE *FILE *EXCL *N)) WAIT(5)
             MONMSG     CPF0000 *NONE EXEC(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('El fichero --BE-- +
                          esta alocatado por otro trabajo.' ' ' IN02)

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(BE *FILE +
                          FICHEROS &MSG &BLOQUEA)

             DLYJOB     DLY(30)

     /*SI HABIA BLOQUEADOS VUELVE A COMPROBAR */
             IF         COND(&BLOQUEA *EQ 'B') THEN(DO)
             GOTO       ALOC
             ENDDO

             ENDDO
             DLCOBJ     OBJ((FICHEROS/BE *FILE *EXCL *N))

             D1         LABEL(BE)       LIB(FICHEROS)

             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR +
                          PGM-NORCOFAC')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BENOFAC FICHEROS +
                          BENOFAC LIBSEG1D C ' ' ' ' &TEX IN02)

   /*---------------------*/
   /*    AUDITORIA      */
   /*---------------------*/
             CPYF       FROMFILE(FICHEROS/BENOFAC) +
                          TOFILE(FICHEROS/BENOFAAUDI) +
                          MBROPT(*REPLACE) CRTFILE(*YES) FROMRCD(1) +
                          FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

   /*---------------------*/

             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR +
                          PGM-SELENPE')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ACUNOSAL FICHEROS +
                          ACUNOSAL LIBSEG1D C ' ' ' ' &TEX IN02)
             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR +
                          PGM-SELENPE')

 /*----------------------------------------------*/
 /* RENOMBRAR ACUNOSAL A BE                      */
 /*----------------------------------------------*/
             RNMOBJ     OBJ(FICHEROS/ACUNOSAL) OBJTYPE(*FILE) +
                          NEWOBJ(BE)

 /*----------------------------------------------*/
 /* CUADRES DE FICHEROS                          */
 /*----------------------------------------------*/
             CHGVAR     VAR(&XOTBE) VALUE(0)
             CALL       PGM(EXPLOTA/SUMABE) PARM(&XOTBE)

             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&XOTBE 'BE0000' '1' +
                          'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : NO +
                          CUADRA EL TOTALES "BE0000".  +
                          INVESTIGAR.-NORCOPEN  -IN02' ' ' IN02)

             CHGVAR     VAR(&DESCRIP) VALUE('IMPORTANTE : NO CUADRA +
                          EL TOTALES "BE0000".  INVESTIGAR. NORCOPEN')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "BE0000" DEL PGM-NORCOPEN DEL +
                          IN02 FACT.ESTABLECIMIENTOS **LLAMAR A +
                          Diners Club Spain     **-S-Seguir  o +
                          cancelar todo el proceso')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             CHGJOB     DATE(&FECHA1)
             ENDDO

             CHGVAR     VAR(&TEX) VALUE('IN02, DESPUES DE PGM-NORCOPEN')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BE FICHEROS BE +
                          LIBSEG1D C ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 74 */
 /********************************************************************/
 /** ============================================================ **/
 /**                                                              **/
 /**    FACTURACION DE ESTABLECIMIENTOS NORMAL 2ª PARTE (EN01M)   **/
 /**                                                              **/
 /** ============================================================ **/
 /********************************************************************/
 REA74:      CALL       PGM(EXPLOTA/EN01M) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 75 */
 /*------------------------------------------------------------------*/
 /*     ACUMULACION ASIENTOS AL ASIFILE  --PROGRAMA ASICO2--         */
 /*------------------------------------------------------------------*/
 REA75:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  ASICO2 EN EJECUCION  ' ' ' IN02)

             CRTPF      FILE(FICHEROS/ASIFAEST) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          OPTION(*NOLIST *NOSRC) SIZE(100 100) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAEST)
             OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASINACI05)
             CALL       PGM(EXPLOTA/ASICO2)
             DLTOVR     FILE(ASIFILE)
             DLTOVR     FILE(ASIFIVA)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAEST)
             OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASISTA10)
             CALL       PGM(EXPLOTA/ASICO2)
             DLTOVR     FILE(ASIFILE)
             DLTOVR     FILE(ASIFIVA)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 76 */
 /*------------------------------------------------------------------*/
 REA76:      OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASINAC08C)
             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAEST)

             CALL       PGM(EXPLOTA/ASICO2)

             DLTOVR     FILE(ASIFIVA)
             DLTOVR     FILE(ASIFILE)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 77 */
 /*------------------------------------------------------------------*/
 REA77:      OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASINORCOFA)
             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAEST)

             CALL       PGM(EXPLOTA/ASICO2)

             DLTOVR     FILE(ASIFIVA)
             DLTOVR     FILE(ASIFILE)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 78 */
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA78:
             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 79 */
 /*------------------------------------------------------------------*/
 REA79:      CHKOBJ     OBJ(FICHEROS/ASIVIRT2) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOASIVIRT2))

             OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASIVIRT2)
             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAEST)

             CALL       PGM(EXPLOTA/ASICO2)

             DLTOVR     FILE(ASIFILE)
             DLTOVR     FILE(ASIFIVA)

             CHGJOB     DATE(&FECHA1)
 NOASIVIRT2: CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 80 */
 /*------------------------------------------------------------------*/
 REA80:      CHKOBJ     OBJ(FICHEROS/ASIVIR22) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOASIVIR22))

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAEST)
             OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASIVIR22)

             CALL       PGM(EXPLOTA/ASICO2)

             DLTOVR     FILE(ASIFILE)
             DLTOVR     FILE(ASIFIVA)

             CHGJOB     DATE(&FECHA1)
 NOASIVIR22: CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 81 */
 /*------------------------------------------------------------------*/
 REA81:
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 82 */
 /*------------------------------------------------------------------*/
 REA82:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA ACASBO  EN EJECUCION  ' ' ' IN02)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAEST)
             CALL       PGM(EXPLOTA/ACASBO) PARM('001')
             DLTOVR     FILE(ASIFILE)

             CALL       PGM(EXPLOTA/TRACE) PARM('Comprobar que se +
                          han acumulado al totales los asientos de +
                          la fac.estab.' ' ' IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 83 */
 /*------------------------------------------------------------------*/
 REA83:      CALL       PGM(EXPLOTA/TRACE) PARM('Se mueve a la +
                          libreria de seguridad: Ficheros Parciales +
                          de Asientos           ' ' ' IN02)

             CHGVAR     VAR(&TEX) VALUE('IN02, PARCIAL DE LOS +
                          ASIENTOS FACT.ESTB.')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASISTA10 +
                          FICHEROS ASISTA10 LIBSEG1D M ' ' ' ' +
                          &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINACI05 +
                          FICHEROS ASINACI05 LIBSEG1D M ' ' ' ' +
                          &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINAC08C +
                          FICHEROS ASINAC08C LIBSEG1D M ' ' ' ' +
                          &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASINORCOFA +
                          FICHEROS ASINORCOFA LIBSEG1D M ' ' ' ' +
                          &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIVIRT2 FICHEROS +
                          ASIVIRT2 LIBSEG1D M ' ' ' ' &TEX IN02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASICXADDNE +
                          FICHEROS ASICXADDNE LIBSEG1D M ' ' ' ' +
                          &TEX IN02)
 /*---*/
             CHKOBJ     OBJ(FICHEROS/ASIVIR22) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOASIVI222))

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIVIR22 FICHEROS +
                          ASIVIR22 LIBSEG1D M ' ' ' ' &TEX IN02)
 /*---*/
 NOASIVI222: CHGVAR     VAR(&TEX) VALUE('IN02,AGRUPA TODOS LOS +
                          ASIENTOS FAC.ESTB.')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIFAEST FICHEROS +
                          ASIFAEST LIBSEG1D M ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 84 */
 /*------------------------------------------------------------------*/
 /* ESTAF2: ACUMULACION DATOS ESTADITICOS AL ESTFACME y ESTFACGN     */
 /*------------------------------------------------------------------*/
 REA84:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  ESTAF2 EN EJECUCION  ' ' ' IN02)

             CHGVAR     &REST1 VALUE('ESTFACME' *CAT +
                        (%SUBSTRING(&FECHA1 3 2)))
             CHGVAR     &REST2 VALUE('ESTFACGN' *CAT +
                        (%SUBSTRING(&FECHA1 3 2)))


             OVRDBF     FILE(ESTFACME) TOFILE(FICHEROS/&REST1)
             OVRDBF     FILE(ESTFACGN) TOFILE(FICHEROS/&REST2)
             OVRDBF     FILE(ESTFACVA) TOFILE(FICHEROS/ESNACI05)

             CALL       PGM(EXPLOTA/ESTAF2) PARM('NACI05')

             DLTOVR     FILE(ESTFACME)
             DLTOVR     FILE(ESTFACGN)
             DLTOVR     FILE(ESTFACVA)

             CHGVAR     VAR(&TEX) VALUE('IN02,DESPUES DE EJECUTAR +
                          PGM-ESTAF2')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&REST1 FICHEROS +
                          &REST1 LIBSEG1D C ' ' ' ' &TEX IN02) /* +
                          ESTFACMEmm */
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(&REST2 FICHEROS +
                          &REST2 LIBSEG1D C ' ' ' ' &TEX IN02) /* +
                          ESTFACGNmm */
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ESNACI05 FICHEROS +
                          ESNACI05 LIBSEG1D M ' ' ' ' &TEX IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 85 */
 /*------------------------------------------------------------------*/
 /* ESTAF6M: CUADRE DIARIO DE ESTADISTICAS                           */
 /*------------------------------------------------------------------*/
 REA85:      CALL       PGM(EXPLOTA/ESTAF6CLM) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 86 */
 /*------------------------------------------------------------------*/
 /*                D E L E T E   D E   F I C H E R O S               */
 /*------------------------------------------------------------------*/
 REA86:
             D1         LABEL(ASINACI05)  LIB(FICHEROS)
             D1         LABEL(ASINAC08C)  LIB(FICHEROS)
             D1         LABEL(ASINORCOFA) LIB(FICHEROS)
             D1         LABEL(ASIVIRT2)   LIB(FICHEROS)
             D1         LABEL(ASIVIR22)   LIB(FICHEROS)
             D1         LABEL(ASICXADDNE) LIB(FICHEROS)
             D1         LABEL(ASIFAEST)   LIB(FICHEROS)
             D1         LABEL(ESNACI05)   LIB(FICHEROS)
             D1         LABEL(BENOFALG)   LIB(FICHEROS)
             D1         LABEL(BENOFAC)    LIB(FICHEROS)
             D1         LABEL(BEFAC)      LIB(FICHEROS)
             D1         LABEL(CHEPEN)     LIB(FICHEROS)
             D1         LABEL(BLONORMA)   LIB(FICHEROS)
             D1         LABEL(PENCOMES)   LIB(FICHEROS)
             D1         LABEL(PENESPEN)   LIB(FICHEROS)
             D1         LABEL(PENESTCO)   LIB(FICHEROS)
             D1         LABEL(PENESTNO)   LIB(FICHEROS)
             D1         LABEL(SPENEST)    LIB(FICHEROS)
             D1         LABEL(ACUNOR)     LIB(FICHEROS)
             D1         LABEL(DUPFACES)   LIB(FICHEROS)
             D1         LABEL(BLODILG3)   LIB(FICHEROS)
             D1         LABEL(BLODIAN)    LIB(FICHEROS)
             D1         LABEL(GTOSCAJE)   LIB(FICHEROS)

             CHGVAR     VAR(&ORDEN) VALUE('GORDO')
             CALL       PGM(EXPLOTA/CTLMAT) PARM('23' &ORDEN)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 87 */
 /*------------------------------------------------------------------*/
 /*     DESPACHO RIESGOS -APARCA-    DEPARTAMENTO FACTURACION        */
 /*------------------------------------------------------------------*/
 REA87:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                            +
                          PROGRAMA -DERIAP- EN EJECUCION  ' ' ' IN02)

             CRTLF      FILE(SADE/APARLG5) OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

 /*-------------------------------------------------------*/
 /*  04-02-16 RECIBIDO MAIL DE DEPARTAMENTO FACTURACION   */
 /*  SE PUEDE ELIMINAR EL ENVIO DEL IMP00P9 POR NO SER    */
 /*  NECESARIOS.                                          */
 /*-------------------------------------------------------*/
             OVRPRTF    FILE(IMP00P9) OUTQ(P9) HOLD(*YES) SAVE(*YES)
             CALL       PGM(EXPLOTA/DERIAP)
             D1         LABEL(APARLG5) LIB(SADE)
             DLTOVR     FILE(IMP00P9)

             CALL       PGM(EXPLOTA/TRACE) PARM('** DESPACHO +
                          RIESGOS, recoger de impresora -p5- y +
                          dejar en Dep. Facturacion **' ' ' IN02)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 88 */
 /*------------------------------------------------------------------*/
 /*              ACMULACION DEL BLONAC AL PA                         */
 /*------------------------------------------------------------------*/
 REA88:      CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -ACUPACL- +
                          EN EJECUCION  ' ' ' IN02)

             CALL       PGM(EXPLOTA/ACUPACLM) PARM(&FECHA1)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 89 */
 /*------------------------------------------------------------------*/
 /*  TARJETA DUAL: DESDE BLONAC/BLOQINTE/PENCOMSODS SE CREA PAPREDS  */
 /*                PARA ACUMULAR A -PADSHIS-.                        */
 /*------------------------------------------------------------------*/
 REA89:      CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                          PROGRAMA +
                          -ACUPADSCL- EN EJECUCION  ' ' ' IN02)

 /*------------------------------------------------------------*/
 /* SE ASTERISCA DESCATALOGADO (T.DUAL)- C.A.U. 2019031204 -   */
 /*------------------------------------------------------------*/
     /*    CALL       PGM(EXPLOTA/ACUPADSCLM) PARM(&FECHA1)  */

 /*------------------------------------------------------------*/
 /* DATA WAREHOUSE + ENVIO FICHEROS DIARIOS A SERVIDOR         */
 /*------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('       +
                          -DATAWAREHOUSE- Envio de ficheros Diarios +
                          a Servidor        ' ' ' IN02)

             CALL       PGM(EXPLOTA/DTWCL) PARM(&FECHA1)
             CHGJOB     DATE(&FECHA1)
 /*------------------------------------------------------------*/
 /* CUADRE IN02M - SUMO FICHEROS SALIDA DEL PROCESO DIARIO   */
 /*------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  +
                          ADDNACMCL   EN EJECUCION' ' ' IN02)

             CALL       PGM(EXPLOTA/ADDNACMCL)

             CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 90 */
 /*------------------------------------------------------------------*/
 /*       CARGAR CABECERA Y TOTALES FICHEROS DE PUNTOS               */
 /* GLOBAL CLUB: OPERACIONES PARA ATRIUM (GCMOV - GCTOT)           */
 /*            (CLP.CABPUNCL --> CLP.ATRIUMGCCL)                   */
 /*------------------------------------------------------------------*/
 REA90:      CHKOBJ     OBJ(FICHEROS/OPERACIE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO NOPUN)

             CALL       PGM(SUBRUDIN/COMFICL) PARM(OPERACIE FICHEROS +
                          &COD '1')

     /* FIC. OPERAC CON REGISTROS */
             IF         COND((&COD) *EQ 0) THEN(DO)
             CALL       PGM(EXPLOTA/CABPUNCL) PARM(&FECHA1)
             CHGJOB     DATE(&FECHA1)
             ENDDO

     /* FIC. OPERAC SIN REGISTROS */
             IF         COND((&COD) *EQ 1) THEN(DO)
             DLTF       FICHEROS/FILIACIE
             DLTF       FICHEROS/OPERACIE
             ENDDO

 NOPUN:      CHGJOB     DATE(&FECHA1)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 91*/
 /*------------------------------------------------------------------*/
 /*  LIBRE  LIBRE  LIBRE  LIBRE  LIBRE ...                           */
 /*------------------------------------------------------------------*/
 REA91:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' IN02) /* 92*/
 /*-----------------------------------------------------------------*/
 /*                       *** F I N ***                           */
 /*-----------------------------------------------------------------*/
 REA92:      CALL       PGM(PRDIACTL) PARM('B' 'IN02      ')
             CALL       PGM(PRFICCTL) PARM('B' 'FACTESTABL')
             CALL       PGM(PRFICCTL) PARM('A' 'SIFNET    ')
             CALL       PGM(PRFICCTL) PARM('B' 'NOACES    ')

 /*-------------------------------------------------*/
 /* PERMISO PARA LA EJECUCION DE LOS PROCESO NOCHE  */
 /*-------------------------------------------------*/
             CALL       PGM(PRFICCTL) PARM('B' 'NOPAIN    ')

             CHGJOB     DATE(&FECHA1)
 /*-------------------------------------------------*/
 /*     E-MAIL  DE FINALIZACION DEL PROCESO         */
 /*-------------------------------------------------*/
             CHGVAR     VAR(&MSG) VALUE('** ACABA DE FINALIZAR EL +
                          PROCESO ** DE CLP.PROCNOCHE --> CLP.IN02M')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((GrupoAS400@dinersclub.es)) +
                          DSTD('FACTURACION DIARIA +
                          ESTABLECIMIENTOS       ') LONGMSG(&MSG)

 /*-------------------------------------------------*/

 FININ02:    CALL       PGM(TRACE) PARM('FIN    GUARDA ' ' ' 'IN02')
 /*-----------------------------------------------------------------*/


/********************************************************************/
/* GRABAR INCIDENCIA                                                */
/********************************************************************/
             SUBR       SUBR(INCIDENCIA)

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CALL       PGM(EXPLOTA/TRACE) PARM(&DESCRIP ' ' IN02)
             ENDSUBR
/********************************************************************/
             ENDPGM