# kaiwu-deploy · Agent 指引

这个仓只描述 **期望状态**，不含任何可执行的业务代码，也不含任何 Secret。

## 动手前

1. 读 `README.md` 的"它保存什么、不保存什么"。越界的改动（把 Chart、业务源码或
   Secret 塞进来）应当直接拒绝，而不是照做。
2. 改完跑 `bash scripts/check.sh`。它检查目录结构、明文密钥、私网 IP，以及
   `targetRevision` 是否指向了可变分支。
3. 不要直接在受保护分支上实现；创建描述性的 feature/fix 分支。

## 常见任务

| 任务 | 怎么做 |
| --- | --- |
| 新增业务项目 | `./scripts/new-project.sh <projectCode>`，再替换 `REPLACE_ME_` |
| 升级平台版本 | 改 `platform/apps/<env>.yaml` 的 `targetRevision` 与 `platform/envs/<env>/values.yaml` 的镜像 tag |
| 发布业务新版本 | 改 `projects/<code>/apps/<env>.yaml` 的 `targetRevision` |
| 开放业务外部入口 | 在 `gateway-routes/<env>/routes/` 增文件，需平台运维审核 |

## 不要做的事

- 不要把 `targetRevision` 改成分支名。唯一例外是 multi-source 里带 `ref:` 的
  values 来源。
- 不要把 Secret、私网地址、具体组织的 Git/镜像仓库地址写死进来——示例必须能被任何
  组织直接使用，环境专有值一律是 `REPLACE_ME_` 占位符。
- 不要在这里复制业务的 Deployment/Service/Ingress。那些随生成的源码仓交付，本仓
  只保存环境选择、版本、镜像、域名、资源与补丁。
- 不要提交一份主体不存在的 `CODEOWNERS`。
