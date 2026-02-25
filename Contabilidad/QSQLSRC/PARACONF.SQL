-- -------------------------------------------------------
-- ** Tabla de Configuracion de Procesos Contables NEW
-- Creado por: Ludolfo Montero
-- Fecha: Octubre 2025
-- Notas:
--    *
-- -------------------------------------------------------
DROP TABLE IF EXISTS PARALELOC.Paralelo_Config_Process;

CREATE TABLE PARALELOC.Paralelo_Config_Process
    FOR SYSTEM NAME PARACONF (

    ID_PROCESO Char( 10) NOT NULL DEFAULT '' ,
    DESCRIPCION_PROCESO Char(200) NOT NULL DEFAULT '' ,
    FILE_REQUERIDO CHAR(10) NOT NULL DEFAULT '' ,
    FILE_TYPE Char( 1) NOT NULL DEFAULT '' ,
    -- P=Fisico
    -- L=Logico
    File_Lib_Src Char( 10) Not Null Default '',
    File_name_Src Char( 10) Not Null Default '',
    File_Src Char( 10) Not Null Default '',
    File_Lib_Des Char( 10) Not Null Default '',
    File_Data Char(  1)  NOT NULL DEFAULT '' ,
      -- Y=Si
      -- N=No
    ESTATUS       Char(  1)  NOT NULL DEFAULT '' ,
      -- A=Activo
      -- I=Inactivo

    FEC_CREACION TimeStamp  NOT NULL DEFAULT current_timestamp ,
    USUARIO_CREACION Char( 10) NOT NULL DEFAULT '' ,
    FEC_MODIFICACION TimeStamp NOT NULL DEFAULT current_timestamp ,
    USUARIO_MODIFICACION Char( 10) NOT NULL DEFAULT '' ,
    PRIMARY KEY( ID_PROCESO, FILE_REQUERIDO ) )
    RCDFMT RPARACONF  ;

LABEL ON TABLE PARALELOC.Paralelo_Config_Process
    IS 'PAR-Configuracion de Procesos' ;

LABEL ON COLUMN PARALELOC.Paralelo_Config_Process
(
    ID_PROCESO           IS 'Id de Proceso' ,
    DESCRIPCION_PROCESO  IS 'Descripcion del Proceso' ,
    FILE_REQUERIDO       IS 'Nombre File Requerido' ,
    FILE_TYPE            IS 'Tipo de Archivo P/L' ,
    File_Lib_Src         IS 'Libreria Origen Fuente' ,
    File_Name_Src        IS 'Nombre Fuente' ,
    File_Data            IS 'Requiere Data S/N' ,
    ESTATUS              IS 'Estatus' ,

    FEC_CREACION         IS 'Fecha de Creacion',
    USUARIO_CREACION     IS 'Usuario Creacion',
    FEC_MODIFICACION     IS 'Fecha   Modificacion',
    USUARIO_MODIFICACION IS 'Usuario Modificacion'
    ) ;

LABEL ON COLUMN PARALELOC.Paralelo_Config_Process
(
    ID_PROCESO           TEXT IS 'Id de Proceso' ,
    DESCRIPCION_PROCESO  TEXT IS 'Descripcion del Proceso' ,
    FILE_REQUERIDO       TEXT IS 'Nombre File Requerido' ,
    FILE_TYPE            TEXT IS 'Tipo de Archivo P/L' ,
    File_Lib_Src         TEXT IS 'Libreria Origen Fuente' ,
    File_Name_Src        TEXT IS 'Nombre Fuente' ,
    File_Data            TEXT IS 'Requiere Data S/N' ,
    ESTATUS              TEXT IS 'Estatus' ,

    FEC_CREACION         TEXT IS 'Fecha de Creacion',
    USUARIO_CREACION     TEXT IS 'Usuario Creacion',
    FEC_MODIFICACION     TEXT IS 'Fecha   Modificacion',
    USUARIO_MODIFICACION TEXT IS 'Usuario Modificacion'
    ) ;


-- Activacion de Journal
-- STRJRNPF FILE(FICHEROS/PARACONF)
--             JRN(FICHEROS/DIARIO) IMAGES(*BOTH)