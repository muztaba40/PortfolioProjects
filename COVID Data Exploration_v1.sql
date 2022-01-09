/*
COVID-19 Data Exploration

SQL kills: Joins, CTE (Common Table Expression),  Temp Tables, Windows Functions, Aggregate Functions (Max,Sum, etc.), 
			Creating Views, Converting Data Types (cast)
*/


SELECT *
FROM PortfolioProject.dbo.CovidDeaths$
Where continent is not null -- as we have continent and locatoin mixed together
order by 3, 4

-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
Where continent is not null
Order by 1,2

-- Looking at aTotal Cases vs Total Deaths
-- Shows likelihood of dying if one contract covid in his country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Where location like '%states%' and continent is not null
Order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
Select Location, date,population, total_cases, (total_cases/population)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Where continent is not null 
Order by 1,2


-- Looking at Countries with Highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as "Highest_infection Count", round(MAX((total_cases/population))*100, 4) as Percentage_Population_Infected
From PortfolioProject..CovidDeaths$
Where continent is not null 
Group by location, population
Order by Percentage_Population_Infected desc

-- Countries with Highest Death Count per Population
Select location, MAX(cast(total_deaths as int)) as "Total Death Count"
From PortfolioProject..CovidDeaths$
Where continent is not null -- as we have continent and locatoin mixed together
Group by location
Order by "Total Death Count" desc

-- Continents with the Highest death count per population
Select continent, MAX(cast(total_deaths as int)) as "Total Death Count"
From PortfolioProject..CovidDeaths$
Where continent is not null -- as we have continent and locatoin mixed together
Group by continent
Order by "Total Death Count" desc

-- Global Numbers
-- Death count per day
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	round(SUM(cast(new_deaths as int))/SUM(new_cases)*100,3) as "Death Percentage"
From PortfolioProject..CovidDeaths$
Where continent is not null
Group By date
Order by 1,2

-- Total Death count across world
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	round(SUM(cast(new_deaths as int))/SUM(new_cases)*100,3) as "Death Percentage"
From PortfolioProject..CovidDeaths$
Where continent is not null
Order by 1,2

-- Total Population vs Vaccination

-- Joining tables
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths$ as dth
Join PortfolioProject..CovidVaccinations$ as vac
 on dth.location = vac.location
 and dth.date = vac.date
Where dth.continent is not null
Order by 1,2,3

-- Total vaccinations for Bangladesh

Select dth.continent, dth.location, dth.date,  vac.new_vaccinations, round((vac.new_vaccinations/dth.population)*100, 3) as "vaccination percentage"
From PortfolioProject..CovidDeaths$ as dth
Join PortfolioProject..CovidVaccinations$ as vac
 on dth.location = vac.location
 and dth.date = vac.date
Where dth.continent is not null and dth.continent = 'Asia' and dth.location = 'Bangladesh' and vac.new_vaccinations is not null
Order by 1,2,3

-- Partition by locations
SET ANSI_WARNINGS ON
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location Order by dth.location, dth.date) as "Rolling People Vaccination"
From PortfolioProject..CovidDeaths$ as dth
Join PortfolioProject..CovidVaccinations$ as vac
 on dth.location = vac.location
 and dth.date = vac.date
Where dth.continent is not null
Order by 2,3

--USE CTE (common table extensions)

With Pop_vs_Vac as (
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location Order by dth.location, dth.date) as "Rolling People Vaccination"
From PortfolioProject..CovidDeaths$ as dth
Join PortfolioProject..CovidVaccinations$ as vac
 on dth.location = vac.location
 and dth.date = vac.date
Where dth.continent is not null
)

Select *, ([Rolling People Vaccination]/population)*100
From Pop_vs_Vac
Order by 2,3

-- TEMP TABLE

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Locatoin nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
Rolling_People_Vaccinated numeric)

Insert into #PercentPopulationVaccinated
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location Order by dth.location, dth.date) as "Rolling People Vaccination"
From PortfolioProject..CovidDeaths$ as dth
Join PortfolioProject..CovidVaccinations$ as vac
 on dth.location = vac.location
 and dth.date = vac.date
Where dth.continent is not null


Select *, ([Rolling_People_Vaccinated]/population)*100
From #PercentPopulationVaccinated


-- Changing something from Created table can be done by Droping table and reinitate the table like below:
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Locatoin nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
Rolling_People_Vaccinated numeric)

Insert into #PercentPopulationVaccinated
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location Order by dth.location, dth.date) as "Rolling People Vaccination"
From PortfolioProject..CovidDeaths$ as dth
Join PortfolioProject..CovidVaccinations$ as vac
 on dth.location = vac.location
 and dth.date = vac.date
-- Where dth.continent is not null


Select *, ([Rolling_People_Vaccinated]/population)*100
From #PercentPopulationVaccinated


-- Creating View to Store Data for later Visualizations

Create View PercentPopulationVaccinated as 
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location Order by dth.location, dth.date) as "Rolling People Vaccination"
From PortfolioProject..CovidDeaths$ as dth
Join PortfolioProject..CovidVaccinations$ as vac
 on dth.location = vac.location
 and dth.date = vac.date
Where dth.continent is not null

Select * 
From PercentPopulationVaccinated