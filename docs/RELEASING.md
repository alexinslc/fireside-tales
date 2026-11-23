# Releasing

Fireside Tales is released from a git tag. GitHub Actions checks the stories, builds the zip, uploads it to CurseForge, and makes a GitHub release.

## First-time setup

These need the project owner's CurseForge account:

1. Create the project at [authors.curseforge.com](https://authors.curseforge.com/#/projects/create/choose-game), using [curseforge-listing.md](curseforge-listing.md) and [art/logo.png](../art/logo.png).
2. Copy the project ID from the project page.
3. Create an API token at [authors-old.curseforge.com/account/api-tokens](https://authors-old.curseforge.com/account/api-tokens).
4. In the GitHub repository's **Settings > Secrets and variables > Actions**, add:
   - A **secret** named `CF_API_TOKEN`, holding the token.
   - A **variable** named `CF_PROJECT_ID`, holding the project ID.

## Each release

1. Set `## Version` in `addon/FiresideTales/FiresideTales.toc`.
2. Add a `## <version>` section to `CHANGELOG.md`. Its text becomes the release notes.
3. Run `node tools/i18n/build.mjs`, and translate any new or changed stories and interface text (see `docs/translation-guide.md`); untranslated stories ship in English.
4. Run `node tools/build-whatsnew.mjs`. It writes `addon/FiresideTales/WhatsNew.lua` from that section, which the What's New window shows once to each player after they update (and `/tales news` opens again).
5. Commit and push to `main`, and check that the Release workflow passes.
6. Tag and push:

   ```bash
   git tag v1.0.0
   ```

   ```bash
   git push origin v1.0.0
   ```

The tag has to match the TOC's version, the changelog needs a section for it, and `WhatsNew.lua` has to match that section, or the release stops before uploading anything. CurseForge reviews a new project's first file before it goes live.

## Community stories

`.github/workflows/community.yml` keeps `Community.lua` up to date with the stories approved on firesidetales.dev and releases a patch version on its own each Monday evening (UTC) when they changed. It writes `WhatsNew.lua` too, so What's New says "New community stories are now available." See "From approval to the addon" in `site/README.md`. A release by hand picks up whatever `Community.lua` has at the time.

The same job translates the new community stories into every language with `tools/i18n/translate-community.mjs`, which needs the `ANTHROPIC_API_KEY` repository secret. Without it, or if a language fails, that week's community stories stay in English there.

## When the client updates

Change `## Interface` in the TOC and `GAME_VERSION` in `.github/workflows/release.yml`. `GAME_VERSION` is CurseForge's name for the client version, such as `1.60.1`.
