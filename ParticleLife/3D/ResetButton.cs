using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ResetButton : UdonSharpBehaviour {
    public ParticleSimDriver2D simDriver;
    public Material onMat,offMat;
    
    private float timeout = -1;
    private MeshRenderer mr;
    
    void Start() {
        mr = GetComponent<MeshRenderer>();
        mr.material = offMat;
    }
    
    void Update() {
		if(timeout > 0) {
			timeout -= Time.deltaTime;
			if(timeout < 0) {
				mr.material = offMat;
			}
		}
	}
    
    void Interact() {
		if(timeout >= 0) return;
		timeout = 3;
		mr.material = onMat;
		if(simDriver != null) simDriver._Reset();
	}
}
