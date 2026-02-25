     H DECEDIT('0,') DATEDIT(*DMY.)
      ***************************************************************
      *          ANEXOS:  APUNTE CONTABLE
      *                   ---------------
      * H1-CICLO NO EN CLESPAÑA
      * H2-NUEVO GRUPO U OPCION
      *     - CADA TABLA TIENE UNA EXPLICACION AL FINAL DEL PROGRAMA.
      ***************************************************************
      * Modificado por: Jose Daniel Martin Perez    29.04.2024
      * .- Se incorpora funcion de Mastercard, para no consultar
      *    clespaña
      ***************************************************************
     FGRANELG4  IF   E           K DISK
     FCLESPAÑA  IF   E           K DISK
     FCALESTAB  IF   E           K DISK
     FMSOCIO    IF   E           K DISK
     FCXNUFI    IF   E           K DISK
     FGRANEPU   O    E             DISK
     FASIFILE   UF A E           K DISK
      *****************************************************************
      **                S E R I E S  /  T A B L A S                  **
      *****************************************************************
     D TX              S             35    DIM(9) CTDATA PERRCD(1)
     D TABA            S              3    DIM(18) CTDATA PERRCD(1)
     D TABB            S             12    DIM(18) ALT(TABA)
     D TABC            S              2    DIM(17) CTDATA PERRCD(1)
     D TABD            S             12    DIM(17) ALT(TABC)
     D TABE            S              1    DIM(6) CTDATA PERRCD(1)
     D TABF            S              3    DIM(6) ALT(TABE)
     D TABI            S              1    DIM(36) CTDATA PERRCD(36)
     D TABJ            S              1    DIM(36) ALT(TABI)
     D RO              S             18    DIM(500)
     D TABK            S              2    DIM(30) CTDATA PERRCD(1)
     D TABL            S              2    DIM(30) ALT(TABK)
     D TABM            S              2    DIM(7) CTDATA PERRCD(1)
     D TABN            S              1    DIM(7) ALT(TABM)

     D CCONC1          S             30

     D                 DS
     D  GNS14D                 1     14  0
     D  CICLO                  3      6  0
     D  NREAL                  7     10
     D  NS8                    3     10  0
     D  NS8a                   3     10
     D*---
     D  CPO12B                15     26
     D  CCTAMA                15     19
     D  CCTAFI                20     21
     D  CCTAAU                22     26
     D*---
     D  CPO12A                27     38
     D  ACTAMA                27     31
     D  AFIASO                32     33
     D  ACTAUX                34     38
     D*---
     D  CAPUNT                39     44
     D  AAPUNT                39     44
     D*---
     D  CPO12C                45     56
     D  CTAMA3                45     47
     D  CCTAMC                45     49
     D  CCTAFC                50     51
     D  CCTAAC                52     56
     D*---
     D                 DS
     D  FECHA                  1      8  0
     D  AÑOC                   1      4
     D  MESC                   5      6
     D  DIAC                   7      8
     D*---
     D                 DS
     D  FECHA2                 1      8  0
     D  DIAD                   1      2
     D  MESD                   3      4
     D  AÑOD                   5      8

       Dcl-s  esMastercard ind;

     C*----------------------------
     C* FECHA PARA CONCEPTOS APUNTE
     C*----------------------------
     C                   Z-ADD     UDATE         KFECHA            8 0
     C                   MOVEL     *YEAR         KFECHA
     C                   MOVE      UDAY          KFECHA
     C     KFECHA        SETGT     CALESW
     C*---
     C     *IN01         DOWEQ     *OFF
     C  N03FDIA          COMP      'J'                                    02
     C  N03
     CAN 02FCALEN        COMP      ' '                                0202
     C                   READ      CALESW                                 01
     C*---
     C  N01UMONTH        IFGE      05
     C     UMONTH        ANDLE     09
     C     FDIA          ANDEQ     'S'
     C                   MOVE      'F'           FCALEN
     C                   END
     C*---
     C   03
     CANN01FDIA          IFEQ      'S'
     C                   SETOFF                                       0203
     C                   MOVE      'F'           FCALEN
     C                   END
     C   02
     CANN01FDIA          COMP      'V'                                    02
     C   02
     CANN01FCALEN        COMP      ' '                                0303
     C*---
     C  N01FCALEN        COMP      ' '                                    01
     C  N01              END
     C*---
     C                   MOVE      *BLANKS       CPO18B           18
     C*-------------------------
     C* PROCESO GRANELG4
     C*-------------------------
     C                   DO        *HIVAL
     C                   READ      GRANEW                                 01
     C   01              GOTO      FINPRE
     C     GFPROC        IFEQ      0
     c     gmepag        andne     'C'
     C*++++++++++++++++++++++++++++++++++++++++++++++++
     C*              CTAS.ABONO APUNTE
     C*++++++++++++++++++++++++++++++++++++++++++++++++
      * Comprueba si es Mastercard para no hacer nada
         Exec Sql
             SET :esMastercard = NUREAL_ES_MASTERCARD(:NS8);
     C*----------------------
     C* CHAIN CLESPAÑA/MSOCIO
     C*---------------------
          If Not esMastercard;
     C     CICLO         CHAIN     CLESPA                             10
          Else;
            *in10 = *Off;
     C*   10TX(6)         DSPLY                   CICLO
     C*   10              GOTO      FIN
          Endif;
     C*---------------------
     C     NS8           CHAIN     MSOCIOW                            10
     C   10TX(9)         DSPLY                   NS8
     C   10              GOTO      FIN
     C*---------------------
           If Not esMastercard;
     C     INDSER        IFGE      13
     C     INDSER        ANDLE     18
     C                   ADD       1             SDIAPR
     C                   END
           Endif;
     C*--
     C                   MOVEL     MODALI        KTABA             3
     C                   MOVE      SDIAPR        KTABA             3
     C*---
     C     KTABA         LOOKUP    TABA          TABB                     02
     C  N02TX(1)         DSPLY                   KTABA
     C  N02              GOTO      FIN
     C                   MOVE      TABB          CPO12B
     C*---------------
     C* TODOS
     C*---------------
     C                   MOVE      522           CCODIG
     C*--
     C                   MOVE      'LIAN03'      CPROGR
     C                   Z-ADD     *DATE         CFECON
     C                   MOVE      'H'           CDEHA
     C                   MOVE      *BLANK        CREFOP
     C                   Z-ADD     0             CFEVTO
     C                   Z-ADD     0             CTIPOP
     C                   MOVE      *BLANKS       CCONCE
     C                   MOVE      '1'           CMONED
     C                   Z-ADD     GIMDET        IMPORH           10 0
      /Free
         CHAIN (CAPUNT:CDEHA:CREFOP:CCTAMA:CCTAFI:CCTAAU:CCODIG:CFEVTO) ASIW;
      /End-Free
     C                   IF        %FOUND
     C                   ADD       IMPORH        CIMPOR
     C                   UPDATE    ASIW
     C                   ELSE
     C                   Z-ADD     GIMDET        CIMPOR
     C                   WRITE     ASIW
     C                   END
     C*-----------
     C* SOLO CAIXA
     C*-----------
     c     scobha        caseq     'X'           especialcaixa
     c                   end
     C*------------------------------------------------
     C* FICHERO GRANEPU-EVIDENCIA CONTABLE
     C*------------------------------------------------
     C                   MOVEL     GMEPAG        KEYTAB            2
     C                   MOVE      GGRUPO        KEYTAB
     C     KEYTAB        LOOKUP    TABK          TABL                     02
     C  N02              SETON                                        H2
     C  N02              GOTO      FIN
     C                   MOVE      TABL          AINDI
     C                   MOVE      CPO12B        CPO12A
     C                   MOVE      GIMDET        AIMPOR
     C                   MOVE      GNS14D        ANS14D
     C                   WRITE     APUNW
     C*++++++++++++++++++++++++++++++++++++++++++++++++
     C*             CTAS.CARGO APUNTE
     C*++++++++++++++++++++++++++++++++++++++++++++++++
     C*-------------
     C* COD.CONCEPTO
     C*-------------
     C     GMEPAG        LOOKUP    TABE          TABF                     02
     C  N02TX(3)         DSPLY                   GMEPAG
     C  N02              GOTO      FIN
     C                   MOVE      TABF          CCODI1            3 0
     C*--------------------------------
     C*      CTAS CARGO ESPECIAES:
     C*--------------------------------
     C                   MOVE      '  '          KEYTAC
     C                   MOVE      GGRUPO        KEYTAC            2
     C*--------------------------
     C* -PAGOS DE BARNA EN MADRID
     C*--------------------------
     C     GLUPAG        IFEQ      'F'
     C                   MOVEL     GMEPAG        KEYTAM            2
     C                   MOVE      GLUPAG        KEYTAM
     C     KEYTAM        LOOKUP    TABM          TABN                     02
     C  N02TX(8)         DSPLY                   GGRUPO
     C  N02              GOTO      FIN
     C                   MOVE      TABN          KEYTAC
     C                   END
     C*--------------------------
     C     KEYTAC        LOOKUP    TABC          TABD                     02
     C  N02TX(2)         DSPLY                   GGRUPO
     C  N02              GOTO      FIN
     C                   MOVE      TABD          CPO12C
     C*----------------
     C* LETRA DE BARNA
     C*----------------
     C     GLUPAG        IFEQ      'B'
     C     GLUPAG        OREQ      'F'
     C     GMEPAG        IFEQ      'L'
     C                   MOVEL     '4500 '       CPO12C
     C                   END
     C                   END

     C     STATUS        IFGE      2
     C     CCTAMC        IFEQ      '4510 '
     C     CCTAFC        ANDEQ     '01'
     C     CCTAAC        ANDEQ     'XXXXX'
     C                   MOVEL     '43540'       CCTAMC
     C                   ENDIF
     C     CCTAMC        IFEQ      '4500 '
     C     CCTAFC        ANDEQ     '01'
     C     CCTAAC        ANDEQ     'XXXXX'
     C                   MOVEL     '43541'       CCTAMC
     C                   ENDIF
     C                   ENDIF
      *-----------------------------
      * DESGLOSES SI EN TABC -XXXXX-
      *-----------------------------
     C                   MOVE      TABD          CPO5A             5
      /Free
        IF CPO5A = 'XXXXX';
           SELECT;

           WHEN %SUBST(LIBRE:6:1) = 'P';
           CCTAAC = %SUBST(LIBRE:5:1) + NREAL;

           WHEN %SUBST(LIBRE:6:1) = 'F';
           CCTAAC = NREAL + %SUBST(LIBRE:5:1);

           WHEN %SUBST(LIBRE:6:1) = '2';
           CCTAAC = %SUBST(NREAL:1:1) + %SUBST(LIBRE:5:1) + %SUBST(NREAL:2:3);

           WHEN %SUBST(LIBRE:6:1) = '3';
           CCTAAC = %SUBST(NREAL:1:2) + %SUBST(LIBRE:5:1) + %SUBST(NREAL:3:2);

           WHEN %SUBST(LIBRE:6:1) = '4';
           CCTAAC = %SUBST(NREAL:1:3) + %SUBST(LIBRE:5:1) + %SUBST(NREAL:4:1);

           ENDSL;
       ENDIF;

        // CONCEPTOS ESPECIALES   

           CCONC1 = *BLANKS;

           IF GMEPAG = 'C';
           CCONC1 = DIAC + '-' + MESC + '-' + AÑOC;
           ENDIF;

           IF GMEPAG = 'T';
           FECHA2 = GFEVTO;
           CCONC1 = DIAD + '-' + MESD + '-' + AÑOD;
           GFEVTO = 0;
           ENDIF;

           IF GMEPAG = 'G';
           CCONC1 = 'GASTOS';
           ENDIF;
      /End-Free

      *----------------------
     C                   MOVE      GFEVTO        CFEVT1            8 0
     C                   MOVE      GGRUPO        GGRUP1            1
     C                   MOVE      GCODTO        GCODT1            2
     C     GMEPAG        IFEQ      'R'
     C                   Z-ADD     0             CFEVT1
     C                   END
     C*-------------------
     C* REF.OPERACION
     C*-------------------
     C                   SETOFF                                       33
     C                   MOVE      *BLANKS       CREFO1
     C     GMEPAG        IFEQ      'P'
     C     GMEPAG        OREQ      'L'
     C     GKEY          CABEQ     KEYAN         FINDO
     C                   SETON                                        33
     C                   MOVE      UDATE         CREFO1            6
     C                   MOVE      UYEAR         CPO1A             1
     C                   MOVEL     CPO1A         CPO2A             2
     C                   MOVE      CPO2A         CREFO1
     C                   MOVE      ' '           KREFA             1
     C*---
     C     REFOP1        TAG
     C     KREFA         LOOKUP    TABI          TABJ                     02
     C  N02TX(5)         DSPLY                   KREFA
     C  N02              GOTO      FIN
     C                   MOVE      TABJ          CREFO1
     C                   MOVE      TABJ          KREFA
     C                   MOVEL     CPO12C        CPO18A           18
     C                   MOVE      CREFO1        CPO18A
     C                   Z-ADD     1             X                 4 0
     C     CPO18A        LOOKUP    RO(X)                                  02
     C   02              GOTO      REFOP1
     C  N02CPO18B        LOOKUP    RO(X)                                  02
     C  N02TX(5)         DSPLY                   KREFA
     C  N02              GOTO      FIN
     C                   MOVEA     CPO18A        RO(X)
     C                   END
     C*-------------------
     C* NO AGRUPAR 572 DE
     C* TRANSFERENCIAS
     C*-------------------
     C                   SETOFF                                       34
     C                   IF        GMEPAG = 'T'
     C     GKEY          CABEQ     KEYAN         FINDO
     C                   SETON                                        34
     C                   END
     C*----------------------
     C* ROTURA CTROL PARA 572
     c*----------------------
     C     FINPRE        TAG

     C                   MOVE      GGRUPO        CT572
     C   01              MOVE      '   '         CT572             3
     C     TOT572        IFNE      0
     C     CT572A        ANDNE     CT572
     C                   MOVE      'D'           CDEHA
     C                   MOVE      CTAANT        CPO12B
     C                   Z-ADD     TOT572        CIMPOR
     C                   MOVE      CODIGA        CCODIG
     C                   MOVE      CONCEA        CCONCE
     C                   MOVE      VTOANT        CFEVTO
     C                   MOVE      REFOAN        CREFOP
     C                   MOVE      '1'           CMONED
     C                   WRITE     ASIW
     C                   Z-ADD     0             TOT572
     C                   END
     C   01              GOTO      FIN
     C*---
     C     CTAMA3        IFNE      '572'
     C     GMEPAG        OREQ      'T'
     C                   MOVE      'D'           CDEHA
     C                   MOVE      CPO12C        CPO12B
     C   34
     COR 33              Z-ADD     GIMPAG        CIMPOR
     C  N34
     CANN33              Z-ADD     GIMDET        CIMPOR
     C                   MOVE      CCODI1        CCODIG
     C                   MOVE      CCONC1        CCONCE
     C                   MOVE      CFEVT1        CFEVTO
     C                   MOVE      CREFO1        CREFOP
     C                   MOVE      '1'           CMONED
     C                   WRITE     ASIW
     C*---------------------
     C* AGRUPA INGRESOS BCO.
     C*---------------------
     C                   ELSE
     C                   MOVE      'D'           DEHANT            1
     C                   MOVE      CPO12C        CTAANT           12
     C                   ADD       GIMDET        TOT572           11 0
     C                   MOVE      CCODI1        CODIGA            3 0
     C                   MOVE      CCONC1        CONCEA           30
     C                   MOVE      CFEVT1        VTOANT            8 0
     C                   MOVE      CREFO1        REFOAN            6
     C                   MOVE      GGRUPO        CT572A            3
     C                   END
     C*---------------------
     C     FINDO         TAG
     C                   Z-ADD     GKEY          KEYAN             4 0
     C*---
     C                   END
     C                   END
     C***************
     C     FIN           TAG
     C                   SETON                                        LR
      ******************************************
      * ASIENTO ESPECIAL CAIXA
      ******************************************
     C     ESPECIALCAIXA BEGSR
     C                   EVAL      CCODIG = 0
     C                   EVAL      CDEHA  = 'D'
     C                   EVAL      CCONCE=*BLANKS
     C                   EVAL      CCONCE = 'COBROS CAIXA NTING-' + NUNETTINGA
     C                   EVAL      CMONED = '1'
     C                   Z-ADD     GIMDET        CIMPOR
     C                   EVAL      CCTAMA = '4322 '
     C                   EVAL      CCTAFI = '01'
     C                   EVAL      CCTAAU = '90399'
     C                   WRITE     ASIW

     C                   EVAL      CCTAMA = '4401 '
     C                   EVAL      CCTAFI = '01'
     C                   EVAL      CDEHA  = 'H'
     C                   WRITE     ASIW
     C                   ENDSR
      ******************************************
      * INICIALIZACION DEL PROGRAMA
      ******************************************
     C     *INZSR        BEGSR

     C     01            chain     cnuNfi
     C                   if        %found
     C     cenvia        add       1             nunetting         4 0
     C                   move      nunetting     nunettinga        4
     C                   ENDIF

     C                   ENDSR
     c******************************************
