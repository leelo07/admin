--******************************************************************************
--   THIS CODE AND INFORMATION ARE PROVIDED “AS IS” WITHOUT WARRANTY OF
--   ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED
--   TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
--   PARTICULAR PURPOSE.
--*
--******************************************************************************

--Query 1.  To Check the SQL Server Install Date


SELECT @@SERVERNAME AS [Server Name], create_date AS [SQL Server Install Date]
 FROM sys.server_principals WITH (NOLOCK)
 WHERE name = N'NT AUTHORITY\SYSTEM'
OR name = N'NT AUTHORITY\NETWORK SERVICE' OPTION (RECOMPILE);

 

--Query 2.  To Check the SQL Server Properties


SELECT SERVERPROPERTY('MachineName') AS [MachineName], SERVERPROPERTY('ServerName') AS [ServerName],
 SERVERPROPERTY('InstanceName') AS [Instance], SERVERPROPERTY('IsClustered') AS [IsClustered],
 SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [ComputerNamePhysicalNetBIOS],
 SERVERPROPERTY('Edition') AS [Edition], SERVERPROPERTY('ProductLevel') AS [ProductLevel],
 SERVERPROPERTY('ProductVersion') AS [ProductVersion], SERVERPROPERTY('ProcessID') AS [ProcessID],
 SERVERPROPERTY('Collation') AS [Collation], SERVERPROPERTY('IsFullTextInstalled') AS [IsFullTextInstalled],
 SERVERPROPERTY('IsIntegratedSecurityOnly') AS [IsIntegratedSecurityOnly],
 SERVERPROPERTY('IsHadrEnabled') AS [IsHadrEnabled], SERVERPROPERTY('HadrManagerStatus') AS [HadrManagerStatus];

--Query 3.  To Check the SQL Server Agent Jobs


SELECT sj.name AS [JobName], sj.[description] AS [JobDescription], SUSER_SNAME(sj.owner_sid) AS [JobOwner],
 sj.date_created, sj.[enabled], sj.notify_email_operator_id, sc.name AS [CategoryName]
 FROM msdb.dbo.sysjobs AS sj WITH (NOLOCK)
 INNER JOIN msdb.dbo.syscategories AS sc WITH (NOLOCK)
 ON sj.category_id = sc.category_id
 ORDER BY sj.name OPTION (RECOMPILE);

--Query 4.  To Check the SQL Server Agent Alerts Information


SELECT name, event_source, message_id, severity, [enabled], has_notification,
 delay_between_responses, occurrence_count, last_occurrence_date, last_occurrence_time
 FROM msdb.dbo.sysalerts WITH (NOLOCK)
 ORDER BY name OPTION (RECOMPILE);

--Query 5.  To Check the SQL Server Global Trace Flags Status


DBCC TRACESTATUS (-1);

-- If no global trace flags are enabled, no results will be returned.
-- It is very useful to know what global trace flags are currently enabled as part of the diagnostic process.
-- Common trace flags that should be enabled in most cases

--Query 6.  To Check the SQL Server Services Info


SELECT servicename, process_id, startup_type_desc, status_desc,
 last_startup_time, service_account, is_clustered, cluster_nodename, [filename]
 FROM sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE);

--Query 7.  To Check the SQL Server Hardware Info


SELECT cpu_count AS [Logical CPU Count], scheduler_count, hyperthread_ratio AS [Hyperthread Ratio],
 cpu_count/hyperthread_ratio AS [Physical CPU Count],
 physical_memory_kb/1024 AS [Physical Memory (MB)], committed_kb/1024 AS [Committed Memory (MB)],
 committed_target_kb/1024 AS [Committed Target Memory (MB)],
 max_workers_count AS [Max Workers Count], affinity_type_desc AS [Affinity Type],
 sqlserver_start_time AS [SQL Server Start Time], virtual_machine_type_desc AS [Virtual Machine Type]
 FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);

--Query 8.  To Check the SQL Server Error Log


SELECT is_enabled, [path], max_size, max_files
 FROM sys.dm_os_server_diagnostics_log_configurations WITH (NOLOCK) OPTION (RECOMPILE);

--Query 9.  To Check the SQL Server Database Properties (Instance Level)


SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], db.state_desc,
 db.log_reuse_wait_desc AS [Log Reuse Wait Description],
 CONVERT(DECIMAL(18,2), ls.cntr_value/1024.0) AS [Log Size (MB)], CONVERT(DECIMAL(18,2), lu.cntr_value/1024.0) AS [Log Used (MB)],
 CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %],
 db.[compatibility_level] AS [DB Compatibility Level],
 db.page_verify_option_desc AS [Page Verify Option], db.is_auto_create_stats_on, db.is_auto_update_stats_on,
 db.is_auto_update_stats_async_on, db.is_parameterization_forced,
 db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on,
 db.is_auto_close_on, db.is_auto_shrink_on, db.target_recovery_time_in_seconds, db.is_cdc_enabled
 FROM sys.databases AS db WITH (NOLOCK)
 INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
 ON db.name = lu.instance_name
 INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
 ON db.name = ls.instance_name
 WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%'
AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
AND ls.cntr_value > 0 OPTION (RECOMPILE);

--Query 10.  To Check the SQL Server Missing Indexes All Databases


SELECT CONVERT(decimal(18,2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) AS [index_advantage],
 migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
 mid.equality_columns, mid.inequality_columns, mid.included_columns,
 migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
 FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
 INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
 ON migs.group_handle = mig.index_group_handle
 INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
 ON mig.index_handle = mid.index_handle
 ORDER BY index_advantage DESC OPTION (RECOMPILE);

--Query 11.  To Check the SQL Server CPU Usage by Database


WITH DB_CPU_Stats
 AS
 (SELECT DatabaseID, DB_Name(DatabaseID) AS [Database Name], SUM(total_worker_time) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID]
 FROM sys.dm_exec_plan_attributes(qs.plan_handle)
 WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
 SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [CPU Rank],
 [Database Name], [CPU_Time_Ms] AS [CPU Time (ms)],
 CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU Percent]
 FROM DB_CPU_Stats
 WHERE DatabaseID <> 32767 -- ResourceDB
 ORDER BY [CPU Rank] OPTION (RECOMPILE);

--Query 12.  To Check the SQL Server IO Usage By Database


WITH Aggregate_IO_Statistics
 AS
 (SELECT DB_NAME(database_id) AS [Database Name],
 CAST(SUM(num_of_bytes_read + num_of_bytes_written)/1048576 AS DECIMAL(12, 2)) AS io_in_mb
 FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]
 GROUP BY database_id)
 SELECT ROW_NUMBER() OVER(ORDER BY io_in_mb DESC) AS [I/O Rank], [Database Name], io_in_mb AS [Total I/O (MB)],
 CAST(io_in_mb/ SUM(io_in_mb) OVER() * 100.0 AS DECIMAL(5,2)) AS [I/O Percent]
 FROM Aggregate_IO_Statistics
 ORDER BY [I/O Rank] OPTION (RECOMPILE);

--Query 13.  To Check the SQL Server Total Buffer Usage by Database


-- This make take some time to run on a busy instance
 WITH AggregateBufferPoolUsage
 AS
 (SELECT DB_NAME(database_id) AS [Database Name],
 CAST(COUNT(*) * 8/1024.0 AS DECIMAL (10,2))  AS [CachedSize]
 FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
 WHERE database_id <> 32767 -- ResourceDB
 GROUP BY DB_NAME(database_id))
 SELECT ROW_NUMBER() OVER(ORDER BY CachedSize DESC) AS [Buffer Pool Rank], [Database Name], CachedSize AS [Cached Size (MB)],
 CAST(CachedSize / SUM(CachedSize) OVER() * 100.0 AS DECIMAL(5,2)) AS [Buffer Pool Percent]
 FROM AggregateBufferPoolUsage
 ORDER BY [Buffer Pool Rank] OPTION (RECOMPILE);

--Query 14.  To Check the SQL Server top waits for server instance since last restart or wait statistics clear


WITH [Waits]
 AS (SELECT wait_type, wait_time_ms/ 1000.0 AS [WaitS],
 (wait_time_ms - signal_wait_time_ms) / 1000.0 AS [ResourceS],
 signal_wait_time_ms / 1000.0 AS [SignalS],
 waiting_tasks_count AS [WaitCount],
 100.0 *  wait_time_ms / SUM (wait_time_ms) OVER() AS [Percentage],
 ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS [RowNum]
 FROM sys.dm_os_wait_stats WITH (NOLOCK)
 WHERE [wait_type] NOT IN (
 N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT',
N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',
N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
AND waiting_tasks_count > 0)
 SELECT
 MAX (W1.wait_type) AS [WaitType],
 CAST (MAX (W1.WaitS) AS DECIMAL (16,2)) AS [Wait_Sec],
 CAST (MAX (W1.ResourceS) AS DECIMAL (16,2)) AS [Resource_Sec],
 CAST (MAX (W1.SignalS) AS DECIMAL (16,2)) AS [Signal_Sec],
 MAX (W1.WaitCount) AS [Wait Count],
 CAST (MAX (W1.Percentage) AS DECIMAL (5,2)) AS [Wait Percentage],
 CAST ((MAX (W1.WaitS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgWait_Sec],
 CAST ((MAX (W1.ResourceS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgRes_Sec],
 CAST ((MAX (W1.SignalS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgSig_Sec]
 FROM Waits AS W1
 INNER JOIN Waits AS W2
 ON W2.RowNum <= W1.RowNum
 GROUP BY W1.RowNum
 HAVING SUM (W2.Percentage) - MAX (W1.Percentage) < 99 -- percentage threshold
 OPTION (RECOMPILE);

--Query 15.  To Check the SQL Server CPU Utilization History


DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK));

SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization],
 SystemIdle AS [System Idle Process],
 100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization],
 DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time]
 FROM (
 SELECT record.value('(./Record/@id)[1]', 'int') AS record_id,
record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')
AS [SystemIdle],
record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]',
'int')
AS [SQLProcessUtilization], [timestamp]
 FROM (
 SELECT [timestamp], CONVERT(xml, record) AS [record]
 FROM sys.dm_os_ring_buffers WITH (NOLOCK)
 WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
AND record LIKE N'%<SystemHealth>%') AS x
 ) AS y
 ORDER BY record_id DESC OPTION (RECOMPILE);

