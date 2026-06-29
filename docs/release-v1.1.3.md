# WinterPlan v1.1.3 发版记录

## 版本定位

`v1.1.3` 是 Forgejo runner 标签匹配修复版本。

## 问题结论

Forgejo Actions 已触发，但任务一直等待。

页面提示：

```text
没有匹配标签的在线运行器：ubuntu-latest
```

仓库当前可用 runner：

```text
AgentCredMint-macOS-Direct-Host
标签：
- agent-credmint-macos-apple-direct
- agent-credmint-macos-intel-direct
状态：空闲
```

## 改动分类

### Infrastructure / CI

- 将 workflow 的 `runs-on` 从 `ubuntu-latest` 改为 `agent-credmint-macos-intel-direct`。
- 移除 Flutter Docker container 配置，让任务直接在现有 macOS runner 上执行。

## 当前目标流程

```text
push main 或 push v* tag
  -> Forgejo Actions
  -> 匹配 agent-credmint-macos-intel-direct runner
  -> flutter pub get
  -> flutter analyze
  -> flutter test
  -> flutter build apk --debug
  -> 上传 winterplan-debug-apk
```

## 后续观察点

- 如果 runner 没有 Flutter，构建会在 `flutter pub get` 失败。
- 如果 runner 没有 Android SDK，构建会在 `flutter build apk --debug` 失败。
