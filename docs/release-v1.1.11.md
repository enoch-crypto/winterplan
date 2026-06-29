# WinterPlan v1.1.11 发版记录

## 版本定位

`v1.1.11` 是 Forgejo tag 自动发版增强版本。

## 已完成基础能力

`v1.1.10` 已经验证成功：

- 推送 `main` 后自动运行 Forgejo CI。
- 推送 `v*` tag 后自动运行 Forgejo CI。
- CI 能完成 Flutter 依赖安装、代码检查、测试和 APK 构建。

## 本版目标

让 tag 构建成功后，自动在 Forgejo 里创建 Release，并把 APK 上传到 Release 附件。

这样以后流程就是：

```text
提交代码
  -> 推送 main
  -> CI 自动检查和打包

打版本 tag
  -> CI 自动检查和打包
  -> Forgejo 自动生成 Release
  -> Release 页面可下载 APK
```

## 改动分类

### Feature / CI

- 新增 `Publish tag release APK` 步骤。
- 仅在 `refs/tags/v*` 触发时执行。
- 自动读取当前 tag 名称。
- 自动创建 Forgejo Release。
- 自动上传 `winterplan-版本号-debug.apk`。

## 验证目标

这一版预期验证：

- `main` 构建仍然成功。
- `v1.1.11` tag 构建成功。
- Forgejo Release 页面出现 `v1.1.11`。
- Release 附件中出现可下载 APK。
