begin;
    
        
        
        delete from FAR_TRANS_DB.marts.mart_asset_performance_incremental as DBT_INTERNAL_DEST
        where (isin) in (
            select distinct isin
            from FAR_TRANS_DB.marts.mart_asset_performance_incremental__dbt_tmp as DBT_INTERNAL_SOURCE
        );

    

    insert into FAR_TRANS_DB.marts.mart_asset_performance_incremental ("ISIN", "ASSET_NAME", "ASSET_CATEGORY", "ASSET_SUB_CATEGORY", "SECTOR", "INDUSTRY", "MARKET_ID", "FIRST_TRADING_DATE", "LAST_TRADING_DATE", "TOTAL_TRADING_DAYS", "MIN_PRICE", "MAX_PRICE", "AVG_PRICE", "PRICE_STDDEV", "AVG_DAILY_RETURN", "DAILY_VOLATILITY", "MIN_DAILY_RETURN", "MAX_DAILY_RETURN", "TOTAL_RETURN", "POSITIVE_DAYS", "NEGATIVE_DAYS", "NEUTRAL_DAYS", "WIN_RATE", "SHARPE_RATIO_DAILY", "ASSET_CLASS", "VOLATILITY_CATEGORY", "LAST_UPDATED")
    (
        select "ISIN", "ASSET_NAME", "ASSET_CATEGORY", "ASSET_SUB_CATEGORY", "SECTOR", "INDUSTRY", "MARKET_ID", "FIRST_TRADING_DATE", "LAST_TRADING_DATE", "TOTAL_TRADING_DAYS", "MIN_PRICE", "MAX_PRICE", "AVG_PRICE", "PRICE_STDDEV", "AVG_DAILY_RETURN", "DAILY_VOLATILITY", "MIN_DAILY_RETURN", "MAX_DAILY_RETURN", "TOTAL_RETURN", "POSITIVE_DAYS", "NEGATIVE_DAYS", "NEUTRAL_DAYS", "WIN_RATE", "SHARPE_RATIO_DAILY", "ASSET_CLASS", "VOLATILITY_CATEGORY", "LAST_UPDATED"
        from FAR_TRANS_DB.marts.mart_asset_performance_incremental__dbt_tmp
    );
    commit;