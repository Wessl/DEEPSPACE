using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioComponent : MonoBehaviour
{
    [SerializeField] private AudioSource _audioSource;
    [SerializeField] private Material audioVisualizeMaterial;
    [SerializeField] private float timeUntilFirstDrop;
    [SerializeField] private float timeUntilSecondDrop;
    private AudioClip _audioClip;
    
    [SerializeField] private float updateStep = 0.01f;
    [SerializeField] private int sampleDataLength = 1024;
    [SerializeField] private float loudnessAmplifier = 5;
    [SerializeField] private float dropModifier = 2;
    [SerializeField] private float dropModifier2 = 2;
 
    private float currentUpdateTime = 0f;
 
    private float clipLoudness;
    private float[] clipSampleData;
    private bool hasDropped1;
    private bool hasDropped2;
    
    void Awake () {
     
        if (!_audioSource) {
            Debug.LogError(GetType() + ".Awake: there was no audioSource set.");
        }
        clipSampleData = new float[sampleDataLength];
        _audioClip = _audioSource.clip;
        
        // Reset some material properties
        audioVisualizeMaterial.SetFloat("_DropModifier", 0);
        audioVisualizeMaterial.SetFloat("_DropModifier2", 0);
        audioVisualizeMaterial.SetFloat("_RotationSpeed", 0);
    }

    // Update is called once per frame
    void Update()
    {
        currentUpdateTime += Time.deltaTime;
        if (currentUpdateTime >= updateStep) {
            currentUpdateTime = 0f;
            _audioSource.clip.GetData(clipSampleData, _audioSource.timeSamples); //I read 1024 samples, which is about 80 ms on a 44khz stereo clip, beginning at the current sample position of the clip.
            clipLoudness = 0f;
            foreach (var sample in clipSampleData) {
                clipLoudness += Mathf.Abs(sample);
            }
            clipLoudness /= sampleDataLength; //clipLoudness is what you are looking for
        }
        audioVisualizeMaterial.SetFloat("_AudioVolume", clipLoudness*loudnessAmplifier);
        CheckDrops();
    }

    private void CheckDrops()
    {
        if (Time.time >= timeUntilFirstDrop && !hasDropped1)
        {
            hasDropped1 = true;
            audioVisualizeMaterial.SetFloat("_DropModifier", dropModifier);
            audioVisualizeMaterial.SetFloat("_RotationSpeed", 20);
            loudnessAmplifier *= 1.5f;
        }
        if (Time.time >= timeUntilSecondDrop && !hasDropped2)
        {
            hasDropped2 = true;
            audioVisualizeMaterial.SetFloat("_DropModifier2", dropModifier2);
            audioVisualizeMaterial.SetFloat("_RotationSpeed", 40);
            loudnessAmplifier *= 1.5f;
        }
    }
}