--Query 16.  To Check the SQL Server Top Worker Time Queries


SELECT TOP(50) DB_NAME(t.[dbid]) AS [Database Name], t.[text] AS [Query Text],
 qs.total_worker_time AS [Total Worker Time], qs.min_worker_time AS [Min Worker Time],
 qs.total_worker_time/qs.execution_count AS [Avg Worker Time],
 qs.max_worker_time AS [Max Worker Time], qs.execution_count AS [Execution Count],
 qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time],
 qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads],
 qs.total_physical_reads/qs.execution_count AS [Avg Physical Reads],
 qp.query_plan AS [Query Plan], qs.creation_time AS [Creation Time]
 FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
 CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
 CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
 ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE);

--Query 17.  To Check the SQL Server System Memory and Process Memory


SELECT total_physical_memory_kb/1024 AS [Physical Memory (MB)],
 available_physical_memory_kb/1024 AS [Available Memory (MB)],
 total_page_file_kb/1024 AS [Total Page File (MB)],
 available_page_file_kb/1024 AS [Available Page File (MB)],
 system_cache_kb/1024 AS [System Cache (MB)],
 system_memory_state_desc AS [System Memory State]
 FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

 

SELECT physical_memory_in_use_kb/1024 AS [SQL Server Memory Usage (MB)],
 large_page_allocations_kb, locked_page_allocations_kb, page_fault_count,
 memory_utilization_percentage, available_commit_limit_kb,
 process_physical_memory_low, process_virtual_memory_low
 FROM sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);

--Query 18.  To Check the SQL Server single-use, Ad hoc Queries


SELECT TOP(50) [text] AS [QueryText], cp.cacheobjtype, cp.objtype, cp.size_in_bytes/1024 AS [Plan Size in KB]
 FROM sys.dm_exec_cached_plans AS cp WITH (NOLOCK)
 CROSS APPLY sys.dm_exec_sql_text(plan_handle)
 WHERE cp.cacheobjtype = N'Compiled Plan'
AND cp.objtype IN (N'Adhoc', N'Prepared')
AND cp.usecounts = 1
 ORDER BY cp.size_in_bytes DESC OPTION (RECOMPILE);


-- **** Switch to a user database *****

USE YourDatabaseName;

GO

--Query 19.  To Check the SQL Server user database  File Sizes and Space


-- Individual File Sizes and space available for current database  (Query 45) (File Sizes and Space)
 SELECT f.name AS [File Name] , f.physical_name AS [Physical Name],
 CAST((f.size/128.0) AS DECIMAL(15,2)) AS [Total Size in MB],
 CAST(f.size/128.0 - CAST(FILEPROPERTY(f.name, 'SpaceUsed') AS int)/128.0 AS DECIMAL(15,2))
 AS [Available Space In MB], [file_id], fg.name AS [Filegroup Name]
 FROM sys.database_files AS f WITH (NOLOCK)
 LEFT OUTER JOIN sys.data_spaces AS fg WITH (NOLOCK)
 ON f.data_space_id = fg.data_space_id OPTION (RECOMPILE);

--Query 20.  To Check the SQL Server User database  IO Stats By File


