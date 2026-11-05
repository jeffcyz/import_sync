
DECLARE @DealName NVARCHAR(100) = N'AALC2201';
DECLARE @PaymentDate DATE = '2026-10-15';

;WITH SourceRows AS (
    SELECT
        v.*,
        a.AssetName AS SetupAssetName,
        a.AltAssetName AS SetupAltAssetName,
        d.DealName AS SetupDealName,

        ROW_NUMBER() OVER (
            ORDER BY v.AssetName, v.AssetId
        ) AS rn,

        COUNT_BIG(*) OVER (
            PARTITION BY v.DealId, v.AssetName, v.PaymentDate
        ) AS LookupCount,

        m.ExactCount,
        m.CriteriaCount

    FROM dbo.vwAssetPeriodicMBS AS v

    LEFT JOIN dbo.AssetSetup AS a
        ON a.DealId = v.DealId
       AND a.AssetId = v.AssetId

    LEFT JOIN dbo.DealSetup AS d
        ON d.DealId = v.DealId

    OUTER APPLY (
        SELECT
            COUNT_BIG(
                CASE WHEN s.AssetName = v.AssetName
                     THEN 1 END
            ) AS ExactCount,

            COUNT_BIG(
                CASE WHEN
                    s.AssetName = v.AssetName
                    OR s.AltAssetName = v.AssetName
                    THEN 1 END
            ) AS CriteriaCount

        FROM dbo.AssetSetup AS s
        WHERE s.DealId = v.DealId
          AND (
              s.AssetName = v.AssetName
              OR s.AltAssetName = v.AssetName
          )
    ) AS m

    WHERE v.DealName = @DealName
      AND v.PaymentDate = @PaymentDate
),

Keys AS (
    SELECT
        sr.*,

        CASE
            WHEN sr.SetupAssetName = sr.AssetName
                THEN sr.SetupAssetName
            ELSE COALESCE(
                NULLIF(LTRIM(RTRIM(sr.SetupAltAssetName)), N''),
                sr.SetupAssetName
            )
        END AS MasterKey,

        CONCAT(
            N'["',
            STRING_ESCAPE(
                CONVERT(NVARCHAR(MAX), sr.DealName), 'json'
            ),
            N'","',
            STRING_ESCAPE(
                CONVERT(NVARCHAR(MAX), sr.AssetName), 'json'
            ),
            N'",{"type":"date","value":"',
            CONVERT(
                VARCHAR(19),
                CAST(sr.PaymentDate AS DATETIME2(0)),
                126
            ),
            N'"}]'
        ) AS ProofKey

    FROM SourceRows AS sr
)

