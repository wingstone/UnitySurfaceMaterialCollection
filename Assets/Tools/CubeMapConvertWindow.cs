using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using System.IO;


namespace Tools
{
    public class CubeMapConvertWindow : EditorWindow
    {


        // ================================================================================
        //  menu entry
        // --------------------------------------------------------------------------------

        [MenuItem("Window/Convert Cubemap")]
        public static void CubemapConvertMenu()
        {
            GetWindow(typeof(CubeMapConvertWindow), false, "Convert Cubemap");
        }

        // ================================================================================
        //  unity methods
        // --------------------------------------------------------------------------------

        Texture2D srcTex;
        Cubemap cubemap;
        Material toCubematerial;
        Shader toCubeshader;
        Material toMatcapmaterial;
        Shader toMatcapshader;

        Vector3 matcapView;

        public void OnGUI()
        {
            srcTex = EditorGUILayout.ObjectField(srcTex, typeof(Texture2D), false) as Texture2D;
            toCubeshader = EditorGUILayout.ObjectField(toCubeshader, typeof(Shader), false) as Shader;
            if (toCubeshader && !toCubematerial)
                toCubematerial = new Material(toCubeshader);

            cubemap = EditorGUILayout.ObjectField(cubemap, typeof(Cubemap), false) as Cubemap;
            toMatcapshader = EditorGUILayout.ObjectField(toMatcapshader, typeof(Shader), false) as Shader;
            if (toMatcapshader && !toMatcapmaterial)
                toMatcapmaterial = new Material(toMatcapshader);

            if (GUILayout.Button("Convert To Matcap"))
            {
                for (int i = 1; i <= 10; i++)
                {
                    int width = 1024 >> i;
                    RenderTexture rt = RenderTexture.GetTemporary(width, width, 0, RenderTextureFormat.ARGB32);
                    toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                    toMatcapmaterial.SetFloat("_LOD", i);
                    toMatcapmaterial.SetFloat("_SrcMipmapCount", cubemap.mipmapCount);
                    toMatcapmaterial.SetFloat("_OmegaPInv", 6.0f * cubemap.width * cubemap.width / (4f * Mathf.PI));

                    Graphics.Blit(rt, rt, toMatcapmaterial, 0);

                    var tex = new Texture2D(width, width);
                    RenderTexture.active = rt;
                    tex.ReadPixels(new Rect(0, 0, width, width), 0, 0);
                    tex.Apply();
                    RenderTexture.ReleaseTemporary(rt);

                    string path = AssetDatabase.GetAssetPath(cubemap) + "_Matcap" + "_mip" + i + ".png";
                    File.WriteAllBytes(path, tex.EncodeToPNG());

                }

                AssetDatabase.Refresh();
                for (int i = 1; i <= 10; i++)
                {
                    string path = AssetDatabase.GetAssetPath(cubemap) + "_Matcap" + "_mip" + i + ".png";
                    TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                    importer.textureType = TextureImporterType.Default;
                    importer.mipmapEnabled = false;
                    importer.isReadable = true;
                    importer.SaveAndReimport();
                }

                //mip 0
                {
                    int width = 1024;
                    RenderTexture rt = RenderTexture.GetTemporary(width, width, 0, RenderTextureFormat.ARGB32);
                    toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                    toMatcapmaterial.SetFloat("_LOD", 0);
                    toMatcapmaterial.SetFloat("_SrcMipmapCount", cubemap.mipmapCount);
                    toMatcapmaterial.SetFloat("_OmegaPInv", 6.0f * cubemap.width * cubemap.width / (4f * Mathf.PI));

                    Graphics.Blit(rt, rt, toMatcapmaterial, 0);

                    var tex = new Texture2D(width, width);
                    RenderTexture.active = rt;
                    tex.ReadPixels(new Rect(0, 0, width, width), 0, 0);
                    tex.Apply();
                    RenderTexture.ReleaseTemporary(rt);

                    string path = AssetDatabase.GetAssetPath(cubemap) + "_Matcap" + "_mip" + ".png";
                    File.WriteAllBytes(path, tex.EncodeToPNG());

                }

                AssetDatabase.Refresh();
                {
                    string path = AssetDatabase.GetAssetPath(cubemap) + "_Matcap" + "_mip" + ".png";
                    TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                    importer.textureType = TextureImporterType.Default;
                    importer.mipmapEnabled = true;
                    importer.isReadable = true;
                    importer.SaveAndReimport();
                }

            }

            // srcTex = EditorGUILayout.ObjectField(srcTex, typeof(Texture2D), false) as Texture2D;

            // if (GUILayout.Button("Convert To Matcap"))
            // {
            //     RenderTexture ret = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
            //     RenderTexture reet = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
            //     Graphics.Blit(srcTex, ret);
            //     Graphics.CopyTexture(ret, reet);

            //     var teex = new Texture2D(1024, 1024);
            //     RenderTexture.active = reet;
            //     teex.ReadPixels(new Rect(0, 0, 1024, 1024), 0, 0);
            //     teex.Apply();
            //     RenderTexture.ReleaseTemporary(ret);
            //     RenderTexture.ReleaseTemporary(reet);
            //     string pah = AssetDatabase.GetAssetPath(cubemap) + "_test" + ".png";
            //     File.WriteAllBytes(pah, teex.EncodeToPNG());
            // }
        }

    }
}
