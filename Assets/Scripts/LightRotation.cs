using UnityEngine;

public class LightRotation : MonoBehaviour
{
    [Range(0, 100)]
    public float speed;
    public void Update()
    {
        transform.Rotate(Vector3.up, speed / 100);
    }
}
