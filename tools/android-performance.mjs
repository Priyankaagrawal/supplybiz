// T-170: explicit Android dev target only; no production data/provider calls.
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { createServer } from 'node:http';
import { stat, writeFile, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
const execute = promisify(execFile);
let stage='preflight';
const progress=value=>{stage=value;console.log(`T170 ${value}`);};
export function percentile(samples, p) {
  if (!samples.length || samples.some(n => !Number.isFinite(n) || n < 0) || p <= 0 || p > 1) throw new Error('Invalid samples');
  return [...samples].sort((a,b)=>a-b)[Math.ceil(p*samples.length)-1];
}
export function launchTime(text, {forceStopped=false}={}) {
  const state=/^LaunchState: (\w+)$/m.exec(text)?.[1];
  if (!/^Status: ok$/m.test(text) || (state ? state!=='COLD' : !forceStopped)) throw new Error('Expected successful cold launch');
  const value = /^TotalTime: (\d+)$/m.exec(text);
  if (!value) throw new Error('Missing launch time');
  return Number(value[1]);
}
export function memoryPss(text) {
  const match = /TOTAL PSS:\s*(\d+)/.exec(text) ?? /^\s*TOTAL\s+(\d+)\s/m.exec(text);
  if (!match) throw new Error('Missing process PSS');
  return Number(match[1]);
}
export function signInReady(xml) {
  const nodes=xml.match(/<node\b[^>]*>/g)||[];
  return nodes.some(node=>/(?:text|content-desc)="Sign in"/.test(node)) &&
    nodes.some(node=>/class="android.widget.EditText"/.test(node)&&/enabled="true"/.test(node));
}
export function screenAwake(power) {
  return /^\s*mWakefulness=Awake\s*$/m.test(power);
}
export function startupPhases(log) {
  const names=['binding','diagnosticsScheduled','dateFormats','storage','firebase','runApp','firstFrame'];
  const rows=(log.match(/\{"event":"STARTUP_PHASE"[^\r\n]*?\}/g)||[]).map(JSON.parse);
  let previous=0;
  if(rows.length!==names.length)throw new Error('Missing startup phase measurements');
  return rows.map((row,index)=>{
    if(row.phase!==names[index] || !Number.isSafeInteger(row.elapsedUs) || !Number.isSafeInteger(row.phaseUs) ||
      row.elapsedUs<previous || row.phaseUs!==row.elapsedUs-previous)throw new Error('Invalid startup phase measurements');
    previous=row.elapsedUs;
    return {phase:row.phase,elapsedUs:row.elapsedUs,phaseUs:row.phaseUs};
  });
}
export async function measure() {
  const serial = process.env.ANDROID_SERIAL;
  if (!serial || !/^[a-zA-Z0-9_.:-]+$/.test(serial)) throw new Error('Explicit ANDROID_SERIAL required');
  const adb = async (...args) => (await execute(process.env.ADB_PATH || 'adb', ['-s',serial,...args], {timeout:120000,maxBuffer:4*1024*1024,windowsHide:true})).stdout.trim();
  const apk = resolve('apps/mobile/build/app/outputs/flutter-apk/app-dev-profile.apk');
  await stat(apk);
  if (await adb('shell','getprop','sys.boot_completed') !== '1') throw new Error('Android target not booted');
  if (!screenAwake(await adb('shell','dumpsys','power'))) throw new Error('Android display asleep; unlock phone before measuring');
  if ((await adb('reverse','--list')).includes('tcp:18770')) throw new Error('Probe reverse port already in use');
  let configCalls=0;
  const server = createServer((req,res)=>{
    const config = req.url === '/api/v1/config';
    if(config)configCalls++;
    res.writeHead(config?200:401,{'content-type':'application/json'});
    res.end(JSON.stringify(config?{minVersionAndroid:'0.1.0',flags:{}}:{code:'UNAUTHENTICATED'}));
  });
  await new Promise((r,j)=>{server.once('error',j);server.listen(18770,'127.0.0.1',r);});
  const pkg='in.supplybiz.mobile.dev', times=[], readyUpperBounds=[], phases=[];
  try {
    progress('install-profile');
    await adb('reverse','tcp:18770','tcp:18770');
    await adb('install','-r',apk);
    for(let i=0;i<10;i++) {
      progress(`cold-run-${i+1}`);
      if (!screenAwake(await adb('shell','dumpsys','power'))) throw new Error('Android display asleep; unlock phone before measuring');
      await adb('shell','am','force-stop',pkg);
      const alive=await adb('shell','pidof',pkg).then(Boolean,error=>{if(error.code===1)return false;throw error;});
      if(alive)throw new Error('Process survived force-stop; not a cold run');
      const start=performance.now();
      const launch=await adb('shell','am','start','-W','-n',`${pkg}/in.supplybiz.supplybiz_mobile.MainActivity`);
      times.push(launchTime(launch,{forceStopped:true}));
      progress(`observe-sign-in-${i+1}`);
      let ready=false;
      for(let attempt=0;attempt<8;attempt++) {
        await adb('shell','uiautomator','dump','/sdcard/t170-window.xml');
        const xml=await adb('exec-out','cat','/sdcard/t170-window.xml');
        // Only retain a boolean, never the accessibility tree or field contents.
        ready=signInReady(xml);
        if(ready)break;
        if(attempt===7) {
          const labels=JSON.parse(await readFile('apps/mobile/lib/l10n/app_en.arb','utf8'));
          const knownLabelKeys=Object.entries(labels).filter(([key,value])=>!key.startsWith('@')&&typeof value==='string'&&(xml.includes(`text="${value}"`)||xml.includes(`content-desc="${value}"`))).map(([key])=>key);
          console.log(JSON.stringify({probe:'sign-in-shape',appWindow:xml.includes(`package="${pkg}"`),nodes:(xml.match(/<node\b/g)||[]).length,knownLabelKeys}));
        }
      }
      if(!ready)throw new Error('Enabled sign-in input not observed; no interactive-time success');
      readyUpperBounds.push(Math.round(performance.now()-start));
      if(process.env.STARTUP_TIMING_PROBE==='1') {
        const pid=await adb('shell','pidof',pkg);
        if(!/^\d+$/.test(pid))throw new Error('Startup process unavailable');
        phases.push(startupPhases(await adb('logcat','-d',`--pid=${pid}`,'-s','flutter:I')));
      }
    }
    if(configCalls===0)throw new Error('Synthetic config was never reached');
    const report={task:'T-170',generatedAt:new Date().toISOString(),mode:'profile',scenario:'signed-out synthetic config',
      referenceAcceptance:'NOT_RUN',startupMetric:'Android TotalTime to initial display; not time to interactive',
      coldInitialDisplayMs:times,p90InitialDisplayMs:percentile(times,.9),
      signInObservedUpperBoundMs:readyUpperBounds,p90SignInObservedUpperBoundMs:percentile(readyUpperBounds,.9),
      observationCaveat:'Accessibility polling adds overhead; no exact input-ready timestamp',
      ...(phases.length?{dartStartupPhases:phases}:{}),
      idlePssKiB:memoryPss(await adb('shell','dumpsys','meminfo',pkg)),
      android:await adb('shell','getprop','ro.build.version.release'),
      abi:await adb('shell','getprop','ro.product.cpu.abi'),
      emulator:(await adb('shell','getprop','ro.kernel.qemu'))==='1'};
    await writeFile('apps/mobile/build/t170-startup.json',JSON.stringify(report,null,2)+'\n');
    console.log(JSON.stringify(report));
  } finally {
    await adb('shell','am','force-stop',pkg).catch(()=>{});
    await adb('shell','rm','-f','/sdcard/t170-window.xml').catch(()=>{});
    await adb('reverse','--remove','tcp:18770').catch(()=>{});
    await new Promise(r=>server.close(r));
  }
}
if(process.argv[1] && import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
  measure().catch(error=>{
    const safe=new Set(['Expected successful cold launch','Missing launch time','Missing process PSS','Enabled sign-in input not observed; no interactive-time success','Synthetic config was never reached','Android target not booted','Android display asleep; unlock phone before measuring','Probe reverse port already in use','Missing startup phase measurements','Invalid startup phase measurements','Startup process unavailable']);
    console.error(`Android performance measurement failed at ${stage}${safe.has(error?.message)?`: ${error.message}`:''}; no acceptance PASS recorded.`);process.exitCode=1;
  });
}
