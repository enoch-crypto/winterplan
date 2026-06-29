# WinterPlan v1.1.4 发版记录

## 版本定位

`v1.1.4` 是 Forgejo runner smoke test 版本。

## 问题结论

`v1.1.3` 的 workflow 已经匹配到 runner，但 job 卡在 `Set up job`，没有进入 checkout。

当前需要验证 runner 是否能执行最简单的 step。

## 改动分类

### Infrastructure / CI

- 新增 `.forgejo/workflows/smoke.yml`。
- 该 workflow 只执行 `echo`、`uname -a`、`whoami`、`pwd`。
- 目标是确认 runner 基础执行能力。

## 判断标准

- smoke 成功：runner 基础可用，继续修 Flutter workflow。
- smoke 卡在 `Set up job`：runner 服务端执行器存在问题，需要检查 runner 进程日志。
