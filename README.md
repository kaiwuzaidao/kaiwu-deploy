# kaiwu-deploy

Kaiwu 平台与业务项目的 **GitOps 期望状态**。只在走 Kubernetes + ArgoCD 时才需要
这个仓；只做一次 Helm 演示不需要它——Chart 在 `kaiwu-system-service` 仓的
`deploy/helm/kaiwu`，直接 `helm upgrade --install` 即可。

## 它保存什么、不保存什么

| 保存 | 不保存 |
| --- | --- |
| 每个环境的取值覆盖、镜像版本、域名、副本数 | Helm Chart 本体（在 `kaiwu-system-service`） |
| ArgoCD Application 与 AppProject | 任何明文 Secret |
| 平台审核过的业务项目外部路由 | 业务源码、基础 manifests（随生成的源码仓交付） |

**Secret 永不入库。** 平台需要 `kaiwu-runtime`，每个业务项目需要
`kaiwu-<projectCode>-runtime`，都由集群侧的密钥系统准备。键位清单见
`kaiwu-system-service` 仓的 `docs/KUBERNETES.md`。

## 目录

```text
platform/
├── argocd/appproject.yaml     # 平台自身的 AppProject
├── apps/{test,prod}.yaml      # 平台每个环境一个 Application
└── envs/{test,prod}/values.yaml
projects/<projectCode>/
├── argocd/project.yaml
└── apps/{test,prod}.yaml
gateway-routes/{test,prod}/routes/<projectCode>.yaml
scripts/
├── new-project.sh             # 生成一个业务项目的骨架
└── check.sh                   # 结构、密钥、私网地址、可变 revision 自检
```

## 怎么用

```bash
# 1. 替换 platform/ 下的 REPLACE_ME_ 占位符（仓库地址、镜像仓库、数据库、域名、tag）
# 2. 自检
bash scripts/check.sh
# 3. 接入 ArgoCD
kubectl apply -f platform/argocd/appproject.yaml
kubectl apply -f platform/apps/test.yaml
```

新增一个业务项目：

```bash
./scripts/new-project.sh <projectCode>
# 替换新生成文件里的 REPLACE_ME_，评审后合入
```

## 两条硬约束

**`targetRevision` 必须是不可变 tag 或 commit。** 指向分支会让"同步成功"失去含义——
你无法说清集群上跑的到底是哪一次提交。唯一例外是 multi-source 里只提供 values 的
那个来源（带 `ref:`），它指的就是本仓，环境值本身即期望状态。`scripts/check.sh`
按 source 块区分这两种情况。

**业务项目的边界是独立的 GitOps 路径，不是独立的 Git 仓库。** 只有出现独立组织
权限、合规隔离、外部团队移交，或单仓规模成为真实瓶颈时，才把某个项目目录迁成
独立部署仓。取舍见 `kaiwu-system-service` 仓的
`docs/adr/0026-shared-gitops-repository-project-paths.md` 与 ADR 0023。

## CODEOWNERS

仓库提供 `CODEOWNERS.template`，不提供生效的 `CODEOWNERS`——Kaiwu 猜不到你的组织里
有哪些用户和 Group，提交一份主体不存在的规则只会制造"看起来有人审"的假象。
按模板填好自己的主体后重命名为 `CODEOWNERS`。

## License

[Apache License 2.0](LICENSE)。
