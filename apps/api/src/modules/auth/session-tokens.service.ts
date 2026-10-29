import { Injectable, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  createPrivateKey, createPublicKey, generateKeyPairSync, KeyObject, sign, verify,
} from "node:crypto";

export interface AccessClaims {
  sub: string;
  sid: string;
  roles: string[];
  aud: "mobile";
  iat: number;
  exp: number;
}

export function unauthenticated(code = "UNAUTHENTICATED"): UnauthorizedException {
  return new UnauthorizedException({ code, detail: "Session is invalid or expired." });
}

@Injectable()
export class SessionTokensService {
  private readonly privateKey: KeyObject;
  private readonly keys: Map<string, KeyObject>;
  private readonly kid: string;

  constructor(config: ConfigService) {
    const pem = config.get<string>("AUTH_SIGNING_PRIVATE_KEY");
    if (!pem && !["development", "test"].includes(config.get<string>("NODE_ENV", "development"))) {
      throw new Error("AUTH_SIGNING_PRIVATE_KEY is required outside development/test.");
    }
    this.privateKey = pem ? createPrivateKey(pem) : generateKeyPairSync("ed25519").privateKey;
    if (this.privateKey.asymmetricKeyType !== "ed25519") {
      throw new Error("AUTH_SIGNING_PRIVATE_KEY must be Ed25519.");
    }
    this.kid = config.get<string>("AUTH_SIGNING_KEY_ID", "development");
    this.keys = new Map([[this.kid, createPublicKey(this.privateKey)]]);
    // Retain public keys for still-valid access tokens during key rotation.
    const previous = config.get<Record<string, string>>("AUTH_PREVIOUS_PUBLIC_KEYS", {});
    for (const [kid, key] of Object.entries(previous)) {
      if (kid !== this.kid) this.keys.set(kid, createPublicKey(key));
    }
  }

  issue(sub: string, sid: string, roles: string[]): string {
    const iat = Math.floor(Date.now() / 1000);
    const header = Buffer.from(JSON.stringify({ alg: "EdDSA", typ: "JWT", kid: this.kid })).toString("base64url");
    const payload = Buffer.from(JSON.stringify({ sub, sid, roles, aud: "mobile", iat, exp: iat + 900 })).toString("base64url");
    const input = `${header}.${payload}`;
    return `${input}.${sign(null, Buffer.from(input), this.privateKey).toString("base64url")}`;
  }

  read(token: string): AccessClaims {
    try {
      const parts = token.split(".");
      if (parts.length !== 3 || token.length > 8192) throw unauthenticated();
      const [header, payload, signature] = parts;
      const meta = JSON.parse(Buffer.from(header, "base64url").toString()) as Record<string, unknown>;
      const key = typeof meta.kid === "string" ? this.keys.get(meta.kid) : undefined;
      if (meta.alg !== "EdDSA" || meta.typ !== "JWT" || !key ||
          !verify(null, Buffer.from(`${header}.${payload}`), key, Buffer.from(signature, "base64url"))) {
        throw unauthenticated();
      }
      const claims = JSON.parse(Buffer.from(payload, "base64url").toString()) as AccessClaims;
      const now = Math.floor(Date.now() / 1000);
      if (claims.aud !== "mobile" || typeof claims.sub !== "string" || typeof claims.sid !== "string" ||
          !Array.isArray(claims.roles) || !claims.roles.every(role => ["CUSTOMER", "VENDOR"].includes(role)) ||
          !Number.isInteger(claims.exp) || !Number.isInteger(claims.iat) || claims.exp <= now ||
          claims.iat > now || claims.exp - claims.iat !== 900 ||
          !/^[0-9a-f-]{36}$/.test(claims.sub) || !/^[0-9a-f-]{36}$/.test(claims.sid)) throw unauthenticated();
      return claims;
    } catch {
      throw unauthenticated();
    }
  }

  jwks(): { keys: object[] } {
    return { keys: [...this.keys].map(([kid, key]) => ({ ...key.export({ format: "jwk" }), kid, alg: "EdDSA", use: "sig" })) };
  }
}
