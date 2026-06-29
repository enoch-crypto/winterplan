# WinterPlan v1.1.7 发版记录

## 版本定位

`v1.1.7` 是 Forgejo CI Flutter 环境自修复版本。

## 问题结论

纯 shell workflow 已经可以在 runner 上执行。

仓库 clone 成功。

失败发生在 `Install dependencies`，该步骤第一条 Flutter 命令未能继续。

## 改动分类

### Infrastructure / CI

- 在 workflow 中显式配置 Flutter PATH。
- 如果 runner 上没有 `flutter` 命令，自动 clone Flutter stable SDK 到 `/tmp/flutter-sdk`。
- 输出 `flutter --version`。
- 执行 `flutter doctor -v` 后再打包 APK，方便定位 Android SDK 问题。

## 当前目标

让 CI 至少进入 Flutter 依赖安装阶段，并把下一步环境问题直接暴露在日志中。