-- I/O Statistics by file for the current database  (Query 46) (IO Stats By File)
 SELECT DB_NAME(DB_ID()) AS [Database Name], df.name AS [Logical Name], vfs.[file_id],
 df.physical_name AS [Physical Name], vfs.num_of_reads, vfs.num_of_writes, vfs.io_stall_read_ms, vfs.io_stall_write_ms,
 CAST(100. * vfs.io_stall_read_ms/(vfs.io_stall_read_ms + vfs.io_stall_write_ms) AS DECIMAL(10,1)) AS [IO Stall Reads Pct],
 CAST(100. * vfs.io_stall_write_ms/(vfs.io_stall_write_ms + vfs.io_stall_read_ms) AS DECIMAL(10,1)) AS [IO Stall Writes Pct],
 (vfs.num_of_reads + vfs.num_of_writes) AS [Writes + Reads],
 CAST(vfs.num_of_bytes_read/1048576.0 AS DECIMAL(10, 2)) AS [MB Read],
 CAST(vfs.num_of_bytes_written/1048576.0 AS DECIMAL(10, 2)) AS [MB Written],
 CAST(100. * vfs.num_of_reads/(vfs.num_of_reads + vfs.num_of_writes) AS DECIMAL(10,1)) AS [# Reads Pct],
 CAST(100. * vfs.num_of_writes/(vfs.num_of_reads + vfs.num_of_writes) AS DECIMAL(10,1)) AS [# Write Pct],
 CAST(100. * vfs.num_of_bytes_read/(vfs.num_of_bytes_read + vfs.num_of_bytes_written) AS DECIMAL(10,1)) AS [Read Bytes Pct],
 CAST(100. * vfs.num_of_bytes_written/(vfs.num_of_bytes_read + vfs.num_of_bytes_written) AS DECIMAL(10,1)) AS [Written Bytes Pct]
 FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) AS vfs
 INNER JOIN sys.database_files AS df WITH (NOLOCK)
 ON vfs.[file_id]= df.[file_id] OPTION (RECOMPILE);

--Query 21.  To Check the SQL Server User database Query Execution Counts


-- Top cached queries by Execution Count (SQL Server 2012)  (Query 47) (Query Execution Counts)
 SELECT TOP (100) qs.execution_count, qs.total_rows, qs.last_rows, qs.min_rows, qs.max_rows,
 qs.last_elapsed_time, qs.min_elapsed_time, qs.max_elapsed_time,
 total_worker_time, total_logical_reads,
 SUBSTRING(qt.TEXT,qs.statement_start_offset/2 +1,
 (CASE WHEN qs.statement_end_offset = -1
 THEN LEN(CONVERT(NVARCHAR(MAX), qt.TEXT)) * 2
 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) AS query_text
 FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
 ORDER BY qs.execution_count DESC OPTION (RECOMPILE);

--Query 22.  To Check the SQL Server User database SP Execution Counts


-- Top Cached SPs By Execution Count (SQL Server 2012)  (Query 48) (SP Execution Counts)
 SELECT TOP(100) p.name AS [SP Name], qs.execution_count,
 ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
 qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], qs.total_worker_time AS [TotalWorkerTime],
 qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
 qs.cached_time
 FROM sys.procedures AS p WITH (NOLOCK)
 INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
 ON p.[object_id] = qs.[object_id]
 WHERE qs.database_id = DB_ID()
 ORDER BY qs.execution_count DESC OPTION (RECOMPILE);

--Query 23.  To Check the SQL Server User database SP Avg Elapsed Time


-- Top Cached SPs By Avg Elapsed Time (SQL Server 2012)  (Query 49) (SP Avg Elapsed Time)
 SELECT TOP(25) p.name AS [SP Name], qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
 qs.total_elapsed_time, qs.execution_count, ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time,
 GETDATE()), 0) AS [Calls/Minute], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
 qs.total_worker_time AS [TotalWorkerTime], qs.cached_time
 FROM sys.procedures AS p WITH (NOLOCK)
 INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
 ON p.[object_id] = qs.[object_id]
 WHERE qs.database_id = DB_ID()
 ORDER BY avg_elapsed_time DESC OPTION (RECOMPILE);

-- This helps you find long-running cached stored procedures that
-- may be easy to optimize with standard query tuning techniques

--Query 24.  To Check the SQL Server User database SP Avg Elapsed Variable Time


-- Top Cached SPs By Avg Elapsed Time with execution time variability (SQL Server 2012)  (Query 50) (SP Avg Elapsed Variable Time)
 SELECT TOP(25) p.name AS [SP Name], qs.execution_count, qs.min_elapsed_time,
 qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
 qs.max_elapsed_time, qs.last_elapsed_time,  qs.cached_time
 FROM sys.procedures AS p WITH (NOLOCK)
 INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
 ON p.[object_id] = qs.[object_id]
 WHERE qs.database_id = DB_ID()
 ORDER BY avg_elapsed_time DESC OPTION (RECOMPILE);

--Query 25.  To Check the SQL Server User database SP Worker Time


-- Top Cached SPs By Total Worker time (SQL Server 2012). Worker time relates to CPU cost  (Query 51) (SP Worker Time)
 SELECT TOP(25) p.name AS [SP Name], qs.total_worker_time AS [TotalWorkerTime],
 qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], qs.execution_count,
 ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
 qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count
 AS [avg_elapsed_time], qs.cached_time
 FROM sys.procedures AS p WITH (NOLOCK)
 INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
 ON p.[object_id] = qs.[object_id]
 WHERE qs.database_id = DB_ID()
 ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE);

