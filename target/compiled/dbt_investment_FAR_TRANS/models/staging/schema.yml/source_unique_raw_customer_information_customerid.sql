
    
    

select
    customerid as unique_field,
    count(*) as n_records

from FAR_TRANS_DB.raw.customer_information
where customerid is not null
group by customerid
having count(*) > 1


