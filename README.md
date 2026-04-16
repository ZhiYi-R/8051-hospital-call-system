# 8051 房间呼叫系统

基于 8051/MCS-51 单片机的房间呼叫系统，实现按键检测、数码管显示和蜂鸣器报警功能。

## 功能特性

- **8 路按键输入**：支持 1-8 号房间呼叫（P2 口）
- **七段数码管显示**：实时显示呼叫房间号（P0 口）
- **蜂鸣器报警**：呼叫触发后蜂鸣器响 1 秒（P3.7）
- **按键防抖**：20ms 软件防抖，确保稳定触发
- **释放触发**：按键释放时刻触发呼叫，避免误触发
- **显示替换**：新呼叫自动覆盖旧显示

## 硬件连接

| 端口 | 功能 | 说明 |
|------|------|------|
| P2.0-P2.7 | 按键输入 | 低电平有效，对应 1-8 号房间 |
| P0.0-P0.6 | 数码管输出 | 共阴极七段数码管（a-g 段） |
| P3.7 | 蜂鸣器控制 | 高电平有效 |

## 编译环境

- **编译器**：SDCC (Small Device C Compiler)
- **模拟器**：ucsim (用于自动化测试)
- **目标芯片**：8051/MCS-51 系列

### 安装依赖

```bash
# Debian/Ubuntu
sudo apt-get install sdcc sdcc-ucsim make

# Fedora
sudo dnf install sdcc sdcc-ucsim make

# macOS
brew install sdcc
```

测试会自动探测常见的模拟器命令名，包括 Ubuntu/Debian 的 `s51`，以及其他环境里的 `ucsim_51` / `sdcc-ucsim_51`。

## 构建项目

```bash
# 编译生成 hex 固件
make build

# 或直接运行（默认目标）
make
```

生成的固件位于 `Build/mcu-1.hex`。

## 测试

项目包含完整的自动化测试套件，使用 ucsim 模拟器验证功能。

```bash
# 运行所有测试
make test

# 运行单个测试
make test-b1              # 测试按键 1
make test-b8              # 测试按键 8
make test-release-trigger # 测试释放触发机制
make test-display-replace # 测试显示替换
make test-buzzer-duration # 测试蜂鸣器持续时间
```

### 测试覆盖

- ✅ 所有 8 个按键功能（test-b1 ~ test-b8）
- ✅ 按键防抖机制
- ✅ 按键释放触发（test-release-trigger）
- ✅ 显示替换逻辑（test-display-replace）
- ✅ 蜂鸣器 1 秒持续时间（test-buzzer-duration）

## 项目结构

```
.
├── main.c                  # 主程序
├── inc/
│   ├── reg52.h            # 8052 寄存器定义
│   └── clangd_compat.h    # clangd 兼容层
├── test/                   # 测试脚本
│   ├── test-b*.sh         # 按键测试（1-8）
│   ├── test-button.sh     # 通用按键测试模板
│   ├── test-release-trigger.sh
│   ├── test-display-replace.sh
│   ├── test-buzzer-duration.sh
│   └── run-ucsim.sh       # ucsim 运行辅助脚本
├── Build/                  # 编译输出目录
├── Makefile               # 构建脚本
└── README.md              # 本文件
```

## 技术细节

### 按键扫描与防抖

- 扫描周期：10ms
- 防抖延迟：20ms（2 个扫描周期）
- 采用状态机实现，连续 2 次读取相同状态才确认

### 七段数码管编码

使用共阴极数码管，段码映射：

| 数字 | 段码（十六进制） | 显示段 |
|------|------------------|--------|
| 1 | 0x06 | b, c |
| 2 | 0x5B | a, b, d, e, g |
| 3 | 0x4F | a, b, c, d, g |
| 4 | 0x66 | b, c, f, g |
| 5 | 0x6D | a, c, d, f, g |
| 6 | 0x7D | a, c, d, e, f, g |
| 7 | 0x07 | a, b, c |
| 8 | 0x7F | a, b, c, d, e, f, g |

### 蜂鸣器控制

- 触发方式：按键释放时刻
- 持续时间：1000ms（100 个扫描周期）
- 控制逻辑：倒计时方式，每个扫描周期递减

## 清理构建

```bash
make clean
```

## 开发工具

项目配置了 clangd 语言服务器支持，提供代码补全和语法检查：

- `.clangd`：clangd 配置
- `.clang-format`：代码格式化规则
- `inc/clangd_compat.h`：SDCC 关键字兼容层

## 说明

本项目为单片机课程作业。

注：`inc/reg52.h` 文件版权归 Keil Elektronik GmbH 和 Keil Software, Inc. 所有。

## AI 使用声明

本项目部分内容使用了 AI 辅助工具生成，详见 [AI_USAGE.md](AI_USAGE.md)。
