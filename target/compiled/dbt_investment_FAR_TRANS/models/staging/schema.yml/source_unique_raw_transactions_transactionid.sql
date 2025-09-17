
    
    

select
    transactionid as unique_field,
    count(*) as n_records

from FAR_TRANS_DB.raw.transactions
where transactionid is not null
group by transactionid
having count(*) > 1


