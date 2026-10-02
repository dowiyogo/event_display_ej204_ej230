# Validation Report

## Git State
- Original repository remained on `feat/endtop-sslg4` at `c6e7843b2486fb3d073f4d56f7a1f0767e14419e`.
- Experimental worktree remained on `feat/ej204-event-display-tracks` at `c93502bd0bf9fed6d72fc87c0f23616a3cb6cd4f`.
- The original repo was not modified during validation.

## Case Results
- xm690_n20: events=1, optical_seen=29206, optical_stored=20, scint=27985, detected=8456, root_entries=8456, sha256=3ffa182ecbef1a98bfdb027c2c9abab675f38d1f1a8fd322304cdfc863cac196
- xm400_n20: events=1, optical_seen=17274, optical_stored=20, scint=16221, detected=4120, root_entries=4120, sha256=c54db0c906ed1e6986b0437212c272698d33fb8f9c3935e080ea4a62182504b9
- x0_n5: events=1, optical_seen=20128, optical_stored=5, scint=19119, detected=4593, root_entries=4593, sha256=5203961731171a3ceec3a7664ababe944b98843c5908528061c59489fed3644f
- x0_n20: events=1, optical_seen=20128, optical_stored=20, scint=19119, detected=4593, root_entries=4593, sha256=5203961731171a3ceec3a7664ababe944b98843c5908528061c59489fed3644f
- x0_n100: events=1, optical_seen=20128, optical_stored=100, scint=19119, detected=4593, root_entries=4593, sha256=5203961731171a3ceec3a7664ababe944b98843c5908528061c59489fed3644f

## Invariance Checks
- x0_n5/x0_n20/x0_n100 SHA256 identical: 5203961731171a3ceec3a7664ababe944b98843c5908528061c59489fed3644f
- x0_n5 track IDs subset of x0_n20: True
- x0_n20 track IDs subset of x0_n100: True

## Run Paths
- Batch runner: `/home/reriosto/SHiP/event_display_ej204_ej230/outputs/selective_tracks_ej204/run_all_validations.sh`
- Interactive launcher: `/home/reriosto/SHiP/event_display_ej204_ej230/outputs/selective_tracks_ej204/launch_selective_display.sh`

## Real Issues Found
- The `/display/*` messenger is only available after `/run/initialize`; the macros were arranged accordingly.
- The result directories needed to be created outside the repositories to keep the source trees untouched.
- The experimental build directory already existed and was reused as requested; the legacy `ej200/build` tree was not touched.

## Safety Notes
- No `git reset`, `git clean`, `git stash`, `git restore`, commit, or push was performed in this validation step.
- `ej200` was not modified.
- `ej230` was not modified.

## Recommended View
- `x0_n20`
- Command: `/home/reriosto/SHiP/event_display_ej204_ej230/outputs/selective_tracks_ej204/launch_selective_display.sh x0_n20`
