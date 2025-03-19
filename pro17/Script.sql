use mysql;
select user from user;

create table T_MEMBER(
	id varchar(10) primary key,
	pwd varchar(10),
	name varchar(20),
	email varchar(20),
	joinDate datetime default CURRENT_TIMESTAMP
);

insert into t_member (id, pwd, name, email)
values('hong', '1212', '홍길동', 'hong@gmail.com'),('lee', '1212', '이순신', 'lee@test.com'),('kim', '1212', '김유신', 'kim@jweb.com');

select * from t_member;

use sys;

create table t_board(
	articleNO int(10) primary key,
	parentNO int(10) default 0,
	title varchar(500) not null,
	content varchar(4000),
	imageFileName varchar(100),
	writedate datetime default CURRENT_TIMESTAMP,
	id varchar(10),
	CONSTRAINT FK_ID foreign KEY(id)
	references t_member(id)
);

use sys;

insert into t_board
values(1, 0, '테스트글입니다.', '테스트글입니다.', null, now(), 'hong'), 
(2, 0, '안녕하세요', '상품 후기입니다.', null, now(), 'hong'),
(3, 2, '답변입니다.', '상품 후기에 대한 답변입니다.', null, now(), 'hong'),
(4, 0, '김유신입니다.', '김유신 테스트글입니다.', null, now(), 'kim'),
(5, 3, '답변입니다.', '상품 좋습니다.', null, now(), 'lee'),
(6, 2, '상품 후기입니다.', '이순신씨의 상품 사용 후기를 올립니다.', null, now(), 'lee')
;

commit;
select * from t_board;

select level, articleNO, parentNO, LPAD(' ', 4*(level-1)) || title title, content, imageFileName, writedate, id
from t_board
start with parentNO = 0
connect by prior articleNO = parentNO
order SIBLINGS by articleNO desc;

WITH RECURSIVE board_tree AS (
    -- 최상위 부모 찾기 (parentNO가 0인 글)
    SELECT 
        1 AS level, 
        articleNO, 
        parentNO, 
        title, 
        content, 
        imageFileName, 
        writedate, 
        id,
        CAST(articleNO AS CHAR(100)) AS path  -- 초기 경로 설정
    FROM t_board
    WHERE parentNO = 0
    
    UNION ALL
    
    -- 자식 노드 찾기 (부모의 path를 이어서 경로 문자열 생성)
    SELECT 
        bt.level + 1, 
        b.articleNO, 
        b.parentNO, 
        b.title, 
        b.content, 
        b.imageFileName, 
        b.writedate, 
        b.id,
        CONCAT(bt.path, '-', b.articleNO) AS path  -- 부모 path + 현재 articleNO
    FROM t_board b
    inner JOIN board_tree bt ON b.parentNO = bt.articleNO
)
SELECT 
    level, 
    articleNO, 
    parentNO, 
    CONCAT(LPAD(' ', 4 * (level - 1), ' '), title) AS title,  -- 들여쓰기 적용
    content, 
    imageFileName, 
    writedate, 
    id,
    path  -- 디버깅을 위해 path 출력
FROM board_tree
ORDER BY path;  -- 부모-자식 관계를 유지하는 정렬 적용

select * from t_board;

DELETE FROM t_board
WHERE articleNO in (
	SELECT articleNO FROM t_board
	START WITH articleNO = 2
	CONNECT BY PRIOR articleNO = parentNO
);

select * from t_board;
commit;

WITH RECURSIVE board_tree AS (
    -- 초기 부모 글(articleNO가 #{articleNO}인 글)
    SELECT 
        articleNO, 
        parentNO
    FROM t_board
    WHERE articleNO = 2

    UNION ALL

    -- 재귀적으로 자식 글 찾기
    SELECT 
        b.articleNO, 
        b.parentNO
    FROM t_board b
    JOIN board_tree bt ON b.parentNO = bt.articleNO
)
SELECT * FROM board_tree;


SELECT * FROM(
	SELECT ROWNUM as recNum,
	LVL,
	articleNO,
	parentNO,
	title,
	content,
	id,
	writedate,
	FROM (
			WITH RECURSIVE board_tree AS (

				SELECT 
					1 as LVL, 
					articleNO, 
					parentNO, 
					title, 
					content, 
					id, 
					writedate
				FROM t_board
				WHERE parentNO = 0
				
				UNION ALL
				
				SELECT 
					bt.LVL + 1, 
					b.articleNO, 
					b.parentNO, 
					b.title, 
					b.content, 
					b.id, 
					b.writedate
				FROM t_board b
				JOIN board_tree bt ON b.parentNO = bt.articleNO
			)
			SELECT 
				LVL, 
				articleNO, 
				parentNO, 
				CONCAT(LPAD(' ', 4 * (LVL - 1), ' '), title) AS title,  
				content, 
				writedate, 
				id
			FROM board_tree

	)
)
where
recNum between(section-1)*100+(pageNum-1)*10+1 and (section-1)*100+pageNum*10;
			
WITH RECURSIVE board_tree AS (

    SELECT 
        1 AS LVL, 
        articleNO, 
        parentNO, 
        title, 
        content, 
        id, 
        writedate
    FROM t_board
    WHERE parentNO = 0
    
    UNION ALL
    
    SELECT 
        bt.LVL + 1, 
        b.articleNO, 
        b.parentNO, 
        b.title, 
        b.content, 
        b.id, 
        b.writedate
    FROM t_board b
    JOIN board_tree bt ON b.parentNO = bt.articleNO
)
SELECT *
FROM (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY articleNO) AS recNum,  
        LVL, 
        articleNO, 
        parentNO, 
        CONCAT(LPAD(' ', 4 * (LVL - 1), ' '), title) AS title,  
        content, 
        writedate, 
        id
    FROM board_tree
) AS numbered_board
WHERE recNum BETWEEN (section - 1) * 100 + (pageNum - 1) * 10 + 1  
                  AND (section - 1) * 100 + pageNum * 10;