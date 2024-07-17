	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	--	AUTHOR: $USER$ - Busuioc Stefania - Eliza
	--
	--	PURPOSE: TO RECONCILE THE DATA AND PREPARE THE SPOTLIGHT READY TEMPLATE IN ORDER TO UPLOAD INTO SPOTLIGHT
	--
	--	SERVER NAME: $SERVER$
	--
	--	DATABASE NAME: $DBNAME$
	--
	--  CLIENT ERP SYSTEM:
	--
	--	CLIENT ERP VERSION NUMBER :
	--
	--	LAST EDITED: $DATE$
	--
	--	COMMENTS: $CURSOR$
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- PREPARE THE DATABASE - TO BE RUN ONCE THE DATABASE HAS BEEN CREATED
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	USE [$DBNAME$]
	SET LANGUAGE BRITISH
	
	IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = 'RAW' ) EXEC ('CREATE SCHEMA [RAW]')
	IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = 'WIP' ) EXEC ('CREATE SCHEMA [WIP]')
	IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = 'READY' ) EXEC ('CREATE SCHEMA [READY]')
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- BULK INSERT
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- MANIPULATE GENERAL LEDGER
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	IF OBJECT_ID('[WIP].GL','U') IS NOT NULL DROP TABLE [WIP].GL
	SELECT * 
	INTO wip.gl 
	FROM (
	SELECT * FROM
	) AS g
	--(XXX row(s) affected)

	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- CREATE A GL PIVOT
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	IF OBJECT_ID('[WIP].[GLPivot]','U') IS NOT NULL DROP TABLE [WIP].[GLPivot]
	SELECT 
	[Company desc] AS Entity,
	[G/L Account] AS [Account Number],
	SUM(CAST([Balance Company Currency] AS MONEY)) AS [Journal Movement EC],
	COUNT(1) AS [Line Count]
	INTO [WIP].[GLPivot]  
	FROM WIP.GL
	GROUP BY
	--(XXX row(s) affected)
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- MANIPULATE TRIAL BALANCE
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	--DELETE IF YOU ARE NOT USING A SEPARATE OPENING AND CLOSING
	IF OBJECT_ID('[WIP].TB','U') IS NOT NULL DROP TABLE [WIP].TB
	;WITH
	 o AS(
	SELECT * 
	FROM 
	),
	c AS (
	SELECT * 
	FROM 
	)
	SELECT	COALESCE(o.NULL,c.NULL) AS Entity,
			COALESCE(o.[G/L Account],c.[G/L Account]) AS [Account Number],
			COALESCE(o.[COLUMN_1],c.[COLUMN_1]) AS [Account Description],
			CAST(o.[Opening Balance Company Currency] AS MONEY) AS Opening,
			CAST(c.[Ending Balance Company Currency] AS MONEY) AS Closing					 
	INTO [WIP].TB
	FROM o
	FULL OUTER JOIN c
	ON 
	--(XXX row(s) affected)
	
	
	--DELETE IF YOU ARE USING A SEPARATE OPENING AND CLOSING
	IF OBJECT_ID('[WIP].TB','U') IS NOT NULL DROP TABLE [WIP].TB
	SELECT	NULL AS Entity,
			[G/L Account] AS [Account Number],
			[COLUMN_1] AS [Account Description],
			CAST([Opening Balance Company Currency] AS MONEY) AS Opening,
			CAST([Ending Balance Company Currency] AS MONEY) AS Closing					 
	INTO [WIP].TB
	FROM 
	--(XXX row(s) affected)
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- CREATE A TB PIVOT
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	IF OBJECT_ID('[WIP].[TBPivot]','U') IS NOT NULL DROP TABLE [WIP].[TBPivot]
	SELECT 
	Entity AS Entity,
	[Account Number] AS [Account Number],
	ISNULL(MIN(LTRIM(RTRIM([Account Description]))),'') AS [Account Description],
	SUM(CAST(ISNULL(Opening,0) AS MONEY)) AS [Period Opening Balance EC],
	SUM(CAST(ISNULL(Closing,0) AS MONEY)) AS [Period Closing Balance EC],
	SUM(CAST(ISNULL(Closing,0) AS MONEY)) - SUM(CAST(ISNULL(Opening,0) AS MONEY)) AS [Movement EC]
	INTO [WIP].[TBPivot]
	FROM WIP.TB
	GROUP BY Entity,
	         [Account Number]
	--(XXX row(s) affected)
	
		
	------------------------------------------------------------------------
	-- DATA CONFIRMATION CHECKS
	------------------------------------------------------------------------
	
	--	SUM TO ZERO CHECK - ALWAYS COMPARE WITH RAW
	SELECT SUM(CAST([Balance Company Currency] AS MONEY)) FROM WIP.GL
	--JOURNALS SUM TO: 0.00 

	--	OPENING SUM TO ZERO CHECK
	SELECT SUM(CAST(OPENING AS MONEY)) FROM WIP.TB
	--OPENING SUMS TO: 0.00
	
	--	CLOSING SUM TO ZERO CHECK
	SELECT SUM(CAST(CLOSING AS MONEY)) FROM WIP.TB
	--CLOSING SUMS TO: 0.00

	--	JOURNAL NUMBER SUM TO ZERO CHECK
	SELECT [Journal Entry], SUM(CAST([Balance Company Currency] AS MONEY)) FROM WIP.GL
	GROUP BY [Journal Entry]
	HAVING SUM(CAST([Balance Company Currency] AS MONEY)) <> 0
	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- CREATE A RECONCILIATION TABLE
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	IF OBJECT_ID('[WIP].[Reconciliation]','U') IS NOT NULL DROP TABLE [WIP].[Reconciliation]
	SELECT
	'PX - PX' AS [Financial Period], --<-- CHANGE THIS TO MATCH PERIOD RANGE
	COALESCE(g.Entity,t.Entity) AS [Entity],
	ISNULL(Cast(g.[Account Number] as varchar(100)),'NOT IN GL') AS [GL Account Number],
	ISNULL(g.[Journal Movement EC], 0) AS [Journal Movement EC],
	ISNULL(g.[Line Count],0) AS [Line Count],
	ISNULL(Cast(t.[Account Number] as varchar(100)),'NOT IN TB') AS [TB Account Number],
	ISNULL(t.[Account Description],'') AS [Account Description],
	ISNULL(t.[Period Opening Balance EC],0) AS [Period Opening Balance EC],
	ISNULL(t.[Period Closing Balance EC],0) AS [Period Closing Balance EC],
	ISNULL(t.[Movement EC],0) AS [TB Movement EC],
	ISNULL(g.[Journal Movement EC],0) - ISNULL(t.[Movement EC], 0) AS [Net Difference],
	ABS(ISNULL(g.[Journal Movement EC],0) - ISNULL(t.[Movement EC], 0)) AS [Absolute Difference]
	INTO WIP.Reconciliation
	FROM WIP.GLPivot g
	FULL OUTER JOIN WIP.TBPivot t
	ON g.Entity = t.Entity 
	AND g.[Account Number] = t.[Account Number]
	--(XXX row(s) affected)
	
	SELECT * FROM [WIP].Reconciliation 
	ORDER BY [Absolute Difference] DESC
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- RECONCILIATION INVESTIGATION
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-- PREPARE SPOTLIGHT-READY GENERAL LEDGER TEMPLATE
	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	SELECT * FROM WIP.GL
	
	IF OBJECT_ID('[READY].[GL]','U') IS NOT NULL DROP TABLE [READY].[GL]
	SELECT
	LTRIM(RTRIM([Company desc])) AS [Entity], --<--<-- MANDATORY
	[Company] AS [Company Name], --<-- IF THERE IS NO COMPANY NAME, POPULATE WITH ENTITY
	[Journal Entry] AS [Journal Number], --<--<-- MANDATORY
	NULL AS [Spotlight Type],
	-->
	CONVERT(VARCHAR(10), CAST[Posting Date] AS DATE), (103)) AS [Date Entered], --<--<-- MANDATORY
	NULL AS [Time Entered],
	CONVERT(VARCHAR(10), CAST(NULL AS DATE), (103)) AS [Date Updated],
	NULL AS [Time Updated],
	-->
	LTRIM(RTRIM([Source Document Created By])) AS [UserID Entered],
	LTRIM(RTRIM([Source Document Created By])) AS [Name of User Entered],
	LTRIM(RTRIM(NULL)) AS [UserID Updated],
	LTRIM(RTRIM(NULL)) AS [Name of User Updated],
	-->
	CONVERT(VARCHAR(10), CAST([Posting Date] AS DATE), (103)) AS [Date Effective],  --<--<-- MANDATORY
	CONVERT(VARCHAR(10), CAST(NULL AS DATE), (103)) AS [Date of Journal],
	[Accounting Period] AS [Financial Period],  --<--<-- MANDATORY
	-->
	LTRIM(RTRIM([Journal Entry Type])) AS [Journal Type],
	LTRIM(RTRIM(NULL)) AS [Journal Type Description],
	[Source Doc] AS [Auto Manual or Interface],  --<--<-- MANDATORY
	-->
	LTRIM(RTRIM(REPLACE(REPLACE(REPLACE([Journal Entry Item Text],'|',''),CHAR(10),''),CHAR(13),''))) AS [Journal Description],
	--[Reference Source Document ID] AS [Line Number],
	ROW_NUMBER()OVER(PARTITION BY [Company desc],[Journal Entry]				  --<-- ENTITY, JOURNAL NUMBER
						 ORDER BY [Journal Entry]) AS [Line Number], --<--			JOURNAL NUMBER
	LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(NULL,'|',''),CHAR(10),''),CHAR(13),''))) AS [Line Description],
	-->
	NULL AS [Currency], --<--<-- MANDATORY
	NULL AS [Entity Currency (EC)], --<--<-- MANDATORY
	NULL AS [Exchange Rate],
	-->
	CASE WHEN CAST(NULL AS MONEY) >= 0 THEN 'D' 
		 WHEN CAST(NULL AS MONEY) <  0 THEN 'C' END AS [DC Indicator], --<--<--
	CAST([Balance Transaction Currency] AS MONEY) AS [Signed Journal Amount],  --<--<--
	CASE WHEN CAST([Balance Transaction Currency] AS MONEY) >= 0 THEN     CAST([Balance Transaction Currency] AS MONEY) ELSE 0 END AS [Unsigned Debit Amount], --<--<--
	CASE WHEN CAST([Balance Transaction Currency] AS MONEY)  < 0 THEN ABS(CAST([Balance Transaction Currency] AS MONEY)) ELSE 0 END AS [Unsigned Credit Amount], --<--<--
	CAST([Balance Company Currency] AS MONEY) AS [Signed Amount EC],  --<--<--
	CASE WHEN CAST([Balance Company Currency] AS MONEY) >= 0 THEN     CAST([Balance Company Currency] AS MONEY) ELSE 0 END AS [Unsigned Debit Amount EC], --<--<--
	CASE WHEN CAST([Balance Company Currency] AS MONEY)  < 0 THEN ABS(CAST([Balance Company Currency] AS MONEY)) ELSE 0 END AS [Unsigned Credit Amount EC], --<--<--
	-->
	LTRIM(RTRIM([G/L Account])) AS [Account Number], --<--<--
	LTRIM(RTRIM(REPLACE(REPLACE(REPLACE([G/L Account desc],'|',''),CHAR(10),''),CHAR(13),''))) AS [Account Description],
	-->
	NULL AS [Controlling Area for Cost and Profit Centre],
	[Cost Center] AS [Cost Centre],
	[Cost Center desc] AS [Cost Centre Description],
	NULL AS [Profit Centre],
	NULL AS [Profit Centre Description],
	NULL AS [Source Activity or Transaction Code]
	INTO [READY].[GL]
	FROM WIP.GL
	--(XXX row(s) affected)
	
	SELECT * FROM READY.GL
	
	
	