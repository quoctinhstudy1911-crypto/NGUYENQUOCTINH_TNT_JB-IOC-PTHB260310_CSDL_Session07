-- Dữ liệu
create database qt_bt;

create table customer (
    customer_id serial primary key,
    full_name varchar(100),
    region varchar(50)
);
create table orders (
    order_id serial primary key,
    customer_id int references customer(customer_id),
    total_amount decimal(10,2),
    order_date date,
    status varchar(20)
);
create table product (
    product_id serial primary key,
    name varchar(100),
    price decimal(10,2),
    category varchar(50)
);
create table order_detail (
    order_id int references orders(order_id),
    product_id int references product(product_id),
    quantity int
);

insert into customer (full_name, region) values
('nguyen van a', 'mien bac'),
('tran thi b', 'mien nam'),
('le van c', 'mien trung'),
('pham thi d', 'mien bac'),
('hoang van e', 'mien nam');
insert into product (name, price, category) values
('laptop dell', 15000000, 'electronics'),
('iphone 13', 20000000, 'electronics'),
('ao thun', 200000, 'fashion'),
('giay nike', 1200000, 'fashion'),
('sach sql', 150000, 'book');
insert into orders (customer_id, total_amount, order_date, status) values
(1, 15200000, '2024-01-01', 'completed'),
(2, 20000000, '2024-01-03', 'completed'),
(3, 350000, '2024-01-05', 'pending'),
(1, 1200000, '2024-02-01', 'completed'),
(4, 150000, '2024-02-10', 'cancelled'),
(5, 20200000, '2024-03-01', 'completed');
insert into order_detail (order_id, product_id, quantity) values
(1, 1, 1),
(1, 5, 1),
(2, 2, 1),
(3, 3, 1),
(4, 4, 1),
(5, 5, 1),
(6, 2, 1);


-- Tạo View tổng hợp doanh thu theo khu vực:
create view v_revenue_by_region as
select 
    c.region,
    sum(o.total_amount) as total_revenue
from customer c
join orders o on c.customer_id = o.customer_id
group by c.region;

	-- Viết truy vấn xem top 3 khu vực có doanh thu cao nhất
	select *
	from v_revenue_by_region
	order by total_revenue desc
	limit 3;

-- Tạo View chi tiết đơn hàng có thể cập nhật được:
create view v_order_detail as
select 
    order_id,
    customer_id,
    total_amount,
    order_date,
    status
from orders
where status = 'pending'
with check option; 
	-- Cập nhật status của đơn hàng thông qua View này
update v_order_detail
set status = 'completed'
where order_id = 3;
	-- Kiểm tra hành vi khi vi phạm điều kiện WITH CHECK OPTION'
update v_order_detail
set status = 'cancelled'
where order_id = 3;


-- Tạo View phức hợp (Nested View):
	-- Từ v_revenue_by_region, tạo View mới v_revenue_above_avg chỉ hiển thị khu vực có doanh thu > trung bình toàn quốc
create view v_revenue_above_avg as
select *
from v_revenue_by_region
where total_revenue > (
    select avg(total_revenue)
    from v_revenue_by_region
);