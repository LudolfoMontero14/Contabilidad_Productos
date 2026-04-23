/*********************************************************************/
/**                 --CONCILIACION CTAS. DE VIAJES--                **/
/**                                                                 **/
/**   TRASPASOS DIARIOS: BOLSA DE AGENCIAS --> BOLSA PROVEEDORES    **/
/**                      =================     =================    **/
/**                         (PTEPREPR)     -->       (PA)           **/
/**                                                                 **/
/*********************************************************************/
             PGM        PARM(&FECHA &NUTRA)
             DCL        VAR(&NUMREG) TYPE(*DEC) LEN(10 0)
             DCL        VAR(&DATOS) TYPE(*CHAR) LEN(14) +
                          VALUE('COBATRCL')
             DCL        VAR(&FECHA) TYPE(*CHAR) LEN(6)
             DCL        VAR(&NUTRA) TYPE(*CHAR) LEN(3)
             DCL        VAR(&COD)   TYPE(*DEC)  LEN(1 0)
             DCL        VAR(&TOTPA) TYPE(*DEC)  LEN(11 0)
             DCL        VAR(&TEX)   TYPE(*CHAR) LEN(50)
             DCL        VAR(&BLOQUEA) TYPE(*CHAR) LEN(1)
             DCL        VAR(&MSG)   TYPE(*CHAR) LEN(240) VALUE('Por +
                          favor, salga al menu durante 5 minutos +
                          para que el programa COBATRCL pueda usar +
                          el fichero PA. De no ser así, pasados +
                          unos segundos se cancelará.')

             DCL        VAR(&NOMPARA) TYPE(*CHAR) LEN(10)

             CHGJOB     DATE(&FECHA)
/*-------------------------------------------------------------------*/
/*--                  --- CARGAR  TRACE ---                        --*/
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

             CALL       PGM(EXPLOTA/TRACE) PARM('CONCILIACIÓN: +
                          TRASPASOS DE OPERACIONES ENTRE BOLSAS +
                          (AGENCIA/PROVEEDOR)       ' ' ' COBATRCL)
/*-------------------------------------------------------------------*/
/*--                    REARRANQUE AUTOMATICO                        */
/*-------------------------------------------------------------------*/
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '01') +
                          THEN(GOTO CMDLBL(RE01))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '02') +
                          THEN(GOTO CMDLBL(RE02))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '03') +
                          THEN(GOTO CMDLBL(RE03))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '04') +
                          THEN(GOTO CMDLBL(RE04))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '05') +
                          THEN(GOTO CMDLBL(RE05))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '06') +
                          THEN(GOTO CMDLBL(RE06))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '07') +
                          THEN(GOTO CMDLBL(RE07))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '08') +
                          THEN(GOTO CMDLBL(RE08))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '09') +
                          THEN(GOTO CMDLBL(RE09))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '10') +
                          THEN(GOTO CMDLBL(RE10))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '11') +
                          THEN(GOTO CMDLBL(RE11))
             IF         COND((%SUBSTRING(&DATOS 13 2)) *EQ '12') +
                          THEN(GOTO CMDLBL(RE12))
