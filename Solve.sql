-- 1. Who is the senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT COUNT(*) AS invoice_count, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

-- 3. What are top 3 values of total invoice?
SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

-- 4. Which city has the best customers? 
-- We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. 
-- Return both the city name & sum of all invoice totals
SELECT billing_city, SUM(total) AS invoice_totals
FROM invoice
GROUP BY billing_city
ORDER BY invoice_totals DESC
LIMIT 1;

-- 5. Who is the best customer? 
-- The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money
SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS total
FROM customer
JOIN invoice 
ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total DESC
LIMIT 1;

-- 6. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A
SELECT customer.first_name, customer.last_name, customer.email, genre.name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name = 'Rock'
ORDER BY customer.email;

-- OR

SELECT customer.first_name, customer.last_name, customer.email
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE invoice_line.track_id IN (
	SELECT track_id FROM track 
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name = 'Rock')
ORDER BY customer.email

-- 7. Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands
SELECT DISTINCT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM artist
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON album.album_id = track.album_id
WHERE track_id IN (
	SELECT track_id FROM track 
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name = 'Rock')
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

-- 8. Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first
SELECT name, milliseconds 
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_song_length 
	FROM track) 
ORDER BY milliseconds DESC;

-- 9. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent
WITH best_selling_artist AS(
	SELECT artist.artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price * invoice_line.quantity) AS total
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON track.album_id = album.album_id
	JOIN artist ON album.artist_id = artist.artist_id
	GROUP BY 1 
	ORDER BY 3 DESC
	LIMIT 1
	)

SELECT C.customer_id, C.first_name,  C.last_name, BSA.artist_name, SUM(IL.unit_price * IL.quantity) AS amount_spent
FROM invoice I
JOIN customer C ON I.customer_id = C.customer_id
JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
JOIN track T ON T.track_id = IL.track_id
JOIN album A ON T.album_id = A.album_id
JOIN artist AR ON A.artist_id = AR.artist_id 
JOIN best_selling_artist BSA ON BSA.artist_id = AR.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- 10. We want to find out the most popular music Genre for each country.
-- We determine the most popular genre as the genre with the highest amount of purchases. 
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres
WITH popular_genres AS(
	SELECT g.genre_id, g.name AS genre_name, i.billing_country AS country, COUNT(*) AS purchases,
	RANK() OVER(
		PARTITION BY i.billing_country
		ORDER BY COUNT(il.quantity) DESC
		) AS rn
	FROM invoice i
	JOIN invoice_line il ON i.invoice_id = il.invoice_id
	JOIN track t ON il.track_id = t.track_id
	JOIN genre g ON t.genre_id = g.genre_id
	GROUP BY 1,2,3
	ORDER BY 3 ASC
)
SELECT * FROM  popular_genres
WHERE rn <= 1;

-- 11. Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount
WITH top_customer AS(
	SELECT customer.customer_id, customer.first_name AS First_Name, customer.last_name AS Last_Name, invoice.billing_country AS Country, SUM(invoice.total) AS Total_Spend,
	RANK() OVER (
		PARTITION BY invoice.billing_country
		ORDER BY SUM(invoice.total) DESC
		) AS rk
	FROM customer
	JOIN invoice ON customer.customer_id = invoice.customer_id
	JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
	GROUP BY 1, 2, 3, 4
	ORDER BY 5 DESC
)
SELECT First_Name, Last_Name, Country, Total_Spend FROM top_customer
WHERE rk = 1

-- OR

WITH RECURSIVE	
	customer_with_country AS (
		SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(i.total) AS total_spending 
		FROM customer c
		JOIN invoice i ON c.customer_id = i.customer_id
		GROUP BY 1, 2, 3, 4
		ORDER BY 5 DESC),

	country_max_spending AS (
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY 1)

SELECT cc.customer_id, cc.first_name, cc.last_name, cc.billing_country, cc.total_spending
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending




