using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class test : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Camera came = GetComponent<Camera>();

        //Debug.Log("==========");
        //Debug.Log(came.worldToCameraMatrix);

        //Debug.Log("==========");
        //Debug.Log(came.projectionMatrix);

        Debug.Log("==========");
        Debug.Log(came.projectionMatrix * came.worldToCameraMatrix);

        Debug.Log("==========");
        Debug.Log(GL.GetGPUProjectionMatrix(came.projectionMatrix, true) * came.worldToCameraMatrix);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
