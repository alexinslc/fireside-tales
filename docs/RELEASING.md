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
3. Commit and push to `main`, and check that the Release workflow passes.
4. Tag and push:

   ```bash
   git tag v1.0.0
   ```

   ```bash
   git push origin v1.0.0
   ```

The tag has to match the TOC's version, and the changelog needs a section for it, or the release stops before uploading anything. CurseForge reviews a new project's first file before it goes live.

## When the client updates

Change `## Interface` in the TOC and `GAME_VERSION` in `.github/workflows/release.yml`. `GAME_VERSION` is CurseForge's name for the client version, such as `1.60.1`.
