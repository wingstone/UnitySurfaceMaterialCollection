using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

//https://zhuanlan.zhihu.com/p/27271879
public class ResourceProcessor : AssetPostprocessor
{
    //导入设置
    void OnPreprocessModel()
    {
        ModelImporter modelImporter = assetImporter as ModelImporter;
        modelImporter.materialImportMode = ModelImporterMaterialImportMode.None;
    }

    //分配默认材质
    protected virtual Material OnAssignMaterialModel(Material previousMaterial, Renderer renderer)
    {
        var materialPath = "Assets/Res/default.mat";

        if (AssetDatabase.LoadAssetAtPath(materialPath, typeof(Material)))
        {
            return AssetDatabase.LoadAssetAtPath(materialPath, typeof(Material)) as Material;
        }

        Debug.Log(previousMaterial.name);

        return previousMaterial;
    }

    //删除导入材质
    public void OnPostprocessModel(GameObject model)
    {
        Renderer[] renders = model.GetComponentsInChildren<Renderer>();
        if (null != renders)
        {
            foreach (Renderer render in renders)
            {
                render.sharedMaterials = new Material[render.sharedMaterials.Length];
            }
        }
    }

    // 添加重新导入fbx的功能。
    [MenuItem("Assets/Reimport all FBX")]
    public static void ReimportAllFBX()
    {
        var files = AssetDatabase.GetAllAssetPaths();
        foreach (var vv in files)
        {
            var vvLower = vv.ToLower();
            if (vvLower.EndsWith("fbx"))
            {
                AssetDatabase.ImportAsset(vv, ImportAssetOptions.ImportRecursive | ImportAssetOptions.ForceUpdate);
            }
        }
    }
}

#if UNITY_EDITOR

[CustomEditor(typeof(ResourceProcessor))]
public class ResourceProcessorEditor : Editor {
    public override void OnInspectorGUI() {
        base.OnInspectorGUI();
        
    }
}

#endif