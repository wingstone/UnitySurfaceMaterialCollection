using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class lut : MonoBehaviour
{
    public Shader lutShader;
    public Texture2D lutTex;
    private Material lutMat;
    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (lutShader != null && lutTex != null)
        {
            if (lutMat == null)
                lutMat = new Material(lutShader);

            lutMat.SetTexture("_lut", lutTex);
            lutMat.SetVector("_lut_pars", new Vector4(1.0f / lutTex.width, 1.0f / lutTex.height, lutTex.height - 1));
            Graphics.Blit(src, dst, lutMat);
        }
    }
}