-- This helps you find the most expensive cached stored procedures from a CPU perspective
-- You should look at this if you see signs of CPU pressure

--Query 26.  To Check the SQL Server User database SP Logical Reads


-- Top Cached SPs By Total Logical Reads (SQL Server 2012). Logical reads relate to memory pressure  (Query 52) (SP Logical Reads)
 SELECT TOP(25) p.name AS [SP Name], qs.total_logical_reads AS [TotalLogicalReads],
 qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],qs.execution_count,
 ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
 qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count
 AS [avg_elapsed_time], qs.cached_time
 FROM sys.procedures AS p WITH (NOLOCK)
 INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
 ON p.[object_id] = qs.[object_id]
 WHERE qs.database_id = DB_ID()
 ORDER BY qs.total_logical_reads DESC OPTION (RECOMPILE);

-- This helps you find the most expensive cached stored procedures from a memory perspective
-- You should look at this if you see signs of memory pressure

--Query 27.  To Check the SQL Server User database SP Physical Reads


-- Top Cached SPs By Total Physical Reads (SQL Server 2012). Physical reads relate to disk I/O pressure  (Query 53) (SP Physical Reads)
 SELECT TOP(25) p.name AS [SP Name],qs.total_physical_reads AS [TotalPhysicalReads],
 qs.total_physical_reads/qs.execution_count AS [AvgPhysicalReads], qs.execution_count,
 qs.total_logical_reads,qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count
 AS [avg_elapsed_time], qs.cached_time
 FROM sys.procedures AS p WITH (NOLOCK)
 INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
 ON p.[object_id] = qs.[object_id]
 WHERE qs.database_id = DB_ID()
 AND qs.total_physical_reads > 0
 ORDER BY qs.total_physical_reads DESC, qs.total_logical_reads DESC OPTION (RECOMPILE);

-- This helps you find the most expensive cached stored procedures from a read I/O perspective
-- You should look at this if you see signs of I/O pressure or of memory pressure

--Query 28.  To Check the SQL Server User database SP Logical Writes


-- Top Cached SPs By Total Logical Writes (SQL Server 2012)  (Query 54) (SP Logical Writes)
-- Logical writes relate to both memory and disk I/O pressure
 SELECT TOP(25) p.name AS [SP Name], qs.total_logical_writes AS [TotalLogicalWrites],
 qs.total_logical_writes/qs.execution_count AS [AvgLogicalWrites], qs.execution_count,
 ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
 qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time],
 qs.cached_time
 FROM sys.procedures AS p WITH (NOLOCK)
 INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
 ON p.[object_id] = qs.[object_id]
 WHERE qs.database_id = DB_ID()
 AND qs.total_logical_writes > 0
 ORDER BY qs.total_logical_writes DESC OPTION (RECOMPILE);

-- This helps you find the most expensive cached stored procedures from a write I/O perspective
-- You should look at this if you see signs of I/O pressure or of memory pressure

--Query 29.  To Check the SQL Server User database Top IO Statements


