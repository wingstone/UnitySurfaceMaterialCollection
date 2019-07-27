using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class TextureArrayCreateWindow : EditorWindow
{
    public int texNum = 10;
    public Texture2D[] textures;
    public ECopyTexMethpd copyTexMethod = ECopyTexMethpd.CopyTexture;
    public TextureFormat textureFormat = TextureFormat.ASTC_RGBA_4x4;

    public Vector2 scrollPos;

    public enum ECopyTexMethpd
    {
        // 使用 Graphics.CopyTexture
        CopyTexture = 0,
        // 使用 Texture2DArray.SetPixels
        SetPexels = 1
    }

    TextureArrayCreateWindow()
    {
        this.titleContent = new GUIContent("TextureArrayCreateWindow");
    }

    private void OnEnable()
    {
        textures = new Texture2D[texNum];
    }

    [MenuItem("Create/TextureArray")]
    static void InitWindow()
    {
        TextureArrayCreateWindow window = (TextureArrayCreateWindow)EditorWindow.GetWindow(typeof(TextureArrayCreateWindow), true);
        window.Show();
    }

    private void OnGUI()
    {
        GUILayout.Label("Texture Array Create Setting", EditorStyles.boldLabel);

        GUITexture();

        copyTexMethod = (ECopyTexMethpd)EditorGUILayout.EnumPopup("Copy Texture Method", copyTexMethod);

        textureFormat = (TextureFormat)EditorGUILayout.EnumPopup("Texture Format", textureFormat);
                
        if (GUILayout.Button("Create Texture Array"))
        {
            if(!SystemInfo.SupportsTextureFormat(textureFormat))
            {
                Debug.Log(DebugPrefix() + "System don't support this setting texture format!!");
                return;
            }
            CreateTextureArray();
        }
    }

    void GUITexture()
    {
        //slider
        int oldTexNum = texNum;
        texNum = EditorGUILayout.IntSlider(texNum, 1, 100);
        if (oldTexNum != texNum)
        {
            Texture2D[] oldTextures = textures;
            textures = new Texture2D[texNum];
            for (int i = 0; i < Math.Min(oldTexNum, texNum); i++)
            {
                textures[i] = oldTextures[i];
            }
        }

        //scroll view
        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);

        for (int i = 0; i < texNum; i++)
        {
            textures[i] = (Texture2D)EditorGUILayout.ObjectField("Texture " + i + " :", textures[i], typeof(Texture2D), false);
        }

        EditorGUILayout.EndScrollView();
    }

    void CreateTextureArray()
    {
        if (textures == null || textures.Length == 0)
        {
            return;
        }

        if (SystemInfo.copyTextureSupport == CopyTextureSupport.None ||
            !SystemInfo.supports2DArrayTextures)
        {
            return;
        }

        Texture2DArray texArr = new Texture2DArray(textures[0].width, textures[0].width, textures.Length, textureFormat, false, false);

        if (copyTexMethod == ECopyTexMethpd.CopyTexture)
        {
            for (int i = 0; i < textures.Length; i++)
            {
                if (!CheckTexture(textures[i], i, texArr.width, texArr.height))
                    return;
                Graphics.CopyTexture(textures[i], 0, 0, texArr, i, 0);
            }
        }
        else if (copyTexMethod == ECopyTexMethpd.SetPexels)
        {
            for (int i = 0; i < textures.Length; i++)
            {
                if (!CheckTexture(textures[i], i, texArr.width, texArr.height))
                    return;
                texArr.SetPixels(textures[i].GetPixels(), i, 0);
            }
            texArr.Apply();
        }

        texArr.wrapMode = TextureWrapMode.Repeat;
        texArr.filterMode = FilterMode.Bilinear;

        AssetDatabase.CreateAsset(texArr, "Assets/TextureArray/textureArray.asset");
        Debug.Log(DebugPrefix() + "Export TextureArray Successful~");
    }

    string DebugPrefix()
    {
        return "Time :" + System.DateTime.Now + "-";
    }

    bool CheckTexture(Texture2D texture2D, int index, int width, int height)
    {   
        if (!texture2D)
        {
            Debug.Log(DebugPrefix() + "Texture " + index + " don't exist!!");
            return false;
        }
        if (texture2D.width != width ||
            texture2D.height != height)
        {
            Debug.Log(DebugPrefix() + "Texture " + index + " size is different with others!!");
            return false;
        }
        if (texture2D.format != textureFormat)
        {
            Debug.Log(DebugPrefix() + "Texture " + index + " have a different texture format with setting format");
            return false;
        }

        return true;
    }
}