/*-------------------------------------------------------------------*/
/* ALOCATAR EL -PA- DURANTE UNOS SEGUNDOS PARA CREAR EL -FIFS01-     */
/*-------------------------------------------------------------------*/
 ALOCAPA:    ALCOBJ     OBJ((FICHEROS/PA *FILE *EXCL))
             MONMSG     CPF0000 *NONE EXEC(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('El fichero PA esta +
                          alocatado por otro trabajo.' ' ' COBATRCL)

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(PA *FILE +
                          FICHEROS &MSG &BLOQUEA)

             GOTO       CMDLBL(ALOCAPA)
             ENDDO
/*----*/
             CL1        LABEL(FIFS01) LIB(FICHEROS) LON(1) /* +
                          Permisos Entre Aplicaciones */
             DLCOBJ     OBJ((FICHEROS/PA *FILE *EXCL))
             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 01 */
/*-------------------------------------------------------------------*/
/*    ALOCATAR FICHERO -COBATRAS- (LIMPIEZA BOLSAS CONCILIACION)    */
/*-------------------------------------------------------------------*/
 RE01:
 ALOCACO:    ALCOBJ     OBJ((FICHEROS/COBATRAS *FILE *EXCL))
             MONMSG     CPF0000 *NONE EXEC(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM(' El fichero +
                          -COBATRAS- esta siendo utilizado por el +
                          departamento de       ' ' ' COBATRCL)
             CALL       PGM(EXPLOTA/TRACE) PARM(' CONCILIACION, se +
                          manda email para que se salgan ' ' ' +
                          COBATRCL)

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(COBATRAS *FILE +
                          FICHEROS &MSG &BLOQUEA)

             GOTO       CMDLBL(ALOCACO)
             ENDDO
             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 02 */
/*-------------------------------------------------------------------*/
/*-- CONTROL: IMPIDE ACCEDER A LAS OPCIONES DE LIMPIEZA DE BOLSAS  --*/
/*--         "COLIMBOAN"  --> SE ELIMINA EN CL.CUPAFACL            --*/
/*-------------------------------------------------------------------*/
 RE02:       CL1        LABEL(COLIMBOAN) /* Permisos entre +
                          Aplicaciones */
             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 03 */
/*-------------------------------------------------------------------*/
/*  RENOMBRA FICHERO -COBATRAS- Y CREAR LIMPIO PARA EL DIA SIGUIENTE */
/*-------------------------------------------------------------------*/
 RE03:       CALL       PGM(EXPLOTA/TRACE) PARM('RENOMBRANDOSE +
                          FICHERO DE TRASPASOS' ' ' COBATRCL)
/*---*/
             CHGVAR     VAR(&TEX) VALUE('COBATRCL, FICHERO DE ENTRADA')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(COBATRAS FICHEROS +
                          COBATRAS LIBSEG1D C ' ' ' ' &TEX COBATRCL)

             RNMOBJ     OBJ(FICHEROS/COBATRAS) OBJTYPE(*FILE) +
                          NEWOBJ(COBATROK)

             DLCOBJ     OBJ((FICHEROS/COBATROK *FILE *EXCL))
/*---*/
             CRTPF      FILE(FICHEROS/COBATRAS) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('CONCILIACION, TRASPASOS DIARIOS +
                          ENTRE BOLSAS') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) FRCRATIO(1) LVLCHK(*NO) +
                          AUT(*ALL)
             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 04 */
/*-------------------------------------------------------------------*/
/*--          VER SI TIENE REGISTROS  FICHERO -COBATROK-             */
/*-------------------------------------------------------------------*/
RE04:        RTVMBRD    FILE(FICHEROS/COBATROK) NBRCURRCD(&NUMREG)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(HAYCARTA))

             IF         COND(&NUMREG = 0) THEN(DO)
/**********************************/
/** HAY CARTAS, ANUCIO TRASPASOS **/
/**********************************/
 HAYCARTA:   RTVMBRD    FILE(FICHEROS/VIDEOCON) NBRCURRCD(&NUMREG)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(FIN))

             IF         COND(&NUMREG > 0) THEN(DO)
             CPYF       FROMFILE(FICHEROS/VIDEOCON) +
                          TOFILE(FICHEROS/VIDEO) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             CHGVAR     VAR(&TEX) VALUE('COBATRCL, DESPUES DE +
                          EJECUTAR PGM-COBATR')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(VIDEOCON FICHEROS +
                          VIDEOCON LIBSEG1D M ' ' ' ' &TEX COBATRCL)
             ENDDO
/**********************************/
             GOTO       CMDLBL(FIN)
             ENDDO

             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 05 */
/*-------------------------------------------------------------------*/
/*--             --- CREACION FICHEROS AUXILIARES ---              --*/
/*--  (DESCRC17 - PAC17 - ASICOC17 - ASOCOC17 - VIDEOCON)          --*/
/*-------------------------------------------------------------------*/
 RE05:       CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -COBATR- EN +
                          EJECUCION                   ' ' ' COBATRCL)

/*----------------------------------------------**/
/**  Ejecucición del proceso del COBATRN (New)  **/
/*----------------------------------------------**/
             CALL       PGM(EXPLOTA/COBATRNCL) PARM(&NUTRA 'COBATRCL')

             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 06 */
/*-------------------------------------------------------------------*/
/*            ACUMULACION -DESCRC17- A -DESCRFAC-                  --*/
/*-------------------------------------------------------------------*/
RE06:        RTVMBRD    FILE(FICHEROS/DESCRC17) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)

             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                      ACUMULACION: +
                          -DESCRC17- A +
                          -DESCRFAC-                    ' ' ' COBATRCL)
             CPYF       FROMFILE(FICHEROS/DESCRC17) +
                          TOFILE(FICHEROS/DESCRFAC) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             ENDDO

             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 07 */
/*-------------------------------------------------------------------*/
/*                 ACUMULACION -PAC17- A -PA-                      --*/
/*-------------------------------------------------------------------*/
RE07:        RTVMBRD    FILE(FICHEROS/PAC17) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                      ACUMULACION: +
                          -PAC17- A +
                          -PA-                             ' ' ' +
                          COBATRCL)
             CPYF       FROMFILE(FICHEROS/PAC17) TOFILE(FICHEROS/PA) +
                          MBROPT(*ADD) FROMRCD(1) FMTOPT(*NOCHK)
             ENDDO

             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 08 */
/*-------------------------------------------------------------------*/
/*                 ACUMULACION -OPAGECO17 A OPAGECO                --*/
/*-------------------------------------------------------------------*/
 RE08:       RTVMBRD    FILE(FICHEROS/OPAGECO17) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('ACUMULACION: +
                          -OPAGECO17- A -OPAGECO' ' ' COBATRCL)
             CPYF       FROMFILE(FICHEROS/OPAGECO17) +
                          TOFILE(FICHEROS/OPAGECO) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             ENDDO

             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 09 */
/*-------------------------------------------------------------------*/
/*            ACUMULACION  -VIDEOCON- A -VIDEO-                    --*/
/*-------------------------------------------------------------------*/
RE09:        RTVMBRD    FILE(FICHEROS/VIDEOCON) NBRCURRCD(&NUMREG)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NOFICHE))

             IF         COND(&NUMREG > 0) THEN(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('ACUMULACION: +
                          -VIDEOCON- A -VIDEO-' ' ' COBATRCL)
             CPYF       FROMFILE(FICHEROS/VIDEOCON) +
                          TOFILE(FICHEROS/VIDEO) MBROPT(*ADD) +
                          FROMRCD(1) FMTOPT(*NOCHK)
             ENDDO

NOFICHE:     CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 10 */
/*-------------------------------------------------------------------*/
/*                 ACUMULACION ASIENTOS AL ASIBOLSA                --*/
/*-------------------------------------------------------------------*/
 RE10:       
             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 11 */
/*-------------------------------------------------------------------*/
/*       CUADRE DIARIO: PA CONTRA FICHERO TOTALES (TOTASAX)        --*/
/*-------------------------------------------------------------------*/
 RE11:       CALL       PGM(EXPLOTA/TRACE) PARM('CUADRE AUTOMATICO +
                          -PA- CONTRA TOTALES' ' ' COBATRCL)
             CALL       PGM(EXPLOTA/SPADIA) PARM(&TOTPA)
             CALL       PGM(EXPLOTA/CUADAU) PARM(&TOTPA  'PAGE00' +
                          '1' 'C' ' ')
             CALL       PGM(TRACE) PARM('+1' ' ' COBATRCL) /* 12 */
/*-------------------------------------------------------------------*/
/*                      COPIAS DE SEGURIDAD                        --*/
/*-------------------------------------------------------------------*/
 RE12:       CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0062' ' ' COBATRCL)

             CHGVAR     VAR(&TEX) VALUE('COBATRCL, DESPUES DE +
                          EJECUTAR PGM-COBATR')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(OPAGECO17 +
                          FICHEROS OPAGECO17 LIBSEG1D M ' ' ' ' +
                          &TEX COBATRCL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DESCRC17 FICHEROS +
                          DESCRC17 LIBSEG1D M ' ' ' ' &TEX COBATRCL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(PAC17 FICHEROS +
                          PAC17 LIBSEG1D M ' ' ' ' &TEX COBATRCL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASICOC17 FICHEROS +
                          ASICOC17 LIBSEG1D M ' ' ' ' &TEX COBATRCL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(VIDEOCON FICHEROS +
                          VIDEOCON LIBSEG1D M ' ' ' ' &TEX COBATRCL)

/*-------------------------------------------------------------------*/
/*--                       ---- F I N ----                         --*/
/*-------------------------------------------------------------------*/
 FIN:        D1         LABEL(COBATRLG) LIB(FICHEROS) /* Traspasos */
             D1         LABEL(COBATROK) LIB(FICHEROS) /* Traspasos */
/*-------------------------------------------------------------------*/
             CALL       PGM(TRACE) PARM('FIN    GUARDA ' ' ' +
                          'COBATRCL')
             ENDPGM