using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using UnityEngine.UI;

public class ParticleSimDriver3D : UdonSharpBehaviour {
	public Slider simSpeedSlider, attractionSlider, radiusSlider;
	public Material simMat;
	public bool is3D = true;

	private float resetTimer = -1;
	private float[] tempArr = new float[16];

	void Start() {
		_Reset();
		simMat.SetFloat("_SimSpeed", 0.65f);
	}

	void Update() {
		if(resetTimer > 0) {
				resetTimer -= Time.deltaTime;
				if(resetTimer < 0) {
						simMat.SetInt("_Reset", 0);
				}
		}
	}

	public void _Reset() {
		if(resetTimer > 0) return;
		resetTimer = 2;
		simMat.SetInt("_Reset", 1);
		for(int i = 0; i < 16; i++) {
			tempArr[i] = (((Random.value - 0.5f) * 2.0f) * attractionSlider.value);
			if(tempArr[i] < 0) tempArr[i] -= 0.03f;
			else tempArr[i] += 0.03f;
		}
		simMat.SetFloatArray("_Rules", tempArr);
		for(int i = 0; i < 16; i++) {
			tempArr[i] = 10 + Random.value * 200;
			if(is3D) {
				tempArr[i] *= radiusSlider.value;
				tempArr[i] = tempArr[i] * tempArr[i];
			}
		}
		simMat.SetFloatArray("_InteractionRadi", tempArr);
		simMat.SetInt("_Seed", (int)(Random.value * 100000000));
	}

	public void _OnSliderValueChanged() {
		simMat.SetFloat("_SimSpeed", simSpeedSlider.value);
	}
}
