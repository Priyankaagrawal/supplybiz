import { user_role_type } from '@prisma/client';

// Server-owned English templates: no names, amounts, addresses or KYC/bank fields.
export const eventTemplates = {
  KYC_STATUS: ['VENDOR', 'SYSTEM', 'KYC status updated', '/vendor/onboarding/status'],
  SECURITY: [null, 'SYSTEM', 'Account security update', '/common/settings'],
  ORDER_NEW: ['VENDOR', 'ORDERS', 'New order', '/vendor/orders/'],
  ORDER_CANCELLED: ['VENDOR', 'ORDERS', 'Order cancelled', '/vendor/orders/'],
  SUBSCRIPTION_REQUEST: ['VENDOR', 'ORDERS', 'Subscription request', '/vendor/customers/subscriptions/'],
  PAYMENT_CLAIM: ['VENDOR', 'PAYMENTS', 'Payment claim received', '/vendor/khata/'],
  PLAN_EXPIRING: ['VENDOR', 'SYSTEM', 'Plan expiring', '/vendor/plans'],
  ORDER_ACCEPTED: ['CUSTOMER', 'ORDERS', 'Order accepted', '/customer/orders/'],
  ORDER_REJECTED: ['CUSTOMER', 'ORDERS', 'Order rejected', '/customer/orders/'],
  OUT_FOR_DELIVERY: ['CUSTOMER', 'ORDERS', 'Order out for delivery', '/customer/orders/'],
  ORDER_DELIVERED: ['CUSTOMER', 'ORDERS', 'Order delivered', '/customer/orders/'],
  DELIVERY_FAILED: ['CUSTOMER', 'ORDERS', 'Delivery update', '/customer/orders/'],
  PAYMENT_RECORDED: ['CUSTOMER', 'PAYMENTS', 'Payment recorded', '/customer/khata/'],
  SUBSCRIPTION_APPROVED: ['CUSTOMER', 'ORDERS', 'Subscription approved', '/customer/subscriptions/'],
  SUBSCRIPTION_RENEWED: ['CUSTOMER', 'ORDERS', 'Subscription renewed', '/customer/subscriptions/'],
  SUBSCRIPTION_PAUSED: ['CUSTOMER', 'ORDERS', 'Subscription paused', '/customer/subscriptions/'],
  VENDOR_HOLIDAY: ['CUSTOMER', 'SYSTEM', 'Vendor holiday', '/customer/subscriptions'],
  DELIVERY_UPDATE: ['VENDOR', 'DELIVERY', 'Delivery update', '/vendor/deliveries'],
} as const;
export type NotificationEvent = { recipientId: string; role: user_role_type; type: keyof typeof eventTemplates;
  sourceKey: string; entityId?: string };
export const mandatoryNotification = (type: string) => type === 'KYC_STATUS' || type === 'SECURITY';
