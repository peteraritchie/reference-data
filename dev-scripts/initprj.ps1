[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory=$true, HelpMessage="Enter name of project to create")]
    [ValidateScript({
        if ($_ -match "(?<=^| )(?!\d)\w+|(?<= )(?!\d)\w+(?= |$)") {
            $true
        } else {
            throw "$_ is not a valid C$([char]0x266f) identifier"
        }
    })]
    [Alias("p")]
    [string]$Project,
    [Parameter()]
    [bool]$RemoveExisting=$false
)

function Update-ProjectMetaData{
    param($ProjectFile)
    $projectName = Split-Path $projectFile -Leaf -Resolve
    $projectName = $ProjectName.Substring(0, $ProjectName.LastIndexOf('.'))

    $temp = Join-Path -path (Split-Path $projectFile -resolve) -ChildPath "__temp__.csproj"
    $Author = "Peter Ritchie"
    $VersionPrefix = "0.1.0"
    $VersionSuffix = "prerelease"
    foreach($line in Get-Content ($ProjectFile)) {
        if($line -match "^\s*\</PropertyGroup\>\s*$"){
            out-file -filepath $temp -InputObject "    <PackageId>PRI.$($projectName)</PackageId>" -Append
            out-file -filepath $temp -InputObject "    <VersionPrefix>$($VersionPrefix)</VersionPrefix>" -Append
            out-file -filepath $temp -InputObject "    <VersionSuffix>$($VersionSuffix)</VersionSuffix>" -Append
            out-file -filepath $temp -InputObject "    <Authors>$($Author)</Authors>" -Append
            out-file -filepath $temp -InputObject "    <Company>$($Author)</Company>" -Append
            out-file -filepath $temp -InputObject "    <GeneratePackageOnBuild>true</GeneratePackageOnBuild>" -Append
        }
        out-file -filepath $temp -InputObject $line -Append
    }
}

if (test-path -path $project)
{
    if($RemoveExisting)
    {   Remove-Item -path $project -recurse}
    else
    {   Write-Output "\"$(project)\" exists as a folder, use -RemoveExisting to automatically remove the folder and all its contents"}
}

mkdir "$($project)\src"
mkdir "$($project)\docs"
mkdir "$($project)\tools"
mkdir "$($project)\lib"
mkdir "$($project)\build"

dotnet new sln -o ".\$($project)\src" $( @{$true='--dry-run'; false = ''}[$WhatIfPreference -eq $true] )
Rename-Item -Path ".\$($project)\src\src.sln" -NewName "$($project).sln"

Set-Location "$($project)\src"

dotnet new classlib -o $project $( @{$true='--dry-run'; false = ''}[$WhatIfPreference -eq $true] )

Set-Location $project

Update-ProjectMetaData -ProjectFile ".\$($project).csproj"

<#
foreach($line in Get-Content ".\$($project).csproj") {
    if($line -match "^\s*\</PropertyGroup\>\s*$"){
        out-file -filepath _temp_.csproj -InputObject "    <PackageId>PRI.$($project)</PackageId>" -Append
        out-file -filepath _temp_.csproj -InputObject "    <Version>0.1.0</Version>" -Append
        out-file -filepath _temp_.csproj -InputObject "    <Authors>Peter Ritchie</Authors>" -Append
        out-file -filepath _temp_.csproj -InputObject "    <Company>Peer Ritchie</Company>" -Append
        out-file -filepath _temp_.csproj -InputObject "    <GeneratePackageOnBuild>true</GeneratePackageOnBuild>" -Append
    }
    out-file -filepath _temp_.csproj -InputObject $line -Append
}
#>
rename-item -Path ".\$($project).csproj" -NewName ".\$($project).csproj.bkp"
rename-item -Path .\_temp_.csproj -NewName ".\$($project).csproj"
#dotnet pack
#dotnet clean
Set-Location ..

dotnet sln ".\$($project).sln" add ".\$($project)\$($project).csproj"  $( @{$true='--dry-run'; false = ''}[$WhatIfPreference -eq $true] )

if($WhatIfPreference=$false)
{
    dotnet new xunit -o .\Tests $( @{$true='--dry-run'; false = ''}[$WhatIfPreference -eq $true] )
}
else {
    Write-Output dotnet new xunit -o .\Tests $( @{$true='--dry-run'; false = ''}[$WhatIfPreference -eq $true] )
}
dotnet sln ".\$($project).sln" add ".\Tests\Tests.csproj" $( @{$true='--dry-run'; false = ''}[$WhatIfPreference -eq $true] )

dotnet build $( @{$true='--dry-run'; false = ''}[$WhatIfPreference -eq $true] )



Set-Location ..\..
$ver