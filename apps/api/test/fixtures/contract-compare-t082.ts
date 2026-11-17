// T-082: compare existing contract semantics independently of YAML key ordering.
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import yaml from 'js-yaml';
type Document={paths:Record<string,unknown>;components:{schemas:Record<string,unknown>}};
const old=yaml.load(execFileSync('git',['show','HEAD:contracts/openapi.yaml'],{encoding:'utf8'})) as Document;
const current=yaml.load(readFileSync('../../contracts/openapi.yaml','utf8')) as Document;
function stable(value:unknown):unknown {
  if(Array.isArray(value))return value.map(stable);
  if(value&&typeof value==='object'){const row=value as Record<string,unknown>;return Object.fromEntries(Object.keys(row).sort().map(k=>[k,stable(row[k])]));}
  return value;
}
function changed(before:Record<string,unknown>,after:Record<string,unknown>){return Object.keys(before).filter(k=>JSON.stringify(stable(before[k]))!==JSON.stringify(stable(after[k])));}
const paths=changed(old.paths,current.paths),schemas=changed(old.components.schemas,current.components.schemas);
process.stdout.write(JSON.stringify({addedPaths:Object.keys(current.paths).filter(k=>!old.paths[k]).length,addedSchemas:Object.keys(current.components.schemas).filter(k=>!old.components.schemas[k]).length,changedExistingPaths:paths,changedExistingSchemas:schemas})+'\n');
if(paths.length||schemas.length)process.exitCode=1;
