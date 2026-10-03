param(
    [string]$DeviceId = "R94X90BYJTM"
)

$ErrorActionPreference = "Stop"
$Package = "com.example.aihackaton"
$Source = Join-Path $PSScriptRoot "..\test\data\offline_question_cases.json"
$Remote = "/data/local/tmp/offline_question_cases.json"
$Sdk = if ($env:ANDROID_SDK_ROOT) {
    $env:ANDROID_SDK_ROOT
} elseif ($env:ANDROID_HOME) {
    $env:ANDROID_HOME
} else {
    Join-Path $env:LOCALAPPDATA "Android\sdk"
}
$Adb = Join-Path $Sdk "platform-tools\adb.exe"

if (-not (Test-Path $Adb)) {
    throw "adb not found at $Adb. Set ANDROID_SDK_ROOT to your Android SDK path."
}

if (-not (Test-Path $Source)) {
    throw "Question dataset not found: $Source"
}

& $Adb -s $DeviceId push $Source $Remote
if ($LASTEXITCODE -ne 0) {
    throw "Could not copy the question dataset to device $DeviceId."
}

& $Adb -s $DeviceId shell run-as $Package mkdir -p files
if ($LASTEXITCODE -ne 0) {
    throw "The app must be installed and launched at least once before evaluation."
}

& $Adb -s $DeviceId shell run-as $Package cp $Remote files/offline_question_cases.json
if ($LASTEXITCODE -ne 0) {
    throw "Could not stage the dataset in the app's private storage."
}

flutter drive `
    --driver=test_driver/integration_test.dart `
    --target=integration_test/offline_model_eval_test.dart `
    --device-id=$DeviceId
if ($LASTEXITCODE -ne 0) {
    throw "On-device offline model evaluation failed."
}
