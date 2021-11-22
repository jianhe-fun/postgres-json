-- Edit | Indent Selection (Tab)
-- Edit | Unindent Selection (Shift+Tab)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Images;
DROP TABLE IF EXISTS Posts;

CREATE TABLE Users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL
);

CREATE TABLE Images (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        key TEXT,
        width INTEGER,
        height INTEGER,
        creator_id UUID
);

CREATE TABLE Posts (
   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
   title TEXT,
   author_id UUID,
   content JSONB
);


DO $$
DECLARE user_id UUID;
DECLARE image1_id UUID;
DECLARE image2_id UUID;
BEGIN
INSERT INTO Users (name) VALUES ('test user') RETURNING id INTO user_id;
INSERT INTO Images (key, width, height, creator_id) VALUES ('upload/test1.jpg', 800, 600, user_id) RETURNING id INTO image1_id;
INSERT INTO Images (key, width, height, creator_id) VALUES ('upload/test2.jpg', 600, 400, user_id) RETURNING id INTO image2_id;
INSERT INTO Posts (title, author_id, content) VALUES (
                                                         'test post',
                                                         user_id,
                                                         ('[ { "type": "text", "text": "learning pg" }, { "type": "image", "image_id": "' || image1_id || '" }, { "type": "image", "image_id": "' || image2_id || '" }, { "type": "text", "text": "pg is awesome" } ]') :: JSONB
                                                     );
END $$;

---Relationship: an user post multi posts. One posts can have multi images.
--Now consolidate Posts and Images.
SELECT jsonb_pretty(to_jsonb(p)) AS post_row_as_json
FROM  (
          SELECT id, title, author_id, c.content
          FROM   posts p
                     LEFT   JOIN LATERAL (
              SELECT jsonb_agg(
                                 CASE WHEN c.elem->>'type' = 'image' AND i.id IS NOT NULL
                                 THEN elem - 'image_id' || jsonb_build_object('image', i)
                    ELSE c.elem END) AS content
              FROM   jsonb_array_elements(p.content) AS c(elem)
                         LEFT   JOIN images i ON c.elem->>'type' = 'image'
              AND i.id = (elem->>'image_id')::uuid
      ) c ON true
   ) p;

select jsonb_build_object('image', i) from images i ;
select  jsonb_array_elements(p.content) from posts p;
-- jsonb_array_elements(p.content) unnest to one row one array.
--jsonb_agg first filter then aggregate it. Part1: jsonb_build_object('image', i)
--Part2, remain the same.