-- Lists the top statements by average input/output usage for the current database  (Query 55) (Top IO Statements)
 SELECT TOP(50) OBJECT_NAME(qt.objectid, dbid) AS [SP Name],
 (qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count AS [Avg IO], qs.execution_count AS [Execution Count],
 SUBSTRING(qt.[text],qs.statement_start_offset/2,
 (CASE
 WHEN qs.statement_end_offset = -1
 THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2
 ELSE qs.statement_end_offset
 END - qs.statement_start_offset)/2) AS [Query Text]
 FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
 WHERE qt.[dbid] = DB_ID()
 ORDER BY [Avg IO] DESC OPTION (RECOMPILE);

-- Helps you find the most expensive statements for I/O by SP

--Query 30.  To Check the SQL Server User database Bad Non-Clustered Indexes


-- Possible Bad NC Indexes (writes > reads)  (Query 56) (Bad NC Indexes)
 SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id,
 i.is_disabled, i.is_hypothetical, i.has_filter, i.fill_factor,
 user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
 user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
 FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
 INNER JOIN sys.indexes AS i WITH (NOLOCK)
 ON s.[object_id] = i.[object_id]
 AND i.index_id = s.index_id
 WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
 AND s.database_id = DB_ID()
 AND user_updates > (user_seeks + user_scans + user_lookups)
 AND i.index_id > 1
 ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC OPTION (RECOMPILE);

-- Look for indexes with high numbers of writes and zero or very low numbers of reads
-- Consider your complete workload, and how long your instance has been running
-- Investigate further before dropping an index!

--Query 31.  To Check the SQL Server User database Missing Indexes


-- Missing Indexes for current database by Index Advantage  (Query 57) (Missing Indexes)
 SELECT DISTINCT CONVERT(decimal(18,2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) AS [index_advantage],
 migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
 mid.equality_columns, mid.inequality_columns, mid.included_columns,
 migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact,
 OBJECT_NAME(mid.[object_id]) AS [Table Name], p.rows AS [Table Rows]
 FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
 INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
 ON migs.group_handle = mig.index_group_handle
 INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
 ON mig.index_handle = mid.index_handle
 INNER JOIN sys.partitions AS p WITH (NOLOCK)
 ON p.[object_id] = mid.[object_id]
 WHERE mid.database_id = DB_ID()
 ORDER BY index_advantage DESC OPTION (RECOMPILE);

-- Look at index advantage, last user seek time, number of user seeks to help determine source and importance
-- SQL Server is overly eager to add included columns, so beware
-- Do not just blindly add indexes that show up from this query!!!

--Query 32.  To Check the SQL Server User database Missing Index Warnings


-- Find missing index warnings for cached plans in the current database  (Query 58) (Missing Index Warnings)
-- Note: This query could take some time on a busy instance
 SELECT TOP(25) OBJECT_NAME(objectid) AS [ObjectName],
 query_plan, cp.objtype, cp.usecounts
 FROM sys.dm_exec_cached_plans AS cp WITH (NOLOCK)
 CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
 WHERE CAST(query_plan AS NVARCHAR(MAX)) LIKE N'%MissingIndex%'
AND dbid = DB_ID()
 ORDER BY cp.usecounts DESC OPTION (RECOMPILE);

-- Helps you connect missing indexes to specific stored procedures
-- This can help you decide whether to add them or not

--Query 33.  To Check the SQL Server User database Buffer Usage


-- Breaks down buffers used by current database by object (table, index) in the buffer cache  (Query 59) (Buffer Usage)
-- Note: This query could take some time on a busy instance
 SELECT OBJECT_NAME(p.[object_id]) AS [Object Name], p.index_id,
 CAST(COUNT(*)/128.0 AS DECIMAL(10, 2)) AS [Buffer size(MB)],
 COUNT(*) AS [BufferCount], p.Rows AS [Row Count],
 p.data_compression_desc AS [Compression Type]
 FROM sys.allocation_units AS a WITH (NOLOCK)
 INNER JOIN sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
 ON a.allocation_unit_id = b.allocation_unit_id
 INNER JOIN sys.partitions AS p WITH (NOLOCK)
 ON a.container_id = p.hobt_id
 WHERE b.database_id = CONVERT(int,DB_ID())
 AND p.[object_id] > 100
 GROUP BY p.[object_id], p.index_id, p.data_compression_desc, p.[Rows]
 ORDER BY [BufferCount] DESC OPTION (RECOMPILE);

-- Tells you what tables and indexes are using the most memory in the buffer cache
-- It can help identify possible candidates for data compression

--Query 34.  To Check the SQL Server User database Table Sizes


-- Get Table names, row counts, and compression status for clustered index or heap  (Query 60) (Table Sizes)
 SELECT OBJECT_NAME(object_id) AS [ObjectName],
 SUM(Rows) AS [RowCount], data_compression_desc AS [CompressionType]
 FROM sys.partitions WITH (NOLOCK)
 WHERE index_id < 2 --ignore the partitions from the non-clustered index if any
 AND OBJECT_NAME(object_id) NOT LIKE N'sys%'
AND OBJECT_NAME(object_id) NOT LIKE N'queue_%'
AND OBJECT_NAME(object_id) NOT LIKE N'filestream_tombstone%'
AND OBJECT_NAME(object_id) NOT LIKE N'fulltext%'
AND OBJECT_NAME(object_id) NOT LIKE N'ifts_comp_fragment%'
AND OBJECT_NAME(object_id) NOT LIKE N'filetable_updates%'
AND OBJECT_NAME(object_id) NOT LIKE N'xml_index_nodes%'
GROUP BY object_id, data_compression_desc
 ORDER BY SUM(Rows) DESC OPTION (RECOMPILE);

-- Gives you an idea of table sizes, and possible data compression opportunities

--Query 35.  To Check the SQL Server User database Table Properties


-- Get some key table properties (Query 61) (Table Properties)
 SELECT [name], create_date, lock_on_bulk_load, is_replicated, has_replication_filter,
 is_tracked_by_cdc, lock_escalation_desc
 FROM sys.tables WITH (NOLOCK)
 ORDER BY [name] OPTION (RECOMPILE);

-- Gives you some good information about your tables

--Query 36.  To Check the SQL Server User database Detect Blocking


-- Detect blocking (run multiple times)  (Query 62) (Detect Blocking)
 SELECT t1.resource_type AS [lock type], DB_NAME(resource_database_id) AS [database],
 t1.resource_associated_entity_id AS [blk object],t1.request_mode AS [lock req],  -- lock requested
 t1.request_session_id AS [waiter sid], t2.wait_duration_ms AS [wait time],       -- spid of waiter
 (SELECT [text] FROM sys.dm_exec_requests AS r WITH (NOLOCK)                      -- get sql for waiter
 CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle])
 WHERE r.session_id = t1.request_session_id) AS [waiter_batch],
 (SELECT SUBSTRING(qt.[text],r.statement_start_offset/2,
 (CASE WHEN r.statement_end_offset = -1
 THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2
 ELSE r.statement_end_offset END - r.statement_start_offset)/2)
 FROM sys.dm_exec_requests AS r WITH (NOLOCK)
 CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) AS qt
 WHERE r.session_id = t1.request_session_id) AS [waiter_stmt],                    -- statement blocked
 t2.blocking_session_id AS [blocker sid],                                        -- spid of blocker
 (SELECT [text] FROM sys.sysprocesses AS p                                        -- get sql for blocker
 CROSS APPLY sys.dm_exec_sql_text(p.[sql_handle])
 WHERE p.spid = t2.blocking_session_id) AS [blocker_stmt]
 FROM sys.dm_tran_locks AS t1 WITH (NOLOCK)
 INNER JOIN sys.dm_os_waiting_tasks AS t2 WITH (NOLOCK)
 ON t1.lock_owner_address = t2.resource_address OPTION (RECOMPILE);

