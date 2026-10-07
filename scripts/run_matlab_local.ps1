param([Parameter(Mandatory=$true)][string]$Statement)
# Windows CLI equivalent of run_matlab.sh, using the installed MATLAB runtime.
$projectPath = Split-Path -Parent $PSScriptRoot
$v2Path = (Join-Path $projectPath '16QAM_Polar/v2').Replace("'", "''")
$matlabCommand = Get-Command matlab -ErrorAction Stop
& $matlabCommand.Source -batch "cd('$v2Path'); setup_paths; $Statement;"
exit $LASTEXITCODE
