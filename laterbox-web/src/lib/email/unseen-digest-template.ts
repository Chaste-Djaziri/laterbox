import { UnseenDigestEmailOptions, UnseenDigestItem } from './types';

export function escapeHtml(str: string | null | undefined): string {
  if (!str) return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export function formatDaysWaiting(createdAt: string, now: Date = new Date()): string {
  try {
    const created = new Date(createdAt);
    const diffMs = Math.max(0, now.getTime() - created.getTime());
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays <= 0) return 'Saved today';
    if (diffDays === 1) return 'Waiting 1 day';
    if (diffDays < 7) return `Waiting ${diffDays} days`;
    if (diffDays < 14) return 'Waiting 1 week';
    const weeks = Math.floor(diffDays / 7);
    if (weeks < 5) return `Waiting ${weeks} weeks`;
    const months = Math.floor(diffDays / 30);
    return months <= 1 ? 'Waiting 1 month' : `Waiting ${months} months`;
  } catch {
    return 'Waiting for review';
  }
}

export function getItemBadge(item: UnseenDigestItem): { label: string; domain?: string } {
  let domain = item.metadata?.domain || '';
  if (!domain && item.url) {
    try {
      domain = new URL(item.url).hostname.replace(/^www\./, '');
    } catch {
      domain = '';
    }
  }

  const rawType = (item.metadata?.content_type || item.type || '').toLowerCase();
  let label = 'LINK';
  if (rawType.includes('video') || (item.url && item.url.includes('youtube.com'))) {
    label = 'VIDEO';
  } else if (rawType.includes('article')) {
    label = 'ARTICLE';
  } else if (rawType.includes('music') || (item.url && item.url.includes('spotify.com'))) {
    label = 'AUDIO';
  } else if (rawType.includes('note') || (!item.url && item.text_content)) {
    label = 'NOTE';
  } else if (rawType.includes('doc') || rawType.includes('document')) {
    label = 'DOC';
  }

  return { label, domain: domain ? domain : undefined };
}

export function getItemDisplayTitle(item: UnseenDigestItem): string {
  const title = item.metadata?.title || item.title;
  if (title && title.trim().length > 0) return title.trim();

  if (item.url) {
    try {
      const url = new URL(item.url);
      const path = url.pathname.replace(/\/$/, '');
      return `${url.hostname}${path ? path.slice(0, 40) : ''}`;
    } catch {
      return item.url;
    }
  }

  if (item.text_content) {
    const snippet = item.text_content.trim().slice(0, 60);
    return snippet.length >= 60 ? `${snippet}…` : snippet;
  }

  return 'Saved Item';
}

export function getItemSnippet(item: UnseenDigestItem): string {
  const desc = item.metadata?.description || item.note?.content || item.text_content;
  if (!desc) return '';
  const cleaned = desc.replace(/\s+/g, ' ').trim();
  return cleaned.length > 140 ? `${cleaned.slice(0, 140)}…` : cleaned;
}

