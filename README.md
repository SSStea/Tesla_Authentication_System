# Tesla Authentication System（原生 Visual Studio 工程）

本目录不使用 CMake。Windows GUI 和 Linux NodeAgent 分别由两个原生 Visual Studio 解决方案管理，算法、协议、加密、指标和负载源码只保留一份。

## 目录

```text
src/
├─ algorithm/       TESLA 算法和认证运行时
├─ crypto/          OpenSSL 密码实现
├─ metrics/         指标与性能计数
├─ protocol/        TCP、UDP 与控制协议
├─ workload/        文本和文件负载
├─ node/            Linux NodeAgent
└─ gui/
   ├─ shared/       GUI 共用控件
   ├─ manager/
   ├─ pc_node/
   ├─ uav_monitor/
   └─ attack_test/

projects/
├─ TeslaSources.props          两个平台共用的唯一源码清单
├─ TeslaWindows.props          Windows、Qt 和 OpenSSL 公共设置
├─ TeslaQtApplication.props    四个 GUI 的公共 Qt 设置
├─ gui/TeslaGui.sln
└─ linux/TeslaLinux.sln

packaging/
├─ AuthenticationSystemInstaller.iss
├─ ChineseSimplified.isl
└─ ChineseSimplified.LICENSE.txt

package_release.bat             Windows Release 安装包一键打包入口
third_party/nlohmann/          固定版本的 JSON 单头文件
out/                           本地生成物，不提交 Git
dist/                          最终安装包输出，不提交 Git
```

每个源码模块中的 `.h` 和 `.cpp` 放在同一目录，不再使用 `common/<module>/include/tesla/<namespace>/src` 多层结构。

## Windows GUI

环境：

- Visual Studio 2022，安装“使用 C++ 的桌面开发”；
- Qt VS Tools；
- Qt 6.10.2 `msvc2022_64`；
- OpenSSL Win64。

打开：

```text
projects/gui/TeslaGui.sln
```

选择 `Release | x64`，执行“生成解决方案”。解决方案包含一个公共静态库和四个 GUI 应用：

```text
TeslaRuntime
TeslaManagerGui
TeslaPcNodeGui
TeslaUavMonitorGui
TeslaAttackTestGui
```

输出：

```text
out/windows/Release/tesla_manager_gui.exe
out/windows/Release/tesla_pc_node_gui.exe
out/windows/Release/tesla_uav_monitor_gui.exe
out/windows/Release/tesla_attack_test_gui.exe
```

节点继续在 UDP `37020` 监听扫描请求。Manager 使用系统分配的独占临时 UDP 端口发送扫描，并在该端口接收公告和后续心跳，不再与同机 PC 节点或攻击测试端共用 `37020`。节点记录最近一次扫描来源的 IP 和端口，把周期心跳回送到该端点。Manager 重启后需要重新扫描以更新心跳目标。

Manager 对已连接节点每秒发送一次 TCP 状态查询，使用独立的单调计时器判断 TCP 响应是否超时（默认 3 秒）。UDP 心跳缺失不关闭正常的 TCP 连接，UDP 心跳持续到达也不能掩盖 TCP 无响应。更新此机制时，应同步重新生成并更新 Manager、PC 节点、攻击测试端和 Linux NodeAgent；发现 JSON 格式及公共函数接口保持不变。

Qt 和 OpenSSL 的默认位置集中在 `projects/TeslaWindows.props`：

```xml
<TeslaQtInstall>6.10.2_msvc2022_64</TeslaQtInstall>
<OpenSslRoot>C:\Program Files\OpenSSL-Win64</OpenSslRoot>
```

其他电脑只需修改这一处，不需要逐个修改五个项目。

Visual Studio 调试时由 Qt VS Tools 提供 Qt 环境。要把 EXE 复制到没有安装 Qt 的 Windows 电脑，使用对应 Qt 版本的 `windeployqt`，并同时复制 OpenSSL 的 `libcrypto-3-x64.dll`。

## Windows 安装包打包

项目使用根目录下的 `package_release.bat` 一键生成四个互相独立的 Windows x64 安装包。每个安装包只包含对应 GUI 及其 Qt、OpenSSL 和 Visual C++ 运行库，不会把其他三个 GUI、PDB 或静态库打入安装包。

