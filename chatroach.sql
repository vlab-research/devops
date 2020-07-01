/* USAGE AT SETUP:
*****************
export VLAB_NAME=foo
cat chatroach.sql | kubectl run -i --rm cockroach-client --image=cockroachdb/cockroach:v19.2.3 --restart=Never --command -- ./cockroach sql --insecure --host ${VLAB_NAME}-cockroachdb-public.default
*****************
*/

CREATE DATABASE chatroach;

-- TODO: add pageid (already in the JSON) or just make JSON field?
CREATE TABLE chatroach.messages(
       id BIGINT PRIMARY KEY,
       content VARCHAR NOT NULL,
       userid VARCHAR NOT NULL,
       timestamp TIMESTAMPTZ NOT NULL,
       INDEX (userid) STORING (content, timestamp asc)
);

CREATE TABLE chatroach.users(
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       typeform_token VARCHAR NOT NULL,
       email VARCHAR NOT NULL UNIQUE
);

CREATE TABLE chatroach.users_projects(
       userid UUID NOT NULL REFERENCES chatroach.users(id) ON DELETE CASCADE,
       projectid UUID NOT NULL REFERENCES chatroach.projects(id) ON DELETE CASCADE
);

CREATE TABLE chatroach.projects(
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       name VARCHAR NOT NULL
);

CREATE TABLE chatroach.facebook_pages(
       pageid VARCHAR PRIMARY KEY,
       token VARCHAR NOT NULL,
       projectid UUID REFERENCES chatroach.projects(id) ON DELETE CASCADE
);

CREATE TABLE chatroach.surveys(
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       created TIMESTAMPTZ NOT NULL,
       formid VARCHAR NOT NULL,
       form VARCHAR NOT NULL,
       messages VARCHAR,
       shortcode VARCHAR NOT NULL,
       title VARCHAR NOT NULL,
       projectid UUID NOT NULL REFERENCES chatroach.projects(id) ON DELETE CASCADE
);

CREATE TABLE chatroach.responses(
       parent_surveyid UUID NOT NULL REFERENCES chatroach.surveys(id),
       parent_shortcode VARCHAR NOT NULL, -- implicit reference to surveys.shortcode
       surveyid UUID NOT NULL REFERENCES chatroach.surveys(id),
       shortcode VARCHAR NOT NULL, -- implicit reference to surveys.shortcode
       flowid INT NOT NULL,
       userid VARCHAR NOT NULL,
       question_ref VARCHAR NOT NULL,
       question_idx INT NOT NULL,
       question_text VARCHAR NOT NULL,
       response VARCHAR NOT NULL,
       seed INT NOT NULL,
       timestamp TIMESTAMPTZ NOT NULL,
       PRIMARY KEY (userid, timestamp, question_ref) -- bit hacky, remove timestamp?
);

CREATE TABLE chatroach.timeouts(
       userid VARCHAR NOT NULL,
       pageid VARCHAR NOT NULL REFERENCES chatroach.facebook_pages(pageid),
       timeout_date TIMESTAMPTZ,
       fulfilled BOOLEAN,
       PRIMARY KEY (userid, timeout_date),
       INDEX (fulfilled, timeout_date) STORING (pageid)
);


CREATE TABLE chatroach.states(
       userid VARCHAR NOT NULL,
       timestamp TIMESTAMPTZ NOT NULL,
       state JSON NOT NULL,
       PRIMARY KEY (userid)
);


CREATE USER chatroach;
GRANT INSERT,SELECT ON TABLE chatroach.messages to chatroach;
GRANT INSERT,SELECT ON TABLE chatroach.responses to chatroach;
GRANT INSERT,SELECT,UPDATE ON TABLE chatroach.timeouts to chatroach;
GRANT INSERT,SELECT,UPDATE ON TABLE chatroach.users to chatroach;
GRANT INSERT,SELECT,UPDATE ON TABLE chatroach.surveys to chatroach;
GRANT INSERT,SELECT,UPDATE ON TABLE chatroach.facebook_pages to chatroach;
GRANT INSERT,SELECT,UPDATE ON TABLE chatroach.states to chatroach;
