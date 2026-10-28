# Final portable package startup / normal close audit

The final Whalefall.exe was launched normally with verbose logging and Dummy audio. The OS returned its game window and title. No code, PCK, EXE, or export configuration was modified.

Normal-close validation is **blocked**, not passed. Window image capture timed out twice. The subsequent Alt+F4 request via the approved Computer Use API failed with `GetCursorPos failed: 拒绝访问 (0x80070005)`. No further UI input was attempted. Only this test's task-created PID 41160 was later force-reclaimed for cleanup; that termination is not normal-close validation. `result.json` records the exact package hash, window, exit and limitations.

The older `package-startup` test used `--quit-after 90`, which bypasses the application's WM_CLOSE_REQUEST cleanup path. Its two ObjectDB warnings remain historical forced-exit evidence, not proof of a normal-close regression. The source project's simulated WM_CLOSE_REQUEST notification test and lifecycle QA already passed with clean logs. The package's NORMAL_QA also exercised graceful_quit. Neither is represented here as a real user/window-X close test; that specific path remains blocked by the desktop API.

Rerun `G:/鲸落万物生/BOB/work/verify_package_normal_close.ps1` in an unlocked interactive desktop. Inspect the launched game and close its window normally. The script records a fresh timestamped evidence folder, requires exit code 0 and AUDIO_SHUTDOWN, rejects errors/warnings, and never kills a timed-out game process. Dummy audio validates lifecycle only, not audible output.
