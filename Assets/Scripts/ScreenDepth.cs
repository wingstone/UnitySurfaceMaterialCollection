using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ScreenDepth : MonoBehaviour
{
    public Material mat;

    // Start is called before the first frame update
    void Start()
    {
        Camera came = GetComponent<Camera>();

        //came.depthTextureMode = DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, mat);
    }
}
