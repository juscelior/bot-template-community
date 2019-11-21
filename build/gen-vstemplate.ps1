# Author: Juscélio Reis
function Append-node {
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $fullName,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $name,
         [Parameter(Mandatory=$true, Position=2)]
         [xml] $vstemplate,
         [Parameter(Mandatory=$true, Position=3)]
         [string] $xdNS,
         [Parameter(Mandatory=$false, Position=4)]
         [int] $depth
    )
    
    [System.Xml.XmlNode]$item = $null
    if((Get-Item $fullName) -is [System.IO.DirectoryInfo]){
        $item = $vstemplate.CreateNode("element","Folder",$xdNS)
        $item.SetAttribute("Name",$name)
        $item.SetAttribute("TargetFolderName",$name)
        #$vstemplate.VSTemplate.TemplateContent.Project.AppendChild($folder)
    }elseif(!$f.Name.EndsWith('.csproj')){
        $item = $vstemplate.CreateNode("element","ProjectItem",$xdNS)
        $item.SetAttribute("ReplaceParameters","true")
        $item.SetAttribute("TargetFileName",$name)
        $item.AppendChild($vstemplate.CreateTextNode($name))
        #$vstemplate.VSTemplate.TemplateContent.Project.AppendChild($projectItem)
    }

    [System.Collections.ArrayList]$names = @()
    
    $files = Get-ChildItem $fullName -Recurse | Select-Object Name, FullName

    foreach ($f in $files) {
        if((Get-Item $f.FullName) -is [System.IO.DirectoryInfo]){
            $sub = Append-node -fullName $fullName -name $name -vstemplate $vstemplate -xdNS $xdNS -depth ($depth + 1)
            $item.AppendChild($sub)
        }else{
            $subItem = $vstemplate.CreateNode("element","ProjectItem",$xdNS)
            $subItem.SetAttribute("ReplaceParameters","true")
            $subItem.SetAttribute("TargetFileName",$f.Name)
            $subItem.AppendChild($vstemplate.CreateTextNode($f.Name))
            $item.AppendChild($subItem)
        }
    }

    if($depth -eq 0){
        $vstemplate.VSTemplate.TemplateContent.Project.AppendChild($item)
    }

    return $item
}

#onlylocal
$PSScriptRoot = 'Z:\dev\bot-template\Bot.Template.Community\build'
# Update NuGet package version
$projectName = 'Bot.Template.Community'
$FullPath = Resolve-Path $PSScriptRoot\..\src
$buildDir = Resolve-Path $FullPath\..\build

New-Item -Path $buildDir.Path -Name "template" -ItemType "directory"

$templateDir = Resolve-Path $FullPath\..\build\template
$ignore = @('bin', 'Bot.Template.Community', 'obj', '*.sln', '.*', '*.cache')


$projects = Get-ChildItem $FullPath -Exclude $ignore | Select-Object Name, FullName

Copy-Item -Path ($buildDir.Path + '/__TemplateIcon.ico') -Destination ($templateDir.Path + '/__TemplateIcon.ico') -Recurse -Force
Copy-Item -Path ($buildDir.Path + '/Bot.Template.Community.vstemplate') -Destination ($templateDir.Path + '/Bot.Template.Community.vstemplate') -Recurse -Force

#
[xml]$content = Get-Content ($templateDir.Path + '/Bot.Template.Community.vstemplate')
$xdNS = $content.DocumentElement.NamespaceURI

$customParameter = $content.CreateNode("element","CustomParameter",$xdNS)
$customParameter.SetAttribute("Name","`$safeprojectname`$")
$customParameter.SetAttribute("Value",$projectName)

$customParameters = $content.CreateNode("element","CustomParameters",$xdNS)
$customParameters.AppendChild($customParameter)

$content.VSTemplate.TemplateContent.AppendChild($customParameters)

foreach ($p in $projects) {
    $files = Get-ChildItem $p.FullName | 
                Where-Object{$_.Name -notin $ignore} | 
                Select-Object Name, FullName
    
    New-Item -Path $templateDir.Path -Name $p.Name -ItemType "directory"

    $projectTemplateLink = $content.CreateNode("element","ProjectTemplateLink",$xdNS)
    $projectTemplateLink.SetAttribute("ProjectName","`$projectname`$" + ($p.Name -replace $projectName,""))
    $projectTemplateLink.SetAttribute("CopyParameters","True")
    $projectTemplateLink.AppendChild($content.CreateTextNode($p.Name+"\MyTemplate.vstemplate"))
    
    $content.VSTemplate.TemplateContent.ProjectCollection.SolutionFolder.AppendChild($projectTemplateLink)

    #
    Copy-Item -Path ($buildDir.Path + '/__TemplateIcon.ico') -Destination ($templateDir.Path + '/' + $p.Name) -Recurse -Force
    Copy-Item -Path ($buildDir.Path + '/MyTemplate.vstemplate') -Destination ($templateDir.Path + '/' + $p.Name) -Recurse -Force

    [xml]$vstemplate = Get-Content ($templateDir.Path + '/' + $p.Name + '/MyTemplate.vstemplate')
    $xdNS = $vstemplate.DocumentElement.NamespaceURI
    $vstemplate.VSTemplate.TemplateData.Description = $p.Name
    $vstemplate.VSTemplate.TemplateContent.Project.SetAttribute("TargetFileName",$p.Name+'.csproj')
    $vstemplate.VSTemplate.TemplateContent.Project.SetAttribute("File",$p.Name+'.csproj')

    foreach($f in $files){
        
        Copy-Item -Path $f.FullName -Destination ($templateDir.Path + '/' + $p.Name) -Recurse -Force -Exclude $ignore  

        if((Get-Item $f.FullName) -is [System.IO.DirectoryInfo]){          
            Append-node -fullName $f.FullName -name $f.Name -vstemplate $vstemplate -xdNS $xdNS
            #$vstemplate.VSTemplate.TemplateContent.Project.AppendChild($node)
        }elseif(!$f.Name.EndsWith('.csproj')){
            $projectItem = $vstemplate.CreateNode("element","ProjectItem",$xdNS)
            $projectItem.SetAttribute("ReplaceParameters","true")
            $projectItem.SetAttribute("TargetFileName",$f.Name)
            $projectItem.AppendChild($vstemplate.CreateTextNode($f.Name))

            $vstemplate.VSTemplate.TemplateContent.Project.AppendChild($projectItem)
        }elseif($f.Name.EndsWith('.csproj')){
            ((Get-Content -path ($templateDir.Path + '/' + $p.Name + '/' + $f.Name) -Raw) -replace $projectName,"`$ext_safeprojectname`$") | Set-Content -Path ($templateDir.Path + '/' + $p.Name + '/' + $f.Name)
        }
    }
    
    $vstemplate.Save(($templateDir.Path + '/' + $p.Name + '/MyTemplate.vstemplate'))
}

$content.Save(($templateDir.Path + '/Bot.Template.Community.vstemplate'))


Add-Type -assembly "system.io.compression.filesystem"

$zipPath = ($FullPath.Path + '\Bot.Template.Community\ProjectTemplates\' + $projectName + '.zip')

New-Item -Path ($FullPath.Path + '\Bot.Template.Community') -Name "ProjectTemplates" -ItemType "directory"

$FileExists = Test-Path $zipPath

If ($FileExists -eq $True) {
    Remove-Item –path $zipPath
}

[io.compression.zipfile]::CreateFromDirectory($templateDir, $zipPath)




        
    