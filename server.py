"""
server.py - 爱掼蛋测试题后台
功能：托管静态页面 + Kimi AI 出题接口

启动方式：
    cd D:\aiguandan && py server.py
    访问 http://localhost:8080

Kimi API Key 配置（两种方式选一种）：
    方式1：环境变量  set KIMI_API_KEY=sk-kN6x0m7OJKrqxsecMItTLJ9MfZusgufHnyXcATgYbfjoURD5  （推荐）
    方式2：直接写在下面的 API_KEY 变量里（本地用可以，别上传 git）
"""

import os
import json
import re
import time
from flask import Flask, send_from_directory, jsonify, request

# ── 配置 ──────────────────────────────────────────────────────────────────────
API_KEY   = os.environ.get("KIMI_API_KEY", "")
BASE_URL  = "https://api.moonshot.cn/v1"
MODEL     = "moonshot-v1-8k"
PORT      = int(os.environ.get("PORT", 8080))

ROOT_DIR  = os.path.dirname(os.path.abspath(__file__))

app = Flask(__name__, static_folder=ROOT_DIR, static_url_path="")


# ── 静态文件服务 ───────────────────────────────────────────────────────────────

@app.route("/")
def index():
    return send_from_directory(ROOT_DIR, "index.html")

@app.route("/<path:path>")
def static_files(path):
    return send_from_directory(ROOT_DIR, path)


# ── AI 出题接口 ────────────────────────────────────────────────────────────────

# 题目分类池（保证覆盖面广，避免重复）
CATEGORIES = [
    "基础规则", "牌型判断", "搭档配合", "炸弹使用",
    "出牌时机", "首家策略", "进攻策略", "防守策略",
    "级牌规则", "升级计分", "复杂局面", "心理博弈",
    "特殊牌型", "残局技巧", "开局布局"
]

PROMPT_TEMPLATE = """你是一位掼蛋扑克专家，请生成一道高质量的掼蛋知识测试题。

要求：
1. 题目类别：{category}
2. 难度等级：{difficulty}（1-5，1最简单）
3. 四个选项（A/B/C/D），只有一个正确答案
4. 答案要有实际意义，考察真实的掼蛋策略或规则
5. 解析要具体，说明"为什么"而不只是"是什么"

请严格按照以下JSON格式输出，不要有任何额外内容：
{{
  "category": "{category}",
  "difficulty": {difficulty},
  "points": {points},
  "text": "题目内容",
  "options": ["A. 选项一", "B. 选项二", "C. 选项三", "D. 选项四"],
  "answer": 0,
  "explanation": "详细解析（100字以上）"
}}

注意：answer 是正确答案的索引，0=A，1=B，2=C，3=D。"""


def _call_kimi(prompt: str) -> str:
    """调用 Kimi API，返回文本"""
    import urllib.request
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    }
    body = json.dumps({
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.85,
        "max_tokens": 800,
    }).encode()

    req = urllib.request.Request(
        f"{BASE_URL}/chat/completions",
        data=body, headers=headers, method="POST"
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.loads(resp.read())
    return data["choices"][0]["message"]["content"]


def _parse_question(raw: str, question_id: int) -> dict:
    """从 AI 返回文本中提取 JSON 题目"""
    # 尝试直接解析
    try:
        q = json.loads(raw.strip())
    except json.JSONDecodeError:
        # 提取 ```json ... ``` 或第一个 { ... }
        match = re.search(r'\{[\s\S]*\}', raw)
        if not match:
            raise ValueError("AI返回内容无法解析为JSON")
        q = json.loads(match.group())

    # 校验必要字段
    required = ["text", "options", "answer", "explanation"]
    for field in required:
        if field not in q:
            raise ValueError(f"缺少字段: {field}")
    if len(q["options"]) != 4:
        raise ValueError("选项必须是4个")
    if not isinstance(q["answer"], int) or not (0 <= q["answer"] <= 3):
        raise ValueError("answer 必须是 0-3 的整数")

    q["id"] = question_id
    q.setdefault("difficulty", 3)
    q.setdefault("points", 10)
    q.setdefault("category", "AI出题")
    return q


@app.route("/api/ai-question", methods=["POST"])
def ai_question():
    """
    生成一道 AI 掼蛋题目

    请求体（JSON，可选）：
        {
            "question_index": 0,        // 第几题（0-9），用于控制难度递进
            "used_categories": []       // 已使用的分类，避免重复
        }

    返回：
        成功: { "ok": true, "question": {...} }
        失败: { "ok": false, "error": "..." }
    """
    if not API_KEY:
        return jsonify({"ok": False, "error": "未配置 KIMI_API_KEY，请在 server.py 中设置 API Key"}), 500

    data = request.get_json(silent=True) or {}
    q_index       = int(data.get("question_index", 0))
    used_cats     = set(data.get("used_categories", []))

    # 难度随题目序号递进（前3题简单，后3题难）
    if q_index <= 2:
        difficulty = 2
        points = 8
    elif q_index <= 5:
        difficulty = 3
        points = 10
    elif q_index <= 7:
        difficulty = 4
        points = 12
    else:
        difficulty = 5
        points = 15

    # 选一个未用过的分类
    available = [c for c in CATEGORIES if c not in used_cats]
    if not available:
        available = CATEGORIES  # 全用过了就重置
    import random
    category = random.choice(available)

    prompt = PROMPT_TEMPLATE.format(
        category=category,
        difficulty=difficulty,
        points=points,
    )

    try:
        raw = _call_kimi(prompt)
        question = _parse_question(raw, question_id=100 + q_index)
        return jsonify({"ok": True, "question": question})
    except Exception as e:
        # 把原始返回也带上，方便调试
        raw_preview = locals().get('raw', '')[:300] if 'raw' in locals() else '(no response)'
        return jsonify({"ok": False, "error": str(e), "raw": raw_preview}), 500


@app.route("/api/health")
def health():
    return jsonify({
        "ok": True,
        "api_key_set": bool(API_KEY),
        "model": MODEL,
        "time": time.time()
    })


# ── 启动 ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print(f"\n{'='*50}")
    print(f"  爱掼蛋 AI 出题服务器")
    print(f"  访问: http://localhost:{PORT}")
    if not API_KEY:
        print(f"\n  ⚠️  警告：未设置 KIMI_API_KEY")
        print(f"  请运行: set KIMI_API_KEY=sk-你的key")
        print(f"  或直接在 server.py 第13行填入 API Key")
    else:
        print(f"  ✓ API Key 已配置")
    print(f"{'='*50}\n")
    app.run(host="0.0.0.0", port=PORT, debug=False)
