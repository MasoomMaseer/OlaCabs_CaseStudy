create database sql_case5_ola;
use sql_case5_ola;

/* 
1	Find hour of 'pickup' and 'confirmed_at' time, and make a column of weekday as "Sun,Mon, etc"next to pickup_datetime												
2	Make a table with count of bookings with booking_type = p2p catgorized by booking mode as 'phone', 'online','app',etc												
3	Create columns for pickup and drop ZONES (using Localities data containing Zone IDs against each area) and fill corresponding values 
    against pick-area and drop_area, using Sheet'Localities'												
4	Find top 5 drop zones in terms of  average revenue												
5	Find all unique driver numbers grouped by top 5 pickzones												
6	Make a list of top 10 driver by driver numbers in terms of fare collected where service_status is done, done-issue												
7	Make a hourwise table of bookings for week between Nov01-Nov-07 and highlight the hours with more than average no.of bookings day wise
*/

select * from DATA LIMIT 2000;
select * from localities LIMIT 2000;

set sql_safe_updates = 0;

ALTER TABLE data
add Column pickup_dt datetime;

ALTER TABLE data
add Column confirmed_dt datetime;

Update data
SET pickup_dt = Str_To_Date(pickup_datetime,"%d-%m-%Y %H:%i");

Update data
SET confirmed_dt = Str_To_Date(confirmed_at,"%d-%m-%Y %H:%i");

ALTER TABLE data
drop Column Confirmed_at;

ALTER TABLE data MODIFY pickup_dt datetime AFTER pickup_time;

-- 1. Find hour of 'pickup' and 'confirmed_at' time, and make a column of weekday as "Sun,Mon, etc"next to pickup_datetime

ALTER TABLE data
add Column weekday text after pickup_dt;

Update data
SET weekday =
(case
    WHEN weekday(pickup_date) = 0 THEN "Monday"
   WHEN weekday(pickup_date) = 1 THEN "Tuesday"
   WHEN weekday(pickup_date) = 2 THEN "Wednesday"
   WHEN weekday(pickup_date) = 3 THEN "Thursday"
   WHEN weekday(pickup_date) = 4 THEN "Friday"
   WHEN weekday(pickup_date) = 5 THEN "Saturday"
   WHEN weekday(pickup_date) = 6 THEN "Sunday"
    ELSE null
end);

-- 2. Make a table with count of bookings with booking_type = p2p catgorized by booking mode as 'phone', 'online','app',etc              

select booking_mode, count(*) as total_p2p
from data
where booking_type = "p2p"
group by booking_mode; 

-- 3.    Create columns for pickup and drop ZONES (using Localities data containing Zone IDs against each area) and
--        fill corresponding values against pick-area and drop_area, using Sheet'Localities'

create view pickup_zone as
select distinct l.zone_id as pickup_zone, d.pickupArea
from data d
inner join localities l
on d.pickupArea = l.area
order by pickup_zone;

create view drop_zone as
select distinct l.zone_id as drop_zone, d.dropArea
from data d
inner join localities l
on d.dropArea = l.area
order by drop_zone;

-- 4. Find top 5 drop zones in terms of  average revenue

select l.zone_id, ceil(avg(d.fare)) as avg_fare
from data d
inner join localities l
on d.dropArea = l.area
group by l.zone_id
order by avg_fare desc
limit 5;

-- 5.    Find all unique driver numbers grouped by top 5 pickzones

create view top5pickzone as
select distinct l.zone_id as top_zone, sum(d.fare) as SumRevenue
from data d
inner join localities l
on d.pickuparea = l.area
group by l.zone_id
order by SumRevenue desc
limit 5;

select distinct l.zone_id, d.Driver_number
from data d
inner join localities l
on d.pickuparea = l.area
where d.Driver_number is not null and
l.zone_id in (select top_zone from top5pickzone)
order by 1,2;

-- 6.    Make a list of top 10 driver by driver numbers in terms of fare collected where service_status is done, done-issue

select driver_number, sum(fare) as total_revenue
from data
where service_status in ("done", "done-issue")
group by driver_number
order by total_revenue desc
limit 10;
