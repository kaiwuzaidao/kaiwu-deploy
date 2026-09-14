# 业务项目的 GitOps 路径

每个业务项目一个目录，目录名是平台不可变的 `projectCode`：

```text
projects/<projectCode>/
├── argocd/project.yaml      # AppProject：限定可引用的仓与 namespace
└── apps/{test,prod}.yaml    # 每个环境一个 Application
```

用 `scripts/new-project.sh <projectCode>` 生成骨架，不要手抄。

硬约束是独立的 GitOps **路径**，不是独立的 Git **仓库**。只有出现独立组织权限、
合规隔离、外部团队移交，或单仓规模成为真实瓶颈时，才把某个项目目录迁成独立部署仓。
完整取舍见 kaiwu-system-service 仓的 `docs/adr/0026-shared-gitops-repository-project-paths.md`。

Secret 永不入库：每个 namespace 自行准备 `kaiwu-<projectCode>-runtime`，
内含业务数据库连接与平台 `context-public-key`。
