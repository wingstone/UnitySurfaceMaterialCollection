﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Text.RegularExpressions;

public class CustomMipmapForIBL : AssetPostprocessor
{
    bool ShouldImportAsset(string path)
    {
        string pattern = GetMipmapFilenamePattern(path);
        string mip1Path = string.Format(pattern, 1);
        return File.Exists(mip1Path);
    }

    string GetMipmapFilenamePattern(string path)
    {
        var filename = Path.GetFileName(path);
        var filenameWithoutExtention = Path.GetFileNameWithoutExtension(path);
        filenameWithoutExtention = filenameWithoutExtention.Substring(0, filenameWithoutExtention.IndexOf("_mip"));
        var extension = Path.GetExtension(path);
        var directoryName = Path.GetDirectoryName(path);

        return Path.Combine(directoryName, filenameWithoutExtention + "_mip{0}" + extension);
    }

    void OnPostprocessTexture(Texture2D texture)
    {
        var filenameWithoutExtention = Path.GetFileNameWithoutExtension(assetPath);
        if (filenameWithoutExtention.EndsWith("_mip"))
        {
            string pattern = GetMipmapFilenamePattern(assetPath);

            for (int m = 1; m < texture.mipmapCount; m++)
            {
                var mipmapTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(string.Format(pattern, m));

                if (mipmapTexture != null)
                {
                    Color[] c = mipmapTexture.GetPixels(0);
                    texture.SetPixels(c, m);
                }
            }

            texture.Apply(false, false);
            TextureImporter textureImporter = (TextureImporter)assetImporter;
            textureImporter.isReadable = true;
        }
    }
}

