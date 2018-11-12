-- Change location of tempdb for next restart
ALTER DATABASE tempdb 
 MODIFY FILE (NAME = tempdev, FILENAME = 'F:\Data\tempdb.mdf');
GO

ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'F:\Data\templog.ldf');
GO
-- Change size of tempdp
ALTER DATABASE tempdb 
MODIFY FILE  (NAME = 'tempdev', SIZE = 15000)