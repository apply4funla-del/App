# Project Intent: Mobile File Tidy Assistant

Last updated: 2026-04-04  
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
- Architecture must be modular, expandable, and migratable.

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

## Locked UX flow (2026-03-29)
- Required sequence:
  - Get Started
  - Sign In
  - Connect Source (user must tap/select one source: Phone, Google Drive, or Dropbox)
  - Method (Tidy Files or Archive Memories)
  - Tidy Files method detail (Amend In Root Folder or Clone And Work)
  - Permission screen (required when Amend In Root Folder is chosen)
  - Explorer
- Onboarding layout requirements:
  - In landscape and wider desktop layouts, primary onboarding buttons like Get Started and Continue must not span the full width of the screen.
  - Keep onboarding actions constrained to a readable width while preserving full-width behavior on narrow phone layouts.
- Sign-in requirements:
  - Sign in must be optional. Users can continue in free mode without sign-in.
  - Sign in must clearly explain: sign in is for Google Drive, Dropbox, and plan restore.
  - Sign-in must use modular auth architecture and store account data in Supabase.
  - Free mode must remain available when users skip sign-in.
- Connect Source layout requirements:
  - Portrait layout can remain stacked.
  - In landscape/wide layouts, Phone, Google Drive, and Dropbox must appear as three horizontal square-style option boxes.
  - Google Drive and Dropbox access must require sign-in first.
- Permission handoff requirement:
  - After user grants folder permission, app must open Explorer immediately.
  - Do not block user behind generic "can't use this folder" style app messages.
  - If default root folders are inaccessible, show clear instruction: "Pick a folder to amend the content."
- Explorer layout requirement (non-negotiable):
  - Explorer must open in 2-panel view.
  - Left panel is folder + file tree structure only (high-level structure and file names).
  - Right panel shows selected file details/content only, with no action buttons inside the preview area.
  - Right panel must be independently scrollable and maximize visible file area.
  - Both panels must be independently scrollable.
  - User taps a file name in left panel to open it on right panel.
  - Rename must be inline in Explorer (no modal sheet required).
  - Rename field must stay visible in the top Explorer navigator area, above the split panels.
  - Explorer controls bar must stay collapsed by default and expand only when user explicitly opens it from the top area.
  - Rename input is a text box with locked file extension shown outside the box.
  - Extension cannot be edited by user.
  - Inline rename must work in both portrait and landscape modes.
  - Explorer bottom bar must expose four actions: Home, History, Settings, and USB Archive.
  - Settings must contain subscription management, logout, privacy explanations, and AI assist controls.

## Locked Explorer layout summary (2026-04-03)
- The current Explorer structure is approved and should be treated as the working baseline.
- The right preview panel is now large enough for practical use and must keep priority over extra controls.
- The right panel must support scrolling for long document previews and metadata-heavy previews.
- PDF preview should use the full preview area where possible.
- Image preview and MP4 thumbnail preview should stay inside scroll-safe containers and must not trigger overflow warnings.
- The rename bar stays visible at the top.
- The Explorer controls row is the part that stays hidden by default, and user can reveal it from the top area when needed.
- The layout must avoid yellow/black overflow warnings in normal desktop and phone-sized windows.
- Do not reintroduce action buttons inside the right preview panel.
- If future UI changes reduce preview area, increase overflow risk, or hide rename by default again, that is drift and should be rejected.

## Cloud and file access requirements
- Support local phone files.
- Support Google Drive connection.
- Support Dropbox connection.
- Use secure sign-in and limited permissions.
- Use Supabase as the current auth/subscription backend behind repository interfaces.
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
- Subscription status must be read from Supabase, not hardcoded in UI.

## Monetization and access control (locked)
- Free mode:
  - Local phone tidy features remain free to use.
  - Users can continue without sign-in.
- Sign-in gated features:
  - Google Drive requires sign-in.
  - Dropbox requires sign-in.
  - Plan restore requires sign-in.
- Paid USB plan:
  - USB archive is a paid feature.
  - Monthly price: $8.90/month.
  - Annual price: $3.90/month billed yearly.
  - USB archive access must be gated by subscription status.

## Architecture principles (non-negotiable)

### Modular architecture
- Build in clear modules by responsibility, not one large code file.
- Screens must be separate modules/pages and reusable where possible.
- Login/auth must be isolated as its own module/widget.
- File browser, preview pane, rename flow, and privacy center must each be independent modules.
- Lottie animations must be integrated via reusable components, not copied ad hoc per screen.
- No business logic inside UI layout widgets.

### Centralized design system (non-negotiable)
- No hardcoded style values in feature screens.
- Fonts, colors, spacing, radii, shadows, and motion timings must come from centralized theme tokens.
- Buttons, inputs, cards, and dialog patterns must come from shared UI components.
- Keep text strings and labels centralized for easier updates/localization.

### Expandable architecture
- New features should be add-on modules with minimal edits to existing modules.
- Use clear interface boundaries between UI, business logic, and data access.
- Feature flags/config should allow controlled rollout of new capabilities.
- Prefer plugin-style connector adapters so new providers can be added without rewriting core logic.

### Migratable architecture
- Never bind core business logic directly to Supabase or any single vendor SDK.
- Use repository/interface layer for all storage and backend operations.
- Keep vendor-specific code in adapter modules only.
- Define stable domain models and mapping layers for provider-specific schemas.
- Maintain data export/import pathways and migration scripts so backend can move to another platform.

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
| Sort controls | Sort files by name/date/size | 5 |
| Landscape split view | Left browse, right preview | 5 |
| Portrait single view | Clean phone-first layout | 5 |
| File preview | Understand file before rename | 4 |
Preview scope note: V1 preview includes PDF, images, text, lightweight content peek for docx/xlsx/pptx, and first-frame thumbnail preview for common video files (mp4/mov). Legacy doc/xls/ppt remain limited preview.
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
