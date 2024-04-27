#!/usr/bin/env python3
import psycopg2
from datetime import datetime, timedelta
#####################################################
## Database Connection
#####################################################
'''
Connect to the database using the connection string
'''
def openConnection():
# connection parameters - ENTER YOUR LOGIN AND PASSWORD HERE
userid = "y23s1c9120_zzhu2278"
passwd = "W9U28K4f"
myHost = "soit-db-pro-2.ucc.usyd.edu.au"
# Create a connection to the database
conn = None
try:
# Parses the config file and connects using the connect string
conn = psycopg2.connect(database="y23s1c9120_zzhu2278",
user=userid,
password=passwd,
host=myHost)
except psycopg2.Error as sqle:
print("psycopg2.Error : " + sqle.pgerror)
# return the connection to use
return conn
'''
Validate staff based on login and password
'''
def checkStaffCredentials(login, password):
conn = openConnection()
cursor = conn.cursor()
cursor.execute("SELECT * FROM Staff WHERE LOWER(login) = LOWER(%s)", (login,))
staff = cursor.fetchone()
#check the user loginname
if(staff == None):
cursor.close()
conn.close()
return None
#check the password
if(staff[1] == password):
cursor.close()
conn.close()
return list(staff)
else:
cursor.close()
conn.close()
return None
'''
List all the associated movies in the database by staff
'''
def findMoviesByStaff(login):
conn = openConnection()
cursor = conn.cursor()
query = """
SELECT
Movie.id AS movie_id,
Movie.Title AS title,
TO_CHAR(Movie.ReleaseDate,'DD-MM-YYYY') AS releasedate,
Movie.AvgRating AS avgrating,
CONCAT((SELECT GenreName FROM Genre WHERE GenreID = PrimaryGenre),
CASE
WHEN SecondaryGenre IS NOT NULL THEN CONCAT(', ', (SELECT
GenreName FROM Genre WHERE GenreID = SecondaryGenre))
ELSE ''
END) AS genre,
COALESCE(Staff.FirstName || ' ' || Staff.LastName, '') AS staff,
COALESCE(Movie.Description, '') AS description
FROM
Movie
LEFT JOIN Genre g1 ON Movie.PrimaryGenre = g1.GenreID
LEFT JOIN Genre g2 ON Movie.SecondaryGenre = g2.GenreID
LEFT JOIN Staff ON Movie.ManagedBy = Staff.Login
WHERE
LOWER(Staff.Login) = LOWER(%s)
ORDER BY
Movie.ReleaseDate DESC,
Movie.Description ASC,
Movie.Title DESC;
"""
cursor.execute(query,(login,))
movies = cursor.fetchall()
# convert movie from list to dict
column_names = [desc[0] for desc in cursor.description] # get the column from
the cursor
movies_dict = [dict(zip(column_names, movie)) for movie in movies] #use zip to
create a list of tuple, then use dict to create dict
cursor.close()
conn.close()
return movies_dict
'''
Find a list of movies based on the searchString provided as parameter
See assignment description for search specification
'''
def findMoviesByCriteria(searchString):
conn = openConnection()
cursor = conn.cursor()
searchString = f"%{searchString}%"
query = """
SELECT
Movie.id AS movie_id,
Movie.Title AS title,
TO_CHAR(Movie.ReleaseDate,'DD-MM-YYYY') AS releasedate,
Movie.AvgRating AS avgrating,
CONCAT((SELECT GenreName FROM Genre WHERE GenreID =
PrimaryGenre),
CASE
WHEN SecondaryGenre IS NOT NULL THEN CONCAT(', ', (SELECT
GenreName FROM Genre WHERE GenreID = SecondaryGenre))
ELSE ''
END) AS genre,
COALESCE(Staff.FirstName || ' ' || Staff.LastName, '') AS
staff,
COALESCE(Movie.Description, '') AS description
FROM
Movie
LEFT JOIN Genre g1 ON Movie.PrimaryGenre = g1.GenreID
LEFT JOIN Genre g2 ON Movie.SecondaryGenre = g2.GenreID
LEFT JOIN Staff ON Movie.ManagedBy = Staff.Login
WHERE
(
LOWER(Movie.Title) LIKE LOWER(%s)
OR LOWER(g1.GenreName) LIKE LOWER(%s)
OR LOWER(g2.GenreName) LIKE LOWER(%s)
OR LOWER(Staff.FirstName || ' ' || Staff.LastName) LIKE LOWER(%s)
OR LOWER(Movie.Description) LIKE LOWER(%s)
)
AND Movie.ReleaseDate >= %s
ORDER BY
(Movie.Description IS NULL) DESC,
Movie.ReleaseDate DESC;
"""
twenty_years_ago = datetime.now() - timedelta(days=20 * 365)
cursor.execute(query, (searchString, searchString, searchString, searchString,
searchString, twenty_years_ago))
movies = cursor.fetchall()
# convert movie from list to dict
column_names = [desc[0] for desc in cursor.description] # get the column from
the cursor
movies_dict = [dict(zip(column_names, movie)) for movie in movies] #use zip to
create a list of tuple, then use dict to create dict
cursor.close()
conn.close()
return movies_dict
'''
Add a new movie
'''
def addMovie(title, releasedate, genre1, genre2, staff, description):
try:
conn = openConnection()
cursor = conn.cursor()
# query = f"SELECT add_movie(%s, %s, %s, %s, %s, %s);"
# cursor.execute(query, (title, releasedate, genre1, genre2, staff,
description))
cursor.callproc('add_movie',[title, releasedate, genre1, genre2, staff,
description])
success = cursor.fetchone()[0]
conn.commit()
cursor.close()
conn.close()
return success
except Exception as e:
print(e)WHEN SecondaryGenre IS NOT NULL THEN CONCAT(', ', (SELECT
GenreName FROM Genre WHERE GenreID = SecondaryGenre))
ELSE ''
END) AS genre,
COALESCE(Staff.FirstName || ' ' || Staff.LastName, '') AS
staff,
COALESCE(Movie.Description, '') AS description
FROM
Movie
LEFT JOIN Genre g1 ON Movie.PrimaryGenre = g1.GenreID
LEFT JOIN Genre g2 ON Movie.SecondaryGenre = g2.GenreID
LEFT JOIN Staff ON Movie.ManagedBy = Staff.Login
WHERE
(
LOWER(Movie.Title) LIKE LOWER(%s)
OR LOWER(g1.GenreName) LIKE LOWER(%s)
OR LOWER(g2.GenreName) LIKE LOWER(%s)
OR LOWER(Staff.FirstName || ' ' || Staff.LastName) LIKE LOWER(%s)
OR LOWER(Movie.Description) LIKE LOWER(%s)
)
AND Movie.ReleaseDate >= %s
ORDER BY
(Movie.Description IS NULL) DESC,
Movie.ReleaseDate DESC;
"""
twenty_years_ago = datetime.now() - timedelta(days=20 * 365)
cursor.execute(query, (searchString, searchString, searchString, searchString,
searchString, twenty_years_ago))
movies = cursor.fetchall()
# convert movie from list to dict
column_names = [desc[0] for desc in cursor.description] # get the column from
the cursor
movies_dict = [dict(zip(column_names, movie)) for movie in movies] #use zip to
create a list of tuple, then use dict to create dict
cursor.close()
conn.close()
return movies_dict
'''
Add a new movie
'''
def addMovie(title, releasedate, genre1, genre2, staff, description):
try:
conn = openConnection()
cursor = conn.cursor()
# query = f"SELECT add_movie(%s, %s, %s, %s, %s, %s);"
# cursor.execute(query, (title, releasedate, genre1, genre2, staff,
description))
cursor.callproc('add_movie',[title, releasedate, genre1, genre2, staff,
description])
success = cursor.fetchone()[0]
conn.commit()
cursor.close()
conn.close()
return success
except Exception as e:
print(e)
return False
'''
Update an existing movie
'''
def updateMovie(movieid, title, releasedate, avgrating, genre1, genre2, staff,
description):
try:
conn = openConnection()
cursor = conn.cursor()
print(genre2)
# query = f"SELECT update_movie(%s, %s, %s, CAST(%s AS DECIMAL), %s, %s,
%s, %s);"
# cursor.execute(query, (movieid, title, releasedate, avgrating, genre1,
genre2, staff, description))
cursor.callproc('update_movie', [movieid, title, releasedate, avgrating,
genre1, genre2, staff, description])
success = cursor.fetchone()[0]
print(success)
conn.commit()
cursor.close()
conn.close()
return success
except Exception as e:
print(e)
return False