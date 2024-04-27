#!/usr/bin/env python3
import psycopg2
from datetime import datetime, timedelta
#####################################################
##  Database Connection
#####################################################

'''
Connect to the database using the connection string
'''
def openConnection():
    # connection parameters - ENTER YOUR LOGIN AND PASSWORD HERE
    userid = ""
    passwd = ""
    myHost = "127.0.0.1"

    # Create a connection to the database
    conn = None
    try:
        # Parses the config file and connects using the connect string
        conn = psycopg2.connect(database="",
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
    cursor.execute("SELECT * FROM Staff WHERE login = %s", (login,))
    staff = cursor.fetchone()
    if(staff == None):
        print('error')
    else:
        print(staff)
    if(staff[1] == password):
        print(list(staff))
        cursor.close()
        conn.close()
        return list(staff)
    else:
        return None

    return ['jdavis', '0123', 'Jamie', 'Davis', '0422349845', 'jdavis@mrc.com.au', '8 Grenfell Way Petersham NSW', 110915.20]


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
                  WHEN SecondaryGenre IS NOT NULL THEN CONCAT(', ', (SELECT GenreName FROM Genre WHERE GenreID = SecondaryGenre))
                  ELSE ''
                END) AS genre,
                Staff.FirstName || ' ' || Staff.LastName AS staff,
                Movie.Description AS description
            FROM
                Movie
                LEFT JOIN Genre g1 ON Movie.PrimaryGenre = g1.GenreID
                LEFT JOIN Genre g2 ON Movie.SecondaryGenre = g2.GenreID
                LEFT JOIN Staff ON Movie.ManagedBy = Staff.Login
            WHERE
                Staff.Login = %s
            ORDER BY
                Movie.Description ASC,
                Movie.Title DESC;
        """

    cursor.execute(query,(login,))
    movies = cursor.fetchall()

    # Converting 'movies' to a list of dictionaries
    column_names = [desc[0] for desc in cursor.description]
    movies_list = [dict(zip(column_names, movie)) for movie in movies]

    print(movies_list)
    cursor.close()
    conn.close()
    return movies_list


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
                    CONCAT((SELECT GenreName FROM Genre WHERE GenreID = PrimaryGenre),
                    CASE
                      WHEN SecondaryGenre IS NOT NULL THEN CONCAT(', ', (SELECT GenreName FROM Genre WHERE GenreID = SecondaryGenre))
                      ELSE ''
                    END) AS genre,
                    Staff.FirstName || ' ' || Staff.LastName AS staff,
                    Movie.Description AS description
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
    cursor.execute(query, ( searchString, searchString, searchString, searchString, searchString, twenty_years_ago))

    movies = cursor.fetchall()

    column_names = [desc[0] for desc in cursor.description]
    movies_list = [dict(zip(column_names, movie)) for movie in movies]

    print(movies_list)
    cursor.close()
    conn.close()
    return movies_list
'''
Add a new movie
'''
def addMovie(title, releasedate, genre1, genre2, staff, description):
    try:
        conn = openConnection()
        cursor = conn.cursor()
        query = '''
                INSERT INTO Movie (Title, ReleaseDate, PrimaryGenre, SecondaryGenre, AvgRating, ManagedBy, Description)
                VALUES (%s, %s,
                        (SELECT GenreID FROM Genre WHERE LOWER(GenreName) = LOWER(%s)),
                        (SELECT GenreID FROM Genre WHERE LOWER(GenreName) = LOWER(%s)),
                        0, %s, %s)
                '''

        cursor.execute(query, (title, releasedate, genre1, genre2, staff, description))

        conn.commit()

        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(e)
        return False


'''
Update an existing movie
'''
def updateMovie(movieid, title, releasedate, avgrating, genre1, genre2, staff, description):
    try:
        conn = openConnection()
        cursor = conn.cursor()
        query = f"""UPDATE Movie
                            SET Title = %s,
                                ReleaseDate = %s,
                                AvgRating = %s,
                                PrimaryGenre = (SELECT GenreID FROM Genre WHERE LOWER(GenreName) = LOWER(%s)),
                                SecondaryGenre = (SELECT GenreID FROM Genre WHERE LOWER(GenreName) = LOWER(%s)),
                                ManagedBy = (SELECT Login FROM Staff WHERE CONCAT(FirstName, ' ', LastName) = %s),
                                Description = %s
                            WHERE ID = %s;"""
        cursor.execute(query, (title, releasedate, avgrating, genre1, genre2, staff, description, movieid))

        conn.commit()

        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(e)
        return False
