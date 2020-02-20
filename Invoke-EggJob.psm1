Function Invoke-EggJob {
  <#
  .SYNOPSIS
    Launches the spcified amounts of jobs, divides tasks evenly bewteen them and runs them concurrently.

  .DESCRIPTION
    Specify the amount of jobs, a variable or command to gather records and a scriptblock to run. Additional features include error log path, and reordering of records.

  .PARAMETER jobs
    Mandatory. Specify the amount of jobs that will be started.

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

  .PARAMETER skipNth
    Optional. Divides files among jobs by assigning array objects to jobs in a sequential order. 
    divides job records by skipping instead of assigning in order (can speed up some jobs) _

    Example: If you choose -jobs 4 and -skipnth 4

    job1 assigned records 0,3,7,11,15

    job2 assigned records 1,4,8,12,16

    job3 assigned records 2,5,9,13,17

    job4 assigned records 3,6,10,14,18

  .INPUTS
    Parameters above

  .OUTPUTS
    Records or items processed in parallel with a scriptblock you provide.

  .NOTES
    Version: 1.0.0
    Author: Eggs Toast Bacon
    Creation Date: 02/19/2020
    Purpose/Change: Initial function development.

  .EXAMPLE
    
    Ex: $myScriptBlock = {$math = $myjobvar + 6 | out-file c:\temp\math.txt -append}
  
    Invoke-EggJob -jobs 8 -int_records $items -scriptBlock $myscriptblock -errorlog C:\windows\temp
  
    Result is the number of items is divided by the number of jobs specified and each job is assigned an even workload.
    8 jobs run concurrently in parallel until their assigned workload is complete.
    Each $item in $items is added by 6 and the result output is appended to c:\temp\math.txt
    
  #>

  [CmdletBinding()]

  Param (
    [Parameter(Mandatory = $true, Position = 0)][string]$jobs,
    [Parameter(Mandatory = $false, Position = 1)][array]$int_records,
    [Parameter(Mandatory = $false, Position = 2)]$ext_records,
    [Parameter(Mandatory = $true, Position = 3)]$scriptBlock,
    [Parameter(Mandatory = $false, Position = 4)]$skipNth,
    [Parameter(Mandatory = $false, Position = 4)]$errorLog
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
    Start-Sleep 3
    Get-JobState
  }
  #Cleanup and stop the timer
  Remove-Job *  
  Clear-variable exp_records -ErrorAction SilentlyContinue
  Clear-variable int_records -ErrorAction SilentlyContinue
  $jobTimer.Stop()

  #Inform the user that the job is done and display elapsed time.  
  Write-Host ("All jobs are done. Time elapsed: " + $jobTimer.elapsed) -ForegroundColor Cyan
}
