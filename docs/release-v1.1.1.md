# WinterPlan v1.1.1 发版记录

## 版本定位

`v1.1.1` 是 `v1.1.0` 之后的 CI / Infrastructure patch。

这次不改业务功能，重点是把自动构建流程从 GitHub Actions 迁移到 Forgejo Actions。

## 改动分类

### Infrastructure / CI

- 删除 `.github/workflows/flutter-apk.yml`。
- 新增 `.forgejo/workflows/flutter-apk.yml`。
- Forgejo Actions 使用 Flutter Docker 容器执行构建，避免 runner 必须提前安装 Flutter。

## Forgejo CI 流程

```text
push / tag
  -> Forgejo Actions
  -> Flutter container
  -> flutter pub get
  -> flutter analyze
  -> flutter test
  -> flutter build apk --debug
  -> upload APK artifact
```

## Forgejo 服务地址

```text
https://github.mindstacklab.ai/
```

后续推送还需要配置完整仓库地址，例如：

```text
https://github.mindstacklab.ai/<owner>/winterplan.git
```

## 说明

`v1.1.0` 是第一次架构优化版本。

`v1.1.1` 只处理 CI 平台迁移，因此使用 patch 版本号。
