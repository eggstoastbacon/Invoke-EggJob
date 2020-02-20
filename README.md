https://www.powershellgallery.com/packages/Invoke-EggJob/

  
  .SYNOPSIS
    Launches the spcified amounts of jobs, divides tasks evenly between them and runs them concurrently.

  .DESCRIPTION
    Specify the amount of jobs, a variable or command to gather records and a scriptblock to run. Additional features include error log     path, and reordering of records.

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
    
    Ex: 
    $items = (1..2500)

    $myScriptBlock = {$math = $myjobvar + 6 | out-file c:\temp\math_$x.txt -append}
  
    Invoke-EggJob -jobs 8 -int_records $items -scriptBlock $myscriptblock -errorlog C:\windows\temp
  
    Result is the number of items is divided by the number of jobs specified and each job is assigned an even workload.
    8 jobs run concurrently in parallel until their assigned workload is complete.
    Each $item in $items is added by 6 and the result output is appended to c:\temp\math_[job#].txt
    
  #>
