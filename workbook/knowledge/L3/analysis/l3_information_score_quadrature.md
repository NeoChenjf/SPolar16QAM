# L3 · 位度量信息分数求积

- method_id为l3_information_score_quadrature。
- file_path为16QAM_Polar/v2/analysis/information_score_quadrature.m。
- module为analysis，health为degraded：有限PMF及数值近似，尚无任意H/任意候选泛化证明。

## Signature

information_score_quadrature(p,sigma,order)输入16点联合PMF、每实维噪声标准差及Gauss–Hermite阶数，输出每16QAM符号的固定s=1位度量信息分数，单位bit/符号。

## Math / Algorithm

实际符号PMF和双实维高斯噪声下，积分 $\log_2(q(x,y)/\sum_{x'}p(x')q(x',y))$。四个位度量由均匀Gray16QAM接收LLR的星座似然相加后相乘，使用log-sum-exp。

## Numerical Notes

该分数不输出BER或实际Goodput；有限阶求积、训练分布误差、位置池化及缺失跨位置相关性需要评估。源自run_information_score_independent.m的已用局部公式。

## Dependencies

MATLAB qammod、de2bi、eig；作为l2_run_information_frontier_main步骤。
