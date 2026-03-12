#Union, Minus, and Intersect: Databases for Developers
select colour from my_brick_collection
minus
select colour from your_brick_collection
order by colour;

select shape from my_brick_collection
union
select shape from your_brick_collection
order  by shape;

select shape from my_brick_collection
union all
select shape from your_brick_collection;

select colour from my_brick_collection
union
select colour from your_brick_collection
order  by colour;