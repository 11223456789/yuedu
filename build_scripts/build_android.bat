
@echo off
echo ========================================
echo   佩宇书屋 - Android 打包脚本
echo ========================================
echo.

cd /d "%~dp0.."

echo [1/4] 清理构建缓存...
call flutter clean
if %errorlevel% neq 0 (
    echo 错误：清理构建缓存失败！
    exit /b 1
)

echo.
echo [2/4] 获取依赖...
call flutter pub get
if %errorlevel% neq 0 (
    echo 错误：获取依赖失败！
    exit /b 1
)

echo.
echo [3/4] 检查是否存在签名配置...
if exist "android\key.properties" (
    echo 找到签名配置，将进行签名打包
    set SIGN_FLAG=--release
) else (
    echo 未找到签名配置，将进行未签名打包
    echo 提示：如需签名打包，请在 android/ 目录下创建 key.properties 文件
    set SIGN_FLAG=--release
)

echo.
echo [4/4] 开始构建 APK...
echo 构建选项：%SIGN_FLAG% --obfuscate --split-debug-info=build\debug-info
call flutter build apk %SIGN_FLAG% --obfuscate --split-debug-info=build\debug-info
if %errorlevel% neq 0 (
    echo.
    echo 错误：APK 构建失败！
    exit /b 1
)

echo.
echo ========================================
echo   APK 构建成功！
echo ========================================
echo.
echo 输出位置：build\app\outputs\flutter-apk\
echo.
dir /b "build\app\outputs\flutter-apk\*.apk"
echo.
echo 是否同时构建 AAB？(Y/N)
set /p BUILD_AAB=
if /i "%BUILD_AAB%"=="Y" (
    echo.
    echo 开始构建 AAB...
    call flutter build appbundle %SIGN_FLAG% --obfuscate --split-debug-info=build\debug-info
    if %errorlevel% neq 0 (
        echo.
        echo 错误：AAB 构建失败！
        exit /b 1
    )
    echo.
    echo ========================================
    echo   AAB 构建成功！
    echo ========================================
    echo.
    echo 输出位置：build\app\outputs\bundle\
    echo.
)

echo.
echo 打包完成！
pause
