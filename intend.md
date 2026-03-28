# Project Intent: Mobile File Tidy Assistant

Last updated: 2026-03-28  
Owner: apply4funla-del/App project

## One-line vision
Help people clean up messy files on phone fast: open folder, preview file, rename clearly, move on.

## Value proposition (locked)
We are building a mobile-first file organization app that turns file cleanup from a slow manual chore into a fast guided workflow: users browse folders, instantly preview each file, and apply smart rename suggestions with one tap while keeping full manual control. Unlike normal file apps that only offer basic rename options, our app helps users understand what a file is before naming it, so they save time, reduce naming mistakes, and can find files later without frustration.

## Core product boundaries
- This is a semi-automated app, not a silent background scraper.
- No automatic full-account crawl by default.
- User must explicitly choose folders to process.
- AI suggests names, but user always confirms before rename.
- Manual rename is always available.
- AI is optional. The app must still deliver strong value without AI.

## Main problems this app solves
- People cannot tell what a file is from a messy filename.
- Renaming on phone is slow and repetitive.
- Photos and travel files become hard to sort after trips.
- Users need quick cleanup, not another complex tool.

## Target users
- Solo professionals with many PDF/doc files.
- Small teams that share files and need consistent names.
- Everyday users with messy photo libraries.
- Older family users who need simple archive workflows.

## Primary use cases
- Folder cleanup: preview and rename files quickly.
- Travel photo tidy: group by date/place and create clean names.
- Fast archive: copy selected files to USB stick with clear confirmation.

## Cloud and file access requirements
- Support local phone files.
- Support Google Drive connection.
- Support Dropbox connection.
- Use secure sign-in and limited permissions.
- Let user choose which folders the app can access.
- Show connected accounts and easy disconnect option.
- Default processing modes:
  - Manual mode: only file user opens.
  - Semi-auto mode: only user-selected folders.
  - Never full-account silent crawl.

## Privacy requirements (non-negotiable)
- Clear consent before processing files.
- No silent scanning of all files.
- Rename actions require user approval.
- Provide a privacy screen that explains what is processed.
- Provide a one-tap "delete my app data" action.
- Keep activity history so users can review and undo changes.
- Local-first option must exist for users who do not want AI.
- Data minimization: send only required snippet/data for AI suggestion.
- No full file upload by default for rename suggestions.

## Security and key handling requirements (non-negotiable)
- Supabase public client key can be in app.
- Supabase service role key must never be in app.
- AI provider key must never be in app.
- All secret keys must stay server-side only.
- Enforce strict per-user access rules in database.

## Product scope by release

### V1 (must ship)
| Feature | User outcome | Confidence (1-5) |
|---|---|---|
| Welcome setup | Clear first-time setup | 5 |
| Connect Google Drive | Access Drive files in app | 4 |
| Connect Dropbox | Access Dropbox files in app | 4 |
| Folder pick control | User chooses folders to allow | 5 |
| Local file access | Browse files on phone | 4 |
| Main folder browser | Navigate files simply | 5 |
| Landscape split view | Left browse, right preview | 5 |
| Portrait single view | Clean phone-first layout | 5 |
| File preview | Understand file before rename | 4 |
| Manual rename | Full user control | 5 |
| AI rename suggestions | 3 smart rename options | 4 |
| Rename confirmation | Prevent accidental changes | 5 |
| Undo rename | Recover from mistakes | 5 |
| Rename history | Track what changed | 5 |
| Tidy Up button | One action to clean a folder | 4 |
| Tidy Up non-AI | Rename/group by date/type/location info | 5 |
| Tidy Up AI | Smarter names and short summary | 4 |
| Travel photo grouping | Group by trip/day/place | 4 |
| Naming templates | Reuse naming format rules | 5 |
| Batch rename | Rename many files in one flow | 5 |
| Privacy center | Transparent controls | 5 |
| Delete my data | User can clear app data | 5 |

### V1.1 (next)
| Feature | User outcome | Confidence (1-5) |
|---|---|---|
| Senior simple mode | Bigger text/buttons, fewer steps | 5 |
| Archive to branded USB | Easy backup from phone | 3 |
| Restore from USB | Easy recovery from backup | 4 |
| Copy verification | Confirm backup success | 4 |

### V2 (later)
| Feature | User outcome | Confidence (1-5) |
|---|---|---|
| Add OneDrive | More file sources | 4 |
| Natural language search | Find by plain sentence | 3 |
| Family/shared plan | Shared cleanup workflow | 4 |

## Hardware USB direction (locked)
- Build a branded USB-C stick workflow that works best with this app.
- Focus on easy archive and restore, especially for older users.
- Show clear success/failure after copy.
- Do not promise impossible device restrictions like "only this app can read the USB" across all phones.

## Monetization direction
- Two paid paths:
  - Pro Local (no AI needed): batch tidy, naming templates, advanced history, better backup tools.
  - Pro AI add-on: AI renames, AI summaries, extra AI credits.
- Free tier: manual rename, preview, non-AI basic tidy, limited AI trials.
- Optional credit packs for high AI usage without subscription.
- Optional hardware bundle margin from branded USB product.
- Ads are not preferred for this product because they reduce trust in a privacy-sensitive app.

## Retention strategy for non-AI users (locked)
- Personalized naming templates and folder presets.
- Reliable undo and rename history.
- Strong archive and restore workflow with USB support.
- Clean ad-light experience to preserve trust.

## Quality and success targets
- Median time from opening a file to completed rename under 10 seconds.
- Most users should accept at least one AI suggestion often enough to show real time savings.
- Rename failures must be rare and recoverable.
- Users must feel in control of every rename.
- Privacy settings must be easy to understand.

## Non-goals for V1
- No enterprise-wide "search everything in every app" promise.
- No automatic mass crawling of whole cloud accounts.
- No complex admin dashboard.

## Drift control
- This file is the source of truth for product scope.
- Any scope change must update this file in the same commit.
- Do not add major features without adding a short reason and release stage here.
