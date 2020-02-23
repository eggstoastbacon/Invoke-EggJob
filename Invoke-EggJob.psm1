Function Invoke-EggJob {
  <#
.SYNOPSIS
  Launches the specified amounts of jobs, divides tasks evenly between them and runs them concurrently.
 
.DESCRIPTION
  Specify the amount of jobs, a variable or command to gather records and a scriptblock to run.
  Additional features include error log path, and reordering of records.
  If your scriptblock will output a file append $x to the file name. Optional Throttling of threads per job.
  Output is stored in the variable $global:myJobData
  Example: $global:myJobData | export-csv c:\temp\myData.csv, or $global:myJobData | outfile-csv c:\temp\myData.txt
 
.PARAMETER jobs
  Mandatory. Specify the amount of jobs that will be started. The $x variable refers to the job number while running.
 
.PARAMETER int_records
  Mandatory. Provide an array of records, such as $items, or $items[0..2500]
 
.PARAMETER exp_records
  Optional. Provide an expression that results in an array of records. Use this instead on Int_Records.
 
.PARAMETER scriptBlock
  Mandatory. Provide a scriptblock to run against the provided array. Scriptblocks are closed in single quotes or parenthesis.
  Use $myJobVar as the reference.
 
  Ex: $myScriptBlock = {$math = $myjobvar + 6 | out-file c:\temp\math.txt -append}
 
.PARAMETER errorLog
  Optional. Provide an error logging path such as "c:\windows\temp"
 
.PARAMETER combinePath
  Required for Combine.
  Together with CombineSrcName, this will combine all output files into one file.
  ex: "c:\temp"
  Specify the path of your output, this must be referenced in your scriptblock as your output destination.
 
.PARAMETER combineSrcName
  Required for Combine, you must tell the script what your unique output file name is, ex: "exportdata".
  This must be the part of the file name you are using to to output in your scriptblock. Function Invoke-EggJob {
  <#
.SYNOPSIS
  Launches the specified amounts of jobs, divides tasks evenly between them and runs them concurrently.
 
.DESCRIPTION
  Specify the amount of jobs, a variable or command to gather records and a scriptblock to run.
  Additional features include error log path, and reordering of records.
  If your scriptblock will output a file append $x to the file name.
 
.PARAMETER jobs
  Mandatory. Specify the amount of jobs that will be started. The $x variable refers to the job number while running.
 
.PARAMETER int_records
  Mandatory. Provide an array of records, such as $items, or $items[0..2500]
 
.PARAMETER exp_records
  Optional. Provide an expression that results in an array of records. Use this instead on Int_Records.
 
.PARAMETER scriptBlock
  Mandatory. Provide a scriptblock to run against the provided array. Scriptblocks are closed in single quotes or parenthesis.
  Use $myJobVar as the reference.
 
  Ex: $myScriptBlock = {$math = $myjobvar + 6 | out-file c:\temp\math.txt -append}
 
.PARAMETER errorLog
  Optional. Provide an error logging path such as "c:\windows\temp"
 
.PARAMETER combinePath
  Required for Combine.
  Together with CombineSrcName, this will combine all output files into one file.
  ex: "c:\temp"
  Specify the path of your output, this must be referenced in your scriptblock as your output destination.
 
.PARAMETER combineSrcName
  Required for Combine, you must tell the script what your unique output file name is, ex: "exportdata".
  This must be the part of the file name you are using to to output in your scriptblock.
  ex: out-file c:\temp\exportdata_$x
 
.PARAMETER combineDestName
  Optional. Set the name of the combined file, default is "combined"
 
.PARAMETER skipNth
  Optional. Divides files among jobs by assigning array objects to jobs in a sequential order.
  divides job records by skipping instead of assigning in order (can speed up some jobs) _
 
  Example: If you choose -jobs 4 and -skipnth 4
 
  job1 assigned records 0,3,7,11,15
 
  job2 assigned records 1,4,8,12,16
 
  job3 assigned records 2,5,9,13,17
 
  job4 assigned records 3,6,10,14,18

    .PARAMETER importFunctions
  Parameter code by: u/PowerShellMichael
  Import one or more declared functions into your scriptblock, will be added to your scriptblock just before the job runs.
  Example:

  Function Demo-Function(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $ParameterName
    )
    Write-Output $ParameterName
}

Function Demo2-Function(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $ParameterName
    )
    Write-Output $ParameterName
}

