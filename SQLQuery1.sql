-- ==============================================================================
-- NETFLIX DATA ANALYSIS USING SQL
-- Advanced Solutions for 18 Business Problems
-- ==============================================================================

-- 1. Count the number of Movies vs TV Shows
SELECT 
    type,
    COUNT(*) AS total_content
FROM netflix
GROUP BY type;

-- 2. Find the most common rating for movies and TV shows
WITH RatingCounts AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY type, rating
),
RankedRatings AS (
    SELECT 
        type,
        rating,
        rating_count,
        RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS rank
    FROM RatingCounts
)
SELECT 
    type,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rank = 1;

-- 3. List all movies released in a specific year (e.g., 2020)
SELECT * FROM netflix
WHERE type = 'Movie' AND release_year = 2020;

-- 4. Find the top 5 countries with the most content on Netflix
SELECT TOP 5 
    TRIM(value) AS country_name, 
    COUNT(*) AS total_content
FROM netflix
CROSS APPLY STRING_SPLIT(country, ',')
WHERE value IS NOT NULL AND TRIM(value) <> ''
GROUP BY TRIM(value)
ORDER BY total_content DESC;

-- 5. Identify the longest movie
SELECT TOP 1 * FROM netflix
WHERE type = 'Movie'
ORDER BY CAST(LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT) DESC;

-- 6. Find content added in the last 5 years (Dynamic based on max dataset date)
SELECT *
FROM netflix
WHERE TRY_CAST(LTRIM(RTRIM(date_added)) AS DATE) >= 
      DATEADD(year, -5, (SELECT MAX(TRY_CAST(LTRIM(RTRIM(date_added)) AS DATE)) FROM netflix));

-- 7. Find all the movies/TV shows by director 'Martin Scorsese' (From USA)
SELECT *
FROM netflix
CROSS APPLY STRING_SPLIT(director, ',')
WHERE TRIM(value) = 'Martin Scorsese'
  AND country LIKE '%United States%';

-- 8. List all TV shows with more than 5 seasons
SELECT *
FROM netflix
WHERE type = 'TV Show'
  AND CAST(LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT) > 5;

-- 9. Count the number of content items in each genre
SELECT 
    TRIM(value) AS genre,
    COUNT(*) AS total_content
FROM netflix
CROSS APPLY STRING_SPLIT(listed_in, ',')
GROUP BY TRIM(value)
ORDER BY total_content DESC;

-- 10. Find each year and the percentage of content release by United States on Netflix
SELECT TOP 5
    release_year,
    COUNT(show_id) AS total_release,
    ROUND(
        CAST(COUNT(show_id) AS FLOAT) / 
        CAST((SELECT COUNT(show_id) FROM netflix WHERE country LIKE '%United States%') AS FLOAT) * 100, 
    2) AS us_release_percentage
FROM netflix
WHERE country LIKE '%United States%' 
GROUP BY release_year
ORDER BY us_release_percentage DESC;

-- 11. List all movies that are documentaries
SELECT * FROM netflix
WHERE type = 'Movie' AND listed_in LIKE '%Documentaries%';

-- 12. Find all content without a director
SELECT * FROM netflix
WHERE director IS NULL OR TRIM(director) = '';

-- 13. Find how many movies actor 'Adam Sandler' appeared in last 10 years
SELECT * FROM netflix
WHERE [cast] LIKE '%Adam Sandler%'
  AND release_year >= (SELECT MAX(release_year) FROM netflix) - 10;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in United States
SELECT TOP 10
    TRIM(value) AS actor,
    COUNT(*) AS total_appearances
FROM netflix
CROSS APPLY STRING_SPLIT(cast, ',')
WHERE country LIKE '%United States%'
GROUP BY TRIM(value)
ORDER BY total_appearances DESC;

-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. 
-- Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.
SELECT 
    category,
    type,
    COUNT(*) AS content_count
FROM (
    SELECT 
        *,
        CASE 
            WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY category, type
ORDER BY type;

-- 16. Seasonality Analysis: Best month for adding content on Netflix
SELECT 
    MONTH(TRY_CAST(LTRIM(RTRIM(date_added)) AS DATE)) AS addition_month,
    COUNT(*) AS total_content_added
FROM netflix
WHERE TRY_CAST(LTRIM(RTRIM(date_added)) AS DATE) IS NOT NULL
GROUP BY MONTH(TRY_CAST(LTRIM(RTRIM(date_added)) AS DATE))
ORDER BY total_content_added DESC;

-- 17. Co-occurrence: Most frequent Director-Actor duo
SELECT TOP 5
    TRIM(d.value) AS director,
    TRIM(a.value) AS actor,
    COUNT(*) AS collaboration_count
FROM netflix
CROSS APPLY STRING_SPLIT(director, ',') d
CROSS APPLY STRING_SPLIT(cast, ',') a
WHERE d.value IS NOT NULL AND a.value IS NOT NULL
  AND TRIM(d.value) <> '' AND TRIM(a.value) <> ''
GROUP BY TRIM(d.value), TRIM(a.value)
ORDER BY collaboration_count DESC;

-- 18. Missing Data: Null percentages in critical columns
SELECT 
    ROUND(SUM(CASE WHEN director IS NULL OR TRIM(director) = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS missing_director_pct,
    ROUND(SUM(CASE WHEN country IS NULL OR TRIM(country) = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS missing_country_pct
FROM netflix;

-- ==============================================================================
-- End of reports
-- ==============================================================================