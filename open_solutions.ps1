Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#Point to where your instance of visual studio is located

#2019
#$vs_work_directory = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE"

#2022
$vs_work_directory = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE"

#Point to where your storewise repo is
$repo_path = "C:\path\to\source\control"

#If you don't want to input every time, set these to default open projects
$default_projects = @(5,6,4)

#form variables
$form_width = 400
$form_height = 700
#labels
$label_x = 10
$label_y = 20
$label_width = $form_width - ($label_x * 3)
$label_height = 20
#buttons
$button_width = 75
$button_height = 20
$ok_button_x = ($form_width - $button_width) * .75 #Place ok button 3/4 of the way to the right
$cancel_button_x = ($form_width - $button_width) * .25 #Place cancel button 1/4 of the way to the right
$button_y = ($form_height - $button_height) * .90 #Place buttons 10% from the bottom
#Listbox
$list_x = 10
$list_y = 40
$list_width = $form_width - ($list_x * 3)
$list_height = $form_height * .75

#Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Open Solutions'
# $form.AutoSize = $true
# $form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$form.Size = New-Object System.Drawing.Size($form_width,$form_height)
$form.StartPosition = 'CenterScreen'
#ok button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point($ok_button_x,$button_y)
$okButton.Size = New-Object System.Drawing.Size($button_width,$button_height)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)
#cancel 
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point($cancel_button_x, $button_y)
$cancelButton.Size = New-Object System.Drawing.Size($button_width,$button_height)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
#labels
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point($label_x,$label_y)
$label.Size = New-Object System.Drawing.Size($label_width,$label_height)
$label.Text = "Select Projects: (Shift + Click) or (Ctrl + Click) to select multiple."
$form.Controls.Add($label)
#list 
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point($list_x,$list_y)
$listBox.Size = New-Object System.Drawing.Size($list_width,$list_height)
$listBox.SelectionMode = 'MultiExtended'


function Get-ProjectObjectArray([string[]]$ProjectFolders){
    foreach($path in $ProjectFolders)
    {
        $project_name = [System.IO.Path]::GetFileNameWithoutExtension($path)
        $solution_path = "$path\$(Get-ChildItem -Path $path -Filter *.sln -File -Name)" | Resolve-Path
        [PSCustomObject]@{
            ProjectName=$project_name; 
            SolutionPath=$solution_path
        }
    }
}

function Show-UserProjectOptions([PSCustomObject[]]$ProjectObjectArray){
    #Show options to user
    $ProjectObjectArray | ForEach-Object {[void] $listBox.Items.Add($_.ProjectName)}
    # $listBox.Height = $list_height
    $form.Controls.Add($listBox)
    $form.Topmost = $true
}

function Get-UserInput{
    #Get User input
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        return $listBox.SelectedItems
    }
}

function Open-ProjectSolutions(
    [string]$Process, 
    [string]$WorkingDirectory,
    [string]$ArgumentList
    ) {
    Start-Process $Process -WorkingDirectory $WorkingDirectory -ArgumentList $ArgumentList
}

function GoTime{
    $vs_process = $vs_work_directory + '/devenv.exe'
    $project_folders = "$repo_path\*" | Resolve-Path
    $project_object_array = Get-ProjectObjectArray -ProjectFolders $project_folders
    Show-UserProjectOptions -ProjectObjectArray $project_object_array
    $selected_projects = Get-UserInput
    if($selected_projects.count -ne 0)
    {
        $filtered = $project_object_array | Where { $selected_projects -contains $_.ProjectName }
        if($filtered.count -ne 0)
        {
            foreach($solution_path in $filtered.SolutionPath)
            {
                Open-ProjectSolutions -Process $vs_process -WorkingDirectory $vs_work_directory -ArgumentList $solution_path
            }
        }
        
    }
    
    # foreach($project in $selected_projects){
    #     $project_int = $project -as [int]
    #     $argument_list = $project_object_array[$project_int].SolutionPath
    # }
}

GoTime
stop-process -Id $PID


