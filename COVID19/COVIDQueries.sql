-- 0. All Data
SELECT * FROM PortfolioProject..CovidDeaths order by 3, 4

-- 1. Data we will be working with 
Select Location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject..CovidDeaths 
where continent is not null
order by 1,2

-- 2. UK: Total cases vs total deaths = death rate
Select Location, date, total_cases, total_deaths, ((CAST(total_deaths AS DECIMAL)/total_cases)*100) as DeathRate
from PortfolioProject..CovidDeaths 
where location = 'United Kingdom'
order by 1,2

-- 3. UK: Total cases vs population = infection rate
Select Location, date, total_cases, population, ((CAST(total_cases AS DECIMAL)/population)*100) as InfectionRate
from PortfolioProject..CovidDeaths 
where location = 'United Kingdom'
order by 1,2

-- 4: By country: MAX Total cases vs population --> Countries with highest infection rate
Select location, population, MAX(total_cases) as HighestInfectionCount, Max((CAST(total_cases AS DECIMAL)/population)*100) as InfectionRate
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by InfectionRate DESC

-- 5: By country: MAX Total Deaths --> Countries with highest death toll
Select location, MAX(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- 6: By continent: MAX Total Deaths --> Total deaths for each continent
Select continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null 
group by continent
order by TotalDeathCount desc

-- 7: Global: Total cases / total deaths each day
Select date, 
	SUM(new_cases) as GlobalCases, 
	SUM(new_deaths) as GlobalDeaths, 
	CASE
		WHEN SUM(new_cases) = 0 THEN 0
		ELSE SUM(new_deaths)/SUM(CAST(new_cases as float))*100
	END as GlobalDeathRate
from PortfolioProject..CovidDeaths
where continent is not null 
group by date
order by 1,2

--8: Total population vs. vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVac
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL and dea.location like '%kingdom%'
order by 2, 3;

-- 9: Use CTE to perform calculationon partition by from previous query
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVac) as (
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVac
	FROM PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not NULL
)
Select *, (CAST(RollingVac as float)/Population)*100 as VaccinationRate
From PopVsVac
Order by location, date

-- 10: Use Temp table to perform calculation by on partition by in previous query
DROP Table if exists #PercentagePopVaccinated
CREATE Table #PercentagePopVaccinated
(
	Contintent nvarchar(50),
	Location nvarchar(50),
	Date datetime2,
	Population bigint,
	New_Vaccinations bigint,
	RollingVac bigint
)
Insert into #PercentagePopVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVac
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (CAST(RollingVac as float)/Population)*100 as VaccinationRate
FROM #PercentagePopVaccinated;


-- 11: Create View to store data for future visualisations
CREATE OR ALTER VIEW PercentagePopVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVac
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;


SELECT * FROM PercentagePopVaccinated
