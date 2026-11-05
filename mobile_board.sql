let
    Config = Excel.CurrentWorkbook(){
        [Name="tblASAP_SQL_Config"]
    }[Content],

    DealName = Text.From(Config{0}[DealName]),
    PaymentDate = Date.From(Config{0}[PaymentDate]),

    Source = Sql.Database(
        "YOUR_SQL_SERVER",
        "ASAP"
    ),

    SQL = "
        WITH SourceRows AS (
            -- 放入原 SQL 的完整 CTE
        )
        -- 放入原 SQL 的 Keys CTE
        -- 以及完整的 77 列 SELECT
    ",

    Result = Value.NativeQuery(
        Source,
        SQL,
        [
            DealName = DealName,
            PaymentDate = PaymentDate
        ]
    )
in
    Result
