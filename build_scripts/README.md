
# 佩宇书屋 - 打包脚本

## Android 打包

### Windows 系统

双击运行 `build_android.bat` 或在命令行执行：

```batch
build_scripts\build_android.bat
```

### Linux/macOS 系统

```bash
chmod +x build_scripts/build_android.sh
./build_scripts/build_android.sh
```

### 签名配置（可选）

如需签名打包，请在 `android/` 目录下创建 `key.properties` 文件：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=你的密钥别名
storeFile=密钥库文件路径 (例如: ../keystore.jks)
```

### 输出文件

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## iOS 打包

**注意：仅支持 macOS 系统，需要安装 Xcode**

```bash
chmod +x build_scripts/build_ios.sh
./build_scripts/build_ios.sh
```

### 构建选项

1. **模拟器版本** - 用于在模拟器上测试
2. **真机版本** - 用于在真机上测试
3. **IPA** - 用于分发或提交 App Store

## 混淆和调试信息

所有打包脚本默认启用：
- 代码混淆 (`--obfuscate`)
- 拆分调试信息 (`--split-debug-info=build/debug-info`)

调试信息保存在 `build/debug-info/` 目录，用于分析崩溃报告。
