using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Fuse.Drawing;


public class Player : Fuse.Controls.Panel
{
	Translation _trans = new Translation();
	float2 Position
	{
		get { return _trans.Vector.XY; }
		set { _trans.Vector = float3(value, 0); }
	}

	float2 _velocity = float2();
	float2 Velocity
	{
		get { return _velocity; }
		set { _velocity = value; }
	}

	bool _wDown = false;
	float2 Up { get { return _wDown ? float2(0,-1) : float2(0); } }
	bool _aDown = false;
	float2 Left { get { return _aDown ? float2(-1,0) : float2(0); } }
	bool _sDown = false;
	float2 Down { get { return _sDown ? float2(0,1) : float2(0); } }
	bool _dDown = false;
	float2 Right { get { return _dDown ? float2(1,0) : float2(0); } }

	public Player()
	{
		Transforms.Add(_trans);
		Width = 50;
		Height = 50;
		App.Current.Window.KeyPressed += KeyPressed;
		App.Current.Window.KeyReleased += KeyReleased;
		Update += OnUpdate;
	}

	public Player(float2 position) : this()
	{
		Position = position;
	}

	void OnUpdate(object sender, EventArgs args)
	{
		var dt = Fuse.Time.FrameInterval;
		ProcessInput(dt);
		Simulate(dt);
	}

	void ProcessInput(float dt)
	{
		var input = Up + Down + Left + Right;
		var velDelta = input * dt;
		Velocity += velDelta;
	}

	void Simulate(float dt)
	{
		Position += Velocity;
	}

	void KeyPressed(object sender, Uno.Platform.KeyEventArgs args)
	{
		switch (args.Key)
		{
			case Uno.Platform.Key.W:
				_wDown = true;
				break;
			case Uno.Platform.Key.A:
				_aDown = true;
				break;
			case Uno.Platform.Key.S:
				_sDown = true;
				break;
			case Uno.Platform.Key.D:
				_dDown = true;
				break;
		}
	}

	void KeyReleased(object sender, Uno.Platform.KeyEventArgs args)
	{
		switch (args.Key)
		{
			case Uno.Platform.Key.W:
				_wDown = false;
				break;
			case Uno.Platform.Key.A:
				_aDown = false;
				break;
			case Uno.Platform.Key.S:
				_sDown = false;
				break;
			case Uno.Platform.Key.D:
				_dDown = false;
				break;
		}
	}
}

public class Game : Panel
{
	

	public Game()
	{
	}	
}

