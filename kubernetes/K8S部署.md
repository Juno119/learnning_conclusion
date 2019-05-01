---
typora-root-url: media
---

# K8S部署

本教程旨在Windows 10企业版上，通过Hyper-V构建3台虚拟机，然后搭建Kubernetes-1.14.0版本集群，节点系统为CentOS-7.5

宿主机信息：

![1554050401492](/win-10.png)

需要提前准备CentOS-7.5的ISO镜像

![1554052981504](/Centos7.5-ISO.png)

## 0 准备前规划

| 角色       | IP            | 操作系统   | KUBERNETES-VERSION | 虚拟机规格 |
| ---------- | ------------- | ---------- | ------------------ | ---------- |
| k8s-master | 192.168.1.106 | CentOS-7.5 | 1.14.0             | 2核1G      |
| k8s-node1  | 192.168.1.107 | CentOS-7.5 | 1.14.0             | 1核1G      |
| k8s-node2  | 192.168.1.108 | CentOS-7.5 | 1.14.0             | 1核1G      |

- k8s-master配置成2核是因为后面安装k8s时要求master节点的核数大于1
- **<u>后续安装的时候，我们先安装一台机器，一般是k8s-master，然后再复制出另外两台Node节点，这样可以节省时间</u>**。
- Hyper-V创建虚拟机的步骤就暂时省略了，后面直接开始操作。

## 1 安装操作系统

准备CentOS-7.5 ISO，虚拟机的默认硬盘大小是127G

| 硬盘大小          | 600G分区安排 | 127G |
| :---------------- | ------------ | :--- |
| /boot             | 1G           | 1G   |
| /swap             | 4G           | 2G   |
| /                 | 200G         | 50G  |
| /var/lib/docker   | 200G         | 30G  |
| /var/lib/registry | 200G         | 44G  |

## 2 设置光盘为本地yum源

### 2.1挂载本地操CentOS-7.5 ISO到系统

![1554053207475](/DVD-ISO.png)

```shell
mkdir -p /mnt/cdrom
mount /dev/sdr0 /mnt/cdrom
```

### 2.2 配置yum源

```shell
[local]
name=local
baseurl=file:///mnt/cdrom
enabled=1
gpgcheck=0
gpgkey=file:///mnt/cdrom/PRM-GPG-KEY-CentOS-7
```

### 2.3更新根本地源，安装部分必要软件vim、net-tools与curl

```shell
yum makecache
yum -y install vim net-tools curl wget
```

### 2.4配置系统IP

#### 2.4.1 ifconfig查看系统网口信息

![1553968989030](/ifconfig.png)

#### 2.4.2查看网口的Link状态

![1553969074122](/ethtool-eth0.png)

#### 2.4.3配置网口IP并验证

![1553970563996](/ip_ping.png)

### 2.5 ssh远程连接后配置docker的相关目录

#### 2.5.1先创建与docker相关的目录

```shell
mkdir -p /var/lib/docker    #容器数据卷volume所在目录
mkdir -p /var/lib/registey  #私有镜像仓库存储镜像目录
```

#### 2.5.2创建分区

![1553973134159](/parted.png)

#### 2.5.6格式化逻辑分区

![1553973317998](/mkfs.png)

#### 2.5.7 生成uuid，加入到/etc/fstab中

![1553974440074](/blkid.png)

![1553974541962](/mount-a.png)

### 2.6 配置cntlm代理

#### 2.6.1 准备CCProxy

由于是使用Hyper-V上的虚拟机上安装，为了使虚拟机内能够方便的访问外网，需要使用CCProxy进行代理，相关的安装包可以在网上下载到，本教程中使用的是

ccproxy2010_118231.rar版本

使用的是如下配置，宿主机IP是192.168.1.101

![1554003019916](/ccproxy-settings.png)

![1554003085883](/ccproxy-account.png)

#### 2.6.2 下载cntlm的安装包cntlm-0.92.3-1.x86_64.rpm，然后rpm安装

```shell
rpm -vih cntlm-0.92.3-1.x86_64.rpm
```

#### 2.6.3 修改cntlm的配置文件

通过Hyper-V连接到k8s-master的虚拟机

![1554050901641](/hyperV-link.png)

临时配置本机IP地址

```shell
ifconfig eth0 192.168.1.106
```

