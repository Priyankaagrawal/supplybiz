import { plan_code } from '@prisma/client';

// ADR-029 / PRD §5. No trial, grace, wallet/settlement or undefined support action.
export const CUSTOMER_LIMITS: Record<plan_code, number> = { BASIC: 100, STANDARD: 250, BUSINESS: 500, PREMIUM: 1000 };
const common = ['BASIC_ORDER_MANAGEMENT', 'QUICK_SALE', 'KHATA', 'PAYMENT_RECORDS', 'BASIC_REPORTS'] as const;
const standard = [...common, 'SUBSCRIPTIONS', 'DELIVERY_MANAGEMENT'] as const;
const business = [...standard, 'AUTO_ACCEPT', 'STOCK_MANAGEMENT', 'STOCK_ALERTS', 'ADVANCED_REPORTS'] as const;
export type PlanFeature = typeof business[number];
export const PLAN_FEATURES: Record<plan_code, readonly PlanFeature[]> = {
  BASIC: common, STANDARD: standard, BUSINESS: business, PREMIUM: business,
};
export type PlanOperation = 'NEW_ORDER' | 'POS_SALE' | 'SUBSCRIPTION' | 'GENERATE_DELIVERY' |
  'READ_HISTORY' | 'RECORD_PAYMENT' | 'CONFIRM_PAYMENT' | 'COMPLETE_ORDER' | 'CANCEL_ORDER';
export const OPERATION_FEATURES: Record<PlanOperation, PlanFeature> = {
  NEW_ORDER: 'BASIC_ORDER_MANAGEMENT', POS_SALE: 'QUICK_SALE', SUBSCRIPTION: 'SUBSCRIPTIONS',
  GENERATE_DELIVERY: 'SUBSCRIPTIONS', READ_HISTORY: 'KHATA', RECORD_PAYMENT: 'PAYMENT_RECORDS',
  CONFIRM_PAYMENT: 'PAYMENT_RECORDS', COMPLETE_ORDER: 'BASIC_ORDER_MANAGEMENT', CANCEL_ORDER: 'BASIC_ORDER_MANAGEMENT',
};
export const EXPIRY_OPERATIONS: readonly PlanOperation[] = ['READ_HISTORY', 'RECORD_PAYMENT', 'CONFIRM_PAYMENT', 'COMPLETE_ORDER', 'CANCEL_ORDER'];
