/*********************************************************************/
/** =============================================================== **/
/** CONTROL-M   CONTROL-M   CONTROL-M   CONTROL-M   CONTROL-M     **/
/** =============================================================== **/
/**                                                                 **/
/**  =============================================================  **/
/** ESPECIAL: FACTURACION SOCIOS "CONCILIACION CUENTAS DE VIAJES" **/
/**  =============================================================  **/
/**     Siempre "A PETICIÓN" del Departamento de Conciliación     **/
/**                                                                 **/
/*********************************************************************/
             PGM        PARM(&FECHAE &RESPU)
             DCL        VAR(&ACCION) TYPE(*CHAR) LEN(1)
             DCL        VAR(&NUMREG) TYPE(*DEC) LEN(10 0)
             DCL        VAR(&DATOS)  TYPE(*CHAR) LEN(14) VALUE('FS01CO')
             DCL        VAR(&DD)     TYPE(*DEC)  LEN(2)
             DCL        VAR(&MM)     TYPE(*CHAR) LEN(2)
             DCL        VAR(&DDMMP)  TYPE(*DEC)  LEN(4)
             DCL        VAR(&DDMMF)  TYPE(*CHAR) LEN(4)
             DCL        VAR(&REST1)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&FECHAE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&FECHAX) TYPE(*DEC)  LEN(6 0)
             DCL        VAR(&FECHA)  TYPE(*CHAR) LEN(6)
             DCL        VAR(&LABAL)  TYPE(*CHAR) LEN(8)
             DCL        VAR(&LABEL)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&LAFA)   TYPE(*CHAR) LEN(6)
             DCL        VAR(&RTCDE)  TYPE(*CHAR) LEN(1)
             DCL        VAR(&CODRET) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TEX)    TYPE(*CHAR) LEN(50)
             DCL        VAR(&CONCI)  TYPE(*CHAR) LEN(1) VALUE('C')
             DCL        VAR(&RESPU)  TYPE(*CHAR) LEN(2)
             DCL        VAR(&SEAT)   TYPE(*CHAR) LEN(4)
             DCL        VAR(&FECSYS) TYPE(*CHAR) LEN(6)
             DCL        VAR(&SS)     TYPE(*CHAR) LEN(2)
             DCL        VAR(&DDPRO)  TYPE(*CHAR) LEN(2)
             DCL        VAR(&BLOQUEA) TYPE(*CHAR) LEN(1)
             DCL        VAR(&MSG)    TYPE(*CHAR) LEN(128)
             DCL        VAR(&ESTADO) TYPE(*CHAR) LEN(1)
             DCL        VAR(&NUMREG) TYPE(*DEC)  LEN(10 0)
             DCL        VAR(&CLAVES) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')
             DCL        VAR(&AGRUP1) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')
             DCL        VAR(&AGRUP2) TYPE(*CHAR) LEN(30) +
                          VALUE('                              ')

             DCL        VAR(&DESCTOT) TYPE(*CHAR) LEN(200) /* PARA +
                          ENVIO MENSAJE DEL INCIDENCIAS AL CONTROL-M */

             DCL        VAR(&CODRET) TYPE(*CHAR) LEN(1)
             DCL        &PTSTOT  *DEC    10 0
             DCL        VAR(&NOCUA)  TYPE(*CHAR) LEN(1)
             DCL        VAR(&TOTCUA) TYPE(*DEC) LEN(11 0)

             DCL        VAR(&PROCE) TYPE(*CHAR) LEN(10) +
                          VALUE('FS01COM   ') /* /fichero de +
                          incidencias */
             DCL        VAR(&PRIORID) TYPE(*DEC) LEN(1 0) VALUE(9)
             DCL        VAR(&DESCRIP) TYPE(*CHAR) LEN(80)

/*-------------------------------------------------------------------*/

             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

             CALL       PGM(EXPLOTA/TRACE) PARM('**   FACTURACION +
                          SOCIOS --CUENTAS DE VIAJES +
                          CONCILIADAS--   **                ' ' ' +
                          FS01CO)
/*-------------------------------------------------------------------*/
/*      CONTROL TERMINADA CONFIRMACION CRUCE        -                */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'NOFS01CO  ')

             IF         COND(&ACCION = 'S') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('NO HA TERMINADO BIEN LA +
                          CONFIRMACION DE CRUCE  -SE CANCELA   FS01CO')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es) +
                          (grupodesarrollo2@dinersclub.es *CC)) +
                          DSTD('FACTURACION SOCIOS     FS01COM   ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FINFIN)

             ENDDO
/*-------------------------------------------------------------------*/
/*-- RPG.CAREBA  -CREA CALENDARIO DE RECIBOS PENDIENTES DE VENCER- --*/
/*        PETICION DE FECHA DE PROCESO                               */
/*-------------------------------------------------------------------*/
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&FECSYS) /*Fecha Sistema*/
/*-------------------------------------------------------------------*/
/*        PETICION DE FECHA DE PROCESO                               */
/*-------------------------------------------------------------------*/

             CHGVAR     VAR(&FECHAX) VALUE(&FECHAE)

             CHGVAR     VAR(&FECHA) VALUE(&FECHAE)
             CHGJOB     DATE(&FECHA) SWS(00000000)

             CHGVAR     VAR(&DD)    VALUE(%SUBSTRING(&FECHA 1 2))
             CHGVAR     VAR(&MM)    VALUE(%SUBSTRING(&FECHA 3 2))
             CHGVAR     VAR(&DDPRO) VALUE(%SUBSTRING(&FECHA 1 2))
             CHGVAR     VAR(&DDMMP) VALUE(%SUBSTRING(&FECHA 1 4))
             CHGVAR     VAR(&DDMMF) VALUE(&DDMMP)
