/*
This project includes the Data Exploration and a bit of manipulation of this Covid-19 dataset downloaded from a Website called "Our World In Data" 
Let's get started
*/

-- Selecting the Database where we have stored both the datasets "CovidDeaths" and CovidVaccination" in "PortFolio" database
use portfolio;

-- Selecting the Datasets
SELECT 
    *
FROM
    CovidDeath
WHERE
    continent IS NOT NULL
ORDER BY 3 , 4;


SELECT 
    *
FROM
    CovidVaccination
WHERE
    Continent IS NOT NULL
ORDER BY 3 , 4; 

-- Now, I would like to change the datatype of the "Date" Column for the Tables as while importing MySQL Has taken it as "text" datatype.

Set SQL_SAFE_UPDATEs = 0;-- Changing the safe update state
UPDATE CovidDeath 
SET 
    date = STR_TO_DATE(date, '%d-%m-%Y');
UPDATE CovidVaccination 
SET 
    date = STR_TO_DATE(date, '%Y-%m-%d');
Set SQL_SAFE_UPDATEs = 1; -- Reseting the safe update state

-- Giving a check on the Description of the Datasets
describe CovidDeath;
describe CovidVaccination;

-- Updating all the Zeros('0') to the Null values for the betterment of the coming queries

SELECT 
    COUNT(*) AS Null_Count
FROM
    CovidDeaths
HAVING NULL;
SELECT 
    COUNT(*) AS Null_Count
FROM
    CovidVaccination
HAVING NULL;


-- Selecting the Data that I would be using furthur
SELECT 
    Location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    Population
FROM
    CovidDeaths
ORDER BY 1 , 2;

-- Let's see the Total Cases Vs Total Deaths
-- Can see the Current Likelihood of the dying if you are Covid-19 posiitve in a particular country
SELECT 
    Location,
    date,
    total_cases,
    total_deaths,
    ROUND((total_deaths / total_cases) * 100, 2) AS DeathPercentage
FROM
    CovidDeaths
WHERE
    Location = 'China'
ORDER BY 1 , 2;


-- Let's see the Total Cases Vs Population
-- Can see the current likelihood of the infection if you are Covid-19 posiitve in a particular country
SELECT 
    Location,
    date,
    total_cases,
    Population,
    ROUND((total_cases / Population) * 100, 2) AS TotalCasesPercentage
FROM
    CovidDeaths
WHERE
    Location = 'Bangladesh'
ORDER BY 1 , 2;


-- Let's see the Countries with highest infection Rate as compared to population
SELECT 
    Location,
    MAX(total_cases) AS HighestInfectionCount,
    Population,
    MAX(ROUND((total_cases / Population) * 100, 2)) AS PopulationInfectedPercentage
FROM
    CovidDeaths
GROUP BY Location , population
ORDER BY 4 DESC;


-- Let's see the Countries highest death count per population
SELECT 
    Location,
    MAX(total_deaths) AS HighestDeathCount,
    Population,
    MAX(ROUND((total_deaths / Population) * 100, 2)) AS PercentageDeathsPerPopulation
FROM
    CovidDeath
WHERE
    continent IS NOT NULL
GROUP BY Location , population
ORDER BY 2 DESC;

-- Setting the "Autocommit to '0' or turning off"
Set session Autocommit = 0;
Start transaction;

-- Creating of the Current Data
CREATE TABLE CovidDeath_Backup AS SELECT * FROM
    CovidDeath;

Start transaction;
UPDATE coviddeath_backup            -- First trying to update the blank values in 'Conitnent" attribute to Null in backup dataset and then in main dataset
SET 
    continent = NULL
WHERE
    continent = ' ';
    
UPDATE coviddeath 
SET 
    continent = NULL
WHERE
    continent = ' ';

-- Let's see the result of Death Rate by continents
SELECT DISTINCT
    (Continent),
    MAX(total_deaths) AS HighestDeathCount,
    Population,
    MAX(ROUND((total_deaths / Population) * 100, 2)) AS PercentageDeathsPerPopulation
FROM
    CovidDeath
WHERE
    continent IS NOT NULL
GROUP BY Continent , population
ORDER BY 2 DESC;


-- Let's see Global Number wrt to DeathPercentage
SELECT 
    date,
    total_cases,
    new_deaths,
    ROUND((new_deaths / new_cases) * 100, 2) AS DeathPercentage
FROM
    coviddeath
WHERE
    continent IS NOT NULL
GROUP BY date , total_cases , new_deaths , new_cases
ORDER BY total_cases;


-- Let's see some insights using the CovidVaccination dataset
-- Let's see the total number of people vaccinated 
SELECT 
    cd.Continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    sum(cv.new_vaccinations) over (partition by cd.Location order by cd.location,cd.date) as cummlaitivePeopleVaccinated
    
FROM
    Coviddeath cd
        JOIN
    covidvaccination cv ON cd.location = cv.location
        AND cd.date = cv.date
order by 2,3;


-- Making a temporary Table 
With PopVSVac (Continent, Location, Date, Population, New_Vaccination, cummlaitivePeopleVaccinated)
as
(SELECT 
    cd.Continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    sum(cv.new_vaccinations) over (partition by cd.Location order by cd.location,cd.date) as cummlaitivePeopleVaccinated
    
FROM
    Coviddeath cd
        JOIN
    covidvaccination cv ON cd.location = cv.location
        AND cd.date = cv.date
)
Select *,(cummlaitivePeopleVaccinated/Population)* 100 as PopVSVacPercentage
from PopVSVac;


-- Converting the above temp Table into Real One
CREATE TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population NUMERIC,
    New_Vaccinated NUMERIC,
    cummlaitivePeopleVaccinated NUMERIC
);

Insert into PercentPopulationVaccinated
SELECT 
    cd.Continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    sum(cv.new_vaccinations) over (partition by cd.Location order by cd.location,cd.date) as cummlaitivePeopleVaccinated
    
FROM
    Coviddeath cd
        JOIN
    covidvaccination cv ON cd.location = cv.location
        AND cd.date = cv.date;
        
SELECT 
    *,
    (cummlaitivePeopleVaccinated / Population) * 100 AS PopVSVacPercentage
FROM
    PercentPopulationVaccinated;


-- Queries Used for extracting data for analyzing in Tableau

Use Portfolio;
-- 1. 
SELECT 
    SUM(new_cases) AS Total_cases,
    SUM(new_deaths) AS Total_deaths,
    ROUND((SUM(new_deaths) / SUM(new_cases)) * 100,
            4) AS DeathPercentage
FROM
    CovidDeath
ORDER BY 1 , 2;


-- 2.
SELECT 
    Continent, SUM(new_deaths) AS TotalDeathCount
FROM
    CovidDeath
WHERE
    Continent IS NOT NULL
GROUP BY Continent
ORDER BY totalDeathCount DESC;

-- 3.
SELECT 
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    ROUND(MAX((total_cases / population)) * 100, 2) AS PercentPopulationInfected
FROM
    CovidDeath
GROUP BY Location , Population
ORDER BY PercentPopulationInfected DESC;

-- 4. 
SELECT 
    Location,
    Population,
    date,
    MAX(total_cases) AS HighestInfectionCount,
    ROUND(MAX((total_cases / population)) * 100, 4) AS PercentPopulationInfected
FROM
    CovidDeath
GROUP BY Location , Population , date
ORDER BY PercentPopulationInfected DESC;

