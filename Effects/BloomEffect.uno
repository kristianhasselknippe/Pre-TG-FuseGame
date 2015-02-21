using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Effects;

namespace FuseGame
{
	public class BloomEffect : Effect
	{
		float _softness;
		public float Softness
		{
			get { return _softness; }
			set
			{
				if (_softness != value)
				{
					_softness = value;

					if (Active)
						OnRenderingChanged();
				}
			}
		}

		public float Multiplier
		{
			get;
			set;
		}

		float2 _offset;
		public float2 Offset
		{
			get { return _offset; }
			set
			{
				if (_offset != value)
				{
					_offset = value;

					if (Active)
						OnRenderingChanged();
				}
			}
		}

		EffectHelpers _helpers = new EffectHelpers();

		private float Padding 
		{
			get 
			{
				return Uno.Math.Sqrt(Softness) * 10 * Element.AbsoluteZoom;
			}
		}

		public override bool ExtendsRenderBounds { get { return true; } }
		public override Rect RenderBounds
		{
			get
			{
				return Rect.Translate(Rect.Inflate(Element.RenderBounds, Padding), Offset);
			}
		}

		public override bool Active
		{
			get
			{
				return true;
			}
		}

		public BloomEffect() : base(EffectType.Overlay)
		{
			Softness = 2;
		}

		public override void Render(DrawContext dc)
		{
			float softness = Uno.Math.Sqrt(Softness) * 10;
			int padding = (int)Math.Ceil(Padding);

			Recti elementRect = GetLocalElementRect();
			if (elementRect.Size.X + 2 * padding > texture2D.MaxSize ||
			    elementRect.Size.Y + 2 * padding > texture2D.MaxSize)
			{
				debug_log "BloomEffect bigger than maximum texture size, dropping rendering (size: " + (elementRect.Size + padding * 2) + ", max-size: " + texture2D.MaxSize;
				return;
			}

			float4x4 compositMatrix = GetCompositMatrix(dc);
			var temp = Element.CaptureRegion(dc, elementRect, int2(padding), Matrix.Invert(compositMatrix));

			var blur = _helpers.Blur(temp.ColorBuffer, dc, Element.AbsoluteZoom, softness * 0.016f);

			float2 blitOffset = Offset - padding / Element.AbsoluteZoom;
			_helpers.BlitAdd(dc, blur.ColorBuffer, temp.ColorBuffer, (int2)((float2)temp.Size / Element.AbsoluteZoom), blitOffset, compositMatrix, Multiplier);

			FramebufferPool.Release(blur);
			FramebufferPool.Release(temp);
		}
	}
}
