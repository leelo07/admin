
USE Test;
GO


--Execute ALTER database statement to create a new file in secondary fielgroup

ALTER DATABASE Test
ADD FILE
( NAME = test_secondary_dat_NEW, FILENAME = 'c:\test_secondary_dat_NEW.ndf')
TO FILEGROUP [SECONDARY];
GO

--show file usage before emptying the file
DBCC SHOWFILESTATS;
go

--empty the old file (this will migrate data to a new file as an online operation;
DBCC SHRINKFILE ('test_secondary_dat', EMPTYFILE);
GO

--show file usage after emptying the file
DBCC SHOWFILESTATS;
GO


--Remove the empty file
ALTER DATABASE TEST REMOVE FILE test_secondary_dat;
GO
