using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RandomPointGenerate : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        GenerateDiskPoint(2, 16);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    float GetRandom01()
    {
        return Random.Range(0.0f, 1.0f);
    }

    void GenerateDiskPoint(float redius, int num)
    {
        float phi = 0;
        float r = 0;

        Vector2 u = new Vector2(1.0f, 0.0f);
        Vector2 v = new Vector2(0.0f, 1.0f);
        Vector2 pos = Vector2.zero;

        string result = "";
        for (int i = 0; i < num; i++)
        {
            phi =  GetRandom01() * Mathf.PI;
            r = Mathf.Sqrt(GetRandom01()) * redius;
            pos = u * Mathf.Cos(phi) * r + v * Mathf.Sin(phi) * r;

            result = result + "( " + pos.x + ", " + pos.y + " ),\n";
        }

        Debug.Log("Result is :\n" + result);
    }

    void GenerateDiskPointUseIternel(float redius, int num)
    {
        Vector2 pos = Vector2.zero;

        string result = "";
        for (int i = 0; i < num; i++)
        {
            pos = Random.insideUnitCircle*redius;

            result = result + "( " + pos.x + ", " + pos.y + " ),\n";
        }

        Debug.Log("Result is :\n" + result);
    }
}
