# Questie Issue & PR Tracking

## Issues Found

| Issue # | Title | Status | GitHub Issue | Notes |
|---------|-------|--------|--------------|-------|
| 001 | Addon fails to load - InitializeTables doesn't exist | Fixed locally | #18 | PR #19 submitted |
| 002 | Quest tracking fails - wrong questId detection | Fixed locally | - | PR #20 submitted |  
| 003 | Quest 26939 has wrong data | In Progress | Not filed | Need to verify objectives |

## Pull Requests Submitted

| PR # | Title | Status | Fixes Issue | Notes |
|------|-------|--------|-------------|-------|
| 19 | Fix loading failure | Pending | #18 | esurm claims "cascading issues" |
| 20 | Fix quest tracking detection | Pending | #002 | Waiting for review |
| 21 | Fix Quest 26939 data | Not submitted | #003 | Need to verify objectives first |

## Fixes Applied Locally

All fixes are running in production without issues:
- ✅ Loading failure fix (PR #19)
- ✅ Quest tracking fix (PR #20)
- ⏳ Quest 26939 data (needs objective verification)

## Upstream Status
- Rolled back from 1.3.4d to 1.3.4b
- Not accepting PRs despite them being tested
- Added bandaid fixes instead of proper solutions