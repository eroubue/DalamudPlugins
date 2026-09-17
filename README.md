https://raw.githubusercontent.com/eroubue/DalamudPlugins/main/pluginmaster.json

# 零师傅维护的卫月插件库

## 插件列表

| 插件名称 | 插件描述 |
|---------|---------|
| Character Panel Refined CN | 角色面板精炼删除了角色面板中无用的信息，同时添加了有用的统计数据，例如暴击和直击概率百分比以及估计伤害输出，以便更轻松地比较装备。 |
| RezPls CN | 轻松概览谁正在复活谁，已经复活了，以及世界上谁拥有可驱散的debuff影响。 |
| ReMakePlacePlugin CN | 重生之我是FF14装修王! |
| Party Icons CN | 根据当前内容调整玩家铭牌。例如，您可以显示团队位置（通过监听聊天自动分配）、职业图标或带有职业图标的名称。 |
| Death Recap CN | 快速确认什么玩意弄死了你和你的小伙伴! 显示: 治疗、受到的伤害、Debuffs、Buffs、盾、伤害来源的目标减 |
| TPie CN | 高度可配置的快捷栏，可以通过按键绑定进行切换。它们可以填充动作、物品、装备组、宏等等... |
| The Collector CN | 自动上交收藏品，并在代币达到上限时购买指定物品。 |

## 更新插件库

将插件 JSON 和 `latest.zip` 放入 `plugins/<插件目录>/`，然后在 PowerShell 运行：

```powershell
.\update_pluginmaster.ps1
```

脚本按 `InternalName` 更新已有条目的版本、API 等级、描述和简介；新插件自动复制完整 JSON 并生成下载链接（目录中的空格会转义）。随后提交插件、索引、脚本和 README 的变更并推送到 `origin/main`，需要已配置 GitHub 推送权限。发布需在 `main` 分支执行，且不能有预先暂存的变更；Git 失败时会停止，无变更时不会创建空提交。

仅更新本地索引、不提交或推送：

```powershell
.\update_pluginmaster.ps1 -NoPush
```
