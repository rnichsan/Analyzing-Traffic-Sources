use mavenfuzzyfactory;


-- Finding top traffic sources:
-- generate a sales report with a breakdown of where the bulk of our website sessions are coming from, 
-- categorized by UTM source, campaign, and referring domain.
    
select distinct utm_source from website_sessions;
select
	utm_source,
    utm_campaign,
    http_referer,
    count(distinct website_session_id) as sessions,
    count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_sessions,
    count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_sessions,
    count(distinct case when utm_source = 'socialbook' then website_session_id else null end) as socialbook_sessions
from website_sessions
where created_at < '2012-04-12'
group by
	utm_campaign,
    utm_source,
    http_referer
order by sessions desc;
	-- Recomendations
	-- Optimize 'gsearch' Campaigns
		-- Non-Brand Campaign:The 'gsearch' non-brand campaign is performing the best with 3613 sessions. 
		-- Continue to invest in and optimize this campaign to maintain and grow its performance.
	-- Referring Domains:
		-- Referring Domains: The majority of traffic is coming from 'gsearch.com' with 
		-- both brand and non-brand campaigns. Make sure to maintain good relationships 
		-- with referring domains and explore partnerships with other high-traffic websites 
		-- to diversify your traffic sources.


-- Traffic source conversion:
-- Please calculate the conversion rate (CVR) from session to order for gsearch and nonbrand. 
-- Based on our costs for clicks, we need a CVR of at least 4% to meet our targets. 
-- If the CVR is significantly lower, reduce bids. If the CVR is higher, increase bids to drive more volume.
select
    count(distinct ws.website_session_id) as sessions,
    count(distinct o.order_id) as orders,
    round(count(distinct o.order_id) / count(distinct ws.website_session_id)*100,2) as session_to_order_conv_rate
from website_sessions as ws
left join orders as o
	on ws.website_session_id = o.website_session_id
where ws.created_at < '2012-04-14'
	and utm_campaign = 'nonbrand'
    and utm_source = 'gsearch';
    -- Based on this analysis, we'll need to dial down search bids a bit.
    -- We're over spending based on the current conversion rate
    
    -- NEXT STEP:
		-- Monitor the impact of bid reductions
        -- Analysze performance trending by device type in order to revince bidding strategy
        
#PIVOTING IN SQL
	-- Traffic source trending:
	-- pull gsearch nonbrand trended session volume, by week,
    -- to see if the bid changes have caused volume to drop at all
select 
	min(date(ws.created_at)) as week_start,
    count(distinct ws.website_session_id) as sessions,
    count(case when created_at <= '2012-04-15'then ws.website_session_id else null end) as "before april fifteen",
    count(case when created_at > '2012-04-15' and created_at <= '2012-05-10' then ws.website_session_id else null end) as "after april fifteen"
from website_sessions as ws
where ws.created_at < '2012-05-10'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by
	year(ws.created_at),
    week(ws.created_at);
    
-- Bid optimization for paid:
-- Pull conversion rates from session to order, by the device type!
-- if desktop performance is better then on mobile we may be able to bid up
-- for desktop specifically to get more volume
select
	device_type,
    count(distinct ws.website_session_id) as sessions,
    count(distinct o.order_id) as orders,
    round(count(distinct o.order_id) / count(distinct ws.website_session_id)*100, 2) as session_to_order_conv_rate
from website_sessions as ws
left join orders as o
	on ws.website_session_id = o.website_session_id
where ws.created_at < '2012-05-11'
	and utm_campaign = 'nonbrand'
    and utm_source = 'gsearch'
group by
	device_type
order by session_to_order_conv_rate desc;
	-- Based on the analysis we're going to increase bids on desktop
    
-- After your device-level analysis of conversion rates, we realized desktop was doing well.
-- So we bid ousr gsearch nonbrand desktop campaigns up on 2012-05-19
	-- Could you pull weekly trends for both desktop and mobile so we can see the impact on volume?
    -- You can use 2012-04-15 until the bid change as baseline
select
	*,
    round((mobile_sessions - lag(mobile_sessions) over(order by start_week)) / lag(mobile_sessions) over(order by start_week)*100,2) as mobile_session_percentage_growth,
    round((desktop_sessions - lag(desktop_sessions) over(order by start_week)) / lag(desktop_sessions) over(order by start_week)*100, 2) as desktop_session_percentage_growth
from
(select
	min(date(ws.created_at)) as start_week,
    count(distinct ws.website_session_id) as sessions,
    count(distinct case when device_type = 'mobile' then ws.website_session_id else null end) as mobile_sessions,
    count(distinct case when device_type = 'desktop' then ws.website_session_id else null end) as desktop_sessions,
    round((count(distinct website_session_id) - lag(count(distinct ws.website_session_id)) over(order by min(date(ws.created_at))))
		/ lag(count(distinct ws.website_session_id)) over(order by min(date(ws.created_at)))*100,2) as session_percentage_growth
from website_sessions as ws
where ws.created_at between '2012-04-15' and '2012-06-09'
	and utm_campaign = 'nonbrand'
    and utm_source = 'gsearch'
group by
	year(ws.created_at),
    week(ws.created_at))subq
order by start_week asc;
	-- Success of Desktop Bidding Increase: The significant increase of 64.02% in desktop sessions in the week following the bid adjustment (May 20, 2012) indicates that the strategy 
    -- of increasing bids for desktop nonbrand campaigns on gsearch was effective. It suggests that users on desktop have a higher conversion rate and respond well to these campaigns.
    
    -- SUMMARY:
		-- The data indicates that the bid increase for desktop nonbrand campaigns on gsearch has been successful, 
        -- resulting in a significant rise in desktop sessions. However, there is a noticeable decline in mobile sessions, 
        -- which needs to be addressed. By focusing on maintaining and optimizing desktop campaigns, improving the mobile user experience, 
        -- balancing resource allocation, and implementing adaptive bidding strategies, the overall performance and user engagement can be enhanced. 
        -- Regular monitoring and analysis will be key to making informed adjustments and ensuring sustained growth across both desktop and mobile platforms.




