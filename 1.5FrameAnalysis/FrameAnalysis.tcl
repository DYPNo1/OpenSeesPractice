# ----------------------------------------------------------------
# 建模部分
wipe
model BasicBuilder -ndm 2 -ndf 3
if {[file exists output]==0} {
    file mkdir output;
}

node 1 0 0 
node 2 0 3.0
node 3 0 6.0
fix 1 1 1 1 ;#约束节点1的三个自由度

geomTransf Linear 1;#单元类型为梁柱单元
element elasticBeamColumn 1 1 2 0.25 3.0e10 5.2e-3 1 
element elasticBeamColumn 2 2 3 0.25 3.0e10 5.2e-3 1 

# 代码输出记录部分
# Drift表示输出记录层间位移角
recorder Node -file output/disp_3.out -time -node 3 -dof 1 2 3 disp
recorder Node -file output/disp_2.out -time -node 2 -dof 1 2 3 disp
recorder Node -file output/reaction_1.out -time -node 1 -dof 1 2 3 reaction
recorder Drift -file output/drift_1.out -time -iNode 1 -jNode 2 -dof 1 -perpDirn 2
recorder Drift -file output/drift_2.out -time -iNode 2 -jNode 3 -dof 1 -perpDirn 2
recorder Element -file output/force_1.out -time -ele 1 globalForce


# ----------------------------------------------------------------
# （1）重力分析部分
pattern Plain 1 Linear {
    load 2 0. -1.0e5 0.0
    load 3 0. -1.0e5 0.0
}
constraints Plain;#表示边界约束方程的处理方式
numberer Plain;#结构自由度的编号方式
system BandGeneral;#方程的储存和求解方式
test NormDispIncr 1.0e-8 6 2;#用位移增量判断收敛
algorithm Newton;#用牛顿迭代法进行计算
integrator LoadControl 0.1;#表示用力加载控制方式
analysis Static;#静力加载
analyze 10;#分析10步完成全部外力的加载分析
puts "----------------------------------------------------------------"
puts {"The frame analysis under gravity is finished"}
puts "----------------------------------------------------------------"


# ----------------------------------------------------------------
# （2）水平pushover分析
# loadConst -time 0.0
# pattern Plain 2 Linear {
#     load 2 0.5 0.0 0.0
#     load 3 1.0 0.0 0.0
# }   
# integrator DisplacementControl 3 1 0.001;#用位移控制加载，因此前面只能给定力的比例关系
# analyze 500;#分析500次，总位移为500*0.001=0.5m
# puts "----------------------------------------------------------------"
# puts {"the analysis of horizon-pushover is finished"}
# puts "----------------------------------------------------------------"


# ----------------------------------------------------------------
# （3）受到最大加速度为0.90g的地震作用
# 地震分析通常在重力分析完成之后，因此只需将（2）中的代码替换成下面的代码即可
mass 2 1.0e4 0.0 0.0;#节点2施加x方向的质量，y方向和旋转向的质量不考虑
mass 3 1.0e4 0.0 0.0
loadConst -time 0.0
timeSeries Path 1 -dt 0.02 -filePath tabas.txt -factor 9.8
pattern UniformExcitation 2 1 -accel 1;#定义荷载形式为基底一致激励 

# 此段内容为根据阻尼比确定Rayleigh阻尼的系数a0和a1
set temp [eigen 1]  ;#求解模型的一个特征值，返回的是一个包含特征值的字符串
scan $temp "%e" wls ;#将temp包含的特征值转换为数字类型，并赋值给wls
set wl [expr sqrt($wls)]
puts "----------------------------------------------------------------"
puts "The first-order frequency f:[expr $wl/6.28]"
puts "----------------------------------------------------------------"
set ksi 0.02
set a0 0
set a1 [expr $ksi*2.0/$wl]
rayleigh $a0 0.0 $a1 0.0 ;#用OpenSees的瑞利阻尼命令定义阻尼

wipeAnalysis
constraints Plain
numberer Plain
system BandGeneral
test NormDispIncr 1.0e-8 10 2
algorithm Newton
integrator Newmark 0.5 0.25
analysis Transient
analyze 1000 0.02
puts "----------------------------------------------------------------"
puts {"The anslysis of the ground-movement is finished."}
puts "----------------------------------------------------------------"

