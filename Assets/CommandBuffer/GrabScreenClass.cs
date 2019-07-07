using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class GrabScreenClass : MonoBehaviour
{
    public Shader blurShader;
    private Material blurMaterial;

    private Camera m_Came;
    private Dictionary<Camera, CommandBuffer> m_Cameras = new Dictionary<Camera, CommandBuffer>();

    void CleanUp()
    {
        foreach (var cam in m_Cameras)
        {
            if (cam.Key)
            {
                cam.Key.RemoveCommandBuffer(CameraEvent.AfterSkybox, cam.Value);
            }
        }
        m_Cameras.Clear();
    }

    private void OnEnable()
    {
        CleanUp();
    }

    private void OnDisable()
    {
        CleanUp();
    }

    public void OnWillRenderObject()
    {
        var act = gameObject.activeInHierarchy && enabled;
        if(!act)
        {
            CleanUp();
            return;
        }

        var came = Camera.current;
        if (!came)
            return;

        if (m_Cameras.ContainsKey(came))
            return;

        var cmdBuffer = new CommandBuffer();
        cmdBuffer.name = "Grab Screen Tex";
        m_Cameras[came] = cmdBuffer;

        if(!blurMaterial)
        {
            if (!blurShader)
                return;
            blurMaterial = new Material(blurShader);
            blurMaterial.hideFlags = HideFlags.HideAndDontSave;
        }

        int grabTexID = Shader.PropertyToID("_GrabTex");
        int blurGrabID = Shader.PropertyToID("_BlurGrabTex");
        cmdBuffer.GetTemporaryRT(grabTexID, -1, -1, 0, FilterMode.Bilinear);
        cmdBuffer.Blit(BuiltinRenderTextureType.CurrentActive, grabTexID);

        int blurOne = Shader.PropertyToID("_BlurOne");
        cmdBuffer.GetTemporaryRT(blurOne, -1, -1, 0, FilterMode.Bilinear);
        int blurTwo = Shader.PropertyToID("_BlurTwo");
        cmdBuffer.GetTemporaryRT(blurTwo, -1, -1, 0, FilterMode.Bilinear);

        cmdBuffer.Blit(grabTexID, blurOne);
        cmdBuffer.Blit(blurOne, blurTwo, blurMaterial, 0);
        cmdBuffer.Blit(blurTwo, blurOne, blurMaterial, 1);
        cmdBuffer.Blit(blurOne, blurTwo, blurMaterial, 0);
        cmdBuffer.Blit(blurTwo, blurOne, blurMaterial, 1);
        cmdBuffer.SetGlobalTexture(blurGrabID, blurOne);
        //cmdBuffer.Blit(blurOne, blurGrabID);

        came.AddCommandBuffer(CameraEvent.AfterSkybox, cmdBuffer);
    }
}
