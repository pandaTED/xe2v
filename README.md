# CleanV2EX (xe2v)

一个干净、快速、无广告的 V2EX 原生 iOS 客户端示例。

## 技术栈
- SwiftUI + async/await + Observation
- 网络读取：V2EX API 2.0 Beta
- 写操作：网页登录态 Cookie + 表单抓取与提交
- 存储：Keychain + UserDefaults + URLCache + 内存缓存

## 运行环境
- Xcode 26+
- iOS 17+

## 如何运行
1. 用 Xcode 打开 `/Users/zhuyunpeng/app_test/xe2v/xe2v.xcodeproj`
2. 选择 `xe2v` scheme
3. 运行到 iPhone 模拟器或真机

## 能力边界

### 官方 API 读取能力
- 首页热门/最新
- 节点列表与节点下主题
- 主题详情与回复列表
- 通知列表（API 失败时自动回退到网页登录态解析）
- 个人资料（公开资料接口）

### 网页态读取回退
- 首页、节点、节点下主题在 API 异常时自动回退到网页登录页面解析，避免空白页

### 网页登录态能力
- 回复帖子（抓取 once/csrf -> 表单提交 -> 成功页识别）
- 发布主题（抓取 once/csrf -> 表单提交 -> 成功页识别）

### 降级策略
- 未登录时明确提示“请先登录后再发帖/回复”
- 写操作失败时显示失败原因，不做“假成功”

## 安全与合规说明
- 不保存明文密码
- Cookie 快照走 Keychain
- 不接广告 SDK / 统计 SDK / 推送营销 SDK
- 本地调试日志默认关闭

## 项目结构
详见代码目录（`App/Core/Network/Features/SharedUI/Data`）。

## 单元测试
示例测试文件：`/Users/zhuyunpeng/app_test/xe2v/xe2vTests/FormParserTests.swift`

> 当前工程默认仅包含 App Target。若需要在 CI 执行测试，请在 Xcode 中添加 `xe2vTests` Test Target，并将该文件加入目标。

## 本地调试日志（DEBUG）
1. 打开 App -> 设置 -> 打开“本地调试日志”
2. 在 Xcode Console 查看 `[DEBUG]` 前缀日志
3. 已覆盖链路：
   - HTTP 请求 URL / 状态码 / 缓存命中
   - 首页、节点、通知加载成功条数与失败原因
   - API 失败后是否触发网页登录回退
   - 网页登录 Cookie 捕获数量
