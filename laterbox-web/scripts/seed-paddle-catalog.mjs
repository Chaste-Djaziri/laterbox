const environment = process.env.PADDLE_CATALOG_ENV || 'sandbox';
const isProduction = environment === 'production';

if (!['sandbox', 'production'].includes(environment)) {
  throw new Error('PADDLE_CATALOG_ENV must be either sandbox or production.');
}

if (isProduction && process.env.PADDLE_CONFIRM_PRODUCTION !== 'CREATE_LIVE_CATALOG') {
  throw new Error(
    'Production seeding requires PADDLE_CONFIRM_PRODUCTION=CREATE_LIVE_CATALOG.',
  );
}

const rawApiKey =
  process.env.PADDLE_CATALOG_API_KEY ||
  (isProduction
    ? process.env.PADDLE_API_KEY
    : process.env.PADDLE_SANDBOX_API_KEY);

if (!rawApiKey) {
  throw new Error(
    `Export PADDLE_CATALOG_API_KEY with Products Read/Write and Prices Read/Write permissions before seeding ${environment}.`,
  );
}

const apiKey = rawApiKey.trim();

const expectedPrefix = isProduction ? 'pdl_live_apikey_' : 'pdl_sdbx_apikey_';
if (!apiKey.startsWith(expectedPrefix)) {
  throw new Error(
    `The ${environment} catalog requires an API key beginning with ${expectedPrefix}.`,
  );
}

const apiBase = isProduction
  ? 'https://api.paddle.com'
  : 'https://sandbox-api.paddle.com';

async function request(path, init = {}) {
  const response = await fetch(`${apiBase}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      ...init.headers,
    },
  });
  const payload = await response.json();
  if (!response.ok) {
    const detail = payload?.error?.detail || `Paddle returned ${response.status}`;
    if (response.status === 403) {
      throw new Error(
        `${detail} The catalog key needs Products Read/Write and Prices Read/Write permissions.`,
      );
    }
    if (response.status === 401) {
      throw new Error(
        `${detail} Copy only the complete pdl_live_apikey_... value, without a variable name or quotes.`,
      );
    }
    throw new Error(detail);
  }
  return payload;
}

async function create(path, body) {
  const payload = await request(path, {
    method: 'POST',
    body: JSON.stringify(body),
  });
  return payload.data;
}

async function findProduct() {
  const payload = await request('/products?status=active&per_page=100');
  return payload.data.find((product) => product.name === 'LaterBox Pro');
}

async function findPrices(productId) {
  const payload = await request(
    `/prices?product_id=${encodeURIComponent(productId)}&status=active&per_page=100`,
  );
  return payload.data;
}

const product =
  (await findProduct()) ||
  (await create('/products', {
    name: 'LaterBox Pro',
    description:
      'Cloud sync, attachments, integrations, and automatic capture across LaterBox.',
    tax_category: 'saas',
  }));

const existingPrices = await findPrices(product.id);
const trialPeriod = { interval: 'day', frequency: 14 };

const monthly =
  existingPrices.find(
    (price) =>
      price.billing_cycle?.interval === 'month' &&
      price.billing_cycle?.frequency === 1 &&
      price.unit_price?.currency_code === 'USD' &&
      price.unit_price?.amount === '399',
  ) ||
  (await create('/prices', {
    product_id: product.id,
    description: 'LaterBox Pro monthly USD',
    unit_price: { amount: '399', currency_code: 'USD' },
    billing_cycle: { interval: 'month', frequency: 1 },
    trial_period: trialPeriod,
  }));

const yearly =
  existingPrices.find(
    (price) =>
      price.billing_cycle?.interval === 'year' &&
      price.billing_cycle?.frequency === 1 &&
      price.unit_price?.currency_code === 'USD' &&
      price.unit_price?.amount === '3999',
  ) ||
  (await create('/prices', {
    product_id: product.id,
    description: 'LaterBox Pro annual USD',
    unit_price: { amount: '3999', currency_code: 'USD' },
    billing_cycle: { interval: 'year', frequency: 1 },
    trial_period: trialPeriod,
  }));

const suffix = isProduction ? '_PROD' : '';
console.log(
  JSON.stringify(
    {
      environment,
      PADDLE_PRO_PRODUCT_ID: product.id,
      [`NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID${suffix}`]: monthly.id,
      [`NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID${suffix}`]: yearly.id,
    },
    null,
    2,
  ),
);
