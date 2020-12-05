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

        Cubemap cubemap;
        Material toCubematerial;
        Shader toCubeshader;
        Material toMatcapmaterial;
        Shader toMatcapshader;

        Vector3 matcapView;

        public void OnGUI()
        {
            // texture
            cubemap = EditorGUILayout.ObjectField(cubemap, typeof(Cubemap)) as Cubemap;

            toCubematerial = EditorGUILayout.ObjectField(toCubematerial, typeof(Material)) as Material;
            toMatcapmaterial = EditorGUILayout.ObjectField(toMatcapmaterial, typeof(Material)) as Material;

            matcapView = EditorGUILayout.Vector3Field("Matcap View", matcapView);

            if (GUILayout.Button("Convert To Matcap"))
            {
                RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
                toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                Graphics.Blit(rt, rt, toMatcapmaterial, 0);

                var tex = new Texture2D(1024, 1024);
                RenderTexture.active = rt;
                tex.ReadPixels(new Rect(0, 0, 1024, 1024), 0, 0);
                tex.Apply();
                File.WriteAllBytes(AssetDatabase.GetAssetPath(cubemap) + "_Matcap.png", tex.EncodeToPNG());

                AssetDatabase.Refresh();
            }

            if (GUILayout.Button("Convert To Cylindrical"))
            {
                RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
                toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                Graphics.Blit(rt, rt, toMatcapmaterial, 1);

                var tex = new Texture2D(2048, 1024);
                RenderTexture.active = rt;
                tex.ReadPixels(new Rect(0, 0, 2048, 1024), 0, 0);
                tex.Apply();
                File.WriteAllBytes(AssetDatabase.GetAssetPath(cubemap) + "_Cylinder.png", tex.EncodeToPNG());

                AssetDatabase.Refresh();
            }

            if (GUILayout.Button("Convert To SphereMap"))
            {
                RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
                toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                Graphics.Blit(rt, rt, toMatcapmaterial, 2);

                var tex = new Texture2D(1024, 1024);
                RenderTexture.active = rt;
                tex.ReadPixels(new Rect(0, 0, 1024, 1024), 0, 0);
                tex.Apply();
                File.WriteAllBytes(AssetDatabase.GetAssetPath(cubemap) + "_SphereMap.png", tex.EncodeToPNG());

                AssetDatabase.Refresh();
            }

            if (GUILayout.Button("Convert To CrossLayout"))
            {
                RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGB32);
                toMatcapmaterial.SetTexture("_Cubemap", cubemap);
                Graphics.Blit(rt, rt, toMatcapmaterial, 3);

                var tex = new Texture2D(256*6, 256);
                RenderTexture.active = rt;
                tex.ReadPixels(new Rect(0, 0, 256*6, 256), 0, 0);
                tex.Apply();
                File.WriteAllBytes(AssetDatabase.GetAssetPath(cubemap) + "_CrossLayout.png", tex.EncodeToPNG());

                AssetDatabase.Refresh();
            }
        }

    }
}
