      //===============================================================
      // Función que Registra errores sql
      //===============================================================
       dcl-pr Diagnostico   char(5);
             programa      char(10) const;
             Observacion_sql   varchar(5000)   options(*nopass);
             tipo_error Char(3) Options(*NOPASS);
       end-pr;

       Dcl-Pr Pgm_Grabamos_error Ind;
             P_observacion  Char(1000);
             P_campo        Char(20);
             P_valor        Char(100);
             P_programa     Char(10);
             P_srclin       Char(13);
             P_linea        Char(13);
             P_Time_Stamp   timestamp;
       End-Pr;

       Dcl-Pr SQLDIAGSRV_Pgm_Pila_Llamadas Ind;
           P_Jobnumberalpha    Char(6);
           P_Jobuser          Char(10);
           P_Jobname          Char(10);
           P_Stack_Info       Varchar(200);
       End-Pr;

       Dcl-Pr SQLDIAGSRV_Notifica_Error Ind;
            V_Time_Stamp timestamp Const;
            V_programa   Char(10) Const;
            V_Time_Stamp_fin timestamp Const Options(*NOPASS);
       End-Pr;

       Dcl-Pr SQLDIAGSRV_Notifica_Pgm_Error Ind;
            V_Time_Stamp timestamp Const;
            V_programa   Char(10) Const;
            V_Time_Stamp_fin timestamp Const Options(*Nopass);
       End-Pr;

       Dcl-s Nivel_Alerta    Char(5);
       Dcl-s observacionSql  VarChar(5000);
