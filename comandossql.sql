# En la consola en el proyecto donde guardamos el archivo
# sqlite3 imdb-large.sqlite3.db
# .tables + enter debería traer las tablas
# The query result has to be exactly like pledu result
# GROUP BY: https://www.w3schools.com/sql/sql_groupby.asp
# schema sqlite3: https://www.dbschema.com/sqlite-database-client.html
*
#-------------------------
# Birthyear
# Encontrá todas las películas hechas en el año que naciste.

SELECT * FROM movies
  WHERE year = 1986;

#-------------------------
# 1982
# ¿Cuantás películas tiene nuestra base de datos para el año 1982?

SELECT COUNT(*) AS No_of_movies, year FROM movies
  WHERE year = 1982;

#-------------------------
# Stacktors
# Encontrá los actores que tienen "stack" en su apellido.

SELECT * FROM actors
  WHERE last_name LIKE '%stack%';

#-------------------------
# Fame Name Game
#¿Cúales son los 10 nombres más populares? ¿Cúales son los 10 apellidos más populares? ¿Cuales son los full_names más populares (nombre y apellido)?

SELECT COUNT(*) AS occurrences, first_name FROM actors
  GROUP BY first_name
  ORDER BY occurrences DESC
  LIMIT 10;

#-------------------------
# Prolific
# Listá el top 100 de actores más activos y el numero de roles que hayan participado.

SELECT actors.first_name || ' ' || actors.last_name AS actor, COUNT(*) AS n_of_roles FROM roles
INNER JOIN actors ON roles.actor_id = actors.id
  GROUP BY roles.actor_id
  ORDER BY n_of_roles DESC
  LIMIT 100;

#-------------------------
# Bottom of the Barrel
# ¿Cuántas películas tiene IMBD de cada género, ordenado por el género más popular?

SELECT genre, COUNT(*) AS No_of_movies FROM movies_genres
INNER JOIN movies ON movies.id = movies_genres.movie_id
  GROUP BY genre
  ORDER BY No_of_movies DESC;

#-------------------------
# Braveheart
# Lista el nombre y apellido de todos los actores que actuaron en la película 'Braveheart' de 1995, ordenados alfabéticamente por sus apellidos.
# ORDER BY es ASC by default

SELECT first_name, last_name FROM movies
INNER JOIN roles ON roles.movie_id = movies.id
INNER JOIN actors ON roles.actor_id = actors.id
  WHERE movies.name = 'Braveheart' AND movies.year = 1995
  ORDER BY actors.last_name; 

#-------------------------
# Leap Noir 🌶
# Listá todos los directores que dirigieron una película de género 'Film-Noir' en un año bisiesto
# (para este challenge hagamos de cuenta que todos los años divisibles por 4 son años bisiestos - lo cual no es verdad en la vida real).
# Tu query debería retornar el nombre del director, el nombre de la película y el año, ordenado por el nombre de la película.
# || = concatenation -> 'hello' || ' ' || 'world' = 'hello world'

SELECT (directors.first_name || ' ' || directors.last_name) AS director_name, movies.name, movies.year FROM movies
INNER JOIN movies_genres ON movies_genres.movie_id = movies.id
INNER JOIN movies_directors ON movies_directors.movie_id = movies.id
INNER JOIN directors ON movies_directors.director_id = directors.id
  WHERE (movies.year % 4) = 0 AND movies_genres.genre = 'Film-Noir'
  ORDER BY movies.name;

#-------------------------
# ° Bacon 🌶🌶
# Lista todos los actores que han trabajado con Kevin Bacon en una película de Drama (incluí el nombre de la película). Por favor exluí al Sr. Bacon de los resultados.
# Joins Performance > Subqueries Performance. De esto se encarga el query optimizer
# Subqueries are more understandable
# https://www.essentialsql.com/what-is-the-difference-between-a-join-and-subquery/

#-- // Using SubQueries -- //
SELECT actors.first_name, actors.last_name, movies.name AS movie FROM roles
  INNER JOIN actors ON roles.actor_id = actors.id
  INNER JOIN movies ON movies.id = roles.movie_id
  WHERE movie_id IN (
                    SELECT movie_id FROM roles
                      WHERE actor_id  = (
                                          SELECT id from actors
                                          WHERE first_name = 'Kevin' AND last_name = 'Bacon'
                                        )
                    )
    AND movie_id IN (
                     SElECT movie_id FROM movies_genres
                     WHERE genre = 'Drama'
                     )
    AND (actors.first_name != 'Kevin' And actors.last_name != 'Bacon');

