**Free
  ctl-opt option(*srcstmt : *nodebugio : *noexpdds)
          datedit(*DMY/) decedit('0,')
          bnddir('UTILITIES/UTILITIES':'CONTBNDDIR')
          dftactgrp(*no) actgrp(*new) main(main);
  //****************************************************************
  // -- CREA EN -BORECI- RECIBOS MC DE LA FACTURACION DE SOCIOS   **
  //                                                              **
  //****************************************************************

  //------------------------------------------------------------
  // Copys
  //------------------------------------------------------------
  /Define Funciones_CONTABSRV
  /Define Estructuras_Asientos_Evidencias
  /define Common_Variables
  /Include EXPLOTA/QRPGLESRC,CONTABSRVH       // Utilidades contabilidad

  /COPY EXPLOTA/QRPGLESRC,DSNUMSOCI
  /copy UTILITIES/QRPGLESRC,PSDSCP      // psds
  /Include UTILITIES/QRPGLESRC,SQLDIAGNCP  // Errores diagnostico SQL

  //------------------------------------------------------------
  // Prototipos
  //------------------------------------------------------------
  dcl-pr VIRTA3 extPgm('VIRTA3');
    *N      Packed(8:0);
    *N      Packed(9:0);
    *N      Packed(3:0);
    *N      Packed(1:0);
    *N      Char(10) Dim(99);
    *N      Char(10) Dim(99);
    *N      Packed(8:0) Dim(99);
    *N      Packed(8:0) Dim(99);
  end-pr;

  dcl-pr ACUTOTN extPgm('ACUTOTN');
    *N      Char(6);
    *N      Char(30);
    *N      Packed(13:0);
    *N      Packed( 6:0);
  end-pr;
  //------------------------------------------------------------
  // Declaraciones de variables
  //------------------------------------------------------------
  Dcl-S IPN          Packed(8:0) DIM(99);  //IMP.PZOS.VIRTUALES
  Dcl-S IP           Char(10)    DIM(99);  //IMP.PZOS.VIRTUALES
  Dcl-S PL           Char(10)    DIM(99);  //FEC.PZOS.VIRTUALES
  Dcl-S PLN          Packed(8:0) DIM(99);  //FEC.PZOS.VIRTUALES
  Dcl-S VE           Packed(8:0) DIM(100); //EVI.CONTABLE
  Dcl-S IV           Packed(9:0) DIM(100); //EVI.CONTABLE
  Dcl-S NR           Packed(8:0) DIM(4);   //EVI.CONTABLE
  Dcl-S IR           Packed(9:0) DIM(4);   //EVI.CONTABLE
  Dcl-S VT           Packed(8:0) DIM(4);   //EVI.CONTABLE

  Dcl-S fechaSistema Timestamp;
  Dcl-s WInd         Zoned(3);
  Dcl-s WApunte      Char(6);
  Dcl-s WCRFS01      Char(96);
  Dcl-s PAIS         Char(1);
  Dcl-s KEYBCO       Zoned(4:0);
  Dcl-s TOTREC       Packed(13:0);
  Dcl-s CC           Zoned(3:0);
  Dcl-s I            Zoned(3:0);
  Dcl-s Euros        Zoned(9:2);
  Dcl-s CLATOT       Char(6);
  Dcl-s TEXTO        Char(30);
  Dcl-s FECSYS       packed(6:0);
  Dcl-s WCodContab   Zoned(5) Inz(4); //Id_Asiento 4 CEREFSN
  dcl-s VIRPER       Packed(3:0);
  Dcl-s MsgError     VarChar(5000) Inz;
  Dcl-s v_tipo_error Char(3) Inz('PGM');
  Dcl-s WRPTS        Packed(9:0);
  Dcl-s WSCODPR      Zoned(3);
  Dcl-s WSCOBHA      Char(1);
  Dcl-s WSBCHRE      Zoned(4);
  Dcl-s WNumBco      Zoned(4);
  Dcl-s WEstado      Char(1);
  Dcl-s WNomProd     Char(30);
  Dcl-s WCod_Prod    Zoned(3);
  Dcl-s FECPRO       Packed(8);
  Dcl-s fecproces    Zoned(8);
  Dcl-s PTSPZO       Packed(9);
  Dcl-s PZOS         Zoned(3);
  Dcl-s WIS_Virtual  Ind;
  Dcl-s WRVIRPL      Packed(1);
  Dcl-s A_SNUSO1     packed(2);
  Dcl-s A_NUREAL     packed(8);
  Dcl-s A_SNUSO2     packed(4);
  Dcl-s WNomAsiPar Char(10);
  Dcl-s WNomCabpar Char(10);
  Dcl-s WNomDetPar Char(10);

  //------------------------------------------------------------
  // Declaraciones de Constantes
  //------------------------------------------------------------
  Dcl-C EURO1            CONST(166,386);
  Dcl-C ESCUD1           CONST(200,482);
  //------------------------------------------------------------
  // Estructuras
  //------------------------------------------------------------
  Dcl-Ds  DS_RECIBOS Qualified Inz;
    Seq       Zoned(15:0);
    TipoTarj  Char(1);
    RNUMSO    Zoned(14:0);
    RNOMSO    Char(35);
    RNOMBA    Char(25);
    RDIRBA    Char(35);
    RLOCBA    Char(35);
    RZONBA    Zoned(4:0);
    RNUMCC    Char(13);
    RNOMCC    Char(25);
    RPTS      Zoned(9:0);
    RLIBR1    Char(3);
    RLIBR2    Char(2);
    RLIBR5    Char(1);
    RFECRE    Zoned(8:0);
    RNUMBC    Zoned(5:0);
    RLIBR3    Char(1);
    RREGEM    Zoned(6:0);
    RLIBR4    Char(4);
    RACCRE    Char(1);
    RNUSUC    Zoned(4:0);
    RLIBR6    Char(1);
    RVTORE    Zoned(8:0);
    RDIAPR    Zoned(2:0);
    RVIRPE    Zoned(2:0);
    RVIRPL    Zoned(1:0);
    REUROS    Packed(9:0);
    RTITEU    Zoned(10:0);
    RELIM1    Char(1);
    Socio     Zoned(8:0);
  End-Ds;

  // BACKUP REG. DEL BORECI
  Dcl-DS DS_REBOIN  Qualified Inz;
    RNUMSO        Zoned(14:0);
    RNUMCC         Char(13);
    RNOMCC         Char(25);
    RPTS         Packed(9:0);
    RFECRE        Zoned(8:0);
    RNUMBC       Packed(5:0);
    RNUSUC        Zoned(4:0);
    RVENTO        Zoned(8:0);
    RFECEN        Zoned(8:0);
    RCOMPR        Zoned(5:0);
    RREPRE         Char(1);
    RESTAD         Char(1);
    REUROS       Packed(9:0);
    RESCUD       Packed(9:0);
    RBCORE        Zoned(4:0);
    RTRBRE         Char(1);
    RNREEM        Zoned(6:0);
    RSAUNA        Zoned(8:0);
  End-Ds;

  Dcl-DS DS_AUNARTA  Qualified;
    ATARMAT    Zoned(8);
    ATARINT    Zoned(8);
    AITCIFD    Char(1);
    ACIFSOC    Char(20);
    ANUMSOC    Char(20);
    ANOMSOC    Char(30);
    ANUMBCO    Zoned(4);
    ANUMSUC    Zoned(4);
    ADIGCON    Char(2);
    ANUMCUE    Char(13);
    ANOMCUE    Char(25);
    AREFREC    Zoned(2);
    AFEALTA    Zoned(8);
    AFEBAJA    Zoned(8);
    ATMATRI    Zoned(8);
    ABANCUE    Char(25);
    AIBANUE    Char(34);
  End-Ds;

  Dcl-DS *N;
    AEVIDE         Char(25)   Pos(1);
    NUMLIN         Zoned(5:0) Pos(1) INZ(0);
    APUNTE         Char(6)    Pos(6);
    AMDSYS         Zoned(8:0) Pos(12);
    APROVI         Zoned(6:0) Pos(20);
  End-DS;

  // Array / Matriz que totaliza importes por productos
  dcl-ds Acumulador likeds(AcumuladorTpl) Dim(100) Inz;
  //------------------------------------------------------------
  // Declaraciones de Cursores
  //------------------------------------------------------------
  Exec sql
    Set Option Commit=*None, CloSQLCsr=*EndMod, Datfmt=*dmy,
    Decmpt =*comma;

  Exec Sql declare C_Recibos Cursor For
    Select
      rrn(a), a.*,
      dec(SubString(Digits(a.RNUMSO), 3, 8), 8, 0) as Socio
    From (
      Select
        'D' as TT, RNUMSO, RNOMSO, RNOMBA, RDIRBA, RLOCBA, RZONBA,
        RNUMCC, RNOMCC, RPTS, RLIBR1, RLIBR2, RLIBR5,
        RFECRE, RNUMBC, RLIBR3, RREGEM, RLIBR4, RACCRE,
        RNUSUC, RLIBR6, RVTORE, RDIAPR, RVIRPE, RVIRPL,
        REUROS, RTITEU, RELIM1
      From Recibos
      Union all
      Select
        'M' as TT, RNUMSO, RNOMSO, RNOMBA, RDIRBA, RLOCBA, RZONBA,
        RNUMCC, RNOMCC, RPTS, RLIBR1, RLIBR2, RLIBR5,
        RFECRE, RNUMBC, RLIBR3, RREGEM, RLIBR4, RACCRE,
        RNUSUC, RLIBR6, RVTORE, RDIAPR, RVIRPE, RVIRPL,
        REUROS, RTITEU, RELIM1
        From recibosMC ) a
    Order by RNUMSO
  ;
  //*****************************************************************
  // Main (inicio)
  //*****************************************************************
  dcl-proc main;

    dcl-pi *n;
      P_NonProc     Char(10);
      P_NomAsiPar   Char(10);
      P_NomCabpar   Char(10);
      P_NomDetPar   Char(10);
      P_NumApunte   Char( 6);
    end-pi;
    
    WNomAsiPar = P_NomAsiPar;
    WNomCabpar = P_NomCabpar;
    WNomDetPar = P_NomDetPar;
    
    InicializarDatos();

    Exec Sql
      Select CRFS01
        Into :WCRFS01
      From CRFS01;

    Monitor;
      fecproces = %Dec(%SubSt(WCRFS01:50:8):8:0);
    on-error;
      fecproces = %Dec(%date():*EUR);
    endmon;

    fecproces = %dec(%char(%date(fechaSistema):*eur0):8:0);
    if not Crear_Temporal_Detalle_Evidencia(dsDetevi);
      //leave;
    endif;


    Reset Acumulador;
    //*   LECTURA DE RECIBOS   **
    Exec Sql Open C_Recibos;
    Exec Sql Fetch From C_Recibos into :DS_RECIBOS;
    dow sqlStt = '00000';

      Reset DS_REBOIN;
      TOTREC += DS_RECIBOS.RPTS;
      If Not Proces();
        Diagnostico(jobname:MsgError:V_tipo_error);
      EndIf;

      Exec Sql Fetch From C_Recibos into :DS_RECIBOS;
    EndDo;
    Exec Sql Close C_Recibos;

    If TOTREC > 0;
      CONTABSRV_Genera_Contabilidad_Totales_Producto(
                Acumulador      // Arreglo de Totales por Producto
                :WInd           // Indice de registros Grabados en el Arreglo
                :WCodContab      // Indice Contable: 4 Para este proceso
                :WApunte        // NUmero de Apunte
                :fecproces       // Fecha del asiento DDMMAAAA
                :WNomAsiPar     // Nombre Fichero Parcial ASIFILEn
                  );

      Inserta_Totales_Evi();

      Grabar_Temporal_A_Detevi(dsDetevi);
      Guardar_Cabecera_Evidencia(dsDetevi);

      // Actualiza Total BORECI
      CLATOT   = 'BORECI';
      TEXTO    = 'ACUMULACION FAC.SOC DI/MC';
      FECSYS   = UDATE;
      ACUTOTN(CLATOT:TEXTO:TOTREC:FECSYS);

      P_NumApunte = WApunte;   // Para devolver el numero de Apunte por paramatro
    Endif;

    *InLR = *On;

  end-proc;

  //****************************************************************
  // SUBRUTINA ACUMULACION AL BORECI
  //****************************************************************
  dcl-proc PROCES;

    dcl-pi *n ind;
    end-pi;

    MsgError = '';

    //---------------
    Exec SQL
      Select SCOBHA, SBCHRE, SCODPR
      Into :WSCOBHA, :WSBCHRE, :WSCODPR
      From T_MSOCIO
      Where NUREAL = :DS_RECIBOS.Socio;

    if Sqlcode = 100;
      MsgError = 'RECIBO ' + %Editc(DS_RECIBOS.RNUMSO:'X') +
                  ' No existe en T_MSOCIO';
    Endif;

    If Sqlcode < 0;
      observacionSql = 'Error en lectura del T_MSOCIO';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;

    //--------------------------
    // OMISION TARJETAS CAIXA
    //--------------------------
    If WSCOBHA = 'X';
      TOTREC = TOTREC - DS_RECIBOS.RPTS;
      MsgError = 'RECIBO ' + %Editc(DS_RECIBOS.RNUMSO:'X') +
        ' No se toma en cuenta porque es de CAIXA';
      Return *Off;
    Endif;

    Pais = 'E';

    //---------------
    // CHAIN INDEBCO
    //---------------
    Exec SQL
      Select Numero, ESTADO
      Into :WNumBco, :WESTADO
      From INDEBCO
      Where
        NUMERO = :DS_RECIBOS.RNUMBC
        AND IDENTI = :Pais;

    If Sqlcode < 0;
      observacionSql = 'Error en lectura del INDEBCO';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;

    // No encuentra Banco registrado
    if Sqlcode = 100;

      If WSCOBHA = 'Z' And WSBCHRE > 0;
        DS_RECIBOS.RNUMBC = 49;
        DS_RECIBOS.RNUSUC = WSBCHRE;

        If DS_RECIBOS.TipoTarj = 'D';
          Exec Sql
            Update Recibos a  Set
              RNUMBC = 49,
              RNUSUC = :WSBCHRE
            Where
              rrn(a) = :DS_RECIBOS.Seq;

          If Sqlcode < 0;
            observacionSql = 'Error en UPDATE al RECIBOS';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
          EndIf;

          If Nivel_Alerta = 'HI';
            *InH1 = *On;
            *InLR = *On;
          EndIf;

        Else;
          Exec Sql
            Update RecibosMC a  Set
              RNUMBC = 49,
              RNUSUC = :WSBCHRE
            Where
              rrn(a) = :DS_RECIBOS.Seq;

          If Sqlcode < 0;
            observacionSql = 'Error en UPDATE al RECIBOSMC';
            Clear Nivel_Alerta;
            Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
          EndIf;

          If Nivel_Alerta = 'HI';
            *InH1 = *On;
            *InLR = *On;
          EndIf;
        EndIf;

        // Se vuelve a verificar con el Nuevo codigo de Banco
        Exec SQL
          Select Numero, ESTADO
          Into :WNumBco, :WESTADO
          From INDEBCO
          Where
            NUMERO = :DS_RECIBOS.RNUMBC
            AND IDENTI = :Pais;

        if Sqlcode = 100;
          MsgError = 'RECIBO ' + %Editc(DS_RECIBOS.RNUMSO:'X') +
                  ' No existe el codigo de banco ' +
                  %Editc(DS_RECIBOS.RNUMBC:'X');
          return *off;
        Endif;

        If Sqlcode < 0;
          observacionSql = 'Error en lectura del INDEBCO';
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
        EndIf;

        If Nivel_Alerta = 'HI';
          *InH1 = *On;
          *InLR = *On;
        EndIf;

      EndIf;

    Endif;

    //--------------------------
    // RECIBO SIN VTO. -AVISO-
    //--------------------------
    If DS_RECIBOS.RVTORE = 0;
      MsgError = 'RECIBO ' + %Editc(DS_RECIBOS.RNUMSO:'X') +
                ' SIN Vencimiento';
      // Exec SQL
      //   INSERT INTO FICHEROS/LOG_CEREFSN
      //   VALUES(current timestamp, :MsgError);
      return *off;
    Endif;

    DS_REBOIN.RNUMSO = DS_RECIBOS.RNUMSO;
    DS_REBOIN.RPTS   = DS_RECIBOS.RPTS;
    DS_REBOIN.RNUMCC = DS_RECIBOS.RNUMCC;
    DS_REBOIN.RNOMCC = DS_RECIBOS.RNOMCC;
    DS_REBOIN.RNUMBC = DS_RECIBOS.RNUMBC;
    DS_REBOIN.RNUSUC = DS_RECIBOS.RNUSUC;
    DS_REBOIN.RESTAD = WESTADO;
    DS_REBOIN.RREPRE = '0';
    DS_REBOIN.RFECRE = %dec(%char(%date():*eur0):8:0); //FECHA PROCESO -DDMMAAAA-
    DS_REBOIN.RFECRE = *date;
    //-----------------
    // FECHA VTO.RECIBO
    //-----------------
    // RVENTO (AAAAMMDD) = RVTORE (DDMMAAAA)
    DS_REBOIN.RVENTO = %DEC( %CHAR( %DATE(%EDITC(DS_RECIBOS.RVTORE:'X') :
     *EUR0) : *ISO0 ) : 8 : 0 );

    // Se acumula totales por Producto
    If Not Acumula_importe(DS_RECIBOS.RPTS/100:WSCODPR);
      MsgError = 'RECIBO ' + %Editc(DS_RECIBOS.RNUMSO:'X') +
                 ' ERROR CODIGO PRODUCTO '       +
                 %Editc(WSCODPR:'X');
      return *off;
    EndIf;

    //   SOLUCION -AUNA-
    Exec SQL
      Select
        ATARMAT,ATARINT,AITCIFD,ACIFSOC,
        ANUMSOC,ANOMSOC,ANUMBCO,ANUMSUC,
        ADIGCON,ANUMCUE,ANOMCUE,AREFREC,
        AFEALTA,AFEBAJA,ATMATRI,ABANCUE,
        AIBANUE
      Into :DS_AUNARTA
      From AUNARTA
      Where
        ATARINT = :DS_RECIBOS.Socio;

    If Sqlcode < 0;
      observacionSql = 'Error en lectura del INDEBCO';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;

    Select;
      When SqlCode = 0;
        //---------------
        Exec SQL
          Select SNUSO1, NUREAL, SNUSO2
          Into :A_SNUSO1, :A_NUREAL, :A_SNUSO2
          From T_MSOCIO
          Where NUREAL = :DS_AUNARTA.ATARMAT;

        if Sqlcode = 100;
          MsgError = 'RECIBO ' + %Editc(DS_RECIBOS.RNUMSO:'X') +
                      ' Tarjeta AUNA No existe en T_MSOCIO';
          // Exec SQL
          //   INSERT INTO FICHEROS/LOG_CEREFSN
          //   VALUES(current timestamp, :MsgError);
          return *off;
        Endif;

        If Sqlcode < 0;
          observacionSql = 'Error en lectura del T_MSOCIO de AUNA';
          Clear Nivel_Alerta;
          Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
        EndIf;

        If Nivel_Alerta = 'HI';
          *InH1 = *On;
          *InLR = *On;
        EndIf;

        SNUSO1 = A_SNUSO1;
        NUREAL = A_NUREAL;
        SNUSO2 = A_SNUSO2;
        DS_REBOIN.RSAUNA = DS_RECIBOS.Socio;
        DS_REBOIN.RNUMCC = DS_AUNARTA.ANUMCUE;
        DS_REBOIN.RNOMCC = DS_AUNARTA.ANOMCUE;
        DS_REBOIN.RNUMBC = DS_AUNARTA.ANUMBCO;
        DS_REBOIN.RNUSUC = DS_AUNARTA.ANUMSUC;
        DS_REBOIN.RNUMSO = MS14_NU;

      When Sqlcode = 100;
        DS_REBOIN.RSAUNA = 0;
    EndSl;

    //-------------------------
    // VTOS TARJ VIRTUALES
    //-------------------------
    WIS_Virtual = *Off;
    If DS_RECIBOS.RVIRPE > 0;
      VIRPER = DS_RECIBOS.RVIRPE * 5;
      If DS_RECIBOS.RVIRPL > 0;
        WIS_Virtual = *On;
        PTSPZO = DS_RECIBOS.RPTS;
        FECPRO = *DATE;
        WRVIRPL = DS_RECIBOS.RVIRPL;
        VIRTA3(FECPRO:PTSPZO:VIRPER:WRVIRPL:IP:PL:IPN:PLN);
        CC = 0;
        PZOS = WRVIRPL;
      Endif;
    Endif;

    If Not WIS_Virtual;
      PZOS = 1;
    Endif;

    //--------------------------
    // GRABO EN BOLSA -BORECI-
    //--------------------------
    For  I = 1 to PZOS;
      If WIS_Virtual;
        CC += 1;
        DS_REBOIN.RPTS  = IPN(CC);
        DS_REBOIN.RVENTO = PLN(CC);
      Endif;
      DS_REBOIN.RESCUD = 0;
      DS_REBOIN.REUROS = 0;
      EUROS  = DS_RECIBOS.RPTS/100;

      EVAL(H) DS_REBOIN.REUROS = EUROS * EURO1; //-PESETAS-

      If PAIS = 'P';
        EVAL(H) DS_REBOIN.RESCUD = EUROS * ESCUD1; //-ESCUDOS-
      ENDIF;

      //--------------------------
      DS_REBOIN.RNREEM = DS_RECIBOS.RREGEM; //-Nº.REGISTRO EMPRESA

      If Not Insert_reg_Boreci();
        Return *Off;
      EndIf;

    EndFor;

    // Evidencia Contable - Detalle
    Inserta_Detalle_Evi();

    Return *on;

  end-proc;
  // -----------------------------------------------------------------------------
  // Insert Registro en el BORECI
  // -----------------------------------------------------------------------------
  dcl-proc Insert_reg_Boreci;

    dcl-pi *n Ind;
    end-pi;

    Exec Sql
      INSERT INTO BORECI
      (
        RNUMSO, RNUMCC, RNOMCC, RPTS, RFECRE, RNUMBC, RNUSUC,
        RVENTO, RFECEN, RCOMPR, RREPRE, RESTAD, REUROS, RESCUD,
        RBCORE, RTRBRE, RNREEM, RSAUNA
      )
    VALUES (:DS_REBOIN);

    If Sqlcode < 0;
      observacionSql = 'Error al insertar en el BORECI';
      Clear Nivel_Alerta;
      Nivel_Alerta = Diagnostico(PROCEDURENAME:observacionSql);
      Return *Off;
    EndIf;

    If Nivel_Alerta = 'HI';
      *InH1 = *On;
      *InLR = *On;
    EndIf;
    Return *On;
  end-proc;
  //-----------------------------------------------------------------------------
  // Inicializamos datos
  //-----------------------------------------------------------------------------
  dcl-proc InicializarDatos;

    // inicializamos Array / Matriz
    Reset Acumulador;

    fechaSistema = %timestamp();
    WApunte = CONTABSRV_Asignar_Numero_Apunte(fechaSistema);
    fechaSistema = fechaSistema -  %days(1);

    // Guardamos datos fijos de dsDetevi.
    // Luego creamos el fichero temporal de detalle y metemos la cabecera del detalle.
    dsDetevi.numeroApunte = WApunte;
    dsDetevi.fechaConciliacion = %dec(%date(fechaSistema):*ISO);
    dsDetevi.numeroEvidencia = %editc(%dec(%time():*HMS):'X');

  end-proc;
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
  //---------------------------------------------------------------
  // Crear el fichero temporal del detalle de la evidencia
  //---------------------------------------------------------------
  dcl-proc Crear_Temporal_Detalle_Evidencia;

    dcl-pi *n ind;
      dsDetevi likeds(dsDeteviTempl);
    end-pi;

    dcl-s marca char(1) inz(CREAR_TEMPORAL);

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'CEREFSN: Error al crear temporal de Evidencias';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return *off;
    endif;

    Inserta_Cabecera_detalle();

    return *on;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Detalle de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Detalle_Evi;

    dcl-s marca char(1);
    dcl-s WImpdec Zoned(9:2);
    dcl-ds dsDetalleEvi Qualified;
      Esp01      Char(1);
      Socio     Zoned(8);
      Esp02      Char(2);
      Tarjeta  Zoned(14);
      Esp03      Char(2);
      NomSoc   Char(35);
      Esp04     Char(2);
      Importe   Char(14);
      Esp05     CHAR(2);
      CodBco   Zoned(4);
      Esp06     Char(2);
      FecVto   Char(10);
      Esp07     Char(2);
      CodPro   Zoned(4);
    End-ds;

    marca = GRABAR_TEMPORAL;

    dsDetalleEvi.Socio   = DS_RECIBOS.Socio;
    dsDetalleEvi.tarjeta = DS_RECIBOS.RNUMSO;
    dsDetalleEvi.NomSoc  = DS_RECIBOS.RNOMSO;
    WImpdec = DS_RECIBOS.RPTS/100;
    dsDetalleEvi.Importe = %Editc(WImpdec:'J');
    dsDetalleEvi.CodBco  = DS_RECIBOS.RNUMBC;

    dsDetalleEvi.FecVto  =
          %SubSt(%Editc(DS_RECIBOS.RVTORE:'X'):1:2) + '-' +
          %SubSt(%Editc(DS_RECIBOS.RVTORE:'X'):3:2) + '-' +
          %SubSt(%Editc(DS_RECIBOS.RVTORE:'X'):5:4);
    dsDetalleEvi.CodPro  = WSCODPR;

    dsDetevi.lineaTexto = dsDetalleEvi;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'CEREFSN: Error al registro de Evidencia en el temporal';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      Return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Inserta registro de Cabecera en el Detalle
  //-----------------------------------------------------------------
  dcl-proc Inserta_Cabecera_detalle;

    dcl-s marca char(1);
    Dcl-s I         Zoned(3);

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto =
      'CEREFSN EVIDENCIA CONTABLE FACT. AL ' +
      %SubSt(%Editc(fecproces:'X'):1:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):3:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):5:4);
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'CEREFSN: Error al registro de Evidencia Inserta_Cabecera_detalle';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      ' NUM REAL  TARJETA         NOMBRE SOCIO' +
      '                              IMPORTE  ' +
      ' BANCO   FEC.VCTO   PROD';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'CEREFSN: Error al registro de Evidencia Inserta_Cabecera_detalle';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      '---------------------------------------------'+
      '---------------------------------------------------------';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'CEREFSN: Error al registro de Evidencia Inserta_Cabecera_detalle';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

  end-proc;
  //-----------------------------------------------------------------
  // Genera Inserta Totales de Evidencia Contable
  //-----------------------------------------------------------------
  dcl-proc Inserta_Totales_Evi;

    dcl-s marca char(1);
    Dcl-s I         Zoned(3);

    marca = GRABAR_TEMPORAL;

    dsDetevi.lineaTexto = '';
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
        marca
        :dsDetevi
        :sqlError
        :sqlMensaje
        :WNomDetPar);
      V_observacion = 'CEREFSN: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      'Codigo Producto'             +
      '                           ' +
      '         Total' ;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
        marca
        :dsDetevi
        :sqlError
        :sqlMensaje
        :WNomDetPar);
      V_observacion = 'CEREFSN: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    dsDetevi.lineaTexto =
      '------------------------------------' +
      '    '                                 +
      '         ------------' ;
    numeroLinea += 1;
    dsDetevi.numeroLinea = numeroLinea;
    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
        marca
        :dsDetevi
        :sqlError
        :sqlMensaje
        :WNomDetPar);
      V_observacion = 'CEREFSN: Error al registro de Evidencia Inserta_Totales_Evi';
      Diagnostico(jobname:V_observacion:V_tipo_error);
      return;
    EndIf;

    // Ordenamiento del Arreglo por Codigo de Producto
    sorta %subarr(Acumulador(*).Cod_prod : 1 : WInd);

    For I=1 to WInd;

      WCod_Prod = Acumulador(I).Cod_prod;
      Exec SQL
        Select NOMBRE_PRODUCTO
          Into :WNomProd
        From Productos
        Where
          CODIGO_PRODUCTO=:WCod_Prod;
      If Sqlcode<>0;
          WNomProd = 'Producto No Definido';
      EndIf;

      dsDetevi.lineaTexto =
        %Editc(Acumulador(I).Cod_prod:'X') +
        ' - ' + WNomProd + '    '    +
        %Editc(
          %Dec(Acumulador(I).Total:16:2)
        :'2');
      WnumLinea += 1;
      dsDetevi.numeroLinea = numeroLinea;

      if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
        marca
        :dsDetevi
        :sqlError
        :sqlMensaje
        :WNomDetPar);
        V_observacion = 'CEREFSN: Error al registro de Evidencia Inserta_Totales_Evi';
        Diagnostico(jobname:V_observacion:V_tipo_error);
        Leave;
      EndIf;
    EndFor;

  end-proc;
  //-----------------------------------------------------------------------------
  // Guardar fichero temporal a DETEVI
  //-----------------------------------------------------------------------------
  dcl-proc Grabar_Temporal_A_Detevi;

    dcl-pi *n;
      dsDetevi likeDs(dsDeteviTempl);
    end-pi;

    dcl-s marca char(1) inz(GRABAR_A_FICHERO);

    if not CONTABSRV_Guardar_Evidencias_Contables_Detalle(
          marca
          :dsDetevi
          :sqlError
          :sqlMensaje
          :WNomDetPar);
      V_observacion = 'CEREFSN: Error al grabar temporal en el DETEVI';
      Diagnostico(jobname:V_observacion:V_tipo_error);
    endif;

  end-proc;
  //-----------------------------------------------------------------------------
  // Guardar cabecera evidencia contable
  //-----------------------------------------------------------------------------
  dcl-proc Guardar_Cabecera_Evidencia;

    dcl-pi *n ind;
      dsDetevi likeDs(dsDeteviTempl);
    end-pi;

    dcl-ds dsCabevi likeds(dsCabeviTempl) inz;

    dsCabevi.descripcion =
      'CEREFSN EVIDENCIA CONTABLE FACT. AL ' +
      %SubSt(%Editc(fecproces:'X'):1:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):3:2) + '-' +
      %SubSt(%Editc(fecproces:'X'):5:4);

    dsCabevi.numeroApunte = dsDetevi.numeroApunte;
    dsCabevi.fechaConciliacion = dsDetevi.fechaConciliacion;
    dsCabevi.fechaBaja = 0;
    dsCabevi.pteModificar = *blanks;
    dsCabevi.numeroEvidencia = dsDetevi.numeroEvidencia;

    if not CONTABSRV_Guardar_Evidencias_Contables_Cabecera(
      dsCabevi
      :sqlError
      :sqlMensaje
      :WNomCabpar);
      return *off;
    endif;

    return *on;

  end-proc;
