using Uno;
using Uno.Collections;
using Uno.Content.Models;
using Fuse;
using Fuse.Entities;
using Fuse.Drawing;
using Fuse.Drawing.Batching;
using Fuse.Drawing.Meshes;
using FuseGame.Audio;

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

	float _attractionCurve = 0.70f;
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

public class Background : Fuse.Controls.Panel
{

	int2 _cubeCount = int2(128,1);
	public int2 CubeCount
	{
		get { return _cubeCount; }
		set
		{
			if (_cubeCount != value)
			{
				_cubeCount = value;
				_batchIsInvalid = true;
			}
		}
	}

	float2 _cubeOffset = float2(3f,3f);
	public float2 CubeOffset
	{
		get { return _cubeOffset; }
		set
		{
			if (_cubeOffset != value)
			{
				_cubeOffset = value;
				_batchIsInvalid = true;
			}
		}
	}

	float _cubeHalfExtent = 1.0f;
	public float CubeHalfExtent
	{
		get { return _cubeHalfExtent; }
		set
		{
			if (_cubeHalfExtent != value)
			{
				_cubeHalfExtent = value;
				_batchIsInvalid = true;
			}
		}
	}

	bool _batchIsInvalid = true;
	Batch _batch;
	ModelMesh _mesh;
	IList<ScaleNode> _nodes;

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

	public Background()
	{
		CachingMode = CachingMode.Never;	
	}

	float[] _scales = null;

	void OnFftAvailable(object sender, byte[] fftData)
	{

		for (int i = 0; i < _nodes.Count; i++)
		{
			_nodes[i].AttractionDestinatoin = Math.Max(fftData[i], 1.0f);
		}

	}



	void CreateBatch()
	{

		_mesh = MeshGenerator.CreateCube(float3(0f), CubeHalfExtent);

		int cubeCount = CubeCount.X * CubeCount.Y;
		int verticeCount = cubeCount * _mesh.VertexCount;
		int indiceCount = cubeCount * _mesh.IndexCount;

		_scales = new float[cubeCount];
		_nodes = new List<ScaleNode>();

		for (int i = 0; i < cubeCount; i++)
		{
			_nodes.Add(new ScaleNode());
		}


		float3[] positions = new float3[cubeCount];

		int posCounter = 0;
		for (int x = 0; x < CubeCount.X; x++)
		{
			for (int y = 0; y < CubeCount.Y; y++)
			{
				positions[posCounter] = float3(x * CubeOffset.X, y * CubeOffset.Y, 0);
				_scales[posCounter] = 1.0f;
				posCounter++;
			}
		}

		_batch = new Batch(verticeCount, indiceCount, true);

		int indexCounter = 0;
		for (int i = 0; i < cubeCount; i++)
		{
			for (int j = 0; j < _mesh.VertexCount; j++)
			{
				_batch.Positions.Write(_mesh.Positions.GetFloat4(j).XYZ + positions[i]);
				_batch.Normals.Write(_mesh.Normals.GetFloat4(j).XYZ);
				_batch.TexCoord0s.Write(_mesh.TexCoords.GetFloat4(j).XY);
				_batch.Attrib0Buffer.Write(float4(1.0f, 0.0f, 0.0f, 1.0f));
				_batch.Attrib1Buffer.Write(float4(1.0f, 1.0f, 1.0f, 1.0f));
			}

			for (int j = 0; j < _mesh.IndexCount; j++)
			{
				_batch.Indices.Write((ushort)(_mesh.Indices.GetInt(j) + indexCounter));
			}

			indexCounter += _mesh.VertexCount;
		}

		_batchIsInvalid = false;
	}

	void UpdateScaling()
	{

		var scaleBuffer = _batch.Attrib1Buffer;
		scaleBuffer.Position = 0;

		int counter = 0;
		for (int x = 0; x < CubeCount.X; x++)
		{
			for (int y = 0; y < CubeCount.Y; y++)
			{
				for (int i = 0; i < _mesh.VertexCount; i++)
				{
					scaleBuffer.Write(float4(1.0f, 1.0f, _nodes[counter].Position / 10f, 1.0f));	
				}
				counter++;
			}
		}
		scaleBuffer.Invalidate();
	}

	protected override void OnRooted()
	{
		Update += OnUpdate;
		base.OnRooted();
	}

	protected override void OnUnrooted()
	{
		Update -= OnUpdate;
		base.OnUnrooted();
	}

	protected override void OnDraw(DrawContext dc)
	{
		base.OnDraw(dc);
		if (_batchIsInvalid)
			return;


		draw Fuse.Entities.DefaultShading, _batch
		{

			Translation: float3(0f);
			DiffuseColor: Attrib0.XYZ;
			Scale: Attrib1.XYZ;

		};
	}

	void OnUpdate(object sender, Uno.EventArgs args)
	{
		InvalidateVisual();
		if (_batchIsInvalid)
		{
			CreateBatch();
		}
		for (int i = 0; i < _nodes.Count; i++)
		{
			_nodes[i].Update();
		}
		UpdateScaling();
	}

}