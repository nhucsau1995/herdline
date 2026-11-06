# Herdline - Source Brief

## Title
Herdline - offline-first dairy herd management

## Description
Herdline is a mobile app for dairy farm teams to run the herd from the phone, in the barn, with no
signal. It keeps every animal's profile and family tree, the AM and PM milk of each cow, the
current lactation with a projected 305-day yield, heats, inseminations, pregnancy checks and
calvings, the bull semen straws in the tank, and health treatments with milk withdrawal periods.
A dashboard and reports show the numbers a manager checks every morning. Four roles (Admin,
Manager, Worker, Veterinarian) see the same herd but can change only their own part of it.

## Store links
Not yet published (portfolio MVP).

## Platform
Android demo, iOS-ready codebase (Flutter).

## Category
Agriculture / farm management / productivity.

## Features
- Animal registration, profile, edit and delete, with ear tag format and duplicate checks
- Pedigree: animal, sire and dam, four grandparents, offspring
- Daily milk records per cow and session, herd total, 7-day chart, previous days
- Withdrawal milk kept out of the tank total
- Lactation curve per cow (peak day and yield), yield to date, 305-day projection, past lactations, dry-off
- Breeding: heat, insemination (uses a straw), pregnancy check (updates status), calving due; due now, calendar, history
- Bulls and semen inventory with conception rate and low-stock warning
- Health timeline: treatments, vaccinations, checks, withdrawal periods
- Farm dashboard, key statistics and reports (production, fertility, health, herd structure)
- Role-based access for Admin, Manager, Worker, Veterinarian
- Offline-first: SQLite on the device, sample farm loaded on first launch, first-run empty state
- Form validation and error handling on every write

## Tech stack
- Flutter 3.35 / Dart 3.9, Material 3 with a custom design system (Inter + Sora, bundled fonts)
- Riverpod 3 (Notifier / AsyncNotifier) for state
- sqflite (SQLite) behind a repository interface; in-memory repository for tests
- Custom chart painters (bars, lactation curve, donut, sparkline), no chart dependency
- Unit and widget tests; integration tests capture screenshots and the demo on an Android emulator in GitHub Actions
- Stack reason: the job asks for Flutter with Provider or Riverpod and SQLite or Drift, so the stack is the job's (Riverpod + SQLite chosen from its options).

## Industry
Livestock and dairy farming.

## Metrics
Unpublished POC, no usage metrics. The sample farm holds 250 head (182 milking, 24 dry, 41
heifers, 3 bulls), 14 days of AM/PM milk records (about 5,000 rows) and loads on first launch
in a single SQLite transaction.

## Research notes
- Verified: all screens run on an Android emulator (screenshots and GIF in the README are real
  captures); 13 unit and widget tests pass; data survives app restarts (SQLite).
- Modelled, not measured: milk yields come from Wood's lactation curve per cow with small daily
  noise; fertility history is generated from a fixed seed; the farm date is fixed at 6 Nov 2026
  so the demo is repeatable.
- Simulated: sign-in is a role pick plus a 4-digit device PIN (no server accounts); "Invite
  member" is a placeholder.
- Known issues (design review 94/100, grade A, 0 Critical, 0 Major): the floating action pill
  covers the last visible card until you scroll; a few metric sizes (22, 28, 36, 40) sit outside
  the 5-step type scale; filter pills are 40 dp tall (44 recommended); the withdrawal chip
  truncates the tag line on the milk list; 'Due now' also lists recent inseminations.
- The demo GIF ends at Record milk: on the CI emulator the first launch spends about 30 s writing
  the sample farm before the walkthrough starts, and the recording stops at 60 s. Breeding and
  Reports are in the screenshots.
- Next steps: multi-device sync and cloud backup behind the repository interface, push reminders
  for heats and calvings, RFID/EID tag scanning, export to PDF/CSV, a manager web dashboard.
