# Roaming Harvest 基础架构

## 目录结构

- `scenes/`: 可运行场景与可复用场景。
- `scenes/ui/`: HUD、对话、背包、任务栏、淡入淡出等 UI 场景。
- `scenes/components/`: 需要场景化复用的组件预制体。
- `scripts/managers/`: 全局系统入口，作为 Autoload 使用。
- `scripts/components/`: 挂到世界对象、NPC、农田、商店等节点上的可复用组件。
- `scripts/data/`: `Resource` 数据类型定义。
- `scripts/ui/`: UI 控件脚本。
- `scripts/multiplayer/`: 联机预留接口，不包含完整联机实现。
- `data/items/`: 物品配置资源。
- `data/crops/`: 作物配置资源。
- `data/npcs/`: NPC 配置资源。
- `data/quests/`: 任务配置资源。
- `data/buildings/`: 建筑配置资源。
- `ui/themes/`: 后续主题、字体、StyleBox 等 UI 资源。

## Manager 职责

- `GameManager`: 游戏状态入口，持有玩家引用、切换暂停/游玩状态，并暴露联机预留信号。
- `TimeManager`: 游戏内时间、日期推进，以及按天/分钟广播时间事件。
- `SaveManager`: 存档读写入口，聚合玩家位置、背包、农田状态、任务进度和组件存档。
- `InteractionManager`: 管理当前可交互目标、交互提示和执行交互。
- `InventoryManager`: 背包数据、物品增减、槽位快照和存档接口。
- `WorldManager`: 当前世界/区域/出生点注册，提供无硬编码的场景状态接口。
- `CropManager`: 农田地块注册、作物种植/浇水/生长更新和农田存档。
- `UIManager`: 基础 UI 入口，显示交互提示、对话、任务栏、背包和 Fade。

## Component 职责

- `InteriorPortal`: 通用室内外传送入口，使用目标场景/目标点配置，不绑定具体房子。
- `InteractableComponent`: 可交互对象通用组件，提供提示文本、交互范围和回调信号。
- `SaveComponent`: 节点级存档组件，给任意对象提供 `save_id` 和自定义数据槽。
- `CropPlotComponent`: 单块农田地块组件，负责种植、浇水、收获状态。
- `GrowthComponent`: 通用生长组件，按游戏时间推进阶段，可复用于作物或其他生长物。
- `DialogueComponent`: NPC/物体对话组件，引用 NPC 数据并发起对话。
- `TaskComponent`: 任务提供/推进组件，引用 QuestData，不绑定具体 NPC。
- `ShopComponent`: 商店组件，按配置售卖/收购物品，调用背包接口。

## Data 职责

- `ItemData`: 物品基础配置。
- `CropData`: 作物、种子、产物和生长阶段配置。
- `NpcData`: NPC 基础信息和对话入口配置。
- `QuestData`: 任务标题、目标、奖励和前置条件配置。
- `BuildingData`: 建筑、室内场景、入口点和解锁条件配置。

## 当前实现边界

本轮只搭建可扩展框架、空壳代码和基础接口。现有角色控制、`GrassWorld.tscn` 以及原型场景资源不重构、不迁移。
