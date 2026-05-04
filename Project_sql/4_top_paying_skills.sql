SELECT
    skills,
    Round(AVG(salary_year_avg), 0) AS avg_salary
FROM job_postings_fact
INNER JOIN skills_job_dim ON job_postings_fact.job_id = skills_job_dim.job_id
INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE
    job_title_short = 'Data Analyst' AND
    job_location = 'Anywhere' AND
    salary_year_avg IS NOT NULL
GROUP BY 
    skills
ORDER BY 
    avg_salary DESC
LIMIT 25;

/* 
Salaries range roughly from ~$120K to ~$210K
The top-paying skill is PySpark, followed by tools like Bitbucket and Couchbase
There’s a mix of data engineering, ML, and DevOps tools — not just “pure analyst” skills
Key Insights from Your Data
 1. Data Engineering Skills Dominate the Top

Top earners:

PySpark
Databricks
Airflow
Kafka-like ecosystem (implicit via tools)
    
Insight:
High-paying “data analyst” roles are actually leaning toward Data Engineering + Big Data roles
*/