#-- // Using Joins -- //
SELECT movies.name, actors.first_name, actors.last_name FROM actors
INNER JOIN roles ON roles.actor_id = actors.id
INNER JOIN movies ON roles.movie_id = movies.id
WHERE movies.id IN (
    SELECT roles.movie_id FROM movies
    INNER JOIN roles ON roles.movie_id = movies.id
    INNER JOIN actors ON roles.actor_id = actors.id
    INNER JOIN movies_genres ON movies_genres.movie_id = movies.id
      WHERE movies_genres.genre = 'Drama' AND actors.first_name = 'Kevin' AND actors.last_name='Bacon'
      ORDER BY movies.name
) AND actors.first_name != 'Kevin' AND actors.last_name != 'Bacon'
ORDER BY movies.name;

#-------------------------
# Interludio: Índices 

# CREATE INDEX "actors_idx_first_name" ON "actors" ("first_name");
# CREATE INDEX "actors_idx_last_name" ON "actors" ("last_name");
# DROP INDEX "actors_idx_first_name";
# DROP INDEX "actors_idx_last_name";

#-------------------------  
#  Immortal Actors 🌶🌶🌶
# ¿Cúales actores han actuado en un film antes de 1900 y también en un film luego del 2000? 
# NOTA; no estamos pidiendo todos los actores pre-1900 y post-2000, 
# ¡estamos pidiendo por cada actor que haya trabajado en ambas eras!

#-- // Using SubQueries -- //
SELECT actors.first_name, actors.last_name, actors.id FROM roles
  INNER JOIN actors ON roles.actor_id = actors.id
  WHERE actor_id IN (
                     SELECT actor_id  FROM  roles
                      where  movie_id IN (
                                            SElECT id FROM movies
                                            WHERE year < 1900
                                          )
                    )
    AND  actor_id IN (
                        SELECT actor_id  FROM  roles
                          where  movie_id IN (
                                                SElECT id FROM movies
                                                WHERE year > 2000
                                              )
                       )
  GROUP BY first_name, last_name
  ORDER BY last_name;

#-- // Using Joins -- //
SELECT actors.first_name, actors.last_name, actors.id FROM actors
INNER JOIN roles ON roles.actor_id=actors.id
INNER JOIN movies ON roles.movie_id=movies.id
  WHERE movies.year < 1900 
  AND actors.id IN (
      SELECT actors.id FROM actors
      INNER JOIN roles ON roles.actor_id=actors.id
      INNER JOIN movies ON roles.movie_id=movies.id
        WHERE movies.year > 2000
  )
  GROUP BY actors.first_name
  ORDER BY actors.id;

#-------------------------   
# Busy Filming 🌶🌶🌶🌶
# Buscá actores que hayan hecho cinco o más roles en la misma película luego del año 1990. Notá que ROLES puede tener duplicaciones ocasionales, 
# pero no estamos interesados en esto: queremos actores que tienen cinco o más roles distintos en la misma película. Escribí un query que retorne 
# el nombre del actor, el nombre de la película y el número de roles distintos que hicieron en esa película (que va a ser ≥5).

SELECT actors.first_name, actors.last_name, movies.name, movies.year, count(distinct roles.role) as num_roles FROM actors
INNER JOIN roles ON roles.actor_id=actors.id
INNER JOIN movies ON roles.movie_id=movies.id
  WHERE year > 1990
  GROUP BY roles.actor_id, roles.movie_id
  HAVING num_roles >= 5
  ORDER BY movies.name DESC;

#------------------------- 
# ♀ 🌶🌶🌶🌶🌶
# Para cada año, contá los números de películas en ese año que tuvieron 
# sólo actrices. Podés empezar por incluir películas sin reparto, 
# pero tu objetivo es estrechar tu búsqueda a sólo películas que tuvieron reparto.

# se pueden probar otras formas de hacerlo, alguna pista rápido puede ser el tiempo de rta de querie
# o ver el rendimiento del CPU y en cuanto tiempo se estabiliza para tener una idea de rendimiento

#-- Most Perfomance Query
SELECT movies.year, count(movies.id) FROM movies
WHERE movies.id IN
(
  SELECT movie_id FROM roles
  WHERE actor_id IN
    ( 
      SELECT actors.id FROM actors
      WHERE actors.gender="F"
      GROUP BY actors.id
    )
  EXCEPT
  SELECT movie_id FROM roles
    WHERE actor_id IN
      ( 
        SELECT actors.id FROM actors
        WHERE actors.gender = "M"
        GROUP BY actors.id
      )

  GROUP BY movie_id
)
GROUP BY movies.year
ORDER BY movies.year;

#-- Other Way
SELECT movies.year, COUNT(DISTINCT movie_id) as num_movies FROM movies
  INNER JOIN roles ON roles.movie_id = movies.id
  WHERE movies.id NOT IN (
                      SELECT DISTINCT movie_id from roles
                        INNER JOIN actors ON roles.actor_id = actors.id
                        WHERE actors.gender = 'M'
                     )
  GROUP BY year;

#------------------------- 
#------------------------- 
#------------------------- 


