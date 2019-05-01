---
typora-root-url: media
---

# 搭建Harbor企业级docker仓库

## 1 Harbor简介

```html
Harbor是一个用于存储和分发Docker镜像的企业级Registry服务器，通过添加一些企业必需的功能特性，例如安全、标识和管理等，扩展了开源Docker
Distribution。作为一个企业级私有Registry服务器，Harbor提供了更好的性能和安全。提升用户使用Registry构建和运行环境传输镜像的效率。Harbor支持安装在多个Registry节点的镜像资源复制，镜像全部保存在私有Registry中，
确保数据和知识产权在公司内部网络中管控。另外，Harbor也提供了高级的安全特性，诸如用户管理，访问控制和活动审计等
```

## 2 Harbor特性

```shell

   a 基于角色的访问控制 ：用户与Docker镜像仓库通过“项目”进行组织管理，一个用户可以对多个镜像仓库在同一命名空间（project）里有不同的权限。
   b 镜像复制 ： 镜像可以在多个Registry实例中复制（同步）。尤其适合于负载均衡，高可用，混合云和多云的场景。
   c 图形化用户界面 ： 用户可以通过浏览器来浏览，检索当前Docker镜像仓库，管理项目和命名空间。
   d AD/LDAP 支持 ： Harbor可以集成企业内部已有的AD/LDAP，用于鉴权认证管理。
   e 审计管理 ： 所有针对镜像仓库的操作都可以被记录追溯，用于审计管理。
   f 国际化 ： 已拥有英文、中文、德文、日文和俄文的本地化版本。更多的语言将会添加进来。
   g RESTful API ： RESTful API 提供给管理员对于Harbor更多的操控, 使得与其它管理软件集成变得更容易。
   h 部署简单 ： 提供在线和离线两种安装工具， 也可以安装到vSphere平台(OVA方式)虚拟设备。
```



## 3 Harbor组件

```shell
Harbor在架构上主要由6个组件构成：

    Proxy：Harbor的registry, UI, token等服务，通过一个前置的反向代理统一接收浏览器、Docker客户端的请求，并将请求转发给后端不同的服务。

    Registry： 负责储存Docker镜像，并处理docker push/pull 命令。由于我们要对用户进行访问控制，即不同用户对Docker image有不同的读写权限，Registry会指向一个token服务，强制用户的每次docker pull/push请求都要携带一个合法的token, Registry会通过公钥对token 进行解密验证。

    Core services： 这是Harbor的核心功能，主要提供以下服务：

    UI：提供图形化界面，帮助用户管理registry上的镜像（image）, 并对用户进行授权。

    webhook：为了及时获取registry 上image状态变化的情况， 在Registry上配置webhook，把状态变化传递给UI模块。

    token 服务：负责根据用户权限给每个docker push/pull命令签发token. Docker 客户端向Regiøstry服务发起的请求,如果不包含token，会被重定向到这里，获得token后再重新向Registry进行请求。

    Database：为core services提供数据库服务，负责储存用户权限、审计日志、Docker image分组信息等数据。

    Job Services：提供镜像远程复制功能，可以把本地镜像同步到其他Harbor实例中。

    Log collector：为了帮助监控Harbor运行，负责收集其他组件的log，供日后进行分析。
```

## 4 Harbor实现

Harbor的每个组件都是以Docker容器的形式构建的，官方也是使用Docker 
Compose来对它进行部署。用于部署Harbor的Docker Compose模板位于 
harbor/docker-compose.yml,打开这个模板文件，发现Harbor是由7个容器组成的；.

![1556695348350](/1556695348350.png)

## 5 Harbor安装

### 5.1安装docker-compose

参考官网：https://docs.docker.com/compose/install/

```shell
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
```

### 5.2 下载Harbor

去github下载最新的Harbor的release版本放到宿主机的某个目录

https://github.com/goharbor/harbor/releases

目前最新的版本是harbor-online-installer-v1.7.5.tgz

### 5.3 安装Harbor

解压到/usr/local/

```shell
tar zxf harbor-online-installer-v1.7.5.tgz  -C /usr/local/
cd /usr/local/harbor/
```

### 5.4 修改配置文件

可以参考如下：

```shell
# vim /usr/local/harbor/harbor.cfg
hostname = rgs.unixfbi.com
#邮箱配置
email_server = smtp.qq.com
email_server_port = 25
email_username = unixfbi@unixfbi.com
email_password =12345678
email_from = UnixFBI <unixfbi@unixfbi.com>
email_ssl = false
#禁止用户注册
self_registration = off
#设置只有管理员可以创建项目
project_creation_restriction = adminonly
```

也可以使用本文件统计目录下的harbor.cfg

### 5.5 执行安装脚本

```shell
/usr/local/harbor/install.sh
```

​	等待安装完成

### 5.6 docker-compose查看状态

![1556700566120](/1556700566120.png)

```shell
启动Harbor
# docker-compose start
停止Harbor
# docker-comose stop
重启Harbor
# docker-compose restart
```

### 5.7 访问测试

如果配置了DNS服务器，要先将电脑的DNS服务器IP设置好

![1556705398426](/1556705398426.png)

在浏览器输入reg.juno.com，因为我配置的域名为reg.juno.com。请大家根据自己的配置情况输入访问的域名；
默认账号密码： admin / Harbor12345 

![1556705208241](/1556705208241.png)

### 5.8 用户管理

除了管理员用户以外，还可以增加用户或者在页面注册用户

![1556705471390](/1556705471390.png)

如上增加了一个"juno的用户"，用户涉及到后续仓库的管理权限。

- 用户有管理员和普通用户之分

- 但是镜像仓库确实基于用户角色管理的，每个用户对于不同的镜像仓库来说有三种角色：项目管理员、开发人员、访客。

  | 角色       | 权限                                 |
  | ---------- | ------------------------------------ |
  | 项目管理员 | 对镜像有上传、下载、删除和查看的权限 |
  | 开发人员   | 只能查看、上传和下载镜像权限         |
  | 访客       | 只能查看和下载镜像的权限             |

### 5.9 创建项目

​	用户可以创建知己的项目（可以理解为仓库），并设置为私有或者共有仓库。

但是每个用户对每个仓库的角色只有admin账户可以设置

![1556705919480](/1556705919480.png)



### 5.10 在docker client测模拟测试

首先登陆到镜像仓库

![1556706149945](/1556706149945.png)

使用rabbitmq:1.0镜像作为测试，打上标签

![1556706108475](/1556706108475.png)

push镜像

![1556706220268](/1556706220268.png)

然后在harbor的界面上可以push的镜像了

![1556706343831](/1556706343831.png)

