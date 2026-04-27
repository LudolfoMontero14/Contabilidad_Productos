/*********************************************************************/
/**                 --CONCILIACION CTAS. DE VIAJES--                **/
/**                                                                 **/
/**     OPERATIVA DIARIA: LIMPIEZA DE BOLSAS (AGENCIA/PROVEEDOR)    **/
/**                                                                 **/
/**     ASIENTO'S/ANEXO'S/EVIDENCIA'S  --DEPART.CONTABILIDAD--      **/
/**     FORMATO ASIFILEN                                            **/
/*********************************************************************/
             PGM        PARM(&FECHA1)
             DCL        VAR(&DATOS) TYPE(*CHAR) LEN(14) +
                          VALUE('COLIMBCL')
             DCL        VAR(&FECHA1) TYPE(*CHAR) LEN(6)
             DCL        VAR(&TEX)    TYPE(*CHAR) LEN(50)
             DCL        VAR(&NUMREG) TYPE(*DEC)  LEN(10 0)
             DCL        VAR(&BLOQUEA) TYPE(*CHAR) LEN(1)
             DCL        VAR(&MSG)    TYPE(*CHAR) LEN(240) VALUE('Por +
                          favor, salga al menu durante 5 minutos +
                          para que el programa COLIMBCL pueda usar +
                          el fichero PA. De no ser así, pasados +
                          unos segundos se cancelará.')

             DCL        VAR(&NOMPARA) TYPE(*CHAR) LEN(10)

             CHGJOB     DATE(&FECHA1)
/*------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE3) PARM(&DATOS)

             CALL       PGM(EXPLOTA/TRACE) PARM('CADENA DE TRABAJO +
                          PARA CREAR "ASIENTO/ANEXOS" LIMPIEZA +
                          BOLSAS CONCILIACION    ' ' ' COLIMBCL)
/*-------------------------------------------------------------------*/
/* ALOCATAR EL PA DURANTE UNOS SEGUNDOS PARA CREAR EL FIFS01         */
/*-------------------------------------------------------------------*/
 ALOCPA:     ALCOBJ     OBJ((FICHEROS/PA      *FILE *EXCL))
             MONMSG     CPF0000 *NONE EXEC(DO)
             CALL       PGM(EXPLOTA/TRACE) PARM('El fichero PA esta +
                          alocatado por otro +
                          trabajo.                                ' +
                          ' ' COLIMBCL)
             CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0064' ' '  COLIMBCL)
             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(PA *FILE +
                          FICHEROS &MSG &BLOQUEA)

             GOTO       ALOCPA
             ENDDO
             CL1        FIFS01 FICHEROS 1
             DLCOBJ     OBJ((FICHEROS/PA *FILE *EXCL))
/*-------------------------------------------------------------------*/
/*    ALOCATAR FICHERO -COLIMBOL- (LIMPIEZA BOLSAS CONCILIACION)    */
/*-------------------------------------------------------------------*/
 ALOCA:      ALCOBJ     OBJ((FICHEROS/COLIMBOL *FILE *EXCL))
             MONMSG     CPF0000 *NONE EXEC(DO)

             CALL       PGM(EXPLOTA/TRACE) PARM(':DIN0042' ' ' COLIMBCL)
             CALL       PGM(EXPLOTA/TRACE) PARM(' El fichero +
                          -COLIMBOL- esta siendo utilizado por el +
                          departamento de       ' ' ' COLIMBCL)
             CALL       PGM(EXPLOTA/TRACE) PARM(' CONCILIACION, +
                          avisarles para dejar de utilizar la +
                          Limpieza de Bolsas.    ' ' ' COLIMBCL)

             CHGVAR     VAR(&BLOQUEA) VALUE(' ')

             CALL       PGM(EXPLOTA/DESBLOQUE3) PARM(COLIMBOL *FILE +
                          FICHEROS &MSG &BLOQUEA)

             GOTO       CMDLBL(ALOCA)
             ENDDO
/*-------------------------------------------------------------------*/
/*-- CONTROL: IMPIDE ACCEDER A LAS OPCIONES DE LIMPIEZA DE BOLSAS  --*/
/*-------------------------------------------------------------------*/
             CL1        LABEL(COLIMBOAN) LIB(FICHEROS)
/*-------------------------------------------------------------------*/
/*  RENOMBRA FICHERO -COLIMBOL- Y CREAR LIMPIO PARA EL DIA SIGUIENTE */
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('COLIMBCL, FICHERO DE ENTRADA')

             CALL       PGM(EXPLOTA/CONCOPCL) PARM(COLIMBOL FICHEROS +
                          COLIMBOL LIBSEG1D C ' ' ' ' &TEX COLIMBCL)

             RNMOBJ     OBJ(FICHEROS/COLIMBOL) OBJTYPE(*FILE) +
                          NEWOBJ(COLIMBOK)

             DLCOBJ     OBJ((FICHEROS/COLIMBOK *FILE *EXCL))

             CRTPF      FILE(FICHEROS/COLIMBOL) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          TEXT('conciliacion, limpieza de bolsas +
                          -agencia/pa-') OPTION(*NOLIST *NOSRC) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
/*-------------------------------------------------------------------*/
/*--          VER SI TIENE REGISTROS  FICHERO -COLIMBOK-             */
/*-------------------------------------------------------------------*/
             CHKOBJ     OBJ(FICHEROS/COLIMBOK) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(FIN))

             RTVMBRD    FILE(FICHEROS/COLIMBOK) NBRCURRCD(&NUMREG)

             IF         COND(&NUMREG = 0) THEN(DO)
             GOTO       CMDLBL(FIN)
             ENDDO
/*-------------------------------------------------------------------*/
/*--              CREACION FICHEROS (ANEXOS/ASIENTOS)              --*/
/*-------------------------------------------------------------------*/
             CRTPF      FILE(FICHEROS/ANEXOLBC) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(ANEXO) +
                          TEXT('conciliacion, anexos limpieza de +
                          bolsas -ag/pa-') OPTION(*NOSRC *NOLIST) +
                          SIZE(*NOMAX) LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000 EXEC(CLRPFM FICHEROS/ANEXOLBC)

/*--------------------------------------------------------*/
/*    Nueva version del COLIMB (COLIMBN)             LM   */
/*    PARALELO - Contabilidad por Producto                */
/*--------------------------------------------------------*/
        CALL PGM(EXPLOTA/CONTAB000) +                       
             PARM(('COLIMBCLM') +                               
                  ('COLIMBN_P') +                           
                  (&NOMPARA))                               
                                                            
/*--------------------------------------------------------*/

             CRTPF      FILE(FICHEROS/ASICOLIB) +
                          SRCFILE(FICHEROS/QDDSSRC) +
                          SRCMBR(ASIFILEN) TEXT('conciliacion, +
                          asiento limpieza de bolsas -ag/pa-') +
                          OPTION(*NOSRC *NOLIST) SIZE(*NOMAX) +
                          LVLCHK(*NO) AUT(*ALL)
             MONMSG     CPF0000 EXEC(CLRPFM FICHEROS/ASICOLIB)
/*----------------**/
/**  C O L I M B  **/
/*----------------**/
             CALL       PGM(EXPLOTA/TRACE) +
                          PARM('                             +
                          PROGRAMA -COLIMB- EN +
                          EJECUCION                   ' ' ' COLIMBCL)

             CRTPF      FILE(FICHEROS/DETE29) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(DETEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/DETE29))

             CRTPF      FILE(FICHEROS/CABE29) +
                          SRCFILE(FICHEROS/QDDSSRC) SRCMBR(CABEVI) +
                          OPTION(*NOSRC *NOLIST) LVLCHK(*NO) AUT(*ALL)
             MONMSG     MSGID(CPF0000) EXEC(CLRPFM +
                          FILE(FICHEROS/CABE29))

             CALL       PGM(EXPLOTA/COLIMB)

/*-------------------------------------- */
/* Copias Parciales Evidencias Contables */
/*-------------------------------------- */
             CPYF       FROMFILE(FICHEROS/DETE29) +
                          TOFILE(FICHEROS/DETEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CPYF       FROMFILE(FICHEROS/CABE29) +
                          TOFILE(FICHEROS/CABEVI) MBROPT(*ADD) +
                          FMTOPT(*NOCHK)

             CHGVAR     VAR(&TEX) VALUE('COLIMBCL, DESPUES DEL +
                          PGM-COLIMB')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(DETE29 FICHEROS +
                          DETE29 LIBSEG1D C ' ' ' ' &TEX COLIMBCL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(CABE29 FICHEROS +
                          CABE29 LIBSEG1D C ' ' ' ' &TEX COLIMBCL)
/*-------------------------------------------------------------------*/
/*                 --- FUSIONAR ASIENTOS--  (COLIMB_N)             --*/
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('COLIMBCL, ANTES DE +
                          FUSIONAR-EJECUTAR PGM-COLIMB_N')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASICOLIB FICHEROS +
                          ASICOLIB LIBSEG1D C ' ' ' ' &TEX COLIMBCL)

             CALL       PGM(EXPLOTA/COLIMB_N)

    /*------------------------------------------------------*/
    /* Copia de Registros a Historicos                      */
    /*------------------------------------------------------*/
    CALL       PGM(CONTAB102)       +
               PARM('ASICOLIB'      +
                    'CABE29'        +
                    'DETE29'        +
                    &NOMPARA        +
                    'N'             +
                    'P')

/*-------------------------------------------------------------------*/
/*                 ACUMULACION ASIENTOS AL ASIBOLSA                --*/
/*-------------------------------------------------------------------*/
             CALL       PGM(EXPLOTA/TRACE) PARM(('PROGRAMA  ACASBO  +
                          EN EJECUCION') (' ') (COLIMBCL))

             OVRDBF     FILE(ASIFILE) TOFILE(FICHEROS/ASICOLIB)
             CALL       PGM(EXPLOTA/ACASBON) PARM('026')
             DLTOVR     FILE(ASIFILE)
/*-------------------------------------------------------------------*/
/*                      COPIAS DE SEGURIDAD                        --*/
/*-------------------------------------------------------------------*/
             CHGVAR     VAR(&TEX) VALUE('COLIMBCL, DESPUES DE +
                          EJECUTAR PGM-COLIMB')
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ASICOLIB FICHEROS +
                          ASICOLIB LIBSEG1D M ' ' ' ' &TEX COLIMBCL)
             CALL       PGM(EXPLOTA/CONCOPCL) PARM(ANEXOLBC FICHEROS +
                          ANEXOLBC LIBSEG1D C ' ' ' ' &TEX COLIMBCL)
/*-------------------------------------------------------------------*/
/*--               FICHERO DE ANEXOS: ¿ VACIO ?                    --*/
/*-------------------------------------------------------------------*/
             RTVMBRD    FILE(FICHEROS/ANEXOLBC) NBRCURRCD(&NUMREG)
             IF         COND(&NUMREG = 0) THEN(DO)
             DLTF       FILE(FICHEROS/ANEXOLBC) /* Anexos */
             ENDDO
/*-------------------------------------------------------------------*/
/*--                       ---- F I N ----                         --*/
/*-------------------------------------------------------------------*/
 FIN:        DLTF       FILE(FICHEROS/COLIMBOK) /* Bolsa Limpieza */
       /*    DLTF       FILE(FICHEROS/COLIMBOAN) Listado Anexos */
             CALL       PGM(EXPLOTA/TRACE) PARM('FIN' ' ' 'COLIMBCL')
             ENDPGM