export function renderUnseenDigestHtml(options: UnseenDigestEmailOptions): string {
  const appBaseUrl = (options.appBaseUrl || process.env.NEXT_PUBLIC_APP_ORIGIN || 'https://app.laterbox.dev').replace(/\/$/, '');
  const customScheme = (options.customScheme || 'laterbox://').replace(/\/$/, '') + '/';
  const logoUrl = 'https://laterbox.dev/branding/laterbox-logo.png';
  const itemCount = options.items.length;
  const totalCount = options.totalUnseenCount || itemCount;
  const greeting = options.recipientName ? `Hi ${escapeHtml(options.recipientName)},` : 'Hello,';
  const subject = options.subject || `${itemCount} unseen ${itemCount === 1 ? 'item is' : 'items are'} waiting in your LaterBox inbox`;

  const webInboxUrl = `${appBaseUrl}/inbox`;
  const appInboxUrl = `${customScheme}inbox`;

  const itemRowsHtml = options.items.map((item) => {
    const title = escapeHtml(getItemDisplayTitle(item));
    const snippet = escapeHtml(getItemSnippet(item));
    const badge = getItemBadge(item);
    const waitingTime = escapeHtml(formatDaysWaiting(item.created_at));

    const webItemUrl = `${appBaseUrl}/item/${encodeURIComponent(item.id)}`;
    const webRescheduleUrl = `${appBaseUrl}/item/${encodeURIComponent(item.id)}?action=reschedule`;
    const appItemUrl = `${customScheme}item/${encodeURIComponent(item.id)}`;
    const appRescheduleUrl = `${customScheme}item/${encodeURIComponent(item.id)}?action=reschedule`;

    const badgeText = badge.domain ? `${badge.label} · ${escapeHtml(badge.domain)}` : badge.label;

    return `
      <tr>
        <td style="padding: 0 0 16px;">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%; border-collapse:separate; background-color:#faf9f5; border:1px solid #eeece5; border-radius:16px;">
            <tr>
              <td style="padding: 18px 20px;">
                <!-- Item category and age badge -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 8px;">
                  <tr>
                    <td align="left" style="vertical-align: middle;">
                      <span style="display:inline-block; font-size:11px; font-weight:700; letter-spacing:0.8px; color:#6b6a62; text-transform:uppercase;">
                        ${badgeText}
                      </span>
                    </td>
                    <td align="right" style="vertical-align: middle;">
                      <span style="display:inline-block; background-color:#fef3c7; color:#92400e; font-size:11px; font-weight:600; padding:3px 8px; border-radius:9999px;">
                        ${waitingTime}
                      </span>
                    </td>
                  </tr>
                </table>

                <!-- Title -->
                <h3 style="margin: 0 0 6px; font-size: 16px; font-weight: 700; line-height: 22px;">
                  <a href="${webItemUrl}" target="_blank" style="color: #171711; text-decoration: none;">
                    ${title}
                  </a>
                </h3>

                <!-- Excerpt if present -->
                ${snippet ? `<p style="margin: 0 0 14px; font-size: 13px; line-height: 20px; color: #66655e;">${snippet}</p>` : `<div style="height: 10px;"></div>`}

                <!-- Action buttons -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0">
                  <tr>
                    <!-- Review Web / Universal -->
                    <td style="padding-right: 8px;">
                      <a href="${webItemUrl}" target="_blank" style="display: inline-block; background-color: #171711; color: #ffffff; font-size: 13px; font-weight: 600; text-decoration: none; padding: 7px 14px; border-radius: 8px;">
                        Review Item
                      </a>
                    </td>
                    <!-- Reschedule -->
                    <td style="padding-right: 8px;">
                      <a href="${webRescheduleUrl}" target="_blank" style="display: inline-block; background-color: #eeece5; color: #3a3935; font-size: 13px; font-weight: 600; text-decoration: none; padding: 7px 14px; border-radius: 8px;">
                        Reschedule
                      </a>
                    </td>
                    <!-- Mobile app deep link -->
                    <td>
                      <a href="${appItemUrl}" style="display: inline-block; font-size: 12px; color: #85837b; text-decoration: underline; padding: 7px 4px;">
                        Open in App
                      </a>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    `;
  }).join('');

  return `<!doctype html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="x-apple-disable-message-reformatting" />
    <meta name="format-detection" content="telephone=no,date=no,address=no,email=no,url=no" />
    <meta name="color-scheme" content="light" />
    <meta name="supported-color-schemes" content="light" />
    <title>${escapeHtml(subject)}</title>
  </head>
  <body style="margin:0; padding:0; background-color:#f4f2ea; color:#171711; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; -webkit-font-smoothing:antialiased;">
    <!-- Preheader for email clients -->
    <div style="display:none; max-height:0; overflow:hidden; mso-hide:all; opacity:0; color:transparent;">
      ${totalCount} unseen items waiting in your inbox. Review them or reschedule for later.
    </div>
    <div style="display:none; max-height:0; overflow:hidden; mso-hide:all;">&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;</div>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%; border-collapse:collapse; background-color:#f4f2ea;">
      <tr>
        <td align="center" style="padding:36px 16px;">
          <!-- Main Card Container -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%; max-width:580px; border-collapse:separate; background-color:#ffffff; border:1px solid #dedbcf; border-radius:24px; box-shadow:0 4px 20px rgba(0,0,0,0.03);">
            
            <!-- Logo Header -->
            <tr>
              <td style="padding:32px 36px 20px; border-bottom:1px solid #eeece5;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                  <tr>
                    <td align="left" style="vertical-align:middle;">
                      <a href="${appBaseUrl}" target="_blank" style="display:inline-block; text-decoration:none;">
                        <img src="${logoUrl}" width="160" alt="LaterBox" border="0" style="display:block; width:160px; max-width:100%; height:auto; border:0; outline:none; text-decoration:none;" />
                      </a>
                    </td>
                    <td align="right" style="vertical-align:middle;">
                      <span style="display:inline-block; background-color:#171711; color:#d7ff27; font-size:11px; font-weight:700; letter-spacing:0.5px; padding:4px 10px; border-radius:9999px; text-transform:uppercase;">
                        Inbox Digest
                      </span>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

            <!-- Body Content -->
            <tr>
              <td style="padding:32px 36px 36px;">
                <p style="margin:0 0 10px; color:#85837b; font-size:12px; font-weight:700; letter-spacing:1px; text-transform:uppercase;">
                  ATTENTION NEEDED
                </p>
                <h1 style="margin:0 0 14px; color:#171711; font-size:26px; font-weight:800; letter-spacing:-0.6px; line-height:34px;">
                  Catch up on what you saved
                </h1>
                <p style="margin:0 0 24px; color:#66655e; font-size:15px; line-height:24px;">
                  ${greeting} You have <strong style="color:#171711;">${totalCount} ${totalCount === 1 ? 'item' : 'items'}</strong> waiting in your LaterBox inbox that ${totalCount === 1 ? 'has' : 'have'} been sitting unseen for a while. Take a quick moment to review ${totalCount === 1 ? 'it' : 'them'}, or reschedule for later so your inbox stays clean.
                </p>

                <!-- Items List -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 24px;">
                  ${itemRowsHtml}
                </table>

                ${totalCount > itemCount ? `
                  <p style="margin:0 0 24px; text-align:center; color:#85837b; font-size:13px; line-height:20px;">
                    <em>+ ${totalCount - itemCount} more unseen items waiting in your inbox</em>
                  </p>
                ` : ''}

                <!-- Primary Global CTA -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-bottom: 24px;">
                  <tr>
                    <td align="center">
                      <a href="${webInboxUrl}" target="_blank" style="display:block; text-align:center; background-color:#171711; color:#ffffff; font-size:15px; font-weight:700; text-decoration:none; padding:14px 28px; border-radius:12px; letter-spacing:-0.2px;">
                        Open Your Inbox →
                      </a>
                    </td>
                  </tr>
                </table>

                <!-- Mobile / Cross-Platform Quick Switch Banner -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:separate; background-color:#f4f2ea; border:1px solid #e5e2d6; border-radius:14px;">
                  <tr>
                    <td style="padding:16px 20px;">
                      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                        <tr>
                          <td style="vertical-align:top; padding-right:12px;">
                            <span style="font-size:20px;">📱</span>
                          </td>
                          <td style="vertical-align:middle;">
                            <p style="margin:0 0 6px; font-size:13px; font-weight:700; color:#171711;">
                              On iPhone, iPad or mobile?
                            </p>
                            <p style="margin:0 0 10px; font-size:12px; line-height:18px; color:#66655e;">
                              Launch directly into the LaterBox native app or keep reading in your mobile browser:
                            </p>
                            <table role="presentation" cellspacing="0" cellpadding="0" border="0">
                              <tr>
                                <td style="padding-right: 8px;">
                                  <a href="${appInboxUrl}" style="display:inline-block; background-color:#171711; color:#d7ff27; font-size:12px; font-weight:700; text-decoration:none; padding:6px 12px; border-radius:6px;">
                                    Open Mobile App
                                  </a>
                                </td>
                                <td>
                                  <a href="${webInboxUrl}" target="_blank" style="display:inline-block; background-color:#ffffff; color:#171711; border:1px solid #dedbcf; font-size:12px; font-weight:600; text-decoration:none; padding:5px 12px; border-radius:6px;">
                                    Open Web Inbox
                                  </a>
                                </td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>

              </td>
            </tr>
          </table>

          <!-- Footer -->
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:580px; margin-top:24px;">
            <tr>
              <td align="center" style="color:#85837b; font-size:12px; line-height:18px;">
                <p style="margin:0 0 8px; font-weight:600; color:#6b6a62;">
                  LaterBox · Put it here. Find it later.
                </p>
                <p style="margin:0;">
                  <a href="${appBaseUrl}/settings" style="color:#85837b; text-decoration:underline;">Notification Settings</a>
                  &nbsp;·&nbsp;
                  <a href="${appBaseUrl}/help" style="color:#85837b; text-decoration:underline;">Help &amp; Support</a>
                </p>
              </td>
            </tr>
          </table>

        </td>
      </tr>
    </table>
  </body>
</html>`;
}

