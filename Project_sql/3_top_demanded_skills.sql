/*
1- what are the top_paying jobs for my role?
2- what are the skills required for these these top paying jobs?
3- what are the most in demand skills to learn for my role?
4- what are the top skills based on salary for my role?
5- what are the most optimal skills to learn for my role?
    a. Optimal: High Demand AND High Paying
*/

SELECT
    skills,
    job_location as Location,
    COUNT(skills_job_dim.job_id) AS Demand_count
FROM job_postings_fact
INNER JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE
    job_title_short = 'Data Analyst' AND
    job_location = 'Anywhere'
GROUP BY job_location, skills
ORDER BY Demand_count DESC
LIMIT 5;

select * from skills_job_dim limit 5;