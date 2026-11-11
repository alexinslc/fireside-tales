# firesidetales.dev

The community site for Fireside Tales: players contribute stories and rumors, and reviewers (on the review page, or a script through the API) approve them into a week. Each week's approved stories (50 to 100 is the aim) go into the addon's Community tab.

One Cloudflare Worker does it all:

- `src/`: the pages, a React app built with Vite and [shadcn/ui](https://ui.shadcn.com) components (`src/components/ui`, themed in `src/index.css`). Pages: this week, past weeks (and a page for each), contribute a story, check on yours, guidelines, feedback, and the review page at `/admin`. Only past weeks offer "Copy for the game"; this week's stories are already in the addon.
- `shared/rules.js`: the story rules, shared by the pages and the server. They match the addon's own checks, so keep them in step with `Import.lua` and `tools/check-stories.ps1`.
- `worker/`: the API. `guidelines.ts` is what reviewers check for (scripts get it from `GET /api/admin`), `posts.ts` handles week posts, and `notify.ts` sends emails.
- `migrations/`: the D1 database tables.

Nothing is published until a reviewer approves it. Writers may skip the mood and never choose story or rumor, so reviewers set both when approving; a story can't be approved without a mood.

## Security

The code is public, so nothing secret lives in it: keys, emails, and token IDs are Cloudflare secrets, and `.dev.vars` is gitignored.

- **The review page and its API** sit behind Cloudflare Access, and the worker checks Access's signed token again on every `/api/admin` request (signature, audience, issuer, expiry, and the `ADMIN_EMAILS` or `REVIEW_TOKENS` lists). Without those settings, the admin API refuses everyone.
- **`DEV_ADMIN=1`** (local sign-in bypass), the skipped bot check, and the fallback address salt only work on `localhost`. On the live site they do nothing, even if set by mistake.
- **Changes to reviewer data** must be JSON and can't come from another site: a browser's `Origin` must be this site's, so a page elsewhere can't use a signed-in reviewer's browser.
- **Every response** carries strict headers: no framing (`frame-ancestors 'none'`), a content security policy allowing only this site's scripts and the Turnstile check, `nosniff`, HSTS, and no caching of admin answers. `public/_headers` sets the same for static files.
- **Only `firesidetales.dev` serves the site**: `workers_dev` and preview URLs are off, so there's no second address to reach it by.
- Everything people send is stored and shown as plain text: database queries use bound parameters, pages escape all text, and week posts strip markup and refuse links.

## Working on it

Needs Node. From this folder:

```sh
npm install
npm run db:local
npm run dev
```

Create `.dev.vars` (it's gitignored) with `DEV_ADMIN=1` to open `/admin` without signing in, . Run the rule tests with `npm test`, type-check with `npm run check`, and build with `npm run build`. To add a shadcn component, run `npx shadcn@latest add <name>`.

## Going live

Once, with the Cloudflare account that owns firesidetales.dev:

1. `npx wrangler login`
2. `npx wrangler d1 create fireside-tales`, then put the database ID in `wrangler.jsonc`, and run `npm run db:remote`.
3. Make a Turnstile widget for firesidetales.dev in the Cloudflare dashboard. Put its site key in `wrangler.jsonc` as `TURNSTILE_SITE_KEY`.
4. Set the secrets: `npx wrangler secret put TURNSTILE_SECRET` and `IP_SALT` (any long random text). Both are required: without them the live site turns away every form rather than skipping the bot check.
5. In Cloudflare Zero Trust, add an Access application for `firesidetales.dev/admin` and `firesidetales.dev/api/admin` (the review page reads stories and feedback through it), allowing only the reviewers' emails. Put the team domain (like `yourteam.cloudflareaccess.com`) and the application's audience tag in `wrangler.jsonc`, and the same emails, comma separated, in a secret: `npx wrangler secret put ADMIN_EMAILS`. Emails stay out of the code, since it's public.
6. Add `firesidetales.dev` as a custom domain on the Worker, then `npm run deploy` (it builds first).
7. Optional, author emails: make a [Resend](https://resend.com) account, verify `firesidetales.dev` there (it gives DNS records to add in Cloudflare), and `npx wrangler secret put RESEND_API_KEY`. Emails come from `EMAIL_FROM` in `wrangler.jsonc`.
8. Optional, reviewing with a script: in Zero Trust, under Access > Service credentials, make a service token, and add a policy to the Access application with the action **Service Auth** that includes it. Put `name=client-id` in a secret, `npx wrangler secret put REVIEW_TOKENS` (comma separated for more than one). The name is what the review page shows as the decider. The client secret stays with the script.
9. The addon's stories: make a long random token, set it on the site with `npx wrangler secret put SCHEDULE_TOKEN`, and add the same value as a GitHub Actions secret named `SCHEDULE_TOKEN` in the addon's repository. The GitHub job needs it to read upcoming weeks; nobody else can, so they stay a surprise.
10. Optional, adding stories to the addon right after an approval: make a fine-grained GitHub token for the addon's repository with **Contents: read and write**, and `npx wrangler secret put GITHUB_DISPATCH_TOKEN`. Without it, the GitHub job still runs once a day.

## Feedback

The Feedback page takes ideas, bug reports, and story requests, with an optional way to reply. Each note is saved and emailed to `FEEDBACK_EMAIL` (a secret, set with `npx wrangler secret put FEEDBACK_EMAIL`), with Reply-To set to the sender when they left an email address. The same daily limit and bot check apply as for stories.

A reviewer, or a script with a service token, can sort notes through `GET /api/admin/feedback?status=new` and `POST /api/admin/feedback/{id}` with `{"review":{"category","priority","summary","notes"}}` and `"status":"done"`. Reviews show on the review page's Feedback tab.

## Letting people know

- **Emails, if the author asks.** The submit page has an optional "Email me when it's featured" box. That address gets at most two emails: one when the story is approved (with its week), and one when that week starts. If the story is turned away, they get the reviewer's note instead. The address is deleted after the last email, when the author follows the stop link in any email, or once the story's week has passed. It's never shown, even on the review page.
- **Each Tuesday** just after midnight UTC, a scheduled run sends the "featured" emails. Reviewers can also run it by hand with `POST /api/admin/weekly-run` (add `?week=YYYY-MM-DD` for another week).

Nothing is sent until `RESEND_API_KEY` is set, so local work is safe. To test emails locally, set `RESEND_API_URL` in `.dev.vars` to a local server that records requests.

## The weekly rotation

Weeks start on Tuesday, the game's weekly reset. `GET /api/schedule` lists every approved story with its week, for the job that builds the addon's `Community.lua`. It needs `Authorization: Bearer <SCHEDULE_TOKEN>`, since it includes weeks that haven't started; `/api/featured` only answers for this week and earlier. The addon can't reach the internet, so community stories arrive with addon updates, each release carrying the weeks ahead.

## Search engines and AI agents

The site is a React app, but the worker fills each public page (`/`, `/past`, `/submit`, `/guidelines`, `/status`, `/feedback`) with real HTML before sending it (`worker/pages.ts`): the title and description, a canonical link, link previews (`public/img/og.jpg`), structured data (the site, the addon, this week's stories, and the guidelines' questions and answers), and the page's text. Crawlers and agents that don't run JavaScript see the content; the React app replaces it as it loads. Each past week also has its own page, `/past/YYYY-MM-DD`, read like a post and searchable, and the Past weeks page searches all of them (`/api/past/search`). `/sitemap.xml` is built from the same pages, including every past week, `robots.txt` keeps the review page and admin API out, and `llms.txt` tells AI assistants what the site is and how to share a story.

## Sharing a story as an agent

Agents can send a story with one request, no form or bot check:

```bash
curl -X POST https://firesidetales.dev/api/agent/submissions \
  -H 'content-type: application/json' \
  -d '{"title":"The Gnome Who Sold Silence","story":"A gnome in Ironforge sells jars of silence.\n*cups an invisible jar in both hands*\nNobody has opened one. Everyone agrees they are very quiet."}'
```

`story` takes the same writing as the submit page (actions in `*asterisks*`, or the game's TITLE/SAY/EMOTE format); a `text/plain` body with that format works too. The reply is `201` with a receipt code and status link, `422` with a list of problems to fix, or `429` past the limit: 3 per address a day, and 200 agent stories a day in all. `GET /api/agent` describes the fields. Agent stories go through the same review, and the review page marks them **Agent**.

## Reviewing with a script

Anything that can send HTTP requests can review stories through the same API the review page uses. Sign in with a Cloudflare Access service token (step 8) by sending its two headers on every request:

```bash
curl https://firesidetales.dev/api/admin \
  -H "CF-Access-Client-Id: $CLIENT_ID" -H "CF-Access-Client-Secret: $CLIENT_SECRET"
```

`GET /api/admin` returns the instructions, the guidelines, and the limits. In short:

- `GET /api/admin/submissions?status=pending` lists what's waiting, with each story's automatic-check notes. `GET /api/admin/submissions/{id}` gets one.
- `POST /api/admin/submissions/{id}` with `{"action":"approve"}` schedules it for the first week from next week with room (or pass `"week"`). `{"action":"reject","note":"..."}` turns it away, and the note is required, since the author sees it. Either can include an edited `"story"`.
- `{"action":"pending"}` undoes a decision.

Each decision records who made it (the token's name or the reviewer's email), shown on the review page.

## From approval to the addon

1. An approval (or a change to an approved story) starts `.github/workflows/community.yml` in the addon's repository, if `GITHUB_DISPATCH_TOKEN` is set. It also runs daily.
2. The job runs `tools/build-community.mjs`, which reads `/api/schedule` and writes `addon/FiresideTales/Community.lua`, checking every line again. If it changed, the job commits it to main.
3. On Monday evening (UTC), before the new week, the job releases if `Community.lua` changed since the last release: it bumps the patch version, adds a changelog line crediting the authors, tags it, and starts the release workflow, which uploads to CurseForge. Run the job by hand with **release** ticked to release sooner.
4. It only releases stories. If other addon files changed since the last release, it skips, so that release is made by hand with its own changelog.

## Week posts

Each week can have a written post: a title, a few paragraphs, and up to 10 highlighted stories with a note on each. It shows above the week's stories, on the home page during that week and on `/past/YYYY-MM-DD` after, and search engines see it too. Posts are plain text, without links.

Write them on the review page's **Week posts** tab, or through the API with a service token (step 8):

- `GET /api/admin/weeks/{week}/post` reads one. `GET /api/admin/weeks?past=8` shows which weeks have one.
- `PUT /api/admin/weeks/{week}/post` with `{"title","intro","highlights":[{"story_id","note"}],"status":"draft"|"published"}` writes or replaces it. A `422` lists what to fix.
- `DELETE /api/admin/weeks/{week}/post` removes it.

A published post goes public only once its week starts, so posts can be written ahead. Drafts never show. Who saved a post is kept for the review page and never shown publicly.

## From submitted to in the addon

Each story has a stage, shown on the review page and in the API: **waiting**, **rejected**, **scheduled** (approved, not in a release yet), **in the addon** (released, its week hasn't started), **featured** (this week), **missed** (this week started without it in a release), or **past**.

The release workflow tells the site which stories each version carries: after uploading to CurseForge, it sends the story ids in `Community.lua` to `POST /api/release`, with the same `SCHEDULE_TOKEN` the stories job uses. That endpoint can only mark approved stories as shipped, once each. Changing an approved story's words or week clears the mark, since it needs a new release.

The review page's **Overview** tab, and `GET /api/admin/overview` for scripts, show counts per stage, the next 12 weeks (stories, how many are in a release, the post), the last and next release, open feedback, and a to-do list of what needs doing.
