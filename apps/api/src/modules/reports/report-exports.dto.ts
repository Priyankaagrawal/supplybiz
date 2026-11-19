import { ApiProperty } from '@nestjs/swagger';
import { IsIn,IsString,Matches } from 'class-validator';
export class ReportExportInput {
  @ApiProperty({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$'}) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) from!:string;
  @ApiProperty({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$'}) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) to!:string;
  @ApiProperty({enum:['CSV']}) @IsIn(['CSV']) format!:string;
}
export class ReportExportCreated { @ApiProperty({format:'uuid'}) exportId!:string; }
export class ReportExportStatus extends ReportExportCreated {
  @ApiProperty({enum:['READY','EXPIRED'],description:'Generated synchronously within operational limits. Download always rechecks live access.'}) status!:string;
  @ApiProperty({type:String,format:'date'}) from!:string;
  @ApiProperty({type:String,format:'date'}) to!:string;
  @ApiProperty({format:'date-time'}) createdAt!:string;
  @ApiProperty({format:'date-time'}) expiresAt!:string;
  @ApiProperty({enum:['CSV']}) format!:string;
  @ApiProperty({type:'integer',minimum:1,maximum:8388608}) sizeBytes!:number;
  @ApiProperty({pattern:'^[a-f0-9]{64}$'}) sha256!:string;
  @ApiProperty({type:String,nullable:true,description:'Same-API authenticated route only, never a filesystem path/public URL. Null after 24-hour artifact/retry window.'}) downloadPath!:string|null;
}
