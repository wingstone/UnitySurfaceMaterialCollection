using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof( Camera))]
public class test : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Camera came = GetComponent<Camera>();

        Debug.Log("==========");
        Debug.Log(came.cameraToWorldMatrix);

        Debug.Log("==========");
        Debug.Log(came.projectionMatrix);

        Debug.Log("==========");
        Debug.Log(came.projectionMatrix * came.worldToCameraMatrix);

        Debug.Log("==========");
        //Debug.Log(GL.)
        Debug.Log(GL.GetGPUProjectionMatrix(came.projectionMatrix, false) * came.worldToCameraMatrix);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
