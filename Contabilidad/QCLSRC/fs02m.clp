 /********************************************************************/
 /*                                                                  */
 /*        F A C T U R A C I O N      D E      S O C I O S           */
 /*                                                                  */
 /*            ------ C O N T I N U A C I O N -------                */
 /*                                                                  */
 /********************************************************************/
             PGM        PARM(&FECHA)
             DCL        VAR(&DATOS)  TYPE(*CHAR) LEN(14) VALUE('FS02')
             DCL        VAR(&FECHA)  TYPE(*CHAR) LEN(6)
             DCL        VAR(&DD)     TYPE(*DEC)  LEN(2)
             DCL        VAR(&MM)     TYPE(*CHAR) LEN(2)
             DCL        VAR(&DDMMP)  TYPE(*DEC)  LEN(4)
             DCL        VAR(&TEX)    TYPE(*CHAR) LEN(50)
             DCL        VAR(&RESPU) TYPE(*CHAR) LEN(2) VALUE('  ') +
                          /* para selbacl */
             DCL        VAR(&REST1)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&NUMREG) TYPE(*DEC)  LEN(10 0)
/*-------------------------------------------------------------------*/
/*--         RECUPERAR VALORES Y CEBAR VARIABLES                   --*/
/*-------------------------------------------------------------------*/
             CHGJOB     DATE(&FECHA) SWS(00000000)
             CHGVAR     VAR(&DD)    VALUE(%SST(&FECHA 1 2))
             CHGVAR     VAR(&MM)    VALUE(%SST(&FECHA 3 2))
             CHGVAR     VAR(&DDMMP) VALUE(%SUBSTRING(&FECHA 1 4))
/*-------------------------------------------------------------------*/
/*--          CARGAR TRACE PARA SEGUIMIENTO                        --*/
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)
/*-------------------------------------------------------------------*/
/*--                    REARRANQUE AUTOMATICO                      --*/
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
/*-------------------------------------------------------------------*/
/*--    RPG. C O V T O 1  --AL 10 Y AL 20 VENCIDAS DE COBRO--      --*/
/*-------------------------------------------------------------------*/
             IF         COND(&DD = 10) THEN(GOTO CMDLBL(VTOCOBRO))
             IF         COND(&DD = 20) THEN(GOTO CMDLBL(VTOCOBRO))
             GOTO       CMDLBL(NOVT1)
 VTOCOBRO:
 NOVT1:      CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 01 */
/*-------------------------------------------------------------------*/
/*--  RPG. FSINFOR   --SOLO EN FIN DE MES, CREACION DEL INFOR--    --*/
/*-------------------------------------------------------------------*/
 RE1:        IF         COND(&DD *GE 28) THEN(GOTO CMDLBL(SIFSINFO))
             GOTO       CMDLBL(NOFSINFO)
 SIFSINFO:   CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA  FSINFOR +
                          EN EJECUCION SOLO FINAL DE +
                          MES.                           ' ' ' FS02)
             CRTPF      FILE(FICHEROS/INFOR) +
                          SRCFILE(FICHEROS/QDDSSRC) TEXT('salido de +
                          la fact. socios fin de mes') +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/INFOR))
             CRTPF      FILE(FICHEROS/DETE12) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE12))
             CRTPF      FILE(FICHEROS/CABE12) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE12))

             OVRPRTF    FILE(IMP0017) TOFILE(*FILE) OUTQ(P10) +
                          FORMTYPE(IMP00P10) SAVE(*YES)
             CALL       PGM(EXPLOTA/FSINFOR)
             DLTOVR     IMP0017

