# Spegel

## 简介

Spegel 是一个轻量级的镜像 P2P 服务, 相比 Dragonfly 更轻量.

* 只支持 containerd

## 部署
 
依赖：
* containerd 配置 `containerd_discard_unpacked_layers: false` 
* 添加额外需要加速 registry host 到 [values.yml](values.yml) 中 `mirroredRegistries` 列表

```bash
helmwave up --build
```

## 卸载

```bash
helmwave down
```