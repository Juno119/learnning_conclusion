---
typora-copy-images-to: media
---

# dnsmasq搭建dns服务器

## 0 初衷

本文旨在通过基于dnsmasq的docker镜像在局域网中搭建DNS服务器。

## 1 准备工作

### 1.1 下载dnsmasq的docker镜像

- 去docker hub的官网查找dnsmasq的docker 镜像

  docker hub:https://hub.docker.com/

- 搜索dnsmasq

  ![1556692676187](G:\Git_Projects\learning_conclusion\linux\tools\dnsmasq\media\1556692676187.png)

- 找到jpillora/dnsmasq

  ![1556692630002](G:\Git_Projects\learning_conclusion\linux\tools\dnsmasq\media\1556692630002.png)

- pull 镜像

  ```shell
  docker pull jpillora/dnsmasq
  ```

### 1.2 准备配置文件

- 参考docker hub上的运行命令，准备配置文件

  ![1556693064819](G:\Git_Projects\learning_conclusion\linux\tools\dnsmasq\media\1556693064819.png)

- 在宿主机上创建目录/dockerdata/docker-dns

  ```shell
  #创建/dockerdata/docker-dns
  mkdir /dockerdata/docker-dns
  ```

  在/dockerdata/docker-dns目录下准备

  ```shell
  dnsmasq.conf  dnsmasqhosts  resolv.dnsmasq
  ```

  ![1556693226669](G:\Git_Projects\learning_conclusion\linux\tools\dnsmasq\media\1556693226669.png)

  准备dnsmasq.conf

  ```shell
  vim dnsmasq.conf
  # 写入以下内容
  resolv-file=/etc/resolv.dnsmasq
  addn-hosts=/etc/dnsmasqhosts
  ```

  准备dnsmasqhosts

  ```shell
  vim dnsmasqhosts
  # 写入以下内容
  192.168.1.105 reg.juno.com #代表要映射的局域网域名和IP
  ```

  准备resolv.dnsmasq

  ```shell
  vim esolv.dnsmasq
  # 写入以下内容
  nameserver 211.148.192.141
  nameserver 114.114.114.114
  nameserver 8.8.8.8
  ```

  准备完毕，准备启动docke

### 1.3 准备docker-compose.yaml

为了方便管理，使用docker-compose来启动dnsmasq

准备docker-compose.yaml

```shell
version: "2"
services:
  docker-dns:
    container_name: docker-dns
    image: jpillora/dnsmasq
    hostname: docker-dns
    volumes:
      - /dockerdata/docker-dns/resolv.dnsmasq:/etc/resolv.dnsmasq
      - /dockerdata/docker-dns/dnsmasqhosts/:/etc/dnsmasqhosts
      - /dockerdata/docker-dns/dnsmasq.conf/:/etc/dnsmasq.conf
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 53:53/tcp
      - 53:53/udp
      - 8080:8080/tcp
    #cap-add: NET_ADMIN
    logging:
      options:
        max-size: "50m"
    environment:
      - HTTP_USER=admin
      - HTTP_PASS=admin
    restart: on-failure:1
    networks:
      - dns
networks:
  dns:
    driver: bridge
```

### 1.4 配置防火墙

如果宿主机开启了防火墙，需要设置iptables。

在iptables配置文件中增加53/tcp，53/udp，8080/tcp的配置

```shell
vim /etc/sysconfig/iptables
# 增加如下内容
-A INPUT -p tcp -m state --state NEW -m tcp --dport 53 -j ACCEPT
-A INPUT -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT

#重新启动iptables服务
systemctl restart iptables
```

## 2 启动dns服务

在docker-compose.yaml的目录下执行

```shell
docker-compose up -d
```

然后通过docker-compose ps命令就可以看到启动的服务了

![1556694052685](G:\Git_Projects\learning_conclusion\linux\tools\dnsmasq\media\1556694052685.png)

## 3 验证dns服务

#### 3.1配置win10的DNS地址

修改win10上的dns地址，添加上局域网的地址就可以了

![1556694756169](G:\Git_Projects\learning_conclusion\linux\tools\dnsmasq\media\1556694756169.png)

#### 3.2 通过浏览器访问dns服务

win10的IP为192.168.1.101，然后再浏览器输入http://reg.juno.com:8080就可以看到开启的dns服务：

![1556694881859](G:\Git_Projects\learning_conclusion\linux\tools\dnsmasq\media\1556694881859.png)