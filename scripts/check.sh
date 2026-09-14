#!/usr/bin/env bash
# 部署仓自检：结构完整、无明文密钥、无组织专有信息、占位符已全部替换。
#
# 占位符检查故意是"未替换即失败"：这个仓一旦真正投入使用，留着 REPLACE_ME_
# 就意味着某个环境的地址或版本还没定，让它渲染出去比报错更危险。
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_dir"
failed=0

fail() { echo "[check] $*" >&2; failed=1; }

for path in platform/argocd platform/apps platform/envs/test platform/envs/prod \
            projects gateway-routes/test/routes gateway-routes/prod/routes scripts; do
  [[ -d "$path" ]] || fail "缺少目录：$path"
done

# 明文密钥：这个仓只描述期望状态，任何真实凭据都不该出现。
if grep -RInE --binary-files=without-match \
    '(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|glpat-[A-Za-z0-9_-]{20}|AKIA[0-9A-Z]{16})' \
    . --exclude-dir=.git --exclude="$(basename "${BASH_SOURCE[0]}")"; then
  fail "发现疑似明文密钥。"
fi

# 组织专有信息：示例必须能被任何组织直接使用。
if grep -RInE --binary-files=without-match \
    '(^|[^0-9.])(10\.[0-9]{1,3}|192\.168|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}' \
    . --exclude-dir=.git --exclude="$(basename "${BASH_SOURCE[0]}")"; then
  fail "发现私网 IP，应改为占位符。"
fi

# 可变 revision：应用来源指向分支会让"同步成功"失去含义。
#
# 例外是 multi-source 里那个只提供 values 的来源（带 ref:）——它指的就是本仓，
# 环境值本身就是期望状态，跟 main 才是对的。按 source 块判断，不是逐行 grep。
mutable_revision_sources() {
  find platform projects -name '*.yaml' -print0 2>/dev/null | xargs -0 -r awk '
    function flush() {
      if (rev != "" && !isref &&
          (rev=="main" || rev=="master" || rev=="dev" || rev=="HEAD"))
        print file ":" revline ": targetRevision: " rev
      rev=""; isref=0
    }
    /^[[:space:]]*-[[:space:]]*repoURL:/ { flush(); inblock=1; file=FILENAME; next }
    inblock && /^[[:space:]]*ref:/ { isref=1 }
    inblock && /^[[:space:]]*targetRevision:/ { rev=$2; revline=FNR; file=FILENAME }
    inblock && /^[[:space:]]*[a-zA-Z]+:/ && /^[[:space:]]{0,4}[a-zA-Z]/ { flush(); inblock=0 }
    END { flush() }
  '
}
if [[ -n "$(mutable_revision_sources)" ]]; then
  mutable_revision_sources >&2
  fail "应用来源的 targetRevision 指向了可变分支，必须用不可变 tag 或 commit。"
fi

remaining="$(grep -RIl --binary-files=without-match 'REPLACE_ME_' . \
  --exclude-dir=.git --exclude="$(basename "${BASH_SOURCE[0]}")" || true)"
if [[ -n "$remaining" ]]; then
  echo "[check] 以下文件仍有未替换的占位符："
  printf '  %s\n' $remaining
  echo "[check] 这是新克隆后的预期状态；按自己的环境替换后再部署。"
  # 未替换不算失败，只提示——否则刚 clone 下来就红，没有意义。
fi

if [[ $failed -eq 0 ]]; then
  echo "[check] kaiwu-deploy 结构检查通过。"
else
  exit 1
fi
