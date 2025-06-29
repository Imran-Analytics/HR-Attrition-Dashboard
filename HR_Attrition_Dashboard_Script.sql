
--PGSQL+Power BI Dashboard:
--============================================
--SECTION 1: Join employees,department,attrition_log,salaries
--============================================

select * from employees
select * from departments
select * from attrition_log
select * from salaries

select e.emp_id,e.name,e.gender,e.hire_date,d.department_name,s.salary,s.effective_date as salary_effective_date,case when exit_date is null then 'Active'
	else 'Left' 
	end as status,a.exit_date,a.attrition_reason,

extract(year from hire_date) as hire_year,
to_char(hire_date,'month') as hire_month,
to_char(hire_date,'day') as hire_date,

	coalesce(extract(year from exit_date),0) as exit_year,
	coalesce(to_char(exit_date, 'month'),'NA') as exit_month,
	coalesce(to_char(exit_date, 'day'),'0') as exit_month 

from employees e
left join attrition_log a on e.emp_id=a.emp_id
left join departments d on e.department_id = d.department_id
left join salaries s on  e.emp_id=s.emp_id
order by e.emp_id

--============================================
--SECTION 2: Adding the two new Columns (First and Last name) to Split the Full name in the source table, and then refreshed the materialized view
--============================================

select * from employees

select split_part(name,' ',1 ) as First_name,
substring(name from position (' ' in name)) as Last_name
from employees

alter table employees
	add column First_name text,
	add column Last_name text;

update employees
set First_name =(select split_part(name,' ',1 )),
Last_name =(select substring(name from position (' ' in name)))

--============================================
--SECTION 3: Remove duplicates from Table using CTID PGSQL:
--============================================ 

with cte as(
	select ctid,emp_id, 
	row_number() over(partition by emp_id) rnk
	from employee)

delete from employee
	where ctid in (select ctid from cte where rnk>1)

--Power BI DAX:

--============================================
--SECTION 4: DAX Queries
--============================================ 

1. Active Emps = CALCULATE(COUNTROWS(HR_Data),HR_Data[status] = "Active" )
2. Attrition % = CALCULATE(COUNTROWS(HR_Data),FILTER(HR_Data,HR_Data[status]="Left"))/COUNT(HR_Data[emp_id])
3. Exit Emps = CALCULATE(COUNTROWS(HR_Data),HR_Data[status]="Left" )
4. Tenure = DATEDIFF(HR_Data[hire_date],TODAY(),YEAR)