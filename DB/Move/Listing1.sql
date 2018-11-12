USE master;
GO




-- Create a database with two file groups.
CREATE DATABASE Test
ON PRIMARY
( NAME = test_primary_dat, FILENAME = 'c:\test_primary_dat.mdf'),
FILEGROUP SECONDARY
( NAME = test_secondary_dat, FILENAME = 'c:\test_secondary_dat.ndf')
LOG ON
( NAME = test_log, FILENAME = 'c:\test_log.ldf');
GO



USE TEST;
go

--create a table on secondary filegroup
CREATE TABLE dbo.TestData (TestData_ID int identity(1000,2) not null primary key clustered, TestData_Field1 int) 
ON [SECONDARY];
GO



--populate some test data
declare @counter int;
set @counter = 1;
while (@counter < 1000)
begin
	insert into dbo.TestData(TestData_Field1)
	VALUES(@counter);
	set @counter = @counter + 1;
end


GO