-- Helps troubleshoot blocking and deadlocking issues
-- The results will change from second to second on a busy system
-- You should run this query multiple times when you see signs of blocking

--Query 37.  To Check the SQL Server User database Update Statistics


-- When were Statistics last updated on all indexes?  (Query 63) (Statistics Update)
 SELECT SCHEMA_NAME(o.Schema_ID) + N'.' + o.NAME AS [Object Name], o.type_desc AS [Object Type],
 i.name AS [Index Name], STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date],
 s.auto_created, s.no_recompute, s.user_created, st.row_count, st.used_page_count
 FROM sys.objects AS o WITH (NOLOCK)
 INNER JOIN sys.indexes AS i WITH (NOLOCK)
 ON o.[object_id] = i.[object_id]
 INNER JOIN sys.stats AS s WITH (NOLOCK)
 ON i.[object_id] = s.[object_id]
 AND i.index_id = s.stats_id
 INNER JOIN sys.dm_db_partition_stats AS st WITH (NOLOCK)
 ON o.[object_id] = st.[object_id]
 AND i.[index_id] = st.[index_id]
 WHERE o.[type] IN ('U', 'V')
AND st.row_count > 0
 ORDER BY STATS_DATE(i.[object_id], i.index_id) DESC OPTION (RECOMPILE);

-- Helps discover possible problems with out-of-date statistics
-- Also gives you an idea which indexes are the most active

--Query 38.  To Check the SQL Server User database Volatile Indexes


-- Look at most frequently modified indexes and statistics (Query 64) (Volatile Indexes)
 SELECT o.name AS [Object Name], o.[object_id], o.type_desc, s.name AS [Statistics Name],
 s.stats_id, s.no_recompute, s.auto_created,
 sp.modification_counter, sp.rows, sp.rows_sampled, sp.last_updated
 FROM sys.objects AS o WITH (NOLOCK)
 INNER JOIN sys.stats AS s WITH (NOLOCK)
 ON s.object_id = o.object_id
 CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
 WHERE o.type_desc NOT IN (N'SYSTEM_TABLE', N'INTERNAL_TABLE')
AND sp.modification_counter > 0
 ORDER BY sp.modification_counter DESC, o.name OPTION (RECOMPILE);

--Query 39.  To Check the SQL Server User database Index Fragmentation


-- Get fragmentation info for all indexes above a certain size in the current database  (Query 65) (Index Fragmentation)
-- Note: This query could take some time on a very large database
 SELECT DB_NAME(ps.database_id) AS [Database Name], OBJECT_NAME(ps.OBJECT_ID) AS [Object Name],
 i.name AS [Index Name], ps.index_id, ps.index_type_desc, ps.avg_fragmentation_in_percent,
 ps.fragment_count, ps.page_count, i.fill_factor, i.has_filter, i.filter_definition
 FROM sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL , N'LIMITED') AS ps
 INNER JOIN sys.indexes AS i WITH (NOLOCK)
 ON ps.[object_id] = i.[object_id]
 AND ps.index_id = i.index_id
 WHERE ps.database_id = DB_ID()
 AND ps.page_count > 2500
 ORDER BY ps.avg_fragmentation_in_percent DESC OPTION (RECOMPILE);

