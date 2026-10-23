import { NodeSDK } from "@opentelemetry/sdk-node";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";

let sdk: NodeSDK | null = null;

export async function initOpenTelemetry(enabled: boolean): Promise<void> {
  if (!enabled || sdk) {
    return;
  }

  sdk = new NodeSDK({
    instrumentations: [getNodeAutoInstrumentations()],
  });

  await sdk.start();
}

export async function shutdownOpenTelemetry(): Promise<void> {
  if (!sdk) {
    return;
  }
  await sdk.shutdown();
  sdk = null;
}
