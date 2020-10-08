using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class VolumeLight : PostEffectsBase {

	public Shader volumeLightShader;
	public Texture2D skyBacklightTex;
	public Texture2D perlinNoiseTex;
	private Material volumeLightMaterial = null;
	public Material material {  
		get {
			volumeLightMaterial = CheckShaderAndCreateMaterial(volumeLightShader, volumeLightMaterial);
			return volumeLightMaterial;
		}  
	}

    //commen
	[Range(0.0f, 2.0f)]
	public float volumeScale = 1.0f;

	private void Update() 
	{
		if(Input.GetButton("Fire1"))
		{
			Vector2 inputpos = GetComponent<Camera>().ScreenToViewportPoint(Input.mousePosition);
			material.SetVector("_LightSourcePos", inputpos);	
		}
	}

	void OnRenderImage (RenderTexture src, RenderTexture dest) {

		if (material != null) {

			material.SetFloat("_VolumeScale", volumeScale);
			material.SetTexture("_SkyBacklight", skyBacklightTex);
			material.SetTexture("_NoiseTex", perlinNoiseTex);

			Graphics.Blit(src, dest, material);

		}
		else 
		{

			Graphics.Blit(src, dest);

		}
	}
}
