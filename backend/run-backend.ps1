# Detect JAVA_HOME
if (Test-Path "C:\Program Files\Android\Android Studio1\jbr\bin\java.exe") {
    $env:JAVA_HOME = "C:\Program Files\Android\Android Studio1\jbr"
} elseif (Test-Path "C:\Users\user5\AppData\Roaming\Code\User\globalStorage\pleiades.java-extension-pack-jdk\java\17\bin\java.exe") {
    $env:JAVA_HOME = "C:\Users\user5\AppData\Roaming\Code\User\globalStorage\pleiades.java-extension-pack-jdk\java\17"
}

$javaCmd = "$env:JAVA_HOME\bin\java.exe"

# Automatically reverse port 8080 for any connected Android physical device
try {
    adb reverse tcp:8080 tcp:8080 2>$null
    Write-Host "[ADB] Port 8080 reversed for connected Android device" -ForegroundColor Cyan
} catch {}

Write-Host "Starting Spring Boot Electricity Billing Backend on port 8080..." -ForegroundColor Green
if (Test-Path "target\electricity-billing-backend-0.0.1-SNAPSHOT.jar") {
    & $javaCmd -Xmx384m -jar target\electricity-billing-backend-0.0.1-SNAPSHOT.jar
} else {
    $mvnCmd = "C:\Users\user5\.m2\wrapper\dists\apache-maven-3.9.16\0daed3be3ebd1c706f0e69e8b07c6b73f5cc4ea3dfce72a8d0ec2e849ca2ddb0\bin\mvn.cmd"
    & $mvnCmd spring-boot:run "-Dspring-boot.run.jvmArguments=-Xmx384m"
}


