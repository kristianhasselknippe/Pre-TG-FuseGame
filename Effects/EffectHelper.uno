using Uno;
using Fuse;
using Fuse.Internal.Drawing;

namespace FuseGame
{
	partial class EffectHelpers
	{
		public framebuffer Pad(DrawContext dc, texture2D source, float2 padding, float4 clearColor)
		{
			var size = source.Size + padding * 2;
			var fb = FramebufferPool.Lock((int)size.X, (int)size.Y, source.Format, false);

			dc.PushRenderTarget(fb);
			dc.Clear(clearColor, 1);

			draw
			{
				float2[] vertices: new float2[]
				{
					float2(0, 0), float2(1, 0), float2(1, 1),
					float2(0, 0), float2(1, 1), float2(0, 1)
				};

				CullFace: Uno.Graphics.PolygonFace.None;

				float2 v: vertex_attrib(vertices);

				float2 p: (float2)padding + v * (float2)source.Size;

				ClipPosition: float4( (p / fb.Size) * float2(2, -2) + float2(-1, 1), 0, 1);

				PixelColor: sample(source, float2(v.X, 1.0f-v.Y),  Uno.Graphics.SamplerState.NearestClamp);

				apply AlphaCompositing;
			};

			dc.PopRenderTarget();


			return fb;
		}

		public void Blit(DrawContext dc, texture2D t, float2 size, float2 position, float4x4 compositMatrix, float4 color, bool colorize)
		{
			draw
			{
				float2[] vertices: new float2[]
				{
					float2(0, 0), float2(1, 0), float2(1, 1),
					float2(0, 0), float2(1, 1), float2(0, 1)
				};

				CullFace: Uno.Graphics.PolygonFace.None;

				float2 Coord: vertex_attrib(vertices);
				float4 p: Vector.Transform(float4(position + Coord * size, 0, 1), compositMatrix);

				ClipPosition:
					Fuse.Spaces.PixelsToClipSpace(p.XY / p.W, dc.VirtualResolution);

				PixelColor: sample(t, float2(Coord.X, 1.0f - Coord.Y));

				PixelColor: colorize ? float4(color.XYZ, color.W*prev.W) : prev * color;

				apply AlphaCompositing;
			};

		}

		public void BlitAdd(DrawContext dc, texture2D t, texture2D f, float2 size, float2 position, float4x4 compositMatrix, float multiplier)
		{
			draw
			{
				float2[] vertices: new float2[]
				{
					float2(0, 0), float2(1, 0), float2(1, 1),
					float2(0, 0), float2(1, 1), float2(0, 1)
				};

				CullFace: Uno.Graphics.PolygonFace.None;

				float2 Coord: vertex_attrib(vertices);
				float4 p: Vector.Transform(float4(position + Coord * size, 0, 1), compositMatrix);

				ClipPosition:
					Fuse.Spaces.PixelsToClipSpace(p.XY / p.W, dc.VirtualResolution);

				PixelColor: sample(t, float2(Coord.X, 1.0f - Coord.Y))*multiplier + sample(f, float2(Coord.X, 1.0f - Coord.Y));

				//PixelColor: colorize ? float4(color.XYZ, color.W*prev.W) : prev * color;

				//apply AlphaCompositing;
			};

		}
	}
}