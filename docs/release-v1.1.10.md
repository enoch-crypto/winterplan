# WinterPlan v1.1.10 发版记录

## 版本定位

`v1.1.10` 是 Forgejo CI 的 JDK 路径修复版本。

## 问题结论

`v1.1.9` 的 JDK 下载已经成功，但 `java -version` 仍然失败：

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
```

原因：

macOS 版 JDK 解压后，真正的 Java 目录在：

```text
Contents/Home
```

上一版把 `JAVA_HOME` 指到了 JDK 包目录外层，系统找不到 `bin/java`。

## 改动分类

### Patch / CI

- 将临时 JDK 的 `JAVA_HOME` 从 `/tmp/jdk17` 修正为 `/tmp/jdk17/Contents/Home`。

## 验证目标

这一版预期验证：

- `java -version` 正常输出。
- Flutter 能识别 JDK。
- Gradle 能继续执行 `assembleDebug`。
