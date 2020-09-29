using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class LightDepthMap : MonoBehaviour
{
    RenderTexture depthMap;
    Shader depthShader;

    // Start is called before the first frame update
    private void OnEnable()
    {
        Camera camera = GetComponent<Camera>();
        depthMap = RenderTexture.GetTemporary(1024, 1024, 16, RenderTextureFormat.Depth);
        camera.targetTexture = depthMap;
        depthShader = Shader.Find("Human/RenderLightDepth");
        camera.enabled = false;
    }

    // Update is called once per frame
    private void Update()
    {
        Camera camera = GetComponent<Camera>();
        camera.RenderWithShader(depthShader, "RenderType");
        Shader.SetGlobalTexture("_LightDepthMap", depthMap);
        Matrix4x4 matrix = camera.projectionMatrix*camera.worldToCameraMatrix;
        Shader.SetGlobalMatrix("_LightMatrix", matrix);
    }

    private void OnDisable()
    {
        RenderTexture.ReleaseTemporary(depthMap);
    }


}
