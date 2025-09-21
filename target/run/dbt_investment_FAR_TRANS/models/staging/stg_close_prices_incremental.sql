-- back compat for old kwarg name
  
  begin;
    
        
            
	    
	    
            
        
    

    

    merge into FAR_TRANS_DB.staging.stg_close_prices_incremental as DBT_INTERNAL_DEST
        using FAR_TRANS_DB.staging.stg_close_prices_incremental__dbt_tmp as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.isin || price_date = DBT_INTERNAL_DEST.isin || price_date))

    
    when matched then update set
        "ISIN" = DBT_INTERNAL_SOURCE."ISIN","PRICE_DATE" = DBT_INTERNAL_SOURCE."PRICE_DATE","CLOSE_PRICE" = DBT_INTERNAL_SOURCE."CLOSE_PRICE","DBT_UPDATED_AT" = DBT_INTERNAL_SOURCE."DBT_UPDATED_AT"
    

    when not matched then insert
        ("ISIN", "PRICE_DATE", "CLOSE_PRICE", "DBT_UPDATED_AT")
    values
        ("ISIN", "PRICE_DATE", "CLOSE_PRICE", "DBT_UPDATED_AT")

;
    commit;