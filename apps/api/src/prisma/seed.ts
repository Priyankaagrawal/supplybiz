import { PrismaClient, category_status, category_type, plan_code, plan_price_duration } from "@prisma/client";

const prisma = new PrismaClient();

type CategorySeed = {
  code: string;
  name_en: string;
  name_hi: string;
  icon: string;
  type: category_type;
  status: category_status;
  sort_order: number;
  product_types: string[];
};

type PlanSeed = {
  code: plan_code;
  name: string;
  customer_limit: number;
  is_popular: boolean;
  features: string[];
  prices: Array<{
    duration: plan_price_duration;
    price_paise: bigint;
  }>;
};

const categories: CategorySeed[] = [
  {
    code: "MILK",
    name_en: "Milk",
    name_hi: "दूध",
    icon: "milk",
    type: category_type.SUPPLY,
    status: category_status.ENABLED,
    sort_order: 1,
    product_types: ["MILK", "CURD", "PANEER", "GHEE"],
  },
  {
    code: "DAIRY_PRODUCTS",
    name_en: "Dairy Products",
    name_hi: "डेयरी उत्पाद",
    icon: "dairy",
    type: category_type.SUPPLY,
    status: category_status.ENABLED,
    sort_order: 2,
    product_types: ["CURD", "PANEER", "GHEE", "BUTTER"],
  },
  {
    code: "WATER_CANS",
    name_en: "Water Cans",
    name_hi: "पानी के कैन",
    icon: "water_can",
    type: category_type.SUPPLY,
    status: category_status.ENABLED,
    sort_order: 3,
    product_types: ["WATER_CAN"],
  },
  {
    code: "TIFFIN",
    name_en: "Tiffin",
    name_hi: "टिफिन",
    icon: "tiffin",
    type: category_type.SUPPLY,
    status: category_status.COMING_SOON,
    sort_order: 4,
    product_types: ["TIFFIN"],
  },
  {
    code: "BILLS",
    name_en: "Bill Payments",
    name_hi: "बिल भुगतान",
    icon: "bill",
    type: category_type.BILL,
    status: category_status.COMING_SOON,
    sort_order: 20,
    product_types: ["ELECTRICITY", "WATER", "GAS", "MOBILE"],
  },
];

const plans: PlanSeed[] = [
  {
    code: plan_code.BASIC,
    name: "Basic",
    customer_limit: 100,
    is_popular: false,
    features: ["BASIC_ORDER_MANAGEMENT"],
    prices: [
      { duration: plan_price_duration.MONTHLY, price_paise: 9900n },
      { duration: plan_price_duration.HALF_YEARLY, price_paise: 49900n },
      { duration: plan_price_duration.YEARLY, price_paise: 99900n },
    ],
  },
  {
    code: plan_code.STANDARD,
    name: "Standard",
    customer_limit: 250,
    is_popular: false,
    features: ["BASIC_ORDER_MANAGEMENT", "SUBSCRIPTIONS", "DELIVERY_MANAGEMENT"],
    prices: [
      { duration: plan_price_duration.MONTHLY, price_paise: 19900n },
      { duration: plan_price_duration.HALF_YEARLY, price_paise: 99900n },
      { duration: plan_price_duration.YEARLY, price_paise: 149900n },
    ],
  },
  {
    code: plan_code.BUSINESS,
    name: "Business",
    customer_limit: 500,
    is_popular: true,
    features: [
      "BASIC_ORDER_MANAGEMENT",
      "SUBSCRIPTIONS",
      "DELIVERY_MANAGEMENT",
      "AUTO_ACCEPT",
      "STOCK_ALERTS",
      "ADVANCED_REPORTS",
    ],
    prices: [
      { duration: plan_price_duration.MONTHLY, price_paise: 29900n },
      { duration: plan_price_duration.HALF_YEARLY, price_paise: 149900n },
      { duration: plan_price_duration.YEARLY, price_paise: 199900n },
    ],
  },
  {
    code: plan_code.PREMIUM,
    name: "Premium",
    customer_limit: 1000,
    is_popular: false,
    features: [
      "BASIC_ORDER_MANAGEMENT",
      "SUBSCRIPTIONS",
      "DELIVERY_MANAGEMENT",
      "AUTO_ACCEPT",
      "STOCK_ALERTS",
      "ADVANCED_REPORTS",
      "WALLET_SETTLEMENT",
      "PRIORITY_SUPPORT",
      "COMPLETE_MANAGEMENT",
    ],
    prices: [
      { duration: plan_price_duration.MONTHLY, price_paise: 49900n },
      { duration: plan_price_duration.HALF_YEARLY, price_paise: 199900n },
      { duration: plan_price_duration.YEARLY, price_paise: 349900n },
    ],
  },
];

async function seedCategories(): Promise<void> {
  for (const category of categories) {
    await prisma.categories.upsert({
      where: { code: category.code },
      update: {
        name_en: category.name_en,
        name_hi: category.name_hi,
        icon: category.icon,
        type: category.type,
        status: category.status,
        sort_order: category.sort_order,
        product_types: category.product_types,
      },
      create: category,
    });
  }
}

async function seedPlans(): Promise<void> {
  for (const plan of plans) {
    const seededPlan = await prisma.plans.upsert({
      where: { code: plan.code },
      update: {
        name: plan.name,
        customer_limit: plan.customer_limit,
        is_popular: plan.is_popular,
        features: plan.features,
      },
      create: {
        code: plan.code,
        name: plan.name,
        customer_limit: plan.customer_limit,
        is_popular: plan.is_popular,
        features: plan.features,
      },
    });

    for (const price of plan.prices) {
      await prisma.plan_prices.upsert({
        where: {
          plan_id_duration: {
            plan_id: seededPlan.id,
            duration: price.duration,
          },
        },
        update: {
          price_paise: price.price_paise,
        },
        create: {
          plan_id: seededPlan.id,
          duration: price.duration,
          price_paise: price.price_paise,
        },
      });
    }
  }
}

async function main(): Promise<void> {
  await seedCategories();
  await seedPlans();
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    // eslint-disable-next-line no-console
    console.error("Seed failed", error);
    await prisma.$disconnect();
    process.exit(1);
  });