/*-------------------------------------------------------------------*/
/*      CONTROL ULTMA FACT. DEL AÑO POR TEMA -BAUTSO-                */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'CTRULTBAU ')

             IF         COND(&ACCION = 'S') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('ESTAMOS A PRIMEROS DE +
                          AÑO Y AUN NO SE HAN MOVIDO LAS +
                          ESTADIST.DEL BAUTSO  FS01CO')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01CO   ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FINFIN)

             ENDDO
/*-------------------------------------------------------------------*/
/*    FICHERO DE TARJETAS CONCILIADAS PARA HACER EXTRACTOS NO EXISTE */
/*-------------------------------------------------------------------*/
             CHKOBJ     OBJ(FICHEROS/ECTASCON) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('NO EXISTE FICHERO  +
                          -ECTASCON-, TARJETAS MARCADAS PARA  +
                          FACTURAR.')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es) +
                          (grupodesarrollo2@dinersclub.es *CC)) +
                          DSTD('FACTURACION SOCIOS     FS01CO    ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FINFIN)

             ENDDO
/*-------------------------------------------------------------------*/
/*           ESTA ARRANCADA LA FACTURACION DE SOCIOS NORMAL          */
/*-------------------------------------------------------------------*/
             CHKOBJ     OBJ(FICHEROS/FIFS01) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(REARRA))

             CHGVAR     VAR(&DESCRIP) VALUE('HAY UNA FACTURACION +
                          NORMAL DE SOCIOS ARRANCADA. SE CANCELA   +
                          FS01CO')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es *PRI) +
                          (grupodesarrollo2@dinersclub.es *CC)) +
                          DSTD('FACTURACION SOCIOS     FS01CO    ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FINFIN)

/*-------------------------------------------------------------------*/
/*--                    REARRANQUE AUTOMATICO                        */
/*-------------------------------------------------------------------*/
 REARRA:     IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '01') +
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
/*-------------------------------------------------------------------*/
/*                CREACION FICHEROS DE CONTROL                       */
/*-------------------------------------------------------------------*/
             CALL       PGM(PRFICCTL) PARM('A' 'NOPROC    ')

             CL1        LABEL(FIFS01CO) LIB(FICHEROS) LON(1) /* +
                          Control Permisos Trabajos -CONCILIACION-  */
/*-------------------------------------------------------------------*/
/*                CONTROL DE EJECUCION                               */
/*-------------------------------------------------------------------*/

             CALL       PGM(PRDIACTL) PARM('A' 'FS01COM   ')

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*01*/
/*-------------------------------------------------------------------*/
/*                       CLASIFICACION -PA-                          */
/*-------------------------------------------------------------------*/
 RE1:        CALL       PGM(EXPLOTA/TRACE) PARM('                    +
                          CLASIFICACION -PA- EN +
                          EJECUCION                  ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             DLTF       FILE(FICHEROS/PACONL*)
             MONMSG     MSGID(CPF0000)

             CL1        LABEL(SORTFAPA) /* CONTROL PROXIMO EXTRACTO */
/*----*/
 ALOCA1:     ALCOBJ     OBJ((FICHEROS/PA *FILE *EXCL))
             MONMSG     MSGID(CPF0000) EXEC(DO)
             CHGVAR     VAR(&MSG) VALUE('Facturacion de Socios, +
                          pongase en el menu general durante 5 +
                          minutos, de lo contrario esta pantalla se +
                          cancelara.')

             CALL       PGM(EXPLOTA/TRACE) PARM('El fichero PA esta +
                          alocatado por otro trabajo.' ' ' FS01CO)

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(PA *FILE +
                          FICHEROS &MSG &BLOQUEA)

             CHGJOB     DATE(&FECHA)
             GOTO       CMDLBL(ALOCA1)
             ENDDO

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

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*02*/
/*-------------------------------------------------------------------*/
/*  COPIA DE SEGURIDAD DEL MSOCIO                                    */
/*-------------------------------------------------------------------*/
RE2:

OTRO_LABEL:  RTVSYSVAL  SYSVAL(QSECOND) RTNVAR(&SS)
             CHGVAR     VAR(&LABEL) VALUE('MSOCIO' || &DDPRO || &SS)
             CHKOBJ     OBJ(LIBSEG30D/&LABEL) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LABEL_OK))
             GOTO       CMDLBL(OTRO_LABEL)

 LABEL_OK:   CRTPF      FILE(LIBSEG30D/&LABEL) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(MSOCIO_PF) +
                          TEXT('FS01CO -MSOCIO- PRINCIPIO +
                          FACTURACION SOCIOS') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)

             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(LIBSEG30D/&LABEL))

             CPYF       FROMFILE(FICHEROS/T_MSOCIO) +
                          TOFILE(LIBSEG30D/&LABEL) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*03*/
/*-------------------------------------------------------------------*/
/*--        CREAR: MSOCIO88 CON LAS TARJETAS A FACTURAR            --*/
/*-------------------------------------------------------------------*/
 RE3:        CALL       PGM(EXPLOTA/TRACE) PARM('**                  +
                          CREACION DEL MSOCIO88             +
                          **             ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTLF      FILE(FICHEROS/MSOCILGJ) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('MSOCIO - +
                          TARJETAS CON CONDICION CONCILIAR') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/MSOCIO88) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(MSOCIO_PF) +
                          TEXT('facturacion de socios') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/MSOCIO88))

             CPYF       FROMFILE(FICHEROS/MSOCILGJ) +
                          TOFILE(FICHEROS/MSOCIO88) +
                          MBROPT(*REPLACE) FMTOPT(*NOCHK)

/*=====================================*/
/* RASTREO -SEAT- ¿Solo Tarjetas SEAT? */
/*=====================================*/
             CHGVAR     VAR(&RTCDE) VALUE(' ')
             CHGVAR     VAR(&SEAT)  VALUE('    ')
             CALL       PGM(EXPLOTA/SEATENMS88) PARM(&RTCDE &SEAT)

             IF         COND(&RTCDE *EQ 'E') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('FACTURACION +
                          GRUPO:SEAT-HAY TARJETAS D OTRAS EMPRESAS +
                          Y NO ESTA PERMITIDO. FIN')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01CO    ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FINFIN)

             ENDDO

             CHGJOB     DATE(&FECHA)
/*--------------------------------------------------------------------------*/
/*    CREA Y VALIDA FICHERO DE CONTROL -CRFS01-                            */
/*--------------------------------------------------------------------------*/
             D1         LABEL(CRFS01) LIB(FICHEROS)
             MONMSG     MSGID(CPF0000)

             CALL       PGM(FSFECHACO) PARM(&SEAT)

             CL1        LABEL(CRFS01) LIB(FICHEROS) LON(96)

             CALL       PGM(EXPLOTA/CRFS01AUT)

/*===============================================*/
/* RASTREO -SEAT- Orden en Fechas de Facturación */
/*===============================================*/
             CHGJOB     DATE(&FECHA)

             IF         COND(&SEAT *EQ 'SEAT') THEN(DO)
             CALL       PGM(EXPLOTA/SEATORDFAC) PARM(&RTCDE)

             IF         COND(&RTCDE *EQ 'E') THEN(DO)


             CHGVAR     VAR(&DESCRIP) VALUE('FS01CO-SEAT-HAY +
                          TARJETA/S PARA FACTURAR Y LA FECHA DE +
                          FACT.NO CORRESPONDE-FIN')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01CO    ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             GOTO       CMDLBL(FINFIN)

             ENDDO
             ENDDO
/*===============================================*/

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*04*/
/*-------------------------------------------------------------------*/
/* FCSUPA: CUADRAR INFORME CONTRA "CIFRA" DEL E-MAIL ENVIADO POR EL  */
/*         DEPARTAMENTO DE CONCILIACION.                             */
/*-------------------------------------------------------------------*/
 RE4:        CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -FCSUPA- +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/FCSUPAM)

 /*Importante: "CUADRAR" */

             CHGVAR     VAR(&PTSTOT) VALUE(0)
             CHGVAR     VAR(&NOCUA) VALUE(' ')
             CALL       PGM(EXPLOTA/CUADAU) PARM(&PTSTOT 'FCONCI' +
                          '1' 'C' &NOCUA)

             IF         COND(&NOCUA *EQ 'N') THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : NO +
                          CUADRA EL TOTALES +
                          -FCONCI-.FACT.CONCILIACION FS01COM' ' ' +
                          FS01CO)

             CHGVAR     VAR(&DESCRIP) VALUE('IMPORTANTE : NO CUADRA +
                          EL TOTALES -FCONCI-.FACT.CONCILIACION    +
                          **INVESTIGAR')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "FCONCI" FACT.CONCILIACION +
                          -FS01COM-        **LLAMAR A DINERS CLUB +
                          SPAIN')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*05*/
/*-------------------------------------------------------------------*/
/*  CREACION CONTROL COMPENSACION DE SALDOS                          */
/*-------------------------------------------------------------------*/
             CRTPF      FILE(FICHEROS/COMPENFAS) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(COMPENSAR) TEXT('Control +
                          compensacion de saldos') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/COMPENFAS))

             CALL       PGM(COMPENCREA) PARM('S')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(COMPENFAS +
                          FICHEROS COMPENFAS LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)

/*-------------------------------------------------------------------*/
/* SE COPIA A LIBSEG30D:  FA, PA y PTEPREPR.     -ENTRADA EN FACT.-  */
/*-------------------------------------------------------------------*/
RE5:         CHGVAR     VAR(&TEX) VALUE('FS01CO, ENTRADA FACTURACION +
                          SOCIOS -CONCILIACION-')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FA FICHEROS FA +
                          LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PTEPREPR FICHEROS +
                          PTEPREPR LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(NOGASTOS FICHEROS +
                          NOGASTOS LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(REGEMP FICHEROS +
                          REGEMP LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*06*/
/*-------------------------------------------------------------------*/
/*                     CHEQUEA SI ESTA: NOABONOS                     */
/*-------------------------------------------------------------------*/
 RE6:        CHKOBJ     OBJ(FICHEROS/NOABONOS) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(DO)
             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/NOABONOS) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('NOABONOS +
                          PARA LA FACTURACION DE SOCIOS') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             ENDDO
/*-------*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, ENTRADA FACTURACION +
                          SOCIOS -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(NOABONOS FICHEROS +
                          NOABONOS LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*07*/
/*-------------------------------------------------------------------*/
/*-- LIBRE   LIBRE                                                 --*/
/*-------------------------------------------------------------------*/
 RE7:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*08*/
/*-------------------------------------------------------------------*/
/*   CHEQUEO: MSOCIO (MSOCILGJ) CONTRA -PA-   MARCAS: CONCILIACION   */
/*-------------------------------------------------------------------*/
 RE8:        CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -CHKCO1- +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CL1        LABEL(INCCHK01) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCCHK01)

             CALL       PGM(EXPLOTA/CHKCO1)

             DLTOVR     FILE(IMP0017)

             RTVMBRD    FILE(FICHEROS/INCCHK01) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 0) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('INCIDENCIAS entre +
                          MSOCIO Y PA,  detener la FACTURACION +
                          INVESTIGAR el motivo.')

             CHGVAR     VAR(&DESCTOT) VALUE('INCIDENCIAS entre +
                          MSOCIO Y PA,  detener la FACTURACION  +
                          INVESTIGAR el motivo.')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&CODRET) VALUE('0')
             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*09*/
/*-------------------------------------------------------------------*/
/*   CHEQUEO: PA (PACONLG5) CONTRA -MSOCIO-   MARCAS: CONCILIACION   */
/*-------------------------------------------------------------------*/
 RE9:        CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -CHKCO2- +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTLF      FILE(FICHEROS/PACONLG5) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -PA- PARA RPG.CHKCO2') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CL1        LABEL(INCCHK02) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCCHK02)

             CALL       PGM(EXPLOTA/CHKCO2)

             DLTOVR     FILE(IMP0017)

             RTVMBRD    FILE(FICHEROS/INCCHK02) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 0) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('INCIDENCIAS entre PA Y +
                          MSOCIO, detener la FACTURACION INVESTIGAR +
                          el motivo.')

             CHGVAR     VAR(&DESCTOT) VALUE('INCIDENCIAS entre PA Y +
                          MSOCIO,  detener la FACTURACION  +
                          INVESTIGAR el motivo.')

             CALLSUBR   SUBR(INCIDENCIA)

             CHGVAR     VAR(&CODRET) VALUE('0')
             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO


             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*10*/
/*-------------------------------------------------------------------*/
/*                     CHEQUEO -PA- CONTRA -DESCRFAC-                */
/*-------------------------------------------------------------------*/
 RE10:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -CHKCO3- +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTLF      FILE(FICHEROS/PACONLG7) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CALL       PGM(EXPLOTA/CHKDESDICL)

             CL1        LABEL(ICHKCO3) LON(132)

             OVRDBF     FILE(IMP0017) TOFILE(FICHEROS/ICHKCO3)

             CALL       PGM(EXPLOTA/CHKCO3) PARM(&RTCDE)

             DLTOVR     FILE(IMP0017)

             IF         COND(&RTCDE = '1') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('INCIDENCIAS entre PA Y +
                          DESCRFAC,detener la FACTURACION +
                          INVESTIGAR el motivo')

             CHGVAR     VAR(&DESCTOT) VALUE('INCIDENCIAS entre PA Y +
                          DESCRFAC, detener la FACTURACION  +
                          INVESTIGAR el motivo.')

             CALLSUBR   SUBR(INCIDENCIA)
/*-----------------------*/
/*    ¿HAY ERRORES?    */
/*-----------------------*/
             RTVMBRD    FILE(FICHEROS/ICHKCO3) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 16 ) THEN(DO)

             DLTDLO     DLO(ICHKCO3) FLR(VARMAIL)
             MONMSG     MSGID(CPF0000)

             CPYTOPCD   FROMFILE(FICHEROS/ICHKCO3) TOFLR(VARMAIL) +
                          REPLACE(*YES)

             SNDDST     TYPE(*DOC) +
                          TOINTNET((operadores@dinersclub.es *PRI)) +
                          DSTD('chequeo descripciones +
                          -pa/descrfa-') MSG('incidencias en +
                          descripciones -pa/descrfa-') DOC(ICHKCO3) +
                          FLR(VARMAIL)

             SNDDST     TYPE(*DOC) +
                          TOINTNET((grupoas400@dinersclub.es *PRI)) +
                          DSTD('chequeo descripciones +
                          -pa/descrfa-') MSG('incidencias en +
                          descripciones -pa/descrfa-') DOC(ICHKCO3) +
                          FLR(VARMAIL)

             CHGVAR     VAR(&TEX) VALUE('FS01COMLincidencias en +
                          descripciones -pa/descrfa-')

             CALL       PGM(EXPLOTA/CONCOBCL) PARM(ICHKCO3 FICHEROS +
                          ICHKCO3 LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CHGVAR     VAR(&CODRET) VALUE('0')
             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO

             ENDDO

             D1         LABEL(PACONLG7) LIB(FICHEROS)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*11*/
/*-------------------------------------------------------------------*/
/*   LIBRE                                                           */
/*-------------------------------------------------------------------*/
 RE11:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*12*/
/*-------------------------------------------------------------------*/
/*-  AL 31 DE ENERO LIMPIO EL MEMPRE  -SOLO CTAS. QUE CONCILIAN-    -*/
/*-------------------------------------------------------------------*/
 RE12:       IF         COND(&DDMMP = 3101) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : POR +
                          SER LA 1ª. FACT.EMPRESAS QUE CONCILIAN +
                          DEL AÑO SE PROCEDE   ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('A LIMPIAR EN +
                          MAESTRO DE EMPRESAS LAS +
                          ESTADITICAS DEL AÑO RECIEN ACABADO       +
                          ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)
/*---*/
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -LIMCEM- +
                          EN EJECUCION' ' ' FS01CO)

             CALL       PGM(EXPLOTA/LIMCEM)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, -MEMPRE- DESPUES +
                          DEL PGM-LIMCEM')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MEMPRE FICHEROS +
                          MEMPRE LIBSEG30D C ' ' ' ' &TEX FS01CO)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*13*/
/*-------------------------------------------------------------------*/
/*                          SORT -FA-                                */
/*-------------------------------------------------------------------*/
 RE13:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  SORT DEL +
                          -FA-' ' ' FS01CO)

             CL1        LABEL(SORTFAPA) /* CONTROL PROXIMO EXTRACTO */
             CHGJOB     DATE(&FECHA)

/*----*/
 ALOCA:      ALCOBJ     OBJ((FICHEROS/FA *FILE *EXCL))
             MONMSG     MSGID(CPF0000) EXEC(DO)

             CHGVAR     VAR(&MSG) VALUE('Facturacion de Socios, +
                          pongase en el menu general durante 5 +
                          minutos, de lo contrario esta pantalla se +
                          cancelara.')

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(FA *FILE +
                          FICHEROS &MSG &BLOQUEA)

             CALL       PGM(EXPLOTA/TRACE) PARM('FICHERO -FA- +
                          ALOCATADO POR OTRO TRABAJO PULSAR INTRO +
                          SE VISUALIZA TRABAJOS   ' ' ' FS01CO)

             GOTO       CMDLBL(ALOCA)
             ENDDO

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

             CHGJOB     DATE(&FECHA)

             DLCOBJ     OBJ((FICHEROS/FA *FILE *EXCL))
             MONMSG     MSGID(CPF0000)

             D1         LABEL(SORTFAPA) LIB(FICHEROS)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*14*/
/*-------------------------------------------------------------------*/
/*-- SAPNB_aux  (Fichero Auxiliar Condiciones Aplazamiento TE'S)   --*/
/*-------------------------------------------------------------------*/
 RE14:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -MSAPNB2- +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTLF      FILE(FICHEROS/SAPNBLG1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -SAPNB- PARA RPG.MSAPNB2') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/SAPNB_AUX) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('AUXILIAR +
                          CONDICIONES DE APLAZAMIENTO TE') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/SAPNB_AUX))

             CALL       PGM(EXPLOTA/MSAPNB2)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, ANTES DE EJECUTAR +
                          -FCFAPA-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SAPNB FICHEROS +
                          SAPNB LIBSEG30D C ' ' ' ' &TEX FS01CO) /* +
                          Maestro */
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SAPNB_AUX +
                          FICHEROS SAPNBA LIBSEG30D P ' ' ' ' &TEX +
                          FS01CO) /* Auxiliar */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*15*/
/*-------------------------------------------------------------------*/
/*             RPG. F C F A P A   (FSFAPA CON RETOQUES)              */
/*-------------------------------------------------------------------*/
 RE15:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -FCFAPA- +
                          EN EJECUCION' ' ' FS01CO)

             CHGJOB     DATE(&FECHA)
/*=====================*/
/*  FICHERO: MICHELIN  */
/*=====================*/

 VERMIC:     CHKOBJ     OBJ(FICHEROS/MICHELIN) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(DO)

             CRTPF      FILE(FICHEROS/MICHELIN) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('CONCILIACIÓN, COMISIONES MICHELIN +
                          PARA EXTRACTO') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             ENDDO

/*=====================*/

             CRTPF      FILE(FICHEROS/PLARESER) RCDLEN(155) +
                          TEXT('plazos reserva para facturar') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PLARESER))

             CRTPF      FILE(FICHEROS/FAPA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FAPA) +
                          TEXT('FUSION DE FA Y PA, FAPA DE SALIDA') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/FAPA))

             CRTPF      FILE(FICHEROS/FASALE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FA) +
                          TEXT('FA DE SALIDA') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FASALE))

             CRTPF      FILE(FICHEROS/PASALE) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(PA) +
                          TEXT('PA DE SALIDA EN EL FCFAPA') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/PASALE))

             CRTPF      FILE(FICHEROS/ASIFAPA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('Asiento RPG.FCFAPA') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFAPA))

             CRTPF      FILE(FICHEROS/PENCOMIC) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(PENCOMES) TEXT('Anexo +
                          Establecimientos Michelin RPG.FCFAPA') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/PENCOMIC))

           /*CALL       PGM(PARONMC01)  */
            /*--------------------------------------------------------------*/
            /* SE LLENA EL PAENT, FAENT, PAENTMC Y FAENTMC CON TODO PA Y FA */
            /* EL PGM MC0100 PARA DEJAR SOLO DINERS O SOLO MC               */
            /*--------------------------------------------------------------*/

             CPYF       FROMFILE(FICHEROS/PA) TOFILE(FICHEROS/PAENT) +
                          MBROPT(*REPLACE) CRTFILE(*YES)

             CPYF       FROMFILE(FICHEROS/PA) TOFILE(FICHEROS/PAENTMC) +
                          MBROPT(*REPLACE) CRTFILE(*YES)

             CPYF       FROMFILE(FICHEROS/FA) TOFILE(FICHEROS/FAENT) +
                          MBROPT(*REPLACE) CRTFILE(*YES)

             CPYF       FROMFILE(FICHEROS/FA) TOFILE(FICHEROS/FAENTMC) +
                          MBROPT(*REPLACE) CRTFILE(*YES)

             CALL MC0100

             OVRDBF     FILE(FAENTRA) TOFILE(FICHEROS/FAENT) +
                          LVLCHK(*NO) SEQONLY(*YES 50) /* FA DE ENTRADA */
             OVRDBF     FILE(PAENTRA) TOFILE(FICHEROS/PAENT) +
                          LVLCHK(*NO) SEQONLY(*YES 50) /* PA DE ENTRADA */
            /*--------------------------------------------------*/

             /*OVRDBF     FILE(FAENTRA) TOFILE(FICHEROS/FA) + */
             /*             LVLCHK(*NO) SEQONLY(*YES 50) */

             /*OVRDBF     FILE(PAENTRA) TOFILE(FICHEROS/PA) + */
             /*             LVLCHK(*NO) SEQONLY(*YES 50) /* PA DE + */
             /*             ENTRADA */

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFAPA)
             OVRPRTF    FILE(IMP7017) COPIES(1)
             OVRPRTF    FILE(IMP1017) OUTQ(P10) SAVE(*YES)
             OVRPRTF    FILE(IMP00P9) SAVE(*YES) /* fax Michelin */

             CALL       PGM(EXPLOTA/FCFAPA)

             DLTOVR     FILE(IMP00P9 IMP1017)

             DLTOVR     FILE(FAENTRA)
             DLTOVR     FILE(PAENTRA)
            /*--------------------------------------------------------------*/
            /* SE RECUPERA EL PA Y EL FA DE MC PARA UNIFICARLO CON          */
            /* PASALE Y FASALE (ASI NO SE PIERDEN REGISTROS                 */
            /*--------------------------------------------------------------*/
             CPYF       FROMFILE(FICHEROS/PAENTMC) +
                          TOFILE(FICHEROS/PASALE) MBROPT(*ADD)
             CPYF       FROMFILE(FICHEROS/FAENTMC) +
                          TOFILE(FICHEROS/FASALE) MBROPT(*ADD)
            /*--------------------------------------------------------------*/

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*16*/
/*-------------------------------------------------------------------*/
/*  -FAPA- VACIO (PETICION DE EXTRACTO A TARJETAS SIN MOVIMIENTO     */
/*-------------------------------------------------------------------*/
RE16:        RTVMBRD    FILE(FICHEROS/FAPA) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG = 0) THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('El fichero FAPA en la +
                          biblioteca FICHEROS esta vacío, SE CANCELA')

             CALLSUBR   SUBR(INCIDENCIA)

             D1         LABEL(CRFS01)    LIB(FICHEROS)
             D1         LABEL(MSOCIO88)  LIB(FICHEROS)
             D1         LABEL(NOABONOS)  LIB(FICHEROS)
             D1         LABEL(PLARESER)  LIB(FICHEROS)
             D1         LABEL(FAPA)      LIB(FICHEROS)
             D1         LABEL(FASALE)    LIB(FICHEROS)
             D1         LABEL(PASALE)    LIB(FICHEROS)
             D1         LABEL(ASIFAPA)   LIB(FICHEROS)
             D1         LABEL(PENCOMIC)  LIB(FICHEROS)
             D1         LABEL(SAPNB_AUX) LIB(FICHEROS)
             CALL       PGM(PRFICCTL) PARM('B' 'NOPROC    ')
             GOTO       CMDLBL(FINFIN)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*17*/
/*=====================================================*/
/*  CLP-FSCUOTE1CL "CUOTAS Y COSTES POR SERVICIOS"   */
/*=====================================================*/
 RE17:       CALL       PGM(EXPLOTA/FSCUOTE1CL) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CHKOBJ     OBJ(FICHEROS/FAPACUOTE5) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOFAPAC5))

             RTVMBRD    FILE(FICHEROS/FAPACUOTE5) NBRCURRCD(&NUMREG)

/*==*/
             IF         COND(&NUMREG > 0) THEN(DO)
             CPYF       FROMFILE(FICHEROS/FAPACUOTE5) +
                          TOFILE(FICHEROS/FAPA) MBROPT(*ADD) FROMRCD(1)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, FAPACUOTE5 DE +
                          SALIDA DE PROGRAMA CUOTE05  ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPACUOTE5 +
                          FICHEROS FAPACUOTE5 LIBSEG30D M ' ' ' ' +
                          &TEX FS01CO)

             FMTDTA     INFILE((FICHEROS/FAPA)) +
                          OUTFILE(FICHEROS/FAPA) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(SFAPA) +
                          OPTION(*NOPRT)
             ENDDO
/*=====================================================*/
 NOFAPAC5:
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*18*/
/*-------------------------------------------------------------------*/
/*      RPG. F S S E G U    -CONTRATACION ADICIONAL SEGURO           */
/*-------------------------------------------------------------------*/
 RE18:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -FCSEGU- +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/ASIFISEG) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          TEXT('Apunte contratacion adicional +
                          seguros') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFISEG))

             CRTPF      FILE(FICHEROS/DETE21) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE21))

             CRTPF      FILE(FICHEROS/CABE21) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE21))

             OVRPRTF    FILE(IMP00P5) PAGESIZE(51 132) OVRFLW(51) +
                          DRAWER(2) SAVE(*YES)

             CALL       PGM(EXPLOTA/FCSEGU) PARM('2')

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */
             CHGJOB     DATE(&FECHA)

             CPYF       FROMFILE(FICHEROS/DETE21) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE21) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01CO,   DESPUES DEL +
                          PGM-FCSEGU')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE21 FICHEROS +
                          DETE21 LIBSEG1D M ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE21 FICHEROS +
                          CABE21 LIBSEG1D M ' ' ' ' &TEX FS01CO)

             OVRDBF     FILE(ASIFILE) TOFILE(ASIFISEG)
             CALL       PGM(EXPLOTA/FCTIME) /* Cambiar Fecha */

             CALL       PGM(EXPLOTA/ACASBO) PARM('024')

             CHGVAR     VAR(&TEX) VALUE('FS01CO, SALIDO DEL +
                          PGM-FSSEGU -CONCILIACION-')
             CALL       PGM(CONCOPCL) PARM(ASIFISEG FICHEROS +
                          ASIFISEG LIBSEG1D M ' ' ' ' &TEX FS01CO)

             DLTOVR     FILE(IMP00P5)
             DLTOVR     FILE(ASIFILE)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*19*/
/*-------------------------------------------------------------------*/
/*SOLUCION AUNA: DESGLOSE OPERACIONES "TARJ.MATRIZ A TARJ.INTERNAS"*/
/*-------------------------------------------------------------------*/
 RE19:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -AUNAFSCL- +
                          EN EJECUCION' ' ' FS01CO)

             CALL       PGM(EXPLOTA/AUNAFSCL)
             CHGJOB     DATE(&FECHA)

 /* ========================================================== */
 /*  TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL      */
 /* ========================================================== */
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('** SOLUCION AUNA: +
                          TRAS -AUNAFSCL- REVISAR FICHERO FAPA, +
                          DESCRFAC,      **     ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('**                +
                          OPAGECO Y MSOCIO88 (DESGLOSE DE +
                          TARJETAS).           **     ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)

  /*         CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')      */
  /*         CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')      */

 /* ========================================================== */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*20*/
/*-------------------------------------------------------------------*/
/*        COPIAS DE SEGURIDAD -PLARESER Y PENCOMIC-                  */
/*-------------------------------------------------------------------*/
 RE20:       CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM.FCFAPA -CONCILIACION-')
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PLARESER FICHEROS +
                          PLARESER LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCOMIC FICHEROS +
                          PENCOMIC LIBSEG1D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*21*/
/*-------------------------------------------------------------------*/
/*-- RPG.RASFEU "RASTREO EXTRACTO UNIFICADO" (FAPA/MSOCIO/MENLACE) --*/
/*--            Y CREACION DE:  F A P A 8 8                        --*/
/*-------------------------------------------------------------------*/
 RE21:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -RASFEU- +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/RASFEU) PARM(&RTCDE) /* Extracto +
                          Unificado */

             IF         COND(&RTCDE = '1') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('Si hay incidencias,que +
                          pararse hasta que se resuelva')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('Si hay incidencias, +
                          pararse hasta que se resuelva **LLAMAR A +
                          DINERS CLUB SPAIN''')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO
/*---*/
             CRTPF      FILE(FICHEROS/FAPA88) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(FAPA) +
                          TEXT('FUSION DE FA Y PA, FAPA DE SALIDA') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FAPA88))

             CPYF       FROMFILE(FICHEROS/FAPA) +
                          TOFILE(FICHEROS/FAPA88) MBROPT(*REPLACE) +
                          FMTOPT(*NOCHK)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*22*/
/*-------------------------------------------------------------------*/
/*-                SORT DEL PENCUOTA (SCUOTA)                       -*/
/*-       SE ENVIA A LIBRERIA -NEGRA- "DESCATALOGADO"  15/6/2023    -*/
/*-------------------------------------------------------------------*/
 RE22:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*23*/
/*-------------------------------------------------------------------*/
/*                  RPG. F C B A L A                                 */
/*-------------------------------------------------------------------*/
 RE23:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  FCBALA  +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)
/*---------------------------------------------------------------------*/
/*         -COPIA DE FICHEROS ANTES DE ACTUALIZAR                    */
/*---------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01M, ANTES DE FCBALA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88 FICHEROS +
                          MSOCIO88 LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA88 FICHEROS +
                          FAPA88 LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCUOTA FICHEROS +
                          PENCUOTA LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(NOGASTOS FICHEROS +
                          NOGASTOS LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DINBCH FICHEROS +
                          DINBCH LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONCPVF FICHEROS +
                          CONCPVF LIBSEG30D C ' ' ' ' &TEX FS01CO)

/*-------------------------------------------------------------------*/
/*----------------*/
/*-- NO MOVIDOS --*/
/*----------------*/
             CHGVAR     VAR(&REST1) VALUE('FCNOEX' *CAT +
                          (%SUBSTRING(&FECHA 1 2)))
             DLTF       FILE(FICHEROS/&REST1)
             MONMSG     MSGID(CPF0000)

             CRTPF      FILE(FICHEROS/&REST1) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(FSNOEXTR) OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)
             OVRDBF     FILE(FSNOEXTR) TOFILE(FICHEROS/&REST1)
/*----------------*/

             CRTPF      FILE(FICHEROS/BS) SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('BALANCE SOCIOS') OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM FILE(FICHEROS/BS))

             CRTPF      FILE(FICHEROS/FSANUAL) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('control +
                          anuales') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/FSANUAL))

             CRTPF      FILE(FICHEROS/CONTROFS) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTROFS))

             CRTPF      FILE(FICHEROS/RECIBOS) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(RECIBOS) +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
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
             OVRDBF     FILE(MSOCIO) TOFILE(FICHEROS/MSOCIO88)
             CALL       PGM(EXPLOTA/BILLHOP3)
             DLTOVR     FILE(MSOCIO)
             DLTOVR     FILE(MS_BILLFAC)

             CPYF       FROMFILE(FICHEROS/MS_BILLFA1) +
                          TOFILE(FICHEROS/MS_BILLFAC) MBROPT(*ADD) +
                          CRTFILE(*YES) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)
/*-----*/

             OVRPRTF    FILE(IMP0017) OUTQ(P11) SAVE(*YES)
             OVRPRTF    FILE(IMP1017) OUTQ(P3) SAVE(*YES)

             CL1        LABEL(EVIFCBALA) LIB(FICHEROS) LON(132) /* +
                          EVIDENCIA CONTABLE DIGITAL */
             OVRDBF     FILE(IMP2017) TOFILE(EVIFCBALA)

             CALL       PGM(EXPLOTA/FCBALA)

/*--EVIDENCIAS EXTRA-CONTABLE---*/
             CPYF       FROMFILE(FICHEROS/BS) +
                          TOFILE(FICHEROS/BSFS01COM) +
                          MBROPT(*REPLACE) CRTFILE(*YES) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/RECIBOS) +
                          TOFILE(FICHEROS/RECIBOSCOM) +
                          MBROPT(*REPLACE) CRTFILE(*YES) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)
/*-------------------------------*/
             CHGJOB     DATE(&FECHA)

 /* ========================================================== */
 /*  TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL      */
 /* ========================================================== */
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('** SOLUCION AUNA: +
                          TRAS -FCBALA- REVISAR FICHERO RECIBOS, BS +
                          Y CONTROFS **     ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)

    /*       CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')      */
    /*       CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')      */

 /* ========================================================== */

 /*--------------------------------------*/
 /* EVIADDCL CREA LA EVIDENCIA CONTABLE  */
 /*--------------------------------------*/
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFCBALA ' +
                          'ASIBALAN  ' 'TOTALES DE +
                          FACTURACION                            ' +
                          'FS01CO    ' '      ' ' ')

             CHGJOB     DATE(&FECHA)

             DLTOVR     FILE(IMP0017)
             DLTOVR     FILE(IMP1017)
             DLTOVR     FILE(IMP2017)
             DLTOVR     FILE(FSNOEXTR)
/*========================================*/
             CRTPF      FILE(FICHEROS/DATAWCUOC) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(DATAWHOUSE) TEXT('DATAWAREHOUSE, +
                          CUOTAS -CODIGOS:9-') OPTION(*NOLIST +
                          *NOSRC) SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DATAWCUOC))

             OVRDBF     FILE(DATAWCUO) TOFILE(FICHEROS/DATAWCUOC)
             CALL       PGM(EXPLOTA/DATAWC)
             DLTOVR     FILE(DATAWCUO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM.DATAWC -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DATAWCUOC +
                          FICHEROS DATAWCUOC LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*24*/
 /*--------------------------------------*/
 /* CONTROL SALDOS ACREEDORES STATUS 1   */
 /*--------------------------------------*/
 RE24:       CALL       PGM(EXPLOTA/CONCOPCL) PARM(ACRESTA1 FICHEROS +
                          ACRESTA1 LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CHGJOB     DATE(&FECHA)

             OVRPRTF    FILE(QSYSPRT) TOFILE(*FILE) OUTQ(P11) +
                          FORMTYPE(IMP00P11) SAVE(*YES)
             CALL       PGM(EXPLOTA/FSACRESTA)
             DLTOVR     FILE(QSYSPRT)
/*---------------------------------------------------*/
/* CUOCTACL - GENERAR CONTABILIZADO Y ASIENTO CUOTAS */
/*---------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA CUOCTACL +
                          EN EJECUCION' ' ' FS01CO)

             CALL       PGM(EXPLOTA/CUOCTACL) PARM('F')
             CHGJOB     DATE(&FECHA)

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*25*/
/*-------------------------------------------------------------------*/
/*                  RPG. F S L I S S                                 */
/*-------------------------------------------------------------------*/
 RE25:
             RTVMBRD    FILE(FICHEROS/SFSBALA1) NBRCURRCD(&NUMREG)

             CALL       PGM(EXPLOTA/TRACE) PARM('comprobar' ' ' +
                          CONTE1CL)

             IF         COND(&NUMREG > 0) THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  FSLISS  +
                          EN EJECUCION' ' ' FS01CO)

             CHGJOB     DATE(&FECHA)

             CL1        LABEL(INCFSLIS) LON(132)
             OVRDBF     FILE(IMP0017) TOFILE(INCFSLIS)
             OVRPRTF    FILE(IMP00P10) OUTQ(P11) SAVE(*YES)

             CALL       PGM(EXPLOTA/FSLISS)
             DLTOVR IMP00P10
             DLTOVR IMP0017

             CHGVAR     VAR(&DESCRIP) VALUE('PGM* FSLISS  Hay  +
                          Saltadas -Facturacion Socios-')

             CALLSUBR   SUBR(INCIDENCIA)

       /* CORREO DE SALTADAS A DESARROLLO2 */
       /*----------------------------------*/
             CHGVAR     VAR(&MSG) VALUE('HAY SALTADAS EN EL PROCESO +
                          VERIFICAR LISTADO Y TOTALES')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((grupodesarrollo2@dinersclub.es)) +
                          DSTD('FS01COM: SALTADAS EN EL FCBALA') +
                          LONGMSG(&MSG)

       /*----------------------------------*/
             CHGVAR     VAR(&DESCTOT) VALUE('PGM* FSLISS  Hay +
                          Saltadas -Facturacion conciliaacion- +
                          **LLAMAR A Diners Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

        /*   CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)  */

             CHGVAR     VAR(&TEX) VALUE('I N F O R M E    D E    S A +
                          L T A D A S  -FS01COM')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(INCFSLIS FICHEROS +
                          INCFSLIS LIBSEG30D C ' ' ' ' &TEX FS01CO)
             ENDDO

/*-------------------------------------------------------------------*/
/*       CUADRAR Y APUNTAR TOTALES DE CUOTAS Y DE SALTADAS           */
/*  SI NO CUADRA BORRAR LOS SIGUIENTE FICHEROS Y CANCELAR CLP      */
/*-------------------------------------------------------------------*/
             GOTO       CMDLBL(HAYSALTA)

             DLTF       FILE(FICHEROS/BS)
             DLTF       FILE(FICHEROS/CONTROFS)
             DLTF       FILE(FICHEROS/FSANUAL)
             DLTF       FILE(FICHEROS/RECIBOS)
             DLTF       FILE(FICHEROS/PENCUSAL)
             DLTF       FILE(FICHEROS/SFSBALA1)

 HAYSALTA:

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*26*/
/*=====================================================*/
/*   CLP-FSCUOTE2CL "CUOTAS Y COSTES POR SERVICIOS"   */
/*   CLP-CUOTE09CL  "FICHERO CARGOS/ABONOS CUOTAS"    */
/*=====================================================*/
 RE26:       CALL       PGM(EXPLOTA/FSCUOTE2CL) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/CUOTE09CL)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*27*/
/*-------------------------------------------------------------------*/
/*        COPIAS:  SFSBALA1                                          */
/*-------------------------------------------------------------------*/
 RE27:       CRTPF      FILE(FICHEROS/BSSALTA) RCDLEN(130) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/BSSALTA))

             CPYF       FROMFILE(FICHEROS/SFSBALA1) +
                          TOFILE(FICHEROS/BSSALTA) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FCBALA -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(SFSBALA1 FICHEROS +
                          SFSBALA1 LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*28*/
/*-------------------------------------------------------------------*/
/*             RPG. T E R C E 1  --CUOTAS A TERCEROS-                */
/*-------------------------------------------------------------------*/
 RE28:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  TERCE1 EN +
                          EJECUCION  ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/TERCE) RCDLEN(84) +
                          TEXT('proceso cuotas a terceros -CTAS.DE +
                          VIAJES-') SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/TERCE))

             CALL       PGM(EXPLOTA/TERCE1)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*29*/
/*-------------------------------------------------------------------*/
/*             SORT  LITERCE     --CUOTAS A TERCEROS-                */
/*-------------------------------------------------------------------*/
 RE29:       CALL       PGM(EXPLOTA/TRACE) PARM('SHORT PARA LITERCE +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             FMTDTA     INFILE((FICHEROS/TERCE)) +
                          OUTFILE(FICHEROS/TERCE) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(STERCE) +
                          OPTION(*NOPRT)

             MONMSG     MSGID(CPF1124) EXEC(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('+2' ' ' FS01CO) /*31*/
             GOTO       NOTERCE
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*30*/
/*-------------------------------------------------------------------*/
/*                 RPG.   L I T E R C E                              */
/*-------------------------------------------------------------------*/
 RE30:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  LITERCE +
                          EN EJECUCION  Retener el spool ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             OVRPRTF    FILE(IMP00PX) TOFILE(IMP00P11) COPIES(1)
             CALL       PGM(EXPLOTA/LITERCE)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*31*/
/*-------------------------------------------------------------------*/
/*                 COPIAS DE SEGURIDAD -CUOTERCE Y TERCE-            */
/*-------------------------------------------------------------------*/
 RE31:
 NOTERCE:    CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DE +
                          PGM-LITERCE -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CUOTERCE FICHEROS +
                          CUOTERCE LIBSEG1D M ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(TERCE FICHEROS +
                          TERCE LIBSEG1D M ' ' ' ' &TEX FS01CO)
/*-------------------------------------------------------------------*/
/*       GENERACION DE TRANSFERENCIAS A SALDOS ACREEDORES            */
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/FSACRECL)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*32*/
/*-------------------------------------------------------------------*/
/* SALVAR: PENCUOTA, FAPA, RECIBOS, BS, CONTROFS, PENCUOTA           */
/*-------------------------------------------------------------------*/
 RE32:       CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DE +
                          PGM-FCFAPA -CONCILIACION-')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PENCUOTA FICHEROS +
                          PENCUOTA LIBSEG30D M ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA FICHEROS +
                          FAPA LIBSEG30D M ' ' ' ' &TEX FS01CO)

             RNMOBJ     OBJ(FICHEROS/PENCUSAL) OBJTYPE(*FILE) +
                          NEWOBJ(PENCUOTA)
/*-------------------------------*/
/* BS A LIBSEG30D  COMO BCddmmaa */
/*-------------------------------*/
             CHGVAR     VAR(&LAFA) VALUE(&FECHA)
             CHGVAR     VAR(&LABAL) VALUE('BC' *CAT &LAFA)
             RNMOBJ     OBJ(FICHEROS/BS) OBJTYPE(*FILE) NEWOBJ(&LABAL)
             CHGVAR     VAR(&REST1) VALUE(&LABAL)
             RNMOBJ     OBJ(FICHEROS/&LABAL) OBJTYPE(*FILE) NEWOBJ(BS)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FCBALA -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS FICHEROS +
                          &REST1 LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFS FICHEROS +
                          CONTROFS LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECIBOS FICHEROS +
                          RECIBOS LIBSEG30D C ' ' ' ' &TEX FS01CO)

             DLTF       FILE(FICHEROS/NOABONOS)

             CHGJOB     DATE(&FECHA)
/*---------------------------------*/
/* CONTROFS PARA MIGRAR A ATRIUM */
/*---------------------------------*/
             CPYF       FROMFILE(FICHEROS/CONTROFS) +
                          TOFILE(FICHEROS/CONTROFSAT) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CONTROFS) +
                          TOFILE(ATRIUMDEMO/CONTROFSFA) +
                          MBROPT(*REPLACE) CRTFILE(*YES) FROMRCD(1) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, CONTROFSAT PDTE. +
                          -MIGRAR- A ATRIUM        ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFSAT +
                          FICHEROS CONTROFSAT LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, CONTROFSFA PDTE. +
                          -MIGRAR- A ATRIUMDEMO    ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROFSFA +
                          ATRIUMDEMO CONTROFSFA LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*33*/
/*-------------------------------------------------------------------*/
/*                  RPG.  C R E A B S                                */
/*-------------------------------------------------------------------*/
 RE33:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  CREABS EN +
                          EJECUCION  ' ' ' FS01CO)

             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/BSEXTRA) RCDLEN(751) TEXT('BS +
                          CON EL CAMPO ADICIONAL DE ORDEN') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BSEXTRA))

             CALL       PGM(EXPLOTA/CREABS)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*34*/
/*-------------------------------------------------------------------*/
/*                  SORT  B S E X T R A - B S                        */
/*-------------------------------------------------------------------*/
 RE34:       CALL       PGM(EXPLOTA/TRACE) PARM('CLASIFICACION +
                          -BSEXTRA-        ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CLRPFM     FILE(FICHEROS/BS)

             FMTDTA     INFILE((FICHEROS/BSEXTRA)) +
                          OUTFILE(FICHEROS/BS) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(SCREABS) +
                          OPTION(*NOPRT)

             DLTF       FILE(FICHEROS/BSEXTRA)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-CREABS -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS FICHEROS BS +
                          LIBSEG30D C ' ' ' ' &TEX FS01CO)

             D1         LABEL(BSFSFAPA) LIB(FICHEROS)

             CRTDUPOBJ  OBJ(BS) FROMLIB(FICHEROS) OBJTYPE(*FILE) +
                          TOLIB(FICHEROS) NEWOBJ(BSFSFAPA) DATA(*YES)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*35*/
/*********************************************************************/
/**   DESDE BS/CONTROFS ---> BSEMPREL/CONTREML (EXTRACTOS LASER)    **/
/*********************************************************************/
 RE35:       CALL       PGM(EXPLOTA/TRACE) PARM('DESDE: BS/CONTROFS +
                          ---> CREAR: BSEMPREL/CONTREML' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/BSEMPREL) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BSOLD) +
                          TEXT('BS -EXTRACTO LASER-') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BSEMPREL))

             CRTPF      FILE(FICHEROS/CONTREML) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(CONTROFS) TEXT('CONTROFS -EXTRACTO +
                          LASER-') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CONTREML))
/*---*/
             CPYF       FROMFILE(FICHEROS/BS) +
                          TOFILE(FICHEROS/BSEMPREL) +
                          MBROPT(*REPLACE) FROMRCD(1) FMTOPT(*NOCHK)
             CPYF       FROMFILE(FICHEROS/CONTROFS) +
                          TOFILE(FICHEROS/CONTREML) +
                          MBROPT(*REPLACE) FROMRCD(1) FMTOPT(*NOCHK)
/*---*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, DE ENTRADA EN +
                          CL.FS01COLAS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSEMPREL FICHEROS +
                          BSEMPREL LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTREML FICHEROS +
                          CONTREML LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*36*/
/*********************************************************************/
/*=================================================================*/
/* FICHEROS MSOCIO87, MSOCIO88 Y ECTASCON PARA ATRIUM  (label+AT)  */
/* PGM-ATRMODEST01: MIGRAR ESTADISTICAS DE SOCIOS FACTURADOS       */
/* RENAME DE -BS- A -BSGENE- Y RENAME DE -CONTROFS- A -CONTROGE-   */
/*=================================================================*/
/*********************************************************************/
 RE36:       CALL       PGM(EXPLOTA/TRACE) PARM('    FICHEROS PARA +
                          LIBRERIA ATRIUM: MSOCIO88 Y +
                          ECTASCON.                       ' ' ' FS01CO)

             CHGJOB     DATE(&FECHA)

             CPYF       FROMFILE(FICHEROS/MSOCIO88) +
                          TOFILE(FICHEROS/MSOCIO88AT) MBROPT(*ADD) +
                          CRTFILE(*YES) FROMRCD(1) FMTOPT(*NOCHK) +
                          ERRLVL(500)

             CPYF       FROMFILE(FICHEROS/ECTASCON) +
                          TOFILE(FICHEROS/ECTASCONAT) +
                          MBROPT(*REPLACE) CRTFILE(*YES) FROMRCD(1) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, MSOCIO88AT PDTE. +
                          -MIGRAC. DIARIA- A ATRIUM')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88AT +
                          FICHEROS MSOCIO88AT LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, ECTASCONAT PDTE. +
                          -MIGRAC. DIARIA- A ATRIUM')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ECTASCONAT +
                          FICHEROS ECTASCONAT LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)

/*-----------------------------------------------*/
/* MIGRACION ESTADISTICAS DE CRUCE (ECTASCON)  */
/*-----------------------------------------------*/
             ADDLIBLE   LIB(ATRIUM)
             MONMSG     MSGID(CPF0000)

             CALL       PGM(EXPLOTA/ATRMOEST01) PARM('F')

             RMVLIBLE   LIB(ATRIUM)
             MONMSG     MSGID(CPF0000)
/*-----------------------------------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('    Guardar BS en +
                          BSGENE y CONTROFS en CONTROGE  (Seguridad +
                          Auxiliar)         ' ' ' FS01CO)

             RNMOBJ     OBJ(FICHEROS/CONTROFS) OBJTYPE(*FILE) +
                          NEWOBJ(CONTROGE)

             RNMOBJ     OBJ(FICHEROS/BS) OBJTYPE(*FILE) NEWOBJ(BSGENE)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*37*/
/*-------------------------------------------------------------------*/
/*  EXTRACTOS EN PDF                                               */
/*-------------------------------------------------------------------*/
 RE37:       D1         LABEL(FESOCI_PDF) LIB(FICHEROS)

             CHGJOB     DATE(&FECHA)
             CRTPF      FILE(FICHEROS/FESOCI_PDF) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(FESOCI_PDF) TEXT('Extractos en PDF +
                          a nivel de socios -desglosado-') +
                          OPTION(*NOLIST *NOSRC) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)

             CALL       PGM(EXPLOTA/FESOCI1)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*38*/
/*--------------------------------------------------------------------------*/
/*  SE VERIFICA QUE NO HAYA UN FESOCI_PDF PENDIENTE DE EXPORTAR           */
/*  20120830 AHMED SE DEJA DE ENVIAR A MICRO                              */
/*--------------------------------------------------------------------------*/
 RE38:
             RTVMBRD    FILE(FICHEROS/FESOCI_PDF) NBRCURRCD(&NUMREG)

             CHGJOB     DATE(&FECHA)
             IF         COND(&NUMREG > 0) THEN(DO)

             CHGVAR     VAR(&ESTADO) VALUE(' ')
/*           CALL       PGM(EXPLOTA/CTREXPORT1) PARM('PCFICHEROS' +
                          'FESOCI_PDF' &ESTADO)                         */
             IF         COND(&ESTADO *NE ' ') THEN(DO)

             CHGVAR     VAR(&DESCRIP) VALUE('EXISTE UN +
                          FESOCI_PDF/PCFICHEROS PENDIENTE DE +
                          EXPORTAR SE RNMOBJ FESOCI_PD2')

             CHGVAR     VAR(&MSG) VALUE(&DESCRIP)

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01CO,   ') +
                          LONGMSG(&MSG)

             CALLSUBR   SUBR(INCIDENCIA)

             D1         LABEL(FESOCI_PD2) LIB(PCFICHEROS)

             RNMOBJ     OBJ(PCFICHEROS/FESOCI_PDF) OBJTYPE(*FILE) +
                          NEWOBJ(FESOCI_PD2)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*39*/
/*--------------------------------------------------------------------------*/
/*  "FESOCI_PDF" PARA "MICROINFORMATICA"                                  */
/*  20120830 AHMED SE DEJA DE ENVIAR A MICRO                              */
/*--------------------------------------------------------------------------*/
 RE39:       D1         LABEL(FESOCI_PDF) LIB(PCFICHEROS)
             CHGJOB     DATE(&FECHA)

 /*          CRTDUPOBJ  OBJ(FESOCI_PDF) FROMLIB(FICHEROS) +
                          OBJTYPE(*FILE) TOLIB(PCFICHEROS) +
                          NEWOBJ(FESOCI_PDF) DATA(*YES)                      */

/*           OVRDBF     FILE(FESOCI_PDF) TOFILE(PCFICHEROS/FESOCI_PDF)       */
/*           CALL       PGM(EXPLOTA/MICSOEMAIL) PARM('FESOCI_PDF' +
                          &MSG &MM)                                          */
/*           DLTOVR     FILE(FESOCI_PDF)                                     */

/*--------------------------------------------------------------------------*/
/*  Control de ficheros a exporta a SQL Server  (Fichero: EXPORT_SQL)     */
/*  20120830 AHMED SE DEJA DE ENVIAR A MICRO                              */
/*--------------------------------------------------------------------------*/
/*           CHGVAR     VAR(&CLAVES) +
                          VALUE('FESOCI_PDF                    ')           */
/*           CALL       PGM(EXPLOTA/CTREXPORTA) PARM('PCFICHEROS' +
                          'FESOCI_PDF' &CLAVES &AGRUP1 &AGRUP2)             */
             CHGVAR     VAR(&CLAVES) VALUE(' ')
/*--------------------------------------------------------------------------*/
/*  COPIAS DE SEGURIDAD                                                   */
/*--------------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, FESOCI_PDF CREADO +
                          PGM-FESOCI1')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FESOCI_PDF +
                          FICHEROS FESOCI_PDF LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*40*/
/*********************************************************************/
/*  ============================================================== */
/*  ==    F S 0 1 C O L A S   (NUEVOS EXTRACTOS)  JULIO-2002    == */
/*  ============================================================== */
/*********************************************************************/
/*--------------------------------------------------------------------------*/
 RE40:       CALL       PGM(EXPLOTA/FS01COLASM) PARM(&FECHA &SEAT +
                          &RESPU)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*41*/
/*********************************************************************/
/**      RENAME del -BSGENE-   (General)  a -BS-       (General)    **/
/**      RENAME del -CONTROGE- (General)  a -CONTROFS- (General)    **/
/*********************************************************************/
 RE41:       CALL       PGM(EXPLOTA/TRACE) PARM('                 +
                          VOLVEMOS A DEJAR -BS/CONTROFS- +
                          (GENERAL)                     ' ' ' FS01CO)

             DLTF       FILE(FICHEROS/BS)       /* Extrac.Normal */
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(FICHEROS/CONTROFS) /* Extrac.Normal */
             MONMSG     MSGID(CPF0000)

             RNMOBJ     OBJ(FICHEROS/CONTROGE) OBJTYPE(*FILE) +
                          NEWOBJ(CONTROFS) /* General */

             RNMOBJ     OBJ(FICHEROS/BSGENE) OBJTYPE(*FILE) +
                          NEWOBJ(BS) /* General */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*42*/
/*-------------------------------------------------------------------*/
/*-- RPG. FSCRECON  CREA: CONTROEU (UN REGTRO.POR CADA TITULAR -EU-) */
/*-------------------------------------------------------------------*/
 RE42:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  FSCRECON  +
                          EN EJECUCION.' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             D1         LABEL(CONTRL1) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/CONTRL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -CONTROFS- PARA RPG.FSCRECON') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)

             D1         LABEL(RECIBL2) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL2) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -RECIBOS- PARA RPG.FSCRECON') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)

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
             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSCRECON')
             CALL       PGM(CONCOPCL) PARM(CONTROEU FICHEROS +
                          CONTROEU LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*43*/
/*-------------------------------------------------------------------*/
/*-- RPG. CEREFS    "ACUMULACION A LA BOLSA DE RECIBOS"            --*/
/*-- CLP. EVIADDCL  -GENERACION AUTOMATICA EVIDENCIAS CONTABLES    --*/
/*-------------------------------------------------------------------*/
 RE43:       CL1        LABEL(CTLREC) LIB(FICHEROS)
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA CEREFS EN +
                          EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

 VERECI:     CHGVAR     VAR(&ACCION) VALUE('C')
             CALL       PGM(PRFICCTL) PARM(&ACCION 'CTLFS01   ')

             IF         COND(&ACCION = 'S') THEN(DO)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: EL FICHEROS +
                          -CTLFS01- ESTA CREADO UN PROCESO DE +
                          RECIBOS NO HA TERMINADO BIEN O HAY +
                          DESCUADRES*-FS01COM-  CONCILIACION +
                          **LLAMAR A Diners Club Spain'' --S--Seguir')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)
             GOTO       CMDLBL(VERECI)
             ENDDO
/*---*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, ANTES DE PGM-CEREFS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BORECI FICHEROS +
                          BORECI LIBSEG30D C ' ' ' ' &TEX FS01CO)

             D1         LABEL(RECIBL1) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -RECIBOS- PARA RPG.CEREFS') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)

             D1         LABEL(RECIBL2) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL2) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -RECIBOS- PARA RPG.CEREFS') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)

             CRTPF      FILE(FICHEROS/ASIRECFS) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFIVA) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIRECFS))

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

/*---*/
             CALL       PGM(EXPLOTA/FCRECI) /* Ver Vto. Recibos */

/*------------------------------------------------------------------*/
/* Respaldo del Fichero RECIBOS antes del CEREFS      LMG 20-08-2025*/
/*------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01COM, ANTES DEL +
                          PGM-CEREFS')
             CALL       PGM(CONCOPCL) PARM(RECIBOS FICHEROS +
                          RECIBOS LIBSEG30D C ' ' ' ' &TEX FS01CO)
/*------------------------------------------------------------------*/

             CALL       PGM(EXPLOTA/CEREFS) /* Acumular Recibos */

/*---*/
             CALL       PGM(EXPLOTA/TRACE) PARM('cuadre BORECI  CON +
                          TOTALES' ' ' FS01CO)
/*---*/
             CALLSUBR   SUBR(CUADRERECI)
/*---*/
             D1         LABEL(RECIBL1) LIB(FICHEROS)
             D1         LABEL(RECIBL2) LIB(FICHEROS)

 /* ========================================================== */
 /*  TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL      */
 /* ========================================================== */
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('** SOLUCION AUNA: +
                          TRAS -CEREFS- REVISAR FICHERO +
                          BORECI.                **     ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)

    /*       CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')    */
    /*       CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')    */

 /* ========================================================== */
/*-------------*/
/* PGM-EVIADDCL*/
/*-------------*/
            /* CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVICEREFS ' +
                          'ASIRECFS  ' 'ACUMULACION DE RECIBOS A LA +
                          BOLSA -BORECI-        ' 'FS01CO    ' +
                          '      ' ' ')*/
             CHGJOB     DATE(&FECHA)
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

             /* Respaldo de Parciales Apuntes Contables Evidencias*/
             CHGVAR     VAR(&TEX) VALUE('FS01COM - DI - EVIDENCIAS +
                            CONT. CEREFS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETECERE FICHEROS +
                          DETECERE LIBSEG1D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABECERE FICHEROS +
                          CABECERE LIBSEG1D C ' ' ' ' &TEX FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01COM - DI APUNTES +
                            CONT. DESPUES DEL CEREFS')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFS FICHEROS +
                          ASIRECFS LIBSEG1D C ' ' ' ' &TEX FS01CO)

             Clrpfm  Ficheros/ASIRECFS
                   ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*44*/
/*-------------------------------------------------------------------*/
/*--         ACUMULACION FICHEROS ASIENTOS DE "RECIBOS"            --*/
/*-------------------------------------------------------------------*/
 RE44:       CRTPF      FILE(FICHEROS/ASIRECFS2) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIRECFS2))
/*-------------------*/
/*- CAMBIO DE FECHA -*/
/*-------------------*/
             /*OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIRECFS)*/
             /*CALL       PGM(EXPLOTA/FCTIME)*/
             /*DLTOVR     FILE(ASIFILE)*/

             /*OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASIRECFS)*/
             /*OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIRECFS2)*/
             /*CALL       PGM(EXPLOTA/ASICO2)*/

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA ACASBO EN +
                          EJECUCION.' ' ' FS01CO)

             /*CALL       PGM(EXPLOTA/ACASBO) PARM('002')*/

             CALL       PGM(EXPLOTA/TRACE) PARM('Comprobar que se +
                          han acumulado al totales los asientos de +
                          los recibos y que  ' ' ' FS01CO)

           /*DLTOVR     FILE(ASIFILE ASIFIVA)  */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*45*/
/*-------------------------------------------------------------------*/
/*-- RPG.CAREBA  -CREA CALENDARIO DE RECIBOS PENDIENTES DE VENCER- --*/
/*-------------------------------------------------------------------*/
 RE45:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  CAREBA  +
                          EN EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTLF      FILE(FICHEROS/BORECLG2) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000

             CHGJOB     DATE(&FECSYS)                 /*Fecha Sistema*/

             CALL       PGM(EXPLOTA/CAREBA)

             CALLSUBR   SUBR(CUADRERECI)

             CHGJOB     DATE(&FECHA) /* Fecha Facturación */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*46*/
/*-------------------------------------------------------------------*/
/*--           COPIAS DE SEGURIDAD DESPUES DEL RPG.CEREFS          --*/
/*-------------------------------------------------------------------*/
RE46:        CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-CEREFS')

             /*CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFS FICHEROS +
                          ASIRECFS LIBSEG30D M ' ' ' ' &TEX FS01CO)*/

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIRECFS2 +
                          FICHEROS ASIRECFS2 LIBSEG1D M ' ' ' ' +
                          &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BORECI FICHEROS +
                          BORECI LIBSEG30D C ' ' ' ' &TEX FS01CO)

             D1         LABEL(CTLREC) LIB(FICHEROS)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*47*/
/*-------------------------------------------------------------------*/
/*--  RPG.FSCREBO   -SUBSIDIARIAS DE EXTRACTO UNIFICADO A "BOREUN" --*/
/*--  CLP.EVIADDCL  -GENERACION AUTOMATICA EVIDENCIAS CONTABLES    --*/
/*-------------------------------------------------------------------*/
 RE47:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -FSCREBO- +
                          EN EJECUCION.' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, ANTES DEL +
                          PGM-FSCREBO ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOREUN FICHEROS +
                          BOREUN LIBSEG30D C ' ' ' ' &TEX FS01CO)

             D1         LABEL(CONTRL1) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/CONTRL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -CONTROFS- PARA RPG.FSCREBO') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)

             D1         LABEL(RECIBL3) LIB(FICHEROS)
             CRTLF      FILE(FICHEROS/RECIBL3) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -RECIBOS- PARA RPG.FSCREBO') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)

             CRTLF      FILE(FICHEROS/BOREUNL1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -BOREUN- PARA RPG.FSCREBO') +
                          OPTION(*NOLIST *NOSRC) LVLCHK(*NO) AUT(*ALL)
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

             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : +
                          EXISTE FICHERO RECMSOREC. SI ES UN +
                          REARRANQUE DEL RPG.FSCREBO SE' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('VA A DEJAR EL +
                          MSOCIO COMO ESTABA ANTES DE REEJECUTAR EL +
                          RPG.FSCREBO.          ' ' ' FS01CO)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: EXISTE +
                          FICHERO RECMSOREC. SI ES UN REARRANQUE,SE +
                          VA A DEJAR EL MSOCIO COMO ESTABA ANTES DE +
                          REEJECUTAR EL RPG.FSCREBO **LLAMAR A +
                          DINERS CLUB SPAIN')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)
/*---*/
 NORECUMS:   CRTPF      FILE(FICHEROS/RECMSOREC) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('Rearranque rpg.fscrebo -RECUPERAR- +
                          msocio') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
/*---*/
 SIRECUMS:   OVRDBF     FILE(BOLINGSO) TOFILE(FICHEROS/BOLINGSOEU)
             OVRDBF     FILE(FA)       TOFILE(FICHEROS/FACOMPEEU)
             OVRDBF     FILE(ASIFILE)  TOFILE(FICHEROS/ASIFSCREBO)
             OVRDBF     FILE(RECMSORE) TOFILE(FICHEROS/RECMSOREC)
             OVRDBF     FILE(IMP00P10) TOFILE(FICHEROS/EVIFSCREBO)

             CALL       PGM(EXPLOTA/FSCREBO) PARM(&CODRET)

             DLTOVR     FILE(BOLINGSO FA ASIFILE RECMSORE)
             DLTOVR     FILE(IMP00P10)
/*---*/
             IF         (&CODRET *EQ '1') THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM('. Recoger impreso y +
                          cuadrar -FSCREBO- con el TOTALES  +
                          "SDOS.COMPENSADOS -EU-"' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('. y +
                          "TRANSFERENCIAS".' ' ' FS01CO)


             CALLSUBR   SUBR(CUADREFA)
             /*-------------*/
             /* PGM-EVIADD  */
             /*-------------*/
             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVIFSCREBO' +
                          'ASIFSCREBO' 'COMPENSACION DE SALDOS DE +
                          EXTRACTO UNIFICADO      ' 'FS01CO    ' +
                          '      ' ' ')
             CHGJOB     DATE(&FECHA)

             ENDDO

             /*-------------*/
/*---*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOREUN FICHEROS +
                          BOREUN LIBSEG30D C ' ' ' ' &TEX FS01CO)
             D1         LABEL(CONTRL1) LIB(FICHEROS)
             D1         LABEL(BORECL3) LIB(FICHEROS)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*48*/
/*-------------------------------------------------------------------*/
/*--  ADICION -FACOMPEEU- "EXTRACTO UNIFICADO" A -FASALE-          --*/
/*-------------------------------------------------------------------*/
 RE48:       CALL       PGM(EXPLOTA/TRACE) PARM('ADICION DEL +
                          -FACOMPEEU- A -FASALE-          ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

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

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FACOMPEEU +
                          FICHEROS FACOMPEEU LIBSEG30D M ' ' ' ' +
                          &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*49*/
/*-------------------------------------------------------------------*/
/*--  ADICION -BOLINGSOEU-  "EXTRACTO UNIFICADO" A -BOLINGSO-      --*/
/*--  Y CALENDARIO POR VENCIMIENTOS PGM-FEINGS                     --*/
/*-------------------------------------------------------------------*/
 RE49:       CALL       PGM(EXPLOTA/TRACE) PARM('ADICION DEL +
                          -BOLINGSOEU- A -BOLINGSO-        ' ' ' +
                          FS01CO)
             CHGJOB     DATE(&FECHA)

             CPYF       FROMFILE(FICHEROS/BOLINGSOEU) +
                          TOFILE(FICHEROS/BOLINGSO) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOLINGSOEU +
                          FICHEROS BOLINGSOEU LIBSEG30D M ' ' ' ' +
                          &TEX FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DE ADICION +
                          -BOLINGSOEU-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BOLINGSO FICHEROS +
                          BOLINGSO LIBSEG30D C ' ' ' ' &TEX FS01CO)
/*-------------*/
/* PGM-FEINGS  */
/*-------------*/
             RTVMBRD    FILE(FICHEROS/BOLINGSO) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       EXPLOTA/FEINGS
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*50*/
/*-------------------------------------------------------------------*/
/*--                  RPG.  F S C R E A                            --*/
/*-------------------------------------------------------------------*/
 RE50:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  FSCREA  +
                          EN EJECUCION.' ' ' FS01CO)

             CHGJOB     DATE(&FECHA)
/*----------------------------------------------------------------*/
/* ESTAS COPIAS SON PARA EL PROGRAMA 'POSICION' MIENTRAS DURA EL  */
/* PROCESO DEL FSCREA                                             */
/*----------------------------------------------------------------*/
             CRTDUPOBJ  OBJ(PA) FROMLIB(FICHEROS) OBJTYPE(*FILE) +
                          NEWOBJ(PAFSCREA) DATA(*YES)

             CRTDUPOBJ  OBJ(FA) FROMLIB(FICHEROS) OBJTYPE(*FILE) +
                          NEWOBJ(FAFSCREA) DATA(*YES)
/*----------------------------------------------------------------*/

             FMTDTA     INFILE((FICHEROS/CONTROFS)) +
                          OUTFILE(FICHEROS/CONTROFS) +
                          SRCFILE(EXPLOTA/QCLSRC) SRCMBR(STATEC) +
                          OPTION(*NOPRT)

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

             /*---------------------------------*/
             /* Reorganizamos los ficheros:     */
             /*      PASALE  (DI + MC)          */
             /*      FASALE  (DI + MC)          */
             /*---------------------------------*/
             RGZPFM FILE(FICHEROS/FASALE) KEYFILE(*FILE)
             RGZPFM FILE(FICHEROS/PASALE) KEYFILE(*FILE)

             CALL       PGM(EXPLOTA/FSCREA)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, entrada DE PROGRAMA +
                          FSCREA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAFSCREA FICHEROS +
                          PAFSCREA LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAFSCREA FICHEROS +
                          FAFSCREA LIBSEG1D M ' ' ' ' &TEX FS01CO)

 /* ========================================================== */
 /*  TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL - TEMPORAL      */
 /* ========================================================== */
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('** SOLUCION AUNA: +
                          TRAS -FSCREA- REVISAR FICHEROS PA Y FA +
                          (COD.0 Y 2)   **     ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('**===================================+
                          ==================================**     +
                          ' ' ' FS01CO)

     /*      CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')       */
     /*      CALL       PGM(EXPLOTA/TRACE) PARM(' ' ' ' ' ')       */

 /* ========================================================== */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*51*/
/*-------------------------------------------------------------------*/
/*--          CUADRAR TOTALES DE -FA- Y -PA-  CREADOS              --*/
/*-------------------------------------------------------------------*/
 RE51:       CALLSUBR   SUBR(CUADREFA)
             CALLSUBR   SUBR(CUADREPA)
/*---*/
             CRTLF      FILE(FICHEROS/PALG5) +
                          SRCFILE(FICHEROS/QDDSSRC) OPTION(*NOSRC +
                          *NOLIST) LVLCHK(*NO)
             MONMSG     CPF0000

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETE34) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE34) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('FS01CO  , DESPUES DEL +
                          PGM-FSCREA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE34 FICHEROS +
                          DETE34 LIBSEG1D M ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE34 FICHEROS +
                          CABE34 LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*52*/
/*-------------------------------------------------------------------*/
/*--  ACTUALIZA -MSOCIO/ECTASCON- CONDICION EXTRACTO: YA REALIZADO --*/
/*-------------------------------------------------------------------*/
 RE52:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  FCPOSO  +
                          EN EJECUCION.' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/FCPOSO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FCPOSO -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ECTASCON FICHEROS +
                          ECTASCON LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*53*/
/*-------------------------------------------------------------------*/
/*     PROGRAMA ABEN01 -SDOS ACREEDORES ABENGOA Y VIRTUALES          */
/*-------------------------------------------------------------------*/
 RE53:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  ABEN01  +
                          EN EJECUCION (ABENGOA)' ' ' FS01CO)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/ABEN01) PARM('10064537')

         /*----------------------------------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  ABEN01  +
                          EN EJECUCION (INDITEX)' ' ' FS01CO)

             CALL       EXPLOTA/ABEN01 PARM('10020374')

         /*----------------------------------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  ABEN01  +
                          EN EJECUCION (BSH)' ' ' FS01CO)

             CALL       EXPLOTA/ABEN01 PARM('10080423')

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*54*/
/*-------------------------------------------------------------------*/
/*--                SALVO:  -PA- Y -FA-  (NUEVOS)                  --*/
/*-------------------------------------------------------------------*/
RE54:        CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSCREA -CONCILIACION-')
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FA FICHEROS FA +
                          LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSCREBO')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECMSOREC +
                          FICHEROS RECMSOREC LIBSEG30D M ' ' ' ' +
                          &TEX FS01CO)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*55*/
/*-------------------------------------------------------------------*/
/*--        CREACION LOGICOS: PA  --OPCIONES CONCILIACION--        --*/
/*-------------------------------------------------------------------*/
 RE55:       CALL       PGM(EXPLOTA/TRACE) PARM('            +
                          CREACION LOGICOS -PA- PARA DEPART.  +
                          CONCILIACION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTLF      FILE(FICHEROS/PALG) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa-') OPTION(*NOLIST *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLG1) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLG3) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLG4) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLG8) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLG9) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLGA) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLGC) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CRTLF      FILE(FICHEROS/PACONLGF) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -pa- conciliación') OPTION(*NOLIST +
                          *NOSRC) LVLCHK(*NO)
             MONMSG     MSGID(CPF0000)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*56*/
/*-------------------------------------------------------------------*/
/*--              C O P I A S  Y   D E L E T E S                   --*/
/*-------------------------------------------------------------------*/
 RE56:       CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0062' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSACTMEM/FSACTMEMFI')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MEMPRE FICHEROS +
                          MEMPRE LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FCFAPA -CONCILIACION-')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FASALE FICHEROS +
                          FASALE LIBSEG30D C ' ' ' ' &TEX FS01CO)
             DLTF       FICHEROS/FASALE

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PASALE FICHEROS +
                          PASALE LIBSEG30D C ' ' ' ' &TEX FS01CO)
             DLTF       FICHEROS/PASALE

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FAPA88 FICHEROS +
                          FAPA88 LIBSEG30D C ' ' ' ' &TEX FS01CO)
             DLTF       FICHEROS/FAPA88

     /*------------------------------------------------------------------*/
     /* 25-7-2019 SE DECIDE QUITARLO DE LIBSEG30D                        */
     /*------------------------------------------------------------------*/
     /*      CHGVAR     VAR(&TEX) VALUE('FS01CO, MSOCIO88 DESPUES +      */
     /*                   DEL PGM-FCFAPA           ')                    */
     /*      CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88 FICHEROS +   */
     /*                   MSOCIO88 LIBSEG30D C ' ' ' ' &TEX FS01CO)      */
     /*------------------------------------------------------------------*/
             D1         LABEL(CONTROEU)   LIB(FICHEROS)
             D1         LABEL(FSANUAL)    LIB(FICHEROS)
             D1         LABEL(ERRDESCR)   LIB(FICHEROS)
             D1         LABEL(PLARESER)   LIB(FICHEROS)
             D1         LABEL(FESOCI_PDF) LIB(FICHEROS)
             D1         LABEL(CUOTEFAC)   LIB(FICHEROS)
             D1         LABEL(BSCUOTE05)  LIB(FICHEROS)
             D1         LABEL(FACTURA05)  LIB(FICHEROS)
             D1         LABEL(CABEVI05)   LIB(FICHEROS)
             D1         LABEL(DETEVI05)   LIB(FICHEROS)

/*---*/
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*57*/
/*-------------------------------------------------------------------*/
/*--  CONTROFS A CONTROCON PARA MISES DE EMPRESAS EN CONCILIACION  --*/
/*-------------------------------------------------------------------*/
 RE57:       RNMOBJ     OBJ(FICHEROS/CONTROFS) OBJTYPE(*FILE) +
                          NEWOBJ(CONTROCON)

             CHGJOB     DATE(&FECHA)
/*-------------------------------------------------------------------*/
/*--                 RPG.  F S P A F A                             --*/
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('Programa -FSPAFA- +
                          en Ejecucion' ' ' FS01CO)

             /*CRTPF      FILE(FICHEROS/ASIFSPAFA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFIVA) +
                          TEXT('asiento traspaso PA a FA') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)*/

             /*CHKOBJ     OBJ(FICHEROS/EVIPAFA) OBJTYPE(*FILE)*/
             /*MONMSG     MSGID(CPF9801) EXEC(DO) */
             /*   CL1        LABEL(EVIPAFA) LIB(FICHEROS) LON(132)*/
             /*ENDDO  */

             /*OVRDBF     FILE(ASIFIVA) TOFILE(FICHEROS/ASIFSPAFA)*/
             /*CALL       PGM(EXPLOTA/FSPAFA)*/

     /*--------------------------------------------------------*/
     /*    Nueva version del FSPAFA                            */
     /*--------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01COM, ANTES DEL +
                        PGM-FSPAFAN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS       FICHEROS +
                        BS       LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CRTPF      FILE(FICHEROS/ASIPAFAN) +
                        SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILEN) +
                        TEXT('Asientos FSPAFAN') +
                        OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                        LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                        FILE(FICHEROS/ASIPAFAN))

             CRTPF      FILE(FICHEROS/DETEPAFA) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETEPAFA))

             CRTPF      FILE(FICHEROS/CABEPAFA) +
                        SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                        OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                        FILE(FICHEROS/CABEPAFA))

             DLTOVR     FILE(*ALL)
             OVRDBF     FILE(ASIFILEN) TOFILE(FICHEROS/ASIPAFAN) +
                        OVRSCOPE(*JOB)
             OVRDBF     FILE(BS)      TOFILE(FICHEROS/BS)
             CALL       PGM(EXPLOTA/FSPAFAN)
             DLTOVR     FILE(ASIFILEN) LVL(*JOB)
             DLTOVR     FILE(BS)
             DLTOVR     FILE(*ALL)

             RTVMBRD    FILE(FICHEROS/ASIPAFAN) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 0) THEN(DO)

              CPYF       FROMFILE(FICHEROS/DETEPAFA) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)
              MONMSG     MSGID(CPF0000)

              CPYF       FROMFILE(FICHEROS/CABEPAFA) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)
              MONMSG     MSGID(CPF0000)

              OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIPAFAN)
              CALL       PGM(EXPLOTA/ACASBON) PARM('002')
              DLTOVR     FILE(ASIFILE)

             CHGVAR     VAR(&TEX) VALUE('FS01COM, DESPUES DEL +
                        PGM-FSPAFAN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEPAFA FICHEROS +
                        DETEPAFA LIBSEG1D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEPAFA FICHEROS +
                        CABEPAFA LIBSEG1D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIPAFAN FICHEROS +
                        ASIPAFAN LIBSEG1D C ' ' ' ' &TEX FS01CO)

             ENDDO
         /*--------------------------------------------------------*/


             RTVMBRD    FILE(FICHEROS/BSSALTA) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG = 0) THEN(GOTO CMDLBL(NOSALBS))

             OVRDBF     FILE(BS) TOFILE(FICHEROS/BSSALTA)

             CALL       PGM(EXPLOTA/FSPAFA)

             DLTOVR     FILE(BS)

 NOSALBS:    CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*58*/
/*-------------------------------------------------------------------*/
/*                --- DEPARTAMENTO CONTABILIDAD ---                  */
/* Conciliación Cuentas de Viajes (Situación Ficheros: PA y PTEPREPR */
/*-------------------------------------------------------------------*/
 RE58:       CALL       PGM(EXPLOTA/TRACE) PARM('Programa +
                          -CONBPR/CONBAG en Ejecución' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/CONBPR) /* Bolsa Proveedores */
             CALL       PGM(EXPLOTA/CONBAG) /* Bolsa Agencia     */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*59*/
/*-------------------------------------------------------------------*/
/*     ESPECIAL (23.6.08) SITUACION BOLSAS DESPUES DE CADA CIERRE.   */
/*                                                                   */
/* 1º FICHERO PARCIAL -PAHICOSIBO- PARA MICROINFORMATICA -EXPORT_SQL-*/
/* 2º FICHERO HISTORICO -HICOSIBO- PARA LUIS PEREZ (LIB.CONTAPC)     */
/*                                                                   */
/*     ESPECIAL (14.9.09) NETO ENTRE BOLSAS DESPUES DE CADA CIERRE.  */
/*     -----------------------------------------------------------   */
/* 1º FICHERO PARCIAL -HICOSIBO_P- PARA MICROINFORMATICA -EXPORT_SQL-*/
/*-------------------------------------------------------------------*/
 RE59:       CALL       PGM(EXPLOTA/COSIBOCL) PARM(&FECHA &SEAT &RESPU)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/CONEBOCL) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*60*/
/*-------------------------------------------------------------------*/
/*             RPG.  A C A S B O   -ACUMULACION DE ASIENTOS-         */
/*-------------------------------------------------------------------*/
 RE60:       CRTPF      FILE(FICHEROS/ASIFS01) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILE) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFS01))

             CRTPF      FILE(FICHEROS/ASIFS02) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ASIFILEN) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CLRPFM +
                          FILE(FICHEROS/ASIFS02))

             CPYF       FROMFILE(FICHEROS/ASIFAPA) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)

             CPYF       FROMFILE(FICHEROS/ASIBALAN) +
                          TOFILE(FICHEROS/ASIFS02) MBROPT(*ADD)

             /*CPYF       FROMFILE(FICHEROS/ASIFSPAFA) +          */
             /*             TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD) */

             CPYF       FROMFILE(FICHEROS/ASIFSCRE) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)
             MONMSG     CPF0000

             CPYF       FROMFILE(FICHEROS/ASIFSCREBO) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)
             MONMSG     CPF0000

             CHKOBJ     OBJ(FICHEROS/ASICUOTE05) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOHAY1))
             CPYF       FROMFILE(FICHEROS/ASICUOTE05) +
                          TOFILE(FICHEROS/ASIFS02) MBROPT(*ADD)
             CHGVAR     VAR(&TEX) VALUE('FS01CO,  ASIENTOS +
                          -CONCILIACION-                  ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASICUOTE05 +
                          FICHEROS ASICUOTE05 LIBSEG1D M ' ' ' ' +
                          &TEX FS01CO)
 NOHAY1:
/*------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                      PROGRAMA +
                          FCTIME/ACASBO EN EJECUCION.' ' ' FS01CO)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFS01)
             CALL       PGM(EXPLOTA/FCTIME)
             CALL       PGM(EXPLOTA/ACASBO) PARM('002')
             DLTOVR     FILE(ASIFILE)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFS02)
             CALL       PGM(EXPLOTA/FCTIME)
             CALL       PGM(EXPLOTA/ACASBON) PARM('002')
             DLTOVR     FILE(ASIFILE)

/*------*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO,  ASIENTOS +
                          -CONCILIACION-                  ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIFAPA FICHEROS +
                          ASIFAPA LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIBALAN FICHEROS +
                          ASIBALAN LIBSEG1D M ' ' ' ' &TEX FS01CO)

        /*     CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIFSPAFA +
                          FICHEROS ASIFSPAFA LIBSEG30D M ' ' ' ' +
                          &TEX FS01CO)                                    */

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIFS01 FICHEROS +
                          ASIFS01 LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIFSCRE FICHEROS +
                          ASIFSCRE LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIFSCREBO +
                          FICHEROS ASIFSCREBO LIBSEG1D M ' ' ' ' +
                          &TEX FS01CO)

             D1         LABEL(BSSALTA) LIB(FICHEROS)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*61*/
/*-------------------------------------------------------------------*/
/*        GRUPO DE SBMJOB INTEGRADOS EN ESTE CL -SBMJOBCO-           */
/*-------------------------------------------------------------------*/
 RE61:       SBMQBATCH  NOMJOB(FS0103) FECPRO(&FECHA) DESBRE('grupo +
                          trabajos en batch') CMD('call +
                          explota/sbmjobco')

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*62*/
/*-------------------------------------------------------------------*/
/*             IMPRESION DE TODOS LOS ASIENTOS DE LA FAC.            */
/*-------------------------------------------------------------------*/
 RE62:       CALL       PGM(EXPLOTA/ASIACUCLM)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*63*/
/*-------------------------------------------------------------------*/
/*             ACUPACL2 -ACUMULACION DE UN PAPRE PENDIENTE-          */
/*-------------------------------------------------------------------*/
RE63:        CHKOBJ     OBJ(FICHEROS/PAPRE) OBJTYPE(*FILE)
             MONMSG     CPF0000 EXEC(GOTO NOPAPRE)
             CHGJOB     DATE(&FECHA)


             CALL       PGM(EXPLOTA/TRACE) PARM('* OJO, hay un PAPRE +
                          en la ficheros, esto solo puede ocurrir +
                          si en la ultima ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('* facturacion de +
                          estab., no se pudo acumular al +
                          PA.                       ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('* En ese caso +
                          debeis tener un aviso producido por el +
                          pgm-acupacl en el que se' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('* comenta este +
                          hecho.                                      -
                   ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('* Por lo tanto al +
                          pulsar intro se ejecutara el pgm-acupacl2 +
                          para que dicho    ' ' ' FS01CO)
             CALL       PGM(EXPLOTA/TRACE) PARM('* PAPRE se acumule +
                          ahora.                                      -
               ' ' ' FS01CO)

             CALL       PGM(EXPLOTA/ACUPACL2M) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)

 NOPAPRE:    CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*64*/
/*-------------------------------------------------------------------*/
/*--     ACUMULACION -BSFACIN- PARCIALES: BSFACINNO Y BSFACINLA    --*/
/*-------------------------------------------------------------------*/
 RE64:       CALL       PGM(EXPLOTA/TRACE) PARM('FUSION DE +
                          BSFACINNO/BSFACINLA A BSFACIN   ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/BSFACIN) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BSFACIN) +
                          TEXT('Extractos Soportes Magneticos +
                          CONCILIACION') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/BSFACIN))

             CPYF       FROMFILE(FICHEROS/BSFACINNO) +
                          TOFILE(FICHEROS/BSFACIN) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK) +
                          /* Extractos Normales */
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/BSFACINLA) +
                          TOFILE(FICHEROS/BSFACIN) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK) +
                          /* Extractos Laser */
             MONMSG     MSGID(CPF0000)
/*--------*/
/* COPIAS */
/*--------*/
             CHGVAR     VAR(&REST1) VALUE('BSCIN' *CAT %SUBSTRING+
                        (&FECHA 1 4))

             CHGVAR     VAR(&TEX) VALUE('FS01CO, FINAL DEL +
                          FS01CO     -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSFACIN FICHEROS +
                          &REST1 LIBSEG30D C ' ' ' ' &TEX FS01CO)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSFACIN FICHEROS +
                          &REST1 LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CHKOBJ     OBJ(FICHEROS/BSFACINLA) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOFACINLA))

             CHGVAR     VAR(&TEX) VALUE('FS01CO, SALIDO DE +
                          PGM.FSFACIN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSFACINLA +
                          FICHEROS BSFACINLA LIBSEG30D C ' ' ' ' +
                          &TEX FS01CO)
             DLTF      FICHEROS/BSFACINLA

 NOFACINLA:  CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*65*/
/*-------------------------------------------------------------------*/
/* Especial SEAT: Informe de Cajones Estadisticos   "Josep Canut"  */
/*-------------------------------------------------------------------*/
 RE65:       IF         COND(&SEAT *EQ 'SEAT') THEN(DO)
             CHGJOB     DATE(&FECHA)

               CALL       PGM(EXPLOTA/TRACE) PARM('                +
                          PROGRAMA -SEATCAJEST- EN EJECUCION    ' ' +
                          ' FS01CO)
               D1         LABEL(SEAT_ES) LIB(FICHEROS)
               CL1        LABEL(SEAT_ES) LON(132)

               OVRDBF     FILE(IMP00P12) TOFILE(FICHEROS/SEAT_ES)
               CALL       PGM(EXPLOTA/SEATCAJEST)
               DLTOVR     FILE(IMP00P12)

               ENMAIL3    SECU(0060) EMSG('FACTURACION DINERS +
                          -ESTADISTICAS GRUPO SEAT-') +
                          CLIB(FICHEROS) FICH(SEAT_ES) CARP(VARMAIL)

               CHGVAR     VAR(&TEX) VALUE('FS01CO, ESTADISTICAS SEAT +
                          SALIDA PGM-SEATCAJEST   ')
               CALL       PGM(EXPLOTA/CONCOPCL) PARM(SEAT_ES FICHEROS +
                          SEAT_ES LIBSEG1D M ' ' ' ' &TEX FS01CO)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*66*/
/*-------------------------------------------------------------------*/
/* FSELTECL Fich. Facturación para Empresas, Standar ó Especiales  */
/*-------------------------------------------------------------------*/
 RE66:
             CALL       PGM(EXPLOTA/FSELTECLM) PARM(&FECHA &CONCI)
             CHGJOB     DATE(&FECHA)
/*-----------------------------*/
             RTVMBRD    FILE(FICHEROS/FITEMFACSO) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG > 2 ) THEN(DO)

             CHGVAR     VAR(&MSG) VALUE('INVESTIGAR **EN LA +
                          TEMFACSO  HAY FICHERO/S DE CONCILIACION  +
                          FS01COM')

             SNDDST     TYPE(*LMSG) +
                          TOINTNET((operadores@dinersclub.es)) +
                          DSTD('FACTURACION SOCIOS     FS01COM   ') +
                          LONGMSG(&MSG)

             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*67*/
/*-------------------------------------------------------------------*/
/*=================================================================*/
/*       ¿ES LA ULTIMA FACT.DE TARJETAS CONCILIADAS DEL MES?       */
/*=================================================================*/
/*-------------------------------------------------------------------*/
 RE67:       IF         COND(&RESPU *EQ 'SI') THEN(DO)
/*-----------------------------------------*/
/*  LIMPIAR EN -MSOCIO- MARCAS QUE NOS   */
/*  INFORMA DEL ESTADO DE LOS EXTRACTOS  */
/*  DURANTE EL PERIODO DE CONCILIACION.  */
/*-----------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA -FCFIN- EN +
                          EJECUCION     ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/FCFIN)
/*-----------------------------------------*/
/* ESPECIAL MODIFICACIONES "ENDESA"      */
/*-----------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, ULTIMA FACTURACION +
                          DE CONCILIACION DEL MES')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MOENDESA FICHEROS +
                          MOENDESA LIBSEG1D C ' ' ' ' &TEX FS01CO)

             CLRPFM     FILE(FICHEROS/MOENDESA)
/*-----------------------------------------*/
/* TARJETAS BLOQUEADAS PROXIMO MES       */
/*-----------------------------------------*/
             CPYF       FROMFILE(FICHEROS/ECTASCON) +
                          TOFILE(FICHEROS/BLOECTAS) +
                          MBROPT(*REPLACE) FROMRCD(1) +
                          FMTOPT(*NOCHK) /* tarjetas bloqueadas +
                          proximo mes */
/*-----------------------------------------*/
/* ADICION: ESTADISTICAS DE EXTRACTOS    */
/*-----------------------------------------*/
             CPYF       FROMFILE(FICHEROS/ECTASCON) +
                          TOFILE(FICHEROS/HCTASCON) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK) /* Historico de +
                          Extractos */

             RMVPFTRG   FILE(FICHEROS/ECTASCON)
             D1         LABEL(ECTASCLG) LIB(FICHEROS)
             D1         LABEL(ECTASLG1) LIB(FICHEROS)
             D1         LABEL(ECTASLG2) LIB(FICHEROS)

/*----------------------*/
/* EXPORT_SQL: ECTASCON */
/*----------------------*/
             CHGVAR     VAR(&CLAVES) +
                          VALUE('ECTASCON                      ')

             CALL       PGM(EXPLOTA/CTREXPORCL) PARM(&FECHA +
                          'ECTASCON' 'FICHEROS' 'ECTASCON' +
                          'PCFICHEROS' &CLAVES &AGRUP1 &AGRUP2)
/*----------------------*/

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ECTASCON FICHEROS +
                          ECTASCON LIBSEG1D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BLOECTAS FICHEROS +
                          BLOECTAS LIBSEG1D C ' ' ' ' &TEX FS01CO)
/*----------------------*/
/* EXPORT_SQL: COPERATI */
/*----------------------*/
             CHGVAR     VAR(&CLAVES) +
                          VALUE('COPERATI                      ')

             CALL       PGM(EXPLOTA/CTREXPORCL) PARM(&FECHA +
                          'COPERATI' 'FICHEROS' 'COPERATI' +
                          'PCFICHEROS' &CLAVES &AGRUP1 &AGRUP2)
/*-----------------------------------------*/
/* LIMPIA: ESPECIAL COMISIONES "MICHELIN"*/
/*-----------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, ULTIMA FACTURACION +
                          DE CONCILIACION DEL MES')

/*-----------------------------------------*/
/* EFECTIVIDAD PROGRAMAS CRUCE           */
/*-----------------------------------------*/
             CALL       PGM(EXPLOTA/CONT34) PARM(' ' &FECHAX)
             CALL       PGM(EXPLOTA/CONT34) PARM('F' &FECHAX)   /* FICTICIO */

/*-----------------------------------------*/
/* INFORME MENSUAL AGENCIAS              */
/*-----------------------------------------*/
             CALL       PGM(EXPLOTA/CONT35) PARM(&FECHAX)
/*-----------------------------------------*/
/* ESTUDIO DESCONCILIADOS                */
/*-----------------------------------------*/
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/CONT37CL) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)
/*-----------------------------------------*/
/* MOVER OPERACIONES DE:                 */
/* BAGENCOND A BAGENHIS                  */
/* OPAGECO_B A OPAGECO                   */
/*-----------------------------------------*/
             CALL       PGM(EXPLOTA/ATR0002EDO)
             CHGJOB     DATE(&FECHA)
/*-----------------------------------------*/

             ENDDO

/*=================================================================*/
/*-------------------------------------------------------------------*/

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*68*/
 RE68:       CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*69*/
/*-------------------------------------------------------------------*/
/*                  ---  COPIAR EL MSOCIO  ---                       */
/*-------------------------------------------------------------------*/
 RE69:       CHGVAR     VAR(&TEX) VALUE('FS01CO, FIN PROCESO +
                          FACTURACION SOCIOS')
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(T_MSOCIO FICHEROS +
                          T_MSOCIO LIBSEG30D C ' ' ' ' &TEX FS01CO)

             IF         COND(&DD *GE 28) THEN(DO)
             CHGVAR     VAR(&TEX) VALUE('FS01CO, FIN PROCESO +
                          FACTURACION SOCIOS')
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*70*/
/*-------------------------------------------------------------------*/
/*                  -----------------------------                    */
/*                  -- CONTROL FIN FACT.SOCIOS --                    */
/*                  -----------------------------                    */
/*   ELIMINAR: FICHEROS DE CONTROL DE LAS OPCIONES DE CONCILIACION   */
/* RECO09: CREA "RECOBRO005" DESDE -MSOCIO- YA ACTUALIZADO.          */
/* RECO10_FPD: INFORECOBRO "IMPAGO DE SALDOS ATRASADOS "PAGO DIRECTO"*/
/* RECO10_FPB: INFORECOBRO "DEVOLUCIONES REFACTURADAS DE "PAGO BANCO"*/
/*-------------------------------------------------------------------*/
RE70:        D1         LABEL(BSFSFAPA)  LIB(FICHEROS)
             D1         LABEL(SICONTE1)  LIB(FICHEROS)
             D1         LABEL(SICONTE2)  LIB(FICHEROS)
             D1         LABEL(SICONTE3)  LIB(FICHEROS)
             D1         LABEL(MICHELIN)  LIB(FICHEROS)
             D1         LABEL(SAPNB_AUX) LIB(FICHEROS)
             CALL       PGM(PRFICCTL) PARM('B' 'NOPROC    ')

/*-------------------------------------*/
/*"InfoRecobro" FICHERO -RECOBRO005- */
/*-------------------------------------*/
/* PGM-RECO09, CON MSOCIO ACTUALIZADO  */
/*-------------------------------------*/
             CALL       PGM(TRACE) PARM('PROGRAMA -RECO09- EN +
                          EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/RECOBRO005) SRCMBR(RECOBRO001) +
                          TEXT('RECOBRO MICROINFORMATICA: +
                          FICHERO-0001') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/RECOBRO005))

             CRTLF      FILE(FICHEROS/GRANELG7) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('LOGICO +
                          -GRANEXFI-') OPTION(*NOLIST *NOSRC) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000)

             OVRDBF     FILE(RECOBRO001) TOFILE(FICHEROS/RECOBRO005)
             CALL       PGM(EXPLOTA/RECO09)
             DLTOVR     FILE(RECOBRO001)

/*-------------------------------------*/
/* "InfoRecobro" FICHERO -RECOBRO006-*/
/*    PGM-RECO10_FPD (PAGO DIRECTO)    */
/*-------------------------------------*/
             CALL       PGM(TRACE) PARM('PROGRAMA -RECO10_FPD- EN +
                          EJECUCION                                   -
        ' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CRTPF      FILE(FICHEROS/RECOBRO006) SRCMBR(RECOBRO002) +
                          TEXT('RECOBRO MICROINFORMATICA: +
                          FICHERO-0002') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/RECOBRO006))

             OVRDBF     FILE(MSOCIOXX) TOFILE(FICHEROS/MSOCIO88)
             OVRDBF     FILE(RECOBRO002) TOFILE(FICHEROS/RECOBRO006)
             CALL       PGM(EXPLOTA/RECO10_FPD)
             DLTOVR     FILE(MSOCIOXX)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*71*/
/*-------------------------------------------------------------------*/
/*-------------------------------------*/
/* PGM-RECO10_FPB (PAGO POR BANCO)     */
/*-------------------------------------*/
 RE71:       CALL       PGM(TRACE) PARM('PROGRAMA -RECO10_FPB- EN +
                          EJECUCION' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             OVRDBF     FILE(MSOCIOXX) TOFILE(FICHEROS/MSOCIO88)
             CALL       PGM(EXPLOTA/RECO10_FPB)
             DLTOVR     FILE(MSOCIOXX)
             DLTOVR     FILE(RECOBRO002)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*71*/
/*-------------------------------------*/
/*          "InfoRecobro"              */
/*  EXPORT_SQL y Seguridad Ficheros  */
/*-------------------------------------*/
             CHGJOB     DATE(&FECHA)
             RTVMBRD    FILE(FICHEROS/RECOBRO006) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(EXPLOTA/RECOTIME) PARM('06')

             CHGVAR     VAR(&CLAVES) +
                          VALUE('RECOBRO006                    ')
             CALL       PGM(EXPLOTA/CTREXPORCL) PARM(&FECHA +
                          'RECOBRO006' 'FICHEROS' 'RECOBRO006' +
                          'PCFICHEROS' &CLAVES &AGRUP1 &AGRUP2)
             CHGVAR     VAR(&CLAVES) VALUE(' ')

             CHGJOB     DATE(&FECHA)
             ENDDO
             ELSE       CMD(DO)
             CLRPFM     FILE(FICHEROS/RECOBRO005) /* Por no tener +
                          registros el RECOBRO006 */
             ENDDO

             CHGVAR     VAR(&TEX) VALUE('FS01CO, RECOBRO006 SALIDO +
                          DE PGM-RECO10_FPD y _FPB')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECOBRO006 +
                          FICHEROS RECOBRO006 LIBSEG30D 'M' ' ' ' ' +
                          &TEX FS01CO)
/*=====*/
             RTVMBRD    FILE(FICHEROS/RECOBRO005) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(EXPLOTA/RECOTIME) PARM('05')

             CHGVAR     VAR(&CLAVES) +
                          VALUE('RECOBRO005                    ')
             CALL       PGM(EXPLOTA/CTREXPORCL) PARM(&FECHA +
                          'RECOBRO005' 'FICHEROS' 'RECOBRO005' +
                          'PCFICHEROS' &CLAVES &AGRUP1 &AGRUP2)
             CHGVAR     VAR(&CLAVES) VALUE(' ')

             CHGJOB     DATE(&FECHA)
             ENDDO

             CHGVAR     VAR(&TEX) VALUE('FS01CO, RECOBRO005 SALIDO +
                          DE PGM-RECO09.          ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECOBRO005 +
                          FICHEROS RECOBRO005 LIBSEG30D 'M' ' ' ' ' +
                          &TEX FS01CO)

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*72*/
/*-------------------------------------------------------------------*/
/*  ===============================================================  */
/*          CLP.SELBACL  --> ACUMULACION BS (BCddmmaa)             */
/*  ===============================================================  */
/*-------------------------------------------------------------------*/
 RE72:       CHGVAR     VAR(&CONCI) VALUE('C')
             CALL       PGM(EXPLOTA/SELBACLM) PARM(&CONCI &RESPU +
                          &FECHA)
             CHGJOB     DATE(&FECHA)

 /*--------------------------------------------------------------------*/
 /* No se mueve el recibos  hasta fin de SELBACL                       */
 /*--------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS01CO, DESPUES DEL +
                          PGM-FSCREA -CONCILIACION-')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(RECIBOS FICHEROS +
                          RECIBOS LIBSEG30D C ' ' ' ' &TEX FS01CO)

             D1         LABEL(RECIBL3) LIB(FICHEROS)
             DLTF       FICHEROS/RECIBOS

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*73*/
/*-------------------------------------------------------------------*/
/*           INFORMES EMP.CONCILIACION --- M I S I N F C L ---       */
/*-------------------------------------------------------------------*/
 RE73:       CHGVAR     VAR(&CONCI) VALUE('C')
             DLTOVR     *ALL
             CHGJOB     DATE(&FECHA)
/*           CALL       PGM(EXPLOTA/MISINFCLM) PARM(&CONCI &FECHA)   */

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*74*/
/*-------------------------------------------------------------------*/
/*  Conciliación SEAT: los 31 de Diciembre Limpieza Estadist.MEMPRE  */
/*-------------------------------------------------------------------*/
 RE74:       IF         COND((&DDMMP = 3112) *AND (&SEAT = 'SEAT')) +
                          THEN(DO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                         PROGRAMA +
                          -LIMCEMSEAT- EN EJECUCION.' ' ' FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO -MEMPRE- ANTES DEL +
                          PGM-LIMCEMSEAT')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MEMPRE FICHEROS +
                          MEMPRE LIBSEG30D C ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/LIMCEMSEAT)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*75*/
/*-------------------------------------------------------------------*/
/*  LIBRE   LIBRE   LIBRE                                            */
/*-------------------------------------------------------------------*/
 RE75:


             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*76*/
/*-------------------------------------------------------------------*/
/* PGM-FSCREBO3-ACTUALIZA 4º RECIBO EXT.UNIF. SIN MOVIMIENTOS        */
/*-------------------------------------------------------------------*/
 RE76:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA FSCREBO3 +
                          EN EJECUCION.' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/FSCREBO3)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*77*/
/*-------------------------------------------------------------------*/
/* PGM-CONT26_V1 CONCIL. TOTAL: -BP- PROTEGE (S) ABONOS LLAA. RANGO FECHA */
/* PGM-CONT27A_V1CONCIL. TOTAL: -BA- PROTEGE (S) CARGOS LLAA. RANGO FECHA */
/* PGM-CONT26 CONCILIACION TOTAL: -BP- PROTEGE (S) ABONOS LLAA.    */
/* PGM-CONT27ACONCILIACION TOTAL: -BA- PROTEGE (S) CARGOS LLAA.    */
/*     ELIMINAR -CRFS01- Y MOVER -MSOCIO88- A LIBRERIA: LIBSEG30D    */
/*                                                                 */
/*   SI CASCA DEJAR NOTA Y SACAR  DUMP ***********************     */
/*                                                                 */
/*-------------------------------------------------------------------*/
 RE77:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA +
                          CONT26/CONT27 EN EJECUCION.' ' ' FS01CO)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/CONT26_V1) /* BOLSA PROVEEDORES +
                          RANGO FECHA*/
             CALL       PGM(EXPLOTA/CONT26) /* BOLSA PROVEEDORES */
/*=====*/
             D1         LABEL(PTEPRLG10) LIB(FICHEROS)

             CRTLF      FILE(FICHEROS/PTEPRLG10) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('logico +
                          -PTEPREPR- cargos - abonos = 0 no +
                          protege') OPTION(*NOSRC *NOLIST) +
                          LVLCHK(*NO) AUT(*ALL)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/CONT27A_V1) /* BOLSA AGENCIA RANGO FECHA*/
             CALL       PGM(EXPLOTA/CONT27A) /* BOLSA AGENCIA */

             DLTF       FILE(FICHEROS/PTEPRLG10)

             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS01CO) /*78*/

/*-------------------------------------------------------------------*/
/*--            FIN CONTROL CONCILIACION  -FACT.SOCIOS-            --*/
/*-------------------------------------------------------------------*/
 RE78:       CALL       PGM(PRDIACTL) PARM('B' 'FS01COM   ')

/* TA-FINANCIACION AMPLIADA,ASIENTO, EVIDENCIA CONTABLE            */

             CALL       PGM(EXPLOTA/TAFA05CL) PARM(&FECHA)

 /*------------------------------------------------------------------*/
 /*  BILLHOP -PLATAFORMA DE PAGO ASIENTO Y EVIDENCIA CONTABLE      */
 /*   03/10/2023 - Volver a descomentar si queremos que concilie     */
 /*                las procurement                                   */
 /*------------------------------------------------------------------*/
       /*    RTVMBRD    FILE(FICHEROS/MS_BILLFAC) NBRCURRCD(&NUMREG) */

       /*    IF         COND(&NUMREG > 0) THEN(DO)                   */
       /*    CALL       PGM(EXPLOTA/BILLHOFACL) PARM(&FECHA)         */
       /*    ENDDO                                                   */

/*=====*/
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CRFS01 FICHEROS +
                          CRFS01 LIBSEG30D M ' ' ' ' &TEX FS01CO)

             CHGVAR     VAR(&TEX) VALUE('FS01CO -MSOCIO88- FINAL +
                          FACTURACION CONCILIACION  ')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(MSOCIO88 FICHEROS +
                          MSOCIO88 LIBSEG30D M ' ' ' ' &TEX FS01CO)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CONTROCON +
                          FICHEROS CONTROCON LIBSEG30D M ' ' ' ' +
                          &TEX FS01CO)

             D1         LABEL(FIFS01CO) LIB(FICHEROS)
             D1         LABEL(COMPENFAS) LIB(FICHEROS)

/*-------------------------------------------------------------------*/
/*                            F I N                                  */
/*-------------------------------------------------------------------*/
 FINFIN:     CALL       PGM(EXPLOTA/TRACE) PARM('FIN    GUARDA ' ' ' +
                          'FS01CO')
/********************************************************************/
/* GRABAR INCIDENCIA                                                */
/********************************************************************/
             SUBR       SUBR(INCIDENCIA)

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

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

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "PAGE00". -FS01M-  INVESTIGAR. FACT.SOCIOS.')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

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

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "FAGE00". -FS01M-  INVESTIGAR. +
                          FACT.SOCIOS.')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

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

             CHGVAR     VAR(&DESCRIP) VALUE('NO CUADRA EL TOTALES +
                          "BORECI". -FS01M-  INVESTIGAR. +
                          FACT.SOCIOS.')

             CALL       PGM(EXPLOTA/PRINCIDENC) PARM(&PROCE &DESCRIP +
                          &PRIORID)

             CHGVAR     VAR(&DESCTOT) VALUE('IMPORTANTE: NO CUADRA +
                          EL TOTALES "BORECI" DEL *-FS01M-  +
                          FACT.SOCIOS   **LLAMAR A Diners Club Spain')

             CHGVAR     VAR(&CODRET) VALUE('0')

             CALL       PGM(MSGGUARDCL) PARM(&DESCTOT &CODRET)

             ENDDO

             ENDSUBR
             ENDPGM
