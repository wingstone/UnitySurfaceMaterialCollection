#ifndef _COMMEN_ENVIROMENT_
#define _COMMEN_ENVIROMENT_

#include "CommenSurface.cginc"

half3 GetIBLColor(SurfaceTexData surfaceTexData, SurfaceOtherData surfaceOtherData)
{
	half3 IBLColor;
#ifdef _GLOSSYREFLECTIONS_OFF
	IBLColor = unity_IndirectSpecColor.rgb;

#else
	half mip = surfaceTexData.roughness * (1.7 - 0.7*surfaceTexData.roughness)*UNITY_SPECCUBE_LOD_STEPS;
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, surfaceOtherData.reflectDir, mip);
	IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR)*surfaceTexData.occlusion;
#endif

	//已经验证！获取的IBLColor确实是Gamma空间的！如果使用gamma空间的话
	//注意如果使用自定义的skybox，需要手动标记skybox是否在gamma空间
	//gamma空间的skybox显示的颜色就是，理论正确计算后输出的颜色

	//这就有个问题，如果使用线性空间的box，就必须使用线性空间流程，
	//若使用gamma空间流程就只能改代码不进行下面的转换了，但这样就不能使用gamm空间的box了，所以说最好使用gamma空间的box

#ifdef UNITY_COLORSPACE_GAMMA
	return GammaToLinearSpace(IBLColor)*surfaceTexData.occlusion;
#else
	return IBLColor * surfaceTexData.occlusion;
#endif
}


#endif