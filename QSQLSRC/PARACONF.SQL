-- -------------------------------------------------------
-- ** Tabla de Configuracion de Procesos Contables NEW
-- Creado por: Ludolfo Montero
-- Fecha: Octubre 2025
-- Notas:
--    *
-- -------------------------------------------------------
DROP TABLE IF EXISTS PARALELOC.Paralelo_Cofig_Process;

CREATE TABLE PARALELOC.Paralelo_Cofig_Process
    FOR SYSTEM NAME PARACONF (

    ID_PROCESO Char( 10) NOT NULL DEFAULT '' ,
    DESCRIPCION_PROCESO Char(200) NOT NULL DEFAULT '' ,
    FILE_REQUERIDO CHAR(10) NOT NULL DEFAULT '' ,
    FILE_TYPE Char( 1) NOT NULL DEFAULT '' ,
    -- P=Fisico
    -- L=Logico
    File_Lib_Origen Char( 10) Not Null Default '',
    SI_DATA Char(  1)  NOT NULL DEFAULT '' ,
      -- S=Si
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

LABEL ON TABLE PARALELOC.Paralelo_Cofig_Process
    IS 'PAR-Configuracion de Procesos' ;

LABEL ON COLUMN PARALELOC.Paralelo_Cofig_Process
(
    ID_PROCESO           IS 'Id de Proceso' ,
    DESCRIPCION_PROCESO  IS 'Descripcion del Proceso' ,
    FILE_REQUERIDO       IS 'Nombre File Requerido' ,
    FILE_TYPE            IS 'Tipo de Archivo P/L' ,
    File_Lib_Origen      IS 'Libreria Origen File' ,
    SI_DATA              IS 'Requiere Data S/N' ,
    ESTATUS              IS 'Estatus' ,

    FEC_CREACION         IS 'Fecha de Creacion',
    USUARIO_CREACION     IS 'Usuario Creacion',
    FEC_MODIFICACION     IS 'Fecha   Modificacion',
    USUARIO_MODIFICACION IS 'Usuario Modificacion'
    ) ;

LABEL ON COLUMN PARALELOC.Paralelo_Cofig_Process
(
    ID_PROCESO           TEXT IS 'Id de Proceso' ,
    DESCRIPCION_PROCESO  TEXT IS 'Descripcion del Proceso' ,
    FILE_REQUERIDO       TEXT IS 'Nombre File Requerido' ,
    FILE_TYPE            TEXT IS 'Tipo de Archivo P/L' ,
    File_Lib_Origen      TEXT IS 'Libreria Origen File' ,
    SI_DATA              TEXT IS 'Requiere Data S/N' ,
    ESTATUS              TEXT IS 'Estatus' ,

    FEC_CREACION         TEXT IS 'Fecha de Creacion',
    USUARIO_CREACION     TEXT IS 'Usuario Creacion',
    FEC_MODIFICACION     TEXT IS 'Fecha   Modificacion',
    USUARIO_MODIFICACION TEXT IS 'Usuario Modificacion'
    ) ;


-- Activacion de Journal
-- STRJRNPF FILE(FICHEROS/PARACONF)
--             JRN(FICHEROS/DIARIO) IMAGES(*BOTH)