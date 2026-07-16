# Roaming Harvest 双人竞速专用服

该目录只部署独立的双人竞速服务，不读取或写入单人存档。房间、匹配队列和重连令牌仅保存在内存中；服务重启后不会恢复进行中的比赛。

## 1. 导出 Linux 专用服

构建脚本会在 `build/staging` 生成一个没有任何单人 Autoload 的最小 Godot 工程，只复制联机服务端、协议、比赛模型和规则。安装 Godot 4.6 Linux 导出模板后，从项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\server\duel\build_server.ps1
```

只验证专用服资源包、不需要 Linux 模板时可执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\server\duel\build_server.ps1 -PackOnly
```

输出应包含：

- `build/server/RoamingHarvestDuelServer.x86_64`
- `build/server/RoamingHarvestDuelServer.pck`

## 2. 配置域名并启动

将 `server/duel/` 整体传到 Linux 服务器，复制环境变量示例并填写已解析到该服务器的域名：

```bash
cd server/duel
cp .env.example .env
docker compose up -d --build
docker compose logs -f duel-server
```

Caddy 自动申请 TLS 证书并将 `wss://你的域名/duel` 代理到容器内部的 `ws://duel-server:9080`。公网防火墙只需允许 TCP 80/443（以及可选的 UDP 443），不要公开 9080。

## 3. 客户端地址

开发环境默认读取 `res://config/duel_network.cfg`。发布前将独立配置中的 `server_url` 改为：

```text
wss://你的域名/duel
```

域名、DNS、证书账户和服务器管理凭据不要提交到仓库。首次上线仍需提供实际域名、DNS 控制权以及 Docker 部署权限，之后用两个不同公网网络完成建房、匹配、比赛和重连冒烟测试。

## 运维参数

- `DUEL_MAX_CONNECTIONS`：默认 100。
- `DUEL_MAX_ROOMS`：默认 50。
- `DUEL_WS_PORT`：容器内固定 9080。
- `/healthz`：Caddy 存活探针。

服务日志只记录连接、房间、匹配和比赛事件；重连令牌只打印安全截断值。
