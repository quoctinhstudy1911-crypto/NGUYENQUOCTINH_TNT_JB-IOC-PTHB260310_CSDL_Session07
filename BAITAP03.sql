-- Dữ liệu 
create table post (
    post_id serial primary key,
    user_id int not null,
    content text,
    tags text[],
    created_at timestamp default current_timestamp,
    is_public boolean default true
);
create table post_like (
    user_id int not null,
    post_id int not null,
    liked_at timestamp default current_timestamp,
    primary key (user_id, post_id)
);
-- test 
insert into post (user_id, content, is_public) values
(1, 'toi di du lich da lat', true),        
(2, 'hom nay troi dep', true),
(3, 'an com chua', true),
(4, 'hoc sql co kho khong', true),
(5, 'tap gym moi ngay', true),
(6, 'di cafe voi ban', true),
(7, 'xem phim cuoi tuan', true),
(8, 'choi game cung ban', true),
(9, 'nghe nhac chill', true),
(10, 'doc sach moi ngay', true),
(11, 'lam viec cham chi', true),
(12, 'di hoc som', true),
(13, 'an uong lan xa', true),
(14, 'tap the duc buoi sang', true),
(15, 'hoc lap trinh python', true),
(16, 'di sieu thi mua do', true),
(17, 'nghi ngoi cuoi tuan', true),
(18, 'hoc database co ban', true),
(19, 'lam bai tap ve nha', true),
(20, 'du lich ha noi', true);              -
-- Yêu cầu


-- Tối ưu hóa truy vấn tìm kiếm bài đăng công khai theo từ khóa:
select * 
from post
where is_public = true
and content ilike '%du lịch%';

-- Tạo Expression Index sử dụng LOWER(content) để tăng tốc tìm kiếm
create index idx_post_content_lower
on post (lower(content));
-- So sánh hiệu suất trước và sau khi tạo chỉ mục
-- Trước 
explain analyze
select * 
from post
where is_public = true
and content ilike '%du lich%';
/*
"Seq Scan on post  (cost=0.00..19.25 rows=1 width=81) (actual time=0.019..0.019 rows=0.00 loops=1)"
"  Filter: (is_public AND (content ~~* '%du lich%'::text))"
"Planning:"
"  Buffers: shared hit=1"
"Planning Time: 0.123 ms"
"Execution Time: 0.038 ms"
*/
-- sau
explain analyze
select * 
from post
where is_public = true
and lower(content) like '%du lich%';
/*
"Seq Scan on post  (cost=0.00..22.45 rows=83 width=70) (actual time=0.039..0.076 rows=2.00 loops=1)"
"  Filter: (is_public AND (lower(content) ~~ '%du lich%'::text))"
"  Rows Removed by Filter: 18"
"  Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=2"
"Planning Time: 0.181 ms"
"Execution Time: 0.098 ms"
*/

-- Bảng quá nhỏ nên nó vẫn chọn seq scan mà nếu hiệu xuất cao khi mà nhiều dòng dữ liệu

-- Tối ưu hóa truy vấn lọc bài đăng theo thẻ (tags):
-- Xóa dữ liệu trên 
truncate table post restart identity;
insert into post (user_id, content, tags, is_public) values
(1, 'du lich da lat', array['travel','food'], true),
(2, 'an uong', array['food'], true),
(3, 'du lich bien', array['travel'], true),
(4, 'hoc sql', array['study'], true),
(5, 'di choi', array['travel','fun'], true),
(6, 'xem phim', array['entertain'], true),
(7, 'du lich ha noi', array['travel'], true),
(8, 'tap gym', array['health'], true),
(9, 'du lich thai lan', array['travel'], true),
(10, 'nghe nhac', array['music'], true);

-- Tạo GIN Index cho cột tags
create index idx_post_tags_gin
on post using gin (tags);
-- Phân tích hiệu suất bằng EXPLAIN ANALYZE
-- Trước
explain analyze
select * 
from post 
where tags @> array['travel'];
drop index idx_post_tags_gin
/*
"Seq Scan on post  (cost=0.00..20.38 rows=1 width=70) (actual time=0.028..0.031 rows=5.00 loops=1)"
"  Filter: (tags @> '{travel}'::text[])"
"  Rows Removed by Filter: 5"
"  Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=5"
"Planning Time: 0.724 ms"
"Execution Time: 0.043 ms"
*/

