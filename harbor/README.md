# Harbor 镜像仓库

## 部署

访问 [values.yml](values.yml) 文件，进行修改:
* expose.tls 选择是否开启 TLS，以及配置证书
  * 如果使用自定义证书则 `certSource: secret`, 并放置证书到 `tls` 目录下对应文件然后执行 `kubectl apply -k .` 部署证书
  * 如果使用 ingress 控制缺省证书则 `certSource: none`, 如果使用 `cert-manager` 则设置对应注解即可
* expose.ingress.hosts.core 配置域名
* externalURL 配置外部访问地址, 通上面域名
* persistence.persistentVolumeClaim.*.storageClass 配置集群存在的共享存储, 以及大小
* database.type 需要修改为 external 用在生产环境中以及添加 eternal 对应连接信息；用在开发环境保存不变即可
* redis 修改等同于 database
* harborAdminPassword 配置管理员密码
* proxy: 建议缺省配置上，可以用于 harbor 作为 image proxy 使用

```bash
helmwave up --build
```

## 提供镜像代理服务

1. 选择**仓库管理**，然后**新建目标**, 选择提供者**Docker Registry**，并填写目标名（例如 `docker.io`/`gcr.io` 等),最后填写对应**目标URL**, 下面是目标名与目标URL的对应关系:

  | 目标名 | 目标URL |
  | ------- | ------- |
  | docker.io | https://mirror.gcr.io |
  | gcr.io | https://gcr.io |
  | ghcr.io | https://ghcr.io |
  | k8s.gcr.io | https://k8s.gcr.io |
  | registry.k8s.io | https://registry.k8s.io |
  | nvcr.io | https://nvcr.io |
  | quay.io | https://quay.io |

###  使用harbor 命令行配置 Registry
- 下载安装： https://github.com/goharbor/harbor-cli/releases

- 登陆私有 harbor
```bash
harbor login https://harbor.home.lan -u admin -p Harbor12345
```

- 批量创建 registry
```bash
for registry in docker.io gcr.io ghcr.io k8s.gcr.io registry.k8s.io nvcr.io quay.io; do harbor registry create --name "$registry" --type docker-registry --url "https://$registry"; done
```

-  查看 registry
```bash
# harbor registry list
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  ID    Name          Status        Endpoint URL              Provider      Creation Time             │
│ ──────────────────────────────────────────────────────────────────────────────────────────────────── │
│  1     docker.io     healthy       https://docker.io         docker-regi…  0 minute ago              │
│  2     gcr.io        healthy       https://gcr.io            docker-regi…  0 minute ago              │
│  3     ghcr.io       healthy       https://ghcr.io           docker-regi…  0 minute ago              │
│  4     k8s.gcr.io    healthy       https://k8s.gcr.io        docker-regi…  0 minute ago              │
│  5     registry.k8…  healthy       https://registry.k8s.io   docker-regi…  0 minute ago              │
│  6     nvcr.io       healthy       https://nvcr.io           docker-regi…  0 minute ago              │
│  7     quay.io       healthy       https://quay.io           docker-regi…  0 minute ago              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

1. 在**项目**中，选择**新建项目**，填写项目名称 (例如, `docker.io`/`gcr.io` 等， 参见上表)，并设置**公开**, 最后开启**镜像代理**并选择对应**目标**
   
- 批量创建 project
```bash
harbor registry list -o json | jq -r '.Payload[] | "\(.id) \(.name)"' | while read id name; do harbor project create "$name" --proxy-cache --public --registry-id "$id"; done
```

- 查看 project 
```bash
# harbor project list
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│  ID    Project Name              Access Level      Type              Repo Co…  Creation Time     │
│ ──────────────────────────────────────────────────────────────────────────────────────────────── │
│  2     docker.io                 public            proxy cache       0         0 minute ago      │
│  3     gcr.io                    public            proxy cache       0         0 minute ago      │
│  4     ghcr.io                   public            proxy cache       0         0 minute ago      │
│  5     k8s.gcr.io                public            proxy cache       0         0 minute ago      │
│  1     library                   public            project           0         4 minute ago      │
│  7     nvcr.io                   public            proxy cache       0         0 minute ago      │
│  8     quay.io                   public            proxy cache       0         0 minute ago      │
│  6     registry.k8s.io           public            proxy cache       0         0 minute ago      │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## 卸载

```bash
helmwave down
```