/*-------------------------------------- */
/* COPIAS PARCIALES EVIDENCIAS CONTABLES */
/*-------------------------------------- */

             CPYF       FROMFILE(FICHEROS/DETE12) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/CABE12) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)
             MONMSG     MSGID(CPF0000)

             CHGVAR     VAR(&TEX) VALUE('FS02, DESPUES DEL +
                          PGM-FSINFOR')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE12 FICHEROS +
                          DETE12 LIBSEG1D M ' ' ' ' &TEX FS02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE12 FICHEROS +
                          CABE12 LIBSEG1D M ' ' ' ' &TEX FS02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(INFOR FICHEROS +
                          INFOR LIBSEG30D C ' ' ' ' &TEX FS02)
             CHKOBJ     OBJ(*LIBL/LIBSEG30D) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF0000) CMPDTA(*NONE) EXEC(CRTLIB +
                          LIB(LIBSEG30D) TEXT('libreria copias +
                          seguridad fin de mes') AUT(*ALL))
             CHGVAR     VAR(&TEX) VALUE('FS02, DESPUES DEL +
                          PGM-FSINFOR')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(INFOR FICHEROS +
                          INFOR LIBSEG30D C ' ' ' ' &TEX FS02)
/*----------------------------------------------------------*/
/* CTROL. GRABAR ASNEF                                      */
/* NO SE PERMITE GRABAR ASNEF HASTA QUE SAQUEMOS EL FICHERO */
/*----------------------------------------------------------*/
             CALL       PGM(PRFICCTL) PARM('A' 'ASNEFCTL  ')
 NOFSINFO:   CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 02 */
/*-------------------------------------------------------------------*/
/*--          RPG. F S T R I M  --ESTADISTICAS TRIMESTRALES--      --*/
/*-------------------------------------------------------------------*/
 RE2:        IF         COND(&DDMMP = 3103) THEN(GOTO CMDLBL(TRIM))
             IF         COND(&DDMMP = 3006) THEN(GOTO CMDLBL(TRIM))
             IF         COND(&DDMMP = 3009) THEN(GOTO CMDLBL(TRIM))
             IF         COND(&DDMMP = 3112) THEN(DO)
 TRIM:       IF         COND(&DDMMP = 3112) THEN(CHGJOB SWS(XXXXX1XX))
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA  FSTRIM  EN EJECUCION' ' ' FS02)
             CALL       PGM(EXPLOTA/FSTRIM)
             ENDDO
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 03 */
/*-------------------------------------------------------------------*/
/*--  RPG. DGTE04  -- LIMPIA EN MSOCIO IMPORTE GTOS.EXTRAJERO--    --*/
/*-------------------------------------------------------------------*/
 RE3:        IF         COND(&DDMMP *EQ 3112) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE :ESTE +
                          PROGRAMA *DGTE04* SOLO SE PUEDE EJECUTAR +
                          SI ESTAMOS         ' ' ' FS02)
             CALL       PGM(EXPLOTA/TRACE) PARM('AL 3112 SI NO +
                          CANCELAR Y AVISAR A +
                          EXPLOTACION.                            +
                          ' ' ' FS02)

             CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA DGTE04 EN +
                          EJECUCION' ' ' FS02)
             CALL       PGM(EXPLOTA/DGTE04)

             CALL       PGM(EXPLOTA/TRACE) PARM(' IMPORTANTE : No +
                          olvidarse que despues de acumular el +
                          bs3112 al VIBASO hay que' ' ' FS02)
             CALL       PGM(EXPLOTA/TRACE) PARM('ejecutar la opcion +
                          4 menu trabajos anuales (prog. +
                          LIMBAUTCL)                  ' ' ' FS02)
             CHGJOB     DATE(&FECHA)
/*-------------------------------------------------------*/
/* PROGRAMA SAPE3112, SOLO A FINAL DE AÑO                */
/*-------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM('Por ser final de +
                          año se ejecuta el programa SAPE3112, +
                          genera un listado       ' ' ' FS02)
             CALL       PGM(EXPLOTA/TRACE) PARM('para contabilidad y +
                          otro para explotacion' ' ' FS02)
             CALL       EXPLOTA/SAPE3112
/*-------------------------------------------------------*/
             ENDDO
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 04 */
/*-------------------------------------------------------------------*/
/*--  RPG. FSPAFA  -ASIENTO Y CUADRE PA Y FA DE SA LIDA EN QBATCH-  --*/
/*-------------------------------------------------------------------*/
 RE4:        CALL       PGM(EXPLOTA/TRACE) PARM('            +
                          Programa FSPAFA en +
                          ejecucion                    ' ' ' FS02)

     /*--------------------------------------------------------*/
     /*    Nueva version del FSPAFA (Actualizacion)       LM   */
     /*    PARALELO                                            */
     /*--------------------------------------------------------*/

             SBMJOB     CMD(CALL PGM(Paraleloc/FSPAFAN_P) + 
                        PARM(('FS02M'))) +
                          JOB(FSPAFAN_P) INLLIBL(PARALELOC EXPLOTA)

     /*--------------------------------------------------------*/

     /*--------------------------------------------------------*/
     /*    Nueva version del FSPAFA                            */
     /*--------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS02, ANTES DEL +
                        PGM-FSPAFAN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS       FICHEROS +
                        BS       LIBSEG30D C ' ' ' ' &TEX FS02)

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BS       FICHEROS +
                        BS       LJMONTERO C ' ' ' ' &TEX FS02)

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

              CHGJOB     DATE(&FECHA)

              CHGVAR     VAR(&TEX) VALUE('FS02, DESPUES DEL +
                        PGM-FSPAFAN')
              CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETEPAFA FICHEROS +
                        DETEPAFA LIBSEG30D C ' ' ' ' &TEX FS02)
              CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABEPAFA FICHEROS +
                        CABEPAFA LIBSEG30D C ' ' ' ' &TEX FS02)
              CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASIPAFAN FICHEROS +
                        ASIPAFAN LIBSEG30D C ' ' ' ' &TEX FS02)

             ENDDO
         /*--------------------------------------------------------*/
             RTVMBRD    FILE(FICHEROS/BSSALTA) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG = 0) THEN(GOTO CMDLBL(NOSALBS))

             OVRDBF     FILE(BS) TOFILE(FICHEROS/BSSALTA)
             CALL       PGM(EXPLOTA/FSPAFA)
             DLTOVR     FILE(BS)

             CHGJOB     DATE(&FECHA)
 NOSALBS:    CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 05 */
/*-------------------------------------------------------------------*/
/*                --- DEPARTAMENTO CONTABILIDAD ---                  */
/* Conciliación Cuentas de Viajes (Situación Ficheros: PA y PTEPREPR */
/*-------------------------------------------------------------------*/
 RE5:        CALL       PGM(EXPLOTA/TRACE) PARM('           Programa +
                          -CONBPR/CONBAG en Ejecución              +
                          ' ' ' FS02)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/CONBPR) /* Bolsa Proveedores */
             CALL       PGM(EXPLOTA/CONBAG) /* Bolsa Agencia     */

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 06 */
/*-------------------------------------------------------------------*/
/*--         ACUMULACION  FICHEROS PARA CONTABILIDAD               --*/
/*--   *ACUMULA TODOS LOS ASIENTOS GENERADOS EN FS01M Y FS03M      --*/
/*--            *ASIENTOS ASIFILE  A ASIFS01                       --*/
/*--            *ASIENTOS ASIFILEN A ASIFS02                       --*/
/*-------------------------------------------------------------------*/
 RE6:        CRTPF      FILE(FICHEROS/ASIFS01) +
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
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*REPLACE)
             MONMSG     MSGID(CPF0000)


             CPYF       FROMFILE(FICHEROS/ASIBALAN) +
                          TOFILE(FICHEROS/ASIFS02) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/ASIFSPAFA) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/ASIANVIES) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/ASIFSCRE) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)

             CPYF       FROMFILE(FICHEROS/ASIFSCREBO) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)

             CHKOBJ     OBJ(FICHEROS/ASICUOTE05) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOCOPIA))
             CPYF       FROMFILE(FICHEROS/ASICUOTE05) +
                          TOFILE(FICHEROS/ASIFS02) MBROPT(*ADD)
             CALL       PGM(CONCOPCL) PARM(ASICUOTE05 FICHEROS +
                          ASICUOTE05 LIBSEG30D M ' ' ' ' &TEX FS02)
             MONMSG     MSGID(CPF0000)
