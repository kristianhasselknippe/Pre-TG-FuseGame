using Uno;
using Uno.Collections;
using Fuse;
using Experimental.ApiBindings.WebAudio;

namespace FuseGame.Audio
{


	public class FftProvider
	{

		public byte[] FftData
		{
			get { return _player.CurrentFft; }
		}

		public event EventHandler<byte[]> FftAvailable;

		readonly MusicPlayer _player;
		readonly float _pushDelay;

		public FftProvider(
			MusicPlayer player,
			float pushDelay = 0.0f)
		{
			_player = player;
			_player.FftAvailable += OnFftAvailable;
			_pushDelay = pushDelay;
		}

		float _lastPushTime = 0.0f;
		void OnFftAvailable(object sender, byte[] fft)
		{
			var elapsed = Fuse.Time.FrameTime - _lastPushTime;
			if (elapsed >= _pushDelay)
			{
				_lastPushTime = Fuse.Time.FrameTime;
				if (FftAvailable != null)
				{
					FftAvailable(this, fft);
				}
			}
		}

	}

	public class MusicPlayer
	{
		readonly AudioContext _context;
		readonly AnalyserNode _analyser;
	
		AudioBufferSourceNode _sourceNode;
		AudioBuffer _sourceBuffer;

		byte[] _fftData;

		public byte[] CurrentFft
		{
			get { return _fftData; }
		}

		public event EventHandler<byte[]> FftAvailable;

		public MusicPlayer(BundleFile musicFile)
		{
			_context = new AudioContext();
			_sourceNode = _context.CreateAudioBufferSourceNode();
			_analyser = _context.CreateAnalyserNode();

			_analyser.FftSize = 256;
			_analyser.SmoothingTimeConstat = 0.0;
			
			_context.CreateAudioBuffer(musicFile, OnBufferLoaded);
		}

		void OnBufferLoaded(AudioBuffer audioBuffer)
		{
			_sourceBuffer = audioBuffer;
			_sourceNode.Buffer = audioBuffer;
			_sourceNode.Connect(_analyser);
			_analyser.Connect(_context.Destination);
			_sourceNode.Start();
			UpdateManager.AddAction(Update);
		}

		public void Update()
		{
			_fftData = new byte[(int)_analyser.FrequencyBinCount];
			_analyser.GetByteFrequencyData(_fftData);
			OnFftAvailable(_fftData);
		}

		void OnFftAvailable(byte[] fft)
		{
			if (FftAvailable != null)
			{
				FftAvailable(this, fft);
			}
		}
	}
}