using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Camera))]
public class DOFEffect : PostEffectsBase {

	public Shader dofEffectShader;
	private Material dofEffectMaterial = null;
	public Material material {  
		get {
			dofEffectMaterial = CheckShaderAndCreateMaterial(dofEffectShader, dofEffectMaterial);
			return dofEffectMaterial;
		}  
	}

    //commen
	[Range(0.0f, 100.0f)]
	public float focusDistance = 12.0f;
	[Range(0.0f, 20.0f)]
	public float focusRange = 2.0f;
	[Range(0.0f, 5.0f)]
	public float bokehRadius  = 1.0f;

	//pass
	const int cocPass = 0;
	const int preFilterPass = 1;
	const int bokehBlurPass = 2;
	const int postFilterPass = 3;
	const int combinePass = 4;

	//rt
	RenderTexture cocRT = null;
	RenderTexture downRT = null;
	RenderTexture blurRT = null;

	private void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}

	//[ImageEffectOpaque]
	void OnRenderImage (RenderTexture src, RenderTexture dest) {

		if(cocRT== null)
		{
			cocRT = RenderTexture.GetTemporary(src.width, src.height, 0, RenderTextureFormat.RHalf);
		}
		if(downRT == null)
		{
			downRT = RenderTexture.GetTemporary(src.width/2, src.height/2, 0, RenderTextureFormat.ARGBHalf);
		}
		if(blurRT == null)
		{
			blurRT = RenderTexture.GetTemporary(src.width/2, src.height/2, 0, RenderTextureFormat.ARGBHalf);
		}

		if (material != null) {

            material.SetFloat("_FocusDistance", focusDistance);
			material.SetFloat("_FocusRange", focusRange);
			material.SetFloat("_BokehRadius", bokehRadius);

			Graphics.Blit(src, cocRT, material, cocPass);
			
			material.SetTexture("_CoCTex", cocRT);
			Graphics.Blit(src, downRT, material, preFilterPass);
			Graphics.Blit(downRT, blurRT, material, bokehBlurPass);
			Graphics.Blit(blurRT, downRT, material, postFilterPass);
			material.SetTexture("_DoFTex", downRT);
			Graphics.Blit(src, dest, material, combinePass);

		} else {
			Graphics.Blit(src, dest);
		}
	}

	private void OnDisable() {
		if(cocRT)
		{
			RenderTexture.ReleaseTemporary(cocRT);
			cocRT = null;
		}

		if(downRT)
		{
			RenderTexture.ReleaseTemporary(downRT);
			downRT = null;
		}
	}
}
