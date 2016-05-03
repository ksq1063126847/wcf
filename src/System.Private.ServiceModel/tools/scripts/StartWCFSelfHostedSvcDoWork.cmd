@if "%_echo%" neq "on" echo off
setlocal

REM This script should always be called from StartWCFSelfHostedSvc.cmd

set _setuplog=%~dp0..\..\..\..\SelfHostedWcfServiceSetup.log

echo Preparing to launch the WCF self hosted service

REM Build tools
echo Building the WCF Self hosted service...
call %~dp0BuildWCFSelfHostedService.cmd >>%_setuplog% 
SET __EXITCODE=%ERRORLEVEL%
if NOT [%__EXITCODE%]==[0] (
    echo ERROR: An error occurred while building WCF Self hosted Service. >>%_setuplog%
    goto :done
  )
  
echo Building the certificate generator ...
call %~dp0BuildCertUtil.cmd >>%_setuplog%
set __EXITCODE=%ERRORLEVEL%
if NOT [%__EXITCODE%]==[0] (
    echo ERROR: An error occurred while building the Certificate generator. >>%_setuplog%
    goto :done
  )

REM Config Certs
REM we need the direcotry to save the test.crl file. We are investigate a way to get rid of it
md c:\wcftest
REM Certificate configuration errors are all non fatal currently because we non cert tests will still pass
echo Generating certificates ...
%~dp0..\..\..\..\bin\Wcf\tools\CertificateGenerator\CertificateGenerator.exe >>%_setuplog%
if NOT [%ERRORLEVEL%]==[0] (
    echo Warning: An error occurred while running certificate generator. >>%_setuplog%
  )

echo Configuring firewall...
call %~dp0OpenFirewallPorts.cmd >>%_setuplog%
if NOT [%ERRORLEVEL%]==[0] (
    echo Warning: An error occurred while running certificate generator. >>%_setuplog%
  )

echo Configuring Https ports...
powershell -NoProfile -ExecutionPolicy unrestricted %~dp0ConfigHttpsPort.ps1 >>%_setuplog%
if NOT [%ERRORLEVEL%]==[0] (
    echo Warning: An error occurred while configuration https port. >>%_setuplog%
  )

REM
REM Start the self hosted WCF Test Service
echo Starting the WCF Self hosted service...
call %~dp0..\..\..\..\bin\Wcf\tools\SelfHostedWcfService\SelfHostedWcfService.exe
set __EXITCODE=%ERRORLEVEL%

:Cleanup
echo Cleaning up after the Self hosted service has completed
call %~dp0CleanUpWCFSelfHostedSvc.cmd
:done

exit /b %__EXITCODE%
