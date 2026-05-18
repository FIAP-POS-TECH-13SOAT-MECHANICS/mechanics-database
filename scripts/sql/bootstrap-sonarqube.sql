-- SQLCMD variables (override via `sqlcmd -v`)
:setvar DB_NAME "sonarqube"
:setvar DB_COLLATION "Latin1_General_CS_AS"
:setvar SONAR_LOGIN "sonarqube"
:setvar SONAR_PASSWORD ""

SET NOCOUNT ON;

DECLARE @dbName sysname = N'$(DB_NAME)';
DECLARE @dbCollation sysname = N'$(DB_COLLATION)';

IF DB_ID(@dbName) IS NULL
BEGIN
  DECLARE @createDbSql NVARCHAR(MAX) =
    N'CREATE DATABASE ' + QUOTENAME(@dbName) + N' COLLATE ' + @dbCollation + N';';
  EXEC(@createDbSql);
END;

IF EXISTS (
  SELECT 1
  FROM sys.databases
  WHERE name = @dbName
    AND is_read_committed_snapshot_on = 0
)
BEGIN
  DECLARE @rcsiSql NVARCHAR(MAX) =
    N'ALTER DATABASE ' + QUOTENAME(@dbName) + N' SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;';
  EXEC(@rcsiSql);
END;

IF LEN(N'$(SONAR_PASSWORD)') > 0
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'$(SONAR_LOGIN)')
  BEGIN
    DECLARE @createLoginSql NVARCHAR(MAX) =
      N'CREATE LOGIN ' + QUOTENAME(N'$(SONAR_LOGIN)') + N' WITH PASSWORD = N''$(SONAR_PASSWORD)'', CHECK_POLICY = ON;';
    EXEC(@createLoginSql);
  END;

  DECLARE @grantSql NVARCHAR(MAX) =
      N'USE ' + QUOTENAME(@dbName) + N';
      IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''$(SONAR_LOGIN)'')
      BEGIN
        CREATE USER ' + QUOTENAME(N'$(SONAR_LOGIN)') + N' FOR LOGIN ' + QUOTENAME(N'$(SONAR_LOGIN)') + N';
      END;
      ALTER ROLE db_owner ADD MEMBER ' + QUOTENAME(N'$(SONAR_LOGIN)') + N';';
  EXEC(@grantSql);
END;

SELECT
  name,
  collation_name,
  is_read_committed_snapshot_on
FROM sys.databases
WHERE name = @dbName;
