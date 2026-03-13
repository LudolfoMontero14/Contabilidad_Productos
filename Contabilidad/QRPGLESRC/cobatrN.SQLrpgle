     H DECEDIT('0,') DATEDIT(*DMY.) 
     H BNDDIR('CONTBNDDIR':'UTILITIES/UTILITIES')
      *****************************************************************
      *             --CONCILIACION CTAS. DE VIAJES--                 **
      *                                                              **
      *   TRASPASOS DIARIOS: BOLSA AGENCIA A BOLSA PROVEEDORES       **
      *                                                              **
      *****************************************************************
     FCOBATRLG  IF   E           K DISK
     FFAGENCON  IF   E           K DISK
     FOPAGECOL1 IF   E           K DISK                                         OPAGECO
     FOPAGECOLG7IF   E           K DISK    RENAME(OPAGCOW:OPAGCOB)              OPAGECO_B
     FOPAGECOLH1IF   E           K DISK    RENAME(OPAGCOW:OPAGCHI)              OPAGECOMIH
     FMSOCIO    IF   F  731     8AIDISK    KEYLOC(3)
     FDESCRC17  O    E             DISK
     FPAC17     O    E             DISK
     FOPAGECO17 O    E             DISK    RENAME(OPAGCOW:OPAGC17)
     FASICOC17  O    F  101        DISK
     FCABE10    O    F   78        DISK
     FDETE10    O    F  157        DISK
     D*----------------------------------------------------------------
     D*--                S E R I E S  /  T A B L A S                 --
     D*----------------------------------------------------------------
     D GLI             S              1    DIM(59)                              CAMPO GLIN
     D DES             S             59    DIM(3) CTDATA PERRCD(1)              TEXTO FIJO L-1
     D MSG             S             30    DIM(1) CTDATA PERRCD(1)              TEXTO-TOTASAX
     D FCONSU          S              8  0
     D*--------------------------------
     D* REGISTRO DEL FICHERO -ASIFILE-
     D*--------------------------------
     D DSCONT          DS
     D  CAPUNT                 1      6
     D  APUN5                  2      6
     D  CCTAMA                 7     11
     D  CCTAFI                12     13
     D  CCTAAU                14     18
     D  CCODIG                19     21  0
     D  CPROGR                22     27    INZ('COBATR')
     D  CFECON                28     35  0
     D  CDEHA                 36     36
     D  CREFOP                37     42
     D  CFEVTO                43     50  0 INZ(00000000)
     D  CCONCE                51     80
     D  CIMPOR                81     94  3
     D  CMONED                95     95    INZ('1')
     D  CPROVI                96    101

      /COPY EXPLOTA/QRPGLESRC,DSTIMSYS
      /COPY EXPLOTA/QRPGLESRC,DSAEVIDE

      /Define Funciones_CONTABSRV
      /Define PGM_ASBUNU
      /Define Estructuras_Asientos_Evidencias
      /define Common_Variables
      /Include Explota/QRPGLESRC,CONTABSRVH

      /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
      /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

      Dcl-S fechaSistema Timestamp;
      Dcl-s WApunte      Char(6);
      Dcl-s fecproces    Zoned(8);
      Dcl-s WCODPROD     Char(3); 
      Dcl-s WCODCONTAB   Packed(5:0) Inz(42); // 
      Dcl-s WInd         Zoned(3);  

     D                 DS
     D  PREEXP                 1     20
     D  EXPEDI                 1     12

     D                 DS
     D  PNUCRU                 1     15
     D  NBILLE                 1     10
     D  NAUTOR                 1      4

     D                 DS
     D  KEYDES                 1      9  0
     D  TRABAJ                 1      3  0
     D  DUPLIC                 4      4  0
     D  NUREG                  5      9  0

     D INIREF          C                   'EXPT.AG.'

       // Array / Matriz que totaliza importes por productos
       dcl-ds Acumulador likeds(AcumuladorTpl) Dim(100) Inz;

     IMSOCIO    NS
     I                                  1   14 0NS14
     I                                434  434  CONDIC

     C*-------------
     C* PARAMETROS
     C*-------------
     C     *ENTRY        PLIST                                                                 COMPS
     C                   PARM                    NUMALF            3            -Nº.TRABAJO    COMPS
     C                   PARM                    PNOMASI          10            ASIFILE
     
        // inicializamos Array / Matriz
        Reset Acumulador;

        fechaSistema = %timestamp();
        WApunte = CONTABSRV_Asignar_Numero_Apunte(fechaSistema);
        fechaSistema = fechaSistema -  %days(1);
        fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);

     C*----------------------------------------------
     C* DESCRFAC (Nº.TRABAJO) BUSCO ULTIMO ASIGNADO
     C*----------------------------------------------
     C                   MOVEL     NUMALF        NUMTRA            3 0          -Nº.TRABAJO
     C*---
     C                   Z-ADD     0             KEYDES                         -Nº.DESCRIPC
     C                   Z-ADD     NUMTRA        TRABAJ                         -Nº.DESCRIPC
     C                   Z-ADD     0             DUPLIC                         -Nº.DESCRIPC
     C                   Z-ADD     0             NUREG                          -Nº.DESCRIPC
     C*---
     C                   Z-ADD     KEYDES        PARM1             9 0          -Nº.DESCRFAC
     C                   CALL      'ULTKEY'                                     -Nº.DESCRFAC
     C                   PARM                    PARM1                          -Nº.DESCRFAC
     C                   Z-ADD     PARM1         KEYDES                         -Nº.DESCRFAC
     C*----------------------------------------------------------------
     C*--               PROCESAR:  C O B A T R O K                   --
     C*----------------------------------------------------------------
     C                   DO        *HIVAL
     C                   READ      COBATRW                                01
     C     *IN01         CABEQ     '1'           FIN
     C*----------------------------
     C* EVIDENCIA: CABEVI - DETEVI
     C*----------------------------
     C                   ADD       1             LIN
     C*-
     C     LIN           IFGE      60                                           -----------
     C                   EXCEPT    CAB                                          -CABECERAS-
     C                   Z-ADD     8             LIN                            -CABECERAS-
     C                   ENDIF                                                  -----------
     C*-
     C                   EXSR      EVIDET                                       -DETALLES-
     C*------------------
     C* GUARDAR: CAMPOS.
     C*------------------
     C                   Z-ADD     PNUREA        GTAORI            8 0          -TARJ.ORIGEN
     C                   Z-ADD     PTARDE        GTADES            8 0          -TARJ.DESTIN
     C                   Z-ADD     PNUREF        GNUREF            9 0          -N.REFERENCIA
     C                   Z-ADD     PIMPOR        GIMPOR            9 0          -IMPORTE
     C                   Z-ADD     PFCONS        GFECON            8 0          -FECHA CONSUMO
     C                   MOVE      PNUCRU        GNUCRU           15            -CRUCE TARJ.CONCI
     C                   Z-ADD     PAGENC        GAGENC            4 0          -AGENCIA
     C                   Z-ADD     PDICON        GDICON            2 0          -DD CONTABLE
     C                   Z-ADD     PMACON        GMACON            6 0          -MA CONTABLE
     C                   MOVE      PTIBAJ        GTIBAJ            1            -TIPO TRASPA
     C*-
     C                   MOVE      PDICON        DDFAC             2            -DD FACTURAD
     C                   MOVEL     PMACON        MMFAC             2            -MM FACTURAD
     C                   MOVE      PMACON        AAFAC             2            -AA FACTURAD
     C*---------------------
     C* RUPTURA POR TARJETA
     C*---------------------
     C     GTADES        IFNE      ATADES
     C*-
     C                   SETOFF                                       33
     C                   SETON                                        11
     C     GTADES        CHAIN     MSOCIO                             11
     C  N11CONDIC        COMP      'C'                                    33

        Exec Sql
          SELECT SCODPR
          INTO :WCODPROD
          FROM T_MSOCIO
          WHERE NUREAL = :GTADES;  

     C                   ENDIF
     C*------------------------------------
     C* ACTUALIZAR: PA, DESCRFAC
     C*------------------------------------
     C                   EXSR      PAAC17                                       **PA**
     C                   EXSR      DESC17                                       **DESCRFAC**
     C                   EXSR      OPAGE17                                      **OPAGECO***
     C*------------------------------------
     C                   Z-ADD     GTADES        ATADES            8 0
     C                   ADD       GIMPOR        TOBABP           13 0          -TOT.TRASPASADO
     C  N33              ADD       GIMPOR        TOTRNC           10 0          -TOT.TRAS.NO CO
     C   33              ADD       GIMPOR        TOTRSC           10 0          -TOT.TRAS.SI CO

        // Aqui lo logica para cargar el arreglo 
          Acumula_importe(GIMPOR/100:WCODPROD);
        //-------------------------------
    
     C                   ENDDO
     C                   
     C                   
     C*----------------------------------------------------------------
     C*--             F I N A L    P R O G R A M A                   --
     C*----------------------------------------------------------------
     C     FIN           TAG
     C*--------------------
     C* ASIENTOS - TOTALES
     C*--------------------

      ****C                   EXSR      ASIC17                                **ASIFILE**
         Genera_Contabilidad();

     C                   EXSR      TOTC17                                       **TOTASAX**
     C*---------------------
     C                   EXCEPT    TOT
     C                   SETON                                        LR
     C                   RETURN
     C*****************************************************************
     C**     DETALLES EVIDENCIA CONTABLE -DETEVI-
     C*****************************************************************
     C     EVIDET        BEGSR
     C*------------------
     C* CHAIN -FAGENCON-
     C*------------------
     C                   SETON                                        14
     C     PAGENC        CHAIN     FAGENCW                            14
     C   14              MOVEL     *BLANKS       FNOAGE
     C  N14              MOVEL     FNOAGE        NAG25            25
     C*-----
     C                   MOVE      *BLANKS       PSERVI            8            -TIPO OPERAC
     C                   SELECT                                                 -TIPO OPERAC
     C     PCOVEN        WHENEQ    '1'                                          -TIPO OPERAC
     C                   MOVEL     'PAQUETE '    PSERVI                         -TIPO OPERAC
     C     PCOVEN        WHENEQ    '2'                                          -TIPO OPERAC
     C                   MOVEL     'LLAA--  '    PSERVI                         -TIPO OPERAC
     C                   MOVE      PIDCIA        PSERVI                         -TIPO OPERAC
     C     PCOVEN        WHENEQ    '3'                                          -TIPO OPERAC
     C                   MOVEL     'RENFE   '    PSERVI                         -TIPO OPERAC
     C                   ENDSL                                                  -TIPO OPERAC
     C*------------------
     C                   EXCEPT    DET                                          -DETALLES-
     C                   ENDSR
     C*****************************************************************
     C**        ALTA OPERACION EN -PA- TARJETA: DESTINO
     C**           (Importante: Cambiar de Signo al Importe)
     C*****************************************************************
     C     PAAC17        BEGSR
     C*--
     C                   ADD       1             KEYDES                         -DESCRFAC+1
     C*--
     C                   Z-ADD     KEYDES        PNUREF                         -**-
     C                   MOVE      '1'           PADICI                         -**-
     C                   MULT      -1            PIMPOR                         -**-
     C                   Z-ADD     GTADES        PNUREA                         -**-
     C                   Z-ADD     UDAY          PDICON                         -**-
     C                   MOVEL     UMONTH        PMACON                         -**-
     C                   MOVE      *YEAR         PMACON                         -**-
     C  N33              Z-ADD     0             PAGENC                         -**-
     C   33              Z-ADD     GAGENC        PAGENC                         -**-
     C  N33              MOVE      ' '           PCONCI                         -**-
     C   33              MOVE      'C'           PCONCI                         -**-
     C                   Z-ADD     PPESET        PESETA
     C                   MOVE      PMONEE        PCOMON
     C                   Z-ADD     0             PNBOPE
     C                   Z-ADD     0             PNBRES
     C                   MOVE      *BLANKS       PNOPRE
     C                   MOVE      *BLANKS       PNREEM
     C                   MOVE      *BLANKS       PPROTE
     C                   WRITE     PPA                                          **PA**
     C                   ENDSR
     C*****************************************************************
     C**       CREAR DESCRIPTIVA -DESCRFAC- TARJETA: DESTINO
     C*****************************************************************
     C     DESC17        BEGSR
     C                   CLEAR                   GDESCR
     C*-
     C                   Z-ADD     KEYDES        GKEY
     C                   Z-ADD     999           GPAIS
     C                   Z-ADD     AMDSYS        GPURGE
     C                   MOVEL     PREEXP        GNOMES                         -EXPEDIENTE-
     C                   Z-ADD     GTADES        GNUMSO
     C*----------
     C* LINEA-1
     C*----------
     C                   MOVE      *BLANKS       GLI                            -LINEA/1-
     C*-
     C                   MOVEA     DES(3)        GLI(1)                         -LINEA/1-
     C                   MOVEA     DDFAC         GLI(26)                        -LINEA/1-
     C                   MOVEA     '.'           GLI(28)                        -LINEA/1-
     C                   MOVEA     MMFAC         GLI(29)                        -LINEA/1-
     C                   MOVEA     '.'           GLI(31)                        -LINEA/1-
     C                   MOVEA     AAFAC         GLI(32)                        -LINEA/1-
     C                   MOVEA     NAG25         GLI(35)                        -LINEA/1-
     C*-
     C                   MOVEA     GLI           GLIN1                          -LINEA/1-
     C*-----------
     C* LINEA-2
     C*-----------
     C                   MOVE      *BLANKS       GLI                            -LINEA/2-
     C*-
     C                   SELECT                                                 ------------
     C     PCOVEN        WHENEQ    '1'                                          **PAQUETE**
     C                   Z-ADD     600           GACTIN                         -ACT.INTER.
     C                   MOVEA     DES(2)        GLI(1)                         -TEXTO
     C                   MOVEA     NAUTOR        GLI(25)                        -Nº.AUTORIZ.
     C                   MOVEA     INIREF        GLI(34)                        -EXPTE.AG.
     C                   MOVEA     EXPEDI        GLI(42)                        -Nº.EXPEDIEN
     C     PCOVEN        WHENEQ    '2'                                          **LLAA**
     C                   Z-ADD     500           GACTIN                         -ACT.INTER.
     C                   MOVEL     PNUCRU        GISOMA                         -Nº.BILLETE
     C                   MOVEA     'BILLETE'     GLI(1)                         -TEXTO
     C                   MOVEA     PIDCIA        GLI(9)                         -CIA ALFABET
     C                   MOVEA     NBILLE        GLI(11)                        -Nº.BILLETE
     C                   MOVEA     INIREF        GLI(34)                        -EXPTE.AG.
     C                   MOVEA     EXPEDI        GLI(42)                        -EXPEDIENTE
     C     PCOVEN        WHENEQ    '3'                                          **RENFE**
     C                   Z-ADD     630           GACTIN                         -ACT.INTER.
     C                   MOVEA     DES(1)        GLI(1)                         -TEXTO
     C                   MOVEA     NAUTOR        GLI(25)                        -Nº.AUTORIZ.
     C                   MOVEA     INIREF        GLI(34)                        -EXPTE.AG.
     C                   MOVEA     EXPEDI        GLI(42)                        -Nº.EXPEDIEN
     C                   ENDSL                                                  ------------
     C*-
     C                   MOVEA     GLI           GLIN2                          -LINEA/2-
     C*-----------
     C* LINEA-3
     C*-----------
     C                   MOVE      *BLANKS       GLI                            -LINEA/3-
     C*-
     C     PNOMPA        IFNE      *BLANKS                                      -LINEA/3-
     C                   MOVEA     PNOMPA        GLI(1)                         -LINEA/3-
     C                   MOVEA     GLI           GLIN3                          -LINEA/3-
     C                   ENDIF                                                  -LINEA/3-
     C*-----------
     C                   WRITE     GDESCR                                       **DESCRFAC**
     C                   ENDSR
     C*****************************************************************
     C**        CREAR REGISTRO DE OPAGECO A OPAGECO17
     C**  TARJETA / REFERENCIA / AAAAMM
     C*****************************************************************
      /Free
         BEGSR OPAGE17;

            CHAIN (GNUREF:GTAORI) OPAGCOW;

            IF %FOUND;
              ONUREF = KEYDES;
              ONREAL = PNUREA;
              OFAMCO = *ZEROS;
              OIMPOR = PIMPOR;
             WRITE OPAGC17;
             LEAVESR;
            ENDIF;

            IF NOT %FOUND;

               CHAIN (GNUREF:GTAORI) OPAGCOB;

                 IF %FOUND;
                   ONUREF = KEYDES;
                   ONREAL = PNUREA;
                   OFAMCO = *ZEROS;
                   OIMPOR = PIMPOR;
                 WRITE OPAGC17;
                 LEAVESR;
                 ENDIF;

                IF NOT %FOUND;

                 FCONSU = %DEC(%DATE(GFECON:*EUR):*ISO);

                 CHAIN (GTAORI:GIMPOR:FCONSU:GNUCRU) OPAGCHI;

                 IF %FOUND;
                   ONUREF = KEYDES;
                   ONREAL = PNUREA;
                   OFAMCO = *ZEROS;
                   OIMPOR = PIMPOR;
                  WRITE OPAGC17;
                  LEAVESR;
                 ENDIF;

                ENDIF;

            ENDIF;


         ENDSR;


      /End-Free

     C*****************************************************************
     C**          (SUBRUTINA)  ASIENTOS  CONTABLES  -ASIFILE-        **
     C*****************************************************************
      *C     ASIC17        BEGSR
     C*------------------------------------------
     C* TRASPASOS, TARJETA DESTINO -SI- CONCILIA
     C*------------------------------------------
      *C     TOTRSC        IFNE      0
      *C                   Z-ADD     *DATE         CFECON
      *C                   Z-ADD     359           CCODIG                     -TSO.FACT.BO
      *C                   MOVE      *BLANKS       CCONCE
      *C                   MOVE      '1'           CMONED                     -EN EUROS
      *C                   Z-ADD     TOTRSC        CIMPOR             13      -CTMOS.EURO
      *C  N13              MOVE      'D'           CDEHA
      *C  N13              MOVEL     '40030'       CCTAMA
      *C  N13              EXCEPT    APUNTE                                   **ASIFILE**
      *C  N13              MOVE      'H'           CDEHA
      *C  N13              MOVEL     '4325 '       CCTAMA
      *C  N13              EXCEPT    APUNTE                                   **ASIFILE**
      *C   13              MULT      -1            CIMPOR
      *C   13              MOVE      'D'           CDEHA
      *C   13              MOVEL     '4325 '       CCTAMA
      *C   13              EXCEPT    APUNTE                                   **ASIFILE**
      *C   13              MOVE      'H'           CDEHA
      *C   13              MOVEL     '40030'       CCTAMA
      *C   13              EXCEPT    APUNTE                                   **ASIFILE**
      *C                   ENDIF
     C*------------------------------------------
     C* TRASPASOS, TARJETA DESTINO -NO- CONCILIA
     C*------------------------------------------
      *C     TOTRNC        IFNE      0
      *C                   Z-ADD     *DATE         CFECON
      *C                   Z-ADD     359           CCODIG                      -TSO.FACT.BO
      *C                   MOVE      *BLANKS       CCONCE
      *C                   MOVE      '1'           CMONED                      -EN EUROS
      *C                   Z-ADD     TOTRNC        CIMPOR              13      -CTMOS.EURO
      *C  N13              MOVE      'D'           CDEHA
      *C  N13              MOVEL     '40030'       CCTAMA
      *C  N13              EXCEPT    APUNTE                                    **ASIFILE**
      *C  N13              MOVE      'H'           CDEHA
      *C  N13              MOVEL     '4321 '       CCTAMA
      *C  N13              EXCEPT    APUNTE                                    **ASIFILE**
      *C   13              MULT      -1            CIMPOR
      *C   13              MOVE      'D'           CDEHA
      *C   13              MOVEL     '4321 '       CCTAMA
      *C   13              EXCEPT    APUNTE                                    **ASIFILE**
      *C   13              MOVE      'H'           CDEHA
      *C   13              MOVEL     '40030'       CCTAMA
      *C   13              EXCEPT    APUNTE                                    **ASIFILE**
      *C                   ENDIF
     C*------------------------------------------
      *C                   ENDSR
     C*****************************************************************
     C**  (SUBRUTINA)  LINEAS PARA FICHERO "TOTALES" -TOTASAX-       **
     C*****************************************************************
     C     TOTC17        BEGSR
     C*--
     C     TOBABP        IFNE      0                                            --------------
     C                   Z-ADD     TOBABP        PTSTOT           13 0          -BOLSA AGENCIA
     C     PTSTOT        MULT      -1            PTSTOT                         -BOLSA AGENCIA
     C                   Z-ADD     UDATE         FECHA6            6 0          -BOLSA AGENCIA
     C*-
     C                   CALL      'ACUTOTN'                                    -BOLSA AGENCIA
     C                   PARM      'PTEPRE'      CLATOT            6            -BOLSA AGENCIA
     C                   PARM      MSG(1)        TEXTO            30            -BOLSA AGENCIA
     C                   PARM                    PTSTOT                         -BOLSA AGENCIA
     C                   PARM                    FECHA6                         -BOLSA AGENCIA
     C*-
     C                   CALL      'ACUTOTN'                                    -BOL.PROVEEDOR
     C                   PARM      'PAGE00'      CLATOT            6            -BOL.PROVEEDOR
     C                   PARM      MSG(1)        TEXTO            30            -BOL.PROVEEDOR
     C                   PARM                    PTSTOT                         -BOL.PROVEEDOR
     C                   PARM                    FECHA6                         -BOL.PROVEEDOR
     C                   ENDIF                                                  ---------------
     C*--
     C                   ENDSR
     C*****************************************************************
     C**               INICIALIZACION DEL PROGRAMA                   **
     C*****************************************************************
     C     *INZSR        BEGSR
     C                   TIME                    TIMSYS
      /Free
       AMDSYS = %DEC(%DATE(FECSYS:*EUR):*ISO);
      /End-Free
     C                   Z-ADD     99            LIN               3 0
     C                   MOVEL     HORSYS        APROVI
     C                   MOVEL     HORSYS        CPROVI
     C*----------------------------------
     C*-- EVIDENCIA DEPART. CONTABILIDAD
     C*----------------------------------
     C                   CALL      'ASBUNU'                                     -Nº. APUNTE
     C                   PARM                    AÑOSYS_ALF2                    -Nº. APUNTE
     C                   PARM                    MESSYS_ALF                     -Nº. APUNTE
     C                   PARM                    CAPUNT                         -Nº. APUNTE
     C                   MOVEL     CAPUNT        AAPUNT

     C                   ENDSR

     O*----------------------------------------------------------------
     O*--      EVIDENCIA PARA "DEPARTAMENTO DE CONTABILIDAD"         --
     O*----------------------------------------------------------------
     OCABE10    E            TOT
     O                                           24 'TRASPASO FACTURACION DE '
     O                                           30 'BOLSAS'
     O                       *DATE         Y     49
     O                       AAPUNT              56
     O                       AMDSYS              64
     O                                           72 '00000000'
     O                       APROVI              78
     ODETE10    E            CAB
     O                                            6 'COBATR'
     O                                           21 'Nº.APUNTE: '
     O                       APUN5               26
     O                                           60 '** CONCILIACION CUENTAS '
     O                                           72 'DE VIAJES **'
     O                                          128 'PAGINA'
     O                       PAGE          Z    132
     O                       AEVIDE             157
     O          E            CAB
     O                       AEVIDE             157
     O          E            CAB
     O                                           40 'TRASPASO OPERACIONES DE:'
     O                                           64 ' PENDIENTE      A: BOLSA'
     O                                           80 ' PROVEEDORES EL '
     O                       *DATE         Y     90
     O                       AEVIDE             157
     O          E            CAB
     O                                           40 '------------------------'
     O                                           64 '------------------------'
     O                                           88 '------------------------'
     O                                           90 '--'
     O                       AEVIDE             157
     O          E            CAB
     O                       AEVIDE             157
     O          E            CAB
     O                                           41 ' TARJETA '
     O                                          121 'FEC.ENTRA.'
     O                                          132 ' TARJETA '
     O                       AEVIDE             157
     O          E            CAB
     O                                           24 '      AGENCIA (FACTURADO'
     O                                           30 'RA)   '
     O                                           41 ' ORIGEN  '
     O                                           56 '   IMPORTE   '
     O                                           70 ' EXPEDIENTE '
     O                                           82 'FE.CONSUMO'
     O                                           99 'NUM.BILL./AUTOR'
     O                                          109 'TIP.OPE.'
     O                                          121 'FEC.FACTU.'
     O                                          132 ' DESTINO '
     O                       AEVIDE             157
     O          E            CAB
     O                                           24 '------------------------'
     O                                           30 '------'
     O                                           41 '---------'
     O                                           56 '-------------'
     O                                           70 '------------'
     O                                           82 '----------'
     O                                           99 '---------------'
     O                                          109 '--------'
     O                                          121 '----------'
     O                                          132 '---------'
     O                       AEVIDE             157
     O          E            DET
     O                       FNOAGE              30
     O                       PNUREA              41 '    -    '
     O                       PIMPOR              56 ' .   . 0 ,  -'
     O                       EXPEDI              70
     O                       PFCONS        Y     82
     O                       PNUCRU              99
     O                       PSERVI             109
     O                       PDICON             113
     O                                          114 '.'
     O                       PMACON             121 '  .    '
     O                       PTARDE             132 '    -    '
     O                       AEVIDE             157
     O*--
     O          E            TOT
     O                                           56 '--------------'
     O                       AEVIDE             157
     O          E            TOT
     O                                           42 'TOTAL **EUR**'
     O                       TOBABP              56 '     .   . 0 ,  -'
     O                       AEVIDE             157
     O          E            TOT
     O                                           56 '--------------'
     O                       AEVIDE             157
     O          E            TOT
     O                       AEVIDE             157
     O          E            TOT
     O                       AEVIDE             157
     O          E            TOT
     O                                           42 'TRASPASADO -SI- CONCILIA'
     O                       TOTRSC              56 '  .   . 0 ,  -'
     O                       AEVIDE             157
     O          E            TOT
     O                       AEVIDE             157
     O          E            TOT
     O                                           42 'TRASPASADO -NO- CONCILIA'
     O                       TOTRNC              56 '  .   . 0 ,  -'
     O                       AEVIDE             157
     O*----------------------------------------------------------------
     O*--               A  S  I  E  N  T  O  S                       --
     O*----------------------------------------------------------------
     OASICOC17  E            APUNTE
     O                       DSCONT             101
     O*----------------------------------------------------------------

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
      //-----------------------------------------------------------------
      // Acumula_importe
      //-----------------------------------------------------------------
      dcl-proc Genera_Contabilidad;
        dcl-pi *n;
        end-pi;

        CONTABSRV_Genera_Contabilidad_Totales_Producto(
          Acumulador      // Arreglo de Totales por Producto
          :WInd           // Indice de registros Grabados en el Arreglo
          :WCodContab     // Indice Contable: 5 Para este proceso
          :WApunte        // NUmero de Apunte
          :fecproces      // Fecha del asiento DDMMAAAA
          :PNOMASI        // Nombre Fichero Parcial ASIFILEn
          );

      end-proc;         
**
BILLETE RENFE NUM. AUT.
PAQUETE AGEN. NUM. AUT.
RETROCESO OPE.FACTURADA:
**
TRASPASO FACT.DE BOLSAS COBATR
