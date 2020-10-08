using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RenderShadowMap : MonoBehaviour
{
    RenderTexture shadowMap;
    RenderTexture blurTmpShadowMap;
    Shader shadowShader;
    Shader blurShadowShader;
    Material material;

    // Start is called before the first frame update
    private void OnEnable()
    {
        Camera camera = GetComponent<Camera>();
        shadowMap = RenderTexture.GetTemporary(1024, 1024, 16, RenderTextureFormat.RFloat);
        blurTmpShadowMap = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.RFloat);
        camera.targetTexture = shadowMap;
        shadowShader = Shader.Find("ShadowMap/RenderShadowMap");
        blurShadowShader = Shader.Find("ShadowMap/ShadowMapBlur");
        material = new Material(blurShadowShader);
        material.hideFlags = HideFlags.DontSave;
        camera.enabled = false;
        Light light = GetComponent<Light>();
        light.shadows = LightShadows.None;
    }
    

    // Update is called once per frame
    private void Update()
    {
        Camera camera = GetComponent<Camera>();
        Shader.SetGlobalTexture("_LightShadowMap", shadowMap);
        Matrix4x4 matrix = camera.projectionMatrix * camera.worldToCameraMatrix;
        Shader.SetGlobalMatrix("_LightMatrix", matrix);
        camera.RenderWithShader(shadowShader, "RenderType");
        BlurShadowMap();
    }

    private void OnDisable()
    {
        RenderTexture.ReleaseTemporary(shadowMap);
        RenderTexture.ReleaseTemporary(blurTmpShadowMap);
    }

    private void BlurShadowMap()
    {
        Graphics.Blit(shadowMap, blurTmpShadowMap, material, 0);
        Graphics.Blit(blurTmpShadowMap, shadowMap, material, 1);
    }
}
