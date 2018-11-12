select 'alter database ', name, ' set single_user with rollback immediate; drop database ', NAME, ';'
FROM SYS.databases