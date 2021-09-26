wipe

#设置模型维度和自由度
model BasicBuilder -ndm 2 -ndf 2

#检查模型是否存在output输出文件夹
if {[file exists output]==0} {
    file mkdir output;
}

#设置模型节点，数字依次为节点编号，x、y方向的坐标位置
node 1  0.0 0.0
node 2 144.0 0.0
node 3 168.0 0.0
node 4 72.0 96.0

#设置约束
fix 1 1 1
fix 2 1 1
fix 3 1 1

#设置材料参数
uniaxialMaterial Elastic 1 3000.0

#设置单元
element truss 1 1 4 10.0 1
element truss 2 2 4 5.0 1
element truss 3 3 4 5.0 1

#设置输出部分
recorder Node -file output/disp_4.out -time -node 4 -dof 1 2 disp
recorder Node -file output/reaction_1.out -time -node 1 -dof 1 2 reaction
recorder Node -file output/reaction_2.out -time -node 2 -dof 1 2 reaction
recorder Node -file output/reaction_3.out -time -node 3 -dof 1 2 reaction

#在节点4上施加外力
pattern Plain 1 Linear {
    load 4 100.0 -50.0
}

#对结构进行有限元静力分析
wipeAnalysis
constraints Transformation
numberer RCM
system BandSPD
test NormDispIncr 1.0e-6 6 2 
algorithm Newton
integrator LoadControl 0.1 
analysis Static
analyze 10 

#对结构进行有限元动力分析
#需要读取一个加速度文件:elcentro.txt
# wipeAnalysis
# loadConst -time 0.0
# mass 4 100.0 100.0
# pattern UniformExcitation 2 1 -accel "Series -factor 3 -filePath elcentro.txt -dt 0.01"
# constraints Transformation
# numberer RCM
# system BandSPD
# test NormDispIncr 1.0e-6 6 4
# algorithm Newton
# integrator Newmark 0.5  0.25
# analysis Transient
# analyze 2000 0.01


# 这里打算输出什么，前面的recorder就要记下来，否则软件不会将结果进行记录，会直接报错
puts [nodeDisp 4 1]