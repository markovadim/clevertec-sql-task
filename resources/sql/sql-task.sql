-- Вывести к каждому самолету класс обслуживания и количество мест этого класса
select air.aircraft_code, air.model, s.fare_conditions, count(s.fare_conditions)
from aircrafts as air
join seats as s
on air.aircraft_code = s.aircraft_code
group by air.aircraft_code, air.model, s.fare_conditions
order by aircraft_code;

-- Найти 3 самых вместительных самолета (модель + кол-во мест)
select air.model, count(s.aircraft_code) as seats
from aircrafts as air
join seats as s
on air.aircraft_code = s.aircraft_code
group by air.model
order by seats desc limit 3;

-- Найти все рейсы, которые задерживались более 2 часов
select *
from flights
where extract(hour from actual_departure) - extract(hour from scheduled_departure) > 2;

-- Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
select tickets.passenger_name, tickets.contact_data
from tickets
join ticket_flights
on tickets.ticket_no = ticket_flights.ticket_no
join bookings on tickets.book_ref = bookings.book_ref
where ticket_flights.fare_conditions = 'Business'
order by bookings.bookings.book_date desc
limit 10;

-- Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
select f.flight_id, f.flight_no, f.departure_airport, f.arrival_airport
from flights f
left join ticket_flights tf
on f.flight_id = tf.flight_id and tf.fare_conditions = 'Business'
where tf.flight_id is null;

-- Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
select distinct airport_name, city
from airports
join flights
on airports.airport_code = flights.departure_airport
where actual_departure != scheduled_departure;

-- Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
select a.airport_name, count(f.flight_id) as flights_count
from flights f
join airports a
on f.departure_airport = a.airport_code
group by a.airport_name
order by flights_count desc;

-- Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
select *
from flights
where scheduled_arrival != actual_arrival;

-- Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
select air.aircraft_code, air.model, s.seat_no
from aircrafts as air
join seats as s
on air.model = 'Аэробус A321-200' and not s.fare_conditions = 'Economy'
order by s.seat_no;

-- Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
select city
from airports
group by city
having count(city) > 1;

-- Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
with total_amount_by_passenger as (
    select t.passenger_name, sum(tf.amount) as total_amount
    from tickets t
             join ticket_flights tf
                  on t.ticket_no = tf.ticket_no
    group by t.passenger_name
), average_amount as (
    select avg(total_amount) as avg_amount
    from total_amount_by_passenger
)
select p.passenger_name, p.total_amount
from total_amount_by_passenger p, average_amount a
where p.total_amount > a.avg_amount;

-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
select fl.flight_id, fl.flight_no, fl.scheduled_departure, fl.status
from flights as fl
join airports
on (departure_airport = (select airport_code from airports where city = 'Екатеринбург')
and (arrival_airport in (select airport_code from airports where city = 'Москва'))
and (fl.scheduled_departure::date - bookings.now()::date >= 0)
and (fl.status in ('On Time', 'Delayed')))
order by scheduled_departure::date - bookings.now()::date limit 1;

-- Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
(select ticket_no, (select min(amount) from ticket_flights) as price from ticket_flights limit 1)
union
(select ticket_no, (select max(amount) from ticket_flights) as price from ticket_flights limit 1);

-- Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
create table if not exists Customers (
id bigserial primary key,
firstName varchar(50) not null,
lastName varchar(50),
email varchar(50) unique check(email like '%_@.%'),
phone varchar(50) unique
);

-- Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
create table if not exists Orders (
id bigserial primary key,
customerId int not null,
quantity int,
foreign key (customerId) references bookings.customers(id)
);

-- Написать 5 insert в эти таблицы
insert into customers (id, firstName, lastName, email, phone)
values (1, 'Ivan','Ivanov','ivan@.mail.ru','80334657639'),
       (2, 'Petr','Petrov','yegfb@.mail.ru','80298756473'),
       (3, 'Kirill','Kirillov','cvc54@.mail.ru','8033342256'),
       (4, 'Semen','Semenov','sekmref@.mail.ru','8029112345'),
       (5, 'Maxim','Maximov','man32jfd@.mail.ru','8029654432');

insert into orders (id, customerId, quantity)
values (1, 1, 123),
       (2, 2, 32),
       (3, 5, 1),
       (4, 3, 3),
       (5, 3, 6);

-- Удалить таблицы
drop table customers, orders;
