-- PHY3645 - Phan 2: dung thu PostgreSQL
SELECT version();

DROP DATABASE IF EXISTS school;
CREATE DATABASE school;
\c school

-- ---------- DDL: tao bang, khoa chinh, khoa ngoai, rang buoc ----------
CREATE TABLE students (
    student_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,   -- T-SQL: IDENTITY(1,1)
    full_name   VARCHAR(100) NOT NULL,
    class_name  VARCHAR(20)  NOT NULL,
    birth_date  DATE
);

CREATE TABLE courses (
    course_code VARCHAR(10)  PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    credits     INT NOT NULL CHECK (credits > 0)
);

CREATE TABLE enrollments (
    student_id  INT         REFERENCES students(student_id),
    course_code VARCHAR(10) REFERENCES courses(course_code),
    score       NUMERIC(4,2) CHECK (score BETWEEN 0 AND 10),
    PRIMARY KEY (student_id, course_code)
);

-- ---------- DML: them du lieu ----------
INSERT INTO students (full_name, class_name, birth_date) VALUES
    ('Nguyễn Thu Hà',   'K68A3', '2005-03-12'),
    ('Trần Minh Khoa',  'K68A3', '2005-07-01'),
    ('Lê Phương Anh',   'K68A2', '2005-11-23'),
    ('Phạm Quốc Bảo',   'K68A2', '2004-12-30'),
    ('Đỗ Gia Linh',     'K68A1', '2005-05-05');

INSERT INTO courses VALUES
    ('PHY3645', 'Thực tập Tin học ứng dụng', 2),
    ('INT2211', 'Cơ sở dữ liệu',             3),
    ('INT3404', 'Thị giác máy tính',         3);

INSERT INTO enrollments VALUES
    (1, 'PHY3645', 9.0), (1, 'INT2211', 8.5), (1, 'INT3404', 9.5),
    (2, 'PHY3645', 7.5), (2, 'INT2211', 6.0),
    (3, 'PHY3645', 8.0), (3, 'INT3404', 7.0),
    (4, 'INT2211', 5.5),
    (5, 'PHY3645', 10.0), (5, 'INT3404', 8.0);

-- ---------- Truy van ----------
-- 1. JOIN 3 bang
SELECT s.full_name, c.course_name, e.score
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses  c ON c.course_code = e.course_code
ORDER BY s.full_name, c.course_code;

-- 2. GROUP BY + HAVING: diem TB cac mon co it nhat 3 SV
SELECT c.course_code, COUNT(*) AS n_students, ROUND(AVG(e.score), 2) AS avg_score
FROM enrollments e JOIN courses c USING (course_code)
GROUP BY c.course_code
HAVING COUNT(*) >= 3
ORDER BY avg_score DESC;

-- 3. Window function: xep hang trong tung mon
SELECT course_code, student_id, score,
       RANK() OVER (PARTITION BY course_code ORDER BY score DESC) AS rnk
FROM enrollments;

-- 4. LIMIT (T-SQL: SELECT TOP 3)
SELECT s.full_name, ROUND(AVG(e.score), 2) AS gpa
FROM students s JOIN enrollments e USING (student_id)
GROUP BY s.full_name
ORDER BY gpa DESC
LIMIT 3;

-- 5. Transaction: sua roi ROLLBACK -> du lieu khong doi
BEGIN;
UPDATE enrollments SET score = 0 WHERE course_code = 'INT2211';
SELECT course_code, score FROM enrollments WHERE course_code = 'INT2211';
ROLLBACK;
SELECT course_code, score FROM enrollments WHERE course_code = 'INT2211';

-- 6. Rang buoc hoat dong: diem 11 bi tu choi
INSERT INTO enrollments VALUES (4, 'PHY3645', 11);

-- 7. Lenh rieng cua psql: liet ke bang, mo ta bang
\dt
\d students
