using Uno;
using Uno.Graphics;
using Fuse;
using Fuse.Controls;
using Fuse.Drawing.Batching;

namespace FuseGame
{
	public class ParticleBatcher : Panel
	{
		public texture2D _particleTexture;

		Batch _batch;

		public ParticleBatcher()
		{			
			Initialize();
		}

		void Initialize()
		{
			const int maxVertices = 65535;
			var quadVertices = new [] {float3(0,0,0),float3(1,0,0),float3(1,1,0),float3(0,1,0)};
			var quadIndices = new ushort[] {0,1,2,2,3,0};

			int particleCount = ParticleCount;//maxVertices / quadVertices.Length;
			int verticeCount = particleCount * quadVertices.Length;
			int indicesCount = particleCount * quadIndices.Length;
			_batch = new Batch(verticeCount, indicesCount, true);
			var rand = new Random(1338);

			int indexAdd = 0;
			for(var i = 0;i < particleCount;i++)
			{
				float3 pos = float3((rand.NextFloat()-0.5f)*2, (rand.NextFloat()-0.5f)*2, 0)*Radius	;

				for(var j = 0; j < quadVertices.Length; j++)
				{
					var v = quadVertices[j];

					_batch.Positions.Write(v);
					_batch.TexCoord0s.Write(float2(v.X, 1.0f - v.Y));
					_batch.Attrib1Buffer.Write(float4(pos, i));	
				}

				for(var j = 0; j < quadIndices.Length; j++)
				{
					_batch.Indices.Write((ushort)(quadIndices[j] + indexAdd));
				}

				indexAdd += quadVertices.Length;
			}
		}

		public float ParticleSize = 5;
		public int ParticleCount = 70;
		public float Radius = 50;
		public float4 Color = float4(0.9f, 0, 0.9f, 1);

		protected override void OnDraw(DrawContext dc)
		{
			InvalidateVisual();
			float4x4 compositMatrix = GetDrawMatrix(dc);

			draw _batch
			{
				float dt: Fuse.Time.FrameInterval;
				float time: Fuse.Time.FrameTime;
				float2 size: float2(ParticleSize, ParticleSize);
				float2 position: Attrib1.XY;

				float2 dir: float2(Math.Cos(time + Attrib1.W), Math.Sin(time + Attrib1.W));
				position: prev + dir * Math.Sin(time + Attrib1.W)*Radius;

				float4 p: Vector.Transform(float4(position + VertexPosition.XY*size, 0, 1), compositMatrix);
				ClipPosition: Fuse.Spaces.PixelsToClipSpace(p.XY, dc.VirtualResolution);

				float colorFactor: Math.Sin(time + Attrib1.W)*0.5f + 0.5f;
				float4 ParticlePixel: float4(Math.Sin(time*2 + 1 + Attrib1.W)*0.1f + Color.X, Color.Y, Math.Sin(time*2 + Attrib1.W)*0.1f + Color.Z, Color.W);
				PixelColor: float4(ParticlePixel.XYZ, 1);
				CullFace: PolygonFace.None;
				DepthTestEnabled: false;
			};
		}
	}
}