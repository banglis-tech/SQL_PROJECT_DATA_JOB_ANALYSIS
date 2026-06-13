/*
Question: what are the top paying data analyst jobs?
-Identify top 10 highest paying Data Analyst roles that are available remotely
-Focus on job postings with specified salaries (remove nulls)
-why? Highlight the top-paying opportunities for Data Analysis, offering insights into employment trends and salary expectations in the field.
*/

SELECT
    job_id,
    job_title,
    job_location,
    job_schedule_type,
    salary_year_avg,
    job_posted_date :: DATE AS posted_date,
    name AS company_name
FROM
    job_postings_fact j
    LEFT JOIN company_dim c ON j.company_id = c.company_id
WHERE
    job_title_short = 'Data Analyst' AND
    job_location = 'Anywhere' AND
    salary_year_avg IS NOT NULL
ORDER BY
    salary_year_avg DESC
LIMIT 10;