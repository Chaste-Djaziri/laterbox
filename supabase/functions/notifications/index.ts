import { createClient } from 'npm:@supabase/supabase-js@2.112.0';
import { DeliveryError, sendDelivery, type Delivery } from './providers.ts';

Deno.serve(async (request) => {
  const secret = Deno.env.get('NOTIFICATION_DISPATCH_SECRET');
  if (!secret || request.headers.get('authorization') !== `Bearer ${secret}`) return new Response('Unauthorized', { status: 401 });
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data, error } = await db.rpc('claim_notification_deliveries');
  if (error) return Response.json({ error: 'Unable to claim notifications' }, { status: 500 });
  let sent = 0; let failed = 0;
  // Small bounded batches keep provider connections and worker duration predictable.
  const rows = (data || []) as Delivery[];
  for (let i = 0; i < rows.length; i += 10) {
    await Promise.all(rows.slice(i, i + 10).map(async (delivery) => {
      try {
        const check = await db.rpc('notification_delivery_is_current', {
          p_event: delivery.event_id, p_installation: delivery.installation_id, p_lease: delivery.lease_id,
        });
        if (check.error) throw check.error;
        if (!check.data) {
          await db.from('notification_deliveries').update({ state: 'discarded' })
            .eq('event_id', delivery.event_id).eq('installation_id', delivery.installation_id).eq('lease_id', delivery.lease_id);
          return;
        }
        await sendDelivery(delivery);
        const result = await db.from('notification_deliveries').update({ state: 'sent', last_error: null })
          .eq('event_id', delivery.event_id).eq('installation_id', delivery.installation_id).eq('lease_id', delivery.lease_id);
        if (result.error) throw result.error;
        sent++;
      } catch (error) {
        failed++;
        const expired = error instanceof DeliveryError && error.expired;
        if (expired) {
          let disable = db.from('notification_installations').update({ enabled: false, token: null, subscription: null }).eq('id', delivery.installation_id);
          // A response for an old token must not disable a newly rotated token.
          disable = delivery.transport === 'web'
            ? disable.eq('subscription->>endpoint', delivery.subscription?.endpoint || '')
            : disable.eq('token', delivery.token || '');
          await disable;
        }
        await db.from('notification_deliveries').update({ state: expired || delivery.attempts >= 8 ? 'discarded' : 'pending',
          retry_at: new Date(Date.now() + Math.min(3600, 2 ** delivery.attempts * 15) * 1000).toISOString(),
          // Do not log tokens, payloads, subscriptions or provider response bodies.
          last_error: error instanceof DeliveryError ? error.message : 'Delivery configuration or network failure',
        }).eq('event_id', delivery.event_id).eq('installation_id', delivery.installation_id).eq('lease_id', delivery.lease_id);
      }
    }));
  }
  return Response.json({ sent, failed });
});
