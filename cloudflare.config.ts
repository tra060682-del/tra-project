import { bindings, defineConfig, defineWorker } from "cf/config";

const workerName = (mode: string | undefined) =>
  mode === "production" ? "tra-project" : `tra-project-${mode || "development"}`;

export default defineConfig(({ mode }) => ({
  accountId: process.env.CLOUDFLARE_ACCOUNT_ID,
  worker: defineWorker({
    name: workerName(mode),
    entrypoint: "vinext/server/fetch-handler",
    compatibilityDate: "2026-11-11",
    assets: {
      htmlHandling: "none",
      notFoundHandling: "none",
      runWorkerFirst: ["/*", "!/_next/static/*", "!/*/_next/static/*"],
    },
    env: {
      ASSETS: bindings.assets(),
    },
  }),
}));
