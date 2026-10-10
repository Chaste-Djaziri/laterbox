export interface AccountUser {
  id: string;
  email?: string;
  user_metadata: Record<string, unknown>;
}
export interface AccountSession {
  access_token: string;
  expires_at?: number;
}
