/**
 * Wyznaczanie kwoty do podzia³u
 * Za³o¿enie
 * Kwota do podzia³u (K) = 2/3 * (suma op³at naliczonych w danym kwartale zgodnie z ppkt 6.5.1.1., 6.5.1.2., 6.5.1.3 T.O) 
 * + 4/5 * (suma op³at naliczonych w danym kwartale zgodnie z ppkt 6.5.3).
*/
SELECT * FROM openquery(NSDRTEST, '
WITH CTE_FEE AS (
	SELECT BGNDATE, ENDDATE, CHRCD, SUM(FEEAMT) AS AMT FROM ( 
		SELECT bgndate,enddate,chrcd,feeamt FROM MOPLDEV.FSIDFEE0F
		UNION ALL
		SELECT bgndate,enddate,chrcd,feeamt FROM MOPLDEV.HSIDFEE0F) AS fee
	WHERE (fee.CHRCD LIKE ''E6.5.1%''OR fee.CHRCD =''E6.5.3'')
	AND fee.bgndate >=  ''2020-10-01''  AND fee.endDate <=  ''2020-10-31''
	GROUP BY BGNDATE, ENDDATE, CHRCD order by bgndate,enddate)	
	,
CTE_FEE_E651 AS(
	SELECT fee.bgndate,fee.enddate, sum(COALESCE(amt,0)) as totalamt, (sum(COALESCE(amt,0))) * CAST((2./3.) as double) AS amount FROM CTE_FEE fee
	WHERE fee.CHRCD LIKE ''E6.5.1%''
	GROUP BY fee.bgndate,fee.enddate
	),
CTE_FEE_E653 AS(
	SELECT fee.bgndate,fee.enddate, sum(COALESCE(amt,0)) as totalamt, sum(COALESCE(amt,0)) * cast((4./5.) as double) AS amount FROM CTE_FEE fee
	WHERE fee.CHRCD = ''E6.5.3''
	GROUP BY fee.bgndate,fee.enddate
	),
CTE_FEE_TOTAL AS(	
	select sum(fee.amount) from (
	SELECT fee.amount FROM CTE_FEE_E651 fee	
	UNION ALL
	SELECT fee.amount FROM CTE_FEE_E653 fee) as fee
	)

	SELECT * FROM CTE_FEE_TOTAL tot')