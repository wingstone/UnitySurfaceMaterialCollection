using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;



[RequireComponent(typeof( Camera))]
public class SaveRenderTextureToPNG : MonoBehaviour
{
    public enum SCREENMETHOD
    {
        RENDER_TEXTURE,
        CUSTOM_RENDER_TEXTURE,
        CAPTURE_SCREEN
    };

    #region PNG Size
    public int width = 1024;
    public int height = 1024;
    public SCREENMETHOD captureMethod = SCREENMETHOD.CUSTOM_RENDER_TEXTURE;
    #endregion

    Camera came = null;
    private void OnEnable()
    {
        came = GetComponent<Camera>();
    }

    //custom resolution, NO GUI
    private void CustomDumpRenderTexture(string pngOutPath)
    {
        var rt = new RenderTexture(width, height, 24);
        came.targetTexture = rt;
        came.Render();

        var tex = new Texture2D(width, height);
        RenderTexture.active = rt;
        tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);
        tex.Apply();
        File.WriteAllBytes(pngOutPath, tex.EncodeToPNG());

        RenderTexture.active = null;
        came.targetTexture = null;
        RenderTexture.DestroyImmediate(rt);
    }

    //screen resolution, NO GUI
    private void DumpRenderTexture(string pngOutPath)
    {
        var tex = new Texture2D(width, height);
        tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);
        tex.Apply();
        File.WriteAllBytes(pngOutPath, tex.EncodeToPNG());
    }

    //with GUI
    private void CaptureScreen(string pngOutPath)
    {
        ScreenCapture.CaptureScreenshot(pngOutPath);
    }

    public void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            switch (captureMethod)
            {
                case SCREENMETHOD.CAPTURE_SCREEN:
                    CaptureScreen("Assets/" + Time.time + ".png");
                    break;
                case SCREENMETHOD.RENDER_TEXTURE:
                    DumpRenderTexture("Assets/" + Time.time + ".png");
                    break;
                case SCREENMETHOD.CUSTOM_RENDER_TEXTURE:
                    CustomDumpRenderTexture("Assets/" + Time.time + ".png");
                    break;
                default:
                    break;
            }
        }
    }

}
