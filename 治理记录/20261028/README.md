# 2026-10-28 仓库治理证据

- [完整报告](../../仓库整理报告-2026-10-28.md)
- [整理前清单](inventory-before.json)：逐文件路径、大小、类型、Git跟踪状态与SHA256；不含.git内部和本治理输出目录。
- [全量分类清单](全量分类清单.csv)：初步用途分类；“历史归档”包含原位置保留，并不表示全部搬迁。
- [逐项处置清单](处置清单.csv)与[机器可读映射](actions.json)：每项旧位置、新位置、理由及原SHA256。
- [链接修复](link-repairs.json)、[原有断链](broken-links-before.json)、[整理后断链](broken-links-after.json)、[验证结论](validation.json)。断链是启发式检测候选，不能据此删除文件。
- [原有用户修改补丁](existing-user-changes.patch)与git-status-before.txt：任务开始时的工作树状态。
- before/：被修改文件的任务前原字节副本；工作材料归档/：完整保留的临时文稿、脚本与P2检查记录。两者为本地忽略目录，不会随普通Git提交传播。
- deleted-files.zip：已删除预览与字节码的恢复副本；归档条目路径相对仓库根。恢复前检查目标是否已有新文件，避免覆盖。

恢复单文件：从before/复制对应文件，或从deleted-files.zip提取相应条目到仓库根。恢复迁移材料：按照actions.json将new移回old；若旧路径已有内容，先人工比较。SHA256可与inventory-before.json核对。

治理备份不纳入活跃研究入口。归档内脚本保留原字节，不保证搬迁后可直接执行；确有需要时先按映射恢复原工作目录。恢复包留在本机，因此本次清理主要改善目录秩序，不等于回收全部原始磁盘空间。
