# 平台审核的业务项目外部入口

每个业务项目在每个环境有且只有一个路由文件：`<env>/routes/<projectCode>.yaml`。
这些文件由平台运维审核后合入，再渲染成只读 ConfigMap（默认名 `kaiwu-project-routes`）
挂给 Gateway。

为什么逐条显式声明：Gateway 不是 discovery locator，不从 Nacos 或 Kubernetes
自动暴露服务。任一路由缺少 `PROJECT` 元数据、或 id 重复，Gateway 启动即失败——
宁可起不来，也不要把一个没人审过的服务暴露到外网。

在部署仓根目录运行。先确认 kubectl 当前上下文指向目标集群，再指定本次要更新的环境。目录中应已有经过评审的路由 YAML。

```bash
env=test
kubectl create configmap kaiwu-project-routes \
  --from-file="gateway-routes/$env/routes/" \
  --dry-run=client -o yaml | kubectl apply -n "kaiwu-$env" -f -
```

单仓或本地部署可以改用 chart 的 `gateway.managedRoutes`，两者互斥。
