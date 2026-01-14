**FREE
//------------------------------------------------------------------------
// BINCPY_H - COPY FILE PARA PROCESOS DE FICHEROS DE BINTER
//------------------------------------------------------------------------

//------------------------------------------------------------------------
// Prototipos
//------------------------------------------------------------------------
dcl-pr Execute extpgm('QCMDEXC');
*n char(32000) const options(*varsize);
*n packed(15: 5) const;
end-pr;

//------------------------------------------------------------------------
// Estucturas Templates
//------------------------------------------------------------------------

//ID File Recibidos de AMADEUS
dcl-ds dsAMADEUS_FilesTpl qualified template inz;
  ID              Zoned(10);
  Filename        Varchar(300);
  Cant_Reg        Zoned(5);
end-ds;
//------------------------------------------------------------------------
// Templates de Ficheros
//------------------------------------------------------------------------
dcl-ds dsAMABINDETTpl qualified template inz;
  ID                     Zoned(10); 
  ID_DEBIT_CREDIT_CODE   CHAR(2); 
  AIRLINE_CODE           VARCHAR(3); 
  DOCUMENT_NUMBER        VARCHAR(10); 
  AGENT_IATA_CODE        VARCHAR(7); 
  ISSUE_DATE             DATE; 
  BILLING_PERIOD         CHAR(1); 
  BILLING_MONTH          Zoned( 5); 
  BILLING_YEAR           Zoned( 5); 
  INVOICE_REFERENCE      VARCHAR(8); 
  PASSENGER_NAME         VARCHAR(25); 
  ENTITY_CODE            CHAR(2); 
  CREDIT_CARD_NUMBER     Zoned(16: 0); 
  RESERVED_SPACE_1       CHAR(2); 
  CLIENT_REFERENCE       VARCHAR(10); 
  DEBIT_CREDIT_AMOUNT    Zoned(15: 4); 
  APPROVAL_CODE          VARCHAR(10); 
  SEQUENCE_NUMBER        VARCHAR(8); 
  INVOICE_DATE           DATE; 
  RESERVED_SPACE_2       VARCHAR(6); 
  CITY_NAME_1            VARCHAR(3); 
  FARE_BASIS_1           VARCHAR(12); 
  CARRIER_1              VARCHAR(4); 
  CLASS_OF_SERVICE_1     CHAR(2); 
  CITY_NAME_2            VARCHAR(3); 
  FARE_BASIS_2           VARCHAR(12); 
  CARRIER_2              VARCHAR(4); 
  CLASS_OF_SERVICE_2     CHAR(2); 
  CITY_NAME_3            VARCHAR(3); 
  FARE_BASIS_3           VARCHAR(12); 
  CARRIER_3              VARCHAR(4); 
  CLASS_OF_SERVICE_3     CHAR(2); 
  CITY_NAME_4            VARCHAR(3); 
  FARE_BASIS_4           VARCHAR(12); 
  CARRIER_4              VARCHAR(4); 
  CLASS_OF_SERVICE_4     CHAR(2); 
  CITY_NAME_5            VARCHAR(3); 
  CURRENCY_CODE          VARCHAR(3); 
  CURRENCY_DECIMALS      Zoned( 5); 
  RESERVED_SPACE_3       VARCHAR(8); 
  DESTINATION_CITY       VARCHAR(3); 
  RESERVED_SPACE_4       VARCHAR(12); 
  SUBENTITY_CODE         CHAR(2); 
  INVOICE_NUMBER         VARCHAR(14); 
  MERCHANT_NUMBER        Zoned(10); 
  EXTENDED_FORM_OF_PAYMENT CHAR(2); 
  EXPIRY_DATE_CREDIT_CARD  VARCHAR(4); 
  COMMISSION             VARCHAR(4); 
  FIRST_FLIGHT_DATE      VARCHAR(5); 
end-ds;
//------------------------------------------------------------------------
// Variables y Constantes
//------------------------------------------------------------------------
Dcl-c WComi   const(x'7D');
//------------------------------------------------------------------------
