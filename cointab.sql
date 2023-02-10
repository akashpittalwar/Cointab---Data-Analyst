create database COINTAB;
use COINTAB;

-- output1
with cte as(select distinct(SKU),`Weight (g)` from `company x - sku master`), -- to remove duplicates
cte1 as 
(select 
a.ExternOrderNo,
a.SKU, 
a.`Order Qty`,
 b.`Weight (g)`,
 (a.`Order Qty`*b.`Weight (g)`) as prod,
c.`AWB Code`,
c.`Type of Shipment`,
c.Zone as Zc,
c.`Charged Weight`,
c.`Billing Amount (Rs.)`,
d.`Customer Pincode`,
d.Zone as Zx
from `company x - order report` a inner join cte b
on a.SKU=b.SKU
join `courier company - invoice` c
on a.ExternOrderNo=c.`Order ID`
join `company x - pincode zones` d
on c.`Customer Pincode`=d.`Customer Pincode`),
cte2 as (select ExternOrderNo,`AWB Code`,sum(prod)/1000 as total_by_x_kg,  
case when
ceil(sum(prod)/1000)-sum(prod)/1000>0.5 then ceil(sum(prod)/1000)-0.5 
else ceil(sum(prod)/1000) end as slab_by_x_kg,
`Charged Weight` as total_by_courier_kg,
case when
ceil(`Charged Weight`)-`Charged Weight`>0.5 then ceil(`Charged Weight`)-0.5 
else ceil(`Charged Weight`) end as slab_by_courier_kg,
`Type of Shipment`,
Zx,Zc,`Customer Pincode`,`Billing Amount (Rs.)`
from cte1
group by ExternOrderNo,`Type of Shipment`,Zc,Zx,`Customer Pincode`,
`AWB Code`,`Charged Weight`,`Billing Amount (Rs.)`),
cte3 as
(select *,
(slab_by_x_kg/0.5), 
case 

when `Type of Shipment`='Forward charges' and Zx = 'a'
then round(fwd_a_fixed + (((slab_by_x_kg/0.5)-1)*fwd_a_additional),2) 
when `Type of Shipment`='Forward and RTO charges' and Zx = 'a'
then round(fwd_a_fixed + (((slab_by_x_kg/0.5)-1)*fwd_a_additional)+((slab_by_x_kg/0.5)*rto_a_fixed),2)

when `Type of Shipment`='Forward charges' and Zx = 'b'
then round(fwd_b_fixed + (((slab_by_x_kg/0.5)-1)*fwd_b_additional),2) 
when `Type of Shipment`='Forward and RTO charges' and Zx = 'b'
then round(fwd_b_fixed + (((slab_by_x_kg/0.5)-1)*fwd_b_additional)+((slab_by_x_kg/0.5)*rto_b_fixed),2)

when `Type of Shipment`='Forward charges' and Zx = 'c'
then round(fwd_c_fixed + (((slab_by_x_kg/0.5)-1)*fwd_c_additional),2) 
when `Type of Shipment`='Forward and RTO charges' and Zx = 'c'
then round(fwd_c_fixed + (((slab_by_x_kg/0.5)-1)*fwd_c_additional)+((slab_by_x_kg/0.5)*rto_c_fixed),2)

when `Type of Shipment`='Forward charges' and Zx = 'd'
then round(fwd_d_fixed + (((slab_by_x_kg/0.5)-1)*fwd_d_additional),2) 
when `Type of Shipment`='Forward and RTO charges' and Zx = 'd'
then round(fwd_d_fixed + (((slab_by_x_kg/0.5)-1)*fwd_d_additional)+((slab_by_x_kg/0.5)*rto_d_fixed),2)

when `Type of Shipment`='Forward charges' and Zx = 'e'
then round(fwd_e_fixed + (((slab_by_x_kg/0.5)-1)*fwd_e_additional),2) 
when `Type of Shipment`='Forward and RTO charges' and Zx = 'e'
then round(fwd_e_fixed + (((slab_by_x_kg/0.5)-1)*fwd_e_additional)+((slab_by_x_kg/0.5)*rto_e_fixed),2)

end as priceX,`Billing Amount (Rs.)` as priceC
from cte2,`courier company - rates`)

select 
ExternOrderNo as 'Order ID',
`AWB Code` as 'AWB Number',
total_by_x_kg as 'Total weight as per X (KG)',
slab_by_x_kg as 'Weight slab as per X (KG)',
total_by_courier_kg as 'Total weight as per Courier Company (KG)',
slab_by_courier_kg as 'Weight slab charged by Courier Company (KG)',
Zx as 'Delivery Zone as per X',
Zc as 'Delivery Zone charged by Courier Company',
priceX as 'Expected Charge as per X (Rs.)',
priceC as 'Charges Billed by Courier Company (Rs.)',
round(priceX-priceC,2) as 'Difference Between Expected Charges and Billed Charges (Rs.)
' from cte3;

-- saved above CTE as CSV file 


-- output2
-- select * from op1;


select count(`Difference Between Expected Charges and Billed Charges (Rs.)`)  as 'Total orders where X has been correctly charged', 
sum(`Expected Charge as per X (Rs.)`) as 'Amount (Rs.)'
from op1 where `Difference Between Expected Charges and Billed Charges (Rs.)`=0;

select count(`Difference Between Expected Charges and Billed Charges (Rs.)`)  as 'Total Orders where X has been overcharged', 
round(abs(sum(`Difference Between Expected Charges and Billed Charges (Rs.)`))) as '<total overcharging amount>'
from op1 where `Difference Between Expected Charges and Billed Charges (Rs.)`<0;

select count(`Difference Between Expected Charges and Billed Charges (Rs.)`)  as 'Total Orders where X has been undercharged', 
round(abs(sum(`Difference Between Expected Charges and Billed Charges (Rs.)`))) as '<total undercharging amount>'
from op1 where `Difference Between Expected Charges and Billed Charges (Rs.)`>0;