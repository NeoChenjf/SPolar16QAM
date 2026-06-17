# L3 方法契约层 Schema —— Method Contract

> L3 是「原子方法契约」层。每个 L3 文件描述一个 `.m` 函数：它的签名、一句话功能、
> 数学/算法定义、数值稳定性坑、依赖的其它方法、健康状态。对标 hic-spec 的「原子工具
> 契约」，但工具是科研代码里的数学/算法函数。
>
> 一句话类比：L3 就像实验室里每台仪器的「铭牌 + 说明书」——输入接什么、输出是什么、
> 内部原理（公式）、使用注意事项（数值坑）、依赖哪些别的仪器、当前是否好用。

---

## 文件命名

`workbook/knowledge/L3/{module}/l3_{func}.md`
例：`L3/polar/l3_SC_decoder.md`（对应 `16QAM_Polar/v2/polar/SC_decoder.m`）

`{module}` ∈ `core` / `polar` / `modulation` / `analysis`

## 字段定义

| 字段 | 必填 | 说明 |
|------|------|------|
| `method_id` | ✅ | `l3_*`，全局唯一 |
| `file_path` | ✅ | `.m` 文件相对路径 |
| `module` | ✅ | core / polar / modulation / analysis |
| `signature` | ✅ | 输入参数（名/类型/含义）、输出参数 |
| `purpose` | ✅ | 一句话功能 |
| `math_definition` | ✅ | 数学/算法定义，保留公式与伪代码语义 |
| `numerical_notes` | ⬜ | 数值稳定性/精度坑（LSE 防溢出、反函数数值、高斯近似误差等） |
| `dependencies` | ✅ | 调用的其它 L3（`l3_ref`）；无则写「无」 |
| `health` | ✅ | `healthy` / `degraded` / `broken` + 理由（如 legacy 口径、已知 bug） |

## Markdown 骨架

```markdown
# L3 · {func}

- **method_id**: l3_{func}
- **file_path**: 16QAM_Polar/v2/{module}/{func}.m
- **module**: polar
- **health**: healthy

## Signature
**输入**
| 参数 | 类型 | 含义 |
|------|------|------|
| llr | N×1 double | 信道 LLR |
| K | int | 信息位数 |

**输出**
| 参数 | 类型 | 含义 |
|------|------|------|
| decoded | K×1 | 译码信息位 |

## Purpose
（一句话）

## Math / Algorithm
（公式、递推、伪代码。例：SC 译码的 f/g 节点运算 f(a,b)=2·atanh(tanh(a/2)tanh(b/2))，
g(a,b,û)=b+(1-2û)a）

## Numerical Notes
- ⚠️ （如：用 log-sum-exp 防上溢）

## Dependencies
- l3_get_llr_layer, l3_get_bit_layer

## Health
healthy — 无已知问题
```

## 提取约束

1. **保真公式**：`math_definition` 照搬源码实现的数学口径（如 `E(p)=18-16p`、
   `I=1-E[log2(1+e^{-sL})]`、`S=ceil(N(1-h(p)))`），不口算改写。
2. **依赖即引用**：函数内调用的其它 `.m` 必须列入 `dependencies` 为 `l3_ref`，
   供 checker 做依赖图断链/成环检查。
3. **健康标注**：源码注释里提到的「修复了旧 bug」「legacy 口径」「@Deprecated 等价物」
   都应在 `health` / `numerical_notes` 标注，并影响 RKS 评分。
4. **绘图/报告类函数**（analysis）也建契约，但 `math_definition` 可简写为「可视化逻辑」。
