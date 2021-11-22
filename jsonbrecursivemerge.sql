
--https://stackoverflow.com/questions/42944888/merging-jsonb-values-in-postgresql
--JSONB deep recursive deep merge.
create or replace function jsonb_recursive_merge(a jsonb, b jsonb)
returns jsonb language sql as $$
select
    jsonb_object_agg(
            coalesce(ka, kb),
            case
                when va isnull then vb
                when vb isnull then va
                when jsonb_typeof(va) <> 'object' then va || vb
                else jsonb_recursive_merge(va, vb)
                end
        )
from jsonb_each(a) e1(ka, va)
         full join jsonb_each(b) e2(kb, vb) on ka = kb
    $$;

select jsonb_recursive_merge(
               '{"a":{"b":{"c":3},"x":5}}'::jsonb,
               '{"a":{"b":{"d":4},"y":6}}'::jsonb);