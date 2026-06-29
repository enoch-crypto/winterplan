# WinterPlan v1.1.8 发版记录

## 版本定位

`v1.1.8` 是 CI 测试目录修复版本。

## 问题结论

CI 已经完成：

- clone 仓库
- 安装 Flutter
- `flutter pub get`
- `flutter analyze`

失败点：

```text
Test directory "test" not found.
```

## 改动分类

### Test / CI

- 新增 `test/widget_test.dart`。
- 先加入最小 sanity test，保证 `flutter test` 有测试目录可执行。

## 后续计划

后续版本再增加真正业务测试：

- 时间段解析测试
- 作业进度计算测试
- 打卡评分测试
