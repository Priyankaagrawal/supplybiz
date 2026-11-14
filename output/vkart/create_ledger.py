from pathlib import Path
from html import escape

ROOT = Path(__file__).parent
rows = []
balance = 0
totals = [0] * 6

def money(n):
    s = str(abs(n))
    tail = s[-3:]
    s = s[:-3]
    groups = []
    while s:
        groups.insert(0, s[-2:])
        s = s[:-2]
    return ('-' if n < 0 else '') + ','.join(groups + [tail]) + '.00'

def month(name):
    rows.append(f'<tr class="month"><td colspan="10">{name} <span>Opening balance</span></td><td class="num">₹ {money(balance)}</td></tr>')

def invoice(date, ref, detail, taxable, tax, tds):
    global balance
    gross = taxable + tax
    net = gross - tds
    balance += net
    for i, v in enumerate([taxable, tax, gross, tds, net, 0]):
        totals[i] += v
    cells = [date, ref, detail or '—'] + [money(v) for v in [taxable, tax, gross, tds, net]] + ['—', '—', money(balance)]
    rows.append('<tr>' + ''.join(f'<td class="{"num" if i in [3,4,5,6,7,9,10] else ""}">{escape(v)}</td>' for i,v in enumerate(cells)) + '</tr>')

def receipt(date, amount, detail='Payment received'):
    global balance
    balance -= amount
    totals[5] += amount
    cells = ['—', '—', detail, '—', '—', '—', '—', '—', date, money(amount), money(balance)]
    rows.append('<tr class="receipt">' + ''.join(f'<td class="{"num" if i in [3,4,5,6,7,9,10] else ""}">{escape(v)}</td>' for i,v in enumerate(cells)) + '</tr>')

month('August 2025')
invoice('05 Aug 2025', 'PR-G/24-25/19', 'Vebrand', 14400, 2592, 1440)
receipt('25 Aug 2025', 15552)
month('September 2025')
invoice('05 Sep 2025', 'PR-G/24-25/24', 'HR cross month leave', 4050, 729, 405)
invoice('19 Sep 2025', 'PR-G/24-25/26', 'HR leave allocation', 8200, 1476, 820)
month('October 2025')
receipt('04 Oct 2025', 13230, 'Payment received (HR)')
invoice('27 Oct 2025', 'PR-G/24-25/29', '', 16050, 2889, 1605)
month('November 2025')
receipt('04 Nov 2025', 17334, 'Payment received (HR)')
invoice('12 Nov 2025', 'PR-G/24-25/34', 'Vebrand run time', 6500, 1170, 650)
invoice('12 Nov 2025', 'PR-G/24-25/35', 'Checkbox filtering job status', 6500, 1170, 650)
receipt('12 Nov 2025', 14040)
month('March 2026')
invoice('04 Mar 2026', 'PR-G/24-25/44', 'Report Builder Development', 35000, 6300, 3500)
receipt('27 Mar 2026', 37800)
assert totals == [90700, 16326, 107026, 9070, 97956, 97956]
assert balance == 0
totalcells = ''.join(f'<td class="num">{money(v)}</td>' for v in totals[:5])
rows.append(f'<tr class="total"><td colspan="3">TOTAL</td>{totalcells}<td>—</td><td class="num">{money(totals[5])}</td><td class="num">{money(balance)}</td></tr>')