$scriptblock = {
    
    $random = get-random
    $toast = "toast"
    
   Demo-Function -ParameterName Demo
   Demo2-Function -ParameterName Demo2
}

Invoke-EggThread -jobs 4 -throttle 4 -int_records $items -importFunctions 'Demo-Function','Demo2-Function' -scriptBlock $scriptblock
 
.INPUTS
  Parameters above
 
.OUTPUTS
  Records or items processed in parallel with a scriptblock you provide. Output variable is $global:myJobData
 
.NOTES
  Version: 1.2.0
  Author: Eggs Toast Bacon
  importFunction parameter code by: u/PowerShellMichael
  Creation Date: 02/19/2020
  Purpose/Change: Better $global:MyJobData examples.
 
.EXAMPLE
   
  Ex A:
  $items = (1..2500)
 
  $myScriptBlock = {$math = $myjobvar + 6 | out-file c:\temp\math_$x.txt -append}
 
  Invoke-EggJob -jobs 8 -int_records $items -scriptBlock $myscriptblock -errorlog C:\windows\temp
 
  Result is the number of items is divided by the number of jobs specified and each job is assigned an even workload.
  8 jobs run concurrently in parallel until their assigned workload is complete.
  Each $item in $items is added by 6 and the result output is appended to c:\temp\math_[job#].txt
 
  #############
 
  Ex B:
   
  $items = (1..2500)
 
  $myScriptBlock = {$math = $myjobvar + 6 | out-file c:\temp\mydata_$x.txt -append}
 
  Invoke-EggJob -jobs 8 -int_records $items -scriptBlock $myscriptblock -errorLog "C:\temp" -combinePath "c:\temp" -combineSrcName "mydata" -combineDestName "combo"
 
  Result is the number of items is divided by the number of jobs specified and each job is assigned an even workload.
  8 jobs run concurrently in parallel until their assigned workload is complete.
  Each $item in $items is added by 6 and the result output is appended to c:\temp\math_[job#].txt
  All files are combined into a file named [random number]combo.txt
#>

  [CmdletBinding()]

  Param (
      [Parameter(Mandatory = $true, Position = 0)][string]$jobs,
      [Parameter(Mandatory = $false, Position = 1)][array]$int_records,
      [Parameter(Mandatory = $false, Position = 2)]$ext_records,
      [Parameter(Mandatory = $true, Position = 3)]$scriptBlock,
      [Parameter(Mandatory = $false, Position = 4)]$skipNth,
      [Parameter(Mandatory = $false, Position = 5)]$errorLog,
      [Parameter(Mandatory = $false, Position = 6)]$combinePath,
      [Parameter(Mandatory = $false, Position = 7)]$combineSrcName,
      [Parameter(Mandatory = $false, Position = 8)]$combineDestName = "combined"    
  )
    
  #Starts the timer of this function.
  $jobTimer = [system.diagnostics.stopwatch]::StartNew()

  #Function to monitor the status of the jobs.
  Function Get-JobState {
      $jobStatus = Get-Job * | Select-Object State | ForEach ( { $_.State })
      if ("Running" -in $jobStatus) { $global:finished = $false }else { $global:finished = $true }
  }

  #Function to round down numbers with decimals.
  Function Get-RoundedDown($d, $digits) {
      $scale = [Math]::Pow(10, $digits)
      [Math]::Truncate($d * $scale) / $scale
  }

  #define how to hand records
  if ($int_records) {
      $records = $int_records
  }
  if ($exp_records) {
      $records = Invoke-Expression $exp_records
  }

  #The skipnth option requires soem magic
  if ($skipNth) {
      $vars = (1..$skipNth)
      foreach ($var in $vars)
      { New-Variable -Name ("job_" + $var + "_array") -Value @() }

      $jobVarNames = Get-Variable | Where-Object { $_.Name -like "*_array*" -and $_.Name -like "*Job*" }
    
      while ($records.count -gt 0) {
          try {
              foreach ($jobVar in $jobVarNames) {
                  $sVarString = ("$" + $jobVar.name + " += `$records[0]") | Out-String
                  Invoke-Expression $sVarString
                  $records = $records | Select-Object -skip 1
              }
          }
          catch { }
      }

      foreach ($jobVar in $jobVarNames) {
          $sVarString = ("`$records += $" + $jobVar.name) | Out-String
          Invoke-Expression $sVarString
      }
  }

  #Determine how the array should be divided uo between jobs
  $y = 0..($jobs - 1)  
  $items = Get-RoundedDown ($records.count / $y.count)
  if (($records.count / $y.count) -like "*.*") { $items = $items + 1 }

  #Make variable unique so that it doesn't interfere with variables that may be running in the scriptblock, don't use variables with "Egg" in it to be safe :).
  $itemsEgg = $items
  $scriptBlockEgg = $scriptBlock
  $recordsEgg = $records
  $cache_dirEgg = $cache_dir
  $errorLogEgg = $errorLog
  $recCount = $records.count

  #Display some information about the jobs that will be running
  write-host ([string]$recCount + " items found, each of the " + $jobs + " jobs will run around " + $items + " items each.") -foregroundcolor cyan
  
  #Create the jobs
  ForEach ($x in $y) {
      Start-Job -Name ([string]$x + "_eggjob") -ScriptBlock {
        
          param ([string]$x, [int]$itemsEgg, $recordsEgg, $scriptBlockEgg, $cache_dirEgg, $errorLogEgg) 
      
          #Actually assign the array to the jobs
          if ($x -eq 0) { $aEgg = 0 } else { $aEgg = (([int]$itemsEgg * $x) + 1) }               
          $bEgg = (([int]$itemsEgg * $x) + [int]$itemsEgg)                              
          $xrecordsEgg = $recordsEgg[[int]$aEgg..[int]$bEgg] 
          $scriptBlockEgg = [Scriptblock]::Create($scriptBlockEgg)

          #The job now has work to do..
          foreach ($myJobVar in $xrecordsEgg) {
              try {
                  Invoke-Command $scriptBlockEgg
              }
              catch {
                  #If an error log is defined
                  if ($errorLogEgg) {
                      $_.Exception.Message | out-file ($errorLogEgg + "\errorEggJob_" + $x + ".txt") -append
                  }
              }     
          }  
      } -ArgumentList ($x, $itemsEgg, $recordsEgg, $scriptBlockEgg, $cache_dirEgg, $errorLogEgg)
  }

  #Monitor the state of the jobs throughout the duration of the work.
  Get-JobState
  while ($global:finished -eq $false) {
      Start-Sleep 1
      Get-JobState
  }
  $global:myJobData = get-job | Receive-Job
  #Cleanup and stop the timer
  Remove-Job *  

  #Combined files if specified
  if ($combinePath -and $CombineSrcName) {
      $aRandom = get-random
      $renameFiles = Get-ChildItem $combinePath | where-object { $_.name -like "*$combineSrcName*" }
      ForEach ($renameFile in $renameFiles ) {
          $combineFileType = $renameFile.Name.split(".")[1]
          Rename-Item -Force ("$combinePath\" + $renameFile.Name) ("$combinePath\" + $aRandom + $renameFile.Name) 
      } 
  }


  if ($combinePath -and $CombineSrcName) { 
      if ($combineFileType -notlike "*csv*") {
          $bRandom = get-random
          $procFiles = Get-ChildItem $combinePath | where-object { $_.name -like "*$aRandom*" } | Select-Object Name
          ForEach ($procFile in $procFiles) {
              Get-Content -path ("$combinePath\" + $procfile.Name) | 
              Out-File ($combinePath + "\" + $bRandom + "-" + $combineDestName + "." + $combineFileType) -append
          } 
      }
  
      if ($combineFileType -like "*csv*") {
          $bRandom = get-random
          $CSVCombine = @()
          $procFiles = Get-ChildItem $combinePath | where-object { $_.name -like "*$aRandom*" } | Select-Object FullName
              ForEach ($procFile in $procFiles) {
              $CSVCombine += Import-CSV -path ($procfile.FullName) 
          }
          $CSVCombine | Export-CSV ($combinePath + "\" + $bRandom + "-" + $combineDestName + "." + $combineFileType) -NoTypeInformation -Append
          
      }
      Get-ChildItem $combinePath | where-object { $_.name -like "*$aRandom*" } | remove-item
  }
  $jobTimer.Stop()
  #Inform the user that the job is done and display elapsed time.
  Write-Host ("All jobs are done. Time elapsed: " + $jobTimer.elapsed) -ForegroundColor Cyan
    
}
