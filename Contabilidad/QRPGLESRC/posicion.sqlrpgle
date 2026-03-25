     H NOMAIN
     H DECEDIT('0,')    DATEDIT(*DMY/)  ALWNULL(*USRCTL)
     H* AUT(*ALL)        OPTIMIZE(*FULL) OPTION(*NOXREF: *NOUNREF)
     H AUT(*ALL)       OPTION(*NOXREF: *NOUNREF)
     H FIXNBR(*INPUTPACKED) INDENT('|')
     H BNDDIR('QC2LE')
     H COPYRIGHT('(C) Copyright Diners Club Español 2009')
      *******************************************************
      *    POSICION EXACTA DEL SOCIO
      *******************************************************
      *Modificado Por: Jose Daniel Martin Perez       12/12/2023
      * MASTERCARD - Se modifica la composicion del AKEYAUT
      *******************************************************
      * AUTORIZA OPERACIONES MIT: Solo se consideraran las operaciones
      * con 5 dias  a la fecha del sistema           21-02-2024
      *******************************************************
      *Compilar:
      *  CRTSQLRPGI OBJ(EXPLOTA/POSICION) SRCFILE(EXPLOTA/QRPGLESRC)
      *  OBJTYPE(*MODULE) RPGPPOPT(*LVL2) DATFMT(*JOB) TIMFMT(*HMS)
      *  DBGVIEW(*SOURCE) COMMIT(*NONE)
      *
      *  CRTSRVPGM SRVPGM(EXPLOTA/POSICION) MODULE(EXPLOTA/POSICION)
      *  EXPORT(*ALL)
      *
      *******************************************************
     FSUB40ELIFMCF   E             WORKSTN USROPN SFILE(DETUSU:LINUSU)
     FAPARLG7   IF   E           K DISK    USROPN
      *FMDIFELOG  IF   E           K DISK    USROPN
     FPAPRE     IF   E           K DISK    USROPN EXTDESC('FICHEROS/PA')
     F                                            RENAME(PPA:PPAPRE)
     FGRANELG5  IF   E           K DISK    USROPN
     FANEPENLG  IF   E           K DISK    USROPN
     FPA        IF   E           K DISK    USROPN EXTFILE(LABELPA)
     FFA        IF   E           K DISK    USROPN EXTFILE(LABELFA)
     FBORECLG1  IF   E           K DISK    USROPN
     FANEXDIN   IF   E             DISK    USROPN
     FFDEVMAG   IF   F  176        DISK    USROPN
     FAUTORIZA  IF   E           K DISK    USROPN
     FBOLISOL1  IF   E           K DISK    USROPN
     FLIMDIS    UF   E           K DISK    USROPN
     FCTLPROCES UF   E           K DISK    USROPN

     DOPERDIAN         PR                  EXTPGM('OPERDIAN')
     D                               10

     DOPERDIAI         PR                  EXTPGM('OPERDIAI')
     D                               10

     DVERPOSI          PR
     D                                8  0

     DNMOVDIA          PR

     DIMOVDIA          PR

     DNADADIA          PR                                                       Libre

     DGOCMD            PR            10I 0 EXTPROC('system')
     D                                 *   VALUE OPTIONS(*STRING)

     D AKEYAUT         S             14  0
     D pantoken        S             14    inz
     D ERR_GOCMD       S              7    IMPORT('_EXCP_MSGID')                Variable de GOCMD
     D FECHA_SYS       S               D   DATFMT(*EUR)
     D FECHA_ISO       S               D   DATFMT(*ISO)
     D LABELPA         S             10
     D LABELFA         S             10
     D LENRCV          S              9B 0 INZ(266)
     D LINUSU          S              5  0
     D PRIUSU          S              3U 0 INZ(1)
     D RETORNO         S             10I 0
     D TEX             S             27    DIM(14) CTDATA PERRCD(1)
     D TOTPOS          S              9  0
     D X               S              3U 0

     D                 DS                  INZ
     D AKEY                    1     14  0
     D AREAL                   3     10  0
      *                     -----------------------
     D FLIBR6                 15     23
     D FPENOFA                19     23P 0
      *                     -----------------------
     D ATOREG                 24    323
     D ATOREG_NS              26     33  0
     D ATOREG_IMP             38     46  0

     DGUARDA           DS                  INZ
     D XGUAR                   1     60P 0 DIM(12)

      /COPY EXPLOTA/QRPGLESRC,DSPOSICION

      /COPY PRICE/QRPGLESRC,ERRDS

      /COPY QSYSINC/QRPGLESRC,QUSRMBRD

      /COPY EXPLOTA/QRPGLESRC,DSTIMSYS

     IFDEVMAG   NS
     I                                 21   28  FDEVNUM
     I                                 89   98 0FDEVIMP

     IREGBOL
     I              NUREAL                      NUREAL_SINUSO


     *                                      
     * LECTURA DE TODOS LOS FICHEROS        
     *                                      

     PPOSICION         B                   EXPORT

     DPOSICION         PI            60
     D WNUREAL                        8  0
     D FICHERO                        2  0 VALUE

     D ADEUDO          C                   CONST('0456789JKLMW')
     D ABONO           C                   CONST('123ABCD')
     D ERROR_FA        S               N
     D ERROR_PA        S               N
     D ERROR_DIFE      S               N
     D NUREAL_ALF      S              8
     D SIESTA          S               N
     D WTOTANXI        S               N

     D Marca           S              2  0 INZ

     D Fecha_Oper      S               D   DATFMT(*ISO)
     D Fecha_4dia      S               D   DATFMT(*ISO)
     D Es_Mit          S              5  0 INZ
     D WTOT_ANX        S             11  2 INZ

     C                   TIME                    TIMSYS

      /Free

         CLEAR POSICI;

       // ENGAÑO Y FIN  

         IF WNUREAL= 88888888;
         RETURN POSICI;
         ENDIF;

         IF WNUREAL= 99999999;
         CLOSE *ALL;
         *INLR = *ON;
         RETURN POSICI;
         ENDIF;

       // CARGO CAMPOS  

         NUREAL_ALF = %EDITC(WNUREAL:'X');

       // SUMO ABONOS DEL PENROJO   

       IF FICHERO = 01 OR FICHERO = 99;

        EXEC SQL
          SET :XPENROJO = COALESCE((SELECT SUM(RIMPOR)
          FROM FICHEROS/PENROJO
          WHERE SUBSTR(RNUMSO, 3, 8) = :NUREAL_ALF AND RFECFA = 0), 0);               
     
       ENDIF;

       // SUMO APARCADAS            

       IF FICHERO = 02 OR FICHERO = 99;

          IF NOT %OPEN(APARLG7);
          OPEN APARLG7;
          ENDIF;

          SETLL NUREAL_ALF VNMOV;

          DOW '1';
          READ VNMOV;

            IF %EOF OR VNS8 <> NUREAL_ALF;
            LEAVE;
            ENDIF;

          XAPARCA += VIMPOR;
          ENDDO;

       ENDIF;

       // SUMO CUENTA RESERVA       

       IF FICHERO = 03 OR FICHERO = 99;
       OBJNME =  'MDIFE     FICHEROS  ';
       ERROR_DIFE = *OFF;
       EXSR EXISTE;

         IF SIESTA;
         MONITOR;

        //  IF NOT %OPEN(MDIFELOG);
        //  OPEN MDIFELOG;
        //  ENDIF;

        //  SETLL WNUREAL MDIFEW;

        //     DOW '1';
        //     READ MDIFEW;

        //       IF %EOF OR NUREAL <> WNUREAL;
        //       LEAVE;
        //       ENDIF;

        //     XRESERVA += DIMVIV;
        //     ENDDO;

        //  CLOSE MDIFELOG;

         ON-ERROR;
         ERROR_DIFE = *ON;
         ENDMON;
         ENDIF;

       ENDIF;

       // SUMO NMOV DEL DIA         

       IF FICHERO = 04 OR FICHERO = 99;

          EXEC SQL
          SET :XNMOV = COALESCE((SELECT SUM(VIMPOR)
          FROM FICHEROS/NMOVDIA
          WHERE SUBSTR(DIGITS(VNUSO), 3, 8) = :NUREAL_ALF OR
                SUBSTR(VTARJE, 3, 8) = :NUREAL_ALF), 0);

       ENDIF;

       // SUMO IMOV DEL DIA         

       IF FICHERO = 05 OR FICHERO = 99;

          EXEC SQL
          SET :XIMOV = COALESCE((SELECT SUM(DEC(SUBSTR(WCPO37, 17, 8)))
          FROM FICHEROS/IMOVDIA
          WHERE SUBSTR(WCPO37, 3, 8) = :NUREAL_ALF), 0);

       ENDIF;

       // SUMO OPERACIONES EN PAPRE (MISMO TOTAL DEL PA)        

       IF FICHERO = 08 OR FICHERO = 99;
       OBJNME =  'PAPRE     FICHEROS  ';
       EXSR EXISTE;

          IF SIESTA;
          OPEN PAPRE;
          SETLL WNUREAL PPAPRE;

            DOW '1';
            READ PPAPRE;

            IF %EOF OR PNUREA <> WNUREAL;
            LEAVE;
            ENDIF;

             IF %SCAN(PCR:ADEUDO) > 0;
             XPA += PIMPOR;
             ENDIF;

             IF %SCAN(PCR:ABONO) > 0;
             XPA -= PIMPOR;
             ENDIF;

            ENDDO;

          CLOSE PAPRE;
          ENDIF;

       ENDIF;

       // SUMO ANEXOS DE HOY (CAJA) 

       IF FICHERO = 07 OR FICHERO = 99;

          IF NOT %OPEN(GRANELG5);
          OPEN GRANELG5;
          ENDIF;

          SETLL NUREAL_ALF GRANEW;

          DOW '1';
          READ GRANEW;

            IF %EOF OR GNS8D <> NUREAL_ALF;
            LEAVE;
            ENDIF;

          IF GIMDET > 0;
          XANEXOS -= GIMDET;
          ELSE;
          XANEXOS += (GIMDET * -1);
          ENDIF;

          ENDDO;

       // SUMO ANEXOS DE HOY        

          IF NOT %OPEN(ANEPENLG);
          OPEN ANEPENLG;
          ENDIF;

          SETLL NUREAL_ALF PENW;

          DOW '1';
          READ PENW;

            IF %EOF OR PNS8A <> NUREAL_ALF;
            LEAVE;
            ENDIF;

          IF PFEREC = 0;

            IF %SCAN(PCOREG:ADEUDO) > 0;
            XANEXOS += PIMPTS;
            ENDIF;

            IF %SCAN(PCOREG:ABONO) > 0;
            XANEXOS -= PIMPTS;
            ENDIF;

          ENDIF;

          ENDDO;

       ENDIF;

       // SUMO OPERACIONES EN PA (MISMO TOTAL QUE PAPRE)        

       IF FICHERO = 08 OR FICHERO = 99;
        OBJNME   =  'PAFSCREA  FICHEROS  ';
        ERROR_PA = *OFF;
        LABELPA  = 'PA';
        EXSR EXISTE;

        IF SIESTA;
          LABELPA = 'PAFSCREA';
        ENDIF;

        MONITOR;

          IF NOT %OPEN(PA);
            OPEN PA;
          ENDIF;

          SETLL WNUREAL PPA;
          DOW '1';
            READ PPA;
            IF %EOF OR PNUREA <> WNUREAL;
              LEAVE;
            ENDIF;

            IF %SCAN(PCR:ADEUDO) > 0;
              XPA += PIMPOR;
            ENDIF;

            IF %SCAN(PCR:ABONO) > 0;
              XPA -= PIMPOR;
            ENDIF;

          ENDDO;

          CLOSE PA;

        ON-ERROR;
          ERROR_PA = *ON;
        ENDMON;

       ENDIF;

       // SUMO OPERACIONES EN FA    
       IF FICHERO = 09 OR FICHERO = 99;
        OBJNME   =  'FAFSCREA  FICHEROS  ';
        ERROR_FA = *OFF;
        LABELFA  = 'FA';
        EXSR EXISTE;

        IF SIESTA;
          LABELFA = 'FAFSCREA';
        ENDIF;

        MONITOR;

          IF NOT %OPEN(FA);
            OPEN FA;
          ENDIF;

          SETLL WNUREAL FFA;

          DOW '1';
          READ FFA;

            IF %EOF OR FNUREA <> WNUREAL;
              LEAVE;
            ENDIF;

            IF %SCAN(FCR:ADEUDO) > 0;
              XFA += FPTS;

              IF FCR = '0';
                XFA += FPENOFA;
              ENDIF;

            ENDIF;

            IF %SCAN(FCR:ABONO) > 0;
              XFA -= FPTS;
            ENDIF;

          ENDDO;

          CLOSE FA;

        ON-ERROR;
          ERROR_FA = *ON;
        ENDMON;

       ENDIF;

       // Sumo movmientos Pendientes en Anexos (ANXSOLANX)
       IF FICHERO = 09 OR FICHERO = 99;
          
          // Adeudo gastos de demora. (ID=1) SUMA
          // ABONO-PAGOS POR TRANSFERENCIAS. (ID=2)RESTA 
          // Abonar gastos de demora. (ID=3) RESTA
          // Abono cuotas. (ID=4) RESTA

        Exec Sql
          // SELECT COALESCE(SUM(IMPORTE*100), 0) 
          // Into :WTOT_ANX
          // From ANXSOLANX
          // WHERE 
          //   NUREAL = :WNUREAL
          //   AND ID_ANEXO = 2
          //   AND ESTATUS = 'P';    
          SELECT 
            Sum(Case
              When b.Tipo_Anexo = 'A' Then (IMPORTE*100) * -1
              Else Importe * 100
              End) Importe_Signo
          Into :WTOT_ANX
          From ANXSOLANX a
              Inner Join ANX_CATALOGO_ANEXOS b
                  On (a.ID_ANEXO = b.ID_ANEXO)
          WHERE 
              a.ESTATUS = 'P'
              and a.NUREAL = :WNUREAL;  

        If Sqlcode <> 0;
          WTOT_ANX = 0;  
        EndIf;
        XANEXOS += WTOT_ANX;  

       EndIf;
       //*************************************

       // SUMO RECIBOS NO VENCIDOS  

       IF FICHERO = 10 OR FICHERO = 99;

          IF NOT %OPEN(BORECLG1);
          OPEN BORECLG1;
          ENDIF;

          FECHA_SYS = %DATE(FECSYS:*EUR);
          SETLL NUREAL_ALF RECIW;

          DOW '1';
          READ RECIW;

            IF %EOF OR RNS8A <> NUREAL_ALF;
            LEAVE;
            ENDIF;

          FECHA_ISO = %DATE(RVENTO:*ISO);

          IF FECHA_ISO >= FECHA_SYS;
          XRECIBOS += RPTS;
          ENDIF;

          ENDDO;

       //----------------------------
       // ANEXDIN (RECIBOS RETIRADOS)
       //----------------------------

          OBJNME =  'ANEXDIN   FICHEROS  ';
          EXSR EXISTE;

          IF SIESTA;
          OPEN ANEXDIN;

            DOW '1';
            READ(E) ANEXW;

            IF %EOF OR %ERROR;
            LEAVE;
            ENDIF;

            IF ATISOE = 1 AND ANUGPO = 04 AND ANUANE = 001 AND
               ATOREG_NS = WNUREAL;
            XRECIBOS -= ATOREG_IMP;
            ENDIF;

            ENDDO;

          CLOSE ANEXDIN;
          ENDIF;

       ENDIF;

       // SUMO DEVOLUCIONES DEL DIA 

       IF FICHERO = 11 OR FICHERO = 99;
       OBJNME =  'FDEVMAG   FICHEROS  ';
       EXSR EXISTE;

         IF SIESTA;
         OPEN FDEVMAG;

           DOW '1';
           READ(E) FDEVMAG;

             IF %EOF OR %ERROR;
             LEAVE;
             ENDIF;

             IF FDEVNUM = NUREAL_ALF;
             XDEVMAG += FDEVIMP;
             ENDIF;

           ENDDO;

         CLOSE FDEVMAG;
         ENDIF;

       ENDIF;

       // SUMO OPERACIONES DEL AUTORIZA 

       IF FICHERO = 12 OR FICHERO = 99;
          //AKEYAUT = (36 * 1000000000000) + (WNUREAL* 10000);


         Exec Sql
            SET :pantoken = EXPLOTA.OBTENER_PANTOKEN_DEL_NUREAL(:WNUREAL);
            IF Pantoken <> *blanks;
               AKEYAUT= %int(%subst(pantoken:1:10)+'0000');
            Else;
               AKEYAUT = (36 * 1000000000000) + (WNUREAL* 10000);
           Endif;

          IF NOT %OPEN(AUTORIZA);
          OPEN AUTORIZA;
          ENDIF;

          SETLL AKEYAUT AUTORIZW;

          DOW '1';
          READ AUTORIZW;

             //Recuperamos la marca de la tarjeta
             // 1 = Diners,  2=  Mastercard
             Exec Sql
             SET :Marca = EXPLOTA.OBTENER_MARCA_DEL_BIN
                       (EXPLOTA.OBTENER_BIN_DEL_PAN(:ANUMTA));


            IF %EOF OR AREAL <> WNUREAL;
            LEAVE;
            ENDIF;

            // Para las operaciones mit solo consideramos aquellas
            // con menos de 5 dias a la fecha del sistema

              Exec Sql
                Set :Fecha_oper =
                     DATE(To_Date(SUBSTR(:Afhcaj, 1, 6), 'YYMMDD'));

             Exec Sql
               Set :fecha_4dia  = CURRENT DATE - 4 DAY;

             Exec Sql
               Set :Es_Mit  = LOCATE('MIT', :Aobser);

            IF  Fecha_oper < fecha_4dia AND ES_MIT > 0 ;
                ITER;
            Endif;


            IF ADIAS = 99 OR ATIDAT = '1' AND MARCA <> 2;                     // Antigua o cargo en
            ITER;
            ENDIF;

            IF %SCAN('/VF-':AOBSER:1) > 0;                     // Preautorizacion cruzada
            ITER;
            ENDIF;

            IF AWSENT = 'CI' AND ADIAS9 = 0 OR                 // Llame al Diners
               AWSENT = 'FD' AND ADIAS9 = 0 OR
               AWSENT = 'R6' AND ADIAS9 = 0 OR
               AWSENT = 'PR' AND ADIAS9 = 0 AND AACTI <> 99 OR
               AWSENT = '4B' AND ADIAS9 = 0 AND AACTI <> 99;
            ITER;
            ENDIF;

            IF AWSENT = 'PR' AND ACLDNI = 2 OR                 // Cajeros facturados
               AWSENT = '4B' AND ACLDNI = 2;                   // Cajeros facturados
            ITER;
            ENDIF;

            IF ACOREC <> 'A' AND ACOREC <> 'I' AND
               ACOREC <> 'B' AND ACOREC <> 'C';
            ITER;
            ENDIF;

          XAUTORIZA += (AIMPMO * 100);
          ENDDO;

       ENDIF;

       // SUMO OPERACIONES DEL BOLINGSO 

       IF 1 = 2;   // No se tienen en cuenta porque se compensan con un cargo al 80209

       IF FICHERO = 06 OR FICHERO = 99;

       IF NOT %OPEN(BOLISOL1);
       OPEN BOLISOL1;
       ENDIF;

       FECHA_SYS = %DATE(FECSYS:*EUR);
       SETLL WNUREAL REGBOL;

         DOW '1';
         READ REGBOL;

           IF %EOF OR TARSOC <> WNUREAL;
           LEAVE;
           ENDIF;

         FECHA_ISO = %DATE(VCMTO:*ISO);

         IF FECHA_ISO >= FECHA_SYS;
         XPAPRE -= IMPING;
         ENDIF;

         ENDDO;

       ENDIF;

       ENDIF;

       // ACTUALIZACION DEL LIMDIS Y FIN 

         IF NOT %OPEN(LIMDIS);
         OPEN LIMDIS;
         ENDIF;

         GUARDA = POSICI;
         CHAIN WNUREAL XLIMDI;

         IF %FOUND;

         IF ERROR_PA;        // Mantiene dato
         XGUAR(8) = XPA;
         ENDIF;

         IF ERROR_FA;        // Mantiene dato
         XGUAR(9) = XFA;
         ENDIF;

         IF ERROR_DIFE;      // Mantiene dato
         XGUAR(3) = XRESERVA;
         ENDIF;

         IF FICHERO = 99;
          POSICI = GUARDA;
          XDISPO = (%XFOOT(XPOSI) / 100);
          XSALFA = ((XFA + XDEVMAG + XANEXOS) / 100);
          UPDATE XLIMDI;
          RETURN POSICI;
         ENDIF;

          SELECT;
            WHEN FICHERO = 01;
              XPENROJO = XGUAR(1);
            WHEN FICHERO = 02;
              XAPARCA  = XGUAR(2);
            WHEN FICHERO = 03;
              XRESERVA = XGUAR(3);
            WHEN FICHERO = 04;
              XNMOV    = XGUAR(4);
            WHEN FICHERO = 05;
              XIMOV    = XGUAR(5);
            WHEN FICHERO = 06;
              XPAPRE   = XGUAR(6);
            WHEN FICHERO = 07;
              XANEXOS  = XGUAR(7);
            WHEN FICHERO = 08;
              XPA      = XGUAR(8);
            WHEN FICHERO = 09;
              XFA      = XGUAR(9);
            WHEN FICHERO = 10;
              XRECIBOS = XGUAR(10);
            WHEN FICHERO = 11;
              XDEVMAG  = XGUAR(11);
            WHEN FICHERO = 12;
              XAUTORIZA= XGUAR(12);
          ENDSL;
          XDISPO = (%XFOOT(XPOSI) / 100);
          XSALFA = ((XFA + XDEVMAG + XANEXOS) / 100);
          UPDATE XLIMDI;
          ENDIF;

         POSICI = GUARDA;
         CLOSE PA;
         CLOSE FA;
         UNLOCK LIMDIS;
         RETURN POSICI;

       //********************************************
       //  VER SI EXISTE UN FICHERO
       //********************************************

       BEGSR EXISTE;
       ERR_IDMSG = *BLANKS;
       SIESTA = *ON;

      /End-Free
     C                   CALL      'QUSRMBRD'
     C                   PARM                    QUSM0200
     C                   PARM                    LENRCV
     C                   PARM      'MBRD0200'    FMTNAM           10
     C                   PARM                    OBJNME           20
     C                   PARM      '*FIRST  '    QUSMN03
     C                   PARM      '0'           OVRPRC            1
     C                   PARM                    ERROR

      /Free

       IF ERR_IDMSG = 'CPF9801' OR ERR_IDMSG = 'CPF9812' OR           // No esta
          ERR_IDMSG = 'CPF3C20';                                      // Esta alocatado
       SIESTA = *OFF;
       ENDIF;

       ENDSR;

       //********************************************
       //  ERRORES EN PROGRAMA
       //********************************************

       BEGSR *PSSR;
       RETURN POSICI;
       ENDSR;

      /End-Free

     PPOSICION         E

     *                                      
     * VER POSICION EXACTA DEL SOCIO        
     *                                      

     PVERPOSI          B                   EXPORT

     DVERPOSI          PI
     D WNUREAL                        8  0

     D CPO60           S             60

      /Free

       // ENGAÑO Y FIN  

        IF WNUREAL= 88888888;
        TXTPIE = 'F1=Fin  F3=Refrescar';

        IF NOT %OPEN(SUB40ELIFM);
        OPEN SUB40ELIFM;
        ENDIF;

        WRITE ENGAÑO;
        RETURN;
        ENDIF;

        IF WNUREAL= 99999999;
        CLOSE SUB40ELIFM;
        *INLR = *ON;
        RETURN;
        ENDIF;

       // BUSCAR LIMDIS 

        IF NOT %OPEN(LIMDIS);
        OPEN LIMDIS;
        ENDIF;

        TXTCAB = 'Posicion del socio: ' + %EDITW(WNUREAL:'    -    ');
        CPO60 = POSICION(WNUREAL:99);
        *IN77 = *ON;

        DOW '1';
        CHAIN(N) WNUREAL XLIMDI;

        IF NOT %FOUND;
        RETURN;
        ENDIF;

        LINUSU = 0;
        X = 0;
        *IN93 = *ON;
        WRITE CTLUSU;
        *IN93 = *OFF;

       // CARGAR SUBFICHERO 

           FOR X = 1 TO 12;

              IF XPOSI(X) <> 0;
              LINUSU += 1;
              TXTDAT = TEX(X) + %EDITW(XPOSI(X):' .   . 0 ,  -');
              WRITE DETUSU;
              ENDIF;

           ENDFOR;

         LINUSU += 1;
         TXTDAT = TEX(13) + '_____________';
         WRITE DETUSU;

         TOTPOS = %XFOOT(XPOSI);

         LINUSU += 1;
         TXTDAT = TEX(14) + %EDITW(TOTPOS:' .   . 0 ,  -');
         WRITE DETUSU;

       // SALIDA SUBFICHERO 

        *IN92 = *ON;
        DOW '1';
        EXFMT CTLUSU;

          IF *IN01;
          LEAVE;
          ENDIF;

          IF *IN03;
          CPO60 = POSICION(WNUREAL:99);
          LEAVE;
          ENDIF;

        ENDDO;
        *IN92 = *OFF;
         WRITE ENGAÑO;

         IF *IN01;
         LEAVE;
         ENDIF;

        ENDDO;

        RETURN;
        CLOSE LIMDIS;

      /End-Free

     PVERPOSI          E

     *                                      
     * ADICIONAR NMOV AL NMOVDIA            
     *                                      

     PNMOVDIA          B                   EXPORT

     DNMOVDIA          PI

     D                 DS                  INZ
     D LABEL                   1     10
     D NMOV                    1      4    INZ('NMOV')
     D ORDEN                   5      6S 0

      /Free

       OPEN CTLPROCES;
       CHAIN 029 CTLREG;
       ORDEN = CTL021;     // Desde

       DOW '1';
       ORDEN += 1;

       RETORNO = GOCMD('CPYF FROMFILE(FICHEROS/' + %TRIM(LABEL) +
       ') TOFILE(FICHEROS/NMOVDIA) MBROPT(*ADD) FROMRCD(1)' +
       ' INCREL((*IF VCODRE *EQ ''7'') (*AND VPAIS *EQ 999)) FMTOPT(*NOCHK)');

       IF RETORNO = 1;
       LEAVE;

          IF ERR_GOCMD = 'CPF3142';   // Objeto no encontrado
          ENDIF;

       ENDIF;

       OPERDIAN(LABEL);
       ENDDO;

       CTL021 = (ORDEN - 1);
       UPDATE CTLREG;
       CLOSE CTLPROCES;

      /End-Free

     PNMOVDIA          E

     *                                      
     * ADICIONAR IMOV AL IMOVDIA            
     *                                      

     PIMOVDIA          B                   EXPORT

     DIMOVDIA          PI

     D                 DS                  INZ
     D LABEL                   1     10
     D IMOV                    1      4    INZ('IMOV')
     D ORDEN                   5      6S 0

      /Free

       OPEN CTLPROCES;
       CHAIN 029 CTLREG;
       ORDEN = CTL022;     // Desde

       DOW '1';
       ORDEN += 1;

       RETORNO = GOCMD('CPYF FROMFILE(FICHEROS/' + %TRIM(LABEL) +
       ') TOFILE(FICHEROS/IMOVDIA) MBROPT(*ADD) FROMRCD(1)' +
       ' INCREL((*IF VCODRE *EQ ''7'')) FMTOPT(*NOCHK)');

       IF RETORNO = 1;
       LEAVE;
       ENDIF;

       OPERDIAI(LABEL);
       ENDDO;

       CTL022 = (ORDEN - 1);
       UPDATE CTLREG;
       CLOSE CTLPROCES;

      /End-Free

     PIMOVDIA          E

     *                                      
     * PROCEDIMIENTO LIBRE                  
     *                                      

     PNADADIA          B                   EXPORT
     PNADADIA          E
**
Abonos sin procesar
Operaciones aparcadas
Cuenta reserva pendiente
Nacional de hoy
Internacional de hoy
Transferencias pendientes
Anexos del dia
PA acumulado
FA acumulado
Recibos no vencidos
Devoluciones hoy
Autorizaciones

                 TOTAL