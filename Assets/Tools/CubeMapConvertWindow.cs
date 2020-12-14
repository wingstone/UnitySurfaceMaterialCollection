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
            // texture
            // srcTex = EditorGUILayout.ObjectField(srcTex, typeof(Texture2D), false) as Texture2D;
            // toCubeshader = EditorGUILayout.ObjectField(toCubeshader, typeof(Shader), false) as Shader;
            // if (toCubeshader)
            //     toCubematerial = new Material(toCubeshader);

            // cubemap = new Cubemap(256, TextureFormat.RGBA32, false);



            cubemap = EditorGUILayout.ObjectField(cubemap, typeof(Cubemap), false) as Cubemap;
            toMatcapshader = EditorGUILayout.ObjectField(toMatcapshader, typeof(Shader), false) as Shader;
            if (toMatcapshader)
                toMatcapmaterial = new Material(toMatcapshader);

            if (GUILayout.Button("Convert To Matcap"))
            {
                for (int i = 0; i <= 10; i++)
                {
                    int width = 1024 >> i;
                    RenderTexture rt = RenderTexture.GetTemporary(width, width, 0, RenderTextureFormat.ARGB32);
                    toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                    toMatcapmaterial.SetFloat("_LOD", i);
                    toMatcapmaterial.SetFloat("_SrcMipmapCount", cubemap.mipmapCount);
                    toMatcapmaterial.SetFloat("_OmegaPInv", 6.0f * cubemap.width * cubemap.width / (4f * Mathf.PI));
                    // Debug.Log(cubemap.width);

                    Graphics.Blit(rt, rt, toMatcapmaterial, 0);

                    var tex = new Texture2D(width, width);
                    RenderTexture.active = rt;
                    tex.ReadPixels(new Rect(0, 0, width, width), 0, 0);
                    tex.Apply();
                    RenderTexture.ReleaseTemporary(rt);

                    string path = AssetDatabase.GetAssetPath(cubemap) + "_Matcap" + i + ".png";
                    File.WriteAllBytes(path, tex.EncodeToPNG());
                    AssetDatabase.Refresh();
                    TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                    importer.textureType = TextureImporterType.Default;
                    importer.SaveAndReimport();
                }
            }

            if (GUILayout.Button("Convert To CrossLayout"))
            {
                RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
                toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                Graphics.Blit(rt, rt, toMatcapmaterial, 3);

                var tex = new Texture2D(256 * 6, 256);
                RenderTexture.active = rt;
                tex.ReadPixels(new Rect(0, 0, 256 * 6, 256), 0, 0);
                tex.Apply();
                File.WriteAllBytes(AssetDatabase.GetAssetPath(cubemap) + "_CrossLayout.png", tex.EncodeToPNG());

                AssetDatabase.Refresh();
            }
        }

    }
}
