using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.UX;
using Fuse;
using Fuse.Designer;
using Fuse.Drawing.Primitives;

namespace FuseGame
{
	partial class EffectHelpers
	{
		public framebuffer Blur(texture2D original, DrawContext dc, float zoom, float amount)
		{

			var b1 = BlurHorizontal(dc, original, Math.Max(1, 2 * zoom * amount), amount);
			var b2 = BlurVertical(dc, b1.ColorBuffer, Math.Max(1, 2 * zoom * amount), amount); FramebufferPool.Release(b1);
			var b3 = BlurHorizontal(dc, b2.ColorBuffer, 1, amount); FramebufferPool.Release(b2);
			var b4 = BlurVertical(dc, b3.ColorBuffer, 1, amount); FramebufferPool.Release(b3);
			var b5 = BlurHorizontal(dc, b4.ColorBuffer, Math.Max(1, 3 * amount), amount); FramebufferPool.Release(b4);
			var b6 = BlurVertical(dc, b5.ColorBuffer, Math.Max(1, 3 * amount), amount); FramebufferPool.Release(b5);
			var b7 = BlurHorizontal(dc, b6.ColorBuffer, 1, amount); FramebufferPool.Release(b6);
			var blur = BlurVertical(dc, b7.ColorBuffer, 1, amount); FramebufferPool.Release(b7);

			return blur;
		}

		framebuffer BlurHorizontal(DrawContext dc, texture2D tex, float h, float amount)
		{
			var nw = (int)(tex.Size.X  / h);
			var nh = tex.Size.Y;

			var fb = FramebufferPool.Lock(nw, nh, Format.RGBA8888, false);

			dc.PushRenderTarget(fb);
			dc.Clear(float4(0), 1);
			DirectionalBlur(tex, float2(1,0), amount);
			dc.PopRenderTarget();

			return fb;
		}

		framebuffer BlurVertical(DrawContext dc, texture2D tex, float h, float amount)
		{
			var nw = tex.Size.X;
			var nh = (int)(tex.Size.Y / h);

			var fb = FramebufferPool.Lock(nw, nh, Format.RGBA8888, false);

			dc.PushRenderTarget(fb);
			dc.Clear(float4(0), 1);
			DirectionalBlur(tex, float2(0,1), amount);
			dc.PopRenderTarget();

			return fb;
		}

		void DirectionalBlur(texture2D tex, float2 dir, float amount)
		{
			draw Quad
			{
				DepthTestEnabled: false;

				float2 tc: VertexPosition.XY * 0.5f + 0.5f;
				float2 delta: float2(dir.X / tex.Size.X, dir.Y / tex.Size.Y) * Math.Sqrt(amount);

				PixelColor:
					sample(tex, tc					  , Uno.Graphics.SamplerState.LinearClamp) * 0.204164f +
					sample(tex, tc + delta * 1.407333f, Uno.Graphics.SamplerState.LinearClamp) * 0.304005f +
					sample(tex, tc - delta * 1.407333f, Uno.Graphics.SamplerState.LinearClamp) * 0.304005f +
					sample(tex, tc + delta * 3.294215f, Uno.Graphics.SamplerState.LinearClamp) * 0.093913f +
					sample(tex, tc - delta * 3.294215f, Uno.Graphics.SamplerState.LinearClamp) * 0.093913f;
			};
		}
	}
}