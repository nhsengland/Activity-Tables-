----Step 1 --- Delete old tables

Drop table [NHSI_Sandbox].[Everyone].[tbl_Elective_WeeklyActuals_Plan_DB]
Drop table [NHSI_Sandbox].[Everyone].[tbl_Elective_Dashboard_Activity_Weekly]




---Step 2 ---- Create staging table -----



select a.DataType,
a.OrgType
,a.orgcode
,a.orgname
,a.stpcode
,a.stpname
,a.ReportingPeriod
,a.MetricID
,case when (a.MetricID like '%outpatient%' and a.datatype = 'Plan') then 0 else sum(a.MetricValue) end as metricvalue
,b.[Fin_Week_No_2_Char]
	  ,b.Fin_Year
	  ,c.[Adj] 
	       
  into  [NHSI_Sandbox].[Everyone].[tbl_Elective_WeeklyActuals_Plan_DB]
	  from [NHSI_Sandbox].[Everyone].[vw_Elective_WeeklyActuals_Plan_DB] as a

left join (SELECT distinct
cast([Week_End] as date) as 'WeekEnd'
      ,[Fin_Week_No_2_Char]
	  ,fin_year

   --  select * from [NHSI_Sandbox].[Everyone].[tbl_Elective_WeeklyActuals_Plan_DB]

      
  FROM [NHSE_Reference].[dbo].[tbl_Ref_Other_Dates_Full]

  where (fin_year in ('201920','202021','202122','202223') and Fin_Week_No_2_Char <> '53') or fin_year in('202324','202425')) as b on a.reportingperiod = b.WeekEnd
    
  left join [NHSI_Sandbox].[dbo].[Everyone.Baseline_Adjustment_Factor] as c on b.Fin_Week_No_2_Char = c.[Fin_Week_No_2_Char] and b.Fin_Year=c.Fin_Year
  
   group by

    a.DataType,
a.OrgType
,a.orgcode
,a.orgname
,a.stpcode
,a.stpname
,a.ReportingPeriod
,a.MetricID
,b.[Fin_Week_No_2_Char]
	  ,b.Fin_Year
	  ,c.[Adj] 

 
 -- Step 3 ---- Create new table ----


with cte_optotal as (

select DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,case when MetricID  in  ('Outpatient attendances (consultant led) - First telephone or Video consultation',
'Outpatient attendances (consultant led) - First attendance face to face')
 then 'Outpatient attendances (consultant led) - First attendance' 
 when metricid  in ('Outpatient attendances (consultant led) - Follow-up attendance face to face','Outpatient attendances (consultant led) - Follow-up telephone or Video consultation') 
 then 'Outpatient attendances (consultant led) - Follow Up attendance' else null end as 'MetricID'
,sum(MetricValue) as 'MetricValue'
,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj] from [NHSI_Sandbox].[Everyone].[tbl_Elective_WeeklyActuals_Plan_DB]

 where MetricID in ('Outpatient attendances (consultant led) - First telephone or Video consultation','Outpatient attendances (consultant led) - First attendance face to face',
 'Outpatient attendances (consultant led) - Follow-up attendance face to face','Outpatient attendances (consultant led) - Follow-up telephone or Video consultation')

 group by DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID
,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj])




,cte_activity as (
select DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID

,sum(MetricValue) as 'MetricValue'
,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj] from [NHSI_Sandbox].[Everyone].[tbl_Elective_WeeklyActuals_Plan_DB] where datatype <> 'Plan' 
	  group by DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID
,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj]
	  
	  union 
	  
	  
	  select DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID

,sum(MetricValue) as 'MetricValue'
,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj]
	  
	  from cte_optotal where datatype <> 'Plan'

	  group by DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID
,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj]
)



  ,cte_1920_baseline as (
  select a.* from cte_activity as a 
  
  where a.fin_year = '201920')


   ,cte_2324_baseline as (
  select a.* from cte_activity as a 
  
  where a.fin_year = '202324')


  ,CTE_FINAL AS (
  select distinct a.*,
  case when a.datatype = 'Plan' then 0 when a.Fin_Week_No_2_Char = '53' and a.fin_year = '202324' then e.metricvalue
when a.fin_year = '202425' then (c.metricvalue*a.[Adj]) 
when a.fin_year <> '202425' then (b.metricvalue *a.[Adj]) 
 end as 'Number_of_patients_baseline'  
  from cte_activity as a

  left join cte_1920_baseline as b on a.Fin_Week_No_2_Char = b.Fin_Week_No_2_Char and a.metricid = b.metricid  and a.OrgCode=b.OrgCode 
  
 left join cte_2324_baseline as c on a.Fin_Week_No_2_Char = c.Fin_Week_No_2_Char and a.metricid = c.metricid  and a.OrgCode=c.OrgCode 
 
 left join (select 
DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,MetricID
,ReportingPeriod
	  ,'53' as [Fin_Week_No_2_Char] 
	  ,Fin_Year
	  ,[Adj]
,metricvalue

from cte_1920_baseline where Fin_Week_No_2_Char = '52' and fin_year = '201920'

)  as e  on a.Fin_Week_No_2_Char = e.Fin_Week_No_2_Char and a.metricid = e.metricid  and a.OrgCode=e.OrgCode 
 
 
 
 
 
 
 
 
 where a.reportingperiod > '2019-03-31'
  and a.MetricID not like '%Regular_Attendance%'


  union



  select
  
  DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID
,metricvalue
	  , [Fin_Week_No_2_Char] 
	  ,Fin_Year
	  ,[Adj]

  , NULL as 'Number_of_patients_baseline' from [NHSI_Sandbox].[Everyone].[tbl_Elective_WeeklyActuals_Plan_DB] where datatype = 'Plan'
  )

  SELECT *
  INTO [NHSI_Sandbox].[Everyone].[tbl_Elective_Dashboard_Activity_Weekly]

  FROM CTE_FINAL
GO


