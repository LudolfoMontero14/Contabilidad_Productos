     H DECEDIT('0,') DATEDIT(*DMY.) DFTACTGRP(*NO) actgrp(*NEW)
     H bnddir('EXPLOTA/CALDIG')
      *****************************************************************
      * -- CREA EN -BORECI- RECIBOS DE LA FACTURACION DE SOCIOS      **
      *                                                              **
      * -- 1/10/97 GENERA REGISTROS PARA TARJETAS VIRTUALES          **
      * -- 28/5/02 HACE UNA PASA CON EL RECIBL1 - NO EXT.UNIFICADO   **
      * -- 28/5/02 HACE UNA PASA CON EL RECIBL2 - SI EXT.UNIFICADO   **
      * -- 25/10/23 SOLO SE HACE LO QUE NO ES MASTERCARD             **
      *                                                              **
      *****************************************************************
     FCRFS01    IF   F   96        DISK
     FRECIBL1   UF   E             DISK    RENAME(RECIW:RECIW1)
     FRECIBL2   UF   E           K DISK    RENAME(RECIW:RECIW2)
     FCLESPAÑA  IF   E           K DISK
     FINDEBCO   IF   E           K DISK
     FCONTROEU  IF   E           K DISK
     FMSOCIO    IF   E           K DISK
     FAUNARTA   IF   E           K DISK
     FBORECI    O    E             DISK    RENAME(RECIW:BOREW)
     FASIRECFS  O    E             DISK
     FIMP00P7   O    F  132        PRINTER
     FIMP00P12  O    F  132        PRINTER

     FCABECERE  O    F   78        DISK
     FDETECERE  O    F  157        DISK
      *****************************************************************
      **                   S E R I E S  / T A B L A S                **
      *****************************************************************
     D TX              S             30    DIM(5) CTDATA PERRCD(1)              TEXTOS
     D TABA            S              3    DIM(18) CTDATA PERRCD(1)             CTAS.ABONO
     D TABB            S             12    DIM(18) ALT(TABA)
     D*--------
     D IPN             S              8  0 DIM(99)                              IMP.PZOS.VIRTUALES
     D IP              S             10    DIM(99)                              IMP.PZOS.VIRTUALES
     D PL              S             10    DIM(99)                              FEC.PZOS.VIRTUALES
     D PLN             S              8  0 DIM(99)                              FEC.PZOS.VIRTUALES
     D*--------
     D*                   EVI         4 25               EVI.CONTABLE  A
     D VE              S              8  0 DIM(100)                             EVI.CONTABLE
     D IV              S              9  0 DIM(100)                             EVI.CONTABLE
     D NR              S              8  0 DIM(4)                               EVI.CONTABLE
     D IR              S              9  0 DIM(4)                               EVI.CONTABLE
     D VT              S              8  0 DIM(4)                               EVI.CONTABLE
     D*****************************************************************

      *------------------------
      * BACKUP REG. DEL BORECI
      *------------------------
     D REBOIN        E DS                  EXTNAME(BORECI)
     D  NS8                    3     10  0
     D  NS7                    3      9  0
     D  CICLO                  3      6  0

     D                 DS
     D  CPO12B                17     28
     D  CCTAMA                17     21
     D  CCTAFI                22     23
     D  CCTAAU                24     28

      /COPY EXPLOTA/QRPGLESRC,DSNUMSOCI
      /copy EXPLOTA/QRPGLESRC,UTILSCONTH    // Utilidades contabilidad

     D EURO1           C                   CONST(166,386)
     D ESCUD1          C                   CONST(200,482)

      *-------------------
      * VTOS. ESPECIALES
      *-------------------
     Dfecvtoesp        S               d   datfmt(*eur)
     Dfecvtoamd        S               d   datfmt(*iso)

     D                 DS
     D  AEVIDE                 1     25
     D  NUMLIN                 1      5S 0  INZ(0)
     D  APUNTE                 6     11
     D  AMDSYS                12     19S 0
     D  APROVI                20     25S 0

     D fechaSistema    S               Z

     D esMastercard    S               n
     D escrCabec       S               n   INZ(*OFF)

        Dcl-s Wfecproces    Zoned(8);
        Dcl-s WApunte       Char(6);

     ICRFS01    ns
     I                                 50   57 0fecproces


        Clear REBOIN;
        Read  CRFS01;

        fechaSistema = %timestamp();
        WApunte = Asignar_Numero_Apunte(fechaSistema);
        fechaSistema = fechaSistema -  %days(1);

        AMDSYS = %dec(%char(%date(fechaSistema):*iso0):8:0);
        fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);
        APROVI = %Dec(%Time());
        APUNTE = WApunte;
        CAPUNT = WApunte;
        Wfecproces = fecproces;


     C*****************************************************************
     C**                    LECTURA DEL RECIBOS                      **
     C*****************************************************************
     C                   DO        *HIVAL
     C                   READ      RECIW1                                 01
     C  N01              EXSR      CMPESMC
     C  N01              IF        esMastercard
     C                   ITER
     C                   ENDIF
     C  N01              ADD       RPTS          TOTFIC           11 0
     C***************************
     C* RECIBO NORMAL
     C***************************
     C  N01              EXSR      PROCES
     C  N01              GOTO      FINDO
     C                   SETON                                        88
     C***************************
     C* EXTRACT UNIFICADO
     C***************************
     C                   DO        *HIVAL
     C                   READ      ECONTR                                 01
     C   01              GOTO      FIN
     C*---------------
     C     ECONBA        CABNE     'S'           FINDO3
     C                   Z-ADD     ENUTIT        NS8EU             8 0
     C     ESDOFI        COMP      0                                  212223    DEU/ACRE/CERO
     C     ESDORE        COMP      0                                  24        ACC.RECOBRO
     C     ESDOAC        COMP      0                                    25      SDOS ACREEDORES
     C                   Z-ADD     0             RIMPEU
     C   25
     CAN 21
     CANN24              Z-ADD     ESDOAC        RIMPEU            9 0
     C     ENUTIT        SETLL     RECIW2
     C*---------------------
     C                   DO        *HIVAL
     C                   READ      RECIW2                                 02
     C  N02RTITEU        COMP      ENUTIT                             02
     C   02              LEAVE

     C                   EXSR      CMPESMC
     C                   IF        esMastercard
     C                   ITER
     C                   ENDIF
     C                   ADD       RPTS          TOTFIC
     C                   Z-ADD     RVTORE        RVTORA            8 0
     C*----------------
     C* SDO FINAL ACREE
     C*----------------
     C     *IN22         IFEQ      '1'
     C                   MOVE      '1'           RELIM1                         NO BORECI
     C                   UPDATE    RECIW2
     C                   GOTO      FINDO2
     C                   ENDIF
     C*----------------
     C* S.F.DEUDOR SIN
     C* ACCIONES Y CON
     C* SDOS ACREEDORES
     C*----------------
     C     *IN21         IFEQ      '1'
     C     *IN24         ANDEQ     '0'
     C     *IN25         ANDEQ     '1'
     C                   MOVE      '1'           RELIM1                         NO BORECI
     C                   UPDATE    RECIW2
     C                   GOTO      FINDO1
     C                   ENDIF
     C*----------------
     C* S.F.DEUDOR CON
     C* ACCIONES Y SIN
     C* SDOS ACREEDORES
     C*----------------
     C     *IN21         IFEQ      '1'
     C     *IN24         ANDEQ     '1'
     C     *IN25         ANDEQ     '0'
     C                   MOVE      ' '           RELIM1                         SI BORECI
     C                   UPDATE    RECIW2
     C                   GOTO      FINDO1
     C                   ENDIF
     C*----------------
     C* S.F.DEUDOR CON
     C* ACCIONES Y CON
     C* SDOS ACREEDORES
     C*----------------
     C     *IN21         IFEQ      '1'
     C     *IN24         ANDEQ     '1'
     C     *IN25         ANDEQ     '1'
     C                   MOVE      ' '           RELIM1                         SI BORECI
     C                   UPDATE    RECIW2
     C                   GOTO      FINDO1
     C                   ENDIF
     C*----------------
     C* S.FINAL CERO
     C*----------------
     C     *IN21         IFEQ      '1'
     C     *IN24         ANDEQ     '1'
     C     *IN25         ANDEQ     '1'
     C                   MOVE      '1'           RELIM1                         NO BORECI
     C                   UPDATE    RECIW2
     C                   GOTO      FINDO2
     C                   ENDIF
     C*----------------
     C     FINDO1        TAG
     C                   ADD       RPTS          RIMPEU
     C     FINDO2        TAG
     C                   ENDDO
     C*---------------------
     C* GRABAR EN BORECI
     C*---------------------
     C     RIMPEU        IFGT      0
     C                   MOVEL     ENUTIT        RNUMSO
     C                   MOVE      SNUSO2        RNUMSO
     C                   MOVEL     SNOMBR        RNOMSO
     C                   MOVEL     SNOMBA        RNOMBA
     C                   MOVEL     SDOMBA        RDIRBA
     C                   MOVEL     SLOCBA        RLOCBA
     C                   Z-ADD     SZOBAN        RZONBA
     C                   MOVE      SNCTAC        RNUMCC
     C                   MOVEL     SMCTAC        RNOMCC
     C                   Z-ADD     RIMPEU        RPTS
     C                   MOVE      *BLANKS       RLIBR1
     C                   MOVE      *BLANKS       RLIBR2
     C                   MOVE      'E'           RLIBR5
     C                   Z-ADD     0             RFECRE
     C                   Z-ADD     NBANCO        RNUMBC
     C                   MOVE      ' '           RLIBR3
     C                   Z-ADD     SREGEM        RREGEM
     C                   MOVE      *BLANKS       RLIBR4
     C                   MOVE      ' '           RACCRE
     C                   Z-ADD     SSUBHA        RNUSUC
     C                   MOVE      ' '           RLIBR6
     C                   Z-ADD     RVTORA        RVTORE                         - NO VIRTUAL
     C                   Z-ADD     SDIAPR        RDIAPR
     C                   MOVE      STVPER        RVIRPE
     C                   MOVE      SPLAST        RVIRPL
     C     RIMPEU        MULT(H)   1,66386       REUROS
     C                   EXSR      PROCES
     C                   ENDIF
     C*---------------------
     C     FINDO3        TAG
     C                   ENDDO
     C***************************
     C     FINDO         TAG
     C                   ENDDO
     C*****************************************************************
     C     FIN           TAG
     C*---------------------
     C* CTAS.CARGO APUNTE
     C*---------------------
     C                   MOVEL     '4520 '       CCTAMA
     C                   MOVEL     '  '          CCTAFI
     C                   MOVE      '     '       CCTAAU
     C                   Z-ADD     450           CCODIG
     C                   MOVE      'D'           CDEHA
     C                   Z-ADD     TOTREC        CIMPOR
    $C                   MOVE      '1'           CMONED                         -EN EUROS
     C                   WRITE     ASIW
     C*----------------------------*
     C* ACTUALIZA TOTALES -BORECI- *
     C*----------------------------*
     C     TOTREC        IFGT      0
     C                   Z-ADD     UDATE         FECSYS            6 0
     C                   CALL      'ACUTOT'
     C                   PARM      'BORECI'      CLATOT            6            -CTMOS.EURO
     C                   PARM      TX(1)         TEXTO            30
     C                   PARM                    TOTREC
     C                   PARM                    FECSYS
     C                   END
     C*--
     C     FINFIN        TAG
     C     TOTFIC        SUB       TOTREC        TOTRED           11 0
     C                   EXCEPT    CABINC
     C                   EXCEPT    TOTFIN
     C*------------------
     C* TOTALES EVIENCIA
     C*------------------
     C                   Z-ADD     4             Y
     C                   EXSR      CREVID
     C                   EXCEPT    DETEV
     C*---
     C     1             DO        100           Y
     C     VE(Y)         IFNE      0
     C                   EXCEPT    DETOEV
     C                   ENDIF
     C                   ENDDO
     C*---
     C                   XFOOT     IV            TOTACU            9 0
     C                   EXCEPT    TOTEVI
     C*------------------
     C                   SETON                                        LR

     C*****************************************************************
     C* COMPRUEBA SI ES MASTERCARD
     C*****************************************************************
     C     CMPESMC       BEGSR

      * Comprueba si es Mastercard si existe el socio
        esMastercard = *off;
        Exec Sql
          SET :esMastercard = NUREAL_ES_MASTERCARD(:NS8);

     C                   ENDSR

     C*****************************************************************
     C* SUBRUTINA ACUMULACION AL BORECI
     C*****************************************************************
     C     PROCES        BEGSR
     C*---------------
     C     NS8           CHAIN     MSOCIOW                            13
     C*--------------------------
     C* OMISION TARJETAS CAIXA
     C*--------------------------
     C  N13SCOBHA        IFEQ      'X'
     C                   SUB       RPTS          TOTFIC
     C                   GOTO      FPROCE
     C                   END
     C*---------------
     C                   MOVE      *BLANKS       PAIS              1
     C*---------------
     C  N13SCOBHA        IFEQ      'O'
     C*                  MOVE      'P'           PAIS
     C                   MOVE      'E'           PAIS
     C                   ELSE
     C                   MOVE      'E'           PAIS
     C                   ENDIF
     C*---------------
     C* CHAIN INDEBCO
     C*---------------
     C     VERBAN        TAG
     C     KINDEB        KLIST
     C                   KFLD                    KEYBCO
     C                   KFLD                    PAIS
     C                   MOVE      RNUMBC        KEYBCO            4 0
     C     KINDEB        CHAIN     INDBCO                             03
     C*-----------
     C* NO BANCO
     C*-----------
     C   03SCOBHA        IFEQ      'Z'
     C     SBCHRE        ANDGT     0
     C                   Z-ADD     49            RNUMBC
     C                   Z-ADD     SBCHRE        RNUSUC
     C  N99              EXCEPT    CABINC
     C  N99              SETON                                        99
     C                   EXCEPT    DETINC
     C  N88              UPDATE    RECIW1                                       **RECIBOS**
     C   88              UPDATE    RECIW2                                       **RECIBOS**
     C                   GOTO      VERBAN
     C                   END
     C*-----------
     C   03TX(5)         DSPLY                   RNUMBC
     C   03              GOTO      FINFIN
     C                   MOVE      ESTADO        RESTAD
     C*--------------------------
     C                   MOVE      '0'           RREPRE
    $C                   ADD       RPTS          TOTREC           10 0          -CTMOS.EURO
     C*--------------------------
     C* RECIBO SIN VTO. -AVISO-
     C*--------------------------
     C     RVTORE        IFEQ      0
     C     TX(4)         DSPLY                   RNUMSO
     C                   GOTO      FINFIN
     C                   END
     C*--------------
     C* FECHA PROCESO
     C*--------------
     C                   Z-ADD     *DATE         RFECRE                         -DDMMAAAA-
     C*-----------------
     C* FECHA VTO.RECIBO
     C*-----------------
     C                   Z-ADD     RVTORE        RVTOR8            8 0          -DDMMAAAA-
     C                   MOVEL     RVTOR8        RDDVTO            2 0          -DD-
     C                   MOVE      RVTOR8        RAAVTO            4 0          -AAAA-
     C     RVTOR8        DIV       100           RVENTO            8 0          -  DDMMAA-
     C                   MOVEL     RAAVTO        RVENTO                         -AAAAMMAA-
     C                   MOVE      RDDVTO        RVENTO                         -AAAAMMDD-
     C*---------------------
     C* CHAIN CLESPAÑA
     C*---------------------
     C     CICLO         CHAIN     CLESPA                             10
     C   10TX(3)         DSPLY                   CICLO
     C   10              GOTO      FINFIN
     C*---------------
     C* TARJETAS -PE-
     C*---------------
     C     INDSER        IFGE      13
     C     INDSER        ANDLE     18
     C                   ADD       1             RDIAPR
     C                   END
     C*-------------------------
     C* VTOS TARJ VIRTUALES
     C*-------------------------
     C     RVIRPE        COMP      0                                  56        TARJ. VIRTUAL
     C   56RVIRPE        MULT      5             VIRPER            3 0
     C   56RVIRPL        COMP      0                                  56        TARJ. VIRTUAL
    $C   56              Z-ADD     RPTS          PTSPZO            8 0          -CTMOS.EURO
     C   56              Z-ADD     *DATE         FECPRO            8 0
     C   56              CALL      'VIRTA3'
     C                   PARM                    FECPRO                         DDMMAAAA DESDE
     C                   PARM                    PTSPZO                         TOTAL APLAZAR
     C                   PARM                    VIRPER                         PERIODICIDAD
     C                   PARM                    RVIRPL                         NUM.PLAZOS
     C                   PARM                    IP                             IMP.PLAZOS ALF.
     C                   PARM                    PL                             FEC.PLAZOS
     C                   PARM                    IPN                            IMP.PLAZOS NUM.
     C                   PARM                    PLN                            FEC.PLAZOS NUM.
     C   56              Z-ADD     0             CC                3 0
     C   56              Z-ADD     RVIRPL        PZOS              3 0
     C  N56              Z-ADD     1             PZOS              3 0
    $C                   Z-ADD     RPTS          PTSTOT            9 0          -CTMOS.EURO
     C*--------------------------
     C* GRABO EN BOLSA -BORECI-
     C*--------------------------
     C                   DO        PZOS
     C   56              ADD       1             CC                3 0
    $C   56              Z-ADD     IPN(CC)       RPTS                           -CTMOS.EURO
     C   56              Z-ADD     PLN(CC)       RVENTO
     C                   Z-ADD     0             RESCUD
     C                   Z-ADD     0             REUROS
    $C                   MOVE      RPTS          EUROS             9 2          -EUROS-
    $C*-
    $C     EUROS         MULT(H)   EURO1         REUROS                         -PESETAS-
    $C*-
    $C     PAIS          IFEQ      'P'                                          ---------
    $C     EUROS         MULT(H)   ESCUD1        RESCUD            9 0          -ESCUDOS-
    $C                   ENDIF                                                  ---------
     C*---------------------------------------------------------------------------------------------
     C*                               Asteriscado: 31-1-2014                                       |
     C*                               ======================                                       |
     C* vtos especiales: Grupo Danone                                           cuando se programe |
     C*--------------------------                                               este tipo de vtos ,|
     C*                  if        ns7 = 3347404 or                             eliminar este trozo|
     C*                            ns7 = 3347407 or                             de calculo.        |
     C*                            ns7 = 1884771                                                   |
     C*                  move      fecproces     fecvtoesp                                         |
     C*                  adddur    3:*m          fecvtoesp                                         |
     C*                  move      fecvtoesp     fecvtoamd                                         |
     C*                  move      fecvtoamd     rvento                                            |
     C*                  move      01            rvento                                            |
     C*                  endif                                                                     |
     c*--------------------------------------------------------------------------------------------|
     C*--------------------------
     C*   SOLUCION -AUNA-       
     C*--------------------------
     C                   SETON                                        14
     C     NS8           CHAIN     AUNASOW                            14
     C*-
     C                   IF        *IN14 = '0'
     C                   Z-ADD     NS8           RSAUNA
     C                   MOVE      ANUMCUE       RNUMCC
     C                   MOVEL     ANOMCUE       RNOMCC
     C                   Z-ADD     ANUMBCO       RNUMBC
     C                   Z-ADD     ANUMSUC       RNUSUC
     C     ATARMAT       CHAIN     MSOCIOW                            13
     C                   Z-ADD     MS14_NU       RNUMSO
     C                   ELSE
     C                   Z-ADD     0             RSAUNA
     C                   ENDIF
     C*--------------------------
     C                   Z-ADD     RREGEM        RNREEM                         -Nº.REGISTRO EMPRESA
     C                   WRITE     BOREW                                        ** BORECI **
     C*-------------------
     C* EVIDENCIA CONTABLE
     C*-------------------
     C                   EXSR      CREVID
     C*-------------------
     C                   END
     C*--------------------------
     C* CTAS.ABONO APUNTE
     C*--------------------------
     C                   MOVEL     MODALI        KTABA             3
     C                   MOVE      RDIAPR        KTABA             3
     C*---
     C     KTABA         LOOKUP    TABA          TABB                     02
     C  N02TX(1)         DSPLY                   KTABA
     C  N02              GOTO      FINFIN
     C                   MOVE      TABB          CPO12B
     C*--
     C                   MOVE      522           CCODIG
     C                   MOVE      'CEREFS'      CPROGR
     C*****                   Z-ADD     *DATE         CFECON
            CFECON = fecproces;
     C                   MOVE      'H'           CDEHA
     C                   MOVE      *BLANK        CREFOP
     C                   Z-ADD     0             CFEVTO
     C                   MOVE      *BLANKS       CCONCE
     C                   Z-ADD     PTSTOT        CIMPOR
    $C                   MOVE      '1'           CMONED                         -EN EUROS
     C                   WRITE     ASIW
     C*--------------------------
     C                   Z-ADD     0             RNUMSO
     C                   MOVE      *BLANKS       RNUMCC
     C                   Z-ADD     0             RPTS                           -CTMOS.EURO
     C                   Z-ADD     0             REUROS                         -PESETAS
     C                   Z-ADD     0             RESCUD                         -ESCUDOS
     C                   Z-ADD     0             RFECRE
     C                   Z-ADD     0             RNUMBC
     C                   Z-ADD     0             RNUSUC
     C                   Z-ADD     0             RNREEM
     C     FPROCE        TAG
     C                   ENDSR
     C*****************************************************************
     C* EVIDENCIA CONTABLE
     C*****************************************************************
     C     CREVID        BEGSR
     C*----------------
     C* CABECERA
     C*----------------

        NUMLIN += 1;

     C                   IF        NOT escrCabec
     C                   EVAL      escrCabec = *ON
     C                   EXCEPT    CABERE
     C**                   EVAL      NUMLIN = NUMLIN + 1
     C                   EXCEPT    CABEV
     C                   ENDIF
     C*----------------
     C* LINEA COMPLETA
     C*----------------
     C     Y             IFGE      4
     C                   EXCEPT    DETEV
     C*--
     C                   ADD       1             LIN               3 0
     C                   Z-ADD     0             Y                 3 0
     C                   MOVE      *ZEROS        NR
     C                   MOVE      *ZEROS        IR
     C                   MOVE      *ZEROS        VT
     C                   ENDIF
     C*----------------
     C                   ADD       1             Y                 3 0
     C                   Z-ADD     NS8           NR(Y)
     C                   Z-ADD     RPTS          IR(Y)
     C                   Z-ADD     RVENTO        VT(Y)
     C                   Z-ADD     1             Z                 3 0
     C     RVENTO        LOOKUP    VE(Z)                                  33
     C  N33*ZEROS        LOOKUP    VE(Z)                                  33
     C   33              ADD       RPTS          IV(Z)
     C   33              MOVEL     RVENTO        VE(Z)
     C*----------------
     C                   ENDSR
     C*****************************************************************

     OIMP00P7   E            CABINC            4
     O                                            6 'CEREFS'
     O                                           40 'INCIDENCIAS EN LA CREACI'
     O                                           64 'ON DE LA BOLSA DE RECIBO'
     O                                           68 'S AL'
     O                       UDATE         Y     77
     O                                          128 'PAG.'
     O                       PAGE          Z    132
     O                                          100 '** SOCIOS **'
     O          E            CABINC      1
     O                                           40 '------------------------'
     O                                           64 '------------------------'
     O                                           68 '----'
     O                                           77 '---------'
     O          E            CABINC      2
     O                                           10 'NO. REAL'
     O                                           22 'INCIDENCIAS'
     O          E            CABINC      1
     O                                           10 '--------'
     O                                           22 '-----------'
     O          E            DETINC      1
     O                       NS8                 10
     O                                           35 'SOCIO BANCO Y CON NUMERO'
     O                                           60 ' DE BANCO CERO, SE HA CR'
     O                                           84 'EADO EL  RECIBO CON EL B'
     O                                          106 'ANCO       Y SUCURSAL '
     O                       RNUMBC              94
     O                       RNUSUC             110
     O                                          131 '- ARREGLAR MSOCIO -'
     OIMP00P12  E            CABINC            4
     O                                            6 'CEREFS'
     O                                           40 'CONTROL TOTALES RECIBOS '
     O                                           64 'EN LA ACUMULACION AL BOR'
     O                                           68 'ECI '
     O                       UDATE         Y     77
     O                                          128 'PAG.'
     O                       PAGE          Z    132
     O                                          105 '** EXPLOTACION **'
     O          E            CABINC      1
     O                                           40 '------------------------'
     O                                           64 '------------------------'
     O                                           68 '----'
     O                                           77 '---------'
     O          E            TOTFIN      3
     O                       TOTREC              23 '  .   .   ,  '
     O                                              ' * ACUMULADO AL TOTALES'
     O                                              ', VERIFICARLO.'
     O          E            TOTFIN      2
     O                       TOTRED              23 '   .   .   ,  '
     O                                              ' * REDUCIDOS POR EXT. U'
     O                                              'NIFICADO    '
     O          E            TOTFIN      2
     O                                           23 '------------'
     O          E            TOTFIN      1
     O                       TOTFIC              23 '   .   .   ,  '
     O                                              ' * TOTAL RECIBOS -ACUMU'
     O                                              'LAR BORECI- DEL FSBALA,'
     O                                              'VERIFICARLO.           '
      *
     OCABECERE  E            CABERE
     O                                           24 'CEREFS-ADICION RECIBOS'
     O                                           35 ' A LA BOLSA'
     O                       WFECPROCES    Y     46
     O                       APUNTE              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       APROVI              78
     ODETECERE  E            CABEV
     O                                            8 'CEREFS'
     O                                           40 'EVIDENCIA CONTABLE ADICI'
     O                                           64 'ON DE RECIBOS A LA BOLSA'
     O                                           68 ' AL '
     O                       UDATE         Y     77
     O                                          105 '** CONTABILIDAD **'
     O                                          128 'PAG.'
     O                       PAGE          Z    132
     O                       AEVIDE             157
     O          E            CABEV
     O                                           40 '------------------------'
     O                                           64 '------------------------'
     O                                           68 '----'
     O                                           77 '---------'
     O                       AEVIDE             157
     O          E            CABEV
     O                                            9 'NUM. REAL'
     O                                           23 'IMP. RECIBO '
     O                                           32 'VENCIMTO'
     O                                           42 'NUM. REAL'
     O                                           55 'IMP. RECIBO '
     O                                           64 'VENCIMTO'
     O                                           74 'NUM. REAL'
     O                                           87 'IMP. RECIBO '
     O                                           96 'VENCIMTO'
     O                                          106 'NUM. REAL'
     O                                          119 'IMP. RECIBO '
     O                                          128 'VENCIMTO'
     O                       AEVIDE             157
     O          E            CABEV
     O                                            9 '---------'
     O                                           23 '------------'
     O                                           32 '--------'
     O                                           42 '---------'
     O                                           55 '------------'
     O                                           64 '--------'
     O                                           74 '---------'
     O                                           87 '------------'
     O                                           96 '--------'
     O                                          106 '---------'
     O                                          119 '------------'
     O                                          128 '--------'
     O                       AEVIDE             157
     O          E            DETEV
     O                       NR(1)          B     9 '    -    '
     O                       IR(1)          B    23 ' .   .   ,  '
     O                       VT(1)         ZB    32
     O                       NR(2)          B    42 '    -    '
     O                       IR(2)          B    55 ' .   .   ,  '
     O                       VT(2)         ZB    64
     O                       NR(3)          B    74 '    -    '
     O                       IR(3)          B    87 ' .   .   ,  '
     O                       VT(3)         ZB    96
     O                       NR(4)          B   106 '    -    '
     O                       IR(4)          B   119 ' .   .   ,  '
     O                       VT(4)         ZB   128
     O                       AEVIDE             157
     O          E            DETOEV
     O                       VE(Y)               40 '    -  -  '
     O                       IV(Y)               55 ' .   .   ,  '
     O                       AEVIDE             157
     O          E            TOTEVI
     O                       TOTACU              55 ' .   .   ,  '
     O                                              ' EUROS ACUMULADOS LA '
     O                                              'BOLSA DE RECIBOS     '
     O                       AEVIDE             157
**
ACUMULACION DESDE -FAC.SOC.-
ELEMENTO NO EN TABA,AVISO EXP.
CICLO NO EN CLESPAÑA,AVISO EX.
RECIBO SIN VTO, AVISO EXPLOTA.
BCO NO EN INDEBCO, SE CANCELA
**
1054300 0305                 SOC.FDO.LOCAL CENTRO
1104300 0310                  "   "   "    EMP.10
1114300 0311                  "   "   "    PER.EMP.10
1154300 0315                  "   "   "    PROV
1204300 0320                  "   "   "    EMP.20
1214300 0321                  "   "   "    PER.EMP.20
1254300 0325                  "   "   "    BARNA
1304300 0330                  "   "   "    EMP.30
1314300 0331                  "   "   "    PER.EMP.30
0054303 0305                 SOC.FDO.INTER.CENTRO
0104303 0310                  "   "   "    EMP.10
0114303 0311                  "   "   "    PER.EMP.10
0154303 0315                  "   "   "    PROV
0204303 0320                  "   "   "    EMP.20
0214303 0321                  "   "   "    PER.EMP.20
0254303 0325                  "   "   "    BARNA
0304303 0330                  "   "   "    EMP.30
0314303 0331                  "   "   "    PER.EMP.30
