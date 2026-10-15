# iterm2-tools

数据工具仓库，统一管理日常工具及 iTerm2 所需的脚本和配置，包括 Python 工具、Profile 配置、SSH 脚本等。

文件在仓库中维护，按需软链接到 iTerm2 对应位置。目前已实现 Python 脚本的安装，其他类型后续扩展。

## Python 脚本准备

在本机 iTerm2 中：

1. **Settings → General → Magic**：启用 **Enable Python API**。
2. **Scripts → Manage → Install Python Runtime**：安装 Python 运行时。

安装器使用 `/bin/sh`，无需 Python；菜单脚本使用 iTerm2 的运行时。

## 安装与使用

在仓库根目录执行：

```sh
./install.sh
```

当前安装器将 `Scripts/` 下的 `.py` 文件逐个软链接到 `~/Library/Application Support/iTerm2/Scripts/`，保留目录结构。忽略 `.DS_Store`、隐藏项、缓存和源软链接；可重复安装，遇到文件冲突时停止。

- `Scripts/hello.py`：手动示例，输出到 Script Console。
- `Scripts/AutoLaunch/logmenu_demo.py`：注册右键菜单 **日志@演示**。

首次从 **Scripts → AutoLaunch → logmenu_demo.py** 手动启动。菜单只向当前会话插入命令，不自动回车、不广播。

脚本名前打勾表示正在运行，再次点击可停止。以后完全退出并重新打开 iTerm2，`AutoLaunch/` 下的脚本自动启动。

通过 **Scripts → Manage → Console** 查看输出和错误；没有右键菜单时，先确认脚本正在运行。

## 更新与卸载

- 修改脚本：停止后重新运行。
- 新增脚本：重新执行 `./install.sh`。
- 卸载：先停止脚本，再执行：

```sh
./install.sh --uninstall
```

卸载只删除指向本仓库的脚本链接，保留源文件及其他文件。

## 可选配置

自定义安装位置需与 iTerm2 的 **Custom Python API Scripts Folder** 一致，安装和卸载时使用相同路径：

```sh
ITERM2_SCRIPTS_DIR="$HOME/tools/iterm-scripts" ./install.sh
```

本地业务脚本在 `.git/info/exclude` 中排除，仍可正常安装。该规则只对未被 Git 跟踪的文件生效。
