# WinterPlan v1.1.2 发版记录

## 版本定位

`v1.1.2` 是 Forgejo CI 兼容性修复版本。

目标是让每次推送代码或推送 `v*` tag 后，Forgejo Actions 自动构建 Android APK。

## 改动分类

### Infrastructure / CI

- 将 workflow 的 runner 标签从 `docker` 调整为 `ubuntu-latest`。
- 保留 Flutter 容器 `ghcr.io/cirruslabs/flutter:stable`，让构建环境自带 Flutter 和 Android 构建工具。
- 将 artifact 上传动作从 `actions/upload-artifact@v4` 改为 `actions/upload-artifact@v3`。

## 为什么这样改

Forgejo runner 通过标签匹配任务。

`runs-on: docker` 只有在 runner 注册了 `docker` 标签时才会运行。

`ubuntu-latest` 是 Forgejo runner 常见兼容标签，更适合作为默认 CI 入口。

Forgejo 官方文档提示 artifact 上传需要使用 v3 或 patched v4；这里先选 v3，降低兼容风险。

## 当前目标流程

```text
push main 或 push v* tag
  -> Forgejo Actions
  -> 匹配 ubuntu-latest runner
  -> 启动 Flutter 容器
  -> flutter pub get
  -> flutter analyze
  -> flutter test
  -> flutter build apk --debug
  -> 上传 winterplan-debug-apk
```

## 仍需确认

- Forgejo 仓库 Actions 是否启用。
- Forgejo runner 是否在线。
- runner 是否包含 `ubuntu-latest` 标签。
- runner 是否允许使用 Docker 容器。
