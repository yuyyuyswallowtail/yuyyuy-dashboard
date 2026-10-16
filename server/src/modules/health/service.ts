import { type HealthResponse, healthResponse } from "./schema";

export function getHealth(): HealthResponse {
  return healthResponse.parse({ status: "ok" });
}
