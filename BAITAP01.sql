-- Dữ liệu 
create database qlsach_db;

create table books(
	book_id serial primary key,
	title varchar(255),
	author varchar(100),
	genre varchar(50),
	price decimal (10,2),
	description text,
	create_at timestamp default current_timestamp
);

insert into books(title,author,genre,price,description) values 
('Sách thiếu nhi ca hành','Kim Tỏa','Fantasy',100000,'Sách hay nhất thế gian');

-- Dùng để test 
INSERT INTO books(title,author,genre,price)
SELECT 
  'Book ' || i,
  CASE 
    WHEN i % 10 = 0 THEN 'J.K Rowling'
    ELSE 'Someone Else'
  END,
  'Fantasy',
  100000
FROM generate_series(1,10000) i;


-- Tạo các chỉ mục phù hợp để tối ưu truy vấn sau:
-- Search chứa chuổi dùng pg_trgm + GIN
SELECT * FROM books WHERE author ILIKE '%Rowling%';
create extension pg_trgm;
create index idx_author_gin on books using gin (author gin_trgm_ops);

-- So sánh bằng dùng B-tree
SELECT * FROM books WHERE genre = 'Fantasy';
create index idx_genre on books (genre);

select * from books
-- So sánh thời gian truy vấn trước và sau khi tạo Index (dùng EXPLAIN ANALYZE)
EXPLAIN ANALYZE SELECT * FROM books WHERE author ILIKE '%Rowling%';
-- Trước 
/*
"Seq Scan on books  (cost=0.00..11.00 rows=1 width=912) (actual time=0.631..0.632 rows=0.00 loops=1)"
"  Filter: ((author)::text ~~* '%Rowling%'::text)"
"  Rows Removed by Filter: 1"
"  Buffers: shared hit=1"
"Planning Time: 0.979 ms"
"Execution Time: 0.687 ms"
*/
-- Sau
/*
"Seq Scan on books  (cost=0.00..1.01 rows=1 width=912) (actual time=0.030..0.030 rows=0.00 loops=1)"
"  Filter: ((author)::text ~~* '%Rowling%'::text)"
"  Rows Removed by Filter: 1"
"  Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=28"
"Planning Time: 1.802 ms"
"Execution Time: 0.048 ms"
*/

EXPLAIN ANALYZE SELECT * FROM books WHERE genre = 'Fantasy';
-- Trước
/*
"Seq Scan on books  (cost=0.00..219.00 rows=10000 width=78) (actual time=0.035..3.461 rows=10000.00 loops=1)"
"  Filter: ((genre)::text = 'Fantasy'::text)"
"  Buffers: shared hit=94"
"Planning:"
"  Buffers: shared hit=50 dirtied=4"
"Planning Time: 3.470 ms"
"Execution Time: 4.202 ms"
*/
-- sau 
/*
"Seq Scan on books  (cost=0.00..219.00 rows=10000 width=78) (actual time=0.034..2.024 rows=10000.00 loops=1)"
"  Filter: ((genre)::text = 'Fantasy'::text)"
"  Buffers: shared hit=94"
"Planning:"
"  Buffers: shared hit=17 read=1"
"Planning Time: 2.482 ms"
"Execution Time: 2.526 ms"
*/

-- Thử nghiệm các loại chỉ mục khác nhau:
-- B-tree cho genre
create index idx_genre on books (genre);
-- GIN cho title hoặc description (phục vụ tìm kiếm full-text)
create index idx_books_gin
on books using gin (to_tsvector('english', description));

-- Tạo một Clustered Index (sử dụng lệnh CLUSTER) trên bảng book theo cột genre và kiểm tra sự khác biệt trong hiệu suất
CLUSTER books USING idx_genre;
EXPLAIN ANALYZE SELECT * FROM books WHERE genre = 'Romantic';
-- Sử dụng 
/*
"Index Scan using idx_genre on books  (cost=0.29..4.30 rows=1 width=78) (actual time=0.045..0.045 rows=0.00 loops=1)"
"  Index Cond: ((genre)::text = 'Romantic'::text)"
"  Index Searches: 1"
"  Buffers: shared read=2"
"Planning:"
"  Buffers: shared hit=6 read=2"
"Planning Time: 3.918 ms"
"Execution Time: 0.059 ms"
*/


-- Viết báo cáo ngắn (5-7 dòng) giải thích:
	-- Loại chỉ mục nào hiệu quả nhất cho từng loại truy vấn?
	/*
B-tree: dùng cho so sánh như =, <, >, BETWEEN
GIN: dùng cho tìm kiếm chuỗi hoặc nội dung như ILIKE '%text%' hoặc full-text search
Hash: chỉ dùng cho so sánh bằng = thôi nên ít dùng
Gist: phù hợp cho các bài toán về map
	*/
	-- Khi nào Hash index không được khuyến khích trong PostgreSQL?
	/*
Cần truy vấn ngoài dấu = như <, >, BETWEEN
Cần sắp xếp (ORDER BY) hoặc tìm theo khoảng giá trị
Muốn linh hoạt
	*/













