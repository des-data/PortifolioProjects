SELECT * FROM DBO.covidDeaths

SELECT * FROM covidVaccinations

--This is the data we will be using
SELECT location, date, total_cases, new_cases,total_deaths, population
FROM covidDeaths
order by 1,2

--looking at total_deaths against total_cases
SELECT location, date,total_cases,total_deaths,(CAST(total_deaths AS FLOAT) / total_cases) * 100 AS DeathPercentage
FROM covidDeaths
WHERE location like '%states%' and continent is not null
ORDER BY location, date;


--Looking at total cases vs population
--it shows the population that has covid
SELECT location, date,population, total_cases,(CAST(total_cases AS FLOAT) / population) * 100 AS CasesPercentage
FROM covidDeaths
WHERE location like '%states%' and continent is not null
ORDER BY location, date;

--Looking at the country with the Highest Infected Population

SELECT location,population, Max(total_cases) as HighestInfectionCount,Max(CAST(total_cases AS FLOAT) / population) * 100 AS PercentPopulationInfected
FROM covidDeaths
where continent is not null
Group by population, location
ORDER BY PercentPopulationInfected desc

--showing the countries with the highest death count per population
Select location, population, max(cast(total_deaths as int)) as TotalDeathCount, Max(CAST(total_deaths AS FLOAT) / population) * 100 AS PercentPopulationDied
FROM covidDeaths
where continent is not null
group by location, population
order by TotalDeathCount desc

--showing contients with the highest death count
Select continent, max(cast(total_deaths as int)) as TotalDeathCount, Max(CAST(total_deaths AS FLOAT) / population) * 100 AS PercentPopulationDied
FROM covidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

--BREAK THINGS UP PER CONTINENT
SELECT continent,SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, (SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent -- You need to group by continent to avoid the grouping error
ORDER BY total_cases DESC;

--Joining Tables
SELECT * 
FROM covidDeaths dea
JOIN covidVaccinations vac
  ON
dea.location = vac.location AND dea.date = vac.date


SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location=vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL
order by 2,3

--Using CTEs
WITH popVsVac (continent, location,date,population,new_vaccinations,RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations AS float)) over (partition by dea.location order by dea.date)as RollingPeopleVaccinated
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location=vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL
----order by 2,3
)
SELECT *,(RollingPeopleVaccinated/population)*100 as percentVaccinated
FROM popVsVac

--USING TEMP TABLE
DROP table if exists #PercentVaccinatedPeople
Create table #PercentVaccinatedPeople(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentVaccinatedPeople
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations AS float)) over (partition by dea.location order by dea.date)as RollingPeopleVaccinated
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location=vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL
--order by 2,3

SELECT *,(RollingPeopleVaccinated/population)*100 as percentVaccinated
FROM #PercentVaccinatedPeople

--CREATING VIEWS
CREATE VIEW PercentVaccinatedPeople AS
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations AS float)) over (partition by dea.location order by dea.date)as RollingPeopleVaccinated
FROM covidDeaths dea
JOIN covidVaccinations vac
ON dea.location=vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL

Select * from PercentVaccinatedPeople
