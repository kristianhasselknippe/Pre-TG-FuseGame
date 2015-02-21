using Uno;
using Uno.Collections;
using Fuse;
using Experimental.ApiBindings.WebAudio;

namespace FuseGame.Audio
{


	public class FftProvider
	{

		public float[] FftData
		{
			get { return _player.CurrentFft; }
		}

		public event EventHandler<float[]> FftAvailable;

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
		void OnFftAvailable(object sender, float[] fft)
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

		float[] _fftData;

		ScaleNode[] _scaleNodes;

		public float[] CurrentFft
		{
			get { return _fftData; }
		}

		public event EventHandler<float[]> FftAvailable;

		public MusicPlayer(BundleFile musicFile)
		{
			_context = new AudioContext();
			_sourceNode = _context.CreateAudioBufferSourceNode();
			_analyser = _context.CreateAnalyserNode();

			_analyser.FftSize = 256;
			_analyser.SmoothingTimeConstat = 0.0;

			_scaleNodes = new ScaleNode[(int)_analyser.FrequencyBinCount];
			_fftData = new float[(int)_analyser.FrequencyBinCount];

			for (int i = 0; i < _scaleNodes.Length; i++)
			{
				_scaleNodes[i] = new ScaleNode();
			}
			
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
			var fftData = new byte[(int)_analyser.FrequencyBinCount];
			_analyser.GetByteFrequencyData(fftData);

			for (int i = 0; i < _scaleNodes.Length; i++)
			{
				_scaleNodes[i].AttractionDestinatoin = fftData[i] * 2.0f;
				_scaleNodes[i].Update();
				_fftData[i] = _scaleNodes[i].Position;
			}

			OnFftAvailable(_fftData);
		}

		void OnFftAvailable(float[] fft)
		{
			if (FftAvailable != null)
			{
				FftAvailable(this, fft);
			}
		}
	}

	public class ScaleNode
	{
		public bool IsLocked
		{
			get; 
			set;
		}

		public float Position 
		{ 
			get; 
			set; 
		}

		float _velocity;
		public float Velocity 
		{ 
			get { return _velocity; }
			set
			{
				if (_velocity != value)
				{
					_velocity = value;
				}
			}
		}

		public float AttractionDestinatoin
		{
			get; set;
		}

		float _attractionForce = 4000;
		public float AttractionForce
		{
			get { return _attractionForce; }
			set { _attractionForce = value; }
		}

		float _attractionCurve = 0.65f;
		public float AttractionCurve
		{
			get { return _attractionCurve; }
			set	{ _attractionCurve = value; }
		}

		float _damping = 0.985f;
		public float Damping
		{
			get { return _damping; }
			set { _damping = value; }
		}

		float _energyEps = 1.0f;
		public float EnergyEps
		{
			get { return _energyEps; }
			set { _energyEps = value;}
		}

		double GetTime() { return Time.FrameTime; }

		double _simTime;

		double timeStep = 0.001;

		public void Update()
		{
			var p = Position;

			while (_simTime < GetTime())
			{
				Iterate();
				_simTime += timeStep;
			}

			if (Position != p && PositionChanged != null)
			{
				PositionChanged(Position);
			}
		}

		public Action<float> PositionChanged;

		float Attraction
		{
			get
			{
				var v = AttractionDestinatoin - Position;
				return Math.Pow(Math.Abs(v), AttractionCurve) * (v < 0 ? -1 : 1);
			}
		}


		float Energy
		{
			get { return Math.Abs(Attraction) + Math.Abs(Velocity); }
		}

		void Iterate()
		{
			Velocity += (float)(Attraction * AttractionForce * timeStep);

			Velocity *= Damping;

			if (!IsLocked)
			{ 
				Position += (float)(Velocity * timeStep);
			}
		}
	}
}