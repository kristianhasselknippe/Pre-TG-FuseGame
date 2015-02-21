using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Fuse.Drawing;
using Fuse.Shapes;


public class GameObject : Panel
{
	static Game _game { get; set; }
	public static void SetGame(Game g)
	{
		_game = g;
	}

	public static void Instantiate(GameObject go)
	{
		_game.Children.Add(go);
		debug_log "Instantiated: " + go + ", TotalObjects: " + _game.Children.Count;
	}

	public static void 	Destroy(GameObject go)
	{
		if (_game.Children.Contains(go))
		{
			_game.Children.Remove(go);
			debug_log "Destroyed: " + go + ", TotalObjects: " + _game.Children.Count;
		}
	}

	public float Acceleration = 5f;
	public float RotationSpeed = 5f;

	protected bool DisableUpdate { get; set; }

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
		if (DisableUpdate) return;
		var dt = Fuse.Time.FrameInterval;
		OnUpdate(dt);
		Position += Velocity;
	}

	protected virtual void OnUpdate(float dt) {}

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
			case Uno.Platform.Key.Space:
				Shoot();
				break;
		}
	}

	void Shoot()
	{
		GameObject.Instantiate(new Bullet(Position, Rotation));
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
	public float BulletSpeed = 10f;

	public Bullet(float2 position, float rotation)
	{
		Width = 15;
		Height = 5;
		Appearance = new Rectangle()
		{
			Fill = new SolidColor(float4(1,0,0,1))
		};
		Position = position;
		Rotation = rotation;
		var rot = Math.DegreesToRadians(Rotation);
		var x = Math.Cos(rot);
		var y = Math.Sin(rot);
		var dir = Vector.Normalize(float2(x,y));
		Velocity = dir * BulletSpeed;
	}

	protected override void OnUpdate(float dt)
	{
		if (Vector.Distance(Position, float2(0,0)) > 2000)
		{
			GameObject.Destroy(this);
		}
	}

}

public class Enemy : GameObject
{
	public Enemy()
	{

	}

}

public class Game : Panel
{
 	public Game()
	{
		GameObject.SetGame(this);
	}

}

