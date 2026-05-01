--CREATE DATABASE sql_course;
DROP DATABASE IF EXISTS sql_course_;

select 
job_title_short as title,
job_location as location,
job_posted_date at time zone 'UTC' at time zone 'EST' as date_time,
EXTRACT(month from job_posted_date) as Month
from job_postings_fact
limit 5;

SELECT *
FROM job_postings_fact
WHERE EXTRACT(Month from job_posted_date) = 1;

Select 
 job_schedule_type,
 AVG(salary_year_avg) as Avverage_yearly_Salary,
 AVG(salary_hour_avg) as Average_hourly_salary
FROM job_postings_fact
WHERE  job_posted_date ::date > '2023-06-01'
group by job_schedule_type
order by job_schedule_type;


select * from job_postings_fact
limit 5;

-- grouping jobs by their respective months per the date they were posted adjusted to NY time
SELECT
    EXTRACT(Month from job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York') as Month,
    
    COUNT(*) as total_jobs
    
FROM job_postings_fact
GROUP BY 
    Month
ORDER BY 
    Month;

-- find companies that have poosted jobs offering health insurance in Q2 of 2023.
SELECT 
    c.name, -- company name
    COUNT(*) as job_posting _count -- total number of jobs offering health insurance
FROM 
    job_postings_fact j -- fact table with job postings data
JOIN 
    company_dim c ON j.company_id = c.company_id
WHERE 
    j.job_posted_date ::date >= '2023-04-01'
AND j.job_posted_date ::date < '2023-07-01'
AND j.job_health_insurance = true
GROUP BY 
    c.name
ORDER BY 
    job_posting _count DESC;
--or
select
    c.name as company_name,
    count(j.job_id) as total_job_postings
FROM 
    job_postings_fact j
    INNER JOIN 
    company_dim c ON j.company_id = c.company_id
WHERE
    j.job_health_insurance = true
    AND Extract(Quarter from j.job_posted_date) = 2 -- AND j.job_posted_date ::date >= '2023-04-01' -- Start of Q2
GROUP BY
    c.name
ORDER BY
    total_job_postings DESC;

-- Job categorizatio by salary from job_posting_fact that are data analyst jobs with yearly salary information in three category. 
SELECT 
    job_id,
    Job_title,
    salary_year_avg as yearly_salary,
    CASE 
        WHEN salary_year_avg < 60000 THEN 'Low Salary'
        WHEN salary_year_avg >= 60000 AND salary_year_avg < 100000 THEN 'Mid Salary'
        WHEN salary_year_avg >= 100000 THEN 'High Salary'
    END as Salary_Category
FROM job_postings_fact

WHERE 
    job_title_short ILIKE '%data analyst%' -- Filter for data analyst jobs
    AND salary_year_avg IS NOT NULL -- Ensure we have yearly salary information
ORDER BY 
    salary_year_avg DESC;


--unique companies offering work from home jobs vs those requiring work on site.
Select
    count(distinct case when job_work_from_home = true then company_id end) as WFH_Companies,
    count(distinct case when job_work_from_home = false then company_id end) as On_Site_Companies
from job_postings_fact;

-- return esperience level, remote option and and av salary per year
Select
    job_id,
    salary_year_avg,
    case
        when job_title ILIKE '%Senior%' then 'senior'
        when job_title ILIKE '%Manager%' or job_title ILIKE '%Lead%' then 'Lead/Manager'
        when job_title ILIKE '%Junior%' or job_title ILIKE '%Entry%' then 'Junior/Entry'
        else 'Not Specified'
    end as experience_level,
    case
        when job_work_from_home is true then 'Yes' else 'No'
    end as remote_option
from job_postings_fact
where salary_year_avg is not null
order by job_id;

-- identify 5 top skills that are most frequently mentioned in job postings. use sub query to find skill ids with highest counts in skills_job_dim table then join the result with the skills_dim table to get the skill name.

SELECT skills_dim.skills
FROM skills_dim
INNER JOIN(
    SELECT
        skill_id,
        COUNT(job_id) as skill_count
    FROM skills_job_dim
    GROUP BY skill_id
    ORDER BY skill_count DESC
    LIMIT 5
) as top_skills on skills_dim.skill_id = top_skills.skill_id
ORDER BY top_skills.skill_count DESC;

WITH company_job_counts As (
SELECT
    c.name as company_name,
    COUNT(job_id) as total_job_postings,
    CASE 
        WHEN COUNT(job_id) <= 10 THEN 'Small'
        WHEN COUNT(job_id) > 10 AND COUNT(job_id) <= 50 THEN 'Medium'
        ELSE 'Large'
    END as company_size    
FROM
    job_postings_fact j
    INNER JOIN company_dim c ON j.company_id = c.company_id
GROUP BY c.name
ORDER BY total_job_postings DESC
)
Select
    --company_name,
    company_size,
    COUNT(company_size) AS Number_of_companies
From company_job_counts
Group by company_size
order by company_size;

--COMPANIES WITH AVERAGE SALARY GREATER THAN OVERALL AVERAGE SALARY
WITH overall_avg_salary AS (
    SELECT AVG(salary_year_avg) AS avg_salary
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
),
company_avg_salary AS (

SELECT
    c.name as company_name,
    AVG(j.salary_year_avg) as avg_company_salary
FROM
    job_postings_fact j
    INNER JOIN company_dim c ON j.company_id = c.company_id
WHERE
    j.salary_year_avg IS NOT NULL
GROUP BY
    c.name
)
SELECT
    cas.company_name,
    cas.avg_company_salary,
    oas.avg_salary as overall_avg_salary
FROM
    company_avg_salary cas
    CROSS JOIN overall_avg_salary oas
WHERE
    cas.avg_company_salary > oas.avg_salary
ORDER BY
    cas.avg_company_salary DESC;

-- Identify comapnies with the most diverse unque titles

with title_diversity as (
    select
        company_id,
        COUNT(DISTINCT JOB_TITLE) AS UNIQUE_TITLES
    FROM job_postings_fact
    GROUP BY company_id
)

    SELECT
        c.name as company_name,
        title_diversity.unique_titles
    FROM title_diversity
    INNER JOIN company_dim c ON title_diversity.company_id = c.company_id
    ORDER BY
        UNIQUE_TITLES desc
    LIMIT 10;

--explore job postings by listing job id, job titles, company name and their average salary rates while categorizing salaries relative to the average in their respective countries. include the month of the posted date.
with country_avg_salary as (
    select
        job_country,
        AVG(salary_year_avg) as avg_salary
           from job_postings_fact
    where salary_year_avg is not null
    group by job_country
    )
--main query to get job details and categorize salaries
select
    j.job_id,
    j.job_country,
    j.job_title,
    c.name as company_name,
    j.salary_year_avg,
    case
        when j.salary_year_avg < cas.avg_salary then 'Below Average'
        when j.salary_year_avg = cas.avg_salary then 'At Average'
        else 'Above Average'
    end as salary_category,
    --Extract months from posted date and write the month in text format.
    to_char(j.job_posted_date, 'Month') as posted_month
from job_postings_fact j
inner join company_dim c on j.company_id = c.company_id
inner join country_avg_salary cas on j.job_country = cas.job_country
where j.salary_year_avg is not null
order by posted_month;

--Calculate two matrices for each company: one for unique skills required forthe job and another for the highest annual salary among job postings that require at least one skill. the final query should return company name, count of unique skills and highest salary.companies with no skill related job posting should count 0 and salary should be null.

--identify skills count for job postings per company
with company_skills as (
    select
        j.company_id,
        count(distinct sj.skill_id) as unique_skills
    from job_postings_fact j
    left join skills_job_dim sj on j.job_id = sj.job_id
    group by j.company_id
),
--identify highest salary for job postings with at least one skill
company_max_salary as (
    select
        j.company_id,
        max(j.salary_year_avg) as max_salary
    from job_postings_fact j
    inner join skills_job_dim sj on j.job_id = sj.job_id
    where j.salary_year_avg is not null
    group by j.company_id
)
--combine results to get final output
select
    c.name as company_name,
    coalesce(cs.unique_skills, 0) as unique_skills_count, -- if no skills, count as 0
    cms.max_salary
from company_dim c
left join company_skills cs on c.company_id = cs.company_id
left join company_max_salary cms on c.company_id = cms.company_id
order by unique_skills_count desc, max_salary desc; 

-- job posting tables for the first quartr on the year creating each table for each month.
select * from job_postings_fact
limit 2;
CREATE TABLE Job_postings_January AS(
SELECT
    job_id,
    job_title,
    c.name as Company_name,
    job_country,
    to_char(job_posted_date, 'month') as posted_month,
    job_posted_date,
    salary_year_avg
FROM job_postings_fact j
INNER JOIN company_dim c ON j.company_id = c.company_id
WHERE EXTRACT(MONTH FROM job_posted_date) = 1
AND job_title ILIKE '%data analyst%'
AND job_country != 'United States'
ORDER BY job_posted_date;
)
CREATE TABLE Job_postings_February AS
SELECT
    job_id,
    job_title,
    c.name as Company_name,
    job_country,
    to_char(job_posted_date, 'month') as posted_month,
    job_posted_date,
    salary_year_avg
FROM job_postings_fact j
INNER JOIN company_dim c ON j.company_id = c.company_id
WHERE EXTRACT(MONTH FROM job_posted_date) = 2
AND job_title ILIKE '%data analyst%'
AND job_country != 'United States'
ORDER BY job_posted_date;   

CREATE TABLE Job_postings_March AS
SELECT
    job_id,
    job_title,
    c.name as Company_name,                 
    job_country,
    to_char(job_posted_date, 'month') as posted_month,
    job_posted_date,
    salary_year_avg
FROM job_postings_fact j
INNER JOIN company_dim c ON j.company_id = c.company_id
WHERE EXTRACT(MONTH FROM job_posted_date) = 3
AND job_title ILIKE '%data analyst%'
AND job_country != 'United States'
ORDER BY job_posted_date;   


--UNION Operation to combine the three tables

Select
    job_country,
    job_title,
    company_name,
    job_posted_date::Date,
    salary_year_avg
FROM(
        select * from Job_postings_January
        union all
        select * from Job_postings_February
        union all
        select * from Job_postings_March
) as combined_jobs
WHERE salary_year_avg > 70000
order by 
    job_country;


select* from Job_postings_fact
limit 5;

--create two table and concatinate using union all where a new column will be created that specifies additional salary_information or not
(
Select
    job_id,
    job_title,
    'Has Salary Info' as salary_info
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL or salary_hour_avg IS NOT NULL
)
UNION ALL
(
Select
    job_id,
    job_title,
    'No Salary Info' as salary_info
FROM job_postings_fact
WHERE salary_year_avg IS NULL and salary_hour_avg IS NULL
)
order by salary_info DESC, job_id;  

select * from skills_dim  limit 2;
select * from skills_job_dim limit 2;


--Analyze the monthly demand for skills by counting the number of job postings for each skill in the first quarter (January to March), 
--utilizing data from separate tables for each month. Ensure to include skills from all job postings across these months.

with Q1_jobs_posting as (
    select * from Job_postings_January
    union all
    select * from Job_postings_February
    union all
    select * from Job_postings_March
)
demanded_skills as(
    select
        Q._id,

)