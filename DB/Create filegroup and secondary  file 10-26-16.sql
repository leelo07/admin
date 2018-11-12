ALTER DATABASE [ctcInventory] ADD FILEGROUP [ctc_Secondary]
GO
--In this case we named our new filegroup ctc_Secondary.
--We now want to create a new file in our ctc_Secondary filegroup to hold our ‘large’ non clustered index:
USE [master]
GO
ALTER DATABASE [ctcInventory] 
ADD FILE 
      ( 
      NAME = N'ctcInventory_data_2', 
      FILENAME = N'E:\MSSQL12.MSSQLSERVER\MSSQL\DATA\ctcInventory_data_2.ndf', 
      SIZE = 50000MB , FILEGROWTH = 2500MB 
      ) 
TO FILEGROUP [ctc_Secondary]
GO
