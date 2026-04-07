#!/bin/sh
set -eu

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/openclaw.json"

mkdir -p "${CONFIG_DIR}"

# Seed bundled stock plugins into the user's config on first boot without
# overwriting any explicit plugin settings they already have.
node - "${CONFIG_FILE}" <<'NODE'
const fs = require("fs");

const configPath = process.argv[2];
let config = {};

if (fs.existsSync(configPath)) {
  const raw = fs.readFileSync(configPath, "utf8");
  config = JSON.parse(raw);
}

let changed = false;

const gateway = config.gateway ?? (config.gateway = {});
if (gateway.mode == null) {
  gateway.mode = "local";
  changed = true;
}

const plugins = config.plugins ?? (config.plugins = {});
const entries = plugins.entries ?? (plugins.entries = {});

if (!Object.prototype.hasOwnProperty.call(entries, "lossless-claw")) {
  entries["lossless-claw"] = { enabled: true, config: {} };
  changed = true;
}

if (!Object.prototype.hasOwnProperty.call(entries, "camofox-browser")) {
  entries["camofox-browser"] = { enabled: true, config: {} };
  changed = true;
}

if (changed) {
  fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
}
NODE

exec "$@"
