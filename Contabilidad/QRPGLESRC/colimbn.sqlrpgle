        Ctl-Opt DECEDIT('0,') DATEDIT(*DMY.) DFTACTGRP(*NO)
                BNDDIR('CONTBNDDIR':'UTILITIES/UTILITIES');
      *****************************************************************
      **            --CONCILIACION CTAS. DE VIAJES--                 **
      **                                                             **
      **  OPERATIVA DIARIA: LIMPIEZA DE BOLSAS (AGENCIA/PROVEEDOR)   **
      **                                                             **
      **    ASIENTO'S/ANEXO'S/EVIDENCIA'S  --DEPART.CONTABILIDAD--   **
      **                                                             **
      *****************************************************************
     FCOLIMBOK  IF   E           K DISK    PREFIX(A:1)
     FANEXOLBC  O    F  165        DISK

     FCABE29    O    F   78        DISK
     FDETE29    O    F  157        DISK
     FDETCOL1   O    F  157        DISK
     FDETCOL2   O    F  157        DISK
     FDETCOL3   O    F  157        DISK
      *****************************************************************
     D  CTIPRO         S              1    INZ('0')
     D  CMONED         S              1    INZ('1')
     D  CPROGR         S              6    INZ('COLIMB')
     D  CPROVI         S              6
     D  CFEVTO         S              8  0 INZ(00000000)
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
      /COPY EXPLOTA/QRPGLESRC,DSTIMSYS

      /COPY EXPLOTA/QRPGLESRC,DSAEVIDE
      // --------------------------
      // Declaracion Estructuras
      // --------------------------
      // Array / Matriz que totaliza importes por productos
       dcl-ds Acumulador_01 likeds(AcumuladorTpl) Dim(100) Inz;
       dcl-ds Acumulador_02 likeds(AcumuladorTpl) Dim(100) Inz;
       dcl-ds Acumulador_05 likeds(AcumuladorTpl) Dim(100) Inz;
       dcl-ds Acumulador_06 likeds(AcumuladorTpl) Dim(100) Inz;

       // --------------------------
       // Declaracion de Variables Globales
       // --------------------------
       Dcl-S fechaSistema Timestamp;

       Dcl-s WInd_01      Zoned(3);
       Dcl-s WInd_02      Zoned(3);
       Dcl-s WInd_05      Zoned(3);
       Dcl-s WInd_06      Zoned(3);

       Dcl-s WCodPro      Zoned(3);
       Dcl-s fecproces    Zoned(8);
       Dcl-s ID_Contab    Zoned(5) Inz(45); //Id_Asiento COLIMB
       Dcl-s WApunte      Char(6);
       Dcl-s v_tipo_error Char(3) Inz('PGM');
       Dcl-s WNomAsiPar Char(10);
       //Dcl-s WNomCabpar Char(10);
       //Dcl-s WNomDetPar Char(10);
       Dcl-s Wtarjeta   Zoned(8);
      *----------------------------------------------------------------
     C     *ENTRY        PLIST
     C                   PARM                    NOMASIPAR        10
     C*                   PARM                    NomCabpar        10
     C*                   PARM                    NomDetPar        10
     C                   PARM                    NumApunte         6
      *----------------------------------------------------------------
      *--               PROCESAR:  C O L I M B O K                   --
      *----------------------------------------------------------------
       /free
         WNomAsiPar = NomAsiPar;
         //WNomCabpar = NomCabpar;
         //WNomDetPar = NomDetPar;

         InicializarDatos();
         NumApunte = Wapunte;
         fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);

     C                   MOVEL     WApunte       AAPUNT
     C                   MOVE      AAPUNT        APUN5             5

     C                   DO        *HIVAL
     C                   READ      COLIMBW                                01
     C     *IN01         CABEQ     '1'           FIN
     C*-------------------
     C* TIPO DE OPERACION
     C*-------------------
     C                   MOVE      *BLANKS       SERVIC            7
     C                   SELECT
     C     ACOOPE        WHENEQ    '1'
     C                   MOVEL     'PAQUETE '    SERVIC
     C     ACOOPE        WHENEQ    '2'
     C                   MOVEL     'LLAA    '    SERVIC
     C     ACOOPE        WHENEQ    '3'
     C                   MOVEL     'RENFE   '    SERVIC
     C                   ENDSL
     C*-------------
     C* OPCION MENU
     C*-------------

         WTarjeta = ATARJE;


     C     ACOOOM        CASEQ     '1'           SUBR01                         -BAJA BA
     C     ACOOOM        CASEQ     '2'           SUBR02                         -BAJA BA REC
     C     ACOOOM        CASEQ     '5'           SUBR05                         -BAJA BP
     C     ACOOOM        CASEQ     '6'           SUBR06                         -BAJA BP REC
     C                   END
     C*-------------
     C                   ENDDO
     C*----------------------------------------------------------------
     C*--                    FIN PROCESO                             --
     C*----------------------------------------------------------------
     C     FIN           TAG
     C*-
     C   11              EXCEPT    TOT1
     C   22              EXCEPT    TOT2
     C   55              EXCEPT    TOT5
     C   66              EXCEPT    TOT6

         If WInd_01 > 0;
           Genera_Contabilidad_Producto(Acumulador_01:WInd_01:2:6);
         endif;

         If WInd_02 > 0;
           Genera_Contabilidad_Producto(Acumulador_02:WInd_02:3:5);
         endif;

         If WInd_05 > 0;
           Genera_Contabilidad_Producto(Acumulador_05:WInd_05:3:4);
         endif;

         If WInd_06 > 0;
           Genera_Contabilidad_Producto(Acumulador_06:WInd_06:1:6);
         endif;

     C                   SETON                                        LR
     C                   RETURN
     C*****************************************************************
     C**               BAJAS OPERACIONES "BOLSA AGENCIA"             **
     C*****************************************************************
     C     SUBR01        BEGSR
     C                   SETON                                        11
     C                   ADD       1             LIN1
     C     LIN1          IFGE      60                                           -----------
     C                   EXCEPT    CAB1                                         -CABECERAS-
     C                   Z-ADD     8             LIN1                           -CABECERAS-
     C                   ENDIF                                                  -----------
     C*-------
     C* ANEXO
     C*-------
     C     ACBAJA        IFEQ      'A'                                          ------------
     C                   EXCEPT    ANEXO                                        **ANEXOLBC**
     C                   ENDIF                                                  ------------
     C*---------
     C* ASIENTO
     C*---------
     C     ACBAJA        IFEQ      'X'                                          ----------
     C     ASIGNO        COMP      '+'                                    13
     C*                   Z-ADD     *DATE         CFECON
     C                   MOVE      AIMPOS        AIMPOSD           9 2

         Exec Sql
          SELECT SCODPR
          INTO :WCODPRO
          FROM T_Msocio
          WHERE Nureal = :WTarjeta;

         Acumula_importe_01(AIMPOSD:WCODPRO);

     C                   ENDIF                                                   ------------
     C*----------
     C* DETALLES
     C*----------
     C                   EXCEPT    DET1                                         --IMPRESORA
     C                   ADD       AIMPOR        TIMPO1            9 0
     C*-
     C                   ENDSR
     C*****************************************************************
     C**       -RECUPERAR- BAJAS OPERACIONES "BOLSA AGENCIA"         **
     C*****************************************************************
     C     SUBR02        BEGSR
     C                   SETON                                        22
     C                   ADD       1             LIN2
     C     LIN2          IFGE      60                                           -----------
     C                   EXCEPT    CAB2                                         -CABECERAS-
     C                   Z-ADD     10            LIN2                           -CABECERAS-
     C                   ENDIF                                                  -----------
     C*-------
     C* ANEXO
     C*-------
     C     ACBAJA        IFEQ      'A'                                          ------------
     C                   EXCEPT    ANEXO                                        **ANEXOLBC**
     C                   ENDIF                                                  ------------
     C*---------
     C* ASIENTO
     C*---------
     C     ACBAJA        IFEQ      'X'                                          ----------
     C     ASIGNO        COMP      '+'                                    13
     C*                   Z-ADD     *DATE         CFECON
     C                   MOVE      AIMPOS        AIMPOSD           9 2

         Exec Sql
          SELECT SCODPR
          INTO :WCODPRO
          FROM T_Msocio
          WHERE Nureal = :WTarjeta;

         Acumula_importe_02(AIMPOSD:WCODPRO);

     C                   ENDIF                                                   ------------
     C*----------
     C* DETALLES
     C*----------
     C                   EXCEPT    DET2
     C                   ADD       AIMPOR        TIMPO2            9 0
     C*-
     C                   ENDSR
     C*****************************************************************
     C**           BAJAS OPERACIONES "BOLSA PROVEEDORES"             **
     C*****************************************************************
     C     SUBR05        BEGSR
     C                   SETON                                        55
     C                   ADD       1             LIN5
     C     LIN5          IFGE      60                                           -----------
     C                   EXCEPT    CAB5                                         -CABECERAS-
     C                   Z-ADD     8             LIN5                           -CABECERAS-
     C                   ENDIF                                                  -----------
     C*-------
     C* ANEXO
     C*-------
     C     ACBAJA        IFEQ      'A'
     C                   EXCEPT    ANEXO                                        **ANEXOLBC**
     C                   ENDIF
     C*---------
     C* ASIENTO
     C*---------
     C     ACBAJA        IFEQ      'X'
     C     ASIGNO        COMP      '+'                                    13
     C*                   Z-ADD     *DATE         CFECON
     C                   MOVE      AIMPOS        AIMPOSD           9 2

         Exec Sql
          SELECT SCODPR
          INTO :WCODPRO
          FROM T_Msocio
          WHERE Nureal = :WTarjeta;

         Acumula_importe_05(AIMPOSD:WCODPRO);

     C                   ENDIF
     C*----------
     C* DETALLES
     C*----------
     C                   EXCEPT    DET5                                         --IMPRESORA
     C                   ADD       AIMPOR        TIMPO5            9 0
     C*-
     C                   ENDSR
     C*****************************************************************
     C**      -RECUPERAR- BAJAS OPERACIONES "BOLSA PROVEEDORES"      **
     C*****************************************************************
     C     SUBR06        BEGSR
     C                   SETON                                        66
     C                   ADD       1             LIN6
     C     LIN6          IFGE      60                                           -----------
     C                   EXCEPT    CAB6                                         -CABECERAS-
     C                   Z-ADD     10            LIN6                           -CABECERAS-
     C                   ENDIF                                                  -----------
     C*-------
     C* ANEXO
     C*-------
     C     ACBAJA        IFEQ      'A'
     C                   EXCEPT    ANEXO                                        **ANEXOLBC**
     C                   ENDIF
     C*---------
     C* ASIENTO
     C*---------
     C     ACBAJA        IFEQ      'X'
     C     ASIGNO        COMP      '+'                                    13
     C*                   Z-ADD     *DATE         CFECON
     C                   MOVE      AIMPOS        AIMPOSD           9 2

         Exec Sql
          SELECT SCODPR
          INTO :WCODPRO
          FROM T_Msocio
          WHERE Nureal = :WTarjeta;

         Acumula_importe_06(AIMPOSD:WCODPRO);

     C                   ENDIF                                                   ------------
     C*----------
     C* DETALLES
     C*----------
     C                   EXCEPT    DET6                                         --IMPRESORA
     C                   ADD       AIMPOR        TIMPO6            9 0
     C*-
     C                   ENDSR
     C*****************************************************************
     C* INICIALIZACION DEL PROGRAMA
     C*****************************************************************
     C     *INZSR        BEGSR
     C                   TIME                    TIMSYS
     C     FECSYS        DIV       100           AMDSYS
     C                   MOVEL     AÑOSYS        AMDSYS
     C                   MOVE      DIASYS        AMDSYS
     C                   Z-ADD     0             CERO7             7 0
     C                   Z-ADD     99            LIN1              3 0
     C                   Z-ADD     99            LIN2              3 0
     C                   Z-ADD     99            LIN5              3 0
     C                   Z-ADD     99            LIN6              3 0
     C                   MOVEL     HORSYS        APROVI
     C                   MOVEL     HORSYS        CPROVI
     C                   ENDSR
     O*----------------------------------------------------------------
     O*--               A  N  E  X  O  S                             --
     O*----------------------------------------------------------------
     OANEXOLBC  E            ANEXO                                              DEVMAG
     O                                            1 '1'                         DEVMAG
     O                       ACOANE               2                             DEVMAG
     O                       CERO7               13P
     O                                           14 '0'
     O                       ATARAN              31
     O                       APUN5               40
     O                       AIMPOS              48P
     O                       AFEBAJ              79
     O                       ACOANE             128
     O*----------------------------------------------------------------
     OCABE29    E            TOT1
     O                                           24 'BAJAS BOLSA AGENCIAS    '
     O                       *DATE         Y     31
     O                       AAPUNT              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       HORSYS              78
     O          E            TOT2
     O                                           24 'RECUPERACION BAJAS BOLSA'
     O                                           33 ' AGENCIAS'
     O                       *DATE         Y     44
     O                       AAPUNT              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       HORSYS              78
     O                                           73 'A'
     O          E            TOT5
     O                                           24 'BAJAS BOLSA PROVEEDORES '
     O                       *DATE         Y     34
     O                       AAPUNT              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       HORSYS              78
     O                                           73 'B'
     O          E            TOT6
     O                                           24 'RECUPERACION BAJAS BOLSA'
     O                                           36 ' PROVEEDORES'
     O                       *DATE         Y     47
     O                       AAPUNT              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       HORSYS              78
     O                                           73 'C'
     O*----------------------------------------------------------------
     O*--       EVIDENCIA: BAJAS EN BOLSA DE AGENCIAS                --
     O*----------------------------------------------------------------
     ODETE29    E            CAB1
     O                                            6 'COLIMB'
     O                                           64 '-- CONCILIACION TARJETAS'
     O                                           82 ' CTAS.DE VIAJES --'
     O                                          110 '(BOLSA AGENCIAS)'
     O                                          128 'PAGINA'
     O                       PAGE          Z    132
     O                       AEVIDE             157
     O          E            CAB1
     O                       AEVIDE             157
     O          E            CAB1
     O                                           54 'ABSORCION PARTIDAS -NO- '
     O                                           78 'PRESENTADAS POR PROVEEDO'
     O                                           85 'RES AL '
     O                       *DATE         Y     95
     O                       AEVIDE             157
     O          E            CAB1
     O                                           54 '------------------------'
     O                                           78 '------------------------'
     O                                           95 '-----------------'
     O                       AEVIDE             157
     O          E            CAB1
     O                       AEVIDE             157
     O          E            CAB1
     O                                            9 ' TARJETA '
     O                                           18 'AGENCIA'
     O                                           27 'Nº.EST.'
     O                                           42 '   IMPORTE   '
     O                                           56 ' EXPEDIENTE '
     O                                           68 'FE.CONSUMO'
     O                                           85 'NUM.BILL./AUTOR'
     O                                           95 'TIP.OPE.'
     O                                          107 'F.BAJ/RECU'
     O                                          125 'TARJETA *ANEXO* '
     O                                          130 'T/A'
     O                       AEVIDE             157
     O          E            CAB1
     O                                            9 '---------'
     O                                           18 '-------'
     O                                           27 '-------'
     O                                           42 '-------------'
     O                                           56 '------------'
     O                                           68 '----------'
     O                                           85 '---------------'
     O                                           95 '--------'
     O                                          107 '----------'
     O                                          125 '----------------'
     O                                          130 '---'
     O                       AEVIDE             157
     O*----------------------------------------------------------------
     O          E            DET1
     O                       ATARJE               9 '    -    '
     O                       AAGENC              17
     O                       ACOMER              27
     O                       AIMPOR              42 ' .   . 0 ,  -'
     O                       AEXPED              56
     O                       AFEOPE        Y     68
     O                       ANAUBI              85
     O                       SERVIC              94
     O                       AFEBAJ        Y    107
     O                       ATARAN             125 '    -      -    '
     O                       ACOANE             129
     O                       AEVIDE             157
     O*----------------------------------------------------------------
     O          E            TOT1
     O                       AEVIDE             157
     O          E            TOT1
     O                       AEVIDE             157
     O          E            TOT1
     O                                           43 '--------------'
     O                       AEVIDE             157
     O          E            TOT1
     O                       TIMPO1              42 '  .   . 0 ,  -'
     O                       AEVIDE             157
     O          E            TOT1
     O                                           43 '--------------'
     O                       AEVIDE             157
     O*----------------------------------------------------------------
     O*--       EVIDENCIA: RECUPERAR BAJAS EN BOLSA DE AGENCIAS      --
     O*----------------------------------------------------------------
     ODETCOL1   E            CAB2
     O                                            6 'COLIMB'
     O                                           64 '-- CONCILIACION TARJETAS'
     O                                           82 ' CTAS.DE VIAJES --'
     O                                          110 '(BOLSA AGENCIAS)'
     O                                          128 'PAGINA'
     O                       PAGE1         Z    132
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                                           70 '-- MARCHA ATRAS --'
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                                           54 'ABSORCION PARTIDAS -NO- '
     O                                           78 'PRESENTADAS POR PROVEEDO'
     O                                           85 'RES AL '
     O                       *DATE         Y     95
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                                           54 '------------------------'
     O                                           78 '------------------------'
     O                                           95 '-----------------'
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                                            9 ' TARJETA '
     O                                           18 'AGENCIA'
     O                                           27 'Nº.EST.'
     O                                           42 '   IMPORTE   '
     O                                           56 ' EXPEDIENTE '
     O                                           68 'FE.CONSUMO'
     O                                           85 'NUM.BILL./AUTOR'
     O                                           95 'TIP.OPE.'
     O                                          107 'F.BAJ/RECU'
     O                                          125 'TARJETA *ANEXO* '
     O                                          130 'T/A'
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            CAB2
     O                                            9 '---------'
     O                                           18 '-------'
     O                                           27 '-------'
     O                                           42 '-------------'
     O                                           56 '------------'
     O                                           68 '----------'
     O                                           85 '---------------'
     O                                           95 '--------'
     O                                          107 '----------'
     O                                          125 '----------------'
     O                                          130 '---'
     O                       AEVIDE             157
     O                                          152 'A'
     O*----------------------------------------------------------------
     O          E            DET2
     O                       ATARJE               9 '    -    '
     O                       AAGENC              17
     O                       ACOMER              27
     O                       AIMPOR              42 ' .   . 0 ,  -'
     O                       AEXPED              56
     O                       AFEOPE        Y     68
     O                       ANAUBI              85
     O                       SERVIC              94
     O                       AFEBAJ        Y    107
     O                       ATARAN             125 '    -      -    '
     O                       ACOANE             129
     O                       AEVIDE             157
     O                                          152 'A'
     O*----------------------------------------------------------------
     O          E            TOT2
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            TOT2
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            TOT2
     O                                           43 '--------------'
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            TOT2
     O                       TIMPO2              42 '  .   . 0 ,  -'
     O                       AEVIDE             157
     O                                          152 'A'
     O          E            TOT2
     O                                           43 '--------------'
     O                       AEVIDE             157
     O                                          152 'A'
     O*----------------------------------------------------------------
     O*--       EVIDENCIA: BAJAS EN BOLSA DE PROVEEDORES (PA)        --
     O*----------------------------------------------------------------
     ODETCOL2   E            CAB5
     O                                            6 'COLIMB'
     O                                           64 '-- CONCILIACION TARJETAS'
     O                                           82 ' CTAS.DE VIAJES --'
     O                                          113 '(BOLSA PROVEEDORES)'
     O                                          128 'PAGINA'
     O                       PAGE2         Z    132
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            CAB5
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            CAB5
     O                                           54 'DESABSORCION POR PRESENT'
     O                                           78 'ACIONES TARDIAS DE PROVE'
     O                                           88 'EDORES AL '
     O                       *DATE         Y     98
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            CAB5
     O                                           54 '------------------------'
     O                                           78 '------------------------'
     O                                           98 '--------------------'
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            CAB5
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            CAB5
     O                                            9 ' TARJETA '
     O                                           18 'AGENCIA'
     O                                           27 'Nº.EST.'
     O                                           42 '   IMPORTE   '
     O                                           56 ' EXPEDIENTE '
     O                                           68 'FE.CONSUMO'
     O                                           85 'NUM.BILL./AUTOR'
     O                                           95 'TIP.OPE.'
     O                                          107 'F.BAJ/RECU'
     O                                          125 'TARJETA *ANEXO* '
     O                                          130 'T/A'
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            CAB5
     O                                            9 '---------'
     O                                           18 '-------'
     O                                           27 '-------'
     O                                           42 '-------------'
     O                                           56 '------------'
     O                                           68 '----------'
     O                                           85 '---------------'
     O                                           95 '--------'
     O                                          107 '----------'
     O                                          125 '----------------'
     O                                          130 '---'
     O                       AEVIDE             157
     O                                          152 'B'
     O*----------------------------------------------------------------
     O          E            DET5
     O                       ATARJE               9 '    -    '
     O                       AAGENC              17
     O                       ACOMER              27
     O                       AIMPOR              42 ' .   . 0 ,  -'
     O                       AEXPED              56
     O                       AFEOPE        Y     68
     O                       ANAUBI              85
     O                       SERVIC              94
     O                       AFEBAJ        Y    107
     O                       ATARAN             125 '    -      -    '
     O                       ACOANE             129
     O                       AEVIDE             157
     O                                          152 'B'
     O*----------------------------------------------------------------
     O          E            TOT5
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            TOT5
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            TOT5
     O                                           43 '--------------'
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            TOT5
     O                       TIMPO5              42 '  .   . 0 ,  -'
     O                       AEVIDE             157
     O                                          152 'B'
     O          E            TOT5
     O                                           43 '--------------'
     O                       AEVIDE             157
     O                                          152 'B'
     O*----------------------------------------------------------------
     O*--   EVIDENCIA: RECUPARAR BAJAS EN BOLSA DE PROVEEDORES (PA)  --
     O*----------------------------------------------------------------
     ODETCOL3   E            CAB6
     O                                            6 'COLIMB'
     O                                           64 '-- CONCILIACION TARJETAS'
     O                                           82 ' CTAS.DE VIAJES --'
     O                                          113 '(BOLSA PROVEEDORES)'
     O                                          128 'PAGINA'
     O                       PAGE3         Z    132
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                                           70 '-- MARCHA ATRAS --'
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                                           54 'DESABSORCION POR PRESENT'
     O                                           78 'ACIONES TARDIAS DE PROVE'
     O                                           88 'EDORES AL '
     O                       *DATE         Y     98
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                                           54 '------------------------'
     O                                           78 '------------------------'
     O                                           98 '--------------------'
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                                            9 ' TARJETA '
     O                                           18 'AGENCIA'
     O                                           27 'Nº.EST.'
     O                                           42 '   IMPORTE   '
     O                                           56 ' EXPEDIENTE '
     O                                           68 'FE.CONSUMO'
     O                                           85 'NUM.BILL./AUTOR'
     O                                           95 'TIP.OPE.'
     O                                          107 'F.BAJ/RECU'
     O                                          125 'TARJETA *ANEXO* '
     O                                          130 'T/A'
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            CAB6
     O                                            9 '---------'
     O                                           18 '-------'
     O                                           27 '-------'
     O                                           42 '-------------'
     O                                           56 '------------'
     O                                           68 '----------'
     O                                           85 '---------------'
     O                                           95 '--------'
     O                                          107 '----------'
     O                                          125 '----------------'
     O                                          130 '---'
     O                       AEVIDE             157
     O                                          152 'C'
     O*---------------------------------------------------------------
     O          E            DET6
     O                       ATARJE               9 '    -    '
     O                       AAGENC              17
     O                       ACOMER              27
     O                       AIMPOR              42 ' .   . 0 ,  -'
     O                       AEXPED              56
     O                       AFEOPE        Y     68
     O                       ANAUBI              85
     O                       SERVIC              94
     O                       AFEBAJ        Y    107
     O                       ATARAN             125 '    -      -    '
     O                       ACOANE             129
     O                       AEVIDE             157
     O                                          152 'C'
     O*---------------------------------------------------------------
     O          E            TOT6
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            TOT6
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            TOT6
     O                                           43 '--------------'
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            TOT6
     O                       TIMPO6              42 '  .   . 0 ,  -'
     O                       AEVIDE             157
     O                                          152 'C'
     O          E            TOT6
     O                                           43 '--------------'
     O                       AEVIDE             157
     O                                          152 'C'

       /Free
        //-----------------------------------------------------------------------------
        // Inicializamos datos
        //-----------------------------------------------------------------------------
        dcl-proc InicializarDatos;

          fechaSistema = %timestamp();
          WApunte = CONTABSRV_Asignar_Numero_Apunte(fechaSistema);
          fechaSistema = fechaSistema -  %days(1);

        end-proc;
        //-----------------------------------------------------------------
        // Acumula_importe
        //-----------------------------------------------------------------
        dcl-proc Acumula_importe_01;
          dcl-pi *n Ind;
              P_Impor   Packed(14:3) const;
              p_Product Zoned(3);
            end-pi;

            Dcl-s WIndx    Zoned(3);

            WIndx = %lookup(p_Product: Acumulador_01(*).Cod_prod:1);
            if WIndx > 0;
              Acumulador_01(WIndx).Total += P_Impor;
            else;
              WInd_01 += 1;
              Acumulador_01(WInd_01).Cod_prod = p_Product;
              Acumulador_01(WInd_01).Total    = P_Impor;
            endif;

            Return *On;

        end-proc;
        //-----------------------------------------------------------------
        // Acumula_importe
        //-----------------------------------------------------------------
        dcl-proc Acumula_importe_02;
          dcl-pi *n Ind;
              P_Impor   Packed(14:3) const;
              p_Product Zoned(3);
            end-pi;

            Dcl-s WIndx    Zoned(3);

            WIndx = %lookup(p_Product: Acumulador_02(*).Cod_prod:1);
            if WIndx > 0;
              Acumulador_02(WIndx).Total += P_Impor;
            else;
              WInd_02 += 1;
              Acumulador_02(WInd_02).Cod_prod = p_Product;
              Acumulador_02(WInd_02).Total    = P_Impor;
            endif;

            Return *On;

        end-proc;
        //-----------------------------------------------------------------
        // Acumula_importe
        //-----------------------------------------------------------------
        dcl-proc Acumula_importe_05;
          dcl-pi *n Ind;
              P_Impor   Packed(14:3) const;
              p_Product Zoned(3);
            end-pi;

            Dcl-s WIndx    Zoned(3);

            WIndx = %lookup(p_Product: Acumulador_05(*).Cod_prod:1);
            if WIndx > 0;
              Acumulador_05(WIndx).Total += P_Impor;
            else;
              WInd_05 += 1;
              Acumulador_05(WInd_05).Cod_prod = p_Product;
              Acumulador_05(WInd_05).Total    = P_Impor;
            endif;

            Return *On;

        end-proc;
        //-----------------------------------------------------------------
        // Acumula_importe
        //-----------------------------------------------------------------
        dcl-proc Acumula_importe_06;
          dcl-pi *n Ind;
              P_Impor   Packed(14:3) const;
              p_Product Zoned(3);
            end-pi;

            Dcl-s WIndx    Zoned(3);

            WIndx = %lookup(p_Product: Acumulador_06(*).Cod_prod:1);
            if WIndx > 0;
              Acumulador_06(WIndx).Total += P_Impor;
            else;
              WInd_06 += 1;
              Acumulador_06(WInd_06).Cod_prod = p_Product;
              Acumulador_06(WInd_06).Total    = P_Impor;
            endif;

            Return *On;

        end-proc;

        //-----------------------------------------------------------------
        // Genera Contabilidad Totales por Productos
        //-----------------------------------------------------------------
        dcl-proc Genera_Contabilidad_Producto;

          dcl-pi *n ind;
            P_Acumulador likeds(AcumuladorTpl) Dim(100);
            P_Ind  Zoned(3);
            P_Orden_debe  Zoned(3) const;
            P_Orden_Haber Zoned(3) const;
          end-pi;

          Dcl-s I        Zoned(3);
          Dcl-s WMarca   Zoned(2);
          Dcl-s WCodProd Zoned(3);
          Dcl-s WExiste_Cod   Ind;
          Dcl-s WCodDiv  Char(3);
          Dcl-s WNumOrden Zoned(2);

          dcl-ds dsKeyAsiento likeds(dsKeyAsientoTpl) inz;
          dcl-ds dsDatosAsientoParametrizables
                  likeds(dsDatosAsientoParametrizablesTpl) inz;
          dcl-ds dsDatosAsientoNoParametrizables
                  likeds(dsDatosAsientoNoParametrizablesTpl) inz;
          dcl-ds dsAsifilen likeds(dsAsifilenTpl) inz;
          dcl-s textoError char(100) inz;
          dcl-s sqlError char(5) inz;
          dcl-s sqlMensaje char(70) inz;

          dsDatosAsientoNoParametrizables.numApunte = WApunte;
          dsDatosAsientoNoParametrizables.fechaContable = fecproces ;
          dsDatosAsientoNoParametrizables.referenciaOperacion = *blanks;
          dsDatosAsientoNoParametrizables.fechaVencimiento = 0;
          dsDatosAsientoNoParametrizables.codMoneda = '1';
          dsDatosAsientoNoParametrizables.apunteProvisional = *blanks;
          dsDatosAsientoNoParametrizables.tipoOperacion = 0;

          dsKeyAsiento.idAsiento = ID_Contab; // 45

          For I=1 to P_Ind;
            WCodProd = P_Acumulador(I).Cod_prod;
            dsKeyAsiento.codProducto = WCodProd;

            dsKeyAsiento.ordenApunte = P_Orden_debe;

            dsDatosAsientoNoParametrizables.debeHaber = 'D';
            if P_Acumulador(I).Total < 0;
              dsDatosAsientoNoParametrizables.debeHaber = 'H';
            endif;
            dsDatosAsientoNoParametrizables.importe =
                  %abs(P_Acumulador(I).Total);

            if not CONTABSRV_Obtener_Datos_Asiento(
                    dsKeyAsiento
                    :dsDatosAsientoParametrizables
                    :dsDatosAsientoNoParametrizables
                    :dsAsifilen
                    :textoError);
              return *off;
            endif;

            if not CONTABSRV_Grabar_Asiento(dsAsifilen
                  :sqlError
                  :sqlMensaje
                  :WNomAsiPar);
              // Agregar funcion de monitoreo de Errores y correo
              return *off;
            endif;

            dsKeyAsiento.ordenApunte = P_Orden_Haber;

            dsDatosAsientoNoParametrizables.debeHaber = 'H';
            if P_Acumulador(I).Total < 0;
              dsDatosAsientoNoParametrizables.debeHaber = 'D';
            endif;
            dsDatosAsientoNoParametrizables.importe =
                  %abs(P_Acumulador(I).Total);

            if not CONTABSRV_Obtener_Datos_Asiento(
                    dsKeyAsiento
                    :dsDatosAsientoParametrizables
                    :dsDatosAsientoNoParametrizables
                    :dsAsifilen
                    :textoError);
              return *off;
            endif;

            if not CONTABSRV_Grabar_Asiento(dsAsifilen
                  :sqlError
                  :sqlMensaje
                  :WNomAsiPar);
              // Agregar funcion de monitoreo de Errores y correo
              return *off;
            endif;
          Endfor;

          return *on;
        end-proc;

        /End-Free