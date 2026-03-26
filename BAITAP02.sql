	-- Dữ liệu
	create database ql_sp_01;
	
	create table customer (
	    customer_id serial primary key,
	    full_name varchar(100),
	    email varchar(100),
	    phone varchar(15)
	);
	create table orders (
	    order_id serial primary key,
	    customer_id int references customer(customer_id),
	    total_amount decimal(10,2),
	    order_date date
	);
	insert into customer (full_name, email, phone) values
	('nguyen van a', 'vana@gmail.com', '0901111111'),
	('tran thi b', 'thib@gmail.com', '0902222222'),
	('le van c', 'vanc@gmail.com', '0903333333'),
	('pham thi d', 'thid@gmail.com', '0904444444'),
	('hoang van e', 'vane@gmail.com', '0905555555');
	insert into orders (customer_id, total_amount, order_date) values
	(1, 150000, '2024-01-01'),
	(1, 200000, '2024-01-05'),
	(2, 300000, '2024-01-03'),
	(3, 120000, '2024-01-04'),
	(4, 500000, '2024-01-06'),
	(5, 250000, '2024-01-07'),
	(2, 180000, '2024-01-08');
	
	-- Yêu cầu:
	/*
	Tạo một View tên v_order_summary hiển thị:
	full_name, total_amount, order_date
	(ẩn thông tin email và phone)
	*/
	create view  v_order_summary as
	select 
		c.full_name as "Tên khách hàng",
		o.total_amount as "Tổng số lượng",
		o.order_date as "Ngày đặt hàng"
	from customer c join orders o on c.customer_id = o.customer_id
	
	/*
	Viết truy vấn để xem tất cả dữ liệu từ View
	*/
	select *
	from v_order_summary
	
	/*
	Tạo 1 view lấy về thông tin của tất cả các đơn hàng với điều kiện total_amount ≥ 1 triệu .
	 Sau đó bạn hãy cập nhật lại thông tin 1 bản ghi trong view đó nhé .
	 */
	 create view v_orders_total_amount_dk as
	 select *
	 from orders
	 where total_amount >= 1000000;
	
	insert into orders (customer_id, total_amount, order_date) values
	(1, 2000000, '2024-01-01');
	
	 update v_orders_total_amount_dk
	 set order_date = '2004-11-19';
	 
	 /*
	Tạo một View thứ hai v_monthly_sales thống kê tổng doanh thu mỗi tháng
	*/
	create view v_monthly_sales as 
	select date_part('month', order_date) as "Tháng", sum(total_amount) as "Danh thu"
	from orders
	group by date_part('month', order_date)
	
	/*
	Thử DROP View và ghi chú sự khác biệt giữa DROP VIEW và DROP MATERIALIZED VIEW trong PostgreSQL
	*/
	drop materialized view v_order_summary;
	drop view v_order_summary;
	/*
	drop view: xóa view bình thường, view này không lưu dữ liệu nên mỗi lần gọi sẽ chạy lại query
	drop materialized view: xóa view có lưu dữ liệu sẵn (giống bảng), giúp truy vấn nhanh hơn
	materialized view cần refresh để cập nhật dữ liệu mới
	*/
	
	
	
	
	
	
	
	
	
	
	
