using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

// https://github.com/miguel12345/UnityWireframeRenderer
public class WireframeBakeToolWindow : EditorWindow
{
    GameObject srcModel = null;

    [MenuItem("Window/Tools/Wireframe Bake Window")]
    static void Init()
    {
        // Get existing open window or if none, make a new one:
        WireframeBakeToolWindow window = (WireframeBakeToolWindow)EditorWindow.GetWindow(typeof(WireframeBakeToolWindow));
        window.Show();
    }

    void OnGUI()
    {
        EditorGUILayout.BeginVertical();
        GUILayout.Label("Wireframe Bake", EditorStyles.boldLabel);
        srcModel = EditorGUILayout.ObjectField("Src Model", srcModel, typeof(GameObject), false) as GameObject;
        if (srcModel != null)
        {
            if (GUILayout.Button("Bake wireframe to mesh"))
            {
                BakeWireframeMesh();
            }
        }
        EditorGUILayout.EndVertical();
    }

    void BakeWireframeMesh()
    {
        string path = AssetDatabase.GetAssetPath(srcModel);
        // Debug.Log(path);
        string dir = Path.GetDirectoryName(path);
        string goName = Path.GetFileNameWithoutExtension(path);

        object[] objects = AssetDatabase.LoadAllAssetsAtPath(path);
        List<Mesh> meshes = new List<Mesh>();
        foreach (var item in objects)
        {
            Mesh mesh = item as Mesh;
            if (mesh != null)
            {
                meshes.Add(mesh);
            }
        }

        foreach (var item in meshes)
        {
            var maximumNumberOfVertices = 65534; //Since unity uses a 16-bit indices, not sure if this is still the case. http://answers.unity3d.com/questions/255405/vertex-limit.html
            var meshTriangles = item.triangles;
            var meshColors = item.colors;
            var meshVertices = item.vertices;
            var meshUVs = item.uv;
            var meshUV2s = item.uv2;
            var meshNormals = item.normals;
            var meshTangents = item.tangents;
            var boneWeights = item.boneWeights;

            var numberOfVerticesRequiredForTheProcessedMesh = meshTriangles.Length;
            if (numberOfVerticesRequiredForTheProcessedMesh > maximumNumberOfVertices)
            {
                Debug.LogError("Wireframe renderer can't safely create the processed mesh it needs because the resulting number of vertices would surpass unity vertex limit!");
                return;
            }

            var processedMesh = new Mesh();
            processedMesh.name = item.name;
            var processedVertices = new Vector3[numberOfVerticesRequiredForTheProcessedMesh];

            var colorsArraySize = (meshColors.Length > 0) ? numberOfVerticesRequiredForTheProcessedMesh : 0;
            var processedColors = new Color[colorsArraySize];

            var UVsArraySize = (meshUVs.Length > 0) ? numberOfVerticesRequiredForTheProcessedMesh : 0;
            var processedUVs = new Vector2[UVsArraySize];

            var UV2sArraySize = (meshUV2s.Length > 0) ? numberOfVerticesRequiredForTheProcessedMesh : 0;
            var processedUV2s = new Vector2[UV2sArraySize];

            var processedUV3s = new Vector2[numberOfVerticesRequiredForTheProcessedMesh];
            var processedUV4s = new Vector2[numberOfVerticesRequiredForTheProcessedMesh];
            var processedTriangles = new int[numberOfVerticesRequiredForTheProcessedMesh];

            var normalsArraySize = (meshNormals.Length > 0) ? numberOfVerticesRequiredForTheProcessedMesh : 0;
            var processedNormals = new Vector3[normalsArraySize];

            var tangentsArraySize = (meshTangents.Length > 0) ? numberOfVerticesRequiredForTheProcessedMesh : 0;
            var processedTangents = new Vector4[tangentsArraySize];

            var boneWeigthsArraySize = (boneWeights.Length > 0) ? numberOfVerticesRequiredForTheProcessedMesh : 0;
            var processedBoneWeigths = new BoneWeight[boneWeigthsArraySize];

            for (var i = 0; i < meshTriangles.Length; i += 3)
            {
                processedVertices[i] = meshVertices[meshTriangles[i]];
                processedVertices[i + 1] = meshVertices[meshTriangles[i + 1]];
                processedVertices[i + 2] = meshVertices[meshTriangles[i + 2]];

                if (processedColors.Length > 0)
                {
                    processedColors[i] = meshColors[meshTriangles[i]];
                    processedColors[i + 1] = meshColors[meshTriangles[i + 1]];
                    processedColors[i + 2] = meshColors[meshTriangles[i + 2]];
                }

                if (processedUVs.Length > 0)
                {
                    processedUVs[i] = meshUVs[meshTriangles[i]];
                    processedUVs[i + 1] = meshUVs[meshTriangles[i + 1]];
                    processedUVs[i + 2] = meshUVs[meshTriangles[i + 2]];
                }

                if (processedUV2s.Length > 0)
                {
                    processedUV2s[i] = meshUV2s[meshTriangles[i]];
                    processedUV2s[i + 1] = meshUV2s[meshTriangles[i + 1]];
                    processedUV2s[i + 2] = meshUV2s[meshTriangles[i + 2]];
                }

                // save lenth to edge to uv3 uv4
                Vector3 v1 = processedVertices[i];
                Vector3 v2 = processedVertices[i + 1];
                Vector3 v3 = processedVertices[i + 2];
                float area = Vector3.Cross(v2 - v1, v3 - v1).magnitude * 0.5f;

                float length1 = area / (v3 - v2).magnitude;
                float length2 = area / (v3 - v1).magnitude;
                float length3 = area / (v2 - v1).magnitude;

                float minid = 2;
                if (length1 < length2)
                {
                    if (length1 < length3)
                        minid = 0;
                }
                else
                {
                    if (length2 < length3)
                        minid = 1;
                }

                processedUV3s[i] = new Vector2(length1, 0);
                processedUV3s[i + 1] = new Vector2(0, length2);
                processedUV3s[i + 2] = new Vector2(0, 0);

                processedUV4s[i] = new Vector2(0, minid);
                processedUV4s[i + 1] = new Vector2(0, minid);
                processedUV4s[i + 2] = new Vector2(length3, minid);

                processedTriangles[i] = i;
                processedTriangles[i + 1] = i + 1;
                processedTriangles[i + 2] = i + 2;

                if (processedNormals.Length > 0)
                {
                    processedNormals[i] = meshNormals[meshTriangles[i]];
                    processedNormals[i + 1] = meshNormals[meshTriangles[i + 1]];
                    processedNormals[i + 2] = meshNormals[meshTriangles[i + 2]];
                }

                if (processedTangents.Length > 0)
                {
                    processedTangents[i] = meshTangents[meshTriangles[i]];
                    processedTangents[i + 1] = meshTangents[meshTriangles[i + 1]];
                    processedTangents[i + 2] = meshTangents[meshTriangles[i + 2]];
                }
                if (processedBoneWeigths.Length > 0)
                {
                    processedBoneWeigths[i] = boneWeights[meshTriangles[i]];
                    processedBoneWeigths[i + 1] = boneWeights[meshTriangles[i + 1]];
                    processedBoneWeigths[i + 2] = boneWeights[meshTriangles[i + 2]];
                }
            }

            processedMesh.vertices = processedVertices;
            processedMesh.colors = processedColors;
            processedMesh.uv = processedUVs;
            processedMesh.uv2 = processedUV2s;
            processedMesh.uv3 = processedUV3s;
            processedMesh.uv4 = processedUV4s;
            processedMesh.triangles = processedTriangles;
            processedMesh.normals = processedNormals;
            processedMesh.tangents = processedTangents;
            processedMesh.bindposes = item.bindposes;
            processedMesh.boneWeights = processedBoneWeigths;

            string newPath = Path.Combine(dir, goName) + "_" + processedMesh.name + ".mesh";
            newPath = AssetDatabase.GenerateUniqueAssetPath(newPath);
            // Debug.Log(newPath);
            AssetDatabase.CreateAsset(processedMesh, newPath);
        }

    }
}