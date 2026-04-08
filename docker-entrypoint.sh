#!/bin/sh
set -eu

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/openclaw.json"

mkdir -p "${CONFIG_DIR}"

# Seed the bundled lossless-claw plugin into the user's config on first boot
# without overwriting any explicit plugin settings they already have.
node - "${CONFIG_FILE}" <<'NODE'
const fs = require("fs");

const configPath = process.argv[2];
let config = {};

if (fs.existsSync(configPath)) {
  const raw = fs.readFileSync(configPath, "utf8");
  config = JSON.parse(raw);
}

const plugins = config.plugins ?? (config.plugins = {});
const entries = plugins.entries ?? (plugins.entries = {});

if (!Object.prototype.hasOwnProperty.call(entries, "lossless-claw")) {
  entries["lossless-claw"] = { enabled: true, config: {} };
  fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
}
NODE

exec "$@"
