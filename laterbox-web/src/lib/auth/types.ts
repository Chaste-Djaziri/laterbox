export interface AccountUser {
  id: string;
  email?: string;
  created_at?: string;
  last_sign_in_at?: string;
  user_metadata: { display_name?: string; name?: string; full_name?: string; [key: string]: unknown };
}
export interface AccountSession {
  access_token: string;
  expires_at?: number;
}