![1554051193320](/ifconfg-eth0.png)

然后就可以试着ping一下宿主机的IP，我这里是192.168.1.101

![1554051285197](/ping-host.png)

然后就可以通过ssh软件，比如MobaxTerm或者Xshell远程连接到机器方便操作

![1554051425476](/mobaxterm.png)

后面的步骤就完全切换到MobaXterm中来操作。

首先，让我们来将机器的IP设置为固定IP，k8s-master=192.168.1.101

```shell
vim /etc/sysconfig/network-scripts/ifcfg-eth0
```

按照如下修改即可：

![1554053683429](/static-master.png)

ifcfg-eth0模板文件如下：

```shell
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=eth0
UUID=c09d9c42-a601-4df8-825e-97fe7ad6b3f1
DEVICE=eth0
ONBOOT=yes
IPADDR=192.168.1.106
GATEWAY=192.168.1.1
NETMASK=255.255.255.0
```

其次，让我们修改cntlm的代理设置

```shell
vim /etc/cntlm.conf
```

将其中的代理配置先注释掉，然后增加宿主机CCProxy设置的IP和端口

![1554003207982](/cntlm-conf.png)

然后既可以启动cntlm了

```shell
cntlm -c /etc/cntlm.conf
```

然后使用如下命令就可以看到cntlm启动了，且在监听3128端口

![1554051895300](/netstat-cntlm.png)

这样做只会让cntlm本次生效，系统重启之后需要重新执行cntlm -c 命令，为了达到cntlm在开机时自动配置好，可以如下设置

```shell
vim /etc/rc.local
#在其尾部加入：
cntlm -c /etc/cntlm.conf

#然后给/etc/rc.d/rc.local增加可执行权限
chmod +x /etc/rc.d/rc.local
```

这样cntlm在每次系统启动之后就生效了，稍微解释一下：

系统启动的时候会执行/etc/rc.local中的命令，而/etc/rc.local是/etc/rc.d/rc.local的软链接，如果想/etc/rc.local中的命令生效，就需要给/etc/rc.d/rc.local设置可执行权限。

#### 2.6.4 设置系统环境变量，增加http_proxy等代理设置

```shell
vim /etc/profile
#在文件尾部添加：
export http_proxy=http://localhost:3128
export https_proxy=${http_proxy}
export ftp_proxy=${http_proxy}
export no_proxy="localhost,127.0.0.1,192.168.*"
```

#### 2.6.5 执行source /etc/profile使代理生效

在/etc/profile中设置代理，是为了使这些和代理有关的环境变量在系统启动的时候就设置好，因为系统启动的时候回执行/etc/profile里面的指令

#### 2.6.6 使用curl测试外网联通

直接curl一下www.baidu.com，看到如下输出表示成功访问外网

![1554003525624](/curl-baidu.png)

## 3 安装docker

### 3.1 准备好访问外网的yum文件

#### 3.1.1 aliyun-centos7.repo

```shell
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#
 
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/os/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#released updates 
[updates]
name=CentOS-$releasever - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/updates/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/extras/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/centosplus/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/centosplus/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#contrib - packages by Centos Users
[contrib]
name=CentOS-$releasever - Contrib - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/contrib/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/contrib/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/contrib/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
```

#### 3.1.2 docker-ce.repo

```shell
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-stable-debuginfo]
name=Docker CE Stable - Debuginfo $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/debug-$basearch/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-stable-source]
name=Docker CE Stable - Sources
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/source/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-edge]
name=Docker CE Edge - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/edge
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-edge-debuginfo]
name=Docker CE Edge - Debuginfo $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/debug-$basearch/edge
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-edge-source]
name=Docker CE Edge - Sources
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/source/edge
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-test]
name=Docker CE Test - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-test-debuginfo]
name=Docker CE Test - Debuginfo $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/debug-$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-test-source]
name=Docker CE Test - Sources
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/source/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-nightly]
name=Docker CE Nightly - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-nightly-debuginfo]
name=Docker CE Nightly - Debuginfo $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/debug-$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-nightly-source]
name=Docker CE Nightly - Sources
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/source/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
```

#### 3.1.3 epel.repo

```shell
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=http://mirrors.aliyun.com/epel/7/$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
 
[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
baseurl=http://mirrors.aliyun.com/epel/7/$basearch/debug
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=0
 
[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
baseurl=http://mirrors.aliyun.com/epel/7/SRPMS
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=0
```

