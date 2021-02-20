using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//https://blogs.unity3d.com/2015/02/06/extending-unity-5-rendering-pipeline-command-buffers/?_ga=2.191503788.769314826.1613725858-1790831840.1603622218
//https://github.com/selfshadow/ltc_code
//https://www.shadertoy.com/view/ldfGWs
[ExecuteAlways]
public class LightControl : MonoBehaviour
{
    public enum LightType
    {
        Sphere,
        Tube
    };

    private void OnEnable()
    {
        Update();
    }

    // Update is called once per frame
    void Update()
    {
        switch (lightType)
        {
            case LightType.Sphere:
                Shader.SetGlobalColor("_SphereLightColor", sphereLightColor);
                Shader.SetGlobalFloat("_SphereLightRedius", sphereLightRedius);
                Shader.SetGlobalVector("_SphereLightPos", transform.position + sphereLightPos);
                break;
            case LightType.Tube:
                Shader.SetGlobalColor("_TubeLightColor", tubeLightColor);
                Shader.SetGlobalFloat("_TubeLightRedius", tubeLightRedius);
                Shader.SetGlobalVector("_TubeLightPos0", transform.position - tubeLightPos0);
                Shader.SetGlobalVector("_TubeLightPos1", transform.position + tubeLightPos1);
                break;
            default:
                break;
        }
    }

    private void OnDrawGizmos()
    {
        switch (lightType)
        {
            case LightType.Sphere:
                Gizmos.DrawSphere(transform.position + sphereLightPos, sphereLightRedius);
                break;
            case LightType.Tube:
                Gizmos.DrawSphere(transform.position - tubeLightPos0, tubeLightRedius);
                Gizmos.DrawSphere(transform.position + tubeLightPos1, tubeLightRedius);
                Gizmos.DrawLine(transform.position - tubeLightPos0, transform.position + tubeLightPos1);
                break;
            default:
                break;
        }
    }
    public LightType lightType;
    public Color sphereLightColor;
    public float sphereLightRedius;
    public Vector3 sphereLightPos;
    public Color tubeLightColor;
    public float tubeLightRedius;
    public Vector3 tubeLightPos0;
    public Vector3 tubeLightPos1;
}
