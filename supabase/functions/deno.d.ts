/// <reference no-default-lib="true"/>
/// <reference lib="esnext" />
/// <reference lib="dom" />
/// <reference lib="dom.iterable" />

declare module "npm:*" {
  const content: any;
  export default content;
  export = content;
}

declare module "jsr:*" {
  export const assert: any;
  export const assertEquals: any;
  export const assertRejects: any;
  export const assertMatch: any;
  const content: any;
  export default content;
}

interface ImportMeta {
  main?: boolean;
  url?: string;
}

declare namespace Deno {
  export interface ServeOptions {
    port?: number;
    hostname?: string;
    signal?: AbortSignal;
    onListen?: (params: { hostname: string; port: number }) => void;
    onError?: (error: unknown) => Response | Promise<Response>;
  }

  export interface TestDefinition {
    name: string;
    fn: () => void | Promise<void>;
    sanitizeOps?: boolean;
    sanitizeResources?: boolean;
    sanitizeExit?: boolean;
  }

  export function serve(
    handler: (request: Request) => Response | Promise<Response>,
  ): void;
  export function serve(
    options: ServeOptions,
    handler: (request: Request) => Response | Promise<Response>,
  ): void;

  export namespace env {
    export function get(key: string): string | undefined;
    export function set(key: string, value: string): void;
    export function has(key: string): boolean;
    export function delete_(key: string): void;
    export function toObject(): Record<string, string>;
  }

  export function test(name: string, fn: () => void | Promise<void>): void;
  export function test(def: TestDefinition): void;
  export function test(name: string, options: Record<string, any>, fn: () => void | Promise<void>): void;

  export interface ConnectOptions {
    hostname?: string;
    port: number;
    transport?: "tcp";
  }

  export interface Conn {
    close(): void;
    readonly localAddr: any;
    readonly remoteAddr: any;
  }

  export function connect(options: ConnectOptions): Promise<Conn>;
  export function resolveDns(
    query: string,
    recordType: "A" | "AAAA" | "CAA" | "CNAME" | "MX" | "NS" | "PTR" | "SOA" | "SRV" | "TXT",
    options?: { nameServer?: { ipAddr: string; port?: number } },
  ): Promise<string[]>;
}
