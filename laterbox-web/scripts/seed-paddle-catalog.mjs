const apiKey = process.env.PADDLE_SANDBOX_API_KEY;
if (!apiKey) {
  throw new Error('Export PADDLE_SANDBOX_API_KEY before seeding the catalog.');
}

async function create(path, body) {
  const response = await fetch(`https://sandbox-api.paddle.com${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const payload = await response.json();
  if (!response.ok) throw new Error(payload?.error?.detail || `Paddle returned ${response.status}`);
  return payload.data;
}

const product = await create('/products', {
  name: 'LaterBox Pro',
  description: 'Cloud sync, attachments, integrations, and automatic capture across LaterBox.',
  tax_category: 'saas',
});

const trial_period = { interval: 'day', frequency: 14 };
const monthly = await create('/prices', {
  product_id: product.id,
  description: 'LaterBox Pro monthly USD',
  unit_price: { amount: '399', currency_code: 'USD' },
  billing_cycle: { interval: 'month', frequency: 1 },
  trial_period,
});
const yearly = await create('/prices', {
  product_id: product.id,
  description: 'LaterBox Pro annual USD',
  unit_price: { amount: '3999', currency_code: 'USD' },
  billing_cycle: { interval: 'year', frequency: 1 },
  trial_period,
});

console.log(JSON.stringify({
  PADDLE_PRO_PRODUCT_ID: product.id,
  NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID: monthly.id,
  NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID: yearly.id,
}, null, 2));
