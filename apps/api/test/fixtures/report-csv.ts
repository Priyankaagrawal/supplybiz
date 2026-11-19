// Independent minimal CSV parser for quoted/unquoted fields, CRLF and embedded lines.
export function parseCsv(input:string):string[][]{
  const text=input.replace(/^\ufeff/,''),rows:string[][]=[];let row:string[]=[],field='',quoted=false;
  for(let i=0;i<text.length;i++){
    const c=text[i]!;
    if(quoted){if(c==='"'){if(text[i+1]==='"'){field+='"';i++;}else quoted=false;}else field+=c;}
    else if(c==='"')quoted=true;
    else if(c===','){row.push(field);field='';}
    else if(c==='\r'&&text[i+1]==='\n'){row.push(field);rows.push(row);row=[];field='';i++;}
    else field+=c;
  }
  if(quoted)throw new Error('Unclosed CSV quote');
  if(field||row.length){row.push(field);rows.push(row);}return rows;
}