### 3.2 移走local.repo后再更新yum缓存

```shell
yum makecache
```

### 3.3 安装docker

#### 3.3.1 先查看yum里面的docker 版本信息

```shell
yum list docker-ce.x86_64  --showduplicates | sort -r
```

![1553975587183](/yum-docker.png)

#### 3.3.2 安装最新的docker

```shell
yum install docker-ce-18.06.3.ce-3.el7.x86_64 docker-ce-selinux-18.06.3.ce-3.el7.x86_64 -y
```

### 3.4 配置docker CDN加速

```shell
mkdir /etc/docker
vim daemon.json
#写入：
{
    "registry-mirrors":["https://69959mok.mirror.aliyuncs.com"]
}
```

### 3.5 配置docker代理

```shell
vim /etc/systemd/system/docker.service.d/http-proxy.conf
#写入:
[Service]
Environment="HTTP_PROXY=http://localhost:3128"
Environment="HTTPS_PROXY=http://localhost:3128"
Environment="NO_PROXY=localhost,127.0.0.0,192.168.*"
```

### 3.6 启动docker

```shell
systemctl start docker
systemctl enable docker
```

### 3.7 检查docker 是否启动

```shell
docker info
```

![1553975996505](/docker-info.png)

### 3.8 检查docker环境变量

![1553975941455](/docker-env.png)

### 3.9 登录docker hub账号

![1553976133969](/docker-login.png)

## 4 安装Kubernetes

### 4.1 准备工作

#### 4.1.1 准备kubernetets yum源

kubernetes.repo

```shell
[kubernetes] 
name=Kubernetes 
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64 
enabled=1 
gpgcheck=1 
repo_gpgcheck=1 
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg 
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
```

#### 4.1.2 更新kubernetes的yum源

```shell
yum makecache
```

#### 4.1.3 查看kubernetes版本，可以看到1.14.0版本

```shell
yum list kubelet.x86_64  --showduplicates | sort -r
```

![1553977076473](/yum-k8s.png)

#### 4.1.4 下载github上的kubernetes二进制安装包

相关链接(以kubernetes v1.14.0为例)：

```shell
https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.14.md#kubernetes-v114-release-notes
```

![1554001412619](/git-kubernetes.png)

拷贝到k8s-master机器上并使用tar -xf解压

![1554002259624](/k8s-tar.png)

#### 4.1.5 检查安装Kubernetes-1.14.0需要的docker镜像

![1554003757331](/kubelet-config.png)

可以看到Kubernetes-1.14.0需要这些镜像

```shell
k8s.gcr.io/kube-apiserver:v1.14.0
k8s.gcr.io/kube-controller-manager:v1.14.0
k8s.gcr.io/kube-scheduler:v1.14.0
k8s.gcr.io/kube-proxy:v1.14.0
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.3.10
k8s.gcr.io/coredns:1.3.1

#其实后面还会用到2个镜像，后面可以一起准备
quay.io/coreos/flannel:v0.11.0-amd64
k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
```

#### 4.1.6 准备镜像

由于国内没法访问k8s.gcr.io仓库，除非使用VPN，所以通过github和docker hub来制作镜像。

a 创建github镜像仓库

![1554004083715](/github.png)

每个目录下放置分别放置构建这个镜像的Dockerfile，以etcd为例：

![1554004219595](/etcd-dockerfile.png)

其实就是为了利用docker hub的在线构建机制。后续可以通过将docker hub链接到github，让docker hub在后台帮我们把镜像pull下来，我们再从dokcer hub上pull。

b 创建docker hub镜像仓库

![1554004695911](/docker-hub.png)

然后耐心等待一会就可以看到kube-apiserver构建成功，此期间什么都不要点击

![554005988599](/build-success.png)

然后采用同样的方法就可以完成其他镜像的构建了

c docker pull所有构建的镜像，然后重新打tag

因为我们pull下来的image的tag都带有自己docker hub仓库的名字，而安装Kubernetes只认k8s.gcr.io仓库下的，所以我们pull下来之后需要重新打标签

以etcd为例：

