#!/usr/bin/env bash
# run_matlab.sh — 用 GNU Octave 跑 SPolar16QAM 的 v2 仿真（agent 可一键调用）
#
# 本机无 MATLAB License，统一用 Octave 跑。本脚本负责：
#   - 切到 16QAM_Polar/v2
#   - 加载 communications / signal package（缺失不致命，仅告警）
#   - setup_paths 后执行用户给定的命令
#   - 非交互、退出码透传（失败时 agent 能感知）
#
# 用法：
#   scripts/run_matlab.sh check_env             # 环境自检
#   scripts/run_matlab.sh run_single            # 端到端冒烟
#   scripts/run_matlab.sh test_qamdemod_bug     # qamdemod 口径专项
#   scripts/run_matlab.sh 'p=0.3; disp(p)'      # 任意 Octave 语句
#
# 说明：参数原样作为 Octave 语句执行（脚本名本身即合法调用语句）。
set -euo pipefail

# 定位项目根（脚本所在目录的上一级），不依赖调用者的 cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
V2_DIR="$PROJECT_ROOT/16QAM_Polar/v2"

if ! command -v octave >/dev/null 2>&1; then
  echo "[run_matlab] 未找到 octave。请先安装：brew install octave" >&2
  exit 127
fi

if [ "$#" -lt 1 ]; then
  echo "用法: scripts/run_matlab.sh <octave 语句或脚本名>" >&2
  echo "示例: scripts/run_matlab.sh check_env" >&2
  exit 2
fi

# 把所有参数拼成一条命令（允许传多段）
USER_CMD="$*"

# package 加载用 try 包裹：缺失只告警，不阻断（check_env 会专门报缺什么）
PRELUDE="cd('${V2_DIR}'); \
try, pkg load communications; catch, warning('communications package 未加载'); end; \
try, pkg load signal; catch, warning('signal package 未加载'); end; \
setup_paths;"

# --norc 跳过用户配置，确保可复现；--eval 非交互；退出码透传
exec octave --no-gui --norc --eval "${PRELUDE} ${USER_CMD};"
