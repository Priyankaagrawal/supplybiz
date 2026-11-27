# T-170: isolated Android check runtime; no saved user AVD or SDK is modified.
param(
  [string]$SdkRoot = "$env:LOCALAPPDATA/Android/Sdk",
  [string]$TemplateConfig = "$env:USERPROFILE/.android/avd/Pixel_5_4.avd/config.ini",
  [ValidateSet('host','swiftshader_indirect')][string]$Renderer = 'swiftshader_indirect',
  [ValidateRange(5554,5682)][int]$Port = 5580
)
$ErrorActionPreference = 'Stop'
if($Port % 2 -ne 0){throw 'An even emulator console port is required'}
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskBuild = Join-Path $taskRoot 'apps/mobile/build'
$taskAvdRoot = Join-Path $taskBuild 't170-avds'
$taskAvd = Join-Path $taskAvdRoot 'SupplyBizT170.avd'
$taskSdk = Join-Path $taskBuild 't170-sdk'
$taskAdb = Join-Path $SdkRoot 'platform-tools/adb.exe'
$taskDevices = & $taskAdb devices
if($LASTEXITCODE -ne 0){throw 'Cannot inspect Android transports'}
if($taskDevices -match "^emulator-$Port\s"){throw 'The requested emulator transport is already in use'}
if(!(Test-Path -LiteralPath (Join-Path $SdkRoot 'system-images/android-34/google_apis/x86_64/userdata.img'))){throw 'Installed Android 34 Google APIs x64 image is required'}
New-Item -ItemType Directory -Path $taskAvd -Force | Out-Null
if(!(Test-Path -LiteralPath (Join-Path $taskAvd 'config.ini'))){
  $taskConfig = [IO.File]::ReadAllText($TemplateConfig)
  $taskValues = @{'AvdId'='SupplyBizT170';'avd.ini.displayname'='Supply Biz T170 disposable';'image.sysdir.1'='system-images\android-34\google_apis\x86_64\';'hw.cpu.arch'='x86_64';'abi.type'='x86_64';'PlayStore.enabled'='false';'hw.ramSize'='1536';'hw.cpu.ncore'='2';'hw.lcd.width'='480';'hw.lcd.height'='960';'hw.lcd.density'='240';'skin.name'='480x960';'skin.path'='480x960';'hw.gpu.mode'='swiftshader_indirect';'fastboot.forceColdBoot'='yes';'fastboot.forceFastBoot'='no'}
  # Copy configuration only. External user data/cache/sdcard paths must not follow it.
  $taskConfig = [regex]::Replace($taskConfig,'(?mi)^(disk\..*\.(path|initPath)|sdcard\.path|snapshot\.storage\.path)\s*=.*\r?\n?','')
  foreach($taskKey in $taskValues.Keys){
    $taskPattern = '(?m)^'+[regex]::Escape($taskKey)+'\s*=.*$'
    $taskValue = $taskKey+' = '+$taskValues[$taskKey]
    if($taskConfig -match $taskPattern){$taskConfig=[regex]::Replace($taskConfig,$taskPattern,$taskValue)}else{$taskConfig+="`n$taskValue`n"}
  }
  [IO.File]::WriteAllText((Join-Path $taskAvd 'config.ini'),$taskConfig,[Text.UTF8Encoding]::new($false))
}
[IO.File]::WriteAllText((Join-Path $taskAvdRoot 'SupplyBizT170.ini'),"avd.ini.encoding=UTF-8`npath=$taskAvd`ntarget=android-34`n",[Text.UTF8Encoding]::new($false))
New-Item -ItemType Directory -Path (Join-Path $taskSdk 'build-tools') -Force | Out-Null
foreach($taskPart in @('platform-tools','platforms','emulator','licenses','ndk','cmake','cmdline-tools')){
  $taskSource = Join-Path $SdkRoot $taskPart
  $taskLink = Join-Path $taskSdk $taskPart
  if((Test-Path -LiteralPath $taskSource) -and !(Test-Path -LiteralPath $taskLink)){
    New-Item -ItemType Junction -Path $taskLink -Target $taskSource | Out-Null
  }
}
# Flutter selects the highest build-tools directory, even an incomplete installer.
$taskTools = Get-ChildItem (Join-Path $SdkRoot 'build-tools') -Directory |
  Where-Object {$_.Name -match '^\d+\.\d+\.\d+$' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'aapt.exe'))} |
  Sort-Object {[version]$_.Name} -Descending | Select-Object -First 1
if(!$taskTools){throw 'A complete installed Android Build Tools package is required'}
$taskToolLink = Join-Path $taskSdk "build-tools/$($taskTools.Name)"
if(!(Test-Path -LiteralPath $taskToolLink)){New-Item -ItemType Junction -Path $taskToolLink -Target $taskTools.FullName | Out-Null}
$taskPreviousAvd = $env:ANDROID_AVD_HOME
$taskPreviousSdk = $env:ANDROID_SDK_ROOT
$taskPreviousEmulatorHome = $env:ANDROID_EMULATOR_HOME
$taskPreviousUserHome = $env:ANDROID_USER_HOME
try {
  $env:ANDROID_AVD_HOME = $taskAvdRoot
  $env:ANDROID_SDK_ROOT = $SdkRoot
  $env:ANDROID_EMULATOR_HOME = Join-Path $taskBuild 't170-emulator-home'
  New-Item -ItemType Directory -Path $env:ANDROID_EMULATOR_HOME -Force | Out-Null
  $env:ANDROID_USER_HOME = $env:ANDROID_EMULATOR_HOME
  $taskProcess = Start-Process -FilePath (Join-Path $SdkRoot 'emulator/emulator.exe') -ArgumentList @('-avd','SupplyBizT170','-no-snapshot','-no-window','-no-audio','-no-boot-anim','-gpu',$Renderer,'-feature','-Vulkan','-memory','1536','-cores','2','-port',"$Port") -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $taskBuild 't170-emulator.out.log') -RedirectStandardError (Join-Path $taskBuild 't170-emulator.err.log')
  [pscustomobject]@{ProcessId=$taskProcess.Id;Serial="emulator-$Port";SdkView=$taskSdk;AvdHome=$taskAvdRoot;Renderer=$Renderer;Status='Starting; verify sys.boot_completed=1 before measuring'}
} finally {
  $env:ANDROID_AVD_HOME = $taskPreviousAvd
  $env:ANDROID_SDK_ROOT = $taskPreviousSdk
  $env:ANDROID_EMULATOR_HOME = $taskPreviousEmulatorHome
  $env:ANDROID_USER_HOME = $taskPreviousUserHome
}
