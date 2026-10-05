#!/usr/bin/env node
const path = require('path');
const rootBumpScript = path.resolve(__dirname, '..', '..', 'scripts', 'bump_version.js');

// Delegate to root unified version bumper
if (process.env.LATERBOX_SKIP_VERSION_BUMP !== "1") {
  require(rootBumpScript);
}
