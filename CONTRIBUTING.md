# 参与 kaiwu-deploy

这个仓只描述 Kubernetes 上的**期望状态**。改动 Helm Chart 请去
`kaiwu-system-service`，改动业务 manifests 请去对应的业务源码仓——本仓不接收
产品代码。

## 提交前

```bash
bash scripts/check.sh
```

它检查目录结构、明文密钥、私网 IP，以及 `targetRevision` 是否指向可变分支。

## 审核口径

- **任何真实凭据都不会被接受。** Secret 由集群侧密钥系统准备，本仓只引用名字。
- **任何具体组织的地址都不会被接受。** 仓库地址、镜像仓库、数据库主机、域名一律
  是 `REPLACE_ME_` 占位符，示例必须能被任何组织直接使用。
- **`targetRevision` 必须是不可变 tag 或 commit**，唯一例外是 multi-source 里带
  `ref:` 的 values 来源。
- `gateway-routes/` 下的改动是把一个服务暴露到外部，必须由平台运维审核，不能由
  业务方自审。

## 分支

不要直接在受保护分支上实现；创建描述性的 feature/fix 分支，一次只做一个可回滚的范围。
