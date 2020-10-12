
param (
    [Parameter(Mandatory=$false, Position=0)]
    [String] $currentDateTimeFormat,
    [Parameter(Mandatory=$false, Position=1)]
    [String] $newDateTimeFormat
    
)

Function Invoke-RenameDatesApplication()
{
    Write-ProgramIntro

    Write-Host "Select a directory you would like to refactor the containing file names for"
    [System.IO.DirectoryInfo] $dir = Get-Folder

    if([string]::IsNullOrEmpty($currentDateTimeFormat))
    {
        $currentDateTimeFormat = Read-Host "Please provide the current date time format"
    }

    if([string]::IsNullOrEmpty($newDateTimeFormat))
    {
       $newDateTimeFormat = Read-Host "Please provide the new date time format"
    }

    #$itemsA = Create-RefactorItems($dir, $("(\d{1,4}([.\-/_])\d{1,2}([.\-/_])\d{1,4})"), $currentDateTimeFormat, $refactoredDateTimeFormat)
    $items = [RefactorItem]::new($dir, $("(\d{6,8})"), $currentDateTimeFormat, $newDateTimeFormat)

    Write-Host($("Found ") + $($items.files.Count) + $(" file(s) containing a date in the file name in ") + $dir)

    if($items.files.Count -gt 0)
    {
        $filesChanged = Update-FileNames $items
        Write-Host $("Program complete with ") $filesChanged $( "file(s) changes") 
    }

}

Class RefactorItem
{
    [System.IO.DirectoryInfo] $directory
    [string] $regEx
    [string] $currentDateTimeFormat
    [string] $refactoredDateTimeFormat
    [System.Collections.ArrayList] $files

    RefactorItem($directory, $regEx, $currentDateTimeFormat, $refactoredDateTimeFormat)
    {
        $this.directory = $directory
        $this.regEx = $regEx
        $this.currentDateTimeFormat = $currentDateTimeFormat
        $this.refactoredDateTimeFormat = $refactoredDateTimeFormat
        $this.files  = Get-FileInfoExtended $this.directory $this.currentDateTimeFormat $this.regEx   
    }
}

Class FileInfoExtended
{
    [System.IO.FileInfo] $fileInfo
    [String] $dateString
    [DateTime] $date
    [String] $newFileName
}
Function Update-FileNames
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [RefactorItem] $refactorItem
    )

    $items = [System.Collections.ArrayList]@()
    foreach($item in $refactorItem.files)
    {
        $newDateString = $item.date.ToString($refactorItem.refactoredDateTimeFormat)
        $item.NewFileName = $item.fileInfo.Name.Replace($item.dateString, $newDateString)
        
        $obj = new-object psobject -Property @{
            Path = $item.fileInfo.DirectoryName
            OldFileName = $item.fileInfo.Name
            NewFileName  = $item.NewFileName
        }
        $items += $obj
    }

    Write-Host "Please review the changes below: "
    $changedItems = $items | Out-String 
    Write-Host $changedItems
    $confirmation = Read-Host "Press Y to confirm"
    if($confirmation.ToLower() -eq "y")
    {
        foreach($item in $refactorItem.files)
        {
            Rename-Item -Path $item.fileInfo.FullName -NewName $item.newFileName
        }
        return $refactorItem.files.Count
    }
    return 0 
    
}

Function Get-FileInfoExtended
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [System.IO.DirectoryInfo] $directory,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $dateTimePattern,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $regEx
    )

    $fileInfos = [System.Collections.ArrayList]@()
    $files = Get-ChildItem -Path $directory.FullName -Recurse | Where-Object { $_.Name -match $regEx }
    foreach ($file in $files) {
        [DateTime] $date = $file.CreationTime
        $dateString = [regex]::matches($file.Name, $regEx).Value
        if([DateTime]::TryParseExact($datestring, $dateTimePattern, [System.Globalization.CultureInfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::None, [ref] $date ))
        {
            $fie = [FileInfoExtended]::new()
            $fie.dateString = $dateString
            $fie.date = $date
            $fie.fileInfo = $file
            #Must use += as Add function would not work
            $fileInfos += $fie
        }
    }
    #comma before the object for arrays ensures an array type is provided back instead of it "unrolling" on its own
    return ,$fileInfos
}

Function Get-Folder($initialDirectory="")

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog 
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder = Get-Item $foldername.SelectedPath
    }
    return  $folder
}


Function Write-ProgramIntro
{
    $initInstrutions = $("Welcome to FileSystem Refactoring by Volare Consulting © ") + $((Get-Date).Year)
    Write-Host $initInstrutions

    Write-Host("This program requires you to provide a date time string pattern.`r
If you are unfamiliar with DateTime.ToString(),`r
please review how to define the pattern here:`r
https://docs.microsoft.com/en-us/dotnet/api/system.datetime.tostring?view=netcore-3.1")
}

Invoke-RenameDatesApplication