SELECT
    q.ProofKey AS [ProofKey],
    q.DealName AS [DealName],
    q.AssetName AS [AssetName],
    CAST(q.PaymentDate AS DATE) AS [PaymentDate],

    q.SetupAssetName AS [Master_RawAssetName],
    q.MasterKey AS [Master_KeyMatchValue],

    CASE
        WHEN q.MasterKey IS NULL THEN NULL
        ELSE CONCAT(N'=', q.MasterKey)
    END AS [Master_KeyCriteria],

    q.ExactCount AS [Master_ExactCount],
    q.CriteriaCount AS [Master_CriteriaCount],
    q.CriteriaCount AS [Master_AllDataCriteriaCount],

    CONVERT(BIT,
        CASE WHEN q.CriteriaCount = 1
               AND q.ExactCount = 1
             THEN 1 ELSE 0 END
    ) AS [Master_ReviewedMatchesOnly],

    CASE WHEN q.CriteriaCount = 1
         THEN q.rn + 1 END AS [Master_MatchRow],

    CASE WHEN q.CriteriaCount = 1
         THEN q.SetupAssetName
    END AS [Master_MatchedAssetName],

    CONVERT(BIT,
        CASE WHEN q.MasterKey = q.AssetName
               AND q.CriteriaCount = 1
             THEN 1 ELSE 0 END
    ) AS [Master_IdentityValid],

    q.SetupDealName AS [Master_MatchedDealName],

    CONVERT(BIT,
        CASE WHEN q.SetupDealName = q.DealName
             THEN 1 ELSE 0 END
    ) AS [Master_ContextValid],

    CASE
        WHEN q.CriteriaCount = 0 THEN 'NOT_FOUND'
        WHEN q.CriteriaCount > 1 THEN 'AMBIGUOUS'
        WHEN q.MasterKey = q.AssetName
         AND q.SetupDealName = q.DealName
            THEN 'MATCHED'
        ELSE 'MISMATCH'
    END AS [Master_Status],

    ISNULL(q.[BegSchBal], 0) AS [BegSchBal],
    ISNULL(q.[Other1], 0) AS [Other1],
    ISNULL(q.[OtherFee1Rate], 0) AS [OtherFee1Rate],
    ISNULL(q.[OtherFee2Rate], 0) AS [OtherFee2Rate],
    ISNULL(q.[Other4], 0) AS [Other4],
    ISNULL(q.[Other5], 0) AS [Other5],
    ISNULL(q.[Other8], 0) AS [Other8],
    ISNULL(q.[Other11], 0) AS [Other11],
    ISNULL(q.[Other14], 0) AS [Other14],
    ISNULL(q.[Other17], 0) AS [Other17],
    ISNULL(q.[Other30], 0) AS [Other30],
    ISNULL(q.[Other31], 0) AS [Other31],
    ISNULL(q.[RecoveredInt], 0) AS [RecoveredInt],

    ISNULL(q.[Other2], 0) AS [Other2],
    ISNULL(q.[Other3], 0) AS [Other3],
    ISNULL(q.[Other6], 0) AS [Other6],
    ISNULL(q.[Other7], 0) AS [Other7],
    ISNULL(q.[Other9], 0) AS [Other9],
    ISNULL(q.[Other10], 0) AS [Other10],
    ISNULL(q.[Other12], 0) AS [Other12],
    ISNULL(q.[Other13], 0) AS [Other13],
    ISNULL(q.[Other15], 0) AS [Other15],
    ISNULL(q.[Other16], 0) AS [Other16],
    ISNULL(q.[Other18], 0) AS [Other18],

    ISNULL(q.[Other32], 0) AS [Other32],
    ISNULL(q.[Other33], 0) AS [Other33],
    ISNULL(q.[Other34], 0) AS [Other34],
    ISNULL(q.[Other35], 0) AS [Other35],
    ISNULL(q.[Other36], 0) AS [Other36],
    ISNULL(q.[Other37], 0) AS [Other37],
    ISNULL(q.[Other38], 0) AS [Other38],
    ISNULL(q.[Other39], 0) AS [Other39],
    ISNULL(q.[Other40], 0) AS [Other40],
    ISNULL(q.[Other41], 0) AS [Other41],
    ISNULL(q.[Other42], 0) AS [Other42],
    ISNULL(q.[Other43], 0) AS [Other43],
    ISNULL(q.[Other44], 0) AS [Other44],
    ISNULL(q.[Other45], 0) AS [Other45],
    ISNULL(q.[Other46], 0) AS [Other46],
    ISNULL(q.[Other47], 0) AS [Other47],
    ISNULL(q.[Other48], 0) AS [Other48],
    ISNULL(q.[Other49], 0) AS [Other49],
    ISNULL(q.[Other50], 0) AS [Other50],
    ISNULL(q.[Other51], 0) AS [Other51],
    ISNULL(q.[Other52], 0) AS [Other52],
    ISNULL(q.[Other53], 0) AS [Other53],
    ISNULL(q.[Other54], 0) AS [Other54],
    ISNULL(q.[Other55], 0) AS [Other55],
    ISNULL(q.[Other56], 0) AS [Other56],
    ISNULL(q.[Other57], 0) AS [Other57],
    ISNULL(q.[Other58], 0) AS [Other58],
    ISNULL(q.[Other59], 0) AS [Other59],
    ISNULL(q.[Other60], 0) AS [Other60],

    ISNULL(q.[ANCI_1], 0) AS [ANCI_1],
    ISNULL(q.[ANCI_2], 0) AS [ANCI_2],
    ISNULL(q.[ANCI_3], 0) AS [ANCI_3],

    q.ProofKey AS [Lookup_KeyCriteria],
    q.LookupCount AS [Lookup_ExactCount],
    q.LookupCount AS [Lookup_CriteriaCount],

    CASE WHEN q.LookupCount = 1
         THEN q.rn + 2
    END AS [Lookup_ValidRow]

FROM Keys AS q
ORDER BY q.AssetName, q.rn;
