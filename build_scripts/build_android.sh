
#!/bin/bash

echo "========================================"
echo "  佩宇书屋 - Android 打包脚本"
echo "========================================"
echo ""

cd "$(dirname "$0")/.."

echo "[1/4] 清理构建缓存..."
flutter clean
if [ $? -ne 0 ]; then
    echo "错误：清理构建缓存失败！"
    exit 1
fi

echo ""
echo "[2/4] 获取依赖..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "错误：获取依赖失败！"
    exit 1
fi

echo ""
echo "[3/4] 检查是否存在签名配置..."
SIGN_FLAG="--release"
if [ -f "android/key.properties" ]; then
    echo "找到签名配置，将进行签名打包"
else
    echo "未找到签名配置，将进行未签名打包"
    echo "提示：如需签名打包，请在 android/ 目录下创建 key.properties 文件"
fi

echo ""
echo "[4/4] 开始构建 APK..."
echo "构建选项：$SIGN_FLAG --obfuscate --split-debug-info=build/debug-info"
flutter build apk $SIGN_FLAG --obfuscate --split-debug-info=build/debug-info
if [ $? -ne 0 ]; then
    echo ""
    echo "错误：APK 构建失败！"
    exit 1
fi

echo ""
echo "========================================"
echo "  APK 构建成功！"
echo "========================================"
echo ""
echo "输出位置：build/app/outputs/flutter-apk/"
echo ""
ls -la "build/app/outputs/flutter-apk/"*.apk
echo ""

read -p "是否同时构建 AAB？(Y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "开始构建 AAB..."
    flutter build appbundle $SIGN_FLAG --obfuscate --split-debug-info=build/debug-info
    if [ $? -ne 0 ]; then
        echo ""
        echo "错误：AAB 构建失败！"
        exit 1
    fi
    echo ""
    echo "========================================"
    echo "  AAB 构建成功！"
    echo "========================================"
    echo ""
    echo "输出位置：build/app/outputs/bundle/"
    echo ""
    ls -la "build/app/outputs/bundle/"
fi

echo ""
echo "打包完成！"
