# WinterPlan v1.3.1 发版记录

## 版本定位

`v1.3.1` 是日常作息打卡版本的 CI 修复版。

## 问题结论

`v1.3.0` 代码和 tag 已推送成功，但 Forgejo tag 构建卡在 `Setup JDK`：

```text
curl -L "$jdk_url" -o /tmp/jdk17.tar.gz
```

下载进度一直为 0，导致 Release 没有生成。

## 改动分类

### Patch / CI

- 优先复用 runner 上已有的 `/tmp/jdk17/Contents/Home`。
- JDK 下载增加连接超时和总超时。
- 避免 JDK 下载卡死后长期占用 runner。

## 验证目标

- `v1.3.1` tag 构建不再卡在 JDK 下载。
- Forgejo 自动生成 `v1.3.1` Release。
- Release 附件出现 `winterplan-v1.3.1-debug.apk`。
