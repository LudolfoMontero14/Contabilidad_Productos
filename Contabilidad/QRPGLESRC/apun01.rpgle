     H DECEDIT('0,') DATEDIT(*DMY.)
      *****************************************************************
      **           ASIENTO CONTABLE PARA EL INTERNACIONAL            **
      **         ==========================================          **
      **                                                             **
      **              H1- NO ENCONTRADO BOLRECAP                     **
      **              H2- NO ENCONTRADO PAIMON                       **
      **              H3- NO ENCONTRADO PAISES                       **
      **                                                             **
      *****************************************************************
     FIMOV      IP  AF  169        DISK
     FBOLRELG2  IF   E           K DISK
     FCLESPAÑA  IF   E           K DISK
     FPAIMOLG9  IF   E           K DISK
     FPAISESA   IF   E           K DISK
     FMSOCIO    IF   F  731     8AIDISK    KEYLOC(3)
     FASIFIVA   O    E             DISK
     FEDITA     CF   F  256        SPECIAL PGMNAME('SUBR01')
     FDETE37    O    F  157        DISK
     FCABE37    O    F   78        DISK
      *****************************************************************
      **                DEFINICION DE SERIES/TABLAS                  **
      *****************************************************************
     D CT              S             12    DIM(999)                             CUENTAS PAISES
     D PT              S              9  0 DIM(999)                             IMPORTE NETO
     D RC              S              7    DIM(999)                             NUMERO RECAP
     D FR              S              8  0 DIM(999)                             FECHA  RECAP
     D DT              S              5  3 DIM(999)                             DESCTO.RECAP
     D NT              S             15  3 DIM(999)                             MONEDA NETA
     D S1              S             10    DIM(6)                               EVI.CONT.SOCIO
    $D S2              S              8  0 DIM(6)                               EVI.CONT.IMPOR

     D                 DS
     D  CAPUNT                 1      6
     D*
     D  CUENTA                 7     18
     D  CCTAMA                 7     11
     D  CCTAFI                12     13
     D  CCTAAU                14     18
     D*
     D  CCODIG                19     21  0
     D  CPROGR                22     27
     D  CFECON                28     35  0
     D  CDEHA                 36     36
     D  CREFOP                37     42
     D  CFEVTO                43     50  0
     D  CCONCE                51     80
     D  CIMPOR                81     94  3
     D  CMONED                95     95
     D  CPROVI                96    101

      /COPY EXPLOTA/QRPGLESRC,DSTIMSYS

      /COPY EXPLOTA/QRPGLESRC,DSAEVIDE

     IEDITA     NS
     I                                  6   23  MONEDI
     I                                 25   34  FECEDI
     I                                 35   44  FECREC
     I                                 45   64  NOPEDI
     I                                 65   74  FECED1

     IIMOV      NS  01    4 CR
     I                                  3    3  CONDUP        L1M1
     I                                 21   28 0IMPOR
     I                                 29   32 0DDMMRE
     I                                 33   34 0AARE
     I                                 38   40 0NUPAIS
     I                                 41   46 3CAMMON
     I                                 58   60 0CLASMO
     I                                 62   65 0NURECA        L2M2
     I                                 84   86 0PAISGR        L3M3
     I                                 87   87  CLAREC
     I                                 88   90  TIPMON
     I          NS  02    4 C7
     I                                  1    1  NOPRO
     I                                  3    3  CONDUP        L1M1
     I                                  7   10 0CLAVE
     I                                  7   14 0NS8
     I                             P   19   20 0ACTCAR
     I                                 21   28 0IMPOR
     I                                 38   40 0NUPAIS
    $I                             P   50   57 3IMPMON
     I                                 58   60 0CLASMO
     I                                 62   62  TIRECA
     I                                 62   65 0NURECA        L2M2
     I                                 84   86 0PAISGR        L3M3
     I                                 88   90  TIPMON
     I                                114  117  WREFCA

     IMSOCIO    NS
     I                                361  361  SCOBHA
     I                                434  434  CONCIL

     C*-------------------------
     C* KEY BOLRELG2 (BOLRECAP)
     C*-------------------------
     C     BUSREC        KLIST
     C                   KFLD                    PAISGR
     C                   KFLD                    NURECA
     C                   KFLD                    TIPMON
     C                   KFLD                    FEREC2            8 0
     C*-------------
     C* PRIMER CICLO
     C*-------------
     C  N99              DO
     C                   SETON                                        99
     C                   Z-ADD     0             PT
     C                   Z-ADD     0             NT
     C                   MOVE      *BLANKS       RC
     C                   Z-ADD     1             X
     C                   EXCEPT    EDIDAT
     C                   READ      EDITA                                  10
     C                   MOVE      FECEDI        FECAPU            8
     C                   ENDDO
     C****************************************************************
     C*                   CALCULO DE REMESA
     C****************************************************************
     C   01              DO
     C   14              EXSR      CALREC
     C     AARE          ADD       2000          FEREC2
     C                   MOVEL     DDMMRE        FEREC2
     C                   SETON                                        1415
     C     BUSREC        CHAIN     BOLSAR                             11
     C   11              SETON                                        H1
     C     TIPMON        CHAIN     WPAIMON                            12
     C   12              SETON                                        H2
     C     NUPAIS        CHAIN     PAISESW                            15
     C*  15              SETON                                        H3
     C                   MOVEL     LIBRE1        CPO03             3
     C                   MOVE      CPO03         CPO05             5
     C                   MOVEL     PAISGR        CPO05
     C                   MOVE      CPO05         CTAPAI
     C                   MOVEL     PAISGR        BUSTAB            7
     C                   MOVE      NURECA        BUSTAB
     C                   Z-ADD     1             Z                 3 0
     C     BUSTAB        LOOKUP    RC(Z)                                  13
     C  N13              DO
     C                   Z-ADD     1             Z
     C     *BLANKS       LOOKUP    RC(Z)                                  13
     C                   MOVEA     CTAPAI        CT(Z)
     C                   MOVEL     BUSTAB        RC(Z)
     C                   Z-ADD     BFEREC        FR(Z)
     C                   Z-ADD     BRATE         DT(Z)
     C                   ENDDO
     C     BRATE         COMP      0,000                                  34    DTO-0       0
     C                   GOTO      FIN
     C                   ENDDO
     C****************************************************************
     C*                   CALCULO DE CARGOS
     C****************************************************************
     C                   SETOFF                                       33
     C   02ACTCAR        COMP      832                                    33    ACT-832-
     C*------------------
     C* BUSCO EN CLESPAÑA
     C*------------------
     C     CLAVE         CHAIN     CLESPA                             10
     C*-------------------------------------
     C* SUMO A LAS CUENTAS DE NO PROCESABLES
     C*-------------------------------------
     C     NOPRO         CASEQ     'X'           APNOPR
     C                   END
     C*------------------------------------------------------------------
     C* SUMO A LAS CUENTAS DE -PA-
     C* ============================
     C*  4321 --> RESTO TARJETAS
     C*  4325 --> TE's CONCILIACION
     C*  4305 --> DUAL (Diners/Santander)
     C*
     C*  Nota: Tarjetas Dual Santander y Banif, no tienen Cajeros.
     C*------------------------------------------------------------------
     C                   IF        NOPRO <> 'X'
     C                   Z-ADD     CONTA         X                 3 0
     C*-
     C                   SETOFF                                       2425
     C                   SETON                                        23
     C     NS8           CHAIN     MSOCIO                             23
     C*-
     C  N23CONCIL        COMP      'C'                                    24    -TE conciliación
     C  N23SCOBHA        COMP      'L'                                    25    -Tarjeta Dual
     C*-
     C  N33
     CANN25
     CANN24              ADD       IMPOR         PANOR             9 0          -Resto Tarjetas
     C  N33
     CANN25
     CAN 24              ADD       IMPOR         PANORC            9 0          -TE Conciliación
     C  N33
     CAN 25
     CANN24              ADD       IMPOR         PANORDS           9 0          -Diners/Santander
     C*-
     C   33
     CANN24              ADD       IMPOR         PA832             9 0          -Resto Tarjetas
     C   33
     CAN 24              ADD       IMPOR         PA832C            9 0          -TE Conciliación
     C*-
     C   25              DO
     C     IMPOR         MULT      BRATE         DESCTODS         15 3          -Comisiones DUAL DS
     C     DESCTODS      DIV(H)    100           CPO09DS           9 0          -Comisiones DUAL DS
     C  N34              ADD       CPO09DS       CONORDS           9 0          -Comisiones DUAL DS
     C                   ENDDO
     C*-
     C                   ENDIF
     C*--------------------------
     C* SUMO A LA CUENTA DEL PAIS
     C*--------------------------
     C  N33              ADD       IMPOR         PT(Z)
     C*----------------------------
     C* EVIDENCIA CONTABLE ACT-832-
     C*----------------------------
     C                   IF        *IN33 = '1'
     C                   ADD       IMPOR         TGTOTO            9 0          TODO GTOS
     C                   ADD       1             TGTNTO            5 0          TODO OPER
     C                   ADD       1             Q                 3 0
     C                   Z-ADD     IMPOR         S2(Q)
     C                   MOVEL     NS8           S1(Q)
     C*--
     C                   SELECT
     C     TIRECA        WHENEQ    '7'                                          CIRRUS
     C                   MOVE      '-C'          S1(Q)                          CIRRUS
     C                   ADD       IMPOR         TGTO4C            9 0          CIRRUS GTOS
     C                   ADD       1             TGTN4C            5 0          CIRRUS OPER
     C                   ADD       IMPOR         CO832C            9 0          CIRRUS
     C     TIRECA        WHENEQ    '8'                                          NO CIRRUS
     C                   MOVE      '-N'          S1(Q)                          NO CIRRUS
     C                   ADD       IMPOR         TGTO4N            9 0          NO CIRRUS GTOS
     C                   ADD       1             TGTN4N            5 0          NO CIRRUS OPER
     C                   ADD       IMPOR         CO832N            9 0          NO CIRRUS
     C     TIRECA        WHENEQ    '0'                                          NO CIRRUS
     C                   MOVE      '-R'          S1(Q)                          RESTO
     C                   ADD       IMPOR         TGTO4R            9 0          RESTO GTOS
     C                   ADD       1             TGTN4R            5 0          RESTO OPER
     C                   ADD       IMPOR         CO832R            9 0          RESTO
     C                   ENDSL
     C*--
     C                   ENDIF
     C*----------------------------
    $C                   IF        Q = 6
     C                   EXCEPT    CONT
     C                   Z-ADD     0             Q
     C                   ENDIF
     C*----------------------------
     C     FIN           TAG
     C******************************
     CLR                 EXSR      CALREC
     C*****************************************************************
     C**           C U E N T A S   D E    P.A.   --ASIENTO--         **
     C*****************************************************************
     C*------------------------
     C*   ACTIVIDADES NO-832-
     C*------------------------
     CLR                 MOVE      *BLANKS       CCONCE
     CLR                 MOVE      *BLANKS       CREFOP
     CLR                 MOVE      '419'         CCODIG
     C*---
     CLR   PANOR         COMP      0                                    2221
     CLRN21              DO
     CLR                 EVAL      CUENTA = '4321        '                      -Resto Tarjetas
     CLR                 Z-ADD     PANOR         CIMPOR
     CLR                 MOVE      'D'           CDEHA
     CLR 22              MOVE      'H'           CDEHA
     CLR 22              MULT      -1            CIMPOR
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*---
     CLR   PANORC        COMP      0                                    2221
     CLRN21              DO
     CLR                 EVAL      CUENTA = '4325        '                      -TE's Conciliación
     CLR                 Z-ADD     PANORC        CIMPOR
     CLR                 MOVE      'D'           CDEHA
     CLR 22              MOVE      'H'           CDEHA
     CLR 22              MULT      -1            CIMPOR
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*---
     CLR   PANORDS       COMP      0                                    2221
     CLRN21              DO
     CLR                 EVAL      CUENTA = '4305 0305   '                      -DUAL:Diners/Santan.
     CLR                 MOVE      UDATE         CREFOP
     CLR                 Z-ADD     PANORDS       CIMPOR
     CLR                 MOVE      'D'           CDEHA
     CLR 22              MOVE      'H'           CDEHA
     CLR 22              MULT      -1            CIMPOR
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*---
     CLR                 MOVE      *BLANKS       CREFOP
     C*--
     C*--> Cta.Comisiones (No Tarjetas Dual)
     C*--
     CLR   CONOR         SUB       CONORDS       CONOR
     CLR   CONOR         COMP      0                                    2221
     CLRN21              DO
     CLR                 EVAL      CUENTA = '7011 0500000'
     CLR                 Z-ADD     CONOR         CIMPOR
     CLR 22              MULT      -1            CIMPOR
     CLR                 MOVE      'H'           CDEHA
     CLR 22              MOVE      'D'           CDEHA
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*--
     C*--> Cta.Comisiones (Dual:Santander ó Banif)
     C*--
     CLR   CONORDS       COMP      0                                    2221
     CLRN21              DO
     CLR                 EVAL      CUENTA = '7011 0500010'
     CLR                 Z-ADD     CONORDS       CIMPOR                         -Cta. Comisiones
     CLR 22              MULT      -1            CIMPOR
     CLR                 MOVE      'H'           CDEHA
     CLR 22              MOVE      'D'           CDEHA
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*-----------------------------------------
     C*   ACTIVIDADES SI-832- (Gastos Cajeros)
     C*-----------------------------------------
     CLR                 MOVE      *BLANKS       CCONCE
     CLR                 MOVE      *BLANKS       CREFOP
     CLR                 MOVE      '430'         CCODIG
     C*---
     CLR   PA832         COMP      0                                    2221
     CLRN21              DO
     CLR                 EVAL      CUENTA = '4321        '
     CLR                 Z-ADD     PA832         CIMPOR
     CLR                 MOVE      'D'           CDEHA
     CLR 22              MOVE      'H'           CDEHA
     CLR 22              MULT      -1            CIMPOR
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*---
     CLR   PA832C        COMP      0                                    2221
     CLRN21              DO
     CLR                 EVAL      CUENTA = '4325        '                      -TE's Conciliación
     CLR                 Z-ADD     PA832C        CIMPOR
     CLR                 MOVE      'D'           CDEHA
     CLR 22              MOVE      'H'           CDEHA
     CLR 22              MULT      -1            CIMPOR
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*---
     CLR   CO832C        COMP      0                                    2221    -CIRRUS
     CLRN21              DO
     CLR                 EVAL      CUENTA = '7011 0571900'                      -Comisiones CIRRUS
     CLR                 Z-ADD     CO832C        CIMPOR
     CLR 22              MULT      -1            CIMPOR
     CLR                 MOVE      'H'           CDEHA
     CLR 22              MOVE      'D'           CDEHA
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*---
     CLR   CO832N        COMP      0                                    2221    NO CIRRUS
     CLRN21              DO
     CLR                 EVAL      CUENTA = '7011 0500000'                      -Comisiones NOCIRRUS
     CLR                 Z-ADD     CO832N        CIMPOR
     CLR 22              MULT      -1            CIMPOR
     CLR                 MOVE      'H'           CDEHA
     CLR 22              MOVE      'D'           CDEHA
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*---
     CLR   CO832R        COMP      0                                    2221    RESTO
     CLRN21              DO
     CLR                 EVAL      CUENTA = '7011 0500000'                      -Comisiones RESTO
     CLR                 Z-ADD     CO832R        CIMPOR
     CLR 22              MULT      -1            CIMPOR
     CLR                 MOVE      'H'           CDEHA
     CLR 22              MOVE      'D'           CDEHA
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     C*--------------------------------------
     C* C U E N T A S     D E     P A I S E S
     C*--------------------------------------
     CLR                 MOVE      '419'         CCODIG
     C*----
     CLR                 Z-ADD     0             X
     CLR                 DO        *HIVAL
     CLR                 ADD       1             X
     CLR   CT(X)         CABEQ     *BLANKS       SAL2
     CLR   PT(X)         COMP      0                                    22
     CLR                 EXCEPT    EDIDAT
     CLR                 READ      EDITA                                  10
     CLR                 MOVEA     CT(X)         CUENTA
     CLR                 MOVEL     '   '         RC(X)
     CLR                 MOVE      RC(X)         CPO4A             4
     CLR                 MOVEL     CPO4A         CPO1A             1
     CLR                 IF        CPO1A = '0'
     CLR                 MOVE      CPO4A         CPO3A             3
     CLR                 MOVE      *BLANKS       CPO4A
     CLR                 MOVEL     CPO3A         CPO4A
     CLR                 ENDIF
     CLR                 MOVEL     CPO4A         CREFOP
     CLR                 MOVE      MONEDI        CCONCE
     CLR                 MOVEL     FECREC        CCONCE
     CLR                 Z-ADD     PT(X)         CIMPOR
     CLR                 MOVE      'H'           CDEHA
     CLR 22              MOVE      'D'           CDEHA
     CLR 22              MULT      -1            CIMPOR
     CLR                 WRITE     ASIW
     CLR                 ENDDO
     CLR   SAL2          TAG
     C*-- ULTIMA LINEA GTOS ACT-832-
     CLR                 EXCEPT    CONT

     C*****************************************************************
     C**       LINEA DE APUNTE PARA PARTIDAS NO PROCESABLES          **
     C*****************************************************************
     C     APNOPR        BEGSR
     C                   SETON                                        98
     C                   SETOFF                                       16
     C                   MOVEL     'P'           CPO05             5
     C                   MOVE      WREFCA        CPO05
     C                   MOVEL     CPO05         CREFOP
     C                   EVAL      CUENTA = '4010002999EX'                       -(2.9.92)
     C                   Z-ADD     IMPOR         CIMPOR
     C                   MOVE      'D'           CDEHA
     C                   MOVE      '402'         CCODIG
     C*---
     C                   IF        CIMPOR < 0
     C                   SETON                                        16
     C                   MOVE      '403'         CCODIG
     C                   MOVE      'H'           CDEHA
     C                   MULT      -1            CIMPOR
     C                   ENDIF
     C*---
     C                   Z-ADD     IMPMON        W4               15 2            2-9-92
     C*---
     C                   EXCEPT    EDIDAT
     C                   READ      EDITA                                  10
     C                   MOVEL(P)  FECED1        CCONCE
     C                   MOVE      NOPEDI        CCONCE
     C                   WRITE     ASIW
     C                   SETOFF                                       98
     C                   ENDSR
     C*****************************************************************
     C**                CALCULOS REMESA ANTERIOR                     **
     C*****************************************************************
     C     CALREC        BEGSR
     C                   Z-ADD     BNETOP        NT(Z)
     C     PT(Z)         MULT      BRATE         DESCTO           15 3
     C     DESCTO        DIV(H)    100           CPO09             9 0
     C                   SUB       CPO09         PT(Z)
     C  N34              ADD       CPO09         CONOR             9 0          CTA.COMISIONES
     C                   ENDSR
     C*****************************************************************
     C**            INICIALIZACION DEL PROGRAMA                      **
     C*****************************************************************
     C     *INZSR        BEGSR
     C                   TIME                    TIMSYS
     C     FECSYS        DIV       100           AMDSYS
     C                   MOVEL     AÑOSYS        AMDSYS
     C                   MOVE      DIASYS        AMDSYS
     C                   MOVEL     HORSYS        AAPUNT
     C                   MOVEL     HORSYS        APROVI
     C*---
     C                   MOVE      *DATE         CFECON
     C                   MOVE      'APUN01'      CPROGR
     C                   MOVE      '16'          CAPUNT
     C                   MOVEL     '4010002'     CTAPAI           12