html = '''<!doctype html><html lang="en"><meta charset="utf-8"><title>Vkart Account Ledger</title>
<style>
@page {size: A4 landscape; margin: 10mm 10mm 9mm;}
* {box-sizing: border-box;} body {font-family: Arial, sans-serif; margin:0; color:#182a3d; font-size:9px; -webkit-print-color-adjust:exact; print-color-adjust:exact;}
.header {background:#153e64; color:#fff; padding:15px 19px; border-radius:5px; display:flex; align-items:center; justify-content:space-between;}
h1 {font-size:24px; margin:0 0 5px; letter-spacing:.2px;} .sub {font-size:10px; color:#e0edfa;} .label {font-size:9px; text-transform:uppercase; letter-spacing:1.3px; margin-bottom:6px; color:#dceafa;} .period {text-align:right; font-size:12px;}
.summary {display:flex; gap:10px; margin:12px 0;} .card {flex:1; border:1px solid #d5e0e9; padding:9px 12px; border-radius:4px; background:#f5f8fb;} .card span {display:block; color:#4a5e71; margin-bottom:4px; font-size:9px;} .card strong {font-size:17px; color:#153e64;} .card.closed {background:#edf7f2; border-color:#bcdccb;} .card.closed strong {color:#185638;}
table {width:100%; border-collapse:collapse; table-layout:fixed; font-size:8px; font-variant-numeric:tabular-nums;}
th {background:#153e64; color:white; text-align:left; font-size:8px; line-height:1.4; padding:7px 5px; border-right:1px solid #436480;}
td {padding:5.5px 5px; border-bottom:1px solid #dbe3ea; vertical-align:middle; line-height:1.25;} .num {text-align:right; white-space:nowrap;} td:nth-child(2) {font-size:7.6px;white-space:nowrap;} .month td {background:#e8eff6; color:#153e64; font-weight:bold; padding-top:5px;padding-bottom:5px;} .month span {font-weight:normal; margin-left:12px; color:#486078;} .receipt td {background:#f7fafc;} .total td {background:#153e64; color:white; font-weight:bold; border:none; padding-top:8px;padding-bottom:8px;}
.notes {margin-top:10px; font-size:8px; line-height:1.6; color:#405569;} .notes strong {color:#153e64;} .footer {display:flex; justify-content:space-between; border-top:1px solid #d5e0e9; margin-top:10px; padding-top:7px; font-size:8px; color:#53687b;} tr {break-inside:avoid;}
</style>
<div class="header"><div><div class="label">Statement of account</div><h1>Vkart Account Ledger</h1><div class="sub">Client: Vkart &nbsp; | &nbsp; Currency: Indian Rupee (₹)</div></div><div class="period"><div class="label">Statement period</div>01 Aug 2025 – 31 Mar 2026</div></div>
<div class="summary"><div class="card"><span>Opening balance</span><strong>₹ 0.00</strong></div><div class="card"><span>Net invoice amount (after TDS)</span><strong>₹ 97,956.00</strong></div><div class="card"><span>Total receipts</span><strong>₹ 97,956.00</strong></div><div class="card closed"><span>Closing balance · 31 Mar 2026</span><strong>₹ 0.00</strong></div></div>
<table><colgroup><col style="width:8%"><col style="width:11%"><col style="width:16%"><col style="width:8%"><col style="width:7%"><col style="width:8%"><col style="width:7%"><col style="width:9%"><col style="width:9%"><col style="width:8%"><col style="width:9%"></colgroup>
<thead><tr><th>Invoice date</th><th>Invoice no.</th><th>Particulars</th><th class="num">Taxable<br>amount (₹)</th><th class="num">Tax<br>18% (₹)</th><th class="num">Gross<br>total (₹)</th><th class="num">TDS<br>10% (₹)</th><th class="num">Net invoice<br>amount (₹)</th><th>Received<br>date</th><th class="num">Received<br>amount (₹)</th><th class="num">Running<br>balance (₹)</th></tr></thead><tbody>''' + '\n'.join(rows) + '''</tbody></table>
<div class="notes"><strong>Reconciliation notes:</strong> Running balances are recalculated chronologically from the supplied invoices and receipts. Invoice numbers and monetary entries are retained as supplied.<br>Tax and TDS column rates reflect the supplied amounts: tax = 18% of taxable amount; TDS = 10% of taxable amount. Net invoice amount = gross total − TDS. No transactions were supplied for December 2025–February 2026.</div>
<div class="footer"><span>Prepared from client-supplied records for account reconciliation and audit review.</span><span>Vkart &nbsp; | &nbsp; Page 1 of 1</span></div></html>'''
(ROOT / 'vkart_account_ledger.html').write_text(html, encoding='utf-8')
print('Verified: 7 invoices, 5 receipts; net invoices and receipts INR 97,956.00; closing INR 0.00.')
