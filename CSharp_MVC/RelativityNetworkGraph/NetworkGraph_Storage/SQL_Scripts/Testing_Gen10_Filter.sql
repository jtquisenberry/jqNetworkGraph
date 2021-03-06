	
	DECLARE @SenderEntityID int = 6621
	DECLARE @RecipientEntityID int = 16592
	DECLARE @MaximumParticipants int = 2000000000
	DECLARE @SavedSearch int = -1
	
DECLARE @DatabaseName nvarchar(300) 

	IF @DatabaseName is NULL
	BEGIN
		SELECT @DatabaseName = (SELECT DB_NAME())
	END

	DECLARE @SQL nvarchar(max) = N''
	DECLARE @ScopeQuery nvarchar(max) = N''
	--DECLARE @OptionalQueryRecipient nvarchar(max) = N''
	DECLARE @CountMatchingScopeClauses int = 0
	--DECLARE @CountMatchingRecipientClauses int = 0


	DECLARE @SelectorClauseSender nvarchar(max) = N''
	DECLARE @SelectorClauseRecipient nvarchar(max) = N''
	DECLARE @SelectorClausePair nvarchar(max) = N''

	IF ((@SenderEntityID <= 0) AND (@RecipientEntityID <= 0))
	BEGIN
		SELECT @SelectorClauseSender = N''
		SELECT @SelectorClauseRecipient = N''
		SELECT @SelectorClausePair = N''
	END
	ELSE IF ((@SenderEntityID > 0) AND (@RecipientEntityID <= 0))
	BEGIN
		SELECT @SelectorClauseSender = N'WHERE s_EntityID = ' + CAST(@SenderEntityID as nvarchar(20))
		SELECT @SelectorClauseRecipient = N'WHERE r_EntityID = ' + CAST(@SenderEntityID as nvarchar(20))
		SELECT @SelectorClausePair = N' AND (p1.s_EntityID = ' + CAST(@SenderEntityID as nvarchar(20)) + ' OR p1.r_EntityID = ' + CAST(@SenderEntityID as nvarchar(20)) + ')'
	END
	ELSE IF ((@SenderEntityID <= 0) AND (@RecipientEntityID > 0))
	BEGIN
		SELECT @SelectorClauseSender = N'WHERE s_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20))
		SELECT @SelectorClauseRecipient = N'WHERE r_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20))
		SELECT @SelectorClausePair = N' AND (p1.s_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20)) + ' OR p1.r_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20)) + ')'
	END
	ELSE IF ((@SenderEntityID > 0) AND (@RecipientEntityID > 0))
	BEGIN
		SELECT @SelectorClauseSender = N'WHERE '+ 
			'(s_EntityID = ' + CAST(@SenderEntityID as nvarchar(20)) + ' AND ' + 'r_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20)) + ')' + ' OR ' +
			'(s_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20)) + ' AND ' + 'r_EntityID = ' + CAST(@SenderEntityID as nvarchar(20)) + ')'
		SELECT @SelectorClauseRecipient = N'WHERE '+ 
			'(s_EntityID = ' + CAST(@SenderEntityID as nvarchar(20)) + ' AND ' + 'r_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20)) + ')' + ' OR ' +
			'(s_EntityID = ' + CAST(@RecipientEntityID as nvarchar(20)) + ' AND ' + 'r_EntityID = ' + CAST(@SenderEntityID as nvarchar(20)) + ')'
		SELECT @SelectorClausePair = N' '
	END

	

	if OBJECT_ID('tempdb..#scopeArtifactIDs') is not null drop table #scopeArtifactIDs
	if OBJECT_ID('tempdb..#sender') is not null drop table #sender
	if OBJECT_ID('tempdb..#recipient') is not null drop table #recipient
	if OBJECT_ID('tempdb..#tempSN_Pairs') is not null drop table #tempSN_Pairs

	
	CREATE TABLE #scopeArtifactIDs
	(
		  ArtifactID int
	)
	
	
	CREATE TABLE #sender
	(
		  ArtifactID int
		, EntityID bigint
		, EntityDisplay nvarchar(max)
	)

	CREATE TABLE #recipient
	(
		  ArtifactID int
		, EntityID bigint
		, EntityDisplay nvarchar(max)
	)

	CREATE TABLE #tempSN_Pairs
	(
		  s_EntityID bigint
		, s_EntityDisplay nvarchar(max)
		, r_EntityID bigint
		, r_EntityDisplay nvarchar(max)
		, PairsCount int
	)


	IF @SavedSearch > -1
	BEGIN
		IF @CountMatchingScopeClauses > 0
		BEGIN
			
			SELECT @ScopeQuery = @ScopeQuery + N'

				INTERSECT
			'
		END
		
		SELECT @CountMatchingScopeClauses = @CountMatchingScopeClauses + 1

		SELECT @ScopeQuery =  @ScopeQuery +  N'
			SELECT DISTINCT ArtifactID
			FROM #SavedSearchDocuments
		'

	END

	
	IF ((@SenderEntityID > -1) AND (@RecipientEntityID <= -1))
	BEGIN
		IF @CountMatchingScopeClauses > 0
		BEGIN
			
			SELECT @ScopeQuery = @ScopeQuery + N'

				INTERSECT
			'
		END		
		
		SELECT @CountMatchingScopeClauses = @CountMatchingScopeClauses + 1

		SELECT @ScopeQuery =  @ScopeQuery +  N'
			SELECT DISTINCT ArtifactID
			FROM simple_SocialNetwork
			WHERE EntityID = '+CAST(@SenderEntityID as nvarchar(10))+'
				
		'
	END

	IF ((@RecipientEntityID > -1) AND (@SenderEntityID <= -1))
	BEGIN
		IF @CountMatchingScopeClauses > 0
		BEGIN
			
			SELECT @ScopeQuery = @ScopeQuery + N'

				INTERSECT
			'
		END		
		
		SELECT @CountMatchingScopeClauses = @CountMatchingScopeClauses + 1

		SELECT @ScopeQuery =  @ScopeQuery +  N'
			SELECT DISTINCT ArtifactID
			FROM simple_SocialNetwork
			WHERE EntityID = '+CAST(@RecipientEntityID as nvarchar(10))+'
				
		'
	END

	-- Two Entities Specified
	IF ((@SenderEntityID > -1) AND (@RecipientEntityID > -1))
	BEGIN
		IF @CountMatchingScopeClauses > 0
		BEGIN
			
			SELECT @ScopeQuery = @ScopeQuery + N'

				INTERSECT
			'
		END		
		
		SELECT @CountMatchingScopeClauses = @CountMatchingScopeClauses + 1

		SELECT @ScopeQuery =  @ScopeQuery +  N'
			SELECT ArtifactID
			FROM
			(
				(
					SELECT ArtifactID
					FROM simple_SocialNetwork
					WHERE EntityID ='+CAST(@SenderEntityID as nvarchar(10))+'
						AND EntityType = 1.00
					INTERSECT
					SELECT ArtifactID
					FROM simple_SocialNetwork
					WHERE EntityID ='+CAST(@RecipientEntityID as nvarchar(10))+'
						AND EntityType > 1.00
				) 
				UNION
				(
					SELECT ArtifactID
					FROM simple_SocialNetwork
					WHERE EntityID ='+CAST(@RecipientEntityID as nvarchar(10))+'
						AND EntityType = 1.00
					INTERSECT
					SELECT ArtifactID
					FROM simple_SocialNetwork
					WHERE EntityID ='+CAST(@SenderEntityID as nvarchar(10))+'
						AND EntityType > 1.00
				)
			) documentsfrompairs
		'
	END


	
	IF @MaximumParticipants < 2000000000
	BEGIN
		IF @CountMatchingScopeClauses > 0
		BEGIN
			
			SELECT @ScopeQuery = @ScopeQuery + N'

				INTERSECT
			'
		END
		
		SELECT @CountMatchingScopeClauses = @CountMatchingScopeClauses + 1

		SELECT @ScopeQuery =  @ScopeQuery +  N'
			SELECT ArtifactID
			FROM simple_SocialNetwork 
			GROUP BY ArtifactID
			HAVING COUNT(DISTINCT EntityID) <= '+CAST(@MaximumParticipants as nvarchar(10))+'
			-- Must use DISTINCT, otherwise To/Cc/Bcc will be double-counted by Recipients
		'

	END


	SELECT @SQL = 
	N'
	INSERT INTO #scopeArtifactIDs (ArtifactID)
	SELECT ArtifactID
	FROM ('+
	@ScopeQuery
	+') scope
	'

	print @sql
	EXECUTE sp_executeSQL @SQL

	
	SELECT @SQL = 
	N'	
	INSERT INTO #sender (ArtifactID, EntityID, EntityDisplay)
	SELECT dds.artifactid, dds.EntityID, el.EntityDisplay
	FROM
	(
		SELECT DISTINCT sn.artifactid, sn.EntityID 
		FROM
		#scopeArtifactIDs sn2 JOIN '+@DatabaseName+'.dbo.simple_SocialNetwork sn
		ON sn2.artifactid = sn.artifactid
		WHERE sn.EntityID is NOT NULL
			AND sn.EntityType = 1.0
	) dds -- Distinct Document-Senders
	JOIN '+@DatabaseName+'.dbo.simple_EntityList el ON dds.EntityID = el.EL_ID
	WHERE el.EntityName <> ''null'' 
		AND el.EntityName > ''''
	'

	print @sql
	EXECUTE sp_executeSQL @SQL

	SELECT @SQL = 
	N'
	INSERT INTO #recipient (ArtifactID, EntityID, EntityDisplay)
	SELECT dds.artifactid, dds.EntityID, el.EntityDisplay
	FROM
	(
		SELECT DISTINCT sn.artifactid, sn.EntityID 
		FROM
		#scopeArtifactIDs sn2 JOIN '+@DatabaseName+'.dbo.simple_SocialNetwork sn
		ON sn2.artifactid = sn.artifactid
		WHERE sn.EntityID is NOT NULL
			AND sn.EntityType in (2.1, 2.2, 2.3, 4.0)
	) dds -- Distinct Document-Recipients
	JOIN '+@DatabaseName+'.dbo.simple_EntityList el ON dds.EntityID = el.EL_ID
	WHERE el.EntityName <> ''null'' 
		AND el.EntityName > ''''
	'

	print @sql
	EXECUTE sp_executeSQL @SQL



	/***********************/
	-- Insert Into Pairs
	/***********************/
	INSERT INTO #tempSN_Pairs (s_EntityID, s_EntityDisplay, r_EntityID, r_EntityDisplay, PairsCount)
	SELECT  
		  s.EntityID as s_EntityID
		, s.EntityDisplay as s_EntityDisplay
		, r.EntityID as r_EntityID
		, r.EntityDisplay as r_EntityDisplay
		, COUNT(*) as PairsCount
	FROM #sender s
	JOIN #recipient r ON s.ArtifactID = r.ArtifactID
	GROUP BY s.EntityID, s.EntityDisplay, r.EntityID, r.EntityDisplay



	-- Results Set #1
	--SELECT TOP 10 s_EntityID = EntityID, s_EntityDisplay = EntityDisplay, theCount = COUNT(*) FROM #sender GROUP BY EntityID, EntityDisplay ORDER BY COUNT(*) DESC

	-- Zero entities selected OR two entities selected
	IF ((@SenderEntityID <= 0) AND (@RecipientEntityID <= 0)) OR ((@SenderEntityID > 0) AND (@RecipientEntityID > 0))
	BEGIN
		SELECT @Sql = N'
			SELECT TOP 10 EntityID as s_EntityID, EntityDisplay as s_EntityDisplay, COUNT(*) as theCount
			FROM #sender
			GROUP BY EntityID, EntityDisplay
			ORDER BY COUNT(*) DESC, s_EntityDisplay ASC
		'
	END
	-- One entity selected  GOOD. Same results as selecting 6621 in Generation10
	ELSE IF ((@SenderEntityID > 0) OR (@RecipientEntityID > 0)) AND NOT ((@SenderEntityID > 0) AND (@RecipientEntityID > 0))
	BEGIN
		SELECT @Sql = N'
			SELECT TOP 10 s_EntityID, s_EntityDisplay, theCount = PairsCount
			FROM #tempSN_Pairs 
			'+@SelectorClauseRecipient+' 
			ORDER BY PairsCount DESC, s_EntityDisplay ASC
		'
	END
	
	print @sql	
	EXECUTE sp_executesql @Sql






















	/*
	SELECT TOP 10 s_EntityID, s_EntityDisplay, theCount = PairsCount
			FROM #tempSN_Pairs 
			WHERE r_EntityID = @SenderEntityID
			ORDER BY PairsCount DESC
			*/


	-- Results Set #2
	--SELECT TOP 10 r_EntityID = EntityID, r_EntityDisplay = EntityDisplay, theCount = COUNT(*) FROM #recipient GROUP BY EntityID, EntityDisplay ORDER BY COUNT(*) DESC

	/*
	SELECT r.r_EntityID, el.EntityDisplay as r_EntityDisplay, r.theCount
	FROM
	(
		SELECT TOP 10 r_EntityID = EntityID, theCount = COUNT(*) 
		FROM #recipient 
		GROUP BY EntityID ORDER BY COUNT(*) DESC
	) r JOIN simple_EntityList el ON r.r_EntityID = el.EL_ID
	*/

	IF ((@SenderEntityID <= 0) AND (@RecipientEntityID <= 0)) OR ((@SenderEntityID > 0) AND (@RecipientEntityID > 0))
	BEGIN
		SELECT @Sql = N'
			SELECT TOP 10 EntityID as r_EntityID, EntityDisplay as r_EntityDisplay, COUNT(*) as theCount
			FROM #recipient
			GROUP BY EntityID, EntityDisplay
			ORDER BY COUNT(*) DESC, r_EntityDisplay ASC
		'
	END
	ELSE
	BEGIN
		SELECT @Sql = N'
			SELECT TOP 10 r_EntityID, r_EntityDisplay, theCount = PairsCount 
			FROM #tempSN_Pairs
			'+@SelectorClauseSender+'
			ORDER BY PairsCount DESC, r_EntityDisplay ASC
		'
	END
		

	EXECUTE sp_executesql @Sql



	-- Results Set #3
	--SELECT TOP 10 * FROM #tempSN_Pairs ORDER BY PairsCount DESC

	/*
	SELECT @Sql = N'
	SELECT TOP 10
			p1.s_EntityID
		, p1.s_EntityDisplay
		, p1.r_EntityID
		, p1.r_EntityDisplay
		, ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) as PairsCount
	FROM #tempSN_Pairs p1
	LEFT JOIN #tempSN_Pairs p2 ON p1.s_EntityID = p2.r_EntityID AND p1.r_EntityID = p2.s_EntityID
	WHERE ((ISNULL(p1.PairsCount, 0) > ISNULL(p2.PairsCount, 0)) OR ((ISNULL(p1.PairsCount, 0) = ISNULL(p2.PairsCount, 0)) AND p1.s_EntityID < p2.s_EntityID))
	ORDER BY ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) DESC
	'
	EXECUTE sp_executesql @Sql

	*/


	/*
	SELECT TOP 10
			p1.s_EntityID
		, p1.s_EntityDisplay
		, p1.r_EntityID
		, p1.r_EntityDisplay
		, ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) as PairsCount
	FROM #tempSN_Pairs p1
	LEFT JOIN #tempSN_Pairs p2 ON p1.s_EntityID = p2.r_EntityID AND p1.r_EntityID = p2.s_EntityID
	WHERE ((ISNULL(p1.PairsCount, 0) > ISNULL(p2.PairsCount, 0)) OR ((ISNULL(p1.PairsCount, 0) = ISNULL(p2.PairsCount, 0)) AND p1.s_EntityID < p2.s_EntityID))
	ORDER BY ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) DESC
	*/

	SELECT @Sql = N'
		SELECT TOP 10
			  p1.s_EntityID
			, p1.s_EntityDisplay
			, p1.r_EntityID
			, p1.r_EntityDisplay
			, ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) as PairsCount
		FROM #tempSN_Pairs p1
		LEFT JOIN #tempSN_Pairs p2 ON p1.s_EntityID = p2.r_EntityID AND p1.r_EntityID = p2.s_EntityID
		WHERE ((ISNULL(p1.PairsCount, 0) > ISNULL(p2.PairsCount, 0)) OR ((ISNULL(p1.PairsCount, 0) = ISNULL(p2.PairsCount, 0)) AND p1.s_EntityID < p2.s_EntityID))
			'+@SelectorClausePair+'
		ORDER BY ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) DESC, p1.s_EntityDisplay ASC, p1.r_EntityDisplay ASC
	'

	print @sql
	EXECUTE sp_executesql @Sql



















	


	-- Results Set #4
	SELECT @Sql = N'
		; with cteTopCommunicators as
		(
			SELECT TOP 20
				  p1.s_EntityID as p1_s_EntityID
				, p1.s_EntityDisplay as p1_s_EntityDisplay
				, p1.r_EntityID as p1_r_EntityID
				, p1.r_EntityDisplay as p1_r_EntityDisplay
				, p1.PairsCount as p1_PairsCount
				, p2.s_EntityID as p2_s_EntityID
				, p2.s_EntityDisplay as p2_s_EntityDisplay
				, p2.r_EntityID as p2_r_EntityID
				, p2.r_EntityDisplay as p2_r_EntityDisplay
				, p2.PairsCount as p2_PairsCount
				, ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) as  p2_PairsCount2
			FROM #tempSN_Pairs p1
			LEFT JOIN #tempSN_Pairs p2 ON p1.s_EntityID = p2.r_EntityID AND p1.r_EntityID = p2.s_EntityID
			WHERE ((ISNULL(p1.PairsCount, 0) > ISNULL(p2.PairsCount, 0)) OR ((ISNULL(p1.PairsCount, 0) = ISNULL(p2.PairsCount, 0)) AND p1.s_EntityID < p2.s_EntityID))
				'+@SelectorClausePair+'
			ORDER BY ISNULL(p1.PairsCount, 0) + ISNULL(p2.PairsCount, 0) DESC
		)

		SELECT 
			  p1_s_EntityID as s_EntityID
			, p1_s_EntityDisplay as s_EntityDisplay
			, p1_r_EntityID as r_EntityID
			, p1_r_EntityDisplay as r_EntityDisplay
			, p1_PairsCount as PairsCount
			, ''sender'' as theRole
		FROM cteTopCommunicators
		UNION ALL
		SELECT 
			  p2_r_EntityID
			, p2_r_EntityDisplay
			, p2_s_EntityID
			, p2_s_EntityDisplay
			, p2_PairsCount
			, ''recipient'' as theRole
		FROM cteTopCommunicators
		WHERE p2_s_EntityID is NOT NULL
		ORDER BY PairsCount DESC, s_EntityDisplay ASC, r_EntityDisplay ASC
	'

	--Print(@Sql)
	EXECUTE sp_executesql @Sql



		
