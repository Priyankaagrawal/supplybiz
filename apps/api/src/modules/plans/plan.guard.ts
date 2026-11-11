import { CanActivate, ExecutionContext, ForbiddenException, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { PlanEntitlementsService } from './plan-entitlements.service';
import { PlanFeature } from './plan-policy';

export const RequirePlanFeature = (feature: PlanFeature) => SetMetadata('plan-feature', feature);
@Injectable()
export class PlanGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly db: PrismaService, private readonly plans: PlanEntitlementsService) {}
  async canActivate(context: ExecutionContext) {
    const feature = this.reflector.getAllAndOverride<PlanFeature>('plan-feature', [context.getHandler(), context.getClass()]);
    if (!feature) return true;
    // SessionGuard must run first. Ignore body/query vendorId and client entitlements.
    const req = context.switchToHttp().getRequest<{ session?: { userId: string } }>();
    await this.db.$transaction(async tx => {
      const user = req.session && await tx.users.findUnique({ where: { id: req.session.userId }, include: { roles: true, vendor: true } });
      if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR') || !user.vendor) {
        throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
      }
      await this.plans.requireFeature(tx, user.vendor.id, feature);
    });
    return true;
  }
}