NOCOPIA:
             CHGJOB     DATE(&FECHA)
/*-------------------*/
/*- Campañas Socios -*/
/*-------------------*/
             IF         COND((&DD = 05) | (&DD = 15) | (&DD = 25)) +
                          THEN(DO)
             CPYF       FROMFILE(FICHEROS/ASICAMSO) +
                          TOFILE(FICHEROS/ASIFS01) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             ENDDO

             IF         COND((&DD = 10) | (&DD = 20) | (&DD *GE 28)) +
                          THEN(DO)
             CPYF       FROMFILE(FICHEROS/ASIBALAP) +
                          TOFILE(FICHEROS/ASIFS02) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             ENDDO
/*----------------------------------*/
/*- ACUMULACION DE ASIENTOS: ACASBO */
/*----------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA ACASBO EN EJECUCION.' ' ' FS02)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFS01)
             CALL       PGM(EXPLOTA/ACASBO) PARM('002')
             DLTOVR     FILE(ASIFILE)

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASIFS02)
             CALL       PGM(EXPLOTA/ACASBON) PARM('002')
             DLTOVR     FILE(ASIFILE)

             CHGVAR     VAR(&TEX) VALUE('FS02, ASIENTOS GEN. FACT. SO+
                          C.')
             CALL       PGM(CONCOPCL) PARM(ASIFAPA   FICHEROS +
                          ASIFAPA  LIBSEG30D M ' ' ' ' &TEX FS02)
             CALL       PGM(CONCOPCL) PARM(ASIBALAN  FICHEROS +
                          ASIBALAN LIBSEG30D M ' ' ' ' &TEX FS02)
             CALL       PGM(CONCOPCL) PARM(ASIFSPAFA FICHEROS +
                        ASIFSPAFA  LIBSEG30D M ' ' ' ' &TEX FS02)

             CALL       PGM(CONCOPCL) PARM(ASIPAFAMC FICHEROS +
                        ASIPAFAMC  LIBSEG30D C ' ' ' ' &TEX FS02)

             CHGJOB     DATE(&FECHA)
/*---------------*/
/* SOLO 05,15,25 */
/*---------------*/
             IF         COND((&DD = 05) | (&DD = 15) | (&DD = 25)) +
                          THEN(DO)
             CALL       PGM(CONCOPCL) PARM(ASICAMSO FICHEROS +
                          ASICAMSO LIBSEG30D M ' ' ' ' &TEX FS02)
             ENDDO
