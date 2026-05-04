/*
1- what are the top_paying jobs for my role?
2- what are the skills required for these these top paying jobs?
3- what are the most in demand skills to learn for my role?
4- what are the top skills based on salary for my role?
5- what are the most optimal skills to learn for my role?
    a. Optimal: High Demand AND High Paying
*/

WITH skills_demand AS (
    SELECT
        s.skill_id,
        s.skills,
        COUNT(sj.job_id) AS Demand_count
    FROM job_postings_fact 
    INNER JOIN skills_job_dim sj ON job_postings_fact.job_id = sj.job_id
    INNER JOIN skills_dim s ON sj.skill_id = s.skill_id
WHERE
    job_title_short = 'Data Analyst' AND
    salary_year_avg IS NOT NULL AND
    job_work_from_home = TRUE
GROUP BY 
    s.skill_id
),
average_salary AS (
SELECT
    sj.skill_id,
    Round(AVG(job_postings_fact.salary_year_avg), 0) AS avg_salary
FROM job_postings_fact
INNER JOIN skills_job_dim sj ON job_postings_fact.job_id = sj.job_id
INNER JOIN skills_dim s ON sj.skill_id = s.skill_id
WHERE
    job_title_short = 'Data Analyst' AND
    job_work_from_home = TRUE AND
    salary_year_avg IS NOT NULL
GROUP BY 
    sj.skill_id
)
SELECT
    skills_demand.skill_id,
    skills_demand.skills,
    Demand_count,
    avg_salary 
FROM
    skills_demand
INNER JOIN average_salary ON skills_demand.skill_id = average_salary.skill_id
WHERE
    Demand_count > 10
ORDER BY
    avg_salary DESC,
    Demand_count DESC
LIMIT 25;

