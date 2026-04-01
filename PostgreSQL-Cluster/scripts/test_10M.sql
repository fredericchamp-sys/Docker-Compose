CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS test_big_data;

CREATE TABLE test_big_data (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid(),
    name TEXT,
    email TEXT,
    age INT,
    salary NUMERIC(10,2),
    is_active BOOLEAN,
    created_at TIMESTAMP,
    last_login TIMESTAMP,
    tags TEXT[],
    metadata JSONB
);

INSERT INTO test_big_data (
    name, email, age, salary, is_active,
    created_at, last_login, tags, metadata
)
SELECT
    'user_' || i,
    'user_' || i || '@test.com',
    (random() * 60 + 18)::INT,
    round((random() * 100000)::numeric, 2),
    (random() > 0.5),
    NOW() - (random() * interval '365 days'),
    NOW() - (random() * interval '30 days'),
    ARRAY['tag' || (random()*10)::int, 'tag' || (random()*10)::int],
    jsonb_build_object(
        'country', (ARRAY['FR','US','DE','UK','JP'])[floor(random()*5)+1],
        'score', round((random()*100)::numeric,2),
        'premium', (random() > 0.7)
    )
FROM generate_series(1, 10000000) i;


SELECT count(*) FROM test_big_data;