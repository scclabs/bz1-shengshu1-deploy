# [MetalLB](https://metallb.universe.tf/)

> GA

高可用的服务均衡器

## 部署

```sh
# 部署 
helmwave up --build

# 等待所有 pod 就绪
kubectl wait -n metallb-system --for=condition=ready pod -l app.kubernetes.io/instance=metallb
```

根据实际情况修改 [default-pool.yaml](default-pool.yaml) 中的 IP 地址池和其所在的 interface

```sh
kubectl apply -k .
```

## 使用

```bash
# 部署测试
kubectl apply -f tests.yaml

# 删除测试
kubectl delete -f tests.yaml
```

## 卸载

```sh 
kubectl delete -k .

helmwave down
```

## 排错

参考 [Troubleshooting](https://metallb.io/troubleshooting/)

- 确保 speaker 运行节点未设置 `node.kubernetes.io/exclude-from-external-load-balancers` 标签
- metallb 查询 vip 分配在那个节点有 3 种方法：
  - 较新 metallb 版本执行 `kubectl get servicel2statuses.metallb.io -n metallb-system`
  - arp 方式检查
    - arping <vip> 获取 <mac>，其中有 2 种可能没有响应或者 timeout
    - vip 工作不正常，可以 telnet <vip> <服务端口> 判断
    - vip 就在当前节点上
    - arp -n |grep <mac> 获取 2 个 ip，其中一个是物理节点 ip
  - 查询 metallb speaker 日志 `kubectl logs <speaker-pod> |grep serviceAnnounced |grep <vip>` , 然后根据查询 pod 获取所在节点
- 抓包分析：
  ```bash
  # 如果 vip 跑在 bond0 上，则在 speaker 上抓包
  tcpdump -i bond0 arp and host 10.254.41.201
  ```