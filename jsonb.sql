--jsonb_array_elements if not named, Default column name: "value".
SELECT '{"foo": {"bar": "baz"}}'::jsonb
    @> '{"bar": "baz"}'::jsonb;  -- yields false

-- A top-level key and an empty object is contained:
SELECT '{"foo": {"bar": "baz"}}'::jsonb @> '{"foo": {}}'::jsonb;

--jsonb existence operator, which is a variation on the theme of containment.
--It tests whether a given string (given as a text value) appears as an object
--key or array element at the top level of the jsonb value.
SELECT '["foo", "bar","baz"]' ::jsonb ?'foo';

--String exists as the object key.
SELECT '{"foo": "bar"}' ::jsonb ?'foo';

--String exists as the object's value.
SELECT '{"foo": "bar"}' ::jsonb ?'bar';

--Create an Temp Table for json demo;
---Still, with appropriate use of expression indexes, the above query can use an index.
-- If querying for particular items within the "tags" key is common, defining an index like this may be worthwhile
Begin;
CREATE  TABLE api (id  serial, jdoc jsonb);
insert into api(jdoc) values('{
                                "guid": "9c36adc1-7fb5-4d5b-83b4-90356a46061a",
                                "name": "Angela Barton",
                                "is_active": true,
                                "company": "Magnafone",
                                "address": "178 Howard Place, Gulf, Washington, 702",
                                "registered": "2009-11-07T08:53:22 +08:00",
                                "latitude": 19.793713,
                                "longitude": 86.513373,
                                "tags": [
                                "enim",
                                "aliquip",
                                "qui"
                                    ]
}');
insert into api(jdoc) values(
                                '{
                                "track": {
                                "segments": [
                                {
                                "location":   [ 47.763, 13.4034 ],
                                "start time": "2018-10-14 10:05:14",
                                "HR": 73
      },
                                {
                                "location":   [ 47.706, 13.2635 ],
                                "start time": "2018-10-14 10:39:21",
                                "HR": 135
      }
    ]
  }
}'
                            );
insert into api(jdoc) values('{"a": {"b":"foo"}}');
insert into api(jdoc) values('{"a": {}}');

insert into api(jdoc) values('{"a":[2,3,4]}');
insert into api(jdoc) values('[2,3,4]');
insert into api(jdoc) values   ( '{"nme": "test"}'),  ( '{"nme": "second test"}');
insert into api(jdoc) values('{}');
insert into api(jdoc) values('{"objects": [{"src":"foo.png"},{"src":"bar.png"}]}');
INSERT INTO api(jdoc) VALUES('{ "customer": "John Doe", "items": {"product": "Beer","qty": 6}}');
INSERT INTO api(jdoc)
VALUES('{ "customer": "Lily Bush", "items": {"product": "Diaper","qty": 24}}'),
      ('{ "customer": "Josh William", "items": {"product": "Toy Car","qty": 1}}'),
      ('{ "customer": "Mary Clark", "items": {"product": "Toy Train","qty": 2}}');

CREATE INDEX idxgin ON api USING GIN (jdoc);
CREATE INDEX idxgintags ON api USING GIN ((jdoc -> 'tags'));
commit;
---------------------------------------------------------
-- Find documents in which the key "company" has value "Magnafone"
SELECT jdoc->'guid' as guid,
       jdoc->'name' as name,
       jdoc->'tags' as tags
    FROM api WHERE jdoc @> '{"company": "Magnafone"}';
------Find out document's gui and name in which the key "tags" contains array element "qui".
SELECT jdoc->'guid' as guid,
       jdoc->'name' as name
FROM api WHERE jdoc -> 'tags' ? 'qui';

-------------SELECT--------SELECT-------------SELECT----------SELECT-------------
select '{}' ::jsonb || '{"alerts": false}' ::jsonb; -- returns: {"alerts": false}
select * from api where jdoc ?& array['items', 'customer'];--returns records that text array exist as top-level keys ['items', 'customer']
SELECT jdoc ->>'track' FROM api WHERE jdoc->'track' IS NOT NULL; ---Only rows that contains key "track".
SELECT *, jdoc ->>'property' FROM api WHERE jdoc->> 'property' = ' '; --Query the key value pair, the Value is empty String.
SELECT * FROM api WHERE jdoc @> '{"tags": ["enim", "aliquip", "qui"]}'; --Find out whole column based on jsonb key value pair.
SELECT * FROM api WHERE jdoc @> '{"location": [47.763, 13.4034]}'; --Find out whole column based on jsonb key value pair.

