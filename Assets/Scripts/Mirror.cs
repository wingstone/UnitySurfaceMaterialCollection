using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class Mirror : MonoBehaviour
{
    public Camera targetCamera;

    private Camera m_refCamera;
    private RenderTexture m_refRendreTexture;
    private Material m_material;

    private float m_planeOffset = 0.07f;
    

    // Start is called before the first frame update
    void RenderReflectTexture()
    {
        if (!m_material)
        {
            MeshRenderer meshRender = GetComponent<MeshRenderer>();
            m_material = meshRender.sharedMaterial;
        }


        if (!targetCamera)
            return;

        if (!m_refRendreTexture)
        {
            int width = 512;
            int hight = 512;
            int antiAliasing = 1;

            if (targetCamera.targetTexture != null)
            {
                width = targetCamera.targetTexture.width;
                hight = targetCamera.targetTexture.height;
                antiAliasing = targetCamera.targetTexture.antiAliasing;
            }
            else
            {
                antiAliasing = QualitySettings.antiAliasing;
            }
            antiAliasing = antiAliasing < 1 ? 1 : antiAliasing;

            m_refRendreTexture = new RenderTexture(width, hight, 16, RenderTextureFormat.ARGBHalf);


            m_refRendreTexture.antiAliasing = antiAliasing;
            m_refRendreTexture.name = "__MirrorReflection" + GetInstanceID();
            m_refRendreTexture.isPowerOfTwo = true;
            m_refRendreTexture.hideFlags = HideFlags.DontSave;
            m_refRendreTexture.filterMode = FilterMode.Bilinear;
        }

        if(!m_refCamera)
        {
            GameObject GO = new GameObject("reflectCamera", typeof(Camera));
            m_refCamera = GO.GetComponent<Camera>();
            m_refCamera.CopyFrom(targetCamera);
            GO.hideFlags = HideFlags.HideAndDontSave;
        }


        //set refcamera.pos
        Vector3 norm = transform.up;
        Vector3 pos = transform.position;
        Vector3 tarCamPos = targetCamera.transform.position;
        Vector4 plane = new Vector4(norm.x, norm.y, norm.z, -Vector3.Dot(norm, pos) - m_planeOffset);

        Matrix4x4 reflectMat = GetReflectMatrixFromPlane(plane);

        float distance = Vector3.Dot(tarCamPos - pos, norm);
        if (distance < 0)
            return;
        m_refCamera.transform.position = tarCamPos - norm * 2.0f * distance;

        //set refcamera.veiwmatrix
        m_refCamera.worldToCameraMatrix = targetCamera.worldToCameraMatrix * reflectMat;

        //set refcamera.projectmatrix
        Matrix4x4 refCameraReflectMat = m_refCamera.worldToCameraMatrix;
        Vector3 cameraSpaceNormal = refCameraReflectMat.MultiplyVector(norm);
        Vector3 offsetPos = refCameraReflectMat.MultiplyPoint(pos + norm * m_planeOffset);
        Vector4 clipPlane = new Vector4(cameraSpaceNormal.x, cameraSpaceNormal.y, cameraSpaceNormal.z, -Vector3.Dot(cameraSpaceNormal, offsetPos));
        Matrix4x4 clipProjectMat = targetCamera.projectionMatrix;
        GetClipProjectMatrix(ref clipProjectMat, clipPlane);
        m_refCamera.projectionMatrix = clipProjectMat;

        //set 
        m_refCamera.targetTexture = m_refRendreTexture;
        m_refCamera.depthTextureMode = DepthTextureMode.Depth;
        int mirrorLayer = LayerMask.NameToLayer("Mirror");
        m_refCamera.cullingMask = ~(1 << mirrorLayer | 1 << 4); // never render water and mirror layer
        m_refCamera.Render();

        
    }

    Matrix4x4 GetReflectMatrixFromPlane(Vector4 plane)
    {
        Matrix4x4 reflectionMat = new Matrix4x4();
        reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2F * plane[1] * plane[0]);
        reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2F * plane[2] * plane[1]);
        reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2F * plane[3] * plane[2]);

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;

        return reflectionMat;
    }

    void GetClipProjectMatrix(ref Matrix4x4 projectMat, Vector4 clipPlane)
    {
        Vector4 q = projectMat.inverse * new Vector4(
            Sgn(clipPlane.x),
            Sgn(clipPlane.y),
            1.0f,
            1.0f
            );
        Vector4 c = clipPlane * (2.0f / Vector4.Dot(clipPlane, q));
        //third row = slip plane - fourth row
        projectMat[2] = c.x - projectMat[3];
        projectMat[6] = c.y - projectMat[7];
        projectMat[10] = c.z - projectMat[11];
        projectMat[14] = c.w - projectMat[15];
    }

    float Sgn(float a)
    {
        if (a > 0.0f) return 1.0f;
        if (a < 0.0f) return -1.0f;
        return 0.0f;
    }

    private void OnWillRenderObject()
    {
        RenderReflectTexture();
        
        m_material.SetTexture("_ReflectionTex", m_refRendreTexture);
    }
}