1    C                   MOVE      '1'           CMONED
     C                   MOVE      *BLANKS       CREFOP
     C                   MOVEL     HORSYS        CPROVI
     C                   Z-ADD     0             CFEVTO
     C                   ENDSR
     C*****************************************************************
     OEDITA     E            EDIDAT
     O                       NT(X)         2     24
     O                       *DATE               34 '  /  /    '
     O                       FR(X)               44 '  /  /    '
     O                       W4            2     64
     O                     98FR(Z)               74 '  /  /    '

     O*----------------------------------------------------------------
     O*-             EVIDENCIA CONTABLE (GTOS.CAJEROS)                -
     O*----------------------------------------------------------------
     OCABE37    T    LR
     O                                           24 'GASTOS 4% CAJEROS RECIBI'
     O                                           34 'DOS DE DCI'
     O                       *DATE         Y     45
     O                       AAPUNT              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       HORSYS              78

     ODETE37    H    1P
     O                                            6 'APUN01'
     O                                           44 'RELACION DE GASTOS DEL 4'
     O                                           68 '% POR USOS EFECTUADOS EN'
     O                                           92 ' CAJEROS RECIBIDOS DEL D'
     O                                           96 'DISC'
     O                       *DATE         Y    115
     O                                          128 'PAGINA'
     O                       PAGE          Z    132
     O                       AEVIDE             157
     O          H    1P
     O                                           44 '------------------------'
     O                                           68 '------------------------'
     O                                           92 '------------------------'
     O                                           96 '----'
     O                       AEVIDE             157
     O          E            CONT
     O                       AEVIDE             157
     O          E            CONT
    $O                       S1(1)          B    10
    $O                       S2(1)          B    22 '   .   ,  -'
    $O                       S1(2)          B    32
    $O                       S2(2)          B    44 '   .   ,  -'
    $O                       S1(3)          B    54
    $O                       S2(3)          B    66 '   .   ,  -'
    $O                       S1(4)          B    76
    $O                       S2(4)          B    88 '   .   ,  -'
    $O                       S1(5)          B    98
    $O                       S2(5)          B   110 '   .   ,  -'
    $O                       S1(6)          B   120
    $O                       S2(6)          B   132 '   .   ,  -'
     O                       AEVIDE             157
     O*--
     O          T    LR
     O                       AEVIDE             157
     O          T    LR
     O                       AEVIDE             157
     O          T    LR
     O                                           42 'C-CIRRUS    --'
     O                       TGTO4C              56 ' .   . 0 ,  -'
     O                       TGTN4C        2
     O                                              '-OPERACIONES'
     O                       AEVIDE             157
     O          T    LR
     O                                           42 '*-NO CIRRUS --'
     O                       TGTO4N              56 ' .   . 0 ,  -'
     O                       TGTN4N        2
     O                                              '-OPERACIONES'
     O                       AEVIDE             157
     O          T    LR
     O                                           42 'R-RESTO     --'
     O                       TGTO4R              56 ' .   . 0 ,  -'
     O                       TGTN4R        2
     O                                              '-OPERACIONES'
     O                       AEVIDE             157
     O          T    LR
     O                                           56 '-------------'
     O                       AEVIDE             157
     O          T    LR
     O                                           42 '  TOTAL     --'
     O                       TGTOTO              56 ' .   . 0 ,  -'
     O                       TGTNTO        2
     O                                              '-OPERACIONES'
     O                       AEVIDE             157
