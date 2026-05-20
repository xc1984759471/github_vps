# github_vps

在 GitHub 上申请免费的 VPS。

> 图文教程：https://mp.weixin.qq.com/s/vnA2AXD5zXiXGJNPdNH0BA

## 创建示例

### Ubuntu
<p align="center">
  <img width="512" alt="image" src="https://github.com/user-attachments/assets/93f97616-8aaf-4206-857a-5d17aed8c4d2" />
</p>

### Windows
<p align="center">
  <img width="512" alt="image" src="https://github.com/user-attachments/assets/f40bc167-62b7-4b29-91e0-15e07a76e21c" />
</p>

## 部署教程

先给脚本添加执行权限。

```bash
chmod +x start.sh
```

## Ubuntu 使用教程

### 启动 Ubuntu

```bash
bash start.sh ubuntu
```

### 默认登录信息

Web 终端：

```text
地址：http://<url>:4200
用户名：root
密码：root
```

SSH：

```text
地址：<url>:8022
用户名：root
密码：root
```

RDP：

```text
地址：<url>:3389
用户名：root
密码：root
```

### 修改 Ubuntu root 密码

启动时可以通过 `ROOT_PASSWORD` 指定 root 密码。

```bash
ROOT_PASSWORD='admin@123' bash start.sh ubuntu
```

### 连接 SSH

本地连接示例：

```bash
ssh root@localhost -p 8022
```

如果使用外部地址，将 `localhost` 替换为你的访问地址。

```bash
ssh root@<url> -p 8022
```

### 连接 RDP

```text
地址：<url>:3389
用户名：root
密码：root
```

如果你启动时设置了 `ROOT_PASSWORD`，这里的密码就是你设置的值。

### 停止 Ubuntu

```bash
bash start.sh stop ubuntu
```

## Windows 使用教程

> 不同Windows版本可以在这里看：https://hub.docker.com/r/dockurr/windows
> 
> 然后改：
> ```bash
> environment:
>     VERSION: "11"
> ```

### 启动 Windows 11

默认启动 Windows 11。

```bash
bash start.sh
```

也可以显式指定 Win11。

```bash
bash start.sh win11
```

### 默认登录信息

管理界面：

```text
地址：http://<url>:8006
```

RDP：

```text
地址：<url>:3389
用户名：MASTER
密码：admin@123
```

### 修改 Windows 登录信息

启动前可以通过环境变量修改用户名和密码。

```bash
WINDOWS_USERNAME='MASTER' WINDOWS_PASSWORD='admin@123' bash start.sh win11
```

也可以修改资源配置。

```bash
WINDOWS_RAM_SIZE='4G' WINDOWS_CPU_CORES='4' WINDOWS_DISK_SIZE='64G' bash start.sh win11
```

### 停止 Windows

```bash
bash start.sh stop win11
```

## 停止全部

如果需要同时停止 Windows 和 Ubuntu，执行：

```bash
bash start.sh stop
```

## 端口说明

| 系统      | 服务       | 端口   |
| ------- | -------- | ---- |
| Ubuntu  | Web 终端   | 4200 |
| Ubuntu  | SSH      | 8022 |
| Ubuntu  | RDP      | 3389 |
| Windows | Web 管理界面 | 8006 |
| Windows | RDP      | 3389 |

注意，Ubuntu 和 Windows 都会使用 `3389` 端口。如果需要切换系统，请先停止当前正在运行的系统。

```bash
bash start.sh stop ubuntu
```

或者：

```bash
bash start.sh stop win11
```

