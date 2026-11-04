// ADR-026: unlisted permissions (including future/deferred functions) are denied.
export const ADMIN_GRANTS = {
  SUPER_ADMIN: ['dashboard.read', 'admins.manage', 'config.manage', 'audit.read', 'privacy.manage',
    'kyc.review', 'kyc.documents', 'vendors.read', 'vendors.manage', 'customers.read', 'customers.manage',
    'orders.read', 'categories.manage', 'cms.manage', 'plans.manage', 'reports.read', 'reports.export'],
  OPS: ['kyc.review', 'kyc.documents', 'vendors.read', 'vendors.manage', 'customers.read',
    'customers.manage', 'categories.manage', 'cms.manage'],
  SUPPORT: ['vendors.read', 'customers.read', 'orders.read'],
  FINANCE: ['plans.manage', 'reports.read', 'reports.export'],
} as const;
export function permissions(role: string): string[] {
  return Object.prototype.hasOwnProperty.call(ADMIN_GRANTS, role) ? [...ADMIN_GRANTS[role as keyof typeof ADMIN_GRANTS]] : [];
}
