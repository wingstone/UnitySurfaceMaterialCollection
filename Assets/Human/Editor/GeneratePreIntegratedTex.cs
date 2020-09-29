using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using System.IO;

public class GeneratePreIntegratedTex
{
    static void Create(int p_width, int p_height, string name, int pass)
    {
        string path = AssetDatabase.GetAssetPath(Selection.activeObject);

        if (path == "")
            path = "Assets";
        else if (Path.GetExtension(path) != "")
            path = path.Replace(Path.GetFileName(AssetDatabase.GetAssetPath(Selection.activeObject)), "");

        string assetPathAndName = AssetDatabase.GenerateUniqueAssetPath(path + "/"+name);

        Material material = new Material(Shader.Find("Human/LookupTexture"));
        RenderTexture rt = new RenderTexture(p_width, p_height, 32);
        Texture2D tex = new Texture2D(p_width, p_height, TextureFormat.RGBA32, true);
        Graphics.Blit(tex, rt, material, pass);
        RenderTexture.active = rt;
        tex.ReadPixels(new Rect(0, 0, p_width, p_height), 0, 0);
        tex.Apply();

        byte[] pngData = tex.EncodeToPNG();
        File.WriteAllBytes(assetPathAndName, pngData);
        Object.DestroyImmediate(tex);
        Object.DestroyImmediate(material);
        Object.DestroyImmediate(rt);
        AssetDatabase.Refresh();

        TextureImporter ti = (TextureImporter)TextureImporter.GetAtPath(assetPathAndName);
        ti.textureType = TextureImporterType.Default;
        ti.textureFormat = TextureImporterFormat.RGBA32;
        ti.textureCompression = TextureImporterCompression.Uncompressed;
        ti.sRGBTexture = true;
        ti.wrapMode = TextureWrapMode.Clamp;

        AssetDatabase.ImportAsset(assetPathAndName);
        AssetDatabase.Refresh();
    }

    [MenuItem("Assets/Create/PreintegratedLookup/skin")]
    static void PreintegratedLookupSkin()
    {
        Create(1024, 1024, "PreintegratedLookupSkin.png", 1);
    }

    [MenuItem("Assets/Create/PreintegratedLookup/shadow")]
    static void PreintegratedLookupShadow()
    {
        Create(1024, 1024, "PreintegratedLookupShadow.png", 0);
    }
}