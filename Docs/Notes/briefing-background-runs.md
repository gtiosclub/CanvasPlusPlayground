# Briefing: can it run in the background? (#588)

## What runs today

The briefing runs in the foreground: after courses load on launch, and when the app becomes
active again. `BriefingConflictFinder.runIfDue` skips a run if the last one is less than 6 hours
old. Each run is timed (`BriefingConflictFinder.lastRunDuration`, also logged as
`[Briefing] Run took …`).

## The BGAppRefresh budget

`BGAppRefreshTask` gets roughly 30 seconds of wall-clock time, at a time the system picks
(usually around when the student tends to open the app). Anything longer is killed, and repeated
overruns make the system schedule the app less often.

## What a run costs

For each active course, one run:

1. reads the course's announcements from the last 14 days (cache first; network only if the
   cache is empty),
2. reads its assignments (cache first) and its ICS calendar feed (always network),
3. extracts dates from each announcement: one on-device model call per announcement on Tier 1,
   or `NSDataDetector` on Tier 0,
4. reconciles them in Swift.

The model calls are what matter. At a few seconds per call on device, 6 courses with 2–3 recent
announcements each is 12–18 calls: well over 30 s on Tier 1. Tier 0 is milliseconds per
announcement; there the ICS fetches dominate (one request per course).

## Recommendation

- **Tier 0 in the background, Tier 1 in the foreground.** A background refresh should run the
  data-detector path and refresh the ICS feeds. The model pass stays in the foreground, where it
  has time.
- **Only new announcements.** Remember the announcement ids already extracted, so a background run
  only reads what's new. Usually that's zero or one, which fits on Tier 1 too.
- To ship it, the app needs `BGTaskSchedulerPermittedIdentifiers` in its Info.plist and the
  Background fetch mode, plus a `BGTaskScheduler.register` handler that calls
  `BriefingConflictFinder.run`, then `BriefingFeed.rebuild`. Not done in this PR.

## Still to measure

`lastRunDuration` on a real device with Apple Intelligence and a full course load. These
estimates come from the steps above, not from device timing.
