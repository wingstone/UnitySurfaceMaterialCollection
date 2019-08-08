using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode]
public class Mirror : MonoBehaviour
{
    public Camera targetCamera;
    public Material blurMat;
    public int textureSize = 1024;
    public LayerMask refLayer = -1;

    private Camera m_refCamera;
    private RenderTexture m_refRendreTexture;
    private RenderTexture m_refBlurRendreTexture;
    //private RenderTexture m_refBlurRendreTexture2;
    private Material m_material;
    private bool m_isRendering = false;

    private float m_planeOffset = 0.07f;
    
    private void OnWillRenderObject()
    {
        RenderReflectTexture();
        
        m_material.SetTexture("_ReflectionTex", m_refRendreTexture);
    }

    // Start is called before the first frame update
    void RenderReflectTexture()
    {
        if (!enabled || !blurMat || !GetComponent<MeshRenderer>().enabled || !GetComponent<MeshRenderer>().sharedMaterial ||  !targetCamera)
            return;

        if (!m_material)
        {
            m_material = GetComponent<MeshRenderer>().sharedMaterial;
        }


        if (!m_refRendreTexture)
        {
            m_refRendreTexture = CreateTexture("mirrorTex");
        }

        if (!m_refBlurRendreTexture)
        {
            m_refBlurRendreTexture = CreateTexture("mirrorBlurTex");
        }

        //if (!m_refBlurRendreTexture2)
        //{
        //    CreateTexture(m_refBlurRendreTexture2);
        //}

        if (!m_refCamera)
        {
            GameObject GO = new GameObject("reflectCamera", typeof(Camera), typeof(Skybox));
            m_refCamera = GO.GetComponent<Camera>();
            m_refCamera.CopyFrom(targetCamera);
            m_refCamera.enabled = false;
            GO.hideFlags = HideFlags.HideAndDontSave;

            UpdateCameraModes(targetCamera, m_refCamera);
        }

        if (m_isRendering)
        {
            return;
        }
        m_isRendering = true;

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
        m_refCamera.cullingMask = ~(1 << mirrorLayer | 1 << 4) & refLayer.value; // never render water and mirror layer
        GL.invertCulling = true;

        m_refCamera.Render();

        //blur
        m_refBlurRendreTexture.DiscardContents();
        Graphics.SetRenderTarget(m_refBlurRendreTexture);
        Graphics.Blit(m_refRendreTexture, m_refBlurRendreTexture, blurMat, 0);
        m_refRendreTexture.DiscardContents();
        Graphics.SetRenderTarget(m_refRendreTexture);
        Graphics.Blit(m_refBlurRendreTexture, m_refRendreTexture, blurMat, 1);
        //Graphics.SetRenderTarget(m_refBlurRendreTexture1);
        //Graphics.Blit(m_refBlurRendreTexture2, m_refBlurRendreTexture1, blurMat, 1);
        Graphics.SetRenderTarget(null);

        GL.invertCulling = false;

        m_isRendering = false;
    }

    private RenderTexture CreateTexture(string name)
    {
        int antiAliasing = 1;

        if (targetCamera.targetTexture != null)
        {
            antiAliasing = targetCamera.targetTexture.antiAliasing;
        }
        else
        {
            antiAliasing = QualitySettings.antiAliasing;
        }
        antiAliasing = antiAliasing < 1 ? 1 : antiAliasing;

        RenderTexture texture = new RenderTexture(textureSize, textureSize, 16, RenderTextureFormat.ARGBHalf);

        texture.antiAliasing = antiAliasing;
        texture.name = name + GetInstanceID();
        texture.isPowerOfTwo = true;
        texture.hideFlags = HideFlags.DontSave;
        texture.filterMode = FilterMode.Bilinear;
        return texture;
    }

    private void UpdateCameraModes(Camera src, Camera dest)
    {
        if (dest == null)
            return;
        // set camera to clear the same way as current camera
        dest.clearFlags = src.clearFlags;
        dest.backgroundColor = src.backgroundColor;
        if (src.clearFlags == CameraClearFlags.Skybox)
        {
            Skybox sky = src.GetComponent(typeof(Skybox)) as Skybox;
            Skybox mysky = dest.GetComponent(typeof(Skybox)) as Skybox;
            if (!sky || !sky.material)
            {
                mysky.enabled = false;
            }
            else
            {
                mysky.enabled = true;
                mysky.material = sky.material;
            }
        }
        // update other values to match current camera.
        // even if we are supplying custom camera&projection matrices,
        // some of values are used elsewhere (e.g. skybox uses far plane)
        dest.farClipPlane = src.farClipPlane;
        dest.nearClipPlane = src.nearClipPlane;
        dest.orthographic = src.orthographic;
        dest.fieldOfView = src.fieldOfView;
        dest.aspect = src.aspect;
        dest.orthographicSize = src.orthographicSize;
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

    private void OnDisable()
    {
        if (m_refCamera)
        {
            DestroyImmediate(m_refCamera);
            m_refCamera = null;
        }
        if (m_refRendreTexture)
        {
            DestroyImmediate(m_refRendreTexture);
            m_refRendreTexture = null;
        }
        if (m_refBlurRendreTexture)
        {
            DestroyImmediate(m_refBlurRendreTexture);
            m_refBlurRendreTexture = null;
        }
        //if (m_refBlurRendreTexture2)
        //{
        //    DestroyImmediate(m_refBlurRendreTexture2);
        //    m_refBlurRendreTexture2 = null;
        //}
    }
}
