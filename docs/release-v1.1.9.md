# WinterPlan v1.1.9 发版记录

## 版本定位

`v1.1.9` 是 Forgejo CI 打包环境修复版本。

## 问题结论

`v1.1.8` 已经通过：

- 拉取仓库代码
- 安装 Flutter 依赖
- 静态检查
- 自动测试

失败点：

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
Gradle task assembleDebug failed with exit code 1
```

含义：

Flutter 项目打 Android APK 时，会调用 Gradle。
Gradle 是 Android 打包工具链的一部分，它需要 JDK。
Forgejo runner 上的 Android SDK 已经存在，但 Java 运行环境没有被正确识别，所以 APK 打包失败。

## 改动分类

### CI / Build

- 新增 `Setup JDK` 步骤。
- 优先使用 runner 机器已有的 JDK 17。
- 如果机器没有 JDK 17，自动下载临时 JDK 17。
- 按 Mac 芯片架构选择 JDK：
  - Apple Silicon 使用 `aarch64`
  - Intel 使用 `x64`
- 将 `JAVA_HOME` 写入 `android/gradle.properties`，保证 Gradle 使用同一份 JDK。
- 后续 Flutter 命令统一把 `JAVA_HOME/bin` 加入执行路径。

## 验证目标

这一版预期验证：

- `flutter doctor -v` 能识别 Java。
- `flutter build apk --debug` 能进入真正的 Android 打包流程。
- CI 能产出 `app-debug.apk`。

## 后续计划

如果 APK 构建成功，下一步处理：

- 将 APK 保存为 Forgejo Actions artifact。
- tag 发版时自动把 APK 挂到 Forgejo Release。
