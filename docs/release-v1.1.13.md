# WinterPlan v1.1.13 发版记录

## 版本定位

`v1.1.13` 是 Forgejo Release 附件上传修复版本。

## 问题结论

`v1.1.12` 已经验证：

- `RELEASE_TOKEN` Secret 生效。
- CI 可以创建 Forgejo Release。
- `v1.1.12` Release 已出现。

失败点：

```text
curl: (22) The requested URL returned error: 404
```

含义：

Release 创建成功后，上传 APK 附件的请求格式不符合当前 Forgejo 版本接口要求。

## 改动分类

### Patch / CI

- 将 APK 上传方式改为 multipart form。
- 使用 `attachment=@apk` 作为 Release asset 上传字段。

## 验证目标

这一版预期验证：

- `v1.1.13` tag 构建成功。
- Forgejo 自动创建 `v1.1.13` Release。
- Release 页面出现 APK 附件。
