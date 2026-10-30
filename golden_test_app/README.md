# iOS golden test app

The app uses the concurrency runtime to render one initial frame of each bundled
fixture directly to a Metal texture. After saving each PNG, the runner publishes
its `Rive` to a paused `RiveUIViewRepresentable` for display. The screen is blank
until a `Rive` is available and contains no labels or controls. The display view
does not drive PNG capture.

## GPU Canvas selection

Set `RIVE_GOLDEN_ENABLE_GPU_CANVAS` in the app's launch environment:

| Value | GPU Canvas |
| --- | --- |
| Unset or `0` | Disabled (default) |
| `1` | Enabled |

The setting configures the worker before any file is imported. Other values fail
the run. A build without `RIVE_CANVAS` reports an error if GPU Canvas is enabled.
`GoldenTestApp.xcconfig` imports the framework's generated feature flags so the app
and framework agree on support.

In Xcode, open `../Rive.xcworkspace`, select the `golden_test_app` scheme, and add
the variable under **Run > Arguments > Environment Variables**. Build the runtime
dependencies using the usual iOS runtime build scripts first.

For an installed simulator build:

```sh
# GPU Canvas disabled (default)
xcrun simctl launch --terminate-running-process booted rive.app.golden-test-app

# GPU Canvas enabled
SIMCTL_CHILD_RIVE_GOLDEN_ENABLE_GPU_CANVAS=1 \
  xcrun simctl launch --terminate-running-process booted rive.app.golden-test-app
```

## Output

Each launch clears previous results and writes `vector.png`, `dwarf.png`, and
`text.png` into the app's Documents directory. The existing BrowserStack collector
can retrieve the same filenames. Images are 860×540 pixels with centered contain
fit, a transparent background, and sRGB PNG output.

The runner advances each default state machine by zero, submits one draw at a
time, and waits for successful GPU completion before reading the texture. Skipped
draws, GPU failures, and PNG export errors fail the run. PNG writes are atomic.
The console reports completion only after all three files are saved, and reports
errors if the run fails.

After every PNG is saved, the app atomically writes `golden_results.json` with
the GPU Canvas setting, filenames, and pixel dimensions. The BrowserStack collector
waits for this manifest and verifies the requested mode before downloading PNGs.
The manifest is cleared along with the PNGs on the next launch.

## GitHub workflows

`schedule_ios_browserstack.yaml` keeps the daily run with GPU Canvas disabled. It
also accepts an `enable_gpu_canvas` boolean when launched manually or reused by
another workflow. The flag reaches the app through Appium's `processArguments.env`.

`schedule_ios_gpu_canvas_browserstack.yaml` reuses that workflow with GPU Canvas
enabled, daily at 10:30 UTC or on manual dispatch. Both modes compare against the
same `zzzgold/ios` baselines on the same curated BrowserStack device list, using
the existing comparison and reporting behavior.

Both workflows publish reports to the existing S3 report location and send results
and failure notifications to the existing Slack destinations.
GPU Canvas reports use a `gpu_canvas` subdirectory and a distinct Slack report
label so results remain distinguishable from runs with GPU Canvas disabled.

## Validation

When changing capture behavior, compare decoded RGBA pixels against the previous
app on the same simulator or device. Compare output with GPU Canvas enabled and
disabled, then repeat each setting to check deterministic results. Also check the
unset environment setting, rejection of invalid values, and rejection of GPU Canvas
in a build without `RIVE_CANVAS`. Failed configuration must leave no stale PNGs.
