@ECHO OFF
SET /P uname=Ingresa el nombre del entorno: 
	IF "%uname%"=="" GOTO Error

	SET NEWLINE=^& echo.
	FIND /C /I "%uname%.dev" %WINDIR%\system32\drivers\etc\hosts
	IF %ERRORLEVEL% NEQ 0 ECHO %NEWLINE%^127.0.0.1                   %uname%.dev>>%WINDIR%\system32\drivers\etc\hosts
	Pause
GOTO End
:Error
	ECHO Es indispensable el nombre del entorno
:End