import {test} from 'node:test';
import assert from 'node:assert/strict';
import {percentile,launchTime,memoryPss,signInReady,startupPhases,screenAwake} from './android-performance.mjs';
test('T-170 rejects sleeping, dozing and missing display state',()=>{
 assert.equal(screenAwake('  mWakefulness=Awake\r\n'),true);
 for(const state of ['Asleep','Dozing','Dreaming'])assert.equal(screenAwake(`  mWakefulness=${state}\n`),false);
 assert.equal(screenAwake('mWakefulnessChanging=true'),false);
 assert.equal(screenAwake(''),false);
});
test('T-170 p90 uses nearest rank over every cold run',()=>{
 assert.equal(percentile([10,9,8,7,6,5,4,3,2,1],.9),9);
 assert.equal(percentile([2],.9),2);
 assert.throws(()=>percentile([],.9));assert.throws(()=>percentile([NaN],.9));
});
test('cold startup parser rejects warm launches, failed and missing metrics',()=>{
 assert.equal(launchTime('Status: ok\nLaunchState: COLD\nTotalTime: 123'),123);
 assert.equal(launchTime('Status: ok\r\nLaunchState: COLD\r\nTotalTime: 123\r\n'),123);
 assert.throws(()=>launchTime('Status: ok\nLaunchState: WARM\nTotalTime: 12'));
 assert.throws(()=>launchTime('Status: error\nLaunchState: COLD\nTotalTime: 12'));
 assert.throws(()=>launchTime('Status: ok\nLaunchState: COLD'));
 assert.throws(()=>launchTime('Status: ok\nTotalTime: 123'));
 assert.equal(launchTime('Status: ok\nTotalTime: 123',{forceStopped:true}),123);
 assert.throws(()=>launchTime('Status: ok\nLaunchState: WARM\nTotalTime: 12',{forceStopped:true}));
});
test('PSS parser handles Android layouts and never treats missing data as zero',()=>{
 assert.equal(memoryPss(' TOTAL PSS: 12345 TOTAL RSS: 45678'),12345);
 assert.equal(memoryPss(' TOTAL 12345 22 33\n'),12345);
 assert.throws(()=>memoryPss('No process found'));
});
test('Flutter sign-in semantics support text and content descriptions, requiring an enabled input',()=>{
 const input='<node enabled="true" class="android.widget.EditText" />';
 assert.equal(signInReady('<node text="Sign in" />'+input),true);
 assert.equal(signInReady('<node content-desc="Sign in" />'+input),true);
 assert.equal(signInReady('<node content-desc="Sign in" /><node class="android.widget.EditText" enabled="false" />'),false);
 assert.equal(signInReady('<node content-desc="Loading" />'+input),false);
 assert.equal(signInReady('<node content-desc="Sign in" />'),false);
});
test('startup phases require a complete monotonic trace and discard all arbitrary fields',()=>{
 const names=['binding','diagnosticsScheduled','dateFormats','storage','firebase','runApp','firstFrame'];
 const rows=names.map((phase,i)=>({event:'STARTUP_PHASE',phase,elapsedUs:(i+1)*10,phaseUs:10,private:'synthetic-secret'}));
 const log=rows.map(row=>`I/flutter: ${JSON.stringify(row)}`).join('\n');
 const parsed=startupPhases(log);
 assert.equal(parsed.length,7);assert.equal(JSON.stringify(parsed).includes('synthetic-secret'),false);
 assert.throws(()=>startupPhases(log.split('\n').slice(1).join('\n')));
 rows[1].elapsedUs=1;
 assert.throws(()=>startupPhases(rows.map(JSON.stringify).join('\n')));
});
