using Uno;
using Uno.Collections;
using Uno.Content.Models;
using Fuse;
using Fuse.Entities;
using Fuse.Drawing;
using Fuse.Drawing.Batching;
using Fuse.Drawing.Meshes;
using FuseGame.Audio;



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

	float2 _cubeOffset = float2(4f,4f);
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



	void OnFftAvailable(object sender, float[] fftData)
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
					scaleBuffer.Write(float4(1.0f, 1.0f, fftData[counter] / 10f, 1.0f));	
				}
				counter++;
			}
		}
		scaleBuffer.Invalidate();

	}



	void CreateBatch()
	{

		_mesh = MeshGenerator.CreateCube(float3(0f), CubeHalfExtent);

		int cubeCount = CubeCount.X * CubeCount.Y;
		int verticeCount = cubeCount * _mesh.VertexCount;
		int indiceCount = cubeCount * _mesh.IndexCount;

		float3[] positions = new float3[cubeCount];

		int posCounter = 0;
		for (int x = 0; x < CubeCount.X; x++)
		{
			for (int y = 0; y < CubeCount.Y; y++)
			{
				positions[posCounter] = float3(x * CubeOffset.X, y * CubeOffset.Y, 0);
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
				_batch.Attrib0Buffer.Write(float4(0.7f, 0.3f, 0.0f, 1.0f));
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
		/*
		
		*/
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

		var m = GetDrawMatrix(dc);

		float3 scale = float3(0f);
		float4 rotation = float4(0f);
		float3 translation = float3(0f);

		Matrix.Decompose(m, out scale, out rotation, out translation);

		draw Fuse.Entities.DefaultShading, _batch
		{
			CameraPosition: float3(0f, 300f, 0f);
			Translation: translation;
			Rotation: rotation;

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
		UpdateScaling();
	}

}