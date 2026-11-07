param([Parameter(Mandatory=$true)][string]$AhkPath,
      [Parameter(Mandatory=$true)][string]$OriginalPath,
      [Parameter(Mandatory=$true)][string]$SmokeDll)
$ErrorActionPreference = 'Stop'
$oracleDirectory = Join-Path ([IO.Path]::GetTempPath()) ('ime-kr-oracle-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $oracleDirectory | Out-Null
$oracleInput = Join-Path $oracleDirectory 'input.txt'
$oracleOutput = Join-Path $oracleDirectory 'output.txt'
$oracleScript = Join-Path $oracleDirectory 'oracle.ahk'
$oracleProcess = $null
try {
    & dotnet $SmokeDll --write-input $oracleInput
    if ($LASTEXITCODE -ne 0) { throw 'Smoke corpus generation failed.' }
    $script = @'
#NoEnv
#NoTrayIcon
#Include __ORIGINAL__
input := FileOpen("__INPUT__", "r", "UTF-8")
output := FileOpen("__OUTPUT__", "w", "UTF-8-RAW")
while (!input.AtEOF) {
    line := RTrim(input.ReadLine(), "`r`n")
    value := ""
    Loop, % StrLen(line) // 4
        value .= Chr("0x" SubStr(line, (A_Index - 1) * 4 + 1, 4))
    Loop, 2 {
        caps := A_Index - 1
        roman := ImeKrLangCorrector.hangulToAlphanumeric(value, caps)
        hangul := ImeKrLangCorrector.alphanumericToHangul(value, caps)
        output.Write(Hex(roman) "|" Hex(hangul) "`n")
    }
}
output.Close()
input.Close()
ExitApp, 0
Hex(value) {
    result := ""
    Loop Parse, value
        result .= Format("{:04X}", Ord(A_LoopField))
    return result
}
'@
    $script = $script.Replace('__ORIGINAL__', $OriginalPath).Replace('__INPUT__', $oracleInput).Replace('__OUTPUT__', $oracleOutput)
    [IO.File]::WriteAllText($oracleScript, $script, [Text.UTF8Encoding]::new($true))
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $AhkPath
    $start.Arguments = '/ErrorStdOut "' + $oracleScript + '"'
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $start.RedirectStandardError = $true
    $oracleProcess = [Diagnostics.Process]::Start($start)
    if (!$oracleProcess.WaitForExit(60000)) {
        $oracleProcess.Kill()
        $oracleProcess.WaitForExit()
        throw 'AHK oracle timed out.'
    }
    if ($oracleProcess.ExitCode -ne 0) { throw ('AHK oracle failed: ' + $oracleProcess.StandardError.ReadToEnd()) }
    (Get-FileHash -LiteralPath $oracleOutput -Algorithm SHA256).Hash
}
finally {
    if ($null -ne $oracleProcess) {
        if (!$oracleProcess.HasExited) { $oracleProcess.Kill(); $oracleProcess.WaitForExit() }
        $oracleProcess.Dispose()
    }
    $resolvedTemp = (Resolve-Path -LiteralPath ([IO.Path]::GetTempPath())).ProviderPath.TrimEnd('\', '/')
    $resolvedOracle = (Resolve-Path -LiteralPath $oracleDirectory).ProviderPath.TrimEnd('\', '/')
    $tempPrefix = $resolvedTemp + [IO.Path]::DirectorySeparatorChar
    if (!$resolvedOracle.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetDirectoryName($resolvedOracle) -ne $resolvedTemp -or
        [IO.Path]::GetFileName($resolvedOracle) -notmatch '^ime-kr-oracle-[0-9a-fA-F-]{36}$') {
        throw "Refusing cleanup outside the intended temporary directory: $resolvedOracle"
    }
    Remove-Item -LiteralPath $resolvedOracle -Recurse -Force
}
