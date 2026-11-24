// T-018: real loopback HTTP/error pipeline; no database/provider needed.
import { BadRequestException, Controller, Get, INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { configureHttpApp } from '../bootstrap';
import { PinoLogger } from './logging/pino.logger';
import { RequestIdMiddleware } from './request-id.middleware';
const privateText='synthetic-secret phone=+919000000000 https://private.example.invalid?token=synthetic';
@Controller('diagnostic-fixture')
class FixtureController {
 @Get('unexpected') unexpected(){throw new Error(privateText);}
 @Get('opaque') opaque(){throw {toString:()=>{throw new Error('Must not inspect payload');}};}
 @Get('invalid') invalid(){throw new BadRequestException({code:'VALIDATION_FAILED',message:'Invalid fixture'});}
}
describe('T-018 sanitized unhandled diagnostics',()=>{
 let app:INestApplication;
 const logger={log:jest.fn(),error:jest.fn(),warn:jest.fn()};
 beforeAll(async()=>{
  const module=await Test.createTestingModule({controllers:[FixtureController],providers:[{provide:PinoLogger,useValue:logger}]}).compile();
  app=module.createNestApplication();
  const ids=new RequestIdMiddleware();app.use(ids.use.bind(ids));
  configureHttpApp(app);await app.init();
 });
 beforeEach(()=>logger.error.mockClear());
 afterAll(async()=>{await app.close();});
 it('returns safe 500 and logs only bounded event/build/environment plus valid request ID',async()=>{
  const id='11111111-1111-4111-8111-111111111111';
  const response=await request(app.getHttpServer()).get('/api/v1/diagnostic-fixture/unexpected?secret=synthetic').set('Authorization','Bearer synthetic-secret').set('X-Request-Id',id).expect(500);
  expect(response.body).toMatchObject({status:500,code:'INTERNAL',requestId:id,detail:'Unexpected server error'});
  expect(logger.error).toHaveBeenCalledTimes(1);
  const text=String(logger.error.mock.calls[0][0]);
  expect(JSON.parse(text)).toMatchObject({event:'API_UNHANDLED_EXCEPTION',requestId:id});
  expect(text).not.toMatch(/synthetic|private|phone|Bearer/);
  expect(JSON.stringify(response.body)).not.toContain(privateText);
 });
 it('does not inspect opaque exceptions or log arbitrary request headers/build variables',async()=>{
  const original=process.env.BUILD_SHA;process.env.BUILD_SHA='synthetic-private-token';
  try{
   await request(app.getHttpServer()).get('/api/v1/diagnostic-fixture/opaque').set('X-Request-Id','synthetic-private-header').expect(500);
   const row=JSON.parse(String(logger.error.mock.calls[0][0]));
   expect(row.requestId).toBe('unavailable');expect(row.build).toBe('unavailable');
   expect(JSON.stringify(row)).not.toContain('synthetic');
  }finally{if(original===undefined)delete process.env.BUILD_SHA;else process.env.BUILD_SHA=original;}
 });
 it('preserves typed validation responses without an unhandled-error diagnostic',async()=>{
  const response=await request(app.getHttpServer()).get('/api/v1/diagnostic-fixture/invalid').expect(400);
  expect(response.body.code).toBe('VALIDATION_FAILED');expect(logger.error).not.toHaveBeenCalled();
 });
});
