# WinterPlan v1.1.0 发版记录

## 版本基线

- `v1.0.0`：原始可用版本，作为本次优化前的基线。
- `v1.1.0`：第一次架构优化版本。

## 改动分类

### Architecture

- 新增 `lib/models/study_models.dart`，把日程、作业、学科作业、每日日志模型从 `main.dart` 拆出。
- 新增 `lib/services/storage_service.dart`，统一管理本地存储 key、读取、写入和清理。
- `AppState` 开始通过 `StorageService` 访问本地数据，减少状态层直接依赖存储细节。
- 新增 `.forgejo/workflows/flutter-apk.yml`，提供 tag / push 后自动构建 APK 的 Forgejo Actions CI 示例。

### Bugfix

- 修复编辑日程弹窗中的“删除”按钮无实际删除效果的问题。

### Patch / UX

- 新增日程时间格式校验，要求输入类似 `09:00 - 11:45`。
- 新增日程表单必填校验，避免空标题、空内容、空图标。
- 打卡提交后增加成功提示，明确展示本次学习分钟数、完成度和质量评分。
- 设置页版本号更新为 `1.1.0`。

## 本地测试环境

目标测试方式：

```bash
flutter pub get
flutter run -d chrome
flutter run -d macos
```

当前机器缺少 `flutter` 和 `dart` 命令，暂时无法在本机完成运行验证。

环境检查结果：

```text
flutter not found
dart not found
java found
git found
```

## APK 构建

目标构建方式：

```bash
flutter build apk --debug
flutter build apk --release
```

当前机器缺少 Flutter SDK，APK 构建需要在安装 Flutter 后继续执行。

本次已补充 Forgejo Actions 构建流程。推送代码或 tag 后，CI 会尝试自动执行：

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Tag 与 CI 原理记录

- Tag：给某一次代码状态贴上版本标签，例如 `v1.0.0`、`v1.1.0`。
- CI：自动构建流水线。代码提交或打 tag 后，Forgejo runner 自动下载依赖、检查代码、运行测试、打包 APK，并输出构建产物。

典型 CI 流程：

```text
push / tag
  -> Forgejo Actions
  -> use Flutter container
  -> flutter pub get
  -> flutter analyze
  -> flutter test
  -> flutter build apk
  -> upload artifact
```