```shell
#pull镜像 
docker pull junolu/etcd:3.3.10

#重新打tag
docker tag junolu/etcd:3.3.10 k8s.gcr.io/etcd:3.3.10

#删除旧的tag 
docker rmi junolu/etcd:3.3.10
```

其它的镜像依次同样操作，最终的结果：

![1554054857183](/right-images.png)

### 4.2 安装kubernetes-1.14.0相关的包

k8s-master和k8s-node均要执行

```shell
yum install kubelet-1.14.0-0.x86_64 kubeadm-1.14.0-0.x86_64 kubectl-1.14.0-0.x86_64 -y

#然后执行
systemctl enable kubelet
#注意：这一步不能直接执行 systemctl start kubelet，否侧会报错，kubelet也起动不成功
```

设置时区和节点名称

```shell
timedatectl set-timezone Asia/Shanghai  #如果安装系统时选的时区时shanghai就不用执行，否则各个节点都要执行
hostnamectl set-hostname k8s-master   #k8s-master执行，这里我们安装master，就只执行这一句
hostnamectl set-hostname k8s-node1    #k8s-node1执行
hostnamectl set-hostname k8s-node2    #k8s-node2执行
```

配置/etc/hosts

```shell
vim /etc/hosts
在文件尾部追加：
192.168.1.106 k8s-master
192.168.1.107 k8s-node1
192.168.1.108 k8s-node2
```

关闭所有节点的seliux以及firewalld

```shell
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
systemctl disable firewalld
systemctl stop firewalld
```

关闭swap，及修改iptables，不然后面kubeadm会报错

```shell
swapoff -a

vi /etc/fstab   #然后将swap一行注释

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

### 4.3 复制2个Node节点

以上的步骤将master和node的公共操作就做完了，现在我们来复制两个node节点，这样就不需要从头开始安装操作系统了，而且docker镜像也完全准备好了。

#### 4.3.1 关闭k8s-master虚拟机

![1554052304771](/shutdown-k8s-master.png)

关闭虚拟机是为了让Hyper-V进行合并操作，将虚拟机的修改持久化到硬盘，免得中间有些步骤丢失了。

#### 4.3.2 复制k8s-master的虚拟磁盘

![1554052420655](/vhd.png)

这里CentOS-7.5-1是k8s-master的虚拟磁盘，我们看一下里面的内容

![1554052501354](/k8s-master-vhdx.png)

这里的路径就是创建虚拟机的时候设置保存的路径

![1554052594564](/vhdx-path.png)

然后复制出两个node节点，也就是上面截图中的CentOS-7.5-2(k8s-node1)和CentOS-7.5-3（k8s-node2）。

以CentOS-7.5-2为例，将目录下带有CentOS-7.5-1的都改为CentOS-7.5-2

![1554052794327](/node-vhdx.png)

CentOS-7.5-3做同样修改即可。

#### 4.3.3 新建两个虚拟机，然后选定刚才复制出来的vhdx

以CentOS-7.5-2为例：

![1554053342405](/new-node.png)

这样两个node节点的虚拟机就创建好了。

#### 4.3.4 启动两个node节点虚拟机

node节点启动之后应该做的修改一些地方，下面以k8s-node1为例进行修改。

a 设置节点名称，需要将节点的名称设置为k8s-node1

```shell
hostnamectl set-hostname k8s-node1
```

b 修改本机的IP地址

![1554054015184](/node1-ip.png)

k8s-node1规划的IP是192.168.1.107

c 在CCProxy上增加账号

![1554054360661](/CCProxy-add-account.png)

d 检查代理通不通

![1554054409842](/node-curl.png)

e 查看docker images是否和master相同

![1554054482519](/node-docker-images.png)

### 4.4 部署k8s-master节点

重新启动master节点，然后在master节点执行

```shell
#如果配置了master节点的核数为2则直接执行
kubeadm init --kubernetes-version=v1.14.0 --pod-network-cidr=10.244.0.0/16

#如果忘了设置为2，而是只有1个核的话，应该执行下面这条，否则安装会报错
kubeadm init --kubernetes-version=v1.14.0 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU
```

等待一会执行完成之后就会打印下面这些信息

```shell
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

#这三步是接下来要执行的
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

#这句话得记录下来，接下来Node节点加入就要执行这句话了
  kubeadm join 192.168.1.106:6443 --token wct45y.tq23fogetd7rp3ck --discovery-token-ca-cert-hash sha256:c267e2423dba21fdf6fc9c07e3b3fa17884c4f24f0c03f2283a230c70b07772f
