using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

public class LUTCreater
{
    // 生成LUT。
    [MenuItem("Assets/Create/netural lut")]
    public static void CreateNeturalLut()
    {
        var select = Selection.activeObject;
        var path = AssetDatabase.GetAssetPath(select);

        var name = path + "/netural.png";
        RenderTexture rt = RenderTexture.GetTemporary(1024, 32, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);

        Shader lutCreaterShader = Shader.Find("Custom/CreateLut");
        Material lutCreaterMat = new Material(lutCreaterShader);
        //(lut_height, 0.5 / lut_width, 0.5 / lut_height, lut_height / lut_height - 1)
        lutCreaterMat.SetVector("_lut_pars", new Vector4(32.0f, 0.5f/1024.0f, 0.5f/32.0f, 32.0f/(32.0f-1.0f)));
        Graphics.Blit(rt, rt, lutCreaterMat, 0);

        var tex = new Texture2D(1024, 32);
        RenderTexture.active = rt;
        tex.ReadPixels(new Rect(0, 0, 1024, 32), 0, 0);
        tex.Apply();
        RenderTexture.ReleaseTemporary(rt);

        File.WriteAllBytes(name, tex.EncodeToPNG());
        AssetDatabase.Refresh();
    }
}
