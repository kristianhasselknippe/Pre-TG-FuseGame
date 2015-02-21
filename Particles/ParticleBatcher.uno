using Uno;
using Uno.Graphics;
using Fuse.Drawing.Batching;

namespace FuseGame
{
	class ParticleBatcher
	{
		public texture2D _particleTexture;

		Batch _batch;

		public ParticleBatcher(float x)
		{
			Initialize();
			//_batch
		}

		void Initialize()
		{
			var quadVertices = new [] {float3(0,0,0),float3(1,0,0),float3(1,1,0),float3(0,1,0)};
			var quadIndices = new ushort[] {0,1,2,2,3,0};
		}
	}
}