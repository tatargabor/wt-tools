## ADDED Requirements

### Requirement: Clean worker shutdown

All background worker threads (StatusWorker, UsageWorker, TeamWorker, ChatWorker) SHALL be stopped before application exit.

The `quit_app()` and `restart_app()` methods SHALL use centralized `_stop_all_workers()` and `_wait_all_workers()` helpers that handle all workers uniformly.

#### Scenario: All workers stopped on quit

- **WHEN** user quits the application via tray menu
- **THEN** all worker threads SHALL be signaled to stop
- **AND** the application SHALL wait up to 2 seconds for each worker to finish
- **AND** workers that don't finish in time SHALL be terminated

#### Scenario: UsageWorker responds to stop within 500ms

- **WHEN** `usage_worker.stop()` is called
- **THEN** the UsageWorker thread SHALL exit its sleep loop within 500ms
- **AND** the thread SHALL terminate cleanly without requiring `QThread.terminate()`

### Requirement: Interruptible worker sleep

The UsageWorker SHALL use interruptible sleep (small chunks checking `_running` flag) instead of a single 30-second `msleep()` call. This ensures `stop()` takes effect promptly.

#### Scenario: Sleep interrupted by stop

- **WHEN** UsageWorker is sleeping between fetch cycles
- **AND** `stop()` is called
- **THEN** the worker SHALL wake and exit within 500ms
