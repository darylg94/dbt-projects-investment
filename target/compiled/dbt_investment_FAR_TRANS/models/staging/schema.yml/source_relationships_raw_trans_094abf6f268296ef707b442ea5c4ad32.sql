
    
    

with child as (
    select isin as from_field
    from FAR_TRANS_DB.raw.transactions
    where isin is not null
),

parent as (
    select isin as to_field
    from FAR_TRANS_DB.raw.asset_information
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


