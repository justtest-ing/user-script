@echo off
setlocal enabledelayedexpansion

:: Set output file and current folder
set "outputFile=filename-log.txt"
for /f %%i in ("%~dp0.") do set "currentFolder=%%~nxi"

:: Delete the output file if it exists to start with a clean slate
if exist "%outputFile%" del "%outputFile%" > nul 2>&1

:: Recursive function to traverse directories and write to output file
:traverse
for /d /r %%D in (*) do (
    > "temp.txt" echo ----------------------------
    >> "temp.txt" echo Files in the folder: %%~nxD
    >> "temp.txt" echo ----------------------------
    >> "temp.txt" dir /b /a-d "%%D\*" 2> nul | findstr /v /i "^$"
    >> "temp.txt" echo(
    type "temp.txt" >> "%outputFile%"
    del "temp.txt" > nul 2>&1
)
:: Check if there are more folders to traverse, and repeat the process until no more directories are found
for /d %%D in (*) do (
    cd /d %%~nxD
    goto :traverse
)
cd .. > nul 2>&1

:: Output message and delete the script after it finishes running
echo Output file: "%outputFile%"
set "scriptPath=%~f0"
del "%scriptPath%" > nul 2>&1
exit

:: This code will traverse directories recursively, list files in each directory and write the output to a log file. 
:: After execution, it also deletes itself for cleanup. 
:: Please note that error messages are redirected to `nul` to hide any unnecessary clutter. 
:: Also, this script is assuming you're running it from a folder where you have the necessary permissions to navigate through subfolders and files.
