--получили данные для распределения по Recency
with processed_data as (
	select
		min(b.datetime::date) as date,
		b.bonus_earned,
		b.bonus_spent,
		b.summ,
		b.card,
		b.summ_with_disc,
		b.doc_id
	from bonuscheques b
	where b.card not like '%-%'
	group by b.bonus_earned, b.bonus_spent, b.summ , b.card, b.summ_with_disc, b.doc_id
),
max_date as (
	select max(pd.date) as max_date
	from processed_data pd
),
diffs as (
	select
		pd.card,
		max(pd.date) as last_purchase,
		md.max_date,
		md.max_date - max(pd.date) as diff
	from processed_data pd, max_date md
	where pd.date between to_date('2022-01-01', 'yyyy-dd-mm') and  md.max_date
	group by pd.card, md.max_date
)
select 
round(avg(diff),2) as average_diff,
PERCENTILE_CONT(0.25) within group(order by diff) as diff_percentile_25,
PERCENTILE_CONT(0.5) within group(order by diff) as median_diff,
PERCENTILE_CONT(0.75) within group(order by diff) as diff_percentile_75
from diffs


--данные для распределения по Frequency
with processed_data as (
	select
		min(b.datetime::date) as date,
		b.bonus_earned,
		b.bonus_spent,
		b.summ,
		b.card,
		b.summ_with_disc,
		b.doc_id
	from bonuscheques b
	where b.card not like '%-%'
	group by b.bonus_earned, b.bonus_spent, b.summ , b.card, b.summ_with_disc, b.doc_id
),
max_date as (
	select max(pd.date) as max_date
	from processed_data pd
),
cnt as(
	select pd.card, count(*) as cnt
	from processed_data  pd, max_date md
	where pd.date between to_date('2022-01-01', 'yyyy-dd-mm') and  md.max_date 
	group by pd.card
)
select 
round(avg(cnt),2) as average_cnt,
PERCENTILE_CONT(0.25) within group(order by cnt) as cnt_percentile_25,
PERCENTILE_CONT(0.5) within group(order by cnt) as median_cnt,
PERCENTILE_CONT(0.75) within group(order by cnt) as cnt_percentile_75
from cnt 

--данные для распределения по Monetary
with processed_data as (
	select
		min(b.datetime::date) as date,
		b.bonus_earned,
		b.bonus_spent,
		b.summ,
		b.card,
		b.summ_with_disc,
		b.doc_id
	from bonuscheques b 
	where b.card not like '%-%'
	group by b.bonus_earned, b.bonus_spent, b.summ , b.card, b.summ_with_disc, b.doc_id
),
max_date as (
	select max(pd.date) as max_date
	from processed_data pd
),
sums as(
	select pd.card, sum(pd.summ_with_disc) as total_sum
	from processed_data  pd, max_date md
	where pd.date between to_date('2022-01-01', 'yyyy-dd-mm') and  md.max_date 
	group by pd.card
)
select 
round(avg(total_sum),2) as average_total_sum,
PERCENTILE_CONT(0.25) within group(order by total_sum) as total_sum_percentile_25,
PERCENTILE_CONT(0.5) within group(order by total_sum) as median_total_sum,
PERCENTILE_CONT(0.75) within group(order by total_sum) as total_sum_percentile_75
from sums 

--запрос с обработанными исходными данными
with processed_data as (
	select
		min(b.datetime::date) as date,
		b.bonus_earned,
		b.bonus_spent,
		b.summ,
		b.card,
		b.summ_with_disc,
		b.doc_id
	from bonuscheques b 
	WHERE b.card NOT LIKE '%-%'
	group by b.bonus_earned, b.bonus_spent, b.summ , b.card, b.summ_with_disc, b.doc_id
),
max_date as (
	select max(pd.date) as max_date
	from processed_data pd
)
select
	pd.card,
	md.max_date - max(pd.date) as diff,
	count(*) as cnt,
	sum(pd.summ_with_disc) as total_sum
from processed_data pd, max_date md
where pd.date between to_date('2022-01-01', 'yyyy-dd-mm') and  md.max_date
group by pd.card, md.max_date


