import { csvNumber,csvText,MAX_CSV_BYTES,reportCsv } from './report-csv';
import { MAX_EXPORT_PRODUCTS,ReportSnapshot } from './reports.service';
import { parseCsv } from '../../../test/fixtures/report-csv';
export function csvSnapshot():ReportSnapshot{
  const range={from:'2026-01-01',to:'2026-01-01',serverTime:'2026-11-19T01:00:00Z',businessDate:'2026-11-19'};
  return {summary:{...range,totalSalesPaise:'9007199254740993',totalOrders:1,deliveredOrders:1,cancelledOrders:0,milkSoldLitres:'0.000001',milkSoldUnmeasuredLines:1,
    totalEarningsPaise:'-9007199254740993',pendingPaymentsPaise:'0',activeCustomers:1,productSalesPaise:'9007199254740993',deliveryChargesPaise:'0',discountPaise:'0',unitemizedSalesPaise:'0'},
    daily:{...range,bucket:'DAY',items:[{from:range.from,to:range.to,salesPaise:'9007199254740993'}]},
    products:{...range,total:1,totalProductSalesPaise:'9007199254740993',items:[{productId:'11111111-1111-4111-8111-111111111111',name:'Synthetic, "milk"\r\nline',unitValue:'0.001',unitType:'ML',quantityPacks:'9007199254740993',salesPaise:'9007199254740993'}]}};
}
describe('T-101 CSV exactness and text boundary',()=>{
  it('neutralizes operators, control/BOM/full-width prefixes and escapes delimiters/quotes/newlines as one cell',()=>{
    for(const s of ['=1+1','+cmd','-2+3','@SUM(A1)',' \t=bad','\r\n=bad','\ufeff=bad','＝bad','＋bad','－bad','＠bad']){
      expect(parseCsv(csvText(s)+'\r\n')).toEqual([['\t'+s]]);
    }
    const value='Synthetic, "quoted"\r\nproduct; =inside';expect(parseCsv(csvText(value)+'\r\n')).toEqual([[value]]);
    expect(parseCsv(csvText('x\u0000y')+'\r\n')).toEqual([['x\ufffdy']]);
  });
  it('keeps only validated numeric literals exact, including legitimate negative net receipts',()=>{
    for(const n of ['0','9007199254740993','-9007199254740993','0.000001'])expect(parseCsv(csvNumber(n)+'\r\n')).toEqual([[n]]);
    for(const n of ['=1','-1+2','1e20',' 2','NaN','Infinity','1,2','01'])expect(()=>csvNumber(n)).toThrow();
  });
  it('writes UTF-8 BOM, a uniform eleven-column table and exact summary/day/product data',()=>{
    const csv=reportCsv(csvSnapshot()),rows=parseCsv(csv.toString('utf8'));expect(csv.subarray(0,3)).toEqual(Buffer.from([239,187,191]));
    expect(rows.every(r=>r.length===11)).toBe(true);
    expect(rows.find(r=>r[1]==='totalEarningsPaise')![9]).toBe('-9007199254740993');
    expect(rows.find(r=>r[0]==='PRODUCT_SALES')).toMatchObject({5:'Synthetic, "milk"\r\nline',8:'9007199254740993',9:'9007199254740993'});
  });
  it('rejects partial/over-cap tables and oversized artifacts without truncating',()=>{
    const s=csvSnapshot();s.products.total=MAX_EXPORT_PRODUCTS+1;expect(()=>reportCsv(s)).toThrow(expect.objectContaining({status:413}));
    s.products.total=2;expect(()=>reportCsv(s)).toThrow(expect.objectContaining({status:413}));
    s.products.total=1;s.products.items[0]!.name='x'.repeat(MAX_CSV_BYTES);expect(()=>reportCsv(s)).toThrow(expect.objectContaining({status:413}));
  });
});
