--array sum aggregate function. sum the array element together.
begin;
create temp table regres(a int[] not null);
insert into regres values ('{1,2,3}'), ('{9, 12, 13}');
commit;

SELECT ARRAY (
   SELECT sum(elem)
   FROM  regres r
       , unnest(r.a) WITH ORDINALITY x(elem, rn)
   GROUP BY rn ORDER BY rn
   );