SELECT (jdoc -> 'track' -> 'segments') -> 0  FROM api WHERE  id = 14;

SELECT jdoc -> 'track' -> 'segments'   FROM api WHERE  id = 14;

SELECT * FROM api WHERE jdoc @> '{"a": 12}'; --Find out whole column based on jsonb key value pair.
SELECT * FROM api WHERE jdoc ->'items' @> '{"qty": 2, "product": "Toy Train"}'; --query jsonb column contains nested json key value pair.
/*
Step1: Query contains specific key items. If contains then query the key's value.
Step2: Query sub-JSON  contains key value pair {'qty': 2}
 */
SELECT * FROM api WHERE (jdoc -> 'items' ->> 'qty'):: integer = 2;
--since top level JSONB type can be array. So following only works for jsonb object type. Put all the distinct keys into an array.
SELECT array_agg(distinct(stuff.key)) result
FROM api, jsonb_each(api.jdoc) stuff
where id > 18;
---For escape characters, using jsonb_build_object to build object.
SELECT jsonb_build_object( k, v ) FROM (VALUES('key', '\' ) ) AS t(k,v);
--exist clause with ilike clause.
select * from api
WHERE
   EXISTS (SELECT 1 FROM jsonb_array_elements(jdoc) as j(jdoc) WHERE (jdoc#>> '{mode}') iLIKE '%a%')
    and jsonb_typeof (jdoc) = 'array';


SELECT * FROM api WHERE jdoc->'objects' @> '[{"src":"foo.png"}]';--query contains json key ('objects') value ('[{"src":"foo.png"}]'). jsonb Array.

SELECT * FROM api WHERE jdoc ->'customer'  @> '"John Doe"'; ---contains specific key value pair.

Select * from api where not (jdoc ? 'items'); -- Not contains key specific. The key is on Top level
---contains specific key(customer) not contains value ('John Doe').
SELECT * FROM api WHERE not (jdoc ->'customer'  @> '"John Doe"');
---the whole JSONB column(jdoc) not contains specific key value pair.
SELECT * FROM api WHERE  NOT (jdoc @> '{"customer":"John Doe"}')
----The whole JSONB column not contain specific key.
select id from api where not (jdoc ? 'items');
SELECT * FROM api WHERE jdoc ->'is_active' @> 'true'; ---query specific key contains specific boolean value
SELECT * FROM api WHERE jdoc ->'latitude' @> '19.793713'; ---query specific key contains specific number value.
--Query contain top-level key: items. If true then get all the correspondent key's value.
SELECT (jdoc->'items') FROM api WHERE jdoc ? 'items'
--Query the whole JSONB column that contain top-level key: items.
SELECT jdoc FROM api WHERE jdoc ? 'items';

SELECT jdoc ->> 'customer' AS customer, jdoc -> 'items' ->> 'product' AS product FROM api
    WHERE CAST ( jdoc -> 'items' ->> 'qty' AS INTEGER) = 2 --Extract qty and cast it as integer. get items and products. -> 'items' ->> 'product'

SELECT jdoc ->> 'customer' AS customer FROM api WHERE jdoc -> 'items' ->> 'product' = 'Beer';

---JSONB aggregate also order by. jsonb_array_elements > a set of elements ->order by >> jsonb_agg
SELECT jsonb_agg(elem ORDER BY (elem->>'ts')::int)
FROM  (
          SELECT *
          FROM   jsonb_array_elements(jsonb '[{"id": 1, "type": 4, "param": 3, "ts": 12354355}
                                     , {"id": 1, "txt": "something", "args": 5, "ts": 12354345}]') a(elem)

      ) sub;
/*
jsonb_path_exists    Checks whether the JSON path returns any item for the specified JSON value.
    $.**                     find any value at any level (recursive processing)
    ?                        where
    @.type() == "string"     value is string
    &&                       and
    @ like_regex "authVar"   value contains regex expression: 'Toy'
 */
select * from api where jsonb_path_exists(jdoc, '$.** ? (@.type() == "string" && @ like_regex 73)')
select *
from api
where jsonb_path_exists(jdoc, '$.** ? (@ == 73)')
--ANY clause with json_array_elements_text.
SELECT car_id, car_type FROM cars
WHERE  car_type = any
       (SELECT * FROM json_array_elements_text('["bmw", "mercedes", "pinto"]'));
--jsonb & aggregate function.
select  jsonb_build_object('totalqty',
        sum((jdoc->'items' -> 'qty')::numeric))
from api where jdoc ? 'items';

select (jdoc->'items') from api where jdoc ? 'items';
SELECT * FROM api  WHERE jdoc::text = '{}'::text; --Query JSON empty object.
SELECT * FROM api WHERE jdoc->>'guid' ilike '%adc%'; -- ilike query. key: guid, value contains 'adc'
SELECT jdoc ->> 'customer' AS customer FROM api WHERE jdoc -> 'items' ->> 'product' ilike '%er%';  --ilike query.
/*
 1. CREATE TEMP TABLE foo(id int) -> jsonb_populate_recordset(null::foo...) will extract JSON.
 Top level key is id, being extracted value data type is int.
2. SELECT ARRAY (SELECT * FROM jsonb_populate_recordset(null::foo, t.jdoc#>'{members,players}') EXTRACT RECORDSET, MAKE IT
 AS ARRAY.
 3. USING LATERAL. This allows them to reference columns (p.players) provided by preceding FROM items p(players).
 */
CREATE TEMP TABLE foo(id int);
SELECT t.id,t.jdoc->>'name' AS team_name, t.jdoc->>'id' AS team_id, p.players
FROM   api t
        , LATERAL (SELECT ARRAY (
    SELECT * FROM jsonb_populate_recordset(null::foo, t.jdoc#>'{members,players}')
    )
    ) AS p(players)
WHERE p.players @> '{3,4}';
------------------------------------------------

SELECT jdoc ->> 'a'  FROM api ; --extracts/get JSON object field with the given key.
SELECT jdoc ->> 'guid' FROM api; ---Extracts JSON object field with the given key, as text.
SELECT jdoc -> 'guid' FROM api; ---Extracts JSON object field with the given key, as text.

SELECT jsonb_each(jdoc) FROM api ; --extract top level jsonb objects. Make Sure top level JSONB type as Object.
SELECT id, jdoc #>> '{items,product}' FROM api where jdoc ? 'items'; --Extracts JSON sub-object at the specified path.
SELECT (j->'i')::int, (j->>'i')::int, (j->'f')::float, (j->>'f')::float
FROM  (SELECT '{"i":123,"f":12.34}'::jsonb) t(j);
----Get the JSONB array element length.
select id, jsonb_array_length(jdoc -> 'track' -> 'segments') from api where id = 14;

SELECT pg_typeof((j->'i')) FROM  (SELECT '{"i":123,"f":12.34}'::jsonb) t(j); --return jsonb.
SELECT pg_typeof((j->>'i')) FROM  (SELECT '{"i":123,"f":12.34}'::jsonb) t(j); --return text
 /* top level type jsonb as a text string.
Possible types are object, array, string, number, boolean, and null.
  */
select id, jsonb_typeof (jdoc) from api order by id;

--expand the top-level JSON object into a set of key/value pairs. The returned value will be type of text.
SELECT jsonb_each_text (jdoc) FROM api;
----GROUP BY and jsonb_each_text. jsonb_each_text top level expand to two columns ("key","value").
--json_object_agg: Collects all the key/value pairs into a JSON object. 1. Expand. 2.Aggregate based on key.
with a as  (select jdoc from api where jdoc ? 'statins_cost')
select  json_object_agg(key, val)
    from (
        select key, sum(value::numeric(20,12)) val
    from a t, jsonb_each_text(t.jdoc)
    group by key
) s

--Returns the set of keys in the top-level JSON object. Text.
SELECT jsonb_object_keys (jdoc) FROM api;

--Returns the type of the top-level JSON value as a text string.
-- Possible types are object, array, string, number, boolean, and null.
SELECT jsonb_typeof (jdoc->'latitude') FROM api;
SELECT jsonb_typeof (jdoc->'registered') FROM api;
SELECT jsonb_typeof (jdoc->'items' -> 'qty') FROM api;
select jsonb_each_text (jdoc) from api;
--coalesce to empty JSONB array
SELECT jsonb_array_elements(
            coalesce(concat('[',jdoc,']')::jsonb,'[]')) from api where id =26;
------------TRANSFORMATION-----------------------------------
--CTE to filer out json rows to id = 29. jsonb return two columns (key, value)
--get id, key from CTE. Filter out condition: "is_invisible_node is true".
with a as (select jdoc, id from api where id = 29)
select a.id, uuid.key uuid
from
    a, jsonb_each(a.jdoc) uuid
where (value->>'is_invisible_node')::boolean;

select pg_typeof(a.key),pg_typeof(a.value)
from (
        SELECT api.id, d.key, d.value FROM api
        join  jsonb_each_text(api.jdoc) d ON true
        ORDER BY 1, 2) a;--return text.
--------Transfrom from JSON to Two Columns. one column: key, another column: value.
/* Both two columns data type are text. THIS WAY IS ON HIGH LEVEL.
   This way the value is    {"qty": 6, "product": "Beer"}\
   Lateral join, jsonb_each_text(api.jdoc) d will return a table.
   Lateral Join, since you can express 'd' in the select clause.
 */
SELECT api.id, d.key, d.value FROM api
    join  jsonb_each_text(api.jdoc) d ON true where id = 11
ORDER BY 1, 2;
--This way, Key is 'product', value is 'Beer'.
SELECT api.id, d.key, d.value FROM api
        join  jsonb_each_text(api.jdoc -> 'items') d ON true where id = 11
ORDER BY 1, 2;
--------testa CTE get the JSONB, select to transform it.
WITH testa AS(
    select jsonb_array_elements
    (t.json -> 'matrix') -> 'offer_currencies' -> 0 as jsonbcolumn from test t)
SELECT d.key, d.value FROM testa
    join  jsonb_each_text(testa.jsonbcolumn) d ON true
ORDER BY 1, 2;

--JSONB cast to boolean value.
select id, jdoc, (jdoc->'is_active') as jsonbvalue from api where (jdoc->'is_active')::boolean
--Transform from JSONB to numeric.
select id, (jdoc -> 'longitude') :: numeric as a from api
    where (jdoc -> 'longitude') :: numeric  is not null;
--------Table Row to JSONB
select  row_to_json(t)::jsonb from (select * from  emp where id > 12) t;
SELECT to_jsonb(rows) FROM (SELECT * FROM emp where id > 12) rows;
select jsonb_build_object('image', i) from images i ; --Top level key is 'image', rows(column&row) become value.

--JSONB ->>> ARRAY, NON-ARRAY ->>> TABLE ROWS.
--1. jsonb ->>array, if data is not array to using jsonb_build_array.
--2. jsonb_array_elements
begin;
create temporary table testarray (id serial, data jsonb);
insert into testarray(data) values('{"date": [456]}');
insert into testarray(data) values('{"date": 123}}');
commit;

select jsonb_array_elements(test.date) as date
from
    (select
    case when jsonb_typeof(data->'date') = 'array'
    then data->'date'
    else jsonb_build_array(data->'date')
    end as date
    from testarray) test;
---"tags" : [],  "tags" : [{"count": 2, "price" : 77}. Aggregate jsonb array's inside object value.
-- https://www.postgresql.org/docs/current/queries-table-expressions.html
with temp as (select id, jdoc from api where id  = 37 or id = 38 )
select jsonb_agg(elem->>'count') as countvalue,jsonb_agg(elem->>'price') as pricevalue
from  temp a left join lateral jsonb_array_elements(a.jdoc->'tags') elem on true;


------------------------------------------------------------
------------------Update-------------------------------------
--Update make jsonb type as jsonb array data type.
update api set jdoc = '[null]' where jsonb_typeof(jdoc) <> 'array' or jdoc = '[]';

UPDATE api SET jdoc = jsonb_set(jdoc, '{customer}', '"Joe Don"') WHERE id = 3; --Update Customer, set customer(key): 'joe don'(value)
UPDATE api SET jdoc = jsonb_set(jdoc, '{location}',
    concat('"', upper(jdoc->>'location'), '"')::jsonb, true) --Upper all the value that the value's key is 'location'.
    WHERE id = 24 returning *;
UPDATE api set jdoc = jsonb_set(jdoc,'{a}','[2,3,4]') WHERE id= 2; --update key value pair. Value type: array.
UPDATE api set jdoc = jsonb_set(jdoc,'{a}','true') WHERE id= 2; --update key value pair. Value type: boolean.
UPDATE api set jdoc = jsonb_set(jdoc,'{a}','12') WHERE id= 4; --update key value pair. Value type: number.
--update JSON array. append new array element to jsonb
UPDATE api SET jdoc = jdoc || '"newString"'::jsonb WHERE id = 16;  --'["newString"]' ALSO OK.
UPDATE api SET jdoc = jdoc - 'newString'  WHERE id = 16;  --Remove array element (string: newString) from JSONB array.
UPDATE api SET jdoc = jdoc - 1  WHERE id = 4; --Delete the array element with specified index
UPDATE api SET jdoc = jdoc - 'a'; --Delete Key value pair. Based on object key = 'a'.\
-- || Concatenate two jsonb values into a new jsonb value
UPDATE api set jdoc = jdoc
                          || '{"city": "delhi", "isactive": true, "num": 877.4672}' where id = 2;
--Concatenating two objects generates an object containing the union of their keys,
-- taking the second object's value when there are duplicate keys. only the top-level array or object structure is merged.
insert into api(jdoc) values (
'{"name": "firstName", "city": "ottawa", "province": "ON", "phone": "phonenum", "prefix": "prefixedName"}');
update api set
    jdoc =jdoc || '{"city": "delhi", "phone": "28903790", "prefix": "dl"}'
    where id = 33;

UPDATE api SET jdoc =
    jsonb_set(jdoc, '{items}', jdoc->'items' || '{"price": 4.57}')
    where id = 8;--add low level objects.

select jdoc -> 'members' ->'coach'  from api where id = 22;
---Nested JSONB update. --https://www.postgresql.org/docs/current/functions-json.html
update api set jdoc = jsonb_set(jdoc, '{members,coach,name}', to_jsonb('2 dude'::text)) where id = 22;
update api set jdoc = jsonb_set(jdoc, '{members,coach,id}', '22') where id = 22;

--Using jsonb_build_object to add more key value pair in a jsonb column.
UPDATE api SET jdoc =
    jsonb_set(jdoc, '{items}', jdoc->'items' || jsonb_build_object('price', 4.57, 'discount', 0.1))
    where id = 9;

/* UPDATE JSON key  top-level.
   set jdoc = jdoc - 'nme' remove key value pair where key is 'nme'.
   jsonb_build_object('name', jdoc->'nme') build an JSON object, key is name.value is jdoc->'nme'
 */
update api
set jdoc = jdoc - 'nme' || jsonb_build_object('name', jdoc->'nme')
where jdoc ? 'nme' --does 'nme' exists as a top-level key within JSON value.
returning *;

--COALESCE  id = 9's jdoc is null then "{}' then add object. '{"alerts": false}'
UPDATE api SET jdoc =  coalesce(jdoc, '{}') || '{"alerts": false}' where id = 9;



Deletes a key (and its value) from a JSON object, or matching string value(s) from a JSON array.
'{"a": "b", "c": "d"}'::jsonb - 'a' → {"c": "d"}
update api set jdoc = jdoc -'lat'  where id = 15;

UPDATE table_a
SET data_column = data_column - 'attr_1'
WHERE type = 'type_a';

begin;
CREATE temp TABLE x(
  id BIGSERIAL PRIMARY KEY,
  data JSONB
);
INSERT INTO x(data)
VALUES( '{"a":"test", "b":123, "c":null, "d":true}' ),
      ( '{"a":"test", "b":123, "c":null, "d":"yay", "e":"foo", "f":[1,2,3]}' );
commit;



SELECT
    json_data.key,
    jsonb_typeof(json_data.value) as valuetype,
    count(*) as type_count
FROM x, jsonb_each(x.data) AS json_data
group by 1,2 order by key;
----------------------JSONB to materialized view.
insert into api(jdoc) values ('[{"event_slug":"test_1","start_time":"2014-10-08","end_time":"2014-10-12"},
 {"event_slug":"test_2","start_time":"2013-06-24","end_time":"2013-07-02"},
 {"event_slug":"test_3","start_time":"2014-03-26","end_time":"2014-03-30"}]');

 CREATE TYPE event_type AS (
   event_slug  text
  , start_time  timestamp
  , end_time    timestamp
 );
 CREATE MATERIALIZED VIEW loc_event AS
 SELECT a.id, e.event_slug, e.end_time, e.start_time
 FROM  api a, jsonb_populate_recordset(null::event_type, a.jdoc) e where a.id = 34;
 ------------------------------------------
--find the last item in an json array.
SELECT jdoc->-1 FROM   api a  WHERE  id = 36;
--How to query a json column for empty objects. in this case, the key is 'tags', the value pair is not empty array.
select id,jdoc ->> 'tags' from api
    where jdoc ->> 'tags' is not null and jdoc ->> 'tags' <> '[]'::text;