-- Sau 
explain analyze
select * 
from post 
where tags @> array['travel'];
/*
"Bitmap Heap Scan on post  (cost=12.80..16.82 rows=1 width=70) (actual time=0.061..0.063 rows=5.00 loops=1)"
"  Recheck Cond: (tags @> '{travel}'::text[])"
"  Heap Blocks: exact=1"
"  Buffers: shared hit=4"
"  ->  Bitmap Index Scan on idx_post_tags_gin  (cost=0.00..12.80 rows=1 width=0) (actual time=0.034..0.034 rows=5.00 loops=1)"
"        Index Cond: (tags @> '{travel}'::text[])"
"        Index Searches: 1"
"        Buffers: shared hit=3"
"Planning:"
"  Buffers: shared hit=3"
"Planning Time: 0.167 ms"
"Execution Time: 0.103 ms"
*/

-- Tốc độ giảm đáng kể khi dùng gin 


-- Tối ưu hóa truy vấn tìm bài đăng mới trong 7 ngày gần nhất
truncate table post restart identity;

insert into post (user_id, content, created_at, is_public) values
(1, 'bai cu', now() - interval '10 days', true),
(2, 'bai moi 1', now() - interval '1 day', true),
(3, 'bai moi 2', now() - interval '2 days', true),
(4, 'bai moi 3', now() - interval '3 days', true),
(5, 'bai moi 4', now() - interval '5 days', true),
(6, 'bai cu 2', now() - interval '15 days', true),
(7, 'bai private', now() - interval '1 day', false),
(8, 'bai moi 5', now() - interval '6 days', true),
(9, 'bai cu 3', now() - interval '20 days', true),
(10, 'bai moi 6', now() - interval '2 days', true);

-- Tạo Partial Index cho bài viết công khai gần đây:
create index idx_post_recent_public
on post (created_at desc)
where is_public = true;
-- Kiểm tra hiệu suất với truy vấn:
explain analyze
select * 
from post
where is_public = true
and created_at >= now() - interval '7 days';

/*
"Seq Scan on post  (cost=0.00..24.53 rows=830 width=70) (actual time=0.020..0.025 rows=6.00 loops=1)"
"  Filter: (is_public AND (created_at >= (now() - '7 days'::interval)))"
"  Rows Removed by Filter: 4"
"  Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=30"
"Planning Time: 2.783 ms"
"Execution Time: 0.036 ms"
*/
-- Vẫn ít nhưng nếu nhiều dữ liệu test ổn hơn 

-- Phân tích chỉ mục tổng hợp (Composite Index):
-- Tạo chỉ mục (user_id, created_at DESC)
create index idx_post_user_created
on post (user_id, created_at desc);
-- Kiểm tra hiệu suất khi người dùng xem “bài đăng gần đây của bạn bè”
explain analyze
select * 
from post
where user_id in (2, 3, 5)
order by created_at desc
limit 10;

/*
"Limit  (cost=1.16..1.17 rows=3 width=58) (actual time=0.037..0.039 rows=3.00 loops=1)"
"  Buffers: shared hit=1"
"  ->  Sort  (cost=1.16..1.17 rows=3 width=58) (actual time=0.036..0.036 rows=3.00 loops=1)"
"        Sort Key: created_at DESC"
"        Sort Method: quicksort  Memory: 25kB"
"        Buffers: shared hit=1"
"        ->  Seq Scan on post  (cost=0.00..1.14 rows=3 width=58) (actual time=0.026..0.027 rows=3.00 loops=1)"
"              Filter: (user_id = ANY ('{2,3,5}'::integer[]))"
"              Rows Removed by Filter: 7"
"              Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=55 read=1 dirtied=1"
"Planning Time: 4.968 ms"
"Execution Time: 0.059 ms"
*/
/*
composite index giúp tối ưu khi query nhiều cột
thứ tự cột trong index rất quan trọng
giúp vừa filter vừa order nhanh hơn
*/






