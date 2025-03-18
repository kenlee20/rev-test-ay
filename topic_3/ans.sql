SELECT c.class
FROM student.score s
JOIN student.class c ON s.name = c.name
ORDER BY s.score DESC
LIMIT 1 OFFSET 1;
