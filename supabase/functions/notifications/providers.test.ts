import { assertEquals } from 'jsr:@std/assert@1';
import { validPushEndpoint } from './providers.ts';
Deno.test('Web Push only sends encrypted payloads to known HTTPS push services', () => {
  for (const endpoint of ['https://fcm.googleapis.com/fcm/send/token', 'https://updates.push.services.mozilla.com/wpush/v2/token', 'https://web.push.apple.com/token', 'https://wns2.notify.windows.com/w/?token=x']) assertEquals(validPushEndpoint(endpoint), true);
  for (const endpoint of ['http://fcm.googleapis.com/token', 'https://fcm.googleapis.com.evil.example/token', 'https://127.0.0.1/token', 'https://169.254.169.254/latest/meta-data', 'https://user:pass@fcm.googleapis.com/token', 'https://fcm.googleapis.com:8443/token', 'file:///etc/passwd']) assertEquals(validPushEndpoint(endpoint), false);
});
