import net from "node:net";

const DATABASE_URL =
  process.env.DATABASE_URL ??
  "postgresql://supplybiz:supplybiz@localhost:5432/supplybiz";
const REDIS_URL = process.env.REDIS_URL ?? "redis://localhost:6379";
const STORAGE_ENDPOINT = process.env.STORAGE_ENDPOINT ?? "http://localhost:9000";
const CHECK_TIMEOUT_MS = Number(process.env.INFRA_CHECK_TIMEOUT_MS ?? 5000);

function normalizePort(rawPort, defaultPort) {
  if (!rawPort) return defaultPort;
  const parsed = Number(rawPort);
  if (!Number.isInteger(parsed) || parsed <= 0 || parsed > 65535) {
    throw new Error(`Invalid port: ${rawPort}`);
  }
  return parsed;
}

function parseHostAndPort(urlString, defaultProtocol, defaultPort) {
  const withProtocol = /^[a-zA-Z]+:\/\//.test(urlString)
    ? urlString
    : `${defaultProtocol}://${urlString}`;
  const parsed = new URL(withProtocol);
  const host = parsed.hostname;
  const port = normalizePort(parsed.port, defaultPort);

  if (!host) {
    throw new Error(`Unable to determine host from ${urlString}`);
  }

  return { host, port, protocol: parsed.protocol, origin: parsed.origin };
}

async function assertTcpReachable(name, host, port, timeoutMs) {
  await new Promise((resolve, reject) => {
    const socket = new net.Socket();
    const timeout = setTimeout(() => {
      socket.destroy();
      reject(new Error(`${name} timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    socket.once("error", (error) => {
      clearTimeout(timeout);
      const details = [error.code, error.message].filter(Boolean).join(" ");
      reject(
        new Error(
          `${name} TCP check failed (${host}:${port})${details ? `: ${details}` : ""}`
        )
      );
    });

    socket.connect(port, host, () => {
      clearTimeout(timeout);
      socket.end();
      resolve();
    });
  });
}

async function assertMinioHealthy(endpoint, timeoutMs) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${endpoint}/minio/health/live`, {
      method: "GET",
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new Error(`MinIO health endpoint returned HTTP ${response.status}`);
    }
  } finally {
    clearTimeout(timeout);
  }
}

async function main() {
  const pg = parseHostAndPort(DATABASE_URL, "postgresql", 5432);
  const redis = parseHostAndPort(REDIS_URL, "redis", 6379);
  const storage = parseHostAndPort(STORAGE_ENDPOINT, "http", 9000);

  console.log("Checking local infra connectivity from API workspace...");
  await assertTcpReachable("Postgres", pg.host, pg.port, CHECK_TIMEOUT_MS);
  console.log(`✓ Postgres reachable at ${pg.host}:${pg.port}`);

  await assertTcpReachable("Redis", redis.host, redis.port, CHECK_TIMEOUT_MS);
  console.log(`✓ Redis reachable at ${redis.host}:${redis.port}`);

  await assertTcpReachable("MinIO", storage.host, storage.port, CHECK_TIMEOUT_MS);
  await assertMinioHealthy(storage.origin, CHECK_TIMEOUT_MS);
  console.log(`✓ MinIO reachable and healthy at ${storage.origin}`);
  console.log("All local infra checks passed.");
}

main().catch((error) => {
  console.error(`Infra connectivity check failed: ${error.message}`);
  process.exit(1);
});
