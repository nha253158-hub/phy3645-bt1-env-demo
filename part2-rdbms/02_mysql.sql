-- PHY3645 - Phan 2: dung thu MySQL (cung schema voi Postgres de so sanh cu phap)
SELECT VERSION();

DROP DATABASE IF EXISTS school;
CREATE DATABASE school CHARACTER SET utf8mb4;
USE school;

CREATE TABLE students (
    student_id  INT AUTO_INCREMENT PRIMARY KEY,                 -- Postgres: GENERATED ... AS IDENTITY
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
    student_id  INT,
    course_code VARCHAR(10),
    score       DECIMAL(4,2) CHECK (score BETWEEN 0 AND 10),
    PRIMARY KEY (student_id, course_code),
    FOREIGN KEY (student_id)  REFERENCES students(student_id),
    FOREIGN KEY (course_code) REFERENCES courses(course_code)
);

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

-- 1. JOIN 3 bang
SELECT s.full_name, c.course_name, e.score
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses  c ON c.course_code = e.course_code
ORDER BY s.full_name, c.course_code;

-- 2. GROUP BY + HAVING
SELECT course_code, COUNT(*) AS n_students, ROUND(AVG(score), 2) AS avg_score
FROM enrollments
GROUP BY course_code
HAVING COUNT(*) >= 3
ORDER BY avg_score DESC;

-- 3. Window function (MySQL >= 8.0)
SELECT course_code, student_id, score,
       RANK() OVER (PARTITION BY course_code ORDER BY score DESC) AS rnk
FROM enrollments;

-- 4. LIMIT
SELECT s.full_name, ROUND(AVG(e.score), 2) AS gpa
FROM students s JOIN enrollments e USING (student_id)
GROUP BY s.full_name
ORDER BY gpa DESC
LIMIT 3;

-- 5. Transaction + ROLLBACK
START TRANSACTION;
UPDATE enrollments SET score = 0 WHERE course_code = 'INT2211';
SELECT course_code, score FROM enrollments WHERE course_code = 'INT2211';
ROLLBACK;
SELECT course_code, score FROM enrollments WHERE course_code = 'INT2211';

-- 6. Liet ke bang, mo ta bang (tuong duong \dt, \d cua psql)
SHOW TABLES;
DESCRIBE students;

-- 7. Rang buoc CHECK: diem 11 bi tu choi (de cuoi vi MySQL dung script khi gap loi)
INSERT INTO enrollments VALUES (4, 'PHY3645', 11);
