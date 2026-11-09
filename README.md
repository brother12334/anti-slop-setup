# Anti-slop web design setup

How to set up my "anti-slop" web design workflow for Claude from scratch on a new machine.

This repo doesn't include any of the skills' own files. It only links to them and gives you the commands to install them. Some of them have licenses that don't allow redistribution (transitions.dev says so outright).

## 1. What this is

This is a design workflow built from Griffin Wooldridge's video [Claude Skills for Designers (Ban AI Slop Forever)](https://www.youtube.com/watch?v=ia8xgSqqQ_0). It uses five skills to keep websites that Claude builds from looking generic. A short set of global rules ([CLAUDE.md](CLAUDE.md)) tells Claude which skill to use when and settles the places where the skills disagree.

## 2. The skills

| Skill | What it does | Where it comes from | Where it's installed |
| --- | --- | --- | --- |
| design-taste-frontend ("taste") | First drafts of landing pages, plus a browser checker | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | Claude Code only (global) |
| impeccable | Critique, polish, distill, typeset, bolder/quieter passes, and live mode | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | claude.ai (synced), and optionally global in Claude Code for live mode |
| transitions-dev | Ready-made CSS transitions with motion tokens | [Jakubantalik/transitions.dev](https://github.com/Jakubantalik/transitions.dev) | claude.ai (synced) |
| pick-ui-library | Picks a frontend library from a curated list. Only runs when you invoke it by name. | [emilkowalski/skills](https://github.com/emilkowalski/skills) | claude.ai (synced) |
| web-design-guidelines (Vercel) | Accessibility and UX audit. Fetches the latest rules on every run. | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | claude.ai (synced) |

Skipped:

- **Mobbin**: needs a paid plan.
- **frontend-design**: built into Claude, so there's nothing to install. Using it is optional.

## 3. Prerequisites

- **Node.js**, so that `npx` works. Get it from [nodejs.org](https://nodejs.org). Check it with:

  ```bash
  node -v
  npx -v
  ```

- **Claude Code v2.1.273 or later.** Check your version with:

  ```bash
  claude --version
  ```

- **The same Claude account** signed in on [claude.ai](https://claude.ai) and in Claude Code. Skill syncing depends on it.

On Windows, run the commands in this guide in Git Bash.

## 4. Step 1: Add skills to claude.ai

Go to [claude.ai/customize/skills](https://claude.ai/customize/skills) and upload these four skills, one zip each:

- pick-ui-library
- web-design-guidelines
- transitions-dev
- impeccable

Skills you enable on claude.ai sync to Claude Code automatically as long as you're signed in with the same account. Claude Code checks for them about every 10 minutes. To see them, run this inside Claude Code; they're listed under "claude.ai sync":

```
/skills
```

### Upload gotchas

- **A zip can contain at most 200 files.**
- **The `description` in SKILL.md can be at most 1024 characters.** transitions-dev's original description is about 1,800 characters, so it has to be shortened before you upload it.
- **Don't upload taste to claude.ai.** It has about 1,700 files, and a trimmed copy breaks its scripts because they need folders you'd have to remove (`assets/ui`, moments, scenes, objects, icons). Taste goes in Claude Code instead (Step 2).

### Building the upload zips

The quick way is the script in this repo. It clones the four repos into a temporary folder, shortens transitions-dev's description, checks both limits, and writes the zips to `./dist`:

```bash
git clone https://github.com/brother12334/anti-slop-setup.git
cd anti-slop-setup
./build-claude-ai-zips.sh
```

`dist/` is git-ignored, so the zips never get committed.

To build a zip by hand instead:

1. Download the skill's repo. On its GitHub page, click **Code → Download ZIP**, then unzip it. Or clone it:

   ```bash
   git clone --depth 1 https://github.com/Jakubantalik/transitions.dev.git
   ```

2. Find the skill's folder. This is the folder that holds `SKILL.md`:

   | Skill | Folder inside the repo |
   | --- | --- |
   | pick-ui-library | `skills/pick-ui-library` |
   | web-design-guidelines | `skills/web-design-guidelines` |
   | transitions-dev | `skills/transitions-dev` |
   | impeccable | `.claude/skills/impeccable` |

3. Zip **the folder itself**, not just what's inside it. The zip should open to a single folder named after the skill. From the folder's parent:

   ```bash
   cd transitions.dev/skills
   zip -r transitions-dev.zip transitions-dev
   ```

4. Check the file count. It must be 200 or fewer:

   ```bash
   find transitions-dev -type f | wc -l
   ```

5. Check the description length. It must be 1024 or fewer. This counts the whole `description:` line, so it slightly overcounts, which is fine:

   ```bash
   grep '^description:' transitions-dev/SKILL.md | wc -m
   ```

   If it's too long (transitions-dev is), edit the `description:` line in SKILL.md to something shorter, then zip it again.

## 5. Step 2: Install taste globally in Claude Code

```bash
cd ~
npx skills add https://github.com/Leonxlnx/taste-skill --skill design-taste-frontend --global --agent claude-code
```

> **Warning:** if a skill with the same name is also enabled on claude.ai, the synced copy wins and Claude Code skips the local install. Delete it from claude.ai first: open the skill, turn off its toggle, then choose **… → Delete**.

## 6. Step 3 (optional): Impeccable live mode

Live mode needs Impeccable installed in Claude Code itself, not just synced from claude.ai:

```bash
npx impeccable install --global
```

If it says Impeccable is already installed, add `--force`:

```bash
npx impeccable install --global --force
```

## 7. Step 4: Add the global rules

Copy [CLAUDE.md](CLAUDE.md) from this repo into `~/.claude/CLAUDE.md`. That's Claude Code's global config, which applies to every project, so don't put it in a project folder. Run these from inside this repo.

Check whether you already have one:

```bash
ls ~/.claude/CLAUDE.md
```

**If it doesn't exist** ("No such file or directory"), copy it:

```bash
mkdir -p ~/.claude
cp CLAUDE.md ~/.claude/CLAUDE.md
```

**If it already exists**, add to the end instead of overwriting it. First make sure the rules aren't already there; if this prints a line, skip the append:

```bash
grep -F "## Design skill rules" ~/.claude/CLAUDE.md
```

```bash
printf '\n' >> ~/.claude/CLAUDE.md
cat CLAUDE.md >> ~/.claude/CLAUDE.md
```

### Or do Steps 2–4 in one go (macOS/Linux)

[setup.sh](setup.sh) checks for Node.js, installs taste, asks before installing Impeccable live mode, and adds the rules safely (it never overwrites your file or adds the rules twice). At the end it prints the claude.ai steps it can't do for you.

```bash
./setup.sh
```

## 8. Step 5: Verify

1. Open Claude Code in a brand-new folder:

   ```bash
   mkdir -p ~/skills-check
   cd ~/skills-check
   claude
   ```

2. Run:

   ```
   /skills
   ```

   All five skills should be listed: taste as a regular skill, and the other four under "claude.ai sync". If the claude.ai ones are missing, wait about 10 minutes and check again.

3. Ask:

   ```
   What are my design skill rules?
   ```

   It should list all seven rules from [CLAUDE.md](CLAUDE.md).

## 9. The workflow

### Full client website

Go through all of these steps, in this order:

1. **Taste draft.**

   ```
   Build a landing page for [business] with the taste skill
   ```

2. **Impeccable critique.** The first critique also creates the project's PRODUCT.md and DESIGN.md.

   ```
   Run an impeccable critique
   ```

3. **Impeccable polish passes**, based on what the critique found:

   ```
   Run impeccable polish
   ```

   ```
   Run impeccable typeset on the headings
   ```

   ```
   Make the hero quieter with impeccable
   ```

4. **App UI only: pick-ui-library and transitions-dev.**

   ```
   Use pick-ui-library: what should I use for toasts?
   ```

   ```
   Add transitions to the dropdown and modal with transitions-dev
   ```

5. **web-design-guidelines check, before shipping.**

   ```
   Run the web-design-guidelines review on this site
   ```

### Quick personal page

Skip all of it. Just ask for the page and take whatever's fastest.

## 10. Known conflicts and quirks

These are the problems I ran into, and the rule in [CLAUDE.md](CLAUDE.md) that fixes each one.

| Problem | Rule that fixes it |
| --- | --- |
| web-design-guidelines wants Title Case; taste wants sentence case. | Sentence case wins for headings and buttons. |
| taste and transitions-dev each have their own motion timings. | One motion system per page: taste's on landing pages, transitions-dev tokens in app UI, never both. |
| taste's palette picker suggested yoga and wellness palettes for "fitness". | Always use the client's brand colors. Use the picker only when there are none. |
| taste's checker is strict and slow. Each run takes several minutes of headless Chrome, there's a limit of three gate rounds, every section has to be exactly 1–2 screens tall at 1440, 1024, 820, 768 and 390 px widths, and it flags hand-built mock-ups that are fine. | Treat the checker as a guide, not a law. Don't reword real copy just to pass a heading check, and log false flags instead of fighting them. |
| Impeccable needs a PRODUCT.md and DESIGN.md in each project for a full critique, and its detector can flag real data or padded panels. | Every client project keeps both files, created on the first critique. |

## 11. Updating

Claude Code skills (taste, and Impeccable if you installed it there):

```bash
npx skills update --global
```

```bash
npx impeccable update
```

claude.ai skills don't update themselves. For each one, download the repo again, build a fresh zip (`./build-claude-ai-zips.sh` does all four), delete the old version at [claude.ai/customize/skills](https://claude.ai/customize/skills), and upload the new zip.

## 12. Credits

- Workflow: Griffin Wooldridge, [Claude Skills for Designers (Ban AI Slop Forever)](https://www.youtube.com/watch?v=ia8xgSqqQ_0)
- design-taste-frontend: [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)
- impeccable: Paul Bakaus, [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- transitions-dev: Jakub Antalik, [Jakubantalik/transitions.dev](https://github.com/Jakubantalik/transitions.dev)
- pick-ui-library: Emil Kowalski, [emilkowalski/skills](https://github.com/emilkowalski/skills)
- web-design-guidelines: Vercel, [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)

All skills belong to their authors and are under their own licenses. This repo only documents how to install them.
