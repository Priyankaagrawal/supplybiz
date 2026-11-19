import { BadRequestException,GoneException,Injectable,NotFoundException,StreamableFile,UnprocessableEntityException } from '@nestjs/common';
import { Prisma,report_exports } from '@prisma/client';
import { createHash,randomUUID } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { dateOnly,dayString } from '../subscriptions/subscription-policy';
import { ReportsService } from './reports.service';
import { reportCsv } from './report-csv';
import { ReportExportCreated,ReportExportInput,ReportExportStatus } from './report-exports.dto';
@Injectable()
export class ReportExportsService {
  constructor(private readonly db:PrismaService,private readonly reports:ReportsService,private readonly keys:IdempotencyService){}
  create(userId:string,key:string,input:ReportExportInput):Promise<ReportExportCreated>{
    if(typeof key!=='string'||!key.trim()||key.length>120)throw new BadRequestException({code:'INVALID_IDEMPOTENCY_KEY'});
    const requestKey=createHash('sha256').update(`REPORT_EXPORT:${userId}:${key}`).digest('hex'),hash=this.keys.hashRequestBody(input);
    return this.reports.authorizedExport(userId,input,async(tx,vendorId,range,days)=>{
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${requestKey},0))::text`;
      const prior=await tx.report_exports.findUnique({where:{request_key:requestKey}}),now=new Date(range.serverTime);
      if(prior){
        if(prior.user_id!==userId||prior.vendor_id!==vendorId||prior.request_hash!==hash)throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
        if(prior.expires_at<=now)throw new GoneException({code:'REPORT_EXPORT_EXPIRED'});
        return {exportId:prior.id};
      }
      const snapshot=await this.reports.exportSnapshot(tx,vendorId,range,days),content=reportCsv(snapshot),id=randomUUID();
      await tx.report_exports.create({data:{id,user_id:userId,vendor_id:vendorId,request_key:requestKey,request_hash:hash,from_date:dateOnly(range.from),to_date:dateOnly(range.to),
        content,byte_size:content.length,sha256:createHash('sha256').update(content).digest('hex'),created_at:now,expires_at:new Date(now.getTime()+86400000)}});
      await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'REPORT_EXPORTED',entity:'REPORT_EXPORT',entity_id:id,
        after:{from:range.from,to:range.to,format:'CSV',sizeBytes:content.length,productGroups:snapshot.products.total}}});
      return {exportId:id};
    });
  }
  private async owned(tx:Prisma.TransactionClient,userId:string,vendorId:string,id:string){
    const row=await tx.report_exports.findFirst({where:{id,user_id:userId,vendor_id:vendorId}});
    if(!row)throw new NotFoundException({code:'REPORT_EXPORT_NOT_FOUND'});return row;
  }
  status(userId:string,id:string):Promise<ReportExportStatus>{return this.reports.authorizedExport(userId,{},async(tx,vendorId,range)=>{
    const row=await this.owned(tx,userId,vendorId,id),expired=row.expires_at<=new Date(range.serverTime);
    return {exportId:row.id,status:expired?'EXPIRED':'READY',format:'CSV',from:dayString(row.from_date),to:dayString(row.to_date),
      createdAt:row.created_at.toISOString(),expiresAt:row.expires_at.toISOString(),sizeBytes:row.byte_size,sha256:row.sha256,
      downloadPath:expired?null:`/api/v1/vendor/reports/exports/${row.id}/download`};
  });}
  download(userId:string,id:string):Promise<StreamableFile>{return this.reports.authorizedExport(userId,{},async(tx,vendorId,range)=>{
    const row=await this.owned(tx,userId,vendorId,id);
    if(row.expires_at<=new Date(range.serverTime))throw new GoneException({code:'REPORT_EXPORT_EXPIRED'});
    return this.file(row);
  });}
  private file(row:report_exports){
    const name=`supplybiz-report-${dayString(row.from_date)}-${dayString(row.to_date)}-${row.id}.csv`;
    return new StreamableFile(row.content,{type:'text/csv; charset=utf-8',disposition:`attachment; filename="${name}"`,length:row.byte_size});
  }
  cleanupExpired(){return this.db.$executeRaw`DELETE FROM report_exports WHERE id IN (
    SELECT id FROM report_exports WHERE expires_at<=clock_timestamp() ORDER BY expires_at,id LIMIT 500 FOR UPDATE SKIP LOCKED)`;}
}