with processed_data as (
	select
		min(b.datetime::date) as date,
		b.bonus_earned,
		b.bonus_spent,
		b.summ,
		b.card,
		b.summ_with_disc,
		b.doc_id
	from bonuscheques b 
	group by b.bonus_earned, b.bonus_spent, b.summ , b.card, b.summ_with_disc, b.doc_id
),
max_date as (
	select max(pd.date) as max_date
	from processed_data pd
),
counted as (
	select
		pd.card,
		md.max_date - max(pd.date) as diff,
		count(*) as cnt,
		sum(pd.summ_with_disc) as total_sum
	from processed_data pd, max_date md
	where pd.date between to_date('2022-01-01', 'yyyy-dd-mm') and  md.max_date
	group by pd.card, md.max_date
),
counted_values as(
	select 
	round(avg(diff),2) as average_diff,
	PERCENTILE_CONT(0.25) within group(order by diff) as diff_percentile_25,
	PERCENTILE_CONT(0.5) within group(order by diff) as median_diff,
	PERCENTILE_CONT(0.75) within group(order by diff) as diff_percentile_75,
	round(avg(cnt),2) as average_cnt,
	PERCENTILE_CONT(0.25) within group(order by cnt) as cnt_percentile_25,
	PERCENTILE_CONT(0.5) within group(order by cnt) as median_cnt,
	PERCENTILE_CONT(0.75) within group(order by cnt) as cnt_percentile_75,
	round(avg(total_sum),2) as average_total_sum,
	PERCENTILE_CONT(0.25) within group(order by total_sum) as total_sum_percentile_25,
	PERCENTILE_CONT(0.5) within group(order by total_sum) as median_total_sum,
	PERCENTILE_CONT(0.75) within group(order by total_sum) as total_sum_percentile_75
	from counted
),
counted_groups as (
	select c.card,
	case 
		when diff <= diff_percentile_25 then 1
		when diff <= median_diff then 2
		else 3
	end recency,
	case
		when cnt = cnt_percentile_25 then 3
		when cnt = median_cnt then 2
		else 1
	end frequency,
	case 
		when total_sum <= total_sum_percentile_25 then 3
		when total_sum <= median_total_sum then 2
		else 1
	end monetary
	from counted c, counted_values cv
),
rfm_groups as (
	select CONCAT(recency, frequency, monetary) as rfm_group, count(*) as cnt
	from counted_groups
	group by CONCAT(recency, frequency, monetary)
),
grouped_rfm as 
(
	select rfm_group, cnt, round((cnt*1.0/(select sum(cnt) from rfm_groups)),3) as perc
	from rfm_groups
	group by rfm_group, cnt
	order by rfm_group
)
select
case when rfm_group in ('111') then 'Чемпионы' 
	 when rfm_group in ('112', '211') then 'Лояльные постоянные' 
	 when rfm_group in ('121', '212') then 'Средние(на грани)' 
	 when rfm_group in ('311', '312') then 'В зоне риска' 
	 when rfm_group in ('233', '323', '332', '333') then 'Спящие' 
	 when rfm_group in ('123', '132', '133') then 'Новички' 
	 when rfm_group in ('131', '213', '221', '231', '313', '321', '331') then 'Требующие внимания' 
	 when rfm_group in ('113', '122') then 'Растущие' 
	 when rfm_group in ('322', '232', '223', '222') then 'Сомневающиеся' 
end
as "Группа",
sum(cnt) as "Кол-во",
sum(perc) as "Доля"
from grouped_rfm
group by 
case when rfm_group in ('111') then 'Чемпионы' 
	 when rfm_group in ('112', '211') then 'Лояльные постоянные' 
	 when rfm_group in ('121', '212') then 'Средние(на грани)' 
	 when rfm_group in ('311', '312') then 'В зоне риска' 
	 when rfm_group in ('233', '323', '332', '333') then 'Спящие' 
	 when rfm_group in ('123', '132', '133') then 'Новички' 
	 when rfm_group in ('131', '213', '221', '231', '313', '321', '331') then 'Требующие внимания' 
	 when rfm_group in ('113', '122') then 'Растущие' 
	 when rfm_group in ('322', '232', '223', '222') then 'Сомневающиеся' 
end

with processed_data as (
	select
		min(b.datetime::date) as date,
		b.bonus_earned,
		b.bonus_spent,
		b.summ,
		b.card,
		b.summ_with_disc,
		b.doc_id
	from bonuscheques b 
	where b.card not like '%-%'
	group by b.bonus_earned, b.bonus_spent, b.summ , b.card, b.summ_with_disc, b.doc_id
),
max_date as (
	select max(pd.date) as max_date
	from processed_data pd
),
counted as (
	select
		pd.card,
		md.max_date - max(pd.date) as diff,
		count(distinct pd.doc_id) as cnt,
		sum(pd.summ_with_disc) as total_sum
	from processed_data pd, max_date md
	where pd.date between to_date('2022-01-01', 'yyyy-dd-mm') and  md.max_date
	group by pd.card, md.max_date
),
counted_values as(
	select 
	round(avg(diff),2) as average_diff,
	PERCENTILE_CONT(0.25) within group(order by diff) as diff_percentile_25,
	PERCENTILE_CONT(0.5) within group(order by diff) as median_diff,
	PERCENTILE_CONT(0.75) within group(order by diff) as diff_percentile_75,
	round(avg(cnt),2) as average_cnt,
	PERCENTILE_CONT(0.25) within group(order by cnt) as cnt_percentile_25,
	PERCENTILE_CONT(0.5) within group(order by cnt) as median_cnt,
	PERCENTILE_CONT(0.75) within group(order by cnt) as cnt_percentile_75,
	round(avg(total_sum),2) as average_total_sum,
	PERCENTILE_CONT(0.25) within group(order by total_sum) as total_sum_percentile_25,
	PERCENTILE_CONT(0.5) within group(order by total_sum) as median_total_sum,
	PERCENTILE_CONT(0.75) within group(order by total_sum) as total_sum_percentile_75
	from counted
),
counted_groups as (
	select c.card,
	case
		when cnt = cnt_percentile_25 then 3
		when cnt = median_cnt then 2
		else 1
	end frequency,
	case 
		when total_sum <= total_sum_percentile_25 then 3
		when total_sum <= median_total_sum then 2
		else 1
	end monetary,
	c.total_sum,
	c.cnt
	from counted c, counted_values cv
)
select monetary, round(count(card) * 1.0/(select count(*) as all_cnt from counted),2)
from counted_groups
where frequency > 1
group by monetary

rfm_groups as (
	select CONCAT(recency, frequency, monetary) as rfm_group, count(*) as cnt
	from counted_groups
	group by CONCAT(recency, frequency, monetary)
)
select rfm_group, cnt, round((cnt*1.0/(select sum(cnt) from rfm_groups)),3) as perc
from rfm_groups
group by rfm_group, cnt
order by rfm_group