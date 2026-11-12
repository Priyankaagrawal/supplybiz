import { ApiProperty } from '@nestjs/swagger';
export class AdminDashboard {
 @ApiProperty({ format: 'date-time' }) serverTime!: string;
 @ApiProperty({ minimum: 0, type: 'integer' }) vendorsTotal!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) vendorsSuspended!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) kycPending!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) kycVerified!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) customersTotal!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) customersBlocked!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) ordersTotal!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) ordersDelivered!: number;
 @ApiProperty({ minimum: 0, type: 'integer' }) ordersFailed!: number;
 @ApiProperty({ pattern: '^[0-9]+$', description: 'Delivered-order component of PRD GMV only; quick-sale value unavailable until T-079/T-080. All-time stored DELIVERED order totals, including delivery charges and discounts; not cash receipts. Decimal integer paise string preserves BigInt precision.' }) recordedGmvPaise!: string;
 @ApiProperty({ enum: ['DELIVERED_ORDERS_ONLY'], description: 'Full platform GMV also requires quick-sale value, unavailable before T-079/T-080.' }) gmvScope!: string;
 @ApiProperty({ minimum: 0, type: 'integer', description: 'All historical audited assignment rows, including superseded grants; never revenue.' }) planAssignmentsTotal!: number;
 @ApiProperty({ enum: ['UNAVAILABLE'], description: 'Automated plan billing is deferred; no inferred revenue.' }) planRevenueStatus!: string;
}
