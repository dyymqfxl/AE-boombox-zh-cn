# Aftereffects的脚本-Boombox 音效中文补丁

为 **Mt. Mograph Boombox v27** 添加音效中英双语名称与中文搜索。本目录仅提供完整音效名称版，版本为 **v1.0.0**。

这是独立的非官方汉化补丁，需要先安装原插件及音效库。本项目不包含原插件安装包、音频文件或激活内容。

## 效果

| 原名称 | 补丁显示 |
| --- | --- |
| Bass - Scrape 04 | 贝斯 - 刮弦 04 · Bass - Scrape 04 |
| Camaro Engine Turn On 02 | 科迈罗引擎启动 02 · Camaro Engine Turn On 02 |
| Rain Ambience | 雨声环境 · Rain Ambience |

- 覆盖这份 v27 音效库的 **3950 条内置音效名称**，保留英文原名与编号。
- **44 个分类 ID** 的中英双语显示，以及首页、用户、浏览、收藏、最近等主导航汉化。
- 支持中文、英文及常用同义词搜索，如“贝斯”“刮弦”“发动机”“雨声”。
- 支持逗号分隔的组合搜索，如“贝斯，刮弦”。
- 收藏、最近使用中的内置音效同样显示双语；用户包中的自定义名称保留原样。

## 安装、升级、卸载

先解压完整目录，关闭 Boombox 面板，再选择对应文件。不要只下载单个脚本。

| 你的情况 | 运行文件 |
| --- | --- |
| 首次安装本补丁 | 右键 `install.cmd` → **以管理员身份运行** |
| 恢复原版英文界面 | 右键 `uninstall.cmd` → **以管理员身份运行** |

完成后重新打开 Boombox。若仍显示旧界面，先保存工程，再重启 AE。

默认扩展目录：

```text
C:\Program Files (x86)\Common Files\Adobe\CEP\extensions\com.mtmograph.boombox
```

扩展装在其他位置时，可以在 PowerShell 中指定目录：

```powershell
# 首次安装
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\patch.ps1 -Mode Install -ExtensionPath "你的扩展目录"

# 卸载
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\patch.ps1 -Mode Uninstall -ExtensionPath "你的扩展目录"
```

## 兼容范围

当前适配 **Windows 上本项目验证过的这份 Boombox v27 程序文件**。安装器检查原 `cep.js` 的 SHA-256；其他构建即使也叫 v27，也可能不兼容。

```text
72c0d065a99c880a40d6cbe503f029f568ce5863aa5ea03353b58b69a529017f
```

本包的安装脚本面向 Windows，尚未验证 macOS 或其他 Boombox 版本。

## 文件与还原

原 `cep.js` 保留不动。安装器在本机生成 `cep.zh-cn.js`，让 `index.html` 加载该副本、中文词典与字体样式。

音频文件、哈希文件名、音效 ID、资源路径及用户数据库不修改。脚本不修改注册表、安全设置或授权逻辑。

原入口文件和卸载清单保存在扩展目录的 `boombox-zh-cn-backup-v1` 文件夹。**请保留这个文件夹**，卸载时需要。安装和升级会检查文件校验值，遇到不兼容版本或本地修改会停止。

## 搜索与常见问题

**搜不到某个中文词？** 搜索受当前音效包和分类选择限制。先选择全部包和全部分类，或点击“在全部音效中重新搜索”。组合词请使用逗号，例如“贝斯，刮弦”。

**提示权限不足？** 关闭面板后，以管理员身份运行对应的 `.cmd` 文件。

**提示版本不支持？** 当前原程序校验值与适配版本不同。不要手动跳过校验，请核对 Boombox 版本。

**提示补丁文件已修改？** 安装器为保护本地改动而停止。先检查修改，不要直接删除原备份。

**名称很长显示不全？** 列表沿用原面板的单行布局。中文放在前面，英文可能随面板宽度被截断；完整对照见 `音效名称中英对照.csv`。

## 翻译范围与验证

“完整”指这份库的 **3950 条内置音效名称全部有中文对应**，并非所有设置页、说明文本、音效包品牌名均已翻译。

译名按原英文语义和音效命名规则整理，未逐条听辨全部音频。少数创意拟声名称可能需要润色，保留英文便于核对。反馈时请提供英文原名、当前中文名和建议译法。

词典覆盖、中文搜索、升级及卸载还原的检查结果见 [验证说明](docs/验证说明.md)。维护者已确认本版本可以发布；本项目未逐条试听全部音频，也未提供所有 AE 操作的逐项人工验收记录。

## 文件说明

| 文件 | 用途 |
| --- | --- |
| `install.cmd` / `update.cmd` / `uninstall.cmd` | 安装、旧版升级、卸载入口 |
| `patch.ps1` / `update.ps1` | 校验、备份和应用补丁 |
| `patch-spec.json` | 适配版本与程序修改点 |
| `boombox-zh-cn.dictionary.js` | 音效、分类的中英名称与搜索词 |
| `boombox-zh-cn.js` / `boombox-zh-cn.css` | 显示与搜索适配、中文字体 |
| `音效名称中英对照.csv` | 全部名称对照表 |
| `tests/validate.cjs` | 可选的词典与搜索检查，无需安装依赖 |

有 Node.js 时可运行 `node tests/validate.cjs` 检查词典。安装和使用补丁本身无需 Node.js。