```

按要求执行后面的指令

```shell
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

这样k8s-master就安装好了，可以使用kubectl命令查看节点，节点状态应该显示NotReady，而NotReady是因为还未部署网络插件。类似这样：

```shell
[root@master1 kubernetes1.10]# kubectl get node
NAME      STATUS     ROLES     AGE       VERSION
master1   NotReady   master    3m        v1.10.1
```

查看所有的pod，kubectl get pod --all-namespaces。kubedns也依赖于容器网络，此时pending是正常的

类似如下（这些图都是网上找的，安装的过程中没来的及记录）

![1554055788050](/k8s-get-pods.png)

部署flannel网络，可以去https://github.com/coreos/flannel中找到

kube-flannel.yml文件，可以git clone到本地之后再上传到服务器上。

![1554056038243](/flannel.png)

上传到master服务器

![1554056199062](/flannel-master.png)

kubernetes-dashboard.yaml是后面创建dashboard需要的yaml文件，可以直接wegt获取

```shell
https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

它的github链接为：https://github.com/kubernetes/dashboard

然后部署flannel网络，需要执行：

```shell
kubectl apply -f kube-flannel.yml
```

网络就绪后，节点的状态会变为ready，类似这样

```shell
[root@master1 kubernetes1.10]# kubectl get node
NAME      STATUS    ROLES     AGE       VERSION
master1   Ready     master    18m       v1.10.1
```

### 4.5 node节点加入集群

在Node节点执行，如下命令：

```shell
kubeadm join 192.168.1.106:6443 --token wct45y.tq23fogetd7rp3ck --discovery-token-ca-cert-hash sha256:c267e2423dba21fdf6fc9c07e3b3fa17884c4f24f0c03f2283a230c70b07772f
```

执行完成之后然后再master节点上执行kubectl get nodes，就可以看到类似：

```shell
[root@master1 kubernetes1.10]# kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
master1   Ready     master    31m       v1.10.1
node1     Ready     <none>    44s       v1.10.1
```

代表节点加入了k8s集群，在k8s-node1和k8s-node2上执行完成之后，最终结果如图：

![1554056844819](/kubectl-get-nodes.png)

表示整个Kubernetes-1.14.0集群就安装好了。

### 4.6 部署k8s ui界面，dashboard

首先修改kubernetes-dashboard.yaml，在最尾部部分修改：

![1554057091174](/kubernetes-dashboard.png)

```shell
# 添加映射到虚拟机的端口,k8s只支持30000以上的端口
      nodePort: 30001
```

变成类似：

![1554057255438](/kubernetes-dashboard-example.png)

然后执行

```shell
kubectl apply -f kubernetes-dashboard.yaml
```

接着就可通过在浏览器输入IP:端口就可以访问k8s的dashboard了

```http
https://<node-ip>:<node-port>
```

这里对应应该是192.168.1.106:30001（master IP:上面添加的nodePort）

打开的过程中需要进行认证，可以选择“令牌”

![1554057470905](/token.png)

令牌可以通过如下命令获得：

```shell
kubectl -n kube-system describe $(kubectl -n kube-system get secret -n kube-system -o name | grep namespace) | grep token
```

![1554057540423](/get-token.png)

接着就可以看到kubernetes dashboard界面了

![1554057638684](/k8s-ui.png)

### 4.7 其他设置

a master节点默认不可部署pod

执行类似如下命令，可以在 kubectl edit node master1中taint配置参数下查到

```shell
root@master1:/var/lib/kubelet# kubectl taint node master1 node-role.kubernetes.io/master- node "master1" untainted
```

b 清理系统，重新搭建需要执行kubeadm reset

```shell
kubeadm reset
```

c 查看详细的pod信息

```shell
kubectl get pods -o wide
```

## 5 参考链接

### 5.1 centos7.3 kubernetes/k8s 1.10 离线安装

https://www.jianshu.com/p/9c7e1c957752

### 5.2 kubernetes1.13安装dashboard

https://blog.csdn.net/fanren224/article/details/86610466

### 5.3 [kubernetes1.9安装dashboard，以及token认证问题]

https://segmentfault.com/a/1190000013681047

