# AE 脚本 Boombox 中文补丁

适用于 **Windows / Mt. Mograph Boombox v27**，需自行安装原插件及音效库。

## 功能

- 3950 条内置音效名称、44 个分类中英双语显示，主要导航中文化。
- 支持中文、英文和常用同义词搜索，保留英文原名与音效编号。
- 保留原音频及用户数据，支持卸载还原。

## 安装

1. 解压整个文件夹，关闭 Boombox 面板。
2. 右键 `install.cmd`，选择「以管理员身份运行」。
3. 完成后重新打开 Boombox；若未生效，保存工程后重启 AE。

默认安装位置：

```text
C:\Program Files (x86)\Common Files\Adobe\CEP\extensions\com.mtmograph.boombox
```

装在其他位置时，在管理员 PowerShell 中运行（替换引号内的目录）：

```powershell
.\install.cmd -ExtensionPath "D:\你的扩展目录\com.mtmograph.boombox"
```

## 使用与卸载

直接搜索中文即可，例如「雨声」「发动机」。组合搜索用逗号分隔，例如「贝斯，刮弦」。搜不到时，先选择全部音效包和分类。

卸载：关闭面板，右键 `uninstall.cmd` →「以管理员身份运行」，然后重新打开 Boombox。自定义位置同样可加 `-ExtensionPath "你的扩展目录"`。

**请保留扩展目录中的 `boombox-zh-cn-backup-v1` 文件夹，卸载需要使用它。**

## 注意

- 安装器会核对原程序；提示版本不支持时，请勿跳过校验。其他 Boombox 构建及 macOS 尚未验证。
- 翻译覆盖全部内置音效名称，部分设置文字、品牌名仍保留英文。译名按英文名称整理，未逐条试听。
- 本项目为非官方补丁，不含原插件、音频库或授权文件。权利说明见 [NOTICE.md](NOTICE.md)。
