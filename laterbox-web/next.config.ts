import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    resolveAlias: {
      'node-fetch': './src/lib/billing/apple-fetch.cjs',
    },
  },
};

export default function config(phase: string): NextConfig {
  if (phase === 'phase-production-build' && process.env.NEXT_PUBLIC_PADDLE_ENV === 'production') {
    const defaultMonthlyPrice = 'pri_01m2g0r3xap0j8rdr8ewbk7wzj';
    const defaultYearlyPrice = 'pri_01m2g0r48pvc4krq97kx0dyer0';

    process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD =
      process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD ||
      process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN;

    process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD =
      process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD ||
      process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID ||
      defaultMonthlyPrice;

    process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD =
      process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD ||
      process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID ||
      defaultYearlyPrice;

    const required = {
      NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD: process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD,
      NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD: process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD,
      NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD: process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD,
    };
    const missing = Object.entries(required).filter(([, value]) => !value?.trim()).map(([name]) => name);
    if (missing.length) throw new Error(`Missing production Paddle build configuration: ${missing.join(', ')}`);
    if (!required.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD!.startsWith('live_')) {
      throw new Error('Production Paddle checkout requires a live_ client-side token.');
    }
  }
  return nextConfig;
}

// Enable calling `getCloudflareContext()` in `next dev`.
// See https://opennext.js.org/cloudflare/bindings#local-access-to-bindings.
import { initOpenNextCloudflareForDev } from "@opennextjs/cloudflare";
initOpenNextCloudflareForDev();
