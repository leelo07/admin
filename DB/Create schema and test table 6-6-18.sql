EXEC ('CREATE SCHEMA [ABC]');
/* Create a table for POC testing */
select top 1000 * into abc.address 
from  dbo.address
