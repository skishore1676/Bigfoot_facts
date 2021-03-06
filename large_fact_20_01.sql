Select oiu.*,
fiu.*,
sv.entityid as shipment_id,
sv.`data`.vendor_tracking_id as vendor_tracking_id,
sv.`data`.status as shipment_current_status,
lookup_date(cast(sv.updatedat/1000 as TIMESTAMP)) as shipment_current_status_date_key,
lookup_time(cast(sv.updatedat/1000 as TIMESTAMP)) as shipment_current_status_time_key,
sv.`data`.payment_type as payment_type,
sv.shipment_priority_flag,
lookupkey('pincode',sv.`data`.destination_address.pincode) as geo_id_key,
sv.`data`.shipment_type as ekl_shipment_type,
lookup_date(sv.`data`.customer_sla) AS customer_promise_date_key,
lookup_time(sv.`data`.customer_sla) AS customer_promise_time_key,
lookup_date(sv.`data`.design_sla) AS logistics_promise_date_key,
lookup_time(sv.`data`.design_sla) AS logistics_promise_time_key,
lookup_date(sv.`data`.created_at) AS shipment_created_at_date_key,
lookup_time(sv.`data`.created_at) AS shipment_created_at_time_key,
lookupkey('vendor_id',sv.`data`.vendor_id) as vendor_id_key,
If(sv.`data`.vendor_id = '','VNF',If(sv.`data`.vendor_id = 200 OR sv.`data`.vendor_id =207, 'FSD','3PL')) as shipment_carrier,
lookupkey('facility_id',sv.`data`.assigned_address.id) as fsd_assigned_hub_id_key,
lookupkey('facility_id',sv.`data`.current_address.id) as fsd_last_current_hub_id_key,
sv.`data`.current_address.type as fsd_last_current_hub_type,
If(oiu.order_item_unit_status in ('returned','return_requested','cancelled','on_hold'),oiu.order_item_unit_status,
If(sv.`data`.shipment_type in ('approved_rto','unapproved_rto'),'RTO',
If(sv.`data`.created_at is null,'Dispatch_Pending',
If(If(sv.`data`.vendor_id = '','VNF',If(sv.`data`.vendor_id = 200 OR sv.`data`.vendor_id =207, 'FSD','3PL')) = '3PL','3PL_Pending',
If(sv.`data`.status =  'Out_For_Delivery','Out_For_Delivery',
If(sv.`data`.status = 'Expected' and sv.`data`.current_address.type in ('DELIVERY_HUB','BULK_HUB'),'Pending@DH',
'RCA')))))) as pending_status,
lookupkey('address_id',omso.`data`.order_shipping_address_id) as order_shipping_address_id_key,
omso.`data`.order_external_id as order_external_id,
cv.`data`.call_verification_reason as call_verification_reason,
cv.`data`.call_verification_status as call_verification_status,
I.entityid as runsheet_id,
I.closed_date as runsheet_closed_date,
I.created_at as runsheet_created_at,
I.ekl_facility_id as runsheet_ekl_facility_id,
I.vehicle_id as runsheet_vehicle_id,
I.agent_id as runsheet_agent_id
from 
(SELECT 
order_item_units.order_item_unit_quantity AS order_item_unit_quantity ,
`data`.order_item_quantity AS order_item_quantity ,
`data`.order_item_selling_price_in_paisa/100 AS order_item_selling_price ,
`data`.order_item_type AS order_item_type,
`data`.order_item_title AS order_item_title,
order_item_units.order_item_unit_status AS order_item_unit_status ,
IF (order_item_units.order_item_unit_new_promised_date IS NULL ,0,1) AS order_item_unit_is_promised_date_updated ,
`data`.order_item_sub_type AS order_item_sub_type,
`data`.order_id AS order_id,
`data`.order_item_id AS order_item_id,
order_item_units.order_item_unit_tracking_id AS order_item_unit_tracking_id,
`data`.order_item_sku AS order_item_sku,
`data`.order_item_category_id AS order_item_category_id,
`data`.order_item_sub_status AS order_item_sub_status,
`data`.order_item_ship_group_id AS order_item_ship_group_id,
`data`.order_item_status AS order_item_status,
order_item_units.order_item_unit_shipment_id AS order_item_unit_shipment_id,
order_item_units.order_item_unit_id AS order_item_unit_id,
lookupkey('product_id', `data`.order_item_fsn) AS order_item_product_id_key,
lookup_date(order_item_units.order_item_unit_promised_date) AS order_item_unit_init_promised_date_key,
lookup_date(`data`.order_item_date) AS order_item_date_key,
lookup_date(IF (order_item_units.order_item_unit_new_promised_date IS NULL ,order_item_units.order_item_unit_promised_date ,order_item_units.order_item_unit_new_promised_date)) AS order_item_unit_final_promised_date_key,
lookupkey('seller_id', order_item_units.order_item_unit_seller_id) AS order_item_seller_id_key,
lookup_time(`data`.order_item_date) AS order_item_time_key,
lookupkey('facility_id', order_item_units.order_item_unit_fc) AS order_item_unit_source_faciltiy_id_key,
lookupkey('listing_id', `data`.order_item_listing_id) AS order_item_listing_id_key,
`data`.order_item_date, 
`data`.order_item_created_at, 
IF (order_item_units.order_item_unit_new_promised_date IS NULL, order_item_units.order_item_unit_promised_date , order_item_units.order_item_unit_new_promised_date) AS order_item_unit_final_promised_date_use,
updatedat as order_item_last_update,
order_item_units.order_item_unit_new_promised_date as order_item_unit_new_promised_date
FROM   dart_fkint_scp_oms_order_item_0_11_view lateral VIEW explode(`data`.order_item_unit) exploded_table AS order_item_units) oiu
left outer join 
(SELECT 
`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_actual_time as fulfill_item_unit_dispatch_actual_time,
`data`.fulfill_item_unit_shipped_status.fulfill_item_unit_shipped_status_actual_time as fulfill_item_unit_ship_actual_time,
`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_expected_time as fulfill_item_unit_dispatch_expected_time,
`data`.fulfill_item_unit_shipped_status.fulfill_item_unit_shipped_status_expected_time as fulfill_item_unit_ship_expected_time,
`data`.fulfill_item_unit_order_item_mapping.order_item_mapping_external_id as fulfillment_order_item_id,
`data`.fulfill_item_unit_id as fulfill_item_unit_id,
`data`.fulfill_item_unit_status as fulfill_item_unit_status,
`data`.fulfill_item_unit_ekl_shipment_mapping.ekl_shipment_mapping_external_id as shipment_merchant_reference_id,
`data`.fulfill_item_unit_updated_at as fulfill_item_unit_updated_at,
`data`.fulfill_item_unit_region as fulfill_item_unit_region,
lookup_date(`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_actual_time) as fulfill_item_unit_dispatch_actual_date_key,
lookup_date(`data`.fulfill_item_unit_shipped_status.fulfill_item_unit_shipped_status_actual_time) as fulfill_item_unit_ship_actual_date_key,
lookup_date(`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_expected_time) as fulfill_item_unit_dispatch_expected_date_key,
lookup_date(`data`.fulfill_item_unit_fulfill_item.fulfill_item_order_date) as fulfill_item_unit_order_date_key ,
lookup_time(`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_actual_time) as fulfill_item_unit_dispatch_actual_time_key,
lookup_time(`data`.fulfill_item_unit_shipped_status.fulfill_item_unit_shipped_status_actual_time) as fulfill_item_unit_ship_actual_time_key,
lookup_time(`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_expected_time) as fulfill_item_unit_dispatch_expected_time_key,
lookup_time(`data`.fulfill_item_unit_fulfill_item.fulfill_item_order_date) as fulfill_item_unit_order_time_key,
`data`.fulfill_item_unit_region_type as fulfill_item_unit_region_type,
`data`.fulfill_item_unit_fulfill_item.fulfill_item_id as fulfill_item_id,
`data`.fulfill_item_unit_fulfill_item.fulfill_item_type as fulfill_item_type,
`data`.fulfill_item_unit_delivered_status.fulfill_item_unit_delivered_status_after_time as fulfill_item_unit_deliver_after_time,
`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_after_time as fulfill_item_unit_dispatch_after_time,
lookup_date(`data`.fulfill_item_unit_delivered_status.fulfill_item_unit_delivered_status_after_time) as fulfill_item_unit_deliver_after_date_key,
lookup_time(`data`.fulfill_item_unit_delivered_status.fulfill_item_unit_delivered_status_after_time) as fulfill_item_unit_deliver_after_time_key,
lookup_date(`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_after_time) as fulfill_item_unit_dispatch_after_date_key,
lookup_time(`data`.fulfill_item_unit_dispatched_status.fulfill_item_unit_dispatched_status_after_time) as fulfill_item_unit_dispatch_after_time_key,
case when `data`.fulfill_item_unit_delivered_status.fulfill_item_unit_delivered_status_after_time is null then 'NotSlotted' else 'Slotted' end  as fulfill_item_unit_is_for_slotted_delivery,
`data`.fulfill_item_unit_reserved_status.fulfill_item_unit_reserved_status_actual_time as fulfill_item_unit_reserved_status_actual_time,
`data`.fulfill_item_unit_reserved_status.fulfill_item_unit_reserved_status_expected_time as fulfill_item_unit_reserved_status_expected_time,
lookup_date(`data`.fulfill_item_unit_reserved_status.fulfill_item_unit_reserved_status_actual_time) as fulfill_item_unit_reserved_status_actual_date_key,
lookup_time(`data`.fulfill_item_unit_reserved_status.fulfill_item_unit_reserved_status_actual_time) as fulfill_item_unit_reserved_status_actual_time_key,
lookup_date(`data`.fulfill_item_unit_reserved_status.fulfill_item_unit_reserved_status_expected_time) as fulfill_item_unit_reserved_status_expected_date_key,
lookup_time(`data`.fulfill_item_unit_reserved_status.fulfill_item_unit_reserved_status_expected_time) as fulfill_item_unit_reserved_status_expected_time_key,
`data`.fulfill_item_unit_delivered_status.fulfill_item_unit_delivered_status_expected_time as fulfill_item_unit_delivered_status_expected_time,
lookup_date(`data`.fulfill_item_unit_delivered_status.fulfill_item_unit_delivered_status_expected_time) as fulfill_item_unit_delivered_status_expected_date_key,
lookup_time(`data`.fulfill_item_unit_delivered_status.fulfill_item_unit_delivered_status_expected_time) as fulfill_item_unit_delivered_status_expected_time_key
from dart_fkint_scp_fulfillment_fulfill_item_unit_1_8_view) fiu ON (fiu.fulfillment_order_item_id = oiu.order_item_id)
left outer join 
(select * from dart_wsr_scp_ekl_shipment_1_4_view s left outer join bigfoot_external_neo.scp_ekl__shipment_logistics_l1_90_fact sl
on  s.`data`.vendor_tracking_id=sl.shipment_id) sv 
on (sv.merchant_reference_id = fiu.shipment_merchant_reference_id)
left outer join 
dart_fkint_scp_oms_order_0_5_view omso on (omso.`data`.order_id = oiu.order_id)
left outer join 
dart_fkint_scp_oms_call_verification_0_5_view_total cv ON (cv.`data`.call_verification_order_id = oiu.order_id)
left outer join 
(select entityid,
max(if(`data`.order_item_status = 'approved',updatedat,null)) as order_item_max_approved_time,
max(if(`data`.order_item_status = 'on_hold',updatedat,null)) as order_item_max_on_hold_time
from dart_fkint_scp_oms_order_item_0_11
group by entityid) G ON (G.entityid = oiu.order_item_id)
left outer join
(select entityid,
min(If(`data`.status = 'InScan_Success', updatedat,null)) as shipment_inscan_time,
min(If(`data`.shipment_type like '%rto%',updatedat,null)) as shipment_rto_create_time,
max(If(`data`.status = 'Received',updatedat,null)) as fsd_last_received_time,
sum(if(`data`.status in ('Out_For_Delivery','out_for_delivery'),1,0)) as fsd_number_of_ofd_attempts,
min(If(`data`.current_address.id = `data`.assigned_address.id and `data`.status = 'Expected',updatedat, null)) as fsd_assignedhub_expected_time,
min(If(`data`.current_address.id = `data`.assigned_address.id and `data`.status = 'Received',updatedat, null)) as fsd_assignedhub_received_time,
min(If(`data`.status = 'Returned_To_Ekl',updatedat,null)) as fsd_returnedtoekl_time,
min(If(`data`.status = 'Received_By_Ekl',updatedat,null)) as fsd_receivedbyekl_time
from dart_wsr_scp_ekl_shipment_1_4
group by entityid) H on (H.entityid = sv.entityid)
left outer join 
(Select entityid,`data`.closed_date,`data`.created_at,`data`.ekl_facility_id,`data`.vehicle_id,`data`.agent_id, task_id
 from dart_wsr_scp_ekl_lastmiletasklist_1_3 lateral view explode(`data`.task_ids) exploded_table as task_id where `data`.document_type = 'runsheet') I 
on (split(I.task_id, "-")[1] = sv.`data`.vendor_tracking_id);