# WinterPlan v1.1.14 发版记录

## 版本定位

`v1.1.14` 是 Forgejo Release ID 解析修复版本。

## 问题结论

`v1.1.13` 已经验证：

- `RELEASE_TOKEN` 可用。
- Release 能自动创建。
- `v1.1.13` Release 已出现。

失败点仍在上传 APK 附件：

```text
curl: (22) The requested URL returned error: 404
```

推断原因：

脚本从 Release JSON 中提取 `id` 时，可能拿到了用户、作者或其它对象的 `id`，导致附件上传请求访问了错误的 Release 地址。

## 改动分类

### Patch / CI

- 优化 `release_id` 解析方式。
- 在日志中输出正在使用的 Release ID，方便后续定位。

## 验证目标

这一版预期验证：

- `v1.1.14` Release 自动创建。
- APK 附件上传到正确 Release。
