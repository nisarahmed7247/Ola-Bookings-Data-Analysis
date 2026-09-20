create database OLA;
use OLA;

--Q1.What is the overall booking success rate, cancellation rate, and incomplete-ride rate?

create view booking_status_rates as select round((successful_rides/total_rides)*100,2) as success_rate, round((cancelled_rides/total_rides)*100,2) as cancelled_rate, round((Incomplete_rides/total_rides)*100,2) as incomplete_rate from (select count(booking_id) as total_rides, count(case when
booking_status="Success" then booking_id end) as successful_rides, count(case when
booking_status IN ('Canceled by Customer', 'Canceled by Driver') then booking_id end) as cancelled_rides, count(case when
booking_status not in("Success", "Canceled by Customer","Canceled by Driver") then booking_id end) as incomplete_rides from bookings) as rides;
select * from booking_status_rates;

--Q2.Which vehicle type generates the highest total booking value and average booking value?

create view highest_booking_value_vehicle as select vehicle_type, sum(booking_value) as total_Booking_value, avg(booking_value) as Average_Booking_value from bookings
group by vehicle_type
order by total_booking_value desc, average_booking_value desc
limit 1;
select * from highest_booking_value_vehicle;

--Q3.Which pickup locations have the highest number of successful rides, and what is their average ride distance?

create view top_pickup_location as select pickup_location, count(booking_id) as successful_rides, avg(ride_distance) as Average_ride_distance from bookings where booking_status="Success"
group by pickup_location
order by successful_rides desc
limit 1;
select * from top_pickup_location;

--Q4.What are the top 10 customers by total booking value, and how many successful rides did each customer complete?

create view top_10_customers as select customer_id, sum(booking_value) as total_booking_value, count(booking_id) as successful_rides from bookings where booking_status="Success"
group by customer_id
order by total_Booking_value desc
limit 10;
select * from top_10_customers;

--Q5.What is the monthly/daily booking trend, and how does the current period compare with the previous period?

create view daily_booking_trend as select date(booking_date) as booking_date, count(booking_id) as daily_bookings, lag(count(booking_id)) over(order by date(booking_date)) as previous_day_bookings, count(booking_id)-lag(count(booking_id)) over(order by date(booking_date)) as booking_difference from bookings
group by date(booking_date);
select * from daily_booking_trend;

--Q6.What is the 7-day rolling average of successful bookings?

create view successful_booking_rolling_avg as select date(booking_date) as booking_date, count(booking_id) as daily_bookings, avg(count(booking_id)) over(order by date(booking_date) rows between 6 preceding and current row) as rolling_7_day_avg from bookings where booking_status="success"
group by date(booking_date);
select * from successful_booking_rolling_avg;

--Q7.Which customers have made multiple bookings but have a high cancellation rate?

create view customer_cancellation_rate as select customer_id, total_bookings, cancelled_bookings, round((cancelled_bookings/total_bookings)*100.0,2) as cancelled_rate from  (select customer_id, count(booking_id) as total_bookings, count(case when
booking_status in ("Canceled by Customer", "Canceled by Driver") then booking_id end) as cancelled_bookings from bookings
group by customer_id
having total_bookings>1) as customer_rides;
select * from customer_cancellation_rate
order by cancelled_rate desc;

--Q8.How does average customer rating and driver rating vary by vehicle type?

create view vehicle_rating_comparison as with Ratings as (select vehicle_type, avg(customer_rating) as average_customer_rating, avg(driver_ratings) as average_driver_rating from bookings
group by vehicle_type)
select vehicle_type, average_customer_rating, average_driver_rating, round((average_customer_rating-average_driver_rating),2) as difference from ratings;
select * from vehicle_rating_comparison;

--Q9.For each pickup location, rank the vehicle types by successful booking volume and identify the top-performing vehicle type


create view top_vehicle_by_pickup as select * from (select pickup_location, vehicle_type, count(booking_id) as successful_bookings, dense_rank() over(partition by pickup_location order by count(booking_id) desc) as vehicle_rank from bookings where booking_status="success"
group by pickup_location, vehicle_type) as vehicle_ranking where vehicle_rank=1;
select * from top_vehicle_by_pickup;

--Q10.For each customer, identify their most frequently used vehicle type and 
--calculate what percentage of their successful bookings were made using that vehicle type.

create view customer_preferred_vehicle as With vehicle_counts as (Select customer_id, vehicle_type, COUNT(booking_id) as successful_bookings from bookings where booking_status = 'Success'
group by customer_id, vehicle_type),
    
ranked_vehicles as (Select customer_id, vehicle_type, successful_bookings, Dense_rank() over (Partition by customer_id order by successful_bookings desc) AS vehicle_rank from vehicle_counts),

customer_totals as (select customer_id, COUNT(booking_id) as total_successful_bookings from bookings where booking_status = 'Success'
group by customer_id)

select r.customer_id, r.vehicle_type, r.successful_bookings, t.total_successful_bookings, round(r.successful_bookings * 100.0 /t.total_successful_bookings,2) as vehicle_usage_percentage 
from ranked_vehicles r join customer_totals t on r.customer_id = t.customer_id where r.vehicle_rank = 1 order by vehicle_usage_percentage desc;
select * from customer_preferred_vehicle;
