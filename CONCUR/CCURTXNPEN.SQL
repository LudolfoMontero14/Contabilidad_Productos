-- -------------------------------------------------------
-- ** CONCUR / Operaciones del TRABSAC para procesar
-- Creado por: Ludolfo Montero
-- Fecha: Noviembre 2.025
-- Notas:
--    *
-- -------------------------------------------------------

DROP TABLE IF EXISTS FICHEROS.CONCUR_Transacciones_Pendientes_Procesar;
CREATE TABLE FICHEROS.CONCUR_Transacciones_Pendientes_Procesar FOR SYSTEM NAME CCURTXNPEN ( 
  ID_TRANS_PEN INTEGER GENERATED ALWAYS AS IDENTITY ( 
  START WITH 1 INCREMENT BY 1 
  NO MINVALUE NO MAXVALUE 
  NO CYCLE NO ORDER 
  CACHE 20 ) 
  ,  
  ID_TRANSAC INTEGER NOT NULL DEFAULT 0 , 
  Estatus char( 1) NOT NULL DEFAULT '' ,
     -- ' ' Pendiente de Procesar
     -- 'P' Procesado

  Fecha_Generacion TimeStamp NOT NULL DEFAULT Current Timestamp , 
  Usuario_Generacion CHAR(10) CCSID 284 NOT NULL DEFAULT '', 
  Fecha_Update TimeStamp NOT NULL DEFAULT Current Timestamp , 
  Usuario_Update CHAR(10) CCSID 284 NOT NULL DEFAULT '' ,
	PRIMARY KEY( ID_TRANS_PEN ) 
  )   
    
  RCDFMT RCCURTXNPE   ; 
  
LABEL ON TABLE FICHEROS.CONCUR_Transacciones_Pendientes_Procesar 
  IS 'CONCUR: Operaciones TRANSAC Pendiente Procesar' ; 
  
LABEL ON COLUMN FICHEROS.CONCUR_Transacciones_Pendientes_Procesar 
( 
  ID_TRANS_PEN IS 'ID Control Operaciones Env.' , 
  ID_TRANSAC   IS 'Tipo de Operacion ' , 
  Estatus      IS 'Estatus del Registro' ,

  Fecha_Generacion IS 'Fecha y Hora de Generacion' , 
  Usuario_Generacion IS 'Usuario Generacion' , 
	Fecha_Update IS 'Fecha y Hora de Actualizacion' , 
  Usuario_Update IS 'Usuario de Actualizacion' 
 ) ; 
  
LABEL ON COLUMN FICHEROS.CONCUR_Transacciones_Pendientes_Procesar 
( 
   ID_TRANS_PEN TEXT IS 'ID Control Operaciones Env.' , 
  ID_TRANSAC   TEXT IS 'Tipo de Operacion ' , 
  Estatus      TEXT IS 'Estatus del Registro' ,

  Fecha_Generacion TEXT IS 'Fecha y Hora de Generacion' , 
  Usuario_Generacion TEXT IS 'Usuario Generacion' , 
	Fecha_Update TEXT IS 'Fecha y Hora de Actualizacion' , 
  Usuario_Update TEXT IS 'Usuario de Actualizacion'   ) ;

-- Activacion de Journal
CL:STRJRNPF FILE(FICHEROS/CCURTXNPEN) JRN(FICHEROS/JOURNAL) IMAGES(*BOTH); 

