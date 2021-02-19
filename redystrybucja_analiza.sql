SELECT * FROM openquery(NSDRTEST, '
 SELECT DISTINCT 
		m2.sidRef, 
	    m2.rspMsgId,  
	    SUBSTR(m2.accSrvAcc, 1, 4) AS realSndr, 
	    rpt.isin, 
	    m0.rcvDt, 
			r.lei, 
			 rpt.coaf,
                 COUNT(1) AS liczbaPosiadaczy 
                  FROM msiddev.FSIMSGR2l0 m2  
                  JOIN msiddev.FSIMSGR0l0 m0 ON 
                  m2.rspMsgId = m0.msgId 
                  AND m0.sndr = SUBSTR(m2.dsclAcc, 1, 4) 
                  AND m2.sidRef = m0.sidRef  
                  AND m0.recSts = ''A''  
                  LEFT JOIN (SELECT sidref,isin,rptDt,recSts,fwdReqInd,coaf 
                       FROM mopldev.FSIDMSG0F 
                       UNION ALL 
                        SELECT sidref,isin,rptDt,recSts,fwdReqInd,coaf 
                        FROM mopldev.HsidMSG0F m0) AS rpt 
                  ON rpt.sidRef = m2.sidRef                  
                 
                  AND rpt.recSts = ''A''  
                  AND (UPPER(rpt.fwdReqInd)=''Y'' OR rpt.fwdReqInd=''1'' ) 
                  JOIN msrddev.FINSTIT0F i ON  
                  i.id = SUBSTR(m2.accSrvAcc, 1, 4) 
                  AND i.recSts = ''A''  
                  AND i.eligDt = (SELECT MAX(eligDt)  
                  FROM msrddev.FINSTIT0F  
                  WHERE id = i.id  
                  AND recSts = ''A''  
                  AND eligDt <= rpt.rptDt)  
                  JOIN mlbddev.FREGCON0F r ON  
                  r.id = i.contrId  
                  AND r.recSts = ''A''  
                  AND r.eligDt = (SELECT MAX(eligDt)  
                  FROM mlbddev.FREGCON0F  
                  WHERE id = r.id  
                  AND recSts = ''A''  
                  AND eligDt <= rpt.rptDt)  
                 
                  WHERE m2.recSts =''A'' --and rpt.rptDt between ''2020-09-01'' and ''2020-09-30''
                  --AND m0.sndr <> ''0001'' 
                  AND m2.sts IN (''36'', ''50'', ''00'', ''37'')  
					--and m2.sidref=''0000000000000896''
                  GROUP BY  
                  m2.sidRef,  
                  m2.rspMsgId, 
                  m2.accSrvAcc, 
                  rpt.isin, 
                  m0.rcvDt, 
                  r.lei ,
				  rpt.coaf
				  

')

--a.	zosta³ zg³oszony przez uczestnika KDPW (sprawdziæ czy wystêpuje w bazie instytucji identyfikator uczestnika)
--b.	zosta³ zg³oszony w instrukcji wys³anej w record date + 1
--c.	instrukcja w której zosta³ zg³oszony zosta³a zaakceptowana przez KDPW 
--d.	zosta³ zg³oszony w ramach kont prowadzonych w KDPW (przypadek RBI , który zg³asza te¿ posiadaczy na kontach u poœredników)

SELECT * FROM openquery(NSDRTEST, 'select * from msiddev.FSIMSGR2l0 m2 where m2.sidref = ''0000000000000900'' 
--and rspnmbrlei =''259400L3KBYEVNHEJF55'' 
and m2.accSrvLei = ''259400L3KBYEVNHEJF55''
--and reportver=''1'' 
AND accsrvlei = ''259400L3KBYEVNHEJF55'' 
--and accsrvacc like ''0954%''
order by rspmsgid
')