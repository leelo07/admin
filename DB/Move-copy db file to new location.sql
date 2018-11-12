--***********************************************
--* Before you copy the file you want to move
--***********************************************
ALTER DATABASE Warehouse001
MODIFY FILE ( NAME = Warehouse_Data_2, FILENAME = 'R:\amldb\Bank001\Warehouse_DATA_2.ndf')
go

ALTER DATABASE Warehouse001 SET OFFLINE WITH ROLLBACK AFTER 30 SECONDS;
--***********************************************
--* After the file is copied to the new location
--***********************************************
ALTER DATABASE Warehouse001 SET ONLINE;

SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'Warehouse001');