Shader "Unlit/SwirlingBG"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AudioVolume ("Audio Volume", float) = 1.0
        _DropModifier ("Drop Modifier", float) = 1.0
        _DropModifier2 ("Drop Modifier 2", float) = 1.0
        _RotationSpeed ("Rotation Speed", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            

            
            float _AudioVolume;
            float _DropModifier;
            float _DropModifier2;
            float _RotationSpeed;
            static float PI = 3.1415926;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float s = sin ( _RotationSpeed * _Time );
                float c = cos ( _RotationSpeed * _Time );
 
                float2x2 rotationMatrix = float2x2( c, -s, s, c);
 
                o.uv = mul ( o.uv - 0.5, rotationMatrix ) + 0.5; 
                return o;
            }

            float3 cosPalette(float t, float3 brightness, float3 contrast, float3 osc, float3 phase)
            {
                return brightness + contrast * cos( 6.28318 * (osc*t + phase) );
            }
            // courtesy of Char Stiles
            float getBPMVis(float bpm)
            {
                // handle time offset specific to the song
                float time = _Time.y + 0.4;
                // this function can be found graphed out here :https://www.desmos.com/calculator/rx86e6ymw7
                float bps = 60./bpm; 
                float bpmVis = tan((time*PI)/bps);
                // multiply it by PI so that tan has a regular spike every 1 instead of PI
                // divide by the beat per second so there are that many spikes per second
                bpmVis = clamp(bpmVis, 0., 10.);
                // tan goes to infinity so lets clamp it at 10
                bpmVis = abs(bpmVis)/30.;
                // tan goes up and down but we only want it to go up
                // (so it looks like a spike) so we take the absolute value
                // dividing by 20 makes the tan function more spiking than smoothly going
                // up and down, check out the desmos link to see
                bpmVis = 1.+(bpmVis*0.55);
                // we want to multiply by this number, but its too big
                // by itself (it would be too stroby) so we want the number to multiply
                // by to be between 1.0 and 1.05 so its a subtle effect
                return bpmVis;
            }

            float smoothMod(float x, float y, float e)
            {
                float top = cos(PI * (x/y)) * sin(PI * (x/y));
                float bot = pow(sin(PI * (x/y)),2.);
                float at = atan(top/bot);
                return y * (1./2.) - (1./PI) * at;
            }

            // courtesy of Char Stiles
            // repeat around the origin by a fixed angle
            // for easier use, num of repetitions is used to specify the angle
            float2 modPolar(float2 p, float repetitions)
            {
                float angle = 2.*PI/repetitions;
                float a = atan2(p.x, p.y) + angle/2.;
                float r = length(p);
                // float c = floor(a/angle);
                a = smoothMod(a, angle, 0.1) - angle/2.;
                float2 p2 = float2(cos(a), sin(a))*r;
                //p = lerp(p, p2, pow(angle - abs(angle - (angle / 2.) ) / angle, 2.));
                return p2;
            }
                

            fixed4 frag( v2f i ) : SV_Target
            {               
                float time = _Time.y;
                // input the bpm of the song here
                float beat = getBPMVis(87.);
                
                float2 uv = -1. + 2. * i.uv;
                
                // uv.x *= _ScreenParams.x/_ScreenParams.y;
               
                uv = modPolar(uv, 20.);
                uv.x -= time;
                

                // this should be volume of the sound playing
                // float volume = texture(iChannel0,float2(1.,1.)).x * beat;
                float volume = _AudioVolume;

                float radius = length(uv * 10.);
                float rings = sin(0.5*beat + beat - radius) + volume + beat * _DropModifier2;
                float angle = sin(atan2(uv.y,uv.x) + time);
                float swirly = sin(beat + (_DropModifier2) - cos(angle) + time);
                
                float3 brightness = lerp(0.1,0.6,(sin(_Time.z + length(uv*10))+0.5)/2);
                float3 contrast = 0.6 + sin(time)/4 * _DropModifier2;
                float3 osc = float3(0.5 * beat, 1.0, 0.0) + angle * _DropModifier / 3;
                float3 phase = float3(0.4, 0.9*beat, 0.2);
                
                float3 palette = cosPalette(angle + swirly + rings + beat*20, brightness, contrast, osc, phase);

                float4 color = float4(palette, 1);
               

                // Output to screen
                return color;
            }
            
            ENDCG
        }
    }
}
