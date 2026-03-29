
# 佩宇书屋 - GitHub Actions 打包指南

## 使用 GitHub Actions 自动打包

### 前置要求

1. 确保你的项目已推送到 GitHub 仓库
2. 确保仓库已启用 GitHub Actions（默认已启用）

### 使用步骤

#### 1. 推送代码到 GitHub

```bash
git add .
git commit -m "feat: 添加新功能"
git push origin main
```

#### 2. 自动触发打包

每次推送到 `main` 分支后，GitHub Actions 会自动开始构建 APK。

#### 3. 手动触发打包（可选）

也可以手动触发打包：

1. 打开 GitHub 仓库页面
2. 点击「Actions」标签
3. 选择「Build Android APK」工作流
4. 点击「Run workflow」
5. 选择分支并点击「Run workflow」

### 查看构建结果

#### 1. 下载 Artifacts

构建完成后：

1. 打开 GitHub 仓库页面
2. 点击「Actions」标签
3. 选择最新的工作流运行
4. 滚动到页面底部的「Artifacts」部分
5. 下载以下文件：
   - `PeiyuBookhouse-Debug-APK
   - `PeiyuBookhouse-Release-APK

#### 2. 查看 Release

推送到 main 分支后，还会自动创建 Release：

1. 打开 GitHub 仓库页面
2. 点击「Releases」标签
3. 下载最新的 Release
4. 在 Assets 部分下载 APK 文件

### 工作流说明

GitHub Actions 工作流会执行以下步骤：

1. 检出代码
2. 设置 Flutter 环境（3.22.2）
3. 安装依赖
4. 生成 Drift 数据库代码
5. 设置 JDK 17
6. 构建 Debug APK
7. 构建 Release APK
8. 上传 Artifacts
9. 创建 Release（仅 main 分支）

### 本地打包（备选方案）

如果需要本地打包，请确保已安装：

- Flutter SDK
- Android Studio / Android SDK
- Java JDK 17+

然后运行：

```bash
# Windows
build_scripts\build_android.bat

# Linux/macOS
chmod +x build_scripts/build_android.sh
./build_scripts/build_android.sh
```

### 常见问题

#### Q: 构建失败怎么办？

A: 检查 Actions 日志，查看具体错误信息。

#### Q: 如何签名 APK？

A: 当前工作流构建的是未签名 APK。如需签名，需要配置签名密钥并修改工作流。

#### Q: 可以构建 iOS 吗？

A: iOS 构建需要 macOS 环境和 Apple 开发者账号，当前工作流仅支持 Android。

## 项目结构

```
peiyu_bookhouse/
├── .github/
│   └── workflows/
│       └── build-android.yml    # GitHub Actions 工作流
├── build_scripts/
│   ├── build_android.bat    # Windows 打包脚本
│   ├── build_android.sh     # Linux/macOS 打包脚本
│   ├── build_ios.sh         # iOS 打包脚本
│   └── README.md          # 打包脚本说明
└── android/
├── lib/
└── pubspec.yaml
```
