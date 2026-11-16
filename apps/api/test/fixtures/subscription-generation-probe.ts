// T-073 subprocess probe: production consumers/lease path, one explicit fixture event only.
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../../src/app.module';
import { OutboxDispatcherService } from '../../src/outbox/outbox-dispatcher.service';
async function main() {
  const id=process.argv[2];
  if(!id || !/^[0-9a-f-]{36}$/i.test(id))throw new Error('Explicit test event required');
  const url=new URL(process.env.DATABASE_URL!);
  if(process.env.NODE_ENV!=='test' || !url.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(url.hostname))throw new Error('Dedicated local test DB required');
  const app=await NestFactory.createApplicationContext(AppModule,{logger:false});
  try {
    const count=await app.get(OutboxDispatcherService).dispatchPendingBatch(1,id);
    process.stdout.write(`GENERATION_PROBE_DONE:${count}\n`);
  } finally {await app.close();}
}
void main().catch(()=>{process.stderr.write('GENERATION_PROBE_FAILED\n');process.exitCode=1;});
