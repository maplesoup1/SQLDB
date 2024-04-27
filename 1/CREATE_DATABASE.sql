DROP TABLE IF EXISTS usertable CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS movie CASCADE;
DROP TABLE IF EXISTS actor CASCADE;
DROP TABLE IF EXISTS genre CASCADE;
DROP TABLE IF EXISTS review CASCADE;
DROP TABLE IF EXISTS relatedrole CASCADE;
DROP TABLE IF EXISTS deleterecord CASCADE;
DROP TABLE IF EXISTS movie_belong_genre CASCADE;
DROP TABLE IF EXISTS customer_purchase_movie CASCADE;
DROP TABLE IF EXISTS movie_have_actor CASCADE;


CREATE TABLE usertable(
	user_id BIGSERIAL PRIMARY KEY,
	user_login_name VARCHAR(50) UNIQUE NOT NULL,
	user_password VARCHAR(50) NOT NULL,
	user_firstname VARCHAR(50) NOT NULL,
	user_middlename VARCHAR(50) NOT NULL,
	user_lastname VARCHAR(50) NOT NULL,
	user_email VARCHAR(100) NOT NULL,
	user_phone VARCHAR(50) NOT NULL,
	UNIQUE(user_email),
	UNIQUE(user_phone)
);
CREATE TABLE genre(
	genre_id BIGSERIAL PRIMARY KEY,
	genre_name VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE customer(
	PRIMARY KEY (user_id),
	UNIQUE(user_login_name),
	UNIQUE(user_email),
	UNIQUE(user_phone)
) INHERITS(usertable);

CREATE TABLE staff(
	user_address VARCHAR(100) NOT NULL,
	user_compensation NUMERIC NOT NULL CHECK (user_compensation > 0),
	PRIMARY KEY (user_id),
	UNIQUE(user_login_name),
	UNIQUE(user_email),
	UNIQUE(user_phone)
) INHERITS(usertable);



CREATE TABLE movie(
	movie_id BIGSERIAL PRIMARY KEY,
	movie_first_genre_id BIGINT NOT NULL,
	movie_first_role_id BIGINT UNIQUE NOT NULL,
	movie_name VARCHAR(50) NOT NULL,
	movie_description VARCHAR(50) NOT NULL,
	movie_avgrating DECIMAL(2,1) CHECK (movie_avgrating BETWEEN 1 AND 5),
	movie_dvdprice DECIMAL(7,2),
	movie_blurayprice DECIMAL(7,2),
	movie_uhdprice DECIMAL(7,2)
);

CREATE TABLE review(
	review_id BIGSERIAL PRIMARY KEY,
	movie_id BIGINT REFERENCES movie(movie_id) ON DELETE CASCADE ON UPDATE CASCADE,
	customer_id BIGINT REFERENCES customer(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
	review_rating INTEGER CHECK (review_rating BETWEEN 1 AND 5),
	review_text TEXT,
	review_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

CREATE TABLE deleterecord (
	delete_id BIGSERIAL PRIMARY KEY,
	review_id BIGINT REFERENCES review(review_id) ON DELETE CASCADE ON UPDATE CASCADE,
	staff_id BIGINT REFERENCES staff(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
	delete_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	UNIQUE(review_id)
);

CREATE TABLE actor(
	actor_id BIGSERIAL PRIMARY KEY,
	actor_firstname VARCHAR(50) NOT NULL,
	actor_middlename VARCHAR(50) NOT NULL,
	actor_lastname VARCHAR(50)
);

CREATE TABLE relatedrole(
	role_id BIGSERIAL PRIMARY KEY,
	actor_id BIGINT NOT NULL REFERENCES actor(actor_id),
	movie_id BIGINT NOT NULL REFERENCES movie(movie_id),
	role_name VARCHAR(100) NOT NULL,
	UNIQUE(movie_id,role_id)
);
CREATE TABLE movie_belong_genre(
	mbg_id BIGSERIAL PRIMARY KEY,
	movie_id BIGINT NOT NULL REFERENCES movie(movie_id),
	genre_id BIGINT NOT NULL REFERENCES genre(genre_id),
	UNIQUE(movie_id,genre_id)
);
CREATE TABLE customer_purchase_movie(
	purchase_id BIGSERIAL PRIMARY KEY,
	customer_id BIGINT NOT NULL REFERENCES customer(user_id),
	movie_id BIGINT NOT NULL REFERENCES movie(movie_id)
);
CREATE TABLE movie_have_actor(
	id BIGSERIAL PRIMARY KEY,
	actor_id BIGINT NOT NULL REFERENCES actor(actor_id),
	movie_id BIGINT NOT NULL REFERENCES movie(movie_id)
);
ALTER TABLE movie ADD CONSTRAINT movie_first_genre_id_fkey FOREIGN KEY (movie_id, movie_first_genre_id) REFERENCES movie_belong_genre(movie_id,genre_id);
ALTER TABLE movie ADD CONSTRAINT movie_first_role_id_fkey FOREIGN KEY (movie_id, movie_first_role_id) REFERENCES relatedrole(movie_id,role_id);
CREATE OR REPLACE FUNCTION update_average_rating()
RETURNS TRIGGER AS $$
DECLARE
  newavgrating DECIMAL(2,1);
BEGIN
  SELECT AVG(review_rating) INTO newavgrating
  FROM review;

  UPDATE movie
  SET movie_avgrating = newavgrating;


  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to call the update_average_rating() function after inserting or updating a review
CREATE TRIGGER update_average_rating_trigger
AFTER INSERT OR UPDATE ON review
FOR EACH ROW
EXECUTE FUNCTION update_average_rating();