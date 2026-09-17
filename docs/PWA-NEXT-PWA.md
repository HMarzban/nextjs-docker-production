# PWA implementation and manual checks

The plugin configuration lives in `next.config.mjs`; the generated worker is
`public/sw.js`. Public icons and the manifest originate in `src/public`.
`UpdatePrompt`, `InstallPWA` and `OfflineIndicator` provide the UI.

Build the production bundle or Docker stack, then use a browser on localhost or
HTTPS. Visit the homepage and weather page online, inspect Application → Service
Workers/Cache Storage, then go offline and revisit a previously loaded page.
Check the offline fallback, installation and the update prompt after another build.

Caching configuration describes intended behavior; CI currently checks the build
and HTTP routes, not browser installation, cache matching or offline interactions.
The live weather provider cannot return fresh data offline. Validate these flows
before making product-level offline guarantees.
