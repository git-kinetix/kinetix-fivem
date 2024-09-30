const fs = require('fs')

const version = process.env.TGT_RELEASE_VERSION
const newVersion = version.replace('v', '')

// Update kinetix_mod manifest
const modManifestFile = fs.readFileSync('kinetix_mod/fxmanifest.lua', {encoding: 'utf8'})
const newModFileContent = modManifestFile.replace(/\bversion\s+(.*)$/gm, `version      '${newVersion}'`)
fs.writeFileSync('kinetix_mod/fxmanifest.lua', newModFileContent)