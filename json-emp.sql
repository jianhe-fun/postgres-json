--json with emp table.
--row to json.
SELECT row_to_json(emp) FROM emp WHERE emp_id = 19;

--update with join to match the data.
update emp e set department_id = d.department_id from departments d where e.department = d.name;
update emp e set department = d.name from departments d where e.department_id = d.department_id;

--Collects all the input values, including nulls, into a JSON array.
SELECT json_agg(e)
FROM (SELECT emp_id, name FROM emp WHERE department_id = 1) e;
--Collects all the input values, including nulls, into a JSONB array.
SELECT jsonb_agg(e)
FROM (SELECT emp_id, name FROM emp WHERE department_id = 1) e;