export function renderUnseenDigestText(options: UnseenDigestEmailOptions): string {
  const appBaseUrl = (options.appBaseUrl || process.env.NEXT_PUBLIC_APP_ORIGIN || 'https://app.laterbox.dev').replace(/\/$/, '');
  const customScheme = (options.customScheme || 'laterbox://').replace(/\/$/, '') + '/';
  const itemCount = options.items.length;
  const totalCount = options.totalUnseenCount || itemCount;
  const greeting = options.recipientName ? `Hi ${options.recipientName},` : 'Hello,';

  let text = `LATERBOX - UNSEEN INBOX DIGEST\n`;
  text += `================================\n\n`;
  text += `${greeting}\n\n`;
  text += `You have ${totalCount} ${totalCount === 1 ? 'item' : 'items'} in your LaterBox inbox that ${totalCount === 1 ? 'has' : 'have'} been sitting unseen for a while.\n`;
  text += `Take a moment to review them or reschedule them for later so your inbox stays clean.\n\n`;
  text += `--------------------------------\n\n`;

  options.items.forEach((item, index) => {
    const title = getItemDisplayTitle(item);
    const snippet = getItemSnippet(item);
    const badge = getItemBadge(item);
    const waiting = formatDaysWaiting(item.created_at);
    const webItemUrl = `${appBaseUrl}/item/${item.id}`;
    const webRescheduleUrl = `${appBaseUrl}/item/${item.id}?action=reschedule`;
    const appItemUrl = `${customScheme}item/${item.id}`;

    text += `${index + 1}. ${title}\n`;
    text += `   [${badge.domain ? `${badge.label} • ${badge.domain}` : badge.label}] (${waiting})\n`;
    if (snippet) {
      text += `   ${snippet}\n`;
    }
    text += `   • Review on Web: ${webItemUrl}\n`;
    text += `   • Reschedule:    ${webRescheduleUrl}\n`;
    text += `   • Open in App:   ${appItemUrl}\n\n`;
  });

  if (totalCount > itemCount) {
    text += `+ ${totalCount - itemCount} more unseen items waiting in your inbox.\n\n`;
  }

  text += `--------------------------------\n`;
  text += `Open your entire inbox on web: ${appBaseUrl}/inbox\n`;
  text += `Open in LaterBox mobile app:    ${customScheme}inbox\n\n`;
  text += `LaterBox · Put it here. Find it later.\n`;
  text += `Manage notifications: ${appBaseUrl}/settings\n`;

  return text;
}
