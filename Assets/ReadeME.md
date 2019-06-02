问题出来了！
在c#脚本中，计算的projectmat*viewmat与shader中的vp矩阵根本不一致；
若采用脚本中的vp矩阵计算，其深度范围刚好为（-1，1）
而采用shader中的vp矩阵计算，其深度范围刚好为(1，0)
卧槽，unity这是什么鬼，竟然在内部这样实现？？？？

参考[这里](https://docs.unity3d.com/Manual/SL-DepthTextures.html)，unity给出了答案

另外使用unity内部的_CameraDepthTexture时，其范围是（0，1）；