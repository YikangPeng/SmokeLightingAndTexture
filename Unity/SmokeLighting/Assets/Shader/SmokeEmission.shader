Shader "Unlit/SmokeEmission"
{
    Properties
    {
        _LightTBLR("LightTBLR", 2D) = "white" {}
        _CloudAlpha("CloudAlpha", 2D) = "white" {}
        _LightScale("LightScale", Range(0,2)) = 1.0
        _ColorRamp("ColorRamp", 2D) = "white" {}
        _EmissionScale("EmissionScale", Range(0,4)) = 1.0
        _EmissionColor("_EmissionColor", 2D) = "white" {}
        _EmissionColorScale("EmissionColorScale", Range(0,2)) = 1.0
        _EmissionColorBias("_EmissionColorBias", Range(-1,1)) = 1.0
        
    }
        SubShader
    {
        //Tags {  "RenderType"="Opaque" }

        Tags {  "Queue" = "Transparent"
                "IgnoreProjector" = "True"
                "RenderType" = "Transparent"  }
        LOD 100

        ZWrite Off //�ر����д��
        Blend SrcAlpha OneMinusSrcAlpha //��ɫ��Ϸ���

        Pass
        {
            Tags { "LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        // make fog work
        #pragma multi_compile_fog
        #pragma multi_compile_fwdbase


        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            UNITY_FOG_COORDS(1)
            float4 vertex : SV_POSITION;
            float3 lightDir:TEXCOORD1;
        };

        sampler2D _LightTBLR;
        float4 _LightTBLR_ST;

        sampler2D _CloudAlpha;
        float4 _CloudAlpha_ST;

        sampler2D _ColorRamp;
        sampler2D _EmissionColor;
        


        float _LightScale;
        float _EmissionColorScale;        
        float _EmissionScale;
        float _EmissionColorBias;

        v2f vert(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            UNITY_TRANSFER_FOG(o,o.vertex);


            TANGENT_SPACE_ROTATION;
            //ƽ�й������ռ�ת������ռ�
            o.lightDir = mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz;
            //ƽ�й������ռ�ת�����߿ռ�ռ�
            o.lightDir = mul(rotation, o.lightDir);

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            // sample the texture
            //R:TopLight G:BottomLight B:LeftLight A:RightLight
            float4 lightMap = tex2D(_LightTBLR, i.uv);
            //R:Alpha G:EmissionMask B:FrontLight A:BackLight
            float4 cloudAlpha = tex2D(_CloudAlpha, i.uv);
            // apply fog
            UNITY_APPLY_FOG(i.fogCoord, col);

            //���������ǰ�������ֱ�Ӷ�ͼ
            //frontMap = cloudAlpha.z;
            //backMap = cloudAlpha.w;
            //ͨ���������ҷ��򣬽��Ƽ���ǰ��Ȩ��
            float frontMap = 0.25f * (lightMap.x + lightMap.y + lightMap.z + lightMap.w);
            frontMap = pow(frontMap, 0.625);

            float backMap = 1.0f - frontMap;
            backMap = saturate(0.25 * (1.0 - backMap) + 0.5 * (backMap * backMap * backMap * backMap));


            //�жϲ�ȡLeft/Right����ƹ�
            float hMap = (i.lightDir.x > 0.0f) ? (lightMap.w) : (lightMap.z);
            //�жϲ�ȡTop/Bottom����ƹ�
            float vMap = (i.lightDir.y > 0.0f) ? (lightMap.x) : (lightMap.y);
            //�жϲ�ȡFront/Back����ƹ�
            float dMap = (i.lightDir.z > 0.0f) ? (frontMap) : (backMap);

            float weight = hMap * i.lightDir.x * i.lightDir.x + vMap * i.lightDir.y * i.lightDir.y + dMap * i.lightDir.z * i.lightDir.z;

            float2 rampuv = float2(saturate(weight * _LightScale), 0.5);

            //��Rampͼ�ж�ȡ��ɫ
            float4 BaseColor = tex2D(_ColorRamp, rampuv);

            float emissionMask = cloudAlpha.y;

            float emissionColorUV = float2(saturate(emissionMask), 0.5);
            float3 emissionColor = tex2D(_EmissionColor, emissionColorUV).xyz;
            emissionColor = emissionColor * emissionMask * _EmissionScale;

            float3 color = lerp(BaseColor.xyz ,emissionColor , emissionMask * _EmissionColorScale + _EmissionColorBias);

            //return fixed4(_WorldSpaceLightPos0.xyz , 1);
            return fixed4(color, cloudAlpha.x);
            //return fixed4(lightMap.xyz,1);


        }
        ENDCG
    }


    }
}
