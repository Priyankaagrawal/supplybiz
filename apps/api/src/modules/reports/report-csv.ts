// T-101: RFC 4180 rows. Untrusted text is distinct from validated numeric cells.
import { PayloadTooLargeException } from '@nestjs/common';
import { MAX_EXPORT_PRODUCTS,ReportSnapshot } from './reports.service';
export const MAX_CSV_BYTES=8*1024*1024;
const quote=(s:string)=>`"${s.replaceAll('"','""')}"`;
export function csvText(value:string){
  // Neutralize operators after whitespace/control/BOM and their full-width forms.
  // Leading control characters are text too; delimiters/newlines remain quoted.
  let offset=0;
  for(const c of value){
    const code=c.codePointAt(0)!;
    if(/\s/u.test(c)||code<=31||code===127)offset+=c.length;else break;
  }
  const first=value.charCodeAt(0),operator=new Set(['=','+','-','@','\uff1d','\uff0b','\uff0d','\uff20']);
  const unsafe=operator.has(value.charAt(offset))||first<=31||first===127||first===65279;
  return quote((unsafe?'\t':'')+value.replaceAll('\u0000','\ufffd'));
}
export function csvNumber(value:string){
  if(!/^-?(0|[1-9]\d*)(\.\d+)?$/.test(value))throw new Error('Invalid report numeric value');
  return quote(value);
}
export function reportCsv(snapshot:ReportSnapshot):Buffer{
  const {summary:s,daily,products}=snapshot;
  if(products.total>MAX_EXPORT_PRODUCTS||products.items.length!==products.total)throw new PayloadTooLargeException({code:'REPORT_EXPORT_TOO_LARGE'});
  const header=['section','metric','from','to','product_id','product_name','unit_value','unit_type','quantity_packs','value','unit'].map(csvText).join(',')+'\r\n';
  const parts=['\ufeff',header];let bytes=3+Buffer.byteLength(header,'utf8');
  const row=(section:string,metric:string,from:string,to:string,productId:string,name:string,unitValue:string,unitType:string,qty:string,value:string,unit:string,numeric=false)=>{
    const cells=[section,metric,from,to,productId,name,unitValue,unitType].map(csvText);
    cells.push(qty?csvNumber(qty):csvText(''),numeric?csvNumber(value):csvText(value),csvText(unit));
    const line=cells.join(',')+'\r\n';bytes+=Buffer.byteLength(line,'utf8');
    if(bytes>MAX_CSV_BYTES)throw new PayloadTooLargeException({code:'REPORT_EXPORT_TOO_LARGE'});
    parts.push(line);
  };
  row('METADATA','generated_at',s.from,s.to,'','','','','',s.serverTime,'UTC');
  row('METADATA','sales_date_basis',s.from,s.to,'','','','','','Actual completion/POS sale date','IST');
  row('METADATA','order_count_basis',s.from,s.to,'','','','','','Scheduled delivery date','IST');
  row('METADATA','current_state_as_of',s.from,s.to,'','','','','',s.serverTime,'Current receivable and active customers');
  row('METADATA','milk_volume_note',s.from,s.to,'','','','','','Known frozen volume only; unknown lines are reported separately','');
  const metrics:[string,string,string][]=[
    ['totalSalesPaise',s.totalSalesPaise,'paise'],['totalOrders',String(s.totalOrders),'orders'],['deliveredOrders',String(s.deliveredOrders),'orders'],
    ['cancelledOrders',String(s.cancelledOrders),'orders'],['milkSoldLitres',s.milkSoldLitres,'litres'],['milkSoldUnmeasuredLines',String(s.milkSoldUnmeasuredLines),'lines'],
    ['totalEarningsPaise',s.totalEarningsPaise,'net received paise'],['pendingPaymentsPaise',s.pendingPaymentsPaise,'current receivable paise'],
    ['activeCustomers',String(s.activeCustomers),'current customers'],['productSalesPaise',s.productSalesPaise,'paise'],['deliveryChargesPaise',s.deliveryChargesPaise,'paise'],
    ['discountPaise',s.discountPaise,'paise'],['unitemizedSalesPaise',s.unitemizedSalesPaise,'paise'],
  ];
  for(const [metric,value,unit] of metrics)row('SUMMARY',metric,s.from,s.to,'','','','','',value,unit,true);
  for(const bucket of daily.items)row(daily.bucket==='WEEK'?'SALES_WEEK':'SALES_DAY','totalSalesPaise',bucket.from,bucket.to,'','','','','',bucket.salesPaise,'paise',true);
  for(const p of products.items)row('PRODUCT_SALES','salesPaise',s.from,s.to,p.productId,p.name,p.unitValue,p.unitType,p.quantityPacks,p.salesPaise,'paise',true);
  return Buffer.from(parts.join(''),'utf8');
}
