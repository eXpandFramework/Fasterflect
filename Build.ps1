if (!(Get-Module XpandPwsh -ListAvailable)){
    Install-Module XpandPwsh -RequiredVersion 0.17.3 -Scope CurrentUser -AllowClobber -Force
}

Get-ChildItem *.sln -Recurse|ForEach-Object{
    dotnet build $_.FullName --configuration Release
    if ($LASTEXITCODE){
        throw
    }
}
Get-ChildItem *.nupkg -Recurse|ForEach-Object{
    $tempFolder="$env:TEMP\$($_.BaseName)"
    New-Item $tempFolder -ItemType Directory -Force
    $zipName="$($_.BaseName).zip"
    Copy-Item $_.FullName "$tempFolder\$zipName" -Force
    Expand-Archive "$tempFolder\$zipName" $tempFolder -Force
    Remove-Item "$tempFolder\$zipName"

    $sha=Get-GitLastSha "https://github.com/eXpandFramework/Fasterflect" master
    "sha=$sha"
    Get-ChildItem $tempFolder *.pdb -Recurse|ForEach-Object{
        Update-Symbols -pdb $_.FullName -TargetRoot "https://raw.githubusercontent.com/eXpandFramework/Fasterflect/$sha/" -SourcesRoot $PSScriptRoot
    }

    Compress-Archive "$tempFolder\*" "$tempFolder\$zipName" 
    Copy-Item "$tempfolder\$zipName" $_.FullName -Force
}
