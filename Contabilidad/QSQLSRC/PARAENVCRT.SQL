-- -------------------------------------------------------
-- ** Tabla de Control para ambientes/Libreria del paralelo
-- Creado por: Ludolfo Montero
-- Fecha: Enero 2026
-- Notas:
--    *
-- -------------------------------------------------------
DROP TABLE IF EXISTS FICHEROS.Paralelo_Ctl_Env;

CREATE TABLE FICHEROS.Paralelo_Ctl_Env
    FOR SYSTEM NAME PARAENVCRT (

    ID_ENVIROMENT INTEGER GENERATED ALWAYS AS IDENTITY ( 
      START WITH 1 INCREMENT BY 1 
      NO MINVALUE NO MAXVALUE 
      NO CYCLE NO ORDER 
      CACHE 20 ) 
      ,  
    NAME_PROCESS   CHAR( 10) NOT NULL DEFAULT '' ,
    DESCR_PROCESS  Char(100) NOT NULL DEFAULT '' ,

    Date_Create TimeStamp  NOT NULL DEFAULT current_timestamp ,
    User Char( 10) NOT NULL DEFAULT '')
    RCDFMT RPARAENV  ;

LABEL ON TABLE FICHEROS.Paralelo_Ctl_Env
    IS 'PAR-Ctl Process Enviroment' ;

LABEL ON COLUMN FICHEROS.Paralelo_Ctl_Env
(
    ID_ENVIROMENT   IS 'Id Enviroment' ,
    NAME_PROCESS    IS 'Name Process' ,
    DESCR_PROCESS   IS 'Description Process' ,

    Date_Create     IS 'Fecha de Creacion',
    User            IS 'Usuario Creacion'
) ;

LABEL ON COLUMN FICHEROS.Paralelo_Ctl_Env
(
    ID_ENVIROMENT   TEXT IS 'Id Enviroment' ,
    NAME_PROCESS    TEXT IS 'Name Process' ,
    DESCR_PROCESS   TEXT IS 'Description Process' ,

    Date_Create     TEXT IS 'Fecha de Creacion',
    User            TEXT IS 'Usuario Creacion'
    ) ;


-- Activacion de Journal
-- STRJRNPF FILE(FICHEROS/PARAENVCRT)
--             JRN(FICHEROS/DIARIO) IMAGES(*BOTH)