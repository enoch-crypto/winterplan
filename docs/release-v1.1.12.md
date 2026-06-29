# WinterPlan v1.1.12 发版记录

## 版本定位

`v1.1.12` 是 Forgejo Release 上传权限修复版本。

## 问题结论

`v1.1.11` 的 APK 构建已经成功，但 Release 上传失败：

```text
FORGEJO_TOKEN is missing.
```

含义：

Forgejo Actions 没有自动给工作流提供可用于创建 Release 的 token。
要让 CI 自动创建 Release 并上传 APK，需要在仓库 Actions Secrets 中配置一个专用令牌。

## 已完成配置

- 已创建 Forgejo 访问令牌：`winterplan-ci-release`。
- 已将令牌保存到仓库 Actions Secret：`RELEASE_TOKEN`。

## 改动分类

### Patch / CI

- `Publish tag release APK` 步骤改为读取 `${{ secrets.RELEASE_TOKEN }}`。
- Release 上传脚本只使用 `RELEASE_TOKEN`。

## 验证目标

这一版预期验证：

- `v1.1.12` tag 构建成功。
- Forgejo 自动创建 `v1.1.12` Release。
- Release 页面出现 `winterplan-v1.1.12-debug.apk` 附件。
