using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class ShaderGUITest : ShaderGUI
{
    public enum SurfaceType
    {
        Opaque,
        Transparent
    }

    public enum BlendMode
    {
        Alpha,
        Premultiply,
        Additive,
        Multiply
    }

    public enum CullMode
    {
        CullBack,
        CullFront,
        CullOff
    }

    bool firstApply = true;

    MaterialProperty alpha;
    MaterialProperty surface;
    MaterialProperty blend;
    MaterialProperty cull;
    MaterialProperty zwrite;
    MaterialProperty srcblend;
    MaterialProperty dstblend;

    public void MaterialChanged(MaterialEditor materialEditor)
    {
        Material material = materialEditor.target as Material;

        SurfaceType surfaceType = (SurfaceType)material.GetInt("_SurfaceType");
        if (surfaceType == SurfaceType.Opaque)
        {
            material.SetOverrideTag("RenderType", "Opaque");
            material.SetInt("_ZWrite", 1);
            material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
            material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
            material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
        }
        else
        {
            BlendMode blendMode = (BlendMode)material.GetInt("_BlendMode");
            switch (blendMode)
            {
                case BlendMode.Alpha:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case BlendMode.Premultiply:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case BlendMode.Additive:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case BlendMode.Multiply:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.DstColor);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                default:
                    break;
            }
        }

    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //base.OnGUI(materialEditor, properties);

        Material material = materialEditor.target as Material;

        alpha = FindProperty("_Alpha", properties);
        surface = FindProperty("_SurfaceType", properties);
        blend = FindProperty("_BlendMode", properties);
        cull = FindProperty("_Cull", properties);
        zwrite = FindProperty("_ZWrite", properties);
        srcblend = FindProperty("_SrcBlend", properties);
        dstblend = FindProperty("_DstBlend", properties);

        if (firstApply)
        {
            MaterialChanged(materialEditor);
            firstApply = false;
        }

        EditorGUI.BeginChangeCheck();
        {
            EditorGUI.BeginChangeCheck();
            var type = EditorGUILayout.Popup("Surface Type", (int)surface.floatValue, Enum.GetNames(typeof(SurfaceType)));
            if (EditorGUI.EndChangeCheck())
            {
                surface.floatValue = (float)type;
            }

            EditorGUI.BeginChangeCheck();
            var blendMode = EditorGUILayout.Popup("Blend Mode", (int)blend.floatValue, Enum.GetNames(typeof(BlendMode)));
            if (EditorGUI.EndChangeCheck())
            {
                blend.floatValue = (float)blendMode;
            }

            EditorGUI.BeginChangeCheck();
            var cullMode = EditorGUILayout.Popup("Cull Mode", (int)cull.floatValue, Enum.GetNames(typeof(UnityEngine.Rendering.CullMode)));
            if (EditorGUI.EndChangeCheck())
            {
                cull.floatValue = (float)cullMode;
            }
        }
        if(EditorGUI.EndChangeCheck())
        {
            MaterialChanged(materialEditor);
        }
        

        materialEditor.RangeProperty(alpha, "Alpha Range");
    }
}
