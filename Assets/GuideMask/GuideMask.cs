using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteAlways]
public class GuideMask : MonoBehaviour
{
    public RectTransform targetRect;
    [Range(0, 0.1f)]
    public float radius;

    private Image image;

    // Update is called once per frame
    void Update()
    {
        if (image == null)
        {
            image = GetComponent<Image>();
        }

        Material mat = image.material;
        mat.SetFloat("_Radius", radius);

        Vector2 center = Vector2.zero;
        center = targetRect.anchoredPosition;
        Vector2 widthHight = Vector2.zero;
        widthHight = targetRect.sizeDelta;

        Vector2 MaskWH = GetComponent<RectTransform>().sizeDelta;
        center.x /= MaskWH.y;
        center.y /= MaskWH.y;
        widthHight.x /= MaskWH.y;
        widthHight.y /= MaskWH.y;

        mat.SetVector("_RectParmeters", new Vector4(center.x, center.y, widthHight.x, widthHight.y));
    }
}
