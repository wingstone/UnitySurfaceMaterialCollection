using UnityEngine;
using System.Collections;

public class EdgeDetect : PostEffectsBase {

	public Shader edgeDetectShader;
	private Material edgeDetectMaterial = null;
	public Material material {  
		get {
			edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
			return edgeDetectMaterial;
		}  
	}

    //commen
	[Range(0.0f, 1.0f)]
	public float edgeIntensity = 0.0f;
	public Color edgeColor = Color.black;
	public float sampleDistance = 1.0f;

    //color
    [Range(0.0f, 1.0f)]
    public float threshold = 1.0f;

    //depth normal
    public float sensitivityDepth = 1.0f;
	public float sensitivityNormals = 1.0f;

    //mode
    public enum EdgeDetectMode
    {
        SobelDepth = 0,
        RobertsCrossDepthNormals = 1,
        SobelColor = 2,
    }

    public EdgeDetectMode mode = EdgeDetectMode.SobelColor;

    void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}

	//[ImageEffectOpaque]
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {

			material.SetColor("_EdgeColor", edgeColor);
			material.SetFloat("_SampleDistance", sampleDistance);
			material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));
            material.SetFloat("_Threshold", threshold);
            material.SetFloat("_EdgeIntensity", edgeIntensity);

			Graphics.Blit(src, dest, material, (int)mode);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