/*---------------*/
/* SOLO 10,20,30 */
/*---------------*/
             IF         COND((&DD = 10) | (&DD = 20) | (&DD *GE 28)) +
                          THEN(DO)
             CALL       PGM(CONCOPCL) PARM(ASIBALAP  FICHEROS +
                        ASIBALAP   LIBSEG30D M ' ' ' ' &TEX FS02)
                        ENDDO
             IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(CONCOPCL) PARM(ASIANVIES FICHEROS +
                        ASIANVIES  LIBSEG30D M ' ' ' ' &TEX FS02)
                        ENDDO
/*---------------*/
             CALL       PGM(CONCOPCL) PARM(ASIFSCRE  FICHEROS +
                        ASIFSCRE   LIBSEG30D M ' ' ' ' &TEX FS02)
             CALL       PGM(CONCOPCL) PARM(ASIFSCREBO FICHEROS +
                          ASIFSCREBO LIBSEG30D M ' ' ' ' &TEX FS02)
             CALL       PGM(CONCOPCL) PARM(ASIFS01   FICHEROS +
                        ASIFS01    LIBSEG30D M ' ' ' ' &TEX FS02)
             CALL       PGM(CONCOPCL) PARM(ASIFS02   FICHEROS +
                        ASIFS02    LIBSEG30D M ' ' ' ' &TEX FS02)
             D1         LABEL(BSSALTA) LIB(FICHEROS)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 07 */