打包电脑除 Windows GUI 的开发环境外，还需要安装 Inno Setup 6：

```bat
winget install --id JRSoftware.InnoSetup --exact
```

双击 `package_release.bat` 会使用默认版本 `1.0.0`。也可以在命令行传入三段式版本号：

```bat
package_release.bat 1.2.0
```

批处理会依次完成：

1. 定位 Visual Studio、Qt、OpenSSL 和 Inno Setup。
2. 重新生成 `Release | x64` 的四个 GUI。
3. 分别调用 `windeployqt` 收集每个程序自己的 Qt 插件和 DLL。
4. 加入 OpenSSL 和 Visual C++ x64 应用本地运行库。
5. 对四个独立部署目录执行限时启动检查。
6. 使用独立 AppId 编译四个可单独安装、升级和卸载的安装包。

安装包输出到：

```text
dist/installers/Authentication_System_Manager_Setup_<版本>_x64.exe
dist/installers/Authentication_System_PC_Node_Setup_<版本>_x64.exe
dist/installers/Authentication_System_UAV_Monitor_Setup_<版本>_x64.exe
dist/installers/Authentication_System_Attack_Test_Setup_<版本>_x64.exe
```

安装程序默认安装到当前用户的 `%LOCALAPPDATA%\Programs\Authentication System`，不要求管理员权限。安装后会创建开始菜单入口，并可选择创建桌面快捷方式；每个程序在 Windows“应用和功能”中都有独立卸载项。目标电脑不需要安装 Qt、OpenSSL、Visual Studio、VC++ 运行库或 Inno Setup。

如开发环境安装在非默认目录，可以在运行批处理前设置：

```bat
set TESLA_QT_ROOT=D:\Qt\6.10.2\msvc2022_64
set TESLA_OPENSSL_ROOT=D:\OpenSSL-Win64
set TESLA_ISCC=D:\Inno Setup 6\ISCC.exe
package_release.bat 1.2.0
```

`dist/` 只保存本地生成的安装包，不提交 Git。当前打包流程未配置数字签名；正式放到网页公开下载前，建议为四个安装包配置代码签名证书，避免 Windows 显示“未知发布者”。

## Linux 远程生成

Linux 机器安装：

```bash
sudo apt update
sudo apt install build-essential gdb rsync zip libssl-dev
```

Visual Studio 安装“使用 C++ 的 Linux 和嵌入式开发”，然后：

1. 打开“工具 → 选项 → 跨平台 → 连接管理器”。
2. 添加目标 Linux 的 IP、SSH 用户、端口和认证信息。
3. 打开 `projects/linux/TeslaLinux.sln`。
4. 右击 `TeslaNodeAgent`，打开“属性 → 常规”。
5. 在“远程生成计算机”中选择对应的 IP。
6. 选择 `Release | x64`，执行“生成解决方案”。

项目使用 GCC 和 C++17，把源码复制到目标机器后进行编译。远程目录固定为：

```text
源码：~/tesla-auth/source
中间文件：~/tesla-auth/obj/Release
程序：~/tesla-auth/bin/Release/tesla_node_agent
```

目标 IP 不写入共享工程文件。Visual Studio 会把个人选择保存到不提交 Git 的 `.vcxproj.user`，因此同一套解决方案可以在不同电脑上选择不同 IP。

## 添加源码

公共模块使用通配清单。把新的 `.h/.cpp` 放进以下任一目录后，会自动进入 Windows 公共库和 Linux 应用，无需修改两套工程：

```text
src/algorithm
src/crypto
src/metrics
src/protocol
src/workload
```

GUI 普通 `.cpp` 也按各自目录自动加入。新增包含 `Q_OBJECT` 的 GUI 头文件时，应在对应 `.vcxproj` 中增加一个 `QtMoc` 项；PC 和 UAV 项目当前采用显式 `QtMoc` 清单，避免对普通头文件运行 moc。

## 当前范围

新目录只包含两套正式产品解决方案。旧仓库中的阶段性测试和历史构建产物没有复制，以免重新引入大量测试项目、构建目录和发布目录。原仓库保持不变，可继续作为迁移对照。