**
NO EN TABA,PRINT EXPLOT.CANCELAR
NO EN TABC,PRINT EXPLOT.CANCELAR
NO EN TABE,PRINT EXPLOT.CANCELAR

NO EN TABI,PRINT EXPLOT.CANCELAR
NO EN CLESPAÑA,PRINT EXPLOT.CANCELAR
AMPLIAR SERIE -RO- ,PRINT EXPLOT.CANCELAR
NO EN TABM,PRINT EXPLOT.CANCELAR
NO EN MSOCIO,PRINT EXPLOT.CANCELAR
**                     //TABA-->CUENTAS DE ABONO //
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
**                      //TABC-->CUENTAS DE CARGO, LIGA CON TABM.
 A5700                            PRIMERO BUSCA EN TABM SI PAGO BARNA
 B5720 0411500                    EN MADRID PARA SACAR EL INDICE DE
 C5720 0411500                    TABC
 D5720 0411500                                               SI NO ES
 E5720 0411500                    DE BARNA EN MADRID BUSCA DIRECTAMENTE
 G4510 01XXXXX                    - EL INDICE ES UN BLANCO Y EL GRUPO
 H4500 01XXXXX                      DE ARCHIVO DOCUMENTOS
 I5701
 J5720 0413430
 N4510 01XXXXX
 Ñ5720 0413430
 O5720 0411500
 Q5720 0470349
 X5720 0455464
 V5720 0455464
 W5720 0430030
 R4520
**                      //TABE-->CODIGOS DE CONCEPTO CONTABLE //
E515
C572
L451
P516
R450
T572
**                      //TABI-->COMPOSICION REF. OPERACION //
 AABBCCDDEEFFGGHHIIJJKKLLMMNNPPQQRRSSTTUUVVWWXXYYZZ00112233445566778899A
**                      //TABK-->INDICES PARA LA EVIDENCIA CONTABLE
EA01                             LISTADA POR EL PROGRAMA LIAN04 //
EI02
EP02
CB03
CC03
CD03
CE03
CF03
CS03
CT03
CU03
CJ04
CK04
CL04
CM04
CP04
PG05
PN06
PP06
LH07
LN08
LP08
RR09
TÑ10
TO10
TQ10
TX10
CV03
TW10
**                      //TABM-->INDICE PARA CUENTAS DE GARGO, LIGA CON
EFI                              TABC.//
CFJ
CFK                              - SOLO SON PAGOS DE BARNA GRABADOS
CFL                                EN MADRID.
CFM
PFN
LFN
