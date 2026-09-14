#!/usr/bin/env bash
# 为一个业务项目创建 GitOps 目录骨架。
#
# 只生成结构与占位符，不猜测任何组织信息，也不写 Secret。生成后必须人工替换
# REPLACE_ME_ 占位符并经评审合入。
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
project_code="${1:-}"

if [[ ! "$project_code" =~ ^[a-z][a-z0-9-]{1,62}$ ]]; then
  echo "用法：$0 <projectCode>" >&2
  echo "projectCode 为平台不可变编码：小写字母开头，仅含小写字母、数字与连字符。" >&2
  exit 1
fi

project_dir="${repo_dir}/projects/${project_code}"
if [[ -e "$project_dir" ]]; then
  echo "已存在：${project_dir}" >&2
  exit 1
fi

mkdir -p "${project_dir}/argocd" "${project_dir}/apps"

cat > "${project_dir}/argocd/project.yaml" <<EOF
# ${project_code} 的 AppProject：只允许该项目自己的两个源码仓、本部署仓，
# 以及该项目两个环境的 namespace。越界的 Application 会被 ArgoCD 拒绝。
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: kaiwu-${project_code}
  namespace: argocd
spec:
  description: 业务项目 ${project_code}
  sourceRepos:
    - REPLACE_ME_BACKEND_REPO
    - REPLACE_ME_FRONTEND_REPO
    - REPLACE_ME_DEPLOY_REPO
  destinations:
    - namespace: kaiwu-${project_code}-test
      server: https://kubernetes.default.svc
    - namespace: kaiwu-${project_code}-prod
      server: https://kubernetes.default.svc
  clusterResourceWhitelist: []
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
EOF

for env in test prod; do
  cat > "${project_dir}/apps/${env}.yaml" <<EOF
# ${project_code} 在 ${env} 环境的 Application。
#
# 基础 Deployment/Service/Ingress/Kustomize 随生成的源码仓交付，本仓只保存
# 环境选择、版本、镜像与补丁，不复制业务源码。
# targetRevision 必须是不可变 tag 或 commit，不要用分支。
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kaiwu-${project_code}-${env}
  namespace: argocd
spec:
  project: kaiwu-${project_code}
  destination:
    server: https://kubernetes.default.svc
    namespace: kaiwu-${project_code}-${env}
  sources:
    - repoURL: REPLACE_ME_BACKEND_REPO
      targetRevision: REPLACE_ME_BACKEND_REVISION
      path: deploy/k8s
    - repoURL: REPLACE_ME_FRONTEND_REPO
      targetRevision: REPLACE_ME_FRONTEND_REVISION
      path: deploy/k8s
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

  route="${repo_dir}/gateway-routes/${env}/routes/${project_code}.yaml"
  if [[ ! -e "$route" ]]; then
    cat > "$route" <<EOF
# ${project_code} 在 ${env} 环境的外部入口。经平台运维审核后合入。
# uri 必须写完整的 Service DNS，Gateway 不做服务发现。
id: ${project_code}
uri: http://kaiwu-${project_code}-service.kaiwu-${project_code}-${env}.svc.cluster.local:8080
metadata:
  kaiwu-route-type: PROJECT
  kaiwu-project-code: ${project_code}
predicates:
  - Path=/${project_code}-api/**
EOF
  fi
done

echo "已创建："
echo "  projects/${project_code}/argocd/project.yaml"
echo "  projects/${project_code}/apps/{test,prod}.yaml"
echo "  gateway-routes/{test,prod}/routes/${project_code}.yaml"
echo
echo "下一步：替换其中的 REPLACE_ME_ 占位符，然后跑 scripts/check.sh。"
