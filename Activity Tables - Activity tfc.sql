USE [NHSI_Sandbox]
GO

/****** Object:  View [Everyone].[vw_Elective_Dashboard_Activity_Weekly_TFC_Level]    Script Date: 22/04/2024 15:57:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Step 1 --Remove existing table---

drop table [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab]
drop table [NHSI_Sandbox].[Everyone].[tbl_Elective_Dashboard_Activity_Weekly_tfc]





--Step 2 -- Create staging table---

select a.datatype, a.orgtype, a.orgcode, a.orgname, a.stpcode, a.stpname, a.ReportingPeriod, a.MetricID,case when a.tfc is null then '999' else a.tfc end as 'tfc', a.tfcname, a.metricvalue

,b.[Fin_Week_No_2_Char]
	  ,b.Fin_Year
	  ,c.[Adj] 
	  into  [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab]

	  
	from [NHSI_Sandbox].[Everyone].[vw_Elective_WeeklyActuals_DB_TFC_Level_ab] as a

left join (SELECT distinct
cast([Week_End] as date) as 'WeekEnd'
      ,[Fin_Week_No_2_Char]
	  ,fin_year
  
      
  FROM [NHSE_Reference].[dbo].[tbl_Ref_Other_Dates_Full]

  where (fin_year in ('201920','202021','202122','202223') and Fin_Week_No_2_Char <> '53') or fin_year in('202324','202425')) as b on a.reportingperiod = b.WeekEnd
  
 left join [NHSI_Sandbox].[dbo].[Everyone.Baseline_Adjustment_Factor] as c on b.Fin_Week_No_2_Char = c.[Fin_Week_No_2_Char] and b.Fin_Year=c.Fin_Year




 ----STEP 3 --Populate new table-----





   with cte_alltfcs as (
  select distinct  tfc ,Fin_Week_No_2_Char,MetricID,orgcode,stpname,stpcode,orgtype,'SUS' as datatype,orgname,'201920' as fin_year from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab]
  union
  
  select distinct tfc,Fin_Week_No_2_Char,MetricID,orgcode,stpname,stpcode,orgtype,'SUS' as datatype,orgname,'202021' as fin_year from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab]

  union
  select distinct tfc,Fin_Week_No_2_Char,MetricID,orgcode,stpname,stpcode,orgtype,'SUS' as datatype,orgname,'202122' as fin_year from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab]

  union
  select distinct tfc,Fin_Week_No_2_Char,MetricID,orgcode,stpname,stpcode,orgtype,'SUS' as datatype,orgname,'202223' as fin_year from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab]

 union
  select distinct tfc,Fin_Week_No_2_Char,MetricID,orgcode,stpname,stpcode,orgtype,'SUS' as datatype,orgname,'202324' as fin_year from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab]
  
   union
  select distinct tfc,Fin_Week_No_2_Char,MetricID,orgcode,stpname,stpcode,orgtype,'SUS' as datatype,orgname,'202425' as fin_year from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab])
  
 ,cte_initial as (
  select distinct a.tfc,a.fin_year,a.Fin_Week_No_2_Char,a.MetricID,a.orgcode,a.orgname,a.stpcode,a.stpname,a.DataType,a.orgtype,d.weekend as 'reportingperiod'
   , c.Adj from cte_alltfcs as a 
    left join [NHSI_Sandbox].[dbo].[Everyone.Baseline_Adjustment_Factor] as c on a.Fin_Week_No_2_Char = c.[Fin_Week_No_2_Char] and a.Fin_Year=c.Fin_Year

  left join (SELECT distinct
cast([Week_End] as date) as 'WeekEnd'
      ,[Fin_Week_No_2_Char]
	  ,fin_year

    
      
  FROM [NHSE_Reference].[dbo].[tbl_Ref_Other_Dates_Full] )as d on a.[Fin_Week_No_2_Char] = d.[Fin_Week_No_2_Char] and a.fin_year = d.fin_year 

  )


  ----OPTOTAL

  ,cte_optotal as (

select 'SUS' AS 'DataType',
a.OrgType
,a.orgcode
,a.orgname
,a.stpcode
,a.stpname
,a.ReportingPeriod
,case when a.MetricID  in  ('Outpatient attendances (consultant led) - First telephone or Video consultation',
'Outpatient attendances (consultant led) - First attendance face to face')
 then 'Outpatient attendances (consultant led) - First attendance' when a.metricid  in ('Outpatient attendances (consultant led) - Follow-up attendance face to face','Outpatient attendances (consultant led) - Follow-up telephone or Video consultation') then 'Outpatient attendances (consultant led) - Follow Up attendance' else null end as 'MetricID'
,a.tfc
,'' as 'tfcname'
,sum(a.MetricValue) as 'MetricValue'
,b.[Fin_Week_No_2_Char]
	  ,b.Fin_Year
	  ,c.[Adj] 
	  
	  from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab] as a

left join (SELECT distinct
cast([Week_End] as date) as 'WeekEnd'
      ,[Fin_Week_No_2_Char]
	  ,fin_year

      
  
      
  FROM [NHSE_Reference].[dbo].[tbl_Ref_Other_Dates_Full]

  where (fin_year in ('201920','202021','202122','202223') and Fin_Week_No_2_Char <> '53') or fin_year in('202324','202425')) as b on a.reportingperiod = b.WeekEnd
   left join [NHSI_Sandbox].[dbo].[Everyone.Baseline_Adjustment_Factor] as c on b.Fin_Week_No_2_Char = c.[Fin_Week_No_2_Char] and b.Fin_Year=c.Fin_Year


 where a.MetricID in ('Outpatient attendances (consultant led) - First telephone or Video consultation','Outpatient attendances (consultant led) - First attendance face to face','Outpatient attendances (consultant led) - Follow-up attendance face to face','Outpatient attendances (consultant led) - Follow-up telephone or Video consultation')

 group by a.DataType,
a.OrgType
,a.orgcode
,a.orgname
,a.stpcode
,a.stpname
,a.ReportingPeriod
,a.metricid
,a.tfc

,b.[Fin_Week_No_2_Char]
	  ,b.Fin_Year
	  ,c.[Adj])


  
  
  
  
  
 ,cte_activity as (
select 'SUS' AS 'DataType',
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID
,a.tfc 
,'' as tfcname
,sum(metricvalue) as 'metricvalue',
[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj] 
	  
	  from [Everyone].[tbl_Elective_WeeklyActuals_DB_TFC_Level_ab] as a
	
	where MetricID not like '%Regular_Attendance%'
	
	  and DataType <> 'Plan'
	
	group by OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID
,a.tfc 
	,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj] 
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
,tfc
,'' as 'tfcname'
,sum(metricvalue) as 'metricvalue',
[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj]
	  
	  from cte_optotal
	  where MetricID not like '%Regular_Attendance%'
	  and DataType <> 'Plan'
	  
	  group by
DataType,
OrgType
,orgcode
,orgname
,stpcode
,stpname
,ReportingPeriod
,MetricID
,tfc
,[Fin_Week_No_2_Char]
	  ,Fin_Year
	  ,[Adj]
	  )
	   
 
  
  
  ,cte_1920_baseline as (
  select a.* from cte_activity as a 
  
  where a.fin_year = '201920'
)

  
 ,cte_2324_baseline as (
  select a.* from cte_activity as a 
  
  where a.fin_year = '202324'


)

 
 select 
 t.metricid
,t.tfc
 ,t.Fin_Week_No_2_Char
 ,t.[OrgCode]
 ,t.Fin_Year

  ,'SUS' as 'DataType' 
	,'Provider' as 'OrgType'
	   ,t.[OrgName]
	    ,t.stpcode 
		 ,t.stpname
	

      , t.[reportingperiod] 
     ,t.[Adj] 
	 ,SUBSTRING(f.TFCNAME, 6,len(f.TFCNAME))AS TFCNAME
	 ,d.metricvalue
	
	   
 ,case when t.Fin_Week_No_2_Char = '53' and t.fin_year = '202324' then g.metricvalue
 when t.fin_year <> '202425' then b.metricvalue
when t.fin_year = '202425' then e.metricvalue
end as 'Number_of_patients_baseline' 

,case when t.Fin_Week_No_2_Char = '53' and t.fin_year = '202324' then g.metricvalue
 when t.fin_year <> '202425' then b.metricvalue*t.[Adj]
when t.fin_year = '202425' then e.metricvalue*t.[Adj]
end as 'Number_of_patients_baseline_adj' 

into  [NHSI_Sandbox].[Everyone].[tbl_Elective_Dashboard_Activity_Weekly_tfc]
 
 from cte_initial as t 
 
 left join cte_activity as d  on d.Fin_Week_No_2_Char = t.Fin_Week_No_2_Char and d.metricid = t.metricid  and d.OrgCode=t.OrgCode and d.tfc = t.tfc and d.Fin_Year = t.fin_year 
 left join cte_1920_baseline as b on t.Fin_Week_No_2_Char = b.Fin_Week_No_2_Char and t.metricid = b.metricid  and t.OrgCode=b.OrgCode and t.tfc = b.tfc 
 left join cte_2324_baseline as e on t.Fin_Week_No_2_Char = e.Fin_Week_No_2_Char and t.metricid = e.metricid  and t.OrgCode=e.OrgCode and t.tfc = e.tfc 
 left join (SELECT DISTINCT [Treatment_Function_Code],[Treatment_Function_Desc_Short] as 'TFCNAME' FROM [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_TreatmentFunction] )as f on t.tfc = f.[Treatment_Function_Code]
 


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
	  ,tfc
	  ,Fin_Year
	  ,[Adj]
,metricvalue

from cte_1920_baseline where Fin_Week_No_2_Char = '52' and fin_year = '201920'

)  as g  on t.Fin_Week_No_2_Char = g.Fin_Week_No_2_Char and t.metricid = g.metricid  and t.OrgCode=g.OrgCode and t.tfc = g.tfc



	

GO


