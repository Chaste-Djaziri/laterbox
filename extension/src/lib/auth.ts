import { getAccessToken, setAccessToken } from "./storage";

export { getAccessToken };

export async function connectWithAccessToken(token: string): Promise<void> {
  await setAccessToken(token);
}
