using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Fuse.Drawing;



public abstract class GameObject : Panel
{
	public float Acceleration = 5f;
	public float RotationSpeed = 5f;

	Translation _trans = new Translation();
	protected float2 Position
	{
		get { return _trans.Vector.XY; }
		set { _trans.Vector = float3(value, 0); }
	}

	Rotation _rot = new Rotation();
	protected float Rotation
	{
		get { return _rot.Degrees; }
		set { _rot.Degrees = value; }
	}

	float2 _velocity = float2();
	protected float2 Velocity
	{
		get { return _velocity; }
		set { _velocity = value; }
	}

	protected GameObject()
	{
		Transforms.Add(_trans);
		Transforms.Add(_rot);
		Update += OnBaseUpdate;
	}

	void OnBaseUpdate(object sender, EventArgs args)
	{
		var dt = Fuse.Time.FrameInterval;
		OnUpdate(dt);
	}

	protected abstract void OnUpdate(float dt);

}


public class Player : GameObject
{


	bool _wDown = false;
	float Up { get { return _wDown ? 1 : 0; } }
	bool _aDown = false;
	float Left { get { return _aDown ? -1 : 0; } }
	bool _sDown = false;
	float Down { get { return _sDown ? -1 : 0; } }
	bool _dDown = false;
	float Right { get { return _dDown ? 1 : 0; } }

	public Player()
	{
		Width = 50;
		Height = 50;
		App.Current.Window.KeyPressed += KeyPressed;
		App.Current.Window.KeyReleased += KeyReleased;
	}

	public Player(float2 position) : this()
	{
		Position = position;
	}

	protected override void OnUpdate(float dt)
	{
		ProcessInput(dt);
		Simulate(dt);
	}

	void ProcessInput(float dt)
	{
		var rotation = Math.DegreesToRadians(Rotation);
		var input = Up + Down;
		var velDelta = input * dt;

		var rot = Left + Right;
		var rotDelta = rot * dt * RotationSpeed;

		Rotation += Math.RadiansToDegrees(rotDelta);
		var x = Math.Cos(rotation);
		var y = Math.Sin(rotation);
		var dir = Vector.Normalize(float2(x,y)) * Acceleration;

		Velocity += velDelta * dir;
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

public class Bullet : GameObject
{
	public Bullet()
	{

	}

	protected override void OnUpdate(float dt)
	{

	}
}

public class Game : GameObject
{

 	public Game()
	{
	}	
	protected override void OnUpdate(float dt)
	{

	}
}