-- Helps determine whether you have framentation in your relational indexes
-- and how effective your index maintenance strategy is

--Query 40.  To Check the SQL Server User database Overall Index Usage - Reads


-- Index Read/Write stats (all tables in current DB) ordered by Reads  (Query 66) (Overall Index Usage - Reads)
 SELECT OBJECT_NAME(s.[object_id]) AS [ObjectName], i.name AS [IndexName], i.index_id,
 user_seeks + user_scans + user_lookups AS [Reads], s.user_updates AS [Writes],
 i.type_desc AS [IndexType], i.fill_factor AS [FillFactor], i.has_filter, i.filter_definition,
 s.last_user_scan, s.last_user_lookup, s.last_user_seek
 FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
 INNER JOIN sys.indexes AS i WITH (NOLOCK)
 ON s.[object_id] = i.[object_id]
 WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
 AND i.index_id = s.index_id
 AND s.database_id = DB_ID()
 ORDER BY user_seeks + user_scans + user_lookups DESC OPTION (RECOMPILE); -- Order by reads

--Query 41.  To Check the SQL Server User database Overall Index Usage - Writes


-- Index Read/Write stats (all tables in current DB) ordered by Writes  (Query 67) (Overall Index Usage - Writes)
 SELECT OBJECT_NAME(s.[object_id]) AS [ObjectName], i.name AS [IndexName], i.index_id,
 s.user_updates AS [Writes], user_seeks + user_scans + user_lookups AS [Reads],
 i.type_desc AS [IndexType], i.fill_factor AS [FillFactor], i.has_filter, i.filter_definition,
 s.last_system_update, s.last_user_update
 FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
 INNER JOIN sys.indexes AS i WITH (NOLOCK)
 ON s.[object_id] = i.[object_id]
 WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
 AND i.index_id = s.index_id
 AND s.database_id = DB_ID()
 ORDER BY s.user_updates DESC OPTION (RECOMPILE);   -- Order by writes

-- Show which indexes in the current database are most active for Writes

--Query 42.  To Check the SQL Server User database Lock Waits


-- Get lock waits for current database (Query 68) (Lock Waits)
 SELECT o.name AS [table_name], i.name AS [index_name], ios.index_id, ios.partition_number,
 SUM(ios.row_lock_wait_count) AS [total_row_lock_waits],
 SUM(ios.row_lock_wait_in_ms) AS [total_row_lock_wait_in_ms],
 SUM(ios.page_lock_wait_count) AS [total_page_lock_waits],
 SUM(ios.page_lock_wait_in_ms) AS [total_page_lock_wait_in_ms],
 SUM(ios.page_lock_wait_in_ms)+ SUM(row_lock_wait_in_ms) AS [total_lock_wait_in_ms]
 FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) AS ios
 INNER JOIN sys.objects AS o WITH (NOLOCK)
 ON ios.[object_id] = o.[object_id]
 INNER JOIN sys.indexes AS i WITH (NOLOCK)
 ON ios.[object_id] = i.[object_id]
 AND ios.index_id = i.index_id
 WHERE o.[object_id] > 100
 GROUP BY o.name, i.name, ios.index_id, ios.partition_number
 HAVING SUM(ios.page_lock_wait_in_ms)+ SUM(row_lock_wait_in_ms) > 0
 ORDER BY total_lock_wait_in_ms DESC OPTION (RECOMPILE);

-- This query is helpful for troubleshooting blocking and deadlocking issues

--Query 43.  To Check the SQL Server User database Recent Full Backups


-- Look at recent Full backups for the current database (Query 69) (Recent Full Backups)
 SELECT TOP (30) bs.machine_name, bs.server_name, bs.database_name AS [Database Name], bs.recovery_model,
 CONVERT (BIGINT, bs.backup_size / 1048576 ) AS [Uncompressed Backup Size (MB)],
 CONVERT (BIGINT, bs.compressed_backup_size / 1048576 ) AS [Compressed Backup Size (MB)],
 CONVERT (NUMERIC (20,2), (CONVERT (FLOAT, bs.backup_size) /
 CONVERT (FLOAT, bs.compressed_backup_size))) AS [Compression Ratio],
 DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) AS [Backup Elapsed Time (sec)],
 bs.backup_finish_date AS [Backup Finish Date]
 FROM msdb.dbo.backupset AS bs WITH (NOLOCK)
 WHERE DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) > 0
 AND bs.backup_size > 0
 AND bs.type = 'D' -- Change to L if you want Log backups
 AND database_name = DB_NAME(DB_ID())
 ORDER BY bs.backup_finish_date DESC OPTION (RECOMPILE);
