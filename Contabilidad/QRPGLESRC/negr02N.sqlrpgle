     H DECEDIT('0,') DATEDIT(*DMY.) 
     H BNDDIR('CONTBNDDIR':'UTILITIES/UTILITIES')
      *****************************************************************
      * -CUENTAS DE VIAJES-           --PROCESO PA--                  *
      *                                                               *
      *  INTENTA CRUZAR LO PRESENTADO POR PROVEEDORES "PA" CONTRA     *
      *  EL PENDIENTE "PTEPREPR" QUE YA NOS PRESENTO LA AGENCIA Y SE  *
      *  FACTURO.                                                     *
      *                                                               *
      * -PTEPRLG1 (PTEPREPR) -------> FACTURADO -NO PRESENT.PROVEEDOR.*
      * -SOCIOLG1 (PA      ) -------> PENDIENTE FACTURAR              *
      * -SOCIOLG2 (PA      ) -------> PENDIENTE FACTURAR (ESPEC.VCI)  *
      * -ASINEGR2 (ASIFILE ) -------> ASIENTOS -OPER.CRUZADAS-        *
      * -ASINEG22 (ASIFILE ) -------> ASIENTOS -REG.DIF.CONV.EUROS-   *
      *                                                               *
      *****************************************************************
     FPTEPRLG1  UF   E           K DISK    RENAME(PPA:PTEPREW)
     FSOCIOLG1  UF   E           K DISK
     F                                     INFDS(INFDS_PA1)
     FSOCIOLG2  UF   E           K DISK
     F                                     INFDS(INFDS_PA2)
     FSOCIOLG3  UF   E           K DISK
     F                                     INFDS(INFDS_PA3)
     FFAGENCON  IF   E           K DISK
     FDESCRFAC  UF   E           K DISK

     FPTEPRHIS  O    E             DISK
     FASINEGR2  O    E             DISK
     FASINEG22  O    E             DISK
     F                                     RENAME(ASIW:ASIW2)
     FDETEVI22  O    F  157        DISK
     FDETE27    O    F  157        DISK
     FCABE27    O    F   78        DISK
     FIMP2017   O    F  132        PRINTER OFLIND(*INOB)
     F                                     USROPN
     D*****************************************************************
     D**                 S E R I E S  /  T A B L A S                 **
     D*****************************************************************
     D MSG             S             30    DIM(2) CTDATA PERRCD(1)              TOTASAX
     D ASI             S              1    DIM(30)                              ASIENTO
     D*-
     D S1              S              4  0 DIM(3)                               CONTABILIDAD
     D S2              S              9  0 DIM(3)                               CONTABILIDAD
     D S3              S              8  0 DIM(3)                               CONTABILIDAD
     D S4              S              9  0 DIM(3)                               CONTABILIDAD
     D*-
     D S1E             S              4  0 DIM(3)                               EXPLOTACION
     D S2E             S              9  0 DIM(3)                               EXPLOTACION
     D S3E             S              8  0 DIM(3)                               EXPLOTACION
     D S4E             S              9  0 DIM(3)                               EXPLOTACION

       Dcl-s WCODPRO Zoned(3);
       Dcl-s WInd    Zoned(3);

      /COPY EXPLOTA/QRPGLESRC,DSAEVIDE

      /COPY EXPLOTA/QRPGLESRC,DSTIMSYS
      // --------------------------
      // Cpys y Include
      // --------------------------
      /Define Funciones_CONTABSRV
      /Define PGM_ASBUNU
      /Define Estructuras_Asientos_Evidencias
      /define Common_Variables
      /Include Explota/QRPGLESRC,CONTABSRVH

      /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
      /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

      // --------------------------
      // Declaracion Estructuras
      // --------------------------
      // Array / Matriz que totaliza importes por productos
      dcl-ds Acumulador likeds(AcumuladorTpl) Dim(100) Inz;

     D                 DS
     D  AEVID1                 1     25
     D  ACERO1                 1      5    INZ('00000')
     D  APUNT1                 6     11
     D  AMDSY1                12     19  0
     D  APROV1                20     25

       dcl-ds INFDS_PA1;
        rrn_pa1 bindec(9)  POS(397);
       end-ds;
       dcl-ds INFDS_PA2;
        rrn_pa2 bindec(9)  POS(397);
       end-ds;
        dcl-ds INFDS_PA3;
        rrn_pa3 bindec(9)  POS(397);
       end-ds;
       dcl-pr Aud_PA_sup extpgm('AUD_PA_SUP');
         *n bindec(9);  //rrn del PA
         *n Char(10);   //nombre programa
         *n ind;        //indicador error
       end-pr;
       dcl-s  P_nombre_pgm Char(10) inz('NEGR02');   //nombre programa
       dcl-s  P_error ind;   //error
     C*-------------------
     C* KEY SOCIOLG1 -PA-
     C*-------------------
     C     KEYSO1        KLIST
     C                   KFLD                    KEY1              8 0          -Nº.REAL-
     C                   KFLD                    KEY2             15            -AUT./BILL-
     C                   KFLD                    KEY3              9 0          -IMPORTE-
     C*-------------------
     C* KEY SOCIOLG2 -PA-
     C*-------------------
     C     KEYSO2        KLIST
     C                   KFLD                    KEY11             8 0          -Nº.REAL-
     C                   KFLD                    KEY22             8            -AUT./BILL-
     C                   KFLD                    KEY33             9 0          -IMPORTE-
     C*-------------------
     C* KEY SOCIOLG3 -PA-
     C*-------------------
     C     KEYSO3        KLIST
     C                   KFLD                    KEY111            8 0          -Nº.REAL-
     C                   KFLD                    KEY222           10            -Nº.REEMBOLS
     C                   KFLD                    KEY333            9 0          -IMPORTE-
     C*-------------------------
     C* KEY PTEPRLG1 -PTEPREPR-
     C*-------------------------
     C     KEYPTE        KLIST
     C                   KFLD                    CAM04             4 0          -AGENCIA-
     C                   KFLD                    CAM08             8 0          -TARJETA-
     C                   KFLD                    CAM15            15            -AUT./BILL-
     C                   Z-ADD     0             CAM04
     C                   Z-ADD     0             CAM08
     C                   MOVE      *BLANKS       CAM15
     C*--------------
    $C                   Z-ADD     *ZEROS        ACOOPE            5 0          -CONT.OPERAC
    $C                   Z-ADD     *ZEROS        XCOOPE            5 0          -CONT.OPERAC
     C**-------------------------------------------------------------**
     C**  -PTEPREPR-  BOLSA DE PRESENTADO AGENCIAS Y NO PROVEEDORES  **
     C**-------------------------------------------------------------**
     C     KEYPTE        SETLL     PTEPREW
     C     LEEPTE        TAG
     C                   READ      PTEPREW                                01
     C   01              GOTO      FINFIN
     C*================================================================
     C*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*
     C*$$           RUPTURA POR Nº AUTOR./BILLETE ...ETC            $$*
     C*$$                CHAIN: SOCIOLG1-SOCIOLG2                   $$*
     C*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$**
     C*================================================================
     C     PNUCRU        IFNE      ANUCRU
     C     FINFIN        TAG
     C*--
     C                   Z-ADD     ANUREA        KEY1                           KEY SOCIOLG1
     C                   MOVEL     ANUCRU        KEY2                           KEY SOCIOLG1
     C                   Z-ADD     AIMPOR        KEY3                           KEY SOCIOLG1
     C*--
     C                   Z-ADD     ANUREA        KEY11                          KEY SOCIOLG2
     C                   MOVEL     ANUCRU        KEY22                          KEY SOCIOLG2
     C                   Z-ADD     AIMPOR        KEY33                          KEY SOCIOLG2
     C*--
     C                   Z-ADD     ANUREA        KEY111                         KEY SOCIOLG3
     C                   MOVEL     ANUCRU        KEY222                         KEY SOCIOLG3
     C                   Z-ADD     AIMPOR        KEY333                         KEY SOCIOLG3
     C*--
     C                   Z-ADD     PPAGEN        CAM04                          -PUNT.BOLSA
     C                   Z-ADD     PPNURE        CAM08                          -PUNT.BOLSA
     C                   MOVEL     PPNUCR        CAM15                          -PUNT.BOLSA
     C*--
    $C                   Z-ADD     KEY3          GKEY3             9 0          -GUARDA IMP.R.
    $C                   SETOFF                                       92        -AUXILIAR
    $C     RCHAIN        TAG                                                    -REPETIR-
     C                   SETON                                        020344
     C     KEYSO1        CHAIN     SOCIO1W                            02
     C   02KEYSO2        CHAIN     SOCIO2W                            03
     C**************************
     C**  --SEGUNDA PASADA--  **
     C**  LLAA (Nº.REEMBOLSO) **
     C**************************
     C   02
     CAN 03ACOVEN        IFEQ      '2'                                          ----------
     C     KEYSO3        CHAIN     SOCIO3W                            44        -SOCIOLG3-
     C                   ENDIF                                                  ----------
    $C*-----------------------------------------------------*
    $C* --TEMPORAL HASTA QUE PTEPREPR Y PA ESTEN EN EUROS-- *
    $C*-----------------------------------------------------*
    $C   02
    $CAN 03
    $CAN 44
    $CANN92AAGENC        IFNE      0000                                         -AGENCIA
    $C     XCOOPE        IFGT      ACOOPE
    $C                   SETON                                        92
    $C                   Z-ADD     0             XCOOPE
    $C                   Z-ADD     GKEY3         KEY3                           -RECUPERAR
    $C                   Z-ADD     GKEY3         KEY33                          -RECUPERAR
    $C                   GOTO      VRESTO
    $C                   ENDIF
    $C                   ADD       1             KEY3                           -IMPORTE
    $C                   ADD       1             KEY33                          -IMPORTE
    $C                   ADD       1             XCOOPE            5 0          -CONT.OPERAC
    $C                   GOTO      RCHAIN                                       -REPETIR-
    $C                   ENDIF
    $C*-----------------------------------------------------*
    $C* --TEMPORAL HASTA QUE PTEPREPR Y PA ESTEN EN EUROS-- *
    $C*-----------------------------------------------------*
    $C     VRESTO        TAG
    $C*--
    $C   02
    $CAN 03
    $CAN 44AAGENC        IFNE      0000                                         -AGENCIA
    $C     XCOOPE        CABGT     ACOOPE        FCHAIN
    $C                   SUB       1             KEY3                           -IMPORTE
    $C                   SUB       1             KEY33                          -IMPORTE
    $C                   ADD       1             XCOOPE            5 0          -CONT.OPERAC
    $C                   GOTO      RCHAIN                                       -REPETIR-
    $C                   ENDIF
    $C*-----------------------------------------------------*
    $C     FCHAIN        TAG
    $C                   Z-ADD     0             ACOOPE
    $C                   Z-ADD     0             XCOOPE
    $C*-----------------------------------------------------*
    $C* --REGULARIZAR DIFERENCIAS CONVERSION -EURO-         *
    $C*                - ASIENTO -                          *
    $C*-----------------------------------------------------*
    $C  N02
    $CORN03
    $CORN44AAGENC        IFNE      0000                                         -AGENCIA
    $C                   Z-ADD     0             RKEY3             9 0
    $C     GKEY3         SUB       KEY3          RKEY3                          -REG.PARCIAL
    $C     RKEY3         IFNE      0
    $C                   ADD       RKEY3         TKEY3             9 0          -REG.TOTAL
    $C*-
    $C                   SELECT                                                 -----------
    $C     ACOVEN        WHENEQ    '1'                                          -TIPO OPER.
    $C                   MOVEL     'PAQUETE'     ASERVI            7            -TIPO OPER.
    $C     ACOVEN        WHENEQ    '2'                                          -TIPO OPER.
    $C                   MOVEL     'LLAA   '     ASERVI                         -TIPO OPER.
    $C     ACOVEN        WHENEQ    '3'                                          -TIPO OPER.
    $C                   MOVEL     'RENFE  '     ASERVI                         -TIPO OPER.
    $C                   ENDSL                                                  -----------
    $C  N55              EXCEPT    CABREG
    $C  N55              SETON                                        55

    $C                   EXCEPT    IMPRE                                        -IMPRESORA

        //Acumulación de importe por Producto 
        Exec Sql
            SELECT SCODPR
            INTO :WCODPRO
            FROM T_MSOCIO
            WHERE NUREAL = :PNUREA;  

        Acumula_importe(SIMPOR/100:WCODPRO);


    $C                   ENDIF
    $C                   ENDIF
     C*******************************************************
     C* NO CRUZADO - NO CRUZADO - NO CRUZADO - NO CRUZADO   *
     C*******************************************************
     C                   IF        *IN02 = '1' AND *IN03 = '1' AND *IN44 = '1'
     C                   IF        ACOVEN = '1' OR ACOVEN = '3'
     C                   GOTO      FUERA
     C                   ELSE
     C                   GOTO      VERAIR
     C                   ENDIF
     C                   ENDIF
     C*******************************************************
     C* OPERACION -LLAA- Operacion a Operación   (ELIMINAR) *
     C*******************************************************
     C  N02
     CORN03
     CORN44              IF        ACOVEN = '2'
     C*--
     C     VERAIR        TAG
     C*--
     C     KEYPTE        SETLL     PTEPREW
     C     LEEAIR        TAG
     C                   READ      PTEPREW                                05
     C     *IN05         CABEQ     '1'           FUERA_AIR
     C     PNUCRU        CABNE     CAM15         FUERA_AIR
     C                   EVAL      KEY1   = PNUREA                              -KEY: KEYSO1
     C                   EVAL      KEY2   = PNUCRU                              -KEY: KEYSO1
     C                   EVAL      KEY3   = PIMPOR                              -KEY: KEYSO1
     C                   EVAL      KEY11  = PNUREA                              -KEY: KEYSO2
     C                   EVAL      KEY22  = PNUCRU                              -KEY: KEYSO2
     C                   EVAL      KEY33  = PIMPOR                              -KEY: KEYSO2
     C                   EVAL      KEY111 = PNUREA                              -KEY: KEYSO3
     C                   EVAL      KEY222 = PNUCRU                              -KEY: KEYSO3
     C                   EVAL      KEY333 = PIMPOR                              -KEY: KEYSO3
     C                   SETON                                        020344
     C     KEYSO1        CHAIN     SOCIO1W                            02
     C   02KEYSO2        CHAIN     SOCIO2W                            03
     C                   IF        *IN02 = '1' AND *IN03 = '1'
     C                   IF        ACOVEN = '2'                                 ----------
     C     KEYSO3        CHAIN     SOCIO3W                            44        -SOCIOLG3-
     C                   ENDIF                                                  ----------
     C                   ENDIF
     C*==========
     C* ELIMINAR
     C*==========
     C                   IF        *IN02 = '0' OR *IN03 = '0' OR *IN44 = '0'
     C                   DELETE    PTEPREW                                      ** PTEPREPR **
            If not *in02;
                Monitor;
                AUD_PA_SUP(rrn_pa1: P_nombre_pgm :p_error);
                ON-ERROR;
                Endmon;
            Endif;
     C  N02              DELETE    SOCIO1W                                      ** PA **
            If not *in03;
                Monitor;
                AUD_PA_SUP(rrn_pa2: P_nombre_pgm :p_error);
                ON-ERROR;
                Endmon;
            Endif;
     C  N03              DELETE    SOCIO2W                                      -FUTURO PA
            If not *in44;
                Monitor;
                AUD_PA_SUP(rrn_pa3: P_nombre_pgm :p_error);
                ON-ERROR;
                Endmon;
            Endif;
     C  N44              DELETE    SOCIO3W                                      -FUTURO PA
     C*--
     C                   EXSR      EVICON                                       -ASIENTO
     C*--
     C                   SETON                                        04        ------------
     C     SNUREF        CHAIN     GDESCR                             04        -DESCRIPCION
     C  N04              IF        ANUREA = GNUMSO                              -DESCRIPCION
     C                   DELETE    GDESCR                                       -DESCRIPCION
     C                   ENDIF                                                  ------------
     C*--
     C                   Z-ADD     SNUMES        PNUMES                         -PROVEEDOR
     C                   Z-ADD     SNUPAI        PNUPAI                         -PAIS
     C                   Z-ADD     SCAMBI        PCAMBI                         -CAMBIO
     C                   Z-ADD     SMONED        PMONED                         -MONEDA
     C                   MOVE      SVARIO        PVARIO                         -IMP.MONEDA
     C                   Z-ADD     SRECAP        PRECAP                         -RECAP
     C                   Z-ADD     AMDSYS        PFECRU                         -FEC.CRUCE
     C                   WRITE     PPAHISW                                      ** PTEPRHIS **
     C                   ENDIF
     C*==========
     C                   GOTO      LEEAIR
     C     FUERA_AIR     TAG
     C                   ENDIF
     C*******************************************************
     C* OPERACIONES --RENFE / PAQUETE--          (ELIMINAR) *
     C*******************************************************
     C  N02              IF        ACOVEN = '1' OR ACOVEN = '3'
     *---------------------------------------------------
     * CONTROL: 2 OPER. EN PTEPREPR CON DISTINTA AUTORIZ.
     *          2 OPER. EN PA CON IGUAL Nº.AUTORIZACION
     *---------------------------------------------------
     C                   IF        ACOOPE = 0
     C     KEYPTE        CHAIN     PTEPREW                                      -PTEPREPR
     C                   IF        NOT %FOUND
     C                   GOTO      FUERA
     C                   ENDIF
     C                   ENDIF
     *---------------------------------------------------
            Monitor;
            AUD_PA_SUP(rrn_pa1: P_nombre_pgm :p_error);
            ON-ERROR;
            Endmon;

     C                   DELETE    SOCIO1W                                      -ELEIMINA EN -PA-
     C                   EXSR      EVICON                                       -EVIDENCIA/ASIENTO
     C                   SETON                                        04        ------------
     C     SNUREF        CHAIN     GDESCR                             04        -DESCRFAC
     C  N04              IF        ANUREA = GNUMSO                              -DESCRFAC
     C                   DELETE    GDESCR                                       -DESCRFAC
     C                   ENDIF                                                  ------------
     C*-----------------------
     C* DESGLOSE OPERACIONES
     C*-----------------------
     C     KEYPTE        SETLL     PTEPREW                                      -PENDIENTE
     C     LEEDES        TAG                                                    -PENDIENTE
     C                   READ      PTEPREW                                05    -PENDIENTE
     C     *IN05         CABEQ     '1'           FUERA                          -PENDIENTE
     C     PNUCRU        CABNE     CAM15         FUERA                          -PENDIENTE
     C                   DELETE    PTEPREW                                      -PENDIENTE
     C*                                                    ----------
     C                   Z-ADD     SNUMES        PNUMES                         -PROVEEDOR
     C                   Z-ADD     SNUPAI        PNUPAI                         -PAIS
     C                   Z-ADD     SCAMBI        PCAMBI                         -CAMBIO
     C                   Z-ADD     SMONED        PMONED                         -MONEDA
     C                   MOVE      SVARIO        PVARIO                         -IMP.MONEDA
     C                   Z-ADD     SRECAP        PRECAP                         -RECAP
     C                   Z-ADD     AMDSYS        PFECRU                         -FEC.CRUCE
     C                   WRITE     PPAHISW                                      -HISTORICO
     C*                                                    ----------
     C                   SUB       PIMPOR        AIMPOR                         -DESGLOSE
     C     AIMPOR        CABEQ     0             FUERA                          -DESGLOSE
     C                   GOTO      LEEDES                                       -PENDIENTE
     C                   END
     C*******************************************************
     C     FUERA         TAG
     C   01              GOTO      FIN
     C                   Z-ADD     0             AIMPOR            9 0
     C                   Z-ADD     PAGENC        PPAGEN            4 0          -PUNT.BOLSA
     C                   Z-ADD     PNUREA        PPNURE            8 0          -PUNT.BOLSA
     C                   MOVEL     PNUCRU        PPNUCR           15            -PUNT.BOLSA
     C                   END
     C*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$**
     C*================================================================
     C                   Z-ADD     PAGENC        AAGENC            4 0          -AGENCIA
     C                   Z-ADD     PNUREA        ANUREA            8 0          -TARJETA
     C                   MOVEL     PNUCRU        ANUCRU           15            -BILL./AUT.
     C                   ADD       PIMPOR        AIMPOR            9 0          -IMPORTE
     C                   MOVE      PCOVEN        ACOVEN            1            -COD.VENTA
    $C                   Z-ADD     PFCONS        AFECON            8 0          -FEC.CONSUMO
    $C                   ADD       1             ACOOPE                         -CONT.OPERAC
     C*--
     C                   GOTO      LEEPTE
     C*****************************************************************
     C***                 FIN PROGRAMA                              ***
     C*****************************************************************
     C     FIN           TAG
     C*------------------------------*
     C* ACTUALIZA -TOTASAX- (PTEPRE) *
     C*------------------------------*
     C                   Z-ADD     PTSPTE        PTSTOT           13 0          -PTEPRE-
     C     PTSTOT        MULT      -1            PTSTOT
     C                   Z-ADD     UDATE         FECHA             6 0          -PTEPRE-
     C                   CALL      'ACUTOTN'                                    -PTEPRE-
     C                   PARM      'PTEPRE'      CLATOT            6            -PTEPRE-
     C                   PARM      MSG(1)        TEXTO            30            -PTEPRE-
     C                   PARM                    PTSTOT                         -PTEPRE-
     C                   PARM                    FECHA                          -PTEPRE-
     C*------------------------------*
     C* ACTUALIZA -TOTASAX- (PAGE00) *
     C*------------------------------*
     C                   CALL      'ACUTOTN'                                    -PAGE00-
     C                   PARM      'PAGE00'      CLATOT            6            -PAGE00-
     C                   PARM      MSG(1)        TEXTO            30            -PAGE00-
     C                   PARM                    PTSTOT                         -PAGE00-
     C                   PARM                    FECHA                          -PAGE00-
    $C*-----------------------------*
    $C*      ASIENTO CONTABLE       *
    $C* REG.DIFEREN.CONVERSION EURO *
    $C*-----------------------------*
    $C     TKEY3         IFNE      0
    $C                   MOVE      *BLANKS       CAPUNT
    $C                   MOVEL     'NEGR02'      CPROGR
     C                   MOVE      HORSYS        CPROVI
     C                   MOVE      'A'           CPROVI
    $C                   Z-ADD     *DATE         CFECON
    $C                   Z-ADD     0             CCODIG
    $C                   MOVEA     MSG(2)        CCONCE
    $C                   MOVE      '1'           CMONED                         -CTMOS.EURO
    $C                   Z-ADD     TKEY3         CIMPOR                 93
    $C   93              MULT      -1            CIMPOR
    $C*---
    $C     TKEY3         IFGT      0
    $C                   MOVEL     '40030'       CCTAMA
    $C                   MOVE      *BLANKS       CCTAFI
    $C                   MOVE      *BLANKS       CCTAAU
    $C                   MOVE      'D'           CDEHA
    $C                   WRITE     ASIW2                                        -ASICONT1-
    $C                   MOVEL     '7472 '       CCTAMA
    $C                   MOVE      '32'          CCTAFI
    $C                   MOVE      '60000'       CCTAAU
    $C                   MOVE      'H'           CDEHA
    $C                   WRITE     ASIW2                                        -ASICONT1-
    $C*-
    $C                   ELSE
    $C*-
    $C                   MOVEL     '62742'       CCTAMA
    $C                   MOVE      '32'          CCTAFI
    $C                   MOVE      '60000'       CCTAAU
    $C                   MOVE      'D'           CDEHA
    $C                   WRITE     ASIW2                                        -ASICONT1-
    $C                   MOVEL     '40030'       CCTAMA
    $C                   MOVE      *BLANKS       CCTAFI
    $C                   MOVE      *BLANKS       CCTAAU
    $C                   MOVE      'H'           CDEHA
    $C                   WRITE     ASIW2                                        -ASICONT1-
    $C                   ENDIF
    $C                   ENDIF
     C*---------------------------
     C* EVIDENCIA ASIENTO -FINAL-
     C*---------------------------
     C     S1(1)         COMP      0                                      11
     C     S1(2)         COMP      0                                      12
     C     S1(3)         COMP      0                                      13
     C   33              ADD       1             LIN
     C   33LIN           IFGE      60
     C                   EXCEPT    CAB
     C                   Z-ADD     8             LIN
     C                   ENDIF
     C   33              EXCEPT    CONTA
     C   33              EXCEPT    CONTAE                                       -IMP2017
     C   33              ADD       6             LIN
     C   33LIN           IFGE      60
     C                   EXCEPT    CAB
     C                   ENDIF
     C   33              EXCEPT    TOT
     C*-----------------
     C* ASIENTO -FINAL-
     C*-----------------
     C   33              EXSR      EVIASI
     C   55              EXCEPT    TOT2
     C*--
     C                   SETON                                        LR
     C                   RETURN

     C*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
     C*%%         SUBRUTINA: EVIDENCIA CONTABLE / TOTASAX           %%*
     C*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
     C     EVICON        BEGSR
     C*----------------------------------
     C* SI HAY EVIDENCIA, SALE LISTADO
     C*----------------------------------
     C  N99              OPEN      IMP2017                                      EXPLOTACION
     C  N99              SETON                                        99
     C*--
     C                   SETON                                        33        -HAY CRUZADO-
     C*--
     C  N98              Z-ADD     AAGENC        XAGENC            4 0          -UNA VEZ-
     C  N98              SETON                                        98        -UNA VEZ-
     C*---------------------
     C* RUPTURA POR AGENCIA
     C*---------------------
     C     AAGENC        IFNE      XAGENC
     C                   EXSR      EVIASI                                       -ASIENTO-
     C                   ENDIF
     C*-------------------------
     C* 3 OPERACIONES POR LINEA
     C*-------------------------
     C     Q             IFEQ      03
     C                   ADD       1             LIN
     C     LIN           IFGE      60
     C                   EXCEPT    CAB
     C                   Z-ADD     8             LIN
     C                   ENDIF
     C                   EXCEPT    CONTA                                        -
     C                   EXCEPT    CONTAE                                       -IMP2017-
     C                   Z-ADD     0             Q                 2 0
     C                   ENDIF
     C                   ADD       1             Q
     C*-
     C                   Z-ADD     AAGENC        S1(Q)                          -AGENCIA
     C                   Z-ADD     SNUREF        S2(Q)                          -Nº.DESCRFAC
     C                   Z-ADD     SNUREA        S3(Q)                          -TARJETA
     C                   Z-ADD     SIMPOR        S4(Q)                          -IMPORTE
     C                   Z-ADD     AAGENC        S1E(Q)                         -AGENCIA
     C                   Z-ADD     SNUREF        S2E(Q)                         -Nº.DESCRFAC
     C                   Z-ADD     SNUREA        S3E(Q)                         -TARJETA
     C                   Z-ADD     SIMPOR        S4E(Q)                         -IMPORTE
     C*-
     C                   ADD       SIMPOR        PTSASI           10 0          -ASIENTO
     C                   ADD       SIMPOR        PTSPTE           13 0          -TOTASAX
     C                   Z-ADD     AAGENC        XAGENC                         -AGENCIA-

          // Acumulación de importe por Producto
          Exec Sql
            SELECT SCODPR
            INTO :WCODPRO
            FROM T_MSOCIO
            WHERE NUREAL = :PNUREA;  

          Acumula_importe(SIMPOR/100:WCODPRO);


     C                   ENDSR
     C*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
     C*%%         SUBRUTINA: LINEAS DE ASIENTOS                     %%*
     C*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
     C     EVIASI        BEGSR
     C*-
     C                   SETON                                        06        -FAGENCON-
     C     XAGENC        CHAIN     FAGENCW                            06        -FAGENCON-
     C*-
     C                   MOVE      '   005'      CAPUNT
     C                   MOVEL     'NEGR02'      CPROGR
     C                   MOVEL     HORSYS        CPROVI
     C                   Z-ADD     *DATE         CFECON
     C                   MOVE      *BLANKS       CCTAFI
     C                   MOVE      *BLANKS       CCTAAU
    $C                   MOVE      '1'           CMONED                         -CTMOS.EURO
     C*-
     C                   MOVEL     '4325 '       CCTAMA
     C                   Z-ADD     0             CCODIG
     C                   MOVE      *BLANKS       CCONCE
     C                   MOVEA     *BLANKS       ASI
     C                   MOVEL     'CRUCE FA'    CAM11            11            TEXTO FIJO
     C                   MOVE      'CT.'         CAM11            11            TEXTO FIJO
     C                   MOVEL     FNOAGE        CAM18            18            NOMBRE AG.
     C                   MOVEA     CAM11         ASI(1)
     C                   MOVEA     CAM18         ASI(12)
     C                   MOVEA     ASI           CCONCE
     C                   Z-ADD     PTSASI        CIMPOR                 17
     C  N17              MOVE      'H'           CDEHA
     C   17              MOVE      'D'           CDEHA
     C   17              MULT      -1            CIMPOR
     C                   WRITE     ASIW
     C*-
     C                   MOVEL     '40030'       CCTAMA
     C                   Z-ADD     PTSASI        CIMPOR                 17
     C  N17              MOVE      'D'           CDEHA
     C   17              MOVE      'H'           CDEHA
     C   17              MULT      -1            CIMPOR
     C                   WRITE     ASIW
     C*-
     C                   Z-ADD     0             PTSASI
     C                   ENDSR
     C*****************************************************************
     C* INICIALIZACION DEL PROGRAMA
     C*****************************************************************
     C     *INZSR        BEGSR
     C                   TIME                    TIMSYS
     C                   MOVE      *DATE         FECSYS
     C     FECSYS        DIV       100           AMDSYS
     C                   MOVEL     AÑOSYS        AMDSYS
     C                   MOVE      DIASYS        AMDSYS
     C                   MOVEL     HORSYS        AAPUNT
     C                   MOVEL     HORSYS        APROVI
     C                   Z-ADD     99            LIN               3 0
     C*
     C                   MOVE      AEVIDE        AEVID1
     C                   MOVE      'A'           APROV1
     C                   MOVE      'A'           APUNT1
     C                   ENDSR
     OCABE27    E            TOT
     O                                           24 'OPER.DE PROVEEDORES YA F'
     O                                           41 'ACTUR.POR AGENCIA'
     O                       UDATE         Y     50
     O                       HORSYS              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       HORSYS              78
     O          E            TOT2
     O                                           24 'REGULAR.DIFER.CONVERSION'
     O                                           29 ' EURO'
     O                       UDATE         Y     38
     O                       HORSYS              56
     O                                           56 'A'
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       HORSYS              78
     O                                           78 'A'
     ODETE27    E            CAB
     O                                            6 'NEGR02'
     O                                           64 '--CONCILIACION TARJETAS '
     O                                           81 'CTAS.DE VIAJES --'
     O                       *DATE         Y    115
     O                                          128 'PAGINA'
     O                       PAGE          Z    132
     O                       AEVIDE             157
     O          E            CAB
     O                       AEVIDE             157
     O          E            CAB
     O                                           29 'RELACION DE OPERACIONES '
     O                                           53 'PRESENTADAS POR PROVEEDO'
     O                                           77 'RES Y YA LO HIZO LA AGEN'
     O                                           80 'CIA'
     O                       AEVIDE             157
     O          E            CAB
     O                                           29 '------------------------'
     O                                           53 '------------------------'
     O                                           77 '------------------------'
     O                                           80 '---'
     O                       AEVIDE             157
     O          E            CAB
     O                       AEVIDE             157
     O          E            CAB
     O                                           29 'AGE./N.DESCRF./N.TARJE./'
     O                                           42 'IMPORTE      '
     O                                           72 'AGE./N.DESCRF./N.TARJE./'
     O                                           85 'IMPORTE      '
     O                                          115 'AGE./N.DESCRF./N.TARJE./'
     O                                          128 'IMPORTE      '
     O                       AEVIDE             157
     O          E            CAB
     O                                           29 '------------------------'
     O                                           42 '-------------'
     O                                           72 '------------------------'
     O                                           85 '-------------'
     O                                          115 '------------------------'
     O                                          128 '-------------'
     O                       AEVIDE             157
     O*----------------------------------------------------------------
     O          E            CONTA
     O                    N11S1(1)          B     9
     O                    N11                    10 '/'
     O                    N11S2(1)          B    19
     O                    N11                    20 '/'
     O                    N11S3(1)          B    28
     O                    N11                    29 '/'
    $O                    N11S4(1)          B    42 ' .   . 0 ,  -'
     O*--
     O                    N12S1(2)          B    52
     O                    N12                    53 '/'
     O                    N12S2(2)          B    62
     O                    N12                    63 '/'
     O                    N12S3(2)          B    71
     O                    N12                    72 '/'
    $O                    N12S4(2)          B    85 ' .   . 0 ,  -'
     O*--
     O                    N13S1(3)          B    95
     O                    N13                    96 '/'
     O                    N13S2(3)          B   105
     O                    N13                   106 '/'
     O                    N13S3(3)          B   114
     O                    N13                   115 '/'
    $O                    N13S4(3)          B   128 ' .   . 0 ,  -'
     O                       AEVIDE             157
     O*----------------------------------------------------------------
     O          E            TOT
     O                       AEVIDE             157
     O          E            TOT
     O                       AEVIDE             157
     O          E            TOT
     O                                           33 '--------------'
     O                       AEVIDE             157
     O          E            TOT
     O                                           16 'TOTAL -----'
     O                       PTSPTE              33 '     .   . 0 ,  -'
     O                       AEVIDE             157
     O          E            TOT
     O                                           33 '--------------'
     O                       AEVIDE             157
     O*---------------------------------------------------------------*-
     O*- EVIDENCIA CONTABLE -REGULARIZAR DIFERENCIAS CONVERSION EURO- *-
     O*---------------------------------------------------------------*-
     ODETEVI22  E            CABREG
     O                                            6 'NEGR02'
     O                                           52 '--CONCILIACION TARJETAS '
     O                                           69 'CTAS.DE VIAJES --'
     O                                          100 '--ACUMULACION PA--'
     O                       *DATE         Y    115
     O                                          128 'PAGINA'
     O                       PAGE1         Z    132
     O                       AEVID1             157
     O          E            CABREG
     O                       AEVID1             157
     O          E            CABREG
     O                                           29 'RELACION DE OPERACIONES '
     O                                           53 'PRESENTADAS POR PROVEEDO'
     O                                           77 'RES Y YA LO HIZO LA AGEN'
     O                                           80 'CIA'
     O                                          109 '-REGULAR.DIFER.CONVERSIO'
     O                                          116 'N EURO-'
     O                       AEVID1             157
     O          E            CABREG
     O                                           29 '------------------------'
     O                                           53 '------------------------'
     O                                           77 '------------------------'
     O                                           80 '---'
     O                                          109 '------------------------'
     O                                          116 '-------'
     O                       AEVID1             157
     O          E            CABREG
     O                       AEVID1             157
     O          E            CABREG
     O                                           19 '  SOCIO  '
     O                                           34 'IMP. -BOLSA-'
     O                                           49 'IMPORTE -PA-'
     O                                           64 'REGULARIZAR '
     O                                           77 'FEC.OPERA.'
     O                                           87 'AGENCIA'
     O                                          104 'AUT./BILL./AQ.'
     O                                          115 'SERVICIO'
     O                       AEVID1             157
     O          E            CABREG
     O                                           19 '---------'
     O                                           34 '------------'
     O                                           49 '------------'
     O                                           64 '------------'
     O                                           77 '----------'
     O                                           87 '-------'
     O                                          104 '--------------'
     O                                          115 '--------'
     O                       AEVID1             157
     O*----------------------------------------------------------------
     O          E            IMPRE
     O                       ANUREA              19 '    -    '
     O                       GKEY3               34 ' .   . 0 ,  -'
     O                       SIMPOR              49 ' .   . 0 ,  -'
     O                       RKEY3               64 ' .   . 0 ,  -'
     O                       AFECON              77 '  .  .    '
     O                       AAGENC              86
     O                       ANUCRU             105
     O                       ASERVI             115
     O                       AEVID1             157
     O*----------------------------------------------------------------
     O          E            TOT2
     O                       AEVID1             157
     O          E            TOT2
     O                       AEVID1             157
     O          E            TOT2
     O                                           64 '------------'
     O                       AEVID1             157
     O          E            TOT2
     O                       TKEY3               64 ' .   . 0 ,  -'
     O                       AEVID1             157
     O                       AEVID1             157
     O          E            TOT2
     O                                           64 '------------'
     O                       AEVID1             157
     O*-----------------------------------------------------------------
     OIMP2017   E            CAB              03
     O                                           24 '** E X P L O T A C I O N'
     O                                           27 ' **'
     O                                           64 '--CONCILIACION TARJETAS '
     O                                           81 'CTAS.DE VIAJES --'
     O                       *DATE         Y    115
     O                                          132 'NEGR02'
     O          E            CAB         2
     O                                           29 'RELACION DE OPERACIONES '
     O                                           53 'PRESENTADAS POR PROVEEDO'
     O                                           77 'RES Y YA LO HIZO LA AGEN'
     O                                           80 'CIA'
     O          E            CAB         1
     O                                           29 '------------------------'
     O                                           53 '------------------------'
     O                                           77 '------------------------'
     O                                           80 '---'
     O          E            CAB         2
     O                                           29 'AGE./N.DESCRF./N.TARJE./'
     O                                           42 'IMPORTE      '
     O                                           72 'AGE./N.DESCRF./N.TARJE./'
     O                                           85 'IMPORTE      '
     O                                          115 'AGE./N.DESCRF./N.TARJE./'
     O                                          128 'IMPORTE      '
     O          E            CAB         1
     O                                           29 '------------------------'
     O                                           42 '-------------'
     O                                           72 '------------------------'
     O                                           85 '-------------'
     O                                          115 '------------------------'
     O                                          128 '-------------'
     O          EF           CONTAE      1
     O                    N11S1E(1)         B     9
     O                    N11                    10 '/'
     O                    N11S2E(1)         B    19
     O                    N11                    20 '/'
     O                    N11S3E(1)         B    28
     O                    N11                    29 '/'
    $O                    N11S4E(1)         B    42 ' .   . 0 ,  -'
     O*--
     O                    N12S1E(2)         B    52
     O                    N12                    53 '/'
     O                    N12S2E(2)         B    62
     O                    N12                    63 '/'
     O                    N12S3E(2)         B    71
     O                    N12                    72 '/'
    $O                    N12S4E(2)         B    85 ' .   . 0 ,  -'
     O*--
     O                    N13S1E(3)         B    95
     O                    N13                    96 '/'
     O                    N13S2E(3)         B   105
     O                    N13                   106 '/'
     O                    N13S3E(3)         B   114
     O                    N13                   115 '/'
    $O                    N13S4E(3)         B   128 ' .   . 0 ,  -'
     O*--
    $O          E            TOT         3
    $O                                           33 '--------------'
    $O          E            TOT         1
    $O                                           16 'TOTAL -----'
    $O                       PTSPTE              33 '     .   . 0 ,  -'
    $O          E            TOT         1
    $O                                           33 '--------------'

        //-----------------------------------------------------------------
        // Acumula_importe
        //-----------------------------------------------------------------
        dcl-proc Acumula_importe;
            dcl-pi *n Ind;
              P_Impor   Packed(14:3) const;
              p_Product Zoned(3);
            end-pi;

            Dcl-s WIndx    Zoned(3);

            WIndx = %lookup(p_Product: Acumulador(*).Cod_prod:1);
            if WIndx > 0;
                Acumulador(WIndx).Total += P_Impor;
            else;
                WInd += 1;
                Acumulador(WInd).Cod_prod = p_Product;
                Acumulador(WInd).Total    = P_Impor;
            endif;

            Return *On;

        end-proc;
**
OP.PROV.YA FACTUR.AGEN. NEGR02
REGUL.DIFERENCIA OPE.AG.NEGR02
