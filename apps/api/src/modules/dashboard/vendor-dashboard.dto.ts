// T-030 / FR-020-022. Exact money and stock strings.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, Matches, ValidateIf } from 'class-validator';
export class VendorDashboardQuery {
  @ApiPropertyOptional({ type: String, pattern: '^\\d{4}-\\d{2}-\\d{2}$', description: 'IST calendar date; omitted uses database current IST date.' })
  @ValidateIf((_: unknown, value: unknown) => value !== undefined)
  @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date?: string;
}
export class VendorDashboard {
  @ApiProperty({ format: 'date-time', description: 'Database snapshot time for last-updated display.' }) serverTime!: string;
  @ApiProperty({ type: String, format: 'date' }) businessDate!: string;
  @ApiProperty({ type: String, format: 'date', description: 'Selected IST date. Order counts use scheduled delivery date; sales use actual completion/sale date.' }) date!: string;
  @ApiProperty({ type: String, nullable: true }) shopName!: string | null;
  @ApiProperty({ type: String, nullable: true }) city!: string | null;
  @ApiProperty({ type: String, format: 'uuid', nullable: true, description: 'Owned photo ID for the existing authorized media route.' }) shopPhotoMediaId!: string | null;
  @ApiProperty({ description: 'Stored VERIFIED KYC only; no provider verification implied.' }) verified!: boolean;
  @ApiProperty({ type: 'integer', minimum: 0, description: 'All retained orders scheduled for selected date, including cancelled/rejected/failed.' }) todayOrders!: number;
  @ApiProperty({ type: 'integer', minimum: 0, description: 'NEW, ACCEPTED, PREPARING or OUT_FOR_DELIVERY on selected delivery date.' }) pendingOrders!: number;
  @ApiProperty({ type: 'integer', minimum: 0, description: 'DELIVERED on selected delivery date.' }) completedOrders!: number;
  @ApiProperty({ type: String, pattern: '^[0-9]+$', description: 'Selected IST completion/sale date gross: delivered order totals plus POS totals. Stored discounts/delivery charges included; not receipts, ledger credits or plan revenue.' }) todaySalesPaise!: string;
  @ApiProperty({ type: String, pattern: '^[0-9]+$', description: 'Lifetime DELIVERED order totals plus POS totals. Recorded sales, not profit or money received; independent payments/claims/reversals are not new sales.' }) totalEarningsPaise!: string;
  @ApiProperty({ type: String, pattern: '^[0-9]+(\\.[0-9]+)?$', description: 'Current known milk litres: active non-deleted MILK stock times pack volume, L plus ML/1000. Exact decimal, independent of date.' }) milkStockLitres!: string;
  @ApiProperty({ type: 'integer', minimum: 0, description: 'Active stocked milk products in G/KG/PCS excluded from litres because volume is unknown. Disclose incomplete volume when nonzero.' }) milkStockUnmeasuredProducts!: number;
  @ApiProperty({ type: 'integer', minimum: 0, description: 'Current ACTIVE non-deleted vendor customer links including offline customers; independent of date.' }) activeCustomers!: number;
}
