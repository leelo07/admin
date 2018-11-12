SELECT top 1000  'table_name' = OBJECT_NAME(i.id),
		i.indid,
        'index_name' = i.name,
        i.groupid,
        'filegroup' = f.name,
        'file_name' = d.physical_name,
        'dataspace' = s.name
FROM    sys.sysindexes i,
        sys.filegroups f,
        sys.database_files d,
        sys.data_spaces s
WHERE   OBJECTPROPERTY(i.id, 'IsUserTable') = 1
        AND f.data_space_id = i.groupid
        AND f.data_space_id = d.data_space_id
        AND f.data_space_id = s.data_space_id
	--	and i.name = 'PK_Groups'
ORDER BY f.name,
        OBJECT_NAME(i.id),
        groupid

		
