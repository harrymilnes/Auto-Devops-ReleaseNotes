# Automatic Azure Pipeline Release Notes Generation

## Important

* Developers must change their workflows so that Pull requests include associated tickets (Probably worth putting in DevOps as a branch policy)

## Release Notes To Custom API

### Prerequisites

* An API that can process markdown text in someway, there's an example in ./src
* Install GenerateReleaseNotes within DevOps > https://marketplace.visualstudio.com/items?itemName=richardfennellBM.BM-VSTS-XplatGenerateReleaseNotes

### Pipeline Setup
* Create a release Generate Release Notes task with a handle bars template, there's an example in ./src/
* Create a powershell task with the following script to post to an API endpoint
 
## Powershell Task

    #Variables
    $projectName = '$(System.TeamProject)'
    $environmentName = '$(Release.EnvironmentName)'
    $buildNumber = '$(Build.BuildNumber)'
    $uri = ('http://localhost:7071/api/release-notes/{0}}/{1}}/{2}' -f $projectName, $environmentName, $buildNumber)
    $content = [IO.File]::ReadAllText("$(System.DefaultWorkingDirectory)\releasenotes.md")
    
    #Post to API
    $params = @{
    'Uri' = $url
    'Method' = 'Post'
    'ContentType' = 'application/json; charset=utf-8'
    'body' = @{content = $content; } | ConvertTo-Json
    }
    
    Invoke-RestMethod @params

---

### Release Notes To Azure Project Wiki

### Prerequisites

* Install GenerateReleaseNotes within DevOps > https://marketplace.visualstudio.com/items?itemName=richardfennellBM.BM-VSTS-XplatGenerateReleaseNotes
* A PAT Token that has Wiki:Read & Write scopes
* Create a base Wiki page for your project called Release Notes/
* Developers must change their workflows so that Pull requests include associated tickets

### Wiki Setup

* Within the project view 'Overview'
* Add a page called 'Release Notes'
* Create a sub-page within 'Release Notes' for each environment you plan to generate release notes for, Eg. "Production"

### Pipeline Setup
* Create a release Generate Release Notes task with a handle bars template, there's an example in ./src/
* Create a powershell task with the following script to post to the Azure Wiki API endpoint

## Powershell script

    #Variables
    $organizationName = '<Insert Organisation Name>'
    $projectName = '$(System.TeamProject)'
    $wikiName = '$(System.TeamProject)' + '.wiki'
    $parentPage = 'Release Notes/' + '$(Release.EnvironmentName)'
    $title = '$(Release.DeploymentID)' + ' - ' + '[' + '$(Build.BuildNumber)' + ']'
    $wikiPatToken = '<Insert Wiki PAT Token>'
    $content = [IO.File]::ReadAllText("$(System.DefaultWorkingDirectory)\releasenotes.md")
    $uri = ('https://dev.azure.com/{0}/{1}/_apis/wiki/wikis/{2}/pages?path={3}/{4}&api-version=5.0' -f $organizationName, $projectName, $wikiName, $parentPage, $title)

    #Post to Project Wiki
    $header = @{
    'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$wikiPatToken"))
    }
        
    $params = @{
    'Uri' = $uri
    'Headers' = $header
    'Method' = 'Put'
    'ContentType' = 'application/json; charset=utf-8'
    'body' = @{content = $content; } | ConvertTo-Json
    }

    Invoke-RestMethod @params

## Further Notes

**Tip for finding Organization Name > If your dev.azure url is https://dev.azure.com/milnes-corp/milnesdotorg/ then your Organization name would be 'milnes-corp'**

**Tip for finding Project Name > If your dev.azure url is https://dev.azure.com/milnes-corp/milnesdotorg/ then your Project name would be 'milnesdotorg'**

**When testing make sure there are changes between builds as releasing the same build twice in a row might where there are no changes will produce an empty release note**

**A list of sample release note templates can be found here: https://github.com/rfennell/AzurePipelines/tree/main/SampleTemplates/XplatGenerateReleaseNotes%20%28Node%20based%29/Version%203**
