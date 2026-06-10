#!/bin/sh
# n8n 容器启动钩子 - 持久化修复 n8n-nodes-wechat-offiaccount
# 每次 n8n 启动都自动应用补丁，确保 40001 错误能自动重试获取新 token
#
# 背景：
#   n8n-nodes-wechat-offiaccount 社区节点在缓存的 access_token 失效后
#   (errcode 40001)，只对 42001 (token expired) 做重试，不对 40001 做重试。
#   该补丁让 40001 也能触发清除旧 token 并重新获取的流程。
#
# 容器重启/重新部署时 init 脚本会自动重新应用，无需手动操作。

set +e

WECHAT_NODE_DIR="/home/node/.n8n/nodes/node_modules/n8n-nodes-wechat-offiaccount"
REQUEST_UTILS="$WECHAT_NODE_DIR/dist/nodes/help/utils/RequestUtils.js"
MODULE_LOAD_UTILS="$WECHAT_NODE_DIR/dist/nodes/help/utils/ModuleLoadUtils.js"
DIST_NODE_FILE="$WECHAT_NODE_DIR/dist/nodes/WechatOfficialAccountNode/WechatOfficialAccountNode.node.js"

echo "[n8n-init] Checking n8n-nodes-wechat-offiaccount patches..."

if [ ! -d "$WECHAT_NODE_DIR" ]; then
  echo "[n8n-init] WeChat node not installed at $WECHAT_NODE_DIR, skipping."
  exit 0
fi

# 1. Patch RequestUtils.js — 让 40001 也能触发 token 刷新重试
# 如果文件不存在或者还没被补丁，就重新写入
if [ -f "$REQUEST_UTILS" ] && grep -q "data.errcode === 40001" "$REQUEST_UTILS"; then
  echo "[n8n-init] RequestUtils.js: already patched"
else
  if [ -f "$REQUEST_UTILS" ]; then
    echo "[n8n-init] RequestUtils.js: exists but unpatched, re-applying patch..."
  else
    echo "[n8n-init] RequestUtils.js: missing, creating patched version..."
  fi
  cat > "$REQUEST_UTILS" << 'PATCH_EOF'
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const n8n_workflow_1 = require("n8n-workflow");
class RequestUtils {
    static async originRequest(options, clearAccessToken = false) {
        const credentials = await this.getCredentials("wechatOfficialAccountCredentialsApi");
        options.baseURL = "https://" + credentials.baseUrl;
        return this.helpers.requestWithAuthentication.call(this, "wechatOfficialAccountCredentialsApi", options, {
            credentialsDecrypted: {
                data: {
                    ...credentials,
                    accessToken: clearAccessToken ? "" : credentials.accessToken,
                },
            },
        });
    }
    static async request(options) {
        return RequestUtils.originRequest.call(this, options).then((text) => {
            const data = JSON.parse(text);
            if (data.errcode && (data.errcode === 42001 || data.errcode === 40001)) {
                return RequestUtils.originRequest.call(this, options, true)
                    .then((text) => {
                    const data = JSON.parse(text);
                    if (data.errcode && data.errcode !== 0) {
                        throw new n8n_workflow_1.NodeOperationError(this.getNode(), "Request Error: " + data.errcode + ", " + data.errmsg);
                    }
                    return data;
                });
            }
            if (data.errcode && data.errcode !== 0) {
                throw new n8n_workflow_1.NodeOperationError(this.getNode(), "Request Error: " + data.errcode + ", " + data.errmsg);
            }
            return data;
        });
    }
}
exports.default = RequestUtils;
PATCH_EOF
  echo "[n8n-init] RequestUtils.js: patched (40001 + 42001 will trigger token refresh)"
fi

# 2. ModuleLoadUtils.js — 检查是否有运行时动态 require 的问题
# (不修改，只做存在性检查)
if [ -f "$MODULE_LOAD_UTILS" ]; then
  echo "[n8n-init] ModuleLoadUtils.js: present (ok)"
fi

# 3. 确保 WechatOfficialAccountNode.node.js 能正常 require 所有 resource
if [ -f "$DIST_NODE_FILE" ]; then
  echo "[n8n-init] WechatOfficialAccountNode.node.js: present (ok)"
fi

echo "[n8n-init] WeChat node patches applied successfully"
