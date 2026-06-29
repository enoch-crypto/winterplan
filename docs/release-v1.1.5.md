# WinterPlan v1.1.5 发版记录

## 版本定位

`v1.1.5` 是 Forgejo Actions action 源兼容修复版本。

## 问题结论

runner smoke workflow 已成功，说明 runner 可以执行基础 shell step。

Flutter APK workflow 失败在 `Set up job` 阶段，尚未进入 checkout。

## 改动分类

### Infrastructure / CI

- 将 checkout action 改为完整 Forgejo action 地址：
  `https://data.forgejo.org/actions/checkout@v6`
- 将 artifact 上传 action 改为完整 Forgejo action 地址：
  `https://data.forgejo.org/actions/upload-artifact@v3`

## 为什么这样改

Forgejo 文档建议使用完整 action 地址，避免实例 `DEFAULT_ACTIONS_URL` 配置或 GitHub Action 兼容问题影响构建。

## 当前目标

让 Flutter APK workflow 进入真实步骤：

```text
Checkout repository
Install dependencies
Analyze code
Run tests
Build debug APK
Upload APK artifact
```
