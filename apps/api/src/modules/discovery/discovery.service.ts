import { BadRequestException, ForbiddenException, Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { MediaService } from '../media/media.service';
import { DiscoveryQuery, DiscoveredVendor } from './discovery.dto';
type Tx = Prisma.TransactionClient;
type Row = DiscoveredVendor & { priority: number; score: number };
type Cursor = { context: string; at: string; priority: number; score: number; distanceMeters: number; id: string };
@Injectable()
export class DiscoveryService {
  private readonly cursorKey: Buffer;
  constructor(private readonly db: PrismaService, private readonly media: MediaService, config: ConfigService) {
    this.cursorKey = createHash('sha256').update('discovery-cursor:').update(config.get<string>('AUTH_SIGNING_PRIVATE_KEY') ?? randomBytes(32)).digest();
  }
  private async customer(tx: Tx, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'CUSTOMER' || !user.roles.some(r => r.role === 'CUSTOMER')) throw new ForbiddenException({ code: 'CUSTOMER_ROLE_REQUIRED' });
  }
  private context(userId: string, q: DiscoveryQuery, favorites: boolean) {
    return createHash('sha256').update(JSON.stringify([userId,q.lat,q.lng,q.pincode,q.category,q.q,q.sort ?? 'NEARBY',favorites])).digest('hex');
  }
  private sign(payload: string) { return createHmac('sha256', this.cursorKey).update(payload).digest(); }
  private encode(c: Cursor) { const p = Buffer.from(JSON.stringify(c)).toString('base64url'); return `${p}.${this.sign(p).toString('base64url')}`; }
  private decode(raw: string, context: string): Cursor {
    try {
      const [p, signature] = raw.split('.');
      const supplied = Buffer.from(signature ?? '', 'base64url'), expected = this.sign(p ?? '');
      if (!p || raw.split('.').length !== 2 || supplied.length !== expected.length || !timingSafeEqual(supplied, expected)) throw new Error();
      const c = JSON.parse(Buffer.from(p, 'base64url').toString()) as Cursor;
      if (c.context !== context || !Number.isFinite(Date.parse(c.at)) || ![0,1].includes(c.priority) || !Number.isSafeInteger(c.score) || c.score > 0 || !Number.isFinite(c.distanceMeters) || c.distanceMeters < 0 || !/^[a-f0-9-]{36}$/i.test(c.id)) throw new Error();
      return c;
    } catch { throw new BadRequestException({ code: 'INVALID_CURSOR' }); }
  }
  /** Eligibility is checked on every read, including detail, products and image streams. */
  private async rows(tx: Tx, userId: string, q: DiscoveryQuery, at: Date, options: { id?: string; favorites?: boolean; cursor?: Cursor | null; limit?: number } = {}) {
    const term = q.q ?? '';
    const score = q.sort === 'POPULAR' ? Prisma.sql`-completed` : Prisma.sql`0`;
    return tx.$queryRaw<Row[]>`WITH eligible AS (
      SELECT v.id, v.business_name AS "businessName", v.category_id AS "categoryId", v.shop_photo_media_id AS "shopPhotoMediaId", v.badges,
        ST_Distance(v.location, ST_SetSRID(ST_MakePoint(${q.lng},${q.lat}),4326)::geography) AS "distanceMeters",
        EXISTS(SELECT 1 FROM favorites f WHERE f.vendor_id=v.id AND f.user_id=${userId}::uuid) AS favorite,
        (SELECT count(*)::int FROM orders o WHERE o.vendor_id=v.id AND o.status='DELIVERED'
          AND o.completed_at >= ${at}::timestamptz - interval '30 days' AND o.completed_at <= ${at}::timestamptz) AS completed
      FROM vendors v JOIN users u ON u.id=v.user_id JOIN vendor_settings s ON s.vendor_id=v.id
      JOIN categories c ON c.id=v.category_id
      WHERE v.kyc_status='VERIFIED' AND NOT v.is_suspended AND u.status='ACTIVE'
        AND c.status='ENABLED' AND c.type='SUPPLY' AND v.business_name IS NOT NULL AND v.location IS NOT NULL
        AND (${options.id ?? null}::uuid IS NULL OR v.id=${options.id ?? null}::uuid)
        AND (${q.category ?? null}::uuid IS NULL OR v.category_id=${q.category ?? null}::uuid)
        AND (COALESCE(ST_DWithin(v.location,ST_SetSRID(ST_MakePoint(${q.lng},${q.lat}),4326)::geography,s.service_radius_km*1000),false)
          OR EXISTS(SELECT 1 FROM vendor_service_pincodes p WHERE p.vendor_id=v.id AND p.pincode=${q.pincode}))
        AND EXISTS(SELECT 1 FROM vendor_plan_assignments a JOIN plans p ON p.id=a.plan_id JOIN audit_logs l ON l.id=a.audit_id
          WHERE a.vendor_id=v.id AND a.superseded_at IS NULL AND p.status='ACTIVE'
            AND a.starts_at <= statement_timestamp() AND a.ends_at > statement_timestamp()
            AND l.actor_type='ADMIN' AND l.actor_id=a.granted_by_admin AND l.entity='VENDOR' AND l.entity_id=v.id AND l.action='PLAN_ASSIGNED')
        AND (${term}='' OR position(lower(${term}) in lower(v.business_name))>0
          OR EXISTS(SELECT 1 FROM products p WHERE p.vendor_id=v.id AND p.is_active AND p.deleted_at IS NULL AND position(lower(${term}) in lower(p.name))>0))
    ), ranked AS (SELECT id,"businessName","categoryId","shopPhotoMediaId",badges,"distanceMeters",favorite,
      completed AS "completedOrders30Days", CASE WHEN favorite THEN 0 ELSE 1 END AS priority, ${score} AS score
      FROM eligible WHERE (${options.favorites ?? false}=false OR favorite))
      SELECT * FROM ranked WHERE ${options.cursor ? Prisma.sql`(priority,score,"distanceMeters",id) > (${options.cursor.priority},${options.cursor.score},${options.cursor.distanceMeters},${options.cursor.id}::uuid)` : Prisma.sql`true`}
      ORDER BY priority,score,"distanceMeters",id LIMIT ${options.limit ?? 1}`;
  }
  list(userId: string, q: DiscoveryQuery, favorites = false) {
    return this.db.$transaction(async tx => {
      await this.customer(tx,userId);
      const context = this.context(userId,q,favorites), cursor = q.cursor ? this.decode(q.cursor,context) : null;
      const [clock] = await tx.$queryRaw<{now:Date}[]>`SELECT statement_timestamp() AS now`;
      const at = cursor ? new Date(cursor.at) : clock!.now;
      if (clock!.now.getTime()-at.getTime()>900000 || at>clock!.now) throw new BadRequestException({code:'INVALID_CURSOR'});
      const after = await this.rows(tx,userId,q,at,{favorites,cursor,limit:(q.limit ?? 20)+1});
      const page = after.slice(0,q.limit ?? 20), last = page.at(-1);
      return { items: page.map(r=>this.present(r)), nextCursor: after.length>page.length && last ? this.encode({context,at:at.toISOString(),priority:last.priority,score:last.score,distanceMeters:last.distanceMeters,id:last.id}) : null };
    }, { isolationLevel:'RepeatableRead' });
  }
  private present(row: Row) { return {id:row.id,businessName:row.businessName,categoryId:row.categoryId,shopPhotoMediaId:row.shopPhotoMediaId,badges:row.badges,distanceMeters:row.distanceMeters,completedOrders30Days:row.completedOrders30Days,favorite:row.favorite}; }
  private async eligible(tx: Tx,userId: string,id: string,q: DiscoveryQuery) {
    await this.customer(tx,userId);
    const [clock] = await tx.$queryRaw<{now:Date}[]>`SELECT statement_timestamp() AS now`;
    const row = (await this.rows(tx,userId,{...q,q:undefined,category:undefined},clock!.now,{id}))[0];
    if (!row) throw new NotFoundException({code:'VENDOR_UNAVAILABLE'});
    return row;
  }
  about(userId: string,id: string,q: DiscoveryQuery) {
    return this.db.$transaction(async tx=>{
      const row = await this.eligible(tx,userId,id,q);
      const v = await tx.vendors.findUniqueOrThrow({where:{id},include:{settings:true}});
      const holidays = await tx.vendor_holidays.findMany({where:{vendor_id:id},orderBy:{date:'asc'}});
      return {...this.present(row),address:v.address_line,city:v.city,state:v.state,pincode:v.pincode,
        deliveryChargePaise:v.settings!.delivery_charge_paise,minOrderPaise:v.settings!.min_order_paise,
        openingHours:null,holidays:holidays.map(h=>({date:h.date.toISOString().slice(0,10),reason:h.reason}))};
    },{isolationLevel:'RepeatableRead'});
  }
  products(userId: string,id: string,q: DiscoveryQuery,productId?: string) {
    return this.db.$transaction(async tx=>{
      await this.eligible(tx,userId,id,q);
      const items = await tx.products.findMany({where:{vendor_id:id,id:productId,is_active:true,deleted_at:null,
        ...(q.q?{name:{contains:q.q,mode:'insensitive' as const}}:{})},orderBy:[{name:'asc'},{id:'asc'}]});
      const mapped = items.map(p=>({id:p.id,name:p.name,productType:p.product_type,milkType:p.milk_type,unitValue:p.unit_value.toNumber(),unitType:p.unit_type,
        sellingPricePaise:p.selling_price_paise,subscriptionPricePaise:p.subscription_price_paise,stockQty:p.stock_qty,moq:p.moq,description:p.description,
        imageMediaId:p.image_media_id,isActive:p.is_active,version:p.version}));
      if (productId && !mapped.length) throw new NotFoundException({code:'PRODUCT_NOT_FOUND'});
      return {items:mapped,total:mapped.length};
    },{isolationLevel:'RepeatableRead'});
  }
  async image(userId:string,id:string,mediaId:string,q:DiscoveryQuery) {
    const owner = await this.db.$transaction(async tx=>{
      await this.eligible(tx,userId,id,q);
      const v = await tx.vendors.findUniqueOrThrow({where:{id}});
      const product = await tx.products.findFirst({where:{vendor_id:id,image_media_id:mediaId,is_active:true,deleted_at:null}});
      const media = await tx.media_files.findFirst({where:{id:mediaId,owner_user_id:v.user_id,status:'READY',purpose:product?'PRODUCT_IMAGE':'SHOP_PHOTO'}});
      if (!media || (!product && v.shop_photo_media_id!==mediaId)) throw new NotFoundException();
      return v.user_id;
    });
    return this.media.content(mediaId,{owner});
  }
  favorite(userId:string,id:string,enabled:boolean,q:DiscoveryQuery,key:string) {
    if (!key?.trim() || key.length>120) throw new BadRequestException({code:'VALIDATION_FAILED'});
    return this.db.$transaction(async tx=>{
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
      await this.customer(tx,userId);
      if (enabled) await this.eligible(tx,userId,id,q);
      const cacheKey = `favorites:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`;
      const hash = createHash('sha256').update(JSON.stringify([id,enabled,q.lat,q.lng,q.pincode])).digest('hex');
      const cached = await tx.idempotency_keys.findUnique({where:{idempotency_key:cacheKey}});
      if (cached && cached.expires_at > new Date()) {
        if (cached.request_hash !== hash) throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
        return cached.response_body;
      }
      if (cached) await tx.idempotency_keys.delete({where:{idempotency_key:cacheKey}});
      if (enabled) {
        await tx.favorites.upsert({where:{user_id_vendor_id:{user_id:userId,vendor_id:id}},create:{user_id:userId,vendor_id:id},update:{}});
      } else await tx.favorites.deleteMany({where:{user_id:userId,vendor_id:id}});
      const result = {vendorId:id,favorite:enabled};
      await tx.idempotency_keys.create({data:{idempotency_key:cacheKey,user_id:userId,method:enabled?'PUT':'DELETE',path:`favorites/${id}`,request_hash:hash,response_status:200,response_body:result,expires_at:new Date(Date.now()+86400000)}});
      return result;
    });
  }
}
