using Uno;
using Fuse;
using Fuse.Effects;
using Uno.Graphics;
using FuseGame.Audio;

namespace FuseGame
{
	class PlayerEffect : Effect
	{
		FftProvider _fftProvider;
		int numFoos = 0;

		public PlayerEffect() : base(EffectType.Overlay)
		{
			_fftProvider = new FftProvider(MainView._musicPlayer, 0.0f);
			_fftProvider.FftAvailable += Sound;
		}

		void Sound(object sender, float []array)
		{
			numFoos = (int)((array[100] / 200) * 5);
			OnRenderingChanged();
		}

		public float Duration { get; set; }

		public override void Render(DrawContext dc)
		{
			float4x4 compositMatrix = GetCompositMatrix(dc);
			
			Recti elementRect = GetLocalElementRect();
			if (elementRect.Size.X > texture2D.MaxSize ||
			    elementRect.Size.Y > texture2D.MaxSize)
			{
				debug_log "Player-effect bigger than maximum texture size, dropping rendering (size: " + elementRect.Size + ", max-size: " + texture2D.MaxSize;
				return;
			}

			var original = Element.CaptureRegion(dc, elementRect, int2(0), Matrix.Invert(compositMatrix));

			float step = 0.2f;
			for(var i = 0;i < numFoos;++i)
			{
				draw Fuse.Drawing.Planar.Image
				{
					DrawContext: dc;
					GraphTransform: compositMatrix;
					Invert: true;
					Size: (int2)((float2)elementRect.Size * (1 - step*i));
					Position: elementRect.Position + ((float2)elementRect.Size - Size)*0.5f;
					Texture: original.ColorBuffer;
					TextureColor: float4(prev TextureColor.XYZ / prev TextureColor.W, prev TextureColor.W);
					PixelColor: TextureColor * Element.Opacity;
				};
			}
		}

		public override Rect RenderBounds
		{
			get
			{
				return new Rect(0,0,Element.ActualSize.X, Element.ActualSize.Y);
			}
		}
	}
}