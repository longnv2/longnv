ALTER PROCEDURE PCD_CHECK_DATA_DAILY @DATE VARCHAR(8)
AS
BEGIN
	TRUNCATE TABLE LOG_DB..CHECK_DATA_DAILY
	DECLARE @SQL VARCHAR(MAX)
	DECLARE @TABLE_NAME VARCHAR(100)
	DECLARE @COLUMN_NAME VARCHAR(100)
	DECLARE @START INT
	DECLARE @END INT
	SET @END = (SELECT MAX(ID) FROM LOG_DB..DAILY_ETL_TABLE_LIST)
	SET @START = 1
	WHILE (@START <= @END)
		BEGIN
		SET @TABLE_NAME = (SELECT TABLE_NAME FROM LOG_DB..DAILY_ETL_TABLE_LIST WHERE ID = @START)
		SET @COLUMN_NAME = (SELECT COLUMN_NAME FROM LOG_DB..DAILY_ETL_TABLE_LIST WHERE ID = @START)
	
		IF @COLUMN_NAME IS NULL
			SET @SQL = 'SELECT COUNT(1) FROM STG_T24..' + @TABLE_NAME
		ELSE 
			SET @SQL = 'SELECT COUNT(1) FROM STG_T24..' + @TABLE_NAME + ' WHERE ' + @COLUMN_NAME + ' = ' + '''' + @DATE + ''''

		INSERT INTO LOG_DB..CHECK_DATA_DAILY (
			  ROW_COUNT
		) EXEC ('' + @SQL +'')

		UPDATE C
		SET TABLE_NAME = @TABLE_NAME
			, COB_DATE = @DATE
		FROM LOG_DB..CHECK_DATA_DAILY AS C
		WHERE C.ID = @START


		SET @START = @START + 1
		IF @START = @END + 1
			BREAK
	END
 
END
