#   Copyright 2023 Anthony Perkins
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

[string]$IsoTime = Get-Date -Date (Get-Date).ToUniversalTime() -UFormat "%Y%m%dT%H%M%SZ"
[string]$XmlPath = "$PSScriptRoot\xml"
[string]$ExportPath = "$PSScriptRoot\exports"
[bool]$CMPSSuppressFastNotUsedCheck = $true  # Disable lazy properties warning.

# Create folders if any are missing.
foreach ($d in @(
        "$XmlPath\task-sequence",
        "$XmlPath\application",
        "$ExportPath\task-sequence\$IsoTime"
        "$ExportPath\application\$IsoTime"
    )) {
    if (-Not (Test-Path -Path $d -PathType Container)) {
        New-Item -Path $d -ItemType Directory | Out-Null
    }
}

Write-Progress -Activity "Load SCCM data" -Status "Task Sequences" -PercentComplete (1/2*100)
$CMTaskSequences = Get-CMTaskSequence

Write-Progress -Activity "Load SCCM data" -Status "Applications" -PercentComplete (2/2*100)
$CMApplications = Get-CMApplication

[int]$i = 0
foreach ($t in $CMTaskSequences) {
    [string]$FileName = $t.Name
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
       $FileName = $FileName -replace [RegEx]::Escape($c), "_"
    }
    $Progress = (($i++ / $($CMTaskSequences.Count)) * 100)
    Write-Progress -Activity "Export Task Sequences" -Status $t.Name -PercentComplete $Progress
    # Pretty-print the XML by using the Windows XML parser to save it.
    $x = [xml]($t).Sequence
    $x.Save("$XmlPath\task-sequence\$FileName.xml")

    # Export the ZIP file in a timestamped folder so SCCM can import it.
    $t | Export-CMTaskSequence -Path "$ExportPath\task-sequence\$IsoTime\$FileName.zip" -WithContent:$false -WithDependence:$false
}

[int]$i = 0
foreach ($a in $CMApplications) {
    [string]$FileName = $a.LocalizedDisplayName
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
       $FileName = $FileName -replace [RegEx]::Escape($c), "_"
    }
    $Progress = (($i++ / $($CMApplications.Count)) * 100)
    Write-Progress -Activity "Export Applications" -Status $a.LocalizedDisplayName -PercentComplete $Progress
    # Pretty-print the XML by using the Windows XML parser to save it.
    $x = [xml]($a).SDMPackageXML
    $x.Save("$XmlPath\application\$FileName.xml")

    # Export the ZIP file in a timestamped folder so SCCM can import it.
    $a | Export-CMApplication -Path "$ExportPath\application\$IsoTime\$FileName.zip" -OmitContent -IgnoreRelated
}

# Write $IsoTime to a timestamp file
Set-Content -Path "$XmlPath\timestamp.txt" -Value $IsoTime
