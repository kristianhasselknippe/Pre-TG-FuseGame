using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Effects;
using Fuse.Controls;
using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.UX;
using Fuse;
using Fuse.Designer;
using Fuse.Drawing.Primitives;
using FuseGame.Audio;

namespace FuseGame
{
	public class BloomEffect : Panel
	{

		FftProvider _fftProvider;
		public FftProvider FftProvider
		{
			get { return _fftProvider; }
			set
			{
				if (_fftProvider != null)
				{
					_fftProvider.FftAvailable -= OnFftAvailable;
				}

				_fftProvider = value;

				if (_fftProvider != null)
				{
					_fftProvider.FftAvailable += OnFftAvailable;
				}
			}
		}

		void OnFftAvailable(object sender, float[] fftData)
		{
			Multiplier = fftData[1] / 128f;
			Offset = float2(fftData[2] / 128f, fftData[3] / 128f);
		}

		float _softness;
		public float Softness
		{
			get { return _softness; }
			set
			{
				if (_softness != value)
				{
					_softness = value;
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
				}
			}
		}

		EffectHelpers _helpers = new EffectHelpers();

		public BloomEffect()
		{
			Softness = 2;
		}

		protected override void OnDraw(DrawContext dc)
		{
			float softness = Uno.Math.Sqrt(Softness) * 10;
			var clientSize = Uno.Application.Current.Window.ClientSize;
			
			var temp = FramebufferPool.Lock(clientSize, Format.RGBA8888, true);
			dc.PushRenderTarget(temp);
			dc.Clear(float4(0), 1);
			base.OnDraw(dc);
			dc.PopRenderTarget();

			float4x4 compositMatrix = GetDrawMatrix(dc);
			var blur = _helpers.Blur(temp.ColorBuffer, dc, AbsoluteZoom, softness * 0.016f);
			_helpers.BlitAdd(dc, blur.ColorBuffer, temp.ColorBuffer, (int2)((float2)temp.Size / AbsoluteZoom), float2(0,0), compositMatrix, Multiplier);

			FramebufferPool.Release(blur);
			FramebufferPool.Release(temp);
		}
	}
}