/*-------------------------------------------------------------------*/
/*-- RPG. LIMCTA  -LIMPIEZA CONDICION CUOTA EN MSOCIO--            --*/
/*-------------------------------------------------------------------*/
 RE7:        IF         COND(&DDMMP = 3004) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('* Programa LIMCTA +
                          en ejecucion' ' ' FS02)
             CALL       PGM(EXPLOTA/LIMCTA)
             ENDDO

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 08 */
/*-------------------------------------------------------------------*/
/*--        GRUPO DE SBMJOB INTEGRADOS EN ESTE CL -SBMJOBCL-       --*/
/*-------------------------------------------------------------------*/
 RE8:        SBMQBATCH  NOMJOB(FS0201) FECPRO(&FECHA) DESBRE('grupo +
                          trabajos en batch') CMD('call +
                          explota/sbmjobcl')

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 09 */
/*-------------------------------------------------------------------*/
/*--            IMPRESION DE TODOS LOS ASIENTOS DE LA FAC.         --*/
/*-------------------------------------------------------------------*/
 /*------------------*/
 /*   Fin de Mes   */
 /*------------------*/
 RE9:        IF         COND(&DD > 27) THEN(DO)
             CALL       PGM(CUPAFACLM) PARM(&FECHA '1')

             CALL       PGM(SUBRUDIN/EVIADDCL) PARM('EVISUPAFA ' +
                          '          ' 'CUADRE CTAS PA/FA, ESPECIAL +
                          AUDITORES            ' 'FS02      ' '700008' '1')
             CHGJOB     DATE(&FECHA)

             CHGVAR     VAR(&TEX) VALUE('FS02, *ESPECIAL AUDITORES*, +
                          DESPUES DEL-CUPAFACL')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(FA FICHEROS FA +
                          LIBSEG30D 'C' ' ' ' ' &TEX FS02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PA FICHEROS PA +
                          LIBSEG30D 'C' ' ' ' ' &TEX FS02)
             ENDDO
 /*--*/
             ELSE       CMD(CALL PGM(EXPLOTA/ASIACUCLM))
             CHGJOB     DATE(&FECHA)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 10 */
/*-------------------------------------------------------------------*/
/*  RPG. A C U P I N  --INFORME DE TARJETAS SIN ACUSAN PIN--       --*/
/*-------------------------------------------------------------------*/
 RE10:       CALL       PGM(EXPLOTA/TRACE) PARM('PROGRAMA ACUPIN EN +
                          EJECUCION' ' ' FS02)

             OVRPRTF    FILE(QSYSPRT) OUTQ(P3) SAVE(*YES)
             CALL       PGM(SADE/ACUPIN)
             DLTOVR     FILE(QSYSPRT)
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 11 */
/*-------------------------------------------------------------------*/
/*     Control: Creación Fichero de Facturación para -EMPRESAS-      */
/*-------------------------------------------------------------------*/
 RE11:       IF         COND((&DD = 05) | (&DD = 15) | (&DD = 25)) +
                          THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('+2' ' ' FS02) /* 13 */
             GOTO       CMDLBL(NOSOPOR)
             ENDDO

             CRTPF      FILE(FICHEROS/BSFACIN) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(BSFACIN) +
                          TEXT('extractos soportes magneticos del +
                          proceso') OPTION(*NOLIST *NOSRC) +
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
             CHGVAR     VAR(&TEX) VALUE('FS02, DESPUES DE ACUMULAR +
                          BSFACINNO/BSFACINLA')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSFACIN FICHEROS +
                          &REST1 LIBSEG30D C ' ' ' ' &TEX FS02)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSFACIN FICHEROS +
                          &REST1 LIBSEG30D C ' ' ' ' &TEX FS02)

/*---*/
/*      CHGVAR     VAR(&TEX) VALUE('FS02, SALIDO DE PGM.FSEXTE')    */
/*           CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSFACINNO +      */
/*                        FICHEROS BSFACINNO LIBSEG30D M ' ' ' ' +  */
/*                        &TEX FS02)                                */
/*---*/
             CHKOBJ     OBJ(FICHEROS/BSFACINLA) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOFACINLA))

/*-----------------------------*/
/* DELOITTE (Nº.BILLETE RENFE) */
/*-----------------------------*/
             IF         COND(&DD *GE 28) THEN(DO)
             CPYF       FROMFILE(FICHEROS/BSFACINLA) +
                          TOFILE(FICHEROS/BSFACIN_FM) +
                          MBROPT(*REPLACE) CRTFILE(*YES) FROMRCD(1) +
                          FMTOPT(*NOCHK)
             CHGPF      FILE(FICHEROS/BSFACIN_FM) TEXT('FS02, +
                          FACT.SOCIOS: BSFACIN FIN DE MES')
             ENDDO
/*----------------------------*/
             CHGVAR     VAR(&TEX) VALUE('FS02, SALIDO DE PGM.FSFACIN')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(BSFACINLA +
                          FICHEROS BSFACINLA LIBSEG30D M ' ' ' ' +
                          &TEX FS02)
/*---*/
 NOFACINLA:  CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 12 */
/*-------------------------------------------------------------------*/
/* FSELTECL Fich. Facturación para Empresas, Standar ó Especiales  */
/*-------------------------------------------------------------------*/
 RE12:       CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/FSELTECLM) PARM(&FECHA ' ')
             CHGJOB     DATE(&FECHA)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 13 */
/*-------------------------------------------------------------------*/
/*--    OPERACIONES FACTURADAS OPERATIVA INTERNA                  --*/
/*    FICHERO PARCIAL -HICOSIBOSS- PARA MICROINFORMATICA -EXPORT_SQL-*/
/*-------------------------------------------------------------------*/
 NOSOPOR:
 RE13:       IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(EXPLOTA/COSIBOCL_O) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)
             ENDDO
             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 14 */
/*-------------------------------------------------------------------*/
/*--  LIBRE                                                          */
/*-------------------------------------------------------------------*/
RE14:
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(T_MSOCIO FICHEROS +
                          MSOCIOFIN LIBSEG30D C ' ' ' ' &TEX FS02)

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 15 */
/*-------------------------------------------------------------------*/
/*--                    CONTROL FIN FACT.SOCIOS                    --*/
/*-------------------------------------------------------------------*/
RE15:        CALL       PGM(PRFICCTL) PARM('B' 'NOPROC    ')
             CHGJOB     DATE(&FECHA)

/*--------------------------------------------------------------*/
/*  ENRIQUECIMIENTO DE DATOS: SOLO LOS CIERRES 10-20-30       */
/*  ANTES DE CREAR -DESCRXXAT- EN CLP.SELBACLM                */
/*--------------------------------------------------------------*/
             IF         COND((&DD = 10) | (&DD = 20) | (&DD *GE 28)) +
                          THEN(DO)
             CALL       PGM(EXPLOTA/ATRDIADED)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 16 */
/*-------------------------------------------------------------------*/
/*--                  ACUMULACION DEL BS                          --*/
/*-------------------------------------------------------------------*/
 RE16:       DLTOVR *ALL
             CALL       PGM(EXPLOTA/SELBACLM) PARM(' ' &RESPU &FECHA)
             CHGJOB     DATE(&FECHA)

             CHGJOB     DATE(&FECHA)
             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 17 */
/*-------------------------------------------------------------------*/
/*--                   COPIA DE FICHEROS -FIN AÑO-                 --*/
/*-------------------------------------------------------------------*/
 RE17:       IF         COND(&DDMMP = 3112) THEN(DO)
             CALL       PGM(EXPLOTA/SEGFINCL) PARM('01')
             CHGJOB     DATE(&FECHA)
             ENDDO

             CALL       PGM(EXPLOTA/TRACE) PARM('+1' ' ' FS02) /* 18 */
/*-------------------------------------------------------------------*/
/*--        Envio de ficheros por SFTP a carpeta de contabilidad  --*/
/*--    TODOS LOS MESES FICHEROS A CONTABILIDAD, TEMA: AUDITORIAS --*/
/*-------------------------------------------------------------------*/
 RE18:       IF         COND(&DD *GE 28) THEN(DO)
             CALL       PGM(EXPLOTA/FS02AUDI) PARM(&FECHA)
             CHGJOB     DATE(&FECHA)
             ENDDO
/*-------------------------------------------------------------------*/
/*--                 Finalización del Proceso                      --*/
/*-------------------------------------------------------------------*/
             CALL       PGM(TRACE) PARM('FIN    GUARDA ' ' ' 'FS02')
             ENDPGM
