# L3 · write_energy_csv

输入路径、列名cell及数值矩阵。校验列数，写17位精度数值CSV，打开或写出失败报错，onCleanup关闭句柄。用于结果与checkpoint；不负责覆盖策略，上游入口负责时间戳新目录。测试包含数值往返和不存在父目录错误路径。
