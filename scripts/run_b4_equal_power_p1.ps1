param(
    [string]$FormalSNRGrid = '16,20,24,28,32,36,40',
    [switch]$SkipFormal
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Runner = Join-Path $ProjectRoot 'scripts/run_matlab_local.ps1'
$V2Root = Join-Path $ProjectRoot '16QAM_Polar/v2'
$Experiment = 'experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m'
$Strategies = @('uniform_p05','uniform_p03','uniform_p01','good_channel_information','good_channel_energy_shaping','bad_channel_energy_only')
$CalibrationSNR = '16,20,24,28,32,36,40'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$P1Root = Join-Path (Join-Path $V2Root 'results') ($stamp + '_b4_equal_power_p1')
New-Item -ItemType Directory -Path $P1Root | Out-Null
$TranscriptPath = Join-Path $P1Root 'orchestration_log.txt'
Start-Transcript -Path $TranscriptPath | Out-Null

function Invoke-P1Job([string]$Tag,[string]$Mode,[int]$Seed,[int]$Realizations,[int]$Frames,[string]$Snr,[double[]]$Scales,[string]$PowerMode,[bool]$Authorized=$false,[string]$ResumeDir='') {
    $scaleText = ($Scales | ForEach-Object { $_.ToString('R',[Globalization.CultureInfo]::InvariantCulture) }) -join ','
    $formalText = if ($Authorized) { 'true' } else { 'false' }
    $resumeField = if ($ResumeDir) { ",'resume_dir','$($ResumeDir.Replace('\','/'))'" } else { '' }
    $statement = "b4_strict_overrides=struct('run_mode','$Mode','result_tag','$Tag','seed',$Seed,'snr_grid',[$Snr],'num_realizations',$Realizations,'num_frames',$Frames,'min_frames',$Frames,'target_errors',1000000000,'max_frames',$Frames,'formal_authorized',$formalText,'power_mode','$PowerMode','strategy_scales',[$scaleText]$resumeField); run('$Experiment')"
    Write-Host "Starting $Tag (mode=$Mode, seed=$Seed, channels=$Realizations, frames=$Frames, SNR=[$Snr])"
    $output = & $Runner $statement 2>&1 | ForEach-Object {
        $text=$_.ToString(); Write-Host $text
        if ($text -match '^Output:\s*(.+)$') { Set-Content -Encoding UTF8 -LiteralPath (Join-Path $P1Root "current_${Tag}_dir.txt") -Value $Matches[1].Trim() }
        $text
    }
    $jobExit=$LASTEXITCODE
    if ($jobExit -ne 0) { throw "MATLAB job failed: $Tag (exit $jobExit). Checkpoint directory is recorded under current_${Tag}_dir.txt." }
    $line = ($output | ForEach-Object { $_.ToString() } | Where-Object { $_ -match '^Saved to:' } | Select-Object -Last 1)
    if (-not $line) { throw "MATLAB job did not report output path: $Tag" }
    return ($line -replace '^Saved to:\s*','').Trim()
}
function Mean-Column($Rows,[string]$Column) {
    $values = @($Rows | ForEach-Object { [double]::Parse($_.$Column,[Globalization.CultureInfo]::InvariantCulture) })
    if ($values.Count -eq 0) { throw "No observations for column $Column" }
    return ($values | Measure-Object -Average).Average
}
function Read-Rows([string]$Dir) {
    $file = Join-Path $Dir 'b4b_repetition_results.csv'
    if (-not (Test-Path -LiteralPath $file)) { throw "Missing repetition CSV: $file" }
    return @(Import-Csv -LiteralPath $file)
}
try {
    $scales = @(1,1,1,1,1,1)
    $budgetList = @(12,24,46,92) # per candidate SNR; 84/168/322/644 frames per seed
    $powerAudit = @()
    $validated = $false
    for ($attempt=0; $attempt -lt $budgetList.Count; $attempt++) {
        $frames = $budgetList[$attempt]
        $calibration = @()
        foreach ($seed in @(7001,7002,7003)) {
            $tag = "p1_cal${frames}_$seed"
            $existing = Get-ChildItem -LiteralPath (Join-Path $V2Root 'results') -Directory | Where-Object { $_.Name -like "*_$tag" } | Sort-Object Name -Descending | Select-Object -First 1
            if ($existing) { $dir = $existing.FullName } else { $dir = Invoke-P1Job $tag 'calibration' $seed 1 $frames $CalibrationSNR @(1,1,1,1,1,1) 'legacy' }
            $calibration += Read-Rows $dir
        }
        $scales = @()
        foreach ($strategy in $Strategies) {
            $rows = @($calibration | Where-Object { $_.strategy -eq $strategy })
            $meanPower = Mean-Column $rows 'tx_ofdm_time_power'
            if ($meanPower -le 0) { throw "Nonpositive calibration power for $strategy" }
            $scale = [Math]::Sqrt(1.0 / $meanPower)
            $scales += $scale
            $powerAudit += [pscustomobject]@{attempt=$attempt+1;frames_per_snr=$frames;total_frames_per_seed=$frames*7;stage='calibration';strategy=$strategy;mean_time_power=$meanPower;scale=$scale;seed_set='7001,7002,7003'}
        }
        $validationRows = @()
        $validationSeeds = @((7101 + 10*$attempt),(7102 + 10*$attempt),(7103 + 10*$attempt))
        foreach ($seed in $validationSeeds) {
            $validationTag = "p1_power_validation_a$($attempt+1)_$seed"
            $existingValidation = Get-ChildItem -LiteralPath (Join-Path $V2Root 'results') -Directory | Where-Object { $_.Name -like "*_$validationTag" } | Sort-Object Name -Descending | Select-Object -First 1
            if ($existingValidation) { $dir = $existingValidation.FullName }
            else { $dir = Invoke-P1Job $validationTag 'calibration' $seed 1 12 $CalibrationSNR $scales 'equal_time_power' }
            $validationRows += Read-Rows $dir
        }
        $maxDeviation = 0.0
        foreach ($strategy in $Strategies) {
            $rows = @($validationRows | Where-Object { $_.strategy -eq $strategy })
            $meanPower = Mean-Column $rows 'tx_ofdm_time_power'
            $deviation = [Math]::Abs($meanPower - 1.0)
            $maxDeviation = [Math]::Max($maxDeviation,$deviation)
            $powerAudit += [pscustomobject]@{attempt=$attempt+1;frames_per_snr=12;total_frames_per_seed=84;stage='validation';strategy=$strategy;mean_time_power=$meanPower;scale=($scales[[array]::IndexOf($Strategies,$strategy)]);seed_set=($validationSeeds -join ',')}
        }
        if ($maxDeviation -le 0.01) { $validated=$true; break }
        Write-Warning "Power validation deviation $maxDeviation exceeds 1%; recalibrating with a larger independent sample."
    }
    $powerAudit | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'power_calibration_validation.csv')
    if (-not $validated) { throw 'Frozen strategy coefficients failed the 1% independent power gate after 640 calibration frames per channel.' }
    $scaleCsv = for ($i=0; $i -lt $Strategies.Count; $i++) { [pscustomobject]@{strategy=$Strategies[$i];amplitude_scale=$scales[$i];target_time_power=1.0} }
    $scaleCsv | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'frozen_strategy_scales.csv')

    $pilotDir = Invoke-P1Job 'p1_equal_power_pilot_seed42' 'pilot' 42 5 2 '16,20,24,28,32,36,40' $scales 'equal_time_power'
    Copy-Item -LiteralPath (Join-Path $pilotDir 'b4b_repetition_results.csv') -Destination (Join-Path $P1Root 'pilot_repetitions.csv')
    $formalGrid = @($FormalSNRGrid.Split(',') | ForEach-Object { [double]::Parse($_,[Globalization.CultureInfo]::InvariantCulture) })
    $missingHistorical = @(@(20,24,28,32,36,40) | Where-Object { $_ -notin $formalGrid })
    if ($formalGrid.Count -lt 6 -or $missingHistorical.Count -gt 0) {
        throw 'Formal grid must include the historical six SNR labels 20–40 dB.'
    }
    $pilotRows = @(Import-Csv -LiteralPath (Join-Path $pilotDir 'b4b_repetition_results.csv'))
    $pilotDirs = @($pilotDir)
    $pilotWindow = @()
    $getPilotWindow = {
        param($Rows)
        $window = @()
        foreach ($snr in @($Rows | Select-Object -ExpandProperty snr_dB -Unique)) {
            $atSNR = @($Rows | Where-Object { [double]$_.snr_dB -eq [double]$snr })
            if (@($atSNR | Where-Object { [double]$_.ber -ge 1e-4 -and [double]$_.ber -le 1e-1 }).Count -gt 0) { $window += [double]$snr }
        }
        return @($window)
    }
    $pilotWindow = & $getPilotWindow $pilotRows
    if ($pilotWindow.Count -eq 0) {
        $allHigh = @($pilotRows | Where-Object { [double]$_.ber -gt 0.1 }).Count -eq $pilotRows.Count
        $allLow = @($pilotRows | Where-Object { [double]$_.ber -lt 1e-4 }).Count -eq $pilotRows.Count
        if (-not $allHigh -and -not $allLow) { throw 'Pilot has mixed out-of-window errors; define an intermediate pilot grid before formal execution.' }
        $extension = if ($allHigh) { @(44,48) } else { @(12,8) }
        foreach ($snr in $extension) {
            $pilotGrid = @((16,20,24,28,32,36,40) + @($extension | Where-Object { $_ -le $snr -and $allLow -or $_ -ge $snr -and $allHigh }))
            $pilotGrid = @($pilotGrid | Sort-Object -Unique)
            $tag = "p1_equal_power_pilot_seed42_extend_$snr"
            $extraDir = Invoke-P1Job $tag 'pilot' 42 5 2 (($pilotGrid -join ',')) $scales 'equal_time_power'
            $pilotDirs += $extraDir
            $extraRows = @(Import-Csv -LiteralPath (Join-Path $extraDir 'b4b_repetition_results.csv'))
            $pilotRows += $extraRows
            $pilotWindow = & $getPilotWindow $pilotRows
            Copy-Item -LiteralPath (Join-Path $extraDir 'b4b_repetition_results.csv') -Destination (Join-Path $P1Root "pilot_extend_$snr.csv")
            if ($pilotWindow.Count -gt 0) { break }
        }
        if ($pilotWindow.Count -eq 0) { throw 'Expanded pilot through 8–48 dB did not localize the waterfall; formal run withheld.' }
    }
    $pilotRows | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'pilot_repetitions_all.csv')
    $formalGrid = @($formalGrid + @($pilotWindow))
    $formalGrid = @($formalGrid | Sort-Object -Unique)
    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'FROZEN_GRID.txt') -Value @(
        'Pilot seed=42; 5 Rayleigh realizations x 2 frames; candidate grid starts at 16:4:40 dB and expands by 4 dB toward the needed side if no waterfall point is found.',
        "Pilot waterfall labels with any strategy BER in [1e-4,1e-1]: $($pilotWindow -join ',') dB.",
        "Formal grid frozen before formal results: $($formalGrid -join ',') dB.",
        'The grid retains historical 20–40 dB labels. Pilot is only a grid-selection screen, not final performance evidence.'
    )
    if (-not $SkipFormal) {
        $resumeNote = @(
            'If MATLAB is interrupted, use the directory from current_b4_equal_power_p1_formal_dir.txt as resume_dir.',
            "MATLAB override: b4_strict_overrides=struct('run_mode','formal','result_tag','b4_equal_power_p1_formal','seed',3142,'snr_grid',[$($formalGrid -join ',')],'num_realizations',30,'num_frames',50,'min_frames',50,'target_errors',1000000000,'max_frames',50,'formal_authorized',true,'power_mode','equal_time_power','strategy_scales',[$(($scales | ForEach-Object { $_.ToString('R',[Globalization.CultureInfo]::InvariantCulture) }) -join ',')],'resume_dir','<saved-directory>'); run('$Experiment')"
        )
        Set-Content -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'RESUME_COMMAND.txt') -Value $resumeNote
        $formalDir = Invoke-P1Job 'b4_equal_power_p1_formal' 'formal' 3142 30 50 (($formalGrid -join ',')) $scales 'equal_time_power' $true
        Set-Content -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'FORMAL_RESULT_PATH.txt') -Value $formalDir
        $analysisStatement = "analyze_b4_equal_power_p1('$($P1Root.Replace('\','/'))')"
        $analysisOutput = & $Runner $analysisStatement 2>&1
        $analysisOutput | ForEach-Object { Write-Host $_.ToString() }
        if ($LASTEXITCODE -ne 0) { throw 'P1 post-analysis failed; formal raw data and checkpoints are retained.' }
        Write-Host "P1 formal output: $formalDir"
    }
    $hashFiles = @(
        (Join-Path $PSScriptRoot 'run_b4_equal_power_p1.ps1'),
        (Join-Path $ProjectRoot '16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m'),
        (Join-Path $ProjectRoot '16QAM_Polar/v2/experiments/multicarrier/analyze_b4_equal_power_p1.m')
    )
    $hashLines = foreach ($file in $hashFiles) { (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash + '  ' + (Resolve-Path -LiteralPath $file).Path }
    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'sha256_manifest.txt') -Value $hashLines
    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $P1Root 'README.txt') -Value @(
        'Fixed-16QAM equal-average-transmit-time-power P1 orchestration.',
        "P1 orchestration root: $P1Root", 'Power includes CP and padding; strategy coefficients are globally frozen.',
        'Complex time-domain noise power is N0=target_time_power/10^(SNR_dB/10). The OFDM helper takes post-FFT real sigma, so sigma_freq=sqrt(Nsc*N0/2) and converts to time sigma=sigma_freq/sqrt(Nsc).',
        'Formal protocol: seed3142, 30 channel realizations, 50 frames per realization/strategy/SNR, common channel/noise/message seeds.',
        'Calibration and validation run directories are recorded in orchestration_log.txt.',
        'RF power is an input to rectifier research, not DC output. BLER is information-block error rate, not CRC packet failure.',
        'Zero-error points retain total error count and information-bit denominator; the summary also reports the Poisson 95% upper bound when total errors are zero.',
        'Historical comparison uses the 2026-09-17 legacy unequal-power run only as context; it is not paired and is not a significance test.'
    )
    Write-Host "P1 orchestration artifacts: $P1Root"
}
finally { Stop-Transcript | Out-Null }


