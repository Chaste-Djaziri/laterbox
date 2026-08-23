#!/usr/bin/env node
const path = require('path');
const rootBumpScript = path.resolve(__dirname, '..', '..', 'scripts', 'bump_version.js');

// Delegate to root unified version bumper
require(rootBumpScript);
