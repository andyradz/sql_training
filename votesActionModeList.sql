
		WITH CTE_ISIN AS (
			SELECT DISTINCT
				fin.eligdt,
				fin.isin,
				fin.fintp,
				fin.cfi 
			FROM MLBDDEV.FFINSTR0L0 fin 
			ORDER BY eligdt DESC                        
		),
		CTE_VTR AS (
			SELECT DISTINCT 
				fin.eligdt,
				fin.isin,
				fin.vtngratio
			FROM MECADEV.FMEPVTR0f fin 
			ORDER BY fin.eligdt DESC                        
		),
		CTE_VOTE AS (
			SELECT DISTINCT
				vot.CAREF,
				vot.MSGID, 
				vot.INSID, 
				vot.VOTEID,
				CASE
					WHEN LOCATE('(PL)',vot.ISSLABEL) > 0 THEN SUBSTR(vot.ISSLABEL, 1, LOCATE(' (PL)', TRIM(vot.ISSLABEL)))
					WHEN LOCATE('(EN)',vot.ISSLABEL) > 0 THEN SUBSTR(vot.ISSLABEL, 1, LOCATE(' (EN)', TRIM(vot.ISSLABEL)))
					ELSE TRIM(vot.ISSLABEL)
				END AS IssrLabl, 
				vot.VOTETP, 
				vot.VOTEQTY,
				vot.VOTECD
			FROM 
				MECADEV.FMEPINS4L0 vot
			WHERE TRIM(vot.ISSLABEL) != ''
			UNION
			SELECT DISTINCT
				vot.CAREF,
				vot.MSGID, 
				vot.INSID, 
				vot.VOTEID,
				'Nowe uchwa³y walnego zgromadzenia' AS IssrLabl, 			
				vot.VOTETP, 
				dtl.qty AS VOTEQTY,
				vot.VOTECD
			FROM 
			MECADEV.FMEPINS4L0 vot
			LEFT JOIN MECADEV.FMEPINS1L0 dtl
				ON  vot.caRef = dtl.caRef
				AND vot.msgId = dtl.msgId
				AND vot.insId = dtl.insId

			WHERE TRIM(vot.ISSLABEL) = '' 
				AND dtl.sts = '30'
		)				
			SELECT 
				TRIM(data.CAREF) AS caRef,
				TRIM(data.msgId) AS msgId,
				TRIM(data.insId) AS insId,				
				TRIM(data.IssrLabl) AS IssrLabl,
				TRIM(CAST(SUM(COALESCE(data.TtlNbOfVotes, 0)) AS CHAR(18))) AS TtlNbOfVotes,
				TRIM(CAST(SUM(COALESCE(data.TtlNbOfVotesFor, 0)) AS CHAR(18))) AS TtlNbOfVotesFor,
				TRIM(CAST(SUM(COALESCE(data.TtlNbOfVotesAgnst, 0)) AS CHAR(18))) AS TtlNbOfVotesAgnst,
				TRIM(CAST(SUM(COALESCE(data.TtlNbOfVotesAbstn, 0)) AS CHAR(18))) AS TtlNbOfVotesAbstn,	
				TRIM(CAST(data.KDPWBNFID AS CHAR(18))) AS KDPWBNFID,
				TRIM(data.IDNTYCRDNB) AS IDNTYCRDNB,
				TRIM(data.RghtsHldrNm) AS RghtsHldrNm,                    	          
				TRIM(CAST(SUM(COALESCE(data.NbOfScties, 0)) AS CHAR(18))) AS NbOfScties,
				TRIM(CAST(SUM(COALESCE(data.NbOfVotes, 0)) AS CHAR(18))) AS NbOfVotes,
				TRIM(CAST(SUM(COALESCE(data.NbOfVotesFor, 0)) AS CHAR(18))) AS NbOfVotesFor,          
				TRIM(CAST(SUM(COALESCE(data.NbOfVotesAgnst, 0)) AS CHAR(18))) AS NbOfVotesAgnst,
				TRIM(CAST(SUM(COALESCE(data.NbOfVotesAbstn, 0)) AS CHAR(18))) AS NbOfVotesAbstn,
				data.shldId,
				data.eligdt,
				data.factor,
				data.isin 
				FROM (		
					SELECT DISTINCT          
						hdr.CAREF,
						dtl.msgId,
						dtl.insId,				
						TRIM(vot.IssrLabl) AS IssrLabl,
						qtyall.qty AS TtlNbOfVotes,
						qtyfor.qty AS TtlNbOfVotesFor,
						qtyags.qty AS TtlNbOfVotesAgnst,
						qtybst.qty AS TtlNbOfVotesAbstn,	
						TRIM(dtl.KDPWBNFID) AS KDPWBNFID,
						TRIM(TRIM(shd.SHLDNM) || ' ' ||  TRIM(shd.SHLDSURNM) || ' ' || TRIM(shd.SHLDFRSTNM)) AS RghtsHldrNm,                    	          
						TRIM(dtl.IDNTYCRDNB) AS IDNTYCRDNB,
						qty.qty AS NbOfScties,
						QTYALL1.qty *  (CASE WHEN finstr.factor <> -1 THEN finstr.factor ELSE vtr.factor END)    AS NbOfVotes,
						qtyall2.qty * (CASE WHEN finstr.factor <> -1 THEN finstr.factor ELSE vtr.factor END) AS NbOfVotesFor,          
						qtyall3.qty * (CASE WHEN finstr.factor <> -1 THEN finstr.factor ELSE vtr.factor END) AS NbOfVotesAgnst,
						qtyall4.qty * (CASE WHEN finstr.factor <> -1 THEN finstr.factor ELSE vtr.factor END) AS NbOfVotesAbstn,
						shd.shldId,
						--finstr.eligdt,
						--finstr.factor,
						--finstr.isin	            
						vtr.eligdt,
						vtr.factor,
						vtr.isin	            							

					FROM MECADEV.FMEPINS0L0 hdr         
					
					INNER JOIN MECADEV.FMEDHDR0L0 nag
						ON nag.caRef = hdr.caRef
	
					INNER JOIN MECADEV.FMEPINS1L0 dtl
						ON hdr.caRef = dtl.caRef
						AND hdr.msgId = dtl.msgId			    
					
					INNER JOIN CTE_VOTE vot
						ON vot.caRef = dtl.caRef
						AND vot.msgId = dtl.msgId
						AND vot.insid = dtl.insid 	  									       

					INNER JOIN (
						SELECT 	
							shdi.caref,
							shdi.msgid,
							shdi.insid,
							shdi.shldnm,
							shdi.shldsurnm,
							shdi.shldfrstnm,
							MIN(shdi.shldId) as shldId
						FROM MECADEV.FMEPINS2L0 shdi
						WHERE shdi.shldId = (
							SELECT MIN(shdo.SHLDID) AS shldid
							FROM MECADEV.FMEPINS2L0 shdo
							WHERE shdo.caRef = shdi.caRef
								AND shdo.msgid = shdi.msgid 
								AND shdo.insid = shdi.insid  									 
						) 	
						GROUP BY
							shdi.caref,
							shdi.msgid,
							shdi.insid,
							shdi.SHLDNM,
							shdi.shldsurnm,
							shdi.shldfrstnm) AS shd          		
						ON dtl.caRef = shd.caRef 
						AND dtl.msgId = shd.msgId      
						AND dtl.insid = shd.insid
						
						LEFT JOIN (
							SELECT
								fin.isin,
								fin.eligdt,
								CASE
							   		WHEN fin.finTp IN('ESB','ESF','ESR') AND length(fin.cfi) >= 3 AND (SUBSTRING(fin.cfi,3,1) ='N' OR SUBSTRING(fin.cfi,3,1) ='n') THEN -1	
							   		WHEN fin.finTp IN('ESB', 'ESF') THEN -1								
							   		ELSE -1
								END AS factor									
							FROM CTE_ISIN fin 
							) AS finstr
								ON finstr.isin = hdr.isin 
								AND finstr.eligdt = (SELECT MAX(eligdt) FROM CTE_ISIN WHERE isin = finstr.isin AND eligdt <= nag.rcdDt)

						LEFT JOIN (
							SELECT 
								vtr.isin,
								vtr.eligdt,
								vtr.VTNGRATIO AS factor
							FROM
								CTE_VTR vtr
						) AS vtr
							ON vtr.isin = hdr.isin 
							AND vtr.eligdt = (SELECT MAX(eligdt) FROM CTE_VTR WHERE isin = vtr.isin AND eligdt <='2021-02-04')		
						
					LEFT JOIN (
						SELECT
							d4.caRef,
							d4.IssrLabl, 
							SUM(d4.VOTEQTY) AS QTY
						FROM CTE_VOTE d4
						INNER JOIN MECADEV.FMEPINS1L0 d1
							ON  d1.caref = d4.caref 
							AND d1.msgid = d4.msgid 
							AND d1.insid = d4.insid
						WHERE d4.voteTp <> '' AND d1.sts = '30'
						GROUP BY d4.caRef, d4.IssrLabl
					) AS QTYALL
						ON  QTYALL.caRef = dtl.caRef
							AND QTYALL.IssrLabl = vot.IssrLabl								  	            										  	            						
	
					LEFT JOIN (
						SELECT
							d4.caRef, 
							d4.IssrLabl,
							SUM(d4.VOTEQTY) AS QTY 
						FROM CTE_VOTE d4
						INNER JOIN MECADEV.FMEPINS1L0 d1
							ON  d1.caref = d4.caref 
							AND d1.msgid = d4.msgid 
							AND d1.insid = d4.insid
						WHERE d4.VOTETP = 'CFOR' AND d1.sts = '30'
						GROUP BY d4.caRef, d4.IssrLabl
					) AS QTYFOR
						ON QTYFOR.caRef = dtl.caRef          						  	  
							AND QTYFOR.IssrLabl = vot.IssrLabl

					LEFT JOIN (
						SELECT 
							d4.caRef, 
							d4.IssrLabl,
							SUM(d4.VOTEQTY) AS QTY 
						FROM CTE_VOTE d4
						INNER JOIN MECADEV.FMEPINS1L0 d1
							ON  d1.caref = d4.caref 
							AND d1.msgid = d4.msgid 
							AND d1.insid = d4.insid
						WHERE d4.VOTETP = 'CAGS' AND d1.sts = '30'
						GROUP BY d4.caRef, d4.IssrLabl
					) AS QTYAGS 
						ON QTYAGS.caRef = dtl.caRef 				  
						AND QTYAGS.IssrLabl = vot.IssrLabl
	
					LEFT JOIN (
						SELECT 
							d4.caRef, 
							d4.IssrLabl,
							SUM(d4.VOTEQTY) AS QTY
						FROM CTE_VOTE d4
						INNER JOIN MECADEV.FMEPINS1L0 d1
							ON  d1.caref = d4.caref 
							AND d1.msgid = d4.msgid 
							AND d1.insid = d4.insid
						WHERE d4.VOTETP = 'ABST' AND d1.sts = '30'
						GROUP BY d4.caRef, d4.IssrLabl
						) AS QTYBST 
						ON QTYBST.caRef = dtl.caRef        		   				
						AND QTYBST.IssrLabl = vot.IssrLabl

					LEFT JOIN (
						SELECT d4.caRef, d4.msgid, d4.insid, d4.IssrLabl, SUM(d4.VOTEQTY) AS QTY
						FROM CTE_VOTE d4
						INNER JOIN MECADEV.FMEPINS1L0 d1
							ON  d1.caref = d4.caref 
							AND d1.msgid = d4.msgid 
							AND d1.insid = d4.insid
						WHERE d4.voteTp <> '' AND d1.sts = '30'
						GROUP BY d4.caRef, d4.msgid, d4.insid, d4.IssrLabl
						) AS QTYALL1
						ON  QTYALL1.caRef = dtl.caRef
						AND QTYALL1.msgid = dtl.msgid 
						AND QTYALL1.insid = dtl.insid
						AND QTYALL1.IssrLabl = vot.IssrLabl
	
					LEFT JOIN (
						SELECT caRef, msgid, insid, IssrLabl, VOTEQTY AS QTY FROM CTE_VOTE
						WHERE VOTETP = 'CFOR'        		
						) AS QTYALL2
						ON QTYALL2.caRef = dtl.caRef
						AND QTYALL2.msgid = dtl.msgid 
						AND QTYALL2.insid = dtl.insid 
						AND QTYALL2.IssrLabl = vot.IssrLabl
	
					LEFT JOIN (
						SELECT caRef, msgid, insid, IssrLabl, VOTEQTY AS QTY FROM CTE_VOTE 
						WHERE VOTETP = 'CAGS'        		
						) AS QTYALL3
						ON QTYALL3.caRef = dtl.caRef
						AND QTYALL3.msgid = dtl.msgid 
						AND QTYALL3.insid = dtl.insid 
						AND QTYALL3.IssrLabl = vot.IssrLabl
	
					LEFT JOIN (
						SELECT caRef, msgid, insid, IssrLabl, VOTEQTY AS QTY FROM CTE_VOTE
						WHERE VOTETP = 'ABST'        		
						) AS QTYALL4
						ON QTYALL4.caRef = dtl.caRef
						AND QTYALL4.msgid = dtl.msgid 
						AND QTYALL4.insid = dtl.insid 
						AND QTYALL4.ISSRLABL = vot.ISSRLABL
	
					LEFT JOIN (
						SELECT caRef, msgid,insid, SUM(QTY) AS QTY FROM MECADEV.FMEPINS1L0 
						GROUP BY caRef,msgid,insid
						) AS QTY
						ON QTY.caRef = dtl.caRef
						AND QTY.msgid = dtl.msgid	
						AND QTY.insid = dtl.insid
			
					WHERE hdr.caRef = '4100GMET20083013' 
						AND 
						vot.voteTp  <> ''						
						AND dtl.sts     = '30')
						AS DATA	

				WHERE (data.NbOfVotesFor > 0 OR data.NbOfVotesAgnst > 0 OR data.NbOfVotesAbstn > 0)						

				GROUP BY
					data.caref,
					data.msgId,
					data.insId,				
					data.IssrLabl,			
					data.kdpwbnfid,
					data.idntycrdnb,
					data.rghtsHldrNm,                	          												
					data.shldId,
					data.eligdt,
					data.factor,
					data.isin
			order by data.caref desc