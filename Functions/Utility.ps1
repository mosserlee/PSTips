<#
 .Synopsis
   Create a new profile if it is nonexistent.
#>
function New-Profile
{
    if (-not (Test-Path $PROFILE) )
    {
      ([io.fileinfo]$PROFILE).Directory.Create()
      '' | Out-File $PROFILE
      if(Test-Path $PROFILE)
      {
        Write-Host "profile created£¡"
     }
  }
    else
    {
      Write-Host "profile exsits."
    }
}