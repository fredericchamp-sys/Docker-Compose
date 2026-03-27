@echo off
REM -----------------------------------------------------------------------------
REM kafka-topics.bat
REM Run Kafka TopicCommand on Windows
REM -----------------------------------------------------------------------------

SETLOCAL

REM Set JAVA_HOME if not already set
IF NOT DEFINED JAVA_HOME (
    echo Please set JAVA_HOME environment variable.
    exit /b 1
)

REM Set Kafka home (adjust if needed)
SET KAFKA_HOME=%~dp0\..

REM Build classpath with all Kafka libraries
SET CLASSPATH=%KAFKA_HOME%\libs\*

REM Run the TopicCommand class with any arguments passed
"%JAVA_HOME%\bin\java" -cp "%CLASSPATH%" ^
  -Dlog4j.configuration=file:%KAFKA_HOME%\config\log4j.properties ^
  kafka.admin.TopicCommand %*

ENDLOCAL
