# Trouble Shooting

* Unable to update the Windows hosts file
  * If you are unable to update your Windows hosts file do the following:
    * **copy** `%WINDIR%\System32\drivers\etc\hosts` to a different location (i.e. Desktop)
  * Open the file with the editor of your choice
  * Make your changes and save the file in its curent location (_do not attepmt to 'Save As' back to the original location...it will fail_)
  * **copy** the updated file back to the original location (`%WINDIR%\System32\drivers\etc`)
