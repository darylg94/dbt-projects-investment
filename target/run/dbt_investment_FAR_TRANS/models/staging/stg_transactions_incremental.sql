-- back compat for old kwarg name
  
  begin;
    
        
            
	    
	    
            
        
    

    

    merge into FAR_TRANS_DB.staging.stg_transactions_incremental as DBT_INTERNAL_DEST
        using FAR_TRANS_DB.staging.stg_transactions_incremental__dbt_tmp as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.transaction_id = DBT_INTERNAL_DEST.transaction_id))

    
    when matched then update set
        "CUSTOMER_ID" = DBT_INTERNAL_SOURCE."CUSTOMER_ID","ISIN" = DBT_INTERNAL_SOURCE."ISIN","TRANSACTION_ID" = DBT_INTERNAL_SOURCE."TRANSACTION_ID","TRANSACTION_TYPE" = DBT_INTERNAL_SOURCE."TRANSACTION_TYPE","TRANSACTION_DATE" = DBT_INTERNAL_SOURCE."TRANSACTION_DATE","TOTAL_VALUE" = DBT_INTERNAL_SOURCE."TOTAL_VALUE","UNITS" = DBT_INTERNAL_SOURCE."UNITS","CHANNEL" = DBT_INTERNAL_SOURCE."CHANNEL","MARKET_ID" = DBT_INTERNAL_SOURCE."MARKET_ID","DBT_UPDATED_AT" = DBT_INTERNAL_SOURCE."DBT_UPDATED_AT"
    

    when not matched then insert
        ("CUSTOMER_ID", "ISIN", "TRANSACTION_ID", "TRANSACTION_TYPE", "TRANSACTION_DATE", "TOTAL_VALUE", "UNITS", "CHANNEL", "MARKET_ID", "DBT_UPDATED_AT")
    values
        ("CUSTOMER_ID", "ISIN", "TRANSACTION_ID", "TRANSACTION_TYPE", "TRANSACTION_DATE", "TOTAL_VALUE", "UNITS", "CHANNEL", "MARKET_ID", "DBT_UPDATED_AT")

;
    commit;