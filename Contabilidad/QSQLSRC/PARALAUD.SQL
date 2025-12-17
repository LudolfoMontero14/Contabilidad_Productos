-- -------------------------------------------------------
-- ** Tabla Auditoria de Procesos Contables en PARALELO
-- Creado por: Ludolfo Montero
-- Fecha: Octubre 2025
-- Notas:
--    *
-- -------------------------------------------------------
DROP TABLE IF EXISTS PARALELOC.Paralelo_Audit_Process;

CREATE TABLE PARALELOC.Paralelo_Audit_Process
    FOR SYSTEM NAME PARALAUD (

    ID_PROCESO Char( 10) NOT NULL DEFAULT '' ,
    ID_PROC_Ejecutor Char( 10) NOT NULL DEFAULT '' ,
    Num_Apunte CHAR(  6) NOT NULL DEFAULT '' ,
    Nom_Asi_Parcial Char( 10) NOT NULL DEFAULT '' ,
    Nom_Cab_Parcial Char( 10) NOT NULL DEFAULT '' ,
    Nom_Det_Parcial Char( 10) NOT NULL DEFAULT '' ,    

    FEC_CREACION TimeStamp  NOT NULL DEFAULT current_timestamp ,
    USUARIO_CREACION Char( 10) NOT NULL DEFAULT '' )
    RCDFMT RPARALAUD  ;

LABEL ON TABLE PARALELOC.Paralelo_Audit_Process
    IS 'PAR-Configuracion de Procesos' ;

LABEL ON COLUMN PARALELOC.Paralelo_Audit_Process
(
    ID_PROCESO           IS 'Id de Proceso' ,
    ID_PROC_Ejecutor     IS 'Proceso Ejecutor' ,
    Num_Apunte           IS 'Numero de Apunte' ,
    Nom_Asi_Parcial      IS 'Nombre Asifilen Parcial' ,
    Nom_Cab_Parcial      IS 'Nombre Cabevi Parcial' ,
    Nom_Det_Parcial      IS 'Nombre Detevi Parcial' ,

    FEC_CREACION         IS 'Fecha de Creacion',
    USUARIO_CREACION     IS 'Usuario Creacion'
    ) ;

LABEL ON COLUMN PARALELOC.Paralelo_Audit_Process
(
    ID_PROCESO           TEXT IS 'Id de Proceso' ,
    ID_PROC_Ejecutor     TEXT IS 'Proceso Ejecutor' ,
    Num_Apunte           TEXT IS 'Numero de Apunte' ,
    Nom_Asi_Parcial      TEXT IS 'Nombre Asifilen Parcial' ,
    Nom_Cab_Parcial      TEXT IS 'Nombre Cabevi Parcial' ,
    Nom_Det_Parcial      TEXT IS 'Nombre Detevi Parcial' ,

    FEC_CREACION         TEXT IS 'Fecha de Creacion',
    USUARIO_CREACION     TEXT IS 'Usuario Creacion'
    ) ;


-- Activacion de Journal
-- STRJRNPF FILE(FICHEROS/PARALAUD)
--             JRN(FICHEROS/DIARIO) IMAGES(*BOTH)