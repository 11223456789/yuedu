
#!/bin/bash

echo "========================================"
echo "  佩宇书屋 - iOS 打包脚本"
echo "========================================"
echo ""

# 检查是否在 macOS 环境
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "错误：iOS 打包需要在 macOS 环境下运行！"
    exit 1
fi

# 检查是否安装 Xcode
if ! command -v xcodebuild &amp;&gt; /dev/null; then
    echo "错误：未找到 Xcode，请先安装 Xcode！"
    exit 1
fi

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
echo "[3/4] 更新 CocoaPods 依赖..."
cd ios
pod install
if [ $? -ne 0 ]; then
    echo "警告：CocoaPods 安装失败，尝试更新..."
    pod repo update
    pod install
    if [ $? -ne 0 ]; then
        echo "错误：CocoaPods 安装失败！"
        exit 1
    fi
fi
cd ..

echo ""
echo "[4/4] 开始构建 iOS..."
echo ""
echo "请选择构建方式："
echo "1) 构建模拟器版本 (debug)"
echo "2) 构建真机版本 (release)"
echo "3) 构建 IPA (需要签名配置)"
read -p "请输入选项 (1-3): " -n 1 -r
echo ""

case $REPLY in
    1)
        echo "开始构建模拟器版本..."
        flutter build ios --debug --simulator
        ;;
    2)
        echo "开始构建真机版本..."
        flutter build ios --release
        ;;
    3)
        echo "开始构建 IPA..."
        flutter build ios --release
        if [ $? -eq 0 ]; then
            echo ""
            echo "iOS 构建成功！"
            echo ""
            echo "下一步："
            echo "1. 打开 Xcode: open ios/Runner.xcworkspace"
            echo "2. 配置签名证书和 Provisioning Profile"
            echo "3. Product -&gt; Archive"
            echo "4. Distribute App -&gt; Ad Hoc / App Store"
        fi
        ;;
    *)
        echo "无效选项！"
        exit 1
        ;;
esac

if [ $? -ne 0 ]; then
    echo ""
    echo "错误：iOS 构建失败！"
    exit 1
fi

echo ""
echo "========================================"
echo "  iOS 构建成功！"
echo "========================================"
echo ""
echo "输出位置：build/ios/"
echo ""
