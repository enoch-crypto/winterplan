# WinterPlan v1.1.6 发版记录

## 版本定位

`v1.1.6` 是 Forgejo CI 纯 shell 构建版本。

## 问题结论

runner smoke workflow 成功，说明 runner 可以执行 shell step。

Flutter APK workflow 使用外部 `uses:` action 时卡在 `Set up job`。

## 改动分类

### Infrastructure / CI

- 移除 Flutter APK workflow 里的所有 `uses:` action。
- 改为纯 shell 步骤：
  - `git clone` 仓库到 `/tmp/winterplan-ci`
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
  - 输出 APK 路径

## 当前目标

先确认 runner 可以完成 APK 构建。

artifact 上传后续